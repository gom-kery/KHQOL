# KHQOL 1.11.2.5 변경·검증 보고서

기준 1.11.2.4 Full · 2026-10-18.

## 재접속 플레이어 적용

실제 사용자 진단: `UF true true false true true nil false`. 크기/높이/위치 읽기는 1·2·4번 부품에서 모두 true, 3번 기본 HealthBar만 모두 false. `UF-D true true true`. OFF→ON은 효과 없고 /reload 뒤에만 적용됐습니다.

1.11.2.4의 ApplyCompactLayout 사전 검사가 기본 HealthBar의 읽기 실패에서 중단되는 조건을 모의 재현했습니다. 수정본은 플레이어도 자체 HealthDisplay를 사용합니다. 기본 HealthBar와 HealthBarsContainer의 크기·위치를 읽거나 변경하지 않고, 수치와 최대치를 숫자 C 위젯으로 전달합니다. 비공개 수치의 비교·계산·문자열 변환으로 배치를 결정하지 않습니다. 기본 수치/스크립트와 클릭/메뉴는 교체하지 않습니다.

이름·레벨·자원·외곽선은 자체 표시를 기준으로 배치하며, 기존 체력 바 컨테이너의 화면 표시는 알파 저널로 억제/복원합니다. OFF·편집 모드·전투·프로필 변경도 검증했습니다. 공개 체력 값과 비공개로 표시한 숫자 패킷을 별도로 시험했으며, 모의 환경은 게임의 보안 경계를 완전히 재현하지 않습니다. 자체 표시는 현재 체력·최대치·기본 문구를 동기화하며, 기본 체력 컨테이너에 붙는 회복 예측·보호막 세그먼트는 복제하지 않습니다. 관련 기본 그림은 간결한 모드에서 컨테이너와 함께 억제되고 OFF/편집 모드에서 복원됩니다.

## 헤더

저장된 대상 버프 분류가 플레이어 기본 경로에 무조건 붙던 코드를 수정했습니다. 분류는 대상/버프·디버프에서만 유효하며 탭 선택·재진입·검색 경로도 같은 규칙을 사용합니다. 분류 선택 자체는 보존합니다.

## 설치 정리

KH_map 전체와 미사용 Theme.lua/그림 3개, 과거 문서 9개를 배포에서 제외했습니다. Theme.lua의 TOC 로드 행도 제거했습니다. 긴 과거 CHANGELOG는 이전 입력 사본에 보존하고 이번 설치에는 현 버전 변경만 담습니다. 정상 기능 파일과 저작권·출처 안내는 유지합니다. 기존 입력/전달 ZIP과 실제 AddOns/WTF는 변경하지 않았습니다.

- `KH_map/KH_map.toc`
- `KH_map/README.md`
- `KHQOL_Map/Theme.lua`
- `KHQOL_Map/Media/Switch.tga`
- `KHQOL/Media/kh-qol-minimap-button.png`
- `KHQOL_Labs/BuffReminder/Media/ForeverBuffReminder-Minimap-BR.png`
- `KHQOL/docs/history/MODULE-CONNECTIONS-1.10.10.md`
- `KHQOL/docs/history/README-1.10.10.md`
- `KHQOL/docs/history/ROADMAP-1.10.10.md`
- `KHQOL/docs/DEPENDENCY-INVENTORY.json`
- `KHQOL/WeaponGuide/INTEGRATION.md`
- `KHQOL_Labs/BuffReminder/KHQOL_INTEGRATION.md`
- `KHQOL_Campfire/Campfire/KHQOL_INTEGRATION.md`
- `KHQOL_Map/REPORT.md`
- `KHQOL_Map/TEST_RESULTS.md`

## 검사 결과

| 검사 | 통과 |
|---|---|
| regression | 256/256 |
| targeted | 18/18 |
| party-shared | 24/24 |
| login | 26/26 |
| visibility | 16/16 |
| migration | 12/12 |
| stacking | 8/8 |
| free-drag | 20/20 |
| relogin | 19/19 |
| health-layout | 14/14 |
| header | 6/6 |
| 합계 | **419/419** |

원래 회귀 검사 256개와 변경 범위별 검사를 통과했습니다. 이전 로그인 검사의 표시 크기 판정은 기본 바 대신 실제 표시용 HealthDisplay를 검사하도록 변경했고, 별도 검사로 기본 HealthBar의 크기·위치 읽기/쓰기 0회를 확인합니다. 미니맵 이전 검사는 KH_map 없는 현재 저장소의 로그인·재접속·캐릭터 공유와 선택적 옛 데이터 호환성으로 갱신했습니다.

19개 폴더 / 268개 파일 / Lua 191개 / XML 4개 / 고유 저장 변수 11개. 최종 ZIP CRC·파일 목록·TOC 경로·버전·자산 경로·제외 목록·설정 소유권·입력 보존은 PACKAGE-MANIFEST.json 및 배포 검사에서 확인합니다.

실제 수정판 게임 검증은 미실시입니다. 설치 후 /reload를 먼저 하지 않고 문제가 있던 캐릭터의 재접속 상태를 확인해야 합니다.
