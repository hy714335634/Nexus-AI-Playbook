---
title: MCP Clients
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - config/mcp/**
    - nexus_utils/mcp/mcp_client/**
  generated_at: 2026-05-08T22:32:37+00:00
  generated_by: docs-sync v2
---

# MCP Clients

## Overview

Besides exposing Nexus-AI agents to Kiro / Claude Code / Cursor (see [MCP Server](./mcp-server)), the platform works the other way around too — any agent can call out to an **external MCP server** and pull its tools into the conversation. While building an agent, add an MCP server to the agent's tool dependencies, and every tool that server advertises is auto-loaded into that agent's runtime.

Nexus-AI supports all **three MCP transports** (stdio / SSE / Streamable HTTP) and two configuration entry points:
- **Config files** under `config/mcp/*.json` — best for operators baking system-level MCPs into a deployment;
- **Platform console / REST API** under `/mcp/servers` — best for adding or removing servers at runtime, which the "Tools" page in the UI wraps into forms.

Both entry points are merged into DynamoDB at first boot, and every agent build reads the latest version from DynamoDB.

## Prerequisites

Before you start:

- The platform is already deployed per the Integrations overview, and `./nexus-cli service status` reports three `running` components.
- The host (or sandbox node) running Nexus-AI can actually launch your target MCP server:
  - **stdio transport** — the host must have `uvx` / `npx` / `python` available (most AWS Labs and community MCPs ship as `uvx` packages).
  - **SSE / HTTP transport** — the service process can reach the MCP URL outbound (corporate networks must allowlist the domain).
- If the MCP requires credentials (AWS profile, GitHub token, API key), you already have the corresponding env vars or HTTP headers ready.

::: tip stdio vs HTTP — which to pick
Local, same-host tools (filesystem, code execution, AWS CLI wrappers) — prefer **stdio**. Long-running, multi-tenant services or third-party SaaS — prefer **HTTP**. SSE is mainly for compatibility with older clients; new deployments should go straight to Streamable HTTP.
:::

## Configuration

### Option A — Config files (system-level)

The config directory is `config/mcp/`. All of the following are auto-loaded at startup:

| File | Purpose |
|------|---------|
| `system_mcp_server.json` | Platform-maintained MCPs (e.g. AWS Labs official tools). Keep operator-owned entries here. |
| `public_mcp_server.json` | Third-party MCPs open to every user; edit as needed. |
| `*.json` (any other JSON file) | Operators can split by business domain; every file in the directory is merged. |

All files share the same Kiro / Cursor-compatible schema:

```json
{
  "mcpServers": {
    "awslabs.core-mcp-server": {
      "transport": "stdio",
      "disabled": false,
      "command": "uvx",
      "args": ["awslabs.core-mcp-server@latest"],
      "env": {
        "FASTMCP_LOG_LEVEL": "ERROR"
      }
    },
    "openskill": {
      "transport": "http",
      "disabled": false,
      "url": "https://mcp.openmcpskills.click/mcp?api_key=sk-mcp-..."
    }
  }
}
```

Each transport requires different fields; mismatches surface as `Invalid configuration` at startup:

| Transport | Required | Optional |
|-----------|----------|----------|
| `stdio`   | `command` | `args`, `env` |
| `sse`     | `url`     | `headers` |
| `http`    | `url`     | `headers` |

Common optional fields for all transports:

| Field | Meaning |
|-------|---------|
| `disabled` | When `true` the server is not registered into any agent — a soft kill switch. |
| `autoApprove` | List of tool names that skip the user confirmation prompt. |
| `description` | Human-readable label shown in the console. |

Restart the service after editing:

```bash
./nexus-cli service restart
```

### Option B — Console / REST API (runtime)

Open the console → **Tools** → **MCP Servers** → **New**. Three quick-add shapes are supported:

1. **Paste JSON** — the same snippet you'd put in a config file; can import multiple servers at once.
2. **Command line** — e.g. `npx -y @modelcontextprotocol/server-filesystem /tmp` or `uvx awslabs.aws-pricing-mcp-server@latest`. The platform splits it into `command` / `args` and derives a default name from the package.
3. **URL** — `https://...` or `sse://...`. A `/sse` path is auto-detected as SSE; anything else becomes Streamable HTTP.

<!-- SCREENSHOT: mcp-client-add-server -->

The REST endpoints backing the UI forms:

| Method | Path | Purpose |
|--------|------|---------|
| `GET` | `/mcp/servers` | List; supports `scope` / `user_id` filters. |
| `GET` | `/mcp/servers/{id_or_name}` | Detail view. |
| `POST` | `/mcp/servers` | Create one server manually. |
| `POST` | `/mcp/servers/import` | Bulk import (auto-detects JSON / command / URL). |
| `PUT` | `/mcp/servers/{id_or_name}` | Update fields. |
| `DELETE` | `/mcp/servers/{id_or_name}` | Delete. |
| `POST` | `/mcp/servers/{id_or_name}/enable` | Enable. |
| `POST` | `/mcp/servers/{id_or_name}/disable` | Disable. |
| `POST` | `/mcp/servers/sync` | Sync `config/mcp/*.json` into DynamoDB (inserts only, never overwrites). |

Example — add AWS Pricing MCP via command string:

```bash
curl -X POST https://<nexus-host>/api/v2/mcp/servers/import \
  -H 'Content-Type: application/json' \
  -d '{
    "config_data": "uvx awslabs.aws-pricing-mcp-server@latest",
    "format": "auto",
    "scope": "shared"
  }'
```

### Scope: shared vs private

The `scope` field on create decides who sees the server when building an agent:

| Value | Meaning |
|-------|---------|
| `shared` | Every user sees it — ideal for operator-maintained system MCPs. |
| `private` | Only the creator sees it — ideal for per-user credential-bound MCPs (personal GitHub token, private API key, etc.). |

Servers loaded from config files are always `shared`.

### Auto-approve list

Tools named in `autoApprove` are invoked without the confirmation dialog. Use it only for read-only, side-effect-free tools; anything that writes, calls external APIs, or costs money should stay on manual confirm.

```json
"autoApprove": ["search_docs", "list_resources"]
```

## Verify

A server showing up in the list does not mean it actually works. Walk through these three checks.

### Step 1 — Test the connection

Click **Test connection** in the UI, or hit the endpoint directly:

```bash
curl -X POST https://<nexus-host>/api/v2/mcp/servers/<name-or-id>/test
```

A successful response:

```json
{
  "success": true,
  "data": {
    "success": true,
    "server_name": "awslabs.core-mcp-server",
    "tool_count": 8,
    "tools": [
      { "name": "prompt_understanding", "description": "...", "input_schema": {...} }
    ]
  }
}
```

`tool_count > 0` means the process launched, the handshake succeeded, and the tool catalog came back. The handshake timeout is 30 s; a first-run `uvx` install can be slow because dependencies are being fetched, so a single retry is fine.

### Step 2 — List the tools

Fetch the tool catalog separately, which is handy for filling in `autoApprove`:

```bash
curl https://<nexus-host>/api/v2/mcp/servers/<name-or-id>/tools
```

### Step 3 — Use it in an agent

1. Open the agent editor → **Tools** → **MCP dependencies** and tick the server you just added.
2. Save and rebuild the agent.
3. In **Chat**, send a prompt that should trigger the tool (e.g. ask the `aws-pricing` MCP "how much does t3.medium cost per hour?").

End-to-end success means you can see the tool actually invoked with a correct result.

<!-- SCREENSHOT: mcp-client-agent-invocation -->

## Troubleshooting

| Symptom | Likely cause | Suggested fix |
|---------|-------------|---------------|
| Startup log: `Failed to import MCP client library` | The `mcp` Python package is missing from the runtime. | Activate `.venv` and re-run `pip install -r requirements.txt`. |
| Test connection: `Connection timeout after 30 seconds` | First-run stdio dependency install is slow, or the HTTP URL is unreachable. | Warm up with a manual `uvx <package>` on the host; or `curl` the URL first to confirm reachability. |
| `Invalid configuration for server 'X'` | stdio entry missing `command`, or SSE/HTTP missing `url`. | Fill in the required fields per the transport table above. |
| A newly added MCP is invisible in the UI | Created with `scope=private` while you're not the creator; or the page wasn't refreshed. | Switch to `scope=shared`, or log in as the creator. |
| Agent runtime cannot find an existing MCP | The server is `disabled=true`, or the name is misspelled. | Re-enable it from the list page, or re-check `mcp_dependencies` on the agent. |
| Every tool call suddenly asks for confirmation | `autoApprove` was cleared or tool names are wrong. | Cross-check names with the response of the list-tools endpoint — they must match exactly. |
| Edited `config/mcp/*.json` but the UI still shows the old config | File-level load policy is insert-only: edits to existing servers never overwrite DynamoDB. | Delete the conflicting DDB entry (or edit it in the UI); calling `POST /mcp/servers/sync` also only inserts new ones. |
| HTTP MCP returns `401 / 403` | API key in the `url` has expired, or `headers` lacks auth. | Rotate the key; add the auth header via `PUT /mcp/servers/{id}`. |
| Long-running MCP tool calls appear cut off | The defaults mentioned above — stdio handshake 120 s, connection-test timeout 30 s — only affect the handshake/test phase. | Once attached to an agent, runtime timeouts are controlled by the agent. If the handshake itself hangs, debug on the host first. |
| Running `sync` did not propagate local edits | `sync` only inserts servers missing from DynamoDB; it never overwrites existing rows. | Delete conflicting entries in the UI first, then `sync`; or use `PUT /mcp/servers/{id}` directly. |

::: info Debug order
Always: **launch the MCP manually on the host → `POST /test` returns `tool_count > 0` → the agent can invoke it.** Do not blame agent config until the first two steps are green.
:::
