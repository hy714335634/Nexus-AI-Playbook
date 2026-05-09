---
title: 外部 MCP 服务器
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - config/mcp/**
    - nexus_utils/mcp/mcp_client/**
  generated_at: 2026-05-08T22:32:37+00:00
  generated_by: docs-sync v2
---

# 外部 MCP 服务器

## 概述

除了可以把 Nexus-AI 的 Agent 暴露给 Kiro / Claude Code / Cursor 之外（见 [MCP Server](./mcp-server)），平台也能反过来——让 Agent 调用任何一个 **外部 MCP 服务器**，把外部能力作为工具集接入对话。构建 Agent 时在「工具」面板把某个 MCP 服务器挂进依赖列表，该服务器暴露的所有工具就会自动加载到这个 Agent 的运行时中。

Nexus-AI 同时支持 **三种 MCP 传输**（stdio / SSE / Streamable HTTP），并提供两种配置入口：
- **配置文件**：`config/mcp/*.json`，适合运维在部署时写死系统级 MCP；
- **平台控制台 / REST API**：`/mcp/servers` 一套 CRUD 接口，前端「工具」页面把它封装成表单，适合运行时动态增减。

两种入口在首次启动时会自动合并到 DynamoDB，Agent 构建时始终读取 DynamoDB 中的最新版本。

## 启用前提

开始前请确认：

- 平台已按「集成总览」完成基础部署，`./nexus-cli service status` 三项都为 `running`。
- 运行 Nexus-AI 的宿主机或沙箱节点具备启动目标 MCP 服务器的能力：
  - **stdio 传输**：主机上可执行 `uvx`、`npx`、`python` 等命令（多数 AWS Labs / 社区 MCP 均以 `uvx` 形式发布）。
  - **SSE / HTTP 传输**：从服务进程出站可直达 MCP 服务器的 URL（企业网络需放行该域名）。
- 如果要挂接的 MCP 需要凭证（如 AWS、GitHub Token），已准备好对应的环境变量或 HTTP Header。

::: tip stdio vs HTTP，怎么选
本地或同机运行的工具（文件系统、代码执行、AWS CLI 包装）优先用 **stdio**；多用户共享的长驻服务、第三方 SaaS 优先用 **HTTP**；SSE 主要面向兼容老客户端，新部署推荐直接用 Streamable HTTP。
:::

## 配置步骤

### 方式 A：写入配置文件（系统级）

配置文件目录为 `config/mcp/`。以下几份都会在启动时被自动加载：

| 文件名 | 用途 |
|--------|------|
| `system_mcp_server.json` | 平台预置的系统级 MCP（如 AWS Labs 官方工具），建议只在此处维护由运维负责的条目 |
| `public_mcp_server.json` | 对所有用户开放的第三方 MCP，可按需编辑 |
| `*.json`（其它任意 JSON 文件） | 运维可按业务拆分为独立文件，每个文件同样会被合并加载 |

所有文件共用同一份 Kiro / Cursor 兼容的 JSON 结构：

```json
{
  "mcpServers": {
    "awslabs.core-mcp-server": {
      "transport": "stdio",
      "disabled": false,
      "command": "uvx",
      "args": ["awslabs.core-mcp-server@latest"],
      "env": {
        "FASTMCP_LOG_LEVEL": "ERROR"
      }
    },
    "openskill": {
      "transport": "http",
      "disabled": false,
      "url": "https://mcp.openmcpskills.click/mcp?api_key=sk-mcp-..."
    }
  }
}
```

三种传输的字段要求不同，填错会在启动阶段报 `Invalid configuration`：

| 传输类型 | 必填字段 | 可选字段 |
|---------|---------|---------|
| `stdio` | `command` | `args`、`env` |
| `sse`   | `url`     | `headers` |
| `http`  | `url`     | `headers` |

所有传输类型共享的可选字段：

| 字段 | 说明 |
|------|------|
| `disabled` | `true` 时该服务器不会注册进 Agent，等同于临时关闭 |
| `autoApprove` | 工具名列表，列表中的工具在调用时跳过用户确认 |
| `description` | 展示在平台前端的说明文字 |

改完文件后重启服务：

```bash
./nexus-cli service restart
```

### 方式 B：平台前端 / REST API（运行时增减）

登录控制台 →「工具」→「MCP 服务器」→「新建」，可以三种方式快速添加：

1. **粘贴 JSON**：与配置文件完全一致的片段，可一次导入多个。
2. **命令行**：`npx -y @modelcontextprotocol/server-filesystem /tmp`、`uvx awslabs.aws-pricing-mcp-server@latest` 等，系统会自动拆分成 `command` / `args`，并以包名为默认名称。
3. **URL**：`https://...`、`sse://...`，含 `/sse` 路径时自动识别为 SSE，否则走 Streamable HTTP。

<!-- SCREENSHOT: mcp-client-add-server -->

对应的 REST 接口（前端表单就是封装这些）：

| 方法 | 路径 | 作用 |
|------|------|------|
| `GET` | `/mcp/servers` | 列表；支持 `scope` / `user_id` 过滤 |
| `GET` | `/mcp/servers/{id_or_name}` | 详情 |
| `POST` | `/mcp/servers` | 手动创建一台 |
| `POST` | `/mcp/servers/import` | 一次导入多台（JSON / 命令 / URL 自动识别） |
| `PUT` | `/mcp/servers/{id_or_name}` | 更新字段 |
| `DELETE` | `/mcp/servers/{id_or_name}` | 删除 |
| `POST` | `/mcp/servers/{id_or_name}/enable` | 启用 |
| `POST` | `/mcp/servers/{id_or_name}/disable` | 禁用 |
| `POST` | `/mcp/servers/sync` | 把 `config/mcp/*.json` 同步进 DynamoDB（仅新增，不覆盖） |

示例：通过命令行添加一台 AWS Pricing MCP：

```bash
curl -X POST https://<nexus-host>/api/v2/mcp/servers/import \
  -H 'Content-Type: application/json' \
  -d '{
    "config_data": "uvx awslabs.aws-pricing-mcp-server@latest",
    "format": "auto",
    "scope": "shared"
  }'
```

### 作用域：shared vs private

创建时的 `scope` 决定哪些用户能在构建 Agent 时看到这台服务器：

| 取值 | 说明 |
|------|------|
| `shared` | 所有用户可见；适合运维统一维护的系统 MCP |
| `private` | 仅创建者可见；适合每人自带的凭证类 MCP（个人 GitHub Token、私有 API Key 等） |

配置文件里加载进来的服务器默认全部为 `shared`。

### 自动批准列表

`autoApprove` 列出的工具名在调用时不会弹出确认框。建议只对已知安全、无副作用的只读工具使用；涉及写入、外发请求、花费金额的工具应保持手动确认。

```json
"autoApprove": ["search_docs", "list_resources"]
```

## 验证

MCP 服务器挂进来不代表一定能用。下面三步按顺序确认。

### 步骤 1：测试连接

在前端列表页点「测试连接」，或调用接口：

```bash
curl -X POST https://<nexus-host>/api/v2/mcp/servers/<name-or-id>/test
```

成功响应示例：

```json
{
  "success": true,
  "data": {
    "success": true,
    "server_name": "awslabs.core-mcp-server",
    "tool_count": 8,
    "tools": [
      { "name": "prompt_understanding", "description": "...", "input_schema": {...} }
    ]
  }
}
```

`tool_count > 0` 即代表进程成功拉起、握手完成、工具清单已拉回。默认 30 秒握手超时，stdio 首次安装包可能较慢（`uvx` 会拉取依赖），超时可重试一次。

### 步骤 2：列出工具

可以单独拉取工具清单，用于前端挑选 `autoApprove` 列表：

```bash
curl https://<nexus-host>/api/v2/mcp/servers/<name-or-id>/tools
```

### 步骤 3：在 Agent 里用起来

1. 进入 Agent 编辑页 →「工具」→「MCP 依赖」，勾选刚添加的服务器。
2. 保存并构建 Agent。
3. 在「对话」里发一句能触发该工具的 prompt（例如对 `aws-pricing` 问「t3.medium 一小时多少钱」）。

看到工具实际被调用、返回正确结果，才算端到端打通。

<!-- SCREENSHOT: mcp-client-agent-invocation -->

## 故障排查

| 现象 | 可能原因 | 建议操作 |
|------|---------|---------|
| 启动日志报 `Failed to import MCP client library` | 运行环境缺少 `mcp` Python 包 | 进入 `.venv` 重新 `pip install -r requirements.txt` |
| 「测试连接」提示 `Connection timeout after 30 seconds` | stdio 服务器首次下载依赖慢；或 HTTP URL 不可达 | 主机先手动跑一次 `uvx &lt;package&gt;` 预热；或用 `curl` 先确认 URL 连通 |
| `Invalid configuration for server 'X'` | stdio 缺 `command`，或 SSE/HTTP 缺 `url` | 按本页「传输字段表」补齐必填字段 |
| 前端看不到刚加的 MCP | 建时选了 `private`，当前用户不是创建者；或没刷新页面 | 改成 `scope=shared` 或切换到创建者账号 |
| Agent 运行时找不到某个已存在的 MCP | 该服务器 `disabled=true`；或名称拼错 | 在列表页启用，或对比 Agent 的 `mcp_dependencies` 配置 |
| 工具调用突然全部需要二次确认 | `autoApprove` 字段被清空或写错工具名 | 核对工具名与「列表工具」接口返回的 `name` 一致 |
| 修改了 `config/mcp/*.json`，但前端仍显示旧配置 | 配置文件加载策略是「仅新增、不覆盖」，修改不会自动同步到 DDB | 删除 DDB 中同名条目，或在前端手动编辑；或调用 `POST /mcp/servers/sync`（同样仅新增） |
| HTTP MCP 报 `401 / 403` | `url` 中的 API Key 过期，或 `headers` 没带鉴权 | 刷新 API Key；或在「更新」时补 `headers` 字段 |
| 长时间推理的 MCP 工具被截断 | 默认 stdio 握手超时 120 秒、连接测试超时 30 秒 | 挂载到 Agent 后超时由 Agent 控制，实际运行不受这两个值影响；如握手就卡住请先在本机排查 |
| 跑 `sync` 接口后本地改动没生效 | `sync` 只会新增 DDB 中不存在的条目，已有条目不会被覆盖 | 先在前端删除冲突条目，再执行 `sync`；或直接用 `PUT /mcp/servers/{id}` |

::: info 排查顺序
永远是：**在宿主机上手动能跑通 → `POST /test` 能返回 `tool_count > 0` → Agent 里能调用**。前两步没通之前不要怀疑 Agent 配置。
:::
