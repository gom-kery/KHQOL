# KHQOL 1.11.6.0 — 최종 안정화 연결

배포 `KHQOL-1.11.6.0-최종안정화.zip` · 기준 1.11.5.11. 19개 폴더 · 논리 모듈 27개 · 287파일 · Lua 207개 · XML 6개 · 미디어 32개 · 저장 변수 11개.

Labs는 buffReminder/procAlert/objectHighlight를 제공합니다. frameInspector/performanceMonitor 구현·등록·UI/위치/명령 연결을 제거하고 과거 비활성 저장 데이터는 보관합니다. 공통 UI/프로필/Navigation 엔진과 나머지 모듈 기본값은 유지합니다.

QuestNavigator의 점선 표시는 Clock의 기존 todo.navigation.pinLines.visible을 사용합니다. Clock 없는 구성은 비활성, ON/OFF는 기존 지도 갱신 경로로 즉시 반영합니다. 새 저장 키/의존성/엔진/타이머는 없습니다. NoteMapPins는 회전 CVar만 미니맵에 반영하며, ClockTools는 스톱워치 표시 초를 캐시합니다. Core의 구형 버튼 처리는 이름 목록으로 각 존재 여부를 확인합니다.

현재 계약·성능/데이터 검증·보류 항목은 CHANGE-VALIDATION-REPORT.md를 따릅니다. 아래는 **이전 버전 설계 기록**이며 제거 도구/점선 설정/배포 정보는 위의 현재 계약이 우선합니다.

---

# KHQOL 1.11.5.11 — 경로 그리기 계약

설치 ZIP: `KHQOL-1.11.5.11-경로그리기.zip`. Clock은 NoteRouteNavigation 다음/NoteMapPins 앞에 NoteRouteDrawing을 로드합니다. 새 저장 변수는 없습니다. 새 Lua 1개와 native 지도 표시줄을 추가하며 기존 엔진/화살표를 재사용합니다.

입력은 BeginTodoRouteDrawing → OnTodoMapCanvasClick/핀 좌클릭 → AddTodoDrawingPin → 기존 ChangeTodoPinRoute 검증/저장 → native 핀·선·순번/표시줄 갱신 순서입니다. FinishTodoRouteDrawing은 완료 또는 기존 저장 경로 안내로 전환합니다. 일반 입력은 모드 밖에서 그대로 유지합니다.

그리기 중 전체 선택 경로를 미리보기하고 안내 중에는 내 위치→현재 핀→남은 경로를 표시합니다. 새 계약과 검증 범위는 CHANGE-VALIDATION-REPORT.md를 따릅니다. 아래는 **이전 버전 설계 기록**이며 현재의 입력/표시 계약은 이 문단이 우선합니다.

---

# KHQOL 1.11.5.10 — 현재 경유지와 남은 경로 표시

배포: `KHQOL-1.11.5.10-남은경로-안내.zip` · 기준 1.11.5.9.

NotePinRoutes:GetTodoPinRouteDisplayStart는 실제 Navigation 목적지와 선택 경로를 대조합니다. 명시 경로는 세션 index, 일반 노트 안내는 그 핀의 경로 위치를 사용합니다. 표시 캐시는 현재 이전의 핀을 가리고 전체 항목 lookup은 유지합니다. 기본 선은 현재→이후만 그려 기존 진입 구간을 플레이어→현재 선으로 대체합니다.

NoteCoordinates의 기존 driver는 실제 대상이 바뀔 때 공급자의 핀/선을 함께 갱신하고, 단순 이동에서는 선 위치만 갱신합니다. 기존 엔진/화살표/저장 구조·필터·우선순위는 유지합니다. 저장된 전체 route.pinIDs를 잘라 쓰지 않습니다. 이전/재시작/종료 때 현재 상태에서 표시 범위를 다시 계산합니다.

현재 계약은 CHANGE-VALIDATION-REPORT.md를 따릅니다. 다음은 **이전 1.11.5.9 설계 기록**이며 ‘안내 중 전체 과거 선 유지’는 새 정책으로 대체합니다.

---

# KHQOL 1.11.5.9 — 현재 위치와 실제 안내 핀 연결

배포: `KHQOL-1.11.5.9-첫핀-접근안내.zip` · 기준 1.11.5.8.

NotePinRoutes:GetTodoPinLineTarget은 기존 Navigation의 현재 노트 목적지를 읽습니다. 저장 경로와 일반 ForeverNote 안내가 동일한 플레이어 접근선을 사용합니다. Clock/Navigation은 목적지 게시·수동 선택 직후 선을 갱신하고, NoteCoordinates의 기존 driver는 열린 지도에서 이동을 반영합니다. NoteMapPins는 지도 표시 수명에 갱신을 맞춥니다. 새 엔진/HUD/설정/저장 형식은 없습니다.

현재 수정·검증 계약은 CHANGE-VALIDATION-REPORT.md를 따릅니다. 다음은 **기존 1.11.5.8 설계 기록**입니다.

---

# KHQOL 1.11.5.8 — 저장 경로와 기존 Navigation 통합

배포: `KHQOL-1.11.5.8-경로저장-순차안내.zip` · 기준 1.11.5.7.

NoteRouteStore는 계정 공용 콘텐츠와 기존 경로 이전, NoteRouteNavigation은 런타임 순차 안내 상태를 관리합니다. 기존 Navigation 엔진에 명시 경로 선택을 덧씌우고, NavigationUI의 같은 HUD/driver를 사용합니다. NotePinRoutes는 전체 기본 선과 플레이어→현재 구간을 그립니다. 기존 좌표계/지도 공급자/미니맵 풀/프로필 콘텐츠 정책은 재사용합니다.

로드: NoteCoordinates → NoteMapGeometry → **NoteRouteStore → NotePinRoutes → NoteRouteNavigation** → NoteMapPins → NoteMinimapPins → XML/노트 UI. 이후 기존 Clock 초기화가 기본값을 합칩니다. 경로 제어는 사용자 시작 때만 활성화합니다.

우선순위: 명시 경로 > 기존 수동 목적지 > 기존 자동 Quest/ForeverNote. 수동 객체와 native 퀘스트 추적 상태는 덮어쓰지 않습니다. 종료/완료 시 override만 제거하고 최신 정책을 다시 선택합니다.

현재 계약/저장 구조/무결성/갱신 주기/검증은 [변경·검증 보고서](CHANGE-VALIDATION-REPORT.md), 도로 탐색 설계는 [기술 검토](ROAD-NAVIGATION-RESEARCH.md)를 따릅니다. 다음은 **이전 1.11.5.7의 설계 기록**이며 안내 시작/우선순위는 현재 문서를 우선합니다.

---

# KHQOL 1.11.5.7 지도·미니맵 핀 경로

전체 ZIP: `KHQOL-1.11.5.7-지역간경로-미니맵핀.zip`. 공용 ordered pinIDs와 원래 mapID/좌표를 유지하면서 현재 지도에 투영합니다. NoteMapGeometry는 공개 좌표 계산, NoteMinimapPins는 주변/목적지 풀, NotePinRoutes는 순서·안내·점선 표시를 담당합니다. 상세 계약과 제한은 CHANGE-VALIDATION-REPORT.md를 따릅니다.

아래는 이전 버전의 설계 기록입니다.

---

# KHQOL 1.11.5.5 노트 핀 연결선

기존 지도·26px 아이콘·추가/삭제/좌표 편집과 길 안내 엔진을 유지합니다. 새 경로는 계정 공용 노트 mapPinRoutes의 ordered pinIDs이며 일반 핀을 자동 포함하지 않습니다. 표시 설정은 프로필 navigation.pinLines입니다. 색/투명도/굵기는 기존 Builder를 사용합니다.

NotePinRoutes.lua는 노트 ID/좌표를 재사용하며 native MapCanvas 공급자 알림과 같은 scroll child에서만 표시합니다. 최대 128개 선택 핀·512개 재사용 점·비입력 하위 레이어, API 실패 시 선만 숨김. 선 전용 OnUpdate/Ticker는 없습니다. 순서 변경은 Navigation Source를 다시 구성하지 않습니다. 자세한 분석/범위는 CHANGE-VALIDATION-REPORT.md를 따릅니다.

전체 ZIP: `KHQOL-1.11.5.5-지도핀-점선연결.zip`. 아래는 이전 버전의 기록입니다.

---

# KHQOL 1.11.5.2 노트 지도 핀

아이콘을 가리는 추가 배경·링 레이어를 제거합니다. 26×26 프레임에 KHQOL 원본 TGA만 전체 크기로 표시합니다. 풀 재사용 시에도 크기26·전체 UV·흰색·불투명·비탈색·BLEND를 재적용합니다. 원본 미디어 파일은 변경하지 않습니다. 아래 40px 장식은 과거 기록입니다.

---

# KHQOL 1.11.5.1 노트 지도 핀 (과거 기록)

지도 핀은 기존 TGA를 유지하고 40px 프레임 안의 36px 아이콘·어두운 배경·밝은 테두리로 구분합니다. 기본 MapCanvas 최상위 핀 레이어, 고정 화면 크기, 전체 불투명도를 사용합니다. 확대/축소 위치 계산은 기본 핀 시스템에 맡깁니다.

Shift+우클릭은 모달 없이 즉시 추가합니다. 핀 우클릭은 기본 MenuUtil 컨텍스트 메뉴(구형 클라이언트는 드롭다운 메뉴)입니다. 해당 핀 / 지도 내 핀 / 전체 핀을 선택하면 미완료 노트 좌표 항목도 삭제합니다. 메뉴를 열 때 삭제 범위를 스냅샷하고 실행 때 프로필·지도·항목을 검증합니다. 다른 지도나 풀에서 재사용된 핀의 오래된 메뉴는 실행하지 않습니다.

노트 지도 좌표 섹션에 ‘도착한 핀 숨기기’, ‘도착한 핀 다시 표시’를 추가합니다. 기본 도착 반경은 같은 지도 10야드입니다. 노트 내용과 완료 상태는 유지합니다. 기존 최근접 선택에 도착 항목 제외를 연결하며 고정 순번·도로 경로·최단 순회 경로는 계산하지 않습니다. 다음의 1.11.5.0 모달 설계는 과거 기록입니다.

---

# KHQOL 1.11.5.0 노트 지도 좌표 (과거 기록)

1.11.4.13의 아코디언·두 열·헤더 위치 편집 체계를 유지합니다. 기존 노트 페이지에 ‘노트 지도 좌표’ 섹션만 추가합니다. 두 체크박스는 기존 Builder를 사용하며 검색에 등록합니다. 노트 사용 OFF에서는 기능을 실행하지 않습니다.

세계지도 핀은 24×24 KHQOL 미니맵 아이콘입니다. 기본 MapCanvas 핀 풀과 정규화 좌표를 사용합니다. 지도 빈 공간 Shift+우클릭만 처리하고 일반 지도 입력은 유지합니다. 추가는 메모 입력창, 삭제는 확인창을 사용합니다. 확인 중 프로필·목록·항목이 바뀌면 오래된 작업을 취소합니다. 새 위치 편집 대상은 만들지 않습니다.

---

# KHQOL 1.11.4.13 설정 배치

설정·실행 항목이 0~1개인 섹션은 화살표 없이 일반 제목과 항상 펼친 내용으로 표시합니다. 복수 항목과 가변 등록·편집 영역에 작은 화살표를 사용합니다. 설명은 항목 수에서 제외합니다. 설치 상태는 일반 헤더 [?] 툴팁이며 공용 위치 편집은 설정창 헤더에서 제공합니다.

접기·펼치기는 활성 화면의 상위 배치까지 갱신합니다. 화면 자체의 Builder는 현재 내용 높이를 스크롤 호스트에 전달합니다.

공용 Design System v2.0의 색·글꼴·입력 규칙을 유지하고, 접을 수 있는 섹션 앞에 26×26 화살표 버튼과 일반 제목을 사용합니다. 기본 섹션은 펼침, 기존 고급 섹션은 접힘을 유지합니다. 상태는 현재 세션에서만 보관합니다.

입력 옵션은 폭 480 이상에서 두 열을 사용합니다. 긴 내용과 목록·편집기는 전체 폭이며 좁은 창에서는 한 열로 표시합니다. 접힌 행은 공간을 제거하고 검색은 필요한 섹션을 펼칩니다. 데이터·실제 기능 엔진은 바꾸지 않습니다. 아래 과거 기능별 유지보수 규칙을 함께 보존합니다.

---

# KHQOL 1.11.1.0 유지보수 안내

현재 설치·공통 인터페이스·데이터 소유권·파일 위치는 FINAL-HANDOFF.md와 MODULE-CONNECTIONS.md를 따릅니다. 설정 UI의 Design System v2.0 구현을 유지했습니다.

아래는 기준본에서 보존한 과거 기능별 유지보수 규칙입니다. 단일 KHQOL 폴더 경로를 언급하면 현재 소유 애드온 폴더로 대응시킵니다. 과거 검증 문구는 실제 게임 검증 완료를 뜻하지 않습니다.

---

# KHQOL 1.10.9.0 유지보수 규칙

## 1.10.9.9 채팅 입력 내역 탐색

- 범위는 기존 기본 대화창 편의의 일반 ↑/↓ 입력 내역이다. ←/→ mode·아이템/퀘스트 tooltip·URL·시전/아이템 레벨 런타임은 변경하지 않는다.
- 1.10.8.4의 native-only 히스토리 위임을 보완한다. native AddHistoryLine/ClearHistory는 교체하지 않고 후속 훅에서 공개 전송 문구만 기존 Chat.boxes runtime record에 임시 보관한다. 입력창별 기본 32개/공개 한도 최대 128개, 문구 8192 bytes 이내, 연속 중복·공백·secret은 제외한다. 받은 채팅/전체 로그/다른 창 기록 스캔·새 SavedVariables·프로필 포함은 금지한다.
- OnArrowPressed를 새로 설치하지 않는다. 기존 자동완성 해제/복원·SetAltArrowKeyMode 처리는 유지한다. OnKeyDown 후속 훅은 일반 UP/DOWN만 처리하고 native 입력이 끝난 다음 한 번만 공개 SetText를 호출한다. 사용자 정의 방향키 스크립트, 자동완성, modifier 키는 우선한다. UTF-8·링크 문자열을 자르거나 cursor 위치를 계산하지 않고 전송 API는 호출하지 않는다.
- 처음 UP 전 초안과 입력창별 index만 보관한다. UP/DOWN 범위는 clamp하고 마지막 다음에서 초안을 복원한다. 입력 변경/OnChar/붙여넣기/창 닫기/초점 상실/OFF/기록 초기화는 pending write를 폐기한다. 연속 키는 box당 0초 단발 요청 하나로 병합하고 callback 때 최신 활성/포커스/자동완성/보호/외부 스크립트를 다시 확인한다. OnUpdate/Ticker는 추가하지 않는다.
- 재접속/reload/기능 OFF에서 임시 내역은 사라진다. 설치 전 native history 내용을 추출하지 않는다. 모의 키 이벤트/게임 기본 코드 확인은 실제 클라이언트 키보드·IME 검증과 구분한다.

## 1.10.9.8 대상 시전바 외형·착용 아이템 레벨

- CastBar/TargetStyle.lua는 기존 TargetFrame.spellbar의 공개 외형만 꾸민다. targetPosition.enabled 및 X/Y를 유지하고 targetStyle.appearance/icon/spellName을 따로 저장한다. 이전 프로필은 기본값 병합 전에 기존 플레이어 모양을 값으로 복사한다. castTime은 기존 공유 정책을 유지한다. native 값·duration·castID·barType을 읽거나 계산하지 않는다. 기본 SetUnit/이벤트/OnUpdate를 호출·교체·해제하지 않는다.
- 공개 크기·폰트·위치·장식 alpha의 소유권은 기존 BasicUI/UnitFrameDecor의 원본/마지막 적용값 정책을 재사용한다. fill texture/atlas/UV/color는 공개 확인된 원본과 실제 엔진의 마지막 적용값을 보관한다. 엔진의 fileID 변환·색 반올림을 반영하고 외부 변경은 OFF에서 덮어쓰지 않는다.
- 형상·폰트 변경은 전투 밖에서만 한다. native UpdateBarFillTexture/PlayInterruptAnims 후속 훅은 공개 설정 artwork만 쓴다. 비공개 native 색·이미지는 해석하지 않고 마지막 공개 복원값을 유지한다. 채널 방향·기본 시간 문구를 유지하고 없는 시간 영역을 복제하지 않는다. OFF는 소유한 변경만 복원한다.
- EquipmentLevels.lua는 기존 generalConvenience에 equipmentLevels=true 하나만 추가한다. 표준 Character*Slot 19개와 player inventory ID/link를 사용한다. 아이템 레벨은 상세 아이템 API의 actualItemLevel, 구 API에서는 GetItemInfo의 4번째 값이다. 최소 요구 레벨을 표시하지 않는다.
- 자체 FontString만 아이콘 TOP 안쪽 2px/중앙/12px 흰 외곽선으로 붙인다. 빈 슬롯·탄약·미확인 숫자는 표시하지 않는다. slot 클릭·드래그·수량·툴팁·다른 애드온 영역은 변경하지 않는다. 장비 교체·캐릭터창 OnShow·아이템 데이터 완료 이벤트만 사용하며 Ticker/OnUpdate는 추가하지 않는다.
- 미캐시 slot→itemID와 중복 로딩 요청만 런타임에 보관한다. 완료 이벤트에서 현재 장비를 다시 읽고 실패 이벤트는 반복 요청하지 않는다. 전투 중 첫 FontString 생성은 종료 후 재시도한다. 별도 SavedVariables/검사창/가방 변경은 없다.
- 모의 구문/동작/프로필/회귀 검사와 실제 Forever 전투·보호 엔진·렌더링 확인은 구분한다.

## 1.10.9.7 표시·위치 보완

- 미니맵 두 버튼은 HUD 편집 대상이 아니다. 기존 각도·표시 저장을 유지하고 자체 원형 드래그만 사용한다. 과거 positionLocked를 삭제하거나 전체 프로필을 마이그레이션하지 않는다.
- 대상 시전의 controlled 경로는 공개 바/루트 앵커와 사용자 X/Y만 사용한다. native smallSize/haveToT·오라 높이·시전 값을 해석하지 않는다. native SetPoint/AdjustPosition/OnShow 뒤 공개 위치를 다시 적용한다. 전투 중 명시적으로 비보호인 프레임만 허용하고 보호·상태 확인 불가·좌표 제한은 보류한다. native 스크립트·값·unit·updater를 교체하지 않는다.
- UnitFrameStatus는 기존 unitFrames의 target.monsterMarks만 소유한다. UIParent 아래 비보호 장식과 이벤트로만 갱신하며 공개 퀘스트/분류 판정만 표시한다. 별도 스캔·OnUpdate·Ticker·GUID 목록을 만들지 않는다. 생성·앵커·크기는 전투 밖에서 처리하며 전투에는 공개 표시 상태만 바꾼다. 기본 모양·OFF·대상 해제에서는 숨기고 native 장식은 기존 owner 복원 경로를 따른다.
- 상태 프록시는 실제 마크가 없어도 예시 두 개를 제공하고 기존 완료/취소 writer에만 저장한다. 신규 target.monsterMarks 기본값은 기존 MergeDefaults에 보충되고 전체 프로필/전송 schema에서 자동 포함한다.
- 휠 질문은 적용 범위 조사다. 기존 파티 보안 버튼과 캐릭터 주문·역할 프로필을 변경하지 않는다. 기본 플레이어 프레임으로 확장하거나 프로필 입력 메뉴를 삭제하지 않고 안내만 보충한다. 실제 서버 오류 원인을 모의 보안 함수 결과만으로 확정하지 않는다.

## 1.10.9.5 프로필 전송

- `ProfileTransfer.lua`는 기존 Capture/Default/ProfileName/MigrateUnitFrameSettings 계약 위에서 설정만 전송한다. `UI/ProfileTransfer.lua`는 공통 스킨의 명시적 검사·확인 창이다. 새 SavedVariables·프레임워크·외부 라이브러리를 추가하지 않는다.
- 기존 프로필 소유 범위를 허용 목록으로 고정한다. 기본값이 비어 있거나 첫 편집 때 생기는 필드만 감사한 선택 schema로 보충한다. partyFrames 역할/휠, 공용 목록, 캐릭터 주문, 잠금 인증과 런타임/복원 기록을 새 프로필 소유로 바꾸지 않는다. 알 수 없는 기존 원본 데이터는 건드리지 않고 전송에서만 제외한다.
- 전송 포맷 1·scopeVersion 1은 애드온 버전과 별개다. 전용 length-delimited parser와 Base64/Adler-32로 처리한다. load/loadstring, 실행 가능한 역직렬화, 메타테이블·함수·객체·순환 참조를 허용하지 않는다. 입력 350,000자·원문 256 KiB·문자열 8 KiB·깊이 20·노드 30,000 한도를 적용한다.
- 검사 중 쓰기는 금지한다. 유닛 마이그레이션도 복사본에서만 수행한다. 새 프로필 추가 한 번만 commit하며 SaveCurrentProfile/SelectProfile·개인 DB·캐릭터 연결에 쓰지 않는다. UI 버튼은 navigationOnly로 공통 Changed 저장을 호출하지 않는다.
- 미검사/입력 변경/프로필·DB·세대 변경은 확인을 무효화한다. 창 닫기·ESC·프로필 편집 정리·전투 진입에서 문자열과 검사 표를 폐기한다. 전투·편집 중 실행 거절을 유지한다. import 창은 재사용하며 상시 OnUpdate/Ticker를 추가하지 않는다.
- 동일 포맷·다른 애드온/클라이언트는 부분 호환 경고다. 지원 밖 값은 실제 leaf 수로 집계하고 제외하며 현재 기본값으로 보충한다. 향후 포맷/범위 마이그레이션은 Migrate 진입점에서 명시적으로 추가하며 최신 미지원 포맷은 거절한다. 베타/정식 API·SpellID·해상도 호환을 확인 없이 보장하지 않는다.

현재 공통 연결 계약과 다음 단계 연결 예는 [MODULE-CONNECTIONS.md](MODULE-CONNECTIONS.md)를 따른다. 아래 버전별 규칙은 변경 이력이며 현재 연결 변경은 이 문서와 공통 계약이 우선한다.

## 설치와 테마

KHQOL.toc 한 개를 사용하는 단일 애드온. 외부 설정 프레임워크와 기능별 LoD를 사용하지 않는다.
공통 회색 버튼·차콜 배경·절제된 강조색·포함 폰트를 유지한다. 설정 스킨이 게임 HUD의 사용자 색상을 덮어쓰지 않는다.

## 설정 등록과 생성

- `UI/SettingsRegistry.lua`: 페이지·세부 탭·순서·모듈 바로가기·명령어·초기화 범위의 등록 기준.
- `UI/SettingsPresenter.lua`: 등록 순서, 측정한 탭 폭과 줄바꿈, 콘텐츠 생성·캐시·선택 관리.
- `SettingsUI.lua`: 공통 창·사이드바·헤더·스크롤·현재 프로필·하단 초기화.
- `UI.lua`: 공통 컨트롤·입력·스킨·비활성 이유·변경 확정과 갱신.
- 모든 탭의 버튼/패널을 먼저 만들고 builder를 실행한다. 생성 도중 재선택·재진입을 허용하지 않는다. 성공한 페이지를 재사용한다.
- UI 갱신은 KHQOL 소유 설정 컨트롤만 대상으로 한다. UIParent/Blizzard 전체 프레임의 재귀 탐색 금지.

## 본문과 조작

주요 동작 → 위치·잠금·편집 → 크기·모양 → 고급·테스트 순서를 기본으로 한다. 기능에 없는 옵션은 만들지 않는다.
짧은 독립 옵션은 2열, 긴 등록 목록과 중요한 설명은 전체 폭. 부모 OFF 시 자식 행은 유지하고 이유를 안내한다.
모듈 토글과 개별 편의 스위치를 혼동하지 않는다. 경험치 기본 바 숨김처럼 기존 독립 옵션은 독립성을 유지한다.
폭·높이·글자는 px, 배율·투명도는 %. 좌표·계층 우선순위 등 다른 값에 잘못된 단위를 붙이지 않는다.
체크박스·슬라이더·선택 항목은 setter 종료 후 공통 저장·현재 페이지 갱신. 프로필 전환 같은 명령 동작은 일반 값 setter와 구분한다.
일반 입력 Enter/포커스 종료 확정, ESC/화면 종료 취소. 작성 중 초안을 Refresh가 덮어쓰지 않는다. 검증·등록 입력은 명시적 적용/저장 유지.
프로필·실험실 상태 변경 시 KHQOL 소유 초안·색상 창·오래된 콜백을 무효화한다. 다른 UI의 포커스나 색상 창을 일괄 조작하지 않는다.

## 위치와 저장

- `UI/PositionStore.lua`: 공개·유한 좌표, 소유 프레임 안전성, 배율 변환, 기존 앵커 저장, 적용/프로필/설정 갱신 공통 처리.
- `PositionTargets.lua`: 모듈별 기존 DB 형식, 대상 조건, 연결 관계, 크기·미리보기·초기화 adapter.
- `PositionEditor.lua`: 가상 미리보기·핸들·선택·완료·취소와 상태 전환 정리.
- 원본 HUD를 테스트 모드로 실행하여 미리보기를 만들지 않는다. 프레임·미리보기는 재사용하고 종료 시 입력·투명도·표시를 복구한다.
- 연결된 시전·콤보·마나·노트 보조 창은 부모와 함께 이동. 보호된 Blizzard 프레임 자체는 편집 대상으로 추가하지 않는다. 대상의 대상은 비보호 프록시를 드래그하고 완료 후 공개 기본 앵커에 저장 보정을 적용한다.
- 완료는 기존 소유 DB 갱신·잠금·프로필 반영. 취소/ESC/전투는 변경 전 상태 유지. 프로필/모듈/실험실/세계 변화로 오래된 작업을 무효화한다.
- 직접 드래그 종료도 기존 좌표 체계를 유지한다. 창 종료·모듈 OFF·프로필 변경 중인 드래그 정리 경로를 함께 점검한다.
- 설정창 이동 위치는 `KHQOLDB.toolWindows.settings`의 계정 공용 값. 프로필 공통 `settingsWindow` 배율·투명도와 별개. 처음 드래그할 때만 추가하며 화면에 보정한다.

## 데이터와 초기화

SavedVariables 이름과 기본값을 변경하지 않는다. 프로필 적용 시 기존 하위 테이블 참조를 유지한다.
노트 내용·완료 상태·즐겨찾기·알람 문구·버프/NPC/발동 등록 목록과 캐릭터 기준 주문은 기존 공유/개인 범위를 보존한다.
캐릭터 저장 파일의 색상도 기존 프로필 캡처/적용 정책을 유지한다. 파일 위치만 보고 프로필 제외라고 판단하지 않는다.
초기화 범위를 본문·확인창에 명시하고 현재 프로필/세션을 검증한다. 위치·모양·모듈·전체 데이터 초기화를 합치지 않는다.
오브젝트 강조는 OFF와 그래픽 원본 복원·실패 기록 유지가 한 정책이다. 전투/복원 실패 시 삭제를 강행하지 않는다.

## 버프와 알림

`AuraReader.lua`는 등록 대상의 공개 API 판정만 수행한다. 버프 렌더링·등록 편집과 분리한다.
ACTIVE/MISSING/EXPIRING/UNKNOWN을 구분한다. 보호된 nil·오류·불확실 시간은 없음/만료로 해석하지 않는다.
가능하면 개별 주문의 secret 분류를 확인한다. 전역 제한만 제공되면 보수적으로 확인 불가 처리한다. secret 우회·추정 시간 금지.
기존 이벤트/주기에서 필요한 등록 목록만 읽는다. 별도 상시 전체 스캔이나 타이머를 추가하지 않는다.
`UI/AlertLayout.lua`는 유한한 KHQOL 알림의 표시/숨김/좌표 변화에 반응한다. 우선순위가 낮은 겹침만 임시 보정하며 DB 좌표·소리·색상을 바꾸지 않는다.
테스트가 이미 표시 중인 실제 경고를 덮어쓰지 않도록 한다. 전역 큐/스캐너/다른 애드온 프레임 조작 금지.

## 실행 예외와 검증

유닛프레임은 실험실 실행 제한에서 분리했으며 기존 유닛프레임 메뉴와 사용자 ON/OFF를 따른다. 버프 리마인더는 기존 실행 예외를 유지하지만 편집 진입은 실험실 잠금 준수.
프레임 검사기는 페이지 종료 시 정지. 성능 모니터 설정 페이지 종료는 오버레이를 유지하며 도구 닫기는 모듈 OFF·측정 정지.
XP/환경/발동/PvP의 기존 런타임 잠금과 저장형 잠금을 구분한다. 설정창 종료만으로 모든 HUD를 임의 잠금하지 않는다.
검증은 정적·모의·실제 게임을 구분한다. 게임을 실행하지 않았다면 taint·secret·렌더링·성능 통과를 주장하지 않는다.
수정마다 관련 상태 변화·실제 저장 경로를 검증한다. 테스트/개발용 코드를 설치 ZIP에 넣지 않는다.

## 1.10.7.1 추가 규칙

- 설정 등록은 8개 상위/23개 세부 화면. frameMover 바로가기는 interface/basic으로 연결한다.
- 기본창 이동은 기본 UI 본문에 포함하되 상단 모듈 스위치/하단 초기화와 독립. 이동 DB의 계정 범위 유지.
- 유닛 수치 기본 모드는 원본 텍스트를 유지하며 별도 레이어를 만들거나 너비를 측정하지 않는다.
- 직접 수치는 좌우 앵커를 사용한다. secret 너비/높이/계층을 산술·비교·크기 setter에 전달하지 않는다.
- 기본 UI Write/Release는 공개 기준값만 기록하고, 확인 불가 복원 기록은 다음 안전한 이벤트까지 유지한다.
- compact 네이티브 크기가 읽히지 않으면 전체 배치를 보류하여 부분 리사이즈를 피한다.
- 자원 표시 OFF는 막대/수치 및 hover만 숨김. native 클릭 상태는 변경하지 않는다.
- showPower/healthHeight/powerHeight는 옵션 변경 시만 기록. 없는 필드는 기존 총 높이/분할/기본 표시를 유지한다.
- 지역 포커스는 기존 지역 도착 대기 완료와 autoTrack에 연결. 실제 tracker watch/header의 낮은 레벨→거리 순서.
- 지역 이동 뒤 외부 SUPER_TRACKING_CHANGED는 예약 무효화를 먼저 처리한다. 완료/반납 전환·핀·노트 수동 안내 유지.
- 거리/좌표 정보가 늦으면 기존 이벤트에서만 재시도. 추가 타이머/영구 저장 포커스/자동 추적 등록을 만들지 않는다.

## 1.10.8.3 유닛 꾸미기

- UnitFrameDecor는 texture/atlas/texcoord/hit/justify를 자체 공개 기준값과 마지막 쓰기 기록으로 복원한다. BasicUI Write가 이를 지원한다고 가정하지 않는다.
- 1.10.8.4: native RGB/atlas setter 후속 훅에서도 선택한 표시를 유지한다. 재진입 방지 상태는 owner에만 저장하며, 기본 값/수치 갱신 함수는 호출하지 않는다.
- 이름·레벨 기본 앵커와 사용자 앵커를 같은 적용에서 두 번 쓰지 않는다. 자신의 중간 쓰기를 외부 원본 변경으로 기록하지 않는다.
- 보조 유닛은 작은 기본 프레임 schema를 확인한다. 하단은 조건을 확인한 TotemFrame만 보정한다. 표시/숨김·타이머·클릭 엔진은 기본 UI가 소유한다.

- 1.10.8.3: native 체력/자원/원본 텍스트 갱신 함수를 애드온에서 직접 실행하지 않는다. 표시 속성만 복원하고 값 갱신은 게임에 맡긴다. 실제 바 callback 후속 훅은 callback 숫자 인수를 읽지 않는다. 텍스트 훅 등록 상태는 native 바 필드 대신 runtime owner에 둔다.

## 1.10.8.3 통합 유지보수

- 클래스 이름과 토큰을 한꺼번에 secret 판정하지 않는다. 사용할 반환값만 공개 여부를 확인한다.
- 다섯 유닛의 모양은 한 layout 경로를 사용하며 실제 없는 레벨 부품은 생성하지 않는다.
- 1.10.8.4: 간결한 바는 단색 사각 fill을 사용한다. 기본 체력은 녹색, 자원은 공개 자원 종류의 색이며 선택한 체력색·선점 회색을 우선한다. OFF에서 원래 atlas/UV/RGB를 복원한다.
- font 초기화는 compact ON 상태에서도 원본 크기로 복원한다. 모양 복사는 전용 기능/실제 위치/활성을 복사하지 않는다.
- 퀘스트 viewport는 native 섹션 콘텐츠 사용 높이가 아닌 컨테이너/다음 섹션 경계로 계산한다. 요청 병합과 generation/전투 정책을 유지하고 native Update/MarkDirty는 호출하지 않는다.
- 대화창 방향키의 native EditBox mode와 기본 자동완성 방향키 스크립트 조정은 유지한다. 1.10.9.9부터 UP/DOWN은 위의 bounded session mirror로 보완한다. 자동완성·사용자/다른 애드온 스크립트를 덮어쓰지 않고 UTF-8·기존 입력 처리를 유지한다.
- 기력 회복 표시의 설정·검색·지원 함수를 제거했다. 이전 키는 프로필 읽기에서 정리한다.

## 1.10.8.4 표시·입력 회귀

- RGB/UV 복원 packet은 opaque 데이터다. secret인 구성 요소를 비교·계산·문자화하지 않는다. `SetStatusBarColor`/`SetTexCoord`의 AllowedWhenTainted 선언을 확인하고 해당 엔진 setter로만 전달한다.
- FontAsset은 문자열 또는 숫자형 파일 ID일 수 있다. 원래 경로·크기·효과를 보존한다.
- 기본 위협 flash와 PetAttackModeTexture는 compact ON에서 숨기고 OFF에서 최근 native alpha로 복원한다. 위협 수치를 계산하거나 별도 빨간 테두리를 생성하지 않는다.
- 이름/레벨의 후속 native 위치·정렬·폭·폰트 변경 뒤 최신 선택을 적용한다. 전투 중 geometry/font 변경은 보류한다.
- 기본 사망 문구가 있는 대상은 사용자 수치 layer를 숨긴다. 살아 있는 0 체력을 사망으로 임의 분류하지 않는다.
- TotemFrame은 확인한 플레이어 하위 구조에서만 허용한다. native 배치·타이머·소환 취소·표시 상태를 대체하지 않는다.
- 설정 변경 후 한 번의 지연 표시 갱신을 병합한다. 프로필 세대가 바뀌었거나 해당 화면이 보이지 않으면 취소한다. 상시 업데이트를 추가하지 않는다.


## 1.10.8.5 유닛·자원 표시

- 대상·대상의 대상·주시대상 기본색은 `#00A118`. 설정색에서만 NPC 관계·선점 상태와 플레이어 직업을 판정한다. 공개된 UnitIsPlayer / UnitReaction / UnitIsTapDenied를 사용하고 제한된 판정은 녹색으로 유예한다. Lua에서 secret 상태를 비교하지 않는다.
- 중립 대상의 나와의 전투는 UnitAffectingCombat 하나로 추정하지 않는다. 공개 threat 관계 또는 플레이어/소환수 대상 여부로 확인한다. 대상의 대상 중립 NPC는 노란색 유지.
- 전사 C79C6E / 성기사 F58CBA / 사냥꾼 ABD473 / 도적 FFF569 / 사제 FFFFFF / 주술사 0070DE / 마법사 69CCF0 / 흑마법사 9482C9 / 드루이드 FF7D0A를 우선한다. 대상 계열의 class-only 선택은 비활성화. 사용자 지정 RGB는 유지한다.
- RGB/UV/alpha 복원 packet은 비교·계산·출력 없이 C 표시 setter에만 전달한다. SetStatusBarColor·SetTexture·SetAtlas·SetVertexColor 후속 훅의 자체 변경은 owner guard로 차단한다.
- PlayerFrameHealthBarAnimatedLoss의 붉은 감소 표시만 compact에서 alpha로 숨긴다. 값·애니메이션 타이밍·native updater는 수정하지 않으며 OFF에서 복원한다.
- 설정의 유닛 내부 탭은 ScrollFrame 밖 공통 창에 둔다. 선택된 모듈의 fixedHeader만 노출하고 그 높이를 스크롤 영역에서 제외한다. 탭 전환은 초안·색 선택·미리보기 취소 후 즉시 및 다음 화면 갱신한다.
- 대상의 대상 frameX/frameY는 원래 native 앵커에 대한 보정이다. 기본 SetPoint 변경 뒤 최신 원본을 추적하고 반복 적용이 누적되지 않게 한다. 전투/편집 모드에서 위치 쓰기를 보류한다.
- 휴식·전투·native 징표의 위치는 geometry owner로 복원한다. 플레이어 native 징표가 없으면 실제 공개 raid index에만 반응하는 KHQOL Texture를 사용한다. 기본 휴식 애니메이션·전투 표시 조건은 게임에 맡긴다.
- resourceTextMode 기본은 percent, 추가 선택은 current. 제한된 current·percentage는 C FontString formatter로 전달하고 미리 Lua 산술을 하지 않는다. 원래 자원 바 수치와 스윙 동작은 유지한다.
- 자동 거절 3행 배치는 해당 섹션에 한정한다. 파티 예외 두 옵션은 같은 행에 유지하고 파티 거절이 꺼지면 사용만 비활성화한다.


## 1.10.8.6 표시 분리와 대상 효과

- UnitFrameDisplay.lua의 대상·주시 체력 표시는 템플릿 없는 KHQOL StatusBar이다. native GetValue/GetMinMaxValues의 opaque 숫자를 secret 허용 C setter에 전달하며 native 값·범위·updater는 쓰거나 호출하지 않는다. native 체력 geometry·mask는 유지한다.
- 기본 숫자·사망 문구는 GetText/GetTextColor/IsShown 결과를 비교·산술 없이 C text/color/boolean alpha setter에 전달한다. 별도 표시가 native 이름·레벨을 덮지 않도록 main frame 레벨의 BACKGROUND fill과 OVERLAY 글자를 사용한다.
- native resource opacity는 opaque alpha owner로 숨김/복원한다. 값·스크립트·단위 필드는 변경하지 않는다.
- UnitFrameAuras.lua는 기본 AuraContainer의 secure inbound 최대 버프/디버프 수와 small/large size API만 사용한다. 아우라 데이터·목록·시간·비교 판정은 native에 맡긴다. 공개 아군 플레이어/공격 가능한 NPC 판정만 사용하며 unknown에서 기본으로 복원한다.
- aura 설정은 기존 값과 마지막 적용값을 추적해 native configure/anchor 뒤 다시 적용하고 OFF·카테고리 변경 시 최신 기본값을 복원한다. 위치의 공개 원본 확인이 불가능하면 적용을 보류한다. 전투 중 aura 변경은 대기한다.
- 숫자 입력의 idle 표시에는 별도 KHQOL FontString을 사용한다. EditBox native glyph 상태와 분리하되 focus에서는 native cursor/selection/draft를 유지한다. reparent/OnShow/refresh 후 display frame level을 editor보다 높인다.
- 이름 위/아래 정렬에는 4 px 안쪽 여백을 추가하지 않는다. 외부/내부 이름 위치에서는 corner side 선택을 비활성화하고 저장 선호는 보존한다.
- 이름·레벨의 사용자 RGB는 각각 따로 저장한다. native SetTextColor 후속 훅은 원래 RGBA를 opaque 복원 packet으로 보관하며 geometry를 건드리지 않고 선택색을 유지한다.
- settingsWindow.opacity는 창 전체 SetAlpha에 전달하지 않는다. 루트 alpha는 1, 기본 backdrop alpha와 grain alpha에만 적용한다. 배율의 의미는 유지한다.

## 1.10.8.7 위치 편집과 상태 그룹

- 이름 Position/Side 설정 변경은 SetLabelAnchor를 통해 X/Y를 원자적으로 0으로 바꾼다. 이름 좌표 입력 초안은 먼저 취소하고, 레벨·크기·색 변경에는 좌표 초기화를 적용하지 않는다.
- 상태·징표는 statusX/statusY 한 쌍으로 함께 이동한다. 기존 rest/combat/marker 개별 보정은 호환성을 위해 유지한다. 플레이어는 세 아이콘, 나머지 유닛은 실제 공개 raid index에 대응하는 징표를 사용한다. 새 징표 Texture도 compact/OFF 표시 조건을 따른다.
- UnitFramePositions는 읽을 수 있는 기본 바의 rect/scale만 사용해 UIParent 아래에 안전한 자체 프록시를 만든다. protected/forbidden native 유닛 프레임·아우라 자식·목록은 편집기에서 이동하거나 복제하지 않는다. 프록시 art는 타이머 없는 예시이고 편집기에서만 표시한다.
- 상태·징표와 플레이어 buffs/debuffs는 각각 별도 편집 대상이다. 대상은 native AuraContainer 하나이므로 버프/디버프를 함께 이동한다. 명시적으로 선택한 대상 유형만 해당 프록시를 만들고 좌표를 그 유형에 저장한다.
- 드래그 변화량을 UIParent와 바의 scale 비율로 변환한다. 플레이어 aura root의 크기도 기본 30 px 아이콘과 공개 iconScale/parent scale로 맞추며 native iconScale 필드나 aura updater/목록을 수정하지 않는다. native SetScale/SetPoint/UpdateGridLayout 후에는 보정만 재적용한다.
- 대상 AuraContainer의 공개 SetFlowLayoutMirroredVertically로 anchor point와 growth direction을 함께 바꾼다. native Point getter의 결과가 제한되면 공개 SetPoint 인자로 원본을 추적한다. 제한된 outgoing 인자는 기록·비교·계산하지 않고 소유권을 내려놓으며 최신 기본 배치를 보존한다.
- 위치·scale 복원은 자체 재진입 guard를 사용한다. OFF·기본 편집 모드·카테고리 변경 시 마지막 공개 기본 배치를 복원한다. 전투 중 native geometry/scale 변경은 보류한다. 편집기의 저장·취소·전투/세대 변경 보호를 그대로 사용한다.
- 대상의 두 aura 설정은 선택 유형별로 한 패널만 보여 준다. 플레이어 자신의 버프·디버프는 player.auras에 분리한다. 기존 target.auras 값은 이동·삭제·재해석하지 않는다.
- CastBar/Target.lua는 native 대상 spellbar의 값·범위·시전 updater·스크립트를 변경하거나 호출하지 않는다. 공개 native SetPoint 인자로 원본을 추적하고 outside-combat C anchor만 보정한다. compact에서는 보이는 바 하단, 기본 모양에서는 기본 대상 frame 하단을 기준으로 한다. 버프가 위로 이동하면 기본 시전바가 아우라를 따라 위로 가지 않도록 기본 하단 배치 기준을 유지하며 buffsOnTop 등 native control 필드에 쓰지 않는다.
- PositionExtras.lua는 커서 툴팁과 마우스오버 사거리 문구의 상대 보정을 고정 예시에서 편집한다. 실시간 GameTooltip의 정보·owner·활성화 함수를 읽거나 호출하지 않는다. 기본창 5종은 보호된 창 대신 안전한 프록시에서 계정 공용 CENTER/BOTTOMLEFT 위치를 저장하고 FrameMover의 원래 복원·지연 로드 동작에 맡긴다. 변경 없이 저장할 때 닫힌 창의 위치를 새로 지정하지 않는다.
- 전체 위치 대상은 27개 기능군·60개 ID로 대조한다. 모듈·하위 기능·지원 구조/직업·실험실 조건은 유지한다. 두 대상 아우라 유형은 전체 목록에 각각 포함한다. 이름·레벨 및 targettarget 상태는 targettarget 프레임 핸들에 연결하고 부모 변화량을 중복 저장하지 않는다.
- 편집기 대상 선택 메뉴와 선택 항목만 표시 옵션은 숨긴 핸들의 위치 초안을 유지한다. 겹친 항목을 선택하면 해당 핸들만 상단으로 올린다. 빈 HUD·중지된 바는 편집 문구가 읽힐 최소 크기를 사용하고 타이머가 0개인 환경 그룹은 순수 예시를 제공한다.


## 1.10.8.8 설정 경로와 UI 선호

SettingsRegistry의 9개 분류와 기존 모듈 키를 유지한다. unitFrames의 그룹만 독립 페이지로 이동했다. SettingsNavigation은 기존 컨트롤에 경로·안정적 ID·읽기/쓰기·지원 조건·저장 범위를 연결한다. SettingsIndex는 정적 소스 제목이며 사용자 데이터와 게임 상태를 색인하지 않는다. 검색은 입력 이벤트로만 실행하고 프로필 세대/검색 세대로 오래된 결과와 강조를 폐기한다.

SettingsLayout은 기존 builder의 셀과 등록된 컨트롤만 재배치한다. 부모 실제 폭 540 미만에서 1열, 그 이상에서는 기존 2열을 사용한다. 창 크기 변경은 입력 초안 취소 후 UI 레이아웃만 갱신하며 게임 HUD를 재배치하지 않는다. 기존 getter/setter와 입력 확정/취소 정책을 보존한다.

KHQOLDB.toolWindows.preferences의 width/height/unit/part/auraCategory/editorMode/editorFilter만 신규 계정 공용 UI 선호다. 기존 settingsWindow 배율/불투명도와 모듈·레거시 저장 정책을 바꾸지 않는다. 이전 버전의 필드를 삭제하거나 독립 모듈 버전을 일괄 치환하지 않는다.

위치 대상 ID 및 writer는 유지한다. unitFrames.*.root 4개는 보호된 기본 버튼의 공개 경계를 복사하는 읽기 전용 대표 프록시다. 편집 대상 메타데이터로 모듈/유닛/부품에 복귀하며 문자열로 표시 이름을 추측하지 않는다. 미세 이동도 기존 handle의 좌표를 조절하고 Finish에서만 같은 writer에 전달한다.

## 1.10.8.8 오라 배치와 전투

새 행 설정은 기본 OFF. 기존 combined size/position/x/y, 플레이어 buffs/debuffs, 대상 friendlyPlayer/attackableNPC 테이블을 보존하고 누락된 layoutEnabled/perRow/maxRows/growth만 보충한다. 대상의 분리 배치는 동일한 TargetFrameAuraContainerTemplate을 상속하는 XML 템플릿을 사용하여 native secure mixin·필터·버튼·쿨다운을 재사용한다. 게임 private aura group/pool/data를 addon Lua에서 읽지 않는다.

전투 중 ApplyTargetAuras는 이전에 적용한 설정 사본으로 공개 secure inbound size/max/enable만 재적용한다. SetPoint 등 보호된 배치 변경과 사용자 새 설정은 전투 종료 후 반영한다. 플레이어의 기존 공개 grid 버튼은 전투 밖에서만 배치하고 원래 한도·좌표·alpha를 보관/복원한다. native alpha 변경은 행 한도를 유지하고 private aura anchors는 건드리지 않는다.

검사 보고서에서는 기본 XML/secure partition 실행, 실제 렌더링과 모의 코드 검사를 구분한다. 모의 통과 수로 실제 taint 해소를 확정하지 않는다.


## 1.10.8.9

- 플레이어 초기 외형: 검증한 native PlayerFrame_UpdateArt / ToPlayerArt / ToVehicleArt 후속 훅과 entering-world 뒤 다음 프레임 적용. 전투·모듈 OFF를 확인하고 최신 DB를 읽는다. native 함수·체력값·currValue를 직접 호출하거나 변경하지 않는다. 반복 Ticker·상시 폴링은 추가하지 않는다.
- 상태 좌표: 기존 statusX/Y는 보존한다. 표시·개별 변경은 status + rest/combat/marker의 합산 좌표로 처리한다. 개별 초기화는 해당 아이콘의 합산 보정만 0으로 만든다. player 3개, target 징표 1개를 등록하고 기존 전체 핸들도 유지한다.
- 대상 오라: category.separatePositions 기본 OFF로 기존 그룹 배치를 보존한다. ON이면 기존 공통 좌표를 각 kind의 position/x/y로 최초 보충한다. native 선언형 오라 템플릿 두 개를 각각 바에 앵커한다. 행·확장 설정, 타입별 적용 snapshot, 전투 보류와 기본 복원을 유지한다. private aura 데이터나 secret 해석은 추가하지 않는다.
- 정수 표시: 정수 step 컨트롤의 formatter 입력만 반올림한다. 읽기·새로고침은 기존 DB를 변경하지 않는다. PositionStore.Round로 새 드래그 저장을 처리하며 fractional 설정·미니맵 각도는 유지한다.
- 크기 변경: 드래그 중 0.03초 단발 요청 병합. 값·폰트 전체 갱신은 종료 때 수행하고, 진행 중에는 active body 레이아웃만 갱신한다. 캐시된 builder 셀 순서·등록 패널 목록을 사용하며 숨은 페이지는 진입 때 갱신한다. close/release serial로 오래된 콜백을 무효화한다.
- 퀘스트 메뉴: tracker/navigation은 같은 questNavigator 모듈과 DB를 사용한다. route.tab을 검색·복귀 경로에 기록한다. 새 런타임 모듈·SavedVariables는 추가하지 않는다.
- 시전 메뉴: fixedHeader에 player/target 하위 탭, preferences.castUnit에 마지막 선택. route.castUnit을 검색·편집기 복귀에 사용한다. 플레이어 바 모양과 기본 대상 바 이동의 지원 범위를 구분한다.
- 신규 저장값은 기존 모듈 테이블 및 계정 공용 UI preferences 안에만 추가한다. 설치 단위 분리와 특성·파티 프레임은 ROADMAP만 기록한다.
- 문서: README는 현재 사용 안내, CHANGELOG는 보관된 최초 1.1.0부터의 버전별 기록, ROADMAP은 미구현 요청으로 구분한다. 과거 README/CHANGELOG/버전별 문서와 ZIP 이름·TOC·파일 차이를 근거로 기록한다. 이력이 없는 기능 설명·출시일을 추측하지 않는다. 이력 파일을 배포에서 제외하지 않는다.
- 개별 상태 드래그는 UI에 표시하는 합산 좌표를 정수·±400 범위로 저장한 뒤 기존 그룹 보정을 차감한다. 과거 그룹의 소수점 값은 보존할 수 있으며 내부 개별 보정이 소수라도 표시·실제 합산 좌표는 정수다. 단순 설정 새로고침은 원본 저장값을 변경하지 않는다.


## 1.10.8.10

- UI RefreshParentsFor는 KHQOL이 등록한 부모만 탐색하여 루트별 목록과 깊이를 캐시한다. 등록·해당 부모의 SetParent 뒤 revision을 바꾼다. ancestor layoutRefresh를 먼저 적용하고 보이는 부모만 갱신하며 숨은 설정은 재진입 때 현재 값을 반영한다. UIParent·Blizzard 자식은 열거하지 않는다.
- 메뉴·탭·드롭다운/색상 창 열기·검색 결과·편집 진입 버튼은 navigationOnly로 표시한다. 일반 setter는 CommitSetting 후 프로필 저장·표시 갱신을 한 번 실행한다. 선택 변경만으로 전체 프로필 사본을 만들지 않는다.
- 통합 위치 편집의 scoped shortcut은 EditorMeta groupID를 넘겨 group 모드와 해당 모듈/유닛 필터로 연다. 전체 진입은 all을 복원하며 직접 부품 드래그는 기존 part 모드를 유지한다. 저장·취소·전투 취소 정책은 유지한다.
- 툴팁 레이블 영역은 실제 글자 폭과 해당 셀 폭 안에만 생성한다. 체크 레이블 클릭은 기존 getter·availability·CommitSetting을 사용한다. Section hint는 builder reflow 목록에 포함하고 실제 설명이 없으면 mouse를 비활성화한다. 공통 색상 버튼은 swatch-aware preferred width와 변경 한 줄을 유지한다.
- 상점 폭은 공개된 유한 수에만 0.01 UI px 오차 비교를 사용한다. 기본 336 및 마지막 소유 폭을 판정하고 원래 소수점 폭으로 복원한다. 타 애드온·슬롯·페이지 크기 충돌 보호는 유지한다.
- 응급치료는 GetProfessions의 기존 항목이 없을 때만 C_SkillInfo.GetSkillLineInfoByID(129), namespaced index, legacy global skill list 순으로 조회한다. 공개 name/rank/maxRank/skillID/isHeader를 검증하고 헤더를 펼치지 않는다. 배운 실제 항목만 중복 없이 보충한다. 새 폴링은 추가하지 않는다.
- 길 안내 DB의 titleFontSize/progressFontSize는 8~30 정수, 기본 14/12다. 공용 NavigationUI HUD 글자와 완료 제목·높이에 적용한다. 추적기 fontSize와 독립이며 노트의 공용 HUD도 같은 렌더러를 사용한다.
- 체력 숫자는 THICKOUTLINE과 검정 shadow를 사용한다. native 숫자는 공개 font/shadow만 별도 runtime owner에 원본·마지막 적용값을 보관하여 OFF에서 소유한 변경만 복원한다. font 크기·텍스트·바 값·currValue는 변경하지 않는다. native font/shadow 변경은 전투에서 보류하며 사용자·mirror text는 자체 글자에 동일한 대비를 사용한다. secret text의 GetWidth 결과를 읽거나 복사하지 않는다.
- SyncHealthDisplay는 opaque 숫자를 기존 secret-capable C StatusBar setter에 계속 전달한다. InCombatLockdown 중 StatusBar Show/Hide/SetShown은 호출하지 않고 owner.healthVisibilityPending 및 모듈 pending을 표시한다. 기존 PLAYER_REGEN_ENABLED의 ApplySettings에서 현재 range/value와 compact/module 설정을 다시 읽어 표시를 적용한다. OFF 복원에서도 보류 표시를 지운다. 전투 때 저장한 오래된 희망 상태를 재생하지 않는다.
- 모의 검사에는 보호 호출을 실패시키는 combat trap, 값·범위 갱신, 읽기 실패 시 hide 보류, 종료 시 최신 상태, compact/module OFF, 5개 유닛 font 복원을 포함한다. 실제 보호 엔진·FPS·렌더링 검증과 구분한다.


## 1.10.8.11 상점 하단 장식

- MerchantBorderSource는 atlas의 C_Texture.GetAtlasInfo / 구 GetAtlasInfo에서 packed file/filename와 left/right/top/bottom UV를 검증한다. Atlas Texture의 GetTexCoord를 backing file 좌표로 가정하지 않는다. Atlas가 없는 원시 Texture만 원래 GetTexture/GetTexCoord를 사용한다.
- 좌표·크기·alpha는 공개 유한 수만 허용하고 부분 테이블·secret·오류·누락 API는 보류한다. 전체 backing texture를 대체 좌표로 복사하지 않는다. MerchantSupported에서 확인하여 원본 미확인 시 상점 배치에 진입하지 않는다.
- 원래 334×61 UI px 장식의 304 px 왼쪽 몸체와 30 px 오른쪽 끝은 같은 크기로 복사한다. 사이의 330 px 확장은 몸체 오른쪽의 빈 1 px 스트립만 사용한다. 버튼 주변 문양을 넓게 늘이지 않는다. 크기는 실제 공개 원본 폭·높이에서 계산한다.
- 복사 Texture는 각 갱신에서 texture/UV/size/anchor를 다시 적용하여 source 교체를 반영한다. ClearAllPoints 뒤 왼쪽 원본 장식을 기준으로 한 줄로 연결한다. 기본 border의 geometry·atlas는 변경하지 않는다.
- 수리·전체 수리·잡템 판매·길드 수리 버튼의 크기·아이콘·상태·스크립트를 변경하지 않는다. native merchant update의 수리 가능·길드·잡템·재매입 조건을 유지한다. OFF·재매입 전환은 소유한 폭과 border alpha를 복원하고 자체 Texture만 숨긴다.
- 이 변경은 상점 표시 수정에 한정한다. 모듈화 질문에 대한 개발 순서 권고는 별도 보고서에 기록하며 런타임 모듈·설치 구조·저장 정책·파티 프레임을 추가하지 않는다.


## 1.10.9.6 설정 화면 개선

파티·공격대는 common/frames/roles 세 탭에서 공통 표시·크기/배치·클릭/역할 프로필을 나누며 기존 단일 모듈 저장 소유권을 유지한다. 공통 상수 ClassColors는 9개 직업만 제공하고 개인·파티 체력/미리보기/색상 곡선에서 공유한다. 자원색/게임 전역 팔레트/사용자 지정색은 변경하지 않는다.

프로필 전송은 데이터 코드 ProfileTransfer.lua를 그대로 유지하고 UI 창의 표시 계층/레벨만 올린다. 미리보기·위치 편집의 버튼은 자동 축소 뒤에도 중앙에 맞도록 명시 폭으로 배치한다. 편집 결과 경로는 groupFilter에서 선택한 category/group 부분만 표시에서 제거하며 전체 경로 검색/툴팁·안정적 대상 ID·세대 검사·완료/취소 writer는 보존한다.


## 1.11.4.5 안정성 계약

- 일반 목록은 실험실을 제외한다. 설치 상태 [?]는 일반 소개 행 오른쪽에 단일 앵커로 둔다. 바로가기 화살표는 26px 안에서 여백 없이 한 글자를 표시한다.
- 잠금 해제된 자원바는 재사용하는 테두리 프레임과 안내 문구로 이동 상태를 표시하며, 잠금 시 실제 리소스/스윙 표시로 돌아간다.
- 포만감은 PetFrame 직속 PetFrameHappiness의 공개 앵커만 변경한다. compact OFF, 모듈 OFF, 기본 편집 모드에서 소유 값을 복원하고 전투 중 변경은 보류한다.
- 토템은 부모를 바꾸지 않고 첫 아이콘의 기준을 PlayerFrame에 고정한다. 외부 SetPoint/ClearAllPoints는 한 번의 After(0)로 병합한다. 기본 컨테이너 폭/위치가 바뀌어도 기준은 누적되지 않는다.
- 토템·포만감 네이티브 훅은 프레임별 소유 객체를 재사용한다. 공개 참조/부모 계층이 잠시 없어져도 새 훅을 덧붙이지 않는다.
- 공통 Surface는 가능한 경우 PixelUtil.GetNearestPixelSize로 최소 1 물리 픽셀 두께를 적용하고 소유 NineSlice 가장자리의 개별 스냅을 해제한다. PixelUtil 부재 시 기존 1 UI단위 두께를 유지한다. 실제 래스터 결과는 게임에서 확인한다.

픽셀 크기/Backdrop 구조 대조에 사용한 게임 UI 소스: [PixelUtil.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_SharedXML/PixelUtil.lua), [Backdrop.lua](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_SharedXML/Backdrop.lua). Forever의 전체 동작을 Retail 코드와 같다고 가정하지 않으며 지원 함수는 존재 여부와 공개 반환값을 확인한다.

## 1.11.4.6 하위 탭과 토템 편집

하위 탭의 공통 프로필 문구를 선택한 기능의 짧은 설명으로 교체합니다. 상태 경고와 데이터 저장 정책은 유지합니다. 토템 프레임은 프레임 위치 확인 ON에서 전용 테두리를 드래그하며 좌표 ±3000, 좌우 확장 방향을 제공합니다. 네이티브 아이콘·시간·툴팁·우클릭을 유지하고 숨김 프레임의 임시 측정값이나 일시적인 플레이어 크기로 위치 기준을 저장하지 않습니다.

## 1.11.4.7 영혼의 조각과 유닛프레임 이동

영혼의 조각은 항목 6265의 이름·수량·가방 슬롯·커서·위치 잠금을 재확인한 실제 클릭에서만 1개 파괴합니다. 이벤트 자동 파기나 전역 확인창 변경은 없습니다. 최대 수량은 일반·영혼 가방의 전체 칸 수 이내로 입력하며 가방이 바뀌어도 저장값을 자동으로 낮추지 않습니다. 유닛프레임 전용 편집기는 원본 프레임을 움직이지 않는 가상 테두리에서 초안을 편집합니다. 완료 시 현재 프로필에 저장하고 네이티브 루트에 적용하며 취소·전투 진입·세대 변경 시 초안을 폐기합니다.

## 1.11.4.8 프레임 모양 미리보기

네이티브 루트의 여백이 포함된 전체 영역 대신 체력·자원 바의 외곽에 편집 테두리를 맞춥니다. 핸들에 붙은 별도 표시가 드래그와 함께 움직이며 현재 유닛은 진입 시점의 공개 텍스트/네이티브 바 값을 사용하고 없는 유닛은 예시 수치를 표시합니다. 현재 크기·색상·글자와 자원 표시를 반영합니다. 저장 시 바와 루트의 오프셋을 변환하여 기존 좌표 형식을 유지하며 원본 루트는 완료 전까지 이동하지 않습니다.

## 1.11.4.9 화면 좌표와 격자

편집 조작 창의 X/Y는 화면 중앙 (0, 0)에 대한 선택 테두리 중심의 UI px입니다. 오른쪽 X·위쪽 Y를 양수로 사용합니다. 숫자 입력은 현재 테두리와 원하는 화면 좌표의 차이를 기존 이동 처리에 전달하므로 루트 TOPLEFT·모듈 앵커·연결 부품 상대 좌표 저장 형식을 바꾸지 않습니다. 격자는 같은 중앙에서 좌우/상하로 반복하며 선과 텍스처를 재사용하고 편집 종료 시 숨깁니다. 기본 32, 범위 8~128, 간격 4 UI px입니다. 조작 창만 90% 배율로 축소합니다.

## 1.11.4.10 직업 보조 표시·수치 배치·판매·디버프 제외

플레이어의 ‘토템 프레임’ 탭을 ‘직업 보조 표시’로 변경하고 자원바의 탄약/영혼의 조각 설정을 옮깁니다. 실행 주체를 UnitFrames로 분리하되 기존 보조 표시 DB·앵커·초과 1개 클릭 파괴와 잠금/전투 조건을 유지합니다. 별도 저장 변수나 논리 모듈은 추가하지 않습니다.

플레이어·대상의 간결한 프레임에서 체력과 자원 수치를 각각 중앙/왼쪽/오른쪽 및 X/Y로 배치합니다. 기본 중앙·0/0, 범위 ±1000 UI px입니다. 실제 수치와 위치 편집용 모양에 같은 규칙을 적용하며 이름·레벨·루트 위치와 기존 수치 표시 형식은 유지합니다. 게임 기본 양쪽 수치는 하나의 움직일 수 있는 텍스트로 표시하고 비공개 문자열은 연산 없이 C 텍스트 설정기에 전달합니다.

자동판매는 완료된 슬롯의 확인 이벤트를 한 번으로 병합하고 이전 예약을 무효화합니다. 응답이 없을 때 0.05초마다 확인하지만 0.75초 응답 창은 유지합니다. 재전송 없이 기존 아이템 식별·퀘스트·가격·잠금 확인을 유지합니다. 마지막 가방/금액 반영을 위해 최종 수리 판단만 0.05초 미룹니다.

디버프 제외 목록은 기본 빈 맵입니다. 계정 공용 파티 프레임 프로필에 저장하고 복제/전환/초기화를 지원합니다. 네이티브 그룹의 후보 필터가 표시 개수 제한 전에 제외하고 남은 아이콘을 정렬합니다. 애드온은 비공개 오라 데이터나 표시 자식의 위치·크기를 읽지 않습니다. 친화 유닛의 보호된 해로운 효과는 클라이언트가 ID 필터를 허용하지 않으며 NeverSecret 주문만 제외할 수 있습니다. API 준비 실패 시 목록을 보존하고 기본 아이콘으로 돌아갑니다. 고정 예시 미리보기는 주문 ID 필터의 실제 결과를 재현하지 않습니다.

## 1.11.4.11 접기/펼치기 뒤 표시 및 파티 탭

아코디언 클릭은 동기 배치를 유지하고 다음 프레임에 기존 표시 갱신을 예약합니다. 최종 자식 높이/표시 상태가 정리된 뒤 ScrollFrame.UpdateScrollChildRect를 호출합니다. 높이 변경 경로에서도 한 번의 예약으로 합치므로 유닛 프레임뿐 아니라 공통 설정과 파티 전용 아코디언에 적용됩니다. 예약 처리는 현재 페이지를 읽고 창이 숨겨져 있으면 생략하며 재귀적 갱신·지속 타이머를 추가하지 않습니다.

디버프 필터의 동적 상태 문구는 생성 시 문자열을 전달하고 이후 uiControls.Refresh로 갱신합니다. 게임 C API의 텍스트 타입 제약을 모의 검증에도 적용하여 함수/테이블 인수가 문자열로 임의 변환되던 검증 누락을 방지합니다. 실제 스크롤 렌더러와 글꼴 캐시의 최종 결과는 게임에서 확인해야 합니다.

## 1.11.4.12 수치 정렬 및 제외 가능 여부

UnitFrameValueText.LayoutValueText는 플레이어·대상의 체력/자원 수치를 선택한 CENTER/LEFT/RIGHT 바 앵커 하나에 붙입니다. 같은 양쪽 앵커 안의 정렬만 바꾸던 구현을 교체하고 이전 폭을 0으로 풀어 자연 폭으로 표시합니다. 글자나 비밀 데이터의 폭을 읽지 않습니다. 기존 ApplySettings 경로에서 즉시 반영하며 전투 중 배치 변경은 기존 보류 정책을 유지합니다. 위치 편집용 미리보기에도 같은 함수와 배율을 적용합니다.

기존 건강/자원 표시 형식과 저장 필드는 유지합니다. 활성 프로필 GetDB에서 플레이어·대상의 healthTextX/Y 및 powerTextX/Y만 -50~50으로 제한합니다. 범위 밖 값은 가까운 경계, 잘못된 값은 0, 잘못된 정렬은 CENTER로 정리합니다. 다른 프레임·이름·보조 표시 좌표는 바꾸지 않습니다.

PartyFrameDebuffFilter.CanExcludeDebuffID는 기존 공개 C_Secrets 판정을 재사용해 공개 주문만 제외 가능으로 안내합니다. 보호 주문은 저장을 허용하되 제외 불가와 아이콘 유지 문구를 표시합니다. 실제 CustomAuraContainer 후보 필터와 목록 저장 구조는 그대로입니다. 휴식 강화 1229451의 보호 분류는 사용자 화면의 현재 클라이언트 판정에 근거하며 전역 상수로 하드코딩하지 않습니다. [클라이언트 필터 기준](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_AuraContainer/Blizzard_AuraContainerUtil.lua).

## 1.11.4.13 전투 종료 적용과 기본 일괄 판매

PartyFrames.OnCombatEnd는 공용 보류 처리기에 등록된 작업을 중복 소비하지 않습니다. 변경이 없으면 전체 ApplyLatest를 생략하고 역할 프로필·그룹/공격대 단계·기본 프레임 소유권을 확인합니다. 변경이 필요할 때 최신 설정을 한 번 적용합니다. 성공한 RefreshAll 뒤 ConfigureEvents는 버튼 이벤트를 다시 등록하지 않습니다. 실패 후 자기 복원/양보 정책을 유지하고 같은 종료 이벤트에서 다시 시도하지 않습니다. 설정·로드/주문 이벤트는 기존 요청 경로를 유지합니다.

UnitFrames.WithResolvedDB는 동기 적용 도중에만 한 번 정규화한 설정을 재사용합니다. 종료/예외 시 해제하고 프로필 세대·루트 DB·유닛 설정 테이블이 바뀌면 재사용하지 않습니다. 단순 체력 표시/글자 스타일의 전투 보류는 각 표시의 플래그로 관리하고 전투 종료에 RefreshCombatDisplays로 복원합니다. 실제 배치·공개 속성 읽기 실패·모듈 OFF·토템 보호 위치 변경은 기존 전체 적용을 유지합니다. 토템/포만감과 상태 표시 복원은 가벼운 경로에도 포함됩니다.

잡템 판매는 IsSellAllJunkEnabled가 참이고 GetNumJunkItems/SellAllJunkItems가 있는 경우 기본 C_MerchantFrame 일괄 판매를 방문당 한 번 요청합니다. 엔진의 대상 판정을 사용하며 애드온이 슬롯별 판매를 함께 보내지 않습니다. 완료는 남은 잡템 수와 이벤트/0.05초 확인으로 처리하고 2초 응답 기한 뒤 중단합니다. 요청 이후 오류/응답 지연에는 개별 판매로 전환하거나 재요청하지 않습니다. API/기능이 미지원인 경우에만 기존 검사 기반 개별 큐를 사용합니다. 자동 수리는 확인된 완료 뒤 기존 한 번의 판단을 사용합니다. [클라이언트 API](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/MerchantFrameDocumentation.lua).
