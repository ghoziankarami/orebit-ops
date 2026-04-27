#!/bin/bash
set -euo pipefail

VAULT_PATH="${VAULT_PATH:-/app/working/workspaces/default/obsidian-system/vault}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TYPE=""
TITLE=""
CONTEXT=""
CONTENT=""
PROJECT=""
TAGS="chat-capture"
STATUS="Draft"
PUSH=0

usage() {
    cat <<EOF
Usage: bash ops/scripts/capture/capture-chat-output.sh \
  --type idea|research|decision|workflow|sop|image-concept|deck-brief|video-brief \
  --title "..." \
  --content "..." \
  [--context "..."] [--project "..."] [--tags "a,b,c"] [--status "Draft"] [--push]
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --type) TYPE="$2"; shift 2 ;;
        --title) TITLE="$2"; shift 2 ;;
        --content) CONTENT="$2"; shift 2 ;;
        --context) CONTEXT="$2"; shift 2 ;;
        --project) PROJECT="$2"; shift 2 ;;
        --tags) TAGS="$2"; shift 2 ;;
        --status) STATUS="$2"; shift 2 ;;
        --push) PUSH=1; shift ;;
        *) echo "Unknown arg: $1"; usage; exit 1 ;;
    esac
done

if [[ -z "$TYPE" || -z "$TITLE" || -z "$CONTENT" ]]; then
    usage
    exit 1
fi

case "$TYPE" in
    idea)
        TARGET_DIR="$VAULT_PATH/0. Inbox/Ideas"
        KIND="Idea"
        ;;
    research)
        TARGET_DIR="$VAULT_PATH/0. Inbox/Research"
        KIND="Research Brief"
        ;;
    decision)
        TARGET_DIR="$VAULT_PATH/0. Inbox/Task Notes"
        KIND="Decision Log"
        ;;
    workflow)
        TARGET_DIR="$VAULT_PATH/3. Resources/Operating Systems"
        KIND="Workflow Draft"
        ;;
    sop)
        TARGET_DIR="$VAULT_PATH/3. Resources/SOPs"
        KIND="SOP Draft"
        ;;
    image-concept)
        TARGET_DIR="$VAULT_PATH/3. Resources/Visual Concepts"
        KIND="Image Concept"
        ;;
    deck-brief)
        TARGET_DIR="$VAULT_PATH/0. Inbox/Task Notes"
        KIND="Deck Brief"
        ;;
    video-brief)
        TARGET_DIR="$VAULT_PATH/0. Inbox/Task Notes"
        KIND="Video Brief"
        ;;
    *)
        echo "Unsupported type: $TYPE"
        exit 1
        ;;
esac

mkdir -p "$TARGET_DIR"
DATE_PREFIX="$(date -u +%Y-%m-%d)"
SLUG="$(printf '%s' "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\+/-/g' | sed 's/^-//;s/-$//')"
OUT="$TARGET_DIR/${DATE_PREFIX}-${SLUG}.md"

IFS=',' read -r -a TAG_ARR <<< "$TAGS"
TAG_BLOCK=""
for tag in "${TAG_ARR[@]}"; do
    clean="$(printf '%s' "$tag" | sed 's/^ *//;s/ *$//')"
    [[ -n "$clean" ]] && TAG_BLOCK+="  - ${clean}\n"
done
case ",$TAGS," in
    *,chat-capture,*) ;;
    *) TAG_BLOCK+="  - chat-capture\n" ;;
esac
case ",$TAGS," in
    *,${TYPE},*) ;;
    *) TAG_BLOCK+="  - ${TYPE}\n" ;;
esac

{
    printf -- '---\n'
    printf 'Kind: %s\n' "$KIND"
    printf 'Status: %s\n' "$STATUS"
    if [[ -n "$PROJECT" ]]; then
        printf 'Project: %s\n' "$PROJECT"
    fi
    printf 'Captured: %s\n' "$(date -u +'%Y-%m-%d %H:%M UTC')"
    printf 'tags:\n'
    printf '%b' "$TAG_BLOCK"
    printf -- '---\n\n'
    printf '# %s\n\n' "$TITLE"
    printf '## Context\n%s\n\n' "${CONTEXT:-Captured from QwenPaw chat.}"
    printf '## Captured Output\n%s\n\n' "$CONTENT"
    printf '## Why it matters\n- High-value output captured from chat so it does not remain only in transcript.\n\n'
    printf '## Next step\n- Review and promote if this becomes reusable or project-critical.\n'
} > "$OUT"

echo "$OUT"

if [[ "$PUSH" -eq 1 ]]; then
    bash "$SCRIPT_DIR/../sync/push-vault-safe.sh" >/dev/null 2>&1 || true
fi
