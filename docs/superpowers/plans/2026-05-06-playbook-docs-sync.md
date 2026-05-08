# Playbook 文档自动同步机制 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a pluggable, semi-automated mechanism in `Nexus-AI-Playbook/scripts/` that detects Nexus-AI source changes, invokes Claude Code to regenerate affected user-manual pages (zh + en), optionally captures Playwright screenshots, and outputs reviewable drafts to `drafts/`.

**Architecture:** 5-stage shell pipeline — Detect → Prepare → Generate → Screenshot → Output — driven by a declarative `config.yaml` mapping source-code globs to doc paths. Claude Code (`claude -p`) performs all natural-language generation; shell scripts handle orchestration, context assembly, and file I/O only. No automated tests (MVP scope per spec §8); each task includes a manual verification step.

**Tech Stack:** Bash 4+, Python 3 (YAML parsing via `pyyaml`), `jq` (JSON), Claude Code CLI (`claude -p`), Node 18+ with Playwright (optional screenshots).

**Reference spec:** `docs/superpowers/specs/2026-05-06-playbook-docs-sync-design.md`

**Working directory for all commands:** `/home/ubuntu/mydev/Nexus-AI-Playbook` unless stated otherwise.

**Important constraints (from spec):**
- No automated tests in MVP — manual verification only.
- Claude Code is the generation engine; scripts must NOT template-generate doc content.
- `drafts/` is gitignored (ephemeral); `scripts/state/last_sync.json` IS git-tracked.
- Sonnet is the default model; Opus is opt-in per mapping via `model: "complex"`.

---

## File Structure

**New directories:**
- `scripts/` — sync mechanism (git-tracked)
- `scripts/lib/` — per-stage shell scripts
- `scripts/prompts/` — Claude Code prompt templates (+ style guide)
- `scripts/screenshots/` — Playwright project (isolated node_modules)
- `scripts/state/` — sync state; `last_sync.json` git-tracked, `work/` and `changes.json` gitignored
- `drafts/` — generated draft output (gitignored root)
- `docs/manual/en/` — English manual mirror (git-tracked, starts empty)

**New files (created across tasks):**
- `scripts/sync.sh` — main entry + CLI flag parser
- `scripts/config.yaml` — mapping + model + screenshot config
- `scripts/lib/common.sh` — shared bash helpers (path resolution, logging)
- `scripts/lib/yaml.py` — Python YAML→JSON adapter (avoids `yq` dependency)
- `scripts/lib/detect.sh` — Stage 1
- `scripts/lib/prepare.sh` — Stage 2
- `scripts/lib/generate.sh` — Stage 3
- `scripts/lib/screenshot.sh` — Stage 4
- `scripts/lib/output.sh` — Stage 5
- `scripts/prompts/style-guide.md` — global voice/format rules
- `scripts/prompts/feature-update.md` — feature-change prompt
- `scripts/prompts/config-reference.md` — config-reference prompt
- `scripts/screenshots/package.json`
- `scripts/screenshots/capture.js`
- `scripts/screenshots/targets.yaml`
- `scripts/README.md` — operator usage
- `scripts/state/last_sync.json` — initialized empty at Task 4
- `.gitignore` (new at repo root, if absent) — for `drafts/`, `state/work/`, `state/changes.json`, `state/errors.log`, `scripts/screenshots/node_modules`

**Files modified:** none (Playbook existing docs untouched).

---

## Task 1: Repository scaffolding + gitignore

**Files:**
- Create: `scripts/` directory tree
- Create: `drafts/` (gitignored)
- Create: `docs/manual/en/.gitkeep`
- Modify: `.gitignore` at repo root (create if missing)

- [ ] **Step 1: Create directories**

```bash
cd /home/ubuntu/mydev/Nexus-AI-Playbook
mkdir -p scripts/lib scripts/prompts scripts/screenshots scripts/state/work
mkdir -p drafts/manual/en drafts/images-todo
mkdir -p docs/manual/en
touch docs/manual/en/.gitkeep
```

- [ ] **Step 2: Write / update `.gitignore`**

Check if a root `.gitignore` exists with `ls -la .gitignore`. If it exists, append; if not, create. Target contents to add (append if missing):

```
# Playbook docs-sync mechanism
drafts/
scripts/state/work/
scripts/state/changes.json
scripts/state/errors.log
scripts/screenshots/node_modules/
scripts/screenshots/package-lock.json
```

Implementation: use `grep -qxF` to avoid duplicate lines.

```bash
cat >> .gitignore <<'EOF'

# Playbook docs-sync mechanism
drafts/
scripts/state/work/
scripts/state/changes.json
scripts/state/errors.log
scripts/screenshots/node_modules/
scripts/screenshots/package-lock.json
EOF
```

(If the root `.gitignore` does not yet exist, the `>>` above creates it.)

- [ ] **Step 3: Verify directory layout**

Run: `find scripts drafts docs/manual/en -type d | sort`

Expected output includes:
```
docs/manual/en
drafts
drafts/images-todo
drafts/manual
drafts/manual/en
scripts
scripts/lib
scripts/prompts
scripts/screenshots
scripts/state
scripts/state/work
```

And: `git check-ignore drafts/foo scripts/state/work/bar scripts/state/changes.json`

Expected: all three paths printed (confirming they are gitignored).

- [ ] **Step 4: Commit**

```bash
git add .gitignore scripts/ drafts/ docs/manual/en/.gitkeep
git status  # confirm drafts/ is NOT staged (ignored)
git add scripts/ docs/manual/en/.gitkeep .gitignore
git commit -m "chore(scripts): scaffold docs-sync directory structure"
```

Note: `drafts/` being gitignored means `git add drafts/` is a no-op. That is expected. The `docs/manual/en/.gitkeep` placeholder keeps the en directory tracked.

---

## Task 2: Config file with real mappings

**Files:**
- Create: `scripts/config.yaml`

- [ ] **Step 1: Write `scripts/config.yaml`**

```yaml
# Nexus-AI 源码仓库路径（相对于 scripts/ 目录）
source_repo:
  path: "../../Nexus-AI"
  default_branch: "main"

# 文档生成模型偏好
models:
  default: "claude-sonnet-4-6"        # 日常生成
  complex: "claude-opus-4-7"          # 架构 / 大范围变更

# 输出语言（顺序 = 输出顺序）
languages:
  - zh
  - en

# 源码变更 → 文档 映射（支持文件级 path 与模块级 glob）
mappings:
  - id: "mcp-feature"
    description: "MCP Server 相关功能"
    watches:
      - "mcp_server/**"
      - "config/mcp/**"
      - "nexus_utils/mcp/**"
    docs:
      - path: "manual/mcp.md"
        prompt: "feature-update.md"
        model: "default"
    screenshots:
      - "mcp-config-page"

  - id: "agent-creation"
    description: "Agent 创建流程"
    watches:
      - "api/v2/routers/agents.py"
      - "api/v2/services/agent_build_service.py"
      - "agents/system_agents/agent_build_workflow/**"
      - "web/app/create/**"
    docs:
      - path: "manual/create-agent.md"
        prompt: "feature-update.md"
        model: "default"
    screenshots:
      - "create-agent"
      - "quick-create"
      - "guided-create"

  - id: "config-reference"
    description: "主配置文件参考"
    watches:
      - "config/default_config.yaml"
    docs:
      - path: "admin/settings.md"
        prompt: "config-reference.md"
        model: "default"
    screenshots: []

# 截图配置
screenshots:
  enabled: "auto"                     # auto | always | never
  base_url: "http://localhost:3000"
  output_dir: "../docs/public/images" # 相对 scripts/ 路径
  login:
    user: "admin"
    password: "nexus"
```

- [ ] **Step 2: Verify YAML is valid**

Run: `python3 -c "import yaml; yaml.safe_load(open('scripts/config.yaml'))" && echo OK`

Expected output: `OK`

- [ ] **Step 3: Commit**

```bash
git add scripts/config.yaml
git commit -m "feat(scripts): add docs-sync config with 3 mappings"
```

---

## Task 3: YAML parsing helper + shared bash helpers

**Files:**
- Create: `scripts/lib/yaml.py`
- Create: `scripts/lib/common.sh`

These are the shared utilities every stage will `source`/invoke. Done early to unblock later stages.

- [ ] **Step 1: Write `scripts/lib/yaml.py`**

```python
#!/usr/bin/env python3
"""
Minimal YAML→JSON adapter. Used by bash stages so we don't need a `yq`
install. Reads a YAML file and writes JSON to stdout.

Usage:
    python3 scripts/lib/yaml.py scripts/config.yaml
    python3 scripts/lib/yaml.py scripts/config.yaml .mappings
    python3 scripts/lib/yaml.py scripts/config.yaml '.mappings[] | select(.id=="mcp-feature")'

Path expressions use the `jq` sub-language by piping through jq. If a
jq expression is supplied as the 2nd argument, this script converts
YAML→JSON, then execs `jq -c <expr>` to filter.
"""
import sys
import json
import os
import subprocess

import yaml


def main() -> int:
    if len(sys.argv) < 2:
        sys.stderr.write("usage: yaml.py <yaml-file> [jq-expr]\n")
        return 2
    path = sys.argv[1]
    with open(path, "r", encoding="utf-8") as f:
        data = yaml.safe_load(f)
    raw = json.dumps(data, ensure_ascii=False)
    if len(sys.argv) >= 3:
        expr = sys.argv[2]
        proc = subprocess.run(["jq", "-c", expr], input=raw, text=True)
        return proc.returncode
    print(raw)
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

- [ ] **Step 2: Write `scripts/lib/common.sh`**

```bash
#!/usr/bin/env bash
# Shared helpers sourced by every stage script.
# Defines: SCRIPTS_DIR, REPO_ROOT, CONFIG_FILE, STATE_DIR, DRAFTS_DIR,
#         log(), die(), yaml_get(), abs_source_repo()

set -euo pipefail

# Resolve SCRIPTS_DIR = directory containing this file's parent (lib/..)
COMMON_SH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$COMMON_SH_DIR/.." && pwd)"
REPO_ROOT="$(cd "$SCRIPTS_DIR/.." && pwd)"
CONFIG_FILE="$SCRIPTS_DIR/config.yaml"
STATE_DIR="$SCRIPTS_DIR/state"
WORK_DIR="$STATE_DIR/work"
DRAFTS_DIR="$REPO_ROOT/drafts"
PROMPTS_DIR="$SCRIPTS_DIR/prompts"

export SCRIPTS_DIR REPO_ROOT CONFIG_FILE STATE_DIR WORK_DIR DRAFTS_DIR PROMPTS_DIR

log() { printf '[%(%H:%M:%S)T] %s\n' -1 "$*" >&2; }
die() { log "ERROR: $*"; exit 1; }

# yaml_get <jq-expression>  — query config.yaml via python→jq bridge
yaml_get() {
    python3 "$SCRIPTS_DIR/lib/yaml.py" "$CONFIG_FILE" "$1"
}

# abs_source_repo — prints absolute path of Nexus-AI repo
abs_source_repo() {
    local rel
    rel="$(yaml_get '.source_repo.path' | tr -d '"')"
    (cd "$SCRIPTS_DIR" && cd "$rel" && pwd)
}
```

- [ ] **Step 3: Make scripts executable and verify helpers**

```bash
chmod +x scripts/lib/yaml.py
bash -c 'source scripts/lib/common.sh && echo "SCRIPTS_DIR=$SCRIPTS_DIR" && echo "source_repo abs=$(abs_source_repo)" && yaml_get ".mappings[0].id"'
```

Expected output (example):
```
SCRIPTS_DIR=/home/ubuntu/mydev/Nexus-AI-Playbook/scripts
source_repo abs=/home/ubuntu/mydev/Nexus-AI
"mcp-feature"
```

If `abs_source_repo` fails (path doesn't exist), that's a problem to fix now — the `../../Nexus-AI` path in `config.yaml` must resolve.

- [ ] **Step 4: Commit**

```bash
git add scripts/lib/yaml.py scripts/lib/common.sh
git commit -m "feat(scripts): add YAML helper and common bash utilities"
```

---

## Task 4: State management — initialize `last_sync.json`

**Files:**
- Create: `scripts/state/last_sync.json` (initially with null SHA)
- Modify: none yet (sync.sh will be written at Task 12, where `--init` handling lives)

- [ ] **Step 1: Create initial state file**

```bash
cat > scripts/state/last_sync.json <<'EOF'
{
  "last_commit_sha": null,
  "timestamp": null,
  "mappings_synced": []
}
EOF
```

- [ ] **Step 2: Verify JSON is valid**

Run: `jq . scripts/state/last_sync.json`

Expected: pretty-printed JSON with `"last_commit_sha": null`.

- [ ] **Step 3: Commit**

```bash
git add scripts/state/last_sync.json
git commit -m "feat(scripts): initialize docs-sync state file"
```

---

## Task 5: Stage 1 — Detect

**Files:**
- Create: `scripts/lib/detect.sh`

Input: `last_sync.json` + optional `--from`/`--to` override.
Output: `scripts/state/changes.json` listing triggered mappings with changed files.

Algorithm:
1. Resolve `from_sha` (argv or `last_sync.json`); `to_sha` (argv or `HEAD`).
2. Run `git diff --name-only from to` in Nexus-AI.
3. For each mapping in config, test if any changed file matches any `watches` glob.
4. Emit JSON.

Since bash glob matching on arbitrary globs is tricky, use Python for the glob filter.

- [ ] **Step 1: Write `scripts/lib/detect.sh`**

```bash
#!/usr/bin/env bash
# Stage 1: Detect source changes and match mappings.
# Usage: detect.sh [<from_sha>] [<to_sha>]
# Reads from_sha from state/last_sync.json if not provided.
# Writes state/changes.json.

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

FROM_SHA="${1:-}"
TO_SHA="${2:-HEAD}"

if [ -z "$FROM_SHA" ]; then
    FROM_SHA="$(jq -r '.last_commit_sha // empty' "$STATE_DIR/last_sync.json")"
fi

[ -n "$FROM_SHA" ] || die "No from_sha. Run 'sync.sh --init <sha>' first or pass --from."

SRC="$(abs_source_repo)"
[ -d "$SRC/.git" ] || die "Not a git repo: $SRC"

log "Detect: $FROM_SHA .. $TO_SHA in $SRC"

# Resolve real SHAs (handles HEAD, branch names)
FROM_SHA="$(git -C "$SRC" rev-parse "$FROM_SHA")"
TO_SHA="$(git -C "$SRC" rev-parse "$TO_SHA")"

if [ "$FROM_SHA" = "$TO_SHA" ]; then
    log "No changes ($FROM_SHA == $TO_SHA)"
    echo '{"from_sha":"'"$FROM_SHA"'","to_sha":"'"$TO_SHA"'","triggered_mappings":[]}' \
        > "$STATE_DIR/changes.json"
    exit 0
fi

# Get changed file list
CHANGED_FILES="$(git -C "$SRC" diff --name-only "$FROM_SHA" "$TO_SHA")"
if [ -z "$CHANGED_FILES" ]; then
    log "No file changes"
    echo '{"from_sha":"'"$FROM_SHA"'","to_sha":"'"$TO_SHA"'","triggered_mappings":[]}' \
        > "$STATE_DIR/changes.json"
    exit 0
fi

# Match mappings via Python (glob handling)
python3 - "$FROM_SHA" "$TO_SHA" "$CONFIG_FILE" <<'PYEOF' > "$STATE_DIR/changes.json"
import sys, json, fnmatch, yaml

from_sha, to_sha, config_path = sys.argv[1:4]
changed = [l.strip() for l in sys.stdin.read().splitlines() if l.strip()]
cfg = yaml.safe_load(open(config_path))

def matches(path, patterns):
    for p in patterns:
        if fnmatch.fnmatch(path, p):
            return True
        # Support ** recursive: fnmatch treats ** like *; broaden manually.
        if "**" in p:
            prefix = p.split("**", 1)[0].rstrip("/")
            if prefix and path.startswith(prefix + "/"):
                return True
    return False

triggered = []
for m in cfg.get("mappings", []):
    hits = [f for f in changed if matches(f, m.get("watches", []))]
    if hits:
        triggered.append({
            "id": m["id"],
            "description": m.get("description", ""),
            "changed_files": hits,
            "docs": m.get("docs", []),
            "screenshots": m.get("screenshots", []),
        })

json.dump({
    "from_sha": from_sha,
    "to_sha": to_sha,
    "triggered_mappings": triggered,
}, sys.stdout, ensure_ascii=False, indent=2)
PYEOF

COUNT="$(jq '.triggered_mappings | length' "$STATE_DIR/changes.json")"
log "Detected $COUNT triggered mapping(s)"
```

Wait — the heredoc above tries to read from stdin (`sys.stdin.read()`) but we never piped `CHANGED_FILES` into it. Fix: pipe explicitly.

- [ ] **Step 2: Fix the stdin piping bug**

Replace the `python3 - ... <<'PYEOF' > "$STATE_DIR/changes.json"` block with a version that pipes `CHANGED_FILES`:

```bash
echo "$CHANGED_FILES" | python3 - "$FROM_SHA" "$TO_SHA" "$CONFIG_FILE" <<'PYEOF' > "$STATE_DIR/changes.json"
import sys, json, fnmatch, yaml

from_sha, to_sha, config_path = sys.argv[1:4]
changed = [l.strip() for l in sys.stdin.read().splitlines() if l.strip()]
cfg = yaml.safe_load(open(config_path))

def matches(path, patterns):
    for p in patterns:
        if fnmatch.fnmatch(path, p):
            return True
        if "**" in p:
            prefix = p.split("**", 1)[0].rstrip("/")
            if prefix and path.startswith(prefix + "/"):
                return True
    return False

triggered = []
for m in cfg.get("mappings", []):
    hits = [f for f in changed if matches(f, m.get("watches", []))]
    if hits:
        triggered.append({
            "id": m["id"],
            "description": m.get("description", ""),
            "changed_files": hits,
            "docs": m.get("docs", []),
            "screenshots": m.get("screenshots", []),
        })

json.dump({
    "from_sha": from_sha,
    "to_sha": to_sha,
    "triggered_mappings": triggered,
}, sys.stdout, ensure_ascii=False, indent=2)
PYEOF
```

(Engineers: when writing the final script, use the Step-2 version — Step 1's heredoc without the `echo "$CHANGED_FILES" |` prefix is a bug to avoid.)

- [ ] **Step 3: Make executable and run a synthetic test**

```bash
chmod +x scripts/lib/detect.sh
# Pick a known-old SHA from Nexus-AI (using a recent one that predates mcp changes):
cd /home/ubuntu/mydev/Nexus-AI
FROM=$(git rev-parse HEAD~30)
TO=$(git rev-parse HEAD)
cd /home/ubuntu/mydev/Nexus-AI-Playbook
bash scripts/lib/detect.sh "$FROM" "$TO"
cat scripts/state/changes.json
```

Expected: `changes.json` contains a `triggered_mappings` array. If none of the 3 configured mappings matched the last 30 commits, rerun with `HEAD~200` or similar. The key verification is the JSON shape is correct and parseable.

Also verify:

```bash
jq '.triggered_mappings | length' scripts/state/changes.json  # non-negative integer
```

- [ ] **Step 4: Commit**

```bash
git add scripts/lib/detect.sh
git commit -m "feat(scripts): add Stage 1 detect — git diff + mapping match"
```

---

## Task 6: Stage 2 — Prepare context packs

**Files:**
- Create: `scripts/lib/prepare.sh`

Reads `changes.json`. For each triggered mapping, builds `state/work/<id>/` containing:
- `changed-files.md` — each changed file's full current content + diff vs `from_sha`
- `current-doc-zh.md` — copy of `docs/<path>.md` (or empty marker if file doesn't exist)
- `current-doc-en.md` — copy of `docs/manual/en/<...>.md` (or empty marker)
- `style-guide.md` — copy of `prompts/style-guide.md`
- `prompt.md` — the mapping's prompt template copied over (filled in Task 8)

- [ ] **Step 1: Write `scripts/lib/prepare.sh`**

```bash
#!/usr/bin/env bash
# Stage 2: Prepare per-mapping context packs under state/work/<id>/.
# Reads state/changes.json.

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

CHANGES_FILE="$STATE_DIR/changes.json"
[ -f "$CHANGES_FILE" ] || die "No changes.json. Run detect first."

SRC="$(abs_source_repo)"
FROM_SHA="$(jq -r '.from_sha' "$CHANGES_FILE")"
TO_SHA="$(jq -r '.to_sha' "$CHANGES_FILE")"

# Clean work dir
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"

COUNT="$(jq '.triggered_mappings | length' "$CHANGES_FILE")"
if [ "$COUNT" = "0" ]; then
    log "Prepare: no triggered mappings, nothing to do"
    exit 0
fi

# Iterate over mappings
for idx in $(seq 0 $((COUNT - 1))); do
    MAP_JSON="$(jq -c ".triggered_mappings[$idx]" "$CHANGES_FILE")"
    MAP_ID="$(echo "$MAP_JSON" | jq -r '.id')"
    WORK="$WORK_DIR/$MAP_ID"
    mkdir -p "$WORK"

    log "Prepare [$MAP_ID]"

    # Build changed-files.md
    {
        echo "# 源码变更清单 ($MAP_ID)"
        echo
        echo "Range: \`$FROM_SHA\` → \`$TO_SHA\`"
        echo
        echo "$MAP_JSON" | jq -r '.changed_files[]' | while IFS= read -r f; do
            echo "## $f"
            echo
            echo "### 当前内容"
            echo '```'
            if [ -f "$SRC/$f" ]; then
                cat "$SRC/$f"
            else
                echo "(文件已删除)"
            fi
            echo '```'
            echo
            echo "### Diff vs $FROM_SHA"
            echo '```diff'
            git -C "$SRC" diff "$FROM_SHA" "$TO_SHA" -- "$f" || true
            echo '```'
            echo
        done
    } > "$WORK/changed-files.md"

    # Per-doc context (iterate mapping.docs)
    echo "$MAP_JSON" | jq -c '.docs[]' | while IFS= read -r DOC_JSON; do
        DOC_PATH="$(echo "$DOC_JSON" | jq -r '.path')"
        DOC_SLUG="$(echo "$DOC_PATH" | tr '/' '_' | sed 's/\.md$//')"
        PROMPT_NAME="$(echo "$DOC_JSON" | jq -r '.prompt')"

        # Current zh doc
        if [ -f "$REPO_ROOT/docs/$DOC_PATH" ]; then
            cp "$REPO_ROOT/docs/$DOC_PATH" "$WORK/current-doc-zh__${DOC_SLUG}.md"
        else
            echo "(文档不存在，需全新创建)" > "$WORK/current-doc-zh__${DOC_SLUG}.md"
        fi

        # Current en doc (path: manual/xxx.md → manual/en/xxx.md)
        EN_PATH="$(echo "$DOC_PATH" | sed 's|^manual/|manual/en/|; s|^guide/|guide/en/|; s|^admin/|admin/en/|; s|^overview/|overview/en/|')"
        if [ -f "$REPO_ROOT/docs/$EN_PATH" ]; then
            cp "$REPO_ROOT/docs/$EN_PATH" "$WORK/current-doc-en__${DOC_SLUG}.md"
        else
            echo "(English version does not exist yet; create from scratch.)" > "$WORK/current-doc-en__${DOC_SLUG}.md"
        fi

        # Copy prompt template
        [ -f "$PROMPTS_DIR/$PROMPT_NAME" ] || die "Prompt not found: $PROMPT_NAME"
        cp "$PROMPTS_DIR/$PROMPT_NAME" "$WORK/prompt__${DOC_SLUG}.md"
    done

    # Style guide
    [ -f "$PROMPTS_DIR/style-guide.md" ] || die "Missing style-guide.md"
    cp "$PROMPTS_DIR/style-guide.md" "$WORK/style-guide.md"
done

log "Prepare: context packs written to $WORK_DIR"
```

- [ ] **Step 2: Make executable; deferred verification**

```bash
chmod +x scripts/lib/prepare.sh
```

Do not run yet — requires prompt templates from Task 7 to be present. Verification happens after Task 7.

- [ ] **Step 3: Commit**

```bash
git add scripts/lib/prepare.sh
git commit -m "feat(scripts): add Stage 2 prepare — context pack assembly"
```

---

## Task 7: Prompt templates

**Files:**
- Create: `scripts/prompts/style-guide.md`
- Create: `scripts/prompts/feature-update.md`
- Create: `scripts/prompts/config-reference.md`

- [ ] **Step 1: Write `scripts/prompts/style-guide.md`**

```markdown
# Nexus-AI Playbook 文档风格指南

这是 **Nexus-AI 产品的终端用户手册（User Manual）**，不是开发者文档。

## 核心原则

1. **面向终端用户** — 不要出现内部类名、函数名、数据库表名、文件路径。
2. **图文并茂** — 涉及 UI 操作时插入 `<!-- SCREENSHOT: <name> -->` 占位符（构建时由自动截图或人工替换）。
3. **简洁直接** — 一步一动作，尽量使用表格、有序列表呈现操作流程。
4. **中英文双版本对齐** — 两份文档结构、小节、示例完全一致；仅自然语言部分翻译。

## 格式约定

- 使用 Markdown + VitePress 扩展语法（`::: tip`、`::: info`、`::: warning`）。
- 标题层级从 `#` 开始（VitePress 要求每篇文档一个 H1）。
- 表格用于：功能对比、参数说明、限制约束、常见问题。
- 代码块用于：真实命令、示例输入、UI 文字标签（用 `「」` 或反引号）。

## 语气

- 中文：直呼"你"，不使用"您"；避免冗长修饰。
- English: second-person "you"; concise, imperative sentences.

## 不要做的事

- 不要解释"为什么这样实现"（这是用户手册，不是设计文档）。
- 不要暴露未发布功能或内部概念。
- 不要添加 TODO、占位符（截图占位符除外）、或"待补充"内容。
- 不要编造代码中不存在的功能。
```

- [ ] **Step 2: Write `scripts/prompts/feature-update.md`**

```markdown
# 任务：基于源代码变更更新用户手册文档

你是一位产品文档工程师，为 Nexus-AI 产品维护终端用户手册。

## 输入文件（都在当前工作目录）

- `style-guide.md` — **必读**，文档整体风格与语气约束。
- `changed-files.md` — 本次触发此文档更新的 Nexus-AI 源码变更（包含每个文件的当前内容和 diff）。
- `current-doc-zh__<slug>.md` — 现有中文文档（可能是 "(文档不存在)" 占位符）。
- `current-doc-en__<slug>.md` — 现有英文文档（可能是 "(English version does not exist yet)" 占位符）。

## 任务

**仔细阅读 style-guide.md，然后：**

1. 对比源码变更与现有中英文文档，判断哪些部分受影响。
2. 生成更新后的 **中文** 文档，保留现有文档中未受影响的内容，按 style-guide 风格修改/新增受影响章节。
3. 生成结构完全对齐的 **英文** 版本。
4. UI 截图若已失效或需新增，在相应位置插入 `<!-- SCREENSHOT: <short-name> -->` 占位符。

## 输出

将结果写入（路径相对当前工作目录）：

- `../../../drafts/manual/<slug-or-path>.md`（中文）
- `../../../drafts/manual/en/<slug-or-path>.md`（英文）

具体的输出路径由操作者传入的 `OUTPUT_ZH` 与 `OUTPUT_EN` 环境变量决定 —— 请优先写入这两个路径。

## 输出的硬性要求

- **只包含文档正文**，不要加"更改说明""变更摘要"之类的解释性段落。
- 中英文必须逐节对齐（同样的标题层级、同样的小节数量）。
- 不要编造代码中不存在的功能或参数。
- 如果源码变更与此文档实际无关（false positive），输出一个仅含一行注释的占位 draft：`<!-- NO_UPDATE_NEEDED: 源码变更与本文档无关 -->`。

## 完成标志

成功写入两个文件后，打印一行："DONE: wrote <zh-path> and <en-path>"。
```

- [ ] **Step 3: Write `scripts/prompts/config-reference.md`**

```markdown
# 任务：更新配置项参考文档

你是产品文档工程师，负责维护 Nexus-AI 的管理员配置参考文档（面向终端管理员/部署者，不是开发者）。

## 输入

- `style-guide.md` — **必读**。
- `changed-files.md` — 本次配置文件（通常是 `config/default_config.yaml`）的变更。
- `current-doc-zh__<slug>.md` / `current-doc-en__<slug>.md` — 现有文档。

## 任务

1. 识别 YAML 配置中新增、删除、重命名、默认值变化的键。
2. 更新现有文档中对应的配置项表格/小节；新增项用醒目标记（如 `::: tip 新增于本次更新`）。
3. 保持中英文结构对齐。
4. 不要暴露开发中/未发布的字段（如字段带有明显的 `experimental` 注释，应在文档中注明"实验性"）。

## 输出

写入 `OUTPUT_ZH` 与 `OUTPUT_EN` 指定的路径。完成后打印 "DONE: wrote <zh-path> and <en-path>"。

与 `feature-update.md` 的其余输出要求相同（仅正文；对齐；不编造）。
```

- [ ] **Step 4: Commit**

```bash
git add scripts/prompts/
git commit -m "feat(scripts): add prompt templates (style-guide, feature-update, config-reference)"
```

- [ ] **Step 5: Verify Task 6 (prepare) now works end-to-end with fixtures**

Prepare depends on these prompts. Re-run a synthetic detect + prepare:

```bash
cd /home/ubuntu/mydev/Nexus-AI-Playbook
cd /home/ubuntu/mydev/Nexus-AI && FROM=$(git rev-parse HEAD~200) && TO=$(git rev-parse HEAD) && cd -
bash scripts/lib/detect.sh "$FROM" "$TO"
bash scripts/lib/prepare.sh
ls scripts/state/work/
# For one of the triggered mappings:
ls scripts/state/work/$(jq -r '.triggered_mappings[0].id // empty' scripts/state/changes.json)/ 2>/dev/null || echo "no mappings triggered in this range, try wider range"
```

Expected: each triggered mapping has a subdirectory containing `changed-files.md`, `style-guide.md`, and one `prompt__*.md` + `current-doc-zh__*.md` + `current-doc-en__*.md` per doc.

If zero mappings triggered, widen the commit range (`HEAD~500`) until at least one matches — or manually create a fixture via `echo '{"from_sha":"x","to_sha":"y","triggered_mappings":[{"id":"config-reference","changed_files":["config/default_config.yaml"],"docs":[{"path":"admin/settings.md","prompt":"config-reference.md"}],"screenshots":[]}]}' > scripts/state/changes.json` then re-run prepare.

---

## Task 8: Stage 3 — Generate (Claude Code invocation)

**Files:**
- Create: `scripts/lib/generate.sh`

Iterates prepared work dirs; for each `(mapping, doc)` pair, invokes `claude -p` with the prompt, working directory set to the mapping's work dir. Output paths are passed via env vars.

- [ ] **Step 1: Write `scripts/lib/generate.sh`**

```bash
#!/usr/bin/env bash
# Stage 3: Invoke Claude Code to generate draft docs.
# Reads state/changes.json + state/work/*.
# Writes drafts to drafts/<path>.md and drafts/manual/en/<path>.md.

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

command -v claude >/dev/null || die "claude CLI not found in PATH"

CHANGES_FILE="$STATE_DIR/changes.json"
[ -f "$CHANGES_FILE" ] || die "No changes.json. Run detect+prepare first."

# Resolve model names from config
MODEL_DEFAULT="$(yaml_get '.models.default' | tr -d '"')"
MODEL_COMPLEX="$(yaml_get '.models.complex' | tr -d '"')"

mkdir -p "$DRAFTS_DIR/manual/en" "$DRAFTS_DIR/admin" "$DRAFTS_DIR/guide" "$DRAFTS_DIR/overview"

COUNT="$(jq '.triggered_mappings | length' "$CHANGES_FILE")"
[ "$COUNT" -gt 0 ] || { log "Generate: nothing to do"; exit 0; }

ERROR_LOG="$STATE_DIR/errors.log"
: > "$ERROR_LOG"

for idx in $(seq 0 $((COUNT - 1))); do
    MAP_JSON="$(jq -c ".triggered_mappings[$idx]" "$CHANGES_FILE")"
    MAP_ID="$(echo "$MAP_JSON" | jq -r '.id')"
    WORK="$WORK_DIR/$MAP_ID"

    echo "$MAP_JSON" | jq -c '.docs[]' | while IFS= read -r DOC_JSON; do
        DOC_PATH="$(echo "$DOC_JSON" | jq -r '.path')"
        DOC_SLUG="$(echo "$DOC_PATH" | tr '/' '_' | sed 's/\.md$//')"
        MODEL_KEY="$(echo "$DOC_JSON" | jq -r '.model // "default"')"
        case "$MODEL_KEY" in
            complex) MODEL="$MODEL_COMPLEX" ;;
            *)       MODEL="$MODEL_DEFAULT" ;;
        esac

        # Compute output paths
        EN_PATH="$(echo "$DOC_PATH" | sed 's|^manual/|manual/en/|; s|^guide/|guide/en/|; s|^admin/|admin/en/|; s|^overview/|overview/en/|')"
        OUT_ZH="$DRAFTS_DIR/$DOC_PATH"
        OUT_EN="$DRAFTS_DIR/$EN_PATH"
        mkdir -p "$(dirname "$OUT_ZH")" "$(dirname "$OUT_EN")"

        # Prompt body for this (mapping,doc) pair
        PROMPT_FILE="$WORK/prompt__${DOC_SLUG}.md"
        [ -f "$PROMPT_FILE" ] || { log "Skip: no prompt file $PROMPT_FILE"; continue; }

        log "Generate [$MAP_ID → $DOC_PATH] model=$MODEL"

        # Construct the combined prompt: preamble + template + slug hint
        COMBINED="$(cat <<EOF
你的工作目录是: $WORK
此次任务的文档 slug: $DOC_SLUG
对应的上下文文件（按 slug 配对）:
  - prompt__${DOC_SLUG}.md  (任务指引)
  - current-doc-zh__${DOC_SLUG}.md
  - current-doc-en__${DOC_SLUG}.md
  - changed-files.md (所有变更文件)
  - style-guide.md

OUTPUT_ZH = $OUT_ZH
OUTPUT_EN = $OUT_EN

请严格按照 prompt__${DOC_SLUG}.md 的指令执行。
EOF
)"

        # Invoke claude -p; working dir = $WORK for relative Read calls
        if ! (cd "$WORK" && claude -p "$COMBINED" \
                --model "$MODEL" \
                --allowed-tools "Read,Write"); then
            echo "[$(date -Iseconds)] FAIL $MAP_ID/$DOC_PATH" >> "$ERROR_LOG"
            log "  FAILED (logged to $ERROR_LOG)"
            continue
        fi

        # Sanity check outputs exist and are non-empty
        if [ ! -s "$OUT_ZH" ]; then
            log "  WARN: $OUT_ZH is empty or missing"
            echo "[$(date -Iseconds)] EMPTY_ZH $MAP_ID/$DOC_PATH" >> "$ERROR_LOG"
        fi
        if [ ! -s "$OUT_EN" ]; then
            log "  WARN: $OUT_EN is empty or missing"
            echo "[$(date -Iseconds)] EMPTY_EN $MAP_ID/$DOC_PATH" >> "$ERROR_LOG"
        fi
    done
done

log "Generate: drafts written to $DRAFTS_DIR"
[ -s "$ERROR_LOG" ] && log "Some errors/warnings; see $ERROR_LOG"
```

- [ ] **Step 2: Make executable**

```bash
chmod +x scripts/lib/generate.sh
```

- [ ] **Step 3: Verify with a minimal real call**

This step incurs real Claude API cost — use a single small mapping. Option: run the full detect+prepare+generate pipeline over a narrow real commit range where you know `config/default_config.yaml` changed:

```bash
cd /home/ubuntu/mydev/Nexus-AI
# Find a commit that touched config/default_config.yaml
LATEST_CONFIG_TOUCH=$(git log -n 1 --pretty=format:%H -- config/default_config.yaml)
BEFORE=$(git rev-parse "$LATEST_CONFIG_TOUCH^")
cd /home/ubuntu/mydev/Nexus-AI-Playbook
bash scripts/lib/detect.sh "$BEFORE" "$LATEST_CONFIG_TOUCH"
bash scripts/lib/prepare.sh
bash scripts/lib/generate.sh
# Check output
ls -la drafts/admin/
cat drafts/admin/settings.md | head -30
cat drafts/admin/en/settings.md | head -30
```

Expected: `drafts/admin/settings.md` and `drafts/admin/en/settings.md` exist and contain structured markdown that references real config keys.

If `claude` errors with auth/context, review `scripts/state/errors.log`.

- [ ] **Step 4: Commit**

```bash
git add scripts/lib/generate.sh
git commit -m "feat(scripts): add Stage 3 generate — claude -p invocation per (mapping,doc)"
```

---

## Task 9: Playwright screenshot scaffolding

**Files:**
- Create: `scripts/screenshots/package.json`
- Create: `scripts/screenshots/targets.yaml`
- Create: `scripts/screenshots/capture.js`

- [ ] **Step 1: Write `scripts/screenshots/package.json`**

```json
{
  "name": "nexus-playbook-screenshots",
  "version": "0.0.1",
  "private": true,
  "type": "module",
  "scripts": {
    "install-browsers": "playwright install chromium"
  },
  "dependencies": {
    "playwright": "^1.48.0",
    "js-yaml": "^4.1.0"
  }
}
```

- [ ] **Step 2: Write `scripts/screenshots/targets.yaml`**

```yaml
# 每个目标 = 一次截图。name 对应 config.yaml 中 mappings.screenshots 列表的条目。
# url 是相对 config.yaml 中的 screenshots.base_url。
targets:
  - name: "mcp-config-page"
    url: "/admin/mcp"
    output: "mcp-config-page.png"
    wait_for_selector: "body"

  - name: "create-agent"
    url: "/create"
    output: "create-agent.png"
    wait_for_selector: "body"

  - name: "quick-create"
    url: "/create?mode=quick"
    output: "quick-create.png"
    wait_for_selector: "body"

  - name: "guided-create"
    url: "/create?mode=guided"
    output: "guided-create.png"
    wait_for_selector: "body"
```

> Note: URLs above are best guesses based on the Nexus-AI web router. The engineer should verify the actual routes by running the Nexus-AI web server locally and adjust `url:` values if wrong.

- [ ] **Step 3: Write `scripts/screenshots/capture.js`**

```javascript
#!/usr/bin/env node
/**
 * Playwright screenshot runner.
 * Usage: node capture.js --targets "name1,name2" --base-url http://localhost:3000 --user admin --password nexus --output-dir ../../docs/public/images
 * If --targets is "all", captures every target in targets.yaml.
 */
import { chromium } from 'playwright';
import fs from 'node:fs';
import path from 'node:path';
import url from 'node:url';
import yaml from 'js-yaml';

const __dirname = path.dirname(url.fileURLToPath(import.meta.url));

function parseArgs(argv) {
  const args = { targets: 'all' };
  for (let i = 2; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--targets') args.targets = argv[++i];
    else if (a === '--base-url') args.baseUrl = argv[++i];
    else if (a === '--user') args.user = argv[++i];
    else if (a === '--password') args.password = argv[++i];
    else if (a === '--output-dir') args.outputDir = argv[++i];
  }
  return args;
}

async function isServiceUp(baseUrl) {
  try {
    const res = await fetch(baseUrl, { method: 'GET' });
    return res.status < 500;
  } catch {
    return false;
  }
}

async function login(page, baseUrl, user, password) {
  await page.goto(baseUrl + '/login', { waitUntil: 'domcontentloaded' });
  // Best-effort: fill any visible username/password fields. If site uses SSO,
  // this no-ops and the caller falls through to taking screenshots of what's visible.
  try {
    await page.fill('input[type="text"], input[name*="user" i], input[name*="email" i]', user, { timeout: 2000 });
    await page.fill('input[type="password"]', password, { timeout: 2000 });
    await page.click('button[type="submit"], button:has-text("登录"), button:has-text("Login")', { timeout: 2000 });
    await page.waitForLoadState('networkidle', { timeout: 5000 }).catch(() => {});
  } catch {
    // Login form not present or shape differs — continue without blocking.
  }
}

async function main() {
  const args = parseArgs(process.argv);
  const baseUrl = args.baseUrl || 'http://localhost:3000';
  const outputDir = path.resolve(args.outputDir || '../../docs/public/images');

  if (!await isServiceUp(baseUrl)) {
    console.error(JSON.stringify({ status: 'service_down', baseUrl }));
    process.exit(2);  // distinct exit code: service not running
  }

  const cfg = yaml.load(fs.readFileSync(path.join(__dirname, 'targets.yaml'), 'utf8'));
  const wanted = args.targets === 'all'
    ? cfg.targets.map(t => t.name)
    : args.targets.split(',').map(s => s.trim()).filter(Boolean);
  const targets = cfg.targets.filter(t => wanted.includes(t.name));

  if (!targets.length) {
    console.error(JSON.stringify({ status: 'no_targets_matched', wanted }));
    process.exit(3);
  }

  fs.mkdirSync(outputDir, { recursive: true });

  const browser = await chromium.launch();
  const context = await browser.newContext({ viewport: { width: 1440, height: 900 } });
  const page = await context.newPage();

  try {
    if (args.user && args.password) {
      await login(page, baseUrl, args.user, args.password);
    }

    const results = [];
    for (const t of targets) {
      const target = baseUrl.replace(/\/$/, '') + t.url;
      try {
        await page.goto(target, { waitUntil: 'domcontentloaded', timeout: 15000 });
        if (t.wait_for_selector) {
          await page.waitForSelector(t.wait_for_selector, { timeout: 5000 }).catch(() => {});
        }
        const outPath = path.join(outputDir, t.output);
        await page.screenshot({ path: outPath, fullPage: true });
        results.push({ name: t.name, status: 'ok', path: outPath });
      } catch (err) {
        results.push({ name: t.name, status: 'error', error: String(err) });
      }
    }
    console.log(JSON.stringify({ status: 'done', results }, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
```

- [ ] **Step 4: Install Playwright dependencies**

```bash
cd scripts/screenshots
npm install
npx playwright install chromium
cd ../..
```

Note: chromium download is ~170 MB. If this fails, skip — Stage 4 will still fall back to TODO list.

- [ ] **Step 5: Verify the script runs (offline dry-run expected to exit 2)**

```bash
node scripts/screenshots/capture.js --targets mcp-config-page --base-url http://localhost:9999
echo "exit=$?"
```

Expected: prints `{"status":"service_down",...}` and exit code 2.

- [ ] **Step 6: Commit**

```bash
git add scripts/screenshots/package.json scripts/screenshots/targets.yaml scripts/screenshots/capture.js
# Check node_modules and package-lock are ignored:
git status scripts/screenshots/
git commit -m "feat(scripts): add Playwright screenshot scaffolding"
```

---

## Task 10: Stage 4 — Screenshot

**Files:**
- Create: `scripts/lib/screenshot.sh`

- [ ] **Step 1: Write `scripts/lib/screenshot.sh`**

```bash
#!/usr/bin/env bash
# Stage 4: optionally run Playwright screenshots. Falls back to TODO list.

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

CHANGES_FILE="$STATE_DIR/changes.json"
[ -f "$CHANGES_FILE" ] || die "No changes.json"

ENABLED="$(yaml_get '.screenshots.enabled' | tr -d '"')"
BASE_URL="$(yaml_get '.screenshots.base_url' | tr -d '"')"
OUT_DIR_REL="$(yaml_get '.screenshots.output_dir' | tr -d '"')"
USER="$(yaml_get '.screenshots.login.user' | tr -d '"')"
PASS="$(yaml_get '.screenshots.login.password' | tr -d '"')"

OUT_DIR_ABS="$(cd "$SCRIPTS_DIR" && cd "$OUT_DIR_REL" 2>/dev/null && pwd || echo "$SCRIPTS_DIR/$OUT_DIR_REL")"
mkdir -p "$OUT_DIR_ABS" "$DRAFTS_DIR/images-todo"

# Collect all screenshot names across triggered mappings (dedup)
WANTED="$(jq -r '[.triggered_mappings[].screenshots[]] | unique | join(",")' "$CHANGES_FILE")"

if [ -z "$WANTED" ]; then
    log "Screenshot: no screenshots requested"
    exit 0
fi

if [ "$ENABLED" = "never" ]; then
    log "Screenshot: disabled in config"
    printf "%s\n" "$WANTED" | tr ',' '\n' | sed 's|^|[ ] |' \
        > "$DRAFTS_DIR/images-todo/TODO.md"
    exit 0
fi

# Try capture
CAPTURE_OUT="$(node "$SCRIPTS_DIR/screenshots/capture.js" \
    --targets "$WANTED" \
    --base-url "$BASE_URL" \
    --user "$USER" \
    --password "$PASS" \
    --output-dir "$OUT_DIR_ABS" 2>&1)" || CAPTURE_EXIT=$?

CAPTURE_EXIT="${CAPTURE_EXIT:-0}"

case "$CAPTURE_EXIT" in
    0)
        log "Screenshot: captured successfully"
        echo "$CAPTURE_OUT"
        ;;
    2)
        log "Screenshot: service not running at $BASE_URL — writing TODO list"
        {
            echo "# 需要手动截图的条目"
            echo
            echo "本次服务未运行 (\`$BASE_URL\`)，以下截图未自动生成，请在服务启动后手动补截："
            echo
            printf "%s\n" "$WANTED" | tr ',' '\n' | sed 's|^|- [ ] |'
        } > "$DRAFTS_DIR/images-todo/TODO.md"
        ;;
    *)
        log "Screenshot: failed with exit=$CAPTURE_EXIT"
        echo "$CAPTURE_OUT" | tail -20
        echo "$CAPTURE_OUT" >> "$STATE_DIR/errors.log"
        {
            echo "# 截图失败"
            echo
            echo "Playwright 捕获失败，请查看 \`scripts/state/errors.log\`。"
            echo
            printf "%s\n" "$WANTED" | tr ',' '\n' | sed 's|^|- [ ] |'
        } > "$DRAFTS_DIR/images-todo/TODO.md"
        ;;
esac
```

- [ ] **Step 2: Make executable and verify fallback path**

```bash
chmod +x scripts/lib/screenshot.sh
# Force a synthetic changes.json with screenshots requested, then run with no service:
cat > scripts/state/changes.json <<'EOF'
{
  "from_sha": "aaa",
  "to_sha": "bbb",
  "triggered_mappings": [
    {"id":"mcp-feature","changed_files":[],"docs":[],"screenshots":["mcp-config-page"]}
  ]
}
EOF
# Override base_url to a definitely-down port:
BASE_OVERRIDE=$(python3 -c "import yaml;d=yaml.safe_load(open('scripts/config.yaml'));d['screenshots']['base_url']='http://localhost:9999';print(yaml.safe_dump(d))")
# Don't actually overwrite config.yaml — instead set by hand for the test and revert.
# Easier: temporarily edit config, run, revert.
```

Simpler verification:

```bash
# Stop any service on :3000 or just trust it's not running, then:
bash scripts/lib/screenshot.sh
cat drafts/images-todo/TODO.md
```

Expected: either "captured successfully" (if Nexus-AI web is running) or a TODO.md listing `- [ ] mcp-config-page`.

- [ ] **Step 3: Commit**

```bash
git add scripts/lib/screenshot.sh
git commit -m "feat(scripts): add Stage 4 screenshot — Playwright with TODO fallback"
```

---

## Task 11: Stage 5 — Output / SUMMARY.md

**Files:**
- Create: `scripts/lib/output.sh`

- [ ] **Step 1: Write `scripts/lib/output.sh`**

```bash
#!/usr/bin/env bash
# Stage 5: Write drafts/SUMMARY.md describing what was produced and next steps.

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

CHANGES_FILE="$STATE_DIR/changes.json"
[ -f "$CHANGES_FILE" ] || die "No changes.json"

FROM="$(jq -r '.from_sha' "$CHANGES_FILE")"
TO="$(jq -r '.to_sha' "$CHANGES_FILE")"
COUNT="$(jq '.triggered_mappings | length' "$CHANGES_FILE")"

SUMMARY="$DRAFTS_DIR/SUMMARY.md"
mkdir -p "$DRAFTS_DIR"

{
    echo "# 同步摘要 ($(date +%Y-%m-%d))"
    echo
    echo "- From: \`$FROM\`"
    echo "- To:   \`$TO\`"
    echo "- Triggered mappings: $COUNT"
    echo
    echo "## 已生成草稿"
    echo
    if [ "$COUNT" = "0" ]; then
        echo "_无映射触发，无草稿生成。_"
    else
        jq -r '.triggered_mappings[] | "- [ ] `\(.id)` → " + ( [.docs[].path] | join(", ") )' "$CHANGES_FILE"
    fi
    echo
    echo "## 草稿文件"
    echo
    if [ -d "$DRAFTS_DIR/manual" ] || [ -d "$DRAFTS_DIR/admin" ] || [ -d "$DRAFTS_DIR/guide" ] || [ -d "$DRAFTS_DIR/overview" ]; then
        (cd "$DRAFTS_DIR" && find manual admin guide overview -type f -name '*.md' 2>/dev/null | sort | sed 's|^|- |')
    else
        echo "_(无)_"
    fi
    echo
    echo "## 截图状态"
    echo
    if [ -f "$DRAFTS_DIR/images-todo/TODO.md" ]; then
        echo "需要手动处理，见 \`drafts/images-todo/TODO.md\`。"
    else
        echo "_全部自动完成或无截图需求。_"
    fi
    echo
    if [ -s "$STATE_DIR/errors.log" ]; then
        echo "## 错误/警告"
        echo
        echo "有错误或警告，详见 \`scripts/state/errors.log\`："
        echo
        echo '```'
        tail -20 "$STATE_DIR/errors.log"
        echo '```'
        echo
    fi
    echo "## 下一步"
    echo
    echo "1. 对比 \`drafts/\` 与 \`docs/\` 的差异。"
    echo "2. 确认无误后，将草稿合并到正式目录（例如 \`cp drafts/manual/xxx.md docs/manual/xxx.md\`）。"
    echo "3. 合并完成后运行 \`./scripts/sync.sh --commit-sync\` 更新 \`last_sync.json\`。"
} > "$SUMMARY"

log "Output: $SUMMARY"
```

- [ ] **Step 2: Make executable and verify**

```bash
chmod +x scripts/lib/output.sh
bash scripts/lib/output.sh
cat drafts/SUMMARY.md
```

Expected: SUMMARY.md exists and lists the currently-staged changes (or "无映射触发" if changes.json is empty-triggered).

- [ ] **Step 3: Commit**

```bash
git add scripts/lib/output.sh
git commit -m "feat(scripts): add Stage 5 output — SUMMARY.md generator"
```

---

## Task 12: Main entry `sync.sh` with CLI flag parsing

**Files:**
- Create: `scripts/sync.sh`

CLI spec (from spec §6):

| Flag | Behavior |
|------|----------|
| (none) | run Detect → Prepare → Generate → Screenshot → Output |
| `--dry-run` | Detect + Prepare only |
| `--only-detect` | Detect only |
| `--mapping <id>` | restrict pipeline to one mapping (post-detect filter) |
| `--from <sha> --to <sha>` | override commit range |
| `--init <sha>` | write `last_sync.json` with the given SHA (no pipeline) |
| `--commit-sync` | write `last_sync.json` to the TO sha from the most recent `changes.json` (no pipeline) |

- [ ] **Step 1: Write `scripts/sync.sh`**

```bash
#!/usr/bin/env bash
# Main entry. Orchestrates the 5-stage docs-sync pipeline.
set -euo pipefail
source "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/lib/common.sh"

MODE="full"            # full | dry-run | only-detect | init | commit-sync
FROM_SHA=""
TO_SHA=""
ONLY_MAPPING=""
INIT_SHA=""

usage() {
    cat <<EOF
Usage: $0 [--dry-run] [--only-detect] [--mapping <id>]
          [--from <sha>] [--to <sha>]
          [--init <sha>] [--commit-sync]
EOF
    exit 2
}

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run)      MODE="dry-run"; shift ;;
        --only-detect)  MODE="only-detect"; shift ;;
        --mapping)      ONLY_MAPPING="${2:-}"; shift 2 ;;
        --from)         FROM_SHA="${2:-}"; shift 2 ;;
        --to)           TO_SHA="${2:-}"; shift 2 ;;
        --init)         MODE="init"; INIT_SHA="${2:-}"; shift 2 ;;
        --commit-sync)  MODE="commit-sync"; shift ;;
        -h|--help)      usage ;;
        *)              log "Unknown flag: $1"; usage ;;
    esac
done

# ---- Sub-modes that don't run the pipeline ----
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

# ---- Pipeline modes ----
# Stage 1
bash "$SCRIPTS_DIR/lib/detect.sh" "$FROM_SHA" "${TO_SHA:-HEAD}"

# Filter mappings by --mapping (in place on changes.json)
if [ -n "$ONLY_MAPPING" ]; then
    jq --arg id "$ONLY_MAPPING" \
        '.triggered_mappings = [ .triggered_mappings[] | select(.id==$id) ]' \
        "$STATE_DIR/changes.json" > "$STATE_DIR/changes.json.tmp"
    mv "$STATE_DIR/changes.json.tmp" "$STATE_DIR/changes.json"
    COUNT="$(jq '.triggered_mappings | length' "$STATE_DIR/changes.json")"
    log "Filter --mapping $ONLY_MAPPING: $COUNT mapping(s) remain"
fi

[ "$MODE" = "only-detect" ] && exit 0

# Stage 2
bash "$SCRIPTS_DIR/lib/prepare.sh"

[ "$MODE" = "dry-run" ] && { log "Dry-run complete"; exit 0; }

# Stage 3
bash "$SCRIPTS_DIR/lib/generate.sh"

# Stage 4
bash "$SCRIPTS_DIR/lib/screenshot.sh" || log "Screenshot stage non-fatal failure"

# Stage 5
bash "$SCRIPTS_DIR/lib/output.sh"

log "Done. See drafts/SUMMARY.md"
```

- [ ] **Step 2: Make executable and smoke-test flags**

```bash
chmod +x scripts/sync.sh
./scripts/sync.sh --help 2>&1 || true    # exits 2, prints usage
./scripts/sync.sh --only-detect --from $(cd /home/ubuntu/mydev/Nexus-AI && git rev-parse HEAD~50) --to $(cd /home/ubuntu/mydev/Nexus-AI && git rev-parse HEAD)
cat scripts/state/changes.json | jq '.triggered_mappings | length'
```

Expected: `--help` prints usage; `--only-detect` writes changes.json; count is a non-negative integer.

- [ ] **Step 3: Commit**

```bash
git add scripts/sync.sh
git commit -m "feat(scripts): add sync.sh main entry with CLI flag parsing"
```

---

## Task 13: Operator README

**Files:**
- Create: `scripts/README.md`

- [ ] **Step 1: Write `scripts/README.md`**

```markdown
# Playbook 文档自动同步工具

将 `Nexus-AI` 源代码变更同步为 `Nexus-AI-Playbook` 用户手册的草稿。
文档内容由 **Claude Code (`claude -p`)** 生成；本目录仅负责编排、上下文准备、输出管理。

> 设计详情见 [`docs/superpowers/specs/2026-05-06-playbook-docs-sync-design.md`](../docs/superpowers/specs/2026-05-06-playbook-docs-sync-design.md)。

## 先决条件

| 工具 | 用途 | 检查命令 |
|------|------|---------|
| `bash` 4+ | 脚本宿主 | `bash --version` |
| `python3` + `pyyaml` | YAML 解析 | `python3 -c "import yaml"` |
| `jq` | JSON 处理 | `jq --version` |
| `claude` (Claude Code CLI) | 文档生成 | `claude --version` |
| `node` 18+ 和 Playwright | 可选自动截图 | `node --version` |
| 本地已 clone `Nexus-AI` | 源码输入 | `ls ../../Nexus-AI/.git` |

## 一次性配置

1. 编辑 [`config.yaml`](config.yaml)：
   - `source_repo.path` 指向本地 Nexus-AI 仓库。
   - `mappings[]` 定义要同步的"源码→文档"规则。
   - `models.default` / `complex` 选择 Claude 模型。
   - `screenshots.base_url` 指向本地 Nexus-AI Web 服务（用于可选截图）。

2. 初始化同步起点（选一个已知正确的 Nexus-AI commit SHA）：

   ```bash
   ./sync.sh --init <SHA>
   ```

## 日常工作流

```bash
# 完整同步（Nexus-AI 的最新变更）
./scripts/sync.sh

# 只看会触发什么，不调用 Claude
./scripts/sync.sh --dry-run

# 只跑一个映射调试
./scripts/sync.sh --mapping mcp-feature

# 指定起止 commit（回放）
./scripts/sync.sh --from <sha1> --to <sha2>

# 人工 review drafts/ → 合并到 docs/ → 更新同步点
./scripts/sync.sh --commit-sync
```

## 输出

- `drafts/SUMMARY.md` — 本次同步摘要与下一步建议
- `drafts/manual/*.md`、`drafts/manual/en/*.md`、`drafts/admin/*.md` — 草稿
- `drafts/images-todo/TODO.md` — 需要手动补的截图（服务未运行时产生）
- `scripts/state/errors.log` — 生成过程中的错误与警告

## 合并到正式文档

草稿生成后请人工 diff 与合并：

```bash
diff -u docs/manual/mcp.md drafts/manual/mcp.md
# 满意后：
cp drafts/manual/mcp.md docs/manual/mcp.md
cp drafts/manual/en/mcp.md docs/manual/en/mcp.md
git add docs/manual/mcp.md docs/manual/en/mcp.md
git commit -m "docs: sync mcp from Nexus-AI <short-sha>"
# 最后更新同步点
./scripts/sync.sh --commit-sync
```

## 调试提示

- `scripts/state/work/<mapping-id>/` 是 Claude 看到的完整上下文；直接查看可验证上下文是否合理。
- 手动调用一次 Claude：`cd scripts/state/work/mcp-feature && claude -p "$(cat prompt__manual_mcp.md)" --allowed-tools "Read,Write"`
- 运行 `git diff scripts/state/last_sync.json` 可以看到上次同步的 SHA。
```

- [ ] **Step 2: Commit**

```bash
git add scripts/README.md
git commit -m "docs(scripts): add operator README"
```

---

## Task 14: End-to-end verification

No new files. Wire everything together with a real run.

- [ ] **Step 1: Choose a real commit range that triggers multiple mappings**

```bash
cd /home/ubuntu/mydev/Nexus-AI
# Find a commit that changed config/default_config.yaml recently
CONFIG_SHA=$(git log -n 1 --pretty=format:%H -- config/default_config.yaml)
# Go back 5 more commits for a wider diff
FROM=$(git rev-parse "$CONFIG_SHA~5")
TO=$(git rev-parse HEAD)
echo "FROM=$FROM  TO=$TO"
cd /home/ubuntu/mydev/Nexus-AI-Playbook
```

- [ ] **Step 2: Dry-run**

```bash
./scripts/sync.sh --dry-run --from "$FROM" --to "$TO"
jq '.triggered_mappings | map({id, changed_files: (.changed_files|length)})' scripts/state/changes.json
ls scripts/state/work/
```

Expected: triggered_mappings count ≥ 1; `scripts/state/work/*` contains the expected per-mapping directories with full context files.

- [ ] **Step 3: Full run**

```bash
./scripts/sync.sh --from "$FROM" --to "$TO"
```

Expected: completes without fatal error. Output ends with `Done. See drafts/SUMMARY.md`.

- [ ] **Step 4: Inspect outputs against the success criteria (spec §9)**

```bash
cat drafts/SUMMARY.md

# Pick one draft and inspect:
DRAFT=$(find drafts/manual drafts/admin -name '*.md' -not -path '*/en/*' | head -1)
echo "=== $DRAFT ==="
head -60 "$DRAFT"

EN="${DRAFT/\/manual\///manual/en/}"
EN="${EN/\/admin\///admin/en/}"
echo "=== $EN ==="
head -60 "$EN"

# Screenshot fallback
cat drafts/images-todo/TODO.md 2>/dev/null || echo "(no TODO file)"
```

**Verification checklist (must all be true before claiming MVP success):**

- [ ] `drafts/SUMMARY.md` lists each triggered mapping with the docs it produced.
- [ ] At least one zh draft and one en draft exist and are non-empty.
- [ ] The zh and en drafts have the **same heading structure** (eyeball check: both have the same number of `#`/`##`/`###` lines).
- [ ] Drafts reference actual features from the source (spot-check by searching for real keywords from `changed-files.md`).
- [ ] Drafts do NOT contain internal implementation references (no Python module paths, no class names from the code — a grep like `grep -E 'class |def |from [a-z_]+ import' drafts/manual/*.md drafts/admin/*.md` should return nothing).
- [ ] Screenshot TODO list OR actual screenshot files exist, matching the requested names.
- [ ] `scripts/state/errors.log` is empty or contains only non-fatal warnings.

- [ ] **Step 5: Final commit marking MVP complete**

No code changes at this step — just a marker commit if verification passes.

```bash
# If any drafts look acceptable, commit a note:
cat >> scripts/README.md <<'EOF'

## Status

MVP verified end-to-end on <date> against Nexus-AI commit range <short-sha>..<short-sha>.
EOF
# Fill in the date/sha manually.
git add scripts/README.md
git commit -m "docs(scripts): mark docs-sync MVP verified end-to-end"
```

---

## Appendix: When things go wrong

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `Not a git repo: …` | `config.yaml` `source_repo.path` is wrong | Correct the path; make sure it points to a clone of Nexus-AI. |
| `No from_sha. Run 'sync.sh --init …'` | First-time use without init | Run `./scripts/sync.sh --init <sha>` once. |
| `claude: command not found` | Claude Code CLI not installed or not in PATH | Install / fix PATH. |
| `Prompt not found: <file>` | Mapping references a template that doesn't exist in `prompts/` | Add the template or fix the mapping's `prompt:` field. |
| `drafts/manual/xxx.md` is empty | Claude wrote to a different path, or failed silently | Look at `scripts/state/errors.log` and `scripts/state/work/<id>/` — re-run `generate.sh` after fixing. |
| Screenshot always falls back to TODO | Base URL wrong or service not up | `curl $base_url` to diagnose; update `screenshots.base_url` if needed. |
| en draft is empty but zh is fine | Prompt didn't write OUTPUT_EN | Ensure the prompt template explicitly names both output paths; re-run with `--mapping <id>`. |
