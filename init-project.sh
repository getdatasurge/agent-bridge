#!/usr/bin/env bash
# agent-bridge — per-project init.
#
# Drops AGENTS.md, CLAUDE.md, PRD.md, PROGRESS.md into a target project
# so any agent entering it follows the agent-bridge conventions.
#
# Also drops .claude/hooks/session-start.sh + .claude/settings.json into
# the project. These commit to git, so every Claude Code session on the
# project (cloud OR local) fires the agent-bridge primer at session
# start regardless of the user's per-machine setup.
#
# Usage:
#   ./init-project.sh <project-dir>
#   ./init-project.sh .                  # init current directory
#
# Existing files are NOT overwritten. To replace, delete them first.
# An existing .claude/settings.json gets merged (if jq is available)
# rather than overwritten.

set -euo pipefail

TARGET="${1:-}"
[[ -n "$TARGET" ]] || { echo "Usage: $0 <project-dir>" >&2; exit 1; }
[[ -d "$TARGET" ]] || { echo "Not a directory: $TARGET" >&2; exit 1; }

# Resolve to absolute path so messages and embedded snapshots are stable.
TARGET="$(cd "$TARGET" && pwd)"

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES="${REPO_DIR}/templates"
PRIMER="${REPO_DIR}/hooks/session-start-primer.js"

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
ok()   { printf '\033[32m%s\033[0m\n' "$*"; }
skip() { printf '\033[33m%s\033[0m\n' "$*"; }
warn() { printf '\033[33m%s\033[0m\n' "$*" >&2; }

bold "==> Initializing agent-bridge in $TARGET"

# --- Markdown templates ------------------------------------------------------
for f in AGENTS.md CLAUDE.md PRD.md PROGRESS.md; do
  src="${TEMPLATES}/${f}"
  dst="${TARGET}/${f}"
  if [[ -e "$dst" ]]; then
    skip "↻ $f already exists — skipping (delete to replace)."
  else
    cp "$src" "$dst"
    ok "✓ Created $f"
  fi
done

# --- Per-repo SessionStart hook ---------------------------------------------
# This is what makes the primer fire in cloud Claude Code sessions even
# without a user-level install — the hook is committed to git, so every
# fresh container that opens the project sees it.

HOOK_DIR="${TARGET}/.claude/hooks"
HOOK_SH="${HOOK_DIR}/session-start.sh"
HOOK_SETTINGS="${TARGET}/.claude/settings.json"

mkdir -p "$HOOK_DIR"

if [[ -e "$HOOK_SH" ]]; then
  skip "↻ .claude/hooks/session-start.sh already exists — skipping (delete to refresh)."
else
  # Snapshot the current primer JSON output and embed it inline. Self-
  # contained: the dropped hook doesn't depend on having agent-bridge
  # cloned. To refresh against newer primer versions, delete the file
  # and re-run init-project.sh, or use update-project.sh.
  if ! command -v node >/dev/null 2>&1; then
    warn "node not on PATH — using minimal fallback primer in dropped hook."
    RENDERED_PRIMER='{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"agent-bridge primer (fallback): check the repo root for PRD.md and PROGRESS.md before addressing the user. If either is missing and this is a code project, alert the user before any other work."}}'
  else
    if ! RENDERED_PRIMER=$(node "$PRIMER" 2>/dev/null); then
      warn "Primer script failed; using minimal fallback in dropped hook."
      RENDERED_PRIMER='{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"agent-bridge primer (fallback): check the repo root for PRD.md and PROGRESS.md before addressing the user."}}'
    fi
  fi

  SNAPSHOT_SHA="$(git -C "$REPO_DIR" rev-parse --short HEAD 2>/dev/null || echo unknown)"
  SNAPSHOT_DATE="$(date +%Y-%m-%d)"

  cat > "$HOOK_SH" <<HOOK_EOF
#!/usr/bin/env bash
# agent-bridge per-repo SessionStart hook.
#
# Emits the agent-bridge primer at session start so every Claude Code
# session on this repo (cloud or local) runs the multi-agent
# coordination gate before processing the user's first prompt.
#
# Snapshot from agent-bridge ${SNAPSHOT_SHA} on ${SNAPSHOT_DATE}. To
# refresh against a newer primer, re-run agent-bridge's update-project.sh
# or delete this file and re-run init-project.sh from a freshly-pulled
# agent-bridge clone.
set -euo pipefail
cat <<'JSON_PAYLOAD'
${RENDERED_PRIMER}
JSON_PAYLOAD
HOOK_EOF
  chmod +x "$HOOK_SH"
  ok "✓ Created .claude/hooks/session-start.sh (primer snapshot from agent-bridge ${SNAPSHOT_SHA})"
fi

# --- .claude/settings.json (create or merge) --------------------------------
HOOK_CMD='$CLAUDE_PROJECT_DIR/.claude/hooks/session-start.sh'
NEW_HOOK_ENTRY='{"matcher":"","hooks":[{"type":"command","command":"'"$HOOK_CMD"'"}]}'

if [[ -f "$HOOK_SETTINGS" ]]; then
  if ! command -v jq >/dev/null 2>&1; then
    warn ".claude/settings.json exists but jq not on PATH — leaving alone. Merge manually:"
    warn "  add SessionStart hook entry running '$HOOK_CMD'"
  elif jq -e --arg cmd "$HOOK_CMD" \
        '(.hooks.SessionStart // []) | flatten
         | map(.hooks // []) | flatten
         | map(.command // "") | any(. == $cmd)' \
        "$HOOK_SETTINGS" >/dev/null 2>&1; then
    skip "↻ .claude/settings.json already registers the hook — skipping."
  else
    TMP=$(mktemp)
    jq --argjson newHook "$NEW_HOOK_ENTRY" '
      .hooks //= {}
      | .hooks.SessionStart = ((.hooks.SessionStart // []) + [$newHook])
    ' "$HOOK_SETTINGS" > "$TMP"
    mv "$TMP" "$HOOK_SETTINGS"
    ok "✓ Merged SessionStart hook into existing .claude/settings.json"
  fi
else
  cat > "$HOOK_SETTINGS" <<'SETTINGS_EOF'
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/session-start.sh"
          }
        ]
      }
    ]
  }
}
SETTINGS_EOF
  ok "✓ Created .claude/settings.json with SessionStart hook"
fi

echo
bold "Done."
echo "Next steps:"
echo "  1. Edit ${TARGET}/PRD.md to capture your actual requirements + initial status."
echo "  2. Commit all six files (AGENTS.md, CLAUDE.md, PRD.md, PROGRESS.md, .claude/hooks/session-start.sh, .claude/settings.json) to git so other agents see them and every cloud Claude session auto-primes."
echo "  3. Run \`gh pr list --state open\` before starting work to see what other agents are doing."
