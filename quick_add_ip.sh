#!/bin/bash

# 快速添加当前IP到RustDesk白名单
# 最简单的方式 - 一键添加

echo "正在检测当前IP..."
CURRENT_IP=$(curl -s https://api.ipify.org)

if [ -z "$CURRENT_IP" ]; then
    echo "✗ 无法检测IP"
    echo "请手动运行: ./add_rustdesk_access.sh"
    exit 1
fi

echo "检测到IP: $CURRENT_IP"
echo ""
read -p "是否添加此IP到RustDesk白名单? (y/n): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "已取消"
    exit 0
fi

echo ""
echo "正在添加到防火墙..."

# 添加到主白名单
CURRENT_IPS=$(gcloud compute firewall-rules describe rustdesk-whitelist-complete --format="value(sourceRanges)" | tr ';' ',')
gcloud compute firewall-rules update rustdesk-whitelist-complete \
    --source-ranges="$CURRENT_IPS,$CURRENT_IP/32" --quiet

# 添加到443端口规则
CURRENT_443=$(gcloud compute firewall-rules describe rustdesk-port-443 --format="value(sourceRanges)" | tr ';' ',')
gcloud compute firewall-rules update rustdesk-port-443 \
    --source-ranges="$CURRENT_443,$CURRENT_IP/32" --quiet

echo ""
echo "✅ 完成！"
echo ""
echo "已添加 $CURRENT_IP 到白名单"
echo "现在可以连接RustDesk了"
echo ""
echo "RustDesk配置:"
echo "  ID服务器: 34.96.199.184:443"
echo "  中继服务器: 34.96.199.184:443"
echo "  Key: pvf53UofpqXlskAxXP9k2KDNbHqZR5qqFVqZTLm26QM="
