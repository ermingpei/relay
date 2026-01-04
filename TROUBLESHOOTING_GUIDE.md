# RustDesk Connection Troubleshooting Guide

## Quick Diagnosis

Run the diagnostic script first:
```bash
./diagnose_connection.sh
```

This will automatically check:
- Network latency and packet loss
- Server CPU and memory usage
- VM resource capacity
- Time-of-day patterns
- System optimizations

---

## Common Issues and Solutions

### Issue 1: Sluggish During China/HK Night Time (6pm-2am HKT)

**Symptoms:**
- Connection is fine during the day
- Becomes slow/laggy at night
- Audio cuts out or stutters

**Likely Cause:** Network congestion during peak hours

**Solutions:**

1. **Confirm it's time-based:**
   ```bash
   # Test during different times
   ./diagnose_connection.sh
   # Save results and compare
   ```

2. **Optimize for peak hours:**
   - Lower video quality to 480p @ 15fps
   - Use audio-only mode when possible
   - Close all bandwidth-heavy apps
   - Use wired connection instead of WiFi

3. **If problem persists:**
   - Consider using a VPN with better routing
   - Test from different network (mobile hotspot)
   - May need to accept peak-hour limitations

---

### Issue 2: Always Sluggish (Day and Night)

**Symptoms:**
- Consistently slow regardless of time
- High CPU usage on server
- Memory warnings

**Likely Cause:** Server resource constraints

**Check Current VM Type:**
```bash
# SSH to server
ssh qubitrhythm@34.96.199.184

# Check VM type
curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/machine-type | \
  awk -F'/' '{print $NF}'
```

**Solutions by VM Type:**

#### If using e2-micro (~$7/month):
```bash
# Upgrade to e2-small (recommended)
./upgrade_to_e2small.sh

# Benefits:
# - 2x baseline CPU (50% vs 25%)
# - 2x memory (2GB vs 1GB)
# - Cost: ~$14/month (still saves $37/month vs original)
```

#### If using e2-small (~$14/month):
- Should be adequate for 1-2 concurrent connections
- If still slow, upgrade to e2-medium:
```bash
gcloud compute instances stop myserver --zone=asia-east2-c
gcloud compute instances set-machine-type myserver \
  --machine-type=e2-medium --zone=asia-east2-c
gcloud compute instances start myserver --zone=asia-east2-c
```

#### If using e2-medium or higher:
- Resources should be plenty
- Issue is likely network-related
- Check network diagnostics section

---

### Issue 3: Audio Choppy/Cutting Out

**Symptoms:**
- Video is okay but audio stutters
- Audio drops completely
- Robotic/distorted audio

**Likely Cause:** UDP port issues or bandwidth saturation

**Solutions:**

1. **Verify UDP port 21116 is working:**
   ```bash
   # On server
   ssh qubitrhythm@34.96.199.184
   sudo tcpdump -i any port 21116 and udp -n
   # Should see packets when connected
   ```

2. **Check firewall:**
   ```bash
   # Verify GCP firewall
   gcloud compute firewall-rules describe rustdesk-relay-tcp-udp
   # Should include: udp:21116
   ```

3. **Prioritize audio over video:**
   - In RustDesk client: Lower video quality
   - Set to 480p @ 15fps or lower
   - Or disable video entirely (audio only)

4. **Check UDP buffer size:**
   ```bash
   # On server
   ssh qubitrhythm@34.96.199.184
   sudo sysctl net.core.rmem_max
   # Should be: 134217728 (128MB)
   
   # If not, fix it:
   sudo sysctl -w net.core.rmem_max=134217728
   sudo sysctl -w net.core.wmem_max=134217728
   ```

---

### Issue 4: High Latency (>250ms)

**Symptoms:**
- Noticeable delay in mouse/keyboard
- Ping times over 250ms
- Feels "laggy"

**Check Latency:**
```bash
# Test from your location
ping -c 20 34.96.199.184

# Look for:
# - Average latency (should be <200ms)
# - Packet loss (should be 0%)
# - Jitter/stddev (should be <30ms)
```

**Solutions:**

1. **If latency is consistently high (>250ms):**
   - This is the physical distance (China ↔ Canada)
   - Consider migrating VM closer to China:
   ```bash
   # Migrate to Hong Kong region
   ./vm_manager.sh migrate asia-east2-a
   ```

2. **If latency varies widely:**
   - Network path is unstable
   - Try different times of day
   - Consider VPN with better routing
   - Check local network quality

3. **If packet loss >1%:**
   - Network quality issue
   - Try wired connection
   - Check with ISP
   - Test from different network

---

### Issue 5: Connection Drops Frequently

**Symptoms:**
- Connection established but drops after a few minutes
- "Connection lost" errors
- Need to reconnect frequently

**Check Server Services:**
```bash
# Verify services are running
ssh qubitrhythm@34.96.199.184
sudo systemctl status rustdesk-hbbs rustdesk-hbbr

# Check for errors in logs
sudo journalctl -u rustdesk-hbbs -n 50
sudo journalctl -u rustdesk-hbbr -n 50
```

**Solutions:**

1. **If services are crashing:**
   ```bash
   # Restart services
   sudo systemctl restart rustdesk-hbbs rustdesk-hbbr
   
   # Check resource usage
   htop
   # Look for hbbs and hbbr processes
   ```

2. **If memory is full:**
   - Upgrade VM to larger size
   - Or restart services periodically

3. **If network is unstable:**
   - Check firewall isn't blocking
   - Verify all ports are open
   - Test with different network

---

## Resource Upgrade Decision Tree

```
Is connection sluggish?
│
├─ Only during China/HK night (6pm-2am)?
│  └─ YES → Network congestion (ISP issue)
│     └─ Solution: Lower quality, use off-peak hours
│
└─ NO → Sluggish all the time?
   │
   ├─ Check VM type:
   │  │
   │  ├─ e2-micro?
   │  │  └─ Upgrade to e2-small ($14/month)
   │  │     └─ Run: ./upgrade_to_e2small.sh
   │  │
   │  ├─ e2-small?
   │  │  └─ Check CPU usage:
   │  │     ├─ >80%? → Upgrade to e2-medium ($28/month)
   │  │     └─ <80%? → Network issue, not resources
   │  │
   │  └─ e2-medium or higher?
   │     └─ Resources are fine, check network
   │
   └─ Network diagnostics:
      └─ Run: ./diagnose_connection.sh
```

---

## Cost vs Performance Guide

### Current Options:

| VM Type | vCPU | RAM | Cost/Month | Best For |
|---------|------|-----|------------|----------|
| e2-micro | 0.25-2 (25% baseline) | 1GB | ~$7 | Testing only |
| e2-small | 0.5-2 (50% baseline) | 2GB | ~$14 | 1-2 users ⭐ |
| e2-medium | 1-2 (100% baseline) | 4GB | ~$28 | 3-5 users |
| e2-custom-2-1024 | 2 vCPU | 1GB | ~$51 | Overkill |

### Recommendations:

**For 1-2 concurrent users (your case):**
- **Best choice:** e2-small (~$14/month)
- Saves $37/month vs original e2-custom
- Adequate CPU and memory
- Good balance of cost and performance

**If experiencing issues with e2-small:**
- Upgrade to e2-medium (~$28/month)
- Still saves $23/month vs original
- Plenty of headroom for peak usage

**Don't use e2-micro for production:**
- Only 25% CPU baseline (gets throttled)
- Only 1GB RAM (may run out)
- Save $7/month but poor experience

---

## Monitoring Commands

### Real-Time Monitoring (Run on Server):

```bash
# 1. Watch CPU and memory
ssh qubitrhythm@34.96.199.184
htop
# Press F4 to filter: "hbb" to see only RustDesk processes

# 2. Monitor network traffic
sudo iftop -i any -f "port 21116 or port 21117"
# Shows bandwidth usage per connection

# 3. Watch UDP packets (audio)
sudo tcpdump -i any port 21116 and udp -n
# Should see continuous packets when audio is active

# 4. Check active connections
sudo ss -tn | grep -E '2111[5-9]'
# Shows all active RustDesk connections
```

### Client-Side Monitoring:

```bash
# 1. Continuous ping test
ping 34.96.199.184 | while read line; do 
  echo "$(date +%H:%M:%S): $line"
done | tee ping_log.txt

# 2. Run diagnostics periodically
while true; do
  echo "=== $(date) ===" >> diagnostics_log.txt
  ./diagnose_connection.sh >> diagnostics_log.txt 2>&1
  sleep 300  # Every 5 minutes
done
```

---

## Quick Fixes Checklist

When experiencing sluggishness, try these in order:

### Client Side (Do First):
- [ ] Close all bandwidth-heavy applications
- [ ] Switch to wired connection (not WiFi)
- [ ] Lower RustDesk video quality to 480p @ 15fps
- [ ] Disable video, use audio only
- [ ] Restart RustDesk client
- [ ] Test from different network (mobile hotspot)

### Server Side (If Client Fixes Don't Help):
- [ ] Run diagnostics: `./diagnose_connection.sh`
- [ ] Check CPU usage: Should be <80%
- [ ] Check memory usage: Should be <85%
- [ ] Restart services if needed:
  ```bash
  ssh qubitrhythm@34.96.199.184
  sudo systemctl restart rustdesk-hbbs rustdesk-hbbr
  ```
- [ ] Consider VM upgrade if resources are maxed

### Network (If Both Above Don't Help):
- [ ] Test at different times of day
- [ ] Check if time-based pattern (peak vs off-peak)
- [ ] Test latency: `ping -c 50 34.96.199.184`
- [ ] Check packet loss (should be 0%)
- [ ] Consider VPN or different routing

---

## Getting Help

### Information to Collect:

When asking for help, provide:

1. **Diagnostic report:**
   ```bash
   ./diagnose_connection.sh > diagnostics.txt 2>&1
   ```

2. **Time of issue:**
   - Date and time (include timezone)
   - Duration of problem
   - Frequency (always, sometimes, specific times)

3. **VM configuration:**
   ```bash
   ssh qubitrhythm@34.96.199.184
   curl -s -H "Metadata-Flavor: Google" \
     http://metadata.google.internal/computeMetadata/v1/instance/machine-type | \
     awk -F'/' '{print $NF}'
   ```

4. **Network test results:**
   ```bash
   ping -c 50 34.96.199.184 > ping_results.txt
   ```

5. **Server resource usage:**
   ```bash
   ssh qubitrhythm@34.96.199.184
   top -bn1 | head -20 > server_resources.txt
   free -m >> server_resources.txt
   ```

---

## Related Documentation

- [diagnose_connection.sh](./diagnose_connection.sh) - Automated diagnostics
- [upgrade_to_e2small.sh](./upgrade_to_e2small.sh) - Upgrade VM resources
- [VM_MANAGEMENT_GUIDE.md](./VM_MANAGEMENT_GUIDE.md) - VM management
- [ARCHITECTURE.md](./ARCHITECTURE.md) - System architecture
- [verify_installation.sh](./verify_installation.sh) - Verify setup
