---
title: Resource Group Administration
sync:
  source_commit: 7f4029536abf5945f2384f544555a3f6815c2519
  source_files:
    - api/v2/routers/resource_groups.py
    - api/v2/routers/resource_shares.py
    - web/app/(main)/resource-groups/**
  generated_at: 2026-07-12T12:32:34+00:00
  generated_by: docs-sync v2
---

# Resource Group Administration

A resource group bundles several resources (Agents, skills, projects, tools, and more) into a "folder" that you then share as a single unit with a user or department. Instead of sharing individual resources one by one, resource groups let you grant access by team, project, or purpose: resources added to a folder are shared along with it, and permissions are managed at the folder level. In the UI this feature is called **Shared Resources**.

::: info
Resource groups are available to all users — everyone can create their own folders. As an **administrator**, you can see and manage **every** resource group on the platform; regular users see only the ones they created plus the ones shared with them.
:::

## Opening Shared Resources

Sidebar「Shared Resources」, or go directly to `/resource-groups`.

The top of the page shows an overview bar (total folders, total resources, shared count) and a permission legend, then splits folders into two sections:

- **Created by me** — folders you created
- **Shared with me** — folders others shared with you

Each card shows the folder name, resource count, and member count, plus a badge: **Shared** (has other members) or **Private** (creator only). A search box and sort control (Recent / Name / Resources / Members) sit at the top.

<!-- SCREENSHOT: resource-groups -->

## Permissions and Resource Types

When you share a folder, each user or department you grant gets a permission level:

| Permission | What it allows |
|------------|----------------|
| **Viewer** | View the folder and the resources in it |
| **Editor** | On top of viewing, add, remove, and reorder resources in the folder |
| **Owner** | Full control, including managing other members |

A folder can hold these resource types:

| Type | Notes |
|------|-------|
| Agent, Skill, Project, Tool | The platform's core shareable resources |
| Connector, Directive, Key, MCP server, Template | The remaining shareable resource types |

::: warning
**Apps cannot be added to a shared resource group** — not even by an administrator. Apps always stay private to their owner.
:::

## Create a Folder

1. Click 「New Folder」at the top right (「Create your first folder」in the empty state).
2. Fill in:
   - **Name** (required, up to 255 characters)
   - **Description** (optional, up to 500 characters)
3. Click 「Create」.

You automatically become the **owner** of the folder you create.

<!-- SCREENSHOT: resource-groups-create -->

## Manage Resources in a Folder

Click any folder card to open its detail page. Resources are split into tabs by **type** (Agent, Skill, Project, …), and each tab shows a count for that type.

- **Search** — the search box at the top filters across all types; only the tabs with matches are shown.
- **Sort** — Manual / Name / Type / Added.
- **Drag to reorder** — when sort is set to Manual, no search is active, and the current tab has 40 resources or fewer, you can drag cards to reorder them; beyond that, or with a search active, it falls back to rule-based sorting (a hint above the grid explains this).

### Add Resources

You can only add resources **you created** to a folder (administrators are exempt and can add any resource). Added resources are shared along with the folder.

### Remove Resources

Click the remove button (`✕`) at the top right of a resource card to take it out of the folder. Removing only breaks the association — it does not delete the resource itself.

::: tip
If a resource in a folder is deleted elsewhere, the platform automatically clears the stale entry the next time you open the folder — no manual cleanup needed.
:::

## Share a Folder

1. On the folder detail page, click 「Share」at the top right.
2. In the picker, search for a target — find **users** by name or email, or **departments (user groups)** by name; you can also browse the tree by department hierarchy and select a whole department directly.
3. Choose a permission level (Viewer / Editor / Owner).
4. Confirm the grant.

The grantee then sees the folder under their own "Shared with me". To revoke, click the remove button next to the member in the access list.

<!-- SCREENSHOT: resource-groups-share -->

::: info
The access list (who has permission) is **visible only to the folder's owner and administrators**. Regular users the folder is shared with see only the resources inside it, not who else has access — this is intentional privacy protection.
:::

::: warning
- Only the folder's **creator or an administrator** can share and revoke access.
- For a folder that belongs to a department, only its creator or an administrator can share it.
- **Owner** permission cannot be removed via the revoke button, so a folder never accidentally loses its owner.
:::

## Delete a Folder

Delete from the folder card (or the detail page). Only the **creator or an administrator** can delete a folder; deletion asks for confirmation and cannot be undone. Deleting a folder only breaks the association between the resources and the folder — it does not delete the resources themselves.

## Administrator View

As an administrator, you have platform-wide authority over resource groups:

- **See every folder** — regardless of owner, every resource group on the platform appears in your list.
- **Manage any folder** — add or remove resources, share, revoke, and delete on any folder, without the "own resources only" restriction.
- **Review the sharing surface** — you can see each folder's full access list to check who was granted what.

## Notes

- Permissions are managed at the folder level: changing a folder's sharing changes the visibility of every resource in it for the grantees.
- Regular users can only add resources they created to a folder; administrators are exempt.
- Apps cannot be added to a shared resource group.
- The access list is visible only to owners and administrators; grantees cannot see other members.
- Owner permission cannot be removed via the revoke button.
- Deleting a folder or removing a resource only breaks the association, not the resource itself; deleting a folder cannot be undone.
