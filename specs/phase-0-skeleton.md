# Spec: Phase 0 — KPackage Skeleton

**Status:** PASS (2026-07-13)  
**Owner:** Bones (Architect)  
**Implementer notes:** structure only; no crosshair rendering

## Goal

KWin must recognize and install the package as a declarative script with valid
metadata and required paths.

## Requirements

1. `KPackageStructure: KWin/Script`
2. `X-Plasma-API: declarativescript`
3. `X-Plasma-MainScript: ui/main.qml` (Plasma 6 install validity — not `Crosshair.qml` alone)
4. `KPlugin.Id: kwin-crosshair`, SemVer version
5. Required paths: `contents/code/main.js`, `contents/ui/main.qml`, `contents/ui/Crosshair.qml`
6. Exit: `./scripts/package.sh` and `./scripts/check.sh` exit 0

## Non-goals

- Cursor tracking / red lines (Phase 1)
- Config UI completeness (Phase 2)
- `KWin.readConfig` (Phase 3)

## Verification commands

```bash
./scripts/package.sh
./scripts/check.sh
```
