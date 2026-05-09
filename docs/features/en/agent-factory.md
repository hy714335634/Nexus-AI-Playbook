---
title: Agent Factory
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - nexus_utils/agent_factory.py
    - nexus_utils/safe_agent_factory.py
  generated_at: 2026-05-08T15:27:05+00:00
  generated_by: docs-sync v2
---

# Agent Factory

## What it is

Agent Factory is the assembly line inside Nexus-AI that turns "prompt template + model + tools" into a runnable agent. Whenever you click **Create Agent**, add an agent to an orchestration, or spin up a batch of agents, the factory is what pulls the template, picks the model, binds the tools, and runs a quick health check before handing the agent back to you.

## When to use it

| Scenario | What Agent Factory does for you |
| --- | --- |
| Create a new agent from a template | Loads the template config (model, temperature, tool list, system prompt) and returns a ready-to-run instance |
| Switch the model behind an agent | Swaps between Bedrock / OpenAI / Anthropic / Gemini / Mistral / Ollama / LlamaAPI / LiteLLM without rewriting the template |
| Run a batch of evaluations or jobs | Builds many agents from one config list; failures are flagged individually and don't block the rest |
| Share an agent without "works on my machine" issues | Validates dependencies before creation and auto-repairs missing pieces |
| Need a safety net for a critical flow | Falls back to a designated backup agent if the primary one fails to build |

## How to use it

### Option 1 — Create an agent from the UI

<!-- SCREENSHOT: agent-factory-create-from-ui -->

1. Go to **Agents** and click `Create Agent`.
2. Pick a prompt template (or duplicate an existing one and tweak it).
3. Choose a model provider and a specific model (see "Key parameters / limits" below).
4. Select the tools to bind: built-in tools, system tools, template tools, or generated tools you've uploaded to the workspace.
5. On submit, Agent Factory will:
   - Validate dependencies (model reachable, tools importable, prompt exists);
   - Auto-repair anything missing (for example, syncing tool scripts from the artifact store);
   - Run a short self-check;
   - Return the result — on success, the agent shows up in your list.

### Option 2 — Validated single-agent creation

When you create via the **Advanced** entry or the API, the validated flow runs by default:

1. Give the agent a name (or a template-relative path).
2. Pick an environment: `production` / `development` / `test` / etc. (drives temperature, max tokens, streaming).
3. Pick a version (defaults to `latest`).
4. Decide whether to enable **auto-fix dependencies** (on by default).
5. Submit. The platform runs: dependency check → dependency repair (optional) → agent build → self-check → return.

::: tip What auto-fix actually does
If the template or tool you referenced is registered in the platform but not yet present in the current environment, Agent Factory syncs the missing script from the artifact store. You don't have to copy anything by hand.
:::

### Option 3 — Batch creation

<!-- SCREENSHOT: agent-factory-batch-create -->

1. Prepare a list of agent configs (each entry at minimum has the agent name; optionally environment, version, model, state, etc.).
2. In the **Batch Create** view, upload or paste the config list.
3. Choose whether to continue on error:
   - Continue: skip failures and keep processing the rest;
   - Abort: stop on the first failure to make root-causing easier.
4. After submit, review the summary: total, succeeded, failed, and per-agent status.

### Option 4 — Primary + fallback agent

For critical flows, pin both a primary and a backup:

1. Enter the primary agent name in the **Advanced** section of the create form.
2. Fill in the **Fallback agent** field with the backup target.
3. On submit, if the primary fails to build, Agent Factory automatically tries the fallback and keeps the primary's error message in the response for debugging.

### Option 5 — Check agent health

<!-- SCREENSHOT: agent-factory-health-status -->

For any created agent, the **Health** card on its detail page shows:

- Agent name
- Model ID, max tokens, temperature
- Number of tools bound
- Length of the system prompt
- Result of the last self-check (pass/fail, plus response length)

## Key parameters / limits

| Parameter | Meaning | Default |
| --- | --- | --- |
| Model provider | `bedrock`, `ollama`, `openai`, `anthropic`, `litellm`, `llamaapi`, `mistral`, `gemini` | `bedrock` |
| Environment (`env`) | Controls temperature, max tokens, streaming | `production` |
| Version (`version`) | Prompt template version to use | `latest` |
| Model ID (`model_id`) | Specific model within the chosen provider | `default` |
| Auto-fix dependencies | Allow the platform to sync missing tool scripts from the artifact store | On |
| Self-check | Send a test message after creation to confirm the agent responds | On |

| Limit | Detail |
| --- | --- |
| Prompt caching | Active only for Claude 3.5 / 4 / 4.5 (Sonnet, Opus, Haiku) and Amazon Nova (Pro, Lite, Micro); skipped on other model families |
| Cache pricing | First write billed at 1.25× standard; cache hits within 5 minutes billed at 0.1× (90% discount) |
| Third-party provider dependencies | Ollama / OpenAI / Anthropic / LiteLLM / LlamaAPI / Mistral / Gemini require the matching extension installed in the environment; otherwise creation fails with a "missing dependency" error |
| Tool sync | Auto-sync fires only when the tool path follows the platform convention (for example, `generated_tools/&lt;dir&gt;/&lt;script&gt;/&lt;function&gt;`) |
| Credential refresh | A fresh credential session is created each time a Bedrock model is built, so long-lived sessions keep working |
| Self-check failure handling | A failed self-check does not block the agent from being returned; it's surfaced as a warning in the health panel |

## FAQ

**Q1: I get "unsupported model provider" when creating — what now?**
A: Make sure the provider is one of: `bedrock`, `ollama`, `openai`, `anthropic`, `litellm`, `llamaapi`, `mistral`, `gemini`. The name is case-insensitive but must be in that list.

**Q2: I picked OpenAI and creation failed with a missing-dependency error.**
A: Non-Bedrock providers need their extension installed — for example, `strands-agents[openai]`. Ask your admin or enable the extension in the workspace settings.

**Q3: Why don't I see a prompt-caching discount?**
A: Caching is only turned on for Claude and Amazon Nova models. Other families (Titan, Llama, Mistral, Cohere, AI21) never trigger the caching path, so no discount applies.

**Q4: What exactly does "auto-fix dependencies" fix? Could it corrupt my config?**
A: It does two things only — (1) pull tool scripts from the artifact store that are registered in the template but missing locally, and (2) re-run dependency validation. It will not modify your prompt template, change your chosen model, or delete any existing config. If you'd rather stay hands-on, turn auto-fix off at creation time and repair the dependencies yourself before retrying.

**Q5: One agent in my batch failed — are the others still usable?**
A: Yes. In the default mode, failed agents are just tagged as "failed" in the summary, while successful ones are returned and ready to use. Switch to "abort on error" if you'd rather stop after the first failure to debug.
