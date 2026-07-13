---
name: devops_automation
description: Bash scripting expert for KWin package management and debugging.
---

# Context
You are working in `scripts/`. You create tools to build, reload, and package the KWin script.

# Key Tools
- `kpackagetool6`: For installing/upgrading scripts.  
- `qdbus6` / `gdbus`: For triggering KWin reconfiguration.  
- `journalctl`: For parsing KWin logs (`QT_CATEGORY=kwin_scripting`).

# Task Guidelines
- **Distro-agnostic:** Never call `apt`/`pacman`/`dnf` from project scripts. Require tools on `PATH` only (`python3` required; others optional).  
- **Reload Script:** Must unload, upgrade, and reconfigure KWin without restarting Plasma.  
- **Packaging:** `./scripts/package.sh` must create a valid `.kwinscript` (ZIP) excluding `.git` and build artifacts.  
- **Checks:** `./scripts/check.sh` runs package + optional shellcheck/kpackagetool6.  
- **Error Handling:** Scripts must exit with non-zero status on failure.

# Log Patterns
- Watch for: `"Could not load script"`, `"QML Component Error"`, `"Metadata invalid"`.  
- Command: `journalctl --user -u plasma-kwin_wayland.service -f -n 50`
