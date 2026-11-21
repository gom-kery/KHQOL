# 마법책·접속 종료 보호 동작 차단 — 수정과 필수 재확인

## 사용자 확인 사실

- DevTools 0.2.0 업데이트 뒤 시작. DevTools 활성화, Usage 기록 OFF.
- DevTools만 비활성화하고 /reload하면 발생하지 않음.
- 전투 중 스킬창/마법책을 열고 전투 종료 뒤 PlayerSpellsFrame:SetAttributeNoHandler(), Frame:SetShown() 차단.
- 첫 로딩에는 LoadAddOn, SetHeight/SetWidth/SetPoint/ClearAllPoints 차단도 보고됨. 불완전한 최초 로딩 가능성이 제기됨.
- 캐릭터 선택 화면으로 나갈 때 보였던 17:37:59 행은 같은 기존 기록이었다고 확인됨. 이 행 자체는 로그아웃 신규 오류 증거로 분류하지 않음.
- 별도로 **17:59:26 ADDON FORBIDDEN: callback()**, GameMenuFrame.lua:170 로그가 새로 보고됨. 사용자가 **접속 종료 버튼 직후** 발생했다고 확인함.

제공 스택은 Blizzard의 PlayerSpells/TabSystem/UIParentPanelManager 내부로 이어지며 최초 오염 지점·차단 귀속 애드온명이 포함되지 않았습니다. 이 자료만으로 특정 함수가 원인이라고 확정하지 않습니다. 실제 게임 재현·수정 확인은 **NOT TESTED**입니다.

## 0.3.0의 변경

0. **확인된 위험 코드 제거:** 0.2.0 UsageUI의 `StaticPopupDialogs=StaticPopupDialogs or {}`는 기존 Blizzard 공용 전역을 다시 쓰고 이어 공용 목록에 확인창을 등록했습니다. 이 두 접근을 모두 없앴습니다. 초기화는 DevTools 소유 확인창에서 취소/확정하며 ON/OFF와 세대 검증을 유지합니다. 이 코드 결함은 확인했지만 두 현상의 단일 원인이라고 확정하는 게임 검증은 아직 없습니다.
1. 로그인 시 Usage 화면 내용을 만들지 않고 사용자가 Usage를 열 때 생성합니다. OFF에서는 진단 구독/관찰 연결/예약 재연결이 없습니다.
2. 모든 ADDON_LOADED 재연결을 없애고 정해진 KHQOL 폴더만 다음 회차에 한 번 연결합니다. Blizzard_PlayerSpells 등의 로딩은 무시합니다. OFF/초기화는 대기 연결을 무효화합니다.
3. Console 수집 콜백에서 화면 글자를 즉시 갱신하지 않습니다. 메모리 버퍼 후 다음 회차에 자체 화면만 갱신하며 secret 값 제외와 콜백 오류 격리를 적용합니다.
4. TOC의 Blizzard_DebugTools 자동 의존 로딩을 제거합니다. Frame Stack 버튼을 누른 경우 전투 밖에서만 요청합니다.
5. 게임이 제공하는 ADDON_ACTION_BLOCKED/FORBIDDEN의 제한된 애드온/동작 식별자를 Console에 표시합니다. Usage DB·JSON에는 넣지 않습니다. 차단을 숨기거나 기본 마법책 함수를 덮어쓰지 않습니다.

이 변경은 의심 경로를 줄이는 수정 후보입니다. 모의 검사는 WoW의 taint·secure execution을 재현하지 못하며 실제 해결의 증거가 아닙니다. 자동 DebugTools 로딩 제거로 오류의 노출 방식이 달라질 수 있으므로 **오류 표시 유무와 마법책 실제 작동을 모두 확인**해야 합니다.

## 인게임 확인표 — 전부 NOT TESTED

게임을 완전히 종료하고 0.3.0으로 교체합니다. 재현마다 /reload하여 마법책 첫 로딩 상태로 시작하고, Frame Stack은 누르지 않습니다. 먼저 Usage OFF를 확인합니다.

| 기준 | 행동 | 정상 기대 | 실제 확인 |
|---|---|---|---|
| OFF / 비전투 /reload | 첫 마법책 열기·탭 전환·닫기 | 창/탭 정상, 차단 없음 | 화면 + Console. 아직 미실행 |
| OFF / 비전투 / 새 접속 | ESC → 접속 종료 | 캐릭터 선택 화면으로 정상 이동, 새 FORBIDDEN 없음 | 17:59:26 재현. 아직 미실행 |
| OFF / Usage 열기 후 | 초기화 확인창 열기 → 취소 → ESC → 접속 종료 | 기존 통계 보존·정상 로그아웃 | 공용 목록 재오염 확인. 아직 미실행 |
| OFF / 새 /reload | 전투 시작 → 첫 마법책 열기 시도 → 전투 종료 → 다시 열기 | 전투 중 제한은 기본 규칙대로, 전투 종료 후 창·탭 정상 | 사용자 재현 순서. 아직 미실행 |
| OFF / 미리 비전투에서 한 번 열기 | 전투 중 열기 시도 → 전투 종료 → 다시 열기 | 초기 로딩 여부와 관계없이 종료 후 정상 | 첫 로딩과 재사용 구분. 아직 미실행 |
| OFF / 위 조건 | Usage 창을 한 번 연 후 같은 순서 반복 | Usage 내용 생성 후에도 정상 | 기록 OFF 유지. 아직 미실행 |
| ON | 위 세 순서 반복 | 통계 ON도 보호 동작 차단 없음 | 연결 상태·Console. 아직 미실행 |
| DevTools만 OFF /reload | 같은 순서 | 대조 조건 정상 | KHQOL/다른 애드온 조합 유지. 사용자 기존 정상 보고, 새 빌드 대조 미실행 |

오류가 재발하면 Console의 `ADDON_ACTION_BLOCKED: addon=..., operation=...` 행과 발생 시각·OFF/ON·전투 전 첫 열기 여부를 함께 기록합니다. 이 귀속명은 게임이 보고한 차단 애드온이며 최초 오염 원인과 다를 수 있습니다. Console에는 다른 채팅이 있을 수 있으므로 필요한 진단 행만 공유하세요. Usage JSON에는 이 정보가 없습니다.

원인 확인 없이 PlayerSpellsFrame 사전 강제 로드, SetTab/ToggleSpellBookFrame 교체, 보호 속성/패널 크기 수정, 전투 종료 뒤 마법책 강제 재시도 같은 처리는 추가하지 않았습니다. 같은 오류가 남으면 이 결과로 후속 원인 추적을 진행합니다. 일반 배포 판정 **HOLD**, 제한 테스트 **LIMITED GO**입니다.

참고한 native 흐름: [PlayerSpellsFrame 소스](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_PlayerSpells/Blizzard_PlayerSpellsFrame.lua), [PlayerSpellsUtil 소스](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_FrameXMLUtil/Mainline/PlayerSpellsUtil.lua). 실제 설치 Forever 빌드와 live 미러의 행 번호가 다를 수 있으며 제공된 로그를 우선합니다.

공용 전역 재대입의 위험을 교차 확인한 1차 자료: [Cogworks 작성자의 수정 기록](https://www.curseforge.com/wow/addons/cogworks/files/8106219). native [GameMenuFrame](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_GameMenu/Shared/GameMenuFrame.lua)은 공용 팝업 상태 확인과 메뉴 콜백을 통해 Logout을 호출합니다. 이는 위험 경로에 대한 근거이며 실제 Forever 빌드에서 최초 오염을 추적한 결과는 아닙니다.
