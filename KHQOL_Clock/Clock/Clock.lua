local _, KHQOL = ...
KHQOL = assert(_G.KHQOL, "Install and enable the KHQOL core addon.")
local FC = KHQOL.modules.clock

local MakeBackdrop=KHQOL.HUDText.MakeBackdrop
FC.MakeBackdrop=MakeBackdrop

FC.clockActions={{"calendar","달력","OpenCalendar"},{"note","포에버 노트","ToggleTodo"},
  {"tools","타이머·알람·스톱워치","ToggleClockTools"},{"reload","UI 새로고침"}}
FC.clockModifiers={{value="none",text="없음"},{value="shift",text="Shift"},{value="ctrl",text="Ctrl"},{value="alt",text="Alt"}}
FC.clockInputs={{value="LeftButton",text="좌클릭"},{value="RightButton",text="우클릭"},{value="Button4",text="마우스 4번"},
  {value="WheelUp",text="휠 위"},{value="WheelDown",text="휠 아래"},{value="disabled",text="사용 안 함"}}
local function labels(options)
  local result={};for _,entry in ipairs(options) do result[entry.value]=entry.text end;return result
end
local modifierLabels,inputLabels=labels(FC.clockModifiers),labels(FC.clockInputs)

function FC:GetClockShortcuts()
  self.db.shortcuts=KHQOL.MergeDefaults(type(self.db.shortcuts)=="table" and self.db.shortcuts or {},self.DEFAULTS.shortcuts,"types")
  return self.db.shortcuts
end

function FC:ClockShortcutAction(input)
  if KHQOL.PositionEditor.active then return end
  local shift,ctrl,alt=IsShiftKeyDown(),IsControlKeyDown(),IsAltKeyDown()
  if (shift and 1 or 0)+(ctrl and 1 or 0)+(alt and 1 or 0)>1 then return end
  local modifier=shift and "shift" or ctrl and "ctrl" or alt and "alt" or "none"
  local choices=self:GetClockShortcuts()
  for _,action in ipairs(self.clockActions) do
    local key=choices[action[1]]
    if key.modifier==modifier and key.input==input then return action end
  end
end

function FC:SetClockShortcut(id,field,value)
  local choices=self:GetClockShortcuts()
  local key=choices[id]
  local valid=field=="modifier" and modifierLabels[value] or field=="input" and inputLabels[value]
  if not key or not valid then return end
  local modifier=field=="modifier" and value or key.modifier
  local input=field=="input" and value or key.input
  for _,action in ipairs(self.clockActions) do
    local other=choices[action[1]]
    if action[1]~=id and input~="disabled" and other.modifier==modifier and other.input==input then
      -- Exchanging the previous binding makes a conflicting choice reversible.
      other.modifier,other.input=key.modifier,key.input
      break
    end
  end
  key[field]=value
  self:ConfigureClockShortcut()
end

function FC:ConfigureClockShortcut()
  local hint=self.clockFrame and self.clockFrame.hoverHint
  if not hint then return end
  local wheel=false
  for _,binding in pairs(self:GetClockShortcuts()) do
    if binding.input=="WheelUp" or binding.input=="WheelDown" then wheel=true;break end
  end
  hint:EnableMouseWheel(wheel)
end

function FC:RunClockShortcut(action)
  if not action then return end
  if action[3] then self[action[3]](self)
  else KHQOL.PublicCall(ReloadUI) end
end

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
    if button == "LeftButton" and not FC.db.locked and not KHQOL.PositionEditor.active
      and not (source==f.hoverHint and (IsAltKeyDown() or IsShiftKeyDown() or IsControlKeyDown())) then
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
    local moved=false
    if button == "LeftButton" then
      if f.dragStartX then
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
          local p=FC.db.position
          p.point,p.relativePoint,p.x,p.y=point,relativePoint,math.floor(px+.5),math.floor(py+.5)
          KHQOL.PositionStore:Committed(function() FC:ApplyClock();FC:ApplyLayout() end)
        end
      end
      f.dragStartX, f.dragStartY = nil, nil
    end
    if not moved and overDigits then FC:RunClockShortcut(FC:ClockShortcutAction(button)) end
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
  hint:SetScript("OnMouseWheel",function(_,delta)
    if delta~=0 and not frame.dragStartX then FC:RunClockShortcut(FC:ClockShortcutAction(delta>0 and "WheelUp" or "WheelDown")) end
  end)
  hint:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_NONE")
    GameTooltip:ClearAllPoints()
    -- Below the digits: the tooltip never covers the current time.
    GameTooltip:SetPoint("TOP", self, "BOTTOM", 0, -10)
    GameTooltip:SetText("ForeverClock", 1, .82, .18)
    local choices=FC:GetClockShortcuts()
    for _,action in ipairs(FC.clockActions) do
      local key=choices[action[1]]
      local label=key.modifier=="none" and "" or (modifierLabels[key.modifier] or "").."+"
      if key.input~="disabled" and inputLabels[key.input] then GameTooltip:AddLine(label..inputLabels[key.input].." · "..action[2],1,1,1) end
    end
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
  self:ConfigureClockShortcut()
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
