---
title: App Center
sync:
  source_commit: 9d40a32f2bad2c7858b3ed0cfb4390e1bd603a30
  source_files:
    - api/v2/routers/apps.py
    - api/v2/services/app_service.py
    - api/v2/services/apps_runtime.py
    - web/app/(main)/apps/**
    - web/components/apps/**
  generated_at: 2026-07-12T13:34:27+00:00
  generated_by: docs-sync v2
---

# App Center

App Center turns one (or several) of your Agents into a **shareable web app**: other people don't need to log in or understand any tech — they just open a link, fill in a form or type a couple of messages, and use your Agent directly. This page walks you through building an app from scratch, publishing it, and managing its versions.

::: tip Before you start
You need at least one usable Agent. If you don't have any yet, see [Creating an Agent](./create-agent.md) to build one; to try things quickly, just use one of the ready-made general assistants like **General Assistant** on screen.
:::

## Open App Center

Click **App Center** in the left sidebar. The page title is "App Center" and the subtitle reads "Turn Agents into shareable web apps." A blue **+ New App** button sits in the top right.

The center of the page lists the apps you've already built as cards. Each card shows:

| Info on the card | What it means |
|------|------|
| Icon + name | The app's icon and name |
| Status label | Its current state — draft, ready, published, disabled, and so on |
| Version number (e.g. v4) | The version currently served to the public |
| Agent count, visits | How many Agents it uses, and how many times it's been visited |

Hover over the bottom of a card to reveal a row of icon buttons: **Edit**, **Publish / Unpublish**, **Copy Link**, **Open App**, and **Delete**.

![apps-list](/images/apps-list.png)

::: tip No apps yet?
The page shows an empty-state prompt — just click **+ New App** in the center to build your first one.
:::

## Step 1: Create an app

Click **+ New App** in the top right to open the creation wizard. It has three steps.

### Choose how to create

First, pick a creation method:

| Method | Who it's for | Roughly how it works |
|------|--------|----------|
| **Quick Create** | Most cases, when you want a result fast | Pick an Agent, enter a name and requirements, and get an app page generated automatically within a few minutes |
| **Full Create** | Complex needs, when you want more polish | Describe your needs in a paragraph; the system builds it fully in the background, stage by stage — this takes a while |

Once chosen, click **Next**.

### Pick an Agent

The second step is choosing the Agent behind your app — the one that actually does the work.

1. The list includes both built-in **featured Agents** (marked with a star) and Agents you've built yourself.
2. Use the search box at the top to find one by name.
3. Click a card to select it; you can pick **up to 5**. Click again to deselect.
4. Quick Create requires at least 1; for Full Create you can skip this step (the system will choose for you).

Click **Next** when done.

### Fill in details / describe your needs

The last step differs slightly depending on the method you chose:

- **Quick Create**: Pick an icon, enter an app name (required), then describe the scenario and what the interface should look like in plain language (e.g. "paste a product description, generate a marketing landing page"). Click **Create App** when done.
- **Full Create**: Enter an app name (optional) and a detailed requirements description (required), then click **Start Full Build**. The system builds it in the background, and you'll be taken to the **Workshop** to watch progress.


::: tip Quick Create or Full Create?
When in doubt, go with **Quick Create** — it's faster, and you can always keep adjusting and regenerating afterward. Full Create suits you when you've already thought things through and your needs are more complex.
:::

## Step 2: Generate the app page (Quick Create)

After a Quick Create, you land on the **app detail page** automatically. A progress indicator at the top shows: **Requirements → Generate → Ready**.

1. In the **Requirements** step, the box is already filled with what you entered earlier — you can add to it or edit it.
2. Click **Start Design**. The system goes to work automatically: it first understands your needs, then generates the whole app page — **no confirmation needed** along the way.
3. While it generates, the screen only shows a growing character count ("N characters generated"). Just wait for it to finish.
4. Once it succeeds, it moves to the **Ready** state and a live preview of your app appears on the right.

![app-detail](/images/app-detail.png)

::: tip How long does generation take?
Quick Create usually finishes within a few minutes. Full Create (and the "rebuild from new requirements" option described later) runs the complete build process in the background — **about 20–40 minutes**, so go do something else and check back.
:::

::: warning What if it errors out mid-way?
If generation fails, the screen shows a message and returns you to the **Requirements** step. Check whether your description was too vague, flesh it out, and click **Start Design** to retry.
:::

## Get to know the app detail page

Once in the **Ready** state, the detail page splits into a left and right column.

**Left column — app info and settings:**

- The app's icon, name, description, and current status.
- Key attributes: number of bound Agents, visit count, access method, and validity period (shown after publishing).
- When published, a copyable **public link** appears here.
- The **Agents involved** card: lists each Agent the app uses, and lets you edit them one by one (see the next section).
- The **Versions & Updates** collapsible area: update the app, and view or switch history versions (covered below).

**Right column — live preview:**

- Labeled "Live preview," it lets you switch between **Desktop** and **Mobile** sizes to see how the app looks on different devices.
- If the app supports two languages, an **EN / 中** language toggle appears in the top right.
- The preview area is the real app interface — you can try it out directly.


The top toolbar also has **Invocations**, **Copy Link**, **Open App**, and **Publish / Unpublish** buttons.

## Adjust the Agent behind your app

In the **Agents involved** card in the left column, each Agent has an **Edit Config** button. Open it to make these adjustments:

| Adjustable | What it does |
|------|------|
| **Label** | Give the Agent a business-facing name within the app (e.g. "Copywriting Assistant") |
| **Base Agent** | Swap in a different Agent to do the work. The page layout stays the same — only the executor changes |
| **Run mode** | Usually fine left at the default; no need to touch it |
| **Capabilities** | Search and check boxes to give the Agent tools, skills, and data connectors |
| **Version** | If the Agent has multiple versions, switch between them here |

Click **Save** when done.


::: warning Watch out when swapping the base Agent
After switching to a different Agent, its output format **may no longer match** the original, and the page will prompt you to double-check. After swapping, test it once in the right-hand preview to confirm the app still produces results correctly.
:::

::: tip The "API" button is for developers
Each Agent card also has an **API** button, meant for technical colleagues who want to call the Agent from their own programs. If you don't do development, just ignore it — it doesn't affect normal use.
:::

## Step 3: Publish the app

Once the app is generated and its status is **Ready**, you can publish it for others to use. Click the **Publish** button at the top (or on the list card) to open the publish settings window.

**Set the validity period.** Pick how long the app link stays valid from the dropdown — 7 days, 30 days, 90 days, or (if your administrator allows) "Permanent." After it expires, the link stops working and visitors see an expiration page.

**Choose an access method.** Decide who can open your app:

| Method | Effect |
|------|------|
| **Public** | Anyone with the link can use it directly, no login required |
| **Password** | You set a username and password; visitors must enter them to get in |
| **API Key** | A key is required to access it — mainly for technical calls |

Click **Publish** when set. After publishing, use **Copy Link** at the top to grab the public address and share it, or click **Open App** to preview it yourself.

<!-- SCREENSHOT: apps-publish -->

::: warning Need to stop public access right away?
Click **Unpublish** — the app stops serving the public **immediately**, and links you've already shared will no longer open. To go public again, just run **Publish** once more.
:::

## How others use your app

Share the public link with a colleague, a customer, or anyone. They **don't need to log in or sign up** — they just open it in a browser:

1. The app's icon and name are at the top; bilingual apps have an **EN / 中** toggle in the top right.
2. They fill in the form as prompted, or type input like a chat.
3. They click the submit / generate button, and the app calls the Agent behind it and shows the result right on the page.

<!-- SCREENSHOT: apps-public -->

::: tip Whose usage is a visitor's activity counted as?
Visitors use the app without logging in, and all usage is counted under you (the app owner). To prevent abuse, the platform rate-limits anonymous access — normal use is unaffected.
:::

## Update your app and manage versions

Want to change your app after publishing? No need to rebuild. In the left column, click **Versions & Updates vN** (vN is the current version number) to expand the version panel.

### Update your app in one sentence

At the top of the panel, you can **describe what you want to change in plain language**, and the system updates it automatically and produces a new version. There are two modes:

- **Modify the current version** (default): Make small changes on top of the existing page — good for fine-tuning.
- **Rebuild from new requirements**: Redo the app from your new description — use this for bigger changes.

Type your change request in the box (e.g. "add an export button to the results area," "switch the theme to a dark color scheme"), then click **AI Update App**. The update runs in the background, and a new version appears when it's done.

<!-- SCREENSHOT: apps-versions -->

### View and switch versions

The lower half of the panel is the **version history**. Each entry shows the version number, where that version came from, and a summary of the changes. You can:

- Click the **preview** icon to see what a history version looks like (without affecting the version currently served to the public).
- Click **Switch to this version** on any history version to make it the one served to the public — effectively a **one-click rollback**. Old versions aren't deleted, so you can always switch back.
- The version currently being served is marked with a **Current** badge.

::: tip No fear of breaking things
Every update is kept as its own version, and history versions stick around. If a new version disappoints, just **Switch to this version** to return to any earlier one.
:::

## View usage records

Want to know how your app is being used? Click **Invocations** at the top to open the usage records window:

- The left column is the **visit list** — one visit is one person's complete use, sorted newest first.
- Click a visit, and the right column expands the **full sequence** of that visit on a timeline — what the user said, what the Agent did, and what it produced, all at a glance.

This is handy for understanding how real users use your app and for troubleshooting.

## Delete an app

Delete apps you no longer need: on the App Center list page, click the **Delete** icon at the bottom of the card and confirm.

::: warning Deletion can't be undone
Deleting wipes out the app along with all its versions, with no way to recover it. If you just want to take it offline temporarily, use **Unpublish** instead of Delete.
:::
