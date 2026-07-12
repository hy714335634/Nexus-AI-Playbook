---
title: Deployment & Upgrade
sync:
  source_commit: 7f4029536abf5945f2384f544555a3f6815c2519
  source_files:
    - config/deploy.yaml.template
    - docs/deployment/**
    - infrastructure/release/README.md
    - nexus-cli
  generated_at: 2026-07-12T12:22:31+00:00
  generated_by: docs-sync v2
---

# Deployment & Upgrade

This chapter is for the IT administrator who deploys Nexus-AI into their own AWS account and maintains it afterward. The whole deployment runs through the `nexus-cli` command-line tool: one command creates the full set of cloud resources, and later upgrades only touch the code on the compute node — your data is never affected.

## Overview

- **One-command deploy**: `nexus-cli deploy up` creates the full environment in your AWS account (networking, application node, database, cache, load balancer, CDN, and more), then prints the access URL and login details.
- **Config-driven**: all deployment parameters live in a single `deploy.yaml` for easy reuse and review; command-line flags can override it on the fly.
- **Data separate from compute**: the database, cache, and object storage all live outside the application node, so upgrading or rebuilding the node never touches your data.
- **Manageable services**: after deployment, use the `nexus-cli service` commands to check status, view logs, and restart individual services.

::: info
The **env-prefix** that follows `deploy up` — for example `nexus-ai-prod` — is the unique identifier for this environment. It determines the naming prefix of every resource, can only be set on the command line (never in the config file), and must be reused for every later status check, upgrade, and deletion.
:::

## Prerequisites

Prepare the following before you start:

| Item | Requirement |
|------|-------------|
| Deploy machine | A machine that can run `nexus-cli` (Amazon Linux 2023 recommended, t3.small/medium, 30GB disk), with outbound internet access |
| AWS credentials | Attach an IAM Role with deployment permissions to the deploy machine, or configure equivalent AWS credentials |
| Deployment permissions | The role must cover a set of permissions across CloudFormation, EC2, RDS, ElastiCache, EFS, load balancing, CloudFront, Lambda, SSM, S3, and IAM; use the IAM policy document shipped with the platform |
| Target region | Decide the deployment region (default `us-west-2`) and confirm its service quotas (EIP/VPC/NAT) are sufficient |
| Key Pair (optional) | If you need SSH access to a node for troubleshooting, create an EC2 Key Pair in the target region first and set its name in the config; leave it empty to skip key binding |
| Model access | In the Bedrock console of the **deployment region** → *Model access*, enable the models the platform needs (the Claude family). IAM cannot substitute for this step; new accounts must request it manually the first time |

::: warning Model access must be enabled manually first
If the first agent build or conversation after deployment returns `AccessDeniedException` (mentioning `aws-marketplace:ViewSubscriptions/Subscribe`), the target model is not yet enabled in your account. Request it on the *Model access* page of the Bedrock console in the deployment region, then retry. See **Model Catalog & Access** for details.
:::

## First-time Deployment

### Option 1: Deploy with a config file (recommended)

A config file is clearer when there are many parameters, and easier for a team to reuse and review.

1. Copy the template and edit it:

   ```bash
   cp config/deploy.yaml.template config/deploy.yaml
   # Edit config/deploy.yaml with your real values (passwords, region, instance type, etc.)
   ```

2. Create the environment with the config file (`env-prefix` still comes from the command line):

   ```bash
   nexus-cli deploy up nexus-ai-prod --config config/deploy.yaml
   ```

3. Command-line flags override matching keys in the config file and take priority:

   ```bash
   nexus-cli deploy up nexus-ai-staging \
     --config config/deploy.yaml \
     --branch release/v2.4 \
     --enable-sso
   ```

### Option 2: Quick deploy from the command line

With few parameters, set them directly on the command line:

```bash
# Simplest form (public repo, default parameters)
nexus-cli deploy up nexus-ai-test

# Private repo + custom login and database passwords
nexus-cli deploy up nexus-ai-demo \
  --github-token ghp_xxxxxxxxxxxx \
  --user admin --password MyPass123 \
  --db-password StrongDBPass!

# Specify branch and instance type
nexus-cli deploy up nexus-ai-dev \
  --branch develop \
  --instance-type m7i.xlarge \
  --github-token ghp_xxx

# CI/CD: skip the confirmation prompt
nexus-cli deploy up nexus-ai-ci -y --github-token ghp_xxx
```

Deployment takes about **15–25 minutes** (it creates the full set of cloud resources). When done, the command prints the CloudFront access URL and login details.

::: tip Chinese interface
Every command supports Chinese prompts — just add `--lang zh`:

```bash
nexus-cli --lang zh deploy up nexus-ai-test --github-token ghp_xxx
```
:::

## Deployment Configuration Items

The following are the configuration items supported by `deploy.yaml`. **These are deploy-time settings** — changes take effect only after you re-apply them through the upgrade flow.

**AWS infrastructure**

| Item | Purpose | Default |
|------|---------|---------|
| `region` | AWS region for all resources | `us-west-2` |
| `instance_type` | Application node EC2 instance type | `c8i.2xlarge` |
| `key_name` | SSH Key Pair name; empty means no key binding | empty |
| `iam_instance_profile` | IAM Instance Profile name bound to the application node | `admin-for-ec2` |
| `volume_size` | Application node root volume size (GB) | `150` |
| `vpc_cidr` | VPC CIDR block | `10.0.0.0/16` |

**Application**

| Item | Purpose | Default |
|------|---------|---------|
| `git_repo_url` | Code repository URL | official repo |
| `git_branch` | Branch to deploy | `main` |
| `github_token` | Access token for private repos (**sensitive**) | empty |

**Authentication (password mode)**

| Item | Purpose | Default |
|------|---------|---------|
| `auth_user` | Login username in password mode | `admin` |
| `auth_password` | Login password in password mode (**sensitive**) | — |

> When SSO is enabled, the password-mode credentials are still kept as a fallback config admin. See **Login & SSO** for SSO details.

**Database and cache**

| Item | Purpose | Default |
|------|---------|---------|
| `db_password` | Database password (**sensitive**) | — |
| `aurora_min_capacity` | Database minimum capacity (ACU; lower saves cost) | `0.5` |
| `aurora_max_capacity` | Database maximum capacity (ACU) | `16` |
| `valkey_max_data_gb` | Cache maximum data size (GB) | `5` |
| `valkey_max_ecpu` | Cache maximum compute (ECPU/sec) | `15000` |

**SSO (IAM Identity Center)**

| Item | Purpose | Default |
|------|---------|---------|
| `enable_sso` | Enable SSO login | `false` |
| `sso_group_name` | User group name in Identity Center | `{env-prefix}-users` |
| `allowed_email_domains` | Allowlist of email domains permitted to log in; empty = no restriction | empty |

**Sandbox runtime (optional)**

| Item | Purpose | Default |
|------|---------|---------|
| `enable_sandbox` | Deploy the sandbox runtime | `false` |
| `sandbox_instance_type` | Sandbox node instance type, **must support KVM** (8th-gen Intel `c8i/m8i/r8i` or `.metal`; not `d` variants like `c8id`) | `c8i.xlarge` |
| `sandbox_pool_size` | Number of sandbox nodes | `1` |

**Deployment behavior**

| Item | Purpose | Default |
|------|---------|---------|
| `no_wait` | Return immediately after submitting, without waiting for completion | `false` |

::: warning Sensitive configuration items
`github_token`, `auth_password`, and `db_password` are sensitive. Never commit a `deploy.yaml` filled with real values to a code repository or share it in plaintext; store it securely after deployment or use a secrets manager instead.
:::

## Enabling SSO Login

Enabling SSO at deploy time automatically creates a SAML application and user group in IAM Identity Center and pushes them to the environment:

```bash
# Enable SSO
nexus-cli deploy up nexus-ai-prod --github-token ghp_xxx --enable-sso

# Enable SSO and restrict login to specific email domains
nexus-cli deploy up nexus-ai-prod \
  --github-token ghp_xxx \
  --enable-sso \
  --allowed-email-domains amazon.com \
  --allowed-email-domains subsidiary.co
```

Enabling SSO requires IAM Identity Center to be turned on in your account and the deploy role to have the corresponding permissions. See **Login & SSO** for the full login configuration and user group assignment.

## Checking Deployment Status

Purpose: view the detailed status of an environment, or list every deployed environment in the account.

```bash
# Detailed status of a single environment (local record + live AWS status)
nexus-cli deploy status nexus-ai-prod

# List all environments
nexus-cli deploy list
```

After deployment, the platform also provides a **Service Status** page — check whether each service is running under "Service Status" in the sidebar.

<!-- SCREENSHOT: admin-service-status -->

## Service Management

Purpose: check and control the running state of the platform's services on the application node.

```bash
# Show the status of all services
nexus-cli service status

# View a service's logs
nexus-cli service logs --mcp

# Restart a service
nexus-cli service restart --mcp

# Stop / start a service
nexus-cli service stop --mcp
nexus-cli service start --mcp
```

::: tip
Run `nexus-cli service` commands on the application node. For routine checks you can also use the in-product **Service Status** page without logging in to the node. Starting/stopping the MCP service and managing its token are covered in **MCP Service Management**.
:::

### Companion: Ops Assistant

The in-product **Service Status** page comes with an **Ops Assistant**. After deployment, you don't have to remember commands for routine operations — just ask it.

- **Where to open it**: the "Service Status" page in the sidebar, via the assistant icon in the top-right corner.
- **What you can ask**: which service is unhealthy, the latest error logs, whether a service should be restarted.
- **What it returns**: service status as a table, plus a confirm-gated button when an action is needed.
- **Guardrails**: impactful actions such as restart and stop **always require a second confirmation** before they run.

See **Built-in AI Assistants (Admin)** and **Service Status Monitoring** for the Ops Assistant's full capabilities.

<!-- SCREENSHOT: ops -->

## Upgrading to a New Version

Purpose: update a deployed environment to a new version.

**An upgrade updates only the code and local config on the compute node — your data is not affected**, since the database, cache, and object storage all live outside the node. During an upgrade the platform automatically: backs up the current config → updates the code → merges the config (preserving runtime values such as database/cache connections) → reinstalls dependencies if needed → rebuilds the frontend → restarts the services.

For an environment deployed via **one-command delivery**, the maintainer issues a new update command; you paste and run it on the deploy machine, and never touch the code repository:

```bash
curl -fsSL "<update link provided by the maintainer>" | bash
```

::: warning Upgrade notes
- **The update link expires**: a few hours by default, 7 days at most; ask the maintainer to re-issue it if it has expired.
- **The target version must support the upgrade flow**: very old versions may lack the components the upgrade needs and must be redeployed instead.
- Files removed between versions are not cleaned up during an in-place update (usually harmless).
- An upgrade restarts the services and causes a brief interruption; run it during off-peak hours.
:::

## Deleting an Environment

Purpose: tear down environments you no longer use to stop incurring charges.

```bash
# Delete the cloud resource stack only, keeping data
nexus-cli deploy down nexus-ai-test

# Delete the stack and clean up all data (object storage / data tables / queues)
nexus-cli deploy down nexus-ai-test --clean-data

# Skip confirmation
nexus-cli deploy down nexus-ai-test --clean-data -y
```

::: warning --clean-data is irreversible
Adding `--clean-data` deletes your data along with the stack and **cannot be undone**. Confirm the environment's data is no longer needed, or has been backed up separately, before running it. Without `--clean-data`, data is kept and can be used to rebuild later.
:::

## FAQ

| Symptom | Where to look |
|---------|---------------|
| Deployment fails midway and leaves a half-built stack | Usually insufficient regional service quota (EIP/VPC/NAT) or missing permissions; fix those and re-run the same command (it resumes automatically without recreating the stack) |
| First build/conversation returns `AccessDeniedException` | Enable the required model access in the Bedrock console of the deployment region — see "Prerequisites" above |
| Can't find an environment's status | Confirm the env-prefix with `nexus-cli deploy list`, then check it with `deploy status &lt;prefix&gt;` |
| A service is unhealthy | Check with `nexus-cli service status` or the in-product "Service Status" page, and `service restart` if needed |

See **FAQ & Troubleshooting** for more.
