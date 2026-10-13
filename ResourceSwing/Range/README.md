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
