# BUG-02 — Multiple Configure dialogs

**Status:** Decision — **wontfix in-package** (KCM host behavior)  
**Priority:** P2 (document; do not thrash product QML)  
**Updated:** 2026-07-13 (Grok + local binary evidence; Bones run timed out mid-research)

## Symptom

Every click of **Configure** on Infinite Crosshair in System Settings → KWin Scripts opens a **new** settings window.

## Context

- Package uses `"X-KDE-ConfigModule": "kwin/effects/configs/kcm_kwin4_genericscripted"`.
- UI: `contents/ui/config.ui` + schema `contents/config/main.xml`.
- Our package **does not** open dialogs from QML.

## Evidence (host owns the dialog)

From `kcm_kwin_scripts.so` strings / symbols on this machine:

- QML trigger: `onConfigTriggered: kcm.configure(model.config)`
- Dialog type: `KCMultiDialog` (`addModule` + `QWidget::show`)

Each Configure action constructs and shows a new multi-dialog. There is **no package-level API** in `config.ui` / `main.xml` to register a singleton or raise-existing window.

## Decision

| option | verdict |
|---|---|
| Fix inside pure KWin script package | **Not available** with genericscripted KCM |
| Custom C++/QML KCM just for singleton dialog | Out of scope / disproportionate |
| Upstream KDE fix (raise-or-reuse dialog) | Correct long-term home |
| Document as known issue | **Accepted for now** |

**Resolution for infinihair:** **wontfix-package**. Operators close extra dialogs manually. Prefer one Configure click.

## Work remaining

- [x] Written decision (this file)
- [ ] Optional: one-line known issue in `README.md` (Grok when touching README polish)
- [ ] Optional: Max file/upstream note against KWin scripts KCM if annoying enough
- [x] TODO: do not schedule Grok implementation for BUG-02

## Exit criteria

- [x] Decision recorded
- [x] Not blocking BUG-01 / product stability
