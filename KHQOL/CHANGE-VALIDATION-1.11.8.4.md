# KHQOL 1.11.8.4 변경·검증 보고서

기준은 `KHQOL-1.11.8.3-Full.zip`입니다. 원본 CRC, 애드온 19개의 버전과 Interface 16001을 확인하고 별도 작업 사본을 사용했습니다. 결과 버전은 다음 패치 번호인 1.11.8.4로 지정했습니다. 설치된 실행 파일에서 WoW Forever 1.60.1.70938을 확인했습니다.

## 기존 기능 개선

| 항목 | 코드에서 확인한 원인과 수정 | 정적·모의 검사 | 실제 포에버 |
| --- | --- | --- | --- |
| 귀환석 휴지통 | 퀘스트 분류가 있으면 등급을 선택해도 즉시 경로에 들어가지 않았습니다. `KHQOL_Convenience/Modules/BagTrash.lua`에서 기본 귀환석 ID 6948이 연결된 퀘스트 없이 안전한 상태로 확인될 때 선택 등급을 적용합니다. | 일반 등급 선택·미선택, 연결된 진행 퀘스트, 보호 목록, 전투 중 기본 확인, 게임 자체 확인이 반환되는 모의 드롭을 검사했습니다. | **인게임 미검증.** 실제 아이템 등급·퀘스트 분류와 즉시 파괴 또는 게임 확인창 중 어느 결과가 나오는지는 확인하지 못했습니다. |
| 길드 초대 | 이전 처리 기록이 동일 송신자의 새 초대를 막았습니다. `KHQOL_Convenience/GeneralOptions.lua`와 `Modules/GeneralConvenience.lua`에서 기본 초대창의 열림·닫힘과 요청 상태로 세대를 구분합니다. | 중복 이벤트, 같은 송신자 재초대, 다른 초대, 늦은 취소, 예약 교체, 기본값과 초기화 OFF, 기존 ON 저장을 확인했습니다. | **인게임 미검증.** |
| 채집 추적 | 부활 직후 빈 목록을 복원 완료로 처리할 수 있었습니다. `Modules/GeneralConvenience.lua`에서 공개 추적 목록을 재조회하고 저장한 항목이 활성 상태일 때 완료합니다. 수동 선택은 기존 복원 요청을 취소합니다. | 빈 목록, 항목 지연, 호출 성공 후 상태 미변경, 약초·광물 동시 복원, 직접 끄기를 검사했습니다. | **인게임 미검증.** 시체 회수·다른 플레이어의 부활·영혼 치유사 경로는 실제로 실행하지 못했습니다. |
| 아이템 링크와 말머리 | `Modules/ChatAutomation.lua`의 메시지 처리가 포에버의 `\|cnIQ…:` 색상을 인식하지 못했습니다. 이름 기반 색상과 기존 RGB 색상을 읽고, 길이가 맞지 않으면 링크가 있는 원문을 보존합니다. | 한글과 아이템·주문·퀘스트 링크 조합, 길이 제한, 기본 전송 직전 입력창 문자열을 검사했습니다. | **인게임 미검증.** 수신자 화면과 링크 클릭을 확인하지 못했습니다. |
| 버프 리마인더 시전 | 기존 아이콘은 표시 전용 프레임이었습니다. `KHQOL_Labs/BuffReminder/Core.lua`, `BuffReminder/UI.lua`, `Adapters.lua`에서 확인된 주문의 좌클릭을 보안 버튼에 연결합니다. 일반 버프는 자신을 대상으로 하며 설정한 토템은 주문과 표시가 일치할 때 연결합니다. | 주문책의 배운 랭크, 좌클릭 속성, 전투 중 위치가 동일한 아이콘, 주문·아이콘 불일치 차단, 토템과 무기 강화, 테스트 미리보기를 검사했습니다. | **인게임 미검증.** 전투에서는 이미 배치된 버튼과 표시가 일치하는 경우에만 클릭 경로가 열립니다. 전투 중 처음 나타나 미리 준비된 버튼이 없는 알림과 주문이 정해지지 않은 무기 강화는 표시 전용입니다. |
| 경험치바 | 실제 XP가 바뀔 때 전체 퀘스트 예상 구간을 숨겼다가 다시 그리는 경로가 있었습니다. `KHQOL_ExperienceBar/Modules/ExperienceBar.lua`와 `Modules/QuestExperiencePreview.lua`에서 동일한 구간의 배치를 유지합니다. 반납으로 중복될 수 있는 예상값만 재조회 동안 보류합니다. | XP 변화 없는 전투 종료, 처치 XP와 예상 구간 유지, XP 이벤트가 먼저 온 반납, 예상 구간 OFF를 검사했습니다. | **인게임 미검증.** 영상에서 반짝인 실제 UI 요소와 깜빡임 해소 여부를 확인하지 못했습니다. |
| 버프 감사 알림 | `sourceUnit`이 없으면 시전자를 판정하지 못했고, 초기 조회가 막힌 뒤 첫 이벤트를 기준 등록에만 사용했습니다. `KHQOL_Convenience/Modules/BuffThanks.lua`에서 공개 GUID와 캐릭터 조회로 직업·전체 이름을 확인하고, 재개 시점에 새로 적용된 사실을 확인한 효과를 처리합니다. | 대상 지정, 공개 GUID만 있는 경우, 자기 버프·비공개 GUID·불완전한 이름, 그룹 전환, 기존 효과·중복과 재개 후 첫 효과를 검사했습니다. | **인게임 미검증.** 야생의 징표·신의 권능 인내의 실제 랭크와 ID, 이름 조회, 귓속말 도착은 확인하지 못했습니다. |
| 대상 색상 | 이름과 레벨의 색상 모드가 기본값과 사용자 지정만 지원했습니다. `KHQOL_UnitFrames/Modules/UnitFrameDecor.lua`, `UnitFrames.lua`, `UnitFrameRootPreview.lua`, `UI/UnitFrameDetails.lua`에 각각 직업 색상 선택과 갱신을 연결했습니다. | 플레이어 직업색, 우호·중립 및 적대 난이도, −2/−3, +4/+5, +9/+10, 회색 경계, 해골과 색상 독립 설정, 데이터 제한 시 기본색 복귀를 확인했습니다. | **인게임 미검증.** |

귀환석 번호, 파괴 호출 제한, 길드 취소 이벤트와 미니맵 추적 호출은 포에버 UI 정의를 참고했습니다. [기본 귀환석 및 난이도 팔레트](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_FrameXMLBase/Constants.lua#L165-L190) · [파괴 API](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/GameCursorDocumentation.lua#L51-L55) · [길드 초대 이벤트](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/GuildInfoDocumentation.lua#L453-L471) · [미니맵 추적 API](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/MinimapDocumentation.lua#L222-L230)

버프 리마인더는 게임의 보안 버튼이 시전을 요청하도록 구성했습니다. 버프 감사 알림은 두 공식 API의 공개 값만 사용합니다. 대상의 회색 경계는 기본 생물 난이도 범위를 따르며 요청한 노랑·초록 경계를 따로 적용합니다. [보안 주문 액션](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua#L371-L379) · [시전자 GUID](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitAuraDocumentation.lua#L158-L174) · [캐릭터 조회](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/PlayerScriptDocumentation.lua#L795-L814) · [기본 난이도 판정](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_FrameXMLUtil/Mainline/DifficultyUtil.lua#L26-L41)

## 퀘스트 보상 최고 판매가 표시

`KHQOL_Convenience/Modules/QuestRewardPrices.lua`에서 NPC 수락 전과 완료 보상창의 현재 퀘스트 ID, 선택 항목의 종류·아이템 ID·수량을 확인합니다. 개당 판매가에 보상 수량을 곱한 총액을 비교합니다. 확정 보상·화폐·경험치는 비교에서 제외합니다. 모든 가격이 확인되고 최고가가 0보다 클 때 최고가 아이템 아이콘 오른쪽 위에 게임 동전 텍스처를 표시합니다. 기본 버튼과 툴팁을 사용합니다. [포에버 퀘스트 보상 그리기](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/QuestInfo.lua#L698-L744) · [아이템 판매가 반환값](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua#L599-L612)

`KHQOL_Convenience.toc`, `Modules/GeneralConvenience.lua`, `UI/ConvenienceDetails.lua`, `UI/SearchIndex.lua`에 모듈 로드와 **공통 → 아이템** 설정을 연결했습니다. 기본값은 OFF이며 현재 프로필에 저장합니다.

| 검증 | 수락 전 미리보기 | 완료 보상 선택창 |
| --- | --- | --- |
| 최고가 한 개, 동점, 수량에 따른 순위 변경, 전부 0원 | 모의 통과 · 인게임 미검증 | 모의 통과 · 인게임 미검증 |
| 가격 지연, 퀘스트 전환, 이전 아이템의 늦은 이벤트, 창 닫기 | 모의 통과 · 인게임 미검증 | 모의 통과 · 인게임 미검증 |
| 옵션 OFF, 버튼 클릭·툴팁 경로, 프로필 저장 | 모의 통과 · 인게임 미검증 | 모의 통과 · 인게임 미검증 |
| 실제 `/reload` | 인게임 미검증 | 인게임 미검증 |

## 패키지 검사

정적 검사에서 Lua 235개, XML 8개, TOC 19개와 SavedVariables 선언 12개를 확인했습니다. 기본 설치와 선택 모듈을 포함한 다섯 구성에서 모의 검사 1,815건을 통과했습니다. 버전 갱신은 TOC 19개와 `KHQOL/Bootstrap.lua`, `KHQOL_Campfire/Campfire/Core.lua`, `KHQOL_Labs/Modules/ObjectHighlightDiagnostics.lua`, `KHQOL_Map/Core.lua`에 적용했습니다. README, CHANGELOG, 설치 안내도 갱신했습니다.

작업에서 접근할 수 있었던 첨부 폴더에는 요청 텍스트가 있었습니다. 요청에 언급된 스냅샷과 영상은 확인하지 못했습니다. 실제 게임 클라이언트의 클릭·전송 및 `/reload`는 인게임 미검증입니다.
