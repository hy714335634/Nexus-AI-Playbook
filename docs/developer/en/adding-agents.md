---
title: Adding Agents
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - agents/template_agents/**
    - config/model_catalog.yaml
    - nexus_utils/agent_factory.py
    - nexus_utils/agent_validation.py
    - nexus_utils/safe_agent_factory.py
  generated_at: 2026-05-09T00:23:13+00:00
  generated_by: docs-sync v2
---

# Adding Agents

## Overview

Agents in Nexus-AI are built around the **Strands SDK** `Agent` class. Each agent is defined by three things:

1. **A prompt template** (`prompts/template_prompts/&lt;name&gt;` or `prompts/generated_agents_prompts/&lt;ns&gt;/&lt;name&gt;`) — carries the system prompt, model tier, per-environment `max_tokens` / `temperature` / `streaming`, and a `tools_dependencies` declaration.
2. **A runner script** (`agents/template_agents/single_agent/*.py` or `agents/generated_agents/&lt;ns&gt;/*.py`) — calls `create_agent_from_prompt_template(...)` to instantiate the agent, exposes a `BedrockAgentCoreApp` entrypoint, and provides a CLI / interactive shell.
3. **A catalog registration** (`agents/template_agents/agent_templates_config.yaml`) — adds the template to the discoverable list consumed by platform tooling.

All agent construction goes through one factory: `nexus_utils.agent_factory.create_agent_from_prompt_template`. It loads the prompt template, resolves `tools_dependencies`, constructs the Bedrock (or other provider) model, injects tools, and returns a `strands.Agent` instance. A validated wrapper with dependency auto-repair lives in `nexus_utils.safe_agent_factory`. Multi-agent collaboration uses either Strands' `Swarm` (see `agents/template_agents/multi_agent/tech_doc_swarm.py`) or explicit orchestration of multiple agents inside a single host class (see `agents/template_agents/multi_agent/stock_analysis_agent.py`).

This document covers **which files change to add a new agent**, **full signatures of the factory and validation functions**, the **model provider registry**, the **tool path resolution rules**, and a **comparison of the two multi-agent orchestration patterns**.

## File Layout

| Path | Responsibility | Dependencies |
|------|----------------|--------------|
| `agents/template_agents/agent_templates_config.yaml` | Template manifest; declares `name` / `description` / `tools_dependencies` / `path` / `prompt_template` / `tags` per template | — |
| `agents/template_agents/single_agent/*.py` | Single-agent template scripts | `nexus_utils.agent_factory`, `bedrock_agentcore.runtime` |
| `agents/template_agents/multi_agent/*.py` | Multi-agent orchestration scripts | above + `strands.multiagent.Swarm` (when used) |
| `agents/generated_agents/&lt;ns&gt;/*.py` | Auto-generated agents (namespaced) | same as single-agent template |
| `nexus_utils/agent_factory.py` | Core factory: model construction, tool resolution, agent assembly | `strands`, `boto3`, `nexus_utils.config_loader`, `nexus_utils.prompts_manager` |
| `nexus_utils/safe_agent_factory.py` | Wrapper with dependency validation and auto-repair | `nexus_utils.agent_factory`, `nexus_utils.agent_validation` |
| `nexus_utils/agent_validation.py` | Tool dependency validation, fix recommendations, stub generation | `nexus_utils.prompts_manager`, `nexus_utils.agent_factory` |
| `config/model_catalog.yaml` | Bedrock model catalog (consumed by the frontend refresh button) | — |
| `prompts/template_prompts/&lt;name&gt;/` | Single-agent prompt template + environment config | Loaded by `prompts_manager` |
| `prompts/generated_agents_prompts/&lt;ns&gt;/&lt;name&gt;/` | Multi-agent / generated-agent prompt templates | same |

## Shipped Templates (from `agent_templates_config.yaml`)

| Template key | Type | Script path | Prompt path |
|--------------|------|-------------|-------------|
| `document_processor_agent` | single_agent | `agents/template_agents/single_agent/document_processor_agent.py` | `prompts/template_prompts/document_processor_agent` |
| `data_analyzer_agent` | single_agent | `agents/template_agents/single_agent/data_analyzer_agent.py` | `prompts/template_prompts/data_analyzer_agent` |
| `api_integration_agent` | single_agent | `agents/template_agents/single_agent/api_integration_agent.py` | `prompts/template_prompts/api_integration_agent` |
| `content_generator_agent` | single_agent | `agents/template_agents/single_agent/content_generator_agent.py` | `prompts/template_prompts/content_generator_agent` |
| `deep_research_agent` | single_agent | `agents/template_agents/single_agent/deep_research_agent.py` | `prompts/template_prompts/deep_research_agent` |
| `html2pptx_agent` | single_agent | `agents/template_agents/single_agent/html2pptx_agent.py` | `prompts/generated_agents_prompts/html2pptx/html2pptx_agent` |
| `aws_pricing_agent` | single_agent | `agents/generated_agents/aws_pricing_agent/aws_pricing_agent.py` | `prompts/generated_agents_prompts/aws_pricing_agent/aws_pricing_agent` |
| `medical_document_translation_agent` | single_agent | `agents/generated_agents/medical_document_translation_agent/medical_translator.py` | `prompts/generated_agents_prompts/medical_document_translation_agent/medical_translator` |
| `tech_doc_multi_agent_system` | multi_agent (Swarm) | `agents/generated_agents/tech_doc_multi_agent_system/tech_doc_swarm.py` | 3 sub-prompts (`document_writer_agent` / `document_reviewer_agent` / `content_processor_agent`) |
| `stock_analysis_agent` | multi_agent (explicit) | `agents/generated_agents/stock_analysis_agent/...` | 7 sub-prompts (coordinator/data_collector/valuation/prediction/risk_assessment/benchmark/report_generator) |

Built-in single-agent scripts also include `agents/template_agents/single_agent/default_agent.py` (`template_prompts/default`) as the minimal boilerplate.

## Core Factory Function

### `create_agent_from_prompt_template` (nexus_utils/agent_factory.py)

**The unified entry point for every agent.** Produces a `strands.Agent` from a prompt template. Effective call signature (derived from the forwarded arguments in `safe_agent_factory`):

```python
from nexus_utils.agent_factory import create_agent_from_prompt_template

agent = create_agent_from_prompt_template(
    agent_name="template_prompts/api_integration_agent",
    env="production",        # development / production / testing
    version="latest",        # prompt template version
    model_id="default",      # key into the bedrock config
    enable_logging=True,
    state=None,              # optional: injected into Agent.state
    session_manager=None,    # optional: session manager
)
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `agent_name` | `str` | — | prompt template relative path or template name |
| `env` | `str` | `"production"` | environment key (maps to the template's `get_environment_config`) |
| `version` | `str` | `"latest"` | prompt template version |
| `model_id` | `str` | `"default"` | model key; `get_bedrock_model` resolves it via the `bedrock` config |
| `enable_logging` | `bool` | `False` | toggles agent call logging |
| `state` | `Optional[Dict[str, Any]]` | `None` | injected into `Agent.state` |
| `session_manager` | `Optional[Any]` | `None` | session manager (history persistence) |
| `**agent_params` | — | — | forwarded to the `strands.Agent` constructor |

### `get_bedrock_model` (nexus_utils/agent_factory.py:2837)

```python
def get_bedrock_model(model_id="model_id", agent_name="template", env="production"):
    resolved_id = config.get_bedrock_config().get(model_id)
    bedrock_model = BedrockModel(
        model_id=resolved_id,
        max_tokens=prompts_manager.get_agent(agent_name).get_environment_config(env).max_tokens,
        temperature=...,
        streaming=prompts_manager.get_agent(agent_name).get_environment_config(env).streaming,
        boto_session=_fresh_boto_session(),
        boto_client_config=boto_config,
        **_get_cache_kwargs(resolved_id),
    )
    return bedrock_model
```

- `model_id` is a key under `config.bedrock`; it resolves to a full Bedrock ID such as `us.anthropic.claude-sonnet-4-20250514-v1:0`.
- `max_tokens`, `temperature`, and `streaming` come from the template's `get_environment_config(env)`.
- `boto_client_config` is built from `config.bedrock.connect_config` (retries / timeouts).
- `_fresh_boto_session()` returns a new boto3 session per call so sandbox VM credential rotation is honored.
- Prompt caching is injected through `_get_cache_kwargs` (see below).

### `_get_cache_kwargs` (nexus_utils/agent_factory.py:2807)

Reads `config.bedrock.prompt_caching`: when enabled and the model ID contains `claude` / `anthropic` / `nova`, injects `cache_prompt="default"` and `cache_tools="default"`. Other model families (Titan / Llama / Mistral / Cohere / AI21) get an empty dict to avoid Strands SDK errors. Billing note (per code comment): first write is 1.25× standard, hits within 5 minutes are 0.1× (90% off).

### `create_model_for_provider` (nexus_utils/agent_factory.py:2863)

Generic factory that picks a model class from the provider registry.

```python
def create_model_for_provider(provider: str, model_id: str,
                              model_config: Optional[Dict[str, Any]] = None,
                              max_tokens: int = None,
                              temperature: float = None) -> Any:
```

Raises `ValueError` (unknown provider) or `ImportError` (missing optional package).

### `MODEL_PROVIDER_REGISTRY` (nexus_utils/agent_factory.py:2852)

| provider | module path | class | pip package |
|----------|-------------|-------|-------------|
| `ollama` | `strands.models.ollama` | `OllamaModel` | `strands-agents[ollama]` |
| `openai` | `strands.models.openai` | `OpenAIModel` | `strands-agents[openai]` |
| `anthropic` | `strands.models.anthropic` | `AnthropicModel` | `strands-agents[anthropic]` |
| `litellm` | `strands.models.litellm` | `LiteLLMModel` | `strands-agents[litellm]` |
| `llamaapi` | `strands.models.llamaapi` | `LlamaAPIModel` | `strands-agents[llamaapi]` |
| `mistral` | `strands.models.mistral` | `MistralModel` | `strands-agents[mistral]` |
| `gemini` | `strands.models.gemini` | `GeminiModel` | `strands-agents[gemini]` |

`bedrock` bypasses this registry and goes through `get_bedrock_model` directly.

## Tool Resolution

### `get_tool_by_path` (nexus_utils/agent_factory.py:3083)

Dispatches by prefix:

| Prefix | Handling |
|--------|---------|
| `strands_tools/&lt;name&gt;` | `importlib.import_module('strands_tools.&lt;name&gt;')`; `browser` is special-cased to `AgentCoreBrowser` |
| `system_tools/&lt;path&gt;/&lt;fn&gt;` | imports `tools.system_tools.&lt;path&gt;` and `getattr(fn)`; for 2-segment paths, scans for `@tool`-decorated callables |
| `generated_tools/&lt;ns&gt;/&lt;script&gt;/&lt;fn&gt;` | imports `tools.generated_tools.&lt;ns&gt;.&lt;script&gt;`; on failure, calls `_sync_tool_from_s3` and retries |
| `template_tools/&lt;cat&gt;/&lt;script&gt;/&lt;fn&gt;` | imports `tools.template_tools.&lt;cat&gt;.&lt;script&gt;` and `getattr(fn)` |

### `_sync_tool_from_s3` (nexus_utils/agent_factory.py:3019)

When a `generated_tools` module is missing locally, fetches it from S3:

- S3 key: `tools/{dir_name}/{script_name}.py`
- Local path: `tools/generated_tools/{dir_name}/{script_name}.py`
- Bucket is read from `config.nexus_ai.artifacts_s3_bucket` (default `nexus-ai-artifacts-2026`)
- An empty `__init__.py` is created if absent

### `get_tool_by_name` (nexus_utils/agent_factory.py:3227)

Name-based lookup. Order:
1. `get_builtin_tools_mapping()` (Strands built-ins such as `file_read`, `current_time`)
2. `get_system_tools_mapping()` (system tools)
3. `tools.system_tools.agent_build_workflow.tool_template_provider.search_tools_by_name`

Both mapping helpers delegate to `tool_template_provider` (`get_builtin_tools` / `list_all_tools`) and return `name -> module.path` dicts.

## Safe Wrapper: `nexus_utils/safe_agent_factory.py`

### `create_validated_agent` (nexus_utils/safe_agent_factory.py:3299)

Calls `validate_agent_dependencies` first; on failure with `auto_fix_dependencies=True`, calls `fix_agent_dependencies` and re-validates; then creates the agent via `create_agent_from_prompt_template` and sends `"Hello, this is a test message."` as a smoke test.

Return shape:

```python
{
    "success": bool,
    "agent": Agent | (absent on failure),
    "validation_result": {...},
    "fix_result": {...} | (absent when no fix),
    "error": "..." | (absent on success),
    "message": "..."
}
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `agent_name` | `str` | — | same as `create_agent_from_prompt_template` |
| `env`, `version`, `model_id` | `str` | `"production"` / `"latest"` / `"default"` | same |
| `enable_logging` | `bool` | `False` | same |
| `state` | `Optional[Dict[str, Any]]` | `None` | same |
| `session_manager` | `Optional[Any]` | `None` | same |
| `auto_fix_dependencies` | `bool` | `True` | try to auto-repair on validation failure |
| `**agent_params` | — | — | forwarded |

### `create_agent_with_fallback` (nexus_utils/safe_agent_factory.py:3412)

```python
create_agent_with_fallback(
    agent_name: str,
    fallback_agent_name: Optional[str] = None,
    **kwargs,
) -> Dict[str, Any]
```

Falls back to `fallback_agent_name` when the primary agent fails; when the fallback succeeds, the return payload carries `primary_agent_error`.

### `batch_create_agents` (nexus_utils/safe_agent_factory.py:3457)

```python
batch_create_agents(
    agent_configs: List[Dict[str, Any]],
    continue_on_error: bool = True,
) -> Dict[str, Any]
```

Each config must contain `agent_name`; remaining keys are forwarded to `create_validated_agent`. Returns `total_agents` / `successful_agents` / `failed_agents` / `agent_results` / `created_agents`.

### `get_agent_health_status` (nexus_utils/safe_agent_factory.py:3517)

```python
get_agent_health_status(agent: Agent) -> Dict[str, Any]
```

Reads `agent.name`, `agent.model.{model_id,max_tokens,temperature}`, `len(agent.tools)`, `len(agent.system_prompt)`, then sends `"Health check test"` as a smoke test and records `last_test_success` / `last_test_response_length` / `last_test_error`.

## Dependency Validation: `nexus_utils/agent_validation.py`

### `validate_agent_dependencies` (nexus_utils/agent_validation.py:3624)

```python
validate_agent_dependencies(agent_name: str, version: str = "latest") -> Dict[str, Any]
```

1. `get_default_prompt_manager().get_agent(agent_name)` loads the template; missing → `{"valid": False, "error": "..."}`.
2. `template.get_version(version)`; missing → same.
3. Iterates `metadata.tools_dependencies`: tries `get_tool_by_path`, then `get_tool_by_name(path.split('/')[-1])`, otherwise adds to `missing_tools`; exceptions go into `invalid_tools`.
4. If `metadata.supported_models` is present, a hook is reserved (no availability check yet).
5. `valid=True` only when nothing is missing/invalid; otherwise `generate_fix_recommendations` appends remediation hints.

Return shape:

```python
{
    "valid": bool,
    "agent_name": str,
    "version": str,
    "tools_validation": {
        "total_tools": int,
        "valid_tools": [str],
        "missing_tools": [str],
        "invalid_tools": [{"tool_path": str, "error": str}],
    },
    "recommendations": [str]  # only when not valid
}
```

### `generate_fix_recommendations` (nexus_utils/agent_validation.py:3718)

Emits advice by prefix: `strands_tools/` → check the pip package; `tools/generated_tools/` / `tools/system_tools/` / `tools/template_tools/` → create the corresponding stub file.

### `validate_all_agents` (nexus_utils/agent_validation.py:3754)

Runs `validate_agent_dependencies` over every relative path returned by `manager.list_all_agent_paths()`; aggregates `total_agents` / `valid_agents` / `invalid_agents` / `agent_results`.

### `fix_agent_dependencies` (nexus_utils/agent_validation.py:3796)

With `auto_fix=True`, dispatches each `missing_tools` entry to `create_generated_tool_stub` or `create_system_tool_stub` by prefix. Returns `fixed_tools` / `failed_fixes`.

### `create_generated_tool_stub` / `create_system_tool_stub` (nexus_utils/agent_validation.py:3872,3933)

Writes a `@tool`-decorated stub at the missing path:

```python
from strands import tool

@tool
def <function_name>(*args, **kwargs) -> str:
    """Stub tool function ..."""
    return "This is an auto-generated tool stub; implement real behavior"
```

## AgentCore Entrypoint Convention

Every runner script must expose an `@app.entrypoint` async function so it can be deployed via `BedrockAgentCoreApp`:

```python
from bedrock_agentcore.runtime import BedrockAgentCoreApp
from bedrock_agentcore.runtime.context import RequestContext

app = BedrockAgentCoreApp()

@app.entrypoint
async def handler(payload: Dict[str, Any], context: RequestContext):
    session_id = context.session_id
    prompt = payload.get("prompt") or payload.get("message") or payload.get("input", "")
    if not prompt:
        yield "Error: Missing 'prompt' in request"
        return
    try:
        stream = agent.stream_async(prompt)
        async for event in stream:
            yield event
    except Exception as e:
        yield f"Error: {str(e)}"
```

| Convention | Notes |
|------------|-------|
| Must `yield` (not `return`) | AgentCore consumes via a streaming protocol |
| Accept `prompt` / `message` / `input` keys | compatible with different frontends |
| Read `session_id` from `context.session_id` | used for session correlation |
| Set `os.environ["BYPASS_TOOL_CONSENT"] = "true"` | skips Strands SDK's interactive tool-consent prompt |

Container launch: scripts end with a check on `os.environ.get("DOCKER_CONTAINER") == "1"`; when true they call `app.run()` (port 8080).

## Single-Agent Script Skeleton

Every `agents/template_agents/single_agent/*.py` follows the same shape. Excerpt from `api_integration_agent.py`:

```python
import os, json
from typing import Dict, Any
from nexus_utils.agent_factory import create_agent_from_prompt_template
from nexus_utils.telemetry_helper import setup_telemetry
from nexus_utils.config_loader import ConfigLoader
from bedrock_agentcore.runtime import BedrockAgentCoreApp
from bedrock_agentcore.runtime.context import RequestContext

loader = ConfigLoader()
os.environ["BYPASS_TOOL_CONSENT"] = "true"
setup_telemetry()
app = BedrockAgentCoreApp()

agent_config_path = "template_prompts/api_integration_agent"

def create_api_integration_agent(env: str = "production", version: str = "latest",
                                 model_id: str = "default"):
    return create_agent_from_prompt_template(
        agent_name=agent_config_path,
        env=env, version=version, model_id=model_id,
        enable_logging=True,
    )

api_integration = create_api_integration_agent()

@app.entrypoint
async def handler(payload, context):
    ...  # same AgentCore handler pattern as above

if __name__ == "__main__":
    # argparse: -i/--input, -e/--env, -v/--version, -it/--interactive
    # is_docker -> app.run()
    # interactive -> loop on input(); agent(user_input)
    # args.input -> agent(args.input)
    # default -> app.run()
    ...
```

Key conventions:

- `agent_config_path` is the prompt template relative path (`template_prompts/&lt;name&gt;` or `generated_agents_prompts/&lt;ns&gt;/&lt;name&gt;`).
- The module creates one default agent instance at import time (`api_integration = create_api_integration_agent()`) which is shared by the `@app.entrypoint` handler.
- The CLI uses `argparse` with: `-i/--input` (one-shot input), `-e/--env`, `-v/--version`, `-it/--interactive` (multi-turn loop). Some templates add `-f/--file` (`document_processor_agent`), `-u/--url` (`api_integration_agent`), `-t/--topic` (`deep_research_agent`), etc.

Per-script defaults and extra CLI flags:

| Script | `agent_config_path` | Extra CLI flags |
|--------|--------------------|-----------------|
| `default_agent.py` | `template_prompts/default` | — |
| `document_processor_agent.py` | `template_prompts/document_processor_agent` | `-f/--file` |
| `data_analyzer_agent.py` | `template_prompts/data_analyzer_agent` | `-f/--file` |
| `api_integration_agent.py` | `template_prompts/api_integration_agent` | `-u/--url` |
| `content_generator_agent.py` | `template_prompts/content_generator_agent` | `-t/--type` |
| `deep_research_agent.py` | `template_prompts/deep_research_agent` | `-t/--topic`, `-s/--scope`, `-d/--depth` |
| `html2pptx_agent.py` | `generated_agents_prompts/html2pptx/html2pptx_agent` | subcommands `convert` / `analyze` / `suggest` / `clear-cache` / `interactive` |

## Multi-Agent Orchestration: Two Patterns

### Pattern A: Explicit Orchestration (`stock_analysis_agent.py`)

The host class `StockAnalysisSystem` (`agents/template_agents/multi_agent/stock_analysis_agent.py:429`) constructs seven sub-agents in a fixed order in `__init__`:

| Attribute | Agent prompt path |
|-----------|-------------------|
| `self.coordinator_agent` | `generated_agents_prompts/stock_analysis_agent/coordinator_agent` |
| `self.data_collector_agent` | `.../data_collector_agent` |
| `self.valuation_agent` | `.../valuation_agent` |
| `self.prediction_agent` | `.../prediction_agent` |
| `self.risk_assessment_agent` | `.../risk_assessment_agent` |
| `self.benchmark_agent` | `.../benchmark_agent` |
| `self.report_generator_agent` | `.../report_generator_agent` |

The business entry point `analyze_stock(symbol, **kwargs)` calls `self.coordinator_agent(request_text)` directly; the coordinator orchestrates the other agents through its prompt. `_parse_agent_response(response)` performs layered attribute checks (`.content` / `str` / `.text`), then extracts JSON via `find('{') ... rfind('}') + 1`.

The AgentCore handler (around `agents/template_agents/multi_agent/stock_analysis_agent.py:647`) streams `system.coordinator_agent.stream_async(prompt)`.

### Pattern B: Swarm Orchestration (`tech_doc_swarm.py`)

`TechDocSwarmSystem` (`agents/template_agents/multi_agent/tech_doc_swarm.py:828`) creates three agents and wraps them with `strands.multiagent.Swarm`:

```python
from strands.multiagent import Swarm

self.swarm = Swarm(
    [self.document_writer, self.document_reviewer, self.content_processor],
    max_handoffs=30,
    max_iterations=30,
    execution_timeout=600.0,         # 10 minutes total
    node_timeout=300.0,              # 5 minutes per agent
    repetitive_handoff_detection_window=10,
    repetitive_handoff_min_unique_agents=2,
)
```

| Swarm parameter | Value | Meaning |
|-----------------|-------|---------|
| `max_handoffs` | `30` | max agent-to-agent handoffs |
| `max_iterations` | `30` | total iteration cap |
| `execution_timeout` | `600.0` | whole-workflow timeout (seconds) |
| `node_timeout` | `300.0` | per-agent timeout (seconds) |
| `repetitive_handoff_detection_window` | `10` | window for repeat-handoff detection |
| `repetitive_handoff_min_unique_agents` | `2` | minimum distinct agents in the window |

The business entry point `process_user_requirement(user_requirement, style_config=None, pass_threshold=75.0)` runs three phases:

1. `_generate_initial_document(user_requirement)` — asks `document_writer` for an initial JSON-shaped draft.
2. Review loop (up to `self.max_review_iterations=5`): `_review_document` → on fail, `_process_review_feedback` hands it back to `document_writer` for revision.
3. `_process_document_to_html(...)` — calls `tools.generated_tools.tech_doc_multi_agent_system.html_generator` utilities directly to turn the approved JSON document into HTML.

`_parse_agent_response` mirrors the `stock_analysis_agent` implementation (layered attribute checks + JSON extraction).

## Extension Points: Adding a New Agent

### 1. Add a Single-Agent Template

**Steps:**

1. **Write the prompt template**: create `prompts/template_prompts/&lt;my_agent&gt;/` (a template directory layout consumed by `prompts_manager`), declaring the system prompt, per-environment `max_tokens` / `temperature` / `streaming` in `get_environment_config`, and `metadata.tools_dependencies`.
2. **Write the runner script**: copy the `agents/template_agents/single_agent/api_integration_agent.py` skeleton (see above) and change only:
    - `agent_config_path = "template_prompts/&lt;my_agent&gt;"`
    - the factory function name `create_&lt;my_agent&gt;()`
    - the top-level instance variable name
    - the `argparse` description and any extra flags
3. **Register in the manifest**: add a template entry under `templates:` in `agents/template_agents/agent_templates_config.yaml` with `name` / `description` / `agent_dependencies` / `tools_dependencies` / `path` / `prompt_template` / `tags`.
4. **Ensure tools exist**: every `tools_dependencies` entry must be resolvable by `get_tool_by_path` (see the Tool Resolution section); sanity-check with `python -m nexus_utils.agent_validation -a &lt;my_agent&gt;`.
5. **Local verification**: `python agents/template_agents/single_agent/&lt;my_agent&gt;.py -i "hello"` or `-it` for an interactive shell.

### 2. Add a Multi-Agent System

**Pattern A (explicit orchestration)** — use when the flow is fixed-order and a coordinator does the dispatching:

1. Copy `stock_analysis_agent.py` as a template.
2. Replace the agent list / prompt paths in `_initialize_agents`.
3. Rewrite `analyze_stock` / the business entry: new prompt text and matching `_parse_agent_response` strategy.
4. Update `@app.entrypoint` so the streamed events from `coordinator_agent.stream_async` are yielded.
5. Register in `agent_templates_config.yaml` with `agent_dependencies: []` (coordination is internal) and the union of all sub-agents' `tools_dependencies`.

**Pattern B (Swarm)** — use when agents hand off peer-to-peer without a central coordinator:

1. Copy `tech_doc_swarm.py`.
2. Replace the three `agent_name`s in the `create_agent_from_prompt_template` calls inside `_create_agents`.
3. Tune `Swarm(..., max_handoffs=, max_iterations=, execution_timeout=, node_timeout=, ...)` to taste.
4. Rewrite the business entry (the `process_user_requirement` flow) or call `self.swarm(...)` directly and let Swarm run autonomously.
5. In the manifest, use `prompt_templates` (plural, array) instead of `prompt_template`.

### 3. Use `safe_agent_factory` in Production

Prefer `create_validated_agent(...)` on the production path:

```python
from nexus_utils.safe_agent_factory import create_validated_agent

result = create_validated_agent(
    agent_name="template_prompts/my_agent",
    env="production",
    auto_fix_dependencies=True,
)
if not result["success"]:
    raise RuntimeError(result["error"])
agent = result["agent"]
```

`auto_fix_dependencies=True` will auto-create stubs for missing tools via `create_generated_tool_stub` — **use with care in production**, since a stub just returns placeholder text.

### 4. Add a Model Provider

To plug in a provider that is not yet in `MODEL_PROVIDER_REGISTRY`:

1. Make sure the model class exists in Strands (e.g. `strands.models.&lt;provider&gt;.<ProviderModel>`).
2. Append a `(module_path, class_name, pip_package)` entry to `MODEL_PROVIDER_REGISTRY`.
3. Put provider-specific parameters in the prompt template YAML at `metadata.model_config`; `create_model_for_provider` merges them into the constructor kwargs (provider-specific params win over `max_tokens` / `temperature`).
4. At the call site, replace `get_bedrock_model` with `create_model_for_provider(provider, model_id, model_config=..., max_tokens=..., temperature=...)`.

### 5. Extend the Model Catalog

`config/model_catalog.yaml` is a presentation-only catalog consumed by the frontend refresh button. Its shape is `providers[*].models[*]`, one dict per entry. Fields:

| Field | Type | Notes |
|-------|------|-------|
| `id` | `str` | Bedrock inference profile ID (e.g. `us.anthropic.claude-sonnet-4-20250514-v1:0`) |
| `name` | `str` | display name |
| `tier` | `"pro" \| "standard" \| "lite"` | tier used for frontend filtering |
| `is_global` | `bool` | whether it is a cross-region inference profile |
| `supports_vision` | `bool` | image/document input support (from Bedrock `inputModalities`) |

The catalog does **not** auto-refresh; after editing, trigger the frontend reload button.

## Call Graph / Data Flow

```
agents/.../<my_agent>.py
   └── create_agent_from_prompt_template(agent_name, env, version, model_id, ...)
          │
          ├── nexus_utils.prompts_manager.get_agent(agent_name)
          │     └─> PromptTemplate.get_environment_config(env) -> {max_tokens, temperature, streaming}
          │
          ├── get_bedrock_model(model_id, agent_name, env)
          │     ├─> _fresh_boto_session()
          │     ├─> _get_cache_kwargs(resolved_id)   # claude/nova -> {cache_prompt, cache_tools}
          │     └─> BedrockModel(...)
          │
          ├── (iterate metadata.tools_dependencies)
          │     └─> get_tool_by_path(tool_path)
          │           ├─ strands_tools/*  -> importlib
          │           ├─ system_tools/*   -> tools.system_tools.*
          │           ├─ generated_tools/* -> tools.generated_tools.* (fallback _sync_tool_from_s3)
          │           └─ template_tools/* -> tools.template_tools.*
          │
          └── strands.Agent(model=..., tools=[...], system_prompt=..., ...)
```

Safe path:

```
safe_agent_factory.create_validated_agent(...)
   ├── agent_validation.validate_agent_dependencies(name, version)
   │     └── (for each tools_dependencies) get_tool_by_path / get_tool_by_name
   ├── (on failure + auto_fix) agent_validation.fix_agent_dependencies(name, version, auto_fix=True)
   │                              └── create_generated_tool_stub / create_system_tool_stub
   ├── create_agent_from_prompt_template(...)
   └── agent("Hello, this is a test message.")   # smoke test
```

## Debugging & Common Issues

| Symptom / log | Likely cause | What to check |
|----------------|--------------|---------------|
| `Agent模板 '&lt;name&gt;' 不存在` | misspelled template path or not under `prompts/.../&lt;name&gt;/` | list with `prompts_manager.get_default_prompt_manager().list_all_agent_paths()` |
| `Agent '&lt;name&gt;' 的版本 '&lt;v&gt;' 不存在` | version not declared in the template YAML | check the version directory and the `latest` symlink |
| `Unsupported model provider: '&lt;x&gt;'` | provider name missing from the registry | add an entry to `MODEL_PROVIDER_REGISTRY` |
| `Provider '&lt;x&gt;' requires '&lt;pkg&gt;'. Install it with: pip install '&lt;pkg&gt;'` | Strands extra not installed | `pip install '&lt;pkg&gt;'` as instructed |
| `Failed to import strands_tools tool &lt;path&gt;` | `strands-agents-tools` missing or wrong tool name | `pip show strands-agents-tools`, verify `get_builtin_tools_mapping()` |
| Still failing after `🔄 从 S3 同步工具文件: ... → ...` | `generated_tools` absent locally *and* no such S3 key, or bad credentials | inspect `config.nexus_ai.artifacts_s3_bucket` and AWS creds |
| `❌ Agent创建失败: ...` with an AWS error below | `BedrockModel` construction failed (IAM / region / model not enabled) | verify `config.bedrock.bedrock_region_name` and Bedrock model access |
| `prompts_manager.get_agent(...).get_environment_config(env).temperature` is `None` | template does not set temperature | `get_bedrock_model` falls back to `0.8` (`if ... is not None else 0.8`) — not a crash |
| Swarm ping-pongs between two agents | `repetitive_handoff_detection_window` / `repetitive_handoff_min_unique_agents` not effective | raise `repetitive_handoff_min_unique_agents` or fix the handoff prompt |
| `execution_timeout` expires | whole Swarm workflow stalled | raise `execution_timeout` / `node_timeout` or lower `max_review_iterations` |

CLI sanity checks:

```bash
# Validate one agent's tool dependencies
python -m nexus_utils.agent_validation -a template_prompts/my_agent -v latest

# Scan every agent
python -m nexus_utils.agent_validation --all

# Auto-fix (writes stubs)
python -m nexus_utils.agent_validation -a template_prompts/my_agent --fix

# Smoke-test through the safe factory
python -m nexus_utils.safe_agent_factory -a template_prompts/my_agent --test "hello"
```

## Further Reading

- `agents/template_agents/agent_templates_config.yaml` — authoritative list of shipped templates
- `nexus_utils/agent_factory.py` — factory internals (tool resolution, S3 sync, cache kwargs)
- `nexus_utils/safe_agent_factory.py` — dependency validation + fallback + batch creation
- `nexus_utils/agent_validation.py` — validation and stub generation
- `config/model_catalog.yaml` — frontend-visible Bedrock catalog
- `agents/template_agents/multi_agent/stock_analysis_agent.py` — explicit orchestration example
- `agents/template_agents/multi_agent/tech_doc_swarm.py` — Swarm orchestration example
