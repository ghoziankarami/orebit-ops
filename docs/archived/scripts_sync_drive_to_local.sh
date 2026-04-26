#!/usr/bin/env bash
set -euo pipefail

OBSIDIAN_REMOTE="gdrive-obsidian:"
RESEARCH_REMOTE="gdrive-research:"
OBSIDIAN_LOCAL="/workspace/obsidian-system/vault"
RESEARCH_CACHE_LOCAL="/workspace/research-data/papers-cache"

mkdir -p "$OBSIDIAN_LOCAL" "$RESEARCH_CACHE_LOCAL"

usage() {
  cat <<'EOF'
Usage:
  bash scripts_sync_drive_to_local.sh obsidian [--dry-run]
  bash scripts_sync_drive_to_local.sh research [--dry-run] [--include PATTERN]
  bash scripts_sync_drive_to_local.sh sample [--dry-run]
EOF
}

DRY_RUN=false
INCLUDE_PATTERN="*.pdf"
MODE="${1:-}"
if [[ -z "$MODE" ]]; then
  usage
  exit 1
fi
shift || true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --include) INCLUDE_PATTERN="${2:-*.pdf}"; shift 2 ;;
    *) echo "Unknown option: $1"; usage; exit 1 ;;
  esac
done

FLAGS=(--progress --fast-list)
if [[ "$DRY_RUN" == true ]]; then
  FLAGS+=(--dry-run)
fi

case "$MODE" in
  obsidian)
    rclone sync "$OBSIDIAN_REMOTE" "$OBSIDIAN_LOCAL" \
      --exclude ".git/**" \
      --exclude ".trash/**" \
      --exclude ".obsidian/workspace*.json" \
      "${FLAGS[@]}"
    ;;
  research)
    rclone copy "$RESEARCH_REMOTE" "$RESEARCH_CACHE_LOCAL" \
      --include "$INCLUDE_PATTERN" \
      "${FLAGS[@]}"
    ;;
  sample)
    rclone copy "$OBSIDIAN_REMOTE" "$OBSIDIAN_LOCAL" \
      --include "README.md" \
      --include "Home.md" \
      --include "0. Inbox/**" \
      --include ".obsidian/**" \
      --exclude ".git/**" \
      "${FLAGS[@]}"
    rclone copy "$RESEARCH_REMOTE" "$RESEARCH_CACHE_LOCAL" \
      --include "*.pdf" \
      --max-transfer 50M \
      --max-size 50M \
      "${FLAGS[@]}"
    ;;
  *)
    usage
    exit 1
    ;;
esac
