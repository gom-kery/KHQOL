# KHQOL 1.9.9.1 — 퀘스트 원형 상태 아이콘 복원

첨부한 최신 1.9.9를 기준으로 퀘스트 제목 왼쪽의 원형 상태 아이콘을 복원했습니다. 진행 중은 `…`, 완료·반납 가능 상태는 `?`로 표시하고, 현재 안내 중인 퀘스트는 기본 UI와 같은 밝은 원형 배경으로 구분합니다. 아이콘 왼쪽 클릭은 길 안내 선택, 오른쪽 클릭은 기존 퀘스트 메뉴입니다.

원인은 1.9.8.6의 taint 격리 전환 때 기본 퀘스트 내용 영역을 가리고 별도 목록을 만들면서 원래 POI 아이콘을 별도 행에 구현하지 않은 것입니다. 1.9.8.8의 상단 장식 제거 대상에는 퀘스트 아이콘이 포함되지 않았습니다.

기본 아이콘 atlas를 KHQOL 소유 버튼·Texture에 표시합니다. 기본 POI 풀·지도 핀·하이라이트 관리자와 공유하지 않으며, 기본 추적기 갱신 메서드·전역 함수도 변경하지 않습니다. 원형 아이콘이 스크롤 왼쪽에서 잘리지 않도록 여백을 확보하되 제목의 내용 폭과 오른쪽 기준은 유지합니다. 지역 제목 없이 퀘스트가 바로 시작하거나 팝업이 먼저 나오는 경우 첫 아이콘 위쪽에 12px 여백을 둡니다.

기존 전투 중 배치/상태 갱신 보류, 편집 모드·OFF 복원, 상단 장식 숨김, 글씨·폭·스크롤·아이템·진행 바·화살표 정책과 SavedVariables를 유지합니다. 수락 전 OFFER 팝업은 기존 표시를 유지하고, COMPLETE 팝업에는 완료 상태 아이콘을 표시합니다. 아이콘 표시는 기본 일반 퀘스트 스타일이며 분류별 특수 POI 모양·지도 핀 애니메이션 전체를 이식한 것은 아닙니다.

설치: ZIP 안의 KHQOL 폴더를 기존 애드온에 덮어쓴 뒤 `/reload`하세요. SavedVariables는 삭제하지 마세요. 실제 인게임 검증은 미실시이며 상세 원인·변경·검증 내용은 RELEASE-1.9.9.1.md 및 별도 작업보고서를 참조하세요.

1.9.9의 공용 Navigation.lua / NavigationUI.lua 분리 구조와 관련 코드를 그대로 보존합니다.

---

# Quest Navigator / Navigation Engine — KHQOL 1.9.9

퀘스트 Source는 `QuestNavigator/Core.lua`, `Tracker.lua`가 담당합니다. 공용 계산은 루트 `Navigation.lua`, 기존 화살표·거리·제목·갱신은 루트 `NavigationUI.lua`로 이동했습니다. `QuestNavigator/UI.lua`는 기존 설정과 위치 편집 진입점을 연결하는 작은 어댑터입니다.

기존 퀘스트 목록, 추적된 퀘스트만 자동 선택, 난이도/지역/거리 우선순위, 두 완료 정책과 수동 선택, 진행 문구, 지도/반납 위치 폴백, 입체 화살표와 거리 단위를 유지합니다. 설정은 기존 `/kh quest`에서 변경합니다. `/kh quest status`, `/kh quest layout` 진단 명령도 유지합니다.

SavedVariables 선언과 `KHQOLDB.modules.questNavigator` / `questTracker` 키를 변경하지 않습니다. 공용 UI는 기존 테이블을 참조하며 별도 저장소를 만들지 않습니다. 다른 Source는 아직 연결하지 않았습니다.

공용 Destination은 `{source, id, mapID, x, y, label, metadata?}`입니다. `mapID/x/y`는 유효한 값 또는 전부 nil인 미확정 목적지이며, 후자는 화살표를 그리지 않습니다. `metadata.navigation`의 선택적 priority/distanceSq는 일반 선택 힌트입니다. QuestID·완료 판정·퀘스트 API는 공용 코드가 사용하지 않습니다.

이벤트에서 Source 후보를 교체하고 현재 초점을 공용 활성 Destination으로 전달합니다. 자동 선택 시점은 기존 Quest 완료 정책이 유지하고, 후보 비교는 공용 Engine이 맡습니다. Source의 `selectedQuestID`는 네이티브 SuperTrack·완료·제거 확인용이며 화면의 좌표/각도 상태가 아닙니다.

전체 조사, 변경 파일, API, 저장 호환, 이벤트/화살표 흐름, 155개 모의 검사와 실게임 확인 목록은 `RELEASE-1.9.9.md`를 참조하세요. 실게임 검증은 별도로 필요합니다.
