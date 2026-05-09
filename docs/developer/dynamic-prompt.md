---
title: 动态 Prompt 构建
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

# 动态 Prompt 构建

## 概述

Nexus-AI 的 Agent system prompt 不是单一的硬编码字符串，而是在运行时由两层代码流水线构建：

1. **基线层** — `nexus_utils/prompts_manager.py` 的 `PromptManager` 单例启动时扫描 `./prompts/**/*.yaml`，把每个 Agent 的 YAML（包含 `system_prompt`、`metadata.tools_dependencies`、`environments`、`versions` 等）解析为 `PromptAgent` / `PromptVersion` 数据类，按 `agent_name` 和相对路径双索引缓存在内存。系统 Agent、模板 Agent、已加载的 generated Agent 都走同一套结构；generated Agent 未命中时通过 DynamoDB + S3 按需加载。
2. **动态注入层** — `nexus_utils/runtime_injection/` 提供统一框架：`InjectionContext` 是贯穿整个构建流程的上下文对象，`BaseInjector` 是所有注入器的抽象基类，`InjectionRegistry` 把所有注入器按 `phase`（`yaml` / `creation` / `runtime`）和 `order` 排序后依次执行。每个注入器向 `ctx.prompt_parts`、`ctx.extra_tool_paths`、`ctx.extra_mcp_deps`、`ctx.runtime_tools`、`ctx.extra_hooks`、`ctx.metadata_patches` 写入增量结果，最后由 `apply_to_yaml` / `apply_to_agent_kwargs` 合并到 YAML 数据或 Agent 构造参数中。

此外，`nexus_utils/post_generation_processor.py` 在 Agent Build Workflow 生成完 Agent 代码后做静态检查和自动修复（去掉不存在的 `prompt_template_path` 参数、替换硬编码 model_id 为 `"default"` 等）。它**不是** runtime injection 链的一部分，而是生成后一次性扫描脚本。

本文档覆盖以下入口：

- 解析与查询基线 prompt：`PromptManager.get_agent(agent_name) → PromptAgent`
- 执行注入阶段：`injection_registry.run_phase(phase, ctx)`
- 把注入结果应用到 YAML：`injection_registry.apply_to_yaml(yaml_data, ctx)`
- 把注入结果应用到 Agent 构造参数：`injection_registry.apply_to_agent_kwargs(agent_kwargs, ctx)`
- 生成后处理：`post_generation_processor.process_generated_agent(path)`

## 文件组织（File Layout）

| 路径 | 责任 | 关键依赖 |
|------|------|----------|
| `nexus_utils/prompts_manager.py` | YAML Prompt 目录扫描、解析、内存缓存、S3 按需加载 | `pyyaml`, `nexus_utils.asset_cache`, `api.v2.database.dynamodb` |
| `nexus_utils/runtime_injection/__init__.py` | 导出 `InjectionContext` / `BaseInjector` / `InjectionRegistry` / `injection_registry` 单例 | — |
| `nexus_utils/runtime_injection/base.py` | `BaseInjector` 抽象基类（`name`/`phase`/`order`/`should_inject`/`inject`） | `abc` |
| `nexus_utils/runtime_injection/context.py` | `InjectionContext` dataclass（输入字段 + 输出字段 + 控制标志） | — |
| `nexus_utils/runtime_injection/registry.py` | `InjectionRegistry`，`run_phase` / `apply_to_yaml` / `apply_to_agent_kwargs`，内置注入器延迟注册 | 各 Injector 子模块 |
| `nexus_utils/runtime_injection/injectors/tool_injector.py` | 拆分普通工具路径与 MCP 工具（`mcp:` 前缀） | — |
| `nexus_utils/runtime_injection/injectors/mcp_injector.py` | 确保 `metadata.mcp_dependencies` 合并（实际解析由 ToolInjector 完成） | — |
| `nexus_utils/runtime_injection/injectors/cowork_injector.py` | 多 Agent 协作：`supervisor` 封装为 `agent_as_tool/`，`swarm` 写 `metadata.swarm_config` | — |
| `nexus_utils/runtime_injection/injectors/skill_injector.py` | Skill L1 摘要注入 + `activate_skill`/`skill_executor` 工具 + Skill 环境预装 | `nexus_utils.runtime_workspace.skill_env` |
| `nexus_utils/runtime_injection/injectors/connector_injector.py` | 数据连接器工具路径 + 连接器 prompt | `nexus_utils.data_connector.tool_generator` |
| `nexus_utils/runtime_injection/injectors/sop_injector.py` | Directive（SOP）业务指示 prompt 注入 | `nexus_utils.sop.prompt_builder` |
| `nexus_utils/runtime_injection/injectors/workspace_injector.py` | Runtime Workspace 规则 + `runtime_workspace_*` 工具 | `nexus_utils.workflow_rule_extract`, `nexus_utils.agent_factory` |
| `nexus_utils/runtime_injection/injectors/workspace_hook_injector.py` | `WorkspaceRedirectHook` 注入 | `nexus_utils.hooks.workspace_redirect_hook` |
| `nexus_utils/runtime_injection/injectors/key_injector.py` | `SecretKeyInjector` Hook（密钥从 Secrets Manager 动态注入，不入上下文） | `nexus_utils.hooks.secret_key_injector` |
| `nexus_utils/runtime_injection/injectors/remote_injector.py` | Nexus Bridge 远程终端工具 `remote_shell` / `remote_task` / `remote_task_status` / `sleep` + 服务器环境 prompt | `nexus_utils.bridge.remote_shell_tool`, `strands_tools.sleep` |
| `nexus_utils/runtime_injection/injectors/template_injector.py` | 用户上传的模板资产路径注入 | — |
| `nexus_utils/post_generation_processor.py` | 生成后的 Agent 代码静态检查与修复 | `nexus_utils.agent_validation`, `nexus_utils.safe_agent_factory` |
| `prompts/system_agents_prompts/**` | 系统 Agent YAML（build/update workflow, directive_builder, featured_agents, skill_build_workflow, tool_build_workflow 等） | 被 `PromptManager.load_prompts` 扫描 |

## 核心数据结构

所有下列 dataclass 定义在 `nexus_utils/prompts_manager.py`：

### `EnvironmentConfig`

| 字段 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `temperature` | `float` | 必填（解析时 `env_data.get('temperature', 0.7)`） | 采样温度 |
| `max_tokens` | `int` | `4096` | 最大输出 token 数 |
| `streaming` | `bool` | `True` | 是否启用流式响应 |
| `debug_mode` | `Optional[bool]` | `None` | 调试模式开关 |

### `ToolConfig`

| 字段 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `name` | `str` | `''` | 工具名 |
| `enabled` | `bool` | `True` | 是否启用 |
| `description` | `str` | `''` | 描述 |

### `PerformanceMetrics`

| 字段 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `accuracy` | `Optional[float]` | `None` | 准确率 |
| `response_time` | `Optional[float]` | `None` | 响应时间 |
| `user_satisfaction` | `Optional[float]` | `None` | 用户满意度 |

### `Compatibility`

| 字段 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `min_strands_version` | `Optional[str]` | `None` | 最低 strands-agents 版本 |
| `supported_models` | `List[str]` | `None` | 兼容模型列表 |

### `ConversationManagerConfig`

| 字段 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `enabled` | `Optional[bool]` | `None` | `None` 走全局配置，显式 `True`/`False` 覆盖 |
| `type` | `Optional[str]` | `None` | `sliding_window` / `summarizing` / `null` |
| `window_size` | `Optional[int]` | `None` | SlidingWindow 窗口大小 |
| `should_truncate_results` | `Optional[bool]` | `None` | 是否截断工具结果 |
| `summary_ratio` | `Optional[float]` | `None` | Summarizing 摘要比例 |
| `preserve_recent_messages` | `Optional[int]` | `None` | Summarizing 保留最近消息数 |
| `use_custom_agent` | `Optional[bool]` | `None` | 是否使用自定义摘要 Agent |
| `custom_agent_model_id` | `Optional[str]` | `None` | 自定义摘要 Agent 模型 ID |
| `custom_agent_prompt_path` | `Optional[str]` | `None` | 自定义摘要 Agent 提示词路径 |

### `Metadata`

| 字段 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `tags` | `List[str]` | `[]` | 标签 |
| `supported_models` | `Optional[List[str]]` | `None` | 支持的模型 |
| `lib_dependencies` | `Optional[List[str]]` | `None` | 库依赖 |
| `tools_dependencies` | `Optional[List[str]]` | `None` | 工具依赖路径列表 |
| `mcp_dependencies` | `Optional[List[str]]` | `None` | MCP 服务器依赖列表 |
| `model_provider` | `Optional[str]` | `None` | `bedrock`(默认) / `ollama` / `openai` / `anthropic` 等 |
| `model_config` | `Optional[Dict[str, Any]]` | `None` | 模型提供商特定配置 |
| `swarm_config` | `Optional[Dict[str, Any]]` | `None` | Swarm 多 Agent 协作配置 |
| `conversation_manager_config` | `Optional[ConversationManagerConfig]` | `None` | 对话管理器配置 |
| `retry_strategy` | `Optional[Dict[str, Any]]` | `None` | 模型调用重试策略（覆盖全局） |
| `performance_metrics` | `Optional[PerformanceMetrics]` | `None` | 性能指标 |
| `dependencies` | `Optional[List[str]]` | `None` | 通用依赖 |
| `compatibility` | `Optional[Compatibility]` | `None` | 兼容性 |
| `additional_request_fields` | `Optional[Dict[str, Any]]` | `None` | 传给模型 API 的附加请求字段 |

`_parse_metadata` 对 `mcp_dependencies` 做了三种容错：字段缺失 → `None`；字段为空 → `[]`；单字符串 → `[str]`；列表直接透传。

### `Example`

| 字段 | 类型 | 说明 |
|------|------|------|
| `user` | `str` | 用户输入 |
| `assistant` | `str` | 助手回复 |

### `PromptVersion`

| 字段 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `agent_name` | `str` | — | 从 YAML `agent.name` 读取 |
| `version` | `str` | — | YAML `versions[].version`，常为 `"latest"` |
| `status` | `str` | `"stable"` | 版本状态 |
| `created_date` | `str` | `''` | 创建日期 |
| `author` | `str` | `''` | 作者 |
| `description` | `str` | `''` | 版本描述 |
| `system_prompt` | `str` | `''` | 系统提示词（基线） |
| `user_prompt_template` | `Optional[str]` | `None` | 用户提示词模板 |
| `context_window` | `Optional[int]` | `None` | 上下文窗口 |
| `tools` | `Optional[List[ToolConfig]]` | `None` | 工具配置 |
| `constraints` | `Optional[List[str]]` | `None` | 约束 |
| `examples` | `Optional[List[Example]]` | `None` | 示例对话 |
| `metadata` | `Optional[Metadata]` | `None` | 元数据 |

### `PromptAgent`

| 字段 | 类型 | 说明 |
|------|------|------|
| `agent_name` | `str` | Agent 名 |
| `description` | `str` | 描述 |
| `category` | `str` | 分类（`system` / `development` / `agent` / `assistant` 等） |
| `environments` | `Dict[str, EnvironmentConfig]` | 环境名 → 环境配置 |
| `versions` | `Dict[str, PromptVersion]` | 版本名 → 版本对象 |

方法：

| 方法 | 签名 | 行为 |
|------|------|------|
| `get_version` | `get_version(version: str = "latest") -> Optional[PromptVersion]` | `latest` 优先返回 `versions["latest"]`；若不存在，取 `versions` 其他键中**版本号最大**的（`_version_key` 把 `"2.0.0"` 解析为 `(2,0,0)` 元组比较）；解析失败回退到 `(0,)` |
| `_version_key` | `_version_key(version_str: str) -> tuple` | 版本号字符串 → 可比较元组；异常时返回 `(0,)` |
| `get_all_versions` | `get_all_versions() -> Dict[str, PromptVersion]` | 返回 versions 的浅拷贝 |
| `get_environment_config` | `get_environment_config(environment: str = "production") -> Optional[EnvironmentConfig]` | 按环境名查 |

### `InjectionContext` (`nexus_utils/runtime_injection/context.py`)

贯穿整个注入流程的统一数据容器，一次构建、被所有 Injector 读写。

#### 基础信息字段

| 字段 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `agent_name` | `str` | `""` | Agent 名 / 相对路径 |
| `session_id` | `str` | `""` | 会话 ID（Bridge 检查、workspace 解析需要） |
| `agent_id` | `str` | `""` | Agent UUID（Key Hook 使用） |
| `user_id` | `str` | `""` | 用户 ID |
| `workspace_path` | `str` | `""` | Runtime workspace 绝对路径 |

#### 输入字段（调用方填充）

| 字段 | 类型 | 说明 |
|------|------|------|
| `skills` | `List[Dict[str, Any]]` | Skill 元数据 dict 列表（含 `skill_id` / `skill_name` / `l1_summary` / `has_scripts` / `has_agents` / `tools`） |
| `tools` | `List[str]` | 附加工具路径（含 `mcp:xxx` 形式） |
| `agents` | `List[str]` | 子 Agent 名（Co-Work 用） |
| `connectors` | `List[Any]` | 数据连接器实例 |
| `keys` | `List[str]` | 本次会话可用的密钥 ID |
| `directive_ids` | `List[str]` | Directive / SOP ID 列表 |
| `templates` | `List[Dict[str, Any]]` | 模板资产（`TemplateMountSpec` dict） |
| `cowork_mode` | `str` | `"supervisor"`（默认） / `"swarm"` |
| `swarm_entry_point` | `str` | Swarm 入口 Agent（为空则用 `agents[0]`） |

#### 输出字段（由 Injector 写入）

| 字段 | 类型 | 写入方 | 最终流向 |
|------|------|--------|----------|
| `prompt_parts` | `List[str]` | 多个 Injector | `apply_to_yaml` 追加到 `system_prompt`；`apply_to_agent_kwargs` 追加到 `agent_kwargs["system_prompt"]` |
| `extra_tool_paths` | `List[str]` | ToolInjector / SkillInjector / ConnectorInjector / CoWorkInjector | 合并到 `metadata.tools_dependencies`（去重） |
| `extra_mcp_deps` | `List[str]` | ToolInjector | 合并到 `metadata.mcp_dependencies`（去重） |
| `extra_hooks` | `List[Any]` | KeyInjector / WorkspaceHookInjector | `agent_kwargs["hooks"]` |
| `runtime_tools` | `List[Any]` | WorkspaceInjector / RemoteTerminalInjector | `agent_kwargs["tools"]` |
| `metadata_patches` | `Dict[str, Any]` | CoWorkInjector（`swarm_config`） | 直接覆盖 `metadata[key]` |

#### 控制标志

| 字段 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `is_workflow_agent` | `bool` | `False` | 工作流 Agent 时跳过 workspace / template / key 等注入 |
| `is_event_scheduler` | `bool` | `False` | 事件调度器标志 |

#### 辅助方法

| 方法 | 行为 |
|------|------|
| `add_tool_path(path)` | 非空且未存在时 append 到 `extra_tool_paths` |
| `add_mcp_dep(server_name)` | 非空且未存在时 append 到 `extra_mcp_deps` |
| `add_prompt(prompt)` | 非空时 append 到 `prompt_parts` |

### `BaseInjector` (`nexus_utils/runtime_injection/base.py`)

```python
class BaseInjector(ABC):
    @property
    @abstractmethod
    def name(self) -> str: ...

    @property
    def phase(self) -> str:
        return "yaml"          # 默认

    @property
    def order(self) -> int:
        return 100             # 默认

    @abstractmethod
    def should_inject(self, ctx: InjectionContext) -> bool: ...

    @abstractmethod
    def inject(self, ctx: InjectionContext) -> None: ...
```

| 成员 | 说明 |
|------|------|
| `name` | 日志标签 |
| `phase` | `yaml`（YAML 模板生成，修改 `tools_dependencies` / `system_prompt`） / `creation`（Agent 构造时，修改 `agent_kwargs`） / `runtime`（Agent 运行时） |
| `order` | 同阶段内执行顺序，**数字越小越先** |
| `should_inject` | 返回 `False` 时跳过 |
| `inject` | 把结果写入 `ctx` 的输出字段；**不直接**修改 YAML 或 Agent 实例 |

### `InjectionRegistry` (`nexus_utils/runtime_injection/registry.py`)

| 方法 | 签名 | 行为 |
|------|------|------|
| `register` | `register(injector: BaseInjector) -> None` | 追加到内部 `_injectors` 列表 |
| `run_phase` | `run_phase(phase: str, ctx: InjectionContext) -> None` | 取该 phase 的注入器，按 `order` 升序排序，逐个 `should_inject` → `inject`；**单个注入器抛异常不影响其他**（被 `warning` 日志吞掉） |
| `apply_to_yaml` | `apply_to_yaml(yaml_data: dict, ctx: InjectionContext) -> None` | 合并 `extra_tool_paths` / `extra_mcp_deps` / `metadata_patches` 到 `yaml_data["agent"]["versions"][0]["metadata"]`；`prompt_parts` 拼接追加到 `latest_version["system_prompt"]` |
| `apply_to_agent_kwargs` | `apply_to_agent_kwargs(agent_kwargs: dict, ctx: InjectionContext) -> None` | `prompt_parts` 追加到 `agent_kwargs["system_prompt"]`；`runtime_tools` 追加到 `agent_kwargs["tools"]`；`extra_hooks` 追加到 `agent_kwargs["hooks"]` |
| `_ensure_initialized` | — | 首次调用 `run_phase` 时延迟触发 `_register_builtin_injectors(self)` |

模块末尾暴露全局单例：

```python
injection_registry = InjectionRegistry()
```

## 关键函数 / 方法

### `PromptManager` (`nexus_utils/prompts_manager.py`)

| 方法 | 签名 | 职责 |
|------|------|------|
| `__new__` | `__new__(cls, prompt_paths: List[str] = None)` | 单例控制：`cls._instance` 为 None 时创建 |
| `__init__` | `__init__(prompt_paths: List[str] = None)` | 首次初始化（`_initialized` 守护），默认路径 `[default_prompt_path, template_prompt_path, generated_prompt_path]` |
| `load_prompts` | `load_prompts() -> None` | `os.walk('./prompts')` 递归扫描所有 `.yaml`，按 `agent_name` 和相对路径双索引写入 `self.agents` |
| `_parse_environment_config` | `_parse_environment_config(env_data: Dict[str, Any]) -> EnvironmentConfig` | 解析 `environments[env_name]` |
| `_parse_tool_config` | `_parse_tool_config(tool_data: Dict[str, Any]) -> ToolConfig` | — |
| `_parse_performance_metrics` | `_parse_performance_metrics(metrics_data) -> PerformanceMetrics` | — |
| `_parse_compatibility` | `_parse_compatibility(compat_data) -> Compatibility` | — |
| `_parse_conversation_manager_config` | `_parse_conversation_manager_config(cm_data: Optional[Dict]) -> Optional[ConversationManagerConfig]` | `cm_data is None` 时返回 `None` |
| `_parse_metadata` | `_parse_metadata(metadata_data) -> Metadata` | 支持 `mcp_dependencies` 的三种容错 |
| `_parse_examples` | `_parse_examples(examples_data) -> List[Example]` | — |
| `get_agent` | `get_agent(agent_name: str) -> Optional[PromptAgent]` | 先查内存缓存；未命中时调用 `_try_load_from_s3`（V2 S3-First 能力） |
| `_try_load_from_s3` | `_try_load_from_s3(identifier: str) -> Optional[PromptAgent]` | 通过 `nexus_utils.asset_cache.get_asset_cache_manager()` 确保资产本地缓存，命中后 `load_single_prompt` 并回查 |
| `_resolve_agent_record_from_ddb` | `_resolve_agent_record_from_ddb(identifier) -> Optional[Dict]` | identifier 识别 3 种格式：UUID（长度 36 且 4 个 `-`）→ `db_client.get_agent`；`agent_name_en` → `db_client.query_agent_by_name_en`；`relative_path` → 取倒数第二段作为 `dir_name` → `db_client.query_agent_by_dir_name` |
| `reload` | `reload() -> None` | 清空缓存并重新 `load_prompts` |
| `load_single_prompt` | `load_single_prompt(prompt_file_path: str) -> bool` | 部署新 Agent 后按单文件加载；自动补 `./prompts/` 前缀和 `.yaml` 后缀 |

### 默认 YAML 目录常量

```python
default_prompt_path = './prompts/system_agents_prompts/*.yaml'
template_prompt_path = './prompts/template_prompts/*.yaml'
generated_prompt_path = './prompts/generated_agents_prompts/*.yaml'
```

注意：虽然 `prompt_paths` 字段保留，但 `load_prompts` 实际用的是 `os.walk('./prompts')` 全量扫描，三个常量已不起过滤作用。

### `post_generation_processor.py` 对外函数

| 函数 | 签名 | 职责 |
|------|------|------|
| `process_generated_agent` | `process_generated_agent(agent_project_path: str, auto_fix: bool = True, create_backup: bool = True) -> Dict[str, Any]` | 顶层入口：查找 Agent 文件 → 备份 → 逐个 `process_agent_file` → `validate_prompt_files` |
| `find_agent_files` | `find_agent_files(project_path: str) -> List[str]` | 递归查找 `*.py` 且文件名含 `agent`，且内容含 `create_agent_from_prompt_template` 或 `Agent` 的文件 |
| `process_agent_file` | `process_agent_file(agent_file_path: str, auto_fix: bool = True) -> Dict[str, Any]` | 三类检查：`prompt_template_path=` 旧参数、Agent 名称格式、硬编码 model_id |
| `validate_prompt_files` | `validate_prompt_files(project_path: str) -> Dict[str, Any]` | 在 `prompts/generated_agents_prompts/&lt;project_name&gt;/` 下找 YAML 并调用 `validate_agent_dependencies` |
| `find_line_number` | `find_line_number(content: str, search_text: str) -> int` | 搜索文本首次出现行号，未找到返回 `-1` |
| `fix_prompt_template_path_parameter` | — | 正则 `r',?\s*prompt_template_path\s*=\s*["\'][^"\']*["\']'` 整体删除 |
| `check_agent_name_format` | — | 正则 `r'agent_name\s*=\s*["\']([^"\']*)["\']'` 捕获，要求前缀属于 `system_agents_prompts/` / `template_prompts/` / `generated_agents_prompts/` 三者之一 |
| `fix_agent_name_format` | — | 占位实现，当前只原样返回（未实现自动修复） |
| `check_model_configuration` | — | 找 `model_id` 中以 `anthropic.` / `us.anthropic.` 开头的硬编码值 |
| `fix_model_configuration` | — | 把 `model_id = "...anthropic..."` 替换为 `model_id = "default"` |

CLI：

```bash
python -m nexus_utils.post_generation_processor -p <agent_project_path> [--no-auto-fix] [--no-backup]
```

## 内置注入器清单

`registry._register_builtin_injectors` 会在 `_ensure_initialized` 时按以下顺序调用 `register`（注册顺序**不等于**执行顺序——执行顺序由 `phase` + `order` 决定）：

| 名称（`name`） | 类 | 文件 | phase | order | `should_inject` 条件 | 主要输出 |
|----------------|----|------|-------|-------|---------------------|----------|
| `tool` | `ToolInjector` | `injectors/tool_injector.py` | `yaml` | 10 | `bool(ctx.tools)` | `extra_tool_paths` + `extra_mcp_deps` |
| `mcp` | `MCPInjector` | `injectors/mcp_injector.py` | `yaml` | 15 | `bool(ctx.extra_mcp_deps)` | 仅日志（合并由 `apply_to_yaml` 完成） |
| `cowork` | `CoWorkInjector` | `injectors/cowork_injector.py` | `yaml` | 20 | `bool(ctx.agents)` | `supervisor`: `extra_tool_paths.append("agent_as_tool/&lt;name&gt;")`；`swarm`: `metadata_patches["swarm_config"]` |
| `skill` | `SkillInjector` | `injectors/skill_injector.py` | `yaml` | 30 | `bool(ctx.skills)` | `prompt_parts`（L1 摘要）+ `extra_tool_paths`（`system_tools/skill_activator`、`system_tools/skill_executor`、可能 `strands_tools/shell`、Skill 自带工具）+ skill env prompt |
| `connector` | `ConnectorInjector` | `injectors/connector_injector.py` | `yaml` | 40 | `bool(ctx.connectors)` | `extra_tool_paths`（`get_connector_tool_paths`）+ `prompt_parts`（`generate_connector_prompt`） |
| `directive` | `SOPInjector` | `injectors/sop_injector.py` | `yaml` | 50 | `bool(ctx.directive_ids)` | `prompt_parts`（`build_directive_prompt`） |
| `workspace` | `WorkspaceInjector` | `injectors/workspace_injector.py` | `creation` | 10 | 非工作流 Agent 且 `config.runtime_workspace.auto_sync` 为 True（默认） | `prompt_parts`（runtime rules + workspace 指引）+ `runtime_tools`（3 个 `runtime_workspace_*` 工具） |
| `remote_terminal` | `RemoteTerminalInjector` | `injectors/remote_injector.py` | `creation` | 10 | `bool(ctx.session_id)` 且 Bridge `/status/&lt;session_id&gt;` 返回 `connected=True` | `runtime_tools`（`remote_shell` / `remote_task` / `remote_task_status` / `sleep`）+ `prompt_parts`（服务器环境与命令规则） |
| `workspace_hook` | `WorkspaceHookInjector` | `injectors/workspace_hook_injector.py` | `creation` | 20 | `bool(ctx.workspace_path)` 且非工作流 | `extra_hooks.append(create_workspace_redirect_hook(ws))` |
| `key` | `KeyInjector` | `injectors/key_injector.py` | `creation` | 25 | `bool(ctx.agent_id)` 且非工作流 | 构造 `SecretKeyInjector`；仅当 `hook.tool_key_map` 非空时 append 到 `extra_hooks` |
| `template` | `TemplateInjector` | `injectors/template_injector.py` | `creation` | 30 | `bool(ctx.templates)` 且非工作流 | `prompt_parts`（列出所有模板文件路径 + `.structured.json` 辅助路径） |

> `workspace` 和 `remote_terminal` 都 `phase=creation, order=10`；相同 `order` 时由 `sorted` 的**稳定排序**决定——执行顺序遵循 `_register_builtin_injectors` 中的注册顺序：`workspace` 先注册，故 `workspace` 先执行。

## 调用流程（Data Flow）

### 构建 Agent YAML（`phase=yaml`）

```
调用方 (DynamicConfigService._generate_dynamic_yaml)
  │
  ├─ ctx = InjectionContext(agent_name, skills=[...], tools=[...], connectors=[...],
  │                          directive_ids=[...], agents=[...], cowork_mode=...)
  │
  ├─ injection_registry.run_phase("yaml", ctx)
  │     │
  │     ├─ ToolInjector      (order=10)  → ctx.extra_tool_paths / extra_mcp_deps
  │     ├─ MCPInjector       (order=15)  → (只 log)
  │     ├─ CoWorkInjector    (order=20)  → extra_tool_paths 或 metadata_patches
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

### 构建 Agent 实例（`phase=creation`）

```
调用方 (agent_factory.create_agent_from_prompt_template)
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

当前版本中所有内置注入器的 `phase` 要么是 `yaml` 要么是 `creation`，**没有**内置的 `runtime` 注入器。`run_phase("runtime", ctx)` 依然合法——保留给第三方注入器或 `agent_runtime_service` 的在线扩展使用。

## 扩展点（Extending）

### 新增一个注入器

1. **选 phase**：
   - 要改 YAML 的 `metadata.tools_dependencies` / `metadata.mcp_dependencies` / `system_prompt` → `yaml`
   - 要往 Agent 构造参数（`tools` 实例、`hooks` 实例、`system_prompt`）里加东西 → `creation`
   - 要在 Agent 已实例化、正在运行时再加 → `runtime`
2. **选 order**：查上表，避开冲突。若依赖前一个注入器的输出（比如等 `ToolInjector` 先把 `mcp:` 前缀分离出来），`order` 要更大。
3. **继承 `BaseInjector`**，实现四项：

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

4. **注册**：修改 `nexus_utils/runtime_injection/registry.py::_register_builtin_injectors`，追加：

   ```python
   try:
       from nexus_utils.runtime_injection.injectors.my_injector import MyInjector
       registry.register(MyInjector())
   except Exception as e:
       logger.warning(f"[injection] Failed to register MyInjector: {e}")
   ```

   或在运行时调用 `injection_registry.register(MyInjector())`。注意：`_ensure_initialized` 只跑一次，运行期 register 需要在**首次 `run_phase` 之后**；如需提前加载，调用一次 `injection_registry._ensure_initialized()`。

### 新增 Context 输入字段

需要新输入（例如 `my_input: List[str]`）时，修改 `nexus_utils/runtime_injection/context.py` 的 `InjectionContext` dataclass 字段，保持向后兼容（给默认值）。调用方在构造 `ctx` 时填充即可。

### 约束与陷阱

- **不要**在 `inject()` 里直接改 `yaml_data` 或 `agent_kwargs`——只写 `ctx` 的输出字段。`apply_to_yaml` / `apply_to_agent_kwargs` 负责合并，否则 `run_phase` 被其他代码直接调用时结果会丢。
- **异常隔离**：`run_phase` 用 `try/except` 包住每个注入器，失败只写 `warning` 日志。想让错误中断流程，**不要**在 `inject()` 里静默 swallow——抛出即可，但要认识到外层仍会 warn-and-continue。
- **MCP 特殊路径**：`ctx.tools` 里的 `mcp:` 前缀条目由 `ToolInjector` 剥离出来放入 `extra_mcp_deps`，而不是 `extra_tool_paths`。
- **workflow Agent 白名单**：`is_workflow_agent=True` 会跳过 `workspace` / `workspace_hook` / `key` / `template` 注入。工作流（Build Workflow、Tool Workflow 等）不需要用户工作空间与密钥。
- **单例 PromptManager**：`PromptManager()` 是 `__new__` 单例，首次 `__init__` 后 `_initialized=True` 会忽略后续 `prompt_paths` 参数。**想改配置必须重启或 `reload()`。**
- **`get_version("latest")` 的降级**：若 YAML 里没有 `"latest"` 键，会按版本号元组取最大。版本号非数字（如 `"beta"`）时 `_version_key` 回退到 `(0,)`，会被任何数字版本覆盖。
- **S3 按需加载**：`_try_load_from_s3` 会 `load_single_prompt` 后把新 Agent 注册到 `self.agents`。并发场景下未加锁——高并发首次加载同一 Agent 时可能重复解析（末次写入生效，功能无误）。
- **生成后处理器的命名约束**：`check_agent_name_format` 要求 `agent_name` 前缀必须是 `system_agents_prompts/` / `template_prompts/` / `generated_agents_prompts/`；与 `prompts_manager` 扫描的目录**硬编码一致**。新增目录分类时两处都要改。

## 常见调试 / 故障排查

### 日志关键词

所有 Injector 日志以 `[injection] &lt;name&gt;:` 开头。常见行：

| 日志 | 含义 |
|------|------|
| `[injection] Registered injector: &lt;name&gt; (phase=..., order=...)` | 注册成功（DEBUG） |
| `[injection] Registered N injector(s)` | `_register_builtin_injectors` 完成 |
| `[injection] tool: added X tools, Y MCP deps` | ToolInjector 成功 |
| `[injection] skill: injected L1 metadata for N skill(s)` | SkillInjector 成功 |
| `[injection] skill: env preparation failed (non-fatal): &lt;err&gt;` | Skill env 装配失败但不中断 |
| `[injection] connector: injected N tools and prompt for M connector(s)` | ConnectorInjector 成功 |
| `[injection] cowork: supervisor mode, N agent(s) as tools` / `swarm mode, N member(s)` | CoWorkInjector 走了哪条分支 |
| `[injection] directive: injected prompt for N directive(s)` | SOPInjector 成功 |
| `[injection] workspace: rules injected for '&lt;agent_name&gt;'` | WorkspaceInjector 成功 |
| `[injection] workspace_hook: injected for &lt;path&gt;` | Hook 成功 |
| `[injection] key: registered SecretKeyInjector for agent &lt;aid&gt;... (N key-required tools)` | KeyInjector 注册了 Hook |
| `[injection] key: no key-required tools for agent &lt;aid&gt;..., skipping` | Agent 没有任何需要密钥的工具（正常） |
| `[injection] remote_terminal: injected for session &lt;sid&gt;, servers=[...]` | Bridge 已接入 |
| `TemplateInjector injected N templates` | TemplateInjector 成功 |
| `[injection] &lt;name&gt; failed: &lt;err&gt;` | 单个注入器异常（不中断其他） |

### 典型故障

| 现象 | 可能原因 | 排查起点 |
|------|----------|----------|
| `get_agent(name)` 返回 `None` | 1. YAML 不在 `./prompts/` 下  2. YAML 没有顶层 `agent:` 键  3. S3 路径与 DDB 记录不一致 | 看 `load_prompts` 启动日志「加载提示词文件 X 时出错」；用 `db_client.query_agent_by_name_en` / `query_agent_by_dir_name` 直接查 DDB |
| Skill 工具没被注入 | `ctx.skills` 为空；或 `skill.tools` 字段缺失 | 打印 `ctx.skills`；确认 L1 元数据有 `tools` 列表 |
| `remote_shell` 工具缺失 | Bridge 未连接：`GET &lt;bridge_url&gt;/status/&lt;session_id&gt;` 返回 `connected=false` | 查 `bridge_logger` 的 `tool_check` 事件；检查 `_get_bridge_url()` |
| 密钥工具报权限错 | `KeyInjector` 认为该 Agent 没有需要密钥的工具（`hook.tool_key_map` 空）故未注册 Hook | 检查 `SecretKeyInjector.tool_key_map` 构造逻辑与 Agent 的 `tools_dependencies` |
| `swarm_config` 没写进 YAML | `cowork_mode != "swarm"` 或 `ctx.agents` 为空 | 打印 `ctx.cowork_mode` 和 `ctx.agents` |
| 生成的 Agent 代码里 `model_id="us.anthropic..."` 没被替换 | `auto_fix=False`、或 `model_id` 使用非字符串字面量（如变量） | `post_generation_processor.check_model_configuration` 只匹配字面量形式；看返回的 `issues` / `fixes_applied` |
| MCP 工具没生效 | `ctx.tools` 里的前缀不是严格 `mcp:` 开头；或 `metadata.mcp_dependencies` 没被后续加载器读 | 看 `ToolInjector.inject` 对 `mcp:` 的字符串切片逻辑：`tool_path[4:]`，再按 `/` 取第一段 |
| 两个 Injector 顺序反了 | 都用默认 `order=100` | 显式重写 `order` property |

## 延伸阅读

- 注册点与调用点：`nexus_utils/runtime_injection/__init__.py`（导出）、`nexus_utils/runtime_injection/registry.py`（`_register_builtin_injectors`）
- Prompt 基线加载：`nexus_utils/prompts_manager.py::PromptManager.load_prompts`
- 生成后处理入口：`nexus_utils/post_generation_processor.py::process_generated_agent`
- 系统 Agent YAML 模板：`prompts/system_agents_prompts/**/*.yaml`（build / update workflow、directive_builder、featured_agents、skill_build_workflow、tool_build_workflow 等 50+ 份样板）
- 相关依赖模块：`nexus_utils.data_connector.tool_generator`、`nexus_utils.sop.prompt_builder`、`nexus_utils.hooks.secret_key_injector`、`nexus_utils.hooks.workspace_redirect_hook`、`nexus_utils.bridge.remote_shell_tool`、`nexus_utils.runtime_workspace.skill_env`、`nexus_utils.asset_cache`、`api.v2.database.dynamodb`
