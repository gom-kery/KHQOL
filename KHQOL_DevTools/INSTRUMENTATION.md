# Phase 1-2 계측 조사·연결 목록

정적·Lua 5.1 모의 기준입니다. 모든 인게임 상태는 **NOT TESTED**입니다. 방식과 검증 단계는 별개입니다. 마법책 회귀를 재확인하기 전 일반 배포는 HOLD입니다.

| 항목 | 0.2.0 실제 상태·제한 | 0.3.0 보완·수집 의미 | 방식 / 판정(정적·모의) |
|---|---|---|---|
| 메뉴 방문 | 최종 페이지 DIRECT, 같은 탭·Refresh 제외 | 기존 경로 유지, 검색·부모/하위 coalesce·자동 복귀 확인 | DIRECT / GO |
| 체류 | UTC, AFK 조건부, 연속 1800초 | 기존 정책 유지·자정 lastDate 보완·반복 조회/정산 확인 | DIRECT / LIMITED GO: 백그라운드 감지 불가 |
| 설정 | 짧은 명시 허용 목록, 색상 최종 확정 없음 | 748개 고정 바인딩 행, 문맥 포함 796개 설정 지표. 최종 getter 실제 차이만 | BRIDGE / GO, 구버전 DIRECT 일부 |
| 모듈 ON/OFF | 체크 UI DIRECT·일부 공개 경로 | 실제 저장 상태 바뀐 사용자 commit에서만, 내부 재적용 제외 | BRIDGE / GO, 구버전 DIRECT |
| 위치 | 시작만 DIRECT, 최종 결과 접근 불가 | 소유 writer 읽기 비교 뒤 저장/변경/취소/불명 분리 | BRIDGE / LIMITED GO: 미등록 writer 불명 |
| ForeverNote·전문기술 | 실제 창 열기 DIRECT | 닫힘→열림 유지, 중복 연결 확인 | DIRECT / GO |
| 퀘스트 | AdoptQuest manual 인자가 자동 동기화에도 쓰임 | Tracker의 두 명시적 사용자 선택 뒤 native 추적 ID 변경 확인 | BRIDGE / LIMITED GO: 기본 로그·다른 애드온 선택 제외 |
| 파티 | 메뉴 함수 요청만 LIMITED | 유효 초대/인사/탈퇴 요청과 채팅 단계/초안 별도 | LIMITED + BRIDGE / LIMITED GO: 서버 성공 아님 |
| 버프 감사 | 알림 DIRECT, 클릭·전송 단계 미계측 | 유효 클릭/실제 초안/API 호출 시도 분리 | DIRECT + BRIDGE / LIMITED GO: 서버 수신 아님 |
| 판매·수리 | 조건 통과/처리 결과 미계측 | 판매는 비어 있지 않은 작업의 처리 증거, 수리는 API 요청 | BRIDGE / LIMITED GO |
| NPC·모닥불·Proc | NPC DIRECT, 나머지 테스트/재표시 혼합 | NPC 유지, 모닥불 live 원인·Proc 실제 신규 표시 전환만 | DIRECT + BRIDGE / LIMITED GO |
| Clock·XP·시전·Tooltip·Threat | 날짜별 running+설정 | 기존 활성 날짜 유지. 프레임 갱신 횟수 미합산 | LIMITED / LIMITED GO |

## 범위·제외

공통 설정은 9개 직업에서 페이지를 생성해 조사했습니다. 매니페스트의 46개 제외 행은 프로필 명령, 조회/대상 선택, 경로 초안 선택, 등록 편집 초안 등입니다. Labs의 실제 영속 HUD 설정 8개는 별도 고정 바인딩입니다. 등록 목록의 저장 버튼·사용자 등록/삭제 작업은 일반 설정 변경으로 세지 않습니다. 필드 내용은 전달하지 않습니다. 목록은 아래 제외 표와 review의 control-manifest.json에 있습니다.

체크/라벨·드롭다운 다른 값 확정은 +1. 한 드래그의 시작/끝이 같으면 0, 별도 드래그 복귀는 각각 +1. 입력 Enter/기존 유효 포커스 이동은 한 번, ESC/숨김/프로필/무효 입력은 0. 색상 preview/cancel/프로그램 닫기는 0, native OK의 최종 변경만 +1. 문맥이 바뀐 초안은 폐기합니다. Clock 사이드 common/date/money/weekday/performance/guild, 파티 party/raid10/raid20/raid40을 별도 정적 ID로 나눕니다.

arrow는 허용한 예약 경로이며 이번 실제 UI에는 없습니다. 향후 미세 화살표는 소유 getter를 D:Begin(control,"arrow") 직전, 원래 setter 실행, D:Finish(control) 직후로 연결하며 자체 값 생성·새 ID 추론을 하지 않습니다.

## 지표별 목록

대표 경로는 새 protocol 지원 시 BRIDGE가 우선이고 DIRECT는 해당 ID를 세지 않습니다. 구버전에서는 fallback=DIRECT가 있는 지표만 기존 경로를 선택합니다. 연결 여부는 설치·기록 상태·선택 모듈에 따라 달라지므로 JSON의 connected/selectedRoute를 확인합니다. 이 표의 GO는 실제 게임 통과를 뜻하지 않습니다.

| 고정 ID | 이름·종류 | 0.3 방식 / 정적·모의 판정 | 관찰 지점·수집 의미 | 제한 |
|---|---|---|---|---|
| feature.active.castBar | castBar 사용 날짜 / features | LIMITED / LIMITED GO | ModuleRegistry.states.running + 저장 설정 — 실행 가능 상태가 관찰된 UTC 날짜 | 실제 픽셀 노출·고유 사용자·캐릭터 수가 아님; OFF·AFK 중 미수집 |
| feature.active.clock | clock 사용 날짜 / features | LIMITED / LIMITED GO | ModuleRegistry.states.running + 저장 설정 — 실행 가능 상태가 관찰된 UTC 날짜 | 실제 픽셀 노출·고유 사용자·캐릭터 수가 아님; OFF·AFK 중 미수집 |
| feature.active.experienceBar | experienceBar 사용 날짜 / features | LIMITED / LIMITED GO | ModuleRegistry.states.running + 저장 설정 — 실행 가능 상태가 관찰된 UTC 날짜 | 실제 픽셀 노출·고유 사용자·캐릭터 수가 아님; OFF·AFK 중 미수집 |
| feature.active.threat | threat 사용 날짜 / features | LIMITED / LIMITED GO | ModuleRegistry.states.running + 저장 설정 — 실행 가능 상태가 관찰된 UTC 날짜 | 실제 픽셀 노출·고유 사용자·캐릭터 수가 아님; OFF·AFK 중 미수집 |
| feature.active.tooltip | tooltip 사용 날짜 / features | LIMITED / LIMITED GO | ModuleRegistry.states.running + 저장 설정 — 실행 가능 상태가 관찰된 UTC 날짜 | 실제 픽셀 노출·고유 사용자·캐릭터 수가 아님; OFF·AFK 중 미수집 |
| feature.buff.display | 발동 버프 HUD 표시 / features | BRIDGE / LIMITED GO | ProcAlert.Visual의 슬롯 전환 — 실제 전투 중 새 HUD 표시 | 버프별 ID·이름 없음; 테스트/미리보기/동일 슬롯 갱신 제외 |
| feature.campfire.complete | 모닥불 효과 알림 / features | BRIDGE / LIMITED GO | live ProcessAuras → ShowComplete — 실제 효과 획득/갱신 알림 | 테스트 표시 제외 |
| feature.campfire.display | 모닥불 탐지 알림 / features | BRIDGE / LIMITED GO | live ProcessAuras → ShowDiscovery — 실제 새 탐지 표시 | initial/test/재배치 제외 |
| feature.note.open | ForeverNote 열기 / features | DIRECT / GO | clock.ToggleTodo 후 todoFrame — 실제로 열린 전환; 이미 열려 있던 창 제외 |  |
| feature.npc.display | NPC 배너 표시 / features | DIRECT / GO | npcAlert.ShowBanner 후 banner — 실제로 표시된 배너; 미리보기 경로 없음 |  |
| feature.party.chat_request | 파티 인사 채팅 요청 / features | BRIDGE / LIMITED GO | SendGroupMessage status=ok — 일반 인사/작별 인사 요청 | party.execute와 단계가 다름; 합산하지 않음 |
| feature.party.draft | 파티 인사 초안 열기 / features | BRIDGE / GO | 제한 상태에서 OpenGroupDraft 성공 — 초안 열림; 전송 아님 |  |
| feature.party.execute | 파티 기능 요청 / features | BRIDGE / LIMITED GO | 초대/일반 인사/탈퇴의 유효 요청 분기 — 각 요청 경로의 실제 호출 | 서버 성공 아님; 작별 채팅은 chat_request로 별도 표시 |
| feature.party.menu_request | 파티 메뉴 열기 요청 / features | LIMITED / LIMITED GO | partyButton.OpenPartyMenu — KHQOL 소유 메뉴 요청 호출 | 클라이언트 메뉴 표시·서버 성공은 확인하지 않음 |
| feature.position.cancel | 위치 편집 취소 / features | BRIDGE / GO | PositionEditor.Finish 최종 save=false — 취소와 제한된 사유 |  |
| feature.position.changed | 위치 변경 확정 / features | BRIDGE / LIMITED GO | PositionEditor.Finish 소유 위치 읽기 비교 — 최소 한 위치의 저장값 변경 확인 | 설정 getter 미등록 writer는 확인 불가; 좌표는 전달하지 않음 |
| feature.position.save | 위치 편집 저장 종료 / features | BRIDGE / GO | PositionEditor.Finish 최종 반환 전 — 저장 루틴이 오류 없이 끝난 종료 |  |
| feature.position.start | 위치 편집 시작 / features | BRIDGE / GO | PositionEditor.Enter 최종 활성 전환 — 유효한 편집 시작 |  |
| feature.position.unconfirmed | 위치 결과 확인 불가 / features | BRIDGE / LIMITED GO | PositionEditor writer/apply 결과 — 실패 또는 변경 확인 불가 | 저장/변경 성공으로 해석하지 않음 |
| feature.professions.open | 전문기술 조회 창 열기 / features | DIRECT / GO | professions.ToggleProfessions 후 professionsPanel — 닫힘→열림 전환 |  |
| feature.quest.manual | 퀘스트 수동 목표 변경 / features | BRIDGE / LIMITED GO | Tracker의 명시적 사용자 선택 직후 — KHQOL 추적기의 실제 supertrack 변경 | 기본 게임 퀘스트 로그·외부 애드온의 선택은 포함하지 않음 |
| feature.repair.request | 자동 수리 요청 / features | BRIDGE / LIMITED GO | 모든 조건을 통과한 RepairAllItems 호출 뒤 — 실제 수리 API 호출 시도 | 서버 수리 성공 아님 |
| feature.sell.processed | 자동 판매 처리 방문 / features | BRIDGE / LIMITED GO | FinishJunkSale의 처리 증거 확인 — 슬롯 소멸+금액 증거 또는 native 요청 후 잡템 0 | native는 동시 사용자 판매를 완전히 배제하지 못함 |
| feature.sell.unconfirmed | 자동 판매 처리 확인 불가 / features | BRIDGE / GO | 판매 후 금액 증거 불일치 — 실제 판매 성공 횟수에 포함하지 않음 |  |
| feature.thanks.click | 유효한 감사 클릭 / features | BRIDGE / GO | BuffThanks.Click 조건 통과 — 유효한 좌클릭 실행 |  |
| feature.thanks.display | 감사 알림 표시 / features | DIRECT / GO | buffThanks.Show 후 alerts — 추가되어 실제 표시된 알림; 인자 미수집 |  |
| feature.thanks.draft | 감사 귓속말 초안 열기 / features | BRIDGE / GO | BuffThanks.Click 초안 성공 뒤 — 초안이 열린 경우; 전송 아님 |  |
| feature.thanks.send_request | 감사 전송 API 요청 / features | BRIDGE / LIMITED GO | BuffThanks.Click 전송 호출 뒤 — 실제 API 호출 시도 | 서버 수신·전송 성공 아님 |
| menu.alerts | 알림 / menus | DIRECT / LIMITED GO | SettingsUI / 사용자 선택 후 최종 표시 — 표시된 페이지 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.alerts.campfire | 알림 / campfire / menus | DIRECT / LIMITED GO | SettingsPresenter / tabButtons — 최종 하위 탭 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.alerts.combat | 알림 / combat / menus | DIRECT / LIMITED GO | SettingsPresenter / tabButtons — 최종 하위 탭 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.alerts.npc | 알림 / npc / menus | DIRECT / LIMITED GO | SettingsPresenter / tabButtons — 최종 하위 탭 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.alerts.pvp | 알림 / pvp / menus | DIRECT / LIMITED GO | SettingsPresenter / tabButtons — 최종 하위 탭 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.alerts.threat | 알림 / threat / menus | DIRECT / LIMITED GO | SettingsPresenter / tabButtons — 최종 하위 탭 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.bars | 바 설정 / menus | DIRECT / LIMITED GO | SettingsUI / 사용자 선택 후 최종 표시 — 표시된 페이지 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.bars.cast | 바 설정 / cast / menus | DIRECT / LIMITED GO | SettingsPresenter / tabButtons — 최종 하위 탭 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.bars.cast.player | 시전 / player / menus | DIRECT / LIMITED GO | CastBar.Settings.SelectCastUnit / castButtons — 최종 시전 바 유닛 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.bars.cast.target | 시전 / target / menus | DIRECT / LIMITED GO | CastBar.Settings.SelectCastUnit / castButtons — 최종 시전 바 유닛 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.bars.environment | 바 설정 / environment / menus | DIRECT / LIMITED GO | SettingsPresenter / tabButtons — 최종 하위 탭 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.bars.experience | 바 설정 / experience / menus | DIRECT / LIMITED GO | SettingsPresenter / tabButtons — 최종 하위 탭 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.bars.resource | 바 설정 / resource / menus | DIRECT / LIMITED GO | SettingsPresenter / tabButtons — 최종 하위 탭 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.convenience | 편의 기능 / menus | DIRECT / LIMITED GO | SettingsUI / 사용자 선택 후 최종 표시 — 표시된 페이지 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.convenience.chat | 편의 기능 / chat / menus | DIRECT / LIMITED GO | SettingsPresenter / tabButtons — 최종 하위 탭 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.convenience.general | 편의 기능 / general / menus | DIRECT / LIMITED GO | SettingsPresenter / tabButtons — 최종 하위 탭 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.convenience.highlight | 편의 기능 / highlight / menus | DIRECT / LIMITED GO | SettingsPresenter / tabButtons — 최종 하위 탭 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.convenience.note | 편의 기능 / note / menus | DIRECT / LIMITED GO | SettingsPresenter / tabButtons — 최종 하위 탭 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.convenience.party | 편의 기능 / party / menus | DIRECT / LIMITED GO | SettingsPresenter / tabButtons — 최종 하위 탭 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.convenience.professions | 편의 기능 / professions / menus | DIRECT / LIMITED GO | SettingsPresenter / tabButtons — 최종 하위 탭 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.general | 일반 / menus | DIRECT / LIMITED GO | SettingsUI / 사용자 선택 후 최종 표시 — 표시된 페이지 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.interface | 인터페이스 / menus | DIRECT / LIMITED GO | SettingsUI / 사용자 선택 후 최종 표시 — 표시된 페이지 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.interface.basic | 인터페이스 / basic / menus | DIRECT / LIMITED GO | SettingsPresenter / tabButtons — 최종 하위 탭 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.interface.clock | 인터페이스 / clock / menus | DIRECT / LIMITED GO | SettingsPresenter / tabButtons — 최종 하위 탭 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.interface.cursor | 인터페이스 / cursor / menus | DIRECT / LIMITED GO | SettingsPresenter / tabButtons — 최종 하위 탭 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.interface.range | 인터페이스 / range / menus | DIRECT / LIMITED GO | SettingsPresenter / tabButtons — 최종 하위 탭 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.interface.tooltip | 인터페이스 / tooltip / menus | DIRECT / LIMITED GO | SettingsPresenter / tabButtons — 최종 하위 탭 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.labs | 실험실 / menus | DIRECT / LIMITED GO | SettingsUI / 사용자 선택 후 최종 표시 — 표시된 페이지 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.labs.buff | 실험실 / buff / menus | DIRECT / LIMITED GO | SettingsPresenter / tabButtons — 최종 하위 탭 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.labs.proc | 실험실 / proc / menus | DIRECT / LIMITED GO | SettingsPresenter / tabButtons — 최종 하위 탭 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.minimap | 미니맵 / menus | DIRECT / LIMITED GO | SettingsUI / 사용자 선택 후 최종 표시 — 표시된 페이지 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.minimap.minimap | 미니맵 / minimap / menus | DIRECT / LIMITED GO | SettingsPresenter / tabButtons — 최종 하위 탭 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.minimap.minimapButtons | 미니맵 / minimapButtons / menus | DIRECT / LIMITED GO | SettingsPresenter / tabButtons — 최종 하위 탭 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.partyFrames | 파티·공격대 / menus | DIRECT / LIMITED GO | SettingsUI / 사용자 선택 후 최종 표시 — 표시된 페이지 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.partyFrames.auras | 파티·공격대 / auras / menus | DIRECT / LIMITED GO | SettingsPresenter / tabButtons — 최종 하위 탭 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.partyFrames.common | 파티·공격대 / common / menus | DIRECT / LIMITED GO | SettingsPresenter / tabButtons — 최종 하위 탭 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.partyFrames.frames | 파티·공격대 / frames / menus | DIRECT / LIMITED GO | SettingsPresenter / tabButtons — 최종 하위 탭 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.partyFrames.roles | 파티·공격대 / roles / menus | DIRECT / LIMITED GO | SettingsPresenter / tabButtons — 최종 하위 탭 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.profiles | 프로필 / menus | DIRECT / LIMITED GO | SettingsUI / 사용자 선택 후 최종 표시 — 표시된 페이지 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.quest | 퀘스트 / menus | DIRECT / LIMITED GO | SettingsUI / 사용자 선택 후 최종 표시 — 표시된 페이지 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.quest.navigation | 퀘스트 / navigation / menus | DIRECT / LIMITED GO | SettingsPresenter / tabButtons — 최종 하위 탭 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.quest.tracker | 퀘스트 / tracker / menus | DIRECT / LIMITED GO | SettingsPresenter / tabButtons — 최종 하위 탭 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.unitFrames | 유닛프레임 / menus | DIRECT / LIMITED GO | SettingsUI / 사용자 선택 후 최종 표시 — 표시된 페이지 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.unitFrames.units | 유닛프레임 / units / menus | DIRECT / LIMITED GO | SettingsPresenter / tabButtons — 최종 하위 탭 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.unitFrames.units.focus.bars | focus / bars / menus | DIRECT / LIMITED GO | UnitFrameDetails 유닛·부품 버튼 — 최종 유닛·부품 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.unitFrames.units.focus.basic | focus / basic / menus | DIRECT / LIMITED GO | UnitFrameDetails 유닛·부품 버튼 — 최종 유닛·부품 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.unitFrames.units.focus.labels | focus / labels / menus | DIRECT / LIMITED GO | UnitFrameDetails 유닛·부품 버튼 — 최종 유닛·부품 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.unitFrames.units.focus.status | focus / status / menus | DIRECT / LIMITED GO | UnitFrameDetails 유닛·부품 버튼 — 최종 유닛·부품 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.unitFrames.units.pet.bars | pet / bars / menus | DIRECT / LIMITED GO | UnitFrameDetails 유닛·부품 버튼 — 최종 유닛·부품 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.unitFrames.units.pet.basic | pet / basic / menus | DIRECT / LIMITED GO | UnitFrameDetails 유닛·부품 버튼 — 최종 유닛·부품 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.unitFrames.units.pet.labels | pet / labels / menus | DIRECT / LIMITED GO | UnitFrameDetails 유닛·부품 버튼 — 최종 유닛·부품 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.unitFrames.units.pet.status | pet / status / menus | DIRECT / LIMITED GO | UnitFrameDetails 유닛·부품 버튼 — 최종 유닛·부품 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.unitFrames.units.player.auras | player / auras / menus | DIRECT / LIMITED GO | UnitFrameDetails 유닛·부품 버튼 — 최종 유닛·부품 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.unitFrames.units.player.bars | player / bars / menus | DIRECT / LIMITED GO | UnitFrameDetails 유닛·부품 버튼 — 최종 유닛·부품 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.unitFrames.units.player.basic | player / basic / menus | DIRECT / LIMITED GO | UnitFrameDetails 유닛·부품 버튼 — 최종 유닛·부품 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.unitFrames.units.player.class | player / class / menus | DIRECT / LIMITED GO | UnitFrameDetails 유닛·부품 버튼 — 최종 유닛·부품 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.unitFrames.units.player.labels | player / labels / menus | DIRECT / LIMITED GO | UnitFrameDetails 유닛·부품 버튼 — 최종 유닛·부품 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.unitFrames.units.player.status | player / status / menus | DIRECT / LIMITED GO | UnitFrameDetails 유닛·부품 버튼 — 최종 유닛·부품 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.unitFrames.units.target.auras.attackableNPC | target / auras / attackableNPC / menus | DIRECT / LIMITED GO | UnitFrameDetails.SelectUnitPart / SelectAuraCategory — 최종 유닛·부품·오라 유형 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.unitFrames.units.target.auras.friendlyPlayer | target / auras / friendlyPlayer / menus | DIRECT / LIMITED GO | UnitFrameDetails.SelectUnitPart / SelectAuraCategory — 최종 유닛·부품·오라 유형 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.unitFrames.units.target.bars | target / bars / menus | DIRECT / LIMITED GO | UnitFrameDetails 유닛·부품 버튼 — 최종 유닛·부품 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.unitFrames.units.target.basic | target / basic / menus | DIRECT / LIMITED GO | UnitFrameDetails 유닛·부품 버튼 — 최종 유닛·부품 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.unitFrames.units.target.labels | target / labels / menus | DIRECT / LIMITED GO | UnitFrameDetails 유닛·부품 버튼 — 최종 유닛·부품 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.unitFrames.units.target.status | target / status / menus | DIRECT / LIMITED GO | UnitFrameDetails 유닛·부품 버튼 — 최종 유닛·부품 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.unitFrames.units.targettarget.bars | targettarget / bars / menus | DIRECT / LIMITED GO | UnitFrameDetails 유닛·부품 버튼 — 최종 유닛·부품 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.unitFrames.units.targettarget.basic | targettarget / basic / menus | DIRECT / LIMITED GO | UnitFrameDetails 유닛·부품 버튼 — 최종 유닛·부품 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.unitFrames.units.targettarget.labels | targettarget / labels / menus | DIRECT / LIMITED GO | UnitFrameDetails 유닛·부품 버튼 — 최종 유닛·부품 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| menu.unitFrames.units.targettarget.status | targettarget / status / menus | DIRECT / LIMITED GO | UnitFrameDetails 유닛·부품 버튼 — 최종 유닛·부품 방문·체류 | 방문은 최종 목적지 기준; 체류는 게임 창 비활성 시간 제외 불가, AFK 감지 조건부 |
| setting.basicUI.control001 | Blizzard 기본 프레임 이동 / settings | BRIDGE / GO | KHQOL/BasicUI/FrameMover.lua:245 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.basicUI.control002 | 이동 키 (+ 드래그) / settings | BRIDGE / GO | KHQOL/BasicUI/FrameMover.lua:247 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.basicUI.control003 | 기본 알림 위치·크기 변경 / settings | BRIDGE / GO | KHQOL/BasicUI/NativeAlerts.lua:275 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.basicUI.control004 | 도안 습득 알림 크기 / settings | BRIDGE / GO | KHQOL/BasicUI/NativeAlerts.lua:282 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.basicUI.control005 | 글자 크기 / settings | BRIDGE / GO | KHQOL/BasicUI/NativeAlerts.lua:282 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.basicUI.control006 | 주사위 굴림 외형 변경 / settings | BRIDGE / GO | KHQOL/BasicUI/NativeAlerts.lua:275 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.basicUI.control007 | 창 크기 / settings | BRIDGE / GO | KHQOL/BasicUI/NativeAlerts.lua:282 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.basicUI.control008 | 가방 버튼 표시 방식 / settings | BRIDGE / GO | KHQOL/BasicUI/Settings.lua:13 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.basicUI.control009 | 공통 숨김 지연 / settings | BRIDGE / GO | KHQOL/BasicUI/Settings.lua:19 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.basicUI.control010 | 메뉴바 표시 방식 / settings | BRIDGE / GO | KHQOL/BasicUI/Settings.lua:14 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.campfire.control001 | 야영 효과 획득 후 재알림 지연 / settings | BRIDGE / GO | KHQOL_Campfire/UI/Settings.lua:7 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.campfire.control002 | 글자 크기 / settings | BRIDGE / GO | KHQOL_Campfire/UI/Settings.lua:24 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.campfire.control003 | 아이콘 크기 / settings | BRIDGE / GO | KHQOL_Campfire/UI/Settings.lua:21 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.campfire.control004 | 표시할 문구 / settings | BRIDGE / GO | KHQOL_Campfire/UI/Settings.lua:26 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.campfire.control005 | 위치 잠금 / settings | BRIDGE / GO | KHQOL_Campfire/UI/Settings.lua:10 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.castBar.player.control001 | Blizzard 시전 바 숨김 / settings | BRIDGE / GO | KHQOL/BasicUI/CastBar/Settings.lua:12 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.castBar.player.control002 | 진행 방향 / settings | BRIDGE / GO | KHQOL/BasicUI/CastBar/Settings.lua:18 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.castBar.player.control003 | 높이 / settings | BRIDGE / GO | KHQOL/BasicUI/CastBar/Settings.lua:15 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.castBar.player.control004 | 바 색상 / settings | BRIDGE / GO | KHQOL/BasicUI/CastBar/Settings.lua:21 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.castBar.player.control005 | 배경 색상 / settings | BRIDGE / GO | KHQOL/BasicUI/CastBar/Settings.lua:21 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.castBar.player.control006 | 시전 중단 색상 / settings | BRIDGE / GO | KHQOL/BasicUI/CastBar/Settings.lua:21 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.castBar.player.control007 | 텍스처 / settings | BRIDGE / GO | KHQOL/BasicUI/CastBar/Settings.lua:18 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.castBar.player.control008 | 폭 / settings | BRIDGE / GO | KHQOL/BasicUI/CastBar/Settings.lua:15 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.castBar.player.control009 | 글자 크기 / settings | BRIDGE / GO | KHQOL/BasicUI/CastBar/Settings.lua:15 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.castBar.player.control010 | 스킬명 표시 / settings | BRIDGE / GO | KHQOL/BasicUI/CastBar/Settings.lua:12 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.castBar.player.control011 | 표시 위치 / settings | BRIDGE / GO | KHQOL/BasicUI/CastBar/Settings.lua:18 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.castBar.player.control012 | 글자 크기 / settings | BRIDGE / GO | KHQOL/BasicUI/CastBar/Settings.lua:15 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.castBar.player.control013 | 시전 시간 표시 / settings | BRIDGE / GO | KHQOL/BasicUI/CastBar/Settings.lua:12 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.castBar.player.control014 | 표시 위치 / settings | BRIDGE / GO | KHQOL/BasicUI/CastBar/Settings.lua:18 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.castBar.player.control015 | 표시 형식 / settings | BRIDGE / GO | KHQOL/BasicUI/CastBar/Settings.lua:18 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.castBar.player.control016 | 스킬 아이콘 표시 / settings | BRIDGE / GO | KHQOL/BasicUI/CastBar/Settings.lua:12 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.castBar.player.control017 | 아이콘 위치 / settings | BRIDGE / GO | KHQOL/BasicUI/CastBar/Settings.lua:18 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.castBar.player.control018 | 아이콘 크기 / settings | BRIDGE / GO | KHQOL/BasicUI/CastBar/Settings.lua:15 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.castBar.player.control019 | ResourceSwing 폭에 맞춤 / settings | BRIDGE / GO | KHQOL/BasicUI/CastBar/Settings.lua:12 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.castBar.player.control020 | X 위치 / settings | BRIDGE / GO | KHQOL/BasicUI/CastBar/Settings.lua:15 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.castBar.player.control021 | Y 위치 / settings | BRIDGE / GO | KHQOL/BasicUI/CastBar/Settings.lua:15 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.castBar.player.control022 | 간격 / settings | BRIDGE / GO | KHQOL/BasicUI/CastBar/Settings.lua:15 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.castBar.player.control023 | 배치 기준 / settings | BRIDGE / GO | KHQOL/BasicUI/CastBar/Settings.lua:18 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.castBar.player.control024 | 위치 잠금 / settings | BRIDGE / GO | KHQOL/BasicUI/CastBar/Settings.lua:12 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.castBar.target.control025 | KHQOL 대상 시전바 사용 / settings | BRIDGE / GO | KHQOL/BasicUI/CastBar/Settings.lua:85 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.castBar.target.control026 | 대상 시전바 X 위치 보정 / settings | BRIDGE / GO | KHQOL/BasicUI/CastBar/Settings.lua:87 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.castBar.target.control027 | 대상 시전바 Y 위치 보정 / settings | BRIDGE / GO | KHQOL/BasicUI/CastBar/Settings.lua:87 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.castBar.target.control028 | 높이 / settings | BRIDGE / GO | KHQOL/BasicUI/CastBar/Settings.lua:94 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.castBar.target.control029 | 바 색상 / settings | BRIDGE / GO | KHQOL/BasicUI/CastBar/Settings.lua:108 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.castBar.target.control030 | 배경 색상 / settings | BRIDGE / GO | KHQOL/BasicUI/CastBar/Settings.lua:108 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.castBar.target.control031 | 시전 중단 색상 / settings | BRIDGE / GO | KHQOL/BasicUI/CastBar/Settings.lua:108 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.castBar.target.control032 | 텍스처 / settings | BRIDGE / GO | KHQOL/BasicUI/CastBar/Settings.lua:100 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.castBar.target.control033 | 폭 / settings | BRIDGE / GO | KHQOL/BasicUI/CastBar/Settings.lua:94 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.castBar.target.control034 | 글자 크기 / settings | BRIDGE / GO | KHQOL/BasicUI/CastBar/Settings.lua:94 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.castBar.target.control035 | 스킬명 표시 / settings | BRIDGE / GO | KHQOL/BasicUI/CastBar/Settings.lua:97 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.castBar.target.control036 | 표시 위치 / settings | BRIDGE / GO | KHQOL/BasicUI/CastBar/Settings.lua:100 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.castBar.target.control037 | 스킬 아이콘 표시 / settings | BRIDGE / GO | KHQOL/BasicUI/CastBar/Settings.lua:97 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.castBar.target.control038 | 아이콘 위치 / settings | BRIDGE / GO | KHQOL/BasicUI/CastBar/Settings.lua:100 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.castBar.target.control039 | 아이콘 크기 / settings | BRIDGE / GO | KHQOL/BasicUI/CastBar/Settings.lua:94 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.clock.control005.common | 글자 색상 / common / settings | BRIDGE / GO | KHQOL_Clock/Clock/Settings.lua:33 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.clock.control005.date | 글자 색상 / date / settings | BRIDGE / GO | KHQOL_Clock/Clock/Settings.lua:33 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.clock.control005.guild | 글자 색상 / guild / settings | BRIDGE / GO | KHQOL_Clock/Clock/Settings.lua:33 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.clock.control005.money | 글자 색상 / money / settings | BRIDGE / GO | KHQOL_Clock/Clock/Settings.lua:33 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.clock.control005.performance | 글자 색상 / performance / settings | BRIDGE / GO | KHQOL_Clock/Clock/Settings.lua:33 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.clock.control005.weekday | 글자 색상 / weekday / settings | BRIDGE / GO | KHQOL_Clock/Clock/Settings.lua:33 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.clock.control006.common | 글자 크기 / common / settings | BRIDGE / GO | KHQOL_Clock/Clock/Settings.lua:110 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.clock.control006.date | 글자 크기 / date / settings | BRIDGE / GO | KHQOL_Clock/Clock/Settings.lua:110 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.clock.control006.guild | 글자 크기 / guild / settings | BRIDGE / GO | KHQOL_Clock/Clock/Settings.lua:110 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.clock.control006.money | 글자 크기 / money / settings | BRIDGE / GO | KHQOL_Clock/Clock/Settings.lua:110 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.clock.control006.performance | 글자 크기 / performance / settings | BRIDGE / GO | KHQOL_Clock/Clock/Settings.lua:110 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.clock.control006.weekday | 글자 크기 / weekday / settings | BRIDGE / GO | KHQOL_Clock/Clock/Settings.lua:110 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.clock.control007.common | 텍스트 효과 / common / settings | BRIDGE / GO | KHQOL_Clock/Clock/Settings.lua:36 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.clock.control007.date | 텍스트 효과 / date / settings | BRIDGE / GO | KHQOL_Clock/Clock/Settings.lua:36 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.clock.control007.guild | 텍스트 효과 / guild / settings | BRIDGE / GO | KHQOL_Clock/Clock/Settings.lua:36 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.clock.control007.money | 텍스트 효과 / money / settings | BRIDGE / GO | KHQOL_Clock/Clock/Settings.lua:36 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.clock.control007.performance | 텍스트 효과 / performance / settings | BRIDGE / GO | KHQOL_Clock/Clock/Settings.lua:36 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.clock.control007.weekday | 텍스트 효과 / weekday / settings | BRIDGE / GO | KHQOL_Clock/Clock/Settings.lua:36 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.clock.control008 | 글자 색상 / settings | BRIDGE / GO | KHQOL_Clock/Clock/Settings.lua:33 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.clock.control009 | 글자 크기 / settings | BRIDGE / GO | KHQOL_Clock/Clock/Settings.lua:103 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.clock.control010 | 텍스트 효과 / settings | BRIDGE / GO | KHQOL_Clock/Clock/Settings.lua:36 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.clock.control015 | FPS / 지연시간 / settings | BRIDGE / GO | KHQOL_Clock/Clock/Settings.lua:43 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.clock.control016 | 골드 / settings | BRIDGE / GO | KHQOL_Clock/Clock/Settings.lua:55 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.clock.control017 | 날짜 / settings | BRIDGE / GO | KHQOL_Clock/Clock/Settings.lua:43 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.clock.control019 | 소지금 / settings | BRIDGE / GO | KHQOL_Clock/Clock/Settings.lua:43 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.clock.control020 | 실버 / settings | BRIDGE / GO | KHQOL_Clock/Clock/Settings.lua:55 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.clock.control021 | 요일 / settings | BRIDGE / GO | KHQOL_Clock/Clock/Settings.lua:43 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.clock.control023 | 코퍼 / settings | BRIDGE / GO | KHQOL_Clock/Clock/Settings.lua:55 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.clock.control024 | 달력 마우스 입력 / settings | BRIDGE / GO | KHQOL_Clock/Clock/Settings.lua:74 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.clock.control025 | 달력 보조키 / settings | BRIDGE / GO | KHQOL_Clock/Clock/Settings.lua:73 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.clock.control026 | 리로드 마우스 입력 / settings | BRIDGE / GO | KHQOL_Clock/Clock/Settings.lua:74 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.clock.control027 | 리로드 보조키 / settings | BRIDGE / GO | KHQOL_Clock/Clock/Settings.lua:73 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.clock.control028 | 타이머·알람·스톱워치 마우스 입력 / settings | BRIDGE / GO | KHQOL_Clock/Clock/Settings.lua:74 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.clock.control029 | 타이머·알람·스톱워치 보조키 / settings | BRIDGE / GO | KHQOL_Clock/Clock/Settings.lua:73 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.clock.control030 | 포에버 노트 마우스 입력 / settings | BRIDGE / GO | KHQOL_Clock/Clock/Settings.lua:74 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.clock.control031 | 포에버 노트 보조키 / settings | BRIDGE / GO | KHQOL_Clock/Clock/Settings.lua:73 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.clock.dateFormat | 날짜 형식 / settings | BRIDGE / GO | KHQOL_Clock/Clock/Settings.lua:51 — 유효한 최종 설정 변경 | 허용 목록의 마우스 클릭·라벨 경로; 키보드 선택은 미계측 |
| setting.clock.guildBackground | 배경 표시 / settings | BRIDGE / GO | KHQOL_Clock/Clock/Settings.lua:95 — 유효한 최종 설정 변경 | 허용 목록의 마우스 클릭·라벨 경로; 키보드 선택은 미계측 |
| setting.clock.guildTitle | 타이틀 표시 / settings | BRIDGE / GO | KHQOL_Clock/Clock/Settings.lua:94 — 유효한 최종 설정 변경 | 허용 목록의 마우스 클릭·라벨 경로; 키보드 선택은 미계측 |
| setting.clock.guildTooltipLimit | 툴팁 명단 축약 기준 / settings | BRIDGE / GO | KHQOL_Clock/Clock/Settings.lua:96 — 유효한 최종 설정 변경 | drag·input 경로; 화살표 UI는 향후 작업 |
| setting.clock.guildVisible | 길드 접속 표시 / settings | BRIDGE / GO | KHQOL_Clock/Clock/Settings.lua:92 — 유효한 최종 설정 변경 | 허용 목록의 마우스 클릭·라벨 경로; 키보드 선택은 미계측 |
| setting.clock.locked | 위치 잠금 / settings | BRIDGE / GO | KHQOL_Clock/Clock/Settings.lua:100 — 유효한 최종 설정 변경 | 허용 목록의 마우스 클릭·라벨 경로; 키보드 선택은 미계측 |
| setting.clock.timerBarLocked | 타이머 바 위치 잠금 / settings | BRIDGE / GO | KHQOL_Clock/Clock/Settings.lua:127 — 유효한 최종 설정 변경 | 허용 목록의 마우스 클릭·라벨 경로; 키보드 선택은 미계측 |
| setting.clock.toolsLocked | 도구 창 위치 잠금 / settings | BRIDGE / GO | KHQOL_Clock/Clock/Settings.lua:124 — 유효한 최종 설정 변경 | 허용 목록의 마우스 클릭·라벨 경로; 키보드 선택은 미계측 |
| setting.clock.toolsScale | 알람·타이머 창 크기 / settings | BRIDGE / GO | KHQOL_Clock/Clock/Settings.lua:121 — 유효한 최종 설정 변경 | drag·input 경로; 화살표 UI는 향후 작업 |
| setting.clock.weekdayLanguage | 요일 언어 / settings | BRIDGE / GO | KHQOL_Clock/Clock/Settings.lua:52 — 유효한 최종 설정 변경 | 허용 목록의 마우스 클릭·라벨 경로; 키보드 선택은 미계측 |
| setting.color.confirmed | 색상 최종 변경 / settings | HOLD / HOLD | UI.OpenColorPicker 최종 확정/취소 — 미리보기·취소 복원 제외 후 최종 변경 | 호환용 미사용 합계 ID. 개별 고정 설정 ID에서 수집 |
| setting.combatStatus.control001 | 글씨 크기 / settings | BRIDGE / GO | KHQOL_CombatStatus/Modules/CombatStatus.lua:353 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.combatStatus.control002 | 위치 잠금 / settings | BRIDGE / GO | KHQOL_CombatStatus/Modules/CombatStatus.lua:318 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.combatStatus.control003 | 문구 (Enter로 저장) / settings | BRIDGE / GO | KHQOL_CombatStatus/Modules/CombatStatus.lua:325 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.combatStatus.control004 | 문구 표시 / settings | BRIDGE / GO | KHQOL_CombatStatus/Modules/CombatStatus.lua:318 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.combatStatus.control005 | 문구 (Enter로 저장) / settings | BRIDGE / GO | KHQOL_CombatStatus/Modules/CombatStatus.lua:325 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.combatStatus.control006 | 문구 표시 / settings | BRIDGE / GO | KHQOL_CombatStatus/Modules/CombatStatus.lua:318 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.combatStatus.control007 | 아이콘 크기 / settings | BRIDGE / GO | KHQOL_CombatStatus/Modules/CombatStatus.lua:356 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.combatStatus.control008 | 칼 애니메이션 ON/OFF / settings | BRIDGE / GO | KHQOL_CombatStatus/Modules/CombatStatus.lua:318 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.combatStatus.control009 | 전투 종료 시 전투 시간 표시 / settings | BRIDGE / GO | KHQOL_CombatStatus/Modules/CombatStatus.lua:318 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.combatStatus.control010 | 페이드 아웃 / settings | BRIDGE / GO | KHQOL_CombatStatus/Modules/CombatStatus.lua:318 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.combatStatus.control011 | 표시 시간 / settings | BRIDGE / GO | KHQOL_CombatStatus/Modules/CombatStatus.lua:359 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.convenienceChat.control001 | 공격대 말머리 (최대 10글자) / settings | BRIDGE / GO | KHQOL_Convenience/UI/ConvenienceDetails.lua:21 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.convenienceChat.control002 | 길드 말머리 (최대 10글자) / settings | BRIDGE / GO | KHQOL_Convenience/UI/ConvenienceDetails.lua:21 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.convenienceChat.control003 | 말머리 사용 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ConvenienceDetails.lua:9 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.convenienceChat.control004 | 일반 말머리 (최대 10글자) / settings | BRIDGE / GO | KHQOL_Convenience/UI/ConvenienceDetails.lua:21 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.convenienceChat.control005 | 파티 말머리 (최대 10글자) / settings | BRIDGE / GO | KHQOL_Convenience/UI/ConvenienceDetails.lua:21 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.convenienceParty.control001 | 파티 버튼 크기 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ConvenienceDetails.lua:120 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.convenienceParty.control002 | 파티 버튼 투명도 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ConvenienceDetails.lua:122 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.convenienceParty.control003 | 파티 버튼 표시 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ConvenienceDetails.lua:118 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.convenienceParty.control004 | 파티 인사 메시지 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ConvenienceDetails.lua:126 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.convenienceParty.control005 | 파티 작별 인사 메시지 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ConvenienceDetails.lua:126 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.convenienceParty.control006 | 공격대 자동 인사 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ConvenienceDetails.lua:9 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.convenienceParty.control007 | 인사말 (캐릭터별 저장 · 최대 255바이트) / settings | BRIDGE / GO | KHQOL_Convenience/UI/ConvenienceDetails.lua:26 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.convenienceParty.control008 | 파티 자동 인사 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ConvenienceDetails.lua:9 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.convenienceParty.control009 | Alt+좌클릭 파티 초대 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ConvenienceDetails.lua:9 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.cursorTrail.control001 | 유지 시간 / settings | BRIDGE / GO | KHQOL_CursorTrail/CursorTrail/Settings.lua:13 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.cursorTrail.control002 | 포인트 간격 / settings | BRIDGE / GO | KHQOL_CursorTrail/CursorTrail/Settings.lua:12 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.cursorTrail.control003 | 색상 / settings | BRIDGE / GO | KHQOL_CursorTrail/CursorTrail/Settings.lua:9 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.cursorTrail.control004 | 잔상 길이 / settings | BRIDGE / GO | KHQOL_CursorTrail/CursorTrail/Settings.lua:7 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.cursorTrail.control005 | 크기 / settings | BRIDGE / GO | KHQOL_CursorTrail/CursorTrail/Settings.lua:8 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.cursorTrail.control006 | 투명도 / settings | BRIDGE / GO | KHQOL_CursorTrail/CursorTrail/Settings.lua:10 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.environmentTimer.control001 | HUD 바 두께 / settings | BRIDGE / GO | KHQOL_EnvironmentTimer/UI/Settings.lua:14 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.environmentTimer.control002 | HUD 전체 크기 / settings | BRIDGE / GO | KHQOL_EnvironmentTimer/UI/Settings.lua:14 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.environmentTimer.control003 | HUD 좌우 간격 / settings | BRIDGE / GO | KHQOL_EnvironmentTimer/UI/Settings.lua:14 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.environmentTimer.control004 | 높이 / settings | BRIDGE / GO | KHQOL_EnvironmentTimer/UI/Settings.lua:14 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.environmentTimer.control005 | 배율 / settings | BRIDGE / GO | KHQOL_EnvironmentTimer/UI/Settings.lua:14 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.environmentTimer.control006 | 세로 채우는 방향 / settings | BRIDGE / GO | KHQOL_EnvironmentTimer/UI/Settings.lua:21 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.environmentTimer.control007 | 투명도 / settings | BRIDGE / GO | KHQOL_EnvironmentTimer/UI/Settings.lua:14 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.environmentTimer.control008 | 폭 / settings | BRIDGE / GO | KHQOL_EnvironmentTimer/UI/Settings.lua:14 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.environmentTimer.control009 | 긴급 시 경고음 / settings | BRIDGE / GO | KHQOL_EnvironmentTimer/UI/Settings.lua:11 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.environmentTimer.control010 | 긴급 시 중앙 경고 / settings | BRIDGE / GO | KHQOL_EnvironmentTimer/UI/Settings.lua:11 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.environmentTimer.control011 | 긴급 시작 (초) / settings | BRIDGE / GO | KHQOL_EnvironmentTimer/UI/Settings.lua:14 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.environmentTimer.control012 | 위험 시작 (%) / settings | BRIDGE / GO | KHQOL_EnvironmentTimer/UI/Settings.lua:14 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.environmentTimer.control013 | 주의 시작 (%) / settings | BRIDGE / GO | KHQOL_EnvironmentTimer/UI/Settings.lua:14 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.environmentTimer.control014 | X 위치 / settings | BRIDGE / GO | KHQOL_EnvironmentTimer/UI/Settings.lua:14 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.environmentTimer.control015 | Y 위치 / settings | BRIDGE / GO | KHQOL_EnvironmentTimer/UI/Settings.lua:14 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.environmentTimer.control016 | 위치 잠금 / settings | BRIDGE / GO | KHQOL_EnvironmentTimer/UI/Settings.lua:33 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.environmentTimer.control017 | HUD 텍스트 크기 / settings | BRIDGE / GO | KHQOL_EnvironmentTimer/UI/Settings.lua:14 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.environmentTimer.control018 | 남은 시간 / settings | BRIDGE / GO | KHQOL_EnvironmentTimer/UI/Settings.lua:11 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.environmentTimer.control019 | 타이머 이름 / settings | BRIDGE / GO | KHQOL_EnvironmentTimer/UI/Settings.lua:11 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.environmentTimer.control020 | 텍스트 형식 / settings | BRIDGE / GO | KHQOL_EnvironmentTimer/UI/Settings.lua:21 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.environmentTimer.control021 | 퍼센트 / settings | BRIDGE / GO | KHQOL_EnvironmentTimer/UI/Settings.lua:11 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.environmentTimer.control022 | 표시 형태 / settings | BRIDGE / GO | KHQOL_EnvironmentTimer/UI/Settings.lua:21 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.environmentTimer.control023 | 죽은척 하기 / settings | BRIDGE / GO | KHQOL_EnvironmentTimer/UI/Settings.lua:11 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.environmentTimer.control024 | 피로도 / settings | BRIDGE / GO | KHQOL_EnvironmentTimer/UI/Settings.lua:11 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.environmentTimer.control025 | 호흡 / settings | BRIDGE / GO | KHQOL_EnvironmentTimer/UI/Settings.lua:11 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.experienceBar.control001 | PlayerFrame과의 간격 / settings | BRIDGE / GO | KHQOL_ExperienceBar/UI/ExperienceSettings.lua:11 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.experienceBar.control002 | X 오프셋 / settings | BRIDGE / GO | KHQOL_ExperienceBar/UI/ExperienceSettings.lua:11 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.experienceBar.control003 | Y 오프셋 / settings | BRIDGE / GO | KHQOL_ExperienceBar/UI/ExperienceSettings.lua:11 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.experienceBar.control004 | 가로 길이 / settings | BRIDGE / GO | KHQOL_ExperienceBar/UI/ExperienceSettings.lua:11 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.experienceBar.control005 | 바 두께 / settings | BRIDGE / GO | KHQOL_ExperienceBar/UI/ExperienceSettings.lua:11 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.experienceBar.control006 | 세로 길이 / settings | BRIDGE / GO | KHQOL_ExperienceBar/UI/ExperienceSettings.lua:11 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.experienceBar.control007 | Blizzard 기본 경험치 바 숨김 / settings | BRIDGE / GO | KHQOL_ExperienceBar/UI/ExperienceSettings.lua:8 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.experienceBar.control008 | 기본 UI 평판 표시 연동 / settings | BRIDGE / GO | KHQOL_ExperienceBar/UI/ExperienceSettings.lua:8 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.experienceBar.control009 | 최대 레벨에서 숨김 / settings | BRIDGE / GO | KHQOL_ExperienceBar/UI/ExperienceSettings.lua:8 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.experienceBar.control010 | 경험치 바 색상 / settings | BRIDGE / GO | KHQOL_ExperienceBar/UI/ExperienceSettings.lua:69 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.experienceBar.control011 | 배경 색상 / settings | BRIDGE / GO | KHQOL_ExperienceBar/UI/ExperienceSettings.lua:69 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.experienceBar.control012 | 텍스트 색상 / settings | BRIDGE / GO | KHQOL_ExperienceBar/UI/ExperienceSettings.lua:69 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.experienceBar.control013 | 레벨업 예상 표시 / settings | BRIDGE / GO | KHQOL_ExperienceBar/UI/ExperienceSettings.lua:8 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.experienceBar.control014 | 예상 경험치 색상 / settings | BRIDGE / GO | KHQOL_ExperienceBar/UI/ExperienceSettings.lua:80 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.experienceBar.control015 | 예상 경험치 수치 표시 / settings | BRIDGE / GO | KHQOL_ExperienceBar/UI/ExperienceSettings.lua:8 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.experienceBar.control016 | 완료 퀘스트 경험치 표시 / settings | BRIDGE / GO | KHQOL_ExperienceBar/UI/ExperienceSettings.lua:8 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.experienceBar.control017 | X 위치 / settings | BRIDGE / GO | KHQOL_ExperienceBar/UI/ExperienceSettings.lua:11 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.experienceBar.control018 | Y 위치 / settings | BRIDGE / GO | KHQOL_ExperienceBar/UI/ExperienceSettings.lua:11 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.experienceBar.control019 | 위치 잠금 / settings | BRIDGE / GO | KHQOL_ExperienceBar/UI/ExperienceSettings.lua:34 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.experienceBar.control020 | 높이 / settings | BRIDGE / GO | KHQOL_ExperienceBar/UI/ExperienceSettings.lua:11 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.experienceBar.control021 | 폭 / settings | BRIDGE / GO | KHQOL_ExperienceBar/UI/ExperienceSettings.lua:11 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.experienceBar.control022 | 가로형 텍스트 위치 / settings | BRIDGE / GO | KHQOL_ExperienceBar/UI/ExperienceSettings.lua:15 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.experienceBar.control023 | 경험치 텍스트 표시 / settings | BRIDGE / GO | KHQOL_ExperienceBar/UI/ExperienceSettings.lua:8 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.experienceBar.control024 | 경험치 텍스트 형식 / settings | BRIDGE / GO | KHQOL_ExperienceBar/UI/ExperienceSettings.lua:15 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.experienceBar.control025 | 레벨 배치 / settings | BRIDGE / GO | KHQOL_ExperienceBar/UI/ExperienceSettings.lua:15 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.experienceBar.control026 | 레벨 위치 / settings | BRIDGE / GO | KHQOL_ExperienceBar/UI/ExperienceSettings.lua:15 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.experienceBar.control027 | 레벨 표시 문구 / settings | BRIDGE / GO | KHQOL_ExperienceBar/UI/ExperienceSettings.lua:15 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.experienceBar.control028 | 현재 레벨 표시 / settings | BRIDGE / GO | KHQOL_ExperienceBar/UI/ExperienceSettings.lua:8 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.experienceBar.control029 | 경험치 툴팁 표시 / settings | BRIDGE / GO | KHQOL_ExperienceBar/UI/ExperienceSettings.lua:8 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.experienceBar.control030 | 표시 형태 / settings | BRIDGE / GO | KHQOL_ExperienceBar/UI/ExperienceSettings.lua:15 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.experienceBar.control031 | 휴식 경험치 색상 / settings | BRIDGE / GO | KHQOL_ExperienceBar/UI/ExperienceSettings.lua:69 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.experienceBar.control032 | 휴식 경험치 표시 / settings | BRIDGE / GO | KHQOL_ExperienceBar/UI/ExperienceSettings.lua:8 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.experienceBar.control033 | 배율 / settings | BRIDGE / GO | KHQOL_ExperienceBar/UI/ExperienceSettings.lua:11 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.experienceBar.control034 | 투명도 / settings | BRIDGE / GO | KHQOL_ExperienceBar/UI/ExperienceSettings.lua:11 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.general.autoConfirmDestroy | autoConfirmDestroy / settings | BRIDGE / GO | general.moduleControls — 사용자 편의 기능 ON/OFF 변경 |  |
| setting.general.autoRepair | autoRepair / settings | BRIDGE / GO | general.moduleControls — 사용자 편의 기능 ON/OFF 변경 |  |
| setting.general.autoSellJunk | autoSellJunk / settings | BRIDGE / GO | general.moduleControls — 사용자 편의 기능 ON/OFF 변경 |  |
| setting.general.centerTextScale | 중앙 알림 텍스트 크기 / settings | BRIDGE / GO | KHQOL_Convenience/GeneralOptions.lua:386 — 유효한 최종 설정 변경 | drag·input 경로; 화살표 UI는 향후 작업 |
| setting.general.chatEnhancement | chatEnhancement / settings | BRIDGE / GO | general.moduleControls — 사용자 편의 기능 ON/OFF 변경 |  |
| setting.general.debug | 디버그 모드 / settings | BRIDGE / GO | KHQOL/SettingsUI.lua:142 — 유효한 최종 설정 변경 | 허용 목록의 마우스 클릭·라벨 경로; 키보드 선택은 미계측 |
| setting.general.locked | 설정 잠금 / settings | BRIDGE / GO | KHQOL/SettingsUI.lua:140 — 유효한 최종 설정 변경 | 허용 목록의 마우스 클릭·라벨 경로; 키보드 선택은 미계측 |
| setting.general.minimapVisible | KHQOL 미니맵 버튼 표시 / settings | BRIDGE / GO | KHQOL/SettingsUI.lua:136 — 유효한 최종 설정 변경 | 허용 목록의 마우스 클릭·라벨 경로; 키보드 선택은 미계측 |
| setting.general.windowOverlap | 기본 UI와 겹칠 때 / settings | BRIDGE / GO | KHQOL/SettingsUI.lua:88 — 유효한 최종 설정 변경 | 허용 목록의 마우스 클릭·라벨 경로; 키보드 선택은 미계측 |
| setting.generalConvenience.centerTextScale | 중앙 알림 텍스트 크기 / settings | DIRECT / GO | SettingsNavigation.Attach / generalConvenience — 유효한 최종 설정 변경 | drag·input 경로; 화살표 UI는 향후 작업 |
| setting.generalConvenience.control001 | 가방 휴지통 사용 / settings | BRIDGE / GO | KHQOL_Convenience/UI/BagItemSettings.lua:17 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.generalConvenience.control002 | 고급 / settings | BRIDGE / GO | KHQOL_Convenience/UI/BagItemSettings.lua:52 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.generalConvenience.control003 | 영웅 / settings | BRIDGE / GO | KHQOL_Convenience/UI/BagItemSettings.lua:52 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.generalConvenience.control004 | 위치 잠금 / settings | BRIDGE / GO | KHQOL_Convenience/UI/BagItemSettings.lua:28 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.generalConvenience.control005 | 일반 / settings | BRIDGE / GO | KHQOL_Convenience/UI/BagItemSettings.lua:52 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.generalConvenience.control006 | 퀘스트 분류 일반 아이템도 즉시 파괴 / settings | BRIDGE / GO | KHQOL_Convenience/UI/BagItemSettings.lua:62 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.generalConvenience.control007 | 하급 / settings | BRIDGE / GO | KHQOL_Convenience/UI/BagItemSettings.lua:52 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.generalConvenience.control008 | 휴지통 배치 / settings | BRIDGE / GO | KHQOL_Convenience/UI/BagItemSettings.lua:27 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.generalConvenience.control009 | 휴지통 아이콘 크기 / settings | BRIDGE / GO | KHQOL_Convenience/UI/BagItemSettings.lua:44 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.generalConvenience.control010 | 희귀 / settings | BRIDGE / GO | KHQOL_Convenience/UI/BagItemSettings.lua:52 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.generalConvenience.control011 | 버프 감사 메시지 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ConvenienceDetails.lua:148 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.generalConvenience.control012 | 버프 아이콘 크기 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ConvenienceDetails.lua:145 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.generalConvenience.control013 | 버프 알림 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ConvenienceDetails.lua:145 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.generalConvenience.control014 | 새 알림 표시 방향 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ConvenienceDetails.lua:145 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.generalConvenience.control015 | 알림 유지 시간 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ConvenienceDetails.lua:145 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.generalConvenience.control016 | 보호 목록 관리 / settings | BRIDGE / GO | KHQOL_Convenience/UI/BagItemSettings.lua:112 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.generalConvenience.control017 | 가방 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ConvenienceDetails.lua:7 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.generalConvenience.control018 | 거절 채팅 알림 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ConvenienceDetails.lua:7 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.generalConvenience.control019 | 결투 요청 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ConvenienceDetails.lua:7 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.generalConvenience.control020 | 기본 대화창 편의 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ConvenienceDetails.lua:9 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.generalConvenience.control021 | 길드 자금 우선 사용 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ConvenienceDetails.lua:9 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.generalConvenience.control022 | 길드 초대 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ConvenienceDetails.lua:9 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.generalConvenience.control023 | 길드원 허용 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ConvenienceDetails.lua:7 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.generalConvenience.control024 | 도안 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ConvenienceDetails.lua:7 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.generalConvenience.control025 | 상인 판매목록 확장 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ConvenienceDetails.lua:7 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.generalConvenience.control026 | 상점 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ConvenienceDetails.lua:7 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.generalConvenience.control027 | 아이템 파괴 자동 입력 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ConvenienceDetails.lua:9 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.generalConvenience.control028 | 이미 습득한 아이템 표시 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ConvenienceDetails.lua:7 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.generalConvenience.control029 | 자동 수리 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ConvenienceDetails.lua:9 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.generalConvenience.control030 | 잡템 자동 판매 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ConvenienceDetails.lua:9 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.generalConvenience.control031 | 착용 아이템 레벨 표시 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ConvenienceDetails.lua:7 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.generalConvenience.control032 | 친구 허용 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ConvenienceDetails.lua:7 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.generalConvenience.control033 | 퀘스트 보상 최고 판매가 표시 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ConvenienceDetails.lua:7 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.generalConvenience.control034 | 탈것 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ConvenienceDetails.lua:7 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.generalConvenience.control035 | 파티 초대 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ConvenienceDetails.lua:9 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.minimap.minimap.control001 | 모양 / settings | BRIDGE / GO | KHQOL_Map/Settings.lua:29 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.minimap.minimap.control002 | 미니맵 크기 / settings | BRIDGE / GO | KHQOL_Map/Settings.lua:25 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.minimap.minimap.control003 | 외형 사용 / settings | BRIDGE / GO | KHQOL_Map/Settings.lua:22 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.minimap.minimap.control007 | 검색 / settings | BRIDGE / GO | KHQOL_Map/Settings.lua:115 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.minimap.minimap.control008 | 낮/밤 / settings | BRIDGE / GO | KHQOL_Map/Settings.lua:115 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.minimap.minimap.control009 | 아이콘 크기 / settings | BRIDGE / GO | KHQOL_Map/Settings.lua:25 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.minimap.minimap.control010 | 우편 / settings | BRIDGE / GO | KHQOL_Map/Settings.lua:115 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.minimap.minimap.control011 | 잠금 / settings | BRIDGE / GO | KHQOL_Map/Settings.lua:22 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.minimap.minimap.control014 | 위치 / settings | BRIDGE / GO | KHQOL_Map/Settings.lua:29 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.minimap.minimap.control015 | 지역명 크기 / settings | BRIDGE / GO | KHQOL_Map/Settings.lua:25 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.minimap.minimap.control016 | 표시 / settings | BRIDGE / GO | KHQOL_Map/Settings.lua:22 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.minimap.minimapButtons.control004 | 방향 / settings | BRIDGE / GO | KHQOL_Map/Settings.lua:29 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.minimap.minimapButtons.control005 | 사용 / settings | BRIDGE / GO | KHQOL_Map/Settings.lua:22 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.minimap.minimapButtons.control006 | 아이콘 크기 / settings | BRIDGE / GO | KHQOL_Map/Settings.lua:25 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.minimap.minimapButtons.control012 | 가로형 / settings | BRIDGE / GO | KHQOL_Map/Settings.lua:176 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.minimap.minimapButtons.control013 | 세로형 / settings | BRIDGE / GO | KHQOL_Map/Settings.lua:176 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.module.basicUI | basicUI 사용 ON/OFF / settings | BRIDGE / GO | KHQOL UI 공통 체크박스 확정 지점 — 사용자 조작 전후 저장된 활성 설정 변경 | 사용자 저장 상태 변경; 재적용 제외 |
| setting.module.buffReminder | buffReminder 사용 ON/OFF / settings | BRIDGE / GO | KHQOL UI 공통 체크박스 확정 지점 — 사용자 조작 전후 저장된 활성 설정 변경 | 사용자 저장 상태 변경; 재적용 제외 |
| setting.module.campfire | campfire 사용 ON/OFF / settings | BRIDGE / GO | KHQOL UI 공통 체크박스 확정 지점 — 사용자 조작 전후 저장된 활성 설정 변경 | 사용자 저장 상태 변경; 재적용 제외 |
| setting.module.castBar | castBar 사용 ON/OFF / settings | BRIDGE / GO | KHQOL UI 공통 체크박스 확정 지점 — 사용자 조작 전후 저장된 활성 설정 변경 | 사용자 저장 상태 변경; 재적용 제외 |
| setting.module.clock | clock 사용 ON/OFF / settings | BRIDGE / GO | KHQOL UI 공통 체크박스 확정 지점 — 사용자 조작 전후 저장된 활성 설정 변경 | 사용자 저장 상태 변경; 재적용 제외 |
| setting.module.combatStatus | combatStatus 사용 ON/OFF / settings | BRIDGE / GO | KHQOL UI 공통 체크박스 확정 지점 — 사용자 조작 전후 저장된 활성 설정 변경 | 사용자 저장 상태 변경; 재적용 제외 |
| setting.module.cursorTrail | cursorTrail 사용 ON/OFF / settings | BRIDGE / GO | KHQOL UI 공통 체크박스 확정 지점 — 사용자 조작 전후 저장된 활성 설정 변경 | 사용자 저장 상태 변경; 재적용 제외 |
| setting.module.environmentTimer | environmentTimer 사용 ON/OFF / settings | BRIDGE / GO | KHQOL UI 공통 체크박스 확정 지점 — 사용자 조작 전후 저장된 활성 설정 변경 | 사용자 저장 상태 변경; 재적용 제외 |
| setting.module.experienceBar | experienceBar 사용 ON/OFF / settings | BRIDGE / GO | KHQOL UI 공통 체크박스 확정 지점 — 사용자 조작 전후 저장된 활성 설정 변경 | 사용자 저장 상태 변경; 재적용 제외 |
| setting.module.minimap | minimap 사용 ON/OFF / settings | BRIDGE / GO | KHQOL UI 공통 체크박스 확정 지점 — 사용자 조작 전후 저장된 활성 설정 변경 | 사용자 저장 상태 변경; 재적용 제외 |
| setting.module.npcAlert | npcAlert 사용 ON/OFF / settings | BRIDGE / GO | KHQOL UI 공통 체크박스 확정 지점 — 사용자 조작 전후 저장된 활성 설정 변경 | 사용자 저장 상태 변경; 재적용 제외 |
| setting.module.objectHighlight | objectHighlight 사용 ON/OFF / settings | BRIDGE / GO | KHQOL UI 공통 체크박스 확정 지점 — 사용자 조작 전후 저장된 활성 설정 변경 | 사용자 저장 상태 변경; 재적용 제외 |
| setting.module.partyFrames | partyFrames 사용 ON/OFF / settings | BRIDGE / GO | KHQOL UI 공통 체크박스 확정 지점 — 사용자 조작 전후 저장된 활성 설정 변경 | 사용자 저장 상태 변경; 재적용 제외 |
| setting.module.procAlert | procAlert 사용 ON/OFF / settings | BRIDGE / GO | KHQOL UI 공통 체크박스 확정 지점 — 사용자 조작 전후 저장된 활성 설정 변경 | 사용자 저장 상태 변경; 재적용 제외 |
| setting.module.pvpAlert | pvpAlert 사용 ON/OFF / settings | BRIDGE / GO | KHQOL UI 공통 체크박스 확정 지점 — 사용자 조작 전후 저장된 활성 설정 변경 | 사용자 저장 상태 변경; 재적용 제외 |
| setting.module.questNavigator | questNavigator 사용 ON/OFF / settings | BRIDGE / GO | KHQOL UI 공통 체크박스 확정 지점 — 사용자 조작 전후 저장된 활성 설정 변경 | 사용자 저장 상태 변경; 재적용 제외 |
| setting.module.range | range 사용 ON/OFF / settings | BRIDGE / GO | KHQOL UI 공통 체크박스 확정 지점 — 사용자 조작 전후 저장된 활성 설정 변경 | 사용자 저장 상태 변경; 재적용 제외 |
| setting.module.resourceSwing | resourceSwing 사용 ON/OFF / settings | BRIDGE / GO | KHQOL UI 공통 체크박스 확정 지점 — 사용자 조작 전후 저장된 활성 설정 변경 | 사용자 저장 상태 변경; 재적용 제외 |
| setting.module.threat | threat 사용 ON/OFF / settings | BRIDGE / GO | KHQOL UI 공통 체크박스 확정 지점 — 사용자 조작 전후 저장된 활성 설정 변경 | 사용자 저장 상태 변경; 재적용 제외 |
| setting.module.todo | todo 사용 ON/OFF / settings | BRIDGE / GO | KHQOL UI 공통 체크박스 확정 지점 — 사용자 조작 전후 저장된 활성 설정 변경 | 사용자 저장 상태 변경; 재적용 제외 |
| setting.module.tooltip | tooltip 사용 ON/OFF / settings | BRIDGE / GO | KHQOL UI 공통 체크박스 확정 지점 — 사용자 조작 전후 저장된 활성 설정 변경 | 사용자 저장 상태 변경; 재적용 제외 |
| setting.module.unitFrames | unitFrames 사용 ON/OFF / settings | BRIDGE / GO | KHQOL UI 공통 체크박스 확정 지점 — 사용자 조작 전후 저장된 활성 설정 변경 | 사용자 저장 상태 변경; 재적용 제외 |
| setting.npcAlert.control001 | 배너 크기 / settings | BRIDGE / GO | KHQOL_NPCAlert/UI/NPCAlertSettings.lua:90 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.npcAlert.control002 | 배너 투명도 / settings | BRIDGE / GO | KHQOL_NPCAlert/UI/NPCAlertSettings.lua:90 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.npcAlert.control003 | 배너 표시 시간 / settings | BRIDGE / GO | KHQOL_NPCAlert/UI/NPCAlertSettings.lua:90 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.npcAlert.control004 | 중앙 위험 배너 사용 / settings | BRIDGE / GO | KHQOL_NPCAlert/UI/NPCAlertSettings.lua:85 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.npcAlert.control005 | 재경고 대기시간 (초) / settings | BRIDGE / GO | KHQOL_NPCAlert/UI/NPCAlertSettings.lua:90 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.npcAlert.control006 | 위험 NPC 발견 시 사운드 / settings | BRIDGE / GO | KHQOL_NPCAlert/UI/NPCAlertSettings.lua:85 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.npcAlert.control007 | 위험 방향 표시 / settings | BRIDGE / GO | KHQOL_NPCAlert/UI/NPCAlertSettings.lua:85 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.npcAlert.control008 | 중심 거리 / settings | BRIDGE / GO | KHQOL_NPCAlert/UI/NPCAlertSettings.lua:90 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.npcAlert.control009 | 크기 / settings | BRIDGE / GO | KHQOL_NPCAlert/UI/NPCAlertSettings.lua:90 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.npcAlert.control010 | 투명도 / settings | BRIDGE / GO | KHQOL_NPCAlert/UI/NPCAlertSettings.lua:90 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.objectHighlight.control001 | 강조 X 위치 / settings | BRIDGE / GO | KHQOL_Labs/UI/LabSettings.lua:232 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.objectHighlight.control002 | 강조 Y 위치 / settings | BRIDGE / GO | KHQOL_Labs/UI/LabSettings.lua:233 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.objectHighlight.control003 | 강조 크기 / settings | BRIDGE / GO | KHQOL_Labs/UI/LabSettings.lua:231 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.objectHighlight.control004 | 강조 투명도 / settings | BRIDGE / GO | KHQOL_Labs/UI/LabSettings.lua:236 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.objectHighlight.control005 | 전투 중 강조 표시 / settings | BRIDGE / GO | KHQOL_Labs/UI/LabSettings.lua:237 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.objectHighlight.control006 | 광맥 강조 / settings | BRIDGE / GO | KHQOL_Labs/UI/LabSettings.lua:226 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.objectHighlight.control007 | 광맥 색상 / settings | BRIDGE / GO | KHQOL_Labs/UI/LabSettings.lua:228 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.objectHighlight.control008 | 광맥 효과 / settings | BRIDGE / GO | KHQOL_Labs/UI/LabSettings.lua:227 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.objectHighlight.control009 | 보물상자 강조 / settings | BRIDGE / GO | KHQOL_Labs/UI/LabSettings.lua:226 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.objectHighlight.control010 | 보물상자 색상 / settings | BRIDGE / GO | KHQOL_Labs/UI/LabSettings.lua:228 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.objectHighlight.control011 | 보물상자 효과 / settings | BRIDGE / GO | KHQOL_Labs/UI/LabSettings.lua:227 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.objectHighlight.control012 | 약초 강조 / settings | BRIDGE / GO | KHQOL_Labs/UI/LabSettings.lua:226 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.objectHighlight.control013 | 약초 색상 / settings | BRIDGE / GO | KHQOL_Labs/UI/LabSettings.lua:228 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.objectHighlight.control014 | 약초 효과 / settings | BRIDGE / GO | KHQOL_Labs/UI/LabSettings.lua:227 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.objectHighlight.control015 | 채집 오브젝트 강조 사용 / settings | BRIDGE / GO | KHQOL_Labs/UI/LabSettings.lua:219 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.objectHighlight.control016 | 퀘스트 오브젝트 반짝임 유지 / settings | BRIDGE / GO | KHQOL_Labs/UI/LabSettings.lua:215 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.auras.control011 | 독 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameAuraSettings.lua:138 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.auras.control012 | 디버프 별 체력 색상 변경 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameAuraSettings.lua:131 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.auras.control013 | 마법 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameAuraSettings.lua:138 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.auras.control014 | 저주 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameAuraSettings.lua:138 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.auras.control015 | 질병 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameAuraSettings.lua:138 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.auras.control016 | 출혈 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameAuraSettings.lua:138 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.auras.control017 | 디버프 X 좌표 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameAuraSettings.lua:126 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.auras.control018 | 디버프 Y 좌표 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameAuraSettings.lua:127 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.auras.control019 | 디버프 간격 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameAuraSettings.lua:123 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.auras.control020 | 디버프 위치 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameAuraSettings.lua:124 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.auras.control021 | 디버프 최대 개수 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameAuraSettings.lua:121 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.auras.control022 | 디버프 크기 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameAuraSettings.lua:122 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.auras.control023 | 디버프 한 줄 개수 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameAuraSettings.lua:120 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.auras.control024 | 파티원 디버프 표시 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameAuraSettings.lua:117 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.auras.control025 | 등록된 제외 주문 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/Modules/PartyFrameDebuffFilter.lua:64 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.auras.control026 | 제외할 주문 ID / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/Modules/PartyFrameDebuffFilter.lua:71 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.auras.control027 | 예시 보호막 비율 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameAuraSettings.lua:164 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.auras.control028 | 보호막 오버레이 표시 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameAuraSettings.lua:155 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.auras.control029 | 보호막 텍스처 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameAuraSettings.lua:158 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.auras.control030 | 흡수 무늬 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameAuraSettings.lua:159 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.common.control001 | 글자 크기 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:119 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.common.control002 | 솔로에서도 표시 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:118 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.common.control003 | 닉네임 위치 X / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:140 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.common.control004 | 닉네임 위치 Y / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:141 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.common.control005 | 닉네임 위치 기준점 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:138 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.common.control006 | 대상 징표 X / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:140 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.common.control007 | 대상 징표 Y / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:141 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.common.control008 | 대상 징표 기준점 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:138 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.common.control009 | 대상 징표 크기 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:139 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.common.control010 | 역할 마크 표시 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:147 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.common.control031 | 역할 마크 X / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:140 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.common.control032 | 역할 마크 Y / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:141 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.common.control033 | 역할 마크 기준점 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:138 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.common.control034 | 역할 마크 크기 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:139 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.common.control036 | 대상 징표 표시 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:145 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.common.control037 | 체력 텍스트 위치 X / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:140 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.common.control038 | 체력 텍스트 위치 Y / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:141 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.common.control039 | 체력 텍스트 위치 기준점 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:138 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.common.control040 | 낮은 체력일수록 빨간색으로 표시 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:130 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.common.control041 | 색상 스타일 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:124 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.common.control042 | 자원 바 높이 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:133 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.common.control043 | 자원 바 표시 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:132 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.common.control044 | 직업 색상 적용 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:122 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.common.control045 | 체력 바 배경 색·투명도 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:126 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.common.control046 | 체력 수치 표시 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:129 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.frames.control047.party | 1파티 정렬 기준 / party / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:97 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.frames.control047.raid10 | 1파티 정렬 기준 / raid10 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:97 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.frames.control047.raid20 | 1파티 정렬 기준 / raid20 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:97 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.frames.control047.raid40 | 1파티 정렬 기준 / raid40 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:97 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.frames.control048.party | X 좌표 / party / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:98 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.frames.control048.raid10 | X 좌표 / raid10 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:98 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.frames.control048.raid20 | X 좌표 / raid20 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:98 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.frames.control048.raid40 | X 좌표 / raid40 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:98 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.frames.control049.party | Y 좌표 / party / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:99 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.frames.control049.raid10 | Y 좌표 / raid10 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:99 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.frames.control049.raid20 | Y 좌표 / raid20 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:99 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.frames.control049.raid40 | Y 좌표 / raid40 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:99 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.frames.control050.party | 기준점 / party / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:96 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.frames.control050.raid10 | 기준점 / raid10 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:96 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.frames.control050.raid20 | 기준점 / raid20 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:96 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.frames.control050.raid40 | 기준점 / raid40 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:96 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.frames.control051.party | 인원 사이 간격 / party / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:94 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.frames.control051.raid10 | 인원 사이 간격 / raid10 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:94 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.frames.control051.raid20 | 인원 사이 간격 / raid20 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:94 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.frames.control051.raid40 | 인원 사이 간격 / raid40 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:94 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.frames.control052.party | 파티 사이 가로 간격 / party / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:104 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.frames.control052.raid10 | 파티 사이 가로 간격 / raid10 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:104 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.frames.control052.raid20 | 파티 사이 가로 간격 / raid20 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:104 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.frames.control052.raid40 | 파티 사이 가로 간격 / raid40 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:104 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.frames.control053.party | 파티 사이 세로 간격 / party / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:105 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.frames.control053.raid10 | 파티 사이 세로 간격 / raid10 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:105 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.frames.control053.raid20 | 파티 사이 세로 간격 / raid20 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:105 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.frames.control053.raid40 | 파티 사이 세로 간격 / raid40 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:105 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.frames.control055.party | 프레임 높이 / party / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:93 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.frames.control055.raid10 | 프레임 높이 / raid10 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:93 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.frames.control055.raid20 | 프레임 높이 / raid20 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:93 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.frames.control055.raid40 | 프레임 높이 / raid40 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:93 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.frames.control056.party | 프레임 정렬 / party / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:95 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.frames.control056.raid10 | 프레임 정렬 / raid10 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:95 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.frames.control056.raid20 | 프레임 정렬 / raid20 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:95 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.frames.control056.raid40 | 프레임 정렬 / raid40 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:95 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.frames.control057.party | 프레임 폭 / party / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:92 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.frames.control057.raid10 | 프레임 폭 / raid10 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:92 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.frames.control057.raid20 | 프레임 폭 / raid20 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:92 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.frames.control057.raid40 | 프레임 폭 / raid40 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:92 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.frames.control058.party | 한 줄의 하위 그룹 수 / party / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:103 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.frames.control058.raid10 | 한 줄의 하위 그룹 수 / raid10 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:103 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.frames.control058.raid20 | 한 줄의 하위 그룹 수 / raid20 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:103 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.frames.control058.raid40 | 한 줄의 하위 그룹 수 / raid40 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:103 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.roles.control060 | 역할에 따라 탱커·딜러·힐러 프로필 자동 선택 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:57 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.roles.control061 | 프레임 안 휠 시전 사용 / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:38 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.roles.control062 | 휠 다운 주문 이름 / ID / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:41 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.partyFrames.roles.control063 | 휠 업 주문 이름 / ID / settings | BRIDGE / GO | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:41 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.procAlert.alpha | 투명도 / settings | BRIDGE / GO | KHQOL_Labs/UI/LabSettings.lua:118 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.procAlert.animation | HUD 애니메이션 / settings | BRIDGE / GO | KHQOL_Labs/UI/LabSettings.lua:118 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.procAlert.scale | 전체 배율 / settings | BRIDGE / GO | KHQOL_Labs/UI/LabSettings.lua:118 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.procAlert.size | 곡선 높이 / settings | BRIDGE / GO | KHQOL_Labs/UI/LabSettings.lua:118 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.procAlert.spacing | 좌우 간격 / settings | BRIDGE / GO | KHQOL_Labs/UI/LabSettings.lua:118 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.procAlert.unlocked | 위치 잠금 / settings | BRIDGE / GO | KHQOL_Labs/UI/LabSettings.lua:118 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.procAlert.x | X 위치 / settings | BRIDGE / GO | KHQOL_Labs/UI/LabSettings.lua:118 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.procAlert.y | Y 위치 / settings | BRIDGE / GO | KHQOL_Labs/UI/LabSettings.lua:118 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.professions.control001 | 전문기술 순서 1 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ProfessionSettings.lua:54 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.professions.control002 | 전문기술 순서 2 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ProfessionSettings.lua:54 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.professions.control003 | 전문기술 순서 3 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ProfessionSettings.lua:54 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.professions.control004 | 전문기술 순서 4 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ProfessionSettings.lua:54 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.professions.control005 | 전문기술 순서 5 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ProfessionSettings.lua:54 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.professions.control006 | 글자 색상 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ProfessionSettings.lua:23 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.professions.control007 | 버튼 글자 크기 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ProfessionSettings.lua:8 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.professions.control008 | 위치 잠금 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ProfessionSettings.lua:8 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.professions.control009 | 전문기술 버튼 표시 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ProfessionSettings.lua:8 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.professions.control010 | 텍스트 효과 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ProfessionSettings.lua:28 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.professions.control011 | 목록 배경 불투명도 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ProfessionSettings.lua:37 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.professions.control012 | 목록에 보조 전문기술 표시 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ProfessionSettings.lua:8 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.professions.control013 | 배치 방향 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ProfessionSettings.lua:8 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.professions.control014 | 부캐 전문기술 표시 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ProfessionSettings.lua:8 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.professions.control015 | 숙련도 글자 크기 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ProfessionSettings.lua:8 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.professions.control016 | 숙련도 위치 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ProfessionSettings.lua:8 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.professions.control017 | 숙련도 표시 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ProfessionSettings.lua:8 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.professions.control018 | 아이콘 크기 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ProfessionSettings.lua:8 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.professions.control019 | 전문기술 사이 간격 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ProfessionSettings.lua:8 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.professions.control020 | 펼침 방향 / settings | BRIDGE / GO | KHQOL_Convenience/UI/ProfessionSettings.lua:8 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.pvpAlert.control001 | 디버그 모드 / settings | BRIDGE / GO | KHQOL_PvPAlert/Modules/PvPAlert/Settings.lua:11 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.pvpAlert.control002 | 비전투 중에만 동작 / settings | BRIDGE / GO | KHQOL_PvPAlert/Modules/PvPAlert/Settings.lua:11 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.pvpAlert.control003 | 남은 시간 표시 / settings | BRIDGE / GO | KHQOL_PvPAlert/Modules/PvPAlert/Settings.lua:11 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.pvpAlert.control004 | 시전 경고 소리 / settings | BRIDGE / GO | KHQOL_PvPAlert/Modules/PvPAlert/Settings.lua:11 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.pvpAlert.control005 | 시전 경고 표시 / settings | BRIDGE / GO | KHQOL_PvPAlert/Modules/PvPAlert/Settings.lua:11 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.pvpAlert.control006 | 시전 바 표시 / settings | BRIDGE / GO | KHQOL_PvPAlert/Modules/PvPAlert/Settings.lua:11 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.pvpAlert.control007 | 주문 아이콘 표시 / settings | BRIDGE / GO | KHQOL_PvPAlert/Modules/PvPAlert/Settings.lua:11 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.pvpAlert.control008 | X 위치 / settings | BRIDGE / GO | KHQOL_PvPAlert/Modules/PvPAlert/Settings.lua:14 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.pvpAlert.control009 | Y 위치 / settings | BRIDGE / GO | KHQOL_PvPAlert/Modules/PvPAlert/Settings.lua:14 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.pvpAlert.control010 | 위치 잠금 / settings | BRIDGE / GO | KHQOL_PvPAlert/Modules/PvPAlert/Settings.lua:34 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.pvpAlert.control011 | 전체 크기 / settings | BRIDGE / GO | KHQOL_PvPAlert/Modules/PvPAlert/Settings.lua:30 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.pvpAlert.control012 | 투명도 / settings | BRIDGE / GO | KHQOL_PvPAlert/Modules/PvPAlert/Settings.lua:31 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.pvpAlert.control013 | Pulse 효과 / settings | BRIDGE / GO | KHQOL_PvPAlert/Modules/PvPAlert/Settings.lua:11 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.pvpAlert.control014 | 접근 경고 소리 / settings | BRIDGE / GO | KHQOL_PvPAlert/Modules/PvPAlert/Settings.lua:11 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.pvpAlert.control015 | 접근 경고 표시 / settings | BRIDGE / GO | KHQOL_PvPAlert/Modules/PvPAlert/Settings.lua:11 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.pvpAlert.control016 | 접근 판정 / settings | BRIDGE / GO | KHQOL_PvPAlert/Modules/PvPAlert/Settings.lua:14 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.pvpAlert.control017 | 주시 경고 소리 / settings | BRIDGE / GO | KHQOL_PvPAlert/Modules/PvPAlert/Settings.lua:11 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.pvpAlert.control018 | 주시 경고 표시 / settings | BRIDGE / GO | KHQOL_PvPAlert/Modules/PvPAlert/Settings.lua:11 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.pvpAlert.control019 | 타겟 확정 시간 / settings | BRIDGE / GO | KHQOL_PvPAlert/Modules/PvPAlert/Settings.lua:14 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.questNavigator.navigation.control001 | 거리 갱신 주기 / settings | BRIDGE / GO | KHQOL_QuestNavigator/QuestNavigator/Settings.lua:71 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.questNavigator.navigation.control002 | 화살표 갱신 주기 / settings | BRIDGE / GO | KHQOL_QuestNavigator/QuestNavigator/Settings.lua:70 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.questNavigator.navigation.control003 | 위치 잠금 / settings | BRIDGE / GO | KHQOL_QuestNavigator/QuestNavigator/Settings.lua:8 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.questNavigator.navigation.control004 | 방향 화살표 표시 / settings | BRIDGE / GO | KHQOL_QuestNavigator/QuestNavigator/Settings.lua:8 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.questNavigator.navigation.control005 | 부드러운 회전 / settings | BRIDGE / GO | KHQOL_QuestNavigator/QuestNavigator/Settings.lua:8 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.questNavigator.navigation.control006 | 화살표 눕힘 각도 / settings | BRIDGE / GO | KHQOL_QuestNavigator/QuestNavigator/Settings.lua:53 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.questNavigator.navigation.control007 | 화살표 크기 / settings | BRIDGE / GO | KHQOL_QuestNavigator/QuestNavigator/Settings.lua:52 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.questNavigator.navigation.control008 | 화살표 투명도 / settings | BRIDGE / GO | KHQOL_QuestNavigator/QuestNavigator/Settings.lua:54 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.questNavigator.navigation.control009 | 같은 지역 퀘스트 우선 / settings | BRIDGE / GO | KHQOL_QuestNavigator/QuestNavigator/Settings.lua:8 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.questNavigator.navigation.control010 | 자동 퀘스트 선택 / settings | BRIDGE / GO | KHQOL_QuestNavigator/QuestNavigator/Settings.lua:8 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.questNavigator.navigation.control011 | 퀘스트 완료 후 / settings | BRIDGE / GO | KHQOL_QuestNavigator/QuestNavigator/Settings.lua:40 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.questNavigator.navigation.control020 | 거리 단위 / settings | BRIDGE / GO | KHQOL_QuestNavigator/QuestNavigator/Settings.lua:57 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.questNavigator.navigation.control021 | 거리 표시 / settings | BRIDGE / GO | KHQOL_QuestNavigator/QuestNavigator/Settings.lua:8 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.questNavigator.navigation.control022 | 점선 표시 / settings | BRIDGE / GO | KHQOL_QuestNavigator/QuestNavigator/Settings.lua:64 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.questNavigator.navigation.control023 | 진행도 글자 크기 / settings | BRIDGE / GO | KHQOL_QuestNavigator/QuestNavigator/Settings.lua:60 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.questNavigator.navigation.control024 | 진행도 표시 / settings | BRIDGE / GO | KHQOL_QuestNavigator/QuestNavigator/Settings.lua:8 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.questNavigator.navigation.control025 | 진행도 표시 방식 / settings | BRIDGE / GO | KHQOL_QuestNavigator/QuestNavigator/Settings.lua:61 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.questNavigator.navigation.control026 | 퀘스트 이름 글자 크기 / settings | BRIDGE / GO | KHQOL_QuestNavigator/QuestNavigator/Settings.lua:59 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.questNavigator.navigation.control027 | 퀘스트 이름 표시 / settings | BRIDGE / GO | KHQOL_QuestNavigator/QuestNavigator/Settings.lua:8 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.questNavigator.tracker.control012 | [D] 던전 표시 / settings | BRIDGE / GO | KHQOL_QuestNavigator/QuestNavigator/Settings.lua:14 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.questNavigator.tracker.control013 | [★] 정예 표시 / settings | BRIDGE / GO | KHQOL_QuestNavigator/QuestNavigator/Settings.lua:14 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.questNavigator.tracker.control014 | 자동 전환 대기 시간 / settings | BRIDGE / GO | KHQOL_QuestNavigator/QuestNavigator/Settings.lua:26 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.questNavigator.tracker.control015 | 지역 이동 시 현재 지역만 자동 펼치기 / settings | BRIDGE / GO | KHQOL_QuestNavigator/QuestNavigator/Settings.lua:14 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.questNavigator.tracker.control016 | 지역 접기 / 펼치기 사용 / settings | BRIDGE / GO | KHQOL_QuestNavigator/QuestNavigator/Settings.lua:14 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.questNavigator.tracker.control017 | 지역별 그룹화 / settings | BRIDGE / GO | KHQOL_QuestNavigator/QuestNavigator/Settings.lua:14 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.questNavigator.tracker.control018 | 퀘스트 글씨 크기 / settings | BRIDGE / GO | KHQOL_QuestNavigator/QuestNavigator/Settings.lua:30 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.questNavigator.tracker.control019 | 퀘스트 내용 표시 폭 / settings | BRIDGE / GO | KHQOL_QuestNavigator/QuestNavigator/Settings.lua:31 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.range.control001 | 거리 X 위치 / settings | BRIDGE / GO | KHQOL_Range/Range/Distance.lua:289 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.range.control002 | 거리 Y 위치 / settings | BRIDGE / GO | KHQOL_Range/Range/Distance.lua:289 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.range.control003 | 거리 구간 간격 / settings | BRIDGE / GO | KHQOL_Range/Range/Distance.lua:289 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.range.control004 | 거리 글자 크기 / settings | BRIDGE / GO | KHQOL_Range/Range/Distance.lua:289 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.range.control005 | 거리 단위 / settings | BRIDGE / GO | KHQOL_Range/Range/Distance.lua:294 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.range.control006 | 거리 위치 잠금 / settings | BRIDGE / GO | KHQOL_Range/Range/Distance.lua:289 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.range.control007 | 거리 형식 / settings | BRIDGE / GO | KHQOL_Range/Range/Distance.lua:289 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.range.control008 | 최대 표시 거리 (50~100m) / settings | BRIDGE / GO | KHQOL_Range/Range/Distance.lua:289 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.range.control009 | 최대 표시 거리 (55~109yd) / settings | BRIDGE / GO | KHQOL_Range/Range/Distance.lua:304 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.range.control010 | X 위치 보정 / settings | BRIDGE / GO | KHQOL_Range/Range/Settings.lua:61 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.range.control011 | Y 위치 보정 / settings | BRIDGE / GO | KHQOL_Range/Range/Settings.lua:62 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.range.control012 | 공격가능 문구 / settings | BRIDGE / GO | KHQOL_Range/Range/Settings.lua:67 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.range.control013 | 공격불가 문구 / settings | BRIDGE / GO | KHQOL_Range/Range/Settings.lua:67 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.range.control014 | 글자 크기 / settings | BRIDGE / GO | KHQOL_Range/Range/Settings.lua:73 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.range.control015 | 마우스오버 거리 측정 사용 / settings | BRIDGE / GO | KHQOL_Range/Range/Settings.lua:51 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.range.control016 | 마우스오버 표시 방식 / settings | BRIDGE / GO | KHQOL_Range/Range/Settings.lua:53 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.range.control017 | 표시 위치 / settings | BRIDGE / GO | KHQOL_Range/Range/Settings.lua:57 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.range.control018 | 데드존 / settings | BRIDGE / GO | KHQOL_Range/Range/Settings.lua:106 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.range.control019 | 사거리 밖 / settings | BRIDGE / GO | KHQOL_Range/Range/Settings.lua:106 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.range.control020 | 사거리 안 / settings | BRIDGE / GO | KHQOL_Range/Range/Settings.lua:106 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.range.control021 | 외곽선 두께 / settings | BRIDGE / GO | KHQOL_Range/Range/Settings.lua:99 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.range.control022 | 외곽선 색상 / settings | BRIDGE / GO | KHQOL_Range/Range/Settings.lua:100 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.range.control023 | 외곽선 표시 / settings | BRIDGE / GO | KHQOL_Range/Range/Settings.lua:97 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.range.control024 | 근거리 공격도 가능으로 판정 / settings | BRIDGE / GO | KHQOL_Range/Range/Settings.lua:44 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.range.control025 | 데드존 감지 사용 / settings | BRIDGE / GO | KHQOL_Range/Range/Settings.lua:45 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.range.control026 | X 위치 / settings | BRIDGE / GO | KHQOL_Range/Range/Settings.lua:78 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.range.control027 | Y 위치 / settings | BRIDGE / GO | KHQOL_Range/Range/Settings.lua:79 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.range.control028 | 위치 잠금 / settings | BRIDGE / GO | KHQOL_Range/Range/Settings.lua:77 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.range.control029 | 사용 가능 / settings | BRIDGE / GO | KHQOL_Range/Range/Settings.lua:87 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.range.control030 | 사용 불가 / settings | BRIDGE / GO | KHQOL_Range/Range/Settings.lua:87 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.range.control031 | 스킬 사거리 별 문구 / settings | BRIDGE / GO | KHQOL_Range/Range/Settings.lua:81 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.range.control032 | 크기 / settings | BRIDGE / GO | KHQOL_Range/Range/Settings.lua:95 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.range.control033 | 특수 문자 / settings | BRIDGE / GO | KHQOL_Range/Range/Settings.lua:92 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.range.control034 | 표시 방식 / settings | BRIDGE / GO | KHQOL_Range/Range/Settings.lua:16 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.resourceSwing.control001 | 스윙 바 내부 레이어 / settings | BRIDGE / GO | KHQOL_ResourceSwing/ResourceSwing/KHQOLResourceSwing.lua:457 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.resourceSwing.control002 | 자원 바 내부 레이어 / settings | BRIDGE / GO | KHQOL_ResourceSwing/ResourceSwing/KHQOLResourceSwing.lua:457 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.resourceSwing.control003 | 전체 표시 레이어 / settings | BRIDGE / GO | KHQOL_ResourceSwing/ResourceSwing/KHQOLResourceSwing.lua:462 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.resourceSwing.control004 | 변신 중 마나바 표시 / settings | BRIDGE / GO | KHQOL_ResourceSwing/ResourceSwing/KHQOLResourceSwing.lua:447 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.resourceSwing.control005 | 바 텍스처 / settings | BRIDGE / GO | KHQOL_ResourceSwing/ResourceSwing/KHQOLResourceSwing.lua:462 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.resourceSwing.control006 | 배경 색상 / settings | BRIDGE / GO | KHQOL_ResourceSwing/ResourceSwing/KHQOLResourceSwing.lua:465 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.resourceSwing.control007 | 보조무기 색상 / settings | BRIDGE / GO | KHQOL_ResourceSwing/ResourceSwing/KHQOLResourceSwing.lua:465 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.resourceSwing.control008 | 원거리 색상 / settings | BRIDGE / GO | KHQOL_ResourceSwing/ResourceSwing/KHQOLResourceSwing.lua:465 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.resourceSwing.control009 | 자원 색상 / settings | BRIDGE / GO | KHQOL_ResourceSwing/ResourceSwing/KHQOLResourceSwing.lua:465 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.resourceSwing.control010 | 주무기 색상 / settings | BRIDGE / GO | KHQOL_ResourceSwing/ResourceSwing/KHQOLResourceSwing.lua:465 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.resourceSwing.control011 | 스윙 바 위치 / settings | BRIDGE / GO | KHQOL_ResourceSwing/ResourceSwing/KHQOLResourceSwing.lua:462 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.resourceSwing.control012 | 스윙 바 표시 / settings | BRIDGE / GO | KHQOL_ResourceSwing/ResourceSwing/KHQOLResourceSwing.lua:462 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.resourceSwing.control013 | 스윙 텍스트 표시 / settings | BRIDGE / GO | KHQOL_ResourceSwing/ResourceSwing/KHQOLResourceSwing.lua:447 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.resourceSwing.control014 | X 위치 / settings | BRIDGE / GO | KHQOL_ResourceSwing/ResourceSwing/KHQOLResourceSwing.lua:457 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.resourceSwing.control015 | Y 위치 / settings | BRIDGE / GO | KHQOL_ResourceSwing/ResourceSwing/KHQOLResourceSwing.lua:457 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.resourceSwing.control016 | 위치 잠금 / settings | BRIDGE / GO | KHQOL_ResourceSwing/ResourceSwing/KHQOLResourceSwing.lua:447 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.resourceSwing.control017 | 글자 크기 / settings | BRIDGE / GO | KHQOL_ResourceSwing/ResourceSwing/KHQOLResourceSwing.lua:457 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.resourceSwing.control018 | 수치 표시 방법 / settings | BRIDGE / GO | KHQOL_ResourceSwing/ResourceSwing/KHQOLResourceSwing.lua:462 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.resourceSwing.control019 | 자원 수치 표시 / settings | BRIDGE / GO | KHQOL_ResourceSwing/ResourceSwing/KHQOLResourceSwing.lua:447 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.resourceSwing.control020 | 표시 위치 / settings | BRIDGE / GO | KHQOL_ResourceSwing/ResourceSwing/KHQOLResourceSwing.lua:462 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.resourceSwing.control021 | 구슬 크기 / settings | BRIDGE / GO | KHQOL_ResourceSwing/ResourceSwing/KHQOLResourceSwing.lua:457 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.resourceSwing.control022 | 마지막 포인트 활성 색상 / settings | BRIDGE / GO | KHQOL_ResourceSwing/ResourceSwing/KHQOLResourceSwing.lua:500 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.resourceSwing.control023 | 배치 / settings | BRIDGE / GO | KHQOL_ResourceSwing/ResourceSwing/KHQOLResourceSwing.lua:462 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.resourceSwing.control024 | 분할 바 높이 / settings | BRIDGE / GO | KHQOL_ResourceSwing/ResourceSwing/KHQOLResourceSwing.lua:457 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.resourceSwing.control025 | 분할 바 폭 / settings | BRIDGE / GO | KHQOL_ResourceSwing/ResourceSwing/KHQOLResourceSwing.lua:457 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.resourceSwing.control026 | 비활성 색상 / settings | BRIDGE / GO | KHQOL_ResourceSwing/ResourceSwing/KHQOLResourceSwing.lua:500 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.resourceSwing.control027 | 콤보 X 위치 / settings | BRIDGE / GO | KHQOL_ResourceSwing/ResourceSwing/KHQOLResourceSwing.lua:457 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.resourceSwing.control028 | 콤보 Y 위치 / settings | BRIDGE / GO | KHQOL_ResourceSwing/ResourceSwing/KHQOLResourceSwing.lua:457 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.resourceSwing.control029 | 콤보 자유 배치 잠금 / settings | BRIDGE / GO | KHQOL_ResourceSwing/ResourceSwing/KHQOLResourceSwing.lua:447 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.resourceSwing.control030 | 포인트 간격 / settings | BRIDGE / GO | KHQOL_ResourceSwing/ResourceSwing/KHQOLResourceSwing.lua:457 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.resourceSwing.control031 | 표시 형태 / settings | BRIDGE / GO | KHQOL_ResourceSwing/ResourceSwing/KHQOLResourceSwing.lua:462 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.resourceSwing.control032 | 활성 색상 / settings | BRIDGE / GO | KHQOL_ResourceSwing/ResourceSwing/KHQOLResourceSwing.lua:500 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.resourceSwing.control033 | 높이 / settings | BRIDGE / GO | KHQOL_ResourceSwing/ResourceSwing/KHQOLResourceSwing.lua:457 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.resourceSwing.control034 | 스윙 바 높이 / settings | BRIDGE / GO | KHQOL_ResourceSwing/ResourceSwing/KHQOLResourceSwing.lua:457 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.resourceSwing.control035 | 폭 / settings | BRIDGE / GO | KHQOL_ResourceSwing/ResourceSwing/KHQOLResourceSwing.lua:457 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.resourceSwing.control036 | 콤보 포인트 표시 / settings | BRIDGE / GO | KHQOL_ResourceSwing/ResourceSwing/KHQOLResourceSwing.lua:447 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.text.confirmed | 문자 입력 확정 / settings | HOLD / HOLD | BindInput / 사용자 문자열 컨트롤 — 문자 입력의 유효한 확정 변경 | 호환용 미사용 합계 ID. 개별 고정 설정 ID에서 수집 |
| setting.threat.control001 | 사냥꾼 / 흑마법사 + 소환수 보유 시 활성 / settings | BRIDGE / GO | KHQOL_Threat/Modules/Threat.lua:570 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.threat.control002 | 글씨 크기 / settings | BRIDGE / GO | KHQOL_Threat/Modules/Threat.lua:525 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.threat.control003 | 대상명 표시 / settings | BRIDGE / GO | KHQOL_Threat/Modules/Threat.lua:527 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.threat.control004 | 어그로 위험도 색상 / settings | BRIDGE / GO | KHQOL_Threat/Modules/Threat.lua:526 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.threat.control005 | 표시 방식 / settings | BRIDGE / GO | KHQOL_Threat/Modules/Threat.lua:524 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.threat.control006 | 하단 어그로 안내 표시 / settings | BRIDGE / GO | KHQOL_Threat/Modules/Threat.lua:528 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.threat.control007 | X 위치 (Enter로 저장) / settings | BRIDGE / GO | KHQOL_Threat/Modules/Threat.lua:555 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.threat.control008 | Y 위치 (Enter로 저장) / settings | BRIDGE / GO | KHQOL_Threat/Modules/Threat.lua:556 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.threat.control009 | 위치 잠금 / settings | BRIDGE / GO | KHQOL_Threat/Modules/Threat.lua:546 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.threat.control010 | 아이콘 위치 / settings | BRIDGE / GO | KHQOL_Threat/Modules/Threat.lua:563 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.threat.control011 | 아이콘 크기 / settings | BRIDGE / GO | KHQOL_Threat/Modules/Threat.lua:562 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.threat.control012 | 어그로 95% 경고 음성 / settings | BRIDGE / GO | KHQOL_Threat/Modules/Threat.lua:565 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.threat.control013 | 위협 아이콘 표시 / settings | BRIDGE / GO | KHQOL_Threat/Modules/Threat.lua:560 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.threat.control014 | 주의 단계에서도 아이콘 표시 / settings | BRIDGE / GO | KHQOL_Threat/Modules/Threat.lua:561 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.threat.control015 | 딜 / settings | BRIDGE / GO | KHQOL_Threat/Modules/Threat.lua:535 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.threat.control016 | 역할 판정 / settings | BRIDGE / GO | KHQOL_Threat/Modules/Threat.lua:542 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.threat.control017 | 탱 / settings | BRIDGE / GO | KHQOL_Threat/Modules/Threat.lua:535 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.threat.control018 | 힐 / settings | BRIDGE / GO | KHQOL_Threat/Modules/Threat.lua:535 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.todo.control001 | 경로 이탈 거리 / settings | BRIDGE / GO | KHQOL_Clock/UI/NoteSettings.lua:118 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.todo.control002 | 경로 이탈 알림 / settings | BRIDGE / GO | KHQOL_Clock/UI/NoteSettings.lua:116 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.todo.control003 | 경유지 도착 반경 / settings | BRIDGE / GO | KHQOL_Clock/UI/NoteSettings.lua:114 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.todo.control004 | 도착한 핀 숨기기 / settings | BRIDGE / GO | KHQOL_Clock/UI/NoteSettings.lua:47 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.todo.control005 | 미니맵에 노트 좌표 핀 표시 / settings | BRIDGE / GO | KHQOL_Clock/UI/NoteSettings.lua:41 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.todo.control006 | 세계지도에 노트 좌표 핀 표시 / settings | BRIDGE / GO | KHQOL_Clock/UI/NoteSettings.lua:38 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.todo.control007 | 연결선 두께 / settings | BRIDGE / GO | KHQOL_Clock/UI/NoteSettings.lua:59 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.todo.control008 | 연결선 색상·투명도 / settings | BRIDGE / GO | KHQOL_Clock/UI/NoteSettings.lua:56 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.todo.control009 | 지도 Shift+우클릭으로 좌표 추가 / settings | BRIDGE / GO | KHQOL_Clock/UI/NoteSettings.lua:44 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.todo.control010 | 핀 연결선 표시 / settings | BRIDGE / GO | KHQOL_Clock/UI/NoteSettings.lua:52 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.todo.control011 | ESC로 노트 닫기 / settings | BRIDGE / GO | KHQOL_Clock/UI/NoteSettings.lua:18 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.todo.control012 | 노트 미니맵 버튼 표시 / settings | BRIDGE / GO | KHQOL_Clock/UI/NoteSettings.lua:16 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.todo.control013 | 위치 잠금 / settings | BRIDGE / GO | KHQOL_Clock/UI/NoteSettings.lua:9 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.todo.control014 | 경로 이름 / settings | BRIDGE / GO | KHQOL_Clock/UI/NoteSettings.lua:76 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.todo.control015 | 선택 경로 안내 사용 / settings | BRIDGE / GO | KHQOL_Clock/UI/NoteSettings.lua:91 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.todo.control016 | 선택 경로 표시 / settings | BRIDGE / GO | KHQOL_Clock/UI/NoteSettings.lua:88 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.todo.control020 | 글자 크기 / settings | BRIDGE / GO | KHQOL_Clock/UI/NoteSettings.lua:13 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.todo.control021 | 배경 불투명도 / settings | BRIDGE / GO | KHQOL_Clock/UI/NoteSettings.lua:14 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.todo.control022 | 네비게이션 연결 / settings | BRIDGE / GO | KHQOL_Clock/UI/NoteSettings.lua:25 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.todo.control023 | 완료 시 다음 위치 자동 안내 / settings | BRIDGE / GO | KHQOL_Clock/UI/NoteSettings.lua:29 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.todo.control024 | 좌표 항목에 ▶ 버튼 표시 / settings | BRIDGE / GO | KHQOL_Clock/UI/NoteSettings.lua:32 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.tooltip.control001 | NPC ID / settings | BRIDGE / GO | KHQOL_Tooltip/Tooltip/Settings.lua:20 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.tooltip.control002 | 아이템 ID / settings | BRIDGE / GO | KHQOL_Tooltip/Tooltip/Settings.lua:20 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.tooltip.control003 | 주문 ID / settings | BRIDGE / GO | KHQOL_Tooltip/Tooltip/Settings.lua:20 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.tooltip.control004 | 체력바 표시 / settings | BRIDGE / GO | KHQOL_Tooltip/Tooltip/Settings.lua:35 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.tooltip.control005 | 텍스트 크기 / settings | BRIDGE / GO | KHQOL_Tooltip/Tooltip/Settings.lua:34 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.tooltip.control006 | 표시 유지 시간 / settings | BRIDGE / GO | KHQOL_Tooltip/Tooltip/Settings.lua:32 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.tooltip.control007 | X 위치 / settings | BRIDGE / GO | KHQOL_Tooltip/Tooltip/Settings.lua:27 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.tooltip.control008 | Y 위치 / settings | BRIDGE / GO | KHQOL_Tooltip/Tooltip/Settings.lua:28 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.tooltip.control009 | 무기 전문가 정보 / settings | BRIDGE / GO | KHQOL_Tooltip/Tooltip/Settings.lua:15 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.tooltip.control010 | 전투 중 대상 툴팁 숨기기 / settings | BRIDGE / GO | KHQOL_Tooltip/Tooltip/Settings.lua:14 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.tooltip.control011 | 플레이어 전문화 정보 표시 / settings | BRIDGE / GO | KHQOL_Tooltip/Tooltip/Settings.lua:8 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.tooltip.control012 | 마우스 오른쪽에 표시 / settings | BRIDGE / GO | KHQOL_Tooltip/Tooltip/Settings.lua:6 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.bars.control061 | 색상 스타일 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:135 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.bars.control062 | 직업 색상 적용 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:133 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.focus.bars.control075 | 자원 수치 표시 방식 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:285 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.focus.bars.control076 | 체력 수치 표시 방식 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:284 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.focus.bars.control077 | 체력·자원 수치 글자 크기 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:286 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.focus.bars.control090 | 바 사이 간격 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:182 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.focus.bars.control091 | 사각 테두리 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:194 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.focus.bars.control092 | 사용자 지정색 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:192 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.focus.bars.control093 | 자원 바 높이 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:181 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.focus.bars.control094 | 자원 바 표시 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:180 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.focus.bars.control095 | 전체 높이 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:178 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.focus.bars.control096 | 체력 바 높이 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:179 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.focus.bars.control097 | 체력 바 배경 불투명도 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:193 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.focus.bars.control098 | 체력 바 색상 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:189 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.focus.bars.control099 | 프레임 폭 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:177 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.focus.basic.control140 | 간결한 프레임 사용 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:159 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.focus.labels.control157 | 레벨 X 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:275 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.focus.labels.control158 | 레벨 Y 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:275 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.focus.labels.control159 | 레벨 구석 정렬 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:259 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.focus.labels.control160 | 레벨 글자 크기 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:263 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.focus.labels.control161 | 레벨 위치 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:258 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.focus.labels.control186 | 이름 X 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:275 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.focus.labels.control187 | 이름 Y 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:275 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.focus.labels.control188 | 이름 구석 정렬 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:259 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.focus.labels.control189 | 이름 글자 크기 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:263 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.focus.labels.control190 | 이름 위치 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:258 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.focus.status.control224 | 상태·징표 X 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:217 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.focus.status.control225 | 상태·징표 Y 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:217 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.pet.bars.control078 | 자원 수치 표시 방식 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:285 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.pet.bars.control079 | 체력 수치 표시 방식 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:284 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.pet.bars.control080 | 체력·자원 수치 글자 크기 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:286 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.pet.bars.control100 | 바 사이 간격 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:182 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.pet.bars.control101 | 사각 테두리 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:194 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.pet.bars.control102 | 사용자 지정색 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:192 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.pet.bars.control103 | 자원 바 높이 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:181 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.pet.bars.control104 | 자원 바 표시 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:180 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.pet.bars.control105 | 전체 높이 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:178 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.pet.bars.control106 | 체력 바 높이 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:179 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.pet.bars.control107 | 체력 바 배경 불투명도 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:193 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.pet.bars.control108 | 체력 바 색상 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:189 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.pet.bars.control109 | 프레임 폭 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:177 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.pet.basic.control141 | 간결한 프레임 사용 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:159 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.pet.labels.control162 | 레벨 X 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:275 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.pet.labels.control163 | 레벨 Y 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:275 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.pet.labels.control164 | 레벨 구석 정렬 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:259 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.pet.labels.control165 | 레벨 글자 크기 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:263 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.pet.labels.control166 | 레벨 위치 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:258 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.pet.labels.control191 | 이름 X 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:275 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.pet.labels.control192 | 이름 Y 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:275 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.pet.labels.control193 | 이름 구석 정렬 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:259 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.pet.labels.control194 | 이름 글자 크기 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:263 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.pet.labels.control195 | 이름 위치 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:258 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.pet.status.control226 | 상태·징표 X 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:217 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.pet.status.control227 | 상태·징표 Y 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:217 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.pet.status.control230 | 포만감 아이콘 X 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:230 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.pet.status.control231 | 포만감 아이콘 Y 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:230 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.auras.control043 | 플레이어 디버프 X 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:317 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.auras.control044 | 플레이어 디버프 Y 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:317 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.auras.control045 | 플레이어 디버프 아이콘 크기 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:308 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.auras.control046 | 플레이어 디버프 위치 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:309 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.auras.control047 | 플레이어 디버프 위치 설정 사용 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:307 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.auras.control048 | 플레이어 디버프 최대 행 수 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:313 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.auras.control049 | 플레이어 디버프 행·확장 설정 사용 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:310 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.auras.control050 | 플레이어 디버프 행당 개수 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:312 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.auras.control051 | 플레이어 디버프 확장 방향 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:314 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.auras.control052 | 플레이어 버프 X 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:317 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.auras.control053 | 플레이어 버프 Y 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:317 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.auras.control054 | 플레이어 버프 아이콘 크기 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:308 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.auras.control055 | 플레이어 버프 위치 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:309 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.auras.control056 | 플레이어 버프 위치 설정 사용 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:307 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.auras.control057 | 플레이어 버프 최대 행 수 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:313 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.auras.control058 | 플레이어 버프 행·확장 설정 사용 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:310 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.auras.control059 | 플레이어 버프 행당 개수 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:312 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.auras.control060 | 플레이어 버프 확장 방향 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:314 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.bars.control063 | 자원 수치 X 좌표 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:294 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.bars.control064 | 자원 수치 Y 좌표 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:294 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.bars.control065 | 자원 수치 정렬 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:291 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.bars.control069 | 체력 수치 X 좌표 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:294 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.bars.control070 | 체력 수치 Y 좌표 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:294 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.bars.control071 | 체력 수치 정렬 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:291 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.bars.control081 | 자원 수치 표시 방식 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:285 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.bars.control082 | 체력 수치 표시 방식 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:284 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.bars.control083 | 체력·자원 수치 글자 크기 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:286 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.bars.control110 | 바 사이 간격 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:182 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.bars.control111 | 사각 테두리 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:194 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.bars.control112 | 사용자 지정색 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:192 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.bars.control113 | 자원 바 높이 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:181 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.bars.control114 | 자원 바 표시 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:180 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.bars.control115 | 전체 높이 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:178 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.bars.control116 | 체력 바 높이 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:179 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.bars.control117 | 체력 바 배경 불투명도 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:193 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.bars.control118 | 체력 바 색상 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:189 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.bars.control119 | 프레임 폭 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:177 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.basic.control142 | 간결한 프레임 사용 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:159 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.class.control145 | 보조 표시 X 좌표 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/PlayerAuxSettings.lua:30 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.class.control146 | 보조 표시 Y 좌표 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/PlayerAuxSettings.lua:30 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.class.control147 | 보조 표시 글자 크기 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/PlayerAuxSettings.lua:32 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.class.control148 | 보조 표시 위치 잠금 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/PlayerAuxSettings.lua:24 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.class.control149 | 영혼의 조각 문구 표시 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/PlayerAuxSettings.lua:16 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.class.control150 | 영혼의 조각 표시 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/PlayerAuxSettings.lua:14 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.class.control151 | 최대 보관 수량 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/PlayerAuxSettings.lua:17 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.class.control152 | 탄약 표시 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/PlayerAuxSettings.lua:11 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.class.control153 | 프레임 X 좌표 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:334 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.class.control154 | 프레임 Y 좌표 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:334 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.class.control155 | 프레임 위치 확인 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:338 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.class.control156 | 프레임 확장 방향 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:337 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.labels.control167 | 레벨 X 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:275 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.labels.control168 | 레벨 Y 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:275 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.labels.control169 | 레벨 구석 정렬 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:259 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.labels.control170 | 레벨 글자 크기 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:263 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.labels.control171 | 레벨 색 선택 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:271 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.labels.control172 | 레벨 색상 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:270 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.labels.control173 | 레벨 위치 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:258 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.labels.control196 | 이름 X 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:275 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.labels.control197 | 이름 Y 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:275 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.labels.control198 | 이름 구석 정렬 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:259 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.labels.control199 | 이름 글자 크기 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:263 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.labels.control200 | 이름 색 선택 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:271 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.labels.control201 | 이름 색상 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:270 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.labels.control202 | 이름 위치 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:258 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.status.control215 | 대상 징표 X 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:206 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.status.control216 | 대상 징표 Y 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:206 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.status.control232 | 전투 상태 X 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:206 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.status.control233 | 전투 상태 Y 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:206 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.status.control234 | 휴식 상태 X 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:206 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.player.status.control235 | 휴식 상태 Y 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:206 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.auras.attackableNPC.control001 | 대상 버프·디버프 설정 사용 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:364 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.auras.attackableNPC.control002 | 디버프 최대 행 수 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:375 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.auras.attackableNPC.control003 | 디버프 표시 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:366 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.auras.attackableNPC.control004 | 디버프 행당 개수 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:374 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.auras.attackableNPC.control005 | 디버프 확장 방향 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:376 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.auras.attackableNPC.control006 | 버프 최대 행 수 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:375 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.auras.attackableNPC.control007 | 버프 표시 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:365 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.auras.attackableNPC.control008 | 버프 행당 개수 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:374 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.auras.attackableNPC.control009 | 버프 확장 방향 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:376 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.auras.attackableNPC.control010 | 버프·디버프 개별 위치 사용 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:368 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.auras.attackableNPC.control011 | 버프·디버프 공통 X 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:381 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.auras.attackableNPC.control012 | 버프·디버프 공통 Y 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:381 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.auras.attackableNPC.control013 | 버프·디버프 공통 위치 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:369 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.auras.attackableNPC.control014 | 버프·디버프 아이콘 크기 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:367 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.auras.attackableNPC.control015 | 행·확장 설정 사용 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:370 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.auras.attackableNPC.control016 | 대상 디버프 X 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:390 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.auras.attackableNPC.control017 | 대상 디버프 Y 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:390 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.auras.attackableNPC.control018 | 대상 디버프 위치 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:388 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.auras.attackableNPC.control019 | 대상 버프 X 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:390 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.auras.attackableNPC.control020 | 대상 버프 Y 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:390 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.auras.attackableNPC.control021 | 대상 버프 위치 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:388 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.auras.friendlyPlayer.control022 | 대상 디버프 X 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:390 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.auras.friendlyPlayer.control023 | 대상 디버프 Y 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:390 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.auras.friendlyPlayer.control024 | 대상 디버프 위치 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:388 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.auras.friendlyPlayer.control025 | 대상 버프 X 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:390 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.auras.friendlyPlayer.control026 | 대상 버프 Y 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:390 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.auras.friendlyPlayer.control027 | 대상 버프 위치 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:388 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.auras.friendlyPlayer.control028 | 대상 버프·디버프 설정 사용 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:364 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.auras.friendlyPlayer.control029 | 디버프 최대 행 수 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:375 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.auras.friendlyPlayer.control030 | 디버프 표시 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:366 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.auras.friendlyPlayer.control031 | 디버프 행당 개수 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:374 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.auras.friendlyPlayer.control032 | 디버프 확장 방향 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:376 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.auras.friendlyPlayer.control033 | 버프 최대 행 수 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:375 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.auras.friendlyPlayer.control034 | 버프 표시 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:365 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.auras.friendlyPlayer.control035 | 버프 행당 개수 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:374 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.auras.friendlyPlayer.control036 | 버프 확장 방향 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:376 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.auras.friendlyPlayer.control037 | 버프·디버프 개별 위치 사용 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:368 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.auras.friendlyPlayer.control038 | 버프·디버프 공통 X 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:381 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.auras.friendlyPlayer.control039 | 버프·디버프 공통 Y 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:381 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.auras.friendlyPlayer.control040 | 버프·디버프 공통 위치 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:369 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.auras.friendlyPlayer.control041 | 버프·디버프 아이콘 크기 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:367 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.auras.friendlyPlayer.control042 | 행·확장 설정 사용 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:370 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.bars.control066 | 자원 수치 X 좌표 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:294 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.bars.control067 | 자원 수치 Y 좌표 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:294 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.bars.control068 | 자원 수치 정렬 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:291 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.bars.control072 | 체력 수치 X 좌표 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:294 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.bars.control073 | 체력 수치 Y 좌표 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:294 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.bars.control074 | 체력 수치 정렬 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:291 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.bars.control084 | 자원 수치 표시 방식 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:285 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.bars.control085 | 체력 수치 표시 방식 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:284 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.bars.control086 | 체력·자원 수치 글자 크기 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:286 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.bars.control120 | 바 사이 간격 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:182 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.bars.control121 | 사각 테두리 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:194 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.bars.control122 | 사용자 지정색 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:192 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.bars.control123 | 자원 바 높이 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:181 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.bars.control124 | 자원 바 표시 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:180 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.bars.control125 | 전체 높이 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:178 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.bars.control126 | 체력 바 높이 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:179 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.bars.control127 | 체력 바 배경 불투명도 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:193 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.bars.control128 | 체력 바 색상 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:189 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.bars.control129 | 프레임 폭 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:177 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.basic.control143 | 간결한 프레임 사용 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:159 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.labels.control174 | 레벨 X 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:275 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.labels.control175 | 레벨 Y 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:275 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.labels.control176 | 레벨 구석 정렬 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:259 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.labels.control177 | 레벨 글자 크기 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:263 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.labels.control178 | 레벨 색 선택 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:271 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.labels.control179 | 레벨 색상 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:270 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.labels.control180 | 레벨 위치 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:258 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.labels.control203 | 이름 X 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:275 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.labels.control204 | 이름 Y 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:275 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.labels.control205 | 이름 구석 정렬 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:259 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.labels.control206 | 이름 글자 크기 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:263 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.labels.control207 | 이름 색 선택 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:271 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.labels.control208 | 이름 색상 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:270 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.labels.control209 | 이름 위치 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:258 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.status.control217 | 대상 징표 X 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:206 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.status.control218 | 대상 징표 Y 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:206 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.status.control219 | 몬스터 마크 X 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:246 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.status.control220 | 몬스터 마크 Y 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:246 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.status.control221 | 몬스터 마크 크기 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:243 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.status.control222 | 정예·희귀 몬스터 마크 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:242 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.status.control223 | 퀘스트 몬스터 마크 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:241 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.target.status.control236 | 기본 대상 콤보 포인트 숨김 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:347 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.targettarget.bars.control087 | 자원 수치 표시 방식 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:285 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.targettarget.bars.control088 | 체력 수치 표시 방식 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:284 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.targettarget.bars.control089 | 체력·자원 수치 글자 크기 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:286 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.targettarget.bars.control130 | 바 사이 간격 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:182 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.targettarget.bars.control131 | 사각 테두리 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:194 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.targettarget.bars.control132 | 사용자 지정색 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:192 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.targettarget.bars.control133 | 자원 바 높이 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:181 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.targettarget.bars.control134 | 자원 바 표시 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:180 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.targettarget.bars.control135 | 전체 높이 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:178 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.targettarget.bars.control136 | 체력 바 높이 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:179 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.targettarget.bars.control137 | 체력 바 배경 불투명도 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:193 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.targettarget.bars.control138 | 체력 바 색상 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:189 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.targettarget.bars.control139 | 프레임 폭 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:177 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.targettarget.basic.control144 | 간결한 프레임 사용 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:159 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.targettarget.labels.control181 | 레벨 X 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:275 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.targettarget.labels.control182 | 레벨 Y 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:275 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.targettarget.labels.control183 | 레벨 구석 정렬 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:259 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.targettarget.labels.control184 | 레벨 글자 크기 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:263 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.targettarget.labels.control185 | 레벨 위치 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:258 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.targettarget.labels.control210 | 이름 X 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:275 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.targettarget.labels.control211 | 이름 Y 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:275 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.targettarget.labels.control212 | 이름 구석 정렬 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:259 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.targettarget.labels.control213 | 이름 글자 크기 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:263 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.targettarget.labels.control214 | 이름 위치 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:258 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.targettarget.status.control228 | 상태·징표 X 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:217 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |
| setting.unitFrames.targettarget.status.control229 | 상태·징표 Y 위치 보정 / settings | BRIDGE / GO | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:217 — 공통 컨트롤의 확정된 실제 변경 | 등록 초안·화면 선택 제외; 정적 문맥 구분; 인게임 NOT TESTED |

## 공통 컨트롤 제외 행

| 모듈 / 제목 | 이유 |
|---|---|
| clock / 설정 대상 | view selector only |
| general / 미니맵 | module toggle gets its existing explicit module ID |
| general / 버튼 정리 | module toggle gets its existing explicit module ID |
| general / 경험치 | module toggle gets its existing explicit module ID |
| general / 시전 | module toggle gets its existing explicit module ID |
| general / 자원/스윙바 | module toggle gets its existing explicit module ID |
| general / 환경타이머 | module toggle gets its existing explicit module ID |
| general / NPC | module toggle gets its existing explicit module ID |
| general / PvP | module toggle gets its existing explicit module ID |
| general / 모닥불 | module toggle gets its existing explicit module ID |
| general / 위협 수치 | module toggle gets its existing explicit module ID |
| general / 전투 상태 | module toggle gets its existing explicit module ID |
| general / 유닛 프레임 | module toggle gets its existing explicit module ID |
| general / 기본 UI | module toggle gets its existing explicit module ID |
| general / 마우스 잔상 | module toggle gets its existing explicit module ID |
| general / 사거리 측정 | module toggle gets its existing explicit module ID |
| general / 시계·정보 표시 | module toggle gets its existing explicit module ID |
| general / 툴팁 설정 | module toggle gets its existing explicit module ID |
| general / 길 안내 | module toggle gets its existing explicit module ID |
| general / 퀘스트 목록 (목표 추적기) | module toggle gets its existing explicit module ID |
| general / 파티·공격대 | module toggle gets its existing explicit module ID |
| general / 기본 대화창 편의 | module toggle gets its existing explicit module ID |
| general / 아이템 파괴 자동 입력 | module toggle gets its existing explicit module ID |
| general / 오브젝트 강조 | module toggle gets its existing explicit module ID |
| general / 자동 수리 | module toggle gets its existing explicit module ID |
| general / 잡템 자동 판매 | module toggle gets its existing explicit module ID |
| general / 포에버 노트 | module toggle gets its existing explicit module ID |
| npcAlert / Map ID | staged registration draft; final Save has separate semantics |
| npcAlert / NPC ID (선택) | staged registration draft; final Save has separate semantics |
| npcAlert / NPC 이름 | staged registration draft; final Save has separate semantics |
| npcAlert / 사용 | staged registration draft; final Save has separate semantics |
| npcAlert / 사운드 | staged registration draft; final Save has separate semantics |
| npcAlert / 위험 방향 표시 | staged registration draft; final Save has separate semantics |
| npcAlert / 위험도 | staged registration draft; final Save has separate semantics |
| npcAlert / 중앙 위험 배너 | staged registration draft; final Save has separate semantics |
| partyFrames / 프레임 프로필 삭제 | profile command or layout view selector |
| partyFrames / 편집할 프레임 | profile command or layout view selector |
| partyFrames / 사용할 프레임 프로필 | profile command or layout view selector |
| profiles / 프로필 삭제 | profile command, not a regular committed setting |
| profiles / 활성 프로필 | profile command, not a regular committed setting |
| range / 근거리 판정 주문 | lookup/registration input without a common commit setter |
| range / 원거리 판정 주문 | lookup/registration input without a common commit setter |
| todo / 저장된 경로 선택 | view/draft selector only, no committed configuration change |
| todo / 추가할 핀 | view/draft selector only, no committed configuration change |
| todo / 편집할 경유지 | view/draft selector only, no committed configuration change |
| unitFrames / 대상 버프·디버프 적용 유형 | navigation selector (menu metric) |
