#!/bin/bash
# Setup rclone with Google Drive Service Account
# Usage: Place service-account.json in /root/.config/rclone/ first

set -euo pipefail

SA_FILE="/root/.config/rclone/service-account.json"
CONFIG_FILE="/root/.config/rclone/rclone.conf"

if [ ! -f "$SA_FILE" ]; then
    echo "❌ Service account JSON not found at $SA_FILE"
    echo ""
    echo "=== Setup Instructions ==="
    echo "1. Open https://console.cloud.google.com/ in your Windows browser"
    echo "2. Create a new project (or use existing)"
    echo "3. Go to APIs & Services → Library → Search 'Google Drive API' → Enable"
    echo "4. Go to IAM & Admin → Service Accounts → Create"
    echo "5. Name: rclone-obsidian → Role: Editor (or Viewer for read-only)"
    echo "6. Create Key → JSON → Download"
    echo "7. Share your 'Obsidian' folder in Google Drive to the service account email"
    echo "8. Upload the JSON file to this container as: $SA_FILE"
    echo ""
    echo "Then run this script again."
    exit 1
fi

# Validate JSON
if ! python3 -c "import json; json.load(open('$SA_FILE'))" 2>/dev/null; then
    echo "❌ Invalid JSON file"
    exit 1
fi

# Create rclone config
mkdir -p "$(dirname "$CONFIG_FILE")"

cat > "$CONFIG_FILE" << EOF
[gdrive-obsidian]
type = drive
scope = drive
service_account_file = $SA_FILE
EOF

echo "✅ rclone config created at $CONFIG_FILE"
echo ""

# Test connection
echo "Testing connection to Google Drive..."
if rclone lsd gdrive-obsidian: 2>&1 | head -5; then
    echo ""
    echo "✅ Connection successful!"
    echo ""
    echo "=== Available commands ==="
    echo "List files:        rclone ls gdrive-obsidian:"
    echo "List folders:      rclone lsd gdrive-obsidian:"
    echo "Sync inbox:        rclone sync gdrive-obsidian:/Obsidian/0.\ Inbox /app/working/workspaces/default/obsidian-system/vault/0.\ Inbox"
    echo "Push inbox:        rclone sync /app/working/workspaces/default/obsidian-system/vault/0.\ Inbox gdrive-obsidian:/Obsidian/0.\ Inbox"
else
    echo ""
    echo "❌ Connection failed. Make sure:"
    echo "   - Google Drive API is enabled"
    echo "   - The 'Obsidian' folder is shared to the service account email"
    exit 1
fi
