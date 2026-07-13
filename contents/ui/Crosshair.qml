import QtQuick
import org.kde.kwin

// Phase 1: hardcoded red crosshair — direct cursor binding, no config, no timers.
Item {
    id: root
    anchors.fill: parent

    // Direct binding only (workspace.cursorPosChanged is implicit)
    property point cursorPos: workspace.cursorPos

    // Vertical line — full virtual desktop height
    Rectangle {
        x: root.cursorPos.x - 0.5
        y: 0
        width: 1
        height: workspace.workspaceHeight
        color: "#FF0000"
        opacity: 0.8
        z: 9999
    }

    // Horizontal line — full virtual desktop width
    Rectangle {
        x: 0
        y: root.cursorPos.y - 0.5
        width: workspace.workspaceWidth
        height: 1
        color: "#FF0000"
        opacity: 0.8
        z: 9999
    }
}
