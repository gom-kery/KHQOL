# KHQOL 1.8.7 — Quest Navigator 난이도 우선 추적

2026-10-06 · Quest Navigator v0.1.5

기준본: 사용자가 지정한 **KHQOL-1.8.6-CompactGeneralUI.zip**.

완료 후 다음 퀘스트를 자동 선택할 때 거리보다 난이도 순위를 먼저 비교합니다.

| 순위 | 퀘스트 |
| --- | --- |
| 1 | 초록색 (회색 포함) |
| 2 | 노란색 |
| 3 | 주황색 |
| 4 | 빨간색 |
| 5 | 던전 퀘스트 (일반·영웅 태그) |

같은 순위에서는 가까운 퀘스트가 우선이며, 거리까지 같으면 퀘스트 ID가 작은 쪽을 선택합니다. 예를 들어 주황 퀘스트가 50야드, 노란 퀘스트가 200야드 떨어져 있으면 노란 퀘스트를 먼저 선택합니다. 던전 퀘스트는 제목이 초록이어도 5순위입니다. 순위가 낮은 퀘스트를 제외하지는 않으므로 다른 후보가 없으면 선택됩니다.

`같은 지역 퀘스트 우선`을 켠 경우에는 **난이도 → 같은 지역 → 거리 → ID** 순서입니다. 기본 설정에서는 난이도 → 거리 → ID입니다. 수동으로 선택한 퀘스트는 난이도와 관계없이 안내하며, 현재 목표를 임의로 바꾸지 않습니다. 레벨이 오르면 다음 자동 선택 시점에 난이도를 다시 읽습니다.

난이도는 기본 목표 추적기가 제목 색상을 정할 때 사용하는 C_PlayerInfo.GetContentDifficultyQuestForPlayer와 Enum.RelativeContentDifficulty를 우선 사용합니다. 읽을 수 없으면 퀘스트 difficultyLevel / GetQuestDifficultyLevel / level 순으로 레벨을 얻고 GetQuestDifficultyColor의 게임 색상을 사용합니다. 색상 함수도 사용할 수 없으면 캐릭터 유효 레벨(없으면 UnitLevel)과 비교합니다: +3~4는 주황, +5 이상은 빨강입니다. 회색은 사용자가 지정한 목록에 없으므로 초록과 같은 쉬운 순위로 취급합니다. 난이도 정보를 모두 읽을 수 없는 퀘스트는 일반 순위(2)에서 거리로 비교합니다.

던전 여부는 C_QuestLog.GetQuestTagInfo의 Dungeon / Heroic 태그로 판단합니다. 단순 그룹 퀘스트를 던전으로 간주하지 않으며, 퀘스트 이름이나 현지화된 문구를 추측하지 않습니다.

기존 완료 후 후보 탐색 한 번에 순위 비교를 추가했습니다. 퀘스트 목록은 한 번만 순회하고 정렬하거나 목록 행을 선택/펼치지 않습니다. 평상시 화살표·거리 갱신에서는 난이도·던전·레벨을 조회하지 않습니다. 새 타이머와 저장 옵션은 추가하지 않았습니다. 자동 선택 OFF와 모듈 OFF 동작은 유지합니다.

설치: ZIP 내부의 KHQOL 폴더를 기존 Interface/AddOns/KHQOL에 덮어쓰고 `/reload`합니다. SavedVariables를 삭제할 필요가 없습니다. `/kh quest`의 추적 영역에 우선순위 설명이 추가됩니다. 기존 눕혀진 입체 화살표, 야드·미터, 진행도 중복 수정, 지도 마크 폴백과 1.8.6의 PvP Alert/Threat/설정 간격을 보존했습니다.

검증: 퀘스트·화살표 **76/76 모의 검사 PASS**, 전체 55개 Lua 5.1 문법 및 TOC 경로 PASS. 신규 검사에는 5단계 우선순위, +2/+3/+4/+5 경계, 색상과 레벨 폴백, 회색, 일반·영웅 던전, 같은 지역 옵션, 거리·ID 동률, 레벨 상승, 자동 전환/수동 선택, 데이터 누락/오류/보호 값, 단일 순회와 평상시/OFF 무조회가 포함됩니다. 실제 1.8.6 공통 UI를 사용한 13개 모듈 메뉴/간격/토글, Quest Navigator 설정/스크롤/영역 재사용도 PASS입니다. 실제 게임에서 이번 자동 선택 동작과 렌더링은 아직 확인하지 못했습니다.

공개 게임 UI 소스 확인:

- [목표 추적기의 제목 처리](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_ObjectiveTracker/Blizzard_QuestObjectiveTracker.lua)
- [난이도 색상과 +3/+5 경계](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_FrameXMLUtil/Mainline/DifficultyUtil.lua)
- [퀘스트 난이도·던전 태그 API](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua)
- [캐릭터 기준 퀘스트 난이도 API](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/PlayerInfoDocumentation.lua)

---

아래는 1.7.x의 최초 구현·수정 기록입니다. 이번 배포의 기준본과 변경 사항은 위 1.8.7 설명을 따릅니다.

# Quest Navigator v0.1.4 — 구현 및 검증 보고서

2026-10-06 · KHQOL 1.7.4

최종 베이스는 사용자가 변경 지정한 **KHQOL-1.6.6-HunterRangeFallback.zip**입니다. 기존 사냥꾼 사거리 폴백을 포함한 기존 모듈 구현과 미디어를 보존하고, Quest Navigator만 추가했습니다.

구현 및 모의 검증을 완료했습니다. 실제 WoW Forever 클라이언트에서의 실행, FPS/CPU 측정, 화면 렌더링과 저장 파일 복원은 아직 확인하지 않았습니다. 아래 PASS는 Lua 5.1 모의 환경의 결과입니다.

## 1.7.4 두께가 있는 입체 화살표

금색 윗면 아래에 어두운 금색 옆면과 그림자를 추가했습니다. 새 리소스 ArrowSide.tga는 128×128 RGBA의 흰색 화살표 마스크입니다. 방향에 따라 윗면·옆면·그림자를 같은 UV로 회전하고, 옆면은 화면 아래쪽으로 쌓아 두께가 있는 판처럼 표현합니다. 텍스처로 구현한 입체 HUD이며 별도의 M2 모델은 사용하지 않습니다.

기존 눕힘 각도를 그대로 사용합니다. 기본 55°, 범위 0~70°이며 0°에서는 옆면과 그림자를 숨겨 평면 모양으로 돌아갑니다. 옆면 두께는 화살표 크기×0.14×sin(눕힘 각도)입니다. 크기가 커지면 두께도 비례합니다. 거리와 제목은 입체 화살표 아래쪽으로 배치해 겹치지 않게 했습니다. 저장 위치, 투명도, 야드·미터 선택과 방향 계산은 유지합니다.

옆면용 영역 18개와 그림자 1개를 처음 한 번만 생성해 재사용합니다. 기본 크기·각도에서는 옆면 8개, 최대 크기·각도에서는 17개를 표시합니다. 기존 0.10초 회전 주기를 공유하며 새 타이머, 퀘스트 조회 또는 지도 조회를 추가하지 않습니다. OFF에서는 갱신이 완전히 해제됩니다. [Forever Region API](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleRegionAPIDocumentation.lua)의 SetVertexColor를 사용합니다. 투영 또는 색상 API가 없으면 옆면을 숨기며, 옆면 회전 실패는 유효한 윗면 안내를 막지 않습니다.

0~359° 회전과 여러 눕힘 각도에서 윗면/옆면/그림자 UV 일치, 아래쪽 두께 고정, 0° 복원, 최대 영역 수, 크기·투명도·텍스트 간격, 영역 재사용, API 실패, 60초 갱신 횟수와 OFF 무작업을 검사했습니다. 모의 검사 **61/61 PASS**, 기존 Tooltip/Range/Hunter 및 통합 설정 회귀 검사 PASS입니다. 새 리소스는 RGBA/투명 가장자리/128×128 크기를 확인했습니다. 실제 게임 렌더링과 FPS/CPU는 미확인입니다. 첨부 미리보기는 렌더링 계산으로 만든 예시입니다.

## 1.7.3 화살표 눕힘과 거리 단위

화살표의 평면 회전 후 세로축에 cos(눕힘 각도)를 적용합니다. 회전은 8개 UV 좌표를 통해 처리하므로 화면에서 기울어진 평면은 고정되고 방향표만 평면 위에서 회전합니다. 상하 방향은 짧게, 좌우 방향은 넓게 표시됩니다. 기존 텍스처를 CLAMP로 사용하여 회전 시 투명한 가장자리가 반복되지 않게 합니다. 기존 방향·거리 계산과 최단각 smoothing은 유지합니다.

설정: `/kh quest` → 화살표 → 화살표 눕힘 각도. 기본 55°, 범위 0~70°, 0°는 기존 모양입니다. 회전 UV API가 없으면 기존 사각 영역과 SetRotation으로 폴백합니다. 화살표 폭은 기존 크기 옵션, 세로 높이는 크기×cos(각도)입니다. HUD 높이도 이에 맞추며 저장 위치는 유지합니다. [Forever 텍스처 API](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleTextureBaseAPIDocumentation.lua)와 [8개 UV 사용 예제](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedXMLBase/TextureUtil.lua)를 확인했습니다.

설정: 표시 → 거리 단위에서 야드(yd) / 미터(m) 선택. 기본 야드입니다. 거리 제곱에서 구한 반올림 전 거리에 0.9144를 곱한 뒤 미터 정수로 반올림합니다. 숫자와 단위가 달라질 때만 표시 문자열을 만들며, 단위 변경은 즉시 반영합니다. 거리 없음/안내 불가 문구는 단위와 관계없이 유지합니다.

기존 저장 테이블에 arrowTilt=55, distanceUnit="yards"를 추가합니다. 위치/기존 옵션 및 SavedVariables 선언은 보존합니다. 새 UI는 공통 Slider/Dropdown을 사용합니다. 기존 0.10초 회전/0.25초 거리 갱신을 사용하고 지도 조회나 타이머는 추가하지 않습니다.

투영된 화살표 끝이 실제 방향에 맞는지 0~359°와 눕힘 0/55/70°에서 검사했습니다. 크기·위치·저장값·API 폴백, 야드/미터 즉시 전환·0거리·중복 반올림 방지·문자열 캐시 검사도 추가했습니다. 총 56/56 PASS 및 기존 통합 설정 회귀 PASS입니다. 수정본의 실게임 렌더링은 확인이 필요합니다.

## 1.7.2 목표 진행 숫자 중복 수정

사용자 스냅샷처럼 목표 설명에 이미 `1/8`이 포함된 경우 기존 구현은 뒤쪽 분수만 제거하여 앞쪽 분수를 그대로 두고 숫자를 다시 붙였습니다. 설명의 앞·뒤 진행 분수와 주변 공백/콜론을 정리한 뒤 실제 numFulfilled/numRequired를 한 번만 붙입니다. 예: `1/8 우두머리 초원늑대 이빨` → `우두머리 초원늑대 이빨 1 / 8`.

목표 이름 안의 숫자와 분수는 유지합니다. 숫자만 모드, 수치가 없는 목표의 표시, 대표 미완료 목표 선택과 저장 설정은 유지합니다. 스냅샷 재현 및 실제 표시 문자열, 이벤트 후 숫자 갱신, 앞/뒤/양쪽 분수·공백·콜론, 목표 이름의 숫자, 빈 설명/수치 누락 등 신규 4개 검사를 추가했습니다. 기존 1.7.1의 마크 좌표 폴백과 함께 총 51/51 PASS입니다. 수정 HUD의 실게임 확인은 필요합니다.

## 1.7.1 수정과 사용자 진단

사용자 실게임 진단에서 경로 API 세 가지는 호출에 성공했지만 좌표를 반환하지 않았습니다. 반면 GetQuestsOnMap은 포커스된 퀘스트 759의 x=0.95776301622391, y=0.087666280567646을 반환했습니다. 마크 좌표를 사용할 수 있는데도 기존 HUD가 GetNextWaypoint만 조회하여 “경로 없음”으로 표시하는 경우가 있었습니다.

목적지는 GetNextWaypoint → GetNextWaypointForMap(현재 지도) → GetQuestsOnMap(현재 지도)의 동일 퀘스트 마크 순서로 조회합니다. 숫자/범위/보호 값, 퀘스트 ID와 지도 안내용 마크 여부를 검사합니다. 퀘스트 ID나 좌표는 하드코딩하지 않습니다. 사용자 핀을 생성하거나 WaypointUI의 추적 상태를 변경하지 않습니다.

지역 마크는 퀘스트 수행 지역의 대표점입니다. 개별 몬스터·아이템·목표의 정확한 위치, 장애물을 피하는 이동 경로는 제공하지 않습니다. 원래 경로가 유효하면 계속 우선하며 다른 UI Map 계산도 차단합니다. 경로와 마크 모두 없으면 “경로 없음”입니다.

퀘스트/지도/경로 이벤트에서만 목적지를 갱신하고 좌표만 보관합니다. 같은 지역 우선 검색에서는 한 번 읽은 마크로 임시 조회표를 만든 후 후보를 순회합니다. 평상시 OnUpdate에서는 마크 조회가 없습니다. 디버그 스냅샷의 waypointSource는 waypoint / mapWaypoint / questPOI 중 하나입니다.

사용자의 위 응답을 재현한 검사를 포함해 신규 13개 검사를 추가했으며 총 47/47 PASS입니다. 수정된 HUD의 실게임 실행은 아직 확인하지 않았습니다.

## 설치와 설정 진입

압축 파일 안의 `KHQOL` 폴더를 게임의 `Interface/AddOns`에 설치한 뒤 `/reload`합니다. 기존 KHQOL 설정 파일을 삭제할 필요가 없습니다.

`/kh quest` 또는 `/kh questnavigator`로 설정을 열 수 있습니다. 미니맵의 KHQOL 버튼 → Quest Navigator에서도 접근합니다. 현재 Blizzard Super Tracking에 선택된 퀘스트가 HUD 대상입니다. 단순히 퀘스트 감시 목록에 체크된 여러 퀘스트 가운데 임의로 초기 대상을 고르지 않습니다.

## 1. 생성 파일

| 파일 | 역할 |
| --- | --- |
| QuestNavigator/Core.lua | 기본값, API 경계 방어, 이벤트, 활성화/비활성화, 갱신 드라이버, 디버그 스냅샷 |
| QuestNavigator/Tracker.lua | 추적 대상, 완료 감지, 후보 탐색, 자동 선택, 진행도, 완료 전환 |
| QuestNavigator/Arrow.lua | 위치, 지도 크기, 방향, 상대각, 최단각 보간 |
| QuestNavigator/UI.lua | 독립 HUD, 완료 표시, 드래그, 위치 저장, 거리 문자열 캐시 |
| QuestNavigator/Settings.lua | 공통 컴포넌트 기반 설정 페이지와 접힌 고급 영역 |
| Media/QuestNavigator/Arrow.tga | 북쪽을 향하는 화살표, 128×128 RGBA |
| Media/QuestNavigator/ArrowSide.tga | 입체 옆면/그림자 마스크, 128×128 RGBA |
| Media/QuestNavigator/Check.tga | 완료 체크, 128×128 RGBA |
| QuestNavigator/README.md | 이 보고서 |

모듈 역할을 파일로 분리했으며, 작업을 별도 Unit으로 나누지는 않았습니다. 테스트용 코드와 Lua 런타임은 설치 패키지에 포함하지 않았습니다.

## 2. 수정 파일

- `Bootstrap.lua`: `modules.questNavigator` 등록, KHQOL 버전 1.7.4.
- `Core.lua`: enabled 기본값, 기존 SetEnabled 분기, `/kh quest` 별칭 추가.
- `KHQOL.toc`: 신규 파일 5개를 공통 Core와 SettingsUI 앞에서 로드, 버전 갱신.
- `SettingsUI.lua`: 모듈 탐색 목록에 Quest Navigator 정의 1개 추가.
- `README.md`, `CHANGELOG.md`: 신규 버전 설명 추가.

`UI.lua`, `DESIGN.md`, Range, Tooltip, CastBar, Combat Status, Clock 및 다른 기존 모듈 코드·미디어는 1.6.6 베이스와 동일합니다. 별도의 SavedVariables 선언도 추가하지 않았습니다.

## 3. 등록과 초기화

기존 `KHQOL.modules.questNavigator` 테이블을 사용합니다. KHQOL의 `PLAYER_LOGIN` 처리 후 기존 enabled 순회가 `SetEnabled(true/false)`를 호출합니다. 신규 전역 애드온이나 별도의 로그인 초기화 체계를 만들지 않았습니다.

HUD와 이벤트 프레임은 최초 호출 때 한 번 생성하여 재사용합니다. OFF에서는 모든 모듈 이벤트 등록과 OnUpdate를 해제하고 전환·페이드를 취소합니다. 다시 ON이면 현재 Super Tracking 대상과 데이터를 읽어 복원합니다.

## 4. 전체 동작 흐름

1. 현재 Super Tracking 퀘스트를 HUD에 표시합니다.
2. Quest 상태 이벤트를 0.10초의 고정 debounce 창으로 합칩니다.
3. 현재 퀘스트의 `IsComplete`가 true가 되면 완료 상태를 한 번 시작합니다.
4. 완료 체크와 “목표 완료!”를 0.85초 표시합니다.
5. 0.15초 Fade-out 뒤 미완료 후보를 한 번 순회합니다.
6. 가장 가까운 후보를 공개 SuperTrack API로 선택합니다.
7. 변경 결과를 다시 읽어 실제 Blizzard 대상과 HUD를 일치시킵니다.
8. waypoint와 현재 목표 진행도를 가져와 새 HUD를 0.15초 Fade-in 합니다.
9. 플레이어 위치와 캐릭터 방향에 따라 설정 주기로 화살표와 거리를 갱신합니다.

자동 선택 OFF 또는 후보 없음이면 현재 추적을 유지합니다. 완료 퀘스트가 남아 있으면 완료 표시를 유지하고 지속 갱신은 멈춥니다. 현재 추적이 없으면 IDLE입니다.

전환 중 다른 퀘스트나 사용자 waypoint 등으로 외부 Super Tracking이 바뀌면 해당 선택을 우선하여 자동 전환을 취소합니다. Blizzard가 반납 처리 중 먼저 기존 추적을 해제하는 경우에는 짧은 debounce 동안 이전 ID를 유지하여 반납 이벤트를 놓치지 않도록 했습니다.

## 5. 사용 Quest API

| API | 사용 목적 |
| --- | --- |
| C_QuestLog.IsComplete | 전체 퀘스트 목표 완료 판정 |
| C_QuestLog.IsOnQuest | 포기·반납으로 사라진 현재 대상 확인 |
| C_QuestLog.GetNumQuestLogEntries / GetInfo | 후보를 한 번 열거 |
| C_QuestLog.GetDistanceSqToQuest | 후보의 distanceSq와 onContinent 확인 |
| C_QuestLog.GetNextWaypoint | mapID, x, y 목적지 우선 조회 |
| C_QuestLog.GetNextWaypointForMap | 현재 지도 내 퀘스트별 경로 폴백 |
| C_QuestLog.GetQuestsOnMap | 같은 퀘스트 ID의 지역 마크 폴백 |
| C_QuestLog.GetTitleForQuestID | 한 줄 제목 |
| C_QuestLog.GetQuestObjectives | 대표 미완료 목표의 진행도 |

Forever 1.60.1 (70235) UI 소스의 [QuestLogDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/a84e2b1b41d3d4137127c07e4da448aa3251d6f1/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua)를 확인했습니다. 목표별 숫자로 전체 퀘스트 완료를 추정하지 않으며, 대표 목표는 `finished == false`를 기준으로 고릅니다.

## 6. 사용 Map API

- `C_Map.GetBestMapForUnit("player")`: 현재 UI Map.
- `C_Map.GetPlayerMapPosition(mapID, "player")`: Vector2D의 `GetXY()` 또는 x/y.
- `C_Map.GetMapWorldSize(mapID)`: 같은 지도 좌표를 실제 야드 단위로 변환할 폭·높이.

지도 크기는 현재 지도별로 한 번 읽어 캐시합니다. 크기를 확인할 수 없으면 부정확한 야드나 방향을 표시하지 않고 안내 불가로 처리합니다. [Forever MapDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/a84e2b1b41d3d4137127c07e4da448aa3251d6f1/Interface/AddOns/Blizzard_APIDocumentationGenerated/MapDocumentation.lua)를 기준으로 구현했습니다.

## 7. 사용 SuperTrack API

- `C_SuperTrack.GetSuperTrackedQuestID`: 실제 선택 대상.
- `C_SuperTrack.SetSuperTrackedQuestID`: 자동 선택된 다음 퀘스트로 변경.
- `C_SuperTrack.IsSuperTrackingQuest`, `IsSuperTrackingAnything`: 사용자 waypoint 등 다른 종류의 추적 존중.

기존 Blizzard 프레임, 스크립트, 퀘스트 감시 목록과 지도 핀을 변경하지 않았습니다. setter의 반환값 대신 getter로 변경 결과를 확인합니다. API 호출이 거부되면 실제 추적 중인 퀘스트를 계속 표시합니다. [Forever SuperTrack 문서](https://github.com/Gethe/wow-ui-source/blob/a84e2b1b41d3d4137127c07e4da448aa3251d6f1/Interface/AddOns/Blizzard_APIDocumentationGenerated/SuperTrackManagerDocumentation.lua)와 [Blizzard 반납 처리 소스](https://github.com/Gethe/wow-ui-source/blob/a84e2b1b41d3d4137127c07e4da448aa3251d6f1/Interface/AddOns/Blizzard_FrameXMLUtil/Mainline/Blizzard_QuestSuperTracking.lua)를 확인했습니다.

## 8. 등록 이벤트

`PLAYER_ENTERING_WORLD`, `QUEST_LOG_UPDATE`, `QUEST_WATCH_UPDATE`, `QUEST_WATCH_LIST_CHANGED`, `QUEST_TURNED_IN`, `QUEST_ACCEPTED`, `QUEST_REMOVED`, `QUEST_POI_UPDATE`, `SUPER_TRACKING_CHANGED`, `SUPER_TRACKING_PATH_UPDATED`, `ZONE_CHANGED_NEW_AREA`, `ZONE_CHANGED`.

Quest/SuperTrack 이벤트명은 해당 Forever API 문서에서 확인했습니다. 월드·지역 이벤트는 기존 클라이언트 이벤트 패턴을 사용합니다. 모든 이벤트는 실제 클라이언트에 `C_EventUtils.IsEventValid`가 있으면 유효성을 추가 확인하며, 등록 자체도 방어 호출합니다. 무효 이벤트는 건너뜁니다.

POI·경로·지역 이벤트는 waypoint만 갱신합니다. 퀘스트 제목과 목표 테이블을 다시 요청하지 않습니다. 등록이나 API 데이터 문제는 기본 상태에서 채팅 메시지를 출력하지 않습니다. [이벤트 유효성 API](https://github.com/Gethe/wow-ui-source/blob/a84e2b1b41d3d4137127c07e4da448aa3251d6f1/Interface/AddOns/Blizzard_APIDocumentationGenerated/EventUtilsDocumentation.lua)도 Forever 소스에서 확인했습니다.

## 9. 후보 제외 기준

- Header이거나 정상적인 양의 정수 questID가 없는 항목.
- 방금 완료된 퀘스트.
- 완료되었거나 완료 여부가 불명확한 퀘스트.
- distanceSq가 nil, 0 이하, NaN, 무한대, 보호 값인 경우.
- `onContinent == true`를 확인할 수 없는 경우.

던전/레이드를 임의의 분류 규칙으로 제외하지 않았습니다. 정상적인 같은 대륙 거리 응답이 있어야 후보가 됩니다. 경로와 현재 지도 마크가 모두 없는 후보도 추적 선택은 가능하며 HUD에 “경로 없음”을 표시합니다.

## 10. 가장 가까운 퀘스트 계산

단일 순회 중 ID와 최소 distanceSq 하나만 유지하는 O(n) 방식입니다. 후보 배열 저장, table.sort, 후보별 제곱근 계산을 하지 않습니다. 동률에서는 작은 questID를 선택하여 결과를 일정하게 유지합니다. 같은 지역 우선 ON에서는 현재 지도 마크 m개를 한 번 읽어 임시 조회표를 구성하므로 전체 검색은 O(n+m)이며, 후보별 마크 전체 순회를 하지 않습니다.

“같은 지역 퀘스트 우선”은 실제 구현한 옵션이며 기본 OFF입니다. ON이면 현재 UI Map과 waypoint UI Map이 일치하는 후보의 최소값을 우선합니다. 같은 지도 후보가 없으면 같은 대륙 전체 후보의 최소값을 사용합니다. 이름이 같은 지역을 텍스트로 추정하지 않습니다.

## 11. 화살표 방향 계산

동일 UI Map에서만 다음을 계산합니다.

```lua
dx = (targetX - playerX) * mapWidth
dy = (targetY - playerY) * mapHeight
targetAngle = atan2(-dx, -dy) % (2*pi)
relativeAngle = (targetAngle - playerFacing) % (2*pi)
```

북쪽은 0, 서쪽은 π/2, 남쪽은 π, 동쪽은 3π/2입니다. 서로 다른 지도 좌표를 빼지 않습니다. 직사각형 지도의 가로·세로 비율도 적용합니다. 회전은 ArrowTexture에만 적용합니다. 플레이어가 waypoint 위에 있으면 거리 0 yd, 화살표 숨김으로 처리합니다.

방향 계산 함수는 UI에서 분리되어 있습니다. 지역 간 좌표 변환이나 이동경로 계산은 포함하지 않았습니다.

## 12. GetPlayerFacing 처리

캐릭터 방향만 사용하며 카메라 방향은 사용하지 않습니다. nil, 보호 값, 숫자가 아닌 값과 API 오류를 거릅니다. 유효하지 않으면 추적은 유지하고 화살표를 숨겨 “경로 안내 불가”로 표시합니다. 이후 정상 데이터가 돌아오면 설정 갱신 주기에서 복구합니다. [Forever GetPlayerFacing 정의](https://github.com/Gethe/wow-ui-source/blob/a84e2b1b41d3d4137127c07e4da448aa3251d6f1/Interface/AddOns/Blizzard_APIDocumentationGenerated/PlayerScriptDocumentation.lua)를 확인했습니다.

## 13. Rotation smoothing

```lua
delta = (target - current + pi) % (2*pi) - pi
current = (current + delta * factor) % (2*pi)
```

factor 기본값은 0.25이며, 부드러운 회전 OFF에서는 1로 적용하여 즉시 목표각으로 이동합니다. 359°→1°와 1°→359° 양방향 경계, 좌·우·180° 회전을 검증했습니다. 대상 변경이나 안내 불가 후 복구 때 이전 대상의 각도를 이어받지 않습니다.

## 14. HUD 상태 구조

| 상태 | 표시와 처리 |
| --- | --- |
| IDLE | 추적 대상 없음, HUD 숨김 |
| TRACKING | 화살표, 거리, 제목, 대표 진행도 |
| NO_WAYPOINT | 화살표 숨김, 경로 없음, 제목·진행도 유지 |
| NAVIGATION_UNAVAILABLE | 화살표 숨김, 경로 안내 불가, 추적 유지 |
| COMPLETED | 체크와 목표 완료! |
| SWITCHING | 기존 완료 화면 Fade-out과 다음 선택 |

HUD 폭은 240px, 화살표 기본 폭 64px(세로 높이는 눕힘 각도에 따라 압축), 거리 16px, 제목 14px, 진행도 12px입니다. 기본 위치는 UIParent CENTER (0, 180)입니다. 기본 배경은 없고 텍스트 Outline과 고정 폭·높이, 줄바꿈 OFF를 사용합니다. 긴 제목·목표 문구는 정해진 한 줄 영역 안으로 제한합니다.

UI는 Tracker가 결정한 상태를 표시합니다. UI 코드가 후보를 고르거나 전체 퀘스트 완료를 판단하지 않습니다.

## 15. SavedVariables

모듈 활성화는 기존 `KHQOLDB.enabled.questNavigator = true` 기본값을 사용합니다. 동일한 enabled 값을 모듈 안에 중복 저장하지 않습니다.

`KHQOLDB.modules.questNavigator`의 기본값:

```lua
autoTrack = true
preferSameRegion = false
showArrow = true
arrowSize = 64
arrowAlpha = 1
arrowTilt = 55
distanceUnit = "yards"
smoothRotation = true
showDistance = true
showTitle = true
showProgress = true
progressMode = "numeric"
locked = true
positionX = 0
positionY = 180
arrowUpdateInterval = 0.10
distanceUpdateInterval = 0.25
smoothingFactor = 0.25
```

기존 MergeDefaults의 types 정책을 사용하고 숫자 범위·NaN·무한대·진행도 선택값을 보정합니다. 다른 모듈 설정은 수정하지 않습니다. 위치 잠금을 해제하면 드래그 모드가 켜지고 좌표를 저장합니다. 화면 경계 Clamp를 사용하며 위치 초기화는 좌표만 (0,180)으로 복원합니다. 설정 페이지를 닫으면 이동 모드가 잠깁니다.

## 16. DESIGN.md 적용

- 기존 좌측 모듈 목록과 우측 설정 영역, 알파벳 순서 등록.
- 공통 CreatePage의 제목 → 설명 → 모듈 사용 → Divider.
- 공통 CreateBuilder, Section, Checkbox, Slider, Dropdown, Button, Description.
- 공통 Theme의 간격·행 높이·폰트·비활성 투명도.
- 추적 / 화살표 / 표시 / 위치 / 고급의 구분.
- “위치 잠금”, “위치 초기화”의 기존 명칭 사용.
- 고급 갱신 주기는 기본 접힌 영역이며 펼칠 때 스크롤 높이를 갱신.
- OFF일 때 하위 설정 입력 차단·투명도 감소, 모듈 사용 체크는 활성 유지.
- 기존 모듈 설정 초기화·전체 초기화 공통 흐름 그대로 적용.

## 17. CPU 최적화

- 전체 후보 순회는 완료 전환의 선택 시점에 한 번만 수행합니다. 초기 활성화와 일반 변경은 현재 퀘스트만 읽습니다.
- 평상시 OnUpdate에서 Quest Log 열거, 후보 거리 API, 목표 API를 호출하지 않습니다.
- 화살표 기본 0.10초, 거리 기본 0.25초 accumulator.
- 경로 이벤트와 실제 Quest 데이터 이벤트를 구분하여 불필요한 목표 재조회 방지.
- distanceSq 비교, 후보 정렬 없음.
- HUD 거리 문자열은 반올림한 정수 야드가 달라질 때만 만들고 표시 값이 같으면 SetText 생략.
- OnUpdate 등록은 실행 여부가 바뀔 때만 변경합니다.
- IDLE 및 완료 표시의 연출 종료 시 지속 OnUpdate를 해제합니다.
- OFF이면 모든 이벤트, OnUpdate와 전환 동작을 해제합니다. 별도의 예약 타이머는 없습니다.

60초 / 60fps 모의 검사에서 Quest Log scan, 후보 GetDistanceSqToQuest, 제목·목표 재조회, 동일 텍스트 SetText는 모두 0회였습니다. 실제 게임 FPS 개선이나 CPU 수치를 의미하는 결과는 아닙니다.

## 18. 메모리 최적화

현재·선택·최근 완료 ID, 목적지 조회 출처와 waypoint 좌표, 플레이어 위치, 지도 크기, 회전·UI 상태와 표시 문자열만 유지합니다. 후보 리스트와 Quest DB를 장기간 보관하지 않습니다. 자체 업데이트마다 임시 테이블을 만들지 않습니다. GetPlayerMapPosition 등 클라이언트 API가 반환하는 객체와 이벤트 시 목표 배열은 일시적으로 읽고 보관하지 않습니다. HUD 프레임·텍스처·설정 컨트롤은 재사용합니다.

디버그 스냅샷 테이블은 명시적으로 `KHQOL.modules.questNavigator:GetDebugSnapshot()`을 호출할 때만 생성합니다. 기본 채팅 출력은 없습니다.

## 19. 실게임에서 추가 확인할 항목

- 현재 설치한 Forever 빌드의 API 존재·동작과 Quest 데이터 완성도.
- 전투 중 SuperTrack setter 허용 여부와 다른 퀘스트 애드온과의 이벤트 순서.
- 실제 지도별 waypoint·GetMapWorldSize 값, Vector2D 응답.
- 캐릭터 좌우 회전과 텍스처 회전의 시각적 방향, 화면 크기·UI Scale.
- 실제 `/reload`, 재접속 후 KHQOLDB 복원과 드래그 Clamp 동작.
- 아주 긴 한국어 제목·목표 문구의 한 줄 표시.
- 게임 프레임 시간·CPU/메모리 프로파일. 모의 검사는 실제 성능 측정이 아닙니다.

API 검증은 공개 Forever UI 소스 확인과 실행 시 기능 검사로 수행했습니다. 사용자의 게임 프로세스에서 직접 API를 실행한 것은 아닙니다.

## 20. 알려진 제한사항

- 화살표는 playerMapID == targetMapID일 때만 지원합니다. 다른 지도면 경로 안내 불가입니다.
- 경로 API와 현재 지도 퀘스트 마크 모두 없으면 경로 없음이며 자체 목표/NPC 위치 DB로 보완하지 않습니다. 지역 마크는 개별 목표 위치와 다를 수 있습니다.
- 야드와 방향은 같은 지도 위 두 점의 직선 안내입니다. 지형, 장애물, 이동 경로, 높이 차이를 계산하지 않습니다.
- 후보 순위는 Blizzard의 Quest 거리, HUD 거리는 현재 waypoint까지의 직선거리여서 두 값은 다를 수 있습니다.
- 후보 검색은 클라이언트 GetNumQuestLogEntries/GetInfo가 제공하는 범위입니다. 누락·접힌 헤더의 열거 범위는 실게임에서 추가 확인해야 하며, 목록을 강제로 펼치지 않습니다.
- 거리 0 또는 대륙 추적 가능 여부가 불명확한 퀘스트는 자동 후보에서 제외합니다.
- 대표 미완료 목표 하나만 표시합니다. 수치가 없으면 숫자 모드에서는 진행 중입니다.
- 후보가 없으면 완료 대상을 유지하며 이동만으로 후보를 계속 재검색하지 않습니다.
- 외부 추적 변경은 우선합니다. 다른 애드온이 지속적으로 Super Tracking을 바꾸면 그 변경을 따릅니다.
- 수락, 반납, 캐릭터 이동, waypoint 생성은 자동화하지 않습니다.

## 21. 실제 게임 테스트 순서

1. 기존 설정을 유지한 채 설치·로그인하고 `/kh quest`에서 ON 상태를 확인합니다. 다른 KHQOL 모듈도 표시되는지 확인합니다.
2. 퀘스트 1개를 Super Tracking으로 선택하고 미완료 상태의 제목·숫자 진행도·거리·화살표를 확인합니다.
3. 여러 퀘스트를 보유하고 같은 지도에서 북·동·남·서 방향 목표를 안내하는지 확인합니다.
4. 캐릭터를 좌·우·180° 회전하고 359°↔1° 경계에서 반대로 한 바퀴 돌지 않는지 확인합니다.
5. 부드러운 회전 OFF에서 즉시 방향이 바뀌는지 확인합니다.
6. 현재 목표를 완료하고 약 0.85초 완료 UI 뒤 가장 가까운 미완료 퀘스트로 Blizzard 추적과 HUD가 함께 전환되는지 확인합니다.
7. 목표 2~3개를 연속 완료하고 중복 이벤트로 완료 연출·선택이 반복되지 않는지 확인합니다.
8. 자동 선택 OFF, 후보 없음, 같은 지역 우선 ON/OFF의 동작을 확인합니다.
9. 경로 API에 좌표가 없어도 같은 지도 퀘스트 마크가 있으면 화살표가 표시되는지 확인합니다. 경로와 마크가 모두 없는 퀘스트/다른 mapID 퀘스트에서 각각 경로 없음/경로 안내 불가이며 추적은 유지되는지 확인합니다.
10. 위치·방향 조회가 어려운 인스턴스에서도 Lua 오류 없이 안내 불가가 되고, 야외 복귀 후 복구되는지 확인합니다.
11. 퀘스트 획득·포기·반납, 완료 전환 도중 다른 퀘스트/사용자 waypoint를 직접 선택하는 경우를 확인합니다.
12. 제목/거리/진행도 각각 OFF, 숫자/목표 텍스트 모드, 화살표 크기·투명도와 고급 갱신 주기를 확인합니다.
13. 위치 잠금 해제 → 드래그 → 페이지 닫기 → `/reload` → 재접속으로 좌표와 설정을 확인하고 위치 초기화를 실행합니다.
14. 완료 연출·이동 중 모듈 OFF로 HUD가 즉시 사라지는지, ON으로 현재 대상을 복원하는지 확인합니다.
15. 사냥꾼 원거리/근거리/먼 거리 폴백, 툴팁, Cast Bar, 다른 HUD와 함께 사용하고 Lua 오류와 평상시 프레임 시간을 확인합니다.

## 검증 결과

- 신규 모듈 모의 시나리오 및 중앙 초기화 검사 59개 + Lua 5.1 문법/TOC 검사 2개 = **61/61 PASS**.
- 패키지의 Lua 파일 48개 문법 검사 PASS.
- 기존 Tooltip 폰트·비동기·보호 값 회귀 검사 PASS.
- 기존 Range/Mouseover/사냥꾼 폴백 회귀 검사 PASS.
- 설정 화면 12개, 모듈 ON/OFF 11개, 60회 페이지 전환 프레임 재사용, 기존 저장값 보존 검사 PASS.
- 최종 패키지의 기존 모듈 코드·미디어와 SavedVariables 선언 보존 검사 PASS.
- 수정 HUD의 실게임 테스트는 **미실행**입니다. 사용자의 사전 진단으로 퀘스트 759의 마크 좌표 반환은 확인했습니다.
