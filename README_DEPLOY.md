# 如何部署到 GitHub 并开启访问

## 第一步：创建 GitHub 仓库

1. 登录您的 [GitHub 账号](https://github.com)。
2. 点击右上角的 "+" 号，选择 **New repository**。
3. 输入仓库名称（例如 `gxas-membership`）。
4. 确保选择 **Public**（公开）。
5. 点击 **Create repository**。

## 第二步：上传代码

在您本地电脑的终端（Terminal）中，依次运行以下命令（将 `<YOUR_URL>` 替换为您刚才创建的仓库地址）：

```bash
git init
git add .
git commit -m "First commit"
git branch -M main
git remote add origin <YOUR_URL>
git push -u origin main
```

*注意：如果这是您第一次使用 Git，系统可能会提示您配置邮箱和用户名，或者弹窗要求登录 GitHub。*

## 第三步：开启 GitHub Pages (网页访问)

1. 代码上传成功后，在 GitHub 仓库页面点击 **Settings**（设置）。
2. 在左侧菜单找到 **Pages**。
3. 在 **Build and deployment** 下的 **Source** 选择 `Deploy from a branch`。
4. 在 **Branch** 下选择 `main` 分支，文件夹选择 `/ (root)`，然后点击 **Save**。
5. 等待几分钟，刷新页面，您会在上方看到一个绿色的提示，显示您的网站访问地址（通常是 `https://您的用户名.github.io/仓库名/`）。

## 特别说明

- 我已经为您优化了 `auth.js` 代码，使其能够自动适应 GitHub Pages 的网址结构（包括子目录），确保注册确认邮件和密码重置邮件的链接能正确跳转。
- `node_modules` 和打包生成的软件文件已被忽略，不会上传到 GitHub，这能加快上传速度并保持仓库整洁。
