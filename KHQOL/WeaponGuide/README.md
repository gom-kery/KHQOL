# 구형 WeaponGuide 보존 자료

이 폴더는 KHQOL 1.10.4.0 메인 TOC에서 로드하지 않습니다. 현재 KHQOL의 무기 안내 기능은 `Tooltip/WeaponGuideProvider.lua` 등 Tooltip 제공자 코드가 담당합니다.

구형 소스·하위 TOC·`ForeverWeaponGuideDB` 관련 호환 처리는 삭제하지 않았습니다. 이 폴더를 별도 애드온으로 설치할 필요는 없습니다. 아래 독립 설치 안내와 beta API 설명은 과거 개발 기록이며 현재 KHQOL 설치 지침이 아닙니다.

## 과거 독립 애드온 기록

---

# ForeverWeaponGuide 0.1.0-beta

Install `ForeverWeaponGuide` in the Forever client's `Interface/AddOns` folder, then enable it at character select.

## Safety status

This package is intentionally conservative. Forever's modern `C_SpellBook.IsSpellKnown` API directly queries each supported weapon-proficiency spell, so it supports the documented Beta weapon-master paths for Warrior, Paladin, Hunter, Rogue, Priest, Shaman, Mage, Warlock, and Druid. It never infers "unlearned" from item usability.

`WeaponData.lua` contains the requested weapon subclass IDs, proficiency spell IDs, class lists, and trainer data sourced from public Forever Beta references. Supported Weapon Master skills use the documented 10-silver / level-1 baseline, except polearms (1 gold / level 20). Coordinates and map IDs remain disabled until verified in the Forever client.

## Supported item metadata

Weapon class ID 2; subclasses: 0/1 axes, 2 bow, 3 gun, 4/5 maces, 6 polearm, 7/8 swords, 10 staff, 13 fist, 15 dagger, 16 thrown, 18 crossbow. Wands, fishing poles, warglaives, claws and miscellaneous weapons are excluded.

## Slash commands

`/fwg`, `/fwg status`, `/fwg scan`, `/fwg debug`, `/fwg test`, `/fwg trainers`, `/fwg item`.

## API compatibility

- TOC: `16001`, reported Forever Beta interface; re-check with `/dump select(4, GetBuildInfo())` after a client update.
- Items: uses `C_Item.GetItemInfo` / `C_Item.GetItemInfoInstant`; no localized tooltip-string parsing.
- Tooltip: uses `TooltipDataProcessor` when present, otherwise a non-invasive `GameTooltip` hook.
- Skills: uses Forever's `C_SpellBook.IsSpellKnown` for each supported proficiency spell, with legacy `GetNumSkillLines` / `GetSkillLineInfo` only as a fallback. Unknown remains hidden.
- Map pins: not enabled. No verified Forever custom-pin provider or coordinate set is available; no guessed pins are created.

## Sources and verification boundary

- [Warcraft Wiki item subtype enum](https://warcraft.wiki.gg/wiki/ItemType) — item subclass IDs, API reference.
- [WoWHead Classic weapon guide](https://www.wowhead.com/classic/guide/classic-wow-weapon-skills) — Classic reference for weapon masters, skills, and class eligibility.
- [Forever spell-book API](https://warcraft.wiki.gg/wiki/API_C_SpellBook.IsSpellKnown) — Forever availability of direct known-spell checks.
- [Forever item 8178](https://www.wowhead.com/forever/item=8178/training-sword) and [Forever Archibald](https://www.wowhead.com/forever/npc=11870/archibald) — item and weapon-master references.
- [Forever weapon-skill table](https://stay-juicy.com/weapons) — Beta-client class/trainer/cost reference.

No coordinate/uiMapID pair is verified in this release, so map pins remain disabled. Data is public-Beta referenced, not a replacement for in-game regression testing after each Forever client update.

## In-game checklist

1. Run `/fwg status`; record the client interface and `skill API` result.
2. Verify each class/weapon combination with an actual weapon master before marking class data verified.
3. Learn a weapon, run `/fwg scan`, and verify it becomes `KNOWN` even at low rank.
4. Confirm each NPC, map ID, coordinate, price, and required level in the Forever client before enabling its record.
5. Exercise bag, equipped, merchant, loot and chat-link tooltips; ensure no duplicate line appears.
6. Open/close the World Map repeatedly after verified pins are implemented; verify no pin duplication.

## Future KHQOL integration

This is a standalone addon today. Its feature boundaries are intentionally kept small:

- `WeaponData.lua` owns static weapon, class, trainer, cost, and verification data.
- `Core.lua` owns character state, event registration, decisions, and the standalone `/fwg` commands.
- `Tooltip.lua` only presents a decision returned by `Core.lua`; it does not own game state.
- `Map.lua` is the isolated map adapter.

For KHQOL, load these files as a namespaced module and replace only the standalone event/slash registration with KHQOL's module lifecycle and command router. Preserve the `FWG:DecisionForItem(itemID)` boundary and retain the `verified` gates. Do not migrate `ForeverWeaponGuideDB` automatically: offer an explicit one-time import into the KHQOL namespace if a future module needs persistent settings.

The standalone package exports no intentionally global Lua table. `FWG` is a file-local addon namespace obtained from the TOC varargs; the only required global names are the unique SavedVariables table `ForeverWeaponGuideDB` and the unique slash-command registration `SLASH_FOREVERWEAPONGUIDE1` / `SlashCmdList.FOREVERWEAPONGUIDE`.
