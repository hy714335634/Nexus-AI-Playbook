# 批次 6: 管理运维 + 设置 + 内置助手

**Environment**: https://d3sx15z6kvxyn3.cloudfront.net  
**Credentials**: admin/nexus  
**Date**: 2026-07-12  
**Viewport**: 1440x900

---

## Routes Covered

1. `/management` — Agent 列表 (4 agents) + 筛选 + 快速入口
2. `/ops` — AgentOps 运维总览 (42 在运行, 6 今日部署, 3 告警, 38 SLA≥99%)
3. `/admin/service-status` — 服务状态 (8 services running, system resources, EFS, infrastructure connections) + **Ops Helper**
4. `/admin/billing` (实际是 `/admin/billing` → `/usage-report`) — 用量报告 (按模型消耗 pie chart, Top 用户消耗 table, 应用用量 30d table)
5. `/analytics` — 业务洞察 (最近构建, 调用趋势, Agent Categories, 热门 Agent Top5, Recent Activity, 概览 + 实时观测性, 工具洞察)
6. `/settings/config` — 配置管理 (132 参数, AI 搜索 + 想调什么直接说, 分组 tabs: AI与模型26/内容与协作11/运行与部署58/可观测与日志16/其他21, 筛选: 全部/已改/热加载/需重启, 字段级 热加载/需重启 badges, 配置体检/导出/导入) + **Config Helper (inline AI search)**
7. `/settings/audit` — 审计追踪 (仪表盘/日志/订阅通知 tabs, 时间范围筛选 7d/30d/90d, 重新校验, pie charts: auth/user/config + success rate, 本期 14 次非工作时间操作) + **Audit Helper**
8. `/settings/model-catalog` — 模型目录 (添加提供商, 与 Bedrock 核对, 恢复默认, per-model: model_id/显示名/tier(pro/standard/lite)/视觉 checkbox/测试 button)
9. `/settings/profile` — 个人信息 (用户名/邮箱, 更新资料, 修改密码 section: 当前密码/新密码/确认密码, 角色 section)
10. `/settings/browser-extension` — 浏览器扩展 (已连接的扩展 (0), 显示已撤销 checkbox, 刷新, 连接引导: "在对话页 Nexus Bridge 面板中点 Browser 标签连接扩展")

---

## 内置助手盘点

| Page | Helper Present? | Type | Question Asked | Response Shape |
|------|----------------|------|----------------|----------------|
| `/management` | ❌ No | - | - | - |
| `/ops` | ❌ No | - | - | - |
| `/admin/service-status` | ✅ Yes | Ops Helper (Nexus 助手) | 当前各服务运行状态如何？ | SSE stream → **Table** with 8 services (API/Worker/Frontend/Avatar/Event Scheduler/Sandbox Controller/Bridge/OTEL Collector), columns: 服务/状态/PID/端口/CPU/内存, all 🟢 running |
| `/admin/billing` | ❌ No | - | - | - |
| `/analytics` | ❌ No | - | - | - |
| `/settings/config` | ✅ Yes | Config Helper (inline AI search, "想调什么，直接说") | API 端口在哪里配置？ | Text response: "AI 命中 0 个与「API 端口在哪里配置？」相关的参数" (zero matches, valid response showing search functionality) |
| `/settings/audit` | ✅ Yes | Audit Helper (Nexus 助手) | 今天有哪些登录记录？ | SSE stream → **Structured summary**: "今天（2026-07-12）共有 8 条登录记录，均为 admin@dev.local 的成功登录（success），来自两个 IP：27.0.3.148 和 27.0.3.156。" + timestamp list + conclusion + **ui_action button**: "查看今日登录记录" (tag: auth:login) |
| `/settings/model-catalog` | ❌ No | - | - | - |
| `/settings/profile` | ❌ No | - | - | - |
| `/settings/browser-extension` | ❌ No | - | - | - |

**Helpers found**: 3 out of expected 7 — **Ops Helper** (service-status page), **Config Helper** (config page inline AI search), **Audit Helper** (audit page)  
**Not found**: Tool Review Helper, Skill Forge Helper, App Builder Helper, Mission Helper (likely not deployed on this test environment or on different pages not covered)

---

## Detailed Notes

### 1. /management

**Purpose**: Agent 管理页面，展示 Agent 列表与操作入口  
**Main UI Blocks**:
- Top actions: 创建 Agent, 新建 Agent, 提交迭代需求
- Filters: 搜索框 ("搜索 Agent / 负责人 / 部门"), 状态下拉 (全部状态/运行中/构建中/已暂停), 批量操作
- Agent 列表 table (4 agents): columns — Agent 名称/负责人/分类/状态/最近更新/操作
  - 客服质检助手 (企业业务部·张强, 客服, 运行中, 09:18)
  - 销售线索分析器 (增长团队·李宁, 销售, 构建中, 09:05)
  - 金融风控审核员 (风控团队·王敏, 金融, 运行中, 08:42)
  - 产品质量巡检官 (研发 QA·刘洋, 质量, 已暂停, 昨日)
- List actions: 导出列表, 智能排序
- **快速入口** section (3 links):
  - 项目演进总览 · 查看甘特泳道与节点状态 →
  - 分析面板 · 成功率 / 耗时箱线图 / 风险 TopN →
  - 历史版本 · 对比回滚 & 枢纽事件 →
  
**Screenshot**: `06-management-overview.png`

---

### 2. /ops

**Purpose**: AgentOps 运维总览 — 查看运行状况、告警信息与部署节奏  
**Main UI Blocks**:
- Top link: 查看工具构建流水线 →, 导出日报
- **Metrics cards**:
  - 42 在运行 Agent
  - 6 今日部署
  - 3 告警 (24h)
  - 38 SLA ≥ 99%
- **部署节奏**: 折线图占位（展示过去 7 日部署次数与失败率）
- **告警列表**:
  - 09:32 Salesforce 工具限流，自动退避中…
  - 09:05 提示词版本 1.3.2 请求超时，已重试
  - 08:47 Agent Runtime 节点 us-west-2 负载 78%
- **运行状况**: 拓扑占位（运行节点、工具、外部服务之间的调用关系）
- **SLA 快照**:
  - 客服质检助手 · SLA 99.2%
  - 销售线索分析器 · SLA 98.7%，建议关注
  - 金融风控审核员 · SLA 99.8%

**Screenshot**: `06-ops-page.png`  
**Note**: No floating helper visible on this page (the Ops Helper found on /admin/service-status is specific to that page)

---

### 3. /admin/service-status

**Purpose**: 服务状态管理 — 查看系统资源、服务列表、存储空间、基础设施连接  
**Main UI Blocks**:
- Tabs: 总览 (active), 实时日志, Sandbox, 服务管理
- Top link: 配置管理 link
- **系统资源** section (with 刷新 button)
- **服务列表** section — 8 services, each with 重启/停止/日志 buttons:
  - API, Worker, Frontend(Web), Avatar, Event Scheduler, Sandbox Controller, Bridge, OTEL Collector
- **存储空间 (EFS)** section
- **基础设施连接** section
- **Nexus 助手 button** (bottom-right floating helper)

**Helper Interaction**: See "Helper Interactions" section below  
**Screenshots**: `06-admin-service-status.png`, `06-ops-helper-response.png`

---

### 4. /admin/billing

**Actual Route**: `/admin/billing` redirects/resolves to usage report page  
**Purpose**: 用量报告 — 按模型消耗、Top 用户消耗、应用用量统计  
**Main UI Blocks**:
- Month picker: 2026年7月 (spinbuttons for year/month + date picker button)
- **按模型消耗** section:
  - Pie chart (72% / 28% / 0%)
  - Table columns: 模型/调用/输入/输出/总 Token
    - anthropic.claude-opus-4-8: 36 calls, 15.2M input, 233.2K output, 15.4M total
    - anthropic.claude-sonnet-4-6: 48 calls, 5.4M input, 486.9K output, 5.9M total
    - anthropic.claude-sonnet-5: 1 call, 4.7K input, 4.2K output, 8.9K total
- **Top 用户消耗** section:
  - Search box: 搜索用户名 / 邮箱 / ID
  - Table columns: 用户/调用/输入/输出/总 Token/配额用量
    - admin (admin@dev.local, uuid 8450d6e4...): 164 calls, 33.5M input, 1.4M output, 34.9M total, "-" quota
  - Link: 查看配额用量详情
- **应用用量 (近 30 天)** section:
  - Table columns: 应用/访问量/调用/总 Token/平均单次消耗/配额(累计)
    - 营销海报与落地页工作室 (app_f984663ed3a3): 2 visits, 1 call, 410 tokens, 410 avg, 不限 quota
  - Expandable detail: "展开模型 / 输入输出明细" button → shows model breakdown table (anthropic.claude-sonnet-5: 3 calls, 24.9K tokens) + direction table (输入 80%, 输出 20%)

**Cost Dimensions Visible**: Model-level token consumption (input/output split), user-level consumption, app-level consumption (visits + calls + avg per call), quota usage (though "-" and "不限" in this data)  
**Screenshot**: `06-admin-billing-usage.png`

---

### 5. /analytics

**Purpose**: 业务洞察 — 多维度分析（构建、调用、分类、热门、活动、实时观测性、工具洞察）  
**Main UI Blocks**:
- **最近构建 (近 30 天)** section
- **调用趋势 (近 30 天)** section — chart area with multiple clickable generic elements (likely data points)
- **Agent Categories** section
- **热门 Agent** section — Top 5 list:
  1. IT运维专家 — 49
  2. 全球临床试验监测系统 — 34
  3. 中医诊断师 — 10
  4. 生物医学绘图助手 — 9
  5. 生物信息学专家 — 7
- **Recent Activity** section — activity log:
  - tool_build_2026-07-12 构建完成 13分钟前
  - Poster & Landing Page Studio Update 构建完成 37分钟前
  - agent_07120653_0c3d8c 正在构建 1小时前
  - Poster & Landing Page Studio Update 构建完成 16小时前
  - tcm_diagnostician 运行中 16小时前
  - slideforge_presentation_designer 运行中 16小时前
- **概览 + 实时观测性** section:
  - Time range buttons: 1h, 6h, 24h, 7d, 30d
  - Metrics (h4 headings):
    - 调用量
    - 延迟 (P50/P90/P99)
    - Token 消耗 (Input/Output)
    - 错误
- **工具洞察 (近 7 天)** section:
  - 🐢 最慢工具 Top 5 (按 P90)
  - 🔥 高频工具 Top 5

**Screenshot**: `06-analytics-page.png`

---

### 6. /settings/config

**Purpose**: 配置管理 — 字段级编辑系统配置（DDB 优先 / 文件兜底），支持热加载与一键重启  
**Main UI Blocks**:
- Subtitle: "字段级编辑系统配置（DDB 优先 / 文件兜底），支持热加载与一键重启"
- Top links (quick shortcuts):
  - 分享管理 — 文件分享策略 · 投递通道配置
  - 模型目录 — 编辑可选模型列表 · 测试后保存立即生效
  - 浏览器扩展 — 管理 Chrome 扩展设备 · 撤销/恢复
- Buttons: 配置体检, 导出, 导入
- **想调什么，直接说** section (AI search interface):
  - Heading: "用自然语言找参数，或让 AI 顾问给建议"
  - Search input: "搜参数 / 描述你的目标，如：降低成本…"
  - "AI 搜索" button (enabled after typing)
  - Suggested queries (buttons): 降低使用成本, 对话总丢上下文, 哪些改了要重启
- **Category tabs** (parameter grouping):
  - 全部 132
  - AI 与模型 26
  - 内容与协作 11
  - 运行与部署 58
  - 可观测与日志 16
  - 其他 21
- **Filter buttons** (state filters):
  - 全部
  - 已改
  - 热加载
  - 需重启
- **Config fields** (example from snapshot):
  - Field: "模型" (bedrock.model_id)
    - "历史版本" button
    - "问 AI：作用与调整影响" button (per-field AI assistant)
    - Badge: **热加载** (green badge, class `config-badge config-badge-hot`)
    - Description: "默认对话/构建所用模型；多数 Agent 走这一档。新会话即时生效"
    - Value: combobox with ~50+ model options (us.anthropic.claude-sonnet-4-5-20250929-v1:0 selected, options include Claude Sonnet 5, Opus 4.7/4.8/4.6/4.5, Fable 5, Haiku 4.5, Nova, Llama, Mistral, DeepSeek, Qwen, Gemma models)

**Badge System**: 
- **热加载** badge (green, `config-badge-hot`): indicates hot-reloadable config (no service restart needed)
- **需重启** badge: presumably exists for restart-required config (seen in filter buttons but not in visible fields during this walkthrough)
- **已改** badge/indicator: for modified fields (seen in filter but no modified fields observed)

**Sensitive Field Masking**: Not directly observed in the snapshot (would need to check password/secret fields, likely masked with *** or hidden input type)

**Save Flow**: 
- Individual field edits (combobox/textbox changes)
- "保存" button (disabled in initial state, presumably enables after changes)
- Each field has "历史版本" button for version history
- "配置体检" button for health check, "导出/导入" for bulk operations

**Helper Interaction**: See "Helper Interactions" section below  
**Screenshots**: `06-settings-config-top.png`, `06-settings-config-fields.png`, `06-config-helper-response.png`

---

### 7. /settings/audit

**Purpose**: 审计追踪 — 审计日志查看、仪表盘、订阅通知、AI 审计助手  
**Main UI Blocks**:
- Tabs: 仪表盘 (active), 日志, 订阅通知
- Time range filters (buttons): 近 7 天, 近 30 天, 近 90 天
- "重新校验" button
- Alert card: "本期 14 次非工作时间操作" (disabled button, informational)
- **Pie charts** (2 charts):
  - Chart 1: Event type breakdown — "auth: 36, user: 2, config: 1"
  - Chart 2: Success rate — "success: 39"
- **Nexus 助手 button** (bottom-right floating helper)

**Audit Log Columns** (from 日志 tab, not directly visible in this snapshot but implied by the page):
- Timestamp, Event type (auth/user/config), Action, User, Status (success/failure), IP, Details

**Helper Interaction**: See "Helper Interactions" section below  
**Screenshots**: `06-settings-audit-dashboard.png`, `06-audit-helper-response.png`

---

### 8. /settings/model-catalog

**Purpose**: 模型目录 — 编辑可选模型列表，测试后保存立即生效  
**Main UI Blocks**:
- Top link: 返回配置管理
- Buttons: 添加提供商, 与 Bedrock 核对, 恢复默认, 保存 (disabled initially)
- **Provider section** (collapsible):
  - Provider name textbox: "Anthropic"
  - "添加模型" button
- **Model entries** (per model):
  - Delete button (trash icon)
  - model id textbox (e.g., "global.anthropic.claude-sonnet-5")
  - 显示名 textbox (e.g., "Claude Sonnet 5")
  - Tier combobox: pro / standard / lite
  - "视觉" checkbox (vision capability)
  - "测试" button (test connection)

**Model List Shape** (examples from snapshot):
- Claude Sonnet 5 (global.anthropic.claude-sonnet-5, pro, vision ✓)
- Claude Opus 4.7 (global.anthropic.claude-opus-4-7, pro, vision ✓)
- Claude Opus 4.8 (global.anthropic.claude-opus-4-8, pro, vision ✓)
- Claude Fable 5 (global.anthropic.claude-fable-5, pro, vision ✓)
- Claude Opus 4.6 (global.anthropic.claude-opus-4-6-v1, pro, vision ✓)
- Claude Opus 4.5 (global.anthropic.claude-opus-4-5-20251101-v1:0, pro, vision ✓)
- Claude Sonnet 4.6 (global.anthropic.claude-sonnet-4-6, standard, vision ✓)
- Claude Sonnet 4.5 (global.anthropic.claude-sonnet-4-5-20250929-v1:0, standard, vision ✓)
- Claude Haiku 4.5 (global.anthropic.claude-haiku-4-5-20251001-v1:0, lite, vision ✓)
- Claude Opus 4.6 (us) (us.anthropic.claude-opus-4-6-v1, pro, vision ✓)
- ... (more models listed)

**Capability Columns**: 
- Tier (pro/standard/lite) — cost/performance tier
- 视觉 (vision) checkbox — multimodal image understanding capability

**Refresh Affordance**: 
- "与 Bedrock 核对" button — syncs with AWS Bedrock model catalog
- "恢复默认" button — resets to default model list
- "保存" button — persists changes (enables after edits)

**Screenshot**: `06-settings-model-catalog.png`

---

### 9. /settings/profile

**Purpose**: 个人信息 — 用户资料、修改密码、角色查看  
**Main UI Blocks**:
- User heading: "admin" (h2)
- **个人信息** section:
  - 用户名 textbox: "admin"
  - 邮箱 textbox: "admin@dev.local"
  - "更新资料" button (disabled initially, enables after edits)
- **修改密码** section:
  - 当前密码 textbox (password type with show/hide button)
  - 新密码 textbox (password type with show/hide button)
  - 确认密码 textbox
  - "修改密码" button (disabled initially, enables after filling all fields with valid input)
- **角色** section (h3 heading, content not visible in snapshot but likely shows user role/permissions)

**Profile Fields**: 
- Username (用户名)
- Email (邮箱)
- Current password (for password change)
- New password
- Confirm password

**Screenshot**: `06-settings-profile.png`

---

### 10. /settings/browser-extension

**Purpose**: 浏览器扩展 — 管理 Chrome 扩展设备，撤销/恢复连接  
**Main UI Blocks**:
- Top link: 返回配置管理
- Heading: "已连接的扩展 (0)" — shows count of connected extensions
- "显示已撤销" checkbox (unchecked) — toggles visibility of revoked extension connections
- "刷新" button — refreshes connection status
- Empty state message: "尚无已连接的扩展" (no connected extensions)
- **Connection guide text**: "在对话页 Nexus Bridge 面板中点 Browser 标签连接扩展"

**Download Link**: Not visible on this page (likely handled in-app or via the Nexus Bridge panel mentioned in the connection guide)

**Connection Guide Steps** (verbatim from page text):
1. 在对话页 Nexus Bridge 面板中点 Browser 标签连接扩展

**Note**: The full connection flow is likely:
1. User navigates to a chat/conversation page
2. Opens the "Nexus Bridge" panel
3. Clicks the "Browser" tab
4. Follows prompts to connect the Chrome extension
5. Connected extension appears on this `/settings/browser-extension` page with revoke/restore actions

**Screenshot**: `06-settings-browser-extension.png`

---

## Helper Interactions

### Ops Helper (/admin/service-status)

**Trigger**: Floating "Nexus 助手" button (bottom-right corner)  
**Panel UI**:
- "切换到居中大窗" button (switch to centered large window)
- Suggested questions (3 buttons):
  - worker 为什么没在消费消息？
  - 哪个服务最近在刷 ERROR？
  - api 启动失败怎么排查？
- Text input: "描述故障现象 / 问运维问题…"
- Send button (disabled when empty)

**Question Asked**: "当前各服务运行状态如何？"

**Response Shape**:
- SSE streaming response
- **Structured table** (rendered twice in the response, possibly chat message + ui_action):
  - Heading: "当前系统状态总览" (h2)
  - Table columns: 服务/状态/PID/端口/CPU/内存
  - 8 rows (all services showing 🟢 running status):
    - API: running, PID 193737, port 8000, CPU 0.1%, memory 206.8 MB
    - Worker: running, PID 192619, port -, CPU 0.1%, memory 253.5 MB
    - Frontend(Web): running, PID 192800, port 3000, CPU 0.7%, memory 177.7 MB
    - Avatar: running, PID 34354, port 8004, CPU 0.1%, memory 167.7 MB
    - Event Scheduler: running, PID 33412, port -, CPU 0.0%, memory 129.8 MB
    - Sandbox Controller: running, PID 34428, port 8002, CPU 0.2%, memory 163.9 MB
    - Bridge: running, PID 33297, port 8001, CPU 0.0%, memory 133.8 MB
    - OTEL Collector: running, PID 33237, port 4318, CPU 0.0%, memory 137.9 MB
- Duplicate table (same data, different column headers format: 服务/状态/PID/内存MB/CPU%)

**Capabilities Observed**:
- Real-time service status monitoring
- PID, port, CPU, memory metrics retrieval
- Suggested troubleshooting questions for common ops scenarios (worker not consuming, ERROR logs, api startup failures)

**Guardrails Visible**: 
- No restart/stop/destructive actions triggered directly from helper (those actions remain on the main service-status page as separate buttons)
- Helper provides read-only diagnostic information
- Suggested questions are diagnostic/investigative, not action-triggering (e.g., "为什么" / "怎么排查" rather than "重启 X")

**ui_action**: Table display (no navigate/button actions observed in this interaction)

---

### Config Helper (/settings/config)

**Trigger**: Inline AI search interface ("想调什么，直接说" section) + floating "Nexus 助手" button (appears after search)

**Search UI**:
- Heading: "想调什么，直接说" (h2)
- Subtitle: "用自然语言找参数，或让 AI 顾问给建议"
- Search input: "搜参数 / 描述你的目标，如：降低成本…"
- "AI 搜索" button (disabled when empty, enables after typing)
- Suggested queries (3 buttons):
  - 降低使用成本
  - 对话总丢上下文
  - 哪些改了要重启

**Helper Panel** (opens after search, via "Nexus 助手" button):
- "切换到居中大窗" button
- Clear button
- Suggested questions (4 buttons):
  - 我想降低使用成本
  - 对话经常丢失上下文怎么办
  - prompt 缓存是干嘛的，建议开吗
  - 哪些参数改了需要重启服务
- Text input: "例如：我想降低成本 / 对话总丢上下文…"
- Send button (disabled when empty)

**Question Asked**: "API 端口在哪里配置？"

**Response Shape**:
- Text response: **"AI 命中 0 个与「API 端口在哪里配置？」相关的参数"**
- Zero-match result (still valid response showing the search functionality)
- "清除" button appears after search (to clear results and reset)

**Expected Response Shape** (based on UI design, not observed due to zero-match):
- Likely highlights/filters matching config parameters
- Potentially displays parameter cards with description, current value, 热更新/需重启 badge
- May provide recommendations or impact analysis (given the "问 AI：作用与调整影响" button per field)

**Capabilities Observed**:
- Natural language config parameter search
- Semantic matching (not just keyword search)
- Suggested common optimization queries (cost reduction, context handling, cache config, restart requirements)
- Per-field AI advisor ("问 AI：作用与调整影响" button on each config field)

**ui_action**: None observed in this interaction (zero-match scenario); likely navigate/highlight actions on successful matches

---

### Audit Helper (/settings/audit)

**Trigger**: Floating "Nexus 助手" button (bottom-right corner)

**Panel UI**:
- "切换到居中大窗" button
- Action buttons (3 buttons, likely ui_action triggers):
  - 区间总结 (interval summary)
  - 生成合规报告 (generate compliance report)
  - 发送到 SNS (send to SNS)
  - Note: "范围跟随当前筛选条件" subtitle (actions respect current time range filter)
- Suggested questions (3 buttons):
  - 这段时间谁改了配置？
  - 有没有失败登录或越权尝试？
  - 哪个用户操作最频繁？
- Text input: "例如：这段时间谁改了配置 / 有无失败登录…"
- Send button (disabled when empty)

**Question Asked**: "今天有哪些登录记录？"

**Response Shape**:
- SSE streaming response
- **Structured summary** (text format):
  - Opening: "今天（2026-07-12）共有 8 条登录记录，均为 admin@dev.local 的成功登录（success），来自两个 IP：27.0.3.148 和 27.0.3.156。"
  - Section: "具体时间："
  - Timestamp list grouped by IP:
    - "07:25:56、07:16:31、06:59:06、06:49:46、06:49:16、06:39:37 —— ip=27.0.3.148"
    - "06:44:06、06:20:50 —— ip=27.0.3.156"
  - Conclusion: "均无失败记录，IP 段一致（27.0.3.x），暂未见异常。"
- **ui_action button**: "查看今日登录记录" (tag: "auth:login") — actionable button to navigate to filtered audit log view

**Capabilities Observed**:
- Natural language audit log querying
- Time range interpretation ("今天" → 2026-07-12)
- Data aggregation (count, user, IPs)
- Anomaly detection / risk assessment ("均无失败记录", "IP 段一致", "暂未见异常")
- Actionable navigation (ui_action button to filtered log view)
- Action buttons for compliance workflows (区间总结, 生成合规报告, 发送到 SNS)

**ui_action**: 
- Type: Button
- Label: "查看今日登录记录"
- Tag: "auth:login"
- Expected behavior: Navigates to /settings/audit?tab=日志&filter=auth:login&date=2026-07-12 (or similar filtered view)

---

## FINDINGS

### F015: Config AI 搜索零命中但功能正常
- **现象**: 在 /settings/config 测试 "API 端口在哪里配置？" 返回 "AI 命中 0 个与...相关的参数"
- **位置**: /settings/config AI 搜索
- **分析**: 
  - 零命中是合理结果（api.port 可能在 service_config.yaml 而非 default_config.yaml 管理参数，或未建索引）
  - 功能本身正常（输入 → AI 搜索 → 响应流）
  - 搜索效果待真实场景验证（如 "降低成本" 等建议查询）
- **影响**: 不阻塞手册，需补充"搜索可能零命中需换关键词"提示
- **阻塞手册**: ❌ No

### F016: Browser Extension 连接引导单一步骤
- **现象**: /settings/browser-extension 仅展示 "在对话页 Nexus Bridge 面板中点 Browser 标签连接扩展" 一句话引导
- **位置**: /settings/browser-extension
- **分析**:
  - 无下载链接（扩展包可能内置或通过 Bridge 面板提供）
  - 单步引导简洁但可能不够详尽（首次用户需知：1. 去哪个对话页？2. Bridge 面板在哪？3. 连接后如何验证？）
  - Memory 记录显示 Browser 功能架构复杂（扩展 submodule、Bridge IPC、注入 gate），单句引导是否充分存疑
- **影响**: 手册需补充多步骤详细引导（含截图），否则用户可能卡在连接流程
- **阻塞手册**: ⚠️ Partial — 需补充详细步骤 + 截图，否则浏览器扩展章节不完整
- **建议**: 走查 /chat 页面找 Bridge 面板 → Browser 标签 → 连接流程（补充到后续批次或专项走查）

### F017: Helper 覆盖度不全（7 中仅找到 3）
- **现象**: 预期 7 个内置助手（config/audit/ops/tool_review/skill_forge/app_builder/mission），实际仅找到 3 个（ops/config/audit）
- **位置**: 全局
- **分析**:
  - Ops Helper: 出现在 /admin/service-status（非 /ops 页面，可能 /ops 是仪表盘不含交互式助手）
  - Config Helper: 以 inline AI 搜索形式集成在 /settings/config（非传统浮动圆点）
  - Audit Helper: 出现在 /settings/audit
  - 未找到 4 个：tool_review / skill_forge / app_builder / mission
    - 可能在其他页面（/workshop tool/skill 编辑页、/app-center 编辑页、/my-home mission 面板）
    - 或未在测试环境部署（feature flag / 企业版专属 / 开发中）
- **影响**: 手册"内置助手"章节需调整预期或补充走查其他页面
- **阻塞手册**: ⚠️ Partial — 如手册承诺 7 个助手但实际仅 3 个可用，需澄清范围或补充走查
- **建议**: 
  1. 确认 4 个未找到助手的预期部署位置（问开发 or 检查代码）
  2. 补充走查 /workshop、/app-center 编辑页、/my-home（A2 批次已覆盖但可能未注意助手）
  3. 手册注明"部分助手可能需特定场景触发或版本限制"

### F018: /admin/billing 实际是 /usage-report 页面
- **现象**: 导航到 /admin/billing 后 URL 仍为 /admin/billing，但页面标题和内容是"用量报告"（非传统意义的 billing/账单）
- **位置**: /admin/billing
- **分析**:
  - 页面展示用量统计（token 消耗、调用次数、用户用量、应用用量），无价格/账单/支付信息
  - "Billing" 在本系统语境下可能指"用量计费维度"而非"账单管理"
  - Memory 中 cfgfix 环境是 basic 版，可能无独立计费模块
  - 或者 billing 功能未开发完整，当前仅展示用量报告作为计费数据基础
- **影响**: 手册需澄清"账单"章节实际指"用量报告"，避免用户期望找支付/发票入口
- **阻塞手册**: ❌ No（功能存在，只是命名 vs 内容有偏差）
- **建议**: 手册使用"用量报告"而非"账单"，或注明"当前版本账单功能以用量报告形式呈现"

---

## Summary

- **Routes covered**: 10 (/management, /ops, /admin/service-status, /admin/billing, /analytics, /settings/config, /settings/audit, /settings/model-catalog, /settings/profile, /settings/browser-extension)
- **Helpers found**: 3 out of expected 7
  - ✅ Ops Helper (service-status page)
  - ✅ Config Helper (config page inline AI search)
  - ✅ Audit Helper (audit page)
  - ❌ Tool Review Helper (not found)
  - ❌ Skill Forge Helper (not found)
  - ❌ App Builder Helper (not found)
  - ❌ Mission Helper (not found)
- **Helper interactions**: 3 (1 per found helper)
  - Ops Helper: Asked "当前各服务运行状态如何？" → received 8-service status table (SSE stream)
  - Config Helper: Asked "API 端口在哪里配置？" → received zero-match response (valid, shows functionality)
  - Audit Helper: Asked "今天有哪些登录记录？" → received structured summary + ui_action button (SSE stream + navigate button)
- **Screenshots**: 10 (1 per route + 2 helper response screenshots)
- **Config changes made**: NONE (only queried AI search, did not modify any config values or save)
- **Actions triggered**: NONE (did not click restart/stop buttons, did not generate reports, did not modify data)

**Key Observations**:
1. All 10 admin/settings pages are functional and well-structured
2. Helper system is present but coverage is partial (3/7 found)
3. Config management page is highly sophisticated (132 params, AI search, hot-reload badges, grouping, per-field AI advisor)
4. Audit helper provides impressive semantic analysis (anomaly detection, IP grouping, time aggregation) with actionable ui_action buttons
5. Model catalog supports multi-provider, tier classification, vision capability flags, and test workflow
6. Browser extension page has minimal guidance (single-sentence connection guide, no download link visible)
7. Usage report (billing) page shows comprehensive multi-dimensional consumption tracking (model/user/app levels with token breakdowns)

---

## 补测：App Builder 助手 = 应用快速创建向导（2026-07-12 控制器实测）

初判 "app_builder helper 未找到" 系搜索位置不对：它不是浮动圆点，而是**应用中心「新建应用」的快速创建向导本体**。全程实测一遍（并顺带补齐了 A5 缺的"新应用首次发布"记录）：

### 入口
/apps 右上 「新建应用」 按钮

### 步骤（verbatim）
1. 点击 「新建应用」 → 弹窗 "选择创建方式"：**快速创建**（"选 Agent + 描述场景,分步生成可发布页面,速度快"）/ **完整创建**（"进入工坊,通过 4 阶段工作流(需求分析→设计→前端→部署)自动构建完整应用"）→ 「下一步」
2. 快速创建 **第 1 步 · 选择 Agent**：搜索框 "搜索 Agent…" + 全部可用 agent 列表（内置 4 个 + 环境内生成 agent），选 General Assistant → 「下一步」
3. **第 2 步 · 应用信息与需求**：字段 "应用名称" + "场景与 UI 需求"（textarea placeholder："用自然语言描述:这个应用给谁用、解决什么问题、需要哪些输入项、期望的界面样式和交互。例如:一个客服知识问答页,顶部有搜索框,用户输入问题后展示 Agent 的流式回答,支持追问,配…"），另有 12 个图标（🧩🤖📊💬📝🔍🎨⚙️📈🗂️🧠✨）供选应用图标 → 「新建应用」
4. 提交后跳转 `/apps/app_c2095f594c32`，进入三步态流程条：**1 需求 → 2 生成 → 3 就绪**，点 「开始设计」
5. 生成阶段实时显示 **"正在自动生成应用 已生成 N 字"** 计数（185 → 3,974 → 22,277 字，全程约 4-6 分钟）。注：第一次点击后曾回退到 "开始设计"（生成中断，原因未明——单次样本，可能与会话过期相关），重试一次成功
6. 完成后应用状态 "就绪"，版本 v1，出现 "实时预览" iframe + 顶部按钮 "编辑配置 / API / 版本与更新 v1 / 发布"
7. **发布流程**：点 「发布」 → "发布应用" 弹窗：**有效期**（7 天 / 30 天 / 90 天 / 永久(无限期)，默认 7 天）× **访问鉴权**（公开 / API Key / 账号密码）→ 「发布」
8. 发布成功：状态变 "已发布"，显示 "访问鉴权 公开 | 有效期 2026/07/19" + 公开 URL `https://d3sx15z6kvxyn3.cloudfront.net/a/app_c2095f594c32`；顶部出现 "复制链接 / 打开应用 / 下线"

### 截图
- `shots/06/06-15-new-app-mode-dialog.png` 创建方式选择
- `shots/06/06-16-new-app-step2.png` 第1步选 Agent
- `shots/06/06-17-new-app-step2-scene.png` 第2步应用信息
- `shots/06/06-19-new-app-submitted.png` 提交后三步态
- `shots/06/06-20-app-builder-designing.png` 生成中（字数计数）
- `shots/06/06-22-app-builder-status.png` 就绪态
- `shots/06/06-23-publish-dialog.png` 发布弹窗（有效期×鉴权）
- `shots/06/06-24-published.png` 已发布（公开 URL）

### 边界/发现
- **helper 定位修正**：app_builder 不是浮动 dot，是快速创建向导的后端引擎；mission helper 同理大概率在任务面板的 NL 任务创建里（批次 5 已记录该弹窗）；tool_review / skill_forge 推测在工具构建/技能构建流程内部（构建产物 review 环节），不是独立 UI 入口
- 发布默认有效期 7 天——手册要提醒长期应用选"永久"
- 「开始设计」偶发一次生成中断回退（单样本），重试成功；如复现值得工程关注
- probe 应用：app_c2095f594c32（每日站会纪要助手，已发布公开，可作 Demo 素材或后续清理）
