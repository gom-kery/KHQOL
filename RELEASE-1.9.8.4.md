# KHQOL 1.9.8.4

기본 경험치 바 숨김을 켜도 바가 남아 있는 문제를 수정하고, 커스텀 경험치 바에 10% 구분선 9개를 추가했습니다. 수정본의 패키지명과 애드온 내부 버전 표기를 **1.9.8.4**로 변경했습니다. 설치 ZIP은 `KHQOL-1.9.8.4.zip`입니다.

## 기본 경험치 바 숨김 수정

기존 코드는 이름이 있는 경험치 프레임과 컨테이너의 `ExperienceBar` 필드만 탐색했습니다. 공개 Classic UI 소스에서는 실제 경험치 바가 이름 없는 프레임으로 생성되어 `barContainers` 내부의 `bars[StatusTrackingBarInfo.BarsEnum.Experience]`에 저장됩니다. 이 구조가 누락되어 있었습니다.

원래 배포한 1.9.8.3 코드를 이 구조의 모의 환경에서 실행해, 숨김 ON인데도 경험치 바와 공유 테두리가 남는 문제를 재현했습니다. 수정본은 다음 경로도 탐색합니다.

- 관리자의 `barContainers` 목록과 각 컨테이너의 `bars` 목록.
- Experience enum 또는 Blizzard ExpBarMixin으로 식별한 경험치 프레임.
- 제공되는 경우 `GetBarFromTemplate("ExpStatusBarTemplate")`.

경험치 프레임과 자식의 표시·입력을 제어합니다. 컨테이너 자체와 평판 바는 숨기지 않습니다. 컨테이너의 공용 테두리는 현재 표시 대상이 경험치일 때만 투명하게 만들고, 평판으로 전환되면 원래 상태를 복원합니다. 바 전환·초기화·재표시 시에도 다시 적용하며 상시 OnUpdate를 추가하지 않았습니다.

커스텀 바 사용과 기본 바 숨김은 계속 독립적입니다. 숨김 OFF 시 기록한 투명도와 입력 상태만 복원하고 기본 프레임을 강제로 Show하지 않습니다.

참고 원본: [Classic StatusTrackingManagerOverrides.lua](https://github.com/Gethe/wow-ui-source/blob/classic/Interface/AddOns/Blizzard_ActionBar/Classic/StatusTrackingManagerOverrides.lua), [Shared StatusTrackingManager.lua](https://github.com/Gethe/wow-ui-source/blob/classic/Interface/AddOns/Blizzard_ActionBar/Shared/StatusTrackingManager.lua), [Classic StatusTrackingBar.xml](https://github.com/Gethe/wow-ui-source/blob/classic/Interface/AddOns/Blizzard_ActionBar/Classic/StatusTrackingBar.xml).

## 경험치 구분선

- 10%, 20%, …, 90% 위치에 불투명 구분선 9개를 표시합니다.
- 가로형은 바 폭을 열 개의 같은 길이로 나눕니다.
- 감싸기 모드에서는 세로+가로의 전체 길이를 기준으로 나눕니다. 모서리에서도 진행률 기준을 유지합니다.
- 구분선은 화면 기준 1픽셀 두께이며 폭·높이·배율 변경 시 위치를 다시 계산합니다.
- XP·휴식 XP 채움 위, **경험치 텍스트 아래의 별도 레이어**에 배치합니다. 선이 텍스트를 덮지 않습니다.
- 구분선은 한 번 생성해 재사용하며 마우스 입력을 가로채지 않습니다.

## 변경 범위와 검증

이전 1.9.8.3 설치 ZIP과 비교하여 기능 코드 변경은 `Modules/ExperienceBar.lua` 한 파일입니다. SavedVariables 구조와 기존 설정값, 환경 타이머, 바 설정 UI 및 다른 모듈은 유지합니다. ZIP에 이 수정 내역을 `RELEASE-1.9.8.4.md`로 추가했습니다.

**Lua 5.1 모의 테스트 28개 통과, 전체 Lua 파일 62개 문법 검사 통과.** 기존 경험치·프로필·환경 타이머 검증에 다음 항목을 추가했습니다.

| 검증 | 결과 |
|---|---|
| 두 컨테이너의 이름 없는 경험치 바 탐색·숨김 | 통과 |
| 컨테이너와 평판 바 표시 보존 | 통과 |
| 공개 Blizzard의 실제 `ApplyPendingBarToShow` 함수 실행 후 경험치↔평판 전환 시 테두리 숨김·복원 | 통과 |
| 기본 바 숨김 OFF 및 커스텀 OFF의 독립성 | 통과 |
| 늦게 초기화된 경험치 프레임 탐색 | 통과 |
| 9개 구분선의 불투명도·10% 좌표·픽셀 두께·텍스트 아래 레이어 | 통과 |
| 위/아래 감싸기에서 모서리를 넘는 구분선 좌표 | 통과 |
| 크기 변경 시 재배치, XP 갱신 중 프레임 재생성 없음 | 통과 |

실제 Forever 클라이언트에서 화면과 기본 바 숨김을 직접 실행 검증하지는 못했습니다. 위 결과는 API·프레임 모의 객체와 공개 Blizzard 코드로 수행한 검증입니다.

## 적용

게임을 종료하고 ZIP 안의 `KHQOL` 폴더를 기존 `Interface/AddOns/KHQOL`에 덮어쓴 뒤 접속하거나, 파일 교체 후 `/reload`하세요. SavedVariables를 삭제할 필요는 없습니다. **바 설정 → 경험치 → Blizzard 기본 경험치 바 숨김**이 ON이면 새 탐색 경로가 적용됩니다.
