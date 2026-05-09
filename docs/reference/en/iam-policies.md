---
title: IAM Policies
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - docs/infrastructure/IAM_POLICIES.md
    - infrastructure/**
  generated_at: 2026-05-09T01:32:56+00:00
  generated_by: docs-sync v2
---

# IAM Policies

A Nexus-AI deployment involves two separate IAM identities, each with its own least-privilege policy:

| Role | Purpose | How to attach |
|------|---------|---------------|
| **Deployer** | The IAM user or role that runs `infrastructure/cloudformation/deploy.sh` to create / update / delete CloudFormation stacks | Attach directly to the IAM user or role |
| **EC2 Runtime** | The role used by the Nexus-AI EC2 instance at runtime — Bedrock invocation, DynamoDB / SQS / S3 / ECR access, log shipping, etc. | Attach via an Instance Profile (CloudFormation parameter `IamInstanceProfile`, default `admin-for-ec2`) |

Both policies are IAM Policy JSON (`"Version": "2012-10-17"`) and can be pasted directly into the IAM Console or fed to `aws iam create-policy`.

::: info Prerequisites
- All Resource ARN prefixes (`nexus-ai-*`, `nexus-ai*`, `nexus*`, table prefixes, etc.) correspond to the `EnvironmentPrefix` convention used by `deploy.sh`.
- The region used in examples is `us-west-2` (the default value of `REGION` in `deploy.sh`).
- To tighten resource scope further, see the "Tightening resource ARNs" section below.
:::

## Deployer policy

**Purpose**: Run `./deploy.sh &lt;env-prefix&gt;` to create / update / delete all AWS resources required for a Nexus-AI test environment (VPC, EC2, ALB, CloudFront, Aurora, ElastiCache, Lambda, etc.).

### Deployer permissions overview

| Sid | Service | Resource scope | Description |
|-----|---------|----------------|-------------|
| CloudFormation | CloudFormation | `arn:aws:cloudformation:*:*:stack/nexus-ai-*/*` | Create, update, delete, describe stacks prefixed `nexus-ai-*` |
| EC2VPCAndInstances | EC2 | `*` | Create VPC / subnets / IGW / NAT / route tables / security groups / VPC endpoints / EC2 instances / EBS volumes |
| IAMRolesAndProfiles | IAM | `arn:aws:iam::*:role/nexus-ai-*`, `arn:aws:iam::*:instance-profile/nexus-ai-*` | Create IAM roles and instance profiles prefixed `nexus-ai-*`; `PassRole` to EC2 |
| RDSAurora | RDS | `*` | Create / delete / modify Aurora clusters, instances, subnet groups |
| ElastiCacheValkey | ElastiCache | `*` | Create / delete Valkey Serverless caches |
| ELB | Elastic Load Balancing | `*` | Create ALBs, target groups, listeners, rules; register / deregister EC2 targets |
| CloudFront | CloudFront | `*` | Create / update / delete CloudFront distributions, tag resources |
| LambdaCustomResource | Lambda | `arn:aws:lambda:*:*:function:nexus-ai-*` | Manage Lambda functions backing CloudFormation Custom Resources |
| SSMGetAMI | SSM | `arn:aws:ssm:*::parameter/aws/service/ami-amazon-linux-latest/*` | Fetch the latest Amazon Linux 2023 AMI ID via SSM parameters |
| CleanDataOptional | S3, DynamoDB, SQS | `*` (with Tag condition) | **Optional** — needed only when running `deploy.sh --delete --clean-data`; restricted by `aws:ResourceTag/Environment=nexus-ai-*` |

### Deployer full policy JSON

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

::: tip CleanDataOptional is optional
`CleanDataOptional` is only required if you plan to run `deploy.sh --delete --clean-data`. If you don't use that flag to wipe S3 buckets, DynamoDB tables, and SQS queues, remove the statement.
:::

### Deployer action details per statement

#### CloudFormation

| Action | Description |
|--------|-------------|
| `cloudformation:CreateStack` | Create a stack |
| `cloudformation:DeleteStack` | Delete a stack |
| `cloudformation:UpdateStack` | Update a stack |
| `cloudformation:DescribeStacks` | Read stack details |
| `cloudformation:DescribeStackEvents` | Read the stack event stream |
| `cloudformation:DescribeStackResources` | List resources inside a stack |
| `cloudformation:ValidateTemplate` | Validate the template before `deploy.sh` creates the stack |
| `cloudformation:GetTemplateSummary` | Fetch template summary |
| `cloudformation:ListStacks` | List stacks |

#### EC2VPCAndInstances

| Action | Description |
|--------|-------------|
| `ec2:CreateVpc` / `ec2:DeleteVpc` | Create / delete the VPC (default `10.0.0.0/16`, override via `VpcCidr`) |
| `ec2:CreateSubnet` / `ec2:DeleteSubnet` | Create / delete public + private subnets (4 in total) |
| `ec2:CreateInternetGateway` / `ec2:DeleteInternetGateway` | Create / delete the IGW |
| `ec2:AttachInternetGateway` / `ec2:DetachInternetGateway` | Attach / detach the IGW to the VPC |
| `ec2:CreateNatGateway` / `ec2:DeleteNatGateway` | Create / delete the NAT Gateway |
| `ec2:AllocateAddress` / `ec2:ReleaseAddress` | Allocate / release the EIP used by NAT |
| `ec2:CreateRouteTable` / `ec2:DeleteRouteTable` | Create / delete route tables |
| `ec2:CreateRoute` / `ec2:DeleteRoute` | Add / remove route entries |
| `ec2:AssociateRouteTable` / `ec2:DisassociateRouteTable` | Associate / disassociate subnets with route tables |
| `ec2:CreateSecurityGroup` / `ec2:DeleteSecurityGroup` | Create / delete security groups |
| `ec2:AuthorizeSecurityGroupIngress` / `ec2:AuthorizeSecurityGroupEgress` | Add ingress / egress rules |
| `ec2:RevokeSecurityGroupIngress` / `ec2:RevokeSecurityGroupEgress` | Revoke ingress / egress rules |
| `ec2:RunInstances` / `ec2:TerminateInstances` | Launch / terminate EC2 instances |
| `ec2:CreateTags` / `ec2:DeleteTags` | Tag resources |
| `ec2:CreateVolume` / `ec2:DeleteVolume` / `ec2:ModifyVolume` | Create / delete / modify EBS volumes (root volume defaults to 150 GB) |
| `ec2:CreateVpcEndpoint` / `ec2:DeleteVpcEndpoints` | Create / delete VPC endpoints (DynamoDB, S3 gateway endpoints) |
| `ec2:Describe*` | Read state of any EC2 resource |

#### IAMRolesAndProfiles

| Action | Description |
|--------|-------------|
| `iam:CreateRole` / `iam:DeleteRole` | Create / delete `nexus-ai-*` roles |
| `iam:GetRole` | Read a role |
| `iam:AttachRolePolicy` / `iam:DetachRolePolicy` | Attach / detach managed policies |
| `iam:PutRolePolicy` / `iam:DeleteRolePolicy` | Put / delete inline policies |
| `iam:CreateInstanceProfile` / `iam:DeleteInstanceProfile` | Create / delete `nexus-ai-*` instance profiles |
| `iam:GetInstanceProfile` | Read an instance profile |
| `iam:AddRoleToInstanceProfile` / `iam:RemoveRoleFromInstanceProfile` | Bind / unbind a role to an instance profile |
| `iam:PassRole` | Hand the EC2 runtime role to the EC2 service |
| `iam:ListAttachedRolePolicies` / `iam:ListRolePolicies` | List policies attached to a role |

#### RDSAurora

| Action | Description |
|--------|-------------|
| `rds:CreateDBCluster` / `rds:DeleteDBCluster` / `rds:ModifyDBCluster` | Create / delete / modify the Aurora PostgreSQL cluster |
| `rds:CreateDBInstance` / `rds:DeleteDBInstance` | Create / delete the Aurora writer instance (`db.serverless`) |
| `rds:CreateDBSubnetGroup` / `rds:DeleteDBSubnetGroup` | Create / delete the DB subnet group |
| `rds:Describe*` | Read Aurora resource state |
| `rds:AddTagsToResource` / `rds:RemoveTagsFromResource` | Tag management |

#### ElastiCacheValkey

| Action | Description |
|--------|-------------|
| `elasticache:CreateServerlessCache` / `elasticache:DeleteServerlessCache` | Create / delete the Valkey Serverless cache |
| `elasticache:Describe*` | Read cache resources |
| `elasticache:AddTagsToResource` / `elasticache:RemoveTagsFromResource` / `elasticache:ListTagsForResource` | Tag management |

#### ELB

| Action | Description |
|--------|-------------|
| `elasticloadbalancing:CreateLoadBalancer` / `elasticloadbalancing:DeleteLoadBalancer` | Create / delete the ALB |
| `elasticloadbalancing:CreateTargetGroup` / `elasticloadbalancing:DeleteTargetGroup` | Create / delete target groups (API 8000, Docs 5173, Bridge 8001, Frontend 3000) |
| `elasticloadbalancing:CreateListener` / `elasticloadbalancing:DeleteListener` | Create / delete listeners (HTTP:80) |
| `elasticloadbalancing:CreateRule` / `elasticloadbalancing:DeleteRule` / `elasticloadbalancing:ModifyRule` | Manage forwarding rules (`/api/*`, `/playbook*`, `/bridge/*`) |
| `elasticloadbalancing:ModifyLoadBalancerAttributes` / `elasticloadbalancing:ModifyTargetGroupAttributes` | Modify ALB / target group attributes |
| `elasticloadbalancing:RegisterTargets` / `elasticloadbalancing:DeregisterTargets` | Register / deregister EC2 targets |
| `elasticloadbalancing:AddTags` / `elasticloadbalancing:RemoveTags` | Tag management |
| `elasticloadbalancing:Describe*` | Read state |

#### CloudFront

| Action | Description |
|--------|-------------|
| `cloudfront:CreateDistribution` / `cloudfront:DeleteDistribution` / `cloudfront:UpdateDistribution` | Create / delete / update a CloudFront distribution |
| `cloudfront:GetDistribution` / `cloudfront:GetDistributionConfig` | Read a distribution and its config |
| `cloudfront:TagResource` / `cloudfront:UntagResource` / `cloudfront:ListTagsForResource` | Tag management |
| `cloudfront:ListDistributions` | List distributions |

#### LambdaCustomResource

| Action | Description |
|--------|-------------|
| `lambda:CreateFunction` / `lambda:DeleteFunction` / `lambda:GetFunction` | Manage Lambda functions used by CloudFormation Custom Resources |
| `lambda:InvokeFunction` | Invoke the Custom Resource |
| `lambda:AddPermission` / `lambda:RemovePermission` | Manage function permissions |
| `lambda:UpdateFunctionCode` | Update function code |

#### SSMGetAMI

| Action | Description |
|--------|-------------|
| `ssm:GetParameter` / `ssm:GetParameters` | Resolve the latest Amazon Linux 2023 AMI ID via `/aws/service/ami-amazon-linux-latest/*` (default value of template parameter `AmiId`) |

#### CleanDataOptional (optional)

| Action | Description |
|--------|-------------|
| `s3:ListAllMyBuckets` / `s3:ListBucket` / `s3:ListBucketVersions` | List buckets with the `-{env_suffix}` suffix |
| `s3:DeleteObject` / `s3:DeleteObjectVersion` / `s3:DeleteBucket` | Empty and delete S3 buckets |
| `s3:GetBucketVersioning` | Determine whether versioned objects must be removed first |
| `dynamodb:ListTables` / `dynamodb:DeleteTable` / `dynamodb:DescribeTable` | List and delete DDB tables with the `{env_prefix}_` prefix |
| `sqs:ListQueues` / `sqs:GetQueueUrl` / `sqs:DeleteQueue` | List and delete SQS queues with the `{env_prefix}-` prefix |

Condition: `aws:ResourceTag/Environment` must start with `nexus-ai-*`, so only resources tagged with that environment are affected.

## EC2 Runtime policy

**Purpose**: Permissions required by the EC2 instance running Nexus-AI. Attached via the `IamInstanceProfile` CloudFormation parameter (default `admin-for-ec2`).

### EC2 Runtime permissions overview

| Sid | Service | Resource scope | Description |
|-----|---------|----------------|-------------|
| BedrockModelInference | Bedrock | `*` | Foundation-model inference (InvokeModel + streaming) |
| BedrockKnowledgeBase | Bedrock | `arn:aws:bedrock:*:*:knowledge-base/*` | Knowledge-base retrieval (Retrieve / RetrieveAndGenerate) |
| DynamoDB | DynamoDB | `arn:aws:dynamodb:*:*:table/*` | Read / write business DDB tables, configure TTL, manage tags |
| SQS | SQS | `arn:aws:sqs:*:*:nexus*` | Read / write queues with the `nexus*` prefix |
| S3 | S3 | `arn:aws:s3:::nexus-ai-*`, `arn:aws:s3:::nexus-ai-*/*` | Object read/write + CORS / versioning / tagging on `nexus-ai-*` buckets |
| S3Vectors | S3 Vectors | `*` | Manage vector buckets and indexes |
| CloudWatchLogs | Logs | `arn:aws:logs:*:*:log-group:*nexus*` | Read / write log groups containing `nexus` |
| CloudWatchMetrics | CloudWatch | `*` | Publish metrics and manage dashboards |
| ECRForAgentCore | ECR | `*` | Get ECR authorization token (AgentCore image build) |
| ECRRepository | ECR | `arn:aws:ecr:*:*:repository/nexus-ai*` | Read / write `nexus-ai*` repositories |
| CloudFormationQuery | CloudFormation | `*` | Query stack outputs at runtime |
| EC2Describe | EC2 | `*` | Describe VPC / subnets / security groups / instances |

### EC2 Runtime full policy JSON

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

### EC2 Runtime action details per statement

#### BedrockModelInference

| Action | Description |
|--------|-------------|
| `bedrock:InvokeModel` | Synchronous foundation-model invocation |
| `bedrock:InvokeModelWithResponseStream` | Streaming foundation-model invocation |
| `bedrock:GetFoundationModel` | Read a single foundation model |
| `bedrock:ListFoundationModels` | List available foundation models |

#### BedrockKnowledgeBase

| Action | Description |
|--------|-------------|
| `bedrock:Retrieve` | Retrieve content from a knowledge base |
| `bedrock:RetrieveAndGenerate` | Retrieve and generate a response |
| `bedrock:GetKnowledgeBase` | Read a single knowledge base |
| `bedrock:ListKnowledgeBases` | List knowledge bases |

#### DynamoDB

| Action | Description |
|--------|-------------|
| `dynamodb:CreateTable` | Business tables created by `nexus-cli init` |
| `dynamodb:DescribeTable` | Read table schema and state |
| `dynamodb:UpdateTable` | Modify table (indexes, capacity) |
| `dynamodb:UpdateTimeToLive` | Configure TTL (e.g. `sandbox_logs` retains 30 days) |
| `dynamodb:ListTables` | List tables |
| `dynamodb:PutItem` / `dynamodb:GetItem` / `dynamodb:UpdateItem` / `dynamodb:DeleteItem` | Single-item CRUD |
| `dynamodb:Query` / `dynamodb:Scan` | Query |
| `dynamodb:BatchGetItem` / `dynamodb:BatchWriteItem` | Batch CRUD |
| `dynamodb:TagResource` / `dynamodb:ListTagsOfResource` | Tag management |

#### SQS

| Action | Description |
|--------|-------------|
| `sqs:CreateQueue` | Queues created by `nexus-cli init` (`nexus-build-queue`, `nexus-build-dlq`, `nexus-deploy-dlq`) |
| `sqs:GetQueueUrl` / `sqs:GetQueueAttributes` / `sqs:SetQueueAttributes` | Read / set queue attributes |
| `sqs:SendMessage` / `sqs:ReceiveMessage` / `sqs:DeleteMessage` | Message read/write |
| `sqs:ChangeMessageVisibility` | Change message visibility timeout |
| `sqs:PurgeQueue` | Empty a queue |
| `sqs:ListQueues` | List queues |
| `sqs:TagQueue` / `sqs:ListQueueTags` | Tag management |

#### S3

| Action | Description |
|--------|-------------|
| `s3:CreateBucket` | Create `nexus-ai-*` buckets at init time |
| `s3:ListBucket` | List objects |
| `s3:GetBucketLocation` | Get bucket region |
| `s3:GetBucketVersioning` / `s3:PutBucketVersioning` | Read / set versioning |
| `s3:PutBucketCors` / `s3:GetBucketCors` | CORS configuration (frontend direct upload) |
| `s3:PutBucketTagging` / `s3:GetBucketTagging` | Bucket tags |
| `s3:GetObject` / `s3:PutObject` / `s3:DeleteObject` | Object CRUD |
| `s3:GetObjectTagging` / `s3:PutObjectTagging` | Object tags |

#### S3Vectors

| Action | Description |
|--------|-------------|
| `s3vectors:CreateVectorBucket` / `s3vectors:DeleteVectorBucket` | Create / delete vector buckets |
| `s3vectors:ListVectorBuckets` / `s3vectors:DescribeVectorBucket` | Read vector buckets |
| `s3vectors:CreateIndex` / `s3vectors:DeleteIndex` / `s3vectors:DescribeIndex` | Index management |
| `s3vectors:PutObject` / `s3vectors:GetObject` / `s3vectors:DeleteObject` | Read / write vector objects |
| `s3vectors:QueryVectors` / `s3vectors:SearchVectors` | Vector search |

#### CloudWatchLogs

| Action | Description |
|--------|-------------|
| `logs:CreateLogGroup` / `logs:CreateLogStream` | Create log groups / log streams |
| `logs:PutLogEvents` | Ship log events |
| `logs:DescribeLogGroups` / `logs:DescribeLogStreams` | Read log groups / streams |
| `logs:PutRetentionPolicy` | Set retention |
| `logs:TagLogGroup` | Tag management |

#### CloudWatchMetrics

| Action | Description |
|--------|-------------|
| `cloudwatch:PutMetricData` | Publish custom metrics (`api.*`, `agent.*`, `build.*`, `sandbox.*` under the `NexusAI` namespace) |
| `cloudwatch:GetMetricStatistics` | Query historical statistics |
| `cloudwatch:ListMetrics` | List metrics |
| `cloudwatch:PutDashboard` / `cloudwatch:GetDashboard` / `cloudwatch:ListDashboards` | Dashboard management (`infrastructure/cloudwatch-dashboard.json`) |

#### ECRForAgentCore

| Action | Description |
|--------|-------------|
| `ecr:GetAuthorizationToken` | Obtain an ECR login token before AgentCore image builds; must be on `*` |

#### ECRRepository

| Action | Description |
|--------|-------------|
| `ecr:CreateRepository` / `ecr:DescribeRepositories` / `ecr:ListImages` / `ecr:DescribeImages` | Create / query `nexus-ai*` repositories |
| `ecr:BatchGetImage` / `ecr:GetDownloadUrlForLayer` / `ecr:BatchCheckLayerAvailability` | Pull images |
| `ecr:PutImage` / `ecr:InitiateLayerUpload` / `ecr:UploadLayerPart` / `ecr:CompleteLayerUpload` | Push images |
| `ecr:TagResource` | Tag management |

#### CloudFormationQuery

| Action | Description |
|--------|-------------|
| `cloudformation:DescribeStacks` | Query stack outputs at runtime (ALB DNS, CloudFront domain, etc.) |
| `cloudformation:DescribeStackResources` | Read resources inside a stack |

#### EC2Describe

| Action | Description |
|--------|-------------|
| `ec2:DescribeInstances` | Describe instances |
| `ec2:DescribeSecurityGroups` | Describe security groups |
| `ec2:DescribeSubnets` | Describe subnets |
| `ec2:DescribeVpcs` | Describe VPCs |

## Optional: Bedrock AgentCore extension

If you use Bedrock AgentCore as a deployment target, append the following statement to the EC2 Runtime policy:

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

| Action | Description |
|--------|-------------|
| `bedrock-agentcore-control:CreateAgentRuntime` | Create an AgentCore runtime |
| `bedrock-agentcore-control:DeleteAgentRuntime` | Delete an AgentCore runtime |
| `bedrock-agentcore-control:DescribeAgentRuntime` | Read an AgentCore runtime |
| `bedrock-agentcore-control:ListAgentRuntimes` | List AgentCore runtimes |
| `bedrock-agentcore:InvokeAgent` | Invoke a deployed agent |

## Tightening resource ARNs

The policies above use `*` for several resources for simplicity. For production, tighten them further:

| Service | Replace `*` with | Example |
|---------|------------------|---------|
| DynamoDB | Table ARN with prefix | `arn:aws:dynamodb:us-west-2:123456789:table/nexus_*` |
| SQS | Queue ARN with prefix | `arn:aws:sqs:us-west-2:123456789:nexus-*` |
| S3 | Bucket ARN with prefix | `arn:aws:s3:::nexus-ai-*` |
| Bedrock | Specific model ARNs | `arn:aws:bedrock:us-west-2::foundation-model/anthropic.claude*` |
| CloudWatch Logs | Log group ARN | `arn:aws:logs:us-west-2:123456789:log-group:/nexus-*` |

::: warning Substitution
Replace `123456789` with your AWS account ID and `us-west-2` with your actual deployment region.
:::

## Common pitfalls

| Symptom | Cause | Fix |
|---------|-------|-----|
| `CREATE_FAILED: iam:PassRole` | Deployer lacks `iam:PassRole`, or the Instance Profile name is outside `nexus-ai-*` | Make sure the Deployer's `IAMRolesAndProfiles` statement includes `iam:PassRole`; or rename the Instance Profile to a `nexus-ai-*` prefix |
| `AccessDenied: bedrock:InvokeModel` | EC2 Runtime missing `BedrockModelInference`, or the model is not enabled in the Bedrock Console | Attach the policy and enable the required models in the Bedrock Console |
| `deploy.sh --clean-data` cannot delete S3 buckets | Deployer lacks `CleanDataOptional`, or resources are missing the `Environment=nexus-ai-*` tag | Add `CleanDataOptional`; the tag is injected at resource creation by `deploy.sh` |
| Cannot create CloudWatch log groups | EC2 Runtime restricts `CloudWatchLogs` to log groups named `*nexus*` | Include `nexus` in the log-group name, or widen the resource scope |
| ECR push fails with `ecr:GetAuthorizationToken` denied | The action must be on `*`; EC2 Runtime must include the `ECRForAgentCore` statement | Keep the `ECRForAgentCore` statement |

## Validation steps

1. **Deployer**: Using the Deployer identity, run `aws cloudformation validate-template --template-body file://infrastructure/cloudformation/nexus-ai-env.yaml --region us-west-2`. It should return a template summary instead of `AccessDenied`.
2. **EC2 Runtime**: SSH into the EC2 instance, run `aws sts get-caller-identity` to confirm the role, then run `aws bedrock list-foundation-models --region us-west-2` to verify Bedrock permissions.
3. **Data cleanup**: Only when needed, run `./deploy.sh &lt;env&gt; --delete --clean-data` and observe whether the target S3 buckets / DDB tables / SQS queues can be listed and removed.
