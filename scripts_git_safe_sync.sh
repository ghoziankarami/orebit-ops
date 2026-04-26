#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

BRANCH="${1:-}"
MESSAGE="${2:-chore: sync orebit ops repo}"

current_branch=$(git branch --show-current)
default_branch=$(git remote show origin 2>/dev/null | awk '/HEAD branch/ {print $NF}')
default_branch=${default_branch:-main}

if [ -z "$BRANCH" ]; then
  if [ "$current_branch" = "$default_branch" ]; then
    echo "ERROR: refusing to auto-push from default branch '$default_branch'"
    echo "Create or switch to a task branch first, or pass a branch name explicitly."
    exit 1
  fi
  BRANCH="$current_branch"
fi

if [ "$BRANCH" = "$default_branch" ]; then
  echo "ERROR: refusing to push directly to default branch '$default_branch'"
  exit 1
fi

git add README.md AGENTS.md docs ops obsidian-system rag-system scripts_git_safe_sync.sh .gitignore || true

if git diff --cached --quiet; then
  echo "No tracked repo changes staged."
  exit 0
fi

git commit -m "$MESSAGE"
git push -u origin "$BRANCH"

echo "Pushed repo changes to branch $BRANCH"
