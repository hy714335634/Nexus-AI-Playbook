---
title: 在 Nexus-AI 中使用 MCP
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - README.md
    - config/mcp/**
    - nexus_utils/mcp/**
  generated_at: 2026-05-09T02:00:07+00:00
  generated_by: docs-sync v2
---

# 在 Nexus-AI 中使用 MCP

这篇教程带你把 Nexus-AI 与 Model Context Protocol (MCP) 生态打通：一方面把平台上的 Agent 暴露给 Kiro / Claude Code / Cursor 等 IDE 调用，另一方面让 Agent 调用外部 MCP 服务器的工具。

## 你会得到什么

- 一个运行在 `http://localhost:9000/mcp` 的 MCP Server，将平台上所有「运行中」的 Agent 自动注册为 MCP Tool，IDE 直接调用。
- 一份可加入 `config/mcp/` 的 JSON 配置，让 Agent 通过 MCP 协议调用外部工具（如 AWS MCP Server、第三方 HTTP MCP Server）。

## 前置条件

| 项目 | 要求 |
|------|------|
| Nexus-AI 服务 | 已完成 `./nexus-cli init` 和 `./nexus-cli service start` |
| AWS 凭证 | `aws configure` 已配置，已开通 Bedrock 访问 |
| 至少一个运行中的 Agent | 在 Web 控制台中 `status = running`（供 MCP Server 暴露） |
| IDE（可选） | Kiro / Claude Code / Cursor 任选其一 |
| Python | 3.13+ |

## 大约耗时

约 15 分钟（不含 Agent 构建时间）。

---

## Part A：把 Agent 暴露给 IDE（MCP Server）

### 步骤 1: 启动 MCP Server

在 Nexus-AI 根目录执行：

```bash
./nexus-cli service start --mcp
```

`--mcp` 标志会在启动 API / Worker / Web 三个核心服务之外额外拉起 MCP Server。

**期望输出**：控制台会打印一段配置信息，包含端口、URL 和自动生成的 Token：

```
============================================================
  Nexus-AI MCP Server
============================================================
  Port:  9000
  URL:   http://localhost:9000/mcp

  Security Token (auto-generated):
  <一段随机字符串>

  MCP client config:
  {
    "mcpServers": {
      "nexus-ai": {
        "url": "http://localhost:9000/mcp",
        "headers": {
          "Authorization": "Bearer <token>"
        }
      }
    }
  }
============================================================
```

::: tip
如果没看到 Token，启动日志可能被截断。可以用 `./nexus-cli service logs --mcp` 查看，也可以读取 `.pids/mcp_token` 文件。
:::

<!-- SCREENSHOT: mcp-server-start-console -->

### 步骤 2: 获取并固定 Token（可选）

默认每次启动都会生成新 Token。如果希望 Token 固定不变（例如团队共享配置），通过环境变量预设：

```bash
export NEXUS_MCP_TOKEN="my-stable-token-value"
./nexus-cli service start --mcp
```

端口也可以通过 `NEXUS_MCP_PORT` 修改（默认 `9000`）。

**期望输出**：启动信息中会显示 `Using token from NEXUS_MCP_TOKEN env var`，不再生成随机值。

### 步骤 3: 验证服务可用

在另一个终端执行：

```bash
# 健康检查（无需 Token）
curl http://localhost:9000/health

# 查看日志
./nexus-cli service logs --mcp
```

日志里应该能看到 `Nexus-AI MCP Server initialized. N agent tools registered.`，其中 `N` 等于平台上 `status=running` 的 Agent 数量。

### 步骤 4: 配置 IDE

把步骤 1 输出的 JSON 片段写入对应 IDE 的 MCP 配置文件：

| IDE | 配置文件位置 |
|-----|------------|
| Kiro | `~/.kiro/settings/mcp.json` |
| Claude Code | `.mcp.json`（项目级） |
| Cursor | 参考 Cursor 文档的 MCP 设置 |

示例（`~/.kiro/settings/mcp.json`）：

```json
{
  "mcpServers": {
    "nexus-ai": {
      "url": "http://localhost:9000/mcp",
      "headers": {
        "Authorization": "Bearer <步骤 1 输出的 token>"
      }
    }
  }
}
```

保存后重启 IDE 或重新加载 MCP 连接。

<!-- SCREENSHOT: mcp-ide-config-kiro -->

### 步骤 5: 在 IDE 中调用 Agent

IDE 加载成功后，每个运行中的 Agent 会以一个 MCP Tool 形式出现。Tool 名称由 Agent 名称转换而来（小写、空格和特殊字符替换为下划线、最长 64 字符）。

每个 Tool 接受一个 `query` 字符串参数，返回 Agent 的文本响应。

**期望行为**：在 IDE 中用自然语言调用 Agent，例如："使用 `aws_pricing_agent` 查询 us-east-1 的 m8g.xlarge 价格"，IDE 会通过 MCP 协议调用 Nexus-AI MCP Server，进而触发对应 Agent 的推理。

<!-- SCREENSHOT: mcp-ide-tool-call -->

### 步骤 6: Agent 列表发生变化时刷新

当你在 Web 控制台新增、启用或停用 Agent，IDE 端的 Tool 列表不会自动同步。在 IDE 的 MCP 工具里调用内置的 `refresh_agents` 工具即可刷新：

```
Tool: refresh_agents
Result: Refresh complete. <N> agents available: <tool_name_1>, <tool_name_2>, ...
```

---

## Part B：让 Agent 调用外部 MCP 工具（MCP Client）

Nexus-AI 平台自带 MCP Client，允许 Agent 调用外部 MCP 服务器提供的工具。配置文件位于 `config/mcp/`：

| 文件 | 用途 |
|------|------|
| `system_mcp_server.json` | 系统内置的服务器（如 AWS 官方 MCP Server） |
| `public_mcp_server.json` | 自定义公共服务器 |

### 步骤 7: 添加一个 stdio 传输的 MCP Server

以 AWS Pricing MCP Server 为例，编辑 `config/mcp/system_mcp_server.json`，在 `mcpServers` 下新增一项：

```json
{
  "mcpServers": {
    "awslabs.aws-pricing-mcp-server": {
      "transport": "stdio",
      "disabled": false,
      "command": "uvx",
      "args": [
        "awslabs.aws-pricing-mcp-server@latest"
      ],
      "env": {
        "FASTMCP_LOG_LEVEL": "ERROR",
        "AWS_PROFILE": "default",
        "AWS_REGION": "us-east-1"
      }
    }
  }
}
```

### 步骤 8: 添加一个 HTTP 传输的 MCP Server

对于远程 HTTP MCP Server，使用 `transport: "http"` 并提供 `url`：

```json
{
  "mcpServers": {
    "my-remote-mcp": {
      "transport": "http",
      "disabled": false,
      "url": "https://example.com/mcp?api_key=xxxxx"
    }
  }
}
```

SSE 传输同理，`transport` 字段改为 `"sse"`。

### 步骤 9: 通过 REST API 管理 MCP Server（可选）

除了编辑 JSON 文件，Nexus-AI API 还提供了 `/api/v2/mcp/servers` 下的一组接口，可在 Web 控制台或自动化脚本中使用：

| 操作 | 方法 | 路径 |
|------|------|------|
| 列出所有服务器 | `GET` | `/api/v2/mcp/servers` |
| 创建服务器 | `POST` | `/api/v2/mcp/servers` |
| 导入配置（JSON / 命令 / URL） | `POST` | `/api/v2/mcp/servers/import` |
| 测试连接 | `POST` | `/api/v2/mcp/servers/{server_id}/test` |
| 列出服务器工具 | `GET` | `/api/v2/mcp/servers/{server_id}/tools` |
| 启用 / 禁用 | `POST` | `/api/v2/mcp/servers/{server_id}/enable`（或 `/disable`） |
| 从本地 JSON 同步到 DynamoDB | `POST` | `/api/v2/mcp/servers/sync` |

导入接口支持 `format: "auto" | "json" | "command" | "url"`，可以直接粘贴 `npx -y @modelcontextprotocol/server-filesystem /path` 这样的命令行，或一个 SSE/HTTP URL，由后端自动识别格式。

### 步骤 10: 在 Agent 中声明 MCP 依赖

Agent 的 prompt 模板中通过 `mcp_dependencies` 字段指定要调用哪些 MCP Server（按名称引用配置文件里的 key）。平台在运行时会：

1. 从 DynamoDB 拉取这些 Server 的最新配置（含 Web 控制台上的修改）。
2. 为每个 Server 创建一个 `MCPClient`。
3. 把 Server 提供的工具注入到 Agent。

如果某个依赖不存在或被禁用，对应的客户端会被跳过并记录告警，不会阻塞 Agent 启动。

---

## 验证

完成后执行以下检查，确保两端都工作正常：

- [ ] `./nexus-cli service status` 显示 MCP 行为 `running`。
- [ ] `curl http://localhost:9000/health` 返回 200。
- [ ] 不带 `Authorization` header 访问 `http://localhost:9000/mcp` 返回 `401`。
- [ ] IDE 的 MCP 工具面板列出了你 Nexus-AI 平台上所有运行中 Agent 对应的 Tool。
- [ ] 在 IDE 中调用某个 Tool 能收到 Agent 的文本响应。
- [ ] `config/mcp/` 中新增的服务器在 `GET /api/v2/mcp/servers` 接口中可见。
- [ ] 对新增服务器调用 `POST /api/v2/mcp/servers/{id}/test` 返回 `success: true` 并列出其 tools。

## 常见问题

| 现象 | 原因 | 处理 |
|------|------|------|
| IDE 显示 `Missing or invalid Authorization header` | 未配置或配置错 Bearer Token | 核对 `.pids/mcp_token` 或启动日志 |
| IDE 显示 `Invalid token` | Token 与 Server 不一致 | 服务重启后 Token 可能变了；改用 `NEXUS_MCP_TOKEN` 固定 |
| IDE 中看不到任何 Agent Tool | 平台上没有 `status=running` 的 Agent | 先在 Web 控制台把 Agent 切到运行中，然后调用 `refresh_agents` |
| 新增 MCP Server 后 Agent 仍报找不到工具 | 配置没有同步到 DynamoDB | 调用 `POST /api/v2/mcp/servers/sync` 或重启 API |
| `uvx` 命令不存在 | 未安装 uv 工具链 | 安装 uv：`curl -LsSf https://astral.sh/uv/install.sh \| sh` |

## 下一步

- 想让你的 IDE 直接驱动 Nexus-AI 的 Agent 构建工作流？阅读 [构建你的第一个 Agent](./build-hermes-analyst)（仍在完善）。
- 想了解 Nexus-AI 的整体架构？阅读 [架构概览](../developer/architecture-overview)。
- 想把部署环境完全自动化？阅读 [一键部署参数参考](../reference/deploy-params)。
