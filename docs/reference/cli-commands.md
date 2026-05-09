---
title: nexus-cli 命令
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - nexus-cli
    - nexus_utils/cli/**
  generated_at: 2026-05-09T01:02:11+00:00
  generated_by: docs-sync v2
---

# nexus-cli 命令

`nexus-cli` 是 Nexus-AI 的 kubectl 风格命令行工具，用于管理项目、Agent、备份、服务和云环境。可执行文件位于仓库根目录的 `nexus-cli`，实际入口为 `nexus_utils/cli/main.py`。

## 概述

| 属性 | 值 |
|------|----|
| 可执行文件 | `./nexus-cli`（Python wrapper） |
| Python 入口 | `python -m nexus_utils.cli.main` |
| 版本来源 | `config/app_manifest.yaml` → `app-manifest.version.current` |
| 输出编码 | 强制 UTF-8（stdout / stderr / `PYTHONIOENCODING`） |
| Python 最低版本 | 3.9+ |
| CLI 框架 | `click >= 8.1.7` |
| 表格渲染 | `tabulate >= 0.9.0` + `rich` |
| YAML 解析 | `pyyaml >= 6.0.1` |

运行 `./nexus-cli --help` 查看顶层帮助；运行 `./nexus-cli &lt;command&gt; --help` 查看任意子命令帮助。

## 全局选项

这些选项在所有子命令前传入（`./nexus-cli [global-options] &lt;command&gt; ...`）：

| 选项 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `--base-path` | string | `.` | Nexus-AI 安装的根路径 |
| `--lang` | `en` \| `zh` | `en` | 输出语言（影响 i18n 消息） |
| `--version` | flag | — | 显示版本号并退出（格式 `nexus-cli, version &lt;x.y.z&gt;`） |
| `--help` / `-h` | flag | — | 显示帮助并退出 |

## 命令总览

| 命令 | 作用 | 子命令数 |
|------|------|---------|
| `project` | 管理项目（初始化、列表、详情、构建、备份、还原、删除） | 7 |
| `agents` | 管理 AI Agent（列表、详情、构建、删除） | 4 |
| `chat` | 与 Agent 交互式对话（支持多模态输入） | 1（主命令） |
| `artifact` | 管理 S3 工件（push、pull、sync、list、versions、describe、delete） | 7 |
| `backup` | 管理项目备份（list、describe、validate、delete） | 4 |
| `job` | 管理任务与队列（list、view、clear、delete） | 4 |
| `service` | 管理服务（start、stop、restart、status、logs） | 5 |
| `deploy` | 管理云环境（up、down、status、list） | 4 |
| `sandbox` | 管理 Sandbox 运行时（overview、list、nodes、logs、runtime、launch、terminate、scale-down、rebuild-rootfs） | 9 |
| `init` | 初始化基础设施（DynamoDB 表、SQS 队列、S3 桶） | 0（主命令） |
| `overview` | 显示系统总览 | 0（主命令） |

::: tip
CLI 的所有输出格式化命令支持三种格式：`table`（默认，人类可读）、`json`（程序化消费）、`text`（简单文本）。通过 `--output` 或 `-o` 切换。
:::

## 环境变量

nexus-cli 在启动时读取以下环境变量：

| 变量 | 默认 | 说明 |
|------|------|------|
| `PYTHONIOENCODING` | `utf-8` | CLI 强制设为 `utf-8`（如未设置） |
| `NEXUS_MAX_FETCH_SIZE` | `104857600`（100 MB） | `chat` 命令下载 URL 附件的大小上限，单位字节 |
| `API_PORT` | `8000` | `service` 命令启动的 API 端口 |
| `WEB_PORT` | `3000` | `service` 命令启动的 Web 前端端口 |
| `NEXUS_MCP_PORT` | `9000` | MCP 服务端口 |
| `BRIDGE_PORT` | `8001` | Bridge 服务端口 |
| `SANDBOX_CONTROLLER_PORT` | `8002` | Sandbox Controller 端口 |
| `RUN_MODE` | `prod` | 服务运行模式（`dev` / `prod`） |
| `AWS_REGION` | 由 `config/default_config.yaml` 的 `aws.aws_region_name` 覆盖 | 启动服务时使用的 AWS 区域 |
| `LOG_LEVEL` | `INFO` | API/Worker 进程的日志级别 |
| `NEXUS_THREAD_POOL_SIZE` | `64` | API 进程的线程池大小（传递给子进程） |
| `NEXUS_AGENT_CREATION_TIMEOUT` | `120` | Agent 创建超时（秒） |
| `NEXUS_AGENT_STREAM_TIMEOUT` | `300` | Agent 流式响应超时（秒） |
| `NEXUS_SSE_HEARTBEAT_INTERVAL` | `15` | SSE 心跳间隔（秒） |
| `NEXUS_MAX_CONCURRENT_STREAMS` | `0`（无限制） | 并发 SSE 流上限 |

## `project` — 项目管理

管理 Nexus-AI 项目的完整生命周期。

### 子命令

| 子命令 | 作用 |
|--------|------|
| `init` | 创建新项目 |
| `list` | 列出所有项目 |
| `describe` | 查看项目详情 |
| `build` | 构建项目的 Docker 镜像 |
| `backup` | 创建项目备份 |
| `restore` | 从备份恢复项目 |
| `delete` | 删除项目及全部相关资源 |

### `project list`

**Usage:**

```bash
./nexus-cli project list [--output json|table|text]
```

| 参数 | 必填/可选 | 类型 | 默认 | 说明 |
|------|-----------|------|------|------|
| `--output`, `-o` | 可选 | `json`\|`table`\|`text` | `table` | 输出格式 |

输出列（table/text 模式）：`name`、`description`、`agents`、`templates`、`prompts`、`tools`、`created`。description 在表格中被截断至 50 字符。结尾追加 `Total: <N> projects`。

**示例：**

```bash
./nexus-cli project list
./nexus-cli project list --output json | jq '.projects[].name'
```

### `project describe`

**Usage:**

```bash
./nexus-cli project describe <name> [--output json|table|text]
```

| 参数 | 必填/可选 | 类型 | 默认 | 说明 |
|------|-----------|------|------|------|
| `name` | 必填 | string | — | 项目名称 |
| `--output`, `-o` | 可选 | `json`\|`table`\|`text` | `text` | 输出格式 |

text 模式输出的分节：`Description` / `Basic Information`（name、version、created、updated）/ `Agents`（每个 Agent 的名称、分类、描述前 3 行）/ `Dependencies`（按 `strands_tools/*`、`generated_tools/*`、`tools/system_tools/*` 分组，每组最多前 5 个）/ `Usage`（资源目录路径）/ `Documentation`（README 路径，如存在）。

JSON 模式额外包含 `agent_details`（每个 Agent 的 `name`/`description`/`category`/`tools`）。

**示例：**

```bash
./nexus-cli project describe my_project
./nexus-cli project describe my_project --output json
```

**退出码：**

- `0`：成功
- `1`：项目未找到或读取失败

### `project init`

**Usage:**

```bash
./nexus-cli project init <name> [--description <text>] [--dry-run]
```

| 参数 | 必填/可选 | 类型 | 默认 | 说明 |
|------|-----------|------|------|------|
| `name` | 必填 | string | — | 新项目的名称（将作为目录名） |
| `--description`, `-d` | 可选 | string | `""` | 项目描述 |
| `--dry-run` | 可选 | flag | `false` | 仅显示将执行的操作，不落盘 |

创建下列结构：

```
projects/<name>/
├── agents/             # 目录
├── config.yaml         # 文件
├── status.yaml         # 文件（初始 overall_status=pending）
└── README.md           # 文件（内容 "# <name>\n\n<description>\n"）
```

**示例：**

```bash
./nexus-cli project init my_agent --description "Customer support agent"
./nexus-cli project init my_agent --dry-run
```

**退出码：**

- `0`：成功或 dry-run
- `1`：名称已存在、校验失败或其他错误

### `project backup`

**Usage:**

```bash
./nexus-cli project backup <name> [--output <dir>] [--dry-run] \
  [--source-delete] [--sync-to-s3] [--notes <text>]
```

| 参数 | 必填/可选 | 类型 | 默认 | 说明 |
|------|-----------|------|------|------|
| `name` | 必填 | string | — | 项目名称 |
| `--output`, `-o` | 可选 | path | `backups/` | 备份输出目录 |
| `--dry-run` | 可选 | flag | `false` | 仅预览将备份的资源 |
| `--source-delete` | 可选 | flag | `false` | 备份成功后删除源目录 |
| `--sync-to-s3` | 可选 | flag | `false` | 备份完成后上传到 S3 |
| `--notes` | 可选 | string | `""` | S3 版本的备注（需配合 `--sync-to-s3`） |

备份文件名格式：`&lt;project-name&gt;_YYYYMMDD_HHMMSS.tar.gz`。

备份内容：
- `projects/&lt;name&gt;/` 目录完整内容
- `agents/generated_agents/&lt;name&gt;/` 下所有 `.py` 文件
- `prompts/generated_agents_prompts/&lt;name&gt;/` 下所有 `.yaml` 文件
- `tools/generated_tools/&lt;name&gt;/` 下所有工具
- Manifest（JSON）含 SHA-256 校验和

**示例：**

```bash
./nexus-cli project backup my_project
./nexus-cli project backup my_project --output /path/to/backups/
./nexus-cli project backup my_project --dry-run
./nexus-cli project backup my_project --source-delete
./nexus-cli project backup my_project --sync-to-s3 --notes "Production release v1.0"
```

### `project restore`

**Usage:**

```bash
./nexus-cli project restore <name> --from-backup <path> \
  [--force] [--dry-run] [--skip-sessions] [--skip-ddb] [--skip-s3]
```

| 参数 | 必填/可选 | 类型 | 默认 | 说明 |
|------|-----------|------|------|------|
| `name` | 必填 | string | — | 目标项目名称（可与备份不同，实现克隆） |
| `--from-backup` | 必填 | path | — | 备份 `.tar.gz` 文件路径 |
| `--force` | 可选 | flag | `false` | 覆盖已存在项目（自动创建安全备份） |
| `--dry-run` | 可选 | flag | `false` | 仅预览还原操作 |
| `--skip-sessions` | 可选 | flag | `false` | 跳过会话数据还原 |
| `--skip-ddb` | 可选 | flag | `false` | 跳过 DynamoDB 记录还原 |
| `--skip-s3` | 可选 | flag | `false` | 跳过 S3 对象还原 |

还原时自动执行 SHA-256 校验；校验失败会报 `Checksum Error`。

**示例：**

```bash
./nexus-cli project restore my_project --from-backup backups/my_project_20241125.tar.gz
./nexus-cli project restore my_project_copy --from-backup backups/my_project_20241125.tar.gz
./nexus-cli project restore my_project --from-backup backup.tar.gz --force
```

### `project delete`

**Usage:**

```bash
./nexus-cli project delete <name> [--force] [--dry-run]
```

| 参数 | 必填/可选 | 类型 | 默认 | 说明 |
|------|-----------|------|------|------|
| `name` | 必填 | string | — | 项目名称 |
| `--force` | 可选 | flag | `false` | 跳过确认提示 |
| `--dry-run` | 可选 | flag | `false` | 仅预览 |

会同时删除：
1. `agents/generated_agents/&lt;name&gt;/`
2. `prompts/generated_agents_prompts/&lt;name&gt;/`
3. `tools/generated_tools/&lt;name&gt;/`
4. `projects/&lt;name&gt;/`

### `project build`

**Usage:**

```bash
./nexus-cli project build <name> [--agent <agent>] [--tag <tag>] \
  [--no-cache] [--push [<uri>]] [--platform <os/arch>] \
  [--build-arg KEY=VALUE]...
```

| 参数 | 必填/可选 | 类型 | 默认 | 说明 |
|------|-----------|------|------|------|
| `name` | 必填 | string | — | 项目名称 |
| `--agent` | 可选 | string | 全部 | 只构建指定 Agent |
| `--tag` | 可选 | string | `&lt;project&gt;:&lt;agent&gt;-latest` | 自定义镜像 tag |
| `--no-cache` | 可选 | flag | `false` | 不使用 Docker 构建缓存 |
| `--push` | 可选 | string/flag | 未推送 | 推送到默认 registry，或指定自定义 URI |
| `--platform` | 可选 | string | — | 目标平台（如 `linux/amd64`） |
| `--build-arg` | 可选 | repeatable | `{}` | Docker `--build-arg` 透传 |

默认 registry：`533267047935.dkr.ecr.us-west-2.amazonaws.com/nexus-ai`。默认 base image：`public.ecr.aws/docker/library/python:3.12-slim`。

Dockerfile 位置：`deployment/&lt;project&gt;/&lt;agent&gt;/Dockerfile`（不存在时自动从模板生成）。构建日志目录：`logs/builds/`（可由 `config/build_config.yaml` 覆盖）。

推送时若 ECR 仓库不存在，默认自动创建（启用 AES256 加密、镜像扫描、生命周期策略保留 100 张镜像）。

## `agents` — Agent 管理

### 子命令

| 子命令 | 作用 |
|--------|------|
| `list` | 列出所有 Agent |
| `describe` | 查看 Agent 详情 |
| `build` | 部署 Agent 到 AgentCore |
| `delete` | 删除 Agent（本地目录 + 可选云资源） |

### `agents list`

**Usage:**

```bash
./nexus-cli agents list [--project <name>] [--output json|table|text]
```

| 参数 | 必填/可选 | 类型 | 默认 | 说明 |
|------|-----------|------|------|------|
| `--project` | 可选 | string | — | 按项目过滤 |
| `--output`, `-o` | 可选 | `json`\|`table`\|`text` | `table` | 输出格式 |

仅列出 `agents/generated_agents/` 下的 Agent；排除 `agents/system_agents/` 与 `agents/template_agents/`。

### `agents describe`

**Usage:**

```bash
./nexus-cli agents describe <name> [--output json|table|text]
```

### `agents build`

**Usage:**

```bash
./nexus-cli agents build <project> [--dry-run] [--yes]
```

部署项目的 Agent 到 AWS Bedrock AgentCore：执行就绪检查 → 确认 → 构建并推送镜像 → 创建 Runtime → 更新 DynamoDB 项目状态。输出包含 `Agent ID`、`Runtime ARN`、`Alias ARN`、`Status`。

### `agents delete`

**Usage:**

```bash
./nexus-cli agents delete <name> [--include-cloud] [--force] [--dry-run]
```

| 参数 | 必填/可选 | 类型 | 默认 | 说明 |
|------|-----------|------|------|------|
| `name` | 必填 | string | — | Agent 名称 |
| `--include-cloud` | 可选 | flag | `false` | 同时删除 AgentCore Runtime、ECR 仓库、DynamoDB Agent 记录 |
| `--force` | 可选 | flag | `false` | 跳过确认 |
| `--dry-run` | 可选 | flag | `false` | 仅预览 |

未指定 `--include-cloud` 时，云资源不会被删除；检测到的云资源会显示提示。

## `chat` — Agent 对话

**Usage:**

```bash
./nexus-cli chat <agent-name> [--env <env>] [--version <ver>] \
  [--model default|lite|pro|<full-model-id>] [--session-id <id>]
```

| 参数 | 必填/可选 | 类型 | 默认 | 说明 |
|------|-----------|------|------|------|
| `agent-name` | 必填 | string | — | Agent 短名或 `generated_agents_prompts/&lt;project&gt;/&lt;agent&gt;` 路径 |
| `--env` | 可选 | string | `production` | 环境配置 |
| `--version` | 可选 | string | `latest` | Agent 版本 |
| `--model` | 可选 | string | `default` | `default`/`lite`/`pro`/完整 model ID |
| `--session-id` | 可选 | string | 自动生成 | 会话 ID（启用持久化） |

会话存储于 `.sessions/&lt;session-id&gt;/`（由 Strands `FileSessionManager` 管理）。

**多模态输入：** 消息中使用 `@` 语法附加文件或 URL：

| 附件类型 | 示例 |
|----------|------|
| 本地图片 | `分析这张图片 @/path/to/image.png` |
| 多个文件 | `对比这两份 @file1.py @file2.py` |
| 带空格路径 | `@"path with spaces/file.txt"` |
| HTTP URL | `总结这篇 @https://example.com/article.html` |
| 图片 URL | `描述图片 @https://example.com/photo.jpg` |

支持的图片格式：`.png`、`.jpg`、`.jpeg`、`.gif`、`.webp`。

支持的文本/代码格式：`.txt`、`.md`、`.csv`、`.json`、`.yaml`、`.yml`、`.py`、`.js`、`.ts`、`.java`、`.go`、`.rs`、`.rb`、`.html`、`.css`、`.xml`、`.sql`、`.sh`、`.bash`、`.log`、`.ini`、`.cfg`、`.conf`、`.toml`。

支持的文档格式（提取文本）：`.pdf`、`.docx`、`.xlsx`、`.xls`、`.pptx`。

URL 下载上限：`NEXUS_MAX_FETCH_SIZE`（默认 100 MB）。

## `artifact` — S3 工件管理

将本地 Agent 同步到 S3，支持跨环境版本管理。

### 子命令

| 子命令 | 作用 |
|--------|------|
| `push` | 推送本地 Agent 到 S3 |
| `pull` | 从 S3 拉取 Agent 到本地 |
| `sync` | 同步单个 Agent（常用缩写） |
| `list` | 列出已同步 Agent |
| `versions` | 列出某 Agent 的所有版本 |
| `describe` | 查看版本详情 |
| `delete` | 删除版本（可选同时删除 S3 对象） |

### `artifact push`

**Usage:**

```bash
./nexus-cli artifact push [--all | <agent>] \
  [--version-tag <tag>] [--notes <text>] [--workspace-id <id>]
```

| 参数 | 必填/可选 | 类型 | 默认 | 说明 |
|------|-----------|------|------|------|
| `--all` | 可选 | flag | — | 推送所有本地 Agent |
| `&lt;agent&gt;` | 可选 | string | — | 指定 Agent 名称（与 `--all` 互斥） |
| `--version-tag` | 可选 | string | `""` | 版本标签 |
| `--notes` | 可选 | string | `""` | 版本备注 |
| `--workspace-id` | 可选 | string | 当天日期格式 | workspace ID |

### `artifact pull`

**Usage:**

```bash
./nexus-cli artifact pull [--all | <agent>] \
  [--version-uuid <uuid>] [--workspace-id <id>] [--force]
```

| 参数 | 必填/可选 | 类型 | 默认 | 说明 |
|------|-----------|------|------|------|
| `--all` | 可选 | flag | — | 拉取所有 Agent |
| `&lt;agent&gt;` | 可选 | string | — | 指定 Agent |
| `--version-uuid` | 可选 | string | 最新版本 | 具体版本 UUID |
| `--workspace-id` | 可选 | string | 最新 workspace | workspace ID |
| `--force` | 可选 | flag | `false` | 覆盖本地文件 |

### `artifact list` / `versions` / `describe` / `delete`

| 命令 | 作用 | 关键参数 |
|------|------|---------|
| `artifact list` | 列出所有已同步 Agent（按 workspace 分组） | `--workspace-id`、`--output` |
| `artifact versions &lt;agent&gt;` | 列出 Agent 的所有版本 | `--output` |
| `artifact describe &lt;agent&gt; &lt;version-uuid&gt;` | 查看版本详情 | `--output` |
| `artifact delete &lt;agent&gt; &lt;version-uuid&gt;` | 删除版本元数据 | `--delete-s3`（同时删除 S3 对象）、`--force` |

## `backup` — 备份管理

| 子命令 | Usage | 说明 |
|--------|-------|------|
| `backup list` | `backup list [--output json\|table\|text]` | 列出 `backups/` 目录下所有 `.tar.gz` |
| `backup describe &lt;file&gt;` | `backup describe &lt;filename&gt; [--output ...]` | 显示 manifest、校验和、资源列表 |
| `backup validate &lt;path&gt;` | `backup validate &lt;path&gt;` | 验证压缩包结构、manifest 存在性、SHA-256 校验和、资源路径完整性 |
| `backup delete &lt;file&gt;` | `backup delete &lt;filename&gt; [--force]` | 删除备份文件（默认要求确认） |

`backup describe` JSON 输出包含：`name`、`path`、`project_name`、`created_at`、`size`、`size_mb`、`format`、`checksum`、完整 `manifest`（含 `version`、`nexus_version`、`resources`、`checksums`、`metadata`）。

## `job` — 任务与队列管理

| 子命令 | Usage | 说明 |
|--------|-------|------|
| `job list` | `job list [--status &lt;s&gt;] [--type &lt;t&gt;]` | 列出任务；显示状态筛选与队列统计 |
| `job view &lt;id&gt;` | `job view &lt;task-id&gt;` | 查看单个任务详情 |
| `job clear` | `job clear [--force]` | **危险：** 清空所有 DynamoDB 表和 SQS 队列 |
| `job delete &lt;agent&gt;` | `job delete &lt;agent-name&gt; [--force]` | 删除指定 Agent 的全部数据（DynamoDB 记录、会话、调用、消息） |

`job clear` 会依次执行：清空所有 DynamoDB 表（按主键扫描后逐条删除）→ 清空所有 SQS 队列（`purge_queue`）→ 汇总删除计数。若队列正处于 `PurgeQueueInProgress` 状态则跳过。

## `service` — 服务管理

管理 Nexus-AI 的后台服务进程。

### 服务类型

| 服务 | 值 | 默认端口 | 说明 |
|------|-----|---------|------|
| `api` | `api` | `8000` | FastAPI 主服务（uvicorn） |
| `worker` | `worker` | — | SQS 消费者 Worker |
| `web` | `web` | `3000` | Next.js Web 前端 |
| `mcp` | `mcp` | `9000` | MCP 服务 |
| `event` | `event` | — | 事件调度器 |
| `bridge` | `bridge` | `8001` | Bridge 服务 |
| `otel` | `otel` | `4318` | OpenTelemetry Collector（OTLP HTTP） |
| `sandbox_controller` | `sandbox_controller` | `8002` | Sandbox Controller（仅启用沙箱时） |

核心服务（始终显示于 `service status`）：`bridge`、`api`、`worker`、`web`。可选服务仅在有 PID 或正在运行时显示。

### 子命令

| 子命令 | Usage | 说明 |
|--------|-------|------|
| `service start` | `service start [&lt;service&gt;\|all]` | 启动单个服务或全部（默认 all） |
| `service stop` | `service stop [&lt;service&gt;\|all] [--force]` | 停止服务；`--force` 用 SIGKILL |
| `service restart` | `service restart [&lt;service&gt;\|all]` | 重启 |
| `service status` | `service status [--output ...]` | 显示状态（running/stopped/unknown）、PID、端口、日志路径 |
| `service logs` | `service logs &lt;service&gt; [--follow] [--lines <N>]` | 查看日志，`logs/&lt;service&gt;.log` |

进程管理：PID 文件在 `.pids/&lt;service&gt;.pid`，日志文件在 `logs/&lt;service&gt;.log`。启动 API 时若端口被占用会先杀掉占用进程，等待 3 秒，然后写入 PID。

API 运行参数（从 `config/service_config.yaml` 读取）：`workers`、`thread_pool_size`、`agent_creation_timeout`、`agent_stream_timeout`、`sse_heartbeat_interval`、`max_concurrent_streams`、`log_level`。

## `deploy` — 云环境部署

通过 CloudFormation 在 AWS 上部署完整 Nexus-AI 环境（VPC + EC2 + Aurora + Valkey + CloudFront + 可选 SSO + 可选 Sandbox）。

### 子命令

| 子命令 | 作用 |
|--------|------|
| `up` | 创建新环境（CloudFormation + 可选 SSO + 可选 Sandbox） |
| `down` | 删除环境，可选同时清理数据 |
| `status` | 查看环境状态 |
| `list` | 列出所有已部署环境 |
| `sso-finalize` | 完成 SSO 配置（在主栈创建后手动执行） |

状态持久化于 `.deploys/&lt;env-prefix&gt;/state.json`（通过 atomic rename 写入，防止 Ctrl+C 损坏）。状态值：`pending` / `creating` / `complete` / `deleting` / `deleted` / `failed`。

### `deploy up`

**Usage:**

```bash
./nexus-cli deploy up <env-prefix> [options...]
```

| 参数 | 必填/可选 | 类型 | 默认 | 说明 |
|------|-----------|------|------|------|
| `env-prefix` | 必填 | string | — | 环境前缀（如 `nexus-ai-test`）；生成 stack 名 `&lt;prefix&gt;-stack` |
| `--config`, `-c` | 可选 | path | — | YAML 配置文件（CLI 参数优先级更高） |
| `--instance-type` | 可选 | string | `c8i.2xlarge` | EC2 实例类型 |
| `--branch` | 可选 | string | `main` | Git 分支 |
| `--user` | 可选 | string | `admin` | 认证用户名 |
| `--password` | 可选 | string | `nexus` | 认证密码 |
| `--github-token` | 可选 | string | — | GitHub PAT |
| `--db-password` | 可选 | string | `Nexus2026!` | Aurora PostgreSQL 密码 |
| `--key-name` | 可选 | string | `Og_Normal` | EC2 SSH Key Pair 名称 |
| `--iam-instance-profile` | 可选 | string | `admin-for-ec2` | EC2 IAM Instance Profile |
| `--volume-size` | 可选 | int | `150` | EC2 根卷大小（GB） |
| `--vpc-cidr` | 可选 | string | `10.0.0.0/16` | VPC CIDR |
| `--git-repo-url` | 可选 | string | `https://github.com/hy714335634/Nexus-AI.git` | Git 仓库 URL |
| `--region` | 可选 | string | 读自 `config/default_config.yaml` 的 `aws.aws_region_name`，fallback `us-west-2` | AWS 区域 |
| `--enable-sso` | 可选 | flag | `false` | 启用 IAM Identity Center SSO |
| `--allowed-email-domains` | 可选 | repeatable | `[]` | SSO 允许的邮箱域名 |
| `--enable-sandbox` | 可选 | flag | `false` | 主栈后自动部署 Sandbox Runtime |
| `--sandbox-instance-type` | 可选 | string | `c8i.xlarge` | Sandbox EC2 实例类型（必须支持 KVM） |
| `--sandbox-pool-size` | 可选 | int | `1` | Sandbox EC2 节点数 |
| `--sandbox-default-runtime` | 可选 | `local`\|`ec2` | `ec2` | Sandbox 默认运行时 |
| `--sandbox-runtimes` | 可选 | 逗号列表 | `local,ec2` | 允许的运行时 |
| `--sandbox-prewarm-vms` | 可选 | int | `1` | 每个节点预热 VM 数 |
| `--sandbox-max-nodes` | 可选 | int | `5` | 自动扩缩容上限 |
| `--no-wait` | 可选 | flag | `false` | 不等待栈创建完成 |
| `--yes`, `-y` | 可选 | flag | `false` | 跳过确认 |

**Pre-flight 检查项（全部必须通过）：**

| 检查 | 说明 |
|------|------|
| AWS Credentials | boto3 能正常发起调用 |
| CF Template | `infrastructure/cloudformation/nexus-ai-env.yaml` 存在 |
| Key Pair | `--key-name` 在目标区域存在 |
| IAM Profile | `--iam-instance-profile` 存在 |
| Stack Available | 同名 stack 未被占用 |
| SSO Instance | 启用 SSO 时验证 IAM Identity Center 实例存在 |

**CloudFormation 参数：** CLI 会自动组装以下 `ParameterKey`：`EnvironmentPrefix`、`InstanceType`、`KeyName`、`IamInstanceProfile`、`VpcCidr`、`VolumeSize`、`GitRepoUrl`、`GitBranch`、`GitHubToken`、`AuthUser`、`AuthPassword`、`DBPassword`、`AuroraMinCapacity`（默认 `0.5`）、`AuroraMaxCapacity`（默认 `16`）、`ValkeyMaxDataGB`（默认 `5`）、`ValkeyMaxECPU`（默认 `15000`）、`EnableSandbox`、`SandboxEFSId`。

**CloudFormation Stack 命名规则：**

| 派生值 | 计算规则 | 示例（`nexus-ai-test`） |
|--------|---------|-------------------------|
| Stack 名 | `&lt;env-prefix&gt;-stack` | `nexus-ai-test-stack` |
| DynamoDB 前缀 | `&lt;env-prefix&gt;` 中连字符转下划线 + `_` | `nexus_ai_test_` |
| SQS 前缀 | `&lt;env-prefix&gt;-` | `nexus-ai-test-` |
| S3 后缀 | 去掉 `nexus-ai-` 前缀 | `test` |
| SSO 用户组 | `&lt;env-prefix&gt;-users` | `nexus-ai-test-users` |

**Stack Outputs（成功后解析）：** `VPCId`、`PublicSubnets`、`PrivateSubnets`、`NATGatewayIP`、`CloudFrontDomainName`、`CloudFrontDistributionId`、`ALBDNSName`、`EC2InstanceId`、`EC2PublicIP`、`EC2PrivateIP`、`SSHCommand`、`AppDirectory`、`DynamoDBTablePrefix`、`SQSQueuePrefix`、`AccessURL`、`AuroraEndpoint`、`AuroraPort`、`AuroraDBName`、`ValkeyEndpoint`、`ValkeyPort`。

**示例：**

```bash
./nexus-cli deploy up nexus-ai-test --github-token ghp_xxx
./nexus-cli deploy up nexus-ai-test --enable-sso --github-token ghp_xxx
./nexus-cli deploy up nexus-ai-test --config deploy.yaml
./nexus-cli deploy up nexus-ai-prod \
  --instance-type c8i.4xlarge \
  --volume-size 300 \
  --enable-sandbox \
  --sandbox-pool-size 3 \
  --yes
```

### `deploy down`

**Usage:**

```bash
./nexus-cli deploy down <env-prefix> [--clean-data] [--yes]
```

| 参数 | 必填/可选 | 类型 | 默认 | 说明 |
|------|-----------|------|------|------|
| `env-prefix` | 必填 | string | — | 要删除的环境 |
| `--clean-data` | 可选 | flag | `false` | 同时删除 S3 桶、DynamoDB 表、SQS 队列 |
| `--yes`, `-y` | 可选 | flag | `false` | 跳过确认 |

::: warning
`--clean-data` 不可逆。已有的项目数据（artifact S3 桶、session 桶、attachment 桶、DynamoDB 表内容、SQS 队列）全部会被清空。
:::

### `deploy status` / `deploy list`

| 命令 | 说明 |
|------|------|
| `deploy status &lt;env-prefix&gt;` | 查看单个环境的 stack 状态、Outputs、SSO 状态、健康检查 |
| `deploy list` | 列出所有 `.deploys/*/state.json` 中记录的环境 |

### `deploy sso-finalize`

**Usage:**

```bash
./nexus-cli deploy sso-finalize <env-prefix> --idp-metadata-url <URL>
```

手动在 IAM Identity Center 控制台完成 SAML 应用配置后，用该命令回填 IdP metadata URL，写入 EC2 配置并重启服务。

## `sandbox` — Sandbox 运行时管理

::: info
`sandbox` 命令仅在 `config/default_config.yaml` 中 `default-config.nexus_ai.sandbox.enabled: true` 时可用；否则调用会显示提示并以退出码 0 结束。
:::

### 子命令

| 子命令 | 作用 |
|--------|------|
| `overview` | 树形总览：节点 → VM → agent / session |
| `list` | 以表格形式列出 VM 实例 |
| `nodes` | 列出 EC2 计算节点 |
| `logs` | 查看调度日志 |
| `runtime` | 查看或切换默认运行时（`local`/`ec2`） |
| `launch` | 手动启动计算节点 |
| `terminate` | 手动终止计算节点 |
| `scale-down` | 缩容空闲节点（运行在主 EC2 的集中式缩容） |
| `rebuild-rootfs` | 重建 VM rootfs 镜像（依赖变更后使用） |

### `sandbox runtime`

**Usage:**

```bash
./nexus-cli sandbox runtime [local|ec2] [--yes]
```

| 参数 | 必填/可选 | 类型 | 默认 | 说明 |
|------|-----------|------|------|------|
| `mode` | 可选 | `local`\|`ec2` | — | 不传则显示当前状态 |
| `--yes`, `-y` | 可选 | flag | `false` | 跳过确认 |

切换行为：
- `ec2 → local`：新会话走本地；已运行的沙箱会话继续执行完；Controller 在所有 VM idle 后自动释放节点。
- `local → ec2`：Controller 启动节点并预热 VM；新会话等节点就绪后使用沙箱。

切换时直接修改 `config/default_config.yaml` 的 `default_runtime` 字段，重载配置，并自动调用 `service restart` 使新模式生效。

### `sandbox list`

**Usage:**

```bash
./nexus-cli sandbox list [--status idle|busy|failed]
```

列出所有 VM 实例，列：`VM ID`、`Status`、`Node`、`Port`、`Agent`、`Session`、`Age`、`Idle For`。离线节点上的 VM 会用红色 `✗` 标记。

### `sandbox overview`

`sandbox overview` 输出树形总览，顶层包含：运行时模式、节点类型、VM 规格（vCPU/MiB）、prewarm 数量、全局统计（在线节点、离线节点、总 VM、busy/idle/failed 计数）。

节点标签包含：在线状态（`●`/`○`）、node_id、private IP、VM 数（`X/max`）、busy/idle 计数、CPU 使用率、内存使用率、最后心跳时间。

VM 标签包含：状态图标（`◦` idle / `●` busy / `◌` warming / `✗` failed）、VM ID、port、状态、Agent 名、session、age、idle_for。

### 其它 sandbox 子命令

| 命令 | 关键参数 | 说明 |
|------|---------|------|
| `sandbox nodes` | `--output` | 列出计算节点（node_id、IP、状态、VM 数、资源使用） |
| `sandbox logs` | `--follow`、`--lines` | 查看调度器日志 |
| `sandbox launch` | `--count <N>` | 手动启动 N 个计算节点 |
| `sandbox terminate` | `&lt;node-id&gt;` | 终止指定节点 |
| `sandbox scale-down` | `--min-idle <N>` | 按 idle 时间缩容 |
| `sandbox rebuild-rootfs` | `--force` | 重建 rootfs 镜像（在 requirements.txt 变更后执行） |

## `init` — 初始化基础设施

**Usage:**

```bash
./nexus-cli init [--region <region>] [--skip-tables] [--skip-queues] [--skip-buckets]
```

根据 `config/default_config.yaml` 的 `nexus_ai.*` 与 `multimodal_parser.aws.s3_bucket` 配置：

1. 创建 DynamoDB 表（workflow 所需的所有表，含 TTL 属性配置）。
2. 创建 SQS 队列。
3. 创建 S3 桶：
   - `artifacts_s3_bucket`（用途 `artifacts`、无 CORS）
   - `session_storage_s3_bucket`（`session`、无 CORS）
   - `attachment_s3_bucket`（`attachment`、**启用 CORS**，用于前端 presigned URL 直传）
   - `event_workspace_s3_bucket`（`event_workspace`、无 CORS）
   - `multimodal_parser.aws.s3_bucket`（`multimodal`、无 CORS）

所有 S3 桶默认启用版本控制；如果桶已存在但 CORS 需要配置会更新 CORS。

区域默认来自 `config/default_config.yaml` 的 `aws.aws_region_name`，fallback `us-west-2`。

## `overview` — 系统总览

**Usage:**

```bash
./nexus-cli overview [--output json|table|text]
```

显示：
- 项目总数
- Agent 总数
- 模板总数
- Prompt 总数
- 工具总数

JSON 模式包含 `summary` 字段，便于用 `jq` 处理：

```bash
./nexus-cli overview --output json | jq '.summary'
```

## 退出码字典

| 退出码 | 含义 |
|--------|------|
| `0` | 成功；或 dry-run 完成；或 sandbox 未启用时的提示退出 |
| `1` | 通用错误（资源未找到、校验失败、命令执行失败、pre-flight 失败等） |

CLI 的所有异常都会被捕获并通过 `click.echo(..., err=True)` 打印到 stderr，然后 `sys.exit(1)`。

## 常见错误

| 错误消息 | 原因 | 解决 |
|----------|------|------|
| `Project '&lt;name&gt;' not found` | `projects/&lt;name&gt;/` 不存在 | 先用 `project init` 创建 |
| `Project '&lt;name&gt;' already exists` | 同名目录已存在 | 换名或用 `--force` |
| `Docker is not installed or not running` | 本机未安装或未启动 Docker | 安装 Docker 并启动 daemon |
| `Checksum Error` | 备份校验失败 | 先 `backup validate`；换更早的备份 |
| `Virtual environment not found` | `.venv/` 不存在 | 按 `docs/Installation.md` 创建 venv |
| `Stack &lt;name&gt; already exists` | CloudFormation 栈名冲突 | 换 `env-prefix` 或先 `deploy down` |
| `Sandbox is not enabled` | `default_config.yaml` 未开启 sandbox | 设置 `default-config.nexus_ai.sandbox.enabled: true` |
| `KVM not supported` | sandbox 实例类型不支持 KVM | 使用 `c8i.*` / `m8i.*` 等 bare metal 友好实例 |

## 相关文档

- 安装与初始化：参见 Getting Started 一节。
- Agent 部署完整流程：参见 Features › Agent 工厂。
- 云环境部署与 SSO：参见 Integrations › SSO / SAML。
- 配置参考：参见 Reference › 配置项。
