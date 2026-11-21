# KHQOL 1.11.9.4 — 아이콘 배치·우클릭 오류 수정

기준은 실제 최신 1.11.9.3 Full (435개 파일), SHA256 `4ff9549f6c9c6eca25e57ff987c977cc99c9cde97ab0a8cefc2f7849c1435203`이다. 결과는 KHQOL 1.11.9.4, 선택 DevTools 0.3.9 / catalog11 / schema1 / protocol1. 이전 ZIP·기준 소스·sources/는 수정하지 않았다.

## 원인과 변경

| 항목 | 원인·수정 |
| --- | --- |
| 음식 위치 | 전체 버프 묶음 바깥의 첫 칸 기준이어서 포만감과 X가 달랐다. 음식에 포만감 짝 식별자를 연결하고 최종 포만감 위치 기준으로 같은 X, 한 칸 위/아래에 배치한다. |
| 침낭 | 같은 규칙으로 충분한 휴식 아이콘의 바로 위/아래에 배치한다. |
| 네 방향·줄바꿈 | 짝 아이콘 공간을 확보한다. 전투 중 보호 버튼은 이동/변경하지 않고 표시와 다른 오래된 클릭 영역은 기존 가림 정책을 적용한다. 일반 주문만 있을 때 기존 위치 보존은 유지한다. |
| 전문기술 우클릭 | 유효한 탭이 선호 정렬 목록에 없으면 인덱스가 nil이 되어 비교가 실패했다. 선호 순서 뒤에 등록 순서로 유지하고 설치 확정 시 누락 탭을 보완한다. 사용자 설치에 누락이 발생한 경위까지 확인한 것은 아니다. |
| 휴지통 우클릭 | 자신의 버튼에서 클릭 전파를 막고 설정창 생성/재배치를 현재 마우스 이벤트 종료 뒤 한 번 실행한다. 우클릭 경로에는 PutItemInBag/삭제 호출이 없다. |
| MultiBarRight 배율 오류 | 아래쪽 미니맵+메뉴바 숨김 모두 KHQOL이라는 제보를 반영했다. 이전에는 기본 위치 판정을 유지한 채 MinimapCluster 자체를 아래로 이동했다. Blizzard가 그 아래 공간으로 오른쪽 행동 단축바 배율을 계산하면 높이가 0 이하가 될 수 있다. 보이는 지도·추적·낮밤·우편 구성요소를 별도 앵커 아래로 옮기고 기본 클러스터 앵커는 유지한다. ResizeLayoutFrame 자식 범위가 아래쪽 지도까지 확장되지 않도록 부모도 함께 관리한다. |

KHQOL 메뉴바 숨김 자체는 위치 이동이 아닌 투명도/마우스 처리다. 메뉴바 숨김이 단독 원인이라고 단정하지 않는다. Baganator 아이템 이동은 로그상 기본 행동 단축바 재배치를 유발하는 계기로 보인다. Baganator는 수정하지 않고 KHQOL의 미니맵 배치를 수정했다.

Blizzard 근거: [공간과 배율 계산](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_EditMode/Shared/EditModeManager.lua), [상하 경계](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_EditMode/Mainline/EditModeManagerOverrides.lua), [클러스터 ResizeLayoutFrame 상속](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_Minimap/Mainline/Minimap.xml). 로컬에 보존된 Forever 1.60.1 소스의 같은 계산도 확인했다. 사용자의 실시간 경계값을 캡처한 것은 아니다.

## 표시·저장·계측

- 음식은 포만감 위/아래, 침낭은 충분한 휴식 위/아래. 같은 X, 아이콘 크기+8px 간격. 기존 ABOVE/BELOW 선택값을 그대로 사용한다.
- 포만감 기본 감시를 직접 끄는 등 짝 아이콘이 없으면 기존 바깥쪽 배치를 사용한다. 음식/침낭 소유 조건과 포만감 아이콘의 10초 식사 진행을 유지한다.
- 전투 중 짝이 새로 생기거나 순서가 바뀌어도 보호 버튼의 위치/속성을 변경하지 않는다. 음식/침낭 사용과 오래된 영역은 차단한다.
- 미니맵은 기존 KHQOLMapDB.position 정규화 x/y를 사용한다. 드래그 시작은 보이는 Minimap 중심이다. 기본 Show/Hide를 표시 앵커로 전달하고 편집 모드·해제 시 소유권이 남은 속성만 journal로 복원한다.
- 기존 메뉴바 숨김·프로필·좌표·잠금·크기·슬라이더는 유지한다. DevTools와 카탈로그는 1.11.9.3과 바이트 단위로 동일하다. 새 계측·반복 조회·전역 보호 함수 교체를 추가하지 않았다.

## 정적·모의 검증

**32개 검사 묶음 PASS. 실제 WoW Forever 검증은 NOT TESTED.**

| 검사 | 결과 |
| --- | --- |
| 이전 1.11.9.3 | 일반 버프를 앞에 넣은 음식 X 불일치, 불완전 탭 순서의 nil 비교, 하단 미니맵+KHQOL 메뉴 숨김의 음수 배율 오류를 각각 재현 |
| 수정본 짝 배치 | 네 방향 × 줄바꿈 × 각각 위/아래 × 비전투/전투 변경. X 동일·Y 간격·셀 중복 없음·보호 쓰기 금지 확인 |
| 수정본 설정 | 누락/빈 탭 순서, 유효 탭 도달 가능, 두 우클릭 설정 경로, 이벤트 후 생성, 이동/삭제 호출 없음 확인 |
| 수정본 미니맵 | 반복 Apply·하단 드래그·기본 앵커 보존·ResizeLayoutFrame 자식 제외·양수 배율·Show/Hide·부모/속성 복원 확인 |
| DevTools OFF/ON | 각각 새 검사 996개(짝 배치 961, 경로 14, 미니맵 21), 합계 1,992개 PASS |
| 기존 검사 | 이전 31개 묶음 PASS. 원본 회귀 712개 포함 |
| 설치 | 19개 폴더, 271개 Lua의 5.1 구문, XML·TOC 참조·의존성·ZIP 지문·기준 보존 확인 |

`fix93-results.json`, `audit/baseline93-reproductions.json`, `audit/integration-tests.json`에 근거를 보존했다. Python+lupa Lua5.1 가상 API 검사이며 실제 보호 상태·화면·Blizzard 실시간 ResizeLayout·FPS·Baganator 실제 입력 전파를 보증하지 않는다.

## 인게임 확인 — NOT TESTED

1. 일반 버프가 앞에 있을 때 음식이 포만감 바로 위/아래에 오는지, 크기·정렬 변경 후에도 맞는지.
2. 음식/침낭 소유·버프 조건, 10초 식사 진행, 버프 획득 후 숨김.
3. 전문기술 텍스트와 빈 커서/아이템을 든 휴지통 우클릭의 설정 진입 및 아이템 보존.
4. 하단 미니맵+KHQOL 메뉴바 숨김에서 휴지통 우클릭 및 Baganator 아이템 이동 후 새 배율 오류·행동 단축바 이상 유무.
5. 미니맵 드래그·클릭·추적·우편·낮밤·수납함·기본 편집 모드/해제·전투 복귀·리로드 위치 유지.

## 수정 파일

- KHQOL/UI/SettingsPresenter.lua, SettingsGroups.lua: 누락 순서 처리.
- KHQOL_Convenience/BuffReminder/CommonBuffs.lua, FoodUI.lua, UI.lua: 짝 연결·배치·설정 문구.
- KHQOL_Convenience/Modules/BagTrash.lua: 마우스 처리·지연 진입.
- KHQOL_Map/Minimap.lua, Core.lua: 표시 전용 앵커·복원·모듈 버전.
- 일반 18개 TOC 버전, Core/Map README·CHANGELOG·설치 안내·본 보고서. 상세 목록/지문은 CHANGED-FILES.json.

## 설치

게임 종료 후 Full ZIP의 19개 폴더를 기존 동일 이름 폴더와 교체한다. WTF/SavedVariables는 유지한다. Review는 문서·검사·기준·소스 묶음이며 설치하지 않는다. 설치본에는 테스트 도구·가상 데이터·개인 저장값이 없다.
