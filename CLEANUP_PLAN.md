# RAG SYSTEM CLEANUP AND ARCHIVAL PLAN

## 📋 OBJECTIVE

Clean up obsolete files and references to old configurations from the RAG system project.

---

## 🗂️ CANONICAL DOCUMENTATION (Keep Up-to-Date)

### Must Maintain (Primary Docs)
| File | Status | Purpose |
|------|--------|---------|
| **README.md** | ✅ Keep | System overview and primary documentation |
| **SOP.md** | ✅ Keep | Standard Operating Procedures (v2.0) |
| **PRODUCTION_DEPLOYMENT_STATUS.md** | ✅ Keep | Current production deployment status |
| **AGENTS.md** | ✅ Keep | Multi-agent system documentation |

---

## 🔧 ACTIVE SCRIPTS (Keep and Maintain)

### Currently Used
| File | Status | Purpose |
|------|--------|---------|
| **check-cloudflared.sh** | ✅ Keep | Cron job: Check Cloudflare tunnel health (*/5 * * * *) |
| **cloudflared-wrapper.sh** | ✅ Keep | Auto-restart wrapper for cloudflared |
| **vps-deploy-rag.sh** | ✅ Keep | VPS-side full RAG deployment script |
| **vps-update-tunnel-url.sh** | ✅ Keep | VPS-side tunnel URL update script |

---

## 🗃️ FILES TO ARCHIVE (Move to docs/archived/)

### Documentation Files (Obsolete or Superseded)

| File | Destination | Reason |
|------|-------------|--------|
| `DEPLOYMENT.md` | docs/archived/ | References old tunnel URL |
| `SOLUTION_WORKING.md` | docs/archived/ | Old solution attempt, superseded |
| `CHECK_AND_FIX_VPS.md` | docs/archived/ | Old fix attempt |
| `UI_SOLUTION_OPTIONS.md` | docs/archived/ | Old UI options analysis |
| `NEW_TUNNEL_URL_ACTIVE.md` | docs/archived/ | Superseded by PRODUCTION_DEPLOYMENT_STATUS.md |
| `TUNNEL_DOWN_EMERGENCY_FIX.md` | docs/archived/ | Emergency fix (historical) |
| `DEPLOY_ACTION_REQUIRED.md` | docs/archived/ | User action completed |
| `UI_DISCOVERY_ANALYSIS.md` | docs/archived/ | Analysis complete, documented |
| `LANDING_PAGE_FIX.md` | docs/archived/ | Landing page issue resolved |
| `VERCEL_VS_VPS_DECISION.md` | docs/archived/ | Decision made (VPS chosen) |
| `VPS_DEPLOY_QUICKSTART.md` | docs/archived/ | Superseded by vps-deploy-rag.sh |
| `VPS_SYNC_COMPLETE.md` | docs/archived/ | Old sync approach |
| `RAG_DEPLOYMENT_COMPLETE_GUIDE.md` | docs/archived/ | Old deployment guide (Vercel) |
| `DEPLOY_ACTION_REQUIRED.md` | docs/archived/ | Deployment completed |
| `DEPLOYMENT_READY.txt` | docs/archived/ | Deployment completed |
| `DEPLOYMENT_COMPLETE_NEXT_STEPS.md` | docs/archived/ | Future plans |
| `DEPLOYMENT_FINAL_STATUS.txt` | docs/archived/ | Old status |
| `DEPLOYMENT_FINAL_SUMMARY.txt` | docs/archived/ | Old status |
| `DEPLOYMENT_SSH_TUNNEL_INSTRUCTIONS.md` | docs/archived/ | SSH tunnel not used |
| `README_SSH_TUNNEL.md` | docs/archived/ | SSH tunnel not used |
| `FINAL_DEPLOYMENT_INSTRUCTIONS.md` | docs/archived/ | Old instructions |
| `NETWORK_ANALYSIS.md` | docs/archived/ | Old analysis |
| `TROUBLESHOOTING_DIRECT_CONNECTION.md` | docs/archived/ | Old troubleshooting |
| `STEP2_COMPLETE.md` | docs/archived/ | Old milestone |
| `CORRECT_ARCHITECTURE_DEPLOYMENT.md` | docs/archived/ | Old architecture |
| `ARCHITECTURE_QUICK_REF.md` | docs/archived/ | Old reference |
| `ARCHITECTURE_SUMMARY.txt` | docs/archived/ | Old summary |
| `SYSTEM_ARCHITECTURE_ANALYSIS.md` | docs/archived/ | Old analysis |
| `DOCUMENTATION_SUMMARY.md` | docs/archived/ | Old summary |
| `CLOUDFLARED_AUTORESTART_COMPLETE.md` | docs/archived/ | Historical |
| `QWENPAW_WORKSPACE_BRIDGE.md` | docs/archived/ | Historical |

### Reference/Analysis Files (Keep as Reference)
| File | Destination | Reason |
|------|-------------|--------|
| `emergency-tunnel-fix.sh` | docs/archived/scripts/ | Historical fix attempt |
| `VERCEL_VPS_DECISION.md` | docs/archived/ | Decision document |
| `docs/operations/RAG_RAILWAY_DEPLOYMENT.md` | docs/archived/ | Railway not used |

---

## 📁 OBSOLETE SCRIPTS TO ARCHIVE

### Deployment Scripts (Superseded)
| File | Destination | Reason |
|------|-------------|--------|
| `deploy-vps-frontend.sh` | docs/archived/scripts/ | Old landing page deployment |
| `deploy-vps-rag-api.sh` | docs/archived/scripts/ | API-only deployment |
| `deploy-rag-ui-to-vps.sh` | docs/archived/scripts/ | Superseded by vps-deploy-rag.sh |
| `deploy-full-rag-to-vps.sh` | docs/archived/scripts/ | SSH-based variant, not used |
| `vps-ssh-tunnel-setup.sh` | docs/archived/scripts/ | SSH tunnel not used |
| `setup-landing-page.sh` | docs/archived/scripts/ | Landing page setup (obsolete) |
| `update-landing-page.sh` | docs/archived/scripts/ | Landing page update (obsolete) |
| `setup-cloudflared-tunnel.sh` | docs/archived/scripts/ | Old tunnel setup |

---

## 🔧 FILES TO UPDATE (Fix Old References)

### Files with Old Tunnel URLs

| File | Old URL | New URL | Action |
|------|---------|---------|--------|
| `DEPLOYMENT.md` | opposite-fountain-... | venture-stud-gale-fuji... | Archive |
| Multiple files | reader-measuring-romance-rarely... | venture-stud-gale-fuji... | Archive |

---

## 🤔 NEW CRON JOBS NEEDED?

### Current Cron Jobs (All Functional)
```bash
*/10 * * * * rclone-token-watchdog-t3.sh          # Sync monitoring
*/15 * * * * heartbeat.sh                         # System health
*/6 * * * * chat-review-stager.sh                # Content curation
*/6 * * * * promote-reviewed-notes.sh            # Content promotion
*/6 * * * * obsidian-sync-backup.sh              # Vault backup
*/6 * * * * runtime-audit.sh                     # System audit
*/6 * * * * vault-safe-push.sh                   # Vault sync
*/6 * * * * paper-intake.sh                      # Paper ingestion
* * * * * verify-sync-status.sh                  # Sync verification
*/5 * * * * check-cloudflared.sh                 # RAG tunnel monitoring ✅
```

### Recommendation: NO NEW CRON JOBS NEEDED

**Reasoning:**
- ✅ Cloudflare tunnel already monitored by `check-cloudflared.sh` (every 5 min)
- ✅ API wrapper running with auto-restart wrapper
- ✅ Obsidian sync already has multiple cron jobs
- ✅ System health checks already in place

**If monitoring enhancements desired in future:**
- Add RAG API health check to heartbeat.sh (current heartbeat focuses on Obsidian)
- Create dedicated RAG monitoring log
- Add alerting if API returns errors
- Track API response time metrics

---

## ✅ FINAL CANONICAL STRUCTURE

### Root Level
```
orebit-ops/
├── README.md                              # ✅ CANONICAL
├── SOP.md                                 # ✅ CANONICAL
├── PRODUCTION_DEPLOYMENT_STATUS.md         # ✅ CANONICAL
├── AGENTS.md                              # ✅ CANONICAL
├── check-cloudflared.sh                   # ✅ ACTIVE (cron)
├── cloudflared-wrapper.sh                 # ✅ ACTIVE (wrapper)
├── vps-deploy-rag.sh                     # ✅ ACTIVE (deployment)
├── vps-update-tunnel-url.sh               # ✅ ACTIVE (maintenance)
├── ops/                                   # ✅ ACTIVE (scripts/SOPs)
├── rag-system/                            # ✅ ACTIVE (RAG system)
└── rag-public/                            # ✅ ACTIVE (React UI)
```

### Archived
```
orebit-ops/
└── docs/archived/                        # ✅ Historical documents
    ├── *.md (old deployment docs)
    ├── *.sh (old scripts)
    └── scripts/ (archived scripts)
```

---

## 🚀 EXECUTION PLAN

### Step 1: Create Archive Directory
```bash
mkdir -p docs/archived/scripts
```

### Step 2: Move Obsolete Files
```bash
# Move obsolete documentation
mv DEPLOYMENT.md docs/archived/
mv SOLUTION_WORKING.md docs/archived/
mv CHECK_AND_FIX_VPS.md docs/archived/
mv UI_SOLUTION_OPTIONS.md docs/archived/
mv NEW_TUNNEL_URL_ACTIVE.md docs/archived/
mv TUNNEL_DOWN_EMERGENCY_FIX.md docs/archived/
mv DEPLOY_ACTION_REQUIRED.md docs/archived/
mv UI_DISCOVERY_ANALYSIS.md docs/archived/
mv LANDING_PAGE_FIX.md docs/archived/
mv VERCEL_VS_VPS_DECISION.md docs/archived/
mv VPS_DEPLOY_QUICKSTART.md docs/archived/
mv VPS_SYNC_COMPLETE.md docs/archived/
mv RAG_DEPLOYMENT_COMPLETE_GUIDE.md docs/archived/
# ... (move all other obsolete files)

# Move obsolete scripts
mv deploy-vps-frontend.sh docs/archived/scripts/
mv deploy-vps-rag-api.sh docs/archived/scripts/
mv deploy-rag-ui-to-vps.sh docs/archived/scripts/
mv deploy-full-rag-to-vps.sh docs/archived/scripts/
mv emergency-tunnel-fix.sh docs/archived/scripts/
mv vps-ssh-tunnel-setup.sh docs/archived/scripts/
mv setup-landing-page.sh docs/archived/scripts/
mv update-landing-page.sh docs/archived/scripts/
mv setup-cloudflared-tunnel.sh docs/archived/scripts/
```

### Step 3: Update README.md
- Document the archival structure
- Reference docs/archived/ for historical documentation
- Keep clean canonical documentation in root

### Step 4: Create CLEANUP_SUMMARY.md
- Document what was archived
- Provide rationale for each archival decision
- Keep record of historical decisions

---

## 📊 SUMMARY

| Category | Count | Action |
|----------|-------|--------|
| **Canonical Docs** | 4 | Keep ✅ |
| **Active Scripts** | 4 | Keep ✅ |
| **Archive Files** | ~30 | Move to docs/archived/ |
| ** Archive Scripts** | ~8 | Move to docs/archived/scripts/ |
| **New Cron Jobs** | 0 | Not needed |

---

## 🎯 FINAL STATE

**Canonical Structure:** Clean and minimal
**Historical Documentation:** Preserved in docs/archived/
**Active Monitoring:** Existing cron jobs sufficient
**No New Cron Jobs Needed:** Current setup covers all requirements

---

**End of Cleanup Plan**
