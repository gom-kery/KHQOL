# KHQOL 1.11.4.13

기준 1.11.4.12 · 인터페이스 16001 · 2026-10-19.

전투 종료 시 불필요한 파티 전체 재적용과 중복 보류 적용을 줄였습니다. 유닛 프레임은 표시 복원과 전체 배치 적용을 구분하고 같은 적용 안의 반복 설정 검사를 줄였습니다. 잡템 자동 판매는 지원되는 클라이언트에서 기본 UI의 일괄 판매를 우선 사용합니다.

전체 설치 ZIP: **`KHQOL-1.11.4.13-전투종료최적화-기본일괄판매.zip`**. 19개 폴더 / 논리 모듈 29개 / 279개 파일 / Lua 201개 / XML 5개 / 미디어 32개 / 저장 변수 11개. KH_map 제외. **WTF·SavedVariables 유지.** [설치·사용 안내](INSTALL-GUIDE.md).

## 기능별 폴더

| 폴더 | 포함 기능 | 필수 항목 |
|---|---|---|
| `KHQOL` | 공통 설정·등록·프로필·검색·위치 편집·전투 보류·공용 길 안내·저장 로더·복원 기록 | 항상 설치·활성 |
| `KHQOL_UnitFrames` | 직업 보조 표시(탄약·영혼의 조각·토템), 기본 UI·기본창 이동·개인 유닛프레임·시전바 | `KHQOL` |
| `KHQOL_PartyFrames` | 파티·공격대·디버프 색상·보호막·클릭/휠·역할 프로필 | `KHQOL` |
| `KHQOL_Clock` | 시계·정보 표시·알람·타이머·노트 | `KHQOL` |
| `KHQOL_Convenience` | 자동 판매/수리/거절·아이템·대화창 | `KHQOL` |
| `KHQOL_Tooltip` | 툴팁·플레이어 정보·무기 전문가 안내 | `KHQOL` |
| `KHQOL_Range` | 사거리·마우스오버·스킬북 등록 | `KHQOL` |
| `KHQOL_CursorTrail` | 마우스 잔상 | `KHQOL` |
| `KHQOL_ResourceSwing` | 자원·스윙·콤보·변신 마나 | `KHQOL` |
| `KHQOL_ExperienceBar` | 경험치·휴식·평판 바 | `KHQOL` |
| `KHQOL_EnvironmentTimer` | 호흡·피로도·죽은척 | `KHQOL` |
| `KHQOL_CombatStatus` | 전투 시작/종료 알림 | `KHQOL` |
| `KHQOL_Threat` | 위협 수치 | `KHQOL` |
| `KHQOL_NPCAlert` | NPC 감지와 등록 목록 | `KHQOL` |
| `KHQOL_PvPAlert` | PvP 경고 | `KHQOL` |
| `KHQOL_Campfire` | 모닥불·야영 효과 알림 | `KHQOL` |
| `KHQOL_QuestNavigator` | 퀘스트 목록·추적·길 안내 | `KHQOL` |
| `KHQOL_Map` | 미니맵 외형·지역명·주변 아이콘·애드온 버튼 정리 | `KHQOL` |
| `KHQOL_Labs` | 버프 리마인더·발동·강조·검사기·성능 모니터 | `KHQOL` |
기반만, 기반+단일 기능, 임의 부분 설치, 전체 설치를 지원합니다. 미설치/비활성 기능은 설정·검색·위치 대상에서 숨깁니다.

## 검증

자동·모의 **781/781 PASS**. 9개 직업·220개 섹션·배치 관찰 1,964건. 작업 호출 수 감소를 검사했으며 실제 게임의 끊김 시간·FPS 향상률은 측정하지 않았습니다. [변경·검증 보고서](CHANGE-VALIDATION-REPORT.md).
