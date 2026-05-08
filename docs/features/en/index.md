---
title: Features
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - (chapter index — aggregated)
  generated_at: 2026-05-08T16:22:31+00:00
  generated_by: docs-sync v2
---

# Features

This chapter walks through every major capability of Nexus-AI grouped by area: the building blocks of an agent (tools, skills, templates, Agent Factory), the runtime isolation that keeps them safe (Sandbox), the orchestration and collaboration layer (workflow engine, multi-agent graph/swarm), real-time interaction pieces (stream relay, event scheduler, Bridge multi-connection), and the operational surface on top — observability, metrics & billing, logging.

If you want to know what a specific feature does, when to use it, and how to reach it in the console, jump to the matching page. If you want the full map of what the platform can do, read the table below in order.

## Docs in this chapter

| Doc | What it covers |
|-----|----------------|
| [Tools & Toolsets](./tools-toolsets) | Two granularities for giving an agent capability: a single tool function, or a full toolset (Skill) bundling tools, scripts and reference docs. |
| [Skills System](./skills-system) | Package specialised expertise into distributable, reusable, versioned Skill packs shared across agents and projects. |
| [Agent Factory](./agent-factory) | The assembly line that turns prompt template + model + tools into a runnable agent, plus the built-in health check. |
| [Prompt Templates](./prompt-templates) | Ready-to-use YAML agent blueprints covering common scenarios, so you don't start a new agent from a blank prompt. |
| [Sandbox Runtime](./sandbox) | Every conversation runs inside its own Firecracker microVM — fully isolated, then pooled for fast reuse. |
| [Workflow Engine](./workflow-engine) | Turns a single sentence of intent into a pipeline: intent → analysis → design → development → validation → deployment. |
| [Multi-Agent Graph/Swarm](./multi-agent) | See who calls whom on a single graph, and let pre-orchestrated swarms of specialist agents relay the same job. |
| [Stream Relay](./stream-relay) | Replies stream token-by-token while the full turn is buffered on the server — switch tabs, refresh, or reconnect without losing anything. |
| [Event Scheduler](./event-scheduler) | Turn any agent into a scheduled job or long-running autonomous task, with automatic triggers and archived results. |
| [Bridge Multi-Connection](./bridge) | A single `curl` connects an agent to your own servers — up to 5 at once, with parallel command execution. |
| [Observability](./observability) | Requests, latency, token usage, build success, sandbox pool state — piped automatically to CloudWatch and X-Ray. |
| [Metrics & Billing](./metrics-billing) | The admin-facing usage and cost center: spend broken down by user, project, and model, with per-user caps. |
| [Logging](./logging) | A two-layer system: colored local logs for your terminal, plus structured logs you can filter by `user_id`, `trace_id`, and more. |
