# RustDesk 服务器管理工具

自建RustDesk服务器的管理工具集，包含IP白名单自动管理、服务器优化等功能。

## 🚀 快速开始

### 客户端：添加IP到白名单

**Mac/Linux:**
```bash
curl -O https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/auto_report_ip_client.sh
chmod +x auto_report_ip_client.sh
./auto_report_ip_client.sh
```

**Windows:**
1. 下载 [auto_report_ip_client.bat](https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/auto_report_ip_client.bat)
2. 右键编辑，修改SECRET_KEY
3. 双击运行

### 中国用户下载（Gitee镜像）

**Mac/Linux:**
```bash
curl -O https://gitee.com/YOUR_USERNAME/YOUR_REPO/raw/main/auto_report_ip_client.sh
chmod +x auto_report_ip_client.sh
./auto_report_ip_client.sh
```

**Windows:**
下载：https://gitee.com/YOUR_USERNAME/YOUR_REPO/raw/main/auto_report_ip_client.bat

---

## 📋 功能特性

### 1. IP自动上报系统
- ✅ 客户端无需gcloud SDK
- ✅ 客户端无需GCP权限
- ✅ 只需要一个密钥
- ✅ 实时响应

### 2. 服务器管理
- 防火墙管理
- 服务监控
- 日志查看
- 性能优化

### 3. 安全特性
- 密钥验证
- 请求频率限制
- IP格式验证
- 完整日志记录

---

## 📚 文档

- [IP自动上报使用指南](IP自动上报-使用指南.md)
- [RustDesk配置说明](RustDesk配置说明.md)
- [故障排除指南](TROUBLESHOOTING_GUIDE.md)

---

## 🔧 服务器端部署

### 1. 启动API服务
```bash
./auto_update_ip_server.sh start
```

### 2. 修改密钥
编辑 `auto_update_ip_server.sh`，修改SECRET_KEY

### 3. 验证服务
```bash
./auto_update_ip_server.sh status
curl http://YOUR_SERVER_IP:8888/health
```

---

## 📦 主要文件

### 客户端脚本
- `auto_report_ip_client.sh` - Mac/Linux客户端
- `auto_report_ip_client.bat` - Windows客户端

### 服务器端脚本
- `auto_update_ip_server.sh` - API服务
- `add_rustdesk_access.sh` - 手动添加IP
- `view_rustdesk_access.sh` - 查看白名单
- `remove_rustdesk_access.sh` - 删除IP

### 测试工具
- `test_ip_report_system.sh` - 系统测试

---

## 🆘 常见问题

### Q: 客户端无法连接服务器？
```bash
# 检查服务器状态
./auto_update_ip_server.sh status

# 测试连接
curl http://YOUR_SERVER_IP:8888/health
```

### Q: 密钥错误？
确保服务器端和客户端的SECRET_KEY完全一致

### Q: IP未添加？
```bash
# 查看服务器日志
tail -20 ~/rustdesk_auto_ip.log
```

---

## 🔒 安全建议

1. **修改默认密钥**
   ```bash
   # 生成强密钥
   openssl rand -base64 32
   ```

2. **定期更换密钥**
   - 更新服务器端配置
   - 更新所有客户端脚本

3. **监控日志**
   ```bash
   tail -f ~/rustdesk_auto_ip.log
   ```

---

## 📞 支持

如有问题，请查看：
- [使用指南](IP自动上报-使用指南.md)
- [故障排除](TROUBLESHOOTING_GUIDE.md)

---

## 📄 许可证

MIT License

---

## 🙏 致谢

基于 [RustDesk](https://github.com/rustdesk/rustdesk) 开源项目
