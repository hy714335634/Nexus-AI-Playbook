---
title: API 层架构
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - api/v2/auth/__init__.py
    - api/v2/config.py
    - api/v2/core/**
    - api/v2/database/__init__.py
    - api/v2/database/aurora.py
    - api/v2/database/dynamodb.py
    - api/v2/database/sqs.py
    - api/v2/database/valkey.py
    - api/v2/main.py
  generated_at: 2026-05-08T23:57:51+00:00
  generated_by: docs-sync v2
---

# API 层架构

## 概述

API 层是 Nexus-AI 平台的前端服务入口，位于 `api/v2/` 包下。它是一个 **FastAPI** 应用（`api/v2/main.py`），对外暴露 `/api/v2/*` 下的 HTTP / SSE 路由，对内封装四类基础设施客户端（DynamoDB / Aurora PostgreSQL / Valkey / SQS），并统一装载认证中间件、请求 ID / trace 注入、指标记录、全局异常处理。

**职责边界：**

- **上游**：由 ALB / API Gateway 路由到 `uvicorn api.v2.main:app:8000`，前端 Web、外部 API 调用方、CLI 均从这里进入。
- **下游**：通过 `api/v2/database/` 下的四个单例客户端与持久层、消息队列、缓存层交互；长耗时任务（构建 / 部署）通过 SQS 投递给 Worker 进程。
- **不做什么**：不执行 Agent 构建、不直接调用 Bedrock、不运行 AgentCore Runtime 容器。所有重任务都异步化到 SQS 队列，由 `agent_build_service/` 下的 Worker 消费。

**主要入口：**

| 入口 | 位置 | 用途 |
|------|------|------|
| `app` (FastAPI 实例) | `api/v2/main.py:87` | 所有路由装配、中间件注册的根对象 |
| `settings` | `api/v2/config.py:476` | 全局配置（AWS / DB / SQS / AgentCore / 模板） |
| `db_client` | `api/v2/database/dynamodb.py` 末尾 | DynamoDB 单例，Aurora 代理生效后自动路由 |
| `pg_client` | `api/v2/database/aurora.py` 末尾 | Aurora PostgreSQL 单例（12 张迁移表） |
| `sqs_client` | `api/v2/database/sqs.py:2710` | SQS 单例，发送 build / deploy 任务 |
| `cache_client` | `api/v2/database/valkey.py:3050` | Valkey 缓存 + Streams + 分布式锁 |

## 文件组织（File Layout）

| 路径 | 责任 | 依赖 |
|------|------|------|
| `api/v2/main.py` | FastAPI app 构造、中间件、路由装配、健康检查、启动/关闭事件 | `fastapi`, `api/v2/config.py`, `api/v2/auth/middleware.py`, `api/v2/routers/*`, `nexus_utils.observability` |
| `api/v2/config.py` | `Settings` Pydantic 模型；`TABLE_*` 常量；`ALL_TABLES` / `ALL_QUEUES` 列表 | `pydantic_settings`, `nexus_utils.config_loader` |
| `api/v2/auth/__init__.py` | 认证模块占位（中间件在 `auth/middleware.py`，此处仅是包标识） | 无 |
| `api/v2/core/__init__.py` | 重新导出 `stage_config` 模块中的所有公共符号 | `api/v2/core/stage_config.py` |
| `api/v2/core/config.py` | **旧版** Settings（已被 `api/v2/config.py` 取代，仅为兼容保留） | `pydantic_settings` |
| `api/v2/core/exceptions.py` | `APIException` 基类 + `ValidationError` / `ResourceNotFoundError` | 无 |
| `api/v2/core/stage_config.py` | 工作流阶段配置的权威来源；`BuildStage` 枚举动态生成 | `nexus_utils.workflow_config` |
| `api/v2/database/__init__.py` | 导出 `db_client` / `pg_client` / `cache_client` / `sqs_client` 四个单例 | 同目录四个客户端模块 |
| `api/v2/database/dynamodb.py` | `DynamoDBClient` 单例；18 张 DDB 表的 CRUD；Aurora 代理装配 | `boto3`, `api/v2/config.py`, `nexus_utils.config_loader` |
| `api/v2/database/aurora.py` | `PostgresClient` 单例；12 张迁移表的 SQL 实现 | `psycopg`, `psycopg_pool`, `nexus_utils.config_loader` |
| `api/v2/database/sqs.py` | `SQSClient` 单例；构建 / 部署任务发送；W3C trace 注入 | `boto3`, `api/v2/config.py` |
| `api/v2/database/valkey.py` | `CacheClient` 单例；缓存 / Streams / 分布式锁 / Pub-Sub | `redis`, `nexus_utils.config_loader` |

## FastAPI 应用装配（`api/v2/main.py`）

### 启动时副作用（导入即执行）

| 位置 | 操作 | 原因 |
|------|------|------|
| `main.py:21-22` | `os.environ.setdefault("BYPASS_TOOL_CONSENT", "true")` 与 `STRANDS_NON_INTERACTIVE=true` | Strands Agent 的 `file_write` / `shell` 工具默认会调用 `prompt_toolkit` 等待 stdin；Web 进程中会永久阻塞 |
| `main.py:25-26` | `from nexus_utils.observability import setup as _setup_observability` → `setup(service_name="nexus-ai-api")` | 必须在 FastAPI / boto3 导入前启动 OTEL 自动插桩 |
| `main.py:84` | `logging.getLogger('opentelemetry.context').setLevel(logging.CRITICAL)` | 静默前端中断 SSE 时的 `GeneratorExit` 日志 |

### FastAPI 构造参数

```python
app = FastAPI(
    title="Nexus AI API",
    description="Nexus AI Platform API v2 - Agent 构建和管理系统",
    version=settings.APP_VERSION,
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json"
)
```

### 中间件（执行顺序：后注册先执行）

| 执行顺序 | 中间件 | 位置 | 作用 |
|---------|--------|------|------|
| 1 | `auth_middleware` | `main.py:163` | 全局认证（`api/v2/auth/middleware.py`） |
| 2 | `add_request_id` | `main.py:115-159` | 生成 `X-Request-ID`、计时、注入 `X-Trace-ID`、上报 API 指标 |
| 3 | `CORSMiddleware` | `main.py:102-110` | CORS（`allow_origins=settings.CORS_ORIGINS`，默认 `["*"]`） |

**`add_request_id` 关键行为：**

- 生成 `uuid.uuid4()` 赋值到 `request.state.request_id`，通过响应头 `X-Request-ID` 回传；
- 计算 `process_time`，写入响应头 `X-Process-Time`；
- 从 `opentelemetry.trace.get_current_span()` 提取 `trace_id`，格式化为 32 位 hex，作为 `X-Trace-ID`；
- 通过 `record_api_request(method, route, status_code, duration)` 上报指标；**路由模板**（如 `/api/v2/agents/{agent_id}`）而非完整路径，避免高基数维度；
- 状态码 ≥ 400 时额外调用 `_api_m.record_error(method, route, error_class)`，`error_class` 为 `4xx_client` 或 `5xx_server`。

### 路由装配

所有路由都以 `prefix="/api/v2"` 挂载。按源文件顺序完整列表如下：

| 路由 | 源文件符号 | 注册位置 |
|------|-----------|---------|
| Auth | `auth_router` | `main.py:169` |
| Manifest | `manifest_router` | `main.py:170` |
| Users | `users_router` | `main.py:173` |
| Projects | `projects_router` | `main.py:176` |
| Agents | `agents_router` | `main.py:177` |
| Agent Files | `agent_files_router` | `main.py:178` |
| Agent Tools | `agent_tools_router` | `main.py:179` |
| Sessions | `sessions_router` | `main.py:180` |
| Tasks | `tasks_router` | `main.py:181` |
| Statistics | `statistics_router` | `main.py:182` |
| Config | `config_router` | `main.py:183` |
| AgentCore | `agentcore_router` | `main.py:184` |
| Workflow Control | `workflow_control_router` | `main.py:185` |
| Workflows | `workflows_router` | `main.py:186` |
| Agent Graph | `agent_graph_router` | `main.py:187` |
| Attachments | `attachments_router` | `main.py:188` |
| MCP | `mcp_router` (来自 `nexus_utils.mcp.mcp_client.api`) | `main.py:189` |
| Clarifications | `clarifications_router` | `main.py:190` |
| Favorites | `favorites_router` | `main.py:191` |
| Skills | `skills_router` | `main.py:192` |
| Event Jobs | `event_jobs_router` | `main.py:193` |
| Workspace | `workspace_router` | `main.py:194` |
| Connectors | `connectors_router` | `main.py:195` |
| Directives | `directives_router` | `main.py:196` |
| Audit | `audit_router` | `main.py:197` |
| Policies | `policies_router` | `main.py:198` |
| Groups | `groups_router` | `main.py:199` |
| Observability | `observability_router` | `main.py:200` |
| Backup Shares | `backup_shares_router` | `main.py:201` |
| File Shares | `file_shares_router` | `main.py:202` |
| Template Assets | `template_assets_router` | `main.py:203` |
| Template Collections | `template_collections_router` | `main.py:204` |
| Template Shares | `template_shares_router` | `main.py:205` |
| Template AI Assist | `template_ai_assist_router` | `main.py:206` |
| Sandbox | `sandbox_router` | `main.py:207` |
| Admin Billing (可选) | `admin_billing_router`（捕获 `ImportError`） | `main.py:211-214` |

### 健康检查与根端点

| 路径 | 方法 | 位置 | 说明 |
|------|------|------|------|
| `/health` | GET | `main.py:219-247` | 同步检查 `db_client.health_check()` 与 `sqs_client.health_check()`；任一失败返回 503，响应体 `status` 为 `degraded` |
| `/` | GET | `main.py:250-259` | 返回 `{message, version, docs, health, api_prefix}` |

### 全局异常处理

```python
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    request_id = getattr(request.state, 'request_id', 'unknown')
    logger.error(f"Unhandled exception: {exc}", exc_info=True, extra={"request_id": request_id})
    return JSONResponse(
        status_code=500,
        content={
            "success": False,
            "error": {
                "code": "INTERNAL_ERROR",
                "message": "服务器内部错误",
                "request_id": request_id
            }
        }
    )
```

### 启动 / 关闭事件

| 事件 | 位置 | 行为 |
|------|------|------|
| `startup_event` | `main.py:285-299` | 读取环境变量 `NEXUS_THREAD_POOL_SIZE`（默认 `64`），设置 asyncio 默认 `ThreadPoolExecutor`；打印版本 / region / endpoint |
| `shutdown_event` | `main.py:303-306` | 仅打印日志 |

### 本地运行入口

```python
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("api.v2.main:app", host="0.0.0.0", port=8000, reload=True, log_level="info")
```

## 配置层（`api/v2/config.py`）

`api/v2/config.py` 是**整个 API 层配置的单一入口**。加载顺序：环境变量 > `default_config.yaml` > 默认值；通过 `nexus_utils.config_loader.get_config()` 读取 YAML。

### `Settings` (`config.py:356`)

继承 `pydantic_settings.BaseSettings`，主要字段分组如下：

| 分组 | 字段 | 类型 | 默认来源 |
|------|------|------|---------|
| Application | `APP_NAME`, `APP_VERSION`, `DEBUG` | `str`, `str`, `bool` | 硬编码（`"Nexus-AI API"`, `"0.1.0"`, `False`） |
| AWS | `AWS_REGION`, `AWS_DEFAULT_REGION`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` | `str`, `str`, `Optional[str]`, `Optional[str]` | `_aws_config` |
| DynamoDB | `DYNAMODB_ENDPOINT_URL`, `DYNAMODB_TABLE_PREFIX` | `Optional[str]`, `str` | `_aws_config`, `_dynamodb_config` |
| SQS 队列名 | `SQS_BUILD_QUEUE_NAME`, `SQS_DEPLOY_QUEUE_NAME`, `SQS_NOTIFICATION_QUEUE_NAME`, `SQS_BUILD_DLQ_NAME`, `SQS_DEPLOY_DLQ_NAME` | `str` | `_sqs_queues`, `_sqs_dlq`, 前缀 `_sqs_prefix`（默认 `nexus-`） |
| SQS 可见性 | `BUILD_VISIBILITY_TIMEOUT` (`3600`), `DEPLOY_VISIBILITY_TIMEOUT` (`600`), `MESSAGE_RETENTION_DAYS` (`14`), `MAX_RETRY_COUNT` (`3`) | `int` | `_sqs_config` |
| AgentCore | `AGENTCORE_REGION`, `AGENTCORE_DEPLOY_DRY_RUN`, `AGENTCORE_DEFAULT_ALIAS`, `AGENTCORE_EXECUTION_ROLE_NAME`, `AGENTCORE_AUTO_CREATE_EXECUTION_ROLE`, `AGENTCORE_AUTO_CREATE_ECR`, `AGENTCORE_POST_DEPLOY_TEST`, `AGENTCORE_POST_DEPLOY_TEST_PROMPT`, `AGENTCORE_AUTO_UPDATE_ON_CONFLICT`, `AGENTCORE_REQUIREMENTS_PATH`, `AGENTCORE_IMAGE_TAG_TEMPLATE` | 多种 | `_agentcore_config` |
| Session 存储 | `SESSION_STORAGE_S3_BUCKET`, `SESSION_STORAGE_S3_PREFIX` | `Optional[str]`, `str` | `_nexus_ai_config` |
| Conversation Manager | `CONVERSATION_MANAGER_ENABLED`, `CONVERSATION_MANAGER_TYPE`, `CM_SLIDING_WINDOW_SIZE` (`40`), `CM_SLIDING_TRUNCATE_RESULTS`, `CM_SUMMARY_RATIO` (`0.3`), `CM_PRESERVE_RECENT_MESSAGES` (`10`), `CM_USE_CUSTOM_AGENT`, `CM_CUSTOM_AGENT_MODEL_ID`, `CM_CUSTOM_AGENT_PROMPT_PATH` | 多种 | `_nexus_ai_config['conversation_manager']` |
| 附件 | `ATTACHMENT_S3_BUCKET`, `ATTACHMENT_PRESIGNED_URL_EXPIRY` (`3600`), `ATTACHMENT_UPLOAD_URL_EXPIRY` (`600`), `ATTACHMENT_MAX_FILE_SIZE` (`50MB`), `ATTACHMENT_MAX_FILES_PER_MESSAGE` (`5`) | 多种 | `_nexus_ai_config` |
| 模板 | `TEMPLATE_S3_BUCKET`, `TEMPLATE_S3_KEY_PREFIX`, `TEMPLATE_EFS_SUBDIR`, `TEMPLATE_LOCAL_CACHE_DIR`, `TEMPLATE_UPLOAD_URL_EXPIRY`, `TEMPLATE_MAX_FILE_SIZE` (`100MB`), `TEMPLATE_ALLOWED_EXTENSIONS`, `TEMPLATE_PREVIEW_TEXT_MAX_BYTES`, `TEMPLATE_PREVIEW_WORKERS`, `TEMPLATE_AI_ENABLED`, `TEMPLATE_AI_ANALYZE_MODEL`, `TEMPLATE_AI_EMBED_MODEL`, `TEMPLATE_AI_EMBED_DIM`, `TEMPLATE_AI_DIFF_MODEL`, `TEMPLATE_LIBREOFFICE_BIN`, `TEMPLATE_IMAGEMAGICK_BIN`, `TEMPLATE_TRIAL_AGENT_ID` | 多种 | `_nexus_ai_config['templates']` |
| Skill | `SKILL_S3_BUCKET` | `str` | `_nexus_ai_config['artifacts_s3_bucket']` |
| CORS | `CORS_ORIGINS` (`["*"]`), `CORS_ALLOW_CREDENTIALS` (`False`) | `list`, `bool` | 硬编码 |
| 日志 | `LOG_LEVEL` (`"INFO"`) | `str` | `_logging_config` |

### `get_settings()` 单例 (`config.py:464-473`)

```python
@lru_cache()
def get_settings() -> Settings:
    s = Settings()
    config_region = _aws_config.get('aws_region_name', 'us-west-2')
    if s.AWS_REGION != config_region:
        object.__setattr__(s, 'AWS_REGION', config_region)
        object.__setattr__(s, 'AWS_DEFAULT_REGION', config_region)
    return s

settings = get_settings()
```

**陷阱**：`AWS_REGION` 环境变量会被 Pydantic 解析进来，可能覆盖 YAML 里的值；`get_settings()` 强制回写以保证 region 以 YAML 为准。

### `TABLE_*` 常量 (`config.py:482-515`)

所有 DynamoDB 表名都在此处定义为模块级常量，带 `DYNAMODB_TABLE_PREFIX`（默认 `nexus_`）。`# [Aurora-migrated]` 注释表示该表已迁移到 Aurora，`DynamoDBClient._setup_aurora_proxy()` 会把 CRUD 方法委托到 `pg_client`。

| 常量 | 原始表 | 状态 |
|------|--------|------|
| `TABLE_PROJECTS` | `projects` | [Aurora-migrated] |
| `TABLE_STAGES` | `stages` | [Aurora-migrated] |
| `TABLE_AGENTS` | `agents` | [Aurora-migrated] |
| `TABLE_INVOCATIONS` | `invocations` | [Aurora-migrated] |
| `TABLE_SESSIONS` | `sessions` | [Aurora-migrated] |
| `TABLE_MESSAGES` | `messages` | [Aurora-migrated] |
| `TABLE_ATTACHMENTS` | `attachments` | [Aurora-migrated] |
| `TABLE_USERS` | `users` | [Aurora-migrated] |
| `TABLE_FAVORITES` | `favorites` | [Aurora-migrated] |
| `TABLE_SKILLS` | `skills` | [Aurora-migrated] |
| `TABLE_SKILL_GROUPS` | `skill_groups` | [Aurora-migrated] |
| `TABLE_GROUPS` | `groups` | [Aurora-migrated] |
| `TABLE_TASKS` | `tasks` | DDB |
| `TABLE_TOOLS` | `tools` | DDB |
| `TABLE_CLARIFICATIONS` | `clarifications` | DDB |
| `TABLE_DYNAMIC_CONFIGS` | `dynamic_configs` | DDB |
| `TABLE_EVENT_JOBS` | `event_jobs` | DDB |
| `TABLE_EVENT_TASKS` | `event_tasks` | DDB |
| `TABLE_REMOTE_CONNECTIONS` | `remote_connections` | DDB |
| `TABLE_CONNECTORS` | `connectors` | DDB |
| `TABLE_KEYS` | `keys` | DDB |
| `TABLE_KEY_USAGE_LOGS` | `key_usage_logs` | DDB |
| `TABLE_DIRECTIVES` | `directives` | DDB |
| `TABLE_POLICIES` | `policies` | DDB |
| `TABLE_AUDIT_LOGS` | `audit_logs` | DDB |
| `TABLE_MCP_SERVERS` | `mcp_servers` | DDB |
| `TABLE_SYSTEM_CONFIGS` | `system_configs` | DDB |
| `TABLE_BACKUP_SHARES` | `backup_shares` | DDB |
| `TABLE_FILE_SHARES` | `file_shares` | DDB |
| `TABLE_BRIDGE_COMMAND_RULES` | `bridge_command_rules` | DDB |
| `TABLE_SANDBOX_INSTANCES` | `sandbox_instances` | DDB |
| `TABLE_SANDBOX_LOGS` | `sandbox_logs` | DDB |
| `TABLE_SANDBOX_NODES` | `sandbox_nodes` | DDB |
| `TABLE_SESSION_TEMPLATE_BINDINGS` | `session_template_bindings` | DDB |

- `ALL_TABLES`：18 张仍在 DDB 的表组成的列表（用于批量操作，如表创建脚本）。
- `ALL_QUEUES`：5 个 SQS 队列名的列表（`BUILD_QUEUE`, `DEPLOY_QUEUE`, `NOTIFICATION_QUEUE`, `BUILD_DLQ`, `DEPLOY_DLQ`）。

## 核心支持模块（`api/v2/core/`）

### `core/exceptions.py`

API 层自定义异常，全部继承 `APIException`（纯 Python 类，**不自动被 FastAPI 捕获**，需要在 Router 中手动处理或依赖全局 exception handler）。

#### `APIException` (`core/exceptions.py:669`)

| 字段 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `message` | `str` | — | 对外消息 |
| `status_code` | `int` | `500` | HTTP 状态码 |
| `error_code` | `str` | `"INTERNAL_ERROR"` | 业务错误码 |
| `details` | `Optional[str]` | `None` | 详细信息 |
| `suggestion` | `Optional[str]` | `None` | 用户修复建议 |
| `docs_url` | `Optional[str]` | `None` | 文档链接 |

#### `ValidationError` (`core/exceptions.py:689`)

固定 `status_code=400`, `error_code="VALIDATION_ERROR"`，`docs_url="https://docs.nexus-ai.com/api/validation"`。

#### `ResourceNotFoundError` (`core/exceptions.py:702`)

构造签名：`ResourceNotFoundError(resource_type: str, resource_id: str)`。固定 `status_code=404`, `error_code="RESOURCE_NOT_FOUND"`，自动生成 `"<Type> with ID '&lt;id&gt;' does not exist"` 的 details。

### `core/stage_config.py`

工作流阶段配置的**唯一权威来源**。内部委托 `nexus_utils.workflow_config.WorkflowConfigManager`，所有数据从 `config/workflows.yaml` 动态加载。

#### `StageConfig` (数据类，`core/stage_config.py:818`)

| 字段 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `name` | `str` | — | 阶段名（snake_case，权威形式） |
| `order` | `int` | — | 阶段序号（1 起） |
| `display_name` | `str` | — | 中文显示名 |
| `prompt_path` | `str` | — | Prompt 模板相对路径 |
| `log_filename` | `str` | — | 日志文件名（不含扩展） |
| `agent_display_name` | `str` | — | 英文 Agent 名 |
| `supports_iteration` | `bool` | `False` | 是否支持多 Agent 迭代 |
| `scope` | `str` | `"project"` | 阶段作用域 |
| `fork_on_complete` | `bool` | `False` | 完成后是否 fork |
| `join_before_start` | `bool` | `False` | 开始前是否 join |
| `join_after_complete` | `bool` | `False` | 完成后是否 join |

#### 模块级符号

| 符号 | 类型 | 说明 |
|------|------|------|
| `BuildStage` | `Enum` | 动态生成，成员名为阶段名的大写（如 `BuildStage.REQUIREMENTS_ANALYSIS`） |
| `STAGES` | `Dict[str, StageConfig]` | 名称 → 配置 |
| `STAGE_SEQUENCE` | `List[str]` | 阶段顺序列表 |
| `ITERATIVE_STAGES` | `List[str]` | 支持迭代的阶段名列表 |
| `LEGACY_NAME_MAPPING` | `Dict[str, str]` | 旧名 → 新名 |

#### 公共函数

| 函数 | 签名 | 说明 |
|------|------|------|
| `get_workflow_config` | `(workflow_type: str = "agent_build") -> WorkflowConfig` | 获取指定工作流；不存在抛 `ValueError` |
| `normalize_stage_name` | `(stage_name: str, workflow_type="agent_build") -> Optional[str]` | 旧名 → 新名（大小写不敏感），无法识别返回 `None` |
| `get_stage_display_name` | `(stage_name, workflow_type="agent_build") -> str` | 中文显示名 |
| `get_stage_number` | `(stage_name, workflow_type="agent_build") -> int` | 阶段序号，识别不到返回 `0` |
| `get_prompt_path` | `(stage_name, workflow_type="agent_build") -> Optional[str]` | Prompt 相对路径 |
| `get_log_filename` | `(stage_name, workflow_type="agent_build") -> Optional[str]` | 日志文件名 |
| `get_agent_display_name` | `(stage_name, workflow_type="agent_build") -> str` | 英文 Agent 名 |
| `is_iterative_stage` | `(stage_name, workflow_type="agent_build") -> bool` | 是否支持迭代 |
| `get_stage_config` | `(stage_name, workflow_type="agent_build") -> Optional[StageConfig]` | 完整配置 |
| `get_all_stage_names` | `(workflow_type="agent_build") -> List[str]` | 所有阶段名 |
| `get_stage_display_name_mapping` | `(workflow_type="agent_build") -> Dict[str, str]` | 名称 → 显示名 |
| `get_prompt_path_mapping` | `(workflow_type="agent_build") -> Dict[str, str]` | 名称 → prompt 路径 |
| `get_log_filename_mapping` | `(workflow_type="agent_build") -> Dict[str, str]` | 名称 → 日志名 |
| `get_available_workflows` | `() -> List[str]` | 所有已启用的工作流类型 |
| `get_workflow_stages` | `(workflow_type: str) -> List[str]` | 指定工作流的阶段序列 |
| `reload_workflow_config` | `() -> None` | 重新加载配置文件，刷新 `STAGES` / `BuildStage` 等全局 |

### `core/config.py`

**遗留文件**。定义了另一个 `Settings`（`core/config.py:611`），字段比 `api/v2/config.py` 少得多。新代码应使用 `from api.v2.config import settings`。

### `core/__init__.py`

仅重新导出 `stage_config` 中的公共符号：`BuildStage`, `StageConfig`, `STAGES`, `STAGE_SEQUENCE`, `ITERATIVE_STAGES`, `LEGACY_NAME_MAPPING`, `normalize_stage_name`, `get_stage_display_name`, `get_stage_number`, `get_prompt_path`, `get_log_filename`, `get_agent_display_name`, `is_iterative_stage`, `get_stage_config`, `get_all_stage_names`, `get_stage_display_name_mapping`, `get_prompt_path_mapping`, `get_log_filename_mapping`.

## 数据层（`api/v2/database/`）

四库架构：

```
Router / Service
      │
      ▼
db_client (DynamoDB)  ←─ Aurora 代理 ─→  pg_client (Aurora PostgreSQL)
      │
      └── 仅保留 18 张 KV/事件/配置表

cache_client (Valkey)  — Cache-Aside / Streams / 分布式锁 / Pub-Sub
sqs_client (SQS)       — Build / Deploy / Notification 队列
```

### `database/__init__.py`

导出 4 个单例：

```python
from .dynamodb import DynamoDBClient, db_client
from .sqs import SQSClient, sqs_client
from .aurora import PostgresClient, pg_client
from .valkey import CacheClient, cache_client
```

### `DynamoDBClient` (`database/dynamodb.py:1282`)

**线程安全单例**（双检锁 `__new__` + `_initialized` 哨兵）。

#### 构造细节

| 步骤 | 行 | 说明 |
|------|----|------|
| 读取 region | `dynamodb.py:1299-1303` | 优先 `default_config.yaml.aws.aws_region_name`，不看 `AWS_REGION` 环境变量 |
| `Config` 参数 | `dynamodb.py:1305-1311` | `retries={'max_attempts': 3, 'mode': 'adaptive'}`, `max_pool_connections=50`, `connect_timeout=10`, `read_timeout=30` |
| 凭证选择 | `dynamodb.py:1314-1323` | AK/SK 优先 YAML；若缺失则用环境变量；`profile_name` 仅当显式配置（非 `default`/空）且无 AK/SK 时 |
| 资源/客户端 | `dynamodb.py:1327-1336` | `dynamodb` 资源 + 底层 `dynamodb` 客户端；均传 `endpoint_url=settings.DYNAMODB_ENDPOINT_URL`（本地开发用） |
| Aurora 代理 | `dynamodb.py:1347` | `_setup_aurora_proxy()` 装配方法委托 |

#### `_setup_aurora_proxy()` (`dynamodb.py:1349`)

**作用**：将 12 张迁移表的 CRUD 方法**在实例方法表上替换**为 `pg_client` 的对应方法。只要 `aurora.host` 配置存在（环境变量 `NEXUS_AURORA_HOST` 或 YAML），代理即生效；否则保留 DynamoDB 实现。

代理覆盖的方法前缀（完整列表见源码 1370–1465）：

| 资源 | 代理方法 |
|------|---------|
| Projects | `create_project`, `get_project`, `update_project`, `list_projects`, `delete_project`, `update_agents_completion` |
| Stages | `create_stage`, `get_stage`, `get_stage_by_agent`, `get_stage_by_key`, `update_stage`, `update_stage_by_key`, `update_stage_by_agent`, `list_stages`, `list_stages_by_prefix`, `list_agent_stages`, `list_all_stages_by_project`, `delete_stage`, `delete_stage_by_key` |
| Agents | `create_agent`, `get_agent`, `update_agent`, `list_agents`, `delete_agent`, `query_agent_by_name_cn`, `query_agent_by_name_en`, `query_agent_by_dir_name`, `check_agent_name_unique`, `list_agent_versions`, `get_active_agent_version`, `switch_active_version`, `backfill_version_fields`, `list_agents_by_project`, `update_agent_statistics`, `get_agent_statistics` |
| Invocations | `create_invocation` |
| Sessions | `create_session`, `get_session`, `update_session`, `list_sessions`, `delete_session`, `delete_session_messages`, `list_all_sessions_by_agent` |
| Messages | `create_message`, `list_messages`, `list_all_messages_by_session` |
| Attachments | `create_attachment`, `get_attachment`, `update_attachment`, `list_attachments_by_session`, `list_attachments_by_message`, `delete_attachment` |
| Skills | `create_skill`, `get_skill`, `update_skill`, `delete_skill`, `list_skills`, `list_skills_by_ids` |
| Skill Groups | `create_skill_group`, `get_skill_group`, `update_skill_group`, `delete_skill_group`, `list_skill_groups`, `find_skill_group_by_source` |
| Users | `create_user`, `get_user_by_id`, `get_user_by_saml_name_id`, `get_user_by_email`, `update_user`, `list_users`, `count_users`, `delete_user` |
| Favorites | `create_favorite`, `get_favorite`, `list_favorites`, `delete_favorite` |
| Groups | `create_group`, `get_group`, `update_group`, `delete_group`, `list_groups` |

**保留在 DDB 的方法**：Tools CRUD、Keys、Key Usage Logs 仍直接访问 DDB 表（源码中标注 `7+ 直接 table 访问` / `16+ 直接 table 访问`）。

#### 表属性（懒加载 + 缓存）

`_get_table(table_name)` 缓存到 `self._tables[table_name]`。每张 DDB 表都有一个对应的 `@property`：`projects_table`, `stages_table`, `agents_table`, `invocations_table`, `sessions_table`, `messages_table`, `tasks_table`, `tools_table`, `clarifications_table`, `attachments_table`, `users_table`, `dynamic_configs_table`, `favorites_table`, `skills_table`, `skill_groups_table`, `event_jobs_table`, `event_tasks_table`, `remote_connections_table`, `bridge_command_rules_table`, `connectors_table`, `keys_table`, `key_usage_logs_table`, `directives_table`, `mcp_servers_table`, `system_configs_table`, `backup_shares_table`, `file_shares_table`, `session_template_bindings_table`。

#### 重试装饰器 `retry_on_error` (`dynamodb.py:1253`)

```python
@retry_on_error(max_retries=3, delay=1.0, backoff=2.0)
def some_method(...): ...
```

仅对 `ClientError.Error.Code` ∈ `{ProvisionedThroughputExceededException, ThrottlingException, ServiceUnavailable, InternalServerError}` 进行指数退避重试；其他 `ClientError` / `BotoCoreError` 直接抛。几乎所有 DDB 写方法都装饰了此装饰器。

#### 代表性 CRUD 方法

所有写方法都会在 `data` 上注入 `created_at` / `updated_at`（UTC ISO，`+00:00` 替换为 `Z`）。类型转换通过 `self._to_dynamo()` / `self._from_dynamo()` / `self._to_dynamo_value()`（处理 `Decimal` / `datetime`）。

| 方法 | 位置 | 行为概要 |
|------|------|---------|
| `create_user(user_data)` | `dynamodb.py:1630` | put_item；注入时间戳 |
| `get_user_by_id(user_id)` | `dynamodb.py:1639` | get_item by `user_id` |
| `get_user_by_saml_name_id(saml_name_id)` | `dynamodb.py:1646` | GSI 查询 `SamlNameIdIndex` |
| `get_user_by_email(email)` | `dynamodb.py:1657` | GSI 查询 `EmailIndex` |
| `update_user(user_id, updates)` | `dynamodb.py:1668` | UpdateExpression + `#k = :k` 构造 |
| `list_users(limit, last_key)` | `dynamodb.py:1686` | scan + `ExclusiveStartKey` |
| `count_users()` | `dynamodb.py:1709` | `scan(Select='COUNT', Limit=1)` |
| `delete_user(user_id)` | `dynamodb.py:1715` | delete_item |
| `create_project(project_data)` | `dynamodb.py:1723` | put_item |
| `put_session_template_binding(binding)` | `dynamodb.py:1592` | upsert by `(session_id, binding_key)` |
| `list_session_template_bindings(session_id)` | `dynamodb.py:1599` | query by `session_id` |
| `delete_session_template_bindings(session_id)` | `dynamodb.py:1607` | `batch_writer` 批量删除 |

### `PostgresClient` (`database/aurora.py:1780`)

**线程安全单例**。`psycopg` v3 + `psycopg_pool.ConnectionPool`；`autocommit=True`, `row_factory=dict_row`。与 `DynamoDBClient` 同名方法签名对齐。

#### 连接池初始化 `_init_pool` (`aurora.py:1809`)

| 参数 | 来源 |
|------|------|
| `host` | 环境变量 `NEXUS_AURORA_HOST` > `aurora.host` |
| `password` | 环境变量 `NEXUS_AURORA_PASSWORD` > `aurora.password` |
| `port` | `aurora.port` (默认 `5432`) |
| `dbname` | `aurora.database` (默认 `nexus`) |
| `user` | `aurora.username` (默认 `nexus_admin`) |
| `sslmode` | `aurora.ssl` = True → `require`；否则 `prefer` |
| `min_size` / `max_size` | `aurora.min_connections` / `max_connections` (默认 2 / 20) |

若未配置 `host`，`pool` 属性读取时抛 `RuntimeError("Aurora host not configured")`。

#### 通用执行器

| 方法 | 签名 | 用途 |
|------|------|------|
| `_execute(sql, params, fetch)` | `fetch ∈ {'one', 'all', 'none', 'rowcount'}` | 获取单行 / 所有行 / 无返回 / 受影响行数；`one` 与 `all` 自动 `_row_to_dict` |
| `_row_to_dict(row)` | `datetime/date → ISO`, `Decimal → int/float` | 结果归一化 |
| `_jsonb(v)` | `dict/list → Jsonb` | JSONB 列包装 |
| `_prepare(data)` | `{k: _jsonb(v)}` | 为 SQL 参数字典批量包装 |

#### 列名缓存与 `_filter_data` (`aurora.py:1902-1926`)

`_column_cache: Dict[str, set]`：首次查询 `information_schema.columns`，缓存表的实际列集合。`_filter_data(table, data)` 会丢弃 DDB 侧存在、Aurora 侧不存在的字段并在 DEBUG 日志中列出 `skipped` 集合，避免 INSERT/UPDATE 语法报错。

#### 通用 CRUD 辅助

| 方法 | 用途 |
|------|------|
| `_insert(table, data)` | 构造 `INSERT INTO ... VALUES (...) RETURNING *`；先过滤 + JSONB 包装 |
| `_get(table, where, params)` | `SELECT * FROM ... WHERE ... LIMIT 1` |
| `_update(table, where, where_params, updates)` | 注入 `updated_at`，构造 `SET k = %(set_k)s, ...` + `RETURNING *` |
| `_delete(table, where, params)` | `DELETE ...`，总返回 `True` |
| `_list(table, where, params, order_by, limit, offset)` | 可选 where/order_by/limit/offset，返回列表 |

#### 表方法一览

所有方法都带统一的返回契约：单记录返回 `Optional[dict]`，列表查询返回 `list`，分页查询返回 `{'items': [...], 'last_key': Optional[str], 'count': int}`，其中 `last_key` 以 `offset` 字符串形式游标化（而非 DDB 的 `ExclusiveStartKey`）。

| 资源 | 方法（节选） | 说明 |
|------|-------------|------|
| Projects | `create_project`, `get_project`, `update_project`, `list_projects(status, user_id, limit, last_key)`, `delete_project`, `update_agents_completion(project_id, agent_id, status)` | `agents_completion` 用 `jsonb_build_object` 增量合并 |
| Stages | `create_stage`（自动生成 `stage_id = project_id#stage_key`）, `get_stage`, `get_stage_by_agent(project_id, stage_name, agent_id)`, `get_stage_by_key`, `update_stage`, `update_stage_by_key`, `update_stage_by_agent`, `list_stages`, `list_stages_by_prefix`, `list_agent_stages(agent_id)`, `list_all_stages_by_project(project_id)`, `delete_stage`, `delete_stage_by_key` | stage_key 的 prefix 搜索用 `LIKE` |
| Agents | `create_agent`（注入默认统计字段 0）, `get_agent`, `update_agent`, `list_agents(status, category, limit, last_key)`, `delete_agent`, `query_agent_by_name_cn`, `query_agent_by_name_en`, `query_agent_by_dir_name`, `check_agent_name_unique(agent_name_cn, agent_name_en)`, `list_agent_versions(version_group_id)`, `get_active_agent_version(version_group_id)`, `switch_active_version(version_group_id, target_agent_id)`, `backfill_version_fields(agent_id)`, `list_agents_by_project`, `update_agent_statistics(agent_id, input_tokens, output_tokens, conversation_turns, duration_ms)` | 统计用 `SET col = col + %s`；切换激活版本两条语句，非事务 |

`PostgresClient.health_check()` 执行 `SELECT 1 AS ok`。

### `SQSClient` (`database/sqs.py:2255`)

**线程安全单例**。

#### 构造

- `region` 来自 YAML（同 DynamoDBClient）；
- `Config(retries={'max_attempts': 3, 'mode': 'adaptive'}, connect_timeout=10, read_timeout=30)`；
- 凭证/profile 选择逻辑同 DynamoDBClient；
- `endpoint_url=settings.SQS_ENDPOINT_URL` 支持 local。

#### 队列 URL 缓存

`_get_queue_url(queue_name)`：调用 `client.get_queue_url(QueueName=...)`，缓存到 `self._queue_urls`；`QueueDoesNotExist` 直接抛。

#### 核心方法

| 方法 | 签名 | 说明 |
|------|------|------|
| `send_message` | `(queue_name, message_body, delay_seconds=0, message_attributes=None, message_group_id=None, message_deduplication_id=None) -> Dict` | 通用发送；若 observability 启用且 `_trace_carrier` 不存在，自动 `opentelemetry.propagate.inject()` 到 body；返回 `{message_id, sequence_number}` |
| `send_build_task` | `(task_id, project_id, requirement, user_id=None, priority=3, metadata=None, target_stage=None, action='execute')` | V1 构建任务；`task_attributes.task_type='build_agent'` |
| `send_build_task_v2` | `(project_id, stage='intent_recognition', requirement='', user_id=None, agent_id=None, agent_type=None, architecture_type=None, agent_context=None, metadata=None)` | V2：消息体带 `workflow_type='agent_build'` + `stage`；`task_type='build_agent_v2'` |
| `send_skill_build_task_v2` | `(project_id, stage='intent_recognition', requirement='', user_id=None, metadata=None)` | 技能构建；`workflow_type='skill_build'`, `task_type='build_skill_v2'` |
| `send_deploy_task` | `(task_id, project_id, agent_id, deployment_config=None)` | 部署任务；`task_type='deploy_agent'` |
| `receive_messages` | `(queue_name, max_messages=1, wait_time_seconds=20, visibility_timeout=None)` | 长轮询接收；自动 JSON 解码 `Body`；返回列表，每项含 `{message_id, receipt_handle, body, attributes, message_attributes}` |
| `delete_message` | `(queue_name, receipt_handle) -> bool` | ACK |
| `change_message_visibility` | `(queue_name, receipt_handle, visibility_timeout) -> bool` | 动态延长处理超时 |
| `get_queue_attributes` | `(queue_name) -> Dict` | 返回 approximate 消息数 / visibility / retention 等 |
| `health_check()` | `() -> bool` | `list_queues(MaxResults=1)` |

#### 消息属性格式化

- `_format_message_attributes(attributes)`：`str` → `String`, `int/float` → `Number (StringValue=str(v))`, `bytes` → `Binary`；
- `_parse_message_attributes(attributes)`：根据 `DataType` 反解回 Python 类型；`Number` 中含 `.` 视为 `float`，否则 `int`。

### `CacheClient` (`database/valkey.py:2750`)

**线程安全单例**。包装 `redis.Redis`（Valkey 兼容 Redis 协议）。

#### 双客户端

| 属性 | 用途 | 关键参数 |
|------|------|---------|
| `client` | 常规 GET/SET/DEL/SCAN/XADD/... | `socket_timeout=5`, `max_connections=50` |
| `stream_client` | 阻塞 `XREAD` | `socket_timeout=60`, `max_connections=10` |

`_init_client()`：从 `NEXUS_VALKEY_ENDPOINT` 或 `valkey.endpoint` 读取；若为空则 `available=False`，所有方法 short-circuit 返回空/`None`/`0`（**永不抛**）。连接成功后 `ping()` 验证。

#### 基础操作

| 方法 | 签名 | 说明 |
|------|------|------|
| `get(key)` | `-> Any` | 失败/未命中返回 `None`；自动 `json.loads` |
| `set(key, value, ttl=60)` | `-> bool` | 自动 `json.dumps(... cls=_CacheEncoder)` 处理 `datetime/Decimal` |
| `delete(*keys)` | `-> int` | 返回删除个数 |
| `delete_pattern(pattern)` | `-> int` | 基于 `SCAN` + `DELETE`（安全）；每批 100 |

#### 业务失效辅助

| 方法 | 作用 |
|------|------|
| `invalidate_project(project_id)` | 删 `project:dashboard:{id}`, `project:detail:{id}`, `stats:overview`；模式删 `stats:build:*`, `projects:list:*` |
| `invalidate_agent(agent_id)` | 删 `agent:detail:{id}`, `stats:overview`；模式删 `agents:list:*`, `stats:agents:*` |
| `invalidate_stage(project_id)` | 删 `project:dashboard:{id}` |
| `invalidate_tool(project_id=None)` | 删 `tools:project:{id}`（可选）；模式删 `tools:*` |
| `invalidate_skill()` | 模式删 `skills:*` |
| `invalidate_user(user_id)` | 删 `user:auth:{user_id}` |
| `invalidate_stats()` | 删 `stats:overview`；模式删 `stats:*` |

#### Redis Streams（Agent 后台事件缓冲）

| 方法 | 签名 | 说明 |
|------|------|------|
| `xadd` | `(stream_key, fields: dict, maxlen=2000) -> Optional[str]` | 非 str 值自动 `json.dumps`；长度受限 |
| `xread` | `(stream_key, last_id='0', block_ms=15000, count=50) -> list` | 使用 `stream_client`（`socket_timeout=60`）；返回 `[(event_id, fields), ...]` |
| `xrange` | `(stream_key, start='-', end='+', count=100) -> list` | 范围读取 |
| `xlen` | `(stream_key) -> int` | 流长度 |
| `expire_stream` | `(stream_key, ttl=1800)` | 设置 TTL |

#### 分布式锁

| 方法 | 签名 | 说明 |
|------|------|------|
| `acquire_lock` | `(key, value='1', ttl=600) -> bool` | `SET NX EX`；**Valkey 不可用时返回 `True`**（不阻塞业务） |
| `release_lock` | `(key)` | 删除 key |
| `get_lock_value` | `(key) -> Optional[str]` | 读取当前锁值 |

#### Pub/Sub

`publish(channel, message) -> int`：发布到频道，非 str 自动 JSON 序列化，返回订阅者数量。

## 数据流 / 调用关系

### 同步请求路径

```
Client → uvicorn → CORSMiddleware → add_request_id → auth_middleware
      → Router (api/v2/routers/<xxx>.py)
      → Service / 直接调用 db_client / pg_client / cache_client
      → Response → add_request_id (注入 headers) → Client
```

### Aurora 代理路径

```
Router 调用 db_client.get_project(pid)
      │
      ▼
_setup_aurora_proxy() 在 __init__ 时已将 get_project 替换为 pg_client.get_project
      │
      ▼
pg_client._get('projects', 'project_id = %(pk)s', {'pk': pid})
      │
      ▼
ConnectionPool.connection() → cursor.execute(SQL) → _row_to_dict
```

### 异步构建流

```
POST /api/v2/projects  →  Router 创建 project 行
                       →  sqs_client.send_build_task_v2(project_id, stage='intent_recognition', ...)
                       →  SQS: nexus-build-queue
                       ↓ (Worker 进程 long-poll)
                       receive_messages → handler dispatch by `task_type`
                       → 阶段性结果写 stages 表 + cache_client.invalidate_project
                       → cache_client.publish('agent_events', ...) 或 xadd stream
                       ↓
SSE Router (同步 API)  ←  cache_client.xread(stream_key, ...)  ←  前端长连接
```

### 可观测性传递

- `main.py` 的 `add_request_id` 中间件：从 current span 提取 trace_id 注入响应头；
- `SQSClient.send_message`：自动 `opentelemetry.propagate.inject()` 将 W3C trace context 塞进消息体 `_trace_carrier`；
- Worker 侧从 `_trace_carrier` extract 即可将处理逻辑挂到同一 trace 下。

## 扩展点（Extending）

### 添加新的 HTTP 路由

1. 在 `api/v2/routers/` 下新建模块 `&lt;feature&gt;.py`，导出 `router = APIRouter(prefix="/&lt;path&gt;", tags=["&lt;tag&gt;"])`；
2. 在 `api/v2/routers/__init__.py` 注册（若想暴露为包级符号）；
3. 在 `api/v2/main.py` 顶部 `import` 新的 router；
4. 在 `main.py:168-207` 的路由装配段调用 `app.include_router(&lt;router&gt;, prefix="/api/v2")`；
5. 若需要在 Swagger 中分组，给 `APIRouter(tags=[...])` 指定标签。

**约束**：

- 全局 `auth_middleware` 会对所有路径执行认证；公开路由（如 `auth_router`, `manifest_router`）由中间件内部白名单处理；
- 返回时不要自己生成 `X-Request-ID`，`add_request_id` 中间件会处理；
- 抛出业务异常建议使用 `api/v2/core/exceptions.py` 中的子类，全局处理器会归一化返回体。

### 添加新的 DynamoDB 表

1. 在 `api/v2/config.py` 的 `_dynamodb_tables` 读取段末尾追加 `TABLE_<NAME>`；
2. 若该表未迁移到 Aurora，追加到 `ALL_TABLES` 列表；
3. 在 `DynamoDBClient._tables` 属性区增加 `@property &lt;name&gt;_table`；
4. 实现 CRUD 方法，用 `@retry_on_error()` 装饰；
5. `_to_dynamo` / `_from_dynamo` 会自动处理 `Decimal` / `datetime` / `set`，不要在方法中手写 `boto3.dynamodb.types.TypeSerializer`；
6. `default_config.yaml` 的 `dynamodb.tables` 段登记用户可覆盖的表名。

### 添加新的 Aurora 表

1. 先在迁移脚本中创建表（本文档不覆盖迁移工具）；
2. 在 `PostgresClient` 中按现有模式添加方法，尽量复用 `_insert` / `_get` / `_update` / `_delete` / `_list`；
3. 若想让现有 `db_client` 调用透明路由到 Aurora，在 `DynamoDBClient._setup_aurora_proxy()` 里追加 `self.&lt;method&gt; = _pg.&lt;method&gt;` 代理行；
4. 新增列后调用 `pg_client._column_cache.clear()` 或重启进程，否则 `_filter_data` 仍按旧 schema 过滤。

### 添加新的 SQS 队列

1. 在 `default_config.yaml` 的 `sqs.queues` / `sqs.dlq` 段登记队列名；
2. 在 `api/v2/config.py` 添加 `SQS_<NAME>_QUEUE_NAME: str = _sqs_queues.get('&lt;key&gt;', ...)`；
3. 加入 `ALL_QUEUES`；
4. 在 `SQSClient` 中添加 `send_&lt;task&gt;_task(...)` 便捷方法：调用 `self.send_message` 并设置合理的 `message_attributes.task_type`；
5. Worker 侧按 `task_type` 分派处理器。

**注意**：`send_message` 会自动注入 `_trace_carrier`；Worker 侧应在处理消息前 `opentelemetry.propagate.extract(body.get('_trace_carrier'))`。

### 添加新的工作流阶段

1. 编辑 `config/workflows.yaml`，在目标工作流的 `stages` 列表下新增条目（`name`, `order`, `display_name`, `prompt_path`, `log_filename`, `agent_display_name`, `supports_iteration`, 可选 `scope`/`fork_on_complete`/`join_before_start`/`join_after_complete`）；
2. 如果引入新名字且旧代码里有旧名引用，在 `legacy_name_mapping` 中登记 `&lt;old&gt;: &lt;new&gt;`；
3. 需要在运行态热更新时，调用 `api.v2.core.stage_config.reload_workflow_config()`；否则重启进程；
4. `BuildStage` 是动态生成的枚举——新阶段自动成为成员；注意消费端不要对枚举成员名做硬编码字符串比较，使用 `normalize_stage_name()`。

### 添加缓存失效点

1. 先看 `CacheClient.invalidate_*` 是否已有覆盖；
2. 若需要新类型，仿照 `invalidate_agent` 模式：删固定 key + `delete_pattern` 模糊清；
3. **写路径**调用 invalidation；**不要**在读路径触发失效；
4. Cache-Aside：写 → DB 成功 → `invalidate_*` → 返回；下次读未命中时从 DB 回填 + `set(..., ttl=60)`。

## 常见调试 / 故障排查

### 日志关键词

| 关键词 | 含义 | 位置 |
|-------|------|------|
| `DynamoDB client initialized` | 单例首次构造完成 | `dynamodb.py:1341` |
| `Aurora 代理已启用` | Aurora host 已配置且代理装配成功 | `dynamodb.py:1467` |
| `Aurora host 未配置，保留 DynamoDB 实现` | 走 DDB 原实现，12 张迁移表不可用 | `dynamodb.py:1367` |
| `Aurora 代理设置失败` | 捕获异常，降级到 DDB | `dynamodb.py:1470` |
| `Aurora 连接池已初始化` | pool 首次建立 | `aurora.py:1835` |
| `Retryable error <Code>, retrying in &lt;wait&gt;s` | DDB 被限流 | `dynamodb.py:1273` |
| `Valkey 缓存已连接` | 缓存层可用 | `valkey.py:2820` |
| `Valkey 连接失败，缓存层禁用` | 所有缓存方法 short-circuit | `valkey.py:2822` |
| `Valkey endpoint 未配置，缓存层禁用` | 同上，未配置场景 | `valkey.py:2791` |
| `Sent message to &lt;queue&gt;: <MessageId>` | SQS 投递成功 | `sqs.py:2375` |
| `Queue &lt;name&gt; does not exist` | `_get_queue_url` 失败 | `sqs.py:2315` |
| `Unhandled exception` + `request_id=&lt;id&gt;` | 全局 exception handler 触发 | `main.py:268` |

### 常见异常含义

| 异常 | 含义 / 修复 |
|------|------------|
| `ProfileNotFound` | `aws_profile_name='default'` 且无 `~/.aws/config`。修复：显式配置 AK/SK 或清空 profile。 |
| `QueueDoesNotExist` | 队列名拼错或未创建。修复：对齐 `default_config.yaml.sqs.queue_prefix` + `queues.*`。 |
| `ClientError: ProvisionedThroughputExceededException` | DDB 读写容量不足。`retry_on_error` 会自动退避 3 次；仍失败需要扩容或切 on-demand。 |
| `RuntimeError: Aurora host not configured` | `PostgresClient.pool` 访问时 host 空。修复：设置 `NEXUS_AURORA_HOST` 或 `aurora.host`。 |
| `ValueError: Workflow config not found` | `get_workflow_config()` 的 `workflow_type` 不存在。检查 `config/workflows.yaml`。 |
| `INTERNAL_ERROR` (500, 响应体) | 全局 handler 兜底。查 `request_id` + 日志堆栈。 |

### 诊断端点

| 端点 | 用途 |
|------|------|
| `GET /health` | DDB + SQS 健康状态；503 = degraded |
| `GET /docs` | Swagger UI，含所有 router 的完整 schema |
| `GET /openapi.json` | 机器可读 OpenAPI 3 文档 |
| `GET /redoc` | Redoc 风格 API 文档 |

### 响应头速查

| 头 | 含义 |
|----|------|
| `X-Request-ID` | 本次请求的 UUID，跨日志关联用 |
| `X-Process-Time` | 服务器侧处理时长（秒） |
| `X-Trace-ID` | 当前 span 的 trace id，CloudWatch / X-Ray 关联 |

## 延伸阅读

- `api/v2/routers/` — 每个 router 的业务 schema 与端点（另见对应子文档）。
- `api/v2/auth/middleware.py` — 认证逻辑与白名单。
- `nexus_utils/observability/` — `setup`, `instrument_fastapi`, `record_api_request`, metrics。
- `nexus_utils/config_loader.py` — YAML 加载与合并逻辑。
- `nexus_utils/workflow_config.py` — `WorkflowConfigManager`, `WorkflowConfig`, `StageConfig`。
- `agent_build_service/` — SQS 消费者、构建 / 部署 handler 实现。
- `config/workflows.yaml` — 工作流阶段定义。
- `default_config.yaml` — `aws` / `dynamodb` / `sqs` / `aurora` / `valkey` / `nexus_ai` / `agentcore` / `logging` 配置段。
