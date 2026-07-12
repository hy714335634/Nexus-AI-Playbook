---
title: Creating an Agent
sync:
  source_commit: 9d40a32f2bad2c7858b3ed0cfb4390e1bd603a30
  source_files:
    - agents/system_agents/agent_build_workflow/**
    - api/v2/routers/agents.py
    - api/v2/routers/workflows.py
    - web/app/(main)/agents/new/**
  generated_at: 2026-07-12T13:22:48+00:00
  generated_by: docs-sync v2
---

# Creating an Agent

An Agent is your own personal assistant. You just describe—in everyday language—what you want it to do for you, and the system automatically designs, builds, and launches it. No coding required at any point.

This guide walks you through creating an Agent from scratch and watching it get built.

::: tip Who this is for
Business users in marketing, operations, analytics, support, and similar roles. All you need is a browser—no technical background required.
:::

## Two ways to create

The system offers two ways to create an Agent. Pick the one that fits you:

| Method | Best when | What it does |
| --- | --- | --- |
| **Quick create** | You already know what you want | Write your request and start building right away |
| **Guided create** | You're still figuring it out | The system asks you a few questions first, helps you fill in the details, then starts building |

If this is your first time, try **Quick create** to get a feel for it. Save **Guided create** for when your needs are more complex.

## Where to start

There are several ways to open the create page—use whichever is closest:

1. The blue **Create Agent** button at the bottom of the sidebar
2. Click **Agents** in the left menu to open the list, then click **+ Create Agent** in the top right
3. The **"From idea to automated Agent"** card at the top of the home page, where you can type your request directly

![agents-list](/images/agents-list.png)

## Method 1: Quick create

The simplest way—you can do it right from the home page card.

1. Go to the home page (click **My Home** in the sidebar, or the logo in the top left).
2. Find the **"From idea to automated Agent"** card at the top.
3. In the text box, describe the Agent you want. The more specific, the better—for example:

   > Create a Chinese–English translation assistant: Chinese in, English out; English in, Chinese out; keep the tone of the original.

4. Click the **Build** button on the right (or press Enter).
5. The page jumps to the **build progress page**, where you can watch your Agent being built step by step (see [Watch your Agent get built](#watch-your-agent-get-built) below).

![quick-create](/images/quick-create.png)

::: tip Do I need to name the Agent?
No. Quick create automatically pulls a name from your description (the example above becomes "Chinese–English translation assistant"). You can rename it later, once it's built.
:::

### You can also pick "Quick create" on the create page

If you came in through the **Create Agent** button, you'll first see two cards. Click the left one:

- **Quick create** (⚡ icon)—"Enter your request directly, skip clarification, and start building right away. Best when your needs are clear."

From there it's the same: write your request and click Build, just like on the home page.

## Method 2: Guided create

If you haven't worked out the details yet, let the system help you fill them in.

1. Open the create page through any entry point.
2. Of the two cards, click the right one:
   - **Guided create** (💬 icon)—"AI analyzes the unclear points in your request and, through a few rounds of questions, helps you refine it into a more precise Agent."
3. Start with a sentence or two about your rough idea (write at least a dozen characters—if it's too short, the system will ask for more).
4. After you submit, the system analyzes your description, finds the vague or missing parts, and **asks you questions in a few rounds**. Some are single-choice, some multiple-choice, and some you fill in yourself.
5. Answer each question and continue to the next round. The top of the page shows "round X of Y" so you know how much is left.
6. Once the questions are done, the system pulls your answers together into a **more complete request** for you to confirm.
7. Confirm it looks right, then start building—this also takes you to the build progress page.

![guided-create](/images/guided-create.png)

::: tip How many rounds will it ask?
Usually up to three. Each question is there to make the final Agent fit your needs more closely, so answering carefully pays off.
:::

## Adding images or documents to your request (optional)

If you have existing materials—a sample screenshot, a spec document, a data sheet—you can hand them to the system to help it understand your request more accurately.

1. In the request area, find **Add attachment** (the paperclip icon).
2. Choose the files to upload. Common image, document, and spreadsheet formats are supported, up to 10 files at a time.
3. Once uploaded, the system **reads the file contents automatically**. Each file shows "Parsing… → Parsed".
4. Wait until every file shows "Parsed", then click Build.

::: warning Note
If you click Build while a file is still "Parsing", the system asks you to wait. Just submit once everything is parsed. If a file shows "Failed", remove it and try again or use a different file.
:::

## Watch your Agent get built

After you submit, the page jumps to the Agent's **build progress page**. Here you can see, in real time, what the system is doing.

![project-detail-stages](/images/project-detail-stages.png)

On this page you'll see:

- **Top**: the Agent's name, plus **Back**, **Pause**, and **Delete** buttons.
- **Summary cards**: total build time, usage, and other stats for this build.
- **Build stage timeline**: a vertical flow listing each stage and its status.

The icon in front of each stage tells you where it is:

| Icon | Meaning |
| --- | --- |
| ✅ | Stage complete |
| 🔄 | Stage in progress |
| ⏳ | Stage waiting in line |

The system starts by "understanding your request", then works through requirement analysis and design, and finally launches the Agent—all automatically.

::: tip How long does it take?
Usually 10 to 40 minutes, depending on how complex your request is. Feel free to do something else in the meantime—the build runs in the background, and you can return to this page anytime to see the latest progress.
:::

::: warning You don't have to watch the whole time
You can leave this page. To find it again later, use the "Build progress" area on the home page, or the Agents list. Once the build finishes, the Agent appears in your Agents list, ready to chat with.
:::

## After the build finishes

When every stage turns ✅, your Agent is ready. Now you can:

- Find it in the **Agents list** and open it to see the details.
- **Chat** with it directly to try it out.
- If it's not quite right, describe your improvements in a sentence and let the system update it for you.

## FAQ

::: tip What if I want to change my request mid-build?
Wait for the current build to finish, then use "Update" on the Agent's detail page to describe your changes. No need to delete it and start over.
:::

::: tip Can I create several Agents at once?
Yes. Each Agent is an independent build task and they don't affect each other.
:::

::: warning What if the build fails?
If a stage shows as failed, it usually means the request wasn't clear enough. Go back to the create page, write your request more specifically (what it should do, what goes in, what comes out), and create it again.
:::
