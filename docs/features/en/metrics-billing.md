---
title: Metrics & Billing
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - api/v2/routers/admin_billing.py
    - nexus_utils/observability/**
  generated_at: 2026-05-08T16:10:40+00:00
  generated_by: docs-sync v2
---

# Metrics & Billing

## What this is

**Metrics & Billing** is Nexus-AI's cost and usage control center for **enterprise administrators**. It rolls up every LLM call, agent run, and build job into a cost breakdown split by user, project, and model — so you can answer two questions:

1. Who spent the most this month, and on which model?
2. How do I cap a user before they burn through the budget?

Behind the scenes, the same data is emitted as **standard business metrics** to CloudWatch, powering 8 out-of-the-box dashboards (Ops / API / Agent / Build / GenAI Cost / Sub-Agent Topology / Sandbox / Security) that your SRE team can open directly.

## When you'd use it

| Scenario                               | Entry point                                               |
| -------------------------------------- | --------------------------------------------------------- |
| Monthly cost review                    | Admin console → `/admin/billing` → Overview               |
| Find the heaviest spenders             | Admin console → `/admin/billing` → "Top users"            |
| Cost breakdown by business unit        | Admin console → `/admin/billing` → "Top projects"         |
| 6-month trend for a single user        | Admin console → User detail page → Usage                  |
| Set a token budget per user/tenant     | Admin console → User detail → Quota                       |
| Monitor production health / latency    | CloudWatch → Dashboards → `<Prefix>-OpsOverview` etc.     |
| Audit who changed a quota              | CloudWatch Logs → `/nexus-ai/audit` log group             |

## How to use it

### 1. Open the admin billing overview

Sign in as an `admin` and go to **Admin → Billing**.

<!-- SCREENSHOT: admin-billing-overview -->

The page shows:

- **Total cost this month** — the USD sum across all users
- **By model** — calls, tokens, and cost for each Bedrock model
- **Top 10 users** — cost leaderboard
- **Top 10 projects** — cost ranked by project

The current month is shown by default; switch the `YYYY-MM` selector at the top to view any past month.

### 2. Drill into a heavy spender

Click any row in the "Top users" table to open the **last-N-months trend** for that user:

<!-- SCREENSHOT: admin-billing-user-usage -->

- Monthly usage curve for the past 6 months (default 6, up to 24)
- Current-month breakdown by model
- Current quota and usage progress

### 3. Set a token quota

Click "Edit quota" on the user detail page:

<!-- SCREENSHOT: admin-billing-set-quota -->

| Field                   | Meaning                                                                 |
| ----------------------- | ----------------------------------------------------------------------- |
| `monthly_token_budget`  | Token ceiling for **one calendar month**                                |
| `alert_threshold_pct`   | Percentage at which to fire an alert (default `80`)                     |
| `disable_on_exceed`     | **Block requests** after the ceiling (default `false` — alert only)     |
| `tenant_id`             | Optional — scope the quota to a tenant (empty = platform-wide)          |
| `notes`                 | Optional note, written to the audit log                                 |

When you click **Save**, Nexus-AI will:

1. Persist the new quota — it takes effect on the next request
2. Write an `admin.quota.update` audit event to the `/nexus-ai/audit` log group
3. Fire an alert once monthly usage crosses `alert_threshold_pct`

::: tip Ease into it
For a new team, start with `disable_on_exceed=false` and observe for one month before flipping to hard enforcement.
:::

### 4. Open the CloudWatch dashboards

On platform init, Nexus-AI creates 8 CloudWatch dashboards. In the AWS Console, go to **CloudWatch → Dashboards** and look for names that start with your `prefix`:

<!-- SCREENSHOT: cloudwatch-dashboards-list -->

| Dashboard                     | For whom                                                      |
| ----------------------------- | ------------------------------------------------------------- |
| `<Prefix>-OpsOverview`        | SRE: API errors, SQS backlog, Bedrock throttles               |
| `<Prefix>-APIPerformance`     | API engineers: volume, latency P50/P90/P99, status codes      |
| `<Prefix>-AgentRuntime`       | AI engineers: agent calls, tokens, tool latency, errors       |
| `<Prefix>-BuildPipeline`      | Build owners: success rate, stage duration, fork events       |
| `<Prefix>-GenAICost`          | Admins: per-model tokens, cache hit rate, Bedrock latency     |
| `<Prefix>-SubAgentTopology`   | AI engineers: sub-agent call chain and failure root cause     |
| `<Prefix>-SandboxRuntime`     | Platform: sandbox pool idle/busy, cold-start, decommissions   |
| `<Prefix>-SecurityAudit`      | Security: auth failures, RBAC denials, sensitive-op audit     |

### 5. Run ad-hoc queries with Logs Insights

Every dashboard has a Logs Insights widget at the bottom (slow requests, top errors, audit events). Click "Open in Logs Insights" on a widget to edit the query — you can slice by `user_id`, `project_id`, or `trace_id`.

<!-- SCREENSHOT: logs-insights-slow-requests -->

Common fields (logs are JSON by default):

- `user_id` / `project_id` / `agent_id` / `session_id` — business dimensions
- `trace_id` / `span_id` — link to X-Ray traces
- `model_id` / `tokens_in` / `tokens_out` — LLM call details
- `duration_ms` / `http.status_code` / `http.route` — API requests

## Parameters & limits

### How tokens are billed

| Token type        | Bedrock billing factor | Meaning                                                |
| ----------------- | ---------------------- | ------------------------------------------------------ |
| `input`           | 1.0x                   | Normal input (cache miss)                              |
| `output`          | 1.0x                   | Model output                                           |
| `cache_read`      | **0.1x**               | Prompt-cache hit — 10× cheaper                         |
| `cache_write`     | **1.25x**              | Prompt-cache write — 25% more than normal input        |

Total cost formula: `tokens_in × 1.0 + cache_read × 0.1 + cache_write × 1.25 + tokens_out × output_unit_price`, multiplied per `model_id` unit price.

### Dimensions you can slice by

| Dimension       | Use case                                                    |
| --------------- | ----------------------------------------------------------- |
| `user_id`       | Per-user cost, top-N leaderboards                           |
| `project_id`    | Cost per business unit / project                            |
| `tenant_id`     | Tenant-level roll-up (multi-tenant deployments)             |
| `agent_id`      | Call volume and tokens for one agent                        |
| `model_id`      | Model-level cost split                                      |
| `workflow_type` | agent_build / tool_build / skill_build / magician           |
| `runtime_type`  | local / agentcore / sandbox                                 |
| `stage_name`    | Stage inside the build pipeline                             |
| `tool_name`     | Per-tool latency and success rate                           |

::: warning session_id is not a metric dimension
`session_id` has extremely high cardinality (one per chat), so it's written to trace spans only — it will **not** appear on CloudWatch metric attributes, which would blow up cost. Use Logs Insights to query per session.
:::

### Limits

| Control                                          | Limit                                   |
| ------------------------------------------------ | --------------------------------------- |
| `/admin/billing/overview` `month` parameter      | `YYYY-MM` or `YYYY-MM-DD`               |
| `/admin/billing/users/top` `limit`               | ≤ **200**                               |
| `/admin/billing/projects/top` `limit`            | ≤ **200**                               |
| Per-user trend `months` parameter                | ≤ **24** months                         |
| CloudWatch dashboard body                        | ≤ **400 KB** JSON (validated on build)  |

### Log retention

| Log group                       | Retention | Purpose                  |
| ------------------------------- | --------- | ------------------------ |
| `/<slug>/application/*`         | 30 days   | Per-service app logs     |
| `/<slug>/agent`                 | 30 days   | Agent execution detail   |
| `/<slug>/build`                 | 30 days   | Build pipeline           |
| `/<slug>/access`                | **90 d**  | API access (compliance)  |
| `/<slug>/audit`                 | **90 d**  | Sensitive-op audit       |
| `/<slug>/security`              | **90 d**  | Auth / RBAC denials      |
| `/<slug>/metrics`               | 7 days    | EMF metric spill         |
| `/<slug>/debug`                 | 3 days    | Temporary debugging      |

### Permissions

- All `/admin/billing/*` endpoints require `role=admin` — any other role receives **403**.
- Every quota change is audited with the current admin's `user_id` — no anonymous writes.

## FAQ

**Q1: Why doesn't the admin-console cost line up with the `GenAICost` CloudWatch dashboard?**

A: The admin overview reads from a monthly-aggregated billing table in the database — stable numbers, settled once per month. The CloudWatch dashboard shows **raw token volume** at minute-level resolution. Trends match, but they won't be penny-aligned. Trust `/admin/billing/overview` for invoiceable figures.

**Q2: If I turn `observability` off, will billing still be accurate?**

A: Yes. Billing and quotas read from the operational database and don't depend on OTEL. `observability.enabled=false` only stops metric and trace export to CloudWatch; the billing page and quota enforcement continue to work.

**Q3: What does a user see when `disable_on_exceed=true` kicks in?**

A: The API returns a quota-exceeded error; chat and build jobs cannot start until the next calendar month resets the counter or an admin raises the budget. Pair it with the 80% alert threshold so users get a warning first.

**Q4: My cache hit rate is low — what now?**

A: Open `<Prefix>-GenAICost` and look at the **Cache Hit %** tile. If it's consistently below 20%, the prompt prefix is probably changing too often and every call misses the cache. Stabilize the system prompt and tool list ordering first; if that's not enough, see the [Bedrock Prompt Caching guide](https://docs.aws.amazon.com/bedrock/latest/userguide/prompt-caching.html) for where to anchor cache points.

**Q5: What's the minimum an audit log entry captures?**

A: Every `admin.quota.update` event in `/nexus-ai/audit` contains at least `timestamp`, `action`, `admin_user` (who changed it), `target_user` (whose quota was changed), `token_budget`, `threshold`, and `disable_on_exceed`. Audit logs are retained for **90 days**, which covers most compliance needs.
