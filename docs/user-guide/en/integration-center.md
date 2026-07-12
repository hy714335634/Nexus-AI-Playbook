---
title: Integration Center
sync:
  source_commit: 9d40a32f2bad2c7858b3ed0cfb4390e1bd603a30
  source_files:
    - api/v2/routers/connectors.py
    - api/v2/routers/directives.py
    - api/v2/routers/template_assets.py
    - config/data_connector.yaml
    - nexus_utils/data_connector/config_loader.py
    - nexus_utils/data_connector/registry.py
    - web/app/(main)/integration/**
  generated_at: 2026-07-12T13:45:02+00:00
  generated_by: docs-sync v2
---

# Integration Center

The Integration Center is where you set up the "external backup" your Agents rely on. A capable Agent often needs more than its own skills: a ready-made PPT/Word template to reuse, a batch of company data to read, an access token to log in to a third-party service, and a set of rules your team has agreed on. Those four needs map to the four sections here.

This page introduces the four sections and walks you through the most common task in each — start to finish, on your own.

## Open the Integration Center

Click **Integration** in the left sidebar. The top of the page shows four cards, each with a number telling you how many items that section currently holds. Click any card to switch to that section:

| Card | What it does | In one line |
|------|--------------|-------------|
| Templates | Stores your template files | Gives Agents ready-made styles to reuse when generating documents |
| Connectors | Connects external business data | Lets Agents read your spreadsheets, files, and system data |
| Keys | Keeps account credentials | Stores tokens for third-party services safely |
| Directives | Defines how work should be done | Gives Agents a shared set of goals, limits, and steps |

![integration-connectors](/images/integration-connectors.png)

::: tip What the numbers mean
The number on each card is a live count. If **Keys** shows 2, you can currently see 2 keys; a smaller line below shows their status (e.g. "2 bound").
:::

---

## Templates

### What this is

Templates are **template files** you upload — a polished PPT, a formatted spreadsheet, a Word or web-page template. Once uploaded, an Agent can reuse them when it generates a document for you, so the output already matches your house style and you don't have to reformat from scratch every time.

Supported file types fall into a few groups: PPT, Excel, documents (Word / PDF / text), HTML pages, images, and more.

### Upload a template

1. Switch to the **Templates** section.
2. In the middle there's a big **drag-and-drop area** that says "Drag files or folders here to upload." You have two ways to upload:
   - Drag files (or a whole folder) into the area; or
   - Click **Choose File** in the area to pick one or more files, or **Choose Folder** to upload an entire folder.
3. Once selected, files appear in the list below the upload area and upload one by one:
   - Spinner = uploading;
   - Green check = uploaded successfully;
   - Red exclamation = failed (the reason shows on the right).

![integration-templates](/images/integration-templates.png)

::: tip There's a short wait after uploading
After a file finishes uploading, the system automatically generates a preview image and summary for it in the background. Wait a moment and the preview will appear on the card — feel free to do something else in the meantime.
:::

### Find and filter templates

The left column has a filter bar to help you locate templates quickly when there are many:

- **Scope**: **All** / **Created by me** / **Shared with me** — switch whose templates you see.
- **Category**: **All Categories** / **PPT** / **Excel** / **Documents** / **HTML** / **Others**.
- The search box at the top right searches by template name.

### Search with AI

To the right of the search box is a **✨ AI** button. Turn it on and the search box switches to "describe the template you want in plain language." Type a sentence (e.g. "a blue business-style PPT for a quarterly results review") and the system finds matches by meaning, not just by name. Click **✨ AI** again to switch back to normal search.

### View and manage a template

Click any template card and a **detail panel** slides out on the right, where you can see the preview, download, manage versions, and share or delete.

To act on a template, you can also **right-click** (long-press on mobile) the card to open a menu:

- **View Details** — open the detail panel above;
- **Share** — share the template with colleagues or a team;
- **Move to Folder** — organize it;
- **Delete** — remove the template (asks for confirmation first).

::: warning Delete with care
Once deleted, the template is no longer in the list. If some Agents were using it as their template, they'll no longer be able to apply that style.
:::

### Group templates into collections

At the bottom of the left filter bar you can switch between **Assets view** and **Collections view**. A **collection** works like a folder for grouping related templates:

1. Switch to **Collections view**.
2. Click **+ New Collection**.
3. Enter a name and click **Save**.

---

## Connectors

### What this is

Connectors let an Agent read your company's **business data** — sales records in an online spreadsheet, reports stored in the cloud, a customer list in an internal system. Once connected, when you ask the Agent in chat "how much did the East region sell last month," it can look up the data and answer on its own.

::: warning Ask a technical colleague to help fill this in
Creating a connector requires some connection details (address, account, and so on), which usually need help from someone technical. Your job is to make clear "which data to connect and who it's for," and let IT fill in the exact settings.
:::

### Create a connector

1. Switch to the **Connectors** section.
2. Click the plus button to the right of the search box to open the create form.
3. Choose a **data source type** (the list covers online spreadsheets, cloud files, network endpoints, business systems, and more).
4. Fill in the name, description, and the connection details required for that type.
5. After saving, the connector appears in the list on the left.


### Test whether the connection works

Once created, it's best to confirm it can actually reach the data:

1. Select a connector in the left list; the details show on the right.
2. Click **Test Connection** at the top right.
3. Wait a moment — success reports the connection is fine, failure reports an error. A failure usually means the address or credentials are wrong, so go back to the config, fix them, and test again.

The small icon on the left card also reflects the status: a green check means healthy, a red cross means an error.

### Bind a key to a connector

If reaching the data needs an account/token, you can attach a **key** you saved earlier instead of writing the token into the connector itself:

1. In the connector details, switch to the **Key Binding** tab.
2. Pick an existing key from the dropdown ("No key" means access with the default identity, no token needed).
3. After choosing, click Save.

See [Keys](#keys) below for how to create one.

### Browse what's in the data

The connector details also have a **Schema** tab. Open it and the system will **list what's inside this data source** (which tables and fields exist), so you can confirm you connected to the right place.

### Delete a connector

In the top right of the connector details, click the trash icon and confirm to delete.

---

## Keys

### What this is

Keys is a **secure vault** dedicated to storing access tokens of all kinds — tokens for third-party services, cloud credentials, login tokens, and so on. Once stored, tools and connectors pull them automatically when needed, while the token itself always stays in the vault and is never exposed in plain text.

The walkthrough environment already has two real key examples, `dashscope_api_key` and `ark_api_key`, both tokens used by image-generation tools.

### Create a key

1. Switch to the **Keys** section.
2. Click **New Key** at the top right.
3. Choose a **key type** — different types ask for different fields:

   | Type | Used for | Main fields |
   |------|----------|-------------|
   | **API Key** | An access token for a third-party service | An API key |
   | **Database Credentials** | Connecting to business data | Host, port, username, password |
   | **Bearer Token** | Token-based authentication | A token |
   | **AWS Credentials** | Accessing cloud services | Access Key ID, Secret Access Key |
   | **GCP Service Account** | Accessing online spreadsheets / warehouses | A service account blob |
   | **OAuth 2.0** | Authorized login | Client ID, Client Secret |
   | **Custom** | When none of the above fits | Add your own fields |

4. Fill in the name, description, and the fields required by the chosen type.
5. Choose the **visibility** (Private / Shared) and save.

![integration-keys](/images/integration-keys.png)

::: tip AWS credentials can be left empty
If your system already has a default access identity configured, you can leave the fields empty when creating **AWS Credentials** — the system will use the default identity automatically, no need to type a token.
:::

### View and change a key's contents

Select a key and the detail panel on the right opens on the **Details** tab, showing name, type, visibility, creation time, and so on.

- To see the stored token value, click **Show value** (values are hidden by default; click once to reveal the plain text).
- To change it, click **Show value** first, then **Edit**, make your changes, and click **Save**.

### Bind a key to a tool

Some tools need a token to work. In the key's **Bindings** tab, you can assign this key to the relevant tools; they'll then pull it automatically at run time, with no need to type it each time.

### Share a key with colleagues

In the key's **Sharing** tab, you can share the key with specific colleagues or teams.

::: warning Keys can't be made public to everyone
For security, a key can only be shared with specific people or teams — it **can't be made public to everyone**.
:::

### See how much a key is used

The **Usage** tab shows how many times the key has been called, how many people/Agents have used it, and when it was last used — helpful for deciding whether it's still in use and safe to delete.

### Delete a key

In the top right of the key details, click the trash icon and confirm.

::: warning Don't delete a key that's still in use
If a key card shows a binding count (a chain icon + a number), tools or connectors are still using it, and deleting it will break their access — unbind them first.
:::

---

## Directives

### What this is

Directives are where you set the "rules of work" for an Agent. You build a tree in an **Organization → Department → Directive** hierarchy, and in each directive you spell out: what the goal is, which red lines can't be crossed, which standards to follow, and what "done well" looks like. Once set and applied to a chat, the Agent works by these rules, keeping the whole team consistent.

### Three working modes

Each directive can pick a mode that decides how much freedom the Agent has:

| Mode | Character | Best for |
|------|-----------|----------|
| Guided | Gives direction and suggestions; the Agent works things out | Most day-to-day tasks |
| Strict | Follows the steps you laid out, one by one | Fixed processes where errors aren't acceptable |
| Open | Fewest limits, maximum freedom | Exploratory, creative tasks |

### Get to know this page

- The **top right** has a row of buttons: **New Node**, **Create Structure from Natural Language**, **Import from Document**, and **Refresh**.
- The **bottom right** has two floating buttons: **Create Manually** and **AI Create**.
- The left side is the **organization tree**; the right side is the **editor** for the node you select.
- **Right-clicking** a node in the tree opens a menu (rename, publish, preview, share, delete, and more).

![integration-directives](/images/integration-directives.png)

### Create a node manually

1. Click **New Node** at the top right (or **Create Manually** at the bottom right).
2. Choose the node type: **Organization**, **Department**, or **Directive**. Organizations and departments are the skeleton for grouping; the real rules live in **Directive** nodes.
3. Enter a name, choose where it sits in the tree, and create it.
4. The new node is highlighted for a few seconds so you can find it.

### Generate a whole org structure from one sentence

Building nodes one at a time too slow? Click **Create Structure from Natural Language** and describe your organization and responsibilities in plain words (e.g. "Marketing handles campaigns and content, Support handles after-sales questions"), and the system builds the whole tree for you. You can tick "preview only" to check the result first, then create it for real once you're happy.

### Import from a document

If you already have a written policy or process document, click **Import from Document**, paste its content, and the system will **extract directive nodes from it** for you.

### Edit a directive

Select a **Directive** node in the tree, and the editor on the right splits into a few tabs to fill in:

- **Basics** — state this directive's **goal** (what to achieve) and pick a working mode.
- **Rules** — enter **constraints** (things never to do), **guidelines** (how it should be done), and **quality criteria** (what counts as acceptable). You can click "Add" to add multiple entries to each.
- **Collaboration** — set up steps that need coordination across departments.
- **Resources** — specify the skills, tools, connectors, and keys this directive may use.

Remember to click Save when done.

::: tip Let AI fill it in for you
Can't come up with constraints and standards? Find **AI Fill** in the editor: as long as you've written the "goal," the system generates a set of constraints, guidelines, and quality criteria from it, which you can then fine-tune.
:::

### Preview what the Agent will see

Want to know how this directive is finally conveyed to the Agent? Use **Preview** in the node's right-click menu to see the complete instructions the system assembles from what you filled in.

### Publish, unpublish, and archive

A directive must be **published** before it can be used for real. Right-click a directive node:

- **Publish** — make a draft take effect (before publishing, its status is "Draft").
- **Unpublish** — pull it back to an editable state.
- **Archive** — put it away for now; you can **Reactivate** it when needed.

### Apply to a chat

Once a directive is published, you can apply it to a chat so that the conversation follows these rules from then on.

### Version management

For bigger changes, you can **save a version snapshot** of the current state. If you later change your mind, you can view the version history and **restore** an earlier version, without fear of breaking things.

---

## FAQ

::: tip How do the four sections relate?
They're independent but work together: **Keys** store tokens, **Connectors** use keys to reach data, **Templates** provide styles, and **Directives** unify the rules. You can use just one or two — you don't have to set up all four.
:::

::: tip Can others see the templates/data/keys I create?
By default they're private — only you can see them. To let colleagues use them, use the matching **Share** feature to pick who to share with. Note that, for security, keys can't be made public to everyone.
:::

::: warning Can't find what you just created?
Click **Refresh** at the top right, or re-enter the section. The lists are live counts and occasionally need a manual refresh.
:::
