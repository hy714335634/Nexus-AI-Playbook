---
title: Avatar Space
sync:
  source_commit: 460f1a3f6eaf3f2c86b695c2043a5d944b0ce733
  source_files:
    - api/v2/routers/avatar.py
    - config/avatar.yaml
    - web/app/(main)/home/page.tsx
  generated_at: 2026-07-12T14:31:14+00:00
  generated_by: docs-sync v2
---

# Avatar Space

Your Avatar is your **digital counterpart** in Nexus-AI, and it has a space of its own called "My Home." It quietly keeps an eye on your recent activity in the background — which Agents you've chatted with, what you've built, what you've done on the platform — then organizes it into reminders, insights, and to-dos and brings them to you. You can also drop in any time to chat with it and tell it your preferences and rules.

This page walks you through activating your Avatar, gets you familiar with every area in My Home, and shows you how to read reminders, talk to your Avatar, and pause it when you need to.

::: tip How is the Avatar different from normal chat?
Normal [Chat](./chat.md) is you going to an Agent to ask something. The Avatar works the other way around — it organizes things for you in the background and proactively reminds you what to pay attention to. Think of it as a personal assistant who gets to know you and looks out for you.
:::

## Open My Home

Click **My Home** in the left sidebar to open your Avatar Space.

## Step 1: Activate your Avatar (first time only)

The first time you enter My Home, you'll see a setup page:

1. The center shows the heading **"Start your personal AI space"**, with a **"Activate Avatar"** button below it.
2. Click **"Activate Avatar"**.
3. Wait about 2–3 seconds while the system sets up your dedicated space.
4. When it's ready, you're taken to the **Reminders** tab, where you'll find a few welcome cards your Avatar has already made for you.

![avatar-onboarding](/images/avatar-onboarding.png)

::: warning One click activates it — there's no second confirmation
Clicking **"Activate Avatar"** turns it on immediately, with no follow-up prompt. It's ready to use right away. If you want to turn it off later, see [Pausing or closing your Avatar](#pausing-or-closing-your-avatar) at the end.
:::

## Getting to know the main view

After activation, the top of My Home has a row of tabs for five areas:

| Tab | What it's for |
|------|---------------|
| **Reminders** | Cards your Avatar pushes to you: reminders, insights, to-dos, and items to confirm. The number on the tab is the current count |
| **Chat** | Talk to your Avatar directly |
| **My Home** | A virtual room that lays out everything your Avatar has organized, area by area |
| **Knowledge Graph** | The web of knowledge your Avatar has built, showing how people, things, and content connect |
| **Settings** | Adjust your Avatar's options |

Let's look at each one.

## Reminders: cards your Avatar pushes to you

**Reminders** is where you'll look most when you enter My Home. Your Avatar turns everything it wants to tell you into individual **cards** that you handle one by one.

![avatar-cards](/images/avatar-cards.png)

### What a card looks like

Each card has a title, a short explanation, and a few action buttons below it. For example, three common cards right after activation:

- **A suggestion** — e.g. "You've had 51 conversations in the last 7 days," asking whether you'd like a summary of the week. Buttons include "Organize now," "No thanks," "Ask," "Snooze," and "Done."
- **A prompt** — asking you to write down something you want your Avatar to always remember (a long-term preference like "answer in English").
- **A prompt** — asking you to write down hard rules your Agents must follow (like "always ask me before anything that costs money").

Different cards have different buttons, but they all mean what they say: **Organize now / Handle now** makes the Avatar act right away, **Snooze** reminds you later, **Done** marks it handled, **Ask** lets you follow up on that card, and **No thanks / Later** skips it this time.

### Filter by type

Above the card list is a row of filter buttons to show just one type; the number is the count for each:

| Filter | What you see |
|--------|--------------|
| All | Every card |
| Urgent | Things that need attention now |
| Reminders | General reminders |
| Insights | Findings and suggestions your Avatar has pulled together |
| To confirm | Items waiting for your decision |
| Agent | Cards related to Agent runs |

### Quick actions at the top

The top of the list also has three batch buttons:

- **"⚡ Smart-handle suggestions"** — let your Avatar handle all the suggestion cards it can complete on its own in one go.
- **"📋 Confirm to-dos in one click"** — confirm to-do items in bulk.
- **"📅 Schedule"** — put time-based items onto your schedule.

At the top right, **"🗑 Clean up"** clears out expired or unwanted cards, and **"Refresh reminders"** pulls the latest cards. Below the list you can change how many show per page (10 / 20 / 50 / 100) and page through them.

::: tip Do cards expire on their own?
Yes. Most cards expire and disappear on their own after a while, so you don't have to clear them by hand. Cards that need your confirmation are shorter-lived — **if you don't respond within 24 hours, they expire automatically** — so try to handle "To confirm" cards sooner rather than later.
:::

## Chat: talk to your Avatar directly

To ask your Avatar something directly, or just jot something down, use the **Chat** tab.

![avatar-chat](/images/avatar-chat.png)

1. The first time in, you'll see "This is your first conversation with your Avatar — just say something."
2. Type in the box at the bottom (placeholder "Say to yourself...").
3. Click the **"Say"** button to send (it's disabled while the box is empty).
4. Your Avatar responds, drawing on what it knows about you.

Above the input box is a row of small icons (📬 Inbox, 📚 Bookshelf, 📅 Calendar, 🗄️ Archive, and so on) that jump you straight to the matching area in My Home. To start over, click **"Clear chat history."**

::: tip This chat is separate from normal chat
This is a dedicated place to talk to your Avatar. It's a completely separate record from the [Chat](./chat.md) in the left sidebar — the two don't mix.
:::

## My Home: a virtual room

**My Home** uses the look of a virtual room to lay out everything your Avatar has organized, sorted by kind — more intuitive than a pile of folders.

![avatar-my-home](/images/avatar-my-home.png)

When you enter, the top shows a greeting (like "Good afternoon — I've organized 3 reminders") plus a few quick cards, along with **"Chat with Avatar," "All reminders,"** and **"Graph"** buttons for quick jumps.

Each area in the room holds one kind of content; click one to go in:

| Area | What's inside |
|------|---------------|
| 📚 Bookshelf | Your preferences and rules (things to remember long-term, hard rules) |
| 🔥 Fireplace | Your Avatar's current status |
| 🖥️ Desk | Notes and memos |
| 📋 Whiteboard | Your Avatar's reflections and summaries |
| 📅 Calendar wall | To-dos and schedule |
| 🗄️ Filing cabinet | Past conversation records |
| 🧪 Recipes | Frequently used workflows and shortcuts |
| ✉️ Inbox | Reminders (the same cards as the Reminders tab) |

The number on an area button is how many items are inside (e.g. "📚 2 Bookshelf" means the bookshelf has 2 items). The **"Change theme"** button at the top right switches the room's look (the default is "Classic study") — purely cosmetic, it doesn't affect content.

## Knowledge Graph: see how things connect

The **Knowledge Graph** shows the people, things, and content your Avatar has pulled together as a web of relationships, so you can see at a glance how they connect.

![avatar-knowledge-graph](/images/avatar-knowledge-graph.png)

- The top has a search box; type a keyword to locate a node.
- There are four views to switch between: **Overview** (default, shows everything), **Mine**, **Avatar**, and **Path**.
- On the right are a **Refresh** button and a zoom slider.

::: info The graph is empty right after activation
Your Avatar needs to build up some activity before it can weave this web. An empty graph right after activation is normal — come back after a while and it'll have content.
:::

## How often does the Avatar organize? Can I make it act now?

Your Avatar **organizes automatically in the background about once an hour**, gathering up new activity from that period, updating its memory, and creating new cards. This all happens in the background — you don't have to watch over it.

If you can't wait and want it to organize now, there are two ways:

- Click **"Organize now"** on a suggestion card in **Reminders**.
- Open the command palette (press `⌘K` / `Ctrl+K`). It has two actions: **"Activate Avatar now"** and **"Avatar reasoning"** — the first makes it organize recent activity immediately, the second makes it generate a fresh batch of suggestion cards based on your current situation. The command palette also lets you jump quickly to Avatar entry points like "Open Knowledge Graph" and "Chat with Avatar."

::: tip Organizing takes a moment
After you ask your Avatar to organize now, it needs a little while to finish in the background — it's not instant. Feel free to do something else and come back to refresh the Reminders page for new cards.
:::

## Pausing or closing your Avatar

If you don't want to use your Avatar for now, or want to close it for good, you can do so in **Settings**. There are two ways:

| Option | Effect |
|--------|--------|
| **Pause but keep data** | Stops the Avatar from organizing and pushing, but keeps your preferences, memory, and history — you can resume any time |
| **Close completely** | Erases all the data in your Avatar Space, keeping nothing |

::: warning Closing completely can't be undone
**"Close completely"** deletes everything in your Avatar Space and **can't be recovered**. If you just want a break, choose **"Pause but keep data."**
:::

To use it again after pausing, click resume in **Settings**. If you chose "Pause but keep data," your earlier preferences and memory will still be there after you resume.

::: info You can only pause your own Avatar
For privacy, you can only pause or resume your own My Home. (Administrators can assist with others' spaces when needed.)
:::

## FAQ

**I didn't do anything — how does the Avatar already have cards?**
That's its job. Your Avatar watches your recent activity in the background and turns it into reminders and suggestions for you automatically. See a card you don't need? Click "No thanks" or "🗑 Clean up" to clear it.

**Can the Avatar see everything of mine? Is it safe?**
My Home is your private space — only you (and administrators) can see it. Everything your Avatar organizes comes from your own activity on the platform.

**How do I make the Avatar remember a preference long-term?**
Respond to the prompt card in **Reminders**, or write your preferences and hard rules into the **Bookshelf** area in **My Home**. Once written down, your Agents will follow them when working for you.

**Can I change my mind after activating the Avatar?**
Yes. Go to **Settings** and choose "Pause but keep data" to stop it for now; if you're sure you no longer need it, you can also "Close completely" to erase the data.
