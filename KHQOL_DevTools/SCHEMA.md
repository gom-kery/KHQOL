# Usage Analytics 0.1 — schema 1 / catalog revision 2

`KHQOLDevUsageDB`는 계정 공용 통계, `KHQOL_DevToolsDB`는 기존 도구 옵션입니다. 기존 schema 1에 선택 필드를 추가했습니다. 기존 ID의 숫자·의미와 UTC를 유지하며 0.2.0 과거 관찰 날짜/버전을 새 연결 자료로 소급 변경하지 않습니다.

| 저장 경로 | 의미 |
|---|---|
| schema / usageVersion / catalogRevision | 1 / 0.1 / 2 |
| enabled | 최초 false, 기존 값 보존 |
| firstDate / lastDate | 누적 관찰 자료의 최초/최근 UTC 날짜. 보관 정리 뒤에도 전체 수집 이력 경계일 수 있음 |
| days[date].recordingSeconds | ON 관찰 초, AFK 포함. 날짜 전체 완전 관찰 아님 |
| days[date].menus[id] | visits, seconds, validVisits |
| days[date].settings[id] | changes, paths[drag/arrow/input/click/unknown] |
| days[date].features[id] | count, active(boolean), 선택 reasons[고정 취소·불명 사유] |
| days[date].observed[id] | 해당 날짜 연결되어 관찰 가능했거나 실제 작동한 지표 |
| days[date].routes[id] | 선택 direct=true / bridge=true. 같은 날 경로 변경 시 둘 다 가능. 이전 날짜에 소급 생성 안 함 |
| days[date].versions[pair] | 실제 관찰 KHQOL/DevTools 쌍. 예: 1.11.8.13/0.2.0, 1.11.8.14/0.3.0 |
| days[date].versionsLimited | 하루 버전 종류 상한 도달 |
| diagnostics[fixedCode] | callback, hook, clock, dwell_capped, version_limit 횟수 |

지표 설명은 배포 카탈로그에만 있습니다. 무제한 임의 ID·원본 이벤트·타임스탬프 목록·설정값을 저장하지 않습니다. 원본 값의 비교는 메모리의 임시 조작 범위에 한정합니다.

## 정규화·기존 데이터

카운터는 0~1,000,000,000 정수, 날짜별 단일 메뉴 초/기록 초는 0~86,400입니다. 날짜는 2000~2100 실제 달력 날짜, ID는 카탈로그의 최대 96 ASCII 문자입니다. 버전 각 32자, 하루 버전 쌍 최대 8개입니다. NaN/무한/음수/문자 숫자는 유효 수치로 보지 않습니다. 알려진 필드만 재구성하고 유효 카운터를 보존합니다. 알 수 없는 필드/ID/사유는 내보내지 않습니다.

정상 OFF에서는 시간 경과만으로 저장 자료를 지우지 않습니다. 비정상 30개 초과 로드 자료는 최신 30개로 제한하고, ON에서는 오늘 포함 30일 밖/미래 날짜를 정리합니다. 기존 firstDate/lastDate는 유지하되 lastDate가 실제 저장 일자보다 작았던 자정 역행 오류는 실제 최신 저장 날짜까지 복구합니다. 기존 카운터는 바꾸지 않습니다.

더 높은 schema는 원본 전역 테이블을 보존하고 기록·초기화를 차단합니다. 알 수 없는 원문은 JSON에 복사하지 않습니다. 하위 도구로 되돌리면 추가 metadata 필드가 제거될 수 있어 다운그레이드는 권장하지 않습니다.

## 시간·정산

GetTime 경과를 시작 UTC epoch에 더해 자정에 나눕니다. 역행은 0, 연속 체류 상한 1800초입니다. 평균 분모는 양수 체류가 있는 날짜별 유효 방문 표본입니다. 같은 방문의 자정 분배는 날짜별 표본이 되고, 자동 복귀·AFK 재개는 같은 방문 표본을 잇습니다. 사용자 방문 수와 분모는 다를 수 있습니다. 부모 행에 하위 방문을 다시 합산하지 않습니다.

조회·JSON 내보내기는 정규화한 복사본에 미정산분을 더하며 원본 DB·구간 커서를 바꾸지 않습니다. OFF·메뉴 이탈·창 닫기·월드 이탈·로그아웃에서 한 번 정산합니다. ON 재개 전 OFF 시간은 제외합니다. 자정 1회 타이머와 최종 탐색/재연결의 다음 회차 작업만 쓰며 통계 OnUpdate/Ticker는 없습니다.

## JSON

UTF-8 객체 형식입니다. 날짜/ID 키 객체를 사용하고 배열은 없습니다. schema/usageVersion/devToolsVersion/catalogRevision은 내보내는 도구 버전입니다.

- `currentInstallation`: 현재 khqolVersion/devToolsVersion/bridgeProtocol. 과거 기록 버전과 별개입니다.
- `range`: 오늘 포함 days=7 또는 30, from/to, timeBasis=UTC.
- `collection`: 현재 enabled/paused, 최초·최근 날짜, AFK·배경 감지 여부, KHQOL 설치, bridgeStatus/bridgeProtocol, futureSchemaPreserved, inGame=NOT TESTED.
- `days`: 선택 기간 모든 날짜. 없으면 noData=true. OFF/미접속/보관 종료를 구분하지 못합니다.
- `totals`: 메뉴 visits/seconds/validVisits/averageSeconds, 설정 changes/paths, 기능 count/activeDays/reasons.
- `observedVersions`: 선택 기간 실제 버전 쌍 합집합.
- `instrumentation[id]`: class(설계 방식), selectedRoute(현재 경로), connected/available, fallback, observedDays, observedRoutes, verdict(정적·모의), inGame=NOT TESTED, 의미·제한.
- `rules`, `diagnostics`: 정적 정책과 제한된 오류 횟수. Console/security 원문 없음.

`observedDays=0`은 미계측입니다. 연결되어도 OFF라면 새 관찰 날짜가 생기지 않습니다. 관찰된 0회도 해당 날짜 전체가 완전 관찰됐다는 뜻은 아닙니다. 연결 범위가 넓어진 뒤 단순 전후 총횟수 비교는 피하세요. 새 지표는 실제 연결 날짜부터 해석합니다.

example-usage.json은 exampleOnly=true인 **가상 데이터**입니다. 일반 메뉴 1회/120초, 잠금 변경 1회(BRIDGE), 노트 1회(DIRECT), Clock 활성 1일, ESC 위치 취소 1회입니다. 현재 OFF여도 과거 집계를 유지하는 사례이며 실제 개인·테스터 자료가 아닙니다. 예시 표시 필드는 SavedVariables 필드가 아닙니다.
