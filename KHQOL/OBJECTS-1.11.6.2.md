# KHQOL 1.11.6.2 구현·조사 보고서

기준: 사용자가 제공한 KHQOL-1.11.6.1.zip. 참조: 사용자가 제공한 Lueur-1.4.0.zip. 날짜: 2026-11-08.

**코드 및 모의 검증을 완료했습니다. 실제 게임 테스트는 미실행입니다.** 사용자가 추가로 보고한 Alt+좌클릭 초대 문제의 Forever 이름 처리도 이번 패치에 포함했습니다.

## 기능별 결과

| 기능 | 상태 | 비고 |
| --- | --- | --- |
| 약초 강조 | 완료(코드/모의) | 현재 softinteract의 GatherHerbs 커서, 초록 Subtle 기본. 실제 표시 미검증 |
| 광맥 강조 | 완료(코드/모의) | Mine 커서, 주황 Reticle 기본. 실제 표시 미검증 |
| 보물상자 강조 | 부분(보수적 분류) | LootAll 또는 실제 동일 GameObject 전리품 출처로 학습한 ID만 사용. 범용 상자 전부를 알아내지 않음 |
| 퀘스트 반짝임 유지 | 보존/독립 옵션 추가 | 기존 그래픽 설정·Forever Loot Sparkles 충돌·복원 경로 유지 |
| CVar 복원 | 완료(코드/모의) | 새 전용 journal, 외부 변경 보존, 실패/잠금/전투/누락된 Labs의 복원 대기 |
| 모닥불 좌표 진단 | 완료(코드/모의) | raw Secret 값 연산/출력 금지, 상태별 기록, 수동 표본 비교 |
| 모닥불 방향 화살표 | 보류 | 좌표계와 방향 일관성의 인게임 근거가 없음. 화살표/작동 옵션을 배포하지 않음 |
| Alt+좌클릭 초대 | 호환성 수정/모의 통과 | Forever 이름+성, 솔로 초대 판단, `/초대진단` 추가. 실제 초대 도착은 재확인 필요 |

## 작업 전 조사 결과

- 기준 ZIP의 공통 런타임은 1.11.6.1이며 Convenience도 1.11.6.1입니다. 이번 요청에 따라 **모든 20개 KHQOL TOC를 1.11.6.2로 통일**했고 공통/Map/Campfire 버전 참조를 갱신했습니다. 과거 릴리스 문서는 기록으로 남겼습니다.
- ObjectHighlight는 별도 독립 클래스가 아니라 공통 기반의 GraphicsJournal을 모듈로 연결한 구조입니다. 기존 `enabled.objectHighlight`, LabLock, ModuleRegistry profile 연결을 유지하고 두 엔진만 분리했습니다.
- GraphicsJournal은 원래 값과 lastWritten을 변경 전에 보관하고, 현재 값이 마지막 쓰기와 다르면 외부 변경으로 보존합니다. 구형 outline 모드 기록의 이름·스키마·CVar 목록은 유지했습니다.
- LabLock의 재잠금과 프로필 적용은 H:Sync를 거칩니다. 여기에 새 엔진 Sync를 연결하고 HasRestoreRecords가 **두 journal**을 확인하도록 하여 전체 초기화가 미복원 기록을 지우지 않게 했습니다.
- Campfire는 네 Object ID를 0.5초마다 조회하며 기존에는 세 번째 반환값인 거리만 사용했습니다. 야영 상태/앉기/타이머/완료 로직은 유지하고 거리의 공개 숫자 확인을 보강했습니다.
- Navigation.Direction은 지도상의 동쪽 X/남쪽 Y와 북쪽=0인 플레이어 방향을 사용합니다. ClosestGameObjectPosition의 X/Y가 이 기준인지 검증되지 않았으므로 호출하거나 목적지를 등록하지 않았습니다. Navigation.lua/NavigationUI.lua는 수정하지 않았습니다.

## Lueur 1.4.0 검토와 라이선스

| 참조 함수/영역 | 확인한 동작 | KHQOL 적용 판단 |
| --- | --- | --- |
| ReadCursor / ObjectID | 숨긴 probe texture에 커서를 읽고 공개 texture/atlas 및 GameObject GUID의 ID를 해석 | 동일 API 원리로 독립 구현. 숫자 cursor ID는 클라이언트 GetFileIDFromPath로 확인 |
| Classify / MatchContainer | 자원 커서, 퀘스트, 이름/학습 ID로 분류 | 자원 커서 사용. 퀘스트/서비스/낚시 찌 제외. 이름만으로 상자를 확정하는 부분은 사용하지 않음 |
| ReadState | 거리/Unable 커서로 상태 구분 | ready/far/locked/unknown을 밝기/회색으로 구분. 모르는 상태를 ready로 간주하지 않음 |
| ResolveTarget | softinteract 이름표, 경우에 따라 보이는 이름표 순회 | 직접 이름표와 **같은 GUID로 확인된 alias 한 개**만 사용. 주변 전체 순회 없음 |
| Present / Effects | 대상에 단일 glow 및 애니메이션/미디어 층을 결합 | 별도의 한 프레임과 최대 24개 Line을 재사용. 세 프리셋의 그림은 독립 절차형 구현 |
| Menu / Locales | 별도 메뉴/현지화 및 커스터마이징 | 기존 KHQOL Builder/한국어 UI를 사용, Lueur 메뉴·번역을 이식하지 않음 |
| exclusive / NodeScan / Media | 기본 이름표 게이트·미니맵 탐색·여러 효과/bitmap | 이번 코드와 배포에서 제외 |

공식 [CurseForge 프로젝트](https://www.curseforge.com/wow/addons/lueur)는 MIT로 표시하지만 제공 ZIP에는 별도 LICENSE 파일이 없었습니다. 미디어의 별도 권리 범위는 확정하지 않았으며 **Lueur 코드·미디어·번역 파일을 복사하거나 ZIP에 포함하지 않았습니다.** 표준 API 동작과 사실 정보만 참고했습니다.

## 설정과 저장 정책

위치: **KHQOL → 실험실 → 오브젝트 강조**. 기존 모듈 사용/실험실 잠금은 그대로입니다.

```text
KHQOLDB.modules.objectHighlight (프로필)
  questSparkles = true      기존 동작을 유지
  gatherEnabled = false    새 전역 CVar 변경은 사용자가 명시적으로 켬
  size = 100 / alpha = 0.8 / showInCombat = false
  categories.herb  = enabled true / subtle / 초록
  categories.ore   = enabled true / reticle / 주황
  categories.chest = enabled true / brackets / 하늘색
KHQOLLabDB.objectHighlight.records     기존 그래픽 복원 기록, 보존
KHQOLLabDB.softTargetJournal.records   새 Soft Target 원본/lastWritten, 계정 공용
KHQOLLabDB.gatheringContainers         출처 일치로 확인한 상자 ID, 계정 공용
```

새 SavedVariables 전역은 없습니다. 새 채집 master를 처음에는 OFF로 두어 기존 사용자의 전역 targeting 설정이 업데이트만으로 바뀌지 않게 했습니다. 카테고리 세 기본 사용값은 요구대로 ON입니다. 스위치/프리셋/색상/크기/투명도는 프로필에 포함되며 복원·학습 자료는 포함되지 않습니다. 기존 채팅 캐릭터별 문구도 그대로 유지합니다.

## 감지·분류·효과

UnitIsGameObject가 공개 true인 현재 softinteract만 읽습니다. 퀘스트 관련 여부가 false로 확인되어야 하며 퀘스트/서비스/찌 커서를 제외합니다. 약초/광맥 커서를 우선하고, 상자는 명확한 LootAll 또는 source GUID 일치로 확인된 학습 ID를 사용합니다. PickLock/Pickup/이름만으로는 상자라고 확정하지 않습니다.

학습은 LOOT_OPENED 시 현재 softinteract와 실제 GetLootSourceInfo의 GUID가 정확히 같고, 수량이 공개 양수이고, 비퀘스트/비자원/비찌이며 이름의 상자 힌트가 보조적으로 있을 때만 저장합니다. 최초의 범용 상자·알 수 없는 언어/커서·직접 출처를 읽을 수 없는 상자는 강조하지 않을 수 있습니다. 자동 채집/자동 상호작용은 없습니다.

이름표를 숨기거나 바꾸지 않고 UIParent의 비입력 자체 프레임을 읽을 수 있는 이름표에 앵커합니다. 이름표가 없거나 금지/보호 상태를 확인할 수 없으면 생략합니다. Subtle/Reticle/Brackets는 최대 24개 Line을 재사용하며 bitmap/상시 OnUpdate/미니맵 스캔은 없습니다. 대상이 있을 때만 0.2초 ticker로 커서·범위·현재 GUID를 확인하고 분류는 캐시합니다. 대상 없음/기능 OFF/재잠금 때 멈춥니다. 상태 UI는 내용이 바뀔 때만 갱신합니다.

## CVar 적용·충돌·복원

새 journal은 SoftTargetInteract=3, SoftTargetNameplateInteract=1, range=15, arc=2, onlyInRange=0, rangeIsHard=0, iconGameObject=1, gameObjectMaxDistance>=60을 관리합니다. **SoftTargetIconInteract는 건드리지 않습니다.** exclusive 게이트나 다른 이름표의 표시/스타일 조작은 없습니다.

모든 지원/쓰기 가능 여부를 먼저 확인하고 전체 변경 계획의 원래 값/쓰기 의도를 기록한 뒤 씁니다. 현재와 다른 값만 실제 변경합니다. 오류 시 가능한 값은 복원하고 복원 실패/알 수 없는 기록은 유지합니다. 전투 중에는 쓰지 않고 종료 후 처리합니다. 사용자/다른 애드온의 이후 값이 lastWritten과 다르면 보존하고 강조를 중지합니다. 무한 재적용을 하지 않으며 사용자가 토글/프로필 재적용으로 다시 시작합니다.

Lueur 동시 로드는 새 강조 적용과 복원을 보류합니다. 동일 값에 대한 소유권을 판단할 수 없으므로 기록을 버리지 않고 Lueur를 끈 뒤 reload하여 처리합니다. 기존 Forever Loot Sparkles 검사와 outline journal은 독립적으로 유지합니다. 공통 기반의 새 journal은 Labs가 선택 설치에서 빠져도 남은 Soft Target 복원을 처리합니다.

## Alt+좌클릭 문제 수정

실제 설치본과 저장 옵션을 읽어 1.11.6.1 및 Alt 초대 ON을 확인했습니다. 이전 plainName은 공백을 무조건 거부했습니다. Forever의 [Camelot NameUtil](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_FrameXMLUtil/Camelot/NameUtil.lua)은 UnitName의 이름·성을 공백으로 결합하므로 유효한 이름이 거부되는 코드 경로가 있었습니다.

RegionalUniqueNamesEnabled일 때 C_NameUtil.ReplaceSurnameSeparatorWithLinkSeparator와 NameUtil.GetUnmodifiedUnitFullName을 사용해 링크/표시 이름을 비교하며, 원래의 전체 이름을 초대 API에 전달합니다. 일반 Name-Realm 경로는 유지합니다. 솔로는 그룹을 만들 수 있으므로 기존 그룹의 CanInvite 판정을 솔로 초대 차단에 사용하지 않습니다. 기존 그룹에서는 여전히 권한을 확인합니다. 실패 후 다른 송신 API로 재시도하지 않습니다.

`/초대진단`은 사용 ON/OFF, 등록 창/현재 적용 훅 수, 마지막 처리 사유를 로컬 출력합니다. 성공한 pcall은 **API 시도**로만 표시하며 서버 수락이라고 주장하지 않습니다. 일반 클릭/우클릭·다른 링크·중복 제한은 유지했고 해당 회귀 테스트도 포함했습니다. 실제 게임에서 보고된 문제의 최종 해결 여부는 초대 도착으로 재확인해야 합니다.

## 모닥불 API 조사 보고서

1. [Forever Unit API 정의](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua)는 `xPos, yPos, distance = ClosestGameObjectPosition(gameObjectID)`를 명시합니다. pcall 사용 시 순서는 `ok, x, y, distance`가 맞습니다. 기존 코드는 거리를 잘못 인덱싱한 것은 아니며 Secret 검사 없이 비교했던 점을 보완했습니다.
2. 명세의 MayReturnNothing / SecretReturns / SecretArguments AllowedWhenUntainted를 확인했습니다. 실제 클라이언트의 raw 숫자/좌표 표본은 이번 작업에서 수집하지 않았습니다.
3. 각 반환값을 public 확인한 후에만 nil/숫자/NaN/무한대/범위를 검사합니다. Secret 값은 저장/문자열 변환/비교/연산하지 않고 `secret` 상태만 보관합니다. X/Y가 Secret여도 거리만 공개 유효 숫자이면 기존 거리 표시에는 사용할 수 있습니다.
4. X/Y가 플레이어 상대인지, 월드인지, 다른 좌표인지 **확인 불가**입니다. 일반 숫자여도 좌표계 미확인, calculable=false로 남깁니다. 방향 계산 일관성도 검증하지 않았습니다.
5. `/cfa coords 표본명`, `/cfa coords list`, `/cfa coords clear`와 설정의 진단 버튼을 제공합니다. Object ID, X/Y/거리 상태, 플레이어 방향/위치, 좌표계·계산 가능 여부를 수동 비교할 수 있습니다. 최근 12개, 세션 한정으로 기록합니다.
6. 결론: **화살표 보류**, 기존 거리/야영 UI 보존. 같은 위치의 90/180도 회전, 접근/이탈/옆 이동, 여러 모닥불/인스턴스 표본이 먼저 필요합니다. 미검증 방향이나 비활성 화살표 옵션을 정상 기능처럼 넣지 않았습니다.

## 검증 결과와 제한

| 구분 | 결과 |
| --- | --- |
| 전체 Lua 5.1 구문 | 215/215 통과 |
| 모의 시나리오 | 171/171 통과: 기존 채팅 131개 + 객체/CVar/좌표/Forever 이름/UI 구성 추가 |
| TOC | 20개, 모두 1.11.6.2, 참조 파일 누락 0 |
| 원본 보존/배포 | 원본 파일 누락 0, ZIP CRC와 압축 전 소스 바이트 일치 확인 |
| 실제 게임 | **미실행**: 초대 수신, 실제 오브젝트/이름표, 전투 보호/taint, IME/그래픽 효과, CVar 서버 적용, 좌표계 실측 |

UI는 공용 Builder와 기존 컨트롤을 사용합니다. 모의 검증은 컨트롤 구성/콜백과 기존 채팅 좌표 테스트까지이며 실제 그래픽/글꼴 렌더링 검증은 아닙니다. 약초/광맥/상자 표시에는 게임이 현재 Soft Target과 이름표를 제공해야 합니다. 분류가 불확실하면 생략하므로 모든 상자를 항상 표시하는 기능은 아닙니다. 보호된 이름표는 전투 표시 ON이어도 생략될 수 있습니다. Lueur 충돌·읽기 불가·복원 실패는 상태와 기록으로 남깁니다.

작업 폴더에서만 수정했으며 게임 설치 폴더나 WTF에 쓰지 않았습니다. Git commit/push는 하지 않았습니다. 재현 가능한 harness와 시나리오별 JSON은 validation/에 제공합니다.

## 주요 함수·연결

- GraphicsJournal: IsEnabled의 questSparkles 게이트, Sync의 두 엔진 연결, HasRestoreRecords/RecoverDormantGraphics의 두 journal 확인.
- SoftTargetJournal: Read/GetState/Acquire/Write/Restore/Suspend/Watch. 변경 계획, 소유 값 비교, 복원 기록과 충돌/전투 이벤트를 담당.
- GatheringHighlight: Supported/ReadCursor/ObjectID/Classify/LearnContainer/ReadState/ResolveTarget/Present/Tick/StopTracking/Sync/GetStatus.
- ObjectHighlightEffects: Register/Render/Line과 독립 Subtle/Reticle/Brackets renderer.
- Campfire: ReadCampfirePosition/ReadCampfirePositions/DiagnoseCampfireCoordinates/PrintCoordinateSamples 신규. UpdateCampfireDistance/DiagnoseCampfireDistance/슬래시 및 설정 연결 수정.
- ChatEnhancement: plainName/canonical/unitName/TryInvite의 Forever 이름·솔로 판정 보강, PrintInviteDiagnostics 및 `/초대진단` 신규.

## 변경 파일

- `KHQOL/Bootstrap.lua`
- `KHQOL/CHANGELOG.md`
- `KHQOL/DESIGN.md`
- `KHQOL/KHQOL.toc`
- `KHQOL/Modules/GraphicsJournal.lua`
- `KHQOL/Modules/SoftTargetJournal.lua` (신규)
- `KHQOL/OBJECTS-1.11.6.2.md` (신규)
- `KHQOL/Profiles.lua`
- `KHQOL/README.md`
- `KHQOL/UI/SettingsRegistry.lua`
- `KHQOL_Campfire/Campfire/Core.lua`
- `KHQOL_Campfire/Campfire/Debug.lua`
- `KHQOL_Campfire/Campfire/PositionDiagnostics.lua` (신규)
- `KHQOL_Campfire/KHQOL_Campfire.toc`
- `KHQOL_Campfire/UI/Settings.lua`
- `KHQOL_Clock/KHQOL_Clock.toc`
- `KHQOL_CombatStatus/KHQOL_CombatStatus.toc`
- `KHQOL_Convenience/KHQOL_Convenience.toc`
- `KHQOL_Convenience/Modules/ChatEnhancement.lua`
- `KHQOL_Convenience/UI/ConvenienceDetails.lua`
- `KHQOL_CursorTrail/KHQOL_CursorTrail.toc`
- `KHQOL_DevTools/KHQOL_DevTools.toc`
- `KHQOL_EnvironmentTimer/KHQOL_EnvironmentTimer.toc`
- `KHQOL_ExperienceBar/KHQOL_ExperienceBar.toc`
- `KHQOL_Labs/KHQOL_Labs.toc`
- `KHQOL_Labs/Modules/GatheringHighlight.lua` (신규)
- `KHQOL_Labs/Modules/ObjectHighlightEffects.lua` (신규)
- `KHQOL_Labs/UI/LabSettings.lua`
- `KHQOL_Labs/UI/SearchIndex.lua`
- `KHQOL_Map/Core.lua`
- `KHQOL_Map/KHQOL_Map.toc`
- `KHQOL_NPCAlert/KHQOL_NPCAlert.toc`
- `KHQOL_PartyFrames/KHQOL_PartyFrames.toc`
- `KHQOL_PvPAlert/KHQOL_PvPAlert.toc`
- `KHQOL_QuestNavigator/KHQOL_QuestNavigator.toc`
- `KHQOL_Range/KHQOL_Range.toc`
- `KHQOL_ResourceSwing/KHQOL_ResourceSwing.toc`
- `KHQOL_Threat/KHQOL_Threat.toc`
- `KHQOL_Tooltip/KHQOL_Tooltip.toc`
- `KHQOL_UnitFrames/KHQOL_UnitFrames.toc`

정확한 변경 전/후 해시, 추가/유지 파일은 FILE-INVENTORY.json에 있습니다. changes.patch는 1.11.6.1 대비 텍스트 diff입니다. 인게임 체크는 INGAME-CHECKLIST-ko.md를 사용하세요.

---

# KHQOL 1.11.6.2 인게임 체크리스트

모든 항목은 **미실행**입니다. 정적/모의 결과를 인게임 PASS로 표시하지 않았습니다.

## 설치와 기존 데이터

- [ ] 게임 종료 후 WTF를 백업하고 ZIP 최상위의 20개 애드온 폴더를 AddOns에 병합한다. SavedVariables를 삭제하지 않는다.
- [ ] KHQOL 모든 TOC가 1.11.6.2이며 기존 프로필·개인 문구·노트·퀘스트·모닥불·프레임 설정이 유지된다.
- [ ] 기존 오브젝트 강조 모듈 사용 상태와 퀘스트 반짝임 기본 동작이 유지된다. 새 채집 사용은 OFF다.
- [ ] 실험실은 기존 코드로 잠금 해제해야 접근할 수 있다. 재잠금/모듈 OFF 시 표시가 사라지고 복원이 수행된다.

## Alt+좌클릭 초대 수정

- [ ] 편의 기능→일반→대화창의 Alt 초대를 ON으로 둔다. 기본 대화창 편의와 독립적으로 동작한다.
- [ ] Forever의 공백이 포함된 이름+성, 링크 구분자가 포함된 이름을 솔로 상태에서 Alt+좌클릭하면 상대에게 초대가 도착한다.
- [ ] 자신과 같은 파티원은 초대하지 않고, 기존 그룹의 권한 없음/만원/2초 반복 클릭은 초대하지 않는다.
- [ ] 일반 클릭은 귓속말, 우클릭은 기본 메뉴이며 Shift/Ctrl 조합·아이템/퀘스트/URL 링크가 유지된다.
- [ ] 작동하지 않으면 `/초대진단`의 ON/OFF, 등록 창/적용 훅 수, 최근 처리 사유를 기록한다.
- [ ] 전투 중 초대/새 채팅창/다른 채팅 애드온 조합에서 보호 동작 오류가 없는지 확인한다.
- [ ] 1.11.6.1 말머리·파티 자동 인사·캐릭터별 문구·프로필을 회귀 확인한다.

## 오브젝트 강조

- [ ] 실험실→오브젝트 강조의 기존 모듈 사용을 켜고 새 “채집 오브젝트 강조 사용”을 명시적으로 켠다.
- [ ] 약초 GatherHerbs, 광맥 Mine, 확실한 LootAll 상자를 각각 Soft Target으로 선택하고 종류/효과가 맞는지 확인한다.
- [ ] 범용 Interact 상자는 이름만으로 강조하지 않는다. 실제 같은 GameObject GUID의 전리품을 확인하고 학습한 경우에만 이후 강조한다.
- [ ] 우편함, 일반 문/레버/서비스, NPC/플레이어, 낚시 찌와 퀘스트 관련 오브젝트는 표시하지 않는다.
- [ ] 대상 변경·소멸·이름표 생성/제거·범위 이탈 시 기존 효과가 남지 않는다.
- [ ] 약초/광맥/상자의 세 프리셋을 서로 바꾸고 색상·크기·투명도를 즉시 확인한다.
- [ ] 범위 안/밖/상호작용 불가를 정상/희미함/회색으로 구분한다.
- [ ] 전투 중 표시 기본 OFF, 선택 ON, 보호된 이름표·금지된 이름표·Secret 값에서의 생략을 확인한다.
- [ ] 오브젝트가 없으면 폴링이 멈추며 다음 Soft Target 변경으로 다시 확인한다.
- [ ] 퀘스트 반짝임만 ON, 채집만 ON, 둘 다 ON/OFF 조합이 독립적으로 동작한다.
- [ ] 기본 이름표/상호작용 아이콘 및 다른 애드온 이름표가 임의로 숨겨지거나 변형되지 않는다.
- [ ] 설정 폭/배율/아코디언 변경 시 입력과 상태 문구가 겹치거나 잘리지 않는다.

## CVar와 프로필

- [ ] 켜기 전 Soft Target CVar를 기록하고 끈 뒤 KHQOL이 변경한 값만 원래대로 돌아오는지 비교한다.
- [ ] 기존 outline/퀘스트 GraphicsJournal 기록이 삭제·혼합되지 않는다.
- [ ] 활성 상태에서 사용자가 Soft Target 값을 바꾸면 강조가 중지되고 그 값을 덮어쓰지 않는다.
- [ ] Lueur가 이미 켜졌거나 나중에 로드되면 새 강조를 중지하고 복원 기록을 보존한다. Lueur를 끈 뒤 reload하여 복원/재적용을 확인한다.
- [ ] Forever Loot Sparkles 충돌은 기존 퀘스트 반짝임의 적용/복원을 보류한다.
- [ ] 전투 중 OFF/잠금/초기화는 전투 종료 후 복원되며 실패 기록은 남는다.
- [ ] /reload·재접속·Labs 선택 미설치 구성에서 복원 기록이 살아 있고 공통 기반이 복원을 처리한다.
- [ ] 프로필 변경 시 이전 효과를 제거하고 새 옵션을 적용한다. 학습된 상자와 복원 기록은 프로필에 복제되지 않는다.
- [ ] 전체 초기화는 어느 복원 기록이든 남아 있으면 기다린다.

## 모닥불 API 좌표 실측

동일한 모닥불 하나를 두고 다음 명령을 차례로 실행한다. 진단은 현재 세션의 최근 12개만 보관하고 raw Secret 값은 출력하지 않는다.

```text
/cfa coords still
/cfa coords turn90
/cfa coords turn180
/cfa coords toward
/cfa coords away
/cfa coords lateral
/cfa coords list
```

- [ ] 정지·같은 위치의 90도/180도 회전·접근·이탈·옆 이동 표본의 X/Y/거리/플레이어 방향/플레이어 위치를 비교한다.
- [ ] API 없음·호출 실패·반환 없음·Secret·일반 숫자·좌표계 미확인 상태가 구분된다.
- [ ] 모닥불 여러 개일 때 Object ID별로 가장 가까운 표본이 바뀌는지 확인한다. 동일 ID의 서로 다른 모닥불 전환에도 주의한다.
- [ ] 인스턴스/좌표 제한 지역·전투·감지 해제에서 Secret에 연산하거나 임의의 방향을 표시하지 않는다.
- [ ] 기존 거리 표시의 0.5초 주기와 야영 효과 감지, 앉기 버튼, 진행 타이머, 완료/재알림, 창 위치/크기가 유지된다.
- [ ] Quest Navigator 목적지·퀘스트 화살표가 바뀌지 않는다.

**현재 배포본에는 모닥불 방향 화살표와 그 작동 옵션이 없습니다.** 위 표본으로 좌표계·축·회전 기준·거리 일관성을 검증한 뒤 별도 구현해야 합니다.
