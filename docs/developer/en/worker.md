---
title: Worker
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - config/workflows.yaml
    - nexus_utils/workflow/**
    - worker/**
  generated_at: 2026-05-09T00:05:17+00:00
  generated_by: docs-sync v2
---

# Worker

## Overview

The Worker is Nexus-AI's background executor process. It long-polls messages from SQS, parses workflow tasks, invokes `WorkflowEngine` / `WorkflowEngineV2` to run a single stage or a full pipeline, and persists results back to DynamoDB and S3. The Worker exposes no HTTP surface and does not participate in API request handling — it is a **pure consumer** process.

- **Entry point:** `python -m worker.main [--queue build|deploy] [--once]` (`worker/main.py:2652`).
- **Message source:** listens on `SQS_BUILD_QUEUE_NAME` by default (optionally `SQS_DEPLOY_QUEUE_NAME`).
- **Core call stack:** `Worker._poll_and_process` → `Worker._process_message` → `WorkflowHandler.handle` → `BuildHandlerV2 / BuildHandler / MetricsRollupHandler / QuotaCheckHandler` → `WorkflowEngineV2 / WorkflowEngine` → `StageExecutor` → Agent (via `nexus_utils.agent_factory.create_agent_from_prompt_template`).
- **Workflow boundary:** the Worker **executes and dispatches** only. It does not decide which stages exist — stage definitions live in `config/workflows.yaml` and are loaded via `nexus_utils.workflow_config.get_workflow_config(workflow_type)`.

Two execution models coexist:

| Model | Entry handler | Engine | Stage execution | Trigger |
|-------|---------------|--------|-----------------|---------|
| V1 | `BuildHandler` / `WorkflowHandler._handle_agent_build` | `WorkflowEngine` | One message runs the full workflow (`execute_to_completion`) | Single API request → enqueue |
| V2 | `BuildHandlerV2` | `WorkflowEngineV2` | Each message runs **one** `stage`; on completion re-enqueues next stage according to `fork_on_complete` / `join_after_complete` | `workflow_type in {agent_build, agent_update, skill_build, tool_build}` and message contains `stage` field |

V1 is retained mainly for legacy messages and regression tests; all new workflows (`agent_build` V2, `agent_update`, `tool_build`, `skill_build`, `magician`) run on V2.

## File Layout

### `worker/` — process entry and message scheduling

| Path | Responsibility | Dependencies |
|------|----------------|--------------|
| `worker/__init__.py` | Declares `__version__ = "2.0.0"` | — |
| `worker/config.py` | `WorkerSettings` (pydantic BaseSettings) aggregating AWS/SQS/DynamoDB/runtime config; `get_worker_settings` with `lru_cache` | `nexus_utils.config_loader.get_config`, `pydantic_settings` |
| `worker/main.py` | `Worker` main loop, signal handling, heartbeat, argparse | `api.v2.database.sqs_client`, `worker.handlers.workflow_handler.WorkflowHandler`, `nexus_utils.observability` |
| `worker/handlers/__init__.py` | Re-exports `BuildHandler` only (back-compat) | — |
| `worker/handlers/build_handler.py` | V1 build handler wrapping `WorkflowEngine.execute_to_completion` et al. | `nexus_utils.workflow`, `api.v2.database.db_client`, `api.v2.models.schemas` |
| `worker/handlers/build_handler_v2.py` | V2 single-stage handler with fork/join dispatch | `nexus_utils.workflow.engine_v2.WorkflowEngineV2`, `api.v2.database.sqs.SQSClient` |
| `worker/handlers/workflow_handler.py` | Routes by `workflow_type` / `task_type` to the right handler; this is the only `Worker.handler` implementation | All handlers above |
| `worker/handlers/metrics_rollup_handler.py` | Rolls CloudWatch metrics into Aurora `agent_metrics_hourly` / `user_metrics_daily` | `api.v2.database.aurora.pg_client`, boto3 CloudWatch |
| `worker/handlers/quota_check_handler.py` | Checks quota exceedances, writes `quota_alerts`, notifies via SNS | `api.v2.database.aurora.pg_client`, boto3 SNS, `nexus_utils.observability.logging.security_log` |

### `nexus_utils/workflow/` — execution engine and data models

| Path | Responsibility | Main exports |
|------|----------------|--------------|
| `__init__.py` | Unified re-export façade | `WorkflowEngine`, `ExecutionResult`, `WorkflowControlSignal`, `PrerequisiteError`, `StageExecutor`, `StageOutput`, `StageStatus`, `ControlStatus`, `StageMetrics`, `MultiAgentIterator`, `AgentValidator`, `FileSyncManager`, … |
| `models.py` | Core dataclasses and enums | `StageStatus`, `ControlStatus`, `StageMetrics`, `FileMetadata`, `StageOutput`, `WorkflowContext`, `IntentRecognitionResult`, `AgentDefinition`, `MultiAgentArchitecture`, `AgentStageProgress`, `AggregatedMetrics`, `STAGE_ORDER` (lazy) |
| `context.py` | Load/save `WorkflowContext` from DynamoDB; assemble stage prompt context | `WorkflowContextManager`, `get_stage_context`, `estimate_tokens`, `truncate_to_tokens`, `summarize_stage_output`, `DEFAULT_MAX_CONTEXT_TOKENS` |
| `executor.py` | V1 single-stage executor: creates Agent, collects metrics, scans generated files | `StageExecutor`, `StageExecutionError`, `execute_stage`, `STAGE_PROMPT_MAPPING` |
| `engine.py` | V1 workflow engine running stages sequentially; exposes pause/resume/stop | `WorkflowEngine`, `ExecutionResult`, `WorkflowControlSignal`, `PrerequisiteError`, `create_workflow_engine`, `run_workflow`, `run_workflow_legacy` |
| `engine_v2.py` | V2 single-stage engine; assembles Agent input, parses JSON, emits fork/join signals | `WorkflowEngineV2`, `StageExecutionResult`, `MAX_RETRY_ON_PARSE_FAILURE` |
| `multi_agent.py` | Iterator/executor for multi-agent projects (V1 architecture) | `MultiAgentIterator`, `MultiAgentStageExecutor`, `create_multi_agent_iterator`, `is_multi_agent_project`, `get_multi_agent_progress` |
| `validator.py` | Prompt tool-path and document-format validation | `PromptValidator`, `DocumentValidator`, `ValidationResult`, `ValidationError`, `validate_workflow_prompts`, `validate_tool_path`, `validate_document` |
| `agent_validator.py` | Post-generation prompt/tools/factory validation triplet | `AgentValidator`, `AgentValidationResult`, `ValidationIssue`, `ValidationLevel`, `validate_agent`, `validate_multiple_agents` |
| `file_sync.py` | Project directory scan and cross-Worker file sync | `FileMetadataManager`, `FileSyncManager`, `FileSyncConfig`, `scan_and_save_files`, `get_file_content`, `sync_project_files` |

### `config/workflows.yaml` — workflow definitions

Defines 5 workflows: `agent_build`, `agent_update`, `tool_build`, `skill_build`, `magician`. All Worker/Engine code treats this file as the single source of truth, read via `nexus_utils.workflow_config.get_workflow_config(workflow_type)`.

## Core Types and Data Structures

### `WorkerSettings` (`worker/config.py:66`)

Derives from `pydantic_settings.BaseSettings`. Read order: **environment variables > `default_config.yaml` > literal defaults**.

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `WORKER_ID` | `str` | `f"worker-{os.getpid()}"` | Worker identifier, used as DynamoDB `worker_id` field |
| `AWS_REGION` | `str` | `_aws_config.get('aws_region_name', 'us-west-2')` | AWS region |
| `AWS_ACCESS_KEY_ID` | `Optional[str]` | `None` | Explicit credentials; `None` falls back to default chain |
| `AWS_SECRET_ACCESS_KEY` | `Optional[str]` | `None` | Same |
| `DYNAMODB_ENDPOINT_URL` | `Optional[str]` | `_aws_config.get('endpoint_url')` | For LocalStack etc. |
| `DYNAMODB_TABLE_PREFIX` | `str` | `'nexus_'` | Prefix, concatenated into full table names |
| `SQS_ENDPOINT_URL` | `Optional[str]` | `_aws_config.get('endpoint_url')` | SQS mock endpoint |
| `SQS_BUILD_QUEUE_NAME` | `str` | `_sqs_queues.get('build', 'nexus-build-queue')` | Build task queue |
| `SQS_DEPLOY_QUEUE_NAME` | `str` | `_sqs_queues.get('deploy', 'nexus-deploy-queue')` | Deploy task queue |
| `POLL_INTERVAL_SECONDS` | `int` | `5` | SQS long-poll `wait_time_seconds` |
| `MAX_MESSAGES_PER_POLL` | `int` | `1` | `receive_messages` batch size |
| `VISIBILITY_TIMEOUT` | `int` | `_sqs_config.get('build_visibility_timeout', 3600)` | Initial visibility; heartbeat extends it |
| `HEARTBEAT_INTERVAL` | `int` | `300` | Heartbeat interval (5 minutes) |
| `MAX_RETRY_COUNT` | `int` | `_sqs_config.get('max_retry_count', 3)` | SQS max redelivery count |
| `BUILD_TIMEOUT_SECONDS` | `int` | `7200` | Overall build timeout (2 hours) |
| `LOG_LEVEL` | `str` | `_logging_config.get('level', 'INFO')` | Root logger level |

Instantiation goes through `get_worker_settings()` (`worker/config.py:105`), which is `@lru_cache()`-wrapped.

### `Worker` (`worker/main.py:2448`)

```python
class Worker:
    queue_type: str         # "build" | "deploy"
    worker_id: str          # worker_settings.WORKER_ID
    queue_name: str         # selected by queue_type
    handler: WorkflowHandler | None   # deploy queue has no handler yet
    visibility_timeout: int # build: worker_settings.VISIBILITY_TIMEOUT; deploy: 600
    running: bool
    _shutdown_event: threading.Event
```

### `StageStatus` / `ControlStatus` (`nexus_utils/workflow/models.py:6503`, `:6523`)

```python
class StageStatus(Enum):
    PENDING   = "pending"
    RUNNING   = "running"
    COMPLETED = "completed"
    FAILED    = "failed"
    PAUSED    = "paused"

class ControlStatus(Enum):
    RUNNING   = "running"
    PAUSED    = "paused"
    STOPPED   = "stopped"
    CANCELLED = "cancelled"
```

### `StageMetrics` (`nexus_utils/workflow/models.py:6541`)

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `input_tokens` | `int` | `0` | Accumulated input tokens |
| `output_tokens` | `int` | `0` | Accumulated output tokens |
| `execution_time_seconds` | `float` | `0.0` | Stage elapsed time |
| `tool_calls_count` | `int` | `0` | Tool-call count |
| `model_id` | `Optional[str]` | `None` | Model ID |

`total_tokens` is a property (`input_tokens + output_tokens`).

### `FileMetadata` (`nexus_utils/workflow/models.py:6609`)

| Field | Type | Notes |
|-------|------|-------|
| `path` | `str` | Path relative to `projects/&lt;agent_name&gt;/` |
| `size` | `int` | Bytes |
| `checksum` | `Optional[str]` | MD5 |
| `last_modified` | `Optional[datetime]` | Modification time |

### `StageOutput` (`nexus_utils/workflow/models.py:6664`)

| Field | Type | Notes |
|-------|------|-------|
| `stage_name` | `str` | Stage name |
| `content` | `str` | Agent output (≤ `MAX_CONTENT_SIZE = 400*1024`) |
| `metrics` | `StageMetrics` | Execution metrics |
| `generated_files` | `List[FileMetadata]` | Files produced |
| `document_content` | `str` | Design document body |
| `document_format` | `str` | `"markdown"` / `"json"` / `"yaml"` / `"python"` |
| `completed_at` | `Optional[datetime]` | Completion timestamp |
| `status` | `StageStatus` | Stage status |
| `error_message` | `Optional[str]` | Error text on failure |
| `s3_content_ref` | `Optional[str]` | S3 reference when content exceeds 400 KB |

### `ExecutionResult` (`nexus_utils/workflow/engine.py:4085`, V1)

| Field | Type | Notes |
|-------|------|-------|
| `success` | `bool` | Whether the whole run succeeded |
| `completed_stages` | `List[str]` | Stages completed in this run |
| `failed_stage` | `Optional[str]` | Failed stage name (if any) |
| `error_message` | `Optional[str]` | Error text |
| `final_status` | `StageStatus` | Final status |
| `metrics` | `Dict[str, Any]` | Aggregated metrics |

### `StageExecutionResult` (`nexus_utils/workflow/engine_v2.py:4751`, V2)

| Field | Type | Notes |
|-------|------|-------|
| `success` | `bool` | Whether this stage succeeded |
| `stage_name` | `str` | Stage name |
| `agent_id` | `Optional[str]` | `agent_id` for agent-scope stages |
| `stage_result` | `Dict[str, Any]` | Parsed JSON result |
| `raw_output` | `str` | Raw Agent output |
| `metrics` | `Dict[str, Any]` | Tokens / timing etc. |
| `error_message` | `Optional[str]` | Failure reason |
| `retry_count` | `int` | JSON-parse retry counter |
| `should_fork` | `bool` | Whether to fork for the next stage |
| `fork_targets` | `List[Dict[str, Any]]` | Fork targets (each with `agent_id` / `agent_type` / `agent_context` / `architecture_type`) |
| `should_check_join` | `bool` | Whether to run a join check after an agent-scope stage |
| `all_agents_completed` | `bool` | Whether all agents finished (for join) |

### `WorkflowContext` (`nexus_utils/workflow/models.py`, assembled by `context.py:3614` `load_from_db`)

Holds `project_id`, `project_name`, `requirement`, `intent_result`, `stage_outputs`, `rules`, `current_stage`, `status`, `aggregated_metrics`, `created_at`, `updated_at`, `control_status`, `pause_requested_at`, `stop_requested_at`, `resume_from_stage`, `workflow_type`. Persisted by `WorkflowContextManager.save_to_db`.

### Other structures

- `AgentDefinition` (`models.py:6860`): a single Agent in a multi-agent architecture (`name / agent_type ∈ {main,sub,tool} / description / orchestration_pattern ∈ {agent_as_tool,swarm,graph} / dependencies / tools / status`).
- `MultiAgentArchitecture` (`models.py:6915`): holds `agents / orchestration_pattern / main_agent`; derives `agent_count`.
- `AgentStageProgress` (`models.py:6977`): per-Agent progress across a fixed 5-stage pipeline (`agent_design`, `tool_development`, `prompt_engineering`, `code_development`, `testing`).
- `AggregatedMetrics` (`models.py:7055`): project-level accumulators (`total_input_tokens / total_output_tokens / total_tokens / total_cost / total_execution_time / total_tool_calls`).
- `IntentRecognitionResult` (`models.py:6791`): orchestrator output (`agent_name / workflow_type ∈ {single_agent, multi_agent} / complexity / estimated_stages / key_features / tool_requirements / raw_analysis`).

### Exceptions and signals

| Class | Location | Meaning |
|-------|----------|---------|
| `WorkflowControlSignal` | `engine.py:4106` | Pause/stop signal, `signal_type ∈ {PAUSE, STOP}` |
| `PrerequisiteError` | `engine.py:4120` | Prerequisite stage not done; carries `missing_prerequisites` |
| `StageExecutionError` | `executor.py:5242` | Stage execution failure; carries `recoverable` flag |
| `ValidationError` | `validator.py:7840` | Tool-path / document validation error |
| `ValidationIssue` (`Level: ERROR/WARNING/INFO`) | `agent_validator.py:2944` | Per-issue record in Agent validation |

## Message Protocols

### V2 build message (`BuildHandlerV2.handle`)

```json
{
  "project_id": "<uuid>",
  "workflow_type": "agent_build" | "agent_update" | "skill_build" | "tool_build",
  "stage": "<stage_name>",
  "action": "execute",
  "agent_id": "<uuid | null>",
  "agent_type": "<type | null>",
  "architecture_type": "<type | null>",
  "agent_context": { ... },
  "user_id": "<uuid | null>",
  "metadata": { ... },

  "_trace_carrier": { "traceparent": "...", "tracestate": "...", "X-Amzn-Trace-Id": "..." },
  "_trace_parent":  "<trace_id_hex>"
}
```

- Presence of `stage` marks a V2 message (`WorkflowHandler.handle` sets `is_v2 = bool(stage)`).
- `agent_id` is `"project"` or omitted for project-scope stages; required for agent-scope stages.
- `_trace_carrier` is a full W3C context. Legacy messages degrade to `_trace_parent` (trace_id hex only), attached as a weak `opentelemetry.trace.Link`.

### V1 build message (`BuildHandler.handle`)

```json
{
  "task_id": "<uuid>",
  "project_id": "<uuid>",
  "requirement": "<user requirement text>",
  "target_stage": "<stage_name | null>",
  "execute_to_completion": true,
  "action": "execute" | "resume" | "restart",
  "metadata": { ... }
}
```

### Operations messages

`metrics_rollup`:

```json
{ "task_type": "metrics_rollup",
  "rollup_type": "hourly" | "daily" | "monthly",
  "target_hour":  "2026-04-30T12:00:00Z"   // optional
}
```

`quota_check`:

```json
{ "task_type": "quota_check",
  "month": "2026-04-01"   // optional, defaults to current month
}
```

## Key Functions and Methods

### `worker/main.py`

| Name | Signature | Responsibility | Notes |
|------|-----------|----------------|-------|
| `Worker.__init__` | `(queue_type: str = "build")` | Selects queue name, visibility timeout and handler. `build` → `WorkflowHandler`; `deploy` → `None` (placeholder) | Raises `ValueError` on unknown queue_type |
| `Worker.start` | `(once: bool = False) -> None` | Registers `SIGINT`/`SIGTERM`, loops `_poll_and_process`; `once=True` exits after the first poll | Second signal forces `sys.exit(1)` |
| `Worker.stop` | `() -> None` | Sets `running=False` + `_shutdown_event.set()` | — |
| `Worker._poll_and_process` | `() -> None` | `receive_messages(queue_name, max_messages, wait_time_seconds=POLL_INTERVAL_SECONDS, visibility_timeout)`; records `record_sqs_poll` | Empty poll prints `[POLL] ... : None` |
| `Worker._process_message` | `(message: dict) -> None` | Starts heartbeat thread → `handler.handle(message)` → `sqs_client.delete_message` on True; leaves to SQS on False | Records `record_sqs_message_processed(queue, success, duration)` |
| `Worker._start_heartbeat` | `(receipt_handle: str) -> HeartbeatThread` | Daemon thread that invokes `change_message_visibility` every `HEARTBEAT_INTERVAL` | Returns a custom `HeartbeatThread` with `cancel()` |
| `main` | `() -> None` | argparse `--queue / --once`, builds `Worker`, `start()` | — |

### `worker/handlers/workflow_handler.py::WorkflowHandler`

| Method | Signature | Responsibility |
|--------|-----------|----------------|
| `handle` | `(message: Dict) -> bool` | Reads `workflow_type`/`stage`, opens tracing span `workflow.&lt;wf&gt;[.stage]`, emits `record_build_started` on the first stage, then calls `_dispatch` |
| `_dispatch` | `(body, message, workflow_type, task_id, project_id, is_v2) -> bool` | Route: `metrics_rollup` / `quota_check` / V2 (`_handle_agent_build_v2`) / `agent_update` / `tool_build` / V1 `agent_build` |
| `_handle_agent_build_v2` | `(message) -> bool` | Delegates to `BuildHandlerV2().handle(message)` |
| `_handle_agent_build` | `(message) -> bool` | Delegates to `BuildHandler().handle(message)` (V1) |
| `_handle_agent_update` | `(message) -> bool` | V1 agent update; builds `WorkflowEngine` with `WorkflowType.AGENT_UPDATE`, runs to completion |
| `_handle_tool_build` | `(message) -> bool` | V1 tool build; uses `WorkflowType.TOOL_BUILD`, injects env vars `NEXUS_TOOL_NAME` / `NEXUS_TARGET_AGENT` |
| `_convert_execution_result` | `(result) -> Dict` | Translates V1 `ExecutionResult` to `{'status', 'success', 'completed_stages', 'failed_stage', 'error_message', 'metrics'}` |
| `_handle_execution_result` | `(task_id, project_id, result) -> bool` | Success/failed/paused/stopped branches: `_update_task_status` + `_update_project_status` + `emit_build_completed_from_project` |
| `_handle_execution_error` | `(task_id, project_id, error) -> bool` | Catches exceptions, updates `TaskStatus.FAILED` + `ProjectStatus.FAILED` |
| `_update_task_status` / `_update_project_status` | `(task_id/project_id, status, result/error_info, clear_error)` | Writes the `tasks` / `projects` DDB tables directly |

`WorkflowHandler.SUPPORTED_WORKFLOWS = ['agent_build', 'agent_update', 'tool_build', 'metrics_rollup', 'quota_check']` (`workflow_handler.py:1823`).

### `worker/handlers/build_handler.py::BuildHandler` (V1)

| Method | Signature | Responsibility |
|--------|-----------|----------------|
| `handle` | `(message: Dict) -> bool` | Validate fields → dedupe (`status ∈ {building, completed}` returns True immediately) → `_check_resume_state` → `_update_task_status(RUNNING)` + `_update_project_status(BUILDING, clear_error=True)` → `_execute_with_workflow_engine` → branch on `status` |
| `_execute_with_workflow_engine` | `(project_id, requirement, target_stage, execute_to_completion, action, metadata)` | Sets `NEXUS_STAGE_TRACKER_PROJECT_ID`; `action` branches: `resume` → `engine.resume(from_stage) + execute_to_completion`; `restart` → `engine.execute_from_stage(target_stage, to_completion)`; default follows `target_stage` or `execute_to_completion` |
| `_convert_execution_result` | `(result)` | Same semantics as `WorkflowHandler._convert_execution_result` |
| `_check_resume_state` | `(project_id)` | Scans `list_stages`; earliest stage with `status ∈ {pending, failed, running}` becomes `resume_from_stage` |
| `_update_project_status` | `(project_id, status, error_info, clear_error)` | On failure records `resume_from_stage` so a later `action='resume'` can pick up |
| `_generate_workflow_report_and_sync` | `(project_id, project_name, result)` | Calls `generate_report_from_stages` + `collect_project_info_after_workflow` |
| `_sync_project_to_s3` | `(project_id, project_name)` | Syncs `projects/&lt;name&gt;` to S3 for multi-Worker topologies |

### `worker/handlers/build_handler_v2.py::BuildHandlerV2`

| Method | Signature | Responsibility |
|--------|-----------|----------------|
| `handle` | `(message) -> bool` | Extracts `project_id / stage / agent_id / agent_context / workflow_type` from `body`; extracts upstream trace context → `push_context(MetricContext)` → opens `worker.stage.&lt;stage&gt;` span → calls `_execute_stage` |
| `_execute_stage` | `(body, project_id, stage, agent_id, agent_context, trace_links)` | ① Pre-check project status `paused/cancelled` → return True to delete the message; ② stage status `completed/running` → skip; ③ for `deployment`, run `_sync_artifacts_to_local`; ④ `WorkflowEngineV2.execute_stage` → `build.record_stage`; ⑤ `_dispatch_next`; ⑥ deployment-class stages post-hooks (`_post_deployment` / `_post_skill_deployment` / `_post_tool_deployment` / `_post_update_deployment`) + `_update_project_on_completion` |
| `_dispatch_next` | `(project_id, current_stage, agent_id, result, original_body)` | Fork → send `agent_design` for each `fork_target`; Join → `deployment` when all done; sequential → `_get_next_stage` then `_send_stage_message` |
| `_get_next_stage` | `(current_stage, workflow_type='agent_build')` | Reads `workflow_config.get_stage_sequence()`; returns `None` if next stage has `join_before_start=True` (join driven) |
| `_send_stage_message` | `(project_id, stage, agent_id, agent_type, architecture_type, agent_context, original_body)` | Builds body + injects W3C `_trace_carrier` / `_trace_parent`; `SQSClient.send_message` with `message_attributes={task_type, stage}` |
| `_post_deployment` | `(project_id, result)` | ① `update_agent(status=running)`; ② pulls README from S3 to `projects/&lt;project_id&gt;/README.md`; ③ vector indexing (`_index_build_artifacts`); ④ `PromptManager.reload()` |
| `_post_skill_deployment` | `(project_id, result)` | `SkillManager.register_built_skill()` + local sync |

`MAX_RETRY_ON_PARSE_FAILURE = 3` (`engine_v2.py:4748`) — JSON-parse retries happen inside `WorkflowEngineV2._parse_and_validate_output`.

### `worker/handlers/metrics_rollup_handler.py::MetricsRollupHandler`

| Method | Signature | Responsibility |
|--------|-----------|----------------|
| `handle` | `(message) -> bool` | Reads `rollup_type ∈ {hourly, daily, monthly}`; branches to `rollup_hourly/daily/monthly` |
| `rollup_hourly` | `(hour: datetime) -> int` | ① `_list_agent_ids` enumerates `agent_id` values → batch `_query_many_agent_metrics` → `_upsert_hourly`; ② `_list_dim_values(ns, "agent.invocations", "user_id")` → `_query_many_user_metrics` → `_upsert_user_daily` |
| `_query_agent_batch` | `(cw, ns, start, end, agent_ids: List[str])` | One `CloudWatch:GetMetricData` fetches `len(agent_ids)*10` metrics (`inv/d50/d90/d99/err/tc/tki/tko/tcr/tcw`); demultiplexed by `"&lt;prefix&gt;_&lt;idx&gt;"` Id. Batch size `_GMD_BATCH_LIMIT // per_agent`, `_GMD_BATCH_LIMIT = 500` |
| `_agent_metric_queries` | `(ns, agent_id, idx)` | Builds the 10 MetricDataQuery entries for one agent with base dimensions `{OTelLib=nexus-ai, agent_id}`; tokens also carry `direction ∈ {input, output, cache_read, cache_write}` |
| `_upsert_hourly` / `_upsert_user_daily` | `(row)` | `INSERT ... ON CONFLICT` into `agent_metrics_hourly` / `user_metrics_daily` |

### `worker/handlers/quota_check_handler.py::QuotaCheckHandler`

| Method | Signature | Responsibility |
|--------|-----------|----------------|
| `handle` | `(message) -> bool` | Parses `month`; calls `_check_quotas` |
| `_check_quotas` | `(month: date) -> List[Dict]` | Joins `user_metrics_monthly × user_quotas` to compute `used_pct`; matches thresholds into `alert_type ∈ {exceeded, threshold_reached}`; checks `quota_alerts` for idempotency; inserts + `_send_notification` |
| `_send_notification` | `(user_id, alert_type, used_pct, cost, budget) -> channel` | Reads env `NEXUS_QUOTA_SNS_TOPIC`; prefers SNS + `security_log`; falls back to audit log only; returns `"sns"` or `"audit_log"` |

### `nexus_utils/workflow/engine.py::WorkflowEngine` (V1)

| Method | Signature | Responsibility |
|--------|-----------|----------------|
| `__init__` | `(project_id, config=None, db_client=None)` | Reads `config.workflow_type` (default `agent_build`); creates `WorkflowContextManager` |
| `load_context` | `() -> WorkflowContext` | Lazy load via `context_manager.load_from_db(project_id)` |
| `validate_prerequisites` | `(stage_name) -> bool` | Uses `context.get_prerequisite_stages`; raises `PrerequisiteError` on missing |
| `execute_single_stage` | `(stage_name, input_message=None, state=None, skip_validation=False) -> StageOutput` | Refresh control, mark running, execute; raises `WorkflowControlSignal(PAUSE/STOP)` based on `control_status` |
| `execute_from_stage` | `(stage_name, to_completion=True, state=None) -> ExecutionResult` | Runs `[stage_name, …]` sequentially; persists failure state on `StageExecutionError`/other exceptions and returns |
| `execute_to_completion` | `(state=None) -> ExecutionResult` | Starts from `context.get_next_stage()`; delegates to `execute_from_stage` |
| `pause` / `stop` / `resume` | `() -> bool` / `(from_stage=None) -> bool` | Writes `context.control_status`; toggles local `_pause_requested` / `_stop_requested` |
| `_check_control_signals` | `() -> None` | `_refresh_control_status` + raises `WorkflowControlSignal` |
| `_refresh_control_status` | `() -> None` | Re-reads `control_status` from DDB so the API side can remote-control via DDB |
| `get_status` | `() -> Dict` | Snapshot: `project_id / status / control_status / current_stage / completed_stages / pending_stages / aggregated_metrics` |

Module helpers: `create_workflow_engine(project_id, config)`, `run_workflow(project_id, from_stage, to_completion, state)`, `run_workflow_legacy(user_input, session_id, project_id)`.

### `nexus_utils/workflow/engine_v2.py::WorkflowEngineV2`

| Method | Signature | Responsibility |
|--------|-----------|----------------|
| `execute_stage` | `(stage_name, agent_id=None, agent_context=None) -> StageExecutionResult` | Main flow: load `stage_config` → `_mark_stage_running` → `_build_agent_input` → `_execute_agent` → `_parse_and_validate_output` (≤3 retries) → `_update_project_from_stage_result` → `_save_stage_result` → fill fork/join signals per `fork_on_complete` / `join_after_complete` |
| `_build_stage_key` | `(stage_name, agent_id)` | `"&lt;stage&gt;#&lt;agent_id&gt;"` when `agent_id` is set, else `"&lt;stage&gt;"` |
| `_build_agent_input` | `(stage_name, agent_id, agent_context)` | Concatenates base rules (`get_base_rules(wf_type)`) + workflow rules (filtered by `stage_config.rule_keys`) + prerequisite stage results (per `prerequisites + scope`) + Project Info + Source Agent Info (for `agent_update`) + Current Agent Info |
| `_execute_agent` | `(stage_name, agent_input, stage_config) -> (raw_output, metrics)` | Creates/invokes Agent via `create_agent_from_prompt_template(agent_name=&lt;prompt_base_path&gt;/&lt;prompt_file&gt;, env='production')`; extracts tokens from `metrics.get_summary().accumulated_usage` (`inputTokens/outputTokens`), `tool_usage.*.execution_stats.call_count`, `accumulated_metrics.latencyMs` |

### `nexus_utils/workflow/executor.py::StageExecutor` (V1)

| Method | Responsibility |
|--------|----------------|
| `create_agent(stage_name, state)` | Resolves prompt path via `_stage_prompt_mapping`; calls `create_agent_from_prompt_template` |
| `format_context(stage_name)` | Delegates to `get_stage_context(include_rules=True, include_local_docs=True)` |
| `execute_stage(stage_name, input_message=None, state=None)` | Delegates to `MultiAgentStageExecutor` for multi-agent; else creates Agent + invokes + collects metrics + scans generated files |
| `should_iterate(stage_name)` | `stage_name ∈ ITERATIVE_STAGES` and multi-agent |

`ITERATIVE_STAGES` is imported from `api.v2.core.stage_config`; `STAGE_PROMPT_MAPPING = get_prompt_path_mapping()` (`executor.py:5239`).

### `nexus_utils/workflow/context.py::WorkflowContextManager`

| Method | Responsibility |
|--------|----------------|
| `load_from_db(project_id) -> WorkflowContext` | Reads `projects` + `list_stages`; builds `stage_outputs`; parses `control_status`, `aggregated_metrics`, `created_at`, … |
| `_parse_intent_result(orchestrator_content)` | Regex-extracts agent name; sets `workflow_type='multi_agent'` when content contains both `multi` and `agent` |
| `_load_workflow_rules()` | Reads `&lt;repo&gt;/config/nexus_ai_base_rule.yaml` with `_rules_cache` |
| `save_to_db(context)` | Re-reads `control_status` from DDB before writing to avoid clobbering; maps `StageStatus → ProjectStatus`; updates `projects` + per-stage `update_stage` |
| `get_stage_context(context, stage_name, include_rules=True, include_local_docs=True, max_tokens=100000)` | Assembles `base_parts`: rules, `project_name` constraint, `intent_result`, user requirement + completed prerequisite stage outputs (summarized via `summarize_stage_output` to a per-stage token budget) + local docs |

### `nexus_utils/workflow/multi_agent.py::MultiAgentIterator`

| Method | Responsibility |
|--------|----------------|
| `_parse_architecture()` | First tries `_parse_json_architecture` (fenced ```json``` block); then `_parse_markdown_architecture` with three patterns (`## Agent: name` / `- **Name**: desc` / table row) |
| `get_agents_for_stage(stage_name)` | Only returns for `ITERATIVE_STAGES`; `_sort_agents_by_dependency` topologically orders agents |
| `format_agent_context(agent, stage_name, base_context)` | Appends `## Current Agent` + `## Other Agents` sections to `base_context` |
| `get_progress(agent_name) / update_progress(...)` | Maintains `Dict[str, AgentStageProgress]` |

`STAGE_TO_PROGRESS_STAGE = {"agent_design": "agent_design", "tools_developer": "tool_development", "prompt_engineer": "prompt_engineering", "agent_code_developer": "code_development"}` (V1 stage names; V2 mapping handled by `workflows.yaml.legacy_name_mapping`).

### `nexus_utils/workflow/validator.py`

`PromptValidator`:
- `validate_tool_paths(prompt_path, strict=False) -> ValidationResult` — extracts paths from `metadata.tools_dependencies` and `versions[].tools`; validates each `strands_tools/` / `system_tools/` / `generated_tools/` / `template_tools/` prefix via `importlib.import_module`.
- `validate_all_workflow_prompts() -> ValidationResult` — iterates `STAGE_PROMPT_MAPPING` to validate everything.

`DocumentValidator`: `STAGE_DOCUMENT_FORMATS` constrains per-stage formats (`requirements_analysis` → markdown + required sections `需求概述/功能需求/非功能需求`; `system_architecture` → json + `architecture_type/components`; `tools_developer` → python + regex `@tool`, `def`; `prompt_engineer` → yaml + `agent/name/system_prompt`; `agent_code_developer` → python + `from\s+nexus_utils` / `create_agent`).

### `nexus_utils/workflow/agent_validator.py::AgentValidator`

`validate_all() -> AgentValidationResult` runs, in order:
1. `validate_prompt_path()` — locates YAML under `prompts/generated_agents_prompts/&lt;name&gt;(.yaml|/prompt.yaml)`; validates `agent.name/description/versions[0].system_prompt`.
2. `validate_tool_dependencies()` — iterates `agent.metadata.tools_dependencies` through `_validate_single_tool`: `strands_tools/&lt;name&gt;` → `hasattr(strands_tools, name)`; `system_tools/`/`generated_tools/` → checks `tools/&lt;category&gt;/<...>.py` or directory.
3. `validate_agent_factory()` — calls `create_agent_from_prompt_template(agent_name=f"generated_agents_prompts/{project_name}", env="production", enable_logging=False)` and asserts `agent is not None and hasattr(agent, '__call__')`.

### `nexus_utils/workflow/file_sync.py`

- `FileMetadataManager.scan_project_files(project_id, project_name)` — walks `projects/&lt;project_name&gt;` or `projects/&lt;project_id&gt;`; computes `size / md5 / mtime` for each non-hidden file.
- `FileMetadataManager.save_file_metadata(project_id, stage_name, files)` — writes into `stages[stage].generated_files`.
- `FileMetadataManager.get_file_content(project_id, file_path, project_name=None)` — UTF-8 first; on `UnicodeDecodeError` returns base64.
- `FileSyncConfig(s3_bucket='nexus-ai-workflow-files', s3_prefix='workflow-files/', local_base_path='projects', auto_sync=True)`.

## Workflow Stage Tables (`config/workflows.yaml`)

### agent_build V2 (`prompt_base_path: system_agents_prompts/agent_build_workflow`)

| order | name | scope | prerequisites | rule_keys | fork/join | supports_iteration |
|------:|------|-------|---------------|-----------|-----------|--------------------|
| 1 | `intent_recognition` | project | [] | [] | — | false |
| 2 | `requirements_analysis` | project | `intent_recognition` | [] | — | false |
| 3 | `system_architecture` | project | `requirements_analysis` | `generation_rules` | **fork_on_complete=true** | false |
| 4 | `agent_design` | agent | `requirements_analysis`, `system_architecture` | `generation_rules` | — | false |
| 5 | `tools_development` | agent | `agent_design` | `directory_rules, generation_rules, cache_rules, external_resources, custom_rules` | — | **true** |
| 6 | `prompt_development` | agent | `requirements_analysis`, `tools_development` | same as above | — | **true** |
| 7 | `code_development` | agent | `prompt_development` | same as above | **join_after_complete=true** | **true** |
| 8 | `deployment` | project | `system_architecture`, `code_development` | `directory_rules` | **join_before_start=true** | false |

V1 compatibility (`legacy_name_mapping`): `orchestrator → intent_recognition`, `requirements_analyzer → requirements_analysis`, `system_architect → system_architecture`, `agent_designer → agent_design`, `tools_developer / tool_developer → tools_development`, `prompt_engineer → prompt_development`, `agent_code_developer / agent_developer_manager → code_development`, `agent_deployer → deployment`.

### agent_update (`prompt_base_path: system_agents_prompts/agent_update_workflow`)

| order | name | scope | prerequisites | optional |
|------:|------|-------|---------------|----------|
| 1 | `update_orchestrator` | project | [] | false |
| 2 | `requirements_update` | project | `update_orchestrator` | false |
| 3 | `tool_update` | project | `requirements_update` | **true** (can be skipped via `skip_stages`) |
| 4 | `prompt_update` | project | `tool_update` | **true** |
| 5 | `update_deployment` | project | `prompt_update` | false |

V1 compatibility: `code_update → update_deployment`.

### tool_build (`prompt_base_path: system_agents_prompts/tool_build_workflow_v2`)

`intent_recognition` → `tool_design` → `tool_development` (supports_iteration) → `tool_validation` → `tool_deployment`, all `scope: project`.

### skill_build (`prompt_base_path: system_agents_prompts/skill_build_workflow`)

`intent_recognition` → `skill_design` → `skill_development` (supports_iteration) → `skill_validation` → `skill_deployment`, all `scope: project`.

### magician

Single stage `magician_orchestrator`; identifies intent and routes to another workflow.

### defaults (same file)

```yaml
defaults:
  execution:
    max_retries: 3
    retry_delay_seconds: 5
    stage_timeout_seconds: 3600
    total_timeout_seconds: 21600      # 6h
    checkpoint_interval_seconds: 60
  context:
    max_tokens: 100000
    summary_threshold_tokens: 5000
    include_rules: true
    include_local_docs: true
```

## Call Graph

### V2 main message flow

```
SQS (build queue)
  │
  └─ Worker._poll_and_process        # worker/main.py:2530
       │
       └─ Worker._process_message    # worker/main.py:2571
            │   │
            │   ├─ _start_heartbeat  (ChangeMessageVisibility every 5 min)
            │   └─ WorkflowHandler.handle(message)
            │        │
            │        ├─ start_as_current_span("workflow.<wf>[.stage]")
            │        └─ _dispatch
            │             │
            │             ├─ task_type=="metrics_rollup"  → MetricsRollupHandler.handle
            │             ├─ task_type=="quota_check"     → QuotaCheckHandler.handle
            │             ├─ is_v2 && wf ∈ {agent_build, agent_update, skill_build, tool_build}
            │             │     → BuildHandlerV2.handle
            │             ├─ workflow_type=="agent_update" → _handle_agent_update (V1)
            │             ├─ workflow_type=="tool_build"   → _handle_tool_build   (V1)
            │             └─ default                       → BuildHandler.handle   (V1)
            │
            └─ if handler returns True: sqs_client.delete_message
               else:                    left to SQS for re-delivery (bounded by MAX_RETRY_COUNT)
```

### V2 single-stage execution (`BuildHandlerV2 → WorkflowEngineV2`)

```
BuildHandlerV2.handle
  │
  ├─ extract trace (_trace_carrier OR _trace_parent)
  ├─ push_context(MetricContext)
  ├─ tracer.start_as_current_span("worker.stage.<stage>")
  └─ _execute_stage
       │
       ├─ get_project(project_id).status ∈ {paused, cancelled} → return True (delete message)
       ├─ get_stage_by_key(stage_key).status ∈ {completed, running} → return True
       ├─ stage == "deployment" → _sync_artifacts_to_local(project_id)
       │
       └─ WorkflowEngineV2.execute_stage(stage, agent_id, agent_context)
            │
            ├─ _mark_stage_running(stage_key, ...)  # DDB create/update nexus_stages
            ├─ _build_agent_input(stage, agent_id, agent_context)
            │     ├─ get_base_rules(wf_type)        # tools.system_tools.agent_build_workflow.build_workflow_v2_tools
            │     ├─ load prerequisite stages       # by stage_config.prerequisites + scope
            │     ├─ Project Info + Source Agent Info (agent_update)
            │     └─ Current Agent Info
            ├─ _execute_agent()
            │     └─ create_agent_from_prompt_template(prompt_base_path/<prompt_file>, env="production")
            │        → agent(agent_input)
            │        → extract tokens / tool_calls / latency
            ├─ _parse_and_validate_output(raw_output)   # JSON parse, ≤3 retries
            ├─ _update_project_from_stage_result(stage, stage_result)
            ├─ _save_stage_result(stage_key, ...)
            └─ fill should_fork / fork_targets / should_check_join / all_agents_completed
       │
       ├─ record build.record_stage(wf_type, stage, success, elapsed)
       │
       └─ _dispatch_next
            ├─ result.should_fork        → for each fork_target: _send_stage_message("agent_design", agent_id=t.agent_id)
            ├─ result.should_check_join  → if all_agents_completed: _send_stage_message("deployment")
            └─ default sequential        → next = workflow_config.get_stage_sequence()[idx+1]
                                           agent_update also runs _skip_optional_stages
```

### V1 execution (`BuildHandler → WorkflowEngine`)

```
BuildHandler.handle
  └─ _execute_with_workflow_engine
       │
       └─ WorkflowEngine(project_id, db_client).<execute>
            │
            ├─ action=="resume"  → engine.resume(from_stage) + execute_to_completion()
            ├─ action=="restart" → engine.execute_from_stage(target_stage, to_completion)
            └─ default           → execute_from_stage(target_stage) or execute_to_completion()
                 │
                 └─ for stage in stages_to_execute:
                      └─ execute_single_stage(stage)
                           ├─ validate_prerequisites(stage) (skipped)
                           ├─ _check_control_signals()      # reads control_status from DDB
                           ├─ stage_service_v2.mark_stage_running
                           └─ StageExecutor.execute_stage(stage, state)
                                ├─ should_iterate(stage) && multi-agent
                                │    → MultiAgentStageExecutor.execute_for_all_agents
                                │         └─ for each agent: MultiAgentIterator.format_agent_context + create_agent + invoke
                                └─ else
                                     ├─ create_agent(stage, state)
                                     ├─ format_context(stage) → get_stage_context(context)
                                     ├─ agent(input)
                                     └─ collect StageMetrics + FileMetadata
```

## Extending

### 1. Add a new workflow stage

File: `config/workflows.yaml`. Append to the target workflow's `stages` list:

```yaml
- name: "<new_stage_name>"
  display_name: "<display name>"
  agent_display_name: "<agent display name>"
  prompt_file: "<file under prompt_base_path, without extension>"
  log_filename: "<log tag>"
  order: <integer>                  # execution order
  scope: "project" | "agent"       # determines whether to fan out per agent
  prerequisites: ["<stage_name>", ...]
  rule_keys: ["directory_rules", "generation_rules", ...]  # optional rule injection
  supports_iteration: false | true
  optional: false | true            # can be skipped via skip_stages
  fork_on_complete: false | true    # fork into multiple agents on completion
  join_after_complete: false | true
  join_before_start: false | true
```

Then:

1. Put the Agent prompt template at `prompts/&lt;prompt_base_path&gt;/&lt;prompt_file&gt;.yaml` (`agent.name / description / versions[].system_prompt / metadata.tools_dependencies`).
2. **No Worker code changes needed**: `WorkflowEngineV2` picks up the stage via `workflow_config.get_stage_sequence()`; `BuildHandlerV2._get_next_stage` dispatches sequentially.
3. For `agent`-scope stages, you need an upstream stage with `fork_on_complete=true` (e.g. `system_architecture`) whose `stage_result` produces the agent list used for `fork_targets`.
4. If the stage writes files under `projects/&lt;name&gt;/`, record the paths in the `StageOutput.generated_files` so `FileMetadataManager.get_file_content` can retrieve them later.

### 2. Add a new workflow type

1. Add a `&lt;new_wf_type&gt;:` block at the top level of `config/workflows.yaml` (see `skill_build` / `tool_build` for a template).
2. Add the name to `WorkflowHandler.SUPPORTED_WORKFLOWS` (`worker/handlers/workflow_handler.py:1823`).
3. Decide in `WorkflowHandler._dispatch` whether to route to V2 (`BuildHandlerV2`) or to a new dedicated handler. V2 accepts any `workflow_type ∈ {agent_build, agent_update, skill_build, tool_build}`; to slot in a new type under V2 you only need to let `_handle_agent_build_v2` accept it, or add a new branch in `_execute_stage`'s deployment post-hooks (`_post_deployment` / `_post_skill_deployment` / `_post_tool_deployment` / `_post_update_deployment`).
4. For ops tasks (not user builds), follow `metrics_rollup` / `quota_check`:
   - Create `worker/handlers/&lt;task&gt;_handler.py` with `def handle(self, message: Dict) -> bool`;
   - Dispatch on `body['task_type']` at the top of `WorkflowHandler._dispatch`.

### 3. Add a new SQS queue

Currently `Worker.__init__` recognises only `build` / `deploy` (`worker/main.py:2457`):

```python
if queue_type == "build":
    self.queue_name = worker_settings.SQS_BUILD_QUEUE_NAME
    self.handler = WorkflowHandler()
    self.visibility_timeout = worker_settings.VISIBILITY_TIMEOUT
elif queue_type == "deploy":
    self.queue_name = worker_settings.SQS_DEPLOY_QUEUE_NAME
    self.handler = None  # TODO
    self.visibility_timeout = 600
else:
    raise ValueError(f"Unknown queue type: {queue_type}")
```

To add a new queue:
1. Add `SQS_<NEW>_QUEUE_NAME` to `worker/config.py::WorkerSettings` (and a key under `config/default_config.yaml.sqs.queues`).
2. Add an `elif queue_type == "&lt;new&gt;":` branch in `Worker.__init__`.
3. Add the new choice to `argparse.add_argument('--queue', choices=[...])` (`worker/main.py:2656`).
4. Implement the corresponding handler and assign it before the final `else`.

### 4. Adding handlers or modifying dispatch

- **Do not** subclass `BuildHandlerV2` directly. The V2 contract is one message = one stage; extensions belong in `workflows.yaml`.
- **Ops handlers** should be standalone classes like `MetricsRollupHandler` / `QuotaCheckHandler`, routed via `body['task_type']`.
- A handler must expose `def handle(self, message: Dict[str, Any]) -> bool`. Semantics: **return True to ACK (SQS deletes the message)**; False → SQS re-delivers after `VISIBILITY_TIMEOUT` (bounded by `MAX_RETRY_COUNT` before DLQ).
- **Idempotency** is mandatory: the same message may be consumed more than once. V2 `_execute_stage` pre-checks `stages.stage_key` status; if `completed/running` it returns True immediately.

### 5. Custom Agent validation

Extend or call `nexus_utils.workflow.agent_validator.AgentValidator`:

```python
from nexus_utils.workflow import validate_agent

result = validate_agent(project_name="my_agent")  # -> AgentValidationResult
if not result.is_valid:
    for issue in result.issues:
        if issue.level == ValidationLevel.ERROR:
            raise RuntimeError(str(issue))
```

Or in batch: `validate_multiple_agents(project_names)`.

### 6. Constraints and pitfalls

- **Thread safety:** `Worker._poll_and_process` is serial (`MAX_MESSAGES_PER_POLL=1`). The heartbeat thread `HeartbeatThread` is a daemon; it shares the `receipt_handle` with the main processing path but only calls `change_message_visibility` — no other state mutation.
- **Environment-variable side effects:** the V1 `_execute_with_workflow_engine` sets `NEXUS_STAGE_TRACKER_PROJECT_ID` / `NEXUS_UPDATE_AGENT_ID` / `NEXUS_TOOL_NAME` / `NEXUS_TARGET_AGENT` and must clear them in `finally`. If your extension sets process-wide env vars, **always use `try/finally`** to avoid leaking into the next message.
- **strands non-interactive:** `worker/main.py:2397` sets `BYPASS_TOOL_CONSENT=true` and `STRANDS_NON_INTERACTIVE=true`. Do not invoke tools that need a TTY from inside the Worker.
- **Logging handlers:** `worker/main.py:2435` **clears** the `FileHandler` configured by `config_loader` and installs a `StreamHandler(stdout)`. If your new module relies on writing to `nexus_ai.log`, adjust `service_manager`'s stdout redirection rather than restoring the FileHandler.
- **Observability initialisation order:** `_setup_observability(service_name="nexus-ai-worker")` must complete before `boto3`-related modules are imported (`worker/main.py:2416`). Keep this in mind when adding top-level imports.
- **Double-write trace context:** V2 puts both `_trace_carrier` (full W3C) and `_trace_parent` (trace_id hex) on outgoing SQS messages. Consumers prefer `_trace_carrier`; they only fall back to `_trace_parent` as a weak `Link`. `_trace_parent` is a transitional compat field and may be retired after M2.
- **Control-status priority:** `WorkflowContextManager.save_to_db` re-reads `control_status` from DDB before each save. If the API side has set `paused/stopped`, the local save will not overwrite it (`context.py:3840`). Extensions that bypass `save_to_db` and write the `projects` table directly **may clobber user pause/stop actions**.
- **Content size:** `StageOutput.MAX_CONTENT_SIZE = 400 * 1024` bytes. Beyond that, `content` is cleared and `s3_content_ref` points to the S3 object.
- **Token estimation:** `estimate_tokens` uses the crude `len(text) // 4` formula (`context.py:3501`); do not use it for billing.
- **JSON parse retries:** `WorkflowEngineV2._parse_and_validate_output` retries up to 3 times (`MAX_RETRY_ON_PARSE_FAILURE`). Retries occur **within the same SQS message**; a full failure fails the stage and the message is redelivered under the regular rules.

## Debugging and Troubleshooting

### Log keywords

| Keyword | Source | Meaning |
|---------|--------|---------|
| `[POLL] queue=&lt;name&gt; region=&lt;r&gt;: None` | `worker/main.py:2551` | Empty poll |
| `[POLL] queue=&lt;name&gt; region=&lt;r&gt;: stage=&lt;s&gt;, project=&lt;p&gt;, agent=&lt;a&gt;` | `worker/main.py:2559` | Received a message summary |
| `Processing message &lt;id&gt;` | `worker/main.py:2576` | Processing starts |
| `Heartbeat: extended message visibility` | `worker/main.py:2628` | Heartbeat succeeded (DEBUG) |
| `[V2][STAGE-DONE] stage=... project=... agent=...` | `build_handler_v2.py:907` | V2 stage complete |
| `[V2][FORK-TARGET] agent_id=... type=... context=...` | `build_handler_v2.py:916` | Fork target snapshot |
| `[V2] Forking: N agents` / `[V2] All agents completed, dispatching deployment` | `build_handler_v2.py` | Dispatch control |
| `[V2] Sent SQS: stage=&lt;s&gt;, agent=&lt;a|project&gt;` | `build_handler_v2.py:1090` | Next stage enqueued |
| `[V2] Project &lt;id&gt; is paused/cancelled, skipping stage &lt;s&gt;` | `build_handler_v2.py:868` | User pause/cancel took effect |
| `Stage &lt;name&gt; marked as running via stage_service` | `engine.py:4323` | V1 stage start |
| `Resuming from checkpoint: stage=&lt;s&gt;, completed=[...]` | `build_handler.py:251` | V1 resume from checkpoint |
| `Prerequisites not met for stage &lt;s&gt;: missing [...]` | `engine.py:4277` | V1 prerequisites unmet |
| `[metrics-rollup] type=&lt;t&gt;, target=&lt;x&gt;` / `upserted N rows` | `metrics_rollup_handler.py` | Metrics rollup |
| `[quota-check] checking quota for month=&lt;m&gt;` / `fired N alerts` | `quota_check_handler.py` | Quota check |
| `trace context extract/inject failed: &lt;e&gt;` | `build_handler_v2.py:790/1073` | OTel issue (non-fatal) |

### Common exceptions

| Exception | Meaning | Typical cause | How to investigate |
|-----------|---------|---------------|--------------------|
| `PrerequisiteError` | V1 prerequisites unmet | The SQS message sets `target_stage`, but that stage's `prerequisites` are not all `completed` in DDB | Inspect `list_stages(project_id)`; verify `_check_resume_state` output |
| `StageExecutionError` | Stage Agent execution failed | Model call failure, missing tool, malformed prompt | Check `error_message` + Agent trace span |
| `WorkflowControlSignal(PAUSE/STOP)` | User pause/stop | The API side set `projects.control_status` to `paused/stopped` | Normal signal; the Worker updates `TaskStatus` to `PENDING`/`CANCELLED` and ACKs |
| `Unknown stage: &lt;s&gt;` (`StageExecutionResult.error_message`) | V2 workflow config lacks the stage | YAML not reloaded, or message's workflow_type/stage mismatch | Inspect `get_workflow_config(wf_type)`; restart Worker to reload YAML |
| `Failed to create agent for stage &lt;s&gt;` | V2 Agent factory failed | Prompt YAML missing/malformed; `tools_dependencies` cannot be imported | Reproduce with `AgentValidator.validate_all()` |
| `Invalid V2 message: missing project_id or stage` | Field missing on V2 message | Bug in upstream producer | Grep `message_body` logs |
| `SNS notify failed: ...` | `QuotaCheckHandler` | `NEXUS_QUOTA_SNS_TOPIC` unset or IAM not allowed | Fallback path writes `audit_log` |

### Diagnostic commands

```bash
# Debug-process a single message
python -m worker.main --queue build --once

# Inspect a project's stage status
aws dynamodb query \
  --table-name nexus_stages \
  --key-condition-expression "project_id = :pid" \
  --expression-attribute-values '{":pid":{"S":"<project_id>"}}'

# Build queue backlog
aws sqs get-queue-attributes \
  --queue-url "$(aws sqs get-queue-url --queue-name nexus-build-queue --query QueueUrl --output text)" \
  --attribute-names ApproximateNumberOfMessages ApproximateNumberOfMessagesNotVisible

# Retry a V1 project (via the API-side resume)
curl -X POST http://<api>/v2/projects/<project_id>/resume

# Run full workflow-prompt validation
python -c "from nexus_utils.workflow import validate_workflow_prompts; r = validate_workflow_prompts(); print(r.to_dict())"
```

## Further Reading

- Workflow config: `config/workflows.yaml`
- Agent factory: `nexus_utils/agent_factory.py` → `create_agent_from_prompt_template`
- Base rules: `config/nexus_ai_base_rule.yaml` (loaded by `WorkflowContextManager._load_workflow_rules`)
- SQS client: `api/v2/database/sqs.py::SQSClient`
- DDB client: `api/v2/database/dynamodb.py::db_client`
- Observability: `nexus_utils/observability/__init__.py`, `nexus_utils/observability/metrics/build.py`
- Multi-agent iterator: `nexus_utils/workflow/multi_agent.py`
- Agent validation: `nexus_utils/workflow/agent_validator.py::AgentValidator`
- File sync: `nexus_utils/workflow/file_sync.py::FileSyncManager`
- V1/V2 stage name mapping: `legacy_name_mapping` inside each workflow block
