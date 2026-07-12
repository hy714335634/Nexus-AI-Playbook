---
env: d3sx15z6kvxyn3
date: 2026-07-12
batch: 4
routes_covered:
  - /ability/tools
  - /ability/mcp
  - /ability/skills
  - /integration (资产模版/数据连接/密钥管理/业务指示)
  - /projects (工坊, Tool项目列表)
---

# Batch 4: 能力中心 + 集成

本批次走查能力中心的三个子页面(工具/MCP/技能)及业务集成的四个标签页。

---

## 功能: 工具列表与管理

### 入口
- 从侧边栏 **能力中心** → 点击"工具"卡片的"进入管理"
- 或直接访问 `/ability/tools`

### 步骤
1. 页面标题 **能力工具**，顶部导航 tabs: **工具** / 技能 / MCP 服务
2. 右上角按钮:
   - **导入工具 NEW**
   - **构建工具**
3. 主区域显示 **工具列表**:
   - 搜索框: "搜索工具..."
   - 过滤按钮: **全部** / 内置工具 / 生成工具 / 系统工具 / 模板工具 / 导入工具
   - 下拉菜单: **全部分类** (包含 AWS Services / Agents & Workflows / Browser Automation / Code Interpretation / File Operations / Generated Tools / Imported Tools / MCP Tools / Multi-modal / RAG & Memory / Shell & System / System Tools / Template Tools / Utilities / Web & Network)
4. 工具以卡片形式呈现，每个卡片显示: 工具名称 + 简短描述
   - 可见工具包括: agent_graph, calculator, cron, current_time, editor, environment, file_read, file_write, generate_image, http_request, image_reader, journal, load_tool, mem0_memory, memory, nexus_browser_act, nexus_browser_navigate, nexus_browser_observe, nova_reels, python_repl, retrieve, shell, slack, speak, stop, swarm, think, use_aws, use_llm, wait_for_human, workflow 等内置工具，以及大量系统/生成/模板工具
5. 工具总数显示: **255 个工具 内置31 导入0**

### 截图
- `04-ability-tools-list.png` — 工具列表首页
- `04-ability-tools-management.png` — 工具管理页(与上同页面，更完整视图)
- `04-ability-tools-detail.png` / `04-ability-tools-detail-scrolled.png` / `04-ability-tools-detail-panel.png` — 尝试查看工具详情(但UI未呈现detail panel，工具卡片点击后无明显响应)

### 边界/发现
- **F011**: 工具卡片点击后未出现 detail panel 或 drawer，无法直接查看工具源码/密钥状态/绑定信息。尝试点击 `current_time` 工具卡片后页面无视觉变化，DOM中未检测到 `[role="dialog"]` 或 drawer 元素。(WAIT 策略已严格执行 8s + networkidle)

---

## 功能: 工具构建入口

（2026-07-12 复核实测：入口可用，初次走查未见弹窗系检测方式误判——见 F012 修订）

### 入口
- **工具** 页面（/ability/tools）右上 **「构建工具」** 按钮 → 弹出 "工具构建" 弹窗（确认可用）
- 侧边栏 **工坊** → `/projects` 顶部 **Tool 构建独立工具** 卡片（待复核，推测同弹窗）

### 步骤（复核实测成功路径）
1. /ability/tools 点击 **「构建工具」** → 弹出居中弹窗（容器是 `div.fixed.inset-0 z-[1000]`，**无 `role="dialog"` 属性**——初次走查用 `[role="dialog"]` 检测因此漏判）
2. 弹窗结构（文案原文）：标题 "工具构建"；字段 "工具需求描述 *"（textarea，placeholder "例如：构建一个网页抓取工具，能从任意 URL 提取文本和链接，支持代理和限速..."）；"工具名称（可选）"（input，placeholder "e.g., web_scraper"）；按钮 "取消" / "开始构建"
3. 实测提交：需求填 「创建一个获取当前 UTC 时间和指定时区当前时间的工具，输入时区名称（如 Asia/Shanghai），返回该时区的当前日期时间字符串」，名称留空 → 点 "开始构建"
4. 提交后**立即跳转**到新建项目详情页 `/projects/proj_edbf3425dc23`，走 tool_build 工作流阶段时间轴（与 agent 构建同一 UI 体系）
5. 历史样本佐证：已有 Tool 项目 **文生图集成工具**（5 stages, 8m, 250K tokens）完整跑完过该工作流

### 截图
- `04-21-tool-build-dialog.png` — "工具构建" 弹窗（空表单）
- `04-22-tool-build-filled.png` — 需求已填写
- `04-23-tool-build-submitted.png` — 提交后跳转项目详情页（proj_edbf3425dc23）
- `04-ability-tools-build-form.png` — （初次走查存档：点击后截图时机过早，弹窗未捕捉到）
- `04-projects-workshop.png` — `/projects` 工坊页四个构建类型卡片
- `04-tool-project-detail.png` — 历史 Tool 项目 **文生图集成工具** 详情页

### 边界/发现
- ✅ **F012 修订：入口可用**。初次误判两个原因：a) 弹窗容器无 `role="dialog"`，DOM 探测选择器不匹配；b) agent-browser 常规 click 对该 React 按钮偶发不触发，`eval` 直点 DOM 可靠
- 弹窗无遮罩点击关闭确认（未测 ESC）；"开始构建" 无需求文本时的禁用态未记录（下次补）
- 提交即跳项目详情——工具构建复用 /projects 的统一项目管理与阶段时间轴
- **可访问性问题（保留为产品建议）**：构建弹窗缺 `role="dialog"` 语义，屏幕阅读器/自动化不可发现
- probe 工具构建项目：`proj_edbf3425dc23`（异步构建中，A9 收尾时回查最终状态；Demo② 素材可用）

---

## 功能: MCP 服务器管理

### 入口
- 从侧边栏 **能力中心** → 点击"MCP 服务"卡片的"进入管理"
- 或直接访问 `/ability/mcp`

### 步骤
1. 页面标题 **MCP 服务器管理**，顶部导航 tabs: 工具 / 技能 / **MCP 服务**
2. 右上角按钮:
   - **导入配置**
   - **添加服务器**
3. 主区域显示服务器列表:
   - 搜索框: "搜索服务器名称、命令、URL..."
   - 下拉菜单: **全部作用域** (共享 / 私有)
   - Tab: **STDIO 6 个服务**
4. 显示的 MCP 服务器(6个):
   - **strands-agents** (已启用)
   - **awslabs.aws-api-mcp-server** (已启用)
   - **awslabs.aws-pricing-mcp-server** (已启用)
   - **awslabs.core-mcp-server** (已启用)
   - **disabled-server** (已禁用)
   - **test-server** (已禁用)
5. 每个服务器卡片显示: 名称 + 操作按钮(测试连接 / 查看工具 / 编辑 / 启用或禁用 / 删除)
6. 点击 **添加服务器** 打开 dialog:
   - 标题: **添加 MCP 服务器**
   - 双 tab: **手动填写** / 粘贴配置
   - 表单字段(手动填写模式):
     - **服务器名称 *** (textbox, placeholder "例如: aws-docs")
     - **传输类型** (三选一按钮: **STDIO** / SSE / HTTP)
     - **命令 *** (textbox, placeholder "uvx, npx, python")
     - **参数** (textbox, placeholder "awslabs.aws-documentation-mcp-server@latest", 说明"多个参数用空格分隔")
     - **环境变量（可选）** (动态添加 KEY/value 对，按钮 **+ 添加环境变量**)
     - **描述** (textbox, placeholder "服务器功能描述...")
     - **作用域** (二选一按钮: **共享** / 私有)
   - 底部按钮: **取消** / **添加服务器**(disabled, 需填必填项)

### 截图
- `04-ability-mcp.png` — MCP 服务器列表
- `04-mcp-add-server-form.png` — 添加服务器 form (手动填写 tab)

### 边界/发现
- 无异常。添加服务器 form 已记录完整字段，按要求未实际提交。

---

## 功能: Skills 管理

### 入口
- 从侧边栏 **能力中心** → 点击"技能"卡片的"进入管理"
- 或直接访问 `/ability/skills`

### 步骤
1. 页面标题 **Skills 管理**，顶部导航 tabs: 工具 / **技能** / MCP 服务
2. 右上角按钮:
   - **刷新**
   - **导入 Skill**
   - **组合**
   - **Skills 构建**
3. 主区域显示 Skill 分组:
   - 搜索框: "搜索 Skill..."
   - 视图切换: **分组** / 平铺
4. 显示的 Skill 分组(5个):
   - **Community Skills** (18 个技能, Local community skills from skills/community_skills, 手动)
   - **System Skills** (2 个技能, Local system skills from skills/system_skills, 手动)
   - **Private Skills** (0 个技能, Local private skills from skills/private_skills, 手动)
   - **Generated Skills** (2 个技能, Local generated skills from skills/generated_skills, 手动)
   - **dptech-corp/bohrium-skills/zh** (17 个技能, Batch imported from GitHub, GitHub)
5. 点击分组右侧的展开图标(▼)可展开查看分组内的 Skill 列表(展开后显示每个 Skill 的卡片: 名称 + 版本 + 简短描述)
6. 可见 Skills 包括: xlsx, skill-creator, pptx, pdf, docx 等(Community Skills 内)
7. 点击某个 Skill(如 **skill-creator**)进入 Skill 详情页:
   - 页面标题: **skill-creator**
   - 左侧面包屑: 能力中心 / 工具 / **技能** / MCP 服务
   - 右上角按钮: **返回** / 分享 / 更多操作
   - Tab 导航: **Skill 详情** / Files (17) / 工具 / Evals / Settings
   - Skill 详情 tab 显示完整的 SKILL.md 内容(Markdown渲染，包含多级标题、代码块、表格等)
   - Files tab 显示 Skill 的文件列表(17个文件)

### 截图
- `04-ability-skills.png` — Skills 管理页(分组视图)
- `04-skills-expanded.png` / `04-skills-list-expanded.png` — Community Skills 分组展开后的 Skill 列表
- `04-skill-detail.png` — skill-creator Skill 详情页(显示 SKILL.md 内容 + Files tab)

### 边界/发现
- **F013**: 点击 Community Skills 分组的展开图标(generic clickable element with onclick)时，首次点击触发了"确认删除"对话框(标题 **确认删除**，按钮: 仅删除分组(保留 Skills) / 删除分组及全部 Skills / 返回)，而非预期的展开行为。点击"返回"关闭对话框后，再次点击分组标题才成功展开Skill列表。UI交互逻辑可能有误: 展开图标(▼)和删除操作的点击区域重叠或误触发。

---

## 功能: 业务集成 — 四个标签页

### 入口
- 从侧边栏 **业务集成** → `/integration`

### 步骤
页面标题 **业务集成**，顶部显示四个卡片式导航(每个卡片可点击进入对应子页面):
1. **资产模版** (0, 暂无集合)
2. **数据连接** (0, 暂无连接)
3. **密钥管理** (2, 2 个已绑定)
4. **业务指示** (0, 全局)

点击每个卡片进入对应的管理页面:

---

### 子页面 1: 资产模版

#### 步骤
1. 主区域显示模板资产管理界面:
   - 左侧过滤栏:
     - **全部** / 我创建的 / 共享给我
     - **全部类别** / PPT / Excel / 文档 / HTML / 其他
   - 视图切换: **资产视图** / 集合视图 (0)
2. 中央拖拽上传区域:
   - 提示: "拖拽文件或文件夹到此处上传"
   - 支持格式: PPT / Word / Excel / HTML / PDF / 图片等
   - 两个按钮: **选择文件** / **选择文件夹**
3. 右侧搜索框: "搜索模板(关键词)..."
4. 右上角 **✨ AI** 按钮
5. 当前状态: 无资产(空白中央区域)

#### 截图
- `04-integration.png` / `04-integration-templates.png` — 资产模版页面(空状态)

---

### 子页面 2: 数据连接

#### 步骤
1. 搜索框: "搜索连接器..."
2. 右上角按钮(未明确标识，可能是添加连接器)
3. 当前状态: 无数据连接(空白列表)

#### 截图
- `04-integration-connectors.png` — 数据连接页面(空状态)

---

### 子页面 3: 密钥管理

#### 步骤
1. 搜索框: "搜索密钥..."
2. 右上角按钮: **新建密钥**
3. 显示已绑定的密钥(2个):
   - **dashscope_api_key** (类型: api_key, 1, 描述: "调用阿里云 DashScope MultiModalConversation API 进行文生图，基于通义千问多模态模型（如 qwen-image-2.0-pro）。通过 workspace_id 动...")
   - **ark_api_key** (类型: api_key, 1, 描述: "调用火山引擎 Ark API（/api/v3/images/generations 端点）进行文生图，支持指定端点模型 ID、提示词、图片尺寸、水印、响应格式（url/b64_json）、顺序图片生成...")
4. 每个密钥卡片显示: 名称 / 类型 / 引用次数 / 描述片段

#### 截图
- `04-integration-keys.png` — 密钥管理页面(显示2个已绑定密钥)

---

### 子页面 4: 业务指示 (Directive)

#### 步骤
1. 右上角按钮组:
   - **新建节点**
   - **自然语言创建架构**
   - **从文档导入**
   - **刷新**
2. 右下角浮动按钮:
   - **手动创建**
   - **AI 智能创建**
3. 当前状态: 无业务指示节点(空白画布或列表)

#### 截图
- `04-integration-directives.png` — 业务指示页面(空状态)

---

### 边界/发现
- 业务集成的四个子页面功能清晰，但当前环境中资产模版/数据连接/业务指示均为空(测试数据未准备)。密钥管理有2个实际密钥(dashscope/ark，均为文生图工具所用)，可作为密钥绑定功能的验证样本。

---

## 功能: 工坊 — Tool 项目列表

### 入口
- 从侧边栏 **工坊** → `/projects`

### 步骤
1. 页面标题 **工坊**，左上角四个卡片导航:
   - **Agent 构建智能 Agent**
   - **Skill 构建可复用 Skill**
   - **Tool 构建独立工具**
   - **App 构建可发布应用**
2. 主区域显示项目列表:
   - 搜索框: "搜索项目名称..."
   - 排序下拉: **最近更新** / 最近创建 / 名称 A-Z / 名称 Z-A
   - 类型过滤 tabs: **全部 19** / Agent 8 / Skill 0 / **Tool 1** / App 10
   - 操作类型 tabs: **全部** / 构建 / 更新
   - 状态过滤 tabs: **全部19** / 构建中 1 / 已完成 18 / 失败 0 / 已暂停 0
3. 可见的 Tool 类型项目:
   - **文生图集成工具** (已完成, 5 stages, 8m, 250K tokens, 2天前)
     - 需求: "生成能够集成豆包和阿里云文生图模型的工具，能够指定模型、传输提示词，返回图片内容或者下载链接，我会提供API Key，请你遵从第三方SDK官方文档进行工具开发，..."
4. 点击项目卡片进入项目详情页，显示: 需求描述 / stages 执行记录 / token 消耗 / 产物链接等

### 截图
- `04-projects-workshop.png` — 工坊页面(项目列表，包含1个Tool项目)
- `04-tool-project-detail.png` — 文生图集成工具项目详情页

### 边界/发现
- 已有 Tool 项目 **文生图集成工具** 可证实 tool_build workflow 确实存在且运行正常(5阶段: orchestrator/requirements/design/develop/validate，总耗时8分钟，250K tokens)。但UI上未找到直接提交新 Tool build 的 form 入口(见 F012)。

---

## 小结

本批次走查涵盖:
- **工具管理** (255 tools, 分类/搜索/过滤功能完整)
- **MCP 服务器管理** (6 servers, 添加服务器 form 字段完整)
- **Skills 管理** (5 groups, 39 skills, skill 详情页功能完整)
- **业务集成** 四个子页面(资产模版/数据连接/密钥管理/业务指示，除密钥管理有2条数据外均为空状态)
- **工坊 Tool 项目** (1 个已完成的 tool_build 项目作为功能验证样本)

发现3个边界问题:
- **F011**: 工具卡片点击后无 detail panel
- **F012**: Tool build 入口点击后无 form/dialog，无法在UI直接提交工具构建
- **F013**: Skills 分组展开图标误触发删除对话框

截图共 20 张，已保存至 `shots/04/`。
