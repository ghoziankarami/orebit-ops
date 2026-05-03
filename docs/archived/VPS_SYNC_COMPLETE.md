# VPS RAG SYSTEM SYNC - COMPLETE SETUP GUIDE

## Overview
Setup VPS (43.157.201.50) untuk sync corpus papers dari Google Drive dan index ke ChromaDB.

## Current Status
- VPS: Online, API running, ChromaDB empty
- Need: Papers corpus + indexing to achieve 350 indexed papers

## Setup Structure

### QwenPaw (Local):
- Vault: `/app/working/workspaces/default/obsidian-system/vault`
- ChromaDB: `/app/working/workspaces/default/file_store/chroma`
- rclone: Already configured & working

### VPS (Deployment):
- Repo: `/home/ubuntu/orebit-ops`
- Vault: Need to sync via rclone
- Papers: Need to sync from Google Drive
- ChromaDB: `/home/ubuntu/orebit-rag/chroma/`
- Papers Data: `/home/ubuntu/orebit-rag/data/papers/`

---

# PHASE A: SETUP RCLONE AND PULL VAULT FROM GOOGLE DRIVE

```bash
# ===========================================================
# PHASE A: RCLONE SETUP
# ===========================================================

echo "======================================================================"
echo "PHASE A: RCLONE SETUP"
echo "======================================================================"

# A1: Install rclone
echo "A1: Installing rclone..."
curl https://rclone.org/install.sh | sudo bash

# Verify
echo ""
echo "A1: rclone version:"
rclone version

echo ""
echo "✅ rclone installed"
echo ""

# A2: Create rclone config directory
echo "A2: Creating rclone config directory..."
mkdir -p ~/.config/rclone
chmod 700 ~/.config

echo "✅ Config directory created"
echo ""

# A3: Setup rclone config (MANUAL STEP REQUIRED)
echo "A3: === ACTION REQUIRED ==="
echo ""
echo "Please create rclone config file: ~/.config/rclone/rclone.conf"
echo ""
echo "Config should include:"
echo "  [gdrive-obsidian]"
echo "  type = drive"
echo "  scope = drive.readonly"
echo "  token = {...}"
echo "  team_drive = ..."
echo ""
echo "  [gdrive-obsidian-oauth]"
echo "  type = drive"
echo "  scope = drive"
echo "  client_id = ..."
echo "  client_secret = ..."
echo "  token = {...}"
echo ""
echo "Copy config from QwenPaw: cat ~/.config/rclone/rclone.conf"
echo "Then paste to VPS: nano ~/.config/rclone/rclone.conf"
echo ""
echo "After config is ready, press Enter to continue..."
read

# A4: Verify config
echo ""
echo "A4: Verifying rclone config..."
rclone config show

# Test remotes
echo ""
echo "A4: Listing remotes:"
rclone listremotes

echo ""
echo "A4: Testing Google Drive connection..."
rclone lsd gdrive-obsidian-oauth:obsidian-system 2>/dev/null | head -5 || echo "Remote not configured yet"

echo ""
echo "✅ rclone config verification"
echo ""

# A5: Explore Google Drive structure for papers
echo "A5: Finding papers in Google Drive..."
echo ""
echo "Checking common paths:"
echo "1. obsidian-system/3. Resources/Papers/"
rclone ls gdrive-obsidian-oauth:obsidian-system/3.\ Resources/Papers/ 2>/dev/null | head -3 || echo "Not found"
echo ""
echo "2. obsidian-system/Papers/"
rclone ls gdrive-obsidian-oauth:obsidian-system/Papers/ 2>/dev/null | head -3 || echo "Not found"
echo ""
echo "3. obsidian-system/"
rclone ls gdrive-obsidian-oauth:obsidian-system/ | grep -i paper || echo "Not found"

echo ""
echo "A5: === ENTER CORRECT PAPERS PATH ==="
echo "Example: gdrive-obsidian-oauth:obsidian-system/3. Resources/Papers/"
read PAPERS_PATH

# A6: Sync papers from Google Drive
echo ""
echo "A6: Syncing papers from Google Drive..."
echo "Source: $PAPERS_PATH"
echo "Destination: /home/ubuntu/orebit-rag/data/papers/"

# Create destination directory
mkdir -p /home/ubuntu/orebit-rag/data/papers

# Sync papers
rclone sync "$PAPERS_PATH" /home/ubuntu/orebit-rag/data/papers/ \
  --progress \
  --stats 5s \
  --log-file /home/ubuntu/orebit-rag/logs/sync.log

# Check sync result
echo ""
echo "A6: Sync complete!"
echo "Total papers synced:"
find /home/ubuntu/orebit-rag/data/papers/ -type f | wc -l

echo ""
echo "✅ Phase A complete: rclone + papers synced"
```

---

# PHASE B: SYNC RUNTIME PATHS (OPTION B: SYMLINKS)

```bash
# ===========================================================
# PHASE B: SYNC RUNTIME PATHS (OPTION B: SYMLINKS - RECOMMENDED)
# ===========================================================

echo "======================================================================"
echo "PHASE B: SYNC RUNTIME PATHS"
echo "======================================================================"

echo "B1: Creating compatibility symlink structure..."
echo ""

# Create the old path structure as symlinks
sudo mkdir -p /app/working/workspaces/default
sudo chown ubuntu:ubuntu /app/working/workspaces/default

# Symlink: /app/working/workspaces/default -> /home/ubuntu
sudo ln -sfn /home/ubuntu /app/working/workspaces/default/ubuntu

# Symlink: /app/working/workspaces/default/orebit-ops -> /home/ubuntu/orebit-ops (if different)
if [ ! -e /app/working/workspaces/default/orebit-ops ]; then
    sudo ln -sfn /home/ubuntu/orebit-ops /app/working/workspaces/default/orebit-ops
fi

# Symlink: /app/working/workspaces/default/obsidian-system -> /home/ubuntu/orebit-ops/obsidian-system
if [ ! -e /app/working/workspaces/default/obsidian-system ]; then
    sudo ln -sfn /home/ubuntu/orebit-ops/obsidian-system /app/working/workspaces/default/obsidian-system
fi

# Verify symlinks
echo "B1: Symlink structure:"
ls -la /app/working/workspaces/default/

echo ""
echo "✅ Symlink structure created"
echo ""

# B2: Sync vault from Google Drive
echo "B2: Syncing obsidian vault from Google Drive..."
rclone sync gdrive-obsidian-oauth:obsidian-system/ /home/ubuntu/orebit-ops/obsidian-system/ \
  --exclude "node_modules/**" \
  --exclude ".git/**" \
  --progress \
  --log-file /home/ubuntu/orebit-rag/logs/vault-sync.log

echo ""
echo "B3: Checking vault structure..."
ls -la /home/ubuntu/orebit-ops/obsidian-system/
ls -la /home/ubuntu/orebit-ops/obsidian-system/vault/ 2>/dev/null || echo "Vault directory not found"

echo ""
echo "✅ Phase B complete: runtime paths synced"
```

---

# PHASE C: INSTALL PDF EXTRACTOR

```bash
# ===========================================================
# PHASE C: INSTALL PDF EXTRACTOR
# ===========================================================

echo "======================================================================"
echo "PHASE C: INSTALL PDF EXTRACTOR"
echo "======================================================================"

# C1: Update package lists and install pdftotext (poppler-utils)
echo "C1: Installing pdftotext (poppler-utils)..."
sudo apt-get update
sudo apt-get install -y poppler-utils

# C2: Alternative: install mutool (mupdf-tools)
echo "C2: Installing mutool (mupdf-tools)..."
sudo apt-get install -y mupdf-tools

# C3: Verify installations
echo ""
echo "C3: Verifying installations..."
echo ""
echo "pdftotext version:"
pdftotext -v 2>/dev/null | head -2

echo ""
echo "mutool version:"
mutool version 2>/dev/null | head -5

echo ""
echo "✅ Phase C complete: PDF extractors installed"
```

---

# PHASE D: RUN INDEXING

```bash
# ===========================================================
# PHASE D: INDEXING PAPERS TO CHROMADB
# ===========================================================

echo "======================================================================"
echo "PHASE D: INDEXING PAPERS TO CHROMADB"
echo "======================================================================"

# D1: Check if ingest script exists
echo "D1: Looking for ingest script..."
cd ~/orebit-ops/rag-system

# Search for ingest scripts
echo "Searching in repository:"
find . -name "*ingest*" -o -name "*index*" | grep -E "\.(sh|py)$" | grep -v node_modules | head -10

echo ""
echo "D2: Checking for existing ingest_all_pdfs_to_papers.sh script..."
if [ -f "ingest_all_pdfs_to_papers.sh" ]; then
    echo "✅ Found ingest script"
    cat ingest_all_pdfs_to_papers.sh
elif [ -f "ingest_papers.sh" ]; then
    echo "✅ Found alternative ingest script"
    cat ingest_papers.sh
else
    echo "❌ No ingest script found"
    echo "Creating basic ingest script..."

    # Create basic ingest script
    cat > ingest_papers.sh << 'INGESTEOF'
#!/bin/bash
# Script to ingest PDF papers into ChromaDB

PAPERS_DIR="/home/ubuntu/orebit-rag/data/papers"
CHROMADB_HOST="127.0.0.1"
CHROMADB_PORT="8000"
COLLECTION_NAME="paper_docs"

echo "=== Ingessing Papers to ChromaDB ==="
echo "Papers directory: $PAPERS_DIR"
echo "Target collection: $COLLECTION_NAME"

# Run Python ingestion script
python3 ingest_papers.py --dir "$PAPERS_DIR" \
  --host "$CHROMADB_HOST" \
  --port "$CHROMADB_PORT" \
  --collection "$COLLECTION_NAME"

echo "=== Ingestion Complete ==="
INGESTEOF

    chmod +x ingest_papers.sh
    echo "✅ Created ingest_papers.sh"
fi

# D3: Check for Python ingestion script
echo ""
echo "D3: Looking for Python ingestion script..."
if [ -f "ingest_papers.py" ]; then
    echo "✅ Found Python ingestion script"
elif [ -f "index_papers.py" ]; then
    echo "✅ Found index_papers.py (renaming)"
    cp index_papers.py ingest_papers.py
else
    echo "❌ No Python ingestion script found"
    echo "Creating basic Python ingestion script..."

    cat > ingest_papers.py << 'PYEOF'
#!/usr/bin/env python3
"""Ingest PDF papers into ChromaDB"""
import chromadb
import os
import subprocess
from pathlib import Path
import hashlib

# Configuration
PAPERS_DIR = "/home/ubuntu/orebit-rag/data/papers"
CHROMADB_HOST = "127.0.0.1"
CHROMADB_PORT = 8000
COLLECTION_NAME = "paper_docs"

def extract_text_from_pdf(pdf_path):
    """Extract text from PDF using pdftotext"""
    try:
        result = subprocess.run(
            ['pdftotext', pdf_path, '-'],
            capture_output=True,
            text=True,
            timeout=30
        )
        return result.stdout
    except Exception as e:
        print(f"Error extracting text from {pdf_path}: {e}")
        return None

def main():
    print("=== Starting Paper Ingestion ===")

    # Connect to ChromaDB
    client = chromadb.HttpClient(host=CHROMADB_HOST, port=CHROMADB_PORT)
    print(f"✅ Connected to ChromaDB")

    # Get or create collection
    try:
        collection = client.get_collection(name=COLLECTION_NAME)
        print(f"✅ Using existing collection: {COLLECTION_NAME}")
    except:
        collection = client.create_collection(name=COLLECTION_NAME)
        print(f"✅ Created new collection: {COLLECTION_NAME}")

    # Scan papers directory
    papers_dir = Path(PAPERS_DIR)
    if not papers_dir.exists():
        print(f"❌ Papers directory not found: {PAPERS_DIR}")
        return

    # Collect all PDF files
    pdf_files = list(papers_dir.glob("*.pdf"))
    print(f"📄 Found {len(pdf_files)} PDF files")

    if not pdf_files:
        print("⚠️ No PDF files found to ingest")
        return

    # Index papers
    ids = []
    documents = []
    metadatas = []

    for i, pdf_file in enumerate(pdf_files):
        print(f"Processing {i+1}/{len(pdf_files)}: {pdf_file.name}")

        # Extract text from PDF
        text = extract_text_from_pdf(pdf_file)

        if text and len(text.strip()) > 100:  # Only process PDFs with content
            doc_id = f"paper_{i:03d}_{hashlib.md5(str(pdf_file).encode()).hexdigest()[:8]}"

            ids.append(doc_id)
            documents.append(text)
            metadatas.append({
                "filename": pdf_file.name,
                "path": str(pdf_file),
                "size": pdf_file.stat().st_size if pdf_file.exists() else 0
            })
        else:
            print(f"  ⚠️ Skipping (no content or too short): {pdf_file.name}")

    # Add to ChromaDB
    if ids:
        # Process in batches for large datasets
        batch_size = 100
        for i in range(0, len(ids), batch_size):
            batch_ids = ids[i:i+batch_size]
            batch_docs = documents[i:i+batch_size]
            batch_metas = metadatas[i:i+batch_size]

            collection.add(
                ids=batch_ids,
                documents=batch_docs,
                metadatas=batch_metas
            )
            print(f"✅ Ingested batch {i//batch_size + 1}: {len(batch_ids)} papers")

        print(f"✅ Total ingested papers: {len(ids)}")
        print(f"✅ Collection count: {collection.count()}")
    else:
        print("⚠️ No papers ingested")

    print("=== Ingestion Complete ===")

if __name__ == "__main__":
    main()
PYEOF

    chmod +x ingest_papers.py
    echo "✅ Created ingest_papers.py"
fi

# D4: Run the ingestion
echo ""
echo "D4: Running paper ingestion..."
python3 ingest_papers.py

# D5: Verify API health
echo ""
echo "D5: Verifying API health after indexing..."
curl -s https://rag.orebit.id/api/rag/health

echo ""
echo "✅ Phase D complete: papers indexed"
```

---

# FINAL VERIFICATION

```bash
# ===========================================================
# FINAL VERIFICATION
# ===========================================================

echo "======================================================================"
echo "FINAL VERIFICATION - ALL PHASES COMPLETE"
echo "======================================================================"

echo "1. ChromaDB Status:"
sudo systemctl status --no-pager orebit-chroma.service | grep "Active:"

echo ""
echo "2. API Status:"
sudo systemctl status --no-pager orebit-api.service | grep "Active:"

echo ""
echo "3. API Health (Final):"
curl -s https://rag.orebit.id/api/rag/health | python3 -m json.tool

echo ""
echo "4. Papers Count in Papers Directory:"
find /home/ubuntu/orebit-rag/data/papers/ -type f | wc -l

echo ""
echo "5. ChromaDB Collections:"
curl -s http://localhost:8000/api/v1/collections 2>/dev/null || echo "Cannot access locally"

echo ""
echo "6. Symlink Structure:"
ls -la /app/working/workspaces/default/

echo ""
echo "======================================================================"
echo "VERIFICATION COMPLETE"
echo "======================================================================"
```

---

# QUICK RCLONE CONFIG (FROM QWENPAW)

Run this command on QwenPaw to get rclone config:

```bash
cat ~/.config/rclone/rclone.conf
```

Then copy the output and paste to VPS: `nano ~/.config/rclone/rclone.conf`

---

# QUICK CHECK PAPERS PATHS (FROM QWENPAW)

Run these commands on QwenPaw to find papers in Google Drive:

```bash
# Check common paths
rclone ls gdrive-obsidian-oauth:obsidian-system/3. Resources/Papers/
rclone ls gdrive-obsidian-oauth:obsidian-system/Papers/
rclone ls gdrive-obsidian-oauth:obsidian-system/ | grep -i paper
```

---

# EXPECTED FINAL RESULT

After running all phases, the API health check should show:

```json
{
  "status": "healthy",
  "service": "rag-api-wrapper",
  "version": "2.0.1-safe",
  "mode": "public_read_only",
  "llm_model": "openai/gpt-oss-120b:free",
  "llm_ready": true,
  "corpus": {
    "indexed_papers": 350,        // Should be ~350
    "summary_count": 342,
    "collection_count": 93
  }
}
```

---

# TROUBLESHOOTING

## Issue: indexed_papers still 0 after indexing

**Possible causes:**
1. Papers directory empty after sync
2. PDF text extraction failed
3. ChromaDB connection failed

**Solutions:**
```bash
# Check papers count
find /home/ubuntu/orebit-rag/data/papers/ -type f | wc -l

# Check ChromaDB logs
tail -50 ~/orebit-rag/logs/chroma.log

# Check ingestion logs
tail -50 ~/orebit-rag/logs/index.log

# Test PDF extraction
pdftotext /home/ubuntu/orebit-rag/data/papers/your-file.pdf -
```

## Issue: rclone cannot connect to Google Drive

**Solution:**
```bash
# Verify config
rclone config show

# Test connection
rclone ls gdrive-obsidian-oauth:obsidian-system/

# Re-auth if needed
rclone config update gdrive-obsidian-oauth
```

## Issue: Symlinks not working

**Solution:**
```bash
# Verify symlinks
ls -la /app/working/workspaces/default/

# Recreate symlinks
sudo mkdir -p /app/working/workspaces/default
sudo ln -sfn /home/ubuntu /app/working/workspaces/default/ubuntu
sudo ln -sfn /home/ubuntu/orebit-ops/obsidian-system /app/working/workspaces/default/obsidian-system
```

---

# AUTO-SYNC SETUP (OPTIONAL)

To setup automatic sync and reindexing:

```bash
# Create sync script
cat > ~/orebit-rag/scripts/sync-and-index.sh << 'SYNCEOF'
#!/bin/bash
# Sync papers from Google Drive and reindex

LOGDIR="$HOME/orebit-rag/logs"
REMOTE_PATH="$1"  # Pass remote path as argument

echo "[$(date)] Starting paper sync..." >> $LOGDIR/sync.log

# Sync papers
rclone sync "$REMOTE_PATH" $HOME/orebit-rag/data/papers/ \
  --progress \
  --log-file $LOGDIR/sync.log

echo "[$(date)] Papers synced. Reindexing..." >> $LOGDIR/sync.log

# Reindex
python3 $HOME/orebit-ops/rag-system/ingest_papers.py >> $LOGDIR/index.log 2>&1

echo "[$(date)] Indexing complete. Done." >> $LOGDIR/sync.log
SYNCEOF

chmod +x ~/orebit-rag/scripts/sync-and-index.sh

# Add to crontab (run every 6 hours)
# 0 */6 * * * /home/ubuntu/orebit-rag/scripts/sync-and-index.sh gdrive-obsidian-oauth:path/to/papers
```

---

# SUMMARY

### What Gets Done:

1. **Phase A**: rclone installed, config setup, papers synced from Google Drive to VPS
2. **Phase B**: Symlink structure created for path compatibility, vault synced
3. **Phase C**: PDF extractors installed (pdftotext, mutool)
4. **Phase D**: Papers indexed into ChromaDB, API health verified

### Final State:

- Papers synced from Google Drive to VPS
- Path compatibility via symlinks
- PDFs indexed to ChromaDB (target collection: paper_docs)
- API shows `indexed_papers: 350`
- Full RAG system operational

### Next Steps After Completion:

1. Test RAG query endpoint
2. Setup auto-sync if needed
3. Monitor API health
4. Update papers as needed via Google Drive sync

---

**Run each phase sequentially on VPS and verify completion before proceeding to next phase!**
