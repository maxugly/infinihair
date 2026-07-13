# STATUS — infinihair

**Date:** 2026-07-13  
**Repo:** `~/.local/share/kwin/scripts/crosshair/` → https://github.com/maxugly/infinihair  
**Plugin id:** `kwin-crosshair`  
**buildId:** `2026-07-13-offset2`

---

## One-line status

**Disable / re-enable works (Max confirmed).** Color picker works with live apply.  
**Offset line mode (v1)** available — borders under grab, not cursor.  
**Open annoyance:** every Configure click opens a **new** settings window — **KWin System Settings bug**, not fixable inside this package.

---

## Max confirmed (2026-07-13)

| item | result |
|---|---|
| Disable → enable in KWin Scripts | **Works** |
| Color picker present | **Yes** |
| Settings / color affect crosshair | **Yes** (after lifecycle fixes + session on reen1) |
| Configure button spawns many windows | **Still yes** — each click = new dialog |
| Offset line mode | **Shipped v1** — Max smoke pending |

### Offset line mode (v1) — shortcuts

| shortcut | action |
|---|---|
| **Meta+Shift+O** | Toggle offset mode |
| **Meta+Shift+B** | Capture nearest window border under cursor (turns mode on) |
| **Meta+Shift+C** | Clear offset / mode off |

While **moving/resizing** a window (config: *Auto offset on move*, default on), offsets update so lines track nearest frame edges. Spec: `specs/offset-line-mode.md`.

---

## BUG-02 — Multiple Configure dialogs

### Symptom

System Settings → Window Management → KWin Scripts → gear/Configure on Infinite Crosshair: **every click** opens another dialog.

### Root cause (upstream KWin, proven)

From current KWin source `src/kcms/scripts/module.cpp`:

```cpp
void Module::configure(const KPluginMetaData &data)
{
    auto dialog = new KCMultiDialog();
    dialog->addModule(data, QVariantList{data.pluginId(), QStringLiteral("KWin/Script")});
    dialog->setAttribute(Qt::WA_DeleteOnClose);
    dialog->show();
}
```

- **Always** `new KCMultiDialog()` — no “already open?” map, no raise/focus existing.
- Triggered from KCM QML: `onConfigTriggered: kcm.configure(model.config)`.
- Our package only supplies `contents/ui/config.ui` + `main.xml`. We never open the dialog.

### What we cannot do in-package

| approach | why not |
|---|---|
| Change `config.ui` / `main.xml` | No singleton API |
| QML in the script | Does not own the Configure button |
| Custom C++ KCM | New project, not a script |

### What would fix it (upstream)

Patch `Module::configure` to keep a `QHash<QString, QPointer<KCMultiDialog>>` (or similar) keyed by `pluginId()`: if a dialog for that script is already open, `raise()` / `activateWindow()`; else create one. Same pattern as many other KCMs.

- Spec note: `specs/bug-multi-config-dialog.md`
- Optional: file https://bugs.kde.org against product **kwin**, component **scripts** / **kcm_kwin_scripts**
- Affects **all** configurable KWin scripts (mousetiler, videowall, etc.), not only infinihair

### Workaround for Max

Close extras manually; one Configure click until upstream ships a fix.

---

## Architecture notes (still true)

- Paint: full-screen `Qt.Window` + `Workspace.cursorPos` (not bare Item).
- Config: `KColorButton` → `LineColor`; disk also mirrors `LineColorR/G/B` for re-enable robustness; 500ms disk poll for live Apply.
- Peers (mousetiler, …) share the same Configure host → **same multi-dialog behavior**.
- Long session + package upgrade: Settings re-enable uses package path; may need KWin restart once if body looks ancient (see research notes).

---

## Process

Lifecycle research is **closed** (Max PASS). Multi-dialog is **documented KDE host behavior**.

Next product work: **spec-driven** (Bones → Grok → Grit). Do not thrash color storage or Window flags without evidence.

---

## Crew

| role | agent | now |
|---|---|---|
| Architect | Bones | next feature specs only when Max asks |
| Implementer | Grok | docs / tasked features |
| QA | Grit | gates on code PRs |
| Operator | Max | ship criteria; one Configure click (KDE) |

Chat: `~/.hermes/agents/chat.md`
