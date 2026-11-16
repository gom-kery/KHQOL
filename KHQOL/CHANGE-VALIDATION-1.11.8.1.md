# KHQOL 1.11.8.1 변경·검증 보고서

## 기준과 결과

- 기준은 `KHQOL-1.11.8.0-Full.zip`입니다. 애드온 19개의 TOC 버전과 Interface 16001, ZIP CRC를 확인했습니다.
- 결과는 `KHQOL-1.11.8.1-Full.zip`입니다. 대상 클라이언트는 WoW Forever 1.60.1, 빌드 70938, Interface 16001입니다.

## 변경 사항

- 조회창 제목을 **전문기술 목록**, 두 번째 열을 **전문기술**로 바꿨습니다. 오른쪽 여백을 줄이고 목록 행 수에 맞춰 창 높이를 조정합니다. 긴 목록은 스크롤할 수 있습니다.
- 캐릭터명에 WoW 직업 색상을 적용합니다. 이전 전문기술 기록에 직업 정보가 없으면 기존 부캐 소지금 기록에서 확인합니다. 두 기록 모두 직업 정보가 비어 있으면 해당 캐릭터로 접속할 때까지 기본 글자색을 표시합니다.
- **전문기술** 또는 **숙련**을 클릭하면 선택한 부캐의 전문기술 상세 목록이 열립니다. 현재·최대 저장 숙련도, 도안·기술명, 필요 숙련도, 숙련 조건 충족 여부를 표시합니다. **목록**으로 돌아가면 이전 스크롤 위치를 복원합니다.
- 도안·기술 자료는 설치된 What’s Training? 11.4.8의 포에버용 `Crafting/Recipes/Camelot`을 사용했습니다. 전문기술 12개의 주문 ID와 필요 숙련도 2,188건 및 MIT 라이선스를 포함했습니다. 상세 목록을 사용하기 위해 What’s Training?을 별도로 설치할 필요는 없습니다. 게임에서 이름을 불러오지 못하면 주문 ID를 표시합니다. [이름 조회 API](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellDocumentation.lua#L478-L491) · [이름 비동기 로드 API](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellDocumentation.lua#L937-L946)
- **충족**은 마지막으로 저장한 숙련도가 요구치에 도달했음을 뜻합니다. NPC에게 배운 기술이나 도안 아이템으로 배운 기술의 실제 습득 여부와 재료·퀘스트 조건은 이 창에서 확인할 수 없습니다.

## 수정 파일

- `KHQOL_Convenience/Modules/AltProfessions.lua` — 직업 색상 기록, 조회창 배치와 상세 목록.
- `KHQOL_Convenience/Data/ProfessionCatalog.lua`, `KHQOL_Convenience/Data/WhatsTraining-LICENSE.txt` — 포에버 도안·기술 자료와 사용권.
- 애드온 TOC 19개, `KHQOL/Bootstrap.lua`, `KHQOL_Campfire/Campfire/Core.lua`, `KHQOL_Labs/Modules/ObjectHighlightDiagnostics.lua`, `KHQOL_Map/Core.lua` — 버전 갱신. `KHQOL_Convenience/KHQOL_Convenience.toc`에 목록 자료 로드 추가.
- `KHQOL/README.md`, `KHQOL/CHANGELOG.md`, `KHQOL/INSTALL-GUIDE.md`, 이 보고서 — 사용 방법과 검증 결과.

## 검증

| 구분 | 확인 결과 |
| --- | --- |
| 자료 비교 | 설치된 What’s Training?에서 전문기술별 주문 ID와 필요 숙련도 쌍 2,188건을 대조하고 중복이 없음을 확인했습니다. |
| 정적 검사 | Lua 234개, XML 8개, TOC 19개를 검사했습니다. SavedVariables 선언 12개를 확인했습니다. |
| 모의 검사 | 구성 5개에서 1,315개 검사를 통과했습니다. 열 이름과 창 크기, 기존 기록의 직업 색상, 전문기술·숙련 열 클릭, 요구치 비교, 스크롤, 지연된 이름 갱신, 목록 복귀를 포함합니다. |
| 실제 인게임 | **미검증.** 게임에서의 창 크기와 색상, 클릭 위치, 한글 도안명, 캐릭터 전환과 `/reload`는 실행하지 못했습니다. |
