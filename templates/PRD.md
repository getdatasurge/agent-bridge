# Project — PRD (canonical, tracked)

This is the **live, agent-maintained** PRD. Source documents (if any)
live elsewhere (e.g. `docs/`) and don't change. **This file is the
source of truth for what is built, what isn't, and what every
requirement points to in code.** Any scope or status change updates
this file in the same commit as the code.

- Companion log: [`PROGRESS.md`](PROGRESS.md) — append-only entry per commit.
- Agent conventions: [`AGENTS.md`](AGENTS.md).

> **Status legend**
> ✅ Done · ⚠️ Partial (scope below) · ❌ Not started · ⛔ Blocked

---

## 1. Problem statement

> What problem does this product solve, for whom, today? One short
> paragraph. Why now? What's the cost of not solving it?

(Fill in.)

## 2. Goals (with evidence)

| # | Goal | Target | Current status |
|---|---|---|---|
| G1 | (e.g. reduce X to Y) | (measurable target) | (current measurement or "not yet measurable") |
| G2 | | | |
| G3 | | | |

## 3. Non-goals (v1)

NG1 · NG2 · NG3. Any addition to v1 scope must include a removal or
explicit timeline extension; otherwise the idea goes to §9 (Parking
lot).

---

## 4. Requirements — P0 (Must-Have)

### P0-1 — (short title) ❌ Not started
- **Acceptance:** (Given/When/Then or checklist)
- **Evidence:** (file:line pointers once built)
- **Gap to close:** (what's missing if Partial)
- **Open:** (any blockers)

### P0-2 — (short title) ❌ Not started
- **Acceptance:**
- **Evidence:**
- **Gap to close:**
- **Open:**

(Add as many P0 rows as your project needs.)

---

## 5. Requirements — P1 (Should-Have)

### P1-1 — (short title) ❌ Not started
- (same shape as P0 rows)

---

## 6. Success metrics (instrumentation status)

| Metric | Target | Instrumentation today |
|---|---|---|
| | | |

---

## 7. Open questions (live)

| # | Question | Owner | Blocking? | Status |
|---|---|---|---|---|
| OQ-1 | | | | Open |

---

## 8. Phasing — progress tracker

| Phase | Scope | Covers | Gate to proceed | Status |
|---|---|---|---|---|
| 1 | | | | ❌ Not started |
| 2 | | | | ❌ Not started |

---

## 9. Parking lot

Good ideas explicitly not in v1. Captured so they don't creep into scope.

- (idea)
- (idea)

---

## 10. Repo-tracked gaps not in original requirements

Things found during code work that the PRD doesn't call out but block
real launch. Treated like requirements going forward.

| ID | Item | Severity | Notes |
|---|---|---|---|
| X-1 | | | |

---

## How to update this PRD

Any agent (Claude, Codex, human) editing the repo:

1. **In the same commit as a code change**, update the matching row(s)
   here — status badge, evidence pointer, or move an entry from a gap
   list to ✅.
2. **Add an entry to [`PROGRESS.md`](PROGRESS.md)** describing the
   change in one or two lines.
3. **New work that doesn't fit any P0/P1/X row** — add it under §10
   (gaps) or §9 (parking lot), don't bury it in code.
4. **Open questions** — when you resolve one, set its status to
   **Resolved** and link the commit/PR in `PROGRESS.md`.

If a code change has no PRD impact (typo, formatting, lint fix),
`PROGRESS.md` still gets a one-line entry but this PRD doesn't need
to move.
