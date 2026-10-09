local _, KHQOL = ...

local defaults = {
  version = 1,
  minimap = { show = true, angle = 225 },
  locked = true, debug = false,
  enabled = { clock = true, todo = true, buffReminder = true, range = true, tooltip = true, resourceSwing = true, campfire = true, cursorTrail = true, castBar = true, combatStatus = true, questNavigator = true, threat = true, pvpAlert = true },
  migrated = {}, modules = {},
  general = {
    centerTextScale = 100, autoSellJunk = false, autoSellJunkReport = false, autoConfirmDestroy = false, chatEnhancement = false,
    autoRepair = false, useGuildFunds = false, declinePartyInvites = false, declineGuildInvites = false,
  },
}

local legacy = {
  clock = "ForeverClockDB", buffReminder = "ForeverBuffReminderDB", range = "FRangeDB",
  weaponGuide = "ForeverWeaponGuideDB", resourceSwing = "KHQOLResourceSwingDB", campfire = "CampfireAlertDB",
}
KHQOL.defaults = defaults
defaults.enabled.environmentTimer = false
defaults.enabled.experienceBar = false
defaults.enabled.procAlert = false
defaults.enabled.objectHighlight = false
defaults.enabled.npcAlert = false

function KHQOL:Migrate()
  for key, variable in pairs(legacy) do
    if not self.db.migrated[key] and type(_G[variable]) == "table" then
      self.db.modules[key] = KHQOL.MergeDefaults({}, _G[variable], "tables")
      self.db.migrated[key] = true
    end
  end
  -- WeaponGuide became a Tooltip information provider.  Preserve the old
  -- database and import its display preference only once into Tooltip.
  if not self.db.migrated.tooltip then
    local old = type(ForeverWeaponGuideDB) == "table" and ForeverWeaponGuideDB or nil
    self.db.modules.tooltip = KHQOL.MergeDefaults(self.db.modules.tooltip or {}, {
      weaponGuide = old == nil or old.enabled ~= false,
      textSize = old and type(old.fontSize) == "number" and math.max(-3, math.min(3, old.fontSize - 13)) or 0,
    }, "tables")
    self.db.migrated.tooltip = true
  end
  -- Todo remains owned by the original clock DB so all pages, groups and window data survive intact.
  if not self.db.migrated.todo and ForeverClockDB and ForeverClockDB.todo then
    self.db.modules.todo = KHQOL.MergeDefaults({}, ForeverClockDB.todo, "tables"); self.db.migrated.todo = true
  end
end

function KHQOL:GetEnabled(key) return self.db.enabled[key] ~= false end

local managedModules = {
  procAlert=true,
  objectHighlight=true,
  npcAlert=true,
  experienceBar=true,
  environmentTimer=true,
  tooltip=true, cursorTrail=true, castBar=true, combatStatus=true,
  questNavigator=true, threat=true, pvpAlert=true,
}
function KHQOL:SetEnabled(key, enabled, reapply)
  -- Internal reapplication preserves preferences while the lock gates execution.
  if not reapply and self.LabLock:IsExperimental(key) and not self.LabLock:IsUnlocked() then return false end
  if not reapply then self.db.enabled[key] = enabled and true or false end
  if self.LabLock:IsExperimental(key) then enabled=enabled and self.LabLock:IsUnlocked() end
  local fc, fr, cfa = self.modules.clock, self.modules.range, self.modules.campfire
  if key == "clock" and fc and fc.SetHUDShown then fc:SetHUDShown(enabled) end
  if key == "todo" and fc then
    if fc.todoFrame and not enabled then fc.todoFrame:Hide() end
    if fc.UpdateTodoMinimapButton then fc:UpdateTodoMinimapButton() end
    if fc.RefreshTodoNavigation then fc:RefreshTodoNavigation() end
  end
  if key == "range" and fr and fr.SetEnabled then fr:SetEnabled(enabled) end
  if key == "buffReminder" and ForeverBuffReminder then
    if enabled then ForeverBuffReminder:RefreshAlerts() else ForeverBuffReminder:StopCountdown(); if ForeverBuffReminder.container then ForeverBuffReminder.container:Hide() end end
  end
  if key == "resourceSwing" then
    if self.modules.resourceSwing.SetEnabled then self.modules.resourceSwing:SetEnabled(enabled)
    else
      if KHQOLResourceSwingDB then KHQOLResourceSwingDB.enabled = enabled and true or false end
      if KHQOLResourceSwingFrame then KHQOLResourceSwingFrame:SetShown(enabled) end
    end
  end
  if key == "campfire" and cfa then if not enabled then cfa:HideDiscovery() elseif cfa.ProcessAuras then cfa:ProcessAuras("khqol-enable") end end
  local module = managedModules[key] and self.modules[key]
  if module and module.SetEnabled then module:SetEnabled(enabled) end
  if key == "resourceSwing" and self.modules.castBar and self.modules.castBar.frame then self.modules.castBar:ApplyLayout(); self.modules.castBar:RefreshControls() end
  if not self.profileApplying and self.settings and self.settings.RefreshModuleState then self.settings:RefreshModuleState(key) end
  return true
end

function KHQOL:HideLegacyButtons()
  local buttons = { ForeverClockMinimapButton, ForeverBuffReminderMinimapButton, KHQOLResourceSwingMinimapButton }
  for _, button in ipairs(buttons) do if button then button:Hide(); button:SetScript("OnShow", function(self) self:Hide() end) end end
end

function KHQOL:CreateMinimapButton()
  local b = CreateFrame("Button", "KHQOLMinimapButton", Minimap)
  b:SetSize(32, 32); b:RegisterForClicks("LeftButtonUp")
  local icon = b:CreateTexture(nil, "BACKGROUND"); icon:SetTexture("Interface\\AddOns\\KHQOL\\Media\\kh-qol-minimap-button.tga"); icon:SetAllPoints(b)
  b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  b:SetScript("OnClick", function() self:ToggleSettings() end)
  b:SetMovable(true); b:RegisterForDrag("LeftButton")
  function self:UpdateMinimapButton()
    local a = math.rad(self.db.minimap.angle or 225); b:ClearAllPoints(); b:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * 108, math.sin(a) * 108); b:SetShown(self.db.minimap.show)
  end
  b:SetScript("OnDragStart", function(button) if not KHQOL.db.minimap.positionLocked then button.positionMoving=true; button:StartMoving() end end)
  b:SetScript("OnDragStop", function(self)
    if not self.positionMoving then return end
    self.positionMoving=nil
    self:StopMovingOrSizing()
    local x, y = GetCursorPosition(); local scale = Minimap:GetEffectiveScale(); x, y = x / scale, y / scale
    local mx, my = Minimap:GetCenter()
    KHQOL.db.minimap.angle = math.deg(math.atan2(y - my, x - mx))
    KHQOL:UpdateMinimapButton()
  end)
  self.minimapButton = b; self:UpdateMinimapButton()
end

function KHQOL:OpenModule(key)
  self:ShowSettings(key)
end
function KHQOL:ToggleSettings() if self.settings and self.settings:IsShown() then self.settings:Hide() else self:ShowSettings("general") end end

local commandPages = KHQOL.UI.SettingsRegistry.commands
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function()
  KHQOL:InitializeProfiles()
  KHQOLDB = KHQOL.MergeDefaults(KHQOLDB or {}, defaults, "tables"); KHQOL.db = KHQOLDB
  KHQOL:Migrate()
  KHQOL.LabLock:GetStorage()
  if KHQOL.modules.general and KHQOL.modules.general.Initialize then KHQOL.modules.general:Initialize() end
  KHQOL.modules.frameMover:Initialize()
  KHQOL.modules.chatEnhancement:Initialize()
  if KHQOL.CreateSettings then KHQOL:CreateSettings() elseif DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffff4040KHQOL: 설정 UI를 불러오지 못했습니다.|r") end
  KHQOL:CreateMinimapButton()
  C_Timer.After(0, function()
    KHQOL:HideLegacyButtons()
    for key in pairs(KHQOL.db.enabled) do KHQOL:SetEnabled(key, KHQOL:GetEnabled(key), true) end
    if KHQOL.modules.tooltip and KHQOL.modules.tooltip.Initialize then KHQOL.modules.tooltip:Initialize() end
    if KHQOL.modules.cursorTrail and KHQOL.modules.cursorTrail.Initialize then KHQOL.modules.cursorTrail:Initialize() end
    KHQOL:FinishProfileLogin()
    KHQOL:ApplyEditorPositions()
  end)
  SLASH_KHQOL1, SLASH_KHQOL2 = "/kh", "/khqol"
  SlashCmdList.KHQOL = function(message)
    local page = (message or ""):lower():match("^%s*(%S*)")
    if page == "threat" and KHQOL.modules.threat then KHQOL.modules.threat:HandleCommand(message); return end
    if (page == "quest" or page == "questnavigator") and KHQOL.modules.questNavigator then KHQOL.modules.questNavigator:HandleCommand(message); return end
    KHQOL:OpenModule(commandPages[page] or "general")
  end
end)
