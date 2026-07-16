---
title: Connecting a Server to Run Tasks
sync:
  source_commit: manual-authored
  generated_by: playbook v4 (orchestration layer)
---

# Connecting a Server to Run Tasks (Nexus Bridge · Remote Server Mode)

The **Nexus Bridge** panel offers two connection modes: **Remote Server** (this page) and **Browser** (see [Browser Extension](./browser-extension.md)). This page covers the "Remote Server" tab — letting an Agent work on your server.

Some tasks can't be handled by chat alone — you need the AI to **actually operate on your server**: run a check, collect logs, set up an environment, execute a process. That's what **Nexus Bridge** is for. It builds a bridge between you and a target server, letting the Agent in your conversation run commands, read and write files, and produce results on a server you've authorized.

::: warning Only operate servers you're authorized to
Bridge lets the Agent run real commands on the target server. **Only connect servers you own or have written authorization to access**, and use the "Command Rules" below to limit what can run. Connect with a least-privilege account.
:::

## How it works (in one sentence)

You click once on the platform to generate a command, **paste and run it in the target server's terminal**, and the server connects back to the platform on its own. From then on, the Agent in your conversation can work on that server.

The key point: **the server always connects back to the platform** — the platform never reaches out to the server. So even if your server sits **inside a private network, behind a firewall, or behind NAT**, it can connect as long as it has outbound internet. You don't open any inbound ports, and you never enter the server's IP, account, or password on the platform.

## Connecting: three steps

1. **Open the Bridge panel**. Go to the [Chat](./chat.md) page, click the **"Nexus Bridge"** button at the top, and switch to the **"Remote Server"** tab.
   ![chat](/images/chat.png)
2. **Generate the connection command**. (Optional) Pick a connection mode:
   - **HTTPS** (default, recommended) — works through CDNs and corporate proxies, most compatible. Use this when unsure.
   - **WebSocket** — needs the server to reach the platform directly; best for low-latency, long-lived connections.

   Click **"Generate Bridge Command"**, and the platform produces a command like `curl ... | python3 -`.
3. **Paste and run it in the server terminal**. Copy the command into the **target server's terminal**. It downloads a zero-dependency script (Python standard library only) and runs it. When the terminal shows "connected," the platform panel automatically flips to "connected." **Keep this terminal open** (`Ctrl+C` disconnects).

::: tip What you need
The target server needs `python3` and outbound internet — that's it. No SSH, no entering server credentials on the platform. Identity uses a one-time token issued by the platform (valid ~10 minutes by default, single-use).
:::

A session can connect up to **5 servers** — add them one at a time with "Add Server" in the panel.

::: tip Want it to reconnect automatically
Turn on **Auto-Reconnect** under "Advanced" in the panel. After a server restart or network blip, the script reconnects on its own — no need to regenerate the command.
:::

## Putting the Agent to work on the server

Once connected, the platform **automatically** gives the Agent in the current conversation remote-operation abilities and tells it the server's basics (OS, user, directory, etc.). No extra setup — just give instructions in the chat, for example:

- "Check disk usage and recent error logs on the server and summarize them"
- "Set up the environment on the test box per this checklist, then tell me the versions"
- "Run a standard security check on this authorized web app and compile the results into a report"

The Agent executes step by step, running the matching command on the server each time — you can see the whole process and [stop](./chat.md#停止生成) it anytime. For long-running work it switches to a background task and checks back periodically. When done, ask it to compile the results into a report saved to the conversation's [workspace](./chat.md) for download.

## Setting what the Agent can do: Command Rules

This is the crux of safety. Under "Advanced → Command Rules" in the Bridge panel, you can restrict which commands the Agent may run on the server:

| Mode | Effect | When to use |
|------|--------|-------------|
| **Unrestricted** (default) | Allows all commands | Fully trusted, isolated test environments |
| **Allowlist** | Only commands matching your list are allowed | Safest when you want it to do only a few specific things |
| **Blocklist** | Blocks the commands you list, allows the rest | When you want to forbid dangerous operations, allow the rest |

There are also two one-click presets:
- **Read-only commands**: allows only view-type commands like `ls`/`cat`/`grep`/`ps`/`df`/`systemctl status` — use when you want the Agent to "look but not touch."
- **Block dangerous commands**: blocks destructive operations like `rm -rf`, disk formatting, shutdown/reboot, `chmod 777`.

A command blocked by a rule fails to run, and the Agent tells you "this command is restricted by a rule" — go back to the panel to adjust.

::: warning Command Rules are not an OS-level sandbox
Command Rules are a soft guard — they catch most mistakes and obviously dangerous commands, but **do not replace the server's own permission controls**. The real safety floor is this: **run the connection command as a least-privilege system account** — the Agent inherits exactly that account's permissions.
:::

## Worked example: an authorized security check on a server

Chaining the pieces together, here's a real scenario — the kind of task where the Agent must **actually log onto the server and run commands**, Bridge's most typical use.

::: warning Confirm authorization first
The steps below run real commands on the target server. **Only do this on servers you own or are authorized in writing to access**, and lock down the scope with Command Rules in Step 3.

1. **Build a dedicated Agent**. Use [Creating an Agent](./create-agent.md) with a clear request:
   > Create a server security-check assistant: run read-only security checks on my authorized Linux servers (open ports, suspicious processes, permission configs, recent login records), explain the risk level of each item, and compile a structured inspection report. Checks only — make no changes.
2. **Connect the target server**. Follow "Connecting: three steps" above and paste-run the generated command in the server terminal.
3. **Lock the scope (critical)**. In the Bridge panel under "Advanced → Command Rules," pick the **Read-only commands** preset — now the Agent can only look, not change, as a mechanical safeguard.
4. **Drive it in the chat**. Open this Agent and say "start a security check on this server." It runs the check commands step by step, all visible to you.
5. **Get the report**. Ask it to "compile the results into an inspection report," saved to the conversation's [workspace](./chat.md) for download.

**Why use an Agent instead of typing commands yourself**: it knows which items to check, understands what each risk means, and turns scattered command output into a human-readable report — the "expertise + execution + fixed deliverable" combination.
:::

## Pairing with capability orchestration

"Have an Agent run a task on a server and produce a report" is a common compound goal. The security check above is just one instance — the same applies to "log analysis," "deployment verification," and more. For the full orchestration path (which Agent to build, how to connect, how to set constraints, how to produce the report), see [From Goal to Plan: Orchestration Recipes](./orchestration-recipes.md).

## FAQ

**Connection never succeeds?** Confirm the command was run in the **target server's** terminal, the server has outbound internet, and `python3` is available. The token has a short lifetime (~10 min) — regenerate it if too much time passed.

**What happens if I close the terminal?** The connection drops. To keep it long-term, turn on "Auto-Reconnect" before running, and keep the terminal running in the background (e.g. `nohup`, `tmux`, or `screen`).

**The Agent says a command is restricted?** It hit a Command Rule you set. Go to the Bridge panel → "Advanced → Command Rules" to relax the rule, or take an approach that fits the rules.
