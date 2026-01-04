#!/bin/bash

# 服务器端：自动接收并添加IP到白名单
# 用法: ./auto_update_ip_server.sh start  (启动API服务)
#      ./auto_update_ip_server.sh stop   (停止API服务)

PORT=8888
SECRET_KEY="RDhHSjQoKjc0RUc3RFNLLi91cGRhdGUtcGhvbmVzLnNoQA=="  # 修改为强密码
LOG_FILE="$HOME/rustdesk_auto_ip.log"  # 使用用户目录，避免权限问题

start_server() {
    echo "启动自动IP更新服务..."
    
    # 创建临时Python脚本
    cat > /tmp/rustdesk_ip_api.py << 'PYEOF'
#!/usr/bin/env python3
import http.server
import socketserver
import json
import subprocess
import os
import re
import ipaddress
import signal
import sys
from datetime import datetime
from threading import Lock

PORT = int(os.environ.get('PORT', 8888))
SECRET_KEY = os.environ.get('SECRET_KEY', 'your-secret-key-change-this')
LOG_FILE = os.environ.get('LOG_FILE', os.path.expanduser('~/rustdesk_auto_ip.log'))

# 全局锁，防止并发修改防火墙
firewall_lock = Lock()

# 请求计数器（防止滥用）
request_counter = {}
MAX_REQUESTS_PER_IP = 100  # 每个IP每小时最多100次请求

def signal_handler(sig, frame):
    log_message("🛑 Received shutdown signal, stopping gracefully...")
    sys.exit(0)

signal.signal(signal.SIGINT, signal_handler)
signal.signal(signal.SIGTERM, signal_handler)

def log_message(msg):
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    log_entry = f"[{timestamp}] {msg}\n"
    print(log_entry.strip())
    try:
        with open(LOG_FILE, 'a') as f:
            f.write(log_entry)
    except Exception as e:
        print(f"Warning: Failed to write log: {e}")

def validate_ip(ip):
    """验证IP地址格式"""
    try:
        ipaddress.ip_address(ip)
        return True
    except ValueError:
        return False

def is_private_ip(ip):
    """检查是否为私有IP"""
    try:
        return ipaddress.ip_address(ip).is_private
    except ValueError:
        return False

def check_rate_limit(client_ip):
    """检查请求频率限制"""
    current_hour = datetime.now().strftime('%Y-%m-%d-%H')
    key = f"{client_ip}:{current_hour}"
    
    if key not in request_counter:
        request_counter[key] = 0
    
    request_counter[key] += 1
    
    # 清理旧的计数器
    keys_to_delete = [k for k in request_counter.keys() if not k.endswith(current_hour)]
    for k in keys_to_delete:
        del request_counter[k]
    
    return request_counter[key] <= MAX_REQUESTS_PER_IP

def add_ip_to_firewall(ip, device_id):
    """添加IP到防火墙白名单（带锁保护）"""
    with firewall_lock:
        try:
            # 验证IP格式
            if not validate_ip(ip):
                log_message(f"❌ Invalid IP format: {ip} (device: {device_id})")
                return False
            
            # 拒绝私有IP
            if is_private_ip(ip):
                log_message(f"❌ Private IP rejected: {ip} (device: {device_id})")
                return False
            
            # 获取当前白名单（带重试）
            max_retries = 3
            for attempt in range(max_retries):
                try:
                    result = subprocess.run(
                        ['gcloud', 'compute', 'firewall-rules', 'describe', 
                         'rustdesk-whitelist-complete', '--format=value(sourceRanges)'],
                        capture_output=True, text=True, check=True, timeout=30
                    )
                    current_ips = result.stdout.strip().replace(';', ',')
                    break
                except subprocess.TimeoutExpired:
                    if attempt < max_retries - 1:
                        log_message(f"⚠️  Timeout getting firewall rules, retrying... ({attempt+1}/{max_retries})")
                        continue
                    else:
                        raise
            
            # 检查IP是否已存在
            if f"{ip}/32" in current_ips or ip in current_ips:
                log_message(f"ℹ️  IP {ip} already in whitelist (device: {device_id})")
                return True
            
            # 添加新IP（带重试）
            new_ips = f"{current_ips},{ip}/32"
            for attempt in range(max_retries):
                try:
                    subprocess.run(
                        ['gcloud', 'compute', 'firewall-rules', 'update', 
                         'rustdesk-whitelist-complete', f'--source-ranges={new_ips}', '--quiet'],
                        check=True, capture_output=True, timeout=60
                    )
                    break
                except subprocess.TimeoutExpired:
                    if attempt < max_retries - 1:
                        log_message(f"⚠️  Timeout updating firewall, retrying... ({attempt+1}/{max_retries})")
                        continue
                    else:
                        raise
            
            log_message(f"✅ Added IP {ip} to whitelist (device: {device_id})")
            return True
            
        except subprocess.CalledProcessError as e:
            error_msg = e.stderr.decode('utf-8') if e.stderr and isinstance(e.stderr, bytes) else str(e.stderr) if e.stderr else str(e)
            log_message(f"❌ Failed to add IP {ip}: {error_msg}")
            return False
        except Exception as e:
            log_message(f"❌ Unexpected error adding IP {ip}: {str(e)}")
            return False

class IPUpdateHandler(http.server.BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        pass  # 禁用默认日志
    
    def send_json_response(self, status_code, data):
        """发送JSON响应"""
        self.send_response(status_code)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(data).encode('utf-8'))
    
    def do_POST(self):
        client_ip = self.client_address[0]
        
        if self.path != '/update-ip':
            self.send_json_response(404, {'error': 'Not found'})
            return
        
        try:
            # 检查请求频率限制
            if not check_rate_limit(client_ip):
                log_message(f"⚠️  Rate limit exceeded for {client_ip}")
                self.send_json_response(429, {'error': 'Too many requests'})
                return
            
            # 读取请求体
            content_length = int(self.headers.get('Content-Length', 0))
            if content_length == 0:
                self.send_json_response(400, {'error': 'Empty request body'})
                return
            
            if content_length > 10240:  # 最大10KB
                self.send_json_response(413, {'error': 'Request too large'})
                return
            
            post_data = self.rfile.read(content_length)
            
            # 解析JSON
            try:
                data = json.loads(post_data.decode('utf-8'))
            except json.JSONDecodeError as e:
                log_message(f"❌ Invalid JSON from {client_ip}: {e}")
                self.send_json_response(400, {'error': 'Invalid JSON'})
                return
            
            # 验证必需字段
            if not isinstance(data, dict):
                self.send_json_response(400, {'error': 'Invalid data format'})
                return
            
            secret = data.get('secret', '')
            ip = data.get('ip', '')
            device_id = data.get('device_id', 'unknown')
            
            # 验证密钥
            if not secret or secret != SECRET_KEY:
                log_message(f"❌ Invalid secret key from {client_ip} (device: {device_id})")
                self.send_json_response(403, {'error': 'Invalid secret key'})
                return
            
            # 验证IP
            if not ip:
                self.send_json_response(400, {'error': 'IP address required'})
                return
            
            # 验证device_id（允许中文、字母、数字、-_，最长100字符）
            if not device_id or len(device_id) > 100:
                log_message(f"❌ Invalid device_id from {client_ip}: {device_id}")
                self.send_json_response(400, {'error': 'Invalid device_id'})
                return
            
            # 添加IP到防火墙
            log_message(f"📥 Request from {client_ip}: add {ip} (device: {device_id})")
            success = add_ip_to_firewall(ip, device_id)
            
            if success:
                self.send_json_response(200, {
                    'status': 'success',
                    'ip': ip,
                    'device_id': device_id,
                    'timestamp': datetime.now().isoformat()
                })
            else:
                self.send_json_response(500, {'error': 'Failed to add IP'})
                
        except Exception as e:
            log_message(f"❌ Error processing request from {client_ip}: {e}")
            self.send_json_response(500, {'error': 'Internal server error'})
    
    def do_GET(self):
        if self.path == '/health':
            self.send_json_response(200, {
                'status': 'ok',
                'timestamp': datetime.now().isoformat(),
                'version': '1.0'
            })
        else:
            self.send_json_response(404, {'error': 'Not found'})

log_message("🚀 Starting RustDesk Auto IP Update Service")
log_message(f"Listening on port {PORT}")
log_message(f"Log file: {LOG_FILE}")
log_message(f"Rate limit: {MAX_REQUESTS_PER_IP} requests per hour per IP")

class ReuseAddrTCPServer(socketserver.TCPServer):
    allow_reuse_address = True
    
    def server_bind(self):
        self.socket.setsockopt(socketserver.socket.SOL_SOCKET, socketserver.socket.SO_REUSEADDR, 1)
        super().server_bind()

try:
    with ReuseAddrTCPServer(("", PORT), IPUpdateHandler) as httpd:
        log_message("✅ Service started successfully")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            log_message("🛑 Service stopped by user")
except OSError as e:
    if e.errno == 98:  # Address already in use
        log_message(f"❌ Port {PORT} is already in use. Stop the existing service first.")
        sys.exit(1)
    else:
        log_message(f"❌ Failed to start service: {e}")
        sys.exit(1)
except Exception as e:
    log_message(f"❌ Unexpected error: {e}")
    sys.exit(1)
PYEOF

    chmod +x /tmp/rustdesk_ip_api.py
    
    # 启动服务
    export PORT=$PORT
    export SECRET_KEY=$SECRET_KEY
    export LOG_FILE=$LOG_FILE
    
    nohup python3 /tmp/rustdesk_ip_api.py > /dev/null 2>&1 &
    echo $! > /tmp/rustdesk_ip_api.pid
    
    echo "✅ 服务已启动在端口 $PORT"
    echo "PID: $(cat /tmp/rustdesk_ip_api.pid)"
    echo "日志: $LOG_FILE"
    echo ""
    echo "⚠️  重要：修改 SECRET_KEY 为强密码！"
    echo "编辑此文件，修改第6行的 SECRET_KEY"
}

stop_server() {
    if [ -f /tmp/rustdesk_ip_api.pid ]; then
        PID=$(cat /tmp/rustdesk_ip_api.pid)
        kill $PID 2>/dev/null
        rm /tmp/rustdesk_ip_api.pid
        echo "✅ 服务已停止"
    else
        echo "服务未运行"
    fi
}

status_server() {
    if [ -f /tmp/rustdesk_ip_api.pid ]; then
        PID=$(cat /tmp/rustdesk_ip_api.pid)
        if ps -p $PID > /dev/null; then
            echo "✅ 服务运行中 (PID: $PID)"
            echo "端口: $PORT"
            echo "日志: $LOG_FILE"
        else
            echo "❌ 服务已停止（PID文件存在但进程不存在）"
            rm /tmp/rustdesk_ip_api.pid
        fi
    else
        echo "❌ 服务未运行"
    fi
}

case "$1" in
    start)
        start_server
        ;;
    stop)
        stop_server
        ;;
    restart)
        stop_server
        sleep 2
        start_server
        ;;
    status)
        status_server
        ;;
    *)
        echo "用法: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac
