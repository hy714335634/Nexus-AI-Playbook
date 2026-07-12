---
title: Chat & Sessions
sync:
  source_commit: 9d40a32f2bad2c7858b3ed0cfb4390e1bd603a30
  source_files:
    - agents/system_agents/magician.py
    - api/v2/routers/sessions.py
    - api/v2/services/agent_runtime_service.py
    - web/app/(main)/agents/[id]/chat/**
    - web/app/(main)/chat/**
  generated_at: 2026-07-12T13:27:25+00:00
  generated_by: docs-sync v2
---

# Chat & Sessions

Chat is where you work with an Agent day to day: pick an Agent, open a session, and send it questions or tasks like a chat message — it replies piece by piece, in real time. This page walks you through a full conversation from scratch and explains what every button in the chat view does.

::: tip Before you start
You need at least one usable Agent. If you don't have any yet, see [Creating an Agent](./create-agent.md) to build one; to try things quickly, just use one of the ready-made general assistants like **General Assistant** on screen.
:::

## Open the Chat page

Click **Chat** in the left sidebar to open the Chat page. It has three areas:

| Area | Location | What it's for |
|------|----------|---------------|
| Agent & session list | Left column | Pick the Agent to chat with, and the sessions under it |
| Conversation | Center | Your back-and-forth messages with the Agent appear here |
| Config panel | Right column (collapsed by default) | View the current Agent's description, available tools, and so on |

When you first arrive, no Agent is selected yet, and the center prompts you to **"Select an Agent from the left to start a conversation."**

![chat](/images/chat.png)

## Step 1: Pick an Agent

The top of the left column has a few **quick-start** general assistants you can use with one click:

- **General Assistant** — a versatile all-purpose helper
- **Deep Research** — in-depth research using the internet
- **Data Analyzer** — data analysis
- **Content Creator** — content creation

To use an Agent you built yourself, click the **Select Agent** dropdown and pick one from the list. Once selected, the left column shows that Agent's **session list**.

::: tip The Agent and APP tabs
The selector has two tabs: **Agent** and **APP**. For normal use, stick with Agent. The APP tab is for chatting with **apps** that have already been published — see [App Center](../guides/apps.md) for how that works.
:::

## Step 2: Create a session

A **session** is one self-contained conversation. You can open several sessions under the same Agent, each with its own separate context — for example, one for real work and one for testing.

1. After picking an Agent, the center prompts you to **"Select or create a session."**
2. Click **Create New Session**.
3. A new session appears in the left column right away, auto-named with its **creation time** (e.g. "Session 2026/7/12 15:08:09").
4. The center switches to the chat view, showing the empty-state hint **"Start chatting with xxx."**

To return to a session later, just click it in the left column — all its earlier messages are still there.

## Step 3: Send a message

Type your question or task into the box at the bottom, then send it.

::: warning The send shortcut is Shift + Enter
Unlike most chat apps: **pressing Enter only adds a new line — it does not send.** To send, press **Shift + Enter** or click the send button at the bottom right. The send button itself is labeled "Shift+Enter to send" as a reminder. The send button is disabled while the box is empty.
:::

1. Click the input box at the bottom (placeholder "Type a message...") and enter your text.
2. Press **Shift + Enter** or click the send button.
3. Your message appears at the top of the conversation immediately.
4. The Agent starts replying, with text appearing **piece by piece in real time** — that's normal, it means it's thinking and writing as it goes. Replies may include bold text, headings, and tables, which are formatted automatically into a clean layout.

<!-- SCREENSHOT: chat-streaming -->

::: tip How long does a reply take?
Simple questions usually finish in ten to twenty seconds. Complex tasks that require looking things up or using tools take longer; during that time the interface shows what it's currently doing (such as "Calling a tool…"), so you don't have to wonder whether it's stuck.
:::

## What you can do while it's replying

While the Agent is answering, the send button turns into **Stop Generating**. If it's heading the wrong way, or the answer is already enough, click it to interrupt — **whatever has been written so far is kept**, so you can add to it or ask again differently. When a reply finishes normally, the button switches back to the send state on its own.

## The chat toolbar

A row of buttons sits at the top of the chat view. The ones you'll use most:

| Button | What it does |
|--------|--------------|
| **Files** | Opens the file panel to view the files used and produced in this conversation |
| **Compact Context** | When a conversation gets long, has the system tidy up and condense earlier content so it keeps replying smoothly |
| **Favorite** | Bookmarks this Agent so you can find it quickly next time |
| **Immersive Fullscreen** | Hides the other areas and enlarges the conversation to focus on chatting (press Esc to exit) |
| **Clear Conversation & Rebuild Agent** | Clears the current conversation and lets the Agent start fresh from a clean state |

::: warning "Clear Conversation & Rebuild" wipes the current conversation
Clicking it clears this session's content and resets the Agent to its initial state. Use it only when you really want to start over; if you just want a new topic, creating a new session is safer.
:::

The toolbar also has advanced features like **Dynamic Config** and **Skill Distillation**. You won't need these for everyday chatting, so feel free to ignore them for now.

## Upload and view files

You can attach files to a chat so the Agent uses their contents in its answer.

1. Click the **attach button** next to the input box (labeled "Attach files (or paste screenshot)").
2. Choose the images, spreadsheets, documents, or other files to upload — you can also **paste a screenshot** directly.
3. Send them along with your question.

Click **Files** at the top to open the file panel, which is split into **Attachments** and **Workspace**: **Attachments** are the files you uploaded, and **Workspace** holds files the Agent generated while working. Click a file name in the tree to preview it.


## Managing multiple sessions

- **Create**: Click **Create New Session** anytime to start a fresh one, independent of older sessions.
- **Switch**: Click any session in the left column to switch to it — its message history is still there.
- **Delete**: Each session has a **Delete Session** button next to it; remove the ones you don't need.

::: tip How are sessions named?
New sessions are named by their creation time by default. The list is ordered by most recent use at the top, so the one you just chatted in is easy to find.
:::

## FAQ

**Why does the reply appear one word at a time?**
That's the normal look of a real-time answer — the Agent is thinking and writing as it goes, not stuck. Once it finishes, the button restores itself.

**Why didn't pressing Enter send my message?**
Enter adds a new line here. To send, use **Shift + Enter** or click the send button.

**If I close the page or navigate away, do I lose a reply that's still being generated?**
No. Reopen the session and you'll see the reply continue or already completed.

**If I open several sessions under one Agent, will they mix together?**
No. Each session's context is independent, so you can safely use one for real work and another for experiments.

**Are the files I upload safe? Can others see them?**
A session is your personal resource — only you (and administrators) can see your sessions and the files in them.
