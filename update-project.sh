#!/usr/bin/env bash
# agent-bridge — show diffs between a project's tracked files and the
# latest templates. Non-destructive: no file is auto-written, you decide
# which hunks to apply.
#
# Usage:
#   ./update-project.sh <project-dir>
#
# What it does, per file in {AGENTS.md, CLAUDE.md, PRD.md, PROGRESS.md}:
#   - If the project doesn't have it: tell you to run init-project.sh.
#   - If it matches the template exactly: skip silently.
#   - Otherwise: show a unified diff. You apply manually.
#
# AGENTS.md and CLAUDE.md are agent-owned convention files — refreshes
# from upstream are usually safe and desirable.
#
# PRD.md and PROGRESS.md are project-owned state — the templates only
# show the SHAPE. Don't blindly apply diffs against them; you'll wipe
# real project content. They're included here only so you can see
# whether the shape has evolved upstream.

set -euo pipefail

TARGET="${1:-}"
[[ -n "$TARGET" ]] || { echo "Usage: $0 <project-dir>" >&2; exit 1; }
[[ -d "$TARGET" ]] || { echo "Not a directory: $TARGET" >&2; exit 1; }

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES="${REPO_DIR}/templates"

bold() { printf '\n\033[1m%s\033[0m\n' "$*"; }
ok()   { printf '\033[32m%s\033[0m\n' "$*"; }
skip() { printf '\033[33m%s\033[0m\n' "$*"; }
warn() { printf '\033[33m%s\033[0m\n' "$*" >&2; }

bold "==> Diffing $TARGET against latest templates in $TEMPLATES"
echo "(Agent-owned files: AGENTS.md, CLAUDE.md — usually safe to refresh.)"
echo "(Project-owned state: PRD.md, PROGRESS.md — review carefully; templates only show shape.)"

# Agent-owned files first (safer to apply).
for f in AGENTS.md CLAUDE.md; do
  src="${TEMPLATES}/${f}"
  dst="${TARGET}/${f}"

  bold "=== $f (agent-owned) ==="
  if [[ ! -f "$dst" ]]; then
    skip "Not present in project. Run ./init-project.sh $TARGET to create."
    continue
  fi
  if [[ ! -f "$src" ]]; then
    warn "No upstream template found at $src (unexpected)."
    continue
  fi
  if diff -q "$dst" "$src" >/dev/null 2>&1; then
    ok "Identical — no update needed."
    continue
  fi
  echo "Unified diff (project -> template):"
  diff -u "$dst" "$src" || true
done

# Project-owned state files. Show diffs but warn loudly.
for f in PRD.md PROGRESS.md; do
  src="${TEMPLATES}/${f}"
  dst="${TARGET}/${f}"

  bold "=== $f (project-owned state — review carefully) ==="
  if [[ ! -f "$dst" ]]; then
    skip "Not present in project. Run ./init-project.sh $TARGET to create."
    continue
  fi
  if [[ ! -f "$src" ]]; then
    warn "No upstream template found at $src (unexpected)."
    continue
  fi
  if diff -q "$dst" "$src" >/dev/null 2>&1; then
    ok "Identical to template — that's unusual unless this is a fresh init. Make sure your project's content is captured."
    continue
  fi
  echo "Unified diff (project -> template). REMINDER: don't blanket-apply — the template is a shape, not content."
  diff -u "$dst" "$src" || true
done

echo
bold "Done."
echo "Nothing was written. Apply hunks by editing files in $TARGET if you want any of them."
