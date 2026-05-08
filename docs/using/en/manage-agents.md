---
title: Managing Agents
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - api/v2/routers/agents.py
    - web/src/app/(authed)/agents/**
  generated_at: 2026-05-08T15:05:33+00:00
  generated_by: docs-sync v2
---

# Managing Agents

The Agent management page is your hub for viewing, managing, and operating every Agent you have built. Open it from **"Agents"** in the left navigation.

![Agent list](/images/agent-list.png)

## Agent List

### Search Agents

A **search box** at the top of the page lets you quickly find an Agent by typing its name or a keyword. Fuzzy matching is supported.

### Multi-dimensional Filters

The Agent list supports several filter dimensions to help you locate a target quickly when you have many Agents:

#### Filter by Deployment Type

| Filter | Description |
|--------|-------------|
| **All types** | Show all Agents |
| **Local** | Agents running on the Nexus-AI server |
| **AgentCore (Cloud)** | Agents deployed on AWS Bedrock AgentCore |

**Differences between the two deployment types:**

| Feature | Local | Cloud (AgentCore) |
|---------|-------|-------------------|
| **Runtime location** | Nexus-AI server | AWS Bedrock AgentCore |
| **Best for** | Development, internal use, quick validation | Production, high-availability workloads |
| **Scalability** | Bounded by server resources | Auto-scales |
| **Operations** | You manage runtime state | Managed by AWS |
| **How to switch** | From the Agent detail page | From the Agent detail page |

#### Filter by Runtime Status

| Filter | Indicator | Meaning |
|--------|-----------|---------|
| **All statuses** | Shows all Agents | — |
| **Running** | Green | Agent is running normally; ready for chat |
| **Offline** | Gray | Agent is stopped; you need to start it manually |
| **Error** | Red | Agent hit a runtime error; investigation required |

#### Filter by Category Tag

The page lists all available **category tags** (such as `cloud_consulting`, `data_analysis`, `medical_research`, etc.). These tags are generated automatically by the system based on an Agent's capabilities at build time. Click a tag to filter Agents of that category.

## Agent Cards

Each Agent is shown as a card with its key information:

| Field | Description | Example |
|-------|-------------|---------|
| **Name** | The Agent's name | "Medical Literature Research Assistant" |
| **Status** | Runtime status | Running (green) / Offline (gray) / Error (red) |
| **Version** | Current version | "1.0", "1.1" |
| **Deployment type** | Local or cloud-hosted | "local" / "agentcore" |
| **Category tag** | Capability category | "data_analysis", "medical_research" |
| **Invocations** | Cumulative invocation count | "156" |
| **Created at** | When the Agent was created | "17 days ago" |

### Quick Actions on the Card

Hover over an Agent card to reveal two shortcut buttons:

- **"View details"** — Open the Agent's full detail page
- **"Chat"** — Open a chat window and talk to the Agent directly

## Agent Detail Page

Click **"View details"** to open the Agent's full detail page, which shows every piece of information and every operation you can perform.

![Agent detail](/images/agent-detail.png)

### Overview Metrics

The top of the detail page shows the Agent's core runtime data:

| Metric | Description | Purpose |
|--------|-------------|---------|
| **Invocations** | Cumulative invocation count | Understand how often the Agent is used |
| **Avg. conversation turns** | Average number of turns per conversation | Reflects depth and complexity of conversations |
| **Total tokens** | Total tokens the Agent has consumed | Understand resource usage |
| **Input tokens** | Tokens spent on user input | — |
| **Output tokens** | Tokens spent on Agent output | — |
| **Avg. invocation duration** | Average response time per invocation | Evaluate the Agent's responsiveness |

### Configuration Info

| Field | Description |
|-------|-------------|
| **Agent ID** | The Agent's unique identifier |
| **Linked project ID** | Identifier of the project that built this Agent |
| **Category tag** | Capability category (e.g., `data_analysis`) |
| **Deployment type** | `local` or `agentcore` |
| **Created at** | When the Agent was created |
| **Last invoked at** | Time of the most recent invocation |
| **Code path** | Storage path of the Agent code file |
| **Prompt path** | Storage path of the system prompt file |

### Quick Action Buttons

A cluster of action buttons sits on the right side of the detail page:

| Button | Function | Description |
|--------|----------|-------------|
| **Start chat** | Open the chat window | Test the Agent in a multi-turn conversation |
| **View / edit files** | Code editor | View and edit Agent code and prompts online |
| **View project** | Jump to the linked project | Open the project that built this Agent |
| **Update Agent** | Incremental update | Use the Agent Update Workflow to apply new requirements |

### Code Viewing and Editing

The detail page offers online **code viewing and editing** with syntax highlighting:

| File type | Description | Format |
|-----------|-------------|--------|
| **Agent code** | The Agent's main program file | Python (.py) |
| **Tool code** | Tool functions attached to the Agent | Python (.py) |
| **System prompt** | The prompt that defines Agent behavior | YAML (.yaml) |

You can edit these files online and the changes take effect immediately:

- **Tune the prompt** — Adjust the Agent's reply style and behavioral logic
- **Modify tools** — Fix bugs in tool functions or tweak parameters
- **Refine code** — Improve the Agent's main program logic

::: warning
Editing code online requires some technical experience. If you are unsure how to make a change, use the "Update Agent" feature instead and describe your requirements in natural language.
:::

### Inline Chat Testing

An embedded chat area at the bottom of the detail page lets you interact with the Agent without leaving the page:

1. Type a message in the input box at the bottom.
2. Watch the Agent respond in real time.
3. Multi-turn conversations and file uploads are supported.
4. Conversation history is saved in the session.

### Tool List

This section lists every tool attached to the Agent:

| Info | Description |
|------|-------------|
| **Tool name** | Name of the tool function |
| **Description** | What the tool does |
| **Parameters** | Name, type, and description of each input parameter |
| **Tool type** | Built-in / generated / MCP / etc. |

The tool list tells you exactly what capabilities the Agent has.

### Invocation Records

View the Agent's historical invocation audit log:

| Field | Description |
|-------|-------------|
| **Invoked at** | Timestamp of each invocation |
| **Input** | The user's message |
| **Output** | The Agent's response |
| **Duration** | Response time for this invocation |
| **Status** | Success / failure |
| **Token usage** | Tokens consumed by this invocation |

### Recent Sessions

Shows a list of the Agent's recent conversations so you can revisit past interactions quickly.

## Agent Operations

### Incremental Update

If you want to change an existing Agent instead of rebuilding from scratch, use the **"Update Agent"** feature:

1. Click the **"Update Agent"** button on the detail page.
2. Describe the change you want in natural language, for example:
   - "Add a PDF export feature"
   - "Change the reply style to be more formal"
   - "Add support for the JSON file format"
3. The system launches the **Agent Update Workflow** and modifies only the parts that need to change.
4. Once the update finishes, the Agent automatically uses the new version.

This is more efficient than building a brand-new Agent because only the changed portion is regenerated.

### Deployment Management

| Action | Description |
|--------|-------------|
| **Deploy to AgentCore** | Publish a local Agent to AWS Bedrock AgentCore for cloud hosting |
| **Start Agent** | Restart an offline Agent |
| **Stop Agent** | Pause a running Agent |

**Benefits of deploying to AgentCore:**
- High availability: AWS cloud hosting with automatic failure recovery
- Auto-scaling: Resources scale up and down based on invocation volume
- Professional operations: AWS handles ops and maintenance

### Delete an Agent

You can delete an Agent from its detail page. A confirmation dialog appears before deletion, where you can choose:

| Option | Description |
|--------|-------------|
| **Delete local files** | Also remove the Agent's local code files and related resources |
| **Delete cloud resources** | If the Agent is deployed to the cloud, also remove its AgentCore resources |

::: warning Deletion is irreversible
Deletion cannot be undone. After deletion, the Agent's code, prompts, tools, and all history are permanently removed. Confirm carefully before proceeding. If you only need to pause the Agent temporarily, use "Stop" instead of "Delete".
:::

## Interaction Network

Click the **"Interaction network"** button in the upper right of the page to see the **network graph of Agent-to-Agent calls**.

This visualization shows:
- Which Agents call each other
- The direction and frequency of the calls
- The collaboration patterns between Agents

It is especially useful for understanding multi-Agent collaboration scenarios.

## Management Tips

1. **Use category tags** — Filter by tag to quickly find Agents in a specific domain.
2. **Watch for errored Agents** — Periodically check whether any Agent is in an error state.
3. **Monitor invocation data** — Use the metrics on the detail page to understand how each Agent is being used.
4. **Update, don't rebuild** — When an Agent needs changes, run an incremental update instead of rebuilding it.
5. **Deploy thoughtfully** — Use local deployment during testing; switch to cloud deployment once the Agent is stable.
