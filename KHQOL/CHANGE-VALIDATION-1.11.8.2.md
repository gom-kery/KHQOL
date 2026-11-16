# KHQOL 1.11.8.2 변경·검증 보고서

## 기준

- 기준 ZIP은 `KHQOL-1.11.8.1-Full.zip`입니다. 내부 애드온 19개 모두 버전 1.11.8.1과 Interface 16001을 확인했습니다. ZIP CRC를 검사하고 별도 작업 사본에 풀었습니다.
- 결과 버전은 직전 패치의 다음 번호인 1.11.8.2로 정했습니다. 설치된 WoW Forever의 실행 파일은 1.60.1.70938이며 Baganator의 설치 버전은 860입니다. 게임과 설치된 애드온은 파일을 읽어 버전과 API를 확인했습니다.

## 동작

- **버프 감사 알림**은 기존 위치 편집의 미리보기로 첫 아이콘을 옮길 수 있습니다. 아이콘 크기는 32~112 px입니다. 기본값은 72 px와 종전의 화면 중앙 위 80 위치입니다. 위치와 크기는 프로필에 저장되며 새 알림 방향도 기존대로 적용합니다.
- **전문기술 목록**의 보조 전문기술 표시는 기본 ON입니다. OFF로 바꾸면 부캐 목록에서 요리·낚시·응급치료를 숨깁니다. 저장 기록에도 모두 남습니다. 클라이언트에서 부캐의 실제 습득 도안을 읽을 기록이 없으므로 상세 클릭은 비활성화했습니다. 상세창 코드와 도안 자료는 패키지에 보존했습니다.
- **퀘스트 목록**은 전투 중 공개 목표 데이터를 읽어 진행과 완료를 표시합니다. 기존 이벤트와 퀘스트 기준 변경 이벤트가 갱신을 요청합니다. 스크롤과 수동 지역 접기·펼치기는 보호된 프레임에서 분리했습니다. 정상적으로 표시되던 목록은 전투 진입 전 확보한 화면 영역을 재사용합니다. 전투 중 추적 목록을 일시적으로 읽을 수 없으면 마지막으로 확인한 목록을 사용합니다. [포에버 퀘스트 이벤트 정의](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua#L1289-L1306)
- **퀘스트 아이템 버튼**은 텍스트 목록과 독립된 화면 영역에 있습니다. 기본 보안 상태 드라이버가 전투 진입 시 버튼 영역을 숨깁니다. `PLAYER_REGEN_ENABLED`에서 퀘스트를 새로 읽고 화면에 온전히 보이는 행에만 버튼을 다시 연결합니다. 사용자가 바꾼 지역 상태와 가능한 스크롤 위치를 적용합니다. [포에버 보안 상태 드라이버](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_RestrictedAddOnEnvironment/SecureStateDriver.lua#L22-L25)
- **가방 휴지통**은 전투 중 보호·퀘스트·수량 검사를 통과하면 기본 확인창을 요청합니다. 선택한 등급도 전투 중에는 기본 확인창으로 연결합니다. 최종 확인은 게임이 처리합니다. 유효한 확인창은 전투에 들어가도 계속 사용할 수 있으며 커서가 바뀌면 취소합니다. 수락 후 파괴되지 않은 것으로 보이면 안내하고 파괴를 다시 요청하지 않습니다. `DeleteCursorItem`은 호출 제한이 있고 성공 여부를 반환하지 않습니다. [포에버 파괴 API](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/GameCursorDocumentation.lua#L51-L55) · [기본 파괴 확인창 정의](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_StaticPopup_Game/GameDialogDefs.lua#L1486-L1512)

## 전투 중 가방별 결과

전투 전에 열어 둔 가방과 전투 중 새로 연 가방을 모의 검사했습니다. 아래의 수량 확인은 게임의 기본 클릭을 모사한 결과입니다.

| 가방 보기 | 드롭 인식 | 기본 확인창을 통한 파괴 | 확인 없는 즉시 파괴 |
| --- | --- | --- | --- |
| 기본 통합 | 모의 통과 · 인게임 미검증 | 모의 통과 · 인게임 미검증 | 전투 중 비활성화 · 인게임 미검증 |
| 기본 개별 | 모의 통과 · 인게임 미검증 | 모의 통과 · 인게임 미검증 | 전투 중 비활성화 · 인게임 미검증 |
| Baganator 단일 | 모의 통과 · 인게임 미검증 | 모의 통과 · 인게임 미검증 | 전투 중 비활성화 · 인게임 미검증 |
| Baganator 카테고리 | 모의 통과 · 인게임 미검증 | 모의 통과 · 인게임 미검증 | 전투 중 비활성화 · 인게임 미검증 |

## 검증 범위

| 항목 | 정적·모의 결과 | 실제 포에버 |
| --- | --- | --- |
| 버프 감사 알림 | 위치 편집 대상, 첫 아이콘 좌표, 다른 알림의 방향과 간격, 크기와 프로필 저장 확인 | 인게임 미검증 |
| 전문기술 목록 | 현재 열린 창의 필터 갱신, 기록 보존, 옵션 저장, 상세 클릭 비활성화 확인 | 인게임 미검증 |
| 퀘스트 진행 | 전투 중 처치 `2/10 → 3/10`, 수집 `0/5 → 2/5`, 완료, 목록을 읽을 수 없는 순간에 마지막 목록 유지 확인 | 인게임 미검증 |
| 스크롤·지역·퀘스트 아이템 | 전투 중 일반 목록 갱신, 보안 버튼 숨김, 전투 중 속성 변경 방지, 전투 종료 후 접기·스크롤 유지와 최신 아이템 연결 확인 | 인게임 미검증 |
| 휴지통 | 드롭 시 확인창 노출과 확인 후 수량 감소를 별도로 검사했습니다. 분할·전체 묶음 수락과 전체 묶음 취소, 보호, 진행 중 퀘스트, 커서 교체, 기본 확인창 도중 전투 진입, 차단 안내와 재실행 방지를 확인했습니다. | 인게임 미검증 |
| 회귀 | 비전투 휴지통 등급과 자동 입력, 잡템 판매·자동 수리, 지도 핀, 기본 추적기 표시 복원, 프로필과 선택 모듈 조합 검사 | 기본 월드맵·ESC 및 `/reload` 포함 인게임 미검증 |

정적 검사는 Lua 234개, XML 8개, TOC 19개와 SavedVariables 선언 12개를 확인했습니다. 설치 구성 다섯 가지에서 모의 검사 1,527건을 통과했습니다.

## 수정 파일

- `KHQOL_QuestNavigator/QuestNavigator/Tracker.lua`
- `KHQOL_Convenience/Modules/BuffThanks.lua`, `AltProfessions.lua`, `Professions.lua`, `BagTrash.lua`
- `KHQOL_Convenience/UI/ConvenienceDetails.lua`, `ProfessionSettings.lua`, `BagItemSettings.lua`, `SearchIndex.lua`
- `KHQOL_Convenience/Adapters.lua`, `KHQOL/Profiles.lua`
- `KHQOL/README.md`, `KHQOL/CHANGELOG.md`, `KHQOL/INSTALL-GUIDE.md` 및 이 보고서
- 버전 갱신 파일은 TOC 19개, `KHQOL/Bootstrap.lua`, `KHQOL_Campfire/Campfire/Core.lua`, `KHQOL_Labs/Modules/ObjectHighlightDiagnostics.lua`, `KHQOL_Map/Core.lua`입니다.
