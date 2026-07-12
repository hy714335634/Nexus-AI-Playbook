---
title: Users & Permissions
sync:
  source_commit: 7f4029536abf5945f2384f544555a3f6815c2519
  source_files:
    - api/v2/routers/policies.py
    - api/v2/routers/users.py
    - web/app/(main)/users/**
  generated_at: 2026-07-12T12:30:02+00:00
  generated_by: docs-sync v2
---

# Users & Permissions

The User Management page lets you manage every account, group (department), and permission policy on the platform in one place — create and disable users, assign roles, organize users into a department tree, and define fine-grained custom permissions. Permissions are driven by **policies**; a role is just a shorthand for a policy.

::: info
User Management is available to **administrators** only. Non-admins see a "no access" placeholder; the page is disabled entirely on the basic edition.
:::

## Opening User Management

Sidebar「User Management」, or go directly to `/users`.

The page has two tabs:

- **User List** — manage users, departments (groups), and assign roles and policies to users (opens by default)
- **Policy Management** — view managed policies, and create and maintain custom permission policies

![users](/images/users.png)

## Roles and the Permission Model

Permissions come from **policies**. Each user is bound to one or more policies, and the role (Admin / Editor / Viewer) is derived automatically from those policies — you pick a "role" and the system materializes it as the matching managed policy behind the scenes.

The system ships four built-in **managed policies** that cover most cases; they cannot be edited or deleted:

| Policy | Role | What it allows | Permissions |
|--------|------|----------------|-------------|
| **AdministratorAccess** | Admin | Full management; operate on all resources and users | 49 |
| **EditorAccess** | Editor | Create and edit Agents, projects, tools, and other resources | 43 |
| **UserAccess** | User | Chat with Agents and view existing resources | 25 |
| **ViewerAccess** | Viewer | Read-only view of all resources; no editing or interaction | 18 |

A permission is a combination of a **resource** and an **action**. The manageable resources and actions are:

| Resource | Available actions |
|----------|-------------------|
| Agent | list, read, create, update, delete, invoke, chat |
| Project / Tool / Skill / Event job / Connector / Directive | list, read, create, update, delete |
| Session | list, read, create, delete |
| Config | read, update |
| Statistics | read |
| User | list, read, create, update, delete |

## User List Tab

The User List tab organizes users into a tree by **department (group)**, with a search box (「Search users...」) at the top and two primary actions: 「Add Department」and 「Create User」. Two default groups exist out of the box: **Default** (the default group for all users) and **SystemAdmin** (the system administrators group).

### Create a User

1. Click 「Create User」at the top right.
2. Fill in the fields:
   - **Username** (display name, required)
   - **Email** (required, must be unique)
   - **Password** (required, at least 4 characters; click the eye icon to reveal)
   - **Role**: one of four cards — **Admin** (full management), **Editor** (create and edit resources), **User** (use Agents and view), **Viewer** (read-only view)
3. Click 「Create」.


::: warning
An already-registered email will be rejected. The basic edition caps total users; when the cap is reached, creation triggers an upgrade prompt with contact details, and you must upgrade to add more.
:::

### Edit a User's Profile

From the user's actions, choose edit to change the **username** and **email** (the email must also be unique).

### Reset a Password

An admin can set a new password for a user directly, without knowing the old one: from the user's actions choose 「Reset Password」, enter the new password (at least 4 characters), and confirm.

::: warning
You cannot reset the password of an SSO (SAML) user — those accounts are managed by your identity provider, so handle it on the IdP side.
:::

### Change Role and Policies

Open the user's 「Permission Policies」dialog:

- **Role** (single select): pick one managed policy as the primary role; it replaces the current role.
- **Custom policies** (multi-select): attach custom policies on top of the primary role to grant extra permissions.

After saving, the user's role stays consistent with the selected policies automatically.

::: tip
The right panel previews the resources and actions a selected policy contains in real time, so you can double-check before assigning.
:::

### Enable / Disable a User

Toggle the status from the user's actions. A disabled user cannot log in, but the account and its resources are kept and can be re-enabled at any time.

### Delete a User

When you delete a user, their resources are **transferred to another user** (by default the current admin, or a target user you specify). Deletion cannot be undone.

::: warning
You cannot change your own role or status, and you cannot delete yourself — this prevents an admin from locking themselves out.
:::

## Department (Group) Management

Groups organize users into a tree by org structure and can carry policies per group, making it easy to manage permissions in bulk.

### Create / Edit a Group

1. Click 「Add Department」(or choose 「Edit Group」from the menu at the top-right of a group card).
2. Fill in:
   - **Group name** (required, e.g. "Engineering Team")
   - **Description** (optional)
   - **Parent group** (dropdown: pick 「None (top-level group)」for a top-level group, or an existing group as the parent)
3. Click 「Create」or 「Save」.


### Group Policies

From the menu at the top-right of a group card, choose 「Group Policies」to select policies for the whole group; members of the group gain the corresponding permissions.

### Move a User

To move a user to another group: choose move from the user's actions and pick a target from the 「Target group」dropdown (choose 「Ungrouped」to remove them from all groups).

::: tip
Moving a user changes their permission visibility, and it may take a brief moment to take effect (cache refresh). If permissions look stale right after a move, wait a moment and check again.
:::

### Delete a Group

Choose 「Delete Group」from the menu at the top-right of a group card.

## Policy Management Tab

The Policy Management tab is where you view and maintain all permission policies, with a search box (「Policy name」) and a 「Create Policy」button at the top. Policies fall into two kinds:

- **Managed policies** — the four built-in policies (see above), marked "system built-in, not editable"; view only.
- **Custom policies** — created by admins; editable and deletable.

Click any policy card to expand its permission matrix.


### Create a Custom Policy

1. Click 「Create Policy」.
2. Enter a **policy name** (cannot collide with a managed policy) and a **description** (optional).
3. In the **permission matrix**, check the boxes: each row is a resource, each column an action; a check grants that resource + action. Gray cells mean the resource does not support that action. Each row has a "select all" toggle at the end.
4. The selected permission count is shown live at the bottom. Click 「Create」to save.


### Edit / Delete a Custom Policy

Edit or delete from a custom policy's card. Deletion asks for confirmation and cannot be undone. Managed policies cannot be edited or deleted.

### Attach Custom Policies to a User

Once created, a custom policy can be attached to a specific user as an extra policy in that user's 「Permission Policies」dialog (see "Change Role and Policies" above).

## User Self-Service

Regular users can manage their own account without an admin:

- **Profile** — view and update their own username and email.
- **Change password** — enter the current password and a new one (at least 4 characters). SSO users change their password through the identity provider.

## Notes

- Permissions are driven by policies; a role is shorthand for a policy. Changing the role resets it to the matching managed policy; changing policies syncs the role.
- You cannot change your own role or status, and you cannot delete yourself.
- You cannot reset or change an SSO (SAML) user's password — that goes through the identity provider.
- Decide on a resource-transfer target before deleting a user; deletion cannot be undone.
- The basic edition has a user cap; exceeding it requires an upgrade.
- After moving a user or adjusting groups, permission changes may take a brief moment to apply.
