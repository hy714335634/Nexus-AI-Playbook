---
title: Usage & Billing
sync:
  source_commit: 7f4029536abf5945f2384f544555a3f6815c2519
  source_files:
    - api/v2/routers/admin_billing.py
    - web/app/(main)/admin/billing/**
  generated_at: 2026-07-12T12:37:37+00:00
  generated_by: docs-sync v2
---

# Usage & Billing

**Usage & Billing** is a **usage report**: it attributes token consumption across four dimensions — model, user, project, and app — and lets you set token quotas for users and apps. Use it to answer questions like "who used the most this month," "which model burned most of the tokens," and "how much budget does this app have left."

::: info About "billing"
This page shows **usage only** (invocations, token consumption, quotas) — not dollar amounts. Underlying model prices change often, so no cost conversion is done here to avoid being misleading. Treat token consumption as the base data for cost attribution, then apply your own contract rates.
:::

<!-- SCREENSHOT: admin-billing -->

## Open the usage report

1. In the sidebar, go to **Admin** → **Usage & Billing**.
2. A **month picker** sits in the top-right corner, defaulting to the current month. Pick any year/month to reload the page data for that month.

The page uses a two-column layout:

- **Left (main) · User-level usage**: active users, invocations, token consumption, and rankings by model / user / project.
- **Right (secondary) · Platform-level usage**: the token consumption of the platform's own built-in helpers (config, audit, ops, etc.).

A separate **App usage (last 30 days)** block sits below.

## Read the overview metrics

Four key metrics (KPIs) at the top of the main column reflect overall usage for the selected month:

| Metric | Meaning |
|--------|---------|
| Active users | Users who made at least one call this month |
| Total invocations | Cumulative invocations for the month |
| Input tokens | Total tokens sent to models this month |
| Output tokens | Total tokens returned by models this month |

Below the KPIs, an **input / output ratio** bar shows whether the month's tokens went into input or output. When the input share is very high (≥90%), a hint appears — usually a sign of long context or prompts, which points to an optimization opportunity.

## View consumption by model

The **Consumption by model** block shows each model's usage as a donut chart plus a table:

| Column | Meaning |
|--------|---------|
| Model | Model identifier (e.g. `anthropic.claude-opus-4-8`) |
| Invocations | Times the model was called this month |
| Input | Input tokens |
| Output | Output tokens |
| Total tokens | Input + output |

Use it to spot which model is the main cost driver, then decide whether to move some scenarios to a lighter model (model tiers are maintained under **Settings** → **Model Catalog**).

## Top users and top projects

- **Top users**: shows the top 5 by total tokens by default; click **Expand all** to see more. A search box above filters by **user name / email / user ID**.
  - The table includes a **Quota usage** column showing the percentage of the user's monthly budget consumed. **Rows near the limit (≥80%) are highlighted amber; over-limit rows (≥100%) are highlighted red** with a warning icon.
  - Click any row (or the external-link icon at the end) to open that user's **usage and quota detail page**.
- **Top projects**: aggregates token consumption by project, paginated (5 per page).

<!-- SCREENSHOT: admin-billing-usage -->

## View a single user's usage and quota

Clicking into a user from the Top users list shows that user's:

- **Usage trend over recent months** (last 6 months by default);
- **This month's usage broken down by model**;
- **Current token quota** and the percentage used.

This is your first stop when investigating "someone's tokens spiked" or "a user reports being rate-limited."

## Manage a user's token quota

On the user's usage and quota detail page, you can set a **monthly token quota** for that user. A quota has three parts:

| Field | Purpose | Default |
|-------|---------|---------|
| Monthly token budget | The user's monthly token ceiling | None (unlimited) |
| Alert threshold (%) | Warn when usage reaches this percentage | 80 |
| Disable on exceed | Whether to stop the user's calls once the ceiling is hit | Off |

After saving, the **Quota usage** column in the user list uses this to compute the amber / red markers.

::: warning Quota changes are audited
Every quota change is written to the **audit log** (searchable under **Settings** → **Audit Trail**). The record includes the acting admin, the target user, and the new budget and threshold values. Be careful with **Disable on exceed** — once enabled, a user who goes over budget can no longer make calls.
:::

## App usage and app quotas

The **App usage (last 30 days)** block at the bottom aggregates usage per app:

| Column | Meaning |
|--------|---------|
| App | App name and ID |
| Visits | Visits in the last 30 days |
| Invocations | Invocations in the last 30 days |
| Total tokens | Total tokens in the last 30 days |
| Avg per invocation | Total tokens ÷ invocations |
| Quota (cumulative) | The app's token budget and cumulative usage; shows "Unlimited" when no budget is set |

- Click **Expand model / input-output detail** on any row to see that app's breakdown by model and by input / output direction.
- The quota column supports **inline editing**: click the edit icon, enter a new token budget, and save to apply. Apps whose cumulative usage meets or exceeds the budget are flagged as over budget.

::: tip Long-running apps
An app quota is **cumulative** (it does not reset monthly). Leave ample headroom when budgeting a long-lived, public-facing app, or set it to "Unlimited" as needed, so it isn't flagged as over budget once the allowance runs out.
:::

## Platform built-in helper usage

The right sidebar tallies the tokens consumed by the platform's **built-in AI helpers** (such as the config, audit, and ops helpers), grouped by module; expand to see a further breakdown by model and by input / output. This is tracked separately from end-user business calls, making it easy to gauge how much usage the platform's own capabilities take up.

## Notes and FAQ

::: info No dedicated AI helper on this page
The Usage & Billing page has no floating AI helper of its own. To ask natural-language questions like "who changed the config" or "were there any abnormal logins," use the **Audit Helper** under **Settings** → **Audit Trail**; to tune parameters for cost reduction in natural language, use the **Config Helper** under **Settings** → **Config Management**.
:::

- **No cost amounts shown**: this is by design (see the note at the top). Use token consumption for cost accounting.
- **A user / app always shows "-" or "Unlimited" quota**: it means no budget has been set yet — this is normal and does not affect usage tracking.
- **Data goes empty after switching months**: that month has no usage records; switch back to a month with activity.
