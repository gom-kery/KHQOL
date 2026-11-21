# KHQOL DevTools 0.4.0

KHQOL 1.12.0의 표시 경로에 대응합니다. catalog 13 / schema 1 / protocol 1과 기존 통계 ID·누적 기록을 유지합니다. 기록 기본 OFF, 새 개인정보/입력값 수집 없음. 논리 원문으로 컨트롤을 다시 연결하며 새 카테고리는 설정 변경·게임 기능 실행으로 집계하지 않습니다. 이전 Core에서는 기존 경로로 동작합니다. Full과 별도 DevTools ZIP의 파일은 동일합니다. 실제 게임 검증은 NOT TESTED입니다.

---

아래는 이전 버전 기록입니다.

# KHQOL DevTools 0.3.11

KHQOL1.11.9.6 대응, catalog13/schema1/protocol1. 기록 기본OFF. 기존 통계ID/정의/이력은 유지하고 새 UI 명칭·위치에 별칭을 연결합니다. 실험실 NPC/PVP/아이템 보호 메뉴 경로를 추가했습니다. 등록 그룹 안의 정적인 기본 버프 스위치만 기존ID로 집계하며 입력한 주문/직업/소지품/중첩/시간 값을 새로 수집하지 않습니다.

같은 한글 제목이 체크박스에서 효과 선택으로 바뀐 경우 컨트롤 종류를 확인하여 기존 체크박스ID에 잘못 집계하지 않습니다. Full/별도 ZIP의 DevTools는 동일합니다. 실제 게임 검증은 NOT TESTED입니다.

---

아래는 이전 버전 기록입니다.

# KHQOL DevTools 0.3.10

KHQOL1.11.9.5 대응, catalog12/schema1/protocol1, 기록 기본OFF. 전문기술 상단 사용 토글은 기존 control009, 1/2줄 배치는 기존 control013, 숙련 단계 안내는 기존 guide.enabled로 집계합니다. 기존 정의/ID/누적 데이터는 유지합니다. 새 글자·좌표·소지품·오라 시간/중첩을 수집하지 않습니다.

새 Core의 상단 사용자 지정 사용 토글을 연결하며 이전 Core에서는 기존 모듈 토글 경로를 유지합니다. Full과 별도 ZIP의 DevTools는 동일합니다. 실제 게임 검증은 NOT TESTED입니다.

---

아래는 이전 버전 기록입니다.

# KHQOL DevTools 0.3.9

KHQOL1.11.9.3 대응 catalog11/schema1/protocol1, Usage 기본OFF. 이전1,732개 고정 등록 행을 보존하고 포만감/휴식 기본 감시·침낭 사용/배치·음식 배치의 설정5개를 추가했습니다. 직업/좌표/입력/소지품/조회 대상/특성 수치를 새로 수집하지 않습니다.

과거 전문기술 노트 지원 토글의 ID는 이전 로그 해석용으로 보존합니다. 현재는 기본 지원이며 그 토글을 생성/계측하지 않습니다. 우클릭 설정 이동은 기존 메뉴 방문, 일반 위치 잠금은 설정 변경이며 Position Editor 시작이 아닙니다. 음식 단계 계측은 기존 의미를 유지하고 침낭 클릭을 음식 요청으로 집계하지 않습니다.

실제 게임 검증은 NOT TESTED입니다. Full/별도ZIP 파일은 같습니다.

---

아래는 이전 버전 기록입니다. 현재 사용법은 위 안내를 따릅니다.

# KHQOL DevTools 0.3.8

KHQOL1.11.9.2 대응. catalog10/schema1/protocol1, Usage 기본OFF입니다. 이전1,716개 고정 등록 행을 보존하고 측정 방식·보호막 측면/전투 표시·HUD텍스트X/Y/색상/선택초기화의 고정 설정7개를 추가했습니다. 최대 거리의 새 제목은 기존 setting.range.control008/009에 이어 기록합니다. 편집 텍스트 대상 선택은 설정값으로 집계하지 않습니다. 텍스트/색상 값·거리 원문·단위별 실제 수치·오라 내용은 수집하지 않습니다.

DevTools OFF 기능과 기존 로그·음식 단계·위치 계측 의미는 유지합니다. 반복 HUD 갱신은 설정 변경이 아니며 일반 위치 잠금은 Position Editor start가 아닙니다. Full과 별도ZIP은 동일합니다. 실제 게임은 NOT TESTED입니다.

---

아래는 이전 버전의 기록입니다. 현재 사용법은 위 안내를 따릅니다.

# KHQOL DevTools 0.3.7

KHQOL 1.11.9.1용 선택 개발 도구입니다. Full 포함본과 별도 ZIP은 동일합니다. Usage는 기본 OFF이며 schema1/protocol1과 과거 로그·버전 이력을 유지합니다.

- catalog9. 1.11.9.0의 고정 등록 1,680행을 보존하고 마크 위치 12개·보호막 옵션 6개의 설정 ID를 추가했습니다.
- 사용자 거리 행을 기본 행 사이로 이동해도 기존 고정 설정 ID를 사용합니다. 이름·거리·좌표·음식 ID·흡수량 자체는 통계에 저장하지 않습니다.
- 음식 request는 직접 아이콘 클릭, used는 그 요청과 실제 식사 시작 확인, well_fed는 귀속된 식사 뒤 실제 포만감 확인입니다. 시간 경과·반복 Refresh·가방 클릭/리로드의 시각 복원만으로 해당 성공 카운터를 늘리지 않습니다.
- 기존 위치 잠금은 설정 변경이며 Position Editor start가 아닙니다. 신규 마크/보호막 기능은 DevTools를 꺼도 동작합니다.

실제 게임과 보호 API 검증은 NOT TESTED입니다. 상세 결과는 KHQOL의 RELEASE-1.11.9.1.md와 배포 REPORT.md에 있습니다.

---

아래는 이전 버전의 기록입니다. 현재 사용법과 제한은 위 안내를 따릅니다.

# KHQOL DevTools 0.3.6

KHQOL 1.11.9.0용 선택 개발 도구입니다. Full 포함본과 별도 ZIP은 같은 파일입니다. Usage는 기본 OFF이며 schema1/protocol1을 유지합니다.

- catalog revision8. 기존 고정 등록 행1,643개 보존, 새 설정18개(글로우2/음식4/거리10/좌측2) 및 음식 요청/섭취 확인/포만감 확인3개 feature ID 추가.
- 편의 기능으로 이동한 버프 리마인더 방문은 과거 menu.labs.buff ID에 이어 기록합니다. ID 이름은 과거 위치이며 현재 경로는 편의 기능입니다.
- 새 색상 행은 이름·좌표·입력값을 기록하지 않고 고정 필드별 변경 횟수만 기록합니다. 미리보기·취소·Refresh는 변경이 아닙니다.
- 음식 클릭 요청은 소비 성공이 아닙니다. 배포 음식 검증 목록은0개여서 실제 음식 used/well_fed 계측은 미지원 상태입니다. 테스트의 합성 음식은 설치본에 들어가지 않습니다.
- 기존 진단/프레임 도구·로그·관찰 날짜·버전 이력은 보존합니다. 실제 게임/보호 API는 NOT TESTED입니다.

---

# KHQOL DevTools 0.3.5

KHQOL 1.11.8.24의 Shift 휠 업/다운 주문 설정 ID 두 개를 추가했습니다. catalog revision 7, Usage v0.1/schema 1/protocol 1입니다. 기존 1,639개 카탈로그 행과 로그·버전 이력을 유지합니다. 보조키 편집 선택은 계측하지 않고 실제 등록/해제 변경만 해당 설정에 집계합니다.

알람·타이머/타이머 바의 창별 일시 잠금은 기존 setting.clock.toolsLocked / timerBarLocked ID를 사용합니다. .24부터 직접 아이콘·세션 범위이며 이전 버전은 저장형 또는 공유 잠금이었으므로 버전 이력을 함께 해석하세요. 과거 ID/정의는 보존하고 제품 설정/검색의 중복 행만 제거했습니다. 잠금 해제는 Position Editor start가 아닙니다.

좌표 원문·지도·메모·주문 ID·실패 문자열을 새 진단에 넣지 않습니다. 전문기술의 실제 새 항목 등록만 완료이고 공통 API의 duplicate는 완료가 아닙니다. DevTools OFF/미설치에서도 기능을 실행합니다. 실제 클라이언트 검증은 NOT TESTED입니다. Full과 별도 DevTools ZIP은 같습니다.

---

# KHQOL DevTools 0.3.4

KHQOL 1.11.8.22의 파티/공격대 위치 잠금 ID 2개를 추가했습니다. catalog revision 6, Usage v0.1/schema 1/protocol 1입니다. 기존 1,635개 카탈로그 행과 로그·버전 이력을 보존합니다. 잠금은 설정 변경이고 앵커 표시·드래그는 Position Editor 시작이 아닙니다. 기존 전문기술 표시·등록 요청·실제 등록 완료의 의미는 유지합니다. 기록 OFF와 DevTools 미설치에서도 위치/전문기술 기능이 동작합니다.

Full에 같은 0.3.4가 들어 있습니다. 별도 DevTools ZIP은 DevTools만 교체할 때 사용합니다. 실제 게임 검증은 NOT TESTED입니다.

---

# KHQOL DevTools 0.3.3

KHQOL 1.11.8.21 위치 잠금·오라 설정 ID 33개를 추가했습니다. catalog revision 5이며 기존 ID/로그/버전 이력, Usage v0.1/schema 1/protocol 1은 유지합니다. 잠금 토글은 설정 변경으로 계측하며 이동 테두리 표시나 드래그를 Position Editor 시작으로 기록하지 않습니다. 시계의 통합 잠금은 기존 toolsLocked ID를 사용하고 timerBarLocked의 과거 정의/로그는 보존합니다.

기록 OFF의 기존 의미는 유지하며 위치 기능은 DevTools 없이도 동작합니다. 새 좌표·프로필명·설정 원본값을 수집하지 않습니다. Full에 같은 0.3.3이 포함되며 별도 DevTools ZIP은 DevTools만 교체할 때 사용합니다. 보호 동작의 실제 게임 확인은 NOT TESTED입니다.

---

# KHQOL DevTools 0.3.2

KHQOL 1.11.8.19의 신규 위치 잠금 설정 ID `setting.generalConvenience.buffThanks.locked`를 추가했습니다. 카탈로그 revision 4, Usage v0.1/schema 1/protocol 1을 사용하며 기존 ID·로그·버전 이력을 유지합니다. 잠금 조작은 setting change이고 Position Editor start가 아닙니다. 이동 예시는 실제 버프 알림 표시나 감사 실행으로 집계하지 않습니다.

---

# KHQOL DevTools 0.3.1

KHQOL 1.11.8.18의 다음 숙련 안내와 상단 잠금 계측을 연결합니다. 기존 ID는 변경하지 않았습니다. schema 1/protocol 1/Usage v0.1은 그대로이며 catalog revision은 3입니다.

추가 설정은 안내 enabled/locations/notes와 기존에 미계측이던 buffReminder.locked입니다. feature.profession.guide(실제 안내 구간), note_request(우클릭 요청), note_added(실제 새 항목), navigate(기존 안내 시작 true)를 구별합니다. 메뉴 열기·Refresh·중복 항목·거부는 완료가 아닙니다.

기록 OFF는 기존대로 수집하지 않습니다. 안내 기능 자체는 DevTools 미설치에도 동작합니다. 이전 0.3.0과 함께 사용하면 새 지표를 인식하지 못할 수 있으나 기존 기능은 유지됩니다. 개인정보·NPC·좌표·숙련값·노트 본문을 새 지표에 넣지 않습니다.

---

# KHQOL DevTools 0.3.0 / Usage Analytics 0.1

KHQOL **1.11.8.14 Full**과 함께 쓰는 수집 준비판입니다. Usage **schema 1**, catalog revision **2**, 로컬 진단 protocol **1**입니다. 기본 기록은 **OFF**이며 기존 0.2.0 저장 통계를 이어받습니다. 엔진·저장·조회·내보내기는 DevTools가 소유합니다.

**정적·모의 기준 LIMITED GO / 실제 WoW Forever NOT TESTED.** 보고된 마법책·접속 종료 차단에 대응해 공용 팝업 변경을 제거했으나 게임에서 수정 확인을 하지 못했습니다. **일반 배포 판정은 해당 회귀 확인 전 HOLD**입니다. 먼저 [보호 동작 확인](PROTECTED_ACTIONS.md)을 수행하세요.

## 설치·교체

1. 정상 종료 또는 /reload로 기존 기록을 저장한 다음 게임을 종료합니다. 필요하면 WTF의 계정 SavedVariables `KHQOL_DevTools.lua`와 `KHQOL.lua`를 직접 별도 보관합니다.
2. `KHQOL-1.11.8.14-Full.zip`의 모든 애드온 폴더를 `Interface\AddOns`에 덮어씁니다. 이 Full에 DevTools 0.3.0도 포함되어 있습니다. 별도 `KHQOL_DevTools-v0.3.0-Full.zip`은 DevTools만 교체할 때 사용하는 동일 소스입니다. ZIP을 두 겹 폴더로 풀지 마세요.
3. 애드온 목록에서 필요한 KHQOL 기능 폴더와 KHQOL DevTools를 활성화합니다. WTF·SavedVariables를 삭제하거나 패키지 파일로 교체하지 않습니다.
4. 먼저 기록 OFF로 마법책과 비전투 접속 종료를 확인합니다. 이어 `/khqoldev usage`에서 **기록: ON**을 누르고 짧은 확인 행동을 합니다. 기존 ON 사용자는 ON 상태도 보존됩니다. 설치만으로 자동 초기화하지 않습니다.

마법책 문제부터 분리 확인할 때는 **현재 KHQOL 1.11.8.13을 유지하고 DevTools 0.3.0만 먼저 교체**할 수 있습니다. 새 계측 전체를 사용하려면 이후 Full 1.11.8.14를 함께 설치합니다.

## 사용

- `/khqoldev`, `/khqoldev console`, `frames`, `position`: 기존 도구.
- `/khqoldev usage`: 7일/30일·요약/전체·새로고침·JSON 복사·확인 후 초기화.
- Usage 화면은 탭을 처음 열 때 만듭니다. 통계 조회와 JSON 생성은 관찰 카운터를 바꾸지 않습니다. ON이면 화면을 열어 두지 않아도 수집합니다.
- Frame Stack은 사용자가 해당 버튼을 누를 때 전투 밖에서만 Blizzard_DebugTools를 요청합니다. 자동 의존 로딩을 제거했습니다.
- 통계 초기화는 DevTools 전용 확인창을 사용합니다. Blizzard 공용 확인창 목록을 다시 대입하거나 항목을 등록하지 않습니다.
- Console은 별도 도구입니다. 게임 출력과 제한된 보호 동작 진단을 메모리에 표시할 수 있으나 Usage DB·JSON으로 복사하지 않습니다.

## 호환·연결 표시

| 조합 | 동작 |
|---|---|
| KHQOL 1.11.8.14 + DevTools 0.3.0 | DIRECT 재사용 + 필요한 최소 BRIDGE. 인게임 검증 대상 |
| KHQOL 1.11.8.13 + DevTools 0.3.0 | 기존 DIRECT 범위만. 색상 최종 확정·최종 위치 결과·새 기능 이벤트 등 미지원 표시 |
| DevTools 단독 | Frames·Console·Position·기존 통계 조회 가능. KHQOL 사용 행동 수집 미지원 |
| KHQOL 1.11.8.14, DevTools 없음 | 원래 기능 실행. 진단 구독자가 없어 즉시 반환 |
| 진단 protocol 불일치 | 구독하지 않음. 지원되는 DIRECT만 선택, BRIDGE 미연결 표시 |

`class`는 설계 방식, `selectedRoute`는 현재 대표 경로, `connected`는 연결 여부, `inGame`은 검증 단계입니다. OFF에서는 BRIDGE 구독이 해제됩니다. 과거 자료의 `observedRoutes`·`observedVersions`는 유지됩니다. `observedDays=0`은 미계측이고, 관찰된 범위의 0회와 다릅니다.

## 저장·시간·개인정보

계정 공용 `KHQOLDevUsageDB`에 UTC 날짜별 집계만 보관합니다. 정상 로그아웃·리로드 때 게임이 파일에 저장하며 비정상 종료 직전 변경은 보장하지 않습니다. ON에서 오늘 포함 최근 30일을 보관하고, OFF는 기존 통계를 시간 경과만으로 삭제하지 않습니다. 조회는 오늘 포함 7일/30일입니다.

메뉴 최종 목적지를 한 번 기록합니다. Refresh·프로필·자동 복귀는 새 방문에서 제외합니다. GetTime 경과를 UTC 자정에 나눕니다. 한국 시간 UTC 자정은 오전 9시입니다. 연속 체류 상한은 30분이며 조회나 자정으로 상한이 재시작되지 않습니다. 평균은 누적 초 / 양수 체류가 있는 날짜별 유효 방문 표본입니다. AFK 공개 상태를 읽을 수 있으면 체류를 제외합니다. 게임 창 비활성 시간은 제외하지 못합니다.

이름·서버·GUID·계정/테스터 식별자·채팅·노트·좌표·설정값 원본·프로필명·오류 원문은 통계/진단에 넣지 않습니다. 임시 비교 값은 원래 소유 코드의 메모리에서 조작 종료 때 폐기합니다. 원본 이벤트 누적·업로드·애드온 통신은 없습니다.

[계측 목록](INSTRUMENTATION.md), [스키마](SCHEMA.md), [BRIDGE 계약](BRIDGE_PROPOSALS.md), [검증 체크리스트](VERIFICATION_USAGE.md), [14일 관찰](OBSERVATION_14_DAYS.md), [변경 보고](CHANGE_REPORT.md)를 함께 보세요. `example-usage.json`은 가상 데이터입니다. `VALIDATION.md`와 `POSITION_DIAGNOSTICS.md`는 보존한 이전 도구 문서이며 이번 게임 검증 결과를 뜻하지 않습니다.
