# KHQOL 1.9.8 구현 보고서

바 설정 카테고리와 환경 타이머를 구현했습니다. 자동 검증은 통과했으며, 실제 Forever 클라이언트에서의 동작·화면 검증은 수행하지 못했습니다.

설치 ZIP에는 `KHQOL/` 폴더가 들어 있습니다. 해당 폴더를 `Interface/AddOns/`에 설치하고, `/kh` → **바 설정** → **환경**에서 **환경 타이머 사용**을 켜세요. 첫 설치 및 기존 버전 업데이트 시 환경 타이머의 기본값은 OFF입니다.

## 1. 수정 / 추가 파일

| 구분 | 파일 | 변경 내용 |
|---|---|---|
| 추가 | `Modules/EnvironmentTimer.lua` | 타이머 이벤트, 표시, 상태 효과, 이동, Blizzard 표시 제어 |
| 추가 | `UI/BarsSettings.lua` | 확장 가능한 탭 등록 구조 및 환경 설정 화면 |
| 수정 | `Bootstrap.lua` | 환경 타이머 모듈 등록, 버전 1.9.8 |
| 수정 | `KHQOL.toc` | 신규 파일 로딩, 버전 1.9.8 |
| 수정 | `Core.lua` | 환경 타이머 기본 OFF 및 기존 활성화 흐름 연결 |
| 수정 | `Profiles.lua` | 기존 프로필 저장·복원 대상에 환경 타이머 추가 |
| 수정 | `SettingsUI.lua` | 바 설정 카테고리와 전용 콘텐츠 연결 |
| 추가 | `RELEASE-1.9.8.md` | 이 보고서 |

원본 ZIP과 비교해 기존 파일 101개는 바이트 단위로 동일합니다. 기존 CastBar, ResourceSwing, Tooltip, Clock, BuffReminder와 다른 기능 모듈의 코드를 수정하지 않았습니다. 공유 파일 변경은 위 연결 지점에 한정했습니다. 이것이 게임 내 전체 기능 회귀 검증을 대신하지는 않습니다.

## 2. 구현 기능

- 바 설정 상단의 경험치 / 시전 / 리소스·스윙 / 환경 탭.
- 경험치 탭은 향후 통합 공간입니다. 시전·리소스/스윙 탭은 기존 설정 페이지를 여는 버튼을 제공합니다. 기존 기능을 강제로 이동하지 않았습니다.
- `BarsSettings:RegisterTab(id, title, build, page)`로 새 설정 빌더 또는 기존 페이지 링크를 등록할 수 있습니다.
- BREATH, EXHAUSTION, FEIGNDEATH 개별 사용 설정.
- 가로형, 세로형, 곡선처럼 보이는 좌우 HUD형.
- 크기·위치·배율·투명도·HUD 두께·간격, 세로 채우는 방향.
- 이름·시간·퍼센트 조합 및 요청한 다섯 가지 텍스트 프리셋.
- 정상·주의·위험·긴급 상태, 주의 Glow, 위험의 느린 Pulse, 긴급의 빠른 Pulse.
- 별도 중앙 경고 프레임, 기존 `Media/aggro.wav` 경고음.
- 그룹 드래그와 X/Y 저장, 위치 기본값 복원.
- 공통 UI Builder, Theme, 체크박스·슬라이더·드롭다운·버튼 및 비활성 처리를 사용했습니다.

## 3. Mirror Timer 처리

`MIRROR_TIMER_START`, `MIRROR_TIMER_STOP`, `MIRROR_TIMER_PAUSE`, `PLAYER_ENTERING_WORLD`를 처리합니다. 로그인·지역 진입·설정 변경·기능 활성화 시 `GetMirrorTimerInfo()`로 진행 중인 타이머를 다시 조회합니다.

최대값과 시작값은 API/이벤트의 실제 밀리초 값을 사용합니다. 진행 중에는 `GetMirrorTimerProgress(timer)`의 현재값을 우선 사용합니다. API가 값을 반환하지 않거나 호출이 실패하면 마지막 실제값과 이벤트의 진행률 `scale`로 보간합니다. 최대 시간이나 종족별 호흡 시간을 고정하지 않았습니다.

타이머의 값이 0이 되어도 활성 여부는 STOP 이벤트를 기준으로 판단합니다. 일시 정지, 회복 방향 및 다시 전달되는 START 이벤트를 처리합니다. 음향 재생 기록은 해당 타이머의 STOP 이후 지워집니다.

활성화되고 표시 대상으로 선택된 타이머가 있을 때만 0.05초 간격으로 갱신합니다. 마지막 표시 대상의 종료 시 OnUpdate를 제거합니다. 이동용 예시는 갱신·경고음 없이 표시합니다. 프레임과 HUD 조각은 처음 한 번 만들고 재사용하며, Pulse는 AnimationGroup으로 처리합니다.

## 4. Blizzard UI 대체 / 복원

Mirror Timer 전체를 숨기거나 이벤트를 해제하지 않습니다. 지원 종류이고, 사용자가 선택했으며, 유효한 최대값으로 KHQOL이 처리 중인 타이머의 **해당 기본 프레임만** 투명도를 0으로 만들고 마우스 입력을 끕니다.

원래 투명도와 마우스 상태를 기록합니다. 타이머별 사용 해제, 전체 기능 OFF, 종료 또는 프레임이 다른 타이머로 재사용되면 기록한 값을 복원합니다. 기본 프레임은 계속 표시 상태와 이벤트·진행값 처리를 유지하므로, 활성 타이머의 슬롯이 빈 슬롯으로 오인되지 않습니다. 기능 OFF 시 진행 중인 기본 타이머를 즉시 복원할 수 있습니다.

`DEATH` 같은 미지원 타이머는 대체하지 않습니다. 유효하지 않은 최대값을 전달받은 경우에도 기본 UI를 대체하지 않습니다. Classic의 `MirrorTimer1..N` / `MirrorTimer_Show`와, 현대형의 `MirrorTimerContainer.mirrorTimers` / `Setup` 경로를 감지하도록 작성했습니다. Classic 원본 코드를 활용한 모의 검증은 수행했지만 현대형 경로와 Forever 자체 구현은 실기 검증하지 못했습니다.

## 5. SavedVariables

독립 SavedVariables를 추가하지 않았으며 TOC의 SavedVariables 선언은 동일합니다.

| 위치 | 저장 항목 |
|---|---|
| `KHQOLDB.enabled.environmentTimer` | 전체 사용 여부, 기본 false |
| `KHQOLDB.modules.environmentTimer.timers` | BREATH / EXHAUSTION / FEIGNDEATH 사용 여부 |
| `KHQOLDB.modules.environmentTimer` | style, x, y, width, height, scale, alpha, direction |
| 같은 위치 | hudSize, hudThickness, hudGap |
| 같은 위치 | showName, showTime, showPercent, textFormat |
| 같은 위치 | caution, danger, critical, centerWarning, sound |

기존 `MergeDefaults` 방식으로 새 항목의 기본값만 보충합니다. 환경 타이머 설정은 기존 프로필 캡처·불러오기·복사·저장 구조에 포함됩니다. 오래된 프로필을 읽으면 환경 항목만 기본값으로 추가합니다. 실제 프로필 캡처/불러오기 함수로 관련 검증을 수행했습니다.

위치 잠금 해제는 일시적인 편집 상태입니다. 좌표와 크기는 저장되고, 재접속 후에는 잠긴 상태로 시작합니다. 잠긴 프레임과 중앙 경고는 마우스 입력을 가로채지 않습니다.

## 6. 가로 / 세로 / HUD형

| 형태 | 구현 |
|---|---|
| 가로 | 일반 StatusBar, 실제 최대값과 현재값 적용 |
| 세로 | VERTICAL StatusBar, ReverseFill로 두 채우는 방향 지원 |
| HUD | 한쪽당 32개 조각을 곡선 좌표에 배치해 아치형 세로 게이지 구성 |

가로·세로에서는 활성 타이머를 세로로 쌓고 텍스트 공간을 확보합니다. HUD에서 한 개는 왼쪽, 두 개는 좌우를 사용하며, 세 번째는 아래쪽 보조 텍스트로 표시합니다. 좌우 텍스트는 바깥 방향으로 배치하여 작은 간격에서도 서로 겹치지 않도록 했습니다.

표시 우선순위는 CRITICAL 먼저, 같은 조건에서는 BREATH → EXHAUSTION → FEIGNDEATH입니다. 모든 HUD 요소는 단일 상위 프레임을 통해 함께 이동합니다. 가로·세로의 배율과 별도로 HUD는 전체 크기 설정을 사용합니다.

## 7. 상태 판정

다음 순서로 판정합니다.

1. 남은 밀리초 ÷ 1000 ≤ 긴급 초: **CRITICAL**, 기본 10초.
2. 현재값 ÷ 최대값 × 100 ≤ 위험 %: **DANGER**, 기본 25%.
3. 같은 퍼센트 ≤ 주의 %: **CAUTION**, 기본 50%.
4. 나머지: **NORMAL**.

긴급은 모든 퍼센트 조건보다 우선합니다. 예를 들어 최대값 12초인 타이머가 9초 남으면 75%여도 긴급입니다. 위험 임계값은 주의 임계값보다 낮도록 보정합니다.

긴급 경고음은 한 번의 활성 기간에 최초 한 번 재생합니다. 시간이 회복되었다가 다시 긴급해져도 STOP 전에 반복하지 않습니다. STOP 후 다시 시작한 타이머는 다시 재생할 수 있습니다. 중앙 경고와 음향은 독립적으로 끌 수 있습니다.

## 8. 테스트 결과

**Lua 5.1 실행 환경에서 자동 테스트 24개 통과. 전체 Lua 파일 60개 문법 검사 통과.** WoW 프레임·API는 모의 객체로 제공했으며, 실제 공통 UI 코드와 프로필 함수, 공개 Blizzard Classic Mirror Timer 원본 코드를 함께 실행한 검증을 포함합니다.

| 요청 테스트 | 모의 검증 결과 | 실기 상태 |
|---|---|---|
| 1 OFF 시 기본 UI | 통과, 투명도·입력 상태 유지 | 미실행 |
| 2 ON + BREATH 시작 | 통과, KHQOL 표시 및 선택적 대체 | 실제 입수 미실행 |
| 3 BREATH 종료 | 통과, 숨김 및 업데이트 제거 | 미실행 |
| 4 다른 호흡 최대값 | 통과, 180초 최대값 / 126초 / 70% 검증 | 종족·버프 조건 미실행 |
| 5 주의 50% | 통과, 경계값 검증 | 시각 확인 미실행 |
| 6 위험 25% | 통과, 상태·애니메이션 선택 검증 | 시각 확인 미실행 |
| 7 긴급 10초 | 통과, 중앙 경고·음향 호출 1회·재시작 검증 | 화면·실제 음향 미실행 |
| 8 가로형 | 통과, 폭·높이·좌표·배율·투명도 검증 | 시각 확인 미실행 |
| 9 세로형 | 통과, 두 방향 검증 | 시각 확인 미실행 |
| 10 HUD형 | 통과, 곡선 좌표·두께·좌우 배치 검증 | 시각 확인 미실행 |
| 11 드래그 / 저장 | 통과, 드래그 좌표·DB 재조회·프로필 저장 검증 | 실제 /reload 미실행 |
| 12 FEIGNDEATH | 통과, 미지원 DEATH 보존 및 슬롯 재사용 검증 | 실제 스킬 미실행 |
| 13 동시 타이머 | 통과, 스택·좌우·보조 텍스트·긴급 우선순위 검증 | 실제 동시 발생 미실행 |
| 14 OFF 시 복원 | 통과, 활성 기본 타이머 즉시 복원 검증 | 미실행 |

추가 검증: 종류별 OFF, 숫자·불리언 PAUSE, 회복 및 보간, 텍스트 5종과 개별 옵션, 잘못된 최대값의 기본 UI 유지, 프레임 재사용, 유휴 상태 갱신 제거, 설정 유지, 실제 공통 UI 생성 및 비활성 처리, 공개 Classic 코드의 슬롯 보존·복원, 실제 프로필 캡처/불러오기와 이전 프로필의 새 항목 보충.

최종 설치 ZIP에는 테스트 실행용 라이브러리나 임시 파일을 넣지 않았습니다. 자동 테스트의 상세 결과는 별도 `KHQOL-1.9.8-test-results.json`에 제공합니다.

## 9. Forever API 차이 / 제한 사항

제공된 파일에는 Forever의 Mirror Timer FrameXML이나 실행 가능한 게임 클라이언트가 없어, Forever 전용 API 차이를 실측했다고 보고할 수는 없습니다. 기존 TOC의 Interface 16001을 유지했습니다.

호환 처리는 숫자 또는 불리언 paused, 종류별 PAUSE 또는 숫자 하나의 전체 PAUSE, Classic 전역 프레임 및 현대형 컨테이너 구조를 고려했습니다. 기본 프레임의 이름·타이머 식별 필드가 Forever에서 다르다면 해당 환경에서 추가 조정이 필요할 수 있습니다.

출시 전 게임 내에서 수중 호흡, 피로도, 실제 죽은척 하기, 전투 중 전환, 화면 배율별 표시, 드래그 후 /reload, 다른 애드온과 함께 사용하는 기본 타이머 복원을 확인해야 합니다. 모의 테스트 통과만으로 “Forever에서 충돌 없음”이나 “모든 기존 기능 회귀 없음”을 확정하지 않았습니다.

검증에 참고한 공개 원본: [Classic MirrorTimer.lua](https://github.com/Gethe/wow-ui-source/blob/classic/Interface/AddOns/Blizzard_FrameXML/Classic/MirrorTimer.lua), [Mirror Timer API 문서](https://github.com/Gethe/wow-ui-source/blob/classic/Interface/AddOns/Blizzard_APIDocumentationGenerated/MirrorTimerDocumentation.lua), [현대형 MirrorTimer.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_MirrorTimer/Mainline/MirrorTimer.lua).
