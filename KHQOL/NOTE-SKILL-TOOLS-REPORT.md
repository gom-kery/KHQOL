# KHQOL 1.11.8.24 — 노트 좌표·스킬 설정·창별 일시 잠금

## 기준과 기존 조사

실제 최신 로컬 작업본은 .23 Full이었습니다. SHA256: 8524704af3d3fe36b2c4d9067555d3168b3f0a78f8b3c68dfe5c13f2c0f44eb1. 취소된 이전 요청에서는 변경 파일이 없었고 이번 첨부 요구를 기준으로 별도 baseline/과 full/을 만들었습니다. 결과는 .24, 대상은 사용자 지정 WoW Forever 1.60.1.70959 / Interface 16001입니다. 원본·sources/·이전 ZIP·실제 설치본을 수정하지 않았고 Git commit/push하지 않았습니다.

| 영역 | 기존 지원 | 이번 수정 |
|---|---|---|
| 좌표 | /way 공백, 메모 @X,Y, /nt·/노트 way, 구조화 API/핀/Navigation | 공백·쉼표 통합, 선두 지역/숫자 ID, 모호성/잘못된 지도 방어, 외부 동일 좌표·메모 재사용 |
| 스킬 패널 | 사거리/휠 탭, 등록/조회/드래그/등급, 별도 휠 fallback | 명칭, 붙인 같은 크기 탭, 네 조합 선택·독립 저장, fallback 스크롤 |
| 클릭 시전 창 | 파티 설정의 OpenClickSettings | 마법책 버튼 연결, 지연 로드/실제 Show 확인, KHQOL 패널 닫아 가림 방지 |
| 휠 | 캐릭터 up/down, 보호된 자식 2개/임시 바인딩/전투 보류/외부 충돌 | Shift 자식 2개 추가, 수정키 상태에 따라 등록 조합만 적용, 잘못된 한 조합의 독립 거부 |
| 창 이동 | 도구·타이머·스톱워치 공유 잠금 + 알림 별도 조건 | 도구/바 각각 메모리 잠금·아이콘, 첫 접속 해제, 기존 다른 창/위치/초기화/전역 편집 유지 |

## 좌표 입력·외부 등록

COORDINATE-FORMATS.md에 모든 지원 형식·우선순위·오류 정책을 기록했습니다. 지역명 공백, 숫자 ID/#mapID, 정수/소수, 쉼표 앞뒤 공백을 지원합니다. 좌표 뒤 메모의 쉼표/특수문자를 그대로 보존하며 숫자나 쉼표가 있는 일반 문장만으로 좌표를 만들지 않습니다. 지역 생략은 기존 명시 경로에서 현재 지도를 확인할 수 있을 때만 처리합니다. 중복/미확인 지도는 추측하지 않습니다.

ParseTodoWaypoint의 반환 순서는 x,y,label,map,selector 그대로입니다. 사용자 백분율은 한 번 나누고 AddTodoCoordinate는 기존 0~1 정규화 API입니다. 기존 원문/체크 상태·순서·노트·프로필을 일괄 이관하지 않았습니다. 실패한 체크리스트 입력은 일반 메모로 남고 명령은 오류/사용법을 안내합니다. 노트 없음/OFF의 API 제한을 유지합니다.

구조화 API는 같은 지도/기존 정밀도 좌표/같은 메모를 재사용하며 첫 반환값은 기존과 같이 항목입니다. 두 번째 값 duplicate로 재사용을 구분합니다. 메모가 다르면 별도 생성할 수 있고 기존 글/완료 상태를 덮어쓰지 않습니다. 전문기술의 좌표 전용 중복 검사를 이 공통 경로로 통합했습니다. 표시 후보/지도 검증/노트·프로필 재확인과 우클릭 메뉴는 유지하고 duplicate를 새 완료로 기록하지 않습니다. 지도 핀/목록/체크/완료/Navigation은 기존 Refresh 경로를 사용하며 수동 안내를 강제로 시작하지 않습니다.

## 마법책·네 조합·클릭 시전

진입 버튼과 제목은 **KHQOL 스킬 설정**입니다. 사거리/휠 탭은 폭 143·같은 테마 높이이며 오른쪽 탭을 왼쪽 RIGHT에 오프셋 0으로 붙입니다. 모듈이 빠지면 빈 기능을 만들지 않습니다. 사거리 없음의 별도 휠 패널도 같은 제목·한 탭·스크롤을 제공합니다. 기존 사거리 Core/Reference 검증과 등록 경로는 보존했습니다. 긴 주문명은 본문 높이를 늘려 스크롤하고 닫을 때 보조키 팝업도 정리합니다.

```text
KHQOL 스킬 설정
[사거리 설정][휠 클릭 시전]

[클릭 시전 열기]
보조키 [없음 / Shift]
[프레임 안 휠 시전 사용]
휠 업   [스킬 끌어 놓기] [해제]
휠 다운 [스킬 끌어 놓기] [해제]
```

편집 선택은 세션 UI 상태이고 주문을 초기화하지 않습니다. 캐릭터 변수 KHQOLPartyCharDB의 wheelEnabled/up/down을 유지하고 누락된 shiftUp/shiftDown만 0으로 보충합니다. 파티 설정에는 기존 두 입력과 Shift 두 입력을 함께 제공하여 같은 데이터를 편집합니다. 역할 프레임 프로필·KHQOL 전체 프로필 전환으로 캐릭터 주문을 잃지 않습니다. 각 주문/아이콘/등급과 해제는 해당 조합만 처리합니다.

기존 보호된 그룹 버튼에 Shift용 SecureActionButton 자식 두 개를 추가했습니다. 한 컨트롤러가 RegisterStateDriver로 없음/Shift/다른 보조키를 구분하고, 마우스 진입 버튼의 임시 바인딩만 갱신합니다. Shift에서 일반 bare 휠 바인딩을 정리하므로 미등록 Shift에 일반 주문을 대입하지 않습니다. Ctrl·Alt·복합 보조키는 이 기능의 등록 대상이 아니며 기존 입력을 유지합니다. 이탈/숨김/유닛 제거는 기존 secure 정리 경로, 실제 모듈 해제는 기존 안전한 적용 경로에서 정리합니다.

전투 중 이미 적용한 주문은 secure 경로로 유지하고, 일반 Lua에서 등록/해제·모듈 상태를 바꾸면 기존 RequestApply/Defer에 따라 전투 종료 후 최신 값을 적용합니다. 마법책 드래그 등록/열기 버튼은 전투 중 제한합니다. 전투 중 모듈 OFF 요청도 실제 보호된 표시/입력 해제는 종료 후 적용합니다. 외부 Clique/Clicked/HealBot/VuhDo/Cell 또는 ClickCastFrames 감지는 기존대로 네 조합 적용을 보류하고 등록 데이터는 보존합니다.

바인딩 방식은 [Blizzard restricted frame methods](https://raw.githubusercontent.com/Gethe/wow-ui-source/classic/Interface/AddOns/Blizzard_RestrictedAddOnEnvironment/RestrictedFrames.lua), [제한 환경 API](https://raw.githubusercontent.com/Gethe/wow-ui-source/classic/Interface/AddOns/Blizzard_RestrictedAddOnEnvironment/RestrictedEnvironment.lua), [secure state driver](https://raw.githubusercontent.com/Gethe/wow-ui-source/classic/Interface/AddOns/Blizzard_RestrictedAddOnEnvironment/SecureStateDriver.lua)를 대조했습니다. classic 미러는 구현 근거이며 정확히 이 Forever 빌드에서 실행했다는 증거가 아닙니다. 새 addon OnUpdate/상시 ticker를 만들지 않았고 등록 조합이 있을 때 기존 native 상태 관리자를 사용합니다.

‘클릭 시전 열기’는 기존 OpenClickSettings에서 ClickBindingFrame_LoadUI/Blizzard_ClickBindingUI를 필요할 때만 로드하고 SetUIPanelShown 후 IsShown을 확인합니다. 성공하면 마법책 KHQOL 패널과 설정창을 닫아 native MEDIUM 창을 가리지 않게 합니다. native 프레임 strata·위치·클릭 시전 설정은 변경하지 않습니다. 미지원/열기 실패/전투는 기존 메시지 영역에 안내합니다.

## 창별 일시 잠금·타이머

도구 창과 타이머 바에 기본 LockButton Locked/Unlocked texture를 쓰는 KHQOL 버튼을 배치했습니다. 같은 세션의 닫기/재열기·접기/펼치기·프로필 전환에서 각각 상태를 유지하고, 새 접속/리로드의 새 모듈 런타임에서는 해제입니다. 잠금은 저장하지 않고 위치는 clockTools.positions의 기존 point/relativePoint/x/y로 저장합니다. 기존 positionLocked/timerBarLocked 필드는 삭제/초기화하지 않았습니다.

| 현재 상태 | 클릭 | 툴팁 |
|---|---|---|
| 이동 가능 | 잠금 | 창 잠금 / 창을 끌어서 옮기지 못하게 합니다. |
| 이동 불가 | 해제 | 창 잠금 해제 / 창을 끌어서 옮길 수 있게 합니다. |

자물쇠는 독립 클릭 영역이고 배경/제목의 이동 경로와 분리했습니다. 이동 중 잠금·닫기·초기화는 SaveClockTool로 이동 종료/저장을 통일합니다. 바 폭을 314에서 342로 늘려 숫자/진행 바/일시정지/펼치기/잠금/닫기의 영역을 분리했습니다. 타이머 동작·남은 시간·종료 시각·일시정지는 원래 로직을 유지합니다. 전역 편집 취소는 위치/세션 상태를 유지하고 완료는 원래 writer로 저장 후 해당 창 세션을 잠급니다. 위치 초기화도 같은 경로입니다.

스톱워치는 기존 ClockToolsLocked 공유 저장값 판정, 중앙 테스트 알림은 기존 positionLocked와 Alt 조건, 시계 HUD는 기존 db.locked를 유지합니다. 도구/바의 새 일시 잠금은 이 값을 건드리지 않습니다. 설정 페이지의 도구 공유 잠금 행·검색 등록·공통 이동 앵커 중복을 제거했습니다. 초기화/크기/전역 편집은 남아 있습니다.

## Usage Analytics·보존

DevTools **0.3.5/catalog revision 7/Usage v0.1/schema 1/protocol 1**입니다. 기존 1,639개 카탈로그 행을 필드별 대조해 보존하고 setting.partyFrames.shiftUp/shiftDown 두 개를 추가했습니다. 기존 업/다운·휠 사용은 원래 ID를 유지합니다. 편집 대상 선택은 새 설정 변경이 아니고 실제 주문 변경만 한 번 집계합니다.

도구/바 아이콘은 기존 toolsLocked/timerBarLocked 설정 ID로 실제 상태 변경만 집계하며 Position Editor start가 아닙니다. .24부터 세션/직접 아이콘 의미이므로 이전 저장형·공유형 로그는 관찰 버전과 함께 해석해야 합니다. 과거 정의는 유지하고 제품 설정/검색만 제거했습니다. 현재 상단 잠금 인벤토리는 47개입니다.

좌표 API는 새 개인정보 이벤트를 만들지 않습니다. 전문기술은 실제 새 항목만 note_added이고 공통 API duplicate는 완료가 아닙니다. 지도 ID·X/Y·지역명·원문·메모·주문값·실패 문자열을 진단에 전달하지 않습니다. DevTools OFF/미설치와 선택 모듈 미설치에서도 동작을 검사했습니다. 저장 변수 선언과 기존 체크/프로필/위치 구조는 유지하며 일괄 이관은 없습니다.

## 정적·Lua 모의 검사

| 검사 | 결과/합성 assert 수 |
|---|---|
| 좌표 변형·공백 지역·ID·모호성·숫자 메모·오류·원문·중복·현재 지도 실패 | PASS / 300 |
| 이름·붙인 탭·긴 주문 스크롤·팝업 정리·Range/Party 선택 설치 | PASS / 61 |
| 생산용 제한 snippet 실행·네 주문·입력 상태·외부 충돌·전투 보류·클릭 시전 연결·캐릭터 저장 복원 | PASS / 119 |
| 독립 잠금·닫기/재열기·타이머·전역 완료/취소·위치와 세션의 새 런타임 복원 | PASS / 107 |
| 기존 공통 앵커/헤더·버프 클릭·전역 editor/provider | PASS / 4328 |
| 기존 Usage·로그 승계·OFF·개인정보·보호 동작 합성 회귀 | PASS / 1446 |
| 기존 기능·사거리·도안 위치·슬라이더·공통 숙련 데이터 | PASS / 2427 |
| 기존 프로필/저장 복원·파티 계정 프레임 프로필/이동 | PASS / 160 |
| 9개 직업 슬라이더 인벤토리·기존 기본값 | PASS / 직업별 공통 306개 |
| 통계 ID 호환 | PASS / 기존 1,639행, 신규 설정 2개 |

배포 Lua 256개를 Lua 5.1로 컴파일하고 XML/TOC를 검사했습니다. 합성 secure fixture는 실제 생산 snippet을 닫힌 API 환경에서 실행하고 전투 중 일반 protected write를 검사합니다. 보안 실행/taint/실제 주문 시전의 게임 엔진을 재현하지는 않습니다. 실제 Note/map pin provider를 모의 세계지도에 연결한 등록·중복·재로딩 검사도 유지했습니다.

## 실제 WoW Forever 검사 — 모두 NOT TESTED

1. 노트에서 요구된 모든 공백/쉼표 입력을 새 등록·수정하고 원문/체크/순서/메모·핀·Navigation을 확인합니다. #ID와 숫자 메모, 중복 지도, 범위 오류, 현재 지도 없음, 512/2048바이트 경계도 확인합니다.
2. 전문기술 우클릭·지도 Shift 클릭 등 외부 등록을 반복해 동일 항목/다른 메모 정책과 기존 글/완료 보존을 확인합니다. 기록 OFF와 DevTools 비활성에서도 동일해야 합니다.
3. 마법책 제목/진입·붙인 탭·긴 주문·스크롤·닫기, Range 또는 UnitFrames 폴더가 없는 구성, native ClickBindingFrame 최초 로드/재열기·전투 안내·가림을 확인합니다.
4. 네 조합에 서로 다른 주문을 넣어 실제 비전투/전투 시전을 확인합니다. Shift를 프레임 안에서 누르고 놓기, 미등록 Shift·Ctrl/Alt/복합키·프레임 밖의 기존 휠 동작, AnyDown/AnyUp 중복 시전이 없는지 확인합니다.
5. 진입/이탈·숨김·유닛 제거/교체·모듈 OFF·전투 중 변경·전투 종료·외부 클릭 시전 애드온을 확인합니다. 전투 변경은 종료 후 최신 값이 적용되어야 합니다. 역할/전체 프로필·리로드 후 네 캐릭터 값 보존도 확인합니다.
6. 도구/바를 독립 잠금하고 배경 이동·입력/시작/정지/닫기·자물쇠 클릭을 확인합니다. 이동 중 잠금/닫기, 접기/펼치기, 실행/일시정지, 작은 바 겹침, 크기·초기화·전역 편집 완료/취소를 확인합니다.
7. 같은 세션 재열기/프로필은 잠금을 유지하고 새 접속/리로드는 이동 가능해야 하며 위치는 복원되어야 합니다. 스톱워치·중앙 알림·HUD 조건과 이전 마법책/게임 메뉴 차단 회귀도 확인합니다.
8. 기록 ON에서 실제 설정 변경 1회와 Position Editor 시작의 분리를 확인하고 JSON에 좌표·메모·오류 원문이 없는지 확인합니다.

## 제출·재실행

Full ZIP이 설치본이며 같은 DevTools 0.3.5를 포함합니다. 별도 DevTools 전체 ZIP은 단독 교체용입니다. Review의 full/ 최종, baseline/ 원본 .23, compat/ .13 Usage 기준, release/ 동일 DevTools와 tests/·결과 JSON·현재 입력 문서·patch·manifest를 제공합니다. 외부 native 구현 전체/원문 HTML/실사용자 저장 데이터는 포함하지 않습니다.

Python+lupa.lua51 환경에서 tests/coordinate_formats.py, skill_ui.py, wheel_skills.py, tool_locks.py, compatibility.py와 기존 run.py, tooltip_policy.py, common_levels.py, profile_roundtrip.py, anchors.py, locks_guide.py, lock_ui.py, party_anchors.py, global_editor.py, sliders_run.py, audit_sliders.py, regression.py, recipe_positions.py로 재검사합니다. package.py에는 기준 ZIP이 기록된 outputs 경로에 필요합니다. 현재 사용법은 .24 README/보고서이며 이전 문서는 버전별 이력입니다.
