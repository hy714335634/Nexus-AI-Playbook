---
title: Extend Agent with Tools
sync:
  source_commit: 9d40a32f2bad2c7858b3ed0cfb4390e1bd603a30
  source_files:
    - api/v2/routers/agent_tools.py
    - tools/**
  generated_at: 2026-07-12T14:19:12+00:00
  generated_by: docs-sync v2
---

# Extend Agent with Tools

Talking isn't enough — an Agent needs to be able to *act*. **Tools** are an Agent's individual skills: doing math, reading and writing files, fetching web pages, generating images, checking the time, calling external services, and more. Whatever tools you give an Agent are exactly what it can do for you. This page explains where an Agent's abilities come from and how to give it more.

::: tip Who this is for
Business folks in marketing, operations, analytics, support, and the like. All you need is to be able to click around in a browser — no technical background required. A few more advanced steps (such as connecting an external tool server) will point out where a technical colleague can help.
:::

## Where an Agent's Abilities Come From

The tools an Agent can use come from four sources:

| Source | What it is | What you do |
| --- | --- | --- |
| **Built-in tools** | Basic abilities the platform ships with, ready to use | Just select them |
| **Generated tools** | Tools the platform builds for you from a plain-language request | Build first, then select |
| **Imported tools** | Ready-made tools you or a colleague bring in from outside | Import first, then select |
| **MCP servers** | Connect an external "tool server" that brings in a whole set of tools at once | Add the server, then select the tools it brings |

The first three are managed in the **Tool Library**, which this page [points you to later](#build-or-import-your-own-tools); MCP servers are the main focus here.

## Open the Capability Center

Everything you can use to extend an Agent lives in the **Capability Center**.

1. Click **Capability Center** in the left menu.
2. There are three tabs across the top: **Tools** / **Skills** / **MCP Servers**.

![ability-tools](/images/ability-tools.png)

- **Tools**: browse, search, build, and import individual tools (see [Tool Library](./tools.md)).
- **Skills**: equip an Agent with ready-made skill packs (see [Skill Library](./skills.md)).
- **MCP Servers**: connect external tool servers to bring in a batch of tools at once.

## What Built-in Tools Can Do for an Agent

The platform ships with a large set of ready-to-use built-in tools covering common everyday scenarios. They're grouped below by purpose so you can quickly tell which kind you need:

| Category | What it can do |
| --- | --- |
| File operations | Read, create, and edit files |
| Web access | Fetch web pages, call external services to pull data |
| Multimedia | Read and analyze images, generate images, generate videos, convert text to speech |
| Knowledge & memory | Search a knowledge base, remember context |
| Running code | Run code for calculations and data processing |
| System & environment | Handle operations tied to the runtime environment |
| Cloud services | Interact with cloud services |
| Browser automation | Automatically open pages, click, fill in, and turn pages |
| Multi-Agent collaboration | Have several Agents divide the work and orchestrate a flow |
| Utilities | Do math, check the current time, and so on |

::: tip You don't need to memorize tool names
There's no tool list to learn. When you create or update an Agent, just describe what you need in plain language and the platform picks the right tools for it. This table only gives you a sense of what the platform can broadly do.
:::

## Assign Tools to an Agent

A tool doesn't run on its own — it's **assigned to an Agent, which then calls it automatically while working**. There are two moments to give an Agent new abilities:

- **When creating it**: describe in plain language what you want the Agent to do, and the platform automatically picks the tools it needs during the build. See [Create an Agent](./create-agent.md).
- **After creating it**: if you notice an Agent is missing an ability, describe the improvement in one sentence on its detail page (for example, "I'd also like it to pull tables out of web pages") and let the platform update it. See [Manage Agents](./manage-agents.md).

::: tip Do I have to tick tools one by one?
Usually not. The easiest approach is to clearly state "what I want it to do" and let the platform pair up the tools. You only need to care about the result, not which tools it uses.
:::

## Worked Example: Give a Support Agent "Check Inventory"

Imagine you already have a product support Agent that handles questions about specs, pricing, and returns. Lately, though, customers keep asking "Is this still in stock?" or "How many are left in blue?" — and the Agent can't answer because it has no inventory-checking ability.

Here's what you do:

1. Open **Capability Center** in the left menu and click the **Tools** tab at the top.
2. Search for "inventory" in the tool library — if your team already prepared an inventory tool, you'll find it right here.
3. If nothing comes up, click **Build Tool** and type a one-sentence description, for example: "Look up real-time stock quantity by product SKU." The platform builds the tool for you automatically.
4. Go back to your product support Agent's detail page and tell it: "I also want you to check real-time inventory by SKU." The platform assigns the new tool to it.
5. Head to the [Chat page](./chat.md) and try it — send "Is SKU-2046 in stock?" The Agent can now report the exact quantity available.

::: tip This is "hot-plugging" a capability
The Agent is already live, already talking to customers. You don't have to rebuild it — just assign the new tool and it **immediately** starts using it. This is a core strength of the Nexus-AI platform: add new abilities to an Agent at any time, with no downtime and no rebuild required.
:::

## Bring In More Tools with MCP Servers

Some abilities come from an **external tool server** — for example, a service dedicated to looking up references, connecting to a data source, or integrating with a particular system. Connect one of these servers and you add its whole set of tools to the platform at once, which you can then assign to your Agents just like any other tool.

::: warning This is a more advanced feature
Adding an MCP server takes some technical details (how to connect to the server, the command to start it, and so on), usually provided by the technical colleague who set it up. If you just want one more ordinary ability for an Agent, [building a tool](./tools.md#build-your-own-tool) is simpler.
:::

### View connected servers

1. Click the **MCP Servers** tab at the top of the **Capability Center**; the page is titled "MCP Server Management".
2. The list shows each connected server and whether it's **enabled** or **disabled**.
3. A search box at the top lets you find servers by name, command, or address.

![ability-mcp](/images/ability-mcp.png)

Each server card has a row of action buttons:

| Button | What it does |
| --- | --- |
| Test connection | Check whether the server is reachable right now |
| View tools | See which tools the server provides |
| Edit | Change the server's connection details |
| Enable / Disable | Turn the server on or off temporarily |
| Delete | Remove the server |

### Add a server

1. Click **Add Server** in the top-right of the MCP Servers page to open the "Add MCP Server" window.
2. There are two ways to fill it in: **Manual** and **Paste config**. If a technical colleague gave you a ready-made config, "Paste config" is quickest; otherwise use "Manual" and fill in each field.
3. When filling it in manually, provide the following (use the exact values your technical colleague gives you):

| Field | What to enter |
| --- | --- |
| Server name | A memorable name for the server, e.g. `aws-docs` |
| Transport type | One of three connection methods (STDIO / SSE / HTTP) — pick the one your colleague specifies |
| Command | The command used to start the server |
| Arguments | Arguments that follow the command, separated by spaces |
| Environment variables (optional) | Add name-and-value pairs as needed; click "+ Add environment variable" for more |
| Description | One line describing what the server is for |
| Scope | Choose **Shared** (everyone on the team can use it) or **Private** (only you) |

4. Only once all required fields are filled does the "Add Server" button become clickable. Confirm the details and click it to finish (click "Cancel" to back out).


Once added, the server appears in the list. Use "View tools" to see which new tools it brings in, after which those tools can be assigned to Agents like any other tool.

::: tip What if it won't connect?
First use "Test connection" on the server card to check reachability. If it can't connect, the connection details are most likely wrong — send the config to the colleague who provided the server to double-check, or ask them to fill it in again for you.
:::

## Build or Import Your Own Tools

When built-in tools and MCP servers aren't enough, you can also have the platform **build** a custom tool for you, or **import** a ready-made tool file:

- **Build a tool**: on the **Tools** page, click "Build Tool", describe the tool you want in one sentence, and the platform builds it. The result shows up under "Generated".
- **Import a tool**: on the **Tools** page, click "Import Tool" to bring in a ready-made tool file; it shows up under "Imported".

For step-by-step instructions on both, see [Tool Library](./tools.md).

::: warning Some tools need a "key" to work
Some imported tools need a **key** bound to them (like a key to access an external service) before they'll work. If a tool says it "requires a key", go to Key Management under **Business Integration** to bind the right key. See [Integration Center](./integration-center.md).
:::

## FAQ

**Do I need to figure out which tools an Agent should use myself?**
No. The easiest approach is to clearly state "what I want the Agent to do", and the platform picks and pairs the tools automatically. The category tables here just help you understand what the platform can broadly do.

**Built-in tools or MCP servers — which should I use?**
Check whether built-in tools are enough first — they cover the vast majority of common needs and work out of the box. You only need MCP servers when you have to connect to a specific external server, which usually takes connection details from a technical colleague.

**Why won't an MCP server connect?**
Use "Test connection" on the server card to check. A failure usually means the connection details (command, arguments, address, and so on) are wrong — hand the config to the colleague who provided the server to verify.

**Will the tools I bring in stay available?**
Yes. Added MCP servers and built tools are all kept — they're still there next time you log in, and you can assign them to different Agents again and again.

## Related Pages

| What you want to do | Where to look |
| --- | --- |
| Browse the tool library, search or build a tool | [Tool Library](./tools.md) |
| Equip an Agent with ready-made skill packs | [Skill Library](./skills.md) |
| Understand how tools are auto-selected during Agent creation | [Create an Agent](./create-agent.md) |
| Test your Agent after adding tools | [Chat with an Agent](./chat.md) |
| Set up credentials that external tools need | [Integration Center](./integration-center.md) |
