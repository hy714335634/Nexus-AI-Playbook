---
title: Learning Path
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - CLAUDE.md
    - README.md
  generated_at: 2026-05-08T14:34:11+00:00
  generated_by: docs-sync v2
---

# Learning Path

## What Is This

This guide gives you a suggested order for learning Nexus-AI: prepare your environment, build your first agent, then opt into IDE integration, SSO, and cloud deployment. Work through it step by step so you don't have to face every feature at once.

## When to Use It

| Your role | Suggested path |
|-----------|----------------|
| First-time user | Install locally → verify → build a sample agent |
| IDE integrator | Install locally → start MCP → configure Kiro / Claude Code / Cursor |
| DevOps / deployer | Skip to cloud deploy → enable SSO / Sandbox |
| Bringing an existing agent | Install locally → import via Web Console → publish |

## How to Use

### Step 1: Prepare your environment

Check the prerequisites:

- Python 3.13+, Node.js 18+
- An AWS account with Bedrock access enabled
- `aws configure` already run locally

### Step 2: Install and initialize

```bash
git clone https://github.com/hy714335634/Nexus-AI.git
cd Nexus-AI
python3.13 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
pip install -e .
./nexus-cli init
```

`./nexus-cli init` creates the DynamoDB tables, SQS queues, and S3 buckets you need.

<!-- SCREENSHOT: install-complete -->

### Step 3: Start services

```bash
./nexus-cli service start
```

This brings up the API, Worker, and Web services together. Open `http://localhost:3000` and sign in to the Web Console with the defaults `admin` / `nexus`.

<!-- SCREENSHOT: web-login -->

### Step 4: Verify the install

Run a built-in agent to confirm the full chain works:

```bash
source .venv/bin/activate
python agents/system_agents/magician.py -i "What is the price of an m8g.xlarge instance in us-east-1?"
```

### Step 5: Build your first agent

Describe what you want in plain language — the platform handles requirements analysis, architecture design, and code generation:

```bash
python agents/system_agents/agent_build_workflow/agent_build_workflow.py \
  -i "Create an agent that analyzes PDF documents and extracts key information"
```

The generated agent code lands under `agents/generated_agents/`.

<!-- SCREENSHOT: first-agent-built -->

### Step 6: Enable extensions as you need them

| Capability | How to enable | Who it's for |
|------------|---------------|--------------|
| MCP Server (IDEs call agents directly) | `./nexus-cli service start --mcp` | Kiro / Claude Code / Cursor users |
| SSO (SAML 2.0) | Set `sso.enabled: True` in `config/default_config.yaml` | Teams |
| Distributed tracing | Start a Jaeger container manually | Tuning / debugging |
| Sandbox runtime | Add `--enable-sandbox` to `nexus-cli deploy` | Multi-tenant isolation |

### Step 7: Deploy to the cloud

With AWS permissions in place, one command brings up a complete environment (VPC + EC2 + Aurora + Valkey + ALB + CloudFront):

```bash
nexus-cli deploy up my-env \
  --github-token ghp_xxxx \
  --db-password 'MySecurePass123!'
```

## Key Parameters / Limits

| Item | Requirement |
|------|-------------|
| Minimum Python | 3.13 |
| Minimum Node.js | 18 |
| Required AWS services | Bedrock, Aurora PostgreSQL, Valkey, DynamoDB, SQS, S3 |
| Web port | 3000 |
| API port | 8000 |
| MCP Server port | 9000 (optional, requires `--mcp`) |
| Default credentials | `admin` / `nexus` (development mode only) |

## FAQ

**Q: Do I need to finish every step to use Nexus-AI?**
A: No. Steps 1–5 are enough to build and run agents locally. Steps 6–7 are optional.

**Q: Can I skip local install and go straight to cloud deployment?**
A: Yes. For operations-only use, `nexus-cli deploy up` provisions a complete environment in one shot — no local install required.

**Q: I'm not a developer — can I still build agents?**
A: Yes. The core workflow is natural-language description; the platform writes the code for you. You don't need to write Python.

**Q: How does my team switch from the default account to SSO?**
A: Set `sso.enabled: True` in `config/default_config.yaml`, then configure the IdP metadata URL, SP entity ID, and ACS URL. SSO mode requires the extra `python3-saml` dependency.

**Q: Where do I find generated agents?**
A: From the CLI, under `agents/generated_agents/`. In the Web Console, they appear directly in the Agent list after sign-in.
