local _, KHQOL = ...
local FC = KHQOL.modules.clock

local function MakeBackdrop(frame, r, g, b, a)
  frame:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
  frame:SetBackdropColor(0.015, 0.015, 0.015, a or 0.84)
  frame:SetBackdropBorderColor(r or 1, g or 0.78, b or 0.18, 0.9)
end
FC.MakeBackdrop = MakeBackdrop

function FC:CreateClock()
  local frame = CreateFrame("Frame", "ForeverClockClockFrame", UIParent, "BackdropTemplate")
  -- Width grows to match the clock and money panel; the initial size stays compact.
  frame:SetSize(430, 190)
  frame:SetClampedToScreen(false)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  MakeBackdrop(frame)
  local function ClockMouseDown(source, button)
    local f = source.clockOwner or source
    f.clockClickSource = source
    if button == "LeftButton" and not FC.db.locked and not (IsAltKeyDown and IsAltKeyDown()) then
      local x, y = GetCursorPosition()
      f.dragStartX, f.dragStartY = x, y
      f:StartMoving()
    end
  end
  local function ClockMouseUp(source, button)
    local f = source.clockOwner or source
    local overDigits = source == f.hoverHint and f.clockClickSource == f.hoverHint
    if overDigits then
      if f.hoverHint.IsMouseOver then overDigits = f.hoverHint:IsMouseOver()
      elseif MouseIsOver then overDigits = MouseIsOver(f.hoverHint) end
    end
    f.clockClickSource = nil
    if overDigits and IsAltKeyDown and IsAltKeyDown() then
      if button == "RightButton" then ReloadUI(); return end
      if button == "LeftButton" then f:StopMovingOrSizing(); FC:OpenCalendar(); return end
    end
    if button == "RightButton" and overDigits then FC:ToggleTodo() end
    if button == "LeftButton" then
      local moved = false
      if not FC.db.locked then
        local x, y = GetCursorPosition()
        moved = math.abs(x - (f.dragStartX or x)) > 5 or math.abs(y - (f.dragStartY or y)) > 5
        f:StopMovingOrSizing()
        if moved then
          -- Constrain the visible clock, not the transparent working frame,
          -- so the clock can be placed flush with the screen top.
          local centerX, centerY = f:GetCenter()
          local uiWidth, uiHeight = UIParent:GetWidth(), UIParent:GetHeight()
          local halfWidth = f.timeText:GetStringWidth() / 2 + 6
          local halfHeight = f.timeText:GetStringHeight() / 2 + 6
          centerX = math.max(halfWidth, math.min(uiWidth - halfWidth, centerX))
          centerY = math.max(halfHeight, math.min(uiHeight - halfHeight, centerY))
          f:ClearAllPoints()
          f:SetPoint("CENTER", UIParent, "CENTER", centerX - uiWidth / 2, centerY - uiHeight / 2)
          local point, _, relativePoint, px, py = f:GetPoint(1)
          FC.db.position = { point = point, relativePoint = relativePoint, x = math.floor(px + 0.5), y = math.floor(py + 0.5) }
        end
      end
      f.dragStartX, f.dragStartY = nil, nil
      if not moved and overDigits then FC:ToggleClockTools() end
    end
  end
  frame:SetScript("OnMouseDown", ClockMouseDown)
  frame:SetScript("OnMouseUp", ClockMouseUp)
  local time = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  time:SetPoint("CENTER", frame, "CENTER", 0, 0)
  time:SetTextColor(1, 1, 1)
  frame.timeText = time
  -- The parent frame is intentionally wide to hold side modules.  A small
  -- child hit area makes the help appear only over the visible clock digits.
  local hint = CreateFrame("Frame", nil, frame)
  hint:SetPoint("CENTER", time, "CENTER", 0, 0)
  hint:SetFrameLevel(frame:GetFrameLevel() + 1)
  hint:EnableMouse(true)
  hint.clockOwner = frame
  hint:SetScript("OnMouseDown", ClockMouseDown)
  hint:SetScript("OnMouseUp", ClockMouseUp)
  hint:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_NONE")
    GameTooltip:ClearAllPoints()
    -- Below the digits: the tooltip never covers the current time.
    GameTooltip:SetPoint("TOP", self, "BOTTOM", 0, -10)
    GameTooltip:SetText("ForeverClock", 1, .82, .18)
    GameTooltip:AddLine("좌클릭: 알람/스톱워치/타이머  |  우클릭: Forever Note", 1, 1, 1)
    GameTooltip:AddLine("Alt+좌클릭: 달력", 1, 1, 1)
    GameTooltip:AddLine("Alt+우클릭: UI 새로고침", 1, 1, 1)
    GameTooltip:Show()
  end)
  hint:SetScript("OnLeave", function() GameTooltip:Hide() end)
  frame.hoverHint = hint
  -- Calendar reminders pulse only the actual time digits, never the invisible work frame.
  local group = time:CreateAnimationGroup()
  group:SetLooping("REPEAT")
  local fadeOut = group:CreateAnimation("Alpha"); fadeOut:SetFromAlpha(1); fadeOut:SetToAlpha(0.35); fadeOut:SetDuration(0.6); fadeOut:SetSmoothing("IN_OUT")
  local fadeIn = group:CreateAnimation("Alpha"); fadeIn:SetFromAlpha(0.35); fadeIn:SetToAlpha(1); fadeIn:SetDuration(0.6); fadeIn:SetSmoothing("IN_OUT")
  frame.timePulse = group
  self.clockFrame = frame
end

function FC:UpdateClock()
  if not self.clockFrame or not self.db.enabled then return end
  local hour, minute = date("%H"), date("%M")
  self.clockFrame.timeText:SetText(hour .. ":" .. minute)
  self:SyncStyledText(self.clockFrame.timeText)
  if self.clockFrame.hoverHint then
    self.clockFrame.hoverHint:SetSize(self.clockFrame.timeText:GetStringWidth(), self.clockFrame.timeText:GetStringHeight())
  end
end

function FC:ApplyClock()
  local db, frame = self.db, self.clockFrame
  frame:ClearAllPoints()
  frame:SetPoint(db.position.point, UIParent, db.position.relativePoint, db.position.x, db.position.y)
  self:ApplyTextStyle(frame.timeText, db.fontSize, self:GetTextStyle("clock"))
  frame:SetBackdropColor(0.015, 0.015, 0.015, db.locked and 0 or 0.84)
  -- The transparent HUD workspace is draggable only; clicks belong to the digits.
  frame:EnableMouse(not db.locked)
  frame:SetShown(db.enabled)
  self:SetInviteGlow(self.calendar and self.calendar.pending and self.calendar.pending > 0)
  self:UpdateClock()
  self:UpdateHUDWidth()
end

function FC:UpdateHUDWidth()
  if not self.clockFrame then return end
  local moneyWidth = self.modules and self.modules.money and self.modules.money:GetWidth() or 175
  local timeWidth = self.clockFrame.timeText:GetStringWidth()
  -- Enough width to keep a full money panel beside the clock at either side.
  self.clockFrame:SetWidth(math.max(430, timeWidth + moneyWidth * 2 + 40))
  if self.UpdateProfessionAnchor then self:UpdateProfessionAnchor() end
end

function FC:StartMinuteTimer()
  local function Tick()
    FC:UpdateClock()
    FC:UpdateDate()
    FC:UpdateWeekday()
    if C_Timer and C_Timer.After then C_Timer.After(60 - (time() % 60) + 0.1, Tick) end
  end
  Tick()
end

function FC:SetInviteGlow(active)
  if not self.clockFrame then return end
  if active then
    self.clockFrame:SetBackdropBorderColor(1, 0.78, 0.18, self.db.locked and 0 or 0.9)
    if not self.clockFrame.timePulse:IsPlaying() then self.clockFrame.timePulse:Play() end
  else
    self.clockFrame.timePulse:Stop(); self.clockFrame.timeText:SetAlpha(1)
    self.clockFrame:SetBackdropBorderColor(1, 0.78, 0.18, self.db.locked and 0 or 0.9)
  end
end
