# KHQOL 1.11.3 변경·검증 보고서

기준: 전달된 1.11.2.5 Full · 결과: 1.11.3 · 2026-10-18.

## 구현

파티·공격대에 [공통] [파티·공격대] [버프·디버프] [프로필] 순서를 적용했습니다. 공통에 있던 디버프 아이콘 설정을 새 탭으로 옮기되 기존 `debuffs` 저장 키와 값을 유지합니다. 크기·간격 및 X·Y는 두 열, 좁은 폭에서는 한 열입니다. 새 설정도 계정 공용 프레임 프로필 안에 저장합니다.

체력이 차 있는 영역에 저주 #9600FF, 질병 #966400, 마법 #3296FF, 독 #009600, 출혈 #C80000의 RGBA 색을 겹칩니다. ON/OFF, 5종 각각의 색·투명도 및 기본색 복원을 제공합니다. 게임 기본 표시기가 우선순위로 한 디버프를 선택하며, 해제 시 색 레이어를 숨겨 기존 직업 색·그라데이션을 드러냅니다. 사망 음영은 효과 위, 이름·수치는 그 위에 표시합니다. 색 변경과 복원은 확장용 알 수 없는 설정 키를 보존합니다.

보호막은 자체 역방향 StatusBar로 총 흡수량/최대 체력 비율을 표시합니다. 오른쪽에서 왼쪽으로 채우며 과다 흡수는 게임 바의 최대 범위까지 표시합니다. 현재 체력 옆에 이어 붙이는 방식과 회복 예측은 이번 구현에 포함하지 않습니다. 사용 ON/OFF, 내장 보호막 무늬·흡수 무늬·WHITE8X8 단색, RGBA를 제공합니다. `UNIT_ABSORB_AMOUNT_CHANGED`와 기존 최대 체력 이벤트로 갱신합니다. OFF·유닛 해제·API 실패 시 지난 보호막 표시를 숨깁니다.

새 색상 표시와 보호막은 기본 ON이며 모듈 ON일 때 적용합니다. 기존 디버프 아이콘 ON/OFF는 그대로입니다. 정상+5종의 예시와 세션 전용 보호막 비율(0~100%)을 추가했습니다. 기존 전체 배치 미리보기도 같은 효과 설정을 사용합니다. 예시는 실제 유닛과 연결하지 않고 공개된 고정 수치로 그립니다. 아이콘이 커지면 예시 행 간격을 늘립니다.

## 게임 API 경계

애드온에서 실제 오라 목록·오라 슬롯의 상태·비공개 디버프 종류를 읽거나 조건 비교하지 않습니다. 공개 설정을 게임 `CustomAuraContainerTemplate`의 한 `HARMFUL` 슬롯에 등록하고, 게임의 dispel 필터·우선순위·RGBA 색상 곡선 평가로 표시합니다. 등록 후 제한될 수 있는 슬롯/그림의 상태를 다시 읽거나 수정하지 않습니다. 공개 색상 곡선 객체를 유지하며 팔레트·프로필 변경을 반영합니다. 아이콘용 기본 템플릿도 PartyFrames 소유 XML로 제공해 UnitFrames 설치 여부에 의존하지 않습니다.

보호막/최대 체력의 값은 산술·비교·문자열 변환 없이 C StatusBar에 직접 전달합니다. 전투 중 설정 적용은 기존 보류 경로를 사용합니다. 상시 OnUpdate, 전투 기록 추론, 주문 ID 목록에 의한 출혈 추정, 기본 프레임 스크립트 교체는 추가하지 않았습니다. 지원 API가 없거나 초기화에 실패하면 해당 기능을 비활성화하고 설정에 이유를 표시합니다. 원래 플레이어 체력/헤더 수정과 미니맵 엔진은 유지합니다.

다음 게임 소스/API 자료를 확인했습니다. 소스 열람과 모의 환경은 현재 사용자 클라이언트에서의 실행 검증을 대신하지 않습니다.

- [CustomAuraContainer의 슬롯·필터·초기화](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_AuraContainer/Blizzard_CustomAuraContainer.lua)
- [CustomAuraButton의 종류별 그림과 RGBA 적용](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_AuraContainer/Blizzard_CustomAuraButton.lua)
- [AuraContainer의 기본 우선순위와 접근 제한](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_AuraContainer/Blizzard_AuraContainerShared.lua)
- [ColorCurve API](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/LuaColorCurveObjectAPIDocumentation.lua)
- [게임 기본 공격대 보호막 리소스 사용](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_UnitFrame/Shared/CompactUnitFrame.lua)
- [Plater 작성자의 dispel 색상 곡선 사용 예](https://github.com/Tercioo/Plater-Nameplates/blob/master/Plater_Auras.lua): Magic=1, Curse=2, Disease=3, Poison=4, Bleed=11 교차 확인. 외부 실행 코드는 복사하지 않았습니다.

## 검사 결과

| 검사 | 통과 |
|---|---|
| regression | 256/256 |
| targeted | 18/18 |
| party-shared | 24/24 |
| login | 26/26 |
| visibility | 16/16 |
| migration | 12/12 |
| stacking | 8/8 |
| free-drag | 20/20 |
| relogin | 19/19 |
| health-layout | 14/14 |
| header | 6/6 |
| effects | 37/37 |
| 합계 | **456/456** |

신규 37개는 정확한 5색·해제 후 복원, 복합 디버프 단일 슬롯, 투명도 0/팔레트 수정, 보호막 텍스처·양/최대 체력 이벤트·0/초과 값·불투명 패킷 전달·OFF·실패 처리, 45개 유닛 분리, 유닛 교체·숨김·늦은 생성, 지원 API 부재, 전투 보류, 프로필 복사·캐릭터 공유·실제 표시 전환, 4개 탭·2열/1열 배치, 색상 팝업 취소, 고정 예시·기존 미리보기, 출처/템플릿 독립성을 검사합니다. 모의 제한 슬롯 접근과 직접 오라 조회는 오류로 처리했습니다.

기존 419개는 전체/부분 설치, 프로필·검색·잠금, 미니맵 자유 드래그/보관함/이전 설정, 로그인·재접속·단일 기능, 개인 프레임·헤더 및 파티 공유를 포함합니다. 기존 실패 재현 3건은 비교용 이전 코드의 예상 실패이며 통과 456개에 포함하지 않았습니다. 시험용 프레임·비공개 값 모사는 실제 클라이언트의 보안/taint나 실제 텍스처 외관을 증명하지 않습니다.

19개 폴더 / 271개 파일 / Lua 193개 / XML 5개 / 미디어 32개 / 고유 저장 변수 11개. 모든 미디어는 1.11.2.5와 동일합니다. 최종 배포 검사는 TOC 버전·경로·의존성, 유일한 저장 소유권, 파일 목록·CRC·바이트, 자산 경로·제외 목록·문서/명세와 이전 ZIP 보존을 확인합니다.

## 정리 유지

다음은 1.11.2.5에서 제외한 목록이며 이번 ZIP에서도 모두 제외합니다. 과거 입력/배포 ZIP과 실제 AddOns/WTF는 변경하지 않았습니다. 실행에 필요한 Bindings.xml·현재 템플릿·출처 기록은 유지합니다.

- `KH_map/KH_map.toc`
- `KH_map/README.md`
- `KHQOL_Map/Theme.lua`
- `KHQOL_Map/Media/Switch.tga`
- `KHQOL/Media/kh-qol-minimap-button.png`
- `KHQOL_Labs/BuffReminder/Media/ForeverBuffReminder-Minimap-BR.png`
- `KHQOL/docs/history/MODULE-CONNECTIONS-1.10.10.md`
- `KHQOL/docs/history/README-1.10.10.md`
- `KHQOL/docs/history/ROADMAP-1.10.10.md`
- `KHQOL/docs/DEPENDENCY-INVENTORY.json`
- `KHQOL/WeaponGuide/INTEGRATION.md`
- `KHQOL_Labs/BuffReminder/KHQOL_INTEGRATION.md`
- `KHQOL_Campfire/Campfire/KHQOL_INTEGRATION.md`
- `KHQOL_Map/REPORT.md`
- `KHQOL_Map/TEST_RESULTS.md`

실게임 검증은 대기입니다. [설치·사용 안내](INSTALL-GUIDE.md)의 실제 보호막 생성/소모, 디버프 변경/해제, 전투 및 캐릭터 전환을 확인해야 합니다.
