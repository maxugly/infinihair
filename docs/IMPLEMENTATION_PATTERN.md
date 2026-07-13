# The Golden Path: KWin Crosshair Pattern

When implementing features, **mimic this structure exactly**. Do not deviate unless the spec demands it.

## 1. The QML Structure (Standard Template)
Always use this boilerplate for `contents/ui/*.qml`:

```qml
import QtQuick
import org.kde.kwin

Item {
    id: root
    anchors.fill: parent

    // 1. Config Binding (Always at top)
    readonly property color lineColor: KWin.readConfig("LineColor", "#FF0000")
    readonly property int lineWidth: KWin.readConfig("LineWidth", 1)
    readonly property real opacity: KWin.readConfig("Opacity", 0.8)

    // 2. Global Cursor Binding (No Timers!)
    // Plasma 6 QML: capital Workspace (lowercase workspace is JS-only / undefined in QML)
    property point cursorPos: Workspace.cursorPos

    // 3. Surface: bare Item is NOT painted. Use PlasmaCore.Dialog or Window
    //    (see contents/ui/Crosshair.qml). Size with Workspace.virtualScreenSize.

    // 4. Rendering (Direct Primitives)
    Rectangle {
        x: root.cursorPos.x - (root.lineWidth / 2)
        y: 0
        width: root.lineWidth
        height: Workspace.virtualScreenSize.height
        color: root.lineColor
        opacity: root.opacity
        z: 9999
    }
      
    // ... Horizontal line follows same pattern
}
```

## 2. The Config Schema Pattern
Always match `main.xml` keys to `KWin.readConfig` strings exactly:
- XML: `<entry name="LineColor" type="Color">`
- QML: `KWin.readConfig("LineColor", ...)`

## 3. Error Handling Pattern
If a property is missing, **fail gracefully** with a default, do not crash:
```javascript
// Good
var w = KWin.readConfig("LineWidth", 1); 

// Bad (Crashes if missing)
var w = config.LineWidth;   
```
