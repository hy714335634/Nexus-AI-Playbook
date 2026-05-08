---
title: Installation
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - README.md
    - pyproject.toml
    - requirements.txt
    - setup_env_alinux2023.sh
  generated_at: 2026-05-08T14:28:42+00:00
  generated_by: docs-sync v2
---

# Installation

## What this is

Nexus-AI runs on a local machine or EC2 host as a Python virtual environment plus a Node.js frontend (and optional Docker). This page covers two install paths: the **one-click Amazon Linux 2023 script** (recommended — installs system packages, Python 3.13, uv, the repo, and frontend dependencies in minutes) and **cross-platform manual install** (for macOS, other Linux distros, or environments where you already have Python).

## When to use each path

| Scenario | Recommended path |
|----------|------------------|
| Setting up a fresh AL2023 EC2 for dev or demo | One-click script `setup_env_alinux2023.sh` |
| Trying Nexus-AI locally on macOS, Ubuntu, or other Linux | Manual install |
| You already have Python 3.13 and just want to plug the code in | Manual install |
| Deploy the full stack to AWS (VPC + EC2 + Aurora + Valkey + ALB + CloudFront) | Use `nexus-cli deploy` (see the "Cloud Deployment" doc, out of scope here) |

## How to install

### Prerequisites

| Component | Requirement |
|-----------|-------------|
| Python | 3.13+ |
| Node.js | 18+ (needed to build the web frontend) |
| AWS account | Bedrock access enabled (Claude model family) |
| AWS CLI | Installed; configure it later with `aws configure` |
| OS (one-click script) | Amazon Linux 2023 only |
| Run-as user | Non-root (the AL2023 script enforces `ec2-user`) |

<!-- SCREENSHOT: installation-prerequisites -->

### Path A: Amazon Linux 2023 one-click script

The script runs the full chain: system packages → Python 3.13 → Node.js → Docker → LibreOffice (for PPT/DOCX/XLSX → PDF template previews) → uv package manager → `git clone` → virtual environment → Python and frontend dependencies → auto-activation of the venv via `~/.bashrc`.

1. Log in as `ec2-user` (do not use root).
2. Download and run the script:

   ```bash
   curl -O https://raw.githubusercontent.com/hy714335634/Nexus-AI/main/setup_env_alinux2023.sh
   chmod +x setup_env_alinux2023.sh
   ./setup_env_alinux2023.sh
   ```

3. Answer the prompts as they appear — e.g. `Pull latest code?` (if the project directory already exists) or `Git repository URL` (on first clone).
4. After the script finishes, log out and log back in once, or run `newgrp docker`, so that the new Docker group membership takes effect.
5. Run the initial configuration:

   ```bash
   aws configure                     # Configure AWS credentials
   ./nexus-cli init                  # Initialize DynamoDB, SQS, S3
   ./nexus-cli service start         # Start API + Worker + Web
   ./nexus-cli service start --mcp   # Optional: also start MCP Server
   ```

<!-- SCREENSHOT: installation-setup-script-success -->

::: tip Default project directory
The one-click script clones into `/home/ec2-user/Nexus-AI` and appends `cd` + `source .venv/bin/activate` to `~/.bashrc`. After the next login you will land in the project directory with the venv already active.
:::

### Path B: Manual install

1. Make sure Python 3.13+ and Node.js 18+ are available.
2. Clone the repo:

   ```bash
   git clone https://github.com/hy714335634/Nexus-AI.git
   cd Nexus-AI
   ```

3. Create and activate a virtual environment:

   ```bash
   python3.13 -m venv .venv
   source .venv/bin/activate
   ```

4. Install Python dependencies:

   ```bash
   pip install -r requirements.txt
   pip install -e .
   ```

5. Install frontend dependencies (only needed if you plan to use the web console):

   ```bash
   cd web && npm install && cd ..
   ```

6. Configure AWS credentials and edit `config/default_config.yaml` as needed (S3 bucket name, model IDs, SSO, etc.):

   ```bash
   aws configure
   ```

7. Initialize infrastructure and start services:

   ```bash
   ./nexus-cli init
   ./nexus-cli service start
   ```

<!-- SCREENSHOT: installation-manual-venv -->

### Verify the install

Once services are running, open each endpoint to confirm the three tiers are up:

| Endpoint | URL |
|----------|-----|
| Web frontend | `http://localhost:3000` |
| API docs (Swagger UI) | `http://localhost:8000/docs` |
| MCP Server (only when started with `--mcp`) | `http://localhost:9000/mcp` |

You can also run a built-in agent as a smoke test:

```bash
source .venv/bin/activate
python agents/system_agents/magician.py -i "What is the price of an m8g.xlarge instance in AWS us-east-1?"
```

## Key parameters and limits

| Item | Notes |
|------|-------|
| OS (one-click script) | Amazon Linux 2023 only; the script checks `/etc/os-release` and aborts on anything else |
| Run-as user | The script refuses to run as root; use `ec2-user` or another non-root user |
| Python version | Must be ≥ 3.13 (`pyproject.toml` requires `python >=3.12`; the script installs 3.13) |
| Node.js | 18+, used to build the web frontend |
| Docker | The one-click script installs and starts Docker (used for optional containers such as Jaeger); with manual install you install it yourself on demand |
| LibreOffice | Installed only by the one-click script (pulled from the documentfoundation RPM archive) for template preview PPTX/DOCX/XLSX → PDF conversion; if the download fails the script keeps going, but template thumbnails/PDF will be unavailable |
| AWS region | Use a region where Bedrock is enabled for your account (for example `us-west-2` or `us-east-1`) |
| Default project dir | The one-click script hard-codes `/home/ec2-user/Nexus-AI`; manual install can use any path |
| Disk space | Plan for at least 20 GB free — LibreOffice, Node modules, Python deps and Docker images add up fast |

## FAQ

**Q1: The script says "this script only supports Amazon Linux 2023" — what now?**
The one-click script strictly enforces the distro. On Ubuntu, Debian, CentOS, macOS, etc., follow "Path B: Manual install" instead.

**Q2: `uv` command not found after the script finishes.**
The script appends `$HOME/.local/bin` to `~/.bashrc`, but the change doesn't apply to the current shell. Log out and back in, or run `export PATH="$HOME/.local/bin:$PATH"`, then re-run `uv --version`.

**Q3: What breaks if LibreOffice fails to download?**
You get a warning and the script continues. The only impact is the "template preview" path that converts PPTX/DOCX/XLSX to PDF to generate thumbnails — Agent building, chat, MCP and the rest of the platform work normally. You can reinstall LibreOffice later.

**Q4: Why is running the script as root not allowed?**
The script writes a `cd` and venv activation line into `~/.bashrc` and runs `sudo usermod -aG docker $USER`. As root those changes land in `/root/.bashrc` and the Docker group grant has no meaning. Use `ec2-user`.

**Q5: What's next after the install finishes?**
Run `aws configure` → `./nexus-cli init` → `./nexus-cli service start`, in that order. Add `--mcp` if you want to expose the platform's Agents to IDEs such as Kiro, Claude Code or Cursor. Full usage details live in the "Quickstart" page.
