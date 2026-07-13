# Feature: Offset guide lines (secondary V/H)

**Status:** Implemented (v3 — automagic edge align)  
**buildId:** `2026-07-13-offset3`

## Product model (Max)

Not “shift the whole crosshair.” Instead:

1. **Primary** vertical + horizontal stay on the **cursor** (main color / width / opacity).
2. **Second vertical** guide: on/off, **offset** (px from cursor), **own color**.
3. **Second horizontal** guide: on/off, **offset** (px from cursor), **own color**.

Use case: keep the main crosshair on the grab/cursor while a second pair of guides sits on the **border** you are aligning (window edge, selection edge, etc.).

## Math

```
primaryX = cursor.x
primaryY = cursor.y
offsetVerticalX   = cursor.x + OffsetVerticalOffset     // px; negative = left of cursor
offsetHorizontalY = cursor.y + OffsetHorizontalOffset // negative = above cursor
```

## Config (`main.xml` + `config.ui`)

| key | type | default | UI |
|---|---|---|---|
| `OffsetVerticalEnabled` | Bool | false | checkbox |
| `OffsetVerticalOffset` | Int | 100 | spinbox (−4000…4000 px) |
| `OffsetVerticalColor` | Color | `#00FFFF` | KColorButton |
| `OffsetHorizontalEnabled` | Bool | false | checkbox |
| `OffsetHorizontalOffset` | Int | 100 | spinbox |
| `OffsetHorizontalColor` | Color | `#00FF00` | KColorButton |
| `AutoOffsetOnMove` | Bool | true | **Automagic:** live-snap second guides to nearest frame edges of window under cursor (and while moving). Off = manual offsets only. |

Disk also mirrors `OffsetVerticalColorR/G/B` and `OffsetHorizontalColorR/G/B` (like primary) for re-enable robustness — not shown in UI.

## Shortcuts (defaults)

| shortcut | action |
|---|---|
| **Meta+Shift+V** | Toggle second vertical guide |
| **Meta+Shift+H** | Toggle second horizontal guide |
| **Meta+Shift+B** | Capture: nearest window edges under cursor → set both offsets + enable both |
| **Meta+Shift+C** | Clear: disable both guides, offsets → 0 |

## Automagic align (`AutoOffsetOnMove`, default on)

No shortcut required for daily use:

1. Hover any normal window → second V/H guides appear on the **nearest** left/right and top/bottom **frame** edges (recomputed from `Workspace.cursorPos` every move — no Timer).
2. Drag/resize that window → tracked window wins; guides stick to its edges.
3. Leave all windows → guides hide (unless you enabled them manually with fixed offsets while auto is **off**).

Manual spinbox offsets apply when auto is **off**, or as fallback when no window is under the cursor.

Capture (**Meta+Shift+B**) still freezes offsets into the spinbox values for manual mode.

## Out of scope

- More than one extra V or H
- Ticks on secondary lines (ticks stay on primary origin)
- Click-to-capture without shortcut (overlay is input-through)

## History

- v1 (`offset1`): shifted the whole crosshair — wrong product shape.  
- v2 (`offset2`): secondary guides per Max.  
