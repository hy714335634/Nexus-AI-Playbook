---
title: 学习路径
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - CLAUDE.md
    - README.md
  generated_at: 2026-05-08T14:34:11+00:00
  generated_by: docs-sync v2
---

# 学习路径

## 这是什么

本指南帮你规划掌握 Nexus-AI 的顺序：从环境准备到构建第一个 Agent，再到按需开启 IDE 接入、SSO 和云端部署。按步推进，不必一次面对所有功能。

## 使用场景

| 你的身份 | 推荐路径 |
|---------|---------|
| 第一次接触 | 本地安装 → 验证 → 构建示例 Agent |
| 想接入 IDE | 本地安装 → 启动 MCP → Kiro / Claude Code / Cursor 配置 |
| 运维 / 部署人员 | 跳到云端部署 → 启用 SSO / Sandbox |
| 已有 Agent 需要托管 | 本地安装 → 通过 Web 控制台导入 → 发布 |

## 如何使用

### 第 1 步：准备环境

确认满足以下条件：

- Python 3.13+、Node.js 18+
- AWS 账户已开通 Bedrock 权限
- 本地已执行 `aws configure` 配置凭证

### 第 2 步：安装并初始化

```bash
git clone https://github.com/hy714335634/Nexus-AI.git
cd Nexus-AI
python3.13 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
pip install -e .
./nexus-cli init
```

`./nexus-cli init` 会创建 DynamoDB 表、SQS 队列和 S3 存储桶。

<!-- SCREENSHOT: install-complete -->

### 第 3 步：启动服务

```bash
./nexus-cli service start
```

该命令一次拉起 API、Worker、Web 三个核心服务。访问 `http://localhost:3000` 登录 Web 控制台，默认账号 `admin` / `nexus`。

<!-- SCREENSHOT: web-login -->

### 第 4 步：验证安装

运行一次内置 Agent，确认整条链路通畅：

```bash
source .venv/bin/activate
python agents/system_agents/magician.py -i "AWS us-east-1 的 m8g.xlarge 实例价格是多少？"
```

### 第 5 步：构建第一个 Agent

用一句自然语言描述需求，平台会自动完成需求分析 → 架构设计 → 代码生成：

```bash
python agents/system_agents/agent_build_workflow/agent_build_workflow.py \
  -i "创建一个能够分析 PDF 文档并提取关键信息的 Agent"
```

生成的 Agent 代码位于 `agents/generated_agents/` 目录。

<!-- SCREENSHOT: first-agent-built -->

### 第 6 步：按需启用扩展能力

| 能力 | 启动方式 | 适用人群 |
|------|---------|---------|
| MCP Server（IDE 直接调用 Agent） | `./nexus-cli service start --mcp` | Kiro / Claude Code / Cursor 用户 |
| SSO 单点登录（SAML 2.0） | 修改 `config/default_config.yaml` 将 `sso.enabled` 设为 `True` | 多人团队 |
| 分布式链路追踪 | 手动启动 Jaeger 容器 | 调优 / 排障 |
| Sandbox 沙箱运行时 | `nexus-cli deploy` 时加 `--enable-sandbox` | 需要多租户隔离 |

### 第 7 步：云端部署

具备 AWS 权限后，用一条命令拉起完整环境（VPC + EC2 + Aurora + Valkey + ALB + CloudFront）：

```bash
nexus-cli deploy up my-env \
  --github-token ghp_xxxx \
  --db-password 'MySecurePass123!'
```

## 关键参数 / 限制

| 项目 | 说明 |
|------|------|
| 最低 Python 版本 | 3.13 |
| 最低 Node.js 版本 | 18 |
| 必需的 AWS 服务 | Bedrock、Aurora PostgreSQL、Valkey、DynamoDB、SQS、S3 |
| Web 前端端口 | 3000 |
| API 端口 | 8000 |
| MCP Server 端口 | 9000（可选，需 `--mcp` 启动） |
| 默认登录凭证 | `admin` / `nexus`（仅开发模式） |

## 常见问题

**Q：必须把所有步骤走完才能使用 Nexus-AI 吗？**
A：不用。完成第 1–5 步就能在本机构建和运行 Agent。第 6–7 步按需启用。

**Q：能跳过本地安装，直接云端部署吗？**
A：可以。只做运维托管时用 `nexus-cli deploy up` 一键拉起完整环境即可，无需本地安装。

**Q：我不是开发者，也能构建 Agent 吗？**
A：可以。核心用法是用自然语言描述需求，平台自动生成代码，不需要手写 Python。

**Q：多人团队怎么从默认账号切换到 SSO？**
A：把 `config/default_config.yaml` 中的 `sso.enabled` 改为 `True`，并配置 IdP Metadata URL、SP 实体 ID 和 ACS URL。SSO 模式需要额外安装 `python3-saml` 依赖。

**Q：生成好的 Agent 在哪里查看？**
A：命令行方式在 `agents/generated_agents/` 目录下；Web 控制台登录后可在 Agent 列表中直接管理。
