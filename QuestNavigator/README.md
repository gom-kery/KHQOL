# KHQOL 1.9.8.1 — 퀘스트 레벨·유형 표기 통합

사용자 제공 KHQOL-1.9.8.zip을 기준으로 목표 추적기의 퀘스트 제목 앞 레벨과 유형을 한 쌍의 대괄호에 표시합니다.

- 정예: `[15 ★] 퀘스트 제목`
- 던전: `[15 D] 퀘스트 제목`
- 일반: `[15] 퀘스트 제목`

태그 표시를 끄면 기존처럼 레벨만 표시합니다. 던전·정예가 동시에 해당하면 D를 우선하고, D는 기존 제목 글꼴로 표시합니다. 기존 난이도 색상과 줄바꿈·높이 계산을 유지합니다. 전투 중 지역 접기·펼치기 보류 정책은 그대로입니다.

변경 실행 파일: QuestNavigator/Tracker.lua, Bootstrap.lua, KHQOL.toc. 문서 3개에 이번 기록을 추가했습니다. 다른 설정·저장 변수·자동 길안내·화살표·위협 표시·음성·환경 타이머·미디어는 기준본과 바이트 비교해 보존합니다. 새로운 실행 파일·옵션·저장 키는 추가하지 않았습니다.

검증: 기존 추적기·전체 퀘스트 수 모의 회귀 검사와 전체 Lua 5.1 문법·TOC·ZIP 무결성 검사. 구체적인 결과는 KHQOL-1.9.8.1-validation.json에 기록합니다. 실제 인게임 검증은 미실시입니다(IN-GAME: NEEDS TEST).

ZIP 안의 KHQOL 폴더를 기존 애드온 폴더에 덮어쓰고 `/reload`하세요. SavedVariables 삭제는 필요하지 않습니다.

---

# KHQOL 1.9.5.7 — 모든 목표에 전체 퀘스트 수 표시

기준본: 사용자 제공 최신 `KHQOL-1.9.5.6.zip`.

목표 추적기의 상단 제목을 `모든 목표 ( 34 / 40 )` 형식으로 표시합니다. 수치는 추적 중인 목록 개수가 아니라 **현재 수락한 전체 퀘스트 수**입니다. 별도 설정은 추가하지 않았으며 Quest Navigator 모듈을 켜면 적용됩니다.

기본 지도 및 퀘스트 목록의 Forever 구현과 같이 `C_QuestLog.GetNumQuestLogEntries()`의 두 번째 반환값(퀘스트 수)과 `Constants.QuestLogConsts.MAXIMUM_NUM_QUESTS_LOG_CAN_ACCEPT`(현재 40)를 사용합니다. 헤더까지 포함하는 첫 번째 반환값이나 Quest Watch 개수는 사용하지 않습니다. 게임 상한이 바뀌면 게임이 제공하는 상한을 따릅니다.

수락·포기·반납·Quest Log 변경·접속 시 이벤트로 갱신합니다. 기본 추적기가 제목을 다시 설정해도 수치가 붙도록 해당 프레임의 Update에 후처리를 연결합니다. 숫자가 같으면 텍스트를 다시 설정하지 않으며 상시 polling·새 UI 프레임·저장 설정을 추가하지 않았습니다. 퀘스트 API를 읽지 못하면 기본 제목만 표시합니다.

기존 상단 제목 FontString에 텍스트만 추가해 글꼴·색상·너비·접기 버튼·다른 추적 모듈 배치를 유지합니다. 전투 중에도 수치 텍스트만 갱신하고 퀘스트 블록·아이템 버튼은 재배치하지 않습니다. 모듈을 끄면 기본 제목을 복원합니다.

## 변경 파일

- `QuestNavigator/Tracker.lua`: 상단 퀘스트 수 집계·표시, 기본 제목 갱신 후처리와 이벤트 연결.
- `Bootstrap.lua`, `KHQOL.toc`: 버전 1.9.5.7.
- `README.md`, `CHANGELOG.md`, `QuestNavigator/README.md`: 이번 변경 안내 추가, 이전 기록 유지.

1.9.5.6의 인스턴스 역할별 위협 설정, 95% 음성, 미니맵 아이콘, 길안내·화살표, 지역 헤더·유형 기호와 기타 코드·미디어는 기준 ZIP과 바이트 비교하여 보존합니다. SavedVariables를 초기화하거나 변경하지 않습니다.

## 검증

**STATIC CHECK: PASS** — 기존 퀘스트 추적기 모의 회귀 55개와 퀘스트 수 연동 검사 13개(총 68개), 전체 Lua 55개 Lua 5.1 문법·TOC 확인. ZIP 무결성 및 기준본 파일 보존 검사를 수행했습니다. 이번 작업에서 이전 Threat 모듈의 397개 검사를 다시 실행했다고 보고하지 않습니다.

**IN-GAME: NEEDS TEST** — 실제 Forever 클라이언트는 실행하지 않았습니다. 제목의 실제 글꼴 배율별 표시, 보호 동작은 게임에서 확인해야 합니다.

- [ ] 기본 지도 오른쪽 상단 수치가 34/40이면 `모든 목표 ( 34 / 40 )`로 표시됨.
- [ ] 퀘스트 수락 시 증가, 포기·반납 시 감소, 진행 목표 달성만으로는 감소하지 않음.
- [ ] 추적 해제·지역 접기와 관계없이 전체 수락 개수를 유지함.
- [ ] 추적기 전체 접기·펼치기, 지도 열기·닫기, `/reload` 후 수치 유지.
- [ ] UI 배율과 기본 추적기 글씨 크기를 바꿔도 제목·숫자·접기 버튼이 겹치지 않음.
- [ ] 전투 중 수치 갱신 시 기존 아이템 사용·보호 동작에 오류가 없음.
- [ ] Quest Navigator OFF 시 기본 `모든 목표` 제목으로 복원됨.

## 설치

ZIP 내부 `KHQOL` 폴더를 기존 애드온 폴더에 덮어쓰고 `/reload`하세요. SavedVariables 삭제는 필요하지 않습니다.

## 확인한 기본 UI 소스

- [Forever 지도 및 퀘스트 목록의 집계](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_UIPanels_Game/Camelot/QuestMapFrameUtils.lua)
- [기본 상단 제목·갱신](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_ObjectiveTracker/Blizzard_ObjectiveTracker.lua)

---

# KHQOL 1.9.5.2 — 퀘스트 유형 기호

퀘스트 제목 앞의 정예 태그는 `[★]`, 던전 태그는 `[D]`로 변경했습니다. 설정 항목도 `[★] 정예 표시`, `[D] 던전 표시`로 맞췄습니다. Dungeon+Elite는 기존처럼 Dungeon을 우선합니다. 기존 표시 옵션과 저장 설정을 유지합니다.

예: `[15] [★] 정예 퀘스트`, `[15] [D] 던전 퀘스트`.

D는 기본 퀘스트 제목 글꼴로 표시합니다. 기본 FontString의 일부 문자에만 굵은 글꼴을 지정하는 별도 서식은 추가하지 않았습니다. 지역명 크기(퀘스트 글씨+1pt)와 색상 `#FF775F`도 유지합니다.

기준본: KHQOL-1.9.5.1.zip. 변경 실행 파일: `QuestNavigator/Tracker.lua`, `QuestNavigator/Settings.lua`, `Bootstrap.lua`, `KHQOL.toc`. 문서 3개에 변경 이력을 추가했습니다.

STATIC CHECK: PASS — 기존 모의 검증 55개, 전체 Lua 55개 문법 및 TOC 검사. IN-GAME: NEEDS TEST — 실제 Forever 클라이언트 화면은 실행하지 않았습니다.

ZIP 내부 KHQOL 폴더를 덮어쓰고 `/reload`하세요. SavedVariables를 삭제할 필요가 없습니다.

---

# KHQOL 1.9.5.1 — 지역 헤더 글씨

지역명 글씨는 설정된 퀘스트 글씨 크기보다 1pt 크게 표시하며, 색상은 `#FF775F`로 적용합니다. 퀘스트 글씨 크기를 변경하면 지역명 크기와 배치 높이도 함께 계산됩니다.

기준본: KHQOL-1.9.5.zip. 변경 실행 파일: `QuestNavigator/Tracker.lua`, `Bootstrap.lua`, `KHQOL.toc`. 문서 3개에 변경 이력을 추가했습니다.

STATIC CHECK: PASS — 기존 모의 검증 55개, 전체 Lua 55개 문법 및 TOC 검사. IN-GAME: NEEDS TEST — 실제 Forever 클라이언트 화면은 실행하지 않았습니다.

ZIP 내부 KHQOL 폴더를 덮어쓰고 `/reload`하세요. SavedVariables를 삭제할 필요가 없습니다.

---

# KHQOL 1.9.5 — 퀘스트 목표 추적창 개선 보고서

기준본: 사용자 제공 KHQOL-1.9.4.zip. 애드온 버전: 1.9.5 / Interface: 16001.

지역별 그룹화, 지역 접기·펼치기, 낮은 레벨순 정렬, [던전]·[정예] 표시, 글씨 크기 10~20, 내용 표시 폭 200~500을 기존 Quest Navigator 설정에 추가했습니다. `/khqol quest`에서 설정하고 `/khqol quest layout`으로 배치 정보를 확인합니다. 기본 퀘스트 블록을 재사용하며 Navigation/Arrow 계산은 변경하지 않았습니다.

**STATIC CHECK: PASS** — 실제 Forever 기본 블록·모듈·퀘스트 추적기 소스를 사용한 모의 검사 55개, 전체 Lua 55개 Lua 5.1 문법 검사, TOC 51개 로드 파일 확인.

**IN-GAME: NEEDS TEST** — 실제 Forever 클라이언트는 실행하지 않았습니다. 모의 글꼴 높이 계산은 근사값이며 실제 화면·아이템 사용·보호 프레임·taint 검증을 대신하지 않습니다.

## 1. 수정한 파일

| 파일 | 변경 내용 |
|---|---|
| `QuestNavigator/Tracker.lua` | 기존 길안내 코드 앞에 퀘스트 목록 표시 기능 추가: 지역·정렬·태그·글씨·폭·기본 블록 연동·전투 후 배치·디버그 |
| `QuestNavigator/Core.lua` | 모듈 활성화에 목록 표시 연결, `quest layout` 명령 분기 추가 |
| `QuestNavigator/Settings.lua` | 기존 공통 설정 Builder로 목록 표시 설정 추가 |
| `Bootstrap.lua` | KHQOL 버전 1.9.5 |
| `KHQOL.toc` | 버전 1.9.5; 파일 로드 순서 및 SavedVariables 선언 유지 |
| `QuestNavigator/README.md` | 이번 구현 보고서와 인게임 체크리스트 추가 |
| `README.md` | 1.9.5 사용·설치 안내 추가, 이전 내용 보존 |
| `CHANGELOG.md` | 1.9.5 변경 이력 추가, 이전 이력 보존 |

`QuestNavigator/Arrow.lua`, `QuestNavigator/UI.lua`, 기존 Tracker의 길안내 본문과 다른 모듈·미디어는 기준본 바이트와 비교합니다. 비교 결과는 validation JSON과 manifest에 포함합니다.

## 2. 추가 파일과 책임 분리

애드온 내부에 신규 실행 파일이나 신규 TOC 항목을 추가하지 않았습니다. 기존 `Tracker.lua`에 표시 책임을 모아 두었습니다. 배포 ZIP 밖의 이 보고서·검증 JSON·파일 비교 manifest는 검토용 산출물입니다.

## 3. 지역 판정

`C_QuestLog.GetHeaderIndexForQuest(questID)` → `C_QuestLog.GetInfo(headerIndex)`의 실제 헤더 제목을 사용합니다. 현재 플레이어 지도, NPC 위치, 외부 DB를 사용하지 않습니다. 유효한 헤더가 없으면 마지막 `기타` 그룹으로 분류합니다. API의 `QuestInfo`에는 영속 헤더 ID가 없으므로 저장 키는 `header:<헤더명>`이며, 매번 바뀔 수 있는 로그 행 번호는 저장하지 않습니다.

## 4. 추적 퀘스트 수집

Forever의 `QuestObjectiveTracker:BuildQuestWatchInfos()`를 그대로 호출합니다. 이 함수는 `GetNumQuestWatches()` / `GetQuestIDForQuestWatchIndex()`로 Watch ID를 읽고, `QuestCache` 및 기본 `ShouldDisplayQuest()` 필터를 적용합니다. 전체 Quest Log를 순회하거나 헤더를 강제로 펼치지 않습니다. 캠페인·월드 퀘스트·보너스 목표 등 다른 기본 모듈 대상은 기존 분류를 따릅니다. 기존 Navigation이 사용하는 world-watch 포함 캐시와 목록 표시용 컬렉션은 분리되어 있습니다.

## 5. 지역 순서

현재 헤더 인덱스 오름차순으로 배치해 기본 Quest Log / Quest Map의 목록 순서를 따릅니다. 가나다순으로 바꾸지 않습니다. 같은 헤더명을 사용하는 항목은 하나의 그룹으로 묶고 가장 앞선 헤더 순서를 사용합니다. 판정 불가 그룹은 마지막에 둡니다.

## 6. 레벨 순서

Forever 지도 제목과 동일한 `QuestInfo.difficultyLevel`을 우선 사용하고, 없으면 `GetQuestDifficultyLevel()` 및 `info.level` 순으로 읽습니다. 지역 내부는 Level ASC → 원래 Watch index ASC입니다. 판정 불가 레벨은 뒤에 둡니다. 지역별 그룹화를 끄면 헤더 없이 추적 퀘스트 전체를 같은 레벨 정책으로 정렬합니다.

## 7. Dungeon / Elite 판정과 제목

`C_QuestLog.GetQuestTagInfo()`의 `tagID`를 실제 `Enum.QuestTag.Dungeon` / `Heroic` 값과 비교합니다. Raid나 제목 문자열에서 던전을 추측하지 않습니다. `C_QuestLog.IsEliteQuest()`로 정예를 판정합니다. 둘 다 해당하면 던전만 우선합니다. 던전 표시를 껐다고 던전·정예 퀘스트에 정예 태그를 대신 붙이지 않습니다.

제목은 원본 `GetTitleForQuestID()`에서 `[레벨] [유형] 제목`으로 작성해 기본 레벨 접두어와 `+`를 중복하지 않습니다. 기본 `SetQuestTitleLevelAndDifficultyColor()` 결과의 색상 코드를 보존하고, 기본 블록의 hover/난이도 색상 정책을 사용합니다. 별도 난이도 색상표를 추가하지 않았습니다.

## 8. Region Header / Collapse

지역 헤더는 `ContentsFrame`의 독립 Button row이며 기본 퀘스트의 linked list, Quest ID, POI 및 퀘스트 메뉴 동작에 포함하지 않습니다. 헤더는 최대 동시 표시 지역 수만큼 재사용합니다. 기본 모듈의 공간 판정·블록 앵커 흐름에 헤더 높이와 간격을 반영하며, 접힌 지역은 Quest Block을 아예 배치하지 않습니다. 미사용 블록·아이템·목표 줄은 기본 풀로 반환됩니다. Quest Watch나 지도 헤더 상태는 변경하지 않습니다.

모듈 전체를 끄면 기본 레이아웃·글꼴·블록 메서드를 복원합니다. 기본 추적기 내부 상태를 전역 mixin 수정으로 바꾸지 않고 `QuestObjectiveTracker` 인스턴스에만 연결합니다.

## 9. Font Size

첫 설정은 실행 중인 `ObjectiveTrackerLineFont:GetFont()` 크기를 읽습니다(소스 기본 한국어 크기 12). 제목·목표·dash에 기존 글꼴 파일과 flags를 유지해 설정 크기를 적용합니다. 줄 사이 간격도 크기에 따라 조절합니다. 크기는 기본 `SetStringText()`가 높이를 측정하기 전에 적용합니다. 제목은 최대 2줄 제한을 해제하고 전체 높이를 사용하며 HeaderButton의 기본 앵커가 클릭 영역을 따라갑니다. 풀 반환·모듈 OFF 시 기존 FontObject와 관련 속성을 복원합니다.

## 10. Content Width / Wrapping

첫 폭은 실행 중인 Quest Module 폭에서 기본 블록 왼쪽 여백을 뺀 실제 기본 폭으로 저장합니다(소스 기본 모듈 260 → 블록 240). UI에 기본 모듈이 아직 없으면 235를 임시 표시하며, 설치 시 실제 폭을 읽습니다. 설정 범위는 200~500입니다.

`ObjectiveTrackerFrame`이나 다른 모듈 폭은 변경하지 않습니다. 퀘스트 블록만 고정 폭으로 만들고 오른쪽 끝을 유지하여 폭이 커지면 왼쪽으로 확장합니다. 기본 제목·목표 앵커의 실제 폭을 먼저 결정한 뒤, 기본 Text Height → Line Height → Block Height → 다음 Block → Module Height → Container Height 흐름을 재사용합니다. 진행률 막대는 기본 수치·동작을 유지하고, 좁은 폭에서는 오른쪽 장식과 아이템 여백 안에 들어가게 폭만 제한합니다.

## 11. Quest Item Button / 전투

기본 `AddRightEdgeFrame()` / `rightEdgeOffset`을 유지해 제목과 모든 목표 줄에서 아이템·그룹 버튼 폭을 확보합니다. 블록 높이는 오른쪽 버튼 높이와 여백보다 작아지지 않게 합니다. 기존 버튼의 cooldown, tooltip, 아이템 식별 정보와 클릭 구현을 교체하지 않습니다.

보수적으로 전투 중에는 이 기능이 적용된 Quest Module의 재배치 전체를 보류하고 `PLAYER_REGEN_ENABLED` 후 기본 Dirty 흐름으로 다시 구성합니다. 설정·접힘 상태는 즉시 저장되지만 화면 적용은 전투 종료 후입니다. **이 보류에는 추적 목록·진행·완료 표시의 구조 갱신도 포함됩니다.** 전투 중 다른 추적 모듈은 기존 흐름을 유지하고, 기존 아이템 버튼의 자체 cooldown/tooltip 갱신은 남습니다. 기본 컨테이너나 게임 자체의 보호 동작까지 보장한 것은 아니므로 실제 taint 및 blocked action 검사가 필요합니다.

## 12. SavedVariables

기존 `KHQOLDB.modules.questNavigator` 안에 `questTracker`를 추가합니다.

```lua
questTracker = {
  groupByRegion = true,
  collapsibleRegions = true,
  showDungeonTag = true,
  showEliteTag = true,
  fontSize = 12,       -- 최초 실행의 기본 글꼴에서 읽음
  contentWidth = 240, -- 최초 실행의 기본 블록 폭에서 읽음
  collapsedRegions = { ["header:은빛소나무 숲"] = true },
}
```

기존 자동 선택·화살표·위치·반납 안내 설정을 초기화하지 않습니다. 별도 SavedVariables 전역을 추가하지 않았으며, 접힘 상태는 같은 DB에 저장되어 `/reload`·재접속 후 다시 읽습니다. 실제 클라이언트 저장·복원은 인게임 체크리스트 대상입니다.

## 13. CPU / 메모리

새 상시 OnUpdate / Quest Log polling / 타이머를 추가하지 않았습니다. 기본 추적기의 Quest Watch·Quest Log·POI·완료 이벤트, 설정 변경, 헤더 클릭, 전투 종료를 사용합니다. 다른 모듈만 Dirty이며 기존 퀘스트 배치를 그대로 사용할 수 있으면 수집·정렬을 생략합니다. 처리량은 추적 대상 W에 대해 수집 O(W), 정렬 O(W log W) 수준입니다. 헤더는 슬롯 재사용, 퀘스트·목표·아이템은 기본 풀을 사용합니다. 모의 반복 검사에서 접기·펼치기 50회와 Watch 변경 100회 동안 프레임 수가 반복마다 증가하지 않았습니다. 실제 장시간 게임 메모리 측정은 하지 않았습니다.

## 14. 정적·모의 검증 결과

- STATIC CHECK: PASS
- Lua 5.1 문법: 전체 55개 파일 PASS
- TOC: 51개 로드 파일 존재 PASS
- 실제 Forever 기본 Block / Module / QuestObjectiveTracker Lua를 실행한 모의 검증: 55개 PASS
- 지역 순서, 안정 정렬, Watch 필터, 캠페인 제외, 태그 우선순위·난이도 색상, 접힘 공간 제외, native completion 상태, 글씨·폭 재측정, 아이템 여백, 진행률 막대 폭, 풀 재사용, 변경 없는 Dirty 배치 생략, 전투 보류·복원, 기본 메서드 복원, 기존 설정 보존을 검사했습니다.
- 화면 렌더링, 실제 UI 상호작용, secure/taint, 실제 아이템 사용, `/reload`·재접속은 실행하지 않았습니다.
- `KHQOL-1.9.5-validation.json`에 검사 목록, `KHQOL-1.9.5-manifest.json`에 ZIP 해시와 기준본 대비 파일별 변경/보존 결과를 기록합니다.

## 15. 실제 Forever에서 반드시 확인할 항목

1. 지역 헤더가 기본 Objective Tracker의 높이 제한·전체 접기·Edit Mode·퀘스트 추가 팝업·완료 애니메이션과 공존하는지.
2. 아이템이 있는 퀘스트를 전투 중 추적/해제·완료·포기하고 설정/지역 접힘도 변경했을 때, 종료 후 배치와 아이템 대상이 정확하며 blocked action/taint가 없는지.
3. 한국어 긴 제목·목표, Font 10/20, Width 200/500, UI Scale·추적기 배율별 잘림·겹침 여부.
4. 오른쪽 끝을 유지하는 폭 조절이 사용자의 추적기 위치에서 다른 UI와 겹치지 않는지.
5. 재접속 저장, 퀘스트 좌/우클릭·링크·공유·상세·지도·수동 Navigation 선택 유지 여부.

## 16. 인게임 테스트 체크리스트

아래 모든 항목의 상태는 **NEEDS TEST**입니다.

- [ ] 1. 서로 다른 3개 Quest Log 지역의 추적 퀘스트가 3개 그룹으로 표시됨
- [ ] 2. 같은 지역 18/12/15 레벨이 12/15/18로 표시됨
- [ ] 3. 같은 레벨은 원래 Quest Watch 순서를 유지함
- [ ] 4. 지역 헤더 클릭으로 접힘
- [ ] 5. 접힌 지역의 퀘스트가 배치 공간을 차지하지 않음
- [ ] 6. 다시 클릭하면 정상 펼침
- [ ] 7. `/reload` 및 재접속 후 지역 접힘 유지; 지도 헤더와 독립
- [ ] 8. 전투 밖 추적 해제 시 다음 기본 Dirty 갱신에서 즉시 제거됨
- [ ] 9. 새 추적 퀘스트가 올바른 지역·레벨 위치에 삽입됨
- [ ] 10. 일반 퀘스트가 `[16] 제목` 형식으로 표시됨
- [ ] 11. 정예 퀘스트가 `[15] [정예] 제목` 형식으로 표시됨
- [ ] 12. 던전 퀘스트가 `[15] [던전] 제목` 형식으로 표시됨
- [ ] 13. 던전+정예는 던전 태그만 표시하며 태그 옵션도 적용됨
- [ ] 14. 글씨 증가 시 제목·목표·전체 높이가 늘고 겹치지 않음
- [ ] 15. 글씨 감소 시 배치 높이가 줄어듦
- [ ] 16. 폭 증가 시 줄바꿈이 감소하고 다음 블록 위치가 재계산됨
- [ ] 17. 폭 감소 시 줄바꿈이 증가하고 잘리지 않음
- [ ] 18. 아이템 버튼·HotKey·목표·진행률 막대 겹침 및 잘림 없음
- [ ] 19. 제목 좌클릭·Modified Click·퀘스트 링크·상세·지도 동작 유지
- [ ] 20. 제목 우클릭 메뉴·추적 해제·공유 동작 유지
- [ ] 21. 전투 밖 목표 진행이 기본 이벤트로 갱신되며, 전투 중 보류분은 종료 후 반영됨
- [ ] 22. 완료·Ready for Turn-In·Completion/Waypoint Text 정상 표시
- [ ] 23. 반납 후 목록 정리 및 기존 반납/자동 Navigation 동작 유지
- [ ] 24. 업적·시나리오·캠페인·보너스·월드 퀘스트·전문기술 추적과 다른 KHQOL 모듈 유지
- [ ] 25. 전투 중 아이템 사용·cooldown·tooltip 유지, 변경 보류 및 종료 후 적용, blocked action/taint 없음
- [ ] 26. 추적 추가/제거·접기/펼치기 장시간 반복 시 프레임/메모리 지속 누적 없음

## 설치

ZIP 내부 `KHQOL` 폴더를 기존 애드온 폴더에 덮어쓰고 `/reload`하세요. SavedVariables를 삭제할 필요가 없습니다. Quest Navigator 모듈을 켜야 목록 표시 개선이 적용됩니다. 모듈 OFF 시 기본 추적기로 돌아갑니다.

## 확인한 Forever 공개 UI 소스

참조 브랜치: `forever`, 커밋 `15666a6e67938a1ab5caf041406464251db111ca`, 버전 `1.60.1.70245`. 최신 Retail 브랜치를 기준으로 구현하지 않았습니다. 공개 소스를 읽어 기존 API·배치에 맞춰 연결했으며 Blizzard 런타임 소스를 애드온 ZIP에 복사해 넣지 않았습니다.

- [Quest Log API / QuestInfo 구조](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua)
- [기본 Quest Objective Tracker](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_ObjectiveTracker/Blizzard_QuestObjectiveTracker.lua)
- [기본 Module의 높이·블록·풀·배치](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_ObjectiveTracker/Blizzard_ObjectiveTrackerModule.lua)
- [기본 Block의 글씨 측정·아이템 여백](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_ObjectiveTracker/Blizzard_ObjectiveTrackerBlock.lua)
- [Forever 지도 레벨·정예 제목](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_UIPanels_Game/Camelot/QuestMapFrameOverrides.lua)
- [기존 레벨·난이도 색상 함수](https://github.com/Gethe/wow-ui-source/blob/15666a6e67938a1ab5caf041406464251db111ca/Interface/AddOns/Blizzard_FrameXMLUtil/Mainline/DifficultyUtil.lua)


---

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
