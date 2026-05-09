---
title: 5 分钟快速上手
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - README.md
    - agents/system_agents/magician.py
    - nexus-cli
  generated_at: 2026-05-08T14:27:06+00:00
  generated_by: docs-sync v2
---

# 5 分钟快速上手

## 这是什么

一份从零到跑通 Nexus-AI 的最短路径指南。完成下面的步骤后，你将拥有一套可以在本地访问的 Web 控制台，以及一个用自然语言就能向其提问的默认 Agent。

## 使用场景

| 你是谁 | 适合走本指南的时机 |
|--------|---------------------|
| 第一次接触 Nexus-AI 的用户 | 想先跑起来、看一眼效果，再决定深入学习哪个模块 |
| 负责做 PoC 的技术评估者 | 需要一套可演示的本地环境来验证"自然语言构建 Agent"是否可行 |
| 准备构建 Agent 的开发者 | 正式开始构建前，先把依赖、服务、凭证都准备好 |
| 部署前的验证者 | 云端部署前，先在本地跑通所有服务 |

## 如何使用

### 步骤 1：确认前置条件

在开始之前，请确认本机满足以下要求：

| 组件 | 要求 |
|------|------|
| Python | 3.13 及以上 |
| Node.js | 18 及以上（Web 前端需要） |
| AWS 账户 | 已开通 Bedrock 访问权限 |
| AWS CLI | 已运行 `aws configure` 配置好凭证 |

::: tip
如果使用 Amazon Linux 2023，可直接运行一键安装脚本：

```bash
curl -O https://raw.githubusercontent.com/hy714335634/Nexus-AI/main/setup_env_alinux2023.sh
chmod +x setup_env_alinux2023.sh
./setup_env_alinux2023.sh
```
:::

### 步骤 2：克隆项目并安装依赖

```bash
git clone https://github.com/hy714335634/Nexus-AI.git
cd Nexus-AI

python3.13 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
pip install -e .
```

### 步骤 3：配置 AWS 凭证

```bash
aws configure
```

如果你需要修改默认的 S3 桶名称、AWS 区域或模型 ID，编辑 `config/default_config.yaml`。默认配置足以完成首次体验。

### 步骤 4：初始化基础设施

首次运行必须先创建 DynamoDB 表、SQS 队列和 S3 存储桶：

```bash
./nexus-cli init
```

<!-- SCREENSHOT: cli-init-output -->

### 步骤 5：启动核心服务

启动 API、Worker、Web 三个核心服务：

```bash
./nexus-cli service start
```

如果你还想把平台上的 Agent 暴露给 Kiro / Claude Code / Cursor 这类 IDE，加上 `--mcp`：

```bash
./nexus-cli service start --mcp
```

可用以下命令查看状态或实时跟踪日志：

```bash
./nexus-cli service status
./nexus-cli service logs -f
```

### 步骤 6：访问 Web 控制台

浏览器打开 `http://localhost:3000`，用默认账号登录：

- 用户名：`admin`
- 密码：`nexus`

<!-- SCREENSHOT: login-page -->

进入后你会看到 Agent 列表、对话入口和构建入口。

### 步骤 7：用命令行验证一次对话

打开新终端，测试默认 Agent 是否能正常回答问题：

```bash
source .venv/bin/activate
python agents/system_agents/magician.py -i "AWS us-east-1 的 m8g.xlarge 实例价格是多少？"
```

如果看到一段正常的中文回答，说明整套链路（AWS 凭证 → Bedrock 模型 → Agent）已经跑通。

::: tip 进入交互模式
不带任何参数运行同一个脚本，就会进入可连续对话的交互模式：

```bash
python agents/system_agents/magician.py
```

输入 `quit` 或 `exit` 退出。
:::

## 关键参数 / 限制

| 名称 | 值 / 说明 |
|------|-----------|
| Web 前端地址 | `http://localhost:3000` |
| API 文档地址 | `http://localhost:8000/docs`（Swagger UI） |
| MCP Server 地址 | `http://localhost:9000/mcp`（需用 `--mcp` 启动） |
| 默认 Web 账号 | `admin` / `nexus`（在 `config/default_config.yaml` 的 `auth` 段修改） |
| Python 版本 | 必须 3.13+ |
| AWS Bedrock | 必须开通 Claude 系列模型访问权限 |
| 默认模型 | Claude Sonnet 4.5（可通过 `bedrock.model_id` 切换） |

## 常见问题

### Q1：`./nexus-cli init` 报 AWS 权限错误怎么办？

先用 `aws sts get-caller-identity` 确认 `aws configure` 的凭证是否生效，然后确认该账号/角色具备创建 DynamoDB 表、SQS 队列和 S3 桶的权限。项目 README 的"部署者 IAM 权限"一节列出了所需的最小权限清单。

### Q2：Web 控制台打不开或端口冲突？

运行 `./nexus-cli service status` 查看服务是否启动，再用 `./nexus-cli service logs --api` 查看错误原因。3000、8000、9000 这三个端口如果被占用，需要先停掉占用进程或修改端口后再重启。

### Q3：验证命令返回 `AccessDeniedException`？

这是 AWS Bedrock 侧的权限问题：进入 AWS 控制台 → Bedrock → Model access，申请 Claude Sonnet / Haiku / Opus 的访问权限。审批通过后再次运行即可。

### Q4：我想跳过 Web 控制台，直接用命令行玩 Agent？

`agents/system_agents/magician.py` 就是为这种场景准备的。不加参数进入默认 Agent 交互模式；`-a &lt;agent_path&gt;` 指定已有 Agent；`-i "<问题>"` 发送一次性问题。

### Q5：默认账号登录后想改密码怎么办？

编辑 `config/default_config.yaml` 的 `nexus-ai.auth.user` 与 `nexus-ai.auth.password`，然后运行 `./nexus-cli service restart` 重启服务。生产环境建议改用 SSO 模式（见"配置说明"文档）。
