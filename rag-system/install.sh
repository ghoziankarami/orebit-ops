#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== RAG System Setup ==="

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker is required but not found in PATH"
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "ERROR: docker compose v2 is required but not available"
  exit 1
fi

mkdir -p "$SCRIPT_DIR/chroma"

echo "Starting RAG stack with docker compose..."
docker compose up -d --build

echo "Waiting for RAG API health..."
for i in $(seq 1 40); do
  if curl -fsS http://127.0.0.1:3004/api/rag/health >/dev/null 2>&1; then
    echo "RAG API is healthy"
    break
  fi
  if [ "$i" -eq 40 ]; then
    echo "ERROR: RAG API did not become healthy in time"
    exit 1
  fi
  sleep 3
done

echo "Checking RAG dashboard health..."
for i in $(seq 1 40); do
  if curl -fsS http://127.0.0.1:8503/_stcore/health >/dev/null 2>&1; then
    echo "RAG dashboard is healthy"
    exit 0
  fi
  sleep 3
done

echo "WARN: RAG dashboard did not become healthy in time"
exit 0
