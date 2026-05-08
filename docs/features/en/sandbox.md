---
title: Sandbox Runtime
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - nexus_utils/sandbox/**
  generated_at: 2026-05-08T15:35:52+00:00
  generated_by: docs-sync v2
---

# Sandbox Runtime

## What it is

The sandbox is where every Nexus-AI agent conversation actually runs. By default the platform puts each agent inside its own Firecracker microVM — fully isolated from other users, other agents, and even the platform backend itself. The workspace files you see, the model calls, and the tool executions all happen inside that "one VM per conversation" box. When a conversation ends, the VM does not immediately get torn down: it returns to an idle pool so your next message can reuse it, which keeps the system both safe and fast.

## When to use it

| Scenario | What the sandbox does for you |
| --- | --- |
| Running an agent that reads files, writes files, or executes code | Confines execution to a microVM — workspace and credentials never leak to other users |
| Continuing a conversation in the same session | Routes your next message to the same VM you used before; the workspace is already mounted, no re-prep needed |
| Launching an agent with multiple generated tools bound | Installs the required dependencies on first run; subsequent runs start instantly |
| Letting admins pick the isolation level | Switch between "run in-process (no isolation)" and "Firecracker sandbox", and decide whether users can override |
| Controlling operational cost | Nodes that sit idle long enough are auto-scaled down; traffic spikes trigger auto-scale-up |

## How to use it

### Scenario 1 — You are a regular user sending a message

<!-- SCREENSHOT: sandbox-chat-running -->

You don't have to change anything. Once a message leaves the chat window, the platform:

1. Picks the execution location according to the current runtime policy (Firecracker sandbox by default).
2. Picks a reusable VM from the idle pool, or cold-starts a fresh VM on a node that still has capacity.
3. Mounts your workspace (your directory on the shared data volume) into the VM and starts the agent.
4. Streams agent output back to the front end. You see `Preparing sandbox environment…` and then the answer begins.
5. Releases the VM back to the idle pool when the conversation ends so you — or the next message in the same session — can reuse it.

::: tip Why the first message can be slower
If no VM can be reused, the platform cold-starts a fresh one; if no node has spare capacity, it also launches a new EC2 node, which typically takes 1–5 minutes. After that, every subsequent turn reuses an existing VM and returns in seconds.
:::

### Scenario 2 — Admin switches the runtime mode

<!-- SCREENSHOT: sandbox-runtime-policy -->

Under **System settings → Sandbox runtime** you can choose:

1. **Default runtime** (`default_runtime`)
   - `local` — run in-process on a backend service node, no isolation. For development/debugging.
   - `ec2` — Firecracker microVM isolation (production default, recommended).
   - `agentcore` — AWS Bedrock AgentCore managed runtime (not yet available).
2. **Allowed runtimes** (`allowed_runtimes`) — tick which modes the platform may use.
3. **Allow user override** (`allow_user_override`) — off means every agent uses the default runtime; on means the UI can switch per agent.
4. Save. New conversations follow the new policy; in-flight conversations are unaffected.

::: warning What switching to `local` does
`local` skips all microVM isolation — agents run directly on backend service nodes. Use it only in dev/test environments; keep production on `ec2`. After the switch, the platform shortens the idle wait and releases existing EC2 nodes during the next patrol, so you don't pay for unused capacity.
:::

### Scenario 3 — Admin checks sandbox cluster status

<!-- SCREENSHOT: sandbox-cluster-status -->

A dedicated sandbox controller (independent background service) patrols every 30 seconds and exposes an HTTP API:

1. `GET /health` — is the controller itself alive.
2. `GET /status` — result of the latest patrol: online nodes, running VMs, idle nodes, and whether scale-up or scale-down happened this round.
3. `POST /scale_down` — manually trigger scale-down; accepts `min_nodes` (lower bound to keep) and `dry_run` (preview candidates without actually terminating).

You can also start the controller from the command line:

```bash
nexus-cli service start --sandbox-controller
```

### Scenario 4 — Automatic scaling up and down

The patrol handles the following automatically — you usually don't need to touch anything:

1. **Node heartbeat timed out** → mark the node offline and clean up ghost VM records it left behind.
2. **All nodes full** → launch a new EC2 node, up to `max_size`.
3. **Node idle past the threshold** → stop the sandbox service on it, unmount shared storage, terminate the EC2 instance, and clean up the registry (keeping at least `min_nodes` nodes).
4. **Runtime switched to `local`** → allow all EC2 nodes to be released (`min_nodes` temporarily drops to 0).

### Scenario 5 — Customize VM shape and node pool

<!-- SCREENSHOT: sandbox-pool-config -->

Under **Sandbox node pool** you can tune:

1. **Node instance type** (e.g. `c8i.xlarge`, `m8i.2xlarge`, `r8i.4xlarge`).
2. **vCPU / memory per VM** (defaults: 1 vCPU, 768 MiB).
3. **Pool `min_size` / `max_size` / `desired_size`**.
4. **Max VMs per node** — set to `auto` to let the platform compute it from the instance shape.
5. **Prewarm policy** — whether to prewarm featured agents, and how many idle VMs to keep ready.

## Key parameters / limits

| Parameter | Description | Default |
| --- | --- | --- |
| Default runtime | Default execution location for new conversations | `ec2` |
| Allowed runtimes | Set of runtimes the platform may pick | `local`, `ec2` |
| Allow user override | Can a user/agent pick a non-default runtime | off |
| Invocation timeout | Maximum duration of one agent execution | 600 s |
| vCPU per VM | vCPUs assigned to each microVM | 1 |
| Memory per VM | Memory assigned to each microVM | 768 MiB |
| vCPU quota per VM | vCPU footprint used for capacity math (supports fractions for over-subscription) | 0.5 |
| VM boot timeout | How long a VM is allowed to boot before the attempt is judged a failure | 30 s |
| VM idle reclaim | How long an idle VM may sit before it is torn down | 300 s |
| Idle scale-down threshold | How long a node must stay idle before it's torn down | 10 min |
| Pool minimum | Nodes to keep even when idle | 1 |
| Max concurrent VMs | Platform-wide cap on running microVMs | 50 |
| Heartbeat timeout | How long without a heartbeat before a node is marked offline | 90 s |
| Patrol interval | Time between two patrol runs | 30 s |

| Limit | Detail |
| --- | --- |
| Nested virtualization required | Node EC2 instances must be KVM-capable: 8th-gen Intel (`c8i`, `m8i`, `r8i`, not the `d` variants) or any `.metal` instance |
| Unsupported instances | 6/7-series non-metal, NVMe-backed `c8id`/`m8id`/`r8id`, and all ARM/AMD instances cannot host Firecracker |
| Networking | Each node runs one Linux bridge on `172.16.0.0/24` by default; VMs reach the outside world via NAT; the reverse proxy uses ports `18001–18100` |
| Shared storage | Every node must mount two shared volumes: a read-only code volume (platform code) and a read/write data volume (workspaces, per-agent venvs, events) |
| Workspace sync | Workspaces are incrementally pushed to an S3 session bucket after each run; if no bucket is configured, data stays on the shared data volume only |
| Template mounts | Up to 30 template asset packs can be mounted per session, each under its own `mount_name`, safe across concurrent sessions |
| Credentials | VMs have no IMDS; AWS temporary credentials are delivered by a proxy on the host node and auto-refreshed ~30 minutes before expiry |
| Dependency install | The first time a VM runs a given agent, dependencies from each bound tool's `requirements.txt` are installed lazily; failures are non-fatal and skipped on retry |
| `agentcore` mode | Currently a placeholder — not usable; keep the default or pick `ec2` |
| Cold-start time | Seconds when a node has capacity; typically 1–5 minutes when a new node needs to launch, depending on EC2 boot speed |

## FAQ

**Q1: If I close the browser and come back, can I still continue the same session?**
A: Yes. The sandbox remembers the VM that last served your session and routes the next message there first (session affinity). Its workspace is already mounted and context is still warm, so there's almost no setup overhead. If that VM has been reclaimed, the platform picks a new one — the conversation continues either way.

**Q2: Why did my first message return "Sandbox unavailable"?**
A: Usually every node is full and a new one is still launching. Try again shortly. If it keeps failing, ask an admin to check whether `max_size` is set too low or whether the chosen EC2 instance type supports nested virtualization (see limits above).

**Q3: What happens if agent execution exceeds 600 seconds?**
A: The platform returns `Execution timed out after 600s`, ends the call, and marks the VM as failed so it gets torn down and rebuilt on the next patrol. Split long-running jobs into multiple turns, or ask an admin to raise `invocation_timeout` in the sandbox settings.

**Q4: I deleted an agent — will the dependencies it installed linger on the VM?**
A: Not for long. Each agent has its own isolated venv directory on the shared data volume, keyed by agent ID. When an agent is deleted its venv directory is cleaned up with it; other agents' VMs are unaffected.

**Q5: As an admin, can I force-reclaim all idle nodes right now?**
A: Yes — call the controller's `POST /scale_down` with `min_nodes` set to 0; or switch the default runtime to `local` in the sandbox policy, and the next patrol will release every EC2 node. Add `dry_run: true` first if you want to preview which nodes would be terminated.
