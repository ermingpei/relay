#!/bin/bash

# Remove IP from RustDesk Firewall Whitelist
# Use this when you want to revoke someone's access

PROJECT=$(gcloud config get-value project 2>/dev/null)

echo "=========================================="
echo "Remove RustDesk Access"
echo "=========================================="
echo ""

# Function to get current whitelist
get_current_ips() {
    gcloud compute firewall-rules describe rustdesk-whitelist-complete --format="value(sourceRanges)" | tr ';' '\n'
}

# Show current whitelist
echo "Current whitelisted IPs/ranges:"
get_current_ips | nl
echo ""

read -p "Enter the IP or range to remove (exactly as shown above): " REMOVE_IP

if [ -z "$REMOVE_IP" ]; then
    echo "No IP entered. Exiting."
    exit 0
fi

echo ""
echo "Removing $REMOVE_IP from whitelist..."

# Get current IPs and remove the specified one
CURRENT_IPS=$(gcloud compute firewall-rules describe rustdesk-whitelist-complete --format="value(sourceRanges)" | tr ';' ',')
NEW_IPS=$(echo "$CURRENT_IPS" | tr ',' '\n' | grep -v "^$REMOVE_IP$" | tr '\n' ',' | sed 's/,$//')

if [ "$CURRENT_IPS" = "$NEW_IPS," ]; then
    echo "✗ IP not found in whitelist"
    exit 1
fi

# Update firewall rule
gcloud compute firewall-rules update rustdesk-whitelist-complete \
    --source-ranges="$NEW_IPS" && \
    echo "✓ Removed $REMOVE_IP from whitelist" || echo "✗ Failed to remove IP"

echo ""
echo "=========================================="
echo "Updated Whitelist"
echo "=========================================="
get_current_ips | nl
echo ""
echo "✅ Done! $REMOVE_IP can no longer connect to your RustDesk server."
