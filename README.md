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

## Install paths (pick the one matching your setup)

agent-bridge runs in three places. They compose — you can use one,
two, or all three.

### A. Local workstation — `install.sh` (one-time per machine)

Adds a SessionStart hook to your user-level Claude Code settings so
every new session in any repo auto-runs the primer.

```bash
git clone https://github.com/getdatasurge/agent-bridge ~/agent-bridge
cd ~/agent-bridge
./install.sh
```

What `install.sh` does:
1. **Symlinks** `hooks/session-start-primer.js` to `~/.claude/hooks/` so
   `git pull` in this clone propagates to Claude Code instantly — no
   re-install needed.
2. Merges the SessionStart hook entry into `~/.claude/settings.json`
   (backing up the original to `~/.claude/settings.json.bak.<timestamp>`).

**Run on each device** where you use Claude Code — user-level
settings.json is per-machine.

### B. Claude Code on the Web — `cloud-setup.sh` (one-time per environment)

Each Claude Code on the Web container boots fresh, so per-machine
installs don't persist. Configure `cloud-setup.sh` as your environment's
**setup script** in the Claude Code web UI. Every container then boots
with the latest agent-bridge from GitHub already installed — no manual
update step, ever.

Paste this one-liner into the environment setup script field:

```bash
curl -fsSL https://raw.githubusercontent.com/getdatasurge/agent-bridge/main/cloud-setup.sh | bash
```

What it does on each container boot:
1. Clones (or pulls) agent-bridge into `~/agent-bridge` from
   `https://github.com/getdatasurge/agent-bridge` on `main`.
2. Runs `./install.sh` to register the user-level hook.

Every new cloud session = fresh container = latest GitHub state. The
"updates to GitHub propagate to every console" guarantee falls out of
this naturally.

Override the source with env vars if you maintain a fork:
`AGENT_BRIDGE_REPO`, `AGENT_BRIDGE_DIR`, `AGENT_BRIDGE_BRANCH`.

### C. Per-repo committed hook — automatic via `init-project.sh`

When you run `./init-project.sh <project-dir>` (see next section), it
ALSO drops `.claude/hooks/session-start.sh` + `.claude/settings.json`
into the project root. These commit to git. The result: every Claude
Code session on that project — cloud OR local, with or without (A) /
(B) installed — fires the primer because the hook lives in the repo
itself.

The dropped hook is self-contained (the primer JSON is snapshotted
into the script at init time), so it doesn't depend on agent-bridge
being cloned next to it. Refresh against newer primer versions by
re-running `init-project.sh` or `update-project.sh`.

---

## Update — pulling in upstream changes

The primer itself prints a one-line "N commits behind upstream" note in
Claude's SessionStart context when this clone is behind, so updates
don't go unnoticed.

```bash
cd ~/agent-bridge
./update.sh
```

What `update.sh` does:
1. `git fetch` + `git pull --ff-only` so your clone is current.
2. Re-validates the primer still produces valid JSON (catches breakage
   before the next Claude session sees it).
3. Confirms the `~/.claude/hooks/session-start-primer.js` symlink still
   points at this clone and the hook is registered in `settings.json`.

Because step 1 of `install.sh` symlinks rather than copies, plain
`git pull` in this directory is also enough — `update.sh` is the
"safe + validated" version.

**Codex / paste-in primers** can't auto-update. The canonical URL is
stamped at the top of `prompts/codex-primer.txt`:

```
https://raw.githubusercontent.com/getdatasurge/agent-bridge/main/prompts/codex-primer.txt
```

Re-paste from that URL when starting a new Codex session if you want
the freshest version.

---

## Init — per project (one-time, for each repo you want tracked)

In any project you want to add coordination to:

```bash
./init-project.sh /path/to/your/project
```

This drops six files into the project:
- `AGENTS.md` — the conventions (any agent reads this first)
- `CLAUDE.md` — one-line `@AGENTS.md` import (Claude reads this; Codex
  reads AGENTS.md directly)
- `PRD.md` — template with sections for goals, requirements, status,
  gaps, open questions
- `PROGRESS.md` — empty ledger with the entry template at the top
- `.claude/hooks/session-start.sh` — self-contained SessionStart hook
  that fires the primer for every Claude Code session on this project
  (cloud or local), even without per-machine setup
- `.claude/settings.json` — registers the hook (merged with any
  existing settings.json if jq is available)

Then edit `PRD.md` once to capture your actual requirements + initial
status. Subsequent agent sessions maintain it.

### Refreshing a project against newer templates

When the templates in this repo evolve (new sections, better wording),
you can see the diff against an existing init'd project:

```bash
./update-project.sh /path/to/your/project
```

This shows a unified diff per file. Nothing is auto-written — you decide
which hunks to apply. `AGENTS.md` and `CLAUDE.md` are agent-owned and
usually safe to refresh; `PRD.md` and `PROGRESS.md` are project-owned
state and the template diff only shows shape, not content.

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

## Parallel-session workflow (the discipline)

The protocol assumes every agent session does this:

1. **Branch first** — `git checkout -b <agent>/<task-slug>`. Never
   commit to `main` directly. The primer + `AGENTS.md` reinforce this.
2. **Push a WIP commit + open a draft PR within minutes.** That's how
   other parallel sessions see your claim and pick around it.
3. **Every commit updates `PRD.md` row + appends a `PROGRESS.md`
   entry** in the same commit as the code.
4. **Merge to `main` at the end with conflicts resolved in the merge
   commit.** Shared files (especially `PROGRESS.md`) will conflict —
   that's expected. `PROGRESS.md` has a `.gitattributes` union-merge
   rule that auto-resolves the common case (both sides' lines kept).
   Re-sort by date afterward if the ordering matters to you.

If sessions skip step 1 (commit directly to `main`) or skip step 2
(no draft PR), the system can't coordinate — that's where painful
conflicts come from.

## Known limits

This toolkit gives you **eventual sync** (agents see each other when they
next list PRs) and **soft locks** (convention + git merge resolution).
Three failure modes to watch:

1. **An agent skips the "list PRs first" step.** The primer + AGENTS.md
   tell it to; you'll want to spot-check the first few sessions.
2. **`PROGRESS.md` ordering after auto-union merge.** Union merge keeps
   all entries but may scramble the "newest on top" property when two
   branches both prepended. Easy manual re-sort. If the ordering keeps
   biting, switch to per-entry files (P1-3 in `PRD.md`:
   `progress/YYYY-MM-DD-agent-slug.md`) instead of one shared file.
3. **PR drift** — draft PR sits stale and locks the queue. Suggested
   rule: anything draft >48h gets closed by you or converted to comment.

If you're running ≥5 agents concurrently or you can't be the one
eyeballing the PR list daily, upgrade the coordination layer to BridgeMind
or another orchestrator. They compose with this toolkit — they read/write
the same files.

---

## License

MIT (or whatever you prefer — add a `LICENSE` file).
