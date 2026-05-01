# DNS Records Checklist - RAG.orebit.id & api.orebit.id

> **VPS IP:** 43.157.201.50  
> **Target:** Deploy RAG system to orebit-sumopod  
> **Last Updated:** 2026-05-01

---

## ⚠️ IMPORTANT: Configure DNS BEFORE Setup

**DNS records must be configured and propagated BEFORE running the VPS setup script.**

---

## DNS Records to Create/Verify

### Required Records

| # | Type | Name/Host | Value/Points To | TTL | Priority | Required? |
|---|:---:|:---:|---|:---:|:---:|:---:|
| 1 | A | rag | 43.157.201.50 | 300 | - | ✅ REQUIRED |
| 2 | A | api | 43.157.201.50 | 300 | - | ✅ REQUIRED |

### Optional Records

| # | Type | Name/Host | Value/Points To | TTL | Priority | Required? |
|---|:---:|:---:|---|:---:|:---:|:---:|
| 3 | A | @ | 43.157.201.50 | 300 | - | ⚪ Optional |
| 4 | CNAME | www | rag.orebit.id | 300 | - | ⚪ Optional |

---

## Full Domain Names

| Record | Full Domain | Points To |
|---|---|---|
| rag (A) | **rag.orebit.id** | 43.157.201.50 |
| api (A) | **api.orebit.id** | 43.157.201.50 |
| @ (A) | **orebit.id** | 43.157.201.50 (optional) |
| www (CNAME) | **www.orebit.id** | rag.orebit.id (optional) |

---

## How to Configure DNS

### Step 1: Login to DNS Provider

Common DNS providers:
- Cloudflare
- Namecheap
- GoDaddy
- Google Domains
- DigitalOcean
- Linode
- AWS Route 53
- Custom DNS

### Step 2: Find DNS Management

Look for:
- "DNS Management"
- "DNS Records"
- "Zone File Editor"
- "Advanced DNS"

### Step 3: Add/Update Records

Create or update the following 2 required records:

#### Record 1: rag.orebit.id
```
Type: A
Name/Host: rag
Value/Points To: 43.157.201.50
TTL: 300 (or default)
```

#### Record 2: api.orebit.id
```
Type: A
Name/Host: api
Value/Points To: 43.157.201.50
TTL: 300 (or default)
```

### Step 4: Save Changes

Save the DNS records. Propagation will begin immediately.

---

## DNS Propagation Verification

### Step 1: Wait for Propagation

- **Minimum wait:** 5-10 minutes
- **Recommended wait:** 15-30 minutes
- **Maximum wait:** 24 hours (rare)

### Step 2: Verify Propagation Locally

```bash
# Check rag.orebit.id
dig rag.orebit.id

# Check api.orebit.id
dig api.orebit.id

# Alternative: Using nslookup
nslookup rag.orebit.id
nslookup api.orebit.id

# Alternative: Using host
host rag.orebit.id
host api.orebit.id
```

**Expected output:**
```
rag.orebit.id.  300  IN  A  43.157.201.50
api.orebit.id.  300  IN  A  43.157.201.50
```

### Step 3: Verify Globally

Use these tools to verify DNS propagation worldwide:

1. **DNS Checker:** https://dnschecker.org/
   - Enter: `rag.orebit.id`
   - Select record type: A
   - Click "Search"

2. **DNS Propagation Checker:** https://www.whatsmydns.net/
   - Enter: `rag.orebit.id`
   - Select record type: A
   - Click "Search"

3. **Google Admin Toolbox:** https://toolbox.googleapps.com/apps/dig/
   - Enter: `rag.orebit.id`
   - Click "Dig"

**Success:** All servers show `43.157.201.50`

---

## Troubleshooting DNS

### Issue: DNS Not Propagating

**Symptom:** `dig` shows old IP or "NXDOMAIN"

**Solution:**
1. Wait 10-15 more minutes
2. Clear local DNS cache
3. Check if records are saved correctly
4. Verify TTL settings

### Issue: Wrong IP Address

**Symptom:** DNS shows different IP than `43.157.201.50`

**Solution:**
1. Check DNS provider dashboard
2. Verify records are correct
3. Look for multiple A records with same name
4. Delete and recreate records

### Issue: 5XX Errors Browsers

**Symptom:** "DNS_PROBE_POSSIBLE" or "DNS_PROBE_FINISHED_NXDOMAIN"

**Solution:**
1. Verify DNS records are configured
2. Wait for full propagation (up to 1 hour)
3. Try different browser
4. Clear browser cache
5. Check if firewall blocking DNS (port 53)

---

## Clearing DNS Cache

### Clear Local DNS Cache

#### macOS
```bash
dscacheutil -flushcache
sudo killall -HUP mDNSResponder
```

#### Linux
```bash
# Many distributions don't cache, but if needed:
sudo systemctl restart systemd-resolved
# or
sudo systemctl restart NetworkManager
```

#### Windows
```cmd
ipconfig /flushdns
```

### Clear Browser DNS Cache

#### Chrome
1. Settings → Privacy & Security → Clear browsing data
2. Select "Cached images and files"
3. Click "Clear data"

#### Firefox
1. Settings → Privacy & Security → Cookies and Site Data
2. Clear Data
3. Select "Cached Web Content"
4. Click "Clear"

---

## DNS Provider Specific Instructions

### Cloudflare
1. Login to Cloudflare Dashboard
2. Select `orebit.id` zone
3. Click "DNS"
4. Add/Update records:
   - Type: A, Name: rag, IPv4: 43.157.201.50
   - Type: A, Name: api, IPv4: 43.157.201.50
5. Set Proxy: DNS only (gray cloud icon)
6. Click "Save"

### Namecheap
1. Login to Namecheap
2. Domain List → Manage → Advanced DNS
3. Add New Record:
   - Type: A Record
   - Host: rag
   - Value: 43.157.201.50
   - TTL: Automatic
4. Repeat for "api"
5. Click "Save All Changes"

### GoDaddy
1. Login to GoDaddy
2. DNS Management → Select `orebit.id`
3. Add Record:
   - Type: A
   - Host: rag
   - Points to: 43.157.201.50
   - TTL: 1 hour
4. Repeat for "api"
5. Click "Save"

### Google Domains
1. Login to Google Domains
2. DNS → Select `orebit.id`
3. Custom resource records → Add:
   - Name: rag, Type: A, TTL: 300, Data: 43.157.201.50
4. Click "Add"
5. Repeat for "api"

---

## Quick Verification Script

```bash
#!/bin/bash

# DNS Verification Script
DOMAIN_RAG="rag.orebit.id"
DOMAIN_API="api.orebit.id"
EXPECTED_IP="43.157.201.50"

echo "=== DNS Verification ==="
echo ""

check_dns() {
    local domain=$1
    local result=$(dig +short $domain)
    
    if [ "$result" == "$EXPECTED_IP" ]; then
        echo "✅ $domain → $result (CORRECT)"
        return 0
    else
        echo "❌ $domain → $result (WRONG, expected $EXPECTED_IP)"
        return 1
    fi
}

echo "Checking DNS records..."
check_dns $DOMAIN_RAG
check_dns $DOMAIN_API

echo ""
echo "=== Full DNS Information ==="
echo ""
echo "rag.orebit.id:"
dig +short $DOMAIN_RAG
echo ""
echo "api.orebit.id:"
dig +short $DOMAIN_API
```

Save as `check-dns.sh` and run:

```bash
chmod +x check-dns.sh
bash check-dns.sh
```

---

## DNS Record Explanations

### A Record
**Purpose:** Directly maps a domain name to an IPv4 address.

**Format:**
```
Type: A
Name: rag
Value: 43.157.201.50
```

**Result:** `rag.orebit.id` → 43.157.201.50

### CNAME Record
**Purpose:** Alias one domain name to another.

**Format:**
```
Type: CNAME
Name: www
Value: rag.orebit.id
```

**Result:** `www.orebit.id` → `rag.orebit.id` → 43.157.201.50

### TTL (Time To Live)
**Purpose:** How long DNS resolvers should cache the record.

**Values:**
- 300 (5 minutes) - Fast propagation, requires more DNS queries
- 3600 (1 hour) - Balanced
- 86400 (24 hours) - Slow propagation, cached for a day

**Recommendation:** 300-3600 for initial setup, increase after stable.

---

## Final Checklist

Before running VPS setup script, verify:

- [ ] rag.orebit.id A record created pointing to 43.157.201.50
- [ ] api.orebit.id A record created pointing to 43.157.201.50
- [ ] DNS records saved in DNS provider
- [ ] DNS propagated locally (dig shows correct IP)
- [ ] DNS propagated globally (checked with online tools)
- [ ✓ ] Ready to run VPS setup script

---

## DNS Configuration Complete?

✅ **DNS configured correctly?** Then proceed to VPS setup:

1. Connect to VPS: `ssh ubuntu@43.157.201.50`
2. Run setup script: `bash setup-vps.sh`
3. Configure SSL when prompted: `yes`
4. Done! 🎉

❌ **DNS not configured yet?** Don't proceed:
- Configure DNS records first
- Wait for propagation
- Verify with `dig rag.orebit.id`
- Then return to this checklist

---

## Additional Resources

- **DNS Checker:** https://dnschecker.org/
- **WhatsMyDNS:** https://www.whatsmydns.net/
- **Google Dig:** https://toolbox.googleapps.com/apps/dig/
- **IANA Root Zone Database:** https://www.iana.org/domains/root/db

---

**Documentation:** `/opt/orebit-rag/orebit-ops/docs/operations/DNS_CHECKLIST.md`  
**VPS Guide:** `VPS_DEPLOYMENT_GUIDE.md`  
**Last Updated:** 2026-05-01
