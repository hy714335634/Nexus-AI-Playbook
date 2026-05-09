---
title: Contributing
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - .python-version
    - CLAUDE.md
    - CONTRIBUTING.md
    - pyproject.toml
  generated_at: 2026-05-08T23:48:10+00:00
  generated_by: docs-sync v2
---

# Contributing

## Overview

This document is the **working handbook for Nexus-AI code contributors**. Its sole sources of truth are `CONTRIBUTING.md`, `CLAUDE.md`, `pyproject.toml`, and `.python-version` in the source repo. It covers: what to install locally, the branch / commit / PR workflow, code conventions, and how Python and dependency versions are pinned.

Scope: only what's needed to **contribute code to the `hy714335634/Nexus-AI` repository**. Architectural details and runtime behavior belong in subsystem-specific docs (API, Worker, Agent Factory, etc.).

Main entry points:

- Contribution workflow overview → `CONTRIBUTING.md`
- Claude Code / IDE collaboration conventions → `CLAUDE.md`
- Python version and dependency manifest → `.python-version`, `pyproject.toml`

---

## File Layout

| Path | Responsibility | Dependencies |
|------|----------------|--------------|
| `CONTRIBUTING.md` | Contribution workflow: environment setup, branching, commit conventions, PR process | None (human-readable) |
| `CLAUDE.md` | IDE / Claude Code collaboration guide; project overview, service catalog, code conventions, AWS dependencies | None |
| `pyproject.toml` | Package metadata, Python constraint, runtime dependencies, build backend, wheel targets | `hatchling` build |
| `.python-version` | Local Python version pin (read by pyenv / `uv`) | None |

---

## Python and Runtime Constraints

### `.python-version`

```
3.13
```

Local development uses Python **3.13** (pyenv / `uv` will pick this up automatically).

### `pyproject.toml` top-level metadata

| Field | Value | Notes |
|-------|-------|-------|
| `[project].name` | `nexus-ai` | Distribution name |
| `[project].version` | `0.1.0` | Current version |
| `[project].description` | `Nexus-AI: Enterprise-grade AI agent development platform` | Summary |
| `[project].readme` | `README.md` | Distribution README |
| `[project].requires-python` | `>=3.12` | Minimum runtime Python; `.python-version` further pins to 3.13 |
| `[build-system].requires` | `["hatchling"]` | Build dependency |
| `[build-system].build-backend` | `hatchling.build` | Build backend |
| `[tool.hatch.build.targets.wheel].packages` | `["agents", "nexus_utils", "tools", "prompts", "config"]` | Top-level directories shipped in the wheel |

::: warning
`requires-python = ">=3.12"` (pyproject) and `.python-version = 3.13` are not in conflict: the former is the **minimum compatible version**, the latter is the **recommended development version**. Validate your PR on 3.13.
:::

### Runtime dependencies (exhaustive, from `[project].dependencies`)

Grouped by purpose; every entry below appears verbatim in `pyproject.toml`.

**Agent runtime / LLM integration:**

| Dependency | Version constraint |
|------------|--------------------|
| `strands-agents[otel]` | unpinned (extras: `otel`) |
| `strands-agents-tools` | unpinned |
| `bedrock-agentcore` | unpinned |
| `bedrock-agentcore-starter-toolkit` | `>=0.3.7` |
| `boto3` | unpinned |
| `botocore` | `>=1.42.16` |
| `langchain-aws` | `>=1.3.0` |

**Web / API framework:**

| Dependency | Version constraint |
|------------|--------------------|
| `fastapi` | `>=0.136.1` |
| `uvicorn[standard]` | `>=0.40.0` |
| `python-multipart` | `>=0.0.21` |
| `httpx` | `>=0.28.1` |
| `aiofiles` | `>=25.1.0` |
| `fastmcp` | `>=3.1.0` |

**Persistence / cache / queue:**

| Dependency | Version constraint |
|------------|--------------------|
| `redis` | `>=7.4.0` |
| `celery` | `>=5.6.3` |
| `psycopg[binary,pool]` | `>=3.3.4` |
| `pgvector` | `>=0.3.6` |

**Configuration / validation / security:**

| Dependency | Version constraint |
|------------|--------------------|
| `pydantic` | `>=2.12.5` |
| `pydantic-settings` | `>=2.12.0` |
| `python-dotenv` | `>=1.2.1` |
| `python-jose[cryptography]` | `>=3.5.0` |
| `python3-saml` | `>=1.16.0` |
| `jsonschema` | `>=4.25.1` |
| `json-repair` | `>=0.59.5` |

**Document parsing / office files:**

| Dependency | Version constraint |
|------------|--------------------|
| `pandas` | `>=3.0.2` |
| `openpyxl` | `>=3.1.5` |
| `python-docx` | `>=1.2.0` |
| `python-pptx` | `>=1.0.2` |
| `pypdf2` | `>=3.0.1` |
| `pdfplumber` | `>=0.11.9` |
| `pymupdf` | `>=1.27.2.3` |
| `pillow` | `>=11.3.0` |
| `markdown` | `>=3.10.2` |
| `html2text` | `>=2025.4.15` |
| `beautifulsoup4` | `>=4.14.3` |
| `chardet` | `>=7.4.3` |
| `xmltodict` | `>=1.0.4` |

**HTTP / scraping / search:**

| Dependency | Version constraint |
|------------|--------------------|
| `requests` | `>=2.32.5` |
| `duckduckgo-search` | `>=8.1.1` |
| `browser-use` | `>=0.11.13` |
| `feedparser` | unpinned |

**Visualization / graphs:**

| Dependency | Version constraint |
|------------|--------------------|
| `matplotlib` | `>=3.10.9` |
| `plotly` | `>=6.7.0` |
| `graphviz` | `>=0.21` |
| `networkx` | `>=3.6.1` |
| `tabulate` | `>=0.10.0` |

**NLP / utilities:**

| Dependency | Version constraint |
|------------|--------------------|
| `nltk` | `>=3.9.4` |
| `pyyaml` | unpinned |
| `croniter` | `>=6.2.2` |
| `colorama` | unpinned |
| `rich` | `>=13.0` |
| `setuptools` | `>=82.0.1` |

**OpenTelemetry observability:**

| Dependency | Version constraint |
|------------|--------------------|
| `opentelemetry-api` | `>=1.39.1` |
| `opentelemetry-sdk` | `>=1.39.1` |
| `opentelemetry-exporter-otlp-proto-http` | `>=1.39.1` |
| `opentelemetry-instrumentation-fastapi` | `>=0.60b1` |
| `opentelemetry-instrumentation-botocore` | `>=0.60b1` |
| `opentelemetry-instrumentation-logging` | `>=0.60b1` |
| `opentelemetry-instrumentation-threading` | `>=0.60b1` |
| `opentelemetry-propagator-aws-xray` | `>=1.0.2` |

::: tip
Prefer `uv pip install` over plain `pip` when updating dependencies (see the "Development Setup" section of `CLAUDE.md`).
:::

---

## Environment Setup

### 1. Install Git

```bash
# macOS
brew install git

# Ubuntu/Debian
sudo apt-get install git

# Verify
git --version
```

### 2. Configure Git identity

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### 3. Configure SSH key (recommended)

```bash
# Generate SSH key
ssh-keygen -t ed25519 -C "your.email@example.com"

# Add to ssh-agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Copy public key and add it to GitHub
cat ~/.ssh/id_ed25519.pub
```

### 4. Clone the repo

```bash
# SSH (recommended)
git clone git@github.com:hy714335634/Nexus-AI.git

# Or HTTPS
git clone https://github.com/hy714335634/Nexus-AI.git

cd Nexus-AI
```

### 5. Python and dependencies

```bash
# Create virtualenv (.venv is the project convention)
python -m venv .venv

# Activate
source .venv/bin/activate

# Install uv (recommended package manager)
pip install uv

# Install dependencies
uv pip install -r requirements.txt
```

### 6. Frontend and infrastructure

```bash
# Frontend deps
cd web && npm install && cd -

# Initialize AWS infrastructure (DynamoDB tables, SQS queues, S3 buckets)
./nexus-cli init
```

### 7. AWS credentials (required)

The runtime hard-depends on AWS services; you must configure credentials up front:

```bash
aws configure
```

| AWS service | Purpose |
|-------------|---------|
| Bedrock | Claude model inference (Sonnet / Opus / Haiku) |
| DynamoDB | All persistent data |
| SQS | Async task queues (build / deploy / notification) |
| S3 | Artifacts, session storage, attachments, skills |

---

## Branching Strategy

The project follows a **simplified GitHub Flow**. Every branch is **cut from `main` and eventually merged back into `main`**.

### Branch types

| Branch | Purpose | Merges into |
|--------|---------|-------------|
| `main` | Trunk | — |
| `feature/*` | New features | `main` |
| `fix/*` | Bug fixes | `main` |
| `hotfix/*` | Urgent patches | `main` |

### Branch flow

```
main ────●────────●────────●────────●────────
         │        ↑        ↑        ↑
         │        │        │        │
feature  └────●───┘        │        │
                           │        │
fix                   ●────┘        │
                                    │
hotfix                         ●────┘
```

### Naming convention: `&lt;type&gt;/&lt;description&gt;`

| Type | Description | Example |
|------|-------------|---------|
| `feature` | New feature | `feature/add-pricing-agent` |
| `fix` | Bug fix | `fix/login-error` |
| `hotfix` | Urgent fix | `hotfix/critical-bug` |
| `docs` | Docs update | `docs/update-readme` |
| `refactor` | Refactor | `refactor/agent-factory` |
| `test` | Tests | `test/add-unit-tests` |
| `chore` | Build / tooling | `chore/update-deps` |

### Standard branching steps

```bash
# 1. Sync main
git checkout main
git pull origin main

# 2. Cut a new branch from main
git checkout -b feature/your-feature-name
```

---

## Development Workflow

### Working loop

1. Make changes on the new branch
2. `git status` to review
3. `git add` (prefer `git add -p` to review hunks)
4. `git commit` with a conventional message
5. `git push` to the same-named remote branch
6. Open a PR on GitHub, assign a reviewer
7. Merge once approved

### Staging and committing

```bash
# Status
git status

# Add
git add path/to/file.py        # single file
git add .                      # all changes
git add -p                     # interactive, hunk by hunk (recommended)

# Commit
git commit -m "feat: add new pricing calculation feature"
```

### Pushing

```bash
# First push of a new branch (establish upstream)
git push -u origin feature/your-feature-name

# Subsequent pushes
git push
```

### Resolving conflicts

```bash
# Fetch latest main and rebase
git fetch origin main
git rebase origin/main

# After resolving conflicts
git add .
git rebase --continue

# Use --force-with-lease (safer than --force) after a rebase
git push --force-with-lease
```

::: warning
**Do not `git push --force` to shared branches or `main`** — you risk overwriting other people's work. Always use `--force-with-lease` after a rebase.
:::

---

## Commit Message Convention

Follows [Conventional Commits](https://www.conventionalcommits.org/).

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types (exhaustive)

| Type | Description |
|------|-------------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Docs update |
| `style` | Formatting (no behavior change) |
| `refactor` | Refactor |
| `perf` | Performance |
| `test` | Tests |
| `chore` | Build / tooling / deps |

### Subject rules

- English, imperative verb
- Lowercase initial, no trailing period
- 50 characters max

### Examples

```bash
# Simple
git commit -m "feat: add AWS pricing calculation tool"

# With scope
git commit -m "fix(agent): resolve memory leak in agent factory"

# With body and footer
git commit -m "feat(api): add batch processing endpoint

- Add new /api/v2/batch endpoint
- Support up to 100 items per request
- Add rate limiting for batch requests

Closes #123"
```

---

## Opening a Pull Request

1. Open the repository page
2. Click **Pull requests** → **New pull request**
3. Select your branch → `main`
4. Fill in the PR title (follow the commit-message convention) and description
5. Assign a reviewer
6. Merge once approved

---

## Code Conventions (from `CLAUDE.md`)

### General rules

- **Backend code, variable names, and comments are English only**; UI strings support i18n (Chinese / English, must stay in sync).
- **Prompt templates** live in `prompts/` as YAML with a structured schema: `agent.versions[].system_prompt`.
- **Tools** use the Strands `@tool` decorator, stored in S3 and synced to DynamoDB.
- **API layering** is strict: `api/v2/routers/` (HTTP) → `api/v2/services/` (business logic) → `api/v2/database/` (persistence).
- **Configuration priority**: environment variables > `config/default_config.yaml` > code defaults. Runtime parameters (worker count, thread pools, timeouts) live in `config/service_config.yaml`.
- **Authentication**: dev mode uses `admin/nexus` credentials; production uses SAML 2.0 SSO.

### Notable environment variables (examples)

| Variable | Description |
|----------|-------------|
| `API_PORT` | API listening port (default 8000) |
| `NEXUS_API_WORKERS` | API worker process count |

---

## Service Architecture Cheat Sheet (Contributor View)

### 5 core services + 2 optional

| # | Service | Entry point | Notes |
|---|---------|-------------|-------|
| 1 | API Backend | `api/v2/main.py` | FastAPI + Uvicorn; 30+ routers, 28+ services; JWT auth, SSE streaming, OpenTelemetry |
| 2 | Worker | `worker/main.py` | SQS consumer; single-stage execution (one message → one workflow stage → next stage via SQS) |
| 3 | Web Frontend | `web/` | Next.js 14 App Router + React 18 + TypeScript + Tailwind CSS; TanStack Query; i18n |
| 4 | Gateway | `nexus_utils/gateway/__main__.py` | Stream proxy with reconnection; WebSocket support, Valkey buffer |
| 5 | Bridge | `nexus_utils/bridge/` | Remote server connection manager (SSH-like operations) |
| 6 (optional) | MCP Server | `nexus_utils/mcp/mcp_server/__main__.py` | FastMCP 3.x; exposes agents as MCP tools (Kiro / Claude Code / Cursor); calls agent_factory directly, bypassing the API |
| 7 (optional) | Event Scheduler | `nexus_utils/event_scheduler/` | Cron-like scheduled task execution |

### Default ports

| Service | Port |
|---------|------|
| Web | 3000 |
| API | 8000 |
| Bridge | 8001 |
| MCP | 9000 |

### Key subsystems

| Subsystem | Entry point | Highlights |
|-----------|-------------|------------|
| Workflow Engine | `nexus_utils/workflow/engine_v2.py` | SQS-driven single-stage execution; fork/join for parallel stages; input assembled from prerequisite stage results in DDB; JSON validation + retry |
| Agent Factory | `nexus_utils/agent_factory.py` | `create_agent_from_prompt_template()` builds agents from YAML; multi-provider: Bedrock, OpenAI, Anthropic, LiteLLM, Ollama, Gemini; stage logs in `logs/stages/` |
| Database Layer | `api/v2/database/dynamodb.py` | Singleton DynamoDB client with connection pooling; exponential-backoff retry on throttling; 28+ tables (projects / agents / sessions / messages / stages / tools / skills, etc.) |
| Configuration | `nexus_utils/config_loader.py` | env vars > `default_config.yaml` > code defaults; runtime parameters in `service_config.yaml` |

### Workflow definitions (`config/workflows.yaml`)

| Name | Version | Stage count | Notes |
|------|---------|-------------|-------|
| `agent_build` | V2 | 8 | Fork/join for parallel agent design |
| `agent_update` | V2 | 5 | Supports `skip_stages` |
| `tool_build` | V2 | 5 | — |
| `skill_build` | V2 | 5 | — |
| `magician` | — | 1 | Single-stage intent router |

### Data flow patterns

- **Agent Build**: API receives request → SQS message → Worker executes stage → writes DDB → routes next stage via SQS → frontend polls the stages table
- **Agent Runtime (Chat)**: frontend SSE request → Sessions Router → AgentRuntimeService → S3SessionManager loads context → Strands `agent.stream()` → events parsed and sent via SSE → session persisted to S3
- **MCP**: IDE MCP client → MCP Server (Bearer Token auth) → `agent_factory.create_agent_from_prompt_template()` → Bedrock → response

---

## Command Cheat Sheet

### Service management (`./nexus-cli`)

```bash
./nexus-cli service start              # Start all services (API + Worker + Web)
./nexus-cli service start --api        # API only
./nexus-cli service start --worker     # Worker only
./nexus-cli service start --web        # Web only
./nexus-cli service start --mcp        # All + MCP Server
./nexus-cli service start --otel       # Start OTEL Collector
./nexus-cli service start --dev        # Development mode
./nexus-cli service stop               # Stop all
./nexus-cli service status             # Status
./nexus-cli service logs --api         # View API logs
./nexus-cli service logs -f            # Follow all logs
./nexus-cli service restart            # Restart all
```

### Frontend

```bash
cd web
npm run dev          # Dev server (port 3000)
npm run build        # Production build
npm run lint         # ESLint
npm run test         # Jest tests
npm run test:watch   # Jest watch mode
```

### Direct agent invocation (for testing)

```bash
source .venv/bin/activate
python agents/system_agents/magician.py -i "your prompt here"
python agents/system_agents/agent_build_workflow/agent_build_workflow.py -i "build description"
```

---

## Common Git Operations

```bash
# Undo the last commit (keep changes)
git reset --soft HEAD~1

# Amend the last commit message
git commit --amend -m "new commit message"

# Stash current changes
git stash
git stash pop  # restore

# View commit history
git log --oneline -10
```

---

## Troubleshooting

| Symptom | Likely cause | Remedy |
|---------|--------------|--------|
| `python --version` is not 3.13 | Local version manager hasn't switched to the version in `.python-version` | Install pyenv/uv and let it switch in the project dir |
| `uv pip install` fails | `uv` not installed | `pip install uv` |
| AWS calls raise `NoCredentialsError` | AWS credentials not configured | Run `aws configure` |
| `./nexus-cli init` fails | IAM permissions / wrong region | Check IAM policy and the `AWS_REGION` env var |
| Push rejected (non-fast-forward) | Remote has been advanced by someone else | `git fetch` + `git rebase origin/main`, then `--force-with-lease` |
| Line-level PR comments misalign after `rebase` | Force-push rewrote history | Mention in the PR description, or switch to a merge-commit flow |
| Frontend reports port 3000 in use | Another process is holding the port | `./nexus-cli service stop` or `lsof -i:3000` to clean up |

---

## Further Reading

- `CONTRIBUTING.md` (repo root) — canonical contribution workflow
- `CLAUDE.md` (repo root) — Claude Code / IDE collaboration guide, architecture overview
- `pyproject.toml` — dependency manifest and build config
- `config/workflows.yaml` — workflow definitions
- `config/default_config.yaml` / `config/service_config.yaml` — runtime configuration
- [Conventional Commits spec](https://www.conventionalcommits.org/)
