---
title: 日志
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - config/logging_config.yaml
    - nexus_utils/observability/**
  generated_at: 2026-05-08T16:17:05+00:00
  generated_by: docs-sync v2
---

# 日志

## 这是什么

**日志**是 Nexus-AI 把每一次工作流、Agent 调用、工具执行、HTTP 请求、敏感操作写成文字或结构化记录的子系统。同一套配置同时提供三种形态：

- **本地彩色文本日志** — 开发机终端一眼能读，工作流 / Agent / 工具按颜色和分隔线分层显示。
- **结构化 JSON 日志** — 生产环境单行 JSON，自动带 `trace_id` / `user_id` / `project_id` / `agent_id`，CloudWatch Logs Insights 可按字段过滤。
- **审计与安全日志** — 敏感操作（登录、RBAC 拒绝、配额变更、Agent 删除等）写进独立日志组，保留更久；即使主日志管道挂掉也会通过 boto3 直连落盘。

你**不需要改业务代码**，只需要调几个参数，并在需要的地方调一个函数，就能用上这三种形态。

::: info 日志 vs 可观测性
这一页讲「日志怎么产生、长什么样」。关于 CloudWatch 仪表板、X-Ray 追踪、指标维度白名单等更宏观的话题，见 [可观测性](./observability)。
:::

## 使用场景

| 场景                                                         | 你会用到什么                                                         |
| ------------------------------------------------------------ | -------------------------------------------------------------------- |
| 本地跑工作流，想看清楚每个 Agent、每次工具调用在做什么       | `enhanced_logging.enable_colors: true`（默认），终端直接读           |
| 线上排查某次请求，只有一个 `trace_id`                        | Logs Insights 按 `trace_id` 过滤 JSON 日志                           |
| 合规审计：上月谁改过配额、删过 Agent                         | 查 `/&lt;slug&gt;/audit` 日志组                                            |
| 安全复盘：SSO 登录失败、暴力破解                             | 查 `/&lt;slug&gt;/security` 日志组                                         |
| 在定时任务或 Worker 里打带 `user_id` 的日志                  | 用 `context_scope(user_id=...)` 包一层                               |

## 如何使用

### 1. 本地调试：彩色工作流日志

`observability.enabled: false`（开发环境默认）时，日志走**本地文本格式**：每条记录带时间戳、Agent 名、工具名、分层分隔线。

编辑 `config/logging_config.yaml`：

```yaml
enhanced_logging:
  enable_colors: true                 # 终端彩色输出
  log_to_file: true                   # 同时写文件
  log_file: "logs/enhanced_workflow.log"
  log_level: "DEBUG"                  # DEBUG / INFO / WARNING / ERROR / CRITICAL
  show_timestamp: true
  show_agent_name: true
  show_tool_details: true             # 展开工具入参 / 结果
  truncate_length:
    input: 300                        # 每条入参最多保留字符数
    output: 300
    tool_result: 200

strands_hooks:
  enable_enhanced_logging: true       # 挂 Strands 钩子，自动记录调用
  log_all_agent_calls: true
  log_all_tool_calls: true
  log_arguments: true
  log_results: true
  sensitive_fields:                   # 命中这些字段时自动掩码
    - "password"
    - "token"
    - "key"
    - "secret"
```

<!-- SCREENSHOT: terminal-enhanced-logs -->

::: tip 什么时候关彩色
CI / Docker 的日志采集管道常把 ANSI 转义字符留成乱码。这种场景把 `enable_colors` 置为 `false`，或者干脆打开下一节的 JSON 模式。
:::

### 2. 生产环境：结构化 JSON 日志

在 `config/default_config.yaml` 把总开关打开：

```yaml
observability:
  enabled: true
```

Nexus-AI 会**自动**把根 logger 切到 JSON 模式——每条日志变成单行 JSON，字段名稳定。业务代码里照常 `logger.info(...)` 就行：

```python
import logging
logger = logging.getLogger(__name__)

# 普通日志
logger.info("project created")

# 带额外字段
logger.info("build finished", extra={
    "project_id": pid,
    "template_id": tpl,
    "duration_ms": 1832,
})
```

输出类似：

```json
{
  "timestamp": "2026-05-08T16:17:05.421Z",
  "level": "INFO",
  "service": "nexus-ai-api",
  "logger": "api.v2.builds",
  "message": "build finished",
  "trace_id": "1-6842abc3-...",
  "span_id": "5f2d...",
  "user_id": "u_abc",
  "project_id": "p_123",
  "agent_id": "a_456",
  "template_id": "tpl_web",
  "duration_ms": 1832
}
```

以下字段由 Nexus-AI **自动注入**，你不用手动传：

| 字段                                                        | 来源                                           |
| ----------------------------------------------------------- | ---------------------------------------------- |
| `timestamp` / `level` / `service` / `logger` / `message`    | 标准字段                                       |
| `trace_id` / `span_id`                                      | OpenTelemetry 当前活动 span                    |
| `user_id` / `project_id` / `agent_id` / `session_id`        | 上下文（FastAPI 中间件 / Agent hook 注入）     |
| `model_id` / `workflow_type` / `stage_name`                 | 同上                                           |
| `error.type` / `error.message` / `error.traceback`          | `logger.exception(...)` 或未捕获异常           |

### 3. 给异步任务 / 脚本手动绑定上下文

**没过 HTTP 入口**的路径（脚本、Worker handler、定时任务）不会自动带 `user_id` / `project_id`。用 `context_scope` 包一层：

```python
from nexus_utils.observability.context import context_scope

with context_scope(user_id=uid, project_id=pid, agent_id=aid):
    logger.info("task started")          # 自动带上三个字段
    run_task()                           # 块内打的日志也都会带上
```

::: warning session_id 不进指标
`session_id` 基数太大（每次对话一个），只会写进日志与 trace span，**不会**出现在 CloudWatch 指标维度上。按会话筛日志请在 Logs Insights 里过滤 `session_id` 字段。
:::

### 4. 审计与安全事件

敏感操作写进**独立日志组**，保留 90 天、与应用日志隔离。即使 OTLP 管道整条挂掉，这条路径也会通过 boto3 直连 CloudWatch 落盘。业务代码这样调：

```python
from nexus_utils.observability.logging import audit_log, security_log

# 审计：谁在什么时候对哪个资源做了什么（合规追踪）
audit_log(
    logger,
    action="admin.quota.update",
    resource_type="user",
    resource_id=target_uid,
    old_value=500,
    new_value=1000,
)

# 安全：认证失败 / 权限拒绝 / 异常 IP
security_log(
    logger,
    event="sso.login.failed",
    reason="invalid_signature",
    ip_address=req.client.host,
)
```

写入时 `user_id` / `project_id` / `agent_id` / `session_id` 会从当前上下文自动补全。

<!-- SCREENSHOT: logs-insights-audit -->

在 CloudWatch Logs Insights 里查：

```text
SOURCE '/nexus-ai/audit'
| fields @timestamp, user_id, action, resource_type, resource_id, ip_address
| filter action like /quota/
| sort @timestamp desc
| limit 100
```

### 5. 敏感字段过滤

`strands_hooks.sensitive_fields` 列出的键名（默认 `password` / `token` / `key` / `secret`）会在打印工具入参与结果时被**自动掩码**，不会进任何日志载体。需要扩展就追加：

```yaml
strands_hooks:
  sensitive_fields:
    - "password"
    - "token"
    - "key"
    - "secret"
    - "authorization"
    - "cookie"
```

工具输入 / 输出的原文默认只记**摘要**（`size` + `sha256[:16]`），不落原文——这一层在 `observability.capture` 里配，详见 [可观测性](./observability)。

## 关键参数 / 限制

### 开关决定日志形态

| `observability.enabled` | 日志形态                  | 去向                                    |
| ----------------------- | ------------------------- | --------------------------------------- |
| `false`（默认）         | 彩色文本，单行可读         | stdout + `logs/enhanced_workflow.log`   |
| `true`                  | 单行 JSON，字段稳定        | stdout + OTLP → ADOT → CloudWatch Logs  |

无论哪种形态，`user_id` / `project_id` / `agent_id` 都会通过 `NexusContextFilter` / `NexusJsonFormatter` 自动注入到每条日志上。

### 日志级别

运行时通过环境变量覆盖 `log_level`：

```bash
NEXUS_LOG_LEVEL=DEBUG python -m api.v2.main
```

可选值：`DEBUG` / `INFO`（默认）/ `WARNING` / `ERROR` / `CRITICAL`。

### 截断长度

`enhanced_logging.truncate_length` 控制本地彩色模式下单条内容最长输出多少字符——超过即截断：

| 键            | 默认 | 含义                 |
| ------------- | ---- | -------------------- |
| `input`       | 300  | 工具 / Agent 入参    |
| `output`      | 300  | Agent 回复           |
| `tool_result` | 200  | 工具返回值           |

JSON 模式下字段值不强制截断，但**异常 traceback** 硬上限 4096 字符。

### 日志组保留策略

`observability.enabled=true` 之后，`nexus-cli init --observability-only` 会按以下策略创建：

| 日志组                          | 保留   | 写入者                                        |
| ------------------------------- | ------ | --------------------------------------------- |
| `/&lt;slug&gt;/application/api`       | 30 天  | `service_name=nexus-ai-api` 的所有日志        |
| `/&lt;slug&gt;/application/worker`    | 30 天  | Worker                                        |
| `/&lt;slug&gt;/application/bridge`    | 30 天  | Bridge                                        |
| `/&lt;slug&gt;/agent`                 | 30 天  | 沙箱 / 本地 Agent                             |
| `/&lt;slug&gt;/build`                 | 30 天  | 构建流水线                                    |
| `/&lt;slug&gt;/access`                | 90 天  | API 访问日志（合规）                          |
| `/&lt;slug&gt;/audit`                 | 90 天  | `audit_log()` 写入，合规必备                  |
| `/&lt;slug&gt;/security`              | 90 天  | `security_log()` 写入，合规必备               |
| `/&lt;slug&gt;/debug`                 | 3 天   | 临时调试                                      |

日志组按进程启动时传给 `configure_logging()` 的 `service_name` 路由，不同进程必须传不同值（`nexus-ai-api` / `nexus-ai-worker` / `nexus-ai-bridge` / `nexus-ai-agent-vm`），否则在 CloudWatch 里会混在一起。

### JSON 字段命名保留

通过 `extra={...}` 传入的字段名如果命中 Python `logging` 的**保留属性**（`args` / `asctime` / `filename` / `funcName` / `levelname` / `message` / `name` / `pathname` / `process` / `thread` 等），会被 formatter 忽略。建议自定义字段统一加业务前缀，例如 `nexus_*` 或 `biz_*`。

## 常见问题

**Q1：本地启动时打印 `Logging configured: service=..., env=..., json=..., otlp=...`，这行是什么？**

A：Nexus-AI 在 `configure_logging()` 结束时会主动打一行「当前日志配置摘要」：是 JSON 还是文本？是否挂了 OTLP 导出？服务名是什么？只有一行，排查问题时很有用，不用去掉。

**Q2：切到 JSON 模式后，本地终端刷屏完全没法读怎么办？**

A：两条路。① 本地 `observability.enabled` 保持 `false`，部署时设环境变量 `NEXUS_ENVIRONMENT=production` 并把 YAML 改成 `true`。② 坚持用 JSON，本地用 `jq` 过滤：

```bash
python -m api.v2.main 2>&1 | jq -r '"\(.timestamp) [\(.level)] \(.service): \(.message)"'
```

**Q3：日志里看不到 `user_id` / `project_id`？**

A：只有经过 FastAPI 入口的请求（URL 含 `/projects/...` / `/agents/...`）才会**自动**注入。脚本、Worker、定时任务要自己用 `context_scope(user_id=..., project_id=...)` 包一下。

**Q4：敏感字段被掩码了，但 hash 还是有顾虑？**

A：`sensitive_fields` 命中的参数会被**整个替换成 `***`**，不做 hash。真正走 hash 的是工具 input/output 摘要（`capture.tool_input=hash_only`），那是 `sha256[:16]`，不可反推原文。如果连 hash 都不想出现，把 `capture.tool_input` 和 `capture.tool_output` 改成 `none`。

**Q5：审计日志失败会拖垮业务吗？**

A：不会。`audit_log()` / `security_log()` 内部的 CloudWatch 写入被 `try / except` 完整包住，**任何异常都只降级到本地 stdlib logger，不会外抛**。业务请求不会因为审计日志写失败而 5xx。

**Q6：本地跑测试时 `observability.enabled=false`，日志会丢字段吗？**

A：`trace_id` / `span_id` 需要 OTEL 插桩才存在，文本模式下不会出现；但 `user_id` / `agent_id` 仍然通过 `NexusContextFilter` 注入到文本行前缀。需要断言结构化字段的测试，临时开总开关，或在用例里显式调 `configure_logging(service_name, force_json=True)`。
