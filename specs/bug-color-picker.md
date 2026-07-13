# BUG-03 — Color picker UX

**Status:** **RESOLVED (Max, 2026-07-13)**  
**buildId:** `2026-07-13-reen1`

## Outcome

- Configure UI uses **`KColorButton`** (`kcfg_LineColor`) again — not R/G/B spinboxes.
- Runtime keeps robust channel handling (disk may also hold `LineColorR/G/B` mirrors; not shown in UI).
- Max: picker works; settings apply; color survives disable/re-enable.

## History (why spinboxes briefly existed)

Commit `e61efa5` swapped to RGB ints after genericscripted `type=Color` looked stuck on default red. That fixed persistence for some paths but regressed UX. **reen1** restored the button and dual-path disk mirroring.

## Do not re-break

Prefer `KColorButton` in the form. If Color load flakiness returns, fix seed/poll — do not remove the picker without Max sign-off.
