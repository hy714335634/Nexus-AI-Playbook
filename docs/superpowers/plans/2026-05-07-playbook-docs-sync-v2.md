# Playbook Docs-Sync v2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend the v1 incremental-sync pipeline into a Wiki/CMS-grade framework that full-generates 5 new Playbook chapters (+ glossary) from Nexus-AI source, preserves human edits across regenerations, and leaves hooks for cron/PR/unattended automation.

**Architecture:** Build atop v1's 5-stage shell pipeline (detect → prepare → generate → screenshot → output). Add a parallel `--full --chapter <name>` path with its own resolve → prepare → generate → index → sidebar → llms.txt → audit stages. Claude Code (`claude -p`) remains the content engine; new helpers manage per-doc content signatures (sha256 skip), HUMAN-EDIT block preservation, cost estimation, and audit logs. No new runtime dependencies beyond v1.

**Tech Stack:** Bash 4+, Python 3 + `pyyaml`, `jq`, Claude Code CLI, Node 18 + Playwright (v1 dep), VitePress (Vue 3 theme component).

**Reference spec:** `docs/superpowers/specs/2026-05-07-playbook-docs-sync-v2-design.md` (commits `5d0e106` + `8cd1329`).

**Working directory for commands:** `/home/ubuntu/mydev/Nexus-AI-Playbook` unless stated otherwise.

**Important constraints (spec §0 + lessons from v1):**
- No automated test framework; verification is manual per task.
- v1 pipeline must keep working (regression): `./scripts/sync.sh --only-detect` on a known range still succeeds.
- Claude Code is the content engine — scripts never template-generate prose.
- `scripts/state/signatures/`, `scripts/state/runs/` are git-tracked (small, auditable).
- `drafts/` remains gitignored; `docs/public/llms.txt` / `llms-full.txt` are git-tracked build artifacts (rebuilt on each run, committed as part of content).
- **Real Nexus-AI `agents/generated_agents/` at time of writing:** `hermes_analyst_agent_2026a96a`, `tech_blog_generator_05b957e9`. Plan uses these for tutorials (not the spec's speculative names).

---

## Decisions locked (resolving spec §10 open questions)

| Question | Decision |
|----------|----------|
| tutorials 精选哪几个 Agent？ | `hermes_analyst_agent` + `tech_blog_generator` (两个本地真实存在的 generated_agents) + 一份基于 `magician.py` 的 "快速上手 Agent" 综合教程 = 3 篇 |
| features 最终文档数？ | **7 篇**：mcp-server, sandbox, workflow-engine, observability, multimodal, bridge, event-scheduler |
| VitePress 顶级 nav 是否需要分组？ | 保持 flat；现有 9 项仍可接受，分组放 stage B |

## File Structure (全量预览)

### 新建文件
```
docs/
├── .vitepress/theme/
│   ├── index.ts                              # Theme 扩展入口 (若已有保留)
│   └── SyncFreshness.vue                     # 新鲜度组件
├── public/
│   ├── llms.txt                              # (生成的构建产物，git-tracked)
│   └── llms-full.txt                         # 同上
└── superpowers/plans/2026-05-07-playbook-docs-sync-v2.md   # 本文件

scripts/
├── lib/
│   ├── resolve.sh            # Stage 0: chapter -> doc list
│   ├── signatures.sh         # sha256 compute/compare
│   ├── estimate.sh           # token/cost preview
│   ├── full_generate.sh      # --full mode orchestrator
│   ├── index_gen.sh          # chapter index.md generator
│   ├── sidebar_gen.sh        # sidebar JSON fragment generator
│   ├── llms_txt.sh           # aggregate docs -> llms*.txt
│   ├── audit.sh              # write state/runs/<ts>.json
│   └── human_edit.py         # Python helper: extract HUMAN-EDIT blocks from file
└── prompts/
    ├── feature-overview.md
    ├── integration-guide.md
    ├── tutorial.md
    ├── developer-guide.md
    ├── reference.md
    ├── chapter-index.md
    └── glossary.md
```

### 修改文件
- `scripts/config.yaml` — 新增 `chapters:` 根节点 + 6 chapters + 约 25 docs
- `scripts/sync.sh` — 新增 9 个 CLI flag 的 dispatch
- `scripts/lib/common.sh` — 新增 `SIGNATURES_DIR`、`RUNS_DIR`、`audit_start/finish` helpers
- `scripts/prompts/style-guide.md` — 追加 frontmatter 与 HUMAN-EDIT 保留规则
- `docs/.vitepress/config.mts` — 加 `editLink`、扩展 nav/sidebar 为 6 新章节占位
- `.gitignore` — 允许 `state/signatures/` + `state/runs/` 提交 (已 ignore `state/work/`,`state/changes.json`)

### 新建目录 (per-chapter drafts 与 docs)
```
docs/features/, docs/features/en/
docs/integrations/, docs/integrations/en/
docs/tutorials/, docs/tutorials/en/
docs/developer/, docs/developer/en/
docs/reference/, docs/reference/en/
docs/glossary/, docs/glossary/en/
drafts/features/, drafts/features/en/
drafts/integrations/..., drafts/reference/..., drafts/glossary/...
drafts/sidebar/
scripts/state/signatures/
scripts/state/runs/
```

---

## Task Groups

- **Group A (Tasks 1–3):** 基础设施 — state dirs, gitignore, config schema, common helpers
- **Group B (Tasks 4–5):** 签名与审计 — signatures.sh, audit.sh
- **Group C (Tasks 6–7):** HUMAN-EDIT 保护 + prompt style-guide 更新
- **Group D (Tasks 8–14):** 7 个 prompt 模板
- **Group E (Tasks 15–18):** Pipeline stages — resolve, full_generate, index_gen, sidebar_gen
- **Group F (Task 19):** estimate.sh
- **Group G (Task 20):** llms_txt.sh
- **Group H (Task 21):** sync.sh CLI 扩展
- **Group I (Tasks 22–23):** VitePress 主题与 config 扩展
- **Group J (Tasks 24–30):** 逐章节全量生成 (features, integrations, tutorials, developer, reference, glossary, Wiki 能力验证)

---

## Task 1: State dirs + gitignore adjustments

**Files:**
- Create: `scripts/state/signatures/.gitkeep`
- Create: `scripts/state/runs/.gitkeep`
- Modify: `.gitignore`

- [ ] **Step 1: Create state subdirectories with .gitkeep**

```bash
cd /home/ubuntu/mydev/Nexus-AI-Playbook
mkdir -p scripts/state/signatures scripts/state/runs
touch scripts/state/signatures/.gitkeep scripts/state/runs/.gitkeep
```

- [ ] **Step 2: Verify `.gitignore` does NOT exclude `state/signatures/` or `state/runs/`**

Run: `cat .gitignore`

Expected: lines currently present are:
```
scripts/state/work/
scripts/state/changes.json
scripts/state/errors.log
```
None of these match `signatures/` or `runs/`. No change needed to `.gitignore` if this is true.

If `scripts/state/` itself is ignored (it shouldn't be), fix by replacing that line with the three specific paths above. Otherwise no edit.

- [ ] **Step 3: Confirm tracking**

Run: `git check-ignore scripts/state/signatures/foo scripts/state/runs/bar 2>&1 || echo "not ignored (good)"`

Expected: `not ignored (good)` (exit 1 from check-ignore, caught by `||`)

- [ ] **Step 4: Commit**

```bash
git add scripts/state/signatures/.gitkeep scripts/state/runs/.gitkeep
git commit -m "chore(scripts): add signatures/ and runs/ state directories"
```

---

## Task 2: Extend `config.yaml` with `chapters`

**Files:**
- Modify: `scripts/config.yaml`

Keep existing v1 `mappings` block. Add a new top-level `chapters` block defining 6 chapters.

- [ ] **Step 1: Read current config**

Run: `cat scripts/config.yaml | head -20`
Expected: sees `source_repo`, `models`, `languages`, `mappings`, `screenshots`.

- [ ] **Step 2: Append `chapters` block**

Edit `scripts/config.yaml`; add these contents **before** the existing `# 截图配置` section (so order is: source_repo, models, languages, mappings, chapters, screenshots):

```yaml
# 章节定义（v2 新增）
# 每个章节声明：输出目录、prompt 默认模板、本章节包含的文档列表
# 每篇文档的 sources 是相对 Nexus-AI 仓库根的 glob/path 列表
chapters:
  features:
    title_zh: "功能特性"
    title_en: "Features"
    output_dir: "features"
    prompt_default: "feature-overview.md"
    docs:
      - slug: "mcp-server"
        title_zh: "MCP 服务器"
        title_en: "MCP Server"
        sources: ["nexus_utils/mcp/mcp_server/**", "nexus_utils/mcp/**"]
      - slug: "sandbox"
        title_zh: "Sandbox 沙箱运行时"
        title_en: "Sandbox Runtime"
        sources: ["nexus_utils/sandbox/**"]
      - slug: "workflow-engine"
        title_zh: "工作流引擎"
        title_en: "Workflow Engine"
        sources: ["nexus_utils/workflow/**", "config/workflows.yaml"]
      - slug: "observability"
        title_zh: "可观测性"
        title_en: "Observability"
        sources: ["nexus_utils/observability/**"]
      - slug: "multimodal"
        title_zh: "多模态处理"
        title_en: "Multimodal Processing"
        sources: ["nexus_utils/multimodal_processing/**"]
      - slug: "bridge"
        title_zh: "Bridge 多连接"
        title_en: "Bridge Multi-Connection"
        sources: ["nexus_utils/bridge/**"]
      - slug: "event-scheduler"
        title_zh: "事件调度"
        title_en: "Event Scheduler"
        sources: ["nexus_utils/event_scheduler/**", "config/eventschedule_config.yaml"]

  integrations:
    title_zh: "集成"
    title_en: "Integrations"
    output_dir: "integrations"
    prompt_default: "integration-guide.md"
    docs:
      - slug: "aws-bedrock"
        title_zh: "AWS Bedrock 模型接入"
        title_en: "AWS Bedrock Models"
        sources: ["nexus_utils/agent_factory.py", "config/model_catalog.yaml", "config/default_config.yaml"]
      - slug: "mcp-clients"
        title_zh: "外部 MCP 服务器集成"
        title_en: "External MCP Servers"
        sources: ["nexus_utils/mcp/mcp_client/**", "config/mcp/**"]
      - slug: "sso-saml"
        title_zh: "SSO 单点登录 (SAML 2.0)"
        title_en: "SSO (SAML 2.0)"
        sources: ["api/v2/auth/**"]
      - slug: "data-stores"
        title_zh: "数据存储层（Aurora / Valkey / DDB / SQS / S3）"
        title_en: "Data Stores (Aurora / Valkey / DynamoDB / SQS / S3)"
        sources: ["api/v2/database/**", "config/default_config.yaml"]
      - slug: "deployment"
        title_zh: "CloudFormation 一键部署"
        title_en: "CloudFormation Deployment"
        sources: ["infrastructure/**", "nexus-cli"]

  tutorials:
    title_zh: "教程"
    title_en: "Tutorials"
    output_dir: "tutorials"
    prompt_default: "tutorial.md"
    docs:
      - slug: "hermes-analyst"
        title_zh: "构建一个 Hermes 分析 Agent"
        title_en: "Build a Hermes Analyst Agent"
        sources: ["agents/generated_agents/hermes_analyst_agent_2026a96a/**", "prompts/generated_agents_prompts/hermes_analyst_agent_2026a96a/**"]
      - slug: "tech-blog-generator"
        title_zh: "构建一个技术博客生成 Agent"
        title_en: "Build a Tech Blog Generator Agent"
        sources: ["agents/generated_agents/tech_blog_generator_05b957e9/**", "prompts/generated_agents_prompts/tech_blog_generator_05b957e9/**"]
      - slug: "first-chat"
        title_zh: "从零体验：第一次对话"
        title_en: "From Zero: Your First Chat"
        sources: ["agents/system_agents/magician.py", "api/v2/routers/sessions.py"]

  developer:
    title_zh: "开发者指南"
    title_en: "Developer Guide"
    output_dir: "developer"
    prompt_default: "developer-guide.md"
    docs:
      - slug: "architecture-overview"
        title_zh: "架构总览"
        title_en: "Architecture Overview"
        sources: ["CLAUDE.md", "README.md", "architecture/**"]
      - slug: "contributing"
        title_zh: "贡献指南"
        title_en: "Contributing"
        sources: ["CONTRIBUTING.md"]
      - slug: "local-setup"
        title_zh: "本地开发环境搭建"
        title_en: "Local Development Setup"
        sources: ["setup_env_alinux2023.sh", "pyproject.toml", "requirements.txt", "README.md"]
      - slug: "extending-agents"
        title_zh: "扩展 Agent 与工具"
        title_en: "Extending Agents and Tools"
        sources: ["nexus_utils/agent_factory.py", "agents/template_agents/**", "tools/**"]

  reference:
    title_zh: "参考"
    title_en: "Reference"
    output_dir: "reference"
    prompt_default: "reference.md"
    docs:
      - slug: "cli-commands"
        title_zh: "nexus-cli 命令参考"
        title_en: "nexus-cli Command Reference"
        sources: ["nexus-cli", "nexus_utils/cli/**"]
      - slug: "config-options"
        title_zh: "配置项参考"
        title_en: "Configuration Reference"
        sources: ["config/default_config.yaml", "config/logging_config.yaml", "config/eventschedule_config.yaml"]
      - slug: "api-endpoints"
        title_zh: "API 端点参考"
        title_en: "API Endpoint Reference"
        sources: ["api/v2/main.py", "api/v2/routers/**"]
      - slug: "deploy-params"
        title_zh: "部署参数参考"
        title_en: "Deployment Parameters"
        sources: ["infrastructure/**", "nexus-cli"]

  glossary:
    title_zh: "术语表"
    title_en: "Glossary"
    output_dir: "glossary"
    prompt_default: "glossary.md"
    docs:
      - slug: "index"
        title_zh: "Nexus-AI 术语表"
        title_en: "Nexus-AI Glossary"
        sources: ["CLAUDE.md", "README.md", "nexus_utils/**", "agents/system_agents/**"]

# 运行策略
run:
  # 签名文件路径（相对 scripts/state/signatures/）
  signatures_dir: "signatures"
  # 审计日志路径（相对 scripts/state/runs/）
  runs_dir: "runs"
  # Token→USD 估算（MVP 粗估，Sonnet input $3/M, output $15/M）
  pricing:
    default:
      input_per_mtok: 3.0
      output_per_mtok: 15.0
    complex:
      input_per_mtok: 15.0
      output_per_mtok: 75.0
```

- [ ] **Step 3: Validate YAML**

Run: `python3 -c "import yaml; d=yaml.safe_load(open('scripts/config.yaml')); print('chapters:', list(d['chapters'].keys()))"`

Expected: `chapters: ['features', 'integrations', 'tutorials', 'developer', 'reference', 'glossary']`

- [ ] **Step 4: Count docs**

Run: `python3 -c "import yaml; d=yaml.safe_load(open('scripts/config.yaml')); print(sum(len(c['docs']) for c in d['chapters'].values()), 'docs total')"`

Expected: `24 docs total` (7+5+3+4+4+1)

- [ ] **Step 5: Commit**

```bash
git add scripts/config.yaml
git commit -m "feat(config): add chapters schema with 6 chapters / 24 docs"
```

---

## Task 3: Extend `common.sh` with new paths + audit helpers

**Files:**
- Modify: `scripts/lib/common.sh`

- [ ] **Step 1: Read current common.sh**

Run: `cat scripts/lib/common.sh`
Expected: see `SCRIPTS_DIR`, `STATE_DIR`, `yaml_get()`, `abs_source_repo()` etc.

- [ ] **Step 2: Append new exports and helpers**

Edit `scripts/lib/common.sh`; append **after** the existing `abs_source_repo()` function (keep all existing code intact):

```bash

# ===== v2 additions =====

SIGNATURES_DIR="$STATE_DIR/signatures"
RUNS_DIR="$STATE_DIR/runs"
DOCS_DIR="$REPO_ROOT/docs"
LLMS_TXT_DIR="$REPO_ROOT/docs/public"

export SIGNATURES_DIR RUNS_DIR DOCS_DIR LLMS_TXT_DIR

mkdir -p "$SIGNATURES_DIR" "$RUNS_DIR" 2>/dev/null || true

# run_id — timestamp used for a single sync.sh invocation's audit trail
_RUN_ID=""
run_id() {
    if [ -z "$_RUN_ID" ]; then
        _RUN_ID="$(date -u +%Y-%m-%dT%H-%M-%SZ)"
    fi
    echo "$_RUN_ID"
}

# chapter_doc_slugs <chapter-id> — prints one slug per line for the given chapter
chapter_doc_slugs() {
    local ch="$1"
    yaml_get ".chapters.\"$ch\".docs[].slug" | tr -d '"'
}

# chapter_exists <chapter-id> — exits 0 if yes, 1 if no
chapter_exists() {
    local ch="$1"
    local out
    out="$(yaml_get ".chapters | has(\"$ch\")" 2>/dev/null || true)"
    [ "$out" = "true" ]
}

# doc_sources <chapter-id> <slug> — prints each source pattern on its own line
doc_sources() {
    local ch="$1" slug="$2"
    yaml_get ".chapters.\"$ch\".docs[] | select(.slug==\"$slug\") | .sources[]" | tr -d '"'
}

# doc_title <chapter-id> <slug> <lang>  — lang in {zh,en}
doc_title() {
    local ch="$1" slug="$2" lang="$3"
    yaml_get ".chapters.\"$ch\".docs[] | select(.slug==\"$slug\") | .title_$lang" | tr -d '"'
}

# chapter_title <chapter-id> <lang>
chapter_title() {
    local ch="$1" lang="$2"
    yaml_get ".chapters.\"$ch\".title_$lang" | tr -d '"'
}

# chapter_prompt_default <chapter-id>
chapter_prompt_default() {
    local ch="$1"
    yaml_get ".chapters.\"$ch\".prompt_default" | tr -d '"'
}
```

- [ ] **Step 3: Verify new helpers work**

Run:
```bash
bash -c 'source scripts/lib/common.sh && chapter_exists features && echo OK; chapter_doc_slugs features; doc_sources features mcp-server; doc_title features mcp-server zh; run_id'
```

Expected:
```
OK
mcp-server
sandbox
workflow-engine
observability
multimodal
bridge
event-scheduler
nexus_utils/mcp/mcp_server/**
nexus_utils/mcp/**
MCP 服务器
2026-05-07T...
```

- [ ] **Step 4: Verify v1 still works**

Run: `bash -c 'source scripts/lib/common.sh && abs_source_repo'`

Expected: `/home/ubuntu/mydev/Nexus-AI`

- [ ] **Step 5: Commit**

```bash
git add scripts/lib/common.sh
git commit -m "feat(lib): add v2 common helpers (paths, run_id, chapter/doc lookups)"
```

---

## Task 4: `signatures.sh` — content-hash skip logic

**Files:**
- Create: `scripts/lib/_expand_sources.py` — standalone Python helper
- Create: `scripts/lib/signatures.sh` — shell library

This is a self-contained library script (`source` it). Provides 3 functions:
- `compute_signature <chapter> <slug>` — prints sha256 of all source files' contents (sorted to be deterministic)
- `load_signature <chapter> <slug>` — prints stored signature or empty if none
- `save_signature <chapter> <slug> <sig>` — stores it

> **Why a separate Python file instead of a heredoc:** when you write `python3 - <<'PYEOF'`, Python reads its script source from the heredoc — which also consumes the function's stdin. The `sys.stdin.read()` inside the script then returns empty, silently breaking glob expansion. V1 already hit this trap (see `match_mappings.py`). Always use a standalone `.py` file when the shell function needs to pipe into Python.

- [ ] **Step 1a: Write `scripts/lib/_expand_sources.py`**

```python
#!/usr/bin/env python3
"""
Read source patterns from stdin (one per line) and print absolute file paths
matching those globs under the Nexus-AI source root.

Usage:
    echo "nexus_utils/mcp/**" | python3 _expand_sources.py /path/to/Nexus-AI
"""
import sys
import glob
import os


def main() -> int:
    if len(sys.argv) != 2:
        sys.stderr.write("usage: _expand_sources.py <source_root>\n")
        return 2
    root = sys.argv[1]
    patterns = [l.strip() for l in sys.stdin.read().splitlines() if l.strip()]
    seen = set()
    for pattern in patterns:
        abs_pattern = os.path.join(root, pattern)
        for p in sorted(glob.glob(abs_pattern, recursive=True)):
            if os.path.isfile(p) and p not in seen:
                seen.add(p)
                print(p)
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

- [ ] **Step 1b: Write `scripts/lib/signatures.sh`**

```bash
#!/usr/bin/env bash
# Content-hash signatures — skip doc generation when sources unchanged.

# Intentionally NOT setting `set -e` here; sourced by scripts that manage strictness.

if [ -z "${COMMON_SOURCED:-}" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
    COMMON_SOURCED=1
fi

# _sig_path <chapter> <slug>
_sig_path() {
    echo "$SIGNATURES_DIR/${1}__${2}.sha"
}

# _expand_sources — read source patterns from stdin, print absolute matching files
_expand_sources() {
    local src
    src="$(abs_source_repo)"
    python3 "$SCRIPTS_DIR/lib/_expand_sources.py" "$src"
}

# compute_signature <chapter> <slug>
compute_signature() {
    local ch="$1" slug="$2"
    local files
    files="$(doc_sources "$ch" "$slug" | _expand_sources | sort -u)"
    if [ -z "$files" ]; then
        echo "NO_SOURCES"
        return
    fi
    echo "$files" | xargs -I{} sha256sum {} | sort | sha256sum | awk '{print $1}'
}

# load_signature <chapter> <slug>
load_signature() {
    local p
    p="$(_sig_path "$1" "$2")"
    [ -f "$p" ] && cat "$p" || echo ""
}

# save_signature <chapter> <slug> <sig>
save_signature() {
    local p
    p="$(_sig_path "$1" "$2")"
    mkdir -p "$(dirname "$p")"
    echo "$3" > "$p"
}

# signature_matches <chapter> <slug> — exit 0 if stored matches computed, 1 otherwise
signature_matches() {
    local computed stored
    computed="$(compute_signature "$1" "$2")"
    stored="$(load_signature "$1" "$2")"
    [ -n "$stored" ] && [ "$computed" = "$stored" ]
}
```

- [ ] **Step 2: Make executable (not required since it's sourced, but harmless) + smoke-test**

```bash
chmod +x scripts/lib/signatures.sh
bash -c '
set -euo pipefail
source scripts/lib/common.sh
source scripts/lib/signatures.sh
sig=$(compute_signature features mcp-server)
echo "computed: $sig"
save_signature features mcp-server "$sig"
load_signature features mcp-server
signature_matches features mcp-server && echo "MATCH OK"
'
```

Expected:
- `computed:` line with a 64-char hex
- same hex echoed again by `load_signature`
- `MATCH OK`

- [ ] **Step 3: Verify mismatch detection**

```bash
bash -c '
set -euo pipefail
source scripts/lib/common.sh
source scripts/lib/signatures.sh
save_signature features mcp-server "fake"
signature_matches features mcp-server && echo "SHOULD NOT REACH" || echo "mismatch detected"
'
```

Expected: `mismatch detected`

- [ ] **Step 4: Reset signature for clean state**

```bash
rm -rf scripts/state/signatures/*
touch scripts/state/signatures/.gitkeep
```

- [ ] **Step 5: Commit**

```bash
git add scripts/lib/signatures.sh
git commit -m "feat(lib): add content-signature skip logic"
```

---

## Task 5: `audit.sh` — per-run JSON audit logs

**Files:**
- Create: `scripts/lib/audit.sh`

Provides: `audit_start`, `audit_record_doc`, `audit_finish`. Appends to a single file `scripts/state/runs/<run_id>.json`.

- [ ] **Step 1: Write `scripts/lib/audit.sh`**

```bash
#!/usr/bin/env bash
# Per-run JSON audit logs.

if [ -z "${COMMON_SOURCED:-}" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
    COMMON_SOURCED=1
fi

# Internal helper — path of the current run's JSON
_audit_path() {
    echo "$RUNS_DIR/$(run_id).json"
}

# audit_start <mode> <chapter> <trigger>
audit_start() {
    local mode="$1" chapter="${2:-}" trigger="${3:-cli}"
    local path
    path="$(_audit_path)"
    mkdir -p "$(dirname "$path")"
    local src
    src="$(abs_source_repo)"
    local commit
    commit="$(git -C "$src" rev-parse HEAD 2>/dev/null || echo unknown)"
    jq -n \
        --arg ts "$(date -u -Iseconds)" \
        --arg mode "$mode" \
        --arg chapter "$chapter" \
        --arg trigger "$trigger" \
        --arg commit "$commit" \
        '{timestamp:$ts, mode:$mode, chapter:$chapter, trigger:$trigger, source_commit:$commit, docs:[], total_cost_usd:0, total_elapsed_s:0, exit_code:null}' \
        > "$path"
}

# audit_record_doc <chapter> <slug> <status> [tokens_in] [tokens_out] [cost_usd] [human_blocks_preserved] [error]
audit_record_doc() {
    local ch="$1" slug="$2" status="$3"
    local tokens_in="${4:-0}" tokens_out="${5:-0}" cost="${6:-0}" hbp="${7:-0}" err="${8:-}"
    local path
    path="$(_audit_path)"
    [ -f "$path" ] || return 0
    jq --arg ch "$ch" --arg slug "$slug" --arg status "$status" \
       --argjson ti "$tokens_in" --argjson to "$tokens_out" --argjson cost "$cost" \
       --argjson hbp "$hbp" --arg err "$err" \
       '.docs += [{chapter:$ch, slug:$slug, status:$status, tokens_in:$ti, tokens_out:$to, cost_usd:$cost, human_blocks_preserved:$hbp, error:$err}] | .total_cost_usd = ([.docs[].cost_usd] | add)' \
       "$path" > "$path.tmp" && mv "$path.tmp" "$path"
}

# audit_finish <exit_code>
audit_finish() {
    local code="${1:-0}"
    local path
    path="$(_audit_path)"
    [ -f "$path" ] || return 0
    local start_ts now_ts
    start_ts="$(jq -r '.timestamp' "$path")"
    now_ts="$(date -u -Iseconds)"
    local elapsed
    elapsed="$(python3 -c "from datetime import datetime as d; a=d.fromisoformat('$start_ts'.replace('Z','+00:00')); b=d.fromisoformat('$now_ts'.replace('Z','+00:00')); print(int((b-a).total_seconds()))")"
    jq --arg now "$now_ts" --argjson code "$code" --argjson elapsed "$elapsed" \
       '.finished_at=$now | .exit_code=$code | .total_elapsed_s=$elapsed' \
       "$path" > "$path.tmp" && mv "$path.tmp" "$path"
    log "Audit: $path"
}
```

- [ ] **Step 2: Smoke-test**

```bash
bash -c '
set -euo pipefail
source scripts/lib/common.sh
source scripts/lib/audit.sh
audit_start full features cli
audit_record_doc features mcp-server generated 1200 400 0.02 1
audit_record_doc features sandbox skipped_signature 0 0 0 0
audit_finish 0
cat "$RUNS_DIR/$(run_id).json" | jq .
'
```

Expected: JSON with `mode:"full"`, `chapter:"features"`, `docs` array of length 2, `total_cost_usd: 0.02`, `exit_code: 0`, `total_elapsed_s` a small integer.

- [ ] **Step 3: Clean up test run**

```bash
rm -f scripts/state/runs/*.json
```

- [ ] **Step 4: Commit**

```bash
git add scripts/lib/audit.sh
git commit -m "feat(lib): add per-run JSON audit logger"
```

---

## Task 6: HUMAN-EDIT block extractor (Python helper)

**Files:**
- Create: `scripts/lib/human_edit.py`

Extracts all `<!-- HUMAN-EDIT-START: <label> --> ... <!-- HUMAN-EDIT-END: <label> -->` blocks from a file. Used both for **pre-generation** (to show Claude the blocks to preserve) and **post-generation** (to verify they survived).

- [ ] **Step 1: Write `scripts/lib/human_edit.py`**

```python
#!/usr/bin/env python3
"""
Extract HUMAN-EDIT-START/END blocks from a markdown file.

Usage:
    python3 human_edit.py extract <file>
        -> prints JSON: [{"label": "...", "content": "..."}]
    python3 human_edit.py count <file>
        -> prints integer (number of blocks)
    python3 human_edit.py verify <original> <regenerated>
        -> exit 0 if all blocks from <original> are present verbatim in <regenerated>,
           exit 1 otherwise; prints missing labels on stderr
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

BLOCK_RE = re.compile(
    r"<!-- HUMAN-EDIT-START: (?P<label>[^\n>]+?) -->\n(?P<body>.*?)\n<!-- HUMAN-EDIT-END: (?P=label) -->",
    re.DOTALL,
)


def extract(path: str) -> list[dict]:
    p = Path(path)
    if not p.exists():
        return []
    text = p.read_text(encoding="utf-8")
    return [
        {"label": m.group("label").strip(), "content": m.group("body")}
        for m in BLOCK_RE.finditer(text)
    ]


def verify(orig_path: str, new_path: str) -> int:
    orig_blocks = extract(orig_path)
    new_blocks = extract(new_path)
    new_map = {b["label"]: b["content"] for b in new_blocks}
    missing = []
    for ob in orig_blocks:
        if new_map.get(ob["label"]) != ob["content"]:
            missing.append(ob["label"])
    if missing:
        sys.stderr.write(
            "Missing or altered HUMAN-EDIT blocks: " + ", ".join(missing) + "\n"
        )
        return 1
    return 0


def main() -> int:
    if len(sys.argv) < 2:
        sys.stderr.write(__doc__ or "")
        return 2
    cmd = sys.argv[1]
    if cmd == "extract":
        if len(sys.argv) != 3:
            return 2
        json.dump(extract(sys.argv[2]), sys.stdout, ensure_ascii=False, indent=2)
        print()
        return 0
    if cmd == "count":
        if len(sys.argv) != 3:
            return 2
        print(len(extract(sys.argv[2])))
        return 0
    if cmd == "verify":
        if len(sys.argv) != 4:
            return 2
        return verify(sys.argv[2], sys.argv[3])
    sys.stderr.write(f"Unknown command: {cmd}\n")
    return 2


if __name__ == "__main__":
    sys.exit(main())
```

- [ ] **Step 2: Test with a fixture**

```bash
chmod +x scripts/lib/human_edit.py
cat > /tmp/he_fixture.md <<'EOF'
# Title

<!-- HUMAN-EDIT-START: intro -->
This is my handwritten intro that must survive regen.
<!-- HUMAN-EDIT-END: intro -->

Some body text.

<!-- HUMAN-EDIT-START: caveat -->
Note: X is Y.
<!-- HUMAN-EDIT-END: caveat -->
EOF

python3 scripts/lib/human_edit.py count /tmp/he_fixture.md
python3 scripts/lib/human_edit.py extract /tmp/he_fixture.md
```

Expected: `count` prints `2`; `extract` prints JSON with two labels (`intro`, `caveat`).

- [ ] **Step 3: Test verify (positive + negative)**

```bash
# Positive: identical file
python3 scripts/lib/human_edit.py verify /tmp/he_fixture.md /tmp/he_fixture.md
echo "exit=$?"

# Negative: altered copy
sed 's|This is my handwritten intro.*|CORRUPTED|' /tmp/he_fixture.md > /tmp/he_fixture_bad.md
python3 scripts/lib/human_edit.py verify /tmp/he_fixture.md /tmp/he_fixture_bad.md
echo "exit=$?"

rm /tmp/he_fixture*.md
```

Expected: first `exit=0`; second prints missing label on stderr and `exit=1`.

- [ ] **Step 4: Commit**

```bash
git add scripts/lib/human_edit.py
git commit -m "feat(lib): add HUMAN-EDIT block extract/verify helper"
```

---

## Task 7: Update `style-guide.md` with frontmatter + HUMAN-EDIT rules

**Files:**
- Modify: `scripts/prompts/style-guide.md`

- [ ] **Step 1: Read current style guide**

Run: `cat scripts/prompts/style-guide.md`

- [ ] **Step 2: Append new rules to the bottom**

Edit `scripts/prompts/style-guide.md`; append (preserve existing content):

```markdown

## Frontmatter（v2 新增）

**每一份生成的 markdown 文档开头必须包含如下 YAML frontmatter**，由调用方注入实际字段值（详见 prompt 任务段的 `OUTPUT_FRONTMATTER_ZH` / `OUTPUT_FRONTMATTER_EN` 环境变量）：

```yaml
---
title: <文档标题>
sync:
  source_commit: <Nexus-AI 的 commit SHA>
  source_files:
    - path/to/source/file1
    - path/to/source/file2
  generated_at: <ISO 8601 时间戳>
  generated_by: docs-sync v2
---
```

**硬性规则：**

- 如果调用方通过 `PRE_FRONTMATTER` 环境变量提供了 frontmatter 块，**原封不动地放在文档开头**（你不需要重新发明字段）。
- frontmatter 之后空一行，然后是 H1 标题，然后是正文。

## HUMAN-EDIT 块保留（v2 新增）

若现有的中/英文档中含有如下注释块，必须在生成的新版文档中 **保留完全相同的内容和标签**，位置应尽量贴近相同章节上下文：

```markdown
<!-- HUMAN-EDIT-START: <标签名> -->
人工精心编辑的段落。
<!-- HUMAN-EDIT-END: <标签名> -->
```

**硬性规则：**

- 调用方会提前把现有文档里所有 HUMAN-EDIT 块通过 `HUMAN_EDIT_BLOCKS_ZH` / `HUMAN_EDIT_BLOCKS_EN` 环境变量（内容为 JSON）告知你。
- 你必须在新文档中对每个 label 产生一个 `HUMAN-EDIT-START/END` 对，**block 内容保持逐字节一致**（不改排版、不翻译、不删）。
- 放置位置：若原文档该 label 位于某小节下，新文档中尽量放到**语义最相关的同级章节**；若无法判断，放文档末尾"备注"小节之前。
```

- [ ] **Step 3: Verify**

Run: `wc -l scripts/prompts/style-guide.md`

Expected: line count increased by ~40 lines vs previous.

Run: `grep -c "HUMAN-EDIT-START" scripts/prompts/style-guide.md`

Expected: `2` (one example line + one rule reference).

- [ ] **Step 4: Commit**

```bash
git add scripts/prompts/style-guide.md
git commit -m "feat(prompts): add frontmatter + HUMAN-EDIT rules to style guide"
```

---

## Task 8: `feature-overview.md` prompt

**Files:**
- Create: `scripts/prompts/feature-overview.md`

- [ ] **Step 1: Write prompt**

```markdown
# 任务：基于源代码全量生成 Features 章节中的一篇功能文档

你是 Nexus-AI 的产品文档工程师。针对 **一个功能模块**，从零撰写一篇面向终端用户的功能介绍。

## 输入文件（都在当前工作目录）

- `style-guide.md` — **必读**。整体风格 + frontmatter + HUMAN-EDIT 规则。
- `sources.md` — 该功能模块的源代码（每个源文件的完整内容）。
- `current-doc-zh.md` / `current-doc-en.md` — 已有文档内容（可能为 "(文档不存在)"）。
- `sync-fields.md` — 本次生成应写入 frontmatter 的 sync 字段（source_commit、source_files、generated_at）。

## 任务

阅读 `style-guide.md`，然后：

1. 从 `sources.md` 中识别该功能的：核心用途、用户能做什么、不能做什么、典型操作步骤、使用前提。
2. 按以下**标准结构**撰写中英文双版：
   - （frontmatter，见 style-guide）
   - H1：功能名
   - **这是什么** — 1-3 句话告诉用户"这个功能解决什么问题"
   - **使用场景** — 2-4 个典型用户场景（列表/表格）
   - **如何使用** — 分步操作（适时插入 `<!-- SCREENSHOT: <name> -->`）
   - **关键参数 / 限制** — 表格形式
   - **常见问题** — 3-5 条 Q&A
3. 如果现有文档含 `HUMAN-EDIT-START/END` 块，按 style-guide 规则保留。

## 输出

通过 Write 工具写入下面两个绝对路径（由环境变量提供）：

- `OUTPUT_ZH` — 中文版
- `OUTPUT_EN` — 英文版

frontmatter 的 sync 字段从 `sync-fields.md` 读取后填入。

## 完成

成功写入两个文件后，打印一行：`DONE: wrote <OUTPUT_ZH> and <OUTPUT_EN>`
```

- [ ] **Step 2: Commit**

```bash
git add scripts/prompts/feature-overview.md
git commit -m "feat(prompts): add feature-overview template"
```

---

## Task 9: `integration-guide.md` prompt

**Files:**
- Create: `scripts/prompts/integration-guide.md`

- [ ] **Step 1: Write prompt**

```markdown
# 任务：基于源代码全量生成 Integrations 章节中的一篇集成文档

你是 Nexus-AI 的产品文档工程师。针对 **一项与外部系统/服务的集成**，面向 **管理员/部署者** 撰写集成指南。

## 输入

- `style-guide.md` — **必读**。
- `sources.md` — 与本集成相关的源代码、配置文件。
- `current-doc-zh.md` / `current-doc-en.md` — 已有文档。
- `sync-fields.md` — frontmatter sync 字段值。

## 任务

1. 识别：
   - 集成的目标系统（AWS Bedrock / MCP Server / SAML IdP / ... ）
   - 为什么需要这项集成
   - 启用/配置的步骤
   - 验证集成是否生效的方法
2. 按下述结构输出中英双版：
   - （frontmatter）
   - H1：集成名
   - **概述** — 1-2 段
   - **启用前提** — 前置条件列表
   - **配置步骤** — 分步，包含 `yaml` / `bash` 代码块
   - **验证** — 如何确认集成成功
   - **故障排查** — 常见问题表格
3. 保留 HUMAN-EDIT 块（见 style-guide）。

## 输出

写入 `OUTPUT_ZH` / `OUTPUT_EN`（环境变量提供的绝对路径）。

## 完成

打印：`DONE: wrote <OUTPUT_ZH> and <OUTPUT_EN>`
```

- [ ] **Step 2: Commit**

```bash
git add scripts/prompts/integration-guide.md
git commit -m "feat(prompts): add integration-guide template"
```

---

## Task 10: `tutorial.md` prompt

**Files:**
- Create: `scripts/prompts/tutorial.md`

- [ ] **Step 1: Write prompt**

```markdown
# 任务：基于源代码全量生成 Tutorials 章节中的一篇分步教程

你是 Nexus-AI 的产品文档工程师。针对 **一个可以独立完成的用户任务**（如"构建一个 XXX Agent"），撰写分步教程。

## 输入

- `style-guide.md` — **必读**。
- `sources.md` — 目标 Agent 的源代码、prompt 文件、生成产物。
- `current-doc-zh.md` / `current-doc-en.md` — 已有文档。
- `sync-fields.md` — frontmatter 值。

## 任务

1. 识别：
   - 用户最终会得到什么（结果/能力）
   - 需要的时间和前置条件
   - 逐步操作（每一步都能独立验证）
2. 按下述结构输出中英双版：
   - （frontmatter）
   - H1：教程名（动词开头："构建一个..."/"从零体验..."）
   - **你会得到什么** — 1-2 句
   - **前置条件** — 列表 (AWS 凭证？Bedrock 开通？)
   - **大约耗时**
   - **步骤 1: ...** / **步骤 2: ...** — 每步含：动作、代码/命令、期望输出、`<!-- SCREENSHOT: -->` 占位
   - **验证** — 终态检查
   - **下一步** — 建议的相关教程链接
3. 保留 HUMAN-EDIT 块。

**关键约束：** 教程必须"跑得通"。所有命令、路径、文件名必须来自源码，不要编造。

## 输出

写入 `OUTPUT_ZH` / `OUTPUT_EN`。

## 完成

打印：`DONE: wrote <OUTPUT_ZH> and <OUTPUT_EN>`
```

- [ ] **Step 2: Commit**

```bash
git add scripts/prompts/tutorial.md
git commit -m "feat(prompts): add tutorial template"
```

---

## Task 11: `developer-guide.md` prompt

**Files:**
- Create: `scripts/prompts/developer-guide.md`

- [ ] **Step 1: Write prompt**

```markdown
# 任务：基于源代码全量生成 Developer Guide 章节中的一篇

你是 Nexus-AI 的文档工程师。这份文档 **面向开发者**（不是终端用户），可以引用架构名词、目录结构、扩展点、源码路径。

## 输入

- `style-guide.md` — 必读。**注意：** developer 章节**允许**包含代码细节、类名、包路径，这是 style-guide 的例外情况。
- `sources.md` — 开发者相关的源文件（CLAUDE.md、CONTRIBUTING.md、架构文档、setup 脚本等）。
- `current-doc-zh.md` / `current-doc-en.md` — 已有文档。
- `sync-fields.md` — frontmatter 值。

## 任务

1. 目标读者：想阅读/修改/扩展 Nexus-AI 代码的开发者。
2. 按下述结构输出中英双版：
   - （frontmatter）
   - H1
   - **适用读者** — 1 段
   - **核心概念** — 列出开发者需要了解的概念（Agent / Stage / Skill / Workflow 等）
   - **代码结构** — 目录树 + 每个目录做什么
   - **关键扩展点** — 如何添加自定义 Agent / Tool / Skill
   - **开发流程** — 从 clone 到提交 PR
   - **延伸阅读** — 其它相关文档链接
3. 保留 HUMAN-EDIT 块。

## 输出

写入 `OUTPUT_ZH` / `OUTPUT_EN`。

## 完成

打印：`DONE: wrote <OUTPUT_ZH> and <OUTPUT_EN>`
```

- [ ] **Step 2: Commit**

```bash
git add scripts/prompts/developer-guide.md
git commit -m "feat(prompts): add developer-guide template"
```

---

## Task 12: `reference.md` prompt

**Files:**
- Create: `scripts/prompts/reference.md`

- [ ] **Step 1: Write prompt**

```markdown
# 任务：基于源代码全量生成 Reference 章节中的一篇参考文档

你是 Nexus-AI 的文档工程师。参考文档 **结构化、表格为主、少叙事**。

## 输入

- `style-guide.md` — 必读。
- `sources.md` — 要参考化的源内容（CLI 源码、YAML 配置、FastAPI 路由、部署脚本等）。
- `current-doc-zh.md` / `current-doc-en.md` — 已有文档。
- `sync-fields.md` — frontmatter 值。

## 任务

根据 sources.md 的内容类型，选择合适的结构：

**CLI 类（nexus-cli）：** 表格：命令 / 作用 / 必填参数 / 可选参数 / 示例
**配置项类（*.yaml）：** 表格：Key / 类型 / 默认值 / 说明 / 示例
**API 类（FastAPI）：** 表格：Method / Path / 说明 / 请求体 / 响应（按 Router 分小节）
**部署参数类：** 表格：参数 / 默认值 / 是否必填 / 说明

**硬性规则：**
- 完整穷举，不省略
- 每条都必须从源代码中提取，不编造
- 中英文表头与顺序完全一致
- 保留 HUMAN-EDIT 块

## 输出

写入 `OUTPUT_ZH` / `OUTPUT_EN`。

## 完成

打印：`DONE: wrote <OUTPUT_ZH> and <OUTPUT_EN>`
```

- [ ] **Step 2: Commit**

```bash
git add scripts/prompts/reference.md
git commit -m "feat(prompts): add reference template"
```

---

## Task 13: `chapter-index.md` prompt

**Files:**
- Create: `scripts/prompts/chapter-index.md`

- [ ] **Step 1: Write prompt**

```markdown
# 任务：生成章节入口页 (index.md)

为某个章节生成一个入口页。它列出本章节下所有文档的链接与简介。

## 输入

- `style-guide.md` — 必读。
- `chapter-manifest.md` — 本章节的 manifest，包含章节标题、每篇文档的 slug、标题、首段摘要。
- `sync-fields.md` — frontmatter 值。

## 任务

生成中英双版的 `index.md`，结构：

- （frontmatter）
- H1：章节名
- 1-2 段"本章节涵盖什么"的引子
- 文档列表（卡片/表格二选一，整章统一）：每项包含文档标题 + 一句简介 + 链接

链接格式：`[标题](./<slug>)`（VitePress 的 cleanUrls 会处理）

## 输出

写入 `OUTPUT_ZH` / `OUTPUT_EN`。

## 完成

打印：`DONE: wrote <OUTPUT_ZH> and <OUTPUT_EN>`
```

- [ ] **Step 2: Commit**

```bash
git add scripts/prompts/chapter-index.md
git commit -m "feat(prompts): add chapter-index template"
```

---

## Task 14: `glossary.md` prompt

**Files:**
- Create: `scripts/prompts/glossary.md`

- [ ] **Step 1: Write prompt**

```markdown
# 任务：生成 Nexus-AI 术语表

从 Nexus-AI 源代码与现有文档中扫描专有名词，生成一份结构化术语表。

## 输入

- `style-guide.md` — 必读。
- `sources.md` — 源代码与既有文档聚合（CLAUDE.md、README.md、nexus_utils/ 代码等）。
- `current-doc-zh.md` / `current-doc-en.md` — 现有术语表（若存在）。
- `sync-fields.md` — frontmatter。

## 任务

1. 扫描 sources.md，识别 Nexus-AI 特有的术语：
   - Agent 类型（Magician Agent、Orchestrator Agent、Builder Agent...）
   - 架构组件（Stage、Skill、Bridge、Workflow Engine、Sandbox、Valkey Stream Relay...）
   - 协议/集成（MCP、SAML、FastMCP...）
   - 产品概念（Guided Creation、Quick Creation、Multi-Agent Swarm/Graph...）
2. 每条术语格式：
   ```markdown
   ### 术语名（英文缩写/全称）

   1-3 句简洁定义。链接到该术语在其它文档中详细出现的位置。
   ```
3. **按字母序组织**（A-Z），不按主题分组。
4. 排除通用技术词汇（Python、JSON、HTTP 这些）。
5. 中英文版**术语同序**，每条定义翻译对应。
6. 保留 HUMAN-EDIT 块。

## 输出

写入 `OUTPUT_ZH` / `OUTPUT_EN`。

## 完成

打印：`DONE: wrote <OUTPUT_ZH> and <OUTPUT_EN>`
```

- [ ] **Step 2: Commit**

```bash
git add scripts/prompts/glossary.md
git commit -m "feat(prompts): add glossary template"
```

---

## Task 15: `resolve.sh` — chapter → doc list expansion

**Files:**
- Create: `scripts/lib/resolve.sh`

Given a chapter (and optional slug filter), produce a JSON work-plan describing exactly which docs to generate. Writes to `scripts/state/work-plan.json`.

- [ ] **Step 1: Write `scripts/lib/resolve.sh`**

```bash
#!/usr/bin/env bash
# Stage 0 for --full mode: resolve a chapter (+ optional --doc filter) to a
# concrete work plan at state/work-plan.json.

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

CHAPTER="${1:?chapter required}"
DOC_FILTER="${2:-}"      # optional slug filter
FORCE="${3:-}"           # "force" to ignore signatures

chapter_exists "$CHAPTER" || die "Unknown chapter: $CHAPTER"

source "$SCRIPTS_DIR/lib/signatures.sh"

PLAN_FILE="$STATE_DIR/work-plan.json"
SRC="$(abs_source_repo)"
COMMIT="$(git -C "$SRC" rev-parse HEAD)"

# Start plan
jq -n --arg ch "$CHAPTER" --arg commit "$COMMIT" \
    '{chapter:$ch, source_commit:$commit, items:[]}' > "$PLAN_FILE"

SLUGS="$(chapter_doc_slugs "$CHAPTER")"

while IFS= read -r slug; do
    [ -z "$slug" ] && continue
    if [ -n "$DOC_FILTER" ] && [ "$slug" != "$DOC_FILTER" ]; then
        continue
    fi
    if [ -z "$FORCE" ] && signature_matches "$CHAPTER" "$slug"; then
        STATUS="skip_signature"
    else
        STATUS="to_generate"
    fi
    TITLE_ZH="$(doc_title "$CHAPTER" "$slug" zh)"
    TITLE_EN="$(doc_title "$CHAPTER" "$slug" en)"
    PROMPT="$(yaml_get ".chapters.\"$CHAPTER\".docs[] | select(.slug==\"$slug\") | .prompt // .prompt_default" | tr -d '"')"
    if [ "$PROMPT" = "null" ] || [ -z "$PROMPT" ]; then
        PROMPT="$(chapter_prompt_default "$CHAPTER")"
    fi
    MODEL="$(yaml_get ".chapters.\"$CHAPTER\".docs[] | select(.slug==\"$slug\") | .model // \"default\"" | tr -d '"')"

    jq --arg slug "$slug" --arg status "$STATUS" --arg tz "$TITLE_ZH" --arg te "$TITLE_EN" --arg p "$PROMPT" --arg m "$MODEL" \
       '.items += [{slug:$slug, status:$status, title_zh:$tz, title_en:$te, prompt:$p, model:$m}]' \
       "$PLAN_FILE" > "$PLAN_FILE.tmp" && mv "$PLAN_FILE.tmp" "$PLAN_FILE"
done <<< "$SLUGS"

TOTAL="$(jq '.items | length' "$PLAN_FILE")"
TO_GEN="$(jq '[.items[] | select(.status=="to_generate")] | length' "$PLAN_FILE")"
log "Resolve: chapter=$CHAPTER, total=$TOTAL, to_generate=$TO_GEN"
```

- [ ] **Step 2: Make executable + smoke test**

```bash
chmod +x scripts/lib/resolve.sh
bash scripts/lib/resolve.sh features
jq '.items | map({slug,status,prompt})' scripts/state/work-plan.json
```

Expected output (all `to_generate` on first run since no signatures yet):
```json
[
  {"slug":"mcp-server","status":"to_generate","prompt":"feature-overview.md"},
  {"slug":"sandbox","status":"to_generate","prompt":"feature-overview.md"},
  ...
]
```

- [ ] **Step 3: Test with `--doc` filter**

```bash
bash scripts/lib/resolve.sh features mcp-server
jq '.items | map(.slug)' scripts/state/work-plan.json
```

Expected: `["mcp-server"]`

- [ ] **Step 4: Commit**

```bash
git add scripts/lib/resolve.sh
git commit -m "feat(lib): add resolve.sh — chapter→doc work plan generator"
```

---

## Task 16: `full_generate.sh` — --full mode orchestration

**Files:**
- Create: `scripts/lib/_format_sources.py` — standalone Python helper for context assembly
- Create: `scripts/lib/full_generate.sh`

Reads `state/work-plan.json` and, for each `to_generate` item:
1. Prepares a per-doc context under `state/work/<chapter>/<slug>/`
2. Calls `claude -p` with proper env (OUTPUT_ZH, OUTPUT_EN, PRE_FRONTMATTER, HUMAN_EDIT_BLOCKS_*)
3. Records into audit + updates signature

- [ ] **Step 1a: Write `scripts/lib/_format_sources.py`**

This is a standalone helper (same heredoc-stdin trap avoidance as `_expand_sources.py`). It reads source glob patterns from stdin, expands them against the Nexus-AI root, and writes each matched file as a markdown-formatted chunk.

```python
#!/usr/bin/env python3
"""
Read source glob patterns from stdin, expand against Nexus-AI root, and print
each matched file formatted as a markdown chunk with file content in a code block.

Usage:
    echo "nexus_utils/mcp/**" | python3 _format_sources.py /path/to/Nexus-AI
"""
import sys
import os
import glob


MAX_CHARS = 20000  # truncate per-file to keep context bounded


def main() -> int:
    if len(sys.argv) != 2:
        sys.stderr.write("usage: _format_sources.py <source_root>\n")
        return 2
    root = sys.argv[1]
    patterns = [l.strip() for l in sys.stdin.read().splitlines() if l.strip()]
    seen = set()
    for pat in patterns:
        abs_pat = os.path.join(root, pat)
        for path in sorted(glob.glob(abs_pat, recursive=True)):
            if not os.path.isfile(path) or path in seen:
                continue
            seen.add(path)
            rel = os.path.relpath(path, root)
            try:
                with open(path, "r", encoding="utf-8") as f:
                    text = f.read()
            except Exception as e:
                text = f"(could not read: {e})"
            if len(text) > MAX_CHARS:
                text = text[:MAX_CHARS] + f"\n\n... (truncated, original {len(text)} chars)"
            print(f"\n## {rel}\n")
            print("```")
            print(text)
            print("```")
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

- [ ] **Step 1b: Write `scripts/lib/full_generate.sh`**

```bash
#!/usr/bin/env bash
# Stage: --full generator.
# Reads state/work-plan.json + config; produces drafts/<chapter>/<slug>.md (zh+en).

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
source "$SCRIPTS_DIR/lib/signatures.sh"
source "$SCRIPTS_DIR/lib/audit.sh"

PLAN_FILE="$STATE_DIR/work-plan.json"
[ -f "$PLAN_FILE" ] || die "No work-plan.json. Run resolve.sh first."

CHAPTER="$(jq -r '.chapter' "$PLAN_FILE")"
COMMIT="$(jq -r '.source_commit' "$PLAN_FILE")"
SRC="$(abs_source_repo)"

# Model names
MODEL_DEFAULT="$(yaml_get '.models.default' | tr -d '"')"
MODEL_COMPLEX="$(yaml_get '.models.complex' | tr -d '"')"

DRAFT_BASE="$DRAFTS_DIR/$CHAPTER"
DRAFT_EN="$DRAFTS_DIR/$CHAPTER/en"
mkdir -p "$DRAFT_BASE" "$DRAFT_EN"

# Clean this chapter's work dir (fresh slate per run)
rm -rf "$WORK_DIR/$CHAPTER"
mkdir -p "$WORK_DIR/$CHAPTER"

COUNT_TO_GEN="$(jq '[.items[] | select(.status=="to_generate")] | length' "$PLAN_FILE")"
log "Full-generate chapter=$CHAPTER: $COUNT_TO_GEN doc(s) to generate"

for idx in $(seq 0 $(($(jq '.items | length' "$PLAN_FILE") - 1))); do
    ITEM="$(jq -c ".items[$idx]" "$PLAN_FILE")"
    SLUG="$(echo "$ITEM" | jq -r '.slug')"
    STATUS="$(echo "$ITEM" | jq -r '.status')"
    TITLE_ZH="$(echo "$ITEM" | jq -r '.title_zh')"
    TITLE_EN="$(echo "$ITEM" | jq -r '.title_en')"
    PROMPT_NAME="$(echo "$ITEM" | jq -r '.prompt')"
    MODEL_KEY="$(echo "$ITEM" | jq -r '.model')"

    if [ "$STATUS" = "skip_signature" ]; then
        log "  [$SLUG] skipped (signature match)"
        audit_record_doc "$CHAPTER" "$SLUG" "skipped_signature" 0 0 0 0 ""
        continue
    fi

    # Resolve model
    case "$MODEL_KEY" in
        complex) MODEL="$MODEL_COMPLEX" ;;
        *)       MODEL="$MODEL_DEFAULT" ;;
    esac

    WORK="$WORK_DIR/$CHAPTER/$SLUG"
    mkdir -p "$WORK"

    # Assemble sources.md — concatenate every matching file
    # We use a standalone helper because heredoc `python3 - <<EOF` would consume
    # the stdin we need to pipe patterns into (same trap as _expand_sources.py).
    log "  [$SLUG] preparing context"
    {
        echo "# 源代码内容 — $CHAPTER / $SLUG"
        echo
        echo "commit: \`$COMMIT\`"
        echo
        doc_sources "$CHAPTER" "$SLUG" | python3 "$SCRIPTS_DIR/lib/_format_sources.py" "$SRC"
    } > "$WORK/sources.md"

    # Copy existing docs (if present)
    DOC_ZH_PATH="$DOCS_DIR/$CHAPTER/$SLUG.md"
    DOC_EN_PATH="$DOCS_DIR/$CHAPTER/en/$SLUG.md"
    if [ -f "$DOC_ZH_PATH" ]; then
        cp "$DOC_ZH_PATH" "$WORK/current-doc-zh.md"
    else
        echo "(文档不存在)" > "$WORK/current-doc-zh.md"
    fi
    if [ -f "$DOC_EN_PATH" ]; then
        cp "$DOC_EN_PATH" "$WORK/current-doc-en.md"
    else
        echo "(document does not exist yet)" > "$WORK/current-doc-en.md"
    fi

    # Extract HUMAN-EDIT blocks from current docs (if any) for Claude's awareness
    HE_ZH="$(python3 "$SCRIPTS_DIR/lib/human_edit.py" extract "$DOC_ZH_PATH" 2>/dev/null || echo '[]')"
    HE_EN="$(python3 "$SCRIPTS_DIR/lib/human_edit.py" extract "$DOC_EN_PATH" 2>/dev/null || echo '[]')"
    HE_COUNT_ZH="$(echo "$HE_ZH" | jq 'length')"
    HE_COUNT_EN="$(echo "$HE_EN" | jq 'length')"
    TOTAL_HE=$((HE_COUNT_ZH + HE_COUNT_EN))

    # Source files list for frontmatter
    SRC_FILES_JSON="$(doc_sources "$CHAPTER" "$SLUG" | jq -R . | jq -s 'unique')"

    # Build sync-fields.md (reminder for Claude)
    NOW_TS="$(date -u -Iseconds)"
    {
        echo "# frontmatter 的 sync 字段"
        echo
        echo "请将以下字段精确填入生成文档的 frontmatter.sync："
        echo
        echo "- source_commit: \`$COMMIT\`"
        echo "- generated_at: \`$NOW_TS\`"
        echo "- generated_by: docs-sync v2"
        echo "- source_files:"
        echo "$SRC_FILES_JSON" | jq -r '.[]' | sed 's|^|  - |'
    } > "$WORK/sync-fields.md"

    # Copy style-guide and prompt
    cp "$PROMPTS_DIR/style-guide.md" "$WORK/style-guide.md"
    [ -f "$PROMPTS_DIR/$PROMPT_NAME" ] || die "Prompt missing: $PROMPT_NAME"
    cp "$PROMPTS_DIR/$PROMPT_NAME" "$WORK/prompt.md"

    # Output paths
    OUT_ZH="$DRAFT_BASE/$SLUG.md"
    OUT_EN="$DRAFT_EN/$SLUG.md"

    # Pre-frontmatter block (we give Claude the full ready-made frontmatter)
    PRE_FRONTMATTER_ZH="$(cat <<EOF
---
title: $TITLE_ZH
sync:
  source_commit: $COMMIT
  source_files:
$(echo "$SRC_FILES_JSON" | jq -r '.[]' | sed 's|^|    - |')
  generated_at: $NOW_TS
  generated_by: docs-sync v2
---
EOF
)"
    PRE_FRONTMATTER_EN="$(cat <<EOF
---
title: $TITLE_EN
sync:
  source_commit: $COMMIT
  source_files:
$(echo "$SRC_FILES_JSON" | jq -r '.[]' | sed 's|^|    - |')
  generated_at: $NOW_TS
  generated_by: docs-sync v2
---
EOF
)"

    # Combined invocation prompt
    COMBINED="$(cat <<EOF
工作目录: $WORK
章节: $CHAPTER
文档 slug: $SLUG
中文标题: $TITLE_ZH
英文标题: $TITLE_EN

请按 prompt.md 的说明执行。你需要读取的文件：
  - style-guide.md
  - prompt.md
  - sources.md
  - current-doc-zh.md
  - current-doc-en.md
  - sync-fields.md

输出必须写入以下绝对路径：
  OUTPUT_ZH = $OUT_ZH
  OUTPUT_EN = $OUT_EN

frontmatter 要求你原样使用以下两个预构 frontmatter 块（PRE_FRONTMATTER_ZH / PRE_FRONTMATTER_EN），放在各自文档的最开头：

---PRE_FRONTMATTER_ZH---
$PRE_FRONTMATTER_ZH
---END---

---PRE_FRONTMATTER_EN---
$PRE_FRONTMATTER_EN
---END---

HUMAN-EDIT 块（必须逐字保留在生成的新版中，仅在相应语言版本）：

HUMAN_EDIT_BLOCKS_ZH = $HE_ZH
HUMAN_EDIT_BLOCKS_EN = $HE_EN

完成后打印一行 DONE: wrote <OUTPUT_ZH> and <OUTPUT_EN>。
EOF
)"

    START=$SECONDS
    log "  [$SLUG] invoking claude (model=$MODEL)"
    if ! (cd "$WORK" && claude -p "$COMBINED" \
            --model "$MODEL" \
            --allowed-tools "Read,Write" \
            --permission-mode "acceptEdits"); then
        log "  [$SLUG] FAILED"
        audit_record_doc "$CHAPTER" "$SLUG" "failed" 0 0 0 0 "claude -p non-zero"
        continue
    fi
    ELAPSED=$((SECONDS - START))

    # Verify outputs exist and non-empty
    OK=1
    [ -s "$OUT_ZH" ] || OK=0
    [ -s "$OUT_EN" ] || OK=0
    if [ "$OK" = 0 ]; then
        log "  [$SLUG] draft empty or missing"
        audit_record_doc "$CHAPTER" "$SLUG" "empty_output" 0 0 0 0 "draft file empty"
        continue
    fi

    # Verify HUMAN-EDIT preservation (if original existed and had blocks)
    HBP=0
    if [ -f "$DOC_ZH_PATH" ] && [ "$HE_COUNT_ZH" -gt 0 ]; then
        if python3 "$SCRIPTS_DIR/lib/human_edit.py" verify "$DOC_ZH_PATH" "$OUT_ZH" >&2; then
            HBP=$((HBP + HE_COUNT_ZH))
        else
            log "  [$SLUG] HUMAN-EDIT verification FAILED (zh)"
            audit_record_doc "$CHAPTER" "$SLUG" "human_edit_lost" 0 0 0 0 "zh blocks missing"
            continue
        fi
    fi
    if [ -f "$DOC_EN_PATH" ] && [ "$HE_COUNT_EN" -gt 0 ]; then
        if python3 "$SCRIPTS_DIR/lib/human_edit.py" verify "$DOC_EN_PATH" "$OUT_EN" >&2; then
            HBP=$((HBP + HE_COUNT_EN))
        else
            log "  [$SLUG] HUMAN-EDIT verification FAILED (en)"
            audit_record_doc "$CHAPTER" "$SLUG" "human_edit_lost" 0 0 0 0 "en blocks missing"
            continue
        fi
    fi

    # Record success + save signature
    audit_record_doc "$CHAPTER" "$SLUG" "generated" 0 0 0 "$HBP" ""
    save_signature "$CHAPTER" "$SLUG" "$(compute_signature "$CHAPTER" "$SLUG")"
    log "  [$SLUG] generated in ${ELAPSED}s (human_blocks=$HBP)"
done

log "Full-generate: done"
```

- [ ] **Step 2: Make executable**

```bash
chmod +x scripts/lib/full_generate.sh
```

- [ ] **Step 3: Commit (defer real run to Task 24+)**

```bash
git add scripts/lib/full_generate.sh
git commit -m "feat(lib): add --full generator orchestrator"
```

---

## Task 17: `index_gen.sh` — chapter index.md generation

**Files:**
- Create: `scripts/lib/index_gen.sh`

- [ ] **Step 1: Write `scripts/lib/index_gen.sh`**

```bash
#!/usr/bin/env bash
# Generate <chapter>/index.md (zh+en) from drafts produced by full_generate.

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

CHAPTER="${1:?chapter required}"
chapter_exists "$CHAPTER" || die "Unknown chapter: $CHAPTER"

DRAFT_BASE="$DRAFTS_DIR/$CHAPTER"
DRAFT_EN="$DRAFTS_DIR/$CHAPTER/en"
mkdir -p "$DRAFT_BASE" "$DRAFT_EN"

WORK="$WORK_DIR/$CHAPTER/_index"
mkdir -p "$WORK"

SRC="$(abs_source_repo)"
COMMIT="$(git -C "$SRC" rev-parse HEAD)"
NOW_TS="$(date -u -Iseconds)"

# Build manifest.md listing every slug with its current draft title + first 2 lines of body
{
    echo "# Chapter manifest: $CHAPTER"
    echo
    echo "## Chapter titles"
    echo "- zh: $(chapter_title "$CHAPTER" zh)"
    echo "- en: $(chapter_title "$CHAPTER" en)"
    echo
    echo "## Docs in this chapter"
    while IFS= read -r slug; do
        [ -z "$slug" ] && continue
        TZ="$(doc_title "$CHAPTER" "$slug" zh)"
        TE="$(doc_title "$CHAPTER" "$slug" en)"
        echo
        echo "### $slug"
        echo "- title_zh: $TZ"
        echo "- title_en: $TE"
        echo "- link: ./$slug"
        # Try to include a one-line summary from the draft if it exists
        if [ -f "$DRAFT_BASE/$slug.md" ]; then
            FIRST_PARA="$(awk '/^---$/{c++;next} c==2 && NF{print; exit}' "$DRAFT_BASE/$slug.md" || true)"
            echo "- lead_zh: $FIRST_PARA"
        fi
        if [ -f "$DRAFT_EN/$slug.md" ]; then
            FIRST_PARA_EN="$(awk '/^---$/{c++;next} c==2 && NF{print; exit}' "$DRAFT_EN/$slug.md" || true)"
            echo "- lead_en: $FIRST_PARA_EN"
        fi
    done <<< "$(chapter_doc_slugs "$CHAPTER")"
} > "$WORK/chapter-manifest.md"

# sync-fields.md
SRC_FILES_JSON='["(chapter index — aggregated)"]'
{
    echo "# frontmatter 的 sync 字段"
    echo
    echo "source_commit: \`$COMMIT\`"
    echo "generated_at: \`$NOW_TS\`"
    echo "generated_by: docs-sync v2 (index)"
} > "$WORK/sync-fields.md"

cp "$PROMPTS_DIR/style-guide.md" "$WORK/style-guide.md"
cp "$PROMPTS_DIR/chapter-index.md" "$WORK/prompt.md"

OUT_ZH="$DRAFT_BASE/index.md"
OUT_EN="$DRAFT_EN/index.md"

TITLE_ZH="$(chapter_title "$CHAPTER" zh)"
TITLE_EN="$(chapter_title "$CHAPTER" en)"

PRE_FM_ZH="$(cat <<EOF
---
title: $TITLE_ZH
sync:
  source_commit: $COMMIT
  source_files:
    - (chapter index — aggregated)
  generated_at: $NOW_TS
  generated_by: docs-sync v2
---
EOF
)"
PRE_FM_EN="$(cat <<EOF
---
title: $TITLE_EN
sync:
  source_commit: $COMMIT
  source_files:
    - (chapter index — aggregated)
  generated_at: $NOW_TS
  generated_by: docs-sync v2
---
EOF
)"

MODEL="$(yaml_get '.models.default' | tr -d '"')"

COMBINED="$(cat <<EOF
工作目录: $WORK
章节: $CHAPTER
任务: 生成章节入口页 index.md

阅读 prompt.md 按要求执行。

OUTPUT_ZH = $OUT_ZH
OUTPUT_EN = $OUT_EN

PRE_FRONTMATTER_ZH:
$PRE_FM_ZH

PRE_FRONTMATTER_EN:
$PRE_FM_EN

完成后打印 DONE: wrote <OUTPUT_ZH> and <OUTPUT_EN>。
EOF
)"

log "Index gen: chapter=$CHAPTER"
(cd "$WORK" && claude -p "$COMBINED" \
        --model "$MODEL" \
        --allowed-tools "Read,Write" \
        --permission-mode "acceptEdits") || die "Index generation failed"

log "Index: $OUT_ZH + $OUT_EN"
```

- [ ] **Step 2: Make executable + commit (defer real run)**

```bash
chmod +x scripts/lib/index_gen.sh
git add scripts/lib/index_gen.sh
git commit -m "feat(lib): add chapter index.md generator"
```

---

## Task 18: `sidebar_gen.sh` — VitePress sidebar fragment

**Files:**
- Create: `scripts/lib/sidebar_gen.sh`

Emits a JSON array that can be pasted into `docs/.vitepress/config.mts`'s sidebar object at key `/${chapter}/`.

- [ ] **Step 1: Write `scripts/lib/sidebar_gen.sh`**

```bash
#!/usr/bin/env bash
# Emit a VitePress sidebar JSON fragment for one chapter.
# Output: drafts/sidebar/<chapter>.json + drafts/sidebar/<chapter>-en.json

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

CHAPTER="${1:?chapter required}"
chapter_exists "$CHAPTER" || die "Unknown chapter: $CHAPTER"

OUT_DIR="$DRAFTS_DIR/sidebar"
mkdir -p "$OUT_DIR"

TITLE_ZH="$(chapter_title "$CHAPTER" zh)"
TITLE_EN="$(chapter_title "$CHAPTER" en)"

python3 - "$CHAPTER" "$CONFIG_FILE" "$OUT_DIR" "$TITLE_ZH" "$TITLE_EN" <<'PYEOF'
import sys, yaml, json, os

chapter, config_path, out_dir, title_zh, title_en = sys.argv[1:6]
cfg = yaml.safe_load(open(config_path))
ch = cfg["chapters"][chapter]

def fragment(lang_title_key, lang_prefix):
    items = []
    for d in ch["docs"]:
        slug = d["slug"]
        title = d[lang_title_key]
        link = f"{lang_prefix}/{chapter}/{slug}" if lang_prefix else f"/{chapter}/{slug}"
        if slug == "index":
            link = f"{lang_prefix}/{chapter}/" if lang_prefix else f"/{chapter}/"
        items.append({"text": title, "link": link})
    return [{"text": ch[lang_title_key], "items": items}]

with open(os.path.join(out_dir, f"{chapter}.json"), "w", encoding="utf-8") as f:
    json.dump(fragment("title_zh", ""), f, ensure_ascii=False, indent=2)

with open(os.path.join(out_dir, f"{chapter}-en.json"), "w", encoding="utf-8") as f:
    json.dump(fragment("title_en", "/en"), f, ensure_ascii=False, indent=2)

print(f"Wrote {chapter}.json and {chapter}-en.json to {out_dir}", file=sys.stderr)
PYEOF
```

- [ ] **Step 2: Make executable + run for features**

```bash
chmod +x scripts/lib/sidebar_gen.sh
bash scripts/lib/sidebar_gen.sh features
cat drafts/sidebar/features.json
```

Expected output — a JSON array, first (and only) group titled "功能特性" with 7 items (MCP 服务器, Sandbox 沙箱运行时, ...).

- [ ] **Step 3: Commit**

```bash
git add scripts/lib/sidebar_gen.sh
git commit -m "feat(lib): add VitePress sidebar JSON fragment generator"
```

---

## Task 19: `estimate.sh` — cost preview

**Files:**
- Create: `scripts/lib/estimate.sh`

Reads `work-plan.json`, for each `to_generate` item: counts source bytes → estimate tokens (bytes/4) → estimate cost using pricing from config.

- [ ] **Step 1: Write `scripts/lib/estimate.sh`**

```bash
#!/usr/bin/env bash
# Print estimate of token usage & cost for the current work-plan.
# No API calls.

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

PLAN_FILE="$STATE_DIR/work-plan.json"
[ -f "$PLAN_FILE" ] || die "No work-plan.json — run resolve first."

CHAPTER="$(jq -r '.chapter' "$PLAN_FILE")"
SRC="$(abs_source_repo)"

INPUT_PRICE_DEFAULT="$(yaml_get '.run.pricing.default.input_per_mtok' | tr -d '"')"
OUTPUT_PRICE_DEFAULT="$(yaml_get '.run.pricing.default.output_per_mtok' | tr -d '"')"
INPUT_PRICE_COMPLEX="$(yaml_get '.run.pricing.complex.input_per_mtok' | tr -d '"')"
OUTPUT_PRICE_COMPLEX="$(yaml_get '.run.pricing.complex.output_per_mtok' | tr -d '"')"

python3 - "$PLAN_FILE" "$SRC" "$CONFIG_FILE" \
    "$INPUT_PRICE_DEFAULT" "$OUTPUT_PRICE_DEFAULT" \
    "$INPUT_PRICE_COMPLEX" "$OUTPUT_PRICE_COMPLEX" <<'PYEOF'
import sys, json, yaml, glob, os

plan_path, src, config_path, ipd, opd, ipc, opc = sys.argv[1:8]
ipd, opd, ipc, opc = float(ipd), float(opd), float(ipc), float(opc)

plan = json.load(open(plan_path))
cfg = yaml.safe_load(open(config_path))
chapter = plan["chapter"]
ch_cfg = cfg["chapters"][chapter]

def sources_for(slug):
    for d in ch_cfg["docs"]:
        if d["slug"] == slug:
            return d["sources"]
    return []

def expand_and_measure(patterns):
    total = 0
    files = 0
    for pat in patterns:
        for p in sorted(glob.glob(os.path.join(src, pat), recursive=True)):
            if os.path.isfile(p):
                try:
                    total += os.path.getsize(p)
                    files += 1
                except OSError:
                    pass
    return total, files

total_in, total_out, total_cost = 0, 0, 0.0
rows = []
for item in plan["items"]:
    if item["status"] != "to_generate":
        continue
    bytes_, n_files = expand_and_measure(sources_for(item["slug"]))
    # ~4 chars per token; double for zh+en generation; assume output ~30% of input
    in_tok = bytes_ // 4
    out_tok = int(in_tok * 0.3) * 2  # zh + en
    if item["model"] == "complex":
        cost = (in_tok * ipc + out_tok * opc) / 1_000_000
    else:
        cost = (in_tok * ipd + out_tok * opd) / 1_000_000
    total_in += in_tok
    total_out += out_tok
    total_cost += cost
    rows.append((item["slug"], n_files, in_tok, out_tok, cost))

print(f"Chapter '{chapter}' — {len(rows)} doc(s) to generate:")
print(f"  {'slug':<30} {'files':>6} {'tok_in':>8} {'tok_out':>8} {'$':>8}")
for slug, n, ti, to, c in rows:
    print(f"  {slug:<30} {n:>6} {ti:>8,} {to:>8,} {c:>7.3f}")
print(f"  {'TOTAL':<30} {'':>6} {total_in:>8,} {total_out:>8,} {total_cost:>7.3f}")
print(f"\nEstimate: ~${total_cost:.2f} USD total (model pricing from config.yaml)")
PYEOF
```

- [ ] **Step 2: Test**

```bash
chmod +x scripts/lib/estimate.sh
# resolve features first (creates work-plan.json)
bash scripts/lib/resolve.sh features
bash scripts/lib/estimate.sh
```

Expected: table with 7 rows + TOTAL line; an "Estimate: ~$X.XX USD total" summary.

- [ ] **Step 3: Commit**

```bash
git add scripts/lib/estimate.sh
git commit -m "feat(lib): add estimate.sh — token/cost preview without API"
```

---

## Task 20: `llms_txt.sh` — aggregate docs for LLM consumption

**Files:**
- Create: `scripts/lib/llms_txt.sh`

- [ ] **Step 1: Write `scripts/lib/llms_txt.sh`**

```bash
#!/usr/bin/env bash
# Generate /public/llms.txt (index) and /public/llms-full.txt (concatenation).
# Run at the end of every sync run, or via sync.sh --emit-llms-txt.

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

mkdir -p "$LLMS_TXT_DIR"

INDEX="$LLMS_TXT_DIR/llms.txt"
FULL="$LLMS_TXT_DIR/llms-full.txt"

# We walk docs/**/*.md, skipping en/ mirror, skipping hidden, skipping .vitepress
python3 - "$DOCS_DIR" "$INDEX" "$FULL" <<'PYEOF'
import os, sys, re

docs_root, index_path, full_path = sys.argv[1:4]

def walk():
    out = []
    for root, dirs, files in os.walk(docs_root):
        # Prune
        dirs[:] = [d for d in dirs if not d.startswith('.') and d not in ('public', 'node_modules', 'en')]
        for name in sorted(files):
            if not name.endswith('.md'):
                continue
            rel = os.path.relpath(os.path.join(root, name), docs_root)
            out.append(rel)
    return sorted(out)

def first_h1(text):
    m = re.search(r"^#\s+(.+)$", text, re.MULTILINE)
    return m.group(1).strip() if m else None

def first_para_after_h1(text):
    lines = text.splitlines()
    seen_h1 = False
    buf = []
    for line in lines:
        if line.startswith('---'):
            continue
        if not seen_h1:
            if line.startswith('# '):
                seen_h1 = True
            continue
        s = line.strip()
        if not s:
            if buf: break
            else: continue
        if s.startswith('#'):
            if buf: break
            else: continue
        buf.append(s)
    return ' '.join(buf)[:200]

entries = []
full_chunks = []
for rel in walk():
    path = os.path.join(docs_root, rel)
    try:
        text = open(path, encoding='utf-8').read()
    except Exception:
        continue
    title = first_h1(text) or rel
    lead = first_para_after_h1(text) or ''
    url = '/' + rel[:-3]  # strip .md
    entries.append((title, url, lead, rel))
    full_chunks.append(f"\n\n========== {rel} ==========\n\n{text}")

# Write index
with open(index_path, 'w', encoding='utf-8') as f:
    f.write("# Nexus-AI Playbook — Docs Index for LLMs\n\n")
    f.write("One line per document: `- [Title](URL) — summary`.\n\n")
    for title, url, lead, rel in entries:
        f.write(f"- [{title}]({url}) — {lead}\n")

with open(full_path, 'w', encoding='utf-8') as f:
    f.write("# Nexus-AI Playbook — Full Docs Aggregation for LLMs\n")
    f.write("Concatenated content of all markdown files under docs/.\n")
    for chunk in full_chunks:
        f.write(chunk)

print(f"Wrote {len(entries)} entries to {index_path}")
print(f"Wrote {sum(len(c) for c in full_chunks)} chars to {full_path}")
PYEOF
```

- [ ] **Step 2: Test**

```bash
chmod +x scripts/lib/llms_txt.sh
bash scripts/lib/llms_txt.sh
ls -la docs/public/llms*.txt
head -10 docs/public/llms.txt
```

Expected: two files exist; `llms.txt` starts with `# Nexus-AI Playbook — Docs Index for LLMs` and lists ~20 lines (one per existing doc).

- [ ] **Step 3: Commit (but do NOT stage the generated files yet — they'll be committed when content is final)**

```bash
rm docs/public/llms.txt docs/public/llms-full.txt
git add scripts/lib/llms_txt.sh
git commit -m "feat(lib): add llms.txt generator for LLM-friendly consumption"
```

---

## Task 21: Extend `sync.sh` with v2 CLI flags

**Files:**
- Modify: `scripts/sync.sh`

- [ ] **Step 1: Read current sync.sh**

Run: `cat scripts/sync.sh`
Expected: see existing v1 flags `--dry-run`, `--only-detect`, `--mapping`, `--from`, `--to`, `--init`, `--commit-sync`.

- [ ] **Step 2: Rewrite sync.sh with v2 extensions (preserving all v1 flags)**

Overwrite `scripts/sync.sh` with:

```bash
#!/usr/bin/env bash
# Main entry. Orchestrates both v1 (incremental) and v2 (full chapter) pipelines.
set -euo pipefail
source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/lib/common.sh"

MODE="full"            # full-sync (v1 default) | dry-run | only-detect | init | commit-sync | full-gen | list-chapters | regen-index | regen-sidebar | estimate | emit-llms-txt
FROM_SHA=""
TO_SHA=""
ONLY_MAPPING=""
INIT_SHA=""
CHAPTER=""
DOC_FILTER=""
FORCE=""

usage() {
    cat <<EOF
Usage: $0 [v1 flags] [v2 flags]

v1 flags (incremental-patch pipeline):
  --dry-run                     detect+prepare only
  --only-detect                 detect only
  --mapping <id>                restrict to one mapping
  --from <sha> --to <sha>       override commit range
  --init <sha>                  set last_sync.json baseline
  --commit-sync                 bump last_sync.json to current changes.json's to_sha

v2 flags (full chapter generation):
  --full --chapter <name>       generate a whole chapter
  --doc <slug>                  (with --full) restrict to one doc
  --force-regenerate            (with --full) ignore signatures
  --estimate                    print cost/token estimate, no API calls
  --list-chapters               print configured chapters
  --regenerate-index            (with --chapter) regenerate index.md only
  --regenerate-sidebar          (with --chapter) regenerate sidebar fragment only
  --emit-llms-txt               (re)generate docs/public/llms*.txt
EOF
    exit 2
}

while [ $# -gt 0 ]; do
    case "$1" in
        # v1 flags
        --dry-run)            MODE="dry-run"; shift ;;
        --only-detect)        MODE="only-detect"; shift ;;
        --mapping)            ONLY_MAPPING="${2:-}"; shift 2 ;;
        --from)               FROM_SHA="${2:-}"; shift 2 ;;
        --to)                 TO_SHA="${2:-}"; shift 2 ;;
        --init)               MODE="init"; INIT_SHA="${2:-}"; shift 2 ;;
        --commit-sync)        MODE="commit-sync"; shift ;;
        # v2 flags
        --full)               MODE="full-gen"; shift ;;
        --chapter)            CHAPTER="${2:-}"; shift 2 ;;
        --doc)                DOC_FILTER="${2:-}"; shift 2 ;;
        --force-regenerate)   FORCE="force"; shift ;;
        --estimate)           MODE="estimate"; shift ;;
        --list-chapters)      MODE="list-chapters"; shift ;;
        --regenerate-index)   MODE="regen-index"; shift ;;
        --regenerate-sidebar) MODE="regen-sidebar"; shift ;;
        --emit-llms-txt)      MODE="emit-llms-txt"; shift ;;
        -h|--help)            usage ;;
        *)                    log "Unknown flag: $1"; usage ;;
    esac
done

source "$SCRIPTS_DIR/lib/audit.sh"

# ---- v1 sub-modes without pipeline ----
if [ "$MODE" = "init" ]; then
    [ -n "$INIT_SHA" ] || die "--init requires a SHA"
    SRC="$(abs_source_repo)"
    INIT_SHA="$(git -C "$SRC" rev-parse "$INIT_SHA")"
    jq --arg sha "$INIT_SHA" --arg ts "$(date -Iseconds)" \
        '.last_commit_sha=$sha | .timestamp=$ts | .mappings_synced=[]' \
        "$STATE_DIR/last_sync.json" > "$STATE_DIR/last_sync.json.tmp"
    mv "$STATE_DIR/last_sync.json.tmp" "$STATE_DIR/last_sync.json"
    log "Init: last_sync.json set to $INIT_SHA"
    exit 0
fi

if [ "$MODE" = "commit-sync" ]; then
    [ -f "$STATE_DIR/changes.json" ] || die "No changes.json to draw TO sha from"
    TO="$(jq -r '.to_sha' "$STATE_DIR/changes.json")"
    [ "$TO" != "null" ] && [ -n "$TO" ] || die "Invalid to_sha in changes.json"
    IDS="$(jq -c '[.triggered_mappings[].id]' "$STATE_DIR/changes.json")"
    jq --arg sha "$TO" --arg ts "$(date -Iseconds)" --argjson ids "$IDS" \
        '.last_commit_sha=$sha | .timestamp=$ts | .mappings_synced=$ids' \
        "$STATE_DIR/last_sync.json" > "$STATE_DIR/last_sync.json.tmp"
    mv "$STATE_DIR/last_sync.json.tmp" "$STATE_DIR/last_sync.json"
    log "Commit-sync: last_sync.json now at $TO"
    exit 0
fi

# ---- v2 sub-modes ----
if [ "$MODE" = "list-chapters" ]; then
    yaml_get '.chapters | keys[]' | tr -d '"'
    exit 0
fi

if [ "$MODE" = "emit-llms-txt" ]; then
    bash "$SCRIPTS_DIR/lib/llms_txt.sh"
    exit 0
fi

if [ "$MODE" = "regen-sidebar" ]; then
    [ -n "$CHAPTER" ] || die "--regenerate-sidebar requires --chapter"
    bash "$SCRIPTS_DIR/lib/sidebar_gen.sh" "$CHAPTER"
    exit 0
fi

if [ "$MODE" = "regen-index" ]; then
    [ -n "$CHAPTER" ] || die "--regenerate-index requires --chapter"
    bash "$SCRIPTS_DIR/lib/index_gen.sh" "$CHAPTER"
    exit 0
fi

if [ "$MODE" = "estimate" ]; then
    [ -n "$CHAPTER" ] || die "--estimate requires --chapter"
    bash "$SCRIPTS_DIR/lib/resolve.sh" "$CHAPTER" "$DOC_FILTER" "$FORCE"
    bash "$SCRIPTS_DIR/lib/estimate.sh"
    exit 0
fi

if [ "$MODE" = "full-gen" ]; then
    [ -n "$CHAPTER" ] || die "--full requires --chapter"
    audit_start "full" "$CHAPTER" "cli"
    bash "$SCRIPTS_DIR/lib/resolve.sh" "$CHAPTER" "$DOC_FILTER" "$FORCE"
    bash "$SCRIPTS_DIR/lib/full_generate.sh"
    bash "$SCRIPTS_DIR/lib/index_gen.sh" "$CHAPTER"
    bash "$SCRIPTS_DIR/lib/sidebar_gen.sh" "$CHAPTER"
    bash "$SCRIPTS_DIR/lib/llms_txt.sh"
    bash "$SCRIPTS_DIR/lib/output.sh" || log "output.sh non-fatal failure"
    audit_finish 0
    log "Full-gen done. See drafts/SUMMARY.md and drafts/$CHAPTER/"
    exit 0
fi

# ---- v1 incremental pipeline (unchanged) ----
bash "$SCRIPTS_DIR/lib/detect.sh" "$FROM_SHA" "${TO_SHA:-HEAD}"

if [ -n "$ONLY_MAPPING" ]; then
    jq --arg id "$ONLY_MAPPING" \
        '.triggered_mappings = [ .triggered_mappings[] | select(.id==$id) ]' \
        "$STATE_DIR/changes.json" > "$STATE_DIR/changes.json.tmp"
    mv "$STATE_DIR/changes.json.tmp" "$STATE_DIR/changes.json"
    COUNT="$(jq '.triggered_mappings | length' "$STATE_DIR/changes.json")"
    log "Filter --mapping $ONLY_MAPPING: $COUNT mapping(s) remain"
fi

[ "$MODE" = "only-detect" ] && exit 0

bash "$SCRIPTS_DIR/lib/prepare.sh"

[ "$MODE" = "dry-run" ] && { log "Dry-run complete"; exit 0; }

bash "$SCRIPTS_DIR/lib/generate.sh"
bash "$SCRIPTS_DIR/lib/screenshot.sh" || log "Screenshot stage non-fatal failure"
bash "$SCRIPTS_DIR/lib/output.sh"

log "Done. See drafts/SUMMARY.md"
```

- [ ] **Step 3: Smoke-test new flags**

```bash
chmod +x scripts/sync.sh
./scripts/sync.sh --list-chapters
```

Expected:
```
features
integrations
tutorials
developer
reference
glossary
```

- [ ] **Step 4: Smoke-test estimate**

```bash
./scripts/sync.sh --estimate --chapter features
```

Expected: cost table with 7 rows + TOTAL. Does NOT call Claude (zero API cost).

- [ ] **Step 5: Smoke-test regen-sidebar (cheap, no API)**

```bash
./scripts/sync.sh --regenerate-sidebar --chapter features
cat drafts/sidebar/features.json
```

Expected: features.json with 7 items.

- [ ] **Step 6: Regression — v1 only-detect still works**

```bash
FROM=$(git -C /home/ubuntu/mydev/Nexus-AI rev-parse HEAD~30)
TO=$(git -C /home/ubuntu/mydev/Nexus-AI rev-parse HEAD)
./scripts/sync.sh --only-detect --from "$FROM" --to "$TO"
jq '.triggered_mappings | length' scripts/state/changes.json
```

Expected: integer ≥ 0 (v1 pipeline unaffected).

- [ ] **Step 7: Commit**

```bash
git add scripts/sync.sh
git commit -m "feat(sync): extend CLI with v2 full-chapter flags, preserve v1 flags"
```

---

## Task 22: VitePress `SyncFreshness.vue` theme component

**Files:**
- Create: `docs/.vitepress/theme/SyncFreshness.vue`
- Create: `docs/.vitepress/theme/index.ts` (only if absent)
- Modify: existing theme if present

- [ ] **Step 1: Check current theme**

Run: `ls docs/.vitepress/theme/`
Expected: may already have `index.ts` or may be empty.

- [ ] **Step 2: Write `SyncFreshness.vue`**

```vue
<template>
  <div v-if="syncInfo" class="sync-freshness">
    📅 本页基于 Nexus-AI commit
    <code>{{ syncInfo.source_commit.slice(0, 8) }}</code>
    于 <time :datetime="syncInfo.generated_at">{{ formatDate(syncInfo.generated_at) }}</time>
    由 <code>{{ syncInfo.generated_by }}</code> 自动生成。
    如发现过时，请 <a :href="issueUrl" target="_blank">报告问题</a>。
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useData } from 'vitepress'

const { frontmatter } = useData()
const syncInfo = computed(() => (frontmatter.value as any).sync)
const issueUrl = 'https://github.com/hy714335634/Nexus-AI-Playbook/issues/new?title=Docs+issue'

function formatDate(iso: string) {
  try { return new Date(iso).toISOString().split('T')[0] } catch { return iso }
}
</script>

<style scoped>
.sync-freshness {
  font-size: 0.85em;
  color: var(--vp-c-text-2);
  background: var(--vp-c-bg-soft);
  border-left: 3px solid var(--vp-c-brand-1);
  padding: 8px 12px;
  margin: 8px 0 24px;
  border-radius: 4px;
}
.sync-freshness code {
  font-size: inherit;
  padding: 1px 4px;
}
.sync-freshness a {
  color: var(--vp-c-brand-1);
}
</style>
```

- [ ] **Step 3: Ensure theme index.ts registers the component**

Run: `ls docs/.vitepress/theme/index.ts 2>/dev/null || echo "missing"`

If missing, create `docs/.vitepress/theme/index.ts`:

```ts
import DefaultTheme from 'vitepress/theme'
import SyncFreshness from './SyncFreshness.vue'
import type { Theme } from 'vitepress'

export default {
  extends: DefaultTheme,
  enhanceApp({ app }) {
    app.component('SyncFreshness', SyncFreshness)
  }
} satisfies Theme
```

If it exists, read its content and merge — add the import and `app.component` registration without removing other customizations.

- [ ] **Step 4: Verify VitePress still builds**

```bash
npm run docs:build 2>&1 | tail -5
```

Expected: "build complete" or similar. If any error, fix syntax in the vue/ts file.

- [ ] **Step 5: Commit**

```bash
git add docs/.vitepress/theme/
git commit -m "feat(theme): add SyncFreshness component for doc freshness marker"
```

---

## Task 23: Update `config.mts` — editLink + nav/sidebar placeholders

**Files:**
- Modify: `docs/.vitepress/config.mts`

- [ ] **Step 1: Read current config**

Run: `cat docs/.vitepress/config.mts`

- [ ] **Step 2: Add `editLink` inside `themeConfig`**

Edit `docs/.vitepress/config.mts`. Inside the `themeConfig: { ... }` block, add after the `socialLinks` entry (before `footer`):

```ts
    editLink: {
      pattern: 'https://github.com/hy714335634/Nexus-AI-Playbook/edit/main/docs/:path',
      text: '在 GitHub 上编辑此页'
    },
```

- [ ] **Step 3: Extend `nav` with new chapter entries**

In the `nav: [ ... ]` array inside `themeConfig`, replace the existing array with:

```ts
    nav: [
      { text: '首页', link: '/' },
      { text: '快速上手', link: '/guide/login' },
      {
        text: '使用手册',
        items: [
          { text: '🏠 工作台', link: '/using/dashboard' },
          { text: '🤖 创建 Agent', link: '/using/create-agent' },
          { text: '📊 构建进度', link: '/using/build-progress' },
          { text: '📋 项目管理', link: '/using/projects' },
          { text: '🗂️ 管理 Agent', link: '/using/manage-agents' },
          { text: '💬 对话测试', link: '/using/chat' },
          { text: '🔧 能力工具', link: '/using/tools' },
          { text: '🔌 MCP 服务器', link: '/using/mcp' },
        ]
      },
      { text: '功能特性', link: '/features/' },
      { text: '集成', link: '/integrations/' },
      { text: '教程', link: '/tutorials/' },
      { text: '开发者', link: '/developer/' },
      { text: '参考', link: '/reference/' },
      {
        text: '了解更多',
        items: [
          { text: '💡 平台概述', link: '/overview/what-is-nexus' },
          { text: '⚙️ 构建原理', link: '/overview/how-it-works' },
          { text: '🛡️ 管理员指南', link: '/admin/settings' },
          { text: '📖 术语表', link: '/glossary/' },
          { text: '❓ 常见问题', link: '/faq' },
        ]
      },
    ],
```

- [ ] **Step 4: Extend `sidebar` with empty placeholders for each new chapter**

In the `sidebar: { ... }` object inside `themeConfig`, add these keys alongside the existing `/guide/`, `/using/`, `/overview/`, `/admin/` entries (keeping existing entries intact):

```ts
      '/features/': [
        { text: '⚡ 功能特性', items: [] }
      ],
      '/integrations/': [
        { text: '🔌 集成', items: [] }
      ],
      '/tutorials/': [
        { text: '📚 教程', items: [] }
      ],
      '/developer/': [
        { text: '👨‍💻 开发者指南', items: [] }
      ],
      '/reference/': [
        { text: '📋 参考', items: [] }
      ],
      '/glossary/': [
        { text: '📖 术语表', items: [
          { text: 'Nexus-AI 术语表', link: '/glossary/' }
        ] }
      ],
```

The empty `items: []` will be populated by pasting contents of `drafts/sidebar/<chapter>.json` after each chapter's full-gen completes (per Task 24+).

- [ ] **Step 5: Verify build still works**

```bash
npm run docs:build 2>&1 | tail -10
```

Expected: build succeeds. Dead links to `/features/` etc. may show as warnings — fine, those targets get generated shortly.

- [ ] **Step 6: Commit**

```bash
git add docs/.vitepress/config.mts
git commit -m "feat(config): add editLink + nav/sidebar for v2 chapters"
```

---

## Task 24: Full-generate `features` chapter

**Files:** (generated) `drafts/features/*.md`, `drafts/features/en/*.md`, `drafts/features/index.md`, `drafts/sidebar/features.json`

- [ ] **Step 1: Estimate first**

```bash
./scripts/sync.sh --estimate --chapter features
```

Expected: cost table. Review totals. If > $5, reconsider scope.

- [ ] **Step 2: Run full-gen**

```bash
./scripts/sync.sh --full --chapter features 2>&1 | tee /tmp/features-run.log
```

Expected: log shows 7 docs being generated, each with "invoking claude" → "generated in N s". Total runtime likely 5–15 minutes.

If any doc fails, the loop continues; check `scripts/state/runs/*.json` for which failed, then use `--doc <slug> --force-regenerate` for targeted retries.

- [ ] **Step 3: Inspect outputs**

```bash
ls drafts/features/
ls drafts/features/en/
head -30 drafts/features/mcp-server.md
head -30 drafts/features/en/mcp-server.md
```

Expected: 8 files each (7 docs + index.md), frontmatter includes `sync.source_commit` etc., H1 matches the chapter config's title.

- [ ] **Step 4: Inspect SUMMARY + audit**

```bash
cat drafts/SUMMARY.md 2>/dev/null | head -30
cat scripts/state/runs/*.json | tail -1 | jq '.docs | map({slug, status})'
```

Expected: audit shows 7 generated (or skipped_signature if any matched), exit_code 0.

- [ ] **Step 5: Merge features drafts into docs/ (human decision)**

Review each draft, then:

```bash
mkdir -p docs/features/en
cp drafts/features/*.md docs/features/ 2>/dev/null
cp drafts/features/en/*.md docs/features/en/ 2>/dev/null
```

- [ ] **Step 6: Paste sidebar fragment into config.mts**

Open `docs/.vitepress/config.mts`, find `'/features/': [ ... ]`, replace its contents with the array from `drafts/sidebar/features.json`. For the English mirror sidebar, do the same under `'/en/features/':` (add that key if absent).

Verify the site builds: `npm run docs:build 2>&1 | tail -5`

- [ ] **Step 7: Commit**

```bash
git add docs/features/ docs/.vitepress/config.mts scripts/state/runs/ scripts/state/signatures/
git commit -m "docs(features): generate 7 feature docs (zh+en) + sidebar"
```

---

## Task 25: Full-generate `integrations` chapter

**Files:** (generated) `drafts/integrations/*.md`, `drafts/integrations/en/*.md`, `drafts/integrations/index.md`, `drafts/sidebar/integrations.json`

- [ ] **Step 1: Estimate**

```bash
./scripts/sync.sh --estimate --chapter integrations
```

- [ ] **Step 2: Run full-gen**

```bash
./scripts/sync.sh --full --chapter integrations 2>&1 | tee /tmp/integrations-run.log
```

Expected: 5 docs generated.

- [ ] **Step 3: Inspect + Merge**

```bash
ls drafts/integrations/ drafts/integrations/en/
# Review a sample
head -30 drafts/integrations/aws-bedrock.md
# If acceptable:
mkdir -p docs/integrations/en
cp drafts/integrations/*.md docs/integrations/
cp drafts/integrations/en/*.md docs/integrations/en/
```

- [ ] **Step 4: Paste sidebar fragment**

Open `docs/.vitepress/config.mts`, replace `'/integrations/': [...]` items with contents of `drafts/sidebar/integrations.json`.

- [ ] **Step 5: Build check**

```bash
npm run docs:build 2>&1 | tail -5
```

Expected: build succeeds.

- [ ] **Step 6: Commit**

```bash
git add docs/integrations/ docs/.vitepress/config.mts scripts/state/runs/ scripts/state/signatures/
git commit -m "docs(integrations): generate 5 integration docs (zh+en) + sidebar"
```

---

## Task 26: Full-generate `tutorials` chapter

**Files:** (generated) `drafts/tutorials/*.md`, `drafts/tutorials/en/*.md`, `drafts/tutorials/index.md`, `drafts/sidebar/tutorials.json`

- [ ] **Step 1: Estimate + run**

```bash
./scripts/sync.sh --estimate --chapter tutorials
./scripts/sync.sh --full --chapter tutorials 2>&1 | tee /tmp/tutorials-run.log
```

Expected: 3 docs generated.

- [ ] **Step 2: Inspect + merge**

```bash
ls drafts/tutorials/ drafts/tutorials/en/
head -50 drafts/tutorials/hermes-analyst.md
# If acceptable:
mkdir -p docs/tutorials/en
cp drafts/tutorials/*.md docs/tutorials/
cp drafts/tutorials/en/*.md docs/tutorials/en/
```

- [ ] **Step 3: Paste sidebar fragment into `'/tutorials/': [...]` of `config.mts`**

- [ ] **Step 4: Build check + commit**

```bash
npm run docs:build 2>&1 | tail -5
git add docs/tutorials/ docs/.vitepress/config.mts scripts/state/runs/ scripts/state/signatures/
git commit -m "docs(tutorials): generate 3 tutorial docs (zh+en) + sidebar"
```

---

## Task 27: Full-generate `developer` chapter

**Files:** (generated) `drafts/developer/*.md`, `drafts/developer/en/*.md`, `drafts/developer/index.md`, `drafts/sidebar/developer.json`

- [ ] **Step 1: Estimate + run**

```bash
./scripts/sync.sh --estimate --chapter developer
./scripts/sync.sh --full --chapter developer 2>&1 | tee /tmp/developer-run.log
```

Expected: 4 docs generated.

- [ ] **Step 2: Inspect + merge**

```bash
ls drafts/developer/ drafts/developer/en/
head -50 drafts/developer/architecture-overview.md
# If acceptable:
mkdir -p docs/developer/en
cp drafts/developer/*.md docs/developer/
cp drafts/developer/en/*.md docs/developer/en/
```

- [ ] **Step 3: Paste sidebar fragment into `'/developer/': [...]` of `config.mts`**

- [ ] **Step 4: Build check + commit**

```bash
npm run docs:build 2>&1 | tail -5
git add docs/developer/ docs/.vitepress/config.mts scripts/state/runs/ scripts/state/signatures/
git commit -m "docs(developer): generate 4 developer docs (zh+en) + sidebar"
```

---

## Task 28: Full-generate `reference` chapter

**Files:** (generated) `drafts/reference/*.md`, `drafts/reference/en/*.md`, `drafts/reference/index.md`, `drafts/sidebar/reference.json`

- [ ] **Step 1: Estimate + run**

```bash
./scripts/sync.sh --estimate --chapter reference
./scripts/sync.sh --full --chapter reference 2>&1 | tee /tmp/reference-run.log
```

Expected: 4 docs generated. Note: api-endpoints may be token-heavy; ensure `--estimate` shows < $3 before running.

- [ ] **Step 2: Inspect + merge**

```bash
ls drafts/reference/ drafts/reference/en/
head -50 drafts/reference/cli-commands.md
# If acceptable:
mkdir -p docs/reference/en
cp drafts/reference/*.md docs/reference/
cp drafts/reference/en/*.md docs/reference/en/
```

- [ ] **Step 3: Paste sidebar fragment into `'/reference/': [...]` of `config.mts`**

- [ ] **Step 4: Build check + commit**

```bash
npm run docs:build 2>&1 | tail -5
git add docs/reference/ docs/.vitepress/config.mts scripts/state/runs/ scripts/state/signatures/
git commit -m "docs(reference): generate 4 reference docs (zh+en) + sidebar"
```

---

## Task 29: Full-generate `glossary` chapter

**Files:** (generated) `drafts/glossary/index.md`, `drafts/glossary/en/index.md`

- [ ] **Step 1: Estimate + run**

```bash
./scripts/sync.sh --estimate --chapter glossary
./scripts/sync.sh --full --chapter glossary 2>&1 | tee /tmp/glossary-run.log
```

Expected: 1 doc generated (index.md). Note: this chapter's sources are broad (`nexus_utils/**`) so estimate may be 100k+ tokens; consider narrowing `sources` in config if cost prohibitive.

- [ ] **Step 2: Inspect + merge**

```bash
head -80 drafts/glossary/index.md
# If acceptable:
mkdir -p docs/glossary/en
cp drafts/glossary/index.md docs/glossary/
cp drafts/glossary/en/index.md docs/glossary/en/
```

- [ ] **Step 3: Regenerate llms.txt (picks up all new chapters)**

```bash
./scripts/sync.sh --emit-llms-txt
head -5 docs/public/llms.txt
wc -l docs/public/llms.txt docs/public/llms-full.txt
```

- [ ] **Step 4: Build check + commit (include llms.txt)**

```bash
npm run docs:build 2>&1 | tail -5
git add docs/glossary/ docs/public/llms.txt docs/public/llms-full.txt scripts/state/runs/ scripts/state/signatures/
git commit -m "docs(glossary): generate glossary + refresh llms.txt"
```

---

## Task 30: Wiki/CMS capability verification

No new files — validates the key Wiki guarantees from spec §9.7.

- [ ] **Step 1: HUMAN-EDIT preservation test**

Pick an already-generated doc (e.g., `docs/features/mcp-server.md`). Add a HUMAN-EDIT block manually:

```bash
DOC=docs/features/mcp-server.md
# Insert a HUMAN-EDIT block right after the H1
python3 - "$DOC" <<'PYEOF'
import sys, re
path = sys.argv[1]
text = open(path, encoding='utf-8').read()
# Find first H1 and insert after it
new_text = re.sub(
    r'(^# [^\n]+\n)',
    r'''\1
<!-- HUMAN-EDIT-START: manual-intro -->
> 这段是我手动加的，下次 sync 不应该被覆盖。This sentence tests the HUMAN-EDIT preservation guarantee.
<!-- HUMAN-EDIT-END: manual-intro -->

''',
    text,
    count=1,
    flags=re.MULTILINE
)
open(path, 'w', encoding='utf-8').write(new_text)
print("Inserted HUMAN-EDIT block into", path)
PYEOF

grep -A 2 "HUMAN-EDIT-START" "$DOC"
```

Expected: the HUMAN-EDIT block appears in the file.

- [ ] **Step 2: Force re-generate that single doc**

```bash
./scripts/sync.sh --full --chapter features --doc mcp-server --force-regenerate 2>&1 | tail -20
```

Expected: regenerate successful, log shows `(human_blocks=1)` in the output.

- [ ] **Step 3: Merge regenerated draft and verify preservation**

```bash
cp drafts/features/mcp-server.md docs/features/mcp-server.md
grep -A 2 "HUMAN-EDIT-START" docs/features/mcp-server.md
python3 scripts/lib/human_edit.py count docs/features/mcp-server.md
```

Expected: still one HUMAN-EDIT block, content byte-identical.

- [ ] **Step 4: Signature skip test**

Re-run without `--force-regenerate`:

```bash
./scripts/sync.sh --full --chapter features --doc mcp-server 2>&1 | grep mcp-server
```

Expected: log line contains `skipped (signature match)` since sources are unchanged.

- [ ] **Step 5: Estimate mode test (no API)**

```bash
./scripts/sync.sh --estimate --chapter features --force-regenerate
```

Expected: full estimate table printed; no `invoking claude` lines; no files written in `drafts/`.

- [ ] **Step 6: V1 regression test**

```bash
./scripts/sync.sh --only-detect --from $(git -C /home/ubuntu/mydev/Nexus-AI rev-parse HEAD~20) --to HEAD
jq '.triggered_mappings | length' scripts/state/changes.json
```

Expected: non-negative integer, no errors.

- [ ] **Step 7: Build + commit final state**

```bash
npm run docs:build 2>&1 | tail -5
git add docs/features/mcp-server.md scripts/state/runs/ scripts/state/signatures/
git commit -m "docs(features): add manual HUMAN-EDIT block — verified preserved by regen"
```

- [ ] **Step 8: Update STATUS.md**

Edit `docs/superpowers/STATUS.md`; change the "当前阶段" section to:

```markdown
## 当前阶段

**阶段：** v2 MVP 已实施并端到端验证通过。
- 5 个新章节 (features, integrations, tutorials, developer, reference) + glossary 均已全量生成并合并
- HUMAN-EDIT 保留、signature 跳过、--estimate、v1 regression 均验证通过
- `docs/public/llms.txt` 与 `llms-full.txt` 同步更新
```

Commit:

```bash
git add docs/superpowers/STATUS.md
git commit -m "docs: mark v2 MVP complete in STATUS tracker"
```

---

## Appendix: Troubleshooting

| Symptom | Cause / Fix |
|---------|-------------|
| `claude -p` fails silently | Check `scripts/state/runs/<latest>.json` for `error` field; rerun with `--doc <slug> --force-regenerate` |
| Draft file empty | Claude may have written to wrong path; look at `scripts/state/work/<chapter>/<slug>/` and rerun |
| `jq: error: Cannot iterate over null` in resolve.sh | Chapter id typo; `./scripts/sync.sh --list-chapters` to verify |
| Sidebar items invisible | Paste from `drafts/sidebar/<chapter>.json` into correct `sidebar['/<chapter>/']` key; rebuild |
| `SyncFreshness` component not rendering | Theme `index.ts` missing `app.component`; rebuild |
| llms.txt missing a chapter | Run `./scripts/sync.sh --emit-llms-txt` after all chapters merged |
| HUMAN-EDIT verification fails | Check block label matches exactly (whitespace-sensitive); regenerate with `--force-regenerate` and inspect work dir |
| Signature mismatch when sources didn't change | Normal after config.yaml edit; remove `scripts/state/signatures/<ch>__<slug>.sha` and rerun |
