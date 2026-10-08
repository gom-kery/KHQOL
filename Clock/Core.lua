local ADDON_NAME, KHQOL = ...
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
    professions = { enabled = true, layout = "horizontal", iconSize = 36, showSkill = true, position = { x = 160, y = 0 } },
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

function FC:SyncStyledText(fontString)
  if not fontString then return end
  local overlay = fontString.foreverClockBoldOverlay
  local point, relativeTo, relativePoint, x, y = fontString:GetPoint(1)
  if overlay then
    overlay:SetText(fontString:GetText() or "")
    overlay:SetShown(fontString:IsShown() and overlay.styleEnabled)
  end
  if point and overlay then
    overlay:ClearAllPoints()
    -- One full UI pixel is intentional: the prior sub-pixel offset could be
    -- rounded away by Forever's renderer and made Bold visually identical.
    overlay:SetPoint(point, relativeTo, relativePoint, (x or 0) + 1, y or 0)
  end
  for _, outline in ipairs(fontString.foreverClockThickOutlines or {}) do
    outline:SetText(fontString:GetText() or "")
    outline:SetShown(fontString:IsShown() and outline.styleEnabled)
    if point then
      outline:ClearAllPoints()
      outline:SetPoint(point, relativeTo, relativePoint, (x or 0) + outline.offsetX, (y or 0) + outline.offsetY)
    end
  end
end

function FC:ApplyTextStyle(fontString, size, style)
  if not fontString or not style then return end
  local effect = style.effect or "OUTLINE"
  local flags = effect == "OUTLINE" and "OUTLINE" or (effect == "THICKOUTLINE" and "THICKOUTLINE" or "")
  local color = style.color or { 1, 1, 1, 1 }
  fontString:SetFont(self.FONT_PATH, size, flags)
  fontString:SetTextColor(color[1] == nil and 1 or color[1], color[2] == nil and 1 or color[2], color[3] == nil and 1 or color[3], color[4] == nil and 1 or color[4])
  if effect == "SHADOW" then
    fontString:SetShadowColor(0, 0, 0, 0.9)
    fontString:SetShadowOffset(1, -1)
  else
    fontString:SetShadowColor(0, 0, 0, 0)
    fontString:SetShadowOffset(0, 0)
  end

  -- IsamanruLight has no bundled bold face.  A second, slightly offset copy
  -- gives a stable synthetic bold without replacing Korean glyph coverage.
  local overlay = fontString.foreverClockBoldOverlay
  if style.bold and not overlay then
    overlay = fontString:GetParent():CreateFontString(nil, "OVERLAY")
    fontString.foreverClockBoldOverlay = overlay
  end
  if overlay then
    overlay:SetFont(self.FONT_PATH, size, flags)
    overlay:SetTextColor(color[1] == nil and 1 or color[1], color[2] == nil and 1 or color[2], color[3] == nil and 1 or color[3], color[4] == nil and 1 or color[4])
    if effect == "SHADOW" then overlay:SetShadowColor(0, 0, 0, 0.9); overlay:SetShadowOffset(1, -1) else overlay:SetShadowColor(0, 0, 0, 0); overlay:SetShadowOffset(0, 0) end
    overlay.styleEnabled = style.bold and true or false
    overlay:SetShown(overlay.styleEnabled)
  end
  local thickOutlines = fontString.foreverClockThickOutlines
  if effect == "THICKOUTLINE" and not thickOutlines then
    thickOutlines = {}
    for _, offset in ipairs({ { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 } }) do
      -- The helper copies must sit below the source text.  OVERLAY would draw
      -- their black glyph interiors on top of the coloured text.
      local outline = fontString:GetParent():CreateFontString(nil, "ARTWORK")
      outline.offsetX, outline.offsetY = offset[1], offset[2]
      thickOutlines[#thickOutlines + 1] = outline
    end
    fontString.foreverClockThickOutlines = thickOutlines
  end
  for _, outline in ipairs(thickOutlines or {}) do
    -- Some Forever builds render THICKOUTLINE almost like OUTLINE.  Four
    -- one-pixel black copies make the selected effect reliably thicker.
    outline:SetFont(self.FONT_PATH, size, "OUTLINE")
    outline:SetTextColor(0, 0, 0, 0.9)
    outline:SetShadowColor(0, 0, 0, 0)
    outline:SetShadowOffset(0, 0)
    outline.styleEnabled = effect == "THICKOUTLINE"
    outline:SetShown(outline.styleEnabled)
  end
  self:SyncStyledText(fontString)
end

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
    if self.db.enabled and self.ApplyLayout then self:ApplyLayout() end
  end
  if self.UpdateTimers then self:UpdateTimers() end
  if self.UpdateProfessionsVisibility then self:UpdateProfessionsVisibility() end
  if self.RefreshSettings then self:RefreshSettings() end
end

function FC:ToggleHUD() self:SetHUDShown(not self.db.enabled) end

function FC:Initialize()
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
  self:CreateProfessions()
  self:CreateCalendar()
  self:CreateMinimapButton()
  self:CreateTodoMinimapButton()
  self:RefreshTodoNavigation()
  self:CreateSettings()
  self:ApplyAll()
  self:StartMinuteTimer()
end

-- Skill-line events can arrive in a short burst while zoning or learning a
-- profession.  Coalesce them so the UI is rebuilt once after the client has
-- finished updating its skill data.
function FC:QueueProfessionScan()
  if not self.db or self.professionScanQueued then return end
  if not (C_Timer and C_Timer.After) then
    if self.ScanProfessions then self:ScanProfessions() end
    return
  end
  self.professionScanQueued = true
  C_Timer.After(0.15, function()
    FC.professionScanQueued = nil
    if FC.db and FC.ScanProfessions then FC:ScanProfessions() end
  end)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_MONEY")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("SKILL_LINES_CHANGED")
eventFrame:SetScript("OnEvent", function(_, event, ...)
  if event == "PLAYER_LOGIN" then
    FC:Initialize()
    SLASH_FOREVERCLOCK1, SLASH_FOREVERCLOCK2 = "/fclock", "/fc"
    SlashCmdList.FOREVERCLOCK = function(message)
      local command = (message or ""):lower():match("^%s*(.-)%s*$")
      if command == "professions" or command == "professions scan" then FC:PrintProfessionDebug()
      elseif _G.KHQOL and _G.KHQOL.OpenModule then _G.KHQOL:OpenModule("clock") else FC:ToggleSettings() end
    end
  elseif event == "PLAYER_MONEY" and FC.UpdateMoney then
    FC:UpdateMoney()
  elseif event == "PLAYER_ENTERING_WORLD" or event == "SKILL_LINES_CHANGED" then
    FC:QueueProfessionScan()
  elseif FC.OnCalendarEvent then
    FC:OnCalendarEvent(event, ...)
  end
end)
