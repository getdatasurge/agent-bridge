#!/usr/bin/env node
// SessionStart hook for Claude Code.
//
// Fires on every session start (terminal, web, desktop, IDE) and injects
// the agent-bridge multi-agent coordination primer into Claude's context
// BEFORE Claude processes the user's first message. Step 1 is a hard
// gate: if PRD.md / PROGRESS.md are missing in a code project, Claude
// alerts the user and offers options before addressing their request.
//
// Also: best-effort tells the user when this primer's local clone is
// behind upstream, so toolkit updates don't go unnoticed. Cheap, no
// network — only checks the local tracking ref.
//
// Output shape per the Claude Code hooks JSON contract:
//   { hookSpecificOutput: { hookEventName: "SessionStart", additionalContext: "..." } }
//
// Install: install.sh symlinks this file to ~/.claude/hooks/ and
// registers it in ~/.claude/settings.json. `git pull` in the cloned
// agent-bridge repo (or ./update.sh) updates what runs next session.

function upstreamLagNote() {
  // Returns a one-line "N commits behind upstream" string, or null if
  // we can't tell or there's no lag. Must never throw — the hook must
  // always produce valid JSON for Claude Code's contract.
  try {
    const { execFileSync } = require("node:child_process");
    const path = require("node:path");
    const fs = require("node:fs");
    const realScript = fs.realpathSync(__filename);
    const repoDir = path.dirname(path.dirname(realScript));
    const opts = { cwd: repoDir, encoding: "utf8", stdio: ["ignore", "pipe", "ignore"], timeout: 1000 };
    const head = execFileSync("git", ["rev-parse", "HEAD"], opts).trim();
    const upstream = execFileSync("git", ["rev-parse", "@{u}"], opts).trim();
    if (!head || !upstream || head === upstream) return null;
    const count = parseInt(execFileSync("git", ["rev-list", "--count", `${head}..${upstream}`], opts).trim(), 10);
    if (!count) return null;
    return `[agent-bridge update available: this clone (${repoDir}) is ${count} commit${count === 1 ? "" : "s"} behind upstream. Run \`cd ${repoDir} && ./update.sh\` to pull + validate.]`;
  } catch {
    return null;
  }
}

const lag = upstreamLagNote();
const lagPrefix = lag ? lag + "\n\n" : "";

process.stdout.write(JSON.stringify({
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: lagPrefix + [
      "agent-bridge primer: this repo may be worked on by other agents (Claude sessions, Codex/Kodex) in parallel. Run this gate BEFORE addressing the user's first message:",
      "",
      "1. Check the repo root for PRD.md AND PROGRESS.md.",
      "",
      "2. If BOTH exist: read them, plus list open PRs (gh pr list / mcp__github__list_pull_requests) to see what other agents are working on. Pick work whose files/PRD-row don't overlap any open PR. Then handle the user's request normally.",
      "",
      "3. If EITHER is missing AND this looks like a code project (presence of any of: package.json, pyproject.toml, Cargo.toml, go.mod, Gemfile, pom.xml, build.gradle, *.csproj, composer.json, mix.exs, etc.): STOP. Do NOT silently create the files and do NOT start on the user's request yet. Your VERY FIRST reply must be this alert, asking which option they want:",
      "",
      "   > This repo doesn't have PRD.md and PROGRESS.md at the root yet. The agent-bridge convention requires them so multiple AI agents (and humans) can coordinate via git instead of stepping on each other.",
      "   >",
      "   > Because this is an existing project, building an honest initial PRD means surveying the codebase to infer current requirements, ship status, and evidence pointers (file:line). For a non-trivial repo that can take 5–30+ minutes before I can start on what you actually asked about.",
      "   >",
      "   > How would you like to proceed?",
      "   >   (a) Do the full survey now, create PRD.md + PROGRESS.md with real content, then continue with your request.",
      "   >   (b) Create minimal stub files now (under a minute) and let them evolve as I work on your request.",
      "   >   (c) Skip tracking for this repo this session — proceed straight to your request, no files created.",
      "",
      "   Wait for the user's choice. Do NOT pick one yourself. Do NOT start on the original request until they answer.",
      "",
      "4. If this is clearly NOT a code project (docs scratch dir, notes, /tmp, standalone shell session, no manifest files), skip the gate and proceed normally.",
      "",
      "Once PRD.md and PROGRESS.md exist, the rest of the protocol applies:",
      "",
      "5. **Branch first; never commit to main.** Before any code change, run `git checkout -b <agent>/<task-slug>` (e.g. `claude/auth-cleanup`). Push a WIP commit + open a draft PR within minutes — that's how parallel sessions see your claim and avoid the same task.",
      "",
      "6. **Every commit updates PRD.md AND PROGRESS.md** in the same commit as the code. Status badge, evidence pointer (file:line), one PROGRESS entry on top. No exceptions.",
      "",
      "7. **Finish by merging your branch into main, resolving all conflicts in the merge commit.** Parallel sessions touching shared files (especially PROGRESS.md) WILL conflict at merge time — that's expected. Keep ALL PROGRESS.md entries from both sides (newest-on-top by date) and reconcile other shared docs carefully. Never push --force to main. A `.gitattributes` rule auto-unions PROGRESS.md so the common case resolves itself; re-sort if needed.",
      "",
      "8. **Possession is per-TASK, not per-agent.** One open draft PR per task; multiple in-flight from the same agent is fine. \"First open PR on a given file/row wins\" — if you see another agent's open PR touching your intended files, pick adjacent work.",
      "",
      "Skipping the gate or committing directly to main risks two agents on the same task, push races, and a lost historical record. Don't skip."
    ].join("\n")
  }
}));
