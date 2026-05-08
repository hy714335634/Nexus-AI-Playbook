---
title: MCP Server
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - nexus_utils/mcp/mcp_server/**
  generated_at: 2026-05-08T22:35:45+00:00
  generated_by: docs-sync v2
---

# MCP Server

## Overview

Nexus-AI ships with a built-in **MCP Server** that exposes every Agent currently in `running` state as an MCP tool to outside clients — Claude Code, Kiro, Cursor, or any other MCP-aware app. Once the client connects, each Agent shows up as an individual tool that takes a single `query` parameter and returns the Agent's text response. In other words: the platform is both an MCP host and an MCP provider.

The MCP Server does not go through the REST API layer — it calls the internal agent factory directly, so it does not consume an extra HTTP request quota. Transport is **Streamable HTTP**, default port `9000`, path `/mcp`, authenticated with a **Bearer Token**. The token is auto-generated on first start and printed to the console, or you can pin it with the `NEXUS_MCP_TOKEN` environment variable.

::: tip How this differs from external MCP servers
This page covers making Nexus-AI Agents available *to* outside MCP clients. The opposite direction — letting a platform Agent call *other* MCP servers as tools — is covered in [External MCP servers](./mcp-clients). The APIs and config files are different; do not mix them up.
:::

## Prerequisites

Before you start, make sure:

- The platform is deployed as described in the integrations overview and `./nexus-cli service status` returns three `running` services.
- At least one Agent has `status=running` (an Agent turns `running` right after the build succeeds on the Agent management page). The MCP Server registers only `running` Agents; anything else is silently skipped.
- Port `9000` (or the port you pick) on the host is reachable from the MCP client. Open any firewall rules first if the client is on a different machine.
- The Python runtime has `fastmcp` installed (it ships as part of the Nexus-AI dependency set, so there is nothing to install manually).

## Configuration steps

### 1. Pick a token mode

There are two sources for the auth token:

| Mode | When to use | How to enable |
|------|-------------|---------------|
| **Auto-generated** | Development, single-host trial | Do not set any environment variable — the server generates a one-shot token at startup and prints it to the console |
| **Fixed value** | Production, multi-node, CI | Provide a random string (≥ 32 chars) via `NEXUS_MCP_TOKEN` before launch |

::: warning Keep fixed tokens safe
The MCP Server has no built-in token rotation — if it leaks, callers get every Agent's execution rights. Inject it from a secrets manager (AWS Secrets Manager, Vault, etc.); never commit it or leave it in shell history.
:::

### 2. Choose a port (optional)

Default is `9000`. Override with `NEXUS_MCP_PORT`:

```bash
export NEXUS_MCP_PORT=9100
export NEXUS_MCP_TOKEN=$(openssl rand -base64 48)
```

### 3. Start the MCP Server

The MCP Server runs as a standalone module — it is **not** started by `./nexus-cli service start`:

```bash
source .venv/bin/activate
python -m nexus_utils.mcp.mcp_server
```

On a successful boot the console prints a config banner delimited by `=`:

```text
============================================================
  Nexus-AI MCP Server
============================================================
  Port:  9000
  URL:   http://localhost:9000/mcp

  Security Token (auto-generated):
  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

  MCP client config:
  {
    "mcpServers": {
      "nexus-ai": {
        "url": "http://localhost:9000/mcp",
        "headers": {
          "Authorization": "Bearer xxxxxxxx..."
        }
      }
    }
  }
============================================================
```

If the token came from the environment variable, the last two lines collapse into `Using token from NEXUS_MCP_TOKEN env var` instead of echoing the secret.

<!-- SCREENSHOT: mcp-server-startup-banner -->

### 4. Run it as a long-lived service

For production, hand it to `systemd`, `supervisord`, or a container restart policy. A sample `systemd` unit:

```ini
[Unit]
Description=Nexus-AI MCP Server
After=network.target

[Service]
Type=simple
User=nexus
Environment=NEXUS_MCP_PORT=9000
Environment=NEXUS_MCP_TOKEN=__replace_me__
WorkingDirectory=/opt/nexus-ai
ExecStart=/opt/nexus-ai/.venv/bin/python -m nexus_utils.mcp.mcp_server
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

### 5. Configure the client

Paste the JSON block from the startup banner into the MCP client (Claude Code, Cursor, and Kiro all use the same `mcpServers` format). Example for Claude Code's `~/.claude/mcp.json`:

```json
{
  "mcpServers": {
    "nexus-ai": {
      "url": "http://localhost:9000/mcp",
      "headers": {
        "Authorization": "Bearer <your-token>"
      }
    }
  }
}
```

For remote clients, replace `localhost` with the host's IP or DNS name. If you want TLS, terminate HTTPS at a reverse proxy (Nginx, ALB); the MCP Server itself listens plaintext HTTP only.

### 6. Agent exposure rules

At startup the server calls `list_agents(status="running", limit=100)` and registers each Agent as a tool using the rules below:

| Field | Behavior |
|-------|----------|
| Tool name | `agent_name` → lowercase → non-`a-z0-9` chars replaced with `_` → runs of `_` collapsed → leading/trailing `_` stripped → truncated to 64 chars |
| Tool description | Agent's `description` field first; falls back to `Invoke Nexus-AI agent: <name>` if empty |
| Parameter | A single `query: str` carrying the user input |
| Return value | Agent's text response; internal errors are returned as `Error invoking agent: ...` string instead of failing the client session |

Besides the per-Agent tools, there is one built-in management tool:

| Tool | Purpose |
|------|---------|
| `refresh_agents` | Re-enumerates the platform's `running` Agents and registers tools again. When you add or retire Agents on the platform, the client does not need to reconnect — just ask the model to call this tool once |

## Verification

Three steps, in order.

### Step 1: health check

The MCP Server's health probes do **not** require a token, so they are safe as a liveness signal:

```bash
curl -i http://localhost:9000/health
```

A `200` means the process is listening. `/health` and `/healthz` are aliases — pick either for a Kubernetes `readinessProbe`.

### Step 2: call the MCP endpoint with the token

```bash
curl -X POST http://localhost:9000/mcp \
  -H "Authorization: Bearer <your-token>" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}'
```

The `result.tools[]` array in the response should contain `refresh_agents` plus one entry per `running` Agent. If you only see `refresh_agents`, the platform currently has no `running` Agents — that is not a misconfiguration.

### Step 3: invoke an Agent from a real MCP client

1. Reload MCP config in Claude Code / Cursor / Kiro so the client reconnects.
2. Ask something that maps to one of your Agents (e.g. an Agent named `sql-expert` — ask "Write a SQL query that aggregates orders by month").
3. The client will prompt for tool use; confirm, and the Agent's text response comes back.

<!-- SCREENSHOT: mcp-server-claude-code-invocation -->

You have a working end-to-end path only when the Agent actually produces output. If the client shows the tool list but calls hang, the most common cause is a single inference exceeding the default **300-second** timeout (see the table below).

## Troubleshooting

| Symptom | Likely cause | What to do |
|---------|--------------|------------|
| Console has no token printed after start | `NEXUS_MCP_TOKEN` is already set | Expected behavior; the client must use the value from that env var |
| Client returns `401 Missing or invalid Authorization header` | `Authorization` header is missing or lacks the `Bearer ` prefix | Check `headers.Authorization` equals `Bearer <token>` |
| Client returns `403 Invalid token` | Token in the client no longer matches the server's current one — usually after a restart under auto-generated mode | Copy the fresh token from the console, or pin one with `NEXUS_MCP_TOKEN` |
| `tools/list` only shows `refresh_agents` | No Agents are in `status=running`, or registration failed on the platform side | Confirm a running Agent exists in Agent management, then have the client call `refresh_agents` |
| A newly built Agent does not appear in the client | The server enumerates Agents only on startup and on `refresh_agents` | Have the client invoke `refresh_agents` once — no server restart required |
| Call fails with `Agent X is not available` | The target Agent moved out of `running` state (rebuilding, stopped) | Restart the Agent on the platform or pick another running Agent |
| Call returns `Agent X execution timed out (300s)` | Single inference exceeded the default 300-second timeout | Shorten the prompt or tool chain, or split long tasks across multiple turns |
| Call returns `Failed to instantiate Agent ...` | The Agent's `prompt_path` / `agent_name` is missing, or the prompt template file is gone | Re-save and rebuild that Agent in Agent management |
| `/health` returns 200 but `/mcp` handshake hangs | Reverse proxy strips `Transfer-Encoding: chunked` or SSE streaming | Set `proxy_buffering off;` and `proxy_http_version 1.1;` in Nginx; use an HTTP/2 target group on ALB |
| Concurrent calls execute serially | The internal thread pool is `max_workers=4`; excess calls queue up | Per-instance concurrency is capped at 4 — scale out horizontally behind a load balancer for more |
| Every client loses auth after a restart | Auto-generated mode regenerates the token every start | Pin `NEXUS_MCP_TOKEN` so restarts do not rotate it |

::: info Where to look first
Always work in this order: **`/health` returns 200 → `tools/list` returns the full tool list → a real client call succeeds**. Do not start debugging platform-side Agent config until the first two steps pass.
:::
