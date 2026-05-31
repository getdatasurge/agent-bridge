#!/usr/bin/env bash
# agent-bridge — explicit pull-and-validate of the local clone.
#
# Pairs with install.sh's symlink-based hook install: a `git pull` in
# this clone is enough to update the primer Claude Code runs, but most
# users want a single command that also (a) shows what's incoming and
# (b) confirms the new primer still produces valid JSON before they
# walk away thinking they're updated.
#
# Usage:
#   ./update.sh

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_DIR"

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
ok()   { printf '\033[32m%s\033[0m\n' "$*"; }
warn() { printf '\033[33m%s\033[0m\n' "$*"; }
die()  { printf '\033[31m%s\033[0m\n' "$*" >&2; exit 1; }

command -v node >/dev/null 2>&1 || die "node not found on PATH (required by the primer)."
command -v jq   >/dev/null 2>&1 || die "jq not found on PATH (used to validate primer output)."
command -v git  >/dev/null 2>&1 || die "git not found on PATH."

[[ -d "$REPO_DIR/.git" ]] || die "$REPO_DIR is not a git checkout — nothing to pull. Re-clone agent-bridge to a path you control."

bold "==> Updating agent-bridge in $REPO_DIR"

# Quietly fetch upstream so we can show the user what would change.
if ! git fetch --quiet origin 2>/dev/null; then
  warn "git fetch failed — network or auth issue. Continuing with what's local."
fi

LOCAL_HEAD=$(git rev-parse HEAD)
UPSTREAM_HEAD=$(git rev-parse '@{u}' 2>/dev/null || echo "$LOCAL_HEAD")

if [[ "$LOCAL_HEAD" == "$UPSTREAM_HEAD" ]]; then
  ok "✓ Already up to date ($(git rev-parse --short HEAD))."
else
  bold "Incoming changes:"
  git --no-pager log --oneline "$LOCAL_HEAD..$UPSTREAM_HEAD"
  echo
  if ! git pull --ff-only --quiet; then
    die "Fast-forward pull failed — your local branch has diverged. Resolve manually."
  fi
  ok "✓ Pulled to $(git rev-parse --short HEAD)."
fi

# Validate the (possibly updated) primer still produces good JSON.
PRIMER="$REPO_DIR/hooks/session-start-primer.js"
[[ -f "$PRIMER" ]] || die "Primer script missing after pull: $PRIMER"

if ! node "$PRIMER" | jq -e '.hookSpecificOutput.additionalContext' >/dev/null; then
  die "Primer no longer produces valid JSON after update. Roll back or investigate before next Claude session."
fi
ok "✓ Primer validation passed."

# Reassure the user that the hook is still wired up.
SETTINGS="${HOME}/.claude/settings.json"
PRIMER_DST="${HOME}/.claude/hooks/session-start-primer.js"
if [[ -L "$PRIMER_DST" ]]; then
  TARGET=$(readlink "$PRIMER_DST")
  if [[ "$TARGET" == "$PRIMER" ]]; then
    ok "✓ Hook symlink points at this clone ($PRIMER_DST -> $TARGET)."
  else
    warn "Hook symlink points elsewhere: $PRIMER_DST -> $TARGET. Run ./install.sh from THIS clone if you want it pointing here."
  fi
elif [[ -f "$PRIMER_DST" ]]; then
  warn "Hook is a copy, not a symlink. Updates won't propagate automatically. Re-run ./install.sh to convert to symlink."
else
  warn "No hook installed at $PRIMER_DST. Run ./install.sh once."
fi

if [[ -f "$SETTINGS" ]] && ! jq -e '.hooks.SessionStart // [] | flatten | map(.hooks // []) | flatten | map(.command // "") | any(contains("session-start-primer.js"))' "$SETTINGS" >/dev/null 2>&1; then
  warn "Hook isn't registered in $SETTINGS. Run ./install.sh once."
fi

echo
bold "Done."
echo "The next Claude Code session will use the updated primer automatically."
