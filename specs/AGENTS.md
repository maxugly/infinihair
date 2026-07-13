# specs/ — Bones' territory

> **You are in the Architect's workshop.** If you're not Bones (`agy`), you
> should not be writing files here. Read — yes. Learn — absolutely.
> Write — only if Bones (or Max) asked you to.

## Who owns this

**Bones** (Gemini via `agy -p`). Architects before implementing. Plans before
code. Specs before PRs.

## What goes here

- Architectural decision records
- Phase / feature specifications
- Design documents that explain *what* to build and *why*
- Anything Grok must follow before writing QML or config

## What does NOT go here

- Product code (`contents/`, `scripts/` implementation)
- QA reports (`../qa/`)
- Task checkboxes only (`../TODO.md` — link specs from there)

## Rules for Bones

1. Read `../constitution.md`, `../AGENTS.md`, and `../TODO.md` before writing.
2. One spec per feature/phase. Name it `<feature>.md` or `phase-N-<name>.md`.
3. Keep specs actionable — Grok needs to implement without guessing.
4. Update `../TODO.md` after writing a spec.
5. Append to `~/.hermes/agents/chat.md` when a spec is ready for Grok.
6. **Always work in** `~/.local/share/kwin/scripts/crosshair` (repo root). Do not
   leave the only copy of changes in Antigravity scratch without syncing.

## Rules for everyone else

Read-only. Architectural ideas go in the chat file, tagged **bones**. Do not
create or edit files here without Bones' or Max's direction.
