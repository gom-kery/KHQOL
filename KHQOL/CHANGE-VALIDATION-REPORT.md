# KHQOL 1.11.6.0 최종 코드 감사·리팩토링 보고서

기준 **KHQOL-1.11.5.11-경로그리기.zip** → **KHQOL-1.11.6.0-최종안정화.zip** · 2026-10-21.

입력 SHA-256: `b82b4898a04da5a3d965b9dcaaf9cb429e77e320f81e8101bbd56032606cfe29`. 기존 배포 ZIP·실제 AddOns/WTF·GitHub는 변경하지 않았습니다. 직접 요청한 두 도구 제거·점선 설정 추가를 적용하고, 감사에서는 재현한 세 문제만 보수적으로 수정했습니다.

## A. 조사 방법과 전체 구조

**조사 → 위험 평가 → 수정 → 검증** 순서로 진행했습니다. 수정 전에 원본 ZIP 해시, 209개 Lua/32,225줄, TOC/XML 역참조·저장 변수·모듈/함수/갱신/이벤트/생성 지점과 중복 후보를 기록했습니다. 모든 소스 파일의 정적 조사에 모듈 어댑터·초기화/종료·고빈도 실행·프로필/지도/보호 프레임 경로 수동 검토와 실행 회귀를 결합했습니다. 형식 검사는 줄 단위 무결점 증명이 아니며 실제 게임 실행은 별도입니다.

결과는 **19개 폴더 · 논리 모듈 27개 · 287파일 · Lua 207개 · XML 6개 · 미디어 32개 · 저장 변수 11개**입니다. 제거한 두 도구를 제외한 기능 모듈과 자원은 유지했습니다. 소스 Lua는 207개/31,657줄입니다. 신규 Lua·모듈·외부 라이브러리는 없습니다.

- 18개 기능 애드온은 KHQOL 코어를 필수 의존성으로 사용합니다. 기존 OptionalDeps와 파일 순서는 유지하고 Labs TOC에서 삭제 파일 두 개만 제외합니다. 전체 순서는 `docs/MODULE-FILES.csv`와 패키지 명세에 있습니다.
- 코어 Bootstrap/ModuleRegistry/Installation이 모듈 소유권을 연결합니다. VARIABLES_LOADED와 PLAYER_LOGIN의 준비/초기화 가드, 의존성 검증, 어댑터 적용·프로필 로그인 마무리를 유지했습니다.
- 런타임 의존성은 기존 todo→clock, unitFrames→basicUI, generalConvenience→general 등을 유지합니다. owner/always 등록도 포함해 논리 모듈 27개입니다.
- 공통 MergeDefaults·ReadPublicAPI/PublicCall·ModuleRegistry·PositionStore·UI builder·Navigation을 재사용합니다. 레거시 저장소의 서로 다른 병합/콘텐츠 정책은 합치지 않았습니다.
- 전투 중 보호 작업은 기존 최신 요청 큐·프로필 세대/소유자 epoch 검증을 사용합니다. 캐시·타이머는 모듈별로 기존 소유/해제 정책을 유지합니다.

### 실제 등록 모듈과 검증 근거

아래 모든 ID에 대해 새 전체 설치 모의 런타임에서 ON/OFF·반복 재적용·초기화 가드·주요 프레임 동일성·프로필 캡처를 실행했습니다. 실제 지원 API에 따른 ready/unsupported 분기는 유지하며, 모의 성공을 실제 게임 기능 성공으로 표기하지 않습니다.

| 모듈 ID | 소유 애드온 | 실제 코드의 기능/생명주기 확인점 |
| --- | --- | --- |
| basicUI | KHQOL_UnitFrames | 기본 UI 조정·보호 작업 지연 |
| buffReminder | KHQOL_Labs | 버프 등록·이벤트/단발 만료 갱신 |
| campfire | KHQOL_Campfire | 야영 상태·거리/만료 ticker 취소 |
| castBar | KHQOL_UnitFrames | 플레이어/대상 시전바·활성 갱신/종료 |
| chatEnhancement | KHQOL_Convenience | 기본 대화창 편의/초기화 가드 |
| clock | KHQOL_Clock | 시계/날짜/골드/FPS·지연/전문기술·타이머/달력 |
| combatStatus | KHQOL_CombatStatus | 전투 시작/종료 알림·만료 취소 |
| cursorTrail | KHQOL_CursorTrail | 잔상 풀·OFF 시 콜백 중지 |
| environmentTimer | KHQOL_EnvironmentTimer | native 환경 타이머·활성 렌더/종료 |
| experienceBar | KHQOL_ExperienceBar | 경험치 이벤트·합쳐진 갱신 |
| frameMover | KHQOL_UnitFrames | 기존 위치 저장/후크 기반 이동 |
| general | KHQOL_Convenience | 공통 일반 설정/연결 |
| generalConvenience | KHQOL_Convenience | 잡템 일괄 판매·수리·파괴 입력·초대 설정 |
| minimap | KHQOL_Map | native 미니맵/버튼·소유권 복원/편집 가드 |
| npcAlert | KHQOL_NPCAlert | 등록 NPC/알림·숨김/유휴 처리 |
| objectHighlight | KHQOL_Labs | 그래픽 변경 저널·복원/잠금 |
| partyFrames | KHQOL_PartyFrames | 1~40인·역할 프로필·휠/클릭·native 오라 |
| procAlert | KHQOL_Labs | 잠금·직업별 발동 HUD·유휴 갱신 제거 |
| pvpAlert | KHQOL_PvPAlert | 이름표 후보·상태/시전·활성 스캔 |
| questNavigator | KHQOL_QuestNavigator | 퀘스트 선택/추적/공유 화살표·점선 설정 접근점 |
| range | KHQOL_Range | 사거리 주기 갱신·OFF 시 분리/캐시 이벤트 유지 |
| resourceSwing | KHQOL_ResourceSwing | 자원/스윙·콤보/변신 마나·잠금/활성 갱신 |
| threat | KHQOL_Threat | 위협 HUD·조건부 ticker |
| todo | KHQOL_Clock | 노트/체크리스트·좌표·경로 그리기/순차 안내 |
| tooltip | KHQOL_Tooltip | 단위/대상/정보·ID·native 툴팁 콜백 |
| unitFrames | KHQOL_UnitFrames | 5종 유닛·텍스트·native 오라·토템/보조표시 |
| weaponGuide | KHQOL_Tooltip | 기존 툴팁 무기 정보 owner 연결 |

### 중복·미사용·디버그 감사

기준 209개 Lua가 모두 TOC/XML에서 참조됐으며 누락/고아 Lua는 없었습니다. 삭제는 요청된 두 구현과 그 탭·검색·실행/위치/명령 연결로 한정했습니다. 문자열·이벤트·SecureHook·프로필 콜백으로 호출되는 코드를 단순 검색 결과로 제거하지 않았습니다.

12줄 교차 파일 중복 후보는 Labs 발동 목록과 NPC 등록 UI에서 확인했습니다. 공통 builder는 이미 사용하며, 직업별/계정 등록 범위와 유효성 검사·편집/삭제 콜백이 다르므로 추가 통합을 보류했습니다. 서로 다른 자원 수치·캐릭터/프로필 병합·좌표 변환 역시 생명주기 차이를 보존했습니다. 낮은 비용의 어댑터 보조 선언을 스타일 목적으로 대량 정리하지 않았습니다. 사용자 명령 응답과 기존 debug 옵션 뒤의 출력은 유지합니다.

## B. 발견 사항과 위험도 결정

| ID/위험도 | 발견/근거 | 결정 |
| --- | --- | --- |
| REQ-01 | 실험실 검사기·성능 모니터 제거 요청. 탭/검색/어댑터/잠금/위치/페이지 하단 액션과 결합 | 구현 두 파일과 모든 실행/UI 연결 제거. 남은 실험실 및 시계 FPS/지연 유지 |
| REQ-02 | 퀘스트 길 안내에서 기존 노트·저장 경로 점선 전체를 조절할 옵션 요청 | 기존 clock.todo.navigation.pinLines.visible의 UI 진입점 추가. 새 저장 키 없음 |
| P1-01 | NoteMapPins의 모든 CVAR_UPDATE가 좌표 캐시 무효화와 native 지도 갱신을 수행. 음향 설정으로도 재현 | 회전 CVar만 미니맵 갱신. 관련 없는 이벤트는 종료. 지역/지도/전투 경로 유지 |
| P1-02 | 스톱워치 HH:MM:SS를 같은 초에도 매 프레임 Format/SetText. 같은 시각 60회 콜백에서 60회 쓰기 재현 | 표시 초 캐시. 초 경계·리셋에만 문구 갱신. 시간 계산/일시 정지/닫기 반응 유지 |
| P2-01 | HideLegacyButtons가 선택적 Frame 배열을 ipairs 순회해 첫 nil 이후 버튼을 건너뜀. 첫 버튼 없는 구성에서 재현 | 동일한 전역 이름 목록을 순회해 각 존재 여부를 독립 검사 |
| 보류 | 추가 공통 UI/프로필/Navigation/보호 Hook 전면 재구성 | 명확한 필요·실제 클라이언트 검증 없이 변경하지 않음 |
| 보류 | 달력 알림의 60초 확인/세션 중복 알림 기록 정리 | 독립 알림·보존 정책을 바꿀 가능성. 임의 중단/삭제하지 않음 |

이번 정적·모의 범위에서 추가로 재현된 P0 데이터 손실·초기화 오류는 없었습니다. 서버 보호값·실제 전투 taint와 API 적합성은 인게임 미검증 항목으로 남깁니다. ‘P0가 전혀 없다’거나 ‘무결점’이라고 판정하지 않습니다.

## C. 변경 파일·함수·이유·영향·검증

| 수정 파일 | 함수/구간 | 기존 문제와 변경 이유 | 변경/예상 영향 | 검증 |
| --- | --- | --- | --- | --- |
| KHQOL_Labs/Modules/FrameInspector.lua, PerformanceMonitor.lua | 구현 전체 | 명시 제거 요청 | 파일·검사/측정/오버레이 실행 제거 | 파일/등록/메뉴/오버레이 부재 검사 |
| KHQOL_Labs/Bootstrap.lua, Adapters.lua, Positions.lua | 모듈 등록·프로필/위치 공급자 | 삭제 구현 참조가 남으면 로딩 오류 | 두 도구 연결 제거. 다른 세 기능 유지 | 전체/부분 설치 및 27개 생명주기 |
| KHQOL_Labs/UI/LabSettings.lua, SearchIndex.lua | 탭/검색 등록 | 제거한 도구 노출 방지 | 해당 탭과 검색만 제거 | 잠금/메뉴/검색 회귀 |
| KHQOL/Installation.lua, Core.lua | 패키지 소유권·기본 enabled 목록 | 제거한 도구가 설치 모듈로 남는 문제 | Labs를 실제 세 기능으로 표시. 과거 DB 값 보관 | 소유권·새/기존 프로필·복원 |
| KHQOL/Modules/LabLock.lua | RefreshRuntime | 삭제한 도구 활성화/정지 참조 | 나머지 잠금/그래픽 복원 경로 유지 | 그래픽 저널·잠금 회귀 |
| KHQOL/SettingsUI.lua | SetPageScrollLayout/SetModuleHeader | 검사기 전용 페이지 액션 참조 | 전용 액션 공간/분기 제거. 나머지 레이아웃의 기존 0 높이 동작 유지 | 전체 설정/아코디언/재오픈 회귀 |
| KHQOL/UI/SettingsRegistry.lua, SettingsGroups.lua, SettingsNavigation.lua | labs 항목·owner·명령/경로·scope | 제거한 도구의 UI 참조 | 해당 연결만 정리 | 등록/검색/명령 검사 |
| KHQOL_QuestNavigator/QuestNavigator/Settings.lua, UI/SearchIndex.lua | BuildSettings/표시 및 검색 | 기존 선 설정의 추가 접근점 필요 | 같은 값을 읽고 갱신. Clock 없는 구성 비활성. 기존 화살표/선택 정책 유지 | 양방향 동기화·선 OFF·프로필·선택 설치 |
| KHQOL_Clock/Clock/NoteMapPins.lua | InstallTodoMapPins 이벤트 콜백 | 관련 없는 CVar에 전체 지도 갱신 | 공개 이름 확인·회전 이름 정규화 후 미니맵만 갱신 | 무관 CVar 50회/회전 이름/secret·nil/전투·지역 |
| KHQOL_Clock/Clock/ClockTools.lua | CreateClockTools 스톱워치 생성/reset/OnUpdate | 동일 초의 중복 문자열/UI 쓰기 | displayedSeconds 캐시. 기존 GetTime 계산과 닫기 기한 유지 | 같은 초·경계·시간·일시 정지·리셋·닫기 |
| KHQOL/Core.lua | HideLegacyButtons | 선택적 배열의 중간 nil | 같은 이름으로 개별 검사, 기존 Hide/OnShow 정책 유지 | 첫/전체 부재·마지막만 존재 |
| 모든 TOC, KHQOL/Bootstrap.lua, KHQOL_Map/Core.lua | 버전/실제 로딩 파일 | 배포 일치 | 1.11.6.0, Labs 삭제 두 파일 제외 | 정확 버전·경로·의존성·CRC/해시 |

변경하지 않은 기능 Lua와 모든 XML·미디어는 입력 ZIP과 바이트 동일합니다. Navigation/NavigationUI, Profiles/ProfileTransfer, 공통 UI.lua, UnitFrames/PartyFrames·캐스트/자원·자동 판매 등 고위험 코어/모듈은 유지합니다. 전체 수정/삭제 목록과 해시는 패키지 명세와 소스 변경 패치에 있습니다.

## D. CPU·메모리·객체 생명주기 감사

- **갱신/이벤트:** 기존 지도 .1초/도착 .5초, 사거리 .08초, 활성 환경/시전/자원·PvP 루프와 전투 큐를 검토했습니다. OFF 또는 유휴 시 중지하는 기존 경로를 유지합니다. Range의 비활성 상태 주문/액션 캐시 이벤트, BuffReminder의 주문 정보 완료 이벤트, 그래픽/보호 프레임 복원 이벤트는 재활성화·등록/복원에 필요하므로 일괄 해제하지 않았습니다.
- **수정한 반복 작업:** 무관 CVar는 노트 전체 지도 갱신을 수행하지 않습니다. 모의 50회 호출에서 좌표 revision·native pin acquire·스냅샷은 유지했습니다. 회전은 미니맵만 갱신하며 지역/전투/지도 수명 이벤트는 기존대로 수행합니다.
- **문구/할당:** 스톱워치 elapsed 계산은 그대로이며, 같은 표시 초에서 반복 Format/SetText를 하지 않습니다. 초 경계와 리셋에 캐시를 맞춥니다. 시간 반응과 닫기 지연을 바꾸지 않았습니다.
- **객체 재사용:** 기존 UI 페이지/목록 캐시, native 핀 풀, 최대 128개 경유지·미니맵 핀/512+512 점선, CursorTrail·알림·유닛 프리뷰 풀을 유지합니다. 제거한 두 도구의 Frame/로그/측정 타이머는 생성되지 않습니다. 신규 타이머/OnUpdate는 없습니다. 추가한 체크박스/도움말은 기존 설정 페이지의 일회 생성/재사용을 따릅니다.
- **정적 지점 수:** 기준 OnUpdate setter 47→43, C_Timer API 105→103입니다. 해제 코드·조건부 호출도 포함한 문자열 지점 수이며 활성 루프 수나 성능 측정값이 아닙니다.
- **잔여/보류:** 보이는 스톱워치의 닫기 호버 타이밍, 독립 달력 알림/세션 중복 방지 기록, native 영구 secure hook의 동작 가드는 유지합니다. 기록 보존·알림 시점·공용 생명주기가 변할 수 있는 추가 정리는 권고로만 남깁니다. 실제 장시간 메모리/CPU·FPS는 측정하지 않았습니다.

**개선율·FPS 증가·실제 CPU/메모리 감소 수치는 주장하지 않습니다.** 확인한 것은 호출/객체/데이터 검사와 코드 경로의 차이입니다.

## E. 데이터 호환성

| 범위 | 실제 저장소/정책 | 결과 |
| --- | --- | --- |
| 계정 | KHQOLDB, ForeverClockDB, ForeverBuffReminderDB, ForeverWeaponGuideDB, KHQOLResourceSwingDB, CampfireAlertDB, KHQOLLabDB | 소유 KHQOL 유지 |
| 캐릭터 | FRangeDB, KHQOLCursorTrailCharDB, KHQOLPartyCharDB | 소유 KHQOL, 캐릭터 범위 유지 |
| 미니맵 | KHQOLMapDB | 소유 KHQOL_Map·기존 설정 유지, KH_map 미포함 |
| 프로필 | 계정 profiles + 캐릭터별 characterProfiles 선택, 기존 profileSchema=1 | 구조/스키마/기본 레시피 변경 없음. 제거 도구의 기본 등록만 제외 |
| 사용자 콘텐츠 | 노트/체크리스트/완료·좌표/경로, 클래스별 버프/발동 목록, NPC 목록, 파티 프로필/휠 데이터 등 기존 위치 | 삭제·범위 통합·프로필 콘텐츠화 없음 |
| 점선 값 | ForeverClockDB.todo.navigation.pinLines.visible, 기존 clock 프로필 캡처 | 새 키/마이그레이션 없음. 기존 OFF 유지, 새 기본값 기존 true 유지 |
| 제거한 도구 | 과거 enabled.performanceMonitor / modules.performanceMonitor 등 미설치 모듈 설정 | DB/기존 프로필에서 강제로 지우지 않고 실행만 제거. 새 세션/프로필 저장·복귀로 확인 |
| 프로필 전송 | formatVersion=1, scopeVersion=1과 기존 필터 | 변경 없음. 미설치/제거 모듈의 전송 제한은 기존 필터 정책을 따름 |

초기화/병합/마이그레이션·기본값은 나머지 모듈에서 변경하지 않았습니다. 정상 새 런타임 복원으로 점선 OFF·전체 경로·과거 모니터 설정 보존을 확인했습니다. 실제 WTF 디스크 저장/서버·다른 캐릭터 상황은 인게임 확인이 필요합니다. 실제 AddOns/WTF는 수정하지 않았습니다.

## F. 최종 검증과 완료 범위

자동·모의 **508/508 PASS**: 이번 감사/변경 48개(27개 모듈 생명주기 포함) + 경로 그리기 42개 + 남은 경로 31개 + 플레이어 접근선 24개 + 경로/안내 61개 + 지도/미니맵 46개 + 기존 회귀 256개를 현재 소스에서 실행했습니다. 제거한 성능 모니터의 수치 집계 검사 1개는 도구·메뉴·오버레이 제거 및 시계 정보 보존 검사로 교체했으며, 미재실행 과거 검사는 합산하지 않았습니다.

Lua 207개의 5.1 문법, 19개 TOC/로드 순서/의존성, XML 6개, 저장 변수 11개 소유권, 삭제 파일·비대상 코드·미디어 비교와 ZIP 파일 목록/CRC/해시를 검증합니다. **실제 Forever 실행·렌더링·보호 실행/taint·CPU/FPS·디스크 저장: NOT RUN / 인게임 확인 필요.**

요청된 코드 변경·정적/모의 감사·패키지 생성을 완료했습니다. 확인할 수 없는 서버 보호값/실제 렌더링·전투 taint·거리/달력 API·CPU/FPS는 `ROADMAP.md`에 구체적으로 남겼습니다. 고위험 전면 재구성과 임의 데이터 정리는 적용하지 않았습니다. 전체 ZIP은 KH_map을 제외하고 KHQOL_Map을 제공합니다. 설치/사용법은 INSTALL-GUIDE.md입니다.
