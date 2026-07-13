# Feature: Offset guide lines (secondary V/H)

**Status:** Implemented (v5 — sticky guides during window drag)  
**buildId:** `2026-07-13-offset5`

## Product model (Max)

Not “shift the whole crosshair.” Two layers:

1. **Primary** vertical + horizontal stay on the **cursor** (main color / width / opacity / ticks).  
   → These **never** depend on window hit-testing, so they stay visible while moving windows.
2. **Second vertical** and **second horizontal** guides: each has enable, **offset** (px), **own color**.  
   → Used to mark the **border** of the thing you are aligning/moving.

## Math

```
primaryX = cursor.x
primaryY = cursor.y

// Manual (auto off):
offsetVerticalX   = cursor.x + OffsetVerticalOffset     // negative = left of cursor
offsetHorizontalY = cursor.y + OffsetHorizontalOffset // negative = above cursor

// Auto (default on):
offsetVerticalX   = nearest left/right of target window frameGeometry
offsetHorizontalY = nearest top/bottom of target window frameGeometry
```

## Config (`main.xml` + `config.ui`)

| key | type | default | UI |
|---|---|---|---|
| `OffsetVerticalEnabled` | Bool | false | checkbox (manual mode) |
| `OffsetVerticalOffset` | Int | 100 | spinbox (−4000…4000 px) |
| `OffsetVerticalColor` | Color | `#00FFFF` | KColorButton |
| `OffsetHorizontalEnabled` | Bool | false | checkbox (manual mode) |
| `OffsetHorizontalOffset` | Int | 100 | spinbox |
| `OffsetHorizontalColor` | Color | `#00FF00` | KColorButton |
| `AutoOffsetOnMove` | Bool | true | Auto-align guides to window borders (under cursor / while moving) |

Disk also mirrors `*ColorR/G/B` for LineColor and both offset colors (not shown in UI).

## Shortcuts (defaults)

| shortcut | action |
|---|---|
| **Meta+Shift+X** | Toggle primary crosshair visibility |
| **Meta+Shift+V** | Toggle second vertical (manual emphasis) |
| **Meta+Shift+H** | Toggle second horizontal |
| **Meta+Shift+B** | Capture nearest edges → set offsets + sticky + enable |
| **Meta+Shift+C** | Clear guides / sticky |

## Automagic + sticky drag (`AutoOffsetOnMove`)

### Hover

Second V/H appear on nearest frame edges of the window under the cursor.  
Recomputed from `Workspace.cursorPos` (no cursor Timer).

### While moving / resizing (critical)

Primary stays on cursor (by design).

Guides **must stay** for the whole drag. Implementation:

1. Prefer any window with KWin **`move` / `resize` true** (cursor may leave the frame).  
2. Else window from `interactiveMoveResize*` hooks (`offsetTrackWindow`).  
3. Else window under cursor.  
4. Store **`guidesSticky` + `stickyEdgeX/Y`**; show guides while sticky.  
5. On each cursor tick / move step / `frameGeometryChanged`, refresh sticky edges from live geometry.  
6. Clear sticky when move ended and no window under cursor.

If guides only used hit-testing, they vanished mid-drag (Max report: main stays, guides go away). Sticky + move flags fix that.

### Manual

Auto off → spinbox offsets only; V/H checkboxes / shortcuts control visibility.

## KWin APIs

| API | use |
|---|---|
| `Workspace.cursorPos` | primary + sync tick |
| `Workspace.stackingOrder` | under-cursor / move scan |
| `window.move` / `window.resize` | detect interactive drag |
| `interactiveMoveResizeStarted/Stepped/Finished` | track + rev bump (Mouse Tiler pattern) |
| `frameGeometry` / geometry fields | live edge positions |

**Yes — KWin allows tracking moving windows.** Overlay stays `WindowTransparentForInput`.

## Out of scope

- More than one extra V or H  
- Ticks on secondary lines  
- Click-to-capture without shortcut  

## History

| build | note |
|---|---|
| `offset1` | Whole-crosshair shift — wrong product shape |
| `offset2` | Second V/H + color + offset (Max model) |
| `offset3` | Automagic edge align under cursor |
| `offset4` | Prefer `move`/`resize` flags while dragging |
| `offset5` | **Sticky** edges so guides do not vanish mid-drag |
