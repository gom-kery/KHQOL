# KHQOL 1.11.9.5 — 전문기술 설정·침낭 휴식·키 입력 개선

기준은 1.11.9.4 Full (436개 파일), SHA256 `b5604c7667d39ea182f8d0e23c33f591c7d06c84d942ae4d48b04ae31569c9f3`이다. 이전 위치 잠금·슬라이더·숙련 안내·사거리·HUD 개선을 포함한다. sources/와 이전 ZIP/기준 소스는 수정하지 않았다. 결과는 KHQOL1.11.9.5 / 선택 DevTools0.3.10 / catalog12 / schema1·protocol1이다.

## 전문기술

| 요청 | 반영 |
| --- | --- |
| 표시 ON/OFF 이동 | 기존 cfg.enabled를 쓰는 `전문기술 사용`을 상단 위치 잠금 위에 표시. 본문 중복 토글 제거. 모듈 always 상태와 표시 사용 상태를 구분 |
| 표시 순서 | 전문기술 버튼(첫 옵션 글자 크기) → 표시 설정 → 전문기술 배치 → 숙련 단계 안내 |
| 표시 설정/배치 방법 | 기존 펼침 방향·크기·간격·배경·숙련도·부캐 설정 유지. 배치 방법은 가로 1줄/2줄, 기본 2줄 |
| 세로형 제거 | 기존 세로형 저장값은 가로 2줄로 정리. 기존 다른 값과 사용자 지정 순서는 유지 |
| 버튼 1~5 | 기본 현재 주 전문기술 1·2, 요리185, 낚시356, 응급치료129. 배운 기술만 실제 아이콘에 표시하며 미습득 슬롯은 기존 비활성 동작 유지 |
| 명칭 | 버튼 순서→전문기술 배치, 전문기술 순서 N→버튼 N, 다음 숙련 단계 안내→숙련 단계 안내. 검색/통계 연결도 갱신 |

글자 색상·텍스트 효과·위치 초기화 및 기존 좌표/잠금 콜백은 유지한다. 기존 가로형 2줄의 첫 줄 주 전문기술/둘째 줄 보조 전문기술 배치를 유지한다. 1줄은 현재 순서대로 같은 줄에 배치한다. 사용자 지정 순서가 있으면 초기화하지 않는다.

## 침낭 설치와 타이머

- 기존 SecureActionButtonTemplate 아이템 클릭의 unit을 player로 지정했다. 잠긴 비전투 직접 클릭만 사용하며 좌표 클릭·TargetUnit·자동 반복 사용·전투 중 보호 속성 변경을 추가하지 않았다. 게임에서 실제 현재 위치에 설치되는지는 NOT TESTED이다. 보호 아이템 경로의 근거는 [Blizzard SecureTemplates](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua)이다.
- 휴식 중1331671이 실제 ACTIVE일 때 표시한다. 자신의 침낭 소유 여부를 타이머 조건으로 사용하지 않아 다른 사람의 침낭에서 얻은 같은 버프도 관찰 가능하다. 아이템 아이콘 자체의 기존 소유 조건은 유지한다.
- 서로 다른 색의 1분 구간 3개와 `n/3중첩 · 다음 중첩까지 ...`를 표시한다. 충분한 휴식429959의 공개 applications를 실제 중첩으로 사용한다. 미적용이 확인됐을 때만0, 읽을 수 없으면?로 구분한다.
- 분당 종료 시각을 공개 API가 제공하면 우선 사용한다. 무기한 휴식 오라라 분당 시각을 읽을 수 없으면 관찰한 진입/실제 중첩 변경 시각부터60초를 추정하고 `약`을 붙인다. 시간이 지났다고 중첩을 만들어 내지 않으며 서버 중첩 갱신을 기다린다.
- 중단 시 현재 분의 추정을 버린다. 재진입하면 실제 중첩 완료 칸은 유지하고 현재 분만 다시 시작한다. 이동 중에는 중단 상태로 표시한다. 이동이 멈췄다는 이유만으로 오래된 오라에 새 시간을 붙이지 않는다.
- 최초 접속/리로드에 이미 무기한 오라가 있으면 시작 시점을 알 수 없으므로 확인 중으로 표시하고 다음 실제 중첩 갱신에서 맞춘다. 임의의 경과 시간을 저장/복원하지 않는다.3중첩은 실제 확인 후 완료, 오라 소실/모듈OFF는 숨김이다.
- 바는 알림 아이콘 묶음 아래에 표시한다. 기존 FBR 단일 예약 갱신을 재사용해 진행 중에만1초 단위로 표시를 갱신하며 새로운 OnUpdate/반복 갱신기를 추가하지 않았다. 확인 불가/서버 대기 상태에서는 시간 전용 갱신을 멈춘다.

## 직접 입력한 /대상 오류

사용자는 이전 입력 호출 없이 처음부터 직접 입력했다고 확인했다. 전문기술 펼친 창에는 모든 키마다 SetPropagateKeyboardInput을 쓰는 OnKeyDown이 있었다. 이를 제거하고 이미 등록된 UISpecialFrames의 기본 ESC 닫기를 사용한다. 전역 위치 편집기도 일반 키에는 키 전달을 다시 쓰지 않는다. 기존 채팅 해석기·TargetUnit·명령 목록을 교체하거나 대상 지정 호출을 대신 수행하지 않는다.

[Blizzard ChatFrameEditBox](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_ChatFrameBase/Shared/ChatFrameEditBox.lua)에서는 보호 명령을 ParseText에서 처리한 다음 말머리용 OnPreSendText를 호출한다. 따라서 이번 코드 검토만으로 말머리 콜백을 직접 원인으로 단정하지 않았다. 제거한 키 전달 코드가 영향을 줄 수 있는 경로임은 확인했지만, WoW의 실제 오염 전파와 해당 TargetUnit 오류 해소는 NOT TESTED이다.

## Usage Analytics·호환성

상단 사용 토글은 기존 setting.professions.control009를 사용한다. 배치 방법은 기존 control013, 숙련 단계 안내는 기존 guide.enabled다. 이름이 바뀐 설정에 별칭을 추가하고 이전 정의/ID를 변경하지 않는다. 사용 토글은 설정 변경으로 한 번 집계하며 Position Editor 시작이 아니다. 타이머 조회/갱신·실제 중첩/시간은 새 통계로 수집하지 않는다. Core 런타임 버전도 TOC의1.11.9.5로 맞췄다.

## 검증

정적·모의33개 검사 묶음 PASS. 새 기능 검사83개 PASS(침낭42, UI/키/계측41). 기존 회귀712개 포함. 가로형 전환과 기본 ESC 동작이 의도적으로 변경되어 해당 이전 기대값을 갱신했으며, 상단 제어 폭과 최신 버전 기대값도 갱신했다. 이 변경은 tests/에 포함한다.

| 검사 | 결과 |
| --- | --- |
| 사용 토글·잠금 | 상단 노출, 두 체크박스 X 정렬, 기존 enabled 쓰기·복원, 본문 중복 제거 |
| 설정 순서·배치 | 실제 아코디언 순서, 새 명칭, 기본 5개 순서, 실제 1/2개 행, 이전 세로형 전환 |
| 키 입력 | 전문기술 창 OnKeyDown 없음/키보드 미등록, 기본 ESC 목록 등록, 위치 편집기의 Enter 전달 쓰기0회 |
| 침낭 사용 | 보호 아이템211527·unit player, 직접 클릭 속성, 전투 중 가림 |
| 중단/재시작 | 부분 진행 제거, 실제 중첩 완료 칸 유지, 이동/정지 시 오래된 오라로 재시작 안 함 |
| 중첩/시간 |60초만 지나면 실제 중첩 증가 없음,1→2→3 실제 오라 갱신, 공개 종료 시각 우선, 추정 표시, 미확인 값 구분 |
| 최초 관찰·OFF | 진행 시점 미확인 상태, 모듈OFF 숨김/이벤트 해제 |
| DevTools | OFF/ON 기능, 기존 ID, 사용 변경1회/편집 시작0회, 이전 로그/프로필 이전 |

환경은 Python+lupa Lua5.1 가상 API다. audit/integration-tests.json·changes94-results.json 및 기존 결과에 기록한다. 실제 게임의 렌더링·보호 실행·오염 엔진·서버 중첩 주기는 검증하지 못했다.

## 인게임 확인 — NOT TESTED

1. 상단 전문기술 사용/잠금과 설정 순서, 가로1/2줄·버튼 순서·길어진 이름/창 폭 확인.
2. 침낭 직접 클릭의 현재 위치 설치와 전투 중 차단.
3. 휴식 중 버프 획득·중단·재진입·이동·1/2/3중첩, 실제 서버 갱신과 타이머 색/문구 확인.
4. 처음 접속/리로드에 이미 쉬는 경우 확인 중 표시 및 다음 중첩 동기화.
5. 새 세션에서 전문기술 목록을 펼친 상태/닫은 상태로 `/대상 농부 레이` 직접 입력 및 전투 전후 보호 키 동작 확인.

## 주요 수정 파일

Core Profiles/Bootstrap, SettingsUI, SettingsRegistry, PositionLocks, PositionEditor, AuraReader, UsageDiagnostics/UsageControlIDs; Convenience Adapters/Professions/ProfessionSettings/ProfessionGuideUI/SearchIndex; BuffReminder SleepingBag(신규)/Core/CommonBuffs/UI; DevTools UsageBridge/UsageObserve/UsageCatalog/UsageControlIDs/버전; Map 내부 버전. 상세 목록은 CHANGED-FILES.json이다.

설치는 Full ZIP만 사용하고 Review는 검증/소스 검토용이다. 게임 종료 후19개 동일 이름 폴더를 교체하고 WTF/SavedVariables는 보존한다. 설치본에는 가상 데이터·테스트 도구·개인 저장값을 포함하지 않는다.
