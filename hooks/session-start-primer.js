#!/usr/bin/env node
// SessionStart hook for Claude Code.
//
// Fires on every session start (terminal, web, desktop, IDE) and injects
// the agent-bridge multi-agent coordination primer into Claude's context
// BEFORE Claude processes the user's first message. Step 1 is a hard
// gate: if PRD.md / PROGRESS.md are missing in a code project, Claude
// alerts the user and offers options before addressing their request.
//
// Output shape per the Claude Code hooks JSON contract:
//   { hookSpecificOutput: { hookEventName: "SessionStart", additionalContext: "..." } }
//
// Install: copy this file to ~/.claude/hooks/ and register it in
// ~/.claude/settings.json (see settings/settings.json.snippet). The
// install.sh script in the agent-bridge repo does both for you.
process.stdout.write(JSON.stringify({
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: [
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
      "5. Every change updates the matching PRD.md row (status/evidence) AND appends a PROGRESS.md entry — in the same commit as the code. Push a WIP commit + open a draft PR within minutes of starting work so other agents see the claim.",
      "",
      "6. Possession is per-TASK, not per-agent. You can hold multiple in-flight draft PRs at once — one per task. \"First open PR on a given file/row wins\" prevents collisions; multiple unrelated PRs from one agent is fine.",
      "",
      "Skipping the gate risks two agents working on the same task and losing the historical record. Don't skip."
    ].join("\n")
  }
}));
