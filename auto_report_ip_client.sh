#!/bin/bash

# RustDesk IP自动上报工具 - Mac/Linux版
# 用法: ./auto_report_ip_client.sh
#      ./auto_report_ip_client.sh install  (安装定时任务)

SERVER_URL="http://34.96.199.184:8888/update-ip"
SECRET_KEY="RDhHSjQoKjc0RUc3RFNLLi91cGRhdGUtcGhvbmVzLnNoQA=="
IP_CACHE_FILE="$HOME/.rustdesk_last_ip"
LOG_FILE="$HOME/.rustdesk_ip_report.log"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

report_ip() {
    echo "============================================"
    echo "   RustDesk IP自动上报工具"
    echo "   设备名称: $(hostname)"
    echo "============================================"
    echo ""
    
    # 获取公网IP
    echo "正在获取公网IP..."
    CURRENT_IP=$(curl -s --max-time 10 https://api.ipify.org)
    
    if [ -z "$CURRENT_IP" ]; then
        echo "❌ 无法获取公网IP，请检查网络连接"
        log_message "ERROR: Failed to get public IP"
        return 1
    fi
    
    echo "✓ 当前公网IP: $CURRENT_IP"
    echo ""
    
    # 检查IP是否变化
    if [ -f "$IP_CACHE_FILE" ]; then
        LAST_IP=$(cat "$IP_CACHE_FILE")
        if [ "$CURRENT_IP" = "$LAST_IP" ]; then
            echo "ℹ️  IP未变化，跳过上报"
            return 0
        fi
    fi
    
    # 发送IP到服务器
    echo "正在发送IP到服务器..."
    
    RESPONSE=$(curl -s --max-time 15 -X POST "$SERVER_URL" \
        -H "Content-Type: application/json" \
        -d "{\"ip\":\"$CURRENT_IP\",\"device_id\":\"$(hostname)\",\"secret\":\"$SECRET_KEY\"}")
    
    if [ $? -eq 0 ]; then
        STATUS=$(echo "$RESPONSE" | grep -o '"status":"success"')
        if [ -n "$STATUS" ]; then
            echo "✅ IP已上报到服务器！"
            echo "$CURRENT_IP" > "$IP_CACHE_FILE"
            log_message "SUCCESS: IP reported: $CURRENT_IP"
            return 0
        else
            ERROR=$(echo "$RESPONSE" | grep -o '"error":"[^"]*"' | cut -d'"' -f4)
            echo "❌ 服务器返回错误: $ERROR"
            echo "   当前IP: $CURRENT_IP"
            log_message "ERROR: Server error: $ERROR (IP: $CURRENT_IP)"
            return 1
        fi
    else
        echo "❌ 无法连接服务器"
        echo "   当前IP: $CURRENT_IP"
        echo ""
        echo "请检查："
        echo "  1. 服务器是否运行了 auto_update_ip_server.sh start"
        echo "  2. 网络连接是否正常"
        echo "  3. 防火墙是否允许访问端口8888"
        log_message "ERROR: Failed to connect to server (IP: $CURRENT_IP)"
        return 1
    fi
}

install_cron() {
    echo "安装定时任务..."
    echo ""
    
    SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
    
    # 检查是否已安装
    if crontab -l 2>/dev/null | grep -q "$SCRIPT_PATH"; then
        echo "✅ 定时任务已存在"
        return 0
    fi
    
    # 添加到crontab（每小时运行一次）
    (crontab -l 2>/dev/null; echo "0 * * * * $SCRIPT_PATH >/dev/null 2>&1") | crontab -
    
    if [ $? -eq 0 ]; then
        echo "✅ 定时任务已安装"
        echo "   - 每小时自动检查IP变化"
        echo "   - 只在IP变化时上报"
        log_message "INFO: Cron job installed"
    else
        echo "❌ 安装定时任务失败"
        return 1
    fi
}

uninstall_cron() {
    echo "卸载定时任务..."
    
    SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
    
    crontab -l 2>/dev/null | grep -v "$SCRIPT_PATH" | crontab -
    
    if [ $? -eq 0 ]; then
        echo "✅ 定时任务已卸载"
        log_message "INFO: Cron job uninstalled"
    else
        echo "❌ 卸载定时任务失败"
        return 1
    fi
}

show_status() {
    echo "============================================"
    echo "   RustDesk IP自动上报 - 状态"
    echo "============================================"
    echo ""
    
    # 显示当前IP
    if [ -f "$IP_CACHE_FILE" ]; then
        LAST_IP=$(cat "$IP_CACHE_FILE")
        echo "上次上报IP: $LAST_IP"
    else
        echo "上次上报IP: (未上报过)"
    fi
    
    # 显示定时任务状态
    SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
    if crontab -l 2>/dev/null | grep -q "$SCRIPT_PATH"; then
        echo "定时任务: ✅ 已安装"
    else
        echo "定时任务: ❌ 未安装"
    fi
    
    # 显示最近日志
    if [ -f "$LOG_FILE" ]; then
        echo ""
        echo "最近日志（最后5条）："
        tail -5 "$LOG_FILE"
    fi
    
    echo ""
}

case "$1" in
    install)
        report_ip
        echo ""
        install_cron
        ;;
    uninstall)
        uninstall_cron
        ;;
    status)
        show_status
        ;;
    *)
        report_ip
        ;;
esac
