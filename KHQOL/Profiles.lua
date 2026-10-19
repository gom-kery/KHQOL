local ADDON_NAME, KHQOL = ...
local DEFAULT = "기본"
local legacy = KHQOL.legacyProfileVariables
local function installed(key) return KHQOL.ModuleRegistry.entries[key]~=nil end
local managed = KHQOL.profileModuleKeys
local common = {"minimap","locked","debug","enabled","general","settingsWindow"}
local commonKeys={};for _,key in ipairs(common) do commonKeys[key]=true end
local noteUI = {navigation=true,transparent=true,backgroundAlpha=true,fontSize=true,tabSpaces=true,
  closeOnEscape=true,minimap=true,window=true}
local rangePersonal = {"rangeSpellID","rangeSpellName","hunterMeleeSpellID","hunterMeleeSpellName","meleeSpellID","meleeSpellName","rangedSpellID","rangedSpellName"}
-- Only a genuinely empty installation or an explicitly created default profile
-- uses this recipe. Keep legacy module defaults for existing/missing fields.
local installDefaults = {
  settings = {
    enabled = {experienceBar=false,castBar=true,resourceSwing=true,environmentTimer=true,
      npcAlert=false,combatStatus=true,campfire=true,buffReminder=false,pvpAlert=false,
      cursorTrail=true,range=true,threat=true,tooltip=true,clock=false,todo=false,
      questNavigator=true,procAlert=false,objectHighlight=false},
    general = {autoConfirmDestroy=true,chatEnhancement=true,autoSellJunk=true,
      autoRepair=true,declinePartyInvites=false,declineGuildInvites=false},
    modules = {
      castBar = {behavior={hideBlizzard=true},icon={enabled=true},
        spellName={enabled=true},castTime={enabled=true}},
      environmentTimer = {style="hud",timers={BREATH=true}},
      tooltip = {mouseRight=true,showPlayerInfo=true,hideUnitTooltipInCombat=false,weaponGuide=true},
    },
  },
  legacy = {clock={enabled=false},range={size=20,stateText=true,
    stateTexts={available="공격 가능",unavailable="공격 불가",unknown="판정 불가"},
    mouseover={availableText="공격 가능",unavailableText="공격 불가",fontSize=20}}},
}
local savedVariables = {"KHQOLDB","ForeverClockDB","ForeverBuffReminderDB",
  "ForeverWeaponGuideDB","KHQOLResourceSwingDB","CampfireAlertDB",
  "FRangeDB","KHQOLCursorTrailCharDB","KHQOLPartyCharDB","KHQOLLabDB"}
local function overlay(target, source)
  for key,value in pairs(source) do
    if type(value)=="table" then
      if type(target[key])~="table" then target[key]={} end
      overlay(target[key],value)
    else target[key]=value end
  end
  return target
end
local function copy(value, seen)
  if type(value)~="table" then return value end
  seen=seen or {}; if seen[value] then return seen[value] end
  local result={}; seen[value]=result
  for k,v in pairs(value) do result[copy(k,seen)]=copy(v,seen) end
  return result
end
-- Keep every live subtable stable: older settings panels close over them.
-- Profile snapshots never share those tables, or each other's nested tables.
local function replace(target, source)
  for key in pairs(target) do if source[key]==nil then target[key]=nil end end
  for key,value in pairs(source) do
    if type(value)=="table" then
      if type(target[key])~="table" then target[key]={} end
      replace(target[key],value)
    else target[key]=value end
  end
  return target
end
KHQOL.CopyProfileValue = copy
KHQOL.ReplaceProfileValue = replace
-- Fields unknown to this module version must survive older profile snapshots.
function KHQOL.PreserveUnknownProfileValue(target, source, defaults)
  for key,value in pairs(target) do
    if source[key]==nil and defaults[key]==nil then source[key]=copy(value)
    elseif type(value)=="table" and type(source[key])=="table" then
      KHQOL.PreserveUnknownProfileValue(value,source[key],type(defaults[key])=="table" and defaults[key] or {})
    end
  end
  return source
end
function KHQOL:GetProfileCharacterKey()
  local name,realm
  if UnitFullName then name,realm=UnitFullName("player") end
  name=name or (UnitName and UnitName("player"))
  realm=(realm and realm~="" and realm) or (GetRealmName and GetRealmName())
  if not name or not realm then return end
  return name.."-"..realm
end
function KHQOL:ProfileMessage(message)
  if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffffd54aKHQOL 프로필:|r "..message) end
end
function KHQOL:CanChangeProfile()
  if self.PositionEditor and self.PositionEditor.active then return false,"위치 편집을 먼저 완료하거나 취소하세요." end
  if (InCombatLockdown and InCombatLockdown()) or (UnitAffectingCombat and UnitAffectingCombat("player")) then
    return false,"전투 중에는 프로필을 변경할 수 없습니다."
  end
  return true
end
function KHQOL:ValidateProfileName(name)
  if type(name)~="string" then return nil,"프로필 이름을 입력하세요." end
  -- Explicit ASCII classes: Windows Lua %c/%s can classify UTF-8 continuation
  -- bytes as controls/whitespace and reject or truncate valid Korean names.
  name=name:gsub("^[ \t\r\n\v\f]+",""):gsub("[ \t\r\n\v\f]+$","")
  local count=0
  for _ in name:gmatch("[%z\1-\127\194-\244][\128-\191]*") do count=count+1 end
  if count==0 then return nil,"프로필 이름을 입력하세요." end
  if count>24 then return nil,"프로필 이름은 한글 포함 24자까지 입력할 수 있습니다." end
  if name:find("[%z\1-\31\127|]") then return nil,"제어 문자와 | 문자는 사용할 수 없습니다." end
  if self.db.profiles[name]~=nil then return nil,"같은 이름의 프로필이 이미 있습니다." end
  return name
end
local function filteredClock(db)
  local result={}
  -- Do not copy potentially large note/checklist content merely to discard it.
  for key,value in pairs(db or {}) do if key~="todo" then result[key]=copy(value) end end
  result.todo={}
  for key in pairs(noteUI) do result.todo[key]=copy(db and db.todo and db.todo[key]) end
  if result.clockTools then result.clockTools.alarmMessage=nil end
  return result
end
local function filteredBuff(db)
  local result={classes={}}
  for key,value in pairs(db or {}) do
    if key~="classes" and key~="selectedClass" then result[key]=copy(value) end
  end
  for token,class in pairs(db and db.classes or {}) do
    if type(class)=="table" then
      result.classes[token]={}
      for key,value in pairs(class) do if key~="buffs" then result.classes[token][key]=copy(value) end end
    end
  end
  return result
end
local function filteredRange(db)
  local result=copy(db or {})
  for _,key in ipairs(rangePersonal) do result[key]=nil end
  return result
end
-- Auxiliary fields remain in the legacy table so old profiles keep their
-- values. They are active with UnitFrames even when ResourceSwing is absent.
local function copyPlayerAuxFields(target,source)
  if not installed("unitFrames") or not KHQOL.PlayerAux then return end
  for key,default in pairs(KHQOL.PlayerAux.defaults) do
    local value=source and source[key]
    if value==nil then value=default end
    target[key]=copy(value)
  end
end
local function clearRetiredOptions(settings)
  if settings.enabled then settings.enabled.generalConvenience=nil end
  if settings.general then settings.general.autoSellJunkReport=nil end
end
local function captureAbsentAndUnknownSettings(self,result,previous)
  -- Carry forward extension data without profiling legacy content mirrors.
  if type(previous)=="table" then
    for key,value in pairs(previous) do if result[key]==nil and key~="resourceColor" and key~="cursorColor" then result[key]=copy(value) end end
    for key,value in pairs(previous.settings or {}) do if key~="modules" and not commonKeys[key] then result.settings[key]=copy(value) end end
    for key,value in pairs(previous.legacy or {}) do if not legacy[key] or not installed(key) then result.legacy[key]=copy(value) end end
    for key,value in pairs(previous.settings and previous.settings.modules or {}) do
      if not self.ModuleRegistry.entries[key] then result.settings.modules[key]=copy(value) end
    end
  end
  for key,value in pairs(self.db.modules or {}) do
    if not self.ModuleRegistry.entries[key] and not legacy[key] and key~="todo" and key~="weaponGuide" and result.settings.modules[key]==nil then result.settings.modules[key]=copy(value) end
  end
end
function KHQOL:CaptureProfile()
  self:MigrateProfileSettings(self.db)
  local previous=self.db.profiles and self.db.profiles[self.currentProfileName]
  local result={settings={modules={}},legacy={}}
  for _,key in ipairs(common) do result.settings[key]=copy(self.db[key]) end
  captureAbsentAndUnknownSettings(self,result,previous)
  for _,key in ipairs(managed) do result.settings.modules[key]=self.ModuleRegistry:CaptureSettings(key) end
  clearRetiredOptions(result.settings)
  if installed("clock") or result.legacy.clock==nil then result.legacy.clock=filteredClock(ForeverClockDB) end
  if installed("buffReminder") or result.legacy.buffReminder==nil then result.legacy.buffReminder=filteredBuff(ForeverBuffReminderDB) end
  if installed("range") or result.legacy.range==nil then result.legacy.range=filteredRange(FRangeDB) end
  if installed("resourceSwing") or result.legacy.resourceSwing==nil then result.legacy.resourceSwing=copy(KHQOLResourceSwingDB or {}) end
  copyPlayerAuxFields(result.legacy.resourceSwing,KHQOLResourceSwingDB)
  local overrides=result.legacy.resourceSwing.resourceColorOverrides or {}
  if not installed("resourceSwing") and previous then result.resourceColor=copy(previous.resourceColor) else result.resourceColor=copy(overrides[self.profileCharacter or self:GetProfileCharacterKey()]) end
  if installed("resourceSwing") then result.legacy.resourceSwing.resourceColorOverrides=nil end
  if installed("campfire") or result.legacy.campfire==nil then result.legacy.campfire=copy(CampfireAlertDB or {}) end
  result.cursorColor=not installed("cursorTrail") and previous and copy(previous.cursorColor) or copy(KHQOLCursorTrailCharDB or {})
  if not installed("general") and previous and previous.settings and previous.settings.general then result.settings.general=copy(previous.settings.general) end
  if previous and previous.settings and previous.settings.enabled then
    for key,value in pairs(previous.settings.enabled) do if not installed(key) then result.settings.enabled[key]=copy(value) end end
  end
  return result
end
function KHQOL:MakeDefaultProfile(legacyDefaults)
  local m=self.modules
  local result={settings={modules={}},legacy={},cursorColor={}}
  for _,key in ipairs(common) do result.settings[key]=copy(self.defaults[key]) end
  for _,key in ipairs(managed) do result.settings.modules[key]=self.ModuleRegistry:DefaultSettings(key) end
  if m.questNavigator then result.settings.modules.questNavigator.questTracker=copy(m.questNavigator.trackerDefaults or {}) end
  result.legacy.clock=filteredClock(m.clock and m.clock.DEFAULTS)
  result.legacy.buffReminder=filteredBuff(ForeverBuffReminder and ForeverBuffReminder.profileDefaults)
  result.legacy.range=filteredRange(m.range and m.range.defaults)
  result.legacy.resourceSwing=copy(m.resourceSwing and m.resourceSwing.defaults or {})
  copyPlayerAuxFields(result.legacy.resourceSwing,KHQOL.PlayerAux and KHQOL.PlayerAux.defaults)
  result.legacy.resourceSwing.resourceColorOverrides=nil
  result.legacy.campfire=copy(m.campfire and m.campfire.defaults or {})
  if not legacyDefaults then
    local recipe=copy(installDefaults)
    for key in pairs(recipe.settings.modules) do if not installed(key) then recipe.settings.modules[key]=nil end end
    for key in pairs(recipe.legacy) do if not installed(key) then recipe.legacy[key]=nil end end
    overlay(result,recipe)
  end
  return result
end
function KHQOL:SaveCurrentProfile()
  if self.UI and (self.UI.settingDepth or 0)>0 then return end
  if self.profileApplying or self.profileResetting or not self.profilesReady or not self.db or not self.db.profiles then return end
  local fc=self.modules.clock
  if fc and fc.db and fc.SaveTodoPage then fc:SaveTodoPage() end
  self.db.profiles[self.currentProfileName]=self:CaptureProfile()
  self:RefreshRuntimeProfile()
end
function KHQOL:RefreshRuntimeProfile()
  local view={settings={modules=self.db.modules},legacy={},cursorColor=KHQOLCursorTrailCharDB}
  for _,key in ipairs(common) do view.settings[key]=self.db[key] end
  for key,variable in pairs(legacy) do view.legacy[key]=_G[variable] end
  self.currentProfile=view
end
function KHQOL:GetCurrentProfile() return self.currentProfile end
function KHQOL:GetCurrentProfileName() return self.currentProfileName or DEFAULT end
function KHQOL:GetProfileOptions(excludeDefault)
  local names={}
  for name,profile in pairs(self.db.profiles) do
    if type(name)=="string" and type(profile)=="table" and not (excludeDefault and name==DEFAULT) then names[#names+1]=name end
  end
  table.sort(names,function(a,b) if a==b then return false elseif a==DEFAULT then return true elseif b==DEFAULT then return false end; return a<b end)
  local options={}
  if excludeDefault then options[1]={value="",text="삭제할 프로필 선택"} end
  for _,name in ipairs(names) do options[#options+1]={value=name,text=name} end
  return options
end
local function retainContentAndCharacterData(self,profile)
  -- Leave content in its original SavedVariables and account/character scope.
  local clock=type(ForeverClockDB)=="table" and ForeverClockDB or {}
  local todo=type(clock.todo)=="table" and clock.todo or {}
  local clockSettings=profile.legacy.clock
  for key,value in pairs(todo) do if not noteUI[key] then clockSettings.todo[key]=copy(value) end end
  clockSettings.clockTools=clockSettings.clockTools or {}
  clockSettings.clockTools.alarmMessage=clock.clockTools and clock.clockTools.alarmMessage or ""
  local buffSettings=profile.legacy.buffReminder
  buffSettings.classes=buffSettings.classes or {}
  for key,class in pairs(ForeverBuffReminderDB and ForeverBuffReminderDB.classes or {}) do
    if type(class)=="table" then
      buffSettings.classes[key]=buffSettings.classes[key] or {}
      buffSettings.classes[key].buffs=copy(class.buffs or {})
    end
  end
  local _,class=UnitClass("player"); buffSettings.selectedClass=class
  for _,key in ipairs(rangePersonal) do profile.legacy.range[key]=FRangeDB and FRangeDB[key] end
  local resource=profile.legacy.resourceSwing
  resource.resourceColorOverrides=copy(KHQOLResourceSwingDB and KHQOLResourceSwingDB.resourceColorOverrides or {})
  resource.resourceColorOverrides[self.profileCharacter]=copy(profile.resourceColor)
  resource.resourceColorsMigrated=true
end
function KHQOL:LoadProfileSettings(profile)
  profile=copy(profile)
  profile.settings=profile.settings or {}
  self:MigrateProfileSettings(profile.settings)
  local savedEnabled=profile.settings.enabled or {}
  profile.settings.enabled=savedEnabled
  for key,value in pairs(self.db.enabled or {}) do if not installed(key) and savedEnabled[key]==nil then savedEnabled[key]=copy(value) end end
  KHQOL.MergeDefaults(profile,self:MakeDefaultProfile(true))
  local settings=profile.settings
  clearRetiredOptions(settings)
  for _,key in ipairs(common) do
    if key~="general" or installed("general") then
    if type(settings[key])=="table" then
      self.db[key]=replace(type(self.db[key])=="table" and self.db[key] or {},settings[key])
    else self.db[key]=settings[key] end
    end
  end
  self.db.modules=self.db.modules or {}
  for _,key in ipairs(managed) do
    self.ModuleRegistry:RestoreSettings(key,settings.modules[key])
  end
  -- Uninstalled module snapshots are kept; absent snapshots do not erase live data.
  for key,value in pairs(settings.modules or {}) do
    if not self.ModuleRegistry.entries[key] then
      if type(value)=="table" and type(self.db.modules[key])=="table" then KHQOL.MergeDefaults(self.db.modules[key],value)
      elseif self.db.modules[key]==nil then self.db.modules[key]=copy(value) end
    end
  end
  retainContentAndCharacterData(self,profile)
  for key,variable in pairs(legacy) do
    if installed(key) then _G[variable]=replace(type(_G[variable])=="table" and _G[variable] or {},profile.legacy[key]) end
  end
  if not installed("resourceSwing") and installed("unitFrames") then
    KHQOLResourceSwingDB=KHQOLResourceSwingDB or {}
    copyPlayerAuxFields(KHQOLResourceSwingDB,profile.legacy.resourceSwing)
  end
  if installed("cursorTrail") then KHQOLCursorTrailCharDB=replace(type(KHQOLCursorTrailCharDB)=="table" and KHQOLCursorTrailCharDB or {},profile.cursorColor) end
  self:RefreshRuntimeProfile()
end
function KHQOL:InitializeProfiles()
  if not self.installationReady then return false end
  if self.profilesReady then return true end
  -- Decide before any normalizer creates SavedVariables, even if the character
  -- identity is delayed. Empty/false/legacy-only saved values count as existing.
  if self.isNewInstall==nil then
    self.isNewInstall=true
    for _,variable in ipairs(savedVariables) do
      if _G[variable]~=nil then self.isNewInstall=false; break end
    end
  end
  if self.isNewInstall and not self.installDefaultsSeeded then
    KHQOLDB=KHQOL.MergeDefaults(KHQOLDB or {},installDefaults.settings)
    for key,values in pairs(installDefaults.legacy) do
      local variable=legacy[key]
      if installed(key) then _G[variable]=KHQOL.MergeDefaults(_G[variable] or {},values) end
    end
    self.installDefaultsSeeded=true
  end
  local character=self:GetProfileCharacterKey()
  if not character then self.profileDeferred=true; return false end
  KHQOLDB=KHQOL.MergeDefaults(type(KHQOLDB)=="table" and KHQOLDB or {},self.defaults,"tables")
  self.db=KHQOLDB
  self:MigrateProfileSettings(self.db)
  for _,profile in pairs(self.db.profiles or {}) do if type(profile)=="table" and profile.settings then self:MigrateProfileSettings(profile.settings) end end
  self.db.enabled.generalConvenience=nil
  self.db.general.autoSellJunkReport=nil
  for _,profile in pairs(self.db.profiles or {}) do
    local settings=type(profile)=="table" and profile.settings
    if settings then
      clearRetiredOptions(settings)
    end
  end
  local fresh=self.db.profileSchema~=1
  if type(self.db.profiles)~="table" then self.db.profiles={} end
  if type(self.db.characterProfiles)~="table" then self.db.characterProfiles={} end
  if type(self.db.globalData)~="table" then self.db.globalData={} end
  local global=self.db.globalData
  global.profileCharacters=type(global.profileCharacters)=="table" and global.profileCharacters or {}
  if not global.profileCharacters[character] then
    -- Preserve per-character combat spell choices outside shared UI profiles.
    global.profileCharacters[character]={range=copy(FRangeDB or {}),cursorColor=copy(KHQOLCursorTrailCharDB or {})}
  end
  if type(self.db.profiles[DEFAULT])~="table" then
    self.db.profiles[DEFAULT]=self:CaptureProfile()
  end
  local name=self.db.characterProfiles[character]
  if type(name)~="string" or type(self.db.profiles[name])~="table" then name=DEFAULT end
  self.profileCharacter=character; self.currentProfileName=name
  self.db.characterProfiles[character]=name; self.db.profileSchema=1
  self.profilesReady=true
  -- On the very first upgrade, legacy normalizers run before capturing the
  -- final defaults. Inserting new defaults earlier would mask old migrations.
  if not fresh then self:LoadProfileSettings(self.db.profiles[name]) else self:RefreshRuntimeProfile() end
  self.profileNeedsApply=self.profileDeferred and not fresh
  return true
end
function KHQOL:FinishProfileLogin()
  if self.profileNeedsApply then self.profileNeedsApply=nil; self:ApplyProfileModules() end
  self.profileLoginComplete=true; self:RefreshRuntimeProfile(); self:SaveCurrentProfile()
end
function KHQOL:CloseProfileEditors()
  self.profileClosingEditors=true
  if self.UI then self.UI:CancelInputs();self.UI:CancelDrafts();self.UI:CloseColorPicker();self.UI:CloseDropdown() end
  self.PositionStore:FinishDrags()
  -- Finish a drag using the OLD settings, never after loading the new position.
  if self.NavigationUI and self.NavigationUI.dragging then self.NavigationUI:SavePosition() end
  for _,module in pairs(self.modules) do
    if module.dragging and module.SavePosition then module:SavePosition() end
  end
  for _,id in ipairs(self.ModuleRegistry.order) do
    local spec=self.ModuleRegistry.entries[id]
    if spec.closeEditors then spec.closeEditors(self.modules[id],self) end
  end
  self.profileClosingEditors=nil
end
function KHQOL:ApplyProfileModules()
  self.ModuleRegistry:ApplyProfileConnections()
  for _,key in ipairs(self.ModuleRegistry.order) do
    local spec=self.ModuleRegistry.entries[key]
    if spec.always or self.defaults.enabled[key]~=nil then self:SetEnabled(key,self:GetEnabled(key),true) end
  end
  self.ModuleRegistry:AfterApplyProfileConnections()
  self:ApplyEditorPositions()
  self:UpdateMinimapButton();self:HideLegacyButtons()
  if self.UI.RefreshSettingsViews then self.UI:RefreshSettingsViews() end
end
function KHQOL:SelectProfile(name)
  local allowed,reason=self:CanChangeProfile(); if not allowed then return false,reason end
  if type(name)~="string" or type(self.db.profiles[name])~="table" then return false,"프로필을 찾을 수 없습니다." end
  if name==self.currentProfileName then return true end
  self:CloseProfileEditors(); self:SaveCurrentProfile()
  local previousName=self.currentProfileName
  local previous=self:CaptureProfile()
  self.profileApplying=true
  self.profileGeneration=(self.profileGeneration or 0)+1
  local ok,errorMessage=pcall(function()
    self.ModuleRegistry:ProfileChanged()
    self.currentProfileName=name; self.db.characterProfiles[self.profileCharacter]=name
    self:LoadProfileSettings(self.db.profiles[name]); self:ApplyProfileModules()
  end)
  if not ok then
    self.currentProfileName=previousName; self.db.characterProfiles[self.profileCharacter]=previousName
    self:LoadProfileSettings(previous)
    pcall(self.ApplyProfileModules,self)
  end
  self.profileApplying=false; self:SaveCurrentProfile()
  if self.RefreshProfileControls then self:RefreshProfileControls() end
  if not ok then return false,"프로필 적용 중 오류가 발생해 이전 설정으로 복원했습니다: "..tostring(errorMessage) end
  return true
end
function KHQOL:CreateProfile(name, duplicate)
  local allowed,reason=self:CanChangeProfile(); if not allowed then return false,reason end
  local valid,errorMessage=self:ValidateProfileName(name); if not valid then return false,errorMessage end
  self:CloseProfileEditors(); self:SaveCurrentProfile()
  self.db.profiles[valid]=duplicate and copy(self.db.profiles[self.currentProfileName]) or self:MakeDefaultProfile()
  local ok,message=self:SelectProfile(valid)
  if not ok then self.db.profiles[valid]=nil end
  return ok,message
end
function KHQOL:DeleteProfile(name)
  local allowed,reason=self:CanChangeProfile(); if not allowed then return false,reason end
  if name==DEFAULT then return false,"기본 프로필은 삭제할 수 없습니다." end
  if type(name)~="string" or type(self.db.profiles[name])~="table" then return false,"프로필을 찾을 수 없습니다." end
  if self.currentProfileName==name then
    local ok,message=self:SelectProfile(DEFAULT); if not ok then return false,message end
  end
  for character,selected in pairs(self.db.characterProfiles) do
    if selected==name then self.db.characterProfiles[character]=DEFAULT end
  end
  self.db.profiles[name]=nil
  if self.RefreshProfileControls then self:RefreshProfileControls() end
  return true
end
function KHQOL:ResetProfileModule(key)
  if self.LabLock:IsExperimental(key) and not self.LabLock:IsUnlocked() then return false,"실험실 개발자 잠금을 먼저 해제하세요." end
  if not self.UI.SettingsRegistry.modules[key] then return false,"초기화할 모듈을 찾을 수 없습니다." end
  local allowed,reason=self:CanChangeProfile(); if not allowed then return false,reason end
  self:CloseProfileEditors(); self:SaveCurrentProfile()
  local profile=self:CaptureProfile(); local defaults=self:MakeDefaultProfile()
  if key=="clock" then
    local note=profile.legacy.clock.todo; profile.legacy.clock=copy(defaults.legacy.clock); profile.legacy.clock.todo=note
  elseif key=="todo" then profile.legacy.clock.todo=copy(defaults.legacy.clock.todo)
  elseif legacy[key] then
    local auxiliary=key=="resourceSwing" and copy(profile.legacy.resourceSwing)
    profile.legacy[key]=copy(defaults.legacy[key])
    if auxiliary then copyPlayerAuxFields(profile.legacy.resourceSwing,auxiliary) end
  else
    local spec=self.ModuleRegistry.entries[key]
    if spec and spec.resetProfile then spec.resetProfile(self.modules[key],profile,defaults,self)
    else
      -- Reset known settings while retaining forward-compatible unknown keys.
      local value=copy(profile.settings.modules[key] or {})
      profile.settings.modules[key]=overlay(value,defaults.settings.modules[key] or {})
    end
  end
  if key=="unitFrames" then copyPlayerAuxFields(profile.legacy.resourceSwing,defaults.legacy.resourceSwing) end
  -- This new module only has an ON/OFF preference: reset means OFF + restore.
  if key=="objectHighlight" then
    self.modules.objectHighlight:CancelPending()
    profile.settings.enabled.objectHighlight=false
  end
  if key=="cursorTrail" then profile.cursorColor={} end
  if key=="resourceSwing" then profile.resourceColor=nil end
  local temporary=self:CaptureProfile()
  self.profileApplying=true; self.profileGeneration=(self.profileGeneration or 0)+1
  if key=="generalConvenience" then
    profile.settings.general.declinePartyInvites=false
    profile.settings.general.declineGuildInvites=false
  end
  local ok,errorMessage=pcall(function() self.ModuleRegistry:ProfileChanged();self:LoadProfileSettings(profile); self:ApplyProfileModules() end)
  if not ok then self:LoadProfileSettings(temporary); pcall(self.ApplyProfileModules,self) end
  self.profileApplying=false; self:SaveCurrentProfile()
  if not ok then return false,"초기화 중 오류가 발생해 이전 설정으로 복원했습니다: "..tostring(errorMessage) end
  return true
end
local events=CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGOUT")
events:SetScript("OnEvent",function() KHQOL:SaveCurrentProfile() end)
