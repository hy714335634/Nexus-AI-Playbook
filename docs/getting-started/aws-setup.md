---
title: AWS 环境准备
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - README.md
    - config/default_config.yaml
    - infrastructure/**
  generated_at: 2026-05-08T14:30:10+00:00
  generated_by: docs-sync v2
---

# AWS 环境准备

## 这是什么

Nexus-AI 运行在 AWS 上，依赖 Bedrock、Aurora、Valkey、DynamoDB、SQS、S3 等服务。在部署之前，你需要准备一个可用的 AWS 账号，并开通必要的服务权限。这一步做对了，后续 `nexus-cli deploy` 或 CloudFormation 一键部署才能顺利跑通。

## 使用场景

| 场景 | 你会做什么 |
|------|-----------|
| 第一次试用 Nexus-AI | 在个人/团队 AWS 账号中开通 Bedrock 模型访问，配置 CLI，然后用 `nexus-cli deploy` 拉起测试环境 |
| 企业内部推广 | 申请独立的沙箱账号，绑定付费和配额，按下方的最小权限策略创建专用 IAM 角色 |
| 已有生产账号扩展功能 | 在现有账号中追加 Bedrock 访问、为 EC2 创建 Instance Profile、设置 SSH Key Pair |
| 多环境隔离（dev / staging / prod） | 每个环境使用不同的 `EnvironmentPrefix`，Nexus-AI 会自动隔离 VPC、DDB、SQS、S3 等资源 |

## 如何使用

下面 6 步按顺序完成，全部结束后就可以进入 [快速部署](./quickstart) 环节。

### 1. 准备 AWS 账号与区域

::: tip 推荐区域
Nexus-AI 默认使用 **`us-west-2`（俄勒冈）**，该区域对 Claude 4.5 系列模型支持最完整。如使用其它区域，需要先确认 Bedrock 模型可用性。
:::

- 登录 AWS Console，确认你有一个可用账号。
- 右上角切换到 `us-west-2`。
- 检查账户配额：默认部署会创建 1 个 VPC、2 个 NAT Gateway、1 个 Aurora 集群、1 台 EC2 实例（`c8i.2xlarge`），确保相关配额满足。

<!-- SCREENSHOT: aws-region-selector -->

### 2. 开通 Bedrock 模型访问

Nexus-AI 默认调用下列三个 Claude 模型，**必须在 Bedrock 控制台申请访问权限**，否则启动后会直接报 AccessDenied。

| 用途 | 模型 ID |
|------|---------|
| 默认模型 | `us.anthropic.claude-sonnet-4-5-20250929-v1:0` |
| 轻量模型 | `us.anthropic.claude-haiku-4-5-20251001-v1:0` |
| 专业模型 | `us.anthropic.claude-opus-4-5-20251101-v1:0` |

操作路径：`AWS Console → Bedrock → Model access → Manage model access`，勾选 Anthropic 的三款 Claude 4.5 模型并提交。大部分账号会在几分钟内自动批准，企业账号可能需要填写用途说明。

<!-- SCREENSHOT: bedrock-model-access -->

### 3. 创建部署者 IAM 用户或角色

执行部署脚本的那台机器（你的本地或 CI）需要一个 IAM 身份，具备下表权限：

| 服务 | 权限 | 用途 |
|------|------|------|
| CloudFormation | `CreateStack`、`DeleteStack`、`DescribeStacks`、`DescribeStackEvents` | 管理部署 Stack |
| EC2 | `RunInstances`、`TerminateInstances`、`CreateVpc`、`CreateSubnet`、`CreateSecurityGroup`、`CreateNatGateway`、`AllocateAddress`、`CreateRouteTable`、`CreateRoute`、`CreateTags`、`Describe*` | 创建 VPC 与实例 |
| IAM | `CreateRole`、`DeleteRole`、`AttachRolePolicy`、`DetachRolePolicy`、`CreateInstanceProfile`、`AddRoleToInstanceProfile`、`PassRole` | 创建实例角色 |
| RDS | `CreateDBCluster`、`CreateDBInstance`、`CreateDBSubnetGroup`、`DeleteDB*`、`Describe*` | 创建 Aurora 集群 |
| ElastiCache | `CreateServerlessCache`、`DeleteServerlessCache`、`Describe*` | 创建 Valkey 缓存 |
| ELB | `CreateLoadBalancer`、`CreateTargetGroup`、`CreateListener`、`CreateRule`、`RegisterTargets`、`Delete*`、`Describe*` | 创建 ALB |
| CloudFront | `CreateDistribution`、`DeleteDistribution`、`Get*`、`Update*` | 创建 CDN |
| Lambda | `CreateFunction`、`DeleteFunction`、`GetFunction` | 自定义资源 |
| SSM | `GetParameter` | 获取 AMI ID |
| S3 / SQS / DynamoDB | `List*`、`Delete*` | 仅 `--clean-data` 时需要 |

推荐做法：在 IAM 中新建一个名为 `nexus-ai-deployer` 的用户或角色，附加一个策略汇总上面所有权限。测试账号也可以直接授予 `AdministratorAccess` 简化流程。

### 4. 创建 EC2 运行时 Instance Profile

部署模板默认会使用名为 `admin-for-ec2` 的 Instance Profile（可通过 `--iam-instance-profile` 覆盖）。Nexus-AI 的 EC2 需要以下最小权限：

| 服务 | 权限 | 用途 |
|------|------|------|
| Bedrock | `InvokeModel`、`InvokeModelWithResponseStream`、`ListFoundationModels` | 模型推理 |
| DynamoDB | `CreateTable`、`PutItem`、`GetItem`、`UpdateItem`、`DeleteItem`、`Query`、`Scan` | 平台数据 |
| SQS | `CreateQueue`、`SendMessage`、`ReceiveMessage`、`DeleteMessage`、`ChangeMessageVisibility` | 异步任务 |
| S3 | `CreateBucket`、`GetObject`、`PutObject`、`DeleteObject`、`ListBucket`、`PutBucketCors` | 制品与文件 |
| S3 Vectors | `CreateVectorBucket`、`CreateIndex`、`PutObject`、`Query` | 向量检索 |
| RDS | `DescribeDBClusters` | Aurora 连接信息（通过 TCP 直连，不使用 IAM Auth） |
| CloudWatch Logs | `CreateLogGroup`、`CreateLogStream`、`PutLogEvents` | 日志 |
| ECR | `GetAuthorizationToken`、`BatchGetImage`、`PutImage` | AgentCore 部署时使用 |

操作步骤：

1. 进入 `IAM → Roles → Create role`。
2. 选择受信任实体类型 **AWS service → EC2**。
3. 附加一个包含上述权限的策略（或直接用 `AdministratorAccess` 临时测试）。
4. 角色名填 `admin-for-ec2`，创建后会自动生成同名 Instance Profile。

<!-- SCREENSHOT: ec2-instance-profile -->

### 5. 准备 SSH Key Pair

部署模板默认引用 Key Pair 名称 `Og_Normal`，便于 SSH 登录排障。

- 进入 `EC2 → Key Pairs → Create key pair`。
- 名称填 `Og_Normal`（或自定义后用 `--key-name` 传入）。
- 文件格式选 `.pem`，下载后妥善保管。

```bash
chmod 400 Og_Normal.pem
```

### 6. 在本地配置 AWS CLI

在准备运行 `nexus-cli deploy` 的机器上：

```bash
# 安装 AWS CLI v2（若未安装）
# macOS: brew install awscli
# Linux: 参考官方文档

aws configure
# AWS Access Key ID       → 第 3 步创建的 deployer 用户的 Access Key
# AWS Secret Access Key   → 对应 Secret
# Default region          → us-west-2
# Default output format   → json
```

验证：

```bash
aws sts get-caller-identity
aws bedrock list-foundation-models --region us-west-2 | head -20
```

第二条命令能列出模型即说明 Bedrock 权限可用。

## 关键参数 / 限制

| 项目 | 默认值 / 建议 | 说明 |
|------|--------------|------|
| 区域 | `us-west-2` | Claude 4.5 系列模型支持最完整 |
| VPC CIDR | `10.0.0.0/16` | 自建独立 VPC，可通过 `--vpc-cidr` 修改 |
| EC2 实例类型 | `c8i.2xlarge` | 运行 API + Worker + Web + Docs 的主节点 |
| 磁盘 | `150 GB` | 主节点根卷，需容纳依赖与构建缓存 |
| Sandbox 节点 | `c8id.xlarge` | 启用 Sandbox 时使用，需支持 KVM |
| Key Pair | `Og_Normal` | 可用 `--key-name` 覆盖 |
| IAM Instance Profile | `admin-for-ec2` | 可用 `--iam-instance-profile` 覆盖 |
| Aurora 密码 | 无默认 | 部署时必须通过 `--db-password` 提供强密码 |
| 登录凭证 | `admin` / `nexus` | 开发模式默认账号，生产建议改 |
| 部署耗时 | 20–30 分钟 | CloudFront 再额外 5–10 分钟 |
| NAT Gateway 费用 | ≈ $0.045/小时 | 空闲环境建议及时 `deploy down` |

## 常见问题

### Q1：必须用 us-west-2 吗？其它区域行不行？

**建议用 `us-west-2`**。Nexus-AI 的默认模型 Claude Sonnet 4.5 / Opus 4.5 / Haiku 4.5 在该区域支持最完整。如需换区域，请先在目标区域 Bedrock 控制台确认这三个模型可申请，再通过 `--region` 指定。

### Q2：Bedrock 申请没通过怎么办？

个人账号通常即时通过；如提示需要审批，请在申请表里写清真实用途（如"评估公司内部 AI Agent 平台"）。企业账号可能受组织 SCP 限制，需要联系主账号管理员放开 Bedrock 权限。

### Q3：没有 IAM 权限，如何让管理员提前配好？

把上面第 3 步（部署者权限）和第 4 步（EC2 运行时权限）两张表发给管理员即可，这两张表就是最小权限清单。管理员创建完后把 Access Key 和 Instance Profile 名称给你。

### Q4：我已经有一个包含其它服务的 AWS 账号，会不会相互干扰？

不会。每个 Nexus-AI 环境用独立的 `EnvironmentPrefix` 做隔离，`deploy.sh` 会自建一个全新 VPC，DDB 表名加前缀、SQS 队列名加前缀、S3 桶名加后缀，跟你原有资源互不影响。

### Q5：销毁环境后，S3、DDB、SQS 的数据会一起删除吗？

默认**不会**。`nexus-cli deploy down` 只删除 CloudFormation 管理的 VPC / EC2 / ALB / CloudFront 等资源。若要同时清空数据，追加 `--clean-data`：

```bash
nexus-cli deploy down my-env --clean-data -y
```

### Q6：为什么我执行 `aws bedrock list-foundation-models` 报 AccessDenied？

通常是两种原因：

1. 你当前使用的 IAM 身份没有 Bedrock 权限 — 参考第 3 步权限清单。
2. 你的账号从未在 Bedrock 控制台进入过任何区域 — 先在控制台手动点一次 `Bedrock → Model access`，触发区域激活。
