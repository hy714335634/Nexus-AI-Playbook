---
title: Logging
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - config/logging_config.yaml
    - nexus_utils/observability/**
  generated_at: 2026-05-08T16:17:05+00:00
  generated_by: docs-sync v2
---

# Logging

## What it is

**Logging** is the subsystem that turns every workflow, agent invocation, tool call, HTTP request, and sensitive action in Nexus-AI into either human-readable text or structured records. One configuration drives three output shapes:

- **Local color text logs** — instantly readable in a terminal; workflows, agents, and tools are laid out with colors and layered separators.
- **Structured JSON logs** — single-line JSON in production, with `trace_id` / `user_id` / `project_id` / `agent_id` already attached; CloudWatch Logs Insights can filter by any field.
- **Audit and security logs** — sensitive actions (logins, RBAC denials, quota changes, agent deletion…) go to dedicated log groups with longer retention. Even if the main pipeline fails, these lines land on CloudWatch through a direct boto3 path.

You **don't modify business code** — tuning a few knobs, plus calling a helper when you need it, is enough.

::: info Logging vs observability
This page is about *how logs are produced and what they look like*. For the broader picture — CloudWatch dashboards, X-Ray tracing, the metric dimension whitelist — see [Observability](./observability).
:::

## When to use it

| Scenario                                                                   | What you reach for                                                         |
| -------------------------------------------------------------------------- | -------------------------------------------------------------------------- |
| Running a workflow locally, want to watch every agent / tool step          | `enhanced_logging.enable_colors: true` (default), read straight off the terminal |
| Tracking down a production request given only a `trace_id`                 | Filter JSON logs by `trace_id` in Logs Insights                            |
| Compliance: "who changed quotas / deleted agents last month?"              | Query the `/&lt;slug&gt;/audit` log group                                        |
| Security review: SSO failures, brute-force attempts                        | Query the `/&lt;slug&gt;/security` log group                                     |
| A scheduled task or Worker that should log with `user_id`                  | Wrap the block in `context_scope(user_id=...)`                             |

## How to use it

### 1. Local debugging: color workflow logs

When `observability.enabled: false` (the default in development), logs use the **local text format**: every line carries a timestamp, agent name, tool name, and layered separators.

Edit `config/logging_config.yaml`:

```yaml
enhanced_logging:
  enable_colors: true                 # color output in the terminal
  log_to_file: true                   # also write to a file
  log_file: "logs/enhanced_workflow.log"
  log_level: "DEBUG"                  # DEBUG / INFO / WARNING / ERROR / CRITICAL
  show_timestamp: true
  show_agent_name: true
  show_tool_details: true             # expand tool inputs / results
  truncate_length:
    input: 300                        # max chars per input
    output: 300
    tool_result: 200

strands_hooks:
  enable_enhanced_logging: true       # wire up Strands hooks to auto-log calls
  log_all_agent_calls: true
  log_all_tool_calls: true
  log_arguments: true
  log_results: true
  sensitive_fields:                   # auto-masked if any arg matches these keys
    - "password"
    - "token"
    - "key"
    - "secret"
```

<!-- SCREENSHOT: terminal-enhanced-logs -->

::: tip When to disable colors
CI and Docker log collectors often show ANSI escape codes as garbage. In that case flip `enable_colors` to `false`, or just switch to the JSON mode described below.
:::

### 2. Production: structured JSON logs

Flip the master switch in `config/default_config.yaml`:

```yaml
observability:
  enabled: true
```

Nexus-AI **automatically** switches the root logger to JSON mode — each record becomes a single-line JSON object with stable field names. Your business code keeps calling `logger.info(...)`:

```python
import logging
logger = logging.getLogger(__name__)

# Plain log
logger.info("project created")

# With extra fields
logger.info("build finished", extra={
    "project_id": pid,
    "template_id": tpl,
    "duration_ms": 1832,
})
```

The output looks like:

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

These fields are **auto-injected** by Nexus-AI — you don't pass them:

| Field                                                        | Source                                          |
| ------------------------------------------------------------ | ----------------------------------------------- |
| `timestamp` / `level` / `service` / `logger` / `message`     | Standard fields                                 |
| `trace_id` / `span_id`                                       | Current active OpenTelemetry span               |
| `user_id` / `project_id` / `agent_id` / `session_id`         | Context (injected by FastAPI middleware / agent hook) |
| `model_id` / `workflow_type` / `stage_name`                  | Same                                            |
| `error.type` / `error.message` / `error.traceback`           | `logger.exception(...)` or uncaught exception   |

### 3. Bind context manually in async tasks and scripts

Paths that **don't go through the HTTP entry point** (scripts, Worker handlers, scheduled jobs) won't automatically carry `user_id` / `project_id`. Wrap the block in `context_scope`:

```python
from nexus_utils.observability.context import context_scope

with context_scope(user_id=uid, project_id=pid, agent_id=aid):
    logger.info("task started")          # now carries all three fields
    run_task()                           # logs inside run_task() do too
```

::: warning session_id is not a metric dimension
`session_id` is too high-cardinality (one per conversation), so it lands in logs and trace spans **but never** in CloudWatch metric dimensions. Filter by `session_id` in Logs Insights instead.
:::

### 4. Audit and security events

Sensitive actions go to **dedicated log groups** with 90-day retention, isolated from application logs. They land even when the OTLP pipeline is down, because the write path is direct boto3:

```python
from nexus_utils.observability.logging import audit_log, security_log

# Audit: who did what to which resource (compliance trail)
audit_log(
    logger,
    action="admin.quota.update",
    resource_type="user",
    resource_id=target_uid,
    old_value=500,
    new_value=1000,
)

# Security: auth failure / permission denied / anomalous IP
security_log(
    logger,
    event="sso.login.failed",
    reason="invalid_signature",
    ip_address=req.client.host,
)
```

`user_id` / `project_id` / `agent_id` / `session_id` are filled in from the current context automatically.

<!-- SCREENSHOT: logs-insights-audit -->

Query in CloudWatch Logs Insights:

```text
SOURCE '/nexus-ai/audit'
| fields @timestamp, user_id, action, resource_type, resource_id, ip_address
| filter action like /quota/
| sort @timestamp desc
| limit 100
```

### 5. Sensitive field filtering

Keys listed in `strands_hooks.sensitive_fields` (default `password` / `token` / `key` / `secret`) are **auto-masked** when printing tool arguments and results — the real value never enters any log sink. Extend the list as needed:

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

Raw tool input / output bodies are stored as a **summary** (`size` + `sha256[:16]`) by default, not in full — that layer is controlled by `observability.capture`; see [Observability](./observability).

## Key parameters / limits

### The switch decides the log shape

| `observability.enabled` | Log shape                    | Sink                                      |
| ----------------------- | ---------------------------- | ----------------------------------------- |
| `false` (default)       | Color text, human-readable   | stdout + `logs/enhanced_workflow.log`     |
| `true`                  | Single-line JSON, stable keys | stdout + OTLP → ADOT → CloudWatch Logs   |

Either way, `user_id` / `project_id` / `agent_id` are injected into every record by `NexusContextFilter` / `NexusJsonFormatter`.

### Log level

Override `log_level` at runtime with an env var:

```bash
NEXUS_LOG_LEVEL=DEBUG python -m api.v2.main
```

Valid values: `DEBUG` / `INFO` (default) / `WARNING` / `ERROR` / `CRITICAL`.

### Truncation

`enhanced_logging.truncate_length` caps how many characters each piece can print in the local color mode — anything longer is truncated:

| Key           | Default | Meaning                           |
| ------------- | ------- | --------------------------------- |
| `input`       | 300     | Tool / agent inputs               |
| `output`      | 300     | Agent response                    |
| `tool_result` | 200     | Tool return value                 |

In JSON mode values are not truncated, but **exception tracebacks** are hard-capped at 4096 characters.

### Log group retention

Once `observability.enabled=true`, `nexus-cli init --observability-only` provisions:

| Log group                       | Retention | Writer                                          |
| ------------------------------- | --------- | ----------------------------------------------- |
| `/&lt;slug&gt;/application/api`       | 30 days   | Anything logged with `service_name=nexus-ai-api`|
| `/&lt;slug&gt;/application/worker`    | 30 days   | Worker                                          |
| `/&lt;slug&gt;/application/bridge`    | 30 days   | Bridge                                          |
| `/&lt;slug&gt;/agent`                 | 30 days   | Sandbox / local agents                          |
| `/&lt;slug&gt;/build`                 | 30 days   | Build pipeline                                  |
| `/&lt;slug&gt;/access`                | 90 days   | API access logs (compliance)                    |
| `/&lt;slug&gt;/audit`                 | 90 days   | `audit_log()` output — compliance grade         |
| `/&lt;slug&gt;/security`              | 90 days   | `security_log()` output — compliance grade      |
| `/&lt;slug&gt;/debug`                 | 3 days    | Throw-away debugging                            |

Routing is keyed on the `service_name` you pass to `configure_logging()` at process startup. Different processes **must** pass different values (`nexus-ai-api` / `nexus-ai-worker` / `nexus-ai-bridge` / `nexus-ai-agent-vm`), otherwise the logs will pile up in one group.

### Reserved JSON keys

Fields you pass via `extra={...}` whose names collide with Python `logging`'s **reserved record attributes** (`args` / `asctime` / `filename` / `funcName` / `levelname` / `message` / `name` / `pathname` / `process` / `thread` …) are dropped by the formatter. Prefix your custom fields (e.g. `nexus_*` or `biz_*`) to stay safe.

## FAQ

**Q1. On startup I see `Logging configured: service=..., env=..., json=..., otlp=...`. What is that?**

A. `configure_logging()` logs a one-line summary of the final configuration — JSON or text, OTLP on or off, service name. It's a quick sanity check; leave it in.

**Q2. JSON mode makes the local terminal unreadable. What now?**

A. Two choices. (1) Keep `observability.enabled: false` locally, and set `NEXUS_ENVIRONMENT=production` plus `enabled: true` only in production. (2) Keep JSON and filter with `jq`:

```bash
python -m api.v2.main 2>&1 | jq -r '"\(.timestamp) [\(.level)] \(.service): \(.message)"'
```

**Q3. My logs don't contain `user_id` / `project_id`.**

A. Only requests that pass the FastAPI entry point (URL contains `/projects/...` / `/agents/...`) get them **auto-injected**. Scripts, Workers, and scheduled tasks need to wrap themselves in `context_scope(user_id=..., project_id=...)`.

**Q4. Sensitive fields are masked, but I'm worried about the hashes.**

A. Values matching `sensitive_fields` are **replaced entirely with `***`** — no hash. What is hashed is the tool input/output summary (`capture.tool_input=hash_only`), which is `sha256[:16]` — it is not reversible. If you don't want even the hash, set `capture.tool_input` and `capture.tool_output` to `none`.

**Q5. Can a failing audit write crash my request?**

A. No. Inside `audit_log()` / `security_log()` the CloudWatch write is wrapped in `try / except` — **any failure is downgraded to a local stdlib log, never re-raised**. A request will never 5xx because the audit log could not be written.

**Q6. I run tests locally with `observability.enabled=false`. Are any log fields missing?**

A. `trace_id` / `span_id` only exist while OTEL instrumentation is active, so they are absent in text mode. `user_id` / `agent_id` are still injected into each text line by `NexusContextFilter`. Tests that assert structured fields should either flip the switch or call `configure_logging(service_name, force_json=True)` explicitly.
