# QA Review — toggle1 (BUG-01)

**Date:** 2026-07-13  
**Reviewer:** Grit (Grok)  
**Commit:** uncommitted working tree on top of `e61efa5` (base)  
**buildId:** `2026-07-13-toggle1`  
**Subject:** BUG-01 — keep overlay Window mapped; gate draw items on `crosshairEnabled`

## Quality Gates

| gate | result |
|---|---|
| `./scripts/package.sh` | **PASS** (`crosshair.kwinscript` 17157 bytes) |
| `./scripts/check.sh` | **PASS** (kpackagetool6 upgrade OK; shellcheck skipped) |

## Constitution Compliance

- [x] No Timer / **cursor** polling — lines bind `Workspace.cursorPos` directly
- [x] No Python / external overlay **core** (python3 only in pre-existing config-disk poll path)
- [x] No Behavior/animation on x/y
- [x] declarativescript + `ui/main.qml` entry (`metadata.json`)
- [x] Global virtual-desktop geometry (`Workspace.virtualScreenSize`, `Workspace.cursorPos`)
- [x] Distro-agnostic scripts (no apt/pacman in project build)

### Timer / poll inventory (this tree)

| mechanism | purpose | cursor-related? | BUG-01 change? |
|---|---|---|---|
| `P5.DataSource` `interval: 500` | live kwinrc config poll | no | no (pre-existing debt) |
| `Timer` `hideClaimRetry` 250ms ×8 | claim skip* after map | no | no longer restarted on toggle (correct once Window stays mapped) |

**No new cursor-position Timer.** Constitution §2.A / §6 satisfied for this fix.

## Spec Compliance (`specs/bug-toggle-input.md`)

| # | requirement | static result |
|---|---|---|
| 1 | Toggle hides/shows **visuals** only | **PASS** — `toggleCrosshair()` flips `crosshairEnabled` only |
| 2 | MUST NOT unmap overlay Window to hide | **PASS** — `Window.visible: true` always |
| 3 | After off→on, pointer reaches underlying UI | **PENDING Max smoke** (static: `WindowTransparentForInput` kept; no unmap/remap) |
| 4 | When hidden, lines/ticks MUST NOT paint | **PASS** — V/H `Rectangle`s + `tickOrigin` gated on `crosshairEnabled` |
| 5 | Shortcut / action / skip* claim behavior remain | **PASS** — `ShortcutHandler` unchanged; claim still onCompleted + hideClaimRetry |
| 6 | No cursor-position Timer polling | **PASS** |
| plan | `main.qml` ↔ `Crosshair.qml` in sync | **PASS** — identical digests (`ba92930be21f…`) |
| plan | bump `buildId` | **PASS** — `2026-07-13-toggle1` |

## Diff summary (reviewed)

Files: `contents/ui/main.qml`, `contents/ui/Crosshair.qml` (mirror).

1. `buildId`: `persist1` → `toggle1`
2. `Window.visible`: `root.crosshairEnabled` → `true` (+ BUG-01 comment)
3. Vertical / horizontal lines: `visible: root.crosshairEnabled`
4. Ticks: `visible: root.crosshairEnabled && showInchTicks && tickStepPx > 0.5`
5. `toggleCrosshair()`: drop re-claim restart on ON (visual-only; buildId in log)

No other product surfaces touched for this fix. Docs/specs/TODO/STATUS also dirty in tree — out of scope for this code verdict.

## Findings

1. **Non-blocking / expected:** Exit criterion “Max: 10× Meta+Shift+X” is human smoke — not exercised here.
2. **Non-blocking / pre-existing debt:** config poll python3 + 500ms DataSource; main/Crosshair monolith dupe; RGB ints vs Color. Documented in STATUS; not introduced by toggle1.
3. **Non-blocking / gate flake note:** First `check.sh` in this session hit install-after-failed-upgrade (`already exists`); immediate re-run **PASS** with `--upgrade`. Not a product defect; watch if CI sees the same race under `set -e` + `|| install` fallback.

No constitution regressions. No scope creep into BUG-02/03.

## Verdict

**PASS — ready for Max** smoke (Meta+Shift+X ×10; confirm hide/show + desktop/settings still clickable; journal `ready build=2026-07-13-toggle1`).

Static gates green. Spec requirements 1–2, 4–6 met in code. Requirement 3 is runtime-only on Wayland and needs Max.
