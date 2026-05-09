---
title: Deployment Parameters
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - infrastructure/**
    - nexus-cli
  generated_at: 2026-05-09T01:29:02+00:00
  generated_by: docs-sync v2
---

# Deployment Parameters

This document exhaustively lists every parameter across all Nexus-AI deployment modes. Each parameter records its **type / default / required / resources affected**. Values come from `infrastructure/cloudformation/nexus-ai-env.yaml`, `infrastructure/cloudformation/deploy.sh`, and `infrastructure/sandbox/*`.

## Deployment Modes at a Glance

| Mode | Entry point | Use case | AWS account required |
|------|-------------|----------|------------------------|
| Local development | `nexus-cli service start` | Single-host development; agents run on the host | Only Bedrock / DDB / S3 / SQS credentials |
| EC2 manual deploy | Manually create EC2 + `nexus-cli init` + `nexus-cli service start` | Single-node test environment | Yes |
| CloudFormation one-shot | `infrastructure/cloudformation/deploy.sh &lt;env-prefix&gt;` | Fully isolated test environment with VPC + ALB + CloudFront + Aurora + Valkey | Yes |
| Firecracker sandbox | Main stack + sandbox stack (`EnableSandbox=true`) | Agent execution isolation; one microVM per session | Yes |
| AgentCore | External Bedrock AgentCore runtime | Managed agent runtime (`runtime_type=agentcore` in config) | Yes |

---

## CloudFormation One-Shot (Main Stack)

### deploy.sh Command-Line Flags

Invocation: `./deploy.sh &lt;env-prefix&gt; [flags]`. The first positional argument `&lt;env-prefix&gt;` is required; all other flags are optional.

| Flag | Type | Default | Required | Description |
|------|------|---------|----------|-------------|
| `&lt;env-prefix&gt;` | positional | — | Yes | Environment name prefix; only lowercase letters, digits, and hyphens allowed. Example: `nexus-ai-guanggao` |
| `--delete` | flag | false | No | Delete the CloudFormation Stack for this environment |
| `--clean-data` | flag | false | No | Used with `--delete`; also empties and deletes S3 buckets, DDB tables, and SQS queues for this environment |
| `--instance-type` | string | `c8i.2xlarge` | No | EC2 instance type |
| `--branch` | string | `main` | No | Git branch |
| `--user` | string | `admin` | No | Web login username |
| `--password` | string | `nexus` | No | Web login password |
| `--github-token` | string | empty | Required for private repo | GitHub Personal Access Token; only `Contents: Read-only` permission needed |
| `--db-password` | string | `Nexus2026!` | No | Aurora PostgreSQL admin password |
| `--no-wait` | flag | false | No | Return immediately after submission; do not wait for Stack creation to complete |

Region is hardcoded to `us-west-2` (via the script's `REGION` variable). Stack name is fixed at `&lt;env-prefix&gt;-stack`.

### deploy.sh Examples

```bash
# Basic deploy (public repo)
./deploy.sh nexus-ai-guanggao

# Private repo with GitHub Token
./deploy.sh nexus-ai-guanggao --github-token ghp_xxxxxxxxxxxx

# Custom account/password
./deploy.sh nexus-ai-luoji --github-token ghp_xxx --user test --password test123

# Custom instance type and branch
./deploy.sh nexus-ai-guanggao --github-token ghp_xxx --instance-type c6i.xlarge --branch dev

# Do not wait for completion (background creation)
./deploy.sh nexus-ai-guanggao --github-token ghp_xxx --no-wait

# Delete environment (Stack only, data resources preserved)
./deploy.sh nexus-ai-guanggao --delete

# Delete environment and wipe data resources
./deploy.sh nexus-ai-guanggao --delete --clean-data
```

### CloudFormation Template Parameters

`deploy.sh` ultimately invokes `aws cloudformation create-stack --template-body file://nexus-ai-env.yaml` with parameters. The full `Parameters` section of `nexus-ai-env.yaml`:

| Key | Type | Default | Required | NoEcho | Description / effect |
|-----|------|---------|----------|--------|-----------------------|
| `EnvironmentPrefix` | String | — | Yes | No | Prefix for all resource names. Pattern `[a-z0-9\-]+` |
| `VpcCidr` | String | `10.0.0.0/16` | No | No | VPC CIDR; subnets are carved via `!Cidr [VpcCidr, 4, 8]` |
| `InstanceType` | String | `c8i.2xlarge` | No | No | Main EC2 instance type |
| `KeyName` | String | `Og_Normal` | No | No | SSH Key Pair name; must already exist in the account |
| `IamInstanceProfile` | String | `admin-for-ec2` | No | No | EC2 Instance Profile name; must already exist |
| `GitRepoUrl` | String | `https://github.com/hy714335634/Nexus-AI.git` | No | No | Code repository URL |
| `GitBranch` | String | `main` | No | No | Git branch |
| `VolumeSize` | Number | `150` | No | No | EC2 root volume size (GB) |
| `AuthUser` | String | `admin` | No | No | Web login username |
| `AuthPassword` | String | `nexus` | No | Yes | Web login password; written into `config/default_config.yaml` |
| `GitHubToken` | String | empty | Required for private repo | Yes | GitHub PAT; empty means unauthenticated HTTPS clone |
| `DBUsername` | String | `nexus_admin` | No | No | Aurora PostgreSQL admin username |
| `DBPassword` | String | `Nexus2026!` | No | Yes | Aurora PostgreSQL admin password |
| `AuroraMinCapacity` | Number | `0.5` | No | No | Aurora Serverless v2 minimum ACU |
| `AuroraMaxCapacity` | Number | `16` | No | No | Aurora Serverless v2 maximum ACU |
| `ValkeyMaxDataGB` | Number | `5` | No | No | Valkey Serverless maximum data storage (GB) |
| `ValkeyMaxECPU` | Number | `15000` | No | No | Valkey Serverless maximum ECPU per second |
| `AmiId` | SSM Param | `/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64` | No | No | Amazon Linux 2023 latest AMI, resolved via SSM parameter |
| `EnableSandbox` | String | `false` | No | No | Allowed: `true` / `false`. When `true`, EFS code + data filesystems are created |
| `SandboxEFSId` | String | empty | No | No | Sandbox EFS FileSystem ID (e.g. from a separately deployed `sandbox-infra.yaml`) |
| `SandboxECRName` | String | empty | No | No | Sandbox ECR repo name; empty defaults to `${EnvironmentPrefix}-sandbox-runtime` |

### Resource Naming Rules

All resource names derived from `EnvironmentPrefix`:

| Resource type | Naming format | Example (`nexus-ai-guanggao`) |
|---------------|---------------|---------------------------------|
| VPC | `{prefix}-vpc` | `nexus-ai-guanggao-vpc` |
| Public subnet | `{prefix}-public-{1,2}` | `nexus-ai-guanggao-public-1` |
| Private subnet | `{prefix}-private-{1,2}` | `nexus-ai-guanggao-private-1` |
| Internet Gateway | `{prefix}-igw` | `nexus-ai-guanggao-igw` |
| NAT EIP | `{prefix}-nat-eip` | `nexus-ai-guanggao-nat-eip` |
| NAT Gateway | `{prefix}-nat` | `nexus-ai-guanggao-nat` |
| Public route table | `{prefix}-public-rt` | `nexus-ai-guanggao-public-rt` |
| Private route table | `{prefix}-private-rt` | `nexus-ai-guanggao-private-rt` |
| ALB | `{prefix}-alb` | `nexus-ai-guanggao-alb` |
| ALB security group | `{prefix}-alb-sg` | `nexus-ai-guanggao-alb-sg` |
| EC2 security group | `{prefix}-ec2-sg` | `nexus-ai-guanggao-ec2-sg` |
| Aurora security group | `{prefix}-aurora-sg` | `nexus-ai-guanggao-aurora-sg` |
| Valkey security group | `{prefix}-valkey-sg` | `nexus-ai-guanggao-valkey-sg` |
| EFS security group | `{prefix}-efs-sg` | `nexus-ai-guanggao-efs-sg` |
| Aurora Subnet Group | `{prefix}-aurora-subnets` | `nexus-ai-guanggao-aurora-subnets` |
| Aurora Cluster | `{prefix}-aurora` | `nexus-ai-guanggao-aurora` |
| Aurora Writer | `{prefix}-aurora-writer` | `nexus-ai-guanggao-aurora-writer` |
| Valkey Serverless | `{prefix}-valkey` | `nexus-ai-guanggao-valkey` |
| EFS code volume | `{prefix}-efs-code` | `nexus-ai-guanggao-efs-code` |
| EFS data volume | `{prefix}-efs-data` | `nexus-ai-guanggao-efs-data` |
| API target group | `{prefix}-api-tg` | `nexus-ai-guanggao-api-tg` |
| Docs target group | `{prefix}-docs-tg` | `nexus-ai-guanggao-docs-tg` |
| CloudFront | `{prefix}-cf` | `nexus-ai-guanggao-cf` |
| Stack | `{prefix}-stack` | `nexus-ai-guanggao-stack` |
| DDB table prefix | Hyphens → underscores + `_` | `nexus_ai_guanggao_` |
| SQS queue prefix | `{prefix}-` | `nexus-ai-guanggao-` |
| S3 bucket suffix | Original bucket name + `-&lt;env&gt;` (`env` = prefix with `nexus-ai-` stripped) | `nexus-ai-artifacts-2026-guanggao` |

### Subnet Layout

`!Cidr [VpcCidr, 4, 8]` carves the VPC CIDR into four /24 subnets (when `VpcCidr=10.0.0.0/16`):

| Subnet | Index | Sample CIDR | AZ position | Egress |
|--------|-------|-------------|-------------|--------|
| Public subnet 1 | 0 | 10.0.0.0/24 | 1st AZ | IGW |
| Public subnet 2 | 1 | 10.0.1.0/24 | 2nd AZ | IGW |
| Private subnet 1 | 2 | 10.0.2.0/24 | 1st AZ | NAT |
| Private subnet 2 | 3 | 10.0.3.0/24 | 2nd AZ | NAT |

### Security Group Inbound Rules

**ALB security group (`{prefix}-alb-sg`)**:

| Protocol | Port | Source | Description |
|----------|------|--------|-------------|
| TCP | 80 | `pl-82a045eb` (CloudFront prefix list) | Only CloudFront origin-facing IPs |

**EC2 security group (`{prefix}-ec2-sg`)**:

| Protocol | Port | Source | Description |
|----------|------|--------|-------------|
| TCP | 3000 | ALB SG | Frontend (Next.js) |
| TCP | 8000 | ALB SG | API (FastAPI) |
| TCP | 8001 | ALB SG | Bridge service |
| TCP | 5173 | ALB SG | Docs (Playbook) |
| TCP | 22 | 0.0.0.0/0 | SSH |
| TCP | 8001 | 10.0.0.0/8 | Bridge calls from VPC (sandbox tasks) |
| TCP | 8000 | 10.0.0.0/8 | Reserved intra-VPC API calls |
| TCP | 8080 | 10.0.0.0/8 | sandbox-host management API |
| TCP | 18000-18100 | 10.0.0.0/8 | Firecracker microVM proxy ports |
| TCP | 4318 | 10.0.0.0/8 | OTLP HTTP receiver (ADOT Collector) |
| TCP | 4317 | 10.0.0.0/8 | OTLP gRPC receiver |

**Aurora security group (`{prefix}-aurora-sg`)**:

| Protocol | Port | Source | Description |
|----------|------|--------|-------------|
| TCP | 5432 | EC2 SG | PostgreSQL; only EC2 may connect |

**Valkey security group (`{prefix}-valkey-sg`)**:

| Protocol | Port | Source | Description |
|----------|------|--------|-------------|
| TCP | 6379 | EC2 SG | Valkey; only EC2 may connect |

**EFS security group (`{prefix}-efs-sg`, only created when `EnableSandbox=true`)**:

| Protocol | Port | Source | Description |
|----------|------|--------|-------------|
| TCP | 2049 | EC2 SG | NFS |

### ALB Routing Rules

| Path | Target group port | Upstream service |
|------|--------------------|--------------------|
| `/api/*` | 8000 | FastAPI |
| `/playbook*` | 5173 | Playbook docs site |
| `/bridge/*` | 8001 | Bridge service |
| default | 3000 | Frontend (Next.js) |

### Health Check

API target group uses:

| Field | Value |
|-------|-------|
| Protocol | HTTP |
| Path | `/docs` |
| Interval | 30 s |
| Timeout | 5 s |
| Healthy Threshold | 5 |
| Unhealthy Threshold | 2 |
| Matcher | `200` |

### Aurora / Valkey Specifications

| Field | Aurora PostgreSQL | Valkey Serverless |
|-------|-------------------|---------------------|
| Engine version | `16.4` | Major `8` |
| Database name / port | `nexus` / 5432 | — / 6379 |
| Capacity unit | ACU (0.5–16) | DataStorage GB + ECPU/s |
| Backup retention | 7 days | — |
| Encryption | `StorageEncrypted: true` | — |
| DeletionProtection | `false` | — |
| Subnets | Private subnets 1 + 2 | Private subnets 1 + 2 |

### EC2 Initialization Flow

The main EC2 UserData executes in order:

1. Install `git` (not included in AL2023 by default).
2. Clone the repo to `/home/ec2-user/&lt;prefix&gt;/`, supports GitHub Token authentication.
3. Run `setup_env_alinux2023.sh` to install Python 3.13, Node.js, uv, Docker, etc.
4. `cd web && npm run build` to build the frontend.
5. Rewrite `config/default_config.yaml`: substitute DDB/SQS/S3 prefixes, inject `AuthUser`/`AuthPassword`, disable SSO.
6. `nexus-cli init` creates DynamoDB tables, SQS queues, and S3 buckets.
7. `nexus-cli service start` + `nexus-cli service start --event` launches all services.

Typical timing: EC2 initialization 20–30 min; CloudFront distribution adds another 5–10 min.

### Deletion Behavior

| Operation | Deletes | Preserves |
|-----------|---------|-----------|
| `--delete` | VPC, EC2, ALB, CloudFront, Aurora, Valkey, (optional) EFS | DDB tables, SQS queues, S3 buckets |
| `--delete --clean-data` | Everything above + DDB tables (matched by prefix) + SQS queues (matched by prefix) + S3 buckets (matched by suffix) | — |

`--clean-data` runs before the Stack deletion and matches resources as follows:

| Resource | Match rule |
|----------|-------------|
| S3 | `ends_with(Name, '-&lt;env-prefix stripped of nexus-ai-&gt;')` |
| DDB | `starts_with(<env-prefix with hyphens→underscores>_)` |
| SQS | `queue-name-prefix=&lt;env-prefix&gt;-` |

---

## Sandbox Runtime Parameters (Firecracker microVM)

Sandbox configuration lives under the `sandbox` section of `config/default_config.yaml` (`enabled: false` by default). Enabling the sandbox requires deploying the main stack with `EnableSandbox=true` and deploying the sandbox stack (ASG + UserData) separately.

### sandbox top-level

| Key | Type | Default | Required | Description |
|-----|------|---------|----------|-------------|
| `sandbox.enabled` | bool | `false` | No | Whether sandbox is enabled |

### sandbox.policy

| Key | Type | Default | Required | Description |
|-----|------|---------|----------|-------------|
| `sandbox.policy.default_runtime` | string | `local` | No | Default runtime; one of `local` / `firecracker` |
| `sandbox.policy.allow_user_override` | bool | `true` | No | Whether callers may override the runtime per request |
| `sandbox.policy.allowed_runtimes` | list | `['local', 'firecracker']` | No | List of permitted runtimes |
| `sandbox.policy.max_concurrent_vms` | int | `50` | No | Global maximum concurrent VMs |

### sandbox.config

| Key | Type | Default | Required | Description |
|-----|------|---------|----------|-------------|
| `sandbox.config.efs_code_id` | string | empty | Yes (if enabled) | EFS code volume FileSystem ID |
| `sandbox.config.efs_code_mount` | string | `/nexus-efs` | No | Node-side mount path of EFS code volume |
| `sandbox.config.repo_root` | string | `/nexus-efs/nexus-ai` | No | Repo path inside the EFS code volume |
| `sandbox.config.efs_data_id` | string | empty | Yes (if enabled) | EFS data volume FileSystem ID |
| `sandbox.config.efs_data_mount` | string | `/nexus-efs-data` | No | Node-side mount path of EFS data volume |
| `sandbox.config.workspace_prefix` | string | `workspaces` | No | Session workspace subdirectory in the EFS data volume |
| `sandbox.config.envs_prefix` | string | `envs` | No | Agent venv subdirectory in the EFS data volume |
| `sandbox.config.rootfs_path` | string | `/nexus-efs-data/rootfs/base.ext4` | No | rootfs template path |
| `sandbox.config.session_s3_bucket` | string | empty | No | Empty inherits from main config |
| `sandbox.config.valkey_endpoint` | string | empty | No | Empty inherits from main config |
| `sandbox.config.valkey_port` | int | `6379` | No | — |
| `sandbox.config.valkey_ssl` | bool | `true` | No | — |
| `sandbox.config.dynamodb_table_prefix` | string | empty | No | Empty inherits from main config |
| `sandbox.config.vm_vcpu` | int | `2` | No | vCPU per VM |
| `sandbox.config.vm_memory_mib` | int | `1024` | No | Memory per VM (MB) |
| `sandbox.config.vm_port` | int | `8080` | No | Port on which runtime_app listens inside the VM |
| `sandbox.config.stream_maxlen` | int | `5000` | No | Maximum length of the Valkey Stream |
| `sandbox.config.invocation_timeout` | int | `600` | No | Agent execution timeout (seconds) |
| `sandbox.config.idle_timeout` | int | `300` | No | VM destroyed after being idle for this long (seconds) |
| `sandbox.config.log_level` | string | `INFO` | No | Log level |

### sandbox.pool

| Key | Type | Default | Required | Description |
|-----|------|---------|----------|-------------|
| `sandbox.pool.instance_type` | string | `c6i.2xlarge` | No | Node EC2 instance type (8 vCPU / 16 GB) |
| `sandbox.pool.min_size` | int | `1` | No | ASG minimum size |
| `sandbox.pool.max_size` | int | `5` | No | ASG maximum size |
| `sandbox.pool.vms_per_node` | int | `4` | No | Max VMs per node; bounded by `instance_vcpu / vm_vcpu` |
| `sandbox.pool.key_name` | string | empty | No | Node SSH Key Pair |
| `sandbox.pool.cluster_name` | string | empty | Filled after deploy | ECS Cluster name (used only for ASG Capacity Provider) |
| `sandbox.pool.subnets` | list | `[]` | Yes (if enabled) | Node subnet IDs |
| `sandbox.pool.security_groups` | list | `[]` | Yes (if enabled) | Node security group IDs |
| `sandbox.pool.prewarm_featured_agents` | bool | `true` | No | Pre-create featured-agent VMs on startup |
| `sandbox.pool.prewarm_idle_vms` | int | `0` | No | Extra pre-warmed empty VMs (0 means on-demand) |

### Sandbox Node UserData Hardcoded Parameters

Values hardcoded into the sandbox node UserData (`infrastructure/sandbox/setup-node.sh`):

| Field | Value | Notes |
|-------|-------|-------|
| Firecracker version | `1.10.1` | Downloaded from GitHub Releases |
| Kernel version | `5.10.230` | First node builds from source; subsequent nodes load from EFS cache (NFS support baked in) |
| Kernel config | Firecracker's official `microvm-kernel-ci-x86_64-5.10.config` | — |
| rootfs size | 2048 MB | `dd` + `mkfs.ext4` |
| rootfs build base image | `amazonlinux:2023` | Exported via Docker |
| Python inside rootfs | `python3.11` | `ln -sf python3.11 /usr/bin/python3` |
| rootfs cache path | `/nexus-efs-data/rootfs/base.ext4` | Written back to EFS after first build |
| rootfs cache invalidation | MD5 of `requirements.txt` | Stored at `/nexus-efs-data/rootfs/requirements.md5` |
| Local storage mount | `/local` | Prefers `/dev/nvme1n1` or `/dev/nvme2n1`, otherwise EBS |
| Network bridge | `br0` | `172.16.0.1/24` |
| DNS forwarder | `dnsmasq` | Listens on `172.16.0.1`, upstream `169.254.169.253` |
| VM proxy port range | 18001–18100 | One port per VM |

### sandbox-host HTTP API

On each node, `sandbox-host.service` exposes port `8080`:

| Method | Path | Description |
|--------|------|-------------|
| POST | `/vms/create` | Create a microVM |
| POST | `/vms/{vm_id}/destroy` | Destroy the specified microVM |
| GET | `/vms` | List all VMs and capacity on this node |
| GET | `/health` | Node health status |

**POST `/vms/create` request body**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `session_id` | string | Yes | Session ID |
| `agent_id` | string | Yes | Agent ID |
| `prompt_path` | string | Yes | Prompt template path |
| `vcpu` | int | No | Overrides `vm_vcpu` |
| `memory_mib` | int | No | Overrides `vm_memory_mib` |

**POST `/vms/create` response body**:

| Field | Type | Description |
|-------|------|-------------|
| `vm_id` | string | `fc-&lt;hex&gt;` |
| `ip` | string | VM internal IP (reachable only inside the node) |
| `proxy_port` | int | Reverse-proxy port on the node (reachable from the VPC) |
| `status` | string | `running` |

### Firecracker VM Specifications (Defaults)

| Field | Value |
|-------|-------|
| vCPU | 2 |
| Memory | 1024 MB |
| Internal port | 8080 |
| rootfs | `base.ext4` (copy-on-write overlay) |
| Network | TAP + bridge `br0`, `172.16.0.0/24` |
| Boot time | ~1.5 s (kernel boot + NFS mount + Python startup) |
| End-to-end first response | ~5–7 s |

### microVM /init Parameters (parsed from kernel cmdline)

| Variable | Description |
|----------|-------------|
| `VM_IP` | VM `eth0` IP |
| `GW_IP` | Default gateway (= bridge `br0` IP, typically `172.16.0.1`) |
| `EFS_CODE_IP` | EFS code volume mount target IP |
| `EFS_DATA_IP` | EFS data volume mount target IP |
| `EFS_CODE_SUBDIR` | Subdirectory of EFS code volume to mount |
| `SESSION_ID` | Session ID |
| `AGENT_ID` | Agent ID |
| `PROMPT_PATH` | Prompt template path |
| `AWS_REGION` | AWS region |
| `TEMPLATE_MOUNTS` | Read-only template mounts, format `aid1:v1:mount1|aid2:v2:mount2` |

### DynamoDB Tables (sandbox)

| Table (with prefix) | PK | Purpose |
|----------------------|-----|---------|
| `{prefix}sandbox_nodes` | `node_id` (EC2 instance ID) | Node registry; tracks node status and capacity |
| `{prefix}sandbox_instances` | `instance_id` (VM ID) | VM instance registry |
| `{prefix}sandbox_logs` | `log_id` | Scheduling logs (30-day TTL) |

### Resource Management Strategy

`ResourceManager.select_node()` picks a node in this priority order:

1. **Affinity**: nodes that already have the agent's venv cached.
2. **Load balancing**: among candidates that fit, pick the one with the most remaining vCPU.
3. **Scale-up**: if every node is full, trigger ASG scale-up, wait up to 120 s, then recurse.

---

## Local Development Mode

No CloudFormation. Driven primarily by `nexus-cli`, with configuration read from `config/default_config.yaml`. See `reference/cli-commands` (commands) and `reference/config-options` (configuration). In local mode:

| Resource | Default location |
|----------|--------------------|
| DDB / S3 / SQS | Real AWS account (reads `~/.aws/credentials`) |
| Main API | `http://localhost:8000` |
| Frontend | `http://localhost:3000` |
| Bridge | `http://localhost:8001` |
| Docs | `http://localhost:5173` |
| Agent runtime | `runtime_type=local` (host process) |

---

## Common Pitfalls

| Pitfall | Symptom | Mitigation |
|---------|---------|------------|
| `EnvironmentPrefix` contains uppercase or underscores | Stack creation fails | Use only lowercase, digits, and hyphens |
| Private repo without `--github-token` | EC2 UserData clone fails with HTTP 401 in init log | Provide a fine-grained token with only `Contents: Read-only` |
| `KeyName` (default `Og_Normal`) does not exist | Stack creation fails | Create the Key Pair beforehand or override via the template parameter |
| `IamInstanceProfile` (default `admin-for-ec2`) does not exist | EC2 fails to launch | Pre-create an Instance Profile with Bedrock / S3 / DDB / SQS / CloudWatch permissions |
| Instance type without KVM support | Sandbox node UserData errors with `/dev/kvm not available` | Choose a KVM-capable EC2 family (e.g. `c6i.*`, `c8i.*` bare-metal, or ordinary x86) |
| `VolumeSize` too small | Python 3.13 compilation + dependency install fills the disk | Keep the default 150 GB |
| `--clean-data` deletes data by mistake | S3 / DDB / SQS lost permanently | Use only when a full wipe is truly intended; without `--clean-data`, those three resource classes are preserved |
| Aurora `DeletionProtection: false` | `--delete` tears down Aurora too, losing data | Enable deletion protection manually for prod, or amend the template |
| Sandbox `rootfs` cache invalidation only checks MD5 of `requirements.txt` | Edits to non-`requirements.txt` dependencies do not rebuild rootfs | Manually delete `/nexus-efs-data/rootfs/base.ext4` to force a rebuild |

## Verification Steps

### After Deployment

```bash
# View Stack outputs (ALB DNS, CloudFront domain, etc.)
aws cloudformation describe-stacks \
  --stack-name <env-prefix>-stack \
  --region us-west-2 \
  --query 'Stacks[0].Outputs'

# SSH into the main EC2
ssh -i <KeyName>.pem ec2-user@<EC2 public IP>

# View UserData init log
sudo cat /var/log/nexus-init.log

# Service status
cd /home/ec2-user/<env-prefix>
source .venv/bin/activate
python nexus-cli service status

# Service logs
python nexus-cli service logs
```

### Sandbox Node Verification

```bash
# Node health
curl http://<node-private-ip>:8080/health

# List VMs on the node
curl http://<node-private-ip>:8080/vms

# sandbox-host logs
sudo journalctl -u sandbox-host -f
```

## Exit Codes

`deploy.sh` runs under `set -e`, so any failing command aborts the script with that command's exit code. Explicit exit points:

| Exit code | Triggered by |
|-----------|---------------|
| `0` | Creation / deletion succeeded; or `--delete` cancelled by the user |
| `1` | Missing env prefix; unknown flag; missing template file; Stack already exists; other AWS CLI errors |
