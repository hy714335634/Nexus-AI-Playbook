---
title: Use MCP with Nexus-AI
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - README.md
    - config/mcp/**
    - nexus_utils/mcp/**
  generated_at: 2026-05-09T02:00:07+00:00
  generated_by: docs-sync v2
---

# Use MCP with Nexus-AI

This tutorial wires Nexus-AI into the Model Context Protocol (MCP) ecosystem in both directions: exposing your platform Agents to IDEs like Kiro / Claude Code / Cursor, and letting those Agents call external MCP servers as tools.

## What you'll get

- An MCP Server running at `http://localhost:9000/mcp` that auto-registers every "running" Agent on your platform as an MCP Tool, callable directly from an IDE.
- A JSON snippet you drop into `config/mcp/` so Agents can call external tools over MCP (AWS MCP servers, third-party HTTP MCP servers, and so on).

## Prerequisites

| Item | Requirement |
|------|-------------|
| Nexus-AI services | `./nexus-cli init` done and `./nexus-cli service start` healthy |
| AWS credentials | `aws configure` set up, Bedrock access enabled |
| At least one running Agent | Any Agent with `status = running` in the Web console (so the MCP Server has something to expose) |
| IDE (optional) | Kiro, Claude Code, or Cursor |
| Python | 3.13+ |

## Estimated time

~15 minutes (excluding Agent build time).

---

## Part A — Expose Agents to your IDE (MCP Server)

### Step 1: Start the MCP Server

From the Nexus-AI root directory:

```bash
./nexus-cli service start --mcp
```

The `--mcp` flag brings up the MCP Server in addition to the three core services (API / Worker / Web).

**Expected output**: the console prints a config block containing the port, URL, and an auto-generated token:

```
============================================================
  Nexus-AI MCP Server
============================================================
  Port:  9000
  URL:   http://localhost:9000/mcp

  Security Token (auto-generated):
  <random string>

  MCP client config:
  {
    "mcpServers": {
      "nexus-ai": {
        "url": "http://localhost:9000/mcp",
        "headers": {
          "Authorization": "Bearer <token>"
        }
      }
    }
  }
============================================================
```

::: tip
If the token scrolled off, run `./nexus-cli service logs --mcp` to find it again, or read `.pids/mcp_token`.
:::

<!-- SCREENSHOT: mcp-server-start-console -->

### Step 2: Pin the token (optional)

By default, a new token is generated on every start. Pin it to a stable value (useful for team-shared IDE configs) via an env var:

```bash
export NEXUS_MCP_TOKEN="my-stable-token-value"
./nexus-cli service start --mcp
```

The port is configurable the same way via `NEXUS_MCP_PORT` (defaults to `9000`).

**Expected output**: the startup banner now says `Using token from NEXUS_MCP_TOKEN env var` instead of generating a random one.

### Step 3: Verify the server is reachable

In a second terminal:

```bash
# Health check (no token required)
curl http://localhost:9000/health

# Tail MCP logs
./nexus-cli service logs --mcp
```

You should see `Nexus-AI MCP Server initialized. N agent tools registered.` where `N` equals the number of Agents with `status=running`.

### Step 4: Configure your IDE

Copy the JSON block from Step 1 into the IDE's MCP config file:

| IDE | Config file |
|-----|------------|
| Kiro | `~/.kiro/settings/mcp.json` |
| Claude Code | `.mcp.json` (project-scoped) |
| Cursor | See Cursor's MCP settings docs |

Example (`~/.kiro/settings/mcp.json`):

```json
{
  "mcpServers": {
    "nexus-ai": {
      "url": "http://localhost:9000/mcp",
      "headers": {
        "Authorization": "Bearer <token from Step 1>"
      }
    }
  }
}
```

Save and reload the IDE (or re-establish the MCP connection).

<!-- SCREENSHOT: mcp-ide-config-kiro -->

### Step 5: Call an Agent from the IDE

Once the IDE connects, each running Agent surfaces as an MCP Tool. The tool name is derived from the Agent name (lowercased, non-alphanumerics replaced with underscores, capped at 64 characters).

Each tool accepts a single `query` string parameter and returns the Agent's text response.

**Expected behavior**: ask the IDE something like "Use `aws_pricing_agent` to fetch the price of an m8g.xlarge in us-east-1", and the IDE forwards it through Nexus-AI MCP Server to the matching Agent.

<!-- SCREENSHOT: mcp-ide-tool-call -->

### Step 6: Refresh after Agent changes

When you add, enable, or disable Agents in the Web console, the IDE's tool list does not auto-sync. Invoke the built-in `refresh_agents` tool from the IDE to rescan:

```
Tool: refresh_agents
Result: Refresh complete. <N> agents available: <tool_name_1>, <tool_name_2>, ...
```

---

## Part B — Let Agents call external MCP tools (MCP Client)

Nexus-AI ships with an MCP Client so Agents can use tools exposed by external MCP servers. Configs live in `config/mcp/`:

| File | Purpose |
|------|---------|
| `system_mcp_server.json` | System-provided servers (e.g. official AWS MCP servers) |
| `public_mcp_server.json` | Your own public servers |

### Step 7: Add a stdio-transport MCP server

Here's the AWS Pricing MCP Server. Edit `config/mcp/system_mcp_server.json` and add an entry under `mcpServers`:

```json
{
  "mcpServers": {
    "awslabs.aws-pricing-mcp-server": {
      "transport": "stdio",
      "disabled": false,
      "command": "uvx",
      "args": [
        "awslabs.aws-pricing-mcp-server@latest"
      ],
      "env": {
        "FASTMCP_LOG_LEVEL": "ERROR",
        "AWS_PROFILE": "default",
        "AWS_REGION": "us-east-1"
      }
    }
  }
}
```

### Step 8: Add an HTTP-transport MCP server

For a remote HTTP MCP server, use `transport: "http"` with a `url`:

```json
{
  "mcpServers": {
    "my-remote-mcp": {
      "transport": "http",
      "disabled": false,
      "url": "https://example.com/mcp?api_key=xxxxx"
    }
  }
}
```

SSE transport works the same way — set `transport` to `"sse"`.

### Step 9: Manage MCP servers via REST API (optional)

Beyond editing JSON files, Nexus-AI exposes an API under `/api/v2/mcp/servers` for use by the Web console or automation scripts:

| Action | Method | Path |
|--------|--------|------|
| List all servers | `GET` | `/api/v2/mcp/servers` |
| Create server | `POST` | `/api/v2/mcp/servers` |
| Import config (JSON / command / URL) | `POST` | `/api/v2/mcp/servers/import` |
| Test connection | `POST` | `/api/v2/mcp/servers/{server_id}/test` |
| List server tools | `GET` | `/api/v2/mcp/servers/{server_id}/tools` |
| Enable / disable | `POST` | `/api/v2/mcp/servers/{server_id}/enable` (or `/disable`) |
| Sync local JSON to DynamoDB | `POST` | `/api/v2/mcp/servers/sync` |

The import endpoint accepts `format: "auto" | "json" | "command" | "url"` — you can paste an `npx -y @modelcontextprotocol/server-filesystem /path` command string or an SSE/HTTP URL directly, and the backend detects the format.

### Step 10: Declare MCP dependencies on your Agent

Agent prompt templates reference MCP servers by name via an `mcp_dependencies` field (the keys from your JSON config). At runtime the platform:

1. Pulls each server's latest config from DynamoDB (picking up any Web-console edits).
2. Creates one `MCPClient` per server.
3. Injects the server's tools into the Agent.

If a dependency is missing or disabled, that client is skipped with a warning — it won't block Agent startup.

---

## Verification

Run through the checklist below to confirm both halves work:

- [ ] `./nexus-cli service status` reports the MCP row as `running`.
- [ ] `curl http://localhost:9000/health` returns 200.
- [ ] Hitting `http://localhost:9000/mcp` without an `Authorization` header returns `401`.
- [ ] Your IDE's MCP panel lists one tool per running Agent.
- [ ] Calling one of those tools from the IDE returns the Agent's text output.
- [ ] A newly added server appears in `GET /api/v2/mcp/servers`.
- [ ] `POST /api/v2/mcp/servers/{id}/test` against it returns `success: true` with a tool list.

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| IDE shows `Missing or invalid Authorization header` | Bearer token missing or wrong | Re-check `.pids/mcp_token` or the startup log |
| IDE shows `Invalid token` | Token mismatch after server restart | Pin the token via `NEXUS_MCP_TOKEN` |
| No Agent tools appear in the IDE | No Agent is in `status=running` | Set an Agent to running in the console, then call `refresh_agents` |
| Agent still can't find a newly added tool | Config not yet synced to DynamoDB | Call `POST /api/v2/mcp/servers/sync` or restart the API |
| `uvx` not found | `uv` toolchain not installed | Install uv: `curl -LsSf https://astral.sh/uv/install.sh \| sh` |

## Next steps

- Want your IDE to drive the Agent-build workflow directly? Read [Build your first Agent](./build-hermes-analyst) (work in progress).
- Want the big picture of Nexus-AI internals? Read the [Architecture Overview](../developer/architecture-overview).
- Want full-blown cloud deployments? See the [Deploy parameters reference](../reference/deploy-params).
