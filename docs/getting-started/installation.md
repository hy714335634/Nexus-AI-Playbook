---
title: 安装 Nexus-AI
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - README.md
    - pyproject.toml
    - requirements.txt
    - setup_env_alinux2023.sh
  generated_at: 2026-05-08T14:28:42+00:00
  generated_by: docs-sync v2
---

# 安装 Nexus-AI

## 这是什么

Nexus-AI 在本地或 EC2 主机上以 Python 虚拟环境 + Node.js 前端 + Docker（可选）的形式运行。本篇介绍两种安装路径：**Amazon Linux 2023 一键脚本**（推荐，几分钟内把系统依赖、Python 3.13、uv、代码仓库、前端依赖全部装好）和**跨平台手动安装**（适合 macOS / 其他 Linux 发行版 / 已有 Python 环境的场景）。

## 使用场景

| 场景 | 建议路径 |
|------|----------|
| 在一台全新的 AL2023 EC2 上搭建开发/演示环境 | 一键脚本 `setup_env_alinux2023.sh` |
| 在本地 macOS、Ubuntu、其他 Linux 上尝试 Nexus-AI | 手动安装 |
| 已有 Python 3.13 环境，只想把代码接入项目 | 手动安装 |
| 一次性部署到 AWS 云上完整运行（VPC + EC2 + Aurora + Valkey + ALB + CloudFront） | 使用 `nexus-cli deploy`（见「云端部署」文档，不在本篇范围） |

## 如何使用

### 前置条件

| 组件 | 要求 |
|------|------|
| Python | 3.13+ |
| Node.js | 18+（用于 Web 前端构建） |
| AWS 账户 | 已开通 Bedrock 访问权限（Claude 系列模型） |
| AWS CLI | 已安装，安装后会通过 `aws configure` 配置 |
| 操作系统（一键脚本） | 仅 Amazon Linux 2023 |
| 运行用户 | 非 root 用户（AL2023 脚本强制要求用 `ec2-user`） |

<!-- SCREENSHOT: installation-prerequisites -->

### 路径 A：Amazon Linux 2023 一键脚本

脚本会依次完成：系统依赖 → Python 3.13 → Node.js → Docker → LibreOffice（用于模板预览 PPT/DOCX 转 PDF）→ uv 包管理器 → 克隆代码 → 创建虚拟环境 → 安装 Python/前端依赖 → 把虚拟环境自动激活写入 `~/.bashrc`。

1. 以 `ec2-user` 身份登录 EC2（不要使用 root）。
2. 下载并执行脚本：

   ```bash
   curl -O https://raw.githubusercontent.com/hy714335634/Nexus-AI/main/setup_env_alinux2023.sh
   chmod +x setup_env_alinux2023.sh
   ./setup_env_alinux2023.sh
   ```

3. 安装过程中如被提示 `是否拉取最新代码?`（项目目录已存在时）或 `Git 仓库地址`（首次克隆时），按需回车/输入。
4. 脚本结束后，重新登录一次终端或执行 `newgrp docker`，让 Docker 组权限生效。
5. 进行初始配置：

   ```bash
   aws configure                     # 配置 AWS 凭证
   ./nexus-cli init                  # 初始化 DynamoDB、SQS、S3
   ./nexus-cli service start         # 启动 API + Worker + Web
   ./nexus-cli service start --mcp   # 可选：额外启动 MCP Server
   ```

<!-- SCREENSHOT: installation-setup-script-success -->

::: tip 项目默认路径
一键脚本会把代码克隆到 `/home/ec2-user/Nexus-AI`，并在 `~/.bashrc` 追加 `cd` 和 `source .venv/bin/activate` 两行。重新登录后将自动进入项目目录并激活虚拟环境。
:::

### 路径 B：手动安装

1. 准备好 Python 3.13+ 和 Node.js 18+。
2. 克隆代码并进入项目目录：

   ```bash
   git clone https://github.com/hy714335634/Nexus-AI.git
   cd Nexus-AI
   ```

3. 创建并激活虚拟环境：

   ```bash
   python3.13 -m venv .venv
   source .venv/bin/activate
   ```

4. 安装 Python 依赖：

   ```bash
   pip install -r requirements.txt
   pip install -e .
   ```

5. 安装前端依赖（如果需要使用 Web 控制台）：

   ```bash
   cd web && npm install && cd ..
   ```

6. 配置 AWS 凭证，并按需编辑 `config/default_config.yaml`（S3 桶名、模型 ID、SSO 等）：

   ```bash
   aws configure
   ```

7. 初始化基础设施并启动服务：

   ```bash
   ./nexus-cli init
   ./nexus-cli service start
   ```

<!-- SCREENSHOT: installation-manual-venv -->

### 验证安装

服务启动后访问下列地址，确认三端都能打开：

| 端点 | 地址 |
|------|------|
| Web 前端 | `http://localhost:3000` |
| API 文档（Swagger UI） | `http://localhost:8000/docs` |
| MCP Server（仅 `--mcp` 启动时） | `http://localhost:9000/mcp` |

也可以直接跑一个内置 Agent 作为烟雾测试：

```bash
source .venv/bin/activate
python agents/system_agents/magician.py -i "AWS us-east-1 的 m8g.xlarge 实例价格是多少？"
```

## 关键参数 / 限制

| 项 | 说明 |
|------|------|
| 操作系统（一键脚本） | 仅支持 Amazon Linux 2023；脚本会主动检测 `/etc/os-release`，其他发行版直接退出 |
| 运行用户 | 脚本禁止以 root 运行；请使用 `ec2-user` 或其他普通用户 |
| Python 版本 | 必须 ≥ 3.13（`pyproject.toml` 要求 `python >=3.12`，脚本安装 3.13） |
| Node.js | 需要 18+，用于 Web 前端构建 |
| Docker | 一键脚本会安装并启动 Docker，用于运行 Jaeger 等可选容器；手动安装路径按需自行安装 |
| LibreOffice | 仅一键脚本会安装（通过 documentfoundation 官方 RPM），用于模板预览中 PPTX/DOCX/XLSX → PDF 的转换；下载失败不会中断安装，但模板缩略图/PDF 功能将不可用 |
| AWS 区域 | 建议使用已开通 Bedrock 访问权限的区域（如 `us-west-2`、`us-east-1`） |
| 项目默认目录 | 一键脚本固定使用 `/home/ec2-user/Nexus-AI`；手动安装路径可任意 |
| 磁盘空间 | 建议至少 20 GB 可用空间，LibreOffice、Node 模块、Python 依赖、Docker 镜像占用较多 |

## 常见问题

**Q1：脚本提示「此脚本仅支持 Amazon Linux 2023」怎么办？**
一键脚本做了严格的发行版检测。若在 Ubuntu、Debian、CentOS、macOS 等系统上运行，请走「路径 B：手动安装」。

**Q2：`uv` 命令找不到？**
脚本会把 `$HOME/.local/bin` 追加到 `~/.bashrc`，但当前 shell 不会立即生效。重新登录终端，或执行 `export PATH="$HOME/.local/bin:$PATH"` 后再运行 `uv --version`。

**Q3：LibreOffice 下载失败会影响什么？**
脚本会打印警告但继续运行。影响范围仅限于「模板预览」里把 PPTX/DOCX/XLSX 转成 PDF 再生成缩略图的功能；其他 Agent 构建、对话、MCP 等核心功能不受影响。之后可以手动重新安装。

**Q4：为什么强调不能用 root 运行脚本？**
脚本会把虚拟环境和 `cd` 命令写进 `~/.bashrc`，还会执行 `sudo usermod -aG docker $USER`。用 root 跑会把配置写到 `/root/.bashrc`，并且 Docker 组权限无从生效。请使用 `ec2-user`。

**Q5：安装完成后，启动服务需要做什么？**
按顺序执行 `aws configure` → `./nexus-cli init` → `./nexus-cli service start`。如果需要把 Agent 暴露给 Kiro / Claude Code / Cursor 等 IDE，追加 `--mcp` 参数启动 MCP Server。详细使用方法参见「快速开始」章节。
