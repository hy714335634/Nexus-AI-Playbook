---
title: Model Catalog & Access
sync:
  source_commit: 7f4029536abf5945f2384f544555a3f6815c2519
  source_files:
    - config/model_catalog.yaml
    - web/app/(main)/settings/model-catalog/**
  generated_at: 2026-07-12T12:45:42+00:00
  generated_by: docs-sync v2
---

# Model Catalog & Access

The model catalog is the master list of language models the platform can use. As an administrator, you decide here which models are available on the platform, which tier each one belongs to, whether it accepts image input, and you can test each model's connectivity before saving. The models users and Agent builds can pick from all come from this catalog.

## What the model catalog does

- Add, remove, and edit selectable models, grouped by provider (Anthropic, Amazon, Meta, and so on)
- Tag each model with a **tier** (pro / standard / lite) and a **vision** capability
- **Test** each model for availability (a real call to Bedrock)
- **Reconcile with Bedrock** in one click to align with the models actually available in the current region
- **Restore defaults** when needed

## Opening the model catalog

Sidebar **Settings → Config Management**, then click **Model Catalog** at the top of the page (you can also enter it from the config page shortcut "Model Catalog — edit the selectable model list · saves take effect immediately after testing").

Once inside, the **Back to Config Management** link in the top-left returns you to the config page.

![settings-model-catalog](/images/settings-model-catalog.png)

## Page layout

Top action buttons:

| Button | What it does |
|--------|--------------|
| **Add Provider** | Add a new model provider group |
| **Reconcile with Bedrock** | Align with the models actually available in the current AWS Bedrock region |
| **Restore Defaults** | Reset the catalog to the platform's default list |
| **Save** | Save changes (disabled initially, enabled after edits) |

Each provider is a collapsible group containing a provider-name input and an **Add Model** button.

## Per-model fields

Under a provider group, each model is one row with the following fields:

| Field | Description |
|-------|-------------|
| Model ID | The Bedrock model identifier, e.g. `global.anthropic.claude-sonnet-5`; must match an ID actually available in Bedrock |
| Display name | The name shown to users, e.g. `Claude Sonnet 5` |
| Tier | Dropdown: `pro` / `standard` / `lite` (see "Tiers" below) |
| **Vision** | Checkbox; when checked, the model accepts image / document input |
| **Test** | Makes a real Bedrock call to verify the model is currently available |
| Delete | Trash icon at the start of the row; removes the model entry |

## Tiers

Tiers mark a model's cost / performance position so you can choose by scenario:

| Tier | Position |
|------|----------|
| `pro` | Most capable, highest cost; suited to complex reasoning and build tasks |
| `standard` | Balanced capability and cost; the general choice for everyday tasks |
| `lite` | Lightweight, low cost; suited to high-frequency, simple, or latency-sensitive scenarios |

## Capability markers

Beyond tier, the catalog reflects the following model capabilities, most of which need no manual handling:

- **Vision**: models with **Vision** checked accept image / document input; unchecked ones are text-only.
- **Tool calling**: all models support tool calling; for models that don't support streaming tool calls, the platform automatically falls back to non-streaming, with no extra configuration.
- **temperature parameter**: newer "thinking" models (such as Claude Opus 4.6 and above, Claude Sonnet 4.6, and the Claude 5 family) don't accept the temperature parameter; the platform adapts automatically.
- **Prompt caching**: the Claude and Nova families support Bedrock Prompt Caching, which helps cut the cost of repeated context.

## Management actions

### Add a provider and models

1. Click **Add Provider** and enter the provider name in the group's name input.
2. Click **Add Model** under that group to add a row.
3. Fill in the **Model ID** and **Display name**, choose a **Tier**, and check **Vision** if applicable.
4. Click **Test** on that row to confirm the model is available.
5. When everything looks right, click **Save** at the top.

### Test model connectivity

Every model row has a **Test** button that makes a real Bedrock call. When bringing up a new model or changing a model ID, test it successfully before saving so users don't pick a model that isn't available.

### Reconcile with Bedrock

Click **Reconcile with Bedrock** to automatically align with the models actually available in the current AWS region, reducing manual upkeep. The command-line equivalent is:

```bash
nexus-cli model reconcile
```

### Restore defaults

**Restore Defaults** resets the catalog to the platform's default list.

::: warning Caution
**Restore Defaults** overwrites all of your custom providers and model entries and cannot be undone. Make sure you've exported or recorded the current configuration first.
:::

### Saving and taking effect

Saved changes take effect immediately for **new conversations**; conversations already in progress are unaffected. The catalog starts from the platform's default list, and your changes are saved as an override on top of it.

::: tip Tip
Changes take effect only after you click **Save**. Testing without saving does not change the list of models available to users.
:::

## Setting the default model in Config Management

The catalog decides "which models are selectable"; "which one is the default" is set in [Config Management](./config-management.md):

- Sidebar **Settings → Config Management**, find the **Model** parameter (`bedrock.model_id`).
- This parameter carries a **hot-reload** badge, so switching it takes effect immediately for new conversations without a restart.
- Each config field has an **Ask AI: effect and impact of changes** button for asking the Config Helper about that parameter.

The "Just say what you want to tune" box at the top of the config page supports natural-language parameter search (e.g. "reduce usage cost", "which changes require a restart"). If a search returns zero matches, try different keywords.

![settings-config](/images/settings-config.png)

## Viewing model usage

Actual model consumption is shown by model in the [usage report](./billing.md):

- Sidebar **Management → Usage Report** (or `/admin/billing`), see **Consumption by Model**, including call counts and input / output tokens.

![admin-billing](/images/admin-billing.png)

## FAQ

| Problem | What to do |
|---------|------------|
| Users can't pick a certain model | Confirm the model is in the catalog and has been **Saved**; verify connectivity with **Test** |
| **Test** fails | Check that the model ID matches an ID actually available in Bedrock; use **Reconcile with Bedrock** to align |
| Changed the catalog but nothing happened | Confirm you clicked **Save**; changes apply only to new conversations |
| Not sure which tier to pick | Use `pro` for complex reasoning, `standard` for everyday tasks, `lite` for high-frequency lightweight cases |

## See Also

- [Config Management](./config-management.md) — switching the default model, hot-reload parameters, and the Config Helper
- [Usage & Billing](./billing.md) — token consumption reports by model / user / project
