# KHQOL 1.11.8.9 변경·검증 보고서

- 기준 `KHQOL-1.11.8.8-Full.zip` 내부 TOC 및 로드 순서 확인 후 별도 작업본에 압축을 풀었습니다. SHA-256 `0bde41da183752a44dc5201706eb50bf79b836dc5737a80f575ece6df3e19092`를 대조했습니다.
- 대상 WoW Forever 1.60.1.70938 / Interface 16001. 로컬 설치된 `Wow.exe`의 파일 버전은 1.60.1.70938입니다. 게임을 실행한 상태의 검증은 수행하지 않았습니다. 아래 인게임 항목은 모두 미검증입니다.
- 결과 `KHQOL-1.11.8.9-Full.zip`. 첨부에서 확인된 세 장은 레벨·소지금·시계 화면입니다. 주사위 카드에는 요청문 표의 왼쪽 아이콘, 오른쪽 위 구분·아이템명, 오른쪽 아래 세 버튼 배치를 적용했습니다.

## 구현

### 전리품 주사위 굴림

- `GroupLootFrame1~4`의 아이콘과 남은 시간 바를 배치하고, 기존 `NeedButton`·`GreedButton`·`PassButton` 위에 KHQOL 스타일을 적용했습니다. 기존 ID와 스크립트, 비활성 사유, 버튼의 부모 관계, 아이템 툴팁, 자동 만료와 귀속 팝업은 게임 쪽에서 처리합니다. 마우스·키보드 기본 창을 대상으로 하며 게임패드 UI, 형상변환·추가 선택, 확인할 수 없는 기본 프레임은 기본 외형을 사용합니다. [Forever 버튼과 프레임 정의](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/GroupLootFrame.xml#L478-L545)
- `START_LOOT_ROLL` 이후 실제 카드의 `rollID`로 `GetLootRollItemInfo`를 읽습니다. 분류는 `C_Item.GetItemInfoInstant` 또는 `C_Item.GetItemInfo`의 게임 현지화 유형입니다. 조회 결과가 늦으면 우선 `—`를 표시하고 `ITEM_DATA_LOAD_RESULT`·`GET_ITEM_INFO_RECEIVED`에서 현재 카드의 `rollID`와 아이템을 대조한 뒤 해당 구분을 갱신합니다. 기본 버튼에는 영향을 주지 않습니다. [Forever 아이템 유형](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua#L621-L639) · [아이템 정보 이벤트](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua#L1716-L1767)
- 실제 결과는 게임이 `MAIN_SPEC_NEED_ROLL(rollID, roll, isWinning)`에서 동일한 카드의 `GroupLootFrame_StartNeedAnimation`으로 전달합니다. 이 단일 기본 연출을 아이콘에 붙이고 배율과 숫자 글꼴을 조정했습니다. 카드별 숫자와 타이머는 게임이 관리하며 카드가 숨겨질 때 기본 게임이 연출과 종료 콜백을 정리합니다. KHQOL은 카드에 덧입힌 외형을 원복합니다. [Forever 실제 결과와 카드 종료](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/GroupLootFrame.lua#L345-L433) · [전리품 이벤트](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/LootDocumentation.lua#L266-L275)

### 공통 알림과 도안 크기

- 주사위는 **GroupLootContainer 하단**, 알림은 **AlertFrame 상단**을 별도의 좌표로 저장합니다. 기본 주사위 대기열 및 카드 순서를 유지하고 큰 카드에는 기본 컨테이너의 슬롯 간격만 늘립니다. 공통 알림 위치는 게임이 배너 순서를 계산하는 기준점입니다.
- 저장한 위치를 사용할 때 `AlertFrame`의 외부 앵커 목록에서 `GroupLootContainer`를 가리키는 항목을 확인합니다. 해당 항목이 이전 알림 기준점을 계속 사용하도록 처리해, 주사위가 떠도 뒤따르는 배너가 주사위 창을 따라가지 않게 합니다. 공식 구조가 다르거나 기본 좌표를 읽을 수 없으면 게임의 기존 배치를 사용합니다. 원복은 `NativePosition`의 마지막 적용값과 최신 게임 배치를 비교합니다. [Forever 외부 앵커 처리](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_FrameXML/Mainline/AlertFrames.lua#L21-L40) · [알림 순서](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_FrameXML/Mainline/AlertFrames.lua#L384-L393) · [주사위 슬롯](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/GroupLootFrame.lua#L108-L129)
- `NewRecipeLearnedAlertSystem`의 활성 풀에 있는 도안 프레임만 배율을 적용합니다. `NativeAppearance`로 기본 배율을 기록하고 반환·재사용·기능 해제 시 원복합니다. 기본 알림의 표시 옵션, 클릭, 대기열과 다른 배너의 배율은 게임이 관리합니다. 전투 중 앵커와 배율 변경은 `PLAYER_REGEN_ENABLED` 이후 최신 설정으로 적용합니다. [도안 알림 시스템과 클릭](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_FrameXML/Mainline/AlertFrameSystems.lua#L935-L947)

### 저장과 단축키

- 계정 공용 `KHQOLDB.nativeAlerts.roll`에 주사위 사용·창 배율·글자 크기·좌표, `KHQOLDB.nativeAlerts.alerts`에 알림 사용·도안 배율·좌표를 저장합니다. 두 섹션은 기본 OFF, 배율은 100%, 좌표는 게임 기본값입니다. 기능별 위치 초기화와 설정 전체 초기화를 제공합니다. 프로필 내보내기 대상에는 포함되지 않습니다.
- 시계 단축키는 `ForeverClockDB.shortcuts`에 저장하고 기존 전체 프로필 전환에 연동합니다. 원래 조합인 Alt+좌클릭 달력, 우클릭 포에버 노트, 좌클릭 타이머·알람·스톱워치, Alt+우클릭 UI 새로고침을 초기값으로 제공합니다. 없음·Shift·Ctrl·Alt와 좌·우·마우스 4번·휠 위·휠 아래를 지원합니다. 중복 조합을 선택하면 기존 조합과 바꾸며 `사용 안 함`도 선택할 수 있습니다. 소지금의 단축키 동작과 설정을 제거하고 마우스오버 툴팁을 유지합니다.
- 경험치 레벨 구분의 저장값 `lv`·`ko`는 계속 쓰며 드롭다운에 표시하는 이름을 변경했습니다.

## 수정 파일

- `KHQOL/BasicUI/GroupLoot.lua`, `NativeAlerts.lua` 추가. `NativeAppearance.lua`, `NativePosition.lua`, `Settings.lua`, `Adapters.lua`, `SearchIndex.lua`, `KHQOL.toc` 변경.
- `KHQOL_Clock/Clock/Clock.lua`, `Core.lua`, `Modules.lua`, `Settings.lua`, `Adapters.lua`, `UI/SearchIndex.lua`와 `KHQOL_ExperienceBar/UI/ExperienceSettings.lua` 변경.
- 전체 TOC 19개와 버전 참조, README·CHANGELOG·설치 안내·검증 보고서 갱신.

## 검증과 인게임 재현 절차

Lua 238개, XML 8개, TOC 19개 정적 검사와 5가지 모의 설치 구성의 회귀 검사를 통과했습니다. 주사위·알림은 구성별 전용 검사 29건을 통과했습니다. 시계의 기본 조합, 키 재지정, 중복 교환, 프로필 저장과 소지금 마우스오버도 모의 검사에서 확인했습니다.

| 항목 | 정적·모의 결과 | 70938 인게임 재현 절차 |
| --- | --- | --- |
| 입찰·차비·포기와 귀속 | 기본 버튼 ID 1·2·0, 기본 아이템 툴팁, 추가 선택 카드의 기본 외형 확인. | **미검증**. 그룹 전리품에서 입찰 가능·불가 장비로 차비와 포기도 시험하고, 획득 시 귀속 장비의 기본 팝업에서 수락·취소 및 시간 만료를 확인합니다. |
| 결과 숫자와 대기열 | 같은 아이템 두 카드에 다른 `rollID` 결과, 카드 재사용 후 늦은 이벤트, 확대 시 컨테이너 슬롯 간격 확인. | **미검증**. 동일한 아이템이 동시에 두 개 이상 나오게 하고 두 카드에 입찰해 게임 결과와 숫자를 대조합니다. 대기 전리품이 있는 상태에서 취소·만료·카드 재사용도 확인합니다. |
| 카드 외형 | 지연된 분류와 이름 영역, 기본 툴팁 스크립트, 크기·글자·위치 전달 확인. | **미검증**. 긴 이름과 서로 다른 품질의 천·가죽·무기를 띄워 70/100/150% 창 크기, 11/22px 글자, 네이티브 툴팁을 확인합니다. |
| 도안 알림과 동시 표시 | 활성 도안 프레임만 배율 변경, 풀 원복·재사용, 주사위와 별도 좌표에서 다른 배너가 도안 뒤를 따르는 것을 확인. | **미검증**. 위치를 서로 멀리 저장한 뒤 주사위가 떠 있는 동안 도안 두 개 이상을 연달아 익히고 다른 기본 배너도 발생시킵니다. 배너 클릭으로 전문기술 열기와 게임 도안 알림 OFF를 확인합니다. |
| 전투·저장·원복 | 전투 후 최신 설정 적용, 인식할 수 없는 앵커의 기본 배치, 위치 편집 예시·저장·취소와 개별 초기화 확인. | **미검증**. 전투 중 만료와 기본 버튼·팝업이 동작하는지 살피고, 두 설정을 전투 중 변경한 뒤 전투 종료 전후를 비교합니다. `/reload` 뒤 좌표·배율, 기능 OFF와 두 초기화 버튼의 원복을 확인합니다. |
| 시계 | 기본 4조합과 마우스 4번·휠·보조키 분기 모의 확인. | **미검증**. 시계 숫자와 소지금에 각각 마우스를 올리고 각 단축키의 대상, 위치 드래그와의 분리, `/reload` 전후 설정을 확인합니다. |
