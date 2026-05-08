---
title: AWS Setup
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - README.md
    - config/default_config.yaml
    - infrastructure/**
  generated_at: 2026-05-08T14:30:10+00:00
  generated_by: docs-sync v2
---

# AWS Setup

## What is this

Nexus-AI runs on AWS and depends on Bedrock, Aurora, Valkey, DynamoDB, SQS, and S3. Before deploying, you need an AWS account with the right services enabled and the right permissions in place. Get this step right and `nexus-cli deploy` (or CloudFormation one-click deployment) will run smoothly afterward.

## When to use this

| Scenario | What you'll do |
|----------|---------------|
| First-time trial | Enable Bedrock model access in your personal/team AWS account, configure the CLI, then spin up a test environment with `nexus-cli deploy` |
| Enterprise rollout | Request a dedicated sandbox account, attach billing and quota, create a dedicated IAM role using the minimum-permission policies below |
| Extending an existing production account | Add Bedrock access, create an EC2 Instance Profile, set up an SSH Key Pair |
| Multi-environment isolation (dev/staging/prod) | Use a different `EnvironmentPrefix` per environment — Nexus-AI automatically isolates VPC, DDB, SQS, and S3 resources |

## How to use it

Complete the 6 steps below in order. Once done, you're ready for the [Quick Start](./quickstart) stage.

### 1. Prepare your AWS account and region

::: tip Recommended region
Nexus-AI defaults to **`us-west-2` (Oregon)** — this region has the most complete Claude 4.5 model coverage. If you use a different region, verify Bedrock model availability there first.
:::

- Sign in to the AWS Console and confirm you have an active account.
- Switch the region selector (top-right) to `us-west-2`.
- Check account quotas: a default deployment creates 1 VPC, 2 NAT Gateways, 1 Aurora cluster, and 1 EC2 instance (`c8i.2xlarge`). Make sure quotas allow this.

<!-- SCREENSHOT: aws-region-selector -->

### 2. Enable Bedrock model access

Nexus-AI invokes the three Claude models below by default. You **must** request access in the Bedrock console — otherwise the platform will fail with AccessDenied on startup.

| Purpose | Model ID |
|---------|----------|
| Default | `us.anthropic.claude-sonnet-4-5-20250929-v1:0` |
| Lite | `us.anthropic.claude-haiku-4-5-20251001-v1:0` |
| Pro | `us.anthropic.claude-opus-4-5-20251101-v1:0` |

Path: `AWS Console → Bedrock → Model access → Manage model access`. Check the three Anthropic Claude 4.5 models and submit. Most accounts are auto-approved within minutes; enterprise accounts may require a short use-case description.

<!-- SCREENSHOT: bedrock-model-access -->

### 3. Create a deployer IAM user or role

The machine that runs the deployment script (your laptop or CI) needs an IAM identity with these permissions:

| Service | Permissions | Purpose |
|---------|-------------|---------|
| CloudFormation | `CreateStack`, `DeleteStack`, `DescribeStacks`, `DescribeStackEvents` | Manage the deployment stack |
| EC2 | `RunInstances`, `TerminateInstances`, `CreateVpc`, `CreateSubnet`, `CreateSecurityGroup`, `CreateNatGateway`, `AllocateAddress`, `CreateRouteTable`, `CreateRoute`, `CreateTags`, `Describe*` | Create VPC and instances |
| IAM | `CreateRole`, `DeleteRole`, `AttachRolePolicy`, `DetachRolePolicy`, `CreateInstanceProfile`, `AddRoleToInstanceProfile`, `PassRole` | Create the instance role |
| RDS | `CreateDBCluster`, `CreateDBInstance`, `CreateDBSubnetGroup`, `DeleteDB*`, `Describe*` | Create the Aurora cluster |
| ElastiCache | `CreateServerlessCache`, `DeleteServerlessCache`, `Describe*` | Create the Valkey cache |
| ELB | `CreateLoadBalancer`, `CreateTargetGroup`, `CreateListener`, `CreateRule`, `RegisterTargets`, `Delete*`, `Describe*` | Create the ALB |
| CloudFront | `CreateDistribution`, `DeleteDistribution`, `Get*`, `Update*` | Create the CDN distribution |
| Lambda | `CreateFunction`, `DeleteFunction`, `GetFunction` | Custom resources |
| SSM | `GetParameter` | Fetch AMI IDs |
| S3 / SQS / DynamoDB | `List*`, `Delete*` | Only needed with `--clean-data` |

Recommended: create a new IAM user or role called `nexus-ai-deployer` and attach a single policy that bundles the permissions above. For test accounts, granting `AdministratorAccess` is a simpler shortcut.

### 4. Create the EC2 runtime Instance Profile

The deployment template uses an Instance Profile named `admin-for-ec2` by default (override via `--iam-instance-profile`). The EC2 instance needs the following minimum permissions:

| Service | Permissions | Purpose |
|---------|-------------|---------|
| Bedrock | `InvokeModel`, `InvokeModelWithResponseStream`, `ListFoundationModels` | Model inference |
| DynamoDB | `CreateTable`, `PutItem`, `GetItem`, `UpdateItem`, `DeleteItem`, `Query`, `Scan` | Platform data |
| SQS | `CreateQueue`, `SendMessage`, `ReceiveMessage`, `DeleteMessage`, `ChangeMessageVisibility` | Async tasks |
| S3 | `CreateBucket`, `GetObject`, `PutObject`, `DeleteObject`, `ListBucket`, `PutBucketCors` | Artifacts and files |
| S3 Vectors | `CreateVectorBucket`, `CreateIndex`, `PutObject`, `Query` | Vector search |
| RDS | `DescribeDBClusters` | Aurora connection info (direct TCP, no IAM Auth) |
| CloudWatch Logs | `CreateLogGroup`, `CreateLogStream`, `PutLogEvents` | Logging |
| ECR | `GetAuthorizationToken`, `BatchGetImage`, `PutImage` | AgentCore deployment |

Steps:

1. Go to `IAM → Roles → Create role`.
2. Select trusted entity type **AWS service → EC2**.
3. Attach a policy with the permissions above (or use `AdministratorAccess` for quick testing).
4. Name the role `admin-for-ec2` — an Instance Profile with the same name is created automatically.

<!-- SCREENSHOT: ec2-instance-profile -->

### 5. Create an SSH Key Pair

The deployment template references the Key Pair `Og_Normal` by default, for SSH troubleshooting access.

- Go to `EC2 → Key Pairs → Create key pair`.
- Name it `Og_Normal` (or use your own name and pass it via `--key-name`).
- Choose `.pem` format, download, and keep it safe.

```bash
chmod 400 Og_Normal.pem
```

### 6. Configure the AWS CLI locally

On the machine where you'll run `nexus-cli deploy`:

```bash
# Install AWS CLI v2 if you haven't already
# macOS: brew install awscli
# Linux: see the official docs

aws configure
# AWS Access Key ID       → Access Key of the deployer user from step 3
# AWS Secret Access Key   → matching secret
# Default region          → us-west-2
# Default output format   → json
```

Verify:

```bash
aws sts get-caller-identity
aws bedrock list-foundation-models --region us-west-2 | head -20
```

If the second command lists models, Bedrock access is working.

## Key parameters & limits

| Item | Default / Recommended | Notes |
|------|----------------------|-------|
| Region | `us-west-2` | Best Claude 4.5 coverage |
| VPC CIDR | `10.0.0.0/16` | Fresh VPC per environment, override with `--vpc-cidr` |
| EC2 instance type | `c8i.2xlarge` | Runs API + Worker + Web + Docs |
| Disk | `150 GB` | Root volume, holds dependencies and build cache |
| Sandbox node | `c8id.xlarge` | Used when Sandbox is enabled, must support KVM |
| Key Pair | `Og_Normal` | Override with `--key-name` |
| IAM Instance Profile | `admin-for-ec2` | Override with `--iam-instance-profile` |
| Aurora password | No default | Must supply a strong password via `--db-password` |
| Login credentials | `admin` / `nexus` | Default dev-mode account — change in production |
| Deploy time | 20–30 min | CloudFront adds another 5–10 min |
| NAT Gateway cost | ≈ $0.045/hour | Tear down idle environments with `deploy down` |

## FAQ

### Q1: Do I have to use us-west-2?

**Strongly recommended**. Nexus-AI's default models (Claude Sonnet 4.5 / Opus 4.5 / Haiku 4.5) have the most complete support in `us-west-2`. If you must use a different region, first confirm in that region's Bedrock console that all three models can be requested, then pass `--region <region>` when deploying.

### Q2: What if my Bedrock model request isn't approved?

Personal accounts are usually auto-approved. If approval is required, write a clear use case (e.g., "evaluating an internal AI Agent platform"). Enterprise accounts may be blocked by organization SCPs — in that case ask your master-account admin to allow Bedrock access.

### Q3: I don't have IAM permissions. How can my admin set things up in advance?

Forward the two tables in step 3 (deployer permissions) and step 4 (EC2 runtime permissions) to your admin — those are the complete minimum-permission lists. Once the admin creates things, they give you an Access Key and the Instance Profile name.

### Q4: I already have an AWS account with other workloads. Will Nexus-AI interfere?

No. Each Nexus-AI environment is isolated by `EnvironmentPrefix`. `deploy.sh` creates a brand-new VPC, prefixes DDB tables and SQS queues, and suffixes S3 bucket names — it won't touch your existing resources.

### Q5: When I tear down the environment, will my S3/DDB/SQS data be deleted?

Not by default. `nexus-cli deploy down` only removes CloudFormation-managed VPC/EC2/ALB/CloudFront resources. To delete data too, add `--clean-data`:

```bash
nexus-cli deploy down my-env --clean-data -y
```

### Q6: Why do I get AccessDenied when running `aws bedrock list-foundation-models`?

Usually one of two reasons:

1. Your current IAM identity has no Bedrock permissions — check step 3.
2. Your account has never opened the Bedrock console in any region — click `Bedrock → Model access` once in the console to activate the region.
