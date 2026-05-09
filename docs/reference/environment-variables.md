---
title: 环境变量
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - api/v2/config.py
    - nexus-cli
    - nexus_utils/config_loader.py
  generated_at: 2026-05-09T01:18:23+00:00
  generated_by: docs-sync v2
---

# 环境变量

本文档列出 Nexus-AI 所有受支持的环境变量。用途、默认值、数据类型均来自源码（`api/v2/config.py`、`nexus_utils/config_loader.py`），不做任何推测。

## 概述

Nexus-AI 的配置加载遵循固定的**优先级顺序**：

1. **环境变量**（进程启动时读取）
2. **配置文件**（`config/default_config.yaml`、`config/service_config.yaml`）
3. **代码内置默认值**

设置了环境变量就会覆盖 YAML 中的同名项。所有环境变量都是 **字符串**，由加载器按需强转为 `int` / `bool`；布尔类型按 Pydantic 规则解析（`true` / `false` / `1` / `0` 等均可）。

::: tip .env 文件
`api/v2/config.py` 的 `Settings` 基于 Pydantic `BaseSettings`，会读取当前工作目录下的 `.env` 文件（编码 UTF-8，大小写敏感）。`.env` 中的条目等价于进程环境变量，但进程环境变量优先级更高。
:::

::: warning 特殊行为：`AWS_REGION` 被强制回写
尽管 Pydantic 默认会用 `AWS_REGION` 环境变量覆盖字段，`get_settings()` 会在缓存前**强制**将 `AWS_REGION` 与 `AWS_DEFAULT_REGION` 回写为 `default_config.yaml` 中 `aws.aws_region_name` 的值。也就是说，**`AWS_REGION` 环境变量在 API v2 路径中不生效**，请改动 `default_config.yaml`。
:::

## 加载来源对照

| 模块                              | 文件                                | 备注                                   |
| --------------------------------- | ----------------------------------- | -------------------------------------- |
| `ConfigLoader` 及子读取器         | `nexus_utils/config_loader.py`      | YAML 配置 + 环境变量覆盖               |
| API / Worker / Web / MCP / Bridge | `nexus_utils/config_loader.py` 中的 `get_service_config()` | 读取 `config/service_config.yaml`      |
| FastAPI `Settings`                | `api/v2/config.py`                  | Pydantic `BaseSettings`，支持 `.env`   |

---

## API 服务

| 环境变量                          | 类型 | 默认值      | 说明 |
| --------------------------------- | ---- | ----------- | ---- |
| `API_PORT`                        | int  | `8000`      | API 服务监听端口 |
| `NEXUS_API_WORKERS`               | int  | `1`         | API 进程的 worker 数量（uvicorn workers） |
| `NEXUS_THREAD_POOL_SIZE`          | int  | `64`        | API 进程的同步线程池大小，用于阻塞调用卸载 |
| `NEXUS_AGENT_CREATION_TIMEOUT`    | int  | `120`       | 创建 Agent 的超时时间，单位秒 |
| `NEXUS_SSE_HEARTBEAT_INTERVAL`    | int  | `15`        | SSE 流的心跳间隔，单位秒 |
| `NEXUS_MAX_CONCURRENT_STREAMS`    | int  | `0`         | 最大并发 SSE 流数量，`0` 表示不限 |

::: info 绑定主机
API 主机名来自 `service_config.yaml` 的 `api.host`（默认 `0.0.0.0`），当前版本未暴露对应环境变量。
:::

## Worker

| 环境变量                           | 类型 | 默认值 | 说明 |
| ---------------------------------- | ---- | ------ | ---- |
| `NEXUS_WORKER_THREAD_POOL_SIZE`    | int  | `32`   | Worker 进程的线程池大小 |

## Web 前端

| 环境变量    | 类型 | 默认值 | 说明 |
| ----------- | ---- | ------ | ---- |
| `WEB_PORT`  | int  | `3000` | Web 前端监听端口 |

## MCP 服务

| 环境变量         | 类型 | 默认值 | 说明 |
| ---------------- | ---- | ------ | ---- |
| `NEXUS_MCP_PORT` | int  | `9000` | MCP 服务监听端口 |

## Bridge 服务

| 环境变量                     | 类型 | 默认值 | 说明 |
| ---------------------------- | ---- | ------ | ---- |
| `BRIDGE_PORT`                | int  | `8001` | Bridge 服务监听端口 |
| `BRIDGE_COMMAND_TIMEOUT`     | int  | `900`  | Bridge 单次命令执行超时，单位秒 |
| `BRIDGE_CONNECTION_TIMEOUT`  | int  | `1200` | Bridge 连接保持超时，单位秒 |

## Sandbox Controller

| 环境变量                             | 类型 | 默认值     | 说明 |
| ------------------------------------ | ---- | ---------- | ---- |
| `SANDBOX_CONTROLLER_HOST`            | str  | `0.0.0.0`  | Sandbox Controller 绑定地址 |
| `SANDBOX_CONTROLLER_PORT`            | int  | `8002`     | Sandbox Controller 监听端口 |
| `SANDBOX_PATROL_INTERVAL`            | int  | `30`       | 巡检节点状态的间隔，单位秒 |
| `SANDBOX_HEARTBEAT_TIMEOUT`          | int  | `90`       | 节点心跳超时阈值，单位秒 |
| `SANDBOX_SCALE_DOWN_IDLE_MINUTES`    | int  | `10`       | 节点闲置多少分钟后缩容 |
| `SANDBOX_MIN_NODES`                  | int  | `1`        | 集群最小保留节点数 |

---

## AWS 基础

以下变量由 Pydantic `BaseSettings` 读取（`api/v2/config.py`）；若未设置则回落到 `default_config.yaml` 中 `aws.*` 的值。

| 环境变量                  | 类型 | 默认值        | 说明 |
| ------------------------- | ---- | ------------- | ---- |
| `AWS_REGION`              | str  | `us-west-2`   | 在 API v2 中被强制回写为 `aws.aws_region_name`，**实际不生效**。请改 YAML |
| `AWS_DEFAULT_REGION`      | str  | `us-west-2`   | 同上，被强制回写 |
| `AWS_ACCESS_KEY_ID`       | str  | —             | 可选；留空则使用环境 / IAM Role 默认凭证链 |
| `AWS_SECRET_ACCESS_KEY`   | str  | —             | 可选；同上 |

## DynamoDB

表名构造规则：`{table_prefix}{short_name}`。短名支持按表类型通过环境变量覆盖；未列出的表使用 YAML `dynamodb.tables.*`。

| 环境变量                           | 类型 | 默认值      | 说明 |
| ---------------------------------- | ---- | ----------- | ---- |
| `NEXUS_DYNAMODB_TABLE_PREFIX`      | str  | `nexus_`    | 所有 DynamoDB 表名的前缀 |
| `NEXUS_DYNAMODB_PROJECTS_TABLE`    | str  | `projects`  | `projects` 表的短名（最终 `{prefix}projects`） |
| `NEXUS_DYNAMODB_STAGES_TABLE`      | str  | `stages`    | `stages` 表的短名 |
| `NEXUS_DYNAMODB_TASKS_TABLE`       | str  | `tasks`     | `tasks` 表的短名 |
| `DYNAMODB_ENDPOINT_URL`            | str  | —           | 可选；指定 DynamoDB 自定义端点（用于 LocalStack、VPC Endpoint 等） |
| `DYNAMODB_TABLE_PREFIX`            | str  | `nexus_`    | Pydantic `Settings` 中的表前缀字段（与 `NEXUS_DYNAMODB_TABLE_PREFIX` 作用等价，由 API v2 读取） |

## SQS

队列名构造规则：`{queue_prefix}{short_name}`。

| 环境变量                              | 类型 | 默认值                  | 说明 |
| ------------------------------------- | ---- | ----------------------- | ---- |
| `NEXUS_SQS_QUEUE_PREFIX`              | str  | `nexus-`                | 所有 SQS 队列名的前缀 |
| `NEXUS_SQS_BUILD_QUEUE`               | str  | `build-queue`           | 构建队列短名 |
| `NEXUS_SQS_DEPLOY_QUEUE`              | str  | `deploy-queue`          | 部署队列短名 |
| `NEXUS_SQS_NOTIFICATION_QUEUE`        | str  | `notification-queue`    | 通知队列短名 |
| `NEXUS_SQS_BUILD_DLQ`                 | str  | `build-dlq`             | 构建死信队列短名 |
| `NEXUS_SQS_DEPLOY_DLQ`                | str  | `deploy-dlq`            | 部署死信队列短名 |
| `NEXUS_SQS_VISIBILITY_TIMEOUT`        | int  | `3600`                  | 默认消息可见性超时，单位秒 |
| `NEXUS_SQS_BUILD_VISIBILITY_TIMEOUT`  | int  | `3600`                  | 构建队列消息可见性超时，单位秒 |
| `NEXUS_SQS_DEPLOY_VISIBILITY_TIMEOUT` | int  | `600`                   | 部署队列消息可见性超时，单位秒 |
| `NEXUS_SQS_MESSAGE_RETENTION_DAYS`    | int  | `14`                    | 消息保留天数 |
| `NEXUS_SQS_MAX_RETRY_COUNT`           | int  | `3`                     | 最大重试次数（与 DLQ 的 `maxReceiveCount` 一致） |
| `SQS_ENDPOINT_URL`                    | str  | —                       | 可选；SQS 自定义端点（API v2 `Settings` 字段） |
| `SQS_BUILD_QUEUE_NAME`                | str  | `{prefix}build-queue`   | Pydantic `Settings` 字段；整个队列名 |
| `SQS_DEPLOY_QUEUE_NAME`               | str  | `{prefix}deploy-queue`  | Pydantic `Settings` 字段；整个队列名 |
| `SQS_NOTIFICATION_QUEUE_NAME`         | str  | `{prefix}notification-queue` | Pydantic `Settings` 字段；整个队列名 |
| `SQS_BUILD_DLQ_NAME`                  | str  | `{prefix}build-dlq`     | Pydantic `Settings` 字段；整个 DLQ 名 |
| `SQS_DEPLOY_DLQ_NAME`                 | str  | `{prefix}deploy-dlq`    | Pydantic `Settings` 字段；整个 DLQ 名 |
| `BUILD_VISIBILITY_TIMEOUT`            | int  | `3600`                  | Pydantic `Settings` 字段（与 `NEXUS_SQS_BUILD_VISIBILITY_TIMEOUT` 等价） |
| `DEPLOY_VISIBILITY_TIMEOUT`           | int  | `600`                   | Pydantic `Settings` 字段（与 `NEXUS_SQS_DEPLOY_VISIBILITY_TIMEOUT` 等价） |
| `MESSAGE_RETENTION_DAYS`              | int  | `14`                    | Pydantic `Settings` 字段（与 `NEXUS_SQS_MESSAGE_RETENTION_DAYS` 等价） |
| `MAX_RETRY_COUNT`                     | int  | `3`                     | Pydantic `Settings` 字段（与 `NEXUS_SQS_MAX_RETRY_COUNT` 等价） |

::: info 两套变量名并存
`NEXUS_SQS_*` 在 `ConfigLoader.get_sqs_config()` 中生效；`SQS_*_NAME` / `BUILD_VISIBILITY_TIMEOUT` 等在 Pydantic `Settings` 中生效。写部署脚本时建议**两套都设**，以保证两条代码路径一致。
:::

---

## Aurora PostgreSQL

| 环境变量                  | 类型 | 默认值 | 说明 |
| ------------------------- | ---- | ------ | ---- |
| `NEXUS_AURORA_HOST`       | str  | `""`   | Aurora 集群端点（写节点），空字符串表示未配置 |
| `NEXUS_AURORA_PASSWORD`   | str  | `""`   | Aurora 数据库密码（生产建议由 Secrets Manager 注入） |

## ElastiCache Valkey

| 环境变量                 | 类型 | 默认值 | 说明 |
| ------------------------ | ---- | ------ | ---- |
| `NEXUS_VALKEY_ENDPOINT`  | str  | `""`   | Valkey Serverless 端点（`host:port` 形式） |

---

## Workflow 引擎

| 环境变量                            | 类型 | 默认值   | 说明 |
| ----------------------------------- | ---- | -------- | ---- |
| `NEXUS_WORKFLOW_MAX_RETRIES`        | int  | `3`      | 工作流阶段的最大重试次数 |
| `NEXUS_WORKFLOW_STAGE_TIMEOUT`      | int  | `3600`   | 单个阶段超时时间，单位秒 |
| `NEXUS_WORKFLOW_MAX_CONTEXT_TOKENS` | int  | `100000` | 工作流上下文最大 token 数 |

---

## AgentCore 部署

以下变量通过 Pydantic `Settings` 提供；若未设置则回落到 `default_config.yaml` 中 `agentcore.*`。

| 环境变量                              | 类型 | 默认值                              | 说明 |
| ------------------------------------- | ---- | ----------------------------------- | ---- |
| `AGENTCORE_REGION`                    | str  | `us-west-2`                         | AgentCore 部署所在 AWS Region（默认取 `aws.aws_region_name`） |
| `AGENTCORE_DEPLOY_DRY_RUN`            | bool | `false`                             | 为 `true` 时不实际创建资源，仅打印计划 |
| `AGENTCORE_DEFAULT_ALIAS`             | str  | `DEFAULT`                           | Agent 默认别名 |
| `AGENTCORE_EXECUTION_ROLE_NAME`       | str  | —                                   | AgentCore 执行角色 ARN；为空时按 `AGENTCORE_AUTO_CREATE_EXECUTION_ROLE` 决定是否自动创建 |
| `AGENTCORE_AUTO_CREATE_EXECUTION_ROLE`| bool | `true`                              | 若执行角色不存在，是否自动创建 |
| `AGENTCORE_AUTO_CREATE_ECR`           | bool | `true`                              | 是否自动创建 ECR 仓库 |
| `AGENTCORE_POST_DEPLOY_TEST`          | bool | `false`                             | 部署完成后是否自动发一次测试消息 |
| `AGENTCORE_POST_DEPLOY_TEST_PROMPT`   | str  | `Hello`                             | 测试消息内容 |
| `AGENTCORE_AUTO_UPDATE_ON_CONFLICT`   | bool | `true`                              | Agent 已存在时是否自动 update（否则报冲突） |
| `AGENTCORE_REQUIREMENTS_PATH`         | str  | `requirements.txt`                  | AgentCore 构建使用的 requirements 文件路径 |
| `AGENTCORE_IMAGE_TAG_TEMPLATE`        | str  | `{agent_name}:{timestamp}`          | 镜像标签模板 |

---

## 会话存储

| 环境变量                      | 类型 | 默认值      | 说明 |
| ----------------------------- | ---- | ----------- | ---- |
| `SESSION_STORAGE_S3_BUCKET`   | str  | —           | 会话历史归档 S3 桶；未配置时关闭归档 |
| `SESSION_STORAGE_S3_PREFIX`   | str  | `sessions/` | 会话对象的 S3 key 前缀 |

## Conversation Manager

| 环境变量                         | 类型  | 默认值                                                                       | 说明 |
| -------------------------------- | ----- | ---------------------------------------------------------------------------- | ---- |
| `CONVERSATION_MANAGER_ENABLED`   | bool  | `true`                                                                       | 是否启用会话管理器 |
| `CONVERSATION_MANAGER_TYPE`      | str   | `sliding_window`                                                             | 管理器类型，支持 `sliding_window` / `summarizing` |
| `CM_SLIDING_WINDOW_SIZE`         | int   | `40`                                                                         | SlidingWindow 保留消息条数 |
| `CM_SLIDING_TRUNCATE_RESULTS`    | bool  | `true`                                                                       | SlidingWindow 是否截断 tool result |
| `CM_SUMMARY_RATIO`               | float | `0.3`                                                                        | Summarizing 模式：摘要占比 |
| `CM_PRESERVE_RECENT_MESSAGES`    | int   | `10`                                                                         | Summarizing 模式：保留最近消息数 |
| `CM_USE_CUSTOM_AGENT`            | bool  | `true`                                                                       | Summarizing 模式：是否使用自定义摘要 Agent |
| `CM_CUSTOM_AGENT_MODEL_ID`       | str   | `us.anthropic.claude-haiku-4-5-20251001-v1:0`                                | 摘要 Agent 使用的模型 ID |
| `CM_CUSTOM_AGENT_PROMPT_PATH`    | str   | `system_agents_prompts/conversation_summarizer/conversation_summarizer`      | 摘要 Agent 提示词路径 |

---

## 附件

| 环境变量                              | 类型 | 默认值                 | 说明 |
| ------------------------------------- | ---- | ---------------------- | ---- |
| `ATTACHMENT_S3_BUCKET`                | str  | `nexus-ai-attachments` | 附件存储 S3 桶 |
| `ATTACHMENT_PRESIGNED_URL_EXPIRY`     | int  | `3600`                 | 下载预签名 URL 过期时间，单位秒 |
| `ATTACHMENT_UPLOAD_URL_EXPIRY`        | int  | `600`                  | 上传预签名 URL 过期时间，单位秒 |
| `ATTACHMENT_MAX_FILE_SIZE`            | int  | `52428800` (50 MB)     | 单文件最大字节数 |
| `ATTACHMENT_MAX_FILES_PER_MESSAGE`    | int  | `5`                    | 单条消息最多附件数 |

## 模板仓库

| 环境变量                             | 类型 | 默认值                                              | 说明 |
| ------------------------------------ | ---- | --------------------------------------------------- | ---- |
| `TEMPLATE_S3_BUCKET`                 | str  | 回落到 `ATTACHMENT_S3_BUCKET`                       | 模板存储 S3 桶 |
| `TEMPLATE_S3_KEY_PREFIX`             | str  | `templates/`                                        | 模板 S3 key 前缀 |
| `TEMPLATE_EFS_SUBDIR`                | str  | `/templates`                                        | EFS 挂载时模板子目录 |
| `TEMPLATE_LOCAL_CACHE_DIR`           | str  | `""`                                                | 纯本地部署时的模板本机缓存目录 |
| `TEMPLATE_UPLOAD_URL_EXPIRY`         | int  | `600`                                               | 模板上传 URL 过期时间，单位秒 |
| `TEMPLATE_MAX_FILE_SIZE`             | int  | `104857600` (100 MB)                                | 模板单文件最大字节数 |
| `TEMPLATE_ALLOWED_EXTENSIONS`        | list | `[pptx, docx, xlsx, pdf, html, htm, md, txt, png, jpg]` | 允许的扩展名（JSON 数组字符串） |
| `TEMPLATE_PREVIEW_TEXT_MAX_BYTES`    | int  | `102400` (100 KB)                                   | 模板文本预览最大字节数 |
| `TEMPLATE_PREVIEW_WORKERS`           | int  | `4`                                                 | 预览生成并发 worker 数 |
| `TEMPLATE_AI_ENABLED`                | bool | `true`                                              | 是否启用模板 AI 分析 |
| `TEMPLATE_AI_ANALYZE_MODEL`          | str  | `us.anthropic.claude-haiku-4-5-20251001-v1:0`       | 模板 AI 分析模型 ID |
| `TEMPLATE_AI_EMBED_MODEL`            | str  | `amazon.titan-embed-text-v2:0`                      | 模板向量化模型 ID |
| `TEMPLATE_AI_EMBED_DIM`              | int  | `1024`                                              | 模板向量维度 |
| `TEMPLATE_AI_DIFF_MODEL`             | str  | `us.anthropic.claude-haiku-4-5-20251001-v1:0`       | 模板差异分析模型 ID |
| `TEMPLATE_LIBREOFFICE_BIN`           | str  | `libreoffice`                                       | LibreOffice 可执行文件路径 |
| `TEMPLATE_IMAGEMAGICK_BIN`           | str  | `convert`                                           | ImageMagick 可执行文件路径 |
| `TEMPLATE_TRIAL_AGENT_ID`            | str  | `featured_deep_research`                            | 模板"试用"默认 Agent ID |

## Skill（已废弃）

| 环境变量            | 类型 | 默认值                     | 说明 |
| ------------------- | ---- | -------------------------- | ---- |
| `SKILL_S3_BUCKET`   | str  | `nexus-ai-artifacts-2026`  | 已废弃；实际使用 `nexus_ai.artifacts_s3_bucket` |

---

## 可观测性

| 环境变量                        | 类型 | 默认值                    | 说明 |
| ------------------------------- | ---- | ------------------------- | ---- |
| `OTEL_EXPORTER_OTLP_ENDPOINT`   | str  | `http://localhost:4318`   | OpenTelemetry OTLP 导出端点；环境变量优先级高于 `nexus_ai.OTEL_EXPORTER_OTLP_ENDPOINT` 配置 |

## 日志与应用元数据

| 环境变量                    | 类型 | 默认值        | 说明 |
| --------------------------- | ---- | ------------- | ---- |
| `LOG_LEVEL`                 | str  | `INFO`        | 日志级别；可选 `DEBUG` / `INFO` / `WARNING` / `ERROR` / `CRITICAL` |
| `APP_NAME`                  | str  | `Nexus-AI API`| FastAPI 应用名称 |
| `APP_VERSION`               | str  | `0.1.0`       | FastAPI 应用版本号 |
| `DEBUG`                     | bool | `false`       | 是否启用 Debug 模式 |

## CORS

| 环境变量                    | 类型 | 默认值      | 说明 |
| --------------------------- | ---- | ----------- | ---- |
| `CORS_ORIGINS`              | list | `["*"]`     | 允许的跨域源（JSON 数组字符串） |
| `CORS_ALLOW_CREDENTIALS`    | bool | `false`     | 是否允许携带凭证 |

---

## `.env` 文件示例

以下示例覆盖了最常用的部署场景。未列出的项会使用源码默认值。

```bash
# 应用
APP_NAME=Nexus-AI API
APP_VERSION=0.1.0
DEBUG=false
LOG_LEVEL=INFO

# API / Web / MCP / Bridge 端口
API_PORT=8000
WEB_PORT=3000
NEXUS_MCP_PORT=9000
BRIDGE_PORT=8001

# API 并发
NEXUS_API_WORKERS=4
NEXUS_THREAD_POOL_SIZE=64
NEXUS_WORKER_THREAD_POOL_SIZE=32
NEXUS_AGENT_CREATION_TIMEOUT=120
NEXUS_SSE_HEARTBEAT_INTERVAL=15
NEXUS_MAX_CONCURRENT_STREAMS=0

# AWS 凭证（留空则走 IAM Role / 默认 credential chain）
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

## 快速速查表

按首字母排序，方便 ⌘F 查找：

| 名称 | 类别 |
| ---- | ---- |
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
| `APP_NAME` | 应用元数据 |
| `APP_VERSION` | 应用元数据 |
| `ATTACHMENT_MAX_FILES_PER_MESSAGE` | 附件 |
| `ATTACHMENT_MAX_FILE_SIZE` | 附件 |
| `ATTACHMENT_PRESIGNED_URL_EXPIRY` | 附件 |
| `ATTACHMENT_S3_BUCKET` | 附件 |
| `ATTACHMENT_UPLOAD_URL_EXPIRY` | 附件 |
| `AWS_ACCESS_KEY_ID` | AWS |
| `AWS_DEFAULT_REGION` | AWS（强制回写） |
| `AWS_REGION` | AWS（强制回写） |
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
| `DEBUG` | 应用元数据 |
| `DEPLOY_VISIBILITY_TIMEOUT` | SQS |
| `DYNAMODB_ENDPOINT_URL` | DynamoDB |
| `DYNAMODB_TABLE_PREFIX` | DynamoDB |
| `LOG_LEVEL` | 日志 |
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
| `OTEL_EXPORTER_OTLP_ENDPOINT` | 可观测性 |
| `SANDBOX_CONTROLLER_HOST` | Sandbox Controller |
| `SANDBOX_CONTROLLER_PORT` | Sandbox Controller |
| `SANDBOX_HEARTBEAT_TIMEOUT` | Sandbox Controller |
| `SANDBOX_MIN_NODES` | Sandbox Controller |
| `SANDBOX_PATROL_INTERVAL` | Sandbox Controller |
| `SANDBOX_SCALE_DOWN_IDLE_MINUTES` | Sandbox Controller |
| `SESSION_STORAGE_S3_BUCKET` | 会话存储 |
| `SESSION_STORAGE_S3_PREFIX` | 会话存储 |
| `SKILL_S3_BUCKET` | Skill（已废弃） |
| `SQS_BUILD_DLQ_NAME` | SQS |
| `SQS_BUILD_QUEUE_NAME` | SQS |
| `SQS_DEPLOY_DLQ_NAME` | SQS |
| `SQS_DEPLOY_QUEUE_NAME` | SQS |
| `SQS_ENDPOINT_URL` | SQS |
| `SQS_NOTIFICATION_QUEUE_NAME` | SQS |
| `TEMPLATE_AI_ANALYZE_MODEL` | 模板 |
| `TEMPLATE_AI_DIFF_MODEL` | 模板 |
| `TEMPLATE_AI_EMBED_DIM` | 模板 |
| `TEMPLATE_AI_EMBED_MODEL` | 模板 |
| `TEMPLATE_AI_ENABLED` | 模板 |
| `TEMPLATE_ALLOWED_EXTENSIONS` | 模板 |
| `TEMPLATE_EFS_SUBDIR` | 模板 |
| `TEMPLATE_IMAGEMAGICK_BIN` | 模板 |
| `TEMPLATE_LIBREOFFICE_BIN` | 模板 |
| `TEMPLATE_LOCAL_CACHE_DIR` | 模板 |
| `TEMPLATE_MAX_FILE_SIZE` | 模板 |
| `TEMPLATE_PREVIEW_TEXT_MAX_BYTES` | 模板 |
| `TEMPLATE_PREVIEW_WORKERS` | 模板 |
| `TEMPLATE_S3_BUCKET` | 模板 |
| `TEMPLATE_S3_KEY_PREFIX` | 模板 |
| `TEMPLATE_TRIAL_AGENT_ID` | 模板 |
| `TEMPLATE_UPLOAD_URL_EXPIRY` | 模板 |
| `WEB_PORT` | Web |

## 备注

- 当同一语义项在 `NEXUS_*` 与 Pydantic 短名（如 `BUILD_VISIBILITY_TIMEOUT`）之间重复时，两套变量读取路径不同。若只设其中一套，会出现 **`ConfigLoader` 取到新值、API v2 `Settings` 取到默认值**（或反之）的不一致。**生产部署建议两套都设为同一值**。
- 环境变量值一旦被 `ConfigLoader` / `get_settings()` 缓存，就不会在运行时再次读取。修改环境变量需要**重启进程**才能生效。
- 对于敏感凭证（`NEXUS_AURORA_PASSWORD`、`AWS_SECRET_ACCESS_KEY`），请通过 Secrets Manager / Parameter Store / Kubernetes Secret 注入，不要写入 `.env` 文件后提交到仓库。
