# 공통 슬라이더 적용 목록

공통 생성 함수를 수정하므로 이 함수를 사용하는 설정 슬라이더에 적용됩니다. 9개 직업의 모의 페이지 생성에서 직업별 300개 등록 설정과 별도 설정창 배율/투명도 2개를 확인했습니다. 실험실은 모의 환경에서만 잠금 판정을 열어 조사했고 실제 잠금 정책은 바꾸지 않았습니다. 등록 편집의 조건부 동적 위젯은 생성 시 공통 함수를 사용하지만 모든 사용자 등록 자료를 열거한 것은 아닙니다.

모의 배치 폭: 164/210/310/640 UI px. 실제 게임 폰트·클릭 영역·배율·스크롤 clipping: NOT TESTED.

| 모듈 | 등록 슬라이더 수 |
|---|---:|
| basicUI | 4 |
| buffReminder | 1 |
| campfire | 3 |
| castBar | 14 |
| clock | 4 |
| combatStatus | 3 |
| convenienceParty | 2 |
| cursorTrail | 5 |
| environmentTimer | 13 |
| experienceBar | 12 |
| general | 1 |
| generalConvenience | 3 |
| minimap | 4 |
| npcAlert | 7 |
| objectHighlight | 4 |
| partyFrames | 26 |
| procAlert | 6 |
| professions | 5 |
| pvpAlert | 6 |
| questNavigator | 10 |
| range | 13 |
| resourceSwing | 14 |
| threat | 2 |
| todo | 5 |
| tooltip | 4 |
| unitFrames | 129 |

## 범위 밖 직접 생성 위젯

| 위치 | 위젯 | 판정 |
|---|---|---|
| KHQOL_Clock/Clock/Todo.lua | 노트 본문 창 글자 크기·투명도 2개 | 독립 노트 창 전용 UI, 공통 설정 함수 미사용. 기존 동작 보존 |
| KHQOL/PositionGrid.lua | 위치 편집 조작창의 격자 간격 1개 | 뷰 선호 전용 저장/편집 도구. 공통 설정과 별도이며 이번에 교체하지 않음 |
| KHQOL_Convenience/Modules/AltProfessions.lua | 세로 스크롤 Slider | 스크롤바이므로 제외 |
| KHQOL/UI/ProfileTransfer.lua | 세로 스크롤 Slider | 스크롤바이므로 제외 |

Blizzard/외부 애드온 Slider, 진행 바·상태 바는 변경하지 않았습니다. 위 3개 전용 설정 위젯의 화살표는 후속 공통 보조 컴포넌트 도입 대상으로 남깁니다. 개별 모듈 복사 구현은 하지 않았습니다.

## 등록 설정 세부 목록

범위/step은 기존과 같으며 현재 조사에서 0.05/0.1/0.5/1/5/10을 확인했습니다. missing/0/음수 step인 실제 등록 항목은 없었습니다. 그런 호출은 임의의 1을 넣지 않고 화살표를 비활성화합니다. 아래 format은 원본 함수로 계속 표시합니다.

| 모듈·정적 문맥 | 제목 | min / max / step | getter 위치 |
|---|---|---|---|
| castBar / player / 바 모양 | 높이 | 8 / 80 / 1 | KHQOL/BasicUI/CastBar/Settings.lua:15 |
| castBar / player / 바 모양 | 폭 | 80 / 800 / 1 | KHQOL/BasicUI/CastBar/Settings.lua:15 |
| castBar / player / 스킬명 | 글자 크기 | 8 / 32 / 1 | KHQOL/BasicUI/CastBar/Settings.lua:15 |
| castBar / player / 시전 시간 | 글자 크기 | 8 / 32 / 1 | KHQOL/BasicUI/CastBar/Settings.lua:15 |
| castBar / player / 아이콘 | 아이콘 크기 | 8 / 80 / 1 | KHQOL/BasicUI/CastBar/Settings.lua:15 |
| castBar / player / 위치 | X 위치 | -3000 / 3000 / 1 | KHQOL/BasicUI/CastBar/Settings.lua:15 |
| castBar / player / 위치 | Y 위치 | -3000 / 3000 / 1 | KHQOL/BasicUI/CastBar/Settings.lua:15 |
| castBar / player / 위치 | 간격 | 0 / 20 / 1 | KHQOL/BasicUI/CastBar/Settings.lua:15 |
| castBar / target / 바 모양 / 현재 프로필 | 높이 | 8 / 80 / 1 | KHQOL/BasicUI/CastBar/Settings.lua:94 |
| castBar / target / 바 모양 / 현재 프로필 | 폭 | 80 / 800 / 1 | KHQOL/BasicUI/CastBar/Settings.lua:94 |
| castBar / target / 스킬명 / 현재 프로필 | 글자 크기 | 8 / 32 / 1 | KHQOL/BasicUI/CastBar/Settings.lua:94 |
| castBar / target / 아이콘 / 현재 프로필 | 아이콘 크기 | 8 / 80 / 1 | KHQOL/BasicUI/CastBar/Settings.lua:94 |
| castBar / target / 대상 시전바 | 대상 시전바 X 위치 보정 | -1000 / 1000 / 1 | KHQOL/BasicUI/CastBar/Settings.lua:87 |
| castBar / target / 대상 시전바 | 대상 시전바 Y 위치 보정 | -1000 / 1000 / 1 | KHQOL/BasicUI/CastBar/Settings.lua:87 |
| unitFrames / target / auras / attackableNPC / 공격 가능한 대상 NPC | 디버프 최대 행 수 | 1 / 4 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:375 |
| unitFrames / target / auras / attackableNPC / 공격 가능한 대상 NPC | 디버프 행당 개수 | 3 / 10 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:374 |
| unitFrames / target / auras / attackableNPC / 공격 가능한 대상 NPC | 버프 최대 행 수 | 1 / 4 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:375 |
| unitFrames / target / auras / attackableNPC / 공격 가능한 대상 NPC | 버프 행당 개수 | 3 / 10 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:374 |
| unitFrames / target / auras / attackableNPC / 공격 가능한 대상 NPC | 버프·디버프 공통 X 위치 보정 | -300 / 300 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:381 |
| unitFrames / target / auras / attackableNPC / 공격 가능한 대상 NPC | 버프·디버프 공통 Y 위치 보정 | -300 / 300 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:381 |
| unitFrames / target / auras / attackableNPC / 공격 가능한 대상 NPC | 버프·디버프 아이콘 크기 | 8 / 64 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:367 |
| unitFrames / target / auras / attackableNPC / 대상 디버프 개별 위치 | 대상 디버프 X 위치 보정 | -300 / 300 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:390 |
| unitFrames / target / auras / attackableNPC / 대상 디버프 개별 위치 | 대상 디버프 Y 위치 보정 | -300 / 300 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:390 |
| unitFrames / target / auras / attackableNPC / 대상 버프 개별 위치 | 대상 버프 X 위치 보정 | -300 / 300 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:390 |
| unitFrames / target / auras / attackableNPC / 대상 버프 개별 위치 | 대상 버프 Y 위치 보정 | -300 / 300 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:390 |
| unitFrames / target / auras / friendlyPlayer / 대상 디버프 개별 위치 | 대상 디버프 X 위치 보정 | -300 / 300 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:390 |
| unitFrames / target / auras / friendlyPlayer / 대상 디버프 개별 위치 | 대상 디버프 Y 위치 보정 | -300 / 300 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:390 |
| unitFrames / target / auras / friendlyPlayer / 대상 버프 개별 위치 | 대상 버프 X 위치 보정 | -300 / 300 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:390 |
| unitFrames / target / auras / friendlyPlayer / 대상 버프 개별 위치 | 대상 버프 Y 위치 보정 | -300 / 300 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:390 |
| unitFrames / target / auras / friendlyPlayer / 아군 대상 플레이어 | 디버프 최대 행 수 | 1 / 4 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:375 |
| unitFrames / target / auras / friendlyPlayer / 아군 대상 플레이어 | 디버프 행당 개수 | 3 / 10 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:374 |
| unitFrames / target / auras / friendlyPlayer / 아군 대상 플레이어 | 버프 최대 행 수 | 1 / 4 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:375 |
| unitFrames / target / auras / friendlyPlayer / 아군 대상 플레이어 | 버프 행당 개수 | 3 / 10 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:374 |
| unitFrames / target / auras / friendlyPlayer / 아군 대상 플레이어 | 버프·디버프 공통 X 위치 보정 | -300 / 300 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:381 |
| unitFrames / target / auras / friendlyPlayer / 아군 대상 플레이어 | 버프·디버프 공통 Y 위치 보정 | -300 / 300 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:381 |
| unitFrames / target / auras / friendlyPlayer / 아군 대상 플레이어 | 버프·디버프 아이콘 크기 | 8 / 64 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:367 |
| basicUI / 알림 / 계정 공용 | 도안 습득 알림 크기 | 60 / 150 / 1 | KHQOL/BasicUI/NativeAlerts.lua:282 |
| basicUI / 주사위 굴림 / 계정 공용 | 글자 크기 | 11 / 22 / 1 | KHQOL/BasicUI/NativeAlerts.lua:282 |
| basicUI / 주사위 굴림 / 계정 공용 | 창 크기 | 70 / 150 / 1 | KHQOL/BasicUI/NativeAlerts.lua:282 |
| basicUI | 공통 숨김 지연 | 0 / 2 / 0.1 | KHQOL/BasicUI/Settings.lua:19 |
| buffReminder / 알림 모양 / 현재 프로필 | 아이콘 크기 | 60 / 100 / 1 | KHQOL_Labs/BuffReminder/Settings.lua:30 |
| campfire / 알림 간격 | 야영 효과 획득 후 재알림 지연 | 0 / 300 / 5 | KHQOL_Campfire/UI/Settings.lua:7 |
| campfire / 알림 모양 | 글자 크기 | 40 / 70 / 5 | KHQOL_Campfire/UI/Settings.lua:24 |
| campfire / 알림 모양 | 아이콘 크기 | 60 / 120 / 10 | KHQOL_Campfire/UI/Settings.lua:21 |
| clock / 사이드 텍스트 / 현재 프로필 | 글자 크기 | 10 / 28 / 1 | KHQOL_Clock/Clock/Settings.lua:110 |
| clock / 시간 글자·모양 / 현재 프로필 | 글자 크기 | 24 / 80 / 1 | KHQOL_Clock/Clock/Settings.lua:103 |
| clock / 알람·타이머·스톱워치 / 현재 프로필 | 알람·타이머 창 크기 | 80 / 100 / 5 | KHQOL_Clock/Clock/Settings.lua:121 |
| clock / 길드 접속 | 툴팁 명단 축약 기준 | 1 / 1000 / 1 | KHQOL_Clock/Clock/Settings.lua:96 |
| combatStatus / 공통 설정 / 현재 프로필 | 글씨 크기 | 40 / 80 / 1 | KHQOL_CombatStatus/Modules/CombatStatus.lua:353 |
| combatStatus / 칼 애니메이션 / 현재 프로필 | 아이콘 크기 | 20 / 160 / 1 | KHQOL_CombatStatus/Modules/CombatStatus.lua:356 |
| combatStatus / 표시 시간 / 효과 / 현재 프로필 | 표시 시간 | 0.5 / 3 / 0.1 | KHQOL_CombatStatus/Modules/CombatStatus.lua:359 |
| convenienceParty / 파티 버튼 | 파티 버튼 크기 | 24 / 96 / 1 | KHQOL_Convenience/UI/ConvenienceDetails.lua:120 |
| convenienceParty / 파티 버튼 | 파티 버튼 투명도 | 0 / 90 / 1 | KHQOL_Convenience/UI/ConvenienceDetails.lua:122 |
| cursorTrail / 고급 / 잔상 동작 / 현재 프로필 | 유지 시간 | 0.1 / 2 / 0.05 | KHQOL_CursorTrail/CursorTrail/Settings.lua:13 |
| cursorTrail / 고급 / 잔상 동작 / 현재 프로필 | 포인트 간격 | 1 / 20 / 0.5 | KHQOL_CursorTrail/CursorTrail/Settings.lua:12 |
| cursorTrail / 잔상 모양 / 현재 프로필 | 잔상 길이 | 1 / 40 / 1 | KHQOL_CursorTrail/CursorTrail/Settings.lua:7 |
| cursorTrail / 잔상 모양 / 현재 프로필 | 크기 | 4 / 32 / 1 | KHQOL_CursorTrail/CursorTrail/Settings.lua:8 |
| cursorTrail / 잔상 모양 / 현재 프로필 | 투명도 | 0.1 / 1 / 0.05 | KHQOL_CursorTrail/CursorTrail/Settings.lua:10 |
| environmentTimer / 모양 및 크기 | HUD 바 두께 | 2 / 30 / 1 | KHQOL_EnvironmentTimer/UI/Settings.lua:14 |
| environmentTimer / 모양 및 크기 | HUD 전체 크기 | 100 / 600 / 1 | KHQOL_EnvironmentTimer/UI/Settings.lua:14 |
| environmentTimer / 모양 및 크기 | HUD 좌우 간격 | 80 / 800 / 1 | KHQOL_EnvironmentTimer/UI/Settings.lua:14 |
| environmentTimer / 모양 및 크기 | 높이 | 8 / 500 / 1 | KHQOL_EnvironmentTimer/UI/Settings.lua:14 |
| environmentTimer / 모양 및 크기 | 배율 | 0.5 / 2 / 0.05 | KHQOL_EnvironmentTimer/UI/Settings.lua:14 |
| environmentTimer / 모양 및 크기 | 투명도 | 0.1 / 1 / 0.05 | KHQOL_EnvironmentTimer/UI/Settings.lua:14 |
| environmentTimer / 모양 및 크기 | 폭 | 40 / 800 / 1 | KHQOL_EnvironmentTimer/UI/Settings.lua:14 |
| environmentTimer / 상태 및 경고 | 긴급 시작 (초) | 0 / 120 / 1 | KHQOL_EnvironmentTimer/UI/Settings.lua:14 |
| environmentTimer / 상태 및 경고 | 위험 시작 (%) | 0 / 99 / 1 | KHQOL_EnvironmentTimer/UI/Settings.lua:14 |
| environmentTimer / 상태 및 경고 | 주의 시작 (%) | 1 / 100 / 1 | KHQOL_EnvironmentTimer/UI/Settings.lua:14 |
| environmentTimer / 위치 | X 위치 | -3000 / 3000 / 1 | KHQOL_EnvironmentTimer/UI/Settings.lua:14 |
| environmentTimer / 위치 | Y 위치 | -3000 / 3000 / 1 | KHQOL_EnvironmentTimer/UI/Settings.lua:14 |
| environmentTimer / 텍스트 | HUD 텍스트 크기 | 8 / 48 / 1 | KHQOL_EnvironmentTimer/UI/Settings.lua:14 |
| experienceBar / PlayerFrame 감싸기 | PlayerFrame과의 간격 | 0 / 60 / 1 | KHQOL_ExperienceBar/UI/ExperienceSettings.lua:11 |
| experienceBar / PlayerFrame 감싸기 | X 오프셋 | -500 / 500 / 1 | KHQOL_ExperienceBar/UI/ExperienceSettings.lua:11 |
| experienceBar / PlayerFrame 감싸기 | Y 오프셋 | -500 / 500 / 1 | KHQOL_ExperienceBar/UI/ExperienceSettings.lua:11 |
| experienceBar / PlayerFrame 감싸기 | 가로 길이 | 160 / 600 / 1 | KHQOL_ExperienceBar/UI/ExperienceSettings.lua:11 |
| experienceBar / PlayerFrame 감싸기 | 바 두께 | 2 / 16 / 1 | KHQOL_ExperienceBar/UI/ExperienceSettings.lua:11 |
| experienceBar / PlayerFrame 감싸기 | 세로 길이 | 16 / 180 / 1 | KHQOL_ExperienceBar/UI/ExperienceSettings.lua:11 |
| experienceBar / 위치 | X 위치 | -3000 / 3000 / 1 | KHQOL_ExperienceBar/UI/ExperienceSettings.lua:11 |
| experienceBar / 위치 | Y 위치 | -3000 / 3000 / 1 | KHQOL_ExperienceBar/UI/ExperienceSettings.lua:11 |
| experienceBar / 크기·모양 | 높이 | 8 / 80 / 1 | KHQOL_ExperienceBar/UI/ExperienceSettings.lua:11 |
| experienceBar / 크기·모양 | 폭 | 120 / 1200 / 1 | KHQOL_ExperienceBar/UI/ExperienceSettings.lua:11 |
| experienceBar | 배율 | 0.5 / 2 / 0.05 | KHQOL_ExperienceBar/UI/ExperienceSettings.lua:11 |
| experienceBar | 투명도 | 0.1 / 1 / 0.05 | KHQOL_ExperienceBar/UI/ExperienceSettings.lua:11 |
| general / 전역 설정 / 현재 프로필 | 중앙 알림 텍스트 크기 | 75 / 200 / 5 | KHQOL_Convenience/GeneralOptions.lua:399 |
| generalConvenience / 가방 휴지통 | 휴지통 아이콘 크기 | 20 / 64 / 1 | KHQOL_Convenience/UI/BagItemSettings.lua:44 |
| generalConvenience / 버프 알림 | 버프 아이콘 크기 | 32 / 112 / 1 | KHQOL_Convenience/UI/ConvenienceDetails.lua:145 |
| generalConvenience / 버프 알림 | 알림 유지 시간 | 10 / 30 / 1 | KHQOL_Convenience/UI/ConvenienceDetails.lua:145 |
| minimap / minimap / 미니맵 / 계정 공용 미니맵 설정 | 미니맵 크기 | 180 / 300 / 1 | KHQOL_Map/Settings.lua:25 |
| minimap / minimapButtons / 버튼 보관 / 계정 공용 미니맵 설정 | 아이콘 크기 | 20 / 30 / 1 | KHQOL_Map/Settings.lua:25 |
| minimap / minimap / 위치 · 지도 및 주변 아이콘 / 계정 공용 미니맵 설정 | 아이콘 크기 | 70 / 150 / 1 | KHQOL_Map/Settings.lua:25 |
| minimap / minimap / 지역명 표시 / 계정 공용 미니맵 설정 | 지역명 크기 | 100 / 200 / 1 | KHQOL_Map/Settings.lua:25 |
| npcAlert / 경고 설정 | 배너 크기 | 0.5 / 2 / 0.05 | KHQOL_NPCAlert/UI/NPCAlertSettings.lua:90 |
| npcAlert / 경고 설정 | 배너 투명도 | 0.1 / 1 / 0.05 | KHQOL_NPCAlert/UI/NPCAlertSettings.lua:90 |
| npcAlert / 경고 설정 | 배너 표시 시간 | 1 / 10 / 1 | KHQOL_NPCAlert/UI/NPCAlertSettings.lua:90 |
| npcAlert / 반복 경고 | 재경고 대기시간 (초) | 1 / 300 / 1 | KHQOL_NPCAlert/UI/NPCAlertSettings.lua:90 |
| npcAlert / 위험 방향 표시 | 중심 거리 | 40 / 500 / 5 | KHQOL_NPCAlert/UI/NPCAlertSettings.lua:90 |
| npcAlert / 위험 방향 표시 | 크기 | 24 / 128 / 1 | KHQOL_NPCAlert/UI/NPCAlertSettings.lua:90 |
| npcAlert / 위험 방향 표시 | 투명도 | 0.1 / 1 / 0.05 | KHQOL_NPCAlert/UI/NPCAlertSettings.lua:90 |
| objectHighlight / 공통 설정 | 강조 X 위치 | -200 / 200 / 1 | KHQOL_Labs/UI/LabSettings.lua:232 |
| objectHighlight / 공통 설정 | 강조 Y 위치 | -200 / 100 / 1 | KHQOL_Labs/UI/LabSettings.lua:233 |
| objectHighlight / 공통 설정 | 강조 크기 | 40 / 240 / 5 | KHQOL_Labs/UI/LabSettings.lua:231 |
| objectHighlight / 공통 설정 | 강조 투명도 | 0.1 / 1 / 0.05 | KHQOL_Labs/UI/LabSettings.lua:236 |
| partyFrames / common / 공통 표시 / 계정 공용 프레임 프로필 | 글자 크기 | 10 / 24 / 1 | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:119 |
| partyFrames / common / 닉네임 위치 / 계정 공용 프레임 프로필 | 닉네임 위치 X | -300 / 300 / 1 | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:140 |
| partyFrames / common / 닉네임 위치 / 계정 공용 프레임 프로필 | 닉네임 위치 Y | -300 / 300 / 1 | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:141 |
| partyFrames / common / 대상 징표 / 계정 공용 프레임 프로필 | 대상 징표 X | -300 / 300 / 1 | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:140 |
| partyFrames / common / 대상 징표 / 계정 공용 프레임 프로필 | 대상 징표 Y | -300 / 300 / 1 | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:141 |
| partyFrames / common / 대상 징표 / 계정 공용 프레임 프로필 | 대상 징표 크기 | 8 / 40 / 1 | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:139 |
| partyFrames / auras / 디버프 아이콘 / 계정 공용 프레임 프로필 | 디버프 X 좌표 | -300 / 300 / 1 | KHQOL_UnitFrames/Party/UI/PartyFrameAuraSettings.lua:126 |
| partyFrames / auras / 디버프 아이콘 / 계정 공용 프레임 프로필 | 디버프 Y 좌표 | -300 / 300 / 1 | KHQOL_UnitFrames/Party/UI/PartyFrameAuraSettings.lua:127 |
| partyFrames / auras / 디버프 아이콘 / 계정 공용 프레임 프로필 | 디버프 간격 | 0 / 20 / 1 | KHQOL_UnitFrames/Party/UI/PartyFrameAuraSettings.lua:123 |
| partyFrames / auras / 디버프 아이콘 / 계정 공용 프레임 프로필 | 디버프 최대 개수 | 1 / 12 / 1 | KHQOL_UnitFrames/Party/UI/PartyFrameAuraSettings.lua:121 |
| partyFrames / auras / 디버프 아이콘 / 계정 공용 프레임 프로필 | 디버프 크기 | 8 / 48 / 1 | KHQOL_UnitFrames/Party/UI/PartyFrameAuraSettings.lua:122 |
| partyFrames / auras / 디버프 아이콘 / 계정 공용 프레임 프로필 | 디버프 한 줄 개수 | 1 / 12 / 1 | KHQOL_UnitFrames/Party/UI/PartyFrameAuraSettings.lua:120 |
| partyFrames / auras / 디버프·보호막 미리보기 / 계정 공용 프레임 프로필 | 예시 보호막 비율 | 0 / 100 / 5 | KHQOL_UnitFrames/Party/UI/PartyFrameAuraSettings.lua:164 |
| partyFrames / common / 역할 마크 / 계정 공용 프레임 프로필 | 역할 마크 X | -300 / 300 / 1 | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:140 |
| partyFrames / common / 역할 마크 / 계정 공용 프레임 프로필 | 역할 마크 Y | -300 / 300 / 1 | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:141 |
| partyFrames / common / 역할 마크 / 계정 공용 프레임 프로필 | 역할 마크 크기 | 8 / 40 / 1 | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:139 |
| partyFrames / common / 체력 텍스트 위치 / 계정 공용 프레임 프로필 | 체력 텍스트 위치 X | -300 / 300 / 1 | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:140 |
| partyFrames / common / 체력 텍스트 위치 / 계정 공용 프레임 프로필 | 체력 텍스트 위치 Y | -300 / 300 / 1 | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:141 |
| partyFrames / common / 체력·자원 바 / 계정 공용 프레임 프로필 | 자원 바 높이 | 1 / 24 / 1 | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:133 |
| partyFrames / frames / 크기·위치·배치 / 계정 공용 프레임 프로필 | X 좌표 | -3000 / 3000 / 1 | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:98 |
| partyFrames / frames / 크기·위치·배치 / 계정 공용 프레임 프로필 | Y 좌표 | -3000 / 3000 / 1 | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:99 |
| partyFrames / frames / 크기·위치·배치 / 계정 공용 프레임 프로필 | 인원 사이 간격 | 0 / 24 / 1 | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:94 |
| partyFrames / frames / 크기·위치·배치 / 계정 공용 프레임 프로필 | 파티 사이 가로 간격 | 0 / 100 / 1 | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:104 |
| partyFrames / frames / 크기·위치·배치 / 계정 공용 프레임 프로필 | 파티 사이 세로 간격 | 0 / 100 / 1 | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:105 |
| partyFrames / frames / 크기·위치·배치 / 계정 공용 프레임 프로필 | 프레임 높이 | 28 / 100 / 1 | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:93 |
| partyFrames / frames / 크기·위치·배치 / 계정 공용 프레임 프로필 | 프레임 폭 | 80 / 320 / 1 | KHQOL_UnitFrames/Party/UI/PartyFrameSettings.lua:92 |
| procAlert / HUD 모양 | 곡선 높이 | 100 / 600 / 5 | KHQOL_Labs/UI/LabSettings.lua:121 |
| procAlert / HUD 모양 | 전체 배율 | 0.5 / 2 / 0.05 | KHQOL_Labs/UI/LabSettings.lua:121 |
| procAlert / HUD 모양 | 좌우 간격 | 80 / 800 / 5 | KHQOL_Labs/UI/LabSettings.lua:121 |
| procAlert / HUD 모양 | 투명도 | 0.1 / 1 / 0.05 | KHQOL_Labs/UI/LabSettings.lua:121 |
| procAlert / 위치 | X 위치 | -1500 / 1500 / 1 | KHQOL_Labs/UI/LabSettings.lua:121 |
| procAlert / 위치 | Y 위치 | -1000 / 1000 / 1 | KHQOL_Labs/UI/LabSettings.lua:121 |
| professions / 전문기술 버튼 | 버튼 글자 크기 | 10 / 28 / 1 | KHQOL_Convenience/UI/ProfessionSettings.lua:8 |
| professions / 펼친 목록 | 목록 배경 불투명도 | 0 / 100 / 1 | KHQOL_Convenience/UI/ProfessionSettings.lua:37 |
| professions / 펼친 목록 | 숙련도 글자 크기 | 8 / 26 / 1 | KHQOL_Convenience/UI/ProfessionSettings.lua:8 |
| professions / 펼친 목록 | 아이콘 크기 | 24 / 56 / 1 | KHQOL_Convenience/UI/ProfessionSettings.lua:8 |
| professions / 펼친 목록 | 전문기술 사이 간격 | 2 / 16 / 1 | KHQOL_Convenience/UI/ProfessionSettings.lua:8 |
| pvpAlert / 위치·크기 / 현재 프로필 | 전체 크기 | 50 / 200 / 5 | KHQOL_PvPAlert/Modules/PvPAlert/Settings.lua:30 |
| pvpAlert / 위치·크기 / 현재 프로필 | 투명도 | 10 / 100 / 5 | KHQOL_PvPAlert/Modules/PvPAlert/Settings.lua:31 |
| pvpAlert / 위치·크기 | X 위치 | -3000 / 3000 / 1 | KHQOL_PvPAlert/Modules/PvPAlert/Settings.lua:14 |
| pvpAlert / 위치·크기 | Y 위치 | -2000 / 2000 / 1 | KHQOL_PvPAlert/Modules/PvPAlert/Settings.lua:14 |
| pvpAlert / 접근 경고 | 접근 판정 | 1 / 3 / 1 | KHQOL_PvPAlert/Modules/PvPAlert/Settings.lua:14 |
| pvpAlert / 주시 경고 | 타겟 확정 시간 | 0.1 / 2 / 0.1 | KHQOL_PvPAlert/Modules/PvPAlert/Settings.lua:14 |
| questNavigator / navigation / 고급 / 현재 프로필 | 거리 갱신 주기 | 0.1 / 1 / 0.05 | KHQOL_QuestNavigator/QuestNavigator/Settings.lua:71 |
| questNavigator / navigation / 고급 / 현재 프로필 | 화살표 갱신 주기 | 0.05 / 0.5 / 0.05 | KHQOL_QuestNavigator/QuestNavigator/Settings.lua:70 |
| questNavigator / navigation / 안내 화살표 크기·모양 / 현재 프로필 | 화살표 눕힘 각도 | 0 / 70 / 5 | KHQOL_QuestNavigator/QuestNavigator/Settings.lua:53 |
| questNavigator / navigation / 안내 화살표 크기·모양 / 현재 프로필 | 화살표 크기 | 32 / 128 / 1 | KHQOL_QuestNavigator/QuestNavigator/Settings.lua:52 |
| questNavigator / navigation / 안내 화살표 크기·모양 / 현재 프로필 | 화살표 투명도 | 0.1 / 1 / 0.05 | KHQOL_QuestNavigator/QuestNavigator/Settings.lua:54 |
| questNavigator / tracker / 퀘스트 목록 표시 / 현재 프로필 | 자동 전환 대기 시간 | 5 / 30 / 1 | KHQOL_QuestNavigator/QuestNavigator/Settings.lua:26 |
| questNavigator / tracker / 퀘스트 목록 표시 / 현재 프로필 | 퀘스트 글씨 크기 | 10 / 20 / 1 | KHQOL_QuestNavigator/QuestNavigator/Settings.lua:30 |
| questNavigator / tracker / 퀘스트 목록 표시 / 현재 프로필 | 퀘스트 내용 표시 폭 | 200 / 500 / 1 | KHQOL_QuestNavigator/QuestNavigator/Settings.lua:31 |
| questNavigator / navigation / 표시 / 현재 프로필 | 진행도 글자 크기 | 8 / 30 / 1 | KHQOL_QuestNavigator/QuestNavigator/Settings.lua:60 |
| questNavigator / navigation / 표시 / 현재 프로필 | 퀘스트 이름 글자 크기 | 8 / 30 / 1 | KHQOL_QuestNavigator/QuestNavigator/Settings.lua:59 |
| range / 마우스오버 거리 측정 / 현재 프로필 | X 위치 보정 | -100 / 200 / 1 | KHQOL_Range/Range/Settings.lua:61 |
| range / 마우스오버 거리 측정 / 현재 프로필 | Y 위치 보정 | -100 / 100 / 1 | KHQOL_Range/Range/Settings.lua:62 |
| range / 마우스오버 거리 측정 / 현재 프로필 | 글자 크기 | 10 / 40 / 1 | KHQOL_Range/Range/Settings.lua:73 |
| range / 외곽선 / 현재 프로필 | 외곽선 두께 | 0 / 4 / 1 | KHQOL_Range/Range/Settings.lua:99 |
| range / 위치 / 현재 프로필 | X 위치 | -1000 / 1000 / 1 | KHQOL_Range/Range/Settings.lua:78 |
| range / 위치 / 현재 프로필 | Y 위치 | -1000 / 1000 / 1 | KHQOL_Range/Range/Settings.lua:79 |
| range / 표시 모양 / 현재 프로필 | 크기 | 10 / 80 / 1 | KHQOL_Range/Range/Settings.lua:95 |
| range / 대상 거리 | 거리 X 위치 | -3000 / 3000 / 1 | KHQOL_Range/Range/Distance.lua:289 |
| range / 대상 거리 | 거리 Y 위치 | -3000 / 3000 / 1 | KHQOL_Range/Range/Distance.lua:289 |
| range / 대상 거리 | 거리 구간 간격 | 1 / 10 / 1 | KHQOL_Range/Range/Distance.lua:289 |
| range / 대상 거리 | 거리 글자 크기 | 20 / 40 / 1 | KHQOL_Range/Range/Distance.lua:289 |
| range / 대상 거리 | 최대 표시 거리 (50~100m) | 50 / 100 / 1 | KHQOL_Range/Range/Distance.lua:289 |
| range / 대상 거리 | 최대 표시 거리 (55~109yd) | 55 / 109 / 1 | KHQOL_Range/Range/Distance.lua:304 |
| resourceSwing / 고급 / 표시 레이어 | 스윙 바 내부 레이어 | 1 / 7 / 1 | KHQOL_ResourceSwing/ResourceSwing/KHQOLResourceSwing.lua:457 |
| resourceSwing / 고급 / 표시 레이어 | 자원 바 내부 레이어 | 1 / 7 / 1 | KHQOL_ResourceSwing/ResourceSwing/KHQOLResourceSwing.lua:457 |
| resourceSwing / 위치 | X 위치 | -3000 / 3000 / 1 | KHQOL_ResourceSwing/ResourceSwing/KHQOLResourceSwing.lua:457 |
| resourceSwing / 위치 | Y 위치 | -3000 / 3000 / 1 | KHQOL_ResourceSwing/ResourceSwing/KHQOLResourceSwing.lua:457 |
| resourceSwing / 자원 텍스트 | 글자 크기 | 8 / 24 / 1 | KHQOL_ResourceSwing/ResourceSwing/KHQOLResourceSwing.lua:457 |
| resourceSwing / 콤보 포인트 | 구슬 크기 | 8 / 40 / 1 | KHQOL_ResourceSwing/ResourceSwing/KHQOLResourceSwing.lua:457 |
| resourceSwing / 콤보 포인트 | 분할 바 높이 | 4 / 30 / 1 | KHQOL_ResourceSwing/ResourceSwing/KHQOLResourceSwing.lua:457 |
| resourceSwing / 콤보 포인트 | 분할 바 폭 | 100 / 600 / 5 | KHQOL_ResourceSwing/ResourceSwing/KHQOLResourceSwing.lua:457 |
| resourceSwing / 콤보 포인트 | 콤보 X 위치 | -3000 / 3000 / 1 | KHQOL_ResourceSwing/ResourceSwing/KHQOLResourceSwing.lua:457 |
| resourceSwing / 콤보 포인트 | 콤보 Y 위치 | -3000 / 3000 / 1 | KHQOL_ResourceSwing/ResourceSwing/KHQOLResourceSwing.lua:457 |
| resourceSwing / 콤보 포인트 | 포인트 간격 | 0 / 12 / 1 | KHQOL_ResourceSwing/ResourceSwing/KHQOLResourceSwing.lua:457 |
| resourceSwing / 크기 | 높이 | 10 / 50 / 1 | KHQOL_ResourceSwing/ResourceSwing/KHQOLResourceSwing.lua:457 |
| resourceSwing / 크기 | 스윙 바 높이 | 3 / 20 / 1 | KHQOL_ResourceSwing/ResourceSwing/KHQOLResourceSwing.lua:457 |
| resourceSwing / 크기 | 폭 | 200 / 600 / 10 | KHQOL_ResourceSwing/ResourceSwing/KHQOLResourceSwing.lua:457 |
| threat / 어그로 표시 / 현재 프로필 | 글씨 크기 | 10 / 24 / 1 | KHQOL_Threat/Modules/Threat.lua:525 |
| threat / 위협 수준 알림 / 현재 프로필 | 아이콘 크기 | 12 / 32 / 1 | KHQOL_Threat/Modules/Threat.lua:562 |
| todo / 경로 안내 / 현재 프로필 | 경로 이탈 거리 | 20 / 1000 / 10 | KHQOL_Clock/UI/NoteSettings.lua:118 |
| todo / 경로 안내 / 현재 프로필 | 경유지 도착 반경 | 3 / 50 / 1 | KHQOL_Clock/UI/NoteSettings.lua:114 |
| todo / 노트 지도 좌표 / 현재 프로필 | 연결선 두께 | 1 / 6 / 1 | KHQOL_Clock/UI/NoteSettings.lua:59 |
| todo / 창 크기·모양 / 현재 프로필 | 글자 크기 | 15 / 30 / 1 | KHQOL_Clock/UI/NoteSettings.lua:13 |
| todo / 창 크기·모양 / 현재 프로필 | 배경 불투명도 | 10 / 95 / 5 | KHQOL_Clock/UI/NoteSettings.lua:14 |
| tooltip / 글자·모양 / 현재 프로필 | 텍스트 크기 | -3 / 3 / 1 | KHQOL_Tooltip/Tooltip/Settings.lua:34 |
| tooltip / 동작 / 현재 프로필 | 표시 유지 시간 | -1.5 / 1.5 / 0.5 | KHQOL_Tooltip/Tooltip/Settings.lua:32 |
| tooltip / 배치 방식 / 현재 프로필 | X 위치 | -150 / 150 / 1 | KHQOL_Tooltip/Tooltip/Settings.lua:27 |
| tooltip / 배치 방식 / 현재 프로필 | Y 위치 | -150 / 150 / 1 | KHQOL_Tooltip/Tooltip/Settings.lua:28 |
| unitFrames / player / auras / 플레이어 디버프 | 플레이어 디버프 X 위치 보정 | -300 / 300 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:317 |
| unitFrames / player / auras / 플레이어 디버프 | 플레이어 디버프 Y 위치 보정 | -300 / 300 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:317 |
| unitFrames / player / auras / 플레이어 디버프 | 플레이어 디버프 아이콘 크기 | 8 / 64 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:308 |
| unitFrames / player / auras / 플레이어 디버프 | 플레이어 디버프 최대 행 수 | 1 / 4 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:313 |
| unitFrames / player / auras / 플레이어 디버프 | 플레이어 디버프 행당 개수 | 3 / 10 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:312 |
| unitFrames / player / auras / 플레이어 버프 | 플레이어 버프 X 위치 보정 | -300 / 300 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:317 |
| unitFrames / player / auras / 플레이어 버프 | 플레이어 버프 Y 위치 보정 | -300 / 300 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:317 |
| unitFrames / player / auras / 플레이어 버프 | 플레이어 버프 아이콘 크기 | 8 / 64 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:308 |
| unitFrames / player / auras / 플레이어 버프 | 플레이어 버프 최대 행 수 | 1 / 4 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:313 |
| unitFrames / player / auras / 플레이어 버프 | 플레이어 버프 행당 개수 | 3 / 10 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:312 |
| unitFrames / player / bars / 자원 수치 위치 | 자원 수치 X 좌표 | -50 / 50 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:294 |
| unitFrames / player / bars / 자원 수치 위치 | 자원 수치 Y 좌표 | -50 / 50 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:294 |
| unitFrames / target / bars / 자원 수치 위치 | 자원 수치 X 좌표 | -50 / 50 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:294 |
| unitFrames / target / bars / 자원 수치 위치 | 자원 수치 Y 좌표 | -50 / 50 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:294 |
| unitFrames / player / bars / 체력 수치 위치 | 체력 수치 X 좌표 | -50 / 50 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:294 |
| unitFrames / player / bars / 체력 수치 위치 | 체력 수치 Y 좌표 | -50 / 50 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:294 |
| unitFrames / target / bars / 체력 수치 위치 | 체력 수치 X 좌표 | -50 / 50 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:294 |
| unitFrames / target / bars / 체력 수치 위치 | 체력 수치 Y 좌표 | -50 / 50 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:294 |
| unitFrames / focus / bars / 체력·자원 수치 | 체력·자원 수치 글자 크기 | 8 / 24 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:286 |
| unitFrames / pet / bars / 체력·자원 수치 | 체력·자원 수치 글자 크기 | 8 / 24 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:286 |
| unitFrames / player / bars / 체력·자원 수치 | 체력·자원 수치 글자 크기 | 8 / 24 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:286 |
| unitFrames / target / bars / 체력·자원 수치 | 체력·자원 수치 글자 크기 | 8 / 24 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:286 |
| unitFrames / targettarget / bars / 체력·자원 수치 | 체력·자원 수치 글자 크기 | 8 / 24 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:286 |
| unitFrames / focus / bars / 프레임 크기·모양 | 바 사이 간격 | 0 / 20 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:182 |
| unitFrames / focus / bars / 프레임 크기·모양 | 자원 바 높이 | 4 / 100 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:181 |
| unitFrames / focus / bars / 프레임 크기·모양 | 전체 높이 | 24 / 236 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:178 |
| unitFrames / focus / bars / 프레임 크기·모양 | 체력 바 높이 | 8 / 100 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:179 |
| unitFrames / focus / bars / 프레임 크기·모양 | 체력 바 배경 불투명도 | 0 / 1 / 0.1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:193 |
| unitFrames / focus / bars / 프레임 크기·모양 | 프레임 폭 | 60 / 400 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:177 |
| unitFrames / pet / bars / 프레임 크기·모양 | 바 사이 간격 | 0 / 20 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:182 |
| unitFrames / pet / bars / 프레임 크기·모양 | 자원 바 높이 | 4 / 100 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:181 |
| unitFrames / pet / bars / 프레임 크기·모양 | 전체 높이 | 24 / 236 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:178 |
| unitFrames / pet / bars / 프레임 크기·모양 | 체력 바 높이 | 8 / 100 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:179 |
| unitFrames / pet / bars / 프레임 크기·모양 | 체력 바 배경 불투명도 | 0 / 1 / 0.1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:193 |
| unitFrames / pet / bars / 프레임 크기·모양 | 프레임 폭 | 60 / 400 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:177 |
| unitFrames / player / bars / 프레임 크기·모양 | 바 사이 간격 | 0 / 20 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:182 |
| unitFrames / player / bars / 프레임 크기·모양 | 자원 바 높이 | 4 / 100 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:181 |
| unitFrames / player / bars / 프레임 크기·모양 | 전체 높이 | 24 / 236 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:178 |
| unitFrames / player / bars / 프레임 크기·모양 | 체력 바 높이 | 8 / 100 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:179 |
| unitFrames / player / bars / 프레임 크기·모양 | 체력 바 배경 불투명도 | 0 / 1 / 0.1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:193 |
| unitFrames / player / bars / 프레임 크기·모양 | 프레임 폭 | 60 / 400 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:177 |
| unitFrames / target / bars / 프레임 크기·모양 | 바 사이 간격 | 0 / 20 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:182 |
| unitFrames / target / bars / 프레임 크기·모양 | 자원 바 높이 | 4 / 100 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:181 |
| unitFrames / target / bars / 프레임 크기·모양 | 전체 높이 | 24 / 236 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:178 |
| unitFrames / target / bars / 프레임 크기·모양 | 체력 바 높이 | 8 / 100 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:179 |
| unitFrames / target / bars / 프레임 크기·모양 | 체력 바 배경 불투명도 | 0 / 1 / 0.1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:193 |
| unitFrames / target / bars / 프레임 크기·모양 | 프레임 폭 | 60 / 400 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:177 |
| unitFrames / targettarget / bars / 프레임 크기·모양 | 바 사이 간격 | 0 / 20 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:182 |
| unitFrames / targettarget / bars / 프레임 크기·모양 | 자원 바 높이 | 4 / 100 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:181 |
| unitFrames / targettarget / bars / 프레임 크기·모양 | 전체 높이 | 24 / 236 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:178 |
| unitFrames / targettarget / bars / 프레임 크기·모양 | 체력 바 높이 | 8 / 100 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:179 |
| unitFrames / targettarget / bars / 프레임 크기·모양 | 체력 바 배경 불투명도 | 0 / 1 / 0.1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:193 |
| unitFrames / targettarget / bars / 프레임 크기·모양 | 프레임 폭 | 60 / 400 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:177 |
| unitFrames / player / class / 보조 표시 위치 | 보조 표시 X 좌표 | -3000 / 3000 / 1 | KHQOL_UnitFrames/UI/PlayerAuxSettings.lua:30 |
| unitFrames / player / class / 보조 표시 위치 | 보조 표시 Y 좌표 | -3000 / 3000 / 1 | KHQOL_UnitFrames/UI/PlayerAuxSettings.lua:30 |
| unitFrames / player / class / 보조 표시 위치 | 보조 표시 글자 크기 | 8 / 24 / 1 | KHQOL_UnitFrames/UI/PlayerAuxSettings.lua:32 |
| unitFrames / player / class / 토템·임시 소환 | 프레임 X 좌표 | -3000 / 3000 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:334 |
| unitFrames / player / class / 토템·임시 소환 | 프레임 Y 좌표 | -3000 / 3000 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:334 |
| unitFrames / focus / labels / 레벨 | 레벨 X 위치 보정 | -100 / 100 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:275 |
| unitFrames / focus / labels / 레벨 | 레벨 Y 위치 보정 | -100 / 100 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:275 |
| unitFrames / focus / labels / 레벨 | 레벨 글자 크기 | 8 / 30 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:263 |
| unitFrames / pet / labels / 레벨 | 레벨 X 위치 보정 | -100 / 100 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:275 |
| unitFrames / pet / labels / 레벨 | 레벨 Y 위치 보정 | -100 / 100 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:275 |
| unitFrames / pet / labels / 레벨 | 레벨 글자 크기 | 8 / 30 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:263 |
| unitFrames / player / labels / 레벨 | 레벨 X 위치 보정 | -100 / 100 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:275 |
| unitFrames / player / labels / 레벨 | 레벨 Y 위치 보정 | -100 / 100 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:275 |
| unitFrames / player / labels / 레벨 | 레벨 글자 크기 | 8 / 30 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:263 |
| unitFrames / target / labels / 레벨 | 레벨 X 위치 보정 | -100 / 100 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:275 |
| unitFrames / target / labels / 레벨 | 레벨 Y 위치 보정 | -100 / 100 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:275 |
| unitFrames / target / labels / 레벨 | 레벨 글자 크기 | 8 / 30 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:263 |
| unitFrames / targettarget / labels / 레벨 | 레벨 X 위치 보정 | -100 / 100 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:275 |
| unitFrames / targettarget / labels / 레벨 | 레벨 Y 위치 보정 | -100 / 100 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:275 |
| unitFrames / targettarget / labels / 레벨 | 레벨 글자 크기 | 8 / 30 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:263 |
| unitFrames / focus / labels / 이름 | 이름 X 위치 보정 | -100 / 100 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:275 |
| unitFrames / focus / labels / 이름 | 이름 Y 위치 보정 | -100 / 100 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:275 |
| unitFrames / focus / labels / 이름 | 이름 글자 크기 | 8 / 30 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:263 |
| unitFrames / pet / labels / 이름 | 이름 X 위치 보정 | -100 / 100 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:275 |
| unitFrames / pet / labels / 이름 | 이름 Y 위치 보정 | -100 / 100 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:275 |
| unitFrames / pet / labels / 이름 | 이름 글자 크기 | 8 / 30 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:263 |
| unitFrames / player / labels / 이름 | 이름 X 위치 보정 | -100 / 100 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:275 |
| unitFrames / player / labels / 이름 | 이름 Y 위치 보정 | -100 / 100 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:275 |
| unitFrames / player / labels / 이름 | 이름 글자 크기 | 8 / 30 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:263 |
| unitFrames / target / labels / 이름 | 이름 X 위치 보정 | -100 / 100 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:275 |
| unitFrames / target / labels / 이름 | 이름 Y 위치 보정 | -100 / 100 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:275 |
| unitFrames / target / labels / 이름 | 이름 글자 크기 | 8 / 30 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:263 |
| unitFrames / targettarget / labels / 이름 | 이름 X 위치 보정 | -100 / 100 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:275 |
| unitFrames / targettarget / labels / 이름 | 이름 Y 위치 보정 | -100 / 100 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:275 |
| unitFrames / targettarget / labels / 이름 | 이름 글자 크기 | 8 / 30 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:263 |
| unitFrames / player / status / 대상 징표 | 대상 징표 X 위치 보정 | -400 / 400 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:206 |
| unitFrames / player / status / 대상 징표 | 대상 징표 Y 위치 보정 | -400 / 400 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:206 |
| unitFrames / target / status / 대상 징표 | 대상 징표 X 위치 보정 | -400 / 400 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:206 |
| unitFrames / target / status / 대상 징표 | 대상 징표 Y 위치 보정 | -400 / 400 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:206 |
| unitFrames / target / status / 몬스터 마크 | 몬스터 마크 X 위치 보정 | -400 / 400 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:246 |
| unitFrames / target / status / 몬스터 마크 | 몬스터 마크 Y 위치 보정 | -400 / 400 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:246 |
| unitFrames / target / status / 몬스터 마크 | 몬스터 마크 크기 | 8 / 40 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:243 |
| unitFrames / focus / status / 상태·징표 · 대상 표시기 | 상태·징표 X 위치 보정 | -200 / 200 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:217 |
| unitFrames / focus / status / 상태·징표 · 대상 표시기 | 상태·징표 Y 위치 보정 | -200 / 200 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:217 |
| unitFrames / pet / status / 상태·징표 · 대상 표시기 | 상태·징표 X 위치 보정 | -200 / 200 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:217 |
| unitFrames / pet / status / 상태·징표 · 대상 표시기 | 상태·징표 Y 위치 보정 | -200 / 200 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:217 |
| unitFrames / targettarget / status / 상태·징표 · 대상 표시기 | 상태·징표 X 위치 보정 | -200 / 200 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:217 |
| unitFrames / targettarget / status / 상태·징표 · 대상 표시기 | 상태·징표 Y 위치 보정 | -200 / 200 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:217 |
| unitFrames / pet / status / 소환수 포만감 아이콘 | 포만감 아이콘 X 위치 보정 | -400 / 400 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:230 |
| unitFrames / pet / status / 소환수 포만감 아이콘 | 포만감 아이콘 Y 위치 보정 | -400 / 400 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:230 |
| unitFrames / player / status / 전투 상태 | 전투 상태 X 위치 보정 | -400 / 400 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:206 |
| unitFrames / player / status / 전투 상태 | 전투 상태 Y 위치 보정 | -400 / 400 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:206 |
| unitFrames / player / status / 휴식 상태 | 휴식 상태 X 위치 보정 | -400 / 400 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:206 |
| unitFrames / player / status / 휴식 상태 | 휴식 상태 Y 위치 보정 | -400 / 400 / 1 | KHQOL_UnitFrames/UI/UnitFrameDetails.lua:206 |
