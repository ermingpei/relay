# 快速参考 - GitHub上传

## 🚀 三步上传

### 1️⃣ 创建GitHub仓库
访问：https://github.com/new
- 名称：`rustdesk-auto-ip`
- 公开：✅
- 点击"Create repository"

### 2️⃣ 推送代码
```bash
# 替换ermingpei为你的GitHub用户名
git remote add origin https://github.com/ermingpei/rustdesk-auto-ip.git
git push -u origin main
```

### 3️⃣ 获取下载链接
```
Windows:
https://raw.githubusercontent.com/ermingpei/rustdesk-auto-ip/main/auto_report_ip_client.bat

Mac/Linux:
https://raw.githubusercontent.com/ermingpei/rustdesk-auto-ip/main/auto_report_ip_client.sh
```

---

## 📝 发送给中国用户

### 微信消息模板

```
RustDesk自动IP上报工具 - 全自动化

Windows用户：
https://raw.githubusercontent.com/ermingpei/rustdesk-auto-ip/main/auto_report_ip_client.bat

使用方法：
1. 点击链接，右键"另存为"
2. 双击运行
3. 完成！

功能：
✅ 自动检测IP变化
✅ 自动上报到服务器
✅ 自动添加到白名单
✅ 每小时自动检查
✅ 开机自动运行

详细说明：
https://github.com/ermingpei/rustdesk-auto-ip
```

---

## 🔧 更新链接

推送后运行（替换john为你的用户名）：

```bash
# 更新所有文档中的链接
sed -i '' 's/ermingpei\/YOUR_REPO/john\/rustdesk-auto-ip/g' README.md
sed -i '' 's/ermingpei\/YOUR_REPO/john\/rustdesk-auto-ip/g' 客户端下载.md
sed -i '' 's/ermingpei\/YOUR_REPO/john\/rustdesk-auto-ip/g' 自动IP上报-完整部署指南.md

# 提交
git add .
git commit -m "更新GitHub链接"
git push
```

---

## ✅ 完成检查

- [ ] GitHub仓库已创建
- [ ] 代码已推送
- [ ] 下载链接可访问
- [ ] 文档链接已更新
- [ ] 已发送给中国用户
- [ ] 服务器API已启动

**全部完成！** 🎉
