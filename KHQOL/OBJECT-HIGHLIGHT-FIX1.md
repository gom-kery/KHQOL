# 오브젝트 강조 미표시 원인 분석·수정 진단본

기준: KHQOL 1.11.6.3 · 진단본 식별자: **1.11.6.3-object-fix1** · 2026-11-08.

## 확인 결과

**실제 미표시의 시작 차단 원인을 확인했습니다. `SoftTargetInteract`가 이미 필요한 값 `3`인데도, 기존 코드가 무조건 쓰기 가능 여부를 검사하면서 `isSecure=true`를 이유로 강조 엔진 전체를 중지했습니다. 값을 바꿀 필요가 없으므로 이 검사는 불필요했습니다.**

사용자가 제공한 상태 화면에 `Soft Target CVar 사용 불가: SoftTargetInteract`가 표시되고, 실제 읽기 결과는 GetCVar=`3`, GetCVarInfo=`"3", "1", true, false, false, true, false`입니다. 읽기 실패가 아닌 보호 메타데이터 검사에 걸렸음이 확정됩니다. 그 위의 ‘지원 설정 적용 완료 (5/5)’는 별도 **퀘스트 반짝임** 엔진의 결과이며 채집 강조 엔진의 성공을 뜻하지 않습니다.

이미 목표값과 같으면 쓰기를 생략하고 진행하도록 수정했습니다. 실제로 값을 바꿔야 할 때는 기존 보호 검사를 유지합니다. Secret/보호를 우회하거나 보안 설정을 해제하는 수정이 아닙니다. 사용자의 실제 반환값으로 원본 중단과 수정본 진행을 모두 모의 재현했습니다. **수정본 적용 후 실제 표시 복구 여부는 아직 NOT TESTED**입니다.

별도로 공통 Line 그리기 인자 누락도 확인·수정했습니다. 이것은 이번 화면의 최초 차단보다 뒤에 있는 호환성 문제입니다. 마지막 로컬 저장값의 약초 개별 OFF 및 이름표/분류 제한도 아래에 구분해 기록합니다.

## 1. 설치 파일·저장값 확인

- 실제 AddOns의 Labs TOC 버전은 1.11.6.3입니다. Gather/Effects 파일이 설치되어 있습니다.
- 설치된 ObjectHighlightEffects.lua의 SHA256은 배포본과 같습니다: `87e67182fac212fef395f82f1121727cac5cf6340737e68899dc0fcfce3d7f99`.
- 마지막 저장된 현재 모듈 설정과 저장 프로필에서 objectHighlight=true, gatherEnabled=true, ore.enabled=true, chest.enabled=true, **herb.enabled=false**를 확인했습니다. 실험실은 마지막 저장 상태에서 해제되어 있습니다. 실행 중 변경값이 저장되지 않았다면 달라질 수 있습니다.
- 확인한 AddOns 경로에는 Lueur 폴더가 없습니다. 이것만으로 실행 중 충돌 API의 반환을 확정하지는 않습니다.
- 사용자 WTF/SavedVariables 전체 내용은 결과물에 복사하지 않았습니다. 게임 폴더와 설정 파일은 읽기만 했습니다.

약초 OFF는 약초 미표시를 설명하지만 광맥·상자까지 설명하지 못합니다. 따라서 세 종류 전체의 미표시를 설정 하나의 문제로 결론 내리지 않았습니다.

## 2. 확정 원인 — 이미 맞는 CVar에도 무조건 쓰기 권한 요구

기준 `KHQOL/Modules/SoftTargetJournal.lua`의 Acquire는 다음 조건으로 CVar 전체를 차단합니다.

```lua
if not current or not K.GraphicsJournal.compat.writable(name) then
  -- Soft Target CVar 사용 불가
  return false
end
```

이 검사가 목표값 비교보다 앞에 있습니다. 사용자 반환값의 여섯째 `true`는 isSecure입니다. writable은 이 경우 false를 반환하므로, 읽기는 성공했고 현재값도 목표값과 같은 `3`인데 첫 CVar에서 중단됩니다. 효과 프레임·커서 분류·이름표 검사까지 도달하지 않습니다.

GetCVarInfo의 반환 순서는 value, defaultValue, isStoredServerAccount, isStoredServerCharacter, isLockedFromUser, isSecure, isReadOnly입니다. 사용자가 제공한 값은 `value="3", default="1", storedAccount=true, storedCharacter=false, locked=false, secure=true, readOnly=false`로 해석됩니다. [Forever CVarDocumentation](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/CVarDocumentation.lua).

수정은 읽기와 쓰기 조건을 분리합니다.

```lua
-- 읽을 수 없으면 중단
-- 목표값과 다를 때만 기존 writable 검사를 요구
if current ~= target then
  local writable, why = K.GraphicsJournal.compat.writable(name)
  if not writable then return false end
end
-- 실제 SetCVar도 current ~= target일 때만 수행하는 기존 경로 유지
```

따라서 사용자의 SoftTargetInteract=`3`에는 SetCVar를 호출하지 않습니다. 다른 CVar가 변경을 필요로 하는데 보호되어 있으면 여전히 중지하며, 이제 ‘읽기 불가’와 ‘쓰기 불가’를 다른 상태로 보여 줍니다. 다음 차단이 있다면 `/오브젝트진단`에서 CVar 이름과 개별 보호 플래그를 확인할 수 있습니다.

## 3. 추가 호환성 문제 — 공통 렌더링의 인자 누락

기준 `KHQOL_Labs/Modules/ObjectHighlightEffects.lua`의 Line 함수:

```lua
line:SetStartPoint("CENTER", x1, y1)
line:SetEndPoint("CENTER", x2, y2)
```

Forever의 SimpleLineAPI 문서는 인자를 `relativePoint, relativeTo, offsetX, offsetY`로 정의합니다. 두 번째 인자는 ScriptRegion이며 좌표 숫자가 아닙니다. 기준 코드에서는 이 자리에 x 좌표가 들어가고 기준 프레임이 빠져 있습니다. 명시적인 호환 호출로 수정했습니다.

```lua
line:SetStartPoint("CENTER", frame, x1, y1)
line:SetEndPoint("CENTER", frame, x2, y2)
```

고정 소스 근거: [Forever SimpleLineAPIDocumentation](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleLineAPIDocumentation.lua).

약초의 Subtle, 광맥의 Reticle, 상자의 Brackets가 모두 이 Line 함수를 사용합니다. 렌더 호출 오류는 Present의 pcall에 잡힌 뒤 효과 전체를 숨기는 경로로 이어집니다. 기준 코드에서는 구체적인 오류 문자열도 남기지 않아 Lua 오류창 없이 ‘표시가 안 됨’으로 보일 수 있습니다. 이번 진단본은 마지막 공개 렌더 오류를 세션 안에서 보관해 출력합니다.

기존 모의 테스트는 SetStartPoint/SetEndPoint에 임의 인자를 받아 주는 방식이어서 이 규격 불일치를 놓쳤습니다. 회귀 검사에 기준 프레임 타입과 오프셋 검사를 추가했습니다. **실제 클라이언트의 구형 축약 호출 허용 여부나 실제 오류 문자열은 아직 관측하지 않았으므로, 이것이 실행 중 유일한 원인이라고 단정하지 않습니다.**

## 4. 다른 표시 조건과 기존 진단의 부족

코드 흐름은 설정/실험실 → 필수 API → Soft Target CVar → softinteract GameObject → 공개 GUID → 퀘스트 무관 판정 → 커서 분류 → 종류 ON → 이름표 → 효과 그리기입니다. 앞 단계가 통과되지 않으면 Line 수정만으로 표시가 살아나지 않습니다.

| 단계 | 미표시 조건 | 이번 진단에서 구분하는 값 |
| --- | --- | --- |
| settings | 모듈/실험실/채집 사용/전체 종류 OFF | module, labUnlocked, canRun, gather, categories |
| api/cvar | 필수 함수 없음, 설정 읽기/쓰기 실패, Lueur 충돌, 전투 적용 보류, 외부 CVar 변경 중지 | journal 상태, CVar 현재값/쓰기 가능 여부, API 존재, Lueur |
| soft-target | 게임이 softinteract 오브젝트를 고르지 않음/공개 확인 불가 | gameObject, exists, GUID. 오브젝트는 UnitExists=false여도 될 수 있어 이 값만으로 제외하지 않음 |
| quest | 퀘스트 관련=true 또는 false를 확인할 수 없음 | questRelated와 오류/비공개 상태 |
| classification | 숫자 커서 ID 미해석/알 수 없는 커서/상자 근거 부족 | cursor texture/atlas/category/blocked |
| category | 해당 종류 설정 OFF | 정확한 종류와 OFF 이유 |
| nameplate | 이름표 없음/숨김/금지/전투 보호 | direct, alias, resolved, shown/forbidden/protected |
| render | 위치 연결 또는 Line 호출 오류/등록되지 않은 효과 | 마지막 공개 오류, stage=render |
| shown | 분류·이름표·효과 호출 성공 | kind, interaction, frame shown |

기준 Tick은 이름표를 못 찾아 숨겼을 때에도 status를 ‘채집 커서’ 같은 분류 성공 문구로 덮어썼습니다. 이 때문에 ‘감지는 됐지만 이름표가 없음’을 구별하기 어려웠습니다. 이번 수정은 중단 단계를 표시하며, 커서 분류 성공 문구를 최종 표시 성공처럼 남기지 않습니다.

이 기능은 **약 15m 범위에서 게임이 고른 Soft Target 한 개**의 이름표에만 효과를 붙입니다. 주변의 모든 약초/광맥/상자를 동시에 탐색하는 기능이 아닙니다. 이름표를 게임이 제공하지 않으면 표시하지 않습니다. 이것은 기존 범위이며 이번 진단본에서 탐색 범위를 확대하지 않았습니다. Lueur 공식 설명도 SoftTargetInteract와 GameObject 이름표 설정의 필요성을 명시합니다. [Lueur 프로젝트 설명](https://www.curseforge.com/wow/addons/lueur).

상자는 추가 제한이 있습니다. LootAll 커서 또는 **동일 GameObject GUID의 실제 전리품 출처로 확인·학습된 ID + 일반 상호작용 커서**만 허용합니다. 처음 보는 일반 커서 상자는 표시되지 않을 수 있습니다. 이름에 ‘상자’가 있다는 이유만으로 표시하거나 퀘스트 오브젝트를 상자로 추측하지 않습니다. 이 제한도 약초/광맥의 동시 미표시를 설명하지는 못합니다.

## 5. 수정 범위

| 파일 | 변경 |
| --- | --- |
| KHQOL/Modules/SoftTargetJournal.lua | 이미 목표값인 CVar의 쓰기 검사 생략, 변경 필요 시 보호 유지, 읽기/쓰기 실패 구분 |
| KHQOL_Labs/Modules/ObjectHighlightEffects.lua | Line 시작/끝 기준 프레임 명시 |
| KHQOL_Labs/Modules/GatheringHighlight.lua | 중단 단계별 이유, 이름표 실패 구분, 위치/렌더 오류 포착 및 마지막 공개 오류 보관 |
| KHQOL_Labs/Modules/ObjectHighlightDiagnostics.lua | 신규 수동 진단·로컬 대화창 출력·명령 |
| KHQOL_Labs/KHQOL_Labs.toc | 진단 파일을 GatheringHighlight 다음에 로드 |
| KHQOL_Labs/UI/LabSettings.lua | ‘오브젝트 진단 출력’ 버튼 |
| KHQOL/README.md / OBJECT-HIGHLIGHT-FIX1.md | 진단본 식별과 현재 설명 |

다른 모듈, 기존 분류 규칙, CVar 목표값·복원 규칙·충돌 보호, 사용자 설정 기본값은 변경하지 않았습니다. 특히 약초 OFF 저장값을 자동으로 ON으로 바꾸지 않습니다. 진단은 Sync/Tick을 강제 실행하거나 CVar를 쓰지 않습니다. 커서 확인은 자체 숨긴 probe Texture에만 수행합니다. 결과는 본인의 로컬 대화창에만 출력되며 파티/일반 채팅으로 전송하지 않습니다. Secret 데이터는 출력하지 않습니다. 진단 이력을 SavedVariables에 새로 저장하지 않습니다.

## 6. 검증

| 검사 | 결과 |
| --- | --- |
| 사용자 실제 CVar 읽기 | 확인: value=3, locked=false, secure=true, readOnly=false. 상태 화면의 최초 차단 위치와 일치 |
| 실제 반환값으로 원본/수정 비교 | 원본은 같은 ‘사용 불가’로 중단, 수정본은 SoftTargetInteract 쓰기 없이 진행. 변경이 필요한 보호 CVar는 계속 차단 |
| 기존 배포본 + 명시적 Line 규격 검사 | 기존 245개 통과, 새 herb/ore/chest 3개 실패 재현: 245/248 |
| 기준 프레임 명시 후 동일 검사 | 248/248 통과 |
| 최종 진단본 Lua 5.1 | 217/217 구문 통과 |
| 최종 진단본 모의 시나리오 | 259/259 통과: 기존 회귀, 사용자 반환값 원본/수정 비교, 보호 유지, 세 종류 규격, 설정·이름표·CVar 구분, 렌더 오류, 읽기 진단·Secret 처리 |
| TOC | 20개, 참조 누락 0, Version 1.11.6.3 / Interface 16001 유지 |
| ZIP | 원본 파일 누락 0, CRC와 소스 바이트 일치 검사 |
| 실제 표시·서버 API·전투 보호/taint | **NOT TESTED** |

원본 실패 결과와 최종 결과 JSON, 테스트 코드를 validation/에 제공합니다. 이 규격 모의 재현은 실제 클라이언트에서 발생한 오류 로그를 대신하지 않습니다. 판정은 **수정·진단본 / 실게임 확인 필요**입니다.

## 7. 게임에서 확인할 순서

1. 게임을 종료하고 기존 코드 폴더를 백업한 뒤 `KHQOL-1.11.6.3-object-fix1.zip`의 전체 애드온 폴더를 교체합니다. WTF/SavedVariables는 유지합니다. 이번 작업에서 설치 폴더를 직접 수정하지 않았습니다. 정식 버전 증번 없이 1.11.6.3 기반 진단본 식별자를 사용합니다.
2. 실험실 → 오브젝트 강조에서 채집 강조 사용과 약초/광맥/상자의 개별 ON을 확인합니다. 약초는 마지막 저장값에서 OFF였습니다.
3. 전투 밖에서 채집물을 약 5~10m 앞에 두고 바라봅니다. 게임이 고르는 대상 한 개만 확인합니다. 우선 분류가 명확한 광맥으로 확인하는 편이 좋습니다.
4. `/오브젝트진단` 또는 `/khobjectdebug`를 실행합니다. 설정 화면의 ‘오브젝트 진단 출력’ 버튼도 같습니다.
5. 여전히 보이지 않으면 출력 중 **active/stage/reason/journal, gameObject/GUID, questRelated, cursor, nameplate, lastRenderError, 실패한 CVar와 info/locked/secure/readOnly**를 전달해 주세요. 다음 단계에서 멈췄는지 실제 값으로 확인할 수 있습니다.
6. 상자는 처음 보는 일반 커서 대상이면 classification 단계에서 제외될 수 있습니다. 약초/광맥이 해결된 뒤 전리품 출처 학습 여부를 별도로 확인합니다.

기존 설정 화면의 ‘현재 적용 상태’ 문구만으로 원인을 확정하기 어려웠던 문제를 해소하도록 준비한 진단본입니다. 표시 성공이나 보호 동작 안전성을 실게임 확인 전에 확정하지 않습니다.
