# KHQOL 1.9.10.3 — NPC Alert v0.1

기준: 사용자 제공 KHQOL-19.10.2.zip. 결과 버전: **1.9.10.3**. 작성일: 2026-10-08.

## 사용

`/kh` → **알림 → NPC**에서 `NPC 알림 사용`을 켭니다. 신규 모듈은 기본 OFF입니다.
`+ NPC 추가`에서 Map ID, NPC ID, 표시할 이름과 위험도를 저장합니다. `현재 Map ID 사용`은 편집기의 Map ID를 현재 지역 값으로 채웁니다. NPC ID를 비우면 이름 기반으로 등록할 수 있으며 동일 이름에 의한 오탐 가능성을 화면에 안내합니다.

현재 Map ID와 등록 Map ID가 정확히 같은 지역에서, 클라이언트에 노출된 NamePlate·대상·마우스오버를 감지합니다. 월드 전체 검색이나 정확한 거리 계산은 하지 않습니다. 이름표 표시가 꺼져 있거나 클라이언트의 이름표 노출 범위 밖이면 NamePlate 기반 사전 경고를 기대할 수 없습니다. 이름표 표시 설정을 자동 변경하지 않습니다.

## 1. 수정 / 추가 파일

추가:

- `Modules/NPCAlert.lua`: 데이터 접근, 지역 인덱스, NPC 감지·GUID별 상태, 경고/쿨다운, 독립 배너와 위험 방향 표시.
- `UI/NPCAlertSettings.lua`: NPC 탭 등록, 목록·인라인 추가/편집, 경고 설정·테스트.
- `RELEASE-1.9.10.3.md`: 이 보고서.

수정:

- `Bootstrap.lua`: 모듈 등록 및 버전.
- `Core.lua`: 기본 OFF, 기존 SetEnabled 경로 연결.
- `Profiles.lua`: npcAlert 표시 옵션을 관리 대상에 추가하는 한 줄.
- `KHQOL.toc`: 신규 파일 로드 및 버전.
- `README.md`, `CHANGELOG.md`: 버전 안내.

기존 `UI/AlertSettings.lua`, `SettingsUI.lua`, ProcAlert, PvPAlert, Navigation/QuestNavigator, EnvironmentTimer, BuffReminder 및 기존 미디어는 기준 ZIP과 바이트 단위로 동일합니다. sources/ 및 원본 ZIP은 수정하지 않았습니다.

## 2. NPC Alert 모듈 구조

기존 `KHQOL.AlertSettings:RegisterTab`에 NPC 탭을 등록합니다. 발동 탭과 같은 고정 상단 탭·스크롤·캐시 패널 구조이며, 신규 설정은 기존 공통 UI Builder/Theme와 체크박스·슬라이더·드롭다운·입력을 사용합니다. 비어 있는 미래 탭은 만들지 않았습니다.

기능은 `RefreshMap → Detect → Warn / RenderIndicator` 경로입니다. 기능 코드와 설정 코드를 분리했고 PvP/Quest Navigator에 감지 로직을 넣지 않았습니다. `activeNPCs[guid]`에 NPC와 연결된 Unit 토큰 집합을 보관합니다. 같은 GUID가 NamePlate와 target/mouseover에 동시에 나타나도 한 NPC로 처리합니다.

## 3. NPC ID 추출

읽을 수 있는 GUID만 전체 스키마에 맞춰 파싱합니다.

`Creature/Vehicle - 숫자 - 숫자 - 숫자 - 숫자 - NPC ID - 16진수 spawn ID`

바이트 위치를 잘라내지 않고 전체 토큰 구조와 종류를 검증합니다. Player/Pet/잘못된 GUID/비공개 값은 제외합니다. 등록 NPC ID가 있으면 ID로 판정하며 이름으로 그 등록 항목을 대신 매칭하지 않습니다. ID 없는 등록만 별도의 이름 인덱스에서 정확한 이름으로 판정합니다.

## 4. Map ID 판정

`C_Map.GetBestMapForUnit("player")`와 등록 Map ID의 정확한 일치만 허용합니다. `C_Map.GetMapInfo`로 지역명을 표시합니다. 부모 지역으로 자동 확장하거나 월드 지도에서 보고 있는 지역을 사용하지 않습니다.

`PLAYER_ENTERING_WORLD`, `ZONE_CHANGED_NEW_AREA`, `ZONE_CHANGED`, `ZONE_CHANGED_INDOORS`에서 목록을 갱신합니다. Map ID가 없거나 해당 Map에 활성 등록이 없으면 감지 이벤트를 구독하지 않습니다. `PLAYER_LEAVING_WORLD`에서는 런타임 표시와 후보를 정리합니다.

## 5. NamePlate 감지

`NAME_PLATE_UNIT_ADDED`에서 UnitGUID/UnitName을 안전하게 읽고 지역 인덱스와 비교합니다. `NAME_PLATE_UNIT_REMOVED`에서 해당 Unit 참조를 제거합니다. 다른 target/mouseover 참조가 남으면 논리적인 NPC 감지는 유지하고, NamePlate가 없어지면 방향 표시를 종료합니다. 마지막 참조가 사라지면 activeNPCs에서도 제거합니다.

활성화/지역 갱신 시 이미 표시된 `nameplate1..100`만 한 번 확인합니다. NPC GUID가 이벤트보다 늦게 준비되는 경우 0.1/0.3/0.7초에 최대 3회만 재시도합니다. 제거·지역 이동·OFF 이후에는 세대/티켓 검증으로 이전 재시도를 무시합니다.

## 6. Target / Mouseover

`PLAYER_TARGET_CHANGED`, `UPDATE_MOUSEOVER_UNIT`, `UNIT_NAME_UPDATE`에서 같은 Detect 경로를 사용합니다. 대상 선택이나 게임 상태를 변경하지 않습니다. target/mouseover만 있고 NamePlate 화면 위치가 없으면 배너·소리는 가능하지만 방향을 임의로 표시하지 않습니다.

## 7. 중앙 AlertBanner

기존 PvP `APPROACHING` 배너는 상태·캐스팅·보조 목록·애니메이션과 결합되어 있어 함수를 직접 공유하기에는 기존 기능 변경 범위가 커집니다. 따라서 검정 배경, 색상 테두리, 상태 아이콘, 이름/상태 텍스트라는 기존 표현 패턴을 신규 독립 배너로 적용했습니다. 공용 렌더러 추출이나 PvP 코드 변경은 없습니다.

위험도와 NPC 이름을 표시하고, 기본 3초 후 사라집니다. 새 NPC의 배너는 최대 8개까지 대기하며 한 번씩 순서대로 표시합니다. 이 상한을 넘는 동시 발견은 추가 배너 대기를 생략합니다. 소리는 배너 대기와 독립적으로 최초 감지 시 처리합니다. 지역 이동·OFF·테스트 종료 시 예약 콜백을 무효화합니다.

## 8–9. Danger Indicator 방향 / 회전 / 위치

`C_NamePlate.GetNamePlateForUnit(unit)`로 원래 NamePlate를 읽습니다. `GetCenter`와 `GetEffectiveScale`을 사용하여 plate와 UIParent 좌표를 같은 배율로 변환합니다.

```text
dx = plateX * plateScale / uiScale - uiCenterX
dy = plateY * plateScale / uiScale - uiCenterY
angle = atan2(dy, dx)
HUD offset = (cos(angle), sin(angle)) * radius
arrow rotation = angle - π/2
```

기존 Navigator의 위쪽을 향하는 `Media/QuestNavigator/Arrow.tga`를 재사용하며 색상만 위험도에 맞게 변경합니다. Navigator의 월드 좌표·목적지·회전 상태는 공유하지 않습니다. NamePlate가 없거나 forbidden/숨김/화면 밖/중심과 사실상 같은 점/좌표 nil·비공개·예외이면 방향을 표시하지 않습니다. 마지막 방향은 0.2초 Fade Out 동안만 보일 수 있습니다.

## 10. 동시 감지 우선순위

방향 표시가 켜져 있고 유효한 NamePlate 좌표가 있는 후보 중 하나만 선택합니다.

1. CRITICAL > HIGH > NORMAL.
2. 같은 위험도이면 화면 중심에서 더 가까운 NamePlate. 이는 화면상의 거리이며 야드 거리가 아닙니다.
3. 동일 화면 거리이면 먼저 감지한 순서.

배너/사운드는 신규 발견별로, 방향은 현재 우선순위 1위 하나로 별도 처리합니다. 보통은 주황, 높음은 빨강, 치명적은 진한 빨강입니다.

## 11. 재경고 쿨다운

GUID별 최근 경고 시각을 런타임에 기록합니다. 기본 대기시간은 10초입니다. 같은 NPC의 참조가 계속 유지되는 동안에는 쿨다운이 지나도 재경고하지 않습니다. 사라진 뒤 재등장했을 때만 마지막 경고 이후 시간을 확인합니다. 새로운 GUID는 별도 개체로 취급합니다.

상태 갱신 시 만료된 기록을 정리하고 최근 기록 수를 256개로 제한합니다. 아주 많은 개체를 만난 경우 가장 오래된 쿨다운이 먼저 제거됩니다. 프로필 전환·모듈 재활성화 시 런타임 경고 이력은 초기화합니다.

## 12. SavedVariables / 프로필

별도 SavedVariables를 선언하지 않습니다.

```lua
KHQOLDB.globalData.npcAlert = {
  nextID=1,
  entries={
    [registrationID]={mapID=130,npcID=1769,name="Son of Arugal",
      enabled=true,dangerLevel="HIGH",showBanner=true,showIndicator=true,sound=true},
  },
}
KHQOLDB.modules.npcAlert = {
  banner=true,bannerDuration=3,bannerScale=1,bannerAlpha=1,
  sound=true,reAlertCooldown=10,
  indicator={enabled=true,size=56,radius=180,alpha=1},
}
KHQOLDB.enabled.npcAlert = false
```

등록 목록과 NPC별 옵션은 계정 공용 사용자 데이터로 모든 캐릭터/프로필에서 공유합니다. 전체 모듈 사용 여부와 HUD·사운드·쿨다운 옵션은 기존 프로필에 저장합니다. 프로필 복사·변경·모듈 초기화가 등록 목록을 지우지 않습니다. 기존 전체 설정 초기화는 목록도 지웁니다. 실제 SavedVariables 입출력과 `/reload`는 게임에서 추가 확인해야 합니다.

## 13. 성능

- 감지와 지역 목록 갱신은 이벤트 기반입니다.
- 현재 지역에 등록이 없으면 NamePlate/target/mouseover 감지 구독을 해제합니다.
- 표시 대상 NamePlate 후보가 있을 때만 0.1초 주기로 후보의 좌표/토큰 유효성을 갱신합니다. 좌표가 잠시 읽히지 않는 후보도 회복을 확인하기 위해 같은 제한 주기를 사용합니다.
- NPC가 없거나 target/mouseover만 있거나 방향 표시가 꺼져 있으면 OnUpdate가 없습니다.
- 배너 종료와 짧은 초기 감지 재시도는 유한 C_Timer 콜백, Fade Out은 AnimationGroup을 사용합니다.
- 프레임과 목록 행을 재사용합니다. 매 프레임 전체 Unit 검색, NPC 세계 좌표 API, 전투 로그, 거리 계산을 사용하지 않습니다.

## 14. Forever API / 제한사항

Forever 분기의 Blizzard 생성 문서 소스에서 [NamePlate API](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/NamePlateDocumentation.lua), [Unit API](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua), [Map API](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/MapDocumentation.lua)를 확인했습니다. 특히 UnitGUID/UnitName에는 신원 제한 관련 secret 조건이 명시되어 있습니다. 이 모듈은 API 기능 확인·pcall·비공개 값 검사를 사용하며 제한된 값을 파싱하거나 좌표 연산하지 않습니다.

**실제 사용자 Forever 빌드에서 실행하지 않았습니다.** 모든 전투/인스턴스 상황에서 감지 가능하다고 보장하지 않습니다. GUID가 제한되면 해당 개체를 식별하지 못하고, NamePlate 좌표가 제한되면 방향을 표시할 수 없습니다. Aura를 읽는 방식은 사용하지 않으며, 기존 Proc Alert의 전투 중 Aura 제한 문제는 이번 작업에서 변경하지 않았습니다.

## 15. 테스트 결과

**자동 검사 PASS:**

- 68개 Lua 파일을 Lua 5.1로 문법 검사.
- 신규 NPC 및 기존 PvP/Navigator 표시 경로를 포함한 모의 검사 **111개**.
- 기존 발동 알림·설정 메뉴·프로필·환경 타이머 모의 검사 **100개** 재실행 통과.
- TOC 파일 존재/버전 일치, 기준 ZIP의 기존 파일 보존 및 최종 ZIP 무결성·압축 내용 일치 검사.

신규 검사에는 OFF, GUID 종류·스키마, Map 필터와 구독, 최초 경고, 계속 감지 시 중복 방지, 소리/배너 분리, 좌우/우상단 방향·회전, 배율 변환, 좌표 오류/비공개/화면 밖, Fade 완료, 다중 Unit 참조, 쿨다운 재등장, 위험도/화면 거리/최초 감지 순서, target/mouseover, 이름 기반과 ID 우선 판정, 지역 이동/초기 스캔, 테스트, 프레임 재사용, 프로필 저장·복원 및 재로드 모의, UI 탭·등록·중복·입력 검증·편집·삭제·현재 Map 입력, 지연 GUID 재시도, 전역/NPC별 사운드 OFF가 포함됩니다.

| 요청 테스트 | 자동 검증 | 실제 Forever |
|---|---|---|
| 1–10 | 탭·OFF·Map·ID/이름·감지·배너·소리 모의 통과 | 확인 필요 |
| 11–16 | 방향 계산·화면 위치·좌표 불가·제거·Fade 모의 통과 | 화면/입력 확인 필요 |
| 17–20 | 재등장 쿨다운·다중 후보 우선순위 모의 통과 | 확인 필요 |
| 21–23 | target/mouseover·테스트 모의 통과 | 실제 NPC와 소리 확인 필요 |
| 24–25 | 프로필 저장/복원·재로드 모의 및 지역 변경 통과 | /reload·재접속·지역 이동 확인 필요 |
| 26–28 | 기존 파일 동일성·관련 렌더링 모의·기존 검사 통과 | 전체 인게임 회귀 확인 필요 |

## 16. PvP Alert 회귀

기존 PvP 파일 전체가 기준 ZIP과 동일합니다. 실제 기존 Alerts/Core를 로드하여 APPROACHING 상태 문구·레이아웃·표시, CASTING 이름/레이아웃, Hide 경로를 모의 검사했습니다. NPC 테스트가 PvP 배너를 표시하지 않음도 확인했습니다. **실제 적 플레이어 감지·사거리·전투·사운드·taint 회귀 검증은 미실행입니다.**

## 17. Quest Navigator 회귀

Navigation.lua, NavigationUI.lua, QuestNavigator 및 미디어가 기준 ZIP과 동일합니다. 기존 방향 계산과 회전 렌더러, 사용 텍스처를 모의 검사하고 NPC 테스트가 Navigator 프레임이나 회전 좌표를 바꾸지 않음을 확인했습니다. **실제 퀘스트·반납 위치·월드 지도 이동·HUD 투영·보호 프레임 회귀 검증은 미실행입니다.**

## 18. 향후 v0.2 확장

등록은 안정된 registrationID로 관리하며 Map별 인덱스와 GUID별 런타임 상태를 분리했습니다. 최근 발견/등록 편의 기능, 메모·아이콘·커스텀 소리와 가져오기/내보내기는 등록 레코드를 확장하면 됩니다. 다중 Indicator는 현재 선택 단계와 프레임 풀을 확장해야 합니다. Navigator 연동은 별도 선택적 소스로 설계해야 하며, 클라이언트가 공개하지 않는 월드 위치/거리 정보를 얻을 수 있다고 가정해서는 안 됩니다.

## 설치 / 확인

ZIP의 `KHQOL` 폴더를 적용하고 기존 SavedVariables는 유지합니다. 게임에서 `/kh → 알림 → NPC`를 열어 사용을 켜고 현재 지역의 NPC를 등록하세요. 먼저 `NPC 경고 테스트`로 배너·오른쪽 위 화살표·소리를 확인한 뒤 실제 NamePlate 감지를 확인하세요. 이번 배포의 자동 검사 결과를 실게임 검증 완료로 간주하지 않습니다.

## 패키지 버전 정정 및 사용자 확인

배포 버전 표기를 19.10.3에서 1.9.10.3으로 정정했습니다. 기능 코드는 동일합니다.

사용자 스냅샷에서 전투 중 `6150 제한: true`가 확인되었습니다. 해당 확인 시점에 Spell ID 6150의 Aura 정보가 제한되므로 현재 Proc Alert의 직접 Aura 조회로 발동 여부를 판정할 수 없습니다. 이 결과가 모든 버프의 제한이나 NPC Alert 감지 실패를 뜻하지는 않습니다. 이번 변경은 패키징 정정이며 Proc Alert 감지 로직 변경은 포함하지 않습니다.
