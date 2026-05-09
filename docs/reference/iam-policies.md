---
title: IAM 权限
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - docs/infrastructure/IAM_POLICIES.md
    - infrastructure/**
  generated_at: 2026-05-09T01:32:56+00:00
  generated_by: docs-sync v2
---

# IAM 权限

Nexus-AI 部署涉及两个独立的 IAM 身份，各自配备一份最小权限策略：

| 角色 | 用途 | 附加方式 |
|------|------|----------|
| **Deployer** | 执行 `infrastructure/cloudformation/deploy.sh`，创建 / 更新 / 删除 CloudFormation Stack 的 IAM 用户或角色 | 直接 attach 到 IAM 用户或角色 |
| **EC2 Runtime** | Nexus-AI EC2 实例运行时使用的角色，支撑 Bedrock 调用、DynamoDB / SQS / S3 / ECR 访问、日志上报等 | 通过 Instance Profile 附加到 EC2（CloudFormation 参数 `IamInstanceProfile`，默认 `admin-for-ec2`） |

两份策略均为 IAM Policy JSON（`"Version": "2012-10-17"`），可直接粘贴到 IAM Console 或 `aws iam create-policy`。

::: info 前置约定
- 所有 Resource ARN 中使用的命名前缀为 `nexus-ai-*`、`nexus-ai*`、`nexus*`、表名前缀等，对应部署脚本 `deploy.sh` 中的 `EnvironmentPrefix` 约定。
- 部署区域示例为 `us-west-2`（与 `deploy.sh` 中 `REGION` 默认值一致）。
- 如需进一步收紧资源范围，见下文「收紧资源 ARN」章节。
:::

## Deployer 策略

**用途**：执行 `./deploy.sh <环境前缀>`，创建 / 更新 / 删除一个 Nexus-AI 测试环境所需的全部 AWS 资源（VPC、EC2、ALB、CloudFront、Aurora、ElastiCache、Lambda 等）。

### Deployer 权限概览

| Sid | 服务 | Resource 范围 | 说明 |
|-----|------|---------------|------|
| CloudFormation | CloudFormation | `arn:aws:cloudformation:*:*:stack/nexus-ai-*/*` | 创建、更新、删除、描述 `nexus-ai-*` 前缀的 Stack |
| EC2VPCAndInstances | EC2 | `*` | 创建 VPC / 子网 / IGW / NAT / 路由表 / 安全组 / VPC Endpoint / EC2 实例 / EBS 卷 |
| IAMRolesAndProfiles | IAM | `arn:aws:iam::*:role/nexus-ai-*`、`arn:aws:iam::*:instance-profile/nexus-ai-*` | 创建 `nexus-ai-*` 前缀的 IAM 角色和 Instance Profile，`PassRole` 给 EC2 使用 |
| RDSAurora | RDS | `*` | 创建 / 删除 / 修改 Aurora 集群、实例、子网组 |
| ElastiCacheValkey | ElastiCache | `*` | 创建 / 删除 Valkey Serverless 缓存 |
| ELB | Elastic Load Balancing | `*` | 创建 ALB、目标组、监听器、转发规则，注册 / 注销 EC2 目标 |
| CloudFront | CloudFront | `*` | 创建 / 更新 / 删除 CloudFront 分发，打标签 |
| LambdaCustomResource | Lambda | `arn:aws:lambda:*:*:function:nexus-ai-*` | CloudFormation Custom Resource 用的 Lambda 函数管理 |
| SSMGetAMI | SSM | `arn:aws:ssm:*::parameter/aws/service/ami-amazon-linux-latest/*` | 通过 SSM 参数获取最新 Amazon Linux 2023 AMI ID |
| CleanDataOptional | S3、DynamoDB、SQS | `*`（带 Tag 条件） | **可选**：仅在使用 `deploy.sh --delete --clean-data` 清理数据资源时需要，带 `aws:ResourceTag/Environment=nexus-ai-*` 条件限制 |

### Deployer 完整策略 JSON

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "CloudFormation",
      "Effect": "Allow",
      "Action": [
        "cloudformation:CreateStack",
        "cloudformation:DeleteStack",
        "cloudformation:UpdateStack",
        "cloudformation:DescribeStacks",
        "cloudformation:DescribeStackEvents",
        "cloudformation:DescribeStackResources",
        "cloudformation:ValidateTemplate",
        "cloudformation:GetTemplateSummary",
        "cloudformation:ListStacks"
      ],
      "Resource": "arn:aws:cloudformation:*:*:stack/nexus-ai-*/*"
    },
    {
      "Sid": "EC2VPCAndInstances",
      "Effect": "Allow",
      "Action": [
        "ec2:CreateVpc",
        "ec2:DeleteVpc",
        "ec2:CreateSubnet",
        "ec2:DeleteSubnet",
        "ec2:CreateInternetGateway",
        "ec2:DeleteInternetGateway",
        "ec2:AttachInternetGateway",
        "ec2:DetachInternetGateway",
        "ec2:CreateNatGateway",
        "ec2:DeleteNatGateway",
        "ec2:AllocateAddress",
        "ec2:ReleaseAddress",
        "ec2:CreateRouteTable",
        "ec2:DeleteRouteTable",
        "ec2:CreateRoute",
        "ec2:DeleteRoute",
        "ec2:AssociateRouteTable",
        "ec2:DisassociateRouteTable",
        "ec2:CreateSecurityGroup",
        "ec2:DeleteSecurityGroup",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:AuthorizeSecurityGroupEgress",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupEgress",
        "ec2:RunInstances",
        "ec2:TerminateInstances",
        "ec2:CreateTags",
        "ec2:DeleteTags",
        "ec2:CreateVolume",
        "ec2:DeleteVolume",
        "ec2:ModifyVolume",
        "ec2:CreateVpcEndpoint",
        "ec2:DeleteVpcEndpoints",
        "ec2:Describe*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "IAMRolesAndProfiles",
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:GetRole",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:PutRolePolicy",
        "iam:DeleteRolePolicy",
        "iam:CreateInstanceProfile",
        "iam:DeleteInstanceProfile",
        "iam:GetInstanceProfile",
        "iam:AddRoleToInstanceProfile",
        "iam:RemoveRoleFromInstanceProfile",
        "iam:PassRole",
        "iam:ListAttachedRolePolicies",
        "iam:ListRolePolicies"
      ],
      "Resource": [
        "arn:aws:iam::*:role/nexus-ai-*",
        "arn:aws:iam::*:instance-profile/nexus-ai-*"
      ]
    },
    {
      "Sid": "RDSAurora",
      "Effect": "Allow",
      "Action": [
        "rds:CreateDBCluster",
        "rds:DeleteDBCluster",
        "rds:ModifyDBCluster",
        "rds:CreateDBInstance",
        "rds:DeleteDBInstance",
        "rds:CreateDBSubnetGroup",
        "rds:DeleteDBSubnetGroup",
        "rds:Describe*",
        "rds:AddTagsToResource",
        "rds:RemoveTagsFromResource"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ElastiCacheValkey",
      "Effect": "Allow",
      "Action": [
        "elasticache:CreateServerlessCache",
        "elasticache:DeleteServerlessCache",
        "elasticache:Describe*",
        "elasticache:AddTagsToResource",
        "elasticache:RemoveTagsFromResource",
        "elasticache:ListTagsForResource"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ELB",
      "Effect": "Allow",
      "Action": [
        "elasticloadbalancing:CreateLoadBalancer",
        "elasticloadbalancing:DeleteLoadBalancer",
        "elasticloadbalancing:CreateTargetGroup",
        "elasticloadbalancing:DeleteTargetGroup",
        "elasticloadbalancing:CreateListener",
        "elasticloadbalancing:DeleteListener",
        "elasticloadbalancing:CreateRule",
        "elasticloadbalancing:DeleteRule",
        "elasticloadbalancing:ModifyRule",
        "elasticloadbalancing:ModifyLoadBalancerAttributes",
        "elasticloadbalancing:ModifyTargetGroupAttributes",
        "elasticloadbalancing:RegisterTargets",
        "elasticloadbalancing:DeregisterTargets",
        "elasticloadbalancing:AddTags",
        "elasticloadbalancing:RemoveTags",
        "elasticloadbalancing:Describe*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "CloudFront",
      "Effect": "Allow",
      "Action": [
        "cloudfront:CreateDistribution",
        "cloudfront:DeleteDistribution",
        "cloudfront:UpdateDistribution",
        "cloudfront:GetDistribution",
        "cloudfront:GetDistributionConfig",
        "cloudfront:TagResource",
        "cloudfront:UntagResource",
        "cloudfront:ListDistributions",
        "cloudfront:ListTagsForResource"
      ],
      "Resource": "*"
    },
    {
      "Sid": "LambdaCustomResource",
      "Effect": "Allow",
      "Action": [
        "lambda:CreateFunction",
        "lambda:DeleteFunction",
        "lambda:GetFunction",
        "lambda:InvokeFunction",
        "lambda:AddPermission",
        "lambda:RemovePermission",
        "lambda:UpdateFunctionCode"
      ],
      "Resource": "arn:aws:lambda:*:*:function:nexus-ai-*"
    },
    {
      "Sid": "SSMGetAMI",
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter",
        "ssm:GetParameters"
      ],
      "Resource": "arn:aws:ssm:*::parameter/aws/service/ami-amazon-linux-latest/*"
    },
    {
      "Sid": "CleanDataOptional",
      "Effect": "Allow",
      "Action": [
        "s3:ListAllMyBuckets",
        "s3:ListBucket",
        "s3:DeleteObject",
        "s3:DeleteObjectVersion",
        "s3:DeleteBucket",
        "s3:GetBucketVersioning",
        "s3:ListBucketVersions",
        "dynamodb:ListTables",
        "dynamodb:DeleteTable",
        "dynamodb:DescribeTable",
        "sqs:ListQueues",
        "sqs:GetQueueUrl",
        "sqs:DeleteQueue"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "aws:ResourceTag/Environment": "nexus-ai-*"
        }
      }
    }
  ]
}
```

::: tip CleanDataOptional 是可选的
`CleanDataOptional` 仅在需要使用 `deploy.sh --delete --clean-data` 时才必需。如果你不会使用该参数清理 S3 桶、DynamoDB 表、SQS 队列，可移除该语句。
:::

### Deployer 每条语句动作明细

#### CloudFormation

| 动作 | 说明 |
|------|------|
| `cloudformation:CreateStack` | 创建 Stack |
| `cloudformation:DeleteStack` | 删除 Stack |
| `cloudformation:UpdateStack` | 更新 Stack |
| `cloudformation:DescribeStacks` | 查询 Stack 详情 |
| `cloudformation:DescribeStackEvents` | 查询 Stack 事件流 |
| `cloudformation:DescribeStackResources` | 查询 Stack 内的资源 |
| `cloudformation:ValidateTemplate` | `deploy.sh` 创建前验证模板 |
| `cloudformation:GetTemplateSummary` | 获取模板摘要 |
| `cloudformation:ListStacks` | 列出 Stack |

#### EC2VPCAndInstances

| 动作 | 说明 |
|------|------|
| `ec2:CreateVpc` / `ec2:DeleteVpc` | 创建 / 删除 VPC（10.0.0.0/16，CIDR 可通过 `VpcCidr` 参数覆盖） |
| `ec2:CreateSubnet` / `ec2:DeleteSubnet` | 创建 / 删除公有 + 私有子网（4 个） |
| `ec2:CreateInternetGateway` / `ec2:DeleteInternetGateway` | 创建 / 删除 IGW |
| `ec2:AttachInternetGateway` / `ec2:DetachInternetGateway` | 关联 / 解除 IGW 与 VPC |
| `ec2:CreateNatGateway` / `ec2:DeleteNatGateway` | 创建 / 删除 NAT Gateway |
| `ec2:AllocateAddress` / `ec2:ReleaseAddress` | 申请 / 释放 NAT 用的 EIP |
| `ec2:CreateRouteTable` / `ec2:DeleteRouteTable` | 创建 / 删除路由表 |
| `ec2:CreateRoute` / `ec2:DeleteRoute` | 添加 / 删除路由条目 |
| `ec2:AssociateRouteTable` / `ec2:DisassociateRouteTable` | 关联 / 解除子网与路由表 |
| `ec2:CreateSecurityGroup` / `ec2:DeleteSecurityGroup` | 创建 / 删除安全组 |
| `ec2:AuthorizeSecurityGroupIngress` / `ec2:AuthorizeSecurityGroupEgress` | 添加入站 / 出站规则 |
| `ec2:RevokeSecurityGroupIngress` / `ec2:RevokeSecurityGroupEgress` | 撤销入站 / 出站规则 |
| `ec2:RunInstances` / `ec2:TerminateInstances` | 启动 / 终止 EC2 实例 |
| `ec2:CreateTags` / `ec2:DeleteTags` | 资源打标签 |
| `ec2:CreateVolume` / `ec2:DeleteVolume` / `ec2:ModifyVolume` | 创建 / 删除 / 修改 EBS 卷（根卷默认 150 GB） |
| `ec2:CreateVpcEndpoint` / `ec2:DeleteVpcEndpoints` | 创建 / 删除 VPC Endpoint（DynamoDB、S3 Gateway Endpoint） |
| `ec2:Describe*` | 查询所有 EC2 资源状态 |

#### IAMRolesAndProfiles

| 动作 | 说明 |
|------|------|
| `iam:CreateRole` / `iam:DeleteRole` | 创建 / 删除 `nexus-ai-*` 角色 |
| `iam:GetRole` | 查询角色 |
| `iam:AttachRolePolicy` / `iam:DetachRolePolicy` | 附加 / 解绑托管策略 |
| `iam:PutRolePolicy` / `iam:DeleteRolePolicy` | 写入 / 删除内联策略 |
| `iam:CreateInstanceProfile` / `iam:DeleteInstanceProfile` | 创建 / 删除 `nexus-ai-*` Instance Profile |
| `iam:GetInstanceProfile` | 查询 Instance Profile |
| `iam:AddRoleToInstanceProfile` / `iam:RemoveRoleFromInstanceProfile` | 绑定 / 解绑角色到 Instance Profile |
| `iam:PassRole` | 把 EC2 运行时角色传给 EC2 服务 |
| `iam:ListAttachedRolePolicies` / `iam:ListRolePolicies` | 列出角色已附加的策略 |

#### RDSAurora

| 动作 | 说明 |
|------|------|
| `rds:CreateDBCluster` / `rds:DeleteDBCluster` / `rds:ModifyDBCluster` | 创建 / 删除 / 修改 Aurora PostgreSQL 集群 |
| `rds:CreateDBInstance` / `rds:DeleteDBInstance` | 创建 / 删除 Aurora writer 实例（`db.serverless`） |
| `rds:CreateDBSubnetGroup` / `rds:DeleteDBSubnetGroup` | 创建 / 删除 DB 子网组 |
| `rds:Describe*` | 查询 Aurora 资源状态 |
| `rds:AddTagsToResource` / `rds:RemoveTagsFromResource` | 打标签 |

#### ElastiCacheValkey

| 动作 | 说明 |
|------|------|
| `elasticache:CreateServerlessCache` / `elasticache:DeleteServerlessCache` | 创建 / 删除 Valkey Serverless 缓存 |
| `elasticache:Describe*` | 查询缓存资源 |
| `elasticache:AddTagsToResource` / `elasticache:RemoveTagsFromResource` / `elasticache:ListTagsForResource` | 标签管理 |

#### ELB

| 动作 | 说明 |
|------|------|
| `elasticloadbalancing:CreateLoadBalancer` / `elasticloadbalancing:DeleteLoadBalancer` | 创建 / 删除 ALB |
| `elasticloadbalancing:CreateTargetGroup` / `elasticloadbalancing:DeleteTargetGroup` | 创建 / 删除目标组（API 8000、Docs 5173、Bridge 8001、Frontend 3000） |
| `elasticloadbalancing:CreateListener` / `elasticloadbalancing:DeleteListener` | 创建 / 删除监听器（HTTP:80） |
| `elasticloadbalancing:CreateRule` / `elasticloadbalancing:DeleteRule` / `elasticloadbalancing:ModifyRule` | 管理转发规则（`/api/*`、`/playbook*`、`/bridge/*`） |
| `elasticloadbalancing:ModifyLoadBalancerAttributes` / `elasticloadbalancing:ModifyTargetGroupAttributes` | 修改 ALB / 目标组属性 |
| `elasticloadbalancing:RegisterTargets` / `elasticloadbalancing:DeregisterTargets` | 注册 / 注销 EC2 目标 |
| `elasticloadbalancing:AddTags` / `elasticloadbalancing:RemoveTags` | 打标签 |
| `elasticloadbalancing:Describe*` | 查询状态 |

#### CloudFront

| 动作 | 说明 |
|------|------|
| `cloudfront:CreateDistribution` / `cloudfront:DeleteDistribution` / `cloudfront:UpdateDistribution` | 创建 / 删除 / 更新 CloudFront 分发 |
| `cloudfront:GetDistribution` / `cloudfront:GetDistributionConfig` | 查询分发与配置 |
| `cloudfront:TagResource` / `cloudfront:UntagResource` / `cloudfront:ListTagsForResource` | 标签管理 |
| `cloudfront:ListDistributions` | 列出分发 |

#### LambdaCustomResource

| 动作 | 说明 |
|------|------|
| `lambda:CreateFunction` / `lambda:DeleteFunction` / `lambda:GetFunction` | CloudFormation Custom Resource 使用的 Lambda 函数管理 |
| `lambda:InvokeFunction` | 调用 Custom Resource |
| `lambda:AddPermission` / `lambda:RemovePermission` | 管理函数权限 |
| `lambda:UpdateFunctionCode` | 更新代码 |

#### SSMGetAMI

| 动作 | 说明 |
|------|------|
| `ssm:GetParameter` / `ssm:GetParameters` | 通过 `/aws/service/ami-amazon-linux-latest/*` 路径自动获取最新 Amazon Linux 2023 AMI ID（模板参数 `AmiId` 默认值） |

#### CleanDataOptional（可选）

| 动作 | 说明 |
|------|------|
| `s3:ListAllMyBuckets` / `s3:ListBucket` / `s3:ListBucketVersions` | 列出 `-{env_suffix}` 后缀桶 |
| `s3:DeleteObject` / `s3:DeleteObjectVersion` / `s3:DeleteBucket` | 清空并删除 S3 桶 |
| `s3:GetBucketVersioning` | 判断是否需要删除版本 |
| `dynamodb:ListTables` / `dynamodb:DeleteTable` / `dynamodb:DescribeTable` | 列出、删除 `{env_prefix}_` 前缀的 DDB 表 |
| `sqs:ListQueues` / `sqs:GetQueueUrl` / `sqs:DeleteQueue` | 列出、删除 `{env_prefix}-` 前缀的 SQS 队列 |

Condition: `aws:ResourceTag/Environment` 必须以 `nexus-ai-*` 开头，限制只能操作带该环境标签的资源。

## EC2 Runtime 策略

**用途**：EC2 实例运行 Nexus-AI 业务时需要的权限。通过 CloudFormation 参数 `IamInstanceProfile`（默认 `admin-for-ec2`）附加到实例。

### EC2 Runtime 权限概览

| Sid | 服务 | Resource 范围 | 说明 |
|-----|------|---------------|------|
| BedrockModelInference | Bedrock | `*` | 基础模型推理（InvokeModel + 流式） |
| BedrockKnowledgeBase | Bedrock | `arn:aws:bedrock:*:*:knowledge-base/*` | 知识库检索（Retrieve / RetrieveAndGenerate） |
| DynamoDB | DynamoDB | `arn:aws:dynamodb:*:*:table/*` | 业务 DDB 表读写、TTL 配置、标签管理 |
| SQS | SQS | `arn:aws:sqs:*:*:nexus*` | `nexus*` 前缀的队列读写 |
| S3 | S3 | `arn:aws:s3:::nexus-ai-*`、`arn:aws:s3:::nexus-ai-*/*` | `nexus-ai-*` 前缀桶的对象读写 + CORS / 版本 / 标签 |
| S3Vectors | S3 Vectors | `*` | 向量桶与索引的创建 / 查询 |
| CloudWatchLogs | Logs | `arn:aws:logs:*:*:log-group:*nexus*` | 含 `nexus` 的日志组读写 |
| CloudWatchMetrics | CloudWatch | `*` | 指标写入 + Dashboard 管理 |
| ECRForAgentCore | ECR | `*` | 获取 ECR 登录令牌（AgentCore 构建镜像） |
| ECRRepository | ECR | `arn:aws:ecr:*:*:repository/nexus-ai*` | `nexus-ai*` 前缀仓库读写 |
| CloudFormationQuery | CloudFormation | `*` | 运行时查询 Stack 输出 |
| EC2Describe | EC2 | `*` | 查询 VPC / 子网 / 安全组 / 实例 |

### EC2 Runtime 完整策略 JSON

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "BedrockModelInference",
      "Effect": "Allow",
      "Action": [
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream",
        "bedrock:GetFoundationModel",
        "bedrock:ListFoundationModels"
      ],
      "Resource": "*"
    },
    {
      "Sid": "BedrockKnowledgeBase",
      "Effect": "Allow",
      "Action": [
        "bedrock:Retrieve",
        "bedrock:RetrieveAndGenerate",
        "bedrock:GetKnowledgeBase",
        "bedrock:ListKnowledgeBases"
      ],
      "Resource": "arn:aws:bedrock:*:*:knowledge-base/*"
    },
    {
      "Sid": "DynamoDB",
      "Effect": "Allow",
      "Action": [
        "dynamodb:CreateTable",
        "dynamodb:DescribeTable",
        "dynamodb:UpdateTable",
        "dynamodb:UpdateTimeToLive",
        "dynamodb:ListTables",
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem",
        "dynamodb:Query",
        "dynamodb:Scan",
        "dynamodb:BatchGetItem",
        "dynamodb:BatchWriteItem",
        "dynamodb:TagResource",
        "dynamodb:ListTagsOfResource"
      ],
      "Resource": "arn:aws:dynamodb:*:*:table/*"
    },
    {
      "Sid": "SQS",
      "Effect": "Allow",
      "Action": [
        "sqs:CreateQueue",
        "sqs:GetQueueUrl",
        "sqs:GetQueueAttributes",
        "sqs:SetQueueAttributes",
        "sqs:SendMessage",
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:ChangeMessageVisibility",
        "sqs:PurgeQueue",
        "sqs:ListQueues",
        "sqs:TagQueue",
        "sqs:ListQueueTags"
      ],
      "Resource": "arn:aws:sqs:*:*:nexus*"
    },
    {
      "Sid": "S3",
      "Effect": "Allow",
      "Action": [
        "s3:CreateBucket",
        "s3:ListBucket",
        "s3:GetBucketLocation",
        "s3:GetBucketVersioning",
        "s3:PutBucketVersioning",
        "s3:PutBucketCors",
        "s3:GetBucketCors",
        "s3:PutBucketTagging",
        "s3:GetBucketTagging",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:GetObjectTagging",
        "s3:PutObjectTagging"
      ],
      "Resource": [
        "arn:aws:s3:::nexus-ai-*",
        "arn:aws:s3:::nexus-ai-*/*"
      ]
    },
    {
      "Sid": "S3Vectors",
      "Effect": "Allow",
      "Action": [
        "s3vectors:CreateVectorBucket",
        "s3vectors:DeleteVectorBucket",
        "s3vectors:ListVectorBuckets",
        "s3vectors:DescribeVectorBucket",
        "s3vectors:CreateIndex",
        "s3vectors:DeleteIndex",
        "s3vectors:DescribeIndex",
        "s3vectors:PutObject",
        "s3vectors:GetObject",
        "s3vectors:DeleteObject",
        "s3vectors:QueryVectors",
        "s3vectors:SearchVectors"
      ],
      "Resource": "*"
    },
    {
      "Sid": "CloudWatchLogs",
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "logs:PutRetentionPolicy",
        "logs:TagLogGroup"
      ],
      "Resource": "arn:aws:logs:*:*:log-group:*nexus*"
    },
    {
      "Sid": "CloudWatchMetrics",
      "Effect": "Allow",
      "Action": [
        "cloudwatch:PutMetricData",
        "cloudwatch:GetMetricStatistics",
        "cloudwatch:ListMetrics",
        "cloudwatch:PutDashboard",
        "cloudwatch:GetDashboard",
        "cloudwatch:ListDashboards"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ECRForAgentCore",
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ECRRepository",
      "Effect": "Allow",
      "Action": [
        "ecr:CreateRepository",
        "ecr:DescribeRepositories",
        "ecr:ListImages",
        "ecr:DescribeImages",
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:BatchCheckLayerAvailability",
        "ecr:TagResource"
      ],
      "Resource": "arn:aws:ecr:*:*:repository/nexus-ai*"
    },
    {
      "Sid": "CloudFormationQuery",
      "Effect": "Allow",
      "Action": [
        "cloudformation:DescribeStacks",
        "cloudformation:DescribeStackResources"
      ],
      "Resource": "*"
    },
    {
      "Sid": "EC2Describe",
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSubnets",
        "ec2:DescribeVpcs"
      ],
      "Resource": "*"
    }
  ]
}
```

### EC2 Runtime 每条语句动作明细

#### BedrockModelInference

| 动作 | 说明 |
|------|------|
| `bedrock:InvokeModel` | 同步调用基础模型 |
| `bedrock:InvokeModelWithResponseStream` | 流式调用基础模型 |
| `bedrock:GetFoundationModel` | 查询单个基础模型信息 |
| `bedrock:ListFoundationModels` | 列出可用基础模型 |

#### BedrockKnowledgeBase

| 动作 | 说明 |
|------|------|
| `bedrock:Retrieve` | 从知识库检索内容 |
| `bedrock:RetrieveAndGenerate` | 检索并生成响应 |
| `bedrock:GetKnowledgeBase` | 查询单个知识库 |
| `bedrock:ListKnowledgeBases` | 列出知识库 |

#### DynamoDB

| 动作 | 说明 |
|------|------|
| `dynamodb:CreateTable` | `nexus-cli init` 创建业务表 |
| `dynamodb:DescribeTable` | 查询表结构与状态 |
| `dynamodb:UpdateTable` | 修改表（索引、容量） |
| `dynamodb:UpdateTimeToLive` | 配置 TTL（`sandbox_logs` 保留 30 天等） |
| `dynamodb:ListTables` | 列出表 |
| `dynamodb:PutItem` / `dynamodb:GetItem` / `dynamodb:UpdateItem` / `dynamodb:DeleteItem` | CRUD 单条 |
| `dynamodb:Query` / `dynamodb:Scan` | 查询 |
| `dynamodb:BatchGetItem` / `dynamodb:BatchWriteItem` | 批量 CRUD |
| `dynamodb:TagResource` / `dynamodb:ListTagsOfResource` | 标签管理 |

#### SQS

| 动作 | 说明 |
|------|------|
| `sqs:CreateQueue` | `nexus-cli init` 创建队列（`nexus-build-queue`、`nexus-build-dlq`、`nexus-deploy-dlq`） |
| `sqs:GetQueueUrl` / `sqs:GetQueueAttributes` / `sqs:SetQueueAttributes` | 查询 / 设置队列属性 |
| `sqs:SendMessage` / `sqs:ReceiveMessage` / `sqs:DeleteMessage` | 消息读写 |
| `sqs:ChangeMessageVisibility` | 修改消息可见性超时 |
| `sqs:PurgeQueue` | 清空队列 |
| `sqs:ListQueues` | 列出队列 |
| `sqs:TagQueue` / `sqs:ListQueueTags` | 标签管理 |

#### S3

| 动作 | 说明 |
|------|------|
| `s3:CreateBucket` | 初始化时创建 `nexus-ai-*` 桶 |
| `s3:ListBucket` | 列出对象 |
| `s3:GetBucketLocation` | 获取桶所在区域 |
| `s3:GetBucketVersioning` / `s3:PutBucketVersioning` | 读取 / 设置版本控制 |
| `s3:PutBucketCors` / `s3:GetBucketCors` | CORS 配置（前端直传）|
| `s3:PutBucketTagging` / `s3:GetBucketTagging` | 桶标签 |
| `s3:GetObject` / `s3:PutObject` / `s3:DeleteObject` | 对象 CRUD |
| `s3:GetObjectTagging` / `s3:PutObjectTagging` | 对象标签 |

#### S3Vectors

| 动作 | 说明 |
|------|------|
| `s3vectors:CreateVectorBucket` / `s3vectors:DeleteVectorBucket` | 向量桶创建 / 删除 |
| `s3vectors:ListVectorBuckets` / `s3vectors:DescribeVectorBucket` | 查询向量桶 |
| `s3vectors:CreateIndex` / `s3vectors:DeleteIndex` / `s3vectors:DescribeIndex` | 索引管理 |
| `s3vectors:PutObject` / `s3vectors:GetObject` / `s3vectors:DeleteObject` | 向量对象读写 |
| `s3vectors:QueryVectors` / `s3vectors:SearchVectors` | 向量检索 |

#### CloudWatchLogs

| 动作 | 说明 |
|------|------|
| `logs:CreateLogGroup` / `logs:CreateLogStream` | 创建日志组 / 日志流 |
| `logs:PutLogEvents` | 写入日志 |
| `logs:DescribeLogGroups` / `logs:DescribeLogStreams` | 查询日志组 / 日志流 |
| `logs:PutRetentionPolicy` | 设置保留策略 |
| `logs:TagLogGroup` | 打标签 |

#### CloudWatchMetrics

| 动作 | 说明 |
|------|------|
| `cloudwatch:PutMetricData` | 上报自定义指标（`NexusAI` 命名空间下的 `api.*`、`agent.*`、`build.*`、`sandbox.*` 等） |
| `cloudwatch:GetMetricStatistics` | 查询历史统计值 |
| `cloudwatch:ListMetrics` | 列出指标 |
| `cloudwatch:PutDashboard` / `cloudwatch:GetDashboard` / `cloudwatch:ListDashboards` | Dashboard 管理（`infrastructure/cloudwatch-dashboard.json`） |

#### ECRForAgentCore

| 动作 | 说明 |
|------|------|
| `ecr:GetAuthorizationToken` | AgentCore 构建前获取登录令牌，只能在 `*` 上 |

#### ECRRepository

| 动作 | 说明 |
|------|------|
| `ecr:CreateRepository` / `ecr:DescribeRepositories` / `ecr:ListImages` / `ecr:DescribeImages` | `nexus-ai*` 仓库创建 / 查询 |
| `ecr:BatchGetImage` / `ecr:GetDownloadUrlForLayer` / `ecr:BatchCheckLayerAvailability` | 拉取镜像 |
| `ecr:PutImage` / `ecr:InitiateLayerUpload` / `ecr:UploadLayerPart` / `ecr:CompleteLayerUpload` | 推送镜像 |
| `ecr:TagResource` | 打标签 |

#### CloudFormationQuery

| 动作 | 说明 |
|------|------|
| `cloudformation:DescribeStacks` | 运行时查询 Stack 输出（如 ALB DNS、CloudFront 域名） |
| `cloudformation:DescribeStackResources` | 查询 Stack 内资源 |

#### EC2Describe

| 动作 | 说明 |
|------|------|
| `ec2:DescribeInstances` | 查询实例 |
| `ec2:DescribeSecurityGroups` | 查询安全组 |
| `ec2:DescribeSubnets` | 查询子网 |
| `ec2:DescribeVpcs` | 查询 VPC |

## 可选：Bedrock AgentCore 扩展

如果你使用 Bedrock AgentCore 作为部署目标，在 EC2 Runtime 策略中追加下面这条语句：

```json
{
  "Sid": "BedrockAgentCore",
  "Effect": "Allow",
  "Action": [
    "bedrock-agentcore-control:CreateAgentRuntime",
    "bedrock-agentcore-control:DeleteAgentRuntime",
    "bedrock-agentcore-control:DescribeAgentRuntime",
    "bedrock-agentcore-control:ListAgentRuntimes",
    "bedrock-agentcore:InvokeAgent"
  ],
  "Resource": "*"
}
```

| 动作 | 说明 |
|------|------|
| `bedrock-agentcore-control:CreateAgentRuntime` | 创建 AgentCore 运行时 |
| `bedrock-agentcore-control:DeleteAgentRuntime` | 删除 AgentCore 运行时 |
| `bedrock-agentcore-control:DescribeAgentRuntime` | 查询 AgentCore 运行时 |
| `bedrock-agentcore-control:ListAgentRuntimes` | 列出 AgentCore 运行时 |
| `bedrock-agentcore:InvokeAgent` | 调用已部署的 Agent |

## 收紧资源 ARN

上述策略对部分 Resource 使用 `*` 以简化部署。生产环境建议进一步收紧：

| 服务 | 将 `*` 替换为 | 示例 |
|------|----------------|------|
| DynamoDB | 带前缀的表 ARN | `arn:aws:dynamodb:us-west-2:123456789:table/nexus_*` |
| SQS | 带前缀的队列 ARN | `arn:aws:sqs:us-west-2:123456789:nexus-*` |
| S3 | 带前缀的桶 ARN | `arn:aws:s3:::nexus-ai-*` |
| Bedrock | 指定模型 ARN | `arn:aws:bedrock:us-west-2::foundation-model/anthropic.claude*` |
| CloudWatch Logs | 指定日志组 ARN | `arn:aws:logs:us-west-2:123456789:log-group:/nexus-*` |

::: warning 替换说明
将 `123456789` 替换为你的 AWS 账号 ID，`us-west-2` 替换为实际部署区域。
:::

## 常见陷阱

| 现象 | 原因 | 处理 |
|------|------|------|
| `CREATE_FAILED: iam:PassRole` | Deployer 缺少 `iam:PassRole`，或 Instance Profile 名称不在 `nexus-ai-*` 范围 | 确认 Deployer 策略 `IAMRolesAndProfiles` 已包含 `iam:PassRole`；或把 Instance Profile 命名为 `nexus-ai-*` 前缀 |
| `AccessDenied: bedrock:InvokeModel` | EC2 Runtime 未附加 `BedrockModelInference`，或模型未在 Bedrock Console 启用 | 附加策略 + 在 Bedrock Console 启用所需模型 |
| `deploy.sh --clean-data` 无法删除 S3 桶 | Deployer 缺少 `CleanDataOptional` 语句或资源没有 `Environment=nexus-ai-*` 标签 | 追加 `CleanDataOptional`；资源创建时已通过 `deploy.sh` 注入该标签 |
| CloudWatch 日志组无法创建 | EC2 Runtime 的 `CloudWatchLogs` 限制在 `*nexus*` 命名的日志组 | 日志组名称需包含 `nexus`，或放宽资源范围 |
| ECR 推送失败 `ecr:GetAuthorizationToken` 被拒 | 该动作只能作用在 `*`，EC2 Runtime 必须含 `ECRForAgentCore` 语句 | 保留 `ECRForAgentCore` 语句 |

## 验证步骤

1. **Deployer**：在 Deployer 身份下执行 `aws cloudformation validate-template --template-body file://infrastructure/cloudformation/nexus-ai-env.yaml --region us-west-2`，应返回模板摘要而非 `AccessDenied`。
2. **EC2 Runtime**：SSH 登录 EC2 后，执行 `aws sts get-caller-identity` 查看当前角色，再执行 `aws bedrock list-foundation-models --region us-west-2` 验证 Bedrock 权限。
3. **数据清理**：仅在需要时执行 `./deploy.sh &lt;env&gt; --delete --clean-data`，观察是否能列出并删除目标 S3 桶 / DDB 表 / SQS 队列。
