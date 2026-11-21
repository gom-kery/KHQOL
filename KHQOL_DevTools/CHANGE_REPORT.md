# Phase 1-2 / 1-3 변경·배포 보고

출력: **KHQOL 1.11.8.14 Full / DevTools 0.3.0 / Usage 0.1 / schema 1 / catalog revision 2 / protocol 1**.

## 기준 조사

입력 Full 1.11.8.13 SHA-256: `fc0f3b3bef526477c0a295b689b823e3a528721dc10668eb764e365d0a760168`.
비교 DevTools 0.1.5 SHA-256: `9abc90539c921c3b91efe5aa601e0faf619439c452a6e332a831a5f1746fd4c0`.
설치 G:의 KHQOL은 Full .13과 파일 내용이 같고, DevTools는 직전 결과 0.2.0/schema 1과 같았습니다. 오래된 C: 개발 checkout은 기준으로 사용하지 않았습니다. 기준 파일과 설치 폴더는 읽기 전용 조사만 했습니다. 원래 ZIP·sources·사용자 설정·실제 설치를 교체하지 않았고 Commit/Push도 하지 않았습니다.

DIRECT 재사용이 가능한 메뉴·체류·실제 창 전환은 유지했습니다. 공통 입력의 확정/취소·최종 위치 지역변수·기능 실행 원인은 post hook만으로 확정하기 어려워 승인된 최소 진단을 연결했습니다. 원래 게임 보호 동작을 바꾸지 않습니다. 별도 승인 대기 조건은 남기지 않았습니다.

## 결과·제한

총 921개 카탈로그 ID, 748개 공통 바인딩 행. 제외 행 46개. schema 1 선택 필드 routes/reasons 추가, 기존 ID·숫자·과거 버전·ON 상태 보존 검사를 통과했습니다. 과거 날짜에 새 관찰 범위를 소급하지 않습니다. 기존 first/lastDate 자정 역행만 실제 저장 날짜 범위에 맞춥니다.

정적·모의 **LIMITED GO**, 실제 게임 **NOT TESTED**. 공개 getter 없는 위치 writer, 기본 퀘스트 로그·다른 애드온 수동 선택, 서버 수신/수리 완료, native 판매에서 동시 사용자 판매 배제, 게임 비활성 시간은 제한입니다. 등록 목록 초안과 개인정보 필드는 일반 설정 계측에서 제외했습니다. 오래된 합계용 color/text ID는 HOLD이고 개별 설정 ID를 사용합니다.

기록 OFF에서도 보고된 마법책·접속 종료 차단에 대응해 **Blizzard 공용 확인창 목록 재대입/등록을 제거**하고 DevTools 전용 확인창으로 교체했습니다. 추가로 초기 Usage 생성 지연, Blizzard 로딩 재연결 배제, Console 화면 지연·격리, 자동 DebugTools 의존 제거를 반영했습니다. **위험 코드 제거는 확인했으나 게임 내 해결 확인은 하지 못했습니다. 두 재현 체크 전 일반 배포 HOLD**입니다. 구체 재현/후속 기록은 PROTECTED_ACTIONS.md에 있습니다.

## 수정한 KHQOL 파일

| 파일 | 필요성 |
|---|---|
| KHQOL/Bootstrap.lua | KHQOL.VERSION 1.11.8.14 |
| KHQOL/Core.lua | 기존 편집 종료의 navigation 사유 |
| KHQOL/Diagnostics/UsageControlIDs.lua | 동일한 고정 설정 ID/정적 문맥 허용 목록. 값·이름으로 ID 생성하지 않음 |
| KHQOL/Diagnostics/UsageDiagnostics.lua | 작은 protocol 1, 구독자 부재 즉시 반환·값 임시 비교·오류 격리 |
| KHQOL/KHQOL.toc | Full 버전 1.11.8.14; core TOC에 진단 로드 순서 추가 |
| KHQOL/Modules/LabLock.lua | 기존 편집 종료 navigation 사유 |
| KHQOL/PositionEditor.lua | 원래 최종 저장/취소 판단과 writer/apply 결과 |
| KHQOL/PositionTargets.lua | 소유 위치 읽기·reset 문맥, 좌표 외부 전달 없음 |
| KHQOL/SettingsUI.lua | 일반/헤더 모듈 토글의 명시 ID |
| KHQOL/UI/SettingsNavigation.lua | 소유 getter와 고정 경로의 진단 바인딩 |
| KHQOL/UI.lua | 기존 공통 입력 commit/확정/취소 지점에 진단 |
| KHQOL_Campfire/Campfire/Core.lua | 실제 live 탐지 원인과 테스트/초기화 구분, 버전 갱신 |
| KHQOL_Campfire/KHQOL_Campfire.toc | Full 버전 표기 1.11.8.14 |
| KHQOL_Clock/KHQOL_Clock.toc | Full 버전 표기 1.11.8.14 |
| KHQOL_CombatStatus/KHQOL_CombatStatus.toc | Full 버전 표기 1.11.8.14 |
| KHQOL_Convenience/GeneralOptions.lua | 수리 API 요청, 판매 처리 증거·티켓 세대 |
| KHQOL_Convenience/KHQOL_Convenience.toc | Full 버전 표기 1.11.8.14 |
| KHQOL_Convenience/Modules/BuffThanks.lua | 감사 클릭·초안·API 요청 단계 분리 |
| KHQOL_Convenience/Modules/PartyButton.lua | 파티 기능·채팅 요청·초안 단계 분리 |
| KHQOL_CursorTrail/KHQOL_CursorTrail.toc | Full 버전 표기 1.11.8.14 |
| KHQOL_EnvironmentTimer/KHQOL_EnvironmentTimer.toc | Full 버전 표기 1.11.8.14 |
| KHQOL_ExperienceBar/KHQOL_ExperienceBar.toc | Full 버전 표기 1.11.8.14 |
| KHQOL_Labs/KHQOL_Labs.toc | Full 버전 표기 1.11.8.14 |
| KHQOL_Labs/Modules/ProcAlert.lua | 실제 신규 알림과 테스트/재적용/편집 표시 구분 |
| KHQOL_Map/KHQOL_Map.toc | Full 버전 표기 1.11.8.14 |
| KHQOL_NPCAlert/KHQOL_NPCAlert.toc | Full 버전 표기 1.11.8.14 |
| KHQOL_PvPAlert/KHQOL_PvPAlert.toc | Full 버전 표기 1.11.8.14 |
| KHQOL_QuestNavigator/KHQOL_QuestNavigator.toc | Full 버전 표기 1.11.8.14 |
| KHQOL_QuestNavigator/QuestNavigator/Tracker.lua | 명시적 수동 목표 선택 뒤 실제 추적 변경 확인 |
| KHQOL_Range/KHQOL_Range.toc | Full 버전 표기 1.11.8.14 |
| KHQOL_ResourceSwing/KHQOL_ResourceSwing.toc | Full 버전 표기 1.11.8.14 |
| KHQOL_Threat/KHQOL_Threat.toc | Full 버전 표기 1.11.8.14 |
| KHQOL_Tooltip/KHQOL_Tooltip.toc | Full 버전 표기 1.11.8.14 |
| KHQOL_UnitFrames/KHQOL_UnitFrames.toc | Full 버전 표기 1.11.8.14 |

## DevTools 파일

| 파일 | 변경 |
|---|---|
| KHQOL_DevTools.lua / .toc | 버전·의존·Usage 지연 생성·Console 콜백/차단 진단. 기존 도구 유지 |
| UsageControlIDs.lua | core와 같은 고정 ID 표 |
| UsageCatalog.lua | 연결 정의·새 고정 지표·구버전 fallback·방식/검증 분리 |
| UsageCore.lua | BRIDGE 허용·선택 경로·routes/reasons·저장/기간·재연결 세대 |
| UsageBridge.lua | 지원 확인·구독/해제·대표 경로·기존 컨트롤 등록 |
| UsageObserve.lua | 기존 DIRECT 경로의 BRIDGE 중복 방지·관찰 유지 |
| UsageUI.lua | 연결/현재 버전/관찰 범위/판정·NOT TESTED 표시·지연 생성 |
| README/CHANGELOG/INSTRUMENTATION/SCHEMA/BRIDGE_PROPOSALS/VERIFICATION_USAGE/PROTECTED_ACTIONS/OBSERVATION_14_DAYS/CHANGE_REPORT/example JSON | 새 범위·운영·검증 문서 |

Bindings.xml, POSITION_DIAGNOSTICS.md, VALIDATION.md, README-v0.1.5.md는 이전과 byte 동일하게 보존합니다. Full의 다른 파일은 변경하지 않습니다. 패키지 해시·차이·원본 보존 확인은 RELEASE-CHECKS.json과 review의 changed-files.json/change.patch/MANIFEST.sha256을 봅니다.

검증 결과는 VERIFICATION_USAGE.md, 저장 계약은 SCHEMA.md, 14일 플레이 절차는 OBSERVATION_14_DAYS.md를 참조합니다. 실제 게임 체크를 통과한 뒤에만 배포 판정을 올립니다.
