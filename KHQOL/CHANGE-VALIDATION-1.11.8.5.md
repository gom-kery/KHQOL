# KHQOL 1.11.8.5 변경·검증 보고서

- 기준 ZIP은 1.11.8.4이며 결과 ZIP은 1.11.8.5입니다. 대상은 WoW Forever 1.60.1, 빌드 70938, Interface 16001입니다.
- `KHQOL_Convenience/Modules/QuestRewardPrices.lua`에서 동전의 위치를 보상 행 오른쪽 위 안쪽으로 옮겼습니다. 수락 전 미리보기와 완료 보상 선택창이 사용하는 기본 템플릿의 이름 배경에는 투명한 여백이 있어, 보상 행을 기준으로 배치했습니다. [포에버 보상 아이템 템플릿](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_ItemButton/Mainline/ItemButtonTemplate.xml#L160-L185)
- 모의 검사에서 두 창의 동전 기준점과 여백, 기본 클릭과 툴팁 경로를 확인했습니다. 전체 모의 검사 1,815건을 통과했습니다. 실제 화면의 표시 위치는 인게임 미검증입니다.
