# KHQOL 1.11.7.3 변경·검증 보고서

2026-11-13 · Forever 검증용 빌드 · 기준 1.11.7.2 Base 및 UnitFrames ZIP

## 기능과 기본값

| 위치 | 동작 및 기본값 |
| --- | --- |
| 인터페이스 → 시계·정보 표시 → 길드 접속 | 표시 OFF, 타이틀 ON, 배경 OFF. 축약 기준 15명, 정수 1~1,000. 시계 기준 오프셋 X 170 / Y 35에서 시작하고 시계 잠금과 통합 위치 편집을 사용합니다. 공통 사이드 글꼴을 상속하며 길드 개별 크기·색·효과를 선택할 수 있습니다. |
| 소지금 HUD | 기존 금·은·동 선택과 위치를 사용합니다. 마우스를 올렸을 때 현재 캐릭터를 제외하고 서버·진영이 일치하는 캐릭터의 이름과 금·은·동을 표시합니다. 직업색은 확인할 수 있을 때 적용합니다. |
| 편의 기능 → 일반 편의 → 공통 | 아이템, 자동 거절, 채집의 기존 저장 키와 이벤트를 사용합니다. 하단 초기화는 이 탭의 옵션을 복원합니다. |
| 편의 기능 → 일반 편의 → 말머리·자동 인사 | 대화창 편의, Alt+좌클릭 초대, 말머리, 파티·공격대 인사를 설정합니다. 하단 초기화는 사용 옵션을 복원하고 캐릭터별 문구를 보존합니다. |
| 편의 기능 → 일반 편의 → 전문기술 | 새 프로필 표시 OFF, 잠금 ON, X 160 / Y 0, 버튼 글자 14px 흰색 외곽선. 가로 배열, 오른쪽 펼침, 아이콘 36px, 숙련도 ON·12px·아이콘 안쪽 아래, 목록 배경 불투명도 92%. 게임의 학습 순서가 초기값이며 기술 ID로 순서를 저장합니다. |
| 선택 설치 유닛프레임 → 대상 → 간결한 모양 | 실제 체력 끝에서 시작하는 녹색 예상 치유 구간. 최대 체력까지만 채웁니다. 기본 모양과 모듈 OFF에서는 기본 예측 표시를 사용합니다. |

전문기술의 펼침 방향에 공간이 부족하면 반대 방향의 공간을 확인해 안쪽으로 펼칩니다. 목록에 화면 경계 제한도 적용합니다. 창 우선순위는 기존 전역 설정을 따릅니다. 전투 밖에서는 목록이 ESC를 처리하고 일반 키 입력을 전달합니다. 전투에서는 Blizzard의 특수 창 닫기 경로를 사용합니다. 그 상황에서 다른 기본 창이 함께 닫히는지는 인게임 검증 항목입니다. [Forever 기본 창 닫기](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UIParentPanelManager/Shared/UIParentPanelManager.lua#L1032-L1110)

## 데이터와 Forever 경로

- 길드는 IsInGuild와 C_Club.GetGuildClubId로 식별합니다. 표시를 켜거나 길드 ID가 바뀌면 FocusMembers와 C_GuildInfo.GuildRoster를 요청합니다. 준비 완료와 명단·상태 변경 이벤트에서만 명단을 읽고 툴팁은 보관된 명단을 사용합니다. 기본 명단과 같이 Online, Away, Busy를 포함합니다. 회원 GUID 또는 회원 ID로 중복을 제거하고 본인 행은 한 번만 포함합니다. 길드 미가입·명단 미준비 시 숨깁니다. 좌클릭은 기본 길드 버튼과 같은 ToggleGuildFrame을 우선 사용하고 현재 길드의 명단 보기를 선택합니다. 자동 거절 모듈의 길드원 예외 코드는 그대로입니다. [Forever 길드 명단 및 집계](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_Communities/CommunitiesMemberList.lua#L315-L377) · [회원 준비·명단 요청](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_Communities/CommunitiesMemberList.lua#L440-L472) · [기본 길드 버튼](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_MicroMenu/Mainline/MainMenuBarMicroButtons.lua#L1217-L1224)
- 소지금은 접속, 소지금 변경, 진영 변경 시 GetMoney 값을 KHQOLDB.globalData.characterMoney에 기록합니다. UnitGUID로 캐릭터를 구분하고 GetRealmName과 UnitFactionGroup의 서버·진영이 모두 일치해야 툴팁에 포함합니다. 미기록과 0코퍼를 구분합니다. 공용 기록은 전체 설정 초기화와 프로필 전환에도 유지되고 프로필 문자열에서 제외됩니다. [Forever 캐릭터 이름 처리](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_FrameXMLUtil/Camelot/NameUtil.lua#L12-L19)
- 전문기술은 기존 프로필의 legacy.clock 또는 당시의 ForeverClockDB에서 읽어 settings.modules.professions로 옮깁니다. 새 경로의 저장값을 우선하고 값이 없는 프로필에서만 이관합니다. 예전 시계 및 전문기술 표시 상태를 함께 평가하고, 잠금·배치·아이콘·숙련도와 개별/공통 글자 크기·색·효과를 계승합니다. 기존 프로필의 숙련도 기본 위치는 예전 배치에 가까운 아이콘 바깥쪽 아래로 이관합니다. 편의 묶음이 빠져 있으면 기존 기록을 보존합니다.
- 이관 좌표는 이전 시계 앵커의 화면 기준점을 유지합니다. 새 버튼의 중심 좌표는 이전 시계 앵커 오프셋에 버튼 상대 오프셋을 더한 후, 이전 시계 프레임의 앵커에서 중심까지의 거리만큼 보정합니다. 예전 프레임 높이는 190px이며, 좌우 앵커에는 이전 공식과 현재 클라이언트의 글자 폭·소지금 형식으로 재구성한 시계 폭을 사용합니다. 해당 폭은 이전 저장 시점의 시각과 금액에 따라 달라졌으므로 예전 화면의 픽셀 위치와 차이가 날 수 있습니다. 앵커나 폭을 확인할 수 없으면 화면 중앙 기준 X 160 / Y 0을 사용하고 원본 좌표를 보존합니다. 시계 설정 초기화도 기존 이관 근거를 보존합니다.
- 기본 대상 프레임은 UnitFrame_Initialize로 두 예측 세그먼트를 연결합니다. UnitFrameHealPredictionBars_Update는 예측·체력 이벤트에서 게임 값을 읽어 치유 흡수량과 함께 각 세그먼트를 배치하며 결합 회복량을 반환하지 않습니다. 세그먼트 배치 결과의 폭은 기본 바와 흡수 오프셋을 반영합니다. KHQOL은 이 갱신 함수에 후크를 추가하고 UNIT_HEAL_PREDICTION도 처리합니다. 게임의 현재 체력바 값과 UnitGetIncomingHeals의 공개 합계를 읽어 표시 전용 StatusBar에 반영합니다. 기본 치유 세그먼트 두 개의 표시 투명도만 일시 적용하고 흡수·보호막·오라·대상 시전바에는 치유 기능이 쓰기 작업을 하지 않습니다. [Forever 대상 프레임 연결](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UnitFrame/Mainline/TargetFrame.lua#L44-L61) · [치유 예측 갱신](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UnitFrame/Mainline/UnitFrame.lua#L185-L329) · [세그먼트 배치](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UnitFrame/Shared/StatusBarOverlaySegment.lua#L51-L84)
- 클라이언트는 UnitGetIncomingHeals의 반환값을 제한할 수 있습니다. 제한된 예측량이나 체력값에 계산·비교·문자열 변환을 하지 않습니다. 새 치유 구간은 0으로 지우고 기존 체력바의 위젯 값 전달 경로는 유지합니다. 대상 변경·해제, 사망, 최대 체력, 예측 해제에서 다시 평가합니다. 구조 변경은 기존 전투 보류 경로를 거치며 전투 종료 후 현재 대상과 설정으로 적용합니다. [Forever API 반환값](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua#L1182-L1207)

## 수정 파일

| 위치 | 파일 |
| --- | --- |
| KHQOL 공통 | MoneyRecords.lua, UI/HUDText.lua, Profiles.lua, ProfileTransfer.lua, SettingsUI.lua, Core.lua, Installation.lua, UI/SettingsGroups.lua, UI/SettingsRegistry.lua, UI/SettingsPresenter.lua, UI/SettingsNavigation.lua |
| KHQOL_Clock | Clock/Core.lua, Clock/Clock.lua, Clock/Modules.lua, Clock/Guild.lua, Clock/Settings.lua, Adapters.lua, Positions.lua, UI/SearchIndex.lua. 기존 Clock/Professions.lua 제거 |
| KHQOL_Convenience | Bootstrap.lua, Adapters.lua, ProfessionProfile.lua, Modules/Professions.lua, UI/ProfessionSettings.lua, UI/ConvenienceTab.lua, UI/ConvenienceDetails.lua, UI/SearchIndex.lua |
| KHQOL_UnitFrames | Modules/UnitFrameDisplay.lua, Modules/UnitFrameDecor.lua, Modules/UnitFrames.lua |
| 버전·문서 | 두 ZIP의 19개 TOC, KHQOL/Bootstrap.lua, KHQOL_Campfire/Campfire/Core.lua, KHQOL_Map/Core.lua, KHQOL_Labs/Modules/ObjectHighlightDiagnostics.lua, README.md, CHANGELOG.md, INSTALL-GUIDE.md, 이 보고서 |

## 검사 결과

| 검사 | 결과 |
| --- | --- |
| 정적 | Lua 5.1 문법 227개, XML 7개, TOC 참조 19개, SavedVariables 소유권 12개. Base의 선택 프레임 필수 의존성 및 ZIP 간 폴더·파일 중복 없음. ZIP CRC와 작업 사본의 바이트 일치 확인. |
| 모의 설치 | 344개 단언 통과. Base 84, Base+UnitFrames 102, Clock 미설치 59, Convenience 미설치 36, 신규 Base 63. |
| 모의 시계·편의 | 명단 대기·접속 상태·14/15/16명 경계·길드 이탈·타이틀/글꼴·클릭과 드래그, 부캐 기록 필터·0코퍼·프로필 제외, 하위 탭·검색 경로·설정 불변, 타이머 접기·펼치기와 알람/노트 내용 보존. |
| 모의 전문기술 | 이전 프로필과 문자열 이관, 신규 경로 우선, OFF 유지, 초기화·복사, Clock 없는 표시, 응급치료 및 기술 순서, 네 방향·경계 분기, ESC 전파/특수 창 닫기, 창 표시 우선순위, 통합 편집 대상과 초기화 연결. |
| 모의 대상 치유 | 대상 이벤트·빠른 전환, 공개량·제한량, 치유 해제·사망·최대 체력·과잉 치유, 체력 갱신·크기·기본 앵커, 전투 중 OFF 후 복원. |
| 인게임 | 로컬 Forever 실행 파일의 버전 1.60.1.70938을 확인했습니다. 접속 세션에서 새 ZIP을 실행한 검증은 미실시입니다. |

### 인게임에서 남은 확인

- 길드창 열기와 이름·성 표시, 실제 길드 명단 지연 및 접속 상태 변경.
- 각 프로필의 실제 전문기술 위치와 배율, 네 방향 화면 경계, 전투 안팎 ESC와 기본 전문기술 창의 동작.
- 아군 대상 치유 시전·취소·완료, 전투 중 제한값과 체력바 갱신, 위치·크기 변경 및 기본 모양·모듈 OFF 복원.
- 1.11.7.2 SavedVariables로 교체 설치 후 /reload, 타이머·노트·미니맵 주머니·기본 시전바·창 겹침 회귀 확인.
- 요청에 언급된 참고 스냅샷 2장은 첨부 목록에서 확인되지 않았습니다. 전문기술은 기존 목록 외형과 명시된 요구사항을 따랐고, 소지금 툴팁은 이름·금액 두 열을 사용했습니다.
