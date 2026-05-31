# agent-bridge — progress log

Append-only ledger of every change to this repo, by any agent or human.
Newest entry on top. Reference: [`PRD.md`](PRD.md) and
[`templates/AGENTS.md`](templates/AGENTS.md).

## Entry format

```
## YYYY-MM-DD — short title
- **agent:** Claude | Codex | Kodex | Cursor | human (name)
- **branch:** branch-name      commit: <short sha or "pending">
- **PRD touchpoints:** P0-3, X-5    (or "—" if doc-only)
- **summary:** one or two sentences. What changed and why, not how.
- **files:** path/one.ts, path/two.md   (top 3–5 only)
```

Keep entries tight: one or two sentences of summary. Long context
belongs in the commit message or PR body.

---

<!-- New entries go here, above this line. Newest on top. -->

## 2026-05-31 — Dogfood: add root-level PRD.md + PROGRESS.md
- **agent:** Claude (Claude Code, claude-opus-4-7)
- **branch:** claude/funny-franklin-vxu5W    commit: pending
- **PRD touchpoints:** P0-6, X-1, X-2, X-3 (gaps captured)
- **summary:** The toolkit now eats its own dog food — `PRD.md` and `PROGRESS.md` live at the repo root with real content reflecting actual shipped state, not blank templates. Future commits must keep both current in the same commit as code.
- **files:** PRD.md, PROGRESS.md

## 2026-05-31 — Initial repo push to GitHub
- **agent:** Claude (Claude Code, claude-opus-4-7)
- **branch:** main and claude/funny-franklin-vxu5W (same commit 9d57544)    commit: 9d57544
- **PRD touchpoints:** P0-1, P0-2, P0-3, P0-4, P0-5 (all shipped at this commit)
- **summary:** Extracted the agent-bridge tarball and pushed the initial commit to `getdatasurge/agent-bridge` on both `main` and the session branch. Contents: install/init scripts, SessionStart hook, templates, Codex primer, README.
- **files:** README.md, install.sh, init-project.sh, hooks/session-start-primer.js, templates/*.md
