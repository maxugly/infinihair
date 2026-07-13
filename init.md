\# Technical Report: Implementing a Dynamic Crosshair Overlay in Krita

\*\*Date:\*\* July 13, 2026  
\*\*Subject:\*\* Native C++ Plugin Development for Infinite Cursor Guides  
\*\*Goal:\*\* Create a vertical and horizontal line ("crosshair") that follows the mouse cursor with zero latency in Krita.

\---

\#\# 1\. Executive Summary  
Krita does not natively support infinite dynamic guides that follow the cursor. While Python plugins exist, they suffer from \*\*latency and stutter\*\* due to the Python Global Interpreter Lock (GIL) and event loop overhead. To achieve "buttery smooth" performance comparable to native C++ applications (like those built with JUCE), a \*\*native C++ plugin\*\* is required. This approach hooks directly into Krita’s rendering engine (\`KisCanvasDecoration\`) to draw overlays in the same pass as the canvas, ensuring synchronization with zoom, pan, and rotation.

\---

\#\# 2\. Technical Architecture

\#\#\# The Core Concept: \`KisCanvasDecoration\`  
Krita uses a decoration system to draw non-destructive elements (grids, assistants, guides) on top of the canvas.  
\*   \*\*Class to Inherit:\*\* \`KisCanvasDecoration\`  
\*   \*\*Rendering Method:\*\* \`draw(QPainter \&painter, const KoViewConverter \&converter)\`  
\*   \*\*Performance:\*\* Runs in the native GUI thread, bypassing Python entirely.

\#\#\# The Challenge: Coordinate Systems  
The plugin must distinguish between:  
1\.  \*\*Widget Coordinates:\*\* Pixel position on your screen (where the mouse is).  
2\.  \*\*Document Coordinates:\*\* Position within the image (affected by zoom/pan).  
\*For a cursor crosshair, you typically draw in \*\*Widget Coordinates\*\* relative to the visible area, ensuring the lines always span the full screen regardless of zoom level.\*

\---

\#\# 3\. Implementation Steps

\#\#\# Phase 1: Environment Setup  
1\.  \*\*Clone Source:\*\* Download the Krita source code from the official Git repository.  
2\.  \*\*Build Dependencies:\*\* Install Qt5/6, KDE Frameworks (KF5/6), and CMake (min version 3.19).  
3\.  \*\*Directory Structure:\*\* Create a new folder in \`plugins/extensions/crosshair\_overlay/\`.

\#\#\# Phase 2: Core Code Logic

\#\#\#\# A. The Decorator (\`CrosshairDecorator.cpp\`)  
This class handles the drawing. It must be lightweight.

\`\`\`cpp  
void CrosshairDecorator::draw(QPainter \&painter, const KoViewConverter \&converter) {  
    painter.save();  
    painter.setPen(QPen(Qt::red, 1.0, Qt::SolidLine)); // High contrast color  
      
    // Get the currently visible area of the canvas (Widget Coordinates)  
    QRectF visibleRect \= converter.visibleArea();  
      
    // Draw Vertical Line (Top to Bottom of View)  
    painter.drawLine(QPointF(m\_cursorPos.x(), visibleRect.top()),   
                     QPointF(m\_cursorPos.x(), visibleRect.bottom()));  
      
    // Draw Horizontal Line (Left to Right of View)  
    painter.drawLine(QPointF(visibleRect.left(), m\_cursorPos.y()),   
                     QPointF(visibleRect.right(), m\_cursorPos.y()));  
      
    painter.restore();  
}  
\`\`\`

\#\#\#\# B. The Plugin Interface (\`CrosshairPlugin.cpp\`)  
This class loads the decorator and captures mouse events.

1\.  \*\*Initialization:\*\* In \`setup()\`, instantiate \`CrosshairDecorator\` and add it to the canvas via \`canvasBase()-\>addCanvasDecoration()\`.  
2\.  \*\*Event Filtering:\*\* Install an \`eventFilter\` on the canvas widget to intercept \`QEvent::MouseMove\`.  
3\.  \*\*Update Loop:\*\* On every mouse move, update the \`m\_cursorPos\` variable in the decorator and call \`updateDecoration()\` to trigger a repaint.

\#\#\# Phase 3: Build Configuration (\`CMakeLists.txt\`)  
You must define the plugin in CMake to link against Krita’s internal libraries.

\`\`\`cmake  
krita\_add\_plugin(crosshair\_overlay)  
target\_link\_libraries(crosshair\_overlay PRIVATE kritaui kritawidgets Qt5::Widgets)  
\`\`\`  
\*Note: Exact target names may vary by Krita version (e.g., \`KritaUI\` vs \`kritaui\`).\*

\---

\#\# 4\. Critical Considerations

\#\#\# Performance Optimization  
\*   \*\*Signal Compression:\*\* Mouse events fire hundreds of times per second. Use \`KisSignalCompressor\` (as seen in Krita’s source) to throttle updates if the system is under heavy load, preventing UI freeze.  
\*   \*\*Minimal Repaint:\*\* Ensure \`updateDecoration()\` only invalidates the decoration layer, not the entire image canvas.

\#\#\# Fragility & Maintenance  
\*   \*\*Internal API:\*\* C++ plugins rely on internal headers (\`libs/ui/...\`) which are not guaranteed to be stable between major versions. A plugin built for Krita 5.2 may break in 5.3.  
\*   \*\*Distribution:\*\* Unlike Python plugins, C++ plugins cannot be simply "dropped" into a folder by users. They must be \*\*compiled\*\* against the specific version of Krita the user is running, or distributed as source code for the user to build.

\---

\#\# 5\. Conclusion & Recommendation  
Writing this plugin is a \*\*medium-difficulty C++ task\*\* requiring familiarity with Qt and CMake.  
\*   \*\*Feasibility:\*\* High. The architecture (\`KisCanvasDecoration\`) explicitly supports this use case.  
\*   \*\*Result:\*\* A lag-free, professional-grade tool that feels native to the application.  
\*   \*\*Alternative:\*\* If compilation is a barrier, continue using \*\*Microsoft PowerToys\*\* (Windows) or \*\*xScope\*\* (Mac), which achieve the same visual result via system-level overlays, bypassing the need for plugin development entirely.

Implementing this in \*\*KWin\*\* (the KDE Window Manager) is actually \*\*easier and more robust\*\* than writing a C++ plugin for Krita.

Because KWin controls the entire desktop composition, a \*\*KWin Script\*\* (written in JavaScript/QtQML) can draw an overlay that sits above \*all\* windows (including full-screen games and Krita) with \*\*zero performance impact\*\* on the applications themselves. The rendering is handled by the compositor, ensuring it is "buttery smooth" and perfectly locked to the cursor.

\#\#\# Why KWin is the Ideal Solution  
1\.  \*\*Global Overlay\*\*: Unlike a Krita plugin, a KWin script works everywhere (Firefox, Krita, Games).  
2\.  \*\*Native Performance\*\*: KWin scripts run in the compositor's thread (C++ backed), avoiding the Python GIL entirely.  
3\.  \*\*Coordinate Access\*\*: KWin provides direct access to global cursor coordinates (\`workspace().cursorPos\`) without complex event filtering.  
4\.  \*\*No Compilation\*\*: You do not need to compile C++ code. You can write the script in JavaScript/QML and load it instantly.

\#\#\# Existing Solution: "Mouse Strip"  
There is already a KWin script called \*\*Mouse Strip\*\* that draws a highlight around the cursor. While it draws a box rather than infinite lines, it proves the architecture works perfectly for your use case. You could fork this script and modify the QML to draw two thin lines instead of a box.

\#\#\# How to Implement "Infinite Crosshair" in KWin  
You would create a simple KWin Effect script.

\#\#\#\# 1\. The Logic (JavaScript)  
The script tracks the cursor position and tells the QML component where to draw.  
\`\`\`javascript  
// main.js  
var workspace \= workspace; // Global KWin workspace object  
var crosshairElement; 

function init() {  
    // Load the QML component for drawing  
    crosshairElement \= workspace.loadEffectComponent("crosshair.qml");  
      
    // Connect to cursor move signal  
    workspace.cursorMoved.connect(function(pos) {  
        // Update the QML property with new X, Y  
        crosshairElement.propertyMap.cursorX \= pos.x;  
        crosshairElement.propertyMap.cursorY \= pos.y;  
        // Trigger repaint  
        workspace.triggerPaint();  
    });  
}  
\`\`\`

\#\#\#\# 2\. The Rendering (QML)  
The QML file draws the lines directly on the screen buffer.  
\`\`\`qml  
// crosshair.qml  
import QtQuick 2.0  
import org.kde.kwin 2.0

Item {  
    id: crosshair  
    property int cursorX: 0  
    property int cursorY: 0

    Rectangle {  
        // Vertical Line  
        x: crosshair.cursorX  
        y: 0  
        width: 1  
        height: screen.height  
        color: "red"  
        opacity: 0.8  
    }

    Rectangle {  
        // Horizontal Line  
        x: 0  
        y: crosshair.cursorY  
        width: screen.width  
        height: 1  
        color: "red"  
        opacity: 0.8  
    }  
}  
\`\`\`

\#\#\# Installation Steps  
1\.  Create a folder \`\~/.local/share/kwin/scripts/crosshair/\`.  
2\.  Add a \`metadata.json\` (defining it as a KWin Script).  
3\.  Add \`main.js\` and \`contents/ui/main.qml\` with the logic above.  
4\.  Enable it via \*\*System Settings\*\* \> \*\*Window Management\*\* \> \*\*KWin Scripts\*\*.

\#\#\# Conclusion  
This is the \*\*superior approach\*\*. It gives you the native C++ performance you experienced in JUCE, requires no compilation, and works globally across your entire KDE desktop. If you are comfortable with JavaScript/QML, you can prototype this in under an hour.

\# Agent Prompt: KWin "Infinite Crosshair" Script Setup

\*\*Role:\*\* You are an expert KDE Plasma developer specializing in KWin scripting (JavaScript/QML).  
\*\*Task:\*\* Initialize a complete, installable KWin Script project that renders a full-screen vertical and horizontal crosshair following the mouse cursor.  
\*\*Target Environment:\*\* KDE Plasma 6 (Wayland/X11).

\---

\#\# 1\. Project Initialization & Directory Structure  
Execute the following shell commands to create the strict KPackage directory structure required by KWin.

\`\`\`bash  
\# 1\. Create root project directory  
mkdir \-p kwin-crosshair/contents/code  
mkdir \-p kwin-crosshair/contents/ui

\# 2\. Initialize Git repository  
cd kwin-crosshair  
git init  
echo "README.md" \> .gitignore  
echo "\*.swp" \>\> .gitignore

\# 3\. Create the file skeleton  
touch metadata.json  
touch contents/code/main.js  
touch contents/ui/Crosshair.qml  
\`\`\`

\---

\#\# 2\. File Implementation Details  
Generate the content for the following three files exactly as specified.

\#\#\# A. \`metadata.json\`  
\*Defines the plugin identity and entry point.\*  
\`\`\`json  
{  
    "KPlugin": {  
        "Name": "Infinite Crosshair",  
        "Description": "Renders full-screen vertical and horizontal lines following the cursor.",  
        "Icon": "preferences-desktop-display",  
        "Authors": \[  
            {  
                "Name": "User",  
                "Email": "user@example.com"  
            }  
        \],  
        "Id": "kwin-crosshair",  
        "Version": "1.0",  
        "License": "GPLv3",  
        "EnabledByDefault": false  
    },  
    "X-Plasma-API": "declarativescript",  
    "X-Plasma-MainScript": "ui/Crosshair.qml",  
    "KPackageStructure": "KWin/Script"  
}  
\`\`\`

\#\#\# B. \`contents/ui/Crosshair.qml\`  
\*The rendering engine. Uses \`org.kde.kwin\` to draw directly on the compositor surface.\*  
\`\`\`qml  
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
        x: root.cursorPos.x \- 0.5 // Center on pixel  
        y: 0  
        width: 1  
        height: parent.height  
        color: "\#FF0000" // Red  
        opacity: 0.8  
        z: 9999 // Ensure top-most rendering  
    }

    // Horizontal Line  
    Rectangle {  
        x: 0  
        y: root.cursorPos.y \- 0.5 // Center on pixel  
        width: parent.width  
        height: 1  
        color: "\#FF0000" // Red  
        opacity: 0.8  
        z: 9999  
    }

    // Optimization: Only repaint when cursor moves significantly or on timer  
    // KWin declarative scripts automatically bind to property changes  
    Connections {  
        target: workspace  
        function onCursorPosChanged() {  
            // Trigger update implicitly via property binding  
            root.cursorPos \= workspace.cursorPos;  
        }  
    }  
}  
\`\`\`

\#\#\# C. \`contents/code/main.js\`  
\*Logic controller (optional for this simple case, but required for robust lifecycle management).\*  
\`\`\`javascript  
// main.js  
// In a declarative script, the QML file handles rendering.  
// This file manages lifecycle if complex logic is needed later.

function init() {  
    console.log("Crosshair Script Initialized");  
}

function configChanged() {  
    // Handle config updates if a config UI is added later  
}  
\`\`\`

\---

\#\# 3\. Installation & Verification  
Provide the agent with the exact commands to build, install, and activate the script locally.

\`\`\`bash  
\# 1\. Install the script using kpackagetool6  
\# Run this from the directory CONTAINING the kwin-crosshair folder  
kpackagetool6 \--type=KWin/Script \--install ./kwin-crosshair

\# 2\. Verify installation  
kpackagetool6 \--type=KWin/Script \--list | grep "kwin-crosshair"

\# 3\. Enable the script  
\# Method A: Via Command Line (Immediate)  
kwriteconfig6 \--file kwinrc \--group Plugins \--key kwin-crosshairEnabled true  
qdbus6 org.kde.KWin /KWin reconfigure

\# Method B: Via GUI (User Action)  
\# Open "System Settings" \-\> "Window Management" \-\> "KWin Scripts"  
\# Check the box next to "Infinite Crosshair" and click Apply.  
\`\`\`

\---

\#\# 4\. Troubleshooting & Debugging  
If the script fails to load or render:

1\.  \*\*Check Logs:\*\*  
    \`\`\`bash  
    journalctl \--user \-u plasma-kwin\_wayland.service \-f  
    \# OR for X11  
    journalctl \--user \-u plasma-kwin\_x11.service \-f  
    \`\`\`  
    \*Look for errors mentioning "kwin-crosshair" or "qml".\*

2\.  \*\*Common Errors:\*\*  
    \*   \*"Metadata invalid"\*: Ensure \`metadata.json\` is valid JSON (no trailing commas).  
    \*   \*"QML Component Error"\*: Ensure \`import org.kde.kwin\` is present and Plasma 6 is installed.  
    \*   \*Lines not visible\*: The \`z\` index might be occluded. Ensure \`z: 9999\` is set in QML.

3\.  \*\*Uninstall/Reset:\*\*  
    \`\`\`bash  
    kpackagetool6 \--type=KWin/Script \--remove kwin-crosshair  
    \`\`\`

\---

\#\# 5\. Deliverable Checklist  
\- \[ \] Directory structure matches KPackage spec.  
\- \[ \] \`metadata.json\` has correct \`X-Plasma-API\` set to \`declarativescript\`.  
\- \[ \] QML file imports \`org.kde.kwin\` and binds to \`workspace.cursorPos\`.  
\- \[ \] Script installs without \`kpackagetool6\` errors.  
\- \[ \] Crosshair appears instantly upon enabling in System Settings.

The next prompt should instruct the agent to \*\*refine the QML implementation\*\* to ensure high-performance rendering and correct coordinate binding, as the previous skeleton lacked the specific \`Connections\` logic required to trigger repaints efficiently in Plasma 6\.

Here is the precise follow-up prompt:

\*\*\*

\*\*Prompt:\*\*  
"Refine the \`contents/ui/Crosshair.qml\` file to ensure \*\*zero-latency rendering\*\* in Plasma 6\. Specifically:  
1\.  \*\*Optimize Repaints\*\*: Replace generic polling with a direct \`Connections\` block targeting \`workspace\` to listen for \`cursorPosChanged\` (or the equivalent signal in Plasma 6\) to trigger updates \*only\* when the mouse moves.  
2\.  \*\*Coordinate Precision\*\*: Ensure the \`cursorPos\` property correctly handles global screen coordinates vs. local QML item coordinates, accounting for multi-monitor setups where \`x\` might exceed screen width.  
3\.  \*\*Visual Polish\*\*: Add a small configuration option in \`metadata.json\` (and corresponding QML property) to toggle the line \*\*color\*\* and \*\*thickness\*\* without recompiling.  
4\.  \*\*Debugging\*\*: Add a \`Component.onCompleted\` log to verify the script successfully binds to the workspace cursor signal.

Provide the updated \`Crosshair.qml\` and the modified \`metadata.json\` with the new config entries."

\*\*\*

\#\#\# Why this is the critical next step:  
\*   \*\*Performance\*\*: Without explicit signal connections, the script might rely on the QML engine's default binding evaluation, which could introduce frame drops. Explicitly binding to the cursor signal ensures the compositor wakes up \*only\* when necessary.  
\*   \*\*Multi-Monitor Support\*\*: Naive implementations often break on multi-monitor setups where cursor X/Y coordinates are global (e.g., X=4000 on a dual 1080p setup). The QML must handle this gracefully.  
\*   \*\*Usability\*\*: Hardcoded red lines are rarely what users want long-term. Adding config options makes the script actually usable for daily work.

The next logical step is to \*\*add a Configuration Interface\*\*.

Currently, your script has hardcoded red lines. To make it a usable, polished tool, you need to allow the user to customize the \*\*color\*\*, \*\*thickness\*\*, and \*\*opacity\*\* via the standard System Settings GUI, and ensure the script handles \*\*multi-monitor setups\*\* correctly (where the cursor X coordinate can exceed a single screen's width).

Here is the precise prompt to give the agent next:

\*\*\*

\*\*Prompt:\*\*  
"Update the KWin Crosshair project to include a \*\*Configuration UI\*\* and \*\*Multi-Monitor Support\*\*.

1\.  \*\*Create Configuration Schema\*\*:  
    \*   Add \`contents/config/main.xml\` defining three options: \`LineColor\` (color, default red), \`LineWidth\` (int, default 1), and \`Opacity\` (double, default 0.8).  
    \*   Update \`metadata.json\` to reference this config file so the 'Configure' button appears in System Settings.

2\.  \*\*Create Configuration UI\*\*:  
    \*   Add \`contents/config/main.ui\` (Qt Designer XML format) with three controls: a \`KColorButton\` (named \`kcfg\_LineColor\`), a \`QSpinBox\` (named \`kcfg\_LineWidth\`), and a \`QDoubleSpinBox\` (named \`kcfg\_Opacity\`).

3\.  \*\*Refine QML Logic\*\*:  
    \*   Update \`contents/ui/Crosshair.qml\` to read these config values using \`KWin.readConfig()\`.  
    \*   Ensure the vertical line spans the \*\*full virtual screen height\*\* and the horizontal line spans the \*\*full virtual screen width\*\* (handling multi-monitor setups where coordinates are global, e.g., X \> 1920).  
    \*   Use the \`cursorPosChanged\` signal from \`workspace\` to trigger updates efficiently.

4\.  \*\*Verification\*\*:  
    \*   Provide the exact \`kpackagetool6\` command to upgrade the existing installation.  
    \*   Explain how to verify the new config options appear in \*\*System Settings \> Window Management \> KWin Scripts \> Infinite Crosshair \> Configure\*\*."

\*\*\*

\#\#\# Why this is the next step:  
\*   \*\*Usability\*\*: Hardcoded values make a plugin difficult to daily-drive. A config UI is standard for any serious KWin script.  
\*   \*\*Correctness\*\*: Naive QML often draws lines relative to a single screen (\`Screen.width\`). In a multi-monitor setup, the cursor might be at X=3000, but a single screen is only 1920 wide. The lines must span the entire \*\*virtual desktop geometry\*\* to look "infinite."  
\*   \*\*Integration\*\*: This step teaches you how to bridge QML, KWin's config system (\`main.xml\`), and Qt Widgets (\`main.ui\`), which is the most complex part of KWin scripting.

The next logical step is to \*\*package the script for distribution\*\* and add a \*\*reload mechanism\*\* so you can test changes without logging out.

Here is the precise prompt to give the agent:

\*\*\*

\*\*Prompt:\*\*  
"Finalize the KWin Crosshair project for \*\*distribution and easy testing\*\*.

1\.  \*\*Create a Packaging Script\*\*:  
    \*   Write a Bash script (\`package.sh\`) that:  
        \*   Validates the \`metadata.json\` syntax.  
        \*   Creates a \`.kwinscript\` file (which is just a renamed \`.tar.gz\` or \`.zip\` of the project directory) suitable for uploading to the KDE Store or sharing.  
        \*   Ensures the directory structure is clean (excludes \`.git\`, \`\*.swp\`).

2\.  \*\*Create a Reload/Debug Script\*\*:  
    \*   Write a Bash script (\`reload.sh\`) that:  
        \*   Unloads the current script instance via \`qdbus6 org.kde.KWin /Scripting unloadScript kwin-crosshair\`.  
        \*   Re-installs the local version using \`kpackagetool6 \--type=KWin/Script \--upgrade ./kwin-crosshair\`.  
        \*   Triggers a KWin reconfiguration (\`qdbus6 org.kde.KWin /KWin reconfigure\`) or restarts the script specifically.  
        \*   Tails the KWin log (\`journalctl \--user \-u plasma-kwin\_wayland.service \-f\`) for 5 seconds to show any startup errors.

3\.  \*\*Add a README.md\*\*:  
    \*   Include installation instructions (both manual \`kpackagetool6\` and via '.kwinscript' file).  
    \*   Document the configuration options (Color, Width, Opacity).  
    \*   Explain how to use the \`reload.sh\` script for development.  
    \*   Add a troubleshooting section for common issues (e.g., 'Lines not visible', 'Config not saving').

4\.  \*\*Verification\*\*:  
    \*   Provide the commands to make the scripts executable (\`chmod \+x\`).  
    \*   Show how to run the packaging script to generate \`crosshair.kwinscript\`."

\*\*\*

\#\#\# Why this is the final step:  
\*   \*\*Workflow Efficiency\*\*: Manually running \`kpackagetool6\` and hunting through logs is slow. A \`reload.sh\` script turns the edit-test cycle into a single command, crucial for tweaking QML visuals.  
\*   \*\*Shareability\*\*: A \`.kwinscript\` file is the standard distribution format for KDE. It allows anyone to install your tool with a single click from the System Settings GUI.  
\*   \*\*Documentation\*\*: A \`README.md\` ensures that your future self (or other users) knows how to install, configure, and debug the tool without reverse-engineering the code.

A \`constitution.md\` for your \*\*KWin Crosshair\*\* project would serve as the "single source of truth" for the project's architecture, coding standards, and design principles. It ensures that any future updates (by you or an AI agent) remain consistent with your original vision of "buttery smooth" performance and native integration.

Here is what a tailored \*\*\`constitution.md\`\*\* would look like for this specific project:

\*\*\*

\# Project Constitution: KWin Infinite Crosshair

\*\*Version:\*\* 1.0.0    
\*\*Date:\*\* July 13, 2026    
\*\*Status:\*\* Active

\#\# 1\. Core Philosophy  
\*   \*\*Zero Latency is Non-Negotiable:\*\* The crosshair must feel "locked" to the cursor. Any implementation that introduces perceptible input lag (e.g., Python scripts, polling loops) is strictly prohibited.  
\*   \*\*Native Compositor Integration:\*\* The solution must leverage KWin’s native rendering pipeline (\`org.kde.kwin\` QML module) to draw directly on the compositor surface, bypassing application-specific overhead.  
\*   \*\*Global Utility:\*\* The tool must function identically across all windows, screens, and applications (Krita, games, browsers) without modification.

\#\# 2\. Technical Standards

\#\#\# A. Architecture  
\*   \*\*Language:\*\* QML (QtQuick) for rendering; JavaScript only for lightweight logic if absolutely necessary. \*\*No C++ compilation required\*\* for the core effect.  
\*   \*\*API:\*\* Must use \`X-Plasma-API: declarativescript\` in \`metadata.json\`.  
\*   \*\*Entry Point:\*\* The \`contents/ui/Crosshair.qml\` file is the single source of truth for rendering.  
\*   \*\*Event Handling:\*\* Must rely exclusively on \`workspace.cursorPosChanged\` signals. \*\*Polling\*\* (e.g., \`Timer\` loops to check position) is forbidden.

\#\#\# B. Coordinate System  
\*   \*\*Global Virtual Desktop:\*\* All coordinates must be treated as \*\*global virtual desktop coordinates\*\*, not local screen coordinates.  
  \*   \*Reasoning:\* This ensures lines span correctly across multi-monitor setups where cursor X/Y can exceed a single screen’s resolution (e.g., X \> 3840).  
\*   \*\*Line Spanning:\*\*  
  \*   \*\*Vertical Line:\*\* Must span from \`y=0\` to \`y=virtualDesktop.height\`.  
  \*   \*\*Horizontal Line:\*\* Must span from \`x=0\` to \`x=virtualDesktop.width\`.

\#\#\# C. Performance Constraints  
\*   \*\*Repaint Trigger:\*\* The scene must only repaint when \`workspace.cursorPos\` changes.  
\*   \*\*Z-Index:\*\* The overlay must use \`z: 9999\` (or higher) to ensure it renders above all windows, including full-screen applications.  
\*   \*\*Opacity/Blending:\*\* Use simple \`Rectangle\` items with \`opacity\` rather than complex shaders to minimize GPU load.

\#\# 3\. Configuration & Extensibility  
\*   \*\*Dynamic Config:\*\* All visual properties (Color, Width, Opacity) must be read via \`KWin.readConfig()\` at runtime.  
\*   \*\*No Hardcoding:\*\* Visual values must \*\*never\*\* be hardcoded in QML. They must default to sensible values (e.g., Red, 1px, 0.8) but be overridable by \`contents/config/main.xml\`.  
\*   \*\*Schema Definition:\*\* Configuration options must be strictly defined in \`contents/config/main.xml\` using standard KDE config types (\`Color\`, \`Int\`, \`Double\`).

\#\# 4\. Project Structure (KPackage Spec)  
The directory structure is immutable and must follow the KWin Script specification:  
\`\`\`text  
kwin-crosshair/  
├── metadata.json            \# Plugin identity & API declaration  
├── contents/  
│   ├── config/  
│   │   ├── main.xml         \# Config schema (XSD)  
│   │   └── main.ui          \# Config UI (Qt Widgets)  
│   ├── ui/  
│   │   └── Crosshair.qml    \# Main rendering component  
│   └── code/  
│       └── main.js          \# (Optional) Lifecycle logic  
└── package.sh               \# Build script  
\`\`\`

\#\# 5\. Workflow Rules  
\*   \*\*Testing:\*\* Changes must be tested on both \*\*X11\*\* and \*\*Wayland\*\* sessions.  
\*   \*\*Reloading:\*\* Use the \`reload.sh\` script to unload/reload the effect without restarting the Plasma session.  
\*   \*\*Distribution:\*\* The final artifact must be a \`.kwinscript\` (tar.gz) file generated by \`package.sh\`.

\#\# 6\. Prohibited Patterns  
\*   ❌ \*\*Python Scripts:\*\* Do not attempt to implement this as a Python KWin script.  
\*   ❌ \*\*C++ Plugins:\*\* Do not create a C++ plugin unless QML performance is proven insufficient (highly unlikely).  
\*   ❌ \*\*External Overlays:\*\* Do not rely on external tools (e.g., \`xshape\`, \`xdotool\`) for the core implementation.  
\*   ❌ \*\*Timer Polling:\*\* Do not use \`Timer { interval: 16; ... }\` to track the mouse.

\*\*\*

\#\#\# How to Use This File  
1\.  \*\*Save\*\* this as \`constitution.md\` in the root of your project directory.  
2\.  \*\*Reference\*\* it in your prompts to AI agents (e.g., \*"Check your proposed QML code against Section 2.B of the constitution.md"\*).  
3\.  \*\*Enforce\*\* it during code reviews or self-checks before committing changes.

Here is what a \*\*Dox-style \`agents.md\`\*\* hierarchy would look like for your KWin Crosshair project.

In the "Dox" pattern (popularized by GitHub Copilot and Cursor), you place a root \`agents.md\` for global context, and then specific \`agents.md\` files in subdirectories to override or refine instructions for agents working in those specific contexts.

\#\#\# 1\. Root: \`agents.md\`  
\*\*Location:\*\* \`./agents.md\`  
\*\*Purpose:\*\* Defines the global persona, the "Constitution," and the high-level architecture. It ensures any agent knows this is a \*\*Zero-Latency KWin Script\*\* project.

\`\`\`markdown  
\---  
name: kwin\_crosshair\_architect  
description: Expert KDE Plasma developer specializing in zero-latency KWin scripting.  
\---

\# Role  
You are the lead architect for the \*\*KWin Infinite Crosshair\*\* project. Your goal is to maintain "buttery smooth" (60fps+) performance by leveraging native KWin compositor APIs.

\# Project Context  
\- \*\*Target:\*\* KDE Plasma 6 (Wayland/X11).  
\- \*\*Core Constraint:\*\* \*\*Zero Latency\*\*. Any solution introducing input lag (Python, polling loops) is forbidden.  
\- \*\*Architecture:\*\* Declarative KWin Script (\`declarativescript\`).  
\- \*\*Tech Stack:\*\* QML (QtQuick 2), JavaScript (ECMAScript 6), KConfig (XML).

\# Directories & Responsibilities  
\- \`contents/ui/\`: \*\*Rendering Engine\*\*. Agents here focus on QML performance, \`workspace\` bindings, and visual fidelity.  
\- \`contents/config/\`: \*\*User Interface\*\*. Agents here focus on KConfigXT schemas and Qt Widgets UI for settings.  
\- \`contents/code/\`: \*\*Lifecycle Logic\*\*. Agents here handle initialization and teardown (minimal logic preferred).  
\- \`scripts/\`: \*\*DevOps\*\*. Agents here manage packaging (\`kpackagetool6\`) and reload workflows.

\# Global Standards (The Constitution)  
1\.  \*\*Signal-Driven:\*\* Never poll \`cursorPos\`. Use \`workspace.cursorPosChanged\`.  
2\.  \*\*Global Coordinates:\*\* All drawing must respect the virtual desktop geometry (multi-monitor safe).  
3\.  \*\*No Hardcoding:\*\* Visuals (Color, Width) must come from \`KWin.readConfig()\`.  
4\.  \*\*KPackage Spec:\*\* Strictly adhere to the KWin Script directory structure.

\# Commands  
\- \`build\`: \`kpackagetool6 \--type=KWin/Script \--install .\`  
\- \`reload\`: \`./scripts/reload.sh\`  
\- \`package\`: \`./scripts/package.sh\`  
\`\`\`

\---

\#\#\# 2\. UI Directory: \`contents/ui/agents.md\`  
\*\*Location:\*\* \`./contents/ui/agents.md\`  
\*\*Purpose:\*\* Overrides the root agent to focus purely on \*\*QML rendering optimization\*\*, coordinate math, and visual properties.

\`\`\`markdown  
\---  
name: qml\_rendering\_specialist  
description: QML expert optimized for KWin compositor overlays and high-frequency updates.  
\---

\# Context  
You are working in the \`contents/ui/\` directory. Your sole responsibility is the \`Crosshair.qml\` file.

\# Technical Constraints  
\- \*\*Import:\*\* Must use \`import org.kde.kwin\` and \`import QtQuick\`.  
\- \*\*Performance:\*\*   
  \- Use \`Rectangle\` primitives (GPU accelerated).  
  \- Set \`z: 9999\` to ensure top-most rendering.  
  \- Bind directly to \`workspace.cursorPos\`. Do not use \`Behavior\` or \`NumberAnimation\` on position (causes lag).  
\- \*\*Coordinates:\*\*   
  \- \`x\` and \`y\` are \*\*Global Virtual Desktop\*\* coordinates.  
  \- Lines must span \`Screen.width\`/\`Screen.height\` of the \*entire\* virtual desktop, not just the current monitor.

\# Task Guidelines  
\- When modifying \`Crosshair.qml\`, ensure \`opacity\` and \`color\` are read from config.  
\- If adding debug visuals, wrap them in a \`debug\` property guarded by \`if (debugMode)\`.  
\- \*\*Never\*\* introduce \`Timer\` elements for position updates.

\# Example Pattern  
\`\`\`qml  
property point pos: workspace.cursorPos  
Rectangle { x: pos.x; y: 0; width: 1; height: virtualDesktop.height }  
\`\`\`  
\`\`\`

\---

\#\#\# 3\. Config Directory: \`contents/config/agents.md\`  
\*\*Location:\*\* \`./contents/config/agents.md\`  
\*\*Purpose:\*\* Focuses on \*\*KConfigXT schemas\*\* and \*\*Qt Widgets\*\* for the settings UI.

\`\`\`markdown  
\---  
name: kconfig\_ui\_engineer  
description: Specialist in KDE KConfigXT schemas and Qt Widgets configuration dialogs.  
\---

\# Context  
You are working in \`contents/config/\`. You define how users customize the crosshair.

\# File Responsibilities  
1\.  \*\*\`main.xml\`\*\*: Defines the schema (\`\<entry\>\`, \`\<label\>\`, \`\<default\>\`).   
    \- Types: \`Color\`, \`Int\`, \`Double\`.  
    \- Keys must match \`kcfg\_\<KeyName\>\` in the UI file.  
2\.  \*\*\`main.ui\`\*\*: Qt Designer XML.  
    \- Widgets must be named exactly \`kcfg\_\<KeyName\>\`.  
    \- Use \`KColorButton\`, \`QSpinBox\`, \`QDoubleSpinBox\`.

\# Standards  
\- \*\*Naming:\*\* Config keys must be PascalCase (e.g., \`LineColor\`, \`LineWidth\`).  
\- \*\*Defaults:\*\* Sensible defaults are mandatory (e.g., Red, 1px, 0.8 Opacity).  
\- \*\*Integration:\*\* Ensure \`metadata.json\` has \`"X-KDE-ConfigModule": "kwin/effects/configs/kcm\_kwin4\_genericscripted"\`.

\# Validation  
\- After editing \`main.xml\`, verify the structure against the KConfigXT XSD.  
\- Ensure \`main.ui\` object names strictly match \`main.xml\` entry names.  
\`\`\`

\---

\#\#\# 4\. Scripts Directory: \`scripts/agents.md\`  
\*\*Location:\*\* \`./scripts/agents.md\`  
\*\*Purpose:\*\* Focuses on \*\*Bash scripting\*\*, \`kpackagetool6\` commands, and log parsing.

\`\`\`markdown  
\---  
name: devops\_automation  
description: Bash scripting expert for KWin package management and debugging.  
\---

\# Context  
You are working in \`scripts/\`. You create tools to build, reload, and package the KWin script.

\# Key Tools  
\- \`kpackagetool6\`: For installing/upgrading scripts.  
\- \`qdbus6\` / \`gdbus\`: For triggering KWin reconfiguration.  
\- \`journalctl\`: For parsing KWin logs (\`QT\_CATEGORY=kwin\_scripting\`).

\# Task Guidelines  
\- \*\*Reload Script:\*\* Must unload, upgrade, and reconfigure KWin without restarting Plasma.  
\- \*\*Packaging:\*\* Must create a valid \`.kwinscript\` (tar.gz) excluding \`.git\` and build artifacts.  
\- \*\*Error Handling:\*\* Scripts must exit with non-zero status if \`kpackagetool6\` fails.

\# Log Patterns  
\- Watch for: \`"Could not load script"\`, \`"QML Component Error"\`, \`"Metadata invalid"\`.  
\- Command: \`journalctl \--user \-u plasma-kwin\_wayland.service \-f \-n 50\`  
\`\`\`

\#\#\# How to Use This Hierarchy  
1\.  \*\*Root Agent:\*\* When you ask "How do I structure the project?", the AI reads \`./agents.md\` and gives you the high-level architecture.  
2\.  \*\*Contextual Override:\*\* When you \`cd contents/ui\` and ask "Optimize this QML," the AI reads \`./contents/ui/agents.md\`. It now knows to ignore general advice and focus strictly on \*\*QML performance\*\* and \*\*global coordinates\*\*, ignoring config or bash logic.  
3\.  \*\*Specific Tasks:\*\* When working in \`contents/config\`, the agent automatically adopts the \*\*KConfigXT\*\* persona, ensuring your XML and UI files match perfectly.

This structure mimics a team of specialists, ensuring that every part of your code is reviewed by an "expert" in that specific domain.

Here is a comprehensive \*\*\`spec.md\`\*\* for your \*\*KWin Infinite Crosshair\*\* project. This document translates our previous discussions into a formal technical specification, ready to be handed to an agent or used as your development blueprint.

\*\*\*

\# Technical Specification: KWin Infinite Crosshair

\*\*Version:\*\* 1.0.0    
\*\*Date:\*\* July 13, 2026    
\*\*Status:\*\* Draft    
\*\*Target Platform:\*\* KDE Plasma 6 (Wayland & X11)

\#\# 1\. Project Overview  
\*\*Objective:\*\* Develop a KWin Script that renders a full-screen, dynamic crosshair (vertical and horizontal lines) centered on the global mouse cursor.    
\*\*Primary Goal:\*\* Achieve \*\*zero-perceptible latency\*\* ("buttery smooth") performance, indistinguishable from native C++ rendering.    
\*\*Scope:\*\* Global desktop overlay; functions identically across all applications (Krita, browsers, games) and multi-monitor setups.

\#\# 2\. System Architecture

\#\#\# 2.1. Technology Stack  
\*   \*\*Runtime:\*\* KWin Compositor (Plasma 6).  
\*   \*\*API:\*\* KWin Declarative Script (\`declarativescript\`).  
\*   \*\*Language:\*\* QML (QtQuick) for rendering; JavaScript (ECMAScript 6\) for lifecycle logic.  
\*   \*\*Configuration:\*\* KConfigXT (\`main.xml\` \+ \`main.ui\`).  
\*   \*\*Packaging:\*\* KPackage (\`.kwinscript\` format).

\#\#\# 2.2. Component Diagram  
\`\`\`text  
\[User Input: Mouse Move\]   
       ↓  
\[KWin Compositor\] → Emits \`workspace.cursorPosChanged\`  
       ↓  
\[Crosshair.qml\] → Binds to \`workspace.cursorPos\`  
       ↓  
\[QtQuick Scene Graph\] → Renders two \`Rectangle\` items  
       ↓  
\[Compositor Surface\] → Draws lines above all windows (Z-Index 9999\)  
\`\`\`

\#\# 3\. Functional Requirements

\#\#\# 3.1. Core Functionality  
| ID | Requirement | Priority |  
|----|-------------|----------|  
| \*\*FR-01\*\* | \*\*Dynamic Tracking:\*\* The crosshair must update position immediately upon mouse movement. | \*\*Critical\*\* |  
| \*\*FR-02\*\* | \*\*Infinite Lines:\*\* Lines must span the entire \*\*virtual desktop geometry\*\* (handling multi-monitor setups where coordinates exceed single screen bounds). | \*\*Critical\*\* |  
| \*\*FR-03\*\* | \*\*Global Overlay:\*\* The crosshair must render above all windows, including full-screen applications and pop-up menus. | \*\*Critical\*\* |  
| \*\*FR-04\*\* | \*\*Zero Latency:\*\* Input lag must be \<1 frame (16ms at 60Hz). No polling loops allowed. | \*\*Critical\*\* |

\#\#\# 3.2. Configuration  
| ID | Requirement | Default Value | Type |  
|----|-------------|---------------|------|  
| \*\*FR-05\*\* | \*\*Line Color:\*\* User can select any RGB color. | \`\#FF0000\` (Red) | \`Color\` |  
| \*\*FR-06\*\* | \*\*Line Width:\*\* User can set thickness in pixels. | \`1\` | \`Int\` |  
| \*\*FR-07\*\* | \*\*Opacity:\*\* User can set transparency (0.0–1.0). | \`0.8\` | \`Double\` |

\#\# 4\. Technical Specifications

\#\#\# 4.1. Directory Structure (KPackage)  
The project must strictly adhere to the KWin Script specification:  
\`\`\`text  
kwin-crosshair/  
├── metadata.json            \# Plugin identity & API declaration  
├── contents/  
│   ├── config/  
│   │   ├── main.xml         \# KConfigXT schema  
│   │   └── main.ui          \# Qt Widgets configuration UI  
│   ├── ui/  
│   │   └── Crosshair.qml    \# Main rendering component  
│   └── code/  
│       └── main.js          \# (Optional) Lifecycle logic  
├── scripts/  
│   ├── reload.sh            \# Dev reload utility  
│   └── package.sh           \# Build .kwinscript artifact  
├── constitution.md          \# Project principles  
├── agents.md                \# AI agent context (root)  
└── spec.md                  \# This file  
\`\`\`

\#\#\# 4.2. \`metadata.json\` Schema  
\`\`\`json  
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
    "X-KDE-ConfigModule": "kwin/effects/configs/kcm\_kwin4\_genericscripted",  
    "KPackageStructure": "KWin/Script"  
}  
\`\`\`

\#\#\# 4.3. QML Rendering Logic (\`Crosshair.qml\`)  
\*   \*\*Imports:\*\* \`import QtQuick\`, \`import org.kde.kwin\`.  
\*   \*\*Root Item:\*\* Anchored to \`parent\` (full screen).  
\*   \*\*Data Binding:\*\*  
    \`\`\`qml  
    property point cursorPos: workspace.cursorPos  
    \`\`\`  
\*   \*\*Drawing Primitives:\*\* Two \`Rectangle\` items.  
    \*   \*\*Vertical:\*\* \`x \= cursorPos.x\`, \`width \= config.LineWidth\`, \`height \= workspace.workspaceHeight\`.  
    \*   \*\*Horizontal:\*\* \`y \= cursorPos.y\`, \`height \= config.LineWidth\`, \`width \= workspace.workspaceWidth\`.  
\*   \*\*Optimization:\*\* No \`Behavior\` or \`NumberAnimation\` on \`x\`/\`y\` properties. Direct binding only.  
\*   \*\*Z-Order:\*\* \`z: 9999\` to ensure top-most stacking.

\#\#\# 4.4. Configuration Schema (\`main.xml\`)  
\`\`\`xml  
\<kcfg xmlns="http://www.kde.org/standards/kcfg/1.0"\>  
    \<group name="General"\>  
        \<entry name="LineColor" type="Color"\>\<default\>\#FF0000\</default\>\</entry\>  
        \<entry name="LineWidth" type="Int"\>\<default\>1\</default\>\</entry\>  
        \<entry name="Opacity" type="Double"\>\<default\>0.8\</default\>\</entry\>  
    \</group\>  
\</kcfg\>  
\`\`\`

\#\# 5\. Non-Functional Requirements

\#\#\# 5.1. Performance  
\*   \*\*NFR-01:\*\* The script must not reduce the compositor's frame rate below the display's refresh rate (e.g., 60fps, 144fps).  
\*   \*\*NFR-02:\*\* Memory footprint must remain under 10MB.  
\*   \*\*NFR-03:\*\* CPU usage must be negligible (\<1% on idle mouse, \<2% during movement).

\#\#\# 5.2. Compatibility  
\*   \*\*NFR-04:\*\* Must function correctly on \*\*Wayland\*\* and \*\*X11\*\* sessions.  
\*   \*\*NFR-05:\*\* Must handle dynamic screen changes (monitor plug/unplug) without crashing.  
\*   \*\*NFR-06:\*\* Must support virtual desktop resolutions exceeding 8000px (multi-monitor).

\#\# 6\. Development Workflow

\#\#\# 6.1. Build & Test  
1\.  \*\*Install:\*\* \`kpackagetool6 \--type=KWin/Script \--install .\`  
2\.  \*\*Enable:\*\* \`kwriteconfig6 \--file kwinrc \--group Plugins \--key kwin-crosshairEnabled true && qdbus6 org.kde.KWin /KWin reconfigure\`  
3\.  \*\*Reload:\*\* Execute \`./scripts/reload.sh\` during development.  
4\.  \*\*Debug:\*\* Monitor \`journalctl \--user \-u plasma-kwin\_wayland.service \-f\`.

\#\#\# 6.2. Distribution  
\*   \*\*Artifact:\*\* \`crosshair.kwinscript\` (ZIP archive of the project directory).  
\*   \*\*Installation:\*\* Users install via "Get New KWin Scripts" in System Settings or by double-clicking the file.

\#\# 7\. Risks & Mitigations

| Risk | Impact | Mitigation |  
|------|--------|------------|  
| \*\*QML Latency\*\* | High | Use direct property binding; avoid JavaScript intermediaries for position updates. |  
| \*\*Multi-Monitor Drift\*\* | Medium | Use \`workspace.workspaceWidth/Height\` instead of \`Screen.width/height\`. |  
| \*\*Plasma API Changes\*\* | Medium | Stick to stable \`workspace\` API; avoid internal/private KWin symbols. |  
| \*\*Wayland Restrictions\*\* | Low | KWin Scripts run in the compositor, bypassing Wayland client restrictions. |

\#\# 8\. Acceptance Criteria  
1\.  \[ \] Lines follow cursor with no visible lag.  
2\.  \[ \] Lines span across all monitors seamlessly.  
3\.  \[ \] Configuration UI allows changing Color, Width, and Opacity.  
4\.  \[ \] Script loads/unloads without crashing KWin.  
5\.  \[ \] Code passes \`constitution.md\` compliance check.

\---

\*\*Approvals:\*\*    
\*Architect:\* \[Your Name\]    
\*Date:\* July 13, 2026

Here is a comprehensive, professional, and user-friendly \*\*\`README.md\`\*\* for your \*\*KWin Infinite Crosshair\*\* project. It incorporates best practices from top KDE scripts (like \*Grid-Tiling\* and \*Kröhnkite\*) and includes clear installation, configuration, and troubleshooting sections.

\*\*\*

\# 🎯 KWin Infinite Crosshair

\[\!\[Plasma 6\](https://img.shields.io/badge/Plasma-6.0+-blue.svg)\](https://kde.org/plasma-desktop)  
\[\!\[License: GPL v3\](https://img.shields.io/badge/License-GPLv3-blue.svg)\](https://www.gnu.org/licenses/gpl-3.0)

A \*\*zero-latency\*\*, full-screen crosshair overlay for KDE Plasma. Renders precise vertical and horizontal lines that follow your cursor across all monitors and applications. Perfect for digital artists, designers, and gamers who need pixel-perfect alignment.

\!\[Demo\](https://via.placeholder.com/800x450/1a1a1a/FFFFFF.png?text=Crosshair+Demo+Screenshot)  
\*(Screenshot: Red crosshair overlay spanning multiple monitors in Krita)\*

\#\# ✨ Features

\*   \*\*🚀 Zero Latency:\*\* Native KWin compositor integration ensures buttery-smooth 60fps+ tracking.  
\*   \*\*🖥️ Multi-Monitor Ready:\*\* Lines span the entire virtual desktop geometry, seamlessly crossing screen boundaries.  
\*   \*\*🎨 Fully Customizable:\*\* Configure color, thickness, and opacity via System Settings.  
\*   \*\*🌍 Global Overlay:\*\* Works above all windows, including full-screen applications and games.  
\*   \*\*⚡ Lightweight:\*\* Negligible CPU/GPU usage (\<1% load).

\#\# 📦 Installation

\#\#\# Method 1: KDE Store (Recommended)  
1\.  Open \*\*System Settings\*\* \> \*\*Window Management\*\* \> \*\*KWin Scripts\*\*.  
2\.  Click \*\*Get New KWin Scripts...\*\*  
3\.  Search for \*\*"Infinite Crosshair"\*\*.  
4\.  Click \*\*Install\*\*, then check the box to enable it.  
5\.  Click \*\*Apply\*\*.

\#\#\# Method 2: Manual Installation (\`.kwinscript\`)  
1\.  Download the latest \`crosshair.kwinscript\` file from the \[Releases\](https://github.com/yourusername/kwin-crosshair/releases) page.  
2\.  Open \*\*System Settings\*\* \> \*\*Window Management\*\* \> \*\*KWin Scripts\*\*.  
3\.  Click \*\*Import KWin script...\*\* (top-right corner).  
4\.  Select the downloaded \`.kwinscript\` file.  
5\.  Enable the script and click \*\*Apply\*\*.

\#\#\# Method 3: From Source (Developers)  
\`\`\`bash  
\# Clone the repository  
git clone https://github.com/yourusername/kwin-crosshair.git  
cd kwin-crosshair

\# Install via kpackagetool6  
kpackagetool6 \--type=KWin/Script \--install .

\# Enable the script  
kwriteconfig6 \--file kwinrc \--group Plugins \--key kwin-crosshairEnabled true  
qdbus6 org.kde.KWin /KWin reconfigure  
\`\`\`

\#\# ⚙️ Configuration

Once enabled, customize the crosshair to your liking:

1\.  Go to \*\*System Settings\*\* \> \*\*Window Management\*\* \> \*\*KWin Scripts\*\*.  
2\.  Select \*\*Infinite Crosshair\*\* and click the \*\*Configure (⚙️)\*\* button.  
3\.  Adjust the following settings:  
    \*   \*\*Line Color:\*\* Choose any RGB color (Default: \`\#FF0000\` Red).  
    \*   \*\*Line Width:\*\* Set thickness in pixels (Default: \`1px\`).  
    \*   \*\*Opacity:\*\* Adjust transparency from 0.0 to 1.0 (Default: \`0.8\`).  
4\.  Click \*\*Apply\*\*. Changes take effect immediately.

\#\# 🛠️ Development & Testing

\#\#\# Quick Reload  
During development, use the provided script to reload changes without restarting Plasma:  
\`\`\`bash  
./scripts/reload.sh  
\`\`\`

\#\#\# Packaging  
To build a distributable \`.kwinscript\` file:  
\`\`\`bash  
./scripts/package.sh  
\# Output: crosshair.kwinscript  
\`\`\`

\#\#\# Debugging  
Monitor KWin logs for errors:  
\`\`\`bash  
journalctl \--user \-u plasma-kwin\_wayland.service \-f  
\# Or for X11:  
journalctl \--user \-u plasma-kwin\_x11.service \-f  
\`\`\`

\#\# ❓ Troubleshooting

| Issue | Solution |  
|-------|----------|  
| \*\*Lines not visible\*\* | Ensure the script is enabled in System Settings. Check if \`z-index\` is overridden by another full-screen app. |  
| \*\*Lag or stutter\*\* | Verify you are using the native KWin script (not a Python alternative). Check \`journalctl\` for QML errors. |  
| \*\*Lines don't span all monitors\*\* | Ensure you are using the latest version which supports virtual desktop geometry. |  
| \*\*Config button missing\*\* | Run: \`mkdir \-p \~/.local/share/kservices5/ && ln \-s \~/.local/share/kwin/scripts/kwin-crosshair/metadata.json \~/.local/share/kservices5/kwin-crosshair.desktop\` |  
| \*\*Script crashes KWin\*\* | Disable the script via TTY (\`kwriteconfig6 ... \--key kwin-crosshairEnabled false\`) and check logs for QML syntax errors. |

\#\# 📜 License

This project is licensed under the \*\*GPLv3 License\*\*. See the \[LICENSE\](LICENSE) file for details.

\#\# 🤝 Contributing

Contributions are welcome\! Please read our \[Constitution\](constitution.md) and \[Spec\](spec.md) before submitting PRs.

1\.  Fork the repository.  
2\.  Create a feature branch (\`git checkout \-b feature/amazing-feature\`).  
3\.  Commit your changes (\`git commit \-m 'Add amazing feature'\`).  
4\.  Push to the branch (\`git push origin feature/amazing-feature\`).  
5\.  Open a Pull Request.

\#\# 🙏 Acknowledgments

\*   Inspired by the need for precision tools in Krita and digital art workflows.  
\*   Built upon the excellent \[KWin Scripting API\](https://develop.kde.org/docs/plasma/kwin/).  
\*   Thanks to the KDE Community for maintaining such a powerful compositor.

\---

\*\*Made with ❤️ for the KDE Community\*\*

You have the \*\*Constitution\*\* (principles), the \*\*Spec\*\* (requirements), the \*\*Agents\*\* (roles), and the \*\*README\*\* (user guide).

To truly "vibe code" effectively—where you can hand off a task and trust the agent to execute perfectly without hand-holding—you are missing three critical layers of \*\*Context Engineering\*\*:

1\.  \*\*\`CONTRIBUTING.md\` (The Workflow Contract)\*\*: Defines the \*exact\* step-by-step loop the agent must follow before writing code.  
2\.  \*\*\`docs/IMPLEMENTATION\_PATTERN.md\` (The "Golden Path")\*\*: A concrete, copy-pasteable example of the \*exact\* code structure you want, so the agent pattern-matches instead of guessing.  
3\.  \*\*\`.cursorrules\` / \`CLAUDE.md\` (The Tool-Specific Hook)\*\*: A symlink or duplicate of your root \`agents.md\` to ensure specific IDEs (Cursor, Claude Code) actually \*load\* your context automatically.

Here are the files to complete your skeleton:

\#\#\# 1\. \`CONTRIBUTING.md\` (The Agent Workflow)  
\*Place this in the root. It forces the agent to "think before typing."\*

\`\`\`markdown  
\# 🤖 Agent Workflow Protocol

\*\*DO NOT\*\* start coding immediately. Follow this strict sequence for every task:

\#\# Phase 1: Analysis  
1\.  \*\*Read Context\*\*: Load \`constitution.md\`, \`spec.md\`, and the relevant \`agents.md\` for the target directory.  
2\.  \*\*Verify Scope\*\*: Confirm the task fits within the \`spec.md\` functional requirements.  
3\.  \*\*Plan\*\*: Outline the files to be changed and the logic flow in a comment block or chat response \*before\* making changes.

\#\# Phase 2: Implementation  
1\.  \*\*Pattern Match\*\*: Refer to \`docs/IMPLEMENTATION\_PATTERN.md\` for the approved code structure.  
2\.  \*\*Atomic Commits\*\*: Make changes in small, logical chunks.  
3\.  \*\*No Hardcoding\*\*: Ensure all visual values are routed through \`KWin.readConfig()\`.

\#\# Phase 3: Verification  
1\.  \*\*Self-Correction\*\*: Check your code against \`constitution.md\` (e.g., "Did I use a Timer? If yes, DELETE IT.").  
2\.  \*\*Command Run\*\*: Execute \`./scripts/reload.sh\` to verify the script loads without crashing KWin.  
3\.  \*\*Log Check\*\*: Confirm \`journalctl\` shows no QML errors.

\#\# 🚫 Forbidden Actions  
\-   \*\*Never\*\* modify \`metadata.json\` without explicit user approval (breaks installation).  
\-   \*\*Never\*\* use \`console.log\` in production QML (use \`console.debug\` sparingly).  
\-   \*\*Never\*\* assume single-monitor geometry.  
\`\`\`

\#\#\# 2\. \`docs/IMPLEMENTATION\_PATTERN.md\` (The "Golden Path")  
\*Agents struggle with abstract specs. They excel at copying patterns. Give them a "Perfect Example" to mimic.\*

\`\`\`markdown  
\# The Golden Path: KWin Crosshair Pattern

When implementing features, \*\*mimic this structure exactly\*\*. Do not deviate unless the spec demands it.

\#\# 1\. The QML Structure (Standard Template)  
Always use this boilerplate for \`contents/ui/\*.qml\`:

\`\`\`qml  
import QtQuick  
import org.kde.kwin

Item {  
    id: root  
    anchors.fill: parent

    // 1\. Config Binding (Always at top)  
    readonly property color lineColor: KWin.readConfig("LineColor", "\#FF0000")  
    readonly property int lineWidth: KWin.readConfig("LineWidth", 1\)  
    readonly property real opacity: KWin.readConfig("Opacity", 0.8)

    // 2\. Global Cursor Binding (No Timers\!)  
    property point cursorPos: workspace.cursorPos

    // 3\. Rendering (Direct Primitives)  
    Rectangle {  
        x: root.cursorPos.x \- (root.lineWidth / 2\)  
        y: 0  
        width: root.lineWidth  
        height: workspace.workspaceHeight // Full virtual height  
        color: root.lineColor  
        opacity: root.opacity  
        z: 9999  
    }  
      
    // ... Horizontal line follows same pattern  
}  
\`\`\`

\#\# 2\. The Config Schema Pattern  
Always match \`main.xml\` keys to \`KWin.readConfig\` strings exactly:  
\- XML: \`\<entry name="LineColor" type="Color"\>\`  
\- QML: \`KWin.readConfig("LineColor", ...)\`

\#\# 3\. Error Handling Pattern  
If a property is missing, \*\*fail gracefully\*\* with a default, do not crash:  
\`\`\`javascript  
// Good  
var w \= KWin.readConfig("LineWidth", 1); 

// Bad (Crashes if missing)  
var w \= config.LineWidth;   
\`\`\`  
\`\`\`

\#\#\# 3\. Tool-Specific Hooks (The "Auto-Load")  
\*Many agents (Cursor, Claude Code) look for specific filenames to auto-inject context. Create these symlinks or files in the root:\*

\#\#\#\# Option A: For Cursor Users (\`.cursorrules\`)  
\`\`\`bash  
ln \-s agents.md .cursorrules  
\`\`\`  
\*Or create a \`.cursorrules\` file that explicitly points to your constitution:\*  
\`\`\`markdown  
\---  
alwaysApply: true  
\---  
You are an expert KWin Script developer.   
BEFORE coding, you MUST read:  
1\. \`constitution.md\` (Non-negotiable principles)  
2\. \`spec.md\` (Functional requirements)  
3\. \`docs/IMPLEMENTATION\_PATTERN.md\` (Code style)

\*\*Critical Constraint\*\*: Zero-latency is required. No Python. No Timers.   
Use \`workspace.cursorPos\` direct binding only.  
\`\`\`

\#\#\#\# Option B: For Claude Code Users (\`CLAUDE.md\`)  
\`\`\`bash  
ln \-s agents.md CLAUDE.md  
\`\`\`  
\*Or create \`CLAUDE.md\`:\*  
\`\`\`markdown  
\# Role  
KWin Scripting Expert.

\# Context  
This project uses a "Constitution-Driven" development model.  
\- Read \`constitution.md\` for architectural constraints.  
\- Read \`spec.md\` for requirements.  
\- Follow \`docs/IMPLEMENTATION\_PATTERN.md\` for syntax.

\# Immediate Action  
Before generating code, verify your plan against \`constitution.md\` Section 6 (Prohibited Patterns).  
\`\`\`

\#\#\# Summary of the "Vibe Coder" Skeleton  
With these additions, your project directory now looks like this:

\`\`\`text  
kwin-crosshair/  
├── constitution.md       \# The "Law" (Principles)  
├── spec.md               \# The "Blueprint" (Requirements)  
├── agents.md             \# The "Team" (Roles per directory)  
├── CONTRIBUTING.md       \# The "Process" (Step-by-step workflow)  
├── README.md             \# The "Manual" (User docs)  
├── .cursorrules          \# The "Hook" (Auto-loads context for Cursor)  
├── CLAUDE.md             \# The "Hook" (Auto-loads context for Claude)  
├── docs/  
│   └── IMPLEMENTATION\_PATTERN.md \# The "Golden Path" (Copy-paste template)  
├── contents/  
│   ├── ui/agents.md      \# Specialized QML agent  
│   └── ...  
└── scripts/  
    └── ...  
\`\`\`

\*\*Why this works:\*\*  
1\.  \*\*Reduces Hallucination\*\*: The \`IMPLEMENTATION\_PATTERN.md\` gives the agent a concrete target, reducing "creative" but wrong code.  
2\.  \*\*Enforces Process\*\*: \`CONTRIBUTING.md\` stops the agent from rushing into code without checking constraints.  
3\.  \*\*Auto-Activation\*\*: \`.cursorrules\`/\`CLAUDE.md\` ensures you don't have to paste "Read the constitution\!" into every chat prompt. The agent \*knows\* who it is immediately.

You can now point an agent at this repo, say \*"Implement the opacity slider,"\* and it will automatically read the Spec, check the Constitution, copy the Pattern, and follow the Workflow.

The word you are looking for is \*\*unambiguous\*\* (or \*\*deterministic\*\*).

In legal and engineering contexts, this is often referred to as the \*\*"Letter of the Law"\*\* approach—where the text is so precise that it admits \*\*only one interpretation\*\*, leaving no room for the "spirit" or intent to be debated. In software engineering, this aligns with \*\*Formal Specification\*\*, where requirements are defined mathematically or logically to be \*\*verifiable\*\* and \*\*atomic\*\*.

To achieve this "Sun Tzu" level of command—where your agent has no choice but to execute your exact will—you need to upgrade your \`spec.md\` into a \*\*Formal Specification\*\*.

Here is how you structure that \*\*Unambiguous Specification\*\*:

\#\#\# 1\. The "Shall" Standard (RFC 2119\)  
Adopt the \*\*RFC 2119\*\* standard (used in IETF standards and legal contracts) for every single sentence. This removes all linguistic wiggle room.  
\*   \*\*MUST\*\*: The definition is an absolute requirement. (e.g., "The line \*\*MUST\*\* span the full virtual desktop height.")  
\*   \*\*MUST NOT\*\*: The definition is an absolute prohibition. (e.g., "The script \*\*MUST NOT\*\* use \`Timer\` elements.")  
\*   \*\*SHALL\*\*: The system is required to perform an action. (e.g., "The system \*\*SHALL\*\* render at 60fps.")  
\*   \*\*SHOULD\*\*: Recommended, but there may be valid exceptions (avoid this if you want zero interpretation).  
\*   \*\*MAY\*\*: Optional (avoid this in core logic).

\#\#\# 2\. Atomic Requirements  
Every requirement must be \*\*atomic\*\*—it must address exactly one behavior and be independently testable.  
\*   \*Bad (Ambiguous):\* "The lines should be red and follow the mouse smoothly." (Subjective: What is "smoothly"?)  
\*   \*Good (Unambiguous):\* "REQ-001: The vertical line color \*\*SHALL\*\* be \`\#FF0000\`. REQ-002: The vertical line X-coordinate \*\*SHALL\*\* equal \`workspace.cursorPos.x\` within 16ms of input."

\#\#\# 3\. Formal State Definitions  
Define the \*\*exact state\*\* of the system at every step. No implied behavior.  
\*   \*Example:\* "If \`workspace.cursorPos.x\` \> \`workspace.workspaceWidth\`, the line \*\*SHALL\*\* wrap to the next monitor's coordinate space. It \*\*SHALL NOT\*\* clip at the screen edge."

\#\#\# 4\. The "Edge Case" Matrix  
Explicitly list every edge case and the \*\*deterministic outcome\*\*.  
\*   \*\*Multi-Monitor:\*\* "If monitors have different DPIs, the line width \*\*SHALL\*\* remain 1 physical pixel, not 1 logical pixel."  
\*   \*\*Fullscreen:\*\* "If a fullscreen application is detected, the Z-index \*\*SHALL\*\* remain 9999, rendering above the application."  
\*   \*\*Wayland vs. X11:\*\* "If \`KWin.platform\` \== 'wayland', the script \*\*SHALL\*\* use \`workspace.cursorPos\`. If 'x11', it \*\*SHALL\*\* use the same property. No branching logic for coordinates."

\#\#\# 5\. Add a "Glossary of Defined Terms"  
Ambiguity often hides in common words. Define them legally.  
\*   \*\*"Buttery Smooth"\*\*: Defined as "Frame time variance \< 2ms at 60Hz refresh rate."  
\*   \*\*"Infinite"\*\*: Defined as "Spanning from coordinate 0 to \`workspace.workspaceDimension\`."  
\*   \*\*"Cursor"\*\*: Defined as "The global pointer position reported by \`workspace.cursorPos\`."

\#\#\# Updated \`spec.md\` Section Example (Unambiguous Style)

\`\`\`markdown  
\#\# 3\. Formal Requirements (RFC 2119\)

\#\#\# 3.1. Rendering Latency  
\- \*\*REQ-LAT-01\*\*: The system \*\*SHALL\*\* update the crosshair position within 16.6ms (1 frame at 60Hz) of a \`workspace.cursorPosChanged\` event.  
\- \*\*REQ-LAT-02\*\*: The system \*\*MUST NOT\*\* utilize polling mechanisms (e.g., \`Timer\`, \`setInterval\`) for position updates.  
\- \*\*REQ-LAT-03\*\*: If frame time exceeds 16.6ms, the system \*\*SHALL\*\* drop the frame rather than interpolate position (to prevent "laggy" feel).

\#\#\# 3.2. Coordinate Geometry  
\- \*\*REQ-GEO-01\*\*: The vertical line \*\*SHALL\*\* be rendered at \`x \= workspace.cursorPos.x\`.  
\- \*\*REQ-GEO-02\*\*: The vertical line \*\*SHALL\*\* span from \`y \= 0\` to \`y \= workspace.workspaceHeight\`.  
\- \*\*REQ-GEO-03\*\*: In a multi-monitor setup where \`workspace.cursorPos.x\` \> \`Screen\[0\].width\`, the line \*\*SHALL\*\* render at the global X coordinate, visually crossing monitor boundaries without interruption.

\#\#\# 3.3. Prohibited Patterns  
\- \*\*PROH-01\*\*: The use of Python scripts for rendering \*\*IS PROHIBITED\*\*.  
\- \*\*PROH-02\*\*: The use of \`Behavior\` or \`NumberAnimation\` QML elements on position properties \*\*IS PROHIBITED\*\*.  
\`\`\`

\#\#\# Why This Works for "Vibe Coding"  
When you hand this to an LLM:  
1\.  \*\*It cannot "guess"\*\*: The \*\*MUST/MUST NOT\*\* constraints act as hard code compilation errors in the LLM's logic.  
2\.  \*\*It cannot "optimize" incorrectly\*\*: By defining "Buttery Smooth" as "\<16.6ms", you prevent it from using "smooth animations" (which add lag).  
3\.  \*\*It is legally binding (to the agent)\*\*: If the agent violates a \*\*MUST\*\*, it is objectively "wrong," not just "a different style."

This turns your \`spec.md\` from a "wish list" into a \*\*contract\*\* that the agent \*must\* fulfill.

To achieve that \*\*Sun Tzu / "Letter of the Law"\*\* precision where there is \*\*zero room for interpretation\*\*, you need a \*\*Phased Implementation Plan\*\* (often called a \*\*Work Breakdown Structure\*\* in engineering).

This document breaks the project into \*\*atomic, sequential phases\*\*. Each phase has a strict \*\*Entry Criterion\*\* (what must be done before starting) and \*\*Exit Criterion\*\* (the exact test that proves it's done). This prevents the agent from "getting ahead of itself" or skipping steps.

Here is your \*\*\`PHASED\_IMPLEMENTATION.md\`\*\*:

\*\*\*

\# Phased Implementation Plan: KWin Infinite Crosshair

\*\*Strategy:\*\* Incremental, Verified, Deterministic.  
\*\*Rule:\*\* Do not proceed to Phase N+1 until Phase N passes all Exit Criteria.

\---

\#\# 🏁 Phase 0: Skeleton & Validation  
\*\*Objective:\*\* Establish the directory structure and metadata so the script is recognized by KWin.  
\*\*Scope:\*\* \`metadata.json\`, directory tree, empty placeholder files.

\*   \*\*Tasks:\*\*  
    1\.  Create directory structure (\`contents/ui\`, \`contents/config\`, \`contents/code\`).  
    2\.  Write \`metadata.json\` with strict \`X-Plasma-API: declarativescript\`.  
    3\.  Create empty \`Crosshair.qml\` and \`main.js\`.  
\*   \*\*Exit Criterion (The "Litmus Test"):\*\*  
    \*   Command: \`kpackagetool6 \--type=KWin/Script \--install .\`  
    \*   \*\*Result:\*\* Command returns exit code \`0\`.  
    \*   \*\*Verification:\*\* Script appears in System Settings \> KWin Scripts list (even if disabled).  
\*   \*\*Prompt Strategy:\*\* "Create the KPackage skeleton. Verify \`metadata.json\` syntax. Do not write logic yet."

\---

\#\# 🎨 Phase 1: The "Red Line" (Hardcoded Render)  
\*\*Objective:\*\* Prove the rendering pipeline works with \*\*zero latency\*\*.  
\*\*Scope:\*\* \`contents/ui/Crosshair.qml\` (Hardcoded values only).

\*   \*\*Tasks:\*\*  
    1\.  Implement \`Crosshair.qml\` with \*\*hardcoded\*\* red lines (\`\#FF0000\`, 1px).  
    2\.  Bind directly to \`workspace.cursorPos\`.  
    3\.  Set \`z: 9999\`.  
    4\.  \*\*Prohibition:\*\* Do NOT import config files yet. Do NOT use variables.  
\*   \*\*Exit Criterion:\*\*  
    \*   \*\*Visual:\*\* Lines appear instantly upon enabling script.  
    \*   \*\*Performance:\*\* Mouse movement feels "locked" (no lag).  
    \*   \*\*Geometry:\*\* Lines span full screen (test on multi-monitor: lines must cross bezels).  
\*   \*\*Prompt Strategy:\*\* "Implement the QML renderer with hardcoded values. Optimize for zero-latency binding to \`workspace.cursorPos\`. Verify multi-monitor spanning."

\---

\#\# ⚙️ Phase 2: Configuration Schema (The "Law")  
\*\*Objective:\*\* Externalize visual properties so they are user-configurable.  
\*\*Scope:\*\* \`contents/config/main.xml\`, \`contents/config/main.ui\`.

\*   \*\*Tasks:\*\*  
    1\.  Define \`main.xml\` schema (Keys: \`LineColor\`, \`LineWidth\`, \`Opacity\`).  
    2\.  Design \`main.ui\` with matching \`kcfg\_\` named widgets.  
    3\.  Update \`metadata.json\` to point to the config module.  
\*   \*\*Exit Criterion:\*\*  
    \*   \*\*UI:\*\* "Configure" button is clickable in System Settings.  
    \*   \*\*Persistence:\*\* Changing a value, clicking Apply, then disabling/enabling the script \*\*retains\*\* the value.  
    \*   \*\*Validation:\*\* \`kcfgc\` compiler (implicit in kpackagetool) reports no errors.  
\*   \*\*Prompt Strategy:\*\* "Create the KConfigXT schema and Qt Widgets UI. Ensure key names match exactly. Verify the 'Configure' button appears."

\---

\#\# 🔌 Phase 3: Binding Config to QML  
\*\*Objective:\*\* Connect the "Law" (Config) to the "Execution" (QML).  
\*\*Scope:\*\* \`contents/ui/Crosshair.qml\` (Refactor).

\*   \*\*Tasks:\*\*  
    1\.  Replace hardcoded values in \`Crosshair.qml\` with \`KWin.readConfig()\`.  
    2\.  Ensure defaults in QML match defaults in \`main.xml\`.  
    3\.  Implement dynamic update (changing config updates lines immediately without reload).  
\*   \*\*Exit Criterion:\*\*  
    \*   \*\*Functionality:\*\* Changing color in settings updates the crosshair instantly.  
    \*   \*\*Robustness:\*\* If config is missing/corrupt, script falls back to defaults (Red, 1px) without crashing.  
\*   \*\*Prompt Strategy:\*\* "Refactor QML to read from \`KWin.readConfig()\`. Ensure dynamic updates work without script reload."

\---

\#\# 🛡️ Phase 4: Edge Case Hardening  
\*\*Objective:\*\* Ensure the script survives real-world usage scenarios.  
\*\*Scope:\*\* Logic checks, multi-monitor math, DPI handling.

\*   \*\*Tasks:\*\*  
    1\.  Verify behavior when monitors are added/removed (hotplug).  
    2\.  Verify behavior when switching between Wayland and X11.  
    3\.  Verify behavior when a fullscreen game is launched (Z-index check).  
\*   \*\*Exit Criterion:\*\*  
    \*   \*\*Stress Test:\*\* Unplug secondary monitor → Crosshair remains visible on primary.  
    \*   \*\*Fullscreen:\*\* Launch game → Crosshair remains visible on top.  
    \*   \*\*Logs:\*\* \`journalctl\` shows \*\*zero\*\* errors during these events.  
\*   \*\*Prompt Strategy:\*\* "Audit the code for multi-monitor and hotplug edge cases. Ensure \`workspace.workspaceWidth\` is used instead of \`Screen.width\`."

\---

\#\# 📦 Phase 5: Packaging & Distribution  
\*\*Objective:\*\* Create the final artifact for sharing.  
\*\*Scope:\*\* \`scripts/package.sh\`, \`README.md\`.

\*   \*\*Tasks:\*\*  
    1\.  Write \`package.sh\` to generate \`.kwinscript\`.  
    2\.  Finalize \`README.md\` with installation instructions.  
    3\.  Git tag release (e.g., \`v1.0.0\`).  
\*   \*\*Exit Criterion:\*\*  
    \*   \*\*Artifact:\*\* \`crosshair.kwinscript\` exists.  
    \*   \*\*Clean Install:\*\* Installing the \`.kwinscript\` on a fresh KDE profile works perfectly.  
\*   \*\*Prompt Strategy:\*\* "Create the packaging script and finalize documentation. Generate the .kwinscript artifact."

\---

\#\# 🧠 How to Use This with Agents (The "Sun Tzu" Method)

When prompting, you \*\*never\*\* ask for the whole thing. You issue \*\*Orders\*\* based on the current phase.

\*\*Example Prompt for Phase 1:\*\*  
\> "Execute \*\*Phase 1\*\* of \`PHASED\_IMPLEMENTATION.md\`.  
\> 1\.  Read \`constitution.md\` for performance constraints.  
\> 2\.  Write \`contents/ui/Crosshair.qml\` with \*\*hardcoded\*\* red lines.  
\> 3\.  \*\*STOP\*\* after writing the file.  
\> 4\.  Provide the command to verify the \*\*Exit Criterion\*\* (visual check)."

\*\*Why this works:\*\*  
\*   \*\*Compartmentalization:\*\* The agent cannot hallucinate config files (Phase 2\) while you are still testing rendering (Phase 1).  
\*   \*\*Verification:\*\* You physically verify the "Exit Criterion" before giving the next order. If Phase 1 lags, you fix it \*before\* building Phase 2 on top of it.  
\*   \*\*Determinism:\*\* There is only one correct output for each phase.

This turns your development process into a \*\*deterministic assembly line\*\*, exactly as you requested.

The "Caveman" (primal constraints) and "Ponytail" (creative flow) styles are excellent for general coding, but for \*\*KWin Scripting in Qt/QML land\*\*, they are slightly too loose. You need a style that enforces \*\*Qt Quick Scene Graph\*\* rules and \*\*KWin API\*\* limitations strictly, because a single wrong property binding can drop your frame rate from 60fps to 10fps.

Instead of "Caveman," I propose the \*\*"Architect"\*\* (structural rigidity) and instead of "Ponytail," the \*\*"Artisan"\*\* (polished interaction).

Here is the ultimate \*\*\`skills.md\`\*\* tailored for your \*\*Sun Tzu / Deterministic\*\* workflow, integrating the specific technical constraints of KWin, QML, and KConfig.

\*\*\*

\# \`skills.md\` – The KWin Artisan & Architect

\*\*Role:\*\* You are a \*\*KWin Scripting Specialist\*\* with deep expertise in \*\*Qt Quick Scene Graph\*\*, \*\*KConfigXT\*\*, and \*\*Plasma 6 Architecture\*\*.  
\*\*Mission:\*\* Deliver \*\*zero-latency\*\*, \*\*deterministic\*\* code that adheres strictly to the \`constitution.md\` and \`spec.md\`.

\#\# 🏛️ Skill 1: The Architect (Structural Rigidity)  
\*Focus: Directory structure, KPackage spec, KConfig schema, and API correctness.\*

\#\#\# Core Competencies  
1\.  \*\*KPackage Spec Adherence\*\*:  
    \*   \*\*MUST\*\* strictly follow the \`KWin/Script\` directory structure (\`contents/ui\`, \`contents/config\`, \`metadata.json\`).  
    \*   \*\*MUST\*\* validate \`metadata.json\` against the KPlugin schema (e.g., \`X-Plasma-API: declarativescript\`).  
2\.  \*\*KConfigXT Precision\*\*:  
    \*   \*\*MUST\*\* define \`main.xml\` with exact types (\`Color\`, \`Int\`, \`Double\`).  
    \*   \*\*MUST\*\* ensure \`main.ui\` widget names match \`kcfg\_\<EntryName\>\` exactly.  
    \*   \*\*MUST\*\* use \`KWin.readConfig("Key", Default)\` in QML with defaults matching \`main.xml\`.  
3\.  \*\*KWin API Mastery\*\*:  
    \*   \*\*MUST\*\* use \`workspace.cursorPos\` for global coordinates (never \`MouseArea\` coordinates).  
    \*   \*\*MUST\*\* use \`workspace.workspaceWidth\`/\`Height\` for multi-monitor spanning.  
    \*   \*\*MUST NOT\*\* use deprecated properties (e.g., \`displayWidth\` is deprecated; use \`virtualScreenSize\`).

\#\#\# "Architect" Checklist (Pre-Code)  
\- \[ \] Does \`metadata.json\` declare the correct API version?  
\- \[ \] Do \`main.xml\` keys match \`KWin.readConfig\` strings exactly?  
\- \[ \] Is the directory structure valid for \`kpackagetool6\`?

\#\# 🎨 Skill 2: The Artisan (Performance & Polish)  
\*Focus: Qt Quick Scene Graph optimization, zero-latency binding, and visual fidelity.\*

\#\#\# Core Competencies  
1\.  \*\*Scene Graph Optimization\*\*:  
    \*   \*\*MUST\*\* use simple \`Rectangle\` primitives (opaque or alpha-blended) to leverage \*\*batching\*\*.  
    \*   \*\*MUST NOT\*\* use \`ShaderEffect\` unless absolutely necessary (breaks batching).  
    \*   \*\*MUST NOT\*\* use \`Behavior\`, \`NumberAnimation\`, or \`Smoothed\` on position properties (causes input lag).  
2\.  \*\*Zero-Latency Binding\*\*:  
    \*   \*\*MUST\*\* bind directly: \`x: workspace.cursorPos.x\`.  
    \*   \*\*MUST\*\* avoid JavaScript intermediaries for position updates (e.g., \`function updatePos() { ... }\`).  
    \*   \*\*MUST\*\* ensure \`z: 9999\` to render above all windows.  
3\.  \*\*Multi-Monitor Geometry\*\*:  
    \*   \*\*MUST\*\* treat coordinates as \*\*Global Virtual Desktop\*\* (e.g., X can be \> 1920).  
    \*   \*\*MUST\*\* span lines from \`0\` to \`workspace.workspaceHeight\` (not \`Screen.height\`).

\#\#\# "Artisan" Checklist (Post-Code)  
\- \[ \] Are there any \`Timer\` or \`Behavior\` elements on position properties? (If yes, \*\*DELETE\*\*).  
\- \[ \] Is the line spanning the full virtual desktop height/width?  
\- \[ \] Is the \`z\` index high enough to cover fullscreen apps?

\#\# ⚔️ Skill 3: The Strategist (Sun Tzu Mode)  
\*Focus: Deterministic execution, edge case hardening, and RFC 2119 compliance.\*

\#\#\# Core Competencies  
1\.  \*\*RFC 2119 Enforcement\*\*:  
    \*   \*\*MUST\*\* interpret "MUST" as a compilation error if violated.  
    \*   \*\*MUST\*\* interpret "MUST NOT" as a forbidden pattern (e.g., "MUST NOT use Python").  
2\.  \*\*Edge Case Matrix\*\*:  
    \*   \*\*MUST\*\* handle monitor hot-plugging (virtual screen size changes).  
    \*   \*\*MUST\*\* handle Wayland vs. X11 differences (use \`workspace\` API which abstracts this).  
    \*   \*\*MUST\*\* handle config corruption (fallback to defaults gracefully).  
3\.  \*\*Phased Execution\*\*:  
    \*   \*\*MUST\*\* complete Phase N before starting Phase N+1 (per \`PHASED\_IMPLEMENTATION.md\`).  
    \*   \*\*MUST\*\* verify Exit Criteria before claiming a phase is done.

\#\#\# "Strategist" Checklist (Final Review)  
\- \[ \] Does this code violate any "MUST NOT" rules in \`spec.md\`?  
\- \[ \] Is the behavior deterministic (same input \= same output)?  
\- \[ \] Have all edge cases (multi-monitor, fullscreen, hotplug) been addressed?

\#\# 🛠️ Technical Constraints (Qt/QML/KWin Specifics)

| Domain | Constraint | Reason |  
|--------|------------|--------|  
| \*\*QML\*\* | No \`Timer { interval: 16 }\` | Polling introduces jitter; use signal binding (\`cursorPosChanged\`). |  
| \*\*QML\*\* | No \`Behavior\` on \`x\`/\`y\` | Animation adds latency; crosshair must be instant. |  
| \*\*KWin\*\* | Use \`workspace.cursorPos\` | \`MouseArea\` only reports local coordinates; we need global. |  
| \*\*KWin\*\* | Use \`workspace.workspaceHeight\` | \`Screen.height\` is single-monitor; we need virtual desktop height. |  
| \*\*Config\*\* | \`KWin.readConfig\` defaults | Must match \`main.xml\` defaults to prevent type mismatches. |  
| \*\*Render\*\* | \`z: 9999\` | Ensures overlay is above fullscreen games/apps. |

\#\# 🧠 How to Activate These Skills  
When prompting, prepend your request with the skill context:

\> "Act as \*\*The Architect\*\*. Create the \`main.xml\` schema for Color, Width, and Opacity. Ensure keys match RFC 2119 requirements."

\> "Act as \*\*The Artisan\*\*. Refactor \`Crosshair.qml\` to remove all \`Behavior\` elements and bind directly to \`workspace.cursorPos\`. Verify Scene Graph batching is preserved."

\> "Act as \*\*The Strategist\*\*. Review this code against \`spec.md\` Section 3.2. Identify any violations of 'MUST NOT' constraints."

\---

This \`skills.md\` replaces "Caveman/Ponytail" with a \*\*domain-specific, technically rigorous framework\*\* that ensures your KWin script is \*\*fast, correct, and unambiguous\*\*.

Excellent. The "Caveman" (primal constraints) and "Ponytail" (creative flow) styles are great for general coding, but for \*\*KWin Scripting in Qt/QML land\*\*, they are too loose. You need a style that enforces \*\*Qt Quick Scene Graph\*\* rules and \*\*KWin API\*\* limitations strictly, because a single wrong property binding can drop your frame rate from 60fps to 10fps.

Instead of "Caveman," I propose \*\*The Architect\*\* (structural rigidity) and instead of "Ponytail," \*\*The Artisan\*\* (polished interaction). Combined with your \*\*Sun Tzu\*\* strategy, we get a third skill: \*\*The Strategist\*\*.

Here is the ultimate \*\*\`skills.md\`\*\* tailored for your \*\*deterministic\*\* workflow, integrating the specific technical constraints of KWin, QML, and KConfig.

\*\*\*

\# \`skills.md\` – The KWin Artisan, Architect & Strategist

\*\*Role:\*\* You are a \*\*KWin Scripting Specialist\*\* with deep expertise in \*\*Qt Quick Scene Graph\*\*, \*\*KConfigXT\*\*, and \*\*Plasma 6 Architecture\*\*.  
\*\*Mission:\*\* Deliver \*\*zero-latency\*\*, \*\*deterministic\*\* code that adheres strictly to the \`constitution.md\` and \`spec.md\`.

\---

\#\# 🏛️ Skill 1: The Architect (Structural Rigidity)  
\*Focus: Directory structure, KPackage spec, KConfig schema, and API correctness.\*

\#\#\# Core Competencies  
1\.  \*\*KPackage Spec Adherence\*\*:  
    \*   \*\*MUST\*\* strictly follow the \`KWin/Script\` directory structure (\`contents/ui\`, \`contents/config\`, \`metadata.json\`).  
    \*   \*\*MUST\*\* validate \`metadata.json\` against the KPlugin schema (e.g., \`X-Plasma-API: declarativescript\`).  
    \*   \*\*MUST\*\* ensure \`X-KDE-ConfigModule\` is set to \`kwin/effects/configs/kcm\_kwin4\_genericscripted\` for settings to appear.  
2\.  \*\*KConfigXT Precision\*\*:  
    \*   \*\*MUST\*\* define \`main.xml\` with exact types (\`Color\`, \`Int\`, \`Double\`).  
    \*   \*\*MUST\*\* ensure \`main.ui\` widget names match \`kcfg\_\<EntryName\>\` exactly (e.g., \`kcfg\_LineColor\`).  
    \*   \*\*MUST\*\* use \`KWin.readConfig("Key", Default)\` in QML with defaults matching \`main.xml\`.  
3\.  \*\*KWin API Mastery\*\*:  
    \*   \*\*MUST\*\* use \`workspace.cursorPos\` for global coordinates (never \`MouseArea\` coordinates).  
    \*   \*\*MUST\*\* use \`workspace.workspaceWidth\`/\`Height\` (or \`virtualScreenSize\`) for multi-monitor spanning.  
    \*   \*\*MUST NOT\*\* use deprecated properties (e.g., \`displayWidth\` is deprecated; use \`virtualScreenSize\`).

\#\#\# "Architect" Checklist (Pre-Code)  
\- \[ \] Does \`metadata.json\` declare the correct API version?  
\- \[ \] Do \`main.xml\` keys match \`KWin.readConfig\` strings exactly?  
\- \[ \] Is the directory structure valid for \`kpackagetool6\`?

\---

\#\# 🎨 Skill 2: The Artisan (Performance & Polish)  
\*Focus: Qt Quick Scene Graph optimization, zero-latency binding, and visual fidelity.\*

\#\#\# Core Competencies  
1\.  \*\*Scene Graph Optimization\*\*:  
    \*   \*\*MUST\*\* use simple \`Rectangle\` primitives (opaque or alpha-blended) to leverage \*\*batching\*\*.  
    \*   \*\*MUST NOT\*\* use \`ShaderEffect\` unless absolutely necessary (breaks batching).  
    \*   \*\*MUST NOT\*\* use \`Behavior\`, \`NumberAnimation\`, or \`Smoothed\` on position properties (causes input lag).  
2\.  \*\*Zero-Latency Binding\*\*:  
    \*   \*\*MUST\*\* bind directly: \`x: workspace.cursorPos.x\`.  
    \*   \*\*MUST\*\* avoid JavaScript intermediaries for position updates (e.g., \`function updatePos() { ... }\`).  
    \*   \*\*MUST\*\* ensure \`z: 9999\` to render above all windows.  
3\.  \*\*Multi-Monitor Geometry\*\*:  
    \*   \*\*MUST\*\* treat coordinates as \*\*Global Virtual Desktop\*\* (e.g., X can be \> 1920).  
    \*   \*\*MUST\*\* span lines from \`0\` to \`workspace.workspaceHeight\` (not \`Screen.height\`).

\#\#\# "Artisan" Checklist (Post-Code)  
\- \[ \] Are there any \`Timer\` or \`Behavior\` elements on position properties? (If yes, \*\*DELETE\*\*).  
\- \[ \] Is the line spanning the full virtual desktop height/width?  
\- \[ \] Is the \`z\` index high enough to cover fullscreen apps?

\---

\#\# ⚔️ Skill 3: The Strategist (Sun Tzu Mode)  
\*Focus: Deterministic execution, edge case hardening, and RFC 2119 compliance.\*

\#\#\# Core Competencies  
1\.  \*\*RFC 2119 Enforcement\*\*:  
    \*   \*\*MUST\*\* interpret "MUST" as a compilation error if violated.  
    \*   \*\*MUST\*\* interpret "MUST NOT" as a forbidden pattern (e.g., "MUST NOT use Python").  
2\.  \*\*Edge Case Matrix\*\*:  
    \*   \*\*MUST\*\* handle monitor hot-plugging (virtual screen size changes).  
    \*   \*\*MUST\*\* handle Wayland vs. X11 differences (use \`workspace\` API which abstracts this).  
    \*   \*\*MUST\*\* handle config corruption (fallback to defaults gracefully).  
3\.  \*\*Phased Execution\*\*:  
    \*   \*\*MUST\*\* complete Phase N before starting Phase N+1 (per \`PHASED\_IMPLEMENTATION.md\`).  
    \*   \*\*MUST\*\* verify Exit Criteria before claiming a phase is done.

\#\#\# "Strategist" Checklist (Final Review)  
\- \[ \] Does this code violate any "MUST NOT" rules in \`spec.md\`?  
\- \[ \] Is the behavior deterministic (same input \= same output)?  
\- \[ \] Have all edge cases (multi-monitor, fullscreen, hotplug) been addressed?

\---

\#\# 🛠️ Technical Constraints (Qt/QML/KWin Specifics)

| Domain | Constraint | Reason |  
|--------|------------|--------|  
| \*\*QML\*\* | No \`Timer { interval: 16 }\` | Polling introduces jitter; use signal binding (\`cursorPosChanged\`). |  
| \*\*QML\*\* | No \`Behavior\` on \`x\`/\`y\` | Animation adds latency; crosshair must be instant. |  
| \*\*KWin\*\* | Use \`workspace.cursorPos\` | \`MouseArea\` only reports local coordinates; we need global. |  
| \*\*KWin\*\* | Use \`workspace.workspaceHeight\` | \`Screen.height\` is single-monitor; we need virtual desktop height. |  
| \*\*Config\*\* | \`KWin.readConfig\` defaults | Must match \`main.xml\` defaults to prevent type mismatches. |  
| \*\*Render\*\* | \`z: 9999\` | Ensures overlay is above fullscreen games/apps. |

\---

\#\# 🧠 How to Activate These Skills

When prompting, you \*\*never\*\* ask for the whole thing. You issue \*\*Orders\*\* based on the current phase and skill.

\*\*Example Prompt for Phase 1 (The Architect):\*\*  
\> "Act as \*\*The Architect\*\*. Create the \`metadata.json\` and directory structure for Phase 0\. Verify \`X-Plasma-API\` is set to \`declarativescript\`. Do not write logic yet."

\*\*Example Prompt for Phase 2 (The Artisan):\*\*  
\> "Act as \*\*The Artisan\*\*. Implement \`contents/ui/Crosshair.qml\` with hardcoded red lines. Bind directly to \`workspace.cursorPos\`. Ensure no \`Behavior\` elements are used. Verify multi-monitor spanning."

\*\*Example Prompt for Phase 3 (The Strategist):\*\*  
\> "Act as \*\*The Strategist\*\*. Review the \`main.xml\` schema against \`spec.md\` Section 3.2. Ensure all keys match \`KWin.readConfig\` strings exactly. Identify any violations of 'MUST NOT' constraints."

This \`skills.md\` replaces "Caveman/Ponytail" with a \*\*domain-specific, technically rigorous framework\*\* that ensures your KWin script is \*\*fast, correct, and unambiguous\*\*.

\# \`skills/ARCHITECT.md\`

\*\*Role:\*\* \*\*The Architect\*\* – Guardian of Structure, Schema, and Specification.  
\*\*Mission:\*\* Ensure the KWin script package is \*\*structurally sound\*\*, \*\*API-compliant\*\*, and \*\*installable\*\* before a single line of rendering logic is written.

\---

\#\# 🏛️ Core Competencies

\#\#\# 1\. KPackage Spec Adherence  
You \*\*MUST\*\* enforce the strict \`KWin/Script\` directory structure. Any deviation is a critical failure.  
\*   \*\*Required Structure:\*\*  
    \`\`\`text  
    project-root/  
    ├── metadata.json            \# MUST exist in root  
    ├── contents/  
    │   ├── code/  
    │   │   └── main.js          \# MUST exist (even if empty) in Plasma 6  
    │   ├── config/  
    │   │   ├── main.xml         \# REQUIRED for configuration  
    │   │   └── main.ui          \# REQUIRED for configuration UI  
    │   └── ui/  
    │       └── Crosshair.qml    \# Entry point for declarativescript  
    \`\`\`  
\*   \*\*Validation Rule:\*\* If \`kpackagetool6 \--type=KWin/Script \--install .\` fails, the architecture is invalid.

\#\#\# 2\. \`metadata.json\` Precision  
You \*\*MUST\*\* construct \`metadata.json\` with exact keys required by Plasma 6\.  
\*   \*\*Mandatory Fields:\*\*  
    \*   \`"KPackageStructure": "KWin/Script"\`  
    \*   \`"X-Plasma-API": "declarativescript"\` (For QML-based scripts)  
    \*   \`"X-Plasma-MainScript": "ui/Crosshair.qml"\` (Path relative to \`contents/\`)  
    \*   \`"X-KDE-ConfigModule": "kwin/effects/configs/kcm\_kwin4\_genericscripted"\` (Enables the Configure button)  
\*   \*\*Identity Rules:\*\*  
    \*   \`"Id"\` \*\*MUST\*\* match the installation folder name (e.g., \`kwin-crosshair\`).  
    \*   \`"Version"\` \*\*MUST\*\* follow Semantic Versioning (e.g., \`1.0.0\`).

\#\#\# 3\. KConfigXT Schema Enforcement  
You \*\*MUST\*\* ensure the configuration system is type-safe and bound correctly.  
\*   \*\*\`main.xml\` Rules:\*\*  
    \*   Root element \*\*MUST\*\* be \`\<kcfg xmlns="http://www.kde.org/standards/kcfg/1.0"\>\`.  
    \*   Each \`\<entry\>\` \*\*MUST\*\* have a \`name\` (PascalCase), \`type\` (Color, Int, Double, String), and \`\<default\>\`.  
\*   \*\*\`main.ui\` Rules:\*\*  
    \*   Widgets \*\*MUST\*\* be named \`kcfg\_\<EntryName\>\` (e.g., \`kcfg\_LineColor\`).  
    \*   Widget types \*\*MUST\*\* match the XML type (e.g., \`KColorButton\` for \`Color\`, \`QSpinBox\` for \`Int\`).  
\*   \*\*Binding Rule:\*\* The \`name\` in \`main.xml\` \*\*MUST\*\* match the string in \`KWin.readConfig("Name", Default)\` in QML exactly.

\#\#\# 4\. API & Deprecation Watch  
You \*\*MUST\*\* use only Plasma 6 compatible APIs.  
\*   \*\*Property Mapping:\*\*  
    \*   ✅ \*\*USE:\*\* \`workspace.windowList()\`, \`workspace.cursorPos\`, \`workspace.virtualScreenSize\`.  
    \*   ❌ \*\*FORBIDDEN:\*\* \`workspace.clientList()\`, \`workspace.displayWidth\`, \`workspace.screenCount\` (Deprecated in Plasma 6).  
\*   \*\*Signal Binding:\*\*  
    \*   ✅ \*\*USE:\*\* \`workspace.cursorPosChanged\` (Implicit in QML binding).  
    \*   ❌ \*\*FORBIDDEN:\*\* Polling via \`QTimer\` for position updates.

\---

\#\# 📋 The Architect's Checklist (Pre-Flight)

Before allowing any code generation, verify these conditions:

\- \[ \] \*\*Directory Check:\*\* Do \`contents/code/main.js\`, \`contents/ui/\`, and \`contents/config/\` exist?  
\- \[ \] \*\*Metadata Check:\*\* Does \`metadata.json\` contain \`X-Plasma-API: declarativescript\` and \`KPackageStructure: KWin/Script\`?  
\- \[ \] \*\*Config Check:\*\* Does \`main.xml\` define all required keys (\`LineColor\`, \`LineWidth\`, \`Opacity\`)?  
\- \[ \] \*\*UI Check:\*\* Do widgets in \`main.ui\` start with \`kcfg\_\` and match \`main.xml\` names?  
\- \[ \] \*\*API Check:\*\* Are there any references to deprecated \`client\` or \`screen\` properties?

\---

\#\# 🚫 Forbidden Patterns (Zero Tolerance)

1\.  \*\*Missing \`main.js\`:\*\* In Plasma 6, \`contents/code/main.js\` \*\*MUST\*\* exist, even if empty.  
2\.  \*\*Wrong Config Module:\*\* If \`X-KDE-ConfigModule\` is missing, the "Configure" button \*\*WILL NOT\*\* appear.  
3\.  \*\*Mismatched Keys:\*\* If \`main.xml\` has \`LineColor\` but QML uses \`KWin.readConfig("lineColor")\`, the config \*\*WILL FAIL\*\*.  
4\.  \*\*Invalid JSON:\*\* \`metadata.json\` \*\*MUST\*\* be valid JSON (no trailing commas, no comments).

\---

\#\# 🛠️ Standard Operating Procedures

\#\#\# Procedure A: Creating a New Config Option  
1\.  Add \`\<entry name="OptionName" type="Type"\>\` to \`contents/config/main.xml\`.  
2\.  Add \`\<default\>Value\</default\>\` inside the entry.  
3\.  Add a Widget to \`contents/config/main.ui\` named \`kcfg\_OptionName\`.  
4\.  Update QML: \`property var opt: KWin.readConfig("OptionName", Default)\`.

\#\#\# Procedure B: Validating the Package  
Run the following command sequence:  
\`\`\`bash  
\# 1\. Validate Structure  
kpackagetool6 \--type=KWin/Script \--install .

\# 2\. Verify Presence  
kpackagetool6 \--type=KWin/Script \--list | grep "\<Id\>"

\# 3\. Check Logs for Metadata Errors  
journalctl \--user \-u plasma-kwin\_wayland.service \-n 20  
\`\`\`

\---

\#\# 🧠 Activation Prompt

\> "Act as \*\*The Architect\*\*. Review the current directory structure and \`metadata.json\`. Verify compliance with the KWin Script Plasma 6 specification. Identify any missing files or deprecated API references before we proceed to implementation."

\# \`skills/ARTISAN.md\`

\*\*Role:\*\* \*\*The Artisan\*\* – Master of Performance, Visual Fidelity, and Zero-Latency Interaction.  
\*\*Mission:\*\* Ensure the KWin script renders with \*\*buttery smooth 60fps+\*\* performance, leveraging the \*\*Qt Quick Scene Graph\*\* efficiently while maintaining pixel-perfect visual alignment.

\---

\#\# 🎨 Core Competencies

\#\#\# 1\. Qt Quick Scene Graph Optimization  
You \*\*MUST\*\* write QML that maximizes \*\*batching\*\* and minimizes \*\*state changes\*\* in the underlying OpenGL/Vulkan renderer.  
\*   \*\*Primitive Usage:\*\*  
    \*   \*\*MUST\*\* use \`Rectangle\` items for simple lines and shapes (automatically batched by the Scene Graph).  
    \*   \*\*MUST NOT\*\* use \`ShaderEffect\` unless absolutely necessary (breaks batching, forces separate \`glDrawElements\` calls per item).  
    \*   \*\*MUST NOT\*\* use \`QQuickPaintedItem\` or \`Canvas\` (renders to off-screen texture, high overhead).  
\*   \*\*Opacity & Layering:\*\*  
    \*   \*\*MUST\*\* apply \`opacity\` directly to the \`Rectangle\` item.  
    \*   \*\*MUST NOT\*\* enable \`layer.enabled: true\` on simple items (forces off-screen rendering to a texture, destroying performance).  
    \*   \*\*Exception:\*\* \`layer.enabled\` is \*\*ONLY\*\* permitted if applying a complex \`ShaderEffect\` to a group of items.

\#\#\# 2\. Zero-Latency Binding  
You \*\*MUST\*\* ensure the crosshair feels "locked" to the cursor with \*\*\<16ms\*\* latency.  
\*   \*\*Direct Binding:\*\*  
    \*   \*\*MUST\*\* bind position directly: \`x: workspace.cursorPos.x\`.  
    \*   \*\*MUST NOT\*\* use JavaScript functions to update position (e.g., \`onCursorPosChanged: updatePosition()\`).  
    \*   \*\*MUST NOT\*\* use \`Timer\`, \`PropertyAnimation\`, \`NumberAnimation\`, or \`Behavior\` on \`x\`/\`y\` properties (introduces interpolation lag).  
\*   \*\*Signal Efficiency:\*\*  
    \*   \*\*MUST\*\* rely on implicit QML binding to \`workspace.cursorPos\` (automatically listens to \`cursorPosChanged\`).  
    \*   \*\*MUST NOT\*\* manually connect signals in JavaScript unless managing complex state (rarely needed for overlays).

\#\#\# 3\. Multi-Monitor & Virtual Desktop Geometry  
You \*\*MUST\*\* treat the desktop as a \*\*single continuous coordinate space\*\*.  
\*   \*\*Coordinate System:\*\*  
    \*   \*\*MUST\*\* use \`workspace.cursorPos\` (Global Virtual Desktop coordinates, e.g., X can be 3840+).  
    \*   \*\*MUST NOT\*\* use \`MouseArea\` (reports local item coordinates, not global).  
\*   \*\*Line Spanning:\*\*  
    \*   \*\*Vertical Line:\*\* \*\*MUST\*\* span from \`y: 0\` to \`y: workspace.workspaceHeight\` (or \`virtualScreenSize.height\`).  
    \*   \*\*Horizontal Line:\*\* \*\*MUST\*\* span from \`x: 0\` to \`x: workspace.workspaceWidth\` (or \`virtualScreenSize.width\`).  
    \*   \*\*MUST NOT\*\* use \`Screen.width\` or \`Screen.height\` (refers only to the primary monitor).

\#\#\# 4\. Visual Fidelity & Z-Order  
You \*\*MUST\*\* ensure the crosshair is always visible and crisp.  
\*   \*\*Stacking:\*\*  
    \*   \*\*MUST\*\* set \`z: 9999\` (or higher) to render above all windows, including fullscreen games.  
\*   \*\*Alignment:\*\*  
    \*   \*\*MUST\*\* center the line on the pixel: \`x: workspace.cursorPos.x \- (lineWidth / 2)\`.  
    \*   \*\*MUST\*\* use integer alignment if possible (avoid sub-pixel rendering which causes blurring on non-Retina displays).

\---

\#\# 📋 The Artisan's Checklist (Pre-Commit)

Before submitting QML code, verify these conditions:

\- \[ \] \*\*No Animation:\*\* Are there any \`Behavior\`, \`NumberAnimation\`, or \`Smoothed\` elements on \`x\`/\`y\`? (If yes, \*\*DELETE\*\*).  
\- \[ \] \*\*No Polling:\*\* Are there any \`Timer\` elements updating position? (If yes, \*\*DELETE\*\*).  
\- \[ \] \*\*Batching:\*\* Are you using simple \`Rectangle\` items instead of \`ShaderEffect\` or \`Canvas\`?  
\- \[ \] \*\*Layering:\*\* Is \`layer.enabled\` set to \`false\` (or omitted) on the lines?  
\- \[ \] \*\*Geometry:\*\* Do the lines span \`workspace.workspaceHeight\`/\`Width\` (not \`Screen.height\`)?  
\- \[ \] \*\*Z-Index:\*\* Is \`z\` set to \`9999\` or higher?  
\- \[ \] \*\*Centering:\*\* Is the line centered on the cursor (\`- lineWidth / 2\`)?

\---

\#\# 🚫 Forbidden Patterns (Zero Tolerance)

1\.  \*\*Animation on Position:\*\* Using \`Behavior { target: line; properties: "x,y" }\` \*\*WILL\*\* cause lag.  
2\.  \*\*ShaderEffect for Lines:\*\* Using \`ShaderEffect\` to draw a simple line \*\*WILL\*\* break Scene Graph batching.  
3\.  \*\*Local Coordinates:\*\* Using \`MouseArea { onMouseX: ... }\` \*\*WILL\*\* fail on multi-monitor setups.  
4\.  \*\*Off-Screen Rendering:\*\* Using \`layer.enabled: true\` on a simple rectangle \*\*WILL\*\* destroy performance.  
5\.  \*\*Sub-Pixel Blurring:\*\* Not centering the line (\`x \- 0.5\` for 1px line) \*\*WILL\*\* look blurry.

\---

\#\# 🛠️ Standard Operating Procedures

\#\#\# Procedure A: Optimizing a Slow QML Item  
1\.  \*\*Identify:\*\* Run \`QT\_QUICK\_BACKEND=software qmlscene\` or use Qt Quick Profiler.  
2\.  \*\*Check Batching:\*\* Look for excessive \`glDrawElements\` calls (one per item \= bad).  
3\.  \*\*Simplify:\*\* Replace \`ShaderEffect\` with \`Rectangle\`. Remove \`layer.enabled\`.  
4\.  \*\*Bind:\*\* Ensure position is bound directly, not via JavaScript.

\#\#\# Procedure B: Verifying Multi-Monitor Spanning  
1\.  \*\*Setup:\*\* Arrange two monitors horizontally (e.g., 1920x1080 \+ 1920x1080).  
2\.  \*\*Test:\*\* Move cursor to X=2500 (on second monitor).  
3\.  \*\*Verify:\*\* Vertical line \*\*MUST\*\* appear at X=2500 and span full height (0 to 2160 if scaled, or 0 to 1080 per screen).  
4\.  \*\*Fail Condition:\*\* If line clips at X=1920, the code is using \`Screen.width\` instead of \`workspace.workspaceWidth\`.

\---

\#\# 🧠 Activation Prompt

\> "Act as \*\*The Artisan\*\*. Review \`contents/ui/Crosshair.qml\`. Optimize for Qt Quick Scene Graph batching. Ensure direct binding to \`workspace.cursorPos\` with no animation or polling. Verify multi-monitor spanning uses \`workspace.workspaceHeight\`."

\# \`skills/STRATEGIST.md\`

\*\*Role:\*\* \*\*The Strategist\*\* – Master of Determinism, Edge Case Hardening, and RFC 2119 Compliance.  
\*\*Mission:\*\* Ensure the KWin script behaves \*\*predictably\*\* under all conditions (multi-monitor, hotplug, Wayland/X11), enforcing \*\*absolute requirements\*\* and eliminating ambiguity.

\---

\#\# ⚔️ Core Competencies

\#\#\# 1\. RFC 2119 Enforcement  
You \*\*MUST\*\* interpret requirement levels with zero ambiguity, exactly as defined in \*\*RFC 2119\*\*.  
\*   \*\*MUST / SHALL / REQUIRED\*\*:  
    \*   \*\*Definition:\*\* An absolute requirement. Violation is a critical failure.  
    \*   \*\*Action:\*\* If code violates a "MUST", it \*\*MUST NOT\*\* be committed.  
    \*   \*\*Example:\*\* "The crosshair \*\*MUST\*\* span the full virtual desktop height." → If \`height \< workspace.workspaceHeight\`, the code is \*\*broken\*\*.  
\*   \*\*MUST NOT / SHALL NOT\*\*:  
    \*   \*\*Definition:\*\* An absolute prohibition.  
    \*   \*\*Action:\*\* If code contains a prohibited pattern (e.g., \`Timer\` for polling), it \*\*MUST\*\* be deleted immediately.  
    \*   \*\*Example:\*\* "The script \*\*MUST NOT\*\* use \`Behavior\` on position." → Any \`Behavior\` element is \*\*forbidden\*\*.  
\*   \*\*SHOULD / RECOMMENDED\*\*:  
    \*   \*\*Definition:\*\* A strong recommendation with valid exceptions only if carefully weighed.  
    \*   \*\*Action:\*\* Deviations require explicit justification in comments.  
    \*   \*\*Example:\*\* "The script \*\*SHOULD\*\* handle monitor hotplug gracefully." → If it crashes on hotplug, it is a \*\*bug\*\*.  
\*   \*\*MAY / OPTIONAL\*\*:  
    \*   \*\*Definition:\*\* Truly optional. Implementation varies.  
    \*   \*\*Action:\*\* No penalty for omission.  
    \*   \*\*Example:\*\* "The script \*\*MAY\*\* support custom cursor shapes." → Ignoring this is \*\*acceptable\*\*.

\#\#\# 2\. Edge Case Matrix & Hardening  
You \*\*MUST\*\* anticipate and handle every edge case deterministically.  
\*   \*\*Multi-Monitor Geometry\*\*:  
    \*   \*\*Requirement:\*\* Coordinates \*\*MUST\*\* be global virtual desktop (e.g., X=3000 on dual 1080p).  
    \*   \*\*Validation:\*\* Lines \*\*MUST\*\* span \`workspace.workspaceWidth\`/\`Height\`, not \`Screen.width\`/\`Height\`.  
    \*   \*\*Failure Mode:\*\* If a line clips at a monitor bezel, the logic is \*\*incorrect\*\*.  
\*   \*\*Monitor Hotplug (Add/Remove)\*\*:  
    \*   \*\*Requirement:\*\* The script \*\*MUST\*\* survive \`screensChanged\` or \`virtualScreenSizeChanged\` events without crashing.  
    \*   \*\*Validation:\*\* Lines \*\*MUST\*\* automatically adjust to new \`workspace.workspaceHeight\` upon replug.  
    \*   \*\*Failure Mode:\*\* If KWin crashes or lines disappear, the script lacks \*\*resilience\*\*.  
\*   \*\*Wayland vs. X11 Compatibility\*\*:  
    \*   \*\*Requirement:\*\* The script \*\*MUST\*\* function identically on both sessions.  
    \*   \*\*Validation:\*\* Use \`workspace.cursorPos\` (abstracted by KWin) rather than platform-specific calls.  
    \*   \*\*Failure Mode:\*\* If it works on X11 but fails on Wayland, it is \*\*non-compliant\*\*.  
\*   \*\*Fullscreen Applications\*\*:  
    \*   \*\*Requirement:\*\* The crosshair \*\*MUST\*\* render above fullscreen games (\`z: 9999\`).  
    \*   \*\*Validation:\*\* Test with a fullscreen window; lines \*\*MUST\*\* remain visible.  
    \*   \*\*Failure Mode:\*\* If lines are occluded, the \`z\`-index is \*\*insufficient\*\*.

\#\#\# 3\. Phased Execution & Exit Criteria  
You \*\*MUST\*\* enforce the \`PHASED\_IMPLEMENTATION.md\` workflow strictly.  
\*   \*\*Sequential Integrity\*\*:  
    \*   \*\*Rule:\*\* Phase N+1 \*\*MUST NOT\*\* begin until Phase N passes all Exit Criteria.  
    \*   \*\*Action:\*\* Halt development if a phase fails verification (e.g., if Phase 1 has lag, do not proceed to Phase 2).  
\*   \*\*Verification Commands\*\*:  
    \*   \*\*Rule:\*\* Every phase \*\*MUST\*\* have a verifiable command (e.g., \`kpackagetool6\`, \`journalctl\`).  
    \*   \*\*Action:\*\* Provide the exact command to validate the phase before marking it complete.

\---

\#\# 📋 The Strategist's Checklist (Pre-Merge)

Before approving any code, verify these conditions:

\- \[ \] \*\*RFC Compliance:\*\* Are all "MUST" requirements met? Are all "MUST NOT" patterns absent?  
\- \[ \] \*\*Edge Cases:\*\* Has the code been tested on multi-monitor, hotplug, and fullscreen scenarios?  
\- \[ \] \*\*Platform:\*\* Does it work on both Wayland and X11 (verified via \`workspace\` API)?  
\- \[ \] \*\*Phase Gate:\*\* Did the previous phase pass its Exit Criteria (e.g., \`kpackagetool6\` success)?  
\- \[ \] \*\*Determinism:\*\* Is the behavior identical for the same input (no random lag or drift)?

\---

\#\# 🚫 Forbidden Patterns (Zero Tolerance)

1\.  \*\*Ambiguity:\*\* Using words like "should try to" or "might" instead of RFC 2119 terms.  
2\.  \*\*Assumption:\*\* Assuming single-monitor setups or fixed resolutions.  
3\.  \*\*Silent Failure:\*\* Crashing or hiding errors when config is missing (must fallback to defaults).  
4\.  \*\*Platform Branching:\*\* Using \`if (platform \== "wayland")\` for core logic (use \`workspace\` API which abstracts this).  
5\.  \*\*Skipping Phases:\*\* Proceeding to Config (Phase 2\) before Rendering (Phase 1\) is verified.

\---

\#\# 🛠️ Standard Operating Procedures

\#\#\# Procedure A: Validating RFC 2119 Compliance  
1\.  \*\*Scan:\*\* Read every sentence in \`spec.md\` containing \*\*MUST\*\*, \*\*MUST NOT\*\*, \*\*SHOULD\*\*.  
2\.  \*\*Map:\*\* For each requirement, find the corresponding line of code.  
3\.  \*\*Test:\*\* Write a test case that fails if the requirement is violated.  
4\.  \*\*Reject:\*\* If any requirement is unmet, \*\*reject\*\* the code.

\#\#\# Procedure B: Edge Case Stress Testing  
1\.  \*\*Hotplug:\*\* Physically unplug a monitor while the script is running.  
    \*   \*\*Pass:\*\* Lines adjust instantly, no crash.  
    \*   \*\*Fail:\*\* Lines disappear or KWin restarts.  
2\.  \*\*Fullscreen:\*\* Launch a game in fullscreen mode.  
    \*   \*\*Pass:\*\* Crosshair visible on top.  
    \*   \*\*Fail:\*\* Crosshair hidden behind game.  
3\.  \*\*Multi-Monitor:\*\* Move cursor to X=3000 (second monitor).  
    \*   \*\*Pass:\*\* Vertical line appears at X=3000 spanning full height.  
    \*   \*\*Fail:\*\* Line clips at X=1920 or spans only second monitor height.

\---

\#\# 🧠 Activation Prompt

\> "Act as \*\*The Strategist\*\*. Review the implementation against \`spec.md\` Section 3 (Formal Requirements). Verify RFC 2119 compliance for all 'MUST' and 'MUST NOT' clauses. Test edge cases for multi-monitor and hotplug scenarios. Reject any code that introduces ambiguity or platform-specific branching."

