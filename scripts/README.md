# Playbook 文档同步工具操作手册

本目录是 **Nexus-AI-Playbook 文档自动生成与同步框架**。它基于 Nexus-AI 源代码仓库自动生成 VitePress 用户手册内容，并长期维护增量更新。

> 设计与架构见 [`docs/superpowers/specs/2026-05-07-playbook-docs-sync-v2-design.md`](../docs/superpowers/specs/2026-05-07-playbook-docs-sync-v2-design.md)，当前落地进度见 [`docs/superpowers/STATUS.md`](../docs/superpowers/STATUS.md)。

---

## 1. 先决条件

| 工具 | 用途 | 检查命令 |
|------|------|---------|
| `bash` 4+ | 管道宿主 | `bash --version` |
| `python3` + `pyyaml` | YAML 解析 | `python3 -c "import yaml"` |
| `jq` | JSON 处理 | `jq --version` |
| `claude` CLI | 文档生成引擎 | `claude --version` |
| `node` 18+ + Playwright (可选) | 自动截图 | `node --version` |
| 本地 clone 了 `Nexus-AI` 仓库 | 源码输入 | `ls ../../Nexus-AI/.git` |

**模型**：当前默认 `global.anthropic.claude-opus-4-7`（Opus 4.7），在 `config.yaml` 的 `models.default` 字段配置。

---

## 2. 目录结构

```
scripts/
├── config.yaml                 # 主配置：源码路径、章节定义、模型、截图
├── sync.sh                     # 主入口命令
├── lib/                        # 管道各阶段实现
│   ├── common.sh               # 共享 helpers（SCRIPTS_DIR、yaml_get、run_id 等）
│   ├── detect.sh               # 【增量模式】Stage 1: git diff + mapping 匹配
│   ├── prepare.sh              # 【增量模式】Stage 2: 组装 context
│   ├── generate.sh             # 【增量模式】Stage 3: 调用 claude -p
│   ├── screenshot.sh           # Stage 4: Playwright 截图（可选）
│   ├── output.sh               # Stage 5: 生成 drafts/SUMMARY.md
│   ├── resolve.sh              # 【全量模式】Stage 0: chapter → work-plan.json
│   ├── full_generate.sh        # 【全量模式】主编排
│   ├── index_gen.sh            # 生成章节 index.md
│   ├── sidebar_gen.sh          # 生成 VitePress sidebar JSON 片段
│   ├── estimate.sh             # --estimate 成本预估（不调 API）
│   ├── audit.sh                # 写 state/runs/*.json 审计日志
│   ├── signatures.sh           # 内容哈希跳过未变更文档
│   ├── llms_txt.sh             # 聚合 docs/*.md 到 llms.txt / llms-full.txt
│   ├── human_edit.py           # 提取/校验 HUMAN-EDIT 块
│   ├── migrate_human_edit.py   # 首次把手写文档包成 HUMAN-EDIT 块
│   ├── sanitize_md.py          # 转义 <placeholder> 让 Vue 编译器不报错
│   ├── match_mappings.py       # Python: glob 匹配增量 mappings
│   ├── _expand_sources.py      # Python: glob 展开源文件列表
│   ├── _format_sources.py      # Python: 把文件内容格式化进 sources.md
│   └── yaml_helper.py          # Python: YAML→JSON 桥（给 bash 用 jq 查）
├── prompts/                    # Claude Code 使用的 prompt 模板
│   ├── style-guide.md          # 全局文风约束（frontmatter / HUMAN-EDIT 规则）
│   ├── feature-overview.md     # Features 章节生成用
│   ├── feature-update.md       # 增量模式 / Using 章节用
│   ├── integration-guide.md    # Integrations 章节用
│   ├── tutorial.md             # Guides 章节用
│   ├── developer-guide.md      # Developer 章节用（参考级详尽度）
│   ├── reference.md            # Reference 章节用（穷举级）
│   ├── chapter-index.md        # 章节 index.md 生成用
│   ├── config-reference.md     # 旧版配置参考
│   └── glossary.md             # 术语表生成用
├── screenshots/                # Playwright 自动截图脚本
│   ├── capture.js              # 截图入口
│   ├── targets.yaml            # 要截图的页面清单
│   └── package.json            # playwright + js-yaml 依赖
└── state/                      # 运行时状态（git 跟踪）
    ├── last_sync.json          # 增量模式：上次同步到的 commit SHA
    ├── work/                   # gitignored: 本次 run 的 per-doc context
    ├── changes.json            # gitignored: detect 产出的变更清单
    ├── work-plan.json          # gitignored: resolve 产出的章节任务计划
    ├── errors.log              # gitignored: 错误汇总
    ├── signatures/             # <chapter>__<slug>.sha，用于跳过未变更文档
    └── runs/                   # 每次 run 的 JSON 审计日志
```

---

## 3. 两种工作模式

### 3.1 全量模式（`--full`）

**用途：** 首次为某章节生成完整内容 / 大改版重写 / 源码结构大调整后重做某章节。

**示例：**

```bash
# 为 features 章节全量生成所有文档（zh+en）
./scripts/sync.sh --full --chapter features
```

**产出：** `drafts/features/*.md` + `drafts/features/en/*.md` + `drafts/features/index.md` + `drafts/sidebar/features.json`。**不会**直接写 `docs/`（保护已有内容），需人工合并。

### 3.2 增量模式（默认）

**用途：** Nexus-AI 代码变更后，追赶受影响的文档（基于 git diff + `config.yaml` 中的 `mappings`）。

**示例：**

```bash
# 从 last_sync.json 里记录的 commit 到当前 HEAD，跑增量同步
./scripts/sync.sh

# 回放历史 commit 范围
./scripts/sync.sh --from abc123 --to def456

# 首次使用前设置同步基线（避免一上来把整个历史当"变更"）
./scripts/sync.sh --init <sha>
```

---

## 4. 日常工作流

### 4.1 首次为一个章节生成内容

```bash
# 1. 预估成本（不调 API，可随时跑）
./scripts/sync.sh --estimate --chapter features

# 2. 满意后真跑
./scripts/sync.sh --full --chapter features

# 3. 人工 review drafts/features/ 下的草稿

# 4. 合并到正式文档
mkdir -p docs/features/en
cp drafts/features/*.md docs/features/
cp drafts/features/en/*.md docs/features/en/

# 5. 同步 sidebar 片段到 docs/.vitepress/config.mts
#    （打开 drafts/sidebar/features.json，把 items 粘贴到对应章节位置）

# 6. 刷新 llms.txt 聚合（可选；每次 --full 结束也会自动刷）
./scripts/sync.sh --emit-llms-txt

# 7. 构建验证
npm run docs:build

# 8. 提交
git add docs/features docs/public/llms.txt docs/public/llms-full.txt \
        scripts/state/runs scripts/state/signatures
git commit -m "docs(features): full-generate chapter"
```

### 4.2 仅重做某一篇

```bash
# 只重新生成 features/mcp-server 这一篇，其它不动
./scripts/sync.sh --full --chapter features --doc mcp-server

# 如果源码没变，默认会因签名匹配而跳过；强制重做加 --force-regenerate
./scripts/sync.sh --full --chapter features --doc mcp-server --force-regenerate
```

### 4.3 代码变更后增量同步（日常维护）

```bash
# Nexus-AI 有新 commit 后
./scripts/sync.sh

# 只看会触发什么，不真跑
./scripts/sync.sh --dry-run

# 只跑一个 mapping
./scripts/sync.sh --mapping mcp-feature

# 合并草稿后，把 last_sync.json 推进到新的 HEAD
./scripts/sync.sh --commit-sync
```

### 4.4 仅重建 index.md 或 sidebar 片段

```bash
./scripts/sync.sh --regenerate-index --chapter features
./scripts/sync.sh --regenerate-sidebar --chapter features
```

### 4.5 预处理：手写内容迁移保护

把 `docs/manual/foo.md` 这类手写文档迁入新章节，让下次 `--full` 不覆盖它：

```bash
mkdir -p docs/using
git mv docs/manual/chat.md docs/using/chat.md
python3 scripts/lib/migrate_human_edit.py docs/using/chat.md docs/using/chat.md chat
```

此后该文档被 `<!-- HUMAN-EDIT-START/END -->` 块包裹；Claude 在下次生成时会 **逐字保留** 该块内的内容。

### 4.6 全站 Markdown 卫生处理

生成文档可能含 `<uuid>`、`<name>` 等占位符 token，Vue 编译器会把它们当成未关闭标签，导致 `npm run docs:build` 失败。每次合并草稿后（或构建失败时）跑一次：

```bash
find docs -name '*.md' -not -path 'docs/superpowers/*' \
  | xargs python3 scripts/lib/sanitize_md.py
```

脚本里有一份 `KNOWN_TAGS` 白名单（`<style>`、`<div>` 等真实 HTML 标签），不会被误转义。

---

## 5. CLI 完整参考

运行 `./scripts/sync.sh --help` 会打印：

```
v1 flags (incremental-patch pipeline):
  --dry-run                     detect + prepare 阶段，不调 API
  --only-detect                 仅 detect
  --mapping <id>                限定到单个 mapping
  --from <sha> --to <sha>       手工指定 commit 范围
  --init <sha>                  初始化 last_sync.json 基线
  --commit-sync                 把 last_sync.json 推进到当前 changes.json 的 to_sha

v2 flags (full chapter generation):
  --full --chapter <name>       对整章节全量生成
  --doc <slug>                  与 --full 配合，只生成该章节的一篇
  --force-regenerate            忽略 signatures，强制重做
  --estimate                    打印 token / 成本预估，不调 API
  --list-chapters               列出 config.yaml 中所有章节
  --regenerate-index            与 --chapter 配合，仅重做 index.md
  --regenerate-sidebar          与 --chapter 配合，仅重做 sidebar JSON 片段
  --emit-llms-txt               刷新 docs/public/llms*.txt
```

---

## 6. config.yaml 要点

| 字段 | 含义 |
|------|------|
| `source_repo.path` | Nexus-AI 仓库相对 `scripts/` 的路径（默认 `../../Nexus-AI`） |
| `models.default` | 日常生成模型；当前 `global.anthropic.claude-opus-4-7` |
| `models.complex` | 复杂场景模型（架构/大改），可在某篇 `docs[].model: complex` 里引用 |
| `languages` | 输出语言顺序，默认 `[zh, en]` |
| `chapters.<id>.title_zh/title_en` | 章节中英文标题，用于 sidebar / index / frontmatter |
| `chapters.<id>.output_dir` | 章节输出目录名（相对 `docs/`） |
| `chapters.<id>.prompt_default` | 该章节默认 prompt 文件名（在 `scripts/prompts/` 下） |
| `chapters.<id>.docs[].slug` | 文档 URL 段 |
| `chapters.<id>.docs[].sources` | 该文档的源文件 glob 列表（相对 Nexus-AI 根） |
| `mappings[*]` | 增量模式：文件变更 → 文档 的触发规则 |
| `screenshots.*` | Playwright 截图目标、登录凭据、base_url |
| `run.pricing.default/complex` | 成本预估用的 $/MTok 价目表 |

**加一个新章节的步骤：**

1. 在 `chapters:` 下新增一节，填 `title_zh/title_en/output_dir/prompt_default/docs[]`
2. 在 `docs/.vitepress/config.mts` 的 `SIDEBAR` 数组里加对应条目
3. 跑 `./scripts/sync.sh --estimate --chapter <新章节>` 看成本
4. 跑 `./scripts/sync.sh --full --chapter <新章节>`
5. 合并草稿 + 同步 sidebar JSON + 构建验证

---

## 7. 产出位置速查

| 类型 | 路径 |
|------|------|
| 本次运行的章节草稿 | `drafts/<chapter>/*.md` 和 `drafts/<chapter>/en/*.md` |
| 章节入口页 | `drafts/<chapter>/index.md`（zh+en） |
| VitePress sidebar 片段 | `drafts/sidebar/<chapter>.json` 和 `<chapter>-en.json` |
| 摘要页 | `drafts/SUMMARY.md` |
| 本次 run 审计 | `scripts/state/runs/<timestamp>.json` |
| 每篇文档的内容签名 | `scripts/state/signatures/<chapter>__<slug>.sha` |
| LLM 友好聚合 | `docs/public/llms.txt`、`docs/public/llms-full.txt` |
| 错误日志 | `scripts/state/errors.log` |

---

## 8. 故障排查

| 症状 | 可能原因 | 处理 |
|------|---------|------|
| `claude: command not found` | Claude Code CLI 未安装或不在 PATH | 安装或补 PATH |
| `API Error: 400 model identifier is invalid` | 模型 ID 过时 | 更新 `config.yaml` 的 `models.default`，使用 Bedrock cross-region 前缀（如 `us.anthropic.…` 或 `global.anthropic.…`） |
| `No from_sha` | 增量模式下 `last_sync.json` 未初始化 | `./scripts/sync.sh --init <sha>` |
| 生成的草稿为空 | Claude 写错路径或 prompt 太难 | 查 `scripts/state/runs/*.json` 中 `status` 与 `error`，加 `--force-regenerate --doc <slug>` 重试 |
| `npm run docs:build` 报 `Element is missing end tag` | 文档含 `<uuid>` 等占位符被 Vue 当标签解析 | 跑 `find docs -name '*.md' -not -path 'docs/superpowers/*' \| xargs python3 scripts/lib/sanitize_md.py` |
| 某页签名不匹配但源码没变 | 改过 `config.yaml` 的 sources | 是预期行为。删除 `scripts/state/signatures/<chapter>__<slug>.sha` 后重跑，或用 `--force-regenerate` |
| 截图全部失败落在 TODO | Nexus-AI Web 服务未运行 | 正常 fallback；启动服务后重跑 `--only-detect` 再 `--full` |
| 估算成本过高 | `sources:` 面积过大（含 `**/**`） | 收窄 glob，避免整体 `api/v2/**` 之类的全量加载 |

---

## 9. 阶段 1 完成状态

截至 commit `5b97ced`：

- 7 个 Hermes 风格章节全部落地：`getting-started` / `using` / `features` / `integrations` / `guides` / `developer` / `reference`
- 55 × (zh + en) = 110 篇内容文档 + 7 个 index = 117 个 .md
- 所有页面含 `sync.source_commit` 新鲜度 frontmatter
- `HUMAN-EDIT` 块保护机制经 `using/` 章节实证
- `docs/public/llms.txt` 77 条目，`llms-full.txt` ~1.0 MB

**阶段 2 演进路径**（spec v2 §4 设计，未落地）：

1. cron/launchd 定时触发 + Slack 通知（已留审计日志钩子）
2. GitHub Action + 自动 PR 模式
3. 无人值守 + 质量门 + 自动回滚

---

## 10. 快速上手（TL;DR）

```bash
# 看看有哪些章节
./scripts/sync.sh --list-chapters

# 预估成本
./scripts/sync.sh --estimate --chapter features

# 全量生成一个章节（产出到 drafts/）
./scripts/sync.sh --full --chapter features

# 人工 review 后合并
cp drafts/features/*.md docs/features/
cp drafts/features/en/*.md docs/features/en/

# 清理 Vue 占位符兼容问题
find docs -name '*.md' -not -path 'docs/superpowers/*' \
  | xargs python3 scripts/lib/sanitize_md.py

# 构建验证
npm run docs:build

# 提交
git add docs/features docs/public/llms.txt docs/public/llms-full.txt \
        scripts/state/runs scripts/state/signatures
git commit -m "docs(features): full-generate chapter"
```
