# KHQOL 1.11.8.6 파티 버튼 변경·검증 보고서

- 기준 패키지 `KHQOL-1.11.8.5-Full.zip`. 기준 ZIP을 작업 사본에 풀어 수정하고 원본 SHA-256 `a4a624249cdf37ce2642e241a18f98aa0308a723def510548b963e6419485d27`을 패키징 시 대조했습니다.
- 대상 WoW Forever `1.60.1 / 70938 / Interface 16001`. 설치된 Forever 실행 파일의 버전과 기존 TOC의 인터페이스 번호를 확인했습니다. 공개 Forever UI 소스는 API 조사에 사용했습니다.
- 결과 패키지 `KHQOL-1.11.8.6-Full.zip`. 전투 중 초대·인사·작별·탈퇴는 **LIMITED GO**입니다. 실제 게임 플레이와 상대 화면 검증이 남아 있습니다.

## 설정과 프로필

- **편의 기능 → 일반 편의 → 말머리**에 기존 채널별 말머리만 배치했습니다. **파티**는 파티 버튼, Alt+좌클릭 초대, 기존 파티 자동 인사로 구성됩니다. **공통**에서 기본 대화창 편의와 버프 감사 알림을 설정합니다. 설정 검색과 초기화 범위에도 새 위치를 반영했습니다.
- 새 설치와 기본값으로 새로 만든 프로필은 파티 버튼이 켜집니다. 이미 저장된 프로필에 버튼 설정이 없으면 꺼진 상태로 추가합니다. 기존 프로필 복제는 원본 설정을 따릅니다. 새 SavedVariables 키는 `settings.modules.generalConvenience.partyButton` 아래에 추가했고 기존 SavedVariables 선언과 스키마를 유지했습니다.
- 수동 인사와 작별 문구의 기본값은 각각 `안녕하세요!`와 `수고하셨습니다!`입니다. 기존 캐릭터별 자동 인사가 있으면 수동 인사 문구를 처음 저장하기 전까지 해당 문구를 표시하고 사용합니다. 기존 자동 인사 설정과 캐릭터별 문구는 해당 위치에 계속 저장됩니다. 말머리 적용 후 내용이 같은 자동·수동 인사 요청은 같은 그룹·채널에서 중복을 억제합니다. 자동 인사의 기존 일반 파티·공격대 조건은 유지합니다.
- 각 메시지는 UTF-8 기준 최대 255바이트입니다. 빈 인사말은 건너뛰며 작별 문구가 비어 있으면 우클릭으로 탈퇴만 요청합니다. 위치 편집 중 HUD 버튼의 초대·채팅·탈퇴 입력은 중지합니다. 초기 위치는 화면 중앙 기준 오른쪽 220, 아래 160입니다.

## 버튼 모드와 채널

| 현재 상태 | 스냅샷 | 좌클릭 | 우클릭 |
| --- | --- | --- | --- |
| 솔로 | 1 · 초대 | 선택한 우호 플레이어 초대 | 동작 없음 |
| 2~4인 일반 파티장 | 1 · 초대 | 초대 권한 확인 후 대상 초대 | 동작 없음 |
| 일반 파티원 또는 5인 일반 파티장 | 2 · 파티 | `PARTY` 인사 | `PARTY` 작별 인사 후 일반 그룹 탈퇴 요청 |
| 공격대 | 2 · 파티 | `RAID` 인사 | `RAID` 작별 인사 후 일반 그룹 탈퇴 요청 |
| 인스턴스 그룹 | 2 · 파티 | `INSTANCE_CHAT` 인사 | `INSTANCE_CHAT` 작별 인사 후 인스턴스 그룹 탈퇴 요청 |

인스턴스 그룹과 일반 그룹이 동시에 있으면 인스턴스 그룹을 우선합니다. 상태 이벤트에서 아이콘을 갱신하고 클릭 시 최신 상태를 다시 읽습니다. 모드나 채널이 바뀐 직후 이전 아이콘에 대한 클릭은 실행하지 않습니다. 역할 판단에 필요한 데이터가 제한되면 읽을 수 있을 때까지 버튼을 숨깁니다.

## Forever API와 전투 동작

- **상태**는 `IsInGroup(LE_PARTY_CATEGORY_HOME/INSTANCE)`, `IsInRaid`, `GetNumGroupMembers`, `UnitIsGroupLeader`로 읽습니다. 기본 채팅 UI도 그룹 종류별 같은 조건으로 채널을 판단합니다. 전투 중 파티장 변경은 관련 이벤트에서 다시 읽습니다. [Forever 기본 채팅 코드](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_ChatFrameBase/Shared/ChatFrameUtil.lua#L433-L469) · [파티장 API](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua#L1925-L1938)
- **초대**는 대상의 전체 이름을 확인한 뒤 `C_PartyInfo.InviteUnit`을 호출합니다. 현재 그룹의 초대 권한은 `C_PartyInfo.CanInvite`, 대상의 그룹 소속은 `UnitInAnyGroup`으로 확인합니다. 게임에서 요구하는 확인은 기본 UI가 처리합니다. 들어오는 초대의 자동 거절 설정은 기존 경로에 연결되어 있습니다. [초대 API](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/PartyInfoDocumentation.lua#L333-L341) · [대상의 그룹 확인](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua#L1496-L1508)
- **인사와 작별 인사**는 `C_ChatInfo.InChatMessagingLockdown`으로 확인하고 `C_ChatInfo.SendChatMessage`에 현재 그룹 채널을 전달합니다. 제한 중에는 작성 중인 내용이 없을 때 `ChatFrameUtil.OpenChat`으로 그룹 채팅 초안을 열 수 있습니다. 사용자가 Enter를 눌러 보내며, 그 경로는 탈퇴를 자동 요청하지 않습니다. [채팅 제한](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/ChatInfoDocumentation.lua#L278-L285) · [전송 API](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/ChatInfoDocumentation.lua#L533-L544)
- **탈퇴**는 작별 인사를 먼저 호출하고 그룹이 같으면 같은 클릭에서 `C_PartyInfo.LeaveParty(category)`를 호출합니다. 채팅 제한, Lua 오류나 명시적 실패가 확인되면 그룹에 남습니다. 채팅 API에 전달 결과가 없어 API 호출이 끝난 뒤 채팅이 서버에서 거부되는 경우에도 탈퇴 요청이 들어갈 수 있습니다. 게임이 탈퇴 확인을 요구하면 사용자가 기본 창에서 승인합니다. 요청을 자동 재시도하지 않습니다. [탈퇴 API](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/PartyInfoDocumentation.lua#L454-L461)
- 일반 버튼의 실제 클릭을 진입점으로 사용합니다. 채팅 API의 매크로 제한도 확인했습니다. 버튼 속성이나 보안 실행 경로를 전투 중에 변경하는 코드는 사용하지 않습니다.

## 수정 파일과 주요 함수

| 파일 | 변경 |
| --- | --- |
| `KHQOL_Convenience/Modules/PartyButton.lua` | `ReadMode`, `InviteTarget`, `Click`, `Refresh`, `Configure`, `AddPositionTarget`, 위치·메시지 저장과 초기화 |
| `KHQOL_Convenience/Modules/ChatEnhancement.lua` | `SubmitPartyInvite`를 HUD와 기존 `TryInvite`에서 공유 |
| `KHQOL_Convenience/Modules/ChatAutomation.lua` | `SendGroupMessage`, `OpenGroupDraft`, `ObserveGroup`, `OnEvent`에서 그룹 채널 전송·중복 억제 |
| `KHQOL_Convenience/Modules/GeneralConvenience.lua`, `Modules/BuffThanks.lua`, `Adapters.lua` | 버튼 적용·위치 편집 등록, 탭과 초기화 연결, 버프 감사 위치 편집의 설정 경로 갱신 |
| `KHQOL_Convenience/UI/ConvenienceDetails.lua`, `UI/SearchIndex.lua` | 말머리와 파티 탭, 옵션·위치 버튼, 검색 등록 |
| `KHQOL/Profiles.lua`, `KHQOL/UI/SettingsGroups.lua`, `KHQOL/UI/SettingsRegistry.lua` | 신규 기본값, 하위 탭 순서, 대화창 설정 바로가기 갱신 |
| `KHQOL_Convenience/Media/PartyInvite.tga`, `PartyGroup.tga` | 첨부 이미지의 버튼 영역을 각각 사용한 초대·파티 아이콘 |
| `KHQOL_Convenience/KHQOL_Convenience.toc` 및 전체 TOC 19개 | 로드 순서와 버전 `1.11.8.6` |
| `KHQOL/Bootstrap.lua`, `KHQOL_Map/Core.lua`, `KHQOL_Campfire/Campfire/Core.lua`, `KHQOL_Labs/Modules/ObjectHighlightDiagnostics.lua` | 버전 문자열 갱신 |
| `KHQOL/README.md`, `CHANGELOG.md`, `INSTALL-GUIDE.md`, `CHANGE-VALIDATION-1.11.8.6.md` | 설치·변경·검증 문서 |

## 검증 결과

Lua 236개, XML 8개, TOC 19개와 SavedVariables 소유 모듈 12개를 정적 검사했습니다. 기본 구성, 유닛프레임 포함, 시계 제외, 편의 기능 제외, 신규 설치의 다섯 구성에서 모의 회귀 검사를 통과했습니다. 편의 기능이 있는 네 구성에서 각각 파티 전용 검사 45건을 통과했습니다. 실제 클라이언트는 실행 중이지 않았고 다른 플레이어가 받는 초대·채팅과 그룹 상태를 관찰할 세션을 확보하지 못했습니다.

| 요구 시나리오 | 모의 검사 | 빌드 70938 인게임 | 판정 |
| --- | --- | --- | --- |
| 전투 중 솔로 초대 | 전체 이름으로 초대 API 호출 | 미검증 | **LIMITED GO** |
| 전투 중 2~4인 파티장 초대 | 권한 확인 후 초대 API 호출 | 미검증 | **LIMITED GO** |
| 전투 중 일반 파티원의 인사 | `PARTY`에 한 번 전송 요청 | 미검증 | **LIMITED GO** |
| 전투 중 작별 인사 | 탈퇴 호출에 앞서 올바른 채널에 한 번 요청 | 미검증 | **LIMITED GO** |
| 전투 중 탈퇴 | 올바른 그룹 분류로 요청, 확인 가능한 채팅 실패 시 그룹 유지 | 미검증 | **LIMITED GO** |
| 전투 중 파티장 변경 | 변경 양방향 아이콘 갱신, 현재 역할에 맞는 클릭 요청 | 미검증 | **LIMITED GO** |
| 전투 중 4인→5인 변경 | 파티 아이콘으로 갱신, 전환 직전의 초대 클릭 폐기 | 미검증 | **LIMITED GO** |
| 전투 중 파티 해체 | 솔로 초대 아이콘과 초대 클릭 복원 | 미검증 | **LIMITED GO** |
| 비전투 상태와 예외 | 솔로·일반 파티·공격대·인스턴스, 무대상·적대·NPC·이미 그룹 상태, API 오류, 채팅 제한 검증 | 미검증 | **LIMITED GO** |
| 설정·저장·회귀 | 위치 편집 및 초기화, 표시 OFF, 프로필 전환과 저장 직렬화, 신규·기존 설치, 자동 인사 중복, 기존 설정·다른 모듈 회귀 검사 | 화면 클릭·실제 `/reload` 미검증 | **LIMITED GO** |
