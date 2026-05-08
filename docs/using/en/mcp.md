---
title: MCP Server
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - config/mcp/**
    - nexus_utils/mcp/**
  generated_at: 2026-05-08T15:09:27+00:00
  generated_by: docs-sync v2
---

# MCP Server

The MCP server management page lives under the **Capability Tools** section, on the **MCP Server Management** tab. Here you manage the external tools and services integrated through the MCP protocol.

![MCP Server Management](/images/mcp.png)

## What is MCP

**MCP (Model Context Protocol)** is a standardized open protocol that connects AI agents with external tools and services. It defines a standard way for agents to discover, invoke, and use external tools.

### Why MCP

Traditionally, letting an agent use an external tool required writing one-off integration code per service — a large, non-reusable effort. MCP solves this with a standardized protocol:

```
Traditional:
  Agent → Custom code → AWS API
  Agent → Custom code → Database
  Agent → Custom code → Search engine
  (every integration needs its own code)

With MCP:
  Agent → MCP protocol → MCP Server A (AWS tools)
                       → MCP Server B (Database tools)
                       → MCP Server C (Search tools)
  (integrate once, reuse everywhere)
```

### How MCP works

```
┌──────────┐     MCP protocol  ┌──────────────────┐
│          │  ◄──────────────► │   MCP Server     │
│  Agent   │   Tool discovery  │                  │
│          │   Tool invocation │  ┌─────────────┐ │
│          │   Results         │  │ Tool A      │ │
│          │                   │  │ Tool B      │ │
│          │                   │  │ Tool C      │ │
└──────────┘                   │  └─────────────┘ │
                               └──────────────────┘
```

1. **Tool discovery** — the agent queries the MCP server for its list of available tools.
2. **Tool invocation** — when a tool is needed, the agent sends an invocation request over the MCP protocol.
3. **Results** — the MCP server executes the tool and returns the result.

### Benefits of MCP

| Benefit | Description |
|------|------|
| **Standardized** | A single open protocol — tools from any source are integrated the same way. |
| **Plug-and-play** | Adding one MCP server immediately gives you every tool it exposes. |
| **Dynamic scaling** | Add or remove MCP servers at any time; an agent's capabilities grow or shrink accordingly. |
| **Rich ecosystem** | More and more services ship MCP interfaces, so the tool catalog keeps growing. |

## Overview panel

The top of the page shows 4 summary cards that give you a quick read on MCP server status:

| Metric | Description |
|------|------|
| **Total servers** | Total number of configured MCP servers. |
| **Enabled** | Number of servers currently enabled (usable by agents). |
| **Disabled** | Number of servers currently disabled (paused). |
| **Total tools** | Total number of tools exposed across all MCP servers. |

## Browsing servers

### Search and filter

- **Search box** — search by server name.
- **Category filter** — filter by category (for example, AWS Services, Other).

### Server list

Servers are **grouped by category** (for example, **AWS Services**, **Other**). Each row shows:

| Field | Description | Example |
|------|------|------|
| **Name** | Server name | awslabs.core-mcp-server |
| **Status** | Enabled (green) / Disabled (gray) | Enabled |
| **Transport** | Communication protocol type | STDIO / SSE |
| **Launch command** | Command used to start the server | uvx awslabs.core-mcp-server@latest |

### Transport types

MCP supports two transports:

| Transport | Full name | Description | When to use |
|----------|------|------|----------|
| **STDIO** | Standard Input/Output | Communicates over standard input/output | Locally running MCP servers — the most common case |
| **SSE** | Server-Sent Events | Communicates over a long-lived HTTP connection | Remotely deployed MCP servers |

Most MCP servers use **STDIO**.

### Viewing a server's tools

Click the **expand arrow `>`** on the left of a server row to view all tools it exposes:

- Tool names and descriptions
- Parameter definitions
- These tools also appear under the MCP tools category in the [Tool Library](/using/tools).

### Server actions

Each server row offers the following actions on the right:

| Button | Action | Description |
|------|------|------|
| **▶ Start** | Start or restart | Start the server to make its tools available. |
| **🔗 Connect** | View connection | Inspect the server's connection configuration and status. |
| **⚙ Configure** | Edit configuration | Modify the server's configuration parameters. |
| **🗑 Delete** | Delete server | Remove the MCP server from the platform. |

## Adding an MCP server

Click **「+ Add Server」** in the top-right corner to configure a new MCP server.

### Configuration steps

#### Step 1: Basic information

| Field | Description | Required |
|------|------|----------|
| **Server name** | A recognizable name | Required |
| **Transport** | Choose STDIO or SSE | Required |

#### Step 2: Connection details

**For STDIO:**

| Field | Description | Example |
|------|------|------|
| **Launch command** | Command used to start the server | `uvx awslabs.aws-pricing-mcp-server@latest` |
| **Working directory** | Working directory for the command (optional) | `/opt/mcp-servers` |

**For SSE:**

| Field | Description | Example |
|------|------|------|
| **Server URL** | HTTP endpoint of the MCP server | `http://mcp-server.example.com:8080` |
| **Auth info** | Access credentials (if required) | API key or token |

#### Step 3: Environment variables (optional)

Some MCP servers need environment variables (API keys, region, etc.):

| Variable | Example value | Description |
|----------|--------|------|
| `AWS_REGION` | `us-east-1` | AWS region |
| `API_KEY` | `your-api-key` | Service API key |

#### Step 4: Save

Verify the configuration and click **「Save」**. The platform tries to connect to the MCP server and fetches its tool list automatically.

### Configuration examples

**Example 1: AWS pricing server**

```
Name:      awslabs.aws-pricing-mcp-server
Transport: STDIO
Command:   uvx awslabs.aws-pricing-mcp-server@latest
```

Tools provided: AWS per-service price lookup, cost estimation, and similar.

**Example 2: AWS core server**

```
Name:      awslabs.core-mcp-server
Transport: STDIO
Command:   uvx awslabs.core-mcp-server@latest
```

Tools provided: AWS resource management, configuration lookup, and similar.

## Managing servers

### Enable / Disable

- **Enabled servers** — their tools are callable by agents.
- **Disabled servers** — their tools no longer appear in an agent's available tool list.
- Toggle state at any time without deleting and re-adding.

**When to use it:**
- When you temporarily don't need a service, disable rather than delete.
- Disable temporarily during service maintenance.
- Enable servers one at a time when isolating a problem.

### Viewing a server's tools

After expanding a server, you can view every tool it exposes:

| Field | Description |
|------|------|
| **Tool name** | The function name of the tool. |
| **Description** | What the tool does. |
| **Parameters** | What input the tool needs. |

These tools also appear under the MCP tools category on the [Tool Library](/using/tools) page, where you can inspect details and test them.

## MCP and agent building

When you build an agent, if its requirements involve external services (like AWS), the system automatically checks your configured MCP servers:

1. The **Tools Agent** analyzes requirements and decides which external services are needed.
2. It checks whether any enabled MCP server already exposes a matching tool.
3. If so, it uses the MCP tool directly (no development needed).
4. Otherwise, the Tools Agent develops a custom tool function.

::: tip Configure MCP servers in advance
If you frequently need agents to interact with certain external services (like AWS), configure the corresponding servers in the MCP Server Management page ahead of time. That way they are ready to use when you build agents, which speeds up construction.
:::

## Troubleshooting

| Issue | Cause | Resolution |
|------|------|----------|
| Server can't connect | Network issue or wrong command | Verify the launch command and check network connectivity. |
| Empty tool list | Server didn't start correctly | Restart the server and check startup logs. |
| Tool execution error | Missing environment variable or insufficient permissions | Check the environment variable configuration and the underlying service's permission settings. |
| Add fails | Wrong configuration parameters | Verify the server name, transport type, and command. |

::: info
MCP servers need appropriate network access and service credentials to work. If a server can't connect or tools fail to execute, ask an administrator to review the network and permission configuration.
:::
