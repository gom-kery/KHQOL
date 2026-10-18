# KHQOL 1.11.2.5 인계

기준은 전달 완료된 1.11.2.4 Full입니다. 실제 사용자 진단에서 기본 플레이어 HealthBar의 geometry 읽기 3종이 실패해 전체 간결한 레이아웃을 막는 조건을 확인했습니다. 자체 HealthDisplay로 배치를 분리하고, 대상 분류가 플레이어 헤더에 남는 문제를 함께 수정했습니다.

19개 폴더 / 268개 파일 / Lua 191개 / XML 4개 / 저장 변수 11개. KH_map과 감사에서 확인한 미사용/과거 파일을 제외했습니다. 덮어쓰기만으로 기존 디스크 파일이 삭제되지는 않으므로 기존 코드 폴더를 AddOns 밖에 보관한 뒤 새 폴더를 넣습니다. WTF와 KHQOLMapDB는 유지합니다.

자동·모의 419/419 통과. 실제 수정판 게임 검증은 대기 중입니다. 설치와 재접속 확인은 INSTALL-GUIDE.md, 근거/검사 범위는 CHANGE-VALIDATION-REPORT.md, 연결 계약은 MODULE-CONNECTIONS.md를 따릅니다. 원본 ZIP과 실제 AddOns/WTF는 수정하지 않았습니다.
