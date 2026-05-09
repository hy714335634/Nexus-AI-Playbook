---
title: Stage 引擎
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - agents/system_agents/**
    - config/workflows.yaml
    - nexus_utils/workflow/**
  generated_at: 2026-05-09T00:14:55+00:00
  generated_by: docs-sync v2
---

# Stage 引擎

## 概述

Stage 引擎是 Nexus-AI 工作流执行的内核，负责把一条用户需求驱动的工作流切分成若干个**阶段（Stage）**，每个阶段由一个 Agent（基于提示词模板）执行，产出的 `StageOutput` 作为下一阶段的上下文输入。代码主要位于 `nexus_utils/workflow/`，阶段序列、Agent 显示名、前置关系、规则注入键等在 `config/workflows.yaml` 中静态声明。

引擎存在两套共存的实现：

- **V1：`nexus_utils/workflow/engine.py::WorkflowEngine`** — 一次性顺序执行全部阶段，DynamoDB 持久化上下文，支持 pause/resume/stop。`agent_build_workflow.py`、`agent_update_workflow.py`、`tool_build_workflow.py` 是其顺序调用版本，用于本地脚本与早期工作流。
- **V2：`nexus_utils/workflow/engine_v2.py::WorkflowEngineV2`** — 每次只执行**一个阶段**，执行结果写回 DDB 后通过 SQS 触发下一阶段；支持 `scope`（project/agent）与 `fork`/`join` 并行模式，是 v2 API + Worker 的当前执行内核。

两套引擎共享 `models.py` 中的数据模型（`StageOutput`、`StageMetrics`、`WorkflowContext` 等）、`executor.py` 的 Agent 创建逻辑、`multi_agent.py` 的多 Agent 迭代器，以及 `validator.py` / `agent_validator.py` 的提示词与 Agent 验证器。`workflows.yaml` 是两套引擎的唯一配置源。

本文档覆盖：阶段生命周期、上下文组装规则、所有数据模型、阶段执行器、多 Agent 迭代、fork/join 并行、V1↔V2 差异、以及扩展新工作流所需的全部接触点。

## 文件组织（File Layout）

| 路径 | 责任 | 主要依赖 |
|------|------|----------|
| `nexus_utils/workflow/__init__.py` | 包入口，统一 re-export 所有公有类型 | `.models` `.context` `.engine` `.executor` `.validator` `.multi_agent` `.agent_validator` `.file_sync` |
| `nexus_utils/workflow/models.py` | 阶段状态枚举、`StageOutput`、`WorkflowContext`、`AggregatedMetrics` 等核心数据结构 | `api.v2.core.stage_config`（延迟导入） |
| `nexus_utils/workflow/context.py` | `WorkflowContextManager`：DynamoDB 加载/保存、阶段上下文格式化、token 估算与摘要 | `api.v2.database.db_client` `api.v2.core.stage_config` |
| `nexus_utils/workflow/engine.py` | V1 引擎：`WorkflowEngine`、`ExecutionResult`、控制信号 | `.context` `.executor` `api.v2.services.stage_service` |
| `nexus_utils/workflow/engine_v2.py` | V2 引擎：`WorkflowEngineV2`、`StageExecutionResult`、fork/join 信号 | `nexus_utils.workflow_config` `api.v2.database.dynamodb` `nexus_utils.agent_factory` |
| `nexus_utils/workflow/executor.py` | 阶段执行器：Agent 创建、指标收集、生成文件扫描 | `nexus_utils.agent_factory` `api.v2.core.stage_config` `.multi_agent` |
| `nexus_utils/workflow/multi_agent.py` | 多 Agent 架构解析与迭代执行 | `.models` |
| `nexus_utils/workflow/validator.py` | 提示词工具路径与输出文档格式校验 | `importlib` `yaml` |
| `nexus_utils/workflow/agent_validator.py` | 生成后 Agent 的提示词/工具/factory 自检 | `nexus_utils.agent_factory` `yaml` |
| `nexus_utils/workflow/file_sync.py` | 生成文件元数据采集、S3 跨 Worker 同步、文件内容 API | `boto3` `hashlib` |
| `config/workflows.yaml` | 所有工作流的阶段定义、提示词路径、前置关系、规则键、fork/join 标记 | —（YAML 配置） |
| `agents/system_agents/agent_build_workflow/agent_build_workflow.py` | V1 顺序调用版的 Agent 构建工作流 | `nexus_utils.agent_factory` `stage_tracker` |
| `agents/system_agents/agent_build_workflow/run_workflow_v2.py` | 基于 `WorkflowEngine` 的 CLI 入口（支持从任意阶段开始、暂停恢复） | `nexus_utils.workflow.engine` |
| `agents/system_agents/agent_update_workflow/agent_update_workflow.py` | Agent 更新工作流（5 阶段顺序调用） | `nexus_utils.workflow_rule_extract` `stage_tracker` |
| `agents/system_agents/tool_build_workflow/tool_build_workflow.py` | 工具构建工作流（6 阶段顺序调用） | `nexus_utils.workflow_rule_extract` |
| `agents/system_agents/*/*_agent.py` | 每个阶段对应的独立 Agent 模块（供单独调用与测试） | `nexus_utils.agent_factory` |

## 工作流配置（`config/workflows.yaml`）

`workflows.yaml` 是引擎的声明式入口。顶层由 `version`、`defaults` 与若干工作流条目（`agent_build` / `agent_update` / `tool_build` / `skill_build` / `magician`）组成。加载由 `nexus_utils/workflow_config.py` 的 `get_workflow_config(workflow_type)` 完成，`WorkflowEngineV2` 与 `StageExecutor._load_stage_prompt_mapping()` 都通过该函数获取配置。

### 全局默认

```yaml
defaults:
  execution:
    max_retries: 3                    # 阶段失败最大重试次数
    retry_delay_seconds: 5
    stage_timeout_seconds: 3600
    total_timeout_seconds: 21600
    checkpoint_interval_seconds: 60
  context:
    max_tokens: 100000                # 与 DEFAULT_MAX_CONTEXT_TOKENS 对齐
    summary_threshold_tokens: 5000
    include_rules: true
    include_local_docs: true
```

### 支持的工作流

| `workflow_type` | 名称 | 阶段数 | `prompt_base_path` | 使用场景 |
|-----------------|------|-------|---------------------|---------|
| `agent_build` | Agent Build Workflow V2 | 8 | `system_agents_prompts/agent_build_workflow` | 从自然语言构建新 Agent，支持多 Agent 并行（fork/join） |
| `agent_update` | Agent Update Workflow V2 | 5 | `system_agents_prompts/agent_update_workflow` | 对已有 Agent 做版本化更新，可用 `skip_stages` 跳过工具/提示词步骤 |
| `tool_build` | Tool Build Workflow V2 | 5 | `system_agents_prompts/tool_build_workflow_v2` | 构建 `@tool` 函数 + `requirements.txt` + `key_bindings`，注册到 `nexus_tools` DDB |
| `skill_build` | Skill Build Workflow | 5 | `system_agents_prompts/skill_build_workflow` | 构建 `SKILL.md` + `scripts/` + `references/` + `evals/` |
| `magician` | Magician 智能路由 | 1 | `system_agents_prompts/magician_workflow` | 识别意图，路由到以上某个工作流 |

### 每个 Stage 的配置字段

单个 stage 条目由 `WorkflowEngineV2` 与 `StageExecutor` 同时读取：

| 字段 | 类型 | 说明 |
|------|------|------|
| `name` | `str` | 阶段内部唯一标识（`stage_name`）。DDB 以 `stage_key` 存储，project 级为 `name`，agent 级为 `name#{agent_id}` |
| `display_name` | `str` | 前端展示名 |
| `agent_display_name` | `str` | 组装上下文时使用的 Agent 名（V1 的 `STAGE_TO_AGENT_NAME` 映射） |
| `prompt_file` | `str` | 提示词文件名（相对 `prompt_base_path`） |
| `log_filename` | `str` | 对应日志文件名 |
| `order` | `int` | 序号（`_mark_stage_running` 写入 `stage_number`） |
| `scope` | `"project"` \| `"agent"` | 阶段作用域。`agent` 级阶段要求 `agent_id` 参数 |
| `prerequisites` | `List[str]` | 前置阶段名。`_build_agent_input` 会把每个前置的 `stage_result` JSON 注入提示 |
| `rule_keys` | `List[str]` | 从工作流规则中选择性注入的子键（见下文规则注入策略） |
| `supports_iteration` | `bool` | 是否支持多 Agent 迭代（V1 看 `ITERATIVE_STAGES`，V2 看 `agent_ids` 循环） |
| `optional` | `bool` | 是否可被 `skip_stages` 跳过 |
| `fork_on_complete` | `bool` | 完成后是否 fork 为多个 agent 级阶段（agent_build 中的 `system_architecture`） |
| `join_after_complete` | `bool` | 完成后是否检查所有 Agent 汇聚（agent_build 中的 `code_development`） |
| `join_before_start` | `bool` | 开始前需要所有 Agent 完成（agent_build 中的 `deployment`） |
| `description` | `str` | 给人看的阶段说明 |

### `agent_build` 阶段总览

| order | name | scope | prerequisites | 特殊 |
|-------|------|-------|--------------|------|
| 1 | `intent_recognition` | project | — | — |
| 2 | `requirements_analysis` | project | `intent_recognition` | — |
| 3 | `system_architecture` | project | `requirements_analysis` | `fork_on_complete: true` |
| 4 | `agent_design` | agent | `requirements_analysis`, `system_architecture` | — |
| 5 | `tools_development` | agent | `agent_design` | `supports_iteration: true` |
| 6 | `prompt_development` | agent | `requirements_analysis`, `tools_development` | `supports_iteration: true` |
| 7 | `code_development` | agent | `prompt_development` | `supports_iteration: true`, `join_after_complete: true` |
| 8 | `deployment` | project | `system_architecture`, `code_development` | `join_before_start: true` |

### 旧命名兼容（`legacy_name_mapping`）

每个工作流都声明一个 V1→V2 的映射，`_normalize_stage_name()` 等工具函数用它来兼容老脚本与老数据：

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

## 核心数据模型（`nexus_utils/workflow/models.py`）

全部数据类使用 `@dataclass`，并同时提供 `to_dict()` / `from_dict()` 以支持 DynamoDB 序列化。以下为穷举：

### 枚举

#### `StageStatus` (models.py)

| 值 | 含义 |
|----|------|
| `PENDING` | 等待执行 |
| `RUNNING` | 正在执行 |
| `COMPLETED` | 执行完成 |
| `FAILED` | 执行失败 |
| `PAUSED` | 已暂停（`save_to_db` 中会映射为项目级 `paused`） |

#### `ControlStatus` (models.py)

| 值 | 含义 |
|----|------|
| `RUNNING` | 正常运行 |
| `PAUSED` | 完成当前阶段后停止（`WorkflowEngine.pause()`） |
| `STOPPED` | 完成当前 LLM 调用后停止（`WorkflowEngine.stop()`） |
| `CANCELLED` | 已取消 |

### `StageMetrics`

| 字段 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `input_tokens` | `int` | `0` | 输入 token（从 `result.metrics.accumulated_usage.inputTokens` 提取） |
| `output_tokens` | `int` | `0` | 输出 token |
| `execution_time_seconds` | `float` | `0.0` | Agent 调用总耗时 |
| `tool_calls_count` | `int` | `0` | 工具调用次数（取自 `result.metrics.tool_metrics` 长度） |
| `model_id` | `Optional[str]` | `None` | `agent.model.model_id` |

属性 `total_tokens` 返回 `input_tokens + output_tokens`。

### `FileMetadata`

| 字段 | 类型 | 说明 |
|------|------|------|
| `path` | `str` | 相对 `projects/&lt;agent_name&gt;/` 的路径 |
| `size` | `int` | 文件字节数 |
| `checksum` | `Optional[str]` | MD5 校验和 |
| `last_modified` | `Optional[datetime]` | 最后修改时间 |

### `StageOutput`

| 字段 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `stage_name` | `str` | — | 阶段名 |
| `content` | `str` | `""` | Agent 输出文本；超过 `MAX_CONTENT_SIZE = 400 * 1024` 字节时写 S3 并置 `s3_content_ref` |
| `metrics` | `StageMetrics` | `StageMetrics()` | 指标 |
| `generated_files` | `List[FileMetadata]` | `[]` | 阶段生成的文件 |
| `document_content` | `str` | `""` | 设计文档（如架构 JSON） |
| `document_format` | `str` | `"markdown"` | `markdown` / `json` / `yaml` / `python` |
| `completed_at` | `Optional[datetime]` | `None` | 完成时间 |
| `status` | `StageStatus` | `PENDING` | 当前状态 |
| `error_message` | `Optional[str]` | `None` | 失败时的错误文本 |
| `s3_content_ref` | `Optional[str]` | `None` | 超限内容的 S3 引用 |

便捷属性：`is_completed`、`is_failed`、`content_exceeds_limit`（字节数 > 400KB）。

### `IntentRecognitionResult`

| 字段 | 类型 | 默认 |
|------|------|------|
| `agent_name` | `str` | `""` |
| `agent_description` | `str` | `""` |
| `workflow_type` | `str` | `"single_agent"` |
| `complexity` | `str` | `"medium"` |
| `estimated_stages` | `List[str]` | `[]` |
| `key_features` | `List[str]` | `[]` |
| `tool_requirements` | `List[str]` | `[]` |
| `raw_analysis` | `str` | `""` |

### `AgentDefinition`

多 Agent 架构中的单个 Agent：

| 字段 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `name` | `str` | — | Agent 名 |
| `agent_type` | `str` | `"main"` | `main` / `sub` / `tool` |
| `description` | `str` | `""` | 描述 |
| `orchestration_pattern` | `str` | `"agent_as_tool"` | `agent_as_tool` / `swarm` / `graph` |
| `dependencies` | `List[str]` | `[]` | 依赖的 Agent 名 |
| `tools` | `List[str]` | `[]` | 需要的工具路径 |
| `status` | `StageStatus` | `PENDING` | 当前状态 |

### `MultiAgentArchitecture`

| 字段 | 类型 | 说明 |
|------|------|------|
| `agents` | `List[AgentDefinition]` | 所有 Agent |
| `orchestration_pattern` | `str` | 整体编排模式 |
| `main_agent` | `str` | 主 Agent 名 |
| `agent_count` | `int`（属性） | `len(agents)` |
| `agent_names` | `List[str]`（属性） | 所有名字 |

方法：`get_agent(name)`、`add_agent(agent)`。

### `AgentStageProgress`

追踪多 Agent 项目中每个 Agent 的阶段进度：

| 字段 | 类型 | 说明 |
|------|------|------|
| `agent_name` | `str` | Agent 名 |
| `stage_statuses` | `Dict[str, StageStatus]` | 各阶段状态 |
| `current_stage` | `str` | 当前阶段 |
| `AGENT_STAGES` | `List[str]` | 固定为 `["agent_design", "tool_development", "prompt_engineering", "code_development", "testing"]` |

属性：`completed_stages`、`total_stages`、`progress_percentage`。

### `AggregatedMetrics`

项目级聚合指标，`add_stage_metrics(metrics)` 会叠加：

| 字段 | 类型 | 默认 |
|------|------|------|
| `total_input_tokens` | `int` | `0` |
| `total_output_tokens` | `int` | `0` |
| `total_tokens` | `int` | `0` |
| `total_cost` | `float` | `0.0` |
| `total_execution_time` | `float` | `0.0` |
| `total_tool_calls` | `int` | `0` |

### `WorkflowContext`

运行期的核心上下文对象（略长；字段摘要）：

| 字段 | 类型 | 说明 |
|------|------|------|
| `project_id` | `str` | 项目 ID |
| `project_name` | `str` | 项目名 |
| `requirement` | `str` | 原始用户输入 |
| `intent_result` | `Optional[IntentRecognitionResult]` | 编排器阶段解析出的意图 |
| `stage_outputs` | `Dict[str, StageOutput]` | 已完成阶段的输出（键为 `stage_name`） |
| `rules` | `str` | 来自 `config/nexus_ai_base_rule.yaml` 的基础规则文本 |
| `current_stage` | `str` | 当前阶段 |
| `status` | `StageStatus` | 项目状态（会映射到 v2 `ProjectStatus`） |
| `aggregated_metrics` | `AggregatedMetrics` | 聚合指标 |
| `control_status` | `ControlStatus` | pause/stop 控制状态 |
| `pause_requested_at` / `stop_requested_at` | `Optional[datetime]` | 控制信号时间 |
| `resume_from_stage` | `Optional[str]` | 恢复起点 |
| `workflow_type` | `str` | `agent_build` / `agent_update` / `tool_build` / `skill_build` |

常用方法（在 `models.py` 末段定义）：`get_completed_stages()`、`get_pending_stages()`、`get_next_stage()`、`get_prerequisite_stages(stage_name)`、`get_stage_output(stage_name)`、`update_stage_output(stage_name, output)`。

### 模块级延迟阶段序列：`STAGE_ORDER`

`models.py` 导出 `STAGE_ORDER = _LazyStageOrder()`，通过迭代时才调用 `api.v2.core.stage_config.get_all_stage_names("agent_build")`，避免循环导入。支持 `__iter__` / `__getitem__` / `__contains__` / `index`。

## V1 引擎：`WorkflowEngine`（`engine.py`）

### 异常与信号类

| 类 | 继承 | 用途 |
|----|------|------|
| `StageExecutionError(stage_name, message, recoverable=True)` | `Exception` | 阶段执行失败（`executor.py`） |
| `WorkflowControlSignal(signal_type, message)` | `Exception` | 控制信号；`signal_type ∈ {"pause", "stop"}` |
| `PrerequisiteError(stage_name, missing_prerequisites)` | `Exception` | 前置阶段未完成 |

### `ExecutionResult`

| 字段 | 类型 | 默认 |
|------|------|------|
| `success` | `bool` | `False` |
| `completed_stages` | `List[str]` | `[]` |
| `failed_stage` | `Optional[str]` | `None` |
| `error_message` | `Optional[str]` | `None` |
| `final_status` | `StageStatus` | `PENDING` |
| `metrics` | `Dict[str, Any]` | `{}` |

### `WorkflowEngine` 公有 API

| 方法 | 签名 | 职责 |
|------|------|------|
| `__init__` | `(project_id, config=None, db_client=None)` | 初始化。`config['workflow_type']` 决定使用哪个工作流（默认 `agent_build`） |
| `context` | 属性 | 延迟加载 `WorkflowContext`（首次调用时 `load_context()`） |
| `executor` | 属性 | 延迟创建 `StageExecutor` |
| `set_callbacks` | `(on_stage_start, on_stage_complete, on_stage_error)` | 设置阶段回调；如果 executor 已存在会同步更新 |
| `load_context` | `() -> WorkflowContext` | 通过 `WorkflowContextManager.load_from_db(project_id)` 加载 |
| `validate_prerequisites` | `(stage_name) -> bool` | 检查前置阶段；缺失则抛 `PrerequisiteError` |
| `execute_single_stage` | `(stage_name, input_message=None, state=None, skip_validation=False) -> StageOutput` | 执行一个阶段；开始/结束前后调用 `_check_control_signals` |
| `execute_from_stage` | `(stage_name, to_completion=True, state=None) -> ExecutionResult` | 从指定阶段开始执行；`to_completion=True` 时顺序执行后续所有 `pending_stages` |
| `execute_to_completion` | `(state=None) -> ExecutionResult` | 从 `context.get_next_stage()` 开始执行到结束 |
| `pause` | `() -> bool` | 设 `control_status=PAUSED`，保存上下文 |
| `resume` | `(from_stage=None) -> bool` | 清控制标志，写回 `control_status=RUNNING` |
| `stop` | `() -> bool` | 设 `control_status=STOPPED` |
| `get_status` | `() -> Dict[str, Any]` | 返回 `project_id` / `status` / `control_status` / `current_stage` / 已完成/待执行阶段 / 聚合指标 |

### 控制信号的刷新机制

`_refresh_control_status()` 在每次阶段执行前后都会重新 `db.get_project(project_id)` 读取 `control_status` 字段，然后把 `paused` / `stopped` 同步到内存。这意味着**外部 HTTP 请求（api 层）把 `control_status` 写进 DDB 就能让正在跑的 Worker 在下一次检查点停下**，不需要进程间通信。

### 便捷函数

- `create_workflow_engine(project_id, config=None) -> WorkflowEngine`
- `run_workflow(project_id, from_stage=None, to_completion=True, state=None) -> ExecutionResult`
- `run_workflow_legacy(user_input, session_id=None, project_id=None) -> Dict[str, Any]` — 兼容旧 `agent_build_workflow.run_workflow()` 的返回格式（含 `session_id`、`execution_time`、`execution_order`）。

## V2 引擎：`WorkflowEngineV2`（`engine_v2.py`）

V2 的核心区别：**每次只跑一个阶段，执行成功后返回带 fork/join 信号的 `StageExecutionResult`，外层 Worker 根据信号派发下一条 SQS 消息**。

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

### `WorkflowEngineV2.execute_stage` 流程

```
execute_stage(stage_name, agent_id=None, agent_context=None)
 │
 ├─ self.workflow_config.get_stage(stage_name)        # 校验阶段存在
 ├─ stage_key = "{name}"  |  "{name}#{agent_id}"      # DDB 主键
 ├─ _mark_stage_running(stage_key, …)                 # status='running', started_at
 │
 ├─ agent_input = _build_agent_input(…)               # 见下
 ├─ raw_output, metrics = _execute_agent(…)           # create_agent_from_prompt_template + agent(input)
 ├─ stage_result = _parse_and_validate_output(…)      # JSON 解析，失败最多重试 MAX_RETRY_ON_PARSE_FAILURE=3
 ├─ _update_project_from_stage_result(…)              # Worker 侧确定性操作（如 system_architecture 生成 agent_id 写 DDB）
 ├─ _save_stage_result(…)                             # 写 DDB stage 表
 │
 └─ 返回 StageExecutionResult:
    - stage_config.fork_on_complete  → should_fork=True, fork_targets=_compute_fork_targets(stage_result)
    - stage_config.join_after_complete && agent_id → should_check_join=True,
         调用 db.update_agents_completion(project_id, agent_id, 'completed')
         检查 db.check_all_agents_completed(project_id)
```

### 规则注入策略（`_build_agent_input`）

V2 按 `workflow_type` 从 `tools.system_tools.agent_build_workflow.build_workflow_v2_tools.get_base_rules(wf_type)` 加载 JSON 规则，然后：

1. **`base` 子节点**：始终全部注入（所有阶段）。
2. **工作流子节点（如 `agent_build`）**：
   - 如果 `stage_config.rule_keys` 非空：**仅**注入这些键（典型用于 `tools_development` / `prompt_development` / `code_development` 等写文件阶段，键包括 `directory_rules` / `generation_rules` / `cache_rules` / `external_resources` / `custom_rules`）。
   - 如果 `rule_keys` 为空：注入**除** `directory_rules` / `generation_rules` 以外的所有键（典型用于设计阶段）。

### 上下文组装（V2）

`_build_agent_input` 拼接顺序：

1. **Base Rules** → 逐 key 输出 `=== Base Rule: {key} ===\n{value}`。
2. **工作流规则** → `=== {wf_type} Rule: {key} ===\n{value}`。
3. **前置阶段结果**：
   - `scope == "project"` 的前置：`db.get_stage(project_id, prereq)` 取 `stage_result`。
   - `scope == "agent"` 的前置：当前阶段是 agent 级时 `db.get_stage_by_agent(project_id, prereq, agent_id)`；当前阶段是 project 级（如 `deployment`）时 `db.list_stages_by_prefix(project_id, prereq)` 聚合所有 Agent 的结果。
4. **Project Info**：`project_id` / `project_name_cn` / `project_name_en` / `requirement` / `workflow_type` / `deployment_type` / `architecture_type` / `agent_count` / `agent_ids`，另外 `metadata` 中的 `skill_id` / `skill_name` / `dir_name` / `tool_name` 也透传。
5. **Source Agent Info**（仅 `workflow_type == "agent_update"`）：加载源 Agent 的 `agent_id` / `agent_name_cn` / `agent_name_en` / `tools` / `capabilities` / `s3_prompt_path` / `s3_tools_path` / `s3_agent_path`，以及预生成的 `new_dir_name` / `new_prompt_path` / `new_s3_tools_path` / `new_s3_prompt_path` / `new_s3_agent_path`。
6. **Current Agent Info**（agent 级阶段）：`agent_id` + SQS 消息带来的 `agent_context`。

### 输出解析与重试

`_parse_and_validate_output(stage_name, raw_output, agent_input, stage_config)` 尝试从 `raw_output` 中提取 JSON；最多重试 `MAX_RETRY_ON_PARSE_FAILURE = 3` 次。每次重试会重新创建 Agent 并带上更具体的"请输出合法 JSON"指令。

### 关键内部方法

| 方法 | 职责 |
|------|------|
| `_build_stage_key` | `stage_name` + `#{agent_id}`（agent 级） |
| `_mark_stage_running` | 写/更新 `stages` 表；同步 `projects.status='building'`、`current_stage` |
| `_mark_stage_failed` | 写 `status='failed'`、`completed_at`、`error_message` |
| `_execute_agent` | 调用 `create_agent_from_prompt_template(agent_name=…, env="production")`；metrics 从 `result.metrics.get_summary()` 的 `accumulated_usage` / `tool_usage` / `accumulated_metrics` 提取 |
| `_compute_fork_targets` | 从 `stage_result` 推导要派发的 agent 级消息列表 |
| `_save_stage_result` | 持久化 `stage_result` + `raw_output` + `metrics` 到 DDB |
| `_update_project_from_stage_result` | Worker 侧确定性操作，例如 `system_architecture` 阶段会生成 `agent_id` 并注册到 `agents` 表 |

## 阶段执行器：`StageExecutor`（`executor.py`）

V1 引擎通过 `StageExecutor` 创建 Agent、收集指标、扫描生成文件。V2 直接在 `engine_v2._execute_agent` 中内联了这一部分，但两者调用的都是 `nexus_utils.agent_factory.create_agent_from_prompt_template`。

### 构造

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

`_load_stage_prompt_mapping()` 会先调 `nexus_utils.workflow_config.get_workflow_config(workflow_type)`；读取失败时回退到 `STAGE_PROMPT_MAPPING = get_prompt_path_mapping()`（默认 agent_build）。

### `ITERATIVE_STAGES`

该常量从 `api.v2.core.stage_config.ITERATIVE_STAGES` 导入，声明哪些阶段在多 Agent 项目中需要按 Agent 迭代；与 `workflows.yaml` 中 `supports_iteration: true` 对应。

### 关键方法

| 方法 | 职责 |
|------|------|
| `should_iterate(stage_name)` | 阶段在 `ITERATIVE_STAGES` 且 `multi_agent_iterator.is_multi_agent` 时返回 `True` |
| `create_agent(stage_name, state)` | 查映射取 `prompt_path`，调 `create_agent_from_prompt_template(agent_name=prompt_path, env="production", enable_logging=True, state={…, project_id, project_name})` |
| `format_context(stage_name)` | 委托给 `context.get_stage_context()`（含规则、本地文档、前置输出） |
| `execute_stage(stage_name, input_message=None, state=None)` | 主入口；如果 `should_iterate` 则走 `_execute_iterative_stage`，否则 `_execute_single_agent_stage` |
| `_collect_metrics(agent, execution_time, result)` | 优先从 `result.metrics.accumulated_usage` 取 token；回退到 `agent.model.usage`。读 `result.metrics.tool_metrics` 为 `tool_calls_count`，读 `agent.model.model_id` |
| `_scan_generated_files(stage_name)` | 递归扫 `projects/&lt;project_name&gt;/`（回退到 `projects/&lt;project_id&gt;/`），为每个文件生成 `FileMetadata`（含 MD5） |
| `_extract_output_content(result)` | 依次尝试 `result.content` / `.message` / `.text` / `str(result)` |
| `_extract_design_document(stage_name, content)` | `requirements_analysis` → markdown；`system_architecture` → 提取 ```json 代码块并 `json.loads` 验证；`agent_design` → markdown |

## 上下文管理器：`WorkflowContextManager`（`context.py`）

### 公有 API

| 方法 | 职责 |
|------|------|
| `load_from_db(project_id) -> WorkflowContext` | 从 `projects` + `stages` 表恢复 `WorkflowContext`，并从 `config/nexus_ai_base_rule.yaml` 加载基础规则；从 `orchestrator` 阶段输出解析 `IntentRecognitionResult` |
| `save_to_db(context)` | 在写入前重新从 DDB 读 `control_status`，防止覆盖用户的 pause/stop；把 `StageStatus` 映射到 `ProjectStatus`（`RUNNING→building`、`COMPLETED→completed`、`FAILED→failed`、`PAUSED→paused`）；然后批量 `update_stage` 写回每个已完成阶段的输出 |
| `get_stage_context(context, stage_name, include_rules=True, include_local_docs=True, max_tokens=DEFAULT_MAX_CONTEXT_TOKENS)` | 产生最终传给 Agent 的提示字符串 |
| `_load_workflow_rules()` | 读 `config/nexus_ai_base_rule.yaml`，结果缓存 |
| `_parse_intent_result(content)` | 正则抓取 `agent_name`；若内容含 `multi` + `agent` 关键字则 `workflow_type="multi_agent"` |

### 上下文格式化（V1）

`get_stage_context` 拼接顺序（与旧 `agent_build_workflow.py` 的 `base_context + "\n===\n{Agent} Agent: " + content + "\n===\n"` 兼容）：

1. `# Build Workflow Kickoff\n## 必须严格遵守的规则:\n{rules}` （Requirement 9.1）
2. `## 项目名称约束`（如果设置了 `project_name`）
3. `## 意图识别结果\n{intent_result JSON}`（Requirement 9.4）
4. `## 用户原始输入\n{requirement}`（Requirement 9.3）
5. `请按顺序完成构建流程，遵守以上规则。`
6. 对每个前置 `completed_stage`，追加 `\n===\n{Agent Name} Agent: {content}\n===\n`（Requirement 9.2）；若 `estimate_tokens(content) > tokens_per_stage`，调 `summarize_stage_output()` 摘要（Requirement 9.7）
7. **本地文档**（Requirement 9.5）：如果剩余 token 预算 > 1000，`_load_local_documents(project_id, project_name)` 读取项目目录下的文档

### Token 估算与摘要

```
DEFAULT_MAX_CONTEXT_TOKENS = 100000
CHARS_PER_TOKEN = 4   # 中英文混合经验值

estimate_tokens(text) -> int                    # len(text) // 4
truncate_to_tokens(text, max_tokens) -> str     # 字符截断 + "\n\n... [内容已截断] ..."
summarize_stage_output(content, max_tokens=2000) -> str
    # 抽取标题 + 章节头
    # 抽取代码块前 10 行
    # 超长则 truncate_to_tokens
```

## 多 Agent 迭代（`multi_agent.py`）

### `MultiAgentIterator`

将 `system_architecture` 阶段输出中的多 Agent 架构解析出来，按依赖顺序迭代所有 Agent：

| 方法 | 职责 |
|------|------|
| `architecture` (property) | 延迟调用 `_parse_architecture()` |
| `is_multi_agent` (property) | `architecture.agent_count > 1` |
| `_parse_architecture()` | 先尝试 `_parse_json_architecture`（匹配 ```json 块中的 `agents` 数组），失败则 `_parse_markdown_architecture`（三种正则：`## Agent: name` / `- **name**: desc` / `\| name \| type \| desc \|`） |
| `get_agents_for_stage(stage_name)` | 若非 `ITERATIVE_STAGES` 则返回 `[]`；否则 `_sort_agents_by_dependency()` |
| `_sort_agents_by_dependency()` | 简易拓扑排序，循环依赖时 fallback 为原顺序 |
| `format_agent_context(agent, stage_name, base_context)` | 追加 `## 当前处理的 Agent` 块，以及 `## 其他 Agent` |
| `get_progress(agent_name) -> AgentStageProgress` | 懒创建每个 Agent 的进度记录 |
| `update_progress(agent_name, stage_name, status)` | 通过 `STAGE_TO_PROGRESS_STAGE` 把 stage 名映射到进度阶段（如 `tools_developer → tool_development`），更新状态 |
| `is_stage_complete_for_all_agents(stage_name)` | 遍历 Agent 进度，全部 COMPLETED 才返回 `True` |
| `get_next_agent_for_stage(stage_name)` | 按依赖顺序返回首个该阶段未完成的 Agent |

`STAGE_TO_PROGRESS_STAGE` 映射：

```
"agent_design"         -> "agent_design"
"tools_developer"      -> "tool_development"
"prompt_engineer"      -> "prompt_engineering"
"agent_code_developer" -> "code_development"
```

### `MultiAgentStageExecutor`

| 方法 | 职责 |
|------|------|
| `should_iterate(stage_name)` | `iterator.is_multi_agent and stage_name in MultiAgentIterator.ITERATIVE_STAGES` |
| `execute_for_agent(stage_name, agent, base_executor, base_context, state=None)` | 格式化 Agent 上下文；把 `state['current_agent'] / 'agent_type' / 'is_multi_agent' / 'total_agents'` 注入；调 `base_executor.execute_stage(stage_name, input_message=agent_context, state=…)` |
| `execute_iterative_stage(stage_name, base_executor, base_context, state=None) -> StageOutput` | 拿到 `agents`（按依赖顺序），逐个调 `execute_for_agent`，最终 `_merge_outputs` 合并为单一 `StageOutput`（内容拼接、指标累加） |

## 验证器

### `PromptValidator`（`validator.py`）

| 方法 | 职责 |
|------|------|
| `validate_tool_paths(prompt_path, strict=False)` | 读提示词 YAML，提取 `metadata.tools_dependencies` + `versions[].tools`，逐一 `_check_tool_exists`；默认把失败作为 warning，`strict=True` 升级为 error |
| `validate_all_workflow_prompts()` | 遍历 `STAGE_PROMPT_MAPPING`，逐阶段 `validate_tool_paths` |
| `_check_tool_exists(tool_path)` | 按前缀分派：`strands_tools/` → `strands_agents.tools`；`system_tools/` → `tools.system_tools.…`；`generated_tools/` → `tools.generated_tools.…`；`template_tools/` → `tools.template_tools.…` |

### `DocumentValidator`

按阶段定义期望文档格式：

| 阶段 | 格式 | 必要字段/章节/模式 |
|------|------|---------------------|
| `requirements_analysis` | markdown | `需求概述` / `功能需求` / `非功能需求` |
| `system_architecture` | json | `architecture_type` / `components` |
| `agent_design` | markdown | `Agent 设计` / `能力定义` |
| `tools_developer` | python | `@tool` / `def\s+\w+` |
| `prompt_engineer` | yaml | `agent` / `name` / `system_prompt` |
| `agent_code_developer` | python | `from\s+nexus_utils` / `create_agent` |

### `AgentValidator`（`agent_validator.py`）

在 Agent 生成后跑三项自检：

| 方法 | 检查内容 |
|------|----------|
| `validate_prompt_path()` | 提示词文件存在；YAML 可解析；含 `agent.name` / `agent.description`（缺失为 warning）；`agent.versions[*]` 至少一个含 `system_prompt` |
| `validate_tool_dependencies()` | 逐个工具 `_validate_single_tool`：strands 内置工具查 `hasattr(strands_tools, name)`；`system_tools/` 或 `generated_tools/` 查 `tools/&lt;dir&gt;/&lt;parts&gt;` 是否存在 |
| `validate_agent_factory()` | 实际调 `create_agent_from_prompt_template(agent_name=f"generated_agents_prompts/{project_name}", env="production")`，校验返回对象 callable |

返回 `AgentValidationResult`（含 `issues: List[ValidationIssue]`、`error_count` / `warning_count` / `prompt_path_valid` / `tools_valid` / `factory_valid`）。

## 文件同步（`file_sync.py`）

| 类 | 职责 |
|----|------|
| `FileSyncConfig` | S3 桶名（默认 `nexus-ai-workflow-files`）、前缀（`workflow-files/`）、`local_base_path`、`auto_sync` |
| `FileMetadataManager` | `scan_project_files(project_id, project_name)` 扫描 `projects/&lt;name&gt;/`（fallback `projects/&lt;id&gt;/`），生成带 MD5 的 `FileMetadata` 列表；`save_file_metadata(project_id, stage_name, files)` 写入 `stages.generated_files`；`get_file_content(project_id, file_path, project_name=None)` 文本读或 base64 回退 |
| `FileSyncManager` | `sync_to_s3(project_id, project_name, files=None)` 上传；`sync_from_s3(project_id, project_name, files=None)` 下载；S3 key 形如 `{s3_prefix}{project_id}/{relative_path}` |

## 调用关系 / 数据流

### V1 完整流

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

### V2 单阶段流（SQS 驱动）

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
      ├─ agent_input = _build_agent_input(…)    ──► DDB (前置 stage_result) + rules JSON
      ├─ raw_output, metrics = _execute_agent(…)  ──► Agent Factory → Bedrock
      ├─ stage_result = _parse_and_validate_output(…, retry≤3)
      ├─ _update_project_from_stage_result(…)   (例如 system_architecture 生成 agent_id)
      ├─ _save_stage_result(…)   ──► DDB stages (status=completed, stage_result JSON)
      │
      └─ return StageExecutionResult:
           ├─ should_fork?      → Worker 派发 N 条 SQS agent 级消息
           └─ should_check_join? → 判断是否可以触发下一个 project 级阶段
```

## 扩展点（Extending）

### 1. 新增一个工作流

最小改动：

1. **在 `config/workflows.yaml` 添加顶层条目**，模仿 `tool_build` 的结构：`name` / `display_name` / `description` / `version` / `enabled: true` / `prompt_base_path` / `stages[]` / `legacy_name_mapping`。每个 stage 至少填 `name` / `display_name` / `agent_display_name` / `prompt_file` / `order` / `scope` / `prerequisites` / `supports_iteration` / `optional` / `description`。
2. **为每个 `stage.prompt_file` 创建提示词 YAML**，路径是 `prompts/{prompt_base_path}/{prompt_file}.yaml`。
3. **如果需要基础规则**：在 `tools.system_tools.agent_build_workflow.build_workflow_v2_tools.get_base_rules(wf_type)` 添加对应的规则 JSON 分支，并为 stage 的 `rule_keys` 声明需要注入的子键。
4. **V1 入口**：`WorkflowEngine(project_id, config={'workflow_type': '<新工作流名>'})` 即可运行；不需要额外代码。
5. **V2 入口**：由 v2 Worker 根据 `project.workflow_type` 自动路由；不需要额外代码。

### 2. 新增一个阶段

1. 在 `workflows.yaml` 的 `stages` 数组里插入新条目，设置正确的 `order` 与 `prerequisites`。
2. 创建 `prompts/{prompt_base_path}/{prompt_file}.yaml`，至少包含 `agent.name` / `agent.description` 与一个 `versions[]` 条目（含 `system_prompt`）。
3. 如果该阶段产出**设计文档**：在 `executor.py::_extract_design_document` 的 `design_stages` 字典中添加 `"&lt;stage_name&gt;": "&lt;format&gt;"`。
4. 如果该阶段产生文件但**不在 `projects/&lt;name&gt;/`**，修改 `executor.py::_scan_generated_files` 的扫描路径。
5. 如果该阶段输出需要**格式校验**：在 `validator.py::DocumentValidator.STAGE_DOCUMENT_FORMATS` 添加规则。
6. 如果该阶段属于**多 Agent 迭代阶段**：在 `api.v2.core.stage_config.ITERATIVE_STAGES` 添加阶段名，并在 `multi_agent.py::MultiAgentIterator.STAGE_TO_PROGRESS_STAGE` 添加映射。
7. 如果该阶段有 **fork/join** 语义（V2）：在 `stages` 条目上设 `fork_on_complete: true` 或 `join_after_complete: true` / `join_before_start: true`；fork 的具体目标在 `engine_v2._compute_fork_targets` 里实现（需要读当前阶段的 `stage_result`）。

### 3. 新增一个 Agent 到既有多 Agent 架构

不需要改代码。`system_architecture` 阶段的 Agent 会直接在输出 JSON 中加入新 Agent 的 `{name, type, description, dependencies, tools, orchestration_pattern}`；`MultiAgentIterator._parse_json_architecture` 会识别；后续 `agent_design` / `tools_development` / `prompt_development` / `code_development` 阶段会自动迭代到它。

### 4. 添加一个新的"迭代"语义阶段

V1：在 `api.v2.core.stage_config.ITERATIVE_STAGES` 添加阶段名。V2：在 `workflows.yaml` 上设 `supports_iteration: true` 且 `scope: agent`，由 Worker 根据 `agent_ids` 遍历派发。

### 5. 挂接回调

在 V1 中：

```python
engine = WorkflowEngine(project_id)
engine.set_callbacks(
    on_stage_start=lambda name: ...,
    on_stage_complete=lambda name, output: ...,
    on_stage_error=lambda name, err: ...,
)
```

V2 不支持过程回调；Worker 自己监听 DDB 变化或订阅 SQS 状态消息。

### 6. 约束与陷阱

- **DDB 先行**：V1 的 `control_status` / `stage_result` 只以 DDB 为权威；Worker 内存状态仅作为缓存。pause/resume/stop 都是改 DDB。
- **规则注入**：若新工作流在某阶段不声明 `rule_keys`（空数组），V2 会注入除 `directory_rules` / `generation_rules` 外的**所有**工作流规则；如果阶段不需要这些规则，显式写成 `rule_keys: []` 仍会落入同一分支——这是设计阶段的语义。
- **上下文预算**：`get_stage_context` 把 `remaining_tokens / len(relevant_stages)` 作为**每个**前置阶段的预算；超过则走 `summarize_stage_output`，摘要只保留标题与代码块前 10 行。大内容阶段（如 `requirements_analysis`）会被后续阶段**部分看到**。
- **`StageOutput.content` > 400KB**：需要外层把内容写 S3 并填 `s3_content_ref`；`to_dict()` 会在有 `s3_content_ref` 时把 `content` 设为 `""`。
- **`legacy_name_mapping`**：在 V1→V2 迁移期间用于兼容老数据；写代码时应直接使用 V2 的阶段名（如 `tools_development`，不是 `tool_developer`）。

## 常见调试 / 故障排查

| 症状 | 关键日志 | 诊断 |
|------|----------|------|
| 阶段一直卡在 `pending` | — | 检查 `prerequisites`：`WorkflowEngine.validate_prerequisites` 抛 `PrerequisiteError` 时写 `logger.warning`；检查前置阶段是否 `completed`（DDB `stages` 表） |
| 阶段完成后立刻被"暂停" | `Workflow paused after stage: {name}` | `_refresh_control_status()` 在 DDB 读到 `control_status=paused`；检查 `projects.control_status` |
| Agent 输出解析失败 | `[V2] Stage {name}: raw_output type=…` + `Failed to extract detailed metrics` | V2 会最多重试 `MAX_RETRY_ON_PARSE_FAILURE=3` 次；第 3 次后 `_parse_and_validate_output` 抛异常 → 阶段 `failed` |
| 多 Agent 架构没识别 | `Failed to parse JSON architecture` / `Failed to parse markdown architecture` | `system_architecture` 输出需要是合法 JSON 或可被 `_parse_markdown_architecture` 三种正则之一匹配 |
| `Failed to create agent from template` | `Failed to create agent for stage {name}` | 提示词路径不存在或 YAML 解析失败；用 `AgentValidator.validate_prompt_path()` 单独复现 |
| 工具路径校验失败 | `[TOOL_NOT_FOUND] {path}: …` | 运行 `validate_workflow_prompts()` 会打印每个阶段缺失的工具 |
| Token 超预算 | `Stage {name} output summarized: X -> Y tokens` | 正常摘要；如果关键信息被摘掉，调大 `DEFAULT_MAX_CONTEXT_TOKENS` 或减少前置阶段数 |
| V2 fork 后某个 agent 级阶段不跑 | 无 | 检查 SQS 死信队列；检查 `_compute_fork_targets(stage_result)` 是否返回了该 Agent；检查 `agent_id` 是否已注册到 `agents` 表 |

## 代码片段索引

| 需要查的 | 位置 |
|---------|------|
| 阶段执行主循环 | `nexus_utils/workflow/engine.py::WorkflowEngine.execute_from_stage` |
| 单阶段 V2 执行 | `nexus_utils/workflow/engine_v2.py::WorkflowEngineV2.execute_stage` |
| 上下文拼接 | `nexus_utils/workflow/context.py::WorkflowContextManager.get_stage_context` |
| Agent 创建 | `nexus_utils/workflow/executor.py::StageExecutor.create_agent` |
| 多 Agent 架构解析 | `nexus_utils/workflow/multi_agent.py::MultiAgentIterator._parse_json_architecture` / `_parse_markdown_architecture` |
| 多 Agent 迭代 | `nexus_utils/workflow/multi_agent.py::MultiAgentStageExecutor.execute_iterative_stage` |
| Token 摘要 | `nexus_utils/workflow/context.py::summarize_stage_output` |
| fork 目标计算 | `nexus_utils/workflow/engine_v2.py::_compute_fork_targets` |
| V2 规则注入 | `nexus_utils/workflow/engine_v2.py::_build_agent_input` |
| 阶段提示词映射 | `api/v2/core/stage_config.py`（外部模块，被 `executor.py` 与 `context.py` 导入） |
| 生成后 Agent 自检 | `nexus_utils/workflow/agent_validator.py::AgentValidator.validate_all` |

## 延伸阅读

- [架构总览](./architecture-overview.md) — 项目整体架构与各子系统关系
- [Worker 子系统](./worker.md) — V2 SQS 驱动 + fork/join 的外层调度实现
- [API 层](./api-layer.md) — v2 REST API 如何触发 WorkflowEngine / 写入 `control_status`
- [贡献指南](./contributing.md) — 开发环境、测试、提交规范
