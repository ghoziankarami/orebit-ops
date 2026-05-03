# RAG System - New Paper End-to-End Workflow

## 🔄 COMPLETE FLOW FOR NEW PAPERS

### **STEP 1: Add New Paper to Google Drive**
```bash
# Upload PDF to Google Drive: AI_Knowledge/
# Example: MyNewPaper_2026.pdf
```

### **STEP 2: Sync Google Drive to Local Vault**
```bash
# Option A: Manual sync
rclone sync gdrive-obsidian:AI_Knowledge/ \
  /app/working/workspaces/default/obsidian-system/vault/3.\ Resources/AI\ Knowledge/

# Option B: Cron automations (if configured)
# Existing jobs sync regularly
```

### **STEP 3: Create Obsidian Paper Note**
```bash
# Method A: Automatic (if paper-intake.sh runs)
# The script will automatically:
#  - Extract PDF text
#  - Generate embeddings
#  - Store in ChromaDB
#  - Create note in 0. Inbox/Papers/

# Method B: Manual note creation
# Create note in: 3. Resources/Papers/MyNewPaper 2026.md
# with frontmatter:
# ---
# title: "My New Paper"
# authors: "Author Name"
# year: 2026
# type: research-paper
# source: "gdrive:AI_Knowledge/MyNewPaper_2026.pdf"
# indexed: 2026-05-03
# ---
```

### **STEP 4: Run Paper Intake (if needed)**
```bash
# Manual trigger
cd /app/working/workspaces/default/orebit-ops
bash ops/scripts/paper-intake.sh

# Check logs
tail -f /tmp/pdf-intake.log
tail -f /tmp/pdf-notes.log
```

### **STEP 5: Verify RAG Index**
```bash
# Check if paper is indexed
curl -s -X POST http://127.0.0.1:3004/api/rag/answer \
  -H "Content-Type: application/json" \
  -H "X-API-Key: orebit-rag-api-key-2026-03-26-temp" \
  -d '{
    "query": "My New Paper topic",
    "limit": 5
  }'

# Browse all papers
curl -s -H "X-API-Key: orebit-rag-api-key-2026-03-26-temp" \
  http://127.0.0.1:3004/api/rag/browse?limit=50
```

### **STEP 6: Query via UI**
```bash
# Access UI: https://rag.orebit.id/
# Search for your new paper
# View citations and evidence
```

### **STEP 7: Verify Obsidian Integration**
```bash
# Check note exists
ls -1 "/app/working/workspaces/default/obsidian-system/vault/3. Resources/Papers/" | grep -i "MyNewPaper"

# Open in Obsidian ( Obsidian URI format)
obsidian://open?vault=obsidian&file=3.%20Resources/Papers/MyNewPaper%202026.md
```

---

## 📋 AUTOMATED WORKFLOWS (Current State)

### **Currently Running:**

#### **Cron Jobs (Every 45 minutes):**
```bash
*/15 * * * * /path/heartbeat.sh                          # System health
*/45 * * * * /path/paper-intake.sh                      # Paper ingestion
*/10 * * * * /path/rclone-watchdog-t3.sh                # Sync monitoring
*/5 * * * * /path/check-cloudflared.sh                  # RAG tunnel
```

#### **What Paper-Intake Does:**
1. Scans vault for PDF files
2. Extracts PDF text using pdftotext/mutool
3. Chunks text into 2200-character segments
4. Generates embeddings via embedding server (port 3005)
5. Stores in ChromaDB (collection: paper_docs)
6. Creates Obsidian note in `0. Inbox/Papers/`

---

## 🎯 CURRENT INFLOW PATH

### **HOW PAPERS GET INTO RAG (Current):**

```
┌─────────────────────────────────────────────────────────┐
│ GOOGLE DRIVE (AI_Knowledge/)                             │
│ - Upload manual papers                                  │
│ - Source of truth for PDFs                              │
└───────────────────┬─────────────────────────────────────┘
                    │ (manual rclone)
                    ↓
┌─────────────────────────────────────────────────────────┐
│ OBSIDIAN VAULT                                            │
│ 3. Resources/Papers/*.md                                  │
│ - Paper notes with metadata                              │
│ - Currently: 343 notes                                   │
└───────────────────┬─────────────────────────────────────┘
                    │ (rag_public_data.py)
                    ↓
┌─────────────────────────────────────────────────────────┐
│ CHROMADB (paper_docs)                                     │
│ - Indexed from Obsidian notes                            │
│ - 343 papers + 8 full-text PDFs                          │
│ - Embeddings: all-MiniLM-L6-v2 (384-dim)                  │
└───────────────────┬─────────────────────────────────────┘
                    │ (semantic search)
                    ↓
┌─────────────────────────────────────────────────────────┐
│ RAG API WRAPPER                                           │
│ http://127.0.0.1:3004                                    │
│ - /api/rag/health                                        │
│ - /api/rag/browse                                        │
│ - /api/rag/stats                                         │
│ - /api/rag/answer                                        │
└───────────────────┬─────────────────────────────────────┘
                    │ (Cloudflare tunnel)
                    ↓
┌─────────────────────────────────────────────────────────┐
│ VPS (43.157.201.50)                                      │
│ - Nginx reverse proxy                                    │
│ - rag.orebit.id (React UI)                              │
│ - api.orebit.id (API proxy)                             │
└───────────────────┬─────────────────────────────────────┘
                    │
                    ↓
┌─────────────────────────────────────────────────────────┐
│ END USER                                                  │
│ - https://rag.orebit.id/                                 │
│ - Query 343 papers by semantic meaning                  │
└─────────────────────────────────────────────────────────┘
```

---

## 🔧 AUTOMATION SETUP (If Needed)

### **To Enable Auto-Sync Google Drive → Vault:**

Create cron job:
```bash
# Add to crontab
*/30 * * * * rclone sync gdrive-obsidian:AI_Knowledge/ /app/working/workspaces/default/obsidian-system/vault/3.\ Resources/AI\ Knowledge/ >> /tmp/gdrive-sync.log 2>&1
```

### **To Enable Auto-Intake New PDFs:**

The `paper-intake.sh` already runs every 45 minutes. It will:
- Find new PDFs in vault
- Process them automatically
- Create Obsidian notes
- Update ChromaDB

### **To Enable LLM Synthesis (Optional):**

Set OpenRouter API key:
```bash
# Add to RAG API wrapper .env
OPENROUTER_API_KEY=your-key-here

# Restart API wrapper
kill 3848107  # Current PID
nohup node index.js > /tmp/rag-wrapper.log 2>&1 &
```

---

## 📊 CURRENT SYSTEM STATE

| Component | Status | Details |
|-----------|--------|---------|
| **Google Drive** | ✅ Connected | gdrive-obsidian, gdrive-obsidian-oauth |
| **Obsidian Vault** | ✅ Active | 343 paper notes |
| **ChromaDB** | ✅ Indexed | 343 papers (8 full-text) |
| **Embedding Server** | ✅ Running | Port 3005, all-MiniLM-L6-v2 |
| **RAG API** | ✅ Serving | Port 3004, v2.0.0 |
| **Cloudflare Tunnel** | ✅ Active | venture-stud-gale-fuji.trycloudflare.com |
| **VPS** | ✅ Live | rag.orebit.id, api.orebit.id |
| **Paper Intake** | ✅ Cron | Every 45 minutes |

---

## ✅ VERIFICATION CHECKLIST

### **For New Papers:**

- [ ] PDF uploaded to Google Drive (AI_Knowledge/)
- [ ] PDF synced to local vault (manual or cron)
- [ ] Obsidian note created (manual or auto via paper-intake.sh)
- [ ] PDF text extracted (pdftotext/mutool)
- [ ] Chunks embedded (embedding server)
- [ ] Stored in ChromaDB (paper_docs collection)
- [ ] Queryable via RAG API (/api/rag/answer)
- [ ] Visible in UI (rag.orebit.id/browse)
- [ ] Linked back to Obsidian note

---

## 🚀 QUICK REFERENCE

### **Index a New Paper Now:**

```bash
# 1. Upload PDF to Google Drive

# 2. Sync to local
rclone sync gdrive-obsidian:AI_Knowledge/ \
  /app/working/workspaces/default/obsidian-system/vault/3.\ Resources/AI\ Knowledge/

# 3. Run intake
cd /app/working/workspaces/default/orebit-ops
bash ops/scripts/paper-intake.sh

# 4. Verify
curl -s -X POST http://127.0.0.1:3004/api/rag/answer \
  -H "Content-Type: application/json" \
  -H "X-API-Key: orebit-rag-api-key-2026-03-26-temp" \
  -d '{"query":"your paper topic","limit":5}'
```

### **Check System Status:**

```bash
# Run complete test
cd /app/working/workspaces/default/orebit-ops
bash test-rag-end-to-end.sh
```

---

## 📝 TESTED WORKFLOWS

| Workflow | Tested | Status |
|----------|--------|--------|
| Google Drive → Local | ✅ | Works (manual sync) |
| PDF → Text Extraction | ✅ | Works (pdftotext) |
| Text → Embeddings | ✅ | Works (embedding server) |
| Embeddings → ChromaDB | ✅ | Works (pdf_to_paper_note.py) |
| ChromaDB → Search | ✅ | Works (96.3% relevance) |
| Search → Obsidian Link | ✅ | Works (343 notes linked) |
| Obsidian → PDF Source | ✅ | Works (gdrive links) |
| API → Cloudflare → VPS | ✅ | Works (rag.orebit.id) |
| VPS → User UI | ✅ | Works (React UI) |

---

**End of New Paper Workflow Guide**

*For detailed test results, see: RAG_END_TO_END_TEST_RESULTS.md*
*For operating procedures, see: SOP.md*
*For production status, see: PRODUCTION_DEPLOYMENT_STATUS.md*
