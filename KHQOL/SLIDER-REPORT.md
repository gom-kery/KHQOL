# 1.11.8.15 변경·검증 보고

기준: 사용자 제공 KHQOL 1.11.8.14 Full, SHA-256 `6f9a93822c003aed7f51c0b2db338e6f1f44b73f1b62d71683d8ed0e9698e683`.
결과: KHQOL 1.11.8.15 / DevTools 0.3.0(파일 동일) / Usage 0.1, schema 1, protocol 1.

## 구현

- UI.lua: 공통 화살표, 원래 Slider/EditBox와 idle 숫자층 유지, 기존 SkinButton, 실제 getter 차이가 있을 때 한 CommitSetting. min/max와 caller step/custom normalize 보존.
- SettingsLayout.lua: 셀 폭에 맞는 FitSlider와 상대 입력 앵커. 버튼을 별도 셀/설정/검색 항목으로 등록하지 않음.
- DetailLayout.lua: 줄바꿈된 제목 아래에서 화살표·트랙·입력을 함께 배치.
- SettingsUI.lua: 설정창 배율/투명도의 164px 전용 공간도 같은 배치 사용.
- UI.lua BindInput: 초기 nil 프로필 세대에서 다른 프로필로 바뀐 초안을 식별하도록 실제 편집 시작 여부를 추적. Enter/포커스 이동·ESC 규칙과 원래 비편집 갱신 호출을 보존.
- Bootstrap/Campfire 버전 상수와 DevTools를 제외한 18개 TOC를 1.11.8.15로 갱신. 기능 코드의 다른 변경 없음.
- README/CHANGELOG/DESIGN/INSTALL-GUIDE에 이번 정보를 앞에 추가하고 기존 내용을 이력으로 보존.

## 수치 정책

기존 min 기반 nearest-step 계약을 적용합니다. 반 step의 이진 표현 오차는 tick 단위 1e-10 허용 오차로 안정화합니다. 기본 정규화 결과의 소수 자릿수는 min/step에서 도출해 표현 오차를 정리하고, 매우 작은 값이나 안전 정수 범위를 벗어나는 경우 잘라내지 않습니다. custom normalize 결과는 별도 정밀도 강제 없이 유한 숫자/범위만 확인합니다.

읽기/Refresh 시 기존 off-grid 값을 바꾸지 않습니다. 첫 조작은 ±step 후보를 원래 min 기반 격자에 맞춥니다. 예: min 0, step 0.1, 기존 0.35에서 오른쪽은 0.5입니다. 범위 길이가 step 배수가 아니면 마지막 값은 max로 clamp될 수 있고, 그 max에서 다음 조작은 격자에 맞춰집니다. 기존 사용자 값이나 새 설치 기본값의 일괄 정규화는 없습니다.

한 드래그 중의 live 적용은 유지하며 Usage는 시작/끝 차이만 셉니다. focus 중 초안을 다른 값으로 바꾼 뒤 화살표를 누르면 기존 규칙대로 입력 확정 1회와 화살표 1회가 각각 생길 수 있습니다. 이는 내부 중복 집계가 아닙니다. 경계/같은 normalize 결과/비활성 조작은 setter·저장·통계 0회입니다.

## 저장·계측

저장 키·스키마·기본값·프로필 구조를 변경하지 않았습니다. 원래 setter/CommitSetting 경로를 사용하고 실제 프로필 저장이 화살표 한 번에 1회임을 검사했습니다. 프로필 전환과 모든 SavedVariables를 새 모의 실행에 복원한 뒤 값/화면을 확인했습니다. 게임의 실제 디스크 쓰기는 NOT TESTED입니다.

기존 D:Begin(slider,"arrow")/Finish를 사용합니다. 새 지표 ID나 이벤트 값 payload가 없습니다. 기존 정적 문맥·DIRECT/BRIDGE 대표 경로·ON/OFF·수신 오류 격리를 유지합니다. DevTools .3을 수정하지 않아 별도 DevTools 설치 ZIP은 필요하지 않습니다. DevTools 없이도 원래 입력과 화살표가 동작합니다.

## 검증

| 종류 | 결과 | 의미·한계 |
|---|---|---|
| 정적 | PASS | Full Lua 248개 Lua 5.1 컴파일, XML/TOC 참조, 기존 개인정보/공용 팝업/통계 폴링 검사 |
| 새 슬라이더 | PASS 985 | DevTools 있음 503, 없음 482; 정수/소수/미세 step, 경계·정규화·동일 값·잠금·입력 혼합·arrow/drag/input |
| 프로필/저장 복원 | PASS 12 | 실제 경험치 X 슬라이더 조작·프로필별 값·전체 SavedVariables fresh runtime 복원 |
| 기존 Usage/호환 | PASS 1407 | 독립/부분/구버전·집계·저장·진단·공용 확인창 쓰기 금지 |
| 기존 기능 회귀 | PASS 712 | 기존 10개 시나리오 묶음, 오류 진단 구독자 존재 |
| UI 범위/배치 | PASS | 9직업 각 300 등록 슬라이더 + 설정창 조절부 2, mock 폭 164/210/310/640 |
| 기준 설정 보존 | PASS | MAGE 전체 페이지 생성/재배치 후 .14와 .15의 기본 설정·프로필 값 완전 동일 |
| 실제 Forever | NOT TESTED | 실제 배치·클릭·폰트·전투 보안·재접속·마법책·접속 종료 |

검사 개수는 assert/시나리오 단위이며 실제 게임 전체 행동 커버리지 비율이 아닙니다. 모의 환경은 네이티브 타이밍/taint/화면 렌더링을 재현하지 못합니다. 실제 게임에서의 기존 보호 차단 해결 판정은 올리지 않았습니다.

## 남은 범위

독립 노트의 두 슬라이더와 편집기 격자 한 개는 공통 설정 함수 밖이므로 유지했습니다. 스크롤바는 의도적으로 제외합니다. 긴 누름·가속은 없습니다. 실제 사용자 등록 자료의 모든 동적 분기를 생성한 것은 아니지만 공통 생성 경로를 통과하는 위젯은 동일하게 적용됩니다. 상세 목록과 인게임 절차를 함께 확인하세요.

원본 ZIP·sources·기존 작업본·실제 설치·사용자 SavedVariables를 수정하지 않았고 Commit/Push도 하지 않았습니다. 전체 설치 ZIP에는 기준 19개 애드온 폴더가 모두 포함됩니다.
