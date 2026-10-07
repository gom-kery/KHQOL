# KHQOL 1.9.4 — 위협 수준 알림 개선 보고서

기준본: 사용자가 첨부한 `KHQOL-1.9.3.zip`. 작성일: 2026-10-07.

## 결과 및 적용 범위

아이콘 크기·위치·표시 단계 설정을 Threat 모듈 한 파일 안에 구현했다.
첨부 설명의 NamePlate 예시는 아이콘/수치의 상대 배치 요구로 적용했다.
실제 1.9.3은 `KHQOLThreatHUD`를 `UIParent`에 만드는 **현재 선택한 적 한 마리의 화면 독립 표시창**이다.
이 기존 구조를 유지했으며 이름표 연결이나 다수 적 표시로 바꾸지 않았다.

기존 수치/퍼센트 포맷, Threat 데이터 읽기, 상태 색상, 파티/공격대·솔로 Hunter/Warlock + 살아 있는 펫 조건,
전투 중 표시, 대상 필터 및 갱신 주기는 그대로다.
1.9.3의 다른 모듈·설정 UI 공통 코드·DESIGN.md·모든 미디어와 바인딩 파일을 보존했다.

## 1. 수정한 파일

| 파일 | 변경 |
|---|---|
| `Modules/Threat.lua` | 아이콘 설정·크기 분리·앞/위 배치·단계 표시 선택·테스트/진단 확장 |
| `Bootstrap.lua` | 버전 1.9.4 |
| `KHQOL.toc` | 버전 1.9.4; 로드 순서와 SavedVariables 선언 유지 |
| `README.md` | 설치와 새 기능 안내 추가; 이전 기록 유지 |
| `CHANGELOG.md` | 1.9.4 변경 내역 추가; 이전 기록 유지 |
| `THREAT.md` | 현재 수정 보고서와 인게임 체크리스트 |

새 리소스나 구현 파일은 추가하지 않는다. `Core.lua`, `UI.lua`, `SettingsUI.lua`와 다른 기능 모듈은 변경하지 않았다.

## 2. 기존 크기 연동 제거 및 새로운 크기 설정

기존 `icon:SetSize(fontSize,fontSize)`를 `icon:SetSize(iconSize,iconSize)`로 바꿨다.
`iconSize`의 범위는 12~32, 설정 간격은 1이다. 새 프로필 기본값은 18이다.
글씨 크기 10~24는 기존 설정을 사용한다. 글씨 크기를 바꿔도 저장된 아이콘 크기는 변하지 않고,
아이콘 크기를 바꿔도 글씨 크기는 변하지 않는다.

크기 및 위치 갱신은 기존 설정 변경/레이아웃 적용 과정에서 수행한다.
수치 포맷 변경이나 위험 단계 전환을 위해 프레임·FontString·Texture를 새로 생성하지 않는다.

## 3. 아이콘 위치와 Anchor

| 저장값 | 설정 표시 | Anchor |
|---|---|---|
| `LEFT` | 수치 앞 | 아이콘 RIGHT → 수치 LEFT, 음수 X 간격 |
| `TOP` | 수치 위 | 아이콘 BOTTOM → 수치 TOP, 양수 Y 간격 |

기본 위치는 LEFT다. 간격은 아이콘 크기의 약 20%를 정수로 반올림하며 최소 2 UI 단위다.
아이콘의 가장자리를 수치의 반대쪽 가장자리에 붙이므로 크기가 커져도 둘이 겹치지 않는다.
수치 글자 길이가 바뀌면 기존 FontString 가장자리를 따라간다.

TOP 배치에서는 대상명을 아이콘 위에 6 UI 단위 간격으로 놓고 상단 공간에 맞춰 컨테이너 높이를 확보한다.
수치 CENTER와 저장된 화면 좌표를 유지하며 하단 문구와 가상 데이터 안내는 기존 중심 기준 위치를 유지한다.
아이콘이 여유 단계에서 숨겨져도 상단 공간을 유지하여 위험 단계 진입 때 이름과 숫자가 뛰지 않게 한다.
아이콘 OFF 또는 LEFT 배치에서는 기존 280x88 레이아웃을 사용한다.

현재 모듈은 NamePlate의 자식이 아니므로 NamePlate Anchor 변경은 **해당 없음**이다.
Platynator나 Blizzard 체력바에는 변경을 가하지 않는다. 이름표가 여러 개 있어도 현재 대상 하나만 표시한다.

## 4. Threat 단계별 표시 조건

1.9.3의 `Risk`와 `Color`, `GetThreatInfo`를 그대로 유지했다. 새 설정은 기존 아이콘 경로 선택에 표시 조건을 더한다.
첨부 설명의 예상 API Status 0/1/2/3을 그대로 새 의미에 재배정하지 않는다.
1.9.3은 `isTanking=true` 또는 API 상태 2/3을 이미 어그로 보유로 판정하므로 이 우선순위를 유지한다.

| 기존 모듈의 표시 단계 | 기본 설정 | 주의 표시 ON | 사용 아이콘 |
|---|---|---|---|
| 여유: scaled 70% 미만 | 숨김 | 숨김 | 없음 |
| 주의: scaled 70% 이상, 90% 미만 | 숨김 | 표시 | 기존 노랑 |
| 위험: scaled 90% 이상, 보유 확인 전 | 표시 | 표시 | 기존 주황 |
| 어그로 보유: isTanking=true 또는 API 상태 2/3 | 표시 | 표시 | 기존 빨강 |

아이콘 사용 OFF이면 모든 단계에서 숨기며 수치와 기존 색상은 계속 갱신한다.
100% 도달만으로 보유를 새로 추측하지 않으며 기존대로 보유 확인 전에는 주황 아이콘을 사용한다.
scaled 비율이 없으면 기존 `Risk`의 확인 가능한 API 상태 처리를 유지한다. API 상태 1의 주의 아이콘도 옵션 ON일 때만 표시한다.
rawPercentage를 scaled로 바꾸거나 새로운 어그로 계산·거리 추정을 도입하지 않았다.
유효한 숫자가 없거나 데이터가 제한돼 기존 수치가 숨겨질 때 아이콘도 숨긴다.

[Forever 클라이언트 추출 Unit API 문서](https://github.com/Atraeau/WoW-Addons/blob/main/docs/api/Units-Combat-PvP/Unit.md)의 상세 API 반환값 순서와
[Forever를 지원하는 ThreatClassic2 개발자 구현](https://github.com/dfherr/ThreatClassic2/blob/master/core/core.lua)을 참고했다.
이 참고 확인은 실제 Forever 실행 검증을 대신하지 않는다. 기존 API Wrapper와 숫자/비율 해석을 이번 변경에서 재작성하지 않았다.

## 5. 설정 UI 및 SavedVariables

위치 섹션을 기존처럼 최상단에 유지하고 어그로 표시 다음에 **위협 수준 알림** 섹션을 추가했다.
DESIGN.md와 현행 공통 Builder/Checkbox/Slider/Dropdown의 행·여백·Disable 규칙을 사용한다.
위치는 공통 2개 선택 드롭다운 하나로 제공한다. 새 색상 설정이나 별도 설정창은 없다.
아이콘 OFF이면 크기·위치·주의 단계 컨트롤은 비활성화하지만 저장값은 유지한다.
모듈 OFF 때의 공통 하위 설정 비활성화도 유지한다.

```lua
KHQOLDB.modules.threat.iconEnabled = true
KHQOLDB.modules.threat.iconSize = 18
KHQOLDB.modules.threat.iconPosition = "LEFT" -- LEFT / TOP
KHQOLDB.modules.threat.showCautionIcon = false
```

이 네 항목을 기존 `KHQOLDB.modules.threat` 안에 추가한다.
표시 방식·글씨 크기·화면 위치·잠금·대상명/하단 안내·색상·솔로 펫·모듈 사용 및 다른 모듈 데이터는 유지한다.

## 6. Migration

- 새 프로필: iconEnabled=true, iconSize=18, iconPosition=LEFT, showCautionIcon=false.
- 기존 프로필에서 iconSize가 없고 유효한 fontSize가 있으면 그 크기를 12~32 범위로 제한해 한 번 저장한다. 예: 15 → 15, 24 → 24, 10 → 12.
- 기존에 명시된 iconSize/iconEnabled/iconPosition/showCautionIcon이 있으면 재사용한다.
- 누락된 기본값만 병합하며 잘못된 타입·무한대·NaN·범위 밖 값은 안전한 값으로 보정한다. 잘못된 위치는 LEFT로 복원한다.
- 이후 fontSize를 변경해도 이미 저장된 iconSize는 다시 복사하지 않는다. 별도의 반복 Migration이나 저장 파일 초기화는 없다.

1.9.3에 이미 있는 퍼센트 표시 Migration은 변경하지 않았다. 이번 새 아이콘 설정 때문에 기존 1.9.3의 표시 방식을 재설정하지 않는다.

## 7. 프레임 재사용 및 성능

기존 한 개의 HUD, 수치 FontString, 아이콘 Texture와 0.20초 단일 Ticker를 사용한다.
아이콘 전용 Ticker/OnUpdate, 깜빡임·애니메이션, 사운드, 전체 Unit/NamePlate 검색은 추가하지 않았다.
상태별 표시/숨김은 기존 `ShowInfo` 안에서 처리한다. 같은 이미지 경로일 때 SetTexture를 다시 호출하지 않는다.
매 Tick마다 Anchor나 크기를 다시 설정하지 않는다. 설정 변경 때만 레이아웃을 다시 적용한다.

모의 검사에서 100회 위험↔여유 전환 중 Anchor 호출이 0이고,
반복 설정 변경 및 갱신에서도 프레임·폰트·타이머가 증가하지 않음을 확인했다.
실제 CPU/FPS는 측정하지 않았다.

## 8. 테스트 및 진단

| 명령 | 동작 |
|---|---|
| `/khqol threat` | 설정 |
| `/khqol threat test` | 기존 가상 테스트 ON/OFF |
| `/khqol threat test 0` | 여유 35% |
| `/khqol threat test 1` | 주의 78% |
| `/khqol threat test 2` | 위험 95% |
| `/khqol threat test 3` | 어그로 보유 100% |
| `/khqol threat status` | 현재 조건·버전·아이콘 설정·위치·숨김 사유 |
| `/khqol threat debug` | 현재 대상 API 진단 ON/OFF |

`/kh` 별칭과 unlock/lock/reset 명령도 유지한다.
잘못된 테스트 단계는 현재 테스트를 변경하지 않고 사용 안내를 출력한다.
테스트는 선택한 크기·위치·사용/주의 표시 설정을 따른다. 따라서 주의 OFF이면 주의 테스트의 숫자는 보이지만 아이콘은 없다.
테스트 중 실제 Threat 조회와 반복 타이머를 중단하며 설정창 닫기·전투 시작/종료 등 기존 테스트 종료 규칙은 유지한다.
이름을 숨긴 테스트에서는 별도의 가상 데이터 안내를 유지한다.

## 9. 정적·모의 검증 결과

**정적·모의 검증: PASS — 251개 검사. 전체 55개 Lua 파일 Lua 5.1 문법/TOC: PASS. 인게임 검증: NEEDS TEST.**

검사 내용:

- 첨부 1.9.3과 파일 비교: 다른 모듈·기존 미디어·DESIGN·공통 설정 코드·바인딩 보존.
- 수치/퍼센트 포맷, API 접근 제한/예외/nil/0, 대상 변경·해제·중립 적, 그룹/펫 활성 조건, 타이머 중단 회귀 검사.
- 아이콘 ON/OFF × 주의 ON/OFF × 네 단계의 실제 데이터 표시 조합.
- 새 기본값, 기존 크기 일회 이전, 저장된 명시값·기존 옵션 보존, 잘못된 값 보정.
- LEFT/TOP × 아이콘 크기 12/18/32 × 글씨 크기 10/15/24의 독립 크기·Anchor·상단 공간.
- 숫자 중앙/하단 위치 유지, 단계 전환 중 Anchor 재설정 없음, 프레임·폰트·Ticker 재사용.
- 설정 콜백의 즉시 적용과 아이콘 OFF 때 종속 컨트롤 사용 조건, 번호별 테스트 명령, DB 재사용 시 복원.

검사 환경은 Lua 5.1 + 모의 WoW API다. 실제 게임 화면·드래그 감각·UI 배율·SavedVariables 파일 저장/재접속·API의 실시간 정확도는 실행하지 않았다.
`KHQOL-1.9.4-validation.json`과 ZIP 무결성/파일 비교 manifest를 별도로 제공한다.

## 10. 인게임 테스트 체크리스트

모든 실행 항목의 현재 상태는 **NEEDS TEST**다.

- [ ] 기존 1.9.3 폴더에 덮어쓰고 `/reload`; 위치·글씨·표시 방식·다른 모듈 설정 유지 확인.
- [ ] 아이콘 OFF → test 0/1/2/3 모두 수치는 보이고 아이콘은 숨김.
- [ ] 아이콘 ON·주의 OFF → 여유/주의 숨김, 위험/보유 아이콘 표시.
- [ ] 주의 ON → 주의 단계부터 노랑 아이콘 표시.
- [ ] LEFT → 수치 왼쪽에 여백을 두고 표시.
- [ ] TOP → 수치 위에 표시하며 수치·대상명과 겹치지 않음.
- [ ] 글씨 크기 10/24 변경 → 아이콘 크기 유지.
- [ ] 아이콘 크기 12/32 변경 → 글씨 크기 유지, LEFT/TOP 모두 겹침 없음.
- [ ] 실제 전투에서 여유↔위험 전환 → 숫자 위치는 유지되고 아이콘만 즉시 표시/숨김.
- [ ] 여러 이름표가 보여도 현재 대상만 표시되고 대상 변경 시 즉시 갱신.
- [ ] 설정 변경이 실제 HUD와 가상 테스트에 즉시 반영.
- [ ] `/reload`·재접속 후 아이콘 사용/크기/위치/주의 설정 유지.
- [ ] 전투 종료·대상 해제·펫 사망·그룹 탈퇴·모듈 OFF 시 이전 아이콘이 남지 않음.
- [ ] Platynator와 함께 사용하며 실제 UI 배율/화면 경계에서 배치·겹침 확인.
- [ ] 1.9.3 Quest Navigator의 추적 후보/완료 동작, ForeverNote 단축키·미니맵, PvP Alert 등 기존 기능 확인.
