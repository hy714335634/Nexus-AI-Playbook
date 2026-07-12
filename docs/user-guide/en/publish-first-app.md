---
title: Publish Your First App
sync:
  source_commit: 9d40a32f2bad2c7858b3ed0cfb4390e1bd603a30
  source_files:
    - api/v2/routers/apps.py
    - web/app/(main)/apps/**
  generated_at: 2026-07-12T14:17:02+00:00
  generated_by: docs-sync v2
---

# Publish Your First App

This page walks you through the whole thing once: turn an Agent into a **shareable web app**, publish it, and let other people use it just by opening a link — no login, no tech knowledge needed. It takes about fifteen minutes. Just follow along and click.

::: tip Before you start
You need at least one usable Agent. If you don't have any yet, see [Creating an Agent](./create-agent.md); to try things quickly, just use one of the ready-made general assistants like **General Assistant** on screen.
:::

Once you've done this once, see [App Center](./app-center.md) for the full feature set (version management, access control, usage records, and more).

## The whole flow at a glance

| Step | What you do | Rough time |
|------|-------------|------------|
| 1. Create the app | Pick an Agent, give it a name, describe what you want | 1 min |
| 2. Generate the page | Click once and let the system build the app page | A few min |
| 3. Publish | Set the validity period and access mode, then publish | 1 min |
| 4. Share | Copy the link and send it to people | 1 min |

## Step 1: Create the app

1. Click **App Center** in the left sidebar.
2. Click the blue **+ New App** button in the top right to open the new-app wizard.
3. Pick the Agent that will power the app — it's the one doing the actual work. Use the search box at the top to find it by name; click a card to select it, **up to 5**. For your first app, just pick one.
4. Choose an icon and enter the app **name** (required).
5. In the requirements box, describe what you want in plain language, for example "Take a product description and generate a marketing landing page for me." The more specific you are, the closer the result.
6. Click **Create App**.

![apps-create](/images/apps-create.png)

::: tip How should I write the requirements?
Spell out three things: what the user **fills in** (input), what you want to **get back** (output), and what the page **looks like** (e.g. "a form on the left, results on the right"). No need to write it like a tech spec — everyday language is fine.
:::

## Step 2: Generate the app page

After creating it, you land on the **app detail page**, which has a flow indicator at the top: **Requirements → Generate → Ready**.

1. The Requirements box already contains what you just typed. You can add to it or edit it.
2. Click **Start Design**. The system goes to work on its own: it understands your requirements, then generates the whole app page — **no confirmation needed** along the way.
3. While it generates, the screen only shows a growing character count ("N characters generated"). Just wait for it to finish.
4. When it succeeds, it automatically moves to **Ready**, and a **live preview** appears on the right — exactly how the finished app will look.

![apps-builder](/images/apps-builder.png)

You can try the app right in the preview, and switch between **Desktop** and **Mobile** sizes to see how it looks on a computer versus a phone.

::: tip How long does generation take?
Usually a few minutes — you'll see the character count climbing the whole time. Go grab a coffee; it'll most likely be done when you're back.
:::

::: warning Something went wrong mid-way?
If generation fails, a message pops up and you're sent back to the Requirements step. It's usually because the description was too vague — spell out the input, output, and page layout you want, then click **Start Design** to try again.
:::

## Step 3: Publish the app

Once the preview looks right and the status is **Ready**, you can publish it for others to use.

1. Click the **Publish** button in the top right to open the publish settings window.
2. **Set the validity period**: pick how long the link stays valid — 7 days, 30 days, 90 days, or (if your admin allows it) **Permanent**. After it expires the link stops working and visitors see an expiry page.
3. **Choose an access mode**: decide who can open your app.

| Access mode | Effect |
|-------------|--------|
| **Public** | Anyone with the link can use it directly, no login |
| **Password** | You set a username and password; visitors must enter them first |
| **API Key** | Requires a key to access, mainly for technical use |

4. Click **Publish**. For your first app, **Public** is the simplest choice.

![apps-publish](/images/apps-publish.png)

::: warning Need to stop public access right away?
Click **Unpublish** and the app stops serving the public **immediately** — links you've already sent out will no longer open. To bring it back online, just publish again.
:::

## Step 4: Share it with people

After publishing, two buttons appear at the top: **Copy Link** and **Open App**:

1. Click **Open App** to see what others will see, in a new tab.
2. Click **Copy Link** to grab the public address and send it to colleagues, customers, or anyone.

They **don't need to log in or sign up** — they just open the link in a browser: fill in the form or type as prompted, click submit, and the app calls the Agent behind it and shows the result right on the page.

![apps-public](/images/apps-public.png)

::: tip Who does visitor usage count against?
Visitors use it without logging in, and all usage is billed to you (the app owner). To prevent abuse, the platform rate-limits anonymous access; normal use is unaffected.
:::

## After you're done

Congratulations — your first app is live. Next you might want to:

- **Change something**: no need to rebuild. In the left column of the detail page, click **Version & Update**, describe your change in one sentence, and the system updates it and creates a new version — see [App Center](./app-center.md#update-your-app-and-manage-versions).
- **See how people use it**: click **Invocations** at the top to view the full course of each visit.
- **Swap the Agent or add capabilities**: click **Edit Config** on the "Agents Involved" card to adjust.

All of these advanced steps are documented in full in [App Center](./app-center.md).
