local _, KHQOL = ...
local R={modules={},groups={},orders={},routes={},commands={},moduleGroups={}}
KHQOL.UI.SettingsRegistry=R
R.pages={
  {"general","일반","KHQOL 공통 설정 및 모듈 관리"},
  {"unitFrames","유닛프레임","유닛과 부품별 모양·표시·위치를 설정합니다."},
  {"partyFrames","파티·공격대","1인 플레이어부터 최대 40인 공격대까지 지원합니다"},
  {"convenience","편의 기능","자동 판매·수리·거절, 아이템·대화창 및 노트를 설정합니다."},
  {"interface","인터페이스","기본 UI, 툴팁, 커서, 사거리와 시계·정보 표시를 설정합니다."},
  {"bars","바 설정","바 계열 기능과 환경 타이머를 관리합니다."},
  {"alerts","알림","전투·위협·NPC·PvP·모닥불 알림을 설정합니다."},
  {"quest","퀘스트","퀘스트 목록과 길 안내·화살표 HUD를 설정합니다."},
  {"profiles","프로필","계정 공용 프로필 및 캐릭터별 사용 프로필 관리"},
  {"labs","실험실","실험 기능과 개발 도구입니다. 접근 잠금은 보안 기능이 아닙니다."},
}
R.groups.partyFrames={};R.orders.partyFrames={}
local function entry(group,id,key,title,description,commands)
  local meta={group=group,id=id,key=key,title=title,description=description}
  R.groups[group]=R.groups[group] or {}; R.groups[group][id]=meta
  R.orders[group]=R.orders[group] or {};R.orders[group][#R.orders[group]+1]=id
  if key then
    R.modules[key]=meta; R.routes[key]=meta
    for _,command in ipairs(commands or {}) do R.commands[command]=key end
  end
  return meta
end
-- Extensions register at file-load time, before the settings window exists.
-- Existing groups and their presenter provide toggle, reset and route behavior.
function R:RegisterModule(key, spec)
  assert(not KHQOL.settings,"Register KHQOL settings before creating the window")
  assert(self.groups[spec.group] and spec.id and spec.title and type(spec.build)=="function","Invalid KHQOL settings connection")
  assert(not self.modules[key] and not self.groups[spec.group][spec.id],"Duplicate KHQOL settings connection")
  local meta=entry(spec.group,spec.id,key,spec.title,spec.description or "",spec.commands)
  meta.tabTitle=spec.tabTitle
  self.positionModules[key]=spec.positions and true or nil
  for _,group in ipairs(self.moduleGroups) do
    for _,page in ipairs(self.pages) do
      if page[1]==spec.group and group.title==page[2] then group.items[#group.items+1]={key,spec.title} end
    end
  end
  KHQOL.UI.SettingsGroups[spec.group]:RegisterTab(spec.id,nil,spec.build)
  if spec.subtabs then
    meta.sharedTabs=true
    for _,tab in ipairs(spec.subtabs) do
      assert(tab.id and tab.title and type(tab.build)=="function" and not self.groups[spec.group][tab.id],"Invalid KHQOL subtab")
      local child=entry(spec.group,tab.id,nil,tab.title,tab.description or spec.description or "")
      child.key=key;child.sharedTabs=true
      KHQOL.UI.SettingsGroups[spec.group]:RegisterTab(tab.id,nil,tab.build)
      if spec.group~="unitFrames" and spec.group~="partyFrames" then
        for _,group in ipairs(self.moduleGroups) do for _,page in ipairs(self.pages) do
          if page[1]==spec.group and group.title==page[2] then group.items[#group.items+1]={key,tab.title,tab=tab.id} end
        end end
      end
    end
  end
  local N=KHQOL.UI.SettingsNavigation
  for _,item in ipairs(spec.search or {}) do
    local route={module=key}
    for field,value in pairs(item.route or {}) do route[field]=value end
    N:Register(route,item.title,item.description,item.aliases)
  end
  self.revision=(self.revision or 0)+1
  return meta
end
function R:ConnectModules()
  for _,id in ipairs(KHQOL.ModuleRegistry.order) do
    local spec=KHQOL.ModuleRegistry.entries[id]
    if spec.settings and not spec.settingsConnected then
      self:RegisterModule(id,spec.settings);spec.settingsConnected=true
    end
  end
end
entry("bars","experience","experienceBar","경험치","경험치와 휴식 경험치 바의 표시·위치·모양을 설정합니다.")
entry("bars","cast","castBar","시전","시전 바의 배치·진행 방향·표시 정보를 설정합니다.",{"cast","castbar"})
entry("bars","resource","resourceSwing","자원/스윙바","자원·스윙 바와 탄약 표시를 설정합니다.",{"resource"})
entry("bars","environment","environmentTimer","환경타이머","호흡·피로도·죽은척 타이머의 표시와 경고를 설정합니다.")
entry("alerts","npc","npcAlert","NPC","등록한 위험 NPC의 감지·배너·방향 경고를 설정합니다.")
entry("alerts","combat","combatStatus","전투 상태","전투 시작과 종료 알림을 설정합니다.",{"combat","combatstatus"})
entry("alerts","campfire","campfire","모닥불","근처 모닥불과 야영 효과 알림을 설정합니다.",{"campfire"})
entry("alerts","pvp","pvpAlert","PvP","적 플레이어의 주시, 접근 및 시전 경고를 설정합니다.",{"pvp","pvpalert"})
entry("interface","cursor","cursorTrail","마우스 잔상","마우스 이동 경로에 잔상을 표시합니다.",{"trail","cursortrail"})
entry("interface","range","range","사거리 측정","선택한 대상의 사거리 상태를 표시합니다.",{"range"})
entry("alerts","threat","threat","위협 수치","현재 선택한 적에 대한 내 어그로를 화면 원하는 위치에 표시합니다.")
entry("interface","basic","basicUI","기본 UI","가방·메뉴바 표시와 Blizzard 기본창 이동을 설정합니다.",{"basicui"})
entry("unitFrames","units","unitFrames","유닛 프레임","플레이어·대상·소환수·대상의 대상·주시대상 프레임의 간결한 모양과 표시를 설정합니다.",{ "unitframes" })
entry("interface","tooltip","tooltip","툴팁 설정","툴팁의 위치, 표시 방식 및 무기 전문가 안내를 조정합니다.",{"tooltip","weapon"})
entry("convenience","general",nil,"일반 편의","대화창·아이템 표시와 판매·수리·자동 거절·채집 기능을 설정합니다.")
R.routes.generalConvenience=R.groups.convenience.general
entry("interface","clock","clock","시계·정보 표시","시간, 날짜, 요일 및 HUD 정보를 표시합니다.",{"clock"})
entry("convenience","note","todo","포에버 노트","화면의 노트 창에서 할 일과 메모를 관리합니다.",{"todo"})
entry("quest","tracker",nil,"퀘스트 목록 (목표 추적기)","목표 추적기의 목록·지역 그룹·글자·폭을 설정합니다.")
R.groups.quest.tracker.key="questNavigator";R.routes.questTracker=R.groups.quest.tracker
entry("quest","navigation","questNavigator","길 안내","퀘스트 선택과 길 안내·화살표 HUD를 설정합니다.",{"quest","questnavigator"})
entry("labs","buff","buffReminder","버프 리마인더","유지할 버프와 만료 전 알림을 설정합니다.",{"buff"})
entry("labs","proc","procAlert","발동 버프","등록한 버프의 전투 중 발동 알림을 설정합니다.")
entry("labs","highlight","objectHighlight","오브젝트 강조","전리품이 있는 퀘스트 오브젝트의 반짝임 유지 설정을 적용합니다.",{"objecthighlight","sparkles"})
entry("labs","inspector",nil,"프레임 검사기","마우스 아래 실제 Frame 이름과 부모 구조를 확인합니다.")
R.groups.labs.inspector.owner="frameInspector"
entry("labs","performance","performanceMonitor","성능 모니터","KHQOL CPU 시간·메모리 사용량을 오버레이로 표시하고 측정 로그를 복사합니다.",{"performance"})
R.routes.frameMover=R.modules.basicUI
R.commands.framemover="frameMover"; R.commands.threat="threat"
-- Order, commands, general shortcuts and presenter all consume this registry.
R.orders.interface={"basic","tooltip","cursor","range","clock"}
R.orders.alerts={"combat","threat","npc","pvp","campfire"}
R.groups.labs.buff.category="실험 기능"
R.groups.labs.inspector.category="개발 도구"
R.routes.proc=R.modules.procAlert;R.routes.inspector=R.groups.labs.inspector
R.routes.highlight=R.modules.objectHighlight;R.routes.frameInspector=R.groups.labs.inspector
R.commands.lab="labs";R.commands.labs="labs";R.commands.proc="procAlert";R.commands.inspector="frameInspector"
for _,page in ipairs(R.pages) do
  if page[1]~="labs" and R.groups[page[1]] then
    local group={title=page[2],items={}}
    for _,id in ipairs(R.orders[page[1]]) do
      local meta=R.groups[page[1]][id]
      if meta.key or meta.owner then
        local item={meta.key or meta.owner,meta.title}
        if page[1]=="quest" and id=="tracker" then item.route="questTracker" end
        group.items[#group.items+1]=item
      end
    end
    if page[1]=="convenience" then
      group.items[#group.items+1]={"generalConvenience","일반 편의",navigationOnly=true}
      for index,item in ipairs({{"autoConfirmDestroy","아이템 파괴 자동 입력",true},
        {"chatEnhancement","기본 대화창 편의",true},
        {"autoSellJunk","잡템 자동 판매",true},{"autoRepair","자동 수리",true}}) do
        if index<=2 then table.insert(group.items,index,item) else group.items[#group.items+1]=item end
      end
    end
    R.moduleGroups[#R.moduleGroups+1]=group
  end
end
function R:ResetScope(key)
  local spec=KHQOL.ModuleRegistry.entries[key]
  if spec and spec.resetScope then return spec.resetScope(KHQOL.modules[key],KHQOL) end
  if key=="objectHighlight" then return "현재 프로필의 오브젝트 강조를 OFF로 초기화하고 KHQOL이 변경한 그래픽 설정을 안전하게 복원합니다.\n복원 실패 시 필요한 기록은 유지합니다. 효과 해제에는 게임 재시작이 필요할 수 있습니다." end
  local scope="현재 프로필의 해당 모듈 설정을 기본값으로 복원합니다. 사용 ON/OFF는 유지합니다."
  if key=="clock" or key=="todo" then return scope.."\n노트 내용·체크리스트·완료 상태·알람 문구는 유지합니다." end
  if key=="buffReminder" then return scope.."\n직업별 등록 버프 목록은 유지합니다." end
  if key=="npcAlert" then return scope.."\n계정 공용 NPC 등록 목록은 유지합니다." end
  if key=="procAlert" then return scope.."\n계정 공용 발동 버프 등록 목록은 유지합니다." end
  return scope.."\n다른 모듈 설정과 공용 등록 데이터는 유지합니다."
end
function R:Resolve(key)
  local meta=self.routes[key]
  if meta then return meta.group,meta.id end
  for _,page in ipairs(self.pages) do if page[1]==key then return key end end
  return "general"
end

R.positionModules={clock=true,todo=true,buffReminder=true,range=true,resourceSwing=true,campfire=true,
  castBar=true,combatStatus=true,questNavigator=true,threat=true,pvpAlert=true,experienceBar=true,
  environmentTimer=true,procAlert=true,performanceMonitor=true,tooltip=true,basicUI=true,unitFrames=true}
