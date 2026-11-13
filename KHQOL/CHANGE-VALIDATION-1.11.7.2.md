# KHQOL 1.11.7.2 변경·검증

기준은 KHQOL 1.11.7.1의 기본 ZIP과 선택 프레임 ZIP입니다.

## 원인과 수정

- Forever의 BugTabs 저장 기록에서 `ObjectiveTrackerFrame:Show()`와 `QuestObjectiveTracker:SetPoint()` 차단이 `KHQOL_QuestNavigator`에 귀속된 것을 확인했습니다. 기존 KHQOL 퀘스트 아이템 버튼의 부모와 앵커를 따라가면 두 기본 프레임 모두에 연결됐습니다. 이 연결을 검사하는 모의 환경에서 두 차단을 재현했습니다. [Forever 기본 추적기 코드](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_ObjectiveTracker/Blizzard_ObjectiveTrackerContainer.lua#L83-L117)
- KHQOL 목록, 퀘스트 수, 아이템 버튼을 `UIParent` 아래 KHQOL 전용 프레임에 배치합니다. 기본 추적기에서 읽은 화면 좌표와 배율로 위치를 맞추며, 아이템 사용 버튼의 보호 템플릿을 유지합니다. [Forever 보호 버튼 템플릿](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.xml#L2-L9)
- 전투 중 KHQOL의 보호된 배치 갱신과 모듈 OFF 정리는 전투 종료 시 적용합니다. 게임 편집 모드와 모듈 OFF에서는 KHQOL이 숨긴 기본 외형을 복원합니다.

## 검증 결과

- 새 회귀 검사 **8/8**. 두 기본 프레임과의 연결 분리, 아이템 버튼과 화면 좌표, 배율·이동·접기, 전투 종료 반영, 모듈 OFF 및 게임 편집 모드 복원을 검사했습니다.
- 전체 모의 검사 **269/269**. 이전 261개 시나리오를 수정본에서 다시 실행했습니다.
- Lua 5.1 문법 222개, XML 7개, TOC 19개, 저장 변수 12개 소유권, ZIP CRC·파일별 SHA-256 및 제외 폴더를 확인했습니다.
- 실제 Forever 클라이언트에서의 전투 재현과 아이템 사용은 미실시입니다.
