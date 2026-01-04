# GitHub上传指令

## 第1步：创建GitHub仓库

1. 访问：https://github.com/new
2. 填写信息：
   - **Repository name:** `rustdesk-auto-ip`
   - **Description:** `RustDesk自动IP白名单管理系统 - 让客户端自动上报IP`
   - **Public** ✅（选择公开，方便中国下载）
   - **不要**勾选 "Add a README file"
   - **不要**勾选 "Add .gitignore"
   - **不要**勾选 "Choose a license"
3. 点击 **"Create repository"**

## 第2步：推送代码到GitHub

复制GitHub显示的命令，或者运行以下命令：

```bash
# 添加远程仓库（替换ermingpei为你的GitHub用户名）
git remote add origin https://github.com/ermingpei/rustdesk-auto-ip.git

# 推送代码
git branch -M main
git push -u origin main
```

**示例（假设你的用户名是 john）：**
```bash
git remote add origin https://github.com/john/rustdesk-auto-ip.git
git branch -M main
git push -u origin main
```

## 第3步：获取下载链接

推送成功后，文件的直接下载链接为：

### Windows版本（中国用户）
```
https://raw.githubusercontent.com/ermingpei/rustdesk-auto-ip/main/auto_report_ip_client.bat
```

### Mac/Linux版本
```
https://raw.githubusercontent.com/ermingpei/rustdesk-auto-ip/main/auto_report_ip_client.sh
```

### 使用指南
```
https://github.com/ermingpei/rustdesk-auto-ip/blob/main/客户端下载.md
```

**记得把 `ermingpei` 替换成你的实际GitHub用户名！**

## 第4步：更新文档中的链接

推送成功后，需要更新以下文件中的链接：

### 1. README.md
找到所有 `ermingpei/YOUR_REPO` 并替换为实际的：
- `ermingpei` → 你的GitHub用户名
- `YOUR_REPO` → `rustdesk-auto-ip`

### 2. 客户端下载.md
同样替换所有链接

### 3. 自动IP上报-完整部署指南.md
同样替换所有链接

**快速替换命令：**
```bash
# 替换README.md（把john替换成你的用户名）
sed -i '' 's/ermingpei\/YOUR_REPO/john\/rustdesk-auto-ip/g' README.md

# 替换客户端下载.md
sed -i '' 's/ermingpei\/YOUR_REPO/john\/rustdesk-auto-ip/g' 客户端下载.md

# 替换部署指南
sed -i '' 's/ermingpei\/YOUR_REPO/john\/rustdesk-auto-ip/g' 自动IP上报-完整部署指南.md

# 提交更改
git add README.md 客户端下载.md 自动IP上报-完整部署指南.md
git commit -m "更新GitHub链接"
git push
```

## 第5步：测试下载

在浏览器中访问：
```
https://raw.githubusercontent.com/ermingpei/rustdesk-auto-ip/main/auto_report_ip_client.bat
```

应该能看到文件内容或自动下载。

## 第6步：发送给中国用户

### 方式1：直接下载链接

发送微信消息：
```
RustDesk自动IP上报工具

Windows用户下载：
https://raw.githubusercontent.com/ermingpei/rustdesk-auto-ip/main/auto_report_ip_client.bat

使用方法：
1. 点击链接，右键"另存为"保存到桌面
2. 双击运行
3. 完成！以后自动运行

详细说明：
https://github.com/ermingpei/rustdesk-auto-ip/blob/main/客户端下载.md
```

### 方式2：GitHub页面

发送微信消息：
```
RustDesk自动IP上报工具

访问：https://github.com/ermingpei/rustdesk-auto-ip

点击 auto_report_ip_client.bat
点击右上角 "Download" 按钮下载
双击运行即可
```

## 完成！

现在中国用户可以：
1. 访问GitHub链接
2. 下载 `auto_report_ip_client.bat`
3. 双击运行
4. 自动上报IP，无需手动操作

---

## 故障排除

### 问题1：git push失败，提示需要认证

**解决方法1：使用Personal Access Token**
1. 访问：https://github.com/settings/tokens
2. 点击 "Generate new token (classic)"
3. 勾选 `repo` 权限
4. 生成token并复制
5. 推送时使用token作为密码

**解决方法2：使用SSH**
```bash
# 生成SSH密钥
ssh-keygen -t ed25519 -C "your_email@example.com"

# 添加到GitHub
cat ~/.ssh/id_ed25519.pub
# 复制输出，添加到 https://github.com/settings/keys

# 修改远程仓库URL
git remote set-url origin git@github.com:ermingpei/rustdesk-auto-ip.git

# 推送
git push -u origin main
```

### 问题2：中国用户无法访问GitHub

**解决方法：使用Gitee镜像**
1. 在Gitee创建仓库
2. 从GitHub导入
3. 提供Gitee链接给中国用户

或者：
- 使用GitHub加速服务
- 使用代理/VPN

### 问题3：raw.githubusercontent.com无法访问

**临时解决：**
- 修改hosts文件
- 使用CDN加速：`https://cdn.jsdelivr.net/gh/ermingpei/rustdesk-auto-ip@main/auto_report_ip_client.bat`

---

## 下一步

1. ✅ 推送代码到GitHub
2. ✅ 更新文档中的链接
3. ✅ 测试下载链接
4. ✅ 发送给中国用户
5. ✅ 启动服务器端API（如果还没启动）

**全部完成后，系统就可以正常使用了！** 🎉
