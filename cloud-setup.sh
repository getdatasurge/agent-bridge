#!/usr/bin/env bash
# agent-bridge — Claude Code on the Web environment bootstrap.
#
# Paste this (or fetch + run via the one-liner below) in your Claude
# Code on the Web environment "setup script" so every container that
# boots from this environment has the agent-bridge primer registered
# BEFORE any chat starts. Each container = fresh clone + fresh install
# = always the latest from GitHub. No manual update step.
#
# One-liner for env setup configs:
#   curl -fsSL https://raw.githubusercontent.com/getdatasurge/agent-bridge/main/cloud-setup.sh | bash
#
# Or check out the repo first, then run this script. Idempotent — safe
# to re-run; the install picks up new primer versions on each boot.
#
# Environment overrides (rarely needed):
#   AGENT_BRIDGE_REPO   — git URL to clone from (default: getdatasurge/agent-bridge on GitHub)
#   AGENT_BRIDGE_DIR    — local clone path (default: $HOME/agent-bridge)
#   AGENT_BRIDGE_BRANCH — branch to track (default: main)

set -euo pipefail

REPO_URL="${AGENT_BRIDGE_REPO:-https://github.com/getdatasurge/agent-bridge.git}"
CLONE_DIR="${AGENT_BRIDGE_DIR:-$HOME/agent-bridge}"
BRANCH="${AGENT_BRIDGE_BRANCH:-main}"

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
ok()   { printf '\033[32m%s\033[0m\n' "$*"; }
warn() { printf '\033[33m%s\033[0m\n' "$*"; }
die()  { printf '\033[31m%s\033[0m\n' "$*" >&2; exit 1; }

command -v git  >/dev/null 2>&1 || die "git not found on PATH."
command -v node >/dev/null 2>&1 || die "node not found on PATH (required by the primer)."
command -v jq   >/dev/null 2>&1 || die "jq not found on PATH (required by install.sh's settings.json merge)."

bold "==> agent-bridge cloud bootstrap"
echo "Repo:   $REPO_URL"
echo "Clone:  $CLONE_DIR"
echo "Branch: $BRANCH"
echo

# --- Clone or pull -----------------------------------------------------------
if [[ -d "$CLONE_DIR/.git" ]]; then
  bold "Updating existing clone at $CLONE_DIR"
  git -C "$CLONE_DIR" fetch --quiet origin "$BRANCH" || warn "fetch failed; using local state."
  # If on the tracking branch with no local commits, ff-pull. Otherwise just warn.
  CURRENT_BRANCH=$(git -C "$CLONE_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
  if [[ "$CURRENT_BRANCH" == "$BRANCH" ]]; then
    if git -C "$CLONE_DIR" pull --ff-only --quiet origin "$BRANCH"; then
      ok "✓ Pulled latest from origin/$BRANCH ($(git -C "$CLONE_DIR" rev-parse --short HEAD))."
    else
      warn "Fast-forward pull failed (local diverged?). Using whatever's checked out: $(git -C "$CLONE_DIR" rev-parse --short HEAD)."
    fi
  else
    warn "Clone is on '$CURRENT_BRANCH', not '$BRANCH'. Leaving as-is."
  fi
else
  bold "Cloning $REPO_URL into $CLONE_DIR"
  git clone --quiet --branch "$BRANCH" "$REPO_URL" "$CLONE_DIR"
  ok "✓ Cloned to $(git -C "$CLONE_DIR" rev-parse --short HEAD)."
fi

# --- Install the user-level hook --------------------------------------------
bold "Running ./install.sh"
cd "$CLONE_DIR"
./install.sh

echo
bold "Done."
echo "Every Claude Code session in this environment will now run the agent-bridge primer at startup."
echo "The primer enforces the PRD/PROGRESS gate, listing open PRs first to avoid stepping on other agents."
