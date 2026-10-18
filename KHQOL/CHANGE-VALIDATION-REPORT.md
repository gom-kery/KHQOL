# KHQOL 1.11.4.6 변경·검증 보고서

기준 **1.11.4.5** → 결과 **1.11.4.6** · 2026-10-18.

전체 설치 파일: **`KHQOL-1.11.4.6-탭설명-토템위치편집.zip`**. 입력 ZIP SHA256: `da3fed65eb1034ee32eb16128dc12fda3ed0c90315889788f62c5403b6ce21cc`.

## 적용 결과

| 요청 | 결과 |
|---|---|
| 2·3Depth 탭의 공통 프로필 문구 | 기능별 짧은 설명으로 교체; 공유 탭 새로고침 시 선택한 설명 유지 |
| 토템 전투 종료 후 위치 이동 | 숨김 프레임 측정값과 임시 플레이어 크기 의존 제거; 고정 TOPLEFT 기준과 네이티브 배치 후 재적용 |
| 플레이어 탭 명칭 | 토템 프레임 → 프레임 위치; 프레임 위치 확인, 프레임 X/Y 좌표 |
| 전체 편집 없이 토템만 이동 | 기본 OFF인 위치 확인 ON에서 전용 테두리 직접 드래그 |
| 좌표·확장 | X/Y 각각 ±3000px, 왼쪽/오른쪽 확장; 첫 아이콘 기준 유지 |
| 저장·정리 | 현재 전체 프로필 저장·복사·내보내기/가져오기, 기본 배치 복원; 세션 전용 테두리 정리 |

토템 원본 프레임·풀·아이콘·타이머·툴팁·우클릭 동작을 유지합니다. 네이티브 Layout과 보호 상태를 확인하며 보호된 프레임/자식의 전투 중 변경은 종료 후 적용합니다. 반복 타이머를 추가하지 않았고, 전용 테두리의 OnUpdate는 드래그 중에만 사용합니다. 메뉴/창/프로필 변경, 전투 시작과 드래그 종료 시 해제합니다.

기존 bottomX/bottomY 저장값은 유지하며 범위를 넓혔습니다. 추가 값은 player.bottomGrowth(RIGHT 기본)와 bottomPlaced(false 기본) 두 개입니다. SavedVariables 이름과 전체 프로필 형식 버전은 바꾸지 않았습니다. 저장 범위 정책·파트별 데이터·노트·공용 파티 프로필·등록 목록을 유지합니다. 고정 배치 기준 변경에 따라 원하는 최종 토템 위치는 전용 테두리에서 조절합니다.

## 재현과 검증

기본 게임과 같은 풀 재사용·행 재배치·실제 앵커/배율 계산을 포함하는 개발용 모형을 만들었습니다. 1.11.4.5에서 숨김 접속 후 전투 중 첫 소환/종료, 플레이어 크기 변경, 전투 중 네이티브 앵커 재배치 세 조건의 위치 이동을 확인했고 1.11.4.6에서 모두 통과했습니다. 이는 실제 게임에서의 재현 완료를 뜻하지 않습니다.

- 자동·모의 **599/599 PASS**: 기존 579개 + 이번 요청 전용 20개.
- 전용 검사: 각 탭 설명/경로/명칭, 첫 소환과 2→1→0→재소환, 풀 재사용, 방향 변경과 첫 아이콘 고정, 보호 상태/비공개 배율, 드래그와 좌표 제한, 창/메뉴/전투/프로필 종료, 초기화와 프로필 내보내기/가져오기.
- 9개 직업, 213개 섹션(일반 제목 43·아코디언 170), 배치 관찰 1,901건, 일반 목록 26개.
- 19개 TOC, Lua **193개**의 Lua 5.1 문법, XML **5개**, 로드 경로·바인딩·저장 변수 소유권·파일/자산 해시 검사.
- 1.11.4.5 입력 ZIP 및 271개 기준 파일의 해시를 작업 전후 대조합니다. 이번 변경은 기능 Lua 11개와 버전 상수 2개, TOC 버전 및 설명/검증 문서로 한정했습니다. 기존 공용 프로필·전송·등록·오라·파티 실행 엔진과 나머지 Lua/XML은 바이트 동일합니다. 새 대규모 리팩터링을 수행하지 않았습니다.

## 패키지

19개 애드온 폴더 / 논리 모듈 29개 / **271개 파일** / Lua 193개 / XML 5개 / 미디어 32개 / 고유 저장 변수 11개.

KH_map 및 이전에 제외한 불필요 경로 15개, 개발/시험 파일은 새 ZIP에 포함하지 않습니다. KHQOLMapDB는 KHQOL_Map만 소유합니다. 공용 저장 변수 10개는 KHQOL이 소유하며 빈 KHQOL/Bindings.xml 호환 파일을 유지합니다. 압축 후 CRC·파일 목록·모든 파일 바이트·해시와 TOC 버전을 재검사합니다. 실제 명세는 [PACKAGE-MANIFEST.json](docs/PACKAGE-MANIFEST.json), 전체 검사 결과는 [validation-results.json](docs/validation-results.json)입니다.

## 확인에 사용한 기본 UI 소스

토템은 표시 수에 따라 풀 버튼을 재사용하고 행을 다시 배치하며, 관리 컨테이너가 부모와 앵커를 갱신합니다. 이 경로를 기준으로 모형과 복원 시점을 구성했습니다. [TotemFrame.lua](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_UnitFrame/Mainline/TotemFrame.lua), [TotemFrame.xml](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_UnitFrame/Mainline/TotemFrame.xml), [ManagedFrameSystem.lua](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_ManagedFrameSystem/Shared/ManagedFrameSystem.lua), [LayoutFrame.lua](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_SharedXML/LayoutFrame.lua).

## 실제 게임 확인 — IN-GAME REQUIRED

실제 Forever 클라이언트를 실행해 검증하지 않았습니다. 재접속 직후, 전투 중 첫 소환·종료, 일부/전체 만료와 재소환에서 위치를 다시 확인해야 합니다. 전용 테두리 드래그·좌우 확장·저장/초기화, 보호/taint 오류와 설정창 배율별 화면 표시도 실제 클라이언트에서 확인합니다. CPU/FPS/메모리 실측은 NOT TESTED입니다.

[설치·사용 안내](INSTALL-GUIDE.md)의 순서로 확인할 수 있습니다. 기존 배포 ZIP과 실제 AddOns/WTF는 변경하지 않았습니다.
