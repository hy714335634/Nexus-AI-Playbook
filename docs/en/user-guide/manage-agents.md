---
title: Managing Agents
sync:
  source_commit: 9d40a32f2bad2c7858b3ed0cfb4390e1bd603a30
  source_files:
    - api/v2/routers/agents.py
    - web/app/(main)/agents/new/page.tsx
    - web/app/(main)/agents/page.tsx
  generated_at: 2026-07-12T13:31:46+00:00
  generated_by: docs-sync v2
---

# Managing Agents

Every Agent you create lives on the **Agents list page**. This is where you find, organize, use, and maintain your Agents day to day—locating one, checking how it's doing, chatting with it, sharing it with a colleague, or deleting it when you no longer need it. It all starts here.

::: tip Who this is for
Business users in marketing, operations, analytics, support, and similar roles. All you need is a browser—no technical background required.
:::

## Opening the Agents list

Click **Agents** in the left menu to open the list page.

The top of the page shows the title **Agents** and the subtitle "Manage and monitor your Agents." In the top right are a few common buttons: **Interaction Network**, **Import Agent**, and the blue **+ Create Agent** (see [Creating an Agent](./create-agent.md) for the full walkthrough).

![agents-list](/images/agents-list.png)

## Reading the list page

Once you're on the list page, you'll see three areas from top to bottom.

**Stats bar at the top**—the big picture at a glance:

| Stat | Meaning |
| --- | --- |
| Agents | How many Agents you have in total |
| Running | How many are ready to use right now |
| Total invocations | How many times all your Agents have been used |
| Active in last 7 days | How many Agents were used in the past week |

**Agent cards**—one card per Agent, showing:

- The name
- A status tag (such as "Running") and version number
- A one-line description
- A source tag like "Local" or "Generated"
- Tags for the tools it uses (want to add more tools? See [Extending an Agent with Tools](./extend-agent-with-tools.md))
- Its invocation count and when it was last used

## Searching, filtering, and sorting

Once you have a lot of Agents, use the row of tools in the middle of the list to zero in on the one you want.

1. **Search**: type any part of a name into the "Search Agent name..." box, and the list narrows in real time.
2. **Sort**: click the **Name** dropdown to reorder by **Invocations**, **Recently active**, or **Created**.
3. **Filter by status**: click **Running**, **Offline**, or **Error** to see only Agents in that state; click **All** to clear it.
4. **Filter by type**: click **Local** or **Cloud** to filter by where the Agent is deployed.
5. **Filter by category**: click the **Category** button to open the tag panel, then check one or more tags to see only Agents with those tags.
6. **Clear**: whenever a filter is active, a **Clear** option appears on the right to return to the full list in one click.

::: tip Can't find an Agent you just created?
A new Agent only appears in the list after it finishes building, with the status "Running". If it's still building, check the [Build Progress](./build-progress.md) page to follow along.
:::

## Opening an Agent to see its details

Click any Agent card to open its detail page. Tabs at the top let you switch between different views:

- **Overview**: the Agent's description, version info, and stats like invocation count and usage.
- **Chat**: talk to the Agent right here to try it out anytime (see [Chatting with an Agent](./chat.md) for details).
- **Files**: view the files associated with the Agent.

The detail page also offers an **Export** option that packages the whole Agent for download—handy for backups or sharing.


## More actions on an Agent

On the list page, **right-click a card** (or **long-press** it on a phone or touchscreen) to open an action menu:

| Menu item | What it does |
| --- | --- |
| View details | Opens the Agent's detail page |
| Edit | Opens the detail page to change its information |
| Share | Shares the Agent with a colleague to use together |
| Create app | Uses this Agent as the basis for quickly creating an app (see [Publishing Your First App](./publish-first-app.md)) |
| Move to folder | Files it into a folder to keep things organized |
| Delete | Deletes the Agent (see [Deleting an Agent](#deleting-an-agent) below) |

### Sharing with colleagues

Click **Share** in the menu to open the sharing settings window. Choose who to share with and what permissions to grant; once you confirm, they can see and use the Agent.

### Moving to a folder

As your Agents pile up, use folders to sort them. Click **Move to folder** in the menu and pick a destination folder.

## Importing an Agent

If you have an Agent file someone exported, you can import it directly.

1. Click **Import Agent** in the top right of the list page.
2. In the window that opens, choose the Agent file to import.
3. Follow the prompts to confirm. Once imported, it appears in your list.

## Deleting an Agent

When you no longer need an Agent, you can delete it.

1. Right-click (or long-press) the card and choose **Delete**.
2. A confirmation window explains what will be removed (the Agent's records, chat history, and related data).
3. The window has extra options you can check:
   - **Delete local files**: also removes the files associated with this Agent.
   - **Delete cloud resources**: shown only for "Cloud" type Agents; check it to also clean up the resources it uses in the cloud.
4. Click **Confirm delete** when you're sure. Click **Cancel** to back out.

::: warning Deletion can't be undone
Once deleted, the Agent and its related data are gone for good. Make sure you no longer need it first. If you just want to set it aside for now, leave it be—an idle Agent doesn't do anything on its own.
:::

## Interaction Network

To see at a glance how your Agents relate to the tools they use, open the Interaction Network.

1. Click **Interaction Network** in the top right of the list page.
2. The page shows a relationship graph of your Agents, versions, and tools, and how they call and depend on each other.
3. The filter bar at the top lets you filter by category, tag, or tool type, and toggle **Show tools** and **Show versions**.
4. Click any node in the graph to see its details in the panel on the right.

![agents-network](/images/agents-network.png)

::: tip The graph is empty?
If your Agents don't call one another yet, the network graph shows up empty. That's normal—relationships appear over time as you use them more.
:::

## FAQ

::: tip What do "Running", "Offline", and "Error" mean?
"Running" means the Agent is fine and ready to use; "Offline" means it's currently unavailable; "Error" means something went wrong. When you see "Error", open the detail page to learn more, or rebuild the Agent.
:::

::: tip Can people I share an Agent with change it?
It depends on the permission you grant when sharing. In the share window you can set whether they can only view and use it, or edit it too.
:::

::: warning Can I recover something I deleted by mistake?
No. Deletion is permanent, and related data is removed along with it. For important Agents, use **Export** on the detail page to make a backup before deleting.
:::
