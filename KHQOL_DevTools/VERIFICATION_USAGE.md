# 검증 결과와 실제 게임 체크리스트

**실제 WoW Forever: 전 항목 NOT TESTED.** 마법책 제보는 사용자 제공 로그·비활성 대조 결과이며 이번 빌드의 인게임 통과가 아닙니다. [PROTECTED_ACTIONS.md](PROTECTED_ACTIONS.md)의 순서를 가장 먼저 확인합니다.

## 실행 결과

| 단계 | 결과 | 범위·한계 |
|---|---|---|
| 정적 | PASS | DevTools 7 Lua, Full 모든 Lua 5.1 컴파일·XML·TOC 참조·금지 API/OnUpdate 검사 |
| Lua 모의 | PASS, 1407개 검사 단위 | 독립/신규 Full/부분 설치/구버전, 저장 복원, 설정·기능·연결·보호 로딩 경로 |
| 원래 KHQOL 회귀 | PASS, 712개 | DevTools 없이 오류를 내는 진단 수신자를 추가한 원래 시나리오 10개 묶음 |
| 실제 게임 | NOT TESTED | 보안 실행/taint, 실제 native 입력 순서·알림·판매 증거·SavedVariables 디스크 기록 |

검사 수는 assert/시나리오 단위로 완전한 사용자 행동 커버리지 비율이 아닙니다. review의 test-results.json, khqol-regression-results.json에 묶음별 수가 있습니다. `tests/run.py`와 `tests/regression.py`는 Python+lupa.lua51로 재실행합니다. 구버전 조합에는 입력 KHQOL 1.11.8.13 Full을 `--full-zip`으로 제공합니다. 원본 SHA-256을 확인합니다. private-dialog.lua는 공용 확인창 전역 재대입과 목록 쓰기를 금지한 환경에서 실제 확인/취소·ON/OFF·세대 무효화·통계 보존을 검사합니다. 이는 WoW의 taint 모델을 대신하지 않습니다.

새 공통 컨트롤의 실제 테스트 바인딩 수는 bridge.lua 결과의 mappedControls입니다. setter 오류·수신 오류·버전 불일치·중복 연결·색상취소·동일 드래그 복귀·프로필/전투 취소·reset 뒤 판매 예약 유입·과거 schema 1 보존을 포함합니다. 실제 게임의 secure 속성을 모의했다고 주장하지 않습니다.

## 판정

| 범위 | 정적·모의 판정 | 실제 게임 |
|---|---|---|
| 메뉴 방문·공통 설정·모듈 commit | GO(명시 연결 범위) | NOT TESTED |
| 체류·기능·위치 결과 | LIMITED GO, 계측 목록의 정의/제한 적용 | NOT TESTED |
| 등록 편집 초안·호환 합계 ID | HOLD/제외, 개별 설정 ID 사용 | NOT TESTED |
| 수집 준비 구현·운영 절차 | LIMITED GO | 제한 테스터 확인 필요 |
| 일반 배포·마법책 회귀 해결 | HOLD | 사용자 재현 순서 확인 전 |

## 수동 확인 방법

기록 ON 전에 현재 7일/30일 JSON을 백업합니다. `/khqoldev usage` → 전체 조회 또는 JSON의 totals와 instrumentation에서 해당 고정 ID의 기준값을 적습니다. 한 행씩 실행하고 새로고침해 증가분을 비교합니다. 테스트도 실제 통계에 포함되며 자동 초기화하지 않습니다. 사용자가 원할 때만 백업 뒤 초기화 버튼으로 지웁니다.

설정 페이지 이동은 메뉴 방문/체류를, 편집 진입은 시작 지표를, 모듈 ON은 활성 날짜를 함께 바꿀 수 있습니다. 검증하려는 단일 ID의 증가량을 비교하고 모든 총합이 하나만 늘어야 한다고 해석하지 마세요. 최초 관찰 ON 시 이미 표시된 메뉴는 관찰 시작 방문 +1이 될 수 있습니다.

| 시나리오 | 행동 전 기준 | 행동 | 기대 증가량 | 확인 위치 |
|---|---|---|---|---|
| 메뉴 경험치→시전→경험치 | 각 menu의 visits 기준 | 각 페이지에서 한 회차 대기 후 이동 | 경험치 +2, 시전 +1; 부모 중복 없음 | menu.bars.experience / menu.bars.cast.player 또는 target |
| 동일 탭·Refresh | 현재 visits | 동일 탭/새로고침/크기 조절 | 추가 방문 +0 | 해당 최종 menu ID |
| 검색·자동 복귀 | 목적지 visits | 검색으로 이동 후 위치 편집 종료 | 검색 목적지 +1, 편집 자동 복귀 +0 | 메뉴 전체 / JSON |
| 체류·조회 반복 | 현재 seconds | 같은 메뉴 10초 체류, 조회/JSON 반복 | 약 +10초, 반복 조회로 중복 없음 | 메뉴 seconds/validVisits |
| 체류 닫기/OFF | seconds | 10초 뒤 닫기; OFF 10초 뒤 ON | 닫기 전 시간만, OFF 0초 | days/menus |
| 슬라이더 드래그 | 선택 지표 changes | 시작 A→B→C 후 놓기 | +1 / paths.drag +1 | 설정 전체에서 제목/고정 ID |
| 같은 드래그 복귀 | changes | A→B→A 후 놓기 | +0 | 같은 ID |
| 별도 드래그 복귀 | changes | A→B 놓고 B→A 놓기 | +2 | 같은 ID |
| 숫자·문자 확정 | changes | 유효 변경 Enter, 다음 유효 변경 포커스 이동 | 각 실제 변경 +1, 중복 없음 | paths.input |
| 입력 취소 | changes | 오류값/ESC/창 닫기/프로필 전환 | 취소 변경 +0 | 같은 ID |
| 색상 확정 | changes | 미리보기 여러 번→다른 최종색 OK | +1 | 해당 색상 고정 ID |
| 색상 취소/복귀 | changes | preview→Cancel; 시작색으로 OK; 프로그램 닫기 | 각 +0 | 같은 색상 ID |
| 체크·라벨·드롭다운 | changes | 체크/라벨 각각 실제 변경, 같은 옵션 재선택 | 실제 변경 각 +1, 같은 값 +0 | 해당 설정 ID |
| 정적 문맥 | 각 문맥 changes | 유닛/부품, Clock 사이드, 파티 편집 레이아웃 바꿔 조작 | 각 정적 문맥 ID에만 +1 | settings / manifest 문맥 |
| 모듈 사용자/재적용 | setting.module.* | 사용자 OFF→ON; 프로필 재적용 | 실제 사용자 저장 변경 각 +1, 재적용 +0 | settings paths.click |
| 위치 무변경 저장 | position.* 기준 | 유효 진입 후 바로 저장 | start +1, save +1, changed +0 | feature.position.* |
| 위치 변경·원점 복귀 | position.* | 이동 저장; 다음 편집 이동 후 시작점 복귀 저장 | 각 start/save +1, 첫 changed +1·복귀 +0 | position.changed |
| 위치 reset/상대/연결 | position.* | 실제 저장값을 다르게 만들고 저장 | save +1, 소유 getter 확인 변경이면 changed +1 | 불명은 unconfirmed |
| 위치 ESC/전투/프로필 | cancel/reasons | 각각 별도 편집에서 종료 유발 | cancel +1, 해당 이유 +1, changed +0 | reasons.escape/combat/profile |
| 위치 실패 | unconfirmed | 검증/적용 실패 경로를 안전한 테스트 환경에서 확인 | 성공 changed 아님, 실패/취소 이유 또는 unconfirmed | 정상 게임에서 오류를 강제하지 않음 |
| DIRECT/BRIDGE 중복 | 단일 설정 changes | 새 조합에서 한 번 변경 | +1, selectedRoute=bridge | instrumentation / days.routes |
| 노트·전문기술 | 각 open | 닫힌 창 열기, 닫고 재열기 | 열림 전환마다 +1 | feature.note.open / professions.open |
| 퀘스트 | quest.manual | KHQOL Tracker에서 다른 목표 선택; 자동 동기화 대기 | 확인된 사용자 목표 변경 +1, 자동 +0 | feature.quest.manual |
| 감사 인사 | thanks.* | 유효 알림·좌클릭, 제한시 초안/지원시 전송 | 표시/클릭/초안/API 단계별; 서버 성공 아님 | feature.thanks.* |
| 파티 | party.* | 메뉴·조건을 충족한 기능 요청·초안 | 해당 단계만 +1, 조건 실패 +0 | execute와 chat_request는 합산 금지 |
| 판매·수리 | sell/repair | 잡템 없는 방문; 실제 잡템 판매; 수리 조건 통과 | 빈 큐 0, 처리 증거 방문 +1, 수리 API 요청 +1 | sell.processed / unconfirmed / repair.request |
| 알림 live/test | npc/buff/campfire | 실제 탐지와 테스트/미리보기/재적용 구분 | 정의한 실제 신규 표시만; 테스트 +0 | feature.*.display / campfire.complete |
| 지속 기능 | activeDays | Clock/XP/시전/Tooltip/Threat 켜고 평소 사용 | 같은 UTC 날짜 최대 1일, render 횟수 아님 | feature.active.* |
| OFF/ON/초기화 | JSON과 enabled | ON→OFF→ON; 백업 후 선택 초기화 | OFF 기존자료 유지; 초기화 이전 예약 유입 없음 | collection / days |
| 정상 저장 복원 | JSON 기준 백업 | 정상 /reload 또는 로그아웃 후 조회 | 카운터 유지, 중간 미접속 체류 제외 | 7일/30일 JSON |
| UTC 자정/7·30일 | dates/range | 한국 오전9시 경계에 체류/두 기간 조회 | UTC 분배·관찰 표본, 기간은 오늘 포함 | days / firstDate / lastDate |
| 구버전/단독/없는 모듈 | 연결 상태 | 별도 테스트 설치로 조합 확인 | 지원 DIRECT만, 미지원은 미연결; 도구 정상 | connected / bridgeStatus / fallback |
| 기존 도구·프로필 | 원래 설정과 도구 상태 | Frames 캡처·Console·Position 사용; 프로필 전환 | 기존 기능/설정 정상, Usage로 raw 정보 유입 없음 | 각 도구·원래 프로필 / JSON |

위 표의 실제 결과는 전부 NOT TESTED입니다. 실제 값/시각/버전과 PASS/FAIL을 사용자가 적어 검증 이력으로 남깁니다.
