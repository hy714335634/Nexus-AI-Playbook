---
title: 部署参数
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - infrastructure/**
    - nexus-cli
  generated_at: 2026-05-09T01:29:02+00:00
  generated_by: docs-sync v2
---

# 部署参数

本文档穷举 Nexus-AI 所有部署模式的参数。每个参数都标注：**类型 / 默认值 / 是否必填 / 影响的资源**。参数值来自 `infrastructure/cloudformation/nexus-ai-env.yaml`、`infrastructure/cloudformation/deploy.sh`、`infrastructure/sandbox/*`。

## 部署模式总览

| 模式 | 入口 | 适用场景 | 需要 AWS 账号 |
|------|------|----------|----------------|
| 本地开发 | `nexus-cli service start` | 单机开发调试；Agent 运行在本机 | 只需 Bedrock、DDB、S3、SQS 凭证 |
| EC2 手动部署 | 手动创建 EC2 + `nexus-cli init` + `nexus-cli service start` | 单节点测试环境 | 是 |
| CloudFormation 一键部署 | `infrastructure/cloudformation/deploy.sh &lt;env-prefix&gt;` | 完整隔离的测试环境；VPC + ALB + CloudFront + Aurora + Valkey | 是 |
| Firecracker 沙箱 | 主栈 + 沙箱栈（`EnableSandbox=true`） | Agent 执行隔离；每次会话一个 microVM | 是 |
| AgentCore | 外部 Bedrock AgentCore 托管 | 托管 Agent 运行时（配置中 `runtime_type=agentcore`） | 是 |

---

## CloudFormation 一键部署（主栈）

### deploy.sh 命令行参数

调用方式：`./deploy.sh <环境前缀> [选项]`。第一个位置参数 `环境前缀` 为必填，其余均为选项。

| 参数 | 类型 | 默认值 | 必填 | 说明 |
|------|------|--------|------|------|
| `<环境前缀>` | 位置参数 | — | 是 | 环境名称前缀；仅允许小写字母、数字、连字符。例：`nexus-ai-guanggao` |
| `--delete` | flag | false | 否 | 删除该环境的 CloudFormation Stack |
| `--clean-data` | flag | false | 否 | 与 `--delete` 配合使用；同时清空并删除该环境的 S3 桶、DDB 表、SQS 队列 |
| `--instance-type` | string | `c8i.2xlarge` | 否 | EC2 实例类型 |
| `--branch` | string | `main` | 否 | Git 分支 |
| `--user` | string | `admin` | 否 | Web 登录用户名 |
| `--password` | string | `nexus` | 否 | Web 登录密码 |
| `--github-token` | string | 空 | private repo 必填 | GitHub Personal Access Token，仅需 `Contents: Read-only` 权限 |
| `--db-password` | string | `Nexus2026!` | 否 | Aurora PostgreSQL 管理员密码 |
| `--no-wait` | flag | false | 否 | 提交后不等待 Stack 创建完成 |

部署区域固定为 `us-west-2`（写死在脚本变量 `REGION` 中）。Stack 名称固定为 `<环境前缀>-stack`。

### deploy.sh 示例

```bash
# 基础部署（public repo）
./deploy.sh nexus-ai-guanggao

# 私有仓库，自带 GitHub Token
./deploy.sh nexus-ai-guanggao --github-token ghp_xxxxxxxxxxxx

# 自定义账号密码
./deploy.sh nexus-ai-luoji --github-token ghp_xxx --user test --password test123

# 指定实例类型和分支
./deploy.sh nexus-ai-guanggao --github-token ghp_xxx --instance-type c6i.xlarge --branch dev

# 不等待完成（后台创建）
./deploy.sh nexus-ai-guanggao --github-token ghp_xxx --no-wait

# 删除环境（仅删 Stack，保留数据资源）
./deploy.sh nexus-ai-guanggao --delete

# 删除环境并清理数据资源
./deploy.sh nexus-ai-guanggao --delete --clean-data
```

### CloudFormation 模板参数

`deploy.sh` 最终调用 `aws cloudformation create-stack --template-body file://nexus-ai-env.yaml`，并传入参数。下表列出 `nexus-ai-env.yaml` 所有 `Parameters`：

| Key | 类型 | 默认值 | 必填 | NoEcho | 说明 / 影响 |
|-----|------|--------|------|--------|--------------|
| `EnvironmentPrefix` | String | — | 是 | 否 | 所有资源命名前缀。正则 `[a-z0-9\-]+` |
| `VpcCidr` | String | `10.0.0.0/16` | 否 | 否 | VPC 地址段；子网按 `!Cidr [VpcCidr, 4, 8]` 划分 4 段 |
| `InstanceType` | String | `c8i.2xlarge` | 否 | 否 | 主 EC2 实例类型 |
| `KeyName` | String | `Og_Normal` | 否 | 否 | SSH Key Pair 名称；须提前在账号中存在 |
| `IamInstanceProfile` | String | `admin-for-ec2` | 否 | 否 | EC2 Instance Profile 名称；须提前存在 |
| `GitRepoUrl` | String | `https://github.com/hy714335634/Nexus-AI.git` | 否 | 否 | 代码仓库地址 |
| `GitBranch` | String | `main` | 否 | 否 | Git 分支 |
| `VolumeSize` | Number | `150` | 否 | 否 | EC2 根卷大小（GB） |
| `AuthUser` | String | `admin` | 否 | 否 | Web 登录用户名 |
| `AuthPassword` | String | `nexus` | 否 | 是 | Web 登录密码；写入 `config/default_config.yaml` |
| `GitHubToken` | String | 空 | private repo 必填 | 是 | GitHub PAT；空则使用无认证 HTTPS clone |
| `DBUsername` | String | `nexus_admin` | 否 | 否 | Aurora PostgreSQL 管理员用户名 |
| `DBPassword` | String | `Nexus2026!` | 否 | 是 | Aurora PostgreSQL 管理员密码 |
| `AuroraMinCapacity` | Number | `0.5` | 否 | 否 | Aurora Serverless v2 最小 ACU |
| `AuroraMaxCapacity` | Number | `16` | 否 | 否 | Aurora Serverless v2 最大 ACU |
| `ValkeyMaxDataGB` | Number | `5` | 否 | 否 | Valkey Serverless 最大数据存储（GB） |
| `ValkeyMaxECPU` | Number | `15000` | 否 | 否 | Valkey Serverless 每秒最大 ECPU |
| `AmiId` | SSM Param | `/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64` | 否 | 否 | 通过 SSM 自动解析的 Amazon Linux 2023 最新 AMI |
| `EnableSandbox` | String | `false` | 否 | 否 | 允许值：`true` / `false`。为 `true` 时创建 EFS（代码卷 + 数据卷） |
| `SandboxEFSId` | String | 空 | 否 | 否 | 沙箱 EFS 文件系统 ID（如通过 `sandbox-infra.yaml` 单独部署） |
| `SandboxECRName` | String | 空 | 否 | 否 | 沙箱 ECR 仓库名；留空使用 `${EnvironmentPrefix}-sandbox-runtime` |

### 资源命名规则

从 `EnvironmentPrefix` 派生的所有资源名称：

| 资源类型 | 命名格式 | 示例（`nexus-ai-guanggao`） |
|----------|----------|------------------------------|
| VPC | `{prefix}-vpc` | `nexus-ai-guanggao-vpc` |
| 公有子网 | `{prefix}-public-{1,2}` | `nexus-ai-guanggao-public-1` |
| 私有子网 | `{prefix}-private-{1,2}` | `nexus-ai-guanggao-private-1` |
| Internet Gateway | `{prefix}-igw` | `nexus-ai-guanggao-igw` |
| NAT EIP | `{prefix}-nat-eip` | `nexus-ai-guanggao-nat-eip` |
| NAT Gateway | `{prefix}-nat` | `nexus-ai-guanggao-nat` |
| 公有路由表 | `{prefix}-public-rt` | `nexus-ai-guanggao-public-rt` |
| 私有路由表 | `{prefix}-private-rt` | `nexus-ai-guanggao-private-rt` |
| ALB | `{prefix}-alb` | `nexus-ai-guanggao-alb` |
| ALB 安全组 | `{prefix}-alb-sg` | `nexus-ai-guanggao-alb-sg` |
| EC2 安全组 | `{prefix}-ec2-sg` | `nexus-ai-guanggao-ec2-sg` |
| Aurora 安全组 | `{prefix}-aurora-sg` | `nexus-ai-guanggao-aurora-sg` |
| Valkey 安全组 | `{prefix}-valkey-sg` | `nexus-ai-guanggao-valkey-sg` |
| EFS 安全组 | `{prefix}-efs-sg` | `nexus-ai-guanggao-efs-sg` |
| Aurora Subnet Group | `{prefix}-aurora-subnets` | `nexus-ai-guanggao-aurora-subnets` |
| Aurora Cluster | `{prefix}-aurora` | `nexus-ai-guanggao-aurora` |
| Aurora Writer | `{prefix}-aurora-writer` | `nexus-ai-guanggao-aurora-writer` |
| Valkey Serverless | `{prefix}-valkey` | `nexus-ai-guanggao-valkey` |
| EFS 代码卷 | `{prefix}-efs-code` | `nexus-ai-guanggao-efs-code` |
| EFS 数据卷 | `{prefix}-efs-data` | `nexus-ai-guanggao-efs-data` |
| API 目标组 | `{prefix}-api-tg` | `nexus-ai-guanggao-api-tg` |
| Docs 目标组 | `{prefix}-docs-tg` | `nexus-ai-guanggao-docs-tg` |
| CloudFront | `{prefix}-cf` | `nexus-ai-guanggao-cf` |
| Stack | `{prefix}-stack` | `nexus-ai-guanggao-stack` |
| DDB 表前缀 | 连字符替换为下划线 + `_` | `nexus_ai_guanggao_` |
| SQS 队列前缀 | `{prefix}-` | `nexus-ai-guanggao-` |
| S3 桶后缀 | 原桶名 + `-&lt;env&gt;`（`env` = 去掉 `nexus-ai-` 后的剩余） | `nexus-ai-artifacts-2026-guanggao` |

### 子网划分

`!Cidr [VpcCidr, 4, 8]` 将 VPC 地址段划成 4 个 /24 子网（当 `VpcCidr=10.0.0.0/16` 时）：

| 子网 | 索引 | 示例 CIDR | AZ 位置 | 路由出口 |
|------|------|-----------|---------|-----------|
| 公有子网 1 | 0 | 10.0.0.0/24 | 第 1 个 AZ | IGW |
| 公有子网 2 | 1 | 10.0.1.0/24 | 第 2 个 AZ | IGW |
| 私有子网 1 | 2 | 10.0.2.0/24 | 第 1 个 AZ | NAT |
| 私有子网 2 | 3 | 10.0.3.0/24 | 第 2 个 AZ | NAT |

### 安全组入站规则

**ALB 安全组（`{prefix}-alb-sg`）**：

| 协议 | 端口 | 来源 | 说明 |
|------|------|------|------|
| TCP | 80 | `pl-82a045eb`（CloudFront 前缀列表） | 仅允许 CloudFront 回源 IP |

**EC2 安全组（`{prefix}-ec2-sg`）**：

| 协议 | 端口 | 来源 | 说明 |
|------|------|------|------|
| TCP | 3000 | ALB SG | Frontend (Next.js) |
| TCP | 8000 | ALB SG | API (FastAPI) |
| TCP | 8001 | ALB SG | Bridge 服务 |
| TCP | 5173 | ALB SG | Docs (Playbook) |
| TCP | 22 | 0.0.0.0/0 | SSH |
| TCP | 8001 | 10.0.0.0/8 | VPC 内的 Bridge 调用（沙箱任务） |
| TCP | 8000 | 10.0.0.0/8 | VPC 内预留的内部 API 调用 |
| TCP | 8080 | 10.0.0.0/8 | sandbox-host 管理 API |
| TCP | 18000-18100 | 10.0.0.0/8 | Firecracker microVM 代理端口 |
| TCP | 4318 | 10.0.0.0/8 | OTLP HTTP receiver（ADOT Collector） |
| TCP | 4317 | 10.0.0.0/8 | OTLP gRPC receiver |

**Aurora 安全组（`{prefix}-aurora-sg`）**：

| 协议 | 端口 | 来源 | 说明 |
|------|------|------|------|
| TCP | 5432 | EC2 SG | PostgreSQL，仅 EC2 可连 |

**Valkey 安全组（`{prefix}-valkey-sg`）**：

| 协议 | 端口 | 来源 | 说明 |
|------|------|------|------|
| TCP | 6379 | EC2 SG | Valkey，仅 EC2 可连 |

**EFS 安全组（`{prefix}-efs-sg`，仅 `EnableSandbox=true` 时创建）**：

| 协议 | 端口 | 来源 | 说明 |
|------|------|------|------|
| TCP | 2049 | EC2 SG | NFS |

### ALB 路由规则

| 路径 | 目标组端口 | 上游服务 |
|------|-------------|-----------|
| `/api/*` | 8000 | FastAPI |
| `/playbook*` | 5173 | Playbook 文档站点 |
| `/bridge/*` | 8001 | Bridge 服务 |
| 默认 | 3000 | Frontend (Next.js) |

### 健康检查

API 目标组使用：

| 项 | 值 |
|----|-----|
| Protocol | HTTP |
| Path | `/docs` |
| Interval | 30s |
| Timeout | 5s |
| Healthy Threshold | 5 |
| Unhealthy Threshold | 2 |
| Matcher | `200` |

### Aurora / Valkey 规格

| 项 | Aurora PostgreSQL | Valkey Serverless |
|----|-------------------|---------------------|
| 引擎版本 | `16.4` | Major `8` |
| 数据库名 / 端口 | `nexus` / 5432 | — / 6379 |
| 容量单位 | ACU（0.5–16） | DataStorage GB + ECPU/s |
| 备份保留 | 7 天 | — |
| 加密 | `StorageEncrypted: true` | — |
| DeletionProtection | `false` | — |
| 子网 | 私有子网 1 + 2 | 私有子网 1 + 2 |

### EC2 初始化流程

主 EC2 UserData 依次执行：

1. 安装 `git`（AL2023 默认不含）。
2. 克隆代码仓库到 `/home/ec2-user/&lt;prefix&gt;/`，支持 GitHub Token 认证。
3. 执行 `setup_env_alinux2023.sh` 安装 Python 3.13、Node.js、uv、Docker 等。
4. `cd web && npm run build` 编译前端。
5. 修改 `config/default_config.yaml`：替换 DDB/SQS/S3 前缀、写入 `AuthUser`/`AuthPassword`、关闭 SSO。
6. `nexus-cli init` 创建 DynamoDB 表、SQS 队列、S3 桶。
7. `nexus-cli service start` + `nexus-cli service start --event` 启动所有服务。

典型耗时：EC2 初始化 20–30 分钟，CloudFront 分发额外 5–10 分钟。

### 删除行为

| 操作 | 会删除 | 不会删除 |
|------|--------|-----------|
| `--delete` | VPC、EC2、ALB、CloudFront、Aurora、Valkey、（可选）EFS | DDB 表、SQS 队列、S3 桶 |
| `--delete --clean-data` | 上述所有 + DDB 表（按前缀匹配） + SQS 队列（按前缀匹配） + S3 桶（按后缀匹配） | — |

`--clean-data` 会在删除 Stack 之前，依次按下述规则清理：

| 资源 | 匹配规则 |
|------|-----------|
| S3 | `ends_with(Name, '-<env-prefix 去掉 nexus-ai->')` |
| DDB | `starts_with(<env-prefix 连字符转下划线>_)` |
| SQS | `queue-name-prefix=&lt;env-prefix&gt;-` |

---

## 沙箱运行时参数（Firecracker microVM）

沙箱配置位于 `config/default_config.yaml` 的 `sandbox` 段（默认 `enabled: false`）。启用沙箱需在主栈部署时设 `EnableSandbox=true`，并单独部署沙箱栈（ASG + UserData）。

### sandbox 顶层

| Key | 类型 | 默认值 | 必填 | 说明 |
|-----|------|--------|------|------|
| `sandbox.enabled` | bool | `false` | 否 | 是否启用沙箱 |

### sandbox.policy

| Key | 类型 | 默认值 | 必填 | 说明 |
|-----|------|--------|------|------|
| `sandbox.policy.default_runtime` | string | `local` | 否 | 默认运行时；可选 `local` / `firecracker` |
| `sandbox.policy.allow_user_override` | bool | `true` | 否 | 是否允许用户在请求中覆盖运行时 |
| `sandbox.policy.allowed_runtimes` | list | `['local', 'firecracker']` | 否 | 允许的运行时列表 |
| `sandbox.policy.max_concurrent_vms` | int | `50` | 否 | 全局最大并发 VM 数 |

### sandbox.config

| Key | 类型 | 默认值 | 必填 | 说明 |
|-----|------|--------|------|------|
| `sandbox.config.efs_code_id` | string | 空 | 是（若启用） | EFS 代码卷 FileSystem ID |
| `sandbox.config.efs_code_mount` | string | `/nexus-efs` | 否 | 节点上 EFS 代码卷挂载路径 |
| `sandbox.config.repo_root` | string | `/nexus-efs/nexus-ai` | 否 | 代码仓库在 EFS 内的路径 |
| `sandbox.config.efs_data_id` | string | 空 | 是（若启用） | EFS 数据卷 FileSystem ID |
| `sandbox.config.efs_data_mount` | string | `/nexus-efs-data` | 否 | 节点上 EFS 数据卷挂载路径 |
| `sandbox.config.workspace_prefix` | string | `workspaces` | 否 | EFS 数据卷内 session workspace 子目录 |
| `sandbox.config.envs_prefix` | string | `envs` | 否 | EFS 数据卷内 agent venv 子目录 |
| `sandbox.config.rootfs_path` | string | `/nexus-efs-data/rootfs/base.ext4` | 否 | rootfs 模板路径 |
| `sandbox.config.session_s3_bucket` | string | 空 | 否 | 留空则继承主 config |
| `sandbox.config.valkey_endpoint` | string | 空 | 否 | 留空则继承主 config |
| `sandbox.config.valkey_port` | int | `6379` | 否 | — |
| `sandbox.config.valkey_ssl` | bool | `true` | 否 | — |
| `sandbox.config.dynamodb_table_prefix` | string | 空 | 否 | 留空则继承主 config |
| `sandbox.config.vm_vcpu` | int | `2` | 否 | 每 VM 的 vCPU 数 |
| `sandbox.config.vm_memory_mib` | int | `1024` | 否 | 每 VM 的内存（MB） |
| `sandbox.config.vm_port` | int | `8080` | 否 | VM 内 runtime_app 监听端口 |
| `sandbox.config.stream_maxlen` | int | `5000` | 否 | Valkey Stream 最大长度 |
| `sandbox.config.invocation_timeout` | int | `600` | 否 | Agent 执行超时（秒） |
| `sandbox.config.idle_timeout` | int | `300` | 否 | VM 空闲后销毁（秒） |
| `sandbox.config.log_level` | string | `INFO` | 否 | 日志级别 |

### sandbox.pool

| Key | 类型 | 默认值 | 必填 | 说明 |
|-----|------|--------|------|------|
| `sandbox.pool.instance_type` | string | `c6i.2xlarge` | 否 | 节点 EC2 实例类型（8 vCPU / 16 GB） |
| `sandbox.pool.min_size` | int | `1` | 否 | ASG 最小节点数 |
| `sandbox.pool.max_size` | int | `5` | 否 | ASG 最大节点数 |
| `sandbox.pool.vms_per_node` | int | `4` | 否 | 每节点最大 VM 数；受限于 `instance_vcpu / vm_vcpu` |
| `sandbox.pool.key_name` | string | 空 | 否 | 节点 SSH Key Pair |
| `sandbox.pool.cluster_name` | string | 空 | 部署后填入 | ECS Cluster 名（仅用于 ASG Capacity Provider） |
| `sandbox.pool.subnets` | list | `[]` | 是（若启用） | 节点所在子网 ID 列表 |
| `sandbox.pool.security_groups` | list | `[]` | 是（若启用） | 节点安全组 ID 列表 |
| `sandbox.pool.prewarm_featured_agents` | bool | `true` | 否 | 启动时预创建 featured agent VM |
| `sandbox.pool.prewarm_idle_vms` | int | `0` | 否 | 额外预热空 VM 数（0 表示按需） |

### 沙箱节点 UserData 固定参数

沙箱节点 UserData（`infrastructure/sandbox/setup-node.sh`）中写死的参数：

| 项 | 值 | 说明 |
|----|-----|------|
| Firecracker 版本 | `1.10.1` | 从 GitHub Release 下载 |
| 内核版本 | `5.10.230` | 首节点用源码编译，后续从 EFS 缓存加载（含 NFS 支持） |
| 内核配置 | Firecracker 官方 `microvm-kernel-ci-x86_64-5.10.config` | — |
| rootfs 大小 | 2048 MB | `dd` + `mkfs.ext4` |
| rootfs 构建基础镜像 | `amazonlinux:2023` | 通过 Docker 导出 |
| rootfs 内 Python | `python3.11` | `ln -sf python3.11 /usr/bin/python3` |
| rootfs 缓存路径 | `/nexus-efs-data/rootfs/base.ext4` | 首次构建后写回 EFS |
| rootfs 缓存失效判定 | `requirements.txt` 的 MD5 | 存入 `/nexus-efs-data/rootfs/requirements.md5` |
| 本地存储挂载点 | `/local` | 优先用 `/dev/nvme1n1` 或 `/dev/nvme2n1`，否则用 EBS |
| 网络 bridge | `br0` | `172.16.0.1/24` |
| DNS 转发器 | `dnsmasq` | 监听 `172.16.0.1`，上游 `169.254.169.253` |
| VM 代理端口范围 | 18001–18100 | 每 VM 一个端口 |

### sandbox-host HTTP API

节点上 `sandbox-host.service` 暴露端口 `8080`：

| Method | Path | 说明 |
|--------|------|------|
| POST | `/vms/create` | 创建一个 microVM |
| POST | `/vms/{vm_id}/destroy` | 销毁指定 microVM |
| GET | `/vms` | 列出本节点所有 VM 及容量 |
| GET | `/health` | 节点健康状态 |

**POST `/vms/create` 请求体**：

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `session_id` | string | 是 | 会话 ID |
| `agent_id` | string | 是 | Agent ID |
| `prompt_path` | string | 是 | Prompt 模板路径 |
| `vcpu` | int | 否 | 覆盖 `vm_vcpu` |
| `memory_mib` | int | 否 | 覆盖 `vm_memory_mib` |

**POST `/vms/create` 响应体**：

| 字段 | 类型 | 说明 |
|------|------|------|
| `vm_id` | string | `fc-&lt;hex&gt;` |
| `ip` | string | VM 内网 IP（仅节点内可达） |
| `proxy_port` | int | 节点上的反向代理端口（VPC 内可达） |
| `status` | string | `running` |

### Firecracker VM 规格（默认）

| 项 | 值 |
|----|-----|
| vCPU | 2 |
| 内存 | 1024 MB |
| 内部端口 | 8080 |
| rootfs | `base.ext4`（copy-on-write overlay） |
| 网络 | TAP + bridge `br0`，IP 段 `172.16.0.0/24` |
| 启动耗时 | ~1.5 s（kernel boot + NFS mount + Python 启动） |
| 端到端首次响应 | ~5–7 s |

### microVM /init 参数（从 kernel cmdline 解析）

| 变量 | 说明 |
|------|------|
| `VM_IP` | VM 的 eth0 IP |
| `GW_IP` | 默认网关（= bridge `br0` 的 IP，通常 `172.16.0.1`） |
| `EFS_CODE_IP` | EFS 代码卷 mount target IP |
| `EFS_DATA_IP` | EFS 数据卷 mount target IP |
| `EFS_CODE_SUBDIR` | EFS 代码卷内挂载子目录 |
| `SESSION_ID` | 会话 ID |
| `AGENT_ID` | Agent ID |
| `PROMPT_PATH` | Prompt 模板路径 |
| `AWS_REGION` | AWS 区域 |
| `TEMPLATE_MOUNTS` | 只读模板卷，格式 `aid1:v1:mount1|aid2:v2:mount2` |

### DynamoDB 表（沙箱）

| 表（带前缀） | PK | 用途 |
|---------------|-----|------|
| `{prefix}sandbox_nodes` | `node_id`（EC2 instance ID） | 节点注册表；维护节点状态、容量 |
| `{prefix}sandbox_instances` | `instance_id`（VM ID） | VM 实例注册表 |
| `{prefix}sandbox_logs` | `log_id` | 调度日志（TTL 30 天） |

### 资源管理策略

`ResourceManager.select_node()` 选节点的优先级：

1. **亲和性**：已有该 `agent_id` 的 venv 缓存的节点优先。
2. **负载均衡**：按剩余 vCPU 降序选。
3. **扩容**：所有节点满载时，触发 ASG scale-up，等待 120 秒后递归重选。

---

## 本地开发模式

不使用 CloudFormation。主要由 `nexus-cli` 驱动，配置读自 `config/default_config.yaml`。参见 `reference/cli-commands`（命令） 和 `reference/config-options`（配置项）。本地模式下：

| 资源 | 默认位置 |
|------|-----------|
| DDB / S3 / SQS | 真实 AWS 账号（读 `~/.aws/credentials`） |
| 主 API | `http://localhost:8000` |
| 前端 | `http://localhost:3000` |
| Bridge | `http://localhost:8001` |
| Docs | `http://localhost:5173` |
| Agent 运行时 | `runtime_type=local`（本机进程） |

---

## 常见陷阱

| 陷阱 | 现象 | 规避 |
|------|------|------|
| `EnvironmentPrefix` 含大写或下划线 | Stack 创建失败 | 仅用小写字母、数字、连字符 |
| 未提供 `--github-token` 且为私有仓库 | EC2 UserData 克隆失败，初始化日志报 401 | 提供 fine-grained token，仅勾选 `Contents: Read-only` |
| `KeyName`（默认 `Og_Normal`）不存在 | Stack 创建失败 | 提前在账号中创建 Key Pair，或通过模板参数覆盖 |
| `IamInstanceProfile`（默认 `admin-for-ec2`）不存在 | EC2 启动失败 | 提前创建带 Bedrock / S3 / DDB / SQS / CloudWatch 权限的 Instance Profile |
| 未开启 KVM 的机型 | 沙箱节点 UserData 报 `/dev/kvm not available` | 选支持 KVM 的 EC2 家族（如 `c6i.*`、`c8i.*` 裸金属或普通 x86） |
| `VolumeSize` 过小 | Python 3.13 编译 + 依赖安装耗尽磁盘 | 保留默认 150 GB |
| `--clean-data` 错删数据 | S3 / DDB / SQS 永久丢失 | 仅在确实要彻底清理时使用；无 `--clean-data` 时这三类资源保留 |
| Aurora `DeletionProtection: false` | `--delete` 会连同 Aurora 一起删除，数据丢失 | 生产环境须先手动开启删除保护，或改写模板 |
| 沙箱 `rootfs` 缓存失效判断仅基于 `requirements.txt` 的 MD5 | 修改 `requirements.txt` 之外的依赖不会重建 rootfs | 需要强制重建时手动删除 `/nexus-efs-data/rootfs/base.ext4` |

## 验证步骤

### 部署后验证

```bash
# 查看 Stack 输出（ALB DNS、CloudFront 域名等）
aws cloudformation describe-stacks \
  --stack-name <env-prefix>-stack \
  --region us-west-2 \
  --query 'Stacks[0].Outputs'

# SSH 登录主 EC2
ssh -i <KeyName>.pem ec2-user@<EC2 公网 IP>

# 查看 UserData 初始化日志
sudo cat /var/log/nexus-init.log

# 查看服务状态
cd /home/ec2-user/<env-prefix>
source .venv/bin/activate
python nexus-cli service status

# 查看服务日志
python nexus-cli service logs
```

### 沙箱节点验证

```bash
# 节点健康
curl http://<node-private-ip>:8080/health

# 列出节点上 VM
curl http://<node-private-ip>:8080/vms

# 查看 sandbox-host 日志
sudo journalctl -u sandbox-host -f
```

## 退出码

`deploy.sh` 使用 `set -e`，任一命令失败即中止并以该命令的退出码退出。显式退出点：

| 退出码 | 触发条件 |
|--------|-----------|
| `0` | 创建 / 删除成功；或 `--delete` 被用户取消 |
| `1` | 未传入环境前缀；未知参数；模板文件不存在；Stack 已存在；其他 AWS CLI 错误 |
