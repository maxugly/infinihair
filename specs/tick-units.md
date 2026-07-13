# Feature: Ruler tick units (Imperial / Metric)

**Status:** Implemented  
**buildId:** `2026-07-13-units1`

## Goal

Toggle tick spacing between **inches** and **centimeters**. Physical screen diagonal is stored **separately** per system so switching units never reuses the other field’s number (27 in ≠ 27 cm).

## UI limitation (genericscripted KCM)

The Configure form is static Qt Designer XML. It **cannot** hide/show widgets when the Units combo changes without a custom KCM.

**Approach:** both diagonal fields are always visible:

- **Diagonal (inches)** → `ScreenDiagonalInches` (default 27)
- **Diagonal (cm)** → `ScreenDiagonalCm` (default 68.6)

Only the field matching **Units** is used for tick math. A note in the form explains this.

## Config keys

| key | type | default | meaning |
|---|---|---|---|
| `TickUnits` | Int | 0 | 0 = Imperial, 1 = Metric |
| `ScreenDiagonalInches` | Double | 27.0 | active when imperial |
| `ScreenDiagonalCm` | Double | 68.6 | active when metric |
| `ShowInchTicks` | Bool | true | show ticks (label: unit ticks) |
| `ShowHalfInchTicks` | Bool | true | half-unit minor ticks |

## Runtime

```
pixelsPerUnit = diagPx / (metric ? ScreenDiagonalCm : ScreenDiagonalInches)
tickStepPx    = showHalf ? pixelsPerUnit * 0.5 : pixelsPerUnit
// major every 1 in or 1 cm
```

No conversion when units change — each diagonal key keeps its own last value.