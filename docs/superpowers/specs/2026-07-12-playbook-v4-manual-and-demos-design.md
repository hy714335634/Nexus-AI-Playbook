# Playbook v4 — 手册重构 + Agent 检索 + Demo 视频产线 — 设计文档

**日期：** 2026-07-12
**状态：** 设计已批准，待实施
**前置文档：**
- [2026-05-07-playbook-docs-sync-v2-design.md](./2026-05-07-playbook-docs-sync-v2-design.md)（docs-sync 框架，继续沿用）
- [../plans/2026-05-08-playbook-docs-sync-v3.md](../plans/2026-05-08-playbook-docs-sync-v3.md)（v3 内容基线，本版大幅重构其内容）

---

## 0. 本版修订说明（Scope 变化）

v3（commit `9376b84`，2026-05-09）交付了 7 章 × 55 docs × 中英双语的手册内容。
此后 Nexus-AI 本体经历了大量演进，v3 内容已系统性滞后；同时提出两个全新需求。

v4 范围：

1. **手册内容 v4 重构** — 以当前代码库全部功能为准，允许大幅删减/重写 v3 内容
2. **Agent 检索链路** — 手册可被 Agent 检索，在平台内回答使用问题并给分步指引
3. **Demo 视频产线** — 重要功能的故事化录屏（中英双版本，字幕+配音）

**docs-sync 框架（scripts/ 管线）本身不重写**，仅修订 `config.yaml`（章节定义、sources 路径、mappings）并按需小修 lib 脚本。

---

## 1. 背景与目标

### 1.1 现状差距

**内容滞后**：v3 之后本体新增/重构（不完全清单，阶段 A 以实测为准）：

- 应用中心深度重构（版本控制 current/latest、发布公开访问 `/a/<app_id>`、application_update 自然语言迭代、trace 回放）
- 权限体系梳理（资源归属/可见性、资源组、分享）
- 7 个内置 AI 助手（config/audit/ops/tool_review/skill_forge/app_builder/mission）
- 浏览器扩展操控（Chrome 扩展 + Bridge，agent 操控真实浏览器）
- Avatar 空间（用户数字分身：记忆、知识图谱、Cards）
- Sandbox 沙箱运行时、事件调度、进化(evolution)/PFR/排障(troubleshoot)
- Spotlight 命令面板、配置管理 UI（DB-backed 热更新）、审计与计费

**配置失效**：`scripts/config.yaml` 大量 sources glob 指向已不存在的路径
（如 `web/src/app/(authed)/**` → 现为 `web/app/(main)/**`；`nexus_utils/magician.py` → 现在
`agents/system_agents/magician.py`）。签名机制依赖 sources，路径错误导致增量检测失真。

**两个新需求**（本版新增）：

- 手册需能被 Agent 检索，用于回答用户使用问题、指导分步操作
- 重要功能需要完整 demo 录屏：从完整故事入手，展示构建与使用全过程，说明示例内容、产出物、价值，带字幕和配音

### 1.2 目标

| # | 目标 | 验收标准 |
|---|------|---------|
| G1 | 手册覆盖当前全部面向用户的功能（用户+管理员） | 功能底账逐项对应到文档章节；关键操作步骤配实测截图 |
| G2 | 手册内容与实际 UI 一致 | 每篇经过测试环境实测走查，非纯源码推断 |
| G3 | 手册可被 Agent 检索 | 平台内"手册助手" Agent 能引用手册内容回答操作问题，并发布为公开应用 |
| G4 | 3 个功能故事的 demo 成片 | 每片含故事开场/分步操作/产出物/价值总结，中英双版本，字幕+配音 |
| G5 | 可持续维护 | mappings 修复后，本体代码变更可继续增量追赶 |

### 1.3 非目标

- 不做视频自动化 CI（成片手工触发生成，先存本地不上云）
- 不做手册站点主题重设计（沿用现有 VitePress 主题）
- 不修复探查中发现的本体 bug（只记录汇报）
- 不做英文以外的第三语言

---

## 2. 硬约束

1. **不修改 Nexus-AI 本体仓库任何代码**。检索链路（线 2）全部用平台自身已有能力
   （UI 建 Agent + 模板工具库现成 `retrieve` 工具 / 数据连接器）实现，零代码改动。
2. 手册在 **Nexus-AI-Playbook 仓库**独立管理（本仓库），允许大幅删减甚至重构 v3 内容。
3. **实测为准**：用 agent-browser 在测试环境实际探查每个功能后再写/改文档。
4. 测试环境：`https://d3sx15z6kvxyn3.cloudfront.net`（admin/nexus），**已确认包含现有全部功能**。

---

## 3. 总体结构：三条线互相咬合

```
线1 手册v4重构 ──产出──> docs/*.md + llms.txt + 截图库
                              │
线2 检索链路：手册 → S3 → Bedrock KB → 平台内"手册助手"Agent（retrieve 工具）
                              │                    │ 应用中心发布为公开应用
线3 Demo产线：Demo③"数据连接+知识问答"的故事素材 ←──┘
              （手册助手的搭建过程本身就是 Demo③ 的剧本，一石三鸟）
```

---

## 4. 线 1：手册 v4 重构

### 4.1 功能盘点（阶段 A 输入）

以当前代码库为准建立**功能底账**：`web/app/(main)/` 路由 + 现役侧边栏
（`web/src/components/layout/sidebar.tsx`）+ 39 个 API routers 交叉核对，
再经 agent-browser 实测确认每个入口的真实行为。

已知功能面（待实测核实）：

| 模块 | 路由 |
|---|---|
| 仪表盘/首页/Avatar 空间 | `/`、`/home` |
| Agent 管理（创建/详情/对话/文件/网络视图） | `/agents/**` |
| 项目与构建（8 阶段工作流、部署） | `/projects/**`、`/build/**` |
| 独立聊天 | `/chat` |
| 能力中心（工具/MCP/技能） | `/ability/**` |
| 集成（SOP/模板/Directive/连接器） | `/integration/**` |
| 应用中心（构建/版本/发布/NL 更新） | `/apps/**`、`/a/<app_id>` |
| 资源组与分享 | `/resource-groups/**` |
| 事件调度 | `/events` |
| 进化 / PFR / 排障 | `/evolution/**`、`/pfr/**`、`/troubleshoot/**` |
| 分析 / 计费 | `/analytics`、`/admin/billing/**` |
| 管理运维（用户/服务状态/ops 助手） | `/management`、`/ops`、`/users`、`/admin/service-status` |
| 设置（配置/审计/模型目录/浏览器扩展/个人资料/分享） | `/settings/**` |
| 横切能力 | 7 个内置助手、Spotlight、双语切换、浏览器扩展、企业版差异 |

### 4.2 实测探查与截图

- **探查**：agent-browser 逐页走查测试环境，每个功能产出操作笔记
  （入口 → 步骤 → 表单字段 → 结果 → 边界行为），存 `scripts/state/explore/<module>.md`
- **截图**：关键步骤截图存 `docs/public/images/`（命名 `<chapter>-<slug>-<step>.png`）；
  **可重复的批量截图**沉淀到 `scripts/screenshots/targets.yaml`，供日后 UI 变更后重刷
- 探查中发现的 bug / 文档-实现不一致：记入 `scripts/state/explore/FINDINGS.md`，只汇报不修

### 4.3 章节结构 v4

保留 7 章骨架 + 新增 **admin** 章，共 8 章，预计 ~80 docs × 中英：

| 章节 | v3 | v4 | 主要变化 |
|---|---|---|---|
| getting-started | 5 | ~5 | 路径修正，增加测试环境/登录说明 |
| **using** | 8 | **~18** | 新增：应用中心、资源组与分享、技能库、集成中心（SOP/模板/Directive/连接器）、内置助手总览、浏览器扩展、Avatar 空间、事件调度、Spotlight、进化/PFR/排障 |
| features | 13 | ~14 | 增补应用中心机制、权限模型；删并失效篇目 |
| integrations | 6 | ~8 | 增补数据连接器、浏览器扩展集成 |
| guides | 4 | ~6 | 重写实战教程（与 Demo 选题呼应：发布应用/扩展工具/知识问答） |
| developer | 10 | ~10 | sources 路径全面修正，内容刷新 |
| reference | 9 | ~10 | 配置项/API/CLI 对齐当前版本 |
| **admin（新）** | (2 篇散落) | **~9** | 部署与升级、配置管理 UI、用户与权限、资源组管理、审计、计费、服务状态、运维助手、版本说明 |

### 4.4 生成与合并流程（沿用 docs-sync）

1. 修订 `scripts/config.yaml`：8 章定义、全部 sources 路径修正、mappings 重建
2. `sync.sh --estimate --chapter <ch>` 先出成本（模型在阶段 B 开始时定，候选：当前
   `global.anthropic.claude-opus-4-7` 或更新型号；预估过高则收窄 sources）
3. 逐章 `--full` 生成 → 人工 review drafts → 合并 docs/ → `sanitize_md.py` →
   `npm run docs:build` 验证 → 刷新 `llms.txt` / `llms-full.txt`
4. **生成 prompt 增强**：把阶段 A 的实测操作笔记 + 截图清单作为额外 context 注入
   （在 config.yaml 的 docs[].sources 里加 `state/explore/<module>.md`），
   确保内容以实测行为为准、源码为辅
5. v3 遗留处理：被重构章节的旧文档整篇替换；`HUMAN-EDIT` 块按机制逐字保留

### 4.5 同步机制延续（G5）

mappings 按 v4 章节重建（watches 指向修正后的真实路径），`--init <当前 Nexus-AI HEAD>`
重置增量基线。此后本体代码变更 → `sync.sh` 增量追赶。

---

## 5. 线 2：Agent 检索链路（零本体代码改动）

### 5.1 数据流

```
docs/**/*.md ──(分章 md + llms-full.txt)──> S3 bucket
      └→ Bedrock Knowledge Base（托管向量化 + 检索）
              └→ 平台 UI 创建 "Nexus-AI 使用手册助手" Agent
                    工具：strands 模板工具库现成 retrieve（指向该 KB）
                    prompt：回答使用问题 + 给分步操作指引 + 引用手册章节链接
                            └→ 应用中心发布为公开应用（/a/<app_id>）
                                  └→ Playbook 站点导航挂该链接
```

### 5.2 关键决策

- **Bedrock KB 而非本体 vector_store**：本体 `nexus_utils/vector_store/` 只索引平台资产
  （tools/prompts/agents），扩展它要改本体代码，违反硬约束 1。Bedrock KB 是纯云资源 +
  平台已有 `retrieve` 模板工具，零代码。
- **KB 数据源**：分章 markdown（保留章节边界、便于引用原文链接）为主；
  `llms-full.txt` 作为整体兜底。中英文档同库，检索时靠语义匹配自然分流。
- **同步**：手册更新后重跑 S3 sync + KB ingestion job（写入 Playbook 的
  `scripts/lib/kb_sync.sh`，挂在 `--emit-llms-txt` 之后可选执行）。
- **建 KB 前与用户确认 region/账号**（新建云资源，需明确归属；倾向与测试环境同账号）。

### 5.3 交付

- 手册助手 Agent（平台内，admin 账号下创建）
- 公开应用链接（挂到 Playbook 站点 nav）
- `scripts/lib/kb_sync.sh` + `scripts/README.md` 增补操作说明
- 搭建全程录屏 → Demo③ 素材

---

## 6. 线 3：Demo 视频产线

### 6.1 选题（已确认）

| # | 故事 | 主线 |
|---|---|---|
| ① | 应用中心发布 | 市场部小王要竞品分析工具：一句话需求 → 8 阶段自动构建 → 应用中心发布 → 全公司经 `/a/<app_id>` 使用 → NL 迭代一轮 |
| ② | 工具/技能扩展 | 给已有 Agent 补数据能力：tool_build 工作流造工具 → 挂到 Agent → 技能库复用 |
| ③ | 数据连接+知识问答 | 把产品手册变成问答助手：数据接入 → 建 KB → retrieve 工具 → 发布公开应用（即线 2 的实录） |

### 6.2 叙事模板（每片 3-6 分钟，1080p mp4，中英双版本）

1. **故事开场**（15-30s）：主角 + 痛点 + 本片要构建什么
2. **分步操作**（主体）：每步旁白说明"做什么/为什么"，字幕同步
3. **产出物展示**：构建产物、运行效果、公开访问
4. **价值总结**（15-30s）：量化收益（时间/成本/复用性）

### 6.3 技术管线（新建 `demos/` 目录）

```
demos/
├── README.md                    # 产线操作手册
├── <story-slug>/
│   ├── storyboard.zh.md         # 分镜脚本（镜头|操作|旁白|时长）—— 先审后录
│   ├── storyboard.en.md
│   ├── record.spec.ts           # Playwright 分段录制脚本（video: on）
│   ├── narration/               # 旁白稿逐段 → tts 音频（gitignored）
│   ├── subtitles/               # zh.srt / en.srt
│   └── output/                  # 成片（gitignored，本地存放）
└── lib/                         # 录制/合成共用脚本
    ├── tts.sh                   # edge-tts 首选（免费中英神经音），AWS Polly 备选
    └── compose.sh               # ffmpeg 拼段 + 混音 + 烧字幕 → zh/en 两成片
```

- **分镜先行**：storyboard 经用户审核后才开录
- **录制**：Playwright 按分镜分段录屏；构建等待期用分段+剪辑压缩，不留长空镜
- **配音**：旁白稿逐段 TTS 合成，段长与视频段对齐
- **字幕**：旁白稿生成 SRT，时间轴对齐分段
- **合成**：ffmpeg concat + amix + subtitles filter，产出 `zh.mp4` / `en.mp4`
- **环境**：默认用测试环境 `d3sx15z6kvxyn3`（与探查/截图统一）；若录制时数据残留
  影响画面，改为新开环境或 `demo_seeder` 造数（届时确认）
- **存放**：成片 gitignore 存本地（`demos/*/output/`），上云/上平台后续再议

---

## 7. 执行阶段

| 阶段 | 内容 | 交付物 | 依赖 |
|---|---|---|---|
| **A 探查** | 功能盘点 + agent-browser 全站走查 + 截图采集 | 功能底账、`state/explore/*.md` 操作笔记、`FINDINGS.md`、截图库、`targets.yaml` 更新 | 测试环境可用 |
| **B 手册** | config.yaml 重构 + 逐章生成 + review 合并 + 构建 + llms.txt | Playbook v4 站点（~80 docs × 中英） | A |
| **C 检索** | S3 + Bedrock KB + 手册助手 Agent + 应用中心发布 + kb_sync.sh | 可问答的手册助手（公开应用）、站点挂链 | B（手册内容）；KB region/账号确认 |
| **D 视频** | 分镜脚本（先审）→ 录制 → TTS/字幕 → 合成 | 3 故事 × zh/en = 6 支成片（本地） | A（熟悉操作路径）；③ 依赖 C 过程实录 |

每阶段独立可交付、独立提交；B 内部按章节增量提交。

---

## 8. 风险与应对

| 风险 | 应对 |
|---|---|
| 生成成本高（~80 docs × 双语 × Opus 级） | 每章先 `--estimate` 出数字再跑；过高则收窄 sources、分批 |
| 测试环境功能开关与预期不符 | 阶段 A 首件事全站走查确认；缺失项记 FINDINGS 报用户定夺 |
| agent-browser 长流程不稳（构建类操作耗时长） | 探查与录制都按功能分段，单段失败可重试；构建类流程预跑一遍确认时长 |
| Bedrock KB 资源归属 | 建前确认 region/账号；资源命名 `nexus-playbook-*` 便于回收 |
| TTS 音色/时长与画面不齐 | 先出①的单片打样（含配音字幕）验收后再批量 |
| 测试环境数据残留入镜 | 录制前清理或新开环境/demo_seeder 造数 |
| 探查发现本体 bug | 只记录 FINDINGS.md 汇报，不改本体代码 |

---

## 9. 验收清单

- [ ] 功能底账逐项对应文档章节（G1）
- [ ] 全部 using/admin 篇目经实测走查，关键步骤有截图（G1/G2）
- [ ] `npm run docs:build` 通过，llms.txt/llms-full.txt 刷新（G1）
- [ ] 手册助手能答"如何发布应用到应用中心"类问题并给分步指引+章节引用（G3）
- [ ] 手册助手已发布为公开应用，站点导航可达（G3）
- [ ] 3 × 2 成片：故事/操作/产出物/价值四要素齐全，字幕配音对齐（G4）
- [ ] mappings 重建 + `--init` 基线重置，增量模式 dry-run 正常（G5）
- [ ] Nexus-AI 本体仓库 `git status` 全程干净（硬约束 1）
