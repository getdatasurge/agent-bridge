# Agent conventions

This repo is worked on by **multiple agents in parallel** — Claude Code,
Codex/Kodex, Cursor, sometimes a human. The same rules apply to all of
you. Read this file **before** doing anything else in the repo.

---

## Primer for a new session (paste this into any new Claude/Codex chat)

```
This repo uses agent-bridge conventions. Multiple agents may be working
in parallel. Before you do anything else:

1. Read /AGENTS.md, /PRD.md, and the most recent ~20 entries of
   /PROGRESS.md.
2. List open PRs (gh pr list / mcp__github__list_pull_requests) — each
   open (draft or not) PR is an active claim on a specific task. Read
   titles and recent commits so you don't pick something already claimed.
3. Pick a task from PRD.md (incomplete requirements, gaps, or open
   questions) whose files/PRD-row aren't claimed by any open PR.
4. Push a WIP commit and open a draft PR within your first few minutes
   — that's your claim. You can hold multiple in-flight claims (one
   per task); the rule is per-task, not per-agent.
5. Every commit updates the matching PRD.md row (status/evidence) AND
   appends one entry to PROGRESS.md, in the same commit as the code.
```

---

## Multi-agent coordination

Treat **open PRs on GitHub** as the source of truth for "who is doing
what right now". `PROGRESS.md` is the historical record.

**Possession is per-TASK, not per-agent.** A single agent can hold
several open draft PRs at once (one per in-flight task). Other agents
see all of them when they list PRs and pick around the claimed work.

### Before you start a task

1. **List open PRs** (`gh pr list --state open` / `mcp__github__list_pull_requests`).
   Read titles, branches, and the last 1–2 commits on each.
2. **Cross-reference against the PRD row(s) you'd touch.** If an open
   PR's diff already changes the same files or claims the same `PRD.md`
   row, pick different work — or post a comment on the existing PR
   offering to help.
3. **Skim `PROGRESS.md`'s last ~20 entries** for context on what shipped
   recently and what almost shipped.

### When you start a task

1. Create a branch with a meaningful slug — e.g. `claude/<task-slug>`,
   `codex/<task-slug>`. Never push to `main`.
2. **Push a WIP commit immediately and open a draft PR.** Title format:
   `[WIP] <PRD id or short title>` — e.g. `[WIP] P0-3 auto-preflight`.
   An empty/early diff is fine; the point is the claim.
3. In the PR body, list:
   - **Touches PRD rows:** P0-3, X-5 (etc.)
   - **Files in flight:** top-level dirs or specific paths if known.
   - **Status:** what's done / what's next.
4. Other agents now see the claim when they `list_pull_requests`.

### While you work

- Update `PRD.md` status (✅/⚠️/❌) and evidence pointers in the same
  commit as the code change. Bias to specificity — `src/foo.ts:142`
  beats "the foo module".
- Append one `PROGRESS.md` entry per commit (top of file, two-sentence cap).
- Keep the PR description's **Status:** field current so other agents
  reading the PR know whether you're 10% or 90% done.

### When you finish (or pause)

- Move the PR out of draft when ready for review.
- If you're pausing mid-task and won't return soon, **add a "PAUSED"
  note to the PR body** with what's left so another agent can pick it
  up cleanly.
- If you abandon work, close the PR (or convert back to draft + comment
  "available — pick up if you want this"). Don't leave silent zombies.

### Conflict / overlap rules

- **First open PR on a given row/file wins the claim.** If you push a
  draft PR and find another agent already has a PR on the same row,
  close yours and either help on theirs (PR comment) or pick adjacent
  work.
- **Multiple in-flight claims from the same agent are fine** — as long
  as each is its own PR on a different row.
- **Never edit another agent's branch** without coordinating in that
  PR's comments first.
- **Merging is human-gated** unless the project says otherwise.

---

## The two files you must keep current

1. **[`PRD.md`](PRD.md)** — canonical tracked PRD with per-requirement
   status, evidence pointers, and open gaps.
2. **[`PROGRESS.md`](PROGRESS.md)** — append-only ledger. **Every commit
   (regardless of agent) appends one entry.**

### When you make a code change

1. Update the matching row(s) in `PRD.md` if status, evidence, or gap
   text moved. Bias to specificity — file paths and short reasons, not
   adjectives.
2. Append one `PROGRESS.md` entry using the template at the top of that
   file. Newest entry on top. Keep it to one or two sentences.
3. Commit both doc updates in the **same commit** as the code change.

### When the change is doc-only (typo, formatting, this file)

Skip `PRD.md`, but still add a `PROGRESS.md` entry. One line is fine.

### When you discover a gap

Don't bury it in a `// TODO` and move on. Add a row to `PRD.md`'s "Gaps"
section and reference it in `PROGRESS.md`. Future agents — including
you in a fresh session — should find it from the PRD.

## Branch + PR rules

- Develop on an agent-prefixed branch (`claude/<slug>`, `codex/<slug>`,
  etc.). Never push directly to `main`.
- Push with `git push -u origin <branch>`. After pushing, open a **draft
  PR** if one doesn't exist — this is how other agents see your claim.
- Never force-push to `main`. Never skip hooks. Never commit secrets / `.env*`.

## Tests + checks before pushing

Project-specific — fill this in once for your repo. Examples:
- `npm run lint && npm run typecheck && npm test`
- `pytest && ruff check`
- `cargo test`

CI should run the same checks on every PR.
