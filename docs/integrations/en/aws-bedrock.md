---
title: AWS Bedrock
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - config/model_catalog.yaml
    - nexus_utils/agent_factory.py
  generated_at: 2026-05-08T22:29:34+00:00
  generated_by: docs-sync v2
---

# AWS Bedrock

## Overview

AWS Bedrock is the default — and only out-of-the-box — model-inference entry point for Nexus-AI. Every agent conversation, tool call, and multimodal input on the platform is routed through Bedrock to reach Claude, Nova, Llama, Mistral, DeepSeek, Qwen, Gemma, GPT OSS, and the other supported families. Without Bedrock the platform will not start; switching to alternate providers (direct OpenAI, direct Anthropic, Gemini, etc.) is an optional extension.

The model catalogue lives in `config/model_catalog.yaml` — the front-end "model picker" dropdown loads from that file. Runtime parameters (region, retries, timeouts, prompt caching) live in the `aws` and `bedrock` sections of `config/default_config.yaml`. This page walks through exactly what to put in those two files and where to look when integration breaks.

## Prerequisites

Before you begin, make sure you have:

- A usable AWS account. The default region is **`us-west-2` (Oregon)** — it has the broadest support for Claude 4.5 / 4.6 and Nova 2.
- Model access approved in `AWS Console → Bedrock → Model access` for every model you plan to use. At minimum, cover the three default model keys (`bedrock.model_id`, `bedrock.small_model_id`, `bedrock.large_model_id`).
- The identity running Nexus-AI services (EC2 Instance Profile or local AWS CLI credentials) holds these Bedrock permissions:
  - `bedrock:InvokeModel`
  - `bedrock:InvokeModelWithResponseStream`
  - `bedrock:ListFoundationModels`
- Outbound HTTPS reachability to `https://bedrock-runtime.&lt;region&gt;.amazonaws.com` from your host or container (corporate networks may need to allow-list it).

::: tip How credentials are refreshed
On EC2 the platform uses the IAM Instance Profile — AWS rotates credentials automatically. Inside Sandbox VMs credentials are refreshed from environment variables periodically. In neither mode do you need to configure long-lived access keys.
:::

## Configuration steps

### 1. Request model access

Go to `AWS Console → Bedrock → Model access → Manage model access` and enable each model you plan to use. A default deployment calls the three Claude models below — request all three up front:

| Role | Model ID |
|------|----------|
| Default model | `us.anthropic.claude-sonnet-4-5-20250929-v1:0` |
| Lite model    | `us.anthropic.claude-haiku-4-5-20251001-v1:0` |
| Pro model     | `us.anthropic.claude-opus-4-5-20251101-v1:0` |

<!-- SCREENSHOT: bedrock-model-access -->

### 2. Fill in the `aws` section

Open `config/default_config.yaml` and set the region in the `aws` section:

```yaml
aws:
  aws_region_name: us-west-2        # Region for every other AWS service
  bedrock_region_name: us-west-2    # Bedrock-only region — can differ from the above
  aws_profile_name: ""              # Leave empty to use the default credential chain
```

::: info Why two region fields
Bedrock availability is independent of other AWS services. For example you can run DynamoDB/Aurora in `ap-northeast-1` while still pointing Bedrock at `us-west-2` for cross-region inference.
:::

### 3. Fill in the `bedrock` section

In the same file, add or modify the `bedrock` section:

```yaml
bedrock:
  # Default model keys that agents reference — feel free to add/rename keys
  # as long as the agent configs refer to the same keys
  model_id: us.anthropic.claude-sonnet-4-5-20250929-v1:0
  small_model_id: us.anthropic.claude-haiku-4-5-20251001-v1:0
  large_model_id: us.anthropic.claude-opus-4-5-20251101-v1:0

  # boto3 connection tuning
  connect_config:
    connect_timeout: 10    # seconds — TCP connect timeout
    read_timeout: 300      # seconds — model response timeout
    retries:
      max_attempts: 5      # max attempts (including the first)
      mode: adaptive       # legacy / standard / adaptive

  # Prompt Caching (optional)
  prompt_caching:
    enabled: true
    cache_system_prompt: true
    cache_tools: true
```

::: warning Tuning `read_timeout`
For streaming and long-running reasoning tasks, `300` seconds is a safe floor. Too low a value causes `Read timeout` exceptions during Opus deep-reasoning runs or long document summarisation.
:::

### 4. Pick your model IDs (optional)

The built-in catalogue lives in `config/model_catalog.yaml`; the front-end model picker loads from it. Main models by provider:

| Provider | Flagship models | Vision | Tier |
|----------|----------------|--------|------|
| Anthropic | Claude Opus 4.6 / 4.5, Sonnet 4.6 / 4.5, Haiku 4.5 | ✔ | pro / standard / lite |
| Amazon    | Nova Pro, Nova 2 Lite, Nova Lite, Nova Micro | ✔ (except Micro) | standard / lite |
| Meta      | Llama 4 Maverick 17B, Llama 3.3 70B, Llama 3.1 405B/70B/8B | Llama 4 only | pro / standard / lite |
| Mistral   | Mistral Large 3, Pixtral Large, Devstral 2, Ministral 3 | partial | pro / standard / lite |
| DeepSeek  | DeepSeek V3.2, V3 | — | standard |
| Qwen      | Qwen3 235B, Qwen3 VL 235B, Qwen3 Coder 480B/30B | Qwen3 VL | pro / standard / lite |
| Google    | Gemma 3 27B / 12B / 4B | ✔ | standard / lite |
| NVIDIA    | Nemotron Super 120B, Nemotron Nano 30B/12B | Nano 12B only | pro / standard / lite |
| OpenAI    | GPT OSS 120B / 20B | — | pro / standard |
| Moonshot  | Kimi K2 Thinking, Kimi K2.5 | K2.5 only | pro / standard |
| MiniMax   | MiniMax M2.5 / M2.1 | — | standard |
| Writer    | Palmyra X5 / X4 | — | standard |
| Z.AI      | GLM 5, GLM 4.7, GLM 4.7 Flash | — | standard / lite |

IDs prefixed with `global.` are Global Inference endpoints (cross-region routing). IDs with no prefix or a `us.` prefix are single-region or US-cross-region endpoints. If a `global.*` model isn't available in your region, try the matching `us.*` variant first.

::: tip Customising the catalogue
If your account has approved access to a model that isn't listed in `config/model_catalog.yaml`, just edit the file. The front-end picker has a refresh button — no service restart required.
:::

### 5. Prompt Caching (optional but recommended)

Bedrock Prompt Caching stores your system prompt and tool definitions for five minutes, cutting cost significantly:

| Event | Rate |
|-------|------|
| First write into cache | 1.25× standard price |
| Cache hit within 5 minutes | 0.1× standard price (90% off) |

Model families that currently support Prompt Caching:

- Anthropic Claude 3.5 / 4 / 4.5 (Sonnet / Opus / Haiku)
- Amazon Nova (Pro / Lite / Micro)

For any other family (Titan / Llama / Mistral / Cohere / AI21), the platform transparently drops the caching arguments even with `prompt_caching.enabled: true` — you won't see an error, just no discount.

### 6. Restart services

Apply the config changes:

```bash
./nexus-cli service restart
```

## Verification

Three checks, from shallow to deep.

### Step 1 — CLI-level check

Confirm the current identity can list Bedrock models:

```bash
aws bedrock list-foundation-models --region us-west-2 | head -40
```

Seeing hundreds of model entries means IAM and region are both correct. If it returns `AccessDenied`, revisit the Prerequisites section.

### Step 2 — service-level check

```bash
./nexus-cli service status
```

API, Worker and Web should all show `running`. If the API fails to start, tail the log:

```bash
./nexus-cli service logs --api -f
```

Search for `bedrock`, `boto`, or `Could not connect`.

### Step 3 — end-to-end agent check

Run a built-in agent to exercise the full inference path:

```bash
source .venv/bin/activate
python agents/system_agents/magician.py -i "Hello"
```

A text response confirms Bedrock + Agent Factory + tool loading are all working.

<!-- SCREENSHOT: bedrock-agent-response -->

## Troubleshooting

| Symptom | Likely cause | What to try |
|---------|--------------|-------------|
| Startup log reports `AccessDeniedException` | IAM identity is missing `bedrock:InvokeModel` or similar permissions | Add the missing actions per the Prerequisites checklist |
| `Could not connect to the endpoint URL "https://bedrock-runtime.xxx.amazonaws.com"` | `aws.bedrock_region_name` is wrong, or Bedrock isn't enabled there | Switch back to `us-west-2`, or request model access in the target region |
| `ValidationException: The provided model identifier is invalid` | Typo in the model ID, or the model isn't offered in the current region | Look up the correct ID in `Bedrock → Model catalog` and confirm regional availability |
| `ThrottlingException: Too many requests` | Hitting account-level QPS / TPM limits | Request a quota increase, or set `bedrock.connect_config.retries.mode: adaptive` so the SDK backs off automatically |
| `Read timeout on endpoint URL` on long reasoning runs | `read_timeout` is too low | Raise `bedrock.connect_config.read_timeout` to at least 300 seconds |
| After switching to Haiku 4.5, `ModelStreamErrorException` appears | The model doesn't support streaming tool calls | No config change needed — the platform silently falls back to non-streaming. You can also disable streaming explicitly in the agent config |
| Prompt Caching never hits | The chosen model family is outside Claude / Nova | Switch to a Claude or Nova model; other families do not trigger caching even with `enabled: true` |
| You requested access but still see `access to the model isn't authorized` | The Model access request isn't in `Access granted` state | Go back to `Bedrock → Model access` and confirm the status |
| Cross-region call returns `inference profile not found` | You referenced a `global.*` ID but your account hasn't enabled Global Inference | Fall back to the matching `us.*` ID |
| Bedrock calls from inside a Sandbox VM fail with expired credentials | VM credential rotation failed | Inspect the VM credential refresh log and restart the Sandbox node if needed |

::: info Where to start digging
Always investigate in this order: does AWS CLI work → do Nexus-AI services start → does the agent respond. Do not suspect agent or tool configuration until the first two are green.
:::
