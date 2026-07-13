# Phased Implementation Plan: KWin Infinite Crosshair

**Strategy:** Incremental, Verified, Deterministic.  
**Rule:** Do not proceed to Phase N+1 until Phase N passes all Exit Criteria.

---

## 🏁 Phase 0: Skeleton & Validation
**Objective:** Establish the directory structure and metadata so the script is recognized by KWin.  
**Scope:** `metadata.json`, directory tree, empty placeholder files.

*   **Tasks:**  
    1.  Create directory structure (`contents/ui`, `contents/config`, `contents/code`).  
    2.  Write `metadata.json` with strict `X-Plasma-API: declarativescript`.  
    3.  Create empty `Crosshair.qml` and `main.js`.  
*   **Exit Criterion (The "Litmus Test"):**  
    *   Command: `kpackagetool6 --type=KWin/Script --install .`  
    *   **Result:** Command returns exit code `0`.  
    *   **Verification:** Script appears in System Settings > KWin Scripts list (even if disabled).  
*   **Prompt Strategy:** "Create the KPackage skeleton. Verify `metadata.json` syntax. Do not write logic yet."

---

## 🎨 Phase 1: The "Red Line" (Hardcoded Render)
**Objective:** Prove the rendering pipeline works with **zero latency**.  
**Scope:** `contents/ui/Crosshair.qml` (Hardcoded values only).

*   **Tasks:**  
    1.  Implement `Crosshair.qml` with **hardcoded** red lines (`#FF0000`, 1px).  
    2.  Bind directly to `workspace.cursorPos`.  
    3.  Set `z: 9999`.  
    4.  **Prohibition:** Do NOT import config files yet. Do NOT use variables.  
*   **Exit Criterion:**  
    *   **Visual:** Lines appear instantly upon enabling script.  
    *   **Performance:** Mouse movement feels "locked" (no lag).  
    *   **Geometry:** Lines span full screen (test on multi-monitor: lines must cross bezels).  
*   **Prompt Strategy:** "Implement the QML renderer with hardcoded values. Optimize for zero-latency binding to `workspace.cursorPos`. Verify multi-monitor spanning."

---

## ⚙️ Phase 2: Configuration Schema (The "Law")
**Objective:** Externalize visual properties so they are user-configurable.  
**Scope:** `contents/config/main.xml`, `contents/config/main.ui`.

*   **Tasks:**  
    1.  Define `main.xml` schema (Keys: `LineColor`, `LineWidth`, `Opacity`).  
    2.  Design `main.ui` with matching `kcfg_` named widgets.  
    3.  Update `metadata.json` to point to the config module.  
*   **Exit Criterion:**  
    *   **UI:** "Configure" button is clickable in System Settings.  
    *   **Persistence:** Changing a value, clicking Apply, then disabling/enabling the script **retains** the value.  
    *   **Validation:** `kcfgc` compiler (implicit in kpackagetool) reports no errors.  
*   **Prompt Strategy:** "Create the KConfigXT schema and Qt Widgets UI. Ensure key names match exactly. Verify the 'Configure' button appears."

---

## 🔌 Phase 3: Binding Config to QML
**Objective:** Connect the "Law" (Config) to the "Execution" (QML).  
**Scope:** `contents/ui/Crosshair.qml` (Refactor).

*   **Tasks:**  
    1.  Replace hardcoded values in `Crosshair.qml` with `KWin.readConfig()`.  
    2.  Ensure defaults in QML match defaults in `main.xml`.  
    3.  Implement dynamic update (changing config updates lines immediately without reload).  
*   **Exit Criterion:**  
    *   **Functionality:** Changing color in settings updates the crosshair instantly.  
    *   **Robustness:** If config is missing/corrupt, script falls back to defaults (Red, 1px) without crashing.  
*   **Prompt Strategy:** "Refactor QML to read from `KWin.readConfig()`. Ensure dynamic updates work without script reload."

---

## 🛡️ Phase 4: Edge Case Hardening
**Objective:** Ensure the script survives real-world usage scenarios.  
**Scope:** Logic checks, multi-monitor math, DPI handling.

*   **Tasks:**  
    1.  Verify behavior when monitors are added/removed (hotplug).  
    2.  Verify behavior when switching between Wayland and X11.  
    3.  Verify behavior when a fullscreen game is launched (Z-index check).  
*   **Exit Criterion:**  
    *   **Stress Test:** Unplug secondary monitor → Crosshair remains visible on primary.  
    *   **Fullscreen:** Launch game → Crosshair remains visible on top.  
    *   **Logs:** `journalctl` shows **zero** errors during these events.  
*   **Prompt Strategy:** "Audit the code for multi-monitor and hotplug edge cases. Ensure `workspace.workspaceWidth` is used instead of `Screen.width`."

---

## 📦 Phase 5: Packaging & Distribution
**Objective:** Create the final artifact for sharing.  
**Scope:** `scripts/package.sh`, `README.md`.

*   **Tasks:**  
    1.  Write `package.sh` to generate `.kwinscript`.  
    2.  Finalize `README.md` with installation instructions.  
    3.  Git tag release (e.g., `v1.0.0`).  
*   **Exit Criterion:**  
    *   **Artifact:** `crosshair.kwinscript` exists.  
    *   **Clean Install:** Installing the `.kwinscript` on a fresh KDE profile works perfectly.  
*   **Prompt Strategy:** "Create the packaging script and finalize documentation. Generate the .kwinscript artifact."

---

## 🧠 How to Use This with Agents (The "Sun Tzu" Method)

When prompting, you **never** ask for the whole thing. You issue **Orders** based on the current phase.

**Example Prompt for Phase 1:**  
> "Execute **Phase 1** of `PHASED_IMPLEMENTATION.md`.  
> 1.  Read `constitution.md` for performance constraints.  
> 2.  Write `contents/ui/Crosshair.qml` with **hardcoded** red lines.  
> 3.  **STOP** after writing the file.  
> 4.  Provide the command to verify the **Exit Criterion** (visual check)."

**Why this works:**  
*   **Compartmentalization:** The agent cannot hallucinate config files (Phase 2) while you are still testing rendering (Phase 1).  
*   **Verification:** You physically verify the "Exit Criterion" before giving the next order. If Phase 1 lags, you fix it *before* building Phase 2 on top of it.  
*   **Determinism:** There is only one correct output for each phase.

This turns your development process into a **deterministic assembly line**, exactly as you requested.
