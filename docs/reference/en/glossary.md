---
title: Glossary
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

# Glossary

This glossary lists every key term, component name, workflow name, configuration key, AWS service, and protocol acronym that appears in the Nexus-AI documentation. Terms are grouped by topic and sorted alphabetically within each group. The "Name" column stays identical to source code, CLI flags, and YAML keys; the "Description" column gives a precise, single-source definition.

::: tip How to look things up
Use your browser's `Ctrl + F` / `⌘ + F` to search by term. All "See also" links point either to another section in this document or to a dedicated page elsewhere in the Reference chapter.
:::

## 1. Platform & Core Concepts

| Term | Name | Description |
|---|---|---|
| Nexus-AI | Nexus-AI | Open-source AI Agent development platform; generates complete Agent systems from natural-language descriptions. Built on AWS Bedrock and the Strands Agents framework. |
| Agent | Agent | Executable unit composed of a system prompt, tool set, and model configuration; maps to a `Strands` framework `Agent` instance in Nexus-AI. |
| Agent Build Agent | Agent Build Agent | Meta-system in which 8 specialized agents collaborate to produce an Agent end-to-end: requirements analysis → architecture design → code generation. |
| Multi-Agent Collaboration | Multi-Agent Collaboration | Pattern where multiple agents work together as a single Agent, a Graph, or a Swarm; driven by workflows such as `agent_build`. |
| Natural Language Build | Natural Language Build | Build mode in which a user supplies requirements in natural language and the platform produces Agent code, tools, and prompts. |
| Playbook | Playbook | Umbrella term for the Nexus-AI documentation site and operating guide — the document you are reading. |

## 2. Agent Categories

| Term | Name | Description |
|---|---|---|
| System Agent | System Agent | Built-in meta Agent that drives build / update / tool workflows; prompts live under `prompts/system_agents_prompts/`. |
| Template Agent | Template Agent | Officially maintained, directly reusable starting-point Agent; prompts live under `prompts/template_prompts/`. |
| Generated Agent | Generated Agent | Business Agent produced by the Agent Build Workflow; prompts live under `prompts/generated_agents_prompts/`. |
| Magician | Magician | Intent-router Agent that picks between single-agent, Graph, or Swarm orchestration and constructs the corresponding instance. |
| Requirements Analyst | Requirements Analyst | System Agent for stage 1 of the Agent Build Workflow; turns natural-language requirements into structured specs. |
| Architect | Architect | System Agent that designs multi-agent topology, data flow, and role boundaries. |
| Agent Designer | Agent Designer | System Agent that defines each target Agent's role, capabilities, and I/O contract. |
| Prompt Engineer | Prompt Engineer | System Agent that produces the platform-format YAML prompt with examples and constraints. |
| Tool Developer | Tool Developer | System Agent that emits `@tool`-decorated functions and registers them in the tool catalog. |
| Code Developer | Code Developer | System Agent that emits the final Agent code, entry script, and dependency declarations. |
| Test Engineer | Test Engineer | System Agent that generates and runs validation test cases. |

## 3. Workflows & Stages

| Term | Name | Description |
|---|---|---|
| Workflow | Workflow | Long-running orchestration of multiple stages, driven by SQS; defined in `config/workflows.yaml`. |
| agent_build | agent_build | V2 Agent build workflow with 8 stages and fork/join for parallel Agent design. |
| agent_update | agent_update | V2 Agent update workflow with 5 stages; supports `skip_stages` to skip work that does not need redoing. |
| tool_build | tool_build | V2 tool build workflow with 5 stages. |
| skill_build | skill_build | V2 Skill build workflow with 5 stages. |
| magician | magician | Single-stage intent-router workflow; delegates work to the Magician Agent. |
| Stage | Stage | Smallest execution unit of a workflow; one SQS message triggers one stage, which then routes to the next via SQS. |
| Single-Stage Execution Model | Single-Stage Execution Model | Convention that the Worker processes exactly one Stage per message and routes onward via SQS — ensures restart safety and horizontal scaling. |
| Fork/Join | Fork / Join | Workflow pattern that fans out parallel stages and then merges their outputs as input to a downstream stage. |
| skip_stages | skip_stages | Input field for `agent_update`; list of stages to skip. |
| Input Assembly | Input Assembly | Worker step before executing a stage: read prerequisite results from DynamoDB and assemble the stage input. |
| Output Parsing | Output Parsing | Mechanism that validates stage output as JSON and retries on failure. |

## 4. Orchestration Modes

| Term | Name | Description |
|---|---|---|
| Orchestration Type | orchestration_type | Field on `AgentOrchestrationResult`; one of `agent`, `graph`, `swarm`. |
| Single Agent | Single Agent | Simplest mode — one Agent handles all input; maps to `orchestration_type=agent`. |
| Graph | Graph | Directed-graph orchestration of nodes (agents) and edges (dependencies); built via `GraphBuilder`. |
| Swarm | Swarm | Autonomous multi-agent collaboration with role, priority, and communication-pattern configuration. |
| GraphBuilder | GraphBuilder | `strands.multiagent.GraphBuilder`; used via `add_node`, `add_edge`, and `build()` to produce a Graph. |
| Node | Node | A single Agent instance inside a Graph, carrying a `node_id` (or `id`) and its agent info. |
| Edge | Edge | Dependency between two Graph nodes; new format uses `from`/`to`, legacy format uses `source`/`target`. |
| depends_on | depends_on | Node field used to infer edges automatically when `edges` is absent. |
| Communication Pattern | communication_pattern | Swarm config field that defines how agents exchange messages. |
| Role | role | Each Swarm agent's duty label. |
| Priority | priority | Swarm agent execution priority; defaults to 1. |
| Alternative Solutions | alternative_solutions | List of fallback/comparison orchestrations on `AgentOrchestrationResult`. |

## 5. Core Services

| Term | Name | Description |
|---|---|---|
| API Backend | API Backend | FastAPI + Uvicorn REST API service, entry at `api/v2/main.py`; default port `8000`, exposes 30+ routers, 28+ services, JWT auth, SSE streaming, and OTEL instrumentation. |
| Worker | Worker | SQS message consumer, entry at `worker/main.py`; runs single stages of build/deploy workflows. |
| Web Frontend | Web Frontend | Next.js 14 App Router + React 18 + TypeScript + Tailwind CSS; default port `3000`, state via TanStack Query. |
| Gateway | Gateway | Streaming proxy with reconnection and a Valkey buffer; supports WebSocket, entry at `nexus_utils/gateway/__main__.py`. |
| Bridge | Bridge | Remote-server connection manager for SSH-like operations, with multi-connection, parallel execution, and command-level permissions; entry at `nexus_utils/bridge/`; default port `8001`. |
| MCP Server | MCP Server | FastMCP 3.x endpoint on default port `9000`; exposes platform Agents as MCP Tools for IDE consumption. |
| Event Scheduler | Event Scheduler | Optional cron-like scheduled task executor at `nexus_utils/event_scheduler/`. |
| OTEL Collector | OTEL Collector | Optional OpenTelemetry Collector; start with `./nexus-cli service start --otel`. |

## 6. Key Subsystems

| Term | Name | Description |
|---|---|---|
| Workflow Engine v2 | Workflow Engine v2 | `nexus_utils/workflow/engine_v2.py`; implements the SQS-driven single-stage model, fork/join, input assembly, output parsing, and retries. |
| Agent Factory | Agent Factory | `nexus_utils/agent_factory.py`; factory that creates Agents from YAML prompt templates via `create_agent_from_prompt_template()`. |
| Prompts Manager | Prompts Manager | `nexus_utils/prompts_manager.py`; singleton YAML prompt loader and version manager. |
| Database Layer | Database Layer | `api/v2/database/dynamodb.py`; singleton DynamoDB client with connection pooling and exponential-backoff retries. |
| S3SessionManager | S3SessionManager | Session manager that persists conversation context to S3; loads before and writes after each Agent turn. |
| Stream Relay | Stream Relay | Valkey Stream-based event buffer that decouples Agent execution from SSE delivery and supports resume-from-offset. |
| Asset Cache Manager | Asset Cache Manager | `nexus_utils/asset_cache`; pulls assets of Generated Agents registered in DDB from S3 to the local cache. |
| S3-First | S3-First | Prompt Manager's lazy-load policy: on cache miss, fetch from DDB+S3 and register in memory. |
| Stage Logging | Stage Logging | Legacy file-level stage log at `logs/stages/`; currently `_STAGE_LOGGING_ENABLED=False` — disk logging is superseded by the Aurora `messages` table. |

## 7. Prompts & YAML Structure

| Term | Name | Description |
|---|---|---|
| Prompt Template | Prompt Template | A YAML file under `prompts/` that defines an Agent's structured prompt, environments, versions, tools, and metadata. |
| PromptAgent | PromptAgent | Top-level YAML object; contains `agent_name`, `description`, `category`, `environments`, `versions`. |
| PromptVersion | PromptVersion | A single version record; holds `system_prompt`, `user_prompt_template`, `tools`, `constraints`, `examples`, `metadata`, etc. |
| Version | version | Version identifier of a PromptVersion; accepts strings like `"1.0.0"` or the special value `"latest"`. |
| latest | latest | Convention keyword for the latest version; first returns a version literally named `latest`, otherwise picks the max by dotted-number sort. |
| Status | status | Status field of a PromptVersion; defaults to `stable`. |
| EnvironmentConfig | EnvironmentConfig | Field group: `temperature`, `max_tokens`, `streaming`, `debug_mode`; defined per environment name such as `production`. |
| production | production | Default environment name; `get_environment_config()` falls back to it. |
| streaming | streaming | EnvironmentConfig field; toggles model streaming output. |
| temperature | temperature | EnvironmentConfig field; model temperature. Agent Factory falls back to `0.8` if absent. |
| max_tokens | max_tokens | EnvironmentConfig field; max generation tokens per call. |
| Metadata | Metadata | YAML `metadata` block describing tags, dependencies, model support, compatibility, performance metrics, etc. |
| tags | tags | `Metadata.tags`; free-text label list for the Agent. |
| supported_models | supported_models | `Metadata` field; models on which the Agent is known to run. |
| lib_dependencies | lib_dependencies | `Metadata` field; Python packages required to run the Agent. |
| tools_dependencies | tools_dependencies | `Metadata` field; tool-path list the Agent consumes. |
| mcp_dependencies | mcp_dependencies | `Metadata` field; list of MCP servers the Agent depends on. Null parses to `[]`; a bare string is auto-wrapped into a list. |
| model_provider | model_provider | `Metadata` field; model provider — defaults to `bedrock`, also accepts `ollama`, `openai`, `anthropic`, `litellm`, `mistral`, `gemini`, `llamaapi`. |
| model_config | model_config | `Metadata` field; provider-specific constructor kwargs; merges with environment config, with provider kwargs taking precedence. |
| swarm_config | swarm_config | `Metadata` field; Swarm multi-agent collaboration config block. |
| conversation_manager_config | ConversationManagerConfig | `Metadata.conversation_manager`; conversation manager policy. |
| retry_strategy | retry_strategy | `Metadata` field; overrides the global `strands.retry_strategy`. |
| performance_metrics | PerformanceMetrics | `Metadata` field; holds three optional fields: `accuracy`, `response_time`, `user_satisfaction`. |
| compatibility | Compatibility | `Metadata` field; holds `min_strands_version` and `supported_models`. |
| additional_request_fields | additional_request_fields | `Metadata` field; extra fields forwarded to the model API (e.g. Bedrock `anthropic_beta`). |
| constraints | constraints | `PromptVersion.constraints`; list of hard constraints to obey at runtime. |
| examples | examples | `PromptVersion.examples`; list of `user`/`assistant` conversation examples. |
| context_window | context_window | `PromptVersion.context_window`; model context window in tokens. |
| user_prompt_template | user_prompt_template | `PromptVersion.user_prompt_template`; template string on the user-input side. |

## 8. Conversation Manager

| Term | Name | Description |
|---|---|---|
| ConversationManagerConfig | ConversationManagerConfig | Parsed class for YAML field `metadata.conversation_manager`. |
| enabled | enabled | Toggle; `None` means inherit global config, `true`/`false` explicitly overrides. |
| type | type | Manager type: `sliding_window`, `summarizing`, or `null`. |
| window_size | window_size | Max recent-message count retained by `sliding_window`. |
| should_truncate_results | should_truncate_results | Whether to truncate tool results. |
| summary_ratio | summary_ratio | Summary ratio for `summarizing` strategy. |
| preserve_recent_messages | preserve_recent_messages | Count of recent messages kept un-summarized by `summarizing`. |
| use_custom_agent | use_custom_agent | Whether to use a custom Agent for summarization. |
| custom_agent_model_id | custom_agent_model_id | Model ID for the custom summarization Agent. |
| custom_agent_prompt_path | custom_agent_prompt_path | YAML prompt path for the custom summarization Agent. |

## 9. Models & Bedrock

| Term | Name | Description |
|---|---|---|
| AWS Bedrock | AWS Bedrock | Managed foundation-model inference service on AWS; required dependency of Nexus-AI. |
| BedrockModel | BedrockModel | `strands.models.BedrockModel`; default model client used by Agent Factory. |
| model_id | model_id | `config/default_config.yaml` → `bedrock.model_id`; default primary model ID. |
| lite_model_id | lite_model_id | `bedrock.lite_model_id`; lightweight model ID (Haiku family). |
| pro_model_id | pro_model_id | `bedrock.pro_model_id`; professional model ID (Opus family). |
| Claude Sonnet | Claude Sonnet | Anthropic general-purpose model family; default `us.anthropic.claude-sonnet-4-5-20250929-v1:0`. |
| Claude Opus | Claude Opus | Anthropic professional model family; default `us.anthropic.claude-opus-4-5-20251101-v1:0`. |
| Claude Haiku | Claude Haiku | Anthropic lightweight model family; default `us.anthropic.claude-haiku-4-5-20251001-v1:0`. |
| Nova | Amazon Nova | Amazon foundation-model family (Pro / Lite / Micro); also supports prompt caching alongside Claude. |
| Prompt Caching | Prompt Caching | Bedrock prompt-cache feature: first write costs 1.25×; hits within 5 minutes cost 0.1× (90% discount). |
| cache_prompt | cache_prompt | `BedrockModel` kwarg that enables system-prompt caching; value `"default"`. |
| cache_tools | cache_tools | `BedrockModel` kwarg that enables tool-definition caching; value `"default"`. |
| bedrock.prompt_caching | bedrock.prompt_caching | `default_config.yaml` key; contains `enabled`, `cache_system_prompt`, `cache_tools`. |
| connect_config | bedrock.connect_config | Bedrock connection parameters (`retries.max_attempts`, `retries.mode`, `connect_timeout`, `read_timeout`). |
| RefreshableCredentials | RefreshableCredentials | boto3 credentials object used inside Sandbox VMs to refresh credentials on schedule. |
| IAM role credential chain | IAM role credential chain | Credential resolution chain used on the primary EC2 instance (instance metadata, env vars, config files). |

## 10. Multi-Provider Models

| Term | Name | Description |
|---|---|---|
| MODEL_PROVIDER_REGISTRY | MODEL_PROVIDER_REGISTRY | Mapping in `agent_factory.py`: provider → (`module path`, `class name`, `pip install target`). |
| bedrock | bedrock | Default provider; uses `get_bedrock_model()` and is not part of `MODEL_PROVIDER_REGISTRY`. |
| ollama | ollama | `strands.models.ollama.OllamaModel`; requires `pip install 'strands-agents[ollama]'`. |
| openai | openai | `strands.models.openai.OpenAIModel`; requires `strands-agents[openai]`. |
| anthropic | anthropic | `strands.models.anthropic.AnthropicModel`; requires `strands-agents[anthropic]`. |
| litellm | litellm | `strands.models.litellm.LiteLLMModel`; requires `strands-agents[litellm]`. |
| llamaapi | llamaapi | `strands.models.llamaapi.LlamaAPIModel`; requires `strands-agents[llamaapi]`. |
| mistral | mistral | `strands.models.mistral.MistralModel`; requires `strands-agents[mistral]`. |
| gemini | gemini | `strands.models.gemini.GeminiModel`; requires `strands-agents[gemini]`. |
| create_model_for_provider | create_model_for_provider | Generic factory; dynamically imports the model class and merges `max_tokens`, `temperature`, and `model_config` kwargs. |

## 11. Tools

| Term | Name | Description |
|---|---|---|
| Tool | Tool | A function/capability an Agent can call; surfaced via the `@tool` decorator or a module. |
| @tool decorator | @tool decorator | Decorator from the `strands` framework; turns a function into a `DecoratedFunctionTool` with a `tool_spec`. |
| DecoratedFunctionTool | DecoratedFunctionTool | Decorated tool object; callable with a `tool_spec` attribute. |
| Builtin Tools | Builtin Tools | Official tools under `strands_tools.*`, e.g. `calculator`, `browser`. |
| System Tools | System Tools | Platform-shipped tools under `tools/system_tools/`, e.g. `agent_build_workflow/project_manager`. |
| Template Tools | Template Tools | Copy-and-modify example tools under `tools/template_tools/`, e.g. `common/demo/weather_forecast`. |
| Generated Tools | Generated Tools | Business tools produced by the build workflow under `tools/generated_tools/`. |
| Tool Path | Tool Path | Reference format used in Agent config, e.g. `generated_tools/&lt;dir&gt;/&lt;script&gt;/&lt;function&gt;`. |
| Tool Template Provider | Tool Template Provider | `tools.system_tools.agent_build_workflow.tool_template_provider`; exposes `get_builtin_tools`, `list_all_tools`, `search_tools_by_name`. |
| get_tool_by_path | get_tool_by_path | Imports a tool by its full path; supports prefixes `strands_tools/`, `system_tools/`, `template_tools/`, `generated_tools/`. |
| get_tool_by_name | get_tool_by_name | Looks up a tool by name in the builtin and system mappings, falling back to a search. |
| S3 Tool Sync | S3 Tool Sync | Mechanism that pulls a missing `generated_tools` file from the S3 key `tools/&lt;dir&gt;/&lt;script&gt;.py` (`_sync_tool_from_s3`). |
| AgentCoreBrowser | AgentCoreBrowser | Special instantiation for `strands_tools.browser`; constructed with the current boto3 region (default `us-west-2`). |

## 12. Skills

| Term | Name | Description |
|---|---|---|
| Skill | Skill | Packaged set of reusable capabilities produced by the `skill_build` workflow; stored in S3 and mirrored to DDB. |
| skill_activator | skill_activator | `tools.system_tools.skill_activator`; lets an Agent activate a named Skill at runtime. |
| skill_build | skill_build | 5-stage V2 workflow that builds a Skill. |

## 13. MCP (Model Context Protocol)

| Term | Name | Description |
|---|---|---|
| MCP | Model Context Protocol | Cross-process tool-invocation protocol; Nexus-AI acts as both MCP Server and MCP Client. |
| FastMCP | FastMCP | Python MCP Server implementation (3.x); Nexus-AI uses it to expose Agents as tools. |
| MCP Server | MCP Server | Built-in Nexus-AI service that auto-registers every Agent with `status=running` as an MCP Tool; entry at `nexus_utils/mcp/mcp_server/__main__.py`. |
| MCP Client | MCP Client | The side that connects to an MCP Server; Kiro, Claude Code, and Cursor are all MCP Clients. |
| Bearer Token | Bearer Token | MCP Server auth credential; passed via the `Authorization: Bearer &lt;token&gt;` header. |
| NEXUS_MCP_TOKEN | NEXUS_MCP_TOKEN | Environment variable that pins a fixed MCP Bearer Token. |
| .pids/mcp_token | .pids/mcp_token | Token file written when the MCP Server starts; used for external reads. |
| Streamable HTTP | Streamable HTTP | Transport used by the MCP Server; endpoint at `http://localhost:9000/mcp`. |
| system_mcp_server.json | system_mcp_server.json | System-preset MCP server manifest (e.g. AWS MCP) under `config/mcp/`. |
| public_mcp_server.json | public_mcp_server.json | User-extensible custom MCP server manifest under `config/mcp/`. |

## 14. AWS Infrastructure

| Term | Name | Description |
|---|---|---|
| Aurora PostgreSQL Serverless v2 | Aurora PostgreSQL Serverless v2 | Relational primary store; holds 12 tables — projects, agents, sessions, messages, and more. |
| DynamoDB | DynamoDB | KV primary store; holds 18 tables — tools, configs, event schedules, and more. |
| ElastiCache Valkey Serverless | ElastiCache Valkey Serverless | Cache tier; provides aggregate stats, hot data, and the Stream event buffer. |
| Valkey Stream | Valkey Stream | Stream data type used by Stream Relay; supports resume-from-offset. |
| SQS | Amazon SQS | Async task queues for build, deploy, and notification. |
| S3 | Amazon S3 | Object store; holds Agent artifacts, session files, multimodal content, and Skills. |
| S3 Vectors | S3 Vectors | Vector store; `CreateVectorBucket`, `CreateIndex`, `Query` for vector search. |
| CloudFormation | AWS CloudFormation | IaC service; `nexus-cli deploy up` manages Stacks under the hood. |
| VPC | VPC | Virtual private network; CloudFormation template defaults to CIDR `10.0.0.0/16`. |
| ALB | Application Load Balancer | L7 load balancer; hosts API/Web target groups. |
| CloudFront | CloudFront | CDN distribution; accelerates Web assets and API traffic. |
| NAT Gateway | NAT Gateway | VPC egress gateway; provisioned by the CloudFormation template. |
| SSM | AWS Systems Manager | Used for `GetParameter` to resolve AMI IDs. |
| EC2 | Amazon EC2 | Instance runtime; default instance type `c8i.2xlarge`. |
| IAM Instance Profile | IAM Instance Profile | Attachment vehicle for EC2 IAM roles; default `admin-for-ec2`. |
| IAM Identity Center | IAM Identity Center | Optional SAML 2.0 IdP; connects to Nexus-AI SSO. |
| ECR | Amazon ECR | Container image registry; read during AgentCore deployments. |
| AgentCore | Bedrock AgentCore | AWS Bedrock AgentCore managed Agent runtime; Nexus-AI supports CI/CD deploys to it. |

## 15. Deployment Environments (nexus-cli deploy)

| Term | Name | Description |
|---|---|---|
| ENV_PREFIX | ENV_PREFIX | Required environment prefix; used to name every AWS resource (Stack, VPC, Aurora, S3, DDB). |
| --github-token | --github-token | GitHub Personal Access Token; used by EC2 at boot to pull code. |
| --db-password | --db-password | Aurora PostgreSQL password; required. |
| --branch | --branch | Git branch, default `main`. |
| --instance-type | --instance-type | EC2 instance type, default `c8i.2xlarge`. |
| --key-name | --key-name | SSH Key Pair name, default `Og_Normal`. |
| --iam-instance-profile | --iam-instance-profile | EC2 instance profile, default `admin-for-ec2`. |
| --volume-size | --volume-size | EC2 root volume size (GB), default `150`. |
| --vpc-cidr | --vpc-cidr | VPC CIDR block, default `10.0.0.0/16`. |
| --region | --region | AWS region, default `us-west-2`. |
| --user / --password | --user / --password | Platform login credentials, defaults `admin` / `nexus`. |
| --enable-sso | --enable-sso | Enable SAML 2.0 SSO; integrates with IAM Identity Center or another IdP. |
| --allowed-email-domains | --allowed-email-domains | Whitelist of email domains allowed to log in under SSO. |
| --enable-sandbox | --enable-sandbox | Enable the Sandbox runtime. |
| --sandbox-instance-type | --sandbox-instance-type | Sandbox node instance type, default `c8i.xlarge`; must support KVM. |
| --sandbox-pool-size | --sandbox-pool-size | Number of Sandbox nodes, default `1`. |
| --sandbox-default-runtime | --sandbox-default-runtime | Default runtime mode: `local` or `ec2`. |
| --sandbox-runtimes | --sandbox-runtimes | Allowed runtime modes, default `local,ec2`. |
| --sandbox-prewarm-vms | --sandbox-prewarm-vms | Pre-warmed VM count per node, default `1`. |
| --clean-data | --clean-data | On teardown, cascade-clean S3 / DDB / SQS data. |

## 16. Sandbox Runtime

| Term | Name | Description |
|---|---|---|
| Sandbox | Sandbox | Execution environment that gives each Agent session a Firecracker microVM-level isolation boundary. |
| Firecracker microVM | Firecracker microVM | AWS open-source lightweight VMM; Sandbox starts isolated runtimes on top of it. |
| Sandbox Node | Sandbox Node | Compute node (EC2 instance) hosting several VMs; managed with `nexus-cli sandbox nodes`. |
| Sandbox VM | Sandbox VM | microVM running a single Agent task; inspect via `nexus-cli sandbox list`. |
| local runtime | local | Runtime mode that boots the VM on the caller's host. |
| ec2 runtime | ec2 | Runtime mode that schedules the VM onto the Sandbox node pool; production default. |
| Prewarm VMs | Prewarm VMs | Idle VM count kept running per node to reduce cold starts. |
| Rootfs | Rootfs | Sandbox VM root filesystem image; rebuild with `nexus-cli sandbox rebuild-rootfs`. |
| vm_credentials | vm_credentials | `nexus_utils/sandbox/vm_credentials`; exposes `get_vm_boto_session`, injecting RefreshableCredentials into VMs. |
| Sandbox Scheduler Log | Sandbox Scheduler Log | Scheduling trace printed by `nexus-cli sandbox logs`. |

## 17. Authentication & Sessions

| Term | Name | Description |
|---|---|---|
| Development Mode | Development Mode | Default auth mode; uses `nexus-ai.auth.user/password` from `config/default_config.yaml` (defaults `admin` / `nexus`). |
| SSO Mode | SSO Mode | Enabled via `sso.enabled=True`; integrates with an external IdP over SAML 2.0. |
| SAML 2.0 | SAML 2.0 | Single sign-on protocol; requires `python3-saml`. |
| idp_metadata_url | idp_metadata_url | IdP SAML metadata URL. |
| sp_entity_id | sp_entity_id | Service-provider (Nexus-AI) entity ID. |
| sp_acs_url | sp_acs_url | Assertion consumer endpoint, shaped like `https://&lt;domain&gt;/api/v2/auth/sso/acs`. |
| frontend_url | frontend_url | Frontend domain that SSO flow redirects back to. |
| JWT | JWT | Internal session token format for API v2. |
| Session | Session | Agent conversation context; loaded from and written back to S3 by `S3SessionManager`. |
| Message | Message | Single conversation row in the Aurora `messages` table. |

## 18. Multimodal

| Term | Name | Description |
|---|---|---|
| Multimodal Parser | Multimodal Parser | Module that parses uploaded images, Excel, Word, and PDF files inside conversations. |
| multimodal_parser.aws.s3_bucket | s3_bucket | Multimodal file storage bucket; configured under `nexus-ai.multimodal_parser.aws`. |
| multimodal_parser.aws.s3_prefix | s3_prefix | S3 key prefix; default `multimodal-content/`. |
| multimodal_parser.aws.bedrock_region | bedrock_region | Bedrock region used for multimodal parsing, e.g. `us-west-2`. |

## 19. Observability & Tracing

| Term | Name | Description |
|---|---|---|
| OpenTelemetry | OpenTelemetry (OTEL) | Standard for distributed traces and metrics; instrumentation is built into the API service. |
| setup_telemetry | setup_telemetry | `nexus_utils/telemetry_helper.setup_telemetry`; initializes tracing at process start. |
| Jaeger | Jaeger | Optional trace backend; run `docker run jaegertracing/all-in-one`; UI at `http://localhost:16686`. |
| OTEL Ports | OTEL Ports | Jaeger-exposed ports: `16686` (UI), `4317` (gRPC), `4318` (HTTP). |
| Stage Log Dir | STAGE_LOG_DIR | Legacy directory `logs/stages/`; with `_STAGE_LOGGING_ENABLED=False` nothing is written today. |

## 20. nexus-cli Commands & Ports

| Term | Name | Description |
|---|---|---|
| nexus-cli | nexus-cli | Platform-wide command-line tool; executable at the repo root as `./nexus-cli`. |
| nexus-cli init | nexus-cli init | Bootstrap infrastructure: create DynamoDB tables, SQS queues, S3 buckets. |
| nexus-cli service start | nexus-cli service start | Start services; flags include `--api`, `--worker`, `--web`, `--mcp`, `--otel`, `--dev`. |
| nexus-cli service stop / status / logs / restart | service stop / status / logs / restart | Stop, check status, tail logs (`-f` to follow), and restart. |
| nexus-cli deploy up / list / status / down | deploy up / list / status / down | CloudFormation-backed cloud deployment lifecycle. |
| nexus-cli sandbox overview / list / nodes / launch / terminate / rebuild-rootfs / logs | sandbox subcommands | Sandbox resource and image management subcommands. |
| Web Port | Web Port | Default `3000`. |
| API Port | API Port | Default `8000`; override with `API_PORT`. |
| Bridge Port | Bridge Port | Default `8001`. |
| MCP Port | MCP Port | Default `9000`. |

## 21. Protocols & Transport

| Term | Name | Description |
|---|---|---|
| HTTP/REST | HTTP/REST | Primary protocol between Web and API. |
| SSE | Server-Sent Events | Streaming downlink protocol; Sessions Router pushes Agent events over SSE. |
| WebSocket | WebSocket | Bidirectional streaming protocol supported by Gateway. |
| SSH-like | SSH-like | Bridge's protocol against remote servers — not native SSH but semantically equivalent. |

## 22. Code Layers & Directories

| Term | Name | Description |
|---|---|---|
| api/v2/routers | Routers | HTTP router layer of the API; defines 30+ endpoints. |
| api/v2/services | Services | Business-logic layer of the API; 28+ services consumed by Routers. |
| api/v2/database | Database | Persistence layer of the API; wraps DynamoDB, Aurora, and Valkey clients. |
| agents/system_agents | System Agents | Implementation directory for system Agents — includes `magician.py` and `agent_build_workflow`. |
| agents/template_agents | Template Agents | Implementation directory for template Agents. |
| agents/generated_agents | Generated Agents | Output directory for Agents produced by the build workflow. |
| prompts/ | Prompts Directory | Root directory scanned recursively by `PromptManager` for prompt YAMLs. |
| tools/ | Tools Directory | Root directory of the tool catalog, partitioned into `system_tools` / `template_tools` / `generated_tools`. |
| config/default_config.yaml | default_config.yaml | Primary config file; lowest precedence — overridden by environment variables. |
| config/service_config.yaml | service_config.yaml | Runtime parameters (workers, thread pools, timeouts). |
| config/workflows.yaml | workflows.yaml | All workflow definitions (`agent_build`, `agent_update`, `tool_build`, `skill_build`, `magician`). |
| config/mcp/ | MCP Configs | MCP client config directory; holds `system_mcp_server.json` and `public_mcp_server.json`. |
| BYPASS_TOOL_CONSENT | BYPASS_TOOL_CONSENT | Environment variable set to `"true"` at process start by `agent_factory.py`; skips interactive tool-execution consent. |
| NEXUS_API_WORKERS | NEXUS_API_WORKERS | Environment variable overriding the API Uvicorn worker count. |
| API_PORT | API_PORT | Environment variable overriding the API port. |

## 23. Acronym Quick Reference

| Acronym | Expansion | Context |
|---|---|---|
| SSE | Server-Sent Events | Streaming downlink |
| SSO | Single Sign-On | SAML 2.0 auth |
| SaaS | — | — |
| JWT | JSON Web Token | API sessions |
| YAML | YAML Ain't Markup Language | Prompts and config files |
| MCP | Model Context Protocol | Tool invocation protocol |
| IAM | Identity and Access Management | AWS permissions |
| VPC | Virtual Private Cloud | AWS networking |
| ALB | Application Load Balancer | AWS L7 LB |
| CDN | Content Delivery Network | CloudFront |
| CRUD | Create / Read / Update / Delete | DDB access pattern |
| DDB | DynamoDB | KV primary store |
| SQS | Simple Queue Service | Async task queue |
| S3 | Simple Storage Service | Object store |
| IaC | Infrastructure as Code | CloudFormation / Terraform |
| OTEL | OpenTelemetry | Observability |
| VMM | Virtual Machine Monitor | Firecracker |
| microVM | Micro Virtual Machine | Sandbox isolation |
| RDS | Relational Database Service | Aurora's service family |
| KVM | Kernel-based Virtual Machine | Hardware virt required for Sandbox nodes |
| CORS | Cross-Origin Resource Sharing | S3 bucket policy |
| SDK | Software Development Kit | boto3 / AWS SDK |

## See Also

- CLI commands: see [`cli-commands`](./cli-commands.md)
- Configuration options: see [`config-options`](./config-options.md)
- Environment variables: see [`environment-variables`](./environment-variables.md)
- API endpoints: see [`api-endpoints`](./api-endpoints.md)
- Deployment parameters: see [`deploy-params`](./deploy-params.md)
- IAM policies: see [`iam-policies`](./iam-policies.md)
- Model catalog: see [`model-catalog`](./model-catalog.md)
