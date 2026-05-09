---
title: 添加 Agent
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

# 添加 Agent

## 概述

Nexus-AI 的 Agent 是围绕 **Strands SDK** `Agent` 类构建的。每个 Agent 由三件事定义：

1. **Prompt 模板**（`prompts/template_prompts/&lt;name&gt;` 或 `prompts/generated_agents_prompts/&lt;ns&gt;/&lt;name&gt;`）— 承载 system prompt、模型类别、温度/max_tokens 等环境配置，以及 `tools_dependencies` 声明。
2. **运行脚本**（`agents/template_agents/single_agent/*.py` 或 `agents/generated_agents/&lt;ns&gt;/*.py`）— 调用 `create_agent_from_prompt_template(...)` 实例化 Agent，声明 `BedrockAgentCoreApp` entrypoint，并提供 CLI/交互入口。
3. **目录注册**（`agents/template_agents/agent_templates_config.yaml`）— 把模板加入可发现列表，供平台工具链查询。

所有 Agent 的创建都经过同一个工厂：`nexus_utils.agent_factory.create_agent_from_prompt_template`。它读取 prompt 模板、解析 `tools_dependencies`、构造 Bedrock（或其他 provider）模型、注入工具并返回 `strands.Agent` 实例。带依赖校验与自动修复的安全封装在 `nexus_utils.safe_agent_factory`。多 Agent 协作使用 Strands 的 `Swarm`（参见 `agents/template_agents/multi_agent/tech_doc_swarm.py`）或在一个主类中显式编排多个 Agent（参见 `agents/template_agents/multi_agent/stock_analysis_agent.py`）。

本文覆盖：**新加一个 Agent 要改哪些文件**、**工厂与校验函数的完整签名**、**模型提供商注册表**、**工具路径解析规则**、以及**多 Agent 编排两种模式的对比**。

## 文件组织（File Layout）

| 路径 | 责任 | 依赖 |
|------|------|------|
| `agents/template_agents/agent_templates_config.yaml` | 模板注册清单；为每个模板声明 `name`/`description`/`tools_dependencies`/`path`/`prompt_template`/`tags` | — |
| `agents/template_agents/single_agent/*.py` | 单 Agent 模板脚本 | `nexus_utils.agent_factory`, `bedrock_agentcore.runtime` |
| `agents/template_agents/multi_agent/*.py` | 多 Agent 编排脚本 | 同上 + `strands.multiagent.Swarm`（如适用） |
| `agents/generated_agents/&lt;ns&gt;/*.py` | 自动生成的 Agent（带命名空间） | 同单 Agent 模板 |
| `nexus_utils/agent_factory.py` | 核心工厂：模型构造、工具解析、Agent 组装 | `strands`, `boto3`, `nexus_utils.config_loader`, `nexus_utils.prompts_manager` |
| `nexus_utils/safe_agent_factory.py` | 带依赖校验与自动修复的 Agent 创建封装 | `nexus_utils.agent_factory`, `nexus_utils.agent_validation` |
| `nexus_utils/agent_validation.py` | 工具依赖验证、修复建议、存根生成 | `nexus_utils.prompts_manager`, `nexus_utils.agent_factory` |
| `config/model_catalog.yaml` | Bedrock 可用模型目录（前端刷新按钮读取） | — |
| `prompts/template_prompts/&lt;name&gt;/` | 单 Agent 的 prompt 模板与环境配置 | 由 `prompts_manager` 加载 |
| `prompts/generated_agents_prompts/&lt;ns&gt;/&lt;name&gt;/` | 多 Agent / 生成 Agent 的 prompt 模板 | 同上 |

## 现有模板清单（来自 `agent_templates_config.yaml`）

| 模板 key | 类型 | 脚本路径 | Prompt 路径 |
|---------|------|---------|-------------|
| `document_processor_agent` | single_agent | `agents/template_agents/single_agent/document_processor_agent.py` | `prompts/template_prompts/document_processor_agent` |
| `data_analyzer_agent` | single_agent | `agents/template_agents/single_agent/data_analyzer_agent.py` | `prompts/template_prompts/data_analyzer_agent` |
| `api_integration_agent` | single_agent | `agents/template_agents/single_agent/api_integration_agent.py` | `prompts/template_prompts/api_integration_agent` |
| `content_generator_agent` | single_agent | `agents/template_agents/single_agent/content_generator_agent.py` | `prompts/template_prompts/content_generator_agent` |
| `deep_research_agent` | single_agent | `agents/template_agents/single_agent/deep_research_agent.py` | `prompts/template_prompts/deep_research_agent` |
| `html2pptx_agent` | single_agent | `agents/template_agents/single_agent/html2pptx_agent.py` | `prompts/generated_agents_prompts/html2pptx/html2pptx_agent` |
| `aws_pricing_agent` | single_agent | `agents/generated_agents/aws_pricing_agent/aws_pricing_agent.py` | `prompts/generated_agents_prompts/aws_pricing_agent/aws_pricing_agent` |
| `medical_document_translation_agent` | single_agent | `agents/generated_agents/medical_document_translation_agent/medical_translator.py` | `prompts/generated_agents_prompts/medical_document_translation_agent/medical_translator` |
| `tech_doc_multi_agent_system` | multi_agent (Swarm) | `agents/generated_agents/tech_doc_multi_agent_system/tech_doc_swarm.py` | 3 个子 prompt（`document_writer_agent` / `document_reviewer_agent` / `content_processor_agent`） |
| `stock_analysis_agent` | multi_agent (显式编排) | `agents/generated_agents/stock_analysis_agent/...` | 7 个子 prompt（coordinator/data_collector/valuation/prediction/risk_assessment/benchmark/report_generator） |

内置单 Agent 模板脚本还包括 `agents/template_agents/single_agent/default_agent.py`（`template_prompts/default`），作为最简样板。

## 核心工厂函数

### `create_agent_from_prompt_template` (nexus_utils/agent_factory.py)

**所有 Agent 的统一入口。** 根据 prompt 模板生成 `strands.Agent`。典型调用签名（依赖 `safe_agent_factory` 的 forward 调用得到的参数集合）：

```python
from nexus_utils.agent_factory import create_agent_from_prompt_template

agent = create_agent_from_prompt_template(
    agent_name="template_prompts/api_integration_agent",
    env="production",        # development / production / testing
    version="latest",        # prompt 模板版本号
    model_id="default",      # 对应 bedrock 配置里的 key
    enable_logging=True,
    state=None,              # 可选：注入 Agent 状态
    session_manager=None,    # 可选：会话管理器
)
```

| 参数 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `agent_name` | `str` | — | prompt 模板相对路径或模板名 |
| `env` | `str` | `"production"` | 环境 key（映射到 prompt 模板的 `get_environment_config`） |
| `version` | `str` | `"latest"` | prompt 模板版本号 |
| `model_id` | `str` | `"default"` | 模型 key；`get_bedrock_model` 会从 `bedrock` 配置中解析为完整 model ID |
| `enable_logging` | `bool` | `False` | 是否开启 Agent 调用日志 |
| `state` | `Optional[Dict[str, Any]]` | `None` | 注入到 `Agent.state` |
| `session_manager` | `Optional[Any]` | `None` | 会话管理器（用于历史持久化） |
| `**agent_params` | — | — | 透传给 `strands.Agent` 构造器的额外参数 |

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

- `model_id` 是 `config.bedrock` 段里的 key；会解析成 Bedrock 完整 ID（如 `us.anthropic.claude-sonnet-4-20250514-v1:0`）。
- 从 prompt 模板的 `get_environment_config(env)` 读取 `max_tokens`、`temperature`、`streaming`。
- `boto_client_config` 由 `config.bedrock.connect_config` 构造，含重试/超时。
- `_fresh_boto_session()` 每次创建新 boto3 session，以支持 sandbox VM 的凭证轮换。
- Prompt caching 通过 `_get_cache_kwargs` 注入（见下）。

### `_get_cache_kwargs` (nexus_utils/agent_factory.py:2807)

读 `config.bedrock.prompt_caching`：若启用且模型 ID 包含 `claude` / `anthropic` / `nova`，注入 `cache_prompt="default"` 与 `cache_tools="default"`。其他模型族（Titan/Llama/Mistral/Cohere/AI21）直接返回空 dict，避免 Strands SDK 报错。计费说明（代码注释）：首次写入 1.25× 标准价，5 分钟内命中 0.1×（90% 折扣）。

### `create_model_for_provider` (nexus_utils/agent_factory.py:2863)

通用模型提供商工厂，根据 provider 名称从注册表加载对应模型类。

```python
def create_model_for_provider(provider: str, model_id: str,
                              model_config: Optional[Dict[str, Any]] = None,
                              max_tokens: int = None,
                              temperature: float = None) -> Any:
```

抛出 `ValueError`（未知 provider）或 `ImportError`（缺少依赖包）。

### `MODEL_PROVIDER_REGISTRY` (nexus_utils/agent_factory.py:2852)

| provider | 模块路径 | 类名 | pip 安装包 |
|----------|---------|------|-----------|
| `ollama` | `strands.models.ollama` | `OllamaModel` | `strands-agents[ollama]` |
| `openai` | `strands.models.openai` | `OpenAIModel` | `strands-agents[openai]` |
| `anthropic` | `strands.models.anthropic` | `AnthropicModel` | `strands-agents[anthropic]` |
| `litellm` | `strands.models.litellm` | `LiteLLMModel` | `strands-agents[litellm]` |
| `llamaapi` | `strands.models.llamaapi` | `LlamaAPIModel` | `strands-agents[llamaapi]` |
| `mistral` | `strands.models.mistral` | `MistralModel` | `strands-agents[mistral]` |
| `gemini` | `strands.models.gemini` | `GeminiModel` | `strands-agents[gemini]` |

`bedrock` 默认走 `get_bedrock_model`，不经此注册表。

## 工具解析

### `get_tool_by_path` (nexus_utils/agent_factory.py:3083)

根据前缀分派：

| 前缀 | 处理方式 |
|------|---------|
| `strands_tools/&lt;name&gt;` | `importlib.import_module('strands_tools.&lt;name&gt;')`；对 `browser` 走 `AgentCoreBrowser` |
| `system_tools/&lt;path&gt;/&lt;fn&gt;` | 导入 `tools.system_tools.&lt;path&gt;` 并 `getattr(fn)`；若 2 段路径则扫描 `@tool` 装饰的函数 |
| `generated_tools/&lt;ns&gt;/&lt;script&gt;/&lt;fn&gt;` | 导入 `tools.generated_tools.&lt;ns&gt;.&lt;script&gt;`；失败时调用 `_sync_tool_from_s3` 从 S3 下载后重试 |
| `template_tools/&lt;cat&gt;/&lt;script&gt;/&lt;fn&gt;` | 导入 `tools.template_tools.&lt;cat&gt;.&lt;script&gt;` 并 `getattr(fn)` |

### `_sync_tool_from_s3` (nexus_utils/agent_factory.py:3019)

`generated_tools` 本地缺失时从 S3 拉取：

- S3 key：`tools/{dir_name}/{script_name}.py`
- 本地路径：`tools/generated_tools/{dir_name}/{script_name}.py`
- Bucket 从 `config.nexus_ai.artifacts_s3_bucket` 读取（默认 `nexus-ai-artifacts-2026`）
- 同步后补齐 `__init__.py`

### `get_tool_by_name` (nexus_utils/agent_factory.py:3227)

按名称查找工具。顺序：
1. `get_builtin_tools_mapping()`（Strands 内置，如 `file_read`、`current_time`）
2. `get_system_tools_mapping()`（系统工具）
3. `tools.system_tools.agent_build_workflow.tool_template_provider.search_tools_by_name`

`get_builtin_tools_mapping` 与 `get_system_tools_mapping` 走 `tool_template_provider`（`get_builtin_tools` / `list_all_tools`），返回 `name -> module.path` 映射。

## 安全封装：`nexus_utils/safe_agent_factory.py`

### `create_validated_agent` (nexus_utils/safe_agent_factory.py:3299)

在创建前调用 `validate_agent_dependencies`；若校验失败且 `auto_fix_dependencies=True`，调用 `fix_agent_dependencies` 后再重校验；最后仍用 `create_agent_from_prompt_template` 创建；创建后发一次 `"Hello, this is a test message."` 作为功能烟测。

返回字典结构：

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

| 参数 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `agent_name` | `str` | — | 与 `create_agent_from_prompt_template` 一致 |
| `env`, `version`, `model_id` | `str` | `"production"` / `"latest"` / `"default"` | 同上 |
| `enable_logging` | `bool` | `False` | 同上 |
| `state` | `Optional[Dict[str, Any]]` | `None` | 同上 |
| `session_manager` | `Optional[Any]` | `None` | 同上 |
| `auto_fix_dependencies` | `bool` | `True` | 校验失败是否自动尝试修复 |
| `**agent_params` | — | — | 透传 |

### `create_agent_with_fallback` (nexus_utils/safe_agent_factory.py:3412)

```python
create_agent_with_fallback(
    agent_name: str,
    fallback_agent_name: Optional[str] = None,
    **kwargs,
) -> Dict[str, Any]
```

主 Agent 创建失败且提供了 `fallback_agent_name` 时用备用 Agent 兜底；备用成功时在返回体中带 `primary_agent_error`。

### `batch_create_agents` (nexus_utils/safe_agent_factory.py:3457)

```python
batch_create_agents(
    agent_configs: List[Dict[str, Any]],
    continue_on_error: bool = True,
) -> Dict[str, Any]
```

每项 config 必须含 `agent_name`，其余键作为参数透传 `create_validated_agent`。返回 `total_agents` / `successful_agents` / `failed_agents` / `agent_results` / `created_agents`。

### `get_agent_health_status` (nexus_utils/safe_agent_factory.py:3517)

```python
get_agent_health_status(agent: Agent) -> Dict[str, Any]
```

读取 `agent.name` / `agent.model.{model_id,max_tokens,temperature}` / `len(agent.tools)` / `len(agent.system_prompt)`，并发送 `"Health check test"` 做功能烟测，把结果汇入 `last_test_success` / `last_test_response_length` / `last_test_error`。

## 依赖校验：`nexus_utils/agent_validation.py`

### `validate_agent_dependencies` (nexus_utils/agent_validation.py:3624)

```python
validate_agent_dependencies(agent_name: str, version: str = "latest") -> Dict[str, Any]
```

1. `get_default_prompt_manager().get_agent(agent_name)` 取模板；不存在返回 `{"valid": False, "error": "..."}`。
2. `template.get_version(version)`；不存在同上。
3. 遍历 `metadata.tools_dependencies`：先 `get_tool_by_path`，失败再 `get_tool_by_name(path.split('/')[-1])`，再失败记入 `missing_tools`；异常进 `invalid_tools`。
4. 若有 `metadata.supported_models`，保留钩子（当前无模型可用性检查）。
5. 无缺失时 `valid=True`，否则调用 `generate_fix_recommendations` 附加修复建议。

返回结构：

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
    "recommendations": [str]  # 仅失败时存在
}
```

### `generate_fix_recommendations` (nexus_utils/agent_validation.py:3718)

按前缀给出建议：`strands_tools/` → 检查 pip 包；`tools/generated_tools/` / `tools/system_tools/` / `tools/template_tools/` → 创建对应存根文件。

### `validate_all_agents` (nexus_utils/agent_validation.py:3754)

对 `manager.list_all_agent_paths()` 的每个相对路径调用 `validate_agent_dependencies`，汇总 `total_agents` / `valid_agents` / `invalid_agents` / `agent_results`。

### `fix_agent_dependencies` (nexus_utils/agent_validation.py:3796)

若 `auto_fix=True`，对 `missing_tools` 按前缀调用 `create_generated_tool_stub` 或 `create_system_tool_stub`。返回 `fixed_tools` / `failed_fixes`。

### `create_generated_tool_stub` / `create_system_tool_stub` (nexus_utils/agent_validation.py:3872,3933)

在缺失路径写入一个 `@tool` 装饰的函数存根，内容为：

```python
from strands import tool

@tool
def <function_name>(*args, **kwargs) -> str:
    """工具函数存根 ..."""
    return "这是一个自动生成的工具存根，请实现具体功能"
```

## AgentCore 入口点约定

每个 Agent 运行脚本都必须提供一个 `@app.entrypoint` 异步函数，使其可被 `BedrockAgentCoreApp` 部署：

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

| 约定 | 说明 |
|------|------|
| 必须 `yield` 而非 `return` | AgentCore 以流式协议消费 |
| 支持 `prompt` / `message` / `input` 三个 key | 兼容不同前端调用 |
| `session_id` 从 `context.session_id` 取 | 用于会话关联 |
| 设置 `os.environ["BYPASS_TOOL_CONSENT"] = "true"` | 跳过 Strands SDK 的交互式工具授权确认 |

容器内启动方式：脚本末尾检测 `os.environ.get("DOCKER_CONTAINER") == "1"`，若是则 `app.run()`（监听 8080）。

## 单 Agent 脚本的骨架模式

所有 `agents/template_agents/single_agent/*.py` 遵循同一结构。以 `api_integration_agent.py` 为例（节选）：

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
    ...  # 同上 AgentCore handler 模式

if __name__ == "__main__":
    # argparse: -i/--input, -e/--env, -v/--version, -it/--interactive
    # is_docker -> app.run()
    # interactive -> 循环 input(); agent(user_input)
    # args.input -> agent(args.input)
    # 默认 -> app.run()
    ...
```

关键约定：

- `agent_config_path` 是 prompt 模板相对路径（`template_prompts/&lt;name&gt;` 或 `generated_agents_prompts/&lt;ns&gt;/&lt;name&gt;`）。
- 模块顶层立即创建一个默认 agent 实例（`api_integration = create_api_integration_agent()`），供 `@app.entrypoint` 共享。
- CLI 通过 `argparse` 支持：`-i/--input`（一次性输入）、`-e/--env`、`-v/--version`、`-it/--interactive`（多轮交互）；部分模板还加 `-f/--file`（`document_processor_agent`）、`-u/--url`（`api_integration_agent`）、`-t/--topic`（`deep_research_agent`）等。

下表展示各单 Agent 脚本的默认 `agent_config_path` 与 CLI 额外参数：

| 脚本 | `agent_config_path` | CLI 额外参数 |
|------|--------------------|---------------|
| `default_agent.py` | `template_prompts/default` | — |
| `document_processor_agent.py` | `template_prompts/document_processor_agent` | `-f/--file` |
| `data_analyzer_agent.py` | `template_prompts/data_analyzer_agent` | `-f/--file` |
| `api_integration_agent.py` | `template_prompts/api_integration_agent` | `-u/--url` |
| `content_generator_agent.py` | `template_prompts/content_generator_agent` | `-t/--type` |
| `deep_research_agent.py` | `template_prompts/deep_research_agent` | `-t/--topic`, `-s/--scope`, `-d/--depth` |
| `html2pptx_agent.py` | `generated_agents_prompts/html2pptx/html2pptx_agent` | 子命令 `convert` / `analyze` / `suggest` / `clear-cache` / `interactive` |

## 多 Agent 编排：两种模式

### 模式 A：显式编排（`stock_analysis_agent.py`）

主类 `StockAnalysisSystem`（`agents/template_agents/multi_agent/stock_analysis_agent.py:429`）在 `__init__` 里按固定顺序创建 7 个子 Agent：

| 属性 | Agent prompt 路径 |
|------|-------------------|
| `self.coordinator_agent` | `generated_agents_prompts/stock_analysis_agent/coordinator_agent` |
| `self.data_collector_agent` | `.../data_collector_agent` |
| `self.valuation_agent` | `.../valuation_agent` |
| `self.prediction_agent` | `.../prediction_agent` |
| `self.risk_assessment_agent` | `.../risk_assessment_agent` |
| `self.benchmark_agent` | `.../benchmark_agent` |
| `self.report_generator_agent` | `.../report_generator_agent` |

业务入口 `analyze_stock(symbol, **kwargs)` 直接调用 `self.coordinator_agent(request_text)`，由 coordinator 在 prompt 里指挥其他 Agent。`_parse_agent_response(response)` 做多层级属性检查（`.content` / `str` / `.text`）再从内容中用 `find('{') ... rfind('}') + 1` 抽取 JSON。

AgentCore handler（`agents/template_agents/multi_agent/stock_analysis_agent.py:647` 附近）`stream_async` 的是 `system.coordinator_agent`。

### 模式 B：Swarm 编排（`tech_doc_swarm.py`）

`TechDocSwarmSystem`（`agents/template_agents/multi_agent/tech_doc_swarm.py:828`）创建 3 个 Agent 后，用 `strands.multiagent.Swarm` 打包：

```python
from strands.multiagent import Swarm

self.swarm = Swarm(
    [self.document_writer, self.document_reviewer, self.content_processor],
    max_handoffs=30,
    max_iterations=30,
    execution_timeout=600.0,         # 10 分钟整体
    node_timeout=300.0,              # 5 分钟每个节点
    repetitive_handoff_detection_window=10,
    repetitive_handoff_min_unique_agents=2,
)
```

| Swarm 参数 | 值 | 语义 |
|------------|-----|------|
| `max_handoffs` | `30` | Agent 之间最大交接次数 |
| `max_iterations` | `30` | 总迭代上限 |
| `execution_timeout` | `600.0` | 整个工作流超时（秒） |
| `node_timeout` | `300.0` | 单个 Agent 节点超时（秒） |
| `repetitive_handoff_detection_window` | `10` | 检测重复交接的窗口 |
| `repetitive_handoff_min_unique_agents` | `2` | 窗口内最少唯一 Agent 数 |

业务入口 `process_user_requirement(user_requirement, style_config=None, pass_threshold=75.0)` 走三步：

1. `_generate_initial_document(user_requirement)` — 让 `document_writer` 输出 JSON 化初稿。
2. 审核循环（最多 `self.max_review_iterations=5` 次）：`_review_document` → 若未通过则 `_process_review_feedback` 让 `document_writer` 改稿。
3. `_process_document_to_html(...)` — 直接调用 `tools.generated_tools.tech_doc_multi_agent_system.html_generator` 系列工具把通过审核的 JSON 文档转 HTML。

`_parse_agent_response` 与 `stock_analysis_agent` 的实现一致（多层属性检查 + JSON 抽取）。

## 扩展点：添加一个新 Agent

### 1. 新增单 Agent 模板

**步骤：**

1. **写 prompt 模板**：在 `prompts/template_prompts/&lt;my_agent&gt;/` 下建立模板目录（由 `prompts_manager` 组织的 YAML/Markdown），声明 system prompt、`get_environment_config` 中各环境的 `max_tokens`/`temperature`/`streaming`、以及 `metadata.tools_dependencies`。
2. **写运行脚本**：参照 `agents/template_agents/single_agent/api_integration_agent.py` 骨架（见上节），只需修改：
    - `agent_config_path = "template_prompts/&lt;my_agent&gt;"`
    - 工厂函数名 `create_&lt;my_agent&gt;()`
    - 顶层实例变量名
    - `argparse` 描述与额外参数
3. **注册到清单**：在 `agents/template_agents/agent_templates_config.yaml` 的 `templates:` 下新增一个条目，字段包括 `name` / `description` / `agent_dependencies` / `tools_dependencies` / `path` / `prompt_template` / `tags`。
4. **确保工具存在**：`tools_dependencies` 中每一条都要能被 `get_tool_by_path` 解析（见工具解析章节）；可用 `python -m nexus_utils.agent_validation -a &lt;my_agent&gt;` 自检。
5. **本地验证**：`python agents/template_agents/single_agent/&lt;my_agent&gt;.py -i "测试消息"` 或 `-it` 交互。

### 2. 新增多 Agent 系统

**模式 A（显式编排）** — 如果流程是固定顺序且 coordinator 会做调度：

1. 复制 `stock_analysis_agent.py` 为模板。
2. 改 `_initialize_agents` 里的 Agent 列表与 prompt 路径。
3. 改 `analyze_stock` / 业务入口：重写 prompt 文本、调整 `_parse_agent_response` 解析策略。
4. 修改 `@app.entrypoint` 中对 `coordinator_agent.stream_async` 的调用，保证流式事件被 `yield` 出去。
5. 在 `agent_templates_config.yaml` 注册 `agent_dependencies: []`（协调内建）与所有子 Agent 需要的 `tools_dependencies` 合集。

**模式 B（Swarm）** — 如果 Agent 间是去中心化的对等交接：

1. 复制 `tech_doc_swarm.py` 为模板。
2. 在 `_create_agents` 换掉 3 个 `create_agent_from_prompt_template` 的 `agent_name`。
3. 按需调整 `Swarm(..., max_handoffs=, max_iterations=, execution_timeout=, node_timeout=, ...)` 参数。
4. 重写业务入口（`process_user_requirement` 那套）或直接 `self.swarm(...)` 让 Swarm 自主跑。
5. 在 `agent_templates_config.yaml` 的模板条目中使用 `prompt_templates`（复数，数组）而非 `prompt_template`。

### 3. 复用 `safe_agent_factory`

生产路径建议优先走 `create_validated_agent(...)`：

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

`auto_fix_dependencies=True` 会尝试用 `create_generated_tool_stub` 补齐缺失工具——**生产环境谨慎使用**，因为存根只返回占位文本。

### 4. 新增模型提供商

如果需要接入 `MODEL_PROVIDER_REGISTRY` 之外的 provider：

1. 在 Strands SDK 中确保模型类存在（如 `strands.models.&lt;provider&gt;.<ProviderModel>`）。
2. 向 `MODEL_PROVIDER_REGISTRY` 加入条目 `(模块路径, 类名, pip 安装包名)`。
3. 在 prompt 模板 YAML 的 `metadata.model_config` 中提供 provider 特定参数，`create_model_for_provider` 会合并到构造 kwargs（provider 特定参数优先级高于 `max_tokens` / `temperature`）。
4. 调用点用 `create_model_for_provider(provider, model_id, model_config=..., max_tokens=..., temperature=...)` 替代 `get_bedrock_model`。

### 5. 扩展模型目录

`config/model_catalog.yaml` 是前端刷新按钮读取的纯展示目录，由 `providers[*].models[*]` 的字典列表构成。每个条目字段：

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | `str` | Bedrock inference profile ID（如 `us.anthropic.claude-sonnet-4-20250514-v1:0`） |
| `name` | `str` | 显示名 |
| `tier` | `"pro" \| "standard" \| "lite"` | 分级，用于前端筛选 |
| `is_global` | `bool` | 是否跨区域 inference profile |
| `supports_vision` | `bool` | 是否支持图片/文档输入（来自 Bedrock `inputModalities`） |

该目录**不会**自动刷新，新增模型后需要手动编辑 YAML 并通过前端按钮触发重载。

## 调用关系 / 数据流

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
          ├── (遍历 metadata.tools_dependencies)
          │     └─> get_tool_by_path(tool_path)
          │           ├─ strands_tools/*  -> importlib
          │           ├─ system_tools/*   -> tools.system_tools.*
          │           ├─ generated_tools/* -> tools.generated_tools.* (失败则 _sync_tool_from_s3)
          │           └─ template_tools/* -> tools.template_tools.*
          │
          └── strands.Agent(model=..., tools=[...], system_prompt=..., ...)
```

安全路径：

```
safe_agent_factory.create_validated_agent(...)
   ├── agent_validation.validate_agent_dependencies(name, version)
   │     └── (对每个 tools_dependencies 项) get_tool_by_path / get_tool_by_name
   ├── (失败且 auto_fix)  agent_validation.fix_agent_dependencies(name, version, auto_fix=True)
   │                         └── create_generated_tool_stub / create_system_tool_stub
   ├── create_agent_from_prompt_template(...)
   └── agent("Hello, this is a test message.")   # smoke test
```

## 调试与常见问题

| 现象 / 日志 | 可能原因 | 排查 |
|-------------|---------|------|
| `Agent模板 '&lt;name&gt;' 不存在` | prompt 模板路径拼写错或未放到 `prompts/.../&lt;name&gt;/` | `prompts_manager.get_default_prompt_manager().list_all_agent_paths()` 查表 |
| `Agent '&lt;name&gt;' 的版本 '&lt;v&gt;' 不存在` | 模板 YAML 中未声明该版本 | 检查模板下的版本目录与 `latest` 软链接 |
| `Unsupported model provider: '&lt;x&gt;'` | `create_model_for_provider` 中 provider 名不在注册表 | 往 `MODEL_PROVIDER_REGISTRY` 加条目 |
| `Provider '&lt;x&gt;' requires '&lt;pkg&gt;'. Install it with: pip install '&lt;pkg&gt;'` | Strands extras 没装 | 按提示 `pip install '&lt;pkg&gt;'` |
| `Failed to import strands_tools tool &lt;path&gt;` | `strands-agents-tools` 未安装或工具名错 | `pip show strands-agents-tools`，核对 `get_builtin_tools_mapping()` |
| `🔄 从 S3 同步工具文件: ... → ...` 后仍失败 | `generated_tools` 本地无且 S3 bucket 也无此 key，或凭证不足 | 检查 `config.nexus_ai.artifacts_s3_bucket` 和 AWS 凭证 |
| `❌ Agent创建失败: ...` 后面紧跟 AWS 异常 | `BedrockModel` 构造失败（权限/区域/模型未开通） | 核对 `config.bedrock.bedrock_region_name` 与 Bedrock Access |
| `prompts_manager.get_agent(...).get_environment_config(env).temperature` 为 `None` | 模板未设 temperature | `get_bedrock_model` 已做 `if ... is not None else 0.8` 兜底，不会崩 |
| Swarm 反复在两个 Agent 之间跳 | `repetitive_handoff_detection_window` / `repetitive_handoff_min_unique_agents` 未生效 | 调高 `repetitive_handoff_min_unique_agents`，或检查 handoff prompt |
| `execution_timeout` 到期 | 整个 Swarm 工作流卡住 | 放宽 `execution_timeout` / `node_timeout`，或减少 `max_review_iterations` |

命令行自检：

```bash
# 验证单个 Agent 的工具依赖
python -m nexus_utils.agent_validation -a template_prompts/my_agent -v latest

# 扫描所有 Agent
python -m nexus_utils.agent_validation --all

# 自动修复（仅补存根）
python -m nexus_utils.agent_validation -a template_prompts/my_agent --fix

# 用 safe factory 跑一次烟测
python -m nexus_utils.safe_agent_factory -a template_prompts/my_agent --test "你好"
```

## 延伸阅读

- `agents/template_agents/agent_templates_config.yaml` — 现存模板的权威清单
- `nexus_utils/agent_factory.py` — 工厂实现（工具解析、S3 同步、缓存 kwargs）
- `nexus_utils/safe_agent_factory.py` — 依赖校验 + fallback + 批量创建
- `nexus_utils/agent_validation.py` — 校验与存根生成
- `config/model_catalog.yaml` — 前端展示用的 Bedrock 模型目录
- `agents/template_agents/multi_agent/stock_analysis_agent.py` — 显式编排示例
- `agents/template_agents/multi_agent/tech_doc_swarm.py` — Swarm 编排示例
