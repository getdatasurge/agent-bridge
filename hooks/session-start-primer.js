#!/usr/bin/env node
// SessionStart hook for Claude Code.
//
// Fires on every session start (terminal, web, desktop, IDE) and injects
// the agent-bridge multi-agent coordination primer into Claude's context
// so it reads PRD.md + PROGRESS.md (and checks open PRs) before doing
// anything in any repo it enters.
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
      "agent-bridge primer: this repo may be worked on by other agents (Claude sessions, Codex/Kodex) in parallel. Before doing anything else:",
      "",
      "1. Check the repo root for PRD.md and PROGRESS.md.",
      "2. If they exist: read them, plus list open PRs (gh pr list / mcp__github__list_pull_requests) to see what other agents are working on. Pick work whose files/PRD-row don't overlap any open PR.",
      "3. If they DON'T exist AND this looks like a code project (has package.json / pyproject.toml / Cargo.toml / go.mod / Gemfile / pom.xml / etc.): create them BEFORE any other change. Use the agent-bridge templates if available, or create generic versions: PRD.md = status-tracked requirements with evidence pointers into the code (file:line); PROGRESS.md = append-only ledger, newest entry on top, one per commit (date, agent, branch, PRD touchpoints, 1-2 sentence summary, top files touched).",
      "4. Whenever you make ANY change in a tracked project: update the matching PRD.md row (status/evidence) AND append a PROGRESS.md entry, in the same commit as the code. Push a WIP commit + open a draft PR within minutes of starting work so other agents see the claim.",
      "5. Possession is per-TASK, not per-agent. You can hold multiple in-flight draft PRs at once — one per task. The rule \"first open PR on a given file/row wins\" prevents collisions; multiple unrelated PRs from one agent is fine.",
      "6. If this is clearly not a code project (docs scratch dir, notes, /tmp, etc.), proceed normally without the tracking files.",
      "",
      "Skipping steps 1-2 risks two agents working on the same task. Don't skip."
    ].join("\n")
  }
}));
