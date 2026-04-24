# Orebit RAG Deployment Guide

## Quick Start

### 1. Clone the repo

```bash
git clone https://github.com/ghoziankarami/orebit-rag-deploy.git
cd orebit-rag-deploy
```

### 2. Set up environment

```bash
cp infra-template/.env.template .env
# Edit .env with your actual values
```

### 3. Deploy

```bash
bash infra-template/install.sh
```

### 4. Verify

```bash
python3 scripts_preflight_validate.py
python3 scripts_postflight_verify.py

# Check endpoints directly
curl -sS http://127.0.0.1:8503/_stcore/health
curl -sS http://127.0.0.1:3004/api/rag/health
curl -sS -X POST http://127.0.0.1:3004/api/rag/query \
  -H 'Content-Type: application/json' \
  -d '{"query":"test","top_k":1}'
curl -sS -o /dev/null -w '%{http_code}\n' http://127.0.0.1:3004/api/rag/query
# Last command should return 405 (GET not allowed)
```

## Migration to Qwenpaw

### Data Migration

Data besar (Chroma DB, Obsidian vault, research data) **tidak masuk repo**. Migrasi dilakukan terpisah:

1. **Backup dari VPS lama**:
   ```bash
   tar czf /tmp/rag-data-backup.tar.gz /workspace/rag-system/chroma
   tar czf /tmp/obsidian-backup.tar.gz /workspace/obsidian-system/vault
   tar czf /tmp/research-backup.tar.gz /workspace/research-data
   ```

2. **Restore di Qwenpaw**:
   ```bash
   tar xzf rag-data-backup.tar.gz -C /workspace/rag-system/
   tar xzf obsidian-backup.tar.gz -C /workspace/obsidian-system/
   tar xzf research-backup.tar.gz -C /workspace/
   ```

3. **Deploy**:
   ```bash
   bash infra-template/install.sh
   ```

## Repo Structure

```
orebit-rag-deploy/
├── infra-template/          # Deployment entry point
│   ├── install.sh           # Master installer
│   ├── .env.template        # Environment template
│   └── README.md            # Full deployment guide
├── BOOTSTRAP.md             # Bootstrap and operator guide
├── AGENTS.md                # Repo instructions for future agents
├── rag-system/              # RAG container stack
│   ├── Dockerfile           # Multi-stage build
│   ├── docker-compose.yml   # Service definitions
│   ├── .dockerignore        # Build exclusions
│   └── api-wrapper/         # API source code
├── research-data/           # Nala datasets & Orebit planning
└── obsidian-system/         # PARA vault structure
```

## What's NOT in this repo

- `.env` files with secrets
- Runtime Chroma DB data
- Obsidian vault content
- Research PDFs and large datasets
- `node_modules/`, `__pycache__/`, logs, backups

These should be migrated separately via backup/restore or mounted volumes.
