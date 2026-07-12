---
title: Sign In & UI Tour
sync:
  source_commit: 9d40a32f2bad2c7858b3ed0cfb4390e1bd603a30
  source_files:
    - web/app/(auth)/login/**
    - web/src/components/layout/sidebar.tsx
  generated_at: 2026-07-12T13:13:45+00:00
  generated_by: docs-sync v2
---

# Sign In & UI Tour

This is your first step with Nexus AI. This page shows you how to sign in and then walks you through everything you see afterward: the navigation bar on the left, the action area at the top, the search panel that's always at hand, and switching between Chinese and English. After reading it, you'll be able to find your way around on your own.

## Sign In

1. Open your browser and go to the web address your administrator gave you. If you signed out earlier, the system also brings you back to the sign-in page automatically.
2. You'll see a sign-in page labeled "Nexus AI" with a sign-in card in the middle.
3. Type your account name in the "Username" box.
4. Type your password in the "Password" box.
5. Click the "Sign in" button.

![login](/images/login.png)

Once you sign in successfully, the page jumps to the dashboard home automatically, and you're ready to start.

::: tip No need to sign in every time
After you sign in, refreshing the page or closing and reopening your browser usually keeps you signed in, so you don't have to type your account and password every time.
:::

::: warning If sign-in doesn't work
If the account name or password is wrong, a red message appears at the top of the card. Double-check and try again. There's no "forgot password" link here — if you've forgotten your password, ask your administrator to reset it for you.
:::

::: info Some organizations use single sign-on
If your organization has turned on "single sign-on," the sign-in page won't show username and password boxes. Instead you'll see a single button that takes you straight to your organization's own sign-in page. Enter your account there, and once you're verified you're sent back to Nexus AI automatically. What you actually see on your page is what applies.
:::

## Getting to Know the Interface

After signing in, the screen has two main parts: **the navigation bar on the left**, used to switch between features, and **the main content area on the right**, which shows the content of the page you're currently on.

![dashboard](/images/dashboard.png)

### The Left Navigation Bar

From top to bottom, the left navigation bar contains:

| Area | Contents | What it does |
| --- | --- | --- |
| Top | Product logo and name | Click it anytime to return to the dashboard home |
| Search entry | "Search or ask…" | Opens the global search panel (covered in the next section) |
| Main navigation | Dashboard, My Home, Agents, Chat, Projects, Capability Center, Integration, App Center, Shared Resources, Events, Business Insights, Usage Report, Audit, Service Status | Click to go to the matching feature page |
| Bottom | Settings, Users, language switch, your account info, Sign out | Account-related actions and system settings |

Click any item and the main content area on the right switches to the matching page. Whichever item you're currently on is highlighted in color.

::: tip You may see fewer menu items
Which items show up in the navigation bar depends on your account's permissions. Items like "Users," "Settings," and "Audit" are usually available only to administrators. If you don't see a certain item, your account simply doesn't have that permission yet — this is normal.
:::

### Collapsing and Expanding the Navigation Bar

If you want more room in the main content area:

1. Move your mouse to the top of the navigation bar and click the collapse button to the right of the logo.
2. The navigation bar narrows to a single column of icons.
3. To check what an icon is, hover over it and its name appears; hover over the narrowed bar and it expands for a preview automatically.
4. Click the button at the top again to pin the navigation bar back to its expanded state.

### The Account Area at the Bottom

The very bottom of the navigation bar holds actions related to your account:

- **Your account info**: shows the username you're signed in as; click it to open your profile page.
- **Sign out**: click to sign out of the current account and return to the sign-in page.
- **Language switch button**: switches between Chinese and English (see below).

## Jump Anywhere with the Search Panel

The interface hides a handy search panel that lets you jump straight to where you want to go, or run a common action, without clicking through menus.

1. Press `⌘K` (Mac) or `Ctrl+K` (Windows), or just click "Search or ask…" in the navigation bar.
2. A search box pops up in the middle of the screen, with the cursor already placed for you.


3. Before you type anything, the panel lists common destinations by category — for example "Dashboard," "Create Agent," "Agents," and "Chat" — and you can move through them with the up and down arrow keys.
4. To find something quickly, just type a keyword. For example, type `agent` and the list instantly narrows to only related items — including pages, your Agents, related conversations, and more.


5. Use the arrow keys to select an item and press Enter to jump to it. Some items also have small buttons on the right, like "Chat" or "View details," that you can click directly.
6. To close the panel, press `Esc`, or click the gray area outside the panel.

::: tip One shortcut is all you need
Just remember `⌘K` / `Ctrl+K` and you can open this search panel from any page — it's the fastest way to get around the whole product.
:::

## Switching the Interface Language

Nexus AI supports both Chinese and English, and you can switch anytime.

1. Find the language button at the bottom of the left navigation bar: it shows "EN" in the Chinese interface and "中" in the English interface.
2. Click that button.
3. The page refreshes automatically (about one or two seconds). After it refreshes, every menu, button, and title switches to the other language.


::: tip Your language choice is remembered
Once you switch, the system remembers your choice and keeps that language the next time you sign in. Note: content you created yourself, such as Agent names and project names, isn't translated and keeps its original text.
:::
