---
title: Data Stores
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - api/v2/database/**
    - config/default_config.yaml
  generated_at: 2026-05-08T22:40:56+00:00
  generated_by: docs-sync v2
---

# Data Stores

## Overview

Nexus-AI's data layer is backed by four storage systems that together hold metadata, relational business data, cache entries, and async task queues:

| Store | Purpose |
| --- | --- |
| **Aurora PostgreSQL Serverless v2** | Relational data for projects, agents, sessions, messages, etc. — supports JOINs, aggregations, and complex queries |
| **DynamoDB** | Key-value lookups, event scheduling, audit logs, and high-write tables such as Tools / Keys |
| **ElastiCache Valkey Serverless** | Cache-Aside layer, distributed locks, Redis Streams, and Pub/Sub |
| **SQS** | Async message queues for build, deploy, and notification tasks |

Aurora and DynamoDB are required; if Valkey is absent, caching and stream-event features degrade gracefully to direct database reads. SQS drives the two long-running pipelines (build and deploy).

## Prerequisites

- Nexus-AI console is deployed and you have administrator access to the target AWS account.
- The target AWS region (default `us-west-2`) has Aurora PostgreSQL, DynamoDB, ElastiCache, and SQS enabled.
- The console host can reach Aurora and Valkey endpoints (VPC peering, PrivateLink endpoints, or public TLS).
- One of the following credential options:
  - EC2 IAM Role (recommended for production) with permissions for DynamoDB and SQS.
  - Static `aws_access_key_id` / `aws_secret_access_key` pair (test environments only).
- The Aurora database exists and the 15 migration tables have been provisioned (`projects`, `stages`, `agents`, `sessions`, `messages`, `attachments`, `skills`, `skill_groups`, `users`, `favorites`, `groups`, etc.).

::: warning
Store Aurora credentials in a secrets manager and inject them via the `NEXUS_AURORA_PASSWORD` and `NEXUS_AURORA_HOST` environment variables — do not keep plaintext passwords in config files.
:::

## Configuration Steps

### Step 1: Configure AWS region and credentials

Edit the `aws` section of `config/default_config.yaml`:

```yaml
aws:
  aws_region_name: us-west-2        # Governs all AWS clients (DynamoDB/SQS/S3/...)
  bedrock_region_name: us-west-2
  aws_profile_name: ''              # Leave empty when running under an EC2 IAM Role
  aws_access_key_id: ''             # Optional for test environments
  aws_secret_access_key: ''
  endpoint_url: ''                  # Set for non-standard endpoints (e.g. LocalStack)
  verify: true
```

::: tip
`aws_region_name` takes precedence over the `AWS_REGION` environment variable. When the console runs on an EC2 IAM Role without `~/.aws/config`, keep `aws_profile_name` empty to avoid `ProfileNotFound: default`.
:::

### Step 2: Configure Aurora PostgreSQL

Edit the `aurora` section:

```yaml
aurora:
  host: 'my-nexus-demo-db.cluster-xxxxxxxx.us-west-2.rds.amazonaws.com'
  port: 5432
  database: nexus
  username: nexus_admin
  password: ''                      # Leave empty to read from NEXUS_AURORA_PASSWORD
  min_connections: 2
  max_connections: 20
  ssl: true
```

Export the secrets before starting the service (recommended):

```bash
export NEXUS_AURORA_HOST="my-nexus-demo-db.cluster-xxxxxxxx.us-west-2.rds.amazonaws.com"
export NEXUS_AURORA_PASSWORD="<your-db-password>"
```

::: info
If `NEXUS_AURORA_HOST` is unset and the `host` field is empty, the console keeps the DynamoDB implementation and does not enable the Aurora proxy layer.
:::

### Step 3: Configure DynamoDB table prefix

Edit the `dynamodb` section to adjust the table prefix and table names:

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

The effective table name is `<table_prefix><table_name>`, e.g. `nexus_tasks`. When deploying multiple environments in the same AWS account, use distinct prefixes (`nexus_prod_`, `nexus_dev_`) to isolate data.

### Step 4: Configure SQS queues

Edit the `sqs` section:

```yaml
sqs:
  queue_prefix: nexus-
  queues:
    build: build-queue              # Effective name: nexus-build-queue
    deploy: deploy-queue
    notification: notification-queue
  dlq:
    build: build-dlq
    deploy: deploy-dlq
  build_visibility_timeout: 3600    # Max visibility per build task (seconds)
  deploy_visibility_timeout: 600
  visibility_timeout: 3600
  message_retention_days: 14
  max_retry_count: 3
```

| Field | Description |
| --- | --- |
| `queue_prefix` | Prefix added to every queue name |
| `build_visibility_timeout` | Visibility timeout for build tasks (seconds); redelivered if not acknowledged in time |
| `max_retry_count` | Max retries before a message is moved to the DLQ |
| `message_retention_days` | Retention period in days (1–14) |

::: warning
`build_visibility_timeout` must exceed the longest time a worker needs to process a single build task, otherwise the message will be redelivered and the task will run twice.
:::

### Step 5: Configure Valkey cache (optional)

Edit the `valkey` section:

```yaml
valkey:
  endpoint: 'nexus-cache.serverless.use1.cache.amazonaws.com'
  port: 6379
  ssl: true
  decode_responses: true
  max_connections: 50
```

Or override via environment variable:

```bash
export NEXUS_VALKEY_ENDPOINT="nexus-cache.serverless.use1.cache.amazonaws.com"
```

When both `endpoint` and `NEXUS_VALKEY_ENDPOINT` are empty, the cache layer is disabled automatically and reads go straight to Aurora/DynamoDB.

### Step 6: Restart services

```bash
systemctl restart nexus-ai-api
systemctl restart nexus-ai-worker
```

## Verification

### 1. Console health check

Log in to the Nexus-AI console and open **System → Health Check**. Confirm that all four entries report `healthy`:

<!-- SCREENSHOT: data-stores-health-check -->

- Aurora PostgreSQL
- DynamoDB
- Valkey cache (or `not configured`)
- SQS

### 2. Aurora connection

The console startup log should include:

```text
Aurora 连接池已初始化 (host=my-nexus-demo-db.cluster-xxxx.us-west-2.rds.amazonaws.com)
Aurora 代理已启用: 12 张迁移表的方法已委托到 PostgresClient
```

If you only see `Aurora host 未配置，保留 DynamoDB 实现`, the host was not injected correctly — re-check the environment variable and YAML override order.

### 3. DynamoDB tables

```bash
aws dynamodb list-tables --region us-west-2 | grep nexus_
```

You should see every table that starts with `nexus_` (e.g. `nexus_tasks`, `nexus_tools`, `nexus_keys`).

### 4. SQS queues

```bash
aws sqs list-queues --region us-west-2 --queue-name-prefix nexus-
```

The output should list `nexus-build-queue`, `nexus-deploy-queue`, `nexus-build-dlq`, and the other queue URLs.

### 5. Valkey connection

The startup log should include:

```text
Valkey 缓存已连接 (endpoint=nexus-cache.serverless.use1.cache.amazonaws.com)
```

Alternatively, create a project and open **System → Cache Monitor** — you should see keys such as `project:dashboard:<id>` being written.

### 6. End-to-end verification

1. Create a test agent in the console and submit a build task.
2. The task must be written to `nexus-build-queue`; the log prints `Sent message to nexus-build-queue: <message-id>`.
3. After the worker processes the task, a new row appears in the Aurora `agents` table (visible on the **Agents** page).
4. When the dashboard refreshes, the response is served from Valkey (latency < 50 ms).

## Troubleshooting

| Issue | Likely cause | Resolution |
| --- | --- | --- |
| Startup log `Aurora host 未配置` | `aurora.host` is empty and `NEXUS_AURORA_HOST` is unset | Set the environment variable or fill in the YAML `host` field |
| `ProfileNotFound: default` | `aws_profile_name: default` under an EC2 IAM Role | Set `aws_profile_name` to an empty string |
| Aurora connection refused / timeout | Security group does not allow 5432, or subnets are not reachable | Check RDS security group and VPC routes; enable PrivateLink for cross-VPC deployments |
| DynamoDB returns `ProvisionedThroughputExceededException` | Table is Provisioned with insufficient capacity | Switch to on-demand capacity or raise RCU/WCU; the client already retries with backoff |
| `Queue <name> does not exist` | Queue was never created, or `queue_prefix` mismatches | Re-run the deploy script to provision the queues and make sure `queue_prefix + name` matches reality |
| SQS messages consumed twice | `build_visibility_timeout` shorter than worker processing time | Raise `build_visibility_timeout`, or call `change_message_visibility` periodically inside the worker |
| Valkey startup log `缓存层禁用` | `endpoint` is empty or unreachable | Populate the endpoint; verify ElastiCache security groups and TLS settings |
| Valkey occasional `Timeout` on streams | Default blocking socket_timeout is 5 s | The console ships a dedicated stream client with 60 s timeout — upgrade to the latest version |
| List API cache never invalidates | Write path did not trigger `invalidate_*` | Review the write path for the matching invalidation call; purge manually from the cache monitor panel if needed |
| Cross-environment data contamination | Multiple environments share the same table or queue prefix | Use distinct `dynamodb.table_prefix` and `sqs.queue_prefix` per environment |

::: tip
All clients are thread-safe singletons and support multi-process deployments. After any configuration change, restart both the API service and the worker so the connection pools pick up the new values.
:::
