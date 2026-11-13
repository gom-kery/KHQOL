# KHQOL 1.11.7.4 변경·검증

2026-11-13 · 검증용 빌드 · 기준 KHQOL 1.11.7.3

## 변경 사항

| 항목 | 변경 |
| --- | --- |
| 전문기술 | 아이콘 위아래 기본 여백을 4px로 맞췄습니다. 숙련도를 바깥쪽으로 둘 때는 글자 높이만큼 아래 공간을 확보합니다. `전문기술 사이 간격`은 2~16px이며, 새 값이 없는 프로필은 4px를 사용합니다. 클릭 영역과 패널 크기가 함께 바뀝니다. |
| 길드 툴팁 | 레벨 열을 오른쪽 정렬하고 8px 간격 뒤에 이름 열을 왼쪽 정렬합니다. 두 열 모두 기존 직업색을 사용합니다. |
| 부캐 소지금 | 툴팁의 설명 한 줄을 제거했습니다. 제목, 저장된 캐릭터 이름과 금액, 빈 목록 안내는 유지합니다. |
| 대상 시전바 | `KHQOL 대상 시전바 사용`이 켜져 있을 때 저장 X/Y와 대상 외형을 독립 표시 바에 적용합니다. 기본 바의 위치·크기와 기본 시전 처리 경로는 그대로 사용합니다. |

## 길드 클릭 경로

사용자 로그의 차단은 기본 커뮤니티 목록이 `C_Club.SetAvatarTexture`를 호출하는 과정에서 발생했습니다. 이전 버전은 애드온 클릭에서 기본 창을 직접 열고 `SelectClub`과 `SetDisplayMode`를 호출했습니다. 이번에는 Blizzard의 `SecureActionButtonTemplate`의 `click` 동작으로 기본 길드 버튼에 위임합니다. 기본 버튼의 현재 화면 선택을 따릅니다. 클라이언트가 위임을 금지하면 기본 길드 버튼 안내를 사용합니다. 전투 중에는 위임 버튼이 숨겨집니다. 통합 위치 편집과 드래그에서는 클릭을 전달하지 않습니다. [Forever 기본 길드 버튼](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_MicroMenu/Mainline/MainMenuBarMicroButtons.lua#L1217-L1224) · [기본 목록의 아바타 호출](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_Communities/CommunitiesList.lua#L468-L488) · [보호 클릭 구현](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua#L520-L527)

## 대상 시전바 경로

기본 대상 바의 `AdjustPosition`은 대상과 오라 배치에 따라 앵커를 다시 씁니다. 이전 버전은 전투 중 보호 프레임의 위치 변경을 보류하므로 기본 앵커가 다시 적용되면 사용자 오프셋이 전투 중 유지되지 않을 수 있었습니다. 새 바는 읽을 수 있는 화면 좌표로 배치하고 전투 중에는 마지막으로 적용한 좌표를 사용합니다. 기본 StatusBar의 최솟값·최댓값·진행값을 대응하는 StatusBar에 전달합니다. 기본 바의 표시·숨김과 중단 알림을 따라가며, 필수 위젯 값 전달이 막히면 기본 표시로 복귀합니다. 모듈 OFF나 게임 편집 모드에서도 기본 바를 표시합니다. [Forever 대상 바 위치 재계산](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UnitFrame/Mainline/TargetFrame.lua#L731-L789) · [StatusBar 위젯 API](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleStatusBarAPIDocumentation.lua#L217-L225)

## 검사

- Lua 5.1 문법 227개, XML 7개, TOC 19개, SavedVariables 소유권 12개, ZIP 무결성 및 기존 패키지 분리를 확인했습니다.
- 모의 검사 450개를 통과했습니다. Base 107, Base+UnitFrames 125, Clock 미설치 77, Convenience 미설치 55, 신규 Base 86입니다. 전문기술 셀 크기와 간격, 길드 열 정렬과 클릭/드래그/전투 분기, 소지금 설명 제거, 대상 바의 전투 중 재배치·제한값 전달·기본 표시 복귀를 포함합니다.
- 실제 Forever 접속 검증은 미실시입니다. 길드 버튼 위임에서 `SetAvatarTexture` 차단이 사라지는지, 던전 안 적대 대상의 시전·채널·중단과 빠른 대상 변경에서 저장 위치가 유지되는지 확인이 필요합니다.

주요 수정 위치는 `KHQOL/Profiles.lua`, `KHQOL/MoneyRecords.lua`, `KHQOL/BasicUI/CastBar/{Core,Target,TargetStyle}.lua`, `KHQOL_Clock/Clock/Guild.lua`, `KHQOL_Convenience/Modules/Professions.lua` 및 해당 설정·검색입니다. UnitFrames는 1.11.7.4 버전 표기를 맞췄습니다.
