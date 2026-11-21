# 1.11.8.19 상단 위치 잠금 현황

기존 22개 + 신규 버프 알림 1개, 총 23개 컨트롤입니다. 현재 페이지/탭/유닛/부품/표시 모드의 대상만 표시합니다. 복수 이름은 모두 직접 표시하고, 이름 선택 메뉴/접기/위치 편집 버튼은 헤더에 없습니다.

| 모듈·경로 | 대상 이름 | 기존 검색 제목 | 통계 ID | 저장 범위 |
|---|---|---|---|---|
| unitFrames / player / class | 보조 표시 | 보조 표시 위치 잠금 | setting.unitFrames.player.class.control148 | 현재 전체 프로필 |
| generalConvenience | 가방 휴지통 | 위치 잠금 | setting.generalConvenience.control004 | 현재 전체 프로필 |
| generalConvenience | 버프 알림 | 버프 알림 위치 잠금 | setting.generalConvenience.buffThanks.locked | 현재 전체 프로필 |
| professions | 전문기술 | 위치 잠금 | setting.professions.control008 | 현재 전체 프로필 |
| todo | 포에버 노트 | 위치 잠금 | setting.todo.control013 | 현재 전체 프로필 |
| range | 거리 | 거리 위치 잠금 | setting.range.control006 | 현재 전체 프로필 |
| range | 사거리 측정 | 위치 잠금 | setting.range.control028 | 현재 전체 프로필 |
| clock | 시계·정보 표시 | 위치 잠금 | setting.clock.locked | 현재 전체 프로필 |
| clock | 도구 창 | 도구 창 위치 잠금 | setting.clock.toolsLocked | 현재 전체 프로필 |
| clock | 타이머 바 | 타이머 바 위치 잠금 | setting.clock.timerBarLocked | 현재 전체 프로필 |
| minimap / minimap | 잠금 | 잠금 | setting.minimap.minimap.control011 | 계정 공용 미니맵 설정 |
| experienceBar | 경험치 | 위치 잠금 | setting.experienceBar.control019 | 잠금은 현재 접속 · 좌표는 현재 전체 프로필 |
| castBar / player | 시전 | 위치 잠금 | setting.castBar.player.control024 | 현재 전체 프로필 |
| resourceSwing | 자원·스윙 | 위치 잠금 | setting.resourceSwing.control016 | 현재 전체 프로필 |
| resourceSwing | 콤보 포인트 | 콤보 자유 배치 잠금 | setting.resourceSwing.control029 | 현재 전체 프로필 |
| environmentTimer | 환경타이머 | 위치 잠금 | setting.environmentTimer.control016 | 잠금은 현재 접속 · 좌표는 현재 전체 프로필 |
| combatStatus | 전투 상태 | 위치 잠금 | setting.combatStatus.control002 | 현재 전체 프로필 |
| threat | 위협 수치 | 위치 잠금 | setting.threat.control009 | 현재 전체 프로필 |
| pvpAlert | PvP | 위치 잠금 | setting.pvpAlert.control010 | 잠금은 현재 접속 · 좌표는 현재 전체 프로필 |
| campfire | 모닥불 | 위치 잠금 | setting.campfire.control005 | 현재 전체 프로필 |
| questNavigator / navigation | 길 안내 | 위치 잠금 | setting.questNavigator.navigation.control003 | 현재 전체 프로필 |
| buffReminder | 버프 리마인더 | 위치 잠금 | setting.buffReminder.locked | 현재 전체 프로필 |
| procAlert | 발동 버프 | 위치 잠금 | setting.procAlert.unlocked | 잠금은 현재 접속 · 좌표는 현재 전체 프로필 |

시계는 본체/정보 도구/타이머 3행, 자원바는 자원/콤보 2행입니다. 전문기술 버튼/펼친 목록은 공유 잠금 1행입니다. 단일 행에서는 대상 이름을 숨깁니다.

일반 편의의 ‘가방 휴지통 사용’과 ‘버프 알림 사용’은 본문 기능 활성화 설정입니다. 상단 잠금은 독립적으로 이동 가능 여부만 바꿉니다. 휴지통 잠금은 기능 ON + 화면에 직접 배치 모드에서 조작하며 배치 모드를 강제로 바꾸지 않습니다. 버프 알림은 기능 ON에서 잠금을 조작하고 비전투에서 움직입니다.

독립 잠금이 없는 대상도 조사했습니다. 파티 버튼은 기존 Alt+좌클릭 드래그와 초기화를 유지합니다. 유닛/파티 루트·전용 부품·대상 시전·기본창·주사위/공통 알림·툴팁은 기존 전역/전용 편집과 연결 배치 정책을 사용합니다. 보호된 기본 창에 새 이동/잠금을 만들지 않았습니다. 그 페이지에는 가짜 잠금 행을 만들지 않습니다.
