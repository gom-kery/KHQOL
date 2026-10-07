# KHQOL DESIGN SYSTEM

## 1. 목적

이 문서는 KHQOL의 설정 화면과 각 모듈 세부 설정 UI가 서로 다른 방식으로 만들어지는 것을 방지하기 위한 최소 디자인 시스템이다.

현재 단계에서는 전체 UI를 완성형으로 리디자인하지 않는다.

목표는 다음과 같다.

- 앞으로 추가되는 신규 모듈이 동일한 UI 규칙을 사용하도록 한다.
- Tooltip, CursorHUD, CastBar 등 신규 모듈부터 동일한 구조로 개발한다.
- 기존 모듈은 KHQOL 전체 통합 단계에서 순차적으로 이 규칙에 맞춘다.
- 기능 개발과 UI 리팩토링이 서로 과도하게 얽히지 않도록 한다.
- 향후 디자인 변경이 필요할 때 공통 규칙만 수정하면 전체에 반영될 수 있도록 한다.

---

# 2. 현재 단계의 원칙

## 2.1 지금 확정할 것

현재 단계에서는 다음 항목만 공통 규칙으로 확정한다.

- 설정 화면 기본 레이아웃
- 페이지 여백
- 섹션 구조
- 항목 간 간격
- 제목 / 설명 텍스트 계층
- 체크박스
- 슬라이더
- 드롭다운
- 버튼
- 색상 선택
- 위치 / 잠금 UI
- 초기화 UI
- 모듈 활성화 UI
- 공통 UI Component 구조
- 명칭 규칙

---

## 2.2 지금 확정하지 않을 것

다음 항목은 전체 통합 이후 Final UI/UX Polish 단계에서 결정한다.

- 세부 색상 팔레트
- 최종 폰트 스타일
- 애니메이션
- Hover 효과
- 세부 테두리 스타일
- 그림자
- 장식 요소
- 고급 Preview 시스템
- 완성형 테마 기능
- 복수 스킨 지원

즉 현재 목표는:

> 예쁘게 만드는 것이 아니라 일관되게 만드는 것

이다.

---

# 3. 전체 설정 화면 구조

KHQOL 설정 화면은 좌측 모듈 목록 + 우측 설정 영역 구조를 기본으로 한다.

```text
┌─────────────────────────────────────────────┐
│ KHQOL                                       │
├───────────────┬─────────────────────────────┤
│ 일반          │                             │
│ Clock         │   선택한 모듈 설정          │
│ Todo          │                             │
│ BuffReminder  │                             │
│ Range         │                             │
│ ResourceSwing │                             │
│ Campfire      │                             │
│ Tooltip       │                             │
│ CursorHUD     │                             │
│ CastBar       │                             │
└───────────────┴─────────────────────────────┘
```

기본 방향:

- 좌측은 모듈 탐색
- 우측은 현재 선택한 모듈 설정
- 모듈별 별도 창을 만들지 않는다.
- 가능한 모든 설정은 KHQOL 설정 화면 안에서 관리한다.

---

# 4. 권장 기본 크기

정확한 수치는 Forever 환경 테스트 후 변경 가능하다.

현재 개발 기준값은 다음을 사용한다.

```text
전체 설정창 폭      : 760 ~ 820
전체 설정창 높이    : 560 ~ 620

좌측 메뉴 폭        : 170 ~ 190
우측 콘텐츠 Padding : 20

페이지 상단 Padding : 18 ~ 24
섹션 간 간격        : 24
항목 간 간격        : 10 ~ 14

일반 Row 높이       : 28 ~ 32
버튼 높이           : 24 ~ 28
드롭다운 높이       : 24 ~ 28
입력창 높이         : 24 ~ 28
```

중요:

- 각 모듈에서 임의의 수치를 직접 사용하는 것을 최소화한다.
- 공통 Theme 또는 Constants에서 가져오도록 한다.

---

# 5. Theme / Constants 구조

공통 레이아웃 값은 한 곳에서 관리한다.

예시:

```lua
KHQOL.UI.Theme = {
    WindowWidth = 800,
    WindowHeight = 590,

    SidebarWidth = 180,
    ContentPadding = 20,

    SectionGap = 24,
    RowGap = 12,
    RowHeight = 30,

    ControlHeight = 26,
    ButtonHeight = 26,

    DisabledAlpha = 0.45,
}
```

모듈별 UI 코드에서 다음과 같은 하드코딩을 반복하지 않는다.

```lua
SetPoint("TOPLEFT", 17, -43)
SetSize(143, 27)
```

가능한 경우 Theme 값을 사용한다.

---

# 6. 페이지 정보 구조

각 모듈은 가능한 한 동일한 정보 구조를 따른다.

기본 순서:

```text
모듈 제목
짧은 설명

[✓] 모듈 사용

General
────────────

Appearance
────────────

Position
────────────

Behavior
────────────

Advanced
────────────
```

모든 모듈이 모든 섹션을 가질 필요는 없다.

필요한 섹션만 사용한다.

---

# 7. 섹션 규칙

## General

모듈의 가장 핵심적인 기능 설정.

예:

- 기능 사용 여부
- 기본 동작
- 핵심 선택 옵션

---

## Appearance

화면 표현 관련 설정.

예:

- 크기
- 폭 / 높이
- 색상
- 투명도
- 텍스트 크기

---

## Position

위치 관련 설정.

예:

- X / Y
- Anchor
- 위치 초기화
- 위치 잠금

---

## Behavior

기능의 동작 방식 설정.

예:

- 전투 중만 표시
- 항상 표시
- 특정 조건에서 숨김
- 표시 시간

---

## Advanced

일반 사용자는 자주 수정하지 않는 설정.

예:

- Refresh Rate
- Frame Strata
- 세부 Offset
- 디버그 관련 설정

Advanced에 들어갈 옵션을 기본 화면에 무분별하게 노출하지 않는다.

---

# 8. 페이지 헤더

각 모듈 페이지 상단은 동일한 구조를 사용한다.

```text
Cursor HUD

마우스 커서의 시인성을 높이고
커서 주변에 전투 정보를 표시합니다.

[✓] 모듈 사용
```

순서:

1. 모듈 제목
2. 한두 줄 설명
3. 모듈 사용 체크박스
4. 첫 번째 섹션

모듈 사용 여부를 페이지 중간이나 하단에 두지 않는다.

---

# 9. 제목 / 설명 텍스트 계층

텍스트 역할을 명확하게 구분한다.

## Level 1 — Module Title

페이지 최상단.

예:

```text
Cursor HUD
```

---

## Level 2 — Section Title

예:

```text
Appearance
Position
Advanced
```

섹션 제목 아래에 Divider를 사용할 수 있다.

---

## Level 3 — Control Label

예:

```text
커서 크기
트레일 길이
툴팁 위치
```

---

## Description

보조 설명.

예:

```text
커서 뒤에 남는 잔상의 최대 길이입니다.
```

설명은 짧게 유지한다.

긴 도움말은 Tooltip 사용을 우선 검토한다.

---

# 10. Control 배치 규칙

각 설정은 가능한 한 Row 단위로 배치한다.

## Checkbox

```text
[✓] 전투 중에만 표시
```

필요한 경우:

```text
[✓] 전투 중에만 표시
    전투가 시작되면 자동으로 표시합니다.
```

---

## Slider

```text
커서 크기

[────────●────────] 80
```

규칙:

- 라벨 위치 통일
- 현재 값 표시 위치 통일
- Min / Max 표시는 꼭 필요할 때만 사용

---

## Dropdown

```text
툴팁 위치

[ 마우스 오른쪽          ▼ ]
```

---

## Color Picker

```text
링 색상

[■] 색상 선택
```

색상 버튼 크기와 위치를 모든 모듈에서 통일한다.

---

## Button

```text
[ 위치 초기화 ]
```

버튼은 기능에 필요한 만큼만 사용한다.

과도하게 큰 버튼이나 모듈마다 다른 크기를 사용하지 않는다.

---

# 11. Enable / Disable 규칙

모든 모듈은 동일한 활성화 방식으로 표현한다.

```text
[✓] 모듈 사용
```

모듈이 비활성화되어 있을 경우:

- 하위 설정 Disable
또는
- Alpha 감소

중 하나의 공통 방식을 사용한다.

추천:

```text
DisabledAlpha = 0.45
```

단, 비활성 상태에서도 현재 설정값은 확인 가능하게 한다.

---

# 12. Position / Move / Lock 규칙

화면에 표시되는 모듈은 가능한 경우 동일한 UX를 사용한다.

기본 용어:

```text
위치 잠금
위치 초기화
X 위치
Y 위치
```

사용하지 않을 표현:

```text
Lock Frame
Frame Lock
이동 금지
Move Lock
```

모듈마다 다른 표현을 쓰지 않는다.

---

## 권장 기본 구조

```text
Position
────────────

[✓] 위치 잠금

X 위치
[────●────] 0

Y 위치
[────●────] 0

[ 위치 초기화 ]
```

---

# 13. Reset 규칙

초기화 기능은 영향 범위가 명확해야 한다.

## Section Reset

필요한 경우에만 제공.

```text
[ 현재 섹션 초기화 ]
```

---

## Module Reset

각 모듈 하단.

```text
[ 모듈 설정 초기화 ]
```

---

## Global Reset

KHQOL 일반 설정에만 제공.

```text
[ 전체 설정 초기화 ]
```

전체 초기화는 확인창을 반드시 사용한다.

---

# 14. 설정 명칭 규칙

동일한 기능은 모든 모듈에서 같은 명칭을 사용한다.

권장:

```text
모듈 사용
위치 잠금
위치 초기화
크기
폭
높이
투명도
텍스트 크기
배경
테두리
색상
전투 중에만 표시
항상 표시
```

기능이 같다면 모듈마다 명칭을 바꾸지 않는다.

---

# 15. 공통 UI Component

KHQOL 신규 모듈은 가능한 한 공통 UI Component를 사용한다.

최소 Component:

```text
CreatePage()
CreateSection()

CreateLabel()
CreateDescription()
CreateDivider()

CreateCheckbox()
CreateSlider()
CreateDropdown()
CreateButton()
CreateButton()
CreateColorPicker()
```

추후 필요하면 추가:

```text
CreateEditBox()
CreateTabGroup()
CreateScrollArea()
```

---

# 16. Component 사용 원칙

모듈에서 직접 Frame을 생성할 수 없는 것은 아니다.

다만 일반적인 설정 UI는 공통 Component를 먼저 사용한다.

예:

```lua
KHQOL.UI:CreateCheckbox(...)
KHQOL.UI:CreateSlider(...)
```

권장하지 않는 방식:

```lua
local checkbox = CreateFrame(...)
local slider = CreateFrame(...)
```

을 모든 모듈에서 반복 구현하는 것.

목적:

- 크기 통일
- 여백 통일
- 동작 통일
- 수정 비용 감소

---

# 17. 신규 모듈 적용 대상

다음 모듈부터 이 DESIGN.md 규칙을 기본 적용한다.

개발 순서 기준:

```text
Tooltip
CursorHUD
CastBar
ResourceSwing
```

기존 모듈:

```text
Clock
Todo
BuffReminder
Range
CampfireAlert
WeaponGuide
```

는 현재 기능 개발 과정에서 무리하게 수정하지 않는다.

KHQOL 전체 통합 단계에서 순차적으로 변경한다.

---

# 18. Tooltip 적용 예시

```text
Tooltip

게임 내 툴팁의 위치와 표시 방식을 조정합니다.

[✓] 모듈 사용


General
────────────

표시 시간
[ 기본값 ▼ ]


Position
────────────

툴팁 위치
[ 마우스 오른쪽 ▼ ]

X Offset
[────●────] 10

Y Offset
[────●────] 0


Appearance
────────────

텍스트 크기
[────●────] +1


Information
────────────

[✓] Item ID
[ ] Spell ID
[✓] Weapon Guide
```

---

# 19. CursorHUD 적용 예시

```text
Cursor HUD

마우스 커서를 강조하고
커서 주변에 전투 정보를 표시합니다.

[✓] 모듈 사용


Cursor
────────────

[✓] 커서 링 표시

크기
[────●────] 80

투명도
[────●────] 100%


Trail
────────────

[✓] 트레일 표시

길이
[────●────] 12


GCD
────────────

[✓] GCD 링 표시


Cast
────────────

[✓] 시전 링 표시
```

---

# 20. CastBar 적용 예시

```text
Cast Bar

플레이어의 주문 시전을
간결한 Cast Bar로 표시합니다.

[✓] 모듈 사용


General
────────────

[✓] Blizzard Cast Bar 숨김


Appearance
────────────

폭
[────●────] 300

높이
[────●────] 22

[■] 바 색상


Text
────────────

[✓] 주문 이름
[✓] 남은 시간


Position
────────────

[✓] 위치 잠금

[ 위치 초기화 ]
```

---

# 21. 피해야 할 패턴

다음과 같은 UI 구현은 피한다.

- 모듈마다 다른 설정창 폭
- 설정 항목마다 다른 Row 높이
- 동일 기능인데 다른 명칭 사용
- 컨트롤 좌표 하드코딩 난립
- 박스를 지나치게 많이 사용
- 설명 텍스트 과다 노출
- 중요하지 않은 기능을 페이지 상단에 배치
- 모든 옵션을 한 페이지에 평면적으로 나열
- Reset 버튼을 옵션마다 배치
- 비활성 옵션이 활성 상태처럼 보이는 UI
- 모듈마다 다른 Button / Slider / Dropdown 구현

---

# 22. 신규 모듈 개발 체크리스트

새로운 설정 화면을 만들기 전에 확인한다.

```text
[ ] 공통 Page 구조를 사용했는가?
[ ] Module Title / Description이 있는가?
[ ] 최상단에 모듈 사용 옵션이 있는가?
[ ] Section 단위로 옵션을 그룹화했는가?
[ ] Theme 값을 사용했는가?
[ ] 공통 Component를 우선 사용했는가?
[ ] 동일 기능에 기존 명칭을 사용했는가?
[ ] Advanced 옵션을 기본 화면에 과도하게 노출하지 않았는가?
[ ] Position / Reset UX가 다른 모듈과 동일한가?
[ ] 설정 저장 후 Reload에서도 유지되는가?
```

---

# 23. 향후 Final UI/UX Polish 단계

모든 주요 모듈 개발 및 KHQOL 통합 이후 다음을 진행한다.

```text
Final UI/UX Polish

- 기존 모듈 전체 디자인 시스템 적용
- 최종 Color Palette
- Font Style
- Divider / Border
- Hover State
- Disabled State
- Preview UX
- 스크롤 영역 정리
- 문구 통일
- 세부 Alignment
- 전체 Padding 재조정
```

이 단계에서 DESIGN.md를 최종 디자인 가이드로 확장한다.

---

# 24. 현재 적용 방침 요약

현재 KHQOL 개발에서는 다음 규칙을 적용한다.

```text
지금:
Design System 뼈대 정의
        ↓
Tooltip부터 적용
        ↓
CursorHUD 적용
        ↓
CastBar 적용
        ↓
ResourceSwing 적용
        ↓
KHQOL 전체 통합
        ↓
기존 모듈 UI 마이그레이션
        ↓
Final UI/UX Polish
```

현재 단계에서는 기존 모듈의 기능 안정성을 해치면서까지
설정 UI 전체를 리팩토링하지 않는다.

신규 모듈부터 일관된 구조로 개발하고,
최종 통합 과정에서 기존 모듈을 동일한 디자인 시스템으로 정리한다.

---

# 25. Tooltip 레퍼런스 구현 (KHQOL 1.1.0)

Tooltip은 이 문서의 첫 구현 레퍼런스다. 다음 공통 패턴을 실제
`SettingsUI.lua`의 `KHQOL.UI` Component로 제공한다.

```text
CreateLabel()
CreateDescription()
CreateSection()
CreateCheckbox()
CreateSlider()
CreateDropdown()
```

각 Component는 동일한 콘텐츠 폭, Section Divider, 행 간격 및
`DisabledAlpha = 0.45` 처리를 사용한다. 이후 신규 모듈은 같은
Component를 우선 사용하며, Tooltip 전용으로 유사 컨트롤을 다시 만들지
않는다.

Tooltip의 기본값 복원은 하단의 모듈 단위 버튼을 사용한다. Tooltip은
기존 WeaponGuide SavedVariables를 한 번만 호환 읽기하므로, Tooltip
초기화 후에는 오래된 WeaponGuide 값을 다시 가져오지 않는다.
