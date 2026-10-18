# KHQOL 1.11.2.5 공통 연결 계약

- 공통 객체는 _G.KHQOL이며 선택 모듈은 로드 중 ModuleRegistry에 등록합니다. 필수 의존성은 공통 기반 KHQOL입니다. 미설치/비활성 기능의 DB와 알 수 없는 설정은 보존합니다.
- 프로필·데이터 소유권·클릭/휠 실행·등록 해제·전투 보류는 기존 엔진을 유지합니다. 예약은 Own/Release/CancelWork로 현재 설정을 읽고 OFF/프로필 변경 시 정리합니다. 상시 OnUpdate를 추가하지 않습니다.
- 플레이어/대상/주시대상 간결한 체력 표시는 자체 HealthDisplay를 사용합니다. 기본 체력 바의 수치/최대치/기본 스크립트는 유지하고, 자체 표시에 값만 전달합니다. 기본 체력 바와 컨테이너의 크기·위치는 간결한 배치의 읽기/쓰기 대상이 아닙니다. 소환수/대상의 대상의 기존 배치 방식은 유지합니다.
- 기본 체력 바 컨테이너/그림/문구 억제는 기존 알파 저널을 사용하고 OFF 시 복원합니다. 자원·이름·레벨·테두리는 자체 체력 표시를 기준으로 배치합니다. 전투 중 크기·위치 쓰기는 보류합니다.
- 대상 버프 분류는 module=unitFrames, unit=target, part=auras 경로에만 붙습니다. 선호 분류는 유지하고 현재 경로와 헤더에서만 불필요 분류를 제외합니다.
- KHQOL.toc은 기존 변수 10개, KHQOL_Map.toc은 계정 KHQOLMapDB만 소유합니다. 전체 ZIP에는 KH_map과 KHminimapDB 저장 선언이 없습니다. 이미 있는 KHQOLMapDB가 우선입니다. 외부에서 옛 변수가 로드된 경우에만 남아 있는 자동 복사 기능이 동작할 수 있습니다.
- KHQOLMapDB.buttonPosition은 계정 공용 화면 비율 좌표입니다. UIParent 부모/배율1/HIGH 표시, 원래 수납 아이콘 복원 저널을 유지합니다. 계정 미니맵 세부 설정은 전체 프로필 전송과 독립입니다.
- 파티 라이브러리는 globalData.partyFrameProfiles.frameProfiles입니다. 사용 선택·역할 연결·휠 주문은 캐릭터별입니다. 공용 라이브러리는 전체 프로필 변경으로 교체하지 않습니다.

현재 파일/로드 순서는 docs/MODULE-FILES.csv, 전체 배포 명세는 docs/PACKAGE-MANIFEST.json에 있습니다.
