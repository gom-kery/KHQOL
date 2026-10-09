# KHQOL 1.10.1.2 작업 결과

기준: 1.10.1.1. 기존 SetUserPlaced 오류 수정 포함. 날짜: 2026-10-09.

## 프레임 검사기

- ‘프레임 인스펙터 활성화’를 고정 모듈 설명 영역 오른쪽으로 이동했습니다. 스크롤해도 표시됩니다.
- ‘현재 정보 복사’, ‘Frame Stack 열기’를 설정창 푸터 위의 고정 영역으로 이동했습니다. 검사기에서만 표시하며 다른 탭에서는 기존 푸터/스크롤 영역을 복원합니다.
- 정보 글자를 TOP 정렬하고 고정 500 높이를 제거했습니다. 안내 문구와 정보가 위에서부터 나오며 실제 줄 높이에 맞춰 콘텐츠 높이를 갱신합니다.
- 숫자는 소수점 둘째 자리까지 표시하고 불필요한 0을 제거해 크기·앵커 정보의 가독성을 개선했습니다.
- 일반적인 프레임 정보는 한 화면에 표시되도록 여백을 줄였습니다. 부모 경로/앵커가 매우 길면 본문만 스크롤되며 고정 버튼은 계속 표시됩니다.
- 복사 버튼은 화면 안의 입력창을 표시하고 전체 정보를 선택합니다. Ctrl+C로 복사하고 Esc로 닫습니다. 숨겨진 입력창을 위해 본문에 빈 높이를 확보하지 않습니다.
- Inspector OFF 또는 페이지 닫기 시 갱신 중단, Reload 후 OFF, KHQOL 위 마지막 정보 유지 정책은 유지합니다.

## 아이템 파괴 확인 문구 자동 입력

경로: `편의 기능 > 일반 > 아이템 파괴 > 아이템 파괴 확인 문구 자동 입력`.

- 기본 OFF. 설정을 켜면 파란색 등급 이상의 아이템 파괴 시 Blizzard가 띄우는 입력형 확인창에 확인 문구를 자동 입력합니다.
- 정확한 대상은 `DELETE_GOOD_ITEM`입니다. 단순 파괴창·다른 확인창·게임패드 전용 확인창은 변경하지 않습니다.
- 한국어 문구를 하드코딩하지 않고 `DELETE_ITEM_CONFIRM_STRING`을 사용합니다. 현재 한국어 클라이언트에서는 ‘지금 파괴’입니다.
- Blizzard의 `StaticPopup_OnShow`가 완료된 뒤 후킹하여 입력합니다. 기존 OnTextChanged 검증이 ‘예’ 버튼을 활성화합니다. 원래 dialog 정의/승인 콜백은 변경하지 않습니다.
- **‘예’를 자동 클릭하거나 아이템을 자동 파괴하지 않습니다.** 최종 확인은 사용자가 선택합니다.
- 이미 입력한 문구, 숨겨진 창, 보안 입력창, 확인 문자열을 제공하지 않는 환경은 건너뜁니다.
- 추가 저장 키는 기존 프로필 대상인 `KHQOLDB.general.autoConfirmDestroy`입니다. 기존 설정은 보존하고 누락된 키에만 기본값 false를 추가합니다.
- 주기적 검색이나 OnUpdate를 추가하지 않습니다. Blizzard 팝업 모듈이 늦게 로드되는 경우 ADDON_LOADED에서 후킹을 재시도합니다.

## 검증

- 전체 Lua 76개 파일의 Lua 5.1 문법 PASS.
- TOC 등록 파일 72개 존재 및 1.10.1.2 버전 일치 PASS.
- FrameMover/Inspector/실제 설정 헤더 함수 모의 검증 214개 assertion PASS.
- 실제 Blizzard `DELETE_GOOD_ITEM` 소스의 OnShow/OnTextChanged를 사용하는 자동 입력 모의 검증 23개 assertion PASS. 승인/클릭 0회 확인.
- 합계 237개 assertion PASS.
- Inspector 고정 컨트롤의 부모 영역, TOP 정렬, 정보 길이에 따른 높이 변경, 복사 오버레이·Esc 닫기, 다른 탭의 헤더·초기화 버튼·스크롤 영역 복원을 검사했습니다.
- 자동 입력의 기본 OFF/ON/OFF 전환, 한국어 및 다른 로케일 확인 문자열, 다른 팝업 제외, 기존 입력 보존, 보안/숨김 입력 제외, 원래 콜백 보존을 검사했습니다.
- 배포 ZIP을 1.10.1.1과 파일 단위로 비교합니다. 변경 대상 외 파일은 동일한 바이트로 보존하며, FrameMover.lua도 그대로 유지합니다.
- 실제 게임 화면·클릭·확인창 입력·taint는 이번 작업에서 직접 검증하지 못했습니다. 첨부 스냅샷의 문제와 소스/모의 환경을 기준으로 수정했습니다.

## 확인 순서

1. 검사기 탭에서 활성화 토글이 설명 영역 오른쪽에 고정되는지 확인합니다.
2. 창 위로 마우스를 옮겨 안내·정보가 상단부터 표시되는지 확인합니다.
3. 본문을 스크롤해도 복사/Frame Stack 버튼이 유지되는지 확인합니다.
4. 복사 → Ctrl+C → Esc, 다른 탭 전환 시 버튼 숨김·기존 레이아웃 복원을 확인합니다.
5. 자동 입력 옵션을 켜고 파괴 확인창에 ‘지금 파괴’가 입력되는지 확인합니다. 최종 ‘예’는 직접 선택합니다. 옵션 OFF 시 자동 입력하지 않는지 확인합니다.

## 설치

ZIP 내부 KHQOL 폴더를 기존 Interface/AddOns/KHQOL에 덮어쓰고 `/reload`하세요. SavedVariables를 삭제할 필요가 없습니다. 설치 폴더를 직접 수정하지 않았습니다.

## 사용한 Blizzard 소스

- [Camelot 아이템 파괴 확인창 선택](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_Game/Camelot/EventImplementation.lua)
- [입력형 파괴 확인창 및 확인 문구 검증](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_StaticPopup_Game/Mainline/GameDialogDefs.lua)
- [팝업 OnShow 처리](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_StaticPopup/StaticPopup.lua)

## 수정/추가 파일

- 수정: `KHQOL/Bootstrap.lua`
- 수정: `KHQOL/CHANGELOG.md`
- 수정: `KHQOL/Core.lua`
- 수정: `KHQOL/GeneralOptions.lua`
- 수정: `KHQOL/KHQOL.toc`
- 수정: `KHQOL/Modules/FrameInspector.lua`
- 수정: `KHQOL/SettingsUI.lua`
- 추가: `KHQOL/RELEASE-1.10.1.2.md`
