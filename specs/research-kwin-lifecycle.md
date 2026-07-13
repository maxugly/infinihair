# Research — KWin script lifecycle & config apply (infinihair)

**Status:** **CLOSED (2026-07-13)**  
**Owner:** Bones (plan) / Max (acceptance) / Grok (notes)  
**Skill:** `skills/KWIN_RESEARCHER.md`

## Problem (as opened)

Configure appeared dead; disable→re-enable unreliable vs peer scripts.

## Resolution (Max)

| check | result |
|---|---|
| Disable → enable in KWin Scripts | **PASS** |
| Color picker + Apply live update | **PASS** |
| Settings persist across re-enable | **PASS** |

Product path accepted at `buildId: 2026-07-13-reen1` after package install + session on current body.

## Useful findings retained

1. **Package path vs temp reload:** `./scripts/reload.sh` loads a unique temp QML path; System Settings enable uses the package path. After upgrades in a long `kwin_wayland` session, a **KWin restart** may be needed once so re-enable uses the new package body.
2. **Peers** share the same KPackage/KCM metadata; multi Configure dialogs are host-side for all scripts.
3. **Instrumentation:** journal `InfiniteCrosshair ready build=` is the body identity; `isScriptLoaded` is load truth; `kwinrc` `[Script-kwin-crosshair]` is disk truth.

## Decision

**A — Fix in-script lifecycle/config (done for accepted path).** No redesign required for re-enable/color.

Multi Configure remains **upstream** (see `bug-multi-config-dialog.md`).

## Decision log

| date | note |
|---|---|
| 2026-07-13 | Freeze opened (Apply dead / re-enable pain). |
| 2026-07-13 | Max: disable/enable + color work. Research closed. Multi-dialog = KDE. |
