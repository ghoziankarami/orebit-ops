#!/bin/bash
# Orebit Chat Review Stager - NO LLM
cd /app/working/workspaces/default/orebit-ops && python3 ops/scripts/capture/review-chat-candidates.py >> /tmp/chat-review-stager.log 2>&1
