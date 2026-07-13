# STATUS — infinihair

**Date:** 2026-07-13  
**Repo:** `~/.local/share/kwin/scripts/crosshair/` → https://github.com/maxugly/infinihair  
**Plugin id:** `kwin-crosshair`  
**buildId:** `2026-07-13-offset5`

---

## One-line status

**Product accepted path works:** disable/re-enable, color picker + live apply, primary crosshair on cursor, **secondary V/H border guides with automagic + sticky tracking while dragging.**  
**Known KDE limit:** Configure gear stacks a new dialog every click (upstream `kcm_kwin_scripts`).

---

## Max confirmed / current

| item | result |
|---|---|
| Disable → enable in KWin Scripts | **Works** (Max) |
| Color picker + Apply | **Works** (Max) |
| Primary crosshair while moving windows | **Stays** (cursor-bound; expected) |
| Secondary guides on hover | **Automagic** to nearest frame edges |
| Secondary guides while dragging | **Sticky** (`offset5`) — must not vanish mid-move |
| Multi Configure dialogs | Upstream KWin only |

---

## Offset guides (current model — `offset5`)

### Layers

| layer | behavior |
|---|---|
| **Primary V + H** | Always on **cursor**; primary color / width / opacity / ticks |
| **Second vertical** | Own enable, offset (px), color (default cyan) |
| **Second horizontal** | Own enable, offset (px), color (default green) |

### Automagic (`AutoOffsetOnMove`, default **on**)

1. Hover a normal window → second guides snap to nearest L/R and T/B **frame** edges.  
2. **Drag/resize** → keep following that window via KWin `move`/`resize` flags + move-resize signals + sticky edge coords (cursor can leave the frame).  
3. Leave windows / finish drag → guides hide (auto mode).  

**Why sticky?** Mid-drag hit-testing often loses “window under cursor”; primary never cared (cursor-only). Guides use `guidesSticky` + `stickyEdgeX/Y` so they stay for the whole move.

### Manual mode

Uncheck auto-align → use Configure offsets + Meta+Shift+V/H.  
**Meta+Shift+B** captures edges into spinbox offsets.

### Shortcuts

| shortcut | action |
|---|---|
| **Meta+Shift+X** | Toggle primary crosshair visibility |
| **Meta+Shift+V** | Toggle second vertical (manual mode) |
| **Meta+Shift+H** | Toggle second horizontal (manual mode) |
| **Meta+Shift+B** | Capture border offsets + enable both |
| **Meta+Shift+C** | Clear guides |

Spec: [`specs/offset-line-mode.md`](specs/offset-line-mode.md)

### KWin APIs used for move tracking

- `window.move` / `window.resize` while interactive  
- `interactiveMoveResizeStarted` / `Stepped` / `Finished`  
- live `frameGeometry` (+ rev bumps on step / geometry change)  

Same family of hooks as Mouse Tiler. **Yes, KWin allows tracking moving windows.**

---

## BUG-02 — Multiple Configure dialogs

**Upstream** `Module::configure` always `new KCMultiDialog()`. Not fixable in-package.  
See `specs/bug-multi-config-dialog.md`. Workaround: one gear click.

---

## Process

- Crew: `AGENTS.md` · tasks: `TODO.md` · chat: `~/.hermes/agents/chat.md`  
- Next features: Bones specs before large architecture thrash  
- After package upgrades in a long session: `./scripts/reload.sh` or restart KWin once if Settings re-enable looks stale  
