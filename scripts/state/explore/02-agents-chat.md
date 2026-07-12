---
env: d3sx15z6kvxyn3.cloudfront.net
date: 2026-07-12
batch: 2
routes_covered: /agents, /agents/new, /projects/:id, /chat, /agents/dialog, /agents/network, / (home create section)
hydration_fix: networkidle + 8s wait required for all CloudFront SPA pages
---

# 批次 2：Agent 全生命周期 + 独立聊天走查

**重要发现**：CloudFront 冷加载 SPA 水合需 5-10 秒，所有页面必须在 `networkidle` 后再等待 8 秒才能截图/交互，否则误判为空白页。

## 功能1：Agent 列表页 (/agents)

### 入口
- 侧边栏 "Agents" 导航项
- URL: https://d3sx15z6kvxyn3.cloudfront.net/agents

### 步骤
1. 点击侧边栏 "Agents" 进入列表页
2. **等待水合**：`wait --load networkidle && wait 8000` 后页面完全加载
3. 页面标题："Agents"，副标题："管理和监控您的智能 Agent"
4. 顶部操作栏：
   - 搜索框："搜索... ⌘K"
   - "交互网络" 按钮
   - "导入 Agent" 按钮
   - "+ 创建 Agent" 按钮（蓝色主按钮）
   - 通知图标、配置管理图标、用户头像
5. 统计卡片：
   - 7 Agent
   - 7 运行中
   - 113 总调用
   - 3 近 7 天活跃
6. 筛选区域：
   - 搜索框："搜索 Agent 名称..."
   - 排序下拉："名称" (可选：调用量、最近活跃、创建时间)
   - 分类筛选：全部 7、本地 0、云端 0
   - 状态筛选：全部 7、运行中 7、离线 0、异常 0
7. **实际数据**：显示 7 个 Agent 卡片（安全代码审计Agent、全球临床试验监测系统、生物信息学专家、生物医学绘图助手、中医诊断师、IT运维专家、SlideForge 演示文稿设计助手）
8. 卡片信息：名称、状态标签（运行中 1.0）、描述、本地/生成标签、工具标签（如 code_analysis、monitoring）、调用次数、时间戳

### 截图
- `shots/02/02-17-agents-list-hydrated.png` - 列表页加载后真实数据（7个Agent）

### 边界/发现
- ✅ **水合问题已解决**：使用正确等待后，列表页显示 7 个 Agent（与首页一致，无 F007 数据同步问题）
- **骨架屏持续显示已不复现**：有数据时正常显示卡片，无需验证空状态（当前环境有数据）
- 列表与首页数据一致，统计准确

---

## 功能2：快速创建 Agent (首页入口)

### 入口
- 首页 (/) "从想法到 Agent 自动化构建" 卡片
- 直接在首页文本框输入需求

### 步骤
1. 从侧边栏 "My Home" 或 Logo 点击进入首页 (/)
2. 页面顶部显示渐变色卡片：
   - 图标：魔法棒图标（蓝紫渐变）
   - 标题："从想法到 Agent 自动化构建"
   - 副标题："无需编程，只需描述业务场景和需求，系统将自动设计、开发并部署您的专属 Agent。业务人员也能轻松构建智能助手，实现业务流程自动化。"
   - 文本框 placeholder："描述你想要构建的 Agent，例如：帮我创建一个能够分析股票数据的智能助手..."
   - "构建" 按钮（带图标）
   - 快捷标签："医学文献"、"AWS 报价"、"新闻简报"
3. 在文本框输入：「创建一个中英互译助手：输入中文输出英文，输入英文输出中文，保持原文语气」
4. 点击 "构建" 按钮（或按 Enter）
5. **跳转至项目详情页**：URL 变为 `https://d3sx15z6kvxyn3.cloudfront.net/projects/proj_3cfac66211ba`
   - 项目 ID 已生成：`proj_3cfac66211ba`
   - 等待水合后页面显示项目构建阶段（见功能4）

### 截图
- `shots/02/02-home-create-section.png` - 首页创建卡片（历史截图）
- `shots/02/02-21-project-detail-stages.png` - 提交后跳转的项目详情页（水合后）

### 边界/发现
- ✅ **项目详情页不再空白**：使用正确等待后，页面显示完整的阶段时间轴（见功能4）
- **无命名提示**：快速创建流程无提示用户输入 Agent 名称，系统自动从需求文本提取 "中英互译助手" 作为名称
- 快捷标签点击未测试，推测为预设需求模板

---

## 功能3：引导创建 Agent (/agents/new)

### 入口
- 首页 "创建 Agent" 链接（指向 /agents/new）
- 侧边栏底部 "创建 Agent" 按钮（蓝色）
- Agent 列表页 "+ 创建 Agent" 按钮
- URL: https://d3sx15z6kvxyn3.cloudfront.net/agents/new

### 步骤
1. 通过任意入口点击进入 /agents/new
2. **等待水合**：`wait --load networkidle && wait 8000`
3. 页面标题："创建 Agent"，副标题："用自然语言描述业务需求，AI 将自动构建专属 Agent"
4. 主体区域显示创建方式选择：
   - **快速创建**（左侧卡片）：
     - 图标：⚡（黄色）
     - 标题："快速创建"
     - 描述："直接输入需求，跳过清理，立即开始构建 Agent。适合需求明确的场景。"
   - **引导创建**（右侧卡片）：
     - 图标：💬（蓝色）
     - 标题："引导创建"
     - 描述："AI 会分析需求中的模糊点，通过几轮问答帮你完善需求，生成更精确的 Agent。"
5. 点击「引导创建」后进入引导向导（未完成交互，避免触发构建）

### 截图
- `shots/02/02-15-agents-new-loaded.png` - /agents/new 页面水合后显示两种创建模式
- `shots/02/02-16-agents-new-guided-wizard.png` - 点击引导创建后的向导界面（未填写）

### 边界/发现
- ✅ **页面不再空白**：使用正确等待后，页面显示完整的模式选择卡片
- **两种创建模式**：快速创建（直接构建）vs 引导创建（问答澄清）
- 引导创建向导 UI 已可见，但未深入测试字段/问题流程（避免触发新构建）

---

## 功能4：项目构建进度页 (/projects/:id)

### 入口
- 快速创建 Agent 后自动跳转
- 首页 "构建进度" 区域点击项目卡片
- URL: https://d3sx15z6kvxyn3.cloudfront.net/projects/proj_3cfac66211ba

### 步骤
1. 提交 Agent 创建后，系统自动跳转至项目详情页
2. **等待水合**：`wait --load networkidle && wait 8000`
3. 页面标题："中英互译助手"
4. 顶部操作栏：
   - "返回" 按钮
   - "暂停" 按钮
   - "删除" 按钮（红色）
5. 统计卡片：
   - 总耗时：12分41秒
   - 输入 Tokens：9.5K
   - 输出 Tokens：6.7K
   - 工具调用：1
6. **构建阶段时间轴**（纵向流程图）：
   - ✅ 意图识别（已完成，7秒，7.7K/409 tokens，1次调用）
   - ✅ 需求深度分析（已完成，12分34秒，1.9K/6.3K tokens）
   - 🔄 系统架构设计（运行中）
   - ⏳ Agent 部署（等待中）
7. 每个阶段卡片显示：序号、阶段名称、状态标签、耗时、token 消耗

### 截图
- `shots/02/02-21-project-detail-stages.png` - 项目详情页阶段时间轴（构建中状态）

### 边界/发现
- ✅ **页面不再空白**：使用正确等待后，页面显示完整的阶段时间轴和统计信息
- **实时构建追踪**：可查看各阶段状态（已完成/运行中/等待中）、耗时、token 消耗
- **项目 ID 可追踪**：proj_3cfac66211ba（供后续批次使用）
- 未测试：点击阶段查看详细日志、暂停/恢复构建、删除项目

---

## 功能5：Agent 详情页 (概览/对话/文件)

### 入口
- Agent 列表点击卡片
- 首页 "运行中 Agent" 点击卡片
- URL: https://d3sx15z6kvxyn3.cloudfront.net/agents/<agent_id>

### 步骤
1. 从列表页点击任意 Agent 卡片（如 "中英互译助手"）
2. **等待水合**：`wait --load networkidle && wait 5000`
3. 页面加载后显示 Agent 详情（具体内容见截图 02-26）
4. 预期包含：
   - 概览 tab：Agent 描述、版本信息、统计数据
   - 对话 tab：直接与该 Agent 对话
   - 文件 tab：Agent 源码/配置文件
   - 导出功能：下载 Agent 包

### 截图
- `shots/02/02-18-agent-detail-overview.png` - Agent 详情概览 tab（浏览器自动导航后）
- `shots/02/02-19-agent-detail-chat-tab.png` - 对话 tab（点击后）
- `shots/02/02-20-agent-detail-files-tab.png` - 文件 tab（点击后）
- `shots/02/02-26-probe-agent-detail.png` - 探测 Agent 详情页（额外验证）

### 边界/发现
- ✅ **详情页可访问**：列表页有数据后，可点击进入详情页
- **tab 切换未完整验证**：浏览器 click 命令未找到 tab 文字（可能需要更精确的选择器）
- 未验证：版本切换、导出功能、文件下载

---

## 功能6：独立聊天页 (/chat)

### 入口
- 侧边栏 "对话" 导航项
- URL: https://d3sx15z6kvxyn3.cloudfront.net/chat

### 步骤
1. 点击侧边栏 "对话"
2. **等待水合**：`wait --load networkidle && wait 8000`
3. 页面标题："会话"，副标题："与 Agent 进行对话交互"
4. **左侧边栏**：
   - 快速启动区域：
     - General As... (General Assistant) - 多功能智能助手
     - Deep Rese... (Deep Research) - 基于互联网的深度研究
     - Data Analy... (Data Analyzer) - 专业数据分析师
     - Content Cr... (Content Creator) - 专业内容创作
   - "选择 Agent" 下拉选择器（Agent / APP 双标签）
   - "会话列表" 标题（可展开）
   - 底部提示："请先选择一个 Agent"
5. **主体区域**：
   - 中央空状态：图标 + "选择 Agent" 标题 + "从左侧选择一个 Agent 开始对话" 提示
6. **右侧抽屉**（折叠状态）：
   - "AGENT 配置" 标题
   - 系统 Prompt / 代码目录 / 工具目录 / 说明 / 标签（均显示 "请选择 Agent"）

### 步骤（补测：完整对话链路，2026-07-12 复核实测）

7. 点击快速启动卡片 "General Assistant" → 左栏出现该 agent 的 "会话列表"，主区提示 "选择或创建会话" + "创建新会话" 按钮
8. 点击 "创建新会话" → 会话列表出现 "会话 2026/7/12 15:08:09 刚刚"（自动以时间命名），旁有 "删除会话" 按钮；主区变为对话界面，空态文案 "开始与 general assistant 对话吧"
9. 对话界面顶部工具条按钮（文案原文）："Nexus Bridge"、"Lifecycle 任务"、"动态配置"、"文件管理"、"清空对话并重建 Agent"、"收藏"、"全屏沉浸模式"
10. 底部输入区：textbox "输入消息..."、"Attach files (or paste screenshot)" 附件按钮、"技能蒸馏"（disabled）、"压缩上下文"、模型选择器（显示 "Sonnet 4.6"）、发送按钮 "Shift+Enter 发送"（空输入时 disabled）
11. 填入 "你好，简单介绍一下你自己" → 发送按钮解除禁用。**注意：Enter 不发送（换行），必须 Shift+Enter 或点按钮**
12. Shift+Enter 发送 → 用户消息立即上屏；发送按钮原位变为 **"停止生成"** 按钮（流式期间可中断）；回复以 SSE 流式渐进渲染（markdown 实时排版，含表格）
13. 约 15-20s 回复完成："停止生成" 恢复为 "Shift+Enter 发送"（disabled）；回复含加粗、标题（"我能帮你做什么？"）、能力表格等富文本
14. "文件管理" 面板：目录树 + "附件 0" / "工作空间 0" 两个分区（空态 "暂无" / "暂无文件"），提示 "选择文件进行预览 从右侧目录树中点击文件"

### 截图
- `shots/02/02-22-chat-page-loaded.png` - /chat 页面水合后初始状态（未选 Agent）
- `shots/02/02-27-chat-input-filled.png` - 选中 Agent + 新会话 + 输入消息后（发送前）
- `shots/02/02-28-chat-streaming.png` - 流式响应进行中（"停止生成" 按钮可见）
- `shots/02/02-29-chat-reply-done.png` - 回复完成（富文本渲染 + 发送按钮恢复）

### 边界/发现
- ✅ **页面不再空白**：使用正确等待后，页面显示完整的三栏布局和 4 个快速启动 Agent
- ✅ **对话链路已实测**：选 Agent → 建会话 → 发消息 → SSE 流式 → 停止生成按钮 → 完成，全链路正常
- **发送快捷键是 Shift+Enter**（按钮文案即提示），Enter 仅换行——与多数 IM 习惯相反，手册须明示
- 会话自动以创建时间命名；删除会话按钮就在会话条目上（是否有二次确认待后续复核）
- Agent/APP 双标签选择器：APP 标签用于与已发布应用对话（应用中心联动），A5 批次覆盖
- 未验证项（留待需要时）：附件上传、压缩上下文、技能蒸馏、清空对话并重建、多会话切换保持

---

## 功能7：Agent 对话页 (/agents/dialog)

### 入口
- 直接 URL 访问
- URL: https://d3sx15z6kvxyn3.cloudfront.net/agents/dialog

### 步骤
1. 直接访问 URL /agents/dialog
2. **等待水合**：`wait --load networkidle && wait 8000`
3. **页面正常加载**，显示：
   - 页面标题："AGENT 列表" (左上角)
   - 副标题："暂无可用 Agent。"
   - 左侧边栏："会话列表" 标题，"新建会话" 和 "刷新" 按钮
   - 左下角："请选择一个 Agent 以查看对应会话。" 提示
   - 中央主体：模态对话框
     - 标题："请选择 Agent"
     - 副标题："从左侧列表中拉框选择一个 Agent 开始对话。"
     - 下拉选择器："暂无可用 Agent"
     - 描述："从左侧列表拉框下拉框选择 Agent 即可开启一段新对话。"
   - 右侧边栏："AGENT 配置" 标题（系统 Prompt / 代码目录 / 工具目录 / 说明 / 标签，均显示 "请选择 Agent 以查看配置详情。"）
   - 底部输入框："请选择左侧 Agent 后开始对话。"，"快捷提示" 和 "发送" 按钮（禁用状态）

### 截图
- `shots/02/02-25-agents-dialog-hydrated.png` - /agents/dialog 水合后正常状态（非异常）

### 边界/发现
- ✅ **不再抛出异常**：使用正确等待后，页面正常加载（F006 已解决，是水合问题）
- **多 Agent 协作对话页面**：与 /chat 类似布局，但聚焦多 Agent 协作场景（"AGENT 列表" 标题暗示可选多个）
- **当前无可用 Agent**：下拉显示 "暂无可用 Agent"（可能需要特定设置或数据）
- 未验证：选择多个 Agent、协作对话流程、Agent 间交互

---

## 功能8：交互网络页 (/agents/network)

### 入口
- Agent 列表页顶部 "交互网络" 按钮
- URL: https://d3sx15z6kvxyn3.cloudfront.net/agents/network

### 步骤
1. 点击 "交互网络" 按钮进入
2. 页面标题："交互网络"，副标题："可视化展示Agent、工具之间的调用关系和依赖网络"
3. 左上角 "返回Agent列表" 按钮
4. 筛选栏：
   - 搜索节点框："搜索节点..."
   - "分类" 下拉：全部
   - "标签" 下拉：全部
   - "工具类型" 下拉：全部
   - 复选框："显示工具"（已勾选）、"显示版本"（已勾选）
5. 主画布显示 "加载中..."
6. 右侧面板：
   - **图统计**：0 Agent、0 版本、0 工具、0 关系
   - **节点详情**："点击节点查看详情"（灰色提示）
   - **图例**：
     - 🤖 Agent（紫色）
     - 📦 Version（橙色）
     - 🔧 Tool（绿色）
     - 📂 Tool Group（青色）
     - 关系类型：Uses Tool（灰线）、Has Version（紫线）、Calls Agent（橙线）、Belongs To（青线）、Agent as Tool（红线）
7. 画布控制：缩放入/缩放出、适配窗口、重置视图 按钮（右下角）

### 截图
- `shots/02/02-agents-network.png` - 交互网络页面全貌（历史截图）

### 边界/发现
- **页面正常加载**：此页面功能完整，无空白或崩溃
- **无数据可视化**：当前环境图统计显示 0（可能需要 Agent 间调用关系数据）
- **功能完备性**：筛选、图例、统计面板齐全，后续有数据后可验证图谱交互

---

## 总结

### 水合问题修复
- **根本原因**：CloudFront SPA 冷加载 JS/CSS 后，React 水合（hydration）需 5-10 秒
- **修复方法**：所有页面必须 `wait --load networkidle && wait 8000` 后再截图/交互
- **受影响页面**：/agents/new、/projects/:id、/chat、/agents/dialog（均从"空白"变为正常）

### 已验证功能
1. ✅ **Agent 列表页** (/agents)：布局、筛选、排序、7个Agent卡片显示正常
2. ✅ **快速创建 Agent** (首页)：入口清晰，提交成功并跳转项目详情页
3. ✅ **引导创建 Agent** (/agents/new)：两种模式选择（快速/引导），向导 UI 可见
4. ✅ **项目构建进度页** (/projects/:id)：阶段时间轴、统计卡片、实时状态显示完整
5. ✅ **Agent 详情页**：可访问，tab 结构可见（未完整交互）
6. ✅ **独立聊天页** (/chat)：三栏布局、4个快速启动Agent、空状态提示正常
7. ✅ **Agent 对话页** (/agents/dialog)：多 Agent 协作页面正常加载（非异常）
8. ✅ **交互网络页** (/agents/network)：功能完整（无数据显示空状态）

### 残留问题
- **浏览器交互限制**：agent-browser click 命令在复杂组件中选择器失败，未能完成：
  - Agent 详情页 tab 切换（概览/对话/文件）
  - /chat 页面选择 Agent 并发送消息
  - 引导创建完整流程
- **数据状态**：部分页面功能依赖特定数据（如 /agents/dialog 的多 Agent、/agents/network 的调用关系）

### 成功创建的 Agent 信息
- **项目 ID**: proj_3cfac66211ba
- **名称**: 中英互译助手
- **需求**: 创建一个中英互译助手：输入中文输出英文，输入英文输出中文，保持原文语气
- **状态**: 构建中（系统架构设计阶段，截图时）
- **供后续批次使用**：A5（项目详情/阶段时间轴）可使用此项目验证完整构建流程

### 截图清单（25张，含新增11张）
**历史截图（保留）**：
1. `02-agents-list-page.png` - Agent 列表页
2. `02-agents-list-loaded.png` - 列表加载后
3. `02-agents-list-after-create.png` - 创建后返回列表
4. `02-home-create-section.png` - 首页创建卡片
5. `02-create-text-filled.png` - 填写需求
6. `02-create-after-submit.png` - 提交后（水合前空白）
7. `02-home-running-agents.png` - 首页构建进度
8. `02-project-building.png` - 项目页面（水合前空白）
9. `02-agents-new-page.png` - /agents/new（水合前空白）
10. `02-agents-create-quick.png` - 点击创建链接后（水合前空白）
11. `02-chat-page.png` - /chat（水合前空白）
12. `02-agents-dialog.png` - /agents/dialog（水合前异常）
13. `02-agents-network.png` - 交互网络页面
14. `02-create-modal.png` - 提交后空白页面（重复）

**新增截图（修复后）**：
15. `02-15-agents-new-loaded.png` - /agents/new 水合后两种创建模式
16. `02-16-agents-new-guided-wizard.png` - 引导创建向导界面
17. `02-17-agents-list-hydrated.png` - 列表页水合后真实数据（7个Agent）
18. `02-18-agent-detail-overview.png` - Agent 详情概览 tab
19. `02-19-agent-detail-chat-tab.png` - Agent 详情对话 tab
20. `02-20-agent-detail-files-tab.png` - Agent 详情文件 tab
21. `02-21-project-detail-stages.png` - 项目详情页阶段时间轴
22. `02-22-chat-page-loaded.png` - /chat 页面水合后初始状态
23. `02-23-chat-streaming.png` - /chat 流式响应中（未成功触发，被 27-29 取代）
24. `02-24-chat-finished.png` - /chat 对话完成状态（未成功触发，被 27-29 取代）
25. `02-25-agents-dialog-hydrated.png` - /agents/dialog 水合后正常状态
26. `02-26-probe-agent-detail.png` - 探测 Agent 详情页

**补测截图（对话链路实测）**：
27. `02-27-chat-input-filled.png` - 选中 Agent + 新会话 + 消息已输入（发送前）
28. `02-28-chat-streaming.png` - SSE 流式响应中（"停止生成" 按钮可见）
29. `02-29-chat-reply-done.png` - 回复完成（富文本渲染 + 发送按钮恢复 disabled）
