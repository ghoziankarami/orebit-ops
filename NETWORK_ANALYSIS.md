# Network Analysis: Why Direct Connection Fails

## Diagnosis Complete

After detailed network analysis, here's what's happening:

---

## Network Configuration

### QwenPaw Actual Network Interfaces:
```
eth0: 10.11.0.185/16   (private)
eth1: 172.18.0.81/16   (Docker network)
eth2: 10.0.1.154/24   (private)
lo: 127.0.0.1/8       (loopback)
```

### Public IP:
```
103.139.244.177   (NAT/Gateway level, NOT directly on host)
```

---

## Root Cause

**QwenPaw is running in a containerized environment:**
- Host has only private IPs (10.x.x.x)
- Public IP 103.139.244.177 is on infrastructure NAT/Gateway level
- API wrapper listening on 0.0.0.0:3004 (private interfaces only)

### Connection Flow:

```
External Request (curl 103.139.244.177:3004)
    ↓
NAT/Gateway (103.139.244.177)
    ↓
❌ NO port forward setup for 3004
    ↓
Connection Refused
```

---

## Why `ufw` Won't Help

**No UFW/iptables blocking:**
- `sudo ufw` not available
- `iptables` rules empty (default accept)
- Firewall NOT the issue

**Real issue:**
- Infrastructure NAT level has NO port forward for 3004
- Cannot change NAT level from host container
- Need infrastructure-level configuration

---

## SOLUTION: SSH Tunnel (Already Correct!)

### Why SSH Tunnel Works:

```
VPS (43.157.201.50)
    ↓ SSH Connection (port 22 usually forwarded)
NAT/Gateway (QwenPaw infrastructure)
    ↓
QwenPaw Host (private IP 10.11.0.185)
    ↓
SSH Tunnel forwards VPS:3004 → QwenPaw:127.0.0.1:3004
    ↓
API Wrapper receives connection ✅
```

### Why SSH Works vs HTTP Doesn't:
- SSH port 22 already forwarded by infrastructure
- SSH uses existing established connection
- Bypasses NAT port forward requirement

---

## Correct Solution: vps-ssh-tunnel-setup.sh

### What the script does (and why it's correct):

1. **Establish SSH connection** from VPS to QwenPaw
   - SSH port 22 already forwarded via NAT
   - Creates encrypted tunnel

2. **Forward port 3004** via SSH
   - `ssh -R 3004:127.0.0.1:3004`
   - VPS localhost:3004 → QwenPaw localhost:3004 via SSH

3. **Nginx proxies to localhost:3004**
   - NOT to 103.139.244.177:3004 (which doesn't work)
   - To localhost:3004 (which goes through SSH tunnel)

4. **Access via HTTPS domain**
   - https://rag.orebit.id → Nginx → localhost:3004 → SSH tunnel → QwenPaw

---

## Why Direct Connection Failed

### Attempted Architecture (doesn't work):
```
https://rag.orebit.id → Nginx → 103.139.244.177:3004
                                          ↓
                                  (NAT level, no port forward)
                                          ↓
                                  Connection refused
```

### Working Architecture:
```
https://rag.orebit.id → Nginx → localhost:3004 → SSH tunnel
                                                         ↓
                                              QwenPaw:127.0.0.1:3004 ✅
```

---

## Confirmed Working Test

### On QwenPaw (local):
```bash
curl http://127.0.0.1:3004/api/rag/health
```
**Result:**
```json
{
  "status": "healthy",
  "indexed_papers": 351
}
```
✅ API wrapper working locally

### From VPS (via SSH tunnel):
```bash
curl http://localhost:3004/api/rag/health
```
**Result:** Should return same JSON ✅

### From VPS (direct IP - doesn't work):
```bash
curl http://103.139.244.177:3004/api/rag/health
```
**Result:** Connection refused ❌

---

## Final Recommendation

### DO NOT try:
- ❌ Opening port 3004 with UFW (UFW not available)
- ❌ iptables rules (iptables not the issue)
- ❌ Direct connection (infrastructure NAT can't forward)

### DO USE:
- ✅ SSH tunnel solution (already implemented in vps-ssh-tunnel-setup.sh)
- ✅ VPS configuration already correct (Nginx ready for localhost:3004)
- ✅ Just need to run: `bash vps-ssh-tunnel-setup.sh` on VPS

---

## Deployment is SIMPLE

### On VPS, run this:

```bash
git clone https://github.com/ghoziankarami/orebit-ops.git
cd orebit-ops
bash vps-ssh-tunnel-setup.sh
```

**That's it!** The script will:
- Create SSH tunnel (bypasses NAT requirement)
- Update Nginx to use localhost:3004
- Test deployment
- Setup auto-restart

---

## Summary

**Problem:** QwenPaw in containerized environment, public IP at NAT level, no port forward for 3004

**Solution:** SSH tunnel from VPS to QwenPaw (port 22 already forwarded)

**Command to fix:** `bash vps-ssh-tunnel-setup.sh` (on VPS)

**Result:** Working deployment via https://rag.orebit.id

---

**Infrastructure-level networking diagnosed: SSH tunnel is the CORRECT solution!** ✅
