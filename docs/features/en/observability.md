---
title: Observability
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - nexus_utils/observability/**
  generated_at: 2026-05-08T16:04:56+00:00
  generated_by: docs-sync v2
---

# Observability

## What it is

**Observability** is how Nexus-AI turns every API request, agent invocation, tool call, build-pipeline stage, and sandbox action into **three signals** — traces, metrics, and logs — and ships them to AWS CloudWatch and X-Ray through a single unified pipeline.

Flip one switch and you immediately get:

- **Eight out-of-the-box CloudWatch dashboards** covering SRE, API, agent runtime, build, cost, sub-agent topology, sandbox, and security views.
- **Fully stitched X-Ray distributed tracing**, so a single user request (API → Worker → Agent → Bedrock → sub-agents → tools) shows up in one flamegraph.
- **Structured JSON logs** carrying `user_id` / `project_id` / `agent_id` / `trace_id`, queryable in Logs Insights by field.
- **Separately retained audit and security log groups** (90 days) aligned with common compliance checklists.

## When to use it

| Scenario                                                            | What to open                                                         |
| ------------------------------------------------------------------- | -------------------------------------------------------------------- |
| 5xx spike in production — who / which endpoint failed first?        | CloudWatch → `<Prefix>-OpsOverview` dashboard                        |
| A user reports "the agent feels slow"                               | CloudWatch → `<Prefix>-AgentRuntime` + X-Ray Service Map             |
| Build is stuck on some stage                                        | `<Prefix>-BuildPipeline` → Logs Insights panel at the bottom         |
| Audit: who changed a quota / deleted an agent last month?           | CloudWatch Logs → `/&lt;slug&gt;/audit` log group                          |
| Security post-mortem: brute-force logins, RBAC denials              | CloudWatch Logs → `/&lt;slug&gt;/security` log group                       |
| Local dev — I want colourful text logs, not JSON                    | `observability.enabled: false`                                       |

## How to use it

### 1. Turn observability on or off

Observability is governed by one top-level switch. It ships **off** to avoid charging dev machines against your CloudWatch bill.

Edit `config/default_config.yaml`:

```yaml
observability:
  enabled: true          # master switch
  prefix: NexusAI        # prefix for every CloudWatch resource name
```

Details live in `config/logging_config.yaml`:

```yaml
observability:
  environment: production    # development / staging / production
  otlp_endpoint: http://localhost:4318
  traces:
    enabled: true
    sample_rate: 0.1         # 10% in production, 100% elsewhere
    propagator: composite    # W3C + X-Ray + Baggage
  metrics:
    enabled: true
    export_interval_ms: 60000
  capture:
    tool_input: hash_only      # hash_only | redacted_preview | none
    tool_output: hash_only
    system_prompt: false
```

Save, then render the Collector config and provision CloudWatch resources with one CLI command:

```bash
nexus-cli init --observability-only
```

That command will:

1. Derive the **12 log groups** and **8 dashboards** from your `prefix`.
2. Render the OTEL Collector template (substituting region, namespace, and log-group names).
3. Create any missing log groups in AWS with their compliance-tier retention, and create/update all dashboards.

::: tip What happens when the switch is off?
With `enabled: false`, Nexus-AI **does not load the OTEL SDK at all** — zero extra dependencies, zero memory overhead, and local logs fall back to coloured text. Billing and quota enforcement keep working because they run on the business database, not on this pipeline.
:::

### 2. Open the CloudWatch dashboards

AWS Console → CloudWatch → Dashboards, then filter by your prefix.

<!-- SCREENSHOT: cloudwatch-dashboards-list -->

| Dashboard                     | Audience  | Core content                                                            |
| ----------------------------- | --------- | ----------------------------------------------------------------------- |
| `<Prefix>-OpsOverview`        | SRE       | API volume / errors / SQS backlog / Bedrock throttles / last-hour top errors |
| `<Prefix>-APIPerformance`     | API eng   | Requests, P50/P90/P99, status-code stacks, `>5s` slow-request table     |
| `<Prefix>-AgentRuntime`       | AI eng    | Invocations, tokens (input / output / cache_read / cache_write), tool latency |
| `<Prefix>-BuildPipeline`      | Build     | Build success rate, stage duration, fork events, failure list           |
| `<Prefix>-GenAICost`          | Admin     | Tokens per model, Bedrock latency, throttle count                       |
| `<Prefix>-SubAgentTopology`   | AI eng    | Sub-agent invocation chain, failure causes                              |
| `<Prefix>-SandboxRuntime`     | Platform  | Pool idle/busy/total, provision cold-start P50/P90/P99                  |
| `<Prefix>-SecurityAudit`      | Security  | Auth failures, RBAC denials, sensitive-operation audit trail            |

Each dashboard starts with 3–5 single-value KPIs at the top, time-series charts in the middle, and Logs Insights widgets at the bottom — click the "Open in Logs Insights" link on any widget title to tweak the query.

### 3. Follow a request through X-Ray

Every API response carries a `traceparent` header (W3C) and `X-Amzn-Trace-Id` (X-Ray). Grab the trace ID, then:

<!-- SCREENSHOT: xray-trace-map -->

1. AWS Console → X-Ray → **Traces** → paste the trace ID.
2. The **Service Map** shows edges between services (`nexus-ai-api` / `nexus-ai-worker` / `nexus-ai-bridge` / `nexus-ai-agent-vm`); red edges mean errors.
3. Expand the **Timeline** and you see each span:
   - HTTP route, status code, latency
   - Bedrock `invoke` / `converse` / `converse_stream` calls (with `model_id` and token counts)
   - Every tool call (`gen_ai.tool.call`, with tool name and input hash)
   - Sub-agent invocation chain (`invoke_sub_agent`)
   - DynamoDB / SQS / S3 calls (auto-instrumented via botocore)

::: tip Sampling policy
Production samples 10% by default, but **any 5xx, a non-empty `error.type`, or an uncaught exception** force-samples the trace in full. Error traces are never thrown away.
:::

### 4. Query with Logs Insights

Service logs are standard JSON; Logs Insights filters by field name directly:

```text
fields @timestamp, level, service, user_id, agent_id, model_id, duration_ms, message
| filter level = "ERROR"
| filter ispresent(tokens_in)
| sort @timestamp desc
| limit 50
```

Common fields at a glance:

| Field                                                          | Meaning                                  |
| -------------------------------------------------------------- | ---------------------------------------- |
| `timestamp` / `level` / `service` / `logger`                   | Time, log level, service, Python logger  |
| `message`                                                      | Raw log text                             |
| `trace_id` / `span_id`                                         | Cross-links to X-Ray                     |
| `user_id` / `project_id` / `agent_id` / `session_id`           | Business dimensions (auto-injected)      |
| `model_id` / `tokens_in` / `tokens_out`                        | LLM call details                         |
| `http.method` / `http.route` / `http.status_code` / `duration_ms` | API request                        |
| `error.type` / `error.message` / `error.traceback`             | Exception details                        |

### 5. Query audit and security events

Sensitive operations (logins, RBAC denials, quota updates, agent deletions, …) are additionally written to two standalone log groups with 90-day retention.

<!-- SCREENSHOT: logs-insights-audit -->

```text
SOURCE '/nexus-ai/audit'
| fields @timestamp, user_id, action, resource_type, resource_id, ip_address
| filter action like /quota/
| sort @timestamp desc
| limit 100
```

A typical audit event carries: `timestamp` / `category=audit` / `action` (e.g. `admin.quota.update`) / `user_id` / `resource_type` / `resource_id` / `ip_address` plus any extra fields the caller passed.

### 6. Get business dimensions into your own logs

In request-handling code you just log normally — `trace_id` / `user_id` / `agent_id` are populated automatically (FastAPI middleware and agent hooks push them onto a contextvar):

```python
logger.info("project created", extra={"project_id": pid, "template_id": tpl})
```

For a standalone async task, bind the context explicitly:

```python
from nexus_utils.observability.context import context_scope

with context_scope(user_id=uid, project_id=pid, agent_id=aid):
    # every log / metric inside this block carries these fields
    do_work()
```

## Key parameters / limits

### Service name per process

Each process must pass a distinct `service_name` so the X-Ray Service Map can separate them cleanly:

| `service_name`          | Process                              | Log group written into               |
| ----------------------- | ------------------------------------ | ------------------------------------ |
| `nexus-ai-api`          | API service                          | `/&lt;slug&gt;/application/api`            |
| `nexus-ai-worker`       | Worker service                       | `/&lt;slug&gt;/application/worker`         |
| `nexus-ai-bridge`       | Bridge service                       | `/&lt;slug&gt;/application/bridge`         |
| `nexus-ai-agent-vm`     | Agent running inside a sandbox VM    | `/&lt;slug&gt;/agent`                      |
| `nexus-ai`              | Other local agent processes (default)| `/&lt;slug&gt;/application`                |

### Log-group retention

| Log group                     | Retention | Purpose                           |
| ----------------------------- | --------- | --------------------------------- |
| `/&lt;slug&gt;/application/*`       | 30 days   | API / Worker / Gateway / …        |
| `/&lt;slug&gt;/agent`               | 30 days   | Agent execution details           |
| `/&lt;slug&gt;/build`               | 30 days   | Build pipeline                    |
| `/&lt;slug&gt;/access`              | **90 days** | API access logs (compliance)    |
| `/&lt;slug&gt;/audit`               | **90 days** | Sensitive-operation audit       |
| `/&lt;slug&gt;/security`            | **90 days** | Auth failures / RBAC denials    |
| `/&lt;slug&gt;/metrics`             | 7 days    | EMF metric stream                 |
| `/&lt;slug&gt;/debug`               | 3 days    | Ad-hoc debugging                  |

### Allow-listed metric dimensions

Dimensions directly drive CloudWatch cost, so Nexus-AI ships a tight allow-list:

| Dimension                                       | Use                                      |
| ----------------------------------------------- | ---------------------------------------- |
| `user_id` / `project_id` / `tenant_id`          | Identity and ownership                   |
| `agent_id` / `model_id` / `runtime_type`        | Agent, model, runtime type               |
| `workflow_type` / `stage_name` / `tool_name`    | Build and tool dimensions                |
| `deployment_id`                                 | Multi-deployment / canary                |

::: warning session_id never goes on metrics
`session_id` has huge cardinality (one per conversation). It lives only on trace spans, **never** on CloudWatch metric dimensions. Slice per session in Logs Insights by filtering the `session_id` field instead.
:::

### Trace sampling

| Configuration                              | Behaviour                                             |
| ------------------------------------------ | ----------------------------------------------------- |
| `traces.sample_rate >= 1.0`                | Sample every trace (dev default)                      |
| `traces.sample_rate < 1.0`                 | Rate + parent-based + "error-aware force-sample"      |
| Upstream already sampled                   | Child spans inherit the decision; no broken chains    |
| Start attributes contain `error.type` / `http.status_code >= 500` / `exception.type` | Full sample regardless of rate |

### Privacy controls

Tool inputs / outputs only capture summaries, never raw text:

| `capture.tool_input` / `tool_output` | What gets recorded                                 |
| ------------------------------------ | -------------------------------------------------- |
| `hash_only` (default)                | `size` + `sha256[:16]`                             |
| `redacted_preview`                   | The above + first 80 characters (after PII scrub)  |
| `none`                               | Nothing                                            |

With `capture.system_prompt: false`, system prompts also stay off spans.

### Collector (advanced)

The Collector template sits at `config/otel-collector-config.tpl.yaml`; the rendered output lands next to it as `otel-collector-config.yaml`. The rendered file carries an `AUTO-GENERATED` banner at the top — **do not edit it directly**. Change the template and re-run `nexus-cli init --observability-only`.

## FAQ

**Q1: With `observability.enabled=false`, does the service still run?**

A: Yes. When the switch is off no OTEL dependencies load at all and logs fall back to coloured text. Usage accounting, quota enforcement, and audit-log writes keep working — they use a direct boto3 path to CloudWatch Logs and do not rely on the OTLP pipeline.

**Q2: Dashboards are empty — what do I check first?**

A: In this order:
1. Confirm the service start-up log contains `Observability 已初始化: service=..., endpoint=...`. If it's missing the switch is off, or the OTLP endpoint is unreachable.
2. Confirm the ADOT Collector is running and the OTLP HTTP port (default `4318`) is reachable from the service.
3. Metrics need at least **one export cycle** (60 s default) before they appear in CloudWatch.
4. Dashboards are named `<Prefix>-OpsOverview`. If you changed `prefix`, filter CloudWatch Dashboards by that value.

**Q3: A trace is missing a middle segment — what happened?**

A: Nearly always a propagator mismatch. The upstream sends a W3C `traceparent` but the downstream only registered the `xray` propagator, so the context is dropped. Keep the default `propagator: composite` and both header formats propagate in and out.

**Q4: `user_id` / `project_id` don't show up in my logs.**

A: By default only requests passing through FastAPI auto-populate them (URL segments like `/projects/...` / `/agents/...` are parsed into the metric context). Standalone scripts, scheduled tasks, and Worker handlers that want those fields need to wrap the work in `context_scope(user_id=..., project_id=...)`.

**Q5: Counters always read as 0 in CloudWatch — why?**

A: That's the classic DELTA vs CUMULATIVE temporality mismatch. Nexus-AI configures the MeterProvider to emit Counter and Histogram as DELTA (which `awsemfexporter` expects). If you ship your own Collector or rewrite the config, preserve the `preferred_temporality` setting on Counter/Histogram; otherwise CloudWatch only sees `cumulative.t1 − cumulative.t0 = 0` between exports.

**Q6: Why are audit/security logs split out?**

A: Compliance. Application logs roll off after 30 days; audit and security logs retain for 90 days and are written through a separate boto3 path, so they still land even if the OTLP pipeline is down. That's enough to satisfy most SOC 2 / ISO 27001 audits.
