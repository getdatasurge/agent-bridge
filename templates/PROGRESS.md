# Project — progress log

Append-only ledger of every change to this repo, by any agent or human.
Newest entry on top. Reference is [`PRD.md`](PRD.md) and [`AGENTS.md`](AGENTS.md).

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
belongs in the commit message or PR body. If a change moves a PRD
row, link the row by id (e.g. `P0-7`, `X-3`).

---

<!-- New entries go here, above this line. Newest on top. -->
