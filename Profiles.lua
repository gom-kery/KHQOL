local ADDON_NAME, KHQOL = ...
local DEFAULT = "기본"
local legacy = {clock="ForeverClockDB", buffReminder="ForeverBuffReminderDB",
  range="FRangeDB", resourceSwing="KHQOLResourceSwingDB", campfire="CampfireAlertDB"}
local managed = {"tooltip","cursorTrail","castBar","combatStatus","questNavigator","threat","pvpAlert"}
local common = {"minimap","locked","debug","enabled","general"}
managed[#managed+1]="environmentTimer"
managed[#managed+1]="experienceBar"
managed[#managed+1]="procAlert"
managed[#managed+1]="npcAlert"
local noteUI = {navigation=true,transparent=true,backgroundAlpha=true,fontSize=true,tabSpaces=true,
  closeOnEscape=true,minimap=true,window=true}
local rangePersonal = {"rangeSpellID","rangeSpellName","hunterMeleeSpellID"}
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
function KHQOL:CaptureProfile()
  local result={settings={modules={}},legacy={}}
  for _,key in ipairs(common) do result.settings[key]=copy(self.db[key]) end
  for _,key in ipairs(managed) do result.settings.modules[key]=copy(self.db.modules and self.db.modules[key]) end
  result.legacy.clock=filteredClock(ForeverClockDB)
  result.legacy.buffReminder=filteredBuff(ForeverBuffReminderDB)
  result.legacy.range=filteredRange(FRangeDB)
  result.legacy.resourceSwing=copy(KHQOLResourceSwingDB or {})
  local overrides=result.legacy.resourceSwing.resourceColorOverrides or {}
  result.resourceColor=copy(overrides[self.profileCharacter or self:GetProfileCharacterKey()])
  result.legacy.resourceSwing.resourceColorOverrides=nil
  result.legacy.campfire=copy(CampfireAlertDB or {})
  result.cursorColor=copy(KHQOLCursorTrailCharDB or {})
  return result
end
function KHQOL:MakeDefaultProfile()
  local m=self.modules
  local result={settings={modules={}},legacy={},cursorColor={}}
  for _,key in ipairs(common) do result.settings[key]=copy(self.defaults[key]) end
  for _,key in ipairs(managed) do result.settings.modules[key]=copy(m[key].defaults or {}) end
  result.settings.modules.questNavigator.questTracker=copy(m.questNavigator.trackerDefaults or {})
  result.legacy.clock=filteredClock(m.clock.DEFAULTS)
  result.legacy.buffReminder=filteredBuff(ForeverBuffReminder and ForeverBuffReminder.profileDefaults)
  result.legacy.range=filteredRange(m.range.defaults)
  result.legacy.resourceSwing=copy(m.resourceSwing.defaults or {})
  result.legacy.resourceSwing.resourceColorOverrides=nil
  result.legacy.campfire=copy(m.campfire.defaults or {})
  return result
end
function KHQOL:SaveCurrentProfile()
  if self.profileApplying or self.profileResetting or not self.profilesReady or not self.db or not self.db.profiles then return end
  local fc=self.modules.clock
  if fc.db and fc.SaveTodoPage then fc:SaveTodoPage() end
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
function KHQOL:LoadProfileSettings(profile)
  profile=copy(profile)
  KHQOL.MergeDefaults(profile,self:MakeDefaultProfile(),"types")
  local settings=profile.settings
  for _,key in ipairs(common) do
    if type(settings[key])=="table" then
      self.db[key]=replace(type(self.db[key])=="table" and self.db[key] or {},settings[key])
    else self.db[key]=settings[key] end
  end
  self.db.modules=self.db.modules or {}
  for _,key in ipairs(managed) do
    self.db.modules[key]=replace(type(self.db.modules[key])=="table" and self.db.modules[key] or {},settings.modules[key])
  end
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
  for key,variable in pairs(legacy) do
    _G[variable]=replace(type(_G[variable])=="table" and _G[variable] or {},profile.legacy[key])
  end
  KHQOLCursorTrailCharDB=replace(type(KHQOLCursorTrailCharDB)=="table" and KHQOLCursorTrailCharDB or {},profile.cursorColor)
  self:RefreshRuntimeProfile()
end
function KHQOL:InitializeProfiles()
  if self.profilesReady then return true end
  local character=self:GetProfileCharacterKey()
  if not character then self.profileDeferred=true; return false end
  KHQOLDB=KHQOL.MergeDefaults(type(KHQOLDB)=="table" and KHQOLDB or {},self.defaults,"tables")
  self.db=KHQOLDB
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
    self.db.profiles[DEFAULT]=fresh and self:CaptureProfile() or self:MakeDefaultProfile()
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
  if self.UI then self.UI:CloseDropdown() end
  if ColorPickerFrame and ColorPickerFrame:IsShown() then ColorPickerFrame:Hide() end
  if GetCurrentKeyBoardFocus then
    local box=GetCurrentKeyBoardFocus(); if box and box.ClearFocus then box:ClearFocus() end
  end
  -- Finish a drag using the OLD settings, never after loading the new position.
  if self.NavigationUI and self.NavigationUI.dragging then self.NavigationUI:SavePosition() end
  for _,module in pairs(self.modules) do
    if module.dragging and module.SavePosition then module:SavePosition() end
  end
  if self.modules.pvpAlert.moving then self.modules.pvpAlert:SetMoving(false) end
end
function KHQOL:ApplyProfileModules()
  local m=self.modules
  -- Cancel non-setting previews and outstanding old-profile work first.
  if m.general.CloseMerchantWork then m.general:CloseMerchantWork() end
  if m.general.CancelInviteDecline then m.general:CancelInviteDecline("party"); m.general:CancelInviteDecline("guild") end
  m.general:ApplyCenterTextScale()
  local fc=m.clock; fc.db=ForeverClockDB
  fc:ApplyAll()
  if fc.ApplyProfessionFont then fc:ApplyProfessionFont() end
  if fc.professionsPanel and fc.professionsPanel:IsShown() then fc:RenderProfessions() end
  if fc.UpdateProfessionsVisibility then fc:UpdateProfessionsVisibility() end
  if fc.todoFrame then
    local p=fc.db.todo.window
    fc.todoFrame:ClearAllPoints(); fc.todoFrame:SetPoint(p.point,UIParent,p.relativePoint,p.x,p.y)
    fc.todoFrame:SetSize(p.width,p.height); fc:UpdateTodoEscapeBinding(); fc:RefreshTodo()
  end
  fc:UpdateTodoMinimapButton()
  fc:RefreshTodoNavigation()
  if fc.RefreshClockTools then fc:RefreshClockTools() end
  local fbr=ForeverBuffReminder
  fbr:StopCountdown(); fbr.testMode=false; fbr:InitializeDatabase()
  fbr.anchor:ClearAllPoints()
  local p=ForeverBuffReminderDB.position
  fbr.anchor:SetPoint(p.point,UIParent,p.point,p.x,p.y); fbr:SetLocked(ForeverBuffReminderDB.locked)
  m.range:InitializeDB(); m.range.testState=nil
  m.range.Range:ClearActionSlotCache()
  m.range.Display:ApplyLayout(true)
  m.range:RefreshDisplay(true)
  m.cursorTrail.color=nil; m.cursorTrail:ApplyAppearance()
  m.resourceSwing:ApplyProfile()
  m.campfire.db=CampfireAlertDB; m.campfire:HideDiscovery(); m.campfire:ApplyLayout()
  m.campfire.ui.complete:Hide()
  local cp=m.campfire.db.position
  m.campfire.ui.root:ClearAllPoints(); m.campfire.ui.root:SetPoint(cp.point,UIParent,cp.point,cp.x,cp.y)
  if not m.campfire.db.locked then m.campfire.ui.discovery:Show(); m.campfire.ui.complete:Hide() end
  m.combatStatus:StopVisual()
  m.threat:StopTest(); m.threat:ResetAggroAlert()
  m.pvpAlert:SetMoving(false); m.pvpAlert:StopTest()
  for key in pairs(self.defaults.enabled) do self:SetEnabled(key,self:GetEnabled(key)) end
  if not self:GetEnabled("buffReminder") then
    for _,frame in ipairs(fbr.alertFrames or {}) do frame:Hide() end
    fbr.anchor:Hide(); fbr:StopCountdown()
  end
  -- These frames use dynamic options but need layout refreshed even when OFF.
  m.castBar:GetDB(); m.castBar:ApplyLayout(); m.castBar:RefreshControls()
  m.tooltip:RefreshVisibleTooltip()
  self:ApplyEditorPositions()
  self:UpdateMinimapButton(); self:HideLegacyButtons()
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
  if not self.UI.SettingsRegistry.modules[key] then return false,"초기화할 모듈을 찾을 수 없습니다." end
  local allowed,reason=self:CanChangeProfile(); if not allowed then return false,reason end
  self:CloseProfileEditors(); self:SaveCurrentProfile()
  local profile=self:CaptureProfile(); local defaults=self:MakeDefaultProfile()
  if key=="clock" then
    local note=profile.legacy.clock.todo; profile.legacy.clock=copy(defaults.legacy.clock); profile.legacy.clock.todo=note
  elseif key=="todo" then profile.legacy.clock.todo=copy(defaults.legacy.clock.todo)
  elseif legacy[key] then profile.legacy[key]=copy(defaults.legacy[key])
  else profile.settings.modules[key]=copy(defaults.settings.modules[key]) end
  if key=="cursorTrail" then profile.cursorColor={} end
  if key=="resourceSwing" then profile.resourceColor=nil end
  local temporary=self:CaptureProfile()
  self.profileApplying=true; self.profileGeneration=(self.profileGeneration or 0)+1
  local ok,errorMessage=pcall(function() self:LoadProfileSettings(profile); self:ApplyProfileModules() end)
  if not ok then self:LoadProfileSettings(temporary); pcall(self.ApplyProfileModules,self) end
  self.profileApplying=false; self:SaveCurrentProfile()
  if not ok then return false,"초기화 중 오류가 발생해 이전 설정으로 복원했습니다: "..tostring(errorMessage) end
  return true
end
-- Registered before all legacy initialization frames: restore the selected
-- settings before ADDON_LOADED/PLAYER_LOGIN creates their existing HUDs.
local events=CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED"); events:RegisterEvent("PLAYER_LOGOUT")
events:SetScript("OnEvent",function(_,event,name)
  if event=="ADDON_LOADED" and name==ADDON_NAME then KHQOL:InitializeProfiles()
  elseif event=="PLAYER_LOGOUT" then KHQOL:SaveCurrentProfile() end
end)
