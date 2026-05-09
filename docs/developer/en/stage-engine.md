---
title: Stage Engine
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - agents/system_agents/**
    - config/workflows.yaml
    - nexus_utils/workflow/**
  generated_at: 2026-05-09T00:14:55+00:00
  generated_by: docs-sync v2
---

# Stage Engine

## Overview

The Stage Engine is the kernel of Nexus-AI workflow execution. It splits a user-need-driven workflow into discrete **stages**, each executed by a single Agent (backed by a prompt template). Each stage's `StageOutput` becomes the context input of the next stage. The code lives primarily under `nexus_utils/workflow/`; stage sequences, Agent display names, prerequisites, and rule-injection keys are declared statically in `config/workflows.yaml`.

Two engine implementations coexist:

- **V1: `nexus_utils/workflow/engine.py::WorkflowEngine`** — runs all stages sequentially in one process, persists `WorkflowContext` to DynamoDB, supports pause/resume/stop. `agent_build_workflow.py`, `agent_update_workflow.py`, and `tool_build_workflow.py` are sequential-call variants used by local scripts and earlier workflows.
- **V2: `nexus_utils/workflow/engine_v2.py::WorkflowEngineV2`** — runs **exactly one stage per invocation**, writes the result back to DDB, and lets the outer Worker fan out the next stage via SQS. Supports `scope` (project/agent) and `fork`/`join` parallelism; this is the current execution kernel for the v2 API + Worker path.

Both engines share the data models in `models.py` (`StageOutput`, `StageMetrics`, `WorkflowContext`, etc.), Agent creation in `executor.py`, the multi-Agent iterator in `multi_agent.py`, and the prompt/Agent validators in `validator.py` / `agent_validator.py`. `workflows.yaml` is the single source of configuration for both.

This document covers: stage lifecycle, context assembly, every data model, the stage executor, multi-Agent iteration, fork/join parallelism, V1↔V2 differences, and every extension point needed to add new workflows.

## File Layout

| Path | Responsibility | Dependencies |
|------|----------------|--------------|
| `nexus_utils/workflow/__init__.py` | Package entry; re-exports all public types | `.models` `.context` `.engine` `.executor` `.validator` `.multi_agent` `.agent_validator` `.file_sync` |
| `nexus_utils/workflow/models.py` | Stage status enums, `StageOutput`, `WorkflowContext`, `AggregatedMetrics`, etc. | `api.v2.core.stage_config` (lazy) |
| `nexus_utils/workflow/context.py` | `WorkflowContextManager`: DDB load/save, stage context formatting, token estimation & summarization | `api.v2.database.db_client` `api.v2.core.stage_config` |
| `nexus_utils/workflow/engine.py` | V1 engine: `WorkflowEngine`, `ExecutionResult`, control signals | `.context` `.executor` `api.v2.services.stage_service` |
| `nexus_utils/workflow/engine_v2.py` | V2 engine: `WorkflowEngineV2`, `StageExecutionResult`, fork/join signals | `nexus_utils.workflow_config` `api.v2.database.dynamodb` `nexus_utils.agent_factory` |
| `nexus_utils/workflow/executor.py` | Stage executor: Agent creation, metrics collection, generated-file scanning | `nexus_utils.agent_factory` `api.v2.core.stage_config` `.multi_agent` |
| `nexus_utils/workflow/multi_agent.py` | Multi-Agent architecture parsing and iterative execution | `.models` |
| `nexus_utils/workflow/validator.py` | Prompt tool-path validation and output document format checks | `importlib` `yaml` |
| `nexus_utils/workflow/agent_validator.py` | Post-generation self-check of prompt/tools/factory for a generated Agent | `nexus_utils.agent_factory` `yaml` |
| `nexus_utils/workflow/file_sync.py` | Generated-file metadata, cross-Worker S3 sync, file-content API | `boto3` `hashlib` |
| `config/workflows.yaml` | Stage definitions, prompt paths, prerequisites, rule keys, fork/join flags for every workflow | — (YAML config) |
| `agents/system_agents/agent_build_workflow/agent_build_workflow.py` | V1 sequential Agent build workflow | `nexus_utils.agent_factory` `stage_tracker` |
| `agents/system_agents/agent_build_workflow/run_workflow_v2.py` | CLI entry based on `WorkflowEngine` (supports from-any-stage, pause/resume) | `nexus_utils.workflow.engine` |
| `agents/system_agents/agent_update_workflow/agent_update_workflow.py` | Agent update workflow (5 sequential stages) | `nexus_utils.workflow_rule_extract` `stage_tracker` |
| `agents/system_agents/tool_build_workflow/tool_build_workflow.py` | Tool build workflow (6 sequential stages) | `nexus_utils.workflow_rule_extract` |
| `agents/system_agents/*/*_agent.py` | Standalone Agent module for each stage (for single-agent invocation and testing) | `nexus_utils.agent_factory` |

## Workflow Configuration (`config/workflows.yaml`)

`workflows.yaml` is the engine's declarative entry point. It consists of `version`, `defaults`, and several workflow entries (`agent_build` / `agent_update` / `tool_build` / `skill_build` / `magician`). Loading goes through `nexus_utils/workflow_config.py::get_workflow_config(workflow_type)`; both `WorkflowEngineV2` and `StageExecutor._load_stage_prompt_mapping()` obtain configuration this way.

### Global defaults

```yaml
defaults:
  execution:
    max_retries: 3                    # stage retry on failure
    retry_delay_seconds: 5
    stage_timeout_seconds: 3600
    total_timeout_seconds: 21600
    checkpoint_interval_seconds: 60
  context:
    max_tokens: 100000                # matches DEFAULT_MAX_CONTEXT_TOKENS
    summary_threshold_tokens: 5000
    include_rules: true
    include_local_docs: true
```

### Supported workflows

| `workflow_type` | Name | Stages | `prompt_base_path` | Use case |
|-----------------|------|-------:|---------------------|----------|
| `agent_build` | Agent Build Workflow V2 | 8 | `system_agents_prompts/agent_build_workflow` | Build a new Agent from natural language, supports multi-Agent parallelism (fork/join) |
| `agent_update` | Agent Update Workflow V2 | 5 | `system_agents_prompts/agent_update_workflow` | Versioned update of an existing Agent; `skip_stages` can skip tool/prompt steps |
| `tool_build` | Tool Build Workflow V2 | 5 | `system_agents_prompts/tool_build_workflow_v2` | Build a `@tool` function + `requirements.txt` + `key_bindings`, register to `nexus_tools` DDB |
| `skill_build` | Skill Build Workflow | 5 | `system_agents_prompts/skill_build_workflow` | Build `SKILL.md` + `scripts/` + `references/` + `evals/` |
| `magician` | Magician router | 1 | `system_agents_prompts/magician_workflow` | Identify intent, route to one of the above workflows |

### Per-stage configuration fields

A single stage entry is consumed by both `WorkflowEngineV2` and `StageExecutor`:

| Field | Type | Meaning |
|-------|------|---------|
| `name` | `str` | Internal unique identifier (`stage_name`). DDB stores `stage_key`: `name` for project-scope, `name#{agent_id}` for agent-scope |
| `display_name` | `str` | UI label |
| `agent_display_name` | `str` | Agent name used when composing context (V1's `STAGE_TO_AGENT_NAME` mapping) |
| `prompt_file` | `str` | Prompt file name (relative to `prompt_base_path`) |
| `log_filename` | `str` | Corresponding log file name |
| `order` | `int` | Sequence number (`_mark_stage_running` writes `stage_number`) |
| `scope` | `"project"` \| `"agent"` | Stage scope. `agent`-scope stages require `agent_id` |
| `prerequisites` | `List[str]` | Prerequisite stage names. `_build_agent_input` injects each prerequisite's `stage_result` JSON |
| `rule_keys` | `List[str]` | Sub-keys to selectively inject from workflow rules (see rule-injection policy below) |
| `supports_iteration` | `bool` | Whether multi-Agent iteration is supported (V1 uses `ITERATIVE_STAGES`, V2 loops through `agent_ids`) |
| `optional` | `bool` | Whether it can be skipped via `skip_stages` |
| `fork_on_complete` | `bool` | Whether completion fans out into multiple agent-scope stages (`system_architecture` in agent_build) |
| `join_after_complete` | `bool` | Whether completion triggers an all-agent convergence check (`code_development` in agent_build) |
| `join_before_start` | `bool` | Whether all Agents must have completed before starting (`deployment` in agent_build) |
| `description` | `str` | Human-readable description |

### `agent_build` stage summary

| order | name | scope | prerequisites | special |
|-------|------|-------|--------------|---------|
| 1 | `intent_recognition` | project | — | — |
| 2 | `requirements_analysis` | project | `intent_recognition` | — |
| 3 | `system_architecture` | project | `requirements_analysis` | `fork_on_complete: true` |
| 4 | `agent_design` | agent | `requirements_analysis`, `system_architecture` | — |
| 5 | `tools_development` | agent | `agent_design` | `supports_iteration: true` |
| 6 | `prompt_development` | agent | `requirements_analysis`, `tools_development` | `supports_iteration: true` |
| 7 | `code_development` | agent | `prompt_development` | `supports_iteration: true`, `join_after_complete: true` |
| 8 | `deployment` | project | `system_architecture`, `code_development` | `join_before_start: true` |

### Legacy name compatibility (`legacy_name_mapping`)

Every workflow declares a V1→V2 mapping used by helpers such as `_normalize_stage_name()` to accept old script names and old data:

```yaml
agent_build:
  legacy_name_mapping:
    orchestrator: "intent_recognition"
    requirements_analyzer: "requirements_analysis"
    system_architect: "system_architecture"
    agent_designer: "agent_design"
    tools_developer: "tools_development"
    tool_developer: "tools_development"
    prompt_engineer: "prompt_development"
    agent_code_developer: "code_development"
    agent_developer_manager: "code_development"
    agent_deployer: "deployment"
```

## Core Data Models (`nexus_utils/workflow/models.py`)

All data classes are `@dataclass` and provide `to_dict()` / `from_dict()` for DynamoDB serialization. Exhaustive list:

### Enums

#### `StageStatus` (models.py)

| Value | Meaning |
|-------|---------|
| `PENDING` | Awaiting execution |
| `RUNNING` | Executing |
| `COMPLETED` | Done |
| `FAILED` | Failed |
| `PAUSED` | Paused (`save_to_db` maps this to project-level `paused`) |

#### `ControlStatus` (models.py)

| Value | Meaning |
|-------|---------|
| `RUNNING` | Normal |
| `PAUSED` | Stop after the current stage (`WorkflowEngine.pause()`) |
| `STOPPED` | Stop after the current LLM call (`WorkflowEngine.stop()`) |
| `CANCELLED` | Cancelled |

### `StageMetrics`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `input_tokens` | `int` | `0` | Input tokens (from `result.metrics.accumulated_usage.inputTokens`) |
| `output_tokens` | `int` | `0` | Output tokens |
| `execution_time_seconds` | `float` | `0.0` | Total Agent call duration |
| `tool_calls_count` | `int` | `0` | Tool call count (length of `result.metrics.tool_metrics`) |
| `model_id` | `Optional[str]` | `None` | `agent.model.model_id` |

Property `total_tokens` returns `input_tokens + output_tokens`.

### `FileMetadata`

| Field | Type | Description |
|-------|------|-------------|
| `path` | `str` | Path relative to `projects/&lt;agent_name&gt;/` |
| `size` | `int` | File size in bytes |
| `checksum` | `Optional[str]` | MD5 checksum |
| `last_modified` | `Optional[datetime]` | Last modified time |

### `StageOutput`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `stage_name` | `str` | — | Stage name |
| `content` | `str` | `""` | Agent output text; if bytes > `MAX_CONTENT_SIZE = 400 * 1024` it is written to S3 and `s3_content_ref` is set |
| `metrics` | `StageMetrics` | `StageMetrics()` | Metrics |
| `generated_files` | `List[FileMetadata]` | `[]` | Files generated by this stage |
| `document_content` | `str` | `""` | Design document (e.g. architecture JSON) |
| `document_format` | `str` | `"markdown"` | `markdown` / `json` / `yaml` / `python` |
| `completed_at` | `Optional[datetime]` | `None` | Completion time |
| `status` | `StageStatus` | `PENDING` | Current status |
| `error_message` | `Optional[str]` | `None` | Error text on failure |
| `s3_content_ref` | `Optional[str]` | `None` | S3 reference for oversized content |

Convenience properties: `is_completed`, `is_failed`, `content_exceeds_limit` (bytes > 400KB).

### `IntentRecognitionResult`

| Field | Type | Default |
|-------|------|---------|
| `agent_name` | `str` | `""` |
| `agent_description` | `str` | `""` |
| `workflow_type` | `str` | `"single_agent"` |
| `complexity` | `str` | `"medium"` |
| `estimated_stages` | `List[str]` | `[]` |
| `key_features` | `List[str]` | `[]` |
| `tool_requirements` | `List[str]` | `[]` |
| `raw_analysis` | `str` | `""` |

### `AgentDefinition`

A single Agent in a multi-Agent architecture:

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `name` | `str` | — | Agent name |
| `agent_type` | `str` | `"main"` | `main` / `sub` / `tool` |
| `description` | `str` | `""` | Description |
| `orchestration_pattern` | `str` | `"agent_as_tool"` | `agent_as_tool` / `swarm` / `graph` |
| `dependencies` | `List[str]` | `[]` | Dependency Agent names |
| `tools` | `List[str]` | `[]` | Tool paths |
| `status` | `StageStatus` | `PENDING` | Current status |

### `MultiAgentArchitecture`

| Field | Type | Description |
|-------|------|-------------|
| `agents` | `List[AgentDefinition]` | All Agents |
| `orchestration_pattern` | `str` | Overall pattern |
| `main_agent` | `str` | Name of the main Agent |
| `agent_count` | `int` (property) | `len(agents)` |
| `agent_names` | `List[str]` (property) | All names |

Methods: `get_agent(name)`, `add_agent(agent)`.

### `AgentStageProgress`

Tracks per-Agent stage progress in multi-Agent projects:

| Field | Type | Description |
|-------|------|-------------|
| `agent_name` | `str` | Agent name |
| `stage_statuses` | `Dict[str, StageStatus]` | Per-stage status |
| `current_stage` | `str` | Current stage |
| `AGENT_STAGES` | `List[str]` | Fixed: `["agent_design", "tool_development", "prompt_engineering", "code_development", "testing"]` |

Properties: `completed_stages`, `total_stages`, `progress_percentage`.

### `AggregatedMetrics`

Project-level aggregated metrics; `add_stage_metrics(metrics)` accumulates:

| Field | Type | Default |
|-------|------|---------|
| `total_input_tokens` | `int` | `0` |
| `total_output_tokens` | `int` | `0` |
| `total_tokens` | `int` | `0` |
| `total_cost` | `float` | `0.0` |
| `total_execution_time` | `float` | `0.0` |
| `total_tool_calls` | `int` | `0` |

### `WorkflowContext`

The runtime context object (abbreviated field summary):

| Field | Type | Description |
|-------|------|-------------|
| `project_id` | `str` | Project ID |
| `project_name` | `str` | Project name |
| `requirement` | `str` | Original user input |
| `intent_result` | `Optional[IntentRecognitionResult]` | Intent parsed at the orchestrator stage |
| `stage_outputs` | `Dict[str, StageOutput]` | Completed stage outputs (keyed by `stage_name`) |
| `rules` | `str` | Base rules loaded from `config/nexus_ai_base_rule.yaml` |
| `current_stage` | `str` | Current stage |
| `status` | `StageStatus` | Project status (mapped to v2 `ProjectStatus`) |
| `aggregated_metrics` | `AggregatedMetrics` | Aggregated metrics |
| `control_status` | `ControlStatus` | Pause/stop state |
| `pause_requested_at` / `stop_requested_at` | `Optional[datetime]` | Control signal timestamps |
| `resume_from_stage` | `Optional[str]` | Resume point |
| `workflow_type` | `str` | `agent_build` / `agent_update` / `tool_build` / `skill_build` |

Common methods (defined at the end of `models.py`): `get_completed_stages()`, `get_pending_stages()`, `get_next_stage()`, `get_prerequisite_stages(stage_name)`, `get_stage_output(stage_name)`, `update_stage_output(stage_name, output)`.

### Module-level lazy stage sequence: `STAGE_ORDER`

`models.py` exports `STAGE_ORDER = _LazyStageOrder()`, which calls `api.v2.core.stage_config.get_all_stage_names("agent_build")` only when iterated, avoiding circular imports. Supports `__iter__` / `__getitem__` / `__contains__` / `index`.

## V1 Engine: `WorkflowEngine` (`engine.py`)

### Exceptions and signals

| Class | Inherits | Purpose |
|-------|----------|---------|
| `StageExecutionError(stage_name, message, recoverable=True)` | `Exception` | Stage execution failure (`executor.py`) |
| `WorkflowControlSignal(signal_type, message)` | `Exception` | Control signal; `signal_type ∈ {"pause", "stop"}` |
| `PrerequisiteError(stage_name, missing_prerequisites)` | `Exception` | Prerequisite not completed |

### `ExecutionResult`

| Field | Type | Default |
|-------|------|---------|
| `success` | `bool` | `False` |
| `completed_stages` | `List[str]` | `[]` |
| `failed_stage` | `Optional[str]` | `None` |
| `error_message` | `Optional[str]` | `None` |
| `final_status` | `StageStatus` | `PENDING` |
| `metrics` | `Dict[str, Any]` | `{}` |

### `WorkflowEngine` public API

| Method | Signature | Responsibility |
|--------|-----------|----------------|
| `__init__` | `(project_id, config=None, db_client=None)` | Init. `config['workflow_type']` decides which workflow (default `agent_build`) |
| `context` | property | Lazy-load `WorkflowContext` (first access calls `load_context()`) |
| `executor` | property | Lazy-create `StageExecutor` |
| `set_callbacks` | `(on_stage_start, on_stage_complete, on_stage_error)` | Install stage callbacks; if the executor exists they are propagated |
| `load_context` | `() -> WorkflowContext` | Loads via `WorkflowContextManager.load_from_db(project_id)` |
| `validate_prerequisites` | `(stage_name) -> bool` | Checks prerequisites; raises `PrerequisiteError` if missing |
| `execute_single_stage` | `(stage_name, input_message=None, state=None, skip_validation=False) -> StageOutput` | Runs one stage; calls `_check_control_signals` before and after |
| `execute_from_stage` | `(stage_name, to_completion=True, state=None) -> ExecutionResult` | Starts from a given stage; with `to_completion=True` runs all remaining `pending_stages` |
| `execute_to_completion` | `(state=None) -> ExecutionResult` | Starts from `context.get_next_stage()` |
| `pause` | `() -> bool` | Sets `control_status=PAUSED`, saves context |
| `resume` | `(from_stage=None) -> bool` | Clears control flags, writes `control_status=RUNNING` |
| `stop` | `() -> bool` | Sets `control_status=STOPPED` |
| `get_status` | `() -> Dict[str, Any]` | Returns `project_id` / `status` / `control_status` / `current_stage` / completed/pending stages / aggregated metrics |

### Control-signal refresh mechanism

`_refresh_control_status()` re-reads `control_status` from DDB via `db.get_project(project_id)` before and after each stage, syncing `paused` / `stopped` into memory. This means **an external HTTP request (from the api layer) that writes `control_status` to DDB can stop a running Worker at the next checkpoint** — no inter-process signalling needed.

### Convenience functions

- `create_workflow_engine(project_id, config=None) -> WorkflowEngine`
- `run_workflow(project_id, from_stage=None, to_completion=True, state=None) -> ExecutionResult`
- `run_workflow_legacy(user_input, session_id=None, project_id=None) -> Dict[str, Any]` — returns the old `agent_build_workflow.run_workflow()` shape (`session_id`, `execution_time`, `execution_order`, …).

## V2 Engine: `WorkflowEngineV2` (`engine_v2.py`)

Core V2 differences: **runs exactly one stage, returns a `StageExecutionResult` with fork/join signals, and the outer Worker dispatches the next SQS message based on those signals**.

### `StageExecutionResult`

```
@dataclass
class StageExecutionResult:
    success: bool = False
    stage_name: str = ""
    agent_id: Optional[str] = None
    stage_result: Dict[str, Any] = field(default_factory=dict)
    raw_output: str = ""
    metrics: Dict[str, Any] = field(default_factory=dict)
    error_message: Optional[str] = None
    retry_count: int = 0
    # Fork/Join
    should_fork: bool = False
    fork_targets: List[Dict[str, Any]] = field(default_factory=list)
    should_check_join: bool = False
    all_agents_completed: bool = False
```

### `WorkflowEngineV2.execute_stage` flow

```
execute_stage(stage_name, agent_id=None, agent_context=None)
 │
 ├─ self.workflow_config.get_stage(stage_name)        # validate stage exists
 ├─ stage_key = "{name}"  |  "{name}#{agent_id}"      # DDB primary key
 ├─ _mark_stage_running(stage_key, …)                 # status='running', started_at
 │
 ├─ agent_input = _build_agent_input(…)               # see below
 ├─ raw_output, metrics = _execute_agent(…)           # create_agent_from_prompt_template + agent(input)
 ├─ stage_result = _parse_and_validate_output(…)      # JSON parse, retry up to MAX_RETRY_ON_PARSE_FAILURE=3
 ├─ _update_project_from_stage_result(…)              # Worker-side deterministic ops (e.g. system_architecture mints agent_id)
 ├─ _save_stage_result(…)                             # persist to DDB stages
 │
 └─ return StageExecutionResult:
    - stage_config.fork_on_complete  → should_fork=True, fork_targets=_compute_fork_targets(stage_result)
    - stage_config.join_after_complete && agent_id → should_check_join=True,
         db.update_agents_completion(project_id, agent_id, 'completed')
         all_agents_completed = db.check_all_agents_completed(project_id)
```

### Rule-injection policy (`_build_agent_input`)

V2 loads JSON rules by `workflow_type` via `tools.system_tools.agent_build_workflow.build_workflow_v2_tools.get_base_rules(wf_type)`, then:

1. **`base` subtree**: always injected in full (for every stage).
2. **Workflow subtree (e.g. `agent_build`)**:
   - If `stage_config.rule_keys` is non-empty: inject **only** those keys (typical for `tools_development` / `prompt_development` / `code_development` — file-writing stages — with keys such as `directory_rules` / `generation_rules` / `cache_rules` / `external_resources` / `custom_rules`).
   - If `rule_keys` is empty: inject **every** key **except** `directory_rules` / `generation_rules` (typical for design stages).

### Context assembly (V2)

`_build_agent_input` concatenates in order:

1. **Base Rules** → `=== Base Rule: {key} ===\n{value}` for each key.
2. **Workflow rules** → `=== {wf_type} Rule: {key} ===\n{value}`.
3. **Prerequisite stage results**:
   - `scope == "project"` prerequisite: `db.get_stage(project_id, prereq)` to read `stage_result`.
   - `scope == "agent"` prerequisite: if the current stage is agent-scope, `db.get_stage_by_agent(project_id, prereq, agent_id)`; if the current stage is project-scope (e.g. `deployment`), `db.list_stages_by_prefix(project_id, prereq)` aggregates results across all Agents.
4. **Project Info**: `project_id` / `project_name_cn` / `project_name_en` / `requirement` / `workflow_type` / `deployment_type` / `architecture_type` / `agent_count` / `agent_ids`; `metadata` keys `skill_id` / `skill_name` / `dir_name` / `tool_name` are also forwarded.
5. **Source Agent Info** (only when `workflow_type == "agent_update"`): loads source Agent's `agent_id` / `agent_name_cn` / `agent_name_en` / `tools` / `capabilities` / `s3_prompt_path` / `s3_tools_path` / `s3_agent_path`, plus pre-generated `new_dir_name` / `new_prompt_path` / `new_s3_tools_path` / `new_s3_prompt_path` / `new_s3_agent_path`.
6. **Current Agent Info** (agent-scope stage): `agent_id` + any `agent_context` passed via SQS.

### Output parsing and retry

`_parse_and_validate_output(stage_name, raw_output, agent_input, stage_config)` attempts to extract JSON from `raw_output`; retries up to `MAX_RETRY_ON_PARSE_FAILURE = 3` times. Each retry recreates the Agent with a more specific "please emit valid JSON" instruction.

### Key internal methods

| Method | Responsibility |
|--------|----------------|
| `_build_stage_key` | `stage_name` + `#{agent_id}` (agent-scope) |
| `_mark_stage_running` | Writes/updates `stages`; syncs `projects.status='building'`, `current_stage` |
| `_mark_stage_failed` | Writes `status='failed'`, `completed_at`, `error_message` |
| `_execute_agent` | Calls `create_agent_from_prompt_template(agent_name=…, env="production")`; extracts metrics from `result.metrics.get_summary()`'s `accumulated_usage` / `tool_usage` / `accumulated_metrics` |
| `_compute_fork_targets` | Derives the set of agent-scope fan-out messages from `stage_result` |
| `_save_stage_result` | Persists `stage_result` + `raw_output` + `metrics` to DDB |
| `_update_project_from_stage_result` | Deterministic Worker-side ops — e.g. `system_architecture` mints an `agent_id` and registers to the `agents` table |

## Stage Executor: `StageExecutor` (`executor.py`)

V1 goes through `StageExecutor` for Agent creation, metrics collection, and generated-file scanning. V2 inlines these in `engine_v2._execute_agent`, but both paths ultimately call `nexus_utils.agent_factory.create_agent_from_prompt_template`.

### Constructor

```
StageExecutor(
    context: WorkflowContext,
    context_manager: Optional[WorkflowContextManager] = None,
    on_stage_start: Optional[Callable[[str], None]] = None,
    on_stage_complete: Optional[Callable[[str, StageOutput], None]] = None,
    on_stage_error: Optional[Callable[[str, Exception], None]] = None,
    enable_multi_agent: bool = True,
    workflow_type: str = "agent_build",
)
```

`_load_stage_prompt_mapping()` first calls `nexus_utils.workflow_config.get_workflow_config(workflow_type)`; on failure it falls back to `STAGE_PROMPT_MAPPING = get_prompt_path_mapping()` (default agent_build).

### `ITERATIVE_STAGES`

Imported from `api.v2.core.stage_config.ITERATIVE_STAGES`. Declares which stages must iterate per-Agent in multi-Agent projects; corresponds to `supports_iteration: true` in `workflows.yaml`.

### Key methods

| Method | Responsibility |
|--------|----------------|
| `should_iterate(stage_name)` | Returns `True` if stage is in `ITERATIVE_STAGES` and `multi_agent_iterator.is_multi_agent` |
| `create_agent(stage_name, state)` | Resolves `prompt_path` from mapping, calls `create_agent_from_prompt_template(agent_name=prompt_path, env="production", enable_logging=True, state={…, project_id, project_name})` |
| `format_context(stage_name)` | Delegates to `context.get_stage_context()` (rules + local docs + prerequisite outputs) |
| `execute_stage(stage_name, input_message=None, state=None)` | Main entry; goes to `_execute_iterative_stage` if `should_iterate`, otherwise `_execute_single_agent_stage` |
| `_collect_metrics(agent, execution_time, result)` | Prefers `result.metrics.accumulated_usage` for tokens; falls back to `agent.model.usage`. Reads `result.metrics.tool_metrics` for `tool_calls_count` and `agent.model.model_id` |
| `_scan_generated_files(stage_name)` | Recursively scans `projects/&lt;project_name&gt;/` (fallback `projects/&lt;project_id&gt;/`), produces `FileMetadata` with MD5 for each file |
| `_extract_output_content(result)` | Tries `result.content` / `.message` / `.text` / `str(result)` in order |
| `_extract_design_document(stage_name, content)` | `requirements_analysis` → markdown; `system_architecture` → extracts ```json block and validates with `json.loads`; `agent_design` → markdown |

## Context Manager: `WorkflowContextManager` (`context.py`)

### Public API

| Method | Responsibility |
|--------|----------------|
| `load_from_db(project_id) -> WorkflowContext` | Rebuilds `WorkflowContext` from `projects` + `stages`; loads base rules from `config/nexus_ai_base_rule.yaml`; parses `IntentRecognitionResult` from the `orchestrator` stage output |
| `save_to_db(context)` | Re-reads `control_status` from DDB before writing to avoid overwriting user pause/stop; maps `StageStatus` → `ProjectStatus` (`RUNNING→building`, `COMPLETED→completed`, `FAILED→failed`, `PAUSED→paused`); then bulk-calls `update_stage` for each completed stage |
| `get_stage_context(context, stage_name, include_rules=True, include_local_docs=True, max_tokens=DEFAULT_MAX_CONTEXT_TOKENS)` | Produces the final prompt string handed to the Agent |
| `_load_workflow_rules()` | Reads `config/nexus_ai_base_rule.yaml`, caches the result |
| `_parse_intent_result(content)` | Regex-extracts `agent_name`; if content contains `multi` + `agent` keywords, `workflow_type="multi_agent"` |

### Context formatting (V1)

`get_stage_context` concatenates in order (compatible with the legacy `agent_build_workflow.py` format `base_context + "\n===\n{Agent} Agent: " + content + "\n===\n"`):

1. `# Build Workflow Kickoff\n## 必须严格遵守的规则:\n{rules}` (Req 9.1)
2. `## 项目名称约束` (if `project_name` is set)
3. `## 意图识别结果\n{intent_result JSON}` (Req 9.4)
4. `## 用户原始输入\n{requirement}` (Req 9.3)
5. `请按顺序完成构建流程，遵守以上规则。`
6. For each prerequisite `completed_stage`, appends `\n===\n{Agent Name} Agent: {content}\n===\n` (Req 9.2); if `estimate_tokens(content) > tokens_per_stage`, calls `summarize_stage_output()` (Req 9.7)
7. **Local documents** (Req 9.5): if remaining token budget > 1000, `_load_local_documents(project_id, project_name)` reads documents from the project directory

### Token estimation and summarization

```
DEFAULT_MAX_CONTEXT_TOKENS = 100000
CHARS_PER_TOKEN = 4   # empirical for mixed CN/EN

estimate_tokens(text) -> int                    # len(text) // 4
truncate_to_tokens(text, max_tokens) -> str     # char truncate + "\n\n... [内容已截断] ..."
summarize_stage_output(content, max_tokens=2000) -> str
    # keep titles and section headers
    # keep first 10 lines of each code block
    # if still too long, truncate_to_tokens
```

## Multi-Agent Iteration (`multi_agent.py`)

### `MultiAgentIterator`

Parses the multi-Agent architecture from the `system_architecture` stage output and iterates all Agents in dependency order:

| Method | Responsibility |
|--------|----------------|
| `architecture` (property) | Lazy calls `_parse_architecture()` |
| `is_multi_agent` (property) | `architecture.agent_count > 1` |
| `_parse_architecture()` | First tries `_parse_json_architecture` (matches ```json block with `agents` array); falls back to `_parse_markdown_architecture` (three regexes: `## Agent: name` / `- **name**: desc` / `\| name \| type \| desc \|`) |
| `get_agents_for_stage(stage_name)` | `[]` if stage not in `ITERATIVE_STAGES`; otherwise `_sort_agents_by_dependency()` |
| `_sort_agents_by_dependency()` | Simple topological sort; falls back to insertion order on cycles |
| `format_agent_context(agent, stage_name, base_context)` | Appends `## 当前处理的 Agent` block and `## 其他 Agent` listing |
| `get_progress(agent_name) -> AgentStageProgress` | Lazy-creates a progress record per Agent |
| `update_progress(agent_name, stage_name, status)` | Maps stage name to progress stage via `STAGE_TO_PROGRESS_STAGE` (e.g. `tools_developer → tool_development`), updates status |
| `is_stage_complete_for_all_agents(stage_name)` | Returns `True` only if every Agent's progress for that stage is COMPLETED |
| `get_next_agent_for_stage(stage_name)` | Returns the first Agent (in dependency order) not yet completed at that stage |

`STAGE_TO_PROGRESS_STAGE`:

```
"agent_design"         -> "agent_design"
"tools_developer"      -> "tool_development"
"prompt_engineer"      -> "prompt_engineering"
"agent_code_developer" -> "code_development"
```

### `MultiAgentStageExecutor`

| Method | Responsibility |
|--------|----------------|
| `should_iterate(stage_name)` | `iterator.is_multi_agent and stage_name in MultiAgentIterator.ITERATIVE_STAGES` |
| `execute_for_agent(stage_name, agent, base_executor, base_context, state=None)` | Formats Agent context; injects `state['current_agent'] / 'agent_type' / 'is_multi_agent' / 'total_agents'`; calls `base_executor.execute_stage(stage_name, input_message=agent_context, state=…)` |
| `execute_iterative_stage(stage_name, base_executor, base_context, state=None) -> StageOutput` | Gets `agents` (dependency-sorted), calls `execute_for_agent` for each, then `_merge_outputs` combines them into a single `StageOutput` (content concatenation, metric accumulation) |

## Validators

### `PromptValidator` (`validator.py`)

| Method | Responsibility |
|--------|----------------|
| `validate_tool_paths(prompt_path, strict=False)` | Reads prompt YAML, extracts `metadata.tools_dependencies` + `versions[].tools`, checks each via `_check_tool_exists`; by default treats misses as warnings, `strict=True` elevates to errors |
| `validate_all_workflow_prompts()` | Iterates `STAGE_PROMPT_MAPPING`, runs `validate_tool_paths` per stage |
| `_check_tool_exists(tool_path)` | Dispatches by prefix: `strands_tools/` → `strands_agents.tools`; `system_tools/` → `tools.system_tools.…`; `generated_tools/` → `tools.generated_tools.…`; `template_tools/` → `tools.template_tools.…` |

### `DocumentValidator`

Per-stage expected document format:

| Stage | Format | Required fields / sections / patterns |
|-------|--------|----------------------------------------|
| `requirements_analysis` | markdown | `需求概述` / `功能需求` / `非功能需求` |
| `system_architecture` | json | `architecture_type` / `components` |
| `agent_design` | markdown | `Agent 设计` / `能力定义` |
| `tools_developer` | python | `@tool` / `def\s+\w+` |
| `prompt_engineer` | yaml | `agent` / `name` / `system_prompt` |
| `agent_code_developer` | python | `from\s+nexus_utils` / `create_agent` |

### `AgentValidator` (`agent_validator.py`)

Three self-checks run after an Agent is generated:

| Method | Checks |
|--------|--------|
| `validate_prompt_path()` | Prompt file exists; YAML parses; contains `agent.name` / `agent.description` (absence → warning); `agent.versions[*]` has at least one entry with `system_prompt` |
| `validate_tool_dependencies()` | Per-tool `_validate_single_tool`: strands built-ins via `hasattr(strands_tools, name)`; `system_tools/` or `generated_tools/` — probe `tools/&lt;dir&gt;/&lt;parts&gt;` on disk |
| `validate_agent_factory()` | Actually calls `create_agent_from_prompt_template(agent_name=f"generated_agents_prompts/{project_name}", env="production")`, validates the returned object is callable |

Returns `AgentValidationResult` (with `issues: List[ValidationIssue]`, `error_count` / `warning_count` / `prompt_path_valid` / `tools_valid` / `factory_valid`).

## File Sync (`file_sync.py`)

| Class | Responsibility |
|-------|----------------|
| `FileSyncConfig` | S3 bucket (default `nexus-ai-workflow-files`), prefix (`workflow-files/`), `local_base_path`, `auto_sync` |
| `FileMetadataManager` | `scan_project_files(project_id, project_name)` walks `projects/&lt;name&gt;/` (fallback `projects/&lt;id&gt;/`), producing `FileMetadata` with MD5; `save_file_metadata(project_id, stage_name, files)` writes into `stages.generated_files`; `get_file_content(project_id, file_path, project_name=None)` reads text or falls back to base64 |
| `FileSyncManager` | `sync_to_s3(project_id, project_name, files=None)` uploads; `sync_from_s3(project_id, project_name, files=None)` downloads; S3 key: `{s3_prefix}{project_id}/{relative_path}` |

## Call Graph / Data Flow

### V1 end-to-end

```
CLI (run_workflow_v2.py) / API (v2/routers/*)
      │
      ▼
WorkflowEngine(project_id, config)
      │
      ├─ WorkflowContextManager.load_from_db(project_id)  ──► DDB projects + stages
      │                                                    │
      │                                                    ▼
      │                                           WorkflowContext
      │
      ├─ for stage in pending_stages:
      │     ├─ validate_prerequisites(stage)
      │     ├─ _check_control_signals()   ◄─ DDB.control_status
      │     └─ StageExecutor.execute_stage(stage)
      │           ├─ (multi-agent?) MultiAgentStageExecutor.execute_iterative_stage
      │           │      └─ for agent in sorted_agents: execute_for_agent
      │           │             └─ base_executor._execute_single_agent_stage
      │           │
      │           └─ _execute_single_agent_stage
      │                  ├─ create_agent(stage)  ──► agent_factory.create_agent_from_prompt_template
      │                  ├─ input_message = format_context(stage)
      │                  ├─ result = agent(input_message)
      │                  ├─ metrics = _collect_metrics(agent, t, result)
      │                  ├─ generated_files = _scan_generated_files(stage)
      │                  ├─ document = _extract_design_document(stage, output)
      │                  └─ context.update_stage_output(stage, output)
      │
      └─ save_to_db(context)  ──► DDB
```

### V2 single-stage (SQS-driven)

```
SQS Message { project_id, stage_name, agent_id? }
      │
      ▼
Worker process
      │
      ▼
WorkflowEngineV2(project_id).execute_stage(stage_name, agent_id, agent_context)
      │
      ├─ stage_config = workflow_config.get_stage(stage_name)
      ├─ _mark_stage_running(stage_key)    ──► DDB stages (status=running)
      ├─ agent_input = _build_agent_input(…)    ──► DDB (prerequisite stage_result) + rules JSON
      ├─ raw_output, metrics = _execute_agent(…)  ──► Agent Factory → Bedrock
      ├─ stage_result = _parse_and_validate_output(…, retry≤3)
      ├─ _update_project_from_stage_result(…)   (e.g. system_architecture mints agent_id)
      ├─ _save_stage_result(…)   ──► DDB stages (status=completed, stage_result JSON)
      │
      └─ return StageExecutionResult:
           ├─ should_fork?      → Worker dispatches N agent-scope SQS messages
           └─ should_check_join? → determine whether to fire the next project-scope stage
```

## Extending

### 1. Add a new workflow

Minimum changes:

1. **Add a top-level entry in `config/workflows.yaml`** modelled on `tool_build`: `name` / `display_name` / `description` / `version` / `enabled: true` / `prompt_base_path` / `stages[]` / `legacy_name_mapping`. Each stage needs at least `name` / `display_name` / `agent_display_name` / `prompt_file` / `order` / `scope` / `prerequisites` / `supports_iteration` / `optional` / `description`.
2. **Create a prompt YAML for each `stage.prompt_file`** at `prompts/{prompt_base_path}/{prompt_file}.yaml`.
3. **If base rules are needed**: add a corresponding branch in `tools.system_tools.agent_build_workflow.build_workflow_v2_tools.get_base_rules(wf_type)` and declare the sub-keys to inject via `rule_keys` on each stage.
4. **V1 entry**: `WorkflowEngine(project_id, config={'workflow_type': '&lt;new name&gt;'})` runs it as-is; no extra code.
5. **V2 entry**: the v2 Worker automatically routes based on `project.workflow_type`; no extra code.

### 2. Add a new stage

1. Insert a new entry in the workflow's `stages` array, set correct `order` and `prerequisites`.
2. Create `prompts/{prompt_base_path}/{prompt_file}.yaml` with at least `agent.name` / `agent.description` and a `versions[]` entry (including `system_prompt`).
3. If the stage emits a **design document**: add `"&lt;stage_name&gt;": "&lt;format&gt;"` to the `design_stages` dict in `executor.py::_extract_design_document`.
4. If the stage writes files **outside `projects/&lt;name&gt;/`**, adjust the scan root in `executor.py::_scan_generated_files`.
5. If the output needs **format validation**: add a rule to `validator.py::DocumentValidator.STAGE_DOCUMENT_FORMATS`.
6. If the stage is a **multi-Agent iteration stage**: add the stage name to `api.v2.core.stage_config.ITERATIVE_STAGES` and add a mapping to `multi_agent.py::MultiAgentIterator.STAGE_TO_PROGRESS_STAGE`.
7. If the stage has **fork/join** semantics (V2): set `fork_on_complete: true` or `join_after_complete: true` / `join_before_start: true` on the stage entry; the concrete fork targets go in `engine_v2._compute_fork_targets` (reading the current `stage_result`).

### 3. Add an Agent to an existing multi-Agent architecture

No code changes required. The `system_architecture` Agent simply emits the new Agent's `{name, type, description, dependencies, tools, orchestration_pattern}` in its output JSON; `MultiAgentIterator._parse_json_architecture` picks it up; subsequent `agent_design` / `tools_development` / `prompt_development` / `code_development` stages iterate over it automatically.

### 4. Add an "iterative" stage

V1: add the stage name to `api.v2.core.stage_config.ITERATIVE_STAGES`. V2: set `supports_iteration: true` and `scope: agent` in `workflows.yaml`; the Worker iterates through `agent_ids`.

### 5. Wire up callbacks

In V1:

```python
engine = WorkflowEngine(project_id)
engine.set_callbacks(
    on_stage_start=lambda name: ...,
    on_stage_complete=lambda name, output: ...,
    on_stage_error=lambda name, err: ...,
)
```

V2 does not support process-level callbacks; Workers watch DDB changes or subscribe to SQS status messages.

### 6. Constraints and pitfalls

- **DDB is the source of truth**: V1's `control_status` / `stage_result` are authoritative in DDB; in-memory state is a cache. Pause/resume/stop are DDB writes.
- **Rule injection**: if a new workflow's stage declares `rule_keys: []` (empty), V2 falls into the "inject all workflow rules **except** `directory_rules` / `generation_rules`" branch — that is the design-stage semantics; you cannot use an empty array to mean "no rules".
- **Context budget**: `get_stage_context` gives each prerequisite stage `remaining_tokens / len(relevant_stages)`; anything larger goes through `summarize_stage_output`, which keeps only titles and the first 10 lines of code blocks. Large-output stages (e.g. `requirements_analysis`) are only **partially visible** downstream.
- **`StageOutput.content` > 400KB**: the outer layer must write the content to S3 and populate `s3_content_ref`; `to_dict()` zeros out `content` when `s3_content_ref` is set.
- **`legacy_name_mapping`**: used to bridge V1→V2 for old data; new code should use V2 stage names directly (e.g. `tools_development`, not `tool_developer`).

## Debugging / Troubleshooting

| Symptom | Key log | Diagnosis |
|---------|---------|-----------|
| Stage stuck in `pending` | — | Check `prerequisites`: `WorkflowEngine.validate_prerequisites` logs `logger.warning` before raising `PrerequisiteError`; verify prerequisite stages are `completed` in the `stages` DDB table |
| Stage "pauses" immediately after completing | `Workflow paused after stage: {name}` | `_refresh_control_status()` read `control_status=paused` from DDB; check `projects.control_status` |
| Agent output fails to parse | `[V2] Stage {name}: raw_output type=…` + `Failed to extract detailed metrics` | V2 retries up to `MAX_RETRY_ON_PARSE_FAILURE=3`; after the 3rd attempt `_parse_and_validate_output` raises → stage `failed` |
| Multi-Agent architecture not detected | `Failed to parse JSON architecture` / `Failed to parse markdown architecture` | `system_architecture` output must be valid JSON or match one of three regexes in `_parse_markdown_architecture` |
| `Failed to create agent from template` | `Failed to create agent for stage {name}` | Prompt path missing or YAML invalid; reproduce with `AgentValidator.validate_prompt_path()` |
| Tool-path validation fails | `[TOOL_NOT_FOUND] {path}: …` | Run `validate_workflow_prompts()` to print every missing tool per stage |
| Token over budget | `Stage {name} output summarized: X -> Y tokens` | Normal summarization; if critical info gets dropped, raise `DEFAULT_MAX_CONTEXT_TOKENS` or reduce prerequisites |
| V2 fork produced an agent stage that never runs | none | Check the SQS dead-letter queue; verify `_compute_fork_targets(stage_result)` returned that agent; verify `agent_id` was registered in the `agents` table |

## Code-Snippet Index

| What to look for | Location |
|------------------|----------|
| Stage execution main loop | `nexus_utils/workflow/engine.py::WorkflowEngine.execute_from_stage` |
| V2 single-stage execution | `nexus_utils/workflow/engine_v2.py::WorkflowEngineV2.execute_stage` |
| Context assembly | `nexus_utils/workflow/context.py::WorkflowContextManager.get_stage_context` |
| Agent creation | `nexus_utils/workflow/executor.py::StageExecutor.create_agent` |
| Multi-Agent architecture parsing | `nexus_utils/workflow/multi_agent.py::MultiAgentIterator._parse_json_architecture` / `_parse_markdown_architecture` |
| Multi-Agent iteration | `nexus_utils/workflow/multi_agent.py::MultiAgentStageExecutor.execute_iterative_stage` |
| Token summarization | `nexus_utils/workflow/context.py::summarize_stage_output` |
| Fork-target computation | `nexus_utils/workflow/engine_v2.py::_compute_fork_targets` |
| V2 rule injection | `nexus_utils/workflow/engine_v2.py::_build_agent_input` |
| Stage prompt mapping | `api/v2/core/stage_config.py` (external module imported by `executor.py` and `context.py`) |
| Post-generation Agent self-check | `nexus_utils/workflow/agent_validator.py::AgentValidator.validate_all` |

## Further Reading

- [Architecture Overview](./architecture-overview.md) — overall project architecture and subsystem relationships
- [Worker Subsystem](./worker.md) — the V2 SQS + fork/join outer scheduler
- [API Layer](./api-layer.md) — how v2 REST APIs trigger `WorkflowEngine` and write `control_status`
- [Contributing Guide](./contributing.md) — development environment, testing, commit conventions
