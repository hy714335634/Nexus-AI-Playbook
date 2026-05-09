---
title: Model Catalog
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - config/model_catalog.yaml
    - nexus_utils/agent_factory.py
  generated_at: 2026-05-09T01:36:41+00:00
  generated_by: docs-sync v2
---

# Model Catalog

The Bedrock language-model catalog used by Nexus-AI. It defines every model entry that agents can invoke. Every entry has been validated through a real Strands Agent conversation.

## Overview

| Item | Value |
|------|-------|
| File location | `config/model_catalog.yaml` |
| Load timing | Loaded at app startup; re-read when the UI **Refresh** button is clicked |
| Last validated | 2026-04-29 |
| Total entries | 63 models |
| Providers | 13 |
| Tool calling | Supported by all entries (models without streaming tool use are auto-downgraded to non-streaming) |

::: info Manual edits
`model_catalog.yaml` is hand-editable: add or remove entries and click the UI refresh button — no service restart needed.
:::

## Top-level structure

```yaml
model_catalog:
  providers:
    - name: <provider name>
      models:
        - {id: "...", name: "...", tier: ..., is_global: ..., supports_vision: ...}
```

## Model fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | required | Bedrock model ID or inference-profile ID; passed to `BedrockModel(model_id=...)` |
| `name` | string | required | Display name shown in the UI |
| `tier` | enum | required | Price / capability tier: `pro` / `standard` / `lite` (see table below) |
| `is_global` | bool | required | `true` for a global cross-region inference profile; `false` for a regional profile or a direct model ID |
| `supports_vision` | bool | required | Whether the model accepts image / document input (from Bedrock `inputModalities`) |

## Tier meaning

| tier | Positioning | Typical use |
|------|-------------|-------------|
| `pro` | Flagship capability | Complex reasoning, long context, high-fidelity code, top-tier multimodal |
| `standard` | Main workhorse | Everyday chat, routine code, structured output, most agent scenarios |
| `lite` | Low-cost tier | High-concurrency, low-latency, summarization / routing / classification |

## Provider overview

| Provider | Models | Has global profile | Has vision models |
|----------|-------:|:------------------:|:-----------------:|
| Anthropic | 12 | Yes | Yes |
| Amazon | 5 | Yes | Yes |
| Meta | 10 | No | Yes |
| Mistral | 11 | No | Yes |
| DeepSeek | 2 | No | No |
| Qwen | 6 | No | Yes |
| Google | 3 | No | Yes |
| NVIDIA | 3 | No | Yes |
| OpenAI | 2 | No | No |
| Moonshot | 2 | No | Yes |
| MiniMax | 2 | No | No |
| Writer | 2 | No | No |
| Z.AI | 3 | No | No |

## Anthropic

| id | name | tier | is_global | supports_vision |
|----|------|------|:---------:|:---------------:|
| `global.anthropic.claude-opus-4-6-v1` | Claude Opus 4.6 | pro | ✓ | ✓ |
| `global.anthropic.claude-opus-4-5-20251101-v1:0` | Claude Opus 4.5 | pro | ✓ | ✓ |
| `global.anthropic.claude-sonnet-4-6` | Claude Sonnet 4.6 | standard | ✓ | ✓ |
| `global.anthropic.claude-sonnet-4-5-20250929-v1:0` | Claude Sonnet 4.5 | standard | ✓ | ✓ |
| `global.anthropic.claude-sonnet-4-20250514-v1:0` | Claude Sonnet 4 | standard | ✓ | ✓ |
| `global.anthropic.claude-haiku-4-5-20251001-v1:0` | Claude Haiku 4.5 | lite | ✓ | ✓ |
| `us.anthropic.claude-opus-4-6-v1` | Claude Opus 4.6 (us) | pro | ✗ | ✓ |
| `us.anthropic.claude-opus-4-5-20251101-v1:0` | Claude Opus 4.5 (us) | pro | ✗ | ✓ |
| `us.anthropic.claude-sonnet-4-6` | Claude Sonnet 4.6 (us) | standard | ✗ | ✓ |
| `us.anthropic.claude-sonnet-4-20250514-v1:0` | Claude Sonnet 4 (us) | standard | ✗ | ✓ |
| `us.anthropic.claude-3-7-sonnet-20250219-v1:0` | Claude 3.7 Sonnet (us) | standard | ✗ | ✓ |
| `us.anthropic.claude-haiku-4-5-20251001-v1:0` | Claude Haiku 4.5 (us) | lite | ✗ | ✓ |

## Amazon

| id | name | tier | is_global | supports_vision |
|----|------|------|:---------:|:---------------:|
| `global.amazon.nova-2-lite-v1:0` | Nova 2 Lite | lite | ✓ | ✓ |
| `us.amazon.nova-pro-v1:0` | Nova Pro (us) | standard | ✗ | ✓ |
| `us.amazon.nova-2-lite-v1:0` | Nova 2 Lite (us) | lite | ✗ | ✓ |
| `us.amazon.nova-lite-v1:0` | Nova Lite (us) | lite | ✗ | ✓ |
| `us.amazon.nova-micro-v1:0` | Nova Micro (us) | lite | ✗ | ✗ |

## Meta

| id | name | tier | is_global | supports_vision |
|----|------|------|:---------:|:---------------:|
| `us.meta.llama4-maverick-17b-instruct-v1:0` | Llama 4 Maverick 17B | standard | ✗ | ✓ |
| `us.meta.llama4-scout-17b-instruct-v1:0` | Llama 4 Scout 17B | standard | ✗ | ✓ |
| `us.meta.llama3-3-70b-instruct-v1:0` | Llama 3.3 70B | pro | ✗ | ✗ |
| `meta.llama3-1-405b-instruct-v1:0` | Llama 3.1 405B | pro | ✗ | ✗ |
| `meta.llama3-1-70b-instruct-v1:0` | Llama 3.1 70B | pro | ✗ | ✗ |
| `us.meta.llama3-1-70b-instruct-v1:0` | Llama 3.1 70B (us) | pro | ✗ | ✗ |
| `meta.llama3-70b-instruct-v1:0` | Llama 3 70B | pro | ✗ | ✗ |
| `meta.llama3-1-8b-instruct-v1:0` | Llama 3.1 8B | lite | ✗ | ✗ |
| `us.meta.llama3-1-8b-instruct-v1:0` | Llama 3.1 8B (us) | lite | ✗ | ✗ |
| `meta.llama3-8b-instruct-v1:0` | Llama 3 8B | lite | ✗ | ✗ |

## Mistral

| id | name | tier | is_global | supports_vision |
|----|------|------|:---------:|:---------------:|
| `us.mistral.pixtral-large-2502-v1:0` | Pixtral Large (us) | pro | ✗ | ✓ |
| `mistral.mistral-large-3-675b-instruct` | Mistral Large 3 (675B) | pro | ✗ | ✓ |
| `mistral.mistral-large-2407-v1:0` | Mistral Large 2407 | pro | ✗ | ✗ |
| `mistral.mistral-large-2402-v1:0` | Mistral Large 2402 | pro | ✗ | ✗ |
| `mistral.devstral-2-123b` | Devstral 2 (123B) | standard | ✗ | ✗ |
| `mistral.magistral-small-2509` | Magistral Small | standard | ✗ | ✓ |
| `mistral.voxtral-small-24b-2507` | Voxtral Small (24B) | standard | ✗ | ✗ |
| `mistral.ministral-3-14b-instruct` | Ministral 3 (14B) | lite | ✗ | ✓ |
| `mistral.ministral-3-8b-instruct` | Ministral 3 (8B) | lite | ✗ | ✓ |
| `mistral.ministral-3-3b-instruct` | Ministral 3 (3B) | lite | ✗ | ✓ |
| `mistral.voxtral-mini-3b-2507` | Voxtral Mini (3B) | lite | ✗ | ✗ |

## DeepSeek

| id | name | tier | is_global | supports_vision |
|----|------|------|:---------:|:---------------:|
| `deepseek.v3.2` | DeepSeek V3.2 | standard | ✗ | ✗ |
| `deepseek.v3-v1:0` | DeepSeek V3 | standard | ✗ | ✗ |

## Qwen

| id | name | tier | is_global | supports_vision |
|----|------|------|:---------:|:---------------:|
| `qwen.qwen3-coder-480b-a35b-v1:0` | Qwen3 Coder 480B | pro | ✗ | ✗ |
| `qwen.qwen3-235b-a22b-2507-v1:0` | Qwen3 235B | pro | ✗ | ✗ |
| `qwen.qwen3-next-80b-a3b` | Qwen3 Next 80B | standard | ✗ | ✗ |
| `qwen.qwen3-vl-235b-a22b` | Qwen3 VL 235B | standard | ✗ | ✓ |
| `qwen.qwen3-32b-v1:0` | Qwen3 32B | standard | ✗ | ✗ |
| `qwen.qwen3-coder-30b-a3b-v1:0` | Qwen3 Coder 30B | lite | ✗ | ✗ |

## Google

| id | name | tier | is_global | supports_vision |
|----|------|------|:---------:|:---------------:|
| `google.gemma-3-27b-it` | Gemma 3 27B | standard | ✗ | ✓ |
| `google.gemma-3-12b-it` | Gemma 3 12B | standard | ✗ | ✓ |
| `google.gemma-3-4b-it` | Gemma 3 4B | lite | ✗ | ✓ |

## NVIDIA

| id | name | tier | is_global | supports_vision |
|----|------|------|:---------:|:---------------:|
| `nvidia.nemotron-super-3-120b` | Nemotron Super 120B | pro | ✗ | ✗ |
| `nvidia.nemotron-nano-3-30b` | Nemotron Nano 30B | standard | ✗ | ✗ |
| `nvidia.nemotron-nano-12b-v2` | Nemotron Nano 12B | lite | ✗ | ✓ |

## OpenAI

| id | name | tier | is_global | supports_vision |
|----|------|------|:---------:|:---------------:|
| `openai.gpt-oss-120b-1:0` | GPT OSS 120B | pro | ✗ | ✗ |
| `openai.gpt-oss-20b-1:0` | GPT OSS 20B | standard | ✗ | ✗ |

## Moonshot

| id | name | tier | is_global | supports_vision |
|----|------|------|:---------:|:---------------:|
| `moonshot.kimi-k2-thinking` | Kimi K2 Thinking | pro | ✗ | ✗ |
| `moonshotai.kimi-k2.5` | Kimi K2.5 | standard | ✗ | ✓ |

## MiniMax

| id | name | tier | is_global | supports_vision |
|----|------|------|:---------:|:---------------:|
| `minimax.minimax-m2.5` | MiniMax M2.5 | standard | ✗ | ✗ |
| `minimax.minimax-m2.1` | MiniMax M2.1 | standard | ✗ | ✗ |

## Writer

| id | name | tier | is_global | supports_vision |
|----|------|------|:---------:|:---------------:|
| `us.writer.palmyra-x5-v1:0` | Palmyra X5 | standard | ✗ | ✗ |
| `us.writer.palmyra-x4-v1:0` | Palmyra X4 | standard | ✗ | ✗ |

## Z.AI

| id | name | tier | is_global | supports_vision |
|----|------|------|:---------:|:---------------:|
| `zai.glm-5` | GLM 5 | standard | ✗ | ✗ |
| `zai.glm-4.7` | GLM 4.7 | standard | ✗ | ✗ |
| `zai.glm-4.7-flash` | GLM 4.7 Flash | lite | ✗ | ✗ |

## ID prefix convention

| Prefix | Meaning | Example |
|--------|---------|---------|
| `global.` | Global cross-region inference profile; Bedrock routes across multiple regions automatically | `global.anthropic.claude-opus-4-6-v1` |
| `us.` | US regional inference profile; routes only across US regions | `us.anthropic.claude-opus-4-6-v1` |
| `&lt;provider&gt;.` (no region prefix) | Direct model ID, available only in the single region that hosts it | `mistral.mistral-large-2407-v1:0` |

::: tip What `is_global` gives you
When `is_global: true`, requests load-balance across regions — usually more stable and less likely to hit quota limits. When `is_global: false`, calls are pinned to fixed regions (mostly US) — slightly lower latency but bound by single-region quotas.
:::

## Capability matrix

Model counts by tier and vision capability:

| tier | Vision | No vision | Subtotal |
|------|-------:|----------:|---------:|
| pro | 6 | 12 | 18 |
| standard | 10 | 18 | 28 |
| lite | 8 | 9 | 17 |
| **Total** | **24** | **39** | **63** |

## Prompt caching

Only specific model families support Bedrock prompt caching; others are silently skipped even when caching is enabled in configuration:

| Family | Supports caching |
|--------|:----------------:|
| Anthropic Claude (3.5 / 4 / 4.5) | ✓ |
| Amazon Nova (Pro / Lite / Micro) | ✓ |
| Titan | ✗ |
| Llama | ✗ |
| Mistral | ✗ |
| Cohere | ✗ |
| AI21 | ✗ |
| Others (DeepSeek / Qwen / Gemma / Nemotron / GPT OSS / Kimi / MiniMax / Palmyra / GLM) | ✗ |

Eligibility is decided by substring match on the model id: `claude`, `anthropic`, `nova`, `amazon.nova`.

**Pricing**: the first write is charged at 1.25× base rate; hits within the 5-minute window are charged at 0.1× (90% off).

## Tool calling and streaming

- **All 63 models support tool calling** and can be used in agent scenarios.
- Models without streaming tool support are automatically downgraded to non-streaming mode — callers do not need to handle this.

## Full example YAML

A minimal runnable `model_catalog.yaml` (one provider, two models) is shown below; see the provider sections above for the complete catalog.

```yaml
# Bedrock-available language models (validated via real Strands Agent conversations)
# Hand-editable; reload via the frontend Refresh button
# Last validated: 2026-04-29
#
# supports_vision: whether the model accepts image/document input (from Bedrock inputModalities)
# All models support tool calling (non-streaming-tool models are auto-downgraded)

model_catalog:
  providers:
    - name: Anthropic
      models:
        - {id: "global.anthropic.claude-opus-4-6-v1", name: "Claude Opus 4.6", tier: pro, is_global: true, supports_vision: true}
        - {id: "global.anthropic.claude-haiku-4-5-20251001-v1:0", name: "Claude Haiku 4.5", tier: lite, is_global: true, supports_vision: true}

    - name: Amazon
      models:
        - {id: "us.amazon.nova-pro-v1:0", name: "Nova Pro (us)", tier: standard, is_global: false, supports_vision: true}
        - {id: "us.amazon.nova-micro-v1:0", name: "Nova Micro (us)", tier: lite, is_global: false, supports_vision: false}
```

## Modifying the catalog

1. Edit `config/model_catalog.yaml`, adding or removing entries following the YAML structure.
2. Keep all five fields present: `id` / `name` / `tier` / `is_global` / `supports_vision`.
3. Click **Refresh models** in the UI — the change takes effect immediately, no Nexus-AI restart required.
4. Before adding an entry, verify the model ID with the Bedrock Console or `aws bedrock list-foundation-models`.

::: warning Exact ID spelling
If `model_id` does not match a real Bedrock ID, agent calls raise `ValidationException`. Watch for version suffixes (e.g. `-v1:0`) and date segments when copying.
:::

## Notes

- Entry order is the display order in the UI dropdown; within a provider, entries are usually arranged from higher tier to lower tier.
- When the same model is listed with both a global and a us entry, both appear in the UI — pick global for stability, us for lower latency.
- This catalog only covers models reached through AWS Bedrock. For direct Ollama / OpenAI / Anthropic API / LiteLLM / Mistral / Gemini / LlamaAPI integrations, see other configuration sections.
