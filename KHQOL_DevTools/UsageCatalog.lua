-- Static, reviewed identifiers only. Translated labels locate controls; they never form IDs.
local U={VERSION="0.1",DEV_VERSION="0.4.0",SCHEMA=1,CATALOG_REVISION=13,catalog={},bindings={}}
_G.KHQOLDevUsage=U
U.managedAddons={KHQOL=true,KHQOL_Campfire=true,KHQOL_Clock=true,KHQOL_CombatStatus=true,KHQOL_Convenience=true,
  KHQOL_CursorTrail=true,KHQOL_EnvironmentTimer=true,KHQOL_ExperienceBar=true,KHQOL_Labs=true,KHQOL_Map=true,
  KHQOL_NPCAlert=true,KHQOL_PvPAlert=true,KHQOL_QuestNavigator=true,KHQOL_Range=true,KHQOL_ResourceSwing=true,
  KHQOL_Threat=true,KHQOL_Tooltip=true,KHQOL_UnitFrames=true}
function U:Define(id,kind,label,class,point,meaning,limit)
  assert(#id<=96 and id:match("^[%w_.]+$") and not self.catalog[id])
  self.catalog[id]={id=id,kind=kind,label=label,class=class,point=point,meaning=meaning,
    limit=limit or "",dedup="최종 상태 비교 / 조작별 1회",
    validation=class=="HOLD" and "보류; 인게임 NOT TESTED" or "공통 경로 Lua 모의 검사; 인게임 NOT TESTED"}
end
local pages={general="일반",profiles="프로필",unitFrames="유닛프레임",partyFrames="파티·공격대",
  convenience="편의 기능",interface="인터페이스",minimap="미니맵",bars="바 설정",alerts="알림",quest="퀘스트",labs="실험실"}
U.pages=pages
U.tabs={unitFrames={"units"},partyFrames={"common","frames","auras","roles"},convenience={"general","chat","party","professions","note","highlight"},
  interface={"basic","tooltip","cursor","range","clock"},minimap={"minimap","minimapButtons"},
  bars={"experience","cast","resource","environment"},alerts={"combat","threat","npc","pvp","campfire"},
  quest={"tracker","navigation"},labs={"buff","proc","npc","pvp","itemProtection"}}
for page,label in pairs(pages) do
  U:Define("menu."..page,"menus",label,"DIRECT","SettingsUI / 사용자 선택 후 최종 표시","표시된 페이지 방문·체류")
  for _,tab in ipairs(U.tabs[page] or {}) do
    U:Define("menu."..page.."."..tab,"menus",label.." / "..tab,"DIRECT","SettingsPresenter / tabButtons","최종 하위 탭 방문·체류")
  end
end
for _,unit in ipairs({"player","target","pet","targettarget","focus"}) do
  for _,part in ipairs({"basic","bars","labels","status","auras","class"}) do
    if part~="auras" and part~="class" or part=="auras" and (unit=="player" or unit=="target") or part=="class" and unit=="player" then
      local id="menu.unitFrames.units."..unit.."."..part
      if unit=="target" and part=="auras" then
        for _,category in ipairs({"friendlyPlayer","attackableNPC"}) do
          U:Define(id.."."..category,"menus",unit.." / "..part.." / "..category,"DIRECT",
            "UnitFrameDetails.SelectUnitPart / SelectAuraCategory","최종 유닛·부품·오라 유형 방문·체류")
        end
      else U:Define(id,"menus",unit.." / "..part,"DIRECT","UnitFrameDetails 유닛·부품 버튼","최종 유닛·부품 방문·체류") end
    end
  end
end
for _,unit in ipairs({"player","target"}) do
  U:Define("menu.bars.cast."..unit,"menus","시전 / "..unit,"DIRECT","CastBar.Settings.SelectCastUnit / castButtons","최종 시전 바 유닛 방문·체류")
end
U.modules={"clock","todo","experienceBar","castBar","tooltip","threat","cursorTrail","range",
  "resourceSwing","environmentTimer","combatStatus","npcAlert","pvpAlert","campfire","questNavigator",
  "unitFrames","partyFrames","basicUI","buffReminder","procAlert","objectHighlight","minimap"}
for _,key in ipairs(U.modules) do
  U:Define("setting.module."..key,"settings",key.." 사용 ON/OFF","DIRECT","moduleHeader.toggle / general.moduleControls",
    "사용자 조작 전후 저장된 활성 설정 변경","재적용·프로필 변경 제외")
end
local function bind(module,title,key,kind)
  local id="setting."..module.."."..key
  U:Define(id,"settings",title,"DIRECT","SettingsNavigation.Attach / "..module,"유효한 최종 설정 변경",
    kind=="slider" and "drag·input 경로; 화살표 UI는 향후 작업" or "허용 목록의 마우스 클릭·라벨 경로; 키보드 선택은 미계측")
  U.bindings[module.."/"..title]={id=id,kind=kind}
end
bind("general","KHQOL 미니맵 버튼 표시","minimapVisible","check")
bind("general","설정 잠금","locked","check")
bind("general","디버그 모드","debug","check")
bind("general","기본 UI와 겹칠 때","windowOverlap","dropdown")
bind("general","중앙 알림 텍스트 크기","centerTextScale","slider")
bind("generalConvenience","중앙 알림 텍스트 크기","centerTextScale","slider")
bind("clock","날짜 형식","dateFormat","dropdown")
bind("clock","요일 언어","weekdayLanguage","dropdown")
bind("clock","길드 접속 표시","guildVisible","check")
bind("clock","타이틀 표시","guildTitle","check")
bind("clock","배경 표시","guildBackground","check")
bind("clock","툴팁 명단 축약 기준","guildTooltipLimit","slider")
bind("clock","위치 잠금","locked","check")
bind("clock","알람·타이머 창 크기","toolsScale","slider")
bind("clock","도구 창 위치 잠금","toolsLocked","check")
bind("clock","타이머 바 위치 잠금","timerBarLocked","check")
U:Define("setting.color.confirmed","settings","색상 최종 변경","BRIDGE","UI.OpenColorPicker 최종 확정/취소",
  "미리보기·취소 복원 제외 후 최종 변경","기존 공개 콜백에는 최종 확정 신호 없음; 미계측")
U:Define("setting.text.confirmed","settings","문자 입력 확정","HOLD","BindInput / 사용자 문자열 컨트롤",
  "문자 입력의 유효한 확정 변경","개인정보 포함 필드와 미등록 컨트롤은 이번 허용 목록에서 제외")
for _,key in ipairs({"autoSellJunk","autoRepair","autoConfirmDestroy","chatEnhancement"}) do
  U:Define("setting.general."..key,"settings",key,"DIRECT","general.moduleControls","사용자 편의 기능 ON/OFF 변경")
end
local function feature(id,label,class,point,meaning,limit)
  U:Define("feature."..id,"features",label,class,point,meaning,limit)
end

feature("profession.guide","다음 숙련 안내 조회","BRIDGE","ProfessionGuide.ShowTooltip","실제 안내 표시 구간당 1회; Refresh 제외")
feature("profession.note_request","숙련 습득 위치 등록 요청","BRIDGE","ProfessionGuide.Request","명시적 우클릭 요청; 선택 메뉴와 완료 구분")
feature("profession.note_added","숙련 습득 위치 등록 완료","BRIDGE","ProfessionGuide.Register","실제 새 노트 항목 생성 확인; 중복 제외")
feature("profession.navigate","숙련 노트 위치 길 안내 실행","BRIDGE","ProfessionGuide.Navigate","기존 노트 안내 시작 true 확인; 자동 안내 없음")

feature("note.open","ForeverNote 열기","DIRECT","clock.ToggleTodo 후 todoFrame","실제로 열린 전환; 이미 열려 있던 창 제외")
feature("professions.open","전문기술 조회 창 열기","DIRECT","professions.ToggleProfessions 후 professionsPanel","닫힘→열림 전환")
feature("thanks.display","감사 알림 표시","DIRECT","buffThanks.Show 후 alerts","추가되어 실제 표시된 알림; 인자 미수집")
feature("npc.display","NPC 배너 표시","DIRECT","npcAlert.ShowBanner 후 banner","실제로 표시된 배너; 미리보기 경로 없음")
feature("party.menu_request","파티 메뉴 열기 요청","LIMITED","partyButton.OpenPartyMenu","KHQOL 소유 메뉴 요청 호출","클라이언트 메뉴 표시·서버 성공은 확인하지 않음")
feature("position.start","위치 편집 시작","DIRECT","PositionEditor.Enter 후 active","비활성→활성 편집 진입")
feature("position.save","위치 편집 저장 종료","BRIDGE","PositionEditor.Finish 반환 직전","최종 save=true 종료","post hook으로 반환값·최종 save 지역변수 접근 불가")
feature("position.changed","위치 편집 변경 확정","BRIDGE","PositionEditor.Finish 쓰기 이후","실제 변경이 확정된 저장","좌표·초안을 추측해서 저장 성공으로 집계하지 않음")
feature("position.cancel","위치 편집 취소","BRIDGE","PositionEditor.Finish 최종 판정","취소·전투·프로필·검증 실패 종료")
feature("quest.manual","길찾기 수동 목표 변경","BRIDGE","QuestNavigator.Selection.AdoptQuest","사용자 수동 목표 변경 확정","manual=true가 자동 추적 동기화에서도 사용됨")
feature("thanks.click","감사 버튼 실행","BRIDGE","buffThanks.Click 조건 통과 후","유효한 감사 버튼 실행")
feature("thanks.send_request","감사 전송 요청","BRIDGE","buffThanks.Click 전송 분기","전송 API 요청","서버 수신 성공을 의미하지 않음")
feature("party.execute","파티 실제 기능 실행","BRIDGE","partyButton.Click 조건 검사 이후","초대·인사·탈퇴의 유효한 요청")
feature("sell.processed","자동 판매 처리 방문","BRIDGE","General.ProcessJunkSale / FinishJunkSale","실제 판매 처리 확인이 있는 방문","빈 큐·조건 실패·취소를 완료로 추정하지 않음")
feature("repair.request","자동 수리 요청","BRIDGE","General.TryAutoRepair / RepairAllItems 직후","수리 API 요청","서버 성공 아님; 함수 진입은 요청 아님")
feature("buff.display","버프 알림 표시","HOLD","ProcAlert.Update / 테스트·미리보기 혼합","실제 알림 표시","프레임 갱신을 실행 횟수로 집계하지 않음")
feature("campfire.display","모닥불 알림 표시","BRIDGE","Campfire.ShowDiscovery / RunTest","실제 탐지 알림","테스트도 동일 함수를 호출하므로 구분 신호 필요")
for _,key in ipairs({"clock","experienceBar","castBar","tooltip","threat"}) do
  feature("active."..key,key.." 사용 날짜","LIMITED","ModuleRegistry.states.running + 저장 설정","실행 가능 상태가 관찰된 UTC 날짜",
    "실제 픽셀 노출·고유 사용자·캐릭터 수가 아님; OFF·AFK 중 미수집")
end
U.rules={time_basis="UTC",retention_days=30,range_includes_today=true,dwell_cap_seconds=1800,
  dwell_cap_scope="연속 표시 구간; 조회·자정 정산으로 상한 재시작 안 함",
  afk="UnitIsAFK + PLAYER_FLAGS_CHANGED가 사용 가능하면 정지; 불명 상태는 LIMITED",
  background="게임 창 비활성 상태를 신뢰할 수 있는 Forever API를 확인하지 못함; 제외 불가",
  visit="창 최초 표시·기록 ON 당시 표시 페이지 1회; 동일 탭 재클릭 0; 자동 복귀 0",
  menu_hierarchy="최종 leaf ID만 증가; 부모 메뉴 행에 하위 방문을 중복 합산하지 않음",
  average="누적 초 / 양수 체류가 있는 날짜별 유효 방문 표본 수 (자정 걸친 방문은 날짜마다 표본)",
  input="check/click, dropdown/click, slider/drag·input; 취소·값 복귀·프로필 전환 제외",
  unsupported="observedDays=0은 미계측; observedDays>0의 0도 전체 기간 완전 관찰을 뜻하지 않음",
  saving="메모리 집계; 정상 로그아웃·리로드 때 SavedVariables 파일 저장",
  reset="확인 후 집계 삭제; 기록 ON/OFF 유지; 현재 ON이면 새 관찰 시작",
  privacy="정적 ID·카운터·초·UTC 날짜·검증된 버전만 저장; 값 원본·이름·채팅·좌표 제외"}
-- Keep every historical ID. New per-control IDs are an explicit, frozen registration table.
local C=_G.KHQOLDevUsageControlIDs
for id,definition in pairs(C.definitions) do
  local meta=U.catalog[id]
  if not meta then
    U:Define(id,"settings",definition.label,"BRIDGE",definition.point,"공통 컨트롤의 확정된 실제 변경",
      "등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED")
    meta=U.catalog[id]
  else meta.fallback="DIRECT";meta.class="BRIDGE" end
  meta.point=definition.point;meta.bridgeKind=definition.kind;meta.owner=definition.owner
  meta.validation="Lua 모의 검사 / 인게임 NOT TESTED";meta.verdict="GO"
end
for _,key in ipairs(U.modules) do
  local meta=U.catalog["setting.module."..key];meta.fallback="DIRECT";meta.class="BRIDGE"
  meta.point="KHQOL UI 공통 체크박스 확정 지점";meta.limit="사용자 저장 상태 변경; 재적용 제외"
end
for _,key in ipairs({"autoSellJunk","autoRepair","autoConfirmDestroy","chatEnhancement"}) do
  local meta=U.catalog["setting.general."..key];meta.fallback="DIRECT";meta.class="BRIDGE"
end
local updates={
  ["position.start"]={"위치 편집 시작","PositionEditor.Enter 최종 활성 전환","유효한 편집 시작","DIRECT"},
  ["position.save"]={"위치 편집 저장 종료","PositionEditor.Finish 최종 반환 전","저장 루틴이 오류 없이 끝난 종료"},
  ["position.changed"]={"위치 변경 확정","PositionEditor.Finish 소유 위치 읽기 비교","최소 한 위치의 저장값 변경 확인",nil,"설정 getter 미등록 writer는 확인 불가; 좌표는 전달하지 않음"},
  ["position.cancel"]={"위치 편집 취소","PositionEditor.Finish 최종 save=false","취소와 제한된 사유"},
  ["position.unconfirmed"]={"위치 결과 확인 불가","PositionEditor writer/apply 결과","실패 또는 변경 확인 불가",nil,"저장/변경 성공으로 해석하지 않음"},
  ["quest.manual"]={"퀘스트 수동 목표 변경","Tracker의 명시적 사용자 선택 직후","KHQOL 추적기의 실제 supertrack 변경",nil,"기본 게임 퀘스트 로그·외부 애드온의 선택은 포함하지 않음"},
  ["thanks.click"]={"유효한 감사 클릭","BuffThanks.Click 조건 통과","유효한 좌클릭 실행"},
  ["thanks.draft"]={"감사 귓속말 초안 열기","BuffThanks.Click 초안 성공 뒤","초안이 열린 경우; 전송 아님"},
  ["thanks.send_request"]={"감사 전송 API 요청","BuffThanks.Click 전송 호출 뒤","실제 API 호출 시도",nil,"서버 수신·전송 성공 아님"},
  ["party.execute"]={"파티 기능 요청","초대/일반 인사/탈퇴의 유효 요청 분기","각 요청 경로의 실제 호출",nil,"서버 성공 아님; 작별 채팅은 chat_request로 별도 표시"},
  ["party.chat_request"]={"파티 인사 채팅 요청","SendGroupMessage status=ok","일반 인사/작별 인사 요청",nil,"party.execute와 단계가 다름; 합산하지 않음"},
  ["party.draft"]={"파티 인사 초안 열기","제한 상태에서 OpenGroupDraft 성공","초안 열림; 전송 아님"},
  ["sell.processed"]={"자동 판매 처리 방문","FinishJunkSale의 처리 증거 확인","슬롯 소멸+금액 증거 또는 native 요청 후 잡템 0",nil,"native는 동시 사용자 판매를 완전히 배제하지 못함"},
  ["sell.unconfirmed"]={"자동 판매 처리 확인 불가","판매 후 금액 증거 불일치","실제 판매 성공 횟수에 포함하지 않음"},
  ["repair.request"]={"자동 수리 요청","모든 조건을 통과한 RepairAllItems 호출 뒤","실제 수리 API 호출 시도",nil,"서버 수리 성공 아님"},
  ["campfire.display"]={"모닥불 탐지 알림","live ProcessAuras → ShowDiscovery","실제 새 탐지 표시",nil,"initial/test/재배치 제외"},
  ["campfire.complete"]={"모닥불 효과 알림","live ProcessAuras → ShowComplete","실제 효과 획득/갱신 알림",nil,"테스트 표시 제외"},
  ["buff.display"]={"발동 버프 HUD 표시","ProcAlert.Visual의 슬롯 전환","실제 전투 중 새 HUD 표시",nil,"버프별 ID·이름 없음; 테스트/미리보기/동일 슬롯 갱신 제외"}}
for key,spec in pairs(updates) do
  local id="feature."..key;local meta=U.catalog[id]
  if not meta then U:Define(id,"features",spec[1],"BRIDGE",spec[2],spec[3],spec[5]);meta=U.catalog[id] end
  meta.label=spec[1];meta.class="BRIDGE";meta.point=spec[2];meta.meaning=spec[3];meta.fallback=spec[4];meta.limit=spec[5] or ""
  meta.validation="Lua 모의 검사 / 인게임 NOT TESTED";meta.verdict=spec[5] and "LIMITED GO" or "GO"
end
for _,id in ipairs({"setting.color.confirmed","setting.text.confirmed"}) do
  local meta=U.catalog[id];meta.class="HOLD";meta.limit="호환용 미사용 합계 ID. 개별 고정 설정 ID에서 수집";meta.verdict="HOLD"
end
U.rules.bridge="protocol 1; 대표 경로 bridge/direct 중 하나; OFF/초기화에서 구독 해제; raw 값 없는 로컬 진단"
U.rules.input="체크·라벨·드롭다운·문자/숫자 확정·슬라이더 drag·색상 최종 OK; 초안/오류/취소/값 복귀 제외"
U.rules.observation="새 지표는 실제 연결된 UTC 날짜부터; 과거 observed/버전을 소급 수정하지 않음"
for _,meta in pairs(U.catalog) do
  if meta.kind=="menus" then
    meta.verdict="LIMITED GO"
    meta.limit="방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부"
  end
end

for _,row in ipairs({{"request","음식 사용 요청","명시적 secure 아이콘 클릭; 성공 아님"},{"used","음식 섭취 확인","검증된 음식 요청과 실제 섭취 오라 시작의 일치"},{"well_fed","음식 포만감 확인","검증된 섭취 뒤 실제 포만감 오라 확인; 시간 경과 제외"}}) do
  U:Define("feature.food."..row[1],"features",row[2],"BRIDGE","BuffReminder/Food.lua",row[3],"자동 후보 whitelist 비어 있음; 실기 NOT TESTED")
end
