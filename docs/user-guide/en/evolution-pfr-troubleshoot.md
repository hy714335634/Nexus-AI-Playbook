---
title: Evolution/PFR/Troubleshoot
sync:
  source_commit: 460f1a3f6eaf3f2c86b695c2043a5d944b0ce733
  source_files:
    - web/app/(main)/evolution/page.tsx
    - web/app/(main)/pfr/page.tsx
    - web/app/(main)/troubleshoot/page.tsx
  generated_at: 2026-07-12T14:39:49+00:00
  generated_by: docs-sync v2
---

# Evolution/PFR/Troubleshoot

Going live isn't the finish line. After an agent ships, you keep polishing it, gathering feedback, and pinpointing problems quickly when they come up — and those three jobs map to three tools:

- **Evolution management**: manage each agent's improvements like a project — sort improvement requests into "iterations" and track them through to release.
- **Iteration review (PFR)**: score every version of an agent's changes and leave improvement notes so the next version is better.
- **Troubleshoot**: when an agent misbehaves, describe the problem and the system helps you put together a plan to handle it.

Here's each one.

## Evolution management: run agent improvements like a project

The evolution page brings every agent's improvement work together on one board.

When you open it, you'll first see a row of summary numbers that give you the whole picture at a glance:

| Summary metric | Meaning |
|----------------|---------|
| **In-progress projects** | How many improvements are currently underway |
| **Due soon** | How many are approaching their delivery date |
| **Delivered this week** | How many are scheduled to finish this week |
| **Risk alerts** | How many need your attention because they might run into trouble |

Below the numbers is a **swimlane view** that sorts each improvement into columns by stage:

- **Planning** — requests raised but not started yet
- **Executing** — requests being edited and built
- **Validating** — done and now being tested and rolled out gradually
- **Released** — versions already live

On the right side there's also an **activity feed** that logs what's happened recently (such as an agent finishing its rollout, or a change improving accuracy) so you can stay up to date at any time.

![evolution-progress](/images/evolution-progress.png)

::: tip Want to export a progress summary?
Click **Export Daily Report** in the top-right corner and the system will generate a progress report for the day.
:::

### Submit an improvement request

To make an agent better, first turn your idea into a request:

1. On the evolution page, click **Submit Request** in the top-right corner.
2. Fill in the form that opens:
   - **Title** (required): sum up what you want to change in one line, e.g. "Support multiple languages in the support assistant."
   - **Owner**: pick an owner from the dropdown.
   - **Priority**: choose High, Medium, or Low.
   - **Description** (required): spell out the effect you want and the problem you're seeing — the more specific, the better.
3. When you're done, click **Submit Request**. If you're not ready yet, click **Save Draft** and come back later.

![evolution-submit](/images/evolution-submit.png)

Once submitted, the request shows up in the "Planning" lane and moves through "Executing," "Validating," and "Released" as it progresses.

### Track progress and history

Evolution management also offers a few views to help you see progress from different angles:

| View | What you'll see |
|------|-----------------|
| **Progress tracking** | Overall progress via burndown charts, dependencies, and a milestone timeline |
| **Agent iterations** | A table listing each agent's current version, status, owner, and iteration |
| **Version history** | Compare differences between versions to see exactly what changed each time |
| **Analytics** | Stats like success-rate trends, time distribution, and top risks |

![evolution-agents](/images/evolution-agents.png)

::: tip These views fill in once there's enough data
If you're just getting started, these charts may still be empty. As improvement requests progress and records build up, the charts fill in automatically.
:::

## Iteration review (PFR): score each change and leave notes

You've finished a version of an agent — is it any good? Iteration review is where reviewers score it and write down improvement notes, helping the team push each version further.

Open the review workspace and you'll see:

- At the top, a **current-agent card** showing its version number, how many times it's been reviewed this week, and its user satisfaction.
- In the middle, the **review queue**, listing changes waiting to be reviewed — each showing a title, who raised it, and its current status (Pending / In progress).
- On the right, a **context panel** with three tabs you can switch between to understand the background before you score:

  | Tab | What it shows |
  |-----|---------------|
  | **Conversation** | The real conversation between the agent and the user |
  | **Current prompt** | The instructions this version of the agent is using |
  | **Past suggestions** | Improvement notes left in the previous review round |

![pfr-history](/images/pfr-history.png)

### Submit a review

1. In the review queue, select the change you want to review.
2. After reviewing the background on the right, fill in your review at the bottom:
   - **Review score**: pick a score from 1 to 5 in the dropdown, from "5 - Excellent" down to "1 - Fail."
   - **Improvement suggestions** (required): write specific notes — for example, suggestions about the prompt, tool use, or memory strategy.
3. When you're done, click **Submit Feedback**. If you haven't finished, click **Save Draft** first.
4. Once submitted, the page confirms your feedback was received.

::: warning Suggestions can't be left blank
"Improvement suggestions" is required. Even with a high score, write a line about your take so the next version has something to work from.
:::

### View review history

To look back over past reviews:

1. Go to "Review history."
2. There's a table listing each review's ID, agent, reviewer, score, status, and date.
3. Use the search box at the top to look up by agent or reviewer, or use the "Status" dropdown to filter (All / Merged / Pending review).
4. To send records to someone, click **Export CSV** to generate a file you can open in spreadsheet software.

![pfr-history](/images/pfr-history.png)

## Troubleshoot: describe the problem, get a plan

When an agent misbehaves — wrong answers, getting stuck, results that don't match expectations — the troubleshoot tool helps you think it through quickly and get a plan to handle it.

![troubleshoot-analysis-page](/images/troubleshoot-analysis-page.png)

Once you open the page:

1. In the large text box in the middle, describe the problem in everyday language, e.g. "The support assistant has been giving off-topic answers lately."
2. Below the box are a few **problem-category cards** to help you place the issue quickly. Click one to expand it and see the suggested handling flow.
3. Once you've described it, click **Generate Plan** and the system pulls together troubleshooting and handling suggestions based on your description.
4. If you just want to log the problem for later, click **Log Issue**.

The page also shows a few summary numbers to give you the overall troubleshooting picture:

| Summary metric | Meaning |
|----------------|---------|
| **Resolved today** | How many issues were handled today |
| **Pending alerts** | How many alerts are still unhandled |
| **Average time** | How long, on average, one issue takes to handle |
| **Auto-fix rate** | The share of issues the system can fix automatically |

### Dig deeper step by step

The **quick navigation** at the bottom breaks a full investigation into stages — from analyzing and reproducing the problem, to review and fixing, to tracking and verifying. Click an entry to dive into a given stage.

::: tip Some stages are still being built out
The detailed step-by-step pages are being rolled out gradually, and some entries may still be blank. For everyday use, just use **Generate Plan** on the main page to get an overall set of suggestions.
:::

## FAQ

::: tip What's the difference between evolution management and iteration review?
In short: **evolution management** handles "what to change and how far along it is," like a project board; **iteration review** handles "was this change any good, and how to make the next one better" — the scoring and note-taking step. Together they make each version of an agent better than the last.
:::

::: tip How long until a submitted request goes live?
It depends on the request's complexity and the owner's schedule. You can always see where it stands in the evolution swimlane view (Planning → Executing → Validating → Released).
:::

::: warning Check the context before you score
When scoring a review, the "Conversation," "Current prompt," and "Past suggestions" on the right help you judge more accurately. Don't score from memory alone — look at what actually happened first.
:::
