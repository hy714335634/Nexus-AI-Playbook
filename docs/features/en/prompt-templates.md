---
title: Prompt Templates
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - nexus_utils/prompts_manager.py
    - prompts/template_prompts/**
  generated_at: 2026-05-08T15:31:56+00:00
  generated_by: docs-sync v2
---

# Prompt Templates

## What it is

Prompt templates are a set of ready-to-use agent blueprints shipped with Nexus-AI. Each template is a complete YAML configuration that bundles a system prompt, environment parameters, model choices, and tool dependencies, so you can start a new agent from a proven baseline instead of writing the prompt from scratch.

## When to use it

| Scenario | Recommended template | Notes |
| --- | --- | --- |
| You need an agent that talks to an external API (HTTP calls, auth, data sync) | `api_integration` | Ships with HTTP client, auth manager, and data sync tools |
| You want the agent to produce articles, reports, marketing copy, or creative writing | `content_generator` | Higher temperature for more expressive output |
| You want to read CSV/JSON/Excel data and output statistics or insights | `data_analyzer` | Bundled with file I/O and data conversion tools |
| You want multi-source research on a topic with a published-quality report | `deep_researcher` | Forces real web search and outputs Markdown with source links |
| You need to parse and extract content from PDF/DOCX/Markdown files | `document_processor` | Covers parsing, text analysis, and format conversion |
| You want to turn a one-line request into a structured JSON requirements doc | `requirements_analyzer` | Strict JSON output with predefined fields and acceptance criteria |
| You want a reference that shows every supported config parameter | `default` | Use as a starting point when authoring your own template |

## How to use it

### 1. Pick a template when creating an agent

On the **Create Agent** page, choose a template at the **Template** step. Nexus-AI pre-fills the form with the template's system prompt, environment parameters, and tool dependencies.

<!-- SCREENSHOT: create-agent-choose-template -->

### 2. Inspect the template

Expand a template card to see:

- **Basics**: name, description, category.
- **Environment config**: `max_tokens`, `temperature`, and `streaming` for `development`, `production`, and `testing`.
- **System prompt**: the behavioural instructions given to the agent.
- **Tool dependencies**: the tools the agent can call.
- **Supported models**: the list of underlying model IDs (the first entry is the default).

<!-- SCREENSHOT: template-detail-view -->

### 3. Customise before saving

A template is only a starting point. You can overwrite any field in the form:

1. Rewrite the system prompt to fit your domain.
2. Add or remove tools — for example, attach an MCP server or one of your generated tools.
3. Adjust temperature, max tokens, or streaming.
4. Swap the default model, e.g. switch from Sonnet to Haiku to save cost.

### 4. Deploy and test

Save the form, click **Create**, then open the chat UI and run a few representative prompts to verify the behaviour matches your expectations.

<!-- SCREENSHOT: chat-with-template-agent -->

## Template catalogue

| Template | Category | Default temperature | Typical use |
| --- | --- | --- | --- |
| `api_integration` | api_integration | 0.3 | REST API calls, auth management, cross-system data sync |
| `content_generator` | content_generation | 0.7 | Articles, reports, marketing copy, creative writing |
| `data_analyzer` | data_analysis | 0.3 | Reading multi-format data, cleaning, statistics, visualisation |
| `deep_researcher` | research_analysis | 0.3 | Multi-source research, Markdown research reports |
| `document_processor` | document_processing | 0.3 | Document parsing, content extraction, format conversion |
| `requirements_analyzer` | analysis | 0.3 | Natural language → structured JSON requirements doc |
| `default` | assistant | 0.3 | Full reference template covering every supported field |

## Key parameters / limits

| Field | Meaning | Notes |
| --- | --- | --- |
| `environments.*.max_tokens` | Max tokens per response | Production is typically 60000; dev and test are smaller to save cost |
| `environments.*.temperature` | Sampling temperature (0–1) | Use 0.3 for deterministic tasks (analysis, integration), 0.7 for creative work |
| `environments.*.streaming` | Stream responses | All templates default to `true` |
| `versions[].status` | Version status | `stable` / `beta` / `deprecated`; the loader uses `latest` by default |
| `metadata.supported_models` | List of supported models | The first entry is the default; you can swap at create time |
| `metadata.tools_dependencies` | Tool dependencies | Reference Strands built-ins, system tools, template tools, generated tools, or other agents by path |
| `metadata.mcp_dependencies` | MCP dependencies (optional) | Reference the name of an MCP server you have configured |
| `metadata.model_provider` | Model provider (optional) | Defaults to `bedrock`; other options include `ollama`, `openai`, `anthropic`, etc. |

::: tip
When no `version` is specified, Nexus-AI picks the one literally named `latest`. If that is missing, it falls back to the highest semantic version.
:::

::: warning
The `default` template is a reference that exposes every configurable parameter. Do not deploy it to production as-is — pick the domain-specific template that matches your use case instead.
:::

## FAQ

**Q: What is the difference between a template and an agent I create?**
A: Templates are read-only blueprints that ship with Nexus-AI (stored under `template_prompts`). Agents you create are saved separately (under `generated_agents_prompts`) and never modify the original template.

**Q: If I rewrite the system prompt after picking a template, does the template change?**
A: No. Templates are always read-only. Your changes only affect the new agent you are creating.

**Q: Can I combine capabilities from multiple templates in one agent?**
A: You can only start from one template, but the create form lets you copy tool dependencies or prompt fragments from other templates into your own version.

**Q: How are the three environments (development / production / testing) selected?**
A: The platform picks the block automatically based on the deployment environment: production deployments use the `production` values, test runs use `testing`, and so on.

**Q: Can I freely edit `supported_models` in a template?**
A: Yes — reorder, add, or remove entries, but make sure at least one model remains that is accessible from your account and region, otherwise the agent cannot start.
