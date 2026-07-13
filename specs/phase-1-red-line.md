# Spec: Phase 1 — Hardcoded Red Line

**Status:** READY for Grok (Implementer)  
**Owner:** Bones (Architect)  
**Skill:** `skills/ARTISAN.md`

## Goal

Prove zero-latency rendering: full-screen vertical + horizontal lines follow the
cursor with no perceptible lag.

## Requirements (MUST)

1. Implement in `contents/ui/Crosshair.qml` only (keep `main.qml` as thin entry).
2. Two `Rectangle` lines, color `#FF0000`, width `1`, opacity `0.8`, `z: 9999`.
3. Position from `workspace.cursorPos` via direct property binding.
4. Vertical span: full virtual height (`workspace.workspaceHeight` or equivalent virtual screen height).
5. Horizontal span: full virtual width (`workspace.workspaceWidth` or equivalent).
6. Center line on pixel (`x - width/2` / `y - height/2` as appropriate).

## MUST NOT

1. `Timer` / polling
2. `Behavior`, `NumberAnimation`, or smoothing on `x`/`y`
3. `KWin.readConfig` (Phase 3)
4. Python, C++, external overlays
5. Single-monitor-only `Screen.width` / `Screen.height` for spanning

## Exit criteria

- Visual: lines appear when script enabled; feel locked to cursor
- Multi-monitor: lines cross bezels (global coordinates)
- Gates: `./scripts/package.sh` && `./scripts/check.sh` exit 0
- Grit writes `qa/review-*.md`

## Out of scope

Config UI, opacity/color settings, packaging polish.
