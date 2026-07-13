# BUG-03 — Restore color picker without breaking persistence

**Status:** Open (design required)  
**Priority:** P1  
**Author note:** Draft for Bones. **Do not implement until design approved.**

## Symptom

Configure UI no longer has a **color picker** (`KColorButton`). Users only get three integer spinboxes (R / G / B).

## Why spinboxes exist (do not discard lightly)

Commit `e61efa5` ("Persist crosshair color across disable/re-enable via RGB ints"):

- KConfig `type=Color` + `KColorButton` under genericscripted KCM:
  - Configure UI often showed **default red** regardless of saved value
  - Apply could **delete** `LineColor` from `kwinrc`
- **LineColorR / LineColorG / LineColorB** as `Int` spinboxes **persist reliably**
- Runtime always rebuilds QML color via `Qt.rgba` from those channels (avoids black-stuck after re-enable)

## Current storage (authoritative)

```
[Script-kwin-crosshair]
LineColorR=...
LineColorG=...
LineColorB=...
```

Legacy single key `LineColor` (`#RRGGBB` or `R,G,B`) still migrated by the disk poller when RGB keys are empty.

## Requirements

1. User **MUST** be able to pick a color with a visual picker (or equivalent UX, not only three bare numbers).
2. Color **MUST** survive: Apply → disable script → enable script → session path that previously broke Color type.
3. Live apply (disk poll path) **MUST** still update the overlay without full KWin restart when possible.
4. **MUST NOT** regress black/stuck color after re-enable.
5. Prefer keeping RGB ints as on-disk source of truth unless design proves Color type safe.

## Design options (Bones chooses)

| option | idea | risk |
|---|---|---|
| A | Restore `KColorButton` + `type=Color` only | High — reintroduces known KCM bugs |
| B | Keep R/G/B ints; add non-kcfg picker (needs custom logic KCM cannot run) | Blocked in pure genericscripted |
| C | Dual-write: KCM Color key + migrate/write RGB ints always; QML reads RGB only | Medium — test load path of Color widget |
| D | Custom/Kirigami config UI outside genericscripted | Large scope |
| E | Spinboxes + live swatch preview only (no picker dialog) | Low risk, weaker UX |

## Work for Bones

1. Pick option (or hybrid) with persistence test matrix.
2. Specify exact `main.xml` keys + `config.ui` widgets + QML read path.
3. Hand Grok a checklist; Grit tests disable/re-enable matrix.

## Exit criteria

- [ ] Design chosen and recorded here
- [ ] Implement + package/check
- [ ] Max: set non-red color, Apply, disable, enable — color remains; picker usable
- [ ] Grit review PASS
