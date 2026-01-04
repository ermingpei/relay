# RustDesk 自动IP上报系统 - 完整部署指南

## 🎯 系统概述

这是一个完全自动化的IP白名单管理系统，让客户端可以自动上报IP到服务器，无需手动操作。

### 工作流程

```
客户端电脑（中国/加拿大）
    ↓
自动检测IP变化
    ↓
自动上报到服务器（HTTP API）
    ↓
服务器自动添加到GCP防火墙白名单
    ↓
客户端可以连接RustDesk
```

---

## 📦 文件说明

### 服务器端文件（管理员使用）

| 文件 | 用途 |
|------|------|
| `auto_update_ip_server.sh` | 服务器端API服务 |
| `add_rustdesk_access.sh` | 手动添加IP（备用） |
| `view_rustdesk_access.sh` | 查看白名单 |
| `remove_rustdesk_access.sh` | 删除IP |

### 客户端文件（发给用户）

| 文件 | 平台 | 用途 |
|------|------|------|
| `auto_report_ip_client.bat` | Windows | 自动上报IP |
| `auto_report_ip_client.sh` | Mac/Linux | 自动上报IP |
| `客户端下载.md` | 所有 | 下载和使用指南 |

---

## 🚀 部署步骤

### 第1步：服务器端部署

#### 1.1 启动API服务

```bash
# SSH到GCP服务器
gcloud compute ssh myserver --zone=asia-east2-a

# 上传服务器脚本
# （或者从GitHub下载）

# 启动服务
./auto_update_ip_server.sh start
```

会显示：
```
✅ 服务已启动在端口 8888
PID: 12345
日志: /home/username/rustdesk_auto_ip.log

⚠️  重要：修改 SECRET_KEY 为强密码！
编辑此文件，修改第6行的 SECRET_KEY
```

#### 1.2 配置防火墙

```bash
# 创建防火墙规则，允许客户端访问API
gcloud compute firewall-rules create rustdesk-auto-ip-api \
    --allow tcp:8888 \
    --source-ranges 0.0.0.0/0 \
    --target-tags myserver \
    --description "RustDesk自动IP上报API"
```

#### 1.3 验证服务

```bash
# 检查服务状态
./auto_update_ip_server.sh status

# 测试API
curl http://localhost:8888/health
```

应该返回：
```json
{"status": "ok", "timestamp": "2025-01-04T10:30:00", "version": "1.0"}
```

---

### 第2步：上传到GitHub

#### 2.1 创建GitHub仓库

1. 访问：https://github.com/new
2. 仓库名称：`rustdesk-auto-ip`
3. 描述：`RustDesk自动IP白名单管理系统`
4. 选择：Public（公开，方便中国下载）
5. 点击"Create repository"

#### 2.2 推送代码

```bash
# 在本地仓库目录
git remote add origin https://github.com/YOUR_USERNAME/rustdesk-auto-ip.git
git branch -M main
git push -u origin main
```

#### 2.3 获取下载链接

推送成功后，文件的直接下载链接为：

**Windows版本：**
```
https://raw.githubusercontent.com/YOUR_USERNAME/rustdesk-auto-ip/main/auto_report_ip_client.bat
```

**Mac/Linux版本：**
```
https://raw.githubusercontent.com/YOUR_USERNAME/rustdesk-auto-ip/main/auto_report_ip_client.sh
```

**使用指南：**
```
https://github.com/YOUR_USERNAME/rustdesk-auto-ip/blob/main/客户端下载.md
```

---

### 第3步：客户端部署

#### 3.1 发送下载链接给用户

**方式1：直接下载**

发送给用户：
```
Windows用户下载：
https://raw.githubusercontent.com/YOUR_USERNAME/rustdesk-auto-ip/main/auto_report_ip_client.bat

使用方法：
1. 点击链接
2. 右键 → "另存为" → 保存到桌面
3. 双击运行
```

**方式2：GitHub页面**

发送给用户：
```
访问：https://github.com/YOUR_USERNAME/rustdesk-auto-ip
点击 auto_report_ip_client.bat
点击 "Download" 按钮
```

#### 3.2 用户使用

**Windows：**
1. 双击 `auto_report_ip_client.bat`
2. 看到"IP已上报到服务器"
3. 完成！以后自动运行

**Mac/Linux：**
```bash
chmod +x auto_report_ip_client.sh
./auto_report_ip_client.sh install
```

---

## 🔧 配置说明

### 修改服务器地址

如果服务器IP变了，需要修改客户端脚本：

**auto_report_ip_client.bat（第7行）：**
```batch
SET SERVER_URL=http://YOUR_NEW_IP:8888/update-ip
```

**auto_report_ip_client.sh（第6行）：**
```bash
SERVER_URL="http://YOUR_NEW_IP:8888/update-ip"
```

### 修改密钥（重要！）

**服务器端（auto_update_ip_server.sh 第6行）：**
```bash
SECRET_KEY="YOUR_STRONG_SECRET_KEY_HERE"
```

**客户端（两个文件都要改）：**
```batch
SET SECRET_KEY=YOUR_STRONG_SECRET_KEY_HERE
```

**⚠️ 修改后需要：**
1. 重启服务器：`./auto_update_ip_server.sh restart`
2. 重新上传客户端文件到GitHub
3. 让用户重新下载

---

## 📊 监控和维护

### 查看服务器日志

```bash
# 实时查看
tail -f ~/rustdesk_auto_ip.log

# 查看最近50条
tail -50 ~/rustdesk_auto_ip.log

# 搜索特定IP
grep "36.33.125.192" ~/rustdesk_auto_ip.log
```

### 查看当前白名单

```bash
./view_rustdesk_access.sh
```

### 查看服务状态

```bash
./auto_update_ip_server.sh status
```

### 重启服务

```bash
./auto_update_ip_server.sh restart
```

---

## 🆘 故障排除

### 问题1：客户端显示"无法连接服务器"

**检查：**
```bash
# 1. 服务是否运行
./auto_update_ip_server.sh status

# 2. 端口是否监听
netstat -tlnp | grep 8888

# 3. 防火墙是否开放
gcloud compute firewall-rules describe rustdesk-auto-ip-api

# 4. 测试连接
curl http://34.96.199.184:8888/health
```

**解决：**
```bash
# 重启服务
./auto_update_ip_server.sh restart

# 检查日志
tail -50 ~/rustdesk_auto_ip.log
```

### 问题2：服务器日志显示"Invalid secret key"

**原因：** 客户端密钥不匹配

**解决：**
1. 检查服务器端密钥：`grep SECRET_KEY auto_update_ip_server.sh`
2. 检查客户端密钥：`grep SECRET_KEY auto_report_ip_client.bat`
3. 确保两边一致
4. 重新上传客户端文件

### 问题3：IP已上报但还是连不上

**检查：**
```bash
# 1. 查看白名单
./view_rustdesk_access.sh

# 2. 检查IP是否在列表中
gcloud compute firewall-rules describe rustdesk-whitelist-complete \
    --format="value(sourceRanges)" | grep "36.33.125.192"

# 3. 手动添加（如果不在）
./add_rustdesk_access.sh
```

### 问题4：定时任务不工作

**Windows：**
```
1. 打开"任务计划程序"
2. 找到"RustDesk Auto IP Report"
3. 右键 → "运行"测试
4. 查看"历史记录"
```

**Mac/Linux：**
```bash
# 查看cron任务
crontab -l

# 手动运行测试
./auto_report_ip_client.sh

# 查看系统日志
grep CRON /var/log/syslog
```

---

## 📈 性能和限制

### 服务器端

- **并发处理：** 支持多个客户端同时上报
- **频率限制：** 每个IP每小时最多100次请求
- **超时设置：** 30秒连接超时，60秒操作超时
- **日志轮转：** 建议定期清理日志文件

### 客户端

- **检查频率：** 每小时一次
- **网络要求：** 需要访问 api.ipify.org 和服务器
- **资源占用：** 极低（运行时间<5秒）
- **日志大小：** 每天约1KB

---

## 🔐 安全建议

### 1. 修改默认密钥

```bash
# 生成强密钥
openssl rand -base64 32

# 更新到服务器和客户端
```

### 2. 限制源IP范围（可选）

如果知道客户端大致IP范围：

```bash
gcloud compute firewall-rules update rustdesk-auto-ip-api \
    --source-ranges="36.0.0.0/8,142.0.0.0/8"
```

### 3. 启用HTTPS（推荐）

使用Nginx反向代理：

```nginx
server {
    listen 443 ssl;
    server_name your-domain.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location /update-ip {
        proxy_pass http://localhost:8888;
    }
}
```

### 4. 定期审计

```bash
# 查看最近添加的IP
tail -100 ~/rustdesk_auto_ip.log | grep "Added IP"

# 查看当前白名单
./view_rustdesk_access.sh

# 删除可疑IP
./remove_rustdesk_access.sh
```

---

## 📞 支持和反馈

### 查看完整文档

- `客户端下载.md` - 客户端使用指南
- `TROUBLESHOOTING_GUIDE.md` - 故障排除
- `README.md` - 项目说明

### 获取帮助

1. 查看日志文件
2. 运行诊断脚本
3. 查看GitHub Issues

---

## 🎉 部署完成检查清单

- [ ] 服务器端API已启动
- [ ] 防火墙规则已创建
- [ ] 服务状态正常
- [ ] 代码已推送到GitHub
- [ ] 下载链接已测试
- [ ] 客户端已测试（Windows）
- [ ] 客户端已测试（Mac/Linux）
- [ ] 定时任务已验证
- [ ] 日志正常记录
- [ ] 密钥已修改（安全）

**全部完成！系统可以投入使用了！** ✅
