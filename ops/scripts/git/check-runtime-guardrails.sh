#!/bin/sh
set -eu

REPO_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../../.." && pwd)
cd "$REPO_ROOT"

blocked_files='
docs/operations/OBSIDIAN_INBOX_AUTOSYNC_STATUS.md
'

staged_files=$(git diff --cached --name-only)
unstaged_files=$(git diff --name-only)

for f in $blocked_files; do
  [ -n "$f" ] || continue
  echo "$staged_files" | grep -qx "$f" && {
    echo "ERROR: refusing commit with runtime status file staged: $f" >&2
    echo "This file is runtime churn, not canonical repo state." >&2
    echo "Unstage it with: git restore --staged '$f'" >&2
    exit 1
  }
done

if echo "$unstaged_files" | grep -qx 'docs/operations/OBSIDIAN_INBOX_AUTOSYNC_STATUS.md'; then
  echo "WARN: runtime status file is dirty: docs/operations/OBSIDIAN_INBOX_AUTOSYNC_STATUS.md" >&2
  echo "This is expected runtime churn; do not treat it as a canonical change unless explicitly intended." >&2
fi

if [ -x "$REPO_ROOT/ops/scripts/sync/status-local-embedding-server.sh" ]; then
  if ! "$REPO_ROOT/ops/scripts/sync/status-local-embedding-server.sh" >/dev/null 2>&1; then
    echo "ERROR: local embedding server health check failed." >&2
    echo "Run: bash ops/scripts/sync/start-local-embedding-server.sh" >&2
    exit 1
  fi
fi

if [ -x "$REPO_ROOT/ops/scripts/sync/status-obsidian-inbox-autosync.sh" ]; then
  if ! "$REPO_ROOT/ops/scripts/sync/status-obsidian-inbox-autosync.sh" >/tmp/orebit-autosync-status.$$ 2>&1; then
    echo "WARN: autosync status script returned non-zero. Review before pushing canonical ops changes." >&2
  elif ! grep -q 'Status: RUNNING' /tmp/orebit-autosync-status.$$; then
    echo "WARN: autosync daemon is not RUNNING. Review before pushing canonical ops changes." >&2
  fi
  rm -f /tmp/orebit-autosync-status.$$
fi

exit 0
