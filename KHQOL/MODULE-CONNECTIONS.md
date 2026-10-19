# KHQOL 1.11.4.13 공통 연결 계약

- 공통 객체는 _G.KHQOL이며 선택 모듈은 ModuleRegistry에 등록합니다. 공통 기반 KHQOL에 의존합니다. 미설치 기능의 DB와 알 수 없는 설정은 보존합니다. 기존 프로필·등록·클릭/휠·정리·전투 보류 엔진을 유지합니다.
- 파티 공용 라이브러리는 globalData.partyFrameProfiles.frameProfiles입니다. 프로필 선택·역할 연결·휠 주문은 캐릭터별입니다. 공용 라이브러리는 전체 프로필 변경으로 교체하지 않습니다.
- 각 파티 프레임 프로필은 기존 debuffs와 새 debuffTint(enabled/colors RGBA), absorb(enabled/texture/color RGBA)를 소유합니다. 파티·10·20·40인에 공통입니다. 기존 저장 키를 이동하거나 새 SavedVariables를 만들지 않습니다.
- PartyFrameEffects는 공개 설정으로 게임 CustomAuraContainer 슬롯을 초기화합니다. 오라 데이터·슬롯 상태·그림 색/표시값을 다시 읽지 않습니다. 공개 RGBA 곡선 객체를 재사용하고 우선순위/판정/해제 표시는 게임 표시기에 맡깁니다. PartyFrames 전용 XML이 아이콘 템플릿을 소유합니다.
- 보호막 값/최대치는 자체 C StatusBar로 바로 전달합니다. 실제 값의 산술·비교·문자열 변환으로 크기·표시 여부를 결정하지 않습니다. 표시기는 체력 바 오른쪽에서 역방향으로 채웁니다. 아이콘은 보호막·디버프 체력 색·사망 음영·라벨보다 위에 표시합니다.
- 새 미리보기는 고정 공개 수치와 색만 사용하며 유닛을 지정하거나 native aura 슬롯을 생성하지 않습니다. 예시 보호막 비율은 모듈 세션 필드이며 SavedVariables/프로필에 저장하지 않습니다. 상시 OnUpdate를 추가하지 않습니다.
- 플레이어/대상/주시대상은 자체 HealthDisplay를 유지합니다. 기본 플레이어 체력 geometry의 읽기/쓰기를 재도입하지 않습니다. 대상 오라 분류는 unitFrames/target/auras 경로에만 붙습니다.
- KHQOL.toc은 기존 저장 변수 10개, KHQOL_Map.toc은 계정 KHQOLMapDB 1개를 소유합니다. 전체 ZIP에는 KH_map 폴더와 KHminimapDB 저장 선언이 없습니다. 이미 있는 KHQOLMapDB가 우선입니다.
- KHQOL_Map의 자유 드래그·36px 트레이·HIGH 표시·화면 비율 위치·복원 기록을 유지합니다. 계정 미니맵 세부 설정은 전체 프로필 전송과 독립입니다.

- 전체 설정의 공용 Builder는 두 열 기준 폭 480과 숨긴 행 간격 축소를 사용합니다. DetailLayout과 편의 기능의 별도 배치도 같은 작은 화살표 접기를 사용합니다. 접기 상태는 UI.disclosureStates의 세션 값이며 모듈·유닛·부품·편집 범위로 구분하고 저장 설정과 독립입니다. 목록과 편집기·미리보기는 전체 폭입니다.
- Builder:Block은 기존 목록·편집기·조건별 화면을 섹션의 표시/높이 계산에 포함합니다. 등록 목록의 저장·취소·데이터 소유권과 실험실 잠금은 그대로입니다. 새 SavedVariables나 반복 갱신 타이머는 없습니다.

- 제목의 화살표만 26×26 버튼입니다. 제목 글자는 별도이며 기존 공용 레이아웃 옵션과 접기 상태를 유지합니다.
- 예시 디버프 색은 자체 StatusBar로 그리며 공개 예시 비율을 전달합니다. 기본 체력 채움 Texture의 크기/상태를 조회하거나 붙이지 않습니다. 실제 native 오라 표시기는 변경하지 않습니다.

- 아코디언 갱신은 현재 활성 설정 화면의 상위 배치까지 포함합니다. 중첩 DetailLayout의 행 높이·좌표도 접기/펼치기와 같은 호출에서 갱신합니다.
- 일반·프로필의 스크롤 contentHeight는 공용 Builder의 현재 reflowBottom과 여백으로 갱신합니다. 최초 생성 높이를 다시 적용하지 않습니다.

- 공용 섹션의 옵션이 0~1개이면 일반 제목과 항상 펼친 내용으로 표시합니다. 숫자 칸·바로가기는 중복 집계하지 않고 설명은 제외하며 등록 목록·편집 블록은 복수 항목으로 유지합니다.
- 일반 목록은 설정 탭을 대조합니다. 퀘스트 목록/길 안내 및 미니맵/버튼 정리는 기존 모듈 사용 상태를 공유하고 진입 탭만 구분합니다. 일반 편의는 설정 진입입니다. 실험실 기능은 일반 목록에서 제외하고 기존 실험실 잠금과 미설치 필터를 유지합니다.
- 설치 상태는 일반 소개 문구 행 오른쪽의 [?] 툴팁, 공용 위치 편집은 설정창 헤더에서 제공합니다. 탭 내부의 자동 위치 편집 버튼은 생성하지 않습니다.

파일/로드 순서는 docs/MODULE-FILES.csv, 배포 명세는 docs/PACKAGE-MANIFEST.json에 있습니다.

- 하위 탭에는 기능 설명을 표시하고 저장 범위는 기존 툴팁에 유지합니다. 공유 모듈을 사용하는 탭도 선택된 설명을 새로고침 후 유지합니다.
- 토템 좌표는 기존 player.bottomX/bottomY를 유지하며 ±3000으로 확장합니다. bottomGrowth(기본 RIGHT)와 bottomPlaced(기본 false)는 현재 전체 프로필의 추가 설정입니다. 위치 확인·드래그 상태는 세션 전용이며 별도 SavedVariables가 없습니다.
- 토템 위치 확인 ON은 전체 위치 편집에 진입하지 않습니다. 전용 테두리만 입력을 받으며 드래그 중에만 자체 OnUpdate를 사용하고 종료·창 닫기·메뉴 이동·전투·프로필 변경 시 해제합니다.

- 1.11.4.7: 자원·스윙바는 SoulShards.lua로 영혼의 조각 문구/최대 수량과 잠금 ON 클릭 조작을 연결합니다. 기존 KHQOLResourceSwingDB의 현재 전체 프로필 범위이며 별도 저장 변수는 없습니다.
- 유닛프레임 각 유닛의 rootPosition(enabled/x/y)은 UIParent 논리 px의 TOPLEFT 좌표입니다. 기본 enabled=false이며 간결한 프레임에서만 적용합니다. 전용 편집은 unitRoots 범위로 5종만 수집하고 전역 편집은 기존 제공자 연결을 유지합니다.
- 네이티브 SetPointBase/ClearAllPointsBase를 우선 사용하여 편집 모드 스냅/저장 메타데이터를 직접 바꾸지 않습니다. 전투 중에는 쓰지 않으며 기본 편집 모드·모듈 OFF·간결한 프레임 OFF에서 소유한 앵커를 복원합니다.

- 1.11.4.8: UnitFrameRootPreview.lua는 드래그 핸들 아래에 체력·자원·이름·레벨·수치를 렌더링합니다. 테두리는 간결한 바 영역만 감싸고 rootPosition은 기존 네이티브 루트 TOPLEFT 좌표 형식을 유지합니다.
- 원본은 표시 플래그·앵커·입력 속성을 변경하지 않고 편집 중 알파만 임시 억제합니다. 원래 위치의 입력은 소유한 비보호 차단 프레임으로 처리하고 완료/취소/전투/필터 변경 시 복원합니다. 복원 실패는 전투 종료 때 재시도합니다.
- 드루이드 변신 마나의 showDruidMana 체크박스를 표시 대상에서 해당 제목 아래로 이동했습니다. 저장 변수·조건·런타임은 그대로입니다.

- 1.11.4.9: PositionGrid.lua는 위치 편집에만 나타나는 화면 중앙 기준 격자와 ON/OFF·간격 슬라이더를 담당합니다. UI/PositionStore.lua의 Screen()과 편집 좌표가 같은 UIParent 좌표계를 사용합니다.
- 격자 선택은 KHQOLDB.toolWindows.preferences.editorGrid/editorGridSpacing에 계정 공통으로 저장하며 현재 프로필 초안을 저장하지 않습니다. 기존 위치 writer·앵커·자식 상대 오프셋은 유지합니다.
- 조작 창은 기본 90% 배율을 사용하고 선택 프레임·미리보기·저장 좌표의 배율은 유지합니다. 드래그 중에만 기존 임시 드라이버에서 좌표 문구를 갱신합니다.

## 1.11.4.10 현재 연결

- PlayerAux/PlayerSoulShards는 KHQOL_UnitFrames가 소유합니다. 기존 KHQOLResourceSwingDB 보조 표시 필드와 ammo 위치 ID를 유지하고 unitFrames 사용 여부로 실행합니다. ResourceSwing OFF·미설치에서도 동작하며 프로필 전환·편집 종료를 UnitFrames 어댑터에서 정리합니다. 위 1.11.4.7의 SoulShards.lua 경로는 이 버전에서 대체됩니다.
- 기존 저장 표를 보존하기 위해 Profiles.lua가 보조 표시 필드만 따로 캡처·기본값·복원합니다. 자원바 초기화는 보조 표시를 유지하고 유닛 프레임 초기화는 보조 표시도 초기화합니다. 없는 자원바 모듈의 다른 값은 보존합니다.
- UnitFrameValueText는 플레이어·대상 수치의 정렬/X/Y와 기본 게임 수치 복사를 담당합니다. UnitFrameRootPreview가 같은 배치 규칙을 사용합니다.
- PartyFrameDebuffFilter는 계정 공용 프레임 프로필에 문자열 키 ID 맵을 저장하고 네이티브 CustomAuraContainer에 숫자 키 제외 필터를 전달합니다. 기본 목록은 비어 있으며 게임 보호 주문은 제외되지 않습니다. 일반 프로필 전송의 기존 파티 프레임 제외 정책은 유지합니다.
- 자동판매는 BAG_UPDATE_DELAYED 후 완료를 확인하면 다음 슬롯으로 진행합니다. 대체 확인 0.05초, 한 요청의 응답 기한 0.75초, 동일 요청 재판매 없음, 마지막 판매 뒤 수리 1회 원칙을 유지합니다.

## 1.11.4.11 설정 화면 갱신

SettingsUI.UpdateContentHeight는 변경 후 다음 화면 갱신에서 메인 ScrollFrame의 자식 영역을 다시 계산합니다. 같은 프레임의 요청을 하나로 병합하고, 창이 닫혔으면 생략하며 현재 페이지를 사용합니다. UI.SettingsLayout.RefreshAccordionLayout은 기존 QueueDisplayRefresh를 재사용해 접기/펼치기 뒤 텍스트와 배치가 안정된 시점에 한 번 더 갱신합니다. 페이지 캐시·선택 탭·아코디언 상태·입력·설정 저장 경로는 유지합니다.

PartyFrameDebuffFilter의 피드백은 빈 문자열로 생성한 문구에 Refresh 콜백이 문자열을 설정합니다. 함수 자체를 FontString.SetText에 넘기지 않습니다. 필터 저장 및 네이티브 렌더링은 변경하지 않습니다.

## 1.11.4.12 수치 정렬 및 제외 가능 여부

UnitFrameValueText.LayoutValueText는 플레이어·대상의 체력/자원 수치를 선택한 CENTER/LEFT/RIGHT 바 앵커 하나에 붙입니다. 같은 양쪽 앵커 안의 정렬만 바꾸던 구현을 교체하고 이전 폭을 0으로 풀어 자연 폭으로 표시합니다. 글자나 비밀 데이터의 폭을 읽지 않습니다. 기존 ApplySettings 경로에서 즉시 반영하며 전투 중 배치 변경은 기존 보류 정책을 유지합니다. 위치 편집용 미리보기에도 같은 함수와 배율을 적용합니다.

기존 건강/자원 표시 형식과 저장 필드는 유지합니다. 활성 프로필 GetDB에서 플레이어·대상의 healthTextX/Y 및 powerTextX/Y만 -50~50으로 제한합니다. 범위 밖 값은 가까운 경계, 잘못된 값은 0, 잘못된 정렬은 CENTER로 정리합니다. 다른 프레임·이름·보조 표시 좌표는 바꾸지 않습니다.

PartyFrameDebuffFilter.CanExcludeDebuffID는 기존 공개 C_Secrets 판정을 재사용해 공개 주문만 제외 가능으로 안내합니다. 보호 주문은 저장을 허용하되 제외 불가와 아이콘 유지 문구를 표시합니다. 실제 CustomAuraContainer 후보 필터와 목록 저장 구조는 그대로입니다. 휴식 강화 1229451의 보호 분류는 사용자 화면의 현재 클라이언트 판정에 근거하며 전역 상수로 하드코딩하지 않습니다. [클라이언트 필터 기준](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_AuraContainer/Blizzard_AuraContainerUtil.lua).

## 1.11.4.13 전투 종료 적용과 기본 일괄 판매

PartyFrames.OnCombatEnd는 공용 보류 처리기에 등록된 작업을 중복 소비하지 않습니다. 변경이 없으면 전체 ApplyLatest를 생략하고 역할 프로필·그룹/공격대 단계·기본 프레임 소유권을 확인합니다. 변경이 필요할 때 최신 설정을 한 번 적용합니다. 성공한 RefreshAll 뒤 ConfigureEvents는 버튼 이벤트를 다시 등록하지 않습니다. 실패 후 자기 복원/양보 정책을 유지하고 같은 종료 이벤트에서 다시 시도하지 않습니다. 설정·로드/주문 이벤트는 기존 요청 경로를 유지합니다.

UnitFrames.WithResolvedDB는 동기 적용 도중에만 한 번 정규화한 설정을 재사용합니다. 종료/예외 시 해제하고 프로필 세대·루트 DB·유닛 설정 테이블이 바뀌면 재사용하지 않습니다. 단순 체력 표시/글자 스타일의 전투 보류는 각 표시의 플래그로 관리하고 전투 종료에 RefreshCombatDisplays로 복원합니다. 실제 배치·공개 속성 읽기 실패·모듈 OFF·토템 보호 위치 변경은 기존 전체 적용을 유지합니다. 토템/포만감과 상태 표시 복원은 가벼운 경로에도 포함됩니다.

잡템 판매는 IsSellAllJunkEnabled가 참이고 GetNumJunkItems/SellAllJunkItems가 있는 경우 기본 C_MerchantFrame 일괄 판매를 방문당 한 번 요청합니다. 엔진의 대상 판정을 사용하며 애드온이 슬롯별 판매를 함께 보내지 않습니다. 완료는 남은 잡템 수와 이벤트/0.05초 확인으로 처리하고 2초 응답 기한 뒤 중단합니다. 요청 이후 오류/응답 지연에는 개별 판매로 전환하거나 재요청하지 않습니다. API/기능이 미지원인 경우에만 기존 검사 기반 개별 큐를 사용합니다. 자동 수리는 확인된 완료 뒤 기존 한 번의 판단을 사용합니다. [클라이언트 API](https://raw.githubusercontent.com/Gethe/wow-ui-source/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/MerchantFrameDocumentation.lua).
