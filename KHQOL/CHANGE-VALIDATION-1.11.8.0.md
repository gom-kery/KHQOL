# KHQOL 1.11.8.0 변경·검증 보고서

2026-11-16 · WoW Forever 1.60.1 / 빌드 70938 / Interface 16001

작업 전 사용 가능한 `KHQOL-1.11.7.10-Full.zip`의 CRC와 TOC 19개에 기록된 버전 및 Interface를 확인했습니다. 로컬 설치 기록의 Forever 빌드는 70938입니다. ZIP을 작업 사본에 풀어 수정한 뒤 전체 설치 ZIP으로 다시 묶었습니다. 요청에서 언급된 스냅샷 1~5는 이번 메시지에서 확인할 수 없어 기존 모닥불의 중앙 배치와 전문기술 패널의 빈 칸을 기준으로 배치했습니다.

## 버프 감사 알림

- **말머리·자동 인사 → 버프 감사 알림** 기본 OFF. 오른쪽 또는 왼쪽 추가 방향, 알림마다 10~30초의 유지 시간을 설정합니다. 기본값은 오른쪽과 20초입니다. 방향을 바꾸면 열린 아이콘도 재배치합니다.
- `UNIT_AURA`의 추가 항목을 확인하고, 공개된 오라 데이터와 다른 플레이어의 캐릭터명·직업이 확인되면 아이콘을 표시합니다. 로그인·`/reload`·그룹 탈퇴 시 현재 오라를 기준 상태로 기록합니다. 지속시간·중첩 갱신 및 동일 효과가 같은 이벤트에서 교체되는 경우를 제외합니다. 홈·인스턴스 그룹과 공격대를 검사하며 그룹에 합류하면 열린 알림을 닫습니다. [오라 업데이트 형식](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitConstantsDocumentation.lua#L55-L63) · [오라 조회 제한](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitAuraDocumentation.lua#L175-L206)
- **음식·스크롤 구별**은 확인 범위를 제한하는 방식입니다. 신비한 지능·총명함, 야생의 징표·선물·가시, 신의 권능: 인내·인내의 기원, 일부 성기사 축복의 등록된 스킬 오라 ID와 시전자 직업을 함께 확인합니다. 자기 버프, 음식·두루마리처럼 등록되지 않은 ID, 오라 출처가 불명확한 효과는 제외합니다. 수신 오라에는 소비 아이템 사용 여부를 알려 주는 필드가 없어 미분류 효과를 허용하지 않습니다. Forever 신규 랭크 및 동일 오라 ID를 공유하는 아이템의 전수 확인은 미검증입니다.
- **좌클릭 즉시 발송**은 클릭 시점의 `C_ChatInfo.SendChatMessage`로 한 번 요청합니다. 전투 여부와 별도로 채팅 발송 제한을 확인합니다. 채팅 제한이 있거나 직접 API를 사용할 수 없는 경우에는 **클릭 즉시 발송 미지원**으로 처리하고, 기존 귓속말 초안을 채워 Enter를 기다립니다. 입력 중인 초안은 보존합니다. 전송 결과가 불명확해도 재요청하지 않습니다. [직접 채팅 API](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/ChatInfoDocumentation.lua#L532-L544) · [게임 귓속말 초안](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_ChatFrameBase/Shared/ChatFrameUtil.lua#L342-L355)

## 부캐 전문기술

- **전문기술 → 부캐 전문기술 표시**의 기본값은 OFF입니다. 펼친 목록의 빈 칸에 도구 아이콘을 넣고, 빈 칸이 없으면 패널을 확장합니다. 아이콘을 클릭하면 **캐릭터명 / 전문기술명 / 숙련** 목록을 열며, 긴 목록은 휠과 스크롤 막대로 이동합니다. OFF로 바꾸거나 프로필을 전환하면 열린 조회창을 닫습니다.
- 기존 전문기술 조회 및 부캐 소지금과 같은 GUID·서버·진영 식별을 사용합니다. 패널 표시와 별도로 로그인과 전문기술 갱신 시 저장합니다. 현재 캐릭터와 다른 서버·진영은 제외하고, 확인한 주·보조 기술을 기술당 한 줄로 표시합니다. 초기 데이터나 일부 기술을 읽지 못하면 그 항목의 기존 값을 보존합니다. 전문기술 갱신 뒤 완전한 조회에서 두 번 연속 빠진 행은 제거합니다. 응급치료는 캐릭터 기술 목록을 추가로 확인합니다. [기술 목록 API](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/SkillInfoDocumentation.lua#L55-L85)
- 계정 공용 기록은 기존 `KHQOLDB.globalData.characterProfessions`에 저장하고 프로필 백업에서 제외합니다. 별도 SavedVariables 선언은 추가하지 않았습니다.

## 변경 파일

- `KHQOL_Convenience/Modules/BuffThanks.lua`, `Modules/ChatEnhancement.lua`, `Modules/GeneralConvenience.lua`, `UI/ConvenienceDetails.lua`와 `Adapters.lua`에 오라 알림·귓속말·설정을 연결했습니다.
- `KHQOL_Convenience/Modules/AltProfessions.lua`, `Modules/Professions.lua`, `UI/ProfessionSettings.lua`, `KHQOL/MoneyRecords.lua`와 `KHQOL/Profiles.lua`에 기술 기록·표·공용 식별·기본 설정을 추가했습니다.
- Convenience의 `UI/SearchIndex.lua`와 모듈 TOC, 전체 버전 표기, README·CHANGELOG·설치 문서를 갱신했습니다.

## 검증 결과

| 항목 | 결과 |
| --- | --- |
| 정적 | Lua 233개, XML 8개, TOC 19개, SavedVariables 선언 12개 검사. 전체 ZIP CRC와 바이트 비교 완료 |
| 모의 | 기존 1,131건과 새 편의기능 144건을 통과 |
| 버프 | 기존 오라·갱신, 자기 버프·음식·두루마리 샘플, 시전자 제한과 불완전한 이름, 방향, 두 알림의 개별 만료, 우클릭을 확인 |
| 그룹·귓속말 | 일반 파티·공격대·인스턴스 그룹, 탈퇴 후 기준 재설정, 그룹 합류 후 클릭 차단, 저장한 성명으로 솔로 전투·비전투 한 번 요청, 초안 보존, 제한·결과 불명 시 재발송 방지를 확인 |
| 부캐 | 닫힌 패널에서 기록, 지연·불완전 조회, 숙련도 갱신, 학습·포기, 서버·진영 필터, 방향과 순서 전환, 조회창·스크롤·OFF, 프로필 재적용을 확인 |
| 실제 인게임 | **미검증**. 솔로 전투·비전투의 실제 마우스 클릭과 수신자 도착, 음식·두루마리 분류, 인게임 모양 및 `/reload` 후 지속은 게임에서 실행하지 못함 |
