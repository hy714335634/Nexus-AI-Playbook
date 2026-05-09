---
title: Event Scheduler
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - config/eventschedule_config.yaml
    - nexus_utils/event_scheduler/**
  generated_at: 2026-05-08T15:54:25+00:00
  generated_by: docs-sync v2
---

# Event Scheduler

## What is this

The Event Scheduler turns any Agent on Nexus-AI into a scheduled job or a long-running autonomous task. You only specify "which Agent", "what prompt", and "when"; the platform triggers the Agent on time, archives every run in its own S3 workspace, and uses a lightweight analysis Agent to produce a short summary. Use it for daily reports, periodic scraping, recurring monitoring, and open-ended tasks where the Agent plans the next step itself.

## Use cases

| Scenario | Job type |
| --- | --- |
| Send me a weekly project recap tomorrow at 8 AM | **One-time** — fires once at a specific moment, then stops |
| Pull industry news every workday at 09:30 and summarize | **Recurring** — repeats on a cron schedule |
| Let the Agent keep pushing on a goal (competitive tracking, rolling research) without me queueing each run | **Autonomous** — the Agent reads its own history, plans the next run, and stops itself when the goal is met |
| Trigger a multi-Agent workflow on a timer | Any type — the scheduler only triggers; multi-Agent handoffs share one S3 workspace |
| "Only tell me when there's something new" heartbeat jobs | Recurring + Agent reply `HEARTBEAT_OK`; the platform silently suppresses empty results |

## How to use

### Step 1: Have an Agent ready

The scheduler only handles *when* to fire. The actual work is done by the Agent you bind. Create and verify that Agent first, making sure it can complete the target task on its own.

::: tip
Your Agent's tools, Skills, and multi-Agent wiring stay intact — the scheduler only layers a small "job-type context" on top of the existing prompt. It never overwrites the Agent's tools / skills / cowork setup.
:::

### Step 2: Create an event job

<!-- SCREENSHOT: event-scheduler-create-job -->

On the Event Scheduler page click **New Job** and fill in by type:

**One-time job**

1. Pick the target Agent.
2. Set the trigger time (ISO 8601, e.g. `2026-05-10T09:00:00Z`).
3. Write the prompt the Agent receives when triggered.
4. Save. The job fires once and is auto-disabled on completion.

**Recurring job**

1. Pick the Agent.
2. Enter a 5-field cron expression (`min hour day month weekday`). For example, `0 9 * * 1-5` means 09:00 every workday.
3. Pick a timezone (IANA name, e.g. `Asia/Shanghai`; default `UTC`).
4. Write the prompt sent on every run (the same prompt is used each time).
5. Optional: set a validity window (`valid_from` / `valid_until`) and a max execution count.

**Autonomous job**

1. Pick the Agent.
2. Use a cron expression for the self-driven loop cadence.
3. Write an initial prompt describing the goal you want the Agent to keep pursuing.
4. Optional: set a max execution count as a "hard ceiling" so the job can't run away.
5. On each run the Agent reads the prior `mission_log.md` to see what's already been done, then plans this round. End the reply with `## Task complete` to stop, or `## Next steps` to continue.

### Step 3: Inspect executions

<!-- SCREENSHOT: event-scheduler-task-history -->

Every job has its own executions page that shows each run (Task):

| Field | Meaning |
| --- | --- |
| Sequence number | The Nth run under this job (starting at 1) |
| Status | `pending`, `running`, `completed`, `failed`, `skipped` |
| Scheduled at | The time the run was supposed to start |
| Started / Completed at | When it actually started and finished |
| Result summary | Auto-generated summary from the analysis Agent (up to 1,000 characters) |
| Workspace | The S3 path dedicated to this run; all Agent-generated files live here |
| Raw Agent output | Download `agent_response.out` to see the full original text |

### Step 4: Enable, disable, delete

- **Disable**: the job is preserved but no longer triggers; any pending execution that comes due while disabled is skipped.
- **Enable**: resume scheduling. A one-time job is auto-disabled after it finishes.
- **Delete**: cascades to all execution records under the job.
- **Auto-stop for autonomous jobs**: when the analysis Agent decides the goal is met (the Agent wrote `## Task complete`, or the wording clearly indicates wrapping up), the scheduler disables the job and records the termination reason.

### Step 5 (optional): heartbeat and empty-result suppression

In recurring / autonomous jobs, if the Agent has nothing new to report this round it can reply `HEARTBEAT_OK` (or `NO_ACTION_NEEDED` / `NOTHING_TO_REPORT` / `TASK_SKIPPED`). The platform detects these tokens and sets the summary to "no action needed", so you don't get spammed with empty reports.

::: info Autonomous job history context
Before each autonomous run, the platform compiles an index of every previous execution (sequence, status, time, short summary, S3 output path) into a table and injects it into the prompt. The Agent can then use `workspace_read_file` to pull the full output of any past run and decide what to do next.
:::

## Key parameters / Limits

### Job types at a glance

| Capability | One-time | Recurring | Autonomous |
| --- | --- | --- | --- |
| Schedule expression | ISO datetime | Cron (5 fields) | Cron (5 fields) |
| Number of runs | Exactly 1 | Determined by cron + validity window + max executions | Same as recurring, plus Agent may self-terminate |
| Prompt per run | Fixed at creation | Fixed at creation | Initial prompt first, then produced by the analysis Agent |
| Needs history context | No | No | History index auto-injected |
| Stop condition | Auto-disabled after the run | Cron schedule, `valid_until`, or max executions | `## Task complete`, max executions, or no follow-up plan |

### Job fields

| Field | Description |
| --- | --- |
| `job_name` | Display name; must be unique within one Agent |
| `agent_id` | The Agent to invoke |
| `schedule_expression` | One-time = ISO datetime; recurring / autonomous = cron expression |
| `timezone` | IANA timezone used for scheduling; defaults to `UTC` |
| `prompt` | Prompt sent to the Agent on trigger |
| `description` | Free-form note for management |
| `max_executions` | Max number of runs before auto-disable |
| `valid_from` / `valid_until` | Validity window (ISO datetime) |
| `model_override` | Override the Agent's default model (e.g. a cheaper one for routine work) |
| `enabled` | Whether the job is active |

### Scheduler runtime (platform defaults)

| Parameter | Default | Meaning |
| --- | --- | --- |
| Job scan interval | 60 s | How often the scheduler checks enabled jobs and queues their next pending executions |
| Task scan interval | 10 s | How often the scheduler picks up due executions and invokes the Agent |
| Max concurrent executions | 5 | Upper bound on simultaneously running Agents; extras are deferred |
| Per-run timeout | 3600 s | Wall-clock cap per Agent run |
| Stuck threshold | 7200 s | A `running` record past this age is considered stuck |
| Analysis Agent model | Lightweight model | Summaries use a cheaper model by default |
| Empty-result tokens | `HEARTBEAT_OK`, `NO_ACTION_NEEDED`, `NOTHING_TO_REPORT`, `TASK_SKIPPED` | When an Agent reply contains one of these, the summary becomes "no action needed" |
| Summary max length | 1,000 characters | Cap on the analysis Agent's summary |
| Max Agent output size | 10 MiB | Larger output is truncated |

### Timezones, cron, and validity

- Cron uses the standard 5-field format: `min hour day month weekday`. Example: `*/15 * * * *` fires every 15 minutes.
- Timezones are IANA names (e.g. `Asia/Shanghai`, `America/New_York`). Internally scheduling converts to UTC.
- One-time jobs don't check `valid_until` — they fire whenever their scheduled time is reached.
- Recurring / autonomous jobs stop creating new executions after `valid_until`, but any already-queued pending run still fires on time.

::: warning
If the analysis Agent fails to return parseable JSON three times in a row, the run finishes with a conservative "parse failed" summary rather than retrying forever. Autonomous jobs are not terminated by this — the slow loop continues queuing the next execution on the normal cadence.
:::

## FAQ

**Q1: My job is created but hasn't executed. What should I check?**

A: Verify three things: (1) the job is enabled; (2) the current time is between `valid_from` and `valid_until`; (3) `max_executions` has not been reached. Invalid cron expressions are rejected at creation. Otherwise, allow ~10 seconds (one task scan interval) after the scheduled time before the run starts.

**Q2: If a one-time job is created after its scheduled time, will it run?**

A: No. When the scheduler finds the `schedule_expression` in the past, it won't queue a new execution. Any pending execution that was already created, however, will still run when picked up.

**Q3: What happens if the previous recurring run hasn't finished but the next run is due?**

A: Runs never overlap. The slow loop only queues the next pending execution after the current one is `completed` / `failed` / `skipped`. In addition, the transition from `pending` to `running` is done atomically (optimistic locking), so even with multiple scheduler instances the same execution won't fire twice.

**Q4: Will an autonomous job run forever? How do I stop it?**

A: Three levers: (1) ask the Agent in its prompt to emit `## Task complete` when the goal is met; (2) set a `max_executions` ceiling at creation; (3) disable the job manually. The analysis Agent also double-checks — if the Agent emits neither `## Next steps` nor `## Task complete` and the reply isn't a heartbeat, it treats the job as finished.

**Q5: How long are Agent outputs kept? Can I browse history?**

A: Each run has its own S3 workspace (`s3://&lt;bucket&gt;/&lt;event_job_id&gt;/&lt;task_id&gt;/`). `agent_response.out` holds the Agent's raw reply; other files generated during the run live alongside it. A per-job `mission_log.md` appends each summary for easy browsing. These records are cascade-deleted when you delete the job.

**Q6: Can I pick a cheaper model for a scheduled job?**

A: Yes. Set `model_override` on the job to override the Agent's default model at invocation time. The summarization step already runs on a lightweight model by default.
