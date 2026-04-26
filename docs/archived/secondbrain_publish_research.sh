#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNTIME_RESEARCH="/workspace/research-data"
OBSIDIAN_INBOX="/workspace/obsidian-system/vault/0. Inbox/Research"

if [ $# -eq 0 ]; then
  echo "Usage: $0 <research-slug>"
  echo "Available slugs:"
  find "$RUNTIME_RESEARCH" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort
  exit 1
fi

SLUG="$1"
PROJECT_DIR="$RUNTIME_RESEARCH/$SLUG"
if [ ! -d "$PROJECT_DIR" ]; then
  echo "ERROR: research project not found: $PROJECT_DIR"
  exit 1
fi

mkdir -p "$OBSIDIAN_INBOX"
STAMP=$(date +%Y-%m-%d)
OUT="$OBSIDIAN_INBOX/Research - $SLUG - $STAMP.md"
README_FILE=""
SUMMARY="No summary available. See runtime research data."

if [ -f "$PROJECT_DIR/README.md" ]; then
  README_FILE="$PROJECT_DIR/README.md"
elif [ -f "$PROJECT_DIR/readme.md" ]; then
  README_FILE="$PROJECT_DIR/readme.md"
fi

if [ -n "$README_FILE" ]; then
  SUMMARY=$(head -c 500 "$README_FILE" | sed 's/^#\+ //')
fi

cat > "$OUT" <<EOF
---
Kind: Resource
Type: Research Output
Status: Active
Date Created: $STAMP
Date Updated: $STAMP
tags:
  - research
  - orebit
  - inbox
Project: $SLUG
Source Path: /workspace/research-data/$SLUG
---

# Research: $SLUG

**Published:** $STAMP

## Summary

$SUMMARY

## Runtime Source

- Runtime folder: \/workspace\/research-data\/$SLUG
- Bootstrap repo: \/workspace\/orebit-rag-deploy
EOF

echo "$OUT"
