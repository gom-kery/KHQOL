# KHQOL 1.10.1.3 작업 결과

기준 버전: 1.10.1.2. 결과 버전: 1.10.1.3. 날짜: 2026-10-09.

## 설정 및 저장

경로: `KHQOL > 편의 기능 > 일반 > 대화창`.

체크박스는 **기본 대화창 편의 기능** 하나입니다. 설명: ‘대화 입력 커서 이동, 이전 대화 호출, 링크 툴팁 및 URL 복사 기능을 개선합니다.’ 기본 OFF입니다. 기존 `KHQOLDB.general.chatEnhancement`에 boolean을 추가하며 기존 저장값과 프로필 구조를 보존합니다. 프로필 변경 시 런타임 상태를 다시 적용하고 Reload 시 저장 설정을 읽습니다. 별도 채팅 history DB나 독립 애드온은 만들지 않습니다.

## 입력창 방향키

- 소스에서 확인한 `GetAltArrowKeyMode()` / `SetAltArrowKeyMode(false)`를 사용합니다.
- 채팅 EditBox가 보이고 실제 Focus를 가진 경우에만 변경합니다. 일반 게임 키 바인딩과 다른 입력창은 변경하지 않습니다.
- Focus 상실, 숨김, 기능 OFF 시 백업한 원래 모드를 복원합니다.
- ←/→ 커서 이동과 ↑/반복 ↑의 history는 Blizzard EditBox 엔진에 맡깁니다. 문자열 자르기, UTF-8 byte 단위 커서 조작, 별도 이전 대화 기록은 없습니다. 기존 Alt 방향키도 같은 네이티브 엔진의 처리를 유지합니다.
- 자동 완성창이 열린 동안에는 Blizzard의 방향키 선택을 우선합니다. 자동 완성 종료 후 일반 방향키 모드를 다시 적용하고, OFF 상태에서는 원래 모드를 복원합니다. Blizzard의 자동 완성 캐시나 원본 함수는 덮어쓰지 않습니다.
- 한글/영어/숫자/특수문자/혼합 문자열을 KHQOL이 다시 작성하지 않습니다. **실제 네이티브 커서 이동, 한글 IME 및 Alt 조합은 게임에서 검증하지 못했습니다.**

## 아이템·퀘스트 MouseOver

각 Blizzard ChatFrame의 `OnHyperlinkEnter` / `OnHyperlinkLeave`에 HookScript를 추가합니다. 원본 스크립트와 `OnHyperlinkClick`/SetItemRef 처리는 유지합니다.

- `item:` 또는 `quest:` 링크에만 GameTooltip을 표시합니다.
- `GameTooltip_SetDefaultAnchor` → `SetHyperlink` → `Show`의 기본 흐름을 사용합니다.
- 기존 KHQOL Tooltip 모듈의 기본 앵커 후킹과 아이템 데이터 후처리를 그대로 통과하며, 모듈이 활성화되어 있으면 `ApplyTextSize`로 퀘스트를 포함한 글자 크기도 반영합니다.
- MouseLeave 시 이 기능이 표시했고 여전히 해당 ChatFrame이 소유한 툴팁만 숨깁니다. 다른 프레임이 소유한 툴팁은 숨기지 않습니다.
- MouseLeave는 요청대로 즉시 Hide를 사용합니다. 기존 툴팁의 fadeOutTime/유지 시간 저장 설정은 수정하지 않습니다.
- 기존 Tooltip의 전투 중 유닛 툴팁 숨김은 유닛 툴팁 대상 정책이며, 이번 항목은 아이템·퀘스트입니다. 기존 정책과 코드는 변경하지 않았습니다.
- 금지/secret 데이터 또는 전투 중 보호된 GameTooltip은 처리하지 않습니다. 보호된 툴팁의 숨김 요청은 전투 종료 후 처리합니다.

## URL 판별 및 클릭

**URL 자동 링크 변환, AddMessage 교체, 채팅 메시지 필터를 추가하지 않았습니다.** 원문 그대로 표시된 URL의 글자 영역을 클릭하면 복사창을 엽니다.

1. 마우스 클릭이 종료될 때만 클릭한 ChatFrame의 표시 줄을 찾습니다.
2. `GetScaledCursorPosition` / `FindCharacterAndLineIndexAtCoordinate`로 줄을 찾고, FontString의 `FindCharacterIndexAtCoordinate`로 실제 줄 안의 클릭인지 확인합니다.
3. 해당 줄의 원문에서 URL 구간을 찾습니다. `CalculateScreenAreaFromCharacterSpan`으로 Blizzard가 계산한 구간의 화면 영역을 받아 클릭 위치가 URL 글자 영역 안에 있는지 확인합니다. 줄바꿈된 URL은 여러 화면 영역으로 검사합니다.
4. 지원: `http://`, `https://`, `www.` 및 `discord.gg/`, `youtu.be/`, `youtube.com/`, `github.com/`.
5. Blizzard hyperlink의 payload와 표시 이름, texture/atlas markup 전체는 건너뜁니다. 아이템·퀘스트·주문·업적·플레이어·Battle.net 등 원래 링크를 가로채지 않습니다.
6. 드래그 이동은 클릭으로 처리하지 않습니다. 상호작용 불가로 설정한 채팅창은 그대로 존중합니다.

클릭 직후 표시 줄 하나만 읽습니다. 채팅 history 전체를 검색하지 않습니다. ON 시 원문 URL 클릭 및 링크 MouseOver를 위해 ChatFrame의 mouse click/motion 입력을 활성화하고, OFF 시 원래 상태를 복원합니다.

Parser는 단순한 토큰 규칙이며 URL 주위의 괄호·마침표·쉼표 등 끝 구두점을 제거합니다. 최대 메시지 8192 byte, URL 2048 byte입니다. 복잡한 괄호가 URL 자체에 포함되는 경계 사례는 게임 내 확인이 필요합니다. 다른 애드온이 이미 만든 hyperlink 안의 URL은 해당 애드온/Blizzard 처리를 우선하여 변경하지 않습니다.

## 복사창 및 Ctrl+C

KHQOL 공통 Label/Button/EditBox/Surface를 사용하는 작은 `KHQOLChatURLCopy` popup을 생성합니다. URL 전체 문자열을 넣고 Focus 및 전체 선택 상태로 엽니다. 기본 Ctrl+A/C 처리와 EditBox 텍스트 처리는 차단하지 않습니다. 브라우저를 실행하지 않습니다.

- Ctrl+C OnKeyDown 감지 후 `C_Timer.After(0, ...)`로 네이티브 복사 키 처리가 끝난 다음 Focus를 해제하고 닫습니다.
- Timer API가 없으면 Ctrl+C의 OnKeyUp에서 닫습니다.
- Esc / Enter / X 버튼으로 닫습니다. 외부 클릭만으로는 자동 닫지 않습니다.
- 이전 팝업의 닫기 예약이 새 팝업을 닫지 않도록 세대 번호를 검사합니다.
- 클립보드 성공 여부는 확인할 수 없습니다. 요청에 허용된 Ctrl+C 키 입력 감지를 기준으로 닫습니다.

## 여러 ChatFrame 및 API 차이

공개 Camelot 계열 ChatFrame 소스를 확인했습니다. 이 계열은 옛 전역 `ChatFrame_OnHyperlinkEnter` 대신 `ChatFrameMixin` 스크립트와 `ChatFrame.OnEditBoxShow` EventRegistry를 사용합니다.

- 초기 `CHAT_FRAMES`의 이름 목록을 등록합니다. 목록이 없는 구형 환경은 NUM_CHAT_WINDOWS의 명명된 창만 확인합니다.
- `FCF_OpenNewWindow` / `FCF_OpenTemporaryWindow`를 secure hook하여 신규/임시 창을 등록합니다.
- `ChatFrame.OnEditBoxShow` 콜백으로 늦은 EditBox와 소유 ChatFrame도 등록합니다.
- `FCF_SetUninteractable` 및 `AutoComplete_HideIfAttachedTo`는 원본을 보존하는 secure hook을 사용합니다.
- ADDON_LOADED / PLAYER_ENTERING_WORLD에 로드 대응, PLAYER_REGEN_ENABLED에 보류된 보호 UI 변경을 적용합니다.
- 각 API의 실제 함수 존재 여부를 런타임에서 확인합니다. 원문 URL hit-test API가 없는 구형 환경에서는 오류 없이 URL 클릭을 생략합니다.

현재 설치 클라이언트의 소스를 CASC에서 직접 추출하거나 실행 중인 채팅창 API를 직접 관측하지는 못했습니다. 앞선 사용자 검사기 캡처의 클라이언트는 1.60.1 / 70291 / 16001이며, 구현은 공개 Camelot 소스와 런타임 존재 검사에 기반합니다.

## 성능 및 secure/taint

이번 모듈에는 OnUpdate, 반복 타이머, ChatFrame 전체 history 검색, EnumerateFrames, 전역 키 바인딩 변경이 없습니다. 입력 Focus·hyperlink hover·마우스 클릭·로드/설정 이벤트로만 동작합니다. Timer는 Ctrl+C 직후 한 번 닫는 작업에만 사용합니다.

원본 ChatFrame 함수, 링크 클릭 처리 및 메시지 필터는 교체하지 않습니다. 전투 중 일반 채팅 입력은 기존 네이티브 기능을 사용합니다. 보호된 프레임의 등록·입력 상태 변경은 전투 종료까지 보류합니다. secret 데이터를 읽거나 계산하지 않습니다.

**실제 게임 taint/blocked action 검증은 미실시입니다.** 모의 환경의 보호 상태 및 보류 경로만 검증했고 ‘taint 없음’을 실제 게임 결과로 주장하지 않습니다. KHQOL의 기존 Tooltip/다른 모듈에 원래 있던 갱신 코드는 변경하지 않습니다.

## 테스트 결과

- 전체 Lua 77개 파일 Lua 5.1 문법 PASS.
- TOC 파일 73개 존재 및 1.10.1.3 버전 일치 PASS.
- 신규 ChatEnhancement 모의 검증 100개 assertion PASS.
- 기존 FrameMover/Inspector/설정 헤더 회귀 214개 + 파괴 확인 자동 입력 23개 assertion PASS.
- 합계 337개 assertion PASS.
- 검증 항목: Focus에 따른 원래 arrow mode 백업/복원, 한글 혼합 입력 텍스트 보존, 추가/임시 창과 late EditBox, 자동 완성과 ON/OFF, 아이템·퀘스트 tooltip 및 원본 클릭 보존, 다른 소유자/금지/보호 tooltip, URL 종류·markup 제외·원문 좌표·클릭 영역·드래그 제외, 복사 Focus/전체 선택·Ctrl+C 지연 닫기·새 창 보호·Esc/Enter·Timer 없는 fallback, OFF 상태 복귀·기존 설정 보존·보호 프레임 보류·secret 데이터 건너뛰기.
- Native 글자 이동/IME/history/Alt 동작, 실제 URL 위치(배율·줄바꿈), 게임 내 Clipboard, 추가 채팅창 화면 및 전투 taint는 게임에서 확인해야 합니다. 이번 검증은 소스/모의 검사입니다.

## 설치 및 게임 내 확인

ZIP의 `KHQOL` 폴더를 기존 Interface/AddOns/KHQOL에 덮어쓰고 `/reload`합니다. SavedVariables를 삭제하지 마세요. 설치 폴더는 이번 작업에서 직접 수정하지 않았습니다.

‘기본 대화창 편의 기능’을 켠 뒤 입력창에서 ←/→/↑ 및 Alt 조합과 한글/영문/혼합 입력을 확인하세요. 아이템·퀘스트 링크 hover/leave와 기본 클릭, 여러 창에서 원문 URL 클릭 → Ctrl+C/Enter/Esc를 확인하세요. OFF 및 다시 ON, Reload 및 프로필 변경 후 설정도 확인하세요.

## 확인한 소스

- [ChatFrame 기본 hyperlink 처리](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_ChatFrameBase/Shared/ChatFrame.lua)
- [EditBox Focus·history 흐름](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_ChatFrameBase/Shared/ChatFrameEditBox.lua)
- [추가/임시 ChatFrame](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_ChatFrameBase/Mainline/FloatingChatFrame.lua)
- [원문 클릭 및 FontString 선택 구간](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_SharedXML/ScrollingMessageFrame.lua)
- [EditBox AltArrowKeyMode API](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleEditBoxAPIDocumentation.lua)
- [FontString 클릭 구간 API](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleFontStringAPIDocumentation.lua)
- [자동 완성 모드 복원](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_AutoComplete/AutoComplete.lua)

## 수정/추가 파일

- 수정: `KHQOL/Bootstrap.lua`
- 수정: `KHQOL/CHANGELOG.md`
- 수정: `KHQOL/Core.lua`
- 수정: `KHQOL/GeneralOptions.lua`
- 수정: `KHQOL/KHQOL.toc`
- 수정: `KHQOL/Profiles.lua`
- 추가: `KHQOL/Modules/ChatEnhancement.lua`
- 추가: `KHQOL/RELEASE-1.10.1.3.md`
