---
title: Spotlight Command Palette
sync:
  source_commit: 460f1a3f6eaf3f2c86b695c2043a5d944b0ce733
  source_files:
    - web/components/spotlight/SpotlightCommandPalette.tsx
  generated_at: 2026-07-12T14:35:51+00:00
  generated_by: docs-sync v2
---

# Spotlight Command Palette

Spotlight is a site-wide search and shortcut hub. Wherever you are, one keyboard shortcut brings it up: type a few characters and instantly find a page, an Agent, an app, a past conversation, or run a common action like "Create Agent" or "Refresh page" in one step. No more clicking through menus to hunt things down.

::: tip One shortcut for the whole site
Just remember `⌘K` (Mac) or `Ctrl+K` (Windows). Wherever you want to go, whatever you want to find or do — press it first.
:::

## Open Spotlight

Any of three ways works:

1. Press **`⌘K`** (Mac) or **`Ctrl+K`** (Windows / Linux) — the fastest.
2. Click the search box at the top of the left sidebar: **"Search or ask... ⌘K"**.
3. Click the search box in the top action bar: **"Search... ⌘K"**.

The screen dims, a search panel appears in the center, and the input box is already focused — just start typing.

![dashboard](/images/dashboard.png)

## What the panel looks like

The panel has two parts, top to bottom:

- **Search box** at the top: type what you're looking for; the small **"ESC"** tag on the right reminds you that Esc closes the panel.
- **Results list** below: pages you can jump to, actions you can run, and content matches, all organized into groups.

**Before you type anything**, a **Recent** group sits at the top of the list, showing the pages you visited most recently so you can jump right back.

## Search for what you need

Type a keyword in the search box and the list **filters in real time**, narrowing as you type with almost no delay.

- Matching is loose: anything whose name, description, or tags **contain** your text shows up, case-insensitive.
- Type `agent`, for example, and the list keeps only related items: "Create Agent", "Agents", "Chat with Agent", plus your individual Agents and related sessions and tools.

![spotlight-search](/images/spotlight-search.png)

## What you can find and do

Spotlight organizes the whole site into groups so you can reach everything from one place:

| Group | What's inside | On Enter |
|-------|---------------|----------|
| Recent | Pages you visited recently | Jump back to that page |
| Quick actions | Common actions like create and refresh | Run the action immediately |
| Pages | Site-wide navigation: Dashboard, Agents, Chat, Tools, and more | Go to that page |
| Apps | Apps in the App Center | Open the app; published ones also offer a one-click public page |
| Agents | All your Agents | Open that Agent |
| Sessions | Recent conversations | Return to that conversation |
| Projects | Builds in progress or completed | View the build status |
| Integration | Connected connectors | Open the matching settings |
| Tools / MCP servers | Built-in platform tools and connected services | View the summary or info |

::: tip Groups change with your account
These groups **only appear when they have content**. If you haven't created any apps, you won't see the Apps group; the number next to each group heading is how many items it contains.
:::

## What the quick actions are

When you haven't typed a search term, the **Quick actions** group holds the most common one-click actions:

- **Create Agent** — describe what you need in plain language and start building a new Agent.
- **New project** — kick off an Agent build.
- **New app** — go to the App Center to create an AI app.
- **Refresh page** — reload the current page.
- A set of **Avatar** actions: have your Avatar organize your activity now, generate suggestions from its current state, open the knowledge graph, view its notifications, browse its space files, or chat with it directly.

## Use the keyboard

Spotlight is built for the keyboard — you can run it start to finish without a mouse:

1. Type to **filter** the results.
2. Press **↑ / ↓** to move the selection; the selected item is highlighted.
3. Press **Enter** to open or run the selected item.
4. Press **Esc** to close the panel; or click the dark area outside the panel.

::: tip Some items have a second button
When an item is selected, small buttons may appear on the right: apps have "Open public page" (opens the public address in a new tab), Agents have "View summary" and "Chat", and projects have "View status". Press Enter for the main action, or click the small button for these extras.
:::

## FAQ

**How is Spotlight different from a normal search box?**
It's more than a search box — it's a site-wide command hub: it searches content *and* jumps to pages *and* runs actions. One entry point covers both finding things and doing things.

**Why don't I see certain groups?**
Groups only show when they have content. No apps means no Apps group; no past conversations means no Sessions group — that's normal, and the more you use the platform, the more you'll be able to find.

**What if I type something and get no results?**
There's no match right now, and the panel shows a no-results message. Try a shorter or more common keyword — for instance, just the first few characters.

**Do I lose anything by closing the panel?**
No. Spotlight is only a temporary search-and-jump layer; closing it doesn't affect whatever you were doing, and you can bring it back anytime with `⌘K`.
