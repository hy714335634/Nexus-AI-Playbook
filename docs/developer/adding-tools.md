---
title: 添加工具
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - api/v2/routers/agent_tools.py
    - nexus_utils/mcp/**
    - nexus_utils/skill/**
    - tools/**
  generated_at: 2026-05-09T00:29:09+00:00
  generated_by: docs-sync v2
---

# 添加工具

## 概述

Nexus-AI 的 "Tool" 是 Strands Agent 在推理循环中可调用的 Python 函数。平台一共识别 **五种工具类型**（`builtin` / `generated` / `system` / `template` / `mcp`）以及一个可选的 **Skill 渐进加载子系统**，统一通过 `api/v2/routers/agent_tools.py` 暴露给前端，通过 `nexus_utils/agent_factory.py` 注册到 Agent。

所有自定义工具都必须满足两点：一是文件中含有被 `@strands.tool` 装饰的函数；二是函数有类型注解与 docstring（Strands 从签名推导 JSON Schema、从 docstring 生成 LLM 可见描述）。本文是写工具、注册工具、调试工具的开发者参考。

入口与主要职责：

| 入口 | 文件 | 职责 |
|------|------|------|
| REST API — Tool | `api/v2/routers/agent_tools.py` | 列表、详情、分类、MCP 管理、测试 |
| REST API — MCP | `nexus_utils/mcp/mcp_client/api.py` | MCP Server CRUD / 导入 / 连接测试 |
| 工具扫描 / 解析 | `api/v2/routers/agent_tools.py:14989`（`_parse_tool_file`） | AST 解析 `@tool` 装饰器 |
| MCP 客户端 | `nexus_utils/mcp/mcp_client/manager.py:13493`（`MCPManager`） | stdio/sse/http 客户端生命周期 |
| MCP 服务端 | `nexus_utils/mcp/mcp_server/server.py:14729`（`create_server`） | 将平台 Agent 暴露为 MCP Tool |
| Skill 管理 | `nexus_utils/skill/manager.py:709`（`SkillManager`） | Skill 本地 + S3 + DDB 生命周期 |
| Skill 运行时 | `nexus_utils/skill/runtime.py:1667`（`SkillRuntime`） | `subprocess` 执行 Skill 脚本 |

## 文件组织（File Layout）

| 路径 | 责任 | 主要依赖 |
|------|------|----------|
| `api/v2/routers/agent_tools.py` | 工具 REST API、AST 扫描、MCP 聚合视图 | `fastapi`, `pydantic`, `ast` |
| `nexus_utils/mcp/__init__.py` | 从 `mcp_client` 重新导出常用接口 | `nexus_utils.mcp.mcp_client` |
| `nexus_utils/mcp/mcp_client/models.py` | `TransportType` 枚举、`MCPServerConfig` 数据类 | `dataclasses`, `enum` |
| `nexus_utils/mcp/mcp_client/parser.py` | 多格式 MCP 配置解析（JSON / 命令行 / URL） | `shlex`, `urllib.parse` |
| `nexus_utils/mcp/mcp_client/client_factory.py` | 根据 `TransportType` 创建 `MCPClient` | `mcp`, `strands.tools.mcp` |
| `nexus_utils/mcp/mcp_client/manager.py` | MCP 服务器配置管理、连接测试、DDB 同步 | `boto3`, `MCPClientFactory` |
| `nexus_utils/mcp/mcp_client/api.py` | `/mcp/servers` REST 路由 | `fastapi`, `mcp_service` |
| `nexus_utils/mcp/mcp_client/exceptions.py` | `MCPManagerError` 等异常类 | — |
| `nexus_utils/mcp/mcp_server/server.py` | FastMCP Server 入口、Bearer Token 中间件 | `fastmcp`, `starlette` |
| `nexus_utils/mcp/mcp_server/agent_tools.py` | 将 Agent 动态注册为 MCP Tool | `nexus_utils.agent_factory` |
| `nexus_utils/mcp/mcp_server/config.py` | MCP Server 端口与 Token 配置 | `os`, `secrets` |
| `nexus_utils/skill/models.py` | Skill 数据模型（`SkillType`、`SkillInfo`、`FileManifest`） | `dataclasses` |
| `nexus_utils/skill/manager.py` | Skill CRUD、导入、分组、执行协调 | `storage`, `importer`, `runtime` |
| `nexus_utils/skill/storage.py` | 本地 + S3 双层存储 | `boto3`, `pathlib` |
| `nexus_utils/skill/runtime.py` | Skill 脚本 / shell 命令执行 | `subprocess` |
| `nexus_utils/skill/importer.py` | 从 GitHub / URL / 本地 / Claude Code 导入 Skill | `httpx`, `yaml`, `git` |
| `tools/system_tools/**` | 平台内置系统工具（MCP Client 外的"一等公民"工具） | `strands` |
| `tools/template_tools/**` | 可复用的参考工具模板 | `strands` |
| `tools/generated_tools/&lt;agent_dir&gt;/**` | Agent 构建流水线生成的自定义工具 | `strands` |

## 核心类型 / 数据结构

### `ToolParameter`（`api/v2/routers/agent_tools.py:14861`）

| 字段 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `name` | `str` | — | 参数名 |
| `type` | `str` | `"Any"` | 由 AST 推导的类型字面量 |
| `description` | `Optional[str]` | `None` | 来自 docstring |
| `required` | `bool` | `True` | 无默认值时为 True |
| `default` | `Optional[Any]` | `None` | 默认值 |

### `ToolInfo`（`api/v2/routers/agent_tools.py:14870`）

| 字段 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `name` | `str` | — | 工具函数名 |
| `type` | `str` | — | `builtin` / `generated` / `system` / `template` / `mcp` |
| `category` | `Optional[str]` | `None` | 分类字符串 |
| `description` | `Optional[str]` | `None` | docstring 第一行 |
| `file_path` | `Optional[str]` | `None` | 源文件绝对路径 |
| `parameters` | `List[ToolParameter]` | `[]` | 解析出的形参 |
| `package` | `Optional[str]` | `None` | 仅内置工具：pip 包名 |
| `enabled` | `bool` | `True` | 是否启用 |
| `mcp_server` | `Optional[str]` | `None` | MCP 工具所属服务器 |
| `return_type` | `Optional[str]` | `None` | 返回值类型字面量 |

### `MCPServerInfo`（`api/v2/routers/agent_tools.py:14884`） / `MCPServerConfig`（`nexus_utils/mcp/mcp_client/models.py:13999`）

`MCPServerConfig` 是 MCP 域的权威 dataclass，`MCPServerInfo` 是 REST 路由的视图模型。

| 字段 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `name` | `str` | — | 全局唯一的服务器名 |
| `transport` | `TransportType` | — | `STDIO` / `SSE` / `HTTP` |
| `command` | `Optional[str]` | `None` | stdio：可执行命令 |
| `args` | `List[str]` | `[]` | stdio：命令行参数 |
| `env` | `Dict[str, str]` | `{}` | stdio：子进程环境变量 |
| `url` | `Optional[str]` | `None` | sse / http：端点 URL |
| `headers` | `Dict[str, str]` | `{}` | sse / http：HTTP 头 |
| `auto_approve` | `List[str]` | `[]` | 免确认工具白名单 |
| `disabled` | `bool` | `False` | 禁用标志 |
| `description` | `Optional[str]` | `None` | 描述文本 |

`MCPServerConfig.validate()`（`nexus_utils/mcp/mcp_client/models.py:14028`）要求 stdio 必须有 `command`，sse / http 必须有 `url`。

### `TransportType`（`nexus_utils/mcp/mcp_client/models.py:13985`）

| 值 | 说明 |
|----|------|
| `STDIO = "stdio"` | 子进程标准输入输出 |
| `SSE = "sse"` | Server-Sent Events |
| `HTTP = "http"` | Streamable HTTP |

### `SkillType`（`nexus_utils/skill/models.py:1277`）

| 值 | 说明 |
|----|------|
| `SYSTEM = "system"` | 平台预置 Skill |
| `GENERATED = "generated"` | 通过 build workflow 生成 |
| `COMMUNITY = "community"` | 从 GitHub / URL 导入 |
| `PRIVATE = "private"` | 用户私有 |

### `SkillInfo`（`nexus_utils/skill/models.py:1473`）

关键字段（完整字段见源文件）：

| 字段 | 类型 | 说明 |
|------|------|------|
| `skill_id` | `str` | `sk-&lt;uuid&gt;` |
| `skill_name` | `str` | 唯一名称（类型内唯一） |
| `skill_type` | `str` | `SkillType` 值 |
| `tools` | `List[str]` | Skill 所需工具列表 |
| `local_path` | `str` | `skills/&lt;type&gt;_skills/&lt;name&gt;/` |
| `s3_prefix` | `str` | `skills/&lt;type&gt;/&lt;skill_id&gt;/` |
| `file_manifest` | `Optional[Dict]` | `FileManifest.to_dict()` |
| `has_scripts` | `bool` | 是否含可执行脚本 |
| `script_runtime` | `str` | `python` / `bash` / `node` / `mixed` |
| `l1_summary` | `str` | 列表页快速摘要（<200 字符） |

`FileManifest`（`nexus_utils/skill/models.py:1412`）按目录分桶：`prompt`、`scripts`、`references`、`agents`、`assets`、`evals`、`config`、`other`。

## Strands `@tool` 装饰器约定

所有 Nexus-AI 自定义工具必须遵守以下约束，否则会被 AST 扫描跳过或 LLM 无法正确调用：

1. **导入**：`from strands import tool`。
2. **装饰器形式**：`@tool` 或 `@module.tool`；`_parse_tool_file` 识别这两种形式（`api/v2/routers/agent_tools.py:15001`）。
3. **函数签名必须带类型注解**。类型用于推导 JSON Schema；支持的注解形式见 `_parse_annotation`（`api/v2/routers/agent_tools.py:14952`）：`ast.Name`、`ast.Subscript`（如 `Optional[str]`、`Dict[str, Any]`）、`ast.Attribute`（如 `typing.Any`）、`ast.BinOp`（Python 3.10+ `str | None`）。
4. **必须有 docstring**。第一行作为工具描述，Args / Returns 段落供 LLM 阅读。
5. **不要在模块顶层有副作用**（比如连接数据库）。AST 扫描不会执行模块，但 Agent 启动时会 import。
6. **首选返回 JSON 字符串**（或 plain str）。调用方会把结果拼回对话上下文，结构化 JSON 便于 LLM 解析。

最小示例（节选自 `tools/generated_tools/hermes_analyst_agent_2026a96a/file_writer.py:2689`）：

```python
from strands import tool

@tool
def file_writer(
    content: str,
    file_path: str,
    encoding: str = "utf-8",
    overwrite: bool = True,
) -> str:
    """将文本内容写入指定路径的文件，主要用于保存 Markdown 格式的技术博文。

    Args:
        content:   要写入文件的完整文本内容。
        file_path: 输出文件路径。
        encoding:  文件编码格式，默认 utf-8。
        overwrite: 是否覆盖已存在的文件，默认 True。

    Returns:
        JSON 字符串：{"success": bool, "file_path": str, "file_size": int, "error": str | null}
    """
```

## 五种工具类型

| 类型 | 来源 | 目录 | 典型用途 |
|------|------|------|----------|
| `builtin` | `strands-agents-tools` pip 包 | pip 安装 | 文件读写、Shell、HTTP、Bedrock KB 等 |
| `system` | Nexus-AI 平台内置 | `tools/system_tools/**` | 平台"一等公民"能力（build workflow、skill 管理、data connector 等） |
| `template` | 可复用参考模板 | `tools/template_tools/**` | 自定义 Agent 开发起点 |
| `generated` | Build Workflow 生成 | `tools/generated_tools/&lt;agent_dir&gt;/**` | Agent 构建产物 |
| `mcp` | 外部 MCP Server | `config/mcp/*.json` 或 DynamoDB | 通过 MCP 协议集成第三方工具 |

### 内置工具清单

由 `_get_builtin_tools_info()`（`api/v2/routers/agent_tools.py:14919` 与 `tools/system_tools/agent_build_workflow/tool_template_provider.py:6145`）硬编码：

| 分类 | 工具 |
|------|------|
| RAG & Memory | `retrieve`, `memory`, `mem0_memory` |
| File Operations | `editor`, `file_read`, `file_write` |
| Shell & System | `environment`, `shell`, `cron` |
| Code Interpretation | `python_repl` |
| Web & Network | `http_request`, `slack` |
| Multi-modal | `image_reader`, `generate_image`, `nova_reels`, `speak` |
| AWS Services | `use_aws` |
| Utilities | `calculator`, `current_time`, `load_tool` |
| Agents & Workflows | `agent_graph`, `journal`, `swarm`, `stop`, `think`, `use_llm`, `workflow` |

`mem0_memory` 使用包 `strands-agents-tools[mem0_memory]`；其余均为 `strands-agents-tools`。

### System tools（代表性清单）

以下工具位于 `tools/system_tools/**`，每个都是独立的 `@tool` 函数：

| 模块 | 工具 | 文件 |
|------|------|------|
| Agent build workflow | `agent_code_developer`, `agent_tool_developer`, `agent_prompt_engineer`, `agent_template_searcher` | `tools/system_tools/agent_build_workflow/agent_developer_team_members.py` |
| Tool template provider | `list_all_tools`, `get_builtin_tools`, `get_template_tools`, `get_generated_tools`, `search_tools_by_name`, `search_tools_by_category`, `get_tool_details`, `get_tool_content`, `validate_tool_file`, `get_available_categories` | `tools/system_tools/agent_build_workflow/tool_template_provider.py` |
| Tool validator | `validate_tool_path`, `validate_tool_list` | `tools/system_tools/agent_build_workflow/tool_validator.py` |
| Build Workflow V2 | `write_tool_file_to_s3`, `read_tool_file_from_s3`, `list_tool_files_in_s3`, `validate_tool_code`, `get_project_info`, `get_stage_result` | `tools/system_tools/tool_build_workflow_v2/tool_build_v2_tools.py` |
| Data connector | `data_connector_query`, `data_connector_read`, `data_connector_schema`, `data_connector_write` | `tools/system_tools/data_connector/*.py` |
| Event scheduler | `workspace_list_files`, `workspace_read_file`, `workspace_write_file` | `tools/system_tools/event_scheduler/workspace_tools.py` |
| Runtime workspace | `runtime_workspace_list_files`, `runtime_workspace_read_file`, `runtime_workspace_write_file` | `tools/system_tools/runtime_workspace/workspace_tools.py` |
| Skill 激活 / 执行 | `activate_skill`, `get_skill_path`, `read_skill_file`, `manage_skill` | `tools/system_tools/skill_activator.py`, `skill_executor.py`, `skill_manager.py` |
| Skill build workflow | `write_skill_file_to_s3`, `read_skill_file_from_s3`, `list_skill_files_in_s3`, `validate_skill_structure`, `read_skill_reference` | `tools/system_tools/skill_build_workflow/skill_build_tools.py` |
| Multimodal | `parse_multimodal_content`, `get_supported_formats`, `validate_files`, `get_processing_status` | `tools/system_tools/multimodal_content_parser.py` |
| Nexus bridge | `create_remote_shell_tool`（工厂） | `tools/system_tools/nexus_bridge/remote_shell.py` |
| Q CLI | `inference_with_amazon_q` | `tools/system_tools/qcli_integration.py` |

### Template tools

`tools/template_tools/common/` 下的 `data_converter.py`、`research_tools.py`、`text_processor.py` 与 `tools/template_tools/network/` 下的 `http_client.py`、`web_search_tool.py` 是可复制到新 Agent 的示例实现，均为标准 `@tool` 函数。

## 工具解析：AST 扫描如何工作

`api/v2/routers/agent_tools.py:14989` 的 `_parse_tool_file` 是平台扫描工具的核心逻辑：

```python
def _parse_tool_file(file_path: FilePath) -> List[Dict[str, Any]]:
    tree = ast.parse(content)
    for node in ast.walk(tree):
        if isinstance(node, ast.FunctionDef):
            # 检查 @tool 或 @module.tool 装饰器
            has_tool_decorator = any(
                (isinstance(d, ast.Name) and d.id == 'tool') or
                (isinstance(d, ast.Attribute) and d.attr == 'tool')
                for d in node.decorator_list
            )
            if has_tool_decorator:
                # 提取 docstring、参数、返回类型
                ...
```

扫描约定：

- 跳过 `__` 开头的文件（如 `__init__.py`、`__pycache__`）。
- `relative_path.parent` 用作 `category`（例如 `tools/system_tools/data_connector/data_connector_query.py` → `category="data_connector"`）；文件位于扫描根目录则 `category="general"`。
- 参数解析通过 `_parse_annotation` 处理泛型（见前文）。
- 有默认值的参数 `required=False`（`api/v2/routers/agent_tools.py:15024`）。

## 扩展点：添加新工具

### 添加一个 Generated / Template 工具

1. 建目录：`tools/generated_tools/&lt;agent_dir&gt;/` 或 `tools/template_tools/&lt;category&gt;/`。
2. 写 Python 文件，遵循装饰器约定：
   ```python
   from strands import tool

   @tool
   def my_tool(arg1: str, arg2: int = 10) -> str:
       """一行描述。

       Args:
           arg1: 参数说明
           arg2: 参数说明，默认 10

       Returns:
           JSON 字符串
       """
       ...
   ```
3. 如需第三方依赖，在同目录加 `requirements.txt`（参见 `tools/generated_tools/hermes_analyst_agent_2026a96a/requirements.txt`）。
4. 工具会被 `GET /api/v2/tools/list?type=generated` 自动发现，无需手动注册。

### 把工具挂到 Agent

在 Agent 的 prompt 模板 YAML 里添加 `tools_dependencies`，由 `nexus_utils/agent_factory.py` 在运行时解析并注入到 Strands Agent。`validate_tool_path`（`tools/system_tools/agent_build_workflow/tool_validator.py:6735`）可在构建阶段先行校验路径存在性：

```python
# tools_dependencies 示例
tools_dependencies:
  - strands_tools/calculator                         # builtin
  - tools/system_tools/data_connector/data_connector_query
  - tools/generated_tools/my_agent/my_tool
```

### Build Workflow V2 的写入流

当工具由 `tool_build_workflow` Agent 生成时，流程是"写 S3 → 写本地缓存 → 校验"：

| 步骤 | 工具 | 说明 |
|------|------|------|
| 1 | `write_tool_file_to_s3` | 写到 `s3://&lt;artifacts_bucket&gt;/tools/&lt;dir_name&gt;/&lt;file&gt;`；同时写 `.cache/assets/&lt;s3_key&gt;` |
| 2 | `list_tool_files_in_s3` | 列出已写文件 |
| 3 | `validate_tool_code` | 对所有 `.py` 做 `ast.parse` + `@tool` 装饰器 + docstring + `get_tool_credentials` 导入校验 |

`validate_tool_code` 的校验项（`tools/system_tools/tool_build_workflow_v2/tool_build_v2_tools.py:11172`）：

- **语法**：`ast.parse` 失败 → `errors`。
- **@tool 装饰器**：至少一个文件中存在 `@tool` 或 `@tool(...)`。
- **docstring**：缺失或 `< 10` 字符 → `warnings`。
- **凭证导入**：源码含 `get_tool_credentials` 但无 `from nexus_utils.secret_key import get_tool_credentials` → `warnings`。

### 添加一个 System 工具

1. 在 `tools/system_tools/&lt;module&gt;/` 下建文件。
2. 遵循 `@tool` 约定。
3. 若要被 Agent 构建流程自动推荐，更新 `_get_builtin_tools_info()` 或 `tool_template_provider` 的元数据。
4. 在需要它的 Agent prompt 模板里加 `tools_dependencies: - tools/system_tools/&lt;module&gt;/&lt;file&gt;`。

## MCP 集成

### 配置文件布局

`MCPManager`（`nexus_utils/mcp/mcp_client/manager.py:13493`）加载顺序：

1. `config/mcp/system_mcp_server.json`
2. `config/mcp/public_mcp_server.json`
3. `config/mcp/*.json`（其他任意 JSON）
4. DynamoDB（运行时覆盖 JSON，见 `_refresh_from_dynamodb` — `manager.py:13787`）

JSON 格式（兼容 Kiro / Cursor）：

```json
{
  "mcpServers": {
    "filesystem": {
      "transport": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path"],
      "env": {},
      "autoApprove": ["read_file"],
      "disabled": false,
      "description": "Local filesystem MCP server"
    },
    "my-sse-server": {
      "transport": "sse",
      "url": "https://api.example.com/sse",
      "headers": {"Authorization": "Bearer xxx"}
    }
  }
}
```

### 三种传输类型

由 `MCPClientFactory`（`nexus_utils/mcp/mcp_client/client_factory.py:13305`）分发：

| 传输 | 必填 | 所用底层库 |
|------|------|-----------|
| `stdio` | `command` | `mcp.StdioServerParameters` + `mcp.client.stdio.stdio_client`；`startup_timeout=120` |
| `sse` | `url` | `mcp.client.sse.sse_client` |
| `http` | `url` | `mcp.client.streamable_http.streamablehttp_client` |

均通过 `strands.tools.mcp.MCPClient` 包装。`config.disabled=True` 时 `create_client` 返回 `None`（`client_factory.py:13334`）。

### 配置解析器支持的输入格式

`MCPConfigParser.parse`（`nexus_utils/mcp/mcp_client/parser.py:14148`）按顺序自动识别：

| 格式 | 触发条件 | 示例 |
|------|---------|------|
| 标准 JSON | 以 `{` 或 `[` 开头 | `{"mcpServers": {...}}` |
| URL | 匹配 `^https?://` 或 `^sse://` | `https://api.example.com/sse` |
| 命令字符串 | 首词为 `npx` / `uvx` / `node` / `python` / `python3` | `npx -y @modelcontextprotocol/server-filesystem /path` |

解析前先做 `_sanitize_input`（`parser.py:14133`）：去 BOM、智能引号替换、零宽字符剔除、全角冒号/逗号转半角（容错中文输入法误输）。

### MCP Manager API

| 方法 | 签名 | 行为 |
|------|------|------|
| `add_server` | `(config, source_file=None) -> bool` | 已存在则抛 `DuplicateServerError` |
| `update_server` | `(name, config) -> bool` | 未找到抛 `ServerNotFoundError` |
| `delete_server` | `(name) -> bool` | 同上 |
| `enable_server` / `disable_server` | `(name) -> bool` | 翻转 `disabled` 字段 |
| `create_client` | `(name) -> MCPClient \| None` | 禁用或未找到返回 `None` |
| `create_clients_for_dependencies` | `(mcp_dependencies: List[str]) -> List[MCPClient]` | **先从 DDB 刷新再创建**，跳过失败项 |
| `test_connection` | `async (name, timeout=30.0) -> Dict` | 返回 `{success, tools, error, tool_count}` |
| `list_tools` | `async (name) -> List[Dict]` | 枚举服务器工具 |
| `import_config` | `(config_data: str) -> List[MCPServerConfig]` | 多格式导入，DuplicateServer 静默跳过 |
| `save_configs` | `(server_name=None) -> None` | 持久化到 JSON（回写源文件） |
| `reload_configs` | `() -> None` | 清空内存后重新加载 |

`get_default_mcp_manager()`（`manager.py:13936`）是单例入口，首次创建时尝试把 JSON 同步进 DynamoDB（静默失败）。

### MCP REST API

挂载于 `/api/v2/mcp`（`nexus_utils/mcp/mcp_client/api.py:13011`）：

| 方法 | 路径 | 权限 | 说明 |
|------|------|------|------|
| GET | `/mcp/servers` | `tool:list` | 列表；支持 `scope` / `user_id` 筛选 |
| GET | `/mcp/servers/{server_id}` | `tool:read` | 按 ID 或 name 查找 |
| POST | `/mcp/servers` | `tool:create` | `ServerConfigRequest` |
| PUT | `/mcp/servers/{server_id}` | `tool:update` | `ServerUpdateRequest`（全部可选） |
| DELETE | `/mcp/servers/{server_id}` | `tool:delete` | — |
| POST | `/mcp/servers/import` | `tool:create` | `ImportConfigRequest`（支持 JSON / 命令 / URL） |
| POST | `/mcp/servers/{server_id}/test` | `tool:read` | 异步测试连接 |
| GET | `/mcp/servers/{server_id}/tools` | `tool:read` | 列出远端工具 |
| POST | `/mcp/servers/{server_id}/enable` | `tool:update` | 翻转 disabled=false |
| POST | `/mcp/servers/{server_id}/disable` | `tool:update` | 翻转 disabled=true |
| POST | `/mcp/servers/sync` | `tool:create` | 从本地 JSON 同步到 DDB |

### Nexus-AI MCP Server（反向暴露）

`nexus_utils/mcp/mcp_server/server.py:14729` 将平台上所有 `status=running` 的 Agent 注册为 MCP Tool 暴露给外部 MCP 客户端：

| 组件 | 行为 |
|------|------|
| `sanitize_tool_name`（`agent_tools.py:14445`） | `lower → [^a-z0-9]+ → _ → 去重下划线 → 截断 64 字符` |
| `list_running_agents`（`agent_tools.py:14468`） | `AgentService.list_agents(status="running", limit=100)` |
| `invoke_agent_sync`（`agent_tools.py:14481`） | `create_agent_from_prompt_template(agent_name=..., nocallback=True)`，在 `ThreadPoolExecutor` 里阻塞执行，带 `timeout`（默认 300s） |
| `refresh_agents` 工具 | 客户端调用可重载 Agent 列表 |
| `BearerTokenMiddleware`（`server.py:14625`） | 校验 `Authorization: Bearer <NEXUS_MCP_TOKEN>`；`/health` / `/healthz` 不校验 |
| `settings`（`config.py:14564`） | `NEXUS_MCP_PORT`（默认 9000）、`NEXUS_MCP_TOKEN`（缺失时用 `secrets.token_urlsafe(32)` 自动生成） |

启动方式：`python -m nexus_utils.mcp_server`（入口 `__main__.py`）。启动时控制台打印 Token 与客户端配置片段。

## Skill 子系统：渐进加载的"工具包"

Skill 不是单个 `@tool` 函数，而是一个包含 `SKILL.md` + 脚本 + 参考 + 子 Agent 指令的目录包，通过 L1/L2/L3 渐进式加载机制按需注入到 Agent 上下文。

### 加载层次

| 层次 | 内容 | 何时加载 |
|------|------|----------|
| L1 | `SkillManager.L1_FIELDS`（`skill_name`、`description`、`l1_summary` 等） | Agent 启动时 |
| L2 | `SKILL.md` 全文 + `references/*.md` + `scripts/*` 作为代码块 | `activate_skill(skill_id)` 被调用时 |
| L3 | 通过 `get_skill_path` / `read_skill_file` 拿到具体文件 | Agent 自主读取 |

### 目录标准（`nexus_utils/skill/models.py:1334`）

```
<skill_name>/
├── SKILL.md          # 必需；YAML frontmatter + body
├── scripts/          # 可执行脚本（.py / .sh / .js / .ts）
├── references/       # 参考文档（.md）
├── agents/           # 子 Agent 指令文件
├── assets/           # 静态资源
├── evals/            # 评估数据
├── eval-viewer/      # 评估 UI
└── config/           # 配置文件
```

`SKILL.md` frontmatter 约定：

```markdown
---
name: my-skill
description: 一句话描述（L1 摘要来源）
tools: Read, Glob, Grep
version: 1.0.0
---
# Body（< 500 行，否则 validate_skill_structure 给 warning）
```

### 存储结构

| 层 | 位置 |
|----|------|
| 本地 | `skills/{system \| generated \| community \| private}_skills/&lt;skill_name&gt;/` |
| S3 | `s3://&lt;artifacts_bucket&gt;/skills/&lt;skill_type&gt;/&lt;skill_id&gt;/` |
| DDB | `nexus_skills` 表（`SkillInfo.to_dict()`） |

同步策略（`nexus_utils/skill/storage.py:2030`）：

- 创建 / 导入：写本地 → 上传 S3 → 写 DDB。
- 使用时：`ensure_local` 检查本地；不存在则 `sync_s3_to_local`。
- `s3_files` 在 `save_to_s3` 后填入 DDB 记录；`_cache_invalidate` 清除内存缓存。

### `SkillManager` 关键 API

位于 `nexus_utils/skill/manager.py:709`：

| 方法 | 签名 | 说明 |
|------|------|------|
| `create_skill` | `(skill_name, skill_type, description, ..., content_files=None) -> Dict` | 本地 → S3 → DDB |
| `register_built_skill` | `(skill_id, skill_name, project_id, stage_result, user_id) -> Dict` | Build workflow 完成后注册；S3 已有文件，仅列 / 同步 / 写 DDB |
| `get_skill` | `(skill_id, include_prompt=True) -> Dict \| None` | `include_prompt=True` 触发 L2 组装 |
| `list_skills` | `(user_id=None, category=None, skill_type=None, search=None) -> List[Dict]` | 只返回 `L1_FIELDS` |
| `update_skill` | `(skill_id, updates: Dict) -> Dict \| None` | 支持通过 `content_files` / `system_prompt_snippet` 更新文件 |
| `delete_skill` | `(skill_id) -> bool` | 本地 + S3 + DDB 三处删除 |
| `import_from_github` | `(repo_url, path, skill_type, user_id, group_id) -> Dict` | 走 `SkillImporter.import_from_github` |

### `SkillRuntime`（`nexus_utils/skill/runtime.py:1667`）

`RUNTIME_MAP` 支持的扩展名：`.py → python`、`.sh → bash`、`.js → node`、`.ts → npx ts-node`。`DEFAULT_TIMEOUT = 120` 秒。

| 方法 | 说明 |
|------|------|
| `ensure_workspace(skill_id, skill_type, skill_name)` | 必要时从 S3 sync 到本地 |
| `list_scripts(skill_type, skill_name)` | 枚举 `scripts/` 下可执行文件，跳过 `__init__.py`、`__pycache__` |
| `execute_script(...)` | `subprocess.run` + `timeout`，注入 `SKILL_DIR` / `SKILL_NAME` / `SKILL_ID` 环境变量 |
| `execute_command(...)` | `shell=True` 执行任意命令；stdout 截断至 5000 字节、stderr 2000 字节 |
| `detect_script_runtime(...)` | 返回 `python` / `bash` / `node` / `mixed` / 空串 |

返回码约定（`ExecutionResult`，`nexus_utils/skill/models.py:1586`）：

| `return_code` | 含义 |
|--------------|------|
| `0` | 成功 |
| `-1` | 脚本不存在 / 不支持的扩展名 |
| `-2` | 超时 |
| `-3` | 其他异常 |

### `SkillImporter`（`nexus_utils/skill/importer.py:123`）

四种来源，统一返回 `(files: Dict[str, bytes], parsed_metadata: Dict)`：

| 方法 | 来源 | 实现 |
|------|------|------|
| `import_from_github(repo_url, path)` | GitHub 仓库单个 Skill | 优先 `raw.githubusercontent.com` + GitHub API；非 GitHub URL 回退 `git clone --depth 1` |
| `scan_github_batch(repo_url, base_path, existing_names)` | GitHub 批量扫描（预览） | 返回 `List[ScanResult]` |
| `import_from_github_batch(...)` | GitHub 批量导入 | 逐个调用 `_fetch_github_skill_files` |
| `import_from_url(url)` | 单个 `SKILL.md` URL | `httpx.get(timeout=30)` |
| `import_from_local_dir(skill_dir: Path)` | 本地目录 | `collect_skill_files` |
| `scan_claude_code_paths(scan_paths)` | Claude Code 本地目录 | 扫描每个子目录有无 `SKILL.md` |

`collect_skill_files`（`importer.py:198`）递归收集顶层文件和 `SKILL_STANDARD_DIRS` 下的内容，跳过隐藏文件和 `__pycache__`。

### Skill 相关的 `@tool` 函数

Agent 在会话中用到的 Skill 工具（均需在 prompt 模板 `tools_dependencies` 中声明）：

| 工具 | 文件 | 用途 |
|------|------|------|
| `activate_skill(skill_id)` | `tools/system_tools/skill_activator.py:9562` | L2 加载：组装 SKILL.md + references + scripts 并返回文本 |
| `get_skill_path(skill_id)` | `tools/system_tools/skill_executor.py:10126` | 返回本地路径、`python_bin`（优先 `&lt;skill&gt;/.venv/bin/python`）、脚本清单 |
| `read_skill_file(skill_id, file_path)` | `tools/system_tools/skill_executor.py:10193` | 读单个文件；防路径穿越；50000 字符截断 |
| `manage_skill(action, skill_data)` | `tools/system_tools/skill_manager.py:10259` | 通过 HTTP 调用平台 `/api/v2/skills/*`；`action ∈ {create, list, get, update, delete, scripts}` |
| `write_skill_file_to_s3` / `read_skill_file_from_s3` / `list_skill_files_in_s3` | `tools/system_tools/skill_build_workflow/skill_build_tools.py` | Build workflow 专用 S3 操作 |
| `validate_skill_structure(skill_id, skill_type)` | 同上 | 校验 SKILL.md 存在、frontmatter 合法、必填 `name` / `description` |
| `read_skill_reference(skill_name)` | 同上 | 读 `skills/community_skills/&lt;skill_name&gt;/SKILL.md` 作为构建参考 |

## Tool REST API（`api/v2/routers/agent_tools.py`）

挂载于 `/api/v2/tools`（`tags=["Agent Tools"]`）。本文覆盖的端点（源文件末尾有更多被截断；列出已确认的）：

| 方法 | 路径 | 权限 | 行为 |
|------|------|------|------|
| GET | `/tools/categories` | `tool:list` | 返回所有工具分类集合 |
| GET | `/tools/list` | `tool:list` | 聚合 5 种工具；支持 `type` / `category` / `search` |
| GET | `/tools/{tool_name}` | `tool:read` | 单个工具详情，含源代码 |

`/tools/list` 的响应包括 `by_type` 分组计数：

```python
{
  "tools": [...],
  "total": N,
  "by_type": {"builtin": n1, "generated": n2, "system": n3, "template": n4, "mcp": n5}
}
```

MCP 工具来源于 `_get_mcp_servers()`（`api/v2/routers/agent_tools.py:15053`）：**优先读 DynamoDB**（`db_client.list_mcp_servers`），失败或为空则回退到 `config/mcp/system_mcp_server.json` 与 `config/mcp/public_mcp_server.json`。

## 调用关系 / 数据流

```
前端 UI
  │
  ├── GET /api/v2/tools/list
  │     └── _scan_tools_directory()  ←  ast.parse(file)
  │                                    └── _parse_tool_file()  ←  @tool 装饰器
  │     └── _get_mcp_servers()  ←  DynamoDB / config/mcp/*.json
  │
  ├── /api/v2/mcp/servers/* ──► mcp_service ──► MCPManager ──► MCPClientFactory
  │                                                 │
  │                                                 └── stdio/sse/http MCPClient
  │
  └── Agent 运行时
         create_agent_from_prompt_template
         ├── tools_dependencies 解析  ──►  get_tool_by_path / get_tool_by_name
         ├── MCPManager.create_clients_for_dependencies(mcp_deps)
         └── Strands Agent(tools=[...])  ──►  推理时调用  @tool 函数
                                                  │
                                                  └── activate_skill(sk-...)
                                                        └── SkillStorage.get_full_prompt
                                                              └── L2: SKILL.md + refs + scripts
```

## 常见调试 / 故障排查

| 症状 | 可能原因 | 排查 |
|------|---------|------|
| 工具在 `/tools/list` 不出现 | 文件名以 `__` 开头 / 无 `@tool` 装饰器 / 语法错误 | 看 `logger.warning("Failed to parse tool file ...")` |
| `validate_tool_code` 报 "No @tool decorated functions" | 装饰器不是 `@tool` 或 `@module.tool` 形式 | 改为标准写法；别 alias |
| MCP 连接测试超时 | stdio：`startup_timeout=120` 未就绪 / sse / http URL 不通 | `test_connection` 返回 `error` 字段；查 `create_stdio_client` 日志 |
| "Failed to import MCP client library" | 未安装 `mcp` pip 包 | `pip install mcp` |
| `ConfigurationError: missing required fields` | stdio 无 `command` / sse / http 无 `url` | `MCPServerConfig.validate()` 检查 |
| Skill 激活后脚本找不到文件 | 本地未 sync | `SkillStorage.ensure_local` 会 `sync_s3_to_local`；检查 `logger.info("[sync] S3 → local: ...")` |
| Skill 脚本超时 | 默认 `DEFAULT_TIMEOUT=120` | `execute_script(timeout=...)` 传更大值 |
| MCP 服务器配置改了但 Agent 不生效 | 本地 JSON 与 DDB 不一致 | `create_clients_for_dependencies` 会先 `_refresh_from_dynamodb`；必要时 POST `/mcp/servers/sync` |
| Nexus-AI MCP Server 401 / 403 | Authorization header 缺失 / Token 不匹配 | 启动控制台输出的 Token；或设置 `NEXUS_MCP_TOKEN` 环境变量 |

常用日志前缀：

| 前缀 | 来源 |
|------|------|
| `[local]` / `[s3]` / `[sync]` / `[ensure]` | `nexus_utils/skill/storage.py` |
| `[runtime]` | `nexus_utils/skill/runtime.py` |
| `[create]` / `[delete]` / `[register_built_skill]` | `nexus_utils/skill/manager.py` |
| `[scan]` / `[batch]` / `[claude-code]` | `nexus_utils/skill/importer.py` |

## 延伸阅读

- Agent 工厂与 `tools_dependencies` 解析：`nexus_utils/agent_factory.py` — `get_tool_by_path` / `get_tool_by_name`。
- Tool Build Workflow V2：`tools/system_tools/tool_build_workflow_v2/tool_build_v2_tools.py`。
- Skill Build Workflow：`tools/system_tools/skill_build_workflow/skill_build_tools.py`。
- MCP 协议与 Strands 集成：`strands.tools.mcp.MCPClient` 在 `client_factory.py` 中的使用。
- 内置工具清单权威来源：`api/v2/routers/agent_tools.py:14919` 与 `tools/system_tools/agent_build_workflow/tool_template_provider.py:6145`。
