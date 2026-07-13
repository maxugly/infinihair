# Skill: KWin Researcher

**Purpose:** Investigate KWin Scripting **lifecycle, config, and QML load** before writing more product QML.  
**Used by:** Bones (plan), Grit (verify claims), Grok (only when tasked with instrumentation).  
**Not:** A free pass to ship features.

## Mindset

1. **Peers are the control group.** If mousetiler survives disable/re-enable and we do not, the bug is in *our surface*, not “KWin is broken.”
2. **Journal is ground truth** for which body ran (`InfiniteCrosshair ready build=`).
3. **Disk is ground truth** for what Configure saved (`kwinrc` `[Script-<Id>]`).
4. **`isScriptLoaded` is ground truth** for whether any body is running.
5. Prefer **one variable per experiment**. Do not change color schema and Window flags in the same step.

## Tools (local)

```bash
# Load state
qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.isScriptLoaded kwin-crosshair
qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.unloadScript kwin-crosshair
# (prefer System Settings or kwriteconfig + reconfigure for enable paths)

# Config on disk
grep -A30 '\[Script-kwin-crosshair\]' ~/.config/kwinrc
kreadconfig6 --file kwinrc --group Script-kwin-crosshair --key LineColor

# Plugin enabled flag
kreadconfig6 --file kwinrc --group Plugins --key kwin-crosshairEnabled

# Body identity
journalctl --user -b --no-pager | rg 'InfiniteCrosshair' | tail -50

# Package vs dev
ls -la ~/.local/share/kwin/scripts/kwin-crosshair/contents/ui/
ls -la ~/.local/share/kwin/scripts/crosshair/contents/ui/

# QML disk cache (does not clear in-memory kwin body)
ls ~/.cache/kwin/qmlcache/ | head
python3 -c "import hashlib; print(hashlib.sha1(b'/home/m/.local/share/kwin/scripts/kwin-crosshair/contents/ui/main.qml').hexdigest())"
```

## Known footguns (infinihair)

| footgun | detail |
|---|---|
| Temp reload vs Settings re-enable | `reload.sh` uses unique temp QML path; Settings uses package path. Different bodies. |
| Session-stale package QML | Long-lived `kwin_wayland` may re-enable an old compiled body until KWin restart. |
| Full-screen `Window` | Peers often do not use this; our paint path is special. |
| Config poll | Live apply depends on executable DataSource + python; peers may not. |
| Color KCM | `type=Color` + `KColorButton` under genericscripted has history of flaky load; do not thrash UI without disk+journal proof. |

## Research deliverable

Fill `specs/research-kwin-lifecycle.md` decision log: hypothesis, evidence, decision A/B/C, tasks for Grok.

## What not to do

- Do not “fix” by rewriting color storage again without E1–E3 data.
- Do not mark phase complete based only on `package.sh` exit 0.
- Do not restart KWin as a silent dependency of every Apply (document if required).
