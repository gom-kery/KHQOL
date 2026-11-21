# KHQOL 1.11.9.2 사거리

정확한 거리만 모드를 선택하면 단일 값/1단위로 설정합니다. 공개된 정확한 거리 API가 없는 대상은 -입니다. 자동 모드의 ~는 실제 구간 추정이며 모든 NPC를1단위로 측정하지 않습니다.

최대 표시 거리는 m/yd 각각45~80,5단위입니다. 초과 확인 시80+처럼 표시하고 최대 거리 색상을 적용합니다. 이 색상의 기준도 원거리 최대값이 아닌 설정한 표시 상한입니다. 경계가 상한에 걸친 추정은 ~80+로 구분합니다. 입력/표시는 정수이며 기존 사용자 구간의 내부 정밀도는 편집 전 보존합니다.

---

아래는 이전 버전의 기록입니다. 현재 사용법은 위 안내를 따릅니다.

# KHQOL 1.11.9.1 사거리 측정

단일 값 표시 간격 1~5는 정확한 값과 추정 단일 값에 적용하고, 거리 구간 간격 1~10은 범위 표시를 조절합니다. `~`는 추정입니다. 5야드 단위 검사 결과만 제공되는 대상은 m 변환 후 약 4~5m씩 변할 수 있습니다. 설정의 현재 측정 상태에서 이를 구분합니다. 갱신 주기는 기존 0.08초이며 OFF/대상 없음에서는 기존 방식으로 갱신을 중지합니다.

거리 색상 제목 옆 [+]로 사용자 구간을 최대 3개 추가하고 색상/▲/▼/삭제 순서로 조작합니다. ▲/▼로 기본 구간 사이에 배치할 수 있습니다. 새 이름과 숫자는 최대 5글자이며 이전 긴 이름은 저장값을 보존합니다. 표시 순서는 기본 행과의 배치이고 색상 우선순위는 사용자 행의 위쪽 활성 일치 → 기본 색상입니다. 단위 변경은 저장된 yd 경계를 변경하지 않습니다.

---

아래는 이전 버전의 기록입니다. 현재 사용법과 제한은 위 안내를 따릅니다.

# KHQOL 1.11.8.13 사거리 측정

화면에는 거리 숫자만 표시합니다. 보조 스킬 안내 줄과 설정 화면의 고정 설명 문구를 제거했습니다. 거리 계산·색상·단위·구간·고정/마우스오버 표시·무기 데드존과 기존 저장값을 유지합니다.

[변경·검증 보고서](../../KHQOL/CHANGE-VALIDATION-1.11.8.13.md). 실제 게임 검증은 미실시입니다. 아래는 과거 FRange 기록입니다.

---

# FRange v0.1.5 — WoW Forever target range indicator

## v0.1.5 changes

* The settings window is now Korean.
* Drag the settings window's title bar or an empty area to move it.
* `FRange.toc` interface is fixed to `16001`.
* Fixed an error when opening **표시 테스트** with Boolean UI settings.
* Reworked the settings layout so display, outline, position, and colour controls do not overlap.
* Replaced manual RGB text inputs with the built-in WoW colour palette.
* Removed the repeat-length setting; the indicator now always repeats its selected symbol five times.

`FRange` is a character-specific, lightweight target range state display. It does **not** calculate yards. It asks the game client whether the one configured hostile spell can be used on your current target and displays repeated symbols.

## Install

1. Extract `FRange-0.1.0.zip`.
2. Copy the contained `FRange` folder into `World of Warcraft/_whatever your Forever client uses_/Interface/AddOns/`.
3. Confirm the final path is `.../Interface/AddOns/FRange/FRange.toc` (there must not be an extra nested `FRange` folder).
4. Enable **FRange** at the character-select AddOns screen. If the client warns that the add-on is out of date, enable **Load out of date AddOns**; update the `## Interface:` value in `FRange.toc` once Forever exposes its final interface number.
5. Enter the game and run `/frange`.

## Configure

1. In **Range Skill**, use a Spell ID, Shift-clicked spell link, or exact spell name, then select **Apply**. Spell ID/link is preferred because localised spell names and ranks vary.
2. Choose `■` or `•`, length, font size, colours, outline and position.
3. Choose **Unlock position**, drag the indicator, then lock it again.
4. For Hunter, leave the melee reference blank to let FRange try known spell IDs, or enter an explicit melee spell ID. The configured range skill remains the actual ranged test.

## Range method and Forever compatibility

The add-on tries, in order:

1. `C_Spell.IsSpellInRange(spellID, "target")`
2. legacy `IsSpellInRange(spellName, "spell", "target")`
3. guarded legacy spell-ID call

It does not require action-bar slots or a guessed distance. Only if both spell APIs cannot decide, it can use `IsActionInRange` / `C_ActionBar.IsActionInRange` for an already-present matching action button; it never asks the player to add one. A result of `true`/`1` is green; `false`/`0` is out of range; `nil` is **unknown** and hides the display. No Lua error should be produced when an API is absent or a spell has no usable range test.

Use `/frange api` after entering Forever to print the detected range API availability. This is the final client-side compatibility check: beta API availability cannot be guaranteed from outside the running Forever client.

## Hunter Dead Zone method

There is no universally reliable range API that distinguishes “too close” from “too far” after a ranged spell reports out of range. FRange therefore uses a conservative three-part test:

* configured ranged spell is usable → **green**
* configured ranged spell is not usable, but melee reference is usable → **red**
* both are not usable **and** `CheckInteractDistance(target, 3)` says the target is in the client’s close-interaction bucket → **orange**
* otherwise → **red**

The final close bucket is intentionally queried from the client rather than represented as a hardcoded yard value. If the melee spell or close-interaction API cannot be verified, FRange fails safely to red instead of inventing a Dead Zone.

## Commands

* `/frange` — open settings
* `/frange test` — cycle green → red → orange test display
* `/frange lock` / `/frange unlock`
* `/frange reset` — reset this character only
* `/frange api` — print detected compatibility APIs

## Game test checklist

### All classes

- [ ] no target, friendly target, dead target, NPC dialogue target: no display
- [ ] hostile target within configured spell range: green
- [ ] hostile target outside configured spell range: red
- [ ] move through the ability boundary: indicator changes without target swap
- [ ] test both combat and out of combat
- [ ] test a spell with no range support: UI hides and does not produce an error

### Hunter

- [ ] valid ranged distance: green
- [ ] close melee distance: red
- [ ] transition into the client-recognised Dead Zone: orange
- [ ] transition back through Dead Zone to ranged distance: colour follows correctly
- [ ] swap bow/gun/crossbow and change configured range spell
- [ ] configure an explicit melee reference if auto-detection does not suit the current spellbook

### UI and persistence

- [ ] change shape, length, size, each colour and outline colour/thickness
- [ ] unlock, drag, and lock the indicator
- [ ] run `/reload` and confirm settings persist
- [ ] log a second character and confirm independent settings
