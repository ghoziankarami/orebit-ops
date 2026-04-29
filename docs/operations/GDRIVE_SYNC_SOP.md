# Google Drive Sync SOP

> **Status:** ✅ OPERATIONAL  
> **Last verified:** 2026-04-29  
> **Author:** QwenPaw Agent (automated)  

---

## Overview

Obsidian vault is synced with Google Drive via **rclone**.  
Two remotes are configured for different access levels:

| Remote | Auth Method | Read | Write | Use Case |
|--------|-------------|------|-------|----------|
| `gdrive-obsidian` | Service Account | ✅ | ❌ | Pull-only operations |
| `gdrive-obsidian-oauth` | OAuth (user credentials) | ✅ | ✅ | Push + Pull operations |

---

## Remote Configuration

### Service Account (Read-Only)
```
[gdrive-obsidian]
type = drive
scope = drive
service_account_file = /root/.config/rclone/service-account.json
root_folder_id = 1a33hipwORSMZh3pKOMvB4PjMQzvvJFGI
```

### OAuth (Read + Write)
```
[gdrive-obsidian-oauth]
type = drive
scope = drive
client_id = <from Google Cloud Console>
client_secret = <from Google Cloud Console>
token = <auto-managed by rclone>
root_folder_id = 1a33hipwORSMZh3pKOMvB4PjMQzvvJFGI
```

---

## Path Reference

> ⚠️ All paths containing spaces must use colons without spaces:  
> ✅ `gdrive-obsidian-oauth:0. Inbox/file.md`  
> ❌ `gdrive-obsidian-oauth:/0. Inbox/file.md` (wrong)

### Common Vault Paths

| Operation | Command |
|-----------|---------|
| List vault folders | `rclone lsd gdrive-obsidian-oauth:` |
| List inbox files | `rclone ls "gdrive-obsidian-oauth:0. Inbox/"` |
| Pull vault | `rclone copy "gdrive-obsidian:" "$LOCAL_VAULT" --verbose` |
| Push inbox | `rclone copy "$LOCAL_VAULT/0. Inbox" "gdrive-obsidian-oauth:0. Inbox" --verbose` |
| Delete file | `rclone delete "gdrive-obsidian-oauth:0. Inbox/filename.md"` |

---

## OAuth Token Lifecycle

### How It Works

1. **Access Token** — Valid for 1 hour, used for API calls
2. **Refresh Token** — Valid for long-term, used to get new access tokens
3. **Auto-Refresh** — rclone automatically refreshes the access token when expired

### Token File Location
```
/root/.config/rclone/rclone.conf
```

Token expiry is stored in the config file. rclone updates it when a new access token is obtained.

---

## ⚠️ KNOWN ISSUES & FIXES

### Issue 1: Token Expired — Write Fails
**Symptom:**
```
Failed to copy: failed to open source object: googleapi: got HTTP response 401
```

**Cause:** Access token expired and rclone failed to refresh automatically.

**Fix:**
```bash
# Force re-authentication
rclone config reconnect gdrive-obsidian-oauth:
# Follow the interactive prompts to re-authenticate
```

### Issue 2: Token Refresh Failed — Invalid Credentials
**Symptom:**
```
Error: invalid_client
The OAuth client was not found.
```

**Cause:** OAuth client_id/client_secret changed or credentials are invalid.

**Fix:** Reconfigure OAuth in Google Cloud Console:
1. Go to Google Cloud Console → APIs & Services → Credentials
2. Check OAuth 2.0 Client ID
3. Update rclone.conf with new client_id and client_secret
4. Run `rclone config reconnect gdrive-obsidian-oauth:`

### Issue 3: Service Account Quota Exceeded
**Symptom:**
```
User rate limit exceeded
```

**Cause:** Google Drive API quota exceeded for service account.

**Fix:** Use OAuth remote instead for write operations.

---

## AUTOMATED WATCHDOG

### Token Watchdog (No LLM)
Runs every 30 minutes via OS crontab:

```bash
*/30 * * * * /app/working/workspaces/default/orebit-ops/ops/scripts/sync/rclone-token-watchdog.sh >> /tmp/rclone-token-watchdog.log 2>&1
```

**What it does:**
1. Reads current token expiry from rclone.conf
2. Triggers a lightweight rclone operation to keep token active
3. Tests write capability
4. Logs all results to `/tmp/rclone-token-watchdog.log`

**Monitor watchdog:**
```bash
tail -f /tmp/rclone-token-watchdog.log
```

---

## Manual Troubleshooting

### Check Token Status
```bash
# View current token expiry
grep expiry /root/.config/rclone/rclone.conf

# Test both remotes
rclone about gdrive-obsidian:
rclone about gdrive-obsidian-oauth:
```

### Test Write Capability
```bash
echo "test $(date)" > /tmp/test.txt
rclone copy /tmp/test.txt "gdrive-obsidian-oauth:0. Inbox/.test.txt"
rclone delete "gdrive-obsidian-oauth:0. Inbox/.test.txt"
rm /tmp/test.txt
echo "✅ Write OK"
```

### Full Vault Pull
```bash
cd /app/working/workspaces/default/orebit-ops
bash ops/scripts/sync/pull-vault-from-drive.sh
```

### Full Vault Push (Inbox Only)
```bash
cd /app/working/workspaces/default/orebit-ops
bash ops/scripts/sync/sync-inbox-push.sh
```

---

## Cron Jobs for Google Drive Sync

| Job | Schedule | Action | LLM? |
|-----|----------|--------|------|
| rclone-token-watchdog | Every 30 min | Keep OAuth token alive | ❌ No |
| pull-vault-from-drive | Every 6 hours | Pull vault from Drive | ❌ No |
| sync-inbox-push | Every 6 hours | Push inbox changes to Drive | ❌ No |

---

## Vault Location

| Location | Path |
|----------|------|
| Local vault | `/app/working/workspaces/default/obsidian-system/vault` |
| Google Drive root | `gdrive-obsidian-oauth:/` |

---

## Emergency Recovery

If Google Drive sync is completely broken:

### Step 1: Check rclone config
```bash
cat /root/.config/rclone/rclone.conf
```

### Step 2: Check watchdog logs
```bash
tail -50 /tmp/rclone-token-watchdog.log
```

### Step 3: Re-authenticate OAuth
```bash
rclone config reconnect gdrive-obsidian-oauth:
```

### Step 4: Test after re-auth
```bash
rclone about gdrive-obsidian-oauth:
```

---

## Quick Reference

```bash
# One-liner health check
rclone about gdrive-obsidian-oauth: && echo "✅ OAuth OK" || echo "❌ OAuth FAILED"

# Emergency token refresh
rclone config reconnect gdrive-obsidian-oauth:

# Full sync pull
cd /app/working/workspaces/default/orebit-ops && bash ops/scripts/sync/pull-vault-from-drive.sh

# Full sync push (inbox only)
cd /app/working/workspaces/default/orebit-ops && bash ops/scripts/sync/sync-inbox-push.sh
```

---

**Maintained by:** QwenPaw Agent  
**Last updated:** 2026-04-29
