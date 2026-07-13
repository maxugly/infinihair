# STATUS — infinihair

**Date:** 2026-07-13  
**Mode:** **PAUSE product feature work — KWin lifecycle research**  
**Repo:** `~/.local/share/kwin/scripts/crosshair/` → https://github.com/maxugly/infinihair  
**Plugin id:** `kwin-crosshair`  
**Last code buildId:** `2026-07-13-reen1`

---

## One-line status

Color picker UI is back, but **Max reports Configure controls do nothing**. Other KWin scripts on this machine (e.g. Mouse Tiler) **disable/re-enable fine**. We stop freelancing QML patches and research **how KWin loads our script vs theirs**.

---

## What Max sees (accepted as ground truth)

| observation | notes |
|---|---|
| Color picker is back | `KColorButton` / `kcfg_LineColor` restored in reen1 |
| **Nothing does anything** | Changing color / settings does not affect the overlay (or overlay dead) |
| Meta+Shift+X was never the core bug | Toggle worked; **Settings disable→re-enable** was the painful cycle |
| Other extensions re-enable fine | Control: mousetiler, rememberwindowpositions on same host |

---

## What we know (evidence, not guesses)

### Architecture of *our* script (unusual vs peers)

| ours | working peers (mousetiler / rememberwindowpositions) |
|---|---|
| Full-screen `Qt.Window` overlay, `WindowTransparentForInput`, skip* flags | Window logic / menus — **not** a persistent full-screen paint surface |
| Live config via `P5.DataSource` + **python3** + `kreadconfig6` every 500ms | Typical `KWin.readConfig` / script-local patterns |
| Color mirrored as `LineColor` + `LineColorR/G/B` | Standard kcfg widgets |
| `reload.sh` loads a **temp** `.qml` path to bust cache | Normal package path only |

Peers use the **same** metadata shape (`declarativescript`, `ui/main.qml`, `kcm_kwin4_genericscripted`). Difference is **implementation surface**, not KPackage metadata.

### Session / load path (proven earlier this session)

1. System Settings enable loads **package path**  
   `~/.local/share/kwin/scripts/kwin-crosshair/contents/ui/main.qml`
2. `kwin_wayland` can keep a **session-stale in-memory QML body** for that URL.
3. `./scripts/reload.sh` loads a **unique temp path** → looks fixed until Settings re-enable revives the package-path body.
4. After `kwin_wayland --replace`, package path ran `buildId=reen1` and disable/re-enable still logged correct seed/poll **in journal**.
5. That does **not** contradict Max: UI can still feel dead (wrong body, unloaded script, overlay not painting, poll not applying, input-eaten window, etc.).

### Snapshot mid-pause (this machine)

```
qdbus6 … isScriptLoaded kwin-crosshair  → false   # may be disabled by Max
qdbus6 … isScriptLoaded mousetiler      → true
```

If the script is **unloaded**, Configure Apply writes `kwinrc` but **nothing runs** to paint or poll — “nothing does anything” is expected until the script is enabled **and** a live body is loaded.

`kwinrc` group `[Script-kwin-crosshair]` still holds keys (`LineColor`, RGB mirrors, LineWidth, Opacity, ticks).

### Configure multi-dialog

Host KCM opens a new `KCMultiDialog` per Configure click. **wontfix inside pure script package.** Document only.

---

## What we do **not** know (research questions)

1. After Max enables the script in System Settings, does journal show `ready build= 2026-07-13-reen1` or an old body / nothing?
2. Does Apply change `~/.config/kwinrc` `[Script-kwin-crosshair]` while the dialog is open?
3. If keys change on disk, does a running reen1 body log `LineColor … ->` / poll updates?
4. Is a full-screen transparent `Window` left mapped after disable, eating input or blocking “settings work”?
5. Why do **Window-less / menu-based** scripts survive re-enable while our overlay pattern does not *feel* alive?
6. Is `KWin.readConfig` after re-enable empty for Color while disk has values? (poller was meant to paper over this.)
7. Does genericscripted KCM bind `KColorButton` correctly when `main.xml` has `type=Color` but group name is `""`?

---

## Freeze rules (crew)

**Until research has a written decision in `specs/research-kwin-lifecycle.md`:**

- **No** more product QML “quick fixes” (color, toggle, poll, Window flags) without Bones plan + Max go-ahead.
- **No** more RGB spinbox / Color thrash.
- Grok may only: docs, research notes, package/check, instrumentation **if** a research task says so.
- Grit reviews research instrumentation and any future fix PR.
- Bones owns research plan + architecture choice after findings.

---

## Crew workflow (use this)

| step | who | action |
|---|---|---|
| 1 | **Bones** | Own `specs/research-kwin-lifecycle.md` — questions, experiments, success criteria |
| 2 | **Max** | Run checklist below; paste journal / kwinrc / yes-no answers into chat |
| 3 | **Grok** | Only implement **instrumentation** or **minimal repro** listed in the research spec |
| 4 | **Grit** | QA any instrumentation PR; no feature PASS until lifecycle understood |
| 5 | **Bones** | Decision: fix in script vs KWin limitation vs redesign paint path |

Optional: skill `skills/KWIN_RESEARCHER.md` — how to think about KWin Scripting load/unload (not a fourth personality; Bones/Grit use it).

Chat: `~/.hermes/agents/chat.md`

---

## Max checklist (when you have a minute)

Please enable the script, try one Configure Apply, then collect:

```bash
# 1) loaded?
qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.isScriptLoaded kwin-crosshair

# 2) disk config
kreadconfig6 --file kwinrc --group Script-kwin-crosshair --key LineColor
kreadconfig6 --file kwinrc --group Script-kwin-crosshair --key LineWidth
grep -A20 '\[Script-kwin-crosshair\]' ~/.config/kwinrc

# 3) what body ran (after enable / Apply / re-enable)
journalctl --user -b --no-pager | rg 'InfiniteCrosshair' | tail -40
```

Also note: **Do you see the crosshair lines at all?** (yes/no)  
After Apply, **does kwinrc LineColor change?** (yes/no)

---

## Tree map

```
crosshair/   # github maxugly/infinihair
├── STATUS.md              ← you are here
├── AGENTS.md              # crew
├── TODO.md                # pause + research tasks
├── specs/research-kwin-lifecycle.md
├── skills/KWIN_RESEARCHER.md
├── contents/ui/main.qml   # reen1 (frozen for feature work)
├── contents/ui/config.ui  # KColorButton restored
└── scripts/{package,check,reload}.sh
```

## Last intentional code state (reen1)

- `KColorButton` + `LineColor` type Color  
- Disk mirror `LineColorR/G/B` (not in UI)  
- Window always mapped; draw items gated by shortcut toggle  
- Config poll every 500ms via executable engine  

**Product verdict on reen1:** UI restored; **behavior not accepted by Max**. Research before more code.
