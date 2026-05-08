---
title: Bridge Multi-Connection
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - nexus_utils/bridge/**
  generated_at: 2026-05-08T16:01:28+00:00
  generated_by: docs-sync v2
---

# Bridge Multi-Connection

## What this is

**Nexus Bridge** is a secure channel that connects the AI assistant to your own servers. Paste a single `curl` command on a server and the Agent can run shell commands, inspect state, and submit long-running tasks on it. A single session can hold **up to 5 concurrent server connections**, and one command can execute across **all of them in parallel**.

Nexus never stores your server's SSH keys, and you don't need to open any inbound port: the connection is **initiated outward by your server**, and you can close it at any time with `Ctrl+C`.

## When to use it

| Scenario | How |
| --- | --- |
| **Single-server ops** | Let the Agent check `df -h`, tail logs, or restart services for you. |
| **Fleet inspection** | Attach multiple servers, then use `server="all"` to collect status from every host at once. |
| **Long-running jobs** | Offload system upgrades, large builds, or data migrations as async tasks; the Agent only checks back when they finish. |
| **Controlled access** | Share a read-only session with a teammate and use command rules to block `rm`, `reboot`, and similar dangerous commands. |

## How to use it

### 1. Open the Bridge panel in a session

Click the Bridge icon in the top-right of any session to open the connection panel.

<!-- SCREENSHOT: bridge-panel-empty -->

### 2. Generate a connection command

In the panel you can configure:

- **Alias** (optional): distinguishes servers in multi-connection setups; if empty, the hostname is used.
- **Mode**: `HTTP` (default, firewall-friendly) or `WebSocket` (lower latency).
- **Auto-reconnect**: when enabled, dropped connections recover automatically for up to 24 hours.

Click **Generate** and you'll get a one-line `curl` command similar to:

```bash
curl -sSL 'https://your-nexus/bridge/script?mode=http' | \
  NEXUS_TOKEN="..." NEXUS_HOST="your-nexus" NEXUS_PORT="443" \
  NEXUS_SSL="true" python3 -
```

<!-- SCREENSHOT: bridge-curl-command -->

### 3. Paste the command on the target server

Log in to the server you want to attach and run the command. As long as the server can reach the Nexus URL and has Python 3, you'll see the welcome banner:

```
╔════════════════════════════════════════════════╗
║   B R I D G E  ·  Remote bridge established    ║
╚════════════════════════════════════════════════╝

✓ Connected  Nexus Bridge channel activated
┌──────────────────────────────┐
│  Hostname     web-01         │
│  OS           Linux          │
│  User         ubuntu         │
└──────────────────────────────┘

⚡ The Agent can now operate this server remotely
```

<!-- SCREENSHOT: bridge-client-banner -->

### 4. Ask the Agent to use the server

Once connected, a green check appears in the panel. Just chat normally:

- "Check the disk usage on web-01."
- "Run `uptime` on all servers and compare."
- "Upgrade the system packages on this host and let me know when it's done."

The Agent picks the right tool automatically:

| Tool | When to use | Typical action |
| --- | --- | --- |
| `remote_shell` | Normal commands (< 2 min) | Status, config tweaks, quick diagnosis |
| `remote_shell(server="all")` | Multi-host fan-out | Fleet inspection, batch deploy |
| `remote_task` | Long-running jobs (> 2 min) | Upgrades, builds, migrations |
| `remote_task_status` | Check progress/result | Agent polls on its own |

### 5. Add more connections or disconnect

- **Add another server**: click **New connection** and repeat. Each connection has its own alias and can carry its own command rules.
- **Disconnect one**: click the disconnect icon next to a server in the list.
- **Disconnect all**: click **Disconnect all**.

<!-- SCREENSHOT: bridge-multi-connection-list -->

### 6. (Optional) Set command rules

To restrict what the Agent can run, pick a mode under **Command Rules** in the Bridge panel:

| Mode | Behavior |
| --- | --- |
| `none` | No restrictions; everything is allowed. |
| `readonly` preset | Only read-only commands (`ls`, `cat`, `ps`, `docker ps`, …). |
| `no_destructive` preset | Blocks `rm -rf`, `shutdown`, fork bombs, `dd`, etc. |
| Custom whitelist | Only commands matching your regex patterns. |
| Custom blacklist | Reject commands matching your regex patterns. |

Blocked commands never reach the server — the Agent sees a `BLOCKED` message along with the rule that was hit.

## Parameters & limits

| Item | Default | Notes |
| --- | --- | --- |
| Max connections per session | 5 | Hitting the cap makes the generate endpoint return `409`. |
| Command execution timeout | 120 seconds | Upper bound for a single `remote_shell`; the Agent can raise it per call. |
| Connection idle timeout | 300 seconds | A missing heartbeat marks the connection as `connection_lost`. |
| Initial token lifetime | 10 minutes | After this the `curl` command must be regenerated. |
| Reconnect token lifetime | 24 hours | Issued only when auto-reconnect is enabled. |
| Client reconnect attempts | 10 | After this the client script exits. |
| Stdout truncation | Last 50 KB | Long logs keep only the tail. |
| Stderr truncation | Last 10 KB | Same. |
| Async task retention | 1 hour after completion | Results are garbage-collected after that. |
| Client dependency | Python 3 stdlib only | No `pip install` required. |
| Command working directory | Remote user's `$HOME` | All commands run there by default. |

## FAQ

### Q1: Does Bridge upload my server credentials to the cloud?

No. The connection is **initiated by your server**; Nexus only keeps a short-lived token for the handshake and **never** stores SSH keys, root passwords, or any credentials. The `NEXUS_TOKEN` in the `curl` command is one-shot — once used it is marked as consumed.

### Q2: My server is behind NAT with no public IP. Can I still use it?

Yes. Bridge only needs your server to **reach outbound** to the Nexus URL (HTTPS/443 by default). Nexus does **not** need to reach back to your server, which fits most corporate networks. If outbound is fully locked down, ask ops to allowlist the Nexus domain.

### Q3: What happens if I close the terminal running `curl`?

- **Auto-reconnect off**: the connection drops immediately; subsequent `remote_shell` calls return "No active Bridge connection".
- **Auto-reconnect on**: the client retries (up to 10 times, 5 seconds apart) and can resume within 24 hours using the reconnect token. Reconnection is allowed **unless** you explicitly clicked **Disconnect** in the panel.

### Q4: Can I run the Bridge client on Windows?

The client uses only Python 3 stdlib, so it technically runs on any OS with Python 3. However, remote commands execute via `shell=True` with the working directory fixed to `$HOME`, which maps best to Linux / macOS shells. On Windows, use WSL, Git Bash, or an equivalent POSIX shell environment and keep command syntax in mind.

### Q5: If the connection drops during a long task, is the result lost?

Not immediately. `remote_task` runs in a background thread on the remote side; the Agent can query `remote_task_status(task_id)` at any time. Results are retained for **1 hour** on the server after completion, so either let the Agent collect them promptly or have it write the output to a file on the server.

### Q6: Can I audit the script that `curl` pipes into Python?

Yes. Open the `curl` URL in a browser and you'll see the full Python source. The script **uses the standard library only** and **only talks to the Nexus host you configured**. If your policy forbids piped execution, download the script, review it, and run it manually.
