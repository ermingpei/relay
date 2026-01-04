# IP自动上报系统 - 使用指南

## 🎯 快速开始

### 客户端使用（最重要）

**Mac/Linux:**
```bash
./auto_report_ip_client.sh
```

**Windows:**
双击运行 `auto_report_ip_client.bat`

**什么时候运行？**
- IP地址变化时（换网络、重启路由器）
- 无法连接RustDesk时
- 到新地方（咖啡店、酒店等）

---

## 📋 系统架构

```
客户端（只需curl）          服务器（GCP）
      |                         |
      | 检测IP并上报            |
      |------------------------>| 验证密钥
      |                         | 添加到防火墙
      |<------------------------|
      | 返回成功                |
```

**优势：**
- ✅ 客户端无需gcloud SDK
- ✅ 客户端无需GCP权限
- ✅ 只需要一个密钥
- ✅ 实时响应

---

## 🔧 服务器管理

### 基本命令
```bash
./auto_update_ip_server.sh start    # 启动服务
./auto_update_ip_server.sh status   # 检查状态
./auto_update_ip_server.sh restart  # 重启服务
tail -f ~/rustdesk_auto_ip.log      # 查看日志
```

### 修改密钥（重要）
1. 编辑 `auto_update_ip_server.sh`，修改第6行：
   ```bash
   SECRET_KEY="your-strong-password"
   ```
2. 重启服务：`./auto_update_ip_server.sh restart`
3. 更新所有客户端脚本的SECRET_KEY

---

## 🧪 测试

```bash
# 完整测试
./test_ip_report_system.sh

# 快速测试
curl http://34.96.199.184:8888/health
```

---

## 🔄 自动化（可选）

### Mac - launchd
创建 `~/Library/LaunchAgents/com.rustdesk.ipreport.plist`：
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.rustdesk.ipreport</string>
    <key>ProgramArguments</key>
    <array>
        <string>/完整路径/auto_report_ip_client.sh</string>
    </array>
    <key>StartInterval</key>
    <integer>3600</integer>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
```

加载：`launchctl load ~/Library/LaunchAgents/com.rustdesk.ipreport.plist`

### Windows - 任务计划程序
1. 打开"任务计划程序"
2. 创建基本任务 → 触发器：每小时
3. 操作：启动 `auto_report_ip_client.bat`

---

## 🆘 故障排除

### 客户端无法连接
```bash
./auto_update_ip_server.sh status
curl http://34.96.199.184:8888/health
```

### 密钥错误
确保服务器端和客户端的SECRET_KEY完全一致

### IP未添加
```bash
tail -20 ~/rustdesk_auto_ip.log
```

---

## 📞 常用命令

| 操作 | 命令 |
|------|------|
| 客户端上报IP | `./auto_report_ip_client.sh` |
| 服务器状态 | `./auto_update_ip_server.sh status` |
| 查看日志 | `tail -f ~/rustdesk_auto_ip.log` |
| 查看白名单 | `./view_rustdesk_access.sh` |
| 测试系统 | `./test_ip_report_system.sh` |

---

## 🎯 RustDesk配置

```
ID服务器: 34.96.199.184
中继服务器: 34.96.199.184
Key: mzhrEkxv82h+9AVvfV3igJgyGxowvSdrc5zSZ7aNQ+o=
```
