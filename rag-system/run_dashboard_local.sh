#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DASHBOARD="$ROOT/rag_dashboard_local.py"
LOG="$ROOT/dashboard_local.log"
PIDFILE="$ROOT/dashboard_local.pid"

if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
  echo "Dashboard already running with PID $(cat "$PIDFILE")"
  exit 0
fi

export STREAMLIT_BROWSER_GATHER_USAGE_STATS=false
export STREAMLIT_SERVER_HEADLESS=true
nohup streamlit run "$DASHBOARD" --server.port 8503 --server.address 0.0.0.0 > "$LOG" 2>&1 &
echo $! > "$PIDFILE"
echo "Started dashboard with PID $(cat "$PIDFILE")"
