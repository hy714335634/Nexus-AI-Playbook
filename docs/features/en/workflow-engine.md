---
title: Workflow Engine
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - config/workflows.yaml
    - nexus_utils/workflow/**
  generated_at: 2026-05-08T15:40:11+00:00
  generated_by: docs-sync v2
---

# Workflow Engine

## What it is

The Workflow Engine is the scheduler that turns a single sentence of intent into a sequence of trackable stages and drives them to completion. Whenever you start an **Agent Build**, **Agent Update**, **Tool Build**, **Skill Build**, or let the **Magician** route your request, the engine advances through a predefined stage list — intent recognition → requirements analysis → design → development → validation → deployment — while persisting context, aggregating metrics, and honoring pause/resume/stop signals.

## When to use it

| Scenario | What the engine does for you |
| --- | --- |
| First time describing an agent | Runs the `Agent Build` workflow: 8 stages — intent recognition, requirements analysis, architecture design, agent design, tool development, prompt development, code development, deployment |
| Want to change an existing agent's capabilities or prompt | Runs the `Agent Update` workflow: 5 stages — update orchestrator, requirements update, tool update, prompt update, deployment; tool/prompt updates are skippable |
| Need a standalone tool function | Runs the `Tool Build` workflow: intent recognition → design → development → validation → deployment (5 stages) |
| Need a Claude-style Skill | Runs the `Skill Build` workflow: intent recognition → design → development → validation → deployment (5 stages) |
| Not sure which workflow fits | Runs the `Magician` router: recognizes intent and dispatches into the right workflow |
| Long-running job you want to pause or inspect | Supports pause, resume, and stop; every stage's output, token usage, and execution time are persisted — you can resume from any completed stage |
| Multi-agent projects | Architecture design forks per agent; development stages run in parallel; a join point gates deployment |

## How to use it

### Option 1 — Run the whole workflow end-to-end

<!-- SCREENSHOT: workflow-engine-run-full -->

1. Open **New project** and pick the target workflow (Agent Build / Tool Build / Skill Build / Agent Update / Magician).
2. Describe your requirement in natural language — the more specific, the better intent recognition works.
3. On submit, the engine steps through the configured stages in order until the last one finishes.
4. The project detail page shows in real time:
   - The current stage and the list of completed stages;
   - Each stage's input/output tokens, execution time, tool call count;
   - Aggregated totals: total tokens, total time, total tool calls.

### Option 2 — Start from a specific stage

When you want to regenerate a stage's output (e.g., you tweaked the prompt or the tool list), rerun from that stage:

1. Open the project detail page.
2. Click `Rerun from here` next to a completed stage.
3. The engine validates that all prerequisites of that stage are already complete. If any are missing, it refuses and tells you which ones.
4. On confirm, the engine runs from that stage all the way through.

::: tip Prerequisite checks are hard gates
Each stage declares `prerequisites` in the workflow config. For example, `code development` depends on `prompt development` — no prompt, no code. The engine will refuse to skip forward and will tell you exactly which prerequisites are missing.
:::

### Option 3 — Pause, resume, stop

<!-- SCREENSHOT: workflow-engine-pause-resume -->

For long stages (tool / prompt / code development can take minutes to tens of minutes):

1. Click `Pause` in the project header. The current stage finishes, then the workflow stops and doesn't advance.
2. Click `Resume` to continue from the next pending stage.
3. Click `Stop` to halt as soon as the current LLM call returns; the workflow moves to `stopped` and will not auto-advance anymore.
4. The control state is always visible on the project page: `running` / `paused` / `stopped` / `cancelled`.

### Option 4 — Fork / join for multi-agent projects

When your requirement needs more than one agent (e.g., a main agent plus sub-agents), the `Agent Build` workflow parallelizes automatically:

1. Once `System Architecture Design` finishes, the engine reads the agent list from the architecture.
2. For each agent, it runs the four agent-scope stages — `Agent Design → Tool Development → Prompt Development → Code Development` — in parallel.
3. After every agent finishes code development, the workflow joins and enters `Agent Deployment` as a single step.
4. The progress view groups by agent and shows each agent's current stage and overall completion percentage.

### Option 5 — Let Magician route you

For mixed or ambiguous requests ("build me an agent that checks the weather and suggests an outfit"), hand it to Magician:

1. Pick `Magician routing` in **New project**.
2. Enter your full request.
3. Magician classifies the intent — new agent? update? tool only? — and forwards you into the matching workflow's remaining stages.

## Key parameters / limits

### Workflows and stages

| Workflow | Stages | Order |
| --- | --- | --- |
| Agent Build Workflow V2 | 8 | Intent Recognition → Requirements Deep Analysis → System Architecture Design → Agent Design → Tool Development → Prompt Development → Code Development → Agent Deployment |
| Agent Update Workflow V2 | 5 | Update Orchestrator → Requirements Update → Tool Update → Prompt Update → Update Deployment |
| Tool Build Workflow V2 | 5 | Intent Recognition → Tool Design → Tool Development → Tool Validation → Tool Deployment |
| Skill Build Workflow | 5 | Intent Recognition → Skill Design → Skill Development → Skill Validation → Skill Deployment |
| Magician Routing | 1 | Magician Orchestrator (auto-routes to another workflow) |

### Stage properties

| Property | Meaning |
| --- | --- |
| `scope` | `project` (runs once globally) or `agent` (runs once per agent) |
| `prerequisites` | Stages that must be completed before this one can start |
| `supports_iteration` | Whether the stage can iterate multiple times (tool / prompt / code development default to true) |
| `optional` | Whether the stage is skippable (tool update and prompt update in `Agent Update` are optional) |
| `fork_on_complete` | Fork into parallel per-agent branches on completion (true for `System Architecture Design`) |
| `join_after_complete` / `join_before_start` | Wait for all agent branches to converge (`Code Development` joins after; `Agent Deployment` joins before start) |
| `rule_keys` | Rule keys injected into stage context, such as `directory_rules`, `generation_rules`, `cache_rules`, `external_resources`, `custom_rules` |

### Default runtime quotas

| Quota | Default | Notes |
| --- | --- | --- |
| Max retries per stage | 3 | Marked `failed` once exceeded |
| Retry delay | 5 s | Wait between retries |
| Per-stage timeout | 3600 s (1 h) | Treated as failure when exceeded |
| Total workflow timeout | 21600 s (6 h) | Wall-clock cap for the whole workflow |
| Checkpoint interval | 60 s | How often state is persisted during execution |
| Max context tokens | 100000 | Upper bound of context injected to the agent |
| Summarization threshold | 5000 tokens | Older stage outputs above this are auto-summarized |
| Max inline stage output | 400 KB | Larger outputs are stored by reference in external object storage |

### Stage and control states

| Type | Values | Meaning |
| --- | --- | --- |
| Stage / project status | `pending` / `running` / `completed` / `failed` / `paused` | Lifecycle of a stage |
| Control status | `running` / `paused` / `stopped` / `cancelled` | Maps to user pause / stop / cancel actions |

## FAQ

**Q1: If I rerun from a stage, do I need to rerun its prerequisites too?**
A: No. As long as the prerequisites are `completed` in history, the engine trusts them and starts from the stage you picked. If any prerequisite never completed — or you changed an earlier stage's output — you have to run the prerequisites first; the engine refuses to skip forward.

**Q2: What's the difference between pause and stop?**
A: Pause means "finish the current stage, then wait"; on resume, execution picks up from the next pending stage — useful when you want to inspect intermediate results. Stop means "wrap up the current LLM call, then end"; the workflow moves to `stopped` and won't auto-resume. To continue after stop, rerun from a stage manually.

**Q3: Can the Agent Update workflow change only the prompt, not the tools?**
A: Yes. The Update Orchestrator stage inspects your request and decides which stages to skip (`skip_stages`). Tool update and prompt update are marked `optional: true`, so they only run when needed, and skipped stages don't consume quota.

**Q4: In a multi-agent project, what happens if one agent fails to build?**
A: Agent branches are independent — a failure in one agent's tool / prompt / code development stage only marks that agent's stage as `failed`; other agents keep advancing. But `Agent Deployment` is a join point: it runs only after every agent's code development succeeds. Otherwise it waits until you fix the failed agent and rerun.

**Q5: Where do I see each stage's execution metrics?**
A: Every completed stage records `input_tokens` / `output_tokens` / `execution_time_seconds` / `tool_calls_count` / `model_id`. The project overview aggregates these into total tokens, total cost, total time, and total tool calls.
