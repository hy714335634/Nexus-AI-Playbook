---
title: Team Collaboration
sync:
  source_commit: 9d40a32f2bad2c7858b3ed0cfb4390e1bd603a30
  source_files:
    - api/v2/routers/groups.py
    - api/v2/routers/resource_groups.py
  generated_at: 2026-07-12T14:27:02+00:00
  generated_by: docs-sync v2
---

# Team Collaboration

In Nexus-AI you don't have to work alone. The agents, skills, and projects you build can be handed to a whole team at once, and your teammates' work shows up on your own workspace. This page shows you how to collaborate with your team.

::: tip In one sentence
Sharing a resource with "one person" is point-to-point. Sharing it with "a whole department" lets the entire group use it at once — that's the easiest way to collaborate.
:::

## The team you belong to

In Nexus-AI, everyone belongs to one or more **teams** (also called "departments" or "user groups"). A team groups together people from the same department or project, so resources can be shared and managed as a unit.

A few things to know about teams:

- Teams are **created and maintained by an administrator**. Which team you're in and who else is on it is set up by your admin — you don't need to (and can't) create or change teams yourself.
- Teams can have **parent-child relationships** — for example, "Marketing" can contain "Marketing Team 1" and "Marketing Team 2", forming an organization tree.
- Your membership decides what gets shared to you: as soon as a resource is shared with a team you belong to, you can use it automatically.

::: info Not sure which team you're in?
Team membership is managed by your administrator. If you're unsure which team you belong to, or you need to join one, just contact your system administrator.
:::

## Share with a whole team at once

The most common way to collaborate is to put a set of resources into a "folder" and then share that folder with a **whole team**, instead of forwarding it to each person one by one.

::: tip Prepare the folder first
Before sharing, you need a folder with resources in it. To learn how to create a folder and add resources, see the **Resource Groups & Sharing** page. Here we only cover the "share with a team" step.
:::

Steps:

1. Open the folder you want to share and go to its detail page.
2. Click the **Share** button in the top-right corner.
3. In the dialog, switch the target from "a person" to a **team (department / user group)**, then search for and select the target team.
4. Choose a permission level for the team (Viewer / Editor / Owner).
5. Confirm. Everyone on the team can immediately find the folder under their own **Shared with me**.

![settings-sharing](/images/settings-sharing.png)

::: tip New teammates get access automatically
After sharing with a team, **everyone currently on the team** gets access — and **anyone who joins the team later gets it automatically too**, so you never have to re-share. That's exactly why sharing with a team beats sharing with individuals.
:::

## Choosing a permission level

When you share with a team, you pick a permission level for them. The three levels differ as follows:

| Permission | What team members can do |
| --- | --- |
| Viewer | View and use the resources in the folder only |
| Editor | View and use, plus adjust the folder's contents |
| Owner | Full control, including re-sharing the folder with other teams or people |

::: warning Be careful with Owner
Giving a whole team "Owner" means anyone in the group can change the contents and even re-share the folder. In most cases, "Viewer" or "Editor" is enough for a team.
:::

## How team members use what's shared with them

If someone shared a folder with a team you belong to, here's how to find it:

1. Click **Shared Resources** in the left navigation bar.
2. Under the **Shared with me** group, find the folder shared with you.
3. Open the folder to see and use all the resources inside.

![resource-groups-list](/images/resource-groups-list.png)

::: info You only see the resources themselves
As the recipient, you can see and use the resources in the folder, but you can't see "who else this folder is shared with." The full share list is visible only to the folder's creator and administrators.
:::

## Revoking a team's access

If you're the folder's creator and want a team to lose access:

1. Go to the folder's detail page and find the **Access** section.
2. Locate the row for that team.
3. Hover over it and click the **Remove** button that appears.

Once removed, members of that team can no longer see the folder. Your own access as the creator (Owner) is unaffected and can't be removed.

::: warning Who can share and revoke
Only the folder's creator or a system administrator can share it with a team or revoke a team's access. For folders others shared with you, you can't change their share settings.
:::

## FAQ

::: tip I shared a resource with a team, but a colleague says they can't see it?
Check three things: first, that this colleague really belongs to the team you shared with (membership is managed by the admin); second, that you shared with the "team," not a single person; third, have them refresh the Shared Resources page. If they still can't see it, ask your admin to verify their team membership.
:::

::: tip After sharing with a team, can I still give one person a higher permission?
Yes. Team sharing and individual sharing don't conflict. You can share the folder with the whole team as "Viewer," then separately set one person as "Editor," and that person will have the higher permission.
:::

::: tip What if a team is dissolved or reorganized?
Adding, removing, and reshuffling teams is all done by the administrator. When a team changes, members' access updates automatically — anyone no longer on a team also loses access to folders shared with that team.
:::

::: tip Can I share an "app" with a team?
No. Apps can't be placed in shared folders, so they can't be shared with a team through a folder. Every other type — agents, skills, projects, connectors, keys, directives, tools, servers, templates, and so on — can.
:::
