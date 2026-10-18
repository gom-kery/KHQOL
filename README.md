# KHQOL 1.11.4.6

기준 1.11.4.5 · 결과 1.11.4.6 · 인터페이스 16001 · 2026-10-18.

하위 설정 탭에 기능 설명을 표시하고 토템 프레임의 위치 기준과 전용 드래그를 개선했습니다. 유닛프레임 → 플레이어 → 토템 프레임에서 **프레임 위치 확인**을 켜고 테두리만 끌어 이동합니다. X·Y는 각각 -3000~3000px, 확장 방향은 왼쪽·오른쪽입니다.

전체 설치 파일: **`KHQOL-1.11.4.6-탭설명-토템위치편집.zip`**. 19개 애드온 폴더 / 논리 모듈 29개 / 271개 파일 / Lua 193개 / XML 5개 / 미디어 32개 / 고유 저장 변수 11개. KH_map과 기존 제외 경로 15개는 포함하지 않습니다. 

## 기능별 폴더

| 폴더 | 포함 기능 | 필수 항목 |

|---|---|---|

| `KHQOL` | 공통 설정·등록·프로필·검색·위치 편집·전투 보류·공용 길 안내·저장 로더·복원 기록 | 항상 설치·활성 |

| `KHQOL_UnitFrames` | 기본 UI·기본창 이동·개인 유닛프레임·시전바 | `KHQOL` |

| `KHQOL_PartyFrames` | 파티·공격대·디버프 색상·보호막·클릭/휠·역할 프로필 | `KHQOL` |

| `KHQOL_Clock` | 시계·정보 표시·알람·타이머·노트 | `KHQOL` |

| `KHQOL_Convenience` | 자동 판매/수리/거절·아이템·대화창 | `KHQOL` |

| `KHQOL_Tooltip` | 툴팁·플레이어 정보·무기 전문가 안내 | `KHQOL` |

| `KHQOL_Range` | 사거리·마우스오버·스킬북 등록 | `KHQOL` |

| `KHQOL_CursorTrail` | 마우스 잔상 | `KHQOL` |

| `KHQOL_ResourceSwing` | 자원·스윙·탄약·콤보 | `KHQOL` |

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

자동·모의 **599/599 PASS**. 이번 변경 전용 20개와 기존 회귀 579개를 포함합니다. 9개 직업의 213개 섹션(일반 제목 43, 아코디언 170), 1,901건의 배치 관찰과 일반 목록 26개 항목을 확인했습니다. 실제 Forever 클라이언트의 재접속·전투·화면 검증은 별도입니다. [변경·검증 보고서](CHANGE-VALIDATION-REPORT.md), [공통 연결](MODULE-CONNECTIONS.md), [출처](ATTRIBUTION.md).
