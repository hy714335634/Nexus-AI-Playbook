---
title: API Endpoints
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

# API Endpoints

Reference for every HTTP endpoint in Nexus-AI Platform API v2. Everything below is grounded in the FastAPI routers and listed per source file.

## Overview

| Item | Value |
|---|---|
| App name | `Nexus AI API` |
| Version field | `settings.APP_VERSION` (injected from configuration at startup) |
| Base URL | `/api/v2` (common prefix for every business router) |
| Interactive docs | `GET /docs` (Swagger UI) |
| ReDoc | `GET /redoc` |
| OpenAPI JSON | `GET /openapi.json` |
| Health check | `GET /health` (**no** `/api/v2` prefix) |
| Root | `GET /` (**no** `/api/v2` prefix) |
| CORS | Origins from `settings.CORS_ORIGINS`; `allow_methods=*`, `allow_headers=*`, `expose_headers=*`, `max_age=3600` |
| Response headers | `X-Request-ID` (per-request UUID), `X-Process-Time` (seconds), `X-Trace-ID` (when observability is enabled) |

## Authentication

The global `auth_middleware` runs on every request, and each endpoint further enforces fine-grained authorization via `require_permission("&lt;permission&gt;")`.

| Method | Header / Mechanism | Notes |
|---|---|---|
| Bearer Token | `Authorization: Bearer &lt;jwt&gt;` | JWT carries claims such as `user_id`, `role`, `name`; `session_service.create_session` / `list_my_sessions` and friends use `Depends(get_auth_user)` to inject the current user |
| Admin role | JWT claim `role=admin` | `/admin/billing/*` and `/audit-logs` require admin; otherwise return `403 admin role required` |

> Endpoints for obtaining and refreshing tokens live in `auth_router` (`api/v2/routers/auth.py`) which is outside this document's source file set and is not covered here.

## Common response shape

Except for streaming endpoints, most endpoints return an `APIResponse`-shaped JSON body:

```json
{
  "success": true,
  "message": "optional human-readable message",
  "data": { /* endpoint-specific payload */ },
  "pagination": { /* present for list endpoints */ },
  "timestamp": "2026-05-09T01:23:51Z",
  "request_id": "a0f1…"
}
```

### Global exception handler

Uncaught exceptions are converted to HTTP 500 by the global handler:

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

### Typical status codes

| Status | Trigger |
|---|---|
| 200 | Success |
| 400 | `ValueError` / missing required field / `无效的状态` / `Favorite agent requires real_agent_id in metadata` |
| 401 | Not authenticated (`未认证`) |
| 403 | `admin role required` |
| 404 | Resource not found (`Agent {id} 不存在`, `会话 {id} 不存在`, `项目 {id} 不存在`, …) |
| 408 | `invoke_agent` internal `TimeoutError` (300-second timeout) |
| 410 | Stream expired (`Stream 已过期或不存在，请从消息历史加载`) |
| 500 | Fall-through exception; see each endpoint's error message |
| 503 | Any `/health` dependency reports `degraded` |

## Router summary

| Router file | Tags | Path prefix (after `/api/v2`) | Endpoints documented |
|---|---|---|---|
| `main.py` (health / root) | — | no prefix | 2 |
| `agents.py` | `Agents` | `/agents` | 10 |
| `sessions.py` | `Sessions` | no common prefix; uses `/sessions/*`, `/agents/{agent_id}/sessions`, `/me/sessions` | 10 |
| `projects.py` | `Projects` | `/projects` | 12 |
| `agent_tools.py` | `Agent Tools` | `/tools` | 3 |
| `attachments.py` | `Attachments` | no common prefix; uses `/sessions/{session_id}/attachments*` | 6 |
| `admin_billing.py` | `admin-billing` | `/admin/billing` | 6 |
| `audit.py` | `Audit Logs` | `/audit-logs` | 1 |

## Root and health check

### `GET /`

Returns platform metadata.

Request parameters: none.

Response:

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

Health check that probes the DynamoDB and SQS dependencies.

Response:

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

Status code: when any check is not `healthy`, the overall `status` becomes `degraded` and the response code is `503`; otherwise `200`.

## Agents — `/api/v2/agents`

### Endpoint list

| Method | Path | Permission | Purpose |
|---|---|---|---|
| GET | `/agents` | `agent:list` | List agents |
| GET | `/agents/featured` | `agent:list` | Featured agents |
| GET | `/agents/{agent_id}` | `agent:read` | Get agent detail (accepts agent_id or version_group_id) |
| GET | `/agents/{agent_id}/context` | `agent:read` | Agent context (prompt, tools, model, runtime, …) |
| GET | `/agents/{agent_id}/statistics` | `agent:read` | Invocation statistics |
| GET | `/agents/{agent_id}/runtime/health` | `agent:read` | Runtime health |
| POST | `/agents/{agent_id}/invoke` | `agent:invoke` | Synchronous invocation |
| PUT | `/agents/{agent_id}/status` | `agent:update` | Update status |
| DELETE | `/agents/{agent_id}` | `agent:delete` | Delete agent |
| GET | `/agents/{agent_id}/versions` | `agent:read` | Version history |

### `GET /agents`

**Query parameters**

| Parameter | Required | Type | Default | Notes |
|---|---|---|---|---|
| `status` | no | string | — | Filter by status |
| `category` | no | string | — | Filter by category |
| `page` | no | int | `1` | Page number, `ge=1` |
| `limit` | no | int | `20` | Page size, `ge=1, le=100` |

Response `AgentListResponse`: `data` is the agent array, with `pagination` attached.

### `GET /agents/featured`

No parameters. Returns the platform-curated featured agents (`APIResponse.data`).

### `GET /agents/{agent_id}`

**Path parameters**

| Parameter | Required | Type | Notes |
|---|---|---|---|
| `agent_id` | yes | string | Agent ID or version group ID; tried as agent_id first, then as version_group_id returning the active version |

`AgentDetailResponse.data` has a `version_info` addendum:

```json
{
  "version_group_id": "vg-…",
  "version_number": 1,
  "is_active_version": true,
  "total_versions": 3
}
```

Returns `404 Agent {agent_id} 不存在` when not found.

### `GET /agents/{agent_id}/context`

Returns the agent context. When the agent does not exist, returns an empty `AgentContextResponse(agent_id=...)` with HTTP 200 (not 404).

Response `data` fields:

| Field | Notes |
|---|---|
| `agent_id` | Agent ID |
| `display_name` | Display name (prefers `display_name`, falls back to `agent_name`) |
| `system_prompt_path` | Prompt YAML path |
| `code_path` | Code path |
| `tools_path` | Tools path |
| `description` | Description |
| `tags` | Tag list |
| `runtime_model_id` | Effective model ID (`runtime_model_id` > `supported_models[0]` > `bedrock.model_id`) |
| `agentcore_runtime_arn` | AgentCore runtime ARN (also accepts `agentcore_arn`) |
| `agentcore_runtime_alias` | AgentCore alias (also accepts `agentcore_alias`) |
| `agentcore_region` | Region (also accepts `region`) |
| `tools_count` | Tool count |
| `mcp_servers_count` | MCP server count |
| `tools_dependencies` | Tool dependencies (resolved from the prompt YAML live) |
| `deployment_type` | Deployment type, defaults to `local` |
| `source` | Source field, defaults to empty string |
| `sandbox_runtime` | `{"enabled": bool, "default_runtime": "local", "allowed_runtimes": ["local", ...]}`; `null` when sandbox is disabled |
| `conversation_manager` | `{"enabled": bool, "type": str\|null, "source": "agent"\|"global"}`; `null` when resolution fails |

### `GET /agents/{agent_id}/statistics`

Response `AgentStatisticsResponse.data`:

| Field | Type | Notes |
|---|---|---|
| `agent_id` | string | Agent ID |
| `total_invocations` | int | Number of invocations |
| `total_input_tokens` | int | Cumulative input tokens |
| `total_output_tokens` | int | Cumulative output tokens |
| `total_cache_read_tokens` | int | Cumulative cache-read tokens |
| `total_cache_write_tokens` | int | Cumulative cache-write tokens |
| `total_tokens` | int | Cumulative total tokens |
| `total_conversation_turns` | int | Cumulative conversation turns |
| `avg_conversation_turns` | float | Average conversation turns |
| `total_duration_ms` | int | Cumulative duration (ms) |
| `avg_duration_ms` | float | Average duration (ms) |
| `statistics_updated_at` | string \| null | Last updated |

### `GET /agents/{agent_id}/runtime/health`

Response `data`:

| Field | Type | Notes |
|---|---|---|
| `agent_id` | string | Agent ID |
| `agent_name` | string | Agent name |
| `status` | string | Agent status |
| `has_agentcore_arn` | bool | Whether bound to AgentCore |
| `has_entrypoint` | bool | Whether a local entrypoint exists |
| `runtime_type` | `"agentcore"` \| `"local_http"` | Chosen by presence of ARN |
| `agentcore_arn` | string \| null | ARN |
| `entrypoint` | string \| null | Entrypoint path |
| `is_ready` | bool | True when ARN or entrypoint is present |

When the agent does not exist the endpoint returns `success=false, data=null, message="Agent '{agent_id}' not found in database"` (HTTP 200).

### `POST /agents/{agent_id}/invoke`

Synchronously invokes the agent via `agent_factory` and returns a text result. **No Session is created, no messages are persisted. Timeout is 300 seconds.**

**Request body** `InvokeAgentRequest` (fields as used in the source):

| Field | Required | Type | Notes |
|---|---|---|---|
| `input_text` | yes | string | Query sent to the agent; an empty string yields `400 input_text is required` |

**Response** `InvokeAgentResponse.data`:

```json
{
  "invocation_id": "inv_<12hex>",
  "output": "<agent text>",
  "status": "<execution status>",
  "duration_ms": 1234
}
```

Errors: `404` (agent not found, mapped from `ValueError`), `408` (mapped from `TimeoutError`), `500` (other).

### `PUT /agents/{agent_id}/status`

**Query parameters**

| Parameter | Required | Type | Notes |
|---|---|---|---|
| `status` | yes | string | Must be a valid `AgentStatus` enum value; otherwise `400 无效的状态: {status}` |
| `error_message` | no | string | Error message to persist |

### `DELETE /agents/{agent_id}`

**Query parameters**

| Parameter | Required | Type | Default | Notes |
|---|---|---|---|---|
| `delete_local_files` | no | bool | `false` | Whether to delete related files under `agents/`, `prompts/`, `tools/`, `projects/` |
| `delete_cloud_resources` | no | bool | `false` | Whether to delete the AgentCore runtime and ECR repository |

Response `data`:

```json
{
  "agent_id": "...",
  "deleted_resources": ["dynamodb", "sessions", "sqs", "..."],
  "errors": ["..."]
}
```

Deletion emits `audit_log("agent.delete", …)`. When `success=false` and `deleted_resources` is empty the endpoint returns `404`.

### `GET /agents/{agent_id}/versions`

The path parameter accepts an `agent_id` or a `version_group_id`. Returns the version list sorted ascending by version number.

## Sessions — `/api/v2/*`

### Endpoint list

| Method | Path | Permission | Purpose |
|---|---|---|---|
| POST | `/agents/{agent_id}/sessions` | `session:create` | Create a session for an agent |
| GET | `/me/sessions` | `session:list` | Current user's recent sessions (across agents) |
| GET | `/agents/{agent_id}/sessions` | `session:list` | Sessions for a specific agent |
| GET | `/sessions/{session_id}` | `session:read` | Session detail |
| GET | `/sessions/{session_id}/messages` | `session:read` | Session messages |
| GET | `/sessions/{session_id}/stream/events` | `agent:chat` | SSE reconnect/replay from Valkey Stream |
| GET | `/sessions/{session_id}/stream/status` | `agent:chat` | Whether a task is running for the session |
| POST | `/sessions/{session_id}/messages` | `agent:chat` | Send a message to a session |
| POST | `/sessions/{session_id}/upload` | `agent:chat` | Upload files to a session |
| POST | `/sessions/{session_id}/stream` | `agent:chat` | Streaming chat (SSE) |

### `POST /agents/{agent_id}/sessions`

**Path parameters**

| Parameter | Required | Type | Notes |
|---|---|---|---|
| `agent_id` | yes | string | Agent ID; for favorite agents (prefix `fav-`), `metadata.real_agent_id` must carry the real agent ID |

**Request body** `CreateSessionRequest` (fields as used in the source):

| Field | Required | Type | Notes |
|---|---|---|---|
| `display_name` | no | string | Session display name |
| `metadata` | no | object | Additional metadata; favorite agents must include `real_agent_id` |

`user_id` is injected from the JWT; **client-supplied values are not trusted**.

### `GET /me/sessions`

**Query parameters**

| Parameter | Required | Type | Default | Notes |
|---|---|---|---|---|
| `limit` | no | int | `50` | `ge=1, le=100` |

Returns the current user's most recent sessions across agents, each with a preview of the last message. Returns `401 未认证` when unauthenticated.

### `GET /agents/{agent_id}/sessions`

**Query parameters**

| Parameter | Required | Type | Default | Notes |
|---|---|---|---|---|
| `limit` | no | int | `20` | `ge=1, le=100` |

Regular users only see their own sessions (matching `user_id`); admins (`role=admin`) see everything. Agents prefixed with `fav-` skip the existence check.

### `GET /sessions/{session_id}`

Returns a `SessionDetailResponse`. `404` when missing.

### `GET /sessions/{session_id}/messages`

**Query parameters**

| Parameter | Required | Type | Default | Notes |
|---|---|---|---|---|
| `limit` | no | int | `1000` | `ge=1, le=5000` |

### `GET /sessions/{session_id}/stream/events`

SSE reconnect endpoint that replays or continues events from a Valkey Stream.

**Query parameters**

| Parameter | Required | Type | Default | Notes |
|---|---|---|---|---|
| `after` | no | string | `"0"` | Starting `event_id`; `0` means replay from the beginning |

**Response headers**

| Header | Value |
|---|---|
| `Content-Type` | `text/event-stream` |
| `Cache-Control` | `no-cache, no-store, must-revalidate` |
| `Connection` | `keep-alive` |
| `X-Accel-Buffering` | `no` |

**Event types**

| `event` | Purpose |
|---|---|
| `message` (default) | Regular message |
| `catchup_done` | Caught up to the live position; the frontend can flush accumulated history in one shot |
| `heartbeat` | Emitted every `NEXUS_SSE_HEARTBEAT_INTERVAL` seconds (default 15s) |
| `done` | End of stream |
| `error` | Read failure |

Each event payload is augmented with `_event_id` to support resumption after disconnects.

When `stream_key` does not exist and the task status is not `running`, the endpoint returns `410 Stream 已过期或不存在，请从消息历史加载`.

### `GET /sessions/{session_id}/stream/status`

Response:

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

Possible `status` values: `running`, `done`, `error`, `null`.

### `POST /sessions/{session_id}/messages`

**Request body** `SendMessageRequest` (fields as used in the source):

| Field | Required | Type | Notes |
|---|---|---|---|
| `role` | yes | string | Message role |
| `content` | yes | string | Message content |
| `metadata` | no | object | Additional metadata |
| `files` | no | array | When present, `metadata.files_count` and `metadata.files[{filename, content_type, size}]` are appended |

### `POST /sessions/{session_id}/upload`

Multipart upload of multiple files. Field `files` (`List[UploadFile]`) is required. Each file is base64-encoded before being returned.

Response `data = FileUploadResponse`:

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

Returns a streaming response over SSE; supports both the AgentCore runtime and local agents, and accepts attachments.

**Request body** `SendMessageRequest` relevant fields:

| Field | Required | Type | Notes |
|---|---|---|---|
| `content` | yes | string | User input |
| `role` | yes | string | Message role |
| `metadata` | no | object | Additional metadata |
| `files` | no | array | Inline files |
| `attachment_ids` | no | string[] | Preferred path — pre-signed attachment IDs |
| `runtime_type` | no | string | User-forced runtime; resolved alongside `sandbox_service.scheduler.resolve_runtime` |

**Runtime resolution**: prefers `user_preference`, then falls back to the resolved runtime; on failure defaults to `local`. When the runtime is `ec2` or `agentcore`, attachments are downloaded to the EFS workspace only — no base64 payload. For `local`, base64 data is sent along.

**Truncation (SSE stability)**

| Constant | Value | Purpose |
|---|---|---|
| `TOOL_INPUT_MAX_LENGTH` | `200` | `tool_call.input` truncation length written to the database |
| `TOOL_RESULT_MAX_LENGTH` | `500` | `tool_call.result` truncation length written to the database |
| `SSE_TOOL_INPUT_MAX_LENGTH` | `100` | `tool_input` truncation in SSE frames |
| `SSE_TOOL_RESULT_MAX_LENGTH` | `2000` | `tool_result` truncation in SSE frames |

## Projects — `/api/v2/projects`

### Endpoint list

| Method | Path | Permission | Purpose |
|---|---|---|---|
| POST | `/projects` | `project:create` | Create project |
| POST | `/projects/skill-build` | `project:create` | Create a skill-build project |
| POST | `/projects/tool-build` | `project:create` | Create a tool-build project (V2) |
| GET | `/projects` | `project:list` | List |
| GET | `/projects/{project_id}` | `project:read` | Detail |
| GET | `/projects/{project_id}/build` | `project:read` | Build dashboard |
| GET | `/projects/{project_id}/stages` | `project:read` | Stage list |
| POST | `/projects/{project_id}/control` | `project:update` | Control (pause / resume / stop / cancel) |
| DELETE | `/projects/{project_id}` | `project:delete` | Delete project |
| GET | `/projects/{project_id}/files` | `project:read` | All files under the project directory |
| GET | `/projects/{project_id}/files/{file_path:path}` | `project:read` | Single file content |
| GET | `/projects/{project_id}/workflow-report` | `project:read` | `workflow_summary_report.md` content |

### `POST /projects`

**Request body** `CreateProjectRequest`: must include a requirement description (validated by the service layer). The server overrides `user_id` and `name` with JWT values. `ValueError` maps to `400`.

### `POST /projects/skill-build`

**Request body** (`dict`)

| Field | Required | Type | Notes |
|---|---|---|---|
| `requirement` | yes | string | An empty value returns `400 requirement is required` |
| `skill_name` | no | string | Defaults to empty string |
| `tags` | no | string[] | Defaults to `[]` |

### `POST /projects/tool-build`

**Request body** (`dict`)

| Field | Required | Type | Notes |
|---|---|---|---|
| `requirement` | yes | string | An empty value returns `400 requirement is required` |
| `tool_name` | no | string | Defaults to empty string |
| `tags` | no | string[] | Defaults to `[]` |

### `GET /projects`

**Query parameters**

| Parameter | Required | Type | Default | Notes |
|---|---|---|---|---|
| `status` | no | string | — | Filter by status |
| `user_id` | no | string | — | Filter by user (admin only) |
| `page` | no | int | `1` | `ge=1` |
| `limit` | no | int | `20` | `ge=1, le=100` |
| `sort_by` | no | string | `updated_at` | `updated_at` \| `created_at` \| `project_name` |
| `sort_order` | no | string | `desc` | `asc` \| `desc` |

Regular users see only their own projects (including legacy rows whose `user_id` is `anonymous`, empty string, or `None`).

### `GET /projects/{project_id}`

Detail. `404` when not found.

### `GET /projects/{project_id}/build`

Build dashboard (`BuildDashboardResponse`).

### `GET /projects/{project_id}/stages`

Returns the project `stages` list (`StageListResponse`).

### `POST /projects/{project_id}/control`

**Request body** `ProjectControlRequest`

| Field | Required | Type | Notes |
|---|---|---|---|
| `action` | yes | string | `pause` \| `resume` (including retrying failures) \| `stop` \| `cancel` |
| `reason` | no | string | Reason |

Invalid actions are mapped from `ValueError` to `400`.

### `DELETE /projects/{project_id}`

Deletes the project and its associated stage data.

### `GET /projects/{project_id}/files`

Walks the project directory recursively, skipping `__pycache__` and dotfiles.

Each element in response `data.files`:

| Field | Notes |
|---|---|
| `name` | Filename |
| `path` | Path relative to the project root |
| `size` | Size in bytes |
| `type` | Inferred from extension: `yaml` (`.yaml/.yml`), `json`, `markdown`, `python`, `text`, otherwise `unknown` |
| `modified_at` | ISO 8601 UTC (ending in `Z`) |

### `GET /projects/{project_id}/files/{file_path:path}`

Reads a single file's contents.

**Safety**: the resolved `realpath` must be a prefix of the project root; otherwise returns `400 非法的文件路径`.

Response `data`:

```json
{
  "filename": "agent.yaml",
  "path": "agents/agent.yaml",
  "type": "yaml",
  "content": "…",
  "parsed_content": { /* when yaml/json parsing succeeds */ }
}
```

### `GET /projects/{project_id}/workflow-report`

Reads `projects/&lt;project_id&gt;/workflow_summary_report.md`. When the file is missing:

```json
{
  "success": true,
  "data": { "exists": false, "content": null }
}
```

## Agent Tools — `/api/v2/tools`

### Endpoint list

| Method | Path | Permission | Purpose |
|---|---|---|---|
| GET | `/tools/categories` | `tool:list` | All tool categories |
| GET | `/tools/list` | `tool:list` | List all tools |
| GET | `/tools/{tool_name}` | `tool:read` | Tool detail (includes source code) |

### `GET /tools/categories`

Returns the union of built-in tool categories plus `Generated Tools`, `System Tools`, `Template Tools`, `MCP Tools`.

### `GET /tools/list`

**Query parameters**

| Parameter | Required | Type | Notes |
|---|---|---|---|
| `type` | no | string | `builtin` \| `generated` \| `system` \| `template` \| `mcp` |
| `category` | no | string | Category filter (case-insensitive substring match) |
| `search` | no | string | Fuzzy match on name or description (case-insensitive) |

**Response `data`**

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

| Field | Type | Notes |
|---|---|---|
| `name` | string | Tool name |
| `type` | string | `builtin` \| `generated` \| `system` \| `template` \| `mcp` |
| `category` | string \| null | Category |
| `description` | string \| null | Description |
| `file_path` | string \| null | Source path (for custom tools) |
| `parameters` | ToolParameter[] | Parsed parameters |
| `package` | string \| null | Package name (for built-in tools) |
| `enabled` | bool | Enabled flag |
| `mcp_server` | string \| null | MCP server the tool belongs to |
| `return_type` | string \| null | Return type |

**`ToolParameter`**: `name`, `type` (default `"Any"`), `description`, `required` (default `true`), `default`.

**Built-in tool catalogue** (`_get_builtin_tools_info`)

| Name | Category | Package |
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

**Custom tool scanning**:

| Type | Directory |
|---|---|
| `generated` | `tools/generated_tools/` |
| `system` | `tools/system_tools/` |
| `template` | `tools/template_tools/` |

**MCP server sources**: DynamoDB first (`db_client.list_mcp_servers`); on failure falls back to local `config/mcp/system_mcp_server.json` and `config/mcp/public_mcp_server.json`.

### `GET /tools/{tool_name}`

**Query parameters**

| Parameter | Required | Type | Notes |
|---|---|---|---|
| `type` | no | string | Restricts the search to the matching directory |

Built-in tools are returned directly; otherwise the endpoint scans `generated` / `system` / `template` in order and reads the source code.

## Attachments — `/api/v2/sessions/{session_id}/attachments`

### Endpoint list

| Method | Path | Permission | Purpose |
|---|---|---|---|
| POST | `/sessions/{session_id}/attachments/presign-upload` | `session:read` | Generate an S3 pre-signed upload URL |
| POST | `/sessions/{session_id}/attachments` | `session:read` | Confirm upload and cache into the workspace |
| GET | `/sessions/{session_id}/attachments` | `session:read` | Session attachment list |
| GET | `/sessions/{session_id}/attachments/{attachment_id}/download` | `session:read` | Generate a pre-signed download URL |
| DELETE | `/sessions/{session_id}/attachments/{attachment_id}` | `session:read` | Delete attachment |
| GET | `/sessions/{session_id}/messages/{message_id}/attachments` | `session:read` | Attachments for a specific message |

### `POST /sessions/{session_id}/attachments/presign-upload`

**Request body** `PresignUploadRequest`

| Field | Required | Type | Notes |
|---|---|---|---|
| `filename` | yes | string | Original filename |
| `content_type` | yes | string | MIME type |
| `file_size` | yes | int | Byte size |

**Response** `data = PresignUploadResponse` (fields come from `attachment_service.generate_presign_upload` and are serialized as-is).

`ValueError` maps to `400`; missing session returns `404`.

### `POST /sessions/{session_id}/attachments`

**Request body** `ConfirmUploadRequest`

| Field | Required | Type | Notes |
|---|---|---|---|
| `attachment_id` | yes | string | The attachment ID returned in the presign step |

After confirmation the server asynchronously attempts to cache the file in the local workspace; failures are logged but do not abort the request.

### `GET /sessions/{session_id}/attachments`

Returns `attachment_service.list_session_attachments(session_id)`.

### `GET /sessions/{session_id}/attachments/{attachment_id}/download`

Returns an `AttachmentDownloadResponse`. `ValueError` maps to `404`.

### `DELETE /sessions/{session_id}/attachments/{attachment_id}`

Deletes the attachment. `ValueError` maps to `404`.

### `GET /sessions/{session_id}/messages/{message_id}/attachments`

Returns the attachment list for the given `message_id`.

## Admin Billing — `/api/v2/admin/billing`

Every endpoint requires `role=admin` in the JWT; otherwise returns `403 admin role required`.

### Endpoint list

| Method | Path | Purpose |
|---|---|---|
| GET | `/admin/billing/overview` | Monthly overview |
| GET | `/admin/billing/users/top` | Top-N users by cost |
| GET | `/admin/billing/projects/top` | Top-N projects by cost |
| GET | `/admin/billing/users/{user_id}/usage` | Per-user trend |
| GET | `/admin/billing/users/{user_id}/quota` | Per-user quota |
| PUT | `/admin/billing/users/{user_id}/quota` | Update quota (emits audit log) |

### `GET /admin/billing/overview`

**Query parameters**

| Parameter | Required | Type | Notes |
|---|---|---|---|
| `month` | no | string | `YYYY-MM` or `YYYY-MM-DD`; defaults to the first day of the current month |

Response:

```json
{
  "month": "2026-05-01",
  "totals": { /* svc.get_tenant_totals(m) */ },
  "by_model": { /* svc.get_cost_by_model(m) */ },
  "top_users": [ /* limit=10 */ ],
  "top_projects": [ /* limit=10 */ ]
}
```

On exception the endpoint returns `{"error": "..."}` (still with status 200).

### `GET /admin/billing/users/top`

**Query parameters**

| Parameter | Required | Type | Default | Notes |
|---|---|---|---|---|
| `month` | no | string | current month | `YYYY-MM[-01]` |
| `limit` | no | int | `20` | `le=200` |
| `tenant_id` | no | string | — | Tenant filter |

### `GET /admin/billing/projects/top`

**Query parameters**

| Parameter | Required | Type | Default | Notes |
|---|---|---|---|---|
| `month` | no | string | current month | same as above |
| `limit` | no | int | `20` | `le=200` |

### `GET /admin/billing/users/{user_id}/usage`

**Query parameters**

| Parameter | Required | Type | Default | Notes |
|---|---|---|---|---|
| `months` | no | int | `6` | `le=24`; returns the trend for the last N months, model breakdown for the current month, and current quota |

### `GET /admin/billing/users/{user_id}/quota`

Response:

```json
{
  "user_id": "...",
  "quota": { /* svc.get_quota(user_id) or {} */ }
}
```

### `PUT /admin/billing/users/{user_id}/quota`

**Request body** `QuotaUpdateBody`

| Field | Required | Type | Default | Notes |
|---|---|---|---|---|
| `monthly_token_budget` | yes | int | — | Monthly token budget |
| `alert_threshold_pct` | no | float | `80` | Alert threshold as a percentage of the budget |
| `disable_on_exceed` | no | bool | `false` | Whether to disable the user on overage |
| `tenant_id` | no | string | `null` | Tenant |
| `notes` | no | string | `null` | Notes |

A successful update writes an `audit_log("admin.quota.update", …)` event.

## Audit Logs — `/api/v2/audit-logs`

### `GET /audit-logs`

Admin-only (`Depends(require_admin)`). Lists audit events.

**Query parameters**

| Parameter | Required | Type | Default | Notes |
|---|---|---|---|---|
| `limit` | no | int | `50` | Number of events to return |
| `user_id` | no | string | — | Filter by user |
| `action` | no | string | — | Filter by action (e.g. `agent.delete`, `admin.quota.update`) |

Response:

```json
{
  "success": true,
  "events": [ /* audit events */ ],
  "count": 5
}
```

## Environment variables (affect API behavior)

| Variable | Default | Notes |
|---|---|---|
| `BYPASS_TOOL_CONSENT` | `true` (set via `setdefault` at startup) | Skips Strands tools' interactive confirmation dialog to avoid blocking the web process |
| `STRANDS_NON_INTERACTIVE` | `true` (set via `setdefault` at startup) | Runs Strands shell tools in non-interactive mode |
| `NEXUS_THREAD_POOL_SIZE` | `64` | FastAPI default thread-pool size (`ThreadPoolExecutor`) |
| `NEXUS_SSE_HEARTBEAT_INTERVAL` | `15` | SSE heartbeat interval in seconds |

## Request logging and auditing

- The `add_request_id` middleware injects `request.state.request_id` on every request and sets the `X-Request-ID` / `X-Process-Time` response headers; when observability is enabled it also emits `X-Trace-ID`.
- `4xx` / `5xx` responses are emitted through `record_api_request` and `api.record_error`; the dimension used is the **route template** rather than the raw URL to avoid UUID-induced cardinality explosions.
- Sensitive actions (e.g. `DELETE /agents/{agent_id}`, `PUT /admin/billing/users/{user_id}/quota`) write an audit log entry that can be queried through `GET /audit-logs`.
