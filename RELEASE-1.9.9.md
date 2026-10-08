# KHQOL 1.9.9 — Navigation Engine 분리 보고서

기준: 사용자가 제공한 **KHQOL-1.9.8.8.zip**. 결과: **1.9.9**. 작성: 2026-10-08 (한국 시간).

이번 변경은 기존 Quest Navigator를 공용 Navigation Engine과 Navigation UI를 사용하는 Source로 분리하는 작업입니다. 새로운 사용자 기능, 설정 페이지, Source 연동은 추가하지 않았습니다. 실제 Forever 클라이언트를 실행한 검증은 하지 않았으며, 아래 PASS는 정적·모의 검사 결과입니다.

## 1. 구현 전에 조사한 파일

| 파일 | 확인한 역할 |
| --- | --- |
| `Bootstrap.lua` | KHQOL 모듈 테이블, 버전, 기본값 병합 도구 |
| `KHQOL.toc` | SavedVariables 선언과 실제 파일 로딩 순서 |
| 루트 `Core.lua` | 로그인 초기화, 모듈 활성화, `/kh quest` 명령 진입 |
| `Profiles.lua` | 저장값 복사·기존 하위 테이블 보존, 프로필 적용, 드래그 종료 |
| `QuestNavigator/Core.lua` | DB 보정, 이벤트, 0.10초 합치기, OnUpdate, 디버그 |
| `QuestNavigator/Tracker.lua` | 자체 퀘스트 목록 UI, 추적 집합, 목표·반납 위치, 난이도, 자동 선택, 완료 상태 |
| `QuestNavigator/Arrow.lua` | 플레이어 위치, 지도 크기, 거리, 상대 각도, 보간 |
| `QuestNavigator/UI.lua` | 기존 HUD 프레임, 입체 화살표, 텍스트, 위치·크기·투명도 |
| `QuestNavigator/Settings.lua` | 퀘스트 목록·완료 동작·화살표·단위·위치·주기 설정 |
| 루트 `UI.lua`, `SettingsUI.lua`, `DESIGN.md` | 공통 UI Component, 설정 진입 및 배치 규칙 |
| `PositionEditor.lua`, `PositionTargets.lua` | HUD 프레임 연결, 위치 저장·잠금·취소·미리보기 |

동일 역할의 기존 공용 Navigation Engine은 없었습니다. 따라서 공용 런타임 파일을 **두 개만** 추가했습니다. 기존 Quest Navigator의 퀘스트 목록 UI는 화살표 HUD와 별도 기능이므로 그대로 남겼습니다.

## 2. 기존 동작 흐름

`Core:OnEvent` → dirty 표시 → `Core:OnUpdate`에서 0.10초 합치기 → `RefreshQuest` 또는 `RefreshWaypoint` → `GetTrackedQuest` / 실제 완료 상태 → `GetWaypoint` 또는 `GetTurnInWaypoint` → targetMapID/X/Y 저장 → `Arrow:UpdateNavigation` → `ReadPlayerPosition` / `ReadMapSize` / `GetPlayerFacing` → 지도 크기를 반영한 거리와 상대 방향 → `SmoothAngle` → `UI:RotateTexture` / `RenderDistance` / `Render`.

완료 후 다음 퀘스트를 선택하는 시점에는 `FindClosestQuest`가 추적된 ID만 확인했습니다. 양수 네이티브 거리와 같은 대륙 판정, 미완료·미제거 조건을 통과한 후보에 대해 **초록(회색 포함) → 노랑 → 주황 → 빨강 → 던전** 순위를 비교했습니다. 같은 지역 옵션은 같은 난이도 안에서만 적용하고, 이후 거리와 숫자 QuestID로 동률을 결정했습니다. 단순 최단거리 선택으로 바꾸지 않았습니다.

## 3. Navigation으로 이동한 코드

`KHQOL.Navigation` (`Navigation.lua`):

- Source별 후보 스냅샷: `RegisterSource`, `SetSourceDestinations`, `GetSourceDestinations`.
- 현재 안내 대상의 단일 상태: `SetActiveDestination`, `GetActiveDestination`, `Clear`.
- `GetPlayerPosition`, `ReadMapSize`, `InvalidateMap`: 기존 지도 API와 크기 캐시.
- `GetDistance`, `GetOffset`, `GetDirection`, `GetRelativeDirection`: 지도 크기를 적용한 계산.
- `Direction`, `Normalize`, `SmoothAngle`, `Refresh`: 기존 축 방향, 최단각 보간, 0거리 처리.
- `GetNearestDestination`: 난이도에 대응하는 일반 priority 값, 선택적인 같은 지도 우선, 네이티브 제곱거리, ID 순서의 비교.

`KHQOL.NavigationUI` (`NavigationUI.lua`):

- 원래 `CreateHUD`, `ApplyLayout`, `SavePosition`, `ResetPosition`, `RotateTexture`, `RenderArrow`, `RenderDistance`, `Render`.
- `Update` / `UpdateDriver`: 유일한 안내 OnUpdate 소유자.
- `Schedule`: Source 이벤트를 기존 주기로 합치는 일반 콜백 예약. 프레임마다 Source 함수를 호출하지 않습니다.
- `BeginTransition`, `CancelTransition`, `FadeIn`: 완료 표시의 유지·페이드 시간과 알파 처리. 종료 때 Source 콜백을 한 번 호출합니다.

공용 두 파일은 `C_QuestLog`, `C_SuperTrack`, Quest Navigator 모듈 및 다른 모듈 DB를 참조하지 않습니다. 기존 미디어 경로와 공개 프레임명에 남은 QuestNavigator 문자열은 리소스·호환 이름이며 데이터 의존성이 아닙니다.

## 4. Quest Navigator에 남긴 코드

퀘스트 추적 집합과 watch 이벤트 보정, Quest API 조회, 진행도 문구, 난이도·던전 판정, ReadyForTurnIn 우선 판정, waypoint/지도 waypoint/동일 퀘스트 POI 폴백, 반납 위치의 이전 목표 좌표 거부, 실제 반납·포기·수동 선택 정책, SuperTrack 읽기·쓰기, 퀘스트 목록 UI와 설정을 유지했습니다.

새 `PublishCandidates`가 자동 선택 가능한 Quest 데이터를 Destination으로 변환합니다. 네이티브 `GetDistanceSqToQuest`는 QuestID가 필요한 API이므로 Source에 남기고, 그 **결과값**을 공용 비교기에 전달합니다. Engine은 이를 계산 가능한 일반 거리 힌트로만 취급합니다.

`FindClosestQuest`는 후보 갱신 후 `Navigation:GetNearestDestination("Quest", ...)`의 결과 ID를 반환하는 얇은 어댑터입니다. 수동·게임 SuperTrack 선택은 `AdoptQuest` / `PublishActive`가 Destination으로 변환합니다. 현재 네이티브 퀘스트의 완료·반납·포기를 판별하기 위한 `selectedQuestID`는 Source에 남지만, 화살표가 참조하는 지도/좌표/거리/각도는 Source에 중복 저장하지 않습니다.

## 5. 신규·변경 파일과 로딩 순서

| 구분 | 파일 | 변경 |
| --- | --- | --- |
| 신규 | `Navigation.lua` | 후보·선택·좌표·거리·방향 |
| 신규 | `NavigationUI.lua` | 기존 HUD와 표시 갱신 |
| 변경 | `QuestNavigator/Core.lua` | 이벤트 Source와 설정 유지, OnUpdate 제거, 공용 표시 연결 |
| 변경 | `QuestNavigator/Tracker.lua` | 후보와 현재 안내의 Destination 변환, 비교기 호출 |
| 변경 | `QuestNavigator/UI.lua` | 기존 설정/위치 편집 진입점을 유지하는 작은 어댑터 |
| 이동·제거 | `QuestNavigator/Arrow.lua` | 공용 Engine으로 이동해 파일·TOC 항목 제거 |
| 변경 | `Profiles.lua` | 프로필 변경 전에 공용 UI 드래그 위치 저장 1줄 추가 |
| 변경 | `KHQOL.toc`, `Bootstrap.lua` | 새 로딩 순서와 1.9.9 버전 |
| 문서 | `README.md`, `CHANGELOG.md`, `QuestNavigator/README.md`, `RELEASE-1.9.9.md` | 이번 구조·검증·확장 지점 설명 |

관련 로딩 순서: 기존 Bootstrap/Profiles/공통 UI 및 다른 모듈 → **Navigation.lua → NavigationUI.lua** → Quest Navigator Core/Tracker/UI/Settings → 기존 루트 Core/위치 편집기/설정창. 공용 객체를 Quest Navigator보다 먼저 만듭니다.

퀘스트 목록 UI 부분, `QuestNavigator/Settings.lua`, 루트 공통 UI·설정창·위치 편집기, 미디어·폰트와 관련 없는 모듈 코드는 바이트 비교로 보존을 확인했습니다.

## 6. SavedVariables 호환

SavedVariables / SavedVariablesPerCharacter 선언을 그대로 유지했습니다. 새 DB나 마이그레이션 키를 만들지 않았습니다. `KHQOLDB.modules.questNavigator`와 그 `questTracker` 테이블을 계속 사용합니다. 공용 UI는 전달받은 기존 DB 테이블을 읽고 위치를 같은 키에 저장합니다.

화살표 표시 기본값은 공용 UI에서 정의하고 Quest Navigator의 기존 defaults 모양에 병합합니다. 퀘스트 완료 정책·진행도 설정은 Source defaults에 남겼습니다. 기존 completionBehavior 이전 정책과 잘못된 저장값 보정도 유지합니다.

후보·활성 목적지·좌표·각도·타이머는 런타임 객체뿐이며 SavedVariables에 저장되지 않습니다. 프로필 저장·로드와 설정창이 닫아 둔 기존 테이블 참조도 유지합니다. `/reload`는 기존 SuperTrack 선택과 저장 설정으로 안내를 복원합니다.

## 7. Quest 이벤트 흐름 변경

이벤트 이름·등록 조건과 퀘스트 의미 처리는 기존 Core에 남습니다. 주요 이벤트는 watch 캐시를 dirty 처리하고, Navigation UI의 일반 작업 예약에 0.10초 콜백 하나를 넣습니다. 같은 기간의 이벤트는 하나로 합칩니다. 콜백에서 Source가 후보를 `SetSourceDestinations("Quest", destinations)`로 교체하고 선택된 퀘스트의 최신 위치를 `SetActiveDestination`으로 전달합니다.

추적 해제·제거 이벤트는 후보 스냅샷에서도 해당 ID를 즉시 제거합니다. 자동 선택 직전에는 watch와 후보를 새로 확인합니다. 자동 선택 OFF에서는 자동 후보 계산을 생략하며 수동 안내는 유지합니다. 현재 안내 중인 퀘스트는 활성 Destination으로 별도 전달하므로, 이벤트 후보 갱신에서 이를 제외해 불필요한 후보 조회를 줄입니다.

경로 이벤트는 이전처럼 완료 상태를 다시 판정하지 않고 캐시된 완료 상태에 맞는 현재 위치만 갱신합니다. 반납/포기/중복 이벤트, 전환 중 수동 퀘스트·사용자 핀 선택, SuperTrack 쓰기 실패를 기존 정책대로 처리합니다.

## 8. Arrow 업데이트 흐름 변경

`NavigationUI:Update` → 기존 arrow/distance 주기 확인 → `Navigation:Refresh` → 기존 좌표·지도 크기·facing 계산 → `NavigationUI:RotateTexture`와 텍스트 표시 순서입니다. 기본 0.10초/0.25초와 사용자 저장 주기를 유지합니다.

UI에 항상 표시 상태인 작은 드라이버 프레임을 두고 HUD 표시와 분리했습니다. WoW에서는 숨겨진 프레임의 OnUpdate가 멈추므로, 안내 대상이 없어 HUD가 숨겨져 있을 때도 예약된 Source 이벤트를 처리할 수 있어야 합니다. 작업·목적지·전환이 없으면 드라이버 OnUpdate를 해제하고, 모듈 OFF는 예약과 갱신을 중단합니다.

평상시 매 프레임 Quest API나 후보·난이도 조회를 하지 않습니다. 이번에는 이벤트 시 후보 스냅샷을 제공하므로 자동 선택 ON의 주요 퀘스트 이벤트에서 기존보다 후보 조회가 추가될 수 있습니다. 추적 ID에만 한정하고 0.10초 단위로 합치며, 후보 비교는 1회 순회, POI 폴백 조회표는 필요할 때 한 번 만듭니다. 실제 FPS·CPU 사용량은 측정하지 않았습니다.

## 9. 회귀 위험과 처리

- **선택 규칙**: priority → 같은 지도 옵션 → 네이티브 제곱거리 → ID 비교를 보존했습니다. 다른 지도 후보의 비교는 네이티브 거리 힌트를 사용합니다.
- **지도·동굴·실내**: 기존처럼 화살표 계산은 플레이어와 목적지 지도 ID가 같고 실제 지도 크기를 읽을 수 있을 때만 합니다. 부모/서브맵을 임의로 합치거나 새 경로를 추측하지 않습니다.
- **완료 타이밍**: 0.85초 유지, 0.15초 페이드와 수동 선택 우선 동작을 보존했습니다. UI는 콜백만 실행하고 Quest 의미를 해석하지 않습니다.
- **정보 없음**: 좌표가 없는 Destination은 제목·진행·상태 표시만 유지합니다. (0,0) 같은 가짜 좌표를 넣지 않습니다. 이전 목표와 같은 반납 좌표를 거부하는 기존 정책도 유지합니다.
- **HUD 외형**: 원래 프레임 크기·폰트·텍스트 위치·투영 UV·입체 옆면·그림자·색상·알파·거리 반올림을 옮겼습니다. 미디어 파일은 변경하지 않았습니다.
- **위치·프로필**: `QN.root`와 레이아웃 진입점을 호환 어댑터로 유지했습니다. 공용 UI 드래그를 옛 프로필 DB에 저장한 뒤 새 프로필을 적용합니다.
- **후보 교체와 수동 초점**: Source 후보 목록 교체만으로 활성 수동 목적지를 탈취하지 않습니다. 자동 선택 시점은 기존 Quest 정책이 요청하고, 비교·선정은 Engine이 수행합니다.

## 10. 실제 실행한 검사와 게임 확인 항목

**PASS: 총 155개 검사 항목** — 안내·공용 Source 115, 최신 퀘스트 목록 35, 전체 로딩·설정·저장·프로필 통합 5. 전체 **63개 Lua 파일을 Lua 5.1로 파싱**하고 TOC 참조 경로를 확인했습니다. 배포 ZIP의 CRC와 압축 해제 내용도 원본 소스와 대조합니다.

검사에는 원래 방향/캐릭터 회전/최단각 보간/사각 지도/0거리/입체 투영/단위/진행 문구/난이도 순위/완료·반납·포기/수동 선택/보호·누락 값/OFF·업데이트 주기와 이벤트 폭주가 포함됩니다. 위치 이동·회전·단위·설정·완료 페이드·다른 지도·복구·SuperTrack 실패는 **수정하지 않은 1.9.8.8과 같은 입력에 대한 표시·상태·좌표·각도 비교**도 통과했습니다.

기존 Quest API와 Quest Navigator·모듈 DB를 제거한 모의 환경에서 일반 Destination의 최근접 선택, 거리·회전·제목 표시, Source 분리·교체를 확인했습니다. 최신 퀘스트 목록은 native 메서드/부모/공유 데이터 불변, 접기·정렬·아이템 버튼·스크롤·편집 모드·전투 지연과 1.9.8.8 헤더 장식 처리를 확인했습니다. 실제 TOC/로그인 경로의 14개 설정 페이지와 기존 277개 Builder 옵션, 저장 DB 비교도 통과했습니다.

실제 Forever 게임에서 다음 항목은 **NEEDS TEST**입니다:

1. 모듈 ON/OFF, 추적 변경, waypoint·퀘스트 POI 인식, 제목·진행도.
2. 이동/좌우·180도 회전, 화살표 눕힘·입체 옆면, 야드/미터와 저장 주기.
3. 두 완료 정책, 실제 반납 후 다음 추적 후보, 던전·난이도·같은 지역 우선.
4. 지도/지역/실내/동굴 전환, 좌표 없음·잘못된 지도에서 숨김과 복구.
5. 드래그·위치 편집 완료/취소·프로필 전환·`/reload` 뒤 위치/크기/설정 유지.
6. 전투 중 퀘스트 목록·아이템 버튼, 게임 지도 열기/닫기, 편집 모드와 실제 taint/Lua 오류 여부.

모의 검사는 게임의 보안 엔진, 실제 지도 데이터, 프레임 렌더링과 폰트·전투 중 아이템 사용을 재현하지 않습니다. 실게임에서 기능 100% 동일함을 확인했다고 주장하지 않습니다.

## 11. 이후 Forever Note를 연결할 지점

아직 Forever Note와 WeaponGuide를 연결하지 않았습니다. 추후 해당 모듈이 자기 데이터/API를 읽어 아래 기본 구조의 배열을 만들고 `Navigation:SetSourceDestinations(source, destinations)`에 전달하면 됩니다.

```lua
{source="FutureSource", id="entry-id", mapID=mapID, x=x, y=y, label=label}
```

좌표는 0~1 정규화 값입니다. 숫자 또는 문자열 ID를 지원합니다. 일반 목적지는 metadata 없이 계산·표시할 수 있습니다. 필요하면 `metadata.navigation.priority`와 검증된 `distanceSq` 힌트를 제공할 수 있습니다. Quest 고유 metadata는 Engine/UI가 읽지 않습니다.

연결 순서: Source 스냅샷 전달 → `GetNearestDestination(source)` 또는 Source에서 명시한 목적지 요청 → `SetActiveDestination(destination)` → `NavigationUI:Configure(기존_소유_DB, 일반_표시_데이터)` → `SetEnabled(true)` → `Refresh(true,true)` / `Render`. 이후 위치·방향 표시 갱신은 공용 UI가 담당합니다. Source 데이터 변경은 해당 Source의 이벤트가 책임집니다. 후보 목록은 교체 방식이고 읽은 스냅샷은 직접 수정하지 않는 계약입니다.

이번 버전의 실제 운영 Source는 Quest 하나이고 공용 활성 목적지와 HUD도 하나입니다. 여러 Source를 동시에 활성화할 때의 선택권·활성화 수명 조정은 실제 연동 단계에서 정해야 합니다. Source Priority UI, MANUAL/AUTO 전환 UI, Note/WeaponGuide 연동 및 경로 탐색은 이번 결과물에 구현하지 않았습니다.

## 설치

게임을 종료하거나 애드온을 갱신한 뒤 ZIP의 `KHQOL` 폴더를 기존 AddOns의 KHQOL에 덮어쓰고 `/reload` 하세요. SavedVariables를 삭제할 필요는 없습니다. 기존 폴더에 예전 `QuestNavigator/Arrow.lua`가 남아 있어도 새 TOC에서 로드하지 않습니다.
