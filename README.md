# 🎯 *KWin? K Now!*

# Infinite Crosshair

[![Plasma 6](https://img.shields.io/badge/Plasma-6.0+-blue.svg)](https://kde.org/plasma-desktop)  
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

A **zero-latency**, full-screen crosshair overlay for KDE Plasma. Precise vertical and horizontal lines follow your cursor across monitors and apps — plus optional border guides and imperial/metric ruler ticks. Built for artists, designers, and anyone who needs pixel-perfect alignment.

**GitHub:** [maxugly/infinihair](https://github.com/maxugly/infinihair) · **Plugin id:** `kwin-crosshair`

> **\*AI-developed.** Large parts of this project — design notes, QML/config, packaging scripts, and docs — were written or co-authored with AI assistants (including Grok / other tools in a multi-agent workflow), under human direction and review. That is intentional and disclosed up front: we are not trying to hide it or leave anyone unsure. Humans own product decisions, testing, and what ships.

## ✨ Features

*   **🚀 Zero latency:** Direct `Workspace.cursorPos` binding (no cursor polling).  
*   **🖥️ Multi-monitor:** Spans the virtual desktop (`Workspace.virtualScreenSize`).  
*   **🎨 Primary crosshair:** Color picker, width, opacity via System Settings.  
*   **📐 Offset guides:** Second V/H lines (own color + offset). Auto-align snaps to nearest window frame edges on hover and **stays sticky while you drag**.  
*   **📏 Ruler ticks:** Imperial (inches) or metric (cm) — separate diagonal fields so values never mix.  
*   **⌨️ Shortcuts:** **Meta+Shift+X** toggle · **V/H** guide toggles · **B** capture borders · **C** clear guides.  
*   **🌍 Input-through overlay:** Full-screen surface; clicks pass through to apps underneath.

## 📦 Installation

### Method 1: From this repo (developers)

```bash
git clone https://github.com/maxugly/infinihair.git
cd infinihair   # live path often: ~/.local/share/kwin/scripts/crosshair

./scripts/package.sh
./scripts/check.sh    # packages + kpackagetool6 upgrade when available

kwriteconfig6 --file kwinrc --group Plugins --key kwin-crosshairEnabled true
qdbus6 org.kde.KWin /KWin reconfigure
# After upgrades in a long session, if re-enable looks stale:
#   kwin_wayland --replace
# or: ./scripts/reload.sh
```

### Method 2: Import `.kwinscript`

1.  `./scripts/package.sh` → `crosshair.kwinscript`  
2.  **System Settings** → **Window Management** → **KWin Scripts** → **Import…**  
3.  Enable **Infinite Crosshair** → **Apply**

### Method 3: KDE Store

Search **Infinite Crosshair** under Get New KWin Scripts when published.

## ⚙️ Configuration

1.  **System Settings** → **Window Management** → **KWin Scripts**  
2.  **Infinite Crosshair** → **Configure** (gear)  
3.  Useful groups:  
    *   **Primary** — color, width, opacity  
    *   **Second vertical / horizontal guides** — enable, offset (px), color  
    *   **Auto-align guides to window borders** — hover + drag sticky edges  
    *   **Ruler ticks** — units (imperial/metric), diagonal inches **and** cm (separate), tick length  
4.  **Apply** — live updates while the script is loaded  

### Known limitation (KDE, not this script)

Each **Configure** click can open a **new** dialog (`kcm_kwin_scripts` always `new KCMultiDialog()`). Close extras; prefer one click. Details: [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) and [specs/bug-multi-config-dialog.md](specs/bug-multi-config-dialog.md).

Ruler form always shows **both** diagonal boxes (inches and cm); only the field matching **Units** is used. Switching units does **not** convert or copy values.

## ⌨️ Default shortcuts

| Shortcut | Action |
|---|---|
| **Meta+Shift+X** | Toggle crosshair visibility |
| **Meta+Shift+V** | Toggle second vertical guide |
| **Meta+Shift+H** | Toggle second horizontal guide |
| **Meta+Shift+B** | Capture nearest window border offsets |
| **Meta+Shift+C** | Clear offset guides |

Rebind: **System Settings → Keyboard → Shortcuts** → search *Infinite Crosshair*.

## 🛠️ Development

```bash
./scripts/reload.sh      # force current package body into session (temp path)
./scripts/package.sh     # build crosshair.kwinscript (python3 only)
./scripts/check.sh       # package + optional kpackagetool6 / shellcheck
```

Crew / status: `AGENTS.md`, `STATUS.md`, `specs/`.

**Something broken?** → **[docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)**

## 📜 License

**GPLv3** — see [LICENSE](LICENSE) if present; otherwise GPLv3 as declared in `metadata.json`.

## 🤝 Contributing

Read [constitution.md](constitution.md), [AGENTS.md](AGENTS.md), and [STATUS.md](STATUS.md). Specs before large features; package/check before “done.”

---

**Made with ❤️ for the KDE Community** · *KWin? K Now!* · *\*AI-developed (disclosed)*
