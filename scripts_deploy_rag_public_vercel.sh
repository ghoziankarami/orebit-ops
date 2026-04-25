#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RAG_DIR="$SCRIPT_DIR/rag-public"
PRIMARY_SECRETS_FILE="$HOME/.orebit/secrets.env"
LEGACY_SECRETS_FILE="$HOME/.openclaw/secrets.env"
SECRETS_FILE="${SECRETS_FILE:-}"
VERCEL_TOKEN_FILE="${VERCEL_TOKEN_FILE:-$HOME/.config/vercel/token}"
VERCEL_TOKEN="${VERCEL_TOKEN:-}"

if [ -z "$SECRETS_FILE" ]; then
  if [ -f "$PRIMARY_SECRETS_FILE" ]; then
    SECRETS_FILE="$PRIMARY_SECRETS_FILE"
  elif [ -f "$LEGACY_SECRETS_FILE" ]; then
    SECRETS_FILE="$LEGACY_SECRETS_FILE"
  else
    SECRETS_FILE="$PRIMARY_SECRETS_FILE"
  fi
fi

if [ -f "$SECRETS_FILE" ]; then
  set -a
  . "$SECRETS_FILE"
  set +a
  echo "Loaded secrets from $SECRETS_FILE"
else
  echo "Secrets file not found at $SECRETS_FILE; continuing with current environment"
fi

NPM_PREFIX="$(npm config get prefix 2>/dev/null || true)"
if [ -n "$NPM_PREFIX" ] && [ -d "$NPM_PREFIX/bin" ]; then
  export PATH="$NPM_PREFIX/bin:$PATH"
fi

RAG_API_BASE="${RAG_API_BASE:-https://api.orebit.id/api/rag}"
RAG_API_KEY="${RAG_API_KEY:-}"

if [ -z "$VERCEL_TOKEN" ] && [ -f "$VERCEL_TOKEN_FILE" ]; then
  VERCEL_TOKEN="$(cat "$VERCEL_TOKEN_FILE")"
fi

if ! command -v vercel >/dev/null 2>&1; then
  echo "Vercel CLI not found; installing..."
  npm install -g vercel
fi

cd "$RAG_DIR"
echo "Working directory: $RAG_DIR"

if [ ! -d ".vercel" ]; then
  echo "Linking Vercel project..."
  if [ -n "$VERCEL_TOKEN" ] && [ "$VERCEL_TOKEN" != "replace-me" ]; then
    vercel link --prod --yes --token "$VERCEL_TOKEN"
  else
    vercel link --prod --yes
  fi
fi

if [ -n "$VERCEL_TOKEN" ] && [ "$VERCEL_TOKEN" != "replace-me" ]; then
  echo "Syncing Vercel env vars..."
  vercel env add RAG_API_BASE production --value "$RAG_API_BASE" --token "$VERCEL_TOKEN" --yes --force >/dev/null
  vercel env add RAG_API_KEY production --value "$RAG_API_KEY" --token "$VERCEL_TOKEN" --yes --force >/dev/null
  vercel env remove VITE_RAG_API_BASE production --token "$VERCEL_TOKEN" --yes >/dev/null 2>&1 || true
  vercel env remove VITE_RAG_API_KEY production --token "$VERCEL_TOKEN" --yes >/dev/null 2>&1 || true
else
  echo "VERCEL_TOKEN missing or placeholder; skipping automatic env sync"
fi

echo "Building rag-public..."
npm install --include=dev
npm run build

echo "Deploying to Vercel..."
if [ -n "$VERCEL_TOKEN" ] && [ "$VERCEL_TOKEN" != "replace-me" ]; then
  vercel --prod --token "$VERCEL_TOKEN"
else
  vercel --prod
fi

echo "Done. Verify https://rag.orebit.id and https://rag.orebit.id/api/rag/health"
