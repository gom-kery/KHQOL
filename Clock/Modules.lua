local _, KHQOL = ...
local FC = KHQOL.modules.clock
local L = FC.L
local ICON = "|TInterface\\MoneyFrame\\UI-GoldIcon:14:14:2:0|t"
local SILVER = "|TInterface\\MoneyFrame\\UI-SilverIcon:14:14:2:0|t"
local COPPER = "|TInterface\\MoneyFrame\\UI-CopperIcon:14:14:2:0|t"

local function NewModule(name)
  local frame = CreateFrame("Button", "ForeverClock" .. name .. "Module", FC.clockFrame, "BackdropTemplate")
  frame:SetHeight(27); frame:SetWidth(120)
  frame:SetMovable(true); frame:SetClampedToScreen(true); frame:EnableMouse(true); frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  FC.MakeBackdrop(frame, 0.95, 0.73, 0.15, 0.68)
  local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  text:SetPoint("CENTER", frame, "CENTER", 0, 0); text:SetTextColor(1, 1, 1)
  frame.text = text
  return frame
end

function FC:SetModulePosition(name, frame)
  local parentX, parentY = self.clockFrame:GetCenter()
  local frameX, frameY = frame:GetCenter()
  local x, y = self:ConstrainModulePosition(name, frame, frameX - parentX, frameY - parentY)
  self.db.modules[name].position = { x = math.floor(x + 0.5), y = math.floor(y + 0.5) }
  self:ApplyLayout()
  if self.RefreshSettings then self:RefreshSettings() end
end

function FC:ConstrainModulePosition(name, frame, x, y)
  -- Side panels are freely placed while unlocked.  Do not snap to dock slots
  -- or push money away from the clock; the player controls the exact alignment.
  return x, y
end

function FC:EnableModuleDrag(name, frame)
  frame:SetScript("OnMouseDown", function(f, button)
    if button == "LeftButton" and not FC.db.locked then
      f.dragStartX, f.dragStartY = GetCursorPosition()
      f:StartMoving()
    end
  end)
  frame:SetScript("OnMouseUp", function(f, button)
    if button == "LeftButton" and not FC.db.locked then
      local x, y = GetCursorPosition()
      local moved = math.abs(x - (f.dragStartX or x)) > 5 or math.abs(y - (f.dragStartY or y)) > 5
      f:StopMovingOrSizing()
      if moved then FC:SetModulePosition(name, f) else FC:ApplyLayout() end
    end
  end)
end

function FC:CreateModules()
  self.modules = {}
  self.modules.date = NewModule("Date")
  self.modules.weekday = NewModule("Weekday")
  self.modules.money = NewModule("Money")
  self.modules.money:SetWidth(175)
  self.modules.performance = NewModule("Performance")
  self.modules.performance:SetWidth(130)
  for name, frame in pairs(self.modules) do self:EnableModuleDrag(name, frame) end
end

function FC:UpdateDate()
  if not self.modules or not self.db.modules.date.enabled then return end
  local now = date("*t")
  local dateDB = self.db.modules.date
  local value = dateDB.format == "MD" and (now.month .. "/" .. now.day) or (now.year .. "/" .. now.month .. "/" .. now.day)
  self.modules.date.text:SetText(value)
  self:SyncStyledText(self.modules.date.text)
  self.modules.date:SetWidth(math.max(28, self.modules.date.text:GetStringWidth() + 16))
end

function FC:UpdateWeekday()
  if not self.modules or not self.db.modules.weekday.enabled then return end
  local now = date("*t")
  local ko = { "일", "월", "화", "수", "목", "금", "토" }
  local en = { "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" }
  local language = self.db.modules.weekday.language or "ko"
  self.modules.weekday.text:SetText(language == "en" and en[now.wday] or ko[now.wday])
  self:SyncStyledText(self.modules.weekday.text)
  self.modules.weekday:SetWidth(math.max(28, self.modules.weekday.text:GetStringWidth() + 16))
end

function FC:UpdateMoney()
  if not self.modules or not self.db.modules.money.enabled then return end
  local amount = type(GetMoney) == "function" and GetMoney() or 0
  local gold, silver, copper = math.floor(amount / 10000), math.floor((amount % 10000) / 100), amount % 100
  local units, pieces = self.db.modules.money.units or {}, {}
  if units.gold then pieces[#pieces + 1] = gold .. " " .. ICON end
  if units.silver then pieces[#pieces + 1] = silver .. " " .. SILVER end
  if units.copper then pieces[#pieces + 1] = copper .. " " .. COPPER end
  self.modules.money.text:SetText(table.concat(pieces, "  "))
  self:SyncStyledText(self.modules.money.text)
  -- Remove the former fixed-width blank space around short money values.
  self.modules.money:SetWidth(math.max(28, self.modules.money.text:GetStringWidth() + 16))
  self:UpdateHUDWidth()
  self:ApplyLayout()
end

function FC:UpdatePerformance()
  if not self.modules or not self.db.modules.performance.enabled then return end
  local fps = type(GetFramerate) == "function" and math.floor(GetFramerate() + 0.5) or 0
  local home, world
  if type(GetNetStats) == "function" then
    local _, _, homeLatency, worldLatency = GetNetStats()
    home, world = homeLatency, worldLatency
  end
  local latency = world or home or 0
  local color = fps >= 60 and "|cff42d95b" or (fps >= 30 and "|cffffd34e" or "|cffff4b4b")
  self.modules.performance.text:SetText("FPS: " .. color .. fps .. "|r  MS: " .. latency)
  self:SyncStyledText(self.modules.performance.text)
end

function FC:ApplyLayout()
  if not self.modules then return end
  for name, frame in pairs(self.modules) do
    local data = self.db.modules[name]
    frame:ClearAllPoints()
    local position = data.position or { x = 0, y = 0 }
    local x, y = self:ConstrainModulePosition(name, frame, position.x or 0, position.y or 0)
    position.x, position.y = x, y
    data.position = position
    frame:SetPoint("CENTER", self.clockFrame, "CENTER", x, y)
    self:ApplyTextStyle(frame.text, data.fontSize or self.db.moduleFontSize, self:GetTextStyle(name))
    frame:SetBackdropColor(0.015, 0.015, 0.015, self.db.locked and 0 or 0.68)
    frame:SetBackdropBorderColor(0.95, 0.73, 0.15, self.db.locked and 0 or 0.68)
    frame:SetShown(self.db.enabled and data.enabled)
  end
  if self.UpdateProfessionsVisibility then self:UpdateProfessionsVisibility() end
end

function FC:UpdateTimers()
  if self.performanceTicker then self.performanceTicker:Cancel(); self.performanceTicker = nil end
  if self.db.enabled and self.db.modules.performance.enabled and C_Timer and C_Timer.NewTicker then
    self:UpdatePerformance()
    self.performanceTicker = C_Timer.NewTicker(2, function() FC:UpdatePerformance() end)
  end
end

function FC:ApplyAll()
  self:ApplyClock(); self:ApplyLayout(); self:UpdateDate(); self:UpdateWeekday(); self:UpdateMoney(); self:UpdateTimers()
end
