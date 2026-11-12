# KHQOL 1.11.6.3 구현 보고서

기준: 사용자가 제공한 `KHQOL-1.11.6.2.zip` → 결과: **1.11.6.3** · 2026-11-08.

## 1. 전체 구현 요약

**A. 대상·대상의 대상·주시 대상의 플레이어 생명력 채움에 지정된 18개 HEX 색상을 적용하는 공통 옵션을 추가했습니다. B. 완료·미반납 퀘스트 보상 XP를 기존 경험치 바 내부에 표시하는 옵션을 추가했습니다. 두 기능 모두 기본 OFF이며 서로 독립적입니다.**

기존 유닛 프레임과 경험치 바를 확장했습니다. 기존 설정·프로필·색상·위치·크기·수치 표시와 Quest Navigator 동작을 유지합니다. Interface는 16001이며 20개 TOC의 Version을 1.11.6.3으로 통일했습니다. Map/Campfire 내부 표시 버전도 일치시켰습니다.

Lua 구문과 모의 검증은 통과했지만 **실제 Forever 게임 실행·화면·서버 보상·전투/taint 검증은 NOT TESTED**입니다. 두 기능의 최종 판정은 **LIMITED GO**입니다. API 근거는 고정된 Forever UI 소스와 문서이며 실행 중 반환값을 직접 측정했다는 의미가 아닙니다.

안전 때문에 다음 표시 제한이 있습니다.

- XP가 먼저 변해 반납 여부를 구별할 수 없으면 **다음 신뢰 가능한 QUEST_LOG_UPDATE까지 예상 구간을 숨깁니다. 일반 몬스터 XP도 같은 처리를 받으며, 로그 이벤트가 오지 않으면 숨김이 계속될 수 있습니다.** 시간 경과만으로 보상 처리가 끝났다고 판단하지 않습니다.
- 접힌 목록 등으로 노출된 로그 항목이 전체 퀘스트 수보다 적으면 부분 합계를 전체 합계처럼 표시하지 않고 숨깁니다. 퀘스트 선택·추적·헤더 펼치기를 강제로 변경하지 않습니다.
- 필수 API/동기화 이벤트가 없거나 정보가 Secret/불명확하면 해당 미리보기를 보류합니다. 선택된 퀘스트에 의존하는 구형 무인자 API로 우회하지 않습니다.
- 다음 레벨 요구량·다중 레벨 결과를 추정하지 않습니다. 현재 레벨 100%까지의 구간, 총 예상 XP, 현재 레벨 초과 XP와 ‘레벨업 예상’만 제공합니다.

## 2. 기준 작업본 조사와 변경 파일

입력 ZIP은 이전 1.11.6.2 배포본과 바이트가 일치합니다. SHA256: `46c8e4049002749a490739166c40a5be2c506e69c6f39503fb18b3ef9e80ed15`. 기준은 20개 애드온 폴더, 302파일, Lua 215개입니다. 기존 README/DESIGN/프로필/TOC/실제 모듈 구조를 기준으로 수정했습니다.

| 영역 | 기존 구조와 이번 연결 |
| --- | --- |
| 유닛 프레임 | `KHQOL_UnitFrames/Modules/UnitFrames.lua`의 UnitParts/AuxiliaryParts와 기존 Blizzard 프레임을 사용. target/focus는 TargetFrameContentMain.HealthBarsContainer.HealthBar, targettarget은 TargetFrame.totFrame 또는 TargetFrameToT의 HealthBar/healthbar를 기존 탐색 함수로 얻음 |
| 유닛 색상 | `UnitFrameDecor.lua`의 HealthColor → ApplyHealthColor → ApplyBarColor. 기존 기본/관계·직업색/사용자 색과 네이티브 갱신 후 훅·복원 기록을 재사용 |
| 경험치 | `KHQOL_ExperienceBar/Modules/ExperienceBar.lua`의 CreateFrames/ReadData/ApplyLayout/Render/SetSegment. 기존 수평 또는 세로→수평 경로, WHITE8X8 채움, 별도 텍스트층, 휴식 표시를 확장 |
| 현재 XP | 기존 UnitXP/UnitXPMax/UnitLevel과 최대 레벨 판정, 기존 평판 연동 유지 |
| 설정 UI | 기존 공용 Builder, 체크박스/드롭다운/Color, Reflow와 검색 인덱스 사용. 새 상위 메뉴 없음 |
| 프로필 | 기존 ModuleRegistry의 profile=true, defaults 및 KHQOLDB.modules 저장 경로 사용. 프로필 포맷/마이그레이션/선택 캐릭터 저장 구조 변경 없음 |
| 로드 순서 | ExperienceBar.lua 다음에 신규 QuestExperiencePreview.lua, 그 뒤 기존 설정/Adapters 로드. 두 기능 간 의존성 없음 |
| Quest Navigator | 추적 목록·선택·화살표·위치·저장 데이터에 연결하지 않음. TOC 버전 외 모든 파일 바이트 동일 |

아래 목록은 원본과 배포 소스를 비교해 생성했습니다. TOC와 내부 버전만 바뀐 파일도 포함합니다.

| 파일 경로 | 구분 | 수정 내용 |
| --- | --- | --- |
| `KHQOL/Bootstrap.lua` | 공통 | 런타임 버전 1.11.6.3 |
| `KHQOL/CHANGELOG.md` | 공통 | 현재 변경 기록 |
| `KHQOL/DESIGN.md` | 공통 | 새 기능 계약·기존 디자인 보존 |
| `KHQOL/INSTALL-GUIDE.md` | 공통 | 현재 전체 ZIP 설치 안내 |
| `KHQOL/KHQOL.toc` | 공통 | TOC Version 1.11.6.3만 변경 |
| `KHQOL/README.md` | 공통 | 현재 릴리스 안내·제한·검증 |
| `KHQOL/UNIT-XP-1.11.6.3.md` | 공통 | 신규 상세 보고서·인게임 체크리스트 |
| `KHQOL_Campfire/Campfire/Core.lua` | 공통 | 내부 표시 버전 1.11.6.3만 변경 |
| `KHQOL_Campfire/KHQOL_Campfire.toc` | 공통 | TOC Version 1.11.6.3만 변경 |
| `KHQOL_Clock/KHQOL_Clock.toc` | 공통 | TOC Version 1.11.6.3만 변경 |
| `KHQOL_CombatStatus/KHQOL_CombatStatus.toc` | 공통 | TOC Version 1.11.6.3만 변경 |
| `KHQOL_Convenience/KHQOL_Convenience.toc` | 공통 | TOC Version 1.11.6.3만 변경 |
| `KHQOL_CursorTrail/KHQOL_CursorTrail.toc` | 공통 | TOC Version 1.11.6.3만 변경 |
| `KHQOL_DevTools/KHQOL_DevTools.toc` | 공통 | TOC Version 1.11.6.3만 변경 |
| `KHQOL_EnvironmentTimer/KHQOL_EnvironmentTimer.toc` | 공통 | TOC Version 1.11.6.3만 변경 |
| `KHQOL_ExperienceBar/KHQOL_ExperienceBar.toc` | B/공통 | 보조 객체 로드 순서·버전 |
| `KHQOL_ExperienceBar/Modules/ExperienceBar.lua` | B | 기존 segment 미리보기·텍스트/툴팁·휴식 우선순위·XP 관찰 |
| `KHQOL_ExperienceBar/Modules/QuestExperiencePreview.lua` | B | 신규 로그/API 필터·합계 캐시·동기화/차단·이벤트 정리 |
| `KHQOL_ExperienceBar/UI/ExperienceSettings.lua` | B | 기존 Builder의 표시/색상/수치/레벨업 옵션과 상태 안내 |
| `KHQOL_ExperienceBar/UI/SearchIndex.lua` | B | 새 옵션 검색 경로 |
| `KHQOL_Labs/KHQOL_Labs.toc` | 공통 | TOC Version 1.11.6.3만 변경 |
| `KHQOL_Map/Core.lua` | 공통 | 내부 표시 버전 1.11.6.3만 변경 |
| `KHQOL_Map/KHQOL_Map.toc` | 공통 | TOC Version 1.11.6.3만 변경 |
| `KHQOL_NPCAlert/KHQOL_NPCAlert.toc` | 공통 | TOC Version 1.11.6.3만 변경 |
| `KHQOL_PartyFrames/KHQOL_PartyFrames.toc` | 공통 | TOC Version 1.11.6.3만 변경 |
| `KHQOL_PvPAlert/KHQOL_PvPAlert.toc` | 공통 | TOC Version 1.11.6.3만 변경 |
| `KHQOL_QuestNavigator/KHQOL_QuestNavigator.toc` | 공통 | TOC Version 1.11.6.3만 변경 |
| `KHQOL_Range/KHQOL_Range.toc` | 공통 | TOC Version 1.11.6.3만 변경 |
| `KHQOL_ResourceSwing/KHQOL_ResourceSwing.toc` | 공통 | TOC Version 1.11.6.3만 변경 |
| `KHQOL_Threat/KHQOL_Threat.toc` | 공통 | TOC Version 1.11.6.3만 변경 |
| `KHQOL_Tooltip/KHQOL_Tooltip.toc` | 공통 | TOC Version 1.11.6.3만 변경 |
| `KHQOL_UnitFrames/KHQOL_UnitFrames.toc` | 공통 | TOC Version 1.11.6.3만 변경 |
| `KHQOL_UnitFrames/Modules/UnitFrameDecor.lua` | A | 확정 HEX 변환·범위/플레이어 판별·기존 HealthColor 우선 RGB |
| `KHQOL_UnitFrames/Modules/UnitFrames.lua` | A | 공통 classHealth 기본값·스타일 정규화 |
| `KHQOL_UnitFrames/UI/SearchIndex.lua` | A | 공통 직업 색상 검색 경로 |
| `KHQOL_UnitFrames/UI/UnitFrameDetails.lua` | A | 공통 설정 블록·두 스타일·중복 비활성 항목 정리 |

전체 파일별 전후 해시: `FILE-INVENTORY.json`. 정확한 텍스트 차이: `changes.patch`.

## 3. 작업 A — 유닛 프레임 직업 색상

### 적용 범위·판별

`SharedClassHealthColor(unit)`는 target/targettarget/focus만 허용하고 공개적으로 UnitExists=true, UnitIsPlayer=true인 경우에만 처리합니다. 기존 ClassToken이 UnitClassBase의 첫 번째 영문 토큰, UnitClass의 두 번째 영문 토큰을 안전하게 확인합니다. 지역화된 직업 이름이 Secret이더라도 공개된 영문 토큰만 사용할 수 있습니다. 지원하지 않는 토큰·NPC·없는 유닛·불명확한 상태는 기존 HealthColor 분기로 돌아갑니다. player/pet/focustarget/파티/공격대/기타 프레임에는 새 색상 정책을 적용하지 않습니다.

Forever 문서는 UnitClassBase의 classFilename/classID와 UnitClass의 지역화 이름/classFilename/classID 반환 구조를 구분합니다. 이는 소스 호환성 근거이며 실제 전투 중 공개 여부는 게임 내 확인이 필요합니다. [Forever UnitDocumentation](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua).

### 확정 팔레트

| 토큰 | 어둡게 (-10%) | 밝게 (+10%) |
| --- | --- | --- |
| WARRIOR | #B38C63 | #DBAC79 |
| PALADIN | #DD7EA7 | #FF9ACD |
| HUNTER | #9ABF68 | #BCE97F |
| ROGUE | #E6DD5F | #FFFF74 |
| PRIEST | #E6E6E6 | #FFFFFF |
| SHAMAN | #0065C8 | #007BF4 |
| MAGE | #5FB8D8 | #74E0FF |
| WARLOCK | #8575B5 | #A38FDD |
| DRUID | #E67109 | #FF8A0B |

각 HEX의 두 자리 값을 정수로 읽고 255로 나눕니다. 추가 밝기 계산, 반올림, 전역 RAID_CLASS_COLORS 수정은 없습니다. 엔진의 최종 화면색·명암 효과는 모의 테스트로 검증한 범위가 아닙니다.

### 채움·갱신·복원

새 코드는 기존 HealthColor 반환 RGB만 우선합니다. 위치·크기·텍스처·배경·테두리·이름·생명력 수치·오라·선택/주시 동작을 새로 변경하지 않습니다. 기존 ApplyBarColor는 원래부터 기본/관계·직업색을 표시할 때 WHITE8X8 채움과 네이티브 색/텍스처 복원 패킷을 관리합니다. 그 기존 경로는 수정하지 않았고, 새 옵션 전환으로 별도 텍스처/기하 변경을 추가하지 않았습니다. 간결한 프레임의 기존 healthDisplay에도 같은 RGB가 전달됩니다.

기존 대상/대상의 대상/주시 이벤트, 생명력 갱신과 네이티브 색상/텍스처 변경 후 훅을 재사용합니다. 새 매 프레임 강제 색상 루프는 없습니다. 스타일/옵션 변경은 ApplySettings, 프로필/로그인/Reload는 기존 모듈 적용 경로로 반영합니다.

새 옵션 OFF 시 **기존 KHQOL 색상 정책**으로 돌아갑니다. 예를 들어 기존 ‘관계·직업색’은 기존 팔레트대로 계속 작동합니다. 유닛 프레임 모듈 OFF 시 기존 소유 상태와 네이티브 색·채움 복원 경로를 따릅니다. 타 애드온의 독자 프레임은 탐색/재작성하지 않으며, 같은 Blizzard 바를 덮어쓰는 애드온과의 실제 충돌은 미검증입니다.

새 코드는 보호 프레임의 위치/속성/타깃 선택을 변경하지 않습니다. 공개 데이터만 사용하며 기존 pcall·후속 훅·전투 시 속성 변경 보류 처리를 유지합니다. 이 사실만으로 전투 중 taint가 없다고 판정하지는 않았습니다.

### 저장과 설정

`KHQOLDB.modules.unitFrames.classHealth = {enabled=false, style="dark"}`. 한 공통 설정을 세 프레임의 ‘바’ 화면에서 보여 주며 프레임별 새 스위치는 없습니다. 기존 개별 색상 설정은 보존하고, 해당 세 프레임의 사용 불가능하던 ‘직업색’ 메뉴 항목만 제거했습니다. 스타일은 dark/bright 두 값으로 정규화합니다.

## 4. 작업 B — 완료 퀘스트 보상 경험치 미리보기

### API 근거와 ID/인덱스

| 용도 | 사용 API와 인자 |
| --- | --- |
| 전체 로그 | C_QuestLog.GetNumQuestLogEntries() → 노출 항목 수, 총 퀘스트 수 |
| 항목 조회 | C_QuestLog.GetInfo(**questLogIndex**) → questID 및 isHeader/isTask/isBounty/isHidden |
| 현재 보유 | C_QuestLog.IsOnQuest(**questID**) |
| 반납 가능·목표 완료 | C_QuestLog.ReadyForTurnIn(**questID**), C_QuestLog.IsComplete(**questID**) 모두 true |
| 과거 보상·반복 | C_QuestLog.IsQuestFlaggedCompleted(**questID**), C_QuestLog.IsRepeatableQuest(**questID**) |
| 보상 XP | 전역 GetQuestLogRewardXP(**questID**) |
| 실제 XP/레벨 | UnitXP("player"), UnitXPMax("player"), UnitLevel("player") |

고정 Forever 문서에서 목록 구조와 ID 인자, 이벤트 인자를 확인했습니다. **C_QuestLog.GetQuestLogRewardXP는 사용하지 않습니다.** 해당 namespace API를 존재한다고 가정하지 않았습니다. [Forever QuestLogDocumentation](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua).

전역 GetQuestLogRewardXP는 같은 Forever 기본 UI에서 rewardQuestID를 인자로 호출합니다. 이 호출이 선택 상태를 바꾸지 않는 ID 조회 경로의 근거입니다. 선택 상태를 바꾸는 SetSelectedQuest/SelectQuestLogEntry나 추적 설정 API는 호출하지 않습니다. 무인자 구형 함수로 반복 조회하거나 임의 레벨 공식으로 보상값을 만들지 않습니다. [Forever ScenarioObjectiveTracker](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_ObjectiveTracker/Blizzard_ScenarioObjectiveTracker.lua).

레벨별 실제 XP 값·보너스·서버 스케일링은 게임 내 대조가 남았습니다. 현재 API가 제공하는 값을 사용하고 레벨 변경 시 재조회하며, 정확성을 확인할 수 없는 반환값은 제외합니다. API 이름 존재 검사와 소스 조사만으로 실제 보상 일치 PASS를 선언하지 않습니다.

### 필터링·합산·캐시

신규 QuestExperiencePreview 모듈은 경험치 모듈의 보조 객체이며 별도 애드온/공통 프레임워크가 아닙니다. 전체 노출 로그를 순회해 questID로 중복 제거하고, 헤더/작업/현상금/숨은 내부 항목은 제외합니다. 현재 보유, 목표 완료, 반납 가능 상태가 모두 확인된 항목만 후보로 둡니다. 이미 보상받은 일반 퀘스트는 제외하며 반복 퀘스트는 과거 완료 이력만으로 현재 재수락분을 제외하지 않습니다.

XP는 공개된 유한한 양의 정수(상한 10억)만 합산합니다. 0/누락/조회 실패/Secret은 제외합니다. 로그 전체 노출 여부, 스캔 시작/끝 XP·레벨, 이벤트 revision의 일관성을 검증합니다. 조건이 불명확하면 미리보기를 숨깁니다. 이벤트가 몰리면 C_Timer.After(0) 한 번으로 합치며 보상 합계를 캐시합니다. 일반 Render/휴식 갱신마다 전체 로그를 순회하지 않습니다. OnUpdate 폴링은 없습니다.

### 동기화와 반납 중복 방지

사용 이벤트는 QUEST_LOG_UPDATE, QUEST_ACCEPTED, QUEST_TURNED_IN, QUEST_REMOVED, QUEST_COMPLETE, QUEST_FINISHED, QUEST_DATA_LOAD_RESULT, PLAYER_ENTERING_WORLD입니다. 실제 XP/레벨 변경은 경험치 바의 기존 PLAYER_XP_UPDATE, PLAYER_LEVEL_UP, UNIT_LEVEL 경로에서 관찰합니다.

- 반납/제거 이벤트는 해당 ID를 즉시 합계에서 빼고 차단 기록을 남깁니다. ID를 읽을 수 없더라도 전체 예상 표시를 즉시 보류합니다. 이전 로그가 한 번 더 보여도 차단 ID를 재합산하지 않습니다.
- XP가 반납/로그 이벤트보다 먼저 바뀌면 캐시를 실제 XP 위에 더하지 않고 숨깁니다. 로그가 먼저 갱신되고 그 스냅샷의 XP·레벨이 현재와 같으면 다시 숨기지 않습니다.
- 이후의 신뢰 가능한 QUEST_LOG_UPDATE로 동기화합니다. 타이머는 호출 합치기만 하며 시간 경과를 완료 증거로 쓰지 않습니다. 일반 XP도 출처를 확정할 수 없어 로그까지 숨길 수 있습니다. 이는 이중 계산을 피하기 위한 기능 제한입니다.
- QUEST_COMPLETE 보상 창이 열리면 예상 표시를 숨깁니다. QUEST_FINISHED에서 XP·레벨이 그대로면 취소로 재확인할 수 있으며, 지급 중 값이 변했으면 로그 동기화를 기다립니다.
- QUEST_ACCEPTED의 첫 인자는 로그 인덱스, 둘째가 questID이므로 **둘째만** 차단 해제에 사용합니다. 포기/재수락과 연속 반납을 분리합니다.
- 실제 레벨업 후 보상값을 다시 조회합니다. 프로필 변경/모듈 OFF는 예약 콜백 티켓을 무효화해 이전 프로필 결과가 돌아오는 것을 차단합니다.

### 기존 바 내부 표시

기존 두 segment 각각에 비입력 questXP Texture 한 장을 추가합니다. 새 StatusBar나 경험치 바를 만들지 않습니다. 실제 SetValue는 바꾸지 않습니다.

`시작 = currentXP/maxXP`, `끝 = min(currentXP+questXP,maxXP)/maxXP`. 4,500/10,000 +2,000이면 45→65%만 표시합니다. 8,500 +3,000이면 85→100%와 총 +3,000, 현재 레벨 초과 +1,500을 구분합니다. 다음 레벨 요구량은 추정하지 않습니다.

기존 폭·높이·위치·배율 변경을 그대로 따르며 기존 wrapTop/wrapBottom의 세로/역방향→수평 경로에도 구간을 분배합니다. **기존 설정에서 감싸기 모드가 비활성인 상태는 그대로 유지**했습니다. 이 작업에서 새 방향 선택 기능을 열지 않았습니다.

실제 XP → 예상 XP → 남는 휴식 구간 순서로 겹침을 피합니다. 휴식의 실제 수치와 끝점은 그대로 두고 예상 구간과 겹치는 시각 부분만 가립니다. 퀘스트 보상에 휴식 배율을 더하지 않습니다. OFF이면 기존 휴식 구간과 같습니다. 기존 마커와 별도 텍스트층은 유지합니다.

기존 BaseText 문자열을 그대로 만든 뒤 선택 시 `(+N 예상)` 및 `레벨업 예상`을 붙입니다. 기존 수치 표시 OFF면 전체 텍스트가 숨겨집니다. 툴팁에는 총 예상 XP와 초과 예상 XP를 추가하고 보상 변동 가능성을 안내합니다. 평판 표시·최대 레벨·maxXP=0·0보상·미완료·모듈 OFF에는 예상 구간을 표시하지 않습니다.

### 저장

새 전역 SavedVariables는 없습니다. 기존 `KHQOLDB.modules.experienceBar` 안에만 다음 기본값을 병합합니다.

```lua
showQuestPreview = false
showQuestXPText = true
showQuestLevelPrediction = true
questPreviewColor = {1, .78, .12, 1}
```

기존 color/restedColor/textColor/위치/크기 등의 값을 덮어쓰지 않습니다. 계산 캐시·차단 ID·타이머 티켓은 런타임 객체이며 저장하지 않습니다. 기존 프로필 캡처/로드 경로가 새 옵션도 관리합니다.

## 5. UI 변경

- 유닛 프레임 → 대상/대상의 대상/주시 대상 → 바: ‘유닛 프레임 직업 색상’ 공통 블록. 적용 OFF, 어둡게 기본. 적용 OFF면 스타일 선택 비활성.
- 바 설정 → 경험치: ‘완료 퀘스트 경험치 미리보기’. 표시 OFF, 별도 노란색 계열 색상, 수치 ON, 레벨업 예상 ON. 하위 옵션은 상위와 모듈 상태를 따르며 수치는 기존 showText에도 종속됩니다.
- 기존 공용 섹션·컨트롤·여백·Reflow·검색 시스템을 사용합니다. 설정 변경은 기존 Changed/ApplySettings로 즉시 반영합니다. 퀘스트 데이터는 이벤트 병합 후 반영합니다.
- 수치·색상 변경 독립성과 XP 설정 컨트롤 콜백은 모의 검증했습니다. 실제 폰트·줄바꿈·스크롤·화면 잘림·상호작용은 NOT TESTED입니다.

## 6. 기존 기능 호환성

기존 사용자 설정/Default 프로필 초기화, 키 삭제, 게임 XP 쓰기, 퀘스트 선택·추적 변경을 추가하지 않았습니다. 두 신규 상위 옵션이 OFF인 경우 기존 표시 정책을 사용합니다. 기존 MergeDefaults와 프로필 시스템을 유지합니다. Quest Navigator는 TOC 버전 외 바이트 동일하며 미설치/비활성 상태에서도 XP 계산은 자체 로그 API를 사용합니다.

1.11.6.2의 채팅 Alt 초대·오브젝트 강조·모닥불 진단 구현을 유지했습니다. 이전 릴리스의 실게임 미검증 및 모닥불 화살표 보류 판단을 이번 검증으로 해소했다고 보지 않습니다. 게임 설치 폴더/WTF에 쓰지 않았고 Git commit/push도 하지 않았습니다.

## 7. 테스트 결과

| 검증 | 상태 | 결과/한계 |
| --- | --- | --- |
| 전체 Lua 5.1 구문 | PASS | 216/216 |
| 모의 시나리오 | PASS | 245/245. 기존 회귀 + 신규 직업/XP 통합 |
| TOC 경로/버전 | PASS | 20개, 참조 누락 0, Version 1.11.6.3 / Interface 16001 |
| 배포 무결성 | PASS | 원본 파일 누락 0, ZIP CRC 및 모든 압축 바이트와 소스 일치 |
| A 직업/대상 조건 | PASS (모의) | 9직업×2스타일×3유닛, 제외 유닛/NPC/Secret/없음/스타일 전환/네이티브 갱신/옵션 및 모듈 OFF 복원 |
| B 계산/렌더 | PASS (모의) | 0/여러/중복/실패/Secret/반복 퀘스트, 45→65, 85→100, 휴식 우선순위, 폭·높이·이동·역방향 경로, 평판/0최대XP |
| B 동기화 | PASS (모의) | XP 선행·로그 선행·반납 선행·지연 콜백·연속 반납·포기/재수락·대화 취소·레벨 재조회·일반XP 보류 후 로그 복원 |
| 설정/프로필 | PARTIAL | 실제 프로필 캡처/로드 및 XP 설정 빌더를 모의 실행. 전체 UI의 실게임 렌더/Reload는 NOT TESTED |
| 실제 Forever API/보상 | NOT TESTED | 로그인하여 보상 XP/레벨 스케일/반복·특수 퀘스트 반환 확인 필요 |
| 실제 화면·전투·충돌 | NOT TESTED | 실화면 색상/텍스처·수치/taint·외부 프레임 애드온·기존 Quest Navigator 회귀 필요 |

모의 테스트는 Lua 5.1로 실제 모듈 함수를 실행하지만 WoW 엔진/서버/Secret 권한/보호 프레임을 재현하지 않습니다. `validation/validation-results.json`에 시나리오별 결과를 제공합니다. 이 결과를 인게임 PASS로 해석하지 마세요. 검증 명령과 고정 네이티브 채팅 참고 소스도 validation에 포함합니다.

## 8. 기능별 최종 판정

| 기능 | 판정 | 근거 |
| --- | --- | --- |
| 유닛 프레임 직업 색상 | **LIMITED GO** | 구현·정적/모의 검증 완료. 실제 3프레임·전투·Secret·외부 애드온 충돌 검증 필요 |
| 완료 퀘스트 XP 미리보기 | **LIMITED GO** | 구현·계산/동기화 모의 검증 완료. 실제 보상/이벤트 순서 검증 필요. 일반 XP 후 로그까지 숨김·불완전 노출 로그 보류 제한 있음 |

## 9. 최종 결과물과 설치

`KHQOL-1.11.6.3.zip`과 `source/`는 동일한 304파일, 20개 애드온 폴더의 전체 배포본입니다. ZIP 최상위 폴더들을 게임 종료 상태에서 Interface/AddOns에 배치하고 기존 WTF/SavedVariables를 유지합니다. 기존 코드 폴더 백업 후 교체를 권장합니다. 설치 안내/버전 README를 갱신했습니다. 첨부 `INGAME-CHECKLIST-ko.md`로 실게임 확인 후 정식 GO 여부를 판단하세요.


---

# KHQOL 1.11.6.3 실게임 확인 체크리스트

**현재 모든 항목: NOT TESTED.** 아래 빈 체크박스는 실행했다는 의미가 아닙니다. 정적/모의 테스트 결과는 IMPLEMENTATION-REPORT-ko.md에 따로 있습니다. 현재 판정은 A/B 모두 LIMITED GO입니다.

## 준비·기존 기능

- [ ] 게임 종료 후 기존 코드와 WTF를 백업하고 전체 ZIP의 20개 애드온 폴더를 AddOns 바로 아래 배치한다. WTF/SavedVariables를 삭제하지 않는다.
- [ ] 애드온 목록 20개 TOC 버전 1.11.6.3, Interface 16001을 확인한다. 선택 설치 모듈이 없어도 나머지가 정상 로드된다.
- [ ] 기존 Default/사용자 프로필, 위치·크기·색상·경험치 형식·휴식 설정이 유지된다. 새 상위 스위치는 둘 다 OFF이다.
- [ ] OFF 상태의 기존 유닛 프레임/경험치/평판/채팅 Alt 초대/오브젝트 강조/모닥불 진단/Quest Navigator가 이전과 같다.
- [ ] 설정 화면의 한글·줄바꿈·정렬·스크롤·비활성 표시·검색 이동에 겹침이나 잘림이 없다.
- [ ] 한 기능만 ON, 반대 조합, 둘 다 ON, 둘 다 OFF에서 독립적으로 동작한다.

## A. 직업 색상

유닛 프레임 → 대상/대상의 대상/주시 대상 → 바에서 공통 ‘직업 색상 적용’을 켠다. 각 칸은 해당 스타일로 **세 유닛 모두** 확인했을 때 체크한다. 화면 캡처만으로 RGB를 정확히 읽기 어렵다면 반환된 RGB와 바의 공개 색값도 비교한다. Secret 값을 강제로 출력/계산하지 않는다.

| 직업 | 어둡게 | 확인 | 밝게 | 확인 |
| --- | --- | --- | --- | --- |
| 전사 | #B38C63 | [ ] | #DBAC79 | [ ] |
| 성기사 | #DD7EA7 | [ ] | #FF9ACD | [ ] |
| 사냥꾼 | #9ABF68 | [ ] | #BCE97F | [ ] |
| 도적 | #E6DD5F | [ ] | #FFFF74 | [ ] |
| 사제 | #E6E6E6 | [ ] | #FFFFFF | [ ] |
| 주술사 | #0065C8 | [ ] | #007BF4 | [ ] |
| 마법사 | #5FB8D8 | [ ] | #74E0FF | [ ] |
| 흑마법사 | #8575B5 | [ ] | #A38FDD | [ ] |
| 드루이드 | #E67109 | [ ] | #FF8A0B | [ ] |

- [ ] 대상 변경/대상의 대상 변경/주시 지정·해제/대상 해제로 색상이 즉시 올바르게 갱신된다.
- [ ] NPC 우호·중립·적대·선점 색상은 기존 정책과 같다. 없는 유닛/알 수 없는 직업도 기존 정책을 따른다.
- [ ] 플레이어·펫·주시 대상의 대상·파티·공격대 등 제외 프레임은 영향이 없다.
- [ ] 기본/간결한 기존 프레임 모두 채움 색상 외 텍스처·위치·크기·배경·테두리·이름·수치·오라가 같다.
- [ ] 생명력 변화와 Blizzard 기본 색상 갱신 후에도 선택한 스타일이 유지된다.
- [ ] 새 옵션 OFF면 기존 기본/관계·직업색/사용자 색으로 돌아간다. 모듈 OFF는 기존 네이티브 복원을 따른다.
- [ ] 전투 진입·종료, 전투 중 대상/주시 변화 및 Secret 정보 상황에서 오류·금지 동작·taint가 없다.
- [ ] 프로필 전환과 Reload 후 새 옵션이 프로필별로 유지되고 기존 설정이 보존된다.
- [ ] 다른 프레임 애드온과 함께 사용할 때 지원 범위/색상 충돌을 기록한다.

## B. 보상 XP API와 목록

바 설정 → 경험치에서 ‘완료 퀘스트 경험치 표시’를 켠다. 최대 레벨이 아닌 캐릭터를 사용한다. **현재 레벨에서 보상창이 보여 주는 실제 XP와 합계가 맞는지 먼저 대조**한다. 다른 애드온이 XP 보너스를 보정하는지도 기록한다.

- [ ] 완료 0개: 예상 구간/예상 숫자 없음.
- [ ] 완료 1개 및 여러 개: 현재 보유·목표 완료·반납 가능·양의 XP인 퀘스트만 정확히 합산.
- [ ] 추적하지 않은 완료 퀘스트도 포함되고 Quest Navigator OFF/미설치에서도 동작.
- [ ] 퀘스트 선택·추적·헤더 상태가 조회 전후 바뀌지 않는다.
- [ ] 미완료/XP0/이미 반납/헤더/조회 불가/Secret 항목은 제외. 불확실한 특수 퀘스트는 잘못 포함하지 않음.
- [ ] 반복 퀘스트 재수락분은 과거 완료 이력과 구별되어 한 번만 합산.
- [ ] 접힌/숨은 로그로 전체 항목을 읽지 못하면 부분합을 표시하지 않고 보류한다. 수동으로 펼치고 로그 갱신하면 복원되는지 확인.
- [ ] 필수 API 미지원 상태에서는 XP 미리보기만 보류되고 직업 색상/나머지 UI는 정상.

## B. 표시·이벤트 순서

- [ ] 실제 XP 뒤부터 예상 구간이 시작하며 실제 채움값은 변하지 않는다. 45% +20%이면 45→65%만 표시.
- [ ] 85% +30%이면 85→100%만 표시하고 총 보상/현재 레벨 초과/‘레벨업 예상’을 구분. 다음 레벨 진행률을 추정하지 않음.
- [ ] 완료/포기/수락/연속 반납/재수락 때 합계가 갱신되고 같은 퀘스트를 중복 계산하지 않는다.
- [ ] 반납 중 실제 XP 증가가 먼저 도착해도 이미 받은 보상을 다시 더한 구간이 한 프레임이라도 나타나지 않는다. 가능하면 영상/이벤트 로그로 기록.
- [ ] 반납 이벤트 선행·XP 선행·로그 선행 순서를 관찰하고 순서별 표시와 복원 시점을 기록.
- [ ] 보상창 열기/취소/보상 선택/실패 후 값이 복원되며, 지급 중에는 오래된 합계가 나타나지 않는다.
- [ ] 일반 몬스터 XP 시 시작점은 현재 XP를 따른다. 출처 미확정 때문에 숨겨진 경우 다음 QUEST_LOG_UPDATE에서 복원되는지 확인. **로그 이벤트가 없으면 계속 숨길 수 있다는 제한의 실제 빈도를 기록.**
- [ ] 실제 레벨업 때 새 레벨의 퀘스트 보상 XP로 재조회한다. 지급 보너스·낮은 레벨 퀘스트·반복/특수 보상과 대조.
- [ ] 휴식 XP가 예상 보상에 곱해지지 않는다. 예상 구간이 우선하고 남는 휴식 구간은 겹치지 않음. OFF면 이전 휴식 표시와 같음.
- [ ] 폭/높이/위치/배율 변경 시 예상 구간이 같은 바 안에서 이동·크기 조정. 기존 감싸기 모드를 저장해 사용 중이었다면 세로/역방향/경계도 확인.
- [ ] 예상 색상은 XP/휴식/배경 색상과 독립 저장·즉시 반영.
- [ ] 기존 숫자 표시 OFF면 예상 숫자도 숨김. 예상 숫자/레벨업 예상 하위 스위치 각각 독립 동작.
- [ ] 평판 전환 시 예상 구간과 XP 예상 텍스트 숨김, XP 복귀 시 안전하게 복원. 최대 레벨/maxXP0도 잘못 표시하지 않음.
- [ ] 기능/모듈 OFF 시 구간이 즉시 숨겨지고 예약 조회가 되살리지 않음. 프로필 전환 중 이전 결과가 새 프로필에 나타나지 않음.
- [ ] Reload/로그인/로그 폭주 중 오류 없고 OFF 시 불필요한 로그 조회가 없음.

## 최종 기록

| 구분 | 실행 환경·증거·결과를 채울 것 |
| --- | --- |
| 클라이언트 빌드·캐릭터 레벨 | 미기록 |
| 동시 사용 애드온 | 미기록 |
| A 실제 검증 | NOT TESTED |
| B 실제 보상 일치·이벤트 순서 | NOT TESTED |
| 전투/taint·화면·프로필/Reload 회귀 | NOT TESTED |
| 로그 보류 빈도·지속 시간 | 미기록 |
| 최종 판정 | A/B LIMITED GO 유지. 실제 검증 후 GO/LIMITED GO/HOLD 갱신 |
