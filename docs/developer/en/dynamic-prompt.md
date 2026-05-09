---
title: Dynamic Prompt Build
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - nexus_utils/post_generation_processor.py
    - nexus_utils/prompts_manager.py
    - nexus_utils/runtime_injection/**
    - prompts/dynamic_agents_prompts/**
    - prompts/system_agents_prompts/**
  generated_at: 2026-05-09T00:52:17+00:00
  generated_by: docs-sync v2
---

# Dynamic Prompt Build

## Overview

A Nexus-AI Agent's system prompt is not a single hard-coded string — it is assembled at runtime by a two-layer pipeline:

1. **Baseline layer** — the `PromptManager` singleton in `nexus_utils/prompts_manager.py` scans `./prompts/**/*.yaml` at startup and parses each Agent's YAML (`system_prompt`, `metadata.tools_dependencies`, `environments`, `versions`, …) into `PromptAgent` / `PromptVersion` dataclasses, cached in memory under both the `agent_name` key and its relative path. System agents, template agents, and already-loaded generated agents all use the same structure; generated agents that miss the in-memory cache are lazy-loaded via DynamoDB + S3.
2. **Dynamic injection layer** — `nexus_utils/runtime_injection/` provides a unified framework: `InjectionContext` is the single context object threaded through the whole build; `BaseInjector` is the abstract base class for every injector; `InjectionRegistry` sorts all injectors by `phase` (`yaml` / `creation` / `runtime`) and `order`, then runs them in sequence. Each injector writes its increments to `ctx.prompt_parts`, `ctx.extra_tool_paths`, `ctx.extra_mcp_deps`, `ctx.runtime_tools`, `ctx.extra_hooks`, or `ctx.metadata_patches`; `apply_to_yaml` / `apply_to_agent_kwargs` then merge those increments into the YAML data or the Agent construction kwargs.

In addition, `nexus_utils/post_generation_processor.py` performs static checks and automatic fixes after the Agent Build Workflow emits Agent code (strips the defunct `prompt_template_path` argument, replaces hard-coded model_ids with `"default"`, …). It is **not** part of the runtime injection chain — it is a one-shot post-generation scan.

This document covers the following entry points:

- Loading and querying baseline prompts: `PromptManager.get_agent(agent_name) → PromptAgent`
- Running an injection phase: `injection_registry.run_phase(phase, ctx)`
- Merging injection results into YAML: `injection_registry.apply_to_yaml(yaml_data, ctx)`
- Merging injection results into Agent kwargs: `injection_registry.apply_to_agent_kwargs(agent_kwargs, ctx)`
- Post-generation processing: `post_generation_processor.process_generated_agent(path)`

## File Layout

| Path | Responsibility | Key deps |
|------|----------------|----------|
| `nexus_utils/prompts_manager.py` | YAML directory scan, parsing, in-memory cache, S3 lazy-load | `pyyaml`, `nexus_utils.asset_cache`, `api.v2.database.dynamodb` |
| `nexus_utils/runtime_injection/__init__.py` | Exports `InjectionContext` / `BaseInjector` / `InjectionRegistry` / the `injection_registry` singleton | — |
| `nexus_utils/runtime_injection/base.py` | `BaseInjector` ABC (`name`/`phase`/`order`/`should_inject`/`inject`) | `abc` |
| `nexus_utils/runtime_injection/context.py` | `InjectionContext` dataclass (input fields + output fields + control flags) | — |
| `nexus_utils/runtime_injection/registry.py` | `InjectionRegistry`, `run_phase` / `apply_to_yaml` / `apply_to_agent_kwargs`, lazy built-in registration | Each injector submodule |
| `nexus_utils/runtime_injection/injectors/tool_injector.py` | Splits plain tool paths from MCP tools (`mcp:` prefix) | — |
| `nexus_utils/runtime_injection/injectors/mcp_injector.py` | Ensures `metadata.mcp_dependencies` is merged (actual parsing lives in ToolInjector) | — |
| `nexus_utils/runtime_injection/injectors/cowork_injector.py` | Multi-Agent collaboration: `supervisor` wraps children as `agent_as_tool/`, `swarm` writes `metadata.swarm_config` | — |
| `nexus_utils/runtime_injection/injectors/skill_injector.py` | Skill L1 summary prompt + `activate_skill`/`skill_executor` tools + Skill env pre-install | `nexus_utils.runtime_workspace.skill_env` |
| `nexus_utils/runtime_injection/injectors/connector_injector.py` | Data connector tool paths + connector prompt | `nexus_utils.data_connector.tool_generator` |
| `nexus_utils/runtime_injection/injectors/sop_injector.py` | Directive (SOP) business-directive prompt injection | `nexus_utils.sop.prompt_builder` |
| `nexus_utils/runtime_injection/injectors/workspace_injector.py` | Runtime workspace rules + `runtime_workspace_*` tools | `nexus_utils.workflow_rule_extract`, `nexus_utils.agent_factory` |
| `nexus_utils/runtime_injection/injectors/workspace_hook_injector.py` | `WorkspaceRedirectHook` injection | `nexus_utils.hooks.workspace_redirect_hook` |
| `nexus_utils/runtime_injection/injectors/key_injector.py` | `SecretKeyInjector` hook (secrets injected from Secrets Manager at tool-call time, never enter the context) | `nexus_utils.hooks.secret_key_injector` |
| `nexus_utils/runtime_injection/injectors/remote_injector.py` | Nexus Bridge remote-terminal tools `remote_shell` / `remote_task` / `remote_task_status` / `sleep` + server-environment prompt | `nexus_utils.bridge.remote_shell_tool`, `strands_tools.sleep` |
| `nexus_utils/runtime_injection/injectors/template_injector.py` | User-uploaded template asset paths | — |
| `nexus_utils/post_generation_processor.py` | Static check + auto-fix for generated Agent code | `nexus_utils.agent_validation`, `nexus_utils.safe_agent_factory` |
| `prompts/system_agents_prompts/**` | System Agent YAML (build/update workflow, directive_builder, featured_agents, skill_build_workflow, tool_build_workflow, …) | Scanned by `PromptManager.load_prompts` |

## Core Data Structures

All the dataclasses below are defined in `nexus_utils/prompts_manager.py`:

### `EnvironmentConfig`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `temperature` | `float` | required (parsed as `env_data.get('temperature', 0.7)`) | Sampling temperature |
| `max_tokens` | `int` | `4096` | Max output tokens |
| `streaming` | `bool` | `True` | Stream responses |
| `debug_mode` | `Optional[bool]` | `None` | Debug toggle |

### `ToolConfig`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `name` | `str` | `''` | Tool name |
| `enabled` | `bool` | `True` | Enabled flag |
| `description` | `str` | `''` | Description |

### `PerformanceMetrics`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `accuracy` | `Optional[float]` | `None` | Accuracy |
| `response_time` | `Optional[float]` | `None` | Response time |
| `user_satisfaction` | `Optional[float]` | `None` | User satisfaction |

### `Compatibility`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `min_strands_version` | `Optional[str]` | `None` | Minimum strands-agents version |
| `supported_models` | `List[str]` | `None` | Compatible models |

### `ConversationManagerConfig`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `enabled` | `Optional[bool]` | `None` | `None` defers to global config, explicit `True`/`False` overrides |
| `type` | `Optional[str]` | `None` | `sliding_window` / `summarizing` / `null` |
| `window_size` | `Optional[int]` | `None` | SlidingWindow size |
| `should_truncate_results` | `Optional[bool]` | `None` | Truncate tool results |
| `summary_ratio` | `Optional[float]` | `None` | Summarizing ratio |
| `preserve_recent_messages` | `Optional[int]` | `None` | Summarizing: recent messages to preserve |
| `use_custom_agent` | `Optional[bool]` | `None` | Use a custom summary Agent |
| `custom_agent_model_id` | `Optional[str]` | `None` | Custom summary Agent model_id |
| `custom_agent_prompt_path` | `Optional[str]` | `None` | Custom summary Agent prompt path |

### `Metadata`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `tags` | `List[str]` | `[]` | Tags |
| `supported_models` | `Optional[List[str]]` | `None` | Supported models |
| `lib_dependencies` | `Optional[List[str]]` | `None` | Library dependencies |
| `tools_dependencies` | `Optional[List[str]]` | `None` | Tool dependency paths |
| `mcp_dependencies` | `Optional[List[str]]` | `None` | MCP server deps |
| `model_provider` | `Optional[str]` | `None` | `bedrock` (default) / `ollama` / `openai` / `anthropic` / … |
| `model_config` | `Optional[Dict[str, Any]]` | `None` | Provider-specific config |
| `swarm_config` | `Optional[Dict[str, Any]]` | `None` | Swarm multi-Agent config |
| `conversation_manager_config` | `Optional[ConversationManagerConfig]` | `None` | Conversation manager config |
| `retry_strategy` | `Optional[Dict[str, Any]]` | `None` | Model-call retry strategy (overrides global) |
| `performance_metrics` | `Optional[PerformanceMetrics]` | `None` | Performance metrics |
| `dependencies` | `Optional[List[str]]` | `None` | Generic dependencies |
| `compatibility` | `Optional[Compatibility]` | `None` | Compatibility |
| `additional_request_fields` | `Optional[Dict[str, Any]]` | `None` | Extra fields appended to model API request |

`_parse_metadata` handles three fallbacks for `mcp_dependencies`: missing field → `None`; empty field → `[]`; single string → `[str]`; list passes through.

### `Example`

| Field | Type | Description |
|-------|------|-------------|
| `user` | `str` | User input |
| `assistant` | `str` | Assistant reply |

### `PromptVersion`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `agent_name` | `str` | — | Read from YAML `agent.name` |
| `version` | `str` | — | YAML `versions[].version`, typically `"latest"` |
| `status` | `str` | `"stable"` | Version status |
| `created_date` | `str` | `''` | Created date |
| `author` | `str` | `''` | Author |
| `description` | `str` | `''` | Version description |
| `system_prompt` | `str` | `''` | Baseline system prompt |
| `user_prompt_template` | `Optional[str]` | `None` | User prompt template |
| `context_window` | `Optional[int]` | `None` | Context window |
| `tools` | `Optional[List[ToolConfig]]` | `None` | Tool configs |
| `constraints` | `Optional[List[str]]` | `None` | Constraints |
| `examples` | `Optional[List[Example]]` | `None` | Example dialogs |
| `metadata` | `Optional[Metadata]` | `None` | Metadata |

### `PromptAgent`

| Field | Type | Description |
|-------|------|-------------|
| `agent_name` | `str` | Agent name |
| `description` | `str` | Description |
| `category` | `str` | Category (`system` / `development` / `agent` / `assistant` …) |
| `environments` | `Dict[str, EnvironmentConfig]` | env name → env config |
| `versions` | `Dict[str, PromptVersion]` | version name → version object |

Methods:

| Method | Signature | Behavior |
|--------|-----------|----------|
| `get_version` | `get_version(version: str = "latest") -> Optional[PromptVersion]` | `latest` first tries `versions["latest"]`; on miss, picks the key with the **largest version tuple** (`_version_key` parses `"2.0.0"` → `(2,0,0)` for comparison); parse failure falls back to `(0,)` |
| `_version_key` | `_version_key(version_str: str) -> tuple` | Version string → comparable tuple; returns `(0,)` on error |
| `get_all_versions` | `get_all_versions() -> Dict[str, PromptVersion]` | Shallow copy of `versions` |
| `get_environment_config` | `get_environment_config(environment: str = "production") -> Optional[EnvironmentConfig]` | Lookup by env name |

### `InjectionContext` (`nexus_utils/runtime_injection/context.py`)

Unified data container carried through every injection stage, built once and read/written by every injector.

#### Base identity fields

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `agent_name` | `str` | `""` | Agent name / relative path |
| `session_id` | `str` | `""` | Session ID (needed by Bridge check and workspace parsing) |
| `agent_id` | `str` | `""` | Agent UUID (used by KeyInjector) |
| `user_id` | `str` | `""` | User ID |
| `workspace_path` | `str` | `""` | Runtime workspace absolute path |

#### Input fields (filled by caller)

| Field | Type | Description |
|-------|------|-------------|
| `skills` | `List[Dict[str, Any]]` | Skill metadata dicts (`skill_id` / `skill_name` / `l1_summary` / `has_scripts` / `has_agents` / `tools`) |
| `tools` | `List[str]` | Extra tool paths (can contain `mcp:xxx`) |
| `agents` | `List[str]` | Child agent names (Co-Work) |
| `connectors` | `List[Any]` | Data connector instances |
| `keys` | `List[str]` | Key IDs available in this session |
| `directive_ids` | `List[str]` | Directive / SOP IDs |
| `templates` | `List[Dict[str, Any]]` | Template assets (`TemplateMountSpec` dicts) |
| `cowork_mode` | `str` | `"supervisor"` (default) / `"swarm"` |
| `swarm_entry_point` | `str` | Swarm entry-point agent (defaults to `agents[0]` if empty) |

#### Output fields (written by injectors)

| Field | Type | Written by | Consumed by |
|-------|------|-----------|-------------|
| `prompt_parts` | `List[str]` | Many injectors | `apply_to_yaml` appends to `system_prompt`; `apply_to_agent_kwargs` appends to `agent_kwargs["system_prompt"]` |
| `extra_tool_paths` | `List[str]` | ToolInjector / SkillInjector / ConnectorInjector / CoWorkInjector | Merged into `metadata.tools_dependencies` (deduped) |
| `extra_mcp_deps` | `List[str]` | ToolInjector | Merged into `metadata.mcp_dependencies` (deduped) |
| `extra_hooks` | `List[Any]` | KeyInjector / WorkspaceHookInjector | `agent_kwargs["hooks"]` |
| `runtime_tools` | `List[Any]` | WorkspaceInjector / RemoteTerminalInjector | `agent_kwargs["tools"]` |
| `metadata_patches` | `Dict[str, Any]` | CoWorkInjector (`swarm_config`) | Overwrite `metadata[key]` directly |

#### Control flags

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `is_workflow_agent` | `bool` | `False` | Workflow agents skip workspace / template / key injections |
| `is_event_scheduler` | `bool` | `False` | Event-scheduler marker |

#### Helper methods

| Method | Behavior |
|--------|----------|
| `add_tool_path(path)` | Appends to `extra_tool_paths` if non-empty and not already present |
| `add_mcp_dep(server_name)` | Appends to `extra_mcp_deps` if non-empty and not already present |
| `add_prompt(prompt)` | Appends to `prompt_parts` if non-empty |

### `BaseInjector` (`nexus_utils/runtime_injection/base.py`)

```python
class BaseInjector(ABC):
    @property
    @abstractmethod
    def name(self) -> str: ...

    @property
    def phase(self) -> str:
        return "yaml"          # default

    @property
    def order(self) -> int:
        return 100             # default

    @abstractmethod
    def should_inject(self, ctx: InjectionContext) -> bool: ...

    @abstractmethod
    def inject(self, ctx: InjectionContext) -> None: ...
```

| Member | Description |
|--------|-------------|
| `name` | Log tag |
| `phase` | `yaml` (YAML template generation — touches `tools_dependencies` / `system_prompt`) / `creation` (Agent construction — touches `agent_kwargs`) / `runtime` (Agent runtime) |
| `order` | Execution order inside one phase; **lower runs first** |
| `should_inject` | Return `False` to skip |
| `inject` | Write output into `ctx`; **never** mutate YAML or Agent instance directly |

### `InjectionRegistry` (`nexus_utils/runtime_injection/registry.py`)

| Method | Signature | Behavior |
|--------|-----------|----------|
| `register` | `register(injector: BaseInjector) -> None` | Append to the internal `_injectors` list |
| `run_phase` | `run_phase(phase: str, ctx: InjectionContext) -> None` | Take injectors of this phase, sort by `order` ascending, run `should_inject` → `inject` for each; **one injector's exception does not abort others** (swallowed as a `warning` log) |
| `apply_to_yaml` | `apply_to_yaml(yaml_data: dict, ctx: InjectionContext) -> None` | Merge `extra_tool_paths` / `extra_mcp_deps` / `metadata_patches` into `yaml_data["agent"]["versions"][0]["metadata"]`; concatenate `prompt_parts` and append to `latest_version["system_prompt"]` |
| `apply_to_agent_kwargs` | `apply_to_agent_kwargs(agent_kwargs: dict, ctx: InjectionContext) -> None` | Append `prompt_parts` to `agent_kwargs["system_prompt"]`; extend `agent_kwargs["tools"]` with `runtime_tools`; extend `agent_kwargs["hooks"]` with `extra_hooks` |
| `_ensure_initialized` | — | Lazy-registers all built-in injectors via `_register_builtin_injectors(self)` on first `run_phase` call |

A global singleton is exposed at module scope:

```python
injection_registry = InjectionRegistry()
```

## Key Functions / Methods

### `PromptManager` (`nexus_utils/prompts_manager.py`)

| Method | Signature | Responsibility |
|--------|-----------|----------------|
| `__new__` | `__new__(cls, prompt_paths: List[str] = None)` | Singleton guard: creates when `cls._instance is None` |
| `__init__` | `__init__(prompt_paths: List[str] = None)` | One-shot init (guarded by `_initialized`); default paths `[default_prompt_path, template_prompt_path, generated_prompt_path]` |
| `load_prompts` | `load_prompts() -> None` | `os.walk('./prompts')` scans every `.yaml`, indexing `self.agents` by both `agent_name` and relative path |
| `_parse_environment_config` | `_parse_environment_config(env_data: Dict[str, Any]) -> EnvironmentConfig` | Parse `environments[env_name]` |
| `_parse_tool_config` | `_parse_tool_config(tool_data: Dict[str, Any]) -> ToolConfig` | — |
| `_parse_performance_metrics` | `_parse_performance_metrics(metrics_data) -> PerformanceMetrics` | — |
| `_parse_compatibility` | `_parse_compatibility(compat_data) -> Compatibility` | — |
| `_parse_conversation_manager_config` | `_parse_conversation_manager_config(cm_data: Optional[Dict]) -> Optional[ConversationManagerConfig]` | Returns `None` when `cm_data is None` |
| `_parse_metadata` | `_parse_metadata(metadata_data) -> Metadata` | Handles three fallbacks for `mcp_dependencies` |
| `_parse_examples` | `_parse_examples(examples_data) -> List[Example]` | — |
| `get_agent` | `get_agent(agent_name: str) -> Optional[PromptAgent]` | Checks the in-memory cache first, then falls back to `_try_load_from_s3` (V2 S3-First capability) |
| `_try_load_from_s3` | `_try_load_from_s3(identifier: str) -> Optional[PromptAgent]` | Ensures assets are locally cached via `nexus_utils.asset_cache.get_asset_cache_manager()`, then `load_single_prompt` and re-lookup |
| `_resolve_agent_record_from_ddb` | `_resolve_agent_record_from_ddb(identifier) -> Optional[Dict]` | Recognizes three identifier formats: UUID (length 36 with four `-`) → `db_client.get_agent`; `agent_name_en` → `db_client.query_agent_by_name_en`; relative path → take the second-to-last segment as `dir_name` → `db_client.query_agent_by_dir_name` |
| `reload` | `reload() -> None` | Clears the cache and re-runs `load_prompts` |
| `load_single_prompt` | `load_single_prompt(prompt_file_path: str) -> bool` | Loads one file (used after deploying a new Agent); auto-prefixes `./prompts/` and appends `.yaml` when needed |

### Default YAML directory constants

```python
default_prompt_path = './prompts/system_agents_prompts/*.yaml'
template_prompt_path = './prompts/template_prompts/*.yaml'
generated_prompt_path = './prompts/generated_agents_prompts/*.yaml'
```

Note: the `prompt_paths` field is kept for compatibility, but `load_prompts` actually does a full `os.walk('./prompts')` — the three constants no longer filter anything.

### `post_generation_processor.py` public functions

| Function | Signature | Responsibility |
|----------|-----------|----------------|
| `process_generated_agent` | `process_generated_agent(agent_project_path: str, auto_fix: bool = True, create_backup: bool = True) -> Dict[str, Any]` | Top-level entry: find Agent files → backup → per-file `process_agent_file` → `validate_prompt_files` |
| `find_agent_files` | `find_agent_files(project_path: str) -> List[str]` | Walks the tree for `*.py` whose filename contains `agent` and whose content contains `create_agent_from_prompt_template` or `Agent` |
| `process_agent_file` | `process_agent_file(agent_file_path: str, auto_fix: bool = True) -> Dict[str, Any]` | Three checks: the obsolete `prompt_template_path=` argument, Agent name format, hard-coded model_id |
| `validate_prompt_files` | `validate_prompt_files(project_path: str) -> Dict[str, Any]` | Finds YAMLs under `prompts/generated_agents_prompts/&lt;project_name&gt;/` and calls `validate_agent_dependencies` |
| `find_line_number` | `find_line_number(content: str, search_text: str) -> int` | Line of first occurrence; `-1` when not found |
| `fix_prompt_template_path_parameter` | — | Deletes matches of `r',?\s*prompt_template_path\s*=\s*["\'][^"\']*["\']'` |
| `check_agent_name_format` | — | Captures `r'agent_name\s*=\s*["\']([^"\']*)["\']'`; valid prefixes are `system_agents_prompts/` / `template_prompts/` / `generated_agents_prompts/` |
| `fix_agent_name_format` | — | Placeholder — currently returns content unchanged (auto-fix unimplemented) |
| `check_model_configuration` | — | Flags `model_id` values starting with `anthropic.` or `us.anthropic.` |
| `fix_model_configuration` | — | Replaces `model_id = "...anthropic..."` with `model_id = "default"` |

CLI:

```bash
python -m nexus_utils.post_generation_processor -p <agent_project_path> [--no-auto-fix] [--no-backup]
```

## Built-in Injectors

`registry._register_builtin_injectors` is invoked during `_ensure_initialized` and registers injectors in the order below (registration order is **not** execution order — execution is driven by `phase` + `order`):

| `name` | Class | File | phase | order | `should_inject` condition | Main output |
|--------|-------|------|-------|-------|---------------------------|-------------|
| `tool` | `ToolInjector` | `injectors/tool_injector.py` | `yaml` | 10 | `bool(ctx.tools)` | `extra_tool_paths` + `extra_mcp_deps` |
| `mcp` | `MCPInjector` | `injectors/mcp_injector.py` | `yaml` | 15 | `bool(ctx.extra_mcp_deps)` | Log only (merge happens in `apply_to_yaml`) |
| `cowork` | `CoWorkInjector` | `injectors/cowork_injector.py` | `yaml` | 20 | `bool(ctx.agents)` | `supervisor`: `extra_tool_paths.append("agent_as_tool/&lt;name&gt;")`; `swarm`: `metadata_patches["swarm_config"]` |
| `skill` | `SkillInjector` | `injectors/skill_injector.py` | `yaml` | 30 | `bool(ctx.skills)` | `prompt_parts` (L1 summary) + `extra_tool_paths` (`system_tools/skill_activator`, `system_tools/skill_executor`, optionally `strands_tools/shell`, Skill's own tools) + skill env prompt |
| `connector` | `ConnectorInjector` | `injectors/connector_injector.py` | `yaml` | 40 | `bool(ctx.connectors)` | `extra_tool_paths` (`get_connector_tool_paths`) + `prompt_parts` (`generate_connector_prompt`) |
| `directive` | `SOPInjector` | `injectors/sop_injector.py` | `yaml` | 50 | `bool(ctx.directive_ids)` | `prompt_parts` (`build_directive_prompt`) |
| `workspace` | `WorkspaceInjector` | `injectors/workspace_injector.py` | `creation` | 10 | Non-workflow Agent, and `config.runtime_workspace.auto_sync` is True (default) | `prompt_parts` (runtime rules + workspace guide) + `runtime_tools` (three `runtime_workspace_*` tools) |
| `remote_terminal` | `RemoteTerminalInjector` | `injectors/remote_injector.py` | `creation` | 10 | `bool(ctx.session_id)` and Bridge `/status/&lt;session_id&gt;` returns `connected=True` | `runtime_tools` (`remote_shell` / `remote_task` / `remote_task_status` / `sleep`) + `prompt_parts` (server env and command rules) |
| `workspace_hook` | `WorkspaceHookInjector` | `injectors/workspace_hook_injector.py` | `creation` | 20 | `bool(ctx.workspace_path)` and non-workflow | `extra_hooks.append(create_workspace_redirect_hook(ws))` |
| `key` | `KeyInjector` | `injectors/key_injector.py` | `creation` | 25 | `bool(ctx.agent_id)` and non-workflow | Builds `SecretKeyInjector`; appends to `extra_hooks` only when `hook.tool_key_map` is non-empty |
| `template` | `TemplateInjector` | `injectors/template_injector.py` | `creation` | 30 | `bool(ctx.templates)` and non-workflow | `prompt_parts` (listing every template file path plus optional `.structured.json` helper path) |

> `workspace` and `remote_terminal` both have `phase=creation, order=10`; when `order` ties, Python's **stable sort** preserves registration order — `workspace` is registered first, so `workspace` runs first.

## Call Flow (Data Flow)

### Building Agent YAML (`phase=yaml`)

```
Caller (DynamicConfigService._generate_dynamic_yaml)
  │
  ├─ ctx = InjectionContext(agent_name, skills=[...], tools=[...], connectors=[...],
  │                          directive_ids=[...], agents=[...], cowork_mode=...)
  │
  ├─ injection_registry.run_phase("yaml", ctx)
  │     │
  │     ├─ ToolInjector      (order=10)  → ctx.extra_tool_paths / extra_mcp_deps
  │     ├─ MCPInjector       (order=15)  → (log only)
  │     ├─ CoWorkInjector    (order=20)  → extra_tool_paths or metadata_patches
  │     ├─ SkillInjector     (order=30)  → prompt_parts + extra_tool_paths + skill_env
  │     ├─ ConnectorInjector (order=40)  → extra_tool_paths + prompt_parts
  │     └─ SOPInjector       (order=50)  → prompt_parts
  │
  └─ injection_registry.apply_to_yaml(yaml_data, ctx)
        → metadata.tools_dependencies   ∪= extra_tool_paths
        → metadata.mcp_dependencies     ∪= extra_mcp_deps
        → metadata.<key>                 = metadata_patches[key]
        → system_prompt                 += ''.join(prompt_parts)
```

### Building the Agent instance (`phase=creation`)

```
Caller (agent_factory.create_agent_from_prompt_template)
  │
  ├─ ctx = InjectionContext(agent_name, agent_id, session_id, user_id,
  │                          workspace_path, keys=[...], templates=[...])
  │
  ├─ injection_registry.run_phase("creation", ctx)
  │     │
  │     ├─ WorkspaceInjector       (order=10)  → prompt_parts + runtime_tools
  │     ├─ RemoteTerminalInjector  (order=10)  → prompt_parts + runtime_tools
  │     ├─ WorkspaceHookInjector   (order=20)  → extra_hooks
  │     ├─ KeyInjector             (order=25)  → extra_hooks
  │     └─ TemplateInjector        (order=30)  → prompt_parts
  │
  └─ injection_registry.apply_to_agent_kwargs(agent_kwargs, ctx)
        → agent_kwargs["system_prompt"] += ''.join(prompt_parts)
        → agent_kwargs["tools"]         += runtime_tools
        → agent_kwargs["hooks"]         += extra_hooks
```

### `phase=runtime`

In the current release every built-in injector has `phase` equal to `yaml` or `creation` — there is **no** built-in `runtime` injector. `run_phase("runtime", ctx)` is still legal; it's reserved for third-party injectors or for online extensions in `agent_runtime_service`.

## Extending

### Adding a new injector

1. **Pick the phase**:
   - Modify `metadata.tools_dependencies` / `metadata.mcp_dependencies` / `system_prompt` in the YAML → `yaml`
   - Push items (tool instances, hook instances, `system_prompt`) into the Agent's construction kwargs → `creation`
   - Hook in after the Agent is instantiated and running → `runtime`
2. **Pick the order**: consult the table above and avoid clashes. If you depend on a previous injector's output (e.g. waiting for `ToolInjector` to strip `mcp:` prefixes first), use a larger `order`.
3. **Subclass `BaseInjector`** and implement four members:

   ```python
   from nexus_utils.runtime_injection.base import BaseInjector
   from nexus_utils.runtime_injection.context import InjectionContext

   class MyInjector(BaseInjector):
       @property
       def name(self) -> str:
           return "my_injector"

       @property
       def phase(self) -> str:
           return "yaml"

       @property
       def order(self) -> int:
           return 60

       def should_inject(self, ctx: InjectionContext) -> bool:
           return bool(getattr(ctx, "my_input", None))

       def inject(self, ctx: InjectionContext) -> None:
           ctx.add_prompt("\n\n## My Section\n...")
           ctx.add_tool_path("custom/my_tool")
   ```

4. **Register it** by editing `nexus_utils/runtime_injection/registry.py::_register_builtin_injectors`:

   ```python
   try:
       from nexus_utils.runtime_injection.injectors.my_injector import MyInjector
       registry.register(MyInjector())
   except Exception as e:
       logger.warning(f"[injection] Failed to register MyInjector: {e}")
   ```

   or call `injection_registry.register(MyInjector())` at runtime. Caveat: `_ensure_initialized` runs only once — a runtime `register` call must happen **after** the first `run_phase`; to force earlier initialization call `injection_registry._ensure_initialized()` directly.

### Adding a new context input field

When you need a new input (say `my_input: List[str]`), add it to the `InjectionContext` dataclass in `nexus_utils/runtime_injection/context.py`. Keep backwards compatibility with a default value; callers populate it when they construct `ctx`.

### Constraints and pitfalls

- **Never** mutate `yaml_data` or `agent_kwargs` inside `inject()` — write to `ctx` only. Merging is done by `apply_to_yaml` / `apply_to_agent_kwargs`; bypassing them breaks results whenever `run_phase` is called by other code.
- **Exception isolation**: `run_phase` wraps every injector in `try/except` and logs failures as `warning`. If you want failures to abort, do **not** swallow them inside `inject()` — raise, but understand the outer layer will still warn-and-continue.
- **MCP special path**: `mcp:`-prefixed entries in `ctx.tools` are peeled off by `ToolInjector` into `extra_mcp_deps`, not `extra_tool_paths`.
- **Workflow-Agent whitelist**: `is_workflow_agent=True` skips `workspace` / `workspace_hook` / `key` / `template`. Workflows (Build, Tool, …) don't need user workspaces or secrets.
- **`PromptManager` is a singleton**: `PromptManager()` is a `__new__`-level singleton; after the first `__init__` sets `_initialized=True`, subsequent `prompt_paths` arguments are ignored. **Reconfiguring requires a restart or an explicit `reload()`.**
- **`get_version("latest")` fallback**: when the YAML has no `"latest"` key, the largest version tuple wins. Non-numeric versions (e.g. `"beta"`) fall back to `(0,)` in `_version_key`, so they lose to any numeric version.
- **S3 lazy-load**: `_try_load_from_s3` calls `load_single_prompt` and registers the new Agent into `self.agents`. No lock is held — under high concurrency the same Agent may be parsed twice on first access (last writer wins; result is still correct).
- **Post-generation name constraint**: `check_agent_name_format` requires the `agent_name` prefix to be one of `system_agents_prompts/` / `template_prompts/` / `generated_agents_prompts/` — **hard-coded to match** the directories scanned by `prompts_manager`. Add a new category in both places.

## Common Debugging / Troubleshooting

### Log keywords

Every injector log starts with `[injection] &lt;name&gt;:`. Common lines:

| Log | Meaning |
|-----|---------|
| `[injection] Registered injector: &lt;name&gt; (phase=..., order=...)` | Registered successfully (DEBUG) |
| `[injection] Registered N injector(s)` | `_register_builtin_injectors` finished |
| `[injection] tool: added X tools, Y MCP deps` | ToolInjector succeeded |
| `[injection] skill: injected L1 metadata for N skill(s)` | SkillInjector succeeded |
| `[injection] skill: env preparation failed (non-fatal): &lt;err&gt;` | Skill env prep failed but did not abort |
| `[injection] connector: injected N tools and prompt for M connector(s)` | ConnectorInjector succeeded |
| `[injection] cowork: supervisor mode, N agent(s) as tools` / `swarm mode, N member(s)` | CoWorkInjector branch taken |
| `[injection] directive: injected prompt for N directive(s)` | SOPInjector succeeded |
| `[injection] workspace: rules injected for '&lt;agent_name&gt;'` | WorkspaceInjector succeeded |
| `[injection] workspace_hook: injected for &lt;path&gt;` | Hook succeeded |
| `[injection] key: registered SecretKeyInjector for agent &lt;aid&gt;... (N key-required tools)` | KeyInjector registered the hook |
| `[injection] key: no key-required tools for agent &lt;aid&gt;..., skipping` | Agent has no key-requiring tools (normal) |
| `[injection] remote_terminal: injected for session &lt;sid&gt;, servers=[...]` | Bridge is connected |
| `TemplateInjector injected N templates` | TemplateInjector succeeded |
| `[injection] &lt;name&gt; failed: &lt;err&gt;` | A single injector errored (others still run) |

### Typical failures

| Symptom | Likely cause | Start from |
|---------|--------------|------------|
| `get_agent(name)` returns `None` | 1. YAML is not under `./prompts/` 2. YAML has no top-level `agent:` key 3. S3 path does not match the DDB record | Check the startup log line "加载提示词文件 X 时出错"; query `db_client.query_agent_by_name_en` / `query_agent_by_dir_name` directly |
| Skill tools not injected | `ctx.skills` is empty; or `skill.tools` field missing | Print `ctx.skills`; verify the L1 metadata has a `tools` list |
| `remote_shell` tool missing | Bridge not connected: `GET &lt;bridge_url&gt;/status/&lt;session_id&gt;` returns `connected=false` | Check `bridge_logger`'s `tool_check` event; inspect `_get_bridge_url()` |
| Key tool fails with permission errors | `KeyInjector` determined the Agent has no key-requiring tools (`hook.tool_key_map` empty) and did not register the hook | Review `SecretKeyInjector.tool_key_map` construction and the Agent's `tools_dependencies` |
| `swarm_config` is not written to YAML | `cowork_mode != "swarm"` or `ctx.agents` empty | Print `ctx.cowork_mode` and `ctx.agents` |
| Generated Agent code still contains `model_id="us.anthropic..."` | `auto_fix=False`, or `model_id` uses a non-literal expression (e.g. a variable) | `post_generation_processor.check_model_configuration` only matches string literals; inspect returned `issues` / `fixes_applied` |
| MCP tool has no effect | The prefix in `ctx.tools` is not exactly `mcp:`; or `metadata.mcp_dependencies` is not read by the downstream loader | See `ToolInjector.inject`'s slicing: `tool_path[4:]`, split by `/` and take the first segment |
| Two injectors run in the wrong order | Both left `order=100` default | Override the `order` property explicitly |

## Further Reading

- Registration and call sites: `nexus_utils/runtime_injection/__init__.py` (exports), `nexus_utils/runtime_injection/registry.py` (`_register_builtin_injectors`)
- Baseline prompt loading: `nexus_utils/prompts_manager.py::PromptManager.load_prompts`
- Post-generation entry: `nexus_utils/post_generation_processor.py::process_generated_agent`
- System Agent YAML templates: `prompts/system_agents_prompts/**/*.yaml` (build / update workflow, directive_builder, featured_agents, skill_build_workflow, tool_build_workflow — 50+ files)
- Related dependency modules: `nexus_utils.data_connector.tool_generator`, `nexus_utils.sop.prompt_builder`, `nexus_utils.hooks.secret_key_injector`, `nexus_utils.hooks.workspace_redirect_hook`, `nexus_utils.bridge.remote_shell_tool`, `nexus_utils.runtime_workspace.skill_env`, `nexus_utils.asset_cache`, `api.v2.database.dynamodb`
