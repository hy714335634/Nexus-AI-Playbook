---
title: Tools
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - api/v2/routers/agent_tools.py
    - nexus_utils/skill/**
  generated_at: 2026-05-08T15:06:54+00:00
  generated_by: docs-sync v2
---

# Tools

The Tools page lists every tool registered on the platform. Open it from **Tools** in the left sidebar — the **Tool List** tab is shown by default.

![Tools](/images/tools.png)

## What Is a Tool

A **tool** extends what an agent can do. If the large language model is the agent's "brain," tools are its "hands and feet" — the way it interacts with the outside world.

Under the hood every tool is a **Python function**. During a conversation the agent decides when to call a tool to get the job done. For example:

- The user uploads a CSV → the agent calls `file_read` to read it
- The user asks about the weather → the agent calls `weather_api` to fetch data
- The user asks for a calculation → the agent calls `calculator` to run the math

**Why tools matter:** an agent without tools can only process text (answer questions, summarize content, and so on). With tools it can read and write files, call APIs, run code, and perform real actions.

## Overview

The top-right corner of the page shows two global counters:
- **Total tools** — every tool available on the platform
- **MCP servers** — the number of configured [MCP servers](/using/mcp)

## Tool Types

Nexus-AI tools come in five flavors.

### Builtin tools

The basic tools shipped with the platform, covering the most common needs:

| Name | Purpose | Notes |
|------|---------|-------|
| **calculator** | Math | Evaluates math expressions and statistics |
| **shell** | Run commands | Executes shell commands for system operations |
| **file_read** | Read files | Reads file contents in various formats |
| **file_write** | Write files | Creates or modifies files |
| **editor** | Edit code | Edits code files in place |
| **http_request** | HTTP | Calls external HTTP/REST APIs |

These are available to every agent out of the box — no extra development needed.

### Template tools

Prebuilt **functional templates** that provide higher-level capabilities:

| Template type | Purpose | Good for |
|---------------|---------|----------|
| **API call template** | Standardized REST API calls | Agents that integrate external APIs |
| **Data processing template** | Cleaning, transformation, aggregation | Data-analysis agents |
| **File operations template** | Multi-format read/write | Agents that juggle different file formats |

### Generated tools

Custom tools that the **Tools Agent** develops automatically while you build an agent. They are tailored to the specific request.

**Example:** if you ask for a "medical-literature research assistant," the Tools Agent may generate:
- `search_pubmed()` — search papers on PubMed
- `parse_pdf()` — parse a paper PDF
- `format_citation()` — format a citation in APA style

Generated tools are a core capability of Nexus-AI — the platform can produce the exact tool functions your workflow needs.

### System tools

Low-level system utilities that expose environment and scheduling primitives:

| Name | Purpose |
|------|---------|
| **environment** | Query system environment info |
| **current_time** | Return the current time |
| **cron** | Manage scheduled tasks |

### MCP tools

Tools provided by external MCP servers via the **Model Context Protocol (MCP)**. They are served by the MCP server itself — no in-platform development required.

**Examples:**
- AWS Pricing MCP server → tools for querying AWS service pricing
- AWS Core MCP server → tools for managing AWS resources

See [MCP servers](/using/mcp) for detailed management.

## Browsing Tools

### Search

Type a keyword into the search box at the top of the page to filter by **tool name** or **description**.

### Filters

Two drop-down filters can be combined:

| Filter | Options | Purpose |
|--------|---------|---------|
| **By type** | All / Builtin / Generated / System / Template / MCP | Filter by tool source |
| **By category** | All / Agents & Workflows / File Operations / Shell & System / Utilities / … | Filter by functional area |

### Tool list

The left panel lists every tool. Each row shows:
- **Name** — the Python function name (for example `search_pubmed`)
- **Description** — a one-line summary of what the tool does
- **Category tag** — which functional category it belongs to

Click a tool on the left to open its full details on the right.

## Tool Details

Selecting a tool reveals the following on the right side of the page:

| Field | Description |
|-------|-------------|
| **Name** | The tool function name |
| **Type** | builtin / generated / system / template / mcp |
| **Description** | A full description of what the tool does |
| **Parameters** | Each parameter's name, data type, required flag, and description |
| **Return value** | The shape and meaning of the tool's return value |
| **Source** | The Python source (with syntax highlighting) |
| **Category** | The functional category |
| **Referenced by** | The agents currently using this tool |

### Parameters

The parameter definition tells you how to call a tool:

```python
# Example: parameters for the search_pubmed tool
Parameters:
  - query (string, required): search keywords
  - max_results (integer, optional): maximum results to return, default 10
  - sort_by (string, optional): sort order, "relevance" or "date"

Returns:
  - list: list of papers, each with title, authors, abstract, pmid, etc.
```

### Viewing source

For **builtin** and **generated** tools you can open the full Python source to see exactly how the tool is implemented.

## Testing a Tool

The details page exposes an **inline test** feature so you can verify a tool works before assigning it to an agent.

### Test steps

1. On the details page, review the tool's parameter definition
2. Fill in the **parameter form**
3. Click **Run**
4. Inspect the returned result

### Example run

```
Tool:   calculator
Input:  expression = "2 + 3 * 4"
Output: 14

Tool:   current_time
Input:  timezone = "Asia/Shanghai"
Output: "2025-01-15T10:30:45+08:00"
```

::: tip Why test
- **Verify behavior** — confirm the tool works as expected
- **Understand I/O** — learn the input and output shape
- **Isolate issues** — if an agent misbehaves, testing the underlying tool helps pinpoint the cause
:::

## Building a New Tool

If you need a tool independently of building any specific agent, use **Build Tool**.

### Steps

1. Click **+ Build Tool** in the top right of the page
2. In the dialog, describe the tool's behavior in natural language
3. The platform generates the Python implementation and documentation
4. The new tool shows up in the list and becomes available to every agent

### Prompt examples

> "Create a tool that calls a weather API to fetch real-time weather for a given city and returns temperature, humidity, wind speed, and a description."

> "Create a tool that reads a JSON file and filters and aggregates rows by a specified key."

> "Create a tool that converts Markdown text into a PDF file."

::: info
Tools built this way live in the shared tool library and can be referenced by any agent. When you later create a new agent, the platform also checks this library for reusable tools.
:::

## How Tools Relate to Agents

Understanding the tool/agent relationship helps you use the platform effectively:

```
Agent = Brain (LLM + prompt) + Hands and Feet (tools)

User message → Agent understands intent → picks a tool → runs it → returns the result

Example:
User:  "Please analyze this CSV file."
Agent: [Understand] the user wants data analysis
       [Pick]       call file_read to load the file
       [Pick]       call calculator for statistics
       [Compose]    assemble the analysis into a report
       [Reply]      present the report to the user
```

A single agent can use many tools, and the same tool can be shared by many agents.

## Related

- [MCP servers →](/using/mcp) — manage external tools and services integrated via MCP
- [Agent management →](/using/manage-agents) — see which tools each agent uses
- [How it works →](/overview/how-it-works) — learn how the Tools Agent develops tools automatically
