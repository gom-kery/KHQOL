# KHQOL 1.11.6.4 위치 수정본

식별자: 1.11.6.4-position-fix1. 기준은 1.11.6.4 전체 ZIP이며 정식 버전 증번 없이 모든 TOC Version 1.11.6.4 / Interface 16001을 유지합니다.

## 표시 Y 위치

강조 프레임의 기본 Y를 -35에서 **-60 UI px**로 내려 모든 효과를 기존보다 25 UI px 아래에 배치합니다. 실험실 → 오브젝트 강조 → 공통 설정에 **강조 Y 위치** 슬라이더(-200~100)를 추가했습니다. 더 작은 음수일수록 아래로 이동하며, -35로 설정하면 기존 높이입니다. Subtle/Reticle/Brackets/Sparkle 및 세 카테고리에 공통 적용합니다. 사용자 화면의 정확한 정렬은 카메라 각도/원근/화면 배율에 따라 달라 조절값을 제공합니다.

새 설정은 기존 objectHighlight 프로필 안의 offsetY 하나입니다. 없는 기존 프로필은 -60을 받고 기존 효과/색상/크기/투명도/사용 여부는 유지합니다. 유효한 저장값은 보존하고 범위를 벗어나거나 유효하지 않은 값만 정규화합니다. 설정 변경 시 같은 효과 프레임을 재사용하며 즉시 반영합니다. `/오브젝트진단`에도 offsetY를 출력합니다.

## 20~25m 감지 요청

현재 Soft Target 방식으로 20~25m 확장을 지원한다는 근거는 확인하지 못했습니다. Forever용 Lueur 개발 문서는 SoftTargetInteractRange의 한도를 **15m(API 제한)**로 명시합니다. [공식 개발자 설명](https://www.curseforge.com/wow/addons/lueur).

따라서 이 수정본은 Range를 20/25로 강제 쓰거나, 실제 감지되지 않은 오브젝트를 추측해 표시하지 않습니다. nameplateGameObjectMaxDistance의 표시 거리와 softinteract 감지 거리는 다른 설정입니다. 이름표 거리를 늘려도 현재 감지 대상이 제공된다고 보장할 수 없습니다. 특히 사용자의 클라이언트에서는 Range 쓰기가 보호된 사례가 있어, 기존 1.11.6.4의 현재값 유지·제한 안내 정책을 그대로 사용합니다. 실제 감지 범위가 15m보다 짧을 수도 있습니다.

이는 참고 개발자 문서와 현재 코드 경로를 근거로 한 판단입니다. 엔진의 정확한 거리 상한을 수정본으로 실게임 실측한 것은 아닙니다. 이번 변경은 표시 위치이며 거리 확장을 완료했다고 보고하지 않습니다.

## 변경 파일·검증

- KHQOL_Labs/Modules/GatheringHighlight.lua: offsetY 기본값/정규화, 기존 Present의 Y 인자 사용.
- KHQOL_Labs/UI/LabSettings.lua: Y 슬라이더와 방향/기존값 설명.
- KHQOL_Labs/UI/SearchIndex.lua: ‘강조 Y 위치’ 검색 항목.
- KHQOL_Labs/Modules/ObjectHighlightDiagnostics.lua: 수정본 식별자/실제 offsetY 출력.
- KHQOL/README.md 및 OBJECT-POSITION-FIX1.md: 현재 안내. 나머지 모듈/CVar/경험치/직업색 코드는 동일합니다.

Lua 218/218, 모의 시나리오 309/309, TOC 20개 참조 누락 0. 기존 회귀 외 새 기본값·기존 설정 보존, 네 효과의 위치 변경/이전 높이 복귀, 값 정규화, 실제 UI 콜백과 동일 프레임 재사용을 확인했습니다. ZIP CRC·소스 바이트 일치·기준 파일 누락 0도 검사했습니다. **수정된 Y의 실제 게임 화면은 NOT TESTED**입니다.

게임 종료 후 기존 코드 폴더를 백업하고 전체 ZIP의 최상위 애드온 폴더들을 교체하세요. WTF/SavedVariables는 유지합니다. 이번 작업에서 설치 폴더에 직접 쓰거나 Git commit/push하지 않았습니다. 실게임에서는 가까운 광맥에서 Y=-60을 확인한 뒤 더 내리려면 -70/-80 등으로 조정하고, 효과 변경·프로필 전환·Reload 뒤 저장값과 정렬을 확인하세요.
