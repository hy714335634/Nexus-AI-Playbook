---
title: Built-in AI Assistants (Admin)
sync:
  source_commit: 7f4029536abf5945f2384f544555a3f6815c2519
  source_files:
    - config/default_config.yaml
    - prompts/system_agents_prompts/helper_agents/**
  generated_at: 2026-07-12T12:42:09+00:00
  generated_by: docs-sync v2
---

# Built-in AI Assistants (Admin)

Nexus-AI embeds AI assistants (collectively labeled "Nexus Assistant" in the UI) on several admin pages. You can handle everyday management — troubleshooting, configuration, auditing — in plain language: ask a question and it gives you an answer, a table, a suggestion, or a clickable button, right where you are.

Every assistant follows the same bottom line: **it works only on its own page, reads only that page's data, and any change it proposes first becomes a "pending confirmation" that takes effect only after you click to confirm** — it never modifies the system behind your back.

## Assistants at a Glance

Three assistants are embedded directly in admin pages for day-to-day management:

| Assistant | Page | What it does for you |
|-----------|------|----------------------|
| Ops Assistant | Service Status | Troubleshoot, assess service health, propose restarts (needs confirmation), analyze error logs |
| Config Advisor | Config Management | Find parameters in plain language, explain them, suggest changes, run a config health check |
| Audit Assistant | Audit Trail | Answer audit questions, summarize a time range, generate compliance reports |

A few more assistants serve "creation" workflows (App Builder, Mission Publisher, Tool Review, Skill Creator). Those are end-user facing and covered in the User Guide; the [Managing Built-in Assistants](#managing-built-in-assistants) section at the end explains how to toggle and configure all of them centrally.

## Common Usage

Whichever assistant you use, the pattern is the same:

- **How to open**: most pages have a floating "Nexus Assistant" button in the bottom-right corner — click to start. The Config Management page additionally has a "Just tell me what to tune" search box at the top.
- **Enlarge the window**: click "Switch to centered large window" inside the panel to view long answers more comfortably.
- **Suggested questions**: the panel pre-loads a few common-question buttons — click one instead of typing.
- **Response shapes**: an answer may be plain text, a structured table, or text followed by a clickable button (which navigates to the relevant page, or applies a filter directly to the current list).
- **Guardrails**: assistants are read-first; any action that would change the system becomes a "pending confirmation" first and runs only after you confirm; assistants never read or write secrets, passwords, or other sensitive items.

## Ops Assistant

**Purpose**: on the Service Status page, help you troubleshoot, check service status, analyze error logs, and propose service restarts when needed.

**Entry**: sidebar "Management" → "Service Status" → the "Nexus Assistant" button in the bottom-right corner.

<!-- SCREENSHOT: admin-service-status -->

**What you can ask**: the assistant covers four kinds of ops needs:

1. **Troubleshooting**: describe a symptom and it pulls log evidence to pinpoint the likely root cause.
2. **Service health assessment**: ask "How are the services running right now?" and it reports each service's status, health, and resource usage.
3. **Service restart**: when you ask to restart a service, it generates a "pending confirmation" (see the guardrails below) instead of acting directly.
4. **Error log analysis**: aggregate high-frequency errors and correlate logs across services in time to trace cascading failures.

Example suggested questions in the panel: "Why isn't the worker consuming messages?", "Which service has been logging ERRORs recently?", "How do I diagnose an api startup failure?".

**Response shapes**: status questions usually return a table (Service / Status / PID / Port / CPU / Memory); troubleshooting and analysis return a text conclusion. If you ask it to "generate/save a report," it writes the full report into its workspace, which you can download after it's saved.

::: warning Guardrails
- The Ops Assistant is **read-only**: it can view fixed logs and service status, propose restarts, and save reports to its workspace — it **cannot change configuration or run arbitrary commands**.
- **Restarts need confirmation**: only for Worker, Frontend (Web), Avatar, and Event Scheduler does the assistant generate a "pending confirmation"; the actual restart is triggered only after you click to confirm in the UI.
- Requests to restart API, Bridge, Sandbox Controller, or OTEL Collector, and requests to "stop" any service, are **politely declined** — do those manually via the "Restart" / "Stop" buttons in the service list, and assess the impact yourself.
:::

## Config Advisor

**Purpose**: on the Config Management page, find parameters in plain language, understand them, get change suggestions, and run a health check over the whole configuration.

**Entry**: sidebar "Settings" → "Config Management". This assistant has three entry points:

- the "Just tell me what to tune" search box at the top of the page;
- the floating "Nexus Assistant" panel in the bottom-right corner;
- the "Ask AI: effect & impact" button on each parameter card (to ask about a single parameter).

<!-- SCREENSHOT: settings-config -->

**What it can do**:

1. **Find parameters**: describe your goal in plain language (not exact keywords) and it does semantic matching to locate relevant parameters.
2. **Explain parameters**: describe what a parameter does, whether its current value is reasonable, and whether a change is **hot-reloaded** (takes effect on the next new session) or **requires a restart**.
3. **Suggest changes**: when it has a clear suggestion, it offers a value you can fill into the parameter box with one click, plus a one-line reason.
4. **Config health check**: click the "Config Health Check" button and the assistant reviews the entire current configuration across cost, performance, reliability, and security/compliance, reporting only what genuinely warrants attention, ranked by severity.

Example suggested questions in the panel: "I want to cut usage cost", "Conversations keep losing context — what do I do?", "What is prompt caching for, should I enable it?", "Which parameters need a service restart after changing?".

**Response shapes**: text explanation + suggestion cards (click to fill the suggested value into the matching parameter box) + a health-check findings list.

::: warning Guardrails
- The advisor **only suggests parameters that exist in the parameter list and satisfy their type/range/enum constraints** — it never suggests secrets, passwords, or other sensitive items.
- A suggestion is only "filled in, pending save" — after it's filled in, you still have to confirm and click "Save" for it to take effect.
- Distinguish **hot-reload** from **requires-restart**: hot-reload items take effect on the next new session after saving; requires-restart items only take effect after the relevant service is restarted.
- Plain-language search may return "zero matches" ("AI matched 0 relevant parameters") — that's a normal result; rephrase or try different keywords.
:::

## Audit Assistant

**Purpose**: on the Audit Trail page, answer audit questions, summarize a time range, and generate compliance-oriented audit reports.

**Entry**: sidebar "Settings" → "Audit Trail" → the "Nexus Assistant" button in the bottom-right corner.

<!-- SCREENSHOT: settings-audit -->

**What it can do**:

1. **Audit Q&A**: ask questions like "who changed what and when," "were there failed logins or privilege-escalation attempts," "which user was most active."
2. **Range summary**: click the "Range Summary" button to get a concise digest of audit activity in the current range (activity volume, most active operator, most-changed resources, risk signals).
3. **Generate compliance report**: click "Generate Compliance Report" to produce a GxP / 21 CFR Part 11-oriented Markdown report (overview, key changes, access control, anomalies & risks, conclusion & recommendations).
4. **Send to SNS**: click "Send to SNS" to push the result to the audit notification topic.

The action buttons in the panel (Range Summary / Generate Compliance Report / Send to SNS) are all labeled "Scope follows the current filter" — their processing scope is exactly the time range you picked on the page (Last 7 days / Last 30 days / Last 90 days).

**Response shapes**: a structured text summary (e.g., "There were 8 login records today, all successful, from two IPs…"), often followed by a clickable button (e.g., "View today's login records," which navigates to the audit log already filtered accordingly); a compliance report is rendered as full Markdown.

::: warning Guardrails
- The assistant **answers only from the server-side audit data in the current range**; when data is insufficient it explicitly says "no relevant records in the current range" and never fabricates events.
- Both the range summary and the compliance report are based on the time range you selected — confirm the range is correct before exporting/sending.
:::

## Creation-Workflow Assistants

The following assistants are not floating buttons; they're embedded in their own creation wizards / build flows and are mainly for end users (see the User Guide for detailed steps). As an admin, what matters to you is whether they're enabled and which model they use (see the next section).

| Assistant | Where it appears | What it does |
|-----------|------------------|--------------|
| App Builder | App Center "New App" → Quick Create wizard | Turns a description + a bound Agent into a publishable single-file app page |
| Mission Publisher | The natural-language task-creation entry in the task panel | Turns a one-line goal into an executable task plan (resource matching + acceptance criteria + scheduling) |
| Tool Review | The tool build flow | Reviews user-uploaded scripts and outputs a structured tool list with review notes |
| Skill Creator | The skill build flow | Distills a conversation history into a reusable skill |

::: tip
When publishing an app via the Quick Create wizard (the App Builder assistant), the default validity is 7 days. For apps you want to keep long-term, remember to set the validity to "Permanent (no expiry)" in the publish dialog.
:::

## Managing Built-in Assistants

Toggling and configuring all built-in assistants is done centrally on the Config Management page: sidebar "Settings" → "Config Management", then search `helper` in the search box to find the relevant parameters. Each assistant can be configured individually:

| Setting | Effect | How it applies |
|---------|--------|----------------|
| Enabled | Turn off and the assistant no longer appears on its page | Hot-reload |
| Model | Which model the assistant uses; leave empty to auto-pick the corresponding model from the model catalog by tier (pro / lite) | Hot-reload |
| Tier (pro / lite) | Applies when the model is left empty — pro is stronger and costs more, lite is cheaper | Hot-reload |
| UI actions allowed | Whether the assistant may include clickable navigate/filter buttons in its answers | Hot-reload |
| Workspace enabled | Whether the assistant may save artifacts such as reports to its workspace for download | Hot-reload |
| Max tool rounds | For assistants that call tools (Ops, Mission Publisher, etc.), the maximum number of tool rounds per answer | Hot-reload |

::: warning Note
- All of the above are **hot-reload** items: changes take effect on the **next new session**, no service restart required.
- Assistants default to a **pro-tier** model (higher answer quality). Switching to the lite tier saves cost, but complex troubleshooting, compliance reports, and similar scenarios may suffer — weigh it against your usage and budget.
- Which models each assistant can use depends on the models enabled in the model catalog (sidebar "Settings" → "Model Catalog").
:::
