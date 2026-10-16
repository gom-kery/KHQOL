local _,K=...
K.Packages={}
K.PackageOrder={}
K.ModuleOwners={}
local function addPackage(name,title,modules)
  K.PackageOrder[#K.PackageOrder+1]=name
  K.Packages[name]={title=title,modules=modules}
  for _,id in ipairs(modules) do K.ModuleOwners[id]=name end
end
addPackage("KHQOL_UnitFrames","기본 UI · 개인 프레임 · 시전바",{"basicUI","frameMover","unitFrames","castBar"})
addPackage("KHQOL_PartyFrames","파티 · 공격대",{"partyFrames"})
addPackage("KHQOL_Clock","시계 · 노트",{"clock","todo"})
addPackage("KHQOL_Convenience","일반 편의 · 대화창",{"general","generalConvenience","chatEnhancement"})
addPackage("KHQOL_Tooltip","툴팁 · 무기 안내",{"tooltip","weaponGuide"})
addPackage("KHQOL_Range","사거리",{"range"})
addPackage("KHQOL_CursorTrail","마우스 잔상",{"cursorTrail"})
addPackage("KHQOL_ResourceSwing","자원 · 스윙바",{"resourceSwing"})
addPackage("KHQOL_ExperienceBar","경험치 바",{"experienceBar"})
addPackage("KHQOL_EnvironmentTimer","환경 타이머",{"environmentTimer"})
addPackage("KHQOL_CombatStatus","전투 상태",{"combatStatus"})
addPackage("KHQOL_Threat","위협 수치",{"threat"})
addPackage("KHQOL_NPCAlert","NPC 알림",{"npcAlert"})
addPackage("KHQOL_PvPAlert","PvP 알림",{"pvpAlert"})
addPackage("KHQOL_Campfire","모닥불",{"campfire"})
addPackage("KHQOL_QuestNavigator","퀘스트",{"questNavigator"})
addPackage("KHQOL_Labs","실험실 · 개발 도구",{"buffReminder","procAlert","objectHighlight","frameInspector","performanceMonitor"})
-- Only KHQOL.toc owns these variables, even when their feature is absent.
K.legacyProfileVariables={clock="ForeverClockDB",buffReminder="ForeverBuffReminderDB",range="FRangeDB",
  resourceSwing="KHQOLResourceSwingDB",campfire="CampfireAlertDB"}
function K:GetPackageStatus(name)
  local package=self.Packages[name]
  if not package then return "알 수 없는 설치 단위","unknown" end
  for _,id in ipairs(package.modules) do
    if self.ModuleRegistry.entries[id] then
      if name=="KHQOL_Labs" and not self.LabLock:IsUnlocked() then return "설치됨 · 실험실 잠금","locked" end
      return "설치됨","installed"
    end
  end
  local api=C_AddOns
  local nameValue=self.PublicCall(api and api.GetAddOnInfo or GetAddOnInfo,name)
  local exists=api and self.PublicCall(api.DoesAddOnExist,name)
  if exists==false or nameValue==nil and (api and api.GetAddOnInfo or GetAddOnInfo) then
    local journal=KHQOLLabDB and KHQOLLabDB.objectHighlight
    if name=="KHQOL_Labs" and type(journal)=="table" and type(journal.records)=="table" and next(journal.records) then return "미설치 · 그래픽 복원 보류 (기록 보존)","missing" end
    return "미설치","missing"
  end
  local state
  if api and api.GetAddOnEnableState then state=self.PublicCall(api.GetAddOnEnableState,name)
  elseif GetAddOnEnableState then state=self.PublicCall(GetAddOnEnableState,self.PublicCall(UnitName,"player"),name) end
  if state==0 then return "게임 애드온 목록에서 비활성","disabled" end
  if nameValue or exists then return "설치됨 · 로드되지 않음 (의존성/버전/오류 확인)","not-loaded" end
  return "로드되지 않음 · 클라이언트 설치 조회 API 없음","unknown"
end
function K:GetModuleAvailability(id)
  local spec=self.ModuleRegistry.entries[id]
  if not spec then
    local owner=self.ModuleOwners[id]
    if owner then local label,status=self:GetPackageStatus(owner);return status,label end
    return "missing","미설치"
  end
  if self.LabLock:IsExperimental(id) and not self.LabLock:IsUnlocked() then return "locked","실험실 잠금" end
  if spec.canRun and spec.canRun(self.modules[id],self)==false then return "unsupported","클라이언트 API 미지원" end
  if not self:GetEnabled(id) and not spec.always then return "off","모듈 OFF" end
  if spec.availability then local status,label=spec.availability(self.modules[id],self);if status then return status,label end end
  return "ready","사용 가능"
end
function K:MigrateProfileSettings(settings)
  for _,id in ipairs(self.ModuleRegistry.order) do
    local spec=self.ModuleRegistry.entries[id]
    if spec.migrateSettings then spec.migrateSettings(self.modules[id],settings,self) end
  end
end
function K:GetNavigationSettings()
  self.db.modules.questNavigator=self.db.modules.questNavigator or {}
  return self.db.modules.questNavigator
end
function K:PrepareInstallation()
  if self.installationReady then return end
  self.ModuleRegistry:Validate()
  self.UI.SettingsRegistry:FinalizeInstallation()
  self.installationReady=true
end
local R=K.ModuleRegistry
function R:AfterApplyProfileConnections()
  for _,id in ipairs(self.order) do
    local spec=self.entries[id]
    if spec.afterApplyProfile then spec.afterApplyProfile(self:Module(id),K) end
  end
  if K.AlertLayout then K.AlertLayout:Initialize() end
end
local event=CreateFrame("Frame")
event:RegisterEvent("VARIABLES_LOADED")
event:SetScript("OnEvent",function(self)
  self:UnregisterAllEvents();K:PrepareInstallation();K:InitializeProfiles()
end)
