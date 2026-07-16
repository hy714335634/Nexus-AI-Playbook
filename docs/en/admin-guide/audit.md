---
title: Audit Trail
sync:
  source_commit: 7f4029536abf5945f2384f544555a3f6815c2519
  source_files:
    - api/v2/routers/audit.py
    - web/app/(main)/settings/audit/**
  generated_at: 2026-07-12T12:35:11+00:00
  generated_by: docs-sync v2
---

# Audit Trail

The Audit Trail page brings "who did what to what, when, and with what outcome" into one place: you get a trend dashboard, multi-dimensional search over the details, export for retention, email subscriptions, and an AI Audit Assistant that helps you investigate and produce compliance reports. Audit records are **tamper-evident**, and you can verify their integrity at any time.

::: info
This page is admin-only. Auditing covers platform management actions such as logins, configuration changes, user management, denied access, and audit exports — even actions like "export audit" and "generate compliance report" are themselves recorded.
:::

### Typical Scenario

A user reports their Agent was modified without their knowledge. You open「Audit Trail」->「Logs」, type that Agent's name in the search box, and instantly see who changed it, when, and what they changed. If the filter conditions are hard to assemble, click the「Nexus Assistant」button in the top-right corner and ask in plain language: "Who modified XX Agent in the past week?" The assistant returns the operator, timestamp, and a summary of what was changed.

## Opening the Audit Trail

Sidebar「Settings」→「Audit Trail」, or go directly to `/settings/audit`.

The top of the page has three tabs, with a floating「Nexus Assistant」button (the AI Audit Assistant) in the top-right corner:

| Tab | Purpose |
|-----|---------|
| **Dashboard** | Audit overview for a time range: action breakdown, success rate, anomaly hints, integrity check |
| **Logs** | Multi-dimensional search over audit details, expand to see changes, export CSV / JSON |
| **Subscriptions** | Subscribe email addresses to audit event notifications and compliance report delivery |

![settings-audit](/images/settings-audit.png)

## Dashboard

Purpose: see, at a glance, the audit overview for the selected period and whether anything looks off.

1. Open the「Dashboard」tab (the default tab).
2. Switch the statistics window with the time-range buttons at the top:「Last 7 days」「Last 30 days」「Last 90 days」.
3. Review the charts and hints:
   - **Action breakdown** pie chart (aggregated by type, such as `auth` / `user` / `config`).
   - **Success rate** pie chart (share of success / failure / denied).
   - **Anomaly hint card**, e.g. "N off-hours actions this period" — a nudge to review sensitive actions performed outside working hours.
4. Click a slice in a chart to jump straight to the「Logs」tab with that filter already applied.

### Integrity Check

Audit records are stored **tamper-evident** and chained together. Click the「Re-verify」button on the dashboard and the platform re-checks whether the entire audit chain is intact and untampered, returning the result (records checked / total, plus the location of the first anomaly, if any).

::: warning
If the check reports the chain is not intact, audit records may have been altered or are missing — investigate immediately and preserve the state; do not keep performing overwriting actions.
:::

## Searching the Logs

Purpose: pinpoint a specific action by user, action, resource, outcome, time, or keyword.

Entry:「Audit Trail」→「Logs」tab.


### Filters

The filter bar supports the following conditions and re-queries automatically when changed:

| Filter | Description |
|--------|-------------|
| **Search box** | Keyword match (across action, email, detail, and other text) |
| **Action** | Filter by a specific action, such as `auth:login`, `config:update`, `config:rollback`, `config:import`, `user:create`, `user:change_role`, `user:change_status`, `user:change_policies`, `user:delete`, `user:reset_password`, `access:denied`, `audit:export` |
| **Resource type** | `config` / `user` / `auth` / `audit` |
| **Outcome** | Success / Failure / Denied |
| **Date range** | Start date → end date |

Once any filter is set, a「Clear」button appears in the bar to reset all conditions at once.

### Table and Details

Logs are shown as a table with the following columns:

| Column | Content |
|--------|---------|
| **Time** | When the action occurred |
| **Operator** | Username and email |
| **Action** | Action label (color-coded by type) |
| **Resource** | Resource type / resource ID |
| **Outcome** | Success / Failure / Denied |
| **IP** | Source IP address |

1. Click a row with an expand arrow to reveal that record's details:
   - **Detail** text description;
   - **Changes**: config / user actions list each change as "field: old value → new value";
   - **Reason** (if any);
   - **Request ID** (for cross-system tracing).
2. The bottom of the list shows how many records are loaded; if there are more, click「Load more」to page through.

## Export for Retention

Purpose: export the audit records within the current filter for archival, offline analysis, or compliance submission.

1. On the「Logs」tab, set your filters (export uses the current filter).
2. Click the「Export」button on the right of the filter bar and choose from the dropdown:
   -「Export as CSV」— a flat table where changes are merged into a single text column, good for spreadsheets.
   -「Export as JSON」— structured data, good for programmatic processing.

Exported fields include time, operator email / username, action, resource type / ID, outcome, IP, request ID, reason, detail, and changes.

::: info
The export action itself is recorded in the audit (`audit:export`), noting the number of records and the format. A single export has a record cap, so narrow the range with filters first if the scope is large.
:::

## Subscriptions

Purpose: let the right people receive audit event notifications and compliance reports by email, without watching the page constantly.

Entry:「Audit Trail」→「Subscriptions」tab.

1. Open the「Subscriptions」tab to see all current email subscriptions and their **confirmation status**.
2. Add a subscription: by **email**, **Nexus username**, or **user ID**.
3. The system sends a confirmation email to that address; the subscription only takes effect after the recipient confirms (status changes from pending to confirmed).
4. To unsubscribe, remove the corresponding subscription from the list.

::: info
Adding / removing a subscription is also recorded in the audit (`audit:subscribe` / `audit:unsubscribe`).
:::

## AI Audit Assistant

Purpose: query the audit in natural language, summarize a period, and generate a compliance report in one click — no manual filter assembly needed.

Entry: the floating「Nexus Assistant」button in the top-right of the audit page. The panel toggles between "docked right" and "centered large window."


### Q&A

Ask in plain language in the input box; the assistant fetches data **within the current filter** on the server and streams its answer. The panel offers a few common questions as a starting point:

- Who changed the configuration during this period?
- Any failed logins or unauthorized attempts?
- Which user is most active?

Answers are usually a structured summary (counts, users and IPs involved, a list of timestamps, and an anomaly judgment such as "no failures, IPs in the same range, nothing abnormal so far"). An answer may include a **jump button** (e.g. "View today's login records") that takes you to the「Logs」tab with the matching filter applied.

### Period Summary and Compliance Report

The top of the panel has three action buttons, and their **scope follows the current filter**:

| Button | Effect |
|--------|--------|
| **Period Summary** | Generate a streaming text summary of audit activity in the selected period |
| **Generate Compliance Report** | Produce a structured compliance report (for archival); the generation action is itself recorded in the audit |
| **Send to SNS** | Deliver the generated compliance report to the audit notification email subscribers |

::: tip
Set the time range, action type, and other filters on the「Logs」or「Dashboard」tab first, then ask the assistant for a「Period Summary」or「Generate Compliance Report」so the result targets exactly the scope you care about.
:::

::: warning
The AI Audit Assistant only queries, summarizes, and reports — it **never alters any audit records**; all audit data is read on the server within scope and is unaffected by the assistant.
:::

## Notes

- Auditing is admin-only, and actions like export and report generation leave their own trace — this is by design, for accountability.
- Periodically use「Re-verify」to confirm the audit chain is intact; if it flags an anomaly, preserve the state before investigating.
- For a large export, narrow the range with filters first to stay under the single-export cap.
- A subscription only takes effect after the recipient confirms the email — follow up on the confirmation status after adding one.
- Not sure how to search? Ask the AI Audit Assistant first and use its jump button to reach the detail list.

## See Also

- [AI Assistants (incl. Audit Assistant)](./helper-agents.md) — full capabilities of the Audit Assistant
- [Users & Permissions](./users-permissions.md) — context for user actions, role changes, and other events that appear in the audit
- [SSO & Authentication](./sso-auth.md) — authentication mechanisms behind login audit events
