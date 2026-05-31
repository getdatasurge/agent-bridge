#!/usr/bin/env bash
# agent-bridge — per-machine install for Claude Code.
#
# Drops the SessionStart primer script into ~/.claude/hooks/ and merges
# the hook registration into ~/.claude/settings.json. Idempotent — safe
# to re-run.
#
# Run on each machine where you use Claude Code (user-level settings.json
# is per-device — Claude Code does not sync it across machines).

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${HOME}/.claude"
HOOKS_DIR="${CLAUDE_DIR}/hooks"
SETTINGS="${CLAUDE_DIR}/settings.json"
BACKUP="${SETTINGS}.bak.$(date +%s)"
PRIMER_SRC="${REPO_DIR}/hooks/session-start-primer.js"
PRIMER_DST="${HOOKS_DIR}/session-start-primer.js"

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
warn() { printf '\033[33m%s\033[0m\n' "$*"; }
ok()   { printf '\033[32m%s\033[0m\n' "$*"; }
die()  { printf '\033[31m%s\033[0m\n' "$*" >&2; exit 1; }

# --- Preflight ---------------------------------------------------------------
command -v node >/dev/null 2>&1 || die "node not found on PATH (required by the hook). Install Node.js first."
command -v jq   >/dev/null 2>&1 || die "jq not found on PATH (required for safe settings.json merge). Install jq first."
[[ -f "$PRIMER_SRC" ]] || die "Primer script missing: $PRIMER_SRC"

bold "==> Installing agent-bridge SessionStart hook"
echo "Hook script: $PRIMER_DST"
echo "Settings:    $SETTINGS"
echo

# --- Drop the primer script --------------------------------------------------
mkdir -p "$HOOKS_DIR"
cp "$PRIMER_SRC" "$PRIMER_DST"
chmod +x "$PRIMER_DST"
ok "✓ Primer script installed at $PRIMER_DST"

# Smoke-test the script: must output valid JSON with hookSpecificOutput.
if ! node "$PRIMER_DST" | jq -e '.hookSpecificOutput.additionalContext' >/dev/null; then
  die "Primer script did not produce valid JSON. Aborting before touching settings.json."
fi
ok "✓ Primer script produces valid JSON"

# --- Merge settings.json -----------------------------------------------------
HOOK_CMD='node "$HOME/.claude/hooks/session-start-primer.js"'
NEW_HOOK=$(jq -n --arg cmd "$HOOK_CMD" '{
  matcher: "",
  hooks: [ { type: "command", command: $cmd } ]
}')

if [[ -f "$SETTINGS" ]]; then
  cp "$SETTINGS" "$BACKUP"
  ok "✓ Backed up existing settings.json to $BACKUP"

  # Skip if a SessionStart hook already calls our primer (idempotent).
  if jq -e --arg dst "$PRIMER_DST" '.hooks.SessionStart // [] | flatten | map(.hooks // [])
       | flatten | map(.command // "") | any(contains("session-start-primer.js"))' \
       "$SETTINGS" >/dev/null 2>&1; then
    warn "↻ SessionStart primer hook already registered — leaving settings.json unchanged."
  else
    TMP=$(mktemp)
    jq --argjson newHook "$NEW_HOOK" '
      .hooks //= {}
      | .hooks.SessionStart = ((.hooks.SessionStart // []) + [$newHook])
    ' "$SETTINGS" > "$TMP"
    mv "$TMP" "$SETTINGS"
    ok "✓ Merged SessionStart hook into existing settings.json"
  fi
else
  jq --argjson newHook "$NEW_HOOK" -n '{
    "$schema": "https://json.schemastore.org/claude-code-settings.json",
    "hooks": { "SessionStart": [ $newHook ] }
  }' > "$SETTINGS"
  ok "✓ Created new settings.json with SessionStart hook"
fi

# --- Final validation --------------------------------------------------------
if jq -e '.hooks.SessionStart' "$SETTINGS" >/dev/null; then
  ok "✓ Validated final settings.json"
else
  die "Final settings.json failed validation. Restore from $BACKUP if you saw a backup created above."
fi

echo
bold "Done."
echo "Open /hooks in any Claude Code session to reload config, or restart Claude Code."
echo "From the next session onward, every Claude Code session in any repo will run the agent-bridge primer."
