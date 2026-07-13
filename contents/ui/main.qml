import QtQuick
import QtQuick.Window
import org.kde.kwin
import org.kde.plasma.plasma5support as P5

// KWin declarativescript entry (X-Plasma-MainScript → ui/main.qml).
// Proven pattern: real Window + Workspace (capital W). Bare Item never paints.
Window {
    id: root

    visible: true
    color: "transparent"
    flags: Qt.BypassWindowManagerHint
         | Qt.FramelessWindowHint
         | Qt.WindowStaysOnTopHint
         | Qt.WindowDoesNotAcceptFocus
         | Qt.WindowTransparentForInput

    x: 0
    y: 0
    width: Workspace.virtualScreenSize.width
    height: Workspace.virtualScreenSize.height

    // Must match metadata.json KPlugin.Id → [Script-<Id>] in kwinrc
    readonly property string configSection: "Script-kwin-crosshair"
    readonly property string pluginId: "kwin-crosshair"

    // --- Live config (mutable; seeded on start, refreshed from disk) ---
    property color lineColor: "#FF0000"
    property int lineWidth: 1
    property real lineOpacity: 0.8
    property bool showInchTicks: true
    property real screenDiagonalInches: 27.0
    property int tickLength: 10
    property bool showHalfInchTicks: true

    // Tick stroke stays 1px — only the infinite lines use LineWidth.
    readonly property int tickStroke: 1

    /*
     * KWin.readConfig() is correct at script *start*, but the script KCM
     * writes ~/.config/kwinrc on Apply without refreshing KWin's in-memory
     * KConfig snapshot — so later readConfig() looks "stuck".
     *
     * Live path: kreadconfig6 against kwinrc (always fresh from disk).
     * Seed path: KWin.readConfig onCompleted (works even if DataSource fails).
     */
    readonly property string configReadCmd:
        "kreadconfig6 --file kwinrc --group " + configSection + " --key LineColor --default '#FF0000'; echo; "
        + "kreadconfig6 --file kwinrc --group " + configSection + " --key LineWidth --default 1; echo; "
        + "kreadconfig6 --file kwinrc --group " + configSection + " --key Opacity --default 0.8; echo; "
        + "kreadconfig6 --file kwinrc --group " + configSection + " --key ShowInchTicks --default true; echo; "
        + "kreadconfig6 --file kwinrc --group " + configSection + " --key ScreenDiagonalInches --default 27.0; echo; "
        + "kreadconfig6 --file kwinrc --group " + configSection + " --key TickLength --default 10; echo; "
        + "kreadconfig6 --file kwinrc --group " + configSection + " --key ShowHalfInchTicks --default true; echo"

    function parseBool(v, fallback) {
        if (v === undefined || v === null || v === "")
            return fallback;
        const s = String(v).trim().toLowerCase();
        if (s === "true" || s === "1" || s === "on" || s === "yes")
            return true;
        if (s === "false" || s === "0" || s === "off" || s === "no")
            return false;
        return fallback;
    }

    function parseIntClamped(v, fallback, minV, maxV) {
        const n = parseInt(String(v).trim(), 10);
        if (isNaN(n))
            return fallback;
        return Math.max(minV, Math.min(maxV, n));
    }

    function parseRealClamped(v, fallback, minV, maxV) {
        const n = parseFloat(String(v).trim());
        if (isNaN(n))
            return fallback;
        return Math.max(minV, Math.min(maxV, n));
    }

    // KConfig Color entries are often "R,G,B" or "R,G,B,A" (0–255).
    // QML color accepts #RRGGBB / #AARRGGBB / named colors, not bare R,G,B.
    function parseColor(v, fallback) {
        if (v === undefined || v === null || v === "")
            return fallback;

        // Already a QML/Qt color object (e.g. from KWin.readConfig).
        if (typeof v === "object") {
            try {
                const c = Qt.color(v);
                if (c && c.valid !== false)
                    return c;
            } catch (e) { /* fall through */ }
        }

        const s = String(v).trim();
        if (s.length === 0)
            return fallback;

        // #RGB / #RRGGBB / #AARRGGBB / named colors
        if (s.charAt(0) === "#" || s.indexOf("rgb") === 0 || s.indexOf("hsv") === 0) {
            try {
                const c = Qt.color(s);
                if (c)
                    return c;
            } catch (e) { /* fall through */ }
            return s;
        }

        // KDE kwinrc: "255,170,127" or "255,170,127,255"
        const parts = s.split(",");
        if (parts.length === 3 || parts.length === 4) {
            const r = parseInt(parts[0].trim(), 10);
            const g = parseInt(parts[1].trim(), 10);
            const b = parseInt(parts[2].trim(), 10);
            const a = parts.length === 4 ? parseInt(parts[3].trim(), 10) : 255;
            if (![r, g, b, a].some(function (n) { return isNaN(n); })) {
                const hx = function (n) {
                    const t = Math.max(0, Math.min(255, n)).toString(16);
                    return t.length === 1 ? "0" + t : t;
                };
                if (a >= 255)
                    return "#" + hx(r) + hx(g) + hx(b);
                return "#" + hx(a) + hx(r) + hx(g) + hx(b);
            }
        }

        try {
            const c = Qt.color(s);
            if (c)
                return c;
        } catch (e) { /* fall through */ }
        return fallback;
    }

    function colorKey(c) {
        try {
            return Qt.color(c).toString().toLowerCase();
        } catch (e) {
            return String(c).toLowerCase();
        }
    }

    function applyConfigValues(color, lw, op, ticks, diag, tlen, half) {
        const nextColor = root.parseColor(color, lineColor);
        if (root.colorKey(lineColor) !== root.colorKey(nextColor)) {
            console.log("InfiniteCrosshair LineColor", lineColor, "->", nextColor, "(raw=", color, ")");
            lineColor = nextColor;
        }
        if (lineWidth !== lw) {
            console.log("InfiniteCrosshair LineWidth", lineWidth, "->", lw);
            lineWidth = lw;
        }
        if (lineOpacity !== op) {
            console.log("InfiniteCrosshair Opacity", lineOpacity, "->", op);
            lineOpacity = op;
        }
        if (showInchTicks !== ticks) {
            console.log("InfiniteCrosshair ShowInchTicks", showInchTicks, "->", ticks);
            showInchTicks = ticks;
        }
        if (screenDiagonalInches !== diag) {
            console.log("InfiniteCrosshair ScreenDiagonalInches", screenDiagonalInches, "->", diag);
            screenDiagonalInches = diag;
        }
        if (tickLength !== tlen) {
            console.log("InfiniteCrosshair TickLength", tickLength, "->", tlen);
            tickLength = tlen;
        }
        if (showHalfInchTicks !== half) {
            console.log("InfiniteCrosshair ShowHalfInchTicks", showHalfInchTicks, "->", half);
            showHalfInchTicks = half;
        }
    }

    function applyConfigLines(stdout) {
        // Order matches configReadCmd (one value per non-empty line).
        const lines = String(stdout).split(/\r?\n/).map(function (s) {
            return s.trim();
        }).filter(function (s) {
            return s.length > 0;
        });
        if (lines.length < 1)
            return;

        applyConfigValues(
            lines.length > 0 ? lines[0] : "#FF0000",
            root.parseIntClamped(lines.length > 1 ? lines[1] : 1, 1, 1, 32),
            root.parseRealClamped(lines.length > 2 ? lines[2] : 0.8, 0.8, 0.05, 1.0),
            root.parseBool(lines.length > 3 ? lines[3] : true, true),
            root.parseRealClamped(lines.length > 4 ? lines[4] : 27.0, 27.0, 5.0, 120.0),
            root.parseIntClamped(lines.length > 5 ? lines[5] : 10, 10, 2, 64),
            root.parseBool(lines.length > 6 ? lines[6] : true, true)
        );
    }

    // Seed from KWin's config API (valid at script start / after full reload).
    function seedFromReadConfig() {
        const color = KWin.readConfig("LineColor", "#FF0000");
        const lw = root.parseIntClamped(KWin.readConfig("LineWidth", 1), 1, 1, 32);
        const op = root.parseRealClamped(KWin.readConfig("Opacity", 0.8), 0.8, 0.05, 1.0);
        const ticks = root.parseBool(KWin.readConfig("ShowInchTicks", true), true);
        const diag = root.parseRealClamped(KWin.readConfig("ScreenDiagonalInches", 27.0), 27.0, 5.0, 120.0);
        const tlen = root.parseIntClamped(KWin.readConfig("TickLength", 10), 10, 2, 64);
        const half = root.parseBool(KWin.readConfig("ShowHalfInchTicks", true), true);
        applyConfigValues(color, lw, op, ticks, diag, tlen, half);
    }

    function kickConfigPoll() {
        // Re-bind source so the executable engine runs immediately.
        configReader.connectedSources = [];
        configReader.connectedSources = [root.configReadCmd];
    }

    // Live disk poll (kreadconfig6 always hits current kwinrc).
    P5.DataSource {
        id: configReader
        engine: "executable"
        interval: 500
        connectedSources: [root.configReadCmd]

        onNewData: function (sourceName, data) {
            if (!data)
                return;
            const code = data["exit code"];
            if (code !== 0 && code !== "0")
                return;
            root.applyConfigLines(data.stdout || "");
        }
    }

    Connections {
        target: Workspace
        function onVirtualScreenSizeChanged() {
            root.width = Workspace.virtualScreenSize.width;
            root.height = Workspace.virtualScreenSize.height;
        }
    }

    // --- Screen resolution under cursor + PPI ---
    function screenUnderCursor() {
        const screens = Workspace.screens;
        if (!screens || screens.length === 0)
            return null;
        const pos = Workspace.cursorPos;
        for (let i = 0; i < screens.length; ++i) {
            const g = screens[i].geometry;
            if (pos.x >= g.x && pos.x < g.x + g.width
                    && pos.y >= g.y && pos.y < g.y + g.height)
                return screens[i];
        }
        return screens[0];
    }

    readonly property real pixelsPerInch: {
        void Workspace.cursorPos;
        const screen = root.screenUnderCursor();
        let w = Workspace.virtualScreenSize.width;
        let h = Workspace.virtualScreenSize.height;
        if (screen && screen.geometry) {
            w = screen.geometry.width;
            h = screen.geometry.height;
        }
        const diagIn = Math.max(0.1, root.screenDiagonalInches);
        const diagPx = Math.sqrt(w * w + h * h);
        return diagPx / diagIn;
    }

    readonly property real tickStepPx: {
        const ppi = root.pixelsPerInch;
        if (!(ppi > 1))
            return 0;
        return root.showHalfInchTicks ? (ppi * 0.5) : ppi;
    }

    readonly property int ticksPerSide: {
        const step = root.tickStepPx;
        if (!(step > 0.5))
            return 0;
        const extent = Math.max(root.width, root.height);
        return Math.ceil(extent / step) + 1;
    }

    readonly property int tickModelCount: root.ticksPerSide * 2

    function tickIndexFromCenter(modelIndex) {
        const side = root.ticksPerSide;
        return modelIndex < side ? (modelIndex - side) : (modelIndex - side + 1);
    }

    function isMajorTick(indexFromCenter) {
        if (!root.showHalfInchTicks)
            return true;
        return (indexFromCenter % 2) === 0;
    }

    // Vertical line
    Rectangle {
        x: Workspace.cursorPos.x - Math.max(1, root.lineWidth) / 2
        y: 0
        width: Math.max(1, root.lineWidth)
        height: parent.height
        color: root.lineColor
        opacity: root.lineOpacity
        z: 9999
    }

    // Horizontal line
    Rectangle {
        x: 0
        y: Workspace.cursorPos.y - Math.max(1, root.lineWidth) / 2
        width: parent.width
        height: Math.max(1, root.lineWidth)
        color: root.lineColor
        opacity: root.lineOpacity
        z: 9999
    }

    // Inch ticks (defaults ON; independent of config poller success)
    Item {
        id: tickOrigin
        x: Workspace.cursorPos.x
        y: Workspace.cursorPos.y
        visible: root.showInchTicks && root.tickStepPx > 0.5
        z: 10000

        Repeater {
            model: root.tickModelCount
            Rectangle {
                required property int index
                readonly property int fromCenter: root.tickIndexFromCenter(index)
                readonly property bool major: root.isMajorTick(fromCenter)
                readonly property int markLen: major ? root.tickLength : Math.max(2, Math.round(root.tickLength * 0.5))

                x: fromCenter * root.tickStepPx - root.tickStroke / 2
                y: -markLen / 2
                width: root.tickStroke
                height: markLen
                color: root.lineColor
                opacity: root.lineOpacity
            }
        }

        Repeater {
            model: root.tickModelCount
            Rectangle {
                required property int index
                readonly property int fromCenter: root.tickIndexFromCenter(index)
                readonly property bool major: root.isMajorTick(fromCenter)
                readonly property int markLen: major ? root.tickLength : Math.max(2, Math.round(root.tickLength * 0.5))

                x: -markLen / 2
                y: fromCenter * root.tickStepPx - root.tickStroke / 2
                width: markLen
                height: root.tickStroke
                color: root.lineColor
                opacity: root.lineOpacity
            }
        }
    }

    Component.onCompleted: {
        seedFromReadConfig();
        kickConfigPoll();

        const s = root.screenUnderCursor();
        const g = s ? s.geometry : null;
        console.log("InfiniteCrosshair ready",
                    "virtual=", width, "x", height,
                    "screen=", g ? (g.width + "x" + g.height) : "n/a",
                    "lineWidth=", root.lineWidth,
                    "ticks=", root.showInchTicks,
                    "diagIn=", root.screenDiagonalInches,
                    "ppi=", root.pixelsPerInch.toFixed(2),
                    "tickStep=", root.tickStepPx.toFixed(2));
    }
}
