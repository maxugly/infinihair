# Technical Specification: KWin Infinite Crosshair

**Version:** 1.0.0  
**Date:** July 13, 2026  
**Status:** Draft  
**Target Platform:** KDE Plasma 6 (Wayland & X11)

## 1. Project Overview
**Objective:** Develop a KWin Script that renders a full-screen, dynamic crosshair (vertical and horizontal lines) centered on the global mouse cursor.  
**Primary Goal:** Achieve **zero-perceptible latency** ("buttery smooth") performance, indistinguishable from native C++ rendering.  
**Scope:** Global desktop overlay; functions identically across all applications (Krita, browsers, games) and multi-monitor setups.

## 2. System Architecture

### 2.1. Technology Stack
*   **Runtime:** KWin Compositor (Plasma 6).
*   **API:** KWin Declarative Script (`declarativescript`).
*   **Language:** QML (QtQuick) for rendering; JavaScript (ECMAScript 6) for lifecycle logic.
*   **Configuration:** KConfigXT (`main.xml` + `main.ui`).
*   **Packaging:** KPackage (`.kwinscript` format).

### 2.2. Component Diagram
```text
[User Input: Mouse Move]   
       ↓  
[KWin Compositor] → Emits `workspace.cursorPosChanged`  
       ↓  
[Crosshair.qml] → Binds to `workspace.cursorPos`  
       ↓  
[QtQuick Scene Graph] → Renders two `Rectangle` items  
       ↓  
[Compositor Surface] → Draws lines above all windows (Z-Index 9999)  
```

## 3. Functional Requirements

### 3.1. Core Functionality
| ID | Requirement | Priority |
|----|-------------|----------|
| **FR-01** | **Dynamic Tracking:** The crosshair must update position immediately upon mouse movement. | **Critical** |
| **FR-02** | **Infinite Lines:** Lines must span the entire **virtual desktop geometry** (handling multi-monitor setups where coordinates exceed single screen bounds). | **Critical** |
| **FR-03** | **Global Overlay:** The crosshair must render above all windows, including full-screen applications and pop-up menus. | **Critical** |
| **FR-04** | **Zero Latency:** Input lag must be <1 frame (16ms at 60Hz). No polling loops allowed. | **Critical** |

### 3.2. Configuration
| ID | Requirement | Default Value | Type |
|----|-------------|---------------|------|
| **FR-05** | **Line Color:** User can select any RGB color. | `#FF0000` (Red) | `Color` |
| **FR-06** | **Line Width:** User can set thickness in pixels. | `1` | `Int` |
| **FR-07** | **Opacity:** User can set transparency (0.0–1.0). | `0.8` | `Double` |

### 3.3. Formal Requirements (RFC 2119)

#### 3.3.1. Rendering Latency
- **REQ-LAT-01**: The system **SHALL** update the crosshair position within 16.6ms (1 frame at 60Hz) of a `workspace.cursorPosChanged` event.
- **REQ-LAT-02**: The system **MUST NOT** utilize polling mechanisms (e.g., `Timer`, `setInterval`) for position updates.
- **REQ-LAT-03**: If frame time exceeds 16.6ms, the system **SHALL** drop the frame rather than interpolate position (to prevent "laggy" feel).

#### 3.3.2. Coordinate Geometry
- **REQ-GEO-01**: The vertical line **SHALL** be rendered at `x = workspace.cursorPos.x`.
- **REQ-GEO-02**: The vertical line **SHALL** span from `y = 0` to `y = workspace.workspaceHeight`.
- **REQ-GEO-03**: In a multi-monitor setup where `workspace.cursorPos.x` > `Screen[0].width`, the line **SHALL** render at the global X coordinate, visually crossing monitor boundaries without interruption.

#### 3.3.3. Prohibited Patterns
- **PROH-01**: The use of Python scripts for rendering **IS PROHIBITED**.
- **PROH-02**: The use of `Behavior` or `NumberAnimation` QML elements on position properties **IS PROHIBITED**.

## 4. Technical Specifications

### 4.1. Directory Structure (KPackage)
The project must strictly adhere to the KWin Script specification:
```text
kwin-crosshair/
├── metadata.json            # Plugin identity & API declaration
├── contents/
│   ├── config/
│   │   ├── main.xml         # KConfigXT schema
│   │   └── main.ui          # Qt Widgets configuration UI
│   ├── ui/
│   │   └── Crosshair.qml    # Main rendering component
│   └── code/
│       └── main.js          # (Optional) Lifecycle logic
├── scripts/
│   ├── reload.sh            # Dev reload utility
│   └── package.sh           # Build .kwinscript artifact
├── constitution.md          # Project principles
├── agents.md                # AI agent context (root)
└── spec.md                  # This file
```

### 4.2. `metadata.json` Schema
```json
{
    "KPlugin": {
        "Name": "Infinite Crosshair",
        "Description": "High-performance global crosshair overlay.",
        "Id": "kwin-crosshair",
        "Version": "1.0.0",
        "License": "GPLv3",
        "EnabledByDefault": false
    },
    "X-Plasma-API": "declarativescript",
    "X-Plasma-MainScript": "ui/Crosshair.qml",
    "X-KDE-ConfigModule": "kwin/effects/configs/kcm_kwin4_genericscripted",
    "KPackageStructure": "KWin/Script"
}
```

### 4.3. QML Rendering Logic (`Crosshair.qml`)
*   **Imports:** `import QtQuick`, `import org.kde.kwin`.
*   **Root Item:** Anchored to `parent` (full screen).
*   **Data Binding:**
    ```qml
    property point cursorPos: workspace.cursorPos
    ```
*   **Drawing Primitives:** Two `Rectangle` items.
    *   **Vertical:** `x = cursorPos.x`, `width = config.LineWidth`, `height = workspace.workspaceHeight`.
    *   **Horizontal:** `y = cursorPos.y`, `height = config.LineWidth`, `width = workspace.workspaceWidth`.
*   **Optimization:** No `Behavior` or `NumberAnimation` on `x`/`y` properties. Direct binding only.
*   **Z-Order:** `z: 9999` to ensure top-most stacking.

### 4.4. Configuration Schema (`main.xml`)
```xml
<kcfg xmlns="http://www.kde.org/standards/kcfg/1.0">
    <group name="General">
        <entry name="LineColor" type="Color"><default>#FF0000</default></entry>
        <entry name="LineWidth" type="Int"><default>1</default></entry>
        <entry name="Opacity" type="Double"><default>0.8</default></entry>
    </group>
</kcfg>
```

## 5. Non-Functional Requirements

### 5.1. Performance
*   **NFR-01:** The script must not reduce the compositor's frame rate below the display's refresh rate (e.g., 60fps, 144fps).
*   **NFR-02:** Memory footprint must remain under 10MB.
*   **NFR-03:** CPU usage must be negligible (<1% on idle mouse, <2% during movement).

### 5.2. Compatibility
*   **NFR-04:** Must function correctly on **Wayland** and **X11** sessions.
*   **NFR-05:** Must handle dynamic screen changes (monitor plug/unplug) without crashing.
*   **NFR-06:** Must support virtual desktop resolutions exceeding 8000px (multi-monitor).

## 6. Development Workflow

### 6.1. Build & Test
1.  **Install:** `kpackagetool6 --type=KWin/Script --install .`
2.  **Enable:** `kwriteconfig6 --file kwinrc --group Plugins --key kwin-crosshairEnabled true && qdbus6 org.kde.KWin /KWin reconfigure`
3.  **Reload:** Execute `./scripts/reload.sh` during development.
4.  **Debug:** Monitor `journalctl --user -u plasma-kwin_wayland.service -f`.

### 6.2. Distribution
*   **Artifact:** `crosshair.kwinscript` (ZIP archive of the project directory).
*   **Installation:** Users install via "Get New KWin Scripts" in System Settings or by double-clicking the file.

## 7. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| **QML Latency** | High | Use direct property binding; avoid JavaScript intermediaries for position updates. |
| **Multi-Monitor Drift** | Medium | Use `workspace.workspaceWidth/Height` instead of `Screen.width/height`. |
| **Plasma API Changes** | Medium | Stick to stable `workspace` API; avoid internal/private KWin symbols. |
| **Wayland Restrictions** | Low | KWin Scripts run in the compositor, bypassing Wayland client restrictions. |

## 8. Acceptance Criteria
1.  [ ] Lines follow cursor with no visible lag.
2.  [ ] Lines span across all monitors seamlessly.
3.  [ ] Configuration UI allows changing Color, Width, and Opacity.
4.  [ ] Script loads/unloads without crashing KWin.
5.  [ ] Code passes `constitution.md` compliance check.

---

**Approvals:**  
*Architect:* [Your Name]  
*Date:* July 13, 2026
