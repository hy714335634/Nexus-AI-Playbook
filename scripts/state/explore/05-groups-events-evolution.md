---
batch: 5
coverage: resource-groups, settings/sharing, users, events, evolution/**, pfr/**, troubleshoot/**
date: 2026-07-12
routes_tested: 19
findings_added: F014
---

# Batch 5: 资源组/分享/用户 + 事件 + 进化/PFR/排障

## 功能 1: /resource-groups — 共享资源（文件夹）

### 入口
- 左侧导航 → "共享资源"
- URL: `https://d3sx15z6kvxyn3.cloudfront.net/resource-groups`

### 步骤
1. 页面标题 "共享资源"
2. 主操作: "新建文件夹" 按钮 + "创建第一个文件夹" 空状态按钮
3. 功能定位: 资源共享文件夹管理（非用户分组）

### 截图
- `05-resource-groups-list.png` — 空状态页面

### 边界
- 空数据状态
- 未创建任何文件夹（保持环境清洁）

---

## 功能 2: /settings/sharing — 文件分享配置

### 入口
- 左侧导航 → "设置" → "分享管理"
- URL: `https://d3sx15z6kvxyn3.cloudfront.net/settings/sharing`

### 步骤
1. 页面标题 "文件分享配置"
2. **全局策略**
   - 默认过期时间: 1h / 6h / 24h / 3天 / 7天（单选按钮组）
   - 最大过期时间: 同上选项
   - 允许格式白名单: `.html, .pdf, .csv`
   - 禁止格式黑名单: `.exe, .bat, .sh`
   - 密码强度要求: 两个 spinbutton（数值输入）
   - 自定义域名: `https://your-domain.com`
3. **投递通道**（7 种，带开关）
   - 链接分享（已启用）
   - 邮件推送（未启用）— SMTP / AWS SES
   - Slack（未启用）— Incoming Webhook
   - 钉钉（未启用）— Webhook
   - 飞书（未启用）— Webhook
   - Microsoft Teams（未启用）— Webhook
   - 通用 Webhook（未启用）— HTTP POST
4. 底部操作: "重置" / "保存配置"（禁用状态，未修改时）

### 截图
- `05-settings-sharing.png` — 完整配置页

### 边界
- 所有投递通道除"链接分享"外均未启用
- 未修改任何配置

---

## 功能 3: /users — 用户管理

### 入口
- 左侧导航 → "用户管理"
- URL: `https://d3sx15z6kvxyn3.cloudfront.net/users`

### 步骤
1. 页面标题 "用户管理"
2. **Tab 1: 用户列表**（默认）
   - 搜索框: "搜索用户..."
   - 主操作: "添加部门" / "创建用户"
   - 分组卡片展示:
     - **Default** (0 人) — "Default group for all users"
     - **SystemAdmin** (0 人) — "System administrators group"
   - 每个卡片右上角下拉菜单: "编辑分组" / "分组策略" / "删除分组"
3. **"创建用户" 对话框**
   - 字段:
     - 用户名: `显示名称`（必填）
     - 邮箱: `user@example.com`（必填）
     - 密码: `至少 4 个字符`（必填，带显示/隐藏切换）
     - 角色: 四选一按钮组
       - **Admin** — 完全管理权限
       - **Editor** — 创建和编辑资源
       - **User** — 使用 Agent 和查看
       - **Viewer** — 只读查看
   - 底部操作: "取消" / "创建"
   - **已点击取消，未创建用户**
4. **"创建分组" 对话框**（点击 "添加部门" 触发）
   - 字段:
     - 分组名称: `例如：工程团队`（必填）
     - 描述: `分组描述（可选）`
     - 上级分组: 下拉菜单，选项: `无（顶级分组）` / `Default` / `System`
   - 底部操作: "取消" / "创建"
   - **已点击取消，未创建分组**
5. **Tab 2: 策略管理**
   - 搜索框: "策略名称"
   - 主操作: "创建策略"
   - **托管策略**（系统内置，不可编辑）:
     - **AdministratorAccess** — 完全管理权限，49 个权限
     - **EditorAccess** — 创建和编辑资源，43 个权限
     - **UserAccess** — 使用 Agent 和查看资源，25 个权限
     - **ViewerAccess** — 只读查看，18 个权限
   - **自定义策略**: 空，带 "创建策略" 按钮

### 截图
- `05-users-list.png` — 用户列表 tab，两个默认分组
- `05-users-create-dialog.png` — 创建用户对话框（完整字段）
- `05-users-create-group-dialog.png` — 创建分组对话框
- `05-users-policy-mgmt.png` — 策略管理 tab

### 边界
- 两个默认分组均无成员（0 人）
- **未创建任何用户或分组**
- 策略管理无自定义策略

### 发现
- 无用户上限提示（与 batch 4 发现的 basic 版 30 用户上限机制不同，此页面未展示剩余配额）

---

## 功能 4: /events — 任务面板

### 入口
- 左侧导航 → "任务面板"
- URL: `https://d3sx15z6kvxyn3.cloudfront.net/events`

### 步骤
1. 页面标题 "任务面板"
2. 主操作: "新建任务" / "Refresh"
3. 空状态（无任务记录）
4. **"自然语言创建任务" 对话框**（点击 "新建任务"）
   - 提示文案: "描述目标，助手帮你匹配资源并生成可执行方案"
   - 引导文字: "用一两句话描述你想让系统持续或一次性完成的目标，信息越具体，方案越准确。"
   - 输入框: `任务目标`（大文本框）
   - 底部操作: "开始分析"（输入前禁用）
   - **已关闭对话框，未输入任何内容**

### 截图
- `05-events-empty.png` — 空任务列表
- `05-events-nl-create.png` — NL 任务创建对话框

### 边界
- 零任务记录
- **未创建任何定时任务**（避免污染环境）
- 对话框未展示三种任务类型（one_time/recurring/autonomous）的区分 UI（可能在 "开始分析" 后的下一步）

---

## 功能 5: /evolution/** — 进化管理（5 子页）

### 入口
- URL 直接访问（左侧导航无独立入口）

### 5.1 /evolution/submit — 需求提交

#### 步骤
1. 表单字段:
   - **需求标题**: 文本框（必填）
   - **负责人**: 下拉菜单，选项: 张强 / 李宁 / 王敏 / 刘洋（默认: 张强）
   - **优先级**: 下拉菜单，选项: 高 / 中 / 低（默认: 高）
   - **需求描述**: 大文本框（必填）
2. 底部操作: "保存草稿" / "提交需求"
3. **未填写任何内容，未提交需求**

#### 截图
- `05-evolution-submit.png`

#### 边界
- 表单空白状态

---

### 5.2 /evolution/progress — 进度跟踪

#### 步骤
1. 三个可视化面板（占位/空数据）:
   - **燃尽图**
   - **依赖关系**
   - **里程碑时间线**

#### 截图
- `05-evolution-progress.png`

#### 边界
- 无实际数据展示

---

### 5.3 /evolution/agents — Agent 迭代

#### 步骤
1. 表格列: Agent 名称 / 版本 / 状态 / 负责人 / 所属迭代 / 操作
2. 示例数据（3 行）:
   - **客服质检助手** — v1.3.2 / 运行中 / 张强 / 迭代 #104 – 多语言支持
   - **销售线索分析器** — v1.2.0 / 构建中 / 李宁 / 迭代 #102 – 提示词重训
   - **金融风控审核员** — v1.1.4 / 运行中 / 王敏 / 迭代 #099 – API 批量同步
3. 底部面板标题: "最近事件"（无数据）

#### 截图
- `05-evolution-agents.png`

#### 边界
- 表格有示例数据（非真实 Agent）
- 未点击 "查看详情" 链接

---

### 5.4 /evolution/history — 版本历史

#### 步骤
1. 面板标题: "版本差异对比"
2. 空内容区域

#### 截图
- `05-evolution-history.png`

#### 边界
- 无数据展示

---

### 5.5 /evolution/analytics — 分析报告

#### 步骤
1. 三个分析面板（占位/空数据）:
   - **成功率趋势**
   - **耗时箱线图**
   - **风险 Top N**

#### 截图
- `05-evolution-analytics.png`

#### 边界
- 无实际数据

---

## 功能 6: /pfr/** — 迭代复盘（2 子页）

### 6.1 /pfr/history — 复盘历史

#### 步骤
1. 搜索框: "搜索 Agent / 评审人"
2. 状态筛选: 下拉菜单，选项: 全部状态 / 已合入 / 待复盘（默认: 全部状态）
3. 主操作: "导出 CSV"
4. 表格列: ID / Agent / 评审人 / 评分 / 状态 / 日期 / 详情
5. 示例数据（2 行）:
   - **pfr-210** — 客服质检助手 / 李宁 / 4 / 已合入 / 2024-03-12
   - **pfr-209** — 销售线索分析器 / 张强 / 3 / 待复盘 / 2024-03-11
6. 未点击 "查看" 链接

#### 截图
- `05-pfr-history.png`

#### 边界
- 表格有示例数据

---

### 6.2 /pfr/iterations — 迭代列表

#### 步骤
1. 返回 **404 页面**

#### 截图
- `05-pfr-iterations-404.png`

#### 发现
- **F014**: `/pfr/iterations` 404（路由未实现或路径错误）

---

## 功能 7: /troubleshoot/** — 排障工具（5 子页）

所有 5 个子页均为**空白页面**（仅框架布局，无内容区组件）:

- `/troubleshoot/analysis` — 空
- `/troubleshoot/code-review` — 空
- `/troubleshoot/reproduction` — 空
- `/troubleshoot/fix` — 空
- `/troubleshoot/tracking` — 空

### 截图
- `05-troubleshoot-analysis.png`
- `05-troubleshoot-code-review.png`
- `05-troubleshoot-reproduction.png`
- `05-troubleshoot-fix.png`
- `05-troubleshoot-tracking.png`

### 边界
- 五个页面均加载成功（无 404），但主内容区完全空白
- 可能为预留功能未实现，或需特定权限/数据触发内容渲染

---

## 统计

- **路由覆盖**: 19 个（resource-groups + settings/sharing + users + events + evolution/* × 5 + pfr/* × 2 + troubleshoot/* × 5）
- **对话框记录**: 3 个（创建用户、创建分组、NL 任务创建）
- **截图数量**: 20 张
- **创建资源**: 0（所有对话框均已取消）
- **FINDINGS 新增**: 1 条（F014）

---

## FINDINGS

### F014: PFR iterations 路由 404

**页面**: `/pfr/iterations`

**现象**: 返回 Next.js 404 页面

**影响**: 
- 任务描述中提到 `pfr/iterations`，但实际路由不存在
- 可能为路径拼写错误或功能未实现

**重现**: 直接访问 `https://d3sx15z6kvxyn3.cloudfront.net/pfr/iterations`

**优先级**: P3（文档与实现不一致）
