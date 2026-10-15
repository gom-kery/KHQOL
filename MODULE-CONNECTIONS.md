# KHQOL 1.10.9.6 모듈 연결 계약

기준: KHQOL 1.10.9.0-fix 전체 ZIP. 단일 설치 폴더·기존 저장 이름을 유지한다. partyFrames의 실제 등록은 UI/PartyFrameSettings.lua에 있다. 아래 1.10.9.0 연결 계약과 과거 예시는 보존한다.

실제 partyFrames: defaultEnabled=false, 독립 ON/OFF, partyFrames 왼쪽 페이지의 common/frames/roles 세 탭, party/raid 명령·검색·positions 제공자. 탭 이름은 공통/파티·공격대/프로필이며 헤더를 표시한다. settings.subtabs로 동일 모듈에 연결하고 ON/OFF·초기화는 단일 모듈 소유다. SettingsRegistry 페이지와 SettingsUI 그룹 조립에 새 페이지를 연결했다.

표시 설정과 역할 프로필은 KHQOLPartyCharDB.frameProfiles에 저장한다. frameProfile/autoRoleProfile, wheelEnabled/up/down도 캐릭터별이며 KHQOL 전체 프로필 캡처에서 제외한다. 예전 KHQOLDB.modules.partyFrames는 최초 한 번 현재 설정의 마이그레이션 입력으로 복사하고 원본을 보존한다. 전체 프로필의 enabled.partyFrames 정책은 유지한다. resetProfile/resetScope 콜백으로 현재 전용 프로필의 초기화 범위를 안내한다.

런타임은 파티 5/공격대 40 버튼, native 부모 원본, 임시 바인딩 및 값 이벤트를 소유한다. 그룹 헤더를 addon Lua에서 직접 갱신하지 않고 게임 보안 OnShow/OnAttributeChanged로 준비·갱신한다. 유닛의 Enter/Leave/Show/Hide는 native 보안 템플릿에서 상속하며 자체 XML로 덮어쓰지 않는다. OnShow/Hide의 표시 값 작업만 후속 HookScript로 실행한다. 일반 값 갱신과 보호 변경의 마지막 요청 보류를 유지한다.

네 배치는 party/raid10/raid20/raid40이며 런타임 visual.raid만 현재 인원 구간의 복사본이다. native 하위 그룹은 실제 인원을 계속 관리한다. 인원·역할 변경의 보호 재배치는 전투 종료 후 최신 DB/인원에 맞춘다. 독립 미리보기는 비보호 샘플이며 설정창을 열어 둔 채 즉시 저장한다. 통합 편집의 기존 완료/취소 계약과 별도이고 두 편집은 동시 진입하지 않는다.

Range/Settings의 마법책 공유 진입은 사거리 OFF에서도 노출한다. 사거리 검증/저장 로직은 유지하며 휠 탭은 PartyFrameSpellBook을 호출한다. 각 모듈의 사용 ON/OFF를 자동으로 바꾸지 않는다. 실제 보호/입력/복원은 게임 재확인 전이다.

1.10.9.4 확장: PartyFrameLayout은 9개 기준점/그룹 방향/10·20·40인 너비/가로·세로 간격과 공개 하위 그룹 메타데이터에 따른 배치를 소유한다. 그룹 메타데이터는 roster 변경 시 확인하며 값·징표 이벤트에서 다시 열거하지 않는다. PartyFrameDisplay는 공통 시각 요소와 내장 색상 곡선을, PartyFrameAuras는 native AuraContainer의 공개 inbound delegate만 소유한다. 오라 기록·자식 풀·비공개 크기는 읽지 않는다. native 컨테이너 내부 OnUpdate는 게임 구현이며 애드온 OnUpdate/Ticker를 추가하지 않는다.

표시 저장 필드: background(RGBA), powerHeight, healthGradient, namePosition/healthPosition/markerPosition/rolePosition, debuffs(enabled/count/size/perRow/gap/position/x/y). 배치 필드: point/x/y/groupAnchor와 공격대 groupGapX/groupGapY. old groupGap은 마이그레이션 시 두 축의 초기값으로 보존한다. 모든 값은 현재 독립 프레임 프로필에 속한다. 기본 그라데이션·디버프는 OFF다. 일부 API 실패는 featureReasons에 보관하고 주 프레임은 유지한다.

## 파일 로드와 등록

`Bootstrap.lua → ModuleRegistry.lua → ModuleAdapters.lua → 기존 모듈/설정 빌더 → Core.lua → 위치/설정 조립 → SettingsUI.lua` 순서다. 등록은 해당 파일의 최상위에서, `SettingsUI.lua` 및 로그인보다 먼저 완료한다. 새 기능 파일의 TOC 경로 추가는 필요하다. 공통 파일에 기능 ID별 실행 분기를 추가할 필요는 없다.

`KHQOL.ModuleRegistry:Register(id, spec)`의 ID는 번역되지 않는 영문/숫자/밑줄 식별자다. 동일 spec의 재등록은 무시하며, 같은 ID에 다른 spec을 등록하면 오류다. `KHQOL.modules[id]`를 실행 시 조회하므로 기존 파일이 Bootstrap의 빈 테이블을 교체해도 이전 참조를 붙잡지 않는다.

| 등록 필드 | 계약 |
|---|---|
| `requires`, `optional` | 등록된 코드 의존성. 필수 누락·순환은 `Validate`에서 실패. 선택 의존성은 설치된 경우만 초기화한다. 의존 모듈의 사용자 ON/OFF를 자동 변경하지 않는다. |
| `initialize(module, K)` | 성공한 초기화는 한 번. 실패 시 초기화 완료로 기록하지 않는다. 기존 모듈의 자체 초기화 가드는 유지한다. |
| `setEnabled(module, running, K)` | 재적용도 호출되므로 idempotent하게 작성한다. OFF에서 자신이 변경한 속성을 복원한다. |
| `defaultEnabled` | 새 모듈의 누락 사용 키 기본값. 새 기능은 명시해야 한다. 기존 키는 덮어쓰지 않는다. |
| `always` | 내부 서비스 전용. 사용자 master switch가 없는 GeneralConvenience의 예외에 사용한다. |
| `canRun(module, K)` | 추가 실행 조건. 실험실 조건은 기존 `module.experimental`로 판정한다. 유닛프레임은 experimental이 아니다. |
| `profile`, `defaults`, `capture`, `restore` | 현재 DB에 연결하는 프로필 어댑터. 아래 저장 계약 참조. |
| `profileChanged`, `applyProfile` | 이전 작업 정리와 새로운 현재 DB 재조회. 내용 데이터나 프레임 객체를 프로필에 넣지 않는다. |
| `resetProfile(module, profile, defaults, K)` | 기본 초기화와 다른 내용/범위를 가진 모듈의 선택 콜백. 사용 ON/OFF는 기본적으로 유지한다. |
| `settings`, `positions` | 기존 설정 그룹·검색 및 안전한 편집 대상 제공. |

`K:SetEnabled(id, preference, reapply)`가 기존 공개 진입점이다. `reapply=true`는 저장된 사용 선호를 바꾸지 않는다. 실험실 잠금은 실행에만 반영한다. `Registry:IsRunning(id)`는 공통 dispatch가 마지막으로 성공한 실행 상태이며, 실제 프레임이 화면에 보인다는 뜻은 아니다. 레거시가 dispatch 밖에서 자체 상태를 바꾸는 경로도 남아 있으므로 실시간 표시 판정은 각 모듈이 소유한다.

## 저장·프로필

새 모듈의 기본 경로는 `KHQOLDB.modules[id]`다. `profile=true`이면 공통 프로필 목록에 추가된다. `defaults`는 현재 모듈 기본값을 반환한다. 신규 설치용 recipe는 `Profiles.lua`의 기존 별도 정책이며 모듈 기본값을 대체하지 않는다.

`capture`를 생략하면 현재 `K.db.modules[id]`를 독립 복사한다. `restore`를 생략하면 현재 테이블을 재귀적으로 교체하되 테이블 정체성을 유지하고, 이 버전 기본값에 없는 키는 이전 스냅샷에도 남긴다. 미등록 모듈은 실행하지 않는다. 그 데이터는 캡처·복사에서 유지하고, 불완전한 스냅샷을 불러올 때 기존 미등록 데이터의 누락 키만 보충한다.

다른 저장소를 사용할 때는 `capture`와 `restore`를 함께 제공한다. `K.CopyProfileValue`로 공유 참조를 차단하고, `K.ReplaceProfileValue`로 기존 테이블을 유지하거나 교체 후 모든 참조를 다시 얻는다. getter를 통해 항상 현재 DB를 조회하는 방식이 권장된다. callback은 설정 테이블을 반환해야 한다. `variable` 필드는 기존 다섯 레거시 연결용으로 유지했으며, 새 모듈에서 이것만 추가한다고 레거시의 내용 필터까지 자동 생성되는 것은 아니다.

노트 본문·완료 상태·직업별 버프·NPC/발동 목록·캐릭터 판정 주문·추적 선택은 프로필 표시 설정과 별도다. Clock/Todo·BuffReminder·Range·ResourceSwing의 내용 필터와 캐릭터 색상 예외는 Profiles에 남겨 두었다. 기본 모듈 초기화는 알려진 설정을 기본값으로 되돌리며 알 수 없는 키를 보존한다. 기존 폐기 키의 명시적 마이그레이션·정규화는 유지된다.

프로필 변경은 전투 중 또는 편집기 사용 중 거절된다. 허용된 변경/초기화는 먼저 입력·드래그를 정리하고 `profileGeneration`을 증가시킨 뒤 이전 등록 작업을 취소한다. 등록된 `profileChanged`는 이전 작업만 종료하고, `applyProfile`은 새 DB를 조회한다. 실패 시 기존 프로필로 복구하는 경로를 유지한다.

## 설정·검색

`settings={group,id,title,description,commands,build,search,positions,subtabs}`로 기존 그룹에 탭을 추가한다. `group`은 현재 페이지 중 하나, `id`는 그 그룹에서 고유한 탭 ID다. `build(content,y)`는 기존 Builder를 사용하고 최종 y를 반환한다. 새 최상위 페이지는 SettingsRegistry의 pages/groups/orders, SettingsUI의 그룹 조립, 모듈의 NewSettingsGroup 연결을 명시해야 한다. 동일 소유 모듈의 추가 탭은 `subtabs={{id,title,description,build}}`로 등록한다. 추가 탭은 모듈을 중복 등록하지 않으며 route.tab으로 검색·선택·복귀한다. 런타임 hot registration은 지원하지 않는다. 설정창이 생성된 후 등록은 허용하지 않는다.

일반 모듈 목록·사용 토글·초기화·명령어·설정 복귀는 기존 Registry/Presenter를 사용한다. 검색 선등록은 `search={{title,description,aliases,route}}`로 하며 실제 컨트롤은 생성 시 SettingsNavigation에 연결된다. 검색에는 사용자 내용/등록 목록을 넣지 않는다. 기존 그룹 순서는 유지되고 새 탭은 해당 그룹 끝에 추가된다. 실험실 그룹은 기존 잠금과 일반 메뉴 제외 정책을 따른다.

프로필 적용 후 숨은 페이지 전체를 Refresh하지 않는다. 현재 페이지를 갱신하고 다른 캐시의 getter는 다음 진입 시 현재 DB를 읽는다. 탭 이동은 설정 저장 명령이 아니다. 기존 숫자 입력·색 선택·표시 형식·한글 입력 처리를 유지한다.

## 위치 편집

`positions(module, focus, K)`는 대상 목록을 반환한다. 대상은 `id,name,frame,write(dx,dy),apply,lock`과 기존 `parentID,linked,sample,art,settingsRoute,resetPoint,resetWrite`를 사용할 수 있다. `frame`은 KHQOL 소유 실제 프레임 또는 안전한 비보호 미리보기다. 보호/비공개 원본 유닛 버튼은 기본 게임 편집 모드를 사용한다. `linked=true`는 읽기 전용 연결 대상을 뜻한다.

등록 제공자는 켜진 실행 가능 모듈만 호출한다. 반환 대상에 자동으로 소유 ID와 기존 그룹·설정 복귀 메타데이터가 붙는다. 프레임·크기·좌표를 공개 API에서 읽지 못하면 대상/저장을 생략한다. 편집 중 값이 읽히지 않게 되면 전체 완료 저장을 취소하며 0을 저장하지 않는다. `write`는 완료 시에만 DB에 쓰고 드래그 중에는 실제 DB를 바꾸지 않는다. 취소·OFF·전투 진입은 기존 값을 유지한다.

UnitFrames의 제공자는 `Modules/UnitFramePositions.lua:EditorTargets`다. 기존 나머지 기능의 위치 어댑터와 초기화 분기는 PositionTargets/PositionExtras에 남아 있다. 새 모듈은 전역 `ConfigurePositionResets` 분기를 늘리지 말고 자체 `resetPoint/resetWrite`를 반환한다.

## 작업 소유·전투 보류·secret 값

`Registry:Own(id, token, cleanup)`으로 자기 이벤트 프레임·타이머·미리보기·지연 작업만 등록한다. 이미 완료된 작업은 `Release(id, token)`으로 제거한다. OFF/프로필 변경은 등록된 cleanup을 실행하고 취소 세대를 증가시킨다. 취소 불가능한 `C_Timer.After`는 별도 token과 세대 검사로 무효화하거나 모듈 기존 guard를 유지해야 한다. hooksecurefunc/HookScript는 제거 가능한 작업처럼 취급하지 않는다. 기존 훅은 한 번 설치하고 실행 조건을 검사한다.

`Registry:Defer(id, function(module,K) ... end, restore)`는 소유 ID마다 마지막 요청만 보관한다. 콜백은 실행 시 DB를 다시 읽어야 한다. 이전 DB 테이블·사용 값·좌표를 캡처하지 않는다. 전투 종료 이벤트에서 프로필 세대·취소 세대·최신 실행 조건을 확인한다. `restore=true`는 OFF 후 원상복원에만 사용하며, 세대 검사를 생략하지 않는다. 추가 polling은 없다. 큐가 비면 전투 종료 이벤트를 해제한다. 안전하게 복원할 수 없으면 기록을 유지하고 같은 요청을 다음 안전한 이벤트로 다시 보류한다.

BasicUI는 이 큐의 실제 사용자다. UnitFrames/시전/퀘스트/상점/그래픽의 기존 전문 복원 큐를 모두 한꺼번에 교체하지 않았다. 이들은 최신 DB와 기존 세대/실행 조건을 사용하며 별도 회귀 검사 대상이다.

체력·자원 값 갱신은 보호된 위치·Show/Hide와 별도다. `IsPublicNumber`와 PositionStore는 일반 설정/공개 좌표 전용이다. 제한된 체력·자원·RGB/UV packet을 Lua에서 비교·산술·문자열화하지 않는다. 검증된 내장 위젯 전달 경로를 이 함수로 바꾸지 않는다. 새 파티 기능의 보안 템플릿·클릭·실제 secret 실행은 다음 단계에서 별도 조사해야 한다.

## 1.10.9.0 당시 다음 단계 연결 예 (기록 보존)

아래는 1.10.9.0에서 작성한 연결 형태 예시다. 1.10.9.4의 실제 구현은 위 경로를 사용한다.

```lua
local _, K = ...
local M = {defaults={scale=1,position={point="CENTER",x=0,y=0}}}
K.modules.partyFrames=M
local R=K.ModuleRegistry
R:Register("partyFrames",{
  profile=true,defaultEnabled=false,
  defaults=function(m) return m.defaults end,
  initialize=function(m) m:InitializeOwnedFrames() end,
  setEnabled=function(m,on) m:ApplyEnabled(on) end,
  profileChanged=function(m) m:CancelPreviewAndDrafts() end,
  applyProfile=function(m) m:ReadCurrentDB() end,
  positions=function(m,focus) return m:SafePositionTargets(focus) end,
  settings={group="unitFrames",id="party",title="파티",
    commands={"party"},positions=true,
    build=function(content,y) return M:BuildSettings(content,y) end,
    search={{title="파티 배율",aliases="party scale"}}},
})
-- Protected layout request; the module owns restoration records.
-- R:Defer("partyFrames",function(m) m:ApplyLatestProtectedLayout() end)
-- R:Own("partyFrames", m.timer, function(timer) timer:Cancel() end)
```

이 예의 메서드는 다음 단계에서 구현해야 한다. 모의 확장 검사는 같은 등록 필드로 초기화·프로필·검색·편집·OFF·전투 큐를 시험했다. 배포 TOC에는 모의 기능이 없다. 코드/모의 검사 완료와 인게임 보호·저장·렌더링 검증 완료는 별개다.


## 1.10.9.6 설정·색상·편집 화면

common은 BuildCommonSettings, frames는 BuildSettings, roles는 BuildRoleSettings에 연결한다. roles에 클릭/휠 시전과 역할 프로필을 함께 둔다. settings.tabTitle은 단일 소유 모듈 이름과 첫 탭 이름을 구분하며 모듈 등록·실행·저장은 중복하지 않는다. statusLabel/commonStatusLabel/profileNotice에 같은 보류/오류를 표시하고 보이는 본문만 재배치한다. 휠 주문 표시 갱신은 profileContent로 연결한다.

Bootstrap.ClassColors의 공개 상수 9개를 UnitFrameDecor와 PartyFrameDisplay/곡선/미리보기가 공유한다. 저장 설정이나 RAID_CLASS_COLORS/PowerBarColor를 덮어쓰지 않는다. 사용자 지정 색과 NPC 반응색 정책은 유지한다.

위치 편집의 목록 경로 축약은 표시 전용이며 원래 fullPath를 검색·툴팁에 유지한다. 그룹 ID·실제 프레임/좌표·writer·세대 가드는 그대로다. 선택 설명과 보조 완료 버튼만 제거하며 완료/취소/초기화·좌표·방향키 저장 계약은 바꾸지 않는다. 프로필 전송 창의 부모/데이터 스키마는 유지하고 FULLSCREEN_DIALOG/프레임 레벨/앞으로 올리기를 사용한다.
