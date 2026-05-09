---
title: 配置项
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

# 配置项

本篇列出 Nexus-AI 的**全部 YAML 配置项**。所有配置文件位于仓库根目录的 `config/` 下，运行时通过 `nexus_utils/config_loader.py` 的 `ConfigLoader` 加载。

## 一、配置加载机制

### 1.1 文件路径

| 文件 | 路径 | 顶层键 | 说明 |
| --- | --- | --- | --- |
| 主配置 | `config/default_config.yaml` | `default-config` | 平台核心配置 |
| 服务配置 | `config/service_config.yaml` | `service-config` | API / Worker / Web / MCP / Bridge / Sandbox Controller 运行参数 |
| 应用清单 | `config/app_manifest.yaml` | `app-manifest` | 品牌、版本、功能开关 |
| 数据连接器 | `config/data_connector.yaml` | `data_connector` / `key_management` | 数据源和密钥管理 |
| 事件调度器 | `config/eventschedule_config.yaml` | `event_scheduler` | 定时任务 |
| 日志增强 | `config/logging_config.yaml` | `enhanced_logging` / `strands_hooks` / `observability` | 日志与 OTEL |
| 模型目录 | `config/model_catalog.yaml` | `model_catalog` | Bedrock 模型清单 |
| 基础规则 | `config/nexus_ai_base_rule.yaml` | `workflows` | 构建 / 更新 / 运行时规则 |
| 工作流 | `config/workflows.yaml` | — | 工作流阶段定义 |

### 1.2 优先级规则

`ConfigLoader.get_with_env_override()` 遵循：

```
环境变量 > 配置文件 > 代码默认值
```

### 1.3 访问 API

| 方法 | 作用 |
| --- | --- |
| `get(key, default)` | 读取 `default-config.&lt;key&gt;` |
| `get_section(name)` | 同 `get`，语义更明确 |
| `get_nested(*keys)` | 深层嵌套，如 `get_nested("multimodal_parser", "aws", "s3_bucket")` |
| `get_with_env_override(env_var, *keys, default)` | 环境变量优先 |
| `get_aws_config()` / `get_bedrock_config()` / `get_strands_config()` / `get_agentcore_config()` / `get_nexus_ai_config()` / `get_mcp_config()` / `get_multimodal_parser_config()` / `get_aurora_config()` / `get_valkey_config()` / `get_s3_vectors_config()` / `get_logging_config()` / `get_workflow_config()` / `get_workflow_version_config()` / `get_workflow_stages()` / `get_dynamodb_config()` / `get_sqs_config()` / `get_service_config()` | 获取对应子配置 |
| `get_table_name(table_key)` | 返回带前缀的完整表名 |
| `has_section(name)` / `list_sections()` | 配置段内省 |
| `reload_config()` | 重新加载 |

---

## 二、`config/default_config.yaml`

顶层键：`default-config`。以下各小节均以 `default-config.&lt;section&gt;` 为根。

### 2.1 `nexus_ai` — 核心平台

#### 基础字段

| Key（YAML path） | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `nexus_ai.base_rule_path` | string | `config/nexus_ai_base_rule.yaml` | 基础规则文件路径 |
| `nexus_ai.base_rule_version` | string | `latest` | 基础规则版本 |
| `nexus_ai.OTEL_EXPORTER_OTLP_ENDPOINT` | string | `http://localhost:4318` | OTLP HTTP 端点，可被同名环境变量覆盖 |
| `nexus_ai.artifacts_s3_bucket` | string | `nexus-ai-artifacts-2026` | 工件存储桶（工具 / Agent / Skill 产物） |
| `nexus_ai.session_storage_s3_bucket` | string | `nexus-ai-session-2026` | 会话存储桶 |
| `nexus_ai.attachment_s3_bucket` | string | `nexus-ai-attachments-2026` | 附件存储桶 |
| `nexus_ai.attachment_presigned_url_expiry` | int（秒） | `3600` | 附件下载预签名 URL 有效期 |
| `nexus_ai.attachment_upload_url_expiry` | int（秒） | `600` | 附件上传预签名 URL 有效期 |
| `nexus_ai.attachment_max_file_size` | int（字节） | `52428800` | 单附件最大 50 MB |
| `nexus_ai.attachment_max_files_per_message` | int | `5` | 单条消息最多附件数 |
| `nexus_ai.auto_sync_to_s3` | bool | `true` | 是否自动同步到 S3 |
| `nexus_ai.event_workspace_s3_bucket` | string | `nexus-ai-event-workspace-2026` | 事件任务工作空间桶 |

#### `nexus_ai.workflow_default_version`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `workflow_default_version.agent_build` | string | `latest` | Agent 构建工作流默认版本 |
| `workflow_default_version.agent_update` | string | `latest` | Agent 更新工作流默认版本 |
| `workflow_default_version.tool_build` | string | `latest` | 工具构建工作流默认版本 |
| `workflow_default_version.skill_build` | string | `latest` | Skill 构建工作流默认版本 |

#### `nexus_ai.file_sharing`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `file_sharing.default_ttl` | int（秒） | `86400` | 分享链接默认有效期（1 天） |
| `file_sharing.max_ttl` | int（秒） | `604800` | 分享链接最大有效期（7 天） |
| `file_sharing.share_code_length` | int | `16` | 分享码字符数 |
| `file_sharing.resolution_presign_ttl` | int（秒） | `3600` | 解析预签名 URL 有效期 |
| `file_sharing.public_base_url` | string | `''` | 公共分享基础 URL |

#### `nexus_ai.templates`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `templates.s3_bucket` | string | `''` | 模板桶，留空则复用 `attachment_s3_bucket` |
| `templates.s3_key_prefix` | string | `templates/` | 模板 S3 前缀 |
| `templates.efs_subdir` | string | `/templates` | EFS 子目录 `/templates/{asset_id}/v{n}/` |
| `templates.upload_url_expiry` | int（秒） | `600` | 上传 URL 有效期 |
| `templates.max_file_size` | int（字节） | `104857600` | 单模板最大 100 MB |
| `templates.allowed_extensions` | list[string] | `[pptx, docx, xlsx, pdf, html, htm, md, txt, png, jpg]` | 允许的扩展名 |
| `templates.preview_text_max_bytes` | int（字节） | `102400` | 预览文本最大 100 KB |
| `templates.preview_workers` | int | `4` | 预览工作进程数 |
| `templates.ai_enabled` | bool | `true` | 是否启用 AI 分析 |
| `templates.ai_analyze_model` | string | `us.anthropic.claude-haiku-4-5-20251001-v1:0` | 分析模型 ID |
| `templates.ai_embed_model` | string | `amazon.titan-embed-text-v2:0` | 嵌入模型 ID |
| `templates.ai_embed_dim` | int | `1024` | 嵌入维度 |
| `templates.ai_diff_model` | string | `us.anthropic.claude-haiku-4-5-20251001-v1:0` | 差异分析模型 |
| `templates.libreoffice_bin` | string | `libreoffice` | LibreOffice 可执行文件路径 |
| `templates.imagemagick_bin` | string | `convert` | ImageMagick `convert` 路径 |

#### `nexus_ai.backup`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `backup.share_mode` | string | `local` | 备份分享模式 |
| `backup.share_default_ttl` | int（小时） | `24` | 备份分享默认有效期 |
| `backup.share_max_ttl` | int（小时） | `168` | 备份分享最大有效期（7 天） |
| `backup.share_cleanup_days` | int | `7` | 备份清理天数 |
| `backup.max_backup_size` | int（字节） | `536870912` | 备份最大 512 MB |
| `backup.hub_url` | string | `''` | 备份中心 URL |
| `backup.public_api_url` | string | `''` | 备份公共 API URL |

#### `nexus_ai.remote_terminal`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `remote_terminal.enabled` | bool | `true` | 启用远程终端 |
| `remote_terminal.type` | string | `http` | 连接类型 |
| `remote_terminal.token_expiry_seconds` | int | `600` | 令牌有效期 |
| `remote_terminal.connection_timeout_seconds` | int | `300` | 连接超时 |
| `remote_terminal.command_timeout_seconds` | int | `120` | 命令超时 |
| `remote_terminal.max_output_length` | int | `50000` | 单次输出最大字符数 |
| `remote_terminal.heartbeat_interval_seconds` | int | `30` | 心跳间隔 |
| `remote_terminal.http_poll_interval_seconds` | int | `1` | HTTP 轮询间隔 |
| `remote_terminal.websocket_path` | string | `/api/v2/remote/ws` | WebSocket 路径 |
| `remote_terminal.nexus_host` | string | `localhost` | 目标主机 |
| `remote_terminal.nexus_port` | int | `8000` | 目标端口 |
| `remote_terminal.use_ssl` | bool | `false` | 启用 SSL |
| `remote_terminal.max_connections_per_session` | int | `5` | 每会话最大连接数 |
| `remote_terminal.reconnect_token_expiry_seconds` | int | `86400` | 重连令牌有效期（1 天） |

#### `nexus_ai.runtime_workspace`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `runtime_workspace.local_base_dir` | string | `.cache` | 本地工作空间根目录 |
| `runtime_workspace.s3_prefix` | string | `workspace/` | S3 前缀 |
| `runtime_workspace.auto_sync` | bool | `true` | 自动同步 |
| `runtime_workspace.sync_on_edit` | bool | `true` | 编辑即同步 |
| `runtime_workspace.presigned_url_expiry` | int（秒） | `3600` | 预签名 URL 有效期 |
| `runtime_workspace.max_workspace_size` | int（字节） | `524288000` | 单工作空间最大 500 MB |
| `runtime_workspace.inline_content_max_size` | int（字节） | `1048576` | 内联内容最大 1 MB |
| `runtime_workspace.cleanup_on_session_delete` | bool | `true` | 会话删除时清理 |

#### `nexus_ai.conversation_manager`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `conversation_manager.enabled` | bool | `true` | 启用对话管理器 |
| `conversation_manager.type` | string | `summarizing` | `sliding_window` 或 `summarizing` |
| `conversation_manager.sliding_window.window_size` | int | `50` | 滑窗消息数 |
| `conversation_manager.sliding_window.should_truncate_results` | bool | `true` | 是否截断工具结果 |
| `conversation_manager.summarizing.summary_ratio` | float | `0.3` | 摘要比例 |
| `conversation_manager.summarizing.preserve_recent_messages` | int | `30` | 保留最近消息数 |
| `conversation_manager.summarizing.use_custom_agent` | bool | `true` | 使用自定义摘要 Agent |
| `conversation_manager.summarizing.custom_agent_model_id` | string | `us.anthropic.claude-haiku-4-5-20251001-v1:0` | 摘要模型 |
| `conversation_manager.summarizing.custom_agent_prompt_path` | string | `system_agents_prompts/conversation_summarizer/conversation_summarizer` | 摘要提示词路径 |

#### `nexus_ai.auth`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `auth.user` | string | `admin` | 默认管理员用户名 |
| `auth.password` | string | `nexus` | 默认管理员密码（生产必改） |
| `auth.secret_key` | string | `''` | JWT 签名密钥 |
| `auth.enforce_auth` | bool | `true` | 强制认证 |
| `auth.default_role_on_first_login` | string | `admin` | 首次登录默认角色 |

#### `nexus_ai.sso`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `sso.enabled` | bool | `false` | 启用 SAML SSO |
| `sso.idp_metadata_url` | string | `https://portal.sso.xxxxx/saml/metadata/xxxxx` | IdP 元数据 URL |
| `sso.idp_metadata_xml` | string | `''` | IdP 元数据 XML（内联） |
| `sso.sp_entity_id` | string | `nexus-ai-sp` | SP 实体 ID |
| `sso.sp_acs_url` | string | `http://localhost:8000/api/v2/auth/sso/acs` | SP ACS URL |
| `sso.sp_sls_url` | string | `http://localhost:8000/api/v2/auth/sso/sls` | SP SLS URL |
| `sso.idp_logout_url` | string | `https://portal.sso.xxxxx/saml/logout/xxxxx` | IdP 登出 URL |
| `sso.frontend_url` | string | `http://localhost:3000` | 前端 URL |
| `sso.jwt_expire_hours` | int | `24` | JWT 过期小时 |
| `sso.allowed_email_domains` | list[string] | `[]` | 允许登录的邮箱域 |
| `sso.dev_user.name` | string | `Dev Admin` | 开发模式默认用户名 |
| `sso.dev_user.email` | string | `admin@dev.local` | 开发模式默认邮箱 |
| `sso.dev_user.role` | string | `admin` | 开发模式默认角色 |

#### `nexus_ai.sandbox`

##### 顶层

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `sandbox.enabled` | bool | `false` | 启用沙箱（EC2 + Firecracker） |

##### `sandbox.policy`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `sandbox.policy.default_runtime` | string | `ec2` | `local` / `ec2` / `agentcore` |
| `sandbox.policy.allow_user_override` | bool | `true` | 允许用户覆盖 |
| `sandbox.policy.allowed_runtimes` | list[string] | `[local, ec2]` | 允许的运行时 |
| `sandbox.policy.max_concurrent_vms` | int | `50` | 全局 VM 上限 |

##### `sandbox.config`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `sandbox.config.efs_code_id` | string | `''` | 代码 EFS FileSystem ID |
| `sandbox.config.efs_code_mount` | string | `/nexus-efs` | 主 EC2 代码挂载点 |
| `sandbox.config.repo_root` | string | `/nexus-efs/nexus-ai` | 仓库根目录 |
| `sandbox.config.vm_code_mount` | string | `/code` | microVM 内代码挂载点 |
| `sandbox.config.efs_data_id` | string | `''` | 数据 EFS FileSystem ID |
| `sandbox.config.efs_data_mount` | string | `/nexus-efs-data` | 数据挂载点 |
| `sandbox.config.workspace_prefix` | string | `workspaces` | 工作空间前缀 |
| `sandbox.config.envs_prefix` | string | `envs` | venv 前缀 |
| `sandbox.config.events_prefix` | string | `events` | 事件前缀 |
| `sandbox.config.rootfs_path` | string | `/local/rootfs/base.ext4` | Firecracker rootfs 模板 |
| `sandbox.config.session_s3_bucket` | string | `''` | 会话桶（留空继承） |
| `sandbox.config.valkey_endpoint` | string | `''` | Valkey 端点（留空继承） |
| `sandbox.config.valkey_port` | int | `6379` | Valkey 端口 |
| `sandbox.config.valkey_ssl` | bool | `true` | Valkey SSL |
| `sandbox.config.dynamodb_table_prefix` | string | `''` | DDB 前缀（留空继承） |
| `sandbox.config.firecracker_bin` | string | `/opt/firecracker/firecracker` | Firecracker 可执行文件 |
| `sandbox.config.kernel_path` | string | `/opt/firecracker/vmlinux` | 内核路径 |
| `sandbox.config.vm_work_dir` | string | `/local/fc-work` | VM overlay 工作目录 |
| `sandbox.config.vm_vcpu` | int | `1` | 每 VM vCPU 数 |
| `sandbox.config.vm_memory_mib` | int | `1536` | 每 VM 内存（MiB，1.5 GB） |
| `sandbox.config.vm_port` | int | `8080` | VM 内 runtime_app 端口 |
| `sandbox.config.vm_boot_timeout` | int（秒） | `30` | VM 启动健康检查超时 |
| `sandbox.config.bridge_name` | string | `br0` | 主机 bridge 名 |
| `sandbox.config.bridge_cidr` | string | `172.16.0.0/24` | VM 子网 |
| `sandbox.config.bridge_gateway` | string | `172.16.0.1` | 网关 |
| `sandbox.config.stream_maxlen` | int | `5000` | 流最大长度 |
| `sandbox.config.invocation_timeout` | int（秒） | `600` | Agent 执行超时 |
| `sandbox.config.idle_timeout` | int（秒） | `300` | VM 空闲销毁 |
| `sandbox.config.log_level` | string | `INFO` | 日志级别 |
| `sandbox.config.host_port` | int | `8080` | sandbox-host HTTP 端口 |
| `sandbox.config.proxy_port_range_start` | int | `18001` | VM 代理起始端口 |
| `sandbox.config.proxy_port_range_end` | int | `18100` | VM 代理结束端口（每节点 100 VM） |

##### `sandbox.pool`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `sandbox.pool.instance_type` | string | `c8id.xlarge` | 实例类型（需支持 KVM） |
| `sandbox.pool.min_size` | int | `1` | ASG 最小节点数 |
| `sandbox.pool.max_size` | int | `5` | ASG 最大节点数 |
| `sandbox.pool.desired_size` | int | `1` | 期望节点数 |
| `sandbox.pool.vms_per_node` | int | `0` | 每节点最大 VM（0=自动） |
| `sandbox.pool.key_name` | string | `''` | SSH 密钥对名 |
| `sandbox.pool.cluster_name` | string | `''` | 集群名（由 CF 填） |
| `sandbox.pool.subnets` | list[string] | `[]` | 子网（由 CF 填） |
| `sandbox.pool.security_groups` | list[string] | `[]` | 安全组（由 CF 填） |
| `sandbox.pool.prewarm_featured_agents` | bool | `false` | 预热 featured agent VM |
| `sandbox.pool.prewarm_idle_vms` | int | `0` | 预热空 VM 数 |

### 2.2 `workflow`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `workflow.config_file` | string | `config/workflows.yaml` | 工作流定义文件 |

### 2.3 `aws`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `aws.bedrock_region_name` | string | `us-west-2` | Bedrock 区域 |
| `aws.aws_region_name` | string | `us-west-2` | 默认 AWS 区域 |
| `aws.aws_profile_name` | string | `''` | AWS 配置文件名 |
| `aws.aws_access_key_id` | string | `''` | 访问密钥 ID |
| `aws.aws_secret_access_key` | string | `''` | 访问密钥 |
| `aws.endpoint_url` | string | `''` | 自定义端点（如 LocalStack） |
| `aws.verify` | bool | `true` | 验证 TLS 证书 |
| `aws.connect_timeout` | int（秒） | `7200` | 连接超时 |

### 2.4 `strands`

#### `strands.retry_strategy`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `strands.retry_strategy.enabled` | bool | `true` | 启用重试 |
| `strands.retry_strategy.max_attempts` | int | `6` | 最大重试次数 |
| `strands.retry_strategy.initial_delay` | int（秒） | `4` | 初始延迟 |
| `strands.retry_strategy.max_delay` | int（秒） | `128` | 最大延迟 |

#### `strands.template`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `strands.template.agent_template_path` | string | `agents/template_agents` | Agent 模板目录 |
| `strands.template.prompt_template_path` | string | `prompts/template_prompts` | 提示词模板目录 |
| `strands.template.tool_template_path` | string | `tools/template_tools` | 工具模板目录 |

#### `strands.generated`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `strands.generated.agent_generated_path` | string | `agents/generated_agents` | 生成 Agent 目录 |
| `strands.generated.prompt_generated_path` | string | `prompts/generated_agents_prompts` | 生成提示词目录 |
| `strands.generated.tool_generated_path` | string | `tools/generated_tools` | 生成工具目录 |

#### `strands.system`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `strands.system.agents_path` | string | `agents/system_agents` | 系统 Agent 目录 |
| `strands.system.prompts_path` | string | `prompts/system_agents_prompts` | 系统提示词目录 |
| `strands.system.tools_path` | string | `tools/system_tools` | 系统工具目录 |

#### 其他

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `strands.requirements_path` | string | `templates/requirements/requirements.txt` | 依赖模板 |
| `strands.mcp_server_path` | string | `config/mcp/` | MCP 配置目录 |
| `strands.project_path` | string | `project/` | 项目目录 |
| `strands.default_tools` | list[string] | `[calculator, shell, file_read, file_write]` | 默认工具 |

### 2.5 `agentcore`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `agentcore.execution_role_arn` | string | `''` | AgentCore 执行角色 ARN |
| `agentcore.auto_create_execution_role` | bool | `true` | 自动创建执行角色 |
| `agentcore.ecr_auto_create` | bool | `true` | 自动创建 ECR |
| `agentcore.runtime_timeout_minutes` | int | `30` | 运行超时（分钟） |
| `agentcore.enable_xray` | bool | `false` | 启用 X-Ray |
| `agentcore.deploy_dry_run` | bool | `false` | 干运行部署 |
| `agentcore.default_alias` | string | `DEFAULT` | 默认别名 |
| `agentcore.post_deploy_test` | bool | `false` | 部署后测试 |
| `agentcore.post_deploy_test_prompt` | string | `Hello` | 测试提示 |
| `agentcore.auto_update_on_conflict` | bool | `true` | 冲突时自动更新 |

### 2.6 `bedrock`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `bedrock.model_id` | string | `us.anthropic.claude-sonnet-4-5-20250929-v1:0` | 默认模型 |
| `bedrock.lite_model_id` | string | `us.anthropic.claude-haiku-4-5-20251001-v1:0` | 轻量模型 |
| `bedrock.pro_model_id` | string | `us.anthropic.claude-opus-4-5-20251101-v1:0` | 高级模型 |
| `bedrock.connect_config.retries.max_attempts` | int | `100` | 最大重试次数 |
| `bedrock.connect_config.retries.mode` | string | `adaptive` | 重试模式 |
| `bedrock.connect_config.connect_timeout` | int（秒） | `3600` | 连接超时 |
| `bedrock.connect_config.read_timeout` | int（秒） | `7200` | 读取超时 |
| `bedrock.prompt_caching.enabled` | bool | `true` | 启用 Prompt Caching |
| `bedrock.prompt_caching.cache_system_prompt` | bool | `true` | 缓存 system prompt |
| `bedrock.prompt_caching.cache_tools` | bool | `true` | 缓存工具定义 |

### 2.7 `logging`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `logging.level` | string | `INFO` | 日志级别 |
| `logging.file_path` | string | `logs/nexus_ai.log` | 日志文件路径 |
| `logging.format` | string | `%(asctime)s - %(name)s - %(levelname)s - %(message)s` | 日志格式 |

### 2.8 `observability`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `observability.enabled` | bool | `false` | 启用可观测性（本地默认关） |
| `observability.prefix` | string | `NexusAI` | 命名前缀 |
| `observability.capture.tool_input` | string | `hash_only` | `none` / `hash_only` / `redacted_preview` |
| `observability.capture.tool_output` | string | `hash_only` | 同上 |
| `observability.capture.system_prompt` | bool | `false` | 捕获 system prompt |
| `observability.capture.user_query` | string | `redacted_preview` | 同 tool_input |
| `observability.capture.bedrock_response` | bool | `false` | 捕获 Bedrock 响应体 |
| `observability.sampling.development` | float | `1.0` | 开发环境采样率 |
| `observability.sampling.production` | float | `0.1` | 生产环境采样率 |

### 2.9 `dynamodb`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `dynamodb.table_prefix` | string | `nexus_` | 表名前缀 |

#### `dynamodb.tables`

所有短名会拼接 `table_prefix`，返回完整表名。

| 短名键 | 默认短名 | 默认完整表名 |
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

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `sqs.queue_prefix` | string | `nexus-` | 队列名前缀 |
| `sqs.queues.build` | string | `build-queue` | 构建队列短名 |
| `sqs.queues.deploy` | string | `deploy-queue` | 部署队列短名 |
| `sqs.queues.notification` | string | `notification-queue` | 通知队列短名 |
| `sqs.dlq.build` | string | `build-dlq` | 构建 DLQ |
| `sqs.dlq.deploy` | string | `deploy-dlq` | 部署 DLQ |
| `sqs.build_visibility_timeout` | int（秒） | `3600` | 构建消息可见性超时 |
| `sqs.deploy_visibility_timeout` | int（秒） | `600` | 部署消息可见性超时 |
| `sqs.visibility_timeout` | int（秒） | `3600` | 默认可见性超时 |
| `sqs.message_retention_days` | int | `14` | 消息保留天数 |
| `sqs.max_retry_count` | int | `3` | 最大重试次数 |

### 2.11 `aurora`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `aurora.host` | string | `my-nexus-demo-db.cluster-c7g64s2w4e6g.ap-southeast-1.rds.amazonaws.com` | 集群端点 |
| `aurora.port` | int | `5432` | 端口 |
| `aurora.database` | string | `nexus_connector_psql` | 数据库名 |
| `aurora.username` | string | `postgres` | 用户名 |
| `aurora.password` | string | `admin123` | 密码（生产必改） |
| `aurora.min_connections` | int | `2` | 最小连接数 |
| `aurora.max_connections` | int | `20` | 最大连接数 |
| `aurora.ssl` | bool | `true` | 启用 SSL |

### 2.12 `valkey`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `valkey.endpoint` | string | `''` | Valkey 端点 |
| `valkey.port` | int | `6379` | 端口 |
| `valkey.ssl` | bool | `true` | 启用 SSL |
| `valkey.decode_responses` | bool | `true` | 解码响应 |
| `valkey.max_connections` | int | `50` | 最大连接数 |

### 2.13 `s3_vectors`

#### `s3_vectors.embedding`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `embedding.model_id` | string | `global.cohere.embed-v4:0` | 嵌入模型 |
| `embedding.dimension` | int | `1536` | 维度 |
| `embedding.distance_metric` | string | `cosine` | 距离度量 |
| `embedding.batch_size` | int | `500` | 批次大小 |
| `embedding.input_type` | string | `search_document` | 输入类型 |

#### `s3_vectors.rerank`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `rerank.enabled` | bool | `true` | 启用重排序 |
| `rerank.model_id` | string | `cohere.rerank-v3-5:0` | 重排模型 |
| `rerank.top_n` | int | `5` | Top N |
| `rerank.min_relevance_score` | float | `0.3` | 最小相关分 |

#### `s3_vectors.query`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `query.default_top_k` | int | `10` | 默认 Top K |
| `query.search_source_types` | list[string] | `[system, template, generated]` | 搜索范围 |

#### 其他

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `s3_vectors.bucket_prefix` | string | `nexus-ai-vectors-` | 桶前缀 |
| `s3_vectors.buckets.system` | string | `system` | 系统桶 |
| `s3_vectors.buckets.agent` | string | `agent` | Agent 桶 |
| `s3_vectors.indexes.prefix` | string | `nexus` | 索引前缀 |
| `s3_vectors.indexes.asset_types` | list[string] | `[tools, prompts, agents]` | 资产类型 |
| `s3_vectors.indexes.source_types` | list[string] | `[system, template, generated]` | 源类型 |
| `s3_vectors.metadata.non_filterable_keys` | list[string] | `[description, file_path, s3_content_key]` | 不可过滤的元数据键 |

### 2.14 `multimodal_parser`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `multimodal_parser.aws.s3_bucket` | string | `awesome-nexus-ai-file-storage` | 多模态 S3 桶 |
| `multimodal_parser.aws.s3_prefix` | string | `multimodal-content/` | S3 前缀 |
| `multimodal_parser.aws.bedrock_region` | string | `us-west-2` | Bedrock 区域 |
| `multimodal_parser.file_limits.max_file_size` | string | `50MB` | 单文件最大 |
| `multimodal_parser.file_limits.max_files_per_request` | int | `10` | 单请求最大文件数 |
| `multimodal_parser.file_limits.supported_formats` | list[string] | `[jpg, jpeg, png, gif, txt, xlsx, docx, csv]` | 支持格式 |
| `multimodal_parser.processing.timeout_seconds` | int | `300` | 处理超时 |
| `multimodal_parser.processing.retry_attempts` | int | `3` | 重试次数 |
| `multimodal_parser.processing.batch_size` | int | `5` | 批次大小 |
| `multimodal_parser.storage.presigned_url_expiration` | int（秒） | `3600` | 预签名 URL 有效期 |
| `multimodal_parser.storage.cleanup_days` | int | `30` | 清理天数 |
| `multimodal_parser.storage.max_retries` | int | `3` | 存储重试次数 |
| `multimodal_parser.storage.retry_delay` | float | `1.0` | 重试间隔（秒） |
| `multimodal_parser.model.primary_model` | string | `us.anthropic.claude-opus-4-5-20251101-v1:0` | 主模型 |
| `multimodal_parser.model.fallback_model` | string | `us.anthropic.claude-sonnet-4-5-20250929-v1:0` | 备用模型 |
| `multimodal_parser.model.max_tokens` | int | `40000` | 最大 token |

---

## 三、`config/logging_config.yaml`

### 3.1 `enhanced_logging`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `enhanced_logging.enable_colors` | bool | `true` | 彩色输出 |
| `enhanced_logging.log_to_file` | bool | `true` | 写入文件 |
| `enhanced_logging.log_file` | string | `logs/enhanced_workflow.log` | 日志文件 |
| `enhanced_logging.log_level` | string | `DEBUG` | DEBUG / INFO / WARNING / ERROR / CRITICAL |
| `enhanced_logging.show_timestamp` | bool | `true` | 显示时间戳 |
| `enhanced_logging.show_agent_name` | bool | `true` | 显示 Agent 名 |
| `enhanced_logging.show_tool_details` | bool | `true` | 显示工具详情 |
| `enhanced_logging.truncate_length.input` | int | `300` | 输入截断长度 |
| `enhanced_logging.truncate_length.output` | int | `300` | 输出截断长度 |
| `enhanced_logging.truncate_length.tool_result` | int | `200` | 工具结果截断长度 |
| `enhanced_logging.separators.workflow` | string | `=` | 工作流分隔符 |
| `enhanced_logging.separators.agent` | string | `-` | Agent 分隔符 |
| `enhanced_logging.separators.tool` | string | `.` | 工具分隔符 |

#### `enhanced_logging.colors`

| Key | 默认值 |
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

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `strands_hooks.enable_enhanced_logging` | bool | `true` | 启用增强日志钩子 |
| `strands_hooks.log_all_agent_calls` | bool | `true` | 记录所有 Agent 调用 |
| `strands_hooks.log_all_tool_calls` | bool | `true` | 记录所有工具调用 |
| `strands_hooks.log_arguments` | bool | `true` | 记录调用参数 |
| `strands_hooks.log_results` | bool | `true` | 记录调用结果 |
| `strands_hooks.sensitive_fields` | list[string] | `[password, token, key, secret]` | 敏感字段脱敏列表 |

### 3.3 `observability`（OTEL 详细参数）

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `observability.service_name` | string | `nexus-ai` | OTEL service.name |
| `observability.environment` | string | `development` | `development` / `staging` / `production` |
| `observability.otlp_endpoint` | string | `http://localhost:4318` | ADOT Collector 端点 |
| `observability.traces.enabled` | bool | `true` | 启用 traces |
| `observability.traces.sample_rate` | float | `1.0` | 采样率（生产建议 0.1-0.5） |
| `observability.traces.propagator` | string | `composite` | `composite` / `xray` / `tracecontext` / `b3` |
| `observability.metrics.enabled` | bool | `true` | 启用 metrics |
| `observability.metrics.export_interval_ms` | int | `60000` | 导出间隔（毫秒） |
| `observability.logs` | object | `{}` | 保留扩展 |

---

## 四、`config/app_manifest.yaml`

顶层键：`app-manifest`。前端通过 `GET /api/v2/manifest` 获取。

### 4.1 `product`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `product.name` | string | `Nexus AI` | 产品名（侧边栏、登录页标题） |
| `product.short_name` | string | `Nexus` | 简称（浏览器标签、通知） |
| `product.tagline` | string | `Agent Intelligence Platform` | 副标题 |
| `product.description` | string | `AI Agent Development & Management Platform` | 描述 |

### 4.2 `version`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `version.current` | string | `0.2.5` | SemVer 版本 |
| `version.release_date` | string | `2026-04-29` | 发布日期 |
| `version.build_number` | string | `''` | CI/CD 自动填入（git SHA） |
| `version.api_version` | string | `v2` | API 版本 |

### 4.3 `branding`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `branding.logo_url` | string | `/logo.png` | 主 logo |
| `branding.logo_dark_url` | string | `''` | 深色模式 logo（可选） |
| `branding.favicon_url` | string | `/favicon.ico` | Favicon |
| `branding.primary_color` | string | `#7c3aed` | 主色（purple-600） |
| `branding.accent_color` | string | `#2563eb` | 强调色（blue-600） |

### 4.4 `organization`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `organization.name` | string | `''` | 公司名 |
| `organization.website` | string | `''` | 网站 |
| `organization.support_email` | string | `''` | 支持邮箱 |
| `organization.documentation_url` | string | `''` | 文档 URL |

### 4.5 `legal`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `legal.copyright` | string | `2026 Nexus AI Platform` | 版权 |
| `legal.terms_url` | string | `''` | 服务条款 URL |
| `legal.privacy_url` | string | `''` | 隐私政策 URL |

### 4.6 `i18n`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `i18n.default_locale` | string | `zh-CN` | 默认语言 |
| `i18n.supported_locales` | list[string] | `[zh-CN, en]` | 支持语言 |
| `i18n.fallback_locale` | string | `zh-CN` | 回退语言 |
| `i18n.allow_user_switch` | bool | `true` | 允许用户切换 |

### 4.7 `features`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `features.show_version_badge` | bool | `true` | 显示版本徽章 |
| `features.show_documentation_link` | bool | `true` | 显示文档链接 |
| `features.allow_agent_export` | bool | `true` | 允许 Agent 导出 |
| `features.allow_tool_creation` | bool | `true` | 允许创建工具 |
| `features.max_agents_per_user` | int | `0` | 每用户最大 Agent 数（0=无限） |
| `features.max_concurrent_sessions` | int | `0` | 每用户最大并发会话（0=无限） |

### 4.8 `deployment`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `deployment.environment` | string | `production` | `development` / `staging` / `production` |
| `deployment.show_env_badge` | bool | `true` | 非生产环境显示徽章 |
| `deployment.instance_id` | string | `''` | 多租户实例 ID |

### 4.9 `login`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `login.title` | string | `''` | 登录页标题（空则用 `product.name`） |
| `login.subtitle` | string | `''` | 登录页副标题（空则用 `product.tagline`） |
| `login.background_style` | string | `gradient` | `gradient` / `image` / `solid` |
| `login.background_image_url` | string | `''` | 背景图（style=image 时） |
| `login.show_copyright` | bool | `true` | 显示版权 |
| `login.custom_notice` | string | `''` | 自定义提示（如维护通知） |

---

## 五、`config/data_connector.yaml`

### 5.1 `data_connector` 顶层

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `data_connector.enabled` | bool | `true` | 全局开关 |
| `data_connector.supported_types` | list[string] | `[mysql, postgresql, s3, dynamodb, http_api, opensearch, s3_vector, bedrock_kb]` | 支持的数据源类型 |

### 5.2 `data_connector.pool_defaults`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `pool_defaults.pool_size` | int | `5` | 连接池大小 |
| `pool_defaults.max_overflow` | int | `10` | 最大溢出连接 |
| `pool_defaults.pool_timeout` | int（秒） | `30` | 获取连接超时 |
| `pool_defaults.pool_recycle` | int（秒） | `3600` | 连接回收时间 |

### 5.3 `data_connector.query_defaults`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `query_defaults.max_rows` | int | `1000` | 单次查询最大行数 |
| `query_defaults.max_execution_time` | int（秒） | `30` | 查询超时 |
| `query_defaults.allow_write` | bool | `false` | 是否允许写操作 |
| `query_defaults.allow_ddl` | bool | `false` | 是否允许 DDL |
| `query_defaults.blocked_keywords` | list[string] | `[DROP, TRUNCATE, ALTER]` | SQL 黑名单 |

### 5.4 `data_connector.s3_defaults`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `s3_defaults.max_file_size` | int（字节） | `104857600` | 单文件最大（100 MB） |
| `s3_defaults.supported_formats` | list[string] | `[csv, json, jsonl, parquet, txt, xlsx, yaml]` | 支持格式 |
| `s3_defaults.presigned_url_expiry` | int（秒） | `3600` | 预签名 URL 有效期 |

### 5.5 `data_connector.vector_defaults`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `vector_defaults.top_k` | int | `10` | 默认 Top-K |
| `vector_defaults.similarity_threshold` | float | `0.7` | 相似度阈值 |
| `vector_defaults.embedding_model` | string | `amazon.titan-embed-text-v2:0` | 默认 Embedding 模型 |

### 5.6 `data_connector.http_api_defaults`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `http_api_defaults.timeout` | int（秒） | `30` | 请求超时 |
| `http_api_defaults.max_retries` | int | `3` | 最大重试次数 |
| `http_api_defaults.retry_delay` | float（秒） | `1.0` | 重试间隔 |

### 5.7 `data_connector.health_check`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `health_check.enabled` | bool | `true` | 启用健康检查 |
| `health_check.interval` | int（秒） | `60` | 检查间隔 |
| `health_check.timeout` | int（秒） | `5` | 检查超时 |

### 5.8 `data_connector.audit`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `audit.enabled` | bool | `true` | 启用审计 |
| `audit.log_query` | bool | `true` | 记录查询语句 |
| `audit.log_result_count` | bool | `true` | 记录返回行数 |
| `audit.log_execution_time` | bool | `true` | 记录执行时间 |
| `audit.retention_days` | int | `90` | 保留天数 |

### 5.9 `data_connector.masking_defaults`

数组，每项包含 `column_pattern` 和 `strategy`。默认规则：

| column_pattern | strategy |
| --- | --- |
| `*password*` | `replace` |
| `*secret*` | `replace` |
| `*token*` | `partial` |

`strategy` 取值：`partial` / `hash` / `replace` / `null`。

### 5.10 `data_connector.prompts`

注入到 Agent system prompt 的数据源说明模板。支持变量：`{connector_name}`, `{connector_id}`, `{connector_type}`, `{database}`, `{bucket}`, `{prefix}`, `{base_url}`, `{table_name}`, `{max_rows}`, `{permission}`, `{write_hint}`, `{region}`, `{endpoint_url}`, `{index_name}`, `{knowledge_base_id}`。

| Key | 用途 |
| --- | --- |
| `prompts.header` | 通用头部 |
| `prompts.mysql` | MySQL |
| `prompts.postgresql` | PostgreSQL |
| `prompts.s3` | S3 |
| `prompts.dynamodb` | DynamoDB |
| `prompts.http_api` | HTTP API |
| `prompts.opensearch` | OpenSearch |
| `prompts.s3_vector` | S3 Vectors |
| `prompts.bedrock_kb` | Bedrock Knowledge Base |
| `prompts.vector` | 通用向量数据库 |

### 5.11 `key_management`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `key_management.storage_backend` | string | `secrets_manager` | `secrets_manager` / `local`（仅开发） |
| `key_management.secrets_manager.prefix` | string | `nexus-ai/keys/` | Secret 名前缀 |
| `key_management.secrets_manager.region` | string | `''` | AWS 区域（空则继承） |
| `key_management.secrets_manager.kms_key_id` | string | `''` | 自定义 KMS 密钥 |

### 5.12 `key_management.key_type_schemas`

每个键类型声明 `label`, `label_en`, `icon`, `description`, `fields`。

| 类型键 | `label` | `label_en` | `icon` | 说明 |
| --- | --- | --- | --- | --- |
| `api_key` | `API 密钥` | `API Key` | `key` | 第三方 API 访问密钥 |
| `database_credentials` | `数据库凭证` | `Database Credentials` | `database` | MySQL/PostgreSQL 等连接凭证 |
| `bearer_token` | `Bearer Token` | `Bearer Token` | `shield` | OAuth / Bearer Token |
| `aws_credentials` | `AWS 凭证` | `AWS Credentials` | `cloud` | Access Key / Secret Key |
| `oauth2` | `OAuth 2.0` | `OAuth 2.0` | `lock` | OAuth 2.0 客户端凭证 |
| `custom` | `自定义密钥` | `Custom` | `settings` | 用户自定义字段 |

字段明细（`fields[*]`）：每项含 `name`, `label`, `label_en`, `type`（`text` / `password` / `number`）, `required`, `placeholder`, 可选 `default`。

| 类型 | 字段 |
| --- | --- |
| `api_key` | `api_key` (password, required) |
| `database_credentials` | `host` (text, required), `port` (number, 默认 `3306`), `database` (text), `username` (text, required), `password` (password, required) |
| `bearer_token` | `token` (password, required) |
| `aws_credentials` | `access_key_id` (password, required), `secret_access_key` (password, required), `session_token` (password) |
| `oauth2` | `client_id` (text, required), `client_secret` (password, required), `token_url` (text) |
| `custom` | `[]`（用户动态添加） |

---

## 六、`config/eventschedule_config.yaml`

顶层键：`event_scheduler`。

### 6.1 `scheduler`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `scheduler.job_scan_interval_seconds` | int | `60` | 作业扫描间隔 |
| `scheduler.task_scan_interval_seconds` | int | `10` | 任务扫描间隔 |
| `scheduler.max_concurrent_tasks` | int | `5` | 最大并发任务 |
| `scheduler.task_timeout_seconds` | int | `3600` | 单任务超时 |
| `scheduler.stuck_task_threshold_seconds` | int | `7200` | 卡死任务阈值 |
| `scheduler.retry_on_failure` | bool | `false` | 失败重试 |
| `scheduler.max_retry_count` | int | `0` | 最大重试次数 |

### 6.2 `workspace`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `workspace.local_base_dir` | string | `.event` | 本地工作空间根 |
| `workspace.s3_bucket_config_key` | string | `event_workspace_s3_bucket` | 从主配置哪个键读取桶名 |
| `workspace.output_file_name` | string | `agent_response.out` | Agent 输出文件名 |
| `workspace.summary_file_name` | string | `task_summary.md` | 总结文件名 |
| `workspace.max_output_size_bytes` | int | `10485760` | 输出最大 10 MB |

### 6.3 `agent_runtime`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `agent_runtime.default_model_id` | string | `''` | 默认模型（空则用全局） |
| `agent_runtime.lite_model_for_analysis` | bool | `true` | 分析用轻量模型 |
| `agent_runtime.analysis_max_tokens` | int | `4096` | 分析最大 token |
| `agent_runtime.analysis_temperature` | float | `0.2` | 分析温度 |
| `agent_runtime.suppress_empty_results` | bool | `true` | 抑制空结果 |
| `agent_runtime.empty_result_tokens` | list[string] | `[HEARTBEAT_OK, NO_ACTION_NEEDED, NOTHING_TO_REPORT, TASK_SKIPPED]` | 视作空结果的令牌 |

### 6.4 `task_type_prompts`

模板键，值为多行字符串，支持变量 `{workspace_s3_path}`, `{task_id}`, `{sequence_number}`, `{scheduled_at}`, `{schedule_expression}`, `{mission_context}`。

| Key | 任务类型 | 主要变量 |
| --- | --- | --- |
| `task_type_prompts.one_time` | 一次性任务 | `workspace_s3_path`, `task_id`, `scheduled_at` |
| `task_type_prompts.recurring` | 周期性任务 | 同上 + `sequence_number`, `schedule_expression` |
| `task_type_prompts.autonomous` | 自主运行任务 | 同上 + `mission_context` |

### 6.5 `analysis_prompt_template`

分析 Agent 的提示词模板，返回结构化 JSON，包含字段：`summary`, `status`, `task_name`, `next_task_description`, `should_terminate`, `terminate_reason`。

---

## 七、`config/model_catalog.yaml`

顶层键：`model_catalog`。`providers` 列表，每项含 `name` 与 `models`；每个模型对象有 `id`, `name`, `tier`（`pro` / `standard` / `lite`）, `is_global`, `supports_vision`。

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

## 八、`config/workflows.yaml`

### 8.1 顶层

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `version` | string | `1.0.0` | 工作流版本 |

### 8.2 `defaults`

#### `defaults.execution`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `defaults.execution.max_retries` | int | `3` | 最大重试次数 |
| `defaults.execution.retry_delay_seconds` | int | `5` | 重试间隔 |
| `defaults.execution.stage_timeout_seconds` | int | `3600` | 单阶段超时 |
| `defaults.execution.total_timeout_seconds` | int | `21600` | 总工作流超时（6 小时） |
| `defaults.execution.checkpoint_interval_seconds` | int | `60` | 检查点间隔 |

#### `defaults.context`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `defaults.context.max_tokens` | int | `100000` | 最大 token 数 |
| `defaults.context.summary_threshold_tokens` | int | `5000` | 摘要触发阈值 |
| `defaults.context.include_rules` | bool | `true` | 包含规则 |
| `defaults.context.include_local_docs` | bool | `true` | 包含本地文档 |

### 8.3 工作流元数据

每个工作流（`agent_build` / `agent_update` / `tool_build` / `skill_build` / `magician`）包含：

| Key | 说明 |
| --- | --- |
| `name` | 内部名 |
| `display_name` | 展示名 |
| `description` | 描述 |
| `version` | 版本 |
| `enabled` | 启用 |
| `prompt_base_path` | 提示词目录 |
| `stages` | 阶段列表 |
| `legacy_name_mapping` | 兼容旧名 |

阶段对象字段：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `name` | string | 阶段标识 |
| `display_name` | string | 阶段中文展示名 |
| `agent_display_name` | string | 执行 Agent 展示名 |
| `prompt_file` | string | 提示词文件（不带扩展名） |
| `log_filename` | string | 日志文件名 |
| `order` | int | 执行顺序 |
| `scope` | string | `project` / `agent` |
| `prerequisites` | list[string] | 前置阶段 |
| `rule_keys` | list[string] | 注入规则键 |
| `supports_iteration` | bool | 支持迭代 |
| `optional` | bool | 可选 |
| `description` | string | 说明 |
| `fork_on_complete` | bool | 完成时分叉（仅 `agent_build.system_architecture`） |
| `join_after_complete` | bool | 完成后汇聚（仅 `agent_build.code_development`） |
| `join_before_start` | bool | 启动前汇聚（仅 `agent_build.deployment`） |

### 8.4 `agent_build` 阶段

| order | name | scope | prerequisites | rule_keys | iteration | optional | 特殊 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | `intent_recognition` | project | `[]` | `[]` | false | false | — |
| 2 | `requirements_analysis` | project | `[intent_recognition]` | `[]` | false | false | — |
| 3 | `system_architecture` | project | `[requirements_analysis]` | `[generation_rules]` | false | false | `fork_on_complete: true` |
| 4 | `agent_design` | agent | `[requirements_analysis, system_architecture]` | `[generation_rules]` | false | false | — |
| 5 | `tools_development` | agent | `[agent_design]` | `[directory_rules, generation_rules, cache_rules, external_resources, custom_rules]` | true | false | — |
| 6 | `prompt_development` | agent | `[requirements_analysis, tools_development]` | 同上 | true | false | — |
| 7 | `code_development` | agent | `[prompt_development]` | 同上 | true | false | `join_after_complete: true` |
| 8 | `deployment` | project | `[system_architecture, code_development]` | `[directory_rules]` | false | false | `join_before_start: true` |

`agent_build.legacy_name_mapping`：`orchestrator→intent_recognition`, `requirements_analyzer→requirements_analysis`, `system_architect→system_architecture`, `agent_designer→agent_design`, `tools_developer/tool_developer→tools_development`, `prompt_engineer→prompt_development`, `agent_code_developer/agent_developer_manager→code_development`, `agent_deployer→deployment`。

### 8.5 `agent_update` 阶段

顶层 `rule_keys: [base_rules, update_workflow_rules]`。

| order | name | scope | prerequisites | iteration | optional |
| --- | --- | --- | --- | --- | --- |
| 1 | `update_orchestrator` | project | `[]` | false | false |
| 2 | `requirements_update` | project | `[update_orchestrator]` | false | false |
| 3 | `tool_update` | project | `[requirements_update]` | true | true |
| 4 | `prompt_update` | project | `[tool_update]` | true | true |
| 5 | `update_deployment` | project | `[prompt_update]` | false | false |

`legacy_name_mapping`：`code_update→update_deployment`。

### 8.6 `tool_build` 阶段

| order | name | scope | prerequisites | rule_keys | iteration |
| --- | --- | --- | --- | --- | --- |
| 1 | `intent_recognition` | project | `[]` | `[]` | false |
| 2 | `tool_design` | project | `[intent_recognition]` | `[generation_rules]` | false |
| 3 | `tool_development` | project | `[tool_design]` | `[directory_rules, generation_rules]` | true |
| 4 | `tool_validation` | project | `[tool_development]` | `[]` | false |
| 5 | `tool_deployment` | project | `[tool_validation]` | `[directory_rules]` | false |

`legacy_name_mapping`：`orchestrator→intent_recognition`, `requirements_analyzer→tool_design`, `tool_designer→tool_design`, `tool_developer→tool_development`, `tool_validator→tool_validation`, `tool_documenter→tool_deployment`。

### 8.7 `skill_build` 阶段

| order | name | scope | prerequisites | rule_keys | iteration |
| --- | --- | --- | --- | --- | --- |
| 1 | `intent_recognition` | project | `[]` | `[]` | false |
| 2 | `skill_design` | project | `[intent_recognition]` | `[generation_rules]` | false |
| 3 | `skill_development` | project | `[skill_design]` | `[directory_rules, generation_rules]` | true |
| 4 | `skill_validation` | project | `[skill_development]` | `[]` | false |
| 5 | `skill_deployment` | project | `[skill_validation]` | `[directory_rules]` | false |

### 8.8 `magician` 阶段

| order | name | prerequisites |
| --- | --- | --- |
| 1 | `magician_orchestrator` | `[]` |

---

## 九、`config/nexus_ai_base_rule.yaml`

顶层键：`workflows`。每类规则含 `version`, `updated_on`, `author`, `change_log`, `attributes`。

### 9.1 规则类别

| 类别 | 说明 |
| --- | --- |
| `base` | 所有工作流共用基础规则 |
| `agent_build` | Agent 构建规则 |
| `agent_update` | Agent 更新规则 |
| `runtime` | 会话运行时规则 |
| `tool_build` | 工具构建规则 |
| `skill_build` | Skill 构建规则 |

### 9.2 规则属性

每类规则的 `attributes` 对象包含以下五个字段：

| 属性键 | 说明 |
| --- | --- |
| `directory_rules` | 目录规则 |
| `generation_rules` | 生成规则 |
| `cache_rules` | 缓存规则 |
| `external_resources` | 外部资源规则 |
| `custom_rules` | 用户自定义规则 |

### 9.3 当前版本快览

| 类别 | version | updated_on | author |
| --- | --- | --- | --- |
| `base` | `latest` | `2026-03-24` | qangz |
| `agent_build` | `latest` | `2025-11-10` | agent_build_workflow |
| `agent_update` | `latest` | `2025-11-10` | qangz |
| `runtime` | `latest` | `2026-03-08` | qangz |
| `tool_build` | `2.0` | `2026-03-30` | qangz |
| `skill_build` | `latest` | `2026-03-30` | qangz |

---

## 十、环境变量覆盖对照表

`ConfigLoader` 在如下方法中读取环境变量，优先于配置文件：

### 10.1 `get_nexus_ai_config()` 相关

| 环境变量 | 配置键 | 默认值 |
| --- | --- | --- |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | `nexus_ai.OTEL_EXPORTER_OTLP_ENDPOINT` | `http://localhost:4318` |

### 10.2 `get_aurora_config()`

| 环境变量 | 配置键 |
| --- | --- |
| `NEXUS_AURORA_HOST` | `aurora.host` |
| `NEXUS_AURORA_PASSWORD` | `aurora.password` |

### 10.3 `get_valkey_config()`

| 环境变量 | 配置键 |
| --- | --- |
| `NEXUS_VALKEY_ENDPOINT` | `valkey.endpoint` |

### 10.4 `get_workflow_config()`

| 环境变量 | 配置键 | 默认 |
| --- | --- | --- |
| `NEXUS_WORKFLOW_MAX_RETRIES` | `workflow.execution.max_retries` | `3` |
| `NEXUS_WORKFLOW_STAGE_TIMEOUT` | `workflow.execution.stage_timeout_seconds` | `3600` |
| `NEXUS_WORKFLOW_MAX_CONTEXT_TOKENS` | `workflow.context.max_tokens` | `100000` |

### 10.5 `get_dynamodb_config()`

| 环境变量 | 配置键 | 默认 |
| --- | --- | --- |
| `NEXUS_DYNAMODB_TABLE_PREFIX` | `dynamodb.table_prefix` | `nexus_` |
| `NEXUS_DYNAMODB_PROJECTS_TABLE` | `dynamodb.tables.projects` | `projects` |
| `NEXUS_DYNAMODB_STAGES_TABLE` | `dynamodb.tables.stages` | `stages` |
| `NEXUS_DYNAMODB_TASKS_TABLE` | `dynamodb.tables.tasks` | `tasks` |

### 10.6 `get_sqs_config()`

| 环境变量 | 配置键 | 默认 |
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

覆盖 `config/service_config.yaml` 中的 `service-config`。

| 环境变量 | 配置键 | 默认 |
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

## 十一、`config/service_config.yaml`（由 `get_service_config()` 消费）

### 11.1 `service-config.api`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `api.host` | string | `0.0.0.0` | API 监听地址 |
| `api.port` | int | `8000` | API 端口 |
| `api.log_level` | string | `info` | 日志级别 |
| `api.workers` | int | `1` | Worker 数 |
| `api.thread_pool_size` | int | `64` | 线程池大小 |
| `api.agent_creation_timeout` | int（秒） | `120` | Agent 创建超时 |
| `api.sse_heartbeat_interval` | int（秒） | `15` | SSE 心跳间隔 |
| `api.max_concurrent_streams` | int | `0` | 最大并发流（0=不限） |

### 11.2 `service-config.worker`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `worker.thread_pool_size` | int | `32` | Worker 线程池 |

### 11.3 `service-config.web`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `web.host` | string | `0.0.0.0` | Web 监听地址 |
| `web.port` | int | `3000` | Web 端口 |

### 11.4 `service-config.mcp`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `mcp.port` | int | `9000` | MCP 端口 |

### 11.5 `service-config.bridge`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `bridge.host` | string | `0.0.0.0` | Bridge 监听地址 |
| `bridge.port` | int | `8001` | Bridge 端口 |
| `bridge.log_level` | string | `info` | 日志级别 |
| `bridge.command_timeout` | int（秒） | `900` | 命令超时 |
| `bridge.connection_timeout` | int（秒） | `1200` | 连接超时 |

### 11.6 `service-config.sandbox_controller`

| Key | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `sandbox_controller.host` | string | `0.0.0.0` | 监听地址 |
| `sandbox_controller.port` | int | `8002` | 端口 |
| `sandbox_controller.log_level` | string | `info` | 日志级别 |
| `sandbox_controller.patrol_interval` | int（秒） | `30` | 巡检间隔 |
| `sandbox_controller.heartbeat_timeout` | int（秒） | `90` | 心跳超时 |
| `sandbox_controller.scale_down_idle_minutes` | int | `10` | 缩容空闲阈值（分钟） |
| `sandbox_controller.min_nodes` | int | `1` | 最小节点数 |

---

## 十二、最小示例

### 12.1 默认配置片段

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

### 12.2 通过环境变量覆盖

```bash
export NEXUS_DYNAMODB_TABLE_PREFIX=prod_
export NEXUS_SQS_MAX_RETRY_COUNT=5
export API_PORT=9090
export NEXUS_AURORA_HOST=my-cluster.cluster-xxx.rds.amazonaws.com
export NEXUS_AURORA_PASSWORD=${PROD_DB_PWD}
```

### 12.3 代码中读取

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
