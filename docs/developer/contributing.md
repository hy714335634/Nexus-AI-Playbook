---
title: 贡献指南
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - .python-version
    - CLAUDE.md
    - CONTRIBUTING.md
    - pyproject.toml
  generated_at: 2026-05-08T23:48:10+00:00
  generated_by: docs-sync v2
---

# 贡献指南

## 概述

本文档是 **Nexus-AI 代码贡献者的工作手册**。它以源码仓库里的 `CONTRIBUTING.md`、`CLAUDE.md`、`pyproject.toml` 与 `.python-version` 为唯一事实来源，告诉你：本地环境要装什么、分支/提交/PR 走什么流程、代码该写成什么样、Python 和依赖版本是如何被固定的。

范围：只覆盖**向 `hy714335634/Nexus-AI` 仓库贡献代码**所需的流程和约束。架构细节与运行时行为请参阅相关子系统文档（API、Worker、Agent Factory 等）。

主要入口：

- 贡献流程总纲 → `CONTRIBUTING.md`
- Claude Code / IDE 协作约定 → `CLAUDE.md`
- Python 版本与依赖清单 → `.python-version`、`pyproject.toml`

---

## 文件组织（File Layout）

| 路径 | 责任 | 依赖 |
|------|------|------|
| `CONTRIBUTING.md` | 贡献工作流：环境准备、分支策略、Commit 规范、PR 流程 | 无（人类可读） |
| `CLAUDE.md` | IDE / Claude Code 协作指南；项目概览、服务清单、代码约定、AWS 依赖 | 无 |
| `pyproject.toml` | 包元数据、Python 约束、运行时依赖、构建后端、wheel 打包目标 | `hatchling` 构建 |
| `.python-version` | 本地 Python 版本锁定（pyenv / uv 可读取） | 无 |

---

## Python 与运行时约束

### `.python-version`

```
3.13
```

本地开发用 Python **3.13**（pyenv / `uv` 会自动挑选这个版本）。

### `pyproject.toml` 顶层元数据

| 字段 | 值 | 说明 |
|------|-----|------|
| `[project].name` | `nexus-ai` | 分发包名 |
| `[project].version` | `0.1.0` | 当前版本号 |
| `[project].description` | `Nexus-AI: Enterprise-grade AI agent development platform` | 简介 |
| `[project].readme` | `README.md` | 分发 README |
| `[project].requires-python` | `>=3.12` | 最低运行 Python 版本；`.python-version` 进一步锁定到 3.13 |
| `[build-system].requires` | `["hatchling"]` | 构建依赖 |
| `[build-system].build-backend` | `hatchling.build` | 构建后端 |
| `[tool.hatch.build.targets.wheel].packages` | `["agents", "nexus_utils", "tools", "prompts", "config"]` | 被打包进 wheel 的顶层目录 |

::: warning
`requires-python = ">=3.12"`（pyproject）与 `.python-version = 3.13` 并不矛盾：前者是**最低兼容版本**，后者是**推荐开发版本**。提交 PR 前请用 3.13 验证。
:::

### 运行时依赖清单（`[project].dependencies`，穷举）

依赖按功能分组列出，所有条目均逐字摘自 `pyproject.toml`。

**Agent 运行时 / LLM 集成：**

| 依赖 | 版本约束 |
|------|---------|
| `strands-agents[otel]` | 未固定（extras: `otel`） |
| `strands-agents-tools` | 未固定 |
| `bedrock-agentcore` | 未固定 |
| `bedrock-agentcore-starter-toolkit` | `>=0.3.7` |
| `boto3` | 未固定 |
| `botocore` | `>=1.42.16` |
| `langchain-aws` | `>=1.3.0` |

**Web / API 框架：**

| 依赖 | 版本约束 |
|------|---------|
| `fastapi` | `>=0.136.1` |
| `uvicorn[standard]` | `>=0.40.0` |
| `python-multipart` | `>=0.0.21` |
| `httpx` | `>=0.28.1` |
| `aiofiles` | `>=25.1.0` |
| `fastmcp` | `>=3.1.0` |

**数据持久化 / 缓存 / 队列：**

| 依赖 | 版本约束 |
|------|---------|
| `redis` | `>=7.4.0` |
| `celery` | `>=5.6.3` |
| `psycopg[binary,pool]` | `>=3.3.4` |
| `pgvector` | `>=0.3.6` |

**配置 / 校验 / 安全：**

| 依赖 | 版本约束 |
|------|---------|
| `pydantic` | `>=2.12.5` |
| `pydantic-settings` | `>=2.12.0` |
| `python-dotenv` | `>=1.2.1` |
| `python-jose[cryptography]` | `>=3.5.0` |
| `python3-saml` | `>=1.16.0` |
| `jsonschema` | `>=4.25.1` |
| `json-repair` | `>=0.59.5` |

**文档解析 / 办公文件：**

| 依赖 | 版本约束 |
|------|---------|
| `pandas` | `>=3.0.2` |
| `openpyxl` | `>=3.1.5` |
| `python-docx` | `>=1.2.0` |
| `python-pptx` | `>=1.0.2` |
| `pypdf2` | `>=3.0.1` |
| `pdfplumber` | `>=0.11.9` |
| `pymupdf` | `>=1.27.2.3` |
| `pillow` | `>=11.3.0` |
| `markdown` | `>=3.10.2` |
| `html2text` | `>=2025.4.15` |
| `beautifulsoup4` | `>=4.14.3` |
| `chardet` | `>=7.4.3` |
| `xmltodict` | `>=1.0.4` |

**HTTP / 爬虫 / 搜索：**

| 依赖 | 版本约束 |
|------|---------|
| `requests` | `>=2.32.5` |
| `duckduckgo-search` | `>=8.1.1` |
| `browser-use` | `>=0.11.13` |
| `feedparser` | 未固定 |

**可视化 / 图：**

| 依赖 | 版本约束 |
|------|---------|
| `matplotlib` | `>=3.10.9` |
| `plotly` | `>=6.7.0` |
| `graphviz` | `>=0.21` |
| `networkx` | `>=3.6.1` |
| `tabulate` | `>=0.10.0` |

**NLP / 工具：**

| 依赖 | 版本约束 |
|------|---------|
| `nltk` | `>=3.9.4` |
| `pyyaml` | 未固定 |
| `croniter` | `>=6.2.2` |
| `colorama` | 未固定 |
| `rich` | `>=13.0` |
| `setuptools` | `>=82.0.1` |

**OpenTelemetry 观测：**

| 依赖 | 版本约束 |
|------|---------|
| `opentelemetry-api` | `>=1.39.1` |
| `opentelemetry-sdk` | `>=1.39.1` |
| `opentelemetry-exporter-otlp-proto-http` | `>=1.39.1` |
| `opentelemetry-instrumentation-fastapi` | `>=0.60b1` |
| `opentelemetry-instrumentation-botocore` | `>=0.60b1` |
| `opentelemetry-instrumentation-logging` | `>=0.60b1` |
| `opentelemetry-instrumentation-threading` | `>=0.60b1` |
| `opentelemetry-propagator-aws-xray` | `>=1.0.2` |

::: tip
更新依赖时**优先用 `uv pip install` 而非 `pip`**（见 `CLAUDE.md` 的 "Development Setup" 段）。
:::

---

## 环境准备

### 1. 安装 Git

```bash
# macOS
brew install git

# Ubuntu/Debian
sudo apt-get install git

# 验证安装
git --version
```

### 2. 配置 Git 用户信息

```bash
git config --global user.name "你的名字"
git config --global user.email "your.email@example.com"
```

### 3. 配置 SSH 密钥（推荐）

```bash
# 生成 SSH 密钥
ssh-keygen -t ed25519 -C "your.email@example.com"

# 添加到 ssh-agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# 复制公钥，添加到 GitHub
cat ~/.ssh/id_ed25519.pub
```

### 4. 克隆代码

```bash
# 使用 SSH 克隆（推荐）
git clone git@github.com:hy714335634/Nexus-AI.git

# 或使用 HTTPS
git clone https://github.com/hy714335634/Nexus-AI.git

cd Nexus-AI
```

### 5. Python 与依赖

```bash
# 创建虚拟环境（.venv 为项目约定路径）
python -m venv .venv

# 激活虚拟环境
source .venv/bin/activate

# 安装 uv（推荐的包管理器）
pip install uv

# 安装依赖
uv pip install -r requirements.txt
```

### 6. 前端与基础设施

```bash
# 前端依赖
cd web && npm install && cd -

# 初始化 AWS 基础设施（DynamoDB 表、SQS 队列、S3 桶）
./nexus-cli init
```

### 7. AWS 凭证（必需）

运行时强依赖 AWS 服务，必须提前配置：

```bash
aws configure
```

| AWS 服务 | 用途 |
|---------|------|
| Bedrock | Claude 模型推理（Sonnet / Opus / Haiku） |
| DynamoDB | 所有持久化数据 |
| SQS | 异步任务队列（build / deploy / notification） |
| S3 | 产物、会话存储、附件、skills |

---

## 分支策略

项目采用**简化版 GitHub Flow**，所有分支都**从 `main` 创建并最终合并回 `main`**。

### 分支类型一览

| 分支 | 用途 | 合并目标 |
|------|------|----------|
| `main` | 主分支 | — |
| `feature/*` | 功能开发 | `main` |
| `fix/*` | Bug 修复 | `main` |
| `hotfix/*` | 紧急修复 | `main` |

### 分支流程

```
main ────●────────●────────●────────●────────
         │        ↑        ↑        ↑
         │        │        │        │
feature  └────●───┘        │        │
                           │        │
fix                   ●────┘        │
                                    │
hotfix                         ●────┘
```

### 命名规范：`&lt;type&gt;/&lt;description&gt;`

| 类型 | 说明 | 示例 |
|------|------|------|
| `feature` | 新功能 | `feature/add-pricing-agent` |
| `fix` | Bug 修复 | `fix/login-error` |
| `hotfix` | 紧急修复 | `hotfix/critical-bug` |
| `docs` | 文档更新 | `docs/update-readme` |
| `refactor` | 代码重构 | `refactor/agent-factory` |
| `test` | 测试相关 | `test/add-unit-tests` |
| `chore` | 构建/工具 | `chore/update-deps` |

### 创建分支的标准动作

```bash
# 1. 同步 main
git checkout main
git pull origin main

# 2. 从 main 创建并切换到新分支
git checkout -b feature/your-feature-name
```

---

## 开发流程

### 工作循环

1. 在新分支上做改动
2. `git status` 查看当前修改
3. `git add` 进暂存区（推荐 `git add -p` 逐块确认）
4. `git commit` 按规范写 message
5. `git push` 到远端同名分支
6. 在 GitHub 上开 PR，指定 Reviewer
7. 通过审查后合并

### 暂存与提交

```bash
# 查看状态
git status

# 添加
git add path/to/file.py        # 单文件
git add .                      # 所有修改
git add -p                     # 交互式，逐块确认（推荐）

# 提交
git commit -m "feat: add new pricing calculation feature"
```

### 推送

```bash
# 首次推送新分支（建立上游追踪）
git push -u origin feature/your-feature-name

# 后续推送
git push
```

### 处理冲突

```bash
# 拉取最新 main 并变基
git fetch origin main
git rebase origin/main

# 解决冲突后继续
git add .
git rebase --continue

# 变基后用 --force-with-lease 强推（比 --force 安全）
git push --force-with-lease
```

::: warning
**不要 `git push --force` 到共享分支或 `main`**，可能覆盖他人工作。变基后统一用 `--force-with-lease`。
:::

---

## Commit Message 规范

采用 [Conventional Commits](https://www.conventionalcommits.org/)。

### 格式

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type 类型（穷举）

| 类型 | 说明 |
|------|------|
| `feat` | 新功能 |
| `fix` | Bug 修复 |
| `docs` | 文档更新 |
| `style` | 代码格式（不影响功能） |
| `refactor` | 代码重构 |
| `perf` | 性能优化 |
| `test` | 测试相关 |
| `chore` | 构建/工具/依赖更新 |

### Subject 规则

- 使用英文，动词原形开头
- 首字母小写，不加句号
- 不超过 50 个字符

### 示例

```bash
# 简单提交
git commit -m "feat: add AWS pricing calculation tool"

# 带 scope
git commit -m "fix(agent): resolve memory leak in agent factory"

# 带 body 与 footer
git commit -m "feat(api): add batch processing endpoint

- Add new /api/v2/batch endpoint
- Support up to 100 items per request
- Add rate limiting for batch requests

Closes #123"
```

---

## 创建 Pull Request

1. 打开仓库页面
2. 点击 **Pull requests** → **New pull request**
3. 选择你的分支 → `main`
4. 填写 PR 标题（与 Commit Message 规范一致）和描述
5. 指定 Reviewer 进行代码审查
6. 审查通过后合并

---

## 代码约定（来自 `CLAUDE.md`）

### 通用规则

- **后端代码、变量名、注释一律英文**；UI 字符串支持 i18n（中英双语，必须同步更新）。
- **Prompt 模板**为 `prompts/` 下的 YAML 文件，结构化 schema：`agent.versions[].system_prompt`。
- **工具（Tool）** 使用 Strands 框架的 `@tool` 装饰器，存储在 S3 并同步到 DynamoDB。
- **API 分层**严格按：`api/v2/routers/`（HTTP 层）→ `api/v2/services/`（业务逻辑）→ `api/v2/database/`（持久化）组织。
- **配置优先级**：环境变量 > `config/default_config.yaml` > 代码默认值。运行时参数写在 `config/service_config.yaml`（worker 数、线程池、超时）。
- **认证模式**：开发模式使用 `admin/nexus` 凭据；生产使用 SAML 2.0 SSO。

### 关键环境变量（示例）

| 变量 | 说明 |
|------|------|
| `API_PORT` | API 监听端口（默认 8000） |
| `NEXUS_API_WORKERS` | API 工作进程数 |

---

## 服务架构速查（贡献者视角）

### 5 个核心服务 + 2 个可选

| 序号 | 服务 | 入口 | 说明 |
|------|------|------|------|
| 1 | API Backend | `api/v2/main.py` | FastAPI + Uvicorn；30+ routers、28+ services；JWT 认证、SSE 流式、OpenTelemetry |
| 2 | Worker | `worker/main.py` | SQS 消息消费者；单阶段执行模型（一条消息触发一个 stage，完成后路由到下一 stage） |
| 3 | Web Frontend | `web/` | Next.js 14 App Router + React 18 + TypeScript + Tailwind CSS；TanStack Query；i18n |
| 4 | Gateway | `nexus_utils/gateway/__main__.py` | 流代理；支持 WebSocket、Valkey 缓冲、重连 |
| 5 | Bridge | `nexus_utils/bridge/` | 远程服务器连接管理器（SSH-like 操作） |
| 6（可选） | MCP Server | `nexus_utils/mcp/mcp_server/__main__.py` | FastMCP 3.x；将 agents 暴露为 MCP 工具（Kiro / Claude Code / Cursor）；直接调用 agent_factory，绕过 API |
| 7（可选） | Event Scheduler | `nexus_utils/event_scheduler/` | 类 Cron 的定时任务执行 |

### 默认端口

| 服务 | 端口 |
|------|------|
| Web | 3000 |
| API | 8000 |
| Bridge | 8001 |
| MCP | 9000 |

### 关键子系统

| 子系统 | 入口 | 要点 |
|--------|------|------|
| Workflow Engine | `nexus_utils/workflow/engine_v2.py` | SQS 驱动单阶段执行；支持 fork/join 并行；从 DDB 前置 stage 结果装配输入；JSON 校验 + 重试 |
| Agent Factory | `nexus_utils/agent_factory.py` | `create_agent_from_prompt_template()` 从 YAML 模板创建 agent；多 provider：Bedrock、OpenAI、Anthropic、LiteLLM、Ollama、Gemini；stage 日志写入 `logs/stages/` |
| Database Layer | `api/v2/database/dynamodb.py` | DynamoDB 单例客户端 + 连接池；节流指数退避重试；28+ 张表（projects / agents / sessions / messages / stages / tools / skills 等） |
| Configuration | `nexus_utils/config_loader.py` | 环境变量 > `default_config.yaml` > 代码默认；运行时参数在 `service_config.yaml` |

### Workflow 定义（`config/workflows.yaml`）

| 名称 | 版本 | Stage 数 | 备注 |
|------|------|---------|------|
| `agent_build` | V2 | 8 | 含 fork/join 并行 agent 设计 |
| `agent_update` | V2 | 5 | 支持 `skip_stages` |
| `tool_build` | V2 | 5 | — |
| `skill_build` | V2 | 5 | — |
| `magician` | — | 1 | 单阶段意图路由 |

### 数据流模式

- **Agent Build**：API 收到请求 → SQS 消息 → Worker 执行 stage → 写 DDB → 通过 SQS 路由下一 stage → 前端轮询 stages 表
- **Agent Runtime（Chat）**：前端 SSE 请求 → Sessions Router → AgentRuntimeService → S3SessionManager 加载上下文 → Strands `agent.stream()` → 事件解析并通过 SSE 下发 → 会话存 S3
- **MCP**：IDE MCP 客户端 → MCP Server（Bearer Token 认证）→ `agent_factory.create_agent_from_prompt_template()` → Bedrock → 响应

---

## 常用命令速查

### 服务管理（`./nexus-cli`）

```bash
./nexus-cli service start              # 启动所有服务（API + Worker + Web）
./nexus-cli service start --api        # 仅 API
./nexus-cli service start --worker     # 仅 Worker
./nexus-cli service start --web        # 仅 Web
./nexus-cli service start --mcp        # 所有 + MCP Server
./nexus-cli service start --otel       # 启动 OTEL Collector
./nexus-cli service start --dev        # 开发模式
./nexus-cli service stop               # 停止全部
./nexus-cli service status             # 查看状态
./nexus-cli service logs --api         # 查看 API 日志
./nexus-cli service logs -f            # 跟随所有日志
./nexus-cli service restart            # 重启全部
```

### 前端

```bash
cd web
npm run dev          # 开发服务器（端口 3000）
npm run build        # 生产构建
npm run lint         # ESLint
npm run test         # Jest 测试
npm run test:watch   # Jest watch 模式
```

### 直接调用 Agent（用于测试）

```bash
source .venv/bin/activate
python agents/system_agents/magician.py -i "your prompt here"
python agents/system_agents/agent_build_workflow/agent_build_workflow.py -i "build description"
```

---

## 常见 Git 操作

```bash
# 撤销最近一次提交（保留修改）
git reset --soft HEAD~1

# 修改最近一次提交信息
git commit --amend -m "new commit message"

# 暂存当前修改
git stash
git stash pop  # 恢复

# 查看提交历史
git log --oneline -10
```

---

## 故障排查

| 现象 | 可能原因 | 对策 |
|------|---------|------|
| `python --version` 不是 3.13 | 本地版本管理器未切到 `.python-version` 指定版本 | 安装 pyenv/uv，在项目目录执行版本切换 |
| `uv pip install` 失败 | 未安装 uv | `pip install uv` |
| AWS API 调用报 `NoCredentialsError` | 未配置 AWS 凭证 | 运行 `aws configure` |
| `./nexus-cli init` 失败 | AWS 权限不足 / 区域不对 | 检查 IAM 策略与 `AWS_REGION` 环境变量 |
| 推送时被拒绝（non-fast-forward） | 远端已被他人推进 | `git fetch` + `git rebase origin/main` 后 `--force-with-lease` |
| `rebase` 后 PR 评论对不上行 | 强推改变了历史 | 在 PR 描述中说明，或改用 merge commit 流程 |
| 前端报端口 3000 被占用 | 已有进程占用 | `./nexus-cli service stop` 或 `lsof -i:3000` 手动清理 |

---

## 延伸阅读

- `CONTRIBUTING.md`（仓库根目录） — 贡献流程原文
- `CLAUDE.md`（仓库根目录） — Claude Code / IDE 协作指南、项目架构总览
- `pyproject.toml` — 依赖清单与构建配置
- `config/workflows.yaml` — Workflow 定义
- `config/default_config.yaml` / `config/service_config.yaml` — 运行时配置
- [Conventional Commits 规范](https://www.conventionalcommits.org/)
