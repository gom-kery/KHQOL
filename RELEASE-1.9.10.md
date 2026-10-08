# KHQOL 1.9.10 — Forever Note 체크리스트 네비게이션

기준은 사용자 제공 `KHQOL-1.9.9.3.zip`입니다. Forever Note가 좌표 목적지를 제공하고, 공용 Navigation Engine이 자동/수동 목적지를 선택하며, 기존 Navigation UI가 화살표와 거리를 표시합니다. WaypointUI와 Quest Navigator를 사용하지 않아도 노트만으로 안내할 수 있습니다.

## 사용 방법

1. ZIP의 `KHQOL` 폴더를 기존 `Interface/AddOns/KHQOL`에 덮어쓰고 `/reload`합니다. SavedVariables는 삭제하지 않습니다.
2. KHQOL 설정 → Note → 체크리스트 네비게이션 → **네비게이션 연결**을 켭니다. 기본값은 OFF입니다.
3. 안내할 지역에서 체크리스트 한 항목에 `/way 46 73 희귀몹` 또는 `희귀몹 확인 @46,73`을 입력합니다. 채팅 명령 실행이 아니라 노트 항목의 텍스트 입력입니다.
4. 자동 안내는 퀘스트가 우선입니다. 퀘스트 목적지가 없으면 현재 지도에서 비교 가능한 미완료 노트 중 가까운 항목을 안내합니다. 다른 페이지·접힌 그룹의 항목도 포함합니다.
5. 특정 노트를 즉시 안내하려면 해당 행의 **▶**를 누릅니다. 퀘스트 이벤트가 발생해도 수동 대상을 유지하며, HUD의 **AUTO**로 자동 모드에 복귀합니다.
6. 체크 완료 시 좌표와 ID는 남고 후보에서만 빠집니다. 체크를 해제하면 후보로 돌아옵니다.

노트 연결, 완료 시 다음 위치 자동 안내, 좌표 행의 ▶ 표시를 각각 설정할 수 있습니다. 다음 위치 자동 안내를 끄면 현재 노트 완료 후 노트 자동 선택을 잠시 멈추며, AUTO 또는 다른 ▶로 재개합니다. 퀘스트의 우선순위는 유지됩니다.

좌표는 입력 당시 현재 mapID에 저장됩니다. 다른 지역으로 이동하거나 `/reload`해도 기존 좌표의 지도는 바꾸지 않습니다. 좌표 수치를 새로 입력하면 그때의 지도를 저장합니다. 다른 지도에 있는 항목을 수동 선택하면 “경로 안내 불가”를 표시하며, 해당 지도로 이동하면 다시 안내합니다. 지도 사이 경로와 지도 핀은 생성하지 않습니다. 화살표 모양·크기·거리 단위·위치는 기존 Quest Navigator의 공용 표시 설정을 사용합니다.

## 1. 조사한 파일과 기존 구조

`Navigation.lua`, `NavigationUI.lua`, `QuestNavigator/Core.lua`, `QuestNavigator/Tracker.lua`, `QuestNavigator/UI.lua`, `QuestNavigator/Settings.lua`에서 후보 등록, 활성 목적지, 거리·각도, 완료 전환, 설정 진입점을 확인했습니다.

Note 관련 조사 파일은 `Clock/Todo.lua`, `Clock/Core.lua`, `Clock/Settings.lua`, `SettingsUI.lua`, `Profiles.lua`, `Core.lua`, `KHQOL.toc`입니다. 실제 Note 설정은 `Clock/Settings.lua`가 아니라 루트 `SettingsUI.lua`의 todo 페이지에서 구성됩니다.

기준 Engine은 Source별 후보 배열과 단일 활성 목적지를 가지고 있었으며, Source 간 우선순위와 수동 추적 정책은 없었습니다. Quest Navigator가 공용 UI의 전체 활성화를 담당하고 있었습니다.

## 2. 기존 체크리스트 데이터

저장 위치는 `ForeverClockDB.todo.pages`이며 Clock 모듈의 `db`가 같은 저장값을 참조합니다. 페이지는 `title`, `text`, `mode`를 갖고, 일반 항목은 `individualTasks`, 그룹 항목은 `groups[].tasks`에 저장됩니다. 기존 `tasks`는 `EnsureTodoGroups`에서 이전됩니다.

항목은 `{text=..., done=false}` 형태이며 영구 ID가 없었습니다. 체크하면 완료 항목을 끝으로, 체크 해제하면 앞쪽으로 옮기므로 배열 순서는 식별자로 사용할 수 없습니다. 기존 완료 필드 `done`과 그룹·페이지·창 저장 구조를 그대로 사용합니다.

## 3. 추가 데이터 구조

```lua
{
  id = "fn:17",
  text = "/way 46 73 희귀몹",
  done = false,
  waypoint = {mapID = 1412, x = 0.46, y = 0.73, label = "희귀몹"},
}
```

mapID 1412는 구조 예시이며 실제 값은 입력 시 현재 지도 API에서 읽습니다. 좌표 항목에만 `id`와 `waypoint`를 추가합니다. ID는 `todo.nextNavigationID`를 이용한 증가값으로 만들고, 재정렬·삭제·체크·재로딩에도 유지합니다. 저장값의 중복 ID는 유효한 첫 ID를 유지하면서 나머지를 보정합니다. 일반 항목에는 불필요한 ID를 추가하지 않습니다.

## 4. 파서 위치와 검증

신규 `Clock/Navigation.lua`의 `ParseTodoWaypoint` / `UpdateTodoWaypoint`가 담당합니다. `/way X Y label`, `label @X,Y`만 인식하고 소수와 0~100을 허용합니다. 100으로 나눠 내부 좌표로 저장합니다. 음수·범위 초과·문자·지수/16진수·불완전한 패턴은 waypoint로 등록하지 않으며 원문은 그대로 저장합니다.

`C_Map.GetBestMapForUnit("player")`가 유효한 지도 ID를 반환할 때만 새 좌표를 저장합니다. 지도 API가 없거나 실패하면 가짜 mapID를 넣지 않습니다. 같은 수치에서 설명만 수정하면 기존 지도는 유지합니다. 기존 저장된 일반 텍스트는 로드만으로 좌표 항목으로 재해석하지 않습니다. 명시적으로 편집하거나 새 텍스트를 체크리스트로 변환할 때 파싱합니다.

## 5. ForeverNote Source 등록

`Clock/Navigation.lua`가 `RegisterSource("ForeverNote", {priority=2, autoSelect=true, allowZero=true, enabled=false})`를 사용합니다. Quest는 기존 어댑터에서 priority=1로 등록합니다. Note 연동 파일은 TOC에서 공용 Engine/UI와 Quest 어댑터 다음에 로드됩니다.

## 6. Destination 갱신 흐름

`RefreshTodoNavigation`은 체크리스트 모드 페이지의 미완료·유효 waypoint를 공용 `{source,id,mapID,x,y,label,metadata}`로 변환합니다. metadata에는 `checklistID`와 페이지 제목을 넣고 `SetSourceDestinations("ForeverNote", destinations)`로 전체 스냅샷을 교체합니다. 중복 누적 등록하지 않습니다.

행 생성·삭제·그룹/페이지 삭제·체크는 기존 `RefreshTodo`를 통해 갱신하며, 행 편집은 `UpdateTodoWaypoint`에서 즉시 갱신합니다. 옵션, Note 모듈 ON/OFF, 로그인과 프로필 적용도 연결했습니다. 지역 이벤트는 공용 UI의 예약 기능으로 병합합니다. Note는 활성 목적지나 거리·각도를 별도로 저장하지 않습니다.

## 7. 완료와 체크 해제

기존 체크박스의 `done` 변경과 항목 이동은 유지됩니다. 완료 항목은 후보에서만 제외하고 `waypoint`, 원문, ID는 삭제하지 않습니다. 체크 해제 시 같은 ID와 좌표로 복귀합니다. 체크리스트와 텍스트를 왕복할 때 동일 원문의 기존 항목을 재사용해 지도와 ID가 다른 지역의 값으로 바뀌지 않도록 했습니다. 기존 그룹 해체 확인창은 유지됩니다.

## 8. Quest 우선순위

Engine에 Source별 focus, 활성화, 고정 priority, 자동 후보 선택, 완료 전환 예약을 추가했습니다. Quest는 기존 네이티브 초점과 완료 정책이 결정한 목적지를 focus로 제공합니다. Quest 후보 전체가 있다고 임의로 새 퀘스트를 선택하지 않으므로 기존 완료 후 선택 정책을 유지합니다.

기본 선택은 Quest focus → ForeverNote nearest입니다. 좌표가 아직 없는 Quest도 기존 제목과 “경로 없음” 상태를 유지합니다. Quest의 완료 애니메이션 동안은 Quest가 자리를 유지합니다. Note nearest는 현재 지도와 실제 지도 크기로 비교할 수 있는 좌표만 계산하며, 선택당 플레이어 위치를 한 번 읽습니다. Quest의 기존 네이티브 거리·난이도·같은 지역 우선 정책은 유지합니다.

## 9. Manual Override와 공용 UI

Engine의 `SetManualDestination(source,id)`와 `ClearManualDestination()`으로 구현했습니다. 수동 상태는 Source와 ID만 런타임에 보관합니다. 목적지의 새 스냅샷에서 같은 ID를 찾아 좌표·설명을 갱신하므로 퀘스트 이벤트와 충돌하지 않습니다. 완료·삭제·좌표 제거·비활성화·무효 좌표는 수동 추적을 해제합니다.

NavigationUI는 Source별 표시 정보와 활성 요청을 관리합니다. Note가 켜져 있으면 Quest 모듈을 꺼도 공용 UI가 동작합니다. Quest의 완료 타이머는 기존대로 처리하되 배경 퀘스트의 fade가 수동 Note HUD를 가리거나 방향 갱신을 멈추지 않도록 했습니다. ▶는 연결·표시 옵션이 켜진 유효 좌표 행에만 나타나며 완료 행에서는 비활성화됩니다. AUTO는 수동 상태 또는 완료 후 노트 자동 선택을 멈춘 상태에서 표시됩니다.

## 10. SavedVariables 호환

새 전역 SavedVariables나 전체 초기화는 없습니다. `todo.navigation={enabled=false,autoAdvance=true,showTrackButton=true}`를 추가하며 설정은 프로필에 포함합니다. 페이지·항목·좌표·ID 증가값은 기존 개인 노트 데이터로 유지해 프로필 적용 시 덮어쓰지 않습니다.

기존 table, 일반 문자열 항목, 이전 `tasks` 배열을 읽습니다. `done`이 없고 `completed`가 있는 항목은 완료 상태를 호환해서 읽고 알 수 없는 사용자 필드는 남깁니다. 창을 처음 만들 때 빈 입력칸으로 기존 메모를 저장하지 않도록 초기 Hide에 저장 방지 처리를 추가했습니다.

## 11. 변경 파일

- `Navigation.lua`: Source 선택, focus/예약/수동 상태, nearest 위치 읽기 공유.
- `NavigationUI.lua`: Source별 활성화·표시·완료 전환, AUTO 버튼.
- `Clock/Navigation.lua` 신규: 파서·ID·후보 어댑터·▶ 연결.
- `Clock/Todo.lua`: 기존 행/체크 갱신 연결, 작은 ▶, 모드 왕복 보존, 초기 저장 방지.
- `Clock/Core.lua`: DB 준비 후 Note 후보 복구.
- `QuestNavigator/Core.lua`, `Tracker.lua`, `UI.lua`: Quest focus·표시·전환을 Source별 공용 API로 연결.
- `Core.lua`, `Profiles.lua`: Note 모듈 전환·프로필 설정 적용 연결.
- `SettingsUI.lua`: Note 설정 3개와 입력 설명.
- `Bootstrap.lua`, `KHQOL.toc`: 버전 및 신규 파일 로드.
- `README.md`, `CHANGELOG.md`, 이 릴리스 문서: 사용법과 검증 기록.

## 12. 검증 결과와 다른 모듈 영향

Lua 5.1과 모의 WoW API/프레임에서 **240개 검증 항목 모두 통과**했습니다. 실제 게임 클라이언트를 실행한 결과는 아닙니다.

| 영역 | 결과 |
|---|---:|
| 기존 Quest 동작과 1.9.9.3 기준 비교, 공용 Engine/UI, 업데이트 예산 | 115/115 |
| 최신 원형 상태 아이콘을 포함한 목표 추적기·상단 장식·상호작용 | 35/35 |
| 전체 TOC/로그인·설정·저장값·공용 위치/프로필 | 5/5 |
| Note 파서·실제 행 콜백·수동 충돌·완료·재로딩·성능 | 31/31 |
| 다른 모듈·공용 설정/프로필/위치 편집·환경 HUD·경험치 바 | 54/54 |

전체 Lua 64개 문법과 TOC 파일 존재를 확인했습니다. 기존 설정 항목은 유지하고 Note 설정만 추가했습니다. 새 기본값을 제외한 초기·레거시 저장값은 1.9.9.3과 동일합니다. 다른 모듈 소스, 텍스처·폰트·바인딩 파일은 바이트 단위로 동일하며, 기준 파일 중 총 122개는 변경하지 않았습니다. 특히 환경 HUD의 전체 길이 발광/긴급 오버레이 숨김, 색상·채움·텍스트 위치·경고음과 경험치 바의 기본 UI 복구·구간 표시·이벤트 동작을 재검사했습니다.

공용 설정의 모든 페이지·모듈 ON/OFF·프로필 적용, 위치 편집 저장/취소/전투 진입, 리소스 연동 시전 바, 사냥꾼 탄약 위치, 주술사 토템 메뉴, Threat/PvP/CastBar의 표시·입력 복구도 확인했습니다. Note는 별도 OnUpdate를 추가하지 않으며 60초 이동 갱신에서 파싱/후보 재생성 0회, 지역 이벤트 100회에서 후보 갱신 1회, UI 반복 갱신에서 프레임 재생성 0회를 확인했습니다.

게임에서 남은 확인은 실제 화살표 방향·거리·한글 버튼 렌더링, 전투 중 보호/taint, 맵 전환과 `/reload`입니다. 간단한 순서는 다음과 같습니다.

1. Quest Navigator OFF, Note 연결 ON에서 `/way 46 73 테스트` 입력 → 제목·화살표·거리 확인. 이동과 회전 후 변화 확인.
2. 같은 지역 좌표 2개 추가 → 가까운 항목 선택, 체크 완료 후 다음 항목 전환, 체크 해제 후 좌표 복귀 확인.
3. Quest Navigator ON 후 퀘스트 초점 → Quest 우선 확인. 다른 Note ▶ → 퀘스트 갱신 후에도 유지, AUTO → Quest 복귀 확인.
4. 수동 항목 좌표 수정·삭제·완료·Note OFF → 해제 확인. 다른 지역 이동 시 잘못된 좌표 비교 없이 안내 불가/해당 지역 자동 후보 확인.
5. 완료 항목과 일반 메모가 있는 상태에서 `/reload` → 원문·체크 상태·좌표·옵션 보존 확인.
6. 기존 버프·거리·리소스·시전·툴팁·경험치 바·환경 HUD·Threat/PvP를 사용하며 Lua 오류와 전투 후 표시 복구 확인.

## 13. 이후 Source 연결에 재사용할 지점

`RegisterSource`, `SetSourceEnabled`, `SetSourceDestinations`, `SetSourceFocus`, `SetManualDestination`, `ClearManualDestination`, `GetNearestDestination`, `RefreshSelection`을 재사용할 수 있습니다. UI는 `SetClientEnabled`, `SetSourcePresentation`으로 연결합니다. WeaponGuide 연결은 이번 버전에 구현하지 않았으며, 별도 Source가 유효 목적지와 명시적 우선순위만 제공하면 같은 계산·화살표를 사용할 수 있습니다.
