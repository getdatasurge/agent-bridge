# agent-bridge — PRD (canonical, tracked)

This is the **live, agent-maintained** PRD for the agent-bridge toolkit
itself. Companion log: [`PROGRESS.md`](PROGRESS.md). Conventions:
[`templates/AGENTS.md`](templates/AGENTS.md) (until the toolkit is
init'd against itself at the root).

> **Status legend**
> ✅ Done · ⚠️ Partial · ❌ Not started · ⛔ Blocked

---

## 1. Problem statement

Multiple AI coding agents (Claude Code sessions, Codex/Kodex, Cursor,
sometimes humans) increasingly work on the same repo in parallel. They
have no built-in way to see each other, so two agents routinely pick
the same task and produce conflicting branches. Existing solutions
(BridgeMind/BridgeSwarm) are productized and good but introduce vendor
state. This toolkit gives the same coordination loop using only plain
text + git + draft PRs — zero lock-in, free, eventual-sync rather than
real-time.

## 2. Goals

| #  | Goal | Target | Current status |
|----|---|---|---|
| G1 | Any new Claude Code session in any repo auto-runs a coordination primer | 100% via `SessionStart` hook | ✅ `hooks/session-start-primer.js` + `install.sh` |
| G2 | Any new repo can be opted-in with one command | Single script drops 4 tracked files | ✅ `init-project.sh` |
| G3 | Agents without hook support (Codex, Cursor) follow the same protocol | Paste-in primer prose | ✅ `prompts/codex-primer.txt` |
| G4 | The toolkit dogfoods its own conventions | This repo has live `PRD.md` + `PROGRESS.md` at root | ⚠️ introduced this commit; needs ongoing upkeep |

## 3. Non-goals (v1)

- Real-time sync between agent sessions (eventual via PR list is good enough).
- Hard file locks. Soft locks via "first draft PR on a row wins" only.
- Auto-merging or auto-conflict-resolution — humans gate merges.
- Per-tool installers beyond Claude Code. Codex/Cursor are paste-in.

---

## 4. Requirements — P0 (Must-Have)

### P0-1 — SessionStart primer for Claude Code ✅ Done
- **Acceptance:** Hook emits valid JSON with `hookSpecificOutput.additionalContext`; Claude reads PRD/PROGRESS/open PRs before acting.
- **Evidence:** `hooks/session-start-primer.js:15-31`.
- **Gap to close:** —
- **Open:** —

### P0-2 — Per-machine install script (Claude Code) ✅ Done
- **Acceptance:** Idempotent merge into `~/.claude/settings.json`; backs up the original; smoke-tests the primer's JSON output before touching settings.
- **Evidence:** `install.sh:36-79`.
- **Gap to close:** —
- **Open:** —

### P0-3 — Per-project init script ✅ Done
- **Acceptance:** Drops `AGENTS.md`, `CLAUDE.md`, `PRD.md`, `PROGRESS.md` into target dir; skips existing files (non-destructive).
- **Evidence:** `init-project.sh:28-37`.
- **Gap to close:** —
- **Open:** —

### P0-4 — Templates (PRD/PROGRESS/AGENTS/CLAUDE) ✅ Done
- **Acceptance:** Templates are filled-in-by-example, not blank; explain the convention inline.
- **Evidence:** `templates/PRD.md`, `templates/PROGRESS.md`, `templates/AGENTS.md`, `templates/CLAUDE.md`.
- **Gap to close:** —
- **Open:** —

### P0-5 — Codex / generic-agent paste-in primer ✅ Done
- **Acceptance:** Tool-agnostic prose primer covering the same 8 rules as the Claude hook.
- **Evidence:** `prompts/codex-primer.txt:1-39`.
- **Gap to close:** —
- **Open:** —

### P0-6 — Toolkit dogfoods its own conventions ⚠️ Partial
- **Acceptance:** This repo has live `PRD.md` + `PROGRESS.md` at root, updated alongside every code change.
- **Evidence:** This file + `PROGRESS.md` (introduced 2026-05-31).
- **Gap to close:** Future commits must update both in the same commit. No CI enforcement yet.
- **Open:** Should there be a pre-commit hook that fails if `PROGRESS.md` wasn't touched? (see OQ-1)

### P0-7 — Pre-prompt gate for missing tracking files ✅ Done
- **Acceptance:** When an agent enters a code project (detected by manifest files) lacking `PRD.md` / `PROGRESS.md`, the SessionStart primer (Claude) and paste-in primer (Codex/Cursor) stop the agent BEFORE it addresses the user's first message, alert the user with the time-cost caveat for existing projects, and offer (a) full survey, (b) minimal stubs, (c) skip-this-session. No silent file creation.
- **Evidence:** `hooks/session-start-primer.js:19-32`, `prompts/codex-primer.txt:7-37`, `templates/AGENTS.md` primer snippet.
- **Gap to close:** —
- **Open:** OQ-4 — the manifest list is heuristic; some projects (Bazel monorepos, raw C, polyglot) won't match. Acceptable tradeoff for now.

---

## 5. Requirements — P1 (Should-Have)

### P1-1 — `LICENSE` file ❌ Not started
- **Acceptance:** Repo has an explicit MIT (or chosen) license file at root.
- **Evidence:** README mentions MIT but no file exists.
- **Gap to close:** Add `LICENSE`.
- **Open:** Confirm MIT vs. Apache-2.0 vs. other.

### P1-2 — CI smoke test for `install.sh` and `init-project.sh` ❌ Not started
- **Acceptance:** GitHub Actions runs both scripts against a scratch dir on every PR; fails if either script errors or produces invalid JSON.
- **Evidence:** —
- **Gap to close:** Add `.github/workflows/smoke.yml`.
- **Open:** —

### P1-3 — Per-entry `PROGRESS/` directory option ❌ Not started
- **Acceptance:** `init-project.sh` accepts a `--mode=per-entry` flag that creates `progress/` with a README instead of a single `PROGRESS.md`. README documents the merge-conflict tradeoff.
- **Evidence:** —
- **Gap to close:** Script flag + template variant.
- **Open:** —

---

## 6. Success metrics (instrumentation status)

| Metric | Target | Instrumentation today |
|---|---|---|
| % of repo's own commits that update both `PRD.md` and `PROGRESS.md` | 100% (excluding pure-doc) | Not instrumented; manual eyeball |
| Time for a new Claude session to "see" another agent's draft PR | <60s after `mcp__github__list_pull_requests` | Not instrumented |
| `install.sh` success rate on fresh machines | >95% (node + jq present) | Not instrumented |

---

## 7. Open questions

| #    | Question | Owner | Blocking? | Status |
|------|---|---|---|---|
| OQ-1 | Should we enforce PRD/PROGRESS updates with a pre-commit hook in the templates, or stay convention-only? | — | No | Open |
| OQ-2 | What's the right "is this a code project?" detector in the SessionStart primer? Currently a list of manifest filenames in the primer prose; could be a real check. | — | No | Open |
| OQ-3 | Should `init-project.sh` also drop a stub `.github/PULL_REQUEST_TEMPLATE.md` enforcing "Touches PRD rows:" / "Status:" fields? | — | No | Open |
| OQ-4 | The "is code project?" detector in the primer is a hard-coded manifest list. Bazel monorepos, raw-C projects, and polyglot repos may fail it. Worth promoting from heuristic to explicit user opt-in/opt-out? | — | No | Open |

---

## 8. Phasing

| Phase | Scope | Covers | Gate to proceed | Status |
|---|---|---|---|---|
| 1 | Toolkit MVP — primer, install, init, templates, Codex prose | P0-1..P0-5 | All shipped to GitHub | ✅ |
| 2 | Self-application + license + CI | P0-6, P1-1, P1-2 | Repo eats its own dog food and a smoke test guards the scripts | ⚠️ in progress |
| 3 | Variants + ecosystem | P1-3 and tool-specific installers (Cursor/Cline) | TBD | ❌ |

---

## 9. Parking lot

- Per-tool optimized primers (Cursor MDC files, Cline `.clinerules`, etc.)
- VS Code extension that surfaces "open PR claims" in the sidebar.
- A `lint-progress` script that diffs the last commit against `PROGRESS.md` and warns when they're out of sync.
- A "PR-drift sweeper" GitHub Action that closes draft PRs idle >48h.

---

## 10. Repo-tracked gaps not in original requirements

| ID  | Item | Severity | Notes |
|-----|---|---|---|
| X-1 | No `LICENSE` file even though README says MIT | low | See P1-1. |
| X-2 | `install.sh` requires `jq` and `node` but README doesn't call this out | low | Already in script's preflight; add to README. |
| X-3 | No GitHub Actions / CI of any kind | low | See P1-2. |

---

## How to update this PRD

Any agent (Claude, Codex, human) editing this repo:

1. **In the same commit as a code change**, update the matching row(s)
   here — status badge, evidence pointer, or move an entry from a gap
   list to ✅.
2. **Add an entry to [`PROGRESS.md`](PROGRESS.md)** in the same commit.
3. **New work that doesn't fit any P0/P1/X row** — add it under §10
   (gaps) or §9 (parking lot).
4. **Resolved open questions** — set status to **Resolved** and link the
   commit/PR in `PROGRESS.md`.

Pure-doc commits (typo, formatting, this file): still append a
`PROGRESS.md` entry; PRD rows don't need to move.
