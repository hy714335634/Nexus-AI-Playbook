---
title: Agent as MCP Tool
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - nexus_utils/mcp/mcp_server/**
  generated_at: 2026-05-08T22:35:45+00:00
  generated_by: docs-sync v2
---

# Agent as MCP Tool

## 概述

Nexus-AI 自带一个 **MCP Server**，能把平台上已经构建并处于 `running` 状态的 Agent 反过来暴露给 Claude Code、Kiro、Cursor 等任意 MCP 客户端。外部客户端连上之后，每个 Agent 都会显示为一个独立的 Tool，通过 `query` 参数调用、返回 Agent 的文本响应。换句话说——平台既是 MCP 宿主，也是 MCP 供应方。

MCP Server 不经过 REST API 层，直接调用内部 Agent 工厂执行推理，因此不额外占用一份 HTTP 配额。通信基于 **Streamable HTTP**，默认端口 `9000`，路径 `/mcp`，统一用 **Bearer Token** 做认证。Token 首次启动时会自动生成并打印在控制台，也可以通过环境变量 `NEXUS_MCP_TOKEN` 固定下来。

::: tip 和外部 MCP 服务器的区别
本页讲的是「让 Nexus-AI 的 Agent 作为 MCP 工具给外部客户端用」；相反方向——「让平台 Agent 调用其他 MCP 服务器」见 [外部 MCP 服务器](./mcp-clients)。两者接口不同、配置不同，不要混用。
:::

## 启用前提

开始前请确认：

- 平台已按「集成总览」完成部署，`./nexus-cli service status` 返回三项 `running`。
- 至少有一个 Agent 的 `status=running`（在「Agent 管理」页面构建成功后状态即变为 `running`）。MCP Server 只会注册 `running` 的 Agent，其它状态会被自动跳过。
- 宿主机的 `9000` 端口（或你自定义的端口）对 MCP 客户端可达。跨机连接时请同步放行防火墙规则。
- Python 运行环境已安装 `fastmcp`（随 Nexus-AI 主依赖一起装好，无需额外操作）。

## 配置步骤

### 1. 选择 Token 模式

启动时的 Token 有两种来源：

| 模式 | 适用场景 | 如何启用 |
|------|---------|---------|
| **自动生成** | 开发、单机试用 | 不设任何环境变量，Server 启动时会生成一次性 Token 并打印到控制台 |
| **固定值** | 生产、多节点部署、CI | 预先通过 `NEXUS_MCP_TOKEN` 提供一个长度 ≥ 32 的随机字符串 |

::: warning 固定 Token 请妥善保管
MCP Server 不支持 Token 轮转；一旦泄露，相当于把所有 Agent 的调用权限交给外部。建议用密钥管理服务（Secrets Manager、Vault 等）注入环境变量，不要明文写进 shell 历史或 Git。
:::

### 2. 选择端口（可选）

默认 `9000`。如需修改，在启动前设置 `NEXUS_MCP_PORT`：

```bash
export NEXUS_MCP_PORT=9100
export NEXUS_MCP_TOKEN=$(openssl rand -base64 48)
```

### 3. 启动 MCP Server

MCP Server 作为独立模块启动，不随 `./nexus-cli service start` 自动拉起：

```bash
source .venv/bin/activate
python -m nexus_utils.mcp.mcp_server
```

启动成功后控制台会打印一块以 `=` 分隔的配置信息：

```text
============================================================
  Nexus-AI MCP Server
============================================================
  Port:  9000
  URL:   http://localhost:9000/mcp

  Security Token (auto-generated):
  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

  MCP client config:
  {
    "mcpServers": {
      "nexus-ai": {
        "url": "http://localhost:9000/mcp",
        "headers": {
          "Authorization": "Bearer xxxxxxxx..."
        }
      }
    }
  }
============================================================
```

如果 Token 来自环境变量，最后两行会变成 `Using token from NEXUS_MCP_TOKEN env var`，不会再回显明文。

<!-- SCREENSHOT: mcp-server-startup-banner -->

### 4. 后台常驻

生产部署建议丢给 `systemd`、`supervisord` 或容器 restart policy 管理。示例 `systemd` 单元：

```ini
[Unit]
Description=Nexus-AI MCP Server
After=network.target

[Service]
Type=simple
User=nexus
Environment=NEXUS_MCP_PORT=9000
Environment=NEXUS_MCP_TOKEN=__replace_me__
WorkingDirectory=/opt/nexus-ai
ExecStart=/opt/nexus-ai/.venv/bin/python -m nexus_utils.mcp.mcp_server
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

### 5. 客户端配置

把启动横幅中的 JSON 片段拷进 MCP 客户端（Claude Code、Cursor、Kiro 均使用同一份 `mcpServers` 格式）。下例是 Claude Code 的 `~/.claude/mcp.json`：

```json
{
  "mcpServers": {
    "nexus-ai": {
      "url": "http://localhost:9000/mcp",
      "headers": {
        "Authorization": "Bearer <your-token>"
      }
    }
  }
}
```

跨机调用时把 `localhost` 换成 MCP Server 所在主机的 IP 或域名；走 HTTPS 请在反向代理层（Nginx / ALB）做 TLS 终止，MCP Server 本身只监听明文 HTTP。

### 6. Agent 暴露规则

Server 启动时会调用 `list_agents(status="running", limit=100)` 拉取所有在运行的 Agent 并按以下规则注册为 Tool：

| 字段 | 处理方式 |
|------|---------|
| Tool 名 | 取 `agent_name` → 转小写 → 非 `a-z0-9` 字符替换为 `_` → 合并连续下划线 → 去掉首尾下划线 → 截断到 64 字符 |
| Tool 描述 | 优先用 Agent 的 `description` 字段；缺失时回退为 `Invoke Nexus-AI agent: &lt;name&gt;` |
| 参数 | 固定一个 `query: str`，对应发给 Agent 的用户输入 |
| 返回 | Agent 的文本响应；内部异常会以 `Error invoking agent: ...` 字符串形式返回，不中断客户端会话 |

除按 Agent 注册的 Tool 外，还有一个内置管理工具：

| 工具 | 作用 |
|------|------|
| `refresh_agents` | 重新拉取平台上的 `running` Agent 列表并注册 Tool。平台上新建/下线 Agent 后，MCP 客户端无需重启，让模型调用一次这个工具即可 |

## 验证

按顺序三步走。

### 步骤 1：健康检查

MCP Server 的健康探针 **不需要 Token**，可用作存活检测：

```bash
curl -i http://localhost:9000/health
```

返回 `200` 即说明进程已监听端口。`/health` 和 `/healthz` 两个路径等价，挂 Kubernetes `readinessProbe` 任选其一。

### 步骤 2：带 Token 调用 MCP 端点

```bash
curl -X POST http://localhost:9000/mcp \
  -H "Authorization: Bearer <your-token>" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}'
```

返回体中的 `result.tools[]` 数组应包含 `refresh_agents` 以及所有 `running` Agent 对应的 Tool 名。如果只看到 `refresh_agents`，说明平台上暂无 `running` Agent——不是配置错误。

### 步骤 3：从 MCP 客户端真实调用

1. 在 Claude Code / Cursor / Kiro 里重新加载 MCP 配置，让客户端重新连接。
2. 对话框中问一句能触发某个 Agent 的 prompt（例如 Agent 名叫 `sql-expert`，就问「帮我写一条按月聚合订单金额的 SQL」）。
3. 客户端会提示是否调用对应 Tool，确认后返回 Agent 的文本响应。

<!-- SCREENSHOT: mcp-server-claude-code-invocation -->

看到 Agent 实际产出结果才算端到端打通。如果客户端显示 Tool 列表但调用无响应，大概率是单次推理超出默认 **300 秒** 超时（见下表）。

## 故障排查

| 现象 | 可能原因 | 建议操作 |
|------|---------|---------|
| 启动后控制台没有打印 Token | 已设置 `NEXUS_MCP_TOKEN` | 属于正常行为，客户端应使用该环境变量的值 |
| 客户端返回 `401 Missing or invalid Authorization header` | 客户端配置里 `Authorization` 字段缺失或未加 `Bearer ` 前缀 | 检查 `headers.Authorization` 应为 `Bearer &lt;token&gt;` |
| 客户端返回 `403 Invalid token` | 客户端配置的 Token 与 Server 当前使用的不一致；常见于自动生成 Token 后 Server 被重启 | 重新从控制台拷 Token；或改用固定的 `NEXUS_MCP_TOKEN` |
| `tools/list` 只看到 `refresh_agents` | 当前没有 `status=running` 的 Agent；或平台侧 Agent 注册失败 | 先在「Agent 管理」确认有 running 实例，再让客户端调用 `refresh_agents` |
| 平台上新建的 Agent 没有出现在 MCP 客户端 | Server 只在启动与 `refresh_agents` 时枚举 Agent | 在客户端调用一次 `refresh_agents`，无需重启 Server |
| 客户端调用报 `Agent X is not available` | 目标 Agent 已从 `running` 变为其它状态（构建中、已停止） | 在平台重启该 Agent 或选用其他 running Agent |
| 调用时返回 `Agent X execution timed out (300s)` | 单次推理超过默认 300 秒 | 优化 Agent prompt 长度或工具链；或把耗时任务拆分为多次对话 |
| 调用时返回 `Failed to instantiate Agent ...` | Agent 的 `prompt_path` / `agent_name` 缺失，或 prompt 模板文件丢失 | 回到平台「Agent 管理」重新保存并构建该 Agent |
| `/health` 200，但 `/mcp` 握手超时 | 反向代理丢失了 `Transfer-Encoding: chunked` / SSE 流 | Nginx 配置 `proxy_buffering off;` 与 `proxy_http_version 1.1;`；ALB 用 HTTP/2 目标组 |
| 并发调用被串行执行 | 内部线程池 `max_workers=4`，超过该值的调用会排队 | 单实例并发上限固定为 4；更高并发请水平扩容多实例并在前面做负载均衡 |
| 重启后 Token 变了，所有客户端都掉线 | 用了自动生成模式 | 固定 `NEXUS_MCP_TOKEN` 环境变量，重启不再刷新 |

::: info 排查顺序
永远是：**`/health` 200 → `tools/list` 返回完整工具清单 → 客户端真实调用成功**。前两步没通之前不要怀疑平台侧的 Agent 配置。
:::
