# Research — KWin script lifecycle & config apply (infinihair)

**Status:** OPEN — product freeze until decision  
**Owner:** Bones (Architect)  
**Operators:** Max (live checks), Grok (instrumentation only if tasked), Grit (QA)  
**Skill:** `skills/KWIN_RESEARCHER.md`  
**Related STATUS:** `../STATUS.md`

## Problem statement

Max reports:

1. Configure UI (including restored color picker) **does not change** the crosshair.
2. **Disable → re-enable** in System Settings → KWin Scripts is unreliable for *this* script.
3. **Other KWin scripts** on the same machine re-enable and work fine.

Therefore the issue is likely **interaction between our overlay architecture and KWin’s load/unload/config path**, not “KWin scripts are generally broken.”

## Goals

1. Explain why Configure Apply appears to do nothing (disk? script unloaded? body dead? paint path?).
2. Explain disable/re-enable differences vs mousetiler / rememberwindowpositions.
3. Produce a **single architectural decision** for the next implementation phase (or “wontfix / redesign”).

## Non-goals (until research closes)

- New visual features (ticks polish, shortcuts UI, etc.)
- Another Color vs RGB UI flip-flop
- Fixing multi-Configure dialogs (host KCM; documented wontfix-package)

## Hypotheses (rank after data)

| id | hypothesis | how to falsify |
|---|---|---|
| H1 | Script **not loaded** when Max tests Apply | `isScriptLoaded` false |
| H2 | Apply **does not write** `Script-kwin-crosshair` keys | kwinrc unchanged after Apply |
| H3 | Apply writes disk; **running body does not re-read** | kwinrc changes; no poll/seed log |
| H4 | Running body is **stale/wrong QML** | journal lacks `build= reen1` |
| H5 | Body runs; color property updates; **lines not visible** (geometry/z/color) | logs show LineColor change; no visible lines |
| H6 | Full-screen `Window` after re-enable **steals input / confuses “control”** | clicks fail only when script enabled |
| H7 | Overlay pattern needs **different lifecycle** than menu scripts | peers work; only Window overlay fails under same enable path |

## Experiments (Bones prioritizes; Max runs where marked)

### E1 — Loaded or not (Max)

1. System Settings → enable Infinite Crosshair.  
2. `qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.isScriptLoaded kwin-crosshair`  
3. `journalctl --user -b | rg InfiniteCrosshair | tail -20`  
**Pass criteria:** loaded true + `ready build=` line present.

### E2 — Apply writes disk (Max)

1. With Configure open, change Line color and Line width; Apply.  
2. `grep -A20 '\[Script-kwin-crosshair\]' ~/.config/kwinrc`  
**Pass criteria:** keys change to chosen values.

### E3 — Running body reacts (Max + journal)

1. Script enabled; Apply a dramatic color (e.g. pure green).  
2. Journal for `LineColor` / `config poll` within 2s.  
**Pass criteria:** log shows new RGB; lines green.

### E4 — Peer comparison (Max)

1. Disable/re-enable **Mouse Tiler**; confirm still works.  
2. Disable/re-enable **Infinite Crosshair**; repeat E1–E3.  
**Note differences only.**

### E5 — Package path vs temp path (Grok if tasked)

1. `./scripts/reload.sh` → journal buildId.  
2. Settings disable/re-enable → journal buildId.  
3. Document whether package path drops to old body (known prior finding).

### E6 — KWin source / docs (Bones)

- How `kcm_kwin_scripts` enables scripts (path, unloadScript, start).  
- Whether declarative scripts share QQmlEngine cache across unload.  
- How genericscripted KCM maps `kcfg_*` → `kwinrc` group `Script-<Id>`.  
- Compare to mousetiler: no full-screen Window.

## Success criteria for closing research

Written in this file:

1. Root cause class: **H1–H7** (or new Hn) with evidence.  
2. Decision:  
   - **A)** Fix in-script lifecycle/config only  
   - **B)** Redesign paint path (closer to peer patterns / effect)  
   - **C)** Document KWin limitation + workaround (reload/restart)  
3. Ordered implementation tasks for Grok (if A/B).  
4. Grit gate list for the fix PR.

## Decision log

| date | note |
|---|---|
| 2026-07-13 | Freeze declared. reen1 on disk. Max: picker visible, controls dead. Research opened. |
