# qa/ — Grit's territory

> **You are in the QA inspector's booth.** If you're not Grit (Grok in QA mode),
> you should not be writing review reports here. Read — yes. Write — only as Grit.

## Who owns this

**Grit** (`grok --no-auto-update -p` or Grok Build acting as QA). Runs quality
gates, checks `constitution.md`, approves or rejects.

## What goes here

- QA review reports: `review-<short-commit>-YYYYMMDD.md`
- Gate logs worth keeping
- Constitution compliance notes discovered during QA

## What does NOT go here

- Feature code
- Specs (`../specs/`)
- Task tracker (`../TODO.md`)

## Rules for Grit

1. Read `../constitution.md` and `../AGENTS.md` before every review.
2. Every review must run:

   ```bash
   ./scripts/package.sh
   ./scripts/check.sh
   ```

3. Check constitution violations:
   - No `Timer` / polling for cursor
   - No Python / external overlay as core
   - No `Behavior` / animation on position
   - `X-Plasma-MainScript` is `ui/main.qml`
   - Coordinates are global virtual desktop, not single-screen hacks
4. Report format: `review-<shortsha>-YYYYMMDD.md`
5. Approval: `PASS — ready for Max` (or Bones sign-off if structural)
6. Rejection: `FAIL — <issue>, <file>, <fix>`
7. Append verdict to `~/.hermes/agents/chat.md`

## Review template

```markdown
# QA Review — <shortsha>

**Date:** YYYY-MM-DD
**Reviewer:** Grit (Grok)
**Commit:** <hash>
**Subject:** <one line>

## Quality Gates

| gate | result |
|---|---|
| `./scripts/package.sh` | PASS / FAIL |
| `./scripts/check.sh` | PASS / FAIL |

## Constitution Compliance

- [ ] No Timer / cursor polling
- [ ] No Python / external overlay core
- [ ] No Behavior/animation on x/y
- [ ] declarativescript + ui/main.qml entry
- [ ] Global virtual-desktop geometry
- [ ] Distro-agnostic scripts (no apt/pacman in project build)

## Spec Compliance

(link specs/… and checklist)

## Findings

(none | list)

## Verdict

PASS / FAIL — (one sentence)
```
