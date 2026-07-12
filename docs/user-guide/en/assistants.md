---
title: Helper Assistants
sync:
  source_commit: 9d40a32f2bad2c7858b3ed0cfb4390e1bd603a30
  source_files:
    - prompts/system_agents_prompts/helper_agents/**
    - web/components/helpers/**
  generated_at: 2026-07-12T13:54:35+00:00
  generated_by: docs-sync v2
---

# Helper Assistants

Nexus builds a set of AI helpers into several pages, collectively called "Nexus Assistants." They stand by on the page, and when you ask a plain-language question or say what you want to do, they look up data, give advice, or generate content for you — no technical knowledge, no parameter names to memorize.

Different pages have helpers good at different things:

| Assistant | Where it appears | What it does for you |
|-----------|-----------------|----------------------|
| Ops Assistant | Service Status page | Check whether each service is running, troubleshoot issues, generate a diagnostic report |
| Config Assistant | Config Management page | Find settings in plain language, explain what a setting does and the impact of changing it, suggest optimizations |
| Audit Assistant | Audit Trail page | See who changed what and when, spot abnormal logins, generate a compliance report |
| App Builder | App Center "New App" | Turn your description into a ready-to-publish app page automatically |
| Mission Publisher | Task publishing entry | Turn a one-sentence goal into an executable task plan |

::: tip You never have to write anything technical
Every built-in helper works on "you say what you need, it delivers." Just describe it in plain language and leave the rest to the helper.
:::

![settings-config](/images/settings-config.png)

## What the helper looks like and how to open it

On a page that supports a helper, a softly glowing **dot** sits in the bottom-right corner — that's the Nexus Assistant entry point.

- **Open**: Click the dot, and a chat panel slides out on the right.
- **Move**: Press and drag the dot; when you let go it snaps to the nearest left or right edge of the screen.
- **Pin as a button**: Right-click the dot and choose "Pin as button" to turn it into a regular on-page button; right-click and choose "Back to floating dot" to switch it back.

Once the panel is open, you'll see:

1. A "Switch to centered large window" button at the top — on a small screen or with a lot of content, click it to move the panel to the center of the screen and enlarge it.
2. A few **suggested questions** — when you're not sure what to ask, just click one; it's the quickest option.
3. An input box at the bottom — type your own question; the "Send" button becomes clickable once you enter text.

## How to use any helper

Every helper works the same way:

1. Click the helper dot in the bottom-right corner.
2. Click a suggested question, or type your question in plain language and click "Send."
3. The answer appears bit by bit (the helper is thinking and answering in the background — just wait a moment).
4. Some answers come with a **clickable button** underneath (such as "View today's login records") — click it to jump straight to the matching page or run the matching action.

::: warning Answers are based on the real data on the current page
The helper answers only from what you're currently viewing (such as the selected time range or the current system state) — it never makes things up. If it says "no matching records in the current range," just switch to a different time range or reword your question.
:::

## Ops Assistant

Open it from the bottom-right corner of the **Service Status page** (Admin: Service Status) to see whether each service is running normally and to troubleshoot issues.

**What it can do for you:**

1. Open the helper and you'll see a few common questions, such as "Why isn't the worker consuming messages?" or "Which service has been throwing errors lately?"
2. You can also just ask "How is each service running right now?"
3. The helper returns a **service status table** listing whether each service is running, the resources it's using, and more — so you can spot problems at a glance.

![ops-helper](/images/ops-helper.png)

::: warning Restarting a service needs your confirmation
If you ask the helper to restart a service, it won't act directly — it gives you a **confirmation button** instead, and the restart happens only after you click to confirm. This prevents mistakes. Some critical services can't be restarted through the helper, and it will politely explain why.
:::

::: tip Diagnostic reports can be downloaded
Ask the helper to "generate a diagnostic report," and it will put together a complete report with a download button underneath — click it to save the report locally.
:::

## Config Assistant

On the **Config Management page** (Settings: Config Management), the Config Assistant is built into the "Just tell me what to tune" section at the top of the page; you can also click the helper dot in the bottom-right corner to open a chat.

**What it can do for you:**

1. In the "Just tell me what to tune" input box, describe your goal in plain language — for example, "reduce usage cost," "conversations keep losing context," or "which changes need a restart" (these are also ready-made suggestion buttons; just click one).
2. Click "AI Search," and the helper finds the relevant settings, explaining what each one does, whether the current value is reasonable, and what changing it would affect.
3. Each setting also has a "Ask AI: what it does and the impact of changing it" button that explains that specific setting.

![config-helper](/images/config-helper.png)

::: tip Nothing found? Reword it
If it says "0 matching parameters found," nothing matched — reword your query or try a different phrasing, and you'll usually get results.
:::

## Audit Assistant

Open it from the bottom-right corner of the **Audit Trail page** (Settings: Audit Trail) to quickly see "who did what, and when," and whether anything looks abnormal.

**What it can do for you:**

1. Open the helper and just ask, "What login records are there today?", "Who changed the config during this period?", or "Any failed logins or unauthorized attempts?"
2. The helper gives you a **clear summary**: for example, how many logins today, by whom, from which sources — and it flags whether anything looks abnormal.
3. Below the summary there's often a button (such as "View today's login records") — click it to jump straight to the filtered record list.

The panel also has three shortcut buttons for common tasks:

- **Interval Summary**: A concise summary of activity within the current time range.
- **Generate Compliance Report**: A formal compliance audit report.
- **Send to SNS**: Send the result out to notify the people involved.

![audit-helper](/images/audit-helper.png)

::: tip Results follow the time range you pick
All three shortcut actions work off the time range you select on the page (Last 7 days / 30 days / 90 days), so pick the range first, then click.
:::

## App Builder

The App Builder isn't a floating dot — it's the engine behind **App Center's "New App" quick create**. You describe the kind of app you want, and it generates a ready-to-publish page automatically.

1. In App Center, click "New App," choose "Quick Create," and click "Next."
2. Pick an Agent to use, and click "Next."
3. Fill in the "App name," and in "Scenario and UI requirements" describe in plain language who the app is for, what inputs it needs, and what kind of interface you want; then click "New App."
4. Click "Start Design," and the page shows "Generating app — N characters generated" in real time — just wait.
5. When it's done, the app becomes "Ready," you can see a live preview, and you're set to publish.

::: tip It takes a few minutes
Automatic generation usually takes a few minutes — feel free to do something else in the meantime. For the full create-and-publish steps, see the "App Center" chapter.
:::

## Other built-in assistants

A few more helpers step in automatically while you're doing certain tasks, so you don't have to go looking for them:

- **Mission Publisher**: At the task publishing entry, state a goal in one sentence (such as "check the data source for anomalies every day"), and it first confirms a few key points with you via multiple-choice questions, then drafts a complete task plan for you to confirm.
- **Tool Review Assistant**: When you upload scripts to register as tools, it automatically reviews them and puts together a tool list with improvement suggestions.
- **Skill Creator**: When you turn a conversation into a reusable skill, it automatically distills the skill content for you to confirm and save.

::: tip Plans and results take effect only after you confirm
Everything these helpers produce is a **draft** — task plans, tool lists, and skill content are all shown to you first, and nothing is actually created or saved until you review it and click confirm. So feel free to let the helper suggest first.
:::
