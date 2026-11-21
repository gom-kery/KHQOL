# 0.4.0 — 2026-11-21

새 화면/기존 소유자와 통계 연결. 기존 카탈로그·번호·저장 스키마·프로토콜 보존.

---

# 0.3.11 — 2026-11-20

catalog13. 이름/그룹이 바뀐 정적 설정의 기존ID 연결과 실험실 메뉴3개 추가. 과거 정의·binding·alias 보존. 정적 기본 버프 컨트롤의 등록 그룹 내 계측 지원. 같은 제목의 체크박스/드롭다운을 종류로 구분. schema1/protocol1 및 기존 누적 데이터 보존. 새 값 원본 수집 없음.

---

아래는 이전 버전 기록입니다.

# 0.3.10 — 2026-11-20

catalog12: 전문기술 표시 명칭의 추가 별칭을 기존 고정 ID에 연결. 상단의 사용자 지정 사용 토글 getter/ID를 bridge와 이전 방식 관찰 경로에 반영. schema1/protocol1 및 기존 정의/누적 로그 보존. 새 이벤트/개인 값 수집 없음.

---

아래는 이전 버전 기록입니다.

# 0.3.9 — 2026-11-20

catalog11. 고정 설정5개 추가, 이전1,732행·로그·schema1/protocol1 보존. 삭제된 전문기술 notes 토글의 정의는 이력용으로 유지. 새 문자열/소지품/특성 자료 수집·통계 polling·기본 UI 함수 교체 없음. DevTools OFF 기능 모의 검사 PASS, 실제 게임 NOT TESTED.

---

아래는 이전 버전 기록입니다. 현재 사용법은 위 안내를 따릅니다.

# 0.3.8 — 2026-11-20

catalog10. KHQOL1.11.9.2의 고정 설정7개 추가, 기존 최대 거리 제목 alias 추가. 기존1,716행·schema1/protocol1·로그 보존. 숫자/좌표/색상/식별값 수집·새 게임 UI 함수 교체·통계용 반복 조회 없음. 정적·모의 PASS, 실제 게임 NOT TESTED.

---

아래는 이전 버전의 기록입니다. 현재 사용법은 위 안내를 따릅니다.

# 0.3.7 — 2026-11-19

KHQOL 1.11.9.1의 마크 위치 설정 12개와 환경 타이머 보호막 설정 6개 고정 ID를 추가했습니다. catalog9/schema1/protocol1. 기존 1,680행과 로그를 보존합니다. 음식의 실제 식사/포만감 확인은 기존 feature ID와 직접 요청 귀속을 유지합니다. 새 API 함수 교체·값 수집·analytics 반복 조회는 없습니다. DevTools OFF 모의 검사 PASS, 실제 WoW Forever 검증은 NOT TESTED입니다.

---

아래는 이전 버전의 기록입니다. 현재 사용법과 제한은 위 안내를 따릅니다.

# 0.3.6

KHQOL1.11.9.0의 고정 설정18개와 음식 단계3개 ID를 연결했습니다. 새 버프 메뉴를 역사적 menu.labs.buff로 alias하고 feature bridge phase를 명시했습니다. catalog8/schema1/protocol1. 기존 고정 등록1,643행 및 저장 이력은 유지합니다. 새 raw 값 수집/게임 함수 교체/analytics polling은 없습니다. 실제 음식 자동 선택·포만감은 검증 자료 확보 전 제한되며 실제 게임 검증은 NOT TESTED입니다.

---

# 0.3.2 — 2026-11-19

- 버프 알림 독립 위치 잠금의 고정 설정 ID 1개 추가, KHQOL 1.11.8.19 호환.
- 기존 0.3.1 카탈로그/전문기술 지표/로그/schema 1 유지. 새 게임 기본 UI 훅 없음.
- 이전 변경 기록은 아래에 보존.

---

# 0.3.1 — 2026-11-19

- 기존 ID/스키마 유지, 새 안내/잠금 고정 지표와 bridge phase 연결.
- 새 버전 표시 0.3.1, catalog revision 3. 자동 게임 API 실행/새 관찰 훅 없음.
- LOCKS-PROFESSIONS-REPORT.md의 정적·모의 검증 통과. 실제 게임 NOT TESTED.

---

# 변경 기록

## DevTools 0.3.0 / KHQOL Full 1.11.8.14 — 2026-11-18

- 0.2.0 Usage 0.1/schema 1 기반. 기존 ID·일별 카운터·과거 관찰 버전·기록 ON/OFF 보존. catalog revision 2.
- 공통 설정 고정 ID 확대. 체크/라벨·드롭다운·슬라이더·숫자/문자 확정·색상 최종 OK에 필요한 진단 연결.
- 위치 편집 시작/저장 종료/실제 변경/취소 사유/확인 불가 분리. 퀘스트 명시적 선택, 파티 요청·초안, 감사 클릭·초안·API 요청, 판매 증거, 수리 요청, 모닥불과 Proc 알림 연결.
- DIRECT/BRIDGE 대표 경로 선택, OFF/초기화 구독 해제와 예약 세대 무효화. 날짜별 routes와 제한된 reasons를 schema 1 선택 필드로 추가.
- UI/JSON에 현재 연결·대표 방식·과거 관찰 경로/버전·인게임 NOT TESTED 표시. 기존 승인 대기 문구 갱신.
- 기록 OFF 마법책 차단 제보 대응: Usage 내용 지연 생성, Blizzard ADDON_LOADED 무시, KHQOL 재연결 다음 회차 처리, Console 화면 갱신 지연/오류 격리/secret 값 제외, Blizzard_DebugTools 자동 로딩 제거. Console에 게임이 보고한 애드온·동작 식별자만 제한적으로 기록. 게임 내 해결 확인은 대기.
- 접속 종료 차단 추가 제보 대응: UsageUI의 StaticPopupDialogs 재대입과 공용 목록 등록을 모두 제거하고 DevTools 전용 초기화 확인창으로 교체. 공용 전역/목록 쓰기 금지 모의 검사 추가.
- UTC 자정 정산으로 lastDate가 과거로 돌아가는 기존 문제 보완. 기존 숫자·날짜별 관찰 의미 유지.
- 기존 Frames·Console·Position·바인딩·사용자 프로필 보존. Commit/Push 및 설치 경로 자동 교체 없음.

## 이전

0.2.0: Usage Analytics 0.1 최초 구현(부분 DIRECT), schema 1.
0.1.5: 독립 Frames·Console·Position 도구. 이전 README는 README-v0.1.5.md로 보존.
