# KHQOL 1.11.7.8 변경·검증 보고서

기준은 KHQOL 1.11.7.7 전체 설치 ZIP입니다. 가방 휴지통과 아이템 보호를 포함한 애드온 19개 폴더를 WoW Forever 1.60.1 / 빌드 70938 / Interface 16001용 1.11.7.8 전체 ZIP으로 패키징했습니다.

- **대상 시전바** — KHQOL이 기존 위치의 기본 시전바를 투명하게 유지하면 게임의 완료 페이드가 생략될 수 있습니다. 완료 처리 시 KHQOL 시전바를 직접 숨기고, 다음 시전 시작 시 저장된 위치에서 다시 표시합니다. 시전 중단 표시에도 종료 시간을 적용합니다. [기본 시전바 종료 처리와 페이드 조건](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UIPanels_Game/Shared/CastingBarFrame.lua)
- **퀘스트 경험치** — 로그의 전체 개수와 노출된 줄의 개수 차이 때문에 확인된 보상까지 보류하던 조건을 제거했습니다. 기본 추적기의 완료 상태를 기준으로 현재 보유한 미반납 퀘스트의 보상을 합산합니다. 화면에 노출된 항목, 확인했던 퀘스트, 기본 추적 목록으로 확인할 수 있는 퀘스트를 검사합니다. 기본 로그와 추적 목록에 모두 나타나지 않고 아직 확인한 적 없는 퀘스트는 조회 가능한 상태가 된 뒤 포함됩니다. [Forever 퀘스트 로그 API](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua) · [기본 추적기의 완료 판정](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_ObjectAPI/Mainline/Quest.lua#L38-L48)
- XP가 바뀌면 이전 예상치는 숨기고 현재 퀘스트 상태를 다시 읽습니다. 전투·탐험 XP를 얻은 경우 별도의 퀘스트 로그 이벤트가 없어도 갱신합니다. 이미 반납하거나 포기한 항목은 늦게 받은 로그 때문에 합계에 다시 들어가지 않도록 처리합니다. 보상 XP는 게임이 제공하는 값을 사용합니다. [기본 UI의 ID별 보상 XP 조회](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_ObjectiveTracker/Blizzard_ScenarioObjectiveTracker.lua#L962-L969)

## 검증

| 구분 | 결과 |
| --- | --- |
| 정적 | Lua 230개, XML 8개, TOC 19개 및 SavedVariables 선언 12개 검사 통과 |
| 모의 | 설치 구성 5개에서 시전바와 기존 기능 475건, 휴지통·아이템 보호 476건, 퀘스트 경험치 75건 통과 |
| 대상 시전바 | 전투 중 저장 위치, 읽기 제한 값, 기본 바가 표시된 채 종료되는 경우, 종료 후 재표시 방지, 다음 시전, 연속 시전과 중단 표시를 모의 검증 |
| 퀘스트 XP | 부분 로그·접힌 항목, 보상 데이터 늦게 로딩, 전투 XP 뒤 갱신, 반납·포기 뒤 중복 방지, 반복 퀘스트 재수락, 보상창 닫은 뒤 표시를 모의 검증 |
| 실제 인게임 | 1.11.7.8의 시전 종료와 사용자 스크린샷에 나온 미반납 퀘스트는 미검증 |

동작 변경 파일은 `KHQOL/BasicUI/CastBar/TargetStyle.lua`와 `KHQOL_ExperienceBar/Modules/QuestExperiencePreview.lua`입니다.
