# AGENTS.md — infinihair (KWin Infinite Crosshair)

> **Read this before doing anything.** If you're an AI agent working on this
> project and you're about to write code without delegating to the crew, stop.

## The crew

infinihair uses a **multi-agent workflow**. You are never the only cook in this
kitchen.

| role | agent | tool | what they do |
|---|---|---|---|
| **Architect** | Bones | `agy -p` (Antigravity / Gemini) | Specs, task breakdowns, structural decisions. Owns `TODO.md` and `specs/`. |
| **Implementer** | Grok | `grok` / this session (Grok Build) | Reads Bones' plans. Writes QML/JS/config/scripts. Runs package/check. Marks tasks done. Does **not** make architecture solo. |
| **QA** | Grit | `grok --no-auto-update -p` (or Grok Build in QA mode) | Reviews diffs. Runs quality gates. Checks `constitution.md`. Writes `qa/review-*.md`. Approves or rejects. |
| **Operator** | Max | human | Final sign-off. Says "ship it." |

Domain skills (how to think, not who runs the tool):

| skill file | maps to |
|---|---|
| `skills/ARCHITECT.md` | Bones |
| `skills/ARTISAN.md` | Grok (when writing QML) |
| `skills/STRATEGIST.md` | Bones + Grit (requirements / edge cases) |
| `skills/SENTINEL.md` | Grit (CI, package, install gates) |

## The rule

**Do not go rogue.** Grok implements, Bones specs, Grit reviews. If you find
yourself writing code without first checking whether Bones has a plan for it
in `specs/` + `TODO.md`, you're off the rails. If you commit without a QA pass
when the change is non-trivial, you're off the rails.

### Current product state (2026-07-13)

Read **`STATUS.md` first.** Max accepted: disable/re-enable + color picker + live apply.

- Multi Configure dialogs = **upstream KWin KCM** (not our package). See `specs/bug-multi-config-dialog.md`.
- New features still need Bones specs. Do not thrash color storage or Window flags without evidence.
- Lifecycle research notes: `specs/research-kwin-lifecycle.md` (closed with Max PASS).

## The cycle

```
Max says "build X"
  → Bones (agy) writes: specs/X.md + updates TODO.md
    → Grok reads plan, writes code, marks TODO done
      → Grit (grok) QA: package + check + constitution, approves or rejects
        → Bones final structural sign-off if needed
          → Max ships
```

Never skip a step. Never do someone else's job. Grok doesn't architect. Grit
doesn't implement. Bones doesn't QA and **doesn't write product QML** (structure
and metadata only when Phase 0 requires it).

## How to delegate

### Bones (Architect / Agy)

**Always run from the real repo root** (not a random scratch clone):

```bash
cd /home/m/.local/share/kwin/scripts/crosshair

agy -p "Read constitution.md, AGENTS.md, and TODO.md.
You are Bones (Architect). Write or update specs/<feature>.md.
Break work into tasks and update TODO.md.
Append a short handoff to ~/.hermes/agents/chat.md for Grok.
Do not implement Phase 1+ QML rendering." \
  --dangerously-skip-permissions
```

Optional: pin workspace if Antigravity drifts:

```bash
agy -p "..." --add-dir /home/m/.local/share/kwin/scripts/crosshair \
  --dangerously-skip-permissions
```

Bones uses Gemini via Antigravity. He reads the repo, writes markdown (and
Phase-0 structure only when explicitly tasked), doesn't paint the crosshair.

### Grit (QA / Grok)

```bash
cd /home/m/.local/share/kwin/scripts/crosshair

grok --no-auto-update -p "You are Grit (QA). Review the diff since last commit
(or the named range). Check constitution.md compliance (no Timer polling, no
Python overlays, global coords, signal-driven cursor). Run:
  ./scripts/package.sh && ./scripts/check.sh
Write qa/review-<shortsha>-YYYYMMDD.md using the template in qa/AGENTS.md.
Append verdict to ~/.hermes/agents/chat.md." \
  --always-approve
```

Grit runs quality gates. He doesn't write features unless Max asks for a small
fix. For full feature QA, give him the commit range or diff.

### Grok (Implementer)

```
Read TODO.md + the linked specs/<feature>.md + constitution.md.
Implement only the checked-out task list. Run ./scripts/package.sh (and
./scripts/check.sh when kpackagetool6 is available). Mark TODO items done.
Append status to ~/.hermes/agents/chat.md. Hand off to Grit for QA.
```

## Chat file

All inter-agent communication goes through **`~/.hermes/agents/chat.md`**.

- Append-only, timestamped
- Format: `## YYYY-MM-DD HH:MM — name` then message
- No formality, no schema
- Tell the next agent what they need to know (paths, phase, blockers)

Tag by name: **bones**, **grok**, **grit**, **max**.

## Quality gates (non-negotiable)

Before any commit is final:

```bash
./scripts/package.sh
./scripts/check.sh
```

Both must exit 0. Distro-agnostic: scripts never call apt/pacman/dnf; only tools
on `PATH` (`python3` required; `kpackagetool6` / `shellcheck` optional unless
`CHECK_REQUIRE_KPACKAGE=1`).

### Constitution gates (non-negotiable)

- No `Timer` / polling for cursor position
- No Python / external overlay core path
- No `Behavior` / animation on crosshair `x`/`y`
- Declarative KWin script only (`X-Plasma-API: declarativescript`)
- Entry: `X-Plasma-MainScript: ui/main.qml`; render SSoT: `contents/ui/Crosshair.qml`
- Global virtual-desktop coordinates (`workspace.cursorPos`, workspace width/height)

## Project structure

```
crosshair/   # also known as infinihair on GitHub
├── AGENTS.md                 # ← you are here — master crew plan
├── STATUS.md                 # honest "where we are" snapshot (read first)
├── constitution.md           # immutable engineering laws
├── spec.md                   # formal product requirements (may lag code)
├── PHASED_IMPLEMENTATION.md  # phase gates 0–5
├── TODO.md                   # task tracker (Bones writes, Grok marks done)
├── metadata.json             # KPackage identity (Id: kwin-crosshair)
├── contents/
│   ├── ui/                   # Grok/Artisan territory (QML)
│   │   ├── main.qml          # KWin entry (currently full impl — debt)
│   │   ├── Crosshair.qml     # intended render SSoT (currently dupe of main)
│   │   └── config.ui         # Configure form (KCM loads THIS path)
│   ├── code/main.js          # lifecycle stub
│   └── config/               # main.xml schema; main.ui empty legacy stub
├── scripts/                  # package.sh, check.sh, reload.sh (Sentinel/Grit)
├── skills/                   # ARCHITECT, ARTISAN, STRATEGIST, SENTINEL
├── specs/                    # Bones' territory (bugs + phases)
│   └── AGENTS.md
├── qa/                       # Grit's territory
│   └── AGENTS.md
└── docs/                     # patterns, testing strategy
```

## Key paths

| what | where |
|---|---|
| live package / repo | `~/.local/share/kwin/scripts/crosshair/` |
| installed runtime tree | `~/.local/share/kwin/scripts/kwin-crosshair/` (from kpackagetool) |
| GitHub | `https://github.com/maxugly/infinihair` |
| chat file | `~/.hermes/agents/chat.md` |
| status snapshot | `STATUS.md` |
| Architect skill | `skills/ARCHITECT.md` + `agy` |
| QA skill | `skills/SENTINEL.md` + `qa/` |
| Agy (Antigravity) | `/home/m/.local/bin/agy` |

## Open / closed work (see STATUS.md)

| id | summary | status |
|---|---|---|
| disable/re-enable | System Settings toggle | **PASS (Max)** |
| color picker + Apply | `KColorButton` + live poll | **PASS (Max)** |
| BUG-02 | Multi Configure dialogs | **upstream KWin** — wontfix-package |
| debt | `main.qml` ≡ `Crosshair.qml` monolith | backlog |

## Phased ownership

| phase | lead | tool |
|---|---|---|
| 0 Skeleton & validation | Bones | `agy` |
| 1 Red line (hardcoded QML) | Grok (Artisan) | grok |
| 2 Config schema | Bones plans → Grok implements | both |
| 3 Config bind to QML | Grok | grok |
| 4 Edge cases | Grit + Grok | grok |
| 5 Packaging polish | Grok + Grit | grok |

## When you mess up

If you catch yourself working solo — committing without QA, designing without
Bones, implementing Phase N+1 before Phase N passes — stop. Tell Max. Append
to the chat file. Delegate the next step to the right agent. The constitution
forgives; skipped cycles don't.
