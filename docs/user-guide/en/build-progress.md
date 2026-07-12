---
title: Build Progress
sync:
  source_commit: 9d40a32f2bad2c7858b3ed0cfb4390e1bd603a30
  source_files:
    - api/v2/routers/projects.py
    - api/v2/routers/workflows.py
    - config/workflows.yaml
    - web/app/(main)/projects/page.tsx
    - worker/handlers/build_handler.py
    - worker/main.py
  generated_at: 2026-07-12T13:25:03+00:00
  generated_by: docs-sync v2
---

# Build Progress

After you submit a request to create something, the system builds it step by step in the background. The build progress page is where you watch that happen—you can see which step the project has reached, how long each step took, and whether the build finished successfully.

![project-detail-stages](/images/project-detail-stages.png)

## How to open the build progress page

There are three ways to reach a project's build progress page:

1. **Right after you submit a request**: once you click "Build," the system **takes you straight to** that project's build progress page—you don't have to do anything.
2. **From the Dashboard**: in the "Build progress" area of the Dashboard, click any project card.
3. **From the project list**: open the projects list page and click the project you want to view.

::: tip Is the page blank when it first opens?
The project page takes a few seconds to load. If you see a blank screen or a loading animation at first, wait a moment and the full content will appear on its own.
:::

## Top of the page: project name and action buttons

The very top of the page shows the project's name (for example, "Chinese–English Translation Assistant"), with a few action buttons on the right:

| Button | What it does |
| --- | --- |
| Back | Return to the previous page |
| Pause | Temporarily stop the build in progress |
| Delete | Delete this project (red button—use with care) |

## Key numbers at a glance

Below the project name are four stat cards that help you quickly understand the overall build:

| Card | Meaning |
| --- | --- |
| Total Time | How long the build has taken so far, from start to now |
| Input Tokens | The amount of text the system read during the process |
| Output Tokens | The amount of text the system produced during the process |
| Tool Calls | How many times an external capability was used during the process |

::: info
"Input Tokens" and "Output Tokens" are units that measure how much text was processed—the bigger the number, the more content was handled. You don't need to worry about the exact figures; they just give you a sense of the scale of this build.
:::

## Reading the build stage timeline

The main part of the page is a **top-to-bottom stage timeline** that breaks the whole build into a series of steps. The system works through them from first to last, and you can watch in real time where it currently is.

Each stage card shows:

- The step's number and name (for example, "Intent Recognition," "Requirements Analysis," "System Architecture Design")
- Its current status label
- How long that step took
- The amount of text that step processed

There are four possible statuses:

| Status | Meaning |
| --- | --- |
| Completed | This step finished successfully |
| Running | The system is working on this step now |
| Waiting | This step's turn hasn't come yet; it's in the queue |
| Failed | This step couldn't finish (see "If a stage fails" below) |

::: info
Different kinds of projects have different numbers of steps and different names. Building an Agent goes through steps like intent recognition, requirements analysis, and architecture design, while building a tool follows a different set of steps. You don't need to memorize the names—just watch them turn "Completed" one by one down the timeline.
:::

## How long does a build take?

::: tip
A full build usually takes about 20–40 minutes. You don't have to stay on the page the whole time—feel free to do something else and come back later to check the result. The whole process runs automatically in the background, and the build continues even if you close the page.
:::

## Pausing and resuming a build

If you want to stop a build temporarily:

1. Click the "Pause" button in the top-right corner of the page.
2. The step currently in progress stops, and the project's status changes to "Paused."
3. When you're ready to continue, come back to this page to resume the build. After resuming, the system picks up where it left off—**completed steps are not redone**.

## If a stage fails

If a step can't finish, its status label changes to "Failed," and a message appears at the top of the project explaining the problem.

1. Read the failure message on the page to understand the general cause.
2. You can have the system **restart from the step that failed**—the steps already completed are kept, so nothing starts over from scratch.
3. If it keeps failing after several attempts, check whether the description you originally entered was clear and complete, and create a new project if needed.

::: warning
The "Delete" button permanently removes this project and its build records, and this can't be undone. Only use it when you're sure you no longer need the project.
:::

## Common questions

**Can I close the page while a build is running?**
Yes. The build runs automatically in the background—closing the page or signing out won't interrupt it. Just reopen the project later to keep watching its progress.

**Why do some steps stay in "Waiting" on the timeline?**
The system does one step at a time, and later steps wait in the queue. They start automatically once the steps before them are done.

**Where do I find the result after a build completes?**
Once every step turns "Completed" and the project status shows "Completed," you can find and use what you just built on its list page (such as the Agents list).
