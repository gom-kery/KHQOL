# KHQOL 1.11.6.5 — 사용자 조준선 이미지 통합

기준: 1.11.6.4-position-fix1 전체 작업본 → 결과 **1.11.6.5** · 2026-11-08.

## 구현 요약·사용 방법

사용자가 제공한 두 ZIP의 **조준선 TGA 5개를 가공 없이** 기존 오브젝트 강조 엔진에 연결했습니다. 사용자 확인에 따라 대상은 **약초·광맥·보물상자**로 유지합니다. 새 이미지 강조를 퀘스트 관련 대상, NPC/플레이어, 일반 상호작용 오브젝트, 낚시 찌, 모닥불에 적용하지 않습니다.

**실험실 → 오브젝트 강조**에서 채집 사용 및 원하는 카테고리를 켜고 ‘약초/광맥/보물상자 효과’에서 **이미지 01~05**를 선택하세요. 기존에 저장한 효과는 강제로 바꾸지 않습니다. 새로 기본값을 받는 카테고리는 이미지 01입니다. 기존 4종은 ‘기존 Subtle/Reticle/Brackets/Sparkle’로 남아 있으며 총 9개 선택지입니다.

| 선택 항목 | 제공 파일 | 표시 방식 |
| --- | --- | --- |
| 이미지 01 · 십자선 (Cross) | ObjectReticle_01_Cross.tga | 투명 배경의 원본 십자선 |
| 이미지 02 · 마름모 (Diamond) | ObjectReticle_02_Diamond.tga | 원본 마름모 |
| 이미지 03 · 분할 원형 (Segmented Ring) | ObjectReticle_03_SegmentedRing.tga | 원본 분할 원형 |
| 이미지 04 · 납작한 회오리 (Flat Swirl) | ObjectReticle_04_FlatSwirl.tga | 원본 비율의 회오리 |
| 이미지 05 · 궤도 별빛 (Orbit Star) | ObjectReticle_05_OrbitStar.tga | 원본 별빛/궤도 |

### 조절 항목

- **색상:** 카테고리별 기존 색상 선택기를 재사용합니다. 흰색 원본에 SetVertexColor로 지정 RGB를 적용합니다.
- **크기:** 공통 40~240 UI px, 정사각형 이미지 전체를 같은 비율로 조절합니다. 원본의 내부 여백과 납작한 회오리/긴 별빛 모양을 왜곡하지 않습니다.
- **투명도:** 공통 10~100%. 원본 알파와 곱해지며, 상호작용 거리/차단 상태에 따른 기존 흐림/회색 처리를 유지합니다. Cross 원본의 최대 알파는 230, 나머지는 255로, 원본의 차이를 보정하지 않았습니다.
- **위치:** 기존 Y(-200~100, 기본 -60)에 X(-200~200, 기본 0)를 추가했습니다. X 증가는 오른쪽, Y 감소는 아래쪽입니다. 카테고리 공통 위치이며 이미지와 기존 효과 모두 같은 앵커를 사용합니다.
- **강조 위치 초기화:** X=0/Y=-60만 복원합니다. 효과·색상·크기·투명도는 유지합니다.

위치는 화면 UI 좌표이며 카메라 원근에 따라 실제 오브젝트와의 정렬이 달라질 수 있습니다. 새 프레임 이동/클릭/게임 선택 동작은 만들지 않습니다.

## 렌더링·자원 관리

`KHQOL_Labs/Modules/ObjectHighlightEffects.lua`에 이미지 5종을 등록하고 Image 렌더러를 추가했습니다. 기존 재사용 효과 프레임에 **Texture 하나**를 생성해 5개 경로를 교체합니다. 같은 이미지의 반복 갱신에서는 파일을 다시 지정하지 않습니다. BLEND와 원본 투명도를 사용하며, 이미지 크기/RGBA를 현재 설정으로 즉시 반영합니다. 별도 이미지 애니메이션은 추가하지 않습니다.

이미지 선택 시 기존 선과 Sparkle 애니메이션을 정리하고, 기존 효과 선택 시 이미지를 숨깁니다. 대상/이름표 소실·전투 숨김·모듈/카테고리 OFF·실험실 잠금·프로필 변경/월드 이탈에는 기존 Hide/Stop 경로가 이미지도 정리합니다. 이미지 로드가 명시적으로 실패하면 효과를 숨기고 진단에 오류를 남깁니다. 실패한 경로를 성공으로 캐시하지 않아 이전 이미지 선택으로 복구할 수 있습니다.

SetTexture/SetBlendMode는 고정 Forever 문서의 TextureBase API를 참고했고, 기존 애드온의 Texture 색상 경로와 같은 SetVertexColor를 사용했습니다. 이는 코드 호환성 조사이며 실제 게임 로딩 성공을 관측한 것은 아닙니다. [Forever SimpleTextureBase API](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleTextureBaseAPIDocumentation.lua).

## 감지·퀘스트 제외·기존 기능 보존

감지 범위와 분류 로직, Soft Target CVar 관리 파일은 **변경하지 않았습니다**. 현재 게임이 고른 softinteract GameObject 한 개와 공개 GUID/커서/퀘스트 관련 여부/이름표를 사용합니다. 약초·광맥의 채집 커서 및 검증된 전리품 출처 기반 상자 규칙을 유지하며, 불확실한 상자는 추측하지 않습니다.

C_QuestLog.UnitIsRelatedToActiveQuest가 true 또는 읽기 불가이면 새 조준선을 숨깁니다. 퀘스트 전용 커서도 제외합니다. 이 판정은 게임이 제공하는 정보에 기반하므로 실제 특수 퀘스트 아이템의 반환값/누락 여부 검증은 필요합니다. 기존 **퀘스트 오브젝트 반짝임 유지** 옵션과 네이티브 그래픽 효과는 별도 기능으로 유지하며 새 이미지를 중복 적용하지 않습니다.

기존 약 15m Soft Target 제약, 보호된 보조 Range 값 유지, 핵심 설정이 맞지 않으면 시작 중단, 이름표가 없거나 금지/보호이면 숨김, Lueur 충돌/전투/잠금/복원 기록 정책을 유지합니다. 이번 버전은 20~25m 확장을 구현하지 않습니다.

경험치 바/퀘스트 XP 동기화/직업 색상/파티 프레임/Quest Navigator/Campfire의 기능 코드는 그대로입니다. 전체 TOC와 core/Map/Campfire 표시 버전만 1.11.6.5로 통일하고 **Interface 16001**을 유지합니다. 기존 프로필은 신규 `objectHighlight.offsetX=0`만 보충하며, effect 키에 새 5개 값을 저장합니다. 새 전역 SavedVariables·프로필 초기화·기존 옵션 삭제는 없습니다.

## 변경 파일

| 파일 | 수정 내용 |
| --- | --- |
| `KHQOL/Bootstrap.lua` | 런타임 표시 버전 |
| `KHQOL/CHANGELOG.md` | 현재 릴리스 안내, 이전 기록 보존 |
| `KHQOL/DESIGN.md` | 현재 릴리스 안내, 이전 기록 보존 |
| `KHQOL/INSTALL-GUIDE.md` | 현재 릴리스 안내, 이전 기록 보존 |
| `KHQOL/KHQOL.toc` | TOC Version 1.11.6.5만 변경 |
| `KHQOL/README.md` | 현재 릴리스 안내, 이전 기록 보존 |
| `KHQOL/RETICLES-1.11.6.5.md` | 신규 구현/사용/검증·체크리스트 |
| `KHQOL_Campfire/Campfire/Core.lua` | 내부 버전만 변경 |
| `KHQOL_Campfire/KHQOL_Campfire.toc` | TOC Version 1.11.6.5만 변경 |
| `KHQOL_Clock/KHQOL_Clock.toc` | TOC Version 1.11.6.5만 변경 |
| `KHQOL_CombatStatus/KHQOL_CombatStatus.toc` | TOC Version 1.11.6.5만 변경 |
| `KHQOL_Convenience/KHQOL_Convenience.toc` | TOC Version 1.11.6.5만 변경 |
| `KHQOL_CursorTrail/KHQOL_CursorTrail.toc` | TOC Version 1.11.6.5만 변경 |
| `KHQOL_DevTools/KHQOL_DevTools.toc` | TOC Version 1.11.6.5만 변경 |
| `KHQOL_EnvironmentTimer/KHQOL_EnvironmentTimer.toc` | TOC Version 1.11.6.5만 변경 |
| `KHQOL_ExperienceBar/KHQOL_ExperienceBar.toc` | TOC Version 1.11.6.5만 변경 |
| `KHQOL_Labs/KHQOL_Labs.toc` | TOC Version 1.11.6.5만 변경 |
| `KHQOL_Labs/Media/ObjectReticles/ObjectReticle_01_Cross.tga` | 사용자 제공 TGA 원본 |
| `KHQOL_Labs/Media/ObjectReticles/ObjectReticle_02_Diamond.tga` | 사용자 제공 TGA 원본 |
| `KHQOL_Labs/Media/ObjectReticles/ObjectReticle_03_SegmentedRing.tga` | 사용자 제공 TGA 원본 |
| `KHQOL_Labs/Media/ObjectReticles/ObjectReticle_04_FlatSwirl.tga` | 사용자 제공 TGA 원본 |
| `KHQOL_Labs/Media/ObjectReticles/ObjectReticle_05_OrbitStar.tga` | 사용자 제공 TGA 원본 |
| `KHQOL_Labs/Media/ObjectReticles/README.md` | 자산 출처/형식 안내 |
| `KHQOL_Labs/Modules/GatheringHighlight.lua` | 새 기본 이미지·offsetX 정규화/앵커, 기존 분류 보존 |
| `KHQOL_Labs/Modules/ObjectHighlightDiagnostics.lua` | 1.11.6.5·X/Y·카테고리 스타일·현재 이미지 경로 |
| `KHQOL_Labs/Modules/ObjectHighlightEffects.lua` | 이미지 5종/공유 Texture/색·크기·캐시·실패 복구/기존 효과 정리 |
| `KHQOL_Labs/UI/LabSettings.lua` | 9개 효과 선택·X 슬라이더·위치 초기화·설명 |
| `KHQOL_Labs/UI/SearchIndex.lua` | X/위치 초기화 검색 |
| `KHQOL_Map/Core.lua` | 내부 버전만 변경 |
| `KHQOL_Map/KHQOL_Map.toc` | TOC Version 1.11.6.5만 변경 |
| `KHQOL_NPCAlert/KHQOL_NPCAlert.toc` | TOC Version 1.11.6.5만 변경 |
| `KHQOL_PartyFrames/KHQOL_PartyFrames.toc` | TOC Version 1.11.6.5만 변경 |
| `KHQOL_PvPAlert/KHQOL_PvPAlert.toc` | TOC Version 1.11.6.5만 변경 |
| `KHQOL_QuestNavigator/KHQOL_QuestNavigator.toc` | TOC Version 1.11.6.5만 변경 |
| `KHQOL_Range/KHQOL_Range.toc` | TOC Version 1.11.6.5만 변경 |
| `KHQOL_ResourceSwing/KHQOL_ResourceSwing.toc` | TOC Version 1.11.6.5만 변경 |
| `KHQOL_Threat/KHQOL_Threat.toc` | TOC Version 1.11.6.5만 변경 |
| `KHQOL_Tooltip/KHQOL_Tooltip.toc` | TOC Version 1.11.6.5만 변경 |
| `KHQOL_UnitFrames/KHQOL_UnitFrames.toc` | TOC Version 1.11.6.5만 변경 |

## 이미지 원본 검증

두 입력 ZIP의 TGA는 256×256, 32-bit RGBA, 무압축이며 배경 알파 0을 포함합니다. 5개 모두 제공 PNG와 RGBA 픽셀이 일치하고 런타임 TGA는 입력 ZIP과 SHA256이 같습니다. 모든 RGB 채널이 흰색이어서 기존 색상 설정으로 착색할 수 있습니다. TGA/SVG/PNG의 새 이미지 생성·변환·재가공은 수행하지 않았습니다.

게임 배포에는 TGA 5개와 출처 설명서만 넣고, 원본 PNG/SVG/Preview/제공 README는 결과 폴더의 `texture-originals/`에 보존했습니다. 전체 파일/헤더/알파·입력 ZIP 해시는 ASSET-INVENTORY.json을 확인하세요. 참조용 네이티브 회귀 파일은 validation에만 있으며 다른 애드온의 이미지/미디어를 추가하지 않았습니다.

## 검증 결과·판정

| 검사 | 결과 |
| --- | --- |
| Lua 5.1 전체 구문 | **PASS 218/218** |
| 모의 시나리오 | **PASS 335/335** |
| 이미지 자산 | **PASS 5/5**, 원본 TGA 바이트·PNG 픽셀 일치, 헤더/알파/흰색 검증 |
| 신규 동작 | **PASS (모의)**: 5이미지×3카테고리의 경로·크기·RGBA·X/Y, 퀘스트 제외, Texture 재사용/경로 캐시, 기존 효과 전환, 로드 실패·복구, 실제 UI 콜백/초기화/프로필 캡처, 거리 흐림·잠금 회색 |
| 회귀 | 기존 채팅·오브젝트/CVar·XP·직업색·파티·프로필 시나리오 포함 |
| TOC/배포 | 20개, Version 1.11.6.5 / Interface 16001, 참조 누락 0, 기준 파일 누락 0, CRC·ZIP/소스 바이트 일치 |
| 실제 게임 | **NOT TESTED**: TGA 로딩/색·알파·시야/카메라 정렬/전투·보호/특수 퀘스트 판정/설정 UI 그래픽/Reload |

모의 Frame/Texture 테스트와 파일 검사로 WoW 엔진·서버·Secret 보안 권한을 검증한 것은 아닙니다. 최종 판정은 **LIMITED GO — 구현·자동 검증 완료, 실제 게임 확인 필요**입니다.

## 설치·실게임 체크리스트

전체 ZIP은 **20개 폴더·316파일**입니다. 게임 종료 → 기존 코드/WTF 백업 → ZIP 최상위 애드온 폴더 교체 → 로그인. **WTF/SavedVariables는 유지**하세요. 게임 설치 폴더에 자동 적용하지 않았으며 Git commit/push하지 않았습니다.

아래는 모두 실제 미실행 상태입니다.

- [ ] 세 카테고리 각각 이미지 01~05를 선택해 누락/뒤집힘/직사각형 배경 없이 로드되는지 확인.
- [ ] 색상/크기/투명도/X/Y 및 위치 초기화를 확인. 거리 흐림/상호작용 불가 회색과 사용자 색상 저장을 구분.
- [ ] 퀘스트 관련 오브젝트에는 조준선이 없고 기존 퀘스트 반짝임만 유지. NPC/플레이어/일반 상호작용/찌/모닥불 제외 확인.
- [ ] 이미지↔기존 효과 전환, 대상/이름표 소실, 전투/모듈 OFF/카테고리 OFF/잠금/프로필 전환/Reload에서 잔상·옛 효과가 없는지 확인.
- [ ] 기존 XP·직업 색상·파티·Quest Navigator·Campfire/설정과 사용자 프로필이 유지되는지 확인.
- [ ] 표시 실패 시 `/오브젝트진단`의 버전/스타일/image 경로/stage/lastRenderError를 확인.
