---
title: Adding Tools
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

# Adding Tools

## Overview

A Nexus-AI "Tool" is a Python function that a Strands Agent can call inside its reasoning loop. The platform recognises **five tool types** (`builtin` / `generated` / `system` / `template` / `mcp`) plus an optional **Skill progressive-loading subsystem**. Everything is surfaced to the UI through `api/v2/routers/agent_tools.py` and wired into Agents by `nexus_utils/agent_factory.py`.

Any custom tool must satisfy two invariants: the file must contain a function decorated with `@strands.tool`, and the function must have type annotations plus a docstring (Strands derives the JSON schema from the signature and the LLM-visible description from the docstring). This document is the developer reference for writing, registering, and debugging tools.

Entry points and their responsibilities:

| Entry point | File | Responsibility |
|-------------|------|----------------|
| REST API — Tool | `api/v2/routers/agent_tools.py` | List, detail, categories, MCP view, test |
| REST API — MCP | `nexus_utils/mcp/mcp_client/api.py` | MCP Server CRUD / import / connection test |
| Tool scanner / parser | `api/v2/routers/agent_tools.py:14989` (`_parse_tool_file`) | AST parses the `@tool` decorator |
| MCP client | `nexus_utils/mcp/mcp_client/manager.py:13493` (`MCPManager`) | stdio/sse/http client lifecycle |
| MCP server | `nexus_utils/mcp/mcp_server/server.py:14729` (`create_server`) | Exposes platform Agents as MCP Tools |
| Skill manager | `nexus_utils/skill/manager.py:709` (`SkillManager`) | Skill local + S3 + DDB lifecycle |
| Skill runtime | `nexus_utils/skill/runtime.py:1667` (`SkillRuntime`) | Executes Skill scripts via `subprocess` |

## File Layout

| Path | Responsibility | Key deps |
|------|----------------|----------|
| `api/v2/routers/agent_tools.py` | Tool REST API, AST scan, MCP aggregate view | `fastapi`, `pydantic`, `ast` |
| `nexus_utils/mcp/__init__.py` | Re-exports the common interface from `mcp_client` | `nexus_utils.mcp.mcp_client` |
| `nexus_utils/mcp/mcp_client/models.py` | `TransportType` enum, `MCPServerConfig` dataclass | `dataclasses`, `enum` |
| `nexus_utils/mcp/mcp_client/parser.py` | Multi-format MCP config parser (JSON / command / URL) | `shlex`, `urllib.parse` |
| `nexus_utils/mcp/mcp_client/client_factory.py` | Creates `MCPClient` by `TransportType` | `mcp`, `strands.tools.mcp` |
| `nexus_utils/mcp/mcp_client/manager.py` | MCP server config management, connection test, DDB sync | `boto3`, `MCPClientFactory` |
| `nexus_utils/mcp/mcp_client/api.py` | `/mcp/servers` REST routes | `fastapi`, `mcp_service` |
| `nexus_utils/mcp/mcp_client/exceptions.py` | `MCPManagerError` and subclasses | — |
| `nexus_utils/mcp/mcp_server/server.py` | FastMCP Server entry, Bearer Token middleware | `fastmcp`, `starlette` |
| `nexus_utils/mcp/mcp_server/agent_tools.py` | Dynamically register Agents as MCP Tools | `nexus_utils.agent_factory` |
| `nexus_utils/mcp/mcp_server/config.py` | MCP Server port & token config | `os`, `secrets` |
| `nexus_utils/skill/models.py` | Skill data models (`SkillType`, `SkillInfo`, `FileManifest`) | `dataclasses` |
| `nexus_utils/skill/manager.py` | Skill CRUD, import, grouping, execution coordination | `storage`, `importer`, `runtime` |
| `nexus_utils/skill/storage.py` | Two-tier storage (local + S3) | `boto3`, `pathlib` |
| `nexus_utils/skill/runtime.py` | Skill script / shell command execution | `subprocess` |
| `nexus_utils/skill/importer.py` | Import from GitHub / URL / local / Claude Code | `httpx`, `yaml`, `git` |
| `tools/system_tools/**` | Platform-builtin system tools (first-class, beyond MCP Client) | `strands` |
| `tools/template_tools/**` | Reusable reference templates | `strands` |
| `tools/generated_tools/&lt;agent_dir&gt;/**` | Tools emitted by the Agent build workflow | `strands` |

## Core Types / Data Structures

### `ToolParameter` (`api/v2/routers/agent_tools.py:14861`)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `name` | `str` | — | Parameter name |
| `type` | `str` | `"Any"` | Literal derived from AST |
| `description` | `Optional[str]` | `None` | From the docstring |
| `required` | `bool` | `True` | `True` when no default |
| `default` | `Optional[Any]` | `None` | Default value |

### `ToolInfo` (`api/v2/routers/agent_tools.py:14870`)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `name` | `str` | — | Tool function name |
| `type` | `str` | — | `builtin` / `generated` / `system` / `template` / `mcp` |
| `category` | `Optional[str]` | `None` | Category string |
| `description` | `Optional[str]` | `None` | First line of docstring |
| `file_path` | `Optional[str]` | `None` | Absolute path of the source file |
| `parameters` | `List[ToolParameter]` | `[]` | Parsed formal parameters |
| `package` | `Optional[str]` | `None` | Builtin only: pip package |
| `enabled` | `bool` | `True` | Enabled flag |
| `mcp_server` | `Optional[str]` | `None` | Owning MCP server (for mcp tools) |
| `return_type` | `Optional[str]` | `None` | Return type literal |

### `MCPServerInfo` (`api/v2/routers/agent_tools.py:14884`) / `MCPServerConfig` (`nexus_utils/mcp/mcp_client/models.py:13999`)

`MCPServerConfig` is the authoritative dataclass; `MCPServerInfo` is the REST view model.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `name` | `str` | — | Globally unique server name |
| `transport` | `TransportType` | — | `STDIO` / `SSE` / `HTTP` |
| `command` | `Optional[str]` | `None` | stdio: executable |
| `args` | `List[str]` | `[]` | stdio: CLI args |
| `env` | `Dict[str, str]` | `{}` | stdio: child-process env |
| `url` | `Optional[str]` | `None` | sse / http: endpoint URL |
| `headers` | `Dict[str, str]` | `{}` | sse / http: HTTP headers |
| `auto_approve` | `List[str]` | `[]` | Tools that skip confirmation |
| `disabled` | `bool` | `False` | Disabled flag |
| `description` | `Optional[str]` | `None` | Description text |

`MCPServerConfig.validate()` (`nexus_utils/mcp/mcp_client/models.py:14028`) requires `command` for stdio and `url` for sse / http.

### `TransportType` (`nexus_utils/mcp/mcp_client/models.py:13985`)

| Value | Description |
|-------|-------------|
| `STDIO = "stdio"` | Subprocess stdio |
| `SSE = "sse"` | Server-Sent Events |
| `HTTP = "http"` | Streamable HTTP |

### `SkillType` (`nexus_utils/skill/models.py:1277`)

| Value | Description |
|-------|-------------|
| `SYSTEM = "system"` | Platform-shipped skills |
| `GENERATED = "generated"` | Produced by build workflow |
| `COMMUNITY = "community"` | Imported from GitHub / URL |
| `PRIVATE = "private"` | User-private |

### `SkillInfo` (`nexus_utils/skill/models.py:1473`)

Key fields (see source for the complete list):

| Field | Type | Description |
|-------|------|-------------|
| `skill_id` | `str` | `sk-&lt;uuid&gt;` |
| `skill_name` | `str` | Unique within a type |
| `skill_type` | `str` | `SkillType` value |
| `tools` | `List[str]` | Tools needed by the skill |
| `local_path` | `str` | `skills/&lt;type&gt;_skills/&lt;name&gt;/` |
| `s3_prefix` | `str` | `skills/&lt;type&gt;/&lt;skill_id&gt;/` |
| `file_manifest` | `Optional[Dict]` | `FileManifest.to_dict()` |
| `has_scripts` | `bool` | Has executable scripts |
| `script_runtime` | `str` | `python` / `bash` / `node` / `mixed` |
| `l1_summary` | `str` | Short summary for list view (<200 chars) |

`FileManifest` (`nexus_utils/skill/models.py:1412`) buckets files by directory: `prompt`, `scripts`, `references`, `agents`, `assets`, `evals`, `config`, `other`.

## The Strands `@tool` Contract

Every Nexus-AI custom tool must satisfy the following, otherwise the AST scan skips it or the LLM cannot invoke it correctly:

1. **Import**: `from strands import tool`.
2. **Decorator form**: `@tool` or `@module.tool`; `_parse_tool_file` recognises both (`api/v2/routers/agent_tools.py:15001`).
3. **Type-annotated parameters**. Types drive JSON schema inference. `_parse_annotation` (`api/v2/routers/agent_tools.py:14952`) understands `ast.Name`, `ast.Subscript` (e.g. `Optional[str]`, `Dict[str, Any]`), `ast.Attribute` (e.g. `typing.Any`), and `ast.BinOp` (Python 3.10+ `str | None`).
4. **Docstring required**. The first line becomes the tool description; Args / Returns sections are read by the LLM.
5. **No import-time side effects** (e.g. DB connections). The AST scan never executes the module, but Agents import it at startup.
6. **Prefer returning a JSON string** (or plain str). The caller stitches the result back into the conversation context, and structured JSON is easier for the LLM to parse.

Minimal example (excerpted from `tools/generated_tools/hermes_analyst_agent_2026a96a/file_writer.py:2689`):

```python
from strands import tool

@tool
def file_writer(
    content: str,
    file_path: str,
    encoding: str = "utf-8",
    overwrite: bool = True,
) -> str:
    """Write text content to a file at the given path (e.g. Markdown blog posts).

    Args:
        content:   Full text content to write.
        file_path: Output file path.
        encoding:  File encoding, default utf-8.
        overwrite: Whether to overwrite existing files, default True.

    Returns:
        JSON string: {"success": bool, "file_path": str, "file_size": int, "error": str | null}
    """
```

## The Five Tool Types

| Type | Source | Directory | Typical use |
|------|--------|-----------|-------------|
| `builtin` | `strands-agents-tools` pip package | installed via pip | File I/O, shell, HTTP, Bedrock KB etc. |
| `system` | Platform-builtin | `tools/system_tools/**` | First-class platform capabilities (build workflow, skill mgmt, data connector, …) |
| `template` | Reusable references | `tools/template_tools/**` | Starting points for custom Agents |
| `generated` | Build workflow output | `tools/generated_tools/&lt;agent_dir&gt;/**` | Emitted during Agent build |
| `mcp` | External MCP Server | `config/mcp/*.json` or DynamoDB | Third-party tools via the MCP protocol |

### Builtin Tool Catalogue

Hard-coded in `_get_builtin_tools_info()` (`api/v2/routers/agent_tools.py:14919` and `tools/system_tools/agent_build_workflow/tool_template_provider.py:6145`):

| Category | Tools |
|----------|-------|
| RAG & Memory | `retrieve`, `memory`, `mem0_memory` |
| File Operations | `editor`, `file_read`, `file_write` |
| Shell & System | `environment`, `shell`, `cron` |
| Code Interpretation | `python_repl` |
| Web & Network | `http_request`, `slack` |
| Multi-modal | `image_reader`, `generate_image`, `nova_reels`, `speak` |
| AWS Services | `use_aws` |
| Utilities | `calculator`, `current_time`, `load_tool` |
| Agents & Workflows | `agent_graph`, `journal`, `swarm`, `stop`, `think`, `use_llm`, `workflow` |

`mem0_memory` uses the package `strands-agents-tools[mem0_memory]`; everything else comes from `strands-agents-tools`.

### System tools (representative list)

All of these live under `tools/system_tools/**`, each being a standalone `@tool` function:

| Module | Tools | File |
|--------|-------|------|
| Agent build workflow | `agent_code_developer`, `agent_tool_developer`, `agent_prompt_engineer`, `agent_template_searcher` | `tools/system_tools/agent_build_workflow/agent_developer_team_members.py` |
| Tool template provider | `list_all_tools`, `get_builtin_tools`, `get_template_tools`, `get_generated_tools`, `search_tools_by_name`, `search_tools_by_category`, `get_tool_details`, `get_tool_content`, `validate_tool_file`, `get_available_categories` | `tools/system_tools/agent_build_workflow/tool_template_provider.py` |
| Tool validator | `validate_tool_path`, `validate_tool_list` | `tools/system_tools/agent_build_workflow/tool_validator.py` |
| Build Workflow V2 | `write_tool_file_to_s3`, `read_tool_file_from_s3`, `list_tool_files_in_s3`, `validate_tool_code`, `get_project_info`, `get_stage_result` | `tools/system_tools/tool_build_workflow_v2/tool_build_v2_tools.py` |
| Data connector | `data_connector_query`, `data_connector_read`, `data_connector_schema`, `data_connector_write` | `tools/system_tools/data_connector/*.py` |
| Event scheduler | `workspace_list_files`, `workspace_read_file`, `workspace_write_file` | `tools/system_tools/event_scheduler/workspace_tools.py` |
| Runtime workspace | `runtime_workspace_list_files`, `runtime_workspace_read_file`, `runtime_workspace_write_file` | `tools/system_tools/runtime_workspace/workspace_tools.py` |
| Skill activate / exec | `activate_skill`, `get_skill_path`, `read_skill_file`, `manage_skill` | `tools/system_tools/skill_activator.py`, `skill_executor.py`, `skill_manager.py` |
| Skill build workflow | `write_skill_file_to_s3`, `read_skill_file_from_s3`, `list_skill_files_in_s3`, `validate_skill_structure`, `read_skill_reference` | `tools/system_tools/skill_build_workflow/skill_build_tools.py` |
| Multimodal | `parse_multimodal_content`, `get_supported_formats`, `validate_files`, `get_processing_status` | `tools/system_tools/multimodal_content_parser.py` |
| Nexus bridge | `create_remote_shell_tool` (factory) | `tools/system_tools/nexus_bridge/remote_shell.py` |
| Q CLI | `inference_with_amazon_q` | `tools/system_tools/qcli_integration.py` |

### Template tools

`tools/template_tools/common/` (`data_converter.py`, `research_tools.py`, `text_processor.py`) and `tools/template_tools/network/` (`http_client.py`, `web_search_tool.py`) are reference implementations meant to be copied into a new Agent; they are all standard `@tool` functions.

## Tool Parsing: How the AST Scan Works

`_parse_tool_file` at `api/v2/routers/agent_tools.py:14989` is the backbone of tool discovery:

```python
def _parse_tool_file(file_path: FilePath) -> List[Dict[str, Any]]:
    tree = ast.parse(content)
    for node in ast.walk(tree):
        if isinstance(node, ast.FunctionDef):
            # Check for @tool or @module.tool
            has_tool_decorator = any(
                (isinstance(d, ast.Name) and d.id == 'tool') or
                (isinstance(d, ast.Attribute) and d.attr == 'tool')
                for d in node.decorator_list
            )
            if has_tool_decorator:
                # Extract docstring, params, return type
                ...
```

Scan conventions:

- Files starting with `__` are skipped (e.g. `__init__.py`, `__pycache__`).
- `relative_path.parent` becomes `category` (e.g. `tools/system_tools/data_connector/data_connector_query.py` → `category="data_connector"`); files at the scan root get `category="general"`.
- Parameter parsing handles generics via `_parse_annotation` (see above).
- Parameters with default values get `required=False` (`api/v2/routers/agent_tools.py:15024`).

## Extension Points: Adding a Tool

### Add a Generated / Template tool

1. Create a directory: `tools/generated_tools/&lt;agent_dir&gt;/` or `tools/template_tools/&lt;category&gt;/`.
2. Write the Python file following the decorator contract:
   ```python
   from strands import tool

   @tool
   def my_tool(arg1: str, arg2: int = 10) -> str:
       """One-line description.

       Args:
           arg1: description
           arg2: description, default 10

       Returns:
           JSON string
       """
       ...
   ```
3. If you need third-party deps, add a `requirements.txt` in the same directory (see `tools/generated_tools/hermes_analyst_agent_2026a96a/requirements.txt`).
4. The tool is auto-discovered by `GET /api/v2/tools/list?type=generated` — no manual registration needed.

### Wire a tool into an Agent

In the Agent's prompt template YAML, add `tools_dependencies`. `nexus_utils/agent_factory.py` resolves and injects them into the Strands Agent at runtime. `validate_tool_path` (`tools/system_tools/agent_build_workflow/tool_validator.py:6735`) can pre-check path existence during the build stage:

```python
# Example tools_dependencies
tools_dependencies:
  - strands_tools/calculator                         # builtin
  - tools/system_tools/data_connector/data_connector_query
  - tools/generated_tools/my_agent/my_tool
```

### Build Workflow V2 Write Path

When the `tool_build_workflow` Agent emits a tool, the flow is "write S3 → write local cache → validate":

| Step | Tool | Notes |
|------|------|-------|
| 1 | `write_tool_file_to_s3` | Writes to `s3://&lt;artifacts_bucket&gt;/tools/&lt;dir_name&gt;/&lt;file&gt;`; also to `.cache/assets/&lt;s3_key&gt;` |
| 2 | `list_tool_files_in_s3` | Lists written files |
| 3 | `validate_tool_code` | Runs `ast.parse` + `@tool` decorator + docstring + `get_tool_credentials` import check on every `.py` |

Checks in `validate_tool_code` (`tools/system_tools/tool_build_workflow_v2/tool_build_v2_tools.py:11172`):

- **Syntax**: `ast.parse` failure → `errors`.
- **@tool decorator**: at least one file must contain `@tool` or `@tool(...)`.
- **Docstring**: missing or `< 10` chars → `warnings`.
- **Credential import**: code uses `get_tool_credentials` without `from nexus_utils.secret_key import get_tool_credentials` → `warnings`.

### Add a System tool

1. Create the file under `tools/system_tools/&lt;module&gt;/`.
2. Follow the `@tool` contract.
3. To make it surface in the Agent build recommender, update `_get_builtin_tools_info()` or the `tool_template_provider` metadata.
4. Add `tools_dependencies: - tools/system_tools/&lt;module&gt;/&lt;file&gt;` to the prompt templates that need it.

## MCP Integration

### Config file layout

`MCPManager` (`nexus_utils/mcp/mcp_client/manager.py:13493`) loads in this order:

1. `config/mcp/system_mcp_server.json`
2. `config/mcp/public_mcp_server.json`
3. `config/mcp/*.json` (any other JSON)
4. DynamoDB (runtime override of JSON — see `_refresh_from_dynamodb` in `manager.py:13787`)

JSON format (compatible with Kiro / Cursor):

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

### The three transports

Dispatched by `MCPClientFactory` (`nexus_utils/mcp/mcp_client/client_factory.py:13305`):

| Transport | Required | Underlying lib |
|-----------|----------|----------------|
| `stdio` | `command` | `mcp.StdioServerParameters` + `mcp.client.stdio.stdio_client`; `startup_timeout=120` |
| `sse` | `url` | `mcp.client.sse.sse_client` |
| `http` | `url` | `mcp.client.streamable_http.streamablehttp_client` |

All are wrapped by `strands.tools.mcp.MCPClient`. When `config.disabled=True`, `create_client` returns `None` (`client_factory.py:13334`).

### Input formats the parser supports

`MCPConfigParser.parse` (`nexus_utils/mcp/mcp_client/parser.py:14148`) auto-detects in this order:

| Format | Trigger | Example |
|--------|---------|---------|
| Standard JSON | Starts with `{` or `[` | `{"mcpServers": {...}}` |
| URL | Matches `^https?://` or `^sse://` | `https://api.example.com/sse` |
| Command string | First token is `npx` / `uvx` / `node` / `python` / `python3` | `npx -y @modelcontextprotocol/server-filesystem /path` |

Before parsing, `_sanitize_input` (`parser.py:14133`) strips BOMs, replaces smart quotes, removes zero-width chars, and converts full-width `:` / `,` — defensive against IME input.

### MCP Manager API

| Method | Signature | Behaviour |
|--------|-----------|-----------|
| `add_server` | `(config, source_file=None) -> bool` | Raises `DuplicateServerError` if exists |
| `update_server` | `(name, config) -> bool` | Raises `ServerNotFoundError` if missing |
| `delete_server` | `(name) -> bool` | Same as above |
| `enable_server` / `disable_server` | `(name) -> bool` | Flips the `disabled` field |
| `create_client` | `(name) -> MCPClient \| None` | Returns `None` when disabled or missing |
| `create_clients_for_dependencies` | `(mcp_dependencies: List[str]) -> List[MCPClient]` | **Refreshes from DDB first**, then creates; skips failures |
| `test_connection` | `async (name, timeout=30.0) -> Dict` | Returns `{success, tools, error, tool_count}` |
| `list_tools` | `async (name) -> List[Dict]` | Enumerates remote tools |
| `import_config` | `(config_data: str) -> List[MCPServerConfig]` | Multi-format import; silently skips `DuplicateServer` |
| `save_configs` | `(server_name=None) -> None` | Persists back to the source JSON |
| `reload_configs` | `() -> None` | Clears memory and reloads |

`get_default_mcp_manager()` (`manager.py:13936`) is the singleton entry; on first creation it also tries to push local JSON into DynamoDB (silent failure).

### MCP REST API

Mounted at `/api/v2/mcp` (`nexus_utils/mcp/mcp_client/api.py:13011`):

| Method | Path | Permission | Behaviour |
|--------|------|------------|-----------|
| GET | `/mcp/servers` | `tool:list` | List; supports `scope` / `user_id` filters |
| GET | `/mcp/servers/{server_id}` | `tool:read` | Lookup by ID or name |
| POST | `/mcp/servers` | `tool:create` | `ServerConfigRequest` |
| PUT | `/mcp/servers/{server_id}` | `tool:update` | `ServerUpdateRequest` (all optional) |
| DELETE | `/mcp/servers/{server_id}` | `tool:delete` | — |
| POST | `/mcp/servers/import` | `tool:create` | `ImportConfigRequest` (JSON / command / URL) |
| POST | `/mcp/servers/{server_id}/test` | `tool:read` | Async connection test |
| GET | `/mcp/servers/{server_id}/tools` | `tool:read` | List remote tools |
| POST | `/mcp/servers/{server_id}/enable` | `tool:update` | Set `disabled=false` |
| POST | `/mcp/servers/{server_id}/disable` | `tool:update` | Set `disabled=true` |
| POST | `/mcp/servers/sync` | `tool:create` | Sync local JSON to DDB |

### Nexus-AI MCP Server (reverse exposure)

`nexus_utils/mcp/mcp_server/server.py:14729` registers every `status=running` Agent on the platform as an MCP Tool for external MCP clients:

| Component | Behaviour |
|-----------|-----------|
| `sanitize_tool_name` (`agent_tools.py:14445`) | `lower → [^a-z0-9]+ → _ → collapse underscores → clip to 64 chars` |
| `list_running_agents` (`agent_tools.py:14468`) | `AgentService.list_agents(status="running", limit=100)` |
| `invoke_agent_sync` (`agent_tools.py:14481`) | `create_agent_from_prompt_template(agent_name=..., nocallback=True)`, runs blocking in a `ThreadPoolExecutor` with `timeout` (default 300s) |
| `refresh_agents` tool | Clients call it to rebuild the Agent list |
| `BearerTokenMiddleware` (`server.py:14625`) | Validates `Authorization: Bearer <NEXUS_MCP_TOKEN>`; `/health` / `/healthz` bypass auth |
| `settings` (`config.py:14564`) | `NEXUS_MCP_PORT` (default 9000), `NEXUS_MCP_TOKEN` (auto-generated via `secrets.token_urlsafe(32)` if missing) |

Startup: `python -m nexus_utils.mcp_server` (entry `__main__.py`). The console prints the token and a ready-to-paste client config fragment.

## The Skill Subsystem: Progressively Loaded "Tool Packs"

A Skill is not a single `@tool` function but a bundle of `SKILL.md` + scripts + references + sub-agent instructions. It is pushed into the Agent context on demand through an L1/L2/L3 progressive-loading scheme.

### Load tiers

| Tier | Content | When loaded |
|------|---------|-------------|
| L1 | `SkillManager.L1_FIELDS` (`skill_name`, `description`, `l1_summary`, …) | At Agent startup |
| L2 | Full `SKILL.md` + `references/*.md` + `scripts/*` as code blocks | When `activate_skill(skill_id)` is called |
| L3 | Individual files via `get_skill_path` / `read_skill_file` | Agent-initiated reads |

### Directory standard (`nexus_utils/skill/models.py:1334`)

```
<skill_name>/
├── SKILL.md          # required; YAML frontmatter + body
├── scripts/          # executable scripts (.py / .sh / .js / .ts)
├── references/       # reference docs (.md)
├── agents/           # sub-agent instructions
├── assets/           # static assets
├── evals/            # eval data
├── eval-viewer/      # eval UI
└── config/           # config files
```

`SKILL.md` frontmatter contract:

```markdown
---
name: my-skill
description: One-liner (source of the L1 summary)
tools: Read, Glob, Grep
version: 1.0.0
---
# Body (< 500 lines, otherwise validate_skill_structure emits a warning)
```

### Storage layout

| Tier | Location |
|------|----------|
| Local | `skills/{system \| generated \| community \| private}_skills/&lt;skill_name&gt;/` |
| S3 | `s3://&lt;artifacts_bucket&gt;/skills/&lt;skill_type&gt;/&lt;skill_id&gt;/` |
| DDB | `nexus_skills` table (`SkillInfo.to_dict()`) |

Sync strategy (`nexus_utils/skill/storage.py:2030`):

- On create / import: write local → upload S3 → write DDB.
- On use: `ensure_local` checks local; falls back to `sync_s3_to_local`.
- `s3_files` is populated into the DDB record after `save_to_s3`; `_cache_invalidate` flushes the in-memory cache.

### `SkillManager` key API

Located at `nexus_utils/skill/manager.py:709`:

| Method | Signature | Notes |
|--------|-----------|-------|
| `create_skill` | `(skill_name, skill_type, description, ..., content_files=None) -> Dict` | local → S3 → DDB |
| `register_built_skill` | `(skill_id, skill_name, project_id, stage_result, user_id) -> Dict` | Called after build workflow finishes; S3 already has files, just list / sync / write DDB |
| `get_skill` | `(skill_id, include_prompt=True) -> Dict \| None` | `include_prompt=True` triggers L2 assembly |
| `list_skills` | `(user_id=None, category=None, skill_type=None, search=None) -> List[Dict]` | Returns `L1_FIELDS` only |
| `update_skill` | `(skill_id, updates: Dict) -> Dict \| None` | Supports updating files via `content_files` / `system_prompt_snippet` |
| `delete_skill` | `(skill_id) -> bool` | Deletes local + S3 + DDB |
| `import_from_github` | `(repo_url, path, skill_type, user_id, group_id) -> Dict` | Delegates to `SkillImporter.import_from_github` |

### `SkillRuntime` (`nexus_utils/skill/runtime.py:1667`)

`RUNTIME_MAP` extensions: `.py → python`, `.sh → bash`, `.js → node`, `.ts → npx ts-node`. `DEFAULT_TIMEOUT = 120` seconds.

| Method | Description |
|--------|-------------|
| `ensure_workspace(skill_id, skill_type, skill_name)` | Syncs from S3 when necessary |
| `list_scripts(skill_type, skill_name)` | Enumerates executables under `scripts/`; skips `__init__.py` and `__pycache__` |
| `execute_script(...)` | `subprocess.run` with `timeout`; injects `SKILL_DIR` / `SKILL_NAME` / `SKILL_ID` env vars |
| `execute_command(...)` | `shell=True` arbitrary command; truncates stdout to 5000 bytes, stderr to 2000 bytes |
| `detect_script_runtime(...)` | Returns `python` / `bash` / `node` / `mixed` / empty string |

Return-code convention (`ExecutionResult`, `nexus_utils/skill/models.py:1586`):

| `return_code` | Meaning |
|---------------|---------|
| `0` | Success |
| `-1` | Script missing / unsupported extension |
| `-2` | Timeout |
| `-3` | Other exception |

### `SkillImporter` (`nexus_utils/skill/importer.py:123`)

Four sources, all returning `(files: Dict[str, bytes], parsed_metadata: Dict)`:

| Method | Source | Implementation |
|--------|--------|----------------|
| `import_from_github(repo_url, path)` | Single skill in a GitHub repo | Prefers `raw.githubusercontent.com` + GitHub API; falls back to `git clone --depth 1` for non-GitHub URLs |
| `scan_github_batch(repo_url, base_path, existing_names)` | GitHub batch scan (preview) | Returns `List[ScanResult]` |
| `import_from_github_batch(...)` | GitHub batch import | Calls `_fetch_github_skill_files` per directory |
| `import_from_url(url)` | Single `SKILL.md` URL | `httpx.get(timeout=30)` |
| `import_from_local_dir(skill_dir: Path)` | Local directory | `collect_skill_files` |
| `scan_claude_code_paths(scan_paths)` | Claude Code local dirs | Inspects each child dir for `SKILL.md` |

`collect_skill_files` (`importer.py:198`) recursively collects top-level files and everything under `SKILL_STANDARD_DIRS`, skipping dotfiles and `__pycache__`.

### Skill-related `@tool` functions

Tools an Agent uses in-session (each must appear in `tools_dependencies` of its prompt template):

| Tool | File | Purpose |
|------|------|---------|
| `activate_skill(skill_id)` | `tools/system_tools/skill_activator.py:9562` | L2 load: assembles SKILL.md + references + scripts into text |
| `get_skill_path(skill_id)` | `tools/system_tools/skill_executor.py:10126` | Returns local path, `python_bin` (prefers `&lt;skill&gt;/.venv/bin/python`), and script list |
| `read_skill_file(skill_id, file_path)` | `tools/system_tools/skill_executor.py:10193` | Reads a single file; blocks path traversal; truncates at 50000 chars |
| `manage_skill(action, skill_data)` | `tools/system_tools/skill_manager.py:10259` | HTTP wrapper around `/api/v2/skills/*`; `action ∈ {create, list, get, update, delete, scripts}` |
| `write_skill_file_to_s3` / `read_skill_file_from_s3` / `list_skill_files_in_s3` | `tools/system_tools/skill_build_workflow/skill_build_tools.py` | Build-workflow S3 ops |
| `validate_skill_structure(skill_id, skill_type)` | Same as above | Checks SKILL.md presence, frontmatter validity, required `name` / `description` |
| `read_skill_reference(skill_name)` | Same as above | Reads `skills/community_skills/&lt;skill_name&gt;/SKILL.md` as a building reference |

## Tool REST API (`api/v2/routers/agent_tools.py`)

Mounted at `/api/v2/tools` (`tags=["Agent Tools"]`). Endpoints documented here (more exist past the source truncation; listed are the confirmed ones):

| Method | Path | Permission | Behaviour |
|--------|------|------------|-----------|
| GET | `/tools/categories` | `tool:list` | Returns the set of all tool categories |
| GET | `/tools/list` | `tool:list` | Aggregates the 5 types; supports `type` / `category` / `search` |
| GET | `/tools/{tool_name}` | `tool:read` | Tool detail, including source |

`/tools/list` also includes a `by_type` breakdown:

```python
{
  "tools": [...],
  "total": N,
  "by_type": {"builtin": n1, "generated": n2, "system": n3, "template": n4, "mcp": n5}
}
```

MCP tools come from `_get_mcp_servers()` (`api/v2/routers/agent_tools.py:15053`): **DynamoDB first** (`db_client.list_mcp_servers`); if empty or on failure, falls back to `config/mcp/system_mcp_server.json` and `config/mcp/public_mcp_server.json`.

## Call Graph / Data Flow

```
Frontend UI
  │
  ├── GET /api/v2/tools/list
  │     └── _scan_tools_directory()  ←  ast.parse(file)
  │                                    └── _parse_tool_file()  ←  @tool decorator
  │     └── _get_mcp_servers()  ←  DynamoDB / config/mcp/*.json
  │
  ├── /api/v2/mcp/servers/* ──► mcp_service ──► MCPManager ──► MCPClientFactory
  │                                                 │
  │                                                 └── stdio/sse/http MCPClient
  │
  └── Agent runtime
         create_agent_from_prompt_template
         ├── resolves tools_dependencies  ──►  get_tool_by_path / get_tool_by_name
         ├── MCPManager.create_clients_for_dependencies(mcp_deps)
         └── Strands Agent(tools=[...])  ──►  invokes @tool functions during inference
                                                  │
                                                  └── activate_skill(sk-...)
                                                        └── SkillStorage.get_full_prompt
                                                              └── L2: SKILL.md + refs + scripts
```

## Debugging / Troubleshooting

| Symptom | Likely cause | How to check |
|---------|--------------|--------------|
| Tool missing from `/tools/list` | File starts with `__` / no `@tool` decorator / syntax error | Look for `logger.warning("Failed to parse tool file ...")` |
| `validate_tool_code` reports "No @tool decorated functions" | Decorator is not `@tool` or `@module.tool` | Use the standard form; don't alias |
| MCP connection test times out | stdio `startup_timeout=120` not ready / sse / http URL unreachable | `test_connection` returns `error`; inspect `create_stdio_client` logs |
| "Failed to import MCP client library" | `mcp` pip package missing | `pip install mcp` |
| `ConfigurationError: missing required fields` | stdio without `command` / sse / http without `url` | Call `MCPServerConfig.validate()` |
| Skill script cannot find the file after activation | Local copy not synced | `SkillStorage.ensure_local` triggers `sync_s3_to_local`; check `logger.info("[sync] S3 → local: ...")` |
| Skill script timeout | Default `DEFAULT_TIMEOUT=120` | Pass a larger `timeout` to `execute_script` |
| MCP config edited but Agent sees stale values | Local JSON and DDB out of sync | `create_clients_for_dependencies` refreshes from DDB; otherwise POST `/mcp/servers/sync` |
| Nexus-AI MCP Server returns 401 / 403 | Missing or wrong Authorization header | Use the token printed at startup, or set `NEXUS_MCP_TOKEN` |

Useful log prefixes:

| Prefix | Source |
|--------|--------|
| `[local]` / `[s3]` / `[sync]` / `[ensure]` | `nexus_utils/skill/storage.py` |
| `[runtime]` | `nexus_utils/skill/runtime.py` |
| `[create]` / `[delete]` / `[register_built_skill]` | `nexus_utils/skill/manager.py` |
| `[scan]` / `[batch]` / `[claude-code]` | `nexus_utils/skill/importer.py` |

## Further Reading

- Agent factory and `tools_dependencies` resolution: `nexus_utils/agent_factory.py` — `get_tool_by_path` / `get_tool_by_name`.
- Tool Build Workflow V2: `tools/system_tools/tool_build_workflow_v2/tool_build_v2_tools.py`.
- Skill Build Workflow: `tools/system_tools/skill_build_workflow/skill_build_tools.py`.
- MCP protocol ↔ Strands integration: how `strands.tools.mcp.MCPClient` is used in `client_factory.py`.
- Authoritative builtin tool catalogue: `api/v2/routers/agent_tools.py:14919` and `tools/system_tools/agent_build_workflow/tool_template_provider.py:6145`.
