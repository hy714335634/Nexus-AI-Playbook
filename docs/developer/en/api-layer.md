---
title: API Layer
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

# API Layer

## Overview

The API layer is the front-door service of the Nexus-AI platform, rooted at the `api/v2/` package. It is a **FastAPI** application (`api/v2/main.py`) that exposes HTTP / SSE routes under `/api/v2/*`, wraps four infrastructure clients (DynamoDB / Aurora PostgreSQL / Valkey / SQS), and uniformly wires in authentication middleware, request-ID / trace injection, metrics recording, and a global exception handler.

**Boundary of responsibility:**

- **Upstream**: ALB / API Gateway routes traffic to `uvicorn api.v2.main:app:8000`. The web frontend, external API callers, and CLIs all enter here.
- **Downstream**: Through the four singleton clients under `api/v2/database/`, the layer talks to the persistence tier, the message queue, and the cache. Long-running tasks (build / deploy) are offloaded to SQS and consumed by workers in `agent_build_service/`.
- **What it does NOT do**: It does not execute Agent builds, call Bedrock directly, or run AgentCore Runtime containers. All heavy work is async and handed off through SQS.

**Main entry points:**

| Entry | Location | Purpose |
|-------|----------|---------|
| `app` (FastAPI instance) | `api/v2/main.py:87` | Root object for all route and middleware registration |
| `settings` | `api/v2/config.py:476` | Global configuration (AWS / DB / SQS / AgentCore / templates) |
| `db_client` | end of `api/v2/database/dynamodb.py` | DynamoDB singleton; auto-proxied to Aurora when enabled |
| `pg_client` | end of `api/v2/database/aurora.py` | Aurora PostgreSQL singleton (12 migrated tables) |
| `sqs_client` | `api/v2/database/sqs.py:2710` | SQS singleton; sends build / deploy tasks |
| `cache_client` | `api/v2/database/valkey.py:3050` | Valkey cache + Streams + distributed lock |

## File Layout

| Path | Responsibility | Depends on |
|------|---------------|------------|
| `api/v2/main.py` | FastAPI app construction, middleware, route wiring, health check, startup/shutdown events | `fastapi`, `api/v2/config.py`, `api/v2/auth/middleware.py`, `api/v2/routers/*`, `nexus_utils.observability` |
| `api/v2/config.py` | `Settings` Pydantic model; `TABLE_*` constants; `ALL_TABLES` / `ALL_QUEUES` lists | `pydantic_settings`, `nexus_utils.config_loader` |
| `api/v2/auth/__init__.py` | Auth module marker (middleware lives in `auth/middleware.py`; this file is a package marker only) | none |
| `api/v2/core/__init__.py` | Re-exports all public symbols from `stage_config` | `api/v2/core/stage_config.py` |
| `api/v2/core/config.py` | **Legacy** Settings (superseded by `api/v2/config.py`; kept for compatibility) | `pydantic_settings` |
| `api/v2/core/exceptions.py` | `APIException` base + `ValidationError` / `ResourceNotFoundError` | none |
| `api/v2/core/stage_config.py` | Single source of truth for workflow stage config; `BuildStage` enum generated dynamically | `nexus_utils.workflow_config` |
| `api/v2/database/__init__.py` | Exports the four singletons `db_client` / `pg_client` / `cache_client` / `sqs_client` | sibling client modules |
| `api/v2/database/dynamodb.py` | `DynamoDBClient` singleton; CRUD for 18 DDB tables; Aurora proxy installation | `boto3`, `api/v2/config.py`, `nexus_utils.config_loader` |
| `api/v2/database/aurora.py` | `PostgresClient` singleton; SQL implementation for 12 migrated tables | `psycopg`, `psycopg_pool`, `nexus_utils.config_loader` |
| `api/v2/database/sqs.py` | `SQSClient` singleton; build / deploy task dispatch; W3C trace injection | `boto3`, `api/v2/config.py` |
| `api/v2/database/valkey.py` | `CacheClient` singleton; cache / Streams / distributed lock / Pub-Sub | `redis`, `nexus_utils.config_loader` |

## FastAPI App Wiring (`api/v2/main.py`)

### Import-time side effects

| Location | Action | Reason |
|----------|--------|--------|
| `main.py:21-22` | `os.environ.setdefault("BYPASS_TOOL_CONSENT", "true")` and `STRANDS_NON_INTERACTIVE=true` | The Strands Agent's `file_write` / `shell` tools call `prompt_toolkit` and wait on stdin — in a web process this blocks forever |
| `main.py:25-26` | `from nexus_utils.observability import setup as _setup_observability` → `setup(service_name="nexus-ai-api")` | OTEL auto-instrumentation must run before FastAPI / boto3 are imported |
| `main.py:84` | `logging.getLogger('opentelemetry.context').setLevel(logging.CRITICAL)` | Silences `GeneratorExit` logs when the frontend aborts an SSE stream |

### FastAPI constructor

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

### Middleware (execution order: last registered runs first)

| Order | Middleware | Location | Role |
|-------|-----------|----------|------|
| 1 | `auth_middleware` | `main.py:163` | Global auth (see `api/v2/auth/middleware.py`) |
| 2 | `add_request_id` | `main.py:115-159` | Issue `X-Request-ID`, timing, inject `X-Trace-ID`, emit API metrics |
| 3 | `CORSMiddleware` | `main.py:102-110` | CORS (`allow_origins=settings.CORS_ORIGINS`, default `["*"]`) |

**`add_request_id` key behaviors:**

- Generates `uuid.uuid4()` into `request.state.request_id` and echoes it back in header `X-Request-ID`;
- Computes `process_time` and writes it into `X-Process-Time`;
- Pulls `trace_id` from `opentelemetry.trace.get_current_span()`, formats it as 32-hex, and writes `X-Trace-ID`;
- Calls `record_api_request(method, route, status_code, duration)`; uses the **route template** (e.g. `/api/v2/agents/{agent_id}`) instead of the raw path to keep cardinality bounded;
- When status ≥ 400, additionally calls `_api_m.record_error(method, route, error_class)`, where `error_class` is `4xx_client` or `5xx_server`.

### Route registration

Every router is mounted under `prefix="/api/v2"`. Full list in source order:

| Route | Source symbol | Registration |
|-------|--------------|--------------|
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
| MCP | `mcp_router` (from `nexus_utils.mcp.mcp_client.api`) | `main.py:189` |
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
| Admin Billing (optional) | `admin_billing_router` (wrapped in `ImportError` catch) | `main.py:211-214` |

### Health and root endpoints

| Path | Method | Location | Notes |
|------|--------|----------|-------|
| `/health` | GET | `main.py:219-247` | Synchronously probes `db_client.health_check()` and `sqs_client.health_check()`; any failure → HTTP 503 with `status="degraded"` in body |
| `/` | GET | `main.py:250-259` | Returns `{message, version, docs, health, api_prefix}` |

### Global exception handler

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

### Startup / shutdown events

| Event | Location | Behavior |
|-------|----------|----------|
| `startup_event` | `main.py:285-299` | Reads env var `NEXUS_THREAD_POOL_SIZE` (default `64`) and sets the asyncio default `ThreadPoolExecutor`; logs version / region / endpoint |
| `shutdown_event` | `main.py:303-306` | Logs only |

### Local entry point

```python
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("api.v2.main:app", host="0.0.0.0", port=8000, reload=True, log_level="info")
```

## Configuration Layer (`api/v2/config.py`)

`api/v2/config.py` is the **single entry point for all API-layer configuration**. Load order: environment variables > `default_config.yaml` > hard-coded defaults; the YAML is read via `nexus_utils.config_loader.get_config()`.

### `Settings` (`config.py:356`)

Subclasses `pydantic_settings.BaseSettings`. Fields by group:

| Group | Field | Type | Default source |
|-------|-------|------|----------------|
| Application | `APP_NAME`, `APP_VERSION`, `DEBUG` | `str`, `str`, `bool` | Hard-coded (`"Nexus-AI API"`, `"0.1.0"`, `False`) |
| AWS | `AWS_REGION`, `AWS_DEFAULT_REGION`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` | `str`, `str`, `Optional[str]`, `Optional[str]` | `_aws_config` |
| DynamoDB | `DYNAMODB_ENDPOINT_URL`, `DYNAMODB_TABLE_PREFIX` | `Optional[str]`, `str` | `_aws_config`, `_dynamodb_config` |
| SQS queue names | `SQS_BUILD_QUEUE_NAME`, `SQS_DEPLOY_QUEUE_NAME`, `SQS_NOTIFICATION_QUEUE_NAME`, `SQS_BUILD_DLQ_NAME`, `SQS_DEPLOY_DLQ_NAME` | `str` | `_sqs_queues`, `_sqs_dlq`, prefix `_sqs_prefix` (default `nexus-`) |
| SQS visibility | `BUILD_VISIBILITY_TIMEOUT` (`3600`), `DEPLOY_VISIBILITY_TIMEOUT` (`600`), `MESSAGE_RETENTION_DAYS` (`14`), `MAX_RETRY_COUNT` (`3`) | `int` | `_sqs_config` |
| AgentCore | `AGENTCORE_REGION`, `AGENTCORE_DEPLOY_DRY_RUN`, `AGENTCORE_DEFAULT_ALIAS`, `AGENTCORE_EXECUTION_ROLE_NAME`, `AGENTCORE_AUTO_CREATE_EXECUTION_ROLE`, `AGENTCORE_AUTO_CREATE_ECR`, `AGENTCORE_POST_DEPLOY_TEST`, `AGENTCORE_POST_DEPLOY_TEST_PROMPT`, `AGENTCORE_AUTO_UPDATE_ON_CONFLICT`, `AGENTCORE_REQUIREMENTS_PATH`, `AGENTCORE_IMAGE_TAG_TEMPLATE` | mixed | `_agentcore_config` |
| Session storage | `SESSION_STORAGE_S3_BUCKET`, `SESSION_STORAGE_S3_PREFIX` | `Optional[str]`, `str` | `_nexus_ai_config` |
| Conversation Manager | `CONVERSATION_MANAGER_ENABLED`, `CONVERSATION_MANAGER_TYPE`, `CM_SLIDING_WINDOW_SIZE` (`40`), `CM_SLIDING_TRUNCATE_RESULTS`, `CM_SUMMARY_RATIO` (`0.3`), `CM_PRESERVE_RECENT_MESSAGES` (`10`), `CM_USE_CUSTOM_AGENT`, `CM_CUSTOM_AGENT_MODEL_ID`, `CM_CUSTOM_AGENT_PROMPT_PATH` | mixed | `_nexus_ai_config['conversation_manager']` |
| Attachments | `ATTACHMENT_S3_BUCKET`, `ATTACHMENT_PRESIGNED_URL_EXPIRY` (`3600`), `ATTACHMENT_UPLOAD_URL_EXPIRY` (`600`), `ATTACHMENT_MAX_FILE_SIZE` (`50MB`), `ATTACHMENT_MAX_FILES_PER_MESSAGE` (`5`) | mixed | `_nexus_ai_config` |
| Templates | `TEMPLATE_S3_BUCKET`, `TEMPLATE_S3_KEY_PREFIX`, `TEMPLATE_EFS_SUBDIR`, `TEMPLATE_LOCAL_CACHE_DIR`, `TEMPLATE_UPLOAD_URL_EXPIRY`, `TEMPLATE_MAX_FILE_SIZE` (`100MB`), `TEMPLATE_ALLOWED_EXTENSIONS`, `TEMPLATE_PREVIEW_TEXT_MAX_BYTES`, `TEMPLATE_PREVIEW_WORKERS`, `TEMPLATE_AI_ENABLED`, `TEMPLATE_AI_ANALYZE_MODEL`, `TEMPLATE_AI_EMBED_MODEL`, `TEMPLATE_AI_EMBED_DIM`, `TEMPLATE_AI_DIFF_MODEL`, `TEMPLATE_LIBREOFFICE_BIN`, `TEMPLATE_IMAGEMAGICK_BIN`, `TEMPLATE_TRIAL_AGENT_ID` | mixed | `_nexus_ai_config['templates']` |
| Skill | `SKILL_S3_BUCKET` | `str` | `_nexus_ai_config['artifacts_s3_bucket']` |
| CORS | `CORS_ORIGINS` (`["*"]`), `CORS_ALLOW_CREDENTIALS` (`False`) | `list`, `bool` | Hard-coded |
| Logging | `LOG_LEVEL` (`"INFO"`) | `str` | `_logging_config` |

### `get_settings()` singleton (`config.py:464-473`)

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

**Gotcha**: Pydantic picks up `AWS_REGION` from the environment and can override the YAML value. `get_settings()` force-writes the YAML region back to guarantee YAML wins.

### `TABLE_*` constants (`config.py:482-515`)

All DynamoDB table names are module-level constants, each prefixed by `DYNAMODB_TABLE_PREFIX` (default `nexus_`). The comment `# [Aurora-migrated]` marks tables migrated to Aurora; `DynamoDBClient._setup_aurora_proxy()` rewires their CRUD methods onto `pg_client`.

| Constant | Base table | Status |
|----------|-----------|--------|
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

- `ALL_TABLES`: list of 18 tables still in DDB (used by batch operations such as table-creation scripts).
- `ALL_QUEUES`: list of 5 SQS queue names (`BUILD_QUEUE`, `DEPLOY_QUEUE`, `NOTIFICATION_QUEUE`, `BUILD_DLQ`, `DEPLOY_DLQ`).

## Core Support Module (`api/v2/core/`)

### `core/exceptions.py`

API-layer custom exceptions, all inheriting from `APIException` (a plain Python class — **FastAPI does not catch it automatically**; handle it in routers or rely on the global exception handler).

#### `APIException` (`core/exceptions.py:669`)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `message` | `str` | — | Outward-facing message |
| `status_code` | `int` | `500` | HTTP status code |
| `error_code` | `str` | `"INTERNAL_ERROR"` | Business error code |
| `details` | `Optional[str]` | `None` | Extra details |
| `suggestion` | `Optional[str]` | `None` | Remediation hint |
| `docs_url` | `Optional[str]` | `None` | Link to docs |

#### `ValidationError` (`core/exceptions.py:689`)

Fixed `status_code=400`, `error_code="VALIDATION_ERROR"`, `docs_url="https://docs.nexus-ai.com/api/validation"`.

#### `ResourceNotFoundError` (`core/exceptions.py:702`)

Signature: `ResourceNotFoundError(resource_type: str, resource_id: str)`. Fixed `status_code=404`, `error_code="RESOURCE_NOT_FOUND"`; auto-generates `"<Type> with ID '&lt;id&gt;' does not exist"` as `details`.

### `core/stage_config.py`

The **single authoritative source** for workflow stage configuration. Internally delegates to `nexus_utils.workflow_config.WorkflowConfigManager`; data is loaded dynamically from `config/workflows.yaml`.

#### `StageConfig` (dataclass, `core/stage_config.py:818`)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `name` | `str` | — | Stage name (snake_case — canonical form) |
| `order` | `int` | — | Stage index (1-based) |
| `display_name` | `str` | — | Chinese display name |
| `prompt_path` | `str` | — | Prompt template relative path |
| `log_filename` | `str` | — | Log file name (no extension) |
| `agent_display_name` | `str` | — | English Agent name |
| `supports_iteration` | `bool` | `False` | Whether multi-agent iteration is supported |
| `scope` | `str` | `"project"` | Stage scope |
| `fork_on_complete` | `bool` | `False` | Fork on completion |
| `join_before_start` | `bool` | `False` | Join before starting |
| `join_after_complete` | `bool` | `False` | Join after completion |

#### Module-level symbols

| Symbol | Type | Description |
|--------|------|-------------|
| `BuildStage` | `Enum` | Dynamically generated; members named by uppercased stage names (e.g. `BuildStage.REQUIREMENTS_ANALYSIS`) |
| `STAGES` | `Dict[str, StageConfig]` | name → config |
| `STAGE_SEQUENCE` | `List[str]` | Ordered stage names |
| `ITERATIVE_STAGES` | `List[str]` | Names of stages that support iteration |
| `LEGACY_NAME_MAPPING` | `Dict[str, str]` | legacy name → canonical name |

#### Public functions

| Function | Signature | Notes |
|----------|-----------|-------|
| `get_workflow_config` | `(workflow_type: str = "agent_build") -> WorkflowConfig` | Raises `ValueError` if missing |
| `normalize_stage_name` | `(stage_name: str, workflow_type="agent_build") -> Optional[str]` | legacy → canonical (case-insensitive); `None` if unknown |
| `get_stage_display_name` | `(stage_name, workflow_type="agent_build") -> str` | Chinese display name |
| `get_stage_number` | `(stage_name, workflow_type="agent_build") -> int` | Stage index; `0` if unknown |
| `get_prompt_path` | `(stage_name, workflow_type="agent_build") -> Optional[str]` | Prompt relative path |
| `get_log_filename` | `(stage_name, workflow_type="agent_build") -> Optional[str]` | Log filename |
| `get_agent_display_name` | `(stage_name, workflow_type="agent_build") -> str` | English Agent name |
| `is_iterative_stage` | `(stage_name, workflow_type="agent_build") -> bool` | Whether iterative |
| `get_stage_config` | `(stage_name, workflow_type="agent_build") -> Optional[StageConfig]` | Full config |
| `get_all_stage_names` | `(workflow_type="agent_build") -> List[str]` | All stage names |
| `get_stage_display_name_mapping` | `(workflow_type="agent_build") -> Dict[str, str]` | name → display |
| `get_prompt_path_mapping` | `(workflow_type="agent_build") -> Dict[str, str]` | name → prompt path |
| `get_log_filename_mapping` | `(workflow_type="agent_build") -> Dict[str, str]` | name → log name |
| `get_available_workflows` | `() -> List[str]` | All enabled workflow types |
| `get_workflow_stages` | `(workflow_type: str) -> List[str]` | Stage sequence of a workflow |
| `reload_workflow_config` | `() -> None` | Reload YAML; refresh global `STAGES` / `BuildStage` etc. |

### `core/config.py`

**Legacy file**. It defines another `Settings` (`core/config.py:611`) with a much smaller field set. New code should use `from api.v2.config import settings`.

### `core/__init__.py`

Re-exports from `stage_config` only: `BuildStage`, `StageConfig`, `STAGES`, `STAGE_SEQUENCE`, `ITERATIVE_STAGES`, `LEGACY_NAME_MAPPING`, `normalize_stage_name`, `get_stage_display_name`, `get_stage_number`, `get_prompt_path`, `get_log_filename`, `get_agent_display_name`, `is_iterative_stage`, `get_stage_config`, `get_all_stage_names`, `get_stage_display_name_mapping`, `get_prompt_path_mapping`, `get_log_filename_mapping`.

## Data Layer (`api/v2/database/`)

Four-store architecture:

```
Router / Service
      │
      ▼
db_client (DynamoDB)  ←─ Aurora proxy ─→  pg_client (Aurora PostgreSQL)
      │
      └── Only 18 remaining KV / event / config tables

cache_client (Valkey)  — Cache-Aside / Streams / distributed lock / Pub-Sub
sqs_client (SQS)       — Build / Deploy / Notification queues
```

### `database/__init__.py`

Exports four singletons:

```python
from .dynamodb import DynamoDBClient, db_client
from .sqs import SQSClient, sqs_client
from .aurora import PostgresClient, pg_client
from .valkey import CacheClient, cache_client
```

### `DynamoDBClient` (`database/dynamodb.py:1282`)

**Thread-safe singleton** (double-checked `__new__` plus `_initialized` sentinel).

#### Constructor details

| Step | Line | Notes |
|------|------|-------|
| Resolve region | `dynamodb.py:1299-1303` | Prefer `default_config.yaml.aws.aws_region_name`; ignore `AWS_REGION` env var |
| `Config` arguments | `dynamodb.py:1305-1311` | `retries={'max_attempts': 3, 'mode': 'adaptive'}`, `max_pool_connections=50`, `connect_timeout=10`, `read_timeout=30` |
| Credential selection | `dynamodb.py:1314-1323` | AK/SK from YAML first, then env vars; `profile_name` used only if explicitly configured (not `default`/empty) AND no AK/SK provided |
| Resource / client | `dynamodb.py:1327-1336` | Both the `dynamodb` resource and low-level client receive `endpoint_url=settings.DYNAMODB_ENDPOINT_URL` (for local dev) |
| Aurora proxy | `dynamodb.py:1347` | `_setup_aurora_proxy()` rewires method attributes |

#### `_setup_aurora_proxy()` (`dynamodb.py:1349`)

**Purpose**: rewrites CRUD methods for the 12 migrated tables onto the **instance** so that every call site transparently routes to `pg_client`. Active as long as `aurora.host` is configured (env `NEXUS_AURORA_HOST` or YAML); otherwise the DynamoDB implementations remain.

Proxied method groups (full list at source lines 1370–1465):

| Resource | Proxied methods |
|----------|-----------------|
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

**Kept on DDB**: Tools CRUD, Keys, Key Usage Logs still hit DDB tables directly (annotated as `7+ direct table accesses` / `16+ direct table accesses` in the source).

#### Table attributes (lazy + cached)

`_get_table(table_name)` caches into `self._tables[table_name]`. Every DDB table has a matching `@property`: `projects_table`, `stages_table`, `agents_table`, `invocations_table`, `sessions_table`, `messages_table`, `tasks_table`, `tools_table`, `clarifications_table`, `attachments_table`, `users_table`, `dynamic_configs_table`, `favorites_table`, `skills_table`, `skill_groups_table`, `event_jobs_table`, `event_tasks_table`, `remote_connections_table`, `bridge_command_rules_table`, `connectors_table`, `keys_table`, `key_usage_logs_table`, `directives_table`, `mcp_servers_table`, `system_configs_table`, `backup_shares_table`, `file_shares_table`, `session_template_bindings_table`.

#### Retry decorator `retry_on_error` (`dynamodb.py:1253`)

```python
@retry_on_error(max_retries=3, delay=1.0, backoff=2.0)
def some_method(...): ...
```

Retries with exponential backoff only for `ClientError.Error.Code` ∈ `{ProvisionedThroughputExceededException, ThrottlingException, ServiceUnavailable, InternalServerError}`; other `ClientError` / `BotoCoreError` propagate unchanged. Essentially every DDB write method is decorated.

#### Representative CRUD methods

Every write method injects `created_at` / `updated_at` (UTC ISO with `+00:00` → `Z`) into `data`. Type conversion goes through `self._to_dynamo()` / `self._from_dynamo()` / `self._to_dynamo_value()` (handles `Decimal` / `datetime`).

| Method | Location | Behavior |
|--------|----------|----------|
| `create_user(user_data)` | `dynamodb.py:1630` | `put_item`; timestamps injected |
| `get_user_by_id(user_id)` | `dynamodb.py:1639` | `get_item` by `user_id` |
| `get_user_by_saml_name_id(saml_name_id)` | `dynamodb.py:1646` | GSI query on `SamlNameIdIndex` |
| `get_user_by_email(email)` | `dynamodb.py:1657` | GSI query on `EmailIndex` |
| `update_user(user_id, updates)` | `dynamodb.py:1668` | `UpdateExpression` + `#k = :k` construction |
| `list_users(limit, last_key)` | `dynamodb.py:1686` | `scan` + `ExclusiveStartKey` |
| `count_users()` | `dynamodb.py:1709` | `scan(Select='COUNT', Limit=1)` |
| `delete_user(user_id)` | `dynamodb.py:1715` | `delete_item` |
| `create_project(project_data)` | `dynamodb.py:1723` | `put_item` |
| `put_session_template_binding(binding)` | `dynamodb.py:1592` | Upsert by `(session_id, binding_key)` |
| `list_session_template_bindings(session_id)` | `dynamodb.py:1599` | Query by `session_id` |
| `delete_session_template_bindings(session_id)` | `dynamodb.py:1607` | Batch delete via `batch_writer` |

### `PostgresClient` (`database/aurora.py:1780`)

**Thread-safe singleton**. Uses `psycopg` v3 + `psycopg_pool.ConnectionPool`; `autocommit=True`, `row_factory=dict_row`. Method names and signatures are kept compatible with `DynamoDBClient`.

#### Pool initialization `_init_pool` (`aurora.py:1809`)

| Parameter | Source |
|-----------|--------|
| `host` | env `NEXUS_AURORA_HOST` > `aurora.host` |
| `password` | env `NEXUS_AURORA_PASSWORD` > `aurora.password` |
| `port` | `aurora.port` (default `5432`) |
| `dbname` | `aurora.database` (default `nexus`) |
| `user` | `aurora.username` (default `nexus_admin`) |
| `sslmode` | `aurora.ssl` = True → `require`; else `prefer` |
| `min_size` / `max_size` | `aurora.min_connections` / `max_connections` (default 2 / 20) |

If `host` is unset, accessing the `pool` property raises `RuntimeError("Aurora host not configured")`.

#### Generic executor

| Method | Signature | Use |
|--------|-----------|-----|
| `_execute(sql, params, fetch)` | `fetch ∈ {'one', 'all', 'none', 'rowcount'}` | Returns single row / all rows / nothing / affected-row count; `one` and `all` auto-normalize via `_row_to_dict` |
| `_row_to_dict(row)` | `datetime/date → ISO`, `Decimal → int/float` | Result normalization |
| `_jsonb(v)` | `dict/list → Jsonb` | JSONB column wrap |
| `_prepare(data)` | `{k: _jsonb(v)}` | Bulk-wrap SQL parameter dict |

#### Column cache and `_filter_data` (`aurora.py:1902-1926`)

`_column_cache: Dict[str, set]`: on first access, queries `information_schema.columns` and caches the actual column set. `_filter_data(table, data)` drops any key that exists on the DDB side but not on Aurora, and logs the skipped set at DEBUG level, preventing INSERT/UPDATE syntax errors.

#### Generic CRUD helpers

| Method | Purpose |
|--------|---------|
| `_insert(table, data)` | Builds `INSERT INTO ... VALUES (...) RETURNING *`; filters + JSONB-wraps first |
| `_get(table, where, params)` | `SELECT * FROM ... WHERE ... LIMIT 1` |
| `_update(table, where, where_params, updates)` | Injects `updated_at`; builds `SET k = %(set_k)s, ...` + `RETURNING *` |
| `_delete(table, where, params)` | `DELETE ...`; always returns `True` |
| `_list(table, where, params, order_by, limit, offset)` | Optional where / order_by / limit / offset; returns list |

#### Table methods at a glance

Unified return contract: single-record lookups return `Optional[dict]`; list queries return `list`; paginated queries return `{'items': [...], 'last_key': Optional[str], 'count': int}`, where `last_key` is the `offset` encoded as a string (rather than DDB's `ExclusiveStartKey`).

| Resource | Methods (excerpt) | Notes |
|----------|-------------------|-------|
| Projects | `create_project`, `get_project`, `update_project`, `list_projects(status, user_id, limit, last_key)`, `delete_project`, `update_agents_completion(project_id, agent_id, status)` | `agents_completion` is incrementally merged with `jsonb_build_object` |
| Stages | `create_stage` (auto-derives `stage_id = project_id#stage_key`), `get_stage`, `get_stage_by_agent(project_id, stage_name, agent_id)`, `get_stage_by_key`, `update_stage`, `update_stage_by_key`, `update_stage_by_agent`, `list_stages`, `list_stages_by_prefix`, `list_agent_stages(agent_id)`, `list_all_stages_by_project(project_id)`, `delete_stage`, `delete_stage_by_key` | Prefix search on `stage_key` uses `LIKE` |
| Agents | `create_agent` (seeds default statistics to 0), `get_agent`, `update_agent`, `list_agents(status, category, limit, last_key)`, `delete_agent`, `query_agent_by_name_cn`, `query_agent_by_name_en`, `query_agent_by_dir_name`, `check_agent_name_unique(agent_name_cn, agent_name_en)`, `list_agent_versions(version_group_id)`, `get_active_agent_version(version_group_id)`, `switch_active_version(version_group_id, target_agent_id)`, `backfill_version_fields(agent_id)`, `list_agents_by_project`, `update_agent_statistics(agent_id, input_tokens, output_tokens, conversation_turns, duration_ms)` | Statistics use `SET col = col + %s`; `switch_active_version` runs two statements non-transactionally |

`PostgresClient.health_check()` executes `SELECT 1 AS ok`.

### `SQSClient` (`database/sqs.py:2255`)

**Thread-safe singleton**.

#### Construction

- `region` comes from YAML (same as `DynamoDBClient`);
- `Config(retries={'max_attempts': 3, 'mode': 'adaptive'}, connect_timeout=10, read_timeout=30)`;
- Credential / profile selection follows the same logic as `DynamoDBClient`;
- `endpoint_url=settings.SQS_ENDPOINT_URL` supports local runs.

#### Queue URL caching

`_get_queue_url(queue_name)`: calls `client.get_queue_url(QueueName=...)` and caches the result in `self._queue_urls`; `QueueDoesNotExist` is re-raised.

#### Core methods

| Method | Signature | Notes |
|--------|-----------|-------|
| `send_message` | `(queue_name, message_body, delay_seconds=0, message_attributes=None, message_group_id=None, message_deduplication_id=None) -> Dict` | Generic send; when observability is enabled and `_trace_carrier` is absent, auto-injects W3C trace context via `opentelemetry.propagate.inject()`; returns `{message_id, sequence_number}` |
| `send_build_task` | `(task_id, project_id, requirement, user_id=None, priority=3, metadata=None, target_stage=None, action='execute')` | V1 build task; `task_attributes.task_type='build_agent'` |
| `send_build_task_v2` | `(project_id, stage='intent_recognition', requirement='', user_id=None, agent_id=None, agent_type=None, architecture_type=None, agent_context=None, metadata=None)` | V2 body carries `workflow_type='agent_build'` + `stage`; `task_type='build_agent_v2'` |
| `send_skill_build_task_v2` | `(project_id, stage='intent_recognition', requirement='', user_id=None, metadata=None)` | Skill build; `workflow_type='skill_build'`, `task_type='build_skill_v2'` |
| `send_deploy_task` | `(task_id, project_id, agent_id, deployment_config=None)` | Deploy task; `task_type='deploy_agent'` |
| `receive_messages` | `(queue_name, max_messages=1, wait_time_seconds=20, visibility_timeout=None)` | Long-poll receive; auto JSON-decodes `Body`; returns `[{message_id, receipt_handle, body, attributes, message_attributes}]` |
| `delete_message` | `(queue_name, receipt_handle) -> bool` | ACK |
| `change_message_visibility` | `(queue_name, receipt_handle, visibility_timeout) -> bool` | Extend processing timeout dynamically |
| `get_queue_attributes` | `(queue_name) -> Dict` | Returns approximate message counts, visibility, retention, etc. |
| `health_check()` | `() -> bool` | `list_queues(MaxResults=1)` |

#### Message-attribute formatting

- `_format_message_attributes(attributes)`: `str` → `String`, `int/float` → `Number (StringValue=str(v))`, `bytes` → `Binary`;
- `_parse_message_attributes(attributes)`: reverse, driven by `DataType`. `Number` values with a `.` become `float`, otherwise `int`.

### `CacheClient` (`database/valkey.py:2750`)

**Thread-safe singleton**. Wraps `redis.Redis` (Valkey is Redis-protocol compatible).

#### Dual-client setup

| Attribute | Use | Key parameters |
|-----------|-----|----------------|
| `client` | Regular GET/SET/DEL/SCAN/XADD/... | `socket_timeout=5`, `max_connections=50` |
| `stream_client` | Blocking `XREAD` | `socket_timeout=60`, `max_connections=10` |

`_init_client()` reads endpoint from `NEXUS_VALKEY_ENDPOINT` or `valkey.endpoint`; if empty, sets `available=False` and every method short-circuits (returning empty / `None` / `0`, **never raising**). On success, `ping()` validates the connection.

#### Basic operations

| Method | Signature | Notes |
|--------|-----------|-------|
| `get(key)` | `-> Any` | Returns `None` on miss/error; auto `json.loads` |
| `set(key, value, ttl=60)` | `-> bool` | Auto `json.dumps(..., cls=_CacheEncoder)`; handles `datetime` / `Decimal` |
| `delete(*keys)` | `-> int` | Returns number deleted |
| `delete_pattern(pattern)` | `-> int` | Uses `SCAN` + `DELETE` (safe); batches of 100 |

#### Business invalidation helpers

| Method | Action |
|--------|--------|
| `invalidate_project(project_id)` | Deletes `project:dashboard:{id}`, `project:detail:{id}`, `stats:overview`; pattern-deletes `stats:build:*`, `projects:list:*` |
| `invalidate_agent(agent_id)` | Deletes `agent:detail:{id}`, `stats:overview`; pattern-deletes `agents:list:*`, `stats:agents:*` |
| `invalidate_stage(project_id)` | Deletes `project:dashboard:{id}` |
| `invalidate_tool(project_id=None)` | Deletes `tools:project:{id}` (optional); pattern-deletes `tools:*` |
| `invalidate_skill()` | Pattern-deletes `skills:*` |
| `invalidate_user(user_id)` | Deletes `user:auth:{user_id}` |
| `invalidate_stats()` | Deletes `stats:overview`; pattern-deletes `stats:*` |

#### Redis Streams (Agent background-event buffer)

| Method | Signature | Notes |
|--------|-----------|-------|
| `xadd` | `(stream_key, fields: dict, maxlen=2000) -> Optional[str]` | Non-str values auto-`json.dumps`; length-capped |
| `xread` | `(stream_key, last_id='0', block_ms=15000, count=50) -> list` | Uses `stream_client` (`socket_timeout=60`); returns `[(event_id, fields), ...]` |
| `xrange` | `(stream_key, start='-', end='+', count=100) -> list` | Range read |
| `xlen` | `(stream_key) -> int` | Stream length |
| `expire_stream` | `(stream_key, ttl=1800)` | Set TTL |

#### Distributed lock

| Method | Signature | Notes |
|--------|-----------|-------|
| `acquire_lock` | `(key, value='1', ttl=600) -> bool` | `SET NX EX`; **returns `True` when Valkey is unavailable** (does not block business logic) |
| `release_lock` | `(key)` | Deletes key |
| `get_lock_value` | `(key) -> Optional[str]` | Reads current lock value |

#### Pub/Sub

`publish(channel, message) -> int`: publishes to a channel; non-str auto JSON-serialized; returns subscriber count.

## Data Flow / Call Graph

### Synchronous request path

```
Client → uvicorn → CORSMiddleware → add_request_id → auth_middleware
      → Router (api/v2/routers/<xxx>.py)
      → Service / direct db_client / pg_client / cache_client
      → Response → add_request_id (inject headers) → Client
```

### Aurora proxy path

```
Router calls db_client.get_project(pid)
      │
      ▼
_setup_aurora_proxy() has replaced get_project with pg_client.get_project during __init__
      │
      ▼
pg_client._get('projects', 'project_id = %(pk)s', {'pk': pid})
      │
      ▼
ConnectionPool.connection() → cursor.execute(SQL) → _row_to_dict
```

### Async build flow

```
POST /api/v2/projects  →  Router inserts project row
                       →  sqs_client.send_build_task_v2(project_id, stage='intent_recognition', ...)
                       →  SQS: nexus-build-queue
                       ↓ (worker long-poll)
                       receive_messages → handler dispatched by `task_type`
                       → writes per-stage result to stages table + cache_client.invalidate_project
                       → cache_client.publish('agent_events', ...) or xadd stream
                       ↓
SSE Router (sync API)  ←  cache_client.xread(stream_key, ...)  ←  frontend long connection
```

### Observability propagation

- `main.py`'s `add_request_id` middleware extracts `trace_id` from the current span and injects it into response headers;
- `SQSClient.send_message` auto-calls `opentelemetry.propagate.inject()` to attach the W3C trace context into `message_body._trace_carrier`;
- Workers `extract` from `_trace_carrier` so processing hangs off the same trace.

## Extending

### Add a new HTTP route

1. Create `api/v2/routers/&lt;feature&gt;.py`, exporting `router = APIRouter(prefix="/&lt;path&gt;", tags=["&lt;tag&gt;"])`.
2. Register in `api/v2/routers/__init__.py` if you want a package-level symbol.
3. Import the new router at the top of `api/v2/main.py`.
4. Call `app.include_router(&lt;router&gt;, prefix="/api/v2")` in the route-registration block at `main.py:168-207`.
5. For Swagger grouping, supply `tags=[...]` to `APIRouter`.

**Constraints:**

- The global `auth_middleware` runs for every path; public routes (`auth_router`, `manifest_router`) are allowed via its internal whitelist.
- Do not emit `X-Request-ID` yourself — the `add_request_id` middleware handles it.
- Raise business exceptions from `api/v2/core/exceptions.py` subclasses so the global handler normalizes the response shape.

### Add a new DynamoDB table

1. Append `TABLE_<NAME>` at the end of the `_dynamodb_tables` reads in `api/v2/config.py`.
2. If not migrated to Aurora, add to `ALL_TABLES`.
3. Add `@property &lt;name&gt;_table` in `DynamoDBClient`'s property block.
4. Implement CRUD methods, decorated with `@retry_on_error()`.
5. `_to_dynamo` / `_from_dynamo` already handle `Decimal` / `datetime` / `set` — do not hand-roll `boto3.dynamodb.types.TypeSerializer`.
6. Register user-overridable table names under `dynamodb.tables` in `default_config.yaml`.

### Add a new Aurora table

1. Create the table in a migration first (migration tooling is outside the scope of this document).
2. Add methods to `PostgresClient` following the existing pattern; reuse `_insert` / `_get` / `_update` / `_delete` / `_list` wherever possible.
3. To make legacy `db_client` calls transparently route to Aurora, add `self.&lt;method&gt; = _pg.&lt;method&gt;` proxy lines in `DynamoDBClient._setup_aurora_proxy()`.
4. After adding columns, call `pg_client._column_cache.clear()` or restart the process; otherwise `_filter_data` still filters against the stale schema.

### Add a new SQS queue

1. Register queue names under `sqs.queues` / `sqs.dlq` in `default_config.yaml`.
2. Add `SQS_<NAME>_QUEUE_NAME: str = _sqs_queues.get('&lt;key&gt;', ...)` in `api/v2/config.py`.
3. Include it in `ALL_QUEUES`.
4. Add a `send_&lt;task&gt;_task(...)` helper in `SQSClient`: call `self.send_message` with a sensible `message_attributes.task_type`.
5. Dispatch on `task_type` in the worker.

**Note**: `send_message` auto-injects `_trace_carrier`; workers must `opentelemetry.propagate.extract(body.get('_trace_carrier'))` before processing.

### Add a new workflow stage

1. Edit `config/workflows.yaml`: add an entry under the target workflow's `stages` list (`name`, `order`, `display_name`, `prompt_path`, `log_filename`, `agent_display_name`, `supports_iteration`, and optional `scope` / `fork_on_complete` / `join_before_start` / `join_after_complete`).
2. If the stage uses a new name that legacy code still references, register `&lt;old&gt;: &lt;new&gt;` under `legacy_name_mapping`.
3. For hot reload at runtime, call `api.v2.core.stage_config.reload_workflow_config()`; otherwise restart.
4. `BuildStage` is generated dynamically — new stages become members automatically. Consumers must not hard-code enum names; use `normalize_stage_name()` instead.

### Add a cache invalidation point

1. Check whether `CacheClient.invalidate_*` already covers it.
2. For new resource types, follow the `invalidate_agent` shape: delete fixed keys + pattern-delete fuzzy keys.
3. Invalidation belongs on the **write path**; **never** invalidate in read paths.
4. Cache-Aside rule: write → DB succeeds → `invalidate_*` → return. On the next read-miss, backfill via DB + `set(..., ttl=60)`.

## Debugging / Troubleshooting

### Log keywords

| Keyword | Meaning | Location |
|---------|---------|----------|
| `DynamoDB client initialized` | Singleton constructed for the first time | `dynamodb.py:1341` |
| `Aurora 代理已启用` | Aurora host is configured and the proxy is installed | `dynamodb.py:1467` |
| `Aurora host 未配置，保留 DynamoDB 实现` | Fallback to DDB; 12 migrated-table methods unavailable on Aurora | `dynamodb.py:1367` |
| `Aurora 代理设置失败` | Exception caught during proxy setup; DDB fallback | `dynamodb.py:1470` |
| `Aurora 连接池已初始化` | Pool established | `aurora.py:1835` |
| `Retryable error <Code>, retrying in &lt;wait&gt;s` | DDB throttling | `dynamodb.py:1273` |
| `Valkey 缓存已连接` | Cache layer is live | `valkey.py:2820` |
| `Valkey 连接失败，缓存层禁用` | All cache methods short-circuit | `valkey.py:2822` |
| `Valkey endpoint 未配置，缓存层禁用` | Same, but via missing configuration | `valkey.py:2791` |
| `Sent message to &lt;queue&gt;: <MessageId>` | SQS publish succeeded | `sqs.py:2375` |
| `Queue &lt;name&gt; does not exist` | `_get_queue_url` failure | `sqs.py:2315` |
| `Unhandled exception` + `request_id=&lt;id&gt;` | Global exception handler invoked | `main.py:268` |

### Common exceptions

| Exception | Meaning / Fix |
|-----------|---------------|
| `ProfileNotFound` | `aws_profile_name='default'` with no `~/.aws/config`. Fix: set AK/SK explicitly or clear the profile. |
| `QueueDoesNotExist` | Queue name mismatch or not created. Fix: align `default_config.yaml.sqs.queue_prefix` with `queues.*`. |
| `ClientError: ProvisionedThroughputExceededException` | DDB read/write capacity exhausted. `retry_on_error` backs off 3 times; if it still fails, scale up or switch to on-demand. |
| `RuntimeError: Aurora host not configured` | `PostgresClient.pool` accessed with empty `host`. Fix: set `NEXUS_AURORA_HOST` or `aurora.host`. |
| `ValueError: Workflow config not found` | `get_workflow_config()` received an unknown `workflow_type`. Check `config/workflows.yaml`. |
| `INTERNAL_ERROR` (500 body) | Global handler catch-all. Grep logs by `request_id`. |

### Diagnostic endpoints

| Endpoint | Use |
|----------|-----|
| `GET /health` | DDB + SQS health; 503 = degraded |
| `GET /docs` | Swagger UI with the full router schema |
| `GET /openapi.json` | Machine-readable OpenAPI 3 document |
| `GET /redoc` | Redoc-styled API docs |

### Response headers cheat sheet

| Header | Meaning |
|--------|---------|
| `X-Request-ID` | UUID of this request; use for cross-log correlation |
| `X-Process-Time` | Server-side handling time (seconds) |
| `X-Trace-ID` | Current span's trace ID; correlate in CloudWatch / X-Ray |

## Further Reading

- `api/v2/routers/` — per-router business schemas and endpoints (see dedicated sub-docs).
- `api/v2/auth/middleware.py` — auth logic and whitelist.
- `nexus_utils/observability/` — `setup`, `instrument_fastapi`, `record_api_request`, metrics.
- `nexus_utils/config_loader.py` — YAML loading and merge logic.
- `nexus_utils/workflow_config.py` — `WorkflowConfigManager`, `WorkflowConfig`, `StageConfig`.
- `agent_build_service/` — SQS consumers, build / deploy handler implementations.
- `config/workflows.yaml` — workflow stage definitions.
- `default_config.yaml` — `aws` / `dynamodb` / `sqs` / `aurora` / `valkey` / `nexus_ai` / `agentcore` / `logging` sections.
