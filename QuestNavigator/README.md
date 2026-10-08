# Quest Navigator / Navigation Engine — KHQOL 1.9.9

퀘스트 Source는 `QuestNavigator/Core.lua`, `Tracker.lua`가 담당합니다. 공용 계산은 루트 `Navigation.lua`, 기존 화살표·거리·제목·갱신은 루트 `NavigationUI.lua`로 이동했습니다. `QuestNavigator/UI.lua`는 기존 설정과 위치 편집 진입점을 연결하는 작은 어댑터입니다.

기존 퀘스트 목록, 추적된 퀘스트만 자동 선택, 난이도/지역/거리 우선순위, 두 완료 정책과 수동 선택, 진행 문구, 지도/반납 위치 폴백, 입체 화살표와 거리 단위를 유지합니다. 설정은 기존 `/kh quest`에서 변경합니다. `/kh quest status`, `/kh quest layout` 진단 명령도 유지합니다.

SavedVariables 선언과 `KHQOLDB.modules.questNavigator` / `questTracker` 키를 변경하지 않습니다. 공용 UI는 기존 테이블을 참조하며 별도 저장소를 만들지 않습니다. 다른 Source는 아직 연결하지 않았습니다.

공용 Destination은 `{source, id, mapID, x, y, label, metadata?}`입니다. `mapID/x/y`는 유효한 값 또는 전부 nil인 미확정 목적지이며, 후자는 화살표를 그리지 않습니다. `metadata.navigation`의 선택적 priority/distanceSq는 일반 선택 힌트입니다. QuestID·완료 판정·퀘스트 API는 공용 코드가 사용하지 않습니다.

이벤트에서 Source 후보를 교체하고 현재 초점을 공용 활성 Destination으로 전달합니다. 자동 선택 시점은 기존 Quest 완료 정책이 유지하고, 후보 비교는 공용 Engine이 맡습니다. Source의 `selectedQuestID`는 네이티브 SuperTrack·완료·제거 확인용이며 화면의 좌표/각도 상태가 아닙니다.

전체 조사, 변경 파일, API, 저장 호환, 이벤트/화살표 흐름, 155개 모의 검사와 실게임 확인 목록은 `RELEASE-1.9.9.md`를 참조하세요. 실게임 검증은 별도로 필요합니다.
