---
title: Project Management
sync:
  source_commit: 9d40a32f2bad2c7858b3ed0cfb4390e1bd603a30
  source_files:
    - api/v2/routers/projects.py
    - web/app/(main)/projects/page.tsx
  generated_at: 2026-07-12T13:29:52+00:00
  generated_by: docs-sync v2
---

# Project Management

The Workshop is the home base for everything you create. Whenever you want the system to build you an Agent, a skill, a tool, or an app, you start here—and every project you've created stays here too, so you can come back anytime to check progress, manage it, or delete it.

![projects-list](/images/projects-list.png)

## How to open the Workshop

Click "Workshop" in the left navigation to open the Workshop page. The title at the top reads "Workshop," and the subtitle below says "Manage Agent build projects and track build progress."

## Creating something from the Workshop

At the top of the page are four colored cards, one for each kind of thing you can create. Click a card to start creating that kind:

| Card | What it builds |
| --- | --- |
| Agent | Build an intelligent Agent |
| Skill | Build a reusable Skill |
| Tool | Build a standalone tool |
| App | Build a publishable app |

How to do it:

1. Decide what you want to make, then click the matching card.
2. Clicking **Agent** takes you to a dedicated creation page (see [Creating an Agent](./create-agent.md) for the full walkthrough); clicking **Skill**, **Tool**, or **App** opens a window where you fill in your request as prompted.
3. Once you've written your request and confirmed, the system starts building in the background, step by step, and adds the project to the list below.

::: tip How long does a build take?
A full build usually takes about 20–40 minutes. You don't have to wait around—feel free to do something else and come back later to check the result. To follow each step in detail, see [Build Progress](./build-progress.md).
:::

::: warning Does clicking "App" show an upgrade prompt?
"App" (publishable apps) is an Enterprise-edition feature. If you're on the Basic edition, clicking the "App" card shows an upgrade prompt instead of opening the creation flow. The other three (Agent, Skill, Tool) are not affected.
:::

## Reading a project card

Every project you've created appears as a card lower on the page. Each card tells you the key facts about that project:

- **Name**: for example, "Chinese–English Translation Assistant."
- **Type tag**: whether it's an Agent, Skill, Tool, or App.
- **Status tag**: how far along it is (see the table below).
- **Request description**: the text you originally entered.
- **Build summary**: how many steps it has, how long it took, how much text was processed, and so on.
- **Progress**: a project that's still building shows a live completion percentage and the step it's currently on.

Common project statuses:

| Status | Meaning |
| --- | --- |
| Building | The system is making it in the background; progress updates live |
| Completed | It's done—go to the matching list page to use it |
| Failed | The build couldn't finish |
| Paused | You manually stopped the build; you can resume anytime |

## Finding a specific project quickly

Once you have a lot of projects, the filter, search, and sort controls help you locate one fast.

**View by status**: a row of status counts near the top shows how many projects are "Building," "Completed," "Failed," and the "Total." Click one to see only projects in that status.

**Filter by type**: the row of buttons beside it filters by kind—"All," "Agent," "Skill," "Tool," "App"—each with a count. If a type contains both freshly built projects and projects that were changed from an existing result, two extra buttons, "Build" and "Update," appear so you can narrow it down further.

**Search**: type a keyword into the "Search project name..." box, and the list instantly narrows to projects whose names match.

**Sort**: click the "Recent Update" dropdown to change how projects are ordered:

| Sort option | Effect |
| --- | --- |
| Recent Update | Recently changed projects appear first (default) |
| Recent Create | Newly created projects appear first |
| Name A–Z | Sort by name, ascending |
| Name Z–A | Sort by name, descending |

## Projects that update an existing result

Some projects are made by changing an earlier result (for example, upgrading an app from an older version to a newer one). Cards for these projects show a version arrow, such as "v1→v2" or "v3→v4," so you can tell at a glance which revision it is.

If the same result has been updated many times, the Workshop keeps only the most recent one in the list and folds the earlier updates away, marking the card with a small badge showing how many updates there were, so the list stays tidy. To see the full update history, click the "Update" button to expand them all.

## Opening a project to view progress

Click any project card to open that project's build progress page, where you can see the detailed progress of each step, pause or resume the build, and delete the project. For the full walkthrough, see [Build Progress](./build-progress.md).

## Common questions

**Can I close the page after creating a project?**
Yes. The build runs automatically in the background—closing the page or signing out won't interrupt it. Come back to the Workshop later and open the project to keep watching its progress.

**Why did some projects disappear after I filtered?**
They're just temporarily hidden by the filter. Switch the status or type back to "All" and clear the search box to see all projects again.

**Where do I use what I've built?**
Once a project's status turns "Completed," you can find and use what you just built on its matching list page. For example, a finished Agent appears on the [Agents list](./manage-agents.md).
