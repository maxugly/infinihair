# 🎯 *KWin? K Now!*

# Infinite Crosshair

[![Plasma 6](https://img.shields.io/badge/Plasma-6.0+-blue.svg)](https://kde.org/plasma-desktop)  
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

A **zero-latency**, full-screen crosshair overlay for KDE Plasma. Renders precise vertical and horizontal lines that follow your cursor across all monitors and applications. Perfect for digital artists, designers, and gamers who need pixel-perfect alignment.

![Demo](https://via.placeholder.com/800x450/1a1a1a/FFFFFF.png?text=Crosshair+Demo+Screenshot)  
*(Screenshot: Red crosshair overlay spanning multiple monitors in Krita)*

## ✨ Features

*   **🚀 Zero Latency:** Native KWin compositor integration — direct `Workspace.cursorPos` binding (no cursor polling).  
*   **🖥️ Multi-Monitor Ready:** Lines span the virtual desktop (`Workspace.virtualScreenSize`).  
*   **🎨 Fully Customizable:** Color (picker), thickness, opacity, inch ticks / PPI via System Settings.  
*   **⌨️ Shortcuts:** **Meta+Shift+X** toggle · **Meta+Shift+V/H** second V/H guides · **Meta+Shift+B** capture border offsets · **Meta+Shift+C** clear guides.  
*   **📐 Offset guides:** Extra V/H lines (own color + offset). With auto-align (default on), they snap to the nearest window frame edges on hover and **stay sticky while you drag** the window; primary crosshair stays on the cursor.  
*   **🌍 Global Overlay:** Full-screen transparent window above other surfaces; input-through so clicks pass through.  
*   **⚡ Lightweight:** Simple `Rectangle` scene-graph primitives.

## 📦 Installation

**GitHub:** [maxugly/infinihair](https://github.com/maxugly/infinihair)  
**Plugin id:** `kwin-crosshair`

### Method 1: From this repo (developers)

```bash
git clone https://github.com/maxugly/infinihair.git
cd infinihair   # or: ~/.local/share/kwin/scripts/crosshair

./scripts/package.sh
./scripts/check.sh    # packages + kpackagetool6 upgrade when available

# Enable
kwriteconfig6 --file kwinrc --group Plugins --key kwin-crosshairEnabled true
qdbus6 org.kde.KWin /KWin reconfigure
# After package upgrades in a long session, restart KWin once if re-enable looks stale:
#   kwin_wayland --replace
```

### Method 2: Import `.kwinscript`

1.  Build with `./scripts/package.sh` (artifact: `crosshair.kwinscript`).  
2.  **System Settings** → **Window Management** → **KWin Scripts** → **Import KWin script…**  
3.  Enable **Infinite Crosshair** → **Apply**.

### Method 3: KDE Store

Search **Infinite Crosshair** under Get New KWin Scripts when published.

## ⚙️ Configuration

1.  **System Settings** → **Window Management** → **KWin Scripts**.  
2.  **Infinite Crosshair** → **Configure** (gear).  
3.  Typical options:  
    *   **Line color** — color button (default red)  
    *   **Line width** — pixels  
    *   **Opacity** — 0.05–1.0  
    *   **Inch ticks** / diagonal / tick length — optional ruler marks  
4.  **Apply**. Live updates are picked up from `kwinrc` while the script is running.

### Known limitation (KDE, not this script)

Each press of **Configure** on any KWin script can open a **new** dialog window (KWin Scripts KCM always `new KCMultiDialog()`). Close extras manually; prefer one click. See `specs/bug-multi-config-dialog.md`.

## 🛠️ Development & Testing

### Quick Reload
During development, use the provided script to reload changes without restarting Plasma:  
```bash
./scripts/reload.sh
```

### Packaging
Distro-agnostic: only **`python3`** on `PATH` (no apt/pacman).  
```bash
./scripts/package.sh
# Output: crosshair.kwinscript

# Optional fuller gate (uses shellcheck / kpackagetool6 if installed):
./scripts/check.sh
```

### Debugging
Monitor KWin logs for errors:  
```bash
journalctl --user -u plasma-kwin_wayland.service -f
# Or for X11:
journalctl --user -u plasma-kwin_x11.service -f
```

## ❓ Troubleshooting

| Issue | Solution |
|-------|----------|
| **Lines not visible** | Enable the script in System Settings. Check journal for `InfiniteCrosshair ready build=`. |
| **Settings / color do nothing** | Confirm `qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.isScriptLoaded kwin-crosshair` is `true`. Apply only writes `kwinrc` if the script is loaded. |
| **Works after reload.sh, broken after disable/re-enable** | Long session may keep a stale package-path QML body. Run `./scripts/reload.sh` or restart KWin once after upgrades. |
| **Many Configure windows** | Upstream KWin Scripts KCM (all scripts). Close extras; one gear click. |
| **Toggle not working** | Default **Meta+Shift+X**. Rebind: System Settings → Keyboard → Shortcuts → search *Infinite Crosshair*. |
| **Offset guides wrong / vanish on drag** | Keep **Auto-align guides to window borders** checked. Hover a window, then drag — guides should stick for the whole move (`offset5`). Manual: **Meta+Shift+B** / V/H; **Meta+Shift+C** clears. |
| **Guides gone but main crosshair stays** | Expected if auto lost the target window; mid-drag that was a bug — update to build `offset5`+. |
| **Lag or stutter** | Must use native declarative script (this package). No cursor `Timer` polling. Check `journalctl` for QML errors. |

```bash
# Useful logs
journalctl --user -b --no-pager | rg InfiniteCrosshair | tail -40
grep -A20 '\[Script-kwin-crosshair\]' ~/.config/kwinrc
```

## 📜 License

This project is licensed under the **GPLv3 License**. See the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please read our [Constitution](constitution.md) and [Spec](spec.md) before submitting PRs.

1.  Fork the repository.  
2.  Create a feature branch (`git checkout -b feature/amazing-feature`).  
3.  Commit your changes (`git commit -m 'Add amazing feature'`).  
4.  Push to the branch (`git push origin feature/amazing-feature`).  
5.  Open a Pull Request.

## 🙏 Acknowledgments

*   Inspired by the need for precision tools in Krita and digital art workflows.  
*   Built upon the excellent [KWin Scripting API](https://develop.kde.org/docs/plasma/kwin/).  
*   Thanks to the KDE Community for maintaining such a powerful compositor.

---

**Made with ❤️ for the KDE Community**
