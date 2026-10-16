# KHQOL 1.11.1.0 출처·자산·사용 조건 확인

2026-10-16. 실행 코드와 미디어의 입력은 사용자가 제공한 1.10.10 TEST-FULL ZIP입니다. 외부 이미지·소리·글꼴·애드온 라이브러리를 새로 내려받아 포함하지 않았습니다. 기존 주석·기능별 안내·과거 변경 이력의 출처 표기를 보존했습니다.

## 동봉 글꼴

`KHQOL/Fonts/IsamanruLight.ttf`의 name table은 esamanru Light / 이사만루체 Light, Version 1.0.0, GONGGAMES, FONTRIX 제작을 표시합니다. 바이너리는 원본과 동일하며 Clock 폴더의 같은 글꼴 사본만 제거했습니다.

권리자 표기: Copyright (c) 2020 GONGGAMES. All rights reserved. Font designed by FONTRIX Inc.

공게임즈의 공식 안내에서 상업적 사용과 임베딩 허용, 수정하여 유료 판매하는 행위의 제한을 확인했습니다. 공식 표의 OFL 항목은 X이므로 이 글꼴을 OFL 자산이라고 새로 표시하지 않습니다. 이번 패키지는 종전 동봉 글꼴을 기능 내 표시용으로 유지합니다. 별도 글꼴 배포·판매에 대한 권한을 추가로 주장하지 않습니다. [공게임즈 공식 Font License](https://gonggames.com/)

## 이미지·소리·참고 코드

32개 동봉 자산은 모두 입력 ZIP의 바이트와 같고 중복 해시는 없습니다. 기존 전투 이미지와 노트 아이콘은 소유 폴더만 바뀌었습니다. PNG/TGA/OGG/WAV의 별도 저작자·허가서가 입력 ZIP에 동봉되어 있지 않은 경우에는 원저작권·별도 재배포 권한까지 확인 완료로 표시하지 않습니다.

게임 내장 atlas/Blizzard 경로는 게임 리소스 참조이며 해당 리소스 파일을 새로 추출해 동봉하지 않았습니다. 기존 README의 사용자 참고 글, WeaponGuide README의 자료 출처, CHANGELOG의 Forever 코드 근거를 보존했습니다. 외부 참고 애드온 코드를 새로 가져오지 않았습니다.

## API 확인 자료

애드온 설치 조회·활성 상태·실제 애드온별 두 번째 vararg 테이블에 관한 API 서명은 [Forever UI 소스의 AddOnsDocumentation.lua](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/AddOnsDocumentation.lua)를 확인했습니다. 코드 열람은 실행 중인 사용자 클라이언트의 지원 실측을 대신하지 않습니다.

목록 아이콘 지정은 [Forever AddonList.lua](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_AddOnList/AddonList.lua)의 IconTexture 메타데이터 읽기와 기본 물음표 처리에 근거합니다. 기존 미니맵 파일을 그대로 참조하며 외부 이미지를 추가하지 않았습니다.

개발 검사는 Lupa 2.8의 Lua 5.1 실행기를 작업 폴더에서만 사용했습니다. Python/Lupa/시험 스크립트는 게임 설치 패키지에 포함하지 않습니다.
