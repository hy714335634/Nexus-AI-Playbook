---
title: FAQ & Troubleshooting
sync:
  source_commit: 9d40a32f2bad2c7858b3ed0cfb4390e1bd603a30
  source_files:
    - README.md
    - docs/operations/**
  generated_at: 2026-07-12T13:07:55+00:00
  generated_by: docs-sync v2
---

# FAQ & Troubleshooting

This chapter collects the problems admins hit most often, along with how to track them down. When something breaks, use the **triage flow** below to locate it first, then jump to the matching section for the fix. Each category tells you which page to check first, which built-in helper to ask, and which chapter to read.

## Triage Flow

When something goes wrong, these three steps are usually the fastest path:

1. **Check service status first** — Sidebar「Management」→「Service Status」. Look at the health score and whether each service is online. This is usually the first place to look.
2. **Then check the logs** — On the「Live Logs」tab of Service Status, filter by service / level / keyword to find the failing line.
3. **Ask a helper or read a chapter** — Use the built-in **Ops Helper** to troubleshoot in natural language, or use the table below to jump to the relevant chapter.

| Symptom | Look here first | Related chapter |
|---------|-----------------|-----------------|
| Page won't load / a service is unhealthy | Service Status overview + live logs | [Service Status Monitoring](./service-status.md) |
| Deploy failed midway, environment not found | `nexus-cli deploy` on the deploy host | [Deployment & Upgrade](./deploy-upgrade.md) |
| Can't log in / SSO error | Login page + auth config | [Login & SSO](./sso-auth.md) |
| Build / chat returns `AccessDeniedException` | Bedrock console model access | [Model Catalog & Access](./model-access.md) |
| Backup or artifact sync fails | `nexus-cli` on the deploy host | [Config Management](./config-management.md) / [Deployment & Upgrade](./deploy-upgrade.md) |
| Logo / branding change didn't take effect | Branding config + hard-refresh browser | "Branding & Logo" in this chapter |

![admin-service-status](/images/admin-service-status.png)

## Services & Operations

**Services that won't start, pages that won't load, failing requests** can mostly be pinpointed on the Service Status page.

| Symptom | What to check |
|---------|---------------|
| Web UI won't load | Confirm the Frontend (Web, :3000) service is online; if not, click「Start」on its card or run `nexus-cli service start --web` |
| API errors / data won't load | Confirm the API (:8000) is online; check the API ERROR lines in「Live Logs」 |
| Build jobs stay queued and never run | Usually the Worker isn't consuming; confirm Worker is online and restart it if needed |
| UI briefly unresponsive | If you just restarted `api`, this is normal — the API is briefly unavailable during a restart and recovers on its own |
|「Infrastructure connections」shows `error` | The problem is usually in an underlying dependency (database / cache / storage), not the platform service itself; confirm those managed services are reachable |

::: warning
Stopping a service makes its features **immediately unavailable** (e.g. stopping the Worker halts build-job consumption). Both stop and restart are recorded as ops alerts. Do this during off-peak hours, and don't leave critical services stopped unless necessary.
:::

See [Service Status Monitoring](./service-status.md) for the full guide to starting/stopping services, logs, and health.

## Deployment & Upgrade

Deployment and upgrades both run on the **deploy host** via `nexus-cli`. Common issues:

| Symptom | What to check |
|---------|---------------|
| Deploy failed midway, leaving half-built resources | Usually regional service quotas (EIP / VPC / NAT, etc.) are exhausted or deploy permissions are missing; fix that and re-run the **same command** to resume — it won't recreate the stack |
| Can't find an environment's status | Run `nexus-cli deploy list` to confirm the env prefix, then `nexus-cli deploy status &lt;prefix&gt;` |
| Upgrade link expired | The one-click upgrade link has a lifetime (default a few hours, max 7 days); ask the maintainer to reissue it if it expired |
| Target version can't be upgraded | Versions that are too old may lack the components the upgrade needs; redeploy instead |

::: tip
An upgrade only updates the code and local config on the compute node — **your data is untouched**, since the database, cache, and object storage all live outside the node. An upgrade restarts services and causes a brief interruption, so run it off-peak.
:::

See [Deployment & Upgrade](./deploy-upgrade.md) for the full deploy, upgrade, and teardown flow.

## Login & Authentication

| Symptom | What to check |
|---------|---------------|
| Forgot password / first login | The password-mode default credentials are `admin` / `nexus`; always change them at deploy time in production |
| SSO enabled but login fails | Confirm SSO is turned on in auth config, the IdP metadata URL is correct, and the callback URL matches the actual domain |
| SSO rejects the domain | If an email-domain allowlist is configured, only domains on it can log in; confirm the user's email domain is allowed |
| SSO fully down, need in urgently | Password-mode credentials are kept as a fallback config admin even after SSO is enabled, so you can use them for emergency access |

See [Login & SSO](./sso-auth.md) for login modes, IdP integration, and user-group assignment.

## Model Access

Builds and chat depend on models on AWS Bedrock. **A new account must enable model access manually before first use** — IAM permissions can't do this for you.

| Symptom | What to check |
|---------|---------------|
| Build / chat returns `AccessDeniedException` | Go to the Bedrock console → *Model access* in your **deploy region**, request the models the platform needs (the Claude family), then retry |
| Error mentions `aws-marketplace:ViewSubscriptions` / `Subscribe` | Same as above — the target model isn't subscribed/enabled in the account yet |
| Some features work, others fail | The platform uses three tiers — default, lite, and pro models; confirm all three are enabled in the deploy region |

See [Model Catalog & Access](./model-access.md) for model tiers, regions, and how access works.

## Backup, Restore & Artifact Sync

Project backups and Agent artifact sync use object storage and data tables. These resources are initialized once with `nexus-cli init`.

| Symptom | What to check |
|---------|---------------|
| "Object storage bucket / data table does not exist" | Run `nexus-cli init` on the deploy host to initialize the missing infrastructure |
| Sync / backup returns `Access Denied` | The deploy role lacks read/write permission on object storage or data tables; apply the runtime IAM policy shipped with the platform |
| "No files found for an Agent" | Confirm the Agent name is spelled correctly and that the Agent actually exists in this environment |
| Want a safety net before overwriting an existing project | A force overwrite **creates a safety backup first**, so you can proceed with confidence |

::: warning
Adding `--clean-data` when tearing down an environment also deletes the data in object storage, data tables, and queues — this **cannot be undone**. Confirm the data is no longer needed or has been backed up separately before running it.
:::

See [Config Management](./config-management.md) and [Deployment & Upgrade](./deploy-upgrade.md) for day-to-day backup and artifact management.

## Branding & Logo

When you swap in a customer's custom logo, the most common issue is "changed the config but the page didn't update" — usually a caching problem.

| Symptom | What to check |
|---------|---------------|
| Changed branding config but the logo didn't change | The frontend caches branding config, so switching pages won't refetch it. **Hard-refresh** the browser (`Cmd+Shift+R` / `Ctrl+Shift+R`); if there's a CDN / reverse-proxy cache, add a version param to the logo URL (e.g. `/logo.svg?v=2`) |
| SVG opens fine in the browser but doesn't show on the page | An SVG containing external fonts, external images, or inline scripts is blocked by the security policy (CSP). Use a plain SVG with vector paths only |
| Logo is hard to read only in dark mode | Prepare a dark-background variant of the logo and set its URL in the branding config |
| Swapped the logo but the browser tab icon (favicon) didn't change | The tab icon doesn't come from branding config; replace the favicon file separately, then restart the Web service |

::: tip
After swapping the logo, check that all these spots updated: the desktop sidebar, the mobile header and drawer menu, the login page, and the Agent backup-import dialog.
:::

::: info
After replacing branding assets you must **restart the Web service** for the new static assets to take effect: `nexus-cli service restart --web`. The API service picks up the new branding config on its next read and usually needs no restart.
:::

## nexus-cli Quick Reference

For routine checks, prefer the web「Service Status」page — one screen shows health, resources, and every service's status. Use `nexus-cli` when you need to act on the server or script it into ops automation:

```bash
nexus-cli service status              # show status of all services
nexus-cli service logs --api          # view a specific service's logs
nexus-cli service logs -f             # follow logs live (Ctrl+C to exit)
nexus-cli service restart --api       # restart a specific service
nexus-cli service stop --web          # stop a specific service
nexus-cli service start --web         # start a specific service
```

Service selectors include `--api`, `--worker`, `--web`, `--mcp`, etc.; the CLI actions match the web buttons. Add `--lang zh` to any command for Chinese prompts.

::: tip
`nexus-cli service` commands run on the application node. See [MCP Service Management](./mcp.md) for starting/stopping the MCP service and managing its token.
:::

## How the Built-in Helpers Assist Troubleshooting

Every management page has an on-hand AI helper, so you can ask in natural language instead of digging through docs first:

| Helper | Where to open | What to ask | Guardrail |
|--------|---------------|-------------|-----------|
| **Ops Helper** | Floating button, bottom-right of Service Status | Which service is unhealthy, who's flooding ERROR lately, how to diagnose a failed startup | **Read-only diagnosis** — it won't restart / stop services for you |
| **Config Helper** | Configuration Management page | What a setting does, which one to change for an effect, whether a restart is needed | Any change still requires your confirmation to run |
| **Audit Helper** | Audit Log page | Who did what and when, searchable by person / time / action | Read-only search — it doesn't modify data |

![ops](/images/ops.png)

::: warning
The Ops Helper only diagnoses — checking status, reading logs, suggesting where to look. It **won't** restart or stop services for you; those risky actions still require you to click the button on the service card and confirm.
:::

See [Built-in AI Helpers](./helper-agents.md) for the helpers' full capabilities.

## Notes

- When something breaks, check the Service Status health and service list first, then use「Live Logs」to find the error, and ask the Ops Helper if needed.
- Restart / stop critical services off-peak; the `api` service is briefly unavailable during a restart.
- Before first use on a new account, enable model access manually in the Bedrock console of your deploy region — otherwise builds and chat return `AccessDeniedException`.
- Always change the password-mode default credentials (`admin` / `nexus`) in production.
- Options like `--clean-data` on teardown and source-delete on backup **cannot be undone** — confirm carefully before running them.
- When「Infrastructure connections」shows `error`, the problem is likely in an underlying managed dependency, not the platform service itself.

## See Also

- [Built-in AI Helpers](./helper-agents.md) — full capabilities of the Ops / Config / Audit helpers
- [Service Status Monitoring](./service-status.md) — health, logs, and service start/stop guide
- [Config Management](./config-management.md) — parameter tuning and the Config Helper
