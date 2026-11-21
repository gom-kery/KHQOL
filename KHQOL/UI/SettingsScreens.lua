-- Presentation routes only. ModuleRegistry, SavedVariables and diagnostic IDs
-- remain owned by their existing modules and logical routes.
local _,K=...
local UI,R=K.UI,K.UI.SettingsRegistry
local function copy(value) local out={};for k,v in pairs(value or {}) do out[k]=v end;return out end
local categories={
  {"character","캐릭터",""},{"battle","전투",""},{"exploration","퀘스트·지도",""},
  {"social","생활·소통",""},{"display","화면·정보",""},{"settings","설정·프로필",""},
}
local legacyPages={general="common",profiles="profiles",unitFrames="units",partyFrames="party_common",
  bars="experience",alerts="combat",quest="tracker",minimap="minimap",interface="basic",convenience="bags",labs="labs"}
local previousCharacterScreens={units=true,party_common=true,party_frames=true,party_auras=true,party_roles=true,
  cast=true,resource=true,experience=true,environment=true,range=true,combat=true,threat=true,buff=true,campfire=true}
local function originalBuilder(group,id)
  for _,tab in ipairs(UI.SettingsGroups[group] and UI.SettingsGroups[group].tabs or {}) do
    if tab.id==id then return tab.build end
  end
end
function R:BuildScreens()
  if self.screens then return end
  self.screens={};self.screenOrder={};self.defaultScreens={};self.pageNames={}
  local oldPages={};for _,p in ipairs(self.pages) do oldPages[#oldPages+1]=p end
  if self.modules.minimap then oldPages[#oldPages+1]={"minimap","미니맵",""} end
  local aliases={};UI.SettingsNavigation.itemAliases=aliases
  if self.modules.minimap then aliases["general//////미니맵/버튼 정리"]="general//////미니맵/미니맵" end
  if self.modules.questNavigator then aliases["general//////퀘스트/퀘스트 목록 (목표 추적기)"]="general//////퀘스트/길 안내" end
  self.legacyPages=oldPages
  for i=#self.pages,1,-1 do table.remove(self.pages,i) end
  for _,p in ipairs(categories) do
    self.pages[#self.pages+1]=p;self.pageNames[p[1]]=p[2]
    self.groups[p[1]]={};self.orders[p[1]]={};UI:NewSettingsGroup(p[1])
  end
  local function add(group,id,title,owner,sourceGroup,sourceTab,build,family,options)
    local source=sourceGroup and self.groups[sourceGroup] and self.groups[sourceGroup][sourceTab]
    if owner and not K.ModuleRegistry.entries[owner] then return end
    build=build or sourceGroup and originalBuilder(sourceGroup,sourceTab)
    if not build then return end
    local view=copy(source)
    view.group,view.id,view.screen,view.title,view.tabTitle,view.family=group,id,id,title,nil,family
    view.key=owner;view.logicalGroup=sourceGroup;view.logicalTab=sourceTab
    view.logicalRoute={module=owner or id}
    if sourceGroup=="quest" or source and source.sharedTabs then view.logicalRoute.tab=sourceTab end
    view.description="";view.compactDescriptions=source and source.compactDescriptions or false
    view.aliases=(source and source.title or "").." "..(sourceGroup or "")
    if previousCharacterScreens[id] then view.aliases=view.aliases.." 캐릭터·전투" end
    for k,v in pairs(options or {}) do view[k]=v end
    self.screens[id]=view;self.screenOrder[#self.screenOrder+1]=id
    self.groups[group][id]=view;self.orders[group][#self.orders[group]+1]=id
    if owner and not self.defaultScreens[owner] then self.defaultScreens[owner]=id end
    UI.SettingsGroups[group]:RegisterTab(id,nil,build)
    return view
  end
  add("character","units","유닛프레임","unitFrames","unitFrames","units")
  for _,v in ipairs({{"common","공통 표시"},{"frames","크기·배치"},{"auras","버프·디버프"},{"roles","역할별 프레임 프로필"}}) do
    add("character","party_"..v[1],v[2],"partyFrames","partyFrames",v[1],nil,"파티·공격대 프레임")
  end
  add("character","experience","경험치·평판","experienceBar","bars","experience")
  add("character","environment","환경·보호막 타이머","environmentTimer","bars","environment")
  add("character","buff","버프 유지 알림","buffReminder","convenience","buff",nil,"버프·휴식 알림")
  add("character","campfire","모닥불 알림","campfire","alerts","campfire",nil,"버프·휴식 알림")
  add("battle","cast","시전바","castBar","bars","cast")
  add("battle","resource","자원·스윙바","resourceSwing","bars","resource")
  add("battle","range","거리·사거리","range","interface","range")
  add("battle","combat","전투 시작·종료","combatStatus","alerts","combat",nil,"전투·위협 알림")
  add("battle","threat","위협 수치·어그로","threat","alerts","threat",nil,"전투·위협 알림")
  add("exploration","tracker","퀘스트 추적","questNavigator","quest","tracker")
  add("exploration","navigation","퀘스트 길 안내","questNavigator","quest","navigation")
  self.defaultScreens.questNavigator=self.screens.navigation and "navigation" or self.defaultScreens.questNavigator
  add("exploration","minimap","미니맵","minimap","minimap","minimap",nil,nil,{sharedReset=true,scope="계정 공용 미니맵 설정"})
  add("exploration","minimapButtons","미니맵 버튼","minimap","minimap","minimapButtons",nil,nil,{sharedReset=true,scope="계정 공용 미니맵 설정"})
  add("exploration","highlight","오브젝트 강조","objectHighlight","convenience","highlight")
  add("exploration","note","포에버 노트","todo","convenience","note")
  local function convenience(mode) return function(c,y) return K.modules.generalConvenience:BuildSettings(c,y,mode) end end
  add("social","bags","가방·아이템","generalConvenience","convenience","general",convenience("bags"),nil,{hideToggle=true,sharedReset=true})
  add("social","merchant","상점·수리","generalConvenience","convenience","general",convenience("merchant"),nil,{hideToggle=true,sharedReset=true})
  add("social","communication","대화창·버프 감사 알림","generalConvenience","convenience","general",convenience("communication"),"채팅·말머리",{hideToggle=true,sharedReset=true})
  add("social","chat","말머리","convenienceChat","convenience","chat",nil,"채팅·말머리")
  add("social","party","파티·초대","convenienceParty","convenience","party")
  add("social","decline","요청 자동 거절","generalConvenience","convenience","general",convenience("decline"),nil,{hideToggle=true,sharedReset=true})
  add("social","professions","전문기술","professions","convenience","professions",nil,"숙련·전문기술")
  add("social","weaponGuide","무기 전문가 안내","tooltip","interface","tooltip",function(c,y) return K.modules.tooltip:BuildWeaponGuideSettings(c,y) end,"숙련·전문기술",{sharedReset=true})
  self.defaultScreens.tooltip="tooltip"
  self.commands.weapon="weaponGuide"
  add("display","basic","기본 화면·창 배치","basicUI","interface","basic",nil,nil,{sharedReset=true})
  add("display","nativeAlerts","기본 알림 외형","basicUI","interface","basic",function(c,y) return K.modules.basicUI:BuildSettings(c,y,"nativeAlerts") end,nil,{hideToggle=true,hideReset=true,scope="계정 공용"})
  add("display","tooltip","툴팁","tooltip","interface","tooltip")
  add("display","cursor","마우스 잔상","cursorTrail","interface","cursor")
  add("display","clock","시계·정보","clock","interface","clock",nil,nil,{sharedReset=true})
  add("display","timeTools","알람·시간 도구","clock","interface","clock",function(c,y) return K.modules.clock:BuildTimeToolSettings(c,y) end,nil,{sharedReset=true})
  for _,v in ipairs({{"common","공통 설정","general"},{"modules","기능 사용 관리","general"},{"profiles","프로필·백업","profiles"}}) do
    local tool,id=v[1],v[3]
    add("settings",tool,v[2],nil,nil,nil,function(c,y) return UI.SettingsToolBuilders[tool](c,y) end,nil,
      {hideToggle=true,hideReset=true,logicalRoute={module=id}})
  end
  if #UI.SettingsGroups.labs.tabs>0 then
    add("settings","labs","실험실",nil,nil,nil,function(c,y) return UI:BuildLabScreen(c,y) end,nil,
      {hideToggle=true,hideReset=true,logicalRoute={module="labs"}})
  end
  -- Keep the table identity captured by SettingsUI, and one real toggle per owner.
  for i=#self.moduleGroups,1,-1 do table.remove(self.moduleGroups,i) end
  local seen={}
  for _,p in ipairs(categories) do
    local group={title=p[2],items={}}
    for _,id in ipairs(self.orders[p[1]]) do
      local view=self.screens[id];local key=view.key
      if key and not seen[key] and self.defaultScreens[key]==id then
        seen[key]=true
        local source=self.modules[key]
        local legacySection
        for _,oldPage in ipairs(self.legacyPages) do if source and oldPage[1]==source.group then legacySection=oldPage[2] end end
        group.items[#group.items+1]={key,key=="partyFrames" and "파티·공격대 프레임" or key=="generalConvenience" and "가방·아이템 등 공유 설정" or view.title,route=key,navigationOnly=view.hideToggle or view.toggle~=nil,
          logicalTitle=key=="generalConvenience" and "일반 편의 · 공통" or source and source.title,
          logicalSection=legacySection}
      end
    end
    if p[1]=="social" and K.modules.general then
      for _,item in ipairs({{"autoConfirmDestroy","아이템 파괴 자동 입력",true,route="bags",logicalSection="편의 기능"},
        {"chatEnhancement","대화창 편의",true,route="communication",logicalTitle="기본 대화창 편의",logicalSection="편의 기능"},
        {"autoSellJunk","잡템 자동 판매",true,route="merchant",logicalSection="편의 기능"},
        {"autoRepair","자동 수리",true,route="merchant",logicalSection="편의 기능"}}) do group.items[#group.items+1]=item end
    end
    if #group.items>0 then self.moduleGroups[#self.moduleGroups+1]=group end
  end
end
function R:ScreenFor(route,title)
  route=route or {};local key=route.module or route.page or "general"
  local explicit=route.screen and self.screens[route.screen]
  if key=="character" then
    local old=explicit or route.tab and self.screens[route.tab]
    if old and previousCharacterScreens[old.id] then return old end
  end
  if explicit and (key==explicit.logicalRoute.module or key==explicit.id or key==explicit.group or explicit.id=="labs" and (key=="labs" or K.LabLock:IsExperimental(key) or self.modules[key] and self.modules[key].group=="labs")) then return explicit end
  local legacy=route.tab and self.groups[key] and self.groups[key][route.tab] or self.routes[key]
  if legacy and legacy.key and legacy.key~=key then
    local p=copy(route);p.module=legacy.key;p.page=nil;p.screen=nil
    if legacy.group=="quest" or legacy.sharedTabs then p.tab=route.tab or legacy.id end
    return self:ScreenFor(p,title)
  end
  local id
  if self.pageNames[key] then id=UI.SettingsGroups[key].selected
  elseif key=="generalConvenience" then
    local text=(route.section or "").." "..(title or "")
    if text:find("버프",1,true) or text:find("대화창",1,true) or text:find("chatEnhancement",1,true) then id="communication"
    elseif text:find("거절",1,true) or text:find("허용",1,true) or text==" 파티 초대" or text==" 길드 초대" or text==" 결투 요청" then id="decline"
    elseif text:find("판매목록",1,true) or text:find("판매",1,true) or text:find("수리",1,true) or text:find("길드 자금",1,true) then id="merchant"
    else id="bags" end
  elseif key=="clock" then id=(route.section=="알람·타이머·스톱워치" or route.section=="알람·시간 도구") and "timeTools" or "clock"
  elseif key=="basicUI" or key=="nativeAlerts" then
    id=(key=="nativeAlerts" or route.section=="주사위 굴림" or route.section=="알림" or route.section=="도안·아이템 획득 알림") and "nativeAlerts" or "basic"
  elseif key=="weaponGuide" or key=="tooltip" and (route.section=="무기 전문가 안내" or title=="무기 전문가 정보") then id="weaponGuide"
  elseif key=="questTracker" then id="tracker"
  elseif key=="questNavigator" then id=route.tab=="tracker" and "tracker" or "navigation"
  elseif key=="partyFrames" then id="party_"..(route.tab or "common")
  elseif key=="minimap" then id=route.tab=="minimapButtons" and "minimapButtons" or "minimap"
  elseif K.LabLock:IsExperimental(key) or key=="labs" or self.modules[key] and self.modules[key].group=="labs" then id="labs"
  else id=self.defaultScreens[key] or legacyPages[key] or (self.screens[key] and key) end
  return self.screens[id] or self.screens.common
end
function R:NavigationRoute(route,title)
  local p=copy(route);local view=self:ScreenFor(p,title)
  if (p.module=="character" or p.page=="character") and p.tab==view.id and previousCharacterScreens[view.id] then
    p.tab=view.logicalRoute.tab
  end
  p.screen=view.id
  if view.key and not (view.id=="labs") then p.module=view.key;p.page=nil end
  if p.tab and view.logicalGroup and not self.groups[view.logicalGroup][p.tab] then return {module="general",screen="common"} end
  if view.id=="common" and p.module~="general" then p={module="general",screen="common"} end
  return p
end
function R:ScreenRoute(view)
  local route=copy(view.logicalRoute);route.screen=view.id;return route
end
function UI:BuildLabScreen(panel,y)
  local versions={};local current
  function panel:RefreshTab()
    local unlocked=K.LabLock:IsUnlocked();local mode=unlocked and "unlocked" or "locked"
    if current~=mode then
      for _,body in pairs(versions) do body:Hide() end
      if not versions[mode] then
        local body=CreateFrame("Frame",nil,panel);body:SetPoint("TOPLEFT",0,0);body:SetWidth(panel:GetWidth())
        body.settingsRoute={module="labs",screen="labs"};body.uiControls={}
        versions[mode]=body
        local bottom
        if unlocked then bottom=K.LabSettings:BuildSettings(body,0)
        else bottom=K.LabLock:BuildLockedSettings(body,0) end
        body:SetHeight(math.max(1,-bottom));body:HookScript("OnSizeChanged",function() panel:SetHeight(body:GetHeight()) end)
      end
      current=mode
    end
    local body=versions[mode];body:SetWidth(panel:GetWidth());body:Show();panel:SetHeight(body:GetHeight())
    if unlocked and body.SelectSettingsTab then
      local requested=self.requestedLabRoute
      local meta=requested and (R.modules[requested.module] or R.routes[requested.module])
      body.SelectSettingsTab(requested and requested.tab or meta and meta.id or K.LabSettings.selected)
    end
    UI:Refresh(body)
  end
  function panel:ActivateHeader()
    local s=K.settings;if not s then return end
    if K.LabLock:IsUnlocked() then
      local meta=R.groups.labs[K.LabSettings.selected];s:SetModuleHeader(meta)
      s.currentRoute={module=meta and meta.key or "labs",screen="labs"}
    else s:SetModuleHeader(R.screens.labs) end
    if s.labLockButton then s.labLockButton:SetShown(K.LabLock:IsUnlocked()) end
  end
  function panel:SelectLab(route)
    self.requestedLabRoute=route
    self:RefreshTab()
    local body=versions.unlocked
    if not K.LabLock:IsUnlocked() or not body then return end
    local meta=R.modules[route.module] or R.routes[route.module]
    if body.SelectSettingsTab then body.SelectSettingsTab(route.tab or meta and meta.id or K.LabSettings.selected) end
    self:ActivateHeader()
  end
  panel:RefreshTab();return -panel:GetHeight()
end
