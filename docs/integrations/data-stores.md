---
title: 数据存储
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - api/v2/database/**
    - config/default_config.yaml
  generated_at: 2026-05-08T22:40:56+00:00
  generated_by: docs-sync v2
---

# 数据存储

## 概述

Nexus-AI 的数据层由四个存储系统组成，共同支撑元数据、业务关系数据、缓存与异步任务队列：

| 存储 | 用途 |
| --- | --- |
| **Aurora PostgreSQL Serverless v2** | 项目 / Agent / Session / Message 等关系数据，支持 JOIN、聚合与复杂查询 |
| **DynamoDB** | 键值查询、事件调度、审计、Tools / Keys 等高频写入表 |
| **ElastiCache Valkey Serverless** | 缓存层（Cache-Aside）、分布式锁、Redis Streams、Pub/Sub |
| **SQS** | 构建任务、部署任务、通知任务的异步消息队列 |

Aurora 与 DynamoDB 为必需项；Valkey 缺省时缓存与流事件功能自动降级为直查数据库；SQS 用于构建/部署两条长任务流水线。

## 启用前提

- 已完成 Nexus-AI 控制台部署，并具备对目标 AWS 账户的管理员权限。
- 目标 AWS 区域（默认 `us-west-2`）启用了 Aurora PostgreSQL、DynamoDB、ElastiCache、SQS 服务。
- 控制台服务器可出站访问 Aurora 与 Valkey 的端点（VPC 内或通过 Endpoint / 公网 + TLS）。
- 准备好以下凭证或策略（二选一）：
  - EC2 IAM Role（推荐生产环境）——角色需具备 DynamoDB、SQS 操作权限。
  - `aws_access_key_id` / `aws_secret_access_key` 静态密钥对（仅限测试）。
- Aurora 数据库实例已创建，已导入 15 张迁移表的结构（`projects`、`stages`、`agents`、`sessions`、`messages`、`attachments`、`skills`、`skill_groups`、`users`、`favorites`、`groups` 等）。

::: warning
Aurora 凭证应存放在密钥管理服务中，再通过环境变量 `NEXUS_AURORA_PASSWORD`、`NEXUS_AURORA_HOST` 注入，避免写入明文配置文件。
:::

## 配置步骤

### 第 1 步：配置 AWS 区域与凭证

编辑 `config/default_config.yaml` 的 `aws` 段，指定部署区域与访问方式：

```yaml
aws:
  aws_region_name: us-west-2        # 控制所有 AWS 客户端（DynamoDB/SQS/S3/...）
  bedrock_region_name: us-west-2
  aws_profile_name: ''              # EC2 IAM Role 环境保持为空
  aws_access_key_id: ''             # 测试环境可填入
  aws_secret_access_key: ''
  endpoint_url: ''                  # 非标准端点（如 LocalStack）时填入
  verify: true
```

::: tip
`aws_region_name` 的优先级高于 `AWS_REGION` 环境变量；当控制台运行在 EC2 IAM Role 上且 `~/.aws/config` 不存在 `default` profile 时，务必保持 `aws_profile_name` 为空。
:::

### 第 2 步：配置 Aurora PostgreSQL

编辑 `config/default_config.yaml` 的 `aurora` 段：

```yaml
aurora:
  host: 'my-nexus-demo-db.cluster-xxxxxxxx.us-west-2.rds.amazonaws.com'
  port: 5432
  database: nexus
  username: nexus_admin
  password: ''                      # 留空则读取环境变量 NEXUS_AURORA_PASSWORD
  min_connections: 2
  max_connections: 20
  ssl: true
```

启动前导出环境变量（推荐方式）：

```bash
export NEXUS_AURORA_HOST="my-nexus-demo-db.cluster-xxxxxxxx.us-west-2.rds.amazonaws.com"
export NEXUS_AURORA_PASSWORD="<your-db-password>"
```

::: info
当 `NEXUS_AURORA_HOST` 未设置且 `host` 字段为空时，控制台保留 DynamoDB 实现，不会启用 Aurora 代理层。
:::

### 第 3 步：配置 DynamoDB 表前缀

编辑 `dynamodb` 段，调整表前缀与表名映射：

```yaml
dynamodb:
  table_prefix: nexus_
  tables:
    tasks: tasks
    tools: tools
    clarifications: clarifications
    dynamic_configs: dynamic_configs
    event_jobs: event_jobs
    event_tasks: event_tasks
    remote_connections: remote_connections
    connectors: connectors
    keys: keys
    key_usage_logs: key_usage_logs
    directives: directives
    mcp_servers: mcp_servers
    system_configs: system_configs
    backup_shares: backup_shares
    file_shares: file_shares
    bridge_command_rules: bridge_command_rules
    sandbox_instances: sandbox_instances
    sandbox_logs: sandbox_logs
    sandbox_nodes: sandbox_nodes
    session_template_bindings: session_template_bindings
```

最终表名为 `&lt;table_prefix&gt;&lt;table_name&gt;`，例如 `nexus_tasks`。若相同账户部署多套环境，建议使用不同前缀（如 `nexus_prod_`、`nexus_dev_`）隔离。

### 第 4 步：配置 SQS 队列

编辑 `sqs` 段：

```yaml
sqs:
  queue_prefix: nexus-
  queues:
    build: build-queue              # 最终队列名：nexus-build-queue
    deploy: deploy-queue
    notification: notification-queue
  dlq:
    build: build-dlq
    deploy: deploy-dlq
  build_visibility_timeout: 3600    # 单次构建任务最长可见性 1 小时
  deploy_visibility_timeout: 600
  visibility_timeout: 3600
  message_retention_days: 14
  max_retry_count: 3
```

| 字段 | 说明 |
| --- | --- |
| `queue_prefix` | 所有队列名的前缀 |
| `build_visibility_timeout` | 构建任务可见性超时（秒），超时未确认将重新投递 |
| `max_retry_count` | 投递 DLQ 前的最大重试次数 |
| `message_retention_days` | 消息保留天数（1–14） |

::: warning
`build_visibility_timeout` 必须大于 Worker 处理单个构建任务的最长时间，否则会出现重复执行。
:::

### 第 5 步：配置 Valkey 缓存（可选）

编辑 `valkey` 段：

```yaml
valkey:
  endpoint: 'nexus-cache.serverless.use1.cache.amazonaws.com'
  port: 6379
  ssl: true
  decode_responses: true
  max_connections: 50
```

或通过环境变量覆盖：

```bash
export NEXUS_VALKEY_ENDPOINT="nexus-cache.serverless.use1.cache.amazonaws.com"
```

当 `endpoint` 与 `NEXUS_VALKEY_ENDPOINT` 均为空时，缓存层自动禁用，所有读请求直接命中 Aurora/DynamoDB。

### 第 6 步：重启服务

```bash
systemctl restart nexus-ai-api
systemctl restart nexus-ai-worker
```

## 验证

### 1. 控制台健康检查

登录 Nexus-AI 控制台，进入 **系统 → 健康检查**，确认以下四项状态为 `healthy`：

<!-- SCREENSHOT: data-stores-health-check -->

- Aurora PostgreSQL
- DynamoDB
- Valkey 缓存（或显示为"未配置"）
- SQS

### 2. Aurora 连接验证

控制台启动日志中应出现：

```text
Aurora 连接池已初始化 (host=my-nexus-demo-db.cluster-xxxx.us-west-2.rds.amazonaws.com)
Aurora 代理已启用: 12 张迁移表的方法已委托到 PostgresClient
```

若只看到 `Aurora host 未配置，保留 DynamoDB 实现`，说明 host 未正确注入，请检查环境变量与 YAML 配置的覆盖顺序。

### 3. DynamoDB 连接验证

```bash
aws dynamodb list-tables --region us-west-2 | grep nexus_
```

应列出以 `nexus_` 开头的所有表（如 `nexus_tasks`、`nexus_tools`、`nexus_keys`）。

### 4. SQS 队列验证

```bash
aws sqs list-queues --region us-west-2 --queue-name-prefix nexus-
```

应看到 `nexus-build-queue`、`nexus-deploy-queue`、`nexus-build-dlq` 等队列 URL。

### 5. Valkey 连接验证

控制台启动日志中应出现：

```text
Valkey 缓存已连接 (endpoint=nexus-cache.serverless.use1.cache.amazonaws.com)
```

或新建一个项目后，在 **系统 → 缓存监控** 面板中看到 `project:dashboard:&lt;id&gt;` 等 key 被写入。

### 6. 端到端验证

1. 在控制台创建一个测试 Agent，提交一条构建任务。
2. 任务应被写入 `nexus-build-queue`，控制台日志打印 `Sent message to nexus-build-queue: &lt;message-id&gt;`。
3. Worker 消费后，Aurora `agents` 表新增一行记录（可通过 **Agent 列表** 页查看）。
4. 控制台 Dashboard 数据刷新时命中 Valkey（响应时间 < 50 ms）。

## 故障排查

| 问题 | 可能原因 | 解决方法 |
| --- | --- | --- |
| 启动日志 `Aurora host 未配置` | `aurora.host` 为空且未设置 `NEXUS_AURORA_HOST` | 设置环境变量或填写 YAML `host` 字段 |
| `ProfileNotFound: default` | EC2 IAM Role 环境下配置了 `aws_profile_name: default` | 将 `aws_profile_name` 置为空字符串 |
| Aurora 连接拒绝 / 超时 | 安全组未放行 5432 端口、或子网不互通 | 检查 RDS 安全组、VPC 路由；若跨 VPC 部署，启用 PrivateLink |
| DynamoDB 写入返回 `ProvisionedThroughputExceededException` | 表配置为 Provisioned 且容量不足 | 切换为按需容量，或上调 RCU/WCU；客户端已带自动退避重试 |
| `Queue &lt;name&gt; does not exist` | 队列未创建或 `queue_prefix` 不一致 | 通过部署脚本重新建队列，确保 `queue_prefix + name` 与实际一致 |
| SQS 消息被重复消费 | `build_visibility_timeout` 短于 Worker 处理耗时 | 上调 `build_visibility_timeout`，或在 Worker 内定期 `change_message_visibility` 续租 |
| Valkey 启动日志 `缓存层禁用` | `endpoint` 为空或网络不通 | 填入 endpoint；检查 ElastiCache 安全组、TLS 设置 |
| Valkey 连接偶发 `Timeout` | 流事件长轮询默认 socket_timeout 5s | 控制台已内置独立的 stream_client（60s 超时），升级到最新版本即可 |
| 列表接口缓存未失效 | 写操作未触发 `invalidate_*` | 检查写路径是否调用了对应缓存失效方法；必要时通过 **缓存监控** 面板手动清除 |
| 跨环境数据污染 | 多套环境共用表前缀或队列前缀 | 为不同环境设置不同的 `dynamodb.table_prefix` 与 `sqs.queue_prefix` |

::: tip
所有客户端均为线程安全单例，支持多进程部署。修改配置后必须重启 API 服务与 Worker，连接池才会使用新配置。
:::
