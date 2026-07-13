import QtQuick
import QtQuick.Window
import org.kde.kwin
import org.kde.plasma.plasma5support as P5

// KWin declarativescript entry (X-Plasma-MainScript → ui/main.qml).
// Proven pattern: real Window + Workspace (capital W). Bare Item never paints.
Window {
    id: root

    // Bump when shipping behavior fixes — logged at ready so we can tell if
    // System Settings re-enable is running a stale QML body from the session.
    readonly property string buildId: "2026-07-13-color3"

    // Stable caption so we can find this surface in Workspace.stackingOrder
    // and set KWin client skip* flags (Qt window flags alone are not enough
    // on Wayland — BypassWindowManagerHint is X11-oriented).
    title: "Infinite Crosshair"
    visible: root.crosshairEnabled
    // Explicit zero-alpha (string "transparent" has been observed as opaque black
    // after some disable/re-enable cycles on Wayland).
    color: Qt.rgba(0, 0, 0, 0)
    flags: Qt.Tool
         | Qt.FramelessWindowHint
         | Qt.WindowStaysOnTopHint
         | Qt.WindowDoesNotAcceptFocus
         | Qt.WindowTransparentForInput
         | Qt.BypassWindowManagerHint

    x: 0
    y: 0
    width: Workspace.virtualScreenSize.width
    height: Workspace.virtualScreenSize.height

    // Must match metadata.json KPlugin.Id → [Script-<Id>] in kwinrc
    readonly property string configSection: "Script-kwin-crosshair"
    readonly property string pluginId: "kwin-crosshair"
    readonly property string overlayTitle: "Infinite Crosshair"
    // Must match ShortcutHandler.name (KWin global-accel action id).
    readonly property string toggleShortcutName: "Infinite Crosshair: Toggle"
    readonly property string toggleShortcutDefault: "Meta+Shift+X"

    // Runtime visibility (toggle via ShortcutHandler; not the script Enabled flag).
    property bool crosshairEnabled: true

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
     *
     * KEY=value lines avoid order/comma ambiguity (colors are R,G,B).
     */
    readonly property string configReadCmd:
        "printf 'LineColor='; kreadconfig6 --file kwinrc --group " + configSection + " --key LineColor --default '#FF0000'; echo; "
        + "printf 'LineWidth='; kreadconfig6 --file kwinrc --group " + configSection + " --key LineWidth --default 1; echo; "
        + "printf 'Opacity='; kreadconfig6 --file kwinrc --group " + configSection + " --key Opacity --default 0.8; echo; "
        + "printf 'ShowInchTicks='; kreadconfig6 --file kwinrc --group " + configSection + " --key ShowInchTicks --default true; echo; "
        + "printf 'ScreenDiagonalInches='; kreadconfig6 --file kwinrc --group " + configSection + " --key ScreenDiagonalInches --default 27.0; echo; "
        + "printf 'TickLength='; kreadconfig6 --file kwinrc --group " + configSection + " --key TickLength --default 10; echo; "
        + "printf 'ShowHalfInchTicks='; kreadconfig6 --file kwinrc --group " + configSection + " --key ShowHalfInchTicks --default true; echo"

    property int configPollCount: 0

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

    // Always return a real QML color via Qt.rgba (never raw "R,G,B" strings).
    // KWin.readConfig(Color) may hand us a QColor-like object; Qt.color(object)
    // can silently become black after disable/re-enable — read channels instead.
    function channel01(n, isByte) {
        if (isNaN(n))
            return 0;
        if (isByte)
            return Math.max(0, Math.min(255, n)) / 255;
        return Math.max(0, Math.min(1, n));
    }

    function rgbaBytes(r, g, b, a) {
        return Qt.rgba(channel01(r, true), channel01(g, true), channel01(b, true),
                       a === undefined ? 1 : channel01(a, true));
    }

    function parseColor(v, fallback) {
        const fb = (fallback === undefined || fallback === null || fallback === "")
                 ? Qt.rgba(1, 0, 0, 1)
                 : fallback;
        if (v === undefined || v === null || v === "")
            return fb;

        // QML color / QColor-like: r,g,b,a in 0..1
        if (typeof v === "object") {
            try {
                if (typeof v.r === "number" && typeof v.g === "number" && typeof v.b === "number") {
                    const a = (typeof v.a === "number") ? v.a : 1;
                    return Qt.rgba(channel01(v.r, v.r > 1 || v.g > 1 || v.b > 1),
                                   channel01(v.g, v.r > 1 || v.g > 1 || v.b > 1),
                                   channel01(v.b, v.r > 1 || v.g > 1 || v.b > 1),
                                   channel01(a, a > 1));
                }
            } catch (e) { /* fall through */ }
        }

        const s = String(v).trim();
        if (s.length === 0)
            return fb;

        // #RGB / #RRGGBB / #AARRGGBB
        if (s.charAt(0) === "#") {
            try {
                const c = Qt.color(s);
                if (c && typeof c.r === "number")
                    return Qt.rgba(c.r, c.g, c.b, (typeof c.a === "number") ? c.a : 1);
            } catch (e) { /* fall through */ }
            return fb;
        }

        // rgb()/hsv() text
        if (s.indexOf("rgb") === 0 || s.indexOf("hsv") === 0) {
            try {
                const c = Qt.color(s);
                if (c && typeof c.r === "number")
                    return Qt.rgba(c.r, c.g, c.b, (typeof c.a === "number") ? c.a : 1);
            } catch (e) { /* fall through */ }
            return fb;
        }

        // KDE kwinrc: "R,G,B" or "R,G,B,A" in 0–255 (integers)
        const parts = s.split(",");
        if (parts.length === 3 || parts.length === 4) {
            const nums = [];
            let ok = true;
            for (let i = 0; i < parts.length; ++i) {
                const n = parseFloat(parts[i].trim());
                if (isNaN(n)) {
                    ok = false;
                    break;
                }
                nums.push(n);
            }
            if (ok) {
                // Prefer 0–255 when any channel > 1 (KConfig default).
                const asBytes = nums[0] > 1 || nums[1] > 1 || nums[2] > 1
                             || (nums.length === 3)
                             || (nums.length === 4 && (nums[3] > 1 || nums[3] === 0));
                if (asBytes) {
                    return rgbaBytes(nums[0], nums[1], nums[2],
                                     nums.length === 4 ? nums[3] : 255);
                }
                return Qt.rgba(channel01(nums[0], false), channel01(nums[1], false),
                               channel01(nums[2], false),
                               nums.length === 4 ? channel01(nums[3], false) : 1);
            }
        }

        // Last resort: named colors only (avoid Qt.color on garbage → black).
        try {
            const c = Qt.color(s);
            if (c && typeof c.r === "number" && (c.r + c.g + c.b) > 0)
                return Qt.rgba(c.r, c.g, c.b, (typeof c.a === "number") ? c.a : 1);
        } catch (e) { /* fall through */ }
        return fb;
    }

    function colorKey(c) {
        try {
            const col = root.parseColor(c, Qt.rgba(1, 0, 0, 1));
            return [
                Math.round(col.r * 255),
                Math.round(col.g * 255),
                Math.round(col.b * 255),
                Math.round(((typeof col.a === "number") ? col.a : 1) * 255)
            ].join(",");
        } catch (e) {
            return String(c);
        }
    }

    function applyConfigValues(color, lw, op, ticks, diag, tlen, half) {
        // Never fall back to a stuck previous color — prefer red default.
        const nextColor = root.parseColor(color, Qt.rgba(1, 0, 0, 1));
        const prevKey = root.colorKey(lineColor);
        const nextKey = root.colorKey(nextColor);
        if (prevKey !== nextKey) {
            console.log("InfiniteCrosshair LineColor", prevKey, "->", nextKey, "(raw=", color, "typeof=", typeof color, ")");
            lineColor = nextColor;
        } else {
            // Re-assign so bindings refresh after disable/re-enable glitches.
            lineColor = nextColor;
        }
        if (lineWidth !== lw) {
            console.log("InfiniteCrosshair LineWidth", lineWidth, "->", lw);
            lineWidth = lw;
        }
        if (Math.abs(lineOpacity - op) > 0.0001) {
            console.log("InfiniteCrosshair Opacity", lineOpacity, "->", op);
            lineOpacity = op;
        }
        if (showInchTicks !== ticks) {
            console.log("InfiniteCrosshair ShowInchTicks", showInchTicks, "->", ticks);
            showInchTicks = ticks;
        }
        if (Math.abs(screenDiagonalInches - diag) > 0.0001) {
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

    function applyConfigMap(map) {
        applyConfigValues(
            map.LineColor !== undefined ? map.LineColor : "#FF0000",
            root.parseIntClamped(map.LineWidth !== undefined ? map.LineWidth : 1, 1, 1, 32),
            root.parseRealClamped(map.Opacity !== undefined ? map.Opacity : 0.8, 0.8, 0.05, 1.0),
            root.parseBool(map.ShowInchTicks !== undefined ? map.ShowInchTicks : true, true),
            root.parseRealClamped(map.ScreenDiagonalInches !== undefined ? map.ScreenDiagonalInches : 27.0, 27.0, 5.0, 120.0),
            root.parseIntClamped(map.TickLength !== undefined ? map.TickLength : 10, 10, 2, 64),
            root.parseBool(map.ShowHalfInchTicks !== undefined ? map.ShowHalfInchTicks : true, true)
        );
    }

    function applyConfigLines(stdout) {
        // Prefer KEY=value (new). Fall back to legacy positional lines.
        const rawLines = String(stdout).split(/\r?\n/).map(function (s) {
            return s.trim();
        }).filter(function (s) {
            return s.length > 0;
        });
        if (rawLines.length < 1)
            return;

        const map = ({});
        let keyed = 0;
        for (let i = 0; i < rawLines.length; ++i) {
            const line = rawLines[i];
            const eq = line.indexOf("=");
            if (eq > 0) {
                const k = line.substring(0, eq);
                const v = line.substring(eq + 1);
                if (k === "LineColor" || k === "LineWidth" || k === "Opacity"
                        || k === "ShowInchTicks" || k === "ScreenDiagonalInches"
                        || k === "TickLength" || k === "ShowHalfInchTicks") {
                    map[k] = v;
                    keyed += 1;
                }
            }
        }

        if (keyed > 0) {
            applyConfigMap(map);
            return;
        }

        // Legacy: one bare value per line in fixed order.
        applyConfigValues(
            rawLines.length > 0 ? rawLines[0] : "#FF0000",
            root.parseIntClamped(rawLines.length > 1 ? rawLines[1] : 1, 1, 1, 32),
            root.parseRealClamped(rawLines.length > 2 ? rawLines[2] : 0.8, 0.8, 0.05, 1.0),
            root.parseBool(rawLines.length > 3 ? rawLines[3] : true, true),
            root.parseRealClamped(rawLines.length > 4 ? rawLines[4] : 27.0, 27.0, 5.0, 120.0),
            root.parseIntClamped(rawLines.length > 5 ? rawLines[5] : 10, 10, 2, 64),
            root.parseBool(rawLines.length > 6 ? rawLines[6] : true, true)
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
        console.log("InfiniteCrosshair seed raw LineColor=", color, "typeof=", typeof color,
                    "key=", root.colorKey(root.parseColor(color, "#FF0000")),
                    "lw=", lw, "ticks=", ticks, "tlen=", tlen);
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
            if (code !== 0 && code !== "0") {
                if (root.configPollCount < 3)
                    console.log("InfiniteCrosshair config poll fail code=", code,
                                "stderr=", data.stderr || "");
                return;
            }
            root.configPollCount += 1;
            if (root.configPollCount <= 2) {
                console.log("InfiniteCrosshair config poll #", root.configPollCount,
                            "stdout=", (data.stdout || "").replace(/\n/g, " | "));
            }
            root.applyConfigLines(data.stdout || "");
        }
    }

    Connections {
        target: Workspace
        function onVirtualScreenSizeChanged() {
            root.width = Workspace.virtualScreenSize.width;
            root.height = Workspace.virtualScreenSize.height;
            root.hideOverlayFromWmLists();
        }
        function onWindowAdded(window) {
            root.claimOverlayClient(window);
        }
    }

    // KWin client-side exclusion from Alt+Tab / taskbar / pager.
    // Match only by our stable Window.title — full-screen heuristics are too risky.
    function isOurOverlayClient(w) {
        if (!w)
            return false;
        const cap = String(w.caption || "");
        return cap === root.overlayTitle || cap.indexOf(root.overlayTitle) !== -1;
    }

    function claimOverlayClient(w) {
        if (!root.isOurOverlayClient(w))
            return false;
        // Already claimed — keep flags sticky without spamming logs.
        if (w.skipSwitcher === true && w.skipTaskbar === true && w.skipPager === true)
            return true;
        try {
            w.skipSwitcher = true;
            w.skipTaskbar = true;
            w.skipPager = true;
            if ("keepAbove" in w)
                w.keepAbove = true;
            console.log("InfiniteCrosshair claimed client caption=", String(w.caption || ""),
                        "class=", String(w.resourceClass || ""),
                        "skipSwitcher=", w.skipSwitcher);
            return true;
        } catch (e) {
            console.log("InfiniteCrosshair claim failed", e);
            return false;
        }
    }

    function hideOverlayFromWmLists() {
        const list = Workspace.stackingOrder;
        if (!list)
            return 0;
        let claimed = 0;
        for (let i = 0; i < list.length; ++i) {
            if (root.claimOverlayClient(list[i]))
                claimed += 1;
        }
        if (claimed > 0)
            hideClaimRetry.stop();
        else if (hideClaimRetry.tries === 3) {
            for (let i = 0; i < list.length; ++i) {
                const w = list[i];
                if (!w)
                    continue;
                console.log("InfiniteCrosshair stack[", i, "] cap=", String(w.caption || ""),
                            "class=", String(w.resourceClass || ""),
                            "skipSw=", w.skipSwitcher);
            }
        }
        return claimed;
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

    function toggleCrosshair() {
        root.crosshairEnabled = !root.crosshairEnabled;
        console.log("InfiniteCrosshair toggled",
                    root.crosshairEnabled ? "ON" : "OFF");
        if (root.crosshairEnabled) {
            hideClaimRetry.tries = 0;
            hideClaimRetry.restart();
            Qt.callLater(root.hideOverlayFromWmLists);
        }
    }

    // System Settings → Keyboard → Shortcuts → KWin (also listed in script Configure).
    ShortcutHandler {
        name: root.toggleShortcutName
        text: root.toggleShortcutName
        sequence: root.toggleShortcutDefault
        onActivated: root.toggleCrosshair()
    }

    Component.onCompleted: {
        seedFromReadConfig();
        kickConfigPoll();
        // Caption / client mapping can lag one frame after the surface maps.
        Qt.callLater(root.hideOverlayFromWmLists);
        hideClaimRetry.restart();

        const s = root.screenUnderCursor();
        const g = s ? s.geometry : null;
        console.log("InfiniteCrosshair ready build=", root.buildId,
                    "virtual=", width, "x", height,
                    "screen=", g ? (g.width + "x" + g.height) : "n/a",
                    "lineColor=", root.colorKey(root.lineColor),
                    "lineWidth=", root.lineWidth,
                    "ticks=", root.showInchTicks,
                    "diagIn=", root.screenDiagonalInches,
                    "ppi=", root.pixelsPerInch.toFixed(2),
                    "tickStep=", root.tickStepPx.toFixed(2),
                    "enabled=", root.crosshairEnabled,
                    "toggle=", root.toggleShortcutDefault);
    }

    // Brief retries: Wayland maps the surface after onCompleted.
    Timer {
        id: hideClaimRetry
        interval: 250
        repeat: true
        property int tries: 0
        onTriggered: {
            root.hideOverlayFromWmLists();
            tries += 1;
            if (tries >= 8)
                stop();
        }
    }
}
