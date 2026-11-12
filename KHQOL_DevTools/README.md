# KHQOL DevTools v0.1.5

Standalone World of Warcraft: Forever developer utility. It has no dependency on KHQOL and uses only its own `KHQOL_DevToolsDB` SavedVariables table.

## Versioning

Bug fixes and small improvements increment the patch number: `0.1.1`, then `0.1.2`, then `0.1.3`. New backward-compatible features increment the minor number; breaking changes increment the major number.

## Install

Place the `KHQOL_DevTools` folder in `Interface\\AddOns`, enable **KHQOL DevTools** on the character-selection AddOns screen, then reload or log in.

## Use

- `/khqoldev` toggles the window.
- `/khqoldev frames` opens the Frames tab.
- `/khqoldev console` opens the Console tab.
- `/khqoldev capture` captures and opens the copy window.
- Default capture binding candidate: **Ctrl+Shift+C**. Bind `KHQOL DevTools: Capture Frame` in the game Key Bindings UI; it is deliberately not assigned automatically to avoid overwriting an existing binding.

Frames samples the cursor target only while its tab and tracking are active. The binding immediately re-queries the cursor target before the copy dialog is shown, then freezes a plain-text snapshot. Addon-owned UI is excluded from capture.

Console passively observes `CHAT_MSG_SYSTEM` and the visible default chat frame's `AddMessage` calls. It does not replace `print`, suppress messages, or change chat output. The client may not expose the source of a line, so captured entries are labelled **Chat Output**, not guaranteed `/run` output. Console data is session-only in v0.1; options are saved independently.

Use the Console tab's **Limit** button to cycle the retained session-log limit through 10, 50, 100, 250, and 500 entries.

## Position Diagnostics

Open the **Position** tab or use `/khqoldev position`. **Snapshot & Copy** reports safe API availability and current values. **Start Sampling** performs manual 1-second sampling only while enabled; **Copy Full Report** prepares the current diagnostics plus samples for sharing. See `POSITION_DIAGNOSTICS.md` for the required in-game dungeon test plan and interpretation rules.

## Limitations needing in-game confirmation

The Forever client must be tested for (1) whether `/run print()` emits `CHAT_MSG_SYSTEM`, (2) `GetMouseFoci` or `GetMouseFocus` availability, and (3) whether a key binding can use Ctrl+Shift+C without another client binding taking precedence. If system filters are absent, Console reports the limitation and does not hook `print`.
