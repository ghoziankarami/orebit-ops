# Architecture Quick Reference

## 🏗️ SYSTEM OVERVIEW

```
┌─────────────────────────────────────────┐
│         QWENPAW NODE (Local)            │
│  80 cores, 251GB RAM                    │
├─────────────────────────────────────────┤
│  • Obsidian Vault (884 files)          │
│  • ChromaDB Local (RAG)                │
│  • rclone (sync to Google Drive)       │
│  • 9router (LLM routing)               │
│  • 9 Cron jobs (automation)            │
└─────────────────────────────────────────┘
            │ HTTPS
            │ Sync
            ▼
┌─────────────────────────────────────────┐
│       OREBIT VPS (Production)           │
│  2 vCPU, 2GB RAM, 40GB SSD              │
├─────────────────────────────────────────┤
│  • Nginx (SSL, reverse proxy)          │
│  • API Wrapper (Node.js)               │
│  • ChromaDB (350 papers)               │
│  • OpenClaw (gateway)                  │
│  • rag.orebit.id (public)              │
└─────────────────────────────────────────┘
```

---

## 📋 FUNCTION BREAKDOWN

### QwenPaw (Local Node)
| Function | Description | Status |
|:---|:---|:---:|
| **Second-Brain** | Obsidian vault, PARA system | ✅ Active |
| **Paper Intake** | PDF ingestion → RAG system | ✅ Every 6h |
| **Content Staging** | Chat review candidates | ✅ Every 6h |
| **PARA Organization** | Auto-promote Inbox→PARA | ✅ Every 6h |
| **Sync Management** | rclone to Google Drive | ✅ Auto |
| **Local RAG** | ChromaDB + embeddings | ✅ Ready |
| **Monitoring** | Health checks, audit | ✅ Every 15m |

### Orebit VPS (Production)
| Function | Description | Status |
|:---|:---|:---:|
| **Public API** | RAG query endpoint | ✅ Running |
| **Domain Management** | rag.orebit.id, api.orebit.id | ✅ Active |
| **SSL/TLS** | Let's Encrypt certificates | ✅ Active |
| **Reverse Proxy** | Nginx routing | ✅ Running |
| **Vector DB** | ChromaDB with papers | ⏳ Syncing |
| **Service Management** | Systemd auto-restart | ✅ Active |

---

## � BEST PRACTICES (Strengths)

1. ✅ **Separation of Concerns** (Local vs Production)
2. ✅ **Single Source of Truth** (Google Drive)
3. ✅ **Automation** (9 cron jobs)
4. ✅ **Security** (SSL, API keys, rate limiting)
5. ✅ **PARA Methodology** (Clear organization)
6. ✅ **Cost-Effective** (60k IDR/month)

---

## ⚠️ IMPROVEMENTS NEEDED

| Issue | Priority | Impact |
|:---|:---:|:---|
| Single VPS (no redundancy) | 🔴 Critical | High downtime risk |
| No load balancing | 🔴 Critical | Poor scalability |
| No ChromaDB backup | 🔴 Critical | Data loss risk |
| No monitoring/alerting | 🟡 High | Poor observability |
| OpenClaw heavy (446MB) | 🟡 High | Wasted resources |
| No caching layer | 🟡 Medium | Slow under load |
| Limited resources (2GB) | 🟡 Medium | Scale limitations |

---

## 📈 SCALABILITY

### Current Limits
| Metric | Limit | Bottleneck |
|:---|:---:|:---|
| Concurrent Users | ~100 | 2 vCPU |
| Queries/Minute | 100 (rate limited) | API |
| Papers | ~1000 | 2GB RAM |
| Storage | 40GB | VPS disk |

### Scaling Scenarios
| Growth | Required |
|:---|:---|
| **10x Traffic** (1000 users) | Load balancer + 3-5 VPS + Redis + CDN |
| **10x Data** (3500 papers) | 8GB RAM + Dedicated ChromaDB |
| **Global Users** | Multi-region + CDN + Replication |

---

## 🚀 EVOLUTION ROADMAP

### Phase 1 (Weeks 1-2): **Stable & Reliable**
- [ ] Fix ChromaDB indexing (350 papers)
- [ ] Setup daily backups
- [ ] Replace OpenClaw (save 400MB)

### Phase 2 (Month 2-4): **Scalable**
- [ ] Add Redis caching
- [ ] Setup load balancer
- [ ] Add 2nd VPS instance
- [ ] Upgrade to 4 vCPU, 8GB RAM

### Phase 3 (Month 5-12): **Enterprise**
- [ ] Microservices architecture
- [ ] Multi-region deployment
- [ ] Auto-scaling
- [ ] Advanced monitoring

---

## 🎯 CONCLUSION

**For Current Scale (<100 users):** ✅ **EXCELLENT**
- Clean architecture
- Good automation
- Cost-effective

**For Future Scale (>1000 users):** ❌ **NEEDS IMPROVEMENT**
- Single point of failure
- Limited resources
- No scaling strategy

---

## 📞 IMMEDIATE ACTIONS

1. **Fix ChromaDB** (Day 1): Sync + index 350 papers
2. **Setup Backup** (Day 1): Daily ChromaDB backups
3. **Monitor** (Day 2): Add basic monitoring
4. **Replace OpenClaw** (Day 3): Save 400MB RAM

---

**Last Updated:** 2026-05-02
**Status:** Current architecture analyzed
**Next Steps:** Implement Phase 1 improvements
