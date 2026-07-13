# Project Todo List — infinihair

> **Bones** writes and prioritizes. **Grok** marks `[x]` when done.  
> Specs live in `specs/`.  
> **Live snapshot:** [STATUS.md](STATUS.md)

## Mode: RESEARCH FREEZE (2026-07-13)

**No product feature coding** until `specs/research-kwin-lifecycle.md` has a Bones decision (A/B/C).

| track | status |
|---|---|
| Phase 0–1 skeleton / red line | historically PASS |
| Config UI + live poll + overlay | **in tree** but **not accepted by Max** |
| Color picker UI | restored (reen1) — **Apply appears dead to Max** |
| Disable/re-enable vs peers | **research open** |
| Multi Configure dialogs | wontfix-package (KCM host) |

---

## Active — KWin lifecycle research

Spec: [specs/research-kwin-lifecycle.md](specs/research-kwin-lifecycle.md)  
Skill: [skills/KWIN_RESEARCHER.md](skills/KWIN_RESEARCHER.md)

- [ ] **Bones:** refine research questions / order experiments; append chat handoff
- [ ] **Max:** E1–E4 checklist in STATUS / research spec (isScriptLoaded, kwinrc, journal, peer compare)
- [ ] **Grok:** only if Bones tasks instrumentation or minimal repro (no drive-by QML)
- [ ] **Grit:** QA any research instrumentation; later QA the real fix PR
- [ ] **Bones:** write decision A/B/C + Grok task list; unfreeze

---

## Parked bugs (do not implement until unfreeze)

| id | issue | note |
|---|---|---|
| BUG-01b | Settings disable→re-enable | subsumed by research |
| BUG-02 | Multi Configure dialogs | wontfix-package |
| BUG-03 | Color picker / Apply | picker back; **behavior dead** per Max — research |
| debt | main.qml ≡ Crosshair.qml | after lifecycle decision |

---

## Phase tracker (historical / not current focus)

| phase | status |
|---|---|
| 0 Skeleton | PASS |
| 1 Red line | PASS then heavily extended |
| 2–3 Config + bind | code present; **not product-accepted** |
| 4 Edge cases | blocked on research |
| 5 Packaging | package/check/reload exist |

---

## Packaging (ok to run during freeze)

- [x] `scripts/package.sh` / `check.sh` / `reload.sh`
- [ ] README polish → maxugly/infinihair (after research)

---

## Process

- [x] Multi-agent crew (`AGENTS.md`)
- [x] STATUS + research spec + KWIN_RESEARCHER skill
- [ ] Commit + push freeze docs + reen1 tree (this cycle)
