# SOP - Standard Operating Procedures: Orebit RAG System

## 📋 Document Information

| Field | Value |
|-------|-------|
| **System** | Orebit RAG System (rag.orebit.id) |
| **Document Owner** | Orebit Operations Team |
| **Version** | 1.0 |
| **Last Updated** | 2026-05-02 |
| **Status** | Production |
| **Purpose** | Operations and maintenance procedures |

---

## 🎯 Scope

This SOP covers:
- System architecture and components
- Deployment procedures
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
│ │ Nginx - Reverse Proxy                               │ │
│ │ - SSL Termination (Lets Encrypt)                    │ │
│ │ - Domain: rag.orebit.id                             │ │
│ │ - Landing Page                                       │ │
│ │ - API Endpoints Proxy                                │ │
│ └──────────────────────────────────────────────────────┘ │
└───────────────────┬──────────────────────────────────────┘
                    │
                    │ Proxy Request
                    ▼
┌──────────────────────────────────────────────────────────┐
│ Cloudflare Tunnel                                       │
│ ┌──────────────────────────────────────────────────────┐ │
│ │ - Encrypted Tunneling (HTTP/QUIC)                   │ │
│ │ - URL: *.trycloudflare.com                          │ │
│ │ - Auto-restart enabled                              │ │
│ └──────────────────────────────────────────────────────┘ │
└───────────────────┬──────────────────────────────────────┘
                    │
                    │ Private Connection
                    ▼
┌──────────────────────────────────────────────────────────┐
│ QwenPaw (103.139.244.177) - Backend                     │
│ ┌──────────────────────────────────────────────────────┐ │
│ │ RAG API Wrapper (Port 3004)                         │ │
│ │ - Query Processing                                  │ │
│ │ - 9router LLM Integration                           │ │
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
| **VPS / Nginx** | 43.157.201.50 | Frontend proxy, SSL termination | HIGH |
| **Cloudflare Tunnel** | QwenPaw → Cloudflare | Encrypted transportation | HIGH |
| **QwenPaw API** | 103.139.244.177:3004 | RAG processing | CRITICAL |
| **ChromaDB** | QwenPaw internal | Vector storage | CRITICAL |

---

## 📊 Monitoring Procedures

### Daily Health Checks

#### 1. System Uptime Check
```bash
# On VPS
curl -s https://rag.orebit.id/api/rag/health | python3 -m json.tool
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

#### 2. Process Status Check

**On VPS:**
```bash
sudo systemctl status nginx | grep "Active"
```

**On QwenPaw:**
```bash
ps aux | grep cloudflared | grep -v grep
ps aux | grep "node.*3004" | grep -v grep
```

**Expected:** Both processes running with active status.

#### 3. SSL Certificate Check
```bash
# Check certificate expiry
echo | openssl s_client -servername rag.orebit.id -connect rag.orebit.id:443 2>/dev/null | openssl x509 -noout -dates
```

**Action Required:** Renew if expiry < 30 days.

#### 4. Log File Review

**VPS Nginx Logs:**
```bash
# Error logs
sudo tail -50 /var/log/nginx/error.log | grep -E "error|ERROR|crit|CRIT"

# Access logs (recent requests)
sudo tail -50 /var/log/nginx/access.log
```

**QwenPaw Tunnel Logs:**
```bash
# Cloudflared logs
tail -50 /tmp/cloudflared-tunnel.log

# Wrapper logs
tail -50 /tmp/cloudflared-wrapper.log
```

**Auto-Restart Logs:**
```bash
cat /tmp/cloudflared-restart.log
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

**Troubleshooting Steps:**

1. **Check Nginx Status (VPS)**
   ```bash
   sudo systemctl status nginx
   ```

2. **Check Nginx Error Logs**
   ```bash
   sudo tail -50 /var/log/nginx/error.log
   ```

3. **Check Cloudflare Tunnel (QwenPaw)**
   ```bash
   ps aux | grep cloudflared | grep -v grep
   ```

4. **Test Tunnel Directly**
   ```bash
   curl https://opposite-fountain-corrected-organized.trycloudflare.com/api/rag/health
   ```

5. **If tunnel down:**
   ```bash
   pkill -f "cloudflared"
   sleep 2
   nohup bash /app/working/workspaces/default/orebit-ops/cloudflared-wrapper.sh > /dev/null 2>&1 &
   ps aux | grep cloudflared | grep -v grep
   ```

### Issue: 404 on Root Domain

**Symptoms:**
- https://rag.orebit.id/ returns 404
- API endpoints still work

**Root Cause:** Landing page file missing or Nginx misconfigured.

**Resolution:**

1. **Check Landing Page File**
   ```bash
   ls -la /var/www/rag.orebit.id/index.html
   ```

2. **Check Nginx Configuration**
   ```bash
   grep -A 5 "location = /" /etc/nginx/sites-enabled/rag-orebit-id
   ```

3. **If misconfigured, run:**
   ```bash
   cd /app/working/workspaces/default/orebit-ops
   bash setup-landing-page.sh
   ```

### Issue: API Returns Connection Refused

**Symptoms:**
- curl http://127.0.0.1:3004/api/rag/health fails
- API wrapper not responding

**Resolution:**

1. **Check API Process**
   ```bash
   ps aux | grep "node.*3004" | grep -v grep
   ```

2. **Check API Logs**
   ```bash
   # API logs location - varies by setup
   # Check process output or application logs
   ```

3. **Restart API Wrapper**
   ```bash
   # Locate restart script or process
   # This depends on your specific API setup
   ```

### Issue: Indexed Papers Count Drop

**Symptoms:**
- Health check shows indexed_papers < 351
- Sudden decrease in corpus size

**Possible Causes:**
- ChromaDB corruption
- Vector index rebuild
- Data synchronization issue

**Resolution:**

1. **Check ChromaDB Status**
   ```bash
   # Check ChromaDB process and logs
   ```

2. **Verify Vector Database**
   ```bash
   # Check ChromaDB data directory
   ls -la /path/to/chromadb/
   ```

3. **If data loss suspected:**
   - Check recent changes
   - Review logs for errors
   - Consider data restoration if backup available

### Issue: Slow API Response Time

**Symptoms:**
- API response > 500ms
- Queries take long time to complete

**Resolution:**

1. **Check System Resources**
   ```bash
   # On QwenPaw
   top  # Check CPU, memory usage
   df -h  # Check disk space
   ```

2. **Check ChromaDB Performance**
   ```bash
   # Check vector search performance
   # May need index optimization
   ```

3. **Review Recent Changes**
   - New papers indexed?
   - Large queries?
   - System load increased?

---

## 🚨 Emergency Procedures

### Complete System Outage

**Situation:** Entire system unreachable (rag.orebit.id down)

**Immediate Actions:**

1. **Confirm Outage**
   ```bash
   curl https://rag.orebit.id/api/rag/health
   # Check if returning timeout/connection error
   ```

2. **Check VPS Status**
   - Can SSH to VPS? `ssh ubuntu@43.157.201.50`
   - Check: `sudo systemctl status nginx`

3. **Check QwenPaw Status**
   - Can access QwenPaw?
   - Check: `ps aux | grep cloudflared`
   - Check: `curl http://127.0.0.1:3004/api/rag/health`

4. **Restart Components**
   - If VPS issue: `sudo systemctl restart nginx`
   - If QwenPaw issue: Restart cloudflared tunnel

5. **Verify Recovery**
   ```bash
   curl https://rag.orebit.id/api/rag/health
   # Should return healthy status
   ```

### Data Integrity Concern

**Situation:** Indexed papers count mismatch or data loss

**Actions:**

1. **Stop All Operations**
   - Stop indexing/intake processes
   - Stop write operations to database

2. **Verify Data State**
   - Check ChromaDB integrity
   - Compare with backups (if available)
   - Review logs to identify issue

3. **Restore Data (if needed)**
   - From recent backup
   - Re-index from source documents

4. **Prevent Recurrence**
   - Identify root cause
   - Implement additional safeguards
   - Update procedures

---

## 🔄 Maintenance Procedures

### Regular Maintenance Schedule

#### Daily:
- [ ] Check system health: `curl https://rag.orebit.id/api/rag/health`
- [ ] Review error logs for anomalies
- [ ] Verify auto-restart logs

#### Weekly:
- [ ] Full log review
- [ ] Performance metrics analysis
- [ ] Check SSL certificate expiry
- [ ] Verify system resources (CPU, memory, disk)

#### Monthly:
- [ ] Backup ChromaDB data
- [ ] Review security logs
- [ ] Update system packages
- [ ] Optimize database indices (if needed)
- [ ] Document any incidents

### SSL Certificate Renewal

**Before Expiry (> 30 days):**

```bash
# On VPS
sudo certbot renew
sudo systemctl reload nginx

# Verify
echo | openssl s_client -servername rag.orebit.id -connect rag.orebit.id:443 2>/dev/null | openssl x509 -noout -dates
```

---

## 📝 Change Management

### Change Request Process

1. **Submit Change Request**
   - Document proposed change
   - Identify risk level (LOW/MEDIUM/HIGH/CRITICAL)
   - Estimate impact

2. **Review and Approve**
   - Operations lead reviews
   - Technical validation
   - Risk assessment

3. **Test in Non-Production**
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
## Change Request #001

**Date:** YYYY-MM-DD
**Component:** [Component Name]
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
- Downtime expected/hours: [X]
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
   - QwenPaw IP 103.139.244.177 must remain internal
   - Never open public ports to QwenPaw

2. **Monitor unusual traffic**
   - Review access logs regularly
   - Look for anomaly patterns
   - Implement rate limiting if needed

3. **Keep systems updated**
   - Security patches applied promptly
   - Dependencies kept current
   - SSL certificates renewed before expiry

### Operational Best Practices

1. **Document all changes**
   - Every change should be tracked
   - Use git for configuration changes
   - Maintain accurate logs

2. **Test before deploying**
   - Never deploy untested changes to production
   - Have rollback plan ready
   - Monitor for issues after deployment

3. **Monitor proactively**
   - Don't wait for failures
   - Set up alerting if possible
   - Regular health checks

---

## 📞 Escalation Procedures

### Problem Escalation Matrix

| Severity | Response Time | Notification | Example Issue |
|----------|---------------|--------------|---------------|
| **P1** | < 15 minutes | All hands on deck | Complete system outage |
| **P2** | < 1 hour | Operations team | API unavailable |
| **P3** | < 4 hours | On-call engineer | Performance degradation |
| **P4** | < 24 hours | Operations team | Minor UI issue |
| **P5** | Next sprint | Development team | Feature request |

### Emergency Contacts

**When to Escalate:**
- System down > 15 minutes (P1)
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
- `README.md` - System overview
- `DEPLOYMENT_FINAL_STATUS.txt` - Current deployment status
- `CLOUDFLARED_AUTORESTART_COMPLETE.md` - Auto-restart details
- `ARCHITECTURE_QUICK_REF.md` - Architecture reference

### Historical Documentation
- `CORRECT_ARCHITECTURE_DEPLOYMENT.md` - Architecture decisions
- `SYSTEM_ARCHITECTURE_ANALYSIS.md` - Technical analysis
- `VPS_DEPLOYMENT_GUIDE.md` - VPS deployment details

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
- System architecture overview
- Monitoring procedures
- Troubleshooting common issues
- Emergency response protocols
- Change management process

### Training Materials
- This SOP document
- System walkthroughs
- Troubleshooting scenarios
- Shadow training period

---

## 📋 Appendices

### Appendix A: Quick Reference Commands

```bash
# VPS Commands (43.157.201.50)
curl https://rag.orebit.id/api/rag/health
sudo systemctl status nginx
sudo tail -f /var/log/nginx/error.log

# QwenPaw Commands (103.139.244.177)
ps aux | grep cloudflared | grep -v grep
curl http://127.0.0.1:3004/api/rag/health
crontab -l
tail -f /tmp/cloudflared-wrapper.log
```

### Appendix B: System Status Checklist

```
□ Landing page loads (HTTP 200)
□ Health check returns (indexed_papers: 351)
□ SSL certificate valid
□ TLS 1.2/1.3 enabled
□ API response time < 200ms
□ Tunnel process running
□ API wrapper process running
□ Nginx running on VPS
□ Cron jobs active on QwenPaw
□ No errors in logs
```

---

**End of SOP**

**Document Control:**
- **Owner:** Orebit Operations Team
- **Next Review:** 2026-08-02 (Quarterly)
- **Last Updated:** 2026-05-02

**For issues, questions, or updates, contact the operations team or update via pull request.**
