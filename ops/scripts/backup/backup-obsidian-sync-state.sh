#!/bin/bash
set -euo pipefail

BACKUP_ROOT="/app/working/workspaces/default/backups/obsidian-sync"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
DEST="${BACKUP_ROOT}/${TS}"
LATEST="${BACKUP_ROOT}/latest"
LOCAL_VAULT="/app/working/workspaces/default/obsidian-system/vault"
LOCAL_INBOX="${LOCAL_VAULT}/0. Inbox"
RCLONE_CONF="/root/.config/rclone/rclone.conf"
LOG="${BACKUP_ROOT}/backup.log"

mkdir -p "$DEST"

log() {
  echo "[$(date -Iseconds)] $*" | tee -a "$LOG"
}

sanitize_rclone_conf() {
  python3 - <<'PY' "$RCLONE_CONF" "$DEST/rclone.conf.sanitized"
import re, sys
src, dst = sys.argv[1], sys.argv[2]
text = open(src, 'r', encoding='utf-8').read()
text = re.sub(r'^(client_secret\s*=\s*).*$','\\1REDACTED', text, flags=re.M)
text = re.sub(r'^(service_account_file\s*=\s*).*$','\\1/root/.config/rclone/service-account.json', text, flags=re.M)
text = re.sub(r'^(token\s*=\s*).*$','\\1REDACTED_JSON_TOKEN', text, flags=re.M)
open(dst, 'w', encoding='utf-8').write(text)
PY
}

write_metadata() {
  {
    echo "timestamp_utc=$TS"
    echo "hostname=$(hostname)"
    echo "vault_path=$LOCAL_VAULT"
    echo "read_remote=gdrive-obsidian"
    echo "write_remote=gdrive-obsidian-oauth"
    echo "root_folder_id=1a33hipwORSMZh3pKOMvB4PjMQzvvJFGI"
    echo "repo=/app/working/workspaces/default/orebit-ops"
  } > "$DEST/backup-meta.env"
}

write_runtime_checks() {
  rclone listremotes > "$DEST/rclone-listremotes.txt" 2>&1 || true
  rclone lsd gdrive-obsidian: > "$DEST/rclone-read-lsd.txt" 2>&1 || true
  rclone lsd gdrive-obsidian-oauth: > "$DEST/rclone-write-lsd.txt" 2>&1 || true
  bash /app/working/workspaces/default/orebit-ops/ops/scripts/sync/status-obsidian-inbox-autosync.sh > "$DEST/autosync-status.txt" 2>&1 || true
  qwenpaw cron list --agent-id default > "$DEST/qwenpaw-cron-list.json" 2>&1 || true
}

archive_local_inbox() {
  tar -czf "$DEST/local-inbox.tgz" -C "$LOCAL_VAULT" "0. Inbox"
}

rotate_latest() {
  rm -f "$LATEST"
  ln -s "$DEST" "$LATEST"
}

prune_old() {
  find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d | sort | head -n -14 | xargs -r rm -rf
}

log "Starting Obsidian sync backup into $DEST"
write_metadata
sanitize_rclone_conf
write_runtime_checks
archive_local_inbox
rotate_latest
prune_old
log "Backup complete: $DEST"
