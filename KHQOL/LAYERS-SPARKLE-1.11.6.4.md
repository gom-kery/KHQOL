# KHQOL 1.11.6.4 구현·검증 보고서

기준: 사용자가 제공한 **1.11.6.3-object-fix1 전체 ZIP** → 결과 **1.11.6.4** · 2026-11-08.

## 1. 구현 요약

- **경험치 바:** 실제 XP → 완료·미반납 퀘스트 예상 XP → 휴식 XP → 배경의 연속 구간으로 수정했습니다. 기존 실제 XP와 예측 XP 계산을 유지하고, 휴식의 표시 시작점·끝점만 요청한 공식으로 변경했습니다.
- **오브젝트 강조:** 기존 Subtle/Reticle/Brackets에 작은 입자 4개의 **Sparkle**을 추가했습니다. 같은 Soft Target/분류/이름표 경로를 사용하며 퀘스트 반짝임 엔진과 분리했습니다.
- **추가 직업 색상:** 기존 대상·대상의 대상·주시 공통 옵션을 플레이어와 KHQOL 파티/공격대 프레임까지 확장했습니다. 같은 18개 HEX를 같은 스타일로 사용합니다. 기존 공통 스위치와 저장 경로를 재사용하고 프레임마다 별도 팔레트를 저장하지 않습니다.
- **실제 진단 화면 대응:** SoftTargetInteractRange 같은 보조 거리/각도 설정이 보호되면 현재 값을 보존하고 감지를 계속하도록 수정했습니다. 활성화/이름표 생성에 필요한 핵심 설정은 계속 엄격히 확인합니다.

모든 20개 TOC Version은 1.11.6.4, Interface는 16001입니다. Lua **218/218**, 모의 시나리오 **302/302** 통과. **수정본을 실제 Forever 게임에서 실행한 검증은 NOT TESTED**이므로 세 기능 모두 LIMITED GO입니다. 사용자의 CVar/상태 화면은 기존 시작 차단의 증거이며, 새 표시·애니메이션 성공의 증거는 아닙니다.

## 2. 기준 조사·변경 파일·주요 함수

기준 ZIP은 20개 애드온 폴더/306파일/Lua 217개입니다. 기존 경험치 바, 오브젝트 효과, SoftTargetJournal, UnitFrames/PartyFrames의 실제 파일과 프로필·UI 연결을 확인했습니다. 원본의 모든 파일을 보존하며 아래 표는 기준 ZIP과 바이트 비교한 결과입니다.

| 파일 | 구분 | 수정 내용 |
| --- | --- | --- |
| `KHQOL/Bootstrap.lua` | 공통 | 런타임 버전 |
| `KHQOL/CHANGELOG.md` | 문서 | 1.11.6.4 현재 안내, 이전 기록 보존 |
| `KHQOL/DESIGN.md` | 문서 | 1.11.6.4 현재 안내, 이전 기록 보존 |
| `KHQOL/INSTALL-GUIDE.md` | 문서 | 1.11.6.4 현재 안내, 이전 기록 보존 |
| `KHQOL/KHQOL.toc` | 공통/직업색 | 새 공통 팔레트 로드 순서·버전 |
| `KHQOL/LAYERS-SPARKLE-1.11.6.4.md` | 문서 | 신규 보고서·실게임 체크리스트 |
| `KHQOL/Modules/ClassHealthColors.lua` | 직업색 | 신규 확정 팔레트·공통 설정·공개 직업 토큰·즉시 갱신 |
| `KHQOL/Modules/SoftTargetJournal.lua` | 오브젝트 | 필수/보조 CVar 구분·보호 보조값 유지·소유권·수치 정규화 |
| `KHQOL/README.md` | 문서 | 1.11.6.4 현재 안내, 이전 기록 보존 |
| `KHQOL_Campfire/Campfire/Core.lua` | 공통 | 내부 표시 버전만 변경 |
| `KHQOL_Campfire/KHQOL_Campfire.toc` | 공통 | TOC Version 1.11.6.4만 변경 |
| `KHQOL_Clock/KHQOL_Clock.toc` | 공통 | TOC Version 1.11.6.4만 변경 |
| `KHQOL_CombatStatus/KHQOL_CombatStatus.toc` | 공통 | TOC Version 1.11.6.4만 변경 |
| `KHQOL_Convenience/KHQOL_Convenience.toc` | 공통 | TOC Version 1.11.6.4만 변경 |
| `KHQOL_CursorTrail/KHQOL_CursorTrail.toc` | 공통 | TOC Version 1.11.6.4만 변경 |
| `KHQOL_DevTools/KHQOL_DevTools.toc` | 공통 | TOC Version 1.11.6.4만 변경 |
| `KHQOL_EnvironmentTimer/KHQOL_EnvironmentTimer.toc` | 공통 | TOC Version 1.11.6.4만 변경 |
| `KHQOL_ExperienceBar/KHQOL_ExperienceBar.toc` | 공통 | TOC Version 1.11.6.4만 변경 |
| `KHQOL_ExperienceBar/Modules/ExperienceBar.lua` | XP | Render/SetSegment의 순차 휴식 구간 |
| `KHQOL_ExperienceBar/UI/ExperienceSettings.lua` | XP | 순차 구간·휴식 의미 설명 |
| `KHQOL_Labs/KHQOL_Labs.toc` | 공통 | TOC Version 1.11.6.4만 변경 |
| `KHQOL_Labs/Modules/GatheringHighlight.lua` | 오브젝트 | 새 기본값·기존값 보존·애니메이션 수명·캠프 제외 |
| `KHQOL_Labs/Modules/ObjectHighlightDiagnostics.lua` | 오브젝트 | 진단 버전 1.11.6.4 |
| `KHQOL_Labs/Modules/ObjectHighlightEffects.lua` | 오브젝트 | Sparkle 4입자·Alpha/Scale·Stop·기존 registry 확장 |
| `KHQOL_Labs/UI/LabSettings.lua` | 오브젝트 | Sparkle/보호된 범위 설명, 기존 선택 UI 재사용 |
| `KHQOL_Map/Core.lua` | 공통 | 내부 표시 버전만 변경 |
| `KHQOL_Map/KHQOL_Map.toc` | 공통 | TOC Version 1.11.6.4만 변경 |
| `KHQOL_NPCAlert/KHQOL_NPCAlert.toc` | 공통 | TOC Version 1.11.6.4만 변경 |
| `KHQOL_PartyFrames/KHQOL_PartyFrames.toc` | 공통 | TOC Version 1.11.6.4만 변경 |
| `KHQOL_PartyFrames/Modules/PartyFrameDisplay.lua` | 직업색 | 실제 채움·그라데이션 우선순위·공개 토큰 |
| `KHQOL_PartyFrames/UI/PartyFramePreview.lua` | 직업색 | 미리보기에 같은 팔레트 적용 |
| `KHQOL_PartyFrames/UI/PartyFrameSettings.lua` | 직업색 | 같은 공통 설정·검색·그라데이션 안내 |
| `KHQOL_PvPAlert/KHQOL_PvPAlert.toc` | 공통 | TOC Version 1.11.6.4만 변경 |
| `KHQOL_QuestNavigator/KHQOL_QuestNavigator.toc` | 공통 | TOC Version 1.11.6.4만 변경 |
| `KHQOL_Range/KHQOL_Range.toc` | 공통 | TOC Version 1.11.6.4만 변경 |
| `KHQOL_ResourceSwing/KHQOL_ResourceSwing.toc` | 공통 | TOC Version 1.11.6.4만 변경 |
| `KHQOL_Threat/KHQOL_Threat.toc` | 공통 | TOC Version 1.11.6.4만 변경 |
| `KHQOL_Tooltip/KHQOL_Tooltip.toc` | 공통 | TOC Version 1.11.6.4만 변경 |
| `KHQOL_UnitFrames/KHQOL_UnitFrames.toc` | 공통 | TOC Version 1.11.6.4만 변경 |
| `KHQOL_UnitFrames/Modules/UnitFrameDecor.lua` | 직업색 | 플레이어 범위 확대·코어 공통 색상/토큰 사용 |
| `KHQOL_UnitFrames/UI/SearchIndex.lua` | 직업색 | 공통 범위 검색 경로 설명 |
| `KHQOL_UnitFrames/UI/UnitFrameDetails.lua` | 직업색 | 플레이어/파티 포함 공통 옵션·즉시 갱신 |

주요 연결은 다음과 같습니다.

- ExperienceBar의 **Render/SetSegment**: 기존 segment에 실제/퀘스트/휴식 구간을 배분. QuestExperiencePreview의 수집·반납 동기화 로직은 바이트 동일하게 유지했습니다.
- ObjectHighlightEffects의 **Register/Render/Stop/Line**: 기존 프리셋 유지, Sparkle 생성·시작·재사용·중단. GatheringHighlight의 **Hide/Present/Tick/Classify/LearnContainer**: 대상 교체/사라짐/잠금에서 정리, 기존 모닥불 ID 명시 제외.
- SoftTargetJournal의 **Acquire**: 핵심/보조 CVar 구분, 보호된 보조 값 유지와 제한 안내. **Read/CVAR_UPDATE**: 숫자 표현 정규화 및 소유하지 않은 생략값의 외부 변경 보존. Write/Restore의 보호·소유권 복원 원칙 유지.
- 신규 core ClassHealthColors의 **GetClassHealthColor/GetClassHealthSettings/GetUnitClassToken/RefreshClassHealthColors**: 건강 채움용 확정 팔레트, 기존 저장 설정, 공개 직업 토큰, 양쪽 모듈 즉시 갱신.
- UnitFrames의 **SharedClassHealthColor** 범위 확장. PartyFrameDisplay의 **ApplyHealthColor/RefreshButton** 및 **RefreshLivePreview**에 같은 팔레트 연결. 기존 생명력 수치·사망/흡수·디버프 표시 경로 보존.

상세 전후 해시·누락 검사는 FILE-INVENTORY.json, 코드 차이는 changes.patch에 있습니다.

## 3. 경험치 바 구간 통합

### 기준 동작과 변경 이유

1.11.6.3은 휴식 끝점을 `(currentXP + restedXP)`에 두고, 퀘스트 예상 구간과 겹친 휴식 부분만 가렸습니다. 따라서 40% + 퀘스트 25% + 휴식 20%이면 퀘스트 구간이 휴식 구간을 덮어 휴식이 보이지 않을 수 있었습니다.

1.11.6.4는 요청한 시각적 연결을 사용합니다.

```text
실제       [0, currentXP]
퀘스트     [currentXP, min(currentXP + questXP, maxXP)]
휴식       [questEnd, min(questEnd + restedXP, maxXP)]
배경       나머지
```

예: maxXP=10,000, 실제=4,000, 완료 퀘스트=2,500, 휴식=2,000 → **0~40% 실제 / 40~65% 퀘스트 / 65~85% 휴식 / 85~100% 배경**. 반납 후 예상은 65%이며 85%가 아닙니다. 퀘스트·휴식 색상의 투명도가 설정되어 있어도 두 구간을 겹쳐 칠하지 않습니다.

### API 의미·예측과의 구분

기존 UnitXP/UnitXPMax/UnitLevel/GetXPExhaustion을 그대로 사용합니다. GetXPExhaustion은 nil 또는 숫자이며, 기본 Forever UI도 이 값을 현재 XP에 더한 뒤 UnitXPMax로 나누어 휴식 구간 길이로 사용합니다. 이번 구현은 **그 XP 단위 길이를 퀘스트 표시 뒤로 옮길 뿐**, 휴식 보너스가 퀘스트에 적용된다거나 최종 획득 XP가 늘어난다고 계산하지 않습니다. [Forever PlayerScriptDocumentation](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/PlayerScriptDocumentation.lua), [기본 ExpBar의 UpdateTickPosition](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_StatusTrackingBar/Shared/ExpBar.lua).

현재 레벨 100%에서 자르며 다음 레벨 요구량을 추정하지 않습니다. maxXP=0/조회 실패/Secret은 새 구간을 추측하지 않습니다. 반납 예상 텍스트·레벨업 예상은 기존 questXP만 사용하고 restedXP를 합산하지 않습니다.

### 예외·기존 설정·이벤트

- 퀘스트가 없거나 옵션 OFF면 실제 XP 뒤에 기존 휴식 구간을 표시합니다. 휴식 옵션 OFF면 퀘스트 구간만 표시합니다. 둘 다 0이면 기존 실제 바와 같습니다.
- 퀘스트가 100%에 도달하면 휴식은 숨기고, 휴식이 남은 공간을 초과하면 화면상 길이만 자릅니다.
- 기존 StatusBar/segment/텍스처/마커/배경/위치/크기/배율/잠금/실제·휴식 색상/숫자 옵션은 유지합니다. 수평 및 기존 세로→수평/역방향 경로에 같은 구간을 분배합니다. 기존 UI에서 미제공 상태인 감싸기 모드 선택을 새로 열지는 않았습니다.
- QuestExperiencePreview 파일은 변경하지 않았습니다. ID별 합계 캐시, 이벤트 병합, 반납 차단 ID, XP 선행 시 로그 동기화 보류, 레벨 변경 재조회, 모듈 OFF의 전용 이벤트 해제/예약 무효화를 유지합니다. 휴식만 변하면 보상 API를 다시 조회하지 않습니다. Quest Navigator를 사용하지 않습니다.
- **이전 제한 유지:** 출처를 확정할 수 없는 일반 XP 획득도 다음 신뢰 가능한 QUEST_LOG_UPDATE까지 미리보기를 숨길 수 있습니다. 로그 이벤트가 없으면 숨김이 계속될 수 있습니다. 불완전하게 노출된 전체 로그도 부분합을 추측하지 않고 보류합니다. 반납 이중 계산 방지가 우선입니다.

## 4. Sparkle와 CVar 대응

### 효과·색상·기존 설정

기존 ObjectHighlightEffects에 네 번째 선택지 **Sparkle · 작은 반짝임**을 추가했습니다. 각 카테고리의 기존 드롭다운과 색상·크기·투명도 설정을 그대로 사용합니다. 기존 사용자가 저장한 Subtle/Reticle/Brackets와 색상은 바꾸지 않습니다. **새로 기본값을 받는 카테고리만 Sparkle**이며, 새 기본 색은 연한 녹색 (.55,1,.65), 따뜻한 금색 (1,.75,.25), 하늘색 (.4,.8,1)입니다. 부모 채집 사용 스위치는 기존처럼 기본 OFF입니다.

입자 프레임 4개를 오브젝트 이름표 주변 가장자리에 배치합니다. 각 입자는 좁은 선 두 개로 만든 작은 4방향 별이며 외부 미디어를 쓰지 않습니다. 각자의 시작 지연·주기가 다른 **Alpha/Scale AnimationGroup**이 부드럽게 반복됩니다. 중앙을 덮는 큰 원/빛기둥/게임 3D 효과를 만들지 않습니다.

동일 이름표의 재표시/크기·색상 갱신에서는 프레임과 AnimationGroup을 재사용하며 진행 중인 반복을 매 tick 다시 시작하지 않습니다. 대상 GUID/이름표 교체, 일반 효과로 전환, 이름표 소실, 전투 숨김, 기능 OFF, 잠금/프로필 변경/월드 이탈에서 Stop/Hide합니다. 기존 최대 24개 선 풀 외에 Sparkle는 입자 4개/선 8개를 재사용합니다. 새 OnUpdate 탐색은 없습니다.

Forever 문서의 AnimationGroup Play/Stop/SetLooping, Alpha SetFromAlpha/SetToAlpha, Scale **SetScaleFrom/SetScaleTo**를 확인해 사용했습니다. `SetFromScale` 같은 이름을 가정하지 않습니다. [AnimationGroup API](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleAnimGroupAPIDocumentation.lua), [Scale API](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleAnimScaleAPIDocumentation.lua), [Alpha API](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleAnimAlphaAPIDocumentation.lua).

### 감지·제외·기존 퀘스트 반짝임

기존 softinteract의 UnitIsGameObject/공개 GUID, SetUnitCursorTexture의 숨긴 probe, C_QuestLog.UnitIsRelatedToActiveQuest, C_NamePlate.GetNamePlateForUnit을 사용합니다. 약초/광맥 커서 또는 검증된 전리품 출처의 보수적인 상자 판정을 유지합니다. 모르는 일반 상호작용/이름만 상자인 항목은 추측하지 않습니다. GameObject가 아닌 NPC/플레이어와 퀘스트/서비스/낚시 찌는 제외하고, 기존 Campfire에 명시된 529161/573022/529148/29784도 강조·상자 학습에서 제외했습니다. Campfire 모듈 자체는 표시 버전 외 변경하지 않았습니다.

현재 게임이 고른 Soft Target **한 개**만 표시합니다. 이름표가 없거나 금지/전투 보호 상태이면 숨깁니다. 기본 이름표나 상호작용 아이콘을 숨기지 않습니다. Quest Sparkles의 기존 그래픽 journal/복원/부모 잠금을 유지하고 새 Sparkle를 퀘스트에 중복 적용하지 않습니다.

Lueur 1.4.0 참고 경로와 이전 조사 기록을 확인했습니다. [공식 프로젝트](https://www.curseforge.com/wow/addons/lueur)는 MIT로 표시하지만 제공 ZIP의 별도 미디어 권리 범위를 확정한 것은 아닙니다. 이번 Sparkle는 **독립 구현**이며 Lueur 코드·미디어·번역·미니맵 스캔을 배포에 넣지 않았습니다.

### 첨부 진단의 Range 쓰기 차단 수정

사용자 화면은 active=false/stage=cvar, **SoftTargetInteractRange 쓰기 불가**입니다. fix1에서 이미 맞는 Interact=3 문제를 지나 다음 보조 설정의 사전 검사에 걸린 상황입니다. 이번에는 다음과 같이 구분했습니다.

| 구분 | CVar | 정책 |
| --- | --- | --- |
| 핵심 | SoftTargetInteract=3, SoftTargetNameplateInteract=1, SoftTargetIconGameObject=1 | 이미 맞으면 쓰지 않음. 다르면 기존 공개·쓰기 가능 검사를 통과한 경우만 변경. 맞출 수 없으면 안전하게 중단 |
| 보조 | InteractRange/Arc/OnlyInRange/RangeIsHard, nameplateGameObjectMaxDistance | 읽히고 변경 가능하면 기존 목표 적용. 보호/메타데이터 불확실 시 **현재 값 유지하고 감지 계속**, 상태에 실제 유지값·범위 제한 안내. 미지원 항목은 생략하되 미복원 기록이 있으면 확인 우선 |

예: Range=10이고 보호되면 15로 강제 쓰지 않고 10을 유지합니다. 그 항목에 새 복원 기록/기대값을 만들지 않으며 다른 곳에서 바꾼 값도 보존합니다. 기존 기록의 유효성·외부 변경 검사, 쓰기 실패 시 복원, 전투 중 보류, Lueur 충돌 시 중지, 로그아웃/잠금의 durable 복원 기록은 유지합니다. 숫자 문자열 `3.000000`과 `3`을 같은 값으로 정규화해 불필요한 쓰기를 줄였습니다.

**보호를 우회하거나 15m 감지를 보장하는 수정은 아닙니다.** 현재 게임 범위가 작거나 각도/거리 조건이 제한되면 가까이서 바라봐야 하며, 핵심 설정도 차단되는 클라이언트에서는 여전히 시작할 수 없습니다. `/오브젝트진단`의 현재 값·쓰기 플래그·이름표/분류/렌더 단계로 확인할 수 있습니다.

## 5. 플레이어·파티 공통 직업 색상

기존 `KHQOLDB.modules.unitFrames.classHealth={enabled=false,style="dark"}`를 그대로 재사용합니다. 유닛 프레임의 플레이어/대상/대상의 대상/주시 ‘바’와 파티·공격대 ‘공통’에서 **같은 설정**을 편집합니다. 새 전역 SavedVariables나 프레임별 복제 팔레트는 없습니다.

| 토큰 | 어둡게 | 밝게 |
| --- | --- | --- |
| WARRIOR | B38C63 | DBAC79 |
| PALADIN | DD7EA7 | FF9ACD |
| HUNTER | 9ABF68 | BCE97F |
| ROGUE | E6DD5F | FFFF74 |
| PRIEST | E6E6E6 | FFFFFF |
| SHAMAN | 0065C8 | 007BF4 |
| MAGE | 5FB8D8 | 74E0FF |
| WARLOCK | 8575B5 | A38FDD |
| DRUID | E67109 | FF8A0B |

코어 한 곳에서 HEX/255 변환한 RGB를 사용합니다. 전역 Blizzard 직업 색상이나 기존 KHQOL.ClassColors는 바꾸지 않습니다. 이름·자원·테두리·텍스처·위치·생명력 수치 설정은 유지합니다. 공개 직업 토큰은 지역화 이름과 분리해 확인합니다.

공통 ON이면 플레이어를 포함한 네 유닛 프레임과 KHQOL 파티/10·20·40인 공격대의 생명력 기본 채움이 동일합니다. 파티 미리보기도 같은 색을 사용합니다. **공통 팔레트가 기존 체력 그라데이션보다 우선**하며 그라데이션 저장값은 그대로 두어 공통 OFF 시 기존 동작으로 돌아갑니다. 기존 사망 음영·디버프 색상/보호막 등의 별도 상태 효과는 보존하므로 상태 효과가 활성인 순간의 최종 화면색까지 항상 팔레트와 같다는 뜻은 아닙니다.

NPC·펫·기타 제외 프레임과 기존 OFF 동작은 유지합니다. 스타일 변경 시 현재 유닛과 적용 중인 파티·미리보기를 즉시 갱신합니다. 기존 프로필 시스템을 사용하며 추가한 팔레트 조회는 보호 프레임의 위치/보안 속성을 변경하지 않습니다. 실제 전투/taint·다른 프레임 애드온 충돌 검증은 남았습니다.

## 6. 검증·호환성·알려진 제한

| 항목 | 상태 | 근거·범위 |
| --- | --- | --- |
| Lua 5.1 구문 | PASS | 218/218 |
| 모의 시나리오 | PASS | 302/302. 기존 회귀와 이번 변경의 실제 모듈 함수 실행 |
| XP 구간 | PASS (모의) | 40/25/20, 퀘스트 합계, 휴식만/퀘스트만/0/100%/초과/시각적 잘림, 수평·세로/역방향 분배, OFF, 휴식 갱신의 캐시 재사용, 조회 실패 |
| 반납·프로필 회귀 | PASS (모의) | 기존 XP 선행/로그 선행/반납 선행/연속 반납·레벨업·무효화 테스트 유지 |
| Sparkle | PASS (모의) | 4개 입자/Alpha·Scale 규격/위상 차이, 프레임·그룹 재사용, 세 종류 색상, 기존 효과 전환, 대상/이름표 소실, 모듈 OFF·잠금 |
| CVar 제한 | PASS (모의) | 사용자 Range 보호 차단 조건에서 현재값 유지 후 진행, 핵심 미지원·보호는 중단, 외부 변경 보존·기존 복원 회귀 |
| 직업 색상 | PASS (모의) | 9직업×2스타일의 플레이어/대상/파티 RGB 일치, 기존 3유닛 검사 확대, OFF 그라데이션 복귀, 실제 파티 설정 콜백·미리보기 함수 실행 |
| 배포 | PASS | 20 TOC, 참조 누락 0, 모든 Version/Interface 일치, 원본 파일 누락 0, CRC·ZIP/소스 바이트 일치 |
| 실게임 화면/보상/보호·충돌 | NOT TESTED | 2D Sparkle 실제 밝기·원근·폰트/설정 높이, 이벤트 실제 순서/보상값, 전투·taint, 다른 애드온 충돌 |
| 전체 UI 검증 | PARTIAL | 공용 Builder/콜백/기하 모의 검사. 실화면 줄바꿈·스크롤·클리핑은 NOT TESTED |

테스트는 엔진/서버/Secret 보안 권한을 재현하지 않습니다. source의 QuestExperiencePreview와 Quest Navigator 코드는 변경하지 않았고, Campfire는 버전 문자열만 변경했음을 바이트 비교합니다. 신규 Sparkle/공통 색상과 기존 채팅·실험실·모닥불 진단 회귀도 포함합니다. 게임 설치/WTF에는 쓰지 않았으며 Git commit/push하지 않았습니다.

## 7. 최종 판정·결과물

| 기능 | 판정 | 남은 확인 |
| --- | --- | --- |
| 경험치 바 구간 통합 | **LIMITED GO** | 구현·모의 검증 완료, 실제 XP/휴식 길이·반납·레벨업/화면 확인 |
| Sparkle 효과 | **LIMITED GO** | 구현·모의 검증 완료, 실제 이름표/애니메이션과 보호된 보조 CVar 유지 상태 확인. 핵심 설정이 불가하면 해당 실행 환경에서는 감지 보류 |
| 플레이어·파티 공통 직업 색상 | **LIMITED GO** | 구현·모의 검증 완료, 전투/프로필/실화면 상태 효과와의 조합 확인 |

전체 ZIP과 source는 같은 **20폴더·308파일**입니다. IMPLEMENTATION-REPORT-ko.md, INGAME-CHECKLIST-ko.md, validation, FILE-INVENTORY.json, SHA256SUMS.txt, changes.patch를 함께 제공합니다. 게임 종료 후 코드 폴더를 백업·교체하고 **WTF/SavedVariables는 유지**하세요. 기존 효과를 저장한 사용자는 약초/광맥/상자 효과에서 Sparkle를 직접 선택해야 합니다.


---

# KHQOL 1.11.6.4 실게임 체크리스트

**아래 모든 항목은 현재 NOT TESTED입니다.** 정적/모의 검증은 구현 보고서에 따로 있습니다. 현재 XP/Sparkle/추가 직업 색상 모두 LIMITED GO입니다.

## 설치·보존

- [ ] 게임 종료 후 기존 KHQOL 코드와 WTF를 백업하고 ZIP 최상위 20개 애드온 폴더를 AddOns에 배치. WTF/SavedVariables 삭제 없음.
- [ ] TOC Version 1.11.6.4 / Interface 16001 확인. 기존 프로필/선택 설치/기본 OFF 설정/위치·크기·색상 유지.
- [ ] 기존 채팅 Alt 초대, 퀘스트 반짝임, Quest Navigator, Campfire, 다른 알림·위치 편집·파티 역할 프로필 정상.
- [ ] 설정 화면 한글/줄바꿈/스크롤/비활성 상태/검색 이동에 잘림·겹침 없음.

## 경험치 바

- [ ] 실제 XP만, 휴식만 추가, 완료 퀘스트만 추가, 세 종류 모두인 상태 확인.
- [ ] 40% 실제 +25% 퀘스트 +20% 휴식이면 0~40 /40~65 /65~85 /85~100 배경. 반납 후 예상 수치는 65%이며 휴식을 더하지 않음.
- [ ] 완료 퀘스트 2개 이상 합계가 하나의 구간이며 실제 보상창 XP와 일치.
- [ ] 퀘스트가 100% 도달/초과하면 휴식 숨김. 휴식이 남은 공간 초과하면 화면상 구간만 잘림.
- [ ] 휴식 OFF와 퀘스트 미리보기 OFF 각각 확인. 두 옵션 OFF면 기존 바와 같음.
- [ ] 바 폭·높이·위치·배율·잠금·텍스트 형식/숫자 OFF·색상·평판 연동 유지. 기존 감싸기 저장 모드를 쓰는 경우 모서리/역방향 확인.
- [ ] 실제 XP 조회 실패/Secret/최대 레벨에서 잘못된 예상 구간 없음.
- [ ] 반납 이벤트보다 XP가 먼저 증가해도 받은 퀘스트 XP를 다시 더하지 않음. 연속 반납/취소/포기/재수락도 확인.
- [ ] 일반 몬스터 XP 후 시작점 갱신. 동기화 대기 시 다음 로그 이벤트까지 숨길 수 있는 기존 제한의 빈도·복원 시점 기록.
- [ ] 실제 레벨업 후 새 필요 XP/보상 XP로 갱신. Quest Navigator OFF에서도 계산.
- [ ] 모듈/옵션 OFF, 프로필 전환, Reload 후 데이터 보존 및 오래된 콜백 표시 없음.

## Sparkle·감지·CVar

- [ ] 실험실 잠금 해제, 오브젝트 강조 모듈/채집 사용/세 카테고리 ON 확인. **기존 사용자는 각 효과를 Sparkle로 직접 선택.**
- [ ] 가까운 약초/광맥/검증된 상자를 바라볼 때 게임이 고른 대상 한 개 주변에 작은 입자 4개가 투명도·크기를 달리하며 반복. 중앙을 과도하게 가리지 않음.
- [ ] 카테고리별 기존 사용자 색상/크기/투명도 반영. 새 기본값은 Sparkle, 녹색/금색/하늘색.
- [ ] Subtle/Reticle/Brackets와 왕복 전환, 대상 교체, 이름표 소실/숨김, 거리 이탈, 전투 숨김, 모듈 OFF, 잠금/프로필/월드 이탈에서 입자 잔상·지속 애니메이션 없음.
- [ ] 전투 표시 ON도 보호/금지 이름표에는 무리하게 붙이지 않으며 taint/금지 동작 없음.
- [ ] NPC/플레이어/퀘스트 오브젝트/일반 상호작용/낚시 찌/모닥불은 제외. 퀘스트는 기존 엔진 반짝임만 유지.
- [ ] 일반 커서의 처음 보는 상자는 근거가 없으면 숨기는 기존 정책 확인. 전리품 출처 학습 후 해당 ID만 표시되는지 확인.
- [ ] `/오브젝트진단`에서 Range 보호 상태가 보이면 active=true 또는 후속 감지 단계로 진행하고, Range 값은 그대로이며 제한 안내가 나옴.
- [ ] 핵심 SoftTargetInteract/NameplateInteract/IconGameObject가 이미 맞으면 쓰기를 요구하지 않음. 변경이 필요하고 보호되면 계속 중단하고 정확한 항목을 표시.
- [ ] 보조 Range/Arc 등 보호·미지원은 현재값 유지/생략. 실제 감지 거리가 그 설정의 영향을 받으며 15m를 강제로 보장하지 않음.
- [ ] 외부 CVar 변경값/기본 이름표/상호작용 아이콘 보존. Lueur 충돌·로그아웃·OFF·잠금에서 기존 변경 기록 복원/보류 정책 확인.

## 공통 직업 색상

- [ ] 유닛 프레임 → 플레이어/대상/대상의 대상/주시 → 바 또는 파티·공격대 → 공통에서 같은 스위치·스타일을 편집.
- [ ] 9직업 각각 어둡게/밝게에서 플레이어·대상·대상의 대상·주시·파티/공격대의 기본 생명력 채움 RGB가 보고서 HEX와 같음.
- [ ] 파티 미리보기도 같은 팔레트. 공통 ON은 그라데이션보다 우선하지만 기존 저장값은 유지. OFF 시 기존 직업색/그라데이션 복원.
- [ ] 기존 사망 음영·디버프·흡수 효과/텍스트/자원색과 위치·크기·텍스처 보존. NPC/펫/기타 프레임에 새 팔레트가 적용되지 않음.
- [ ] 대상/주시/파티 구성·직업 정보 변경, 전투 진입·종료/Secret, 프로필 전환, Reload에서 정상. 다른 프레임 애드온과 충돌 기록.

## 기록

| 구분 | 결과 |
| --- | --- |
| 실제 빌드/캐릭터 레벨/동시 애드온 | 미기록 |
| XP 구간·반납·레벨업 | NOT TESTED |
| Sparkle 실화면·감지·CVar 제한 | NOT TESTED |
| 직업 색상·그라데이션·전투 | NOT TESTED |
| 프로필·Reload·기존 기능 회귀 | NOT TESTED |
| 판정 | 세 기능 LIMITED GO 유지. 실제 확인 후 GO/LIMITED GO/HOLD 갱신 |
