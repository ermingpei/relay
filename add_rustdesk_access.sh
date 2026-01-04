#!/bin/bash

# 添加新IP到RustDesk防火墙白名单
# 当你换地方需要连接RustDesk时使用

PROJECT=$(gcloud config get-value project 2>/dev/null)

echo "=========================================="
echo "添加RustDesk访问权限"
echo "=========================================="
echo ""

# 获取当前白名单
get_current_ips() {
    gcloud compute firewall-rules describe rustdesk-whitelist-complete --format="value(sourceRanges)" | tr ';' '\n'
}

# 添加IP到两个防火墙规则
add_ip_to_firewall() {
    local NEW_IP=$1
    
    echo "正在添加 $NEW_IP 到防火墙..."
    
    # 1. 添加到主白名单（21115-21119端口）
    CURRENT_IPS=$(gcloud compute firewall-rules describe rustdesk-whitelist-complete --format="value(sourceRanges)" | tr ';' ',')
    gcloud compute firewall-rules update rustdesk-whitelist-complete \
        --source-ranges="$CURRENT_IPS,$NEW_IP/32" --quiet
    
    # 2. 添加到443端口规则
    CURRENT_443=$(gcloud compute firewall-rules describe rustdesk-port-443 --format="value(sourceRanges)" | tr ';' ',')
    gcloud compute firewall-rules update rustdesk-port-443 \
        --source-ranges="$CURRENT_443,$NEW_IP/32" --quiet
    
    echo "✓ 已添加 $NEW_IP 到所有防火墙规则"
}

# 显示当前白名单
echo "当前白名单中的IP:"
get_current_ips | nl
echo ""

# 选项1: 自动检测当前IP
echo "选项1: 自动添加当前电脑的IP"
read -p "是否添加当前电脑的IP? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "正在检测当前IP..."
    CURRENT_IP=$(curl -s https://api.ipify.org)
    if [ -n "$CURRENT_IP" ]; then
        echo "检测到IP: $CURRENT_IP"
        add_ip_to_firewall "$CURRENT_IP"
        echo ""
        echo "✅ 完成！现在可以连接RustDesk了"
    else
        echo "✗ 无法检测IP，请手动输入"
    fi
fi

# 选项2: 手动输入IP
echo ""
echo "选项2: 手动输入IP地址"
echo "  提示: 访问 https://api.ipify.org 查看IP"
echo ""
read -p "输入IP地址 (或按Enter跳过): " NEW_IP

if [ -n "$NEW_IP" ]; then
    add_ip_to_firewall "$NEW_IP"
    echo ""
    echo "✅ 完成！"
fi

# 选项3: 添加IP段
echo ""
echo "选项3: 添加整个IP段 (适用于公司网络)"
read -p "输入IP段 (如 192.168.1.0/24) 或按Enter跳过: " NEW_RANGE

if [ -n "$NEW_RANGE" ]; then
    echo "正在添加IP段 $NEW_RANGE..."
    
    CURRENT_IPS=$(gcloud compute firewall-rules describe rustdesk-whitelist-complete --format="value(sourceRanges)" | tr ';' ',')
    gcloud compute firewall-rules update rustdesk-whitelist-complete \
        --source-ranges="$CURRENT_IPS,$NEW_RANGE" --quiet
    
    CURRENT_443=$(gcloud compute firewall-rules describe rustdesk-port-443 --format="value(sourceRanges)" | tr ';' ',')
    gcloud compute firewall-rules update rustdesk-port-443 \
        --source-ranges="$CURRENT_443,$NEW_RANGE" --quiet
    
    echo "✓ 已添加IP段 $NEW_RANGE"
fi

echo ""
echo "=========================================="
echo "更新后的白名单"
echo "=========================================="
get_current_ips | nl
echo ""
echo "查看访问列表: ./view_rustdesk_access.sh"
echo "删除IP: ./remove_rustdesk_access.sh"
