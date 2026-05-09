---
title: Configuration Options
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - config/app_manifest.yaml
    - config/data_connector.yaml
    - config/default_config.yaml
    - config/eventschedule_config.yaml
    - config/logging_config.yaml
    - config/model_catalog.yaml
    - config/nexus_ai_base_rule.yaml
    - config/workflows.yaml
    - nexus_utils/config_loader.py
  generated_at: 2026-05-09T01:10:50+00:00
  generated_by: docs-sync v2
---

# Configuration Options

This page lists **every** YAML configuration item in Nexus-AI. All config files live under `config/` at the repo root and are loaded at runtime by `ConfigLoader` in `nexus_utils/config_loader.py`.

## 1. Loading mechanism

### 1.1 File paths

| File | Path | Top-level key | Purpose |
| --- | --- | --- | --- |
| Main config | `config/default_config.yaml` | `default-config` | Core platform settings |
| Service config | `config/service_config.yaml` | `service-config` | Runtime parameters for API / Worker / Web / MCP / Bridge / Sandbox Controller |
| App manifest | `config/app_manifest.yaml` | `app-manifest` | Branding, versioning, feature flags |
| Data connector | `config/data_connector.yaml` | `data_connector` / `key_management` | Data sources and key management |
| Event scheduler | `config/eventschedule_config.yaml` | `event_scheduler` | Scheduled jobs |
| Logging | `config/logging_config.yaml` | `enhanced_logging` / `strands_hooks` / `observability` | Logging and OTEL |
| Model catalog | `config/model_catalog.yaml` | `model_catalog` | Bedrock model listing |
| Base rules | `config/nexus_ai_base_rule.yaml` | `workflows` | Build / update / runtime rules |
| Workflows | `config/workflows.yaml` | — | Workflow stage definitions |

### 1.2 Precedence

`ConfigLoader.get_with_env_override()` uses:

```
environment variable > config file > code default
```

### 1.3 Access API

| Method | Purpose |
| --- | --- |
| `get(key, default)` | Read `default-config.&lt;key&gt;` |
| `get_section(name)` | Same as `get`, clearer semantics |
| `get_nested(*keys)` | Deep lookup, e.g. `get_nested("multimodal_parser", "aws", "s3_bucket")` |
| `get_with_env_override(env_var, *keys, default)` | Env var takes precedence |
| `get_aws_config()` / `get_bedrock_config()` / `get_strands_config()` / `get_agentcore_config()` / `get_nexus_ai_config()` / `get_mcp_config()` / `get_multimodal_parser_config()` / `get_aurora_config()` / `get_valkey_config()` / `get_s3_vectors_config()` / `get_logging_config()` / `get_workflow_config()` / `get_workflow_version_config()` / `get_workflow_stages()` / `get_dynamodb_config()` / `get_sqs_config()` / `get_service_config()` | Sub-section getters |
| `get_table_name(table_key)` | Returns a fully prefixed table name |
| `has_section(name)` / `list_sections()` | Introspection |
| `reload_config()` | Reload config |

---

## 2. `config/default_config.yaml`

Top-level key: `default-config`. All sections below are rooted at `default-config.&lt;section&gt;`.

### 2.1 `nexus_ai` — core platform

#### Base fields

| Key (YAML path) | Type | Default | Description |
| --- | --- | --- | --- |
| `nexus_ai.base_rule_path` | string | `config/nexus_ai_base_rule.yaml` | Path to base rules file |
| `nexus_ai.base_rule_version` | string | `latest` | Base rules version |
| `nexus_ai.OTEL_EXPORTER_OTLP_ENDPOINT` | string | `http://localhost:4318` | OTLP HTTP endpoint; overridable by env var of the same name |
| `nexus_ai.artifacts_s3_bucket` | string | `nexus-ai-artifacts-2026` | Artifact bucket (tools / agents / skills) |
| `nexus_ai.session_storage_s3_bucket` | string | `nexus-ai-session-2026` | Session storage bucket |
| `nexus_ai.attachment_s3_bucket` | string | `nexus-ai-attachments-2026` | Attachment bucket |
| `nexus_ai.attachment_presigned_url_expiry` | int (seconds) | `3600` | Attachment download presigned URL TTL |
| `nexus_ai.attachment_upload_url_expiry` | int (seconds) | `600` | Attachment upload presigned URL TTL |
| `nexus_ai.attachment_max_file_size` | int (bytes) | `52428800` | Max single attachment size (50 MB) |
| `nexus_ai.attachment_max_files_per_message` | int | `5` | Max attachments per message |
| `nexus_ai.auto_sync_to_s3` | bool | `true` | Auto-sync to S3 |
| `nexus_ai.event_workspace_s3_bucket` | string | `nexus-ai-event-workspace-2026` | Event task workspace bucket |

#### `nexus_ai.workflow_default_version`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `workflow_default_version.agent_build` | string | `latest` | Default Agent build workflow version |
| `workflow_default_version.agent_update` | string | `latest` | Default Agent update workflow version |
| `workflow_default_version.tool_build` | string | `latest` | Default tool build workflow version |
| `workflow_default_version.skill_build` | string | `latest` | Default skill build workflow version |

#### `nexus_ai.file_sharing`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `file_sharing.default_ttl` | int (seconds) | `86400` | Default share link TTL (1 day) |
| `file_sharing.max_ttl` | int (seconds) | `604800` | Max share link TTL (7 days) |
| `file_sharing.share_code_length` | int | `16` | Share code character length |
| `file_sharing.resolution_presign_ttl` | int (seconds) | `3600` | Resolution presigned URL TTL |
| `file_sharing.public_base_url` | string | `''` | Public share base URL |

#### `nexus_ai.templates`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `templates.s3_bucket` | string | `''` | Template bucket; empty reuses `attachment_s3_bucket` |
| `templates.s3_key_prefix` | string | `templates/` | Template S3 key prefix |
| `templates.efs_subdir` | string | `/templates` | EFS subdir `/templates/{asset_id}/v{n}/` |
| `templates.upload_url_expiry` | int (seconds) | `600` | Upload URL TTL |
| `templates.max_file_size` | int (bytes) | `104857600` | Max template size (100 MB) |
| `templates.allowed_extensions` | list[string] | `[pptx, docx, xlsx, pdf, html, htm, md, txt, png, jpg]` | Allowed extensions |
| `templates.preview_text_max_bytes` | int (bytes) | `102400` | Max preview text size (100 KB) |
| `templates.preview_workers` | int | `4` | Preview worker processes |
| `templates.ai_enabled` | bool | `true` | Enable AI analysis |
| `templates.ai_analyze_model` | string | `us.anthropic.claude-haiku-4-5-20251001-v1:0` | Analysis model ID |
| `templates.ai_embed_model` | string | `amazon.titan-embed-text-v2:0` | Embedding model ID |
| `templates.ai_embed_dim` | int | `1024` | Embedding dimension |
| `templates.ai_diff_model` | string | `us.anthropic.claude-haiku-4-5-20251001-v1:0` | Diff analysis model |
| `templates.libreoffice_bin` | string | `libreoffice` | LibreOffice binary path |
| `templates.imagemagick_bin` | string | `convert` | ImageMagick `convert` path |

#### `nexus_ai.backup`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `backup.share_mode` | string | `local` | Backup share mode |
| `backup.share_default_ttl` | int (hours) | `24` | Default backup share TTL |
| `backup.share_max_ttl` | int (hours) | `168` | Max backup share TTL (7 days) |
| `backup.share_cleanup_days` | int | `7` | Backup cleanup days |
| `backup.max_backup_size` | int (bytes) | `536870912` | Max backup size (512 MB) |
| `backup.hub_url` | string | `''` | Backup hub URL |
| `backup.public_api_url` | string | `''` | Backup public API URL |

#### `nexus_ai.remote_terminal`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `remote_terminal.enabled` | bool | `true` | Enable remote terminal |
| `remote_terminal.type` | string | `http` | Connection type |
| `remote_terminal.token_expiry_seconds` | int | `600` | Token TTL |
| `remote_terminal.connection_timeout_seconds` | int | `300` | Connection timeout |
| `remote_terminal.command_timeout_seconds` | int | `120` | Command timeout |
| `remote_terminal.max_output_length` | int | `50000` | Max output chars per call |
| `remote_terminal.heartbeat_interval_seconds` | int | `30` | Heartbeat interval |
| `remote_terminal.http_poll_interval_seconds` | int | `1` | HTTP poll interval |
| `remote_terminal.websocket_path` | string | `/api/v2/remote/ws` | WebSocket path |
| `remote_terminal.nexus_host` | string | `localhost` | Target host |
| `remote_terminal.nexus_port` | int | `8000` | Target port |
| `remote_terminal.use_ssl` | bool | `false` | Use SSL |
| `remote_terminal.max_connections_per_session` | int | `5` | Max connections per session |
| `remote_terminal.reconnect_token_expiry_seconds` | int | `86400` | Reconnect token TTL (1 day) |

#### `nexus_ai.runtime_workspace`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `runtime_workspace.local_base_dir` | string | `.cache` | Local workspace root |
| `runtime_workspace.s3_prefix` | string | `workspace/` | S3 prefix |
| `runtime_workspace.auto_sync` | bool | `true` | Auto-sync |
| `runtime_workspace.sync_on_edit` | bool | `true` | Sync on edit |
| `runtime_workspace.presigned_url_expiry` | int (seconds) | `3600` | Presigned URL TTL |
| `runtime_workspace.max_workspace_size` | int (bytes) | `524288000` | Max workspace size (500 MB) |
| `runtime_workspace.inline_content_max_size` | int (bytes) | `1048576` | Max inline content size (1 MB) |
| `runtime_workspace.cleanup_on_session_delete` | bool | `true` | Clean up on session delete |

#### `nexus_ai.conversation_manager`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `conversation_manager.enabled` | bool | `true` | Enable conversation manager |
| `conversation_manager.type` | string | `summarizing` | `sliding_window` or `summarizing` |
| `conversation_manager.sliding_window.window_size` | int | `50` | Sliding window size |
| `conversation_manager.sliding_window.should_truncate_results` | bool | `true` | Truncate tool results |
| `conversation_manager.summarizing.summary_ratio` | float | `0.3` | Summarization ratio |
| `conversation_manager.summarizing.preserve_recent_messages` | int | `30` | Preserve most recent messages |
| `conversation_manager.summarizing.use_custom_agent` | bool | `true` | Use custom summarizer agent |
| `conversation_manager.summarizing.custom_agent_model_id` | string | `us.anthropic.claude-haiku-4-5-20251001-v1:0` | Summarizer model |
| `conversation_manager.summarizing.custom_agent_prompt_path` | string | `system_agents_prompts/conversation_summarizer/conversation_summarizer` | Summarizer prompt path |

#### `nexus_ai.auth`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `auth.user` | string | `admin` | Default admin username |
| `auth.password` | string | `nexus` | Default admin password (must change in production) |
| `auth.secret_key` | string | `''` | JWT signing key |
| `auth.enforce_auth` | bool | `true` | Enforce authentication |
| `auth.default_role_on_first_login` | string | `admin` | Default role for first login |

#### `nexus_ai.sso`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `sso.enabled` | bool | `false` | Enable SAML SSO |
| `sso.idp_metadata_url` | string | `https://portal.sso.xxxxx/saml/metadata/xxxxx` | IdP metadata URL |
| `sso.idp_metadata_xml` | string | `''` | IdP metadata XML (inline) |
| `sso.sp_entity_id` | string | `nexus-ai-sp` | SP entity ID |
| `sso.sp_acs_url` | string | `http://localhost:8000/api/v2/auth/sso/acs` | SP ACS URL |
| `sso.sp_sls_url` | string | `http://localhost:8000/api/v2/auth/sso/sls` | SP SLS URL |
| `sso.idp_logout_url` | string | `https://portal.sso.xxxxx/saml/logout/xxxxx` | IdP logout URL |
| `sso.frontend_url` | string | `http://localhost:3000` | Frontend URL |
| `sso.jwt_expire_hours` | int | `24` | JWT expiration in hours |
| `sso.allowed_email_domains` | list[string] | `[]` | Allowed email domains |
| `sso.dev_user.name` | string | `Dev Admin` | Dev mode username |
| `sso.dev_user.email` | string | `admin@dev.local` | Dev mode email |
| `sso.dev_user.role` | string | `admin` | Dev mode role |

#### `nexus_ai.sandbox`

##### Top level

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `sandbox.enabled` | bool | `false` | Enable sandbox (EC2 + Firecracker) |

##### `sandbox.policy`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `sandbox.policy.default_runtime` | string | `ec2` | `local` / `ec2` / `agentcore` |
| `sandbox.policy.allow_user_override` | bool | `true` | Allow user override |
| `sandbox.policy.allowed_runtimes` | list[string] | `[local, ec2]` | Allowed runtimes |
| `sandbox.policy.max_concurrent_vms` | int | `50` | Global VM cap |

##### `sandbox.config`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `sandbox.config.efs_code_id` | string | `''` | Code EFS FileSystem ID |
| `sandbox.config.efs_code_mount` | string | `/nexus-efs` | Host code mount |
| `sandbox.config.repo_root` | string | `/nexus-efs/nexus-ai` | Repo root |
| `sandbox.config.vm_code_mount` | string | `/code` | microVM code mount |
| `sandbox.config.efs_data_id` | string | `''` | Data EFS FileSystem ID |
| `sandbox.config.efs_data_mount` | string | `/nexus-efs-data` | Data mount |
| `sandbox.config.workspace_prefix` | string | `workspaces` | Workspace prefix |
| `sandbox.config.envs_prefix` | string | `envs` | venv prefix |
| `sandbox.config.events_prefix` | string | `events` | Events prefix |
| `sandbox.config.rootfs_path` | string | `/local/rootfs/base.ext4` | Firecracker rootfs template |
| `sandbox.config.session_s3_bucket` | string | `''` | Session bucket (inherits if empty) |
| `sandbox.config.valkey_endpoint` | string | `''` | Valkey endpoint (inherits if empty) |
| `sandbox.config.valkey_port` | int | `6379` | Valkey port |
| `sandbox.config.valkey_ssl` | bool | `true` | Valkey SSL |
| `sandbox.config.dynamodb_table_prefix` | string | `''` | DDB prefix (inherits if empty) |
| `sandbox.config.firecracker_bin` | string | `/opt/firecracker/firecracker` | Firecracker binary |
| `sandbox.config.kernel_path` | string | `/opt/firecracker/vmlinux` | Kernel path |
| `sandbox.config.vm_work_dir` | string | `/local/fc-work` | VM overlay work dir |
| `sandbox.config.vm_vcpu` | int | `1` | vCPU per VM |
| `sandbox.config.vm_memory_mib` | int | `1536` | Memory per VM (MiB, 1.5 GB) |
| `sandbox.config.vm_port` | int | `8080` | runtime_app port inside VM |
| `sandbox.config.vm_boot_timeout` | int (seconds) | `30` | VM boot health timeout |
| `sandbox.config.bridge_name` | string | `br0` | Host bridge name |
| `sandbox.config.bridge_cidr` | string | `172.16.0.0/24` | VM subnet |
| `sandbox.config.bridge_gateway` | string | `172.16.0.1` | Gateway |
| `sandbox.config.stream_maxlen` | int | `5000` | Stream max length |
| `sandbox.config.invocation_timeout` | int (seconds) | `600` | Agent invocation timeout |
| `sandbox.config.idle_timeout` | int (seconds) | `300` | VM idle destroy |
| `sandbox.config.log_level` | string | `INFO` | Log level |
| `sandbox.config.host_port` | int | `8080` | sandbox-host HTTP port |
| `sandbox.config.proxy_port_range_start` | int | `18001` | VM proxy port start |
| `sandbox.config.proxy_port_range_end` | int | `18100` | VM proxy port end (100 VMs per node) |

##### `sandbox.pool`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `sandbox.pool.instance_type` | string | `c8id.xlarge` | Instance type (KVM-capable) |
| `sandbox.pool.min_size` | int | `1` | ASG min size |
| `sandbox.pool.max_size` | int | `5` | ASG max size |
| `sandbox.pool.desired_size` | int | `1` | Desired size |
| `sandbox.pool.vms_per_node` | int | `0` | VMs per node (0=auto) |
| `sandbox.pool.key_name` | string | `''` | SSH key pair name |
| `sandbox.pool.cluster_name` | string | `''` | Cluster name (filled by CF) |
| `sandbox.pool.subnets` | list[string] | `[]` | Subnets (filled by CF) |
| `sandbox.pool.security_groups` | list[string] | `[]` | Security groups (filled by CF) |
| `sandbox.pool.prewarm_featured_agents` | bool | `false` | Pre-warm featured agent VMs |
| `sandbox.pool.prewarm_idle_vms` | int | `0` | Pre-warm idle VMs |

### 2.2 `workflow`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `workflow.config_file` | string | `config/workflows.yaml` | Workflow definition file |

### 2.3 `aws`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `aws.bedrock_region_name` | string | `us-west-2` | Bedrock region |
| `aws.aws_region_name` | string | `us-west-2` | Default AWS region |
| `aws.aws_profile_name` | string | `''` | AWS profile name |
| `aws.aws_access_key_id` | string | `''` | Access key ID |
| `aws.aws_secret_access_key` | string | `''` | Secret key |
| `aws.endpoint_url` | string | `''` | Custom endpoint (e.g. LocalStack) |
| `aws.verify` | bool | `true` | Verify TLS certs |
| `aws.connect_timeout` | int (seconds) | `7200` | Connect timeout |

### 2.4 `strands`

#### `strands.retry_strategy`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `strands.retry_strategy.enabled` | bool | `true` | Enable retries |
| `strands.retry_strategy.max_attempts` | int | `6` | Max attempts |
| `strands.retry_strategy.initial_delay` | int (seconds) | `4` | Initial delay |
| `strands.retry_strategy.max_delay` | int (seconds) | `128` | Max delay |

#### `strands.template`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `strands.template.agent_template_path` | string | `agents/template_agents` | Agent template dir |
| `strands.template.prompt_template_path` | string | `prompts/template_prompts` | Prompt template dir |
| `strands.template.tool_template_path` | string | `tools/template_tools` | Tool template dir |

#### `strands.generated`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `strands.generated.agent_generated_path` | string | `agents/generated_agents` | Generated agent dir |
| `strands.generated.prompt_generated_path` | string | `prompts/generated_agents_prompts` | Generated prompt dir |
| `strands.generated.tool_generated_path` | string | `tools/generated_tools` | Generated tool dir |

#### `strands.system`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `strands.system.agents_path` | string | `agents/system_agents` | System agent dir |
| `strands.system.prompts_path` | string | `prompts/system_agents_prompts` | System prompt dir |
| `strands.system.tools_path` | string | `tools/system_tools` | System tool dir |

#### Others

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `strands.requirements_path` | string | `templates/requirements/requirements.txt` | Requirements template |
| `strands.mcp_server_path` | string | `config/mcp/` | MCP config dir |
| `strands.project_path` | string | `project/` | Project dir |
| `strands.default_tools` | list[string] | `[calculator, shell, file_read, file_write]` | Default tools |

### 2.5 `agentcore`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `agentcore.execution_role_arn` | string | `''` | AgentCore execution role ARN |
| `agentcore.auto_create_execution_role` | bool | `true` | Auto-create execution role |
| `agentcore.ecr_auto_create` | bool | `true` | Auto-create ECR |
| `agentcore.runtime_timeout_minutes` | int | `30` | Runtime timeout (minutes) |
| `agentcore.enable_xray` | bool | `false` | Enable X-Ray |
| `agentcore.deploy_dry_run` | bool | `false` | Dry-run deploy |
| `agentcore.default_alias` | string | `DEFAULT` | Default alias |
| `agentcore.post_deploy_test` | bool | `false` | Post-deploy test |
| `agentcore.post_deploy_test_prompt` | string | `Hello` | Test prompt |
| `agentcore.auto_update_on_conflict` | bool | `true` | Auto-update on conflict |

### 2.6 `bedrock`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `bedrock.model_id` | string | `us.anthropic.claude-sonnet-4-5-20250929-v1:0` | Default model |
| `bedrock.lite_model_id` | string | `us.anthropic.claude-haiku-4-5-20251001-v1:0` | Lite model |
| `bedrock.pro_model_id` | string | `us.anthropic.claude-opus-4-5-20251101-v1:0` | Pro model |
| `bedrock.connect_config.retries.max_attempts` | int | `100` | Max retry attempts |
| `bedrock.connect_config.retries.mode` | string | `adaptive` | Retry mode |
| `bedrock.connect_config.connect_timeout` | int (seconds) | `3600` | Connect timeout |
| `bedrock.connect_config.read_timeout` | int (seconds) | `7200` | Read timeout |
| `bedrock.prompt_caching.enabled` | bool | `true` | Enable prompt caching |
| `bedrock.prompt_caching.cache_system_prompt` | bool | `true` | Cache system prompt |
| `bedrock.prompt_caching.cache_tools` | bool | `true` | Cache tool definitions |

### 2.7 `logging`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `logging.level` | string | `INFO` | Log level |
| `logging.file_path` | string | `logs/nexus_ai.log` | Log file path |
| `logging.format` | string | `%(asctime)s - %(name)s - %(levelname)s - %(message)s` | Log format |

### 2.8 `observability`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `observability.enabled` | bool | `false` | Enable observability (off locally by default) |
| `observability.prefix` | string | `NexusAI` | Naming prefix |
| `observability.capture.tool_input` | string | `hash_only` | `none` / `hash_only` / `redacted_preview` |
| `observability.capture.tool_output` | string | `hash_only` | Same as above |
| `observability.capture.system_prompt` | bool | `false` | Capture system prompt |
| `observability.capture.user_query` | string | `redacted_preview` | Same as tool_input |
| `observability.capture.bedrock_response` | bool | `false` | Capture Bedrock response body |
| `observability.sampling.development` | float | `1.0` | Dev sampling rate |
| `observability.sampling.production` | float | `0.1` | Prod sampling rate |

### 2.9 `dynamodb`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `dynamodb.table_prefix` | string | `nexus_` | Table name prefix |

#### `dynamodb.tables`

All short names are concatenated with `table_prefix` to produce the final table name.

| Short key | Default short name | Default full name |
| --- | --- | --- |
| `tasks` | `tasks` | `nexus_tasks` |
| `tools` | `tools` | `nexus_tools` |
| `clarifications` | `clarifications` | `nexus_clarifications` |
| `dynamic_configs` | `dynamic_configs` | `nexus_dynamic_configs` |
| `event_jobs` | `event_jobs` | `nexus_event_jobs` |
| `event_tasks` | `event_tasks` | `nexus_event_tasks` |
| `remote_connections` | `remote_connections` | `nexus_remote_connections` |
| `connectors` | `connectors` | `nexus_connectors` |
| `keys` | `keys` | `nexus_keys` |
| `key_usage_logs` | `key_usage_logs` | `nexus_key_usage_logs` |
| `directives` | `directives` | `nexus_directives` |
| `policies` | `policies` | `nexus_policies` |
| `audit_logs` | `audit_logs` | `nexus_audit_logs` |
| `mcp_servers` | `mcp_servers` | `nexus_mcp_servers` |
| `system_configs` | `system_configs` | `nexus_system_configs` |
| `backup_shares` | `backup_shares` | `nexus_backup_shares` |
| `file_shares` | `file_shares` | `nexus_file_shares` |
| `bridge_command_rules` | `bridge_command_rules` | `nexus_bridge_command_rules` |
| `sandbox_instances` | `sandbox_instances` | `nexus_sandbox_instances` |
| `sandbox_logs` | `sandbox_logs` | `nexus_sandbox_logs` |
| `sandbox_nodes` | `sandbox_nodes` | `nexus_sandbox_nodes` |
| `session_template_bindings` | `session_template_bindings` | `nexus_session_template_bindings` |

### 2.10 `sqs`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `sqs.queue_prefix` | string | `nexus-` | Queue name prefix |
| `sqs.queues.build` | string | `build-queue` | Build queue short name |
| `sqs.queues.deploy` | string | `deploy-queue` | Deploy queue short name |
| `sqs.queues.notification` | string | `notification-queue` | Notification queue short name |
| `sqs.dlq.build` | string | `build-dlq` | Build DLQ |
| `sqs.dlq.deploy` | string | `deploy-dlq` | Deploy DLQ |
| `sqs.build_visibility_timeout` | int (seconds) | `3600` | Build visibility timeout |
| `sqs.deploy_visibility_timeout` | int (seconds) | `600` | Deploy visibility timeout |
| `sqs.visibility_timeout` | int (seconds) | `3600` | Default visibility timeout |
| `sqs.message_retention_days` | int | `14` | Message retention days |
| `sqs.max_retry_count` | int | `3` | Max retry count |

### 2.11 `aurora`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `aurora.host` | string | `my-nexus-demo-db.cluster-c7g64s2w4e6g.ap-southeast-1.rds.amazonaws.com` | Cluster endpoint |
| `aurora.port` | int | `5432` | Port |
| `aurora.database` | string | `nexus_connector_psql` | Database name |
| `aurora.username` | string | `postgres` | Username |
| `aurora.password` | string | `admin123` | Password (must change in production) |
| `aurora.min_connections` | int | `2` | Min connections |
| `aurora.max_connections` | int | `20` | Max connections |
| `aurora.ssl` | bool | `true` | Enable SSL |

### 2.12 `valkey`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `valkey.endpoint` | string | `''` | Valkey endpoint |
| `valkey.port` | int | `6379` | Port |
| `valkey.ssl` | bool | `true` | Enable SSL |
| `valkey.decode_responses` | bool | `true` | Decode responses |
| `valkey.max_connections` | int | `50` | Max connections |

### 2.13 `s3_vectors`

#### `s3_vectors.embedding`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `embedding.model_id` | string | `global.cohere.embed-v4:0` | Embedding model |
| `embedding.dimension` | int | `1536` | Dimension |
| `embedding.distance_metric` | string | `cosine` | Distance metric |
| `embedding.batch_size` | int | `500` | Batch size |
| `embedding.input_type` | string | `search_document` | Input type |

#### `s3_vectors.rerank`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `rerank.enabled` | bool | `true` | Enable rerank |
| `rerank.model_id` | string | `cohere.rerank-v3-5:0` | Rerank model |
| `rerank.top_n` | int | `5` | Top N |
| `rerank.min_relevance_score` | float | `0.3` | Min relevance score |

#### `s3_vectors.query`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `query.default_top_k` | int | `10` | Default Top K |
| `query.search_source_types` | list[string] | `[system, template, generated]` | Search scope |

#### Others

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `s3_vectors.bucket_prefix` | string | `nexus-ai-vectors-` | Bucket prefix |
| `s3_vectors.buckets.system` | string | `system` | System bucket |
| `s3_vectors.buckets.agent` | string | `agent` | Agent bucket |
| `s3_vectors.indexes.prefix` | string | `nexus` | Index prefix |
| `s3_vectors.indexes.asset_types` | list[string] | `[tools, prompts, agents]` | Asset types |
| `s3_vectors.indexes.source_types` | list[string] | `[system, template, generated]` | Source types |
| `s3_vectors.metadata.non_filterable_keys` | list[string] | `[description, file_path, s3_content_key]` | Non-filterable metadata keys |

### 2.14 `multimodal_parser`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `multimodal_parser.aws.s3_bucket` | string | `awesome-nexus-ai-file-storage` | Multimodal S3 bucket |
| `multimodal_parser.aws.s3_prefix` | string | `multimodal-content/` | S3 prefix |
| `multimodal_parser.aws.bedrock_region` | string | `us-west-2` | Bedrock region |
| `multimodal_parser.file_limits.max_file_size` | string | `50MB` | Max single file |
| `multimodal_parser.file_limits.max_files_per_request` | int | `10` | Max files per request |
| `multimodal_parser.file_limits.supported_formats` | list[string] | `[jpg, jpeg, png, gif, txt, xlsx, docx, csv]` | Supported formats |
| `multimodal_parser.processing.timeout_seconds` | int | `300` | Processing timeout |
| `multimodal_parser.processing.retry_attempts` | int | `3` | Retry attempts |
| `multimodal_parser.processing.batch_size` | int | `5` | Batch size |
| `multimodal_parser.storage.presigned_url_expiration` | int (seconds) | `3600` | Presigned URL TTL |
| `multimodal_parser.storage.cleanup_days` | int | `30` | Cleanup days |
| `multimodal_parser.storage.max_retries` | int | `3` | Storage retries |
| `multimodal_parser.storage.retry_delay` | float | `1.0` | Retry delay (seconds) |
| `multimodal_parser.model.primary_model` | string | `us.anthropic.claude-opus-4-5-20251101-v1:0` | Primary model |
| `multimodal_parser.model.fallback_model` | string | `us.anthropic.claude-sonnet-4-5-20250929-v1:0` | Fallback model |
| `multimodal_parser.model.max_tokens` | int | `40000` | Max tokens |

---

## 3. `config/logging_config.yaml`

### 3.1 `enhanced_logging`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `enhanced_logging.enable_colors` | bool | `true` | Color output |
| `enhanced_logging.log_to_file` | bool | `true` | Write to file |
| `enhanced_logging.log_file` | string | `logs/enhanced_workflow.log` | Log file |
| `enhanced_logging.log_level` | string | `DEBUG` | DEBUG / INFO / WARNING / ERROR / CRITICAL |
| `enhanced_logging.show_timestamp` | bool | `true` | Show timestamp |
| `enhanced_logging.show_agent_name` | bool | `true` | Show agent name |
| `enhanced_logging.show_tool_details` | bool | `true` | Show tool details |
| `enhanced_logging.truncate_length.input` | int | `300` | Input truncate length |
| `enhanced_logging.truncate_length.output` | int | `300` | Output truncate length |
| `enhanced_logging.truncate_length.tool_result` | int | `200` | Tool result truncate length |
| `enhanced_logging.separators.workflow` | string | `=` | Workflow separator |
| `enhanced_logging.separators.agent` | string | `-` | Agent separator |
| `enhanced_logging.separators.tool` | string | `.` | Tool separator |

#### `enhanced_logging.colors`

| Key | Default |
| --- | --- |
| `colors.workflow_start` | `GREEN` |
| `colors.workflow_end` | `GREEN` |
| `colors.agent_start` | `BLUE` |
| `colors.agent_end` | `GREEN` |
| `colors.tool_call` | `MAGENTA` |
| `colors.tool_result` | `GREEN` |
| `colors.error` | `RED` |
| `colors.warning` | `YELLOW` |
| `colors.info` | `BLUE` |
| `colors.timestamp` | `GRAY` |
| `colors.separator` | `GRAY` |

### 3.2 `strands_hooks`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `strands_hooks.enable_enhanced_logging` | bool | `true` | Enable enhanced logging hook |
| `strands_hooks.log_all_agent_calls` | bool | `true` | Log all agent calls |
| `strands_hooks.log_all_tool_calls` | bool | `true` | Log all tool calls |
| `strands_hooks.log_arguments` | bool | `true` | Log call arguments |
| `strands_hooks.log_results` | bool | `true` | Log call results |
| `strands_hooks.sensitive_fields` | list[string] | `[password, token, key, secret]` | Redacted field names |

### 3.3 `observability` (OTEL runtime detail)

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `observability.service_name` | string | `nexus-ai` | OTEL `service.name` |
| `observability.environment` | string | `development` | `development` / `staging` / `production` |
| `observability.otlp_endpoint` | string | `http://localhost:4318` | ADOT Collector endpoint |
| `observability.traces.enabled` | bool | `true` | Enable traces |
| `observability.traces.sample_rate` | float | `1.0` | Sample rate (prod: 0.1-0.5 recommended) |
| `observability.traces.propagator` | string | `composite` | `composite` / `xray` / `tracecontext` / `b3` |
| `observability.metrics.enabled` | bool | `true` | Enable metrics |
| `observability.metrics.export_interval_ms` | int | `60000` | Export interval (ms) |
| `observability.logs` | object | `{}` | Reserved for extension |

---

## 4. `config/app_manifest.yaml`

Top-level key: `app-manifest`. Frontend fetches via `GET /api/v2/manifest`.

### 4.1 `product`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `product.name` | string | `Nexus AI` | Product name (sidebar, login title) |
| `product.short_name` | string | `Nexus` | Short name (browser tab, notifications) |
| `product.tagline` | string | `Agent Intelligence Platform` | Tagline |
| `product.description` | string | `AI Agent Development & Management Platform` | Description |

### 4.2 `version`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `version.current` | string | `0.2.5` | SemVer version |
| `version.release_date` | string | `2026-04-29` | Release date |
| `version.build_number` | string | `''` | Filled by CI/CD (git SHA) |
| `version.api_version` | string | `v2` | API version |

### 4.3 `branding`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `branding.logo_url` | string | `/logo.png` | Primary logo |
| `branding.logo_dark_url` | string | `''` | Dark-mode logo (optional) |
| `branding.favicon_url` | string | `/favicon.ico` | Favicon |
| `branding.primary_color` | string | `#7c3aed` | Primary color (purple-600) |
| `branding.accent_color` | string | `#2563eb` | Accent color (blue-600) |

### 4.4 `organization`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `organization.name` | string | `''` | Company name |
| `organization.website` | string | `''` | Website |
| `organization.support_email` | string | `''` | Support email |
| `organization.documentation_url` | string | `''` | Documentation URL |

### 4.5 `legal`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `legal.copyright` | string | `2026 Nexus AI Platform` | Copyright text |
| `legal.terms_url` | string | `''` | Terms of service URL |
| `legal.privacy_url` | string | `''` | Privacy policy URL |

### 4.6 `i18n`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `i18n.default_locale` | string | `zh-CN` | Default locale |
| `i18n.supported_locales` | list[string] | `[zh-CN, en]` | Supported locales |
| `i18n.fallback_locale` | string | `zh-CN` | Fallback locale |
| `i18n.allow_user_switch` | bool | `true` | Allow user switching |

### 4.7 `features`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `features.show_version_badge` | bool | `true` | Show version badge |
| `features.show_documentation_link` | bool | `true` | Show documentation link |
| `features.allow_agent_export` | bool | `true` | Allow agent export |
| `features.allow_tool_creation` | bool | `true` | Allow tool creation |
| `features.max_agents_per_user` | int | `0` | Max agents per user (0=unlimited) |
| `features.max_concurrent_sessions` | int | `0` | Max concurrent sessions per user (0=unlimited) |

### 4.8 `deployment`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `deployment.environment` | string | `production` | `development` / `staging` / `production` |
| `deployment.show_env_badge` | bool | `true` | Show env badge for non-prod |
| `deployment.instance_id` | string | `''` | Multi-tenant instance ID |

### 4.9 `login`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `login.title` | string | `''` | Login title (falls back to `product.name`) |
| `login.subtitle` | string | `''` | Login subtitle (falls back to `product.tagline`) |
| `login.background_style` | string | `gradient` | `gradient` / `image` / `solid` |
| `login.background_image_url` | string | `''` | Background image (when style=image) |
| `login.show_copyright` | bool | `true` | Show copyright |
| `login.custom_notice` | string | `''` | Custom notice (e.g. maintenance) |

---

## 5. `config/data_connector.yaml`

### 5.1 `data_connector` top level

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `data_connector.enabled` | bool | `true` | Global switch |
| `data_connector.supported_types` | list[string] | `[mysql, postgresql, s3, dynamodb, http_api, opensearch, s3_vector, bedrock_kb]` | Supported source types |

### 5.2 `data_connector.pool_defaults`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `pool_defaults.pool_size` | int | `5` | Pool size |
| `pool_defaults.max_overflow` | int | `10` | Max overflow |
| `pool_defaults.pool_timeout` | int (seconds) | `30` | Acquire timeout |
| `pool_defaults.pool_recycle` | int (seconds) | `3600` | Connection recycle time |

### 5.3 `data_connector.query_defaults`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `query_defaults.max_rows` | int | `1000` | Max rows per query |
| `query_defaults.max_execution_time` | int (seconds) | `30` | Query timeout |
| `query_defaults.allow_write` | bool | `false` | Allow writes |
| `query_defaults.allow_ddl` | bool | `false` | Allow DDL |
| `query_defaults.blocked_keywords` | list[string] | `[DROP, TRUNCATE, ALTER]` | SQL blocklist |

### 5.4 `data_connector.s3_defaults`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `s3_defaults.max_file_size` | int (bytes) | `104857600` | Max single file (100 MB) |
| `s3_defaults.supported_formats` | list[string] | `[csv, json, jsonl, parquet, txt, xlsx, yaml]` | Supported formats |
| `s3_defaults.presigned_url_expiry` | int (seconds) | `3600` | Presigned URL TTL |

### 5.5 `data_connector.vector_defaults`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `vector_defaults.top_k` | int | `10` | Default Top-K |
| `vector_defaults.similarity_threshold` | float | `0.7` | Similarity threshold |
| `vector_defaults.embedding_model` | string | `amazon.titan-embed-text-v2:0` | Default embedding model |

### 5.6 `data_connector.http_api_defaults`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `http_api_defaults.timeout` | int (seconds) | `30` | Request timeout |
| `http_api_defaults.max_retries` | int | `3` | Max retries |
| `http_api_defaults.retry_delay` | float (seconds) | `1.0` | Retry delay |

### 5.7 `data_connector.health_check`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `health_check.enabled` | bool | `true` | Enable health check |
| `health_check.interval` | int (seconds) | `60` | Check interval |
| `health_check.timeout` | int (seconds) | `5` | Check timeout |

### 5.8 `data_connector.audit`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `audit.enabled` | bool | `true` | Enable audit |
| `audit.log_query` | bool | `true` | Log query text |
| `audit.log_result_count` | bool | `true` | Log row count |
| `audit.log_execution_time` | bool | `true` | Log execution time |
| `audit.retention_days` | int | `90` | Retention days |

### 5.9 `data_connector.masking_defaults`

An array; each item has `column_pattern` and `strategy`. Defaults:

| column_pattern | strategy |
| --- | --- |
| `*password*` | `replace` |
| `*secret*` | `replace` |
| `*token*` | `partial` |

Values for `strategy`: `partial` / `hash` / `replace` / `null`.

### 5.10 `data_connector.prompts`

Per-source prompt templates injected into the agent system prompt. Variables supported: `{connector_name}`, `{connector_id}`, `{connector_type}`, `{database}`, `{bucket}`, `{prefix}`, `{base_url}`, `{table_name}`, `{max_rows}`, `{permission}`, `{write_hint}`, `{region}`, `{endpoint_url}`, `{index_name}`, `{knowledge_base_id}`.

| Key | Purpose |
| --- | --- |
| `prompts.header` | Shared header |
| `prompts.mysql` | MySQL |
| `prompts.postgresql` | PostgreSQL |
| `prompts.s3` | S3 |
| `prompts.dynamodb` | DynamoDB |
| `prompts.http_api` | HTTP API |
| `prompts.opensearch` | OpenSearch |
| `prompts.s3_vector` | S3 Vectors |
| `prompts.bedrock_kb` | Bedrock Knowledge Base |
| `prompts.vector` | Generic vector database |

### 5.11 `key_management`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `key_management.storage_backend` | string | `secrets_manager` | `secrets_manager` / `local` (dev only) |
| `key_management.secrets_manager.prefix` | string | `nexus-ai/keys/` | Secret name prefix |
| `key_management.secrets_manager.region` | string | `''` | AWS region (inherits if empty) |
| `key_management.secrets_manager.kms_key_id` | string | `''` | Custom KMS key |

### 5.12 `key_management.key_type_schemas`

Each key type declares `label`, `label_en`, `icon`, `description`, `fields`.

| Key | `label` | `label_en` | `icon` | Description |
| --- | --- | --- | --- | --- |
| `api_key` | `API 密钥` | `API Key` | `key` | Third-party API access key |
| `database_credentials` | `数据库凭证` | `Database Credentials` | `database` | MySQL/PostgreSQL connection credentials |
| `bearer_token` | `Bearer Token` | `Bearer Token` | `shield` | OAuth / Bearer Token |
| `aws_credentials` | `AWS 凭证` | `AWS Credentials` | `cloud` | Access Key / Secret Key |
| `oauth2` | `OAuth 2.0` | `OAuth 2.0` | `lock` | OAuth 2.0 client credentials |
| `custom` | `自定义密钥` | `Custom` | `settings` | User-defined fields |

Field details (`fields[*]`): each item has `name`, `label`, `label_en`, `type` (`text` / `password` / `number`), `required`, `placeholder`, and optional `default`.

| Type | Fields |
| --- | --- |
| `api_key` | `api_key` (password, required) |
| `database_credentials` | `host` (text, required), `port` (number, default `3306`), `database` (text), `username` (text, required), `password` (password, required) |
| `bearer_token` | `token` (password, required) |
| `aws_credentials` | `access_key_id` (password, required), `secret_access_key` (password, required), `session_token` (password) |
| `oauth2` | `client_id` (text, required), `client_secret` (password, required), `token_url` (text) |
| `custom` | `[]` (user-added dynamically) |

---

## 6. `config/eventschedule_config.yaml`

Top-level key: `event_scheduler`.

### 6.1 `scheduler`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `scheduler.job_scan_interval_seconds` | int | `60` | Job scan interval |
| `scheduler.task_scan_interval_seconds` | int | `10` | Task scan interval |
| `scheduler.max_concurrent_tasks` | int | `5` | Max concurrent tasks |
| `scheduler.task_timeout_seconds` | int | `3600` | Per-task timeout |
| `scheduler.stuck_task_threshold_seconds` | int | `7200` | Stuck task threshold |
| `scheduler.retry_on_failure` | bool | `false` | Retry on failure |
| `scheduler.max_retry_count` | int | `0` | Max retries |

### 6.2 `workspace`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `workspace.local_base_dir` | string | `.event` | Local workspace root |
| `workspace.s3_bucket_config_key` | string | `event_workspace_s3_bucket` | Main-config key to read bucket name from |
| `workspace.output_file_name` | string | `agent_response.out` | Agent output filename |
| `workspace.summary_file_name` | string | `task_summary.md` | Summary filename |
| `workspace.max_output_size_bytes` | int | `10485760` | Max output size (10 MB) |

### 6.3 `agent_runtime`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `agent_runtime.default_model_id` | string | `''` | Default model (empty = global) |
| `agent_runtime.lite_model_for_analysis` | bool | `true` | Use lite model for analysis |
| `agent_runtime.analysis_max_tokens` | int | `4096` | Analysis max tokens |
| `agent_runtime.analysis_temperature` | float | `0.2` | Analysis temperature |
| `agent_runtime.suppress_empty_results` | bool | `true` | Suppress empty results |
| `agent_runtime.empty_result_tokens` | list[string] | `[HEARTBEAT_OK, NO_ACTION_NEEDED, NOTHING_TO_REPORT, TASK_SKIPPED]` | Tokens treated as empty |

### 6.4 `task_type_prompts`

Template keys; values are multi-line strings with variables `{workspace_s3_path}`, `{task_id}`, `{sequence_number}`, `{scheduled_at}`, `{schedule_expression}`, `{mission_context}`.

| Key | Task type | Main variables |
| --- | --- | --- |
| `task_type_prompts.one_time` | One-time | `workspace_s3_path`, `task_id`, `scheduled_at` |
| `task_type_prompts.recurring` | Recurring | above + `sequence_number`, `schedule_expression` |
| `task_type_prompts.autonomous` | Autonomous | above + `mission_context` |

### 6.5 `analysis_prompt_template`

Prompt template for the analysis agent; returns structured JSON with fields `summary`, `status`, `task_name`, `next_task_description`, `should_terminate`, `terminate_reason`.

---

## 7. `config/model_catalog.yaml`

Top-level key: `model_catalog`. `providers` is a list; each item has `name` and `models`. Each model has `id`, `name`, `tier` (`pro` / `standard` / `lite`), `is_global`, `supports_vision`.

### 7.1 Anthropic

| ID | Name | tier | global | vision |
| --- | --- | --- | --- | --- |
| `global.anthropic.claude-opus-4-6-v1` | Claude Opus 4.6 | pro | ✓ | ✓ |
| `global.anthropic.claude-opus-4-5-20251101-v1:0` | Claude Opus 4.5 | pro | ✓ | ✓ |
| `global.anthropic.claude-sonnet-4-6` | Claude Sonnet 4.6 | standard | ✓ | ✓ |
| `global.anthropic.claude-sonnet-4-5-20250929-v1:0` | Claude Sonnet 4.5 | standard | ✓ | ✓ |
| `global.anthropic.claude-sonnet-4-20250514-v1:0` | Claude Sonnet 4 | standard | ✓ | ✓ |
| `global.anthropic.claude-haiku-4-5-20251001-v1:0` | Claude Haiku 4.5 | lite | ✓ | ✓ |
| `us.anthropic.claude-opus-4-6-v1` | Claude Opus 4.6 (us) | pro | — | ✓ |
| `us.anthropic.claude-opus-4-5-20251101-v1:0` | Claude Opus 4.5 (us) | pro | — | ✓ |
| `us.anthropic.claude-sonnet-4-6` | Claude Sonnet 4.6 (us) | standard | — | ✓ |
| `us.anthropic.claude-sonnet-4-20250514-v1:0` | Claude Sonnet 4 (us) | standard | — | ✓ |
| `us.anthropic.claude-3-7-sonnet-20250219-v1:0` | Claude 3.7 Sonnet (us) | standard | — | ✓ |
| `us.anthropic.claude-haiku-4-5-20251001-v1:0` | Claude Haiku 4.5 (us) | lite | — | ✓ |

### 7.2 Amazon

| ID | Name | tier | global | vision |
| --- | --- | --- | --- | --- |
| `global.amazon.nova-2-lite-v1:0` | Nova 2 Lite | lite | ✓ | ✓ |
| `us.amazon.nova-pro-v1:0` | Nova Pro (us) | standard | — | ✓ |
| `us.amazon.nova-2-lite-v1:0` | Nova 2 Lite (us) | lite | — | ✓ |
| `us.amazon.nova-lite-v1:0` | Nova Lite (us) | lite | — | ✓ |
| `us.amazon.nova-micro-v1:0` | Nova Micro (us) | lite | — | — |

### 7.3 Meta

| ID | Name | tier | global | vision |
| --- | --- | --- | --- | --- |
| `us.meta.llama4-maverick-17b-instruct-v1:0` | Llama 4 Maverick 17B | standard | — | ✓ |
| `us.meta.llama4-scout-17b-instruct-v1:0` | Llama 4 Scout 17B | standard | — | ✓ |
| `us.meta.llama3-3-70b-instruct-v1:0` | Llama 3.3 70B | pro | — | — |
| `meta.llama3-1-405b-instruct-v1:0` | Llama 3.1 405B | pro | — | — |
| `meta.llama3-1-70b-instruct-v1:0` | Llama 3.1 70B | pro | — | — |
| `us.meta.llama3-1-70b-instruct-v1:0` | Llama 3.1 70B (us) | pro | — | — |
| `meta.llama3-70b-instruct-v1:0` | Llama 3 70B | pro | — | — |
| `meta.llama3-1-8b-instruct-v1:0` | Llama 3.1 8B | lite | — | — |
| `us.meta.llama3-1-8b-instruct-v1:0` | Llama 3.1 8B (us) | lite | — | — |
| `meta.llama3-8b-instruct-v1:0` | Llama 3 8B | lite | — | — |

### 7.4 Mistral

| ID | Name | tier | global | vision |
| --- | --- | --- | --- | --- |
| `us.mistral.pixtral-large-2502-v1:0` | Pixtral Large (us) | pro | — | ✓ |
| `mistral.mistral-large-3-675b-instruct` | Mistral Large 3 (675B) | pro | — | ✓ |
| `mistral.mistral-large-2407-v1:0` | Mistral Large 2407 | pro | — | — |
| `mistral.mistral-large-2402-v1:0` | Mistral Large 2402 | pro | — | — |
| `mistral.devstral-2-123b` | Devstral 2 (123B) | standard | — | — |
| `mistral.magistral-small-2509` | Magistral Small | standard | — | ✓ |
| `mistral.voxtral-small-24b-2507` | Voxtral Small (24B) | standard | — | — |
| `mistral.ministral-3-14b-instruct` | Ministral 3 (14B) | lite | — | ✓ |
| `mistral.ministral-3-8b-instruct` | Ministral 3 (8B) | lite | — | ✓ |
| `mistral.ministral-3-3b-instruct` | Ministral 3 (3B) | lite | — | ✓ |
| `mistral.voxtral-mini-3b-2507` | Voxtral Mini (3B) | lite | — | — |

### 7.5 DeepSeek

| ID | Name | tier | global | vision |
| --- | --- | --- | --- | --- |
| `deepseek.v3.2` | DeepSeek V3.2 | standard | — | — |
| `deepseek.v3-v1:0` | DeepSeek V3 | standard | — | — |

### 7.6 Qwen

| ID | Name | tier | global | vision |
| --- | --- | --- | --- | --- |
| `qwen.qwen3-coder-480b-a35b-v1:0` | Qwen3 Coder 480B | pro | — | — |
| `qwen.qwen3-235b-a22b-2507-v1:0` | Qwen3 235B | pro | — | — |
| `qwen.qwen3-next-80b-a3b` | Qwen3 Next 80B | standard | — | — |
| `qwen.qwen3-vl-235b-a22b` | Qwen3 VL 235B | standard | — | ✓ |
| `qwen.qwen3-32b-v1:0` | Qwen3 32B | standard | — | — |
| `qwen.qwen3-coder-30b-a3b-v1:0` | Qwen3 Coder 30B | lite | — | — |

### 7.7 Google

| ID | Name | tier | global | vision |
| --- | --- | --- | --- | --- |
| `google.gemma-3-27b-it` | Gemma 3 27B | standard | — | ✓ |
| `google.gemma-3-12b-it` | Gemma 3 12B | standard | — | ✓ |
| `google.gemma-3-4b-it` | Gemma 3 4B | lite | — | ✓ |

### 7.8 NVIDIA

| ID | Name | tier | global | vision |
| --- | --- | --- | --- | --- |
| `nvidia.nemotron-super-3-120b` | Nemotron Super 120B | pro | — | — |
| `nvidia.nemotron-nano-3-30b` | Nemotron Nano 30B | standard | — | — |
| `nvidia.nemotron-nano-12b-v2` | Nemotron Nano 12B | lite | — | ✓ |

### 7.9 OpenAI

| ID | Name | tier | global | vision |
| --- | --- | --- | --- | --- |
| `openai.gpt-oss-120b-1:0` | GPT OSS 120B | pro | — | — |
| `openai.gpt-oss-20b-1:0` | GPT OSS 20B | standard | — | — |

### 7.10 Moonshot

| ID | Name | tier | global | vision |
| --- | --- | --- | --- | --- |
| `moonshot.kimi-k2-thinking` | Kimi K2 Thinking | pro | — | — |
| `moonshotai.kimi-k2.5` | Kimi K2.5 | standard | — | ✓ |

### 7.11 MiniMax

| ID | Name | tier | global | vision |
| --- | --- | --- | --- | --- |
| `minimax.minimax-m2.5` | MiniMax M2.5 | standard | — | — |
| `minimax.minimax-m2.1` | MiniMax M2.1 | standard | — | — |

### 7.12 Writer

| ID | Name | tier | global | vision |
| --- | --- | --- | --- | --- |
| `us.writer.palmyra-x5-v1:0` | Palmyra X5 | standard | — | — |
| `us.writer.palmyra-x4-v1:0` | Palmyra X4 | standard | — | — |

### 7.13 Z.AI

| ID | Name | tier | global | vision |
| --- | --- | --- | --- | --- |
| `zai.glm-5` | GLM 5 | standard | — | — |
| `zai.glm-4.7` | GLM 4.7 | standard | — | — |
| `zai.glm-4.7-flash` | GLM 4.7 Flash | lite | — | — |

---

## 8. `config/workflows.yaml`

### 8.1 Top level

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `version` | string | `1.0.0` | Workflow file version |

### 8.2 `defaults`

#### `defaults.execution`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `defaults.execution.max_retries` | int | `3` | Max retries |
| `defaults.execution.retry_delay_seconds` | int | `5` | Retry delay |
| `defaults.execution.stage_timeout_seconds` | int | `3600` | Per-stage timeout |
| `defaults.execution.total_timeout_seconds` | int | `21600` | Total workflow timeout (6h) |
| `defaults.execution.checkpoint_interval_seconds` | int | `60` | Checkpoint interval |

#### `defaults.context`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `defaults.context.max_tokens` | int | `100000` | Max tokens |
| `defaults.context.summary_threshold_tokens` | int | `5000` | Summary trigger threshold |
| `defaults.context.include_rules` | bool | `true` | Include rules |
| `defaults.context.include_local_docs` | bool | `true` | Include local docs |

### 8.3 Workflow metadata

Each workflow (`agent_build` / `agent_update` / `tool_build` / `skill_build` / `magician`) contains:

| Key | Description |
| --- | --- |
| `name` | Internal name |
| `display_name` | Display name |
| `description` | Description |
| `version` | Version |
| `enabled` | Enabled |
| `prompt_base_path` | Prompt directory |
| `stages` | Stage list |
| `legacy_name_mapping` | Legacy name mapping |

Stage object fields:

| Field | Type | Description |
| --- | --- | --- |
| `name` | string | Stage ID |
| `display_name` | string | Display name |
| `agent_display_name` | string | Executing agent display name |
| `prompt_file` | string | Prompt filename (no extension) |
| `log_filename` | string | Log filename |
| `order` | int | Execution order |
| `scope` | string | `project` / `agent` |
| `prerequisites` | list[string] | Prerequisite stages |
| `rule_keys` | list[string] | Injected rule keys |
| `supports_iteration` | bool | Supports iteration |
| `optional` | bool | Optional |
| `description` | string | Description |
| `fork_on_complete` | bool | Fork on complete (only `agent_build.system_architecture`) |
| `join_after_complete` | bool | Join after complete (only `agent_build.code_development`) |
| `join_before_start` | bool | Join before start (only `agent_build.deployment`) |

### 8.4 `agent_build` stages

| order | name | scope | prerequisites | rule_keys | iteration | optional | Special |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `intent_recognition` | project | `[]` | `[]` | false | false | — |
| 2 | `requirements_analysis` | project | `[intent_recognition]` | `[]` | false | false | — |
| 3 | `system_architecture` | project | `[requirements_analysis]` | `[generation_rules]` | false | false | `fork_on_complete: true` |
| 4 | `agent_design` | agent | `[requirements_analysis, system_architecture]` | `[generation_rules]` | false | false | — |
| 5 | `tools_development` | agent | `[agent_design]` | `[directory_rules, generation_rules, cache_rules, external_resources, custom_rules]` | true | false | — |
| 6 | `prompt_development` | agent | `[requirements_analysis, tools_development]` | same as above | true | false | — |
| 7 | `code_development` | agent | `[prompt_development]` | same as above | true | false | `join_after_complete: true` |
| 8 | `deployment` | project | `[system_architecture, code_development]` | `[directory_rules]` | false | false | `join_before_start: true` |

`agent_build.legacy_name_mapping`: `orchestrator→intent_recognition`, `requirements_analyzer→requirements_analysis`, `system_architect→system_architecture`, `agent_designer→agent_design`, `tools_developer/tool_developer→tools_development`, `prompt_engineer→prompt_development`, `agent_code_developer/agent_developer_manager→code_development`, `agent_deployer→deployment`.

### 8.5 `agent_update` stages

Top-level `rule_keys: [base_rules, update_workflow_rules]`.

| order | name | scope | prerequisites | iteration | optional |
| --- | --- | --- | --- | --- | --- |
| 1 | `update_orchestrator` | project | `[]` | false | false |
| 2 | `requirements_update` | project | `[update_orchestrator]` | false | false |
| 3 | `tool_update` | project | `[requirements_update]` | true | true |
| 4 | `prompt_update` | project | `[tool_update]` | true | true |
| 5 | `update_deployment` | project | `[prompt_update]` | false | false |

`legacy_name_mapping`: `code_update→update_deployment`.

### 8.6 `tool_build` stages

| order | name | scope | prerequisites | rule_keys | iteration |
| --- | --- | --- | --- | --- | --- |
| 1 | `intent_recognition` | project | `[]` | `[]` | false |
| 2 | `tool_design` | project | `[intent_recognition]` | `[generation_rules]` | false |
| 3 | `tool_development` | project | `[tool_design]` | `[directory_rules, generation_rules]` | true |
| 4 | `tool_validation` | project | `[tool_development]` | `[]` | false |
| 5 | `tool_deployment` | project | `[tool_validation]` | `[directory_rules]` | false |

`legacy_name_mapping`: `orchestrator→intent_recognition`, `requirements_analyzer→tool_design`, `tool_designer→tool_design`, `tool_developer→tool_development`, `tool_validator→tool_validation`, `tool_documenter→tool_deployment`.

### 8.7 `skill_build` stages

| order | name | scope | prerequisites | rule_keys | iteration |
| --- | --- | --- | --- | --- | --- |
| 1 | `intent_recognition` | project | `[]` | `[]` | false |
| 2 | `skill_design` | project | `[intent_recognition]` | `[generation_rules]` | false |
| 3 | `skill_development` | project | `[skill_design]` | `[directory_rules, generation_rules]` | true |
| 4 | `skill_validation` | project | `[skill_development]` | `[]` | false |
| 5 | `skill_deployment` | project | `[skill_validation]` | `[directory_rules]` | false |

### 8.8 `magician` stages

| order | name | prerequisites |
| --- | --- | --- |
| 1 | `magician_orchestrator` | `[]` |

---

## 9. `config/nexus_ai_base_rule.yaml`

Top-level key: `workflows`. Each rule category contains `version`, `updated_on`, `author`, `change_log`, `attributes`.

### 9.1 Rule categories

| Category | Purpose |
| --- | --- |
| `base` | Shared base rules for all workflows |
| `agent_build` | Agent build rules |
| `agent_update` | Agent update rules |
| `runtime` | Session runtime rules |
| `tool_build` | Tool build rules |
| `skill_build` | Skill build rules |

### 9.2 Rule attributes

Each category's `attributes` object contains the following five fields:

| Attribute key | Description |
| --- | --- |
| `directory_rules` | Directory rules |
| `generation_rules` | Generation rules |
| `cache_rules` | Cache rules |
| `external_resources` | External resource rules |
| `custom_rules` | User-defined rules |

### 9.3 Current versions at a glance

| Category | version | updated_on | author |
| --- | --- | --- | --- |
| `base` | `latest` | `2026-03-24` | qangz |
| `agent_build` | `latest` | `2025-11-10` | agent_build_workflow |
| `agent_update` | `latest` | `2025-11-10` | qangz |
| `runtime` | `latest` | `2026-03-08` | qangz |
| `tool_build` | `2.0` | `2026-03-30` | qangz |
| `skill_build` | `latest` | `2026-03-30` | qangz |

---

## 10. Environment-variable overrides

`ConfigLoader` reads the following env vars, taking precedence over file values.

### 10.1 `get_nexus_ai_config()` related

| Env var | Config key | Default |
| --- | --- | --- |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | `nexus_ai.OTEL_EXPORTER_OTLP_ENDPOINT` | `http://localhost:4318` |

### 10.2 `get_aurora_config()`

| Env var | Config key |
| --- | --- |
| `NEXUS_AURORA_HOST` | `aurora.host` |
| `NEXUS_AURORA_PASSWORD` | `aurora.password` |

### 10.3 `get_valkey_config()`

| Env var | Config key |
| --- | --- |
| `NEXUS_VALKEY_ENDPOINT` | `valkey.endpoint` |

### 10.4 `get_workflow_config()`

| Env var | Config key | Default |
| --- | --- | --- |
| `NEXUS_WORKFLOW_MAX_RETRIES` | `workflow.execution.max_retries` | `3` |
| `NEXUS_WORKFLOW_STAGE_TIMEOUT` | `workflow.execution.stage_timeout_seconds` | `3600` |
| `NEXUS_WORKFLOW_MAX_CONTEXT_TOKENS` | `workflow.context.max_tokens` | `100000` |

### 10.5 `get_dynamodb_config()`

| Env var | Config key | Default |
| --- | --- | --- |
| `NEXUS_DYNAMODB_TABLE_PREFIX` | `dynamodb.table_prefix` | `nexus_` |
| `NEXUS_DYNAMODB_PROJECTS_TABLE` | `dynamodb.tables.projects` | `projects` |
| `NEXUS_DYNAMODB_STAGES_TABLE` | `dynamodb.tables.stages` | `stages` |
| `NEXUS_DYNAMODB_TASKS_TABLE` | `dynamodb.tables.tasks` | `tasks` |

### 10.6 `get_sqs_config()`

| Env var | Config key | Default |
| --- | --- | --- |
| `NEXUS_SQS_QUEUE_PREFIX` | `sqs.queue_prefix` | `nexus-` |
| `NEXUS_SQS_BUILD_QUEUE` | `sqs.queues.build` | `build-queue` |
| `NEXUS_SQS_DEPLOY_QUEUE` | `sqs.queues.deploy` | `deploy-queue` |
| `NEXUS_SQS_NOTIFICATION_QUEUE` | `sqs.queues.notification` | `notification-queue` |
| `NEXUS_SQS_BUILD_DLQ` | `sqs.dlq.build` | `build-dlq` |
| `NEXUS_SQS_DEPLOY_DLQ` | `sqs.dlq.deploy` | `deploy-dlq` |
| `NEXUS_SQS_VISIBILITY_TIMEOUT` | `sqs.visibility_timeout` | `3600` |
| `NEXUS_SQS_BUILD_VISIBILITY_TIMEOUT` | `sqs.build_visibility_timeout` | `3600` |
| `NEXUS_SQS_DEPLOY_VISIBILITY_TIMEOUT` | `sqs.deploy_visibility_timeout` | `600` |
| `NEXUS_SQS_MESSAGE_RETENTION_DAYS` | `sqs.message_retention_days` | `14` |
| `NEXUS_SQS_MAX_RETRY_COUNT` | `sqs.max_retry_count` | `3` |

### 10.7 `get_service_config()`

Overrides `service-config` in `config/service_config.yaml`.

| Env var | Config key | Default |
| --- | --- | --- |
| `API_PORT` | `api.port` | `8000` |
| `NEXUS_API_WORKERS` | `api.workers` | `1` |
| `NEXUS_THREAD_POOL_SIZE` | `api.thread_pool_size` | `64` |
| `NEXUS_AGENT_CREATION_TIMEOUT` | `api.agent_creation_timeout` | `120` |
| `NEXUS_SSE_HEARTBEAT_INTERVAL` | `api.sse_heartbeat_interval` | `15` |
| `NEXUS_MAX_CONCURRENT_STREAMS` | `api.max_concurrent_streams` | `0` |
| `NEXUS_WORKER_THREAD_POOL_SIZE` | `worker.thread_pool_size` | `32` |
| `WEB_PORT` | `web.port` | `3000` |
| `NEXUS_MCP_PORT` | `mcp.port` | `9000` |
| `BRIDGE_PORT` | `bridge.port` | `8001` |
| `BRIDGE_COMMAND_TIMEOUT` | `bridge.command_timeout` | `900` |
| `BRIDGE_CONNECTION_TIMEOUT` | `bridge.connection_timeout` | `1200` |
| `SANDBOX_CONTROLLER_HOST` | `sandbox_controller.host` | `0.0.0.0` |
| `SANDBOX_CONTROLLER_PORT` | `sandbox_controller.port` | `8002` |
| `SANDBOX_PATROL_INTERVAL` | `sandbox_controller.patrol_interval` | `30` |
| `SANDBOX_HEARTBEAT_TIMEOUT` | `sandbox_controller.heartbeat_timeout` | `90` |
| `SANDBOX_SCALE_DOWN_IDLE_MINUTES` | `sandbox_controller.scale_down_idle_minutes` | `10` |
| `SANDBOX_MIN_NODES` | `sandbox_controller.min_nodes` | `1` |

---

## 11. `config/service_config.yaml` (consumed by `get_service_config()`)

### 11.1 `service-config.api`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `api.host` | string | `0.0.0.0` | API bind address |
| `api.port` | int | `8000` | API port |
| `api.log_level` | string | `info` | Log level |
| `api.workers` | int | `1` | Worker count |
| `api.thread_pool_size` | int | `64` | Thread pool size |
| `api.agent_creation_timeout` | int (seconds) | `120` | Agent creation timeout |
| `api.sse_heartbeat_interval` | int (seconds) | `15` | SSE heartbeat interval |
| `api.max_concurrent_streams` | int | `0` | Max concurrent streams (0=unlimited) |

### 11.2 `service-config.worker`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `worker.thread_pool_size` | int | `32` | Worker thread pool |

### 11.3 `service-config.web`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `web.host` | string | `0.0.0.0` | Web bind address |
| `web.port` | int | `3000` | Web port |

### 11.4 `service-config.mcp`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `mcp.port` | int | `9000` | MCP port |

### 11.5 `service-config.bridge`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `bridge.host` | string | `0.0.0.0` | Bridge bind address |
| `bridge.port` | int | `8001` | Bridge port |
| `bridge.log_level` | string | `info` | Log level |
| `bridge.command_timeout` | int (seconds) | `900` | Command timeout |
| `bridge.connection_timeout` | int (seconds) | `1200` | Connection timeout |

### 11.6 `service-config.sandbox_controller`

| Key | Type | Default | Description |
| --- | --- | --- | --- |
| `sandbox_controller.host` | string | `0.0.0.0` | Bind address |
| `sandbox_controller.port` | int | `8002` | Port |
| `sandbox_controller.log_level` | string | `info` | Log level |
| `sandbox_controller.patrol_interval` | int (seconds) | `30` | Patrol interval |
| `sandbox_controller.heartbeat_timeout` | int (seconds) | `90` | Heartbeat timeout |
| `sandbox_controller.scale_down_idle_minutes` | int | `10` | Scale-down idle threshold (minutes) |
| `sandbox_controller.min_nodes` | int | `1` | Min nodes |

---

## 12. Minimal examples

### 12.1 Default config snippet

```yaml
default-config:
  nexus_ai:
    artifacts_s3_bucket: my-nexus-artifacts
    session_storage_s3_bucket: my-nexus-sessions
    auth:
      user: admin
      password: change-me
      enforce_auth: true
  aws:
    aws_region_name: us-west-2
    bedrock_region_name: us-west-2
  bedrock:
    model_id: us.anthropic.claude-sonnet-4-5-20250929-v1:0
  dynamodb:
    table_prefix: nexus_
    tables:
      tasks: tasks
```

### 12.2 Override via env vars

```bash
export NEXUS_DYNAMODB_TABLE_PREFIX=prod_
export NEXUS_SQS_MAX_RETRY_COUNT=5
export API_PORT=9090
export NEXUS_AURORA_HOST=my-cluster.cluster-xxx.rds.amazonaws.com
export NEXUS_AURORA_PASSWORD=${PROD_DB_PWD}
```

### 12.3 Read from code

```python
from nexus_utils.config_loader import get_config

cfg = get_config()
model = cfg.get_bedrock_config()["model_id"]
bucket = cfg.get_nested("nexus_ai", "artifacts_s3_bucket")
otel = cfg.get_with_env_override(
    "OTEL_EXPORTER_OTLP_ENDPOINT",
    "nexus_ai", "OTEL_EXPORTER_OTLP_ENDPOINT",
    default="http://localhost:4318",
)
tasks_table = cfg.get_table_name("tasks")   # => "nexus_tasks"
```
