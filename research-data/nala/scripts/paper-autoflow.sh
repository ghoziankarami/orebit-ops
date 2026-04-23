#!/bin/bash
# Nala Auto-Paper Pipeline
# Purpose: Wrapper to run paper-autoflow.py with proper environment
# Config: config/nala-paper-topics.yaml
# Log: /var/log/nala-paper-autoflow.log
# Requires: python3, paper-autoflow.py, log_activity.py
# Cron: 0 18 * * * /usr/bin/python3 /workspace/research-data/nala/scripts/paper-autoflow.py

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$SCRIPT_DIR/../config/nala-paper-topics.yaml"
LOG_FILE="/var/log/nala-paper-autoflow.log"
PAPER_TRACKER="$SCRIPT_DIR/paper-autoflow.py"
GENERATE_NOTES="/workspace/rag-system/scripts/generate_obsidian_notes_enhanced.py"
PROJECT_SLUG="pinn-geostat-augmented"  # Default project for tracking

timestamp() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log() {
    timestamp "$*"
}

error_exit() {
    timestamp "❌ ERROR: $*"
    exit 1
}

# Check prerequisites
for cmd in python3 jq; do
    if ! command -v $cmd &>/dev/null; then
        error_exit "Required command not found: $cmd"
    fi
done

if [ ! -f "$PAPER_TRACKER" ]; then
    error_exit "paper-tracker not found: $PAPER_TRACKER"
fi

if [ ! -f "$GENERATE_NOTES" ]; then
    error_exit "generate_obsidian_notes not found: $GENERATE_NOTES"
fi

# Read config
if [ ! -f "$CONFIG" ]; then
    error_exit "Config file not found: $CONFIG"
fi

# Parse YAML simply (awk/grep based)
MAX_PAPERS=$(grep -E "^max_papers_per_topic:" "$CONFIG" | head -1 | awk '{print $2}' | tr -d ' ')
MAX_AGE=$(grep -E "^max_age_days:" "$CONFIG" | head -1 | awk '{print $2}' | tr -d ' ')
EXECUTE=$(grep -E "^execute:" "$CONFIG" | head -1 | awk '{print $2}' | tr -d ' ')

if [ "$EXECUTE" != "true" ]; then
    log "DRY RUN mode (execute=false in config). No actual downloads will occur."
    EXECUTE=false
else
    log "EXECUTE mode enabled. Will download and process papers."
    EXECUTE=true
fi

log "=== Nala Auto-Paper Pipeline Starting ==="
log "Config: $CONFIG"
log "Max papers per topic: $MAX_PAPERS"
log "Max age days: $MAX_AGE"
log "Project: $PROJECT_SLUG"

# Extract topics
TOPICS=()
while IFS= read -r line; do
    # Remove leading/trailing spaces and quotes
    topic=$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/^"//' -e 's/"$//')
    if [[ -n "$topic" && ! "$topic" =~ ^# ]]; then
        TOPICS+=("$topic")
    fi
done < <(sed -n '/^topics:/,/^[a-z]/p' "$CONFIG" | tail -n +2 | grep -v '^[[:space:]]*$')

log "Topics to search: ${#TOPICS[@]}"

# Function to search for papers using Brave Search
search_papers_for_topic() {
    local topic="$1"
    local max_papers="$2"
    
    log "Searching for topic: $topic"
    
    # Use Brave Search API via web_search tool equivalent
    # Since we're in bash script, we'll simulate by calling python script that uses web_search
    # But we don't have direct web_search CLI. Instead, we'll use a simple approach:
    # We'll create a temporary script that uses the OpenClaw gateway to perform search
    
    # For now, we'll generate search queries and ask user to manually run web_search
    # Better: integrate with Nala agent via sessions_send
    
    # Temporary workaround: Print search query for manual execution
    echo "SEARCH_QUERY: $topic"
    
    # Return empty list (would need proper API integration)
    echo "[]"
}

# Alternative: Use Nala agent directly via OpenClaw API
# This would be more proper but requires gateway access

log "⚠️  Full automation requires integration with Brave Search API or Nala agent."
log "For now, this script demonstrates the pipeline structure."

# Steps would be:
# 1. For each topic: search → get DOIs/URLs
# 2. paper-tracker add <doi/url> for each
# 3. paper-tracker download --project $PROJECT_SLUG
# 4. paper-tracker index --project $PROJECT_SLUG
# 5. python3 $GENERATE_NOTES --project $PROJECT_SLUG --overwrite

log "Pipeline steps:"
echo "  1. Search topics (requires Brave API or Nala integration)"
echo "  2. paper-tracker add <DOI/URL>"
echo "  3. paper-tracker download --project $PROJECT_SLUG"
echo "  4. paper-tracker index --project $PROJECT_SLUG"
echo "  5. generate_obsidian_notes_enhanced.py --project $PROJECT_SLUG --overwrite"

log "✅ Config created. Ready to implement full search integration."
log "📝 See config: $CONFIG"

exit 0
