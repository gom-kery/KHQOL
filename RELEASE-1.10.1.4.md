# KHQOL 1.10.1.4 작업 보고서

기준 1.10.1.3 / 결과 1.10.1.4 / 2026-10-09.
설정 UI 초기 표시와 월드맵 위치 복원만 수정했습니다. 이전에 중지한 대화창 방향키 수정 및 기본값 ON 변경은 포함하지 않습니다.

## 문제 A: 확인된 코드 경로와 한계

기존 `SettingsUI.ShowPage`도 최초 진입에서 `UI:Refresh(content)`를 호출했습니다. 따라서 단순한 “최초 Refresh 미호출”은 원인이 아닙니다. 코드에서 확인한 결함은 다음과 같습니다.

1. `UI:Refresh`는 **직접 자식에 uiControls가 있을 때만** 내려갑니다. 일반 컨테이너 아래에 실제 옵션이 있으면 갱신이 그 중간에서 끊깁니다.
2. `CreateLabel`은 생성 시만 폰트·문구를 설정하고 갱신 모델에 등록하지 않습니다. 일반 버튼의 Refresh도 활성 상태만 적용하고 문구를 다시 적용하지 않습니다.
3. `ShowPage`는 content를 먼저 Show한 뒤 설정 탭 선택·갱신을 합니다. Presenter도 패널 Show 후 RefreshTab을 실행하고 content OnShow에서 다시 탭을 선택합니다. 최초 생성(기본 Show 상태)과 재표시(OnShow 발생)의 경로가 다릅니다.

수정은 이 세 가지 확인된 표시 갱신 결함을 제거합니다. **실제 클라이언트의 간헐적 빈 글자를 직접 재현하지 못했으므로, 이 결함 중 어느 것이 관측 증상을 유발했는지까지 확정한 것은 아닙니다.** 렌더러의 상태나 다른 애드온 영향은 미확인입니다.

DB는 Core의 PLAYER_LOGIN에서 기본값 병합·Migrate·관련 모듈 초기화 이후 설정창을 생성합니다. 최초 설정 본문은 메뉴 방문 때 생성됩니다. 현재 코드에서 DB/Locale 미준비나 설정 항목의 지연 등록을 원인으로 볼 근거는 발견하지 못했습니다. 목록 재사용 시 동적 이름을 갱신하는 기존 흐름은 보존했습니다.

## 문제 A 수정과 표시 순서

- `UI.lua`: 설정 소유 라벨의 현재 문구 모델을 등록합니다. SetText 후크로 동적 이름·설명과 의도적인 빈 문자열도 반영합니다. 공통 Refresh가 컨트롤 값을 갱신한 후 폰트·문구를 재적용하고 모든 자식 컨테이너로 내려갑니다. 일반 버튼도 현재 문구를 갱신합니다. 드롭다운의 선택 문구 및 색상 버튼의 별도 Refresh는 유지합니다.
- `SettingsUI.lua`: 새 content는 Hide 상태에서 생성합니다. `RefreshActivePage`가 본문·모듈 헤더·탭 헤더·높이를 공통 갱신하며 최초 진입·재진입·설정 변경·창 OnShow에서 사용됩니다. 프로필 변경은 기존 RefreshSettingsViews → ShowPage 경로로 같은 함수를 통과합니다.
- `UI/SettingsPresenter.lua`: 선택 패널의 RefreshTab → UI.Refresh → Show → 높이 계산 순서로 변경하고 중복 content OnShow 탭 선택을 제거했습니다.

흐름: 캐시 확인/비표시 상태 생성 → 탭 선택 및 패널 갱신 → RefreshActivePage(값·문구·헤더·높이) → 본문 Show → 실제 표시 높이 재계산. 지연 타이머나 강제 재진입을 추가하지 않았습니다. 메뉴·항목·디자인·크기 수치는 변경하지 않았습니다.

## 문제 B: 확인된 원인

`FrameMover.Apply`는 저장된 `CENTER / UIParent BOTTOMLEFT`를 SetPoint로 적용하지만 최종 크기를 이용한 화면 경계 검사가 없었습니다. 기존 자동 경계 제한은 드래그 시작 때만 설정되므로 reload 후 저장값만 복원한 세션에는 적용되지 않을 수 있습니다.

참조한 Camelot Blizzard 소스의 `QuestLogOwnerMixin.SetQuestLogPanelShown`은 펼칠 때 월드맵 폭을 minimizedWidth + questLogWidth로 늘린 뒤 QuestLog Show와 UpdateUIPanelPositions를 실행합니다. `SetDisplayState`는 ShowUIPanel → 표시 상태/목록 변경 → 목록 갱신/스페이서 배치 → SynchronizeDisplayState 흐름입니다. 기존 KHQOL은 OnShow와 SetPoint 후크만 사용하므로 **폭 변경만으로 중심 앵커의 왼쪽 경계가 달라지는 경우**와 **Blizzard 재배치 후 전체 영역 검사**를 처리하지 못했습니다.

예: 중심 X=351에서 폭 702는 왼쪽 0입니다. 폭 1035로 펼치면 같은 중심에서 왼쪽은 -166.5가 됩니다. 저장 앵커를 바꾸지 않고 X를 166.5만 보정하면 전체 창이 들어옵니다. 이 흐름은 모의 검사에서 재현했습니다. 설치된 클라이언트 내부 Lua는 직접 추출하지 않았으며 참조 Blizzard 리비전은 `15666a6e67938a1ab5caf041406464251db111ca`입니다.

## 문제 B 수정과 위치 정책

수정 파일: `Modules/FrameMover.lua`.

최종 적용을 기존 Apply에 모았습니다. 유효 저장 위치 복원 → 현재 월드맵 Rect와 표시 중인 QuestLog Rect의 합집합 계산 → 각 프레임의 유효 배율을 UIParent 좌표로 변환 → 화면 경계 초과분만 이동합니다. 월드맵 자체가 목록 폭을 이미 포함할 때 폭을 중복 가산하지 않습니다.

- 기존 OnShow/SetPoint 후크 유지.
- 월드맵 OnSizeChanged 및 SetQuestLogPanelShown·SetDisplayState·SynchronizeDisplayState 보안 후크에서 Apply를 호출합니다. 펼침/접힘 및 UIPanel의 최종 위치 배치 후에도 재검사합니다.
- UI_SCALE_CHANGED / DISPLAY_SIZE_CHANGED도 기존 Refresh 이벤트에 연결했습니다.
- applying/moving 가드로 후크 재귀와 드래그 간섭을 방지합니다. 후크가 여러 번 실행되어도 매번 같은 저장 중심과 최종 크기를 사용하므로 드리프트가 없습니다.
- 보정 위치는 SavedVariables에 덮어쓰지 않습니다. **사용자가 저장한 좌표를 유지하고 열기/크기 변경마다 Clamp하는 정책**입니다. 수동 드래그 종료의 저장 정책은 기존 그대로입니다.
- 자동 위치 적용은 월드맵이 실제 Protected인 전투에서 보류합니다. 비보호 월드맵의 OnShow/레이아웃 후크는 전투에서도 적용할 수 있습니다. 기존 수동 이동/등록/전체 초기화/전역 Refresh의 전투 보류 정책은 유지합니다.
- FrameMover OFF나 유효 저장 위치가 없는 월드맵은 새로운 자동 위치 제어를 받지 않습니다. 다른 대상 프레임의 위치 적용은 변경하지 않았습니다.
- 창이 화면보다 큰 경우 위치 이동만으로 완전히 넣는 것은 불가능합니다. 이때 왼쪽/아래 경계를 맞춥니다. 크기·배율을 자동 축소하지 않습니다.

Blizzard 원본·전역 함수 override·지도 크기/퀘스트 크기 변경·타이머는 없습니다.

## 파일과 데이터

기능 수정: UI.lua, SettingsUI.lua, UI/SettingsPresenter.lua, Modules/FrameMover.lua.
버전/문서: Bootstrap.lua, KHQOL.toc, README.md, CHANGELOG.md, 이 보고서.
런타임 신규 파일은 없습니다. 새 보고서만 추가했습니다. README에 1.10.1.0~1.10.1.3의 누락된 변경 이력을 추가했습니다.
SavedVariables 키·스키마·기존 좌표·프로필·기능 기본값 변경 및 마이그레이션 없음. 대화창·아이템 파괴·다른 이동 대상의 실행 코드 보존.

## 검증

STATIC CHECK: PASS. Lua 5.1 구문 77개 / TOC 파일 경로 73개.
모의 검사: 기존 FrameMover/Inspector 214개, 대화창 100개, 실제 Blizzard 파괴 확인 테이블 기반 23개, 이번 설정/지도 회귀 31개 assertion 통과(총 368개).
이번 검사에는 비표시 상태 문구 재적용, 중간 컨테이너, 동적/빈 문구, 드롭다운, 실제 ShowPage 함수의 첫 Show 이전 갱신·캐시 재진입·재오픈, 지도 좌/우/상/하, 펼침 후 반복 재오픈, 목록 합집합, 배율, 저장 좌표 보존, 보호/비보호 전투 분기와 기본 위치 복원이 포함됩니다.
게임 렌더링·IME·보호 실행 엔진을 흉내 낸 검증은 아니며 아래 게임 항목의 통과를 뜻하지 않습니다.

IN-GAME: NEEDS TEST. 실제 Forever 클라이언트는 실행하지 않았습니다.

## 인게임 테스트 체크리스트 (모두 NEEDS TEST)

- A-1~A-3: /reload 후 처음 설정창을 열고 일반·바 설정·편의 기능에서 버튼/Checkbox/라벨 문구 확인.
- A-4~A-5: 다른 메뉴에서 복귀하고 창을 닫았다 다시 열어 동일 표시 확인.
- A-6: 프로필 변경 후 문구·값·활성 상태 확인.
- A-7: /reload 반복 후 간헐적 누락 여부 확인.
- B-1~B-3: 이동 기능 ON 및 저장 위치가 있는 상태에서 목록 닫힘·펼침·펼친 상태 재오픈의 전체 경계 확인.
- B-4~B-5: 지도 재오픈 및 목록 펼침/접힘 반복 시 드리프트 확인.
- B-6: 수동 이동 후 재오픈하여 저장 위치와 필요한 보정만 적용되는지 확인.
- B-7~B-8: 왼쪽/오른쪽 끝에 이동 후 펼쳐 최소 보정 확인.
- B-9~B-10: UI 배율 변경 및 /reload 후 위치 복원 확인.
- 전투 중 열기/목록 전환/전투 종료, 기능 OFF/초기화, 최대화/최소화 후 오류·taint와 복원 확인.
- 캐릭터창·특성·마법책·매크로 이동/복원 및 대화창·아이템 파괴 옵션의 기존 동작 확인.

설치: ZIP 내부 KHQOL 폴더로 교체하고 /reload. SavedVariables를 삭제하지 않습니다.
