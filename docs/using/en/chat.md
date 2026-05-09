---
title: Chat & Sessions
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - api/v2/routers/sessions.py
    - nexus_utils/magician.py
    - web/src/app/(authed)/chat/**
  generated_at: 2026-05-08T15:02:50+00:00
  generated_by: docs-sync v2
---

# Chat & Sessions

The Chat page provides a dedicated conversation interface where you can have multi-turn interactions with any Agent. It is the primary entry point for validating Agent behavior and testing business scenarios. Open it from **Sessions** in the left navigation bar.

![Chat page](/images/chat.png)

## Starting a Conversation

### Step 1: Select an Agent

The **Select Agent** dropdown at the top-left lists every Agent currently in the running state.

![Select Agent](/images/chat-select-agent.png)

After picking an Agent, the conversation area appears on the right. Each Agent in the dropdown shows its name and a short description so you can identify it at a glance.

::: tip Only running Agents can chat
If the Agent you want is not in the dropdown, it is likely offline or in an error state. Check its status on the [Agent Management](/using/manage-agents) page.
:::

### Step 2: Create or Select a Session

Once an Agent is selected:
- The system automatically creates a **new session**
- You can also click the **+** button next to the session list to create a new session manually
- Or click any existing session in history to resume it

Each session has its own isolated context. Within the same session, the Agent remembers all previous turns.

### Step 3: Send a Message

1. Type your message into the **input box** at the bottom
2. Press **Enter** or click the **send button**
3. The Agent generates a response in real time (streaming output — text appears progressively)

## Intelligent Conversation Routing

The Nexus-AI chat system is more than a plain user-to-Agent Q&A loop. The platform embeds a **Magician Agent (Conversation Magician)** that manages the conversation intelligently:

### How the Magician Agent Works

When you start a conversation, the Magician Agent runs three steps in the background:

1. **Agent matching** — finds the most relevant Agent from the existing Agent catalog based on your question, scenario, and keywords
2. **Dynamic conversation Agent construction** — dynamically builds the most suitable conversation Agent from the match and the current question
3. **Question response** — the constructed conversation Agent handles the multi-turn response

In practice, the system automatically finds or constructs the best Agent for your question — you do not need to decide which Agent to call yourself.

### Three Conversation Modes

The platform supports three conversation modes depending on the complexity of the question and the number of Agents involved:

| Mode | Description | When to use |
|------|-------------|-------------|
| **Single Agent** | A single Agent handles the request on its own | Clear question, single domain |
| **Multi-Agent Swarm** | Multiple Agents collaborate as a "swarm intelligence" | Cross-domain questions that require dynamic negotiation between Agents |
| **Multi-Agent Graph** | Multiple Agents collaborate along a predefined graph structure | Complex multi-step flows with an explicit processing order |

::: info
The conversation mode is chosen automatically by the system — no manual setting is needed. The platform picks the best mode from your question's complexity and the Agents that are available.
:::

## Multi-Turn Conversations

Nexus-AI supports full multi-turn context management:

### Context Retention

Within the same session:
- The Agent remembers every previous turn
- You can follow up on earlier answers
- Contextual information stays consistent across the whole session
- Uploaded files remain part of the context

**Example conversation:**

```
You:   Please analyze the sales data I just uploaded.
Agent: Done. The data contains 1,200 records across 5 product categories.
       Category A has the highest sales, accounting for 35% ...

You:   What is the monthly trend for Category A?
Agent: Based on the data, Category A's monthly sales trend is:
       Jan: ¥120,000  Feb: ¥98,000 ...
       The overall trend is upward, with an average monthly growth of 8.2%.

You:   Turn that trend into a line chart.
Agent: Here is the monthly sales trend chart for Category A:
       [Mermaid chart]
```

### Starting a New Session

When you want to begin a completely new topic, create a new session:

- New session = fresh context = unaffected by previous conversations
- Old sessions are kept and you can switch back any time

::: tip When to create a new session
- **When changing topics** — put different analysis tasks into different sessions
- **When starting over** — if the earlier conversation has drifted off course, start fresh
- **When context grows too long** — an overly long context can degrade response quality
:::

## File Upload (Multimodal Interaction)

Nexus-AI supports **multimodal interaction** — you can upload files in a conversation so the Agent can analyze and process their contents.

### Upload Steps

1. Click the **📎 attachment button** next to the input box
2. Select one or more files to upload
3. Wait for the upload to finish (a progress bar shows the status)
4. Type your question or instruction in the input box, e.g.:
   - "Please analyze the data in this Excel file"
   - "Summarize the core content of this PDF"
   - "What information is in this image?"
5. Click send — the Agent will analyze the files together with your prompt

### Supported File Formats

| Format | File type | Typical use |
|--------|-----------|-------------|
| **JPG / PNG** | Image files | Chart analysis, OCR, image description |
| **PDF** | Document files | Document summaries, content extraction, information lookup |
| **Excel (.xlsx)** | Spreadsheets | Data analysis, statistics, trend analysis |
| **Word (.docx)** | Document files | Content summaries, document editing, format conversion |
| **CSV** | Data files | Data analysis, data cleaning, visualization |
| **TXT** | Plain text files | Text analysis, information extraction |

### File Limits

| Limit | Quota |
|-------|-------|
| **Single file size** | Up to **50 MB** |
| **Attachments per message** | Up to **5 files** |

::: warning
Files over the size limit cannot be uploaded. If a file is too large, split it into smaller files or compress it first.
:::

### File Usage Tips

| Scenario | Recommended prompt |
|----------|--------------------|
| Analyzing Excel data | Upload the file + "Please analyze the key characteristics and outliers in this data" |
| Summarizing a PDF | Upload the file + "Please summarize the core content of this document in 300 words" |
| Comparing multiple files | Upload several files + "Please compare the differences between these files" |
| Extracting image information | Upload an image + "Please describe the image and extract the key information" |

## Agent Response Formats

Agent replies support a rich set of formatted content:

### Markdown

The Agent can return full Markdown content:

- **Headings** — structure long replies
- **Lists** — ordered and unordered
- **Tables** — tabular data
- **Links** — references and citations
- **Blockquotes** — quoted passages
- **Bold / italic** — emphasis

### Code Blocks

Code returned by the Agent is rendered with **syntax highlighting**:

- Supports Python, JavaScript, SQL, and many other languages
- One-click copy for code blocks

### Mermaid Diagrams

The Agent can generate **visual diagrams** using Mermaid syntax:

- **Flowcharts** — business flows or decision logic
- **Architecture diagrams** — system architecture or component relationships
- **Sequence diagrams** — interaction sequences
- **Gantt charts** — plans and progress

::: info
Mermaid diagrams are rendered live inside the conversation — no extra tooling required.
:::

## Session Management

The left panel manages all your sessions:

| Action | How | Description |
|--------|-----|-------------|
| **Create a new session** | Click the **+** button | Start a fresh conversation context |
| **Switch sessions** | Click an item in the session list | Jump to another session and review its history |
| **View history** | Click any existing session | Replay the full conversation history |
| **Resume a conversation** | Send a message in a historical session | Continue from the previous context |

Each session shows:
- **Session title** — usually a summary of the first message
- **Last update time** — when the most recent turn happened
- **Message count** — total number of messages in the session

## Other Entry Points for Chat

Besides the Sessions page, you can also start a conversation from:

| Entry point | Location | Description |
|-------------|----------|-------------|
| **Workbench** | "Running Agents" section | Click the "Chat" button on an Agent card |
| **Agent detail page** | Conversation area at the bottom of the page | Chat directly inside the Agent's detail view |
| **Agent list** | Hover over an Agent card | Click the "Chat" shortcut button |

## Chat Best Practices

### Prompting Tips

| Tip | Why | Example |
|-----|-----|---------|
| **Be specific** | The more specific the question, the more accurate the answer | ✅ "How did Q3 2024 sales grow year-over-year?" ❌ "Show me the data" |
| **Use attachments** | Upload files so the Agent can analyze them directly | Upload an Excel file + "Please aggregate sales by month" |
| **Ask step by step** | Break complex questions into smaller steps | First "Summarize the data" → then "Analyze outliers" → then "Suggest improvements" |
| **Provide context** | Background information helps the Agent understand | "I'm a product manager preparing next week's product review report ..." |
| **State the output format** | Make the expected output explicit | "Please compare the pros and cons of these two options in a table" |

### Troubleshooting

| Problem | Cause | Resolution |
|---------|-------|------------|
| Inaccurate Agent reply | Question is not specific enough or missing context | Provide a more detailed question and background information |
| Agent cannot process a file | The Agent has no file-handling tools | Check the Agent's tool list; you may need to create a new Agent |
| Response takes too long | Heavy content or high model load | Reduce file size or split the request |
| Context is confused | The session is too long and the context is overloaded | Create a new session and start fresh |
| Agent is offline and cannot chat | The Agent has not been started | Start the Agent from the Agent Management page |
