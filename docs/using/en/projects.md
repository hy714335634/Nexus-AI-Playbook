---
title: Project Management
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - api/v2/routers/projects.py
    - web/src/app/(authed)/projects/**
  generated_at: 2026-05-08T15:04:20+00:00
  generated_by: docs-sync v2
---

# Project Management

The Project Management page lists every build project and its current status. It is your control center for tracking the full lifecycle of an agent build. Open it from **Build Projects** in the left sidebar.

![Project Management](/images/projects.png)

## What Is a Project

In Nexus-AI, a **Project** is the management unit for an agent build task. Every time you create an agent, the system automatically creates a corresponding build project.

A project records the entire process from the moment you submit a requirement to the final deployment of the agent, including:

- Your original requirement description
- The execution status and artifacts of each stage
- The working logs of every Builder Agent
- The link to the final agent that was built

::: info Project vs. Agent
One project produces one agent. The project records *how* the agent was built; the agent is *the result* of the build. You can jump from a project to its agent, and from the agent detail page back to the associated project.
:::

## Project List

### Status Filters

The top of the page provides **status filter tags**. The number next to each tag shows how many projects have that status:

| Tag | Description | Color |
|------|------|----------|
| **All** | Shows every project | — |
| **Building** | Projects whose build pipeline is still running | Blue |
| **Completed** | Projects that built successfully (agent deployed) | Green |
| **Failed** | Projects that errored during the build | Red |
| **Paused** | Projects that have been paused manually | Gray |

Click a tag to switch views quickly. For example, clicking **Failed** helps you locate every project that needs attention.

### Build Status Reference

A project goes through these states during its lifecycle:

```
Create project → Pending (waiting to start) → Running (building)
                                                    ↙     ↓     ↘
                                           Completed   Failed   Paused
```

| Status | Description | What to do |
|------|------|-------------|
| **Pending** | The project is created and waiting for system resources | Wait a moment — the system starts it automatically |
| **Running** | Eight Builder Agents are collaborating on the build | Watch the real-time progress |
| **Waiting Human** | Guided-creation mode is waiting for your answer | Go to the Build Progress page and answer the AI's question |
| **Completed** | All 9 stages finished successfully | Start using the agent |
| **Failed** | A stage failed | Check the error log; you may need to edit the requirement and retry |
| **Paused** | You paused the build manually | Resume it or abandon it |

### Search and Sort

- **Search box** — Type keywords to search by project name
- **Sort order** — Defaults to most-recently-updated; other options include creation time

### Project Card

Each project is shown as a card with rich information:

| Field | Description | Example |
|------|------|------|
| **Project name** | Name generated automatically from the requirement | "Medical Literature Research Assistant" |
| **Status tag** | Current build status | Completed (green) / Building (blue) / Failed (red) |
| **Created at** | When the project was created | "17 days ago", "2 hours ago" |
| **Current stage** | The Builder Agent currently running or the last one that ran | "agent_deployer", "tools_engineer" |
| **Stage progress** | Completion of the 9 stages | Each stage marked with ✅ / ⏳ / ❌ |
| **Progress bar** | Overall completion percentage | 0% – 100% |
| **Percent complete** | Exact percentage | "100%", "86%", "44%" |

### Stage Icon Meanings

Each project card shows 9 small icons, one per build stage:

| Icon | Status | Description |
|------|------|------|
| ✅ Green check | Completed | The stage finished successfully |
| ⏳ Yellow in-progress | Running | The stage is currently executing |
| ❌ Red cross | Failed | The stage errored |
| ⬜ Gray blank | Not started | The stage has not run yet |

At a glance, these icons tell you exactly how far the build has progressed.

## View Project Details

Click the **`>`** arrow on the right side of a project card to open its detail page. The detail page is the same as the [Build Progress](/using/build-progress) page, showing:

- Detailed execution information for every stage
- Stage artifacts and resource files
- Execution logs from the Builder Agents
- Token usage and time statistics

## Project Actions

### New Project

Click **+ New Project** in the top-right corner to create a new build project directly. This is equivalent to opening the [Create Agent](/using/create-agent) page.

### Other Actions

| Action | Description |
|------|------|
| **View details** | Open the project's Build Progress page to see each stage's output |
| **View agent** | After a successful build, jump to the associated agent detail page |
| **Refresh list** | Manually refresh the project list to see the latest status |

::: tip
After a project completes, the associated agent automatically appears on the [Agent Management](/using/manage-agents) page. You can jump there directly from the project list.
:::

## Best Practices

### Pay Attention to Failed Projects

Failed builds deserve a closer look. Click a failed project to see details; common resolutions:

| Failed stage | Common cause | Recommended action |
|----------|----------|----------|
| Requirements Analysis | Requirement is too vague | Recreate using guided-creation mode |
| Tool Development | Required API is unavailable | Check the API service, or remove that feature from the requirement |
| Code Development | Requirement is too complex | Simplify the requirement and build in smaller steps |
| Developer Manager | Code quality did not meet the bar | The system usually auto-retries; if it keeps failing, simplify the requirement |
| Deployment | Deployment environment issue | Contact the administrator to check the deployment environment |

### Learn from Completed Projects

Completed projects are a valuable reference:

- Review each stage's artifacts to see how the platform turned your requirement into an agent
- Read the requirement documents and architecture designs to learn how to describe requirements more effectively
- Compare build time and token usage across projects to understand how complexity maps to resource cost
