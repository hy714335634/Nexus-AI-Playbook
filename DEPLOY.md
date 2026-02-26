# 部署指南

本文档说明如何将 Nexus-AI 用户手册部署到服务器。

## 技术栈

- **VitePress** — 静态站点生成器
- **Node.js** ≥ 18 — 构建环境

## 本地预览

```bash
# 安装依赖
npm install

# 开发模式（热重载）
npm run docs:dev

# 构建生产版本
npm run docs:build

# 预览构建结果
npm run docs:preview
```

## 构建产物

构建命令 `npm run docs:build` 会在 `docs/.vitepress/dist/` 目录下生成纯静态文件（HTML + CSS + JS + 图片），可直接部署到任何静态文件服务器。

## 部署方式

### 方式一：Nginx

1. 将 `docs/.vitepress/dist/` 目录的内容上传到服务器

2. Nginx 配置示例：

```nginx
server {
    listen 80;
    server_name docs.your-domain.com;
    root /var/www/nexus-ai-playbook;
    index index.html;

    # VitePress cleanUrls 支持
    location / {
        try_files $uri $uri.html $uri/ =404;
    }

    # 静态资源缓存
    location /assets/ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    location /images/ {
        expires 7d;
        add_header Cache-Control "public";
    }

    # gzip 压缩
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml;
}
```

3. 上传文件：
```bash
# 构建
npm run docs:build

# 上传到服务器
rsync -avz docs/.vitepress/dist/ user@server:/var/www/nexus-ai-playbook/
```

### 方式二：Docker

1. 创建 Dockerfile：

```dockerfile
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run docs:build

FROM nginx:alpine
COPY --from=builder /app/docs/.vitepress/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
```

2. 创建 `nginx.conf`：

```nginx
server {
    listen 80;
    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri.html $uri/ =404;
    }

    location /assets/ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml;
}
```

3. 构建和运行：

```bash
docker build -t nexus-ai-playbook .
docker run -d -p 8080:80 nexus-ai-playbook
```

### 方式三：AWS S3 + CloudFront

```bash
# 构建
npm run docs:build

# 上传到 S3
aws s3 sync docs/.vitepress/dist/ s3://your-bucket-name/ --delete

# 配置 CloudFront（首次需要创建分配）
aws cloudfront create-invalidation --distribution-id YOUR_DIST_ID --paths "/*"
```

S3 存储桶需要开启静态网站托管，错误文档设置为 `404.html`。

### 方式四：GitHub Pages

在 `.github/workflows/deploy.yml` 中配置：

```yaml
name: Deploy Docs
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 18
      - run: npm ci
      - run: npm run docs:build
      - uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: docs/.vitepress/dist
```

## 更新截图

如需更新文档中的截图（例如 UI 有变化），可以重新安装 Playwright 并运行截图脚本：

```bash
npm install playwright
npx playwright install chromium

# 修改脚本中的 BASE URL 和登录凭据后运行
node capture-screenshots.mjs
```

## 目录结构

```
Nexus-AI-Playbook/
├── docs/
│   ├── .vitepress/
│   │   ├── config.mts        # VitePress 配置
│   │   ├── theme/
│   │   │   ├── index.ts       # 自定义主题入口
│   │   │   └── custom.css     # 自定义样式
│   │   └── dist/              # 构建输出（git忽略）
│   ├── public/
│   │   ├── images/            # 截图（21张）
│   │   └── logo.svg           # 站点 Logo
│   ├── guide/                 # 快速上手
│   │   ├── login.md
│   │   ├── workspace.md
│   │   └── first-agent.md
│   ├── manual/                # 使用手册
│   │   ├── dashboard.md
│   │   ├── create-agent.md
│   │   ├── build-progress.md
│   │   ├── projects.md
│   │   ├── manage-agents.md
│   │   ├── chat.md
│   │   ├── tools.md
│   │   └── mcp.md
│   ├── overview/              # 平台介绍
│   │   ├── what-is-nexus.md
│   │   └── how-it-works.md
│   ├── admin/                 # 管理员指南
│   │   ├── settings.md
│   │   └── users.md
│   ├── faq.md                 # 常见问题
│   └── index.md               # 首页
├── package.json
├── .gitignore
└── DEPLOY.md                  # 本文件
```
