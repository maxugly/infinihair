import QtQuick
import org.kde.kwin

// Root item represents the full screen overlay
Item {
    id: root
    anchors.fill: parent

    // Access global workspace cursor position
    property point cursorPos: workspace.cursorPos

    // Vertical Line
    Rectangle {
        x: root.cursorPos.x - 0.5 // Center on pixel
        y: 0
        width: 1
        height: parent.height
        color: "#FF0000" // Red
        opacity: 0.8
        z: 9999 // Ensure top-most rendering
    }

    // Horizontal Line
    Rectangle {
        x: 0
        y: root.cursorPos.y - 0.5 // Center on pixel
        width: parent.width
        height: 1
        color: "#FF0000" // Red
        opacity: 0.8
        z: 9999
    }

    // Optimization: Only repaint when cursor moves significantly or on timer
    // KWin declarative scripts automatically bind to property changes
    Connections {
        target: workspace
        function onCursorPosChanged() {
            // Trigger update implicitly via property binding
            root.cursorPos = workspace.cursorPos;
        }
    }
}
