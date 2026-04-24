# Orebit Workspace Deployment

Single source of truth for deploying the complete Orebit workspace on Qwenpaw or any fresh VPS.

## What's Included

| Component | Purpose | Deploy Method |
|---|---|---|
| `infra-template/` | Master installer + env templates | `bash install.sh` |
| `rag-system/` | RAG API + Dashboard + Chroma DB | `bash rag-system/install.sh` |
| `obsidian-system/` | PARA vault + capture workflow | Symlink + restore |
| `research-data/` | Nala scripts + Orebit planning | Install script |

## Quick Start

### 1. Clone

```bash
git clone https://github.com/ghoziankarami/orebit-rag-deploy.git
cd orebit-rag-deploy
```

### 2. Install

```bash
bash infra-template/install.sh
```

This will:
- Validate Docker, Python 3, curl, and rclone are available
- Run preflight checks against `.env` and runtime layout
- Run component installers
- Run postflight verification

### 3. Configure

```bash
cp infra-template/.env.template .env
# Edit .env with your actual values
```

### 4. Restore Data

Data is NOT in this repo. Restore from backup:

```bash
# Obsidian vault
tar xzf obsidian-backup.tar.gz -C /workspace/obsidian-system/

# Research data
tar xzf research-backup.tar.gz -C /workspace/

# RAG Chroma DB
tar xzf rag-chroma-backup.tar.gz -C /workspace/rag-system/
```

### 5. Configure Rclone

```bash
rclone config
# Create "gdrive" remote for Google Drive
# Or copy your existing rclone.conf to ~/.config/rclone/
```

### 6. Verify

```bash
# Services
systemctl is-active rag-dashboard-advanced rag-api-wrapper

# Endpoints
curl -sS http://127.0.0.1:8503 >/dev/null && echo "Dashboard: OK"
curl -sS http://127.0.0.1:3004/api/rag/health
curl -sS -X POST http://127.0.0.1:3004/api/rag/query \
  -H 'Content-Type: application/json' \
  -d '{"query":"test","top_k":1}'
curl -sS -o /dev/null -w '%{http_code}\n' http://127.0.0.1:3004/api/rag/query
# Last should return 405 (GET not allowed)

# Rclone
ls /mnt/gdrive/AI_Knowledge | head
```

## Migration from VPS

### On Old VPS (Before Shutdown)

```bash
# Create backup directory
mkdir -p /tmp/workspace-backup

# Backup Obsidian vault
tar czf /tmp/workspace-backup/obsidian-backup.tar.gz \
  -C /workspace/obsidian-system vault

# Backup research data
tar czf /tmp/workspace-backup/research-backup.tar.gz \
  -C /workspace/research-data .

# Backup RAG Chroma DB
tar czf /tmp/workspace-backup/rag-chroma-backup.tar.gz \
  -C /workspace/rag-system chroma

# Backup rclone config
cp ~/.config/rclone/rclone.conf /tmp/workspace-backup/

# Download backups to local machine
scp user@vps:/tmp/workspace-backup/*.tar.gz ./
```

### On Qwenpaw (After Clone)

```bash
# Restore Obsidian
tar xzf obsidian-backup.tar.gz -C /workspace/obsidian-system/

# Restore research data
tar xzf research-backup.tar.gz -C /workspace/research-data/

# Restore Chroma DB
tar xzf rag-chroma-backup.tar.gz -C /workspace/rag-system/

# Restore rclone config
mkdir -p ~/.config/rclone
cp rclone.conf ~/.config/rclone/

# Mount Google Drive
rclone mount gdrive:AI_Knowledge /mnt/gdrive/AI_Knowledge --daemon

# Start services
bash infra-template/install.sh
```

## Repo Structure

```
orebit-rag-deploy/
├── infra-template/
│   ├── install.sh              # Master installer
│   ├── .env.template           # Environment template
│   ├── .env.example            # Example env
│   └── rclone.conf.template    # Rclone config template
├── BOOTSTRAP.md                # Operator and agent bootstrap guide
├── AGENTS.md                   # Repo instructions for future agents
├── rag-system/
│   ├── Dockerfile              # Multi-stage build
│   ├── docker-compose.yml      # Service definitions
│   ├── .dockerignore           # Build exclusions
│   ├── .env.example            # RAG env example
│   ├── install.sh              # RAG installer
│   └── api-wrapper/            # API source code
├── obsidian-system/
│   ├── install.sh              # Obsidian setup
│   └── vault/                  # Vault structure
│       └── .obsidian/          # Obsidian config
├── research-data/
│   ├── install.sh              # Research data setup
│   ├── nala/                   # Nala scripts + configs
│   ├── orebit/                 # Orebit planning data
│   └── papers-index/           # Paper metadata
└── .gitignore                  # Git exclusions
```

## What's NOT in This Repo

- `.env` files with secrets
- Obsidian vault content (markdown files)
- Chroma DB runtime data
- Research PDFs and large datasets
- `node_modules/`, `__pycache__/`, logs, backups

These should be migrated separately via backup/restore.

## Services

| Service | Port | Purpose |
|---|---|---|
| `rag-dashboard-advanced` | 8503 | RAG Dashboard |
| `rag-api-wrapper` | 3004 | RAG API |
| `hermes-gateway` | - | Gateway runtime |
| `caddy` | 80/443 | Reverse proxy |

## Troubleshooting

### Dashboard not loading
```bash
systemctl restart rag-dashboard-advanced
curl http://127.0.0.1:8503
```

### API not responding
```bash
systemctl restart rag-api-wrapper
curl http://127.0.0.1:3004/api/rag/health
```

### Rclone mount missing
```bash
rclone mount gdrive:AI_Knowledge /mnt/gdrive/AI_Knowledge --daemon
ls /mnt/gdrive/AI_Knowledge
```

### Data not showing
```bash
# Verify backup was restored correctly
ls /workspace/obsidian-system/vault/
ls /workspace/research-data/nala/
ls /workspace/rag-system/chroma/
```

## Data Sync via Google Drive (rclone)

Files NOT in this repo (vault content, Chroma DB, secrets) are synced to GDrive:

```
gdrive:orebit-workspace-backup/
├── obsidian-system/
│   ├── vault/              # Markdown files
│   └── .obsidian/          # Config (no plugins/themes)
├── rag-system/
│   └── chroma/             # Vector DB
├── research-data/          # Nala configs, paper tracker
├── env-files/              # .env files (secrets)
└── rclone-config/          # rclone.conf
```

### Backup (from VPS)

```bash
bash infra-template/sync-to-gdrive.sh
```

### Restore (on Qwenpaw)

```bash
bash infra-template/sync-to-gdrive.sh --restore
```

### Dry Run (preview only)

```bash
bash infra-template/sync-to-gdrive.sh --dry-run
```
