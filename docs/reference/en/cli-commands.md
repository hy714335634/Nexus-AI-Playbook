---
title: nexus-cli Commands
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - nexus-cli
    - nexus_utils/cli/**
  generated_at: 2026-05-09T01:02:11+00:00
  generated_by: docs-sync v2
---

# nexus-cli Commands

`nexus-cli` is Nexus-AI's kubectl-style command-line tool for managing projects, agents, backups, services, and cloud environments. The executable lives at the repository root (`nexus-cli`); the real entry point is `nexus_utils/cli/main.py`.

## Overview

| Property | Value |
|----------|-------|
| Executable | `./nexus-cli` (Python wrapper) |
| Python entry | `python -m nexus_utils.cli.main` |
| Version source | `config/app_manifest.yaml` → `app-manifest.version.current` |
| Output encoding | UTF-8 forced on stdout / stderr / `PYTHONIOENCODING` |
| Minimum Python | 3.9+ |
| CLI framework | `click >= 8.1.7` |
| Table rendering | `tabulate >= 0.9.0` + `rich` |
| YAML parsing | `pyyaml >= 6.0.1` |

Run `./nexus-cli --help` for top-level help; run `./nexus-cli &lt;command&gt; --help` for any subcommand.

## Global Options

These options come before any subcommand (`./nexus-cli [global-options] &lt;command&gt; ...`):

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `--base-path` | string | `.` | Base path to the Nexus-AI installation |
| `--lang` | `en` \| `zh` | `en` | Output language (affects i18n messages) |
| `--version` | flag | — | Print version and exit (`nexus-cli, version &lt;x.y.z&gt;`) |
| `--help` / `-h` | flag | — | Show help and exit |

## Command Index

| Command | Purpose | Subcommands |
|---------|---------|-------------|
| `project` | Manage projects (init, list, describe, build, backup, restore, delete) | 7 |
| `agents` | Manage AI agents (list, describe, build, delete) | 4 |
| `chat` | Chat with an agent interactively (multimodal input supported) | 1 (leaf) |
| `artifact` | Manage S3 artifacts (push, pull, sync, list, versions, describe, delete) | 7 |
| `backup` | Manage project backups (list, describe, validate, delete) | 4 |
| `job` | Manage tasks and queues (list, view, clear, delete) | 4 |
| `service` | Manage services (start, stop, restart, status, logs) | 5 |
| `deploy` | Manage cloud environments (up, down, status, list) | 4 |
| `sandbox` | Manage Sandbox Runtime (overview, list, nodes, logs, runtime, launch, terminate, scale-down, rebuild-rootfs) | 9 |
| `init` | Initialize infrastructure (DynamoDB tables, SQS queues, S3 buckets) | 0 (leaf) |
| `overview` | Display system-wide overview | 0 (leaf) |

::: tip
All formatted commands support three output modes: `table` (default, human-readable), `json` (for scripting), and `text` (plain). Select with `--output` or `-o`.
:::

## Environment Variables

nexus-cli reads the following environment variables at startup:

| Variable | Default | Description |
|----------|---------|-------------|
| `PYTHONIOENCODING` | `utf-8` | Forced to `utf-8` by the CLI if unset |
| `NEXUS_MAX_FETCH_SIZE` | `104857600` (100 MB) | Maximum download size for URL attachments in `chat` (bytes) |
| `API_PORT` | `8000` | API port used by `service` |
| `WEB_PORT` | `3000` | Web frontend port |
| `NEXUS_MCP_PORT` | `9000` | MCP service port |
| `BRIDGE_PORT` | `8001` | Bridge service port |
| `SANDBOX_CONTROLLER_PORT` | `8002` | Sandbox Controller port |
| `RUN_MODE` | `prod` | Service run mode (`dev` / `prod`) |
| `AWS_REGION` | Overridden by `config/default_config.yaml` `aws.aws_region_name` | Region passed to services on start |
| `LOG_LEVEL` | `INFO` | API/Worker log level |
| `NEXUS_THREAD_POOL_SIZE` | `64` | API thread-pool size (passed to child) |
| `NEXUS_AGENT_CREATION_TIMEOUT` | `120` | Agent creation timeout (seconds) |
| `NEXUS_AGENT_STREAM_TIMEOUT` | `300` | Agent stream timeout (seconds) |
| `NEXUS_SSE_HEARTBEAT_INTERVAL` | `15` | SSE heartbeat interval (seconds) |
| `NEXUS_MAX_CONCURRENT_STREAMS` | `0` (unlimited) | Concurrent SSE streams cap |

## `project` — Project Management

Manages the full lifecycle of a Nexus-AI project.

### Subcommands

| Subcommand | Purpose |
|------------|---------|
| `init` | Create a new project |
| `list` | List all projects |
| `describe` | Show project details |
| `build` | Build Docker images for the project |
| `backup` | Create a project backup |
| `restore` | Restore a project from a backup |
| `delete` | Delete a project and all related resources |

### `project list`

**Usage:**

```bash
./nexus-cli project list [--output json|table|text]
```

| Argument | Required | Type | Default | Description |
|----------|----------|------|---------|-------------|
| `--output`, `-o` | optional | `json`\|`table`\|`text` | `table` | Output format |

Table/text columns: `name`, `description`, `agents`, `templates`, `prompts`, `tools`, `created`. Description is truncated to 50 characters in the table. A `Total: <N> projects` line is appended.

**Examples:**

```bash
./nexus-cli project list
./nexus-cli project list --output json | jq '.projects[].name'
```

### `project describe`

**Usage:**

```bash
./nexus-cli project describe <name> [--output json|table|text]
```

| Argument | Required | Type | Default | Description |
|----------|----------|------|---------|-------------|
| `name` | required | string | — | Project name |
| `--output`, `-o` | optional | `json`\|`table`\|`text` | `text` | Output format |

Text-mode sections: `Description` / `Basic Information` (name, version, created, updated) / `Agents` (each agent's name, category, first 3 lines of description) / `Dependencies` (grouped as `strands_tools/*`, `generated_tools/*`, `tools/system_tools/*`, first 5 per group) / `Usage` (resource paths) / `Documentation` (README path if present).

JSON mode additionally includes `agent_details` (per-agent `name`/`description`/`category`/`tools`).

**Examples:**

```bash
./nexus-cli project describe my_project
./nexus-cli project describe my_project --output json
```

**Exit codes:**

- `0`: success
- `1`: project not found or read failure

### `project init`

**Usage:**

```bash
./nexus-cli project init <name> [--description <text>] [--dry-run]
```

| Argument | Required | Type | Default | Description |
|----------|----------|------|---------|-------------|
| `name` | required | string | — | New project name (used as directory name) |
| `--description`, `-d` | optional | string | `""` | Project description |
| `--dry-run` | optional | flag | `false` | Preview operations without writing files |

Creates the following layout:

```
projects/<name>/
├── agents/             # directory
├── config.yaml         # file
├── status.yaml         # file (initial overall_status=pending)
└── README.md           # file (contents: "# <name>\n\n<description>\n")
```

**Examples:**

```bash
./nexus-cli project init my_agent --description "Customer support agent"
./nexus-cli project init my_agent --dry-run
```

**Exit codes:**

- `0`: success or dry-run
- `1`: name exists, validation failure, or other error

### `project backup`

**Usage:**

```bash
./nexus-cli project backup <name> [--output <dir>] [--dry-run] \
  [--source-delete] [--sync-to-s3] [--notes <text>]
```

| Argument | Required | Type | Default | Description |
|----------|----------|------|---------|-------------|
| `name` | required | string | — | Project name |
| `--output`, `-o` | optional | path | `backups/` | Output directory |
| `--dry-run` | optional | flag | `false` | Preview resources to back up |
| `--source-delete` | optional | flag | `false` | Delete source directories after backup succeeds |
| `--sync-to-s3` | optional | flag | `false` | Upload backup to S3 after creation |
| `--notes` | optional | string | `""` | S3 version notes (requires `--sync-to-s3`) |

Archive filename pattern: `&lt;project-name&gt;_YYYYMMDD_HHMMSS.tar.gz`.

Backed-up content:
- All of `projects/&lt;name&gt;/`
- All `.py` files in `agents/generated_agents/&lt;name&gt;/`
- All `.yaml` files in `prompts/generated_agents_prompts/&lt;name&gt;/`
- All tools in `tools/generated_tools/&lt;name&gt;/`
- JSON manifest with SHA-256 checksums

**Examples:**

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

| Argument | Required | Type | Default | Description |
|----------|----------|------|---------|-------------|
| `name` | required | string | — | Target project name (may differ from backup → clone) |
| `--from-backup` | required | path | — | Path to backup `.tar.gz` |
| `--force` | optional | flag | `false` | Overwrite existing project (writes a safety backup first) |
| `--dry-run` | optional | flag | `false` | Preview restore |
| `--skip-sessions` | optional | flag | `false` | Skip session data restore |
| `--skip-ddb` | optional | flag | `false` | Skip DynamoDB record restore |
| `--skip-s3` | optional | flag | `false` | Skip S3 object restore |

SHA-256 verification runs automatically; a mismatch raises a `Checksum Error`.

**Examples:**

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

| Argument | Required | Type | Default | Description |
|----------|----------|------|---------|-------------|
| `name` | required | string | — | Project name |
| `--force` | optional | flag | `false` | Skip confirmation |
| `--dry-run` | optional | flag | `false` | Preview |

Removes:
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

| Argument | Required | Type | Default | Description |
|----------|----------|------|---------|-------------|
| `name` | required | string | — | Project name |
| `--agent` | optional | string | all | Build only the specified agent |
| `--tag` | optional | string | `&lt;project&gt;:&lt;agent&gt;-latest` | Custom image tag |
| `--no-cache` | optional | flag | `false` | Disable Docker build cache |
| `--push` | optional | string/flag | no push | Push to default registry or a custom URI |
| `--platform` | optional | string | — | Target platform (e.g. `linux/amd64`) |
| `--build-arg` | optional | repeatable | `{}` | Docker `--build-arg` pass-through |

Default registry: `533267047935.dkr.ecr.us-west-2.amazonaws.com/nexus-ai`. Default base image: `public.ecr.aws/docker/library/python:3.12-slim`.

Dockerfile path: `deployment/&lt;project&gt;/&lt;agent&gt;/Dockerfile` (auto-generated from a template if missing). Build logs: `logs/builds/` (overridable via `config/build_config.yaml`).

When pushing, the ECR repository is auto-created if missing (AES256 encryption, image scanning, lifecycle policy retaining 100 images).

## `agents` — Agent Management

### Subcommands

| Subcommand | Purpose |
|------------|---------|
| `list` | List all agents |
| `describe` | Show agent details |
| `build` | Deploy an agent to AgentCore |
| `delete` | Delete an agent (local dirs + optionally cloud resources) |

### `agents list`

**Usage:**

```bash
./nexus-cli agents list [--project <name>] [--output json|table|text]
```

| Argument | Required | Type | Default | Description |
|----------|----------|------|---------|-------------|
| `--project` | optional | string | — | Filter by project |
| `--output`, `-o` | optional | `json`\|`table`\|`text` | `table` | Output format |

Lists agents under `agents/generated_agents/` only; `agents/system_agents/` and `agents/template_agents/` are excluded.

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

Deploys a project's agent to AWS Bedrock AgentCore: readiness check → confirmation → build & push image → create Runtime → update project state in DynamoDB. Output includes `Agent ID`, `Runtime ARN`, `Alias ARN`, `Status`.

### `agents delete`

**Usage:**

```bash
./nexus-cli agents delete <name> [--include-cloud] [--force] [--dry-run]
```

| Argument | Required | Type | Default | Description |
|----------|----------|------|---------|-------------|
| `name` | required | string | — | Agent name |
| `--include-cloud` | optional | flag | `false` | Also delete AgentCore Runtime, ECR repository, DynamoDB agent records |
| `--force` | optional | flag | `false` | Skip confirmation |
| `--dry-run` | optional | flag | `false` | Preview |

Without `--include-cloud`, cloud resources are not deleted; detected resources are shown as a hint.

## `chat` — Agent Conversation

**Usage:**

```bash
./nexus-cli chat <agent-name> [--env <env>] [--version <ver>] \
  [--model default|lite|pro|<full-model-id>] [--session-id <id>]
```

| Argument | Required | Type | Default | Description |
|----------|----------|------|---------|-------------|
| `agent-name` | required | string | — | Short name or `generated_agents_prompts/&lt;project&gt;/&lt;agent&gt;` path |
| `--env` | optional | string | `production` | Environment profile |
| `--version` | optional | string | `latest` | Agent version |
| `--model` | optional | string | `default` | `default`/`lite`/`pro`/full model ID |
| `--session-id` | optional | string | auto-generated | Session ID (enables persistence) |

Sessions are stored under `.sessions/&lt;session-id&gt;/` (managed by Strands `FileSessionManager`).

**Multimodal input:** Use `@` syntax in the message to attach files or URLs:

| Attachment | Example |
|------------|---------|
| Local image | `Analyze this image @/path/to/image.png` |
| Multiple files | `Compare these @file1.py @file2.py` |
| Path with spaces | `@"path with spaces/file.txt"` |
| HTTP URL | `Summarize @https://example.com/article.html` |
| Image URL | `Describe @https://example.com/photo.jpg` |

Supported image formats: `.png`, `.jpg`, `.jpeg`, `.gif`, `.webp`.

Supported text/code formats: `.txt`, `.md`, `.csv`, `.json`, `.yaml`, `.yml`, `.py`, `.js`, `.ts`, `.java`, `.go`, `.rs`, `.rb`, `.html`, `.css`, `.xml`, `.sql`, `.sh`, `.bash`, `.log`, `.ini`, `.cfg`, `.conf`, `.toml`.

Supported document formats (text extraction): `.pdf`, `.docx`, `.xlsx`, `.xls`, `.pptx`.

URL download cap: `NEXUS_MAX_FETCH_SIZE` (default 100 MB).

## `artifact` — S3 Artifact Management

Syncs local agents to S3 with cross-environment version tracking.

### Subcommands

| Subcommand | Purpose |
|------------|---------|
| `push` | Push local agent(s) to S3 |
| `pull` | Pull agent(s) from S3 to local |
| `sync` | Sync a single agent (shortcut) |
| `list` | List synced agents |
| `versions` | List versions of a specific agent |
| `describe` | Show version details |
| `delete` | Delete a version (optionally remove S3 objects too) |

### `artifact push`

**Usage:**

```bash
./nexus-cli artifact push [--all | <agent>] \
  [--version-tag <tag>] [--notes <text>] [--workspace-id <id>]
```

| Argument | Required | Type | Default | Description |
|----------|----------|------|---------|-------------|
| `--all` | optional | flag | — | Push all local agents |
| `&lt;agent&gt;` | optional | string | — | Specific agent name (mutex with `--all`) |
| `--version-tag` | optional | string | `""` | Version tag |
| `--notes` | optional | string | `""` | Version notes |
| `--workspace-id` | optional | string | today's date-format ID | workspace ID |

### `artifact pull`

**Usage:**

```bash
./nexus-cli artifact pull [--all | <agent>] \
  [--version-uuid <uuid>] [--workspace-id <id>] [--force]
```

| Argument | Required | Type | Default | Description |
|----------|----------|------|---------|-------------|
| `--all` | optional | flag | — | Pull all agents |
| `&lt;agent&gt;` | optional | string | — | Specific agent |
| `--version-uuid` | optional | string | latest | Specific version UUID |
| `--workspace-id` | optional | string | latest workspace | workspace ID |
| `--force` | optional | flag | `false` | Overwrite local files |

### `artifact list` / `versions` / `describe` / `delete`

| Command | Purpose | Key Options |
|---------|---------|-------------|
| `artifact list` | List all synced agents (grouped by workspace) | `--workspace-id`, `--output` |
| `artifact versions &lt;agent&gt;` | List versions for an agent | `--output` |
| `artifact describe &lt;agent&gt; &lt;version-uuid&gt;` | Show version details | `--output` |
| `artifact delete &lt;agent&gt; &lt;version-uuid&gt;` | Delete version metadata | `--delete-s3` (also removes S3 objects), `--force` |

## `backup` — Backup Management

| Subcommand | Usage | Description |
|------------|-------|-------------|
| `backup list` | `backup list [--output json\|table\|text]` | List all `.tar.gz` files under `backups/` |
| `backup describe &lt;file&gt;` | `backup describe &lt;filename&gt; [--output ...]` | Show manifest, checksum, resource list |
| `backup validate &lt;path&gt;` | `backup validate &lt;path&gt;` | Verify archive structure, manifest, SHA-256 checksums, resource path integrity |
| `backup delete &lt;file&gt;` | `backup delete &lt;filename&gt; [--force]` | Delete a backup file (confirmation required by default) |

`backup describe` JSON output contains: `name`, `path`, `project_name`, `created_at`, `size`, `size_mb`, `format`, `checksum`, full `manifest` (with `version`, `nexus_version`, `resources`, `checksums`, `metadata`).

## `job` — Tasks & Queues

| Subcommand | Usage | Description |
|------------|-------|-------------|
| `job list` | `job list [--status &lt;s&gt;] [--type &lt;t&gt;]` | List tasks with status filter and queue statistics |
| `job view &lt;id&gt;` | `job view &lt;task-id&gt;` | Show task details |
| `job clear` | `job clear [--force]` | **Destructive:** clear all DynamoDB tables and SQS queues |
| `job delete &lt;agent&gt;` | `job delete &lt;agent-name&gt; [--force]` | Delete all data for an agent (DDB records, sessions, invocations, messages) |

`job clear` runs: truncate all DynamoDB tables (scan + per-key delete) → purge all SQS queues (`purge_queue`) → print delete counts. Queues in `PurgeQueueInProgress` state are skipped.

## `service` — Service Management

Manages Nexus-AI's background services.

### Service Types

| Service | Value | Default Port | Description |
|---------|-------|--------------|-------------|
| `api` | `api` | `8000` | FastAPI main service (uvicorn) |
| `worker` | `worker` | — | SQS consumer worker |
| `web` | `web` | `3000` | Next.js web frontend |
| `mcp` | `mcp` | `9000` | MCP service |
| `event` | `event` | — | Event scheduler |
| `bridge` | `bridge` | `8001` | Bridge service |
| `otel` | `otel` | `4318` | OpenTelemetry Collector (OTLP HTTP) |
| `sandbox_controller` | `sandbox_controller` | `8002` | Sandbox Controller (only when sandbox enabled) |

Core services (always shown in `service status`): `bridge`, `api`, `worker`, `web`. Optional services appear only when they have a PID or are running.

### Subcommands

| Subcommand | Usage | Description |
|------------|-------|-------------|
| `service start` | `service start [&lt;service&gt;\|all]` | Start one service or all (default: all) |
| `service stop` | `service stop [&lt;service&gt;\|all] [--force]` | Stop service(s); `--force` uses SIGKILL |
| `service restart` | `service restart [&lt;service&gt;\|all]` | Restart |
| `service status` | `service status [--output ...]` | Show status (running/stopped/unknown), PID, port, log path |
| `service logs` | `service logs &lt;service&gt; [--follow] [--lines <N>]` | Tail `logs/&lt;service&gt;.log` |

Process management: PID file at `.pids/&lt;service&gt;.pid`, log file at `logs/&lt;service&gt;.log`. When starting the API, a busy port is freed first (SIGTERM → wait 3 s), then the new PID is written.

API runtime parameters (loaded from `config/service_config.yaml`): `workers`, `thread_pool_size`, `agent_creation_timeout`, `agent_stream_timeout`, `sse_heartbeat_interval`, `max_concurrent_streams`, `log_level`.

## `deploy` — Cloud Environment Deployment

Deploys a full Nexus-AI environment on AWS via CloudFormation (VPC + EC2 + Aurora + Valkey + CloudFront + optional SSO + optional Sandbox).

### Subcommands

| Subcommand | Purpose |
|------------|---------|
| `up` | Create a new environment (CloudFormation + optional SSO + optional Sandbox) |
| `down` | Delete an environment, optionally wiping data |
| `status` | Show environment status |
| `list` | List deployed environments |
| `sso-finalize` | Finalize SSO setup (run after the main stack completes) |

State is persisted under `.deploys/&lt;env-prefix&gt;/state.json` (atomic rename write to survive Ctrl+C). Statuses: `pending` / `creating` / `complete` / `deleting` / `deleted` / `failed`.

### `deploy up`

**Usage:**

```bash
./nexus-cli deploy up <env-prefix> [options...]
```

| Argument | Required | Type | Default | Description |
|----------|----------|------|---------|-------------|
| `env-prefix` | required | string | — | Environment prefix (e.g. `nexus-ai-test`); stack name is `&lt;prefix&gt;-stack` |
| `--config`, `-c` | optional | path | — | YAML config file (CLI flags take precedence) |
| `--instance-type` | optional | string | `c8i.2xlarge` | EC2 instance type |
| `--branch` | optional | string | `main` | Git branch |
| `--user` | optional | string | `admin` | Auth username |
| `--password` | optional | string | `nexus` | Auth password |
| `--github-token` | optional | string | — | GitHub PAT |
| `--db-password` | optional | string | `Nexus2026!` | Aurora PostgreSQL password |
| `--key-name` | optional | string | `Og_Normal` | EC2 SSH key-pair name |
| `--iam-instance-profile` | optional | string | `admin-for-ec2` | EC2 IAM Instance Profile |
| `--volume-size` | optional | int | `150` | EC2 root volume size (GB) |
| `--vpc-cidr` | optional | string | `10.0.0.0/16` | VPC CIDR |
| `--git-repo-url` | optional | string | `https://github.com/hy714335634/Nexus-AI.git` | Git repo URL |
| `--region` | optional | string | From `config/default_config.yaml` `aws.aws_region_name`; fallback `us-west-2` | AWS region |
| `--enable-sso` | optional | flag | `false` | Enable IAM Identity Center SSO |
| `--allowed-email-domains` | optional | repeatable | `[]` | Allowed SSO email domains |
| `--enable-sandbox` | optional | flag | `false` | Deploy Sandbox Runtime after the main stack |
| `--sandbox-instance-type` | optional | string | `c8i.xlarge` | Sandbox EC2 instance type (must support KVM) |
| `--sandbox-pool-size` | optional | int | `1` | Number of sandbox EC2 nodes |
| `--sandbox-default-runtime` | optional | `local`\|`ec2` | `ec2` | Sandbox default runtime |
| `--sandbox-runtimes` | optional | csv | `local,ec2` | Allowed runtimes |
| `--sandbox-prewarm-vms` | optional | int | `1` | Prewarm VMs per node |
| `--sandbox-max-nodes` | optional | int | `5` | Auto-scaling cap |
| `--no-wait` | optional | flag | `false` | Do not wait for stack creation |
| `--yes`, `-y` | optional | flag | `false` | Skip confirmation |

**Pre-flight checks (all must pass):**

| Check | Description |
|-------|-------------|
| AWS Credentials | boto3 can make calls |
| CF Template | `infrastructure/cloudformation/nexus-ai-env.yaml` exists |
| Key Pair | `--key-name` exists in the target region |
| IAM Profile | `--iam-instance-profile` exists |
| Stack Available | No existing stack with the same name |
| SSO Instance | If SSO is enabled, IAM Identity Center instance exists |

**CloudFormation parameters:** the CLI auto-assembles the following `ParameterKey`s: `EnvironmentPrefix`, `InstanceType`, `KeyName`, `IamInstanceProfile`, `VpcCidr`, `VolumeSize`, `GitRepoUrl`, `GitBranch`, `GitHubToken`, `AuthUser`, `AuthPassword`, `DBPassword`, `AuroraMinCapacity` (default `0.5`), `AuroraMaxCapacity` (default `16`), `ValkeyMaxDataGB` (default `5`), `ValkeyMaxECPU` (default `15000`), `EnableSandbox`, `SandboxEFSId`.

**Naming rules derived from `env-prefix`:**

| Derived value | Rule | Example (`nexus-ai-test`) |
|---------------|------|---------------------------|
| Stack name | `&lt;env-prefix&gt;-stack` | `nexus-ai-test-stack` |
| DynamoDB prefix | hyphens → underscores, then append `_` | `nexus_ai_test_` |
| SQS prefix | `&lt;env-prefix&gt;-` | `nexus-ai-test-` |
| S3 suffix | strip `nexus-ai-` prefix | `test` |
| SSO user group | `&lt;env-prefix&gt;-users` | `nexus-ai-test-users` |

**Stack Outputs (parsed on success):** `VPCId`, `PublicSubnets`, `PrivateSubnets`, `NATGatewayIP`, `CloudFrontDomainName`, `CloudFrontDistributionId`, `ALBDNSName`, `EC2InstanceId`, `EC2PublicIP`, `EC2PrivateIP`, `SSHCommand`, `AppDirectory`, `DynamoDBTablePrefix`, `SQSQueuePrefix`, `AccessURL`, `AuroraEndpoint`, `AuroraPort`, `AuroraDBName`, `ValkeyEndpoint`, `ValkeyPort`.

**Examples:**

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

| Argument | Required | Type | Default | Description |
|----------|----------|------|---------|-------------|
| `env-prefix` | required | string | — | Environment to delete |
| `--clean-data` | optional | flag | `false` | Also delete S3 buckets, DynamoDB tables, SQS queues |
| `--yes`, `-y` | optional | flag | `false` | Skip confirmation |

::: warning
`--clean-data` is irreversible. Project data (artifact bucket, session bucket, attachment bucket, DynamoDB contents, SQS queues) will be wiped.
:::

### `deploy status` / `deploy list`

| Command | Description |
|---------|-------------|
| `deploy status &lt;env-prefix&gt;` | Show stack status, Outputs, SSO state, health check |
| `deploy list` | List all environments recorded under `.deploys/*/state.json` |

### `deploy sso-finalize`

**Usage:**

```bash
./nexus-cli deploy sso-finalize <env-prefix> --idp-metadata-url <URL>
```

After finishing the SAML application config in the IAM Identity Center console, use this command to write back the IdP metadata URL, update the EC2 config, and restart services.

## `sandbox` — Sandbox Runtime

::: info
`sandbox` commands are available only when `default-config.nexus_ai.sandbox.enabled: true` in `config/default_config.yaml`; otherwise the command prints a hint and exits with code 0.
:::

### Subcommands

| Subcommand | Purpose |
|------------|---------|
| `overview` | Tree view: nodes → VMs → agents / sessions |
| `list` | List VM instances as a table |
| `nodes` | List EC2 compute nodes |
| `logs` | View scheduler logs |
| `runtime` | View or switch default runtime (`local`/`ec2`) |
| `launch` | Launch compute node(s) manually |
| `terminate` | Terminate a compute node |
| `scale-down` | Scale down idle nodes (centralized, runs on main EC2) |
| `rebuild-rootfs` | Rebuild VM rootfs image (after dependency changes) |

### `sandbox runtime`

**Usage:**

```bash
./nexus-cli sandbox runtime [local|ec2] [--yes]
```

| Argument | Required | Type | Default | Description |
|----------|----------|------|---------|-------------|
| `mode` | optional | `local`\|`ec2` | — | Without argument, prints current state |
| `--yes`, `-y` | optional | flag | `false` | Skip confirmation |

Switch behavior:
- `ec2 → local`: new sessions run locally; in-flight sandbox sessions finish normally; controller auto-releases nodes when all VMs are idle.
- `local → ec2`: controller launches nodes and prewarms VMs; new sessions use sandbox once nodes are ready.

On switch, the CLI rewrites the `default_runtime` field in `config/default_config.yaml`, reloads the cached config, and calls `service restart` to apply the change.

### `sandbox list`

**Usage:**

```bash
./nexus-cli sandbox list [--status idle|busy|failed]
```

Lists all VM instances with columns: `VM ID`, `Status`, `Node`, `Port`, `Agent`, `Session`, `Age`, `Idle For`. VMs on an offline node are marked with a red `✗`.

### `sandbox overview`

`sandbox overview` prints a tree. The root summary shows runtime mode, node type, VM spec (vCPU/MiB), prewarm count, and global totals (online/offline nodes, total VMs, busy/idle/failed).

Node labels include: online indicator (`●` / `○`), node_id, private IP, VM count (`X/max`), busy/idle counts, CPU usage, memory usage, last heartbeat.

VM labels include: status icon (`◦` idle / `●` busy / `◌` warming / `✗` failed), VM ID, port, status, agent name, session, age, idle_for.

### Other sandbox subcommands

| Command | Key options | Description |
|---------|-------------|-------------|
| `sandbox nodes` | `--output` | List compute nodes (node_id, IP, status, VM count, resource usage) |
| `sandbox logs` | `--follow`, `--lines` | View scheduler logs |
| `sandbox launch` | `--count <N>` | Manually launch N compute nodes |
| `sandbox terminate` | `&lt;node-id&gt;` | Terminate a specific node |
| `sandbox scale-down` | `--min-idle <N>` | Scale down based on idle time |
| `sandbox rebuild-rootfs` | `--force` | Rebuild rootfs image (after requirements.txt changes) |

## `init` — Initialize Infrastructure

**Usage:**

```bash
./nexus-cli init [--region <region>] [--skip-tables] [--skip-queues] [--skip-buckets]
```

Using `nexus_ai.*` and `multimodal_parser.aws.s3_bucket` sections from `config/default_config.yaml`, the command:

1. Creates DynamoDB tables (all workflow tables, with TTL attributes where configured).
2. Creates SQS queues.
3. Creates S3 buckets:
   - `artifacts_s3_bucket` (purpose `artifacts`, no CORS)
   - `session_storage_s3_bucket` (`session`, no CORS)
   - `attachment_s3_bucket` (`attachment`, **CORS enabled** for presigned uploads from the frontend)
   - `event_workspace_s3_bucket` (`event_workspace`, no CORS)
   - `multimodal_parser.aws.s3_bucket` (`multimodal`, no CORS)

All S3 buckets have versioning enabled by default; if a bucket already exists but CORS is needed, CORS is reconciled.

Default region: `config/default_config.yaml` `aws.aws_region_name`, fallback `us-west-2`.

## `overview` — System Overview

**Usage:**

```bash
./nexus-cli overview [--output json|table|text]
```

Shows:
- Total projects
- Total agents
- Total templates
- Total prompts
- Total tools

JSON mode includes a `summary` field that is convenient for `jq`:

```bash
./nexus-cli overview --output json | jq '.summary'
```

## Exit Code Dictionary

| Exit code | Meaning |
|-----------|---------|
| `0` | Success; or dry-run completed; or sandbox disabled hint exit |
| `1` | Generic error (resource not found, validation failure, command failure, pre-flight failure, etc.) |

All exceptions are caught, printed to stderr via `click.echo(..., err=True)`, and the CLI exits with `sys.exit(1)`.

## Common Errors

| Message | Cause | Resolution |
|---------|-------|------------|
| `Project '&lt;name&gt;' not found` | `projects/&lt;name&gt;/` missing | Create it with `project init` |
| `Project '&lt;name&gt;' already exists` | Name collision | Choose a new name or use `--force` |
| `Docker is not installed or not running` | Docker absent or daemon down | Install Docker and start the daemon |
| `Checksum Error` | Backup verification failed | Run `backup validate`; try an older backup |
| `Virtual environment not found` | `.venv/` missing | Create a venv per `docs/Installation.md` |
| `Stack &lt;name&gt; already exists` | CloudFormation stack name conflict | Change `env-prefix` or run `deploy down` first |
| `Sandbox is not enabled` | Sandbox flag off in config | Set `default-config.nexus_ai.sandbox.enabled: true` |
| `KVM not supported` | Sandbox instance type can't host KVM | Use `c8i.*` / `m8i.*` or similar bare-metal-friendly instance |

## Related Documentation

- Installation & initialization: see Getting Started.
- Full agent deployment flow: see Features › Agent Factory.
- Cloud deployment & SSO: see Integrations › SSO / SAML.
- Configuration reference: see Reference › Configuration.
