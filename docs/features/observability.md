---
title: 可观测性
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - nexus_utils/observability/**
  generated_at: 2026-05-08T16:04:56+00:00
  generated_by: docs-sync v2
---

# 可观测性

## 这是什么

**可观测性**是 Nexus-AI 把平台里每一次 API 请求、Agent 调用、工具执行、构建流水线、沙箱动作都翻译成**三类信号**——追踪（Traces）、指标（Metrics）、日志（Logs）——并统一送进 AWS CloudWatch 与 X-Ray 的能力。

一个开关打开后，你会立刻得到：

- **8 个开箱即用的 CloudWatch 仪表板**，覆盖 SRE、API、Agent、构建、成本、子 Agent 拓扑、沙箱、安全 8 个视角。
- **自动打通的 X-Ray 分布式追踪**，一次用户请求的全链路（API → Worker → Agent → Bedrock → 子 Agent → 工具）在一张火焰图里可视化。
- **结构化 JSON 日志**，带上 `user_id` / `project_id` / `agent_id` / `trace_id`，Logs Insights 可直接过滤。
- **独立保留的审计与安全日志组**（90 天），符合常见合规要求。

## 使用场景

| 场景                                         | 你会打开的工具                                                       |
| -------------------------------------------- | -------------------------------------------------------------------- |
| 线上 API 500 多，想知道是谁 / 哪个接口先挂   | CloudWatch → `<Prefix>-OpsOverview` 仪表板                           |
| 某个用户反馈「Agent 特别慢」                 | CloudWatch → `<Prefix>-AgentRuntime` + X-Ray Service Map             |
| 排查「构建卡在某个 Stage」                   | `<Prefix>-BuildPipeline` → 底部 Logs Insights 面板                   |
| 合规审计：上个月谁改过配额 / 删过 Agent      | CloudWatch Logs → `/&lt;slug&gt;/audit` 日志组                             |
| 安全事件复盘：爆破登录 / RBAC 拒绝           | CloudWatch Logs → `/&lt;slug&gt;/security` 日志组                          |
| 本地开发想看彩色文本日志而非 JSON            | `observability.enabled: false`                                       |

## 如何使用

### 1. 开启或关闭可观测性

可观测性由一个顶层开关统一控制，默认**关闭**以避免开发机产生 CloudWatch 账单。

编辑 `config/default_config.yaml`：

```yaml
observability:
  enabled: true          # 打开总开关
  prefix: NexusAI        # 所有 CloudWatch 资源名称的前缀
```

详细配置写在 `config/logging_config.yaml`：

```yaml
observability:
  environment: production    # development / staging / production
  otlp_endpoint: http://localhost:4318
  traces:
    enabled: true
    sample_rate: 0.1         # production 默认 10%，dev 默认 100%
    propagator: composite    # W3C + X-Ray + Baggage
  metrics:
    enabled: true
    export_interval_ms: 60000
  capture:
    tool_input: hash_only      # hash_only | redacted_preview | none
    tool_output: hash_only
    system_prompt: false
```

保存后，用 CLI 一键生成 / 刷新 Collector 配置与 CloudWatch 资源：

```bash
nexus-cli init --observability-only
```

这条命令会：

1. 用 `prefix` 推导出 **12 个日志组**与 **8 个仪表板**的名字。
2. 渲染 OTEL Collector 配置模板（替换区域、命名空间、日志组名）。
3. 在 AWS 上创建缺失的日志组（并按合规等级设置保留期）与仪表板。

::: tip 开关关闭会怎样
`enabled: false` 时，Nexus-AI **完全不加载 OTEL SDK**，零依赖、零额外内存开销，本地日志切回彩色文本格式。计费 / 配额仍照常工作——它们走业务数据库，不依赖这套管道。
:::

### 2. 打开 CloudWatch 仪表板

登录 AWS Console → CloudWatch → Dashboards，按前缀过滤。

<!-- SCREENSHOT: cloudwatch-dashboards-list -->

| Dashboard                     | 读者     | 核心内容                                                                |
| ----------------------------- | -------- | ----------------------------------------------------------------------- |
| `<Prefix>-OpsOverview`        | SRE      | API 量 / 错误 / SQS 积压 / Bedrock 限流 / 近 1h 错误 Top-N              |
| `<Prefix>-APIPerformance`     | API 工程 | 请求量、P50/P90/P99、状态码堆叠、>5s 慢请求列表                         |
| `<Prefix>-AgentRuntime`       | AI 工程  | Agent 调用、Token（input/output/cache_read/cache_write）、工具耗时      |
| `<Prefix>-BuildPipeline`      | 构建     | 构建成功率、Stage 耗时、Fork 事件、失败明细                             |
| `<Prefix>-GenAICost`          | 管理员   | 各模型 Token、Bedrock 延迟、限流次数                                    |
| `<Prefix>-SubAgentTopology`   | AI 工程  | 子 Agent 调用链、失败根因                                               |
| `<Prefix>-SandboxRuntime`     | 平台     | 池中 idle/busy/total、provision 冷启动 P50/P90/P99                      |
| `<Prefix>-SecurityAudit`      | 安全     | 登录失败、RBAC 拒绝、敏感操作审计                                       |

每个仪表板顶行是 3–5 个单值 KPI，中间是时序图，底部是 Logs Insights 小部件——点标题「在 Logs Insights 中打开」即可改查询条件。

### 3. 用 X-Ray 追踪一次请求

每个 API 响应头里带有 `traceparent`（W3C）与 `X-Amzn-Trace-Id`（X-Ray）。拿到 trace ID 后：

<!-- SCREENSHOT: xray-trace-map -->

1. 打开 AWS Console → X-Ray → **Traces** → 粘贴 trace ID。
2. **Service Map** 显示各服务（`nexus-ai-api` / `nexus-ai-worker` / `nexus-ai-bridge` / `nexus-ai-agent-vm`）之间的调用边，红色边代表错误。
3. **Timeline** 展开后，能看到每个 span：
   - HTTP 路由、状态码、延迟
   - Bedrock `invoke` / `converse` / `converse_stream` 调用（含 `model_id`、token 数）
   - 每次工具调用（`gen_ai.tool.call`，含工具名与输入哈希）
   - 子 Agent 调用链（`invoke_sub_agent`）
   - DynamoDB / SQS / S3 调用（由 botocore 自动插桩）

::: tip 采样策略
线上默认只采样 10%，但**任何 5xx、`error.type` 非空、或未捕获异常**的 trace 都会被强制完整采样，定位线上故障不怕丢样本。
:::

### 4. 用 Logs Insights 做结构化查询

所有服务日志是标准 JSON，CloudWatch Logs Insights 可以用字段名过滤：

```text
fields @timestamp, level, service, user_id, agent_id, model_id, duration_ms, message
| filter level = "ERROR"
| filter ispresent(tokens_in)
| sort @timestamp desc
| limit 50
```

常用字段速查：

| 字段                                            | 含义                                 |
| ----------------------------------------------- | ------------------------------------ |
| `timestamp` / `level` / `service` / `logger`    | 时间、日志级别、服务、Python logger  |
| `message`                                       | 原始日志文本                         |
| `trace_id` / `span_id`                          | 与 X-Ray 串联                        |
| `user_id` / `project_id` / `agent_id` / `session_id` | 业务维度（自动从上下文注入）    |
| `model_id` / `tokens_in` / `tokens_out`         | LLM 调用详情                         |
| `http.method` / `http.route` / `http.status_code` / `duration_ms` | API 请求        |
| `error.type` / `error.message` / `error.traceback` | 异常详情                          |

### 5. 审计与安全事件查询

敏感操作（账号登录、RBAC 拒绝、配额变更、Agent 删除等）会额外进两个独立日志组，保留 90 天。

<!-- SCREENSHOT: logs-insights-audit -->

```text
SOURCE '/nexus-ai/audit'
| fields @timestamp, user_id, action, resource_type, resource_id, ip_address
| filter action like /quota/
| sort @timestamp desc
| limit 100
```

一条典型审计事件字段：`timestamp` / `category=audit` / `action`（如 `admin.quota.update`）/ `user_id` / `resource_type` / `resource_id` / `ip_address` + 业务自定义字段。

### 6. 让自己的代码打出带业务维度的日志

业务代码里写日志时，`trace_id` / `user_id` / `agent_id` 会**自动**填上（由 FastAPI 中间件与 Agent hook 注入）。只需像平常一样：

```python
logger.info("project created", extra={"project_id": pid, "template_id": tpl})
```

如果是一段独立异步任务，想手动绑定上下文：

```python
from nexus_utils.observability.context import context_scope

with context_scope(user_id=uid, project_id=pid, agent_id=aid):
    # 块内所有 log / metric 都会带上这些字段
    do_work()
```

## 关键参数 / 限制

### Service 命名

不同进程必须传不同的 `service_name`，X-Ray Service Map 才能正确区分：

| `service_name`          | 对应进程                     | 自动写入的日志组路径                 |
| ----------------------- | ---------------------------- | ------------------------------------ |
| `nexus-ai-api`          | API 服务                     | `/&lt;slug&gt;/application/api`            |
| `nexus-ai-worker`       | Worker 服务                  | `/&lt;slug&gt;/application/worker`         |
| `nexus-ai-bridge`       | Bridge 服务                  | `/&lt;slug&gt;/application/bridge`         |
| `nexus-ai-agent-vm`     | 沙箱 VM 内的 agent           | `/&lt;slug&gt;/agent`                      |
| `nexus-ai`              | 其他本地 Agent 进程（默认）  | `/&lt;slug&gt;/application`                |

### 日志组保留策略

| 日志组                        | 保留天数 | 定位                         |
| ----------------------------- | -------- | ---------------------------- |
| `/&lt;slug&gt;/application/*`       | 30 天    | API / Worker / Gateway 等    |
| `/&lt;slug&gt;/agent`               | 30 天    | Agent 执行明细               |
| `/&lt;slug&gt;/build`               | 30 天    | 构建流水线                   |
| `/&lt;slug&gt;/access`              | **90 天**| API 访问日志（合规）         |
| `/&lt;slug&gt;/audit`               | **90 天**| 敏感操作审计（合规）         |
| `/&lt;slug&gt;/security`            | **90 天**| 登录失败 / RBAC 拒绝（合规） |
| `/&lt;slug&gt;/metrics`             | 7 天     | EMF 指标                     |
| `/&lt;slug&gt;/debug`               | 3 天     | 临时调试                     |

### 业务维度白名单

指标维度直接决定 CloudWatch 成本，Nexus-AI 收紧成一份白名单：

| 维度                                           | 说明                         |
| ---------------------------------------------- | ---------------------------- |
| `user_id` / `project_id` / `tenant_id`         | 身份与归属                   |
| `agent_id` / `model_id` / `runtime_type`       | Agent 标识、模型、运行形态   |
| `workflow_type` / `stage_name` / `tool_name`   | 构建与工具维度               |
| `deployment_id`                                | 多部署 / 灰度                |

::: warning session_id 不进指标
`session_id` 基数太大（每次对话一个），只写进 trace span，**不会**作为 CloudWatch 指标维度。按会话查请用 Logs Insights 过滤 `session_id` 字段。
:::

### Trace 采样

| 配置                              | 行为                                                  |
| --------------------------------- | ----------------------------------------------------- |
| `traces.sample_rate >= 1.0`       | 全采样（dev 默认）                                    |
| `traces.sample_rate < 1.0`        | 按比例 + 父级继承 + 「错误强制采样」                  |
| 上游请求头已决定采样              | 子 span 跟随父级决策，不会出现链路断裂                |
| span 启动时属性含 `error.type` / `http.status_code >= 500` / `exception.type` | 无视采样率强制完整保留 |

### 隐私控制

工具输入 / 输出默认只记摘要，不落原文：

| `capture.tool_input` / `tool_output` | 记录内容                                    |
| ------------------------------------ | ------------------------------------------- |
| `hash_only`（默认）                  | `size` + `sha256[:16]`                      |
| `redacted_preview`                   | 上者 + 前 80 字符（先经 PII 脱敏）          |
| `none`                               | 完全不记录                                  |

`capture.system_prompt: false` 时，系统提示词也不会进 span。

### Collector 端（进阶）

Collector 配置模板位于 `config/otel-collector-config.tpl.yaml`，渲染后的最终配置在同目录下 `otel-collector-config.yaml`——文件顶部有 `AUTO-GENERATED` 注释，**不要直接改**，改模板后重跑 `nexus-cli init --observability-only`。

## 常见问题

**Q1：`observability.enabled=false` 之后，业务还跑得动吗？**

A：能。开关关闭时完全不加载 OTEL 依赖，日志切回彩色文本格式。业务数据库里的用量、配额拦截、审计记录仍然正常工作——那条路径用 boto3 直连 CloudWatch Logs，不走 OTLP 管道。

**Q2：我在仪表板上看不到任何数据，先查什么？**

A：按这个顺序：
1. 确认进程启动日志里有 `Observability 已初始化: service=..., endpoint=...`；没有的话要么开关没开，要么 OTLP endpoint 不通。
2. 确认 ADOT Collector 正在运行，且指向的 OTLP HTTP 端口（默认 `4318`）能被业务进程访问。
3. 指标至少需要**一个导出周期**（默认 60s）才会出现在 CloudWatch。
4. 仪表板名字是 `<Prefix>-OpsOverview`；如果把 `prefix` 改成非默认值，去 CloudWatch Dashboards 按前缀搜。

**Q3：Trace 断了一截（中间几层看不到），怎么回事？**

A：几乎都是**传播器不一致**造成的——上游发的是 W3C `traceparent`，下游只配了 `xray` 传播器时会丢掉上下文。保持默认 `propagator: composite` 通常就能自动双向兼容。

**Q4：日志里看不到 `user_id` / `project_id`？**

A：默认只有经过 FastAPI 入口的请求会自动填这两个字段（由 URL 中 `/projects/...` / `/agents/...` 片段解析）。独立脚本、定时任务、Worker handler 里要打带维度的日志，需要自己包一层 `context_scope(user_id=..., project_id=...)`。

**Q5：为什么 Counter 指标在 CloudWatch 上老是 0？**

A：这是 DELTA vs CUMULATIVE 时间性问题，Nexus-AI 已经在 MeterProvider 里为 Counter / Histogram 显式指定 DELTA，所以自己部署的 Collector 必须使用 `awsemfexporter` 期望的格式。如果你自行替换了 Collector 或重写了配置，请保留 `preferred_temporality` 为 DELTA。

**Q6：审计日志和应用日志为什么要分开？**

A：合规。应用日志 30 天就滚动删除，审计 / 安全日志保留 90 天、写入时走独立的 boto3 路径，即使 OTLP 管道整条挂掉也会落盘，满足大多数 SOC2 / ISO27001 审计要求。
