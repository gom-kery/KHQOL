# KHQOL integration note

`ForeverWeaponGuide` remains independently installable and functional. KHQOL is not a dependency and this package does not create a KHQOL core, settings screen, shared event bus, or shared SavedVariables table.

## Stable module boundary

| File | Future KHQOL responsibility |
| --- | --- |
| `WeaponData.lua` | Load unchanged as module data; retain each `verified` gate. |
| `Core.lua` | Adapt lifecycle registration only. Keep `RefreshCharacterState`, `ScanKnownSkills`, and `DecisionForItem`. |
| `Tooltip.lua` | Register through the KHQOL module lifecycle only if its tooltip dispatcher requires it. |
| `Map.lua` | Keep as the optional map adapter; do not introduce pins before Forever support and coordinates are verified. |

## Migration checklist

1. Create a KHQOL-owned module namespace; do not expose `FWG` globally.
2. Replace the standalone frame event registration and `/fwg` router with KHQOL equivalents.
3. Keep the SavedVariables key isolated, or provide an explicit opt-in migration from `ForeverWeaponGuideDB` to a KHQOL module subtree.
4. Retest tooltip hooks alongside other KHQOL modules for duplicate lines.
5. Preserve the current safe-empty behavior for unknown skill APIs or unverified trainer data.

No current addon functionality depends on these future changes.
