# KHQOL Resource / Swing Bar — Forever MVP

Install the `KHQOLResourceSwing` folder under `World of Warcraft/_forever_/Interface/AddOns/`, then enable it from the AddOns list. Use `/krsb` to open the standalone Korean settings window. It does not use the unstable Forever Edit Mode / ESC Settings integration.

## Compatibility decisions

The addon targets the currently reported WoW: Forever interface number `16001` and deliberately avoids Edit Mode registration. Forever uses the modern UI architecture, but custom Edit Mode registration is not yet a stable public contract; the addon instead provides the native-style Settings panel and direct drag/lock controls.

Resource values are refreshed from `UNIT_POWER_UPDATE` and `UNIT_MAXPOWER`, with `UnitPower`, `UnitPowerMax`, and `UnitPowerType`. The resource fill uses a native `StatusBar`, which safely accepts Forever's Secret power values without Lua arithmetic. The text uses the client formatter, and the resource colour follows `PowerBarColor` when automatic colour is enabled.

Swing starts and durations are received from Forever's native `PLAYER_SWING` event. Its `Enum.PlayerSwingType` value identifies main hand, off hand, or ranged, and its duration is the client-authoritative timer value. A single lane inside the bottom of the resource frame displays the most recently restarted swing; its colour identifies the weapon type. `WEAPON_SLOT_CHANGED` refreshes weapon-dependent auxiliary information. Only the brief active swing animation uses `OnUpdate`.

## Forever swing handling

`COMBAT_LOG_EVENT_UNFILTERED` is blocked for third-party addons in Forever, so the addon does not register it. The client provides `PLAYER_SWING` instead; it supplies the authoritative timer duration and hand type needed for this UI.

Hunter ammo uses `GetInventorySlotInfo("AmmoSlot")`, `GetInventoryItemTexture`, and `GetInventoryItemCount`. It is shown only for Hunters with an ammo-slot item. This should be checked in the live Forever client because the game-era rules and item inventory behavior may still change.

## Saved variables

`KHQOLResourceSwingDB` stores enablement, dimensions, lock state, point/offset, colour values, text toggles, ammo toggle, and automatic resource-colour choice. Forever beta reports a known SavedVariables restore issue, so persistence must be retested after client updates.

## Test checklist for live client

- Warrior (rage): resource update, main-hand and off-hand with dual wield.
- Rogue (energy): resource regeneration and dual wield.
- Hunter (mana): ranged auto attack, equipped ammo, zero-ammo state.
- Weapon swap and haste/attack-speed change while in combat.
- Reload UI: saved size, colours, and position.

Druid form-specific power selection is consciously outside this MVP. A later pass should add form-change events and a per-form resource policy around `UnitPowerType`.
