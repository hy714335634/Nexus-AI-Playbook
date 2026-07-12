# Playbook v4 实施计划（手册重构 + Agent 检索 + Demo 视频产线）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 按已批准设计（specs/2026-07-12-playbook-v4-manual-and-demos-design.md）交付：实测为准的 v4 手册（8 章 × 中英）、可被平台内 Agent 检索的手册问答链路、3 个故事化 Demo 成片（中英双版本，字幕+配音）。

**Architecture:** 四阶段流水：A 探查（agent-browser 走查测试环境产出操作笔记+截图）→ B 手册（docs-sync 管线逐章生成合并）→ C 检索（S3+Bedrock KB+平台 UI 建手册助手+应用中心发布）→ D 视频（分镜→Playwright 录制→edge-tts→ffmpeg 合成）。

**Tech Stack:** agent-browser CLI、docs-sync（bash+claude CLI）、VitePress、AWS S3/Bedrock KB、Playwright、edge-tts（经 uvx）、ffmpeg。

## Global Constraints

- **不修改 Nexus-AI 本体仓库任何代码**（含 config/prompts/web）。执行前记录本体 `git status` 基线（当前已有用户自己的改动 `M api/v2/routers/apps.py`，属 feature/app-center-optimization 分支既有状态），每阶段结束核对无新增改动。
- 测试环境：`https://d3sx15z6kvxyn3.cloudfront.net`，账号 `admin` / 密码 `nexus`，已确认含全部功能。
- 所有产出提交到 Nexus-AI-Playbook 仓库 `main` 分支；视频成片 gitignore 存本地。
- 探查中发现的本体 bug / 不一致：只记 `scripts/state/explore/FINDINGS.md`，不修。
- 本机工具基线：`agent-browser`（已装）、`claude` CLI 2.1.207、`jq` 1.7.1、`python3+pyyaml`、`ffmpeg`（已装）、`uv/uvx`（已装，edge-tts 用 `uvx edge-tts`）、`node` 24。
- 中文文档在 `docs/<chapter>/`，英文在 `docs/<chapter>/en/`（沿用 v3 布局）。
- Playbook 工作目录：`/Users/qangz/Downloads/99.Project/Nexus-AI-Playbook`（下文 `$PB`）；本体只读参照：`/Users/qangz/Downloads/99.Project/Nexus-AI`（下文 `$NX`）。

---

## Phase A — 探查（功能底账 + 全站走查 + 截图）

### Task A1: 环境预检与登录态固化

**Files:**
- Create: `$PB/scripts/state/explore/` 目录
- Create: `$PB/scripts/state/explore/_baseline.md`（本体 git 基线 + 环境信息）
- Create: `$PB/.agent-browser-auth.json`（登录态，须 gitignore）
- Modify: `$PB/.gitignore`（追加 auth 文件与 explore 截图原始目录）

**Interfaces:**
- Produces: agent-browser 会话名 `nexus-explore`（后续所有走查任务复用）；登录态文件 `.agent-browser-auth.json`

- [ ] **Step 1: 记录本体 git 基线**

```bash
cd /Users/qangz/Downloads/99.Project/Nexus-AI && git status --porcelain > /tmp/nx_baseline.txt && git rev-parse HEAD >> /tmp/nx_baseline.txt
mkdir -p /Users/qangz/Downloads/99.Project/Nexus-AI-Playbook/scripts/state/explore
cp /tmp/nx_baseline.txt /Users/qangz/Downloads/99.Project/Nexus-AI-Playbook/scripts/state/explore/_baseline.md
```

- [ ] **Step 2: gitignore 追加**

在 `$PB/.gitignore` 末尾追加：

```
# v4 exploration artifacts
.agent-browser-auth.json
scripts/state/explore/shots/
demos/*/raw/
demos/*/narration/*.mp3
demos/*/output/
```

- [ ] **Step 3: 登录测试环境并保存状态**

```bash
agent-browser --session nexus-explore open https://d3sx15z6kvxyn3.cloudfront.net/login
agent-browser --session nexus-explore snapshot -i
# 按 snapshot 返回的 @ref 填入用户名/密码并提交：
agent-browser --session nexus-explore fill @eN "admin"
agent-browser --session nexus-explore fill @eM "nexus"
agent-browser --session nexus-explore click @eK
agent-browser --session nexus-explore wait --load networkidle
agent-browser --session nexus-explore state save /Users/qangz/Downloads/99.Project/Nexus-AI-Playbook/.agent-browser-auth.json
```

Expected: 登录后 URL 离开 `/login`；`get url` 验证。

- [ ] **Step 4: 确认功能开关全开**

```bash
agent-browser --session nexus-explore open https://d3sx15z6kvxyn3.cloudfront.net/ && agent-browser --session nexus-explore wait --load networkidle && agent-browser --session nexus-explore snapshot -i
```

核对侧边栏出现：agents/chat/projects/ability/integration/apps/resource-groups/events/analytics/settings 等入口；将实际侧边栏项记入 `_baseline.md`。任何预期入口缺失 → 记入 FINDINGS 并暂停报告用户。

- [ ] **Step 5: Commit**

```bash
cd $PB && git add .gitignore scripts/state/explore/_baseline.md && git commit -m "chore(explore): env preflight baseline + auth state gitignore"
```

### Task A2: 功能底账（代码侧盘点）

**Files:**
- Create: `$PB/scripts/state/explore/INVENTORY.md`

**Interfaces:**
- Produces: `INVENTORY.md` — 三列对照表（路由页面 | 对应 API router | 计划章节/slug），后续 A3-A8 按它走查、B1 按它定 config.yaml

- [ ] **Step 1: 从本体代码提取路由与 router 清单（只读）**

```bash
find "$NX/web/app" -name "page.tsx" | sed 's|.*/web/app||;s|/page.tsx||' | sort
ls "$NX/api/v2/routers/" | grep -v __
grep -n "href" "$NX/web/src/components/layout/sidebar.tsx" | head -40
```

- [ ] **Step 2: 写 INVENTORY.md**

结构（每行一个用户可见功能单元）：

```markdown
| 功能 | 路由 | API routers | v4 章节/slug | 走查任务 |
|---|---|---|---|---|
| 登录 | /login | auth | getting-started/first-login | A3 |
| 仪表盘 | / | statistics | using/dashboard | A3 |
| Avatar 空间 | /home | avatar | using/avatar-space | A3 |
| Agent 列表/创建/详情/对话/文件 | /agents/** | agents, agent_files | using/manage-agents 等 | A4 |
| …（覆盖 INVENTORY 全部路由，包括 evolution/pfr/troubleshoot/demos）… |
```

要求：`web/app/(main)` 下每个含 page.tsx 的目录都必须出现一行，不得遗漏；43 个 router 每个至少映射到一行（纯内部的注明"无 UI，归 developer/reference 章"）。

- [ ] **Step 3: Commit**

```bash
cd $PB && git add scripts/state/explore/INVENTORY.md && git commit -m "docs(explore): code-side feature inventory for v4"
```

### Task A3: 走查批次 1 — 登录/仪表盘/Avatar 空间/Spotlight/双语

**Files:**
- Create: `$PB/scripts/state/explore/01-dashboard-home.md`
- Create: `$PB/scripts/state/explore/shots/01/*.png`（原始截图，gitignored；curation 在 B 阶段）
- Create: `$PB/scripts/state/explore/FINDINGS.md`（首个走查任务建立，此后各批次追加）

**Interfaces:**
- Consumes: 会话 `nexus-explore`（A1）
- Produces: 操作笔记 markdown，格式统一为：`## <功能>` → `### 入口` → `### 步骤`（编号步骤，每步含操作+结果）→ `### 截图`（文件名清单）→ `### 边界/发现`

- [ ] **Step 1: 走查登录页（登出后重登一次，截图登录页）**
- [ ] **Step 2: 走查仪表盘 `/`**：统计卡片、快捷入口，逐个 hover/点击记录去向；截图
- [ ] **Step 3: 走查 `/home` Avatar 空间**：开通引导（若未开通先截引导页）、记忆/知识图谱/Cards 各 tab；截图
- [ ] **Step 4: 走查 Spotlight**（`agent-browser press Meta+k` 或页面快捷键，snapshot 确认）与右上角语言切换（zh↔en 各截一张同页对比）
- [ ] **Step 5: 写 01-dashboard-home.md + FINDINGS.md 初始化，Commit**

```bash
cd $PB && git add scripts/state/explore/01-dashboard-home.md scripts/state/explore/FINDINGS.md && git commit -m "docs(explore): batch1 dashboard/home/avatar/spotlight walkthrough"
```

截图统一命令形态（后续批次同）：

```bash
agent-browser --session nexus-explore screenshot --screenshot-dir $PB/scripts/state/explore/shots/01 <name>.png
```

### Task A4: 走查批次 2 — Agent 全生命周期 + 独立聊天

**Files:**
- Create: `$PB/scripts/state/explore/02-agents-chat.md`、`shots/02/*.png`

**Interfaces:**
- Consumes: 会话 `nexus-explore`
- Produces: 笔记含一次**真实快速创建 Agent** 的全过程记录（用于 getting-started/quickstart 与 using/create-agent）

- [ ] **Step 1: `/agents` 列表页**：筛选/搜索/卡片操作；截图
- [ ] **Step 2: `/agents/new` 创建**：快速创建与引导创建两条路径都点开记录表单字段；**实际提交一个快速创建**（命名 `playbook-probe-agent`，描述用"翻译助手"类轻量需求），记录跳转与构建启动
- [ ] **Step 3: 构建进行中**：项目详情页 stage 进度 UI 截图（此构建同时服务 A5 批次的 projects 走查素材）
- [ ] **Step 4: Agent 详情页**（等构建完成或用环境里已有 agent）：概览/文件/对话 tab、版本、导出；截图
- [ ] **Step 5: `/agents/dialog` 与 `/agents/network`**：多 agent 会话与网络视图；截图
- [ ] **Step 6: `/chat` 独立聊天**：选 agent、发消息、SSE 流、会话管理、附件、中断（停止生成）；截图
- [ ] **Step 7: 写笔记 + 追加 FINDINGS + Commit**（提交信息 `docs(explore): batch2 agents lifecycle + chat`）

### Task A5: 走查批次 3 — 项目/构建工作流 + 应用中心

**Files:**
- Create: `$PB/scripts/state/explore/03-projects-apps.md`、`shots/03/*.png`

**Interfaces:**
- Consumes: A4 发起的构建项目
- Produces: 8 阶段构建全记录 + 应用中心 构建→版本→发布→NL更新→公开访问 全链路记录（Demo① 与 Demo③ 的脚本素材）

- [ ] **Step 1: `/projects` 列表 + 项目详情**：stage 时间线、fork/join 并行 stage、产物查看、失败重试入口；截图每个 stage 状态
- [ ] **Step 2: `/build`、`/build/graph`、`/build/modules`**：构建总览页功能；截图
- [ ] **Step 3: `/apps` 应用中心**：用环境内既有 agent 构建一个应用（记录 app_build 过程）；版本面板（current/latest 双指针）、trace 回放；截图
- [ ] **Step 4: 发布公开访问**：发布流程 → `/a/<app_id>` 匿名窗口验证（`agent-browser --session nexus-anon open …`）；截图
- [ ] **Step 5: NL 更新一轮**（application_update 工作流）：提一个小改动（如"标题改为深色"），记录三阶段渲染与版本推进
- [ ] **Step 6: 写笔记 + FINDINGS + Commit**（`docs(explore): batch3 projects/build + app center e2e`）

### Task A6: 走查批次 4 — 能力中心 + 集成

**Files:**
- Create: `$PB/scripts/state/explore/04-ability-integration.md`、`shots/04/*.png`

- [ ] **Step 1: `/ability/tools`**：工具列表/详情/源码查看/密钥状态；工具构建入口（tool_build 工作流，实际提交一个轻量工具构建：如"当前时间查询"）；截图
- [ ] **Step 2: `/ability/mcp`**：MCP 服务器管理、外接 MCP 配置；截图
- [ ] **Step 3: `/ability/skills`**：技能库、skill_build 入口、技能详情/版本；截图
- [ ] **Step 4: `/integration`**：SOP、模板（template assets/collections）、Directive tab、连接器（data connectors，含 key 管理跳转）；每个 tab 截图
- [ ] **Step 5: 写笔记 + FINDINGS + Commit**（`docs(explore): batch4 ability + integration`）

### Task A7: 走查批次 5 — 资源组/分享/用户 + 事件 + 进化/PFR/排障

**Files:**
- Create: `$PB/scripts/state/explore/05-groups-events-evolution.md`、`shots/05/*.png`

- [ ] **Step 1: `/resource-groups`** 列表/详情/成员/资源挂载；`/settings/sharing` 分享管理；`/users` 用户管理（管理员视角）；截图
- [ ] **Step 2: `/events`**：one_time/recurring/autonomous 三类任务创建表单与运行记录；截图
- [ ] **Step 3: `/evolution/**`（submit/progress/agents/history/analytics）与 `/pfr/**`、`/troubleshoot/**` 五子页：逐页记录用途与操作；截图
- [ ] **Step 4: 写笔记 + FINDINGS + Commit**（`docs(explore): batch5 groups/events/evolution/pfr/troubleshoot`）

### Task A8: 走查批次 6 — 管理运维 + 设置 + 内置助手

**Files:**
- Create: `$PB/scripts/state/explore/06-admin-settings-helpers.md`、`shots/06/*.png`

- [ ] **Step 1: `/management`、`/ops`、`/admin/service-status`、`/admin/billing`、`/analytics`**：逐页走查（ops 助手问一条真实问题记录响应形态）；截图
- [ ] **Step 2: `/settings/config`**：配置管理 UI（分组/热更新/重启标记/敏感项）；`/settings/audit`（审计+AI 审计助手）；`/settings/model-catalog`；`/settings/profile`；`/settings/browser-extension`（扩展下载与连接引导）；截图
- [ ] **Step 3: 内置助手盘点**：逐页找浮动助手圆点（config/audit/ops/tool_review/skill_forge/app_builder/mission），每个打开问一条问题，记录能力边界与 ui_action 联动；截图
- [ ] **Step 4: 写笔记 + FINDINGS 汇总修订（全部批次的发现整理成表：现象/位置/影响/是否阻塞手册） + Commit**（`docs(explore): batch6 admin/settings/helpers + findings rollup`）

### Task A9: Phase A 收尾 — targets.yaml 重建 + 阶段汇报

**Files:**
- Modify: `$PB/scripts/screenshots/targets.yaml`（按走查结果重建可重复截图清单）
- Modify: `$PB/scripts/config.yaml` 的 `screenshots.base_url`（改为测试环境）与 `login`

**Interfaces:**
- Produces: targets.yaml 每条 = 一张可无人值守重刷的稳定页面截图（动态弹窗/多步操作的截图不进 targets，保留在 explore 笔记里人工重截）

- [ ] **Step 1: 重建 targets.yaml**：按 6 批走查记录里"稳定可直达 URL"的截图逐条登记（name/url/output/wait_for_selector），预计 30-50 条
- [ ] **Step 2: 安装截图依赖并验证跑通**

```bash
cd $PB/scripts/screenshots && npm install && npx playwright install chromium
node capture.js --targets all --base-url https://d3sx15z6kvxyn3.cloudfront.net --user admin --password nexus --output-dir ../../docs/public/images
```

Expected: JSON 输出 `status: done`，错误条目为 0（个别 wait_for_selector 需迭代修正）。

- [ ] **Step 3: 本体 git 基线核对**

```bash
cd $NX && git status --porcelain | diff /tmp/nx_baseline.txt - || echo "DIRTY: 本体出现新改动，必须排查"
```

- [ ] **Step 4: Commit + 向用户汇报**（FINDINGS 摘要 + 截图数量 + 下阶段成本预估计划）

```bash
cd $PB && git add scripts/screenshots/targets.yaml scripts/config.yaml docs/public/images && git commit -m "feat(screenshots): rebuild targets for v4 against test env"
```

---

## Phase B — 手册 v4（config 重构 + 逐章生成合并）

### Task B1: config.yaml 章节与 sources 重构

**Files:**
- Modify: `$PB/scripts/config.yaml`（8 章定义 + 全部 sources 修正 + mappings 重建）

**Interfaces:**
- Consumes: `INVENTORY.md`（A2）、explore 笔记（A3-A8）
- Produces: 8 章 × ~80 docs 的完整章节定义；每篇 `sources` 额外包含对应 explore 笔记路径（如 `../Nexus-AI-Playbook/scripts/state/explore/03-projects-apps.md` 不可行——sources 相对本体根，改为把 explore 笔记复制进 `$PB/scripts/state/work/` 由 generate.sh 注入，见 Step 3）

已知路径修正表（v3 → 现实，写 config 时逐条应用并用 Step 4 验证）：

| v3 sources | 修正为 |
|---|---|
| `web/src/app/(authed)/**` | `web/app/(main)/**` 对应子目录 |
| `nexus_utils/magician.py` | `agents/system_agents/magician.py` |
| `worker/handlers/build_handler*.py` | `worker/handlers/**` |
| `nexus_utils/runtime_workspace/**` | 核实：`api/v2/services/agent_runtime_service.py` + S3SessionManager 所在模块 |
| `architecture/**` | `docs/architecture/**` |
| `docs/infrastructure/IAM_POLICIES.md` | 核实现路径（`docs/deployment/**` 下） |

- [ ] **Step 1: 写 8 章骨架**：`getting-started`(5) / `using`(~18) / `features`(~14) / `integrations`(~8) / `guides`(~6) / `developer`(~10) / `reference`(~10) / `admin`(~9，新)。using 新篇目（slug 固定，供 B2 sidebar 引用）：`app-center`、`resource-groups-sharing`、`skills`、`integration-center`、`assistants`、`browser-extension`、`avatar-space`、`event-scheduler`、`spotlight`、`evolution-pfr-troubleshoot`；admin 篇目：`deploy-upgrade`、`config-management`、`users-permissions`、`resource-group-admin`、`audit`、`billing`、`service-status`、`ops-assistant`、`release-notes`
- [ ] **Step 2: 每篇填 sources**（本体真实 glob，按修正表 + INVENTORY 的 router 映射）
- [ ] **Step 3: 注入实测笔记**：修改 `chapters.<ch>.docs[].sources` 支持绝对路径已不可行——采用现有机制：explore 笔记按模块复制到 `$NX` 之外不动本体，改为在 `config.yaml` 新增每篇可选字段 `extra_context`（相对 `$PB` 根），并在 `scripts/lib/generate.sh`/`full_generate.sh` 组装 sources.md 时若存在 `extra_context` 则一并 cat 进 context（≤30 行的 bash/yaml_helper 小改，属 Playbook 自身工具链，允许）
- [ ] **Step 4: 验证所有 sources 非空**

```bash
cd $PB/scripts && for ch in $(./sync.sh --list-chapters | awk '{print $1}'); do echo "== $ch"; done
# 对每篇跑 _expand_sources 检查空匹配：
python3 lib/yaml_helper.py config.yaml chapters | jq -r '…' # 列出每篇 sources
echo "<glob>" | python3 lib/_expand_sources.py /Users/qangz/Downloads/99.Project/Nexus-AI | head -1
```

Expected: 每个 glob 至少命中 1 个文件；空匹配逐条修正。

- [ ] **Step 5: mappings 重建**：按 v4 章节把高频变更面（apps/agents/sessions/config/skills/connectors/browser/avatar）建 8-12 条 watch 规则
- [ ] **Step 6: Commit**（`feat(config): v4 chapters + corrected sources + extra_context injection`）

### Task B2: sidebar 与站点导航更新

**Files:**
- Modify: `$PB/docs/.vitepress/config.mts`（SIDEBAR 增补 using 新篇目 + admin 章；快速链接指向新 admin 章）

- [ ] **Step 1: 更新 SIDEBAR**：using 组扩到 18 项、新增 `🛡️ 管理员指南` 组（9 项）、guides/features/integrations 按 B1 slug 对齐
- [ ] **Step 2: `npm run docs:build` 验证**（ignoreDeadLinks 已开，构建须过）
- [ ] **Step 3: Commit**（`feat(site): v4 sidebar with using expansion + admin chapter`）

### Task B3: 成本预估与模型确认（用户 gate）

- [ ] **Step 1: 逐章 estimate**

```bash
cd $PB && for ch in getting-started using features integrations guides developer reference admin; do ./scripts/sync.sh --estimate --chapter $ch; done
```

- [ ] **Step 2: 汇总成本表报用户**，同时给模型建议（保持 opus-4-7 或换新型号），拿到确认后再进 B4

### Task B4: 逐章生成与合并（×8，同构循环）

对每章依次执行（顺序：getting-started → using → admin → features → integrations → guides → developer → reference）：

- [ ] **Step 1: 生成** `./scripts/sync.sh --full --chapter <ch>`
- [ ] **Step 2: Review drafts**：自查（frontmatter/HUMAN-EDIT 保留/截图引用存在/步骤与 explore 笔记一致），摘要报用户
- [ ] **Step 3: 合并**

```bash
mkdir -p docs/<ch>/en && cp drafts/<ch>/*.md docs/<ch>/ && cp drafts/<ch>/en/*.md docs/<ch>/en/
```

- [ ] **Step 4: 卫生处理 + 构建**

```bash
find docs -name '*.md' -not -path 'docs/superpowers/*' | xargs python3 scripts/lib/sanitize_md.py
npm run docs:build
```

Expected: build 通过。

- [ ] **Step 5: 截图 curation**：本章引用的关键步骤图从 `shots/` 复制改名到 `docs/public/images/<ch>-<slug>-<step>.png`，文档内引用核对
- [ ] **Step 6: Commit**（`docs(<ch>): v4 full generation (zh+en)`，每章一提交）

### Task B5: v3 遗留清理 + llms.txt + 基线重置

**Files:**
- Delete: `docs/manual/`（空目录）、`docs/guide/`、`docs/overview/`（v3 遗留三目录，内容已并入新章节；确认无 HUMAN-EDIT 丢失后删）
- Modify: `docs/index.md`（首页链接对齐 v4）

- [ ] **Step 1: 遗留目录逐篇核对**（有 HUMAN-EDIT 块的先迁移进对应新篇）后删除；`config.mts` 快速链接同步
- [ ] **Step 2: 刷新聚合** `./scripts/sync.sh --emit-llms-txt`
- [ ] **Step 3: 增量基线重置** `./scripts/sync.sh --init $(cd $NX && git rev-parse HEAD)` + `--dry-run` 验证空变更
- [ ] **Step 4: 最终构建 + 本体基线核对 + Commit**（`docs: v4 complete — legacy cleanup, llms refresh, sync baseline reset`）

---

## Phase C — 检索链路（S3 + Bedrock KB + 手册助手 + 发布）

### Task C1: region/账号确认（用户 gate）+ S3 上传

**Files:**
- Create: `$PB/scripts/lib/kb_sync.sh`

**Interfaces:**
- Produces: `kb_sync.sh sync-s3` 与 `kb_sync.sh ingest` 两个子命令；环境变量 `PB_KB_BUCKET`、`PB_KB_ID`、`PB_KB_DS_ID`、`AWS_REGION`

- [ ] **Step 1: 问用户确认** KB 所在 region/账号（建议与测试环境同账号）与 bucket 名（建议 `nexus-playbook-kb-<suffix>`）
- [ ] **Step 2: 写 kb_sync.sh**

```bash
#!/usr/bin/env bash
# Sync Playbook docs to S3 and trigger Bedrock KB ingestion.
# Usage: kb_sync.sh sync-s3 | ingest | status
set -euo pipefail
: "${PB_KB_BUCKET:?set PB_KB_BUCKET}"; : "${AWS_REGION:?set AWS_REGION}"
DOCS_DIR="$(cd "$(dirname "$0")/../../docs" && pwd)"
case "${1:-}" in
  sync-s3)
    aws s3 sync "$DOCS_DIR" "s3://$PB_KB_BUCKET/docs/" --region "$AWS_REGION" \
      --exclude "*" --include "*.md" \
      --exclude ".vitepress/*" --exclude "superpowers/*" --delete
    aws s3 cp "$DOCS_DIR/public/llms-full.txt" "s3://$PB_KB_BUCKET/docs/llms-full.txt" --region "$AWS_REGION"
    ;;
  ingest)
    : "${PB_KB_ID:?set PB_KB_ID}"; : "${PB_KB_DS_ID:?set PB_KB_DS_ID}"
    aws bedrock-agent start-ingestion-job --knowledge-base-id "$PB_KB_ID" \
      --data-source-id "$PB_KB_DS_ID" --region "$AWS_REGION"
    ;;
  status)
    : "${PB_KB_ID:?set PB_KB_ID}"; : "${PB_KB_DS_ID:?set PB_KB_DS_ID}"
    aws bedrock-agent list-ingestion-jobs --knowledge-base-id "$PB_KB_ID" \
      --data-source-id "$PB_KB_DS_ID" --region "$AWS_REGION" \
      --query 'ingestionJobSummaries[0].{status:status,stats:statistics}' ;;
  *) echo "usage: kb_sync.sh sync-s3|ingest|status" >&2; exit 2;;
esac
```

- [ ] **Step 3: 建 bucket + 首次 sync-s3**，验证对象数与 docs md 数一致
- [ ] **Step 4: Commit**（`feat(kb): kb_sync.sh + first S3 sync`）

### Task C2: 创建 Bedrock Knowledge Base 并入库

- [ ] **Step 1: 控制台/CLI 建 KB**：命名 `nexus-playbook-kb`，数据源指向 `s3://$PB_KB_BUCKET/docs/`，embedding 模型选该 region 可用的 Titan/Cohere，向量库用 KB 托管默认（OpenSearch Serverless 或 S3 Vectors，取决 region 支持，选成本低者）
- [ ] **Step 2: `kb_sync.sh ingest` + `status` 轮询至 COMPLETE**，记录 KB_ID/DS_ID 到 `$PB/scripts/README.md` 新章节
- [ ] **Step 3: 检索冒烟**：`aws bedrock-agent-runtime retrieve --knowledge-base-id … --retrieval-query text="如何发布应用到应用中心"`，Expected: 返回 app-center 相关 chunk
- [ ] **Step 4: Commit**（README 更新）

### Task C3: 平台内创建"手册助手" Agent（UI 操作，录屏留档）

**Interfaces:**
- Consumes: KB_ID（C2）；平台模板工具库现成 `retrieve` 工具（strands 内置，KNOWLEDGE_BASE_ID 参数）
- Produces: 平台内 agent `Nexus-AI 使用手册助手`；全程录屏原片（Demo③ 素材，`demos/kb-qa-assistant/raw/`）

- [ ] **Step 1: 开录**（agent-browser `record start` 或 Playwright headed；1920x1080）
- [ ] **Step 2: 按 A4 记录的创建路径**在 UI 建 agent：名称 `Nexus-AI 使用手册助手`；系统提示词（全文入库到 `$PB/scripts/state/kb-assistant-prompt.md` 供复用）：

```
你是 Nexus-AI 平台的使用手册助手。用户问平台"怎么用/在哪里/为什么报错"时：
1. 先调用 retrieve 工具检索官方手册（知识库内是 Nexus-AI Playbook 全文，中英双语）。
2. 基于检索结果回答：给出分步操作指引（第一步/第二步…，标注页面路径如"能力中心 → 工具"）。
3. 每个答案末尾列出所引用的手册章节相对路径（如 using/app-center）。
4. 检索无结果时明确说"手册未覆盖"，不要编造界面与步骤。
5. 跟随用户语言回答（中文问中文答，英文问英文答）。
```

- [ ] **Step 3: 挂 retrieve 工具**，KNOWLEDGE_BASE_ID 配置为 C2 的 KB_ID（若模板工具在 UI 无参数位，按 A6 记录的工具配置路径处理；确实不可配则改用数据连接器 BEDROCK_KB provider 路径——两条路都零本体代码）
- [ ] **Step 4: 对话验证 3 问**：「怎么发布应用」「怎么给 agent 加工具」「事件调度怎么建定时任务」，Expected: 均给分步指引+章节引用
- [ ] **Step 5: 停录**，笔记 + Commit（`docs(kb): assistant prompt + creation walkthrough notes`）

### Task C4: 应用中心发布 + 站点挂链

**Files:**
- Modify: `$PB/docs/.vitepress/config.mts`（nav 加「🤖 手册助手」外链）
- Modify: `$PB/docs/index.md`（首页 hero 加入口）

- [ ] **Step 1: 按 A5 记录的发布路径**把手册助手经应用中心发布为公开应用，拿到 `/a/<app_id>` URL；匿名会话验证可问答（此段继续录屏进 Demo③ 素材）
- [ ] **Step 2: nav/首页挂链** + `npm run docs:build`
- [ ] **Step 3: 验收清单 G3 核对 + Commit**（`feat(site): link published manual assistant app`）

---

## Phase D — Demo 视频产线（3 故事 × zh/en）

### Task D1: demos/ 脚手架 + 共用脚本

**Files:**
- Create: `$PB/demos/README.md`（产线操作手册：分镜→录制→TTS→合成四步）
- Create: `$PB/demos/lib/tts.sh`
- Create: `$PB/demos/lib/gen_srt.py`
- Create: `$PB/demos/lib/compose.sh`
- Create: `$PB/demos/lib/record.template.ts`（Playwright 分段录制模板）
- Create: `$PB/demos/package.json`（playwright 依赖，复用 scripts/screenshots 版本）

**Interfaces:**
- Produces: 每个 demo 目录约定 `demos/<slug>/{storyboard.zh.md,storyboard.en.md,narration.yaml,record.spec.ts,raw/,narration/,subtitles/,output/}`；`narration.yaml` 格式：`scenes: [{id, title, zh, en, max_sec}]`

- [ ] **Step 1: tts.sh**（逐场景合成，中文 `zh-CN-YunjianNeural`、英文 `en-US-AndrewNeural`）

```bash
#!/usr/bin/env bash
# Usage: tts.sh <demo-dir> <lang zh|en>
set -euo pipefail
DIR="$1"; LANG="$2"
VOICE_zh="zh-CN-YunjianNeural"; VOICE_en="en-US-AndrewNeural"
VOICE_VAR="VOICE_$LANG"; VOICE="${!VOICE_VAR}"
mkdir -p "$DIR/narration"
python3 - "$DIR/narration.yaml" "$LANG" <<'PY' | while IFS=$'\t' read -r id text; do
import sys, yaml
scenes = yaml.safe_load(open(sys.argv[1]))["scenes"]
for s in scenes:
    print(f"{s['id']}\t{s[sys.argv[2]]}")
PY
  uvx edge-tts --voice "$VOICE" --text "$text" --write-media "$DIR/narration/${id}.${LANG}.mp3"
  echo "tts: ${id}.${LANG}.mp3"
done
```

- [ ] **Step 2: gen_srt.py**（narration.yaml + 各段 mp3 实测时长 → 每语言一份 SRT，段起点=前段累计+场景视频起点对齐表）

```python
#!/usr/bin/env python3
"""Generate SRT from narration.yaml + measured mp3 durations.
Usage: gen_srt.py <demo-dir> <lang>   (writes subtitles/<lang>.srt)
Scene timing = cumulative video segment durations read from raw/segments.json
(produced by compose.sh probe step)."""
import sys, json, yaml, subprocess, pathlib

def dur(p):
    out = subprocess.run(["ffprobe","-v","quiet","-show_entries","format=duration",
                          "-of","json",str(p)], capture_output=True, text=True)
    return float(json.loads(out.stdout)["format"]["duration"])

def ts(sec):
    h=int(sec//3600); m=int(sec%3600//60); s=sec%60
    return f"{h:02d}:{m:02d}:{int(s):02d},{int(s%1*1000):03d}"

d = pathlib.Path(sys.argv[1]); lang = sys.argv[2]
scenes = yaml.safe_load((d/"narration.yaml").read_text())["scenes"]
seg = json.loads((d/"raw/segments.json").read_text())  # {id: video_sec}
t = 0.0; lines = []
for i, s in enumerate(scenes, 1):
    a = dur(d/f"narration/{s['id']}.{lang}.mp3")
    v = max(seg[s["id"]], a)          # compose.sh pads video to audio length
    lines += [str(i), f"{ts(t)} --> {ts(t+a)}", s[lang], ""]
    t += v
(d/"subtitles").mkdir(exist_ok=True)
(d/f"subtitles/{lang}.srt").write_text("\n".join(lines), encoding="utf-8")
print(f"wrote subtitles/{lang}.srt ({len(scenes)} cues, total {t:.1f}s)")
```

- [ ] **Step 3: compose.sh**（探测各段时长写 segments.json → 视频段 tpad 到音频长 → concat → 混音 → 烧字幕 → `output/<lang>.mp4`）

```bash
#!/usr/bin/env bash
# Usage: compose.sh <demo-dir> <lang zh|en>
# raw/<scene-id>.webm (ordered per narration.yaml) + narration/<id>.<lang>.mp3
# -> output/<lang>.mp4 (1080p, aac, burned-in subtitles)
set -euo pipefail
DIR="$1"; LANG="$2"; cd "$DIR"
mapfile -t IDS < <(python3 -c "import yaml,sys;[print(s['id']) for s in yaml.safe_load(open('narration.yaml'))['scenes']]")
mkdir -p output tmp
python3 - <<'PY'
import json,subprocess,yaml,pathlib
def dur(p):
    o=subprocess.run(["ffprobe","-v","quiet","-show_entries","format=duration","-of","json",p],capture_output=True,text=True)
    return float(json.loads(o.stdout)["format"]["duration"])
ids=[s["id"] for s in yaml.safe_load(open("narration.yaml"))["scenes"]]
json.dump({i:dur(f"raw/{i}.webm") for i in ids}, open("raw/segments.json","w"))
PY
python3 "$(dirname "$0")/gen_srt.py" . "$LANG"
CONCAT=""
for id in "${IDS[@]}"; do
  A="narration/${id}.${LANG}.mp3"
  AD=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$A")
  # pad video with last frame if narration longer than the segment
  ffmpeg -y -i "raw/${id}.webm" -i "$A" \
    -filter_complex "[0:v]tpad=stop_mode=clone:stop_duration=999[v0];[v0]trim=0:${AD%.*}.99,scale=1920:1080,fps=30[v]" \
    -map "[v]" -map 1:a -c:v libx264 -preset fast -crf 20 -c:a aac -shortest "tmp/${id}.${LANG}.mp4"
  CONCAT+="file '$PWD/tmp/${id}.${LANG}.mp4'"$'\n'
done
printf '%s' "$CONCAT" > "tmp/concat.${LANG}.txt"
ffmpeg -y -f concat -safe 0 -i "tmp/concat.${LANG}.txt" \
  -vf "subtitles=subtitles/${LANG}.srt:force_style='FontSize=20,Outline=1'" \
  -c:v libx264 -crf 20 -c:a copy "output/${LANG}.mp4"
echo "done: output/${LANG}.mp4"
```

- [ ] **Step 4: record.template.ts**（每场景一个 test，`video: {mode:'on', size:{width:1920,height:1080}}`，storageState 用 A1 auth 文件转 Playwright 格式或重登；场景末尾把 video 另存为 `raw/<scene-id>.webm`）
- [ ] **Step 5: demos/README.md 写四步操作 + Commit**（`feat(demos): pipeline scaffolding (tts/srt/compose/record template)`）

### Task D2: Demo① 应用中心发布 — 分镜（用户 gate）

**Files:**
- Create: `$PB/demos/app-center-publish/storyboard.zh.md`、`storyboard.en.md`、`narration.yaml`

- [ ] **Step 1: 依 A5 实测写分镜**：故事=市场部小王要竞品分析工具；场景表（镜头|页面/操作|旁白 zh/en|预计秒数），含开场/需求提交/构建阶段速览（剪辑压缩）/应用构建/发布/`/a/` 匿名使用/NL 迭代/价值总结，总长 4-5 分钟
- [ ] **Step 2: narration.yaml 同步落库**（scenes 与分镜一一对应）
- [ ] **Step 3: 报用户审分镜**，通过后 Commit（`docs(demo1): storyboard zh/en`）

### Task D3: Demo① 录制 + 打样成片（用户 gate）

**Files:**
- Create: `$PB/demos/app-center-publish/record.spec.ts`
- Create: `raw/*.webm`、`narration/*.mp3`、`subtitles/*.srt`、`output/{zh,en}.mp4`（均 gitignored）

- [ ] **Step 1: record.spec.ts**：从模板实例化，每场景一 test（构建等待用 API 轮询到位后再进场景，不录空等）
- [ ] **Step 2: 录制**（环境数据若杂乱，录前在测试环境清出干净演示账号视图；不行则报用户议新环境）
- [ ] **Step 3: `tts.sh . zh && tts.sh . en`** → 听抽查 2 段
- [ ] **Step 4: `compose.sh . zh && compose.sh . en`** → 自检（时长/音画对齐/字幕样式/1080p）
- [ ] **Step 5: 打样交付用户验收**（zh 成片本地路径），通过后 Commit（spec+storyboard+narration 进 git；`feat(demo1): recording spec + sample accepted`）

### Task D4: Demo② 工具/技能扩展 — 分镜→成片

**Files:**
- Create: `$PB/demos/tool-skill-extend/storyboard.zh.md`、`storyboard.en.md`、`narration.yaml`、`record.spec.ts`
- Create: `raw/*.webm`、`narration/*.mp3`、`subtitles/*.srt`、`output/{zh,en}.mp4`（gitignored）

**Interfaces:**
- Consumes: D1 的 `lib/tts.sh`、`lib/gen_srt.py`、`lib/compose.sh`、`record.template.ts`；A6 实测笔记（tool_build/技能库操作路径）

- [ ] **Step 1: 分镜**：故事=数据分析师小李的 Agent 只会聊不会查数：能力中心提交 tool_build 工作流（"汇率查询工具"）→ 5 阶段构建速览 → 工具挂载到既有 Agent → 对话验证新能力 → 技能库沉淀复用 → 价值总结；总长 3-4 分钟，场景表与 `narration.yaml` 同步落库
- [ ] **Step 2: 报用户审分镜**，通过后 Commit（`docs(demo2): storyboard zh/en`）
- [ ] **Step 3: record.spec.ts 实例化 + 录制**（tool_build 等待段用 API 轮询跳过空等）
- [ ] **Step 4: `tts.sh . zh && tts.sh . en` → `compose.sh . zh && compose.sh . en`**，自检时长/对齐/字幕
- [ ] **Step 5: 交付用户验收，通过后 Commit**（`feat(demo2): recording spec + final cut accepted`）

### Task D5: Demo③ 数据连接+知识问答 — 分镜→成片

**Files:**
- Create: `$PB/demos/kb-qa-assistant/storyboard.zh.md`、`storyboard.en.md`、`narration.yaml`、`record.spec.ts`（仅补录场景）
- Create: `raw/*.webm`、`narration/*.mp3`、`subtitles/*.srt`、`output/{zh,en}.mp4`（gitignored）

**Interfaces:**
- Consumes: **C3/C4 的实录原片**（建 KB→建助手→挂 retrieve→发布公开应用全程）；D1 共用脚本

- [ ] **Step 1: 分镜**：故事=支持团队被"怎么用"类问题淹没：把产品手册接入 Bedrock KB → 平台建手册助手 Agent → retrieve 工具问答验证 → 应用中心发布 → 任何人经 `/a/<app_id>` 提问获得分步指引 → 价值总结；总长 4-5 分钟
- [ ] **Step 2: 报用户审分镜**，通过后 Commit（`docs(demo3): storyboard zh/en`）
- [ ] **Step 3: 素材整理**：C3/C4 原片按场景切段进 `raw/<scene-id>.webm`（ffmpeg -ss/-t 切割），缺口场景（开场/KB 控制台/总结画面）用 record.spec.ts 补录
- [ ] **Step 4: TTS + 合成 + 自检**（同 D4 Step 4 命令）
- [ ] **Step 5: 交付用户验收，通过后 Commit**（`feat(demo3): final cut accepted`）

### Task D6: 收尾 — 验收清单核对 + 总结报告

- [ ] **Step 1: 对照 spec §9 验收清单逐项打钩**（G1-G5 + 硬约束），未达项列明原因
- [ ] **Step 2: 本体 git 基线终核**（同 A9 Step 3）
- [ ] **Step 3: 总结报告**：交付物清单（站点/助手应用 URL/6 支成片路径）、FINDINGS 汇总、后续维护 SOP（增量同步 + kb_sync + 截图重刷 + demo 重录条件）
- [ ] **Step 4: 最终 Commit + push**（push 前问用户是否推 GitHub）
