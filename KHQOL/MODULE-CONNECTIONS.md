# KHQOL 1.11.4.1 공통 연결 계약

- 공통 객체는 _G.KHQOL이며 선택 모듈은 ModuleRegistry에 등록합니다. 공통 기반 KHQOL에 의존합니다. 미설치 기능의 DB와 알 수 없는 설정은 보존합니다. 기존 프로필·등록·클릭/휠·정리·전투 보류 엔진을 유지합니다.
- 파티 공용 라이브러리는 globalData.partyFrameProfiles.frameProfiles입니다. 프로필 선택·역할 연결·휠 주문은 캐릭터별입니다. 공용 라이브러리는 전체 프로필 변경으로 교체하지 않습니다.
- 각 파티 프레임 프로필은 기존 debuffs와 새 debuffTint(enabled/colors RGBA), absorb(enabled/texture/color RGBA)를 소유합니다. 파티·10·20·40인에 공통입니다. 기존 저장 키를 이동하거나 새 SavedVariables를 만들지 않습니다.
- PartyFrameEffects는 공개 설정으로 게임 CustomAuraContainer 슬롯을 초기화합니다. 오라 데이터·슬롯 상태·그림 색/표시값을 다시 읽지 않습니다. 공개 RGBA 곡선 객체를 재사용하고 우선순위/판정/해제 표시는 게임 표시기에 맡깁니다. PartyFrames 전용 XML이 아이콘 템플릿을 소유합니다.
- 보호막 값/최대치는 자체 C StatusBar로 바로 전달합니다. 실제 값의 산술·비교·문자열 변환으로 크기·표시 여부를 결정하지 않습니다. 표시기는 체력 바 오른쪽에서 역방향으로 채웁니다. 아이콘은 보호막·디버프 체력 색·사망 음영·라벨보다 위에 표시합니다.
- 새 미리보기는 고정 공개 수치와 색만 사용하며 유닛을 지정하거나 native aura 슬롯을 생성하지 않습니다. 예시 보호막 비율은 모듈 세션 필드이며 SavedVariables/프로필에 저장하지 않습니다. 상시 OnUpdate를 추가하지 않습니다.
- 플레이어/대상/주시대상은 자체 HealthDisplay를 유지합니다. 기본 플레이어 체력 geometry의 읽기/쓰기를 재도입하지 않습니다. 대상 오라 분류는 unitFrames/target/auras 경로에만 붙습니다.
- KHQOL.toc은 기존 저장 변수 10개, KHQOL_Map.toc은 계정 KHQOLMapDB 1개를 소유합니다. 전체 ZIP에는 KH_map 폴더와 KHminimapDB 저장 선언이 없습니다. 이미 있는 KHQOLMapDB가 우선입니다.
- KHQOL_Map의 자유 드래그·36px 트레이·HIGH 표시·화면 비율 위치·복원 기록을 유지합니다. 계정 미니맵 세부 설정은 전체 프로필 전송과 독립입니다.

- 전체 설정의 공용 Builder는 두 열 기준 폭 480과 숨긴 행 간격 축소를 사용합니다. DetailLayout과 편의 기능의 별도 배치도 같은 작은 화살표 접기를 사용합니다. 접기 상태는 UI.disclosureStates의 세션 값이며 모듈·유닛·부품·편집 범위로 구분하고 저장 설정과 독립입니다. 목록과 편집기·미리보기는 전체 폭입니다.
- Builder:Block은 기존 목록·편집기·조건별 화면을 섹션의 표시/높이 계산에 포함합니다. 등록 목록의 저장·취소·데이터 소유권과 실험실 잠금은 그대로입니다. 새 SavedVariables나 반복 갱신 타이머는 없습니다.

- 제목의 화살표만 26×26 버튼입니다. 제목 글자는 별도이며 기존 공용 레이아웃 옵션과 접기 상태를 유지합니다.
- 예시 디버프 색은 자체 StatusBar로 그리며 공개 예시 비율을 전달합니다. 기본 체력 채움 Texture의 크기/상태를 조회하거나 붙이지 않습니다. 실제 native 오라 표시기는 변경하지 않습니다.

- 아코디언 갱신은 현재 활성 설정 화면의 상위 배치까지 포함합니다. 중첩 DetailLayout의 행 높이·좌표도 접기/펼치기와 같은 호출에서 갱신합니다.
- 일반·프로필의 스크롤 contentHeight는 공용 Builder의 현재 reflowBottom과 여백으로 갱신합니다. 최초 생성 높이를 다시 적용하지 않습니다.

파일/로드 순서는 docs/MODULE-FILES.csv, 배포 명세는 docs/PACKAGE-MANIFEST.json에 있습니다.
