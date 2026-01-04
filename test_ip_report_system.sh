#!/bin/bash

# 测试自动IP上报系统
# 用法: ./test_ip_report_system.sh

echo "=========================================="
echo "测试自动IP上报系统"
echo "=========================================="
echo ""

# 测试1: 检查服务器API服务状态
echo "测试1: 检查服务器API服务..."
response=$(gcloud compute ssh myserver --zone=asia-east2-c --command="ps aux | grep rustdesk_ip_api | grep -v grep" 2>&1)

if echo "$response" | grep -q "rustdesk_ip_api.py"; then
    echo "✅ API服务正在运行"
else
    echo "❌ API服务未运行"
    echo "请在服务器上运行: ./auto_update_ip_server.sh start"
    exit 1
fi
echo ""

# 测试2: 测试健康检查端点
echo "测试2: 测试健康检查端点..."
health_response=$(curl -s --connect-timeout 5 http://34.96.199.184:8888/health 2>&1)

if echo "$health_response" | grep -q '"status".*:.*"ok"'; then
    echo "✅ 健康检查通过"
    echo "   响应: $health_response"
else
    echo "❌ 健康检查失败"
    echo "   响应: $health_response"
    exit 1
fi
echo ""

# 测试3: 获取当前IP
echo "测试3: 获取当前公网IP..."
CURRENT_IP=$(curl -s --connect-timeout 5 https://api.ipify.org 2>/dev/null)

if [ -z "$CURRENT_IP" ]; then
    echo "❌ 无法获取公网IP"
    exit 1
fi

echo "✅ 当前IP: $CURRENT_IP"
echo ""

# 测试4: 检查IP是否在白名单
echo "测试4: 检查IP是否在白名单..."
whitelist=$(gcloud compute firewall-rules describe rustdesk-whitelist-complete --format="value(sourceRanges)" 2>&1)

if echo "$whitelist" | grep -q "$CURRENT_IP"; then
    echo "✅ IP已在白名单中"
else
    echo "⚠️  IP不在白名单中（这是正常的，如果是第一次运行）"
fi
echo ""

# 测试5: 运行客户端脚本
echo "测试5: 运行客户端上报脚本..."
echo "----------------------------------------"
./auto_report_ip_client.sh
echo "----------------------------------------"
echo ""

# 测试6: 验证IP已添加
echo "测试6: 验证IP已添加到白名单..."
sleep 2  # 等待防火墙规则生效

whitelist_after=$(gcloud compute firewall-rules describe rustdesk-whitelist-complete --format="value(sourceRanges)" 2>&1)

if echo "$whitelist_after" | grep -q "$CURRENT_IP"; then
    echo "✅ IP已成功添加到白名单"
else
    echo "❌ IP未添加到白名单"
    exit 1
fi
echo ""

# 测试7: 查看服务器日志
echo "测试7: 查看服务器最近的日志..."
echo "----------------------------------------"
gcloud compute ssh myserver --zone=asia-east2-c --command="tail -5 ~/rustdesk_auto_ip.log" 2>&1 | grep -v "^Updates are available"
echo "----------------------------------------"
echo ""

# 总结
echo "=========================================="
echo "✅ 所有测试通过！"
echo "=========================================="
echo ""
echo "系统状态:"
echo "  - API服务: 运行中"
echo "  - 当前IP: $CURRENT_IP"
echo "  - 白名单: 已包含"
echo ""
echo "现在可以使用RustDesk连接了！"
echo "  ID服务器: 34.96.199.184"
echo "  中继服务器: 34.96.199.184"
