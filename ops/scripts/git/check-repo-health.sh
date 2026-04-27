#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../../.." && pwd)
cd "$REPO_ROOT"

printf 'repo=%s\n' "$REPO_ROOT"
printf 'branch=%s\n' "$(git branch --show-current 2>/dev/null || echo unknown)"
printf 'head=%s\n' "$(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
printf 'remote=%s\n' "$(git remote get-url origin 2>/dev/null || echo missing)"
printf 'user.name=%s\n' "$(git config --get user.name || echo unset)"
printf 'user.email=%s\n' "$(git config --get user.email || echo unset)"
printf 'pull.ff=%s\n' "$(git config --get pull.ff || echo unset)"
printf 'fetch.prune=%s\n' "$(git config --get fetch.prune || echo unset)"
printf 'hooksPath=%s\n' "$(git config --get core.hooksPath || echo unset)"
printf 'worktrees=%s\n' "$(git worktree list --porcelain 2>/dev/null | grep -c '^worktree ' || echo 0)"

if git diff --quiet && git diff --cached --quiet; then
  echo 'status=clean'
else
  echo 'status=dirty'
  git status --short
  if git diff --name-only | grep -qx 'docs/operations/OBSIDIAN_INBOX_AUTOSYNC_STATUS.md'; then
    echo 'note=runtime-status-churn-detected'
  fi
fi
