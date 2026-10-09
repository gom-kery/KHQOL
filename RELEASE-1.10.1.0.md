## 1.10.1.0 수정본 — SetUserPlaced 오류 해결

사용자 로그에서 WorldMapFrame의 원래 movable=false 상태를 확인했습니다. 이전 Restore 구현은 SetMovable(false)를 먼저 호출한 뒤 SetUserPlaced(false)를 호출해, 이동 또는 크기 변경이 불가능한 프레임에 SetUserPlaced를 호출하는 오류가 발생했습니다. 오류가 복원을 중단하면서 applying=true 상태가 남을 수도 있었습니다.

Restore에서 임시 SetMovable(true) → SetUserPlaced(원본 값) → SetMovable(원본 값) 순으로 변경했습니다. 전투 중 복원 보류 정책은 유지합니다. 저장 위치만 적용된 Reload 직후 프레임에서도 안전한 호출 순서를 사용합니다. 버전 번호는 요청한 1.10.1.0을 유지하고 파일명으로 수정본을 구분합니다.

검증 도구에 SetUserPlaced의 movable/resizable 전제 조건을 추가하여 기존 코드의 동일 오류를 재현했습니다. 수정 후 Lua 5.1 문법 76개, 동작 검증 197개 assertion, TOC 파일 72개 경로 PASS. 원래 movable=true/false 프레임, 초기화, OFF, 전투 종료 후 복원, 저장 위치만 적용된 새 세션, 복원 후 상태 플래그 정리를 확인했습니다. 실제 게임 재검증은 미실시입니다.

이번 수정은 Modules/FrameMover.lua와 변경 기록/검증 보고서에 한정됩니다. 이전 배포 ZIP의 나머지 기능 파일은 그대로입니다.

# KHQOL 1.10.1.0 작업 결과

기준: KHQOL 1.10.0.0. 결과: KHQOL 1.10.1.0. 날짜: 2026-10-09.

## 설치

배포 ZIP의 `KHQOL` 폴더를 기존 `Interface/AddOns/KHQOL`에 덮어쓰고 `/reload`합니다. SavedVariables 삭제는 필요 없습니다. 이번 작업에서는 설치 폴더를 직접 수정하지 않았습니다.

## 추가 기능

- `KHQOL > 편의 기능 > 일반 > Blizzard 기본 프레임 이동`
- 기본 OFF. 기본 보조키 Shift. Shift/Ctrl/Alt 중 선택.
- 창 상단 제목 표시줄의 빈 영역을 보조키와 함께 드래그합니다. 내부 지도·아이템·주문·매크로 버튼의 기존 드래그 스크립트는 바꾸지 않습니다.
- 이동 완료 시 자동 저장. 초기화는 기능 ON 유지. OFF는 즉시 위치 데이터를 삭제하며, 원래 위치 및 이동 관련 프레임 플래그를 복원합니다.
- `KHQOL > 실험실 > 프레임 검사기`
- 기본 OFF. 페이지를 닫거나 이동하면 OFF. 이름·DebugName·Parent·Strata·Level·Size·MouseEnabled·Movable·모든 앵커(최대 16개)·부모 경로(최대 16단계)·사용 API·클라이언트 버전 표시.
- KHQOL 설정창 위로 마우스를 옮기면 마지막 외부 프레임 정보를 유지합니다. 복사 버튼을 누른 뒤 입력창에서 Ctrl+C로 복사합니다.

## 확인된 프레임 및 소스

설치 경로 `G:/World of Warcraft/_classic_beta_`와 제품 `wow_classic_beta`, 설치 메타데이터 버전 `1.60.1.70291`을 확인했습니다. Blizzard UI 파일은 설치 폴더에 개별 Lua/XML로 제공되지 않아, 기존 KHQOL 변경 기록에서 참조한 공개 Blizzard UI의 Camelot 소스를 직접 내려받아 확인했습니다.

**아래 이름은 Camelot XML/Lua에서 확인한 값입니다. 실행 중인 설치 클라이언트에서 생성된 객체를 직접 관측한 결과는 아닙니다.** 설치 클라이언트의 실제 객체·API 확인은 배포된 검사기로 가능합니다.

| 대상 | 전체 창 최상위 Frame | 실제 하위 패널 | Blizzard AddOn / 생성 시점 |
|---|---|---|---|
| 지도 | `WorldMapFrame` | `ScrollContainer` 등 | `Blizzard_WorldMap` / 기본 UI 로드 시 |
| 캐릭터창 | `CharacterFrame` | `LeftPaneHost`, `RightPaneHost` 등 | `Blizzard_UIPanels_Game` / 기본 UI 로드 시 |
| 특성 | `PlayerSpellsFrame` | `PlayerSpellsFrame.TalentsFrame` | `Blizzard_PlayerSpells` / LoadOnDemand, 관련 창 첫 열기 시 |
| 마법책 | `PlayerSpellsFrame` | `PlayerSpellsFrame.SpellBookFrame` | `Blizzard_PlayerSpells` / LoadOnDemand, 관련 창 첫 열기 시 |
| 매크로창 | `MacroFrame` | 매크로 목록·편집 영역 | `Blizzard_MacroUI` / LoadOnDemand, 관련 창 첫 열기 시 |

다섯 논리 대상, 네 개 실제 최상위 객체입니다. 모두 XML에 부모 `UIParent`가 명시되어 있습니다. 이름만 일치하고 부모가 다른 객체는 등록하지 않습니다. 특성과 마법책은 현재 `GetTab()` 및 소스에서 확인한 `talentTabID`/`spellBookTabID`로 구별하고, 전체 창을 이동하면서 각 화면의 마지막 위치를 따로 저장합니다. 전문화 화면은 지원 대상에서 제외했습니다.

소스 고정 리비전: `15666a6e67938a1ab5caf041406464251db111ca`.

- [지도 XML](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_WorldMap/Blizzard_WorldMap.xml)
- [캐릭터창 Camelot XML](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_UIPanels_Game/Camelot/CharacterFrame.xml)
- [특성·마법책 Camelot XML](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_PlayerSpells/Camelot/Blizzard_PlayerSpellsFrame.xml)
- [특성·마법책 Camelot 동작](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_PlayerSpells/Camelot/Blizzard_PlayerSpellsFrame.lua)
- [PlayerSpells 탭 전환](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_PlayerSpells/Blizzard_PlayerSpellsFrame.lua)
- [PlayerSpells 로드 목록](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_PlayerSpells/Blizzard_PlayerSpells.toc)
- [매크로 XML](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_MacroUI/Blizzard_MacroUI.xml)
- [마우스 포커스 API](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_APIDocumentationGenerated/InputDocumentation.lua)
- [공식 Frame Stack 연결](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_FrameStack/FrameStack.lua)

## 위치 저장 및 기본 위치 복원

`KHQOLDB.frameMover = { enabled=false, modifier="SHIFT", positions={} }`를 추가합니다. 기존 프로필 구조를 변경하지 않기 위해 계정 공용으로 저장하고, 프로필을 바꿔도 FrameMover 설정은 유지합니다. 기존 키와 데이터는 삭제하거나 재작성하지 않습니다.

`positions.Map/Character/Talents/Spellbook/Macro`에 `point="CENTER"`, `relativePoint="BOTTOMLEFT"`, `x`, `y`를 저장합니다. 드래그 종료 시 프레임과 UIParent의 유효 배율 비율로 중심 좌표를 변환합니다. 저장 앵커의 상대 프레임은 항상 `UIParent`입니다. 비정상 좌표·NaN·잘못된 앵커 데이터는 적용하지 않습니다. 저장은 드래그 종료 또는 이동 중 창 닫기 시에만 수행하며 매 프레임 저장하지 않습니다.

첫 제어 전 `GetNumPoints()`의 모든 `GetPoint(i)`를 런타임에서 백업합니다. 기본 위치의 좌표를 하드코딩하지 않습니다. 원래 `IsMovable`, `IsClampedToScreen`, `IsUserPlaced` 값도 백업합니다. 초기화/OFF 시 모든 앵커와 플래그를 복원합니다. 게임 자체의 user-placed 위치 캐시에 FrameMover 좌표가 남지 않도록 이동 종료 후 원래 `IsUserPlaced` 값을 되돌립니다. Reload 후에는 새로 생성된 기본 프레임에서 다시 원본을 백업한 뒤 애드온 저장 위치를 적용합니다.

## Lazy Load 및 성능

초기화 시 존재하는 whitelist 프레임만 등록합니다. `ADDON_LOADED`는 registry에 명시된 Blizzard AddOn에 대해서만 처리합니다. `PLAYER_LOGIN`, `PLAYER_ENTERING_WORLD`, `PLAYER_REGEN_ENABLED`와 각 프레임의 `OnShow`로 늦은 생성 및 복원을 처리합니다. 없는 프레임은 건너뛰고 다른 전역 이름을 추정하지 않습니다.

Blizzard가 OnShow 이후 또는 탭·창 크기 변경 시 재배치하는 경우를 위해 네 개 대상 객체의 `SetPoint`에만 안전 후킹을 적용합니다. 재진입 방지 플래그를 사용하며 사용자 위치가 있는 경우에만 다시 적용합니다. 공유 창은 `SetTab`에도 후킹합니다. UIParent 후킹·전역 함수 교체·UIPanel attribute 변경은 하지 않습니다.

FrameMover에는 OnUpdate, 타이머, 주기적 프레임 검색, EnumerateFrames가 없습니다. OFF 시 신규 핸들을 생성하지 않습니다. 한 번 등록한 안전 후킹은 WoW 특성상 제거하지 못하지만 OFF 상태에서는 위치를 변경하지 않습니다.

Inspector는 소스에 정의된 `GetMouseFoci()`를 우선하며 실제 런타임 함수 존재를 확인합니다. 구형 클라이언트에서는 `GetMouseFocus()`로 대체합니다. 어느 API도 없으면 안내만 표시합니다. 전체 프레임 열거는 하지 않습니다. ON이며 검사기 페이지가 보일 때만 OnUpdate를 설치하고 0.25초 간격으로 직접 포커스를 조회합니다. OFF/페이지 닫기 시 OnUpdate를 제거합니다. 켜져 있을 때 경과 시간을 누적하는 OnUpdate 콜백은 매 프레임 호출되지만 실제 조회·정보 갱신은 초당 최대 4회입니다.

## Combat Lockdown 및 Frame Stack

전투 중에는 이동 시작과 프레임 등록·앵커·이동 플래그 변경을 수행하지 않습니다. OFF/초기화 요청의 저장 데이터 삭제는 즉시 수행하고 물리적 복원은 `PLAYER_REGEN_ENABLED`까지 보류합니다. 드래그 중 전투에 진입하여 종료가 제한되는 경우에도 전투 종료 후 이동 정리 및 복원을 처리합니다.

공개 소스의 공식 FrameStack 연결은 `Blizzard_DebugTools`를 로드하고 `FrameStackTooltip_Toggle(false, true, true)`를 호출합니다. 배포 코드도 이 방식을 사용합니다. 런타임 AddOn/API 존재를 확인하며, 사용 불가 또는 전투 중에는 버튼을 비활성화합니다. `/fstack`은 안내용이며 임의 슬래시 명령을 실행하지 않습니다. 현재 설치 클라이언트의 실제 `/fstack` 실행은 미검증입니다.

## 검증 결과

- Lua 5.1 문법: 전체 Lua 76개 파일 PASS.
- TOC: 등록 파일 72개 존재 및 버전 1.10.1.0 PASS.
- 모의 환경: 197개 assertion PASS. 드래그 보조키, 배율 변환, 모든 원본 앵커/플래그 복원, 초기화 ON 유지, OFF 삭제 후 ON, 늦은 로드, 네 객체 중복 등록 방지, 다섯 대상별 드래그·닫기/열기, 특성/마법책 독립 위치, 전문화 제외, 전투 중 이동 차단·복원 보류·이동 정리, 새 런타임 프레임에 저장 데이터 복원, 기존 DB 보존을 검사했습니다.
- Inspector 모의 검사: 기본/OFF 무탐색, 직접 API 및 fallback, 0.25초 제한, 이름·부모·strata·level·size·앵커 텍스트, KHQOL 위 마지막 정보 유지, 복사 입력창 선택, 페이지 닫기 OFF, 공식 FrameStack 호출 및 미지원 처리 PASS.
- 기존 파일을 기준 ZIP과 해시 비교했습니다. 변경 목록 외 코드·폰트·미디어·설정 파일은 원본 바이트를 유지합니다.
- 패키지 ZIP 무결성 및 폴더 구조를 검사합니다. 결과는 별도 validation JSON에 기록합니다.

**실제 게임 검증: 미실시.** 활성 Forever 게임 세션이 없으므로 각 창의 화면·제목 표시줄 히트 영역·실제 Shift/Ctrl/Alt 드래그·지도 확대/축소·Reload·재접속 후 디스크 저장·전투 taint/blocked action·실측 CPU는 직접 검증하지 못했습니다. 모의 새 런타임 검사를 실제 `/reload`/재접속 성공으로 보고하지 않습니다.

게임 내 확인 순서: 다섯 창 각각 OFF 기본 동작 → ON Shift 이동 → Ctrl 선택 시 Shift 차단/Ctrl 이동 → 닫기/다시 열기 → Reload → 재접속 → 전체 초기화(ON 유지) → OFF 복원 → 다시 ON에서 과거 위치 없음. 검사기는 각 창 위에서 이름·부모·크기·앵커·복사·Frame Stack 확인 후 OFF 상태에서 갱신이 멈추는지 확인합니다.

## 제한사항

- 설치 클라이언트의 CASC 내 Blizzard 소스를 직접 추출하거나 실행 객체를 관측하지 않았습니다. 고정 공개 Camelot 리비전과 현재 설치 빌드 간 변경 가능성은 남아 있습니다.
- 실게임 taint가 발생하지 않는다는 보장은 할 수 없으며, 전투 시 프레임 변경을 보류하는 코드 경로만 모의 검증했습니다.
- 조작 영역은 제목 표시줄의 빈 부분입니다. 창 전체에 드래그를 덮지 않습니다.
- 기본 앵커 백업은 세션 내 최초 제어 전 상태입니다. 먼저 개입한 다른 프레임 이동 애드온이 있으면 그 상태가 백업될 수 있습니다.
- 화면 해상도·배율 변경, 다른 이동 애드온과의 충돌은 게임 내 검증이 필요합니다.
- 특성·마법책은 동일 루트 객체를 공유합니다. 전문화 탭에서 FrameMover는 기본 위치로 복원하고 핸들을 숨깁니다.
- Inspector 화면 텍스트가 긴 경우 전체 부모 경로·앵커는 복사 입력창에서 확인할 수 있습니다.

## 수정/추가 파일

- 수정: `KHQOL/Bootstrap.lua`
- 수정: `KHQOL/CHANGELOG.md`
- 수정: `KHQOL/Core.lua`
- 수정: `KHQOL/KHQOL.toc`
- 수정: `KHQOL/UI/ConvenienceSettings.lua`
- 수정: `KHQOL/UI/LabSettings.lua`
- 수정: `KHQOL/UI/SettingsRegistry.lua`
- 추가: `KHQOL/Modules/FrameInspector.lua`
- 추가: `KHQOL/Modules/FrameMover.lua`
- 추가: `KHQOL/RELEASE-1.10.1.0.md`
