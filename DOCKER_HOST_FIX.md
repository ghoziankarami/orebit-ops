# Docker Host Fix Runbook

This runbook explains why the RAG dashboard stack cannot fully start on this host and what to fix.

## Current symptom

`rag-system/install.sh` cannot bring up the Docker Compose stack reliably.

Observed behavior:

- `RAG API` on port `3004` is reachable
- `RAG dashboard` on port `8503` is not healthy
- `dockerd` fails during startup on this host

## Root cause summary

The failure is at the host Docker runtime layer, not in the `orebit-rag-deploy` repository.

The Docker daemon log shows startup problems around host networking and permissions, including:

- daemon root propagation warnings
- startup failure when preparing Docker networking/NAT behavior
- Docker daemon not staying alive long enough for `docker compose up` to work

In practice, this means the repo and compose config are present, but the host cannot provide a stable Docker engine for the dashboard container.

## What already works

- `/workspace/orebit-rag-deploy` bootstrap repo is present
- `/workspace/orebit-rag-deploy/.env` contains the main keys
- `/workspace/obsidian-system/vault` PARA structure is valid
- `/workspace/research-data` structure is valid
- local RAG API health endpoint returns `200`

## What does not work yet

- `docker compose -f /workspace/orebit-rag-deploy/rag-system/docker-compose.yml up -d --build`
- Streamlit dashboard health on `http://127.0.0.1:8503/_stcore/health`

## Host-level checks

Run these on the host when fixing Docker:

```bash
service docker status
ps -ef | grep -E '[d]ockerd|[c]ontainerd'
docker version
docker info
journalctl -u docker -n 200 --no-pager
cat /var/log/docker.log | tail -n 200
```

## Common fixes to try

### 1. Fix Docker daemon startup on the host

If the host blocks Docker bridge/NAT setup, Docker may fail during network initialization.

Check:

```bash
iptables -t nat -L -n
nft list ruleset
sysctl net.ipv4.ip_forward
```

Expected direction:

- Docker must be allowed to create/manage its bridge networking
- host must allow required iptables/nftables operations
- IP forwarding should not be disabled in a way that breaks Docker bridge mode

### 2. Check container runtime permissions

If this is a nested container/VPS environment, Docker may be missing capabilities required for networking.

Typical host/container requirements:

- `CAP_NET_ADMIN`-like networking capability at the host runtime boundary
- writable Docker state directories
- working `containerd`
- no policy blocking bridge/NAT creation

### 3. Verify Docker stays up before retrying compose

After host fixes:

```bash
service docker start
service docker status
docker ps
```

Only retry the app stack after `docker ps` works cleanly.

## Retry sequence after host fix

```bash
cd /workspace/orebit-rag-deploy
python3 scripts_preflight_validate.py
bash rag-system/install.sh
python3 scripts_postflight_verify.py
```

## Success criteria

- `docker ps` works
- `docker compose ... ps` shows healthy services
- `curl http://127.0.0.1:3004/api/rag/health` returns `200`
- `curl http://127.0.0.1:8503/_stcore/health` returns `200`
- `python3 /workspace/orebit-rag-deploy/scripts_postflight_verify.py` reports only expected warnings

## Notes

The repo changes already prepared the application side. The remaining blocker is host Docker stability, not missing repo files.
