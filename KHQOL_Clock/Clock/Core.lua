local ADDON_NAME, KHQOL = ...
KHQOL = assert(_G.KHQOL, "Install and enable the KHQOL core addon.")
local FC = KHQOL.modules.clock
local L = FC.L

-- Bundled Korean font.  Keeping it inside the addon makes the appearance
-- consistent regardless of the player's global UI-font replacement.
FC.FONT_PATH = "Interface\\AddOns\\KHQOL\\Fonts\\IsamanruLight.ttf"

FC.DEFAULTS = {
  version = 3, enabled = true, locked = true, fontSize = 48, moduleFontSize = 14,
  position = { point = "CENTER", relativePoint = "CENTER", x = 0, y = 0 },
  modules = {
    date = { enabled = true, position = { x = 0, y = 62 }, format = "YMD", weekday = "off" },
    weekday = { enabled = false, position = { x = 0, y = 35 }, language = "ko" },
    money = { enabled = true, position = { x = 170, y = 0 }, units = { gold = true, silver = true, copper = true } },
    performance = { enabled = true, position = { x = -82, y = -54 } },
    guild = { enabled = false, showTitle = true, background = false, tooltipLimit = 15, position = { x = 170, y = 35 } },
  },
  -- Per-target style values are intentionally separate from module data.
  -- Missing target entries inherit the common side-module style, preserving
  -- every existing user's current white outlined appearance on upgrade.
  textStyle = {
    clock = { color = { 1, 1, 1, 1 }, bold = false, effect = "OUTLINE" },
    common = { color = { 1, 1, 1, 1 }, bold = false, effect = "OUTLINE" },
  },
  minimap = { angle = 225 },
  settings = { window = { point = "CENTER", relativePoint = "CENTER", x = 0, y = 0 } },
  clockTools = {
    timerMinutes = 5,
    timerSeconds = 0,
    toolsScale = 100,
    timerDisplay = "full",
    timerBarLocked = true,
    alarm24Hour = false,
    alarmHour = 8,
    alarmMinute = 0,
    alarmSecond = 0,
    alarmAMPM = "AM",
    alarmMessage = "",
    alarmMessageFontSize = 14,
    alertFontSize = 24,
    alarmSound = true,
    alarmSoundChoice = "alarm",
  },
  todo = {
    currentPage = 1,
    pages = { { title = "", text = "" } },
    transparent = false,
    backgroundAlpha = 0.95,
    fontSize = 15,
    tabSpaces = 8,
    closeOnEscape = true,
    minimap = { show = true, angle = 135 },
    window = { point = "CENTER", relativePoint = "CENTER", x = 0, y = 0, width = 430, height = 310 },
  },
}

local function CopyColor(color)
  return { color[1] == nil and 1 or color[1], color[2] == nil and 1 or color[2], color[3] == nil and 1 or color[3], color[4] == nil and 1 or color[4] }
end

function FC:GetTextStyle(target)
  local styles = self.db.textStyle or {}
  local common = styles.common or self.DEFAULTS.textStyle.common
  local saved = target == "clock" and (styles.clock or self.DEFAULTS.textStyle.clock) or (styles[target] or {})
  return {
    color = CopyColor(saved.color or common.color),
    -- Bold is no longer exposed in the settings UI.  Ignore older saved
    -- values so removing the option also returns every target to normal weight.
    bold = false,
    effect = saved.effect or common.effect,
  }
end

function FC:SetTextStyleValue(target, key, value)
  self.db.textStyle = self.db.textStyle or {}
  self.db.textStyle[target] = self.db.textStyle[target] or {}
  self.db.textStyle[target][key] = key == "color" and CopyColor(value) or value
end

FC.SyncStyledText=KHQOL.HUDText.SyncStyledText
FC.ApplyTextStyle=KHQOL.HUDText.ApplyTextStyle

function FC:Print(message)
  local chat = DEFAULT_CHAT_FRAME or ChatFrame1
  if chat and chat.AddMessage then chat:AddMessage("|cffffd34e" .. self.ADDON_NAME .. "|r: " .. message) end
end

function FC:SafeCall(fn, ...)
  if type(fn) ~= "function" then return nil end
  local ok, a, b, c, d = pcall(fn, ...)
  if ok then return a, b, c, d end
  return nil
end

function FC:SetHUDShown(shown)
  self.db.enabled = shown and true or false
  if self.clockFrame then
    self.clockFrame:SetShown(self.db.enabled)
    if self.ApplyLayout then self:ApplyLayout() end
  end
  if self.UpdateTimers then self:UpdateTimers() end
  if self.RefreshSettings then self:RefreshSettings() end
end

function FC:ToggleHUD() self:SetHUDShown(not self.db.enabled) end

function FC:Initialize()
  if self.initialized then return end
  if KHQOL.InitializeProfiles then KHQOL:InitializeProfiles() end
  -- Keep prior money-display choices when upgrading from the radio-button version.
  local savedMoney = ForeverClockDB and ForeverClockDB.modules and ForeverClockDB.modules.money
  if savedMoney and not savedMoney.units and savedMoney.displayUnits then
    savedMoney.units = {
      gold = true,
      silver = savedMoney.displayUnits == "GS" or savedMoney.displayUnits == "GSC",
      copper = savedMoney.displayUnits == "GSC",
    }
  end
  local savedTodo = ForeverClockDB and ForeverClockDB.todo
  if savedTodo and savedTodo.backgroundAlpha == nil then
    savedTodo.backgroundAlpha = savedTodo.transparent and 0.18 or 0.95
  end
  local savedModules = ForeverClockDB and ForeverClockDB.modules
  if savedModules and savedModules.date and savedModules.date.weekday and savedModules.date.weekday ~= "off" then
    savedModules.weekday = savedModules.weekday or { enabled = true, position = { x = 0, y = 35 } }
    savedModules.weekday.enabled = true
    savedModules.weekday.language = savedModules.date.weekday
    savedModules.date.weekday = "off"
  end
  ForeverClockDB = KHQOL.MergeDefaults(ForeverClockDB or {}, self.DEFAULTS)
  self.db = ForeverClockDB
  self:CreateClock()
  self:CreateClockTools()
  self:CreateModules()
  self:CreateCalendar()
  self:CreateMinimapButton()
  self:CreateTodoMinimapButton()
  self:RefreshTodoNavigation()
  -- Settings controls are created in their owning tab on first use.
  self:ApplyAll()
  self:StartMinuteTimer()
  self.initialized=true
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_MONEY")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_LOGIN" then FC:Initialize()
  elseif FC.initialized then FC:UpdateMoney() end
end)
