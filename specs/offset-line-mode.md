# Feature: Offset line mode

**Status:** Implemented (v1)  
**buildId:** `2026-07-13-offset1`  
**Owner implementer:** Grok (Max-directed)

## Goal

Shift the crosshair from the raw cursor so the **vertical/horizontal lines sit on the border** of the window (or object) you are aligning or moving — not through the grab point under the finger/cursor.

## Why

When you drag a window by the title bar (or an app by an interior handle), the cursor is **not** on the edge you care about. Guides through the cursor miss the edge by that grab offset. Offset mode subtracts that delta so lines track the **nearest frame edges**.

## Behavior

| action | shortcut (default) | effect |
|---|---|---|
| Toggle offset mode | **Meta+Shift+O** | On/off. When on, lines at `cursor - (offsetX, offsetY)`. |
| Capture border under cursor | **Meta+Shift+B** | Window under cursor → nearest L/R + T/B edges → set offset; mode ON. |
| Clear offset | **Meta+Shift+C** | offset → 0; mode OFF. |
| Auto while move/resize | config **Auto offset on move** (default on) | On interactive move/resize, continuously recompute offset from that window’s frame so lines stick to nearest edges. |

### Math

```
lineX = cursorPos.x - offsetX
lineY = cursorPos.y - offsetY
// when capturing from frameGeometry g:
// offsetX = cursor.x - nearest(g.x, g.x+g.width)
// offsetY = cursor.y - nearest(g.y, g.y+g.height)
```

Ticks follow the same origin as the lines.

### Constraints

- Overlay stays `WindowTransparentForInput` (no click-to-capture on the overlay itself) — use shortcuts.
- Skip our own overlay client when picking windows.
- Prefer `frameGeometry` when available, else `geometry`.
- No cursor-position Timer; offsets update on shortcut, move/resize signals, or existing cursor-driven bindings.

## Config

| key | type | default |
|---|---|---|
| `AutoOffsetOnMove` | Bool | `true` |

Offset mode itself is runtime (shortcuts); optional sticky offsets are not written to kwinrc in v1.

## Out of scope (later)

- Click-to-capture without shortcut (would need input-through off briefly)
- Multi-window / screen edge only
- Persistent saved offset in config

## Exit criteria

- [x] Spec written  
- [ ] package + check  
- [ ] Max: capture on a window edge, drag window, lines ride the border  
- [ ] Max: Meta+Shift+O off restores cursor-centered crosshair  
