# KHQOL 1.11.7.0 변경·검증 보고서

기준은 `KHQOL-1.11.6.5.zip`입니다. SHA-256 `3261868cf517d23bfaacb5bde4043172de3c9e3275284a448e7879aab78ebef5`를 기준 ZIP 보존 검사에 사용했습니다.

## 변경 파일과 모듈 소유권

| 범위 | 적용 |
| --- | --- |
| `KHQOL_Clock/Clock/ClockTools.lua`, `Clock/Settings.lua`, `Adapters.lua`, `Positions.lua` | 전체 390×282 기본 크기, 80~100% 눈금, 314×42 축소 바, 음식 900초 프리셋. 전체·축소가 실행 상태와 기존 갱신 타이머를 공유합니다. 바 위치 잠금은 기본 ON이며 전체 창 위치와 별도로 저장합니다. 알람 문구는 계정 공용입니다. |
| `KHQOL_Campfire/Campfire/UI.lua`, `UI/Settings.lua`, `Positions.lua`, `KHQOL/ProfileTransfer.lua` | 60~120px·10px 간격·100px 기본값을 옵션, 아이콘, 위치 편집, 저장과 가져오기에 공통 적용합니다. 105→110, 115→120, 140→120입니다. 닫기 버튼은 아이콘 오른쪽에 배치합니다. |
| `KHQOL/UI/WindowLayers.lua`, `SettingsUI.lua`, `UI.lua`, `UI/SettingsNavigation.lua`, `UI/SettingsPresenter.lua`, 시계·노트 및 채팅 창 | 일반 설정창과 검색·선택 목록, ForeverNote, 알람·타이머·축소 바, 스톱워치, 전문기술 창과 채팅 링크 복사 창에 적용합니다. 기본 UI 우선이 기본값입니다. KHQOL 우선에서도 기본 확인창과 색상 선택창이 표시되면 일반 창이 뒤로 물러납니다. |
| `KHQOL_Range/Range/Settings.lua`, `KHQOL_UnitFrames/Party/WheelBook.lua` | 사거리 공용 주문 등록과 파티 전용 등록이 기본 스킬창 위에 표시됩니다. 프레임 묶음 미설치 시 사거리 탭만 제공합니다. 탭 전환, 스킬창 닫기, 전투 진입에 등록창을 닫습니다. |
| `KHQOL_Map/Buttons.lua`, `Core.lua` | 주머니 배경·열기 버튼·수납 아이콘·페이지 버튼을 채팅 위에 둡니다. 은행과 순서 또는 겹침을 안전하게 판단할 수 없는 동안 주머니를 숨겨 입력을 양보합니다. 은행이 닫히면 그때의 주머니 설정과 열림 상태를 사용합니다. 수납을 해제하면 기존 복원 경로를 사용합니다. |
| `KHQOL/BasicUI/`, `KHQOL/Installation.lua` | 기본 설치의 KHQOL이 `basicUI`, `frameMover`, `castBar`를 소유합니다. 대상 시전바는 개인 모듈이 OFF 또는 미설치일 때 기본 대상 프레임에 붙고, ON이면 기존 자원·체력 바와 대상 오라 배치 연동을 사용합니다. |
| `KHQOL_UnitFrames/Modules/`, `UI/`, `Party/`, `Adapters.lua`, `KHQOL/Profiles.lua` | 선택 묶음이 기존 ID `unitFrames`, `partyFrames`를 소유합니다. 미설치 동안에도 개인 프레임 스냅샷과 ON/OFF를 프로필별로 보관합니다. OFF 상태의 초기화는 현재 프로필의 개인 설정·보조 표시를 저장한 뒤 리로드합니다. 공통 직업 색상과 다른 설정은 보존합니다. |

은행만 미니맵 주머니의 기본 상호작용 창 정책에 넣었습니다. 길드은행·상점·우편·경매장의 실제 Forever 입력은 확인하지 못했습니다. 창 상태와 우선순위 갱신은 창 열기·닫기, 필요한 애드온 로드, 설정·프로필 변경 및 전투 종료에서 처리합니다.

스킬창 관찰 지점은 공개된 Camelot FrameXML의 `PlayerSpellsFrame.SpellBookFrame`과 `SetTab`을 기준으로 잡았습니다. 일반 창의 확인창 양보는 Blizzard의 `StaticPopup` 레이어와 분리해 처리했습니다. [Camelot 스킬창 XML](https://raw.githubusercontent.com/Gethe/wow-ui-source/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_PlayerSpells/Camelot/Blizzard_PlayerSpellsFrame.xml), [PlayerSpells 탭 코드](https://raw.githubusercontent.com/Gethe/wow-ui-source/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_PlayerSpells/Blizzard_PlayerSpellsFrame.lua), [Blizzard StaticPopup 코드](https://raw.githubusercontent.com/Gethe/wow-ui-source/live/Interface/AddOns/Blizzard_StaticPopup/StaticPopup.lua)

## 저장 범위

- 전체 프로필과 프레임 설정은 `KHQOLDB`에 있습니다. 파티 공용 역할 프로필은 `KHQOLDB.globalData.partyFrameProfiles`, 역할 선택·자동 전환·휠 주문은 `KHQOLPartyCharDB`의 기존 경로에 남습니다.
- 개인 프레임 보조 표시의 기존 저장 경로 `KHQOLResourceSwingDB`를 유지합니다. 공유 직업 색상은 현재 전체 프로필의 기존 값을 읽습니다.
- 크기·표시 모드·바 위치는 `ForeverClockDB.clockTools`의 전체 프로필 흐름에 연결됩니다. 실행 중인 카운트다운은 접속 중에만 유지됩니다.
- 기존 저장 변수 소유권을 유지합니다. 코어 KHQOL 10개, KHQOL_Map의 `KHQOLMapDB` 1개, 기존 독립 KHQOL_DevTools의 1개입니다. 선택 ZIP에 새 저장 변수 선언은 없습니다.

## 정적·모의 검증

| 범위 | 통과 |
| --- | ---: |
| 타이머·모닥불 | 16/16 |
| 창 우선순위·스킬창·은행 | 10/10 |
| 프레임 설치·이전 저장값·복원·초기화 | 18/18 |
| 전체 설정 화면·창 이동·시전바 연결 | 6/6 |
| 기존 지도·경로 회귀 | 204/204 |
| 합계 | 254/254 |

Lua 5.1 문법 222개, XML 7개, TOC 19개 및 참조·의존성, 저장 변수 12개의 소유권, 원본 미디어 37개의 바이트 동일성을 검사했습니다. 다섯 설치 조합과 구버전 파티 폴더의 양쪽 로드 순서를 모의 검증했습니다. 두 ZIP의 CRC·경로·해시와 제외 폴더는 압축 후 확인했습니다.

## 실제 Forever에서 확인할 항목

**인게임 미실시 · 검증용 빌드.** 로컬 Forever 클라이언트는 1.60.1.70888로 확인했습니다. 아래 항목은 실제 UI와 보호 실행 환경에서 확인해야 합니다.

1. 게임 UI 배율을 바꿔 최소 알람·타이머 창의 한글과 숫자 입력, 접기·펼치기, 소리·알람 1회, 타이머 바 드래그·화면 가장자리·위치 편집 테두리를 확인합니다.
2. 모닥불 60·100·120px에서 글자와 닫기 버튼 간격, 위치 편집 크기, 기존 105·140px 가져오기 결과를 확인합니다.
3. 두 창 우선순위에서 설정·노트·시계 도구·확인창을 겹칩니다. 은행의 슬롯·버튼·휠과 주머니·채팅을 겹쳐 클릭하고 은행 종료 후 현재 설정대로 복귀하는지 확인합니다. 스킬창 등록은 사거리+파티, 사거리만, 파티만 구성에서 탭 변경·닫기까지 확인합니다.
4. 전투 중 지도 열기·ESC·스킬창 전환과 전투 종료 후 보호 오류 또는 표시 지연을 확인합니다. 대상 시전바와 오라, 기본 창 이동도 함께 확인합니다.
5. 모듈 OFF 후 Blizzard 기본 프레임·휠을 확인하고 다른 프레임 애드온으로 전환합니다. 이전 폴더 정리, 여러 캐릭터의 저장과 `/reload`·재접속을 실제 클라이언트에서 재확인합니다.
