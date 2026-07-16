---
title: Service Status Monitoring
sync:
  source_commit: 7f4029536abf5945f2384f544555a3f6815c2519
  source_files:
    - api/v2/routers/admin_services.py
    - web/app/(main)/admin/service-status/**
  generated_at: 2026-07-12T12:39:34+00:00
  generated_by: docs-sync v2
---

# Service Status Monitoring

The Service Status page gives you the platform's overall health at a glance in one place — whether each backend service is online, system resource usage, storage space, infrastructure connections — and lets you restart / stop / start services and view live logs right here. When something breaks, this is usually the first place to look.

::: info
Every action on this page requires the matching permission: viewing status needs read access; restart / stop / start actions need write access.
:::

## Opening Service Status

Sidebar「Management」→「Service Status」, or go directly to `/admin/service-status`.

The top of the page offers a quick link to [Configuration Management](./config-management.md), so you can jump straight to tuning parameters after diagnosing an issue.

![admin-service-status](/images/admin-service-status.png)

## Interface Overview

The page has four tabs:

| Tab | Purpose |
|-----|---------|
| **Overview** | Health score, system resources, service list, storage, infrastructure connections |
| **Live Logs** | Stream logs in real time, filtered by service / level / keyword |
| **Sandbox** | Sandbox runtime and node status (shown when sandbox capability is deployed) |
| **Service Management** | Service actions and ops notification subscriptions |

## Overview: Health at a Glance

The「Overview」tab is open by default and auto-refreshes every 60 seconds; you can also click「Refresh」to update manually.

### Top Metrics

There are four metric cards at the top:

| Metric | Meaning |
|--------|---------|
| **Health Score** | A composite 0–100 score driven mainly by the share of services online. ≥80 is green (healthy), 50–79 amber (attention), <50 red (degraded) |
| **Services Online** | "online / total", e.g. `8/8` |
| **Memory Usage** | System memory usage percentage; turns red above 80% |
| **Disk Usage** | Root partition disk usage percentage; turns red above 80% |

### System Resources

The「System Resources」section shows current memory, disk, and load average as progress bars, which turn yellow above 70% and red above 90%.

### Service List

The platform is made up of the following 8 backend services, one card each:

| Service | Port | Role |
|---------|------|------|
| **API** | 8000 | Backend API service; entry point for the frontend and external calls |
| **Worker** | — | Background task processing (e.g. Agent builds, async jobs) |
| **Frontend (Web)** | 3000 | Frontend UI service |
| **Avatar** | 8004 | Avatar / digital persona service |
| **Event Scheduler** | — | Scheduled and event-driven jobs |
| **Sandbox Controller** | 8002 | Sandbox runtime controller |
| **Bridge** | 8001 | Bridge connection service (browser extension, etc.) |
| **OTEL Collector** | 4318 | Observability data collector |

Each card shows: a status dot (🟢 running / ⚪ stopped / 🔴 error), PID, port, uptime, memory usage, and action buttons.

### Storage and Infrastructure Connections

- **Storage**: shows the size and item count of each data directory (Avatar spaces, workspaces, event data, Agent environments, VM images, etc.).
- **Infrastructure Connections**: shows the connection status (`connected` / `error`) of managed services such as the database, cache, and object storage, so you can quickly tell whether the problem is the platform itself or an underlying dependency.

## Service Actions: Restart / Stop / Start

From either the service cards on「Overview」or the「Service Management」tab, you can act on an individual service:

1. Find the target service card.
2. When a service is running, it shows「Restart」and「Stop」buttons; when stopped, it shows a「Start」button.
3. Click the button; the result appears as a toast. Status auto-refreshes after about 2 seconds.

The「Service Management」tab also offers a **「Restart All」** button to restart every service at once.

::: warning
Restarting `api` (the API service) causes a brief outage — the platform schedules the restart asynchronously, returns "scheduled" immediately, then auto-detects recovery. The UI may be briefly unresponsive during this window; that is expected.
:::

::: warning
**Stopping a service makes the related features immediately unavailable** (e.g. stopping the Worker halts build task consumption). Both stop and restart are recorded as ops alerts. Do this during off-peak hours, and avoid leaving critical services stopped for long unless necessary.
:::

## Live Logs

The「Live Logs」tab lets you watch log streams without logging in to the server.

1. Pick a log source from the top dropdown: `API` / `Worker` / `Avatar` / `Event Scheduler` / `Sandbox Controller` / `Bridge` / `OTEL Collector`, or "All Mixed".
2. Optionally filter by level: `DEBUG` / `INFO` / `WARNING` / `ERROR`, or all levels.
3. Optionally enter a keyword to show only lines containing it.
4. Logs are color-coded by level (ERROR red, WARNING amber) and stream in live.
5. Use「Pause」to freeze the current view for inspection, and the「Auto-scroll」toggle to control whether it always jumps to the latest line.

::: tip
You can also click the「Logs」button on any service card to pop up a live log window for **that service** directly — no need to switch to the Logs tab and filter.
:::

## Sandbox Tab

If sandbox capability is deployed and enabled, the「Sandbox」tab shows the runtime type and node / VM counts (online / busy / idle / failed), and supports actions such as launching nodes, scaling down, switching the runtime, and running a manual health check. On environments without sandbox enabled, this tab may be empty or hidden.

## Ops Notification Subscriptions

In the「Service Management」tab, you can subscribe to ops alert notifications (for events such as service restart or stop):

1. Add a subscriber (an email or other delivery address).
2. The platform pushes a notification to subscribers when a key ops event occurs.
3. Remove a subscriber when it's no longer needed.

::: info
Stopping a service is a critical-level alert (the service will be unavailable); restarting is a warning-level alert. Subscribe to learn about these changes right away.
:::

## Ops Helper

The Service Status page has a built-in AI Ops Helper that lets you troubleshoot in natural language instead of digging through logs and stitching metrics together yourself.

### Opening and Asking

Click the floating **「Nexus Assistant」** button in the bottom-right corner to open the helper panel; you can switch between "dock right" and "centered large window" layouts. The panel offers suggested troubleshooting questions, such as:

- Why isn't the worker consuming messages?
- Which service has been logging ERRORs recently?
- How do I diagnose an api startup failure?

You can also type a symptom or question directly, e.g. "What's the current running status of each service?"

### What the Answers Look Like

The helper streams its response and returns **structured results** based on your question. For example, asked "What's the current running status of each service?", it returns a service status table (Service / Status / PID / Port / CPU / Memory) that lists the live metrics for all 8 services at once.


::: warning
The Ops Helper is **read-only diagnostics** — it checks status, reads logs, and suggests how to investigate. It will **not** restart or stop services for you; those actions still require you to click the buttons on the service cards and take responsibility for confirming them.
:::

## Command Line (nexus-cli)

Besides the web UI, `nexus-cli` offers the same service management capabilities, handy on the server or in scripts:

```bash
nexus-cli status              # Show status of all services
nexus-cli start <service>     # Start a service
nexus-cli stop <service>      # Stop a service
nexus-cli restart <service>   # Restart a service
nexus-cli logs <service>      # View a service's logs
```

Here `&lt;service&gt;` is the service key, such as `api`, `worker`, `web`, `avatar`, `event`, `sandbox`, `bridge`, `otel`. Command-line actions have the same effect as the web buttons.

::: tip
For routine checks, prefer the web「Overview」— one screen shows health score, resources, and every service's status. Reach for `nexus-cli` when you need to act in bulk on the server or wire operations into an ops script.
:::

## Notes

- When something breaks, start with the health score and service list on「Overview」, use「Live Logs」to pinpoint the error, and ask the Ops Helper if needed.
- Schedule restarts / stops of critical services during off-peak hours; the `api` service is briefly unavailable during its restart.
- Stopping a service interrupts related features immediately and is recorded as a critical alert — don't leave one stopped for long unless necessary.
- The Ops Helper only diagnoses; it does not perform risky actions like restart / stop for you.
- When「Infrastructure Connections」shows `error`, the problem is likely in an underlying dependency (database / cache / storage) rather than a platform service itself.

## See Also

- [Built-in AI Helpers](./helper-agents.md) — full capabilities and usage of the Ops Helper
- [Config Management](./config-management.md) — where to go when a config change requires a restart
- [Deployment & Upgrade](./deploy-upgrade.md) — post-upgrade service restarts and nexus-cli service commands
