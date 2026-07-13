# BUG-01 — Toggle off/on steals UI input

**Status:** Fix landed in tree (`buildId: 2026-07-13-toggle1`) — **Max smoke + Grit QA pending**  
**Priority:** P0  
**Author note:** Drafted by Grok from Max report + journal evidence. Bones may refine.

## Symptom

After toggling the crosshair **off then on** (default **Meta+Shift+X**, action name `Infinite Crosshair: Toggle`), the user **loses control from the UI** — desktop / apps / settings no longer receive pointer input as expected.

## Evidence

- Journal (`kwin_wayland`): sequences of  
  `InfiniteCrosshair toggled OFF` → `claimed client caption= Infinite Crosshair` → `toggled ON`.
- Code (pre-fix): `Window { visible: root.crosshairEnabled ... }` so each OFF **unmaps** the full-screen surface and each ON **remaps** it.

## Hypothesis

On Wayland, remapping the full-screen `Qt.Window` fails to reliably re-apply (or KWin fails to honor) `Qt.WindowTransparentForInput` / related flags. The overlay then sits above the desktop and **eats input**. Claiming `skipSwitcher` etc. does not restore input-through.

## Requirements

1. Toggle **MUST** hide and show the crosshair **visuals** only.
2. Toggle **MUST NOT** unmap the overlay `Window` solely to hide the crosshair.
3. After arbitrary off→on cycles, pointer events **MUST** reach underlying windows (same as before first toggle).
4. When hidden, crosshair lines and ticks **MUST NOT** paint.
5. Shortcut, action name, and skip* / keepAbove claim behavior **MUST** remain.
6. **MUST NOT** introduce cursor-position `Timer` polling (constitution).

## Implementation plan (Grok)

1. Keep root `Window` always mapped: `visible: true` (or equivalent always-on).
2. Bind `visible: root.crosshairEnabled` (or opacity gate) on:
   - vertical line `Rectangle`
   - horizontal line `Rectangle`
   - tick `Item` (combine with existing tick visibility conditions)
3. Simplify `toggleCrosshair()`: flip `crosshairEnabled`; optional re-claim only if needed (prefer not remapping).
4. Bump `buildId` so Max can confirm the running body from journal `ready build=`.
5. Keep `main.qml` and `Crosshair.qml` **in sync** until dedupe debt is planned (both are currently full copies).

## Out of scope

- Color picker (BUG-03)
- Multi Configure dialogs (BUG-02)
- Dedupe main/Crosshair architecture

## Exit criteria

- [ ] `./scripts/package.sh && ./scripts/check.sh` exit 0
- [ ] Max: 10× Meta+Shift+X off/on — crosshair hides/shows; mouse still clicks panels/apps
- [ ] Grit: `qa/review-*-toggle*.md` PASS (constitution: no cursor Timer)

## Test notes for Max

1. Enable script; confirm lines track cursor.
2. Press Meta+Shift+X → lines gone; click taskbar / terminal — must work.
3. Press again → lines back; click again — must work.
4. Repeat rapidly; check journal for `build=` id after reload.
