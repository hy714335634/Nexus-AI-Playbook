---
title: 术语表
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - CLAUDE.md
    - README.md
    - nexus_utils/agent_factory.py
    - nexus_utils/magician.py
    - nexus_utils/prompts_manager.py
  generated_at: 2026-05-09T01:39:50+00:00
  generated_by: docs-sync v2
---

# 术语表

本表收录 Nexus-AI 文档中出现的所有关键术语、组件名、工作流名、配置键、AWS 服务和协议缩写。术语按主题分组，组内按字母顺序排列；"英文"列保持与源代码、CLI、YAML 键完全一致，不翻译；"说明"列给出精确、单一来源的定义。

::: tip 如何查阅
使用浏览器的 `Ctrl + F` / `⌘ + F` 直接搜索术语的中文或英文名。所有"参见"指向同一文档内的其他小节或 Reference 章节下的独立文档。
:::

## 1. 平台与核心概念

| 术语 | 英文 | 说明 |
|---|---|---|
| Nexus-AI | Nexus-AI | 开源 AI Agent 开发平台；通过自然语言描述自动生成完整 Agent 系统，基于 AWS Bedrock 与 Strands Agents 框架。 |
| Agent（智能体） | Agent | 由系统提示词、工具集合、模型配置组成的可执行单元；在 Nexus-AI 中对应 `Strands` 框架的 `Agent` 实例。 |
| Agent Build Agent | Agent Build Agent | 由 8 个专业 Agent 协作完成 Agent 构建的元系统；覆盖需求分析→架构设计→代码生成全流程。 |
| 多 Agent 协作 | Multi-Agent Collaboration | 多个 Agent 按 Graph、Swarm 或单体方式协作完成复合任务的模式；由 `agent_build` 等工作流驱动。 |
| 自然语言构建 | Natural Language Build | 用户以自然语言输入需求，平台自动产出 Agent 代码、工具、提示词的构建方式。 |
| Playbook | Playbook | Nexus-AI 的文档站点与操作指南总称，即当前阅读的文档集合。 |

## 2. Agent 分类

| 术语 | 英文 | 说明 |
|---|---|---|
| 系统 Agent | System Agent | 平台内置、驱动构建/更新/工具工作流的元 Agent；提示词位于 `prompts/system_agents_prompts/`。 |
| 模板 Agent | Template Agent | 官方维护、可直接复用的 Agent 起点模板；提示词位于 `prompts/template_prompts/`。 |
| 生成 Agent | Generated Agent | 由 Agent Build Workflow 自动生成的业务 Agent；提示词位于 `prompts/generated_agents_prompts/`。 |
| Magician | Magician | 意图路由 Agent，负责根据用户输入选择单体、Graph 或 Swarm 编排方式并构建对应实例。 |
| 需求分析师 | Requirements Analyst | Agent Build Workflow 第 1 阶段的系统 Agent，负责将自然语言需求结构化。 |
| 架构师 | Architect | 负责多 Agent 拓扑、数据流、职责边界设计的系统 Agent。 |
| Agent 设计师 | Agent Designer | 为每个目标 Agent 设计角色、能力、输入输出的系统 Agent。 |
| 提示词工程师 | Prompt Engineer | 生成符合平台 YAML 结构的系统提示词、示例、约束的系统 Agent。 |
| 工具开发者 | Tool Developer | 生成 `@tool` 装饰的工具函数并登记到工具库的系统 Agent。 |
| 代码开发者 | Code Developer | 生成最终 Agent 代码、入口脚本、依赖声明的系统 Agent。 |
| 测试工程师 | Test Engineer | 生成并执行验证测试用例的系统 Agent。 |

## 3. 工作流与阶段

| 术语 | 英文 | 说明 |
|---|---|---|
| 工作流 | Workflow | 由多个阶段（Stage）通过 SQS 驱动串联而成的长时任务编排；定义在 `config/workflows.yaml`。 |
| agent_build | agent_build | V2 Agent 构建工作流，共 8 个阶段，支持 fork/join 并行 Agent 设计。 |
| agent_update | agent_update | V2 Agent 更新工作流，共 5 个阶段，支持 `skip_stages` 跳过不需要重做的阶段。 |
| tool_build | tool_build | V2 工具构建工作流，共 5 个阶段。 |
| skill_build | skill_build | V2 技能（Skill）构建工作流，共 5 个阶段。 |
| magician | magician | 单阶段意图路由工作流，交由 Magician Agent 处理。 |
| 阶段 | Stage | 工作流的最小执行单元；一条 SQS 消息触发一个 Stage，完成后路由至下一个 Stage。 |
| 单阶段执行模型 | Single-Stage Execution Model | Worker 每次仅处理一个 Stage 再通过 SQS 路由到下一个的执行约定，保证重启安全与水平扩展。 |
| Fork/Join | Fork / Join | 工作流分叉并行执行多个 Stage、再汇合输入到下游的模式。 |
| skip_stages | skip_stages | `agent_update` 工作流入参字段，指定要跳过的阶段列表。 |
| 输入拼装 | Input Assembly | Worker 执行某 Stage 前从 DynamoDB 读取前置阶段结果并组装成输入的过程。 |
| 输出解析 | Output Parsing | 对 Stage 输出做 JSON 校验与失败重试的机制。 |

## 4. 编排模式

| 术语 | 英文 | 说明 |
|---|---|---|
| 编排类型 | orchestration_type | `AgentOrchestrationResult` 字段；取值 `agent`、`graph` 或 `swarm`。 |
| 单体 Agent | Single Agent | 单一 Agent 处理全部输入的最简编排；对应 `orchestration_type=agent`。 |
| Graph | Graph | 有向图编排，由节点（Agent）与边（依赖关系）组成；由 `GraphBuilder` 构建。 |
| Swarm | Swarm | 多 Agent 自主协作编排，支持角色、优先级、通信模式等配置。 |
| GraphBuilder | GraphBuilder | `strands.multiagent.GraphBuilder`，用于 `add_node`、`add_edge`、`build()` 构建 Graph。 |
| 节点 | Node | Graph 编排中的一个 Agent 实例，带 `node_id`（或 `id`）与 `agent` 信息。 |
| 边 | Edge | Graph 编排中两个节点间的依赖关系；新格式用 `from`/`to`，旧格式用 `source`/`target`。 |
| depends_on | depends_on | 节点字段，在无 `edges` 时用于自动推导 Graph 边。 |
| 通信模式 | communication_pattern | Swarm 配置字段，定义 Agent 之间的消息交换方式。 |
| 角色 | role | Swarm 中每个 Agent 的职责标签。 |
| 优先级 | priority | Swarm 中 Agent 的执行优先级数值，默认 1。 |
| 备选方案 | alternative_solutions | `AgentOrchestrationResult` 中的备选编排列表，供 Magician 回退或对比。 |

## 5. 核心服务

| 术语 | 英文 | 说明 |
|---|---|---|
| API 后端 | API Backend | 基于 FastAPI + Uvicorn 的 RESTful API 服务，入口 `api/v2/main.py`；默认端口 `8000`，提供 30+ 路由、28+ 服务、JWT 认证、SSE 流式与 OTEL 探针。 |
| Worker | Worker | SQS 消息消费者，入口 `worker/main.py`；执行构建/部署工作流的单阶段任务。 |
| Web 前端 | Web Frontend | Next.js 14 App Router + React 18 + TypeScript + Tailwind CSS；默认端口 `3000`，使用 TanStack Query 管理状态。 |
| Gateway | Gateway | 带重连与 Valkey 缓冲的流式代理；支持 WebSocket，入口 `nexus_utils/gateway/__main__.py`。 |
| Bridge | Bridge | 远端服务器连接管理器，支持 SSH 类操作、多连接、并行执行与命令权限控制，入口 `nexus_utils/bridge/`；默认端口 `8001`。 |
| MCP Server | MCP Server | 基于 FastMCP 3.x 的 MCP 端点，默认端口 `9000`，将平台 Agent 暴露为 MCP Tool 供 IDE 调用。 |
| Event Scheduler | Event Scheduler | 可选的类 Cron 定时任务执行器，位于 `nexus_utils/event_scheduler/`。 |
| OTEL Collector | OTEL Collector | 可选的 OpenTelemetry Collector，由 `./nexus-cli service start --otel` 启动。 |

## 6. 关键子系统

| 术语 | 英文 | 说明 |
|---|---|---|
| Workflow Engine v2 | Workflow Engine v2 | `nexus_utils/workflow/engine_v2.py`；实现 SQS 驱动的单阶段执行、fork/join、输入拼装、输出解析与重试。 |
| Agent Factory | Agent Factory | `nexus_utils/agent_factory.py`；从 YAML 提示词模板创建 Agent 的工厂，入口函数 `create_agent_from_prompt_template()`。 |
| Prompts Manager | Prompts Manager | `nexus_utils/prompts_manager.py`；单例模式的 YAML 提示词加载与版本管理器。 |
| Database Layer | Database Layer | `api/v2/database/dynamodb.py`；单例 DynamoDB 客户端，连接池、指数退避重试。 |
| S3SessionManager | S3SessionManager | 将会话上下文持久化到 S3 的会话管理器；Agent 对话前加载、对话后写回。 |
| Stream Relay | Stream Relay | 基于 Valkey Stream 的事件缓冲层，将 Agent 执行与 SSE 推送解耦，支持断点续播。 |
| Asset Cache Manager | Asset Cache Manager | `nexus_utils/asset_cache`；负责将 DDB 中登记的 Generated Agent 资产从 S3 拉取到本地缓存。 |
| S3-First | S3-First | Prompt Manager 的按需加载策略：内存缓存未命中时从 DDB+S3 拉取并注册。 |
| Stage Logging | Stage Logging | 已废弃的文件级阶段日志（`logs/stages/`），现由 Aurora `messages` 表承担对话记录。 |

## 7. 提示词与 YAML 结构

| 术语 | 英文 | 说明 |
|---|---|---|
| 提示词模板 | Prompt Template | `prompts/` 下 YAML 文件，定义 Agent 的结构化提示词、环境配置、版本、工具、元数据。 |
| PromptAgent | PromptAgent | YAML 顶层对象；包含 `agent_name`、`description`、`category`、`environments`、`versions`。 |
| PromptVersion | PromptVersion | 一个版本的提示词记录；含 `system_prompt`、`user_prompt_template`、`tools`、`constraints`、`examples`、`metadata` 等。 |
| 版本 | version | PromptVersion 的版本号；支持字符串如 `"1.0.0"` 或特殊值 `"latest"`。 |
| latest | latest | 请求最新版本的约定关键字；优先返回名为 `latest` 的版本，否则按点分数字排序取最大值。 |
| 状态 | status | PromptVersion 的状态字段，默认 `stable`。 |
| 环境配置 | EnvironmentConfig | 字段组：`temperature`、`max_tokens`、`streaming`、`debug_mode`；按 `production` 等环境名分别定义。 |
| production | production | 默认环境名；`get_environment_config()` 默认取该环境。 |
| streaming | streaming | 环境配置字段，控制是否开启模型流式输出。 |
| temperature | temperature | 环境配置字段，模型温度；Agent Factory 未提供时默认 `0.8`。 |
| max_tokens | max_tokens | 环境配置字段，单次最大生成 token 数。 |
| 元数据 | Metadata | YAML 的 `metadata` 块，描述 Agent 的标签、依赖、模型支持、兼容性、性能指标等。 |
| tags | tags | `Metadata.tags`，Agent 的自由文本标签列表。 |
| supported_models | supported_models | `Metadata`，声明该 Agent 可运行的模型列表。 |
| lib_dependencies | lib_dependencies | `Metadata`，运行该 Agent 需要的 Python 包。 |
| tools_dependencies | tools_dependencies | `Metadata`，该 Agent 需要的工具路径列表。 |
| mcp_dependencies | mcp_dependencies | `Metadata`，该 Agent 依赖的 MCP Server 列表；空值解析为 `[]`，单字符串自动转列表。 |
| model_provider | model_provider | `Metadata`，模型提供商；默认 `bedrock`，可选 `ollama`、`openai`、`anthropic`、`litellm`、`mistral`、`gemini`、`llamaapi`。 |
| model_config | model_config | `Metadata`，提供商特定的模型构造参数；与环境配置合并，提供商参数优先。 |
| swarm_config | swarm_config | `Metadata`，Swarm 多 Agent 协作的配置块。 |
| conversation_manager_config | ConversationManagerConfig | `Metadata.conversation_manager`；对话管理器策略。 |
| retry_strategy | retry_strategy | `Metadata`，覆盖全局 `strands.retry_strategy` 的重试策略。 |
| performance_metrics | PerformanceMetrics | `Metadata`，包含 `accuracy`、`response_time`、`user_satisfaction` 三个可选字段。 |
| compatibility | Compatibility | `Metadata`，含 `min_strands_version` 与 `supported_models`。 |
| additional_request_fields | additional_request_fields | `Metadata`，传递给模型 API 的额外字段（例如 Bedrock 的 `anthropic_beta` 等）。 |
| constraints | constraints | `PromptVersion.constraints`，运行时必须遵守的硬约束文本列表。 |
| examples | examples | `PromptVersion.examples`，`user`/`assistant` 对话示例列表。 |
| context_window | context_window | `PromptVersion.context_window`，模型上下文窗口长度（token 数）。 |
| user_prompt_template | user_prompt_template | `PromptVersion.user_prompt_template`，用户输入侧的模板字符串。 |

## 8. 对话管理器（Conversation Manager）

| 术语 | 英文 | 说明 |
|---|---|---|
| ConversationManagerConfig | ConversationManagerConfig | YAML 字段 `metadata.conversation_manager` 的解析类。 |
| enabled | enabled | 是否启用；`None` 表示沿用全局配置，`true`/`false` 显式覆盖。 |
| type | type | 对话管理器类型；`sliding_window`、`summarizing` 或 `null`。 |
| window_size | window_size | `sliding_window` 策略保留的最近消息数量上限。 |
| should_truncate_results | should_truncate_results | 是否对工具结果做截断。 |
| summary_ratio | summary_ratio | `summarizing` 策略的摘要比例。 |
| preserve_recent_messages | preserve_recent_messages | `summarizing` 策略保留的最近未摘要消息数。 |
| use_custom_agent | use_custom_agent | 是否使用自定义 Agent 做摘要。 |
| custom_agent_model_id | custom_agent_model_id | 自定义摘要 Agent 的模型 ID。 |
| custom_agent_prompt_path | custom_agent_prompt_path | 自定义摘要 Agent 的提示词 YAML 路径。 |

## 9. 模型与 Bedrock

| 术语 | 英文 | 说明 |
|---|---|---|
| AWS Bedrock | AWS Bedrock | 托管基础模型推理的 AWS 服务；Nexus-AI 必需依赖。 |
| BedrockModel | BedrockModel | `strands.models.BedrockModel`；Agent Factory 默认使用的模型客户端。 |
| model_id | model_id | `config/default_config.yaml` → `bedrock.model_id`，默认主模型 ID。 |
| lite_model_id | lite_model_id | `bedrock.lite_model_id`，轻量模型 ID（Haiku 系列）。 |
| pro_model_id | pro_model_id | `bedrock.pro_model_id`，专业模型 ID（Opus 系列）。 |
| Claude Sonnet | Claude Sonnet | Anthropic 通用模型系列；默认 `us.anthropic.claude-sonnet-4-5-20250929-v1:0`。 |
| Claude Opus | Claude Opus | Anthropic 专业模型系列；默认 `us.anthropic.claude-opus-4-5-20251101-v1:0`。 |
| Claude Haiku | Claude Haiku | Anthropic 轻量模型系列；默认 `us.anthropic.claude-haiku-4-5-20251001-v1:0`。 |
| Nova | Amazon Nova | Amazon 基础模型系列（Pro / Lite / Micro）；与 Claude 同属支持 prompt caching 的模型族。 |
| Prompt Caching | Prompt Caching | Bedrock 提供的提示词缓存；首次写入 1.25× 费用，5 分钟内命中 0.1×（90% 折扣）。 |
| cache_prompt | cache_prompt | `BedrockModel` 构造参数；开启系统提示词缓存，取值 `"default"`。 |
| cache_tools | cache_tools | `BedrockModel` 构造参数；开启工具定义缓存，取值 `"default"`。 |
| bedrock.prompt_caching | bedrock.prompt_caching | `default_config.yaml` 配置键；包含 `enabled`、`cache_system_prompt`、`cache_tools` 等。 |
| connect_config | bedrock.connect_config | Bedrock 连接参数（`retries.max_attempts`、`retries.mode`、`connect_timeout`、`read_timeout`）。 |
| RefreshableCredentials | RefreshableCredentials | Sandbox VM 内用于凭证定期刷新的 boto3 凭证对象。 |
| IAM role credential chain | IAM role credential chain | 主 EC2 使用的凭证解析链（实例元数据、环境变量、配置文件等）。 |

## 10. 多模型提供商

| 术语 | 英文 | 说明 |
|---|---|---|
| MODEL_PROVIDER_REGISTRY | MODEL_PROVIDER_REGISTRY | `agent_factory.py` 的映射表：provider → (`模块路径`, `类名`, `pip 安装包`)。 |
| bedrock | bedrock | 默认提供商；使用 `get_bedrock_model()`，不进入 `MODEL_PROVIDER_REGISTRY`。 |
| ollama | ollama | `strands.models.ollama.OllamaModel`；需要 `pip install 'strands-agents[ollama]'`。 |
| openai | openai | `strands.models.openai.OpenAIModel`；需要 `strands-agents[openai]`。 |
| anthropic | anthropic | `strands.models.anthropic.AnthropicModel`；需要 `strands-agents[anthropic]`。 |
| litellm | litellm | `strands.models.litellm.LiteLLMModel`；需要 `strands-agents[litellm]`。 |
| llamaapi | llamaapi | `strands.models.llamaapi.LlamaAPIModel`；需要 `strands-agents[llamaapi]`。 |
| mistral | mistral | `strands.models.mistral.MistralModel`；需要 `strands-agents[mistral]`。 |
| gemini | gemini | `strands.models.gemini.GeminiModel`；需要 `strands-agents[gemini]`。 |
| create_model_for_provider | create_model_for_provider | 通用工厂函数；根据 `provider` 动态导入类并合并 `max_tokens`、`temperature`、`model_config` 参数。 |

## 11. 工具（Tools）

| 术语 | 英文 | 说明 |
|---|---|---|
| Tool | Tool | Agent 可调用的函数/能力；用 `@tool` 装饰或以模块方式暴露。 |
| @tool 装饰器 | @tool decorator | `strands` 框架装饰器；使函数成为 `DecoratedFunctionTool`，带 `tool_spec`。 |
| DecoratedFunctionTool | DecoratedFunctionTool | 装饰后的工具对象；`callable` 且具备 `tool_spec` 属性。 |
| 内置工具 | Builtin Tools | `strands_tools.*` 下的官方工具，如 `calculator`、`browser`。 |
| 系统工具 | System Tools | `tools/system_tools/` 下平台自带工具；例如 `agent_build_workflow/project_manager`。 |
| 模板工具 | Template Tools | `tools/template_tools/` 下可复制修改的示例工具；例如 `common/demo/weather_forecast`。 |
| 生成工具 | Generated Tools | `tools/generated_tools/` 下由构建流程生成的业务工具。 |
| 工具路径 | Tool Path | 工具在 Agent 配置中的引用格式，例如 `generated_tools/&lt;dir&gt;/&lt;script&gt;/&lt;function&gt;`。 |
| Tool Template Provider | Tool Template Provider | `tools.system_tools.agent_build_workflow.tool_template_provider`；提供 `get_builtin_tools`、`list_all_tools`、`search_tools_by_name` 等接口。 |
| get_tool_by_path | get_tool_by_path | 按完整路径导入工具，支持 `strands_tools/`、`system_tools/`、`template_tools/`、`generated_tools/` 四种前缀。 |
| get_tool_by_name | get_tool_by_name | 按工具名在内置映射、系统映射中查找；失败时转搜索。 |
| S3 工具同步 | S3 Tool Sync | 本地缺失 `generated_tools` 文件时从 `tools/&lt;dir&gt;/&lt;script&gt;.py` S3 Key 拉取的机制（`_sync_tool_from_s3`）。 |
| AgentCoreBrowser | AgentCoreBrowser | `strands_tools.browser` 的特殊实例化；按当前 boto3 region 构造（默认 `us-west-2`）。 |

## 12. 技能（Skills）

| 术语 | 英文 | 说明 |
|---|---|---|
| Skill | Skill | 一组可复用的能力打包，经由 `skill_build` 工作流生成；存储在 S3 并同步至 DDB。 |
| skill_activator | skill_activator | `tools.system_tools.skill_activator`；允许 Agent 运行时激活指定 Skill。 |
| skill_build | skill_build | 构建 Skill 的 5 阶段 V2 工作流。 |

## 13. MCP（Model Context Protocol）

| 术语 | 英文 | 说明 |
|---|---|---|
| MCP | Model Context Protocol | 跨进程的工具调用协议；Nexus-AI 既作为 MCP Server 也作为 MCP 客户端。 |
| FastMCP | FastMCP | MCP Server 的 Python 实现（3.x）；Nexus-AI 使用它将 Agent 暴露为工具。 |
| MCP Server | MCP Server | Nexus-AI 内置服务；将所有 `status=running` 的 Agent 自动注册为 MCP Tool；入口 `nexus_utils/mcp/mcp_server/__main__.py`。 |
| MCP Client | MCP Client | 连接 MCP Server 的一方；Kiro、Claude Code、Cursor 等 IDE 均为 MCP Client。 |
| Bearer Token | Bearer Token | MCP Server 认证凭证；通过 `Authorization: Bearer &lt;token&gt;` 请求头传递。 |
| NEXUS_MCP_TOKEN | NEXUS_MCP_TOKEN | 环境变量，用于预设固定的 MCP Bearer Token。 |
| .pids/mcp_token | .pids/mcp_token | 启动 MCP Server 时写入的 token 文件，用于外部读取。 |
| Streamable HTTP | Streamable HTTP | MCP Server 使用的传输层协议；MCP 端点 `http://localhost:9000/mcp`。 |
| system_mcp_server.json | system_mcp_server.json | `config/mcp/` 下的系统预置 MCP 服务器（如 AWS MCP）清单。 |
| public_mcp_server.json | public_mcp_server.json | `config/mcp/` 下用户可添加的自定义 MCP 服务器清单。 |

## 14. AWS 基础设施

| 术语 | 英文 | 说明 |
|---|---|---|
| Aurora PostgreSQL Serverless v2 | Aurora PostgreSQL Serverless v2 | 关系型主存；保存项目、Agent、会话、消息等 12 张表。 |
| DynamoDB | DynamoDB | KV 主存；保存工具、配置、事件调度等 18 张表。 |
| ElastiCache Valkey Serverless | ElastiCache Valkey Serverless | 缓存层；承担统计聚合、热数据、Stream 事件缓冲。 |
| Valkey Stream | Valkey Stream | Stream Relay 使用的流式结构，支持断点续播。 |
| SQS | Amazon SQS | 异步任务队列；构建、部署、通知三类队列。 |
| S3 | Amazon S3 | 对象存储；Agent 制品、会话文件、多模态内容、技能包。 |
| S3 Vectors | S3 Vectors | 向量存储；`CreateVectorBucket`、`CreateIndex`、`Query` 用于向量检索。 |
| CloudFormation | AWS CloudFormation | IaC 服务；`nexus-cli deploy up` 底层通过 Stack 管理资源。 |
| VPC | VPC | 虚拟私有网络；CloudFormation 模板默认 CIDR `10.0.0.0/16`。 |
| ALB | Application Load Balancer | 七层负载均衡；挂载 API/Web 目标组。 |
| CloudFront | CloudFront | CDN 分发；用于加速 Web 资源与 API。 |
| NAT Gateway | NAT Gateway | VPC 出网网关；由 CloudFormation 模板创建。 |
| SSM | AWS Systems Manager | 用于 `GetParameter` 获取 AMI ID。 |
| EC2 | Amazon EC2 | 实例运行时；默认实例类型 `c8i.2xlarge`。 |
| IAM Instance Profile | IAM Instance Profile | EC2 挂载角色的载体；默认 `admin-for-ec2`。 |
| IAM Identity Center | IAM Identity Center | 可选的 SAML 2.0 IdP；供 Nexus-AI SSO 对接。 |
| ECR | Amazon ECR | 容器镜像仓库；AgentCore 部署时读取镜像。 |
| AgentCore | Bedrock AgentCore | AWS Bedrock AgentCore 托管 Agent 运行时；Nexus-AI 支持 CI/CD 自动部署到该环境。 |

## 15. 部署与环境（nexus-cli deploy）

| 术语 | 英文 | 说明 |
|---|---|---|
| ENV_PREFIX | ENV_PREFIX | 必填的环境名前缀；用于命名所有 AWS 资源（Stack、VPC、Aurora、S3、DDB 等）。 |
| --github-token | --github-token | GitHub Personal Access Token；EC2 启动时用于拉取代码。 |
| --db-password | --db-password | Aurora PostgreSQL 数据库密码；必填。 |
| --branch | --branch | Git 分支，默认 `main`。 |
| --instance-type | --instance-type | EC2 实例类型，默认 `c8i.2xlarge`。 |
| --key-name | --key-name | SSH Key Pair 名称，默认 `Og_Normal`。 |
| --iam-instance-profile | --iam-instance-profile | EC2 绑定的 Instance Profile，默认 `admin-for-ec2`。 |
| --volume-size | --volume-size | EC2 根卷大小（GB），默认 `150`。 |
| --vpc-cidr | --vpc-cidr | VPC CIDR 地址段，默认 `10.0.0.0/16`。 |
| --region | --region | AWS 区域，默认 `us-west-2`。 |
| --user / --password | --user / --password | 平台登录凭证，默认 `admin` / `nexus`。 |
| --enable-sso | --enable-sso | 启用 SAML 2.0 SSO；与 IAM Identity Center 或其他 IdP 对接。 |
| --allowed-email-domains | --allowed-email-domains | SSO 模式下允许登录的邮箱域白名单。 |
| --enable-sandbox | --enable-sandbox | 启用 Sandbox 沙箱运行时。 |
| --sandbox-instance-type | --sandbox-instance-type | Sandbox 节点实例类型，默认 `c8i.xlarge`；必须支持 KVM。 |
| --sandbox-pool-size | --sandbox-pool-size | Sandbox 节点数量，默认 `1`。 |
| --sandbox-default-runtime | --sandbox-default-runtime | 默认运行时模式，取值 `local` 或 `ec2`。 |
| --sandbox-runtimes | --sandbox-runtimes | 允许的运行时模式列表，默认 `local,ec2`。 |
| --sandbox-prewarm-vms | --sandbox-prewarm-vms | 每节点预热 VM 数量，默认 `1`。 |
| --clean-data | --clean-data | 删除环境时级联清理 S3 / DDB / SQS 数据。 |

## 16. Sandbox 沙箱运行时

| 术语 | 英文 | 说明 |
|---|---|---|
| Sandbox | Sandbox | 为每个 Agent 会话提供 Firecracker microVM 级隔离的执行环境。 |
| Firecracker microVM | Firecracker microVM | AWS 开源的轻量级 VMM；Sandbox 用它启动隔离运行时。 |
| Sandbox Node | Sandbox Node | 承载若干 VM 的计算节点（EC2 实例）；由 `nexus-cli sandbox nodes` 管理。 |
| Sandbox VM | Sandbox VM | 运行单次 Agent 任务的 microVM；由 `nexus-cli sandbox list` 查看。 |
| local runtime | local | 在调用方本机直接启动 VM 的运行时模式。 |
| ec2 runtime | ec2 | 将 VM 任务调度到 Sandbox 节点池的运行时模式；生产默认。 |
| Prewarm VMs | Prewarm VMs | 每节点预先启动并保持空闲的 VM 数量，用于降低冷启动延迟。 |
| Rootfs | Rootfs | Sandbox VM 的根文件系统镜像；`nexus-cli sandbox rebuild-rootfs` 重建。 |
| vm_credentials | vm_credentials | `nexus_utils/sandbox/vm_credentials`；提供 `get_vm_boto_session`，为 VM 注入 RefreshableCredentials。 |
| Sandbox 调度日志 | Sandbox Scheduler Log | `nexus-cli sandbox logs` 输出的调度轨迹。 |

## 17. 认证与会话

| 术语 | 英文 | 说明 |
|---|---|---|
| 开发模式 | Development Mode | 默认认证模式；使用 `config/default_config.yaml` 中 `nexus-ai.auth.user/password`（默认 `admin` / `nexus`）。 |
| SSO 模式 | SSO Mode | 通过 `sso.enabled=True` 启用；使用 SAML 2.0 与外部 IdP 对接。 |
| SAML 2.0 | SAML 2.0 | 单点登录协议；依赖 `python3-saml`。 |
| idp_metadata_url | idp_metadata_url | IdP 的 SAML Metadata URL。 |
| sp_entity_id | sp_entity_id | 服务提供方（Nexus-AI）Entity ID。 |
| sp_acs_url | sp_acs_url | 断言消费端点，形如 `https://&lt;domain&gt;/api/v2/auth/sso/acs`。 |
| frontend_url | frontend_url | SSO 流程回跳的前端域名。 |
| JWT | JWT | API v2 内部会话令牌格式。 |
| Session | Session | Agent 对话上下文；由 `S3SessionManager` 从 S3 载入并回写。 |
| Message | Message | Aurora `messages` 表中的单条对话记录。 |

## 18. 多模态

| 术语 | 英文 | 说明 |
|---|---|---|
| Multimodal Parser | Multimodal Parser | 处理对话中上传的图片、Excel、Word、PDF 的解析模块。 |
| multimodal_parser.aws.s3_bucket | s3_bucket | 多模态文件存储桶；配置在 `nexus-ai.multimodal_parser.aws`。 |
| multimodal_parser.aws.s3_prefix | s3_prefix | S3 对象键前缀，默认 `multimodal-content/`。 |
| multimodal_parser.aws.bedrock_region | bedrock_region | 多模态解析使用的 Bedrock 区域，例如 `us-west-2`。 |

## 19. 观测与追踪

| 术语 | 英文 | 说明 |
|---|---|---|
| OpenTelemetry | OpenTelemetry (OTEL) | 分布式追踪与指标标准；API 服务内置探针。 |
| setup_telemetry | setup_telemetry | `nexus_utils/telemetry_helper.setup_telemetry`；进程启动时初始化追踪。 |
| Jaeger | Jaeger | 可选的追踪后端；通过 `docker run jaegertracing/all-in-one` 启动，UI 默认 `http://localhost:16686`。 |
| OTEL Ports | OTEL Ports | Jaeger 暴露端口：`16686`（UI）、`4317`（gRPC）、`4318`（HTTP）。 |
| Stage Log Dir | STAGE_LOG_DIR | 历史遗留目录 `logs/stages/`；当前 `_STAGE_LOGGING_ENABLED=False`，已不写入。 |

## 20. nexus-cli 命令与端口

| 术语 | 英文 | 说明 |
|---|---|---|
| nexus-cli | nexus-cli | 平台统一命令行工具；可执行文件位于仓库根目录 `./nexus-cli`。 |
| nexus-cli init | nexus-cli init | 初始化基础设施：创建 DynamoDB 表、SQS 队列、S3 桶。 |
| nexus-cli service start | nexus-cli service start | 启动服务；支持 `--api`、`--worker`、`--web`、`--mcp`、`--otel`、`--dev` 标志。 |
| nexus-cli service stop / status / logs / restart | service stop / status / logs / restart | 停止、查看状态、看日志（`-f` 跟随）、重启。 |
| nexus-cli deploy up / list / status / down | deploy up / list / status / down | 基于 CloudFormation 的云端部署生命周期管理。 |
| nexus-cli sandbox overview / list / nodes / launch / terminate / rebuild-rootfs / logs | sandbox subcommands | 沙箱资源与镜像管理子命令。 |
| Web 端口 | Web Port | 默认 `3000`。 |
| API 端口 | API Port | 默认 `8000`；可通过 `API_PORT` 覆盖。 |
| Bridge 端口 | Bridge Port | 默认 `8001`。 |
| MCP 端口 | MCP Port | 默认 `9000`。 |

## 21. 协议与传输

| 术语 | 英文 | 说明 |
|---|---|---|
| HTTP/REST | HTTP/REST | Web → API 的主要调用协议。 |
| SSE | Server-Sent Events | 流式下行协议；Sessions Router 通过 SSE 推送 Agent 事件。 |
| WebSocket | WebSocket | Gateway 支持的双向流协议。 |
| SSH-like | SSH-like | Bridge 对远端服务器的交互协议；非原生 SSH 协议但语义等价。 |

## 22. 代码层级与目录

| 术语 | 英文 | 说明 |
|---|---|---|
| api/v2/routers | Routers | API 的 HTTP 路由层；定义 30+ 端点。 |
| api/v2/services | Services | API 的业务服务层；28+ 服务，供 Routers 调用。 |
| api/v2/database | Database | API 的持久化层；DynamoDB、Aurora、Valkey 客户端封装。 |
| agents/system_agents | System Agents | 系统 Agent 实现目录，含 `magician.py`、`agent_build_workflow`。 |
| agents/template_agents | Template Agents | 模板 Agent 实现目录。 |
| agents/generated_agents | Generated Agents | 构建工作流生成的 Agent 输出目录。 |
| prompts/ | Prompts Directory | 所有提示词 YAML 的根目录；被 `PromptManager` 递归扫描。 |
| tools/ | Tools Directory | 工具库根目录；按 `system_tools` / `template_tools` / `generated_tools` 分类。 |
| config/default_config.yaml | default_config.yaml | 主配置文件；优先级最低，环境变量覆盖之。 |
| config/service_config.yaml | service_config.yaml | 运行时参数（workers、线程池、超时）。 |
| config/workflows.yaml | workflows.yaml | 所有工作流定义（agent_build、agent_update、tool_build、skill_build、magician）。 |
| config/mcp/ | MCP Configs | MCP 客户端配置目录，含 `system_mcp_server.json`、`public_mcp_server.json`。 |
| BYPASS_TOOL_CONSENT | BYPASS_TOOL_CONSENT | `agent_factory.py` 在进程启动时设为 `"true"` 的环境变量；跳过交互式工具执行确认。 |
| NEXUS_API_WORKERS | NEXUS_API_WORKERS | API Uvicorn worker 数量的覆盖环境变量。 |
| API_PORT | API_PORT | 覆盖 API 端口的环境变量。 |

## 23. 缩写速查

| 缩写 | 全称 | 上下文 |
|---|---|---|
| SSE | Server-Sent Events | 流式下行 |
| SSO | Single Sign-On | SAML 2.0 认证 |
| SaaS | — | — |
| JWT | JSON Web Token | API 会话 |
| YAML | YAML Ain't Markup Language | 提示词与配置文件格式 |
| MCP | Model Context Protocol | 工具调用协议 |
| IAM | Identity and Access Management | AWS 权限 |
| VPC | Virtual Private Cloud | AWS 网络 |
| ALB | Application Load Balancer | AWS 七层 LB |
| CDN | Content Delivery Network | CloudFront |
| CRUD | Create / Read / Update / Delete | DDB 操作模式 |
| DDB | DynamoDB | KV 主存 |
| SQS | Simple Queue Service | 异步任务队列 |
| S3 | Simple Storage Service | 对象存储 |
| IaC | Infrastructure as Code | CloudFormation / Terraform |
| OTEL | OpenTelemetry | 可观测性 |
| VMM | Virtual Machine Monitor | Firecracker |
| microVM | Micro Virtual Machine | Sandbox 隔离 |
| RDS | Relational Database Service | Aurora 所属服务族 |
| KVM | Kernel-based Virtual Machine | Sandbox 节点必需硬件虚拟化 |
| CORS | Cross-Origin Resource Sharing | S3 Bucket Policy |
| SDK | Software Development Kit | boto3 / AWS SDK |

## 相关参考

- 命令行：参见 [`cli-commands`](./cli-commands.md)
- 配置项：参见 [`config-options`](./config-options.md)
- 环境变量：参见 [`environment-variables`](./environment-variables.md)
- API 端点：参见 [`api-endpoints`](./api-endpoints.md)
- 部署参数：参见 [`deploy-params`](./deploy-params.md)
- IAM 权限：参见 [`iam-policies`](./iam-policies.md)
- 模型目录：参见 [`model-catalog`](./model-catalog.md)
