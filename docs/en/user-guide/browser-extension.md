---
title: Browser Extension
sync:
  source_commit: 9d40a32f2bad2c7858b3ed0cfb4390e1bd603a30
  source_files:
    - api/v2/routers/browser.py
    - nexus_utils/browser/**
    - web/app/(main)/settings/browser-extension/**
  generated_at: 2026-07-12T13:57:34+00:00
  generated_by: docs-sync v2
---

# Browser Extension (Nexus Bridge · Browser Mode)

The **Nexus Bridge** panel offers two connection modes:

| Mode | Tab | Purpose |
| --- | --- | --- |
| **Remote Server** | "Remote Server" | Let an Agent run commands and manage files on your server (see [Connecting a Server to Run Tasks](./bridge-server.md)) |
| **Browser** | "Browser" | Let an Agent control your Chrome browser directly (this page) |

This page covers **Browser mode** — the browser extension lets a Nexus assistant **do things directly in your Chrome browser**: open pages, read what's on them, click buttons, and fill in forms. You describe the task in a chat, and the assistant works through it step by step in a dedicated browser tab. When something needs you personally — a CAPTCHA or a login — it stops and asks.

Once the extension is installed and connected, you can see which browsers are linked to your account at any time and disconnect them when you no longer want them.

::: tip When this helps
Great for repetitive point-and-click work like "fill out this batch of forms on that site," "open these pages and compare prices," or "go into the back office and export today's orders."
:::

## What the extension can do

- Open any page you point it to
- Read which buttons, links, and input fields are on the current page
- Click, type, and submit on your behalf
- Open several tabs at once to compare across pages or process in bulk
- When it hits a CAPTCHA, two-factor prompt, or login wall, it stops and hands it to you — finish it, reply once, and it continues

## Before you start

You'll need:

1. A computer with the **Chrome browser**
2. A working Nexus login (your usual account)
3. The Nexus Chrome browser extension installed (if you don't have it yet, ask your administrator for the package or install instructions)

## Connect the extension

After the extension is installed, link it to your Nexus account so the assistant can use it.

1. Open any **chat page** (go to "Chat" in the left menu).
2. Find the **"Nexus Bridge"** panel on the chat page and click its **"Browser"** tab.
3. Follow the panel's prompt to connect. Once connected, the extension is tied to the account you're currently signed in with.

![chat](/images/chat.png)

::: tip Can't connect?
First make sure the Nexus extension is enabled in Chrome and that you're signed in to Nexus in the same browser. If it still won't connect, refresh the chat page and try again.
:::

## First-time authorization

The first time the assistant tries to act in your browser, the browser may show an **authorization prompt** asking whether to allow it. Click "Allow" so the assistant can continue.

::: warning Don't leave the prompt sitting
If you don't confirm within about a minute, that action times out and fails. Confirm the prompt promptly; if you miss it, just ask the assistant to try again.
:::

## Manage connected extensions

You can see which browsers are linked to your account and disconnect them whenever you like.

1. Go to **"Settings" → "Configuration"** and click the **"Browser Extension"** shortcut at the top (or open the "Settings · Browser Extension" page directly).
2. The top of the page shows **"Connected extensions (N)"**, where N is the current number of connections.
3. Each connection lists the browser it runs in and when it was last used.

![settings-browser-extension](/images/settings-browser-extension.png)

Actions on this page:

| Action | What it does |
| --- | --- |
| "Refresh" | Pulls the latest connection status |
| "Show revoked" | Check this to also list connections you've already disconnected |

::: tip No extensions connected yet
If you've never connected one, you'll see **"No connected extensions"** and a hint to "connect the extension from the Browser tab in the Nexus Bridge panel on the chat page" — just follow the *Connect the extension* section above.
:::

### Disconnect an extension

When you no longer want a browser acting on your account, disconnect it:

1. Find that connection in the list.
2. Click its "Revoke" action.
3. Once disconnected, any browser task running in that browser stops immediately, and the assistant can no longer use it.

### Restore a disconnected extension

1. Check **"Show revoked"** so disconnected connections appear.
2. Find the one you want back and click "Reinstate".
3. **It won't reconnect on its own** — you need to connect again from the Nexus Bridge panel on the chat page, as described in *Connect the extension*.

## Let the assistant work in your browser

Once connected, go back to the chat and describe the task in plain language, for example:

> Open the order page in our back office and filter to today's orders.

The assistant works in a dedicated **browser tab** where you can watch each step it takes.

::: tip Working across pages
You can have the assistant open several tabs at once (for example, keep a search-results tab open while it opens each result). There's a limit on how many tabs each browser task may open — see *Usage limits* below.
:::

## CAPTCHAs and logins

The assistant won't solve CAPTCHAs for you, and it won't enter your username and password. When it runs into these:

1. It **stops** and tells you in the chat what it needs (for example, "please complete the CAPTCHA in the browser").
2. Switch to that browser tab and finish the verification / login yourself.
3. Return to the chat, reply "done" or "continue," and the assistant picks up where it left off.

::: tip No waste while it waits
While the assistant waits for you, it isn't tying up resources. It continues whenever you come back and reply.
:::

## Usage limits

To keep resource use in check, browser work has two caps (the exact numbers are set by your administrator; defaults are shown below):

| Limit | Default | Notes |
| --- | --- | --- |
| Concurrent browser tasks | 5 | Beyond this, finish one before starting another |
| Tabs per task | 10 | At the cap, have the assistant close finished tabs before opening new ones |

## FAQ

::: tip Can the extension see my other pages?
The assistant only works in the tabs it opened itself — it can't reach content in your other windows or tabs.
:::

::: warning Connections expire
A connection has an expiry, after which the assistant can no longer use it. If the assistant can't reach your browser, just reconnect from the Nexus Bridge panel on the chat page.
:::

::: tip Disconnect when you're done
On a shared computer, or whenever you no longer need it, revoke the connection on the "Settings · Browser Extension" page for peace of mind.
:::
