---
title: Dashboard
sync:
  source_commit: 9d40a32f2bad2c7858b3ed0cfb4390e1bd603a30
  source_files:
    - api/v2/routers/statistics.py
    - web/app/(main)/page.tsx
    - web/components/dashboard/**
  generated_at: 2026-07-12T13:20:52+00:00
  generated_by: docs-sync v2
---

# Dashboard

The Dashboard is the first page you see after signing in, and it's your starting point for everyday work in Nexus AI. From here you can create a new Agent with a single sentence, check the progress of ongoing builds, jump to the features you use most, and see how the platform is doing at a glance.

![dashboard](/images/dashboard.png)

## How to open the Dashboard

1. Right after you sign in, the system **takes you straight to the Dashboard**—you don't have to do anything.
2. If you're on another page, click **"Dashboard"** at the very top of the left sidebar to come back here anytime.

::: tip
The left sidebar can be collapsed. Click the collapse button at the top of the sidebar to shrink it into a single column of icons and give the main area more room; click it again to expand.
:::

## What's on the page

The Dashboard is divided into a few areas, from top to bottom:

| Area | What it does |
| --- | --- |
| Quick build area | Describe what you need in one sentence and create a new Agent right away |
| Stat cards | See running Agents, projects being built, today's usage, and the build success rate at a glance |
| Build progress | Check your recently created projects and their status |
| Quick actions | Jump straight to "Create Agent" and the tool library |
| Running Agents | See the Agents available now and how many times each has been used |

## Key numbers at a glance

Four stat cards near the top help you quickly understand the current state of the platform:

| Card | Meaning |
| --- | --- |
| Running Agents | How many Agents are currently running (and the total number of Agents) |
| Building Projects | How many projects are still being built (and the total number of projects) |
| Today's Usage | The total number of times Agents were used today |
| Build Success Rate | The share of build tasks that finished successfully |

::: info
These numbers update in real time. If you briefly see gray placeholder blocks, the data is still loading—it will appear in a moment.
:::

## Create your first Agent with one sentence

The colorful card at the top of the Dashboard is the feature you'll use most—just describe what you want in plain language, and the system turns it into an Agent for you.

1. On the card titled **"From idea to Agent, built automatically"**, find the input box in the middle.
2. **Describe what you need in one sentence**, for example: "Help me create an assistant that can analyze stock data."
3. Once you've typed something, the **"Build"** button on the right lights up automatically. Click **"Build"**.
4. The page takes you to that project's detail page, where you can follow the build progress.

If you're not sure how to phrase it, click one of the example shortcuts below the input box. The system fills the example text into the box for you, and you can edit it as needed:

- "Medical Literature"
- "AWS Quote"
- "News Digest"

::: tip How long does a build take?
After you create it, the system does a series of tasks in the background, usually about 20–40 minutes. Feel free to do something else and come back to the "Build progress" area later to check the result.
:::

::: warning
If the build didn't start, a red message appears below the card explaining why. Check that your description is complete, then click "Build" again.
:::

## Check build progress

The "Build progress" area lists your most recently created projects so you can keep an eye on how they're going.

1. Find the block titled **"Build progress"**.
2. Each item shows: the project name, its current stage, the last update time, plus a status label and a progress bar on the right.
3. Click any item to open that project's detail page and see the full details.
4. Want to see every project? Click **"View all"** in the top-right corner of the block.

::: info
If you see "No projects" here, you haven't created any projects yet. Click the link in the message to create your first Agent.
:::

## Quick actions

The "Quick actions" area offers two common shortcuts—one click takes you there:

| Shortcut | What it does |
| --- | --- |
| Create Agent | Describe your business need in natural language and create a new Agent |
| Tool Library | Browse and manage the capabilities available on the platform |

## Running Agents

The "Running Agents" area shows the Agents available now and how many times each has been used.

1. Find the block titled **"Running Agents"**.
2. Each item shows the Agent's name and its usage count; when the small dot before the name is green and pulsing, that Agent is currently running.
3. Click any Agent to open its detail page.
4. Want to see every Agent? Click **"All"** in the top-right corner of the block.

## Top action bar

The action bar at the very top of the page also gives you a few handy buttons:

- **Search box**: click to search or ask a question directly (you can also bring it up with a keyboard shortcut anytime).
- **"Create Agent" button**: highlighted in blue; click it to go to the Create Agent page.
- **Notifications button**: view system alerts.
- **Avatar**: click to open your account menu.

::: tip
"Create Agent" appears in several places on the page (the top action bar, the quick build area, and the quick actions area). They all do the same thing—click whichever is closest so you can create one on the spot.
:::
