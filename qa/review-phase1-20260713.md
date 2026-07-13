# QA Review — Phase 1 red line

**Date:** 2026-07-13
**Reviewer:** Grit (Grok)
**Commit:** (pending this review's commit)
**Subject:** Phase 1 hardcoded red crosshair (`Crosshair.qml`)

## Quality Gates

| gate | result |
|---|---|
| `./scripts/package.sh` | PASS |
| `./scripts/check.sh` | PASS (`kpackagetool6` upgrade OK) |

## Constitution Compliance

- [x] No Timer / cursor polling
- [x] No Python / external overlay core
- [x] No Behavior/animation on x/y
- [x] declarativescript + ui/main.qml entry
- [x] Global virtual-desktop geometry (`workspace.workspaceWidth` / `workspace.workspaceHeight`)
- [x] Distro-agnostic scripts (no apt/pacman in project build)

## Spec Compliance (`specs/phase-1-red-line.md`)

- [x] Two `Rectangle`s, `#FF0000`, 1px, opacity 0.8, `z: 9999`
- [x] Direct `workspace.cursorPos` binding
- [x] Pixel centering (`- 0.5`)
- [x] No `KWin.readConfig`
- [x] `main.qml` remains thin entry

## Findings

none (static). Visual lock-to-cursor and multi-monitor bezel span need Max eyes on a live session.

## Verdict

**PASS** — gates green; constitution/spec clean for Phase 1. Ready for Max visual smoke (enable script, move cursor across monitors).
