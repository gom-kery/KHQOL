# KHQOL 1.10.4.0 모닥불 통합 경계

현재 모닥불은 이미 KHQOL 메인 TOC가 로드하는 모듈입니다. `KHQOL.modules.campfire`를 공유하며 `CampfireAlertDB`의 기존 저장 이름과 설정 연결을 보존합니다. 아래의 독립 설치·향후 편입·새 마이그레이션 계획은 과거 기록으로, 현재 작업 지침이 아닙니다.

Aura 읽기는 `aura, status`를 반환합니다. `present`/`absent`만 확인된 결과이며 `missing`/`error`/`unreadable`는 불확실합니다. `HasPlayerAura`의 첫 반환은 확인된 true/false 또는 불확실한 nil입니다. 실제 상태 전환은 불확실한 값을 버프 없음으로 확정하지 않습니다. 현대 Forever 타깃 조회는 `GetPlayerAuraBySpellID(spellID)` 단일 인자를 사용하고, 필드 정규화도 보호합니다.

OFF·프로필 변경·새 대기 이후 이전 콜백은 상태 객체/serial/generation 검사로 무효화합니다. 이 문서는 데이터 초기화나 별도 독립 애드온 설치를 요구하지 않습니다.

## 과거 독립 버전 편입 메모

---

# KHQOL 편입 메모

CampfireAlert는 현재 독립적으로 설치·배포되는 WoW Forever 애드온이다. 이 문서는 향후 KHQOL의 독립 모듈로 편입할 때 필요한 최소 변경 사항만 기록한다.

## 현재 경계

- `Core.lua` — 상태 머신, 이벤트 등록, SavedVariables 초기화, 타이머 및 거리 실험 기능
- `Aura.lua` — 클라이언트별 Aura API 호환 계층
- `UI.lua` — 프레임 생성, UI 입력, 위치·크기 적용
- `Debug.lua` — `/cfa` 명령 및 진단 출력
- `CampfireAlertDB` — 이 애드온만 사용하는 SavedVariables. `debug`, `position`, `iconSize`, `fontSize`만 보관한다.

코드 내부 공유 테이블은 로드 인수로 받은 지역 `CFA`이며, 다른 애드온에 전역으로 노출하지 않는다. 전역 이름은 독립 배포에 필요한 `CampfireAlertDB`, `SLASH_CAMPFIREALERT1/2`, `SlashCmdList.CAMPFIREALERT`로 한정한다.

## 편입 시 최소 작업

1. KHQOL의 모듈 등록 방식으로 네 Lua 파일을 로드하되, `CFA`를 KHQOL의 CampfireAlert 모듈 테이블로 전달한다.
2. KHQOL이 자체 설정 저장소를 사용한다면 `CampfireAlertDB`의 네 설정값만 모듈 전용 경로로 한 번 마이그레이션한다. 독립 애드온이 함께 활성화된 경우에는 중복 이벤트·UI를 피하기 위해 둘 중 하나만 로드한다.
3. KHQOL 명령 체계가 제공되면 `/cfa`를 그 명령의 하위 명령으로 연결한다. 독립 버전의 slash 전역은 모듈 버전에서 등록하지 않는다.
4. KHQOL 공통 설정 UI가 생기면 위치·크기·debug 값만 연결한다. 현재 UI·상태 머신·Aura 호환 계층은 그대로 유지한다.

## 편입 시 유지할 원칙

- `UNIT_AURA` 기반 감지와 활성 상태에서만 실행되는 ticker 정책을 유지한다.
- `CampfireAlertDB` 외의 독립 애드온 SavedVariables를 읽거나 쓰지 않는다.
- 거리 실험 기능은 `ClosestGameObjectPosition` API와 알려진 GameObject ID가 있을 때만 활성화한다.
- KHQOL 편입 전까지는 이 애드온의 TOC, slash 명령, SavedVariables를 변경하지 않는다.
