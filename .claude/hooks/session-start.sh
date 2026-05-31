#!/usr/bin/env bash
# Self-hook for the agent-bridge repo. Fires the bundled primer at
# session start, so working on agent-bridge in Claude Code (cloud or
# local) triggers the gate even without the user-level install.
#
# This is the per-repo equivalent of the user-level hook that
# `./install.sh` registers in ~/.claude/settings.json.
set -euo pipefail
exec node "$CLAUDE_PROJECT_DIR/hooks/session-start-primer.js"
