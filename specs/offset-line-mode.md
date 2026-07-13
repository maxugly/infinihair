# Feature: Offset guide lines (secondary V/H)

**Status:** Implemented (v2 — Max-corrected model)  
**buildId:** `2026-07-13-offset2`

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
| `AutoOffsetOnMove` | Bool | true | while move/resize, set offsets from nearest frame edges + enable both guides |

Disk also mirrors `OffsetVerticalColorR/G/B` and `OffsetHorizontalColorR/G/B` (like primary) for re-enable robustness — not shown in UI.

## Shortcuts (defaults)

| shortcut | action |
|---|---|
| **Meta+Shift+V** | Toggle second vertical guide |
| **Meta+Shift+H** | Toggle second horizontal guide |
| **Meta+Shift+B** | Capture: nearest window edges under cursor → set both offsets + enable both |
| **Meta+Shift+C** | Clear: disable both guides, offsets → 0 |

## Auto on move

When `AutoOffsetOnMove` and the user interactively moves/resizes a window: recompute offsets so the secondary lines sit on the nearest L/R and T/B **frame** edges of that window; enable both guides.

## Out of scope

- More than one extra V or H
- Ticks on secondary lines (ticks stay on primary origin)
- Click-to-capture without shortcut (overlay is input-through)

## History

- v1 (`offset1`): shifted the whole crosshair — wrong product shape.  
- v2 (`offset2`): secondary guides per Max.  
