---
title: Quickstart
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - README.md
    - agents/system_agents/magician.py
    - nexus-cli
  generated_at: 2026-05-08T14:27:06+00:00
  generated_by: docs-sync v2
---

# Quickstart

## What this is

The shortest path from nothing to a running Nexus-AI. After completing the steps below, you will have a local web console and a default Agent you can talk to in natural language.

## When to use this

| Who you are | When this guide fits |
|-------------|----------------------|
| First-time Nexus-AI user | You want to see it working before deciding where to dig deeper |
| PoC / technical evaluator | You need a demo-able local environment to validate "build Agents with natural language" |
| Developer about to build an Agent | You want dependencies, services, and credentials all in place before your first build |
| Pre-deployment verifier | You want a local dry run before deploying to the cloud |

## How to use it

### Step 1: Check prerequisites

Before you start, confirm your machine meets the following:

| Component | Requirement |
|-----------|-------------|
| Python | 3.13 or later |
| Node.js | 18 or later (for the web frontend) |
| AWS account | Bedrock access enabled |
| AWS CLI | Credentials already configured via `aws configure` |

::: tip
On Amazon Linux 2023 you can use the one-click setup script:

```bash
curl -O https://raw.githubusercontent.com/hy714335634/Nexus-AI/main/setup_env_alinux2023.sh
chmod +x setup_env_alinux2023.sh
./setup_env_alinux2023.sh
```
:::

### Step 2: Clone the repo and install dependencies

```bash
git clone https://github.com/hy714335634/Nexus-AI.git
cd Nexus-AI

python3.13 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
pip install -e .
```

### Step 3: Configure AWS credentials

```bash
aws configure
```

If you need to change the default S3 bucket, AWS region, or model ID, edit `config/default_config.yaml`. The defaults are fine for a first run.

### Step 4: Initialize the infrastructure

On the first run you must create the DynamoDB tables, SQS queues, and S3 buckets:

```bash
./nexus-cli init
```

<!-- SCREENSHOT: cli-init-output -->

### Step 5: Start the core services

Start the API, Worker, and Web services:

```bash
./nexus-cli service start
```

If you also want to expose platform Agents to IDEs like Kiro, Claude Code, or Cursor, add `--mcp`:

```bash
./nexus-cli service start --mcp
```

Use these commands to check status or tail logs:

```bash
./nexus-cli service status
./nexus-cli service logs -f
```

### Step 6: Open the web console

Open `http://localhost:3000` in your browser and log in with the default account:

- Username: `admin`
- Password: `nexus`

<!-- SCREENSHOT: login-page -->

You will land on the Agent list, with entry points for chat and for building new Agents.

### Step 7: Verify a conversation from the command line

In a new terminal, confirm the default Agent can answer questions:

```bash
source .venv/bin/activate
python agents/system_agents/magician.py -i "What is the price of an m8g.xlarge instance in AWS us-east-1?"
```

If you get a normal answer back, the full chain (AWS credentials → Bedrock model → Agent) is working.

::: tip Interactive mode
Running the same script with no arguments drops you into a multi-turn interactive mode:

```bash
python agents/system_agents/magician.py
```

Type `quit` or `exit` to leave.
:::

## Key parameters / limits

| Item | Value / notes |
|------|---------------|
| Web frontend URL | `http://localhost:3000` |
| API docs URL | `http://localhost:8000/docs` (Swagger UI) |
| MCP Server URL | `http://localhost:9000/mcp` (requires `--mcp` at start) |
| Default web account | `admin` / `nexus` (change under `auth` in `config/default_config.yaml`) |
| Python version | Must be 3.13+ |
| AWS Bedrock | Claude-family model access required |
| Default model | Claude Sonnet 4.5 (switch via `bedrock.model_id`) |

## FAQ

### Q1: `./nexus-cli init` fails with an AWS permission error — what should I check?

Run `aws sts get-caller-identity` first to confirm the credentials from `aws configure` are active. Then confirm the account/role can create DynamoDB tables, SQS queues, and S3 buckets. The project README's "Deployer IAM permissions" section lists the minimum set.

### Q2: The web console will not load, or I hit port conflicts.

Run `./nexus-cli service status` to see which services actually started, and `./nexus-cli service logs --api` for the error message. Ports 3000, 8000, and 9000 must be free — stop whatever is holding them, or change the ports and restart.

### Q3: The verification command returns `AccessDeniedException`.

That is a Bedrock-side permission issue. Go to AWS Console → Bedrock → Model access and request access to Claude Sonnet / Haiku / Opus. Re-run the command once access is approved.

### Q4: I want to skip the web console and play with Agents from the command line.

`agents/system_agents/magician.py` exists for exactly this case. No arguments puts you into default-Agent interactive mode; `-a &lt;agent_path&gt;` picks an existing Agent; `-i "&lt;question&gt;"` sends a one-shot query.

### Q5: How do I change the default login password?

Edit `nexus-ai.auth.user` and `nexus-ai.auth.password` in `config/default_config.yaml`, then run `./nexus-cli service restart`. For production, switch to SSO mode instead (see the Configuration doc).
