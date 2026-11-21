# 구현된 최소 로컬 진단 계약

이번 사용자 요청에서 필요한 최소 진단 인터페이스와 호출 위치는 승인되었습니다. 이 문서는 이전 제안서를 대체합니다. 엔진·집계·저장·화면·내보내기는 DevTools에 있고, KHQOL에는 통계 DB나 Usage 메뉴를 추가하지 않았습니다.

## protocol 1 / revision 2

`KHQOL.UsageDiagnostics:Subscribe(ownerTable, callback, 1)` → true/false. 소유자별 한 구독, 최대 8개입니다. `Unsubscribe(ownerTable)`로 해제합니다. `Capabilities()`는 현재 지원되는 정적 ID의 true 집합입니다. `Supports(id)`로 개별 기능을 확인합니다. protocol 불일치/구독 실패는 지원 DIRECT만 사용합니다.

callback의 인자는 `(id, phase, path, reason, changed)`뿐입니다. 임의 payload·함수 인자·이름·좌표·설정값·초안·오류 원문은 없습니다. ID는 고정 목록, changed는 boolean입니다.

| 필드 | 허용 값 |
|---|---|
| phase | change, start, save, changed, cancel, unconfirmed, request, execute, draft, processed, display |
| path | click, drag, input, arrow, unknown |
| reason | explicit, escape, combat, profile, navigation, hidden, world, validation, apply, unavailable, unknown |

일반 설정은 공통 commit 전후의 소유 getter 값만 임시 비교합니다. 색상은 native OK post-click과 취소·숨김을 구분합니다. ColorPicker OkayButton을 확인할 수 없는 클라이언트는 색상 최종 계측을 미지원으로 표시합니다. 프로그램 닫기를 확정으로 추측하지 않습니다.

위치 편집은 원래 유효 진입과 최종 종료 판정을 그대로 사용합니다. writer/reset/apply 순서·반환값을 보존하고, writer/apply가 원래 오류를 내면 진단은 확인 불가만 알린 뒤 원래 오류를 그대로 다시 전달합니다. 진단 수신 오류는 pcall로 격리합니다. 저장 종료는 내부 저장 루틴 종료이며 모든 서버/픽셀 상태 성공을 뜻하지 않습니다. 최소 한 소유 getter의 최종 저장 위치가 달라질 때 changed입니다. getter가 없는 writer는 unconfirmed이며 좌표를 수신자에게 보내지 않습니다.

기능 호출 위치는 INSTRUMENTATION.md에 고정 ID별로 있습니다. 퀘스트는 두 사용자 선택 지점 뒤 실제 supertrack 변경만, 수리/전송은 API 호출 시도만, 판매는 처리 증거만, 모닥불은 live 원인만, Proc는 테스트/재적용을 제외한 신규 실제 표시 전환만 전달합니다.

## 연결·해제·수명

- DevTools는 기록 ON에서 지원 여부 확인 후 한 owner를 구독합니다. 재연결해도 중복 등록하지 않습니다.
- 같은 지표의 BRIDGE가 선택되면 기존 DIRECT observer는 해당 지표를 즉시 건너뜁니다. 기존 post hook은 되돌려 갈아끼우지 않고 OFF에서 즉시 반환합니다.
- OFF/초기화/월드 이탈/로그아웃은 구독 해제, pending 입력·탐색·재연결·자정 작업의 세대 무효화를 수행합니다. reset 뒤 과거 판매 작업이 다시 들어오지 않습니다. 다른 진단 구독자가 있어도 티켓이 무효화됩니다.
- KHQOL은 구독자 0명일 때 즉시 반환합니다. getter 비교/이벤트 payload 생성/통계용 타이머·주기 작업이 없습니다. 컨트롤 고정 ID 표와 함수 정의는 로드되지만 통계 저장소를 만들지 않습니다.
- callback 오류를 덤프하지 않습니다. 원래 게임 함수·보호 동작·클릭 결과·실행 순서를 변경하지 않습니다. Blizzard spellbook 함수에는 hook이나 대체 함수를 설치하지 않습니다.

원래 source의 위치 읽기와 native 색상 버튼을 확인할 수 없는 범위는 LIMITED/미연결입니다. 실제 Forever의 보안 실행 환경은 모의로 재현할 수 없어 인게임 NOT TESTED이며, 마법책 회귀 확인 전 일반 배포 HOLD입니다.
