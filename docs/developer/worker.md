---
title: Worker 架构
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - config/workflows.yaml
    - nexus_utils/workflow/**
    - worker/**
  generated_at: 2026-05-09T00:05:17+00:00
  generated_by: docs-sync v2
---

# Worker 架构

## 概述

Worker 是 Nexus-AI 的后台执行进程。它从 SQS 队列长轮询消息、解析工作流任务、调用 `WorkflowEngine`/`WorkflowEngineV2` 执行单个阶段或完整流水线，并把结果写回 DynamoDB 与 S3。Worker 不暴露 HTTP 接口，也不参与 API 层的请求处理——它是一个**纯消费者**进程。

- **入口**：`python -m worker.main [--queue build|deploy] [--once]`（`worker/main.py:2652`）。
- **消息来源**：默认监听 `SQS_BUILD_QUEUE_NAME`（可选 `SQS_DEPLOY_QUEUE_NAME`）。
- **核心调用栈**：`Worker._poll_and_process` → `Worker._process_message` → `WorkflowHandler.handle` → `BuildHandlerV2 / BuildHandler / MetricsRollupHandler / QuotaCheckHandler` → `WorkflowEngineV2 / WorkflowEngine` → `StageExecutor` → Agent（通过 `nexus_utils.agent_factory.create_agent_from_prompt_template`）。
- **工作流边界**：Worker 只负责**执行并分发**。它不决定有哪些阶段，阶段表由 `config/workflows.yaml` 定义并由 `nexus_utils.workflow_config.get_workflow_config(workflow_type)` 加载。

执行模型有两代并存：

| 模型 | 入口 Handler | 引擎 | 阶段执行方式 | 触发方式 |
|------|--------------|------|--------------|----------|
| V1 | `BuildHandler` / `WorkflowHandler._handle_agent_build` | `WorkflowEngine` | 单条消息执行完整工作流（`execute_to_completion`） | 一次性 API 请求入队 |
| V2 | `BuildHandlerV2` | `WorkflowEngineV2` | 每条消息执行**一个** `stage`，完成后按 `fork_on_complete` / `join_after_complete` 再入队下一阶段 | `workflow_type in {agent_build, agent_update, skill_build, tool_build}` 且消息含 `stage` 字段 |

V1 保留主要用于老消息与回归测试；所有新工作流（`agent_build` V2、`agent_update`、`tool_build`、`skill_build`、`magician`）均走 V2。

## 文件组织

### `worker/` — 进程入口与消息调度

| 路径 | 责任 | 依赖 |
|------|------|------|
| `worker/__init__.py` | 声明 `__version__ = "2.0.0"` | — |
| `worker/config.py` | `WorkerSettings`（pydantic BaseSettings）聚合 AWS/SQS/DynamoDB/运行时配置；`get_worker_settings` 带 `lru_cache` | `nexus_utils.config_loader.get_config`, `pydantic_settings` |
| `worker/main.py` | `Worker` 主循环、信号处理、消息心跳、参数解析 | `api.v2.database.sqs_client`, `worker.handlers.workflow_handler.WorkflowHandler`, `nexus_utils.observability` |
| `worker/handlers/__init__.py` | 只导出 `BuildHandler`（向后兼容） | — |
| `worker/handlers/build_handler.py` | V1 构建处理器，封装 `WorkflowEngine.execute_to_completion` 等 | `nexus_utils.workflow`, `api.v2.database.db_client`, `api.v2.models.schemas` |
| `worker/handlers/build_handler_v2.py` | V2 单阶段处理器 + fork/join 分发 | `nexus_utils.workflow.engine_v2.WorkflowEngineV2`, `api.v2.database.sqs.SQSClient` |
| `worker/handlers/workflow_handler.py` | 根据 `workflow_type` / `task_type` 把消息路由到具体 handler；是 `Worker.handler` 的唯一实现 | 上述所有 handler |
| `worker/handlers/metrics_rollup_handler.py` | 从 CloudWatch 拉 metric 聚合到 Aurora `agent_metrics_hourly` / `user_metrics_daily` | `api.v2.database.aurora.pg_client`, `boto3` CloudWatch |
| `worker/handlers/quota_check_handler.py` | 查配额超限，写 `quota_alerts`，通过 SNS 通知 | `api.v2.database.aurora.pg_client`, `boto3` SNS, `nexus_utils.observability.logging.security_log` |

### `nexus_utils/workflow/` — 执行引擎与数据模型

| 路径 | 责任 | 主要导出 |
|------|------|----------|
| `__init__.py` | 统一 re-export 工作流门面 | `WorkflowEngine`, `ExecutionResult`, `WorkflowControlSignal`, `PrerequisiteError`, `StageExecutor`, `StageOutput`, `StageStatus`, `ControlStatus`, `StageMetrics`, `MultiAgentIterator`, `AgentValidator`, `FileSyncManager`, … |
| `models.py` | 核心 dataclass 与 Enum | `StageStatus`, `ControlStatus`, `StageMetrics`, `FileMetadata`, `StageOutput`, `WorkflowContext`, `IntentRecognitionResult`, `AgentDefinition`, `MultiAgentArchitecture`, `AgentStageProgress`, `AggregatedMetrics`, `STAGE_ORDER`（懒加载） |
| `context.py` | 从 DynamoDB 加载/保存 `WorkflowContext`，拼装阶段提示词上下文 | `WorkflowContextManager`, `get_stage_context`, `estimate_tokens`, `truncate_to_tokens`, `summarize_stage_output`, `DEFAULT_MAX_CONTEXT_TOKENS` |
| `executor.py` | V1 单阶段执行器，创建 Agent、收集 metrics、扫描生成文件 | `StageExecutor`, `StageExecutionError`, `execute_stage`, `STAGE_PROMPT_MAPPING` |
| `engine.py` | V1 工作流引擎，顺序执行多阶段；暴露 pause/resume/stop 控制 | `WorkflowEngine`, `ExecutionResult`, `WorkflowControlSignal`, `PrerequisiteError`, `create_workflow_engine`, `run_workflow`, `run_workflow_legacy` |
| `engine_v2.py` | V2 单阶段引擎，组装 Agent 输入、解析 JSON、fork/join 信号 | `WorkflowEngineV2`, `StageExecutionResult`, `MAX_RETRY_ON_PARSE_FAILURE` |
| `multi_agent.py` | 多 Agent 项目的迭代器与阶段执行器（V1 架构） | `MultiAgentIterator`, `MultiAgentStageExecutor`, `create_multi_agent_iterator`, `is_multi_agent_project`, `get_multi_agent_progress` |
| `validator.py` | 提示词工具路径与文档格式校验 | `PromptValidator`, `DocumentValidator`, `ValidationResult`, `ValidationError`, `validate_workflow_prompts`, `validate_tool_path`, `validate_document` |
| `agent_validator.py` | 生成后 Agent 的 prompt/tools/factory 三件套校验 | `AgentValidator`, `AgentValidationResult`, `ValidationIssue`, `ValidationLevel`, `validate_agent`, `validate_multiple_agents` |
| `file_sync.py` | 项目目录扫描与跨 Worker 文件同步 | `FileMetadataManager`, `FileSyncManager`, `FileSyncConfig`, `scan_and_save_files`, `get_file_content`, `sync_project_files` |

### `config/workflows.yaml` — 工作流定义

定义 5 个工作流：`agent_build`、`agent_update`、`tool_build`、`skill_build`、`magician`。所有 Worker/Engine 代码均以该文件为唯一真源，通过 `nexus_utils.workflow_config.get_workflow_config(workflow_type)` 读取。

## 核心类型与数据结构

### `WorkerSettings` (`worker/config.py:66`)

`pydantic_settings.BaseSettings` 派生。读取顺序：**环境变量 > `default_config.yaml` > 字面默认值**。

| 字段 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `WORKER_ID` | `str` | `f"worker-{os.getpid()}"` | Worker 标识，用于 DynamoDB `worker_id` 字段 |
| `AWS_REGION` | `str` | `_aws_config.get('aws_region_name', 'us-west-2')` | AWS Region |
| `AWS_ACCESS_KEY_ID` | `Optional[str]` | `None` | 显式凭证；为空走默认凭证链 |
| `AWS_SECRET_ACCESS_KEY` | `Optional[str]` | `None` | 同上 |
| `DYNAMODB_ENDPOINT_URL` | `Optional[str]` | `_aws_config.get('endpoint_url')` | LocalStack 等本地模拟用 |
| `DYNAMODB_TABLE_PREFIX` | `str` | `'nexus_'` | 前缀，拼接后构成完整表名 |
| `SQS_ENDPOINT_URL` | `Optional[str]` | `_aws_config.get('endpoint_url')` | SQS 模拟端点 |
| `SQS_BUILD_QUEUE_NAME` | `str` | `_sqs_queues.get('build', 'nexus-build-queue')` | 构建任务队列 |
| `SQS_DEPLOY_QUEUE_NAME` | `str` | `_sqs_queues.get('deploy', 'nexus-deploy-queue')` | 部署任务队列 |
| `POLL_INTERVAL_SECONDS` | `int` | `5` | SQS 长轮询 `wait_time_seconds` |
| `MAX_MESSAGES_PER_POLL` | `int` | `1` | `receive_messages` 一次取的最大消息数 |
| `VISIBILITY_TIMEOUT` | `int` | `_sqs_config.get('build_visibility_timeout', 3600)` | 初始可见性超时；心跳会续期 |
| `HEARTBEAT_INTERVAL` | `int` | `300` | 心跳间隔（秒，5 分钟） |
| `MAX_RETRY_COUNT` | `int` | `_sqs_config.get('max_retry_count', 3)` | SQS 最大重投次数 |
| `BUILD_TIMEOUT_SECONDS` | `int` | `7200` | 单次构建总超时（2 小时） |
| `LOG_LEVEL` | `str` | `_logging_config.get('level', 'INFO')` | root logger 等级 |

实例化通过 `get_worker_settings()`（`worker/config.py:105`），带 `@lru_cache()`。

### `Worker` (`worker/main.py:2448`)

```python
class Worker:
    queue_type: str         # "build" | "deploy"
    worker_id: str          # worker_settings.WORKER_ID
    queue_name: str         # 按 queue_type 选择
    handler: WorkflowHandler | None   # deploy 队列暂未实现 handler
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

| 字段 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `input_tokens` | `int` | `0` | 累积输入 token |
| `output_tokens` | `int` | `0` | 累积输出 token |
| `execution_time_seconds` | `float` | `0.0` | 阶段耗时 |
| `tool_calls_count` | `int` | `0` | 工具调用次数 |
| `model_id` | `Optional[str]` | `None` | 模型 ID |

`total_tokens` 为 property（`input_tokens + output_tokens`）。

### `FileMetadata` (`nexus_utils/workflow/models.py:6609`)

| 字段 | 类型 | 说明 |
|------|------|------|
| `path` | `str` | 相对 `projects/&lt;agent_name&gt;/` 的路径 |
| `size` | `int` | 字节 |
| `checksum` | `Optional[str]` | MD5 |
| `last_modified` | `Optional[datetime]` | 修改时间 |

### `StageOutput` (`nexus_utils/workflow/models.py:6664`)

| 字段 | 类型 | 说明 |
|------|------|------|
| `stage_name` | `str` | 阶段名称 |
| `content` | `str` | Agent 输出内容（≤ `MAX_CONTENT_SIZE = 400*1024`） |
| `metrics` | `StageMetrics` | 执行指标 |
| `generated_files` | `List[FileMetadata]` | 生成的文件 |
| `document_content` | `str` | 设计文档内容 |
| `document_format` | `str` | `"markdown"` / `"json"` / `"yaml"` / `"python"` |
| `completed_at` | `Optional[datetime]` | 完成时间 |
| `status` | `StageStatus` | 阶段状态 |
| `error_message` | `Optional[str]` | 失败时错误文本 |
| `s3_content_ref` | `Optional[str]` | 超过 400KB 时存 S3 的引用 |

### `ExecutionResult` (`nexus_utils/workflow/engine.py:4085`, V1)

| 字段 | 类型 | 说明 |
|------|------|------|
| `success` | `bool` | 是否全量成功 |
| `completed_stages` | `List[str]` | 本次完成的阶段名 |
| `failed_stage` | `Optional[str]` | 失败阶段（如有） |
| `error_message` | `Optional[str]` | 错误文本 |
| `final_status` | `StageStatus` | 最终状态 |
| `metrics` | `Dict[str, Any]` | 聚合指标 |

### `StageExecutionResult` (`nexus_utils/workflow/engine_v2.py:4751`, V2)

| 字段 | 类型 | 说明 |
|------|------|------|
| `success` | `bool` | 本阶段是否成功 |
| `stage_name` | `str` | 阶段名 |
| `agent_id` | `Optional[str]` | agent 级阶段的 agent_id |
| `stage_result` | `Dict[str, Any]` | 解析后的 JSON 结果 |
| `raw_output` | `str` | Agent 原始输出 |
| `metrics` | `Dict[str, Any]` | tokens/时间等 |
| `error_message` | `Optional[str]` | 失败信息 |
| `retry_count` | `int` | JSON 解析重试计数 |
| `should_fork` | `bool` | 是否需要 fork 下一阶段 |
| `fork_targets` | `List[Dict[str, Any]]` | fork 目标列表（每个含 `agent_id` / `agent_type` / `agent_context` / `architecture_type`） |
| `should_check_join` | `bool` | 是否在 Agent 级阶段后做 join |
| `all_agents_completed` | `bool` | 全部 Agent 是否完成（join 判断） |

### `WorkflowContext` (`nexus_utils/workflow/models.py`，由 `context.py:3614` 的 `load_from_db` 组装)

保存 `project_id`、`project_name`、`requirement`、`intent_result`、`stage_outputs`、`rules`、`current_stage`、`status`、`aggregated_metrics`、`created_at`、`updated_at`、`control_status`、`pause_requested_at`、`stop_requested_at`、`resume_from_stage`、`workflow_type` 等字段。所有状态都会被 `WorkflowContextManager.save_to_db` 持久化回 DDB。

### 其他数据结构

- `AgentDefinition` (`models.py:6860`)：多 Agent 架构中的单个 Agent（`name / agent_type ∈ {main,sub,tool} / description / orchestration_pattern ∈ {agent_as_tool,swarm,graph} / dependencies / tools / status`）。
- `MultiAgentArchitecture` (`models.py:6915`)：包含 `agents / orchestration_pattern / main_agent`，派生 `agent_count`。
- `AgentStageProgress` (`models.py:6977`)：多 Agent 下每个 Agent 的阶段进度（固定 5 阶段：`agent_design`、`tool_development`、`prompt_engineering`、`code_development`、`testing`）。
- `AggregatedMetrics` (`models.py:7055`)：项目级累加（`total_input_tokens / total_output_tokens / total_tokens / total_cost / total_execution_time / total_tool_calls`）。
- `IntentRecognitionResult` (`models.py:6791`)：编排阶段产物（`agent_name / workflow_type ∈ {single_agent, multi_agent} / complexity / estimated_stages / key_features / tool_requirements / raw_analysis`）。

### 异常与信号

| 类 | 位置 | 含义 |
|------|------|------|
| `WorkflowControlSignal` | `engine.py:4106` | 暂停/停止控制，`signal_type ∈ {PAUSE, STOP}` |
| `PrerequisiteError` | `engine.py:4120` | 前置阶段未完成，带 `missing_prerequisites` |
| `StageExecutionError` | `executor.py:5242` | 阶段执行失败，带 `recoverable` 标志 |
| `ValidationError` | `validator.py:7840` | 工具路径/文档验证错误 |
| `ValidationIssue` (`Level: ERROR/WARNING/INFO`) | `agent_validator.py:2944` | Agent 验证单条问题 |

## 消息协议

### V2 构建消息（`BuildHandlerV2.handle`）

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

- `stage` 存在即为 V2 消息（`WorkflowHandler.handle` 中 `is_v2 = bool(stage)`）。
- `agent_id` 对 project-scope 阶段是 `"project"` 或缺省，对 agent-scope 阶段必填。
- `_trace_carrier` 为 W3C 完整 context；旧消息降级为 `_trace_parent`（仅 trace_id hex，通过 `opentelemetry.trace.Link` 弱关联）。

### V1 构建消息（`BuildHandler.handle`）

```json
{
  "task_id": "<uuid>",
  "project_id": "<uuid>",
  "requirement": "<用户需求文本>",
  "target_stage": "<stage_name | null>",
  "execute_to_completion": true,
  "action": "execute" | "resume" | "restart",
  "metadata": { ... }
}
```

### 运维任务消息

`metrics_rollup`：

```json
{ "task_type": "metrics_rollup",
  "rollup_type": "hourly" | "daily" | "monthly",
  "target_hour":  "2026-04-30T12:00:00Z"   // optional
}
```

`quota_check`：

```json
{ "task_type": "quota_check",
  "month": "2026-04-01"   // optional, 默认本月
}
```

## 关键函数与方法

### `worker/main.py`

| 名称 | 签名 | 职责 | 备注 |
|------|------|------|------|
| `Worker.__init__` | `(queue_type: str = "build")` | 根据 `queue_type` 选择队列名、可见性超时与 handler。`build` → `WorkflowHandler`，`deploy` → `None`（占位） | raise `ValueError` 若 queue_type 未知 |
| `Worker.start` | `(once: bool = False) -> None` | 注册 `SIGINT`/`SIGTERM`，循环调用 `_poll_and_process`；`once=True` 处理一条后退出 | 第二次收到信号强制 `sys.exit(1)` |
| `Worker.stop` | `() -> None` | 设置 `running=False` + `_shutdown_event.set()` | — |
| `Worker._poll_and_process` | `() -> None` | `receive_messages(queue_name, max_messages, wait_time_seconds=POLL_INTERVAL_SECONDS, visibility_timeout)`，记录 `record_sqs_poll` 指标 | 空轮询打印 `[POLL] ... : None` |
| `Worker._process_message` | `(message: dict) -> None` | 起心跳线程 → `handler.handle(message)` → 成功则 `sqs_client.delete_message`，失败留给 SQS 重投 | 记录 `record_sqs_message_processed(queue, success, duration)` |
| `Worker._start_heartbeat` | `(receipt_handle: str) -> HeartbeatThread` | 后台线程每 `HEARTBEAT_INTERVAL` 调 `change_message_visibility` | 返回自定义 `HeartbeatThread`，有 `cancel()` |
| `main` | `() -> None` | argparse 解析 `--queue / --once`，构造 `Worker` 并 `start` | — |

### `worker/handlers/workflow_handler.py::WorkflowHandler`

| 方法 | 签名 | 职责 |
|------|------|------|
| `handle` | `(message: Dict) -> bool` | 取 `workflow_type`/`stage`，开 tracing span `workflow.&lt;wf&gt;[.stage]`，按首阶段条件发 `record_build_started`，再调 `_dispatch` |
| `_dispatch` | `(body, message, workflow_type, task_id, project_id, is_v2) -> bool` | 路由：`metrics_rollup` / `quota_check` / V2 (`_handle_agent_build_v2`) / `agent_update` / `tool_build` / `agent_build` (V1) |
| `_handle_agent_build_v2` | `(message) -> bool` | 委托 `BuildHandlerV2().handle(message)` |
| `_handle_agent_build` | `(message) -> bool` | 委托 `BuildHandler().handle(message)` (V1) |
| `_handle_agent_update` | `(message) -> bool` | V1 Agent 更新，用 `WorkflowType.AGENT_UPDATE` 构建 `WorkflowEngine` 执行到完成 |
| `_handle_tool_build` | `(message) -> bool` | V1 工具构建，用 `WorkflowType.TOOL_BUILD`，注入环境变量 `NEXUS_TOOL_NAME`/`NEXUS_TARGET_AGENT` |
| `_convert_execution_result` | `(result) -> Dict` | 把 V1 `ExecutionResult` 翻译为 `{'status', 'success', 'completed_stages', 'failed_stage', 'error_message', 'metrics'}` |
| `_handle_execution_result` | `(task_id, project_id, result) -> bool` | 成功/失败/暂停/停止分别 `_update_task_status` + `_update_project_status` + `emit_build_completed_from_project` |
| `_handle_execution_error` | `(task_id, project_id, error) -> bool` | 捕获异常，更新 `TaskStatus.FAILED` + `ProjectStatus.FAILED` |
| `_update_task_status` / `_update_project_status` | `(task_id/project_id, status, result/error_info, clear_error)` | 直接写 DDB `tasks` / `projects` 表 |

`WorkflowHandler.SUPPORTED_WORKFLOWS = ['agent_build', 'agent_update', 'tool_build', 'metrics_rollup', 'quota_check']`（`workflow_handler.py:1823`）。

### `worker/handlers/build_handler.py::BuildHandler` (V1)

| 方法 | 签名 | 职责 |
|------|------|------|
| `handle` | `(message: Dict) -> bool` | 校验字段 → 去重（`status ∈ {building, completed}` 直接返回 True）→ `_check_resume_state` → `_update_task_status(RUNNING)` + `_update_project_status(BUILDING, clear_error=True)` → `_execute_with_workflow_engine` → 按 `status` 分支收尾 |
| `_execute_with_workflow_engine` | `(project_id, requirement, target_stage, execute_to_completion, action, metadata)` | 设 `NEXUS_STAGE_TRACKER_PROJECT_ID`；`action` 分支：`resume` → `engine.resume(from_stage) + execute_to_completion`；`restart` → `engine.execute_from_stage(target_stage, to_completion)`；默认按 `target_stage` 或 `execute_to_completion` |
| `_convert_execution_result` | `(result)` | 同 WorkflowHandler，独立副本 |
| `_check_resume_state` | `(project_id)` | 扫描 `list_stages`，取最早 `status ∈ {pending, failed, running}` 的阶段作为 `resume_from_stage` |
| `_update_project_status` | `(project_id, status, error_info, clear_error)` | 失败时会记录 `resume_from_stage` 方便下次 `action='resume'` |
| `_generate_workflow_report_and_sync` | `(project_id, project_name, result)` | 调 `generate_report_from_stages` + `collect_project_info_after_workflow` 收尾 |
| `_sync_project_to_s3` | `(project_id, project_name)` | 多 Worker 场景把 `projects/&lt;name&gt;` 同步到 S3 |

### `worker/handlers/build_handler_v2.py::BuildHandlerV2`

| 方法 | 签名 | 职责 |
|------|------|------|
| `handle` | `(message) -> bool` | 从 `body` 取 `project_id / stage / agent_id / agent_context / workflow_type`；提取上游 trace context → `push_context(MetricContext)` → 开 `worker.stage.&lt;stage&gt;` span → 调 `_execute_stage` |
| `_execute_stage` | `(body, project_id, stage, agent_id, agent_context, trace_links)` | ① 执行前项目状态 `paused/cancelled` → 直接 True 让 SQS 删消息；② 阶段状态 `completed/running` → 跳过；③ `deployment` 阶段先 `_sync_artifacts_to_local`；④ `WorkflowEngineV2.execute_stage` → 记录 `build.record_stage`；⑤ `_dispatch_next`；⑥ 部署类阶段后 `_post_deployment` / `_post_skill_deployment` / `_post_tool_deployment` / `_post_update_deployment` + `_update_project_on_completion` |
| `_dispatch_next` | `(project_id, current_stage, agent_id, result, original_body)` | Fork → 每个 `fork_target` 发 `agent_design` 消息；Join → 全员完成则发 `deployment`；普通顺序 → `_get_next_stage` 后 `_send_stage_message` |
| `_get_next_stage` | `(current_stage, workflow_type='agent_build')` | 读 `workflow_config.get_stage_sequence()`，若下一阶段 `join_before_start=True` 则返回 None（由 join 触发） |
| `_send_stage_message` | `(project_id, stage, agent_id, agent_type, architecture_type, agent_context, original_body)` | 组装 body + 注入 W3C `_trace_carrier` / `_trace_parent`，`SQSClient.send_message` 带 `message_attributes={task_type, stage}` |
| `_post_deployment` | `(project_id, result)` | ① `update_agent(status=running)`；② 从 S3 拉 README 到 `projects/&lt;project_id&gt;/README.md`；③ 向量索引 (`_index_build_artifacts`)；④ `PromptManager.reload()` |
| `_post_skill_deployment` | `(project_id, result)` | `SkillManager.register_built_skill()` + 同步本地 |

`MAX_RETRY_ON_PARSE_FAILURE = 3`（`engine_v2.py:4748`）— JSON 解析重试在 `WorkflowEngineV2._parse_and_validate_output`。

### `worker/handlers/metrics_rollup_handler.py::MetricsRollupHandler`

| 方法 | 签名 | 职责 |
|------|------|------|
| `handle` | `(message) -> bool` | 读 `rollup_type ∈ {hourly, daily, monthly}`，分支到 `rollup_hourly/daily/monthly` |
| `rollup_hourly` | `(hour: datetime) -> int` | ① `_list_agent_ids` 列 agent_id 维度值 → 批量 `_query_many_agent_metrics` → `_upsert_hourly`；② `_list_dim_values(ns, "agent.invocations", "user_id")` → `_query_many_user_metrics` → `_upsert_user_daily` |
| `_query_agent_batch` | `(cw, ns, start, end, agent_ids: List[str])` | 单次 `CloudWatch:GetMetricData` 查 `len(agent_ids)*10` 个 metric（`inv/d50/d90/d99/err/tc/tki/tko/tcr/tcw`），按 `"&lt;prefix&gt;_&lt;idx&gt;"` Id 拆分结果；批大小 `_GMD_BATCH_LIMIT // per_agent`，`_GMD_BATCH_LIMIT = 500` |
| `_agent_metric_queries` | `(ns, agent_id, idx)` | 构造单个 agent 的 10 条 MetricDataQuery，维度基 `{OTelLib=nexus-ai, agent_id}`；tokens 额外含 `direction ∈ {input, output, cache_read, cache_write}` |
| `_upsert_hourly` / `_upsert_user_daily` | `(row)` | `INSERT ... ON CONFLICT` 到 `agent_metrics_hourly` / `user_metrics_daily` |

### `worker/handlers/quota_check_handler.py::QuotaCheckHandler`

| 方法 | 签名 | 职责 |
|------|------|------|
| `handle` | `(message) -> bool` | 解析 `month`，调 `_check_quotas` |
| `_check_quotas` | `(month: date) -> List[Dict]` | join `user_metrics_monthly × user_quotas` 计算 `used_pct`；阈值匹配后 `alert_type ∈ {exceeded, threshold_reached}`；检 `quota_alerts` 幂等；插入 + 调用 `_send_notification` |
| `_send_notification` | `(user_id, alert_type, used_pct, cost, budget) -> channel` | 读环境 `NEXUS_QUOTA_SNS_TOPIC`，优先 SNS + `security_log`；否则仅 audit 日志；返回 `"sns"` 或 `"audit_log"` |

### `nexus_utils/workflow/engine.py::WorkflowEngine` (V1)

| 方法 | 签名 | 职责 |
|------|------|------|
| `__init__` | `(project_id, config=None, db_client=None)` | 读 `config.workflow_type`（默认 `agent_build`），创建 `WorkflowContextManager` |
| `load_context` | `() -> WorkflowContext` | 通过 `context_manager.load_from_db(project_id)` 懒加载 |
| `validate_prerequisites` | `(stage_name) -> bool` | 用 `context.get_prerequisite_stages`，缺失抛 `PrerequisiteError` |
| `execute_single_stage` | `(stage_name, input_message=None, state=None, skip_validation=False) -> StageOutput` | 刷 control 状态、标记 running、执行 → 按 `control_status` 抛 `WorkflowControlSignal(PAUSE/STOP)` |
| `execute_from_stage` | `(stage_name, to_completion=True, state=None) -> ExecutionResult` | 顺序执行 `[stage_name, …]`；遇 `StageExecutionError` / 异常保存失败状态并返回 |
| `execute_to_completion` | `(state=None) -> ExecutionResult` | 从 `context.get_next_stage()` 开始 `execute_from_stage` |
| `pause` / `stop` / `resume` | `() -> bool` / `(from_stage=None) -> bool` | 写 `context.control_status`，设本地 `_pause_requested` / `_stop_requested` 标志 |
| `_check_control_signals` | `() -> None` | `_refresh_control_status` + 抛 `WorkflowControlSignal` |
| `_refresh_control_status` | `() -> None` | 从 DDB 重新读 `control_status`，支持 API 侧通过 DDB 远程控制 |
| `get_status` | `() -> Dict` | 快照：`project_id / status / control_status / current_stage / completed_stages / pending_stages / aggregated_metrics` |

模块级便捷：`create_workflow_engine(project_id, config)`、`run_workflow(project_id, from_stage, to_completion, state)`、`run_workflow_legacy(user_input, session_id, project_id)`。

### `nexus_utils/workflow/engine_v2.py::WorkflowEngineV2`

| 方法 | 签名 | 职责 |
|------|------|------|
| `execute_stage` | `(stage_name, agent_id=None, agent_context=None) -> StageExecutionResult` | 主流程：读 `stage_config` → `_mark_stage_running` → `_build_agent_input` → `_execute_agent` → `_parse_and_validate_output`（含 3 次重试）→ `_update_project_from_stage_result` → `_save_stage_result` → 按 `fork_on_complete` / `join_after_complete` 填 fork/join 信号 |
| `_build_stage_key` | `(stage_name, agent_id)` | `agent_id` 存在则 `"&lt;stage&gt;#&lt;agent_id&gt;"`，否则 `"&lt;stage&gt;"` |
| `_build_agent_input` | `(stage_name, agent_id, agent_context)` | 拼装：base rules（`get_base_rules(wf_type)`） + 工作流规则（按 `stage_config.rule_keys` 选择）+ 前置阶段结果（按 `prerequisites + scope`）+ Project Info + `agent_update` 时 Source Agent Info + Current Agent Info |
| `_execute_agent` | `(stage_name, agent_input, stage_config) -> (raw_output, metrics)` | 通过 `create_agent_from_prompt_template(agent_name=&lt;prompt_base_path&gt;/&lt;prompt_file&gt;, env='production')` 创建并调用 Agent；提取 `metrics.get_summary().accumulated_usage` 中 `inputTokens/outputTokens`、`tool_usage.*.execution_stats.call_count`、`accumulated_metrics.latencyMs` |

### `nexus_utils/workflow/executor.py::StageExecutor` (V1)

| 方法 | 职责 |
|------|------|
| `create_agent(stage_name, state)` | 从 `_stage_prompt_mapping` 取提示词路径，调 `create_agent_from_prompt_template` |
| `format_context(stage_name)` | 委托 `get_stage_context(include_rules=True, include_local_docs=True)` |
| `execute_stage(stage_name, input_message=None, state=None)` | 多 Agent 时委托 `MultiAgentStageExecutor`；单 Agent 时创建 Agent + 调用 + 收集 metrics + 扫描生成文件 |
| `should_iterate(stage_name)` | `stage_name ∈ ITERATIVE_STAGES` 且多 Agent |

`ITERATIVE_STAGES` 来自 `api.v2.core.stage_config`，`STAGE_PROMPT_MAPPING = get_prompt_path_mapping()`（`executor.py:5239`）。

### `nexus_utils/workflow/context.py::WorkflowContextManager`

| 方法 | 职责 |
|------|------|
| `load_from_db(project_id) -> WorkflowContext` | 读 `projects` + `list_stages`，构造 `stage_outputs`、解析 `control_status`、`aggregated_metrics`、`created_at` 等 |
| `_parse_intent_result(orchestrator_content)` | 正则抽取 agent 名称；含 `multi agent` 关键字则 `workflow_type='multi_agent'` |
| `_load_workflow_rules()` | 从 `&lt;repo&gt;/config/nexus_ai_base_rule.yaml` 读规则文件，带 `_rules_cache` |
| `save_to_db(context)` | 先从 DDB 刷 `control_status` 防覆盖；`StageStatus → ProjectStatus` 映射；更新 `projects` + 逐阶段 `update_stage` |
| `get_stage_context(context, stage_name, include_rules=True, include_local_docs=True, max_tokens=100000)` | 拼装 `base_parts`：rules、project_name 约束、`intent_result`、用户需求 + 已完成前置阶段输出（用 `summarize_stage_output` 压到每阶段预算） + local docs |

### `nexus_utils/workflow/multi_agent.py::MultiAgentIterator`

| 方法 | 职责 |
|------|------|
| `_parse_architecture()` | 先试 `_parse_json_architecture`（````json``` 块），失败后 `_parse_markdown_architecture`（三种模式：`## Agent: name` / `- **Name**: desc` / 表格） |
| `get_agents_for_stage(stage_name)` | 仅对 `ITERATIVE_STAGES` 返回，`_sort_agents_by_dependency` 做拓扑排序 |
| `format_agent_context(agent, stage_name, base_context)` | 在 `base_context` 后拼 `## 当前处理的 Agent` + `## 其他 Agent` 段 |
| `get_progress(agent_name) / update_progress(...)` | 维护 `Dict[str, AgentStageProgress]` |

`STAGE_TO_PROGRESS_STAGE = {"agent_design": "agent_design", "tools_developer": "tool_development", "prompt_engineer": "prompt_engineering", "agent_code_developer": "code_development"}`（V1 阶段名，V2 映射由 `workflows.yaml.legacy_name_mapping` 处理）。

### `nexus_utils/workflow/validator.py`

`PromptValidator`：
- `validate_tool_paths(prompt_path, strict=False) -> ValidationResult` — 从 `metadata.tools_dependencies` 与 `versions[].tools` 提取路径，对每个 `strands_tools/` / `system_tools/` / `generated_tools/` / `template_tools/` 前缀路径通过 `importlib.import_module` 验证。
- `validate_all_workflow_prompts() -> ValidationResult` — 遍历 `STAGE_PROMPT_MAPPING` 全量验证。

`DocumentValidator`：`STAGE_DOCUMENT_FORMATS` 按阶段约束格式（`requirements_analysis` → markdown + 必含段 `需求概述/功能需求/非功能需求`，`system_architecture` → json + `architecture_type/components`，`tools_developer` → python + 正则 `@tool`、`def`，`prompt_engineer` → yaml + `agent/name/system_prompt`，`agent_code_developer` → python + `from\s+nexus_utils` / `create_agent`）。

### `nexus_utils/workflow/agent_validator.py::AgentValidator`

`validate_all() -> AgentValidationResult`：依次运行
1. `validate_prompt_path()` — 在 `prompts/generated_agents_prompts/&lt;name&gt;(.yaml|/prompt.yaml)` 找 YAML；校验 `agent.name/description/versions[0].system_prompt`。
2. `validate_tool_dependencies()` — 从 `agent.metadata.tools_dependencies` 逐条 `_validate_single_tool`：`strands_tools/&lt;name&gt;` → `hasattr(strands_tools, name)`；`system_tools/`/`generated_tools/` → 检查 `tools/&lt;category&gt;/<...>.py` 或目录。
3. `validate_agent_factory()` — 调 `create_agent_from_prompt_template(agent_name=f"generated_agents_prompts/{project_name}", env="production", enable_logging=False)` 并验 `agent is not None and hasattr(agent, '__call__')`。

### `nexus_utils/workflow/file_sync.py`

- `FileMetadataManager.scan_project_files(project_id, project_name)` — 递归扫 `projects/&lt;project_name&gt;` 或 `projects/&lt;project_id&gt;`，对每个非隐藏文件计算 `size / md5 / mtime`。
- `FileMetadataManager.save_file_metadata(project_id, stage_name, files)` — 写入 `stages[stage].generated_files`。
- `FileMetadataManager.get_file_content(project_id, file_path, project_name=None)` — 优先 UTF-8 文本，UnicodeDecodeError 时返回 base64。
- `FileSyncConfig(s3_bucket='nexus-ai-workflow-files', s3_prefix='workflow-files/', local_base_path='projects', auto_sync=True)`。

## 工作流阶段表（`config/workflows.yaml`）

### agent_build V2 (`prompt_base_path: system_agents_prompts/agent_build_workflow`)

| order | name | scope | prerequisites | rule_keys | fork/join | supports_iteration |
|------:|------|-------|---------------|-----------|-----------|--------------------|
| 1 | `intent_recognition` | project | [] | [] | — | false |
| 2 | `requirements_analysis` | project | `intent_recognition` | [] | — | false |
| 3 | `system_architecture` | project | `requirements_analysis` | `generation_rules` | **fork_on_complete=true** | false |
| 4 | `agent_design` | agent | `requirements_analysis`, `system_architecture` | `generation_rules` | — | false |
| 5 | `tools_development` | agent | `agent_design` | `directory_rules, generation_rules, cache_rules, external_resources, custom_rules` | — | **true** |
| 6 | `prompt_development` | agent | `requirements_analysis`, `tools_development` | 同上 | — | **true** |
| 7 | `code_development` | agent | `prompt_development` | 同上 | **join_after_complete=true** | **true** |
| 8 | `deployment` | project | `system_architecture`, `code_development` | `directory_rules` | **join_before_start=true** | false |

V1 兼容映射（`legacy_name_mapping`）：`orchestrator → intent_recognition`、`requirements_analyzer → requirements_analysis`、`system_architect → system_architecture`、`agent_designer → agent_design`、`tools_developer / tool_developer → tools_development`、`prompt_engineer → prompt_development`、`agent_code_developer / agent_developer_manager → code_development`、`agent_deployer → deployment`。

### agent_update (`prompt_base_path: system_agents_prompts/agent_update_workflow`)

| order | name | scope | prerequisites | optional |
|------:|------|-------|---------------|----------|
| 1 | `update_orchestrator` | project | [] | false |
| 2 | `requirements_update` | project | `update_orchestrator` | false |
| 3 | `tool_update` | project | `requirements_update` | **true**（可被 `skip_stages` 跳过） |
| 4 | `prompt_update` | project | `tool_update` | **true** |
| 5 | `update_deployment` | project | `prompt_update` | false |

V1 兼容：`code_update → update_deployment`。

### tool_build (`prompt_base_path: system_agents_prompts/tool_build_workflow_v2`)

`intent_recognition` → `tool_design` → `tool_development`（supports_iteration）→ `tool_validation` → `tool_deployment`，全部 `scope: project`。

### skill_build (`prompt_base_path: system_agents_prompts/skill_build_workflow`)

`intent_recognition` → `skill_design` → `skill_development`（supports_iteration）→ `skill_validation` → `skill_deployment`，全部 `scope: project`。

### magician

单阶段 `magician_orchestrator`，负责意图识别并路由到其他工作流。

### defaults（同文件）

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

## 调用关系

### V2 消息处理主流程

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
            └─ if handler 返回 True: sqs_client.delete_message
               else:                 留给 SQS 重投（受 MAX_RETRY_COUNT 限制）
```

### V2 单阶段执行（`BuildHandlerV2 → WorkflowEngineV2`）

```
BuildHandlerV2.handle
  │
  ├─ extract trace (_trace_carrier OR _trace_parent)
  ├─ push_context(MetricContext)
  ├─ tracer.start_as_current_span("worker.stage.<stage>")
  └─ _execute_stage
       │
       ├─ get_project(project_id).status ∈ {paused, cancelled} → return True (删消息)
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
            ├─ _parse_and_validate_output(raw_output)   # JSON 解析，≤3 次重试
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
                                           agent_update 额外 _skip_optional_stages
```

### V1 执行（`BuildHandler → WorkflowEngine`）

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
                           ├─ validate_prerequisites(stage) (跳过)
                           ├─ _check_control_signals()      # 从 DDB 读 control_status
                           ├─ stage_service_v2.mark_stage_running
                           └─ StageExecutor.execute_stage(stage, state)
                                ├─ should_iterate(stage) 且多 Agent
                                │    → MultiAgentStageExecutor.execute_for_all_agents
                                │         └─ for each agent: MultiAgentIterator.format_agent_context + create_agent + invoke
                                └─ else
                                     ├─ create_agent(stage, state)
                                     ├─ format_context(stage) → get_stage_context(context)
                                     ├─ agent(input)
                                     └─ collect StageMetrics + FileMetadata
```

## 扩展点（Extending）

### 1. 添加新的 workflow 阶段

文件：`config/workflows.yaml`。在对应 workflow 的 `stages` 列表追加：

```yaml
- name: "<new_stage_name>"
  display_name: "<中文显示名>"
  agent_display_name: "<Agent 显示名>"
  prompt_file: "<prompt_base_path 下的文件名，不带扩展名>"
  log_filename: "<log 标签>"
  order: <整数>                  # 决定顺序
  scope: "project" | "agent"    # 决定是否按 agent 展开
  prerequisites: ["<前置阶段名>", ...]
  rule_keys: ["directory_rules", "generation_rules", ...]  # 可选，控制注入哪些规则
  supports_iteration: false | true
  optional: false | true         # 可被 skip_stages 跳过
  fork_on_complete: false | true # 完成后 fork 为多 agent
  join_after_complete: false | true
  join_before_start: false | true
```

随后：

1. 在 `prompts/&lt;prompt_base_path&gt;/&lt;prompt_file&gt;.yaml` 放置 Agent 提示词模板（`agent.name / description / versions[].system_prompt / metadata.tools_dependencies`）。
2. **无需** 改 Worker 代码：`WorkflowEngineV2` 通过 `workflow_config.get_stage_sequence()` 自动识别；`BuildHandlerV2._get_next_stage` 顺序分发。
3. 若阶段为 `agent` 级，需要 `fork_on_complete=true` 的上游阶段（如 `system_architecture`）在 `stage_result` 中产出 `fork_targets` 所需的 agent 列表。
4. 若阶段需要向本地 `projects/&lt;name&gt;/` 写入文件，请把路径写到 `generated_files` 的 `StageOutput` 中，便于 `FileMetadataManager.get_file_content` 追溯。

### 2. 添加新的 workflow 类型

1. 在 `config/workflows.yaml` 顶层加 `&lt;new_wf_type&gt;:` block（参照 `skill_build` / `tool_build`）。
2. 在 `WorkflowHandler.SUPPORTED_WORKFLOWS` 列表里加上名字（`worker/handlers/workflow_handler.py:1823`）。
3. 在 `WorkflowHandler._dispatch` 路由分支里决定：走 V2（`BuildHandlerV2`）还是单独的 handler。V2 兼容所有 `workflow_type ∈ {agent_build, agent_update, skill_build, tool_build}`，新类型默认走 V2 只需让 `_handle_agent_build_v2` 接受此类型，或在 `_execute_stage` 的部署后置分支（`_post_deployment` / `_post_skill_deployment` / `_post_tool_deployment` / `_post_update_deployment`）加新的分支。
4. 如果是运维任务（非用户构建），参考 `metrics_rollup` / `quota_check`：
   - 在 `worker/handlers/` 新建 `&lt;task&gt;_handler.py`，实现 `def handle(self, message: Dict) -> bool`；
   - 在 `WorkflowHandler._dispatch` 顶部根据 `body['task_type']` 分发。

### 3. 添加新的 SQS 队列

目前 `Worker.__init__` 只识别 `build` / `deploy`（`worker/main.py:2457`）：

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

新增队列：
1. 在 `worker/config.py::WorkerSettings` 加 `SQS_<NEW>_QUEUE_NAME`（并在 `config/default_config.yaml.sqs.queues` 加键）。
2. 在 `Worker.__init__` 加 `elif queue_type == "&lt;new&gt;":` 分支。
3. 在 `argparse.add_argument('--queue', choices=[...])` 加入新 choice（`worker/main.py:2656`）。
4. 实现对应 handler 并在 `else` 前赋值。

### 4. 添加 handler 或修改分发

- **不要**直接继承 `BuildHandlerV2`。V2 路径设计为一条消息 = 一个阶段；扩展点应在 `workflows.yaml`。
- **运维 handler**应像 `MetricsRollupHandler` / `QuotaCheckHandler` 一样是独立类，用 `body['task_type']` 路由。
- handler 必须具备 `def handle(self, message: Dict[str, Any]) -> bool`，语义：**返回 True 即 ACK（SQS 删除消息）**；返回 False → SQS 在 `VISIBILITY_TIMEOUT` 后重投（受 `MAX_RETRY_COUNT` 限制进入 DLQ）。
- **幂等性**是强制约束：同一消息可能被消费多次。V2 的 `_execute_stage` 在执行前检查 `stages.stage_key` 状态为 `completed/running` 即直接返回 True。

### 5. 自定义 Agent 验证

继承或调用 `nexus_utils.workflow.agent_validator.AgentValidator`：

```python
from nexus_utils.workflow import validate_agent

result = validate_agent(project_name="my_agent")  # -> AgentValidationResult
if not result.is_valid:
    for issue in result.issues:
        if issue.level == ValidationLevel.ERROR:
            raise RuntimeError(str(issue))
```

或批量 `validate_multiple_agents(project_names)`。

### 6. 约束与陷阱

- **线程安全**：`Worker._poll_and_process` 串行处理消息（`MAX_MESSAGES_PER_POLL=1`）；心跳线程 `HeartbeatThread` 是 daemon，与主消息处理共享 `receipt_handle`，但只发 `change_message_visibility`，不修改其他状态。
- **环境变量副作用**：V1 的 `_execute_with_workflow_engine` 会设置 `NEXUS_STAGE_TRACKER_PROJECT_ID` / `NEXUS_UPDATE_AGENT_ID` / `NEXUS_TOOL_NAME` / `NEXUS_TARGET_AGENT`，`finally` 中必须清理。若你的扩展也在进程全局设置环境变量，**必须使用 `try/finally`** 避免污染下一条消息。
- **strands 非交互**：`worker/main.py:2397` 预置 `BYPASS_TOOL_CONSENT=true` 与 `STRANDS_NON_INTERACTIVE=true`。不要在 Worker 进程内调用需要 TTY 的工具。
- **日志 handler**：`worker/main.py:2435` 会**清空** `config_loader` 设的 `FileHandler` 并加一个 `StreamHandler(stdout)`。如果你的新模块依赖写 `nexus_ai.log`，需要改 `service_manager` 的 stdout 重定向策略而非恢复 FileHandler。
- **Observability 初始化顺序**：`_setup_observability(service_name="nexus-ai-worker")` 必须在 `boto3` 相关模块导入前完成（`worker/main.py:2416`）。新增顶层 import 时注意这一点。
- **Trace context 双写**：V2 发送 SQS 消息时同时写 `_trace_carrier`（W3C 完整）与 `_trace_parent`（trace_id hex）。消费时优先 `_trace_carrier`；缺失才用 `_trace_parent` 作为 `Link` 弱关联。`_trace_parent` 是过渡兼容字段，M2 之后可能下线。
- **控制状态优先**：`WorkflowContextManager.save_to_db` 在每次保存前会从 DDB 重新拉一次 `control_status`，若 API 侧已置为 `paused/stopped`，本地保存不会覆盖（`context.py:3840`）。扩展代码若绕过 `save_to_db` 直接写 `projects` 表，**可能覆盖用户的暂停操作**。
- **内容大小**：`StageOutput.MAX_CONTENT_SIZE = 400 * 1024` 字节。超出时 `content` 置空，用 `s3_content_ref` 指向 S3 对象。
- **Token 估算**：`estimate_tokens` 使用 `len(text) // 4` 的粗略估算（`context.py:3501`）；不要用于计费。
- **JSON 解析重试**：`WorkflowEngineV2._parse_and_validate_output` 最多重试 3 次（`MAX_RETRY_ON_PARSE_FAILURE`）。重试在**同一 SQS 消息内**发生；失败则整阶段失败，消息按普通规则重投。

## 调试与故障排查

### 日志关键词

| 关键词 | 出处 | 含义 |
|--------|------|------|
| `[POLL] queue=&lt;name&gt; region=&lt;r&gt;: None` | `worker/main.py:2551` | 一次空轮询 |
| `[POLL] queue=&lt;name&gt; region=&lt;r&gt;: stage=&lt;s&gt;, project=&lt;p&gt;, agent=&lt;a&gt;` | `worker/main.py:2559` | 取到消息摘要 |
| `Processing message &lt;id&gt;` | `worker/main.py:2576` | 开始处理 |
| `Heartbeat: extended message visibility` | `worker/main.py:2628` | 心跳成功（DEBUG） |
| `[V2][STAGE-DONE] stage=... project=... agent=...` | `build_handler_v2.py:907` | V2 阶段完成 |
| `[V2][FORK-TARGET] agent_id=... type=... context=...` | `build_handler_v2.py:916` | fork 目标快照 |
| `[V2] Forking: N agents` / `[V2] All agents completed, dispatching deployment` | `build_handler_v2.py` | 分发控制 |
| `[V2] Sent SQS: stage=&lt;s&gt;, agent=&lt;a|project&gt;` | `build_handler_v2.py:1090` | 下一阶段已入队 |
| `[V2] Project &lt;id&gt; is paused/cancelled, skipping stage &lt;s&gt;` | `build_handler_v2.py:868` | 用户暂停命中 |
| `Stage &lt;name&gt; marked as running via stage_service` | `engine.py:4323` | V1 阶段开始 |
| `Resuming from checkpoint: stage=&lt;s&gt;, completed=[...]` | `build_handler.py:251` | V1 断点恢复 |
| `Prerequisites not met for stage &lt;s&gt;: missing [...]` | `engine.py:4277` | V1 前置未完成 |
| `[metrics-rollup] type=&lt;t&gt;, target=&lt;x&gt;` / `upserted N rows` | `metrics_rollup_handler.py` | 指标回填 |
| `[quota-check] checking quota for month=&lt;m&gt;` / `fired N alerts` | `quota_check_handler.py` | 配额检查 |
| `trace context extract/inject failed: &lt;e&gt;` | `build_handler_v2.py:790/1073` | OTel 可忽略（非致命） |

### 常见异常

| 异常 | 含义 | 常见原因 | 排查 |
|------|------|----------|------|
| `PrerequisiteError` | V1 前置阶段未完成 | SQS 消息指定了 `target_stage`，但 DDB 中该阶段的 `prerequisites` 未全 `completed` | 查 `list_stages(project_id)`；确认 `_check_resume_state` 返回值 |
| `StageExecutionError` | 阶段 Agent 执行失败 | 模型调用失败、工具未找到、提示词非法 | 看 `error_message` + Agent trace span |
| `WorkflowControlSignal(PAUSE/STOP)` | 用户主动暂停/停止 | API 层把 `projects.control_status` 改为 `paused/stopped` | 正常信号；Worker 会把 `TaskStatus` 置为 `PENDING`/`CANCELLED` 并 ACK |
| `Unknown stage: &lt;s&gt;` (`StageExecutionResult.error_message`) | V2 `workflows.yaml` 不含该阶段 | 工作流配置未热加载；或消息 workflow_type/stage 不匹配 | 检查 `get_workflow_config(wf_type)`；确保 Worker 重启以加载新 YAML |
| `Failed to create agent for stage &lt;s&gt;` | V2 Agent 工厂失败 | 提示词 YAML 缺失/格式错；`tools_dependencies` 不可 import | `AgentValidator.validate_all()` 复现 |
| `Invalid V2 message: missing project_id or stage` | V2 消息字段缺失 | 上游发消息逻辑有 bug | grep `message_body` 日志 |
| `SNS notify failed: ...` | `QuotaCheckHandler` | 未设置 `NEXUS_QUOTA_SNS_TOPIC` 或 IAM 权限不足 | Fallback 走 `audit_log` |

### 诊断命令

```bash
# 启动单条消息调试
python -m worker.main --queue build --once

# 查看某 project 的阶段状态
aws dynamodb query \
  --table-name nexus_stages \
  --key-condition-expression "project_id = :pid" \
  --expression-attribute-values '{":pid":{"S":"<project_id>"}}'

# 查看 build 队列当前堆积
aws sqs get-queue-attributes \
  --queue-url "$(aws sqs get-queue-url --queue-name nexus-build-queue --query QueueUrl --output text)" \
  --attribute-names ApproximateNumberOfMessages ApproximateNumberOfMessagesNotVisible

# 重试某 V1 project（通过 API 侧 resume）
curl -X POST http://<api>/v2/projects/<project_id>/resume

# 单独跑全量工作流提示词校验
python -c "from nexus_utils.workflow import validate_workflow_prompts; r = validate_workflow_prompts(); print(r.to_dict())"
```

## 延伸阅读

- 工作流配置：`config/workflows.yaml`
- Agent 工厂：`nexus_utils/agent_factory.py` → `create_agent_from_prompt_template`
- 基础规则：`config/nexus_ai_base_rule.yaml`（由 `WorkflowContextManager._load_workflow_rules` 读取）
- SQS 客户端：`api/v2/database/sqs.py::SQSClient`
- DDB 客户端：`api/v2/database/dynamodb.py::db_client`
- Observability：`nexus_utils/observability/__init__.py`、`nexus_utils/observability/metrics/build.py`
- 多 Agent 架构迭代器：`nexus_utils/workflow/multi_agent.py`
- Agent 验证：`nexus_utils/workflow/agent_validator.py::AgentValidator`
- 文件同步：`nexus_utils/workflow/file_sync.py::FileSyncManager`
- V1/V2 阶段名映射：各工作流 yaml 内 `legacy_name_mapping`
