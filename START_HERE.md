# RustDesk 服务器管理 - 从这里开始

## ⚡ 最常用：添加IP到白名单

**客户端使用（推荐）：**
```bash
# Mac/Linux
./auto_report_ip_client.sh

# Windows
双击运行 auto_report_ip_client.bat
```

详细说明：`IP自动上报-使用指南.md`

---

# Fix Sluggish RustDesk Connection

## 🚀 Quick Fix (5 Minutes)

### Do These 3 Things Right Now:

1. **Use Wired Connection (Both Computers)**
   - Unplug WiFi, connect Ethernet cable
   - Impact: -20 to -50ms latency

2. **Lower Video Quality**
   - In RustDesk: Set to 720p @ 20fps
   - Impact: Smoother, more stable

3. **Close These Apps (Both Computers)**
   - ❌ YouTube, Netflix, B站
   - ❌ Downloads, torrents, 迅雷
   - ❌ Cloud sync (OneDrive, Dropbox, 百度网盘)

**Then test your connection. If still slow, continue below.**

---

## 🔧 Server Optimization (10 Minutes)

Run this script to optimize your server:

```bash
./optimize_server.sh
```

This will:
- Increase network buffers (128MB → 256MB)
- Optimize TCP for long distance
- Enable TCP Fast Open (saves ~177ms per connection)
- Restart services with better settings

**Expected improvement: 10-20% lower latency**

---

## 💻 Client Optimization (30 Minutes)

Follow the guide for your operating system:

**File:** [optimize_client.md](optimize_client.md)

### Windows:
- Optimize network adapter settings
- Disable visual effects
- Add RustDesk to antivirus exclusions
- Optimize TCP settings

### macOS:
- Increase network buffers
- Disable transparency effects
- Increase RustDesk priority

### Both:
- Configure router QoS
- Change DNS servers
- Optimize RustDesk settings

**Expected improvement: 20-30% better performance**

---

## 📊 Test & Verify

### Before Optimizations:
```bash
./diagnose_local.sh > before.txt
./diagnose_server.sh >> before.txt
```

### After Optimizations:
```bash
./diagnose_local.sh > after.txt
./diagnose_server.sh >> after.txt
```

### Compare:
```bash
diff before.txt after.txt
```

---

## 📚 Detailed Guides

### Complete Fix Guide:
**File:** [FIX_SLUGGISH_CONNECTION.md](FIX_SLUGGISH_CONNECTION.md)

Covers:
- All server-side fixes
- All client-side fixes
- Network-level fixes
- Advanced optimizations
- Testing procedures

### Client Optimization:
**File:** [optimize_client.md](optimize_client.md)

Step-by-step for:
- Windows optimizations
- macOS optimizations
- Router configuration
- RustDesk settings

### Troubleshooting:
**File:** [TROUBLESHOOTING_GUIDE.md](TROUBLESHOOTING_GUIDE.md)

For when things don't work:
- Common issues
- Decision trees
- When to upgrade
- Cost vs performance

---

## 🎯 Expected Results

### After Quick Fix (5 min):
- Latency: 177ms → 160ms
- Stability: Much better
- Subjective: Noticeably smoother

### After Server Optimization (15 min):
- Latency: 160ms → 150ms
- Throughput: +20-30%
- Connection: More stable

### After Client Optimization (45 min):
- Latency: 150ms → 140ms
- Responsiveness: Much better
- Overall: 30-50% improvement

---

## ⚠️ Important Notes

### If Only Slow at Night (6pm-2am HKT):
This is **ISP congestion** during peak hours. You can't fix this, but you can:
- Use lower quality during peak hours (480p @ 15fps)
- Use during off-peak hours when possible
- Try VPN (may or may not help)

### If Slow All the Time:
Follow the optimization guides above. The issue is likely:
- WiFi quality (use wired)
- Client settings (lower quality)
- Background apps (close them)

### If Still Slow After Everything:
1. Test from different network (mobile hotspot)
2. Test at different times (morning vs evening)
3. Consider upgrading server to e2-medium (+$14/month)
4. Consider VPN for better routing ($5-15/month)

---

## 📋 Quick Checklist

### Immediate (5 min):
- [ ] Wired connection (both computers)
- [ ] Lower video quality (720p @ 20fps)
- [ ] Close bandwidth-heavy apps

### Server (10 min):
- [ ] Run `./optimize_server.sh`
- [ ] Verify services restarted
- [ ] Test connection

### Client (30 min):
- [ ] Follow `optimize_client.md`
- [ ] Optimize network settings
- [ ] Configure router QoS
- [ ] Test connection

### Verify (5 min):
- [ ] Run diagnostics before/after
- [ ] Test actual usage
- [ ] Document improvements

---

## 🆘 Need Help?

### Run Diagnostics:
```bash
# Test network
./diagnose_local.sh

# Test server
./diagnose_server.sh

# Both
./diagnose_connection.sh
```

### Check Current Status:
```bash
# Server status
./vm_manager.sh status

# Verify installation
./verify_installation.sh
```

### View Logs:
```bash
# If you set up monitoring
~/rustdesk_logs/analyze_performance.sh
```

---

## 📖 All Documentation

1. **START_HERE.md** ← You are here
2. **FIX_SLUGGISH_CONNECTION.md** - Complete fix guide
3. **optimize_client.md** - Client-side optimizations
4. **TROUBLESHOOTING_GUIDE.md** - When things don't work
5. **DIAGNOSIS_RESULTS.md** - Your current system status
6. **IMPROVEMENT_PLAN.md** - Long-term improvements

---

## Summary

**Current Status:**
- Network: 177ms latency, 0% packet loss ✅
- Server: e2-small, 0% CPU, 24% memory ✅
- Optimizations: BBR enabled, UDP buffers set ✅

**To Fix Sluggishness:**
1. Quick fixes (5 min) → 10-20% better
2. Server optimization (10 min) → +10-20% better
3. Client optimization (30 min) → +20-30% better
4. **Total: 30-60% improvement**

**Start with the quick fixes, then optimize server, then client.**

**Expected total time: 45 minutes**  
**Expected improvement: 30-60% better performance**  
**Cost: $0**
