#!/usr/bin/env bash
set -euo pipefail

WRAPPER_ROOT="${WRAPPER_ROOT:-/app/working/workspaces/default/orebit-ops/rag-system/api-wrapper}"
HOST="${RAG_WRAPPER_HOST:-127.0.0.1}"
WRAPPER_PORT="${RAG_WRAPPER_PORT:-3004}"
BASE_URL="http://${HOST}:${WRAPPER_PORT}/api/rag"
EMBED_HEALTH_URL="${EMBED_HEALTH_URL:-http://127.0.0.1:3005/health}"

cd "$WRAPPER_ROOT"

echo "== RAG Wrapper Preflight =="
echo "wrapper_root=$WRAPPER_ROOT"
echo "base_url=$BASE_URL"

echo "-- embedding health"
curl -fsS "$EMBED_HEALTH_URL"
echo

echo "-- provider stats"
python3 rag_public_data.py stats >/tmp/rag-wrapper-stats.json
python3 - <<'PY'
import json
from pathlib import Path
p = Path('/tmp/rag-wrapper-stats.json')
data = json.loads(p.read_text())
print(json.dumps({
    'mode': data.get('mode'),
    'llm_ready': data.get('llm_ready'),
    'indexed_papers': data.get('indexed_papers'),
    'summary_count': data.get('summary_count'),
    'collection_count': data.get('collection_count'),
}, indent=2))
PY

echo "-- wrapper health"
curl -fsS "$BASE_URL/health"
echo

echo "-- wrapper stats"
curl -fsS "$BASE_URL/stats"
echo

echo "-- wrapper browse smoke"
curl -fsS "$BASE_URL/browse?page=1&limit=3" >/tmp/rag-wrapper-browse.json
python3 - <<'PY'
import json
from pathlib import Path
p = Path('/tmp/rag-wrapper-browse.json')
data = json.loads(p.read_text())
print(json.dumps({
    'keys': sorted(list(data.keys()))[:10],
    'record_count': len(data.get('papers', []) or data.get('results', []) or []),
}, indent=2))
PY

echo "preflight=ok"
