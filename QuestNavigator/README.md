# KHQOL 1.9.3 — 추적 퀘스트 후보 제한 / 완료 후 동작 선택

2026-10-07 · Quest Navigator v0.2.0

기준본은 사용자 제공 **KHQOL-1.9.2.zip**입니다. 기존 기능·미디어·저장 설정을 유지하고 요청한 후보 필터와 완료 이후 처리만 개선했습니다.

**정적·모의 검증: PASS. 인게임 검증: NEEDS TEST.** 실제 WoW Forever를 실행하지 않았습니다. 공개 Forever UI/API 소스에서 함수·이벤트와 사용 방식을 확인했으며, 실제 클라이언트에서의 응답과 반납 좌표 정확성은 설치 후 확인해야 합니다.

## 1. 수정 파일

| 파일 | 변경 |
| --- | --- |
| Bootstrap.lua, KHQOL.toc | 표시 버전 1.9.3 |
| Core.lua | `/khqol quest status`와 debug 명령 전달 |
| SettingsUI.lua | Quest Navigator 페이지 설명 갱신 |
| QuestNavigator/Core.lua | 완료 동작 기본값·이전 정책, 이벤트 처리, 진단 |
| QuestNavigator/Tracker.lua | 추적 집합, 후보 필터, 실제 완료 상태, 반납 안내·반납 후 전환 |
| QuestNavigator/UI.lua | 반납 위치 없음/안내 불가 표시와 실제 반납 후 완료 표시 |
| QuestNavigator/Settings.lua | 자동 선택 체크박스 명칭, 완료 후 동작 단일 선택 |
| QuestNavigator/README.md, README.md, CHANGELOG.md | 이번 변경과 검증 설명 |

QuestNavigator/Arrow.lua의 방향·거리·최단각 보간 코드는 변경하지 않았습니다. 모든 미디어, 다른 기능 모듈, ForeverNote 데이터/미니맵/단축키 파일과 1.9.2의 TOC 바인딩 수정도 보존합니다. 설치 패키지에 테스트 코드나 Lua 런타임은 넣지 않습니다.

## 2. 전체 Quest Log 탐색 변경

기존 GetNumQuestLogEntries → GetInfo 전체 순회를 제거했습니다. 자동 선택은 GetTrackedQuests의 QuestID 집합만 순회합니다. 해당 후보의 레벨 정보가 필요할 때만 GetLogIndexForQuestID → GetInfo로 개별 행을 읽습니다. 추적하지 않은 퀘스트는 로그에 있어도 후보가 되지 않습니다.

후보 조건은 현재 추적 중, 제외 대상 아님, 게임 완료 판정이 false, 퀘스트가 제거된 것으로 확인되지 않음, 유효한 양수 거리와 같은 대륙입니다. 기존 초록(회색 포함) → 노랑 → 주황 → 빨강 → 던전 순위를 유지합니다. 같은 순위에서는 거리, 동률에서는 QuestID를 비교합니다. 같은 지역 우선 옵션은 같은 난이도 순위 안에서 적용합니다.

## 3. Tracked Quest 감지

C_QuestLog.GetNumQuestWatches / GetQuestIDForQuestWatchIndex를 사용합니다. 지원되는 경우 GetNumWorldQuestWatches / GetQuestIDForWorldQuestWatchIndex도 합칩니다. 중복 ID는 제거하고 잘못된/보호된 값은 버립니다. 관련 API를 사용할 수 없으면 해당 목록은 비워 두며 전체 로그를 대신 후보로 쓰지 않습니다.

QUEST_WATCH_LIST_CHANGED의 questID/added를 동기적으로 반영합니다. 추적 해제는 이벤트 처리 즉시 집합에서 제거합니다. 이벤트가 API 목록보다 먼저 도착하면 임시 보정값을 적용하고, 목록에 반영되면 보정값을 제거합니다. 추가/해제 때 `/reload`나 다음 완료를 기다릴 필요가 없습니다. 로그인/재활성화, 지역 변경, 주요 퀘스트 이벤트와 자동 선택 직전에 재동기화합니다.

## 4. ReadyForTurnIn 판정

IsQuestReadyForTurnIn으로 C_QuestLog.ReadyForTurnIn을 우선 호출합니다. false도 유효한 게임 판정이며 IsComplete의 true로 덮어쓰지 않습니다. 함수 부재, 오류, nil 또는 읽을 수 없는 값이면 C_QuestLog.IsComplete를 호환 폴백으로 사용합니다. 두 경로 모두 알 수 없으면 완료 상태를 추측하지 않습니다.

진행 숫자와 목표 텍스트는 화면 표시용입니다. 5/5, 1/1이나 목표 문구를 합산·해석해 완료를 판정하지 않습니다. 숫자 목표가 없는 이동/대화/이벤트 퀘스트도 게임 판정을 사용합니다.

## 5. 반납 위치 획득과 위치 실패

반납 가능 상태에서 위치를 새로 조회합니다: GetNextWaypoint → 현재 지도에 대한 GetNextWaypointForMap → GetQuestsOnMap의 동일 QuestID 마크 순서입니다. 지도 ID와 좌표의 타입·범위·보호 값, 퀘스트 ID 및 지도 안내용 마크 여부를 검사합니다. 게임 기본 지도 역시 이 경로/마크 데이터를 사용합니다. 이는 게임이 현재 완료 퀘스트에 제공하는 위치이며 자체 NPC 데이터베이스로 확정한 좌표가 아닙니다.

이전 Objective 위치를 반납 목표로 복사하지 않습니다. 새 응답이 직전 목표와 완전히 같아 구분할 수 없으면 그 응답을 거부하고 다음 위치 경로를 시도합니다. 따라서 목표 수행과 반납이 실제로 같은 곳인 퀘스트도 보수적으로 `반납 위치 없음`이 표시될 수 있습니다. 직전 목표 좌표는 이 비교·진단에만 사용하며 안내에 재사용하지 않습니다.

반납 위치를 얻지 못하면 화살표를 숨기고 `반납 위치 없음`을 표시합니다. 다른 지도이거나 현재 위치/방향/지도 크기를 확인할 수 없으면 `반납 위치 안내 불가`입니다. 누락 좌표에 (0,0)을 넣거나 지도 ID를 임의로 보충하지 않습니다. 지도 이벤트에서 유효한 위치가 도착하면 기존 갱신 주기로 복구합니다.

## 6. 완료 후 동작 옵션

`/kh quest` → 추적:

- **자동 퀘스트 선택**: 기존 autoTrack 설정을 유지합니다. OFF이면 완료·실제 반납 후 자동 후보 선택을 하지 않고 수동 안내만 유지합니다.
- **퀘스트 완료 후**: 공통 Dropdown의 단일 선택(라디오 표시)으로 `반납 위치 안내` / `다음 추적 퀘스트 자동 선택` 중 선택합니다.

turnin: 완료 직후 현재 선택을 유지하고 반납 위치를 안내합니다. 실제 QUEST_TURNED_IN을 받으면 선택/좌표/거리/회전/목표 캐시를 제거한 후, 자동 선택 ON일 때 다른 추적 중인 미완료 후보를 선택합니다.

next: 진행 중인 현재 퀘스트가 완료되면 기존 짧은 완료 표시/페이드 후 다음 추적 후보로 전환합니다. 완료 퀘스트를 직접 선택하거나 /reload 때 완료 퀘스트가 이미 선택돼 있었다면, 자동 전환 대신 해당 퀘스트 반납 안내를 유지합니다. 완료 전환 도중 다른 퀘스트나 사용자 핀을 선택해도 사용자 선택을 우선합니다. 퀘스트 포기는 실제 반납으로 취급하지 않습니다. 중복 반납 이벤트도 다음 선택을 중복 실행하지 않습니다.

## 7. SavedVariables와 Migration

KHQOLDB.modules.questNavigator에 `completionBehavior = "turnin" | "next"` 하나만 추가했습니다. 기존 autoTrack, 위치, 거리 단위, 화살표와 모든 다른 옵션을 보존합니다. SavedVariables 선언은 변경하지 않았습니다.

- 새 DB 또는 기존 DB에 autoTrack 명시값이 없으면 **turnin**.
- 기존 DB가 autoTrack=true를 저장하고 완료 동작이 없으면 **next**로 이전하여 기존 자동 전환 UX 유지.
- 기존 autoTrack=false는 OFF를 유지하고 완료 동작은 turnin.
- 이미 turnin/next가 있으면 유지하며, 잘못된 값은 turnin으로 복원.

기존 사용자는 적용 후에도 자동 전환 모드일 수 있습니다. 반납 안내를 원하면 위 옵션을 한 번 변경하면 됩니다. 설정은 기존 저장 구조에 즉시 반영되며 재접속/재활성화 때 유지됩니다.

## 8. CPU 관련 변경

후보 탐색은 전체 로그 N개 대신 추적 목록 K개를 검사합니다. 25개 로그/3개 추적의 모의 검사에서는 추적 ID 3개만 열거하고, 현재 완료 대상을 제외한 후보 2개의 거리·개별 정보만 검사했습니다. 전체 로그 탐색은 0회입니다. 같은 지역 옵션의 지도 마크 조회도 탐색당 한 번 읽어 임시 조회표로 사용합니다.

평상시 OnUpdate에서 추적 목록/퀘스트 로그/완료 상태/던전·난이도 정보를 조회하지 않습니다. 기존 0.10초 화살표, 0.25초 거리, 0.10초 이벤트 합치기를 유지하며 새 타이머를 추가하지 않았습니다. 지도/퀘스트 이벤트가 몰릴 때도 화살표 회전은 기존 주기를 유지합니다. OFF는 이벤트와 OnUpdate를 해제합니다. 실게임 FPS/CPU 수치 개선은 측정하지 않았습니다.

## 9. Debug

`/khqol quest status` 또는 `/kh quest debug`에서 선택 QuestID, 현재 추적 ID, 각 ReadyForTurnIn YES/NO/UNKNOWN, 완료 동작, 자동 선택 ON/OFF, Navigation Mode, 위치 확인 이유, 자동 후보 ID와 유효한 대상 지도/좌표를 출력합니다. 인수가 없는 `/kh quest`는 기존 설정창을 엽니다.

GetDebugSnapshot에는 기존 방향·거리와 함께 trackedQuestIDs 복사본, trackedReadyForTurnIn, autoCandidates, completionBehavior, navigationMode, manualTurnIn, objectiveMapID/X/Y, turnInMapID/X/Y를 제공합니다. 출력 요청 때만 진단 조회·정렬을 하며 자동 운영 중 채팅을 출력하지 않습니다. 가짜 퀘스트 생성/상태 변경 기능은 추가하지 않았습니다.

## 10. 정적·모의 검증

**PASS: 108/108**. 기존 화살표 방향/캐릭터 회전/보간/투영/입체 옆면/거리 단위/진행도와 난이도 우선순위 검사, 추적 후보 제한/즉시 추적 해제/실제 완료 판정/두 완료 모드/수동 선택/데이터 지연·오류·보호 값/반납·포기·중복 이벤트/저장 정책/OFF와 주기 유지 검사를 포함합니다. 전체 **55개 Lua 5.1 문법**, TOC 참조 경로도 PASS입니다.

최신 공통 설정 UI에서 13개 모듈 메뉴·일반 탭 간격·토글·저장값, Quest Navigator 완료 모드 선택·OFF 제어·스크롤·컨트롤 겹침·영역 재사용 검사가 PASS입니다. 배포 ZIP은 원본 파일 목록, 허용 변경 파일, 다른 모듈/미디어와 Arrow.lua 바이트 보존, SavedVariables/TOC 등록 및 압축 무결성을 확인합니다.

## 11. 인게임 체크리스트 — NEEDS TEST

1. 로그 A/B/C/D와 추적 A/B를 준비해 자동 후보가 A/B뿐인지 status로 확인.
2. B 추적 해제 직후 후보에서 빠지는지, 추가하면 다시 들어오는지 확인.
3. 진행 중 A의 기존 목표 방향·거리·진행도와 캐릭터 회전 반응 확인.
4. turnin 모드에서 A 완료 후 선택을 유지하고 반납 NPC 쪽으로 안내하는지 확인.
5. next 모드에서 A 완료 후 추적 중인 미완료 B/C만 난이도·거리 순으로 선택하는지 확인.
6. next 모드에서 완료 A를 직접 선택하면 반납 안내를 유지하는지 확인.
7. 숫자 목표 없는 이동/대화형 퀘스트의 실제 완료 판정 확인.
8. 반납 위치 미제공/이전 목표와 같은 좌표/다른 지도에서 잘못된 화살표가 없는지 확인.
9. A 실제 반납 후 A 선택/좌표 제거와 다음 추적 후보 전환, 포기 시 비전환 확인.
10. 추적 퀘스트가 없으면 자동 선택이 없고 안내가 비는지 확인. 명시적 수동 선택 안내는 별도로 유지합니다.
11. 완료 동작 변경 후 /reload, 위치/단위/다른 설정 보존 및 기존 autoTrack 이전 정책 확인.
12. 로그 20개 이상/추적 3개에서 후보가 3개로 제한되는지, 다른 모듈과 ForeverNote 단축키가 정상인지 확인.

확인한 공개 소스:

- [Forever 퀘스트 API·이벤트](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua)
- [게임 지도 경로/퀘스트 마크 사용](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedMapDataProviders/QuestDataProvider.lua)
- [게임의 완료 퀘스트 마크 구분](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_POIButton/POIButtonUtil.lua)
