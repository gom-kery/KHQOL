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

# KHQOL 1.9.7.2 — 회색 버튼 / 절제된 강조색

1.9.7.1을 기준으로 회색 평면 버튼을 유지하면서 현재 페이지·섹션 제목, 선택 메뉴, ON 표시와 슬라이더 손잡이에 차분한 청록색 #72ADA5를 적용했습니다. 일반 버튼·OFF·비활성 상태·배경은 기존 회색으로 유지합니다.

기존 HUD·사용자 색상·레이아웃·옵션·프로필·노트·등록 데이터·위치 편집 기능을 보존합니다. 새 이미지·저장 키·옵션·마이그레이션은 없습니다.

전체 ZIP의 KHQOL 폴더를 기존 Interface/AddOns/KHQOL에 덮어쓰고 /reload하세요. SavedVariables는 삭제하지 마세요.

정적·모의 검사 20개 항목 및 ZIP 무결성 PASS. 실제 인게임 검증은 미실시입니다. 모의 프리뷰는 실제 게임 화면이 아닙니다. 상세: [1.9.7.2 변경·검증 보고서](RELEASE-1.9.7.2.md).

---

# KHQOL 1.9.7.1 — 회색 설정 테마 / 버튼 스킨 수정

1.9.7 전체 배포본을 기준으로 설정·위치 편집 UI의 민트색을 밝은 회색으로 변경했습니다. 공통 버튼에서 Forever 기본 붉은 배경 템플릿을 제거하고, 평면 배경·회색 테두리·전용 상태별 글꼴을 적용했습니다. 기본·오버·눌림·선택·비활성 상태를 함께 처리합니다.

기존 레이아웃·옵션·HUD 외형과 사용자 색상·SavedVariables·프로필·노트·등록 데이터·위치 편집 기능을 유지합니다. 새 이미지·외부 의존성·설정 마이그레이션은 없습니다.

기존 `Interface/AddOns/KHQOL` 폴더에 전체 ZIP의 KHQOL 폴더를 덮어쓰고 `/reload`하세요. SavedVariables는 삭제하지 마세요.

정적·모의 검사 21개 항목 PASS. 실제 Forever 인게임 검증은 미실시입니다. 원인·수정 파일·검증과 실제 확인 항목은 [1.9.7.1 보고서](RELEASE-1.9.7.1.md)에 정리했습니다. 모의 프리뷰는 실제 게임 화면이 아닙니다.

---

# KHQOL 1.9.7 — 설정 UI 통합 디자인 / 통합 위치 편집

기준 버전은 1.9.6.1입니다. 모든 설정 페이지를 차콜·청록색 공통 디자인으로 정돈하고, 활성화된 화면 요소를 함께 이동할 수 있는 위치 편집 모드를 추가했습니다. 게임 화면 HUD의 기존 외형, 설정값, 등록 버프, 노트와 기존 프로필 기능은 유지합니다.

설정창 상단 또는 일반 탭의 **위치 편집** → 이름이 표시된 테두리 드래그 → **완료 / 잠금**으로 저장합니다. **취소 / ESC**는 변경을 버립니다. 겹친 요소는 편집 도구창의 목록에서 선택합니다. 연결된 시전바와 미니맵 버튼은 기존 연결 방식으로 움직입니다. 전투 중에는 진입할 수 없으며 편집 중 전투가 시작되면 취소합니다.

기존 `Interface/AddOns/KHQOL` 폴더에 이 ZIP의 `KHQOL` 폴더를 덮어쓰고 `/reload`하세요. SavedVariables를 삭제하지 마세요. 외부 참고 애드온은 필요하지 않습니다.

정적·모의 검사 15개 항목 PASS. 실제 Forever 인게임 검증은 미실시입니다. 모의 화면은 실제 게임 화면이 아닙니다. 지원 대상, 저장 키, 변경 파일, 확인 항목은 [1.9.7 변경·검증 보고서](RELEASE-1.9.7.md)에 정리했습니다.

---

# KHQOL 1.9.6.1 — 프로필 탭 분리

1.9.6을 기준으로 프로필 관리 설정을 일반 탭에서 별도 **프로필** 탭으로 옮겼습니다. 왼쪽 메뉴에서 일반 바로 아래에 표시합니다. 일반 탭의 모듈 관리와 공통 옵션은 그대로 유지합니다.

프로필 탭에서 활성 프로필 선택·기본값 생성·현재 프로필 복사·삭제를 사용합니다. 모듈 사용 체크박스나 모듈 초기화 버튼은 표시하지 않습니다. 저장 구조와 기존 프로필·캐릭터 선택·사용자 데이터는 변경하지 않습니다.

기존 KHQOL 폴더를 덮어쓰고 `/reload`하세요. SavedVariables는 삭제하지 마세요. Lua 5.1 문법·모의 검사·ZIP 무결성 PASS, 실제 게임 화면은 NEEDS TEST입니다. [프로필 보고서](PROFILES.md)를 참고하세요.

아래는 이전 버전 기록입니다.

---

# KHQOL 1.9.6 — 계정 공용 프로필

기준: 사용자 첨부 KHQOL-1.9.5.7.zip. 일반 탭 상단에서 계정 공용 프로필을 생성·복사·선택·삭제할 수 있습니다. 캐릭터마다 사용할 프로필을 선택하며 같은 프로필이면 설정을 공유합니다. 최초 적용 시 기존 설정을 `기본`으로 보존합니다.

새 이름 입력 → 기본값으로 생성 / 현재 프로필 복사 → 즉시 전환. 삭제는 확인 후 실행하고 연결된 캐릭터를 기본으로 돌립니다. 기본은 삭제할 수 없습니다. 정상 전환에 리로드는 필요하지 않으며 전투 중 변경은 차단합니다. 노트/ToDo 완료 상태/등록 버프/직업별 사거리 기준 주문은 전환해도 유지합니다.

기존 KHQOL 폴더를 덮어쓰고 `/reload`하세요. SavedVariables를 삭제하지 마세요. 적용 전 게임 종료 후 SavedVariables 백업을 권장합니다. 구조·마이그레이션·변경 파일·검증·인게임 체크리스트는 [프로필 보고서](PROFILES.md)를 확인하세요. 실제 게임 검증은 NEEDS TEST입니다.

아래는 이전 버전 기록입니다.

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

# KHQOL 1.9.5.6 — 인스턴스 역할별 위협 표시

1.9.5.5에 던전·레이드 역할별 위협 표시와 음성 사용 설정을 추가했습니다.

`/khqol threat` → **인스턴스 내 위협 수치 설정**

```text
[ ] 탱    [✓] 딜    [✓] 힐
```

체크한 역할일 때만 실제 위협 수치·대상명·아이콘·하단 안내와 95% 경고 음성이 작동합니다. 기본값은 탱 OFF, 딜·힐 ON이며 모두 해제하면 던전·레이드의 실제 표시와 음성을 중지합니다. 음성 전체 ON/OFF 설정도 계속 적용됩니다.

역할은 파티에 지정된 역할을 우선 사용하고, 미지정이면 활성 전문화로 확인합니다. 자동 인식이 안 되면 같은 섹션의 **역할 판정**에서 탱·딜·힐을 직접 선택하세요. 역할을 확인할 수 없는 경우에는 숨기며, 세 역할을 모두 체크하면 역할 미확인 상태에서도 기존 표시 조건을 따릅니다.

필드의 기존 파티/공격대·솔로 펫 표시 조건은 유지합니다. 위치 미리보기와 가상 테스트는 역할 제한과 관계없이 사용할 수 있으며 무음입니다. 실제 경고는 기존처럼 95% 이상 도달 시 한 번, 음량은 와우 소리 설정의 대화 음량을 따릅니다. 별도 재생 간격 제한은 추가하지 않았습니다.

ZIP의 `KHQOL` 폴더를 기존 애드온 폴더에 덮어쓰고 `/reload`하세요. SavedVariables 삭제는 필요하지 않습니다. 기존 설정과 다른 모듈은 보존합니다.

397개 정적·모의 검사와 전체 55개 Lua 문법 검사 PASS. 실제 게임에서 역할 인식·표시·음성 확인이 필요합니다. [변경 보고서](THREAT.md). 아래는 이전 기록입니다.

---

# KHQOL 1.9.5.5 — 어그로 95% 경고 음성

사용자 제공 `KHQOL-1.9.5.4.zip`을 기준으로, 음성 알림 시점을 어그로 획득에서 **어그로 수치 95% 이상 도달**로 변경했습니다. 기존 음성과 Note 미니맵 아이콘을 포함한 다른 기능은 보존합니다.

- 실제 전투에서 현재 대상의 전환 기준 대비 퍼센트가 95% 이상에 도달하면 한 번 재생합니다. 94%에서 96% 등으로 건너뛰어도 감지합니다.
- 95% 이상 상태가 유지되거나 이후 어그로를 획득해도 반복하지 않습니다. 어그로를 보유하지 않은 상태로 95% 아래까지 내려갔다가 다시 도달하면 재생합니다.
- 전투 시작부터 100% 어그로 보유인 경우는 기존처럼 무음입니다. 가상 테스트와 위치 미리보기에서도 재생하지 않습니다.
- `/khqol threat` → **위협 수준 알림 → 어그로 95% 경고 음성**에서 켜고 끕니다. 이전 음성 ON/OFF 설정을 그대로 사용합니다.
- 음량은 **와우 소리 설정 → 대화 음량**에서 조절합니다. Dialog 채널을 사용하며 애드온이 게임 음량을 덮어쓰지 않습니다.

ZIP의 `KHQOL` 폴더를 기존 애드온 폴더에 덮어쓰고 `/reload`하세요. SavedVariables 삭제는 필요하지 않습니다.

309개 정적·모의 검사와 전체 55개 Lua 문법 검사 PASS. 실제 게임에서의 음성 출력과 대화 음량 반영은 확인이 필요합니다. [변경 보고서](THREAT.md). 아래는 이전 버전 기록입니다.

---

# KHQOL 1.9.5.3 — 어그로 획득 음성

사용자 제공 `KHQOL-1.9.5.2.zip`에 어그로 전환 음성을 추가했습니다. 1.9.5.2의 퀘스트 제목 표기·설정과 지역 헤더 등 다른 모듈의 변경 사항은 그대로 유지합니다.

- 실제 전투에서 현재 대상의 위협 상태가 **위험 → 어그로 보유**로 바뀔 때 첨부된 `aggro.wav`를 한 번 재생합니다. 보유 상태가 유지되는 동안 반복하지 않습니다.
- 전투 시작부터 어그로를 보유한 경우, 대상 변경 후 이미 어그로를 보유한 경우, 가상 테스트와 위치 미리보기에서는 재생하지 않습니다.
- 어그로를 잃고 다시 위험 상태를 거쳐 획득하면 해당 전환에 한 번 다시 재생합니다. 여유·주의에서 바로 보유로 바뀌는 경우는 재생하지 않습니다.
- `/khqol threat` → **위협 수준 알림 → 어그로 획득 음성**에서 켜고 끕니다. 기본값은 켜짐이며 아이콘 표시와 별도로 작동합니다. 게임의 대화(Dialog) 소리 채널을 사용합니다.

ZIP 안의 `KHQOL` 폴더를 기존 애드온 폴더에 덮어쓰고 게임에서 `/reload`하세요. SavedVariables 삭제는 필요하지 않습니다. 음성 파일도 함께 복사해야 합니다.

전체 55개 Lua 문법 검사와 정적·모의 검사 288개를 통과했습니다. 실제 게임에서의 재생은 확인이 필요합니다. [변경 내용과 게임 확인 항목](THREAT.md). 아래는 이전 버전 기록입니다.

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

# KHQOL 1.9.5 — 퀘스트 목록 지역별 그룹화

기준본: 사용자 제공 KHQOL-1.9.4.zip.

`/khqol quest` → **퀘스트 목록 표시**에서 지역별 그룹화·접기, [던전]·[정예] 표시, 글씨 크기 10~20, 내용 표시 폭 200~500을 조절합니다. 지역은 Quest Log 헤더 순서로, 지역 내부는 낮은 레벨부터 표시합니다. 추적 중인 퀘스트만 사용하고 기존 기본 블록의 클릭·우클릭·아이템·완료 표시를 재사용합니다.

첫 글씨 크기와 폭은 기본 추적기에서 읽습니다. 지역 접힘은 저장되며 지도 헤더 접힘이나 Watch 상태를 변경하지 않습니다. 전투 중에는 퀘스트 목록·진행·설정의 구조 갱신을 보류하고 전투 종료 후 적용합니다. 기존 Arrow·자동 선택·반납 Navigation 계산은 유지합니다.

ZIP 내부 KHQOL 폴더를 덮어쓰고 `/reload`하세요. SavedVariables를 삭제할 필요가 없습니다. Quest Navigator 모듈을 켜면 적용되며 OFF 시 기본 배치를 복원합니다. `/khqol quest layout`으로 배치 정보를 확인할 수 있습니다.

STATIC CHECK: PASS — 모의 검사 55개, 전체 Lua 55개 문법 및 TOC 검사. IN-GAME: NEEDS TEST — 실제 Forever 화면과 전투 중 보호 동작은 실행 검증하지 않았습니다. [변경 보고서 및 인게임 체크리스트](QuestNavigator/README.md)를 확인하세요.

---

# KHQOL 1.9.4 — 위협 아이콘 크기·위치·표시 단계

기준본: 사용자 제공 KHQOL-1.9.3.zip.

`/khqol threat` → **위협 수준 알림**에서 위협 아이콘 ON/OFF, 독립 크기 12~32, 수치 앞/수치 위 위치, 주의 단계 표시를 설정합니다. 기본은 위험 + 어그로 보유 단계이며 주의 표시는 OFF입니다. 새 프로필의 아이콘 크기는 18, 위치는 수치 앞입니다. 기존 사용자는 첫 적용 시 기존 글씨 크기에 가까운 아이콘 크기를 한 번 저장합니다.

현재 선택한 적의 화면 독립 표시창과 수치/퍼센트 계산, 색상, 글씨 크기, 화면 위치, 0.20초 갱신 및 파티/펫 조건을 유지합니다. 위 배치에서는 아이콘과 대상명이 겹치지 않도록 위쪽 공간을 확보하며 수치 중심 좌표는 유지합니다.

`/khqol threat test 0`, `1`, `2`, `3`으로 여유·주의·위험·어그로 보유 상태를 확인합니다. 인수 없는 `test`는 기존처럼 테스트를 켜고 끕니다. 색상과 아이콘은 기존 리소스를 재사용합니다.

ZIP의 KHQOL 폴더를 기존 애드온 폴더에 덮어쓰고 `/reload`하세요. SavedVariables를 삭제할 필요가 없습니다. 1.9.3의 Quest Navigator·ForeverNote·PvP Alert 등 다른 모듈과 미디어를 그대로 보존합니다.

정적·모의 검사 251개 및 전체 55개 Lua 5.1 문법/TOC 검사 PASS. 인게임 검증 NEEDS TEST. [수정 보고서 및 인게임 체크리스트](THREAT.md)를 확인하세요. 아래는 이전 버전 기록입니다.

---

# KHQOL 1.9.3 — 추적 중인 퀘스트만 자동 선택 / 완료 후 동작 선택

기준본: 사용자 제공 KHQOL-1.9.2.zip. Quest Navigator v0.2.0.

자동 선택은 게임 목표 추적창에 등록된 미완료 퀘스트만 사용합니다. 추적 해제는 즉시 후보에서 제외합니다. 기존 난이도·거리 우선순위는 유지합니다.

`/kh quest` → 추적 → 퀘스트 완료 후에서 반납 위치 안내 / 다음 추적 퀘스트 자동 선택을 고릅니다. 새 설정은 반납 안내가 기본이며, 기존 autoTrack=true 저장 설정은 자동 전환을 유지합니다. 완료 퀘스트를 직접 선택하면 모드와 관계없이 반납 안내를 우선합니다. 반납 위치를 확인할 수 없거나 이전 목표와 구분할 수 없으면 화살표를 숨깁니다.

`/khqol quest status`로 현재 추적 목록·완료 상태·후보·위치를 확인할 수 있습니다. ZIP 내부 KHQOL 폴더를 덮어쓰고 `/reload`하세요. SavedVariables를 삭제할 필요가 없습니다. 기존 화살표/거리/위치, ForeverNote와 다른 모듈·미디어는 유지합니다.

정적·모의 검증 108/108, 55개 Lua 5.1 문법/TOC 및 공통 설정 UI 검사 PASS. 인게임 검증 NEEDS TEST. [수정 보고서와 인게임 체크리스트](QuestNavigator/README.md)를 확인하세요. 아래는 이전 기록입니다.

---

# KHQOL 1.9.0 — 내부 리팩토링 / 위치 설정 상단 배치

기준 패키지: 사용자가 제공한 KHQOL-1.8.9-GeneralConvenience.zip.

위치를 조절할 수 있는 각 모듈은 제목·설명·모듈 ON/OFF 아래의 첫 상세 섹션에
위치 설정을 표시합니다. Tooltip, Quest Navigator, Threat, PvP Alert를 재배치했으며,
Resource Swing의 탄약 위치 섹션도 주 위치 설정 바로 다음으로 옮겼습니다.
이미 위치 설정이 상단인 모듈은 유지했습니다. Todo와 Cursor Trail에는 위치 항목을
새로 추가하지 않았습니다. 아이콘·텍스트의 내부 정렬 옵션은 해당 모양 섹션에 유지합니다.

모듈 활성화 전달, 공통 기본값 처리, 명령어·초대·아이템 필드 조회 상수,
마우스오버 사거리 표시의 레이아웃 캐시와 모닥불 OFF 중복 정리를 정리했습니다.
기능, 저장 변수/기본값/위치, 리소스와 게임 내 표시 방식은 유지합니다.
잡템 자동 판매·판매 금액 출력·자동 수리·길드 자금 우선·초대 거절도 그대로 포함됩니다.

ZIP 안의 KHQOL 폴더로 기존 애드온을 교체하고 /reload하세요.
SavedVariables를 삭제하거나 설정을 초기화할 필요가 없습니다.
전체 Lua 55개 문법 검사와 15개 정적·모의 검증 항목: PASS.
실제 WoW Forever 화면·보호 프레임·게임 API 응답은 NEEDS TEST입니다.
아래 내용은 이전 릴리스 기록입니다.

---

# KHQOL 1.8.7 — 퀘스트 난이도 우선 추적

기준본: KHQOL-1.8.6-CompactGeneralUI.zip.

Quest Navigator의 완료 후 다음 퀘스트 자동 선택 순서: **초록(회색 포함) → 노랑 → 주황 → 빨강 → 던전**. 같은 순위에서는 가까운 퀘스트를 선택합니다. 같은 지역 우선 옵션을 켜면 같은 난이도 순위 안에서 지역을 먼저 비교합니다. 수동 선택한 목표의 안내와 기존 설정은 유지합니다.

ZIP 안의 KHQOL 폴더를 덮어쓰고 `/reload`하세요. 저장 설정을 삭제할 필요가 없습니다. 1.8.6의 PvP Alert, Threat, 입체 화살표, 야드·미터 및 압축된 일반 설정 간격을 보존했습니다.

76개 모의 검사, 전체 55개 Lua 5.1 문법/TOC, 최신 공통 설정 UI 검사 PASS. 실제 게임에서의 이번 자동 선택은 미확인입니다. [Quest Navigator 설명과 검증](QuestNavigator/README.md)을 확인하세요. 아래는 이전 버전 기록입니다.

---

# KHQOL 1.8.6 — 일반 설정 간격 조정

기준본: KHQOL-1.8.5-PvPAlert-v0.1.zip.

왼쪽 메뉴의 모듈 사이 빈 간격을 기존의 1/2로, 일반 탭 모듈 관리의 행 사이 빈 간격을 기존의 1/3로 줄였습니다. 버튼·체크박스 크기, 모듈 이름·정렬·3열 배치, 일반 탭 구분선과 각 모듈의 세부 설정은 유지합니다.

ZIP의 KHQOL 폴더를 기존 애드온 폴더에 덮어쓰고 `/reload`하세요. SavedVariables를 삭제할 필요가 없습니다. 첨부 1.8.5의 PvP Alert를 포함한 모든 기능 모듈과 미디어를 보존합니다. 설정창과 애드온 메타데이터의 버전은 1.8.6입니다.

전체 55개 Lua 파일의 문법, 모의 UI의 간격·체크박스·메뉴 이동, 원본 95개 파일 보존 여부를 확인했습니다. 실제 게임 화면의 렌더링은 적용 후 확인이 필요합니다. 아래는 이전 버전 기록입니다.

---

# KHQOL 1.8.4 — 어그로 표시 옵션과 아이콘

`/khqol threat` 설정에 **대상명 표시**와 **하단 어그로 안내 표시**를 추가했습니다. 각각 켜거나 끌 수 있으며 변경 즉시 적용하고 저장합니다. 기본값은 둘 다 켜짐입니다.

수치 왼쪽에 첨부된 아이콘을 표시합니다: 주의(70% 이상) — threat-caution-yellow, 위험(90% 이상) — threat-danger-orange, 실제 어그로 보유 — threat-aggro-red. 여유 단계에서는 아이콘을 숨깁니다. 아이콘은 글씨 크기와 같은 크기로 연동하며 원래 색을 유지합니다.

ZIP의 KHQOL 폴더를 덮어쓰고 `/reload`하세요. 새 아이콘 파일 3개가 Media 폴더에 포함되어 있습니다. 기존 화면 위치·글씨 크기·퍼센트 표시 및 다른 설정을 보존합니다. `/khqol threat`의 색상 테스트로 단계별 아이콘을 확인할 수 있습니다.

175개 정적·모의 검사 및 전체 49개 Lua 5.1 문법 PASS. 실제 게임의 이번 아이콘 렌더링과 옵션 저장 검증은 NEEDS TEST입니다. 자세한 내용은 [Threat 보고서](THREAT.md)를 확인하세요. 아래는 이전 버전 기록입니다.

---

# KHQOL 1.8.3 — 전투 중 어그로 표시 수정

공격 가능한 중립 몬스터가 실제 전투의 표시 대상에서 제외되던 조건을 수정했습니다. 테스트가 보이지만 실제 전투에서 숨겨지는 증상과 관련된 코드 경로입니다. NPC 판별의 정상적인 nil 반환도 처리하고, 제한된 어그로 보유 플래그가 읽을 수 있는 퍼센트까지 무효화하지 않도록 보완했습니다.

ZIP의 KHQOL 폴더를 덮어쓰고 `/reload`하세요. 위치·글씨 크기·퍼센트 표시 방식과 다른 모듈 설정을 유지합니다. 실제 전투 중 적을 선택한 상태에서 표시를 확인하세요.

계속 표시되지 않으면 `/khqol threat status`와 `/khqol threat debug`를 실행하세요. 버전, 대상 제외 사유, 전투 조건, 퍼센트 반환값을 출력하도록 진단을 보강했습니다.

140개 정적·모의 검사 및 전체 49개 Lua 5.1 문법 PASS. 이번 수정의 실제 게임 검증은 NEEDS TEST입니다. 자세한 설명은 [Threat 보고서](THREAT.md)를 확인하세요. 아래는 이전 버전 기록입니다.

---

# KHQOL 1.8.2 — 어그로 퍼센트 표시

현재 선택한 적에 대한 내 어그로를 **전환 기준 대비 0~100%**로 표시합니다. 70%부터 노란색 주의, 90%부터 주황색 위험, 이미 어그로를 보유한 경우 빨간색으로 안내합니다. 70%와 90%는 KHQOL 안내 구간입니다.

기존 사용자도 첫 적용 시 퍼센트 표시로 전환됩니다. 화면 위치, 글씨 크기, 잠금, 색상 옵션과 다른 모듈 설정은 보존합니다. 이후 표시 방식을 직접 바꾸면 그 선택을 유지합니다.

ZIP의 KHQOL 폴더를 기존 애드온 폴더에 덮어쓰고 `/reload`하세요. SavedVariables를 삭제할 필요가 없습니다. `/khqol threat`에서 위치와 표시 방식을 조절할 수 있습니다.

128개 정적·모의 검사와 전체 49개 Lua 5.1 문법 검사 PASS. 실제 게임에서의 이번 버전 검증은 NEEDS TEST입니다. 자세한 설명은 [Threat 보고서](THREAT.md)를 확인하세요. 아래는 이전 버전 기록입니다.

---

# KHQOL 1.8.1 — 화면 독립 어그로 표시

현재 선택한 적 한 마리에 대한 내 Threat를 원하는 화면 위치에 표시합니다. 기본 위치는 화면 중앙 아래 120입니다.

`/khqol threat` → 위치 잠금 해제 → 드래그 → 잠금 순서로 배치하거나 X/Y 숫자를 입력하세요. `/khqol threat unlock`, `lock`, `reset` 명령도 지원합니다. `/khqol threat test`는 실제 표시 위치에서 가상 데이터를 보여줍니다.

표시창은 KHQOL 자체 화면 프레임이며 이름표와 체력바에 연결하지 않습니다. Platynator가 Blizzard 체력바를 숨기는 구조에 의존하지 않습니다. 파티/공격대 또는 허용된 솔로 사냥꾼·흑마법사 + 살아 있는 펫 조건과 전투 중 갱신 규칙은 유지했습니다.

기존 설정과 다른 기능 모듈을 보존했습니다. 108개 정적·모의 검사 및 전체 49개 Lua 5.1 문법 검사는 PASS입니다. 실제 Forever + Platynator 조합 검증은 NEEDS TEST입니다.

자세한 사용법과 인게임 체크리스트는 [Threat 보고서](THREAT.md)를 확인하세요. 아래 내용은 이전 버전의 기록입니다.

---

# KHQOL 1.8.0 — Threat

기준본: 사용자 제공 KHQOL-1.7.4-QuestNavigator-3DArrow.zip.

적대적 NPC 이름표 체력바 위에 플레이어 자신의 어그로 수치/비율을 표시하는 Threat 모듈을 추가했습니다. 파티·공격대 또는 솔로 사냥꾼/흑마법사 + 살아 있는 펫 조건에서 전투 중에만 갱신합니다.

설정: `/khqol threat`. 테스트: `/khqol threat test`. 진단: `/khqol threat status`, `/khqol threat debug`. 글씨 크기, X/Y 위치, 상태 색상과 솔로 펫 조건을 즉시 변경할 수 있습니다.

기존 SavedVariables, 기능 모듈과 미디어는 유지했습니다. 정적·모의 검증 102개 및 Lua 5.1 문법 검사는 PASS이며, 실제 Forever 클라이언트 검증은 NEEDS TEST입니다. 수치는 API 원시 Threat 단위이며 임의의 배율 변환을 적용하지 않습니다.

구현, API 호환성, 변경 파일과 인게임 체크리스트는 [Threat 보고서](THREAT.md)를 확인하세요. 아래는 이전 버전의 안내입니다.

---
# KHQOL 1.7.4 — Quest Navigator v0.1.4

베이스: KHQOL-1.6.6-HunterRangeFallback.zip.

현재 Super Tracking 퀘스트의 목표가 완료되면 짧은 완료 표시 후 가장 가까운 미완료 퀘스트를 선택합니다. 같은 UI Map에서 캐릭터 방향 기준의 독립 화살표 HUD, 거리, 제목과 대표 진행도를 표시합니다.

경로 API가 좌표를 반환하지 않으면 현재 지도에서 같은 퀘스트 ID의 지역 마크를 조회하여 안내합니다. 기존 경로 → 지도별 경로 → 퀘스트 지역 마크 순서로 사용하며, 지역 마크까지 없으면 “경로 없음”을 유지합니다. WaypointUI 없이 작동하고 사용자 핀을 생성하지 않습니다. 지역 마크는 수행 지역의 대표 위치이므로 개별 목표의 정확한 위치와 다를 수 있습니다.

목표 텍스트 + 숫자 모드에서 게임이 설명 앞이나 뒤에 제공하는 진행 숫자를 제거해 “우두머리 초원늑대 이빨 1 / 8”처럼 한 번만 표시합니다. 숫자만 모드와 설정값은 유지합니다.

화살표를 회전한 뒤 세로 방향을 눌러 바닥에 놓인 방향표처럼 표시하고, 어두운 금색 옆면과 그림자로 두께를 표현합니다. 새 ArrowSide.tga 리소스로 입체 표현을 만들며 0°에서는 옆면·그림자를 숨깁니다. `/kh quest` → 화살표 → 화살표 눕힘 각도에서 0~70°로 조절합니다(기본 55°, 0°는 기존 모양). 표시 → 거리 단위에서 야드(yd) / 미터(m)를 선택합니다. 기본 단위는 야드이며 1 yd = 0.9144 m로 환산합니다.

설정: `/kh quest` 또는 KHQOL 설정 → Quest Navigator. 위치 잠금을 해제하여 이동할 수 있습니다. 고급 갱신 주기는 기본 접혀 있습니다.

기존 1.6.6의 사냥꾼 사거리 폴백, 툴팁 성능 수정과 다른 모듈 코드·미디어를 보존했습니다. 기존 SavedVariables를 그대로 사용합니다.

모의 검사 61/61 및 기존 설정/Range/Tooltip 회귀 검사를 통과했습니다. 사용자 진단에서 퀘스트 759의 지역 마크 좌표 반환을 확인했습니다. 수정한 HUD의 실제 Forever 게임 테스트는 아직 실행하지 않았습니다. 구현 상세와 실게임 테스트 순서는 [Quest Navigator 보고서](QuestNavigator/README.md)를 확인하세요.

---

# KHQOL 1.6.6 — Hunter Melee Range Fallback

1.6.5를 기준으로 원거리 밖/근거리에서 근거리 검사 실패가 전체 ‘판정 불가’로 이어지는 경로를 보완했습니다.

- 원거리 검사가 가능하면 초록입니다. 원거리는 밖이지만 확인된 근거리 범위이면 초록입니다. 둘 다 밖인 먼 거리이면 빨강입니다. 사용자 지정 문구와 표시 문자/색상은 그대로 사용합니다.
- 새 C_SpellBook 주문책/사거리 API를 추가 지원합니다. 기본 ID가 아닌 실제 습득한 랭크 ID를 찾아 검사하며, 주문책은 캐시하고 SPELLS_CHANGED 때 갱신합니다.
- 랩터의 일격을 활성화할 수 있다는 결과만으로 근거리라고 판단하지 않습니다. 날개 절단 검사가 불가능하면 독립적인 5야드 아이템 사거리 조회로 보완합니다. 아이템을 실제로 사용하거나 소비하지 않습니다.
- 근거리 검사가 불가능해도 원거리가 밖이고 근접 보조 범위 밖으로 확인되면 빨강을 유지합니다. 가까운지 모르는 상태를 임의로 초록으로 바꾸지는 않습니다.
- 기존 데드존 감지/색상과 ‘근거리 공격도 가능으로 판정’ OFF의 원거리 전용 동작은 유지합니다.
- `/frange api` 또는 Range 설정의 ‘API 상태’에서 대상/마우스오버별 원거리·근거리·확인 경로와 최종 판정을 한 번 출력합니다.

모의 검사에서는 전투 중 먼 거리/원거리/근거리의 사용자 지정 문구와 + 색상 검증을 통과했습니다. 실제 Forever 클라이언트의 새 주문책/아이템 API 응답은 설치 후 확인해야 합니다. 모든 검사 결과가 없거나 보호 값이면 ‘판정 불가’가 남을 수 있습니다. 1.6.5의 Tooltip/캐스팅바/전투 알림 최적화 파일은 변경하지 않았습니다.

## KHQOL 1.6.5 — Cast Interaction Names / Tooltip Performance (historical)

1.6.4를 기준으로 채집/열기 캐스팅의 불필요한 이름 표시와 적 툴팁의 반복 갱신 비용을 줄였습니다.

- 퀘스트 물체 획득에 사용되는 열기(3365), Opening - No Text(22810) 계열은 이름만 숨깁니다. 진행 바, 남은 시간, 아이콘은 유지합니다. ID가 없는 클라이언트에서는 동일한 영문/현지화 이름도 확인합니다. 일반 주문, 채광 같은 별도 채집 기술, 채널링은 유지합니다.
- NPC 툴팁에는 플레이어용 이름/길드/직업 지연 처리를 예약하지 않습니다. 같은 플레이어 툴팁의 중복 예약도 합칩니다.
- 전문화 감시/변환은 플레이어에만 적용하고, 오른쪽 정보 열의 불필요한 전체 검사를 줄입니다. 보호 값은 계속 검사하며 캐시하지 않습니다.
- 대상 이름과 배치가 같으면 대상 행을 다시 쓰지 않고, 최종 텍스트/폰트 배치가 같으면 툴팁 패딩을 재설정하지 않습니다. 새 정보/대상/툴팁 수명 주기는 계속 갱신합니다.
- 마우스오버 거리 문구는 변할 때만 크기와 색을 갱신합니다. 사거리 조회 주기는 유지합니다.
- 중복 전투 진입/종료 이벤트로 같은 알림이 재시작되지 않도록 방어합니다. 전투 알림과 기본 툴팁의 표시/숨김 정책은 유지합니다.

모의 검사는 통과했습니다. 실제 FPS 저하의 단일 원인을 확정한 것은 아니며 실제 WoW Forever에서 이동/시야 변경 및 전투 종료 상황을 확인해야 합니다. 기존 설정과 1.6.4 사거리 수정은 유지합니다.

## KHQOL 1.6.4 — Range Accuracy / Compact Mouseover Settings (historical)

1.6.3 기준으로 사냥꾼 근거리 오판 방어와 마우스오버 설정 배치를 보완했습니다.

- 랩터의 일격(2973 계열)의 응답만으로 근거리 공격 가능을 판정하지 않습니다. 습득한 날개 절단(2974 계열)으로 실제 근거리 사거리를 확인하며, 확인할 수 없으면 ‘판정 불가’입니다. 기존 75/2973 등록값은 유지합니다.
- 구형 IsSpellInRange는 이름+대상, 또는 확인한 주문책 인덱스+bookType+대상 형식으로 호출합니다. 주문 ID를 구형 주문책 인덱스로 전달하지 않습니다.
- 습득 여부 API가 false인 주문을 이름 조회 성공만으로 습득했다고 간주하지 않습니다. 주문책에서 확인한 습득 랭크는 지원합니다.
- ‘근거리 공격도 가능으로 판정’ OFF는 원거리만 확인하므로 가까운 대상도 빨간색일 수 있습니다. 근거리와 원거리를 함께 확인하려면 ON 상태로 사용하세요. 기본 단축바 색상은 변경하지 않습니다.
- 설정 그룹명은 ‘마우스오버 거리 측정’, 배치 선택은 ‘툴팁 아래 / 툴팁 왼쪽’입니다.
- 간격 옵션은 삭제했습니다. 기존 값은 X/Y 보정에 한 번 합산합니다. X -100~200, Y -100~100 범위이며 범위 밖 저장값은 제한됩니다.
- 가능/불가 문구는 한글을 포함한 최대 8자입니다. 기존 긴 문구도 처음 8자로 줄입니다.
- 표시 위치+초기화 → X/Y → 가능 문구/불가 문구/글자 크기 순서로 배치했습니다. 사망 대상 숨김은 유지합니다.

모의 검증은 통과했으나 실제 WoW Forever의 거리 API와 습득한 날개 절단의 판정은 확인이 필요합니다. Tooltip 보호 값 수정과 다른 모듈/미디어는 유지합니다.

## KHQOL 1.6.3 — Hunter Dual Range / Mouseover Controls (historical)

1.6.2 기준으로 마우스오버 메시지 문구/위치 보정 및 사냥꾼 원거리·근거리 판정을 추가했습니다.

- `Range → 마우스오버 공격 가능 표시`: 공격 가능/불가 문구를 입력하고 Enter로 적용합니다. 빈 문구는 기본값으로 복원합니다.
- 같은 그룹의 X/Y 위치 보정은 툴팁 아래/왼쪽 앵커에 상대적으로 적용됩니다. X +는 오른쪽, Y +는 위쪽이며 기본값은 각각 0입니다.
- 사망한 대상의 마우스오버 메시지는 표시하지 않습니다.
- 사냥꾼에게는 ‘사거리 기준 주문’에 원거리/근거리 입력란을 함께 표시합니다. 기존 rangeSpellID/hunterMeleeSpellID를 그대로 사용하며, 다른 직업은 단일 주문 입력란을 유지합니다.
- ‘근거리 공격도 가능으로 판정’ 기본값은 켜짐입니다. 원거리 또는 근거리 주문 중 하나라도 사거리 안이면 초록색입니다. 옵션을 끄면 기존 원거리 기준 판정을 사용합니다.
- 두 주문 모두 사거리 밖일 때만 기존 데드존 감지 옵션을 적용합니다. API가 판정하지 못하는 경우에는 공격 불가로 단정하지 않습니다.

기존 근거리 빨간색은 원거리 기준 판정의 의도된 동작이었습니다. 근거리 주문은 이전에 데드존 보조 판정으로만 사용되었습니다. 새 방식은 대상 사거리 아이콘과 마우스오버 메시지 양쪽에 적용됩니다. 재사용 대기시간·자원·시야·방향은 검사하지 않습니다.
기존 저장값을 초기화하지 않으며, 1.6.1의 Tooltip 보호 값 수정도 유지합니다. 실제 게임의 거리/데드존 API 확인은 필요합니다.

## KHQOL 1.6.2 — Mouseover Range (historical)

Range의 기존 기준 주문을 사용해 적 마우스오버 툴팁에 사거리 판정을 추가했습니다.
`Range → 마우스오버 공격 가능 표시`에서 표시 여부, 툴팁 아래/왼쪽 위치, 글자 크기 및 간격을 조절합니다.
기본값은 표시 켜짐, 툴팁 아래, 22px, 간격 8px입니다. 기존 설정은 초기화하지 않습니다.

- 초록 `공격 가능`: 공격 가능한 생존 적이며 기준 주문의 사거리 안입니다.
- 빨강 `공격 불가`: 사거리 밖/사냥꾼 데드존, 사망한 적 또는 공격할 수 없는 적입니다.
- 노랑 `판정 불가`: 기준 주문 미등록, API 미지원/오류 또는 판정에 필요한 보호된 정보를 읽을 수 없습니다.
- 아군, 아이템, 현재 마우스오버와 관계없는 툴팁에는 표시하지 않습니다. 보호된 대상 토큰은 판정을 건너뜁니다.

표시는 사거리 기준입니다. 재사용 대기시간, 자원, 시야, 캐릭터의 방향까지 확인하거나 실제 공격 성공을 보장하지 않습니다.
기존 대상 사거리 아이콘과 Tooltip 모듈의 기능은 유지합니다. Tooltip 모듈이 꺼져 있어도 기본 GameTooltip에 표시할 수 있습니다.
Range 모듈을 끄면 두 사거리 표시가 함께 꺼지며, 새 옵션만 끄면 기존 대상 아이콘은 유지됩니다.
실제 WoW Forever에서의 판정 API, 배치/페이드, 다른 툴팁 애드온과의 호환성은 추가 확인이 필요합니다.

## KHQOL 1.6.1 — Tooltip Secret Value Guard

사용자가 첨부한 1.6.0을 기준으로 툴팁의 보호된 대상 토큰 및 문자열 처리 오류를 수정했습니다.
보호된 값이 있는 경우 KHQOL의 툴팁 텍스트 후처리는 생략하고 게임의 기본 표시를 유지합니다.
일반 툴팁의 캐릭터명 +2pt와 전문화·대상 행 정리는 유지합니다.
문법 및 모의 회귀 검사는 통과했으며, 실제 게임에서의 검증은 필요합니다.

## KHQOL 1.6.0 — Refactoring / Maintenance Release

This release uses the supplied KHQOL 1.5.36 CombatStatus package as its baseline.
Gameplay features, UI layout, controls, defaults, commands, media and existing
SavedVariables are retained. No settings reset or new setup is required.
See `CHANGELOG.md` for the internal changes and the separate release report for
static comparison results and the WoW Forever in-game verification checklist.
This workspace cannot run the game client; in-game compatibility needs testing.

The notes below describe earlier releases and are retained as historical context.

## Historical 1.1.1 — Tooltip reference module

This package targets WoW Forever interface `16001`.  `Tooltip` is the first
KHQOL settings page built from reusable page, section, checkbox, slider,
dropdown, description and disabled-state helpers in `SettingsUI.lua`.

## Tooltip

- Enable/disable at **Tooltip → 툴팁 모듈 사용**.  Turning it off stops the
  registered hooks from applying changes, clears its timer, and hides the
  current managed tooltip so the next Blizzard tooltip uses its normal anchor.
- Position options: Blizzard default, cursor right, cursor upper-right and
  cursor lower-right.  Cursor modes use offsets and `SetClampedToScreen(true)`.
- Hold time: a `-2.0초 ~ +2.0초` slider with 0.5-second steps.  `기본` is the
  current Blizzard fade time.  When Forever exposes `GameTooltip.fadeOutTime`,
  the offset is applied to that client value without replacing Blizzard logic.
- Text size: `-3px` through `+3px`, stored as a delta and applied only to
  fonts belonging to the managed tooltip instance.
- Position includes `X 위치` / `Y 위치` offsets from -100 to +100 and a
  Position-only reset. Cursor presets reposition the open tooltip as the
  pointer moves, without repeatedly changing its owner.

## Information providers

`Tooltip/IDsProvider.lua` supplies independently switchable Item, Spell, NPC
and Quest ID rows.  The display mode is Always, only while Shift is held, or
Never; individual checks are preserved when the global mode is Never.  Core
collects provider lines and emits one divider only when at least one provider
has content.

## WeaponGuide migration

WeaponGuide is now the `Tooltip.weaponGuide` information provider.  Its
weapon/class data, known-skill checks, verified trainer gate and data tables
are retained under `Tooltip/WeaponGuideData.lua` and
`Tooltip/WeaponGuideProvider.lua`.  The former `WeaponGuide/` folder remains
in the package as unreferenced legacy source for recovery, but is deliberately
not listed in `KHQOL.toc`; it therefore cannot register a second hook or slash
command.

On first load, `ForeverWeaponGuideDB.fontSize` is converted to the Tooltip
`textSize` delta (13px → 0), and an explicit legacy `enabled = false` becomes
the provider's disabled checkbox.  The old SavedVariable is retained and is
not deleted.  New Tooltip preferences live in `KHQOLDB.modules.tooltip`.

## Forever data status

The existing trainer NPC labels are preserved exactly as supplied by the old
module.  No new Korean NPC names, coordinates or costs were invented:

- All trainer `mapID`, `x`, `y` values remain `nil` pending Forever UI-map
  verification.
- Default training cost and Polearm / Two-Handed Sword values remain the old
  verified-reference entries; other per-weapon costs are not claimed.

## Recommended in-game verification

1. Toggle Tooltip, change every position mode plus X/Y offsets at each screen edge, then reload.
2. Verify each hold-time preset after leaving a normal item tooltip.
3. Check text size at `-3`, `0`, and `+3` with a title and multiline tooltip.
4. Test Item, Spell, NPC and Quest ID rows plus the three ID display modes.
5. Test an eligible unlearned weapon, a learned weapon, an ineligible weapon,
   a non-trainable weapon, and rapid item mouseover changes.
6. Verify each trainer's localized name, map coordinate and price before adding
   any missing data to `Tooltip/WeaponGuideData.lua`.
# KHQOL

## 1.3.5 — Per-character trail colors

Trail color now defaults to the player's RAID_CLASS_COLORS class color. Manual
RGB selections are saved in KHQOLCursorTrailCharDB (per character) and take
priority on later logins. Other trail settings remain account-wide. Canceling
the picker restores both the previous color and automatic/manual preference.
Module reset clears the current character's color and restores the class default.

Upgrade: old versions did not track manual edits or character ownership. A
non-default legacy account color is copied once to the first character logged
in after upgrading; other characters start with their class color. A manual
selection exactly matching the old default cannot be distinguished from an
untouched default. Legacy RGB is retained in the account DB as a backup.

## 1.3.4 — Adjustable point spacing

Adds an Appearance slider for point spacing (1–20 UI units, step 0.5).
Lower spacing makes points overlap more; with the same maximum point count,
it also shortens the trail. Existing profiles inherit their previous spacing.
The spacing is saved and applies to new points independently of head size.
Large cursor jumps emit only the newest bounded samples, preventing delayed
point generation after the cursor has stopped.

## 1.3.3 — Tapered cursor trail

The newest trail points form a thick head; older points taper into a thin,
fainter tail. Ordering also tapers points generated in the same update.
When movement stops, remaining points shrink and fade over their duration.
Trail size controls the head size. Existing saved settings are preserved.

## 1.3.2 — Soft glow cursor trail

Replaces the bordered dots with a bundled radial alpha texture and additive
blending. Halos overlap softly, broaden slightly with age, and fade smoothly.
Existing color, size, duration, length and opacity settings are preserved.
No additional textures or settings are created during cursor updates.

## 1.3.1 — Color picker compatibility fix

Uses SetupColorPickerAndShow on modern clients, with a legacy RGB API fallback.
Color changes apply immediately; cancel restores the color saved when opened.

## 1.3.0 — Cursor Trail

Adds the independent **Cursor Trail** module. It creates a bounded, reusable
pool of non-interactive trail points while the cursor moves, fades each point
over the selected duration, and exposes the module in the main KHQOL settings
window.
