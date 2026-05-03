# SOP - Standard Operating Procedures: Orebit RAG System

## 📋 Document Information

| Field | Value |
|-------|-------|
| **System** | Orebit RAG System (rag.orebit.id, api.orebit.id) |
| **Document Owner** | Orebit Operations Team |
| **Version** | 2.0 |
| **Last Updated** | 2026-05-03 |
| **Status** | Production |
| **Purpose** | Operations and maintenance procedures |

---

## 🎯 Scope

This SOP covers:
- System architecture and components (Full Stack React UI + API)
- Deployment procedures (VPS-only, no Vercel)
- Monitoring and health checks
- Troubleshooting procedures
- Emergency response protocols
- Maintenance windows
- Change management

---

## 🏗️ System Architecture Overview

### Component Map

```
┌──────────────────────────────────────────────────────────┐
│                    PUBLIC INTERNET                       │
└───────────────────┬──────────────────────────────────────┘
                    │
                    │ HTTPS (SSL/TLS)
                    ▼
┌──────────────────────────────────────────────────────────┐
│ VPS (43.157.201.50) - Frontend                          │
│ ┌──────────────────────────────────────────────────────┐ │
│ │ Nginx - Reverse Proxy + Static File Server          │ │
│ │ - SSL Termination (Let's Encrypt)                   │ │
│ │ - Domain 1: rag.orebit.id (React UI + API)          │ │
│ │ - Domain 2: api.orebit.id (API only)               │ │
│ │ - Location /: React UI files                        │ │
│ │ - Location /api/rag/*: Proxy to Cloudflare          │ │
│ └──────────────────────────────────────────────────────┘ │
└───────────────────┬──────────────────────────────────────┘
                    │
                    │ Proxy Request (API only)
                    ▼
┌──────────────────────────────────────────────────────────┐
│ Cloudflare Tunnel                                       │
│ ┌──────────────────────────────────────────────────────┐ │
│ │ - Encrypted Tunneling (HTTP/QUIC)                   │ │
│ │ - URL: venture-stud-gale-fuji.trycloudflare.com    │ │
│ │ - Target: http://127.0.0.1:3004                    │ │
│ │ - Auto-restart enabled                              │ │
│ └──────────────────────────────────────────────────────┘ │
└───────────────────┬──────────────────────────────────────┘
                    │
                    │ Private Connection
                    ▼
┌──────────────────────────────────────────────────────────┐
│ QwenPaw (Private IP) - Backend                          │
│ ┌──────────────────────────────────────────────────────┐ │
│ │ RAG API Wrapper (Node.js, Port 3004, 0.0.0.0)       │ │
│ │ - Query Processing                                  │ │
│ │ - API Key Authentication                            │ │
│ │ - Vector Search                                     │ │
│ └──────────────────────────────────────────────────────┘ │
│ ┌──────────────────────────────────────────────────────┐ │
│ │ ChromaDB Vector Database                            │ │
│ │ - 351 Indexed Papers                               │ │
│ │ - 343 Summaries                                    │ │
│ │ - 93 Collections                                   │ │
│ └──────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────┘
```

### Component Details

| Component | Location | Role | Criticality |
|-----------|----------|------|---------------|
| **VPS / Nginx** | 43.157.201.50 | React UI + Proxy + SSL | HIGH |
| **Cloudflare Tunnel** | QwenPaw → Cloudflare | Encrypted transportation | HIGH |
| **QwenPaw API** | Private:3004 | RAG processing | CRITICAL |
| **ChromaDB** | QwenPaw internal | Vector storage | CRITICAL |

---

## 📊 Monitoring Procedures

### Daily Health Checks

#### 1. System Uptime Check (Public)

On any machine:
```bash
# Check API via api.orebit.id
curl -s https://api.orebit.id/api/rag/health | python3 -m json.tool
```

**Expected Output:**
```json
{
  "status": "healthy",
  "corpus": {
    "indexed_papers": 351,
    "summary_count": 343,
    "collection_count": 93
  }
}
```

**Alert Thresholds:**
- ❌ Status != "healthy"
- ❌ indexed_papers < 350
- ❌ HTTP response != 200

#### 2. UI Health Check

```bash
# Check React UI loads
curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" https://rag.orebit.id/
```

**Expected:** HTTP Status: 200

#### 3. Process Status Check

**On VPS:**
```bash
sudo systemctl status nginx | grep "Active"
curl https://api.orebit.id/api/rag/health
```

**On QwenPaw:**
```bash
# Check API wrapper
ps aux | grep "node.*index.js" | grep -v grep

# Check Cloudflare tunnel
ps aux | grep cloudflared | grep -v grep

# Check local API
curl http://127.0.0.1:3004/api/rag/health
```

**Expected:** All processes running with healthy status.

#### 4. SSL Certificate Check
```bash
# Check certificate expiry for both domains
echo | openssl s_client -servername rag.orebit.id -connect rag.orebit.id:443 2>/dev/null | openssl x509 -noout -dates
echo | openssl s_client -servername api.orebit.id -connect api.orebit.id:443 2>/dev/null | openssl x509 -noout -dates
```

**Action Required:** Renew if expiry < 30 days.

#### 5. Log File Review

**VPS Nginx Logs:**
```bash
# Error logs
sudo tail -50 /var/log/nginx/rag-orebit-id-error.log

# Access logs (recent requests)
sudo tail -50 /var/log/nginx/rag-orebit-id-access.log
```

**QwenPaw Logs:**
```bash
# Cloudflared logs
tail -f /tmp/cloudflared-tunnel-*.log

# API wrapper logs
tail -f /tmp/rag-api-wrapper.log
```

### Automated Monitoring

**Cron Jobs on QwenPaw:**
```bash
# View all cron jobs
crontab -l
```

**Key Cron Job (Health Check):**
```bash
*/5 * * * * /app/working/workspaces/default/orebit-ops/check-cloudflared.sh > /dev/null 2>&1
```

**Purpose:** Check cloudflared, wrapper, and API health every 5 minutes.

---

## 🔧 Troubleshooting Procedures

### Issue: 502 Bad Gateway

**Symptoms:**
- Browser shows 502 Bad Gateway
- curl returns 502 status
- UI loads but API calls fail

**Troubleshooting Steps:**

1. **Check Nginx Status (VPS)**
   ```bash
   sudo systemctl status nginx
   curl https://rag.orebit.id/  # Should work (UI)
   curl https://api.orebit.id/api/rag/health  # Should fail with 502
   ```

2. **Check Nginx Error Logs (VPS)**
   ```bash
   sudo tail -50 /var/log/nginx/rag-orebit-id-error.log
   ```

3. **Check Cloudflare Tunnel (QwenPaw)**
   ```bash
   ps aux | grep cloudflared | grep -v grep
   ```

4. **Test Tunnel Directly**
   ```bash
   curl https://venture-stud-gale-fuji.trycloudflare.com/api/rag/health
   ```

5. **If tunnel down:**
   ```bash
   # On QwenPaw
   pkill -f cloudflared
   sleep 2
   nohup cloudflared tunnel --url http://127.0.0.1:3004 > /tmp/cloudflared-tunnel-$(date +%Y%m%d-%H%M%S).log 2>&1 &

   # Get new tunnel URL
   tail -50 /tmp/cloudflared-tunnel-*.log | grep -oP 'https://[^ ]+\.trycloudflare\.com' | tail -1

   # Update VPS Nginx with new URL
   # See vps-update-tunnel-url.sh script
   ```

6. **If API wrapper down:**
   ```bash
   # On QwenPaw
   cd /app/working/workspaces/default/orebit-ops/rag-system/api-wrapper
   bash start-wrapper.sh

   # Verify
   curl http://127.0.0.1:3004/api/rag/health
   ```

### Issue: 404 on UI

**Symptoms:**
- https://rag.orebit.id/ returns 404 or shows blank page
- API endpoints still work

**Root Cause:** UI files missing or Nginx misconfigured.

**Resolution:**

1. **Check UI Files**
   ```bash
   # On VPS
   ls -la /var/www/rag-ui/index.html
   ```

2. **Check Nginx Configuration**
   ```bash
   # On VPS
   grep -A 5 "location / {" /etc/nginx/sites-enabled/rag-orebit-id
   ```

3. **If misconfigured, redeploy UI:**
   ```bash
   # Clone or pull latest from GitHub
   cd /root
   git clone https://github.com/ghoziankarami/orebit-ops.git /root/orebit-ops

   # Deploy UI
   bash /root/orebit-ops/vps-deploy-rag.sh
   ```

### Issue: API Returns 401 Unauthorized

**Symptoms:**
- curl returns 401 status
- API endpoints not responding

**Root Cause:** API key missing or incorrect.

**Resolution:**

1. **Check API Request Headers**
   ```bash
   # Should include: x-api-key: orebit-rag-api-key-2026-03-26-temp
   curl -H "x-api-key: orebit-rag-api-key-2026-03-26-temp" \
     https://api.orebit.id/api/rag/stats
   ```

2. **Check API Wrapper Config (QwenPaw)**
   ```bash
   cat /app/working/workspaces/default/orebit-ops/rag-system/api-wrapper/.env
   ```
   Should contain: `RAG_API_KEY=orebit-rag-api-key-2026-03-26-temp`

3. **Note:** Health endpoint (`/api/rag/health`) doesn't require API key.

### Issue: Tunnel URL Changed (NXDOMAIN)

**Symptoms:**
- API returns 502 Bad Gateway
- Nginx shows "cannot resolve host" errors
- Previous tunnel URL not responding

**Root Cause:** Cloudflare quick tunnel URLs change on restart.

**Resolution:**

1. **Identify Old URL in Nginx Config**
   ```bash
   # On VPS
   grep "trycloudflare.com" /etc/nginx/sites-enabled/rag-orebit-id
   ```

2. **Get New Tunnel URL (QwenPaw)**
   ```bash
   tail -50 /tmp/cloudflared-tunnel-*.log | grep -oP 'https://[^ ]+\.trycloudflare\.com' | tail -1
   ```

3. **Update VPS Nginx**
   ```bash
   # On VPS
   # Option 1: Use update script
   bash /app/working/workspaces/default/orebit-ops/vps-update-tunnel-url.sh

   # Option 2: Manual update
   sudo sed -i 's|OLD_URL|NEW_URL|g' /etc/nginx/sites-enabled/rag-orebit-id
   sudo nginx -t
   sudo systemctl reload nginx
   ```

4. **For Permanent URL, Create Named Tunnel**
   ```bash
   # On QwenPaw
   cloudflared tunnel login
   cloudflared tunnel create qwenpaw-rag
   # This will provide a stable URL
   ```

---

## 🚨 Emergency Procedures

### Complete System Outage

**Situation:** Entire system unreachable (rag.orebit.id down)

**Immediate Actions:**

1. **Confirm Outage Scope**
   ```bash
   # Test from external machine
   curl https://rag.orebit.id/api/rag/health
   ```

2. **Check VPS Status**
   ```bash
   # Can SSH to VPS?
   ssh root@43.157.201.50

   # Check Nginx
   sudo systemctl status nginx
   ```

3. **Check QwenPaw Status**
   ```bash
   # From QwenPaw
   ps aux | grep cloudflared
   ps aux | grep "node.*3004"
   curl http://127.0.0.1:3004/api/rag/health
   ```

4. **Restart Components as Needed**
   - **VPS:** `sudo systemctl restart nginx`
   - **QwenPaw Tunnel:** `pkill -f cloudflared && start tunnel`
   - **QwenPaw API:** Restart wrapper script

5. **Verify Recovery**
   ```bash
   # From any machine
   curl https://api.orebit.id/api/rag/health
   open https://rag.orebit.id
   ```

### UI Works, API Fails

**Situation:** React UI loads but API calls return errors

**Diagnosis:**
- UI: https://rag.orebit.id → OK
- API: https://api.orebit.id/api/rag/health → FAIL

**Possible Causes:**
1. Cloudflare tunnel down → Check QwenPaw tunnel
2. API wrapper stopped → Check QwenPaw API process
3. Tunnel URL changed → Update VPS Nginx config

**Resolution:** Follow troubleshooting steps in Issue: 502 Bad Gateway.

---

## 🔄 Maintenance Procedures

### Regular Maintenance Schedule

#### Daily:
- [ ] Check system health: `curl https://api.orebit.id/api/rag/health`
- [ ] Verify UI loads: `curl https://rag.orebit.id/`
- [ ] Review error logs for anomalies
- [ ] Check tunnel process status

#### Weekly:
- [ ] Full log review (Nginx + cloudflared)
- [ ] Performance metrics analysis
- [ ] Check SSL certificate expiry (both domains)
- [ ] Verify system resources (CPU, memory, disk)

#### Monthly:
- [ ] Update system packages (VPS + QwenPaw)
- [ ] Review security logs
- [ ] Check ChromaDB data integrity
- [ ] Document any incidents or changes

### SSL Certificate Renewal

**Before Expiry (> 30 days):**

```bash
# On VPS
sudo certbot renew

# Check status
sudo certbot certificates

# Reload Nginx
sudo systemctl reload nginx

# Verify
echo | openssl s_client -servername rag.orebit.id -connect rag.orebit.id:443 2>/dev/null | openssl x509 -noout -dates
echo | openssl s_client -servername api.orebit.id -connect api.orebit.id:443 2>/dev/null | openssl x509 -noout -dates
```

---

## 📝 Change Management

### Change Request Process

1. **Submit Change Request**
   - Document proposed change
   - Identify risk level (LOW/MEDIUM/HIGH/CRITICAL)
   - Estimate impact and downtime

2. **Review and Approve**
   - Operations lead reviews
   - Technical validation
   - Risk assessment

3. **Test in Non-Production** (if available)
   - Apply change to test environment
   - Verify system functionality
   - Rollback plan if test fails

4. **Schedule Maintenance Window**
   - Choose low-traffic period
   - Notify stakeholders
   - Document expected downtime

5. **Implement Change**
   - Execute change plan
   - Monitor system during/after
   - Document results

### Example Change Record Format:

```markdown
## Change Request #YYYY-MM-DD-###

**Date:** YYYY-MM-DD
**Component:** [VPS/Nginx/QwenPaw/Tunnel/UI/API]
**Risk Level:** [LOW/MEDIUM/HIGH/CRITICAL]
**Requested By:** [Name]

**Description:**
[Brief description of change]

**Justification:**
[Why change is needed]

**Implementation Plan:**
[Step-by-step implementation]

**Rollback Plan:**
[How to revert if needed]

**Impact Assessment:**
- Downtime expected: [X minutes/hours]
- Affected components: [UI/API/Both]
- Affected users: [All/Specific group]
- Risk mitigation: [List]

**Testing:**
[Test results]

**Approval:** [Name, Date]
**Status:** [APPROVED/REJECTED/PENDING]
```

---

## 🎯 Best Practices

### Security Best Practices

1. **Never expose internal IP**
   - QwenPaw must remain private (no public IP)
   - Never open public ports to QwenPaw
   - Only expose via Cloudflare tunnel

2. **Monitor unusual traffic**
   - Review access logs regularly
   - Look for anomaly patterns
   - Implement rate limiting if needed
   - Monitor API key usage

3. **Keep systems updated**
   - Security patches applied promptly
   - Dependencies kept current
   - SSL certificates renewed before expiry
   - Cloudflared updated regularly

### Operational Best Practices

1. **Document all changes**
   - Every change tracked in git
   - Commit messages descriptive
   - Rollback plans documented

2. **Test before deploying**
   - Never deploy untested changes
   - Verify API endpoints work
   - Check UI functionality
   - Have rollback plan ready

3. **Monitor proactively**
   - Don't wait for failures
   - Set up alerting if possible
   - Regular health checks
   - Review logs daily

4. **Tunnel URL Management**
   - Quick tunnel URLs can change
   - Update VPS Nginx when URL changes
   - Consider named tunnel for stability
   - Keep both old and new URL for gradual transition

---

## 📞 Escalation Procedures

### Problem Escalation Matrix

| Severity | Response Time | Notification | Example Issue |
|----------|---------------|--------------|---------------|
| **P1** | < 15 minutes | All hands on deck | Complete system outage |
| **P2** | < 1 hour | Operations team | API unavailable (502/503) |
| **P3** | < 4 hours | On-call engineer | UI issues, slow performance |
| **P4** | < 24 hours | Operations team | Minor configuration issue |
| **P5** | Next sprint | Development team | Feature request or enhancement |

### Emergency Contacts

**When to Escalate:**
- System down > 15 minutes (P1)
- API unavailable > 1 hour (P2)
- Tunnel URL change causes outage (P2)
- Data integrity concern
- Security breach suspected
- Unrecoverable error

**Escalation Path:**
1. On-call operator
2. Operations lead
3. System architect
4. Management

---

## 📚 Related Documents

### Critical Documentation
- **README.md** - System overview and canonical documentation
- **DEPLOYMENT.md** - Deployment procedures
- **vps-deploy-rag.sh** - VPS deployment script
- **vps-update-tunnel-url.sh** - Tunnel URL update script

### Reference Documentation
- **VERCEL_VS_VPS_DECISION.md** - Why VPS deployment was chosen
- **ARCHITECTURE_QUICK_REF.md** - Architecture quick reference
- **NEW_TUNNEL_URL_ACTIVE.md** - Current tunnel URL information

### GitHub Repository
- https://github.com/ghoziankarami/orebit-ops
- Main branch contains latest documentation

---

## ✅ SOP Maintenance

### SOP Review Schedule
- Quarterly review for accuracy
- Annual comprehensive update
- Update after major incidents
- Update after significant changes

### SOP Version Control
- Maintain in git repository
- Use semantic versioning
- Document all changes
- Notify team of updates

---

## 🎓 Training Requirements

### Required Training
- Full stack architecture overview (VPS + QwenPaw + React UI)
- Monitoring procedures for UI and API
- Troubleshooting common issues (tunnel, API, UI)
- Emergency response protocols
- Change management process
- Tunnel URL update procedures

### Training Materials
- This SOP document
- System walkthroughs
- Troubleshooting scenarios
- Shadow training period

---

## 📋 Appendices

### Appendix A: Quick Reference Commands

```bash
# Public Commands (from any machine)
curl https://api.orebit.id/api/rag/health
open https://rag.orebit.id

# VPS Commands (43.157.201.50)
ssh root@43.157.201.50
sudo systemctl status nginx
sudo tail -f /var/log/nginx/rag-orebit-id-error.log
curl https://api.orebit.id/api/rag/health

# QwenPaw Commands (private IP only)
ps aux | grep cloudflared | grep -v grep
ps aux | grep "node.*3004" | grep -v grep
curl http://127.0.0.1:3004/api/rag/health
tail -f /tmp/cloudflared-tunnel-*.log

# Deployment Commands
# On VPS:
git clone https://github.com/ghoziankarami/orebit-ops.git /root/orebit-ops
bash /root/orebit-ops/vps-deploy-rag.sh
bash /root/orebit-ops/vps-update-tunnel-url.sh NEW_URL
```

### Appendix B: System Status Checklist

```
□ React UI loads (https://rag.orebit.id) - HTTP 200
□ API health check returns (indexed_papers: 351)
□ API stats endpoint works (needs API key)
□ SSL certificates valid (both domains)
□ TLS 1.2/1.3 enabled
□ API response time < 200ms
□ Tunnel process running on QwenPaw
□ API wrapper process running on QwenPaw (port 3004)
□ Nginx running on VPS
□ UI files present in /var/www/rag-ui
□ No errors in Nginx logs
□ No errors in cloudflared logs
□ Tunnel URL matches current active URL
```

### Appendix C: Tunnel URL Update Procedure

When Cloudflare tunnel URL changes:

1. **Get New Tunnel URL (QwenPaw)**
   ```bash
   tail -50 /tmp/cloudflared-tunnel-*.log | grep -oP 'https://[^ ]+\.trycloudflare\.com' | tail -1
   ```

2. **Update VPS Nginx**
   ```bash
   # Option 1: Automated
   bash /root/orebit-ops/vps-update-tunnel-url.sh

   # Option 2: Manual
   sudo nano /etc/nginx/sites-enabled/rag-orebit-id
   # Replace old URL with new URL in proxy_pass and Host header
   sudo nginx -t
   sudo systemctl reload nginx
   ```

3. **Verify**
   ```bash
   curl https://api.orebit.id/api/rag/health
   ```

**Current Active Tunnel URL:** `venture-stud-gale-fuji.trycloudflare.com`

---

**End of SOP**

**Document Control:**
- **Owner:** Orebit Operations Team
- **Next Review:** 2026-08-03 (Quarterly)
- **Last Updated:** 2026-05-03

**For issues, questions, or updates, contact the operations team or update via pull request.**
