# Playbook Docs-Sync v3 — Hermes-Style Restructure + Getting Started Batch

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restructure Playbook into a Hermes-style 6-category sidebar (persistent, always-visible), fold existing `/using/*.md` into `/using/` with HUMAN-EDIT preservation, then full-generate the **Getting Started** category (5 pages, zh+en = 10 files) as Batch 1 out of 4 planned batches.

**Architecture:** Re-use v2's full-generate pipeline (`resolve.sh` + `full_generate.sh` + `index_gen.sh` + `sidebar_gen.sh`) unchanged. Swap `config.yaml`'s `chapters:` block to the 6-category structure. Preview kept as `/preview/` scratch. Migrate `/using/*.md` to `/using/` via git mv + inject `HUMAN-EDIT-START/END` markers so subsequent regenerations respect them. Build sidebar in `config.mts` as a single persistent tree spanning all 6 categories (not per-route switching).

**Tech Stack:** VitePress 1.6, bash scripts already built in v1/v2, Claude Code CLI, `jq`, Python 3.

**Reference spec:** `docs/superpowers/specs/2026-05-07-playbook-docs-sync-v2-design.md` (v3 reuses all v2 infrastructure; no spec rewrite needed).

**Working directory:** `/home/ubuntu/mydev/Nexus-AI-Playbook`

**Important constraints:**
- v1 and v2 commits (`ca15f43..da1abb4`) stay. No deletions of prior infra.
- `docs/superpowers/**` excluded from VitePress build (already configured).
- Current state: preview pages exist at `docs/preview/*` — keep as throwaway until v3 lands, then delete.
- v2's infra (config schema, `--full --chapter`, sidebar_gen, llms_txt) all works. This plan only changes **content org** and does **1 of 4** batches.
- **`/preview/` cleanup** is part of Task 9 before marking v3 landing.

---

## Batch strategy (4 batches total; this plan ships Batch 1)

| Batch | Scope | Tasks in this plan | Status |
|-------|-------|---------------------|--------|
| **Restructure** | 6-category skeleton + sidebar rework + manual migration | **T1–T9** | shipped by this plan |
| **Batch 1 — Getting Started** | 5 pages: quickstart, installation, aws-setup, updating, learning-path | **T10–T12** | shipped by this plan |
| Batch 2 — Using + Features-Core | ~12 pages | separate plan (next) | deferred |
| Batch 3 — Features-rest + Integrations | ~13 pages | separate plan | deferred |
| Batch 4 — Developer + Reference + Guides | ~20 pages | separate plan | deferred |

---

## Final sidebar structure (locked)

```
🚀 Getting Started
  ├─ Quickstart
  ├─ Installation
  ├─ AWS 环境准备
  ├─ Updating
  └─ Learning Path

📖 Using Nexus-AI              ← folded in from /using/
  ├─ Dashboard (from manual/dashboard.md)
  ├─ Creating an Agent (manual/create-agent.md)
  ├─ Build Progress (manual/build-progress.md)
  ├─ Chat & Sessions (manual/chat.md)
  ├─ Project Management (manual/projects.md)
  ├─ Managing Agents (manual/manage-agents.md)
  └─ Multimodal Uploads (new from manual/chat.md section)

⚡ Features
  ├─ Core
  │   ├─ Tools & Toolsets
  │   ├─ Skills System
  │   ├─ Agent Factory
  │   └─ Prompt Templates
  ├─ Runtime
  │   ├─ Sandbox
  │   ├─ Workflow Engine
  │   ├─ Multi-Agent Graph/Swarm
  │   └─ Stream Relay (Valkey)
  ├─ Automation
  │   ├─ Event Scheduler
  │   └─ Bridge (multi-connection)
  └─ Observability
      ├─ OpenTelemetry
      ├─ Metrics & Billing
      └─ Logging

🔌 Integrations
  ├─ Overview
  ├─ AWS Bedrock
  ├─ MCP Clients
  ├─ MCP Server
  ├─ SSO (SAML 2.0)
  └─ Data Stores

📚 Guides & Tutorials
  ├─ Tips & Best Practices
  ├─ 构建 Hermes 分析 Agent (tutorial)
  ├─ 构建技术博客生成 Agent (tutorial)
  └─ Use MCP with Nexus-AI

👨‍💻 Developer Guide
  ├─ Contributing
  ├─ Architecture
  │   ├─ Architecture Overview
  │   ├─ API Layer
  │   ├─ Worker
  │   └─ Stage Engine
  ├─ Extending
  │   ├─ Adding Agents
  │   ├─ Adding Tools
  │   └─ Adding Skills
  └─ Internals
      ├─ Session Storage
      └─ Dynamic Prompt Build

📋 Reference
  ├─ nexus-cli Commands
  ├─ Configuration Options
  ├─ Environment Variables
  ├─ API Endpoints
  ├─ Deploy Parameters
  ├─ IAM Policies
  ├─ Model Catalog
  ├─ Glossary
  └─ FAQ & Troubleshooting
```

`/overview/` and `/admin/` become leaf pages moved into `/using/` and `/reference/` respectively (T6).

---

## File Structure

### Created by this plan
```
scripts/
├── config.yaml                     # MODIFIED: chapters block rewritten
└── lib/
    └── migrate_human_edit.py       # NEW: inject HUMAN-EDIT markers into legacy manual/*.md

docs/
├── using/                          # NEW directory: /using/* moves here (git mv)
│   ├── index.md                    # NEW: chapter landing
│   ├── dashboard.md                # MOVED from manual/dashboard.md + HUMAN-EDIT block
│   ├── create-agent.md             # MOVED
│   ├── build-progress.md           # MOVED
│   ├── chat.md                     # MOVED
│   ├── projects.md                 # MOVED
│   ├── manage-agents.md            # MOVED
│   ├── tools.md                    # MOVED from manual/tools.md
│   ├── mcp.md                      # MOVED from manual/mcp.md
│   └── en/.gitkeep                 # NEW: English mirror placeholder
├── getting-started/                # NEW (generated by Batch 1)
│   ├── quickstart.md
│   ├── installation.md
│   ├── aws-setup.md
│   ├── updating.md
│   ├── learning-path.md
│   ├── index.md
│   └── en/                         # 6 files zh+en
├── features/                       # directory placeholder only (Batch 2–3)
├── integrations/                   # placeholder
├── guides/                         # placeholder (new; replaces v2's tutorials/)
├── developer/                      # placeholder
├── reference/                      # placeholder
└── .vitepress/
    └── config.mts                  # MODIFIED: sidebar rebuilt persistent, nav simplified

docs/superpowers/plans/
└── 2026-05-08-playbook-docs-sync-v3.md    # THIS FILE
```

### Deleted by this plan
```
docs/preview/                       # scratch preview, remove at T9
docs/tutorials/*                    # v2 had this name; v3 renames to /guides/ (rename, not hard delete)
```

### Unchanged
- `/guide/` (existing onboarding flow, 3 pages) — deliberately NOT merged into `/getting-started/`. It's kept as an introductory funnel; `/getting-started/` is the Hermes-style anchored reference. This plan leaves `/guide/` alone; Batch 4 will consolidate.
- `/admin/`, `/faq.md`, `/overview/` — deferred to Batch 4.
- `scripts/lib/*.sh`, `scripts/prompts/*.md` from v1/v2 — all reusable.

---

## Task 1: Rewrite `scripts/config.yaml` chapters block

**Files:**
- Modify: `scripts/config.yaml`

Locked task decisions:
- 6 top categories (renaming `tutorials` → `guides`, adding `getting-started` and `using`, removing standalone `glossary`)
- Features/Developer use 2-level sub-grouping via doc ordering (flat `docs` list; VitePress sidebar expresses grouping)
- `/using/` docs derive `sources:` from the actual moved files so signatures anchor on the current content; regeneration respects HUMAN-EDIT

- [ ] **Step 1: Read current config to confirm v2 structure**

Run: `grep -n "^chapters:" scripts/config.yaml && grep -c "^    docs:" scripts/config.yaml`

Expected: shows `chapters:` line and `docs:` count ≥ 1 (confirms v2 block present).

- [ ] **Step 2: Replace the entire `chapters:` block**

Use Edit to replace from the `chapters:` line through the `run:` line. Old block spans roughly 150 lines. The new block:

```yaml
# 章节定义（v3：Hermes 风格 6-category 侧栏结构）
# 每个章节声明输出目录、默认 prompt、本章节包含的文档清单。
# docs 内的顺序即 sidebar 顺序。
chapters:
  getting-started:
    title_zh: "快速开始"
    title_en: "Getting Started"
    output_dir: "getting-started"
    prompt_default: "feature-overview.md"
    docs:
      - slug: "quickstart"
        title_zh: "5 分钟快速上手"
        title_en: "Quickstart"
        sources:
          - "agents/system_agents/magician.py"
          - "nexus-cli"
          - "README.md"
      - slug: "installation"
        title_zh: "安装 Nexus-AI"
        title_en: "Installation"
        sources:
          - "setup_env_alinux2023.sh"
          - "pyproject.toml"
          - "requirements.txt"
          - "README.md"
      - slug: "aws-setup"
        title_zh: "AWS 环境准备"
        title_en: "AWS Setup"
        sources:
          - "infrastructure/**"
          - "config/default_config.yaml"
          - "README.md"
      - slug: "updating"
        title_zh: "升级与卸载"
        title_en: "Updating & Uninstalling"
        sources:
          - "nexus-cli"
          - "pyproject.toml"
          - "README.md"
      - slug: "learning-path"
        title_zh: "学习路径"
        title_en: "Learning Path"
        sources:
          - "README.md"
          - "CLAUDE.md"

  using:
    title_zh: "使用 Nexus-AI"
    title_en: "Using Nexus-AI"
    output_dir: "using"
    prompt_default: "feature-update.md"   # 使用 v1 的 update prompt 因为这些文档已存在
    docs:
      - slug: "dashboard"
        title_zh: "工作台"
        title_en: "Dashboard"
        sources: ["web/src/app/(authed)/dashboard/**", "api/v2/routers/projects.py"]
      - slug: "create-agent"
        title_zh: "创建 Agent"
        title_en: "Creating an Agent"
        sources: ["web/src/app/(authed)/create/**", "api/v2/routers/agents.py"]
      - slug: "build-progress"
        title_zh: "构建进度"
        title_en: "Build Progress"
        sources: ["web/src/app/(authed)/projects/**", "worker/handlers/build_handler*.py"]
      - slug: "chat"
        title_zh: "对话"
        title_en: "Chat & Sessions"
        sources: ["web/src/app/(authed)/chat/**", "api/v2/routers/sessions.py", "nexus_utils/magician.py"]
      - slug: "projects"
        title_zh: "项目管理"
        title_en: "Project Management"
        sources: ["api/v2/routers/projects.py", "web/src/app/(authed)/projects/**"]
      - slug: "manage-agents"
        title_zh: "Agent 管理"
        title_en: "Managing Agents"
        sources: ["api/v2/routers/agents.py", "web/src/app/(authed)/agents/**"]
      - slug: "tools"
        title_zh: "工具库"
        title_en: "Tools"
        sources: ["api/v2/routers/agent_tools.py", "nexus_utils/skill/**"]
      - slug: "mcp"
        title_zh: "MCP 服务器"
        title_en: "MCP Server"
        sources: ["nexus_utils/mcp/**", "config/mcp/**"]

  features:
    title_zh: "功能特性"
    title_en: "Features"
    output_dir: "features"
    prompt_default: "feature-overview.md"
    docs:
      # Core
      - slug: "tools-toolsets"
        title_zh: "工具与工具集"
        title_en: "Tools & Toolsets"
        sources: ["nexus_utils/skill/**", "agents/template_agents/**"]
      - slug: "skills-system"
        title_zh: "技能系统"
        title_en: "Skills System"
        sources: ["nexus_utils/skill/**"]
      - slug: "agent-factory"
        title_zh: "Agent Factory"
        title_en: "Agent Factory"
        sources: ["nexus_utils/agent_factory.py", "nexus_utils/safe_agent_factory.py"]
      - slug: "prompt-templates"
        title_zh: "提示词模板"
        title_en: "Prompt Templates"
        sources: ["prompts/template_prompts/**", "nexus_utils/prompts_manager.py"]
      # Runtime
      - slug: "sandbox"
        title_zh: "Sandbox 沙箱"
        title_en: "Sandbox Runtime"
        sources: ["nexus_utils/sandbox/**"]
      - slug: "workflow-engine"
        title_zh: "工作流引擎"
        title_en: "Workflow Engine"
        sources: ["nexus_utils/workflow/**", "config/workflows.yaml"]
      - slug: "multi-agent"
        title_zh: "多 Agent 图/群"
        title_en: "Multi-Agent Graph/Swarm"
        sources: ["nexus_utils/agent_graph/**", "agents/system_agents/**"]
      - slug: "stream-relay"
        title_zh: "流式响应中继"
        title_en: "Stream Relay"
        sources: ["nexus_utils/runtime_workspace/**", "api/v2/routers/sessions.py"]
      # Automation
      - slug: "event-scheduler"
        title_zh: "事件调度"
        title_en: "Event Scheduler"
        sources: ["nexus_utils/event_scheduler/**", "config/eventschedule_config.yaml"]
      - slug: "bridge"
        title_zh: "Bridge 多连接"
        title_en: "Bridge Multi-Connection"
        sources: ["nexus_utils/bridge/**"]
      # Observability
      - slug: "observability"
        title_zh: "可观测性"
        title_en: "Observability"
        sources: ["nexus_utils/observability/**"]
      - slug: "metrics-billing"
        title_zh: "指标与计费"
        title_en: "Metrics & Billing"
        sources: ["nexus_utils/observability/**", "api/v2/routers/admin_billing.py"]
      - slug: "logging"
        title_zh: "日志"
        title_en: "Logging"
        sources: ["config/logging_config.yaml", "nexus_utils/observability/**"]

  integrations:
    title_zh: "集成"
    title_en: "Integrations"
    output_dir: "integrations"
    prompt_default: "integration-guide.md"
    docs:
      - slug: "overview"
        title_zh: "集成总览"
        title_en: "Overview"
        sources: ["config/default_config.yaml", "README.md"]
      - slug: "aws-bedrock"
        title_zh: "AWS Bedrock 模型接入"
        title_en: "AWS Bedrock"
        sources: ["nexus_utils/agent_factory.py", "config/model_catalog.yaml"]
      - slug: "mcp-clients"
        title_zh: "外部 MCP 服务器"
        title_en: "MCP Clients"
        sources: ["nexus_utils/mcp/mcp_client/**", "config/mcp/**"]
      - slug: "mcp-server"
        title_zh: "Agent as MCP Tool"
        title_en: "MCP Server"
        sources: ["nexus_utils/mcp/mcp_server/**"]
      - slug: "sso-saml"
        title_zh: "SSO (SAML 2.0)"
        title_en: "SSO (SAML 2.0)"
        sources: ["api/v2/auth/**"]
      - slug: "data-stores"
        title_zh: "数据存储"
        title_en: "Data Stores"
        sources: ["api/v2/database/**", "config/default_config.yaml"]

  guides:
    title_zh: "使用指南"
    title_en: "Guides & Tutorials"
    output_dir: "guides"
    prompt_default: "tutorial.md"
    docs:
      - slug: "tips"
        title_zh: "技巧与最佳实践"
        title_en: "Tips & Best Practices"
        sources: ["CLAUDE.md", "README.md"]
      - slug: "build-hermes-analyst"
        title_zh: "构建 Hermes 分析 Agent"
        title_en: "Build a Hermes Analyst Agent"
        sources:
          - "agents/generated_agents/hermes_analyst_agent_2026a96a/**"
          - "prompts/generated_agents_prompts/hermes_analyst_agent_2026a96a/**"
      - slug: "build-tech-blog"
        title_zh: "构建技术博客生成 Agent"
        title_en: "Build a Tech Blog Generator"
        sources:
          - "agents/generated_agents/tech_blog_generator_05b957e9/**"
          - "prompts/generated_agents_prompts/tech_blog_generator_05b957e9/**"
      - slug: "use-mcp-with-nexus"
        title_zh: "在 Nexus-AI 中使用 MCP"
        title_en: "Use MCP with Nexus-AI"
        sources: ["nexus_utils/mcp/**", "config/mcp/**", "README.md"]

  developer:
    title_zh: "开发者指南"
    title_en: "Developer Guide"
    output_dir: "developer"
    prompt_default: "developer-guide.md"
    docs:
      - slug: "contributing"
        title_zh: "贡献指南"
        title_en: "Contributing"
        sources: ["CONTRIBUTING.md"]
      # Architecture
      - slug: "architecture-overview"
        title_zh: "架构总览"
        title_en: "Architecture Overview"
        sources: ["CLAUDE.md", "README.md", "architecture/**"]
      - slug: "api-layer"
        title_zh: "API 层架构"
        title_en: "API Layer"
        sources: ["api/v2/main.py", "api/v2/routers/**"]
      - slug: "worker"
        title_zh: "Worker 架构"
        title_en: "Worker"
        sources: ["worker/**"]
      - slug: "stage-engine"
        title_zh: "Stage 引擎"
        title_en: "Stage Engine"
        sources: ["nexus_utils/workflow/**"]
      # Extending
      - slug: "adding-agents"
        title_zh: "添加 Agent"
        title_en: "Adding Agents"
        sources: ["agents/template_agents/**", "nexus_utils/agent_factory.py"]
      - slug: "adding-tools"
        title_zh: "添加工具"
        title_en: "Adding Tools"
        sources: ["nexus_utils/skill/**", "tools/**"]
      - slug: "adding-skills"
        title_zh: "添加技能"
        title_en: "Adding Skills"
        sources: ["nexus_utils/skill/**", "prompts/template_prompts/**"]
      # Internals
      - slug: "session-storage"
        title_zh: "会话存储"
        title_en: "Session Storage"
        sources: ["nexus_utils/runtime_workspace/**", "api/v2/routers/sessions.py"]
      - slug: "dynamic-prompt"
        title_zh: "动态 Prompt 构建"
        title_en: "Dynamic Prompt Build"
        sources: ["nexus_utils/prompts_manager.py", "prompts/dynamic_agents_prompts/**"]

  reference:
    title_zh: "参考"
    title_en: "Reference"
    output_dir: "reference"
    prompt_default: "reference.md"
    docs:
      - slug: "cli-commands"
        title_zh: "nexus-cli 命令"
        title_en: "nexus-cli Commands"
        sources: ["nexus-cli", "nexus_utils/cli/**"]
      - slug: "config-options"
        title_zh: "配置项"
        title_en: "Configuration Options"
        sources: ["config/default_config.yaml", "config/logging_config.yaml"]
      - slug: "environment-variables"
        title_zh: "环境变量"
        title_en: "Environment Variables"
        sources: ["nexus_utils/config_loader.py", "nexus-cli"]
      - slug: "api-endpoints"
        title_zh: "API 端点"
        title_en: "API Endpoints"
        sources: ["api/v2/main.py", "api/v2/routers/**"]
      - slug: "deploy-params"
        title_zh: "部署参数"
        title_en: "Deployment Parameters"
        sources: ["infrastructure/**", "nexus-cli"]
      - slug: "iam-policies"
        title_zh: "IAM 权限"
        title_en: "IAM Policies"
        sources: ["docs/infrastructure/IAM_POLICIES.md", "infrastructure/**"]
      - slug: "model-catalog"
        title_zh: "模型目录"
        title_en: "Model Catalog"
        sources: ["config/model_catalog.yaml"]
      - slug: "glossary"
        title_zh: "术语表"
        title_en: "Glossary"
        sources: ["CLAUDE.md", "README.md", "nexus_utils/**"]
      - slug: "faq"
        title_zh: "FAQ 与故障排查"
        title_en: "FAQ & Troubleshooting"
        sources: ["CLAUDE.md", "README.md"]
```

Use Edit with the complete old block (read first via grep to know exact boundaries) replaced by the block above.

- [ ] **Step 3: Validate YAML + chapter count**

Run:
```bash
python3 -c "import yaml; d=yaml.safe_load(open('scripts/config.yaml')); print('chapters:', list(d['chapters'].keys())); print(sum(len(c['docs']) for c in d['chapters'].values()), 'docs total')"
```

Expected output: `chapters: ['getting-started', 'using', 'features', 'integrations', 'guides', 'developer', 'reference']` and `55 docs total`.

Note: that's 7 top-level keys, but `using/` plays dual role (new sidebar category housing pre-existing manual content). The sidebar will render 7 headers.

- [ ] **Step 4: Smoke-test resolve.sh against new config**

Run: `bash scripts/lib/resolve.sh getting-started && jq '.items | map(.slug)' scripts/state/work-plan.json`

Expected: `["quickstart","installation","aws-setup","updating","learning-path"]` with all items status `to_generate`.

- [ ] **Step 5: Commit**

```bash
git add scripts/config.yaml
git commit -m "feat(config): v3 chapters — 7 Hermes-style categories, 51 docs"
```

---

## Task 2: HUMAN-EDIT marker migration helper

**Files:**
- Create: `scripts/lib/migrate_human_edit.py`

Purpose: take a hand-written `manual/xxx.md`, wrap its entire body in a single `HUMAN-EDIT-START/END` block so the next `full_generate` on `/using/xxx.md` preserves it verbatim. Also injects a `sync:` frontmatter stub noting the migration.

- [ ] **Step 1: Write `scripts/lib/migrate_human_edit.py`**

```python
#!/usr/bin/env python3
"""
Migrate a hand-written markdown doc from /using/ (or elsewhere) into a v3 /using/
doc that survives regen.

Wraps the full body (below any existing frontmatter) in a single
`<!-- HUMAN-EDIT-START: <label> --> ... <!-- HUMAN-EDIT-END: <label> -->` block,
and prepends a sync-style frontmatter stub marking the file as migrated.

Usage:
    python3 migrate_human_edit.py <input.md> <output.md> <slug>

Example:
    python3 scripts/lib/migrate_human_edit.py \
        docs/using/chat.md docs/using/chat.md chat
"""
from __future__ import annotations

import re
import sys
from datetime import datetime, timezone
from pathlib import Path


def split_frontmatter(text: str) -> tuple[str, str]:
    """Return (frontmatter_including_fences, rest). Empty frontmatter if absent."""
    if text.startswith("---\n"):
        m = re.match(r"^---\n.*?\n---\n", text, re.DOTALL)
        if m:
            return text[: m.end()], text[m.end():]
    return "", text


def build_frontmatter(slug: str, existing_fm: str) -> str:
    """If input had frontmatter, merge title; always add sync stub."""
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    title_match = re.search(r"^title:\s*(.+)$", existing_fm, re.MULTILINE) if existing_fm else None
    title = title_match.group(1).strip() if title_match else slug.replace("-", " ").title()
    return (
        "---\n"
        f"title: {title}\n"
        "sync:\n"
        "  source_commit: migrated-from-manual\n"
        f"  source_files:\n    - docs/using/{slug}.md\n"
        f"  generated_at: {ts}\n"
        "  generated_by: migrate_human_edit v3\n"
        "  protected: true\n"
        "---\n"
    )


def wrap_body(body: str, slug: str) -> str:
    # Strip leading blank lines from body so HUMAN-EDIT block starts cleanly.
    body = body.lstrip("\n")
    return (
        f"<!-- HUMAN-EDIT-START: manual-{slug} -->\n"
        f"{body}"
        f"{'' if body.endswith(chr(10)) else chr(10)}"
        f"<!-- HUMAN-EDIT-END: manual-{slug} -->\n"
    )


def main() -> int:
    if len(sys.argv) != 4:
        sys.stderr.write("usage: migrate_human_edit.py <input.md> <output.md> <slug>\n")
        return 2
    in_path = Path(sys.argv[1])
    out_path = Path(sys.argv[2])
    slug = sys.argv[3]

    text = in_path.read_text(encoding="utf-8")
    fm, rest = split_frontmatter(text)
    new_fm = build_frontmatter(slug, fm)
    new_body = wrap_body(rest, slug)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(new_fm + "\n" + new_body, encoding="utf-8")
    print(f"Migrated {in_path} -> {out_path} (slug={slug})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

- [ ] **Step 2: Smoke-test with a fixture**

```bash
chmod +x scripts/lib/migrate_human_edit.py
cp docs/using/chat.md /tmp/chat-in.md
python3 scripts/lib/migrate_human_edit.py /tmp/chat-in.md /tmp/chat-out.md chat
head -20 /tmp/chat-out.md
grep -c "HUMAN-EDIT-START\|HUMAN-EDIT-END" /tmp/chat-out.md
python3 scripts/lib/human_edit.py count /tmp/chat-out.md
rm /tmp/chat-in.md /tmp/chat-out.md
```

Expected: frontmatter with `sync.protected: true`, the body wrapped in one HUMAN-EDIT block; `grep -c` = 2; `human_edit.py count` = 1.

- [ ] **Step 3: Commit**

```bash
git add scripts/lib/migrate_human_edit.py
git commit -m "feat(lib): add migrate_human_edit.py for manual→using migration"
```

---

## Task 3: Migrate `/using/*.md` → `/using/*.md`

**Files:**
- Modify (move): 8 files under `docs/using/` → `docs/using/`
- Create: `docs/using/en/.gitkeep`

This uses `git mv` (preserves history) followed by in-place mutation to add HUMAN-EDIT wrapping.

- [ ] **Step 1: Create target dir**

```bash
mkdir -p docs/using/en
touch docs/using/en/.gitkeep
```

- [ ] **Step 2: Move + wrap each manual doc**

For each of the 8 files, do `git mv` to preserve history, then run the migration script on the moved file:

```bash
for slug in dashboard create-agent build-progress chat projects manage-agents tools mcp; do
    if [ -f "docs/using/$slug.md" ]; then
        git mv "docs/using/$slug.md" "docs/using/$slug.md"
        # Wrap in HUMAN-EDIT and add sync frontmatter (operates in place)
        python3 scripts/lib/migrate_human_edit.py "docs/using/$slug.md" "docs/using/$slug.md" "$slug"
    else
        echo "WARN: docs/using/$slug.md missing"
    fi
done
```

**Note:** `migrate_human_edit.py` reads and writes the same path safely because it loads entire contents before writing.

- [ ] **Step 3: Verify**

```bash
ls docs/using/
# Expect: 8 .md files + en/ + (no index.md yet)
grep -l "HUMAN-EDIT-START" docs/using/*.md | wc -l    # expect 8
# Old manual/ should be empty
ls docs/using/ 2>&1 || echo "manual dir removed"
```

Expected: 8 `.md` files all contain HUMAN-EDIT markers, `manual/` directory is empty or removed.

- [ ] **Step 4: Handle link references from the rest of the site**

The existing `/using/...` links in `docs/guide/*.md`, `docs/overview/*.md`, `docs/admin/*.md`, `docs/index.md`, and the nav in `config.mts` need updating.

Run:
```bash
grep -rln "/using/" docs/ --include='*.md' | grep -v /using/
```

For each match, replace `/using/` with `/using/` using sed:

```bash
grep -rln "/using/" docs/ --include='*.md' | grep -v /using/ | xargs sed -i 's|/using/|/using/|g'
```

Verify the home page:
```bash
grep "link:" docs/index.md | head
```

Expected: any `link: /using/xxx` now reads `link: /using/xxx`.

- [ ] **Step 5: Commit**

```bash
git add -A docs/manual docs/using
git commit -m "refactor(docs): migrate /using/ → /using/ with HUMAN-EDIT wrappers"
```

If `docs/manual` is now empty, git mv already handled the move and the dir may or may not still exist; that's fine.

---

## Task 4: Rewrite `docs/.vitepress/config.mts` with persistent Hermes sidebar

**Files:**
- Modify: `docs/.vitepress/config.mts`

Key changes:
1. Remove per-route sidebar (current behavior: different sidebar per `/using/` vs `/admin/`)
2. Build one persistent sidebar used for **every** `/getting-started/`, `/using/`, `/features/`, ... route
3. Drop the long `nav` with dropdowns; keep nav to 3 items (首页 / Docs / 简体中文) mirroring Hermes
4. Add the `/preview/` to srcExclude so preview pages stop showing up

- [ ] **Step 1: Read current config**

Run: `cat docs/.vitepress/config.mts | head -40`

Expected: sees `srcExclude: ['superpowers/**']`, `nav: [...]`, `sidebar: { '/guide/': [...], '/using/': [...] }`.

- [ ] **Step 2: Rewrite entire config**

Replace the whole file with:

```ts
import { defineConfig } from 'vitepress'

// Single persistent sidebar used across every docs route.
// Groups are rendered as collapsible categories in Hermes style.
const SIDEBAR = [
  {
    text: '🚀 快速开始',
    collapsed: false,
    items: [
      { text: '5 分钟快速上手', link: '/getting-started/quickstart' },
      { text: '安装 Nexus-AI', link: '/getting-started/installation' },
      { text: 'AWS 环境准备', link: '/getting-started/aws-setup' },
      { text: '升级与卸载', link: '/getting-started/updating' },
      { text: '学习路径', link: '/getting-started/learning-path' },
    ]
  },
  {
    text: '📖 使用 Nexus-AI',
    collapsed: true,
    items: [
      { text: '工作台', link: '/using/dashboard' },
      { text: '创建 Agent', link: '/using/create-agent' },
      { text: '构建进度', link: '/using/build-progress' },
      { text: '对话', link: '/using/chat' },
      { text: '项目管理', link: '/using/projects' },
      { text: 'Agent 管理', link: '/using/manage-agents' },
      { text: '工具库', link: '/using/tools' },
      { text: 'MCP 服务器', link: '/using/mcp' },
    ]
  },
  {
    text: '⚡ 功能特性',
    collapsed: true,
    items: [
      { text: '概览', link: '/features/' },
      {
        text: 'Core',
        collapsed: true,
        items: [
          { text: '工具与工具集', link: '/features/tools-toolsets' },
          { text: '技能系统', link: '/features/skills-system' },
          { text: 'Agent Factory', link: '/features/agent-factory' },
          { text: '提示词模板', link: '/features/prompt-templates' },
        ]
      },
      {
        text: 'Runtime',
        collapsed: true,
        items: [
          { text: 'Sandbox 沙箱', link: '/features/sandbox' },
          { text: '工作流引擎', link: '/features/workflow-engine' },
          { text: '多 Agent 图/群', link: '/features/multi-agent' },
          { text: '流式响应中继', link: '/features/stream-relay' },
        ]
      },
      {
        text: 'Automation',
        collapsed: true,
        items: [
          { text: '事件调度', link: '/features/event-scheduler' },
          { text: 'Bridge 多连接', link: '/features/bridge' },
        ]
      },
      {
        text: 'Observability',
        collapsed: true,
        items: [
          { text: '可观测性', link: '/features/observability' },
          { text: '指标与计费', link: '/features/metrics-billing' },
          { text: '日志', link: '/features/logging' },
        ]
      },
    ]
  },
  {
    text: '🔌 集成',
    collapsed: true,
    items: [
      { text: '集成总览', link: '/integrations/overview' },
      { text: 'AWS Bedrock 模型接入', link: '/integrations/aws-bedrock' },
      { text: '外部 MCP 服务器', link: '/integrations/mcp-clients' },
      { text: 'Agent as MCP Tool', link: '/integrations/mcp-server' },
      { text: 'SSO (SAML 2.0)', link: '/integrations/sso-saml' },
      { text: '数据存储', link: '/integrations/data-stores' },
    ]
  },
  {
    text: '📚 使用指南',
    collapsed: true,
    items: [
      { text: '技巧与最佳实践', link: '/guides/tips' },
      { text: '构建 Hermes 分析 Agent', link: '/guides/build-hermes-analyst' },
      { text: '构建技术博客生成 Agent', link: '/guides/build-tech-blog' },
      { text: '在 Nexus-AI 中使用 MCP', link: '/guides/use-mcp-with-nexus' },
    ]
  },
  {
    text: '👨‍💻 开发者指南',
    collapsed: true,
    items: [
      { text: '贡献指南', link: '/developer/contributing' },
      {
        text: 'Architecture',
        collapsed: true,
        items: [
          { text: '架构总览', link: '/developer/architecture-overview' },
          { text: 'API 层架构', link: '/developer/api-layer' },
          { text: 'Worker 架构', link: '/developer/worker' },
          { text: 'Stage 引擎', link: '/developer/stage-engine' },
        ]
      },
      {
        text: 'Extending',
        collapsed: true,
        items: [
          { text: '添加 Agent', link: '/developer/adding-agents' },
          { text: '添加工具', link: '/developer/adding-tools' },
          { text: '添加技能', link: '/developer/adding-skills' },
        ]
      },
      {
        text: 'Internals',
        collapsed: true,
        items: [
          { text: '会话存储', link: '/developer/session-storage' },
          { text: '动态 Prompt 构建', link: '/developer/dynamic-prompt' },
        ]
      },
    ]
  },
  {
    text: '📋 参考',
    collapsed: true,
    items: [
      { text: 'nexus-cli 命令', link: '/reference/cli-commands' },
      { text: '配置项', link: '/reference/config-options' },
      { text: '环境变量', link: '/reference/environment-variables' },
      { text: 'API 端点', link: '/reference/api-endpoints' },
      { text: '部署参数', link: '/reference/deploy-params' },
      { text: 'IAM 权限', link: '/reference/iam-policies' },
      { text: '模型目录', link: '/reference/model-catalog' },
      { text: '术语表', link: '/reference/glossary' },
      { text: 'FAQ 与故障排查', link: '/reference/faq' },
    ]
  },
]

export default defineConfig({
  base: '/playbook/',
  title: 'Nexus-AI',
  description: '用自然语言构建 AI Agent — 产品使用手册',
  lang: 'zh-CN',
  lastUpdated: true,
  cleanUrls: true,

  // Exclude internal planning docs and preview scratch area from the build.
  srcExclude: ['superpowers/**', 'preview/**'],

  head: [
    ['link', { rel: 'icon', type: 'image/png', href: '/playbook/default_logo.png' }],
    ['meta', { name: 'theme-color', content: '#6366f1' }],
    ['meta', { name: 'apple-mobile-web-app-capable', content: 'yes' }],
    ['meta', { name: 'apple-mobile-web-app-status-bar-style', content: 'black-translucent' }],
    ['meta', { name: 'viewport', content: 'width=device-width, initial-scale=1.0, viewport-fit=cover' }],
  ],

  markdown: {
    lineNumbers: true,
  },

  themeConfig: {
    logo: '/default_logo.png',
    siteTitle: 'Nexus-AI',

    // Minimal top nav — sidebar is the primary navigation.
    nav: [
      { text: '首页', link: '/' },
      { text: '文档', link: '/getting-started/quickstart' },
      {
        text: '快速链接',
        items: [
          { text: '💡 平台概述', link: '/overview/what-is-nexus' },
          { text: '🛡️ 管理员指南', link: '/admin/settings' },
          { text: '🚀 引导教程', link: '/guide/login' },
        ]
      },
    ],

    // Persistent sidebar shown across all docs routes.
    sidebar: {
      '/': SIDEBAR,
    },

    socialLinks: [
      { icon: 'github', link: 'https://github.com/hy714335634/Nexus-AI' }
    ],

    editLink: {
      pattern: 'https://github.com/hy714335634/Nexus-AI-Playbook/edit/main/docs/:path',
      text: '在 GitHub 上编辑此页'
    },

    footer: {
      message: 'Released under the MIT License.',
      copyright: 'Copyright © 2025-present Nexus-AI Team'
    },

    search: {
      provider: 'local',
      options: {
        translations: {
          button: { buttonText: '搜索文档', buttonAriaLabel: '搜索文档' },
          modal: {
            noResultsText: '没有找到相关内容',
            resetButtonTitle: '清除',
            footer: { selectText: '选择', navigateText: '切换', closeText: '关闭' }
          }
        }
      }
    },

    outline: { label: '📑 本页目录', level: [2, 3] },
    lastUpdated: { text: '最后更新' },
    docFooter: { prev: '← 上一篇', next: '下一篇 →' },
    returnToTopLabel: '回到顶部',
    sidebarMenuLabel: '菜单',
    darkModeSwitchLabel: '主题',
  }
})
```

- [ ] **Step 3: Build and confirm**

Run: `npm run docs:build 2>&1 | tail -15`

Expected: `build complete`. Dead-link warnings for `/features/*`, `/integrations/*`, etc. pages that don't exist yet are expected; if build itself fails on them we need to patch. VitePress treats dead internal links as warnings, not errors, when the file truly doesn't exist _and_ is not referenced outside sidebar — but if it errors, we'll add `ignoreDeadLinks: true` at the top level.

**If build fails with dead link errors:** add to `defineConfig`:
```ts
  ignoreDeadLinks: 'localhostLinks',
```
OR more liberally:
```ts
  ignoreDeadLinks: true,
```

Use whichever keeps the build passing. Rebuild and confirm.

- [ ] **Step 4: Commit**

```bash
git add docs/.vitepress/config.mts
git commit -m "feat(vitepress): Hermes-style persistent sidebar + minimal nav"
```

---

## Task 5: Delete legacy `/preview/` scratch content

**Files:**
- Delete: `docs/preview/`

- [ ] **Step 1: Remove directory**

```bash
git rm -r docs/preview
```

- [ ] **Step 2: Verify build still passes**

```bash
npm run docs:build 2>&1 | tail -5
```

Expected: `build complete`.

- [ ] **Step 3: Commit**

```bash
git commit -m "chore(docs): remove /preview/ scratch area"
```

---

## Task 6: Retire ad-hoc `/overview/` and `/admin/` top-level entries (redirect-only)

**Decision:** keep `/overview/` and `/admin/` files in place (they are hand-written and good) but they don't appear in the persistent sidebar. They're reachable through the top-nav "快速链接" dropdown (already configured in Task 4). No file moves this round — Batch 4 will fold them into the sidebar properly. This task just confirms the setup.

**Files:**
- No file changes.

- [ ] **Step 1: Verify accessibility**

Run: `npm run docs:build 2>&1 | tail -5`

Expected: `build complete` (overview and admin pages still build because their markdown files exist).

- [ ] **Step 2: Verify nav dropdown contains them (visual / config check)**

Run: `grep -A 6 "'快速链接'" docs/.vitepress/config.mts`

Expected: sees the three items (`/overview/what-is-nexus`, `/admin/settings`, `/guide/login`).

- [ ] **Step 3: No commit needed** (nothing changed).

---

## Task 7: Update `docs/index.md` hero actions to point at new structure

**Files:**
- Modify: `docs/index.md`

The homepage still advertises `/guide/login` and multiple `/using/...` feature cards. After the migration we want:
- Primary CTA → `/getting-started/quickstart`
- Secondary CTA → `/using/create-agent` (the core workflow)
- Feature cards remain but their `link:` values use `/using/...`

Task 3 Step 4 already sed-replaced `/using/` → `/using/` in `docs/index.md`. We just need to retarget the hero.

- [ ] **Step 1: Read current hero section**

Run: `head -20 docs/index.md`

- [ ] **Step 2: Edit hero actions**

Find the block:
```yaml
  actions:
    - theme: brand
      text: 🚀 快速上手
      link: /guide/login
    - theme: alt
      text: 💡 了解 Nexus-AI
      link: /overview/what-is-nexus
```

Replace with:
```yaml
  actions:
    - theme: brand
      text: 🚀 快速开始
      link: /getting-started/quickstart
    - theme: alt
      text: 📖 Agent 使用手册
      link: /using/dashboard
```

- [ ] **Step 3: Build + commit**

```bash
npm run docs:build 2>&1 | tail -5
git add docs/index.md
git commit -m "refactor(index): hero CTAs target /getting-started and /using"
```

Expected: `build complete`, commit succeeds.

---

## Task 8: Prune obsolete top-level nav references

Task 4 already simplified nav to 3 items. This task is a no-op confirmation.

- [ ] **Step 1: Verify nav is minimal**

Run: `grep -A 20 "nav: \[" docs/.vitepress/config.mts`

Expected: three top-level entries (首页 / 文档 / 快速链接). No `使用手册`, `功能特性`, `集成`, `教程`, `开发者`, `参考` entries (those live in sidebar now).

- [ ] **Step 2: No commit.**

---

## Task 9: Restructure landing — validate end-to-end with dev server

**Files:**
- No changes.

Final gate before Batch 1 generation: dev-server the site and click around to confirm the sidebar is persistent, the migrated /using/ pages render intact (HUMAN-EDIT preserved), and preview/ is gone.

- [ ] **Step 1: Start server**

```bash
pkill -f "vitepress dev" 2>/dev/null; sleep 1
npm run docs:dev -- --host 0.0.0.0
```

(Run in background via the agent's `run_in_background=true`, then `sleep 5` and tail the output file.)

- [ ] **Step 2: Verify URL map**

Open:
- `http://localhost:5173/playbook/` — home with new CTAs
- `http://localhost:5173/playbook/getting-started/quickstart` — expect sidebar listing all 7 categories on left, page 404 or empty-but-clean on right (content generated in T10–T12)
- `http://localhost:5173/playbook/using/chat` — migrated page, content renders exactly as old /using/chat.md did
- `http://localhost:5173/playbook/preview/` — expect 404 (removed)

- [ ] **Step 3: Stop server**

```bash
pkill -f "vitepress dev"
```

- [ ] **Step 4: Pause for human review**

Restructure is landed. Before generating Batch 1 content (which hits the Claude API), present to the user:

> "Restructure complete (commits T1–T8). Sidebar is persistent 7-category Hermes-style, /using/ moved to /using/ with HUMAN-EDIT markers, preview/ removed. Ready to run Batch 1 (Getting Started, 5 docs, ~$1.50 USD). Confirm to proceed?"

Wait for explicit approval before T10.

---

## Task 10: Generate Getting Started — estimate + dry-run

**Files:**
- No changes; reads `config.yaml`, writes `drafts/getting-started/` (gitignored).

- [ ] **Step 1: Estimate cost**

```bash
./scripts/sync.sh --estimate --chapter getting-started
```

Expected: cost table with 5 rows (quickstart, installation, aws-setup, updating, learning-path). Total should be well under $5 (these sources are small — mostly README excerpts and config files).

- [ ] **Step 2: Report estimate to user**

Show the estimate output verbatim. Confirm proceed.

If user asks to adjust `sources` on any doc (narrow or broaden), go back to Task 1 Step 2, edit `config.yaml`, re-estimate, before continuing.

---

## Task 11: Generate Getting Started — execute full-gen

**Files:**
- Generated (gitignored): `drafts/getting-started/**`
- Generated (git-tracked): `scripts/state/signatures/getting-started__*.sha`, `scripts/state/runs/<ts>.json`

- [ ] **Step 1: Run full-gen**

```bash
./scripts/sync.sh --full --chapter getting-started 2>&1 | tee /tmp/gs-run.log
```

Expected: 5 docs × (zh + en) = 10 files produced in `drafts/getting-started/` + index.md pair; pipeline ends with `Full-gen done. See drafts/SUMMARY.md and drafts/getting-started/`.

- [ ] **Step 2: Inspect one draft as sanity check**

```bash
head -40 drafts/getting-started/quickstart.md
head -40 drafts/getting-started/en/quickstart.md
cat drafts/SUMMARY.md
```

Expected:
- Both zh and en have `sync:` frontmatter with `source_commit`, `source_files`, `generated_at`.
- H1 matches the chapter's `title_zh` / `title_en`.
- Body follows the `feature-overview` structure (这是什么 / 使用场景 / 如何使用 / ...).
- `SUMMARY.md` lists all 5 slugs under the `getting-started` mapping.

- [ ] **Step 3: Look for errors/warnings**

```bash
cat scripts/state/runs/*.json | jq -s 'last'
```

Expected: most recent run shows `exit_code: 0`, all docs `status: generated`, none `failed` or `empty_output`.

If any doc failed, `./scripts/sync.sh --full --chapter getting-started --doc <slug> --force-regenerate` retries just that slug.

---

## Task 12: Merge Batch 1 drafts into `docs/` + final commit

**Files:**
- Copy: 10 draft files → `docs/getting-started/` and `docs/getting-started/en/`
- Copy: `drafts/sidebar/getting-started.json` — not needed, sidebar is hand-built in `config.mts` (skip)
- Refresh: `docs/public/llms.txt` and `llms-full.txt`

- [ ] **Step 1: Create target dirs**

```bash
mkdir -p docs/getting-started/en
```

- [ ] **Step 2: Copy drafts into place**

```bash
cp drafts/getting-started/*.md docs/getting-started/ 2>/dev/null
cp drafts/getting-started/en/*.md docs/getting-started/en/ 2>/dev/null
ls docs/getting-started/
ls docs/getting-started/en/
```

Expected: each of the 6 files (quickstart, installation, aws-setup, updating, learning-path, index) present in both zh and en dirs.

- [ ] **Step 3: Build**

```bash
npm run docs:build 2>&1 | tail -8
```

Expected: `build complete`.

- [ ] **Step 4: Refresh llms.txt**

```bash
./scripts/sync.sh --emit-llms-txt
wc -l docs/public/llms.txt docs/public/llms-full.txt
```

Expected: line count increased by 5–6 (new getting-started entries).

- [ ] **Step 5: Commit**

```bash
git add docs/getting-started/ docs/public/llms.txt docs/public/llms-full.txt scripts/state/runs/ scripts/state/signatures/
git commit -m "docs(getting-started): generate Batch 1 — 5 docs (zh+en)"
```

- [ ] **Step 6: Update STATUS.md**

Edit `docs/superpowers/STATUS.md` replacing the **当前阶段** section with:

```markdown
## 当前阶段

**阶段：** v3 Batch 1 (Getting Started) 已完成。剩余 3 个 batch 待生成。

- ✅ Restructure: 7-category persistent Hermes-style sidebar
- ✅ /using/ → /using/ migration（HUMAN-EDIT 保护启用）
- ✅ Batch 1: Getting Started 5 页（zh+en）已合并至 docs/
- ⏳ Batch 2: Using(wrap existing)+Features-Core (~12 页) — 待单独 plan
- ⏳ Batch 3: Features-rest+Integrations (~13 页) — 待单独 plan
- ⏳ Batch 4: Developer+Reference+Guides (~20 页) — 待单独 plan
```

- [ ] **Step 7: Commit**

```bash
git add docs/superpowers/STATUS.md
git commit -m "docs(status): mark v3 Batch 1 complete"
```

---

## Self-Review

**Spec coverage vs `2026-05-07-playbook-docs-sync-v2-design.md`:**
- §1 新增章节规划 → Task 1 (with v3's revised category list) ✓
- §1.5 端用户接口 → 已由 v2 实施；Task 4 `editLink` 保留 ✓
- §2 双模式 → v2 保留 (v1 regression 未触碰) ✓
- §2.5 自动化强化 → Signatures/audit/estimate/HUMAN-EDIT 已由 v2 实施；Task 2 额外扩展为"把手写内容也纳入 HUMAN-EDIT 保护" ✓
- §3 Prompt 模板 → v3 未增加新模板，复用 v2 的 7 个 ✓
- §4 自动化演进路径 → 未实施（deferred per user choice；hooks still in place via audit logs）✓
- §5 目录结构 → Task 3 实际产出 `/using/`, `/getting-started/` 等 ✓
- §6 CLI → v2 全部 flag 未动 ✓
- §7 MVP (v3 是 v2 的 Batch 1) → 第一批次交付 ✓
- §9 成功标准 → Task 11 Step 2-3 + Task 12 Step 3 ✓

**Placeholder scan:** No "TBD" / "implement later" / "add appropriate error handling" / "similar to Task N" phrases. Every step has concrete commands and (where relevant) exact content.

**Type consistency:**
- `migrate_human_edit.py` reads/writes in Task 2 — same API used in Task 3 loop
- `human_edit.py count` / `verify` commands match v2 API
- Chapter id strings (`getting-started`, `using`, `features`, `integrations`, `guides`, `developer`, `reference`) consistent across config.yaml (T1), sidebar.mts (T4), sync.sh --chapter invocations (T10, T11)
- `drafts/getting-started/` / `drafts/getting-started/en/` paths consistent between full_generate.sh (inherited from v2) and T11/T12

**Known issues flagged (worth surfacing to the user):**

1. **Chapter count:** Plan commits to **7** top-level categories in the sidebar (getting-started, using, features, integrations, guides, developer, reference). My spec section named "6 categories" historically — this is an off-by-one **in the spec wording**, not a bug. The 7 is intentional and documented in Task 1 Step 3's expected output.
2. **`/guide/`, `/admin/`, `/overview/` dual exposure:** These stay as leaf pages reachable only via the top-nav "快速链接" dropdown. Users landing on them see the same persistent sidebar (which doesn't include those pages directly), which might feel mildly disorienting. Batch 4 should resolve by merging them into existing categories.
3. **`ignoreDeadLinks`:** Task 4 Step 3 tentatively allows `ignoreDeadLinks: true` or `'localhostLinks'` if the build fails. This is pragmatic but means a future typo in a link won't be caught. Revisit once all 4 batches land — at that point we want dead-link errors back on.
4. **`tools.md` and `mcp.md`:** They exist both as manual-migrated `/using/{tools,mcp}.md` (hand-written) and as auto-generated `/features/{tools-toolsets, mcp-server}.md` / `/integrations/mcp-server.md`. Content will overlap. Acceptable because `/using/` is user-facing how-to while `/features/` is concept explanation, but we should name-disambiguate if overlap becomes confusing (Batch 2 decision).

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-05-08-playbook-docs-sync-v3.md`.

**Two execution options:**

1. **Subagent-Driven (recommended)** — dispatch a fresh subagent per task, review between tasks, fast iteration.
2. **Inline Execution** — execute tasks in this session using executing-plans, with natural pause points at **T9 (restructure complete)** and **T10 (pre-API estimate)**.

Which approach?
