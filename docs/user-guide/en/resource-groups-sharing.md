---
title: Resource Groups & Sharing
sync:
  source_commit: 9d40a32f2bad2c7858b3ed0cfb4390e1bd603a30
  source_files:
    - api/v2/routers/groups.py
    - api/v2/routers/resource_groups.py
    - api/v2/routers/resource_shares.py
    - web/app/(main)/resource-groups/**
  generated_at: 2026-07-12T13:50:33+00:00
  generated_by: docs-sync v2
---

# Resource Groups & Sharing

**Shared Resources** lets you put the things you create — agents, skills, projects, and more — into "folders," then share them with a colleague or a whole department all at once. Your teammates don't need you to forward items one by one; they just open the folder and see everything inside.

::: tip When to use it
Whenever you want to hand a related set of resources to someone else. For example, put your "Support Assistant" and the few skills it relies on into one folder, share it with the support team, and everyone on the team can use it right away.
:::

## Scenario: sharing a content-creation Agent across marketing

Imagine someone on your marketing team spent two days building a "Content Creator" agent — it generates social media copy based on product highlights, and comes with a custom "Brand Voice Check" skill and a "Competitor Analysis" tool. Without sharing, the other 15 team members would each have to build their own, or keep asking for links.

Shared Resources solves this:

1. That person creates a folder called "Marketing Content Kit."
2. They add the "Content Creator" agent and its two companion skills to the folder.
3. They click **Share**, pick the "Marketing" user group, and set the permission to **Viewer**.
4. All 15 team members immediately see the folder under **Shared with me**, open it, and start chatting with the agent — no one has to rebuild anything.

This is the core value of Shared Resources: **one person builds it, the whole team benefits, ready to use instantly.**

## Open "Shared Resources"

1. Click **Shared Resources** in the left navigation bar.
2. The page opens with the title **Shared Resources**.

![resource-groups-list](/images/resource-groups-list.png)

If you haven't created any folders yet, an empty state appears in the middle of the page with a **Create your first folder** button.

## What's on the page

At the top is an overview bar that sums up your current situation:

| Item | Meaning |
| --- | --- |
| Folders | Total number of folders you can see |
| Resources | Total number of resources across those folders |
| Shared | Number of folders you've shared with others |

To the right of the overview bar are three permission labels (Viewer, Editor, Owner). Hover over each to see what that permission means.

Folders below are split into two groups:

- **Created by me** — folders you created yourself.
- **Shared with me** — folders others shared with you.

Each folder is shown as a card that indicates:

- A badge in the top-right corner: **Shared** (green — shared with others) or **Private** (gray — only you).
- A row of small icons previewing which resource types are inside.
- At the bottom: the resource count and member count; if you're the creator, an **Owner** tag appears.

## Create a folder

1. Click the **Create folder** button in the top-right corner (in the empty state it's **Create your first folder**).
2. In the **Create new folder** dialog, fill in:
   - **Folder name** (required).
   - **Folder description** (optional — a short line on what the folder is for).
3. Click **Create**. Once the dialog closes, the new folder appears immediately under **Created by me**.


::: tip
A folder is empty when first created. Next you'll add resources to it, then decide who to share it with.
:::

## Add resources to a folder

When you put resources into a folder, keep two rules in mind:

::: warning You can only add resources you created
You can only add resources **you created** to a folder. You can't add someone else's resources on their behalf.
:::

::: warning Apps can't be added
**Apps** cannot be placed in a shared folder. Every other type — agents, skills, projects, connectors, keys, directives, tools, servers, templates, and so on — can.
:::

## View resources inside a folder

Click any card in the folder list to open the folder's detail page.

![resource-groups](/images/resource-groups.png)

The top of the detail page shows the folder name, description, and resource count. Below that are the resources inside, split into a row of **tabs** by type (for example, one tab each for agents and skills). Click a tab to switch between types.

Two tools help you find things quickly:

- **Search box**: type a keyword to filter resources within the current folder.
- **Sort menu**: choose from **Manual / Name / Type / Date added**.

::: tip Rearrange resources
When the sort is set to **Manual**, no search term is entered, and there aren't too many resources, you can drag cards directly to reorder them. When the list is long or you're searching, dragging turns off automatically — use the sort menu instead.
:::

If you have management rights on the folder, hovering over a resource card reveals a **Remove** button in the top-right corner. Click it to take the resource out of the folder (the resource itself isn't deleted — it just no longer belongs to this folder).

## Share a folder with others

Only the folder's creator (or an administrator) can share it.

1. On the folder detail page, click the **Share** button in the top-right corner.
2. In the dialog, search for who you want to share with — this can be **a person** or **a department / user group**.
3. Pick a permission level for them (Viewer / Editor / Owner).
4. Once confirmed, the folder shows up in their own **Shared with me** list.

![settings-sharing](/images/settings-sharing.png)

### Permission levels

| Permission | What they can do |
| --- | --- |
| Viewer | View the resources in the folder only |
| Editor | View, and adjust the folder's contents |
| Owner | Full management, including re-sharing with others |

::: tip
When you share with a **department / user group**, everyone in the group automatically gets access to the folder — and anyone who joins the group later gets it too, with no need to add them one by one.
:::

## Manage who has access

If you're the creator or an administrator, the detail page has an **Access** section listing everyone and every group that's been granted access, along with their permission.

- Each row shows the person's name (or the user group) and a permission tag.
- To revoke someone's access, hover over their row and click the **Remove** button that appears. The creator (owner) can't be removed.

::: info
Regular members who've been given access can't see the **Access** section and can't see who else has access — they only see the resources in the folder.
:::

## Delete a folder

1. Hover over the folder card (or wherever you have delete rights) and click the **Delete** icon.
2. A confirmation prompt appears; confirm it to delete the folder.

::: warning
Only the creator or an administrator can delete a folder. Deleting only removes the **folder** itself — the individual resources inside are kept and are not deleted along with it.
:::

## FAQ

::: tip Once I add resources to a folder, can my colleagues see them?
Only after you **share** the folder with them (or their department) can they see it. Simply adding resources to a folder without sharing it keeps them invisible to others.
:::

::: tip Why can't I see "who else is shared" in someone else's folder?
For privacy, only the folder's creator and administrators can see the full access list. People it's shared with only see the resources, not the other people who have access.
:::

::: tip Can I change a permission after sharing?
Yes. Share with the same person again and pick a new permission level to overwrite the old one; or remove them from the **Access** section and share again.
:::

## Related guides

- [Create an Agent](./create-agent.md) — build the agent you want to share
- [Publish your first app](./publish-first-app.md) — if you want broader access beyond folder members, publish the agent as an app
- [App Center](./app-center.md) — understand app-level sharing vs. resource-group sharing
- [Team collaboration](./team-collaboration.md) — more collaboration features (user groups, permissions, and more)
