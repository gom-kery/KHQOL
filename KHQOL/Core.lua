local _, KHQOL = ...

local defaults = {
  version = 1,
  minimap = { show = true, angle = 225 },
  locked = true, debug = false, settingsWindow={scale=100,opacity=100},
  enabled = { clock = true, todo = true, buffReminder = true, range = true, tooltip = true, resourceSwing = true, campfire = true, cursorTrail = true, castBar = true, combatStatus = true, questNavigator = true, threat = true, pvpAlert = true },
  migrated = {}, modules = {},
  general = {
    centerTextScale = 100, autoSellJunk = false, autoConfirmDestroy = false, chatEnhancement = false,
    autoRepair = false, useGuildFunds = false, declinePartyInvites = false, declineGuildInvites = false,
  },
}

-- WeaponGuide participates only in migration, never modern module dispatch.
local legacy = {weaponGuide="ForeverWeaponGuideDB"}
for key,variable in pairs(KHQOL.legacyProfileVariables) do legacy[key]=variable end
KHQOL.defaults = defaults
defaults.enabled.environmentTimer = false
defaults.enabled.experienceBar = false
defaults.enabled.procAlert = false
defaults.enabled.objectHighlight = false
defaults.enabled.npcAlert = false
defaults.enabled.performanceMonitor = false
-- General convenience features have individual switches, no master switch.
defaults.enabled.basicUI = true
defaults.enabled.unitFrames = true
for _,id in ipairs(KHQOL.ModuleRegistry.order) do
  local spec=KHQOL.ModuleRegistry.entries[id]
  if spec.defaultEnabled~=nil then defaults.enabled[id]=spec.defaultEnabled end
end

function KHQOL:Migrate()
  for key, variable in pairs(legacy) do
    if (self.ModuleRegistry.entries[key] or key=="weaponGuide" and self.ModuleRegistry.entries.tooltip) and not self.db.migrated[key] and type(_G[variable]) == "table" then
      self.db.modules[key] = KHQOL.MergeDefaults({}, _G[variable], "tables")
      self.db.migrated[key] = true
    end
  end
  -- WeaponGuide became a Tooltip information provider.  Preserve the old
  -- database and import its display preference only once into Tooltip.
  if self.ModuleRegistry.entries.tooltip and not self.db.migrated.tooltip then
    local old = type(ForeverWeaponGuideDB) == "table" and ForeverWeaponGuideDB or nil
    self.db.modules.tooltip = KHQOL.MergeDefaults(self.db.modules.tooltip or {}, {
      weaponGuide = old == nil or old.enabled ~= false,
      textSize = old and type(old.fontSize) == "number" and math.max(-3, math.min(3, old.fontSize - 13)) or 0,
    }, "tables")
    self.db.migrated.tooltip = true
  end
  -- Todo remains owned by the original clock DB so all pages, groups and window data survive intact.
  if self.ModuleRegistry.entries.todo and not self.db.migrated.todo and ForeverClockDB and ForeverClockDB.todo then
    self.db.modules.todo = KHQOL.MergeDefaults({}, ForeverClockDB.todo, "tables"); self.db.migrated.todo = true
  end
end

function KHQOL:GetEnabled(key) return self.ModuleRegistry.entries[key]~=nil and self.db and self.db.enabled[key] ~= false or false end

function KHQOL:SetEnabled(key, enabled, reapply)
  if not reapply and not enabled and self.PositionEditor and self.PositionEditor.active then self.PositionEditor:Finish(false) end
  local spec=self.ModuleRegistry.entries[key]
  if not spec then return false end
  if spec.always then
    if key=="generalConvenience" then self.db.enabled[key]=nil end
    return self.ModuleRegistry:Dispatch(key,true)
  end
  -- Lock gates execution without rewriting the saved preference.
  if not reapply and self.LabLock:IsExperimental(key) and not self.LabLock:IsUnlocked() then return false end
  if not reapply and not enabled then self.PositionStore:FinishDrags(key) end
  if not reapply then self.db.enabled[key]=enabled and true or false end
  self.ModuleRegistry:Dispatch(key,enabled)
  if not self.profileApplying and self.settings and self.settings.RefreshModuleState then self.settings:RefreshModuleState(key) end
  return true
end

function KHQOL:HideLegacyButtons()
  local buttons = { ForeverClockMinimapButton, ForeverBuffReminderMinimapButton, KHQOLResourceSwingMinimapButton }
  for _, button in ipairs(buttons) do if button then button:Hide(); button:SetScript("OnShow", function(self) self:Hide() end) end end
end

function KHQOL:CreateMinimapButton()
  if self.minimapButton then return end
  local b = CreateFrame("Button", "KHQOLMinimapButton", Minimap)
  b:SetSize(32, 32); b:RegisterForClicks("LeftButtonUp")
  local icon = b:CreateTexture(nil, "BACKGROUND"); icon:SetTexture("Interface\\AddOns\\KHQOL\\Media\\kh-qol-minimap-button.tga"); icon:SetAllPoints(b)
  b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  b:SetScript("OnClick", function() self:ToggleSettings() end)
  b:SetMovable(true); b:RegisterForDrag("LeftButton")
  function self:UpdateMinimapButton()
    local a = math.rad(self.db.minimap.angle or 225); b:ClearAllPoints(); b:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * 108, math.sin(a) * 108); b:SetShown(self.db.minimap.show)
  end
  b:SetScript("OnDragStart", function(button) button.positionMoving=true; button:StartMoving() end)
  b:SetScript("OnDragStop", function(self)
    if not self.positionMoving then return end
    self.positionMoving=nil
    self:StopMovingOrSizing()
    local x, y = GetCursorPosition(); local scale = Minimap:GetEffectiveScale(); x, y = x / scale, y / scale
    local mx, my = Minimap:GetCenter()
    KHQOL.db.minimap.angle = math.deg(math.atan2(y - my, x - mx))
    KHQOL.PositionStore:Committed(function() KHQOL:UpdateMinimapButton() end)
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
  if KHQOL.loginStarted then return end
  KHQOL.loginStarted=true
  events:UnregisterEvent("PLAYER_LOGIN")
  KHQOL:PrepareInstallation()
  KHQOL:InitializeProfiles()
  KHQOL:RecoverDormantGraphics()
  KHQOLDB = KHQOL.MergeDefaults(KHQOLDB or {}, defaults, "tables"); KHQOL.db = KHQOLDB
  KHQOL:Migrate()
  KHQOL.LabLock:GetStorage()
  KHQOL.ModuleRegistry:Validate()
  for _,id in ipairs(KHQOL.ModuleRegistry.order) do if KHQOL.ModuleRegistry.entries[id].always then KHQOL.ModuleRegistry:Initialize(id) end end
  if KHQOL.CreateSettings then KHQOL:CreateSettings() elseif DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffff4040KHQOL: 설정 UI를 불러오지 못했습니다.|r") end
  KHQOL:CreateMinimapButton()
  C_Timer.After(0, function()
    KHQOL:HideLegacyButtons()
    KHQOL.ModuleRegistry:ApplyProfileConnections()
    KHQOL:SetEnabled("generalConvenience",true,true)
    for _,key in ipairs(KHQOL.ModuleRegistry.order) do
      if KHQOL.db.enabled[key]~=nil then KHQOL:SetEnabled(key, KHQOL:GetEnabled(key), true) end
    end
    KHQOL.ModuleRegistry:AfterApplyProfileConnections()
    KHQOL:FinishProfileLogin()
    KHQOL:ApplyEditorPositions()
  end)
  SLASH_KHQOL1, SLASH_KHQOL2 = "/kh", "/khqol"
  SlashCmdList.KHQOL = function(message)
    local page = (message or ""):lower():match("^%s*(%S*)")
    local id=commandPages[page]
    local spec=id and KHQOL.ModuleRegistry.entries[id]
    if spec and spec.handleCommand then spec.handleCommand(KHQOL.modules[id],message,KHQOL);return end
    KHQOL:OpenModule(commandPages[page] or "general")
  end
end)
