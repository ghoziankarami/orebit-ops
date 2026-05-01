#!/bin/bash
# PROMOTE REVIEWED NOTES - PARA AUTOMATION
# Promotes reviewed notes to appropriate lanes (Projects, Areas, Resources)

cd /app/working/workspaces/default/orebit-ops
python3 ops/scripts/capture/promote-reviewed-notes.py >> /tmp/promote-notes.log 2>&1
