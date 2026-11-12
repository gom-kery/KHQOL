# KHQOL 1.11.6.1 구현·검증 보고서

기준: 사용자가 제공한 `KHQOL.zip` (1.11.6.0). 작성: 2026-11-08, Asia/Seoul.

**코드 구현·Lua 5.1 모의 검증 완료. 실제 인게임 검증은 미실행입니다.** 설치된 Wow.exe의 파일 버전은 `1.60.1.70862`이며, 조사한 Forever UI 소스의 version.txt와 일치했습니다. 서버 접속·초대 수신·게임 화면·전투 오염을 시험했다는 의미는 아닙니다.

## 결과물·설치

`KHQOL-1.11.6.1.zip`은 원본에 들어 있던 애드온 폴더를 모두 포함하는 전체 설치본입니다. `source/`는 압축 전 동일한 전체 소스입니다. ZIP 최상위에 `KHQOL/`, `KHQOL_Convenience/` 등 애드온 폴더가 직접 위치합니다.

게임을 종료하고 ZIP의 폴더를 `Interface/AddOns`에 병합하세요. 게임 설치 경로에 직접 수정하지 않았습니다. WTF와 SavedVariables는 그대로 유지합니다. Git commit/push는 수행하지 않았습니다.

공통 기반과 Convenience TOC, 공통 런타임 버전은 **1.11.6.1**입니다. 다른 구성 요소의 `1.11.6.0`과 독립 DevTools의 `0.1.5` 표시는 변경하지 않았습니다. 기존 문서의 과거 릴리스·검증 기록도 보존했습니다. 이전 문서의 PASS 수치는 이번 작업의 검증 결과가 아닙니다.

## 기존 코드 분석

| 파일/영역 | 확인한 계약과 확장 방법 |
| --- | --- |
| ChatEnhancement.lua | 입력 커서·히스토리·자동완성, item/quest 툴팁, URL 히트 테스트/복사, 새 창 탐색, 보호 프레임의 전투 후 처리를 유지. URL용 OnMouseDown/Up은 이름 링크를 원래 제외함 |
| ChatFrame.xml / Shared ChatFrame.lua | 기본 이름 클릭은 OnHyperlinkClick→SetItemRef로 진행. 사후 훅으로 초대를 추가하면 기본 귓속말까지 실행될 수 있으므로, 해당 프레임의 클릭 진입점에서 Alt 제스처만 먼저 소비 |
| Forever ChatFrameEditBox.lua | ParseText 다음, GetText/송신 이전의 OnPreSendText가 공식 확장 이벤트를 발생시킴. 전역 SendChatMessage/SetItemRef/전역 믹스인을 교체할 필요 없음 |
| GeneralOptions.lua / Core.lua | general 설정을 프로필에 캡처·복원하는 기존 구조. 네 스위치를 false 기본값으로 추가, 기존 chatEnhancement 값/새 설치 ON 레시피는 유지 |
| GeneralConvenience.lua / Profiles.lua | `globalData.profileCharacters[이름-서버]`에 캐릭터 개인 데이터를 두고 프로필 캡처의 common 목록에서 제외. 동일 구조를 재사용 |
| ConvenienceDetails.lua / DESIGN.md | 공용 Checkbox/EditBox/Button 및 입력 확정·취소 정책을 재사용. 대화창만 한 열로 확장하고 기존 나머지 섹션은 유지. 라벨 줄바꿈과 입력/버튼 높이를 아코디언 계산에 포함 |
| Bootstrap / TOC / Adapters / Installation | chatAutomation을 내부 always 모듈로 연결하고 초기화 한 번·프로필 적용 연결을 명시. 별도 최상위 설정창/마스터 스위치 없음 |

## 사용법

신규 기능은 모두 기본 OFF입니다. `/khqol → 편의 기능 → 일반 → 대화창`에서 각각 켜세요. 기존 기본 대화창 편의 스위치와 독립적입니다.

- Alt+좌클릭: 캐릭터 이름만 초대 대상으로 처리합니다. 같은 파티·자신·초대 권한 없음·2초 이내 반복 클릭은 초대하지 않습니다.
- `/말머리 일반 [초보]`, `/말머리 파티 [힐러]`, `/말머리 길드 길드원`, `/말머리 공격대 [공대]`: 채널별 문구 저장. 대괄호는 필수가 아닙니다.
- `/말머리`: 현재 설정 표시. `/말머리 리셋`: 현재 캐릭터의 네 말머리만 삭제. `/말머리 파티`처럼 내용 없이 입력하면 해당 채널만 비웁니다.
- 인사말은 설정의 입력란에서 직접 저장합니다. Enter/포커스 이동으로 확정, Esc/창 닫기/프로필 전환으로 미확정 편집 취소.
- `/파티요청 이름-서버`: “파티 참여 가능할까요?” 귓속말 **초안**을 엽니다. 직접 Enter로 전송해야 합니다. Alt 초대 기능 ON일 때 사용할 수 있습니다.
- 말머리·인사말 내용은 캐릭터와 서버별로 유지됩니다. 기능 스위치는 프로필별입니다.


## A. 초대 및 참여 요청 구현

- `player:`와 `playerCommunity:` 캐릭터 링크의 정확한 Alt+좌클릭만 소비합니다. Shift/Ctrl이 추가되거나 다른 링크이면 원래 핸들러를 한 번 호출합니다. Battle.net·GM 이름은 제외합니다.
- 이름/서버를 보존하고 로컬 서버 공백을 정규화해 자기 자신·동일 그룹을 검사합니다. 자기/명단 이름을 읽을 수 없으면 초대하지 않습니다.
- CanInvite 공개 결과를 우선 사용하며, API가 없을 때는 솔로/파티장/공격대 부관 여부로 보수적으로 권한을 판단합니다. 만원 그룹을 제외하고 2초 공통 클릭 제한을 둡니다.
- `C_PartyInfo.InviteUnit`을 우선, 없을 때만 `InviteUnit`을 선택합니다. 호출을 시도한 뒤 오류가 났다고 다른 API로 재전송하지 않습니다.
- 현재 target 또는 mouseover의 **전체 이름**이 클릭한 이름과 일치하고, UnitInAnyGroup이 다른 그룹 소속을 확인한 솔로 상태에 한해 `C_PartyInfo.RequestInviteFromUnit`을 시도합니다. 확인되지 않은 채팅 이름에 이 API를 호출하지 않습니다.
- 참여 요청 API가 없으면 귓속말 초안을 엽니다. 초대 이후에는 최근 8초 내 요청 대상과 정확히 일치하는 `ERR_ALREADY_IN_GROUP_S` 서버 문장만 다른 그룹 소속의 근거로 사용합니다. 일반 오류·타인 응답은 추정하지 않습니다.
- 귓속말은 자동 송신하지 않습니다. 비동기 응답이 입력 중인 대화를 덮어쓰지 않도록 수동 명령으로 안내합니다. 다른 애드온이 핸들러를 교체한 경우 강제로 되찾지 않습니다. OFF 복원도 현재 핸들러가 자신의 래퍼일 때만 수행합니다.

**실제 참여 신청 API 호출 경로와 수동 귓속말 초안은 별개입니다.** 전자는 문서에 있는 API를 조건부 호출하도록 구현했으며 서버에서 신청이 수락되는지까지 확인하지 않았습니다.

## B. 말머리 구현

SAY/PARTY/GUILD/RAID의 일반 채팅 입력창 전송 직전에만 문구를 추가합니다. native ParseText가 채널/명령을 해석한 뒤의 이벤트를 사용하므로 입력 중 텍스트·IME·키보드 스크립트는 건드리지 않습니다. 송신 함수는 native 경로가 한 번만 호출하고 native 히스토리는 최종 입력을 기록합니다.

말머리는 Unicode scalar 수 기준 최대 10자입니다. 한글·영문·숫자 혼합, 사용자가 입력한 대괄호를 보존합니다. Lua 5.1 바이트 디코더로 잘못된 UTF-8, overlong, surrogate, 범위 초과를 거부합니다. 조합 문자·복합 이모지는 여러 scalar로 셉니다. `|`/제어 코드 및 `/`로 시작하는 설정 문구는 저장하지 않습니다. 오류 입력은 이전 값을 유지합니다.

이미 현재 말머리 또는 `말머리 + 공백`으로 시작하면 추가하지 않습니다. 최종 문자열은 보수적으로 255바이트 예산으로 구성하며, UTF-8 중간·하이퍼링크·텍스처/아틀라스 토큰을 쪼개지 않고 뒤를 줄입니다. 잘린 색상은 reset으로 닫습니다. 지원하지 않는 제어 구문이나 선두 링크가 예산을 차지해 말머리를 안전하게 넣을 수 없으면 원문과 native 처리를 유지하고 **이번 말머리 생략을 로컬 안내**합니다.

귓속말·일반 CHANNEL·공격대 경보 등 나머지 채널, slash 명령 문자열에는 적용하지 않습니다. 다른 애드온/매크로의 직접 API 송신을 가로채지 않습니다. KHQOL 자동 인사만 같은 PrepareMessage 함수를 명시적으로 사용합니다.

## C. 자동 인사 구현

공개 HOME 그룹 상태·멤버 수·전체 멤버 GUID를 확인하고 솔로→일반 파티/공격대의 상태 전이를 소비합니다. 그룹 참가 GUID 자체가 없어도 이 상태로 동작합니다. 참가 시도를 소비한 다음 송신하므로 이벤트 반복·API 오류·서버 실패로 재전송하지 않습니다. 탈퇴 후에는 GROUP_LEFT와 실제 솔로 관측을 함께 확인해야 다음 참가에 다시 인사합니다.

로그인·reload·지역 이동은 새 그룹 참가로 취급하지 않습니다. 세계 진입 때 즉시/2초 후 기준 상태를 다시 읽고 그 사이에는 인사를 억제합니다. 이 유한 안정화는 초기 복원 억제용이며, 중복 방지는 groupActive 상태가 담당합니다. 불확실 명단의 참가 후보는 10초를 넘기면 인사 없이 소비합니다. 프로필 변경·설정 활성화는 현재 상태를 새 기준으로 잡습니다.

일반 파티는 PARTY, 별도 공격대 스위치까지 켜진 경우 RAID를 사용합니다. instance 그룹 경로가 함께 활성화되어 있으면 채널을 추정하지 않고 건너뜁니다. 빈 문구·미확인 상태·기능 OFF는 보내지 않습니다. 반복 Ticker/OnUpdate, 송신 재시도, 작별 인사 및 작별 옵션은 없습니다.

## Forever API 호환성 근거

조사 커밋: `9dc84f0d3bbae1768ac3405b3716000bd93eda06`. version.txt와 로컬 Wow.exe는 모두 `1.60.1.70862`입니다. **소스/명세 확인과 런타임 검증을 구분합니다.**

| 항목 | 소스/명세 확인 | 런타임 대응 | 인게임 상태 |
| --- | --- | --- | --- |
| C_PartyInfo.InviteUnit / CanInvite | Forever 생성 문서에 있음 | 함수 존재·공개 권한 확인 후 pcall | 미실행 |
| InviteUnit | 구형 전역 별칭의 현 클라이언트 노출은 정적으로 확정하지 않음 | 실제 함수가 있고 신 API가 없을 때만 fallback | 미실행 |
| C_PartyInfo.RequestInviteFromUnit | Forever 생성 문서에 있음 | 이름과 그룹 소속을 확인한 대상에만 호출 | 신청/수락 미실행 |
| ChatFrame.OnEditBoxPreSendText | Forever native EditBox 코드에 있음 | 믹스인 메서드/레지스트리 확인 후 1회 등록; 없으면 UI 비활성 | native 함수+가짜 transport 모의 실행 |
| C_ChatInfo.SendChatMessage | Forever native SendText가 사용 | 자체 인사는 해당 함수 우선, 없으면 전역 송신 함수 선택 | 실제 발신 미실행 |
| GROUP_JOINED / GROUP_LEFT / GROUP_ROSTER_UPDATE | Forever PartyInfo 이벤트 명세에 있음 | 일반 그룹 이벤트는 기능 ON일 때만 등록 | 이벤트 순서 현장 확인 필요 |
| UTF-8 | 새 클라이언트 전용 utf8 API 불필요 | Lua 5.1 decoder 사용 | 한글 IME 현장 확인 필요 |

근거: [버전](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/version.txt), [PartyInfo API·이벤트](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_APIDocumentationGenerated/PartyInfoDocumentation.lua), [EditBox 송신 경로](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_ChatFrameBase/Shared/ChatFrameEditBox.lua), [기본 클릭 경로](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_ChatFrameBase/Shared/ChatFrame.lua), [캐릭터 링크 종류](https://github.com/Gethe/wow-ui-source/blob/9dc84f0d3bbae1768ac3405b3716000bd93eda06/Interface/AddOns/Blizzard_SharedXML/LinkUtil.lua).

## SavedVariables·프로필 호환성

새 SavedVariables 전역 선언이나 기존 데이터 마이그레이션/삭제가 없습니다. 기존 KHQOLDB 안에서 필요한 키만 추가합니다.

```text
KHQOLDB.general
  chatAltInvite / chatPrefixes / chatAutoGreeting / chatRaidGreeting : false
KHQOLDB.globalData.profileCharacters[이름-서버].chatAutomation
  prefixes.SAY / PARTY / GUILD / RAID : 문자열, 기본 빈 값
  greeting : 문자열, 기본 빈 값
```

general은 기존 프로필 캡처/로드에 포함됩니다. globalData는 common 목록에서 제외되므로 새 문구가 프로필로 복제되거나 타 캐릭터 문구로 바뀌지 않습니다. 실제 Profiles.lua의 CaptureProfile/LoadProfileSettings/MakeDefaultProfile를 모의 실행해 참조·문구 보존, 새 스위치 OFF, 새 설치의 기존 chatEnhancement ON을 확인했습니다. 레거시 프로필 데이터 구조는 수정하지 않았습니다.

## 정적·모의 검증

| 검증 | 결과 | 범위 |
| --- | --- | --- |
| 전체 Lua 5.1 loadstring 구문 검사 | 211/211 통과 | 패키지 전체 Lua 파일 |
| 시나리오 | 131/131 통과 | Unicode·slash·채널·초대·명단 전이·데이터·기존 기능·UI 좌표 모의 |
| Forever native 송신 함수 경로 | 5개 시나리오 포함 | 고정 커밋의 SendText/OnPreSendText 실행, transport는 가짜 |
| TOC 참조 | 20개 TOC, 누락 0 | 로드 파일 존재 확인 |
| UI 폭/아코디언 | 220/320/480/600/800 폭 모의 | 실제 Theme 수치 + 가짜 글꼴/프레임 좌표; 실제 스크린샷 아님 |
| 원본·최종 비교 | FILE-INVENTORY.json 참조 | 원본 파일 누락, 변경 파일, SHA-256, ZIP 재추출 바이트 일치 |
| 실제 인게임 | **미실행** | 실제 서버 송신·초대/신청·전투 보호·IME·그림·타 애드온 조합 모두 별도 확인 |

`validation/validation-results.json`은 실행한 시나리오별 결과입니다. `validation/run_validation.py`와 Lua harness도 제공합니다. Python의 lupa Lua 5.1 backend를 사용하며 첫 실행 시 고정 커밋의 검증용 native 소스를 내려받습니다. 검증 도구·외부 라이브러리는 게임 ZIP에 포함하지 않습니다.

## 신규·주요 변경 함수

| 소유 파일 | 함수와 역할 |
| --- | --- |
| ChatEnhancement.lua 신규 | InviteEnabled, TryInvite, InviteClick, ApplyInviteHandler: 기능 게이트·권한/대상·입구 소비·원본 복원 |
| ChatEnhancement.lua 신규 | OpenPartyWhisper, InviteSystemMessage: 수동 초안/정확한 서버 응답 처리; plainName/canonical/unitName 내부 helper |
| ChatEnhancement.lua 변경 | ApplyFrameInput, RegisterFrame 연계, ApplySettings, Initialize: 기존 클릭/입력 경로와 독립 초대 연결, 이벤트/슬래시 1회 등록 |
| ChatAutomation.lua 신규 | ValidateText/nextUTF8, ClipMessage/PrepareMessage/PreSend: 입력 검증·길이/링크 보존·native 전송 직전 적용 |
| ChatAutomation.lua 신규 | GetCharacterData, Get/SetPrefix, Get/SetGreeting, ResetPrefixes, Slash: 캐릭터 저장·명령 처리 |
| ChatAutomation.lua 신규 | ReadGroup, Baseline, ObserveGroup, OnEvent, ApplySettings, RegisterPreSend, Initialize: 보수적 상태 전이·프로필/이벤트 수명 |
| GeneralOptions.lua 변경 | GetDB 기본값, SetConvenienceEnabled 연결 |
| ConvenienceDetails.lua 변경 | BuildSettings: 입력/버튼·상하위 활성 상태·동적 높이·검색 연결 |
| Profiles.lua | 수정 없음. 기존 개인 저장/프로필 캡처 경계를 그대로 사용하고 실제 함수를 테스트 |

## 알려진 제한과 현장 확인 필요 사항

1. 인게임 미실행이므로 보호/taint, 입력 조합, 서버 현지화 응답, 다른 채팅 애드온과의 조합을 확정하지 않습니다. API 명세가 있는 것과 실제 성공은 다릅니다.
2. 채팅 이름만으로 상대 그룹은 알 수 없습니다. 이름이 맞는 target/mouseover 또는 정확한 named 서버 응답 외에는 추정하지 않습니다. 필요하면 `/파티요청 이름-서버`로 직접 초안을 엽니다.
3. 로그인/지역 이동 직후 **2초 동안 실제 새 파티에 들어가도 인사를 생략**합니다. 명단이 10초 넘게 불명확하거나 솔로 복귀가 확인되지 않은 재참가도 생략합니다. 누락 가능성을 택해 잘못된 자동 인사를 줄인 정책입니다.
4. 다른 애드온이나 매크로의 직접 SendChatMessage 호출 전체에 말머리를 강제하지 않습니다. native 입력창과 KHQOL 자동 인사 경로를 지원합니다. 지원되지 않는 선두 제어 구문/예산을 넘는 링크에서는 원문 보존을 위해 말머리를 생략하고 안내합니다. 길이 제한 뒤의 일반 본문은 줄어들 수 있습니다.
5. 다른 애드온이 OnHyperlinkClick을 이후에 완전히 교체하면 해당 창의 초대 기능이 적용되지 않을 수 있습니다. 기존 핸들러를 강제로 재교체하지 않습니다. 보호된 새 창은 전투 종료 후 등록합니다.
6. 실제 그룹 GUID를 사용한 서버 그룹 식별은 하지 않습니다. confirmed solo와 leave/join 상태로 중복을 막고, 불확실한 전이는 보내지 않습니다. instanced chat routing은 제외합니다.
7. 자동 작별 인사는 구현하지 않았고 UI에도 없습니다. 실게임 검증 전 이 결과를 “인게임 전 항목 PASS”로 간주하지 마세요.

## 변경 파일

정확한 목록과 변경 전/후 SHA-256은 `FILE-INVENTORY.json`, 텍스트 diff는 `changes.patch`에 있습니다. 다음 목록은 원본 ZIP과 직접 비교해 생성했습니다.

- `KHQOL/Bootstrap.lua`
- `KHQOL/CHANGELOG.md`
- `KHQOL/CHAT-1.11.6.1.md` (신규)
- `KHQOL/Core.lua`
- `KHQOL/DESIGN.md`
- `KHQOL/INSTALL-GUIDE.md`
- `KHQOL/Installation.lua`
- `KHQOL/KHQOL.toc`
- `KHQOL/README.md`
- `KHQOL_Convenience/Adapters.lua`
- `KHQOL_Convenience/Bootstrap.lua`
- `KHQOL_Convenience/GeneralOptions.lua`
- `KHQOL_Convenience/KHQOL_Convenience.toc`
- `KHQOL_Convenience/Modules/ChatAutomation.lua` (신규)
- `KHQOL_Convenience/Modules/ChatEnhancement.lua`
- `KHQOL_Convenience/UI/ConvenienceDetails.lua`
- `KHQOL_Convenience/UI/SearchIndex.lua`

---

# KHQOL 1.11.6.1 인게임 테스트 체크리스트

상태: **모두 미실행**. 아래 체크는 사용자가 실제 Forever 클라이언트에서 확인한 뒤 표시합니다. 모의 테스트의 PASS를 인게임 PASS로 옮기지 않았습니다.

실행 환경 기록: 클라이언트 빌드 ______ / 캐릭터-서버 ______ / 날짜 ______ / 함께 켠 채팅 애드온 ______.

## 설치·저장·UI

- [ ] 게임을 종료하고 기존 WTF를 백업한 뒤 ZIP의 20개 애드온 폴더를 AddOns에 병합한다. WTF/SavedVariables 파일은 삭제하지 않는다.
- [ ] KHQOL 공통 기반과 Convenience가 1.11.6.1로 표시되고 Lua 오류 없이 로그인한다. 나머지 구성 요소의 기존 버전 표시는 유지된다.
- [ ] 기존 노트·지도·파티 프레임·알람·채집·일반 설정이 유지되고 새 네 스위치는 OFF다.
- [ ] 기존 프로필의 chatEnhancement 값과 새 설치의 기본 대화창 편의 ON이 유지된다.
- [ ] 대화창 섹션의 네 기능 스위치, 네 말머리 입력, 초기화 버튼, 인사 입력, 공격대 스위치가 표시된다.
- [ ] 부모 기능 OFF 시 하위 입력/공격대 스위치가 비활성화된다. ON/OFF로 다른 항목 위치가 어긋나지 않는다.
- [ ] 설정 폭·배율 변경과 섹션 접기/펼치기 시 입력창 잘림·겹침·스크롤 높이 오류가 없다.
- [ ] 한글 IME 조합 중 글자가 지워지거나 커서가 이동하지 않는다. Enter 저장/Esc 취소/포커스 이동 저장이 정상이다.
- [ ] 프로필 A/B를 바꾸면 스위치만 바뀌고 현재 캐릭터의 말머리·인사말은 유지된다.
- [ ] 다른 캐릭터 및 다른 서버의 동명 캐릭터는 독립 문구를 사용한다. /reload·재접속 후 유지된다.
- [ ] 말머리 초기화는 현재 캐릭터의 네 말머리만 비우며 인사말·다른 캐릭터·채집 데이터는 유지된다.

## Alt+좌클릭 초대·참여 요청

- [ ] 일반·길드(커뮤니티 이름 링크 포함)·파티·공격대 채팅의 타인 이름 Alt+좌클릭이 가능한 상태에서 초대를 한 번 시도한다.
- [ ] 자신의 이름(서버 생략/포함), 같은 파티·공격대원의 이름은 초대하지 않는다.
- [ ] 초대 권한 없는 일반 파티원, 가득 찬 파티/공격대에서는 초대를 시도하지 않는다.
- [ ] 2초 이내 반복 클릭 시 초대가 연속 실행되지 않고, 이후 다시 클릭하면 재시도할 수 있다.
- [ ] 다른 서버 이름이 정확하게 전달되고 동명 타 서버 인물을 자신으로 잘못 판단하지 않는다.
- [ ] target/mouseover와 정확히 일치하고 다른 그룹 소속임이 공개 API로 확인되면 실제 참여 신청이 동작하는지 확인한다.
- [ ] 채팅 이름만 있는 상대에게는 그룹 상태를 추측한 참여 신청을 하지 않는다.
- [ ] 정확한 이름을 포함한 “이미 다른 그룹” 서버 응답만 귓속말 초안을 연다. 일반 실패·추정·시간이 지난 오류는 초안도 열지 않는다.
- [ ] 서버 응답이 다르거나 확인 불가하면 `/파티요청 이름-서버`로 초안을 열 수 있다. 자동으로 귓속말이 전송되지 않는다.
- [ ] 응답 도착 시 이미 입력 중인 대화가 있으면 그 초안을 보존하고 수동 명령 안내만 표시한다.
- [ ] 일반 좌클릭의 귓속말, 우클릭 메뉴, Shift/Ctrl 조합의 기본 동작이 한 번만 실행된다.
- [ ] 아이템·퀘스트·주문·URL·Battle.net 이름·GM 이름 링크가 초대 대상으로 처리되지 않는다.
- [ ] 기본 대화창 편의 OFF/Alt 초대 ON, 반대 조합 및 둘 다 OFF가 각각 정상이다.
- [ ] 전투 중 기존 채팅창 및 새 임시창의 클릭이 보호 동작 오류·오염(taint)을 만들지 않는다. 전투 중 미등록 보호 프레임은 종료 후 처리된다.

## 채팅 말머리

- [ ] SAY/PARTY/GUILD/RAID에 서로 다른 문구가 상대 화면에도 실제 한 번만 보인다.
- [ ] WHISPER/BN_WHISPER/OFFICER/CHANNEL/INSTANCE_CHAT/RAID_WARNING 및 애드온 직접 발신에 말머리가 붙지 않는다.
- [ ] /말머리, 네 채널 설정, 전체 리셋, 채널별 빈 값 초기화가 정상이다. 대괄호 없는 입력도 저장된다.
- [ ] 한글 10자·영문 10자·혼합 10자는 저장되며 11자는 오류 안내 후 이전 저장값이 유지된다.
- [ ] 색상·링크 코드·제어 문자는 거부된다. 저장된 잘못된 UTF-8 데이터는 실행에 사용되지 않는다.
- [ ] 빈 말머리와 기능 OFF는 원래 메시지를 유지한다. /run, /reload, /invite, /말머리 등 명령 자체에는 붙지 않는다.
- [ ] /p /g /ra /s로 채널을 선택하고 바로 전송해도 최종 채널에 맞는 말머리가 붙는다.
- [ ] 긴 한글·영문 메시지는 UTF-8을 깨뜨리지 않고 길이를 제한한다. 링크가 잘려 깨지지 않는다.
- [ ] 이미 현재 말머리가 붙은 메시지와 자동 인사에는 중복으로 붙지 않는다.
- [ ] 전송 실패 시 애드온이 다시 보내지 않는다. 같은 입력을 사용자가 직접 재전송할 때만 새 요청이 생긴다.

## 자동 인사

- [ ] 로그인/지역 이동 후 안정화 구간이 지난 솔로 상태에서 파티 구성 또는 참여 시 한 번 인사한다.
- [ ] 솔로→파티→탈퇴(솔로 확인)→새 파티 참여 시 각 새 파티에서 한 번씩 인사한다.
- [ ] 파티원 추가·탈퇴·파티장 변경·연속 GROUP_ROSTER_UPDATE는 추가 인사를 만들지 않는다.
- [ ] 기존 파티에서 /reload·재접속·던전 입장·지역 이동 시 인사하지 않는다.
- [ ] 파티→공격대 전환 시 추가 인사하지 않는다. 솔로→공격대는 별도 스위치 ON일 때 RAID로 한 번 보낸다.
- [ ] 공격대 스위치 OFF, 전체 자동 인사 OFF, 빈 인사말에서는 보내지 않는다.
- [ ] 명단/GUID/채널 상태가 불확실하거나 참가 명단 확인이 10초를 넘기면 보내지 않는다.
- [ ] 파티 말머리/공격대 말머리와 함께 켜도 최종 인사에 말머리가 한 번만 붙는다.
- [ ] 파티 탈퇴·해체·추방 후에는 아무 인사도 보내지 않는다. 자동 작별 설정은 표시되지 않는다.
- [ ] 송신 제한·API 오류가 나더라도 무한 재시도나 다음 명단 이벤트의 중복 전송이 없다.

## 기존 기능 회귀

- [ ] 채팅 커서 좌우 이동, Up/Down 이전 대화, 자동완성 선택, 한글 IME가 기존처럼 동작한다.
- [ ] 아이템/퀘스트 마우스오버 툴팁, 클릭 링크, URL 클릭/복사, Ctrl+C/Enter/Esc 닫기가 정상이다.
- [ ] 채팅창 추가·임시 귓속말 창·창 이동·입력 금지 상태·전투 중 채팅이 기존 동작을 유지한다.
- [ ] 기존 편의 기능과 다른 KHQOL 모듈, 프로필 저장/복원, 단독/선택 설치가 정상이다.
- [ ] 다른 채팅 애드온을 함께 켰을 때 중복 동작·훅 경쟁·추가 송신이 없다.

## API 현장 점검(로컬 출력)

다음은 읽기 전용 로컬 확인용이며 채팅을 보내지 않습니다.

```lua
/run print(GetBuildInfo())
/run print("Invite",type(C_PartyInfo and C_PartyInfo.InviteUnit),"Legacy",type(InviteUnit))
/run print("Request",type(C_PartyInfo and C_PartyInfo.RequestInviteFromUnit))
/run print("PreSend",type(ChatFrameEditBoxMixin and ChatFrameEditBoxMixin.OnPreSendText))
```
