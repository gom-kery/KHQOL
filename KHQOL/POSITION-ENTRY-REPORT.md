# 1.11.8.19 참고 안내

아래 내용은 이전 버전의 조사/구현 기록입니다. 모듈별 위치 편집 메뉴는 1.11.8.19에서 제거했고 버프 알림 독립 잠금과 드래그를 추가했습니다. 현재 동작·검증·제한은 LOCK-UI-REPORT.md와 HEADER-LOCKS.md를 따르세요. 전문기술 숙련 데이터와 안내 동작은 유지합니다.

---

# KHQOL 1.11.8.17 위치 편집 진입 — 조사·구현·검증

## 기준과 범위

- 기준: 직전 배포 KHQOL 1.11.8.16 Full. SHA256 `fcc2f4291c2c66b89d6b5eb43fc00a8fdd2803d03408674220ec93c9487d681a`.
- 결과: **KHQOL 1.11.8.17**, DevTools **0.3.0** / Usage v0.1 / schema 1 / diagnostics protocol 1 유지.
- 1.11.8.15 공통 슬라이더 화살표/정규화/입력과 1.11.8.16 도안 알림 위치 보완을 이어받았습니다. DESIGN.md 최신 계약을 대조했습니다. 설치본을 자동 변경하거나 Git commit/push하지 않았습니다.
- 수정 범위는 헤더 진입/탐색 메뉴/순수 조회/새 경로의 대상 확인 및 중복 버튼 정리입니다. 이동/저장 엔진, 위치 데이터 형식, 모듈 기본값을 교체하지 않습니다.

## 조사와 적용 현황

아래 수는 설치·프레임 가용성·모듈 사용 조건을 만족했을 때의 **독립 선택 가능 수**입니다. OFF/조건 미충족은 0이며 지원 버튼을 비활성화하고 이유를 안내합니다. 연결된 자식은 선택 수에서 제외하지만 편집기의 종속 관계는 유지합니다. 전체 편집기 대상 수와 다릅니다.

| 페이지·문맥 | 이전 진입 | ID·표시 대상 / 조건별 수 | 편집·저장 범위 | 상단 적용 |
|---|---|---|---|---|
| 경험치 | 위치 잠금 해제 후 직접 이동, 전체 편집기 | `experience` 경험치 바; 가로형 1, 세로형 0 | 기존 좌표/현재 전체 프로필 | 단일 |
| 시전·플레이어 | 본문 드래그 이동 | `cast`; 자유 위치 1, 자원바 연결 0 | free 위치/현재 전체 프로필; 연결 시 resource와 이동 | 현재 시전 유닛 단일 |
| 시전·대상 | 본문 드래그 이동 | `cast.target`; 전용 사용 ON+접근 가능한 대상 시전바 1 | targetPosition/현재 전체 프로필 | 플레이어 제외, 단일 |
| 자원·스윙 | 잠금 해제·전체 편집기 | `resource` 자원/스윙 그룹 1. `resource.combo`는 지원 직업·폼·공개 콤보 정보+showCombo+FREE+프레임 존재 때 추가, 최대 2 | 기존 본체/콤보 필드·현재 전체 프로필 | 단일/다중. 자원과 스윙을 분리하지 않음 |
| 환경 타이머 | 잠금 해제·전체 편집기 | `environment` 그룹; 바 방식 1. HUD는 `environment.text.BREATH/EXHAUSTION/FEIGNDEATH` 중 사용 타이머 텍스트 추가, 2~4. 모두 OFF이면 기존 BREATH 예시 규칙 | 기존 x/y 및 hudTextPositions/현재 전체 프로필 | 단일/다중, 텍스트는 그룹 자식 |
| 시계·정보 | 잠금 해제·전체 편집기 | `clock`, `clock.date/weekday/money/performance/guild` 중 사용/실제 프레임. `clock.alert/tools/timerBar/stopwatch` 중 실제 프레임; 최대 10 | 기존 Clock/도구 위치·현재 전체 프로필 | 현재 조건의 안정된 provider 순서 메뉴 |
| 전투 상태 / 위협 / PvP | 직접 이동·전체 편집기 | 각각 `combat`, `threat`, `pvp` 각 1 | 기존 위치·현재 전체 프로필 | 단일 |
| 모닥불 | 직접 이동·전체 편집기 | `campfire` 발견/진행, `campfire.complete` 효과 획득, 최대 2 | 기존 position/completePosition·현재 전체 프로필 | 다중 |
| 기본 UI | 본문 기본창 전체/주사위/알림 위치 버튼 | `basicUI.Map/Character/Talents/Spellbook/Macro` 5 + `basicUI.roll/alerts` 2, 독립 스위치별 0~7 | 계정 공용. 닫힌 창은 기존 위치 예시 | 기본 UI 모듈 OFF에도 독립 설정을 기준으로 메뉴 |
| 일반 편의·공통 | 버프 알림/휴지통 본문 버튼 | `buffThanks` 1, `bagTrash` 사용+free일 때 1, 총 0~2 | 현재 전체 프로필 | 별도 모듈 토글 없이 헤더. attached→free 자동 변경 제거 |
| 일반 편의·파티 | 파티 버튼 본문 위치 버튼 | `partyButton` 별도 사용 ON 때 1 | 현재 전체 프로필 | 다른 편의 대상 제외, 헤더 단일 |
| 전문기술 | 본문 통합 위치 편집 | `professions` 버튼 ON 때 1; `professions.panel`은 부모에 연결되어 독립 선택 제외 | 현재 전체 프로필 | 별도 모듈 토글 없이 헤더 단일 |
| 노트 | 창 직접 드래그·전체 편집기 | `note` 창 + `quest` 공용 안내 HUD, 최대 2 | 노트 window 및 기존 NavigationUI.db 위치/현재 전체 프로필; 노트 내용은 별도 공용 콘텐츠 유지 | 단일/다중, 설정창 등 공통 도구 제외 |
| 퀘스트·길 안내 | 잠금 해제·전체 편집기 | `quest` 공용 안내 HUD 1. 목표 추적기 탭 0 | 기존 NavigationUI.db 위치/현재 전체 프로필 | 길 안내에 단일, 목록 탭은 숨김 |
| 사거리 | 직접 이동·거리 본문 버튼 | displayMode distance는 `range.distance`, 그 외 `range`; 각 문맥 1 | 기존 위치/캐릭터 DB 및 전체 프로필 캡처 정책 유지 | 단일. 마우스오버 추종 표시는 별도 대상 아님 |
| 툴팁 | 본문 드래그 편집 | `tooltip.position`; mouseRight ON 때 1 | 기존 커서 기준 x/y·현재 전체 프로필 | 단일, 기존 위치 예시 |
| 유닛·기본/체력·자원 | 본문 유닛 프레임 위치 이동 | 현재 유닛의 `unitFrames.<unit>.root`, 대상의 대상은 `unitFrames.targettarget`; compact ON 1, OFF 0 | rootPosition, 대상의 대상 기존 frameX/Y 처리/현재 전체 프로필 | `unitRoots` 전용 진입 유지. 기본/바 문맥에서 현재 루트 선택 |
| 유닛·이름·레벨 | 각 본문 드래그 이동 | 현재 유닛 `unitFrames.<unit>.name/level`, 사용 가능한 공개 부품 최대 2 | 기존 보정값/현재 전체 프로필 | 다른 유닛·부품 제외 |
| 유닛·상태·징표 | 각 본문 드래그 이동 | 현재 유닛 `.status`, player/target `.marker`, player `.rest/.combat`, target `.monster`, pet `.happiness` 중 조건 만족 대상 | 기존 보정값/현재 전체 프로필 | 현재 부품의 독립 대상 메뉴, 행복도 경로를 상태에 연결 |
| 유닛·오라 | 공통/분리 본문 드래그 이동 | player `.buffs/.debuffs` 최대 2. target `.auras.<category>` 공통 1 또는 `.buffs/.debuffs` 분리 2 | 기존 오라 보정값/현재 전체 프로필 | 현재 friendlyPlayer/attackableNPC 분류만 표시 |
| 유닛·직업 보조 | 본문 드래그/직접 이동·전체 편집기 | `.player.totems`, `ammo` 중 실제 직업·표시·프레임 조건 만족 항목. 서로 독립 가능 여부는 기존 공급자 조건 사용 | 기존 보조 필드/현재 전체 프로필 | 현재 직업 보조 문맥만 표시 |
| 파티·공격대·프레임 | 전체 편집기 + 즉시 저장 별도 미리보기 | `partyFrames.party`, `partyFrames.raid` 현재 공격대 배치, 적용 성공 상태 때 2 | 계정 공용 파티·공격대 프레임 프로필 | 배치 탭 다중. 별도 미리보기의 즉시 저장 정책은 그대로 |
| NPC / 마우스 잔상 / 오브젝트 강조 / 미니맵 등 | 직접/추종 기능 또는 공급자 없음 | 독립 Position Editor 대상 없음 | 기존 조작 유지 | 헤더 버튼 숨김 |

기본창 Talents/Spellbook은 기존 서로 다른 ID/저장 항목을 유지합니다. 실제 기본 게임에서는 동일 PlayerSpellsFrame을 공유할 수 있습니다. 같은 ID의 중복 등록만 한 항목으로 합칩니다. unitRoots 진입 후에는 기존 전용 편집기가 다른 유닛 루트도 표시할 수 있으며 처음 선택은 요청한 현재 유닛입니다.

## 공통 처리와 보존

- 대상 조회는 기존 provider와 조건을 사용합니다. 전용 query flag는 pcall 종료 뒤 복원하고, 가상 예시/부품 프록시/파티 예시의 생성·좌표·크기·소유권 등록을 생략합니다. writer/apply/reset/lock은 호출하지 않습니다. 새 이름 파싱/중복 ID 카탈로그/저장 스키마는 없습니다.
- 헤더는 기존 ButtonHeight·스킨·한글 폰트·disabled hint·공통 스크롤 메뉴를 사용합니다. 본문 폭 600px 미만은 설명 아래 버튼과 토글을 배치합니다. 650/900/1200px 창 모의에서 겹침/헤더 높이/본문 시작점을 검사했습니다. 실제 픽셀 렌더링은 미검증입니다.
- 메뉴는 창 바깥의 기존 popup parent에 붙고 화면 경계 제한과 긴 텍스트 줄바꿈/스크롤을 사용합니다. 바깥 클릭은 메뉴가 보일 때만 GLOBAL_MOUSE_DOWN을 관찰하며 닫힐 때 해제합니다. 페이지/현재 유닛·부품/프로필/조건 변화·전투·창 닫기에 정리합니다. ESC는 기존 UISpecialFrames 설정창 닫기 정책을 사용합니다.
- 선택 직전 현재 route·profileGeneration·provider 조건을 재조회합니다. 엔진의 새 exact 인자에서 실제 ID/프레임/핸들을 다시 확인합니다. 거부 시 start 0, 다른 첫 대상 대체 0입니다. 기존 전체 편집 버튼과 공개 Enter/OpenUnitPositionEditor 경로는 남습니다.
- 같은 본문 진입 버튼은 레이아웃 셀 없이 검색 메타데이터만 등록합니다. 기존 제목·section·경로 검색 ID는 유지하고 고정 헤더를 강조합니다. 초기화/위치·크기 슬라이더/잠금/미리보기는 남았습니다. 휴지통의 과거 ‘직접 배치로 바꾸고 편집’은 기존 배치 선택과 순수 편집으로 분리했습니다.
- 드래그/좌표 보정/부모 자식/저장/취소/리셋/ESC/전투/프로필 종료 및 돌아가기 처리는 기존 엔진을 사용합니다. 전투 중 설정 복귀 생략도 기존 정책입니다. 헤더가 이동 모드나 위치를 초기화하지 않습니다.

## 슬라이더·데이터·Usage

공통 Slider의 화살표·숫자 입력·드래그·min/max/step·정규화·FitSlider 계약은 그대로입니다. 9개 직업에서 공통 설정 슬라이더 300개와 창 슬라이더 2개의 배치/화살표를 확인했고, 전체 페이지 구축 후 저장 설정/프로필은 .16 기준과 같았습니다. 새 실행에 SavedVariables를 넘겨 프로필 값과 헤더 진입·취소를 재확인했습니다.

메뉴 열기/닫기/선택은 navigationOnly/menuNavigation이며 CommitSetting/Changed/추가 카운터를 호출하지 않습니다. 실제 시작과 최종 결과는 기존 UsageDiagnostics만 전달합니다. 메뉴 start 0·설정 변경 0, 거부 start 0, 시작 1, 변경 없는 저장 changed 0, 실제 변경 저장 changed 1, 취소 changed 0, 자동 설정 복귀 방문 증가 0을 검사했습니다. DevTools의 카탈로그/기록/프로토콜/allowlist와 코어 진단 파일은 .16과 byte 동일합니다. OFF/미설치 모두 동작했습니다.

## 검사 결과

| 구분 | 결과 | 근거/한계 |
|---|---|---|
| 정적 | PASS | Full Lua 249개 Lua 5.1 컴파일, DevTools Lua 7개, XML/TOC 참조·버전·패키지 해시 |
| 신규 위치 진입 | PASS 948 | full 473 + no DevTools 467 + 일부 모듈 미설치 5 + Rogue 콤보/중복 ID 3 |
| 기존 기능 회귀 | PASS 712 | 원래 10개 시나리오. 본문→헤더로 옮긴 버프 위치 검사만 새 UI에 맞춰 변경, 나머지 기능 유지 |
| Usage/호환 | PASS 1407 | 기존 구독/기록 OFF/standalone/구버전/보호 로딩/저장 schema·버전 이력 |
| 슬라이더 동작 | PASS 985 | 화살표·드래그·숫자·정밀도·제한·프로필 초안 |
| 슬라이더 전수/기본값 | PASS | 9직업 각 300+2, 기존 값/프로필 equality, mock 폭 164/210/310/640 |
| 실제 설정 프로필·리로드 모의 | PASS 15 | 별도 프로필의 값, 새 runtime SavedVariables 복원·헤더 진입·취소 |
| 도안 알림 위치 회귀 | PASS 112 | .16 보완과 기본 쌓임/풀/크기/전투 가드 유지 |
| 실제 Forever 인게임 | **NOT TESTED** | 실제 화면 렌더링·보호/taint·실제 입력/전투/native 지연·다른 애드온 조합 |

조회 모의는 CreateFrame/Virtual/SaveCurrentProfile를 실패하도록 바꿔 프레임 생성/예시 이동/저장을 금지한 상태에서 수행하고 저장 데이터 전후를 비교했습니다. 기본창·타이머·대상 시전·유닛·파티의 실제 provider를 사용했습니다. 대상 시전/유닛 부품은 공개 구조를 가진 합성 프레임을 공급했습니다. 파티 모의는 보안 파티 초기화가 제공되지 않아 provider의 기존 ‘적용 완료’ admission flag만 설정한 분리 시험을 포함합니다. 이것은 실제 게임 적용 성공이나 화면 위치를 입증하지 않습니다.

`position-entry-observed.json`은 시험 중 여러 설정 상태에서 얻은 실제 ID·이름·경로·모드 목록이며 기본값 현황표가 아닙니다. `position-entry-census.json`도 시험 마지막 조건의 스냅샷이므로 0은 미구현의 의미가 아닙니다. 위 표의 조건과 함께 읽으세요.

## 인게임 확인 순서 — 전부 NOT TESTED

1. 기존 저장 데이터를 유지해 Full 설치 후 접속. 경험치 가로형의 상단 단일 진입, 세로형/OFF의 이유 표시, 오른쪽 위 전체 편집을 확인합니다.
2. 시계·모닥불·기본 UI의 메뉴를 열고 바깥 클릭/ESC/페이지 전환으로 닫습니다. 값과 편집 start/설정 변경 카운터가 늘지 않는지 확인합니다.
3. X/Y 화살표·드래그·직접 입력 후 편집 시작 위치를 확인합니다. 이동 저장/취소/무변경 저장 각각 좌표와 숫자, start/save/changed/cancel을 확인합니다.
4. 자원·스윙 그룹, Rogue 또는 고양이 Druid FREE 콤보, 자원바 연결 시전, 환경 HUD 텍스트를 확인합니다. 부모 이동과 상대 위치를 확인합니다.
5. 유닛/부품/오라 분류 변경과 전용 루트 이동 후 같은 설정으로 돌아오는지 확인합니다. 대상 시전바와 파티/현재 공격대 배치도 선택합니다.
6. 기본 UI 모듈 OFF에서 기본창/주사위/알림의 독립 설정으로 편집하고 계정 공용 위치를 확인합니다. 도안 연속 습득의 .16 위치 보완도 확인합니다.
7. 가방 attached에서는 편집 대상이 없고 free 선택 후 편집되는지 확인합니다. 파티 버튼·전문기술은 각 사용 스위치를 확인합니다. NPC·추종 효과·미니맵은 기존 직접 조작을 확인합니다.
8. 메뉴를 열고 옵션/프로필을 바꾸고, 편집 중 ESC·전투 진입·프로필 변경을 시도합니다. 다른 대상에 대체 진입하지 않고 기존 정책대로 취소되는지 확인합니다. 전투 종료 후 재진입합니다.
9. DevTools 기록 ON/OFF/미설치 각각 편집하고 실제 로그아웃·재접속 후 프로필과 위치를 확인합니다. 좁은 창·한글 긴 이름·화면 모서리에서 헤더/메뉴/본문을 확인합니다.

## 제출·재검사

Full ZIP만 설치합니다. Review ZIP은 full(소스)/baseline(.16)/compat(.13)/release(DevTools .3)/tests/검사 JSON/diff/문서를 포함한 검토용입니다. 기존 Review를 설치할 필요가 없습니다. Python+lupa.lua51 환경에서 tests/run.py, position_entry.py, sliders_run.py, audit_sliders.py, profile_roundtrip.py, regression.py, recipe_positions.py를 실행할 수 있습니다. Python 패키지 lupa는 환경에 설치해야 하며 Review ZIP에 실행 환경 자체를 포함하지 않습니다.

이전 버그 재현 스크립트 reproduce_baseline.py는 .15 기준의 과거 도안 문제 전용이므로 현재 .16 기준 회귀 목록에서 제외했습니다. DevTools 수정이 없어 별도 새 DevTools ZIP은 만들지 않았습니다. sources/·이전 배포·설치본은 수정하지 않았습니다.

바깥 클릭의 공개 이벤트/마우스 판정 패턴은 [게임 UI 소스의 이벤트 사용 예](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_DamageMeter/DamageMeterSourceWindow.lua)를 참고했습니다. 현재 설치 Forever 빌드와 동일하다고 단정하지 않으며 게임에서 최종 확인해야 합니다.
