---
title: FAQ & Troubleshooting
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - CLAUDE.md
    - CONTRIBUTING.md
    - README.md
  generated_at: 2026-05-09T01:45:54+00:00
  generated_by: docs-sync v2
---

# FAQ & Troubleshooting

This chapter collects the most common questions across installation, configuration, runtime, deployment, Agent building, authentication, and MCP — along with resolution steps. Every entry comes from scripts, config, or docs already in the repository; anything not defined in the source is marked `—`.

## How to use this doc

- **By scenario**: questions are grouped by lifecycle stage (install → start → configure → run → deploy).
- **By ID**: each question has a unique ID (e.g., `Q-INSTALL-01`) for easy reference in Issues.
- **By symptom**: the final “symptom index” table maps error keywords to the relevant entry.

## Conventions

| Term | Meaning |
|------|---------|
| `&lt;repo&gt;` | Nexus-AI repository root |
| `nexus-cli` | The `./nexus-cli` script at the repo root |
| Core services | API (`:8000`) + Worker + Web (`:3000`) |
| Optional services | MCP Server (`:9000`), OTEL Collector, Jaeger |
| Main config | `config/default_config.yaml` |

---

## 1. Install & environment (Q-INSTALL)

### Q-INSTALL-01: What prerequisites are required?

| Component | Minimum version | Required | Notes |
|-----------|-----------------|----------|-------|
| Python | 3.13+ | Yes | Backend runtime |
| Node.js | 18+ | Yes | Frontend (`web/`) |
| AWS account | — | Yes | Must have Bedrock model access |
| AWS CLI | — | Yes | Run `aws configure` to set credentials |
| Git | — | Yes | Clone and contribute |

### Q-INSTALL-02: How do I bootstrap on Amazon Linux 2023?

Download and run the provided script:

```bash
curl -O https://raw.githubusercontent.com/hy714335634/Nexus-AI/main/setup_env_alinux2023.sh
chmod +x setup_env_alinux2023.sh
./setup_env_alinux2023.sh
```

### Q-INSTALL-03: What is the full manual install procedure?

```bash
# Clone
git clone https://github.com/hy714335634/Nexus-AI.git
cd Nexus-AI

# Create and activate a virtualenv
python3.13 -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt
pip install -e .

# Configure AWS credentials
aws configure

# Edit main config (S3 bucket name, etc.)
# vim config/default_config.yaml

# Frontend dependencies
cd web && npm install && cd ..
```

### Q-INSTALL-04: Why does the doc recommend `uv` instead of `pip`?

`CLAUDE.md` states `uv pip install -r requirements.txt` is preferred over `pip`. `uv` accelerates dependency resolution and download; it is not mandatory — `pip` also works.

### Q-INSTALL-05: What initialization must I run on first use?

```bash
./nexus-cli init
```

This creates the required DynamoDB tables, SQS queues, and S3 buckets. See the architecture overview.

### Q-INSTALL-06: Do I have to activate the virtualenv every time?

Yes. `CLAUDE.md` notes that `source .venv/bin/activate` must precede any Python execution. The `nexus-cli` script handles this internally, but direct calls like `python agents/...` require manual activation.

---

## 2. Service start & management (Q-SERVICE)

### Q-SERVICE-01: What services exist and on which ports?

| Service | Port | Flag | Required |
|---------|------|------|----------|
| Web frontend | 3000 | `--web` | Default-on |
| API backend | 8000 | `--api` | Default-on |
| Worker | — | `--worker` | Default-on |
| Bridge | 8001 | — (bundled) | Default-on |
| MCP Server | 9000 | `--mcp` | Optional |
| OTEL Collector | — | `--otel` | Optional |

### Q-SERVICE-02: What subcommands does `nexus-cli service` support?

| Command | Purpose |
|---------|---------|
| `./nexus-cli service start` | Start core services (API + Worker + Web) |
| `./nexus-cli service start --api` | Start API only |
| `./nexus-cli service start --worker` | Start Worker only |
| `./nexus-cli service start --web` | Start Web only |
| `./nexus-cli service start --mcp` | Start core services + MCP Server |
| `./nexus-cli service start --otel` | Start OTEL Collector |
| `./nexus-cli service start --dev` | Development mode |
| `./nexus-cli service stop` | Stop all services |
| `./nexus-cli service status` | Check status |
| `./nexus-cli service restart` | Restart all |
| `./nexus-cli service restart --mcp` | Restart MCP Server |
| `./nexus-cli service logs` | View all logs |
| `./nexus-cli service logs --api` | View API logs |
| `./nexus-cli service logs --mcp` | View MCP logs |
| `./nexus-cli service logs -f` | Follow logs in real time |

### Q-SERVICE-03: What are the service URLs?

| Service | URL |
|---------|-----|
| Web frontend | `http://localhost:3000` |
| API Swagger UI | `http://localhost:8000/docs` |
| MCP Server | `http://localhost:9000/mcp` |

### Q-SERVICE-04: How do I follow logs for a single service?

```bash
./nexus-cli service logs --api -f     # API only
./nexus-cli service logs --mcp        # Recent MCP logs
./nexus-cli service logs -f           # All services, live
```

### Q-SERVICE-05: Can I run only the Worker, without API/Web?

Yes:

```bash
./nexus-cli service start --worker
```

The Worker consumes SQS messages independently in a single-stage execution model (one message triggers one workflow stage, then routes to the next stage via SQS).

### Q-SERVICE-06: Port 3000 is already taken — what now?

`nexus-cli` does not currently expose a flag to change the Web port. Stop the conflicting process first, then restart:

```bash
./nexus-cli service stop
lsof -ti:3000 | xargs kill -9
./nexus-cli service start
```

> To change the port permanently, see the Next.js config under `web/`.

### Q-SERVICE-07: What are the common frontend npm scripts?

| Command | Purpose |
|---------|---------|
| `npm run dev` | Dev server (port 3000) |
| `npm run build` | Production build |
| `npm run lint` | ESLint |
| `npm run test` | Jest tests |
| `npm run test:watch` | Jest watch mode |

### Q-SERVICE-08: How do I invoke an Agent directly (bypassing Web/API)?

```bash
source .venv/bin/activate
python agents/system_agents/magician.py -i "your prompt here"
python agents/system_agents/agent_build_workflow/agent_build_workflow.py \
  -i "build description"
```

---

## 3. Configuration (Q-CONFIG)

### Q-CONFIG-01: Which config files exist, and what is their precedence?

| Config | Purpose | Precedence |
|--------|---------|------------|
| Environment variables | Overrides everything | Highest |
| `config/default_config.yaml` | Main config (model, SSO, multimodal, etc.) | Medium |
| `config/service_config.yaml` | Runtime params (workers, thread pools, timeouts) | Medium |
| Code defaults | Hardcoded defaults | Lowest |

### Q-CONFIG-02: How do I switch Bedrock models?

Edit `config/default_config.yaml`:

```yaml
bedrock:
  model_id: 'us.anthropic.claude-sonnet-4-5-20250929-v1:0'      # default
  lite_model_id: 'us.anthropic.claude-haiku-4-5-20251001-v1:0'   # lite
  pro_model_id: 'us.anthropic.claude-opus-4-5-20251101-v1:0'     # pro
```

### Q-CONFIG-03: How do I enable multimodal chat (images, Excel, Word, PDF)?

```yaml
nexus-ai:
  multimodal_parser:
    aws:
      s3_bucket: "your-file-storage-bucket"
      s3_prefix: "multimodal-content/"
      bedrock_region: "us-west-2"
```

### Q-CONFIG-04: How do I enable SSO?

```yaml
nexus-ai:
  auth:
    user: 'admin'
    password: 'nexus'
  sso:
    enabled: True
    idp_metadata_url: 'https://portal.sso.xxxxx/saml/metadata/xxxxx'
    sp_entity_id: 'nexus-ai-sp'
    sp_acs_url: 'https://your-domain/api/v2/auth/sso/acs'
    frontend_url: 'https://your-domain'
```

> SSO mode additionally requires the `python3-saml` package.

### Q-CONFIG-05: What are the default dev-mode credentials?

`admin` / `nexus` (under `nexus-ai.auth` in `config/default_config.yaml`). Active only when `sso.enabled: False` (the default).

### Q-CONFIG-06: Which environment variables are read?

Environment variables explicitly documented:

| Env var | Effect |
|---------|--------|
| `API_PORT` | Override the API port |
| `NEXUS_API_WORKERS` | Override the API worker count |
| `NEXUS_MCP_TOKEN` | Preset a fixed MCP Bearer Token |

> Other env vars follow the precedence rules in `nexus_utils/config_loader.py` and override keys from `default_config.yaml`; see `reference/environment-variables`.

### Q-CONFIG-07: Where are workflows defined, and which ones exist?

At `config/workflows.yaml`. Built-in workflows:

| Workflow | Version | Stages | Notes |
|----------|---------|--------|-------|
| `agent_build` | V2 | 8 | Fork/join for parallel Agent design |
| `agent_update` | V2 | 5 | Supports `skip_stages` |
| `tool_build` | V2 | 5 | Tool build |
| `skill_build` | V2 | 5 | Skill build |
| `magician` | — | 1 | Single-stage intent router |

---

## 4. Authentication & access (Q-AUTH)

### Q-AUTH-01: Which authentication modes are supported?

| Mode | How to enable | When to use |
|------|---------------|-------------|
| Username/password (JWT) | `sso.enabled: False` (default) | Development, self-test |
| SAML 2.0 SSO | `sso.enabled: True` | Production, IAM Identity Center |
| MCP Bearer Token | Generated when `--mcp` is started | IDE invoking Agents |

### Q-AUTH-02: Where do I find the MCP Bearer Token?

Three sources (any will work):

| Source | Location |
|--------|----------|
| Console output at startup | stdout of `./nexus-cli service start --mcp` |
| Local file | `.pids/mcp_token` |
| Preset env var | `NEXUS_MCP_TOKEN=&lt;your-token&gt;` |

### Q-AUTH-03: How do I configure an MCP client in an IDE?

```json
{
  "mcpServers": {
    "nexus-ai": {
      "url": "http://localhost:9000/mcp",
      "headers": {
        "Authorization": "Bearer <token generated at startup>"
      }
    }
  }
}
```

IDE-specific config paths:

| Config path | IDE |
|-------------|-----|
| `~/.kiro/settings/mcp.json` | Kiro |
| `.mcp.json` (project-level) | Claude Code |

---

## 5. Deployment (Q-DEPLOY)

### Q-DEPLOY-01: What subcommands does `nexus-cli deploy` provide?

| Command | Purpose |
|---------|---------|
| `nexus-cli deploy up &lt;env&gt;` | Create/update the CloudFormation environment |
| `nexus-cli deploy list` | List all deployed environments |
| `nexus-cli deploy status &lt;env&gt;` | Show the status of a specific environment |
| `nexus-cli deploy down &lt;env&gt; -y` | Delete the environment (keep data) |
| `nexus-cli deploy down &lt;env&gt; --clean-data -y` | Delete the environment and wipe S3/DDB/SQS data |

### Q-DEPLOY-02: What are the full deployment parameters?

| Parameter | Default | Required | Description |
|-----------|---------|----------|-------------|
| `ENV_PREFIX` | — | Yes | Environment prefix used to name all AWS resources |
| `--github-token` | — | Yes | GitHub Personal Access Token (code pull) |
| `--db-password` | — | Yes | Aurora PostgreSQL password |
| `--branch` | `main` | No | Git branch |
| `--instance-type` | `c8i.2xlarge` | No | EC2 instance type |
| `--key-name` | `Og_Normal` | No | SSH Key Pair name |
| `--iam-instance-profile` | `admin-for-ec2` | No | EC2 IAM Instance Profile |
| `--volume-size` | `150` | No | EC2 root volume size (GB) |
| `--vpc-cidr` | `10.0.0.0/16` | No | VPC CIDR block |
| `--region` | `us-west-2` | No | AWS region |
| `--user` | `admin` | No | Web login username |
| `--password` | `nexus` | No | Web login password |
| `--enable-sso` | off | No | Enable SAML 2.0 SSO |
| `--allowed-email-domains` | — | No | Allowed email domains for SSO |
| `--enable-sandbox` | off | No | Enable Sandbox runtime |
| `--sandbox-instance-type` | `c8i.xlarge` | No | Sandbox node instance type (must support KVM) |
| `--sandbox-pool-size` | `1` | No | Sandbox node count |
| `--sandbox-default-runtime` | `ec2` | No | Default runtime mode (`local` / `ec2`) |
| `--sandbox-runtimes` | `local,ec2` | No | Allowed runtime modes |
| `--sandbox-prewarm-vms` | `1` | No | Prewarmed VMs per node |
| `-y` | — | No | Skip confirmation prompts |

### Q-DEPLOY-03: What does a minimal deploy command look like?

```bash
nexus-cli deploy up my-env \
  --github-token ghp_xxxx \
  --db-password 'MySecurePass123!'
```

### Q-DEPLOY-04: How do I enable the Sandbox runtime?

```bash
nexus-cli deploy up my-env \
  --github-token ghp_xxxx \
  --db-password 'MySecurePass123!' \
  --enable-sandbox \
  --sandbox-instance-type c8i.xlarge \
  --sandbox-pool-size 2 \
  --sandbox-default-runtime ec2 \
  --sandbox-runtimes local,ec2 \
  --sandbox-prewarm-vms 3 \
  -y
```

Sandbox provides Firecracker microVM isolation per Agent session.

### Q-DEPLOY-05: What Sandbox management commands exist?

| Command | Purpose |
|---------|---------|
| `nexus-cli sandbox overview` | Overview of sandbox nodes, VMs, Agents |
| `nexus-cli sandbox list` | List VM instances |
| `nexus-cli sandbox nodes` | List compute nodes |
| `nexus-cli sandbox launch --count <N>` | Launch nodes manually |
| `nexus-cli sandbox terminate &lt;node-id&gt;` | Terminate a specific node |
| `nexus-cli sandbox rebuild-rootfs -y --restart-nodes` | Rebuild VM rootfs image (after deps change) |
| `nexus-cli sandbox logs --limit 20` | Recent scheduler logs |

### Q-DEPLOY-06: What AWS IAM permissions does the deployer need?

The IAM user/role running `deploy.sh` needs:

| Service | Permissions | Purpose |
|---------|-------------|---------|
| CloudFormation | `CreateStack`, `DeleteStack`, `DescribeStacks`, `DescribeStackEvents` | Stack management |
| EC2 | `RunInstances`, `TerminateInstances`, `CreateVpc`, `CreateSubnet`, `CreateSecurityGroup`, `CreateNatGateway`, `AllocateAddress`, `CreateRouteTable`, `CreateRoute`, `CreateTags`, `Describe*` | Create VPC and instances |
| IAM | `CreateRole`, `DeleteRole`, `AttachRolePolicy`, `DetachRolePolicy`, `CreateInstanceProfile`, `AddRoleToInstanceProfile`, `PassRole` | Instance roles |
| RDS | `CreateDBCluster`, `CreateDBInstance`, `CreateDBSubnetGroup`, `DeleteDB*`, `Describe*` | Aurora cluster |
| ElastiCache | `CreateServerlessCache`, `DeleteServerlessCache`, `Describe*` | Valkey cache |
| ELB | `CreateLoadBalancer`, `CreateTargetGroup`, `CreateListener`, `CreateRule`, `RegisterTargets`, `Delete*`, `Describe*` | ALB |
| CloudFront | `CreateDistribution`, `DeleteDistribution`, `Get*`, `Update*` | CDN |
| Lambda | `CreateFunction`, `DeleteFunction`, `GetFunction` | Custom resources |
| S3 | `ListAllMyBuckets`, `DeleteBucket`, `DeleteObject` (only with `--clean-data`) | Data cleanup |
| SQS | `ListQueues`, `DeleteQueue` (only with `--clean-data`) | Data cleanup |
| DynamoDB | `ListTables`, `DeleteTable` (only with `--clean-data`) | Data cleanup |
| SSM | `GetParameter` | AMI ID lookup |

### Q-DEPLOY-07: What IAM permissions does the running EC2 instance need?

| Service | Permissions | Purpose |
|---------|-------------|---------|
| Bedrock | `InvokeModel`, `InvokeModelWithResponseStream`, `ListFoundationModels` | Model inference |
| DynamoDB | `CreateTable`, `PutItem`, `GetItem`, `UpdateItem`, `DeleteItem`, `Query`, `Scan` | CRUD across 18 reserved tables |
| SQS | `CreateQueue`, `SendMessage`, `ReceiveMessage`, `DeleteMessage`, `ChangeMessageVisibility` | Task queues |
| S3 | `CreateBucket`, `GetObject`, `PutObject`, `DeleteObject`, `ListBucket`, `PutBucketCors` | File storage |
| S3 Vectors | `CreateVectorBucket`, `CreateIndex`, `PutObject`, `Query` | Vector search |
| RDS | `DescribeDBClusters` (Aurora uses direct TCP; no IAM Auth needed) | Connection metadata |
| CloudWatch Logs | `CreateLogGroup`, `CreateLogStream`, `PutLogEvents` | Logging |
| ECR | `GetAuthorizationToken`, `BatchGetImage`, `PutImage` (AgentCore deploys) | Container images |

### Q-DEPLOY-08: Does deleting an environment also delete data?

By default, **no**. `nexus-cli deploy down &lt;env&gt; -y` removes only the CloudFormation-managed resources; S3, DDB, SQS data is kept. Use `--clean-data` to wipe it.

---

## 6. AWS dependencies (Q-AWS)

### Q-AWS-01: Are all AWS services mandatory?

| Service | Purpose | Required |
|---------|---------|----------|
| AWS Bedrock | Model inference (Claude Sonnet/Opus/Haiku) | Yes |
| Aurora PostgreSQL Serverless v2 | Relational data (projects, Agents, sessions, messages — 12 tables) | Yes |
| ElastiCache Valkey Serverless | Cache (aggregate stats, hot data, stream event buffer) | Yes |
| DynamoDB | KV data (tools, config, event scheduling — 18 tables) | Yes |
| SQS | Async task queues (build, deploy) | Yes |
| S3 | Agent artifacts, session files, multimodal content | Yes |
| IAM Identity Center | SSO | Optional |

### Q-AWS-02: How do I apply for Bedrock access?

In the AWS console → Bedrock → “Model access”, request the Claude models you need. Nexus-AI defaults to `us.anthropic.claude-sonnet-4-5-20250929-v1:0`, `claude-haiku-4-5-20251001-v1:0`, and `claude-opus-4-5-20251101-v1:0`.

### Q-AWS-03: Which model providers does Agent Factory support?

Per `CLAUDE.md`, `agent_factory` supports:

- Bedrock
- OpenAI
- Anthropic
- LiteLLM
- Ollama
- Gemini

---

## 7. Agent build & runtime (Q-AGENT)

### Q-AGENT-01: What is the full Agent build pipeline?

```
User request → Requirements → Architecture → Agent design → Prompt eng. → Tool dev → Codegen → Test
                ↓              ↓              ↓              ↓            ↓          ↓         ↓
             Requirements   Architect    Agent designer  Prompt eng.  Tool dev   Coder    Tester
```

Eight specialized Agents collaborate, mirroring the 8 stages of the `agent_build` workflow.

### Q-AGENT-02: How does the Agent Build data flow work?

```
API receives the request
  → Writes an SQS message
  → Worker pulls and executes one stage
  → Saves the result to DDB
  → Routes to the next stage via SQS
  → Frontend polls the stages table for progress
```

### Q-AGENT-03: How does the Agent runtime (Chat) data flow work?

```
Frontend opens an SSE request
  → Sessions Router
  → AgentRuntimeService
  → S3SessionManager loads context
  → Strands agent.stream()
  → Events are parsed and pushed over SSE
  → Session is saved back to S3
```

### Q-AGENT-04: How do I trigger a full build from the CLI?

```bash
source .venv/bin/activate
python agents/system_agents/agent_build_workflow/agent_build_workflow.py \
  -i "Create an Agent that analyzes PDF documents and extracts key information"
```

Generated code is written to `agents/generated_agents/`.

### Q-AGENT-05: What built-in Agent examples ship with the platform?

| Category | Agent | Function |
|----------|-------|----------|
| AWS | `aws_pricing_agent` | AWS pricing queries and sizing recommendations |
| AWS | `aws_architecture_diagram_generator` | Generate AWS architecture diagrams from natural language |
| AWS | `aws_network_topology_analyzer` | Network topology analysis, visualization, compliance checks |
| Docs | `html_courseware_generator` | Interactive HTML courseware (math, chemistry) |
| Docs | `html2pptx` | HTML → PPT preserving styles |
| Docs | `pdf_content_extractor` | PDF content extraction with multimodal support |
| Docs | `ppt_to_markdown` | PPT → Markdown preserving hierarchy |
| Analysis | `stock_analysis_agent` | Stock analysis and investment reports (DCF) |
| Analysis | `company_info_search_agent` | Company info search, batch-friendly |
| Content | `logo_design_agent` | Logo design with imagery and written rationale |
| Medical | `medical_document_translation_agent` | Medical document translation with domain glossary |
| Medical | `openfda_data_agent` | FDA data queries (drugs, devices, food) |
| Medical | `drug_feedback_collector` | Drug feedback collection, sentiment & topic analysis |
| Medical | `clinicaltrials_search_agent` | Clinical trial data search |
| Medical | `pubmed_literature_agent` | PubMed literature search and analysis |
| Platform | `Nexus-AI-QA-Assistant` | Project knowledge-base Q&A (FastAPI-ready) |

### Q-AGENT-06: What’s a good first call to verify installation?

```bash
source .venv/bin/activate
python agents/system_agents/magician.py \
  -i "What is the price of an m8g.xlarge instance in AWS us-east-1?"
```

---

## 8. MCP protocol (Q-MCP)

### Q-MCP-01: What are the two MCP roles Nexus-AI plays?

| Role | Description |
|------|-------------|
| MCP Server | Auto-registers every `status=running` Agent as an MCP Tool, exposing them to Kiro/Claude Code/Cursor |
| MCP Client | Agents call external tools over MCP (e.g., the bundled AWS MCP server) |

### Q-MCP-02: Why does the MCP Server bypass the API?

The MCP Server directly calls `agent_factory.create_agent_from_prompt_template()` to instantiate a Strands Agent, skipping the API layer to reduce latency. Identity is verified via Bearer Token.

### Q-MCP-03: Where do I configure external MCP servers that Agents call?

| Config file | Purpose |
|-------------|---------|
| `config/mcp/system_mcp_server.json` | System-preconfigured MCP servers (e.g., AWS) |
| `config/mcp/public_mcp_server.json` | User-defined MCP servers |

---

## 9. Observability (Q-OBS)

### Q-OBS-01: How do I enable distributed tracing?

```bash
docker run -d --name jaeger \
  -p 16686:16686 -p 4317:4317 -p 4318:4318 \
  jaegertracing/all-in-one:latest
```

Jaeger UI: `http://localhost:16686`.

### Q-OBS-02: Is OpenTelemetry already wired into the API?

Yes. The API backend ships with OpenTelemetry instrumentation; start Jaeger and traces appear immediately.

### Q-OBS-03: How do I start the OTEL Collector?

```bash
./nexus-cli service start --otel
```

---

## 10. Contributing (Q-CONTRIB)

### Q-CONTRIB-01: What is the branch naming convention?

| Type | Description | Example |
|------|-------------|---------|
| `feature` | New feature | `feature/add-pricing-agent` |
| `fix` | Bug fix | `fix/login-error` |
| `hotfix` | Urgent fix | `hotfix/critical-bug` |
| `docs` | Docs update | `docs/update-readme` |
| `refactor` | Refactor | `refactor/agent-factory` |
| `test` | Tests | `test/add-unit-tests` |
| `chore` | Build/tooling | `chore/update-deps` |

### Q-CONTRIB-02: Where do branches get merged?

Into `main`. The project follows a simplified GitHub Flow: branches are created from `main` and merged back into `main`:

| Branch | Purpose | Merge target |
|--------|---------|--------------|
| `main` | Main branch | - |
| `feature/*` | Feature work | main |
| `fix/*` | Bug fixes | main |
| `hotfix/*` | Urgent fixes | main |

### Q-CONTRIB-03: What commit message convention is used?

[Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

| Type | Meaning |
|------|---------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Docs |
| `style` | Formatting (no functional impact) |
| `refactor` | Refactor |
| `perf` | Performance |
| `test` | Tests |
| `chore` | Build/tooling/deps |

The subject must be English, start with an imperative verb, be lowercase, omit the trailing period, and stay under 50 characters.

### Q-CONTRIB-04: What hard rules apply to code conventions?

From `CLAUDE.md`:

| Area | Rule |
|------|------|
| Backend code, variables, comments | English |
| UI strings | i18n (Chinese/English must stay in sync) |
| Prompt templates | YAML under `prompts/` with structured schema (`agent.versions[].system_prompt`) |
| Tool definitions | Use the Strands `@tool` decorator; stored in S3 and synced to DDB |
| API layers | `api/v2/routers/` (HTTP) → `api/v2/services/` (business) → `api/v2/database/` (persistence) |
| Auth | Dev mode `admin/nexus`; production SAML 2.0 SSO |

### Q-CONTRIB-05: What is the recommended merge-conflict workflow?

```bash
# Sync with main
git fetch origin main
git rebase origin/main

# Resolve conflicts, then
git add .
git rebase --continue

# Force-push (required after rebase)
git push --force-with-lease
```

### Q-CONTRIB-06: What Git emergency commands are worth knowing?

| Need | Command |
|------|---------|
| Undo the last commit, keep changes | `git reset --soft HEAD~1` |
| Amend the last commit message | `git commit --amend -m "new commit message"` |
| Stash current changes | `git stash` |
| Restore stash | `git stash pop` |
| View last 10 commits | `git log --oneline -10` |

---

## 11. Symptom index

Reverse-lookup from error keywords to the relevant FAQ entry.

| Symptom | Likely cause | See |
|---------|--------------|-----|
| `ModuleNotFoundError` | virtualenv not activated | Q-INSTALL-06 |
| `aws: command not found` | AWS CLI not installed | Q-INSTALL-01 |
| `Could not connect to DynamoDB` | `./nexus-cli init` not run | Q-INSTALL-05 |
| Port 3000 in use | another process holds it | Q-SERVICE-06 |
| SSO login fails, missing `python3-saml` | SAML dependency not installed | Q-CONFIG-04 |
| MCP client returns 401 Unauthorized | Wrong Bearer Token | Q-AUTH-02 |
| MCP client cannot reach `:9000` | Not started with `--mcp` | Q-SERVICE-02 |
| Bedrock `AccessDenied` | Model access not requested | Q-AWS-02 |
| Default Web credentials rejected | Config changed | Q-CONFIG-05 |
| CloudFormation create fails | IAM permissions incomplete | Q-DEPLOY-06 |
| Bedrock calls fail after deploy | EC2 role permissions incomplete | Q-DEPLOY-07 |
| Build workflow stuck mid-stage | SQS message not consumed / Worker not running | Q-SERVICE-05, Q-AGENT-02 |
| Cannot find generated Agent | Did not check `agents/generated_agents/` | Q-AGENT-04 |

---

## 12. Doc index

Additional official docs:

| Doc | Path |
|-----|------|
| Complete install guide | `docs/NEXUS_AI_SYSTEM_GUIDE.md` |
| API usage examples | `docs/API_USAGE_EXAMPLES.md` |
| Agent build template | `docs/VIBE_CODING_AGENT_BUILD_TEMPLATE.md` |
| MCP Server setup | `docs/MCP_SERVER_SETUP.md` |
| IAM Policy JSON samples | `docs/infrastructure/IAM_POLICIES.md` |
