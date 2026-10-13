# KHQOL 편입 메모

`ForeverBuffReminder`는 현재 독립 설치·배포용 애드온이다. 이 문서는 KHQOL에 편입할 때의 최소 작업만 기록하며, KHQOL의 Core·설정 UI·의존성은 포함하지 않는다.

## 현재 경계

- `Core.lua`: SavedVariables 초기화, 직업별 버프 상태 판정, 이벤트와 `/fbr` 명령을 소유한다.
- `UI.lua`: 알림 Anchor, 아이콘 풀, Glow와 카운트다운 표시만 소유한다.
- `Settings.lua`: 독립 설정창과 버프 편집 UI만 소유한다.
- `ForeverBuffReminderDB`: 이 애드온의 계정 공용 설정만 저장한다. 직업별 데이터는 `classes[CLASS_TOKEN].buffs`에 있다.

전역 이름은 `ForeverBuffReminder`, `ForeverBuffReminderDB`, `ForeverBuffReminderAnchor`, `ForeverBuffReminderSettings`, `ForeverBuffReminderClassDropdown`, `SLASH_FOREVERBUFFREMINDER*`로 고유 접두사를 사용한다. 그 밖의 런타임 함수와 상태는 파일 지역 변수 또는 `ForeverBuffReminder` 테이블에 둔다.

## 향후 편입 시 최소 변경

1. KHQOL의 모듈 등록 지점에서 `Core.lua`, `UI.lua`, `Settings.lua`를 로드한다.
2. `ForeverBuffReminderDB`를 KHQOL의 모듈 네임스페이스로 마이그레이션한다. 기존 `ForeverBuffReminderDB`가 있으면 한 번만 복사해 기존 사용자의 버프 목록을 보존한다.
3. KHQOL이 제공하는 설정창에서 `CreateSettingsUI`, `ToggleSettings` 호출만 대체한다. 버프 편집 데이터와 표시 로직은 변경하지 않는다.
4. KHQOL의 공통 명령 체계를 채택할 경우에만 `/fbr` 등록을 제거하거나 하위 명령으로 위임한다.

## 호환성 원칙

- 이 모듈은 플레이어 aura만 읽으며, 보호된 값은 `UNKNOWN`으로 처리한다.
- 다른 애드온의 SavedVariables, 전역 프레임, 이벤트 핸들러를 읽거나 변경하지 않는다.
- 독립 배포 중에는 `ForeverBuffReminderDB`와 `/fbr`의 이름을 바꾸지 않는다. 이는 업데이트 때 기존 설정을 유지하는 호환 계약이다.
