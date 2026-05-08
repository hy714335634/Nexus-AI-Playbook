# Playbook 文档自动同步机制 — 设计文档

**日期：** 2026-05-06
**状态：** 设计已批准，待实施
**作者：** Nexus-AI-Playbook 团队

---

## 1. 背景与目标

### 1.1 问题

`Nexus-AI` 是产品代码仓库，`Nexus-AI-Playbook` 是该产品的 **终端用户手册** 站点（基于 VitePress）。两个仓库相互独立，当 Nexus-AI 发布新功能或修改既有功能时，Playbook 的用户文档容易滞后、失真。

当前文档维护是纯手动的，存在以下问题：

- 代码变更后，需要手动识别哪些文档受影响
- 需要手动把功能变化转译为面向终端用户的说明文字
- UI 变化后的截图更新容易被遗忘
- 中英文文档缺乏同步机制（目前只有中文）

### 1.2 目标

构建一个 **自动化、可插拔、可维护** 的机制，使 Playbook 的用户文档能够 **准实时** 跟上 Nexus-AI 代码的变更。

**核心原则：**

1. **人工 review 后发布** — 生成草稿，用户 review 合并，不直接写入正式文档
2. **Claude Code 为生成引擎** — 通过 `claude -p` 调用，由脚本编排，不用传统代码模板
3. **面向终端用户** — 输出是 User Manual（产品特性、使用指导），不是开发者文档
4. **独立于源码仓库运行** — 不依赖 `nexus-cli`，不修改 Nexus-AI 仓库
5. **中英文双语** — 同时生成两个语言版本
6. **尽量简单** — MVP 优先，快速验证，后续迭代

### 1.3 非目标

- 不做 CI/CD 集成（MVP 阶段全部本地手动执行）
- 不做 Web UI 触发界面
- 不做开发者 API 文档生成
- 不做文档质量评分 / 多仓库源码支持 / 历史 changelog 生成

---

## 2. 总体架构

```
┌───────────────────────────────────────────────────────────────────────────┐
│                    Nexus-AI-Playbook 仓库                                  │
│                                                                            │
│  ┌────────────────────────┐        ┌────────────────────────────┐        │
│  │    scripts/            │        │     docs/ (正式文档)       │        │
│  │  (文档同步机制)         │        │  ├─ manual/*.md            │        │
│  │                        │───────▶│  ├─ manual/en/*.md (新增)  │        │
│  │  ┌──────────────────┐ │ 人工    │  ├─ guide/*.md             │        │
│  │  │  drafts/         │ │ review │  ├─ admin/*.md             │        │
│  │  │  (草稿输出)       │◀┤ 合并   │  └─ public/images/*.png    │        │
│  │  └──────────────────┘ │        └────────────────────────────┘        │
│  └───────────┬────────────┘                                               │
└──────────────┼────────────────────────────────────────────────────────────┘
               │ 读取 (通过 config.yaml 配置路径)
               ▼
┌───────────────────────────────────────────────────────────────────────────┐
│                    Nexus-AI 仓库 (源代码)                                  │
│  api/, agents/, nexus_utils/, config/, web/, ...                          │
└───────────────────────────────────────────────────────────────────────────┘
```

**核心组件：**

| 组件 | 职责 |
|------|------|
| `scripts/` | 独立的同步机制，放在 Playbook 仓库中 |
| `config.yaml` | 定义 Nexus-AI 仓库路径、映射规则、模型偏好 |
| Claude Code (`claude -p`) | 文档生成引擎，由脚本编排调用 |
| Playwright | 可选的自动截图工具 |
| `drafts/` | 生成的文档草稿输出目录，review 后手动合并到 `docs/` |

**5 阶段 Pipeline：**

```
sync.sh
  ├── [1] Detect    → git diff 分析 + 映射匹配 → 变更清单
  ├── [2] Prepare   → 为每个待更新文档组装 context (源码片段 + 现有文档)
  ├── [3] Generate  → claude -p 调用，生成中英文双版本草稿
  ├── [4] Screenshot→ 可选，检测服务运行则 Playwright 截图
  └── [5] Output    → 草稿写入 drafts/ + 生成 SUMMARY.md 列出改动
```

**关键设计取舍：**

- 脚本只负责编排，**文档内容由 Claude Code 生成**，不用代码模板拼接
- 每阶段可独立运行/调试（如 `sync.sh --only-detect`）
- 首次运行记录 "上次同步点"（git commit SHA），之后增量同步
- 串行执行，不做并发、重试、复杂错误处理 — shell 出错就停

---

## 3. 目录结构

```
Nexus-AI-Playbook/
├── docs/                          # 现有正式文档（不动）
│   ├── manual/                    # 中文（现有）
│   ├── manual/en/                 # 英文（新增空目录，首次运行时生成）
│   ├── guide/
│   ├── admin/
│   └── public/images/
│
├── scripts/                       # 【本次新增】文档同步机制
│   ├── config.yaml                # 配置文件
│   ├── sync.sh                    # 主入口
│   ├── lib/                       # Shell 辅助函数
│   │   ├── detect.sh              # Stage 1
│   │   ├── prepare.sh             # Stage 2
│   │   ├── generate.sh            # Stage 3
│   │   ├── screenshot.sh          # Stage 4
│   │   └── output.sh              # Stage 5
│   ├── prompts/                   # Claude Code 使用的 prompt 模板
│   │   ├── feature-update.md
│   │   ├── config-reference.md
│   │   ├── cli-command.md
│   │   └── style-guide.md         # 通用文风指南
│   ├── screenshots/               # Playwright 截图脚本
│   │   ├── package.json
│   │   ├── capture.js
│   │   └── targets.yaml           # 页面清单
│   ├── state/                     # 同步状态（git 跟踪，last_sync.json 需要持久化）
│   │   └── last_sync.json
│   └── README.md                  # 使用说明
│
└── drafts/                        # 【本次新增】生成的草稿（gitignored，临时工作区）
    ├── SUMMARY.md                 # 本次同步的改动摘要
    ├── manual/                    # 与 docs/manual/ 结构对齐
    ├── manual/en/
    └── images-todo/               # 需要手动更新截图的清单
```

---

## 4. 配置文件

### 4.1 `scripts/config.yaml`

```yaml
# Nexus-AI 源码仓库路径
source_repo:
  path: "../Nexus-AI"
  default_branch: "main"

# 文档生成的模型偏好
models:
  default: "claude-sonnet-4-6"       # 日常文档生成
  complex: "claude-opus-4-7"          # 架构类、大范围变更时使用

# 输出语言
languages:
  - zh                                # 中文（主）
  - en                                # 英文

# 映射规则：源码变更 → 文档更新
# 支持文件级 (path) 和模块级 (glob) 混合
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

# 截图配置
screenshots:
  enabled: "auto"                     # auto | always | never
  base_url: "http://localhost:3000"
  output_dir: "../docs/public/images"
  login:
    user: "admin"
    password: "nexus"
```

### 4.2 `scripts/state/last_sync.json`

记录上一次成功同步到的 Nexus-AI commit SHA：

```json
{
  "last_commit_sha": "abc123...",
  "timestamp": "2026-05-06T10:00:00Z",
  "mappings_synced": ["mcp-feature", "agent-creation"]
}
```

---

## 5. 核心流程细节

### 5.1 Stage 1 · Detect（检测变更）

```bash
cd $source_repo_path
git diff --name-only $last_commit_sha HEAD
```

对每个变更文件，匹配 `config.yaml` 的 `mappings.watches`（支持 glob）。输出 `state/changes.json`：

```json
{
  "from_sha": "abc123",
  "to_sha": "def456",
  "triggered_mappings": [
    {
      "id": "mcp-feature",
      "changed_files": ["mcp_server/handlers.py", "config/mcp/system_mcp_server.json"],
      "docs": ["manual/mcp.md"],
      "screenshots": ["mcp-config-page"]
    }
  ]
}
```

### 5.2 Stage 2 · Prepare（组装 context）

对每个触发的 mapping，在 `state/work/<mapping-id>/` 下生成 context 包：

```
state/work/<mapping-id>/
├── prompt.md              # 从 prompts/ 复制，填入变量
├── changed-files.md       # 每个变更文件的完整内容 + diff 片段
├── current-doc-zh.md      # docs/manual/xxx.md 的当前内容
├── current-doc-en.md      # docs/manual/en/xxx.md 的当前内容（若存在）
└── style-guide.md         # 全局文风指南
```

### 5.3 Stage 3 · Generate（Claude Code 生成）

**调用方式：**

```bash
cd state/work/<mapping-id>
claude -p "$(cat prompt.md)" \
  --model "$model" \
  --allowed-tools "Read,Write"
# 具体 flag 在实现阶段确认 — 此处展示调用形态而非最终命令
```

**Prompt 模板结构示例（`prompts/feature-update.md`）：**

```markdown
# 任务
基于源代码变更，更新用户手册文档（面向终端用户）。

## 输入
- 现有中文文档: current-doc-zh.md
- 现有英文文档: current-doc-en.md
- 源代码变更: changed-files.md
- 文风指南: style-guide.md

## 要求
1. 参考现有文档的格式、语气、结构
2. 仅更新受本次代码变更影响的部分
3. 保持中英文版本同步
4. 如果涉及 UI 变化，在相应位置标注 `<!-- SCREENSHOT: <name> -->`
5. 简洁、直接、图文并茂
6. 这是 User Manual，不是开发者文档 — 不要出现代码细节、内部类名

## 输出
写入到以下路径：
- ../../drafts/manual/<doc>.md      (中文)
- ../../drafts/manual/en/<doc>.md   (英文)
```

### 5.4 Stage 4 · Screenshot（可选）

```bash
# 检测服务是否运行
curl -s http://localhost:3000 > /dev/null && SERVICE_UP=1

if [ "$SERVICE_UP" = "1" ]; then
  cd screenshots && node capture.js --targets "$screenshot_list"
  # Playwright 登录 → 访问目标页面 → 截图到 docs/public/images/
else
  # 在 drafts/images-todo/TODO.md 里列出需要手动截图的项
fi
```

### 5.5 Stage 5 · Output（汇总）

生成 `drafts/SUMMARY.md`：

```markdown
# 同步摘要 (2026-05-06)
- From: abc123 → To: def456

## 已生成草稿
- [ ] manual/mcp.md (中文 + 英文) — 基于 mcp-feature 映射

## 需要手动更新的截图
- mcp-config-page (服务未运行，未自动截图)

## 下一步
1. 对比 drafts/ 与 docs/ 的差异
2. 确认无误后，`cp drafts/manual/xxx.md docs/manual/xxx.md` 合并
3. 合并完成后，运行 `./sync.sh --commit-sync` 更新 last_sync.json
```

---

## 6. 命令行接口

| 命令 | 作用 |
|------|------|
| `./sync.sh` | 完整跑 5 个阶段 |
| `./sync.sh --dry-run` | 只跑 Detect + Prepare，不调用 claude -p |
| `./sync.sh --only-detect` | 只检测变更，输出清单 |
| `./sync.sh --mapping <id>` | 只对指定 mapping 执行同步 |
| `./sync.sh --from <sha> --to <sha>` | 指定起止 commit（回放历史） |
| `./sync.sh --init <sha>` | 首次运行，初始化 last_sync.json |
| `./sync.sh --commit-sync` | 合并完成后更新 last_sync.json |

---

## 7. 错误处理

| 场景 | 处理方式 |
|------|---------|
| Nexus-AI 路径不存在 | 启动时校验，报错退出 |
| `last_sync.json` 不存在（首次运行） | 提示用户用 `--init <sha>` 初始化 |
| git diff 为空（无变更） | 输出"无变更"并退出 |
| `claude -p` 调用失败 | 记录到 `state/errors.log`，跳过该 mapping，继续下一个 |
| Playwright 登录失败 | 降级为 TODO 清单，不中断整体流程 |
| 生成的草稿文件为空 | 保留空文件并在 SUMMARY.md 中标红提醒 |

**不做的事：** 重试、并发、rate limiting — 失败就停，用户重跑。

---

## 8. 测试策略

**MVP 阶段不写自动化测试**，通过以下方式手动验证：

1. **Dry-run：** `sync.sh --dry-run` 验证映射配置
2. **单 mapping：** `sync.sh --mapping mcp-feature` 调试单个生成
3. **历史回放：** `sync.sh --from <sha> --to <sha>` 用历史 commit 验证

**首次跑通验证清单：**

- [ ] Detect 阶段正确匹配到预期文件
- [ ] Prepare 阶段 context 包内容完整
- [ ] Generate 阶段生成的文档符合现有文风
- [ ] 中英文版本内容一致
- [ ] 截图 fallback（服务未运行时）正确产出 TODO 清单

---

## 9. 交付范围

### MVP 包含

- `scripts/` 完整目录 + 5 阶段 pipeline
- `config.yaml` 示例，包含 3 个真实映射：`mcp-feature`、`agent-creation`、`config-reference`
- 3 个 prompt 模板：`feature-update.md`、`config-reference.md`、`style-guide.md`
- Playwright 截图脚本 + 2-3 个页面示范
- `scripts/README.md` 使用说明
- `docs/manual/en/` 英文目录初始化（可为空）

### MVP 不包含（后续迭代）

- Web UI 触发界面
- 多仓库源码支持
- 细粒度 prompt 版本管理
- 文档质量自动评分
- 文档变更 changelog 自动生成
- CI/CD 集成

### 成功标准

MVP 成功 = 能跑通以下场景：

1. 给定 Nexus-AI 从 `abc123` 到 `HEAD` 的真实变更（涉及 MCP 功能）
2. 运行 `cd scripts && ./sync.sh`
3. 得到 `drafts/manual/mcp.md` 和 `drafts/manual/en/mcp.md`，内容体现代码变更、文风与现有文档一致
4. 截图目录有自动截图（服务运行时）或有 TODO 清单（服务未运行）
5. 人工 review 后能直接合并到 `docs/` 使用

---

## 10. 依赖清单

### Playbook 仓库新增依赖

- `bash` 4+（脚本宿主环境）
- `yq`（解析 YAML 配置，或用 Python 替代）
- `jq`（处理 JSON 状态文件）
- `claude` CLI（Claude Code 已安装）
- `node` 18+（Playwright 运行环境）
- `playwright`（仅 `screenshots/` 子目录的 npm 依赖）

### Nexus-AI 仓库依赖

- 本地已 clone，通过 `config.yaml` 中的 `source_repo.path` 指定
- Playwright 截图时需本地已启动 Nexus-AI 服务（否则 fallback 到 TODO）
