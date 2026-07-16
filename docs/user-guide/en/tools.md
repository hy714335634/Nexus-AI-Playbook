---
title: Tools
sync:
  source_commit: 9d40a32f2bad2c7858b3ed0cfb4390e1bd603a30
  source_files:
    - api/v2/routers/agent_tools.py
    - nexus_utils/tool_path.py
    - tools/system_tools/agent_build_workflow/tool_template_provider.py
    - web/app/(main)/ability/tools/**
  generated_at: 2026-07-12T13:39:24+00:00
  generated_by: docs-sync v2
---

# Tools

Tools are an Agent's "skills" — things like doing math, reading files, fetching web pages, generating images, or checking the time. Whatever tools you give an Agent, those are the things it can do for you. The **Tools** page is where you see which ready-made tools the platform offers, find the one you need, and build or import tools of your own.

::: tip Who this is for
Business folks in marketing, operations, analytics, support, and the like. All you need is to be able to click around in a browser — no technical background required. Building a tool is the same: describe what you want in one sentence and the platform builds it for you.
:::

## Open the Tools page

There are two ways in:

1. Click **Capability Center** in the left menu, then click **Manage** on the "Tools" card.
2. Or open the Tools page directly.

Once inside, the page is titled "Agent Tools" with three tabs across the top: **Tools** / Skills / MCP Servers. This page covers the **Tools** tab only.

![ability-tools](/images/ability-tools.png)

## Read the tools list

From top to bottom, the Tools page has these main parts:

- **Top-right buttons**: **Import Tool** and **Build Tool** — for adding a ready-made tool, and for having the platform build a new one for you.
- **Search box**: type a keyword to find a tool fast.
- **A row of type buttons**: All / Built-in / Generated / System / Template / Imported.
- **Category dropdown**: filter by purpose (such as file operations, web requests, and so on).
- **Tool cards**: the main area shows a card per tool, each with the **tool name** and a **one-line description** telling you what it does.
- **The count**: the page shows the total number of tools, and how many of them are built-in versus imported (for example, "255 tools · 31 built-in · 0 imported").

::: tip The card alone tells you enough
A tool's name plus its one-line description is usually all you need to tell whether it's the one you want — no need to open each one.
:::

## The types of tools

That row of buttons up top groups tools by **where they come from**. Click any one to see just that kind; click **All** to see everything.

| Type | What it is |
| --- | --- |
| Built-in | The platform's ready-to-use basics — math, reading and writing files, fetching web pages, generating images, checking the time |
| Generated | Tools the platform built for you earlier via **Build Tool** |
| System | Internal tools the platform relies on to run |
| Template | Sample tools you can reference or draw on when building |
| Imported | Tools you or a colleague prepared elsewhere and brought in |

## Find a tool

Once there are a lot of tools, use these to zero in quickly:

1. **Search by name or description**: type any fragment in the "Search tools..." box and the list narrows as you type.
2. **Filter by type**: click one of the type buttons (Built-in, Generated, and so on) to see just that kind.
3. **Filter by purpose**: open the "All Categories" dropdown and pick a purpose, for example:

| Category | Rough purpose |
| --- | --- |
| File Operations | Read, write, and edit files |
| Web & Network | Reach web pages and online services |
| Multi-modal | Work with images, audio, and video |
| RAG & Memory | Retrieve knowledge and remember information |
| Code Interpretation | Run code to compute things |
| Shell & System | System- and environment-related actions |
| AWS Services | Interact with cloud services |
| Browser Automation | Automatically operate browser pages |
| Agents & Workflows | Coordinate multiple Agents and orchestrate flows |
| Utilities | Small helpers like math and checking the time |

Search, type, and category stack together to narrow the list as much as you like.

## Build your own tool

When the ready-made tools aren't enough, describe what you need in one sentence and let the platform build a tool just for you — just like building an Agent, with no coding at all.

1. Click **Build Tool** in the top-right of the Tools page. The "Build Tool" window opens.
2. In the **Tool requirement** box, use plain language to spell out what you want the tool to do. The more specific, the better — for example: "Create a tool that returns the current date and time for a given time zone; it takes a time-zone name (like Asia/Shanghai) and returns that zone's current date and time."
3. **Tool name (optional)** — fill it in or leave it blank; if blank, the platform names it for you.
4. When it looks right, click **Start Build** (click **Cancel** to back out).

::: info Real scenario: build a certificate-expiry checker in one sentence
Say you manage your company's website and need your Agent to watch whether any domain certificates are about to expire. All you write in the **Tool requirement** box is:

> Build a tool: given a list of domain names, check the SSL certificate expiry date for each one, and output the list of domains expiring within 30 days

Click **Start Build**, wait a few minutes, and the platform produces a fully working tool — no coding, no technical know-how required. Assign this tool to your Agent and from then on it can check certificates for you automatically.
:::

![tool-build-dialog](/images/tool-build-dialog.png)

After you click **Start Build**, the page **jumps straight** to a project detail page where you can watch the build progress step by step.

![tool-project-detail](/images/tool-project-detail.png)

::: tip How long does a build take?
Anywhere from a few minutes to a few tens of minutes, depending on how complex the tool is. You don't have to watch it — go do something else and come back for the result; the progress is kept. Once it's done, the tool shows up under **Generated** in the tools list.
:::

## Import a ready-made tool

If you or a technical colleague already has a ready-made tool file, you can bring it in directly.

1. Click **Import Tool** in the top-right of the Tools page.
2. In the window that opens, provide the tool file as prompted.
3. The platform checks it first, then adds it to the library once it's clear — it appears under **Imported**.

::: tip This one is more advanced
Importing a tool requires a ready-made tool file, usually prepared by a technical colleague. If you just want a new tool, [Build your own tool](#build-your-own-tool) above is simpler — describe what you need and the platform builds it.
:::

::: warning Some tools need a "key" to work
Some imported tools need a **key** bound to them (think of it as a key that unlocks access to an outside service) before they'll work. If a tool says it "requires a key," go to Key Management under [Integration Center](./integration-center.md) and bind the matching key.
:::

## Related pages

- [Skills](./skills.md) — what is the difference between skills and tools? A tool is a single action (like "check a certificate"), while a skill is an end-to-end workflow (like "produce a full competitor analysis report").
- [Extend an Agent with Tools](./extend-agent-with-tools.md) — how to assign tools you have built to an Agent.
- [Create an Agent](./create-agent.md) — when you create an Agent, the platform automatically designs and assigns appropriate tools based on your description.
- [Integration Center](./integration-center.md) — some tools need access credentials for external services (keys) bound to them; manage those here.

## FAQ

**Built-in, Generated, System… what's the difference between all these types?**
In short: **Built-in** tools come with the platform and work right away; **Generated** tools are the ones you had the platform build; **Imported** tools were brought in from elsewhere; **System** and **Template** tools are more for the platform's internal use and you rarely touch them day to day. To find something you can use right now, start with Built-in.

**Will a tool I build get lost?**
No. A finished tool stays under **Generated**, is still there next time you sign in, can be reused as often as you like, and can be assigned to your Agents.

**What if a build fails?**
Check the project detail page to see which step it stalled at; if it really failed, start the build again or describe your requirement more clearly. If it still won't work, contact your administrator.

**How do I actually use these tools?**
A tool doesn't run on its own — you assign it to an Agent, which then calls it automatically while getting work done. All you do is pick the tools you want when you create or edit an Agent, and leave the rest to the Agent. See [Extend an Agent with Tools](./extend-agent-with-tools.md) for the step-by-step.
