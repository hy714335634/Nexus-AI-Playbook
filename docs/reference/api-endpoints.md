---
title: API 端点
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - api/v2/auth/__init__.py
    - api/v2/main.py
    - api/v2/routers/__init__.py
    - api/v2/routers/admin_billing.py
    - api/v2/routers/agent_tools.py
    - api/v2/routers/agents.py
    - api/v2/routers/attachments.py
    - api/v2/routers/audit.py
    - api/v2/routers/projects.py
    - api/v2/routers/sessions.py
  generated_at: 2026-05-09T01:23:51+00:00
  generated_by: docs-sync v2
---

# API 端点

Nexus-AI Platform API v2 的所有 HTTP 端点参考。本文以源码中的 FastAPI 路由为准，按路由文件分节列出。

## 概述

| 项 | 值 |
|---|---|
| 应用名 | `Nexus AI API` |
| 版本字段 | `settings.APP_VERSION`（启动时从配置注入） |
| Base URL | `/api/v2`（所有业务路由统一前缀） |
| 交互式文档 | `GET /docs`（Swagger UI） |
| ReDoc | `GET /redoc` |
| OpenAPI JSON | `GET /openapi.json` |
| 健康检查 | `GET /health`（**不带** `/api/v2` 前缀） |
| 根端点 | `GET /`（**不带** `/api/v2` 前缀） |
| CORS | 来源由 `settings.CORS_ORIGINS` 决定；`allow_methods=*`、`allow_headers=*`、`expose_headers=*`、`max_age=3600` |
| 响应头 | `X-Request-ID`（每请求 UUID）、`X-Process-Time`（秒）、`X-Trace-ID`（启用 observability 时） |

## 认证

认证由全局 `auth_middleware` 在所有请求上执行，随后各 endpoint 再用 `require_permission("&lt;permission&gt;")` 做细粒度鉴权。

| 方法 | Header / 机制 | 说明 |
|---|---|---|
| Bearer Token | `Authorization: Bearer &lt;jwt&gt;` | JWT 中携带 `user_id`、`role`、`name` 等声明；`session_service.create_session` / `list_my_sessions` 等通过 `Depends(get_auth_user)` 注入当前用户 |
| Admin 角色 | JWT 声明 `role=admin` | `/admin/billing/*`、`/audit-logs` 强制 admin，非 admin 返回 `403 admin role required` |

> 登录获取 token、刷新 token 等端点位于 `auth_router`（`api/v2/routers/auth.py`），不在本参考文档的源文件列表中，本文不展开。

## 通用响应结构

除流式端点外，绝大多数 endpoint 返回形如 `APIResponse` 的 JSON 结构：

```json
{
  "success": true,
  "message": "可选的人类可读消息",
  "data": { /* 端点特定载荷 */ },
  "pagination": { /* 列表端点时出现 */ },
  "timestamp": "2026-05-09T01:23:51Z",
  "request_id": "a0f1…"
}
```

### 全局异常处理

未被具体端点捕获的异常由全局处理器转为 HTTP 500：

```json
{
  "success": false,
  "error": {
    "code": "INTERNAL_ERROR",
    "message": "服务器内部错误",
    "request_id": "a0f1…"
  }
}
```

### 典型状态码

| 状态码 | 触发场景 |
|---|---|
| 200 | 成功 |
| 400 | `ValueError` / 必填参数缺失 / `无效的状态` / `Favorite agent requires real_agent_id in metadata` |
| 401 | 未认证（`未认证`） |
| 403 | `admin role required` |
| 404 | 资源不存在（`Agent {id} 不存在`、`会话 {id} 不存在`、`项目 {id} 不存在` 等） |
| 408 | `invoke_agent` 内部 `TimeoutError`（300 秒超时） |
| 410 | Stream 已过期（`Stream 已过期或不存在，请从消息历史加载`） |
| 500 | 捕获兜底异常，见各端点错误消息 |
| 503 | `/health` 任一依赖 `degraded` |

## 路由总览

| Router 文件 | Tags | 路由前缀（在 `/api/v2` 之后） | 端点数（本文所列） |
|---|---|---|---|
| `main.py`（健康 / 根） | — | 无前缀 | 2 |
| `agents.py` | `Agents` | `/agents` | 10 |
| `sessions.py` | `Sessions` | 无独立前缀，多为 `/sessions/*`、`/agents/{agent_id}/sessions`、`/me/sessions` | 10 |
| `projects.py` | `Projects` | `/projects` | 12 |
| `agent_tools.py` | `Agent Tools` | `/tools` | 3 |
| `attachments.py` | `Attachments` | 无独立前缀，多为 `/sessions/{session_id}/attachments*` | 6 |
| `admin_billing.py` | `admin-billing` | `/admin/billing` | 6 |
| `audit.py` | `Audit Logs` | `/audit-logs` | 1 |

## 根与健康检查

### `GET /`

返回平台元信息。

请求参数：无。

响应：

```json
{
  "message": "Nexus AI Platform API",
  "version": "<APP_VERSION>",
  "docs": "/docs",
  "health": "/health",
  "api_prefix": "/api/v2"
}
```

### `GET /health`

健康检查，探测 DynamoDB 与 SQS 依赖。

响应：

```json
{
  "status": "healthy",
  "service": "nexus-ai-api",
  "version": "<APP_VERSION>",
  "checks": {
    "dynamodb": "healthy",
    "sqs": "healthy"
  }
}
```

状态码：任一 check 不为 `healthy` 时整体 `status` 变为 `degraded` 并返回 `503`，其余返回 `200`。

## Agents — `/api/v2/agents`

### 端点清单

| Method | Path | 权限 | 作用 |
|---|---|---|---|
| GET | `/agents` | `agent:list` | 列出 Agent |
| GET | `/agents/featured` | `agent:list` | 推荐 Agent |
| GET | `/agents/{agent_id}` | `agent:read` | 获取 Agent 详情（支持 agent_id 或 version_group_id） |
| GET | `/agents/{agent_id}/context` | `agent:read` | 获取 Agent 上下文（提示词、工具、模型、运行时等） |
| GET | `/agents/{agent_id}/statistics` | `agent:read` | 获取调用统计 |
| GET | `/agents/{agent_id}/runtime/health` | `agent:read` | 检查运行时状态 |
| POST | `/agents/{agent_id}/invoke` | `agent:invoke` | 同步调用 Agent |
| PUT | `/agents/{agent_id}/status` | `agent:update` | 更新 Agent 状态 |
| DELETE | `/agents/{agent_id}` | `agent:delete` | 删除 Agent |
| GET | `/agents/{agent_id}/versions` | `agent:read` | 获取版本历史 |

### `GET /agents`

**Query 参数**

| 参数 | 必填 | 类型 | 默认 | 说明 |
|---|---|---|---|---|
| `status` | 否 | string | — | 按状态筛选 |
| `category` | 否 | string | — | 按类别筛选 |
| `page` | 否 | int | `1` | 页码，`ge=1` |
| `limit` | 否 | int | `20` | 每页数量，`ge=1, le=100` |

响应 `AgentListResponse`：`data` 为 Agent 列表，附带 `pagination`。

### `GET /agents/featured`

无参数。返回平台内置的快捷 Agent 列表（`APIResponse.data`）。

### `GET /agents/{agent_id}`

**Path 参数**

| 参数 | 必填 | 类型 | 说明 |
|---|---|---|---|
| `agent_id` | 是 | string | Agent ID 或 Version Group ID；先按 agent_id 查找，找不到时退化为 version_group_id 并返回激活版本 |

响应 `AgentDetailResponse.data` 中追加 `version_info`：

```json
{
  "version_group_id": "vg-…",
  "version_number": 1,
  "is_active_version": true,
  "total_versions": 3
}
```

找不到时返回 `404 Agent {agent_id} 不存在`。

### `GET /agents/{agent_id}/context`

返回 Agent 上下文。若 Agent 不存在，返回 `AgentContextResponse(agent_id=...)` 的空上下文（HTTP 200，不 404）。

响应 `data` 字段：

| 字段 | 说明 |
|---|---|
| `agent_id` | Agent ID |
| `display_name` | 展示名（优先 `display_name`，回落 `agent_name`） |
| `system_prompt_path` | 提示词 YAML 路径 |
| `code_path` | 代码路径 |
| `tools_path` | 工具路径 |
| `description` | 描述 |
| `tags` | 标签列表 |
| `runtime_model_id` | 实际生效的模型 ID（`runtime_model_id` > `supported_models[0]` > `bedrock.model_id`） |
| `agentcore_runtime_arn` | AgentCore Runtime ARN（兼容 `agentcore_arn`） |
| `agentcore_runtime_alias` | AgentCore alias（兼容 `agentcore_alias`） |
| `agentcore_region` | 运行区域（兼容 `region`） |
| `tools_count` | 工具数量 |
| `mcp_servers_count` | MCP 服务器数量 |
| `tools_dependencies` | 工具依赖列表（实时从 Prompt YAML 解析） |
| `deployment_type` | 部署类型，默认 `local` |
| `source` | 来源字段，默认空字符串 |
| `sandbox_runtime` | `{"enabled": bool, "default_runtime": "local", "allowed_runtimes": ["local", ...]}`，未启用沙箱时为 `null` |
| `conversation_manager` | `{"enabled": bool, "type": str\|null, "source": "agent"\|"global"}`，解析失败时为 `null` |

### `GET /agents/{agent_id}/statistics`

响应 `AgentStatisticsResponse.data`：

| 字段 | 类型 | 说明 |
|---|---|---|
| `agent_id` | string | Agent ID |
| `total_invocations` | int | 调用次数 |
| `total_input_tokens` | int | 累计输入 Token |
| `total_output_tokens` | int | 累计输出 Token |
| `total_cache_read_tokens` | int | 累计缓存读 Token |
| `total_cache_write_tokens` | int | 累计缓存写 Token |
| `total_tokens` | int | 累计 Token 总数 |
| `total_conversation_turns` | int | 累计对话轮数 |
| `avg_conversation_turns` | float | 平均对话轮数 |
| `total_duration_ms` | int | 累计耗时（毫秒） |
| `avg_duration_ms` | float | 平均耗时（毫秒） |
| `statistics_updated_at` | string \| null | 最后更新时间 |

### `GET /agents/{agent_id}/runtime/health`

响应 `data`：

| 字段 | 类型 | 说明 |
|---|---|---|
| `agent_id` | string | Agent ID |
| `agent_name` | string | Agent 名 |
| `status` | string | Agent 状态 |
| `has_agentcore_arn` | bool | 是否绑定 AgentCore |
| `has_entrypoint` | bool | 是否有本地 entrypoint |
| `runtime_type` | `"agentcore"` \| `"local_http"` | 由 ARN 是否存在决定 |
| `agentcore_arn` | string \| null | ARN |
| `entrypoint` | string \| null | entrypoint 路径 |
| `is_ready` | bool | ARN 或 entrypoint 至少有一项 |

若 Agent 不存在，返回 `success=false, data=null, message="Agent '{agent_id}' not found in database"`（HTTP 200）。

### `POST /agents/{agent_id}/invoke`

同步调用 Agent，通过 `agent_factory` 实例化并返回文本结果。**不创建 Session，不保存消息。超时 300 秒。**

**请求体** `InvokeAgentRequest`（字段以源码中使用到的为准）：

| 字段 | 必填 | 类型 | 说明 |
|---|---|---|---|
| `input_text` | 是 | string | 传给 Agent 的查询内容；空字符串返回 `400 input_text is required` |

**响应** `InvokeAgentResponse.data`：

```json
{
  "invocation_id": "inv_<12hex>",
  "output": "<Agent 返回的文本>",
  "status": "<执行状态>",
  "duration_ms": 1234
}
```

错误码：`404`（Agent 不存在，`ValueError` 映射）、`408`（`TimeoutError` 映射）、`500`（其余）。

### `PUT /agents/{agent_id}/status`

**Query 参数**

| 参数 | 必填 | 类型 | 说明 |
|---|---|---|---|
| `status` | 是 | string | 必须为 `AgentStatus` 枚举合法值；否则 `400 无效的状态: {status}` |
| `error_message` | 否 | string | 同时写入的错误消息 |

### `DELETE /agents/{agent_id}`

**Query 参数**

| 参数 | 必填 | 类型 | 默认 | 说明 |
|---|---|---|---|---|
| `delete_local_files` | 否 | bool | `false` | 是否删除 `agents/`、`prompts/`、`tools/`、`projects/` 下相关文件 |
| `delete_cloud_resources` | 否 | bool | `false` | 是否删除 AgentCore runtime 与 ECR 仓库 |

响应 `data`：

```json
{
  "agent_id": "...",
  "deleted_resources": ["dynamodb", "sessions", "sqs", "..."],
  "errors": ["..."]
}
```

删除操作触发 `audit_log("agent.delete", …)`。当 `success=false` 且 `deleted_resources` 为空时返回 `404`。

### `GET /agents/{agent_id}/versions`

Path 参数接受 `agent_id` 或 `version_group_id`。按版本号升序返回版本列表。

## Sessions — `/api/v2/*`

### 端点清单

| Method | Path | 权限 | 作用 |
|---|---|---|---|
| POST | `/agents/{agent_id}/sessions` | `session:create` | 为指定 Agent 创建会话 |
| GET | `/me/sessions` | `session:list` | 当前用户最近会话（跨 Agent） |
| GET | `/agents/{agent_id}/sessions` | `session:list` | 指定 Agent 的会话列表 |
| GET | `/sessions/{session_id}` | `session:read` | 获取会话详情 |
| GET | `/sessions/{session_id}/messages` | `session:read` | 获取会话消息 |
| GET | `/sessions/{session_id}/stream/events` | `agent:chat` | SSE 断线重连，从 Valkey Stream 回放 |
| GET | `/sessions/{session_id}/stream/status` | `agent:chat` | 查询 session 是否有运行中任务 |
| POST | `/sessions/{session_id}/messages` | `agent:chat` | 发送消息到会话 |
| POST | `/sessions/{session_id}/upload` | `agent:chat` | 上传文件到会话 |
| POST | `/sessions/{session_id}/stream` | `agent:chat` | 流式对话（SSE） |

### `POST /agents/{agent_id}/sessions`

**Path 参数**

| 参数 | 必填 | 类型 | 说明 |
|---|---|---|---|
| `agent_id` | 是 | string | Agent ID；`fav-` 前缀的收藏 Agent 必须在 `metadata.real_agent_id` 中提供真实 ID |

**请求体** `CreateSessionRequest`（字段以源码中使用到的为准）：

| 字段 | 必填 | 类型 | 说明 |
|---|---|---|---|
| `display_name` | 否 | string | 会话展示名 |
| `metadata` | 否 | object | 附加元信息；`fav-` Agent 必须包含 `real_agent_id` |

`user_id` 从 JWT 注入，**不信任客户端传入**。

### `GET /me/sessions`

**Query 参数**

| 参数 | 必填 | 类型 | 默认 | 说明 |
|---|---|---|---|---|
| `limit` | 否 | int | `50` | `ge=1, le=100` |

返回当前用户跨 Agent 的最近会话，每条附带最后一条消息预览。未认证返回 `401 未认证`。

### `GET /agents/{agent_id}/sessions`

**Query 参数**

| 参数 | 必填 | 类型 | 默认 | 说明 |
|---|---|---|---|---|
| `limit` | 否 | int | `20` | `ge=1, le=100` |

普通用户只能看到自己 (`user_id` 匹配) 的会话，管理员 (`role=admin`) 看到全部。`fav-` 前缀 Agent 跳过 agent 存在性校验。

### `GET /sessions/{session_id}`

返回 `SessionDetailResponse`。不存在则 `404`。

### `GET /sessions/{session_id}/messages`

**Query 参数**

| 参数 | 必填 | 类型 | 默认 | 说明 |
|---|---|---|---|---|
| `limit` | 否 | int | `1000` | `ge=1, le=5000` |

### `GET /sessions/{session_id}/stream/events`

SSE 重连端点，从 Valkey Stream 回放或继续接收事件。

**Query 参数**

| 参数 | 必填 | 类型 | 默认 | 说明 |
|---|---|---|---|---|
| `after` | 否 | string | `"0"` | 起始 `event_id`，`0` 表示全量回放 |

**响应头**

| Header | 值 |
|---|---|
| `Content-Type` | `text/event-stream` |
| `Cache-Control` | `no-cache, no-store, must-revalidate` |
| `Connection` | `keep-alive` |
| `X-Accel-Buffering` | `no` |

**事件类型**

| `event` | 用途 |
|---|---|
| `message`（默认） | 正常消息 |
| `catchup_done` | 已追到实时位置，前端可一次性渲染累积历史 |
| `heartbeat` | 每 `NEXUS_SSE_HEARTBEAT_INTERVAL` 秒（默认 15s）发送 |
| `done` | 流结束 |
| `error` | 读取失败 |

每条事件负载会注入 `_event_id` 供断线续传。

当 `stream_key` 不存在且任务状态不是 `running` 时，返回 `410 Stream 已过期或不存在，请从消息历史加载`。

### `GET /sessions/{session_id}/stream/status`

响应：

```json
{
  "success": true,
  "data": {
    "session_id": "...",
    "status": "running",
    "stream_key": "...",
    "has_active_stream": true
  }
}
```

`status` 取值：`running`、`done`、`error`、`null`。

### `POST /sessions/{session_id}/messages`

**请求体** `SendMessageRequest`（源码使用到的字段）：

| 字段 | 必填 | 类型 | 说明 |
|---|---|---|---|
| `role` | 是 | string | 消息角色 |
| `content` | 是 | string | 消息内容 |
| `metadata` | 否 | object | 附加元信息 |
| `files` | 否 | array | 若存在，会写入 `metadata.files_count` 和 `metadata.files[{filename, content_type, size}]` |

### `POST /sessions/{session_id}/upload`

Multipart 上传多个文件。字段 `files`（`List[UploadFile]`）必填。每个文件被 base64 编码后返回。

响应 `data = FileUploadResponse`：

```json
{
  "files": [
    {
      "filename": "...",
      "content_type": "...",
      "size": 1234,
      "data": "<base64>",
      "file_id": "<hex32>"
    }
  ],
  "count": 1,
  "session_id": "..."
}
```

### `POST /sessions/{session_id}/stream`

使用 SSE 返回流式响应；同时支持 AgentCore 运行时和本地 Agent；支持附件。

**请求体** `SendMessageRequest` 相关字段：

| 字段 | 必填 | 类型 | 说明 |
|---|---|---|---|
| `content` | 是 | string | 用户输入 |
| `role` | 是 | string | 消息角色 |
| `metadata` | 否 | object | 附加元信息 |
| `files` | 否 | array | 直接内联文件 |
| `attachment_ids` | 否 | string[] | 优先使用的 presigned 上传附件 ID |
| `runtime_type` | 否 | string | 用户强制指定的运行时（与 `sandbox_service.scheduler.resolve_runtime` 一起解析） |

**运行时解析**：优先 `user_preference` → `resolved_runtime_type`；解析失败默认回落到 `local`。若为 `ec2` 或 `agentcore`，附件只下载到 EFS 工作空间，不走 base64；`local` 时下发 base64 数据。

**数据截断（SSE 稳定性）**

| 常量 | 值 | 用途 |
|---|---|---|
| `TOOL_INPUT_MAX_LENGTH` | `200` | 写入数据库的 `tool_call.input` 截断长度 |
| `TOOL_RESULT_MAX_LENGTH` | `500` | 写入数据库的 `tool_call.result` 截断长度 |
| `SSE_TOOL_INPUT_MAX_LENGTH` | `100` | SSE 推送给前端的 `tool_input` 截断 |
| `SSE_TOOL_RESULT_MAX_LENGTH` | `2000` | SSE 推送给前端的 `tool_result` 截断 |

## Projects — `/api/v2/projects`

### 端点清单

| Method | Path | 权限 | 作用 |
|---|---|---|---|
| POST | `/projects` | `project:create` | 创建项目 |
| POST | `/projects/skill-build` | `project:create` | 创建 Skill 构建项目 |
| POST | `/projects/tool-build` | `project:create` | 创建 Tool 构建项目（V2） |
| GET | `/projects` | `project:list` | 列表 |
| GET | `/projects/{project_id}` | `project:read` | 详情 |
| GET | `/projects/{project_id}/build` | `project:read` | 构建仪表板 |
| GET | `/projects/{project_id}/stages` | `project:read` | 阶段列表 |
| POST | `/projects/{project_id}/control` | `project:update` | 控制项目（pause / resume / stop / cancel） |
| DELETE | `/projects/{project_id}` | `project:delete` | 删除项目 |
| GET | `/projects/{project_id}/files` | `project:read` | 项目目录下所有文件 |
| GET | `/projects/{project_id}/files/{file_path:path}` | `project:read` | 单个文件内容 |
| GET | `/projects/{project_id}/workflow-report` | `project:read` | `workflow_summary_report.md` 内容 |

### `POST /projects`

**请求体** `CreateProjectRequest`：必须包含需求描述（由 service 层验证）。服务端会用 JWT 的 `user_id` 与 `name` 覆盖请求里的对应字段。`ValueError` 映射为 `400`。

### `POST /projects/skill-build`

**请求体**（`dict`）

| 字段 | 必填 | 类型 | 说明 |
|---|---|---|---|
| `requirement` | 是 | string | 空值返回 `400 requirement is required` |
| `skill_name` | 否 | string | 默认空字符串 |
| `tags` | 否 | string[] | 默认 `[]` |

### `POST /projects/tool-build`

**请求体**（`dict`）

| 字段 | 必填 | 类型 | 说明 |
|---|---|---|---|
| `requirement` | 是 | string | 空值返回 `400 requirement is required` |
| `tool_name` | 否 | string | 默认空字符串 |
| `tags` | 否 | string[] | 默认 `[]` |

### `GET /projects`

**Query 参数**

| 参数 | 必填 | 类型 | 默认 | 说明 |
|---|---|---|---|---|
| `status` | 否 | string | — | 状态筛选 |
| `user_id` | 否 | string | — | 用户筛选（仅 admin 有效） |
| `page` | 否 | int | `1` | `ge=1` |
| `limit` | 否 | int | `20` | `ge=1, le=100` |
| `sort_by` | 否 | string | `updated_at` | `updated_at` \| `created_at` \| `project_name` |
| `sort_order` | 否 | string | `desc` | `asc` \| `desc` |

普通用户看自己的项目（含 `user_id` 为 `anonymous`、空字符串、`None` 的历史兼容数据）。

### `GET /projects/{project_id}`

详情。找不到返回 `404`。

### `GET /projects/{project_id}/build`

构建仪表板（`BuildDashboardResponse`）。

### `GET /projects/{project_id}/stages`

返回项目 `stages` 列表（`StageListResponse`）。

### `POST /projects/{project_id}/control`

**请求体** `ProjectControlRequest`

| 字段 | 必填 | 类型 | 说明 |
|---|---|---|---|
| `action` | 是 | string | `pause` \| `resume`（含失败重试） \| `stop` \| `cancel` |
| `reason` | 否 | string | 说明 |

非法 action 由 `ValueError` 映射为 `400`。

### `DELETE /projects/{project_id}`

删除项目及关联阶段数据。

### `GET /projects/{project_id}/files`

遍历项目目录（递归），跳过 `__pycache__` 和 `.` 开头的隐藏文件。

响应 `data.files` 每项：

| 字段 | 说明 |
|---|---|
| `name` | 文件名 |
| `path` | 相对项目根的路径 |
| `size` | 字节数 |
| `type` | 由扩展名推断：`yaml`（`.yaml/.yml`）、`json`、`markdown`、`python`、`text`，其余为 `unknown` |
| `modified_at` | ISO 8601 UTC（`Z` 结尾） |

### `GET /projects/{project_id}/files/{file_path:path}`

读取单个文件内容。

**安全**：`realpath` 必须以项目根路径为前缀，否则 `400 非法的文件路径`。

响应 `data`：

```json
{
  "filename": "agent.yaml",
  "path": "agents/agent.yaml",
  "type": "yaml",
  "content": "…",
  "parsed_content": { /* yaml/json 解析成功时 */ }
}
```

### `GET /projects/{project_id}/workflow-report`

读取 `projects/&lt;project_id&gt;/workflow_summary_report.md`。文件不存在时返回：

```json
{
  "success": true,
  "data": { "exists": false, "content": null }
}
```

## Agent Tools — `/api/v2/tools`

### 端点清单

| Method | Path | 权限 | 作用 |
|---|---|---|---|
| GET | `/tools/categories` | `tool:list` | 获取所有工具分类 |
| GET | `/tools/list` | `tool:list` | 列出所有工具 |
| GET | `/tools/{tool_name}` | `tool:read` | 工具详情（含源码） |

### `GET /tools/categories`

返回内置工具分类合集加上 `Generated Tools`、`System Tools`、`Template Tools`、`MCP Tools`。

### `GET /tools/list`

**Query 参数**

| 参数 | 必填 | 类型 | 说明 |
|---|---|---|---|
| `type` | 否 | string | `builtin` \| `generated` \| `system` \| `template` \| `mcp` |
| `category` | 否 | string | 按分类筛选（不区分大小写，子串匹配） |
| `search` | 否 | string | 按名称或描述模糊匹配（不区分大小写） |

**响应 `data`**

```json
{
  "tools": [ /* ToolInfo[] */ ],
  "total": 42,
  "by_type": {
    "builtin": 25,
    "generated": 0,
    "system": 0,
    "template": 0,
    "mcp": 17
  }
}
```

**`ToolInfo`**

| 字段 | 类型 | 说明 |
|---|---|---|
| `name` | string | 工具名 |
| `type` | string | `builtin` \| `generated` \| `system` \| `template` \| `mcp` |
| `category` | string \| null | 分类 |
| `description` | string \| null | 描述 |
| `file_path` | string \| null | 源码路径（自定义工具） |
| `parameters` | ToolParameter[] | 解析出的参数 |
| `package` | string \| null | 内置工具所属包名 |
| `enabled` | bool | 启用状态 |
| `mcp_server` | string \| null | MCP 工具所属服务器 |
| `return_type` | string \| null | 返回值类型 |

**`ToolParameter`**：`name`、`type`（默认 `"Any"`）、`description`、`required`（默认 `true`）、`default`。

**内置工具清单**（`_get_builtin_tools_info`）

| 名称 | 分类 | 包 |
|---|---|---|
| `retrieve` | RAG & Memory | `strands-agents-tools` |
| `memory` | RAG & Memory | `strands-agents-tools` |
| `mem0_memory` | RAG & Memory | `strands-agents-tools[mem0_memory]` |
| `editor` | File Operations | `strands-agents-tools` |
| `file_read` | File Operations | `strands-agents-tools` |
| `file_write` | File Operations | `strands-agents-tools` |
| `environment` | Shell & System | `strands-agents-tools` |
| `shell` | Shell & System | `strands-agents-tools` |
| `cron` | Shell & System | `strands-agents-tools` |
| `python_repl` | Code Interpretation | `strands-agents-tools` |
| `http_request` | Web & Network | `strands-agents-tools` |
| `slack` | Web & Network | `strands-agents-tools` |
| `image_reader` | Multi-modal | `strands-agents-tools` |
| `generate_image` | Multi-modal | `strands-agents-tools` |
| `nova_reels` | Multi-modal | `strands-agents-tools` |
| `speak` | Multi-modal | `strands-agents-tools` |
| `use_aws` | AWS Services | `strands-agents-tools` |
| `calculator` | Utilities | `strands-agents-tools` |
| `current_time` | Utilities | `strands-agents-tools` |
| `load_tool` | Utilities | `strands-agents-tools` |
| `agent_graph` | Agents & Workflows | `strands-agents-tools` |
| `journal` | Agents & Workflows | `strands-agents-tools` |
| `swarm` | Agents & Workflows | `strands-agents-tools` |
| `stop` | Agents & Workflows | `strands-agents-tools` |
| `think` | Agents & Workflows | `strands-agents-tools` |
| `use_llm` | Agents & Workflows | `strands-agents-tools` |
| `workflow` | Agents & Workflows | `strands-agents-tools` |

**自定义工具扫描**：

| 类型 | 目录 |
|---|---|
| `generated` | `tools/generated_tools/` |
| `system` | `tools/system_tools/` |
| `template` | `tools/template_tools/` |

**MCP 服务器来源**：优先 DynamoDB (`db_client.list_mcp_servers`)，失败回落到本地 `config/mcp/system_mcp_server.json`、`config/mcp/public_mcp_server.json`。

### `GET /tools/{tool_name}`

**Query 参数**

| 参数 | 必填 | 类型 | 说明 |
|---|---|---|---|
| `type` | 否 | string | 指定类型后只搜索对应目录 |

先命中内置工具后直接返回；否则按 `generated` / `system` / `template` 顺序扫描并读取源码。

## Attachments — `/api/v2/sessions/{session_id}/attachments`

### 端点清单

| Method | Path | 权限 | 作用 |
|---|---|---|---|
| POST | `/sessions/{session_id}/attachments/presign-upload` | `session:read` | 生成 S3 预签名上传 URL |
| POST | `/sessions/{session_id}/attachments` | `session:read` | 确认上传完成并缓存到工作空间 |
| GET | `/sessions/{session_id}/attachments` | `session:read` | 会话附件列表 |
| GET | `/sessions/{session_id}/attachments/{attachment_id}/download` | `session:read` | 生成下载预签名 URL |
| DELETE | `/sessions/{session_id}/attachments/{attachment_id}` | `session:read` | 删除附件 |
| GET | `/sessions/{session_id}/messages/{message_id}/attachments` | `session:read` | 指定消息的附件列表 |

### `POST /sessions/{session_id}/attachments/presign-upload`

**请求体** `PresignUploadRequest`

| 字段 | 必填 | 类型 | 说明 |
|---|---|---|---|
| `filename` | 是 | string | 原始文件名 |
| `content_type` | 是 | string | MIME 类型 |
| `file_size` | 是 | int | 字节数 |

**响应** `data = PresignUploadResponse`（字段由 `attachment_service.generate_presign_upload` 返回并原样序列化）。

`ValueError` 映射为 `400`；会话不存在为 `404`。

### `POST /sessions/{session_id}/attachments`

**请求体** `ConfirmUploadRequest`

| 字段 | 必填 | 类型 | 说明 |
|---|---|---|---|
| `attachment_id` | 是 | string | 预签名阶段返回的附件 ID |

确认成功后会异步尝试下载到本地工作空间缓存；失败会记录日志但不影响主流程。

### `GET /sessions/{session_id}/attachments`

返回 `attachment_service.list_session_attachments(session_id)`。

### `GET /sessions/{session_id}/attachments/{attachment_id}/download`

返回 `AttachmentDownloadResponse`。`ValueError` 映射为 `404`。

### `DELETE /sessions/{session_id}/attachments/{attachment_id}`

删除附件。`ValueError` 映射为 `404`。

### `GET /sessions/{session_id}/messages/{message_id}/attachments`

根据 `message_id` 获取附件列表。

## Admin Billing — `/api/v2/admin/billing`

所有端点需要 JWT 中 `role=admin`，否则 `403 admin role required`。

### 端点清单

| Method | Path | 作用 |
|---|---|---|
| GET | `/admin/billing/overview` | 本月总览 |
| GET | `/admin/billing/users/top` | Top-N 用户成本 |
| GET | `/admin/billing/projects/top` | Top-N 项目成本 |
| GET | `/admin/billing/users/{user_id}/usage` | 单用户趋势 |
| GET | `/admin/billing/users/{user_id}/quota` | 单用户配额 |
| PUT | `/admin/billing/users/{user_id}/quota` | 修改配额（触发审计） |

### `GET /admin/billing/overview`

**Query 参数**

| 参数 | 必填 | 类型 | 说明 |
|---|---|---|---|
| `month` | 否 | string | `YYYY-MM` 或 `YYYY-MM-DD`；缺省为当月 1 号 |

响应：

```json
{
  "month": "2026-05-01",
  "totals": { /* svc.get_tenant_totals(m) */ },
  "by_model": { /* svc.get_cost_by_model(m) */ },
  "top_users": [ /* limit=10 */ ],
  "top_projects": [ /* limit=10 */ ]
}
```

异常时返回 `{"error": "..."}`（状态码仍为 200）。

### `GET /admin/billing/users/top`

**Query 参数**

| 参数 | 必填 | 类型 | 默认 | 说明 |
|---|---|---|---|---|
| `month` | 否 | string | 当月 | `YYYY-MM[-01]` |
| `limit` | 否 | int | `20` | `le=200` |
| `tenant_id` | 否 | string | — | 租户过滤 |

### `GET /admin/billing/projects/top`

**Query 参数**

| 参数 | 必填 | 类型 | 默认 | 说明 |
|---|---|---|---|---|
| `month` | 否 | string | 当月 | 同上 |
| `limit` | 否 | int | `20` | `le=200` |

### `GET /admin/billing/users/{user_id}/usage`

**Query 参数**

| 参数 | 必填 | 类型 | 默认 | 说明 |
|---|---|---|---|---|
| `months` | 否 | int | `6` | `le=24`；返回近 N 月趋势、本月按模型分布、当前配额 |

### `GET /admin/billing/users/{user_id}/quota`

响应：

```json
{
  "user_id": "...",
  "quota": { /* svc.get_quota(user_id) 或 {} */ }
}
```

### `PUT /admin/billing/users/{user_id}/quota`

**请求体** `QuotaUpdateBody`

| 字段 | 必填 | 类型 | 默认 | 说明 |
|---|---|---|---|---|
| `monthly_token_budget` | 是 | int | — | 月度 Token 预算 |
| `alert_threshold_pct` | 否 | float | `80` | 达到预算百分比触发告警 |
| `disable_on_exceed` | 否 | bool | `false` | 超限是否禁用 |
| `tenant_id` | 否 | string | `null` | 租户 |
| `notes` | 否 | string | `null` | 备注 |

修改成功后写入 `audit_log("admin.quota.update", …)` 审计事件。

## Audit Logs — `/api/v2/audit-logs`

### `GET /audit-logs`

Admin-only（`Depends(require_admin)`）。列出审计事件。

**Query 参数**

| 参数 | 必填 | 类型 | 默认 | 说明 |
|---|---|---|---|---|
| `limit` | 否 | int | `50` | 返回数量 |
| `user_id` | 否 | string | — | 过滤用户 |
| `action` | 否 | string | — | 过滤动作（如 `agent.delete`、`admin.quota.update`） |

响应：

```json
{
  "success": true,
  "events": [ /* 审计事件 */ ],
  "count": 5
}
```

## 环境变量（影响 API 行为）

| 变量 | 默认 | 说明 |
|---|---|---|
| `BYPASS_TOOL_CONSENT` | `true`（启动前 setdefault） | 跳过 Strands 工具的交互式确认，避免 Web 进程阻塞 |
| `STRANDS_NON_INTERACTIVE` | `true`（启动前 setdefault） | Strands shell 工具非交互模式 |
| `NEXUS_THREAD_POOL_SIZE` | `64` | FastAPI 默认线程池大小（`ThreadPoolExecutor`） |
| `NEXUS_SSE_HEARTBEAT_INTERVAL` | `15` | SSE 心跳间隔秒数 |

## 请求日志与审计

- 每请求由 `add_request_id` 中间件注入 `request.state.request_id`、设置 `X-Request-ID` / `X-Process-Time` 响应头；启用 observability 时同时附上 `X-Trace-ID`。
- `4xx` / `5xx` 分别通过 `record_api_request` 与 `api.record_error` 打点，维度使用 **路由模板** 而非完整路径，避免 UUID 造成的高基数。
- 敏感操作（如 `DELETE /agents/{agent_id}`、`PUT /admin/billing/users/{user_id}/quota`）写入审计日志，可通过 `GET /audit-logs` 查看。
