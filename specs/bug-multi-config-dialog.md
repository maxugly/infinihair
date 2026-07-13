# BUG-02 — Multiple Configure dialogs

**Status:** Confirmed upstream KWin KCM — **wontfix in-package**  
**Priority:** P3 (UX annoyance; does not break crosshair)  
**Updated:** 2026-07-13 (Max still hits it; Grok confirmed source)

## Symptom

Every click of **Configure** on a KWin script in System Settings opens a **new** settings window (stacks forever).

## Root cause (KWin, not infinihair)

File: `kwin/src/kcms/scripts/module.cpp` (Plasma 6 / current master):

```cpp
void Module::configure(const KPluginMetaData &data)
{
    auto dialog = new KCMultiDialog();
    dialog->addModule(data, QVariantList{data.pluginId(), QStringLiteral("KWin/Script")});
    dialog->setAttribute(Qt::WA_DeleteOnClose);
    dialog->show();
}
```

Called from the scripts KCM UI as `kcm.configure(model.config)`.

No check for an existing dialog for that `pluginId`.

## Scope

Affects **every** script using `X-KDE-ConfigModule: kwin/effects/configs/kcm_kwin4_genericscripted` (Infinite Crosshair, Mouse Tiler, Video Wall, …).

## Decision

| option | verdict |
|---|---|
| Fix inside pure KWin script package | **Impossible** |
| Custom config module for infinihair only | Out of scope |
| Upstream KWin patch | **Correct fix** |
| Document + workaround | **Current** |

## Suggested upstream fix (sketch)

Keep open dialogs by plugin id; raise if present:

```cpp
// Module members: QHash<QString, QPointer<KCMultiDialog>> m_configDialogs;

void Module::configure(const KPluginMetaData &data)
{
    const QString id = data.pluginId();
    if (auto *existing = m_configDialogs.value(id).data()) {
        existing->raise();
        existing->activateWindow();
        return;
    }
    auto *dialog = new KCMultiDialog();
    dialog->addModule(data, QVariantList{id, QStringLiteral("KWin/Script")});
    dialog->setAttribute(Qt::WA_DeleteOnClose);
    m_configDialogs.insert(id, dialog);
    QObject::connect(dialog, &QObject::destroyed, this, [this, id]() {
        m_configDialogs.remove(id);
    });
    dialog->show();
}
```

(Exact API may need KF6 `KCMultiDialog` review; intent is raise-or-create.)

## Workaround

Close extra windows; click Configure once.

## Exit criteria (package)

- [x] Decision + source citation recorded  
- [x] STATUS documents known issue  
- [ ] Optional: Max/Bones file bugs.kde.org or invent.kde.org MR  
