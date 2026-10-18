# KHQOL 1.11.4.1 변경·검증 보고서

기준 1.11.4 · 2026-10-18 · 배포 파일 `KHQOL-1.11.4.1-아코디언여백-겹침수정.zip`.

## 문제와 원인

사용자 화면에서 주시대상 → 체력·자원의 섹션을 접어도 큰 여백이 남고, 이름·레벨을 접은 채 다른 메뉴를 다녀온 뒤 펼치면 두 섹션의 옵션이 겹쳤습니다.

하위 Builder는 접기 상태에 맞게 높이를 바꿨지만 아코디언 갱신은 해당 하위 프레임에만 Refresh를 호출했습니다. 바깥 DetailLayout의 배치 갱신은 그 범위 밖이어서, 하위 내용의 높이와 상위 행의 높이가 달라졌습니다. 접은 직후에는 상위 행의 펼친 높이가 남아 여백이 생기고, 재진입으로 상위 행이 작아진 뒤 펼치면 다음 행이 아래로 이동하지 않아 겹쳤습니다.

전체 메뉴 검사를 확장하면서 일반·프로필 화면의 별도 문제도 확인했습니다. 공용 Builder가 현재 높이를 계산한 뒤 스크롤 호스트가 처음 생성 때의 contentHeight를 다시 사용했습니다. 접기·펼치기에 따라 스크롤 범위가 잘못 유지되거나 내용이 잘릴 수 있었습니다.

## 수정

공용 SettingsLayout.lua의 아코디언 갱신이 현재 활성 설정 화면까지 포함해 Refresh하도록 바꿨습니다. 하위 영역이 속한 상위 행의 배치 갱신도 함께 실행하므로 클릭 직후 다음 제목·옵션과 스크롤 높이가 현재 내용에 맞춰집니다. 독립적으로 만든 영역은 기존 해당 영역 갱신을 사용하며 다른 메뉴를 강제로 열지 않습니다.

일반·프로필처럼 화면 자체가 공용 Builder를 사용하는 경우에는 현재 재배치 결과로 contentHeight를 갱신한 뒤 스크롤 높이와 현재 위치를 조정합니다.

전체 아코디언·두 열 배치와 세션 접기 상태를 유지합니다. 데이터·프로필 스키마·기능 ON/OFF는 바꾸지 않습니다. 변경한 Lua는 공용 배치 1개와 버전 표기 2개뿐이며 나머지 개인/파티 프레임 표시·오라·보호막·미니맵·입력·저장 실행 코드와 미디어는 1.11.4와 같습니다.

## 검증

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
| effects | 37/37 |
| layout | 7/7 |
| preview-paint | 1/1 |
| settings | 20/20 |
| reflow | 20/20 |
| 합계 | **504/504** |

새 reflow 검사 20개에는 첨부 화면의 주시대상 체력·자원과 이름·레벨, 두 섹션의 독립 펼침, 일반·프로필 스크롤 범위, 5개 유닛의 지원 부품 전환, 전체 11개 메뉴의 모든 탭에서 접기 → 메뉴 이동 → 재진입 → 펼치기와 폭 700/480/400 변경을 포함합니다. 하위 영역과 상위 행 높이가 일치하고 표시된 행·셀의 사각 영역이 겹치지 않는지, 내용이 스크롤 높이에 포함되는지 검사합니다. 접기로 모듈 설정·프로필 세대가 변하지 않는지도 확인합니다.

이전 배포 1.11.4에 같은 검사 중 4개를 실행하면 상위 행 높이와 스크롤 높이 단정이 모두 실패합니다. 수정본에서는 통과합니다. 이전 484개 검사도 현재 배포 사본에서 다시 실행했습니다. 기존 검사가 전환 직후의 상위 행 좌표와 스크롤 범위를 충분히 확인하지 못했던 부분을 보완했습니다.

자동 검사는 게임 UI를 모의한 결과입니다. 실제 클라이언트 글꼴·그리기·보호/taint·재접속·정상 저장 검증을 대신하지 않습니다. 수정판 실게임 확인 절차는 [설치 안내](INSTALL-GUIDE.md)에 기록했습니다.

## 배포 정리

19개 폴더 / 271개 파일 / Lua 193개 / XML 5개 / 미디어 32개 / 고유 저장 변수 11개입니다. KH_map과 이전 불필요 파일 15개는 계속 제외합니다. KHQOLMapDB는 KHQOL_Map이 소유합니다. TOC·저장 변수·자원 경로·해시·파일 목록·ZIP CRC와 실제 새 파일명을 별도 검사합니다. 이전 배포본·기준 작업 사본과 실제 AddOns/WTF는 변경하지 않았습니다.

## 유지된 효과 구현의 참고 자료

다음은 1.11.3에서 확인한 API 자료입니다. 이번 UI 변경에서 새로운 외부 코드나 자산은 추가하지 않았습니다.

소스 열람과 모의 환경은 현재 사용자 클라이언트에서의 실행 검증을 대신하지 않습니다.

- [CustomAuraContainer의 슬롯·필터·초기화](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_AuraContainer/Blizzard_CustomAuraContainer.lua)
- [CustomAuraButton의 종류별 그림과 RGBA 적용](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_AuraContainer/Blizzard_CustomAuraButton.lua)
- [AuraContainer의 기본 우선순위와 접근 제한](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_AuraContainer/Blizzard_AuraContainerShared.lua)
- [ColorCurve API](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/LuaColorCurveObjectAPIDocumentation.lua)
- [게임 기본 공격대 보호막 리소스 사용](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_UnitFrame/Shared/CompactUnitFrame.lua)
- [Plater 작성자의 dispel 색상 곡선 사용 예](https://github.com/Tercioo/Plater-Nameplates/blob/master/Plater_Auras.lua): Magic=1, Curse=2, Disease=3, Poison=4, Bleed=11 교차 확인. 외부 실행 코드는 복사하지 않았습니다.
