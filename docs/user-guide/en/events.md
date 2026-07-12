---
title: Event Jobs
sync:
  source_commit: 9d40a32f2bad2c7858b3ed0cfb4390e1bd603a30
  source_files:
    - api/v2/routers/event_jobs.py
    - nexus_utils/event_scheduler/**
    - web/app/(main)/events/**
  generated_at: 2026-07-12T13:52:25+00:00
  generated_by: docs-sync v2
---

# Event Jobs

Event jobs let your agent **work automatically on a schedule** — no need to sit at your computer. You set up "when to run and what to do," and it runs on its own, tidies up the results, and waits for you to review them.

Common uses:

- Summarize yesterday's data every morning and produce a daily report
- Check pending items every Monday morning and send a reminder
- Let an agent keep working toward a goal, step by step, until it's done

## Three types of jobs

| Type | When it runs | Good for |
|------|-------------|----------|
| **One-time** | Once, at a time you specify | "Generate a quarterly report next Wednesday at 10 AM" |
| **Recurring** | Repeatedly, on a fixed rhythm (daily, weekly, hourly…) | "Summarize sales data every morning at 8 AM" |
| **Autonomous** | Runs continuously; the agent decides its own next step until the goal is met | "Keep following up on this project and write up any progress" |

::: tip No need to memorize complex time formats
Just describe "when" in everyday language — the system understands it and sets up the schedule for you.
:::

## Open the job panel

1. In the left sidebar, click **Jobs**.
2. The page title reads "Jobs," with **New Job** and **Refresh** buttons in the top-right corner.
3. If you haven't created any jobs yet, the page shows an empty state prompting you to create your first one.


## Create a job

Nexus-AI helps you create jobs **conversationally** — you just describe your goal, and the system matches the right agent and generates a runnable plan.

1. Click **New Job** in the top-right corner.
2. The "Create a job in natural language" dialog opens, showing "Describe your goal and the assistant will match resources and build a runnable plan."
3. In the "Job goal" text box, describe in a sentence or two what you want the system to do — once or continuously. **The more specific you are, the more accurate the plan.** For example:
   - "Every morning at 9 AM, compile yesterday's support tickets into a summary."
   - "Next Monday at 10 AM, generate a sales summary for last month."
4. Once you've described it, click **Start Analysis** (the button is greyed out and unclickable until you type something).
5. The system analyzes your description, picks a suitable agent, confirms the schedule, and builds a plan. Confirm as prompted, and the job is created.


::: tip It starts automatically once created
After a job is created, it's queued to run automatically at the time you set. You don't need to do anything before then — the system handles it in the background.
:::

## View jobs and run history

The job panel offers three ways to view your jobs, switchable on the page:

- **List** — one row per job, all the key info at a glance
- **Kanban** — grouped into columns by status, great for an overview of progress
- **Timeline** — arranged in time order, ideal for reviewing run history

Every run leaves a record. Here's what each status means:

| Status | Meaning |
|--------|---------|
| **Pending** | Queued, not yet time to run |
| **Running** | Currently executing — please wait |
| **Completed** | Ran successfully; results are ready to view |
| **Failed** | The run didn't succeed; open it to see why |
| **Skipped** | This run didn't happen (for example, the job was paused) |

## Manage existing jobs

Hover over a job to reveal a row of action buttons:

- **Pause / Enable** — once paused, the job no longer runs automatically; re-enable to resume
- **Run now** — don't want to wait for the next scheduled time? Trigger a run manually right away

  ::: warning Enable before running manually
  If a job is paused, you need to re-enable it first before you can trigger a manual run.
  :::
- **Edit** — change the schedule, prompt, description, and other settings
- **Delete** — remove the job itself and clear all its run records (this can't be undone, so proceed carefully)

::: tip One-time jobs pause themselves when done
A one-time job automatically turns off after it finishes, so it won't trigger again — no need to shut it off manually.
:::

## View results and generated files

1. In the job panel, open one of the run records.
2. The detail panel shows this run's **result summary**, the full output, and all files generated during the run.
3. Many file types preview directly: documents, spreadsheets, images, web pages, presentations, and more. Images and graphics can also be zoomed in and out.
4. To send a result to someone, generate a **share link** for a file — they can view it just by opening the link (share links expire automatically after a while).

::: tip Runs take a little time
An agent may need anywhere from a few minutes to tens of minutes to complete a job, depending on its complexity. Feel free to do something else and come back later — click **Refresh** to see the latest progress.
:::

## About autonomous jobs

Autonomous jobs are special: they run continuously, and after each round they plan their own next step.

- When the system judges the **goal has been reached**, the job stops automatically.
- If you want it to take on something new, open the job details and give it a **new instruction** — the job restarts and continues with your new direction.
- You can also set a **maximum number of runs** for an autonomous job; once it hits that limit, it pauses automatically to avoid running indefinitely.

## FAQ

::: tip A job's time has passed but it didn't run?
First check whether the job is "paused" — paused jobs don't run automatically. Once you've confirmed it's enabled, try **Run now** to trigger it manually.
:::

::: tip Can I see jobs created by others?
By default you only see the jobs you created. If someone shares a job with you through shared resources, you'll see it too. Administrators can see all jobs.
:::

::: warning Deleting a job can't be undone
Deleting a job also clears all of its run records, and they can't be recovered. If you just don't need it for now, use "Pause" instead of "Delete."
:::
