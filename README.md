# agent-bridge

Lightweight coordination toolkit for running **multiple AI coding agents
(Claude Code, Codex, Cursor, etc.) on the same repo in parallel** without
them stepping on each other's work.

Two artifacts per project:
- **`PRD.md`** — status-tracked requirements with evidence pointers into the
  code. The menu of what's available to work on.
- **`PROGRESS.md`** — append-only ledger. Every commit by any agent adds one
  entry. The historical record of who did what.

One artifact per machine:
- A **SessionStart hook** in `~/.claude/settings.json` that primes every new
  Claude Code session (terminal, web, desktop, IDE) to read those files and
  check open PRs before doing anything.

One paste-in prompt:
- **`prompts/codex-primer.txt`** — the equivalent for Codex chat sessions
  (Codex doesn't have hooks; you paste it as the first message).

> **Inspired by** the productized version at [BridgeMind / BridgeSwarm](https://www.bridgemind.ai/bridgeswarm).
> This is the DIY-with-git-and-plain-text version: lower fidelity (eventual
> sync via `gh pr list`, soft locks via "first draft PR wins"), but zero
> vendor lock-in and free to run.

---

## How it works

The coordination loop, in one paragraph:

> Every agent that enters the repo reads `PRD.md` + `PROGRESS.md` + the
> open PR list. It picks a task whose files/PRD-row aren't already claimed
> by an open PR. It pushes a WIP commit + opens a draft PR within minutes
> — that's its "claim". Every subsequent commit updates the matching
> `PRD.md` row AND appends one `PROGRESS.md` entry. **Multiple in-flight
> claims per agent are fine** — the rule is per-task, not per-agent.
> Conflicts are resolved by "first open PR on a given row wins".

**Gate behavior for existing repos.** When an agent enters a code project
that doesn't yet have `PRD.md` / `PROGRESS.md`, the SessionStart hook (or
the Codex paste-in primer) **stops the agent before it addresses the
user's first request** and alerts the user: building an honest initial
PRD on a non-trivial existing codebase can take 5–30+ minutes of survey
work. The user picks (a) full survey + real PRD, (b) minimal stubs that
evolve, or (c) skip tracking this session. No silent file creation.

What this gets you:
- Two Claude sessions and one Codex session running simultaneously, none
  picking the same task because they all see each other's draft PRs.
- A persistent record (in git) of every change, by which agent, with which
  PRD touchpoints — no proprietary cloud state to lose.
- Works with any AI tool that can read text and use git. No SDK, no MCP
  server, no subscription.

---

## Install — per machine (one-time, for Claude Code)

This adds a SessionStart hook to your user-level Claude Code settings so
every new session in any repo auto-runs the primer.

```bash
git clone <this-repo-url> ~/agent-bridge
cd ~/agent-bridge
./install.sh
```

What `install.sh` does:
1. Copies `hooks/session-start-primer.js` to `~/.claude/hooks/`.
2. Merges the SessionStart hook entry into `~/.claude/settings.json`
   (backing up the original to `~/.claude/settings.json.bak`).

After install, open `/hooks` once in any Claude Code session (any project)
to reload config, or restart Claude Code. From then on, every new session
fires the primer.

**Run on each device** where you use Claude Code in a terminal/CLI/web/IDE
— user-level settings.json is per-machine (Claude Code doesn't sync it).

---

## Init — per project (one-time, for each repo you want tracked)

In any project you want to add coordination to:

```bash
./init-project.sh /path/to/your/project
```

This drops four files at the project root:
- `AGENTS.md` — the conventions (any agent reads this first)
- `CLAUDE.md` — one-line `@AGENTS.md` import (Claude reads this; Codex
  reads AGENTS.md directly)
- `PRD.md` — template with sections for goals, requirements, status,
  gaps, open questions
- `PROGRESS.md` — empty ledger with the entry template at the top

Then edit `PRD.md` once to capture your actual requirements + initial
status. Subsequent agent sessions maintain it.

---

## Use with Codex

Codex doesn't support hooks, so the primer is paste-in. Open
`prompts/codex-primer.txt`, copy the entire contents, paste as the first
message in a new Codex chat. Codex will then follow the same protocol
Claude does.

---

## Use with Cursor / Cline / other agents

Most coding agents read `AGENTS.md` (or accept a system prompt) on entry.
Either:
- Point the agent at the template `AGENTS.md` shipped here, or
- Paste `prompts/codex-primer.txt` as the system/initial prompt (works
  for most agents — the wording is tool-agnostic).

---

## Uninstall

Per-machine:
```bash
rm ~/.claude/hooks/session-start-primer.js
# Restore the pre-install settings.json if needed:
mv ~/.claude/settings.json.bak ~/.claude/settings.json
```
Or run `/hooks` in Claude Code and disable the entry from the UI.

Per-project:
```bash
rm AGENTS.md CLAUDE.md PRD.md PROGRESS.md
```
The git history still reflects past agent activity — uninstalling only
turns off the convention going forward.

---

## Customization

- **Want different files**? Edit the templates in `templates/`. The next
  `./init-project.sh` run picks up the changes.
- **Want different primer wording**? Edit `hooks/session-start-primer.js`
  (the script outputs JSON to stdout — see the comments inside).
- **Want enforcement instead of convention**? See the "limits" section
  below — for hard file locks and real-time sync, you eventually want
  [BridgeMind / BridgeSwarm](https://www.bridgemind.ai/bridgeswarm) on
  top. The two compose.

---

## Known limits (and when to upgrade)

This toolkit gives you **eventual sync** (agents see each other when they
next list PRs) and **soft locks** (convention + git merge resolution).
Three failure modes to watch:

1. **An agent skips the "list PRs first" step.** The primer + AGENTS.md
   tell it to; you'll want to spot-check the first few sessions.
2. **`PROGRESS.md` merge conflicts** when two agents append simultaneously.
   Trivially resolvable; if it bites often, switch to per-entry files
   (`progress/YYYY-MM-DD-agent-slug.md`) instead of one shared file.
3. **PR drift** — draft PR sits stale and locks the queue. Suggested
   rule: anything draft >48h gets closed by you or converted to comment.

If you're running ≥5 agents concurrently or you can't be the one
eyeballing the PR list daily, upgrade the coordination layer to BridgeMind
or another orchestrator. They compose with this toolkit — they read/write
the same files.

---

## License

MIT (or whatever you prefer — add a `LICENSE` file).
