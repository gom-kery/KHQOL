# KHQOL 1.11.7.9 변경·검증 보고서

기준은 KHQOL 1.11.7.8 전체 설치 ZIP입니다. WoW Forever 1.60.1 / 빌드 70938 / Interface 16001용으로 패키징했습니다.

| 수정 | 적용 동작 |
| --- | --- |
| 길드 접속 툴팁 | 내 캐릭터의 행은 로컬 캐릭터의 현재 레벨을 표시합니다. 열린 툴팁에 레벨업과 플레이어 레벨 갱신을 반영합니다. 다른 길드원은 서버가 제공하는 길드 명단의 레벨을 사용합니다. |
| 휴지통 | 퀘스트 분류·귀속 정보·관련 퀘스트 ID만으로 포기 경고를 띄우던 조건을 수정했습니다. 진행 중인 퀘스트와의 연관이 확인되면 퀘스트용 경고를 유지합니다. 퀘스트 관련 메타데이터가 있지만 진행 중인 퀘스트가 확인되지 않으면 즉시 파괴를 건너뛰고 일반 수동 확인창을 표시합니다. 퀘스트 상태를 읽지 못하면 수동 확인을 유지합니다. |
| 지도 핀 공유 | 월드맵의 사용자 지정 핀에만 적용합니다. 기본 동작이 현재 채팅 입력창에 링크를 넣은 뒤 호출하는 자동 클립보드 단계에서 오류가 났습니다. 열린 채팅 입력창이 있으면 링크를 그대로 유지합니다. 입력창이 없으면 수동 복사할 핀 명령을 표시합니다. 링크 전송은 사용자가 직접 합니다. |

구현 시 길드 명단의 `isSelf`와 `guid`, 가방 아이템의 `isQuestItem`·`questID`·`isActive`를 확인했습니다. 지도는 재사용되는 월드맵 핀의 복사 단계에만 적용합니다. [길드 명단 데이터](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/ClubDocumentation.lua#L1724-L1742) · [가방 퀘스트 메타데이터](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/ContainerDocumentation.lua#L779-L786) · [기본 지도 핀 공유 동작](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedMapDataProviders/WaypointLocationDataProvider.lua#L136-L179)

## 검증

- Lua 231개, XML 8개, TOC 19개, SavedVariables 선언 12개 정적 검사 통과. 전체 ZIP CRC와 작업 사본의 바이트 일치를 확인했습니다.
- 설치 구성 5개에서 모의 검사 총 **1,075건** 통과. 캐릭터 레벨 21과 캐시 레벨 불일치, 레벨 변경 시 열린 툴팁 갱신, 홉 열매와 같은 비활성 퀘스트 분류 아이템 및 활성 퀘스트 아이템의 확인창 분기, 퀘스트 ID 0, 기존 핀과 새 핀에서 귓속말 초안·수신인 유지, 수동 복사창을 검사했습니다.
- **실제 인게임 미검증**. 첨부 화면의 결과는 수정 전 제보이며, 1.11.7.9에서 홉 열매의 실제 슬롯 상태나 지도 핀 공유 입력은 다시 확인하지 못했습니다.

동작 변경 파일은 `KHQOL_Clock/Clock/Guild.lua`, `KHQOL_Convenience/Modules/BagTrash.lua`, `KHQOL_Map/WaypointShare.lua`입니다. 지도 모듈 TOC에 새 파일을 등록했습니다.
