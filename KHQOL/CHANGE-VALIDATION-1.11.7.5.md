# KHQOL 1.11.7.5 변경·검증 보고서

## 기준과 제출물

- 기준은 KHQOL 1.11.7.4입니다. 접근 가능한 원본은 `KHQOL-1.11.7.4-Base.zip`과 `KHQOL_UnitFrames-1.11.7.4.zip` 두 개였습니다. ZIP 무결성과 내부 TOC 19개의 실제 버전 `1.11.7.4` 및 Interface `16001`을 확인한 뒤 작업 사본에서 합쳤습니다.
- 요청의 결과 버전이 자리표시자로 남아 있어 다음 패치인 **1.11.7.5**로 지정했습니다. `KHQOL-1.11.7.5-Full.zip`에는 기본 폴더 18개와 `KHQOL_UnitFrames`가 있습니다.
- 확인 기준은 **WoW Forever 1.60.1 / 70938 / Interface 16001**입니다. 로컬 설치 기록에서 `1.60.1.70938`을 확인하고 설치된 Baganator 854의 코드를 검토했습니다. 인게임 결과에는 사용자가 제공한 스크린샷으로 확인한 항목을 기록했습니다.

## 설정과 가방 휴지통

**편의기능 → 일반 편의 → 공통 → 아이템**에 **가방 휴지통**과 **아이템 보호**를 추가했습니다. 설정 검색어는 `휴지통`과 `아이템 보호`입니다. 휴지통은 초기 OFF, 위치 잠금은 ON이며 아이콘 크기는 32px입니다. **휴지통 위치 편집**을 선택하면 화면 직접 배치로 전환합니다. 가방에서 휴지통이 보이면 현재 표시 위치를 시작점으로 사용합니다. 화면 직접 배치의 위치·잠금·크기는 프로필에 저장됩니다. 위치를 잠근 상태에서는 드롭을 받고, 위치 편집 중에는 받지 않습니다.

| 가방 보기 | 구현 경로 | 인게임 |
| --- | --- | --- |
| 기본 통합 | 열려 있는 통합 가방 창 왼쪽에 표시 | 미검증 |
| 기본 개별 | 열려 있는 캐릭터 가방 중 첫 번째 창 왼쪽에 표시하고 다른 가방을 열거나 닫으면 재배치 | 미검증 |
| Baganator 단일 | 공개 `RegisterRegion` API로 가방 하단에 배치. `Baganator_SingleViewBackpackViewFrameblizzard`의 실제 캐릭터 가방을 대상으로 표시 | 미검증 |
| Baganator 카테고리 | 같은 공개 API로 현재 카테고리 보기의 가방 하단에 배치. 다른 캐릭터의 저장된 가방에서는 휴지통 버튼을 숨김 | 미검증 |
| 그 외 인벤토리 애드온 | **화면에 직접 배치**를 사용하고, 실제 캐릭터 가방의 커서 위치와 집은 수량을 확인할 수 있는 드롭을 처리 | 미검증 |

### 실제 드롭 즉시 파괴

**기본 가방과 Baganator 모두 미검증입니다.** `C_Cursor.GetCursorItem()`의 반환값에서 가방·슬롯을 확인할 수 있습니다. `DeleteCursorItem`, `C_Item.DeleteItem`, `C_Item.ConfirmDeleteItem`은 공개 인터페이스에서 호출 제한이 표시됩니다. 문서만으로는 70938에서 애드온의 마우스 드롭 입력으로 즉시 파괴가 가능한지 판정할 수 없습니다. [커서 위치 API](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/CursorDocumentation.lua) · [커서 파괴 API](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/GameCursorDocumentation.lua#L49-L54) · [아이템 파괴 API](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua#L77-L104)

이번 빌드는 **하급 · 일반 · 고급 · 희귀 · 영웅**을 한 줄에 표시하고 각 등급의 기본값을 미선택으로 둡니다. 실제 드롭이 검증되기 전까지 등급 선택은 비활성화되고 모든 등급의 파괴는 게임의 기본 확인창에서 사용자가 승인합니다. 확인창에는 집은 수량을 표시합니다. 퀘스트 아이템은 확인 문구를 요구하는 퀘스트용 확인창으로 보냅니다. 일반적인 희귀 이상 아이템에 기존 **아이템 파괴 자동 입력**이 켜져 있으면 확인 문구를 채우고 최종 승인은 사용자에게 맡깁니다. [기본 파괴 확인창](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_StaticPopup_Game/GameDialogDefs.lua#L1485-L1542) · [문구 입력 및 퀘스트용 확인창](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_StaticPopup_Game/Mainline/GameDialogDefs.lua#L539-L729)

커서와 가방 슬롯의 아이템 ID·링크를 대조하고, 전체 묶음은 집을 때 확인한 수량을, 분할 묶음은 분할 호출의 수량을 확인합니다. 출처 또는 수량을 확인할 수 없으면 아이템을 보존합니다. 확인창은 원본 슬롯의 GUID 없이 커서 아이템을 대상으로 엽니다. 같은 드롭에 확인창을 한 번만 열며, 보고 있던 아이템의 커서나 슬롯 상태가 바뀌거나 보호가 추가되면 창을 닫습니다. 전투 및 게임패드 입력에서는 휴지통 처리를 중단합니다. [가방 슬롯과 수량 API](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/ContainerDocumentation.lua)

## 아이템 보호와 판매·우편 범위

**게임 단축키 → KHQOL → 가방 아이템 보호 / 해제**에서 원하는 키를 지정합니다. 기본 키는 지정되어 있지 않습니다. 기본 가방 또는 Baganator의 현재 캐릭터 아이템 위에서 단축키를 누르면 같은 **아이템 ID 전체**에 보호를 적용하거나 해제합니다. 보호 아이템은 가방 툴팁에 표시됩니다. **보호 목록 관리**에서 등록 상태를 보고 해제할 수도 있습니다. 계정 공용 목록은 `KHQOLDB.globalData.protectedBagItems`에 저장됩니다. 슬롯을 이동하거나 스택을 분할·합치면 같은 ID의 모든 스택에 보호가 적용되며, 프로필을 바꾸어도 같은 목록을 사용합니다.

| 입력 경로 | 구현 및 확인 결과 | 인게임 |
| --- | --- | --- |
| KHQOL 휴지통 | 아이템 ID를 확인한 뒤 보호 상태면 확인창을 열지 않고 안내 | 미검증 |
| KHQOL 잡템 자동 판매 | 휴지통과 독립적으로 보호 아이템을 제외. 보호 아이템이 가방에 있거나 가방 정보가 불분명하면 기존 슬롯별 경로를 사용하고 각 요청 직전에 ID·링크·수량과 보호 상태를 다시 읽음 | 미검증 |
| 기본 상점에서 가방 우클릭 | 가방 툴팁에 보호 상태 표시. 판매 사전 차단 미지원 | 미검증 |
| 기본 상점에 아이템 드롭 | 판매 사전 차단 미지원 | 미검증 |
| 게임 기본 잡템 일괄 판매 버튼 | 보호 목록 적용 미지원 | 미검증 |
| 기본 우편에서 가방 우클릭 또는 첨부 슬롯에 드롭 | `MAIL_SEND_INFO_UPDATE` 뒤 첨부된 보호 아이템을 감지해 제거하라는 경고를 표시. 첨부 사전 차단 미지원 | 미검증 |
| 기본 우편 발송 | 발송 사전 차단 미지원 | 미검증 |
| Baganator 판매 버튼 | 설치본 `Transfers/VendorItems.lua`가 자체 판매 흐름을 호출. 보호 목록 적용 미지원 | 미검증 |
| Baganator 우편 전송 버튼 | 설치본 `Transfers/AddToMail.lua`가 우편에 첨부. 기본 발송 창에 첨부되면 같은 첨부 후 경고를 사용. 전송 버튼 사전 차단 미지원 | 미검증 |

설치된 Baganator 공개 API와 기본 판매·우편 흐름에서 KHQOL이 활용할 수 있는 사전 차단 경로는 확인되지 않았습니다. 판매나 우편 클릭 처리기를 교체하지 않았습니다. 기본 판매 일괄 API에는 슬롯 제외 인자가 없어 보호 후보가 있으면 KHQOL 내부에서 슬롯별로 처리합니다. [상점 API](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/MerchantFrameDocumentation.lua#L72-L84) · [기본 가방 UI](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/ContainerFrame.lua) · [기본 우편 UI](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_MailFrame/MailFrame.lua)

## 변경 파일

| 파일 | 변경 |
| --- | --- |
| `KHQOL_Convenience/Modules/BagTrash.lua` | 휴지통 버튼, 가방 배치, 수량 검증, 확인창 연결 |
| `KHQOL_Convenience/Modules/BagProtection.lua`, `Bindings.xml` | 계정 공용 목록, 가방 단축키, 툴팁, 우편 경고 |
| `KHQOL_Convenience/GeneralOptions.lua` | 일괄·슬롯 판매 경로 선택과 판매 직전 보호 재확인 |
| `KHQOL_Convenience/UI/BagItemSettings.lua`, `UI/ConvenienceDetails.lua`, `UI/SearchIndex.lua` | 아이템 설정, 목록 관리, 검색 |
| `KHQOL_Convenience/Modules/GeneralConvenience.lua`, `Adapters.lua`, `KHQOL_Convenience.toc` | 모듈 로딩 및 기존 위치 편집 연동 |
| `KHQOL_Convenience/Media/BagTrash.tga` | 휴지통 아이콘 |
| TOC 19개와 `KHQOL/Bootstrap.lua`, `KHQOL_Campfire/Campfire/Core.lua`, `KHQOL_Labs/Modules/ObjectHighlightDiagnostics.lua`, `KHQOL_Map/Core.lua` | 릴리스 버전 표기 |
| `KHQOL/README.md`, `INSTALL-GUIDE.md`, `CHANGELOG.md` | 사용법·설치·변경 이력 |

## 정적·모의 검사 결과

- Lua 5.1 구문 230개, XML 8개, TOC 19개를 검사했습니다. TOC 버전, Interface, 로딩 경로, 의존성 및 SavedVariables 12개 소유자에 대한 검사를 통과했습니다.
- 설치 구성 5개에서 기존 회귀 검사 **450건**을 통과했습니다. 편의기능을 설치한 구성 4개에서 가방 시나리오 **80건씩**을 실행해 **320건**을 통과했습니다.
- 가방 열기·닫기와 보기 전환, 네 가방 보기의 `OnReceiveDrag` 처리, 캐시 가방 구분, 직접 배치 좌표·잠금·크기, 설정 검색을 모의 검사했습니다.
- 다섯 등급의 미선택 및 선택 값에 기본 확인창이 열리는지, 파괴 확인 문구 자동 입력이 최종 승인과 분리되는지, 중복 드롭 처리, 퀘스트 확인창, 수량을 알 수 없는 드롭, 취소와 분할 후 집은 수량만 처리하는 흐름을 모의 검사했습니다.
- 단축키와 툴팁, 슬롯 이동·분할·합치기, 프로필 재적용, 보호 도중 열린 확인창 닫기, 휴지통 OFF 상태의 보호, 판매 직전 보호 재확인, 보호 후보가 없을 때의 일괄 판매와 후속 자동 수리, 첨부 후 우편 경고를 모의 검사했습니다.
- ZIP의 파일 목록, CRC, 작업 사본과의 바이트 일치, 원본 ZIP의 SHA-256을 확인했습니다.

## 실제 인게임 결과

| 항목 | 결과 |
| --- | --- |
| 휴지통에 마우스로 드롭한 뒤 기본 파괴 확인창 표시 | **확인**. 사용자 스크린샷에 `[조각난 곰 이빨] ×1`과 **예 / 아니요**가 표시됨. 사용한 가방 보기는 미확인 |
| 기본 가방과 Baganator의 실제 마우스 드롭에서 추가 클릭 없이 즉시 파괴 | 미검증 |
| `DeleteCursorItem` 및 `C_Item` 파괴 API의 실제 드롭 호출 제한과 `ADDON_ACTION_BLOCKED` 발생 여부 | 미검증 |
| 기본 확인창 승인·취소, 전체·분할 수량, 퀘스트·추가 확인, 다섯 등급 | 미검증 |
| 가방 열기·닫기, 보기 전환, 위치 이동·잠금, 크기 및 배치 시각 확인 | 미검증 |
| 보호 목록, 슬롯 정렬·스택 분할과 합치기, `/reload` 후 옵션 및 목록 유지 | 미검증 |
| KHQOL 자동 판매·자동 수리, 수동 판매와 우편, Baganator 판매·전송 및 실게임 Lua 오류 | 미검증 |
