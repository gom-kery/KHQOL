# KHQOL 1.11.8.8 변경·검증 보고서

- 기준 `KHQOL-1.11.8.7-Full.zip`의 작업 사본. 원본 SHA-256 `1cf69ac839de6ae73c298e5a39721e81e821e39b0208df3e7170e339c920c975`.
- 대상 WoW Forever 1.60.1 / 빌드 70938 / Interface 16001. 결과 `KHQOL-1.11.8.8-Full.zip`.

## 변경 및 확인 결과

| 항목 | 변경 | 모의 검사 |
| --- | --- | --- |
| 가방 휴지통 | 기존 UI가 휴지통의 전체 설정을 한 프레임으로 세어 아코디언 화살표를 숨기던 문제를 수정했습니다. | 화살표 표시, 접기 시 전체 컨트롤 숨김, 다시 펼치기, 기존 휴지통 설정과 아이템 보호를 확인했습니다. |
| 길드 접속자 | 접속자의 레벨·캐릭터명·지역을 정렬합니다. 지역은 `C_Club.GetMemberInfo`의 공개 `zone` 값을 쓰며, 본인 지역은 `GetRealZoneText()`가 우선입니다. 누락되거나 읽을 수 없는 지역은 `—`로 표시합니다. 기존 툴팁 축약 기준도 적용됩니다. | 이름·지역 정렬, 비공개 값, 지역 이동 이벤트, 명단 재조회 없이 본인 지역 갱신, 축약 시 지역 열 숨김을 확인했습니다. |
| 파티 버튼 | 우클릭 시 아군 플레이어 대상의 상태에 따라 `PLAYER`, `PARTY`, `RAID_PLAYER` 메타를 기본 메뉴에 전달합니다. 대상 없음, 본인, 적대 대상, NPC 또는 대상 관계를 확인할 수 없으면 본인 `SELF` 메뉴를 엽니다. | 대상 없음·본인·일반 아군·파티원·공격대원·적대·NPC·제한 데이터에 따른 기본 메뉴 요청을 확인했습니다. |
| 미니맵 버튼 정리 | 펼쳐진 수납함은 기본 24px 아이콘에 맞춘 격자를 사용하며 아이콘 크기 슬라이더는 수납 버튼의 배율만 조절합니다. 직사각형 버튼은 긴 변을 기준으로 비율을 유지합니다. | 가로형과 세로형에서 20→30px로 변경했을 때 펼친 수납함의 크기·위치·수용량 및 수납 버튼 36px 크기가 유지되고 개별 버튼만 커졌습니다. |
| 경험치바 | 문자열에 공백 한 칸을 사용하는 `Lv 29`·`레벨 29` 형식을 적용했습니다. 가로형에서 바 내부·외부 및 왼쪽·오른쪽을 조합할 수 있습니다. 내부에 레벨이 있을 때는 경험치 문자열 영역을 줄여 텍스트 자리를 나눕니다. 초기값은 바 외부·왼쪽·`Lv 29`입니다. | 네 위치의 실제 앵커, 문구와 공백, 내부 배치 여백, 레벨 표시 OFF 시 여백 해제, 프로필 값 저장을 확인했습니다. |

길드 지역 정보의 제공 여부와 갱신 주기는 게임 명단을 따릅니다. 대상 메뉴 종류와 UI 플래그는 기본 대상 프레임의 경로를 따릅니다. [Forever 길드 명단 API](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/ClubDocumentation.lua#L1724-L1742) · [Forever 대상 메뉴](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UnitFrame/Mainline/TargetFrame.lua#L574-L626)

## 수정 파일과 검증 범위

- `KHQOL_Convenience/UI/ConvenienceDetails.lua`, `BagItemSettings.lua`, `KHQOL_Convenience/Modules/PartyButton.lua`.
- `KHQOL_Clock/Clock/Guild.lua`, `KHQOL_Map/Buttons.lua`, `KHQOL_Map/Settings.lua`.
- `KHQOL_ExperienceBar/Modules/ExperienceBar.lua`, `KHQOL_ExperienceBar/UI/ExperienceSettings.lua`, `SearchIndex.lua`.
- 버전 참조, TOC 19개와 패키지 내 문서를 갱신했습니다.

Lua 236개와 XML 8개, TOC 19개 정적 검사를 통과했습니다. 기본 설치, 유닛프레임 포함, 시계 제외, 편의 기능 제외, 신규 설치의 5가지 모의 구성에서 회귀 검사를 통과했습니다. 포에버 실제 접속 상태에서 길드 지역 수신, 파티 메뉴 표시 및 전투 제한, 툴팁과 바 화면의 실제 배치는 **인게임 미검증**입니다.
