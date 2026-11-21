# KHQOL 1.11.8.7 변경·검증 보고서

- 기준 `KHQOL-1.11.8.6-Full.zip`. 원본 SHA-256 `7e948a6c444b75044e9dd8a23520951179f5635bce728f50a80522f435eacd15`.
- 대상 WoW Forever 1.60.1 / 70938 / Interface 16001. 결과 `KHQOL-1.11.8.7-Full.zip`.
- 첨부의 32비트 투명 TGA 4개를 사용했습니다. 클라이언트 호환을 위해 원본 68×70 화소를 유지한 채 128×128에 넣고, 게임에서 원본 영역만 표시합니다.

## 화면과 동작

| 위치 | 변경 |
| --- | --- |
| 편의 기능 | **일반 편의 → 오브젝트 강조 → 포에버 노트** 순으로 표시합니다. 오브젝트 강조는 실험실 잠금 없이 켤 수 있고 프로필 설정을 사용합니다. 기존 그래픽 복원 보호는 전체 초기화에 계속 적용됩니다. 설치 폴더의 기존 모듈 이름과 저장 데이터 위치를 사용합니다. |
| 일반 편의 → 공통 | 기본 대화창 편의와 상인 판매목록 확장을 맨 위에 배치했습니다. 가방 휴지통의 독립 아코디언을 추가했고 아이템 보호는 아이템에 둡니다. 채집 추적 저장·복원과 관련 옵션을 제거했습니다. |
| 공통 → 버프 알림 | 이름을 바꾸고 **버프 감사 메시지**를 추가했습니다. 최대 255바이트이며 빈 값은 `감사합니다.`를 사용합니다. 귓속말과 입력창 초안에 같은 값을 사용합니다. |
| 미니맵 버튼 보관함 | 우클릭은 새 세션에서 `일반`, 같은 세션에서는 마지막 설정 경로를 엽니다. 접기·펼치기는 기존 좌클릭을 사용합니다. |
| 인터페이스 → 시계·정보 표시 | 제목은 `서버 합계 소지금 : {총 금액}`이며 현재 캐릭터의 실시간 잔액과 같은 서버·진영 부캐의 마지막 기록을 합산합니다. 본문에는 기존처럼 부캐만 표시하고 금·은·동을 열별로 정렬합니다. 마우스오버는 계속 동작하고, 지정한 조합으로 같은 툴팁을 고정·해제합니다. 기본 조합은 보조키 없음 + 우클릭입니다. Shift/Ctrl/Alt, 좌·우·마우스 4번 및 휠 위·아래를 지원합니다. 다른 기본 UI가 공용 툴팁을 사용하면 고정 표시를 대체할 수 있습니다. |

## 파티 버튼

| 상태 | 아이콘 | 좌클릭 |
| --- | --- | --- |
| 솔로 | `party_tab_add_member` | 우호 플레이어 초대 |
| 일반 파티원 | `party_tab_members` | `PARTY` 인사 |
| 일반 파티장·공격대장 | `party_tab_marker` | 빈자리가 있으면 대상 초대, 정원이 차면 현재 채널에 인사 |
| 공격대원 | `party_tab_group` | `RAID` 인사 |
| 인스턴스 그룹 | 역할에 맞는 파티·공격대·리더 아이콘 | `INSTANCE_CHAT` 인사 |

- 크기는 아이콘 높이 기준 24~96px, 투명도는 0~90%입니다. Alt+왼쪽 드래그와 기존 위치 편집을 모두 사용할 수 있습니다.
- 우클릭으로 기본 플레이어 메뉴를 엽니다. Forever의 플레이어 프레임이 사용하는 `UnitPopup_OpenMenu("SELF", contextData)` 경로를 사용합니다. 실제 메뉴 표시 및 전투 중 항목 사용은 인게임 미검증입니다. [Forever 플레이어 메뉴 코드](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UnitFrame/Mainline/PlayerFrame.lua#L74-L91)
- Shift+좌클릭으로 작별 메시지를 먼저 요청하고 **1초 뒤 같은 그룹이면 탈퇴를 한 번 요청**합니다. 메시지가 비어 있으면 즉시 탈퇴를 요청합니다. 채팅이 제한되거나 호출이 실패하면 그룹에 남습니다. 지연 중 그룹 변경 이벤트나 프로필 전환을 감지하면 이전 탈퇴 요청을 취소합니다. 채팅 API에는 상대 수신 결과가 없으므로 지연은 실제 전달을 보장하지 않습니다. [Forever 채팅 API](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/ChatInfoDocumentation.lua#L533-L544) · [Forever 탈퇴 API](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/PartyInfoDocumentation.lua#L454-L461)
- 같은 메시지를 이미 보낸 그룹은 마지막으로 확인한 수신자 명단과 비교합니다. 새 파티원이 생기면 좌클릭으로 다시 보낼 수 있습니다. 현재 명단을 읽을 수 없을 때는 같은 메시지의 2초 내 반복을 막습니다. 입장 자동 인사는 새 그룹을 확인하고 1.5초 뒤 한 번 요청합니다. 프로필에 이미 저장된 선택은 유지하며 새 설치와 기본 프로필의 자동 인사는 OFF입니다.

## 변경 파일

- `KHQOL_Convenience`의 `Modules/PartyButton.lua`, `ChatAutomation.lua`, `GeneralConvenience.lua`, `BuffThanks.lua`, `BagTrash.lua`, `Adapters.lua`, `UI/ConvenienceDetails.lua`, `BagItemSettings.lua`, `SearchIndex.lua` 및 아이콘 4개.
- `KHQOL`의 `Profiles.lua`, `UI/SettingsRegistry.lua`, `UI/SettingsGroups.lua`, `PositionEditor.lua`, `Modules/GraphicsJournal.lua`, `Modules/LabLock.lua`, `MoneyRecords.lua`, `UI/HUDText.lua`, `Media/MoneyColumnSpacer.tga`.
- `KHQOL_Labs/UI/LabSettings.lua`, `KHQOL_Map/Buttons.lua`, `KHQOL_Clock/Clock/Core.lua`, `Modules.lua`, `Settings.lua`. 전체 TOC와 버전 참조 및 설치 문서 갱신.

## 검증

Lua 236개, XML 8개, TOC 19개의 정적 검사를 통과했습니다. 기존 설치, 신규 설치, 유닛프레임 포함 및 일부 선택 모듈을 제외한 5가지 구성에서 회귀 검사를 통과했습니다. 파티가 있는 구성에서 각각 파티 전용 56건을 실행했습니다.

| 항목 | 정적·모의 결과 | Forever 인게임 |
| --- | --- | --- |
| 오브젝트 강조와 공통 화면 | 탭 순서, 실험실 잠금 분리, 설정 탐색과 채집 추적 미개입 | 미검증 |
| 파티 버튼 | 역할별 자산, 초대·채널, 신규 파티원과 동일 인원 교체, 자동 인사 지연과 취소, 크기·투명도·위치와 프로필 전환 | 미검증 |
| Shift+좌클릭 | 메시지를 먼저 호출, 1초 전 탈퇴 미발생, 한 번만 탈퇴 요청, 다른 그룹으로 전환하면 취소, 채팅 실패 시 그룹 유지 | 1초 뒤의 실제 탈퇴 및 전투 중 동작 미검증 |
| 우클릭 | `SELF` 메뉴 요청과 `player` 전달 확인 | 기본 메뉴 표시 및 전투 중 사용 미검증 |
| 미니맵·소지금 | 첫 설정과 마지막 경로 복원, 서버·진영 합계, 열 맞춤용 폭 계산, 클릭·마우스 4번·휠 방향과 보조키 분기 | 실제 툴팁 정렬, 마우스 입력, 로그오프·재접속 미검증 |
| 버프 감사 | 프로필 저장, 문구 검증 및 기본값, 기존 알림과 귓속말 경로 | 실제 귓속말 수신 미검증 |
