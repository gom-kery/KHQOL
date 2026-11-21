# KHQOL 1.11.9.0 결과 보고서

## 결과와 중요한 지원 범위

KHQOL 1.11.8.24 Full을 조사한 뒤 0~6단계를 순서대로 같은 작업 사본에 누적했고, 7단계에서 통합 검사/문서/설치를 정리했습니다. 결과 버전은 사용자 지정 **1.11.9.0**, 선택 DevTools는 실제 연결 변경 때문에 **0.3.6**입니다. 게임 폴더나 실제 사용자 SavedVariables를 수정하지 않았습니다.

**정적·모의25개 검사 묶음 PASS. 실제 WoW Forever는 NOT TESTED입니다.** 음식은 검증 데이터 부족에 관한 문서의 조건부 허용 범위에 따라 안전한 부분만 구현했습니다. 배포 자동 whitelist는 **0개**, 실제 자동 음식 선택 및 포만감 타이머/획득 성공은 지원 확정이 아닙니다. 수동 지정·음식 분류/가방 상태 확인·명시적 secure 클릭 경로는 구현했습니다. Glow는 없음/자체 Pixel만 제공하며 Action Button/Auto-Cast는 미지원입니다. 레이어는 기존2단계를 유지합니다.

## 기준과 재현 환경

- 입력 Full SHA256: `803be12736700e1bae299062231e4382843ef70fbf152a440369845bcd4d9b8e`.
- 입력 DevTools0.3.5 SHA256: `5e1afca45219438ab63907e9f82871dc9deca1d39e95c650ec9a5702dd031d77`.
- 최초 Full 19개 폴더/416파일/256Lua. 별도 DevTools와 Full 포함본 바이트 일치. `baseline.json`에 TOC/Interface/로드 순서/의존성/SV 선언 원문, `stage-0-fingerprints.json`에 최초 파일 해시 보존. 0단계 코드 무변경 PASS.
- 실행 검사는 Python+lupa Lua5.1 및 명시적인 가상 WoW API 환경입니다. 사용자 이전 캡처의 1.60.1/70959/16001을 이번 실행 빌드 확인으로 간주하지 않습니다.
- API/원본 근거: [Forever API 자료 생성 설명](https://github.com/Atraeau/WoW-Addons/blob/main/docs/README.md), [LibCustomGlow source/readme](https://github.com/Stanzilla/LibCustomGlow), [MIT 라이선스](https://github.com/Stanzilla/LibCustomGlow/blob/master/LICENSE). LibCustomGlow minor25를 조사했지만 새 라이브러리를 배포하지 않습니다. 보관된 Camelot/Mainline native source의 구체 경로·확인 범위와 현재 클라이언트 일치 미확인은 0/6단계 보고서에 기록했습니다. 외부 음식 가이드/접근 실패 URL을 아이템별 검증 원본으로 채택하지 않았습니다.

## 요구사항 추적

|ID|요구|결과·제한|주요 파일|검사|
|---|---|---|---|---|
|UI-01|일반 중복 heading/설명 제거; 실제 목록/경고 유지|구현|SettingsUI.lua|stage1 / regression / sliders|
|UI-02|좌측 두 막대 제거, ±5, 입력/73보존/FitScreen·높이|구현; 실제 배치 미실시|SettingsUI.lua|stage1 / stage7|
|UI-03|현재 프로필 이름 제거·프로필 관리 보존|구현|SettingsUI.lua|stage1 / profile_roundtrip|
|UI-04|기존2값 레이어 좌측 이동·전투/모달 예외|구현; 중간 단계는 근거 없어 추가 안 함|SettingsUI.lua / unchanged WindowLayers.lua|stage1 / analytics / protected-load|
|AL-01|알림 공통 문구·검색/계정 저장/위치 ID|구현|BasicUI/NativeAlerts.lua / SearchIndex.lua|stage1 / compatibility / upgrade24|
|AL-02|도안/loot/upgrade active scale·큐/재사용/복원·roll독립|조건부: 존재/접근 가능한 알려진 pool; 실제 획득 미실시|BasicUI/NativeAlerts.lua|recipe_positions / stage1 / regression|
|FBR-01|Convenience 실제 소유·실험실게이트 제거/부분 설치|구현|Convenience/BuffReminder/* / Labs wiring / Installation / registry|stage2 / compatibility|
|FBR-02|DB/목록/9직업/주술사/profile·명령·ID 연속|구현|Profiles 경로 보존 / adapter / UsageObserve|stage2 / upgrade24 / run|
|FBR-03|Labs ProcAlert 주문 조회 독립|구현|Core SpellDetails.lua / ProcAlert.lua|stage2 Labs-only / without_convenience|
|GL-01|미적용 Pixel/없음·색상·상태/재사용/정지|구현; 실기 선명도 미실시|BuffReminder/Glow.lua / Core/UI/Settings|stage3 / stage7 / existing release-tests|
|GL-02|ActionButton/AutoCast|현재 미지원/선택지 없음: 추가 API 지원 미검증|의존성 미도입|stage0 조사; INGAME NOT TESTED|
|FD-01|기본OFF 수동ID/link/drag·재고/잠금·secure item 클릭|구현; 실제 소비 미실시|BuffReminder/Food.lua / FoodUI.lua / UI.lua|stage4 / stage7|
|FD-02|검증된5% 비창조 자동 후보·선택 우선순위|조건부 구조 구현, 실사용 후보0개/자동선택 미지원|Food.verified 빈 목록|stage4 합성 후보 필터/정렬; 원본 자료 미확보|
|FD-03|실제 섭취→진행/10초≠성공→실제 포만감|조건부 구조 구현, 배포본 음식 대응 미검증으로 실사용 진행 제한|Food/FoodUI|stage4/7 합성 상태검사; 실제효과 NOT TESTED|
|FD-04|구세대/전투/이동/숨김/OFF/프로필 정리·별도 계측|구현|Food/UI / UsageDiagnostics / UsageBridge|stage4 / stage7 / upgrade24|
|RG-01|singleStep1~5·bucket1~10 유지·원 측정 독립|구현|Range Distance/Database|stage5 / original distance-tests|
|RG-02|행0~3·안정ID·입력/색상/정렬·yd고정·원값판정|구현|Range/ColorRanges.lua / Display / Mouseover|stage5 / stage7|
|RG-03|profile transfer/reload/깊은 복사·stale callback/캐시|구현|ColorRanges / ProfileTransfer.lua|stage5 / stage7 / upgrade24|
|UF-01|native/custom/숫자 중복 제거·alpha복원|구현; 실제화면 미실시|UnitFrameDecor.lua / UnitFrames.lua|stage6 / original release-tests|
|UF-02|contextual 진영/PvP 별도 공간·상대배치·전투 보류|구현; 옵션 추가 없음|UnitFrameDecor.lua|stage6 / anchors / locks_guide|
|COMP-01|기존 기능·선택설치·privacy/성능·Frozen ID|정적/모의 PASS; 게임 전체 NOT TESTED|기존 경로+추가 고정 진단|25개 검사 묶음 / integration-tests.json|

## 저장·설치·계측 호환

buffReminder·ForeverBuffReminder·ForeverBuffReminderDB 및 직업별 등록 목록/순서/활성/displayMode를 그대로 사용합니다. SavedVariables 선언은 기존 Core 하나가 소유합니다. 외형/위치는 기존 프로필, 목록은 기존 계정 범위를 유지합니다. 주술사 specials·노트/완료·좌표·Range 개인 기준 주문·기존 모듈 상태를 보존합니다. 실제 .24 TOC에서 만든 비식별 가상 저장 데이터로 새 버전 업그레이드/추가 default/내보내기·가져오기/새 런타임 리로드를 확인했습니다. 새 행은 깊은 복사이며 다른 프로필과 공유하지 않습니다. 사용자 저장 파일은 읽거나 재사용하지 않았습니다.

Core+Convenience는 Labs 없이 FBR를 실행합니다. Convenience가 없으면 메뉴/검색/위치가 제거되고 ProcAlert는 Core helper로 독립 조회합니다. 신/구 파일이 남아도 새 TOC에 중복 FBR 경로는 없으며 최종 설치 ZIP에는 옮긴 새 파일만 있습니다. DevTools OFF/없음, Labs 없음/재잠금, Convenience 없음, UnitFrames 없음, Labs-only 조합을 모의 검사했습니다.

기존 고정 등록 행1,643개를 field별 비교해 보존했습니다. 새 설정18개와 음식 feature3개만 추가했고 schema1/protocol1을 유지합니다. 버프 방문은 역사적 menu.labs.buff로 alias합니다. UI refresh·애니메이션·시험 표시·색상 취소는 사용/성공으로 세지 않습니다. 새 색상 이름/입력/아이템 링크/좌표를 진단 payload로 전달하지 않습니다. 설정+음식 단계의 실제 DevTools 카운터/내보내기까지 모의 검사했습니다. 이름은 지역 상태에만 있고 export에는 없음을 확인했습니다.

새 영구 ticker/상시 aura·bag poll은 없습니다. Pixel은 표시 중인 icon만 updater를 갖고 음식 진행은 검증 데이터가 있을 때 활성 한 건만 그립니다. 숨김/OFF/전환에서 정지합니다. 가방 조회는 기능 enabled 이벤트를 합쳐 OOC에서만 합니다. 보호/secret/읽기 실패는 기존 public wrapper와 보류/UNKNOWN을 사용합니다. 이 코드/모의 결과는 실제 idle CPU/taint 검사 대용이 아닙니다.

## 검사 결과와 과장하지 않은 범위

`integration-tests.json`의25개 묶음이 모두 PASS입니다. 기존 회귀712개, 전문기술/Note 입력·좌표 정책·네 휠 조합·세션 잠금·슬라이더·위치 편집·유닛/파티·도안 앵커·기존 Usage 업그레이드 검사를 포함합니다. 각 JSON의 checks는 해당 묶음 안의 assertion 수이며 일부 묶음은 공통 fixture를 재실행하므로 서로 더해 고유 기능 수로 해석하지 않습니다.

이번 통합 검증에서 좌측 조작부 재연결, 동적 색상 행의 개별 getter 문맥, 음식 feature bridge phase, 지연 입력 취소, 재사용된 음식 아이콘의 진행 소유권/종료 updater를 보완했습니다. 최종 소스로 관련 검사와 전체 회귀를 통과했습니다. `test-runs/*.log`, 각 `*-results.json`, 합성 upgrade fixture가 검토 ZIP에 있습니다.

실제 배너 획득/품질/대기 큐·쌓임·클릭, 실제 아이템 소비·435/1249519/포만감시간, Frame strata·최소 크기·새 행 가독성·아이콘 간격, 전투 보호/secret/taint, 실제 프로필 저장/로그아웃/리로드는 **NOT TESTED**입니다. `INGAME-CHECKLIST.md`의25개 확인 동작을 분리했습니다. 실제 게임 관측이 없으므로 이 항목에 PASS를 부여하지 않았습니다.

## 사용 및 제출물

게임 종료 후 최종 Full의19개 애드온 폴더를 Interface/AddOns 바로 아래에 교체합니다. WTF/SavedVariables는 유지합니다. FBR에는 Convenience를 켜고, DevTools는 선택적으로 켭니다. Review ZIP은 설치하지 않으며 단계별 ZIP을 섞지 않습니다. 최종 Full 한 개만 설치합니다. 자세한 조작은 설치본 README/INSTALL-GUIDE/RELEASE-1.11.9.0과 아래 단계 보고서를 봅니다.

Full/별도 DevTools SHA256·폴더 목록·변경 파일은 CHECKSUMS.txt / release-manifest.json에 기록합니다. Full에는 개발 fixture·Python 도구·개인 SavedVariables·sources가 없고 기존 정식 문서/라이선스는 보존합니다. 새 외부 라이브러리 의존성은 없습니다. Review에는 0~6단계 ZIP/해시/인계, 최종 소스·검사·보고서·재현용 기준 자료가 들어 있습니다.

최종 Full의 신규 코드8개: Core SpellDetails, Convenience FBR adapter/positions/search/glow/food/foodUI, Range ColorRanges (기존 FBR Core/UI/Settings는 이동 및 수정). 실제 누적 수정/삭제/추가 파일 전체는 manifest로 확인합니다. 단계별 문서는 당시 결과이며, 최종 변경과 검사값은 이 보고서와 최종 manifest가 우선합니다.
