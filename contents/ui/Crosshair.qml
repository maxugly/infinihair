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
    readonly property string buildId: "2026-07-13-offset3"

    // Stable caption so we can find this surface in Workspace.stackingOrder
    // and set KWin client skip* flags (Qt window flags alone are not enough
    // on Wayland — BypassWindowManagerHint is X11-oriented).
    title: "Infinite Crosshair"
    // ALWAYS mapped. Toggling Window.visible unmaps/remaps the full-screen
    // surface on Wayland and can drop WindowTransparentForInput — user then
    // loses pointer control of the desktop/UI (BUG-01). Hide draw items only.
    visible: true
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
    readonly property string toggleOffsetVShortcutName: "Infinite Crosshair: Toggle Offset Vertical"
    readonly property string toggleOffsetVShortcutDefault: "Meta+Shift+V"
    readonly property string toggleOffsetHShortcutName: "Infinite Crosshair: Toggle Offset Horizontal"
    readonly property string toggleOffsetHShortcutDefault: "Meta+Shift+H"
    readonly property string captureOffsetShortcutName: "Infinite Crosshair: Capture Border Offset"
    readonly property string captureOffsetShortcutDefault: "Meta+Shift+B"
    readonly property string clearOffsetShortcutName: "Infinite Crosshair: Clear Offset Guides"
    readonly property string clearOffsetShortcutDefault: "Meta+Shift+C"

    // Runtime visibility (toggle via ShortcutHandler; not the script Enabled flag).
    property bool crosshairEnabled: true

    // Primary crosshair stays on the cursor.
    readonly property real linePosX: Workspace.cursorPos.x
    readonly property real linePosY: Workspace.cursorPos.y

    // --- Secondary offset guides (specs/offset-line-mode.md v2) ---
    // Each axis: enable + offset(px from cursor) + color. Independent of primary.
    property bool offsetVerticalEnabled: false
    property int offsetVerticalOffset: 100
    property int offsetVerticalColorR: 0
    property int offsetVerticalColorG: 255
    property int offsetVerticalColorB: 255
    property color offsetVerticalColor: Qt.rgba(0, 1, 1, 1)

    property bool offsetHorizontalEnabled: false
    property int offsetHorizontalOffset: 100
    property int offsetHorizontalColorR: 0
    property int offsetHorizontalColorG: 255
    property int offsetHorizontalColorB: 0
    property color offsetHorizontalColor: Qt.rgba(0, 1, 0, 1)

    // When true: second V/H guides snap to nearest frame edges of the window
    // under the cursor (or the window being moved) — live, every cursor move.
    // When false: fixed offsets from Configure (cursor + offsetVerticalOffset).
    property bool autoOffsetOnMove: true
    property var offsetTrackWindow: null
    // Bumped on move/resize steps so edge positions rebind when geometry
    // changes without a cursorPos change.
    property int autoAlignRev: 0

    // Live target window for automagic edge align (move-tracked wins).
    readonly property var autoAlignWindow: {
        void Workspace.cursorPos;
        void Workspace.stackingOrder;
        void root.autoAlignRev;
        if (root.offsetTrackWindow)
            return root.offsetTrackWindow;
        if (root.autoOffsetOnMove)
            return root.windowUnderCursor();
        return null;
    }

    // Nearest frame edges for automagic (manual offset fallback when no window).
    readonly property real autoEdgeX: {
        void Workspace.cursorPos;
        void root.autoAlignRev;
        const w = root.autoAlignWindow;
        const g = root.windowFrameGeometry(w);
        if (!g)
            return root.linePosX + root.offsetVerticalOffset;
        const pos = Workspace.cursorPos;
        const left = g.x;
        const right = g.x + g.width;
        return (Math.abs(pos.x - left) <= Math.abs(pos.x - right)) ? left : right;
    }

    readonly property real autoEdgeY: {
        void Workspace.cursorPos;
        void root.autoAlignRev;
        const w = root.autoAlignWindow;
        const g = root.windowFrameGeometry(w);
        if (!g)
            return root.linePosY + root.offsetHorizontalOffset;
        const pos = Workspace.cursorPos;
        const top = g.y;
        const bottom = g.y + g.height;
        return (Math.abs(pos.y - top) <= Math.abs(pos.y - bottom)) ? top : bottom;
    }

    // Draw positions for second guides.
    readonly property real offsetVerticalPosX: {
        void Workspace.cursorPos;
        void root.autoAlignRev;
        if (root.autoOffsetOnMove && root.autoAlignWindow)
            return root.autoEdgeX;
        return root.linePosX + root.offsetVerticalOffset;
    }

    readonly property real offsetHorizontalPosY: {
        void Workspace.cursorPos;
        void root.autoAlignRev;
        if (root.autoOffsetOnMove && root.autoAlignWindow)
            return root.autoEdgeY;
        return root.linePosY + root.offsetHorizontalOffset;
    }

    // Automagic shows both guides when auto-align has a window (unless cleared
    // and auto is off). Manual toggles still apply when auto is off.
    readonly property bool showOffsetVertical: root.crosshairEnabled && (
        root.autoOffsetOnMove && root.autoAlignWindow
            ? true
            : root.offsetVerticalEnabled)
    readonly property bool showOffsetHorizontal: root.crosshairEnabled && (
        root.autoOffsetOnMove && root.autoAlignWindow
            ? true
            : root.offsetHorizontalEnabled)

    // --- Live config (mutable; seeded on start, refreshed from disk) ---
    // UI: KColorButton ↔ kcfg_LineColor (KConfig Color). Runtime always uses
    // channel ints + Qt.rgba rebuild so re-enable never sticks on a black QColor.
    property int lineColorR: 255
    property int lineColorG: 0
    property int lineColorB: 0
    property color lineColor: Qt.rgba(1, 0, 0, 1)
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
     * Color: UI writes LineColor (KConfig Color). We also mirror LineColorR/G/B
     * ints on disk (not in the form) so re-enable still has channels if Color
     * load is flaky. Poller keeps both in sync, then dumps KEY=value.
     */
    readonly property string configReadCmd:
        "python3 - <<'PY'\n"
        + "import subprocess\n"
        + "G=" + JSON.stringify(configSection) + "\n"
        + "def kr(key, default=''):\n"
        + "    r=subprocess.run(['kreadconfig6','--file','kwinrc','--group',G,'--key',key,'--default',str(default)],capture_output=True,text=True)\n"
        + "    return (r.stdout or '').strip()\n"
        + "def kw(key, val):\n"
        + "    subprocess.run(['kwriteconfig6','--file','kwinrc','--group',G,'--key',key,str(val)],check=False)\n"
        + "def parse_color(s):\n"
        + "    s=(s or '').strip()\n"
        + "    if not s: return None\n"
        + "    if s.startswith('#') and len(s)>=7:\n"
        + "        h=s[1:7]; return int(h[0:2],16),int(h[2:4],16),int(h[4:6],16)\n"
        + "    parts=[p.strip() for p in s.split(',')]\n"
        + "    if len(parts)>=3:\n"
        + "        try:\n"
        + "            a,b,c=float(parts[0]),float(parts[1]),float(parts[2])\n"
        + "            if a>1 or b>1 or c>1:\n"
        + "                return int(a),int(b),int(c)\n"
        + "            if any('.' in parts[i] for i in range(3)):\n"
        + "                return int(round(a*255)),int(round(b*255)),int(round(c*255))\n"
        + "            return int(a),int(b),int(c)\n"
        + "        except: return None\n"
        + "    return None\n"
        + "def sync_color(name, dr, dg, db):\n"
        + "    leg=kr(name,'')\n"
        + "    R,Gg,B=kr(name+'R',''),kr(name+'G',''),kr(name+'B','')\n"
        + "    rgb=parse_color(leg)\n"
        + "    if rgb is None and R!='':\n"
        + "        try: rgb=(max(0,min(255,int(float(R)))),max(0,min(255,int(float(Gg or 0)))),max(0,min(255,int(float(B or 0)))))\n"
        + "        except: rgb=None\n"
        + "    if rgb is None: rgb=(dr,dg,db)\n"
        + "    r,g,b=rgb\n"
        + "    kw(name+'R',r); kw(name+'G',g); kw(name+'B',b)\n"
        + "    kw(name,'%d,%d,%d'%(r,g,b))\n"
        + "    print(name+'=%d,%d,%d'%(r,g,b))\n"
        + "    print(name+'R='+str(r)); print(name+'G='+str(g)); print(name+'B='+str(b))\n"
        + "sync_color('LineColor',255,0,0)\n"
        + "sync_color('OffsetVerticalColor',0,255,255)\n"
        + "sync_color('OffsetHorizontalColor',0,255,0)\n"
        + "print('LineWidth='+kr('LineWidth','1'))\n"
        + "print('Opacity='+kr('Opacity','0.8'))\n"
        + "print('ShowInchTicks='+kr('ShowInchTicks','true'))\n"
        + "print('ScreenDiagonalInches='+kr('ScreenDiagonalInches','27.0'))\n"
        + "print('TickLength='+kr('TickLength','10'))\n"
        + "print('ShowHalfInchTicks='+kr('ShowHalfInchTicks','true'))\n"
        + "print('OffsetVerticalEnabled='+kr('OffsetVerticalEnabled','false'))\n"
        + "print('OffsetVerticalOffset='+kr('OffsetVerticalOffset','100'))\n"
        + "print('OffsetHorizontalEnabled='+kr('OffsetHorizontalEnabled','false'))\n"
        + "print('OffsetHorizontalOffset='+kr('OffsetHorizontalOffset','100'))\n"
        + "print('AutoOffsetOnMove='+kr('AutoOffsetOnMove','true'))\n"
        + "PY"

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

    function setLineColorRgb(r, g, b, sourceTag) {
        r = root.parseIntClamped(r, 255, 0, 255);
        g = root.parseIntClamped(g, 0, 0, 255);
        b = root.parseIntClamped(b, 0, 0, 255);
        const prev = root.lineColorR + "," + root.lineColorG + "," + root.lineColorB;
        const next = r + "," + g + "," + b;
        root.lineColorR = r;
        root.lineColorG = g;
        root.lineColorB = b;
        root.lineColor = root.rgbaBytes(r, g, b, 255);
        if (prev !== next) {
            console.log("InfiniteCrosshair LineColor", prev, "->", next,
                        "src=", sourceTag || "n/a");
        }
    }

    function setOffsetVerticalColorRgb(r, g, b, sourceTag) {
        r = root.parseIntClamped(r, 0, 0, 255);
        g = root.parseIntClamped(g, 255, 0, 255);
        b = root.parseIntClamped(b, 255, 0, 255);
        const prev = root.offsetVerticalColorR + "," + root.offsetVerticalColorG + "," + root.offsetVerticalColorB;
        const next = r + "," + g + "," + b;
        root.offsetVerticalColorR = r;
        root.offsetVerticalColorG = g;
        root.offsetVerticalColorB = b;
        root.offsetVerticalColor = root.rgbaBytes(r, g, b, 255);
        if (prev !== next)
            console.log("InfiniteCrosshair OffsetVerticalColor", prev, "->", next, "src=", sourceTag || "n/a");
    }

    function setOffsetHorizontalColorRgb(r, g, b, sourceTag) {
        r = root.parseIntClamped(r, 0, 0, 255);
        g = root.parseIntClamped(g, 255, 0, 255);
        b = root.parseIntClamped(b, 0, 0, 255);
        const prev = root.offsetHorizontalColorR + "," + root.offsetHorizontalColorG + "," + root.offsetHorizontalColorB;
        const next = r + "," + g + "," + b;
        root.offsetHorizontalColorR = r;
        root.offsetHorizontalColorG = g;
        root.offsetHorizontalColorB = b;
        root.offsetHorizontalColor = root.rgbaBytes(r, g, b, 255);
        if (prev !== next)
            console.log("InfiniteCrosshair OffsetHorizontalColor", prev, "->", next, "src=", sourceTag || "n/a");
    }

    function applyConfigValues(r, g, b, lw, op, ticks, diag, tlen, half, sourceTag) {
        root.setLineColorRgb(r, g, b, sourceTag);
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

    function applyConfigMap(map, sourceTag) {
        let r = 255, g = 0, b = 0;
        // Prefer explicit channels (mirrored by poller); else KConfig Color string.
        if (map.LineColorR !== undefined && map.LineColorG !== undefined && map.LineColorB !== undefined
                && String(map.LineColorR).length > 0) {
            r = root.parseIntClamped(map.LineColorR, 255, 0, 255);
            g = root.parseIntClamped(map.LineColorG, 0, 0, 255);
            b = root.parseIntClamped(map.LineColorB, 0, 0, 255);
        } else if (map.LineColor !== undefined && String(map.LineColor).length > 0) {
            const c = root.parseColor(map.LineColor, Qt.rgba(1, 0, 0, 1));
            r = Math.round(c.r * 255);
            g = Math.round(c.g * 255);
            b = Math.round(c.b * 255);
        }
        applyConfigValues(
            r, g, b,
            root.parseIntClamped(map.LineWidth !== undefined ? map.LineWidth : 1, 1, 1, 32),
            root.parseRealClamped(map.Opacity !== undefined ? map.Opacity : 0.8, 0.8, 0.05, 1.0),
            root.parseBool(map.ShowInchTicks !== undefined ? map.ShowInchTicks : true, true),
            root.parseRealClamped(map.ScreenDiagonalInches !== undefined ? map.ScreenDiagonalInches : 27.0, 27.0, 5.0, 120.0),
            root.parseIntClamped(map.TickLength !== undefined ? map.TickLength : 10, 10, 2, 64),
            root.parseBool(map.ShowHalfInchTicks !== undefined ? map.ShowHalfInchTicks : true, true),
            sourceTag || "map"
        );
        if (map.AutoOffsetOnMove !== undefined) {
            const ao = root.parseBool(map.AutoOffsetOnMove, true);
            if (autoOffsetOnMove !== ao) {
                console.log("InfiniteCrosshair AutoOffsetOnMove", autoOffsetOnMove, "->", ao);
                autoOffsetOnMove = ao;
            }
        }

        if (map.OffsetVerticalEnabled !== undefined) {
            const en = root.parseBool(map.OffsetVerticalEnabled, false);
            if (offsetVerticalEnabled !== en)
                offsetVerticalEnabled = en;
        }
        if (map.OffsetVerticalOffset !== undefined) {
            const off = root.parseIntClamped(map.OffsetVerticalOffset, 100, -4000, 4000);
            if (offsetVerticalOffset !== off)
                offsetVerticalOffset = off;
        }
        if (map.OffsetVerticalColorR !== undefined || map.OffsetVerticalColor !== undefined) {
            let vr = 0, vg = 255, vb = 255;
            if (map.OffsetVerticalColorR !== undefined && String(map.OffsetVerticalColorR).length > 0) {
                vr = root.parseIntClamped(map.OffsetVerticalColorR, 0, 0, 255);
                vg = root.parseIntClamped(map.OffsetVerticalColorG, 255, 0, 255);
                vb = root.parseIntClamped(map.OffsetVerticalColorB, 255, 0, 255);
            } else if (map.OffsetVerticalColor !== undefined) {
                const c = root.parseColor(map.OffsetVerticalColor, Qt.rgba(0, 1, 1, 1));
                vr = Math.round(c.r * 255); vg = Math.round(c.g * 255); vb = Math.round(c.b * 255);
            }
            root.setOffsetVerticalColorRgb(vr, vg, vb, sourceTag || "map");
        }

        if (map.OffsetHorizontalEnabled !== undefined) {
            const en = root.parseBool(map.OffsetHorizontalEnabled, false);
            if (offsetHorizontalEnabled !== en)
                offsetHorizontalEnabled = en;
        }
        if (map.OffsetHorizontalOffset !== undefined) {
            const off = root.parseIntClamped(map.OffsetHorizontalOffset, 100, -4000, 4000);
            if (offsetHorizontalOffset !== off)
                offsetHorizontalOffset = off;
        }
        if (map.OffsetHorizontalColorR !== undefined || map.OffsetHorizontalColor !== undefined) {
            let hr = 0, hg = 255, hb = 0;
            if (map.OffsetHorizontalColorR !== undefined && String(map.OffsetHorizontalColorR).length > 0) {
                hr = root.parseIntClamped(map.OffsetHorizontalColorR, 0, 0, 255);
                hg = root.parseIntClamped(map.OffsetHorizontalColorG, 255, 0, 255);
                hb = root.parseIntClamped(map.OffsetHorizontalColorB, 0, 0, 255);
            } else if (map.OffsetHorizontalColor !== undefined) {
                const c = root.parseColor(map.OffsetHorizontalColor, Qt.rgba(0, 1, 0, 1));
                hr = Math.round(c.r * 255); hg = Math.round(c.g * 255); hb = Math.round(c.b * 255);
            }
            root.setOffsetHorizontalColorRgb(hr, hg, hb, sourceTag || "map");
        }
    }

    function applyConfigLines(stdout, sourceTag) {
        const rawLines = String(stdout).split(/\r?\n/).map(function (s) {
            return s.trim();
        }).filter(function (s) {
            return s.length > 0;
        });
        if (rawLines.length < 1)
            return;

        const map = ({});
        let keyed = 0;
        const keys = {
            "LineColorR": 1, "LineColorG": 1, "LineColorB": 1, "LineColor": 1,
            "OffsetVerticalColorR": 1, "OffsetVerticalColorG": 1, "OffsetVerticalColorB": 1, "OffsetVerticalColor": 1,
            "OffsetHorizontalColorR": 1, "OffsetHorizontalColorG": 1, "OffsetHorizontalColorB": 1, "OffsetHorizontalColor": 1,
            "LineWidth": 1, "Opacity": 1, "ShowInchTicks": 1,
            "ScreenDiagonalInches": 1, "TickLength": 1, "ShowHalfInchTicks": 1,
            "OffsetVerticalEnabled": 1, "OffsetVerticalOffset": 1,
            "OffsetHorizontalEnabled": 1, "OffsetHorizontalOffset": 1,
            "AutoOffsetOnMove": 1
        };
        for (let i = 0; i < rawLines.length; ++i) {
            const line = rawLines[i];
            const eq = line.indexOf("=");
            if (eq > 0) {
                const k = line.substring(0, eq);
                const v = line.substring(eq + 1);
                if (keys[k]) {
                    map[k] = v;
                    keyed += 1;
                }
            }
        }

        if (keyed > 0) {
            applyConfigMap(map, sourceTag || "poll");
            return;
        }
    }

    // Seed from KWin's config API (valid at script start / after full reload).
    // Prefer channel ints when present (stable across re-enable); else LineColor.
    // Disk poller is authoritative shortly after start and keeps Color↔RGB mirrored.
    function seedFromReadConfig() {
        let r = root.parseIntClamped(KWin.readConfig("LineColorR", -1), -1, -1, 255);
        let g = root.parseIntClamped(KWin.readConfig("LineColorG", -1), -1, -1, 255);
        let b = root.parseIntClamped(KWin.readConfig("LineColorB", -1), -1, -1, 255);
        if (r < 0 || g < 0 || b < 0) {
            const c = root.parseColor(KWin.readConfig("LineColor", "#FF0000"), Qt.rgba(1, 0, 0, 1));
            r = Math.round(c.r * 255);
            g = Math.round(c.g * 255);
            b = Math.round(c.b * 255);
        }
        const lw = root.parseIntClamped(KWin.readConfig("LineWidth", 1), 1, 1, 32);
        const op = root.parseRealClamped(KWin.readConfig("Opacity", 0.8), 0.8, 0.05, 1.0);
        const ticks = root.parseBool(KWin.readConfig("ShowInchTicks", true), true);
        const diag = root.parseRealClamped(KWin.readConfig("ScreenDiagonalInches", 27.0), 27.0, 5.0, 120.0);
        const tlen = root.parseIntClamped(KWin.readConfig("TickLength", 10), 10, 2, 64);
        const half = root.parseBool(KWin.readConfig("ShowHalfInchTicks", true), true);
        root.autoOffsetOnMove = root.parseBool(KWin.readConfig("AutoOffsetOnMove", true), true);
        root.offsetVerticalEnabled = root.parseBool(KWin.readConfig("OffsetVerticalEnabled", false), false);
        root.offsetVerticalOffset = root.parseIntClamped(KWin.readConfig("OffsetVerticalOffset", 100), 100, -4000, 4000);
        root.offsetHorizontalEnabled = root.parseBool(KWin.readConfig("OffsetHorizontalEnabled", false), false);
        root.offsetHorizontalOffset = root.parseIntClamped(KWin.readConfig("OffsetHorizontalOffset", 100), 100, -4000, 4000);
        {
            let vr = root.parseIntClamped(KWin.readConfig("OffsetVerticalColorR", -1), -1, -1, 255);
            let vg = root.parseIntClamped(KWin.readConfig("OffsetVerticalColorG", -1), -1, -1, 255);
            let vb = root.parseIntClamped(KWin.readConfig("OffsetVerticalColorB", -1), -1, -1, 255);
            if (vr < 0 || vg < 0 || vb < 0) {
                const c = root.parseColor(KWin.readConfig("OffsetVerticalColor", "#00FFFF"), Qt.rgba(0, 1, 1, 1));
                vr = Math.round(c.r * 255); vg = Math.round(c.g * 255); vb = Math.round(c.b * 255);
            }
            root.setOffsetVerticalColorRgb(vr, vg, vb, "seed");
        }
        {
            let hr = root.parseIntClamped(KWin.readConfig("OffsetHorizontalColorR", -1), -1, -1, 255);
            let hg = root.parseIntClamped(KWin.readConfig("OffsetHorizontalColorG", -1), -1, -1, 255);
            let hb = root.parseIntClamped(KWin.readConfig("OffsetHorizontalColorB", -1), -1, -1, 255);
            if (hr < 0 || hg < 0 || hb < 0) {
                const c = root.parseColor(KWin.readConfig("OffsetHorizontalColor", "#00FF00"), Qt.rgba(0, 1, 0, 1));
                hr = Math.round(c.r * 255); hg = Math.round(c.g * 255); hb = Math.round(c.b * 255);
            }
            root.setOffsetHorizontalColorRgb(hr, hg, hb, "seed");
        }
        console.log("InfiniteCrosshair seed rgb=", r, g, b,
                    "lw=", lw, "op=", op, "ticks=", ticks, "tlen=", tlen,
                    "offV=", root.offsetVerticalEnabled, root.offsetVerticalOffset,
                    "offH=", root.offsetHorizontalEnabled, root.offsetHorizontalOffset,
                    "autoOffset=", root.autoOffsetOnMove,
                    "build=", root.buildId);
        applyConfigValues(r, g, b, lw, op, ticks, diag, tlen, half, "seed");
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
            root.applyConfigLines(data.stdout || "", "poll");
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
            root.hookWindowMoveResize(window);
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

    function windowFrameGeometry(w) {
        if (!w)
            return null;
        try {
            if (w.frameGeometry)
                return w.frameGeometry;
        } catch (e) { /* fall through */ }
        try {
            if (w.geometry)
                return w.geometry;
        } catch (e2) { /* fall through */ }
        return null;
    }

    function windowUnderCursor() {
        const list = Workspace.stackingOrder;
        if (!list)
            return null;
        const pos = Workspace.cursorPos;
        for (let i = list.length - 1; i >= 0; --i) {
            const w = list[i];
            if (!w || root.isOurOverlayClient(w))
                continue;
            try {
                if (w.desktopWindow === true || w.dock === true)
                    continue;
                if (w.deleted === true)
                    continue;
            } catch (e) { /* ignore */ }
            const g = root.windowFrameGeometry(w);
            if (!g)
                continue;
            if (pos.x >= g.x && pos.x < g.x + g.width
                    && pos.y >= g.y && pos.y < g.y + g.height)
                return w;
        }
        return null;
    }

    // Nearest L/R → vertical guide offset; nearest T/B → horizontal guide offset.
    // offset = edge - cursor so (cursor + offset) sits on the edge.
    function setOffsetFromFrame(g, sourceTag) {
        if (!g)
            return false;
        const pos = Workspace.cursorPos;
        const left = g.x;
        const right = g.x + g.width;
        const top = g.y;
        const bottom = g.y + g.height;
        const edgeX = (Math.abs(pos.x - left) <= Math.abs(pos.x - right)) ? left : right;
        const edgeY = (Math.abs(pos.y - top) <= Math.abs(pos.y - bottom)) ? top : bottom;
        root.offsetVerticalOffset = Math.round(edgeX - pos.x);
        root.offsetHorizontalOffset = Math.round(edgeY - pos.y);
        root.offsetVerticalEnabled = true;
        root.offsetHorizontalEnabled = true;
        console.log("InfiniteCrosshair guide offsets",
                    "v=", root.offsetVerticalOffset, "h=", root.offsetHorizontalOffset,
                    "edge=", Math.round(edgeX) + "," + Math.round(edgeY),
                    "src=", sourceTag || "n/a");
        return true;
    }

    function captureBorderOffset() {
        const w = root.windowUnderCursor();
        if (!w) {
            console.log("InfiniteCrosshair capture: no window under cursor");
            return;
        }
        const g = root.windowFrameGeometry(w);
        if (!root.setOffsetFromFrame(g, "capture"))
            console.log("InfiniteCrosshair capture: no geometry");
    }

    function clearOffsetGuides() {
        root.offsetVerticalEnabled = false;
        root.offsetHorizontalEnabled = false;
        root.offsetVerticalOffset = 0;
        root.offsetHorizontalOffset = 0;
        root.offsetTrackWindow = null;
        console.log("InfiniteCrosshair offset guides cleared");
    }

    function toggleOffsetVertical() {
        root.offsetVerticalEnabled = !root.offsetVerticalEnabled;
        console.log("InfiniteCrosshair offset vertical",
                    root.offsetVerticalEnabled ? "ON" : "OFF",
                    "off=", root.offsetVerticalOffset);
    }

    function toggleOffsetHorizontal() {
        root.offsetHorizontalEnabled = !root.offsetHorizontalEnabled;
        console.log("InfiniteCrosshair offset horizontal",
                    root.offsetHorizontalEnabled ? "ON" : "OFF",
                    "off=", root.offsetHorizontalOffset);
    }

    function refreshOffsetFromTrackedWindow() {
        const w = root.offsetTrackWindow;
        if (!w || !root.autoOffsetOnMove)
            return;
        const g = root.windowFrameGeometry(w);
        root.setOffsetFromFrame(g, "move");
    }

    function hookWindowMoveResize(w) {
        if (!w || root.isOurOverlayClient(w))
            return;
        try {
            if (w._infinihairOffsetHooked)
                return;
            w._infinihairOffsetHooked = true;
        } catch (e) {
            // Some clients may not allow expando props; still connect.
        }
        try {
            w.interactiveMoveResizeStarted.connect(function () {
                if (!root.autoOffsetOnMove)
                    return;
                root.offsetTrackWindow = w;
                root.refreshOffsetFromTrackedWindow();
            });
            w.interactiveMoveResizeStepped.connect(function () {
                if (root.offsetTrackWindow !== w)
                    return;
                root.refreshOffsetFromTrackedWindow();
            });
            w.interactiveMoveResizeFinished.connect(function () {
                if (root.offsetTrackWindow === w) {
                    root.refreshOffsetFromTrackedWindow();
                    // Keep mode + last offset so the next placement still shows edges.
                    root.offsetTrackWindow = null;
                }
            });
        } catch (e2) {
            console.log("InfiniteCrosshair hook move/resize failed", e2);
        }
    }

    function hookAllWindowsMoveResize() {
        const list = Workspace.stackingOrder;
        if (!list)
            return;
        for (let i = 0; i < list.length; ++i)
            root.hookWindowMoveResize(list[i]);
    }

    // Primary vertical (cursor)
    Rectangle {
        visible: root.crosshairEnabled
        x: root.linePosX - Math.max(1, root.lineWidth) / 2
        y: 0
        width: Math.max(1, root.lineWidth)
        height: parent.height
        color: root.lineColor
        opacity: root.lineOpacity
        z: 9999
    }

    // Primary horizontal (cursor)
    Rectangle {
        visible: root.crosshairEnabled
        x: 0
        y: root.linePosY - Math.max(1, root.lineWidth) / 2
        width: parent.width
        height: Math.max(1, root.lineWidth)
        color: root.lineColor
        opacity: root.lineOpacity
        z: 9999
    }

    // Second vertical guide (manual offset, or automagic nearest frame edge)
    Rectangle {
        visible: root.showOffsetVertical
        x: root.offsetVerticalPosX - Math.max(1, root.lineWidth) / 2
        y: 0
        width: Math.max(1, root.lineWidth)
        height: parent.height
        color: root.offsetVerticalColor
        opacity: root.lineOpacity
        z: 9998
    }

    // Second horizontal guide (manual offset, or automagic nearest frame edge)
    Rectangle {
        visible: root.showOffsetHorizontal
        x: 0
        y: root.offsetHorizontalPosY - Math.max(1, root.lineWidth) / 2
        width: parent.width
        height: Math.max(1, root.lineWidth)
        color: root.offsetHorizontalColor
        opacity: root.lineOpacity
        z: 9998
    }

    // Inch ticks (defaults ON; independent of config poller success)
    Item {
        id: tickOrigin
        x: root.linePosX
        y: root.linePosY
        visible: root.crosshairEnabled && root.showInchTicks && root.tickStepPx > 0.5
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
        // Visual-only: do not touch Window.visible (see buildId toggle1 / BUG-01).
        root.crosshairEnabled = !root.crosshairEnabled;
        console.log("InfiniteCrosshair toggled",
                    root.crosshairEnabled ? "ON" : "OFF",
                    "build=", root.buildId);
    }

    // System Settings → Keyboard → Shortcuts → KWin (also listed in script Configure).
    ShortcutHandler {
        name: root.toggleShortcutName
        text: root.toggleShortcutName
        sequence: root.toggleShortcutDefault
        onActivated: root.toggleCrosshair()
    }

    ShortcutHandler {
        name: root.toggleOffsetVShortcutName
        text: root.toggleOffsetVShortcutName
        sequence: root.toggleOffsetVShortcutDefault
        onActivated: root.toggleOffsetVertical()
    }

    ShortcutHandler {
        name: root.toggleOffsetHShortcutName
        text: root.toggleOffsetHShortcutName
        sequence: root.toggleOffsetHShortcutDefault
        onActivated: root.toggleOffsetHorizontal()
    }

    ShortcutHandler {
        name: root.captureOffsetShortcutName
        text: root.captureOffsetShortcutName
        sequence: root.captureOffsetShortcutDefault
        onActivated: root.captureBorderOffset()
    }

    ShortcutHandler {
        name: root.clearOffsetShortcutName
        text: root.clearOffsetShortcutName
        sequence: root.clearOffsetShortcutDefault
        onActivated: root.clearOffsetGuides()
    }

    Component.onCompleted: {
        seedFromReadConfig();
        kickConfigPoll();
        // Caption / client mapping can lag one frame after the surface maps.
        Qt.callLater(root.hideOverlayFromWmLists);
        hideClaimRetry.restart();
        Qt.callLater(root.hookAllWindowsMoveResize);

        const s = root.screenUnderCursor();
        const g = s ? s.geometry : null;
        console.log("InfiniteCrosshair ready build=", root.buildId,
                    "virtual=", width, "x", height,
                    "screen=", g ? (g.width + "x" + g.height) : "n/a",
                    "rgb=", root.lineColorR + "," + root.lineColorG + "," + root.lineColorB,
                    "lineWidth=", root.lineWidth,
                    "opacity=", root.lineOpacity,
                    "ticks=", root.showInchTicks,
                    "diagIn=", root.screenDiagonalInches,
                    "ppi=", root.pixelsPerInch.toFixed(2),
                    "tickStep=", root.tickStepPx.toFixed(2),
                    "autoOffset=", root.autoOffsetOnMove,
                    "offV=", root.offsetVerticalEnabled, root.offsetVerticalOffset,
                    "offH=", root.offsetHorizontalEnabled, root.offsetHorizontalOffset,
                    "enabled=", root.crosshairEnabled,
                    "toggle=", root.toggleShortcutDefault,
                    "capV=", root.toggleOffsetVShortcutDefault,
                    "capH=", root.toggleOffsetHShortcutDefault,
                    "capture=", root.captureOffsetShortcutDefault);
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
