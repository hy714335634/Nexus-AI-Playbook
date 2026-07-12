---
title: Configuration Management
sync:
  source_commit: 7f4029536abf5945f2384f544555a3f6815c2519
  source_files:
    - api/v2/config_registry.py
    - config/default_config.yaml
    - web/components/config/ConfigManager.tsx
  generated_at: 2026-07-12T12:27:09+00:00
  generated_by: docs-sync v2
---

# Configuration Management

The Configuration Management page lets you tune platform-wide runtime parameters field by field in one place — models, conversation strategy, attachment limits, observability, message queues, and more. Every item is tagged with **whether a change applies immediately or requires a service restart**. Changes go into a draft first, save in one batch after you confirm, and restart-required items can be restarted with one click.

::: info
Configuration is stored "database-first, file-fallback": edits made here are saved to the platform database and do not overwrite the config files on the server.
:::

## Opening Configuration Management

Sidebar「Settings」→「Configuration Management」, or go directly to `/settings/config`.

The top of the page offers quick links to three related areas:

- **Sharing Management** — file sharing policy and delivery channels
- **Model Catalog** — edit the list of available models (saves take effect immediately after testing)
- **Browser Extension** — manage Chrome extension devices

![settings-config](/images/settings-config.png)

## Interface Overview

There are many parameters (currently around 132), so the page uses two layers of filtering to help you locate them fast:

1. **Category tabs** (top): switch by major category; each tab carries a count badge.
   - All
   - AI & Models
   - Content & Collaboration
   - Runtime & Deploy
   - Observability & Logs
   - Others
2. **State filters** (below the tabs):
   - All
   - Changed
   - Hot-reload
   - Restart

Each parameter is shown as a card with: its label, a description, the value control (toggle / number / dropdown / model picker / text), and an **effect badge**.

### Effect Badges

| Badge | Meaning | After saving |
|-------|---------|--------------|
| 🟢 **Hot-reload** | Applies on next read | No restart; new sessions / new calls pick it up immediately |
| 🟠 **Restart** | Requires restarting affected services | Restart `api` and/or `worker` after saving |

::: tip
To see only changes that require a restart, click the「Restart」state filter to show just those parameters.
:::

## Configuration Groups at a Glance

The category tabs group the underlying sections into four major areas so you can search by goal:

| Category | Covers |
|----------|--------|
| **AI & Models** | Standard / Lite / Pro models, prompt caching, conversation management strategy, multimodal parsing, vector search & rerank |
| **Content & Collaboration** | Attachment size and URL TTLs, template AI analysis, sharing & backup policy |
| **Runtime & Deploy** | AgentCore deploy, workflows, runtime retry, message queue, service runtime, sandbox |
| **Observability & Logs** | Trace sampling rate, data capture granularity, log level, audit & ops alerts |
| **Others** | Config groups not placed in the categories above |


## Editing and Saving Configuration

1. Find the target parameter (use category tabs, state filters, or the search box — see "Configuration Helper" below).
2. Edit the value directly on the field control. The field enters a "pending" state; use the「Changed」state filter to review all pending edits.
3. Click「Save」.
   - If your changes are **all hot-reload items**: they save directly, you get a success toast, and they take effect immediately.
   - If any change **requires a restart**: a confirmation dialog opens, listing each change and the affected services; you can tick「Restart automatically after saving」in the dialog.
4. Confirm the save. If you chose auto-restart, the platform restarts affected services after saving; otherwise a「Restart now」action button appears so you can trigger it later manually.

::: warning
Restarting the `api` service causes a brief outage — the platform schedules the restart asynchronously, polls for recovery automatically, and notifies you when it's back. Schedule restart-required changes during off-peak hours.
:::

::: tip
Made a mistake and want to undo? Change the value back to its original — the field automatically leaves the "pending" state (dirty tracking is exact: matching the original counts as no change).
:::

## Sensitive Parameters

Secret / credential parameters (such as the admin password) are marked sensitive:

- They are **masked and read-only** in the UI — only "set / not set" is shown, never the plaintext.
- These values are **never written to the database**; they come only from config files or environment variables.

::: warning
Sensitive items cannot be edited here. To change one, update the config file or environment variable on the server and restart the relevant services as prompted.
:::

## History and Rollback

Each parameter card has a「History」button to view that parameter's change log and roll back to an earlier value. Rollback goes through the normal save flow — if the item requires a restart, the rollback also needs a restart to take effect.

## Config Doctor

The「Config Doctor」button at the top scans the current configuration and lists potential issues (such as out-of-range values, conflicts, or better recommendations). Each finding has a「Locate parameter」action that jumps to the matching field. Results are cached, so reopening the panel won't re-scan unless you rescan manually.


## Export and Import

- **Export**: click「Export」to download a snapshot of the current configuration (a timestamped JSON file), useful for backup or migrating to another environment.
- **Import**: click「Import」and choose a snapshot file. The platform **runs a dry-run preview first**, listing the number of changes and affected services, and only writes them after you confirm.

::: tip
Before importing, export the current configuration first as a rollback point.
:::

## Configuration Helper (Config Helper)

The config page has a built-in AI assistant that helps you find parameters in natural language, understand what an item does, and assess the impact of a change.

### Find parameters in natural language

The「Just tell me what to tune」area provides a natural-language search box (semantic matching, not just keywords).

1. Describe your goal in the box, e.g. "lower cost" or "conversations keep losing context".
2. Click「AI Search」. Matching parameters are filtered and highlighted.
3. You can also click a preset suggested query: **Lower usage cost**, **Conversations keep losing context**, **Which changes need a restart**.

::: info
A search may return zero matches (for example, if the parameter you asked about isn't manageable here, you'll see "AI matched 0 related parameters"). Rephrase or try different keywords.
:::

### Per-field AI explanation

Each parameter card has an「Ask AI: purpose & impact」button. Clicking it opens the assistant and auto-asks about that parameter — a quick way to understand "what this does and what happens if I raise or lower it." The assistant's suggestion can be written into the draft in one click (using the normal save flow) and reverted at any time.

### Assistant panel

Click the floating「Nexus Assistant」button to open the panel, which can toggle between "docked right" and "centered large window." The panel offers common suggested questions, such as:

- I want to lower usage cost
- What to do when conversations keep losing context
- What is prompt caching, should I enable it
- Which parameters require a service restart when changed


::: warning
The assistant only explains, searches, and suggests draft changes — it **does not save or restart for you**. All changes still require you to click「Save」and confirm in the main interface.
:::

## Common Parameters Quick Reference

Below are the more frequently tuned parameters and their effect type (not exhaustive — the page is the source of truth).

### AI & Models

| Parameter | Purpose | Effect |
|-----------|---------|--------|
| Standard Model | Default chat / build model | 🟢 Hot-reload |
| Lite Model | Low-cost tasks (classify, summarize, quick judgment) | 🟢 Hot-reload |
| Pro Model | Complex reasoning / multimodal main model | 🟢 Hot-reload |
| Enable Prompt Caching | Cache system prompt / tool definitions to cut input-token cost | 🟢 Hot-reload |
| Bedrock Read Timeout (s) | Raise for long outputs | 🟠 Restart (api, worker) |
| Enable Conversation Manager | Auto window / summarize long chats to control context length | 🟢 Hot-reload |
| Strategy | Sliding window (keep recent N) or summarizing (compress old messages) | 🟢 Hot-reload |
| Proactive Compaction Threshold | Trigger compaction when usage reaches this ratio | 🟢 Hot-reload |
| Embedding Model | Embedding model used for vector search | 🟠 Restart (reindex needed to fully apply) |

### Content & Collaboration

| Parameter | Purpose | Effect |
|-----------|---------|--------|
| Max Attachment Size (bytes) | Max bytes per attachment (default 50MB) | 🟢 Hot-reload |
| Download / Upload URL TTL (s) | Presigned link lifetime | 🟢 Hot-reload |
| Template AI Analysis | AI-analyze / vectorize templates on upload | 🟢 Hot-reload |
| Backup Share Mode / TTL | Backup sharing method and default / max TTL | 🟢 Hot-reload |

### Runtime & Deploy

| Parameter | Purpose | Effect |
|-----------|---------|--------|
| Deploy Dry-Run | Simulate deploy only, for debugging | 🟠 Restart (api, worker) |
| Post-deploy Test | Run tests automatically after deploy | 🟠 Restart (api, worker) |
| Enable Retry / Max Attempts | Agent runtime retry strategy | 🟢 Hot-reload |
| Build Visibility Timeout (s) | Should exceed the longest build time, or messages get re-consumed | 🟠 Restart (worker) |
| Max Retry Count / Message Retention (days) | Queue retry and retention policy | 🟠 Restart (worker) |

### Observability & Logs

| Parameter | Purpose | Effect |
|-----------|---------|--------|
| Enable Observability | Master switch for traces / metrics / logs | 🟠 Restart (api, worker) |
| Production / Development Sampling Rate | Sampling ratio (0.1 = sample 10%) | 🟠 Restart (api, worker) |
| Tool Input Capture | none / hash_only / redacted_preview (use hash_only or none for compliance) | 🟠 Restart (api, worker) |
| Log Level | DEBUG / INFO / WARNING / ERROR / CRITICAL | 🟢 Hot-reload |

### Sensitive

| Parameter | Purpose | Effect |
|-----------|---------|--------|
| Admin Password | Masked and read-only; file / env only, never written to the database | 🟠 Restart (api) |

## Notes

- Batch restart-required changes into a single off-peak window to minimize service interruptions.
- Export the current snapshot as a rollback point before importing configuration.
- Sensitive items aren't edited here — use config files / environment variables.
- Unsure what a parameter does or affects? Use the「Ask AI」button on the field to ask the Config Helper before changing it.
