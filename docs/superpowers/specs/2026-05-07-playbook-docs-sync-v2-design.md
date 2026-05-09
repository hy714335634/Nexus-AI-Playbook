# Playbook 文档自动同步机制 v2 — 设计文档

**日期：** 2026-05-07
**状态：** 设计待批准，待实施
**前置文档：** [2026-05-06-playbook-docs-sync-design.md](./2026-05-06-playbook-docs-sync-design.md)（v1，已部分实施）
**作用：** supersedes v1

---

## 0. 本版修订说明（Scope 变化）

v1 范围是 **"增量补丁同步三个既有文档"**（mcp、create-agent、settings）。v1 的 scripts/ 管道已实现到 Task 12 并提交（`ca15f43..53592e3`）。

v2 的范围扩展为：

- **首次全量生成** 5 个全新章节（基于现有 Nexus-AI 源码）：`/features/`、`/integrations/`、`/tutorials/`、`/developer/`、`/reference/`
- **统一的工作框架**：同一套 scripts/ 同时支持"全量"和"增量"两种模式
- **演进路径清晰**：从当前的"半自动"（生成草稿 → 人工 review → 合并）演进到将来的"全自动"（定时/hook 触发 → 直接写入 docs 或 PR）
- **作为 Wiki/CMS 的接口强化**：端用户侧的可发现性、可反馈性、LLM 友好度（详见 §1.5）
- **长期运营所需的自动化强化**：签名跳过、人工编辑保护、成本预估、审计、部分重生成（详见 §2.5）
- v1 的 sidebar (`/guide/`、`/manual/`、`/overview/`、`/admin/`、FAQ) **保持不动**
- v1 已实现的 scripts/ 大部分代码复用，仅需扩展

**仍然继承 v1 的核心原则**（人工 review、Claude Code 生成、独立仓库、中英双语、保持简单）。

**v2 的非目标：**

- 不做 `/use-cases/` 章节（需人工精选案例，暂缓）
- 不改 VitePress 主题或站点风格
- 不做视觉重构（Hermes 只是结构参考，不是视觉参考）
- MVP 阶段仍然是半自动，CI/CD 集成与无人值守模式只做**演进路径设计**，不落地

---

## 1. 新增文档章节规划

映射 Hermes docs 的信息架构到 Nexus-AI 语境：

| 章节 | 路径 | 文档数量估计 | 内容来源 | 主 prompt 类型 |
|------|------|-------------|---------|-------------|
| **功能特性** | `/features/` | 6-8 | `mcp_server/`、`sandbox/`、`nexus_utils/workflow/`、`nexus_utils/observability/`、`nexus_utils/multimodal_parser/`、`nexus_utils/bridge/`、`nexus_utils/event_scheduler/` 等子系统 | `feature-overview.md` |
| **集成** | `/integrations/` | 4-6 | `config/mcp/*.json`、AWS Bedrock、SSO (SAML)、Aurora/Valkey/DDB/SQS/S3 | `integration-guide.md` |
| **教程** | `/tutorials/` | 3-5 | `agents/generated_agents/` 中精选 3-5 个（如 stock_analysis_agent、pdf_content_extractor、aws_pricing_agent） | `tutorial.md` |
| **开发者指南** | `/developer/` | 3-4 | `CLAUDE.md`、`CONTRIBUTING.md`、`architecture/`、`setup_env_alinux2023.sh` | `developer-guide.md` |
| **参考** | `/reference/` | 4-5 | `nexus-cli --help`、`config/default_config.yaml`、FastAPI OpenAPI (`api/v2/main.py`)、部署参数（`nexus-cli deploy --help`）、IAM policies | `reference.md` |

**总计：约 20-28 篇新文档。** 每篇都有中英文版本 ≈ 40-56 个文件。

### 1.1 每章节的骨架

每个章节目录下先有一个 `index.md` 作为入口，列出该章节下的文档索引；然后是具体的文档文件。例如：

```
docs/
├── features/
│   ├── index.md                    # 章节入口
│   ├── mcp-server.md
│   ├── sandbox.md
│   ├── workflow-engine.md
│   ├── observability.md
│   ├── multimodal.md
│   └── en/                          # 英文镜像
│       ├── index.md
│       ├── mcp-server.md
│       └── ...
```

### 1.2 VitePress sidebar 变更

在 `docs/.vitepress/config.mts` 中增加新章节的 nav 和 sidebar 配置。顶级 nav 扩展为：

```
首页 | 快速上手 | 使用手册 | 功能特性 | 集成 | 教程 | 开发者 | 参考 | 了解更多
```

原"使用手册"、"了解更多"下拉保留，新增的章节每个都是一级顶部 nav。

### 1.5 端用户接口强化（作为 Wiki/CMS 的体验）

这一层是"用户读到的东西好不好用"。MVP 实现以下 4 项：

#### 1.5.1 `/llms.txt` 与 `/llms-full.txt`

VitePress 构建后，自动产出两份 LLM 友好的聚合文件：

- `/llms.txt` —— 轻量索引，列出所有文档标题 + URL + 一句描述（类似 sitemap，但给 LLM 看）
- `/llms-full.txt` —— 全部文档正文的单文件聚合（供一次性塞入 LLM context）

这样 Claude Code、Cursor、ChatGPT 等工具可以一次性加载整个 Playbook 做 context；高级用户也能直接下载。

**实现方式：** `scripts/lib/llms_txt.sh` 在全量/增量 run 结束时聚合 `docs/**/*.md`（跳过 `en/`、模板、隐藏文件），写入 `docs/public/llms.txt` 和 `llms-full.txt`。

#### 1.5.2 每篇文档的"新鲜度标记"

每篇生成的文档头部 frontmatter 写入：

```yaml
---
title: MCP 服务器
sync:
  source_commit: abc123de
  source_files:
    - mcp_server/handlers.py
    - config/mcp/system_mcp_server.json
  generated_at: 2026-05-07T08:30:00Z
  generated_by: docs-sync v2
---
```

VitePress 的 Layout 里（在自定义 theme 或页面组件）读取 frontmatter，在标题下显示：

> 📅 本页基于 Nexus-AI commit `abc123de` 生成于 2026-05-07（如发现过时，请 [报告问题](...)）

**实现方式：** 生成 prompt 约束 Claude 输出 frontmatter；主题层（`docs/.vitepress/theme/`）加一个小组件渲染该信息。

#### 1.5.3 Edit on GitHub / Report issue

VitePress 内置 `themeConfig.editLink`。config.mts 里配置：

```js
editLink: {
  pattern: 'https://github.com/hy714335634/Nexus-AI-Playbook/edit/main/docs/:path',
  text: '在 GitHub 上编辑此页'
}
```

外加自定义的 "Report issue" 链接（页脚或页头），链到 GitHub Issues 带预填模板。

**实现方式：** 一次性在 `config.mts` 配置（不是每次 sync 的工作），MVP 人工加上。

#### 1.5.4 术语表 `/glossary/`

`/glossary/index.md` 中英双版，收录 Nexus-AI 全部专有名词：Magician Agent、Orchestrator、Stage、Skill、Bridge、Sandbox、Valkey Stream Relay 等。每条术语：

```markdown
### Magician Agent（对话魔术师）

在对话发起时动态匹配/构建最合适的 Agent 以响应用户问题。详见 [对话测试](/manual/chat#智能对话路由)。
```

**实现方式：** 新增一个 chapter `glossary`，其 prompt 让 Claude 扫描所有源码+现有文档中出现的专有名词，产出一份结构化术语表。首次全量生成，后续增量运行也会更新。

---

## 2. 统一工作框架（核心设计）

### 2.1 两种工作模式

同一套 scripts/ 通过 `--mode` 参数切换：

| 模式 | 命令 | 输入 | 输出 | 用途 |
|------|------|------|------|------|
| **增量** (v1 保留) | `./scripts/sync.sh` | `last_sync.json` → HEAD 的 git diff | 受影响的现有文档草稿 | 日常跟上代码变更 |
| **全量** (v2 新增) | `./scripts/sync.sh --full --chapter <name>` | 整个 Nexus-AI 源码快照 | 整章节所有文档的草稿 | 初始化章节 / 大改版重写 |

### 2.2 config.yaml 扩展

v1 的 `mappings` 概念扩展为 `chapters` + `mappings`：

```yaml
source_repo:
  path: "../../Nexus-AI"
  default_branch: "main"

models:
  default: "claude-sonnet-4-6"
  complex: "claude-opus-4-7"

languages: [zh, en]

# 章节定义（新增于 v2）
# 每个章节声明：输出目录、本章节包含的文档、每个文档的生成配置
chapters:
  features:
    title: "功能特性"
    output_dir: "features"
    prompt_default: "feature-overview.md"
    docs:
      - slug: "mcp-server"
        title_zh: "MCP 服务器"
        title_en: "MCP Server"
        sources:
          - "mcp_server/**"
          - "nexus_utils/mcp/**"
        model: "default"
      - slug: "sandbox"
        title_zh: "Sandbox 沙箱运行时"
        title_en: "Sandbox Runtime"
        sources:
          - "nexus_utils/sandbox/**"
          - "infrastructure/sandbox/**"
      # ... 更多 docs

  integrations:
    title: "集成"
    output_dir: "integrations"
    prompt_default: "integration-guide.md"
    docs:
      - slug: "aws-bedrock"
        sources: ["nexus_utils/agent_factory.py", "config/default_config.yaml"]
      # ... 更多 docs

  tutorials:
    title: "教程"
    output_dir: "tutorials"
    prompt_default: "tutorial.md"
    docs:
      - slug: "build-stock-analysis-agent"
        sources: ["agents/generated_agents/stock_analysis_agent/**"]
      # ... 更多 docs

  developer:
    title: "开发者指南"
    output_dir: "developer"
    prompt_default: "developer-guide.md"
    docs:
      - slug: "architecture-overview"
        sources: ["CLAUDE.md", "architecture/**"]
      - slug: "contributing"
        sources: ["CONTRIBUTING.md"]
      - slug: "local-setup"
        sources: ["setup_env_alinux2023.sh", "pyproject.toml", "requirements.txt"]

  reference:
    title: "参考"
    output_dir: "reference"
    prompt_default: "reference.md"
    docs:
      - slug: "cli-commands"
        sources: ["nexus-cli", "nexus_utils/cli/**"]
      - slug: "config-options"
        sources: ["config/default_config.yaml", "config/service_config.yaml"]
      - slug: "api"
        sources: ["api/v2/routers/**", "api/v2/main.py"]
      - slug: "deploy-params"
        sources: ["infrastructure/**", "nexus-cli"]
      - slug: "iam-policies"
        sources: ["docs/infrastructure/IAM_POLICIES.md"]

# 增量映射（v1 保留 + 从 chapters 自动派生）
# v1 的 mappings 仍然存在用于跨章节的已有文档（manual/、admin/、overview/）
mappings:
  - id: "mcp-feature"
    watches: ["mcp_server/**", "config/mcp/**", "nexus_utils/mcp/**"]
    docs:
      - path: "manual/mcp.md"
        prompt: "feature-update.md"
  # ... 保持 v1 的映射不变

# 截图配置保持 v1
screenshots:
  enabled: "auto"
  base_url: "http://localhost:3000"
  output_dir: "../docs/public/images"
  login: { user: "admin", password: "nexus" }
```

### 2.3 全量模式执行流程

```
./sync.sh --full --chapter features
  ├── [1] Resolve    → 从 config.chapters.features.docs 展开所有文档
  ├── [2] Prepare    → 为每篇文档组装 context（源文件完整内容 + 章节骨架 + 现有同名文档若存在）
  ├── [3] Generate   → 每篇调用 claude -p 生成中英文
  ├── [4] Index      → 生成该章节的 index.md（中英文），列出本章节所有文档
  ├── [5] Screenshot → 可选截图（与 v1 一致）
  ├── [6] Sidebar    → 更新或生成该章节的 VitePress sidebar 片段（输出到 drafts/ 供 review）
  └── [7] Output     → drafts/SUMMARY.md 列出所有产出
```

### 2.4 增量模式（v1 继承 + 扩展）

```
./sync.sh  或  ./sync.sh --mode incremental
```

行为与 v1 一致，但现在检测范围包含 `chapters[*].docs[*].sources`：
- 如果某源文件在 diff 中，且匹配某 chapter doc 的 sources，触发该文档的增量更新
- 增量更新使用 `<chapter>-update.md` prompt（基于现有文档做修订），不是 `<chapter>-overview.md` 全量生成 prompt

### 2.5 自动化机制强化（维护者侧）

这一层是"长期运营的效率与安全"。MVP 实现以下 5 项：

#### 2.5.1 per-doc 内容签名（避免无效生成）

每次生成文档时，计算其所有 `sources` 文件内容的 sha256 聚合签名，写入 `scripts/state/signatures/<chapter>__<slug>.sha`。

下次 sync 时：
- 先重新计算签名
- 如果签名未变 → 跳过生成（避免无效 API 调用）
- 如果签名变化 → 进入正常生成流程

**例外：** `--force-regenerate` flag 忽略签名，全部重做。

这大幅降低全量/增量 run 的成本（尤其是长期维护中大部分文档不动的场景）。

#### 2.5.2 人工编辑保护

**核心约束：** Wiki 必须允许人工直接编辑 `docs/` 下的文档（修错字、补内容、微调措辞），且下一次 sync 不能无条件覆盖这些编辑。

策略（两层）：

1. **整页保护：** frontmatter 里加 `sync.protected: true` → 该文档完全不再自动生成
2. **段落保护：** 文档中用 HTML 注释标记保护区：
   ```markdown
   <!-- HUMAN-EDIT-START: custom-intro -->
   这一段是人工精心写的介绍，下次 sync 请保留。
   <!-- HUMAN-EDIT-END: custom-intro -->
   ```
   生成 prompt 里明确要求 Claude：**扫描目标文档中所有 `HUMAN-EDIT-START/END` 块，把它们原封不动地保留在新文档的相同上下文位置**。

signatures 在段落保护场景下需要区分对待：source 变但 human block 完好 → 正常覆盖其他部分；source 未变 → 直接跳过。

#### 2.5.3 成本预估与 dry-run preview

新增 flag：

```bash
./scripts/sync.sh --full --chapter features --estimate
```

仅计算：
- 本次会触发多少篇文档（基于签名对比）
- 每篇 context 的 token 数（调用 tokenizer；若没有现成 tokenizer，用字符数 ÷ 4 的粗估）
- 按配置的 model 单价估算总成本

输出示例：

```
Chapter 'features' will generate 3 of 6 docs (3 skipped by signature):
  - mcp-server        ~14k tokens  ~$0.08
  - sandbox           ~22k tokens  ~$0.13
  - workflow-engine   ~18k tokens  ~$0.10
  Total: ~$0.31  (Sonnet default)
```

不实际调用 Claude。用户确认后再去掉 `--estimate` 真正运行。

#### 2.5.4 运行审计日志

每次 `sync.sh` 实际运行时（不是 --estimate / --dry-run），写一份：

```
scripts/state/runs/2026-05-07T08-30-00Z.json
```

内容：

```json
{
  "timestamp": "2026-05-07T08:30:00Z",
  "mode": "full",
  "chapter": "features",
  "trigger": "cli",
  "source_commit": "abc123",
  "docs": [
    {"slug": "mcp-server", "status": "generated", "tokens": 14320, "model": "claude-sonnet-4-6", "cost_usd": 0.08, "human_blocks_preserved": 2},
    {"slug": "sandbox", "status": "skipped_signature", "signature": "deadbeef..."},
    {"slug": "workflow-engine", "status": "failed", "error": "..."}
  ],
  "total_cost_usd": 0.21,
  "total_elapsed_s": 87,
  "exit_code": 0
}
```

这份日志是阶段 2/3/4 自动化的基础数据源（用于通知、看板、回滚）。

#### 2.5.5 部分重生成

新增 flag 支持更细粒度的目标：

```bash
./scripts/sync.sh --full --chapter features --doc mcp-server       # 只重做这一篇
./scripts/sync.sh --full --chapter features --force-regenerate     # 忽略签名，全章节重做
./scripts/sync.sh --regenerate-index --chapter features            # 只重做 index
```

这对 MVP 阶段频繁迭代 prompt、修 bug 很关键。

#### 2.5.6 留给阶段 B 的钩子（不实现但预留）

- **质量门 (quality gates)：** 生成后自动检查 zh/en 结构对齐、无悬空链接、frontmatter 完整。可以加 `scripts/lib/quality_check.sh` 骨架但不强制。
- **变更通知：** Slack / email 通知。审计日志已经准备好，阶段 2 加个 notify 脚本即可。
- **多层审核：** PR 模式下多人 review，目前不涉及。

### 2.6 Sidebar 管理策略

VitePress 的 sidebar 写在 `docs/.vitepress/config.mts`。自动更新配置文件风险大，采用以下策略：

1. **人工一次性创建** 主 config.mts 中每个章节的 sidebar 占位（空数组或基础项）
2. **scripts/ 生成 sidebar 片段** 到 `drafts/sidebar/<chapter>.json`，给人工 review 后手动粘贴
3. 这样 config.mts 仍然 human-owned，只是内容按生成的文档列表更新

MVP 阶段这样手工对接即可；将来自动化可以扩展为安全的 AST 修改或 include。

---

## 3. Prompt 模板扩展

v1 已有：`style-guide.md`、`feature-update.md`、`config-reference.md`。

v2 新增以下 prompt 模板（都在 `scripts/prompts/` 下）：

| 模板 | 用于 | 与 feature-update 的差异 |
|------|------|-----------------------|
| `feature-overview.md` | 全量生成 features 章节文档 | 从零描述一个功能模块，不需要 "diff 受影响部分" 的概念 |
| `integration-guide.md` | 全量生成 integrations 章节文档 | 强调"如何集成"，包含配置示例、步骤、验证 |
| `tutorial.md` | 全量生成 tutorials 章节文档 | 结构是"目标 → 前置 → 步骤 → 验证 → 下一步"，分步教程 |
| `developer-guide.md` | 全量生成 developer 章节文档 | 面向开发者，可以出现架构名词、目录结构、扩展点 |
| `reference.md` | 全量生成 reference 章节文档 | 结构化、表格化，不需要叙事（CLI help 转表、配置项转表、API endpoint 转表） |
| `chapter-index.md` | 生成章节的 index.md | 列出本章节所有文档的简要介绍 |
| `glossary.md` | 生成 `/glossary/` 术语表 | 从源码+现有文档中扫描专有名词，按字母顺序结构化输出 |

所有 prompt 统一约束：

- 必读 `style-guide.md`
- 面向终端用户（除 developer-guide.md）
- 中英文对齐
- UI 相关插入 `<!-- SCREENSHOT: ... -->` 占位符
- 输出到 `OUTPUT_ZH` / `OUTPUT_EN` 指定绝对路径
- **输出 frontmatter 必须包含 `sync` 节** (见 §1.5.2)
- **保留 `HUMAN-EDIT-START/END` 块**：生成前从现有文档中提取所有此类块；生成时将它们原位保留（见 §2.5.2）

---

## 4. 自动化演进路径

这是你的核心需求：**现在半自动，将来能平滑演进到全自动**。

### 4.1 阶段设计

| 阶段 | 触发方式 | 审核方式 | 合并方式 | 输出位置 |
|------|---------|---------|---------|---------|
| **阶段 1（MVP，当前）** | 手动运行 `./sync.sh` | 人工 diff `drafts/` vs `docs/` | 手动 `cp` | `drafts/` |
| **阶段 2（轻度自动）** | cron / launchd 每天一次 | 邮件/Slack 通知"有草稿待 review" | 手动 `cp` 或一键合并脚本 | `drafts/` + 通知 |
| **阶段 3（PR 模式）** | GitHub Action on push to Nexus-AI | GitHub PR review 界面 | PR 合并 | 自动生成 PR 到 Playbook |
| **阶段 4（无人值守）** | GitHub Action 定时/push | 可选 AI 自检 + 质量门禁 | 自动合并（加 rollback 机制） | 直接 `docs/` + revert 能力 |

**MVP 只实现阶段 1。但框架设计需要满足阶段 2/3/4 无需重写核心逻辑。**

### 4.2 为演进预留的设计约束

1. **无状态执行**：`scripts/sync.sh` 一次调用就能完成所有工作（cron-ready）
2. **幂等性**：相同输入多次运行输出一致（不依赖全局变量/随机种子）
3. **机器可读的输出结构**：SUMMARY.md 之外还输出 `drafts/summary.json`（后续自动化消费）
4. **非交互**：所有 prompt 走 `--allowed-tools "Read,Write"` + `--permission-mode acceptEdits`（v1 已是）
5. **明确的退出码**：成功 0、部分失败 1、致命错误 2（供 CI 判断）
6. **可追踪**：每次运行写 `state/runs/<timestamp>.json` 记录谁触发、输入、输出文件列表（方便审计与回滚）

### 4.3 具体的阶段 2 落地路径（后续可做）

给你一个粗略的预览（不在 MVP 实施范围内）：

```bash
# /etc/cron.daily/nexus-docs-sync
cd /path/to/Nexus-AI-Playbook
./scripts/sync.sh                                           # 生成 drafts/
if [ -s drafts/summary.json ]; then
    /usr/local/bin/notify-slack "Playbook 有 $(jq .new_drafts_count drafts/summary.json) 份待 review"
fi
```

阶段 3/4 等需要时再设计。

---

## 5. 目录结构更新

v1 的结构基础上新增：

```
Nexus-AI-Playbook/
├── docs/
│   ├── (v1 保留: guide/ manual/ overview/ admin/ faq.md)
│   ├── features/           # NEW
│   │   ├── index.md
│   │   ├── en/
│   │   └── *.md
│   ├── integrations/       # NEW
│   ├── tutorials/          # NEW
│   ├── developer/          # NEW
│   ├── reference/          # NEW
│   ├── glossary/           # NEW: 术语表（中英双版）
│   │   ├── index.md
│   │   └── en/index.md
│   ├── public/
│   │   ├── (现有 images/ 等保留)
│   │   ├── llms.txt        # NEW: 轻量索引 (for LLMs)
│   │   └── llms-full.txt   # NEW: 全量聚合 (for LLMs)
│   └── .vitepress/
│       └── theme/
│           ├── (现有保留)
│           └── SyncFreshness.vue  # NEW: 文档"新鲜度标记"小组件
│
├── scripts/
│   ├── (v1 保留: config.yaml, sync.sh, lib/*, prompts/*, screenshots/*, state/*)
│   ├── lib/
│   │   ├── (v1 保留)
│   │   ├── resolve.sh         # NEW: Stage 0 for --full, expand chapter→docs
│   │   ├── full_generate.sh   # NEW: --full mode orchestration
│   │   ├── signatures.sh      # NEW: compute/compare content sha256 per doc
│   │   ├── estimate.sh        # NEW: token & cost estimation (no API call)
│   │   ├── index_gen.sh       # NEW: chapter index.md generator
│   │   ├── sidebar_gen.sh     # NEW: sidebar JSON fragment generator
│   │   ├── llms_txt.sh        # NEW: aggregate docs/*.md → llms.txt / llms-full.txt
│   │   └── audit.sh           # NEW: write state/runs/<ts>.json
│   ├── prompts/
│   │   ├── (v1 保留: style-guide.md, feature-update.md, config-reference.md)
│   │   ├── feature-overview.md     # NEW
│   │   ├── integration-guide.md    # NEW
│   │   ├── tutorial.md             # NEW
│   │   ├── developer-guide.md      # NEW
│   │   ├── reference.md            # NEW
│   │   ├── chapter-index.md        # NEW
│   │   └── glossary.md             # NEW: 术语表扫描与编写
│   └── state/
│       ├── (v1 保留: last_sync.json, work/, errors.log, changes.json)
│       ├── signatures/              # NEW: per-doc sha256 (<chapter>__<slug>.sha)
│       └── runs/                    # NEW: per-run audit logs (JSON)
│
└── drafts/
    ├── (v1 保留结构)
    ├── features/           # NEW: per-chapter drafts
    ├── integrations/       # NEW
    ├── tutorials/          # NEW
    ├── developer/          # NEW
    ├── reference/          # NEW
    ├── glossary/           # NEW
    ├── sidebar/            # NEW: generated sidebar fragments (chapter-scoped JSON)
    └── summary.json        # NEW: machine-readable summary for automation
```

---

## 6. CLI 扩展

v1 的 flags 全部保留。v2 新增：

| Flag | 作用 |
|------|------|
| `--full` | 进入全量模式 |
| `--chapter <name>` | 指定要处理的章节（全量模式必填；增量模式可选过滤） |
| `--doc <slug>` | 在 `--full --chapter` 基础上进一步限定到一篇文档 |
| `--list-chapters` | 列出 config.yaml 中所有章节 |
| `--regenerate-index` | 只重新生成某章节的 index.md |
| `--regenerate-sidebar` | 只重新生成 sidebar 片段 |
| `--estimate` | 仅估算本次 run 的文档数与成本，不调用 Claude |
| `--force-regenerate` | 忽略 signatures，强制重新生成 |
| `--emit-llms-txt` | 重新生成 `docs/public/llms.txt` 与 `llms-full.txt`（run 结束默认也会做） |

示例：

```bash
# 一次性生成 features 章节所有文档
./scripts/sync.sh --full --chapter features

# 先估算再跑
./scripts/sync.sh --full --chapter features --estimate
./scripts/sync.sh --full --chapter features

# 只重做单篇
./scripts/sync.sh --full --chapter features --doc mcp-server

# 列出章节
./scripts/sync.sh --list-chapters

# 仅重新生成 tutorials 的 index 页
./scripts/sync.sh --regenerate-index --chapter tutorials
```

---

## 7. 实施分阶段（MVP → 演进）

### 阶段 A（MVP，本次实施）

- 扩展 `config.yaml` 加入 `chapters` 配置，填充 5 个章节（+ glossary）的 docs 清单
- 新增 7 个 prompt 模板（feature-overview / integration-guide / tutorial / developer-guide / reference / chapter-index / glossary）
- 新增 flag：`--full`、`--chapter`、`--doc`、`--list-chapters`、`--regenerate-index`、`--regenerate-sidebar`、`--estimate`、`--force-regenerate`、`--emit-llms-txt`
- 新增 lib：`resolve.sh`、`full_generate.sh`、`signatures.sh`、`estimate.sh`、`index_gen.sh`、`sidebar_gen.sh`、`llms_txt.sh`、`audit.sh`
- 生成 prompt 中约束 frontmatter `sync:*` 字段与 `HUMAN-EDIT-START/END` 保留逻辑
- VitePress 主题新增 `SyncFreshness.vue` 组件，每页显示新鲜度
- `config.mts` 新增 `editLink` 配置与 5 个新章节 + glossary 的顶级 nav + 空 sidebar 占位（人工一次性）
- 分章节执行全量生成 —— review —— 合并

### 阶段 B（后续迭代，不在本次范围）

- `/use-cases/` 章节
- cron 自动触发 + 通知
- GitHub Action PR 模式
- 文档质量自检

---

## 8. 与 v1 的兼容性

- v1 的增量模式（针对 `manual/mcp.md`、`manual/create-agent.md`、`admin/settings.md` 三个现有文档）完全保留
- v1 的 scripts/ 文件大部分不动；新增 lib 脚本与 prompt 模板；`sync.sh` 的主入口扩展 flag
- v1 的 `state/last_sync.json` 仍然驱动增量模式
- v2 的 `chapters` 和 v1 的 `mappings` 共存：
  - `mappings` 继续负责对 **现有既有文档** 的增量更新
  - `chapters` 负责 **新章节的全量生成 + 该章节自己的增量维护**

---

## 9. 成功标准

本 v2 MVP 成功的判据：

1. `./scripts/sync.sh --full --chapter features` 一次运行产出 `drafts/features/` 下 6-8 个中文文档 + 等量英文镜像 + `index.md` + sidebar 片段
2. 其他 4 个章节（`integrations`、`tutorials`、`developer`、`reference`）+ 1 个附加章节 `glossary` 同样能通过一次命令完成
3. 生成的文档：
   - 符合 `style-guide.md`（面向终端用户，除 developer 外）
   - 中英文结构对齐
   - 真实引用源码中的特性（不编造）
   - 每篇 frontmatter 含 `sync.source_commit`、`sync.source_files`、`sync.generated_at`
4. 人工在 `docs/.vitepress/config.mts` 合并 sidebar 片段后，VitePress `npm run docs:dev` 能正常渲染 5 个新章节与 glossary；"新鲜度标记"组件在每页正常显示
5. v1 的增量同步功能仍可正常工作（回归）
6. `drafts/summary.json` 与 `state/runs/<ts>.json` 产出结构化信息
7. **Wiki 维护能力验证：**
   - 跑一次 sync → 人工在某篇生成的文档中加一个 `HUMAN-EDIT-START/END` 块 + 改一行 frontmatter 外的文字 → 再跑一次 sync（强制重做）→ 验证 HUMAN-EDIT 块原封不动，其他部分按代码更新
   - 跑一次 `--estimate` → 不调用 API，输出预估文档数和 token/成本
   - signatures 在源码无变更时使 sync 跳过已处理文档
8. `docs/public/llms.txt` 和 `llms-full.txt` 可访问（构建后 URL `/playbook/llms.txt` 返回聚合索引）

---

## 10. 开放问题（待实施中明确）

- **tutorials 的 3-5 个案例精选**：从 `agents/generated_agents/` 里挑哪几个？建议：`stock_analysis_agent`、`pdf_content_extractor`、`aws_pricing_agent`（领域、复杂度各不同，覆盖面好）
- **features 章节的最终清单**：源码子系统较多，最终列 6-8 篇还是 8-10 篇？由 plan 阶段确定
- **VitePress 顶级 nav 是否太长？** 9 项顶级可能显得拥挤。可以用 dropdown 分组（"产品"/"开发"/"参考"三个下拉），plan 阶段细化
