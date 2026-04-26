#!/bin/bash
set -euo pipefail

VAULT_PATH="${VAULT_PATH:-/app/working/workspaces/default/obsidian-system/vault}"
TASK_DIR="${VAULT_PATH}/0. Inbox/Task Notes"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TITLE=""
PROJECT=""
PRIORITY=""
DEADLINE=""
STATUS="Draft"
DESCRIPTION=""
TAGS="task-note"
PUSH=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --title) TITLE="$2"; shift 2 ;;
        --project) PROJECT="$2"; shift 2 ;;
        --priority) PRIORITY="$2"; shift 2 ;;
        --deadline) DEADLINE="$2"; shift 2 ;;
        --status) STATUS="$2"; shift 2 ;;
        --description) DESCRIPTION="$2"; shift 2 ;;
        --tags) TAGS="$2"; shift 2 ;;
        --push) PUSH=1; shift ;;
        *) echo "Unknown arg: $1"; exit 1 ;;
    esac
 done

if [[ -z "$TITLE" ]]; then
    echo "Usage: bash capture-task-note.sh --title \"...\" [--project ...] [--priority ...] [--deadline ...] [--description ...] [--push]"
    exit 1
fi

mkdir -p "$TASK_DIR"
DATE_PREFIX="$(date -u +%Y-%m-%d)"
SLUG="$(printf '%s' "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g' | sed 's/^-//;s/-$//')"
OUT="$TASK_DIR/${DATE_PREFIX}-${SLUG}.md"

cat > "$OUT" <<EOF
---
Kind: Task
Status: $STATUS
Priority: $PRIORITY
Deadline: $DEADLINE
tags:
  - ${TAGS}
Cover:
Description: ${DESCRIPTION}
Project: ${PROJECT}
---

# ${TITLE}

## Task Context
${DESCRIPTION}

## Next Actions
- 

## Notes
- Captured from chat on $(date -u +'%Y-%m-%d %H:%M UTC')
EOF

echo "$OUT"

if [[ "$PUSH" -eq 1 ]]; then
    bash "$SCRIPT_DIR/../sync/push-vault-safe.sh" >/dev/null 2>&1 || true
fi
