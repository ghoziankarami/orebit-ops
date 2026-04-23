# Infra template

This is the single source of truth for Qwenpaw deployment, restore, and migration in this workspace. Start here, keep data outside Git, and use the scripts in this repo as the only bootstrap path.

## Workspace map

The workspace is organized as `infra-template/`, `obsidian-system/`, `rag-system/`, and `research-data/`.

1. `infra-template/` is the entry point for the full workspace install.
2. `obsidian-system/` holds the Obsidian vault layout and capture workflow.
3. `rag-system/` holds the Qwenpaw container stack, with the dashboard on port `8503` and the API on port `3004`.
4. `research-data/` holds validated paper data, Nala scripts, and Orebit planning material.

The files you should look at first are `infra-template/install.sh`, `infra-template/.env.template`, `infra-template/.env.template.master`, `infra-template/.env.example`, `rag-system/install.sh`, `rag-system/.env.example`, `rag-system/docker-compose.yml`, `rag-system/Dockerfile`, and `research-data/install.sh`.

## Repo policy

### Commit these

1. Install scripts.
2. Docker and compose files.
3. Sanitized templates such as `*.example` and `.env.template`.
4. Source files, configs, scripts, and docs.
5. Small validation reports that help future operators verify the current layout.

### Keep these out of GitHub

1. Real `.env` files and any secret material.
2. Runtime databases and vector stores, including `rag-system/chroma`.
3. Logs, crash dumps, caches, and temp files.
4. `node_modules`, `__pycache__`, `.venv`, build output, and package caches.
5. Backup archives, mounted storage contents, and copied live data.

If a file is a live secret, a runtime artifact, or a mounted data source, it stays out of the repo. Only the template or metadata version belongs in Git.

## Deployment entrypoints

### Full workspace bootstrap

Run this from `/workspace/infra-template` when you want the whole workspace brought up from one place.

```bash
bash install.sh
```

`infra-template/install.sh` checks Docker, Python 3, and rclone, then delegates to `obsidian-system/install.sh`, `rag-system/install.sh`, and `research-data/install.sh`.

### Qwenpaw container stack only

Run this from `/workspace/rag-system` when you only want the RAG services.

```bash
bash install.sh
```

`rag-system/install.sh` requires Docker Compose v2, creates `rag-system/chroma`, starts the stack with `docker compose up -d --build`, and waits for `chroma`, `rag-api`, and `rag-dashboard` to pass health checks.

### Research data layout check

Run this from `/workspace/research-data` when you want to verify the paper mount and helper scripts.

```bash
bash install.sh
```

`research-data/install.sh` expects `python3`, `mountpoint`, and a live mount at `/mnt/gdrive/AI_Knowledge`. It also ensures `/data/obsidian/3. Resources/Papers` exists.

### Obsidian vault check

Run this from `/workspace/obsidian-system` when you want to verify the vault tree without changing it.

```bash
bash install.sh
```

`obsidian-system/install.sh` keeps the vault intact, creates the expected folders, and leaves `/data/obsidian` alone if it is already mounted.

## Migration to Qwenpaw

Use this flow when moving from the old VPS or old storage to a fresh Qwenpaw host.

1. Clone the repo into `/workspace`.
2. Restore the data that is still external to Git before you run the installer.
3. Create local environment files from the templates.
4. Run the workspace install.
5. Verify the live ports and health checks.

### 1. Clone the repo

Place the repo so the four top level directories stay aligned with the paths above.

### 2. Restore data from the old VPS or storage

Restore file trees, not Git history.

1. If the old VPS or backup disk is still available, mount it read only or copy it to a staging directory first.
2. Restore the Obsidian vault into `/workspace/obsidian-system/vault`.
3. Restore the Chroma data into `/workspace/rag-system/chroma`.
4. Restore the research trees under `/workspace/research-data`, especially `nala/`, `orebit/`, and `papers-index/`.
5. Keep the paper source mount available at `/mnt/gdrive/AI_Knowledge` so `research-data/install.sh` can validate it.
6. If the old host had `/data/obsidian`, keep that path available on the new host too, because the Obsidian and research checks still refer to it.

For a straight file copy, use `rsync -a` from the mounted backup or old host tree into the matching destination tree. Do not copy raw backup archives into the repo.

### 3. Create local env files

1. Copy `rag-system/.env.example` to a local untracked `rag-system/.env`.
2. Fill in the RAG key and model values you actually use.
3. Use `infra-template/.env.template` and `infra-template/.env.template.master` as the sanitized workspace reference, but keep the real values in local files only.

### 4. Run the install

From `/workspace/infra-template` run:

```bash
bash install.sh
```

This is the preferred path because it runs the sibling installers in the same layout the repo already uses.

### 5. Verify the deploy

Run these checks after the install finishes:

```bash
docker compose -f /workspace/rag-system/docker-compose.yml ps
curl -sS http://127.0.0.1:8503 >/dev/null && echo dashboard-ok
curl -sS http://127.0.0.1:3004/api/rag/health
curl -sS -X POST http://127.0.0.1:3004/api/rag/query -H 'Content-Type: application/json' -d '{"query":"test","top_k":1}'
curl -sS -o /dev/null -w '%{http_code}\n' http://127.0.0.1:3004/api/rag/query
```

`POST /api/rag/query` should return JSON with the same body shape as `POST /api/rag/search`. `GET /api/rag/query` should return `405`.

If the host uses systemd wrappers, the recorded live service names are `rag-dashboard-advanced`, `rag-api-wrapper`, `caddy`, `docker`, and `tailscaled`, with `streamlit-dashboard` disabled. In that mode, also run:

```bash
systemctl is-active rag-dashboard-advanced rag-api-wrapper caddy docker tailscaled
systemctl is-enabled streamlit-dashboard
ss -ltnp '( sport = :3004 )'
ss -ltnp '( sport = :8503 )'
```

## File reference

1. `infra-template/install.sh` is the master entry point.
2. `infra-template/.env.template` is the sanitized workspace env reference.
3. `infra-template/.env.template.master` is the broader sanitized template source.
4. `infra-template/.env.example` mirrors the template for install checks.
5. `rag-system/docker-compose.yml` defines `chroma`, `rag-api`, and `rag-dashboard`.
6. `rag-system/Dockerfile` builds the dashboard and API wrapper images.
7. `rag-system/install.sh` starts and waits for the container stack.
8. `research-data/install.sh` checks the mount and helper layout.
9. `obsidian-system/install.sh` verifies the vault layout without rewriting it.

## Ignore policy

The repo already keeps build context clean with `rag-system/.dockerignore`, which ignores `.env`, `node_modules`, `__pycache__`, Python bytecode, and local virtualenvs while allowing `*.example` files back in.

Follow the same rule for the repo itself. If it is a secret, cache, runtime store, backup, or live mount, ignore it. If it is a sanitized template, installer, compose file, or validation note, commit it.
