---
title: Environment Variables
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - api/v2/config.py
    - nexus-cli
    - nexus_utils/config_loader.py
  generated_at: 2026-05-09T01:18:23+00:00
  generated_by: docs-sync v2
---

# Environment Variables

This document lists every environment variable Nexus-AI reads. Purpose, default, and type all come from source (`api/v2/config.py`, `nexus_utils/config_loader.py`) — nothing is inferred.

## Overview

Nexus-AI resolves configuration in a fixed **priority order**:

1. **Environment variable** (read at process start)
2. **YAML config file** (`config/default_config.yaml`, `config/service_config.yaml`)
3. **Built-in code default**

Setting an environment variable overrides the matching YAML key. All environment variables are **strings** and are coerced to `int` / `bool` as needed; booleans follow Pydantic's rules (`true` / `false` / `1` / `0` all work).

::: tip `.env` file
The `Settings` class in `api/v2/config.py` extends Pydantic's `BaseSettings` and reads a `.env` file from the current working directory (UTF-8, case-sensitive). `.env` entries are equivalent to process environment variables, but real environment variables win.
:::

::: warning Special behavior: `AWS_REGION` is force-overwritten
Even though Pydantic would normally let the `AWS_REGION` environment variable override the field, `get_settings()` **forces** `AWS_REGION` and `AWS_DEFAULT_REGION` back to `aws.aws_region_name` from `default_config.yaml` before returning the cached instance. In other words, **setting `AWS_REGION` in the environment has no effect in the API v2 path** — change the YAML instead.
:::

## Loader map

| Module                            | File                                | Notes                                  |
| --------------------------------- | ----------------------------------- | -------------------------------------- |
| `ConfigLoader` and sub-getters    | `nexus_utils/config_loader.py`      | YAML config + env overrides            |
| API / Worker / Web / MCP / Bridge | `get_service_config()` in `nexus_utils/config_loader.py` | Reads `config/service_config.yaml`     |
| FastAPI `Settings`                | `api/v2/config.py`                  | Pydantic `BaseSettings`, supports `.env` |

---

## API service

| Variable                          | Type | Default     | Description |
| --------------------------------- | ---- | ----------- | ----------- |
| `API_PORT`                        | int  | `8000`      | Port the API server listens on |
| `NEXUS_API_WORKERS`               | int  | `1`         | Number of API workers (uvicorn workers) |
| `NEXUS_THREAD_POOL_SIZE`          | int  | `64`        | Sync thread-pool size on the API process, used to offload blocking calls |
| `NEXUS_AGENT_CREATION_TIMEOUT`    | int  | `120`       | Timeout for agent creation, in seconds |
| `NEXUS_SSE_HEARTBEAT_INTERVAL`    | int  | `15`        | SSE heartbeat interval, in seconds |
| `NEXUS_MAX_CONCURRENT_STREAMS`    | int  | `0`         | Maximum concurrent SSE streams; `0` means unlimited |

::: info Bind host
The API host comes from `api.host` in `service_config.yaml` (default `0.0.0.0`); the current build does not expose an environment variable for it.
:::

## Worker

| Variable                           | Type | Default | Description |
| ---------------------------------- | ---- | ------- | ----------- |
| `NEXUS_WORKER_THREAD_POOL_SIZE`    | int  | `32`    | Thread-pool size on the Worker process |

## Web frontend

| Variable    | Type | Default | Description |
| ----------- | ---- | ------- | ----------- |
| `WEB_PORT`  | int  | `3000`  | Port the web frontend listens on |

## MCP service

| Variable         | Type | Default | Description |
| ---------------- | ---- | ------- | ----------- |
| `NEXUS_MCP_PORT` | int  | `9000`  | Port the MCP service listens on |

## Bridge service

| Variable                     | Type | Default | Description |
| ---------------------------- | ---- | ------- | ----------- |
| `BRIDGE_PORT`                | int  | `8001`  | Port the Bridge service listens on |
| `BRIDGE_COMMAND_TIMEOUT`     | int  | `900`   | Per-command execution timeout, in seconds |
| `BRIDGE_CONNECTION_TIMEOUT`  | int  | `1200`  | Connection keep-alive timeout, in seconds |

## Sandbox Controller

| Variable                             | Type | Default    | Description |
| ------------------------------------ | ---- | ---------- | ----------- |
| `SANDBOX_CONTROLLER_HOST`            | str  | `0.0.0.0`  | Sandbox Controller bind address |
| `SANDBOX_CONTROLLER_PORT`            | int  | `8002`     | Sandbox Controller listen port |
| `SANDBOX_PATROL_INTERVAL`            | int  | `30`       | Interval between node health patrols, in seconds |
| `SANDBOX_HEARTBEAT_TIMEOUT`          | int  | `90`       | Node heartbeat timeout threshold, in seconds |
| `SANDBOX_SCALE_DOWN_IDLE_MINUTES`    | int  | `10`       | Minutes a node must be idle before it is scaled down |
| `SANDBOX_MIN_NODES`                  | int  | `1`        | Minimum retained nodes in the cluster |

---

## AWS basics

These are read by the Pydantic `BaseSettings` class in `api/v2/config.py`; if unset they fall back to `aws.*` in `default_config.yaml`.

| Variable                  | Type | Default       | Description |
| ------------------------- | ---- | ------------- | ----------- |
| `AWS_REGION`              | str  | `us-west-2`   | Force-overwritten in API v2 by `aws.aws_region_name`; **has no effect** — change the YAML |
| `AWS_DEFAULT_REGION`      | str  | `us-west-2`   | Same as above, force-overwritten |
| `AWS_ACCESS_KEY_ID`       | str  | —             | Optional; leave empty to use the ambient / IAM-role credential chain |
| `AWS_SECRET_ACCESS_KEY`   | str  | —             | Optional; same as above |

## DynamoDB

Table names are built as `{table_prefix}{short_name}`. Selected short names can be overridden per table; unlisted tables fall back to `dynamodb.tables.*` in the YAML.

| Variable                           | Type | Default     | Description |
| ---------------------------------- | ---- | ----------- | ----------- |
| `NEXUS_DYNAMODB_TABLE_PREFIX`      | str  | `nexus_`    | Prefix for all DynamoDB table names |
| `NEXUS_DYNAMODB_PROJECTS_TABLE`    | str  | `projects`  | Short name for the `projects` table (final name is `{prefix}projects`) |
| `NEXUS_DYNAMODB_STAGES_TABLE`      | str  | `stages`    | Short name for the `stages` table |
| `NEXUS_DYNAMODB_TASKS_TABLE`       | str  | `tasks`     | Short name for the `tasks` table |
| `DYNAMODB_ENDPOINT_URL`            | str  | —           | Optional; custom DynamoDB endpoint (for LocalStack, VPC Endpoints, etc.) |
| `DYNAMODB_TABLE_PREFIX`            | str  | `nexus_`    | Pydantic `Settings` prefix field (equivalent to `NEXUS_DYNAMODB_TABLE_PREFIX`, read by API v2) |

## SQS

Queue names are built as `{queue_prefix}{short_name}`.

| Variable                              | Type | Default                 | Description |
| ------------------------------------- | ---- | ----------------------- | ----------- |
| `NEXUS_SQS_QUEUE_PREFIX`              | str  | `nexus-`                | Prefix for all SQS queue names |
| `NEXUS_SQS_BUILD_QUEUE`               | str  | `build-queue`           | Build queue short name |
| `NEXUS_SQS_DEPLOY_QUEUE`              | str  | `deploy-queue`          | Deploy queue short name |
| `NEXUS_SQS_NOTIFICATION_QUEUE`        | str  | `notification-queue`    | Notification queue short name |
| `NEXUS_SQS_BUILD_DLQ`                 | str  | `build-dlq`             | Build dead-letter queue short name |
| `NEXUS_SQS_DEPLOY_DLQ`                | str  | `deploy-dlq`            | Deploy dead-letter queue short name |
| `NEXUS_SQS_VISIBILITY_TIMEOUT`        | int  | `3600`                  | Default message visibility timeout, in seconds |
| `NEXUS_SQS_BUILD_VISIBILITY_TIMEOUT`  | int  | `3600`                  | Visibility timeout for the build queue, in seconds |
| `NEXUS_SQS_DEPLOY_VISIBILITY_TIMEOUT` | int  | `600`                   | Visibility timeout for the deploy queue, in seconds |
| `NEXUS_SQS_MESSAGE_RETENTION_DAYS`    | int  | `14`                    | Message retention window, in days |
| `NEXUS_SQS_MAX_RETRY_COUNT`           | int  | `3`                     | Maximum retries (matches the DLQ `maxReceiveCount`) |
| `SQS_ENDPOINT_URL`                    | str  | —                       | Optional; custom SQS endpoint (API v2 `Settings` field) |
| `SQS_BUILD_QUEUE_NAME`                | str  | `{prefix}build-queue`   | Pydantic `Settings` field; full queue name |
| `SQS_DEPLOY_QUEUE_NAME`               | str  | `{prefix}deploy-queue`  | Pydantic `Settings` field; full queue name |
| `SQS_NOTIFICATION_QUEUE_NAME`         | str  | `{prefix}notification-queue` | Pydantic `Settings` field; full queue name |
| `SQS_BUILD_DLQ_NAME`                  | str  | `{prefix}build-dlq`     | Pydantic `Settings` field; full DLQ name |
| `SQS_DEPLOY_DLQ_NAME`                 | str  | `{prefix}deploy-dlq`    | Pydantic `Settings` field; full DLQ name |
| `BUILD_VISIBILITY_TIMEOUT`            | int  | `3600`                  | Pydantic `Settings` field (equivalent to `NEXUS_SQS_BUILD_VISIBILITY_TIMEOUT`) |
| `DEPLOY_VISIBILITY_TIMEOUT`           | int  | `600`                   | Pydantic `Settings` field (equivalent to `NEXUS_SQS_DEPLOY_VISIBILITY_TIMEOUT`) |
| `MESSAGE_RETENTION_DAYS`              | int  | `14`                    | Pydantic `Settings` field (equivalent to `NEXUS_SQS_MESSAGE_RETENTION_DAYS`) |
| `MAX_RETRY_COUNT`                     | int  | `3`                     | Pydantic `Settings` field (equivalent to `NEXUS_SQS_MAX_RETRY_COUNT`) |

::: info Two parallel variable sets
The `NEXUS_SQS_*` variables are read inside `ConfigLoader.get_sqs_config()`; the `SQS_*_NAME` / `BUILD_VISIBILITY_TIMEOUT` etc. are read by the Pydantic `Settings`. To keep both code paths consistent, **set both sets to the same value** in your deployment scripts.
:::

---

## Aurora PostgreSQL

| Variable                  | Type | Default | Description |
| ------------------------- | ---- | ------- | ----------- |
| `NEXUS_AURORA_HOST`       | str  | `""`    | Aurora writer endpoint; empty string means unconfigured |
| `NEXUS_AURORA_PASSWORD`   | str  | `""`    | Aurora database password (inject from Secrets Manager in production) |

## ElastiCache Valkey

| Variable                 | Type | Default | Description |
| ------------------------ | ---- | ------- | ----------- |
| `NEXUS_VALKEY_ENDPOINT`  | str  | `""`    | Valkey Serverless endpoint (`host:port`) |

---

## Workflow engine

| Variable                            | Type | Default  | Description |
| ----------------------------------- | ---- | -------- | ----------- |
| `NEXUS_WORKFLOW_MAX_RETRIES`        | int  | `3`      | Maximum retries per workflow stage |
| `NEXUS_WORKFLOW_STAGE_TIMEOUT`      | int  | `3600`   | Per-stage timeout, in seconds |
| `NEXUS_WORKFLOW_MAX_CONTEXT_TOKENS` | int  | `100000` | Maximum workflow context tokens |

---

## AgentCore deployment

These variables come from Pydantic `Settings`; if unset they fall back to `agentcore.*` in `default_config.yaml`.

| Variable                              | Type | Default                             | Description |
| ------------------------------------- | ---- | ----------------------------------- | ----------- |
| `AGENTCORE_REGION`                    | str  | `us-west-2`                         | AWS region for AgentCore deployments (falls back to `aws.aws_region_name`) |
| `AGENTCORE_DEPLOY_DRY_RUN`            | bool | `false`                             | When `true`, print the plan without creating resources |
| `AGENTCORE_DEFAULT_ALIAS`             | str  | `DEFAULT`                           | Default agent alias |
| `AGENTCORE_EXECUTION_ROLE_NAME`       | str  | —                                   | AgentCore execution role ARN; if empty, `AGENTCORE_AUTO_CREATE_EXECUTION_ROLE` decides whether to create one |
| `AGENTCORE_AUTO_CREATE_EXECUTION_ROLE`| bool | `true`                              | Whether to auto-create the execution role if missing |
| `AGENTCORE_AUTO_CREATE_ECR`           | bool | `true`                              | Whether to auto-create the ECR repository |
| `AGENTCORE_POST_DEPLOY_TEST`          | bool | `false`                             | Whether to send a test message after deployment |
| `AGENTCORE_POST_DEPLOY_TEST_PROMPT`   | str  | `Hello`                             | Test message content |
| `AGENTCORE_AUTO_UPDATE_ON_CONFLICT`   | bool | `true`                              | Auto-update an existing agent on conflict (otherwise raise) |
| `AGENTCORE_REQUIREMENTS_PATH`         | str  | `requirements.txt`                  | Path to the requirements file used by AgentCore build |
| `AGENTCORE_IMAGE_TAG_TEMPLATE`        | str  | `{agent_name}:{timestamp}`          | Image tag template |

---

## Session storage

| Variable                      | Type | Default     | Description |
| ----------------------------- | ---- | ----------- | ----------- |
| `SESSION_STORAGE_S3_BUCKET`   | str  | —           | S3 bucket for session history archive; archiving is disabled when unset |
| `SESSION_STORAGE_S3_PREFIX`   | str  | `sessions/` | S3 key prefix for session objects |

## Conversation Manager

| Variable                         | Type  | Default                                                                      | Description |
| -------------------------------- | ----- | ---------------------------------------------------------------------------- | ----------- |
| `CONVERSATION_MANAGER_ENABLED`   | bool  | `true`                                                                       | Enable the conversation manager |
| `CONVERSATION_MANAGER_TYPE`      | str   | `sliding_window`                                                             | Manager type; `sliding_window` or `summarizing` |
| `CM_SLIDING_WINDOW_SIZE`         | int   | `40`                                                                         | Number of messages retained by the sliding window |
| `CM_SLIDING_TRUNCATE_RESULTS`    | bool  | `true`                                                                       | Whether the sliding window truncates tool results |
| `CM_SUMMARY_RATIO`               | float | `0.3`                                                                        | Summarizing mode: summary ratio |
| `CM_PRESERVE_RECENT_MESSAGES`    | int   | `10`                                                                         | Summarizing mode: most recent messages to preserve |
| `CM_USE_CUSTOM_AGENT`            | bool  | `true`                                                                       | Summarizing mode: use the custom summarizer agent |
| `CM_CUSTOM_AGENT_MODEL_ID`       | str   | `us.anthropic.claude-haiku-4-5-20251001-v1:0`                                | Model ID for the summarizer agent |
| `CM_CUSTOM_AGENT_PROMPT_PATH`    | str   | `system_agents_prompts/conversation_summarizer/conversation_summarizer`      | Prompt path for the summarizer agent |

---

## Attachments

| Variable                              | Type | Default                 | Description |
| ------------------------------------- | ---- | ----------------------- | ----------- |
| `ATTACHMENT_S3_BUCKET`                | str  | `nexus-ai-attachments`  | S3 bucket for attachment storage |
| `ATTACHMENT_PRESIGNED_URL_EXPIRY`     | int  | `3600`                  | Download presigned URL expiry, in seconds |
| `ATTACHMENT_UPLOAD_URL_EXPIRY`        | int  | `600`                   | Upload presigned URL expiry, in seconds |
| `ATTACHMENT_MAX_FILE_SIZE`            | int  | `52428800` (50 MB)      | Maximum bytes per file |
| `ATTACHMENT_MAX_FILES_PER_MESSAGE`    | int  | `5`                     | Maximum attachments per message |

## Template repository

| Variable                             | Type | Default                                             | Description |
| ------------------------------------ | ---- | --------------------------------------------------- | ----------- |
| `TEMPLATE_S3_BUCKET`                 | str  | Falls back to `ATTACHMENT_S3_BUCKET`                | S3 bucket for templates |
| `TEMPLATE_S3_KEY_PREFIX`             | str  | `templates/`                                        | S3 key prefix for templates |
| `TEMPLATE_EFS_SUBDIR`                | str  | `/templates`                                        | Template subdirectory when EFS is mounted |
| `TEMPLATE_LOCAL_CACHE_DIR`           | str  | `""`                                                | Local template cache directory for pure-local deployments |
| `TEMPLATE_UPLOAD_URL_EXPIRY`         | int  | `600`                                               | Template upload URL expiry, in seconds |
| `TEMPLATE_MAX_FILE_SIZE`             | int  | `104857600` (100 MB)                                | Maximum bytes per template file |
| `TEMPLATE_ALLOWED_EXTENSIONS`        | list | `[pptx, docx, xlsx, pdf, html, htm, md, txt, png, jpg]` | Allowed extensions (JSON array string) |
| `TEMPLATE_PREVIEW_TEXT_MAX_BYTES`    | int  | `102400` (100 KB)                                   | Maximum bytes for text preview |
| `TEMPLATE_PREVIEW_WORKERS`           | int  | `4`                                                 | Concurrent workers for preview generation |
| `TEMPLATE_AI_ENABLED`                | bool | `true`                                              | Enable AI analysis for templates |
| `TEMPLATE_AI_ANALYZE_MODEL`          | str  | `us.anthropic.claude-haiku-4-5-20251001-v1:0`       | Template analysis model ID |
| `TEMPLATE_AI_EMBED_MODEL`            | str  | `amazon.titan-embed-text-v2:0`                      | Template embedding model ID |
| `TEMPLATE_AI_EMBED_DIM`              | int  | `1024`                                              | Template embedding dimension |
| `TEMPLATE_AI_DIFF_MODEL`             | str  | `us.anthropic.claude-haiku-4-5-20251001-v1:0`       | Template diff model ID |
| `TEMPLATE_LIBREOFFICE_BIN`           | str  | `libreoffice`                                       | LibreOffice binary path |
| `TEMPLATE_IMAGEMAGICK_BIN`           | str  | `convert`                                           | ImageMagick binary path |
| `TEMPLATE_TRIAL_AGENT_ID`            | str  | `featured_deep_research`                            | Default agent ID for template "try it" |

## Skill (deprecated)

| Variable            | Type | Default                    | Description |
| ------------------- | ---- | -------------------------- | ----------- |
| `SKILL_S3_BUCKET`   | str  | `nexus-ai-artifacts-2026`  | Deprecated; skills now use `nexus_ai.artifacts_s3_bucket` |

---

## Observability

| Variable                        | Type | Default                   | Description |
| ------------------------------- | ---- | ------------------------- | ----------- |
| `OTEL_EXPORTER_OTLP_ENDPOINT`   | str  | `http://localhost:4318`   | OpenTelemetry OTLP exporter endpoint; the env var overrides `nexus_ai.OTEL_EXPORTER_OTLP_ENDPOINT` |

## Logging & app metadata

| Variable                    | Type | Default        | Description |
| --------------------------- | ---- | -------------- | ----------- |
| `LOG_LEVEL`                 | str  | `INFO`         | Log level; one of `DEBUG` / `INFO` / `WARNING` / `ERROR` / `CRITICAL` |
| `APP_NAME`                  | str  | `Nexus-AI API` | FastAPI application name |
| `APP_VERSION`               | str  | `0.1.0`        | FastAPI application version |
| `DEBUG`                     | bool | `false`        | Enable debug mode |

## CORS

| Variable                    | Type | Default     | Description |
| --------------------------- | ---- | ----------- | ----------- |
| `CORS_ORIGINS`              | list | `["*"]`     | Allowed origins (JSON array string) |
| `CORS_ALLOW_CREDENTIALS`    | bool | `false`     | Allow credentials in CORS requests |

---

## `.env` example

The example below covers the most common deployment settings. Unlisted values stay at their source-code defaults.

```bash
# Application
APP_NAME=Nexus-AI API
APP_VERSION=0.1.0
DEBUG=false
LOG_LEVEL=INFO

# API / Web / MCP / Bridge ports
API_PORT=8000
WEB_PORT=3000
NEXUS_MCP_PORT=9000
BRIDGE_PORT=8001

# API concurrency
NEXUS_API_WORKERS=4
NEXUS_THREAD_POOL_SIZE=64
NEXUS_WORKER_THREAD_POOL_SIZE=32
NEXUS_AGENT_CREATION_TIMEOUT=120
NEXUS_SSE_HEARTBEAT_INTERVAL=15
NEXUS_MAX_CONCURRENT_STREAMS=0

# AWS credentials (leave empty to use IAM role / default credential chain)
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=

# DynamoDB
NEXUS_DYNAMODB_TABLE_PREFIX=nexus_

# SQS
NEXUS_SQS_QUEUE_PREFIX=nexus-
NEXUS_SQS_VISIBILITY_TIMEOUT=3600
NEXUS_SQS_BUILD_VISIBILITY_TIMEOUT=3600
NEXUS_SQS_DEPLOY_VISIBILITY_TIMEOUT=600
NEXUS_SQS_MESSAGE_RETENTION_DAYS=14
NEXUS_SQS_MAX_RETRY_COUNT=3

# Aurora / Valkey
NEXUS_AURORA_HOST=nexus-aurora.cluster-xxxxx.us-west-2.rds.amazonaws.com
NEXUS_AURORA_PASSWORD=changeme
NEXUS_VALKEY_ENDPOINT=nexus-valkey.serverless.use1.cache.amazonaws.com:6379

# Workflow
NEXUS_WORKFLOW_MAX_RETRIES=3
NEXUS_WORKFLOW_STAGE_TIMEOUT=3600
NEXUS_WORKFLOW_MAX_CONTEXT_TOKENS=100000

# AgentCore
AGENTCORE_REGION=us-west-2
AGENTCORE_DEPLOY_DRY_RUN=false
AGENTCORE_AUTO_CREATE_EXECUTION_ROLE=true
AGENTCORE_AUTO_CREATE_ECR=true
AGENTCORE_AUTO_UPDATE_ON_CONFLICT=true

# Observability
OTEL_EXPORTER_OTLP_ENDPOINT=http://otel-collector:4318
```

## Quick lookup

Alphabetical, for ⌘F:

| Name | Category |
| ---- | -------- |
| `AGENTCORE_AUTO_CREATE_ECR` | AgentCore |
| `AGENTCORE_AUTO_CREATE_EXECUTION_ROLE` | AgentCore |
| `AGENTCORE_AUTO_UPDATE_ON_CONFLICT` | AgentCore |
| `AGENTCORE_DEFAULT_ALIAS` | AgentCore |
| `AGENTCORE_DEPLOY_DRY_RUN` | AgentCore |
| `AGENTCORE_EXECUTION_ROLE_NAME` | AgentCore |
| `AGENTCORE_IMAGE_TAG_TEMPLATE` | AgentCore |
| `AGENTCORE_POST_DEPLOY_TEST` | AgentCore |
| `AGENTCORE_POST_DEPLOY_TEST_PROMPT` | AgentCore |
| `AGENTCORE_REGION` | AgentCore |
| `AGENTCORE_REQUIREMENTS_PATH` | AgentCore |
| `API_PORT` | API |
| `APP_NAME` | App metadata |
| `APP_VERSION` | App metadata |
| `ATTACHMENT_MAX_FILES_PER_MESSAGE` | Attachments |
| `ATTACHMENT_MAX_FILE_SIZE` | Attachments |
| `ATTACHMENT_PRESIGNED_URL_EXPIRY` | Attachments |
| `ATTACHMENT_S3_BUCKET` | Attachments |
| `ATTACHMENT_UPLOAD_URL_EXPIRY` | Attachments |
| `AWS_ACCESS_KEY_ID` | AWS |
| `AWS_DEFAULT_REGION` | AWS (force-overwritten) |
| `AWS_REGION` | AWS (force-overwritten) |
| `AWS_SECRET_ACCESS_KEY` | AWS |
| `BRIDGE_COMMAND_TIMEOUT` | Bridge |
| `BRIDGE_CONNECTION_TIMEOUT` | Bridge |
| `BRIDGE_PORT` | Bridge |
| `BUILD_VISIBILITY_TIMEOUT` | SQS |
| `CM_CUSTOM_AGENT_MODEL_ID` | Conversation Manager |
| `CM_CUSTOM_AGENT_PROMPT_PATH` | Conversation Manager |
| `CM_PRESERVE_RECENT_MESSAGES` | Conversation Manager |
| `CM_SLIDING_TRUNCATE_RESULTS` | Conversation Manager |
| `CM_SLIDING_WINDOW_SIZE` | Conversation Manager |
| `CM_SUMMARY_RATIO` | Conversation Manager |
| `CM_USE_CUSTOM_AGENT` | Conversation Manager |
| `CONVERSATION_MANAGER_ENABLED` | Conversation Manager |
| `CONVERSATION_MANAGER_TYPE` | Conversation Manager |
| `CORS_ALLOW_CREDENTIALS` | CORS |
| `CORS_ORIGINS` | CORS |
| `DEBUG` | App metadata |
| `DEPLOY_VISIBILITY_TIMEOUT` | SQS |
| `DYNAMODB_ENDPOINT_URL` | DynamoDB |
| `DYNAMODB_TABLE_PREFIX` | DynamoDB |
| `LOG_LEVEL` | Logging |
| `MAX_RETRY_COUNT` | SQS |
| `MESSAGE_RETENTION_DAYS` | SQS |
| `NEXUS_AGENT_CREATION_TIMEOUT` | API |
| `NEXUS_API_WORKERS` | API |
| `NEXUS_AURORA_HOST` | Aurora |
| `NEXUS_AURORA_PASSWORD` | Aurora |
| `NEXUS_DYNAMODB_PROJECTS_TABLE` | DynamoDB |
| `NEXUS_DYNAMODB_STAGES_TABLE` | DynamoDB |
| `NEXUS_DYNAMODB_TABLE_PREFIX` | DynamoDB |
| `NEXUS_DYNAMODB_TASKS_TABLE` | DynamoDB |
| `NEXUS_MAX_CONCURRENT_STREAMS` | API |
| `NEXUS_MCP_PORT` | MCP |
| `NEXUS_SQS_BUILD_DLQ` | SQS |
| `NEXUS_SQS_BUILD_QUEUE` | SQS |
| `NEXUS_SQS_BUILD_VISIBILITY_TIMEOUT` | SQS |
| `NEXUS_SQS_DEPLOY_DLQ` | SQS |
| `NEXUS_SQS_DEPLOY_QUEUE` | SQS |
| `NEXUS_SQS_DEPLOY_VISIBILITY_TIMEOUT` | SQS |
| `NEXUS_SQS_MAX_RETRY_COUNT` | SQS |
| `NEXUS_SQS_MESSAGE_RETENTION_DAYS` | SQS |
| `NEXUS_SQS_NOTIFICATION_QUEUE` | SQS |
| `NEXUS_SQS_QUEUE_PREFIX` | SQS |
| `NEXUS_SQS_VISIBILITY_TIMEOUT` | SQS |
| `NEXUS_SSE_HEARTBEAT_INTERVAL` | API |
| `NEXUS_THREAD_POOL_SIZE` | API |
| `NEXUS_VALKEY_ENDPOINT` | Valkey |
| `NEXUS_WORKER_THREAD_POOL_SIZE` | Worker |
| `NEXUS_WORKFLOW_MAX_CONTEXT_TOKENS` | Workflow |
| `NEXUS_WORKFLOW_MAX_RETRIES` | Workflow |
| `NEXUS_WORKFLOW_STAGE_TIMEOUT` | Workflow |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | Observability |
| `SANDBOX_CONTROLLER_HOST` | Sandbox Controller |
| `SANDBOX_CONTROLLER_PORT` | Sandbox Controller |
| `SANDBOX_HEARTBEAT_TIMEOUT` | Sandbox Controller |
| `SANDBOX_MIN_NODES` | Sandbox Controller |
| `SANDBOX_PATROL_INTERVAL` | Sandbox Controller |
| `SANDBOX_SCALE_DOWN_IDLE_MINUTES` | Sandbox Controller |
| `SESSION_STORAGE_S3_BUCKET` | Session storage |
| `SESSION_STORAGE_S3_PREFIX` | Session storage |
| `SKILL_S3_BUCKET` | Skill (deprecated) |
| `SQS_BUILD_DLQ_NAME` | SQS |
| `SQS_BUILD_QUEUE_NAME` | SQS |
| `SQS_DEPLOY_DLQ_NAME` | SQS |
| `SQS_DEPLOY_QUEUE_NAME` | SQS |
| `SQS_ENDPOINT_URL` | SQS |
| `SQS_NOTIFICATION_QUEUE_NAME` | SQS |
| `TEMPLATE_AI_ANALYZE_MODEL` | Templates |
| `TEMPLATE_AI_DIFF_MODEL` | Templates |
| `TEMPLATE_AI_EMBED_DIM` | Templates |
| `TEMPLATE_AI_EMBED_MODEL` | Templates |
| `TEMPLATE_AI_ENABLED` | Templates |
| `TEMPLATE_ALLOWED_EXTENSIONS` | Templates |
| `TEMPLATE_EFS_SUBDIR` | Templates |
| `TEMPLATE_IMAGEMAGICK_BIN` | Templates |
| `TEMPLATE_LIBREOFFICE_BIN` | Templates |
| `TEMPLATE_LOCAL_CACHE_DIR` | Templates |
| `TEMPLATE_MAX_FILE_SIZE` | Templates |
| `TEMPLATE_PREVIEW_TEXT_MAX_BYTES` | Templates |
| `TEMPLATE_PREVIEW_WORKERS` | Templates |
| `TEMPLATE_S3_BUCKET` | Templates |
| `TEMPLATE_S3_KEY_PREFIX` | Templates |
| `TEMPLATE_TRIAL_AGENT_ID` | Templates |
| `TEMPLATE_UPLOAD_URL_EXPIRY` | Templates |
| `WEB_PORT` | Web |

## Notes

- When the same semantic value can be set via both a `NEXUS_*` variable and a Pydantic short-name variable (e.g. `BUILD_VISIBILITY_TIMEOUT`), the two are read on different code paths. Setting only one leads to **`ConfigLoader` seeing the new value while API v2 `Settings` keeps the default** (or vice versa). **Set both to the same value in production deployments.**
- Once an environment variable has been captured by `ConfigLoader` / `get_settings()`, it is cached and not re-read at runtime. Changing an environment variable requires **restarting the process** to take effect.
- For sensitive credentials (`NEXUS_AURORA_PASSWORD`, `AWS_SECRET_ACCESS_KEY`), inject them via Secrets Manager / Parameter Store / Kubernetes Secret. Do not commit them in a `.env` file to the repository.
