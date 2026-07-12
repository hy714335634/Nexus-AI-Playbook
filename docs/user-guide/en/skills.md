---
title: Skills
sync:
  source_commit: 9d40a32f2bad2c7858b3ed0cfb4390e1bd603a30
  source_files:
    - agents/system_agents/skill_build_workflow/**
    - api/v2/routers/skills.py
    - web/app/(main)/ability/skills/**
  generated_at: 2026-07-12T13:42:26+00:00
  generated_by: docs-sync v2
---

# Skills

A Skill is a whole "know-how, packaged" — it bundles the how-to, the instructions, and any small tools a certain kind of task needs into one package. Giving an Agent a Skill is like hiring it an expert: for things like "make a slide deck," "work with Excel spreadsheets," or "write a PDF document," an Agent that has the matching Skill knows how to get that kind of work done step by step. The **Skills** page is where you see which ready-made Skills the platform offers, find the one you need, and build, import, or combine Skills of your own.

::: tip Who this is for
Business folks in marketing, operations, analytics, support, and the like. All you need is to be able to click around in a browser — no technical background required. Building a Skill is the same: describe what you want in one sentence and the platform builds it for you.
:::

::: info How is a Skill different from a tool?
In short: a **tool** is a single ability (like "check the time" — one action), while a **Skill** is a whole approach packaged up, often including instructions, a few tools, and reference material that teach an Agent to handle an entire kind of task. To add one small action to an Agent, use a [tool](./tools.md); to give it a whole way of working, use a Skill.
:::

## Open the Skills page

There are two ways in:

1. Click **Capability Center** in the left menu, then click **Manage** on the "Skills" card.
2. Or open the Skills page directly.

Once inside, the page is titled "Skills" with three tabs across the top: Tools / **Skills** / MCP Servers. This page covers the **Skills** tab only.

![ability-skills](/images/ability-skills.png)

## Read the Skills page

From top to bottom, the Skills page has these main parts:

- **Top-right buttons**: **Refresh**, **Import Skill**, **Combo**, and **Build Skill** — for refreshing the list, adding a ready-made Skill, combining several Skills into one group, and having the platform build a new Skill for you.
- **Search box**: type a keyword in "Search skills..." to find a Skill fast.
- **View toggle**: **Grouped** / Flat. The grouped view sorts Skills into folders by where they come from; the flat view spreads every Skill out as a field of cards.
- **Skill groups**: the main area shows a set of folders, each holding one group of Skills.

## Skill groups

In the **Grouped** view, Skills are sorted into folders, and each folder shows how many Skills it holds. The common groups are:

| Group | What's inside |
| --- | --- |
| Community Skills | A batch of ready-made, widely useful Skills that come with the platform — making slide decks, working with Excel, generating PDFs, and so on |
| System Skills | Internal Skills the platform relies on to run |
| Generated Skills | Skills the platform built for you earlier via **Build Skill** |
| Private Skills | Your own private Skills |
| An imported group | Skills you or a colleague brought in from outside as a batch appear as their own group (the group name usually carries source info) |

Click a folder's row to **expand** it and see a card for each Skill inside — each card shows the Skill's **name**, **version**, and a **one-line description**. Click again to collapse.


::: warning Don't hit the trash icon when expanding
When you move your pointer over a group's row, a **trash icon** (delete this group) appears on the right. To expand a group, click the row with the folder name; only click the trash icon when you really mean to delete the whole group. If a "Confirm delete" window pops up by accident, just click **Back** to dismiss it — nothing changes.
:::

## View a Skill

Click any Skill card (for example, `skill-creator`) to open that Skill's detail page. The Skill's name sits at the top, with **Back**, **Share**, and **More** buttons in the top-right. A row of tabs below lets you look at the Skill from different angles:

| Tab | What you see |
| --- | --- |
| Skill Details | The Skill's full write-up — what it does and how to use it, laid out with text and formatting |
| Files | A list of every file the Skill contains |
| Tools | The tools this Skill uses |
| Evals | Evaluation-related content for this Skill |
| Settings | The Skill's settings |

The page also shows the Skill's basics: source (System / Community / Generated), category, version, file count, size, and tags — enough to quickly tell whether it's the one you want.


::: tip The detail page alone tells you enough
Reading the write-up on the "Skill Details" tab is usually all you need to understand what the Skill can do and whether it fits your case — no need to dig through each file.
:::

## Build your own Skill

When the ready-made Skills aren't enough, describe what you need in one sentence and let the platform build a Skill just for you — just like building an Agent or a tool, with no coding at all.

1. Click **Build Skill** in the top-right of the Skills page. The build window opens.
2. In the requirement box, use plain language to spell out what you want the Skill to help an Agent do. The more specific, the better.
3. When it looks right, start the build.

After you start the build, the page jumps to a project detail page where you can watch the build progress step by step.


::: tip How long does a build take?
Anywhere from a few minutes to a few tens of minutes, depending on how complex the Skill is. You don't have to watch it — go do something else and come back for the result; the progress is kept. Once it's done, the Skill shows up under the **Generated Skills** group.
:::

## Import a ready-made Skill

If you or a technical colleague already has a ready-made Skill, you can bring it in directly.

1. Click **Import Skill** in the top-right of the Skills page.
2. In the window that opens, provide the Skill source as prompted.
3. The platform checks it first, then adds it to the library once it's clear — it lands in its own group.

::: tip This one is more advanced
Importing a Skill requires a ready-made Skill source, usually prepared by a technical colleague. If you just want a new Skill, [Build your own Skill](#build-your-own-skill) above is simpler — describe what you need and the platform builds it.
:::

## Combine Skills

If you often use several Skills together, you can bundle them into a **Combo** for easier management and use.

1. Click **Combo** in the top-right of the Skills page. The "Create Combo" window opens.
2. Fill in the combo's **name** and **description**.
3. In the Skill list, check the Skills you want in this combo (use the search box to find them fast), then confirm to create it.

A combo can freely pick Skills from different groups — there's no restriction by source.

## FAQ

**What's really the difference between a Skill and a tool?**
A tool is a single ability, one action (like "check the time"); a Skill is a whole approach packaged up, usually including instructions, a few tools, and reference material that teach an Agent to handle a whole kind of task. Use a tool to add one small action to an Agent; use a Skill to give it a whole method.

**How do I actually use these Skills?**
A Skill doesn't run on its own — you assign it to an Agent, which then draws on it automatically while getting work done. All you do is pick the Skills you want when you create or edit an Agent, and leave the rest to the Agent.

**Will a Skill I build get lost?**
No. A finished Skill stays under the **Generated Skills** group, is still there next time you sign in, can be reused as often as you like, and can be assigned to your Agents.

**What do the System, Community, and Generated labels mean?**
They mark where a Skill comes from: **System** are internal Skills the platform relies on to run; **Community** are the batch of widely useful ones that come with the platform; **Generated** are the ones you had the platform build. To find something you can use right away, start with Community.

**Why did a delete window pop up when I tried to expand a group?**
The trash icon on the right of a group's row is "delete group," and it sits close to the expand area, so it's easy to hit by mistake. When the "Confirm delete" window appears, just click **Back** to dismiss it — nothing changes — then click the folder-name row once more to expand it normally.
