# Project Todo List — infinihair

> **Bones** writes and prioritizes. **Grok** marks `[x]` when done.  
> Specs live in `specs/`. Do not invent architecture in this file — link a spec.

## Status

| phase | status | notes |
|---|---|---|
| **0** Skeleton & validation | **PASS** | package + check + kpackagetool install OK (2026-07-13) |
| **1** Red line (hardcoded) | **PASS** | implemented 2026-07-13; Grit static QA PASS — Max visual smoke pending |
| **2** Config schema + UI | pending | |
| **3** Bind config to QML | pending | |
| **4** Edge case hardening | pending | |
| **5** Packaging / dist | partial | `package.sh` / `check.sh` / CI exist; `reload.sh` empty |

---

## Phase 0 — Skeleton (Bones)

- [x] KPackage layout: `contents/{ui,code,config}`, `metadata.json`
- [x] `X-Plasma-API: declarativescript`, `X-Plasma-MainScript: ui/main.qml`
- [x] `KPlugin.Id: kwin-crosshair`, Version SemVer `1.0.0`
- [x] `contents/code/main.js` lifecycle stub
- [x] `contents/ui/main.qml` entry + `Crosshair.qml` placeholder (no render logic)
- [x] Litmus: `./scripts/package.sh` && `./scripts/check.sh` exit 0
- [x] Crew setup: `AGENTS.md`, `specs/`, `qa/`, chat handoff (this cycle)

Spec: [specs/phase-0-skeleton.md](specs/phase-0-skeleton.md)

---

## Phase 1 — Red line / Artisan (Grok)

Spec: [specs/phase-1-red-line.md](specs/phase-1-red-line.md) *(Bones to flesh if thin)*

- [ ] Implement hardcoded red lines in `contents/ui/Crosshair.qml` (`#FF0000`, 1px, opacity 0.8)
- [ ] Bind position to `workspace.cursorPos` only (no Timer, no Behavior)
- [ ] `z: 9999`; span full virtual desktop (`workspace.workspaceWidth` / `workspace.workspaceHeight` or virtual screen size)
- [ ] Keep `main.qml` as thin entry only
- [ ] Do **not** add `KWin.readConfig` yet (Phase 3)
- [ ] Run `./scripts/package.sh` && `./scripts/check.sh`
- [ ] Hand off to Grit for QA review under `qa/`

---

## Phase 2 — Config schema (Bones plan → Grok)

- [ ] Spec in `specs/config-ui.md` (if not covered by `spec.md` §3–4)
- [ ] `contents/config/main.xml` keys: LineColor, LineWidth, Opacity
- [ ] `contents/config/main.ui` with `kcfg_*` widgets
- [ ] Configure button works in System Settings

---

## Phase 3 — Bind config (Grok)

- [ ] `KWin.readConfig` in QML; defaults match `main.xml`
- [ ] Dynamic update without full session restart where possible

---

## Phase 4 — Edge cases (Grit + Grok)

- [ ] Multi-monitor, hotplug, fullscreen z-order, Wayland/X11 smoke

---

## Phase 5 — Packaging polish

- [x] `scripts/package.sh` (python3-only, distro-agnostic)
- [x] `scripts/check.sh`
- [x] `.github/workflows/ci.yml`
- [ ] `scripts/reload.sh` body
- [ ] README paths → `maxugly/infinihair`

---

## Backlog / process

- [x] Multi-agent crew file (`AGENTS.md`) matching civitui pattern
- [ ] Delete or archive accidental GitHub repo `maxugly/-hair` if still present
- [ ] Optional: pre-commit hook calling `./scripts/package.sh`
