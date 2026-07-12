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

### 入口
- 从 **工具** 页面点击 **构建工具** 按钮
- 或从侧边栏 **工坊** → `/projects` → 点击 **Tool 构建独立工具** 卡片

### 步骤
1. 点击 **构建工具** 按钮后未出现 dialog/modal(已验证 DOM 中无 `[role="dialog"]`)
2. 尝试直接访问 `/workshop/build?type=tool` → 404
3. 尝试直接访问 `/workshop` → 404 (但从侧边栏点击"工坊"实际跳转到 `/projects`)
4. 从 `/projects` 页面点击 **Tool 构建独立工具** 卡片 → 同样未出现 dialog
5. 尝试通过 ⌘K 搜索"构建工具" → 无结果
6. 成功路径: 访问 `/projects` → 页面显示 **工坊** 标题，顶部有四个卡片:
   - **Agent 构建智能 Agent**
   - **Skill 构建可复用 Skill**
   - **Tool 构建独立工具**
   - **App 构建可发布应用**
7. 点击 **Tool 构建独立工具** 卡片后仍未触发 form/dialog(已 wait 3s + networkidle)
8. 查看已有 Tool 项目 **文生图集成工具** 的详情页(成功进入项目详情页，显示需求/stages/status)，确认 Tool build workflow 确实存在并能完成

### 截图
- `04-ability-tools-build-form.png` — 点击"构建工具"按钮后的页面(仍显示工具列表，无 form)
- `04-projects-page.png` / `04-workshop-page.png` — `/workshop` 404 页面
- `04-projects-workshop.png` — `/projects` 工坊页面，显示四个构建类型卡片
- `04-tool-build-dialog.png` / `04-tool-build-scrolled.png` — 点击 Tool 卡片后页面(无 dialog 出现)
- `04-tool-build-create-page.png` — 尝试访问 `/projects/create?type=tool` → "项目不存在"
- `04-tool-project-detail.png` — 已有 Tool 项目 **文生图集成工具** 的详情页
- `04-tasks-panel.png` / `04-new-task-dialog.png` — 任务面板的自然语言任务创建 dialog(NL描述 → 开始分析，非Tool build专用入口)

### 边界/发现
- **F012**: Tool build 入口点击后未触发表单/对话框，无法在UI中直接提交工具构建需求。尝试了多种路径(构建工具按钮、Tool卡片、URL直达、cmdk搜索)均未成功打开Tool build form。但从已有项目 **文生图集成工具** 可确认 tool_build workflow 确实在后端运行且能完成(5 stages, 8m, 250K tokens)。推测: 要么Tool build入口尚未完整实现前端form，要么走的是其他非modal路径(如任务面板的自然语言创建，但任务面板偏向event scheduling，非专门的build workflow)。

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
