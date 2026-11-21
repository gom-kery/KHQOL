# KHQOL 1.12.0.1 최종 메뉴표

전체 설치 기준입니다. 기본 하위 메뉴 30개와 조건부 실험실을 유지하며 최상위만 6개로 나눕니다.

| 최상위 순서 | 최상위 | 하위 메뉴 수 | 하위 메뉴 |
| --- | --- | --- | --- |
| 1 | 캐릭터 | 5 | 유닛프레임 / 파티·공격대 프레임 / 경험치·평판 / 환경·보호막 타이머 / 버프·휴식 알림 |
| 2 | 전투 | 4 | 시전바 / 자원·스윙바 / 거리·사거리 / 전투·위협 알림 |
| 3 | 퀘스트·지도 | 6 | 퀘스트 추적 / 퀘스트 길 안내 / 미니맵 / 미니맵 버튼 / 오브젝트 강조 / 포에버 노트 |
| 4 | 생활·소통 | 6 | 가방·아이템 / 상점·수리 / 채팅·말머리 / 파티·초대 / 요청 자동 거절 / 숙련·전문기술 |
| 5 | 화면·정보 | 6 | 기본 화면·창 배치 / 기본 알림 외형 / 툴팁 / 마우스 잔상 / 시계·정보 / 알람·시간 도구 |
| 6 | 설정·프로필 | 4 | 공통 설정 / 기능 사용 관리 / 프로필·백업 / 실험실 |

설정·프로필의 4개 중 실험실은 기존 설치·잠금 조건을 따르는 조건부 진입입니다. 코어만 설치해도 최상위 6개는 유지하고 빈 카테고리는 설치 안내만 표시합니다.

| 1Depth | 2Depth | 3Depth | 화면 ID | 실제 소유 key | 이전 논리 group/tab | 대표 진입 인자 | 초기화 범위 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 캐릭터 | 유닛프레임 |  | units | unitFrames | unitFrames/units | {"module": "unitFrames", "screen": "units"} | 현재 프로필의 개인 유닛 프레임과 직업 보조 표시를 초기화합니다. 공통 직업 색상과 파티·공격대 설정은 유지합니다. |
| 캐릭터 | 파티·공격대 프레임 | 공통 표시 | party_common | partyFrames | partyFrames/common | {"tab": "common", "screen": "party_common", "module": "partyFrames"} | 현재 계정 공용 파티·공격대 역할 프로필의 표시·배치를 초기화합니다. 이 프로필을 사용하는 다른 캐릭터에도 반영됩니다. 다른 프로필과 캐릭터 휠 주문은 유지합니다. |
| 캐릭터 | 파티·공격대 프레임 | 크기·배치 | party_frames | partyFrames | partyFrames/frames | {"tab": "frames", "screen": "party_frames", "module": "partyFrames"} | 현재 계정 공용 파티·공격대 역할 프로필의 표시·배치를 초기화합니다. 이 프로필을 사용하는 다른 캐릭터에도 반영됩니다. 다른 프로필과 캐릭터 휠 주문은 유지합니다. |
| 캐릭터 | 파티·공격대 프레임 | 버프·디버프 | party_auras | partyFrames | partyFrames/auras | {"tab": "auras", "screen": "party_auras", "module": "partyFrames"} | 현재 계정 공용 파티·공격대 역할 프로필의 표시·배치를 초기화합니다. 이 프로필을 사용하는 다른 캐릭터에도 반영됩니다. 다른 프로필과 캐릭터 휠 주문은 유지합니다. |
| 캐릭터 | 파티·공격대 프레임 | 역할별 프레임 프로필 | party_roles | partyFrames | partyFrames/roles | {"tab": "roles", "screen": "party_roles", "module": "partyFrames"} | 현재 계정 공용 파티·공격대 역할 프로필의 표시·배치를 초기화합니다. 이 프로필을 사용하는 다른 캐릭터에도 반영됩니다. 다른 프로필과 캐릭터 휠 주문은 유지합니다. |
| 캐릭터 | 경험치·평판 |  | experience | experienceBar | bars/experience | {"module": "experienceBar", "screen": "experience"} | 현재 프로필의 해당 모듈 설정을 기본값으로 복원합니다. 사용 ON/OFF는 유지합니다.<br>다른 모듈 설정과 공용 등록 데이터는 유지합니다. |
| 캐릭터 | 환경·보호막 타이머 |  | environment | environmentTimer | bars/environment | {"module": "environmentTimer", "screen": "environment"} | 현재 프로필의 해당 모듈 설정을 기본값으로 복원합니다. 사용 ON/OFF는 유지합니다.<br>다른 모듈 설정과 공용 등록 데이터는 유지합니다. |
| 캐릭터 | 버프·휴식 알림 | 버프 유지 알림 | buff | buffReminder | convenience/buff | {"module": "buffReminder", "screen": "buff"} | 현재 프로필의 해당 모듈 설정을 기본값으로 복원합니다. 사용 ON/OFF는 유지합니다.<br>직업별 등록 버프 목록은 유지합니다. |
| 캐릭터 | 버프·휴식 알림 | 모닥불 알림 | campfire | campfire | alerts/campfire | {"module": "campfire", "screen": "campfire"} | 현재 프로필의 해당 모듈 설정을 기본값으로 복원합니다. 사용 ON/OFF는 유지합니다.<br>다른 모듈 설정과 공용 등록 데이터는 유지합니다. |
| 전투 | 시전바 |  | cast | castBar | bars/cast | {"module": "castBar", "screen": "cast"} | 현재 프로필의 해당 모듈 설정을 기본값으로 복원합니다. 사용 ON/OFF는 유지합니다.<br>다른 모듈 설정과 공용 등록 데이터는 유지합니다. |
| 전투 | 자원·스윙바 |  | resource | resourceSwing | bars/resource | {"module": "resourceSwing", "screen": "resource"} | 현재 프로필의 해당 모듈 설정을 기본값으로 복원합니다. 사용 ON/OFF는 유지합니다.<br>다른 모듈 설정과 공용 등록 데이터는 유지합니다. |
| 전투 | 거리·사거리 |  | range | range | interface/range | {"module": "range", "screen": "range"} | 현재 프로필의 해당 모듈 설정을 기본값으로 복원합니다. 사용 ON/OFF는 유지합니다.<br>다른 모듈 설정과 공용 등록 데이터는 유지합니다. |
| 전투 | 전투·위협 알림 | 전투 시작·종료 | combat | combatStatus | alerts/combat | {"module": "combatStatus", "screen": "combat"} | 현재 프로필의 해당 모듈 설정을 기본값으로 복원합니다. 사용 ON/OFF는 유지합니다.<br>다른 모듈 설정과 공용 등록 데이터는 유지합니다. |
| 전투 | 전투·위협 알림 | 위협 수치·어그로 | threat | threat | alerts/threat | {"module": "threat", "screen": "threat"} | 현재 프로필의 해당 모듈 설정을 기본값으로 복원합니다. 사용 ON/OFF는 유지합니다.<br>다른 모듈 설정과 공용 등록 데이터는 유지합니다. |
| 퀘스트·지도 | 퀘스트 추적 |  | tracker | questNavigator | quest/tracker | {"tab": "tracker", "screen": "tracker", "module": "questNavigator"} | 현재 프로필의 해당 모듈 설정을 기본값으로 복원합니다. 사용 ON/OFF는 유지합니다.<br>다른 모듈 설정과 공용 등록 데이터는 유지합니다. |
| 퀘스트·지도 | 퀘스트 길 안내 |  | navigation | questNavigator | quest/navigation | {"tab": "navigation", "screen": "navigation", "module": "questNavigator"} | 현재 프로필의 해당 모듈 설정을 기본값으로 복원합니다. 사용 ON/OFF는 유지합니다.<br>다른 모듈 설정과 공용 등록 데이터는 유지합니다. |
| 퀘스트·지도 | 미니맵 |  | minimap | minimap | minimap/minimap | {"tab": "minimap", "screen": "minimap", "module": "minimap"} | 계정 공용 미니맵·버튼 정리 설정과 위치·보관 제외 목록을 기본값으로 복원합니다. 다른 모듈과 현재 프로필의 사용 ON/OFF는 유지합니다. |
| 퀘스트·지도 | 미니맵 버튼 |  | minimapButtons | minimap | minimap/minimapButtons | {"tab": "minimapButtons", "screen": "minimapButtons", "module": "minimap"} | 계정 공용 미니맵·버튼 정리 설정과 위치·보관 제외 목록을 기본값으로 복원합니다. 다른 모듈과 현재 프로필의 사용 ON/OFF는 유지합니다. |
| 퀘스트·지도 | 오브젝트 강조 |  | highlight | objectHighlight | convenience/highlight | {"module": "objectHighlight", "screen": "highlight"} | 현재 프로필의 오브젝트 강조를 OFF로 초기화하고 KHQOL이 변경한 그래픽 설정을 안전하게 복원합니다.<br>복원 실패 시 필요한 기록은 유지합니다. 효과 해제에는 게임 재시작이 필요할 수 있습니다. |
| 퀘스트·지도 | 포에버 노트 |  | note | todo | convenience/note | {"module": "todo", "screen": "note"} | 현재 프로필의 해당 모듈 설정을 기본값으로 복원합니다. 사용 ON/OFF는 유지합니다.<br>노트 내용·체크리스트·완료 상태·알람 문구는 유지합니다. |
| 생활·소통 | 가방·아이템 |  | bags | generalConvenience | convenience/general | {"module": "generalConvenience", "screen": "bags"} | 현재 프로필의 가방·아이템, 상점·수리, 요청 자동 거절, 대화창 편의·버프 감사 알림 설정을 함께 복원합니다. 파티 버튼과 계정 공용 아이템 보호 목록은 유지합니다. |
| 생활·소통 | 상점·수리 |  | merchant | generalConvenience | convenience/general | {"module": "generalConvenience", "screen": "merchant"} | 현재 프로필의 가방·아이템, 상점·수리, 요청 자동 거절, 대화창 편의·버프 감사 알림 설정을 함께 복원합니다. 파티 버튼과 계정 공용 아이템 보호 목록은 유지합니다. |
| 생활·소통 | 채팅·말머리 | 대화창·버프 감사 알림 | communication | generalConvenience | convenience/general | {"module": "generalConvenience", "screen": "communication"} | 현재 프로필의 가방·아이템, 상점·수리, 요청 자동 거절, 대화창 편의·버프 감사 알림 설정을 함께 복원합니다. 파티 버튼과 계정 공용 아이템 보호 목록은 유지합니다. |
| 생활·소통 | 채팅·말머리 | 말머리 | chat | convenienceChat | convenience/chat | {"module": "convenienceChat", "screen": "chat"} | 현재 프로필의 말머리 사용 설정을 복원합니다. 캐릭터별 말머리 문구는 유지합니다. |
| 생활·소통 | 파티·초대 |  | party | convenienceParty | convenience/party | {"module": "convenienceParty", "screen": "party"} | 현재 프로필의 파티 버튼 위치·메시지와 자동 인사 옵션을 복원합니다. 표시 설정과 캐릭터별 자동 인사 문구는 유지합니다. |
| 생활·소통 | 요청 자동 거절 |  | decline | generalConvenience | convenience/general | {"module": "generalConvenience", "screen": "decline"} | 현재 프로필의 가방·아이템, 상점·수리, 요청 자동 거절, 대화창 편의·버프 감사 알림 설정을 함께 복원합니다. 파티 버튼과 계정 공용 아이템 보호 목록은 유지합니다. |
| 생활·소통 | 숙련·전문기술 | 전문기술 | professions | professions | convenience/professions | {"module": "professions", "screen": "professions"} | 현재 프로필의 해당 모듈 설정을 기본값으로 복원합니다. 사용 ON/OFF는 유지합니다.<br>다른 모듈 설정과 공용 등록 데이터는 유지합니다. |
| 생활·소통 | 숙련·전문기술 | 무기 전문가 안내 | weaponGuide | tooltip | interface/tooltip | {"module": "tooltip", "screen": "weaponGuide"} | 현재 프로필의 해당 모듈 설정을 기본값으로 복원합니다. 사용 ON/OFF는 유지합니다.<br>다른 모듈 설정과 공용 등록 데이터는 유지합니다. |
| 화면·정보 | 기본 화면·창 배치 |  | basic | basicUI | interface/basic | {"module": "basicUI", "screen": "basic"} | 현재 프로필의 해당 모듈 설정을 기본값으로 복원합니다. 사용 ON/OFF는 유지합니다.<br>다른 모듈 설정과 공용 등록 데이터는 유지합니다. |
| 화면·정보 | 기본 알림 외형 |  | nativeAlerts | basicUI | interface/basic | {"module": "basicUI", "screen": "nativeAlerts"} | 현재 프로필의 해당 모듈 설정을 기본값으로 복원합니다. 사용 ON/OFF는 유지합니다.<br>다른 모듈 설정과 공용 등록 데이터는 유지합니다. |
| 화면·정보 | 툴팁 |  | tooltip | tooltip | interface/tooltip | {"module": "tooltip", "screen": "tooltip"} | 현재 프로필의 해당 모듈 설정을 기본값으로 복원합니다. 사용 ON/OFF는 유지합니다.<br>다른 모듈 설정과 공용 등록 데이터는 유지합니다. |
| 화면·정보 | 마우스 잔상 |  | cursor | cursorTrail | interface/cursor | {"module": "cursorTrail", "screen": "cursor"} | 현재 프로필의 해당 모듈 설정을 기본값으로 복원합니다. 사용 ON/OFF는 유지합니다.<br>다른 모듈 설정과 공용 등록 데이터는 유지합니다. |
| 화면·정보 | 시계·정보 |  | clock | clock | interface/clock | {"module": "clock", "screen": "clock"} | 현재 프로필의 시계·정보와 알람·시간 도구 설정을 함께 초기화합니다. 사용 ON/OFF와 노트 설정·내용·체크리스트·알람 문구는 유지합니다. |
| 화면·정보 | 알람·시간 도구 |  | timeTools | clock | interface/clock | {"module": "clock", "screen": "timeTools"} | 현재 프로필의 시계·정보와 알람·시간 도구 설정을 함께 초기화합니다. 사용 ON/OFF와 노트 설정·내용·체크리스트·알람 문구는 유지합니다. |
| 설정·프로필 | 공통 설정 |  | common | 코어 도구 | / | {"module": "general", "screen": "common"} | 기존 도구/잠금 조건 |
| 설정·프로필 | 기능 사용 관리 |  | modules | 코어 도구 | / | {"module": "general", "screen": "modules"} | 기존 도구/잠금 조건 |
| 설정·프로필 | 프로필·백업 |  | profiles | 코어 도구 | / | {"module": "profiles", "screen": "profiles"} | 기존 도구/잠금 조건 |
| 설정·프로필 | 실험실 |  | labs | 코어 도구 | / | {"module": "labs", "screen": "labs"} | 기존 도구/잠금 조건 |

## 기존 진입 호환

| 이전 진입 | 결과 |
| --- | --- |
| 캐릭터·전투 이름 검색 | 이전 이름을 별칭으로 보존 |
| character + tab=cast / screen=resource | 전투의 시전바 / 자원·스윙바 |
| character + tab=party_roles | 캐릭터 > 파티·공격대 프레임 > 역할별 프레임 프로필 |
| combat / alerts / bars 등 기존 호출 | 기존 화면·소유자로 정규화. battle 페이지 ID와 충돌 없음 |
| 자원·스윙바 명령어 | 전투의 해당 화면을 열고 같은 화면에서 다시 실행하면 닫음 |
| 깊은 선택 | 기존 unit/part/category/castUnit/sideTarget/tab/section 보존 |

## 주요 기능 60개 새 경로

| ID | 기능 | 1.12.0 경로 | 1.12.0.1 경로 | 소유자 | 결과 |
| --- | --- | --- | --- | --- | --- |
| F001 | 가방 휴지통 | 생활·소통 > 가방·아이템 | 생활·소통 > 가방·아이템 | generalConvenience | PASS |
| F002 | 자동 거절 | 생활·소통 > 요청 자동 거절 | 생활·소통 > 요청 자동 거절 | generalConvenience | PASS |
| F003 | 버프 알림 | 생활·소통 > 채팅·말머리 > 대화창·버프 감사 알림 | 생활·소통 > 채팅·말머리 > 대화창·버프 감사 알림 | generalConvenience | PASS |
| F004 | 기본 대화창 편의 | 생활·소통 > 채팅·말머리 > 대화창·버프 감사 알림 | 생활·소통 > 채팅·말머리 > 대화창·버프 감사 알림 | generalConvenience | PASS |
| F005 | 상인 판매목록 확장 | 생활·소통 > 상점·수리 | 생활·소통 > 상점·수리 | generalConvenience | PASS |
| F006 | 착용 아이템 레벨 표시 | 생활·소통 > 가방·아이템 | 생활·소통 > 가방·아이템 | generalConvenience | PASS |
| F007 | 퀘스트 보상 최고 판매가 표시 | 생활·소통 > 가방·아이템 | 생활·소통 > 가방·아이템 | generalConvenience | PASS |
| F008 | 아이템 파괴 자동 입력 | 생활·소통 > 가방·아이템 | 생활·소통 > 가방·아이템 | generalConvenience | PASS |
| F009 | 잡템 자동 판매 | 생활·소통 > 상점·수리 | 생활·소통 > 상점·수리 | generalConvenience | PASS |
| F010 | 자동 수리 | 생활·소통 > 상점·수리 | 생활·소통 > 상점·수리 | generalConvenience | PASS |
| F011 | 이미 습득한 아이템 표시 | 생활·소통 > 가방·아이템 | 생활·소통 > 가방·아이템 | generalConvenience | PASS |
| F012 | 대화 말머리 | 생활·소통 > 채팅·말머리 > 말머리 | 생활·소통 > 채팅·말머리 > 말머리 | convenienceChat | PASS |
| F013 | 파티 버튼 | 생활·소통 > 파티·초대 | 생활·소통 > 파티·초대 | convenienceParty | PASS |
| F014 | 파티 초대 | 생활·소통 > 파티·초대 | 생활·소통 > 파티·초대 | convenienceParty | PASS |
| F015 | 파티 자동 인사 | 생활·소통 > 파티·초대 | 생활·소통 > 파티·초대 | convenienceParty | PASS |
| F016 | 전문기술 버튼·숙련도 표시 | 생활·소통 > 숙련·전문기술 > 전문기술 | 생활·소통 > 숙련·전문기술 > 전문기술 | professions | PASS |
| F017 | 부캐 전문기술 조회 | 생활·소통 > 숙련·전문기술 > 전문기술 | 생활·소통 > 숙련·전문기술 > 전문기술 | professions | PASS |
| F018 | 숙련 단계·습득처 안내 | 생활·소통 > 숙련·전문기술 > 전문기술 | 생활·소통 > 숙련·전문기술 > 전문기술 | professions | PASS |
| F019 | 버프 누락·만료 알림 | 캐릭터·전투 > 버프·휴식 알림 > 버프 유지 알림 | 캐릭터 > 버프·휴식 알림 > 버프 유지 알림 | buffReminder | PASS |
| F020 | 음식·포만감 알림 | 캐릭터·전투 > 버프·휴식 알림 > 버프 유지 알림 | 캐릭터 > 버프·휴식 알림 > 버프 유지 알림 | buffReminder | PASS |
| F021 | 침낭·휴식 알림 | 캐릭터·전투 > 버프·휴식 알림 > 버프 유지 알림 | 캐릭터 > 버프·휴식 알림 > 버프 유지 알림 | buffReminder | PASS |
| F022 | 주술사 무기·토템 알림 | 캐릭터·전투 > 버프·휴식 알림 > 버프 유지 알림 | 캐릭터 > 버프·휴식 알림 > 버프 유지 알림 | buffReminder | PASS |
| F023 | 퀘스트 오브젝트 반짝임 | 퀘스트·지도 > 오브젝트 강조 | 퀘스트·지도 > 오브젝트 강조 | objectHighlight | PASS |
| F024 | 채집 오브젝트 강조 | 퀘스트·지도 > 오브젝트 강조 | 퀘스트·지도 > 오브젝트 강조 | objectHighlight | PASS |
| F025 | 노트·체크리스트 | 퀘스트·지도 > 포에버 노트 | 퀘스트·지도 > 포에버 노트 | todo | PASS |
| F026 | 지도 좌표·핀 관리 | 퀘스트·지도 > 포에버 노트 | 퀘스트·지도 > 포에버 노트 | todo | PASS |
| F027 | 길 안내·경로 관리 | 퀘스트·지도 > 포에버 노트 | 퀘스트·지도 > 포에버 노트 | todo | PASS |
| F028 | 가방·메뉴바 표시 제어 | 화면·정보 > 기본 화면·창 배치 | 화면·정보 > 기본 화면·창 배치 | basicUI | PASS |
| F029 | Blizzard 기본창 이동 | 화면·정보 > 기본 화면·창 배치 | 화면·정보 > 기본 화면·창 배치 | basicUI | PASS |
| F030 | 주사위 굴림 외형 | 화면·정보 > 기본 알림 외형 | 화면·정보 > 기본 알림 외형 | basicUI | PASS |
| F031 | 도안 습득 알림 | 화면·정보 > 기본 알림 외형 | 화면·정보 > 기본 알림 외형 | basicUI | PASS |
| F032 | 툴팁 정보 확장 | 화면·정보 > 툴팁 | 화면·정보 > 툴팁 | tooltip | PASS |
| F033 | 무기 전문가 안내 | 생활·소통 > 숙련·전문기술 > 무기 전문가 안내 | 생활·소통 > 숙련·전문기술 > 무기 전문가 안내 | tooltip | PASS |
| F034 | 마우스 잔상 | 화면·정보 > 마우스 잔상 | 화면·정보 > 마우스 잔상 | cursorTrail | PASS |
| F035 | 대상·마우스오버 사거리 표시 | 캐릭터·전투 > 거리·사거리 | 전투 > 거리·사거리 | range | PASS |
| F036 | 시계·날짜 표시 | 화면·정보 > 시계·정보 | 화면·정보 > 시계·정보 | clock | PASS |
| F037 | 소지금·성능 정보 표시 | 화면·정보 > 시계·정보 | 화면·정보 > 시계·정보 | clock | PASS |
| F038 | 길드 접속 정보 | 화면·정보 > 시계·정보 | 화면·정보 > 시계·정보 | clock | PASS |
| F039 | 알람·타이머·스톱워치 | 화면·정보 > 알람·시간 도구 | 화면·정보 > 알람·시간 도구 | clock | PASS |
| F040 | 미니맵 외형 | 퀘스트·지도 > 미니맵 | 퀘스트·지도 > 미니맵 | minimap | PASS |
| F041 | 지역명·주변 정보 표시 | 퀘스트·지도 > 미니맵 | 퀘스트·지도 > 미니맵 | minimap | PASS |
| F042 | 미니맵 버튼 수납·정리 | 퀘스트·지도 > 미니맵 버튼 | 퀘스트·지도 > 미니맵 버튼 | minimap | PASS |
| F043 | 경험치·휴식 경험치 바 | 캐릭터·전투 > 경험치·평판 | 캐릭터 > 경험치·평판 | experienceBar | PASS |
| F044 | 퀘스트 완료 예상 경험치 | 캐릭터·전투 > 경험치·평판 | 캐릭터 > 경험치·평판 | experienceBar | PASS |
| F045 | 평판 표시 연동 | 캐릭터·전투 > 경험치·평판 | 캐릭터 > 경험치·평판 | experienceBar | PASS |
| F046 | 플레이어 시전 바 | 캐릭터·전투 > 시전바 | 전투 > 시전바 | castBar | PASS |
| F047 | 대상 시전 바 | 캐릭터·전투 > 시전바 | 전투 > 시전바 | castBar | PASS |
| F048 | 자원 바 | 캐릭터·전투 > 자원·스윙바 | 전투 > 자원·스윙바 | resourceSwing | PASS |
| F049 | 스윙 바 | 캐릭터·전투 > 자원·스윙바 | 전투 > 자원·스윙바 | resourceSwing | PASS |
| F050 | 콤보 포인트 | 캐릭터·전투 > 자원·스윙바 | 전투 > 자원·스윙바 | resourceSwing | PASS |
| F051 | 드루이드 변신 마나 | 캐릭터·전투 > 자원·스윙바 | 전투 > 자원·스윙바 | resourceSwing | PASS |
| F052 | 환경 타이머 (호흡·피로도·죽은척) | 캐릭터·전투 > 환경·보호막 타이머 | 캐릭터 > 환경·보호막 타이머 | environmentTimer | PASS |
| F053 | 보호막 지속 시간·흡수량 표시 | 캐릭터·전투 > 환경·보호막 타이머 | 캐릭터 > 환경·보호막 타이머 | environmentTimer | PASS |
| F054 | 전투 시작·종료 알림 | 캐릭터·전투 > 전투·위협 알림 > 전투 시작·종료 | 전투 > 전투·위협 알림 > 전투 시작·종료 | combatStatus | PASS |
| F055 | 위협 수치·어그로 알림 | 캐릭터·전투 > 전투·위협 알림 > 위협 수치·어그로 | 전투 > 전투·위협 알림 > 위협 수치·어그로 | threat | PASS |
| F056 | 모닥불 효과 알림 | 캐릭터·전투 > 버프·휴식 알림 > 모닥불 알림 | 캐릭터 > 버프·휴식 알림 > 모닥불 알림 | campfire | PASS |
| F057 | 퀘스트 목록·진행도 표시 | 퀘스트·지도 > 퀘스트 추적 | 퀘스트·지도 > 퀘스트 추적 | questNavigator | PASS |
| F058 | 퀘스트 길 안내·화살표 HUD | 퀘스트·지도 > 퀘스트 길 안내 | 퀘스트·지도 > 퀘스트 길 안내 | questNavigator | PASS |
| F059 | 퀘스트 자동 선택 | 퀘스트·지도 > 퀘스트 길 안내 | 퀘스트·지도 > 퀘스트 길 안내 | questNavigator | PASS |
| F060 | 프로필 관리·백업·복원 | 설정·프로필 > 프로필·백업 | 설정·프로필 > 프로필·백업 | profiles | PASS |
