# Playbook 文档优化指南

> 本指南按章节给出 **当前内容清单、薄弱环节诊断、优化机会** 与 **可直接复制的 sync.sh 命令**。你可以按 topic 一个个跑。

**基线：** Phase 1 结束时（commit `382ce21`），共 55 篇内容文档 + 7 章节 index；模型 `global.anthropic.claude-opus-4-7`；签名机制使未变动源码时自动跳过重跑。

---

## 0. 通用工作流（每次优化都一样）

不管优化哪一篇/哪一章，都是这 4 步：

```bash
# 1. 预估 — 看这次要花多少钱
./scripts/sync.sh --estimate --chapter <ch> [--doc <slug>]

# 2. 生成 — 草稿进 drafts/，docs/ 不动
./scripts/sync.sh --full --chapter <ch> [--doc <slug>] --force-regenerate

# 3. Review + 合并
diff docs/<ch>/<slug>.md drafts/<ch>/<slug>.md | head -60
cp drafts/<ch>/<slug>.md docs/<ch>/
cp drafts/<ch>/en/<slug>.md docs/<ch>/en/

# 4. 收尾
python3 scripts/lib/sanitize_md.py docs/<ch>/<slug>.md docs/<ch>/en/<slug>.md
npm run docs:build
./scripts/sync.sh --emit-llms-txt
git add docs/<ch>/ docs/public/llms*.txt scripts/state/signatures/ scripts/state/runs/
git commit -m "docs(<ch>/<slug>): optimize — <one-line reason>"
```

**`--force-regenerate` 的作用：** 默认情况下 `--full` 会根据 `scripts/state/signatures/` 判断源文件是否变过；变了才重跑。优化场景里源文件往往没变 → 必须加 `--force-regenerate` 才会真跑。

**`--doc <slug>` 的作用：** 精确到一篇，其他篇即便触发了也不会跑。成本最小化。

---

## 1. `getting-started`（5 页，ERP 级入门）

### 当前内容

| Slug | 行数 | 主题 |
|------|------|------|
| `quickstart` | 166 | 5 分钟跑通第一个 Agent |
| `installation` | 165 | Python 3.13 / pip / venv / AWS 凭据 |
| `aws-setup` | 185 | IAM / Bedrock / 存储 / 网络 |
| `updating` | 169 | 升级 / 卸载 / 回滚 |
| `learning-path` | 131 | 按角色（用户/管理员/开发者）推荐阅读路径 |

### 典型薄弱点

- **macOS / Windows WSL2** 路径现在基本没写（主要写 Linux），`installation.md` 可以扩充平台差异。
- **Troubleshooting** 放在 `reference/faq` 里，入门页没有直接连过去的 "遇到问题？" 卡片。
- **`learning-path`** 偏抽象，可以补一份 "第一天 / 第一周 / 第一月" 的时间盒推荐。

### 优化命令

```bash
# 只优化 installation 一篇
./scripts/sync.sh --estimate --chapter getting-started --doc installation
./scripts/sync.sh --full --chapter getting-started --doc installation --force-regenerate

# 全章节重做（含 index）
./scripts/sync.sh --estimate --chapter getting-started
./scripts/sync.sh --full --chapter getting-started --force-regenerate
```

---

## 2. `using`（8 页，用户手册，⚠️ 含 HUMAN-EDIT 保护）

### 当前内容

| Slug | 行数 | 主题 | HUMAN-EDIT |
|------|------|------|-----------|
| `dashboard` | 137 | 工作台 | ✅ 保留原手写 |
| `create-agent` | 260 | 创建 Agent（快速/引导两模式） | ✅ |
| `build-progress` | 330 | 8 个 Builder Agent 协作进度 | ✅ |
| `chat` | 247 | 对话 + 多模态 | ✅ |
| `projects` | 150 | 项目管理 | ✅ |
| `manage-agents` | 243 | Agent 管理/版本/发布 | ✅ |
| `tools` | 232 | 工具库 | ✅ |
| `mcp` | 241 | MCP 服务器对外暴露 | ✅ |

### ⚠️ 重要约束

每页都有一个 `<!-- HUMAN-EDIT-START: manual-<slug> --> ... <!-- HUMAN-EDIT-END: manual-<slug> -->` 块，包含从 `docs/manual/` 迁入的原始手写内容。**Claude 规定会逐字保留这些块**，所以：

- 想把原手写内容替换成新生成的 → **先移除 HUMAN-EDIT 标记**（变成正常段落），再跑 `--full`；否则新生成的内容会夹在被保留的旧块旁边，文档臃肿。
- 想保持原手写不变，只补充新章节 → 正常跑 `--full`，Claude 会在保留旧块的同时新增小节。

### 典型薄弱点

- 每篇都有 2 份内容（原手写 + 生成的），**长度臃肿**。可视情况修剪 HUMAN-EDIT 块。
- 若 Nexus-AI 的 UI 改版，截图会滞后。Playwright 截图脚本目前在 `scripts/screenshots/` 但未在优化流程里被调用。

### 优化命令

```bash
# 典型：保留原手写，仅补充 claude 生成的新章节
./scripts/sync.sh --full --chapter using --doc chat --force-regenerate

# 完全重写某篇（放弃原手写）
#   先编辑 docs/using/<slug>.md，手工删掉 <!-- HUMAN-EDIT-START/END --> 标记
#   再跑 --full --force-regenerate
```

---

## 3. `features`（13 页，功能特性详解）

### 当前内容

| Slug | 行数 | 主题 |
|------|------|------|
| `tools-toolsets` | 151 | 工具与工具集 |
| `skills-system` | 144 | 技能系统 |
| `agent-factory` | 124 | Agent Factory |
| `prompt-templates` | 113 | 提示词模板 |
| `sandbox` | 147 | Sandbox 沙箱运行时 |
| `workflow-engine` | 144 | 工作流引擎 |
| `multi-agent` | 167 | 多 Agent 图 / 群 |
| `stream-relay` | 83 ⚠️ | 流式响应中继（最短） |
| `event-scheduler` | 174 | 事件调度 |
| `bridge` | 155 | Bridge 多连接 |
| `observability` | 275 | 可观测性 |
| `metrics-billing` | 195 | 指标 & 计费 |
| `logging` | 290 | 日志 |

### 典型薄弱点

- **`stream-relay` 偏短**（83 行），相对同类 feature 文档太简。优化时扩大 sources（加上 Valkey 相关代码）可显著提升质量。
- **没有横向对比图**。例如 `multi-agent` + `workflow-engine` + `stage-engine`(dev) 三者的边界容易混淆，考虑在某一篇加一个对比表。
- **架构图**：13 篇 features 都是纯文字，缺 mermaid 流程图。优化命令里可在 prompt 上追加 "生成 mermaid 图" 要求（见 §9 "调整 prompt" ）。

### 优化命令

```bash
# 单篇增强（stream-relay 是最佳起点）
./scripts/sync.sh --estimate --chapter features --doc stream-relay
./scripts/sync.sh --full --chapter features --doc stream-relay --force-regenerate

# 对比各特性的详尽度：
wc -l docs/features/*.md | sort -n
```

---

## 4. `integrations`（6 页，外部系统集成）

### 当前内容

| Slug | 行数 | 主题 |
|------|------|------|
| `overview` | 118 | 集成总览 |
| `aws-bedrock` | 203 | AWS Bedrock 模型接入 |
| `mcp-clients` | 215 | 接入外部 MCP 服务器 |
| `mcp-server` | 206 | 把 Agent 暴露为 MCP Tool |
| `sso-saml` | 180 | SSO (SAML 2.0) |
| `data-stores` | 255 | Aurora / Valkey / DDB / SQS / S3 |

### 典型薄弱点

- **`overview` 118 行偏短**。可扩展：加一张集成全景图、每个集成的启用决策树。
- **没写"如何自定义集成"**（等于缺一个 "integration-template" 章节）—— 属于增加新 slug，不是优化现有。
- **AWS Bedrock 的 cross-region inference profile 细节** 可以加一节（现在只列了模型 ID）。

### 优化命令

```bash
# 扩展 overview
./scripts/sync.sh --full --chapter integrations --doc overview --force-regenerate

# 若要加新 slug（如 "integration-template"），先改 scripts/config.yaml
#   chapters.integrations.docs 里 append 一项 → 然后：
./scripts/sync.sh --full --chapter integrations --doc integration-template
```

---

## 5. `guides`（4 页，场景化教程）

### 当前内容

| Slug | 行数 | 主题 |
|------|------|------|
| `tips` | 163 | 技巧与最佳实践 |
| `build-hermes-analyst` | 192 | 基于真实 generated_agent 的分析型教程 |
| `build-tech-blog` | 192 | 技术博客生成教程 |
| `use-mcp-with-nexus` | 264 | MCP 端到端使用 |

### 典型薄弱点

- **`tips` 通用性强但抽象**。可加一节 "常见反模式"（anti-patterns），结合现实错误案例。
- **两个 build-* 教程** 基于 `agents/generated_agents/` 下的真实产物，**Nexus-AI 新增 generated_agents 时，应追加新 tutorials**（不是优化现有）。
- 考虑加一个 "**从零构建你的第一个领域 Agent**" 不依赖已有 generated_agent 的通用教程。

### 优化命令

```bash
# 优化 tips（加反模式）
./scripts/sync.sh --full --chapter guides --doc tips --force-regenerate

# 加新 guide（先在 config.yaml 添加 slug）
```

---

## 6. `developer`（10 页，参考级开发者文档）⭐

### 当前内容（平均 597 行，是最厚的章节）

| Slug | 行数 | 主题 |
|------|------|------|
| `contributing` | 598 | 贡献流程 / 开发环境 |
| `architecture-overview` | 547 | 系统总览 |
| `api-layer` | 750 | FastAPI 层详解 |
| `worker` | 747 | Worker 架构 |
| `stage-engine` | 721 | Stage 引擎 |
| `adding-agents` | 594 | 添加 Agent |
| `adding-tools` | 616 | 添加工具 |
| `adding-skills` | 768 | 添加技能 |
| `session-storage` | 757 | 会话存储 |
| `dynamic-prompt` | 504 | 动态 prompt 构建 |

### 典型薄弱点

- **质量已经参考级**，不需要普遍"扩充"。优化机会更多在 **时效性**：Nexus-AI 源码变了就失效。
- **跨页链接稀疏**。比如 `worker` 和 `stage-engine` 明显有关联但没互相 link。一次优化可加强 "See also"。
- **`architecture-overview`** 没有 mermaid 图，可在 prompt 里追加要求。

### 优化命令

```bash
# 追更某篇（代码有改动 → 签名自动 mismatch → 不加 --force-regenerate 也会跑）
./scripts/sync.sh --full --chapter developer --doc worker

# 强制重做（源码没变但想改风格时）
./scripts/sync.sh --full --chapter developer --doc api-layer --force-regenerate

# 注意：这章平均 700 行 × Opus 生成，单篇成本约 $5-15
./scripts/sync.sh --estimate --chapter developer --doc architecture-overview
```

---

## 7. `reference`（9 页，穷举级参考）⭐

### 当前内容（平均 689 行）

| Slug | 行数 | 主题 |
|------|------|------|
| `cli-commands` | 775 | nexus-cli 全命令参考 |
| `config-options` | 1358 ⚠️ | 全部配置项（最长） |
| `environment-variables` | 468 | 环境变量 |
| `api-endpoints` | 915 | FastAPI 全端点 |
| `deploy-params` | 483 | 部署参数 |
| `iam-policies` | 767 | IAM 权限 |
| `model-catalog` | 292 | 模型目录 |
| `glossary` | 413 | 术语表 |
| `faq` | 704 | FAQ |

### 典型薄弱点

- **`config-options` 1358 行** — 最长文档。若 `config/default_config.yaml` 新增一节，需要让 sync 追上；属于增量（`--only-detect` 会触发）。
- **`api-endpoints` 915 行** — 如果 FastAPI router 里新加 endpoint，这里会滞后；监控一下 `api/v2/routers/**` 的 commit。
- **`glossary`** 偏抽象，可加 "快速检索表格" 字母索引；但不是大改。
- **整章 "时效性 > 扩充性"** 是核心原则。

### 优化命令

```bash
# 代码变动驱动（增量）
./scripts/sync.sh --only-detect                  # 先看什么变了
./scripts/sync.sh --full --chapter reference --doc config-options

# 手工触发某篇强制重做
./scripts/sync.sh --full --chapter reference --doc api-endpoints --force-regenerate

# 整章预估成本
./scripts/sync.sh --estimate --chapter reference
```

---

## 8. 跨章节维护工具（零 API 成本）

这些命令用于"非内容"优化，跑完不调用 Claude：

```bash
# 刷新 /llms.txt 和 /llms-full.txt 聚合（合并后忘记刷时必跑）
./scripts/sync.sh --emit-llms-txt

# 重建某章节 index.md（不改内页）
./scripts/sync.sh --regenerate-index --chapter features

# 重建 sidebar JSON 片段（改了 config.yaml 的 slug 顺序/标题后跑）
./scripts/sync.sh --regenerate-sidebar --chapter features

# 列出所有章节
./scripts/sync.sh --list-chapters

# 全站 Markdown 卫生处理（修复 <uuid>/<tag> 破坏 Vue 构建）
find docs -name '*.md' -not -path 'docs/superpowers/*' \
  | xargs python3 scripts/lib/sanitize_md.py

# 检查当前 Nexus-AI 有哪些变更会触发文档更新
./scripts/sync.sh --only-detect
jq '.triggered_mappings | map({id, changed_files: (.changed_files | length)})' \
   scripts/state/changes.json
```

---

## 9. 调整 prompt（改变全章节生成风格）

若你发现某类文档普遍不够好，改的不是 config，而是 prompt。

**prompt 与章节的映射：**

| 章节 | 默认 prompt |
|------|------------|
| `getting-started` | `feature-overview.md` |
| `using` | `feature-update.md` |
| `features` | `feature-overview.md` |
| `integrations` | `integration-guide.md` |
| `guides` | `tutorial.md` |
| `developer` | `developer-guide.md` |
| `reference` | `reference.md` |

**优化 prompt 的流程：**

```bash
# 1. 编辑 scripts/prompts/developer-guide.md（比如加 "必须含 mermaid 图" 的要求）
vim scripts/prompts/developer-guide.md

# 2. 先用一篇小的试跑验证
./scripts/sync.sh --full --chapter developer --doc dynamic-prompt --force-regenerate

# 3. 看草稿质量
diff docs/developer/dynamic-prompt.md drafts/developer/dynamic-prompt.md | head -60

# 4. 满意后整章重做
./scripts/sync.sh --full --chapter developer --force-regenerate
```

---

## 10. 建议的优化顺序（按 ROI）

如果你想逐步提升整个 Playbook，我建议按这个顺序：

1. **先跑 `--only-detect`**（零成本）— 看 Nexus-AI 源码自 `ab4bae1c` 以来有什么变化，先做必要的增量同步。
2. **扩充最短的 3 篇**：`features/stream-relay` (83)、`prompt-templates` (113)、`agent-factory` (124)，预估成本 < $5。
3. **给 `features` / `developer` 加 mermaid 图**：改 prompt，整章 `--force-regenerate`。中等成本，视觉回报大。
4. **`integrations/overview` 扩充**：加集成全景图和决策树。成本低。
5. **新增章节或 slug**：如 `/use-cases/` 或 `guides/build-domain-agent`。属于扩展而非优化。

---

## 11. 快速命令速查表

| 目标 | 命令 |
|------|------|
| 看所有章节 | `./scripts/sync.sh --list-chapters` |
| 看某章节的预估成本 | `./scripts/sync.sh --estimate --chapter <ch>` |
| 看某一篇的预估成本 | `./scripts/sync.sh --estimate --chapter <ch> --doc <slug>` |
| 重做一篇（源码没变） | `./scripts/sync.sh --full --chapter <ch> --doc <slug> --force-regenerate` |
| 重做一整章（源码没变） | `./scripts/sync.sh --full --chapter <ch> --force-regenerate` |
| 代码变动后增量同步 | `./scripts/sync.sh` |
| 只看会触发什么 | `./scripts/sync.sh --only-detect` |
| 仅重做 index | `./scripts/sync.sh --regenerate-index --chapter <ch>` |
| 仅重做 sidebar JSON | `./scripts/sync.sh --regenerate-sidebar --chapter <ch>` |
| 刷新 LLM 聚合 | `./scripts/sync.sh --emit-llms-txt` |
| 修复 `<uuid>` Vue 构建报错 | `find docs -name '*.md' -not -path 'docs/superpowers/*' \| xargs python3 scripts/lib/sanitize_md.py` |
| 构建验证 | `npm run docs:build` |
| 起开发服务器（review） | `npm run docs:dev -- --host 0.0.0.0` |

---

**使用建议：** 打开这份 guide 的同时开着终端。选一个章节，按 §0 的 4 步跑完 → review → 下一个章节。**永远先 `--estimate` 再 `--full`**，Opus 成本不低。
