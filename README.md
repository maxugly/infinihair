# 🎯 KWin Infinite Crosshair

[![Plasma 6](https://img.shields.io/badge/Plasma-6.0+-blue.svg)](https://kde.org/plasma-desktop)  
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

A **zero-latency**, full-screen crosshair overlay for KDE Plasma. Renders precise vertical and horizontal lines that follow your cursor across all monitors and applications. Perfect for digital artists, designers, and gamers who need pixel-perfect alignment.

![Demo](https://via.placeholder.com/800x450/1a1a1a/FFFFFF.png?text=Crosshair+Demo+Screenshot)  
*(Screenshot: Red crosshair overlay spanning multiple monitors in Krita)*

## ✨ Features

*   **🚀 Zero Latency:** Native KWin compositor integration ensures buttery-smooth 60fps+ tracking.  
*   **🖥️ Multi-Monitor Ready:** Lines span the entire virtual desktop geometry, seamlessly crossing screen boundaries.  
*   **🎨 Fully Customizable:** Configure color, thickness, and opacity via System Settings.  
*   **🌍 Global Overlay:** Works above all windows, including full-screen applications and games.  
*   **⚡ Lightweight:** Negligible CPU/GPU usage (<1% load).

## 📦 Installation

### Method 1: KDE Store (Recommended)
1.  Open **System Settings** > **Window Management** > **KWin Scripts**.  
2.  Click **Get New KWin Scripts...**  
3.  Search for **"Infinite Crosshair"**.  
4.  Click **Install**, then check the box to enable it.  
5.  Click **Apply**.

### Method 2: Manual Installation (`.kwinscript`)
1.  Download the latest `crosshair.kwinscript` file from the [Releases](https://github.com/yourusername/kwin-crosshair/releases) page.  
2.  Open **System Settings** > **Window Management** > **KWin Scripts**.  
3.  Click **Import KWin script...** (top-right corner).  
4.  Select the downloaded `.kwinscript` file.  
5.  Enable the script and click **Apply**.

### Method 3: From Source (Developers)
```bash
# Clone the repository
git clone https://github.com/yourusername/kwin-crosshair.git
cd kwin-crosshair

# Install via kpackagetool6
kpackagetool6 --type=KWin/Script --install .

# Enable the script
kwriteconfig6 --file kwinrc --group Plugins --key kwin-crosshairEnabled true
qdbus6 org.kde.KWin /KWin reconfigure
```

## ⚙️ Configuration

Once enabled, customize the crosshair to your liking:

1.  Go to **System Settings** > **Window Management** > **KWin Scripts**.  
2.  Select **Infinite Crosshair** and click the **Configure (⚙️)** button.  
3.  Adjust the following settings:  
    *   **Line Color:** Choose any RGB color (Default: `#FF0000` Red).  
    *   **Line Width:** Set thickness in pixels (Default: `1px`).  
    *   **Opacity:** Adjust transparency from 0.0 to 1.0 (Default: `0.8`).  
4.  Click **Apply**. Changes take effect immediately.

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
| **Lines not visible** | Ensure the script is enabled in System Settings. Check if `z-index` is overridden by another full-screen app. |
| **Lag or stutter** | Verify you are using the native KWin script (not a Python alternative). Check `journalctl` for QML errors. |
| **Lines don't span all monitors** | Ensure you are using the latest version which supports virtual desktop geometry. |
| **Config button missing** | Run: `mkdir -p ~/.local/share/kservices5/ && ln -s ~/.local/share/kwin/scripts/kwin-crosshair/metadata.json ~/.local/share/kservices5/kwin-crosshair.desktop` |
| **Script crashes KWin** | Disable the script via TTY (`kwriteconfig6 ... --key kwin-crosshairEnabled false`) and check logs for QML syntax errors. |

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
