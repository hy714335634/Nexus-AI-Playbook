---
title: MCP Service Management
sync:
  source_commit: 7f4029536abf5945f2384f544555a3f6815c2519
  source_files:
    - config/mcp/**
    - nexus_utils/mcp/**
    - web/app/(main)/ability/mcp/**
  generated_at: 2026-07-12T12:47:38+00:00
  generated_by: docs-sync v2
---

# MCP Service Management

The MCP (Model Context Protocol) service management page lets you register external MCP servers in one place, bring their tools into the platform, and make them available for agents to call at runtime. You can add, import, enable/disable, test connections, view tools, and control who can see and use each server by scope (shared / private).

MCP works in two directions on the platform:

- **As a client consuming external MCP services**: register third-party MCP servers (such as the official AWS MCP servers) so agents can use their tools. This is the main function of this page.
- **As a server exposing platform agents**: the platform also runs a built-in outbound MCP server that exposes your "running" agents as MCP tools to external MCP clients (such as MCP-capable desktop apps / IDEs). See "Exposing Platform Agents as an MCP Service" at the end.

## Opening MCP Service Management

Sidebar「Capability Center」→ click「Enter management」on the「MCP Services」card, or go directly to `/ability/mcp`. The top navigation also switches to「Tools」and「Skills」, which belong to the same Capability Center.

![ability-mcp](/images/ability-mcp.png)

## Interface Overview

The page is titled「MCP Server Management」and has two entries in the top-right:

- **Add Server** — add an MCP server by filling in fields manually or pasting a config
- **Import Config** — paste a config to import in bulk

The main area is the server list, which offers:

- **Search box** — search by server name, command, or URL
- **Scope dropdown** — All scopes / Shared / Private
- **Transport group tabs** — grouped by STDIO / SSE / HTTP, each with a count badge
- **Stats** — total, enabled, and disabled server counts

Each server is shown as a card, with action buttons: **Test Connection**, **View Tools**, **Edit**, **Enable / Disable**, **Delete**.

### Built-in Servers

The platform ships with a set of ready-to-enable MCP servers, synced in on first startup (add-only, never overwriting your changes). Common ones include:

| Server | Purpose | Default state |
|--------|---------|---------------|
| `awslabs.core-mcp-server` | AWS core capabilities | Enabled |
| `awslabs.aws-pricing-mcp-server` | AWS pricing lookup | Enabled |
| `awslabs.aws-api-mcp-server` | AWS API calls | Enabled |
| `strands-agents` | Strands Agents tools | Enabled |

> The list may also include sample servers used for demonstration (e.g. `test-server`, `disabled-server`), which are disabled by default.

## Transport Types

When adding a server you pick a transport type; each type requires different fields:

| Transport | Description | Required fields |
|-----------|-------------|-----------------|
| **STDIO** | An MCP server run as a local subprocess (e.g. a package launched via `uvx` / `npx`) | Command (`command`); optional args and env vars |
| **SSE** | A remote server connected over Server-Sent Events | URL; optional headers |
| **HTTP** | A remote server connected over Streamable HTTP | URL; optional headers |

::: info
A URL containing `/sse` or starting with `sse://` is treated as SSE; otherwise it is handled as HTTP. STDIO servers require the given command to be executable on the server — if the command is missing, that server is skipped (agents keep working with their other tools).
:::

## Scope and Visibility

Each server has a scope:

- **Shared** — visible and usable platform-wide; modifying / deleting still requires owner or editor permission.
- **Private** — visible only to the creator and anyone it is explicitly shared with.

::: info
Admins can see and manage all MCP servers; non-admins only see shared servers, ones they created, and those shared with them or visible via their resource group. Actions are gated by tool-level permissions (view / create / update / delete).
:::

## Adding a Server (Manual)

1. Click「Add Server」in the top-right to open the「Add MCP Server」dialog.
2. Keep the top tab on「Manual」.
3. Fill in the fields per the table below:

| Field | Description | Required |
|-------|-------------|----------|
| **Server Name** | A globally unique name, e.g. `aws-docs` | Required |
| **Transport Type** | Pick one of STDIO / SSE / HTTP | Required |
| **Command** | STDIO only, e.g. `uvx`, `npx`, `python` | Required for STDIO |
| **Args** | STDIO only; separate multiple args with spaces | Optional |
| **URL** | The server address for SSE / HTTP | Required for SSE/HTTP |
| **Headers** | SSE / HTTP only; add Key/Value pairs dynamically (e.g. auth headers) | Optional |
| **Environment Variables** | Add KEY/value pairs dynamically via「+ Add environment variable」 | Optional |
| **Description** | What the server does | Optional |
| **Scope** | Shared / Private | Required, defaults to Shared |

4. Once all required fields are filled, the「Add Server」button at the bottom becomes clickable. Click it to save.

## Pasting / Importing a Config

Rather than filling fields one by one, use the「Paste Config」tab or「Import Config」in the top-right to paste a config directly. The platform auto-detects the format:

| Format | Example |
|--------|---------|
| **JSON (Cursor/Kiro style)** | `{ "mcpServers": { "my-server": { "command": "uvx", "args": ["my-package@latest"] } } }` |
| **Command line** | `uvx awslabs.aws-documentation-mcp-server@latest` |
| **URL** | `http://localhost:3000/sse` |

The dialog offers three example chips (Cursor JSON / npx·uvx command / SSE·HTTP URL); clicking one fills in the example. You can also choose a scope when importing. An `autoApprove` list in the JSON is imported as the list of auto-approved tools.


## Managing Existing Servers

On each server card:

- **Test Connection** — attempts to connect and fetch the tool list, returning the number of tools found or an error. A connection timeout is reported explicitly (about 30 seconds by default). Use it to confirm reachability before enabling.
- **View Tools** — lists the tools the server provides; expand each tool to see its name, description, and parameters (input schema).
- **Edit** — change transport type, command / URL, env vars, headers, description, scope, etc. (the name cannot be changed).
- **Enable / Disable** — a disabled server is not used by agents but its config is kept; you can re-enable it anytime.
- **Delete** — removes the server config and cleans up all of its share records. Deletion cannot be undone.

A server can also be **shared** or **moved to a folder** for organization via the「More」menu on its card.

::: warning
Deletion is irreversible and also clears the server's shares. Before deleting, make sure no agent still depends on it — you can "Disable" it first, watch for a while, and delete only after confirming no impact.
:::

## Exposing Platform Agents as an MCP Service

Besides consuming external tools, the platform runs a built-in outbound MCP server that exposes your "running" agents as MCP tools to external MCP clients. Each agent maps to one tool that takes a `query` parameter and returns the agent's text response.

| Item | Description |
|------|-------------|
| **Port** | Defaults to `9000`; change it with the `NEXUS_MCP_PORT` environment variable |
| **Address** | `http://localhost:&lt;port&gt;/mcp` |
| **Security Token** | Set via the `NEXUS_MCP_TOKEN` environment variable; if unset, one is auto-generated and printed to the console on startup |
| **Health check** | The `/health` and `/healthz` endpoints require no auth |

External clients must send the `Authorization: Bearer &lt;token&gt;` header. Example config:

```json
{
  "mcpServers": {
    "nexus-ai": {
      "url": "http://localhost:9000/mcp",
      "headers": {
        "Authorization": "Bearer <your token>"
      }
    }
  }
}
```

When agents are added or removed on the platform, external clients can call the built-in `refresh_agents` tool to refresh the list of available agents without reconnecting.

::: info
Only agents in the "running" state are exposed as tools. If an agent does not appear in an external client, confirm it is live and running, then call `refresh_agents`.
:::

## Notes

- Before enabling a new MCP server, use "Test Connection" to confirm it is reachable and can list tools, so you don't discover it's unavailable only at agent runtime.
- STDIO types depend on the corresponding command being installed on the server (e.g. `uvx`); a missing command causes the server to be silently skipped. For remote servers, prefer SSE / HTTP.
- Shared-scope servers are visible and usable platform-wide; keep sensitive or experimental servers private.
- Deletion also clears share records and is irreversible — disable first if unsure.
- The outbound MCP server's token is an access credential; keep it safe. In production, set `NEXUS_MCP_TOKEN` explicitly rather than relying on auto-generation.
