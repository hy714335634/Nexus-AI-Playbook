---
title: Dashboard
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - api/v2/routers/projects.py
    - web/src/app/(authed)/dashboard/**
  generated_at: 2026-05-08T14:54:10+00:00
  generated_by: docs-sync v2
---

# Dashboard

The Dashboard is your home page after signing in to Nexus-AI. It is the control center of the entire platform, providing a global overview, quick creation entries, and status monitoring.

![Dashboard](/images/dashboard.png)

## Quick Build

The most important feature of the Dashboard is the **Quick Build area** at the top, which lets you start creating an Agent without leaving the home page.

### How to Use

1. Enter your requirement description in the text box. For example:

   > Create an Agent that can query weather information and suggest what to wear

   > Help me create a medical literature research assistant that can search papers on PubMed and generate APA citations

2. Click the **Send button** on the right (or press Enter).
3. The system automatically creates a build project and redirects you to the [Build Progress](/using/build-progress) page.
4. Eight specialized Builder Agents begin to collaborate automatically to build your Agent.

::: tip Multimodal input
In addition to a text description, you can attach files (PDF, Excel, images, etc.) at creation time to supplement your requirement. Attachments help the AI understand your data format and business scenario more accurately.
:::

### Quick Templates

Quick templates are provided below the input box. Click a template to start a build in one click:

| Template | Purpose | Description |
|----------|---------|-------------|
| **Medical Literature** | Create a medical literature research assistant | Integrates the PubMed API; supports paper search, PDF parsing, and citation generation |
| **AWS Pricing** | Create an AWS service pricing advisor | Integrates the AWS Pricing MCP server; supports service recommendations and cost estimation |
| **News Briefing** | Create a daily news summary Agent | Supports multi-source news collection, summary generation, and categorization |

::: info
Quick template requirements are preset and trigger the fast build flow directly. If you want to customize the requirement or use guided creation mode, go to the [Create Agent](/using/create-agent) page instead.
:::

### Requirement Description Best Practices

When entering a requirement in the Quick Build area, the following tips will help you get better results.

**Recommended — specific and structured:**

> Create a data analysis Agent that can:
> 1. Read uploaded CSV and Excel files
> 2. Automatically detect data types and missing values
> 3. Generate a data summary report (including mean, median, distribution, etc.)
> 4. Answer data queries and filtering questions from the user
> 5. Reply in Chinese

**Not recommended — too vague:**

> Help me make something that analyzes data

A good requirement description should include: **what the Agent does**, **what data it processes**, **what output it produces**, and **any special requirements**.

## Data Overview

The middle area of the Dashboard shows **4 statistics cards** so you can grasp the platform status at a glance:

| Metric | Description | Meaning |
|--------|-------------|---------|
| **Running Agents** | Number of Agents currently running / Total number of Agents | Shows how many Agents are available for use. A value of 0 means you have no Agents ready yet |
| **Building Projects** | Number of build tasks in progress | Shows how many builds are running in the background. Multiple builds indicate the system is processing them in parallel |
| **Today's Business Requests** | Cumulative number of business requests all Agents handled today | Reflects Agent activity today. A higher value means more frequent usage |
| **Build Success Rate** | Success percentage across historical build tasks | Reflects overall build quality. Under normal conditions it should stay at a high level |

### How to Interpret These Metrics

- **Running Agents = 0** — You haven't created an Agent yet, or all the Agents you've created are offline.
- **Build Success Rate is lower than expected** — Your requirement description may not be clear enough. Try guided creation mode so the AI can help you refine it.
- **Today's Business Requests is high** — Your Agents are being used frequently. Pay attention to response quality and performance.
- **Many Building Projects** — The system supports parallel builds; multiple projects running at the same time do not interfere with each other.

## Recent Projects

Displays the build projects you recently created or updated, so you can track progress quickly:

| Field | Description |
|-------|-------------|
| **Project Name** | Auto-generated from the requirement description. Click to jump to the project details |
| **Build Progress** | Progress bar showing completion percentage (0–100%) |
| **Current Stage** | Shows the Builder Agent currently running (e.g. `agent_designer`, `tools_engineer`) |
| **Status Tag** | Building (blue) / Completed (green) / Failed (red) / Paused (gray) |
| **Updated At** | Time of the last status change (e.g. "17 days ago", "2 hours ago") |

**Quick actions:**
- Click a project name → jump to the [Build Progress](/using/build-progress) details page
- For completed projects → jump directly to the associated Agent

## Running Agents

Displays Agents that are currently running, with a quick entry to start a chat:

| Field | Description |
|-------|-------------|
| **Agent Name** | Name of the Agent |
| **Short Description** | Brief summary of what the Agent does |
| **Invocation Count** | Cumulative number of times the Agent has been invoked |
| **Quick Action** | The "Chat" button — start a chat test directly |

::: tip Quick chat
This is the fastest way to start a chat test. Click the "Chat" button on an Agent card to open the chat window and begin interacting.
:::

## Quick Action Entries

The Dashboard also provides the following quick entries:

| Action | Description |
|--------|-------------|
| **Create Agent** | Jump to the [Create Agent](/using/create-agent) page and use the full creation mode |
| **View All Projects** | Jump to the [Project Management](/using/projects) page to view all build projects |
| **View All Agents** | Jump to the [Agent Management](/using/manage-agents) page to manage all Agents |

## Tips

1. **Use quick templates** — If you aren't sure how to describe your requirement, starting from a template is a solid choice.
2. **Watch the build success rate** — If it's low, try guided creation mode to produce a more precise requirement description.
3. **Check recent projects regularly** — A build may take a few minutes. Do something else in the meantime and come back to check progress later.
4. **Use quick chat** — The "Running Agents" section is the fastest way to test an Agent.
