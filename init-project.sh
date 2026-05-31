#!/usr/bin/env bash
# agent-bridge — per-project init.
#
# Drops AGENTS.md, CLAUDE.md, PRD.md, PROGRESS.md into a target project
# so any agent entering it follows the agent-bridge conventions.
#
# Usage:
#   ./init-project.sh <project-dir>
#   ./init-project.sh .                  # init current directory
#
# Existing files are NOT overwritten. To replace, delete them first.

set -euo pipefail

TARGET="${1:-}"
[[ -n "$TARGET" ]] || { echo "Usage: $0 <project-dir>" >&2; exit 1; }
[[ -d "$TARGET" ]] || { echo "Not a directory: $TARGET" >&2; exit 1; }

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES="${REPO_DIR}/templates"

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
ok()   { printf '\033[32m%s\033[0m\n' "$*"; }
skip() { printf '\033[33m%s\033[0m\n' "$*"; }

bold "==> Initializing agent-bridge in $TARGET"

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

echo
bold "Done."
echo "Next steps:"
echo "  1. Edit ${TARGET}/PRD.md to capture your actual requirements + initial status."
echo "  2. Commit the four files to git so other agents see them."
echo "  3. Run \`gh pr list --state open\` before starting work to see what other agents are doing."
