# Project Todo List — infinihair

> **Bones** writes and prioritizes. **Grok** marks `[x]` when done.  
> **Live snapshot:** [STATUS.md](STATUS.md)

## Status (2026-07-13)

| item | status |
|---|---|
| Disable / re-enable in KWin Scripts | **PASS (Max)** |
| Color picker + live apply | **PASS (Max)** |
| Multi Configure dialogs | **Upstream KWin** — documented |
| Offset guides (2nd V/H + color + offset) | **Shipped** |
| Automagic border align + sticky while drag | **Shipped `offset5`** |
| Tick units Imperial / Metric | **Shipped `units1`** |
| buildId | `2026-07-13-units1` |

---

## Done recently

- [x] Color button restored  
- [x] Lifecycle / re-enable path accepted by Max  
- [x] BUG-02 documented as KDE host (`KCMultiDialog`)  
- [x] Offset guides v2–v5 (secondary lines, auto, sticky drag)  
- [x] Spec `specs/offset-line-mode.md` + STATUS/README  

## Optional / backlog

### BUG-02 Multi Configure (upstream only)

- [ ] Optional: bugs.kde.org / invent.kde.org MR  

### Product debt

- [ ] Structural: thin `main.qml` + `Crosshair.qml` SSoT (no full dupe)  
- [ ] Revisit config poll / python vs constitution wording  
- [ ] Multi-monitor / fullscreen smoke notes from Max  

### Packaging

- [x] `package.sh` / `check.sh` / `reload.sh`  
- [x] GitHub `maxugly/infinihair`  
