local _, KHQOL = ...
local R={modules={},groups={},orders={},routes={},commands={},moduleGroups={}}
KHQOL.UI.SettingsRegistry=R
R.pages={
  {"general","일반","KHQOL 공통 설정 및 모듈 관리"},
  {"bars","바 설정","바 계열 기능과 환경 타이머를 관리합니다."},
  {"alerts","알림","NPC, 전투, 모닥불, 버프 및 PvP 알림을 관리합니다."},
  {"interface","인터페이스","커서, 사거리, 어그로 및 툴팁을 관리합니다."},
  {"convenience","편의 기능","자동화 편의 기능, 시계, 노트 및 퀘스트 안내를 관리합니다."},
  {"labs","실험실","개발 중이나 정상적으로 동작되지 않는 기능입니다."},
  {"profiles","프로필","계정 공용 프로필 및 캐릭터별 사용 프로필 관리"},
}
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
entry("bars","experience","experienceBar","경험치","경험치와 휴식 경험치 바의 표시·위치·모양을 설정합니다.")
entry("bars","cast","castBar","시전","시전 바의 배치·진행 방향·표시 정보를 설정합니다.",{"cast","castbar"})
entry("bars","resource","resourceSwing","리소스/스윙","자원·스윙 바와 탄약 표시를 설정합니다.",{"resource"})
entry("bars","environment","environmentTimer","환경","호흡·피로도·죽은척 타이머의 표시와 경고를 설정합니다.")
entry("alerts","npc","npcAlert","NPC","등록한 위험 NPC의 감지·배너·방향 경고를 설정합니다.")
entry("alerts","combat","combatStatus","전투","전투 시작과 종료 알림을 설정합니다.",{"combat","combatstatus"})
entry("alerts","campfire","campfire","모닥불","근처 모닥불과 야영 효과 알림을 설정합니다.",{"campfire"})
entry("alerts","buff","buffReminder","버프","유지할 버프와 만료 전 알림을 설정합니다.",{"buff"})
entry("alerts","pvp","pvpAlert","PvP","적 플레이어의 주시, 접근 및 시전 경고를 설정합니다.",{"pvp","pvpalert"})
entry("interface","cursor","cursorTrail","마우스 잔상","마우스 이동 경로에 잔상을 표시합니다.",{"trail","cursortrail"})
entry("interface","range","range","거리 측정","선택한 대상의 사거리 상태를 표시합니다.",{"range"})
entry("interface","threat","threat","위협 수치","현재 선택한 적에 대한 내 어그로를 화면 원하는 위치에 표시합니다.")
entry("interface","tooltip","tooltip","툴팁 설정","툴팁의 위치, 표시 방식 및 무기 전문가 안내를 조정합니다.",{"tooltip","weapon"})
entry("convenience","general",nil,"일반","판매·수리·초대 관련 편의 기능을 설정합니다.")
entry("convenience","clock","clock","시계 설정","시간, 날짜, 요일 및 HUD 정보를 표시합니다.",{"clock"})
entry("convenience","note","todo","포에버 노트","화면의 노트 창에서 할 일과 메모를 관리합니다.",{"todo"})
entry("convenience","quest","questNavigator","퀘스트 설정","추적 중인 퀘스트의 목표·반납 위치를 안내합니다.",{"quest","questnavigator"})
entry("labs","proc","procAlert","발동","등록한 버프의 전투 중 발동 알림을 설정합니다.")
entry("labs","inspector",nil,"프레임 검사기","마우스 아래 실제 Frame 이름과 부모 구조를 확인합니다.")
for _,page in ipairs(R.pages) do
  if page[1]~="labs" and R.groups[page[1]] then
    local group={title=page[2],items={}}
    for _,id in ipairs(R.orders[page[1]]) do
      local meta=R.groups[page[1]][id]
      if meta.key then group.items[#group.items+1]={meta.key,meta.title} end
    end
    if page[1]=="convenience" then
      for _,item in ipairs({{"autoSellJunk","잡템 자동 판매",true},{"autoRepair","자동 수리",true},
        {"declinePartyInvites","파티초대 거절",true},{"declineGuildInvites","길드초대 거절",true}}) do group.items[#group.items+1]=item end
    end
    R.moduleGroups[#R.moduleGroups+1]=group
  end
end
function R:ResetScope(key)
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
