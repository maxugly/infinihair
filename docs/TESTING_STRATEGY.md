# Testing Strategy: KWin Infinite Crosshair

**Owner:** The Sentinel (`skills/SENTINEL.md`)  
**Status:** Active

## Goal

Ensure the script **loads** without crashing KWin and that every change remains **installable**, **syntax-valid**, and **packageable**.

KWin scripts run inside the **compositor**. You cannot treat them like a normal CLI binary under test. For declarative (QML) scripts, “unit tests” are primarily:

1. **Static analysis** (JSON / XML / QML / shell syntax)
2. **Integration checks** (does `kpackagetool6` install the package and list it?)

## Method

| Layer | What we verify | How |
|-------|----------------|-----|
| **Package (required)** | metadata, layout, `.kwinscript` | `./scripts/package.sh` (**python3 only**, any distro) |
| **Check (preferred)** | package + optional shellcheck / kpackagetool6 | `./scripts/check.sh` (tools on `PATH`) |
| **Install** | KPackage accepted by Plasma | `kpackagetool6` when installed via *your* package manager |
| **CI gate** | Same scripts on every push/PR | `.github/workflows/ci.yml` (runner may bootstrap tools; project scripts never call apt/pacman/dnf) |

### Exit criteria automation

CI automates the structural exit criteria from `PHASED_IMPLEMENTATION.md` (install succeeds, package builds). Visual/performance exit criteria remain local (see below).

## Limitation

**Visual correctness** (color, thickness, cursor lock, multi-monitor spanning, z-order over fullscreen apps) is verified by **The Artisan** on a real Plasma session (X11 and Wayland), **not** in CI.

Full visual regression would require a nested Wayland session and screenshot tooling; that is out of scope for the current gate. Future-proofing may use `xvfb-run` only if interaction tests become necessary—still not a substitute for compositor-native checks.

## Distro policy

* **Build = distro-agnostic.** Packaging and structural checks require `python3` on `PATH`. No `apt` / `pacman` / `dnf` in project scripts.
* **Optional tools** (`kpackagetool6`, `shellcheck`) are whatever your distro provides (CachyOS/Arch, Fedora, etc.). Install them yourself; scripts only probe `PATH`.
* **CI runners** may use a host package manager solely to put tools on the image. That is not the project build interface.

## Local vs CI

| Check | CI (Sentinel) | Local (Artisan / developer) |
|-------|---------------|-----------------------------|
| `./scripts/package.sh` | Yes (required) | Yes (required) |
| `./scripts/check.sh` | Yes | Yes |
| `kpackagetool6` install | When available on runner | When on `PATH` |
| Cursor lag / “locked” feel | No | Yes |
| Multi-monitor geometry | No | Yes |
| Fullscreen z-order | No | Yes |

## Failure policy

* If `kpackagetool6` returns non-zero, the build **MUST** fail.
* If lint fails, the build **MUST** fail.
* “I tested it locally” alone is **not** sufficient for merge.

## Related docs

* `skills/SENTINEL.md` — agent role and SOPs
* `PHASED_IMPLEMENTATION.md` — phase exit criteria
* `constitution.md` — prohibited patterns (e.g. timer polling)
