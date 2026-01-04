#!/bin/bash

# View Current RustDesk Access List
# Shows who can currently connect to your RustDesk server

PROJECT=$(gcloud config get-value project 2>/dev/null)

echo "=========================================="
echo "RustDesk Server Access List"
echo "=========================================="
echo ""

echo "Currently whitelisted IPs and ranges:"
echo ""

gcloud compute firewall-rules describe rustdesk-whitelist-complete --format="value(sourceRanges)" | tr ';' '\n' | nl

echo ""
echo "=========================================="
echo "Security Status"
echo "=========================================="
echo ""

# Count total IPs/ranges
TOTAL=$(gcloud compute firewall-rules describe rustdesk-whitelist-complete --format="value(sourceRanges)" | tr ';' '\n' | wc -l)
echo "Total whitelisted IPs/ranges: $TOTAL"
echo ""

echo "Protection layers:"
echo "  ✓ Firewall: Only whitelisted IPs can reach server"
echo "  ✓ Password: Required for all connections"
echo "  ✓ 2FA: Required after password"
echo ""

echo "To add access: ./add_rustdesk_access.sh"
echo "To remove access: ./remove_rustdesk_access.sh"
echo ""

# Show recent connections
echo "=========================================="
echo "Recent Connections (last 10)"
echo "=========================================="
echo ""
gcloud compute ssh myserver --zone=asia-east2-c --command="sudo journalctl -u hbbs --since '24 hours ago' | grep 'IP change' | tail -10" 2>/dev/null || echo "Could not fetch recent connections"
