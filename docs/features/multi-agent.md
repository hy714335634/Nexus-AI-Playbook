---
title: 多 Agent 图/群
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - agents/system_agents/**
    - nexus_utils/agent_graph/**
  generated_at: 2026-05-08T15:45:01+00:00
  generated_by: docs-sync v2
---

# 多 Agent 图/群

## 这是什么

多 Agent 图/群让你用一张网络图看清"谁调用谁、谁在用哪个工具"，同时让多个专家 Agent 像小组一样接力完成同一件事。它由两部分组成：

- **Agent 图**：把平台里所有 Agent、它们的版本、所依赖的工具、以及 Agent 之间的调用关系（Agent-as-Tool）绘制成一张可交互网络图。
- **Agent 群（Swarm）**：一组预先编排好的专家 Agent，按任务分工顺序协作并统一交付结果。Nexus-AI 内置了 Agent 构建、Agent 更新、工具构建、通用助手、Magician 智能路由、多模态分析、组织构建、指令构建等多条开箱即用的 Agent 群。

## 使用场景

| 场景 | 用哪个能力 |
|------|-----------|
| 想看自己工作空间里有哪些 Agent，它们共用了哪些工具 | 打开 Agent 图，按分类/标签/工具类型筛选 |
| 删除一个工具前想确认「还有谁在用它」 | 在 Agent 图中点击工具节点，右侧弹出"被哪些 Agent 使用" |
| 一句话描述需求，让一组专家 Agent 协作完成 | 从 Magician 入口提问，自动路由到对应 Agent 群 |
| 用自然语言一次性搭起公司/部门组织树 | 组织构建 Agent 群（Org Builder） |
| 把一份 SOP 文档直接转成可执行的 Agent 指令 | 指令构建 Agent 群（Directive Builder） |
| 让一个"主 Agent"把若干"子 Agent"当工具调用 | Agent-as-Tool 组合 |

## 如何使用

### 1. 打开 Agent 图

进入「Agent 图」页面（或在 Agent 列表右上角点击 `以图查看`），平台会把所有已登记的 Agent、版本节点、工具节点以及它们之间的关系加载为一张力导向网络图。

<!-- SCREENSHOT: agent-graph-overview -->

你可以看到四类节点和五类边：

| 节点类型 | 颜色 | 含义 |
|---------|------|------|
| Agent | 紫色 | 一个 Agent 的主节点 |
| Agent 版本 | 浅紫色 | 同一 Agent 的不同版本 |
| 工具 | 按工具类型区分（蓝/绿/黄/紫/粉） | 单个工具 |
| 工具组 | 青色 | 工具所属的组（如 `strands_tools`、`mcp`） |

| 边类型 | 颜色 | 含义 |
|-------|------|------|
| 使用工具 | 灰色 | Agent 版本 → 工具 |
| 有版本 | 浅紫色 | Agent → Agent 版本 |
| 调用 Agent | 橙色 | Agent A 把 Agent B 当作工具调用（Agent-as-Tool） |
| 属于组 | 青色 | 工具 → 工具组 |
| Agent 被封装为工具 | 红色 | Agent 对外以工具形式暴露 |

### 2. 筛选和搜索

顶部工具条可按以下维度过滤：

- **分类**（category）：Agent 的业务分类
- **标签**（tags）：Agent 版本携带的标签
- **工具类型**：`strands_tools` / `generated_tools` / `system_tools` / `template_tools` / `mcp`

<!-- SCREENSHOT: agent-graph-filters -->

### 3. 查看节点详情

点击任意节点，右侧面板显示：

- **Agent 节点**：描述、分类、所含版本数量、工具数量、相关边（谁调用它、它调用谁）
- **版本节点**：版本号、状态、作者、创建日期、标签、支持的模型、工具依赖
- **工具节点**：工具路径、工具类型、被哪些 Agent 使用

### 4. 让多个 Agent 协同完成任务（Agent 群）

Nexus-AI 把常见的复杂任务封装成 Agent 群，你只需要从对应入口提一句需求，群内的专家 Agent 会顺序接力完成：

| Agent 群 | 专家角色（按顺序） | 典型触发入口 |
|---------|----------------|-------------|
| 构建 Agent | 意图识别 → orchestrator → requirements_analyzer → system_architect → agent_designer → tool_developer → prompt_engineer → agent_code_developer → agent_developer_manager → agent_deployer | 「创建 Agent」页面 |
| 更新 Agent | update_orchestrator → requirements_update → tool_update → prompt_update → code_update | Agent 详情页「更新」 |
| 构建工具 | orchestrator → requirements_analyzer → tool_designer → tool_developer → tool_validator → tool_documenter | 「创建工具」页面 |
| 通用助手 | 单 Agent 全能对话（知识问答、计算、搜索、文件、AWS 云服务） | 主聊天入口 |
| Magician 智能路由 | 根据你的输入选择合适的模板或临时组装 Agent 群 | 主聊天入口，不指定 Agent |
| 多模态分析 | 处理图片、文档、文本等混合输入 | 上传文件后的分析入口 |
| 组织构建 | 从自然语言描述批量创建组织与部门节点 | 「组织管理 → 一键生成」 |
| 指令构建 | 从 Markdown / SOP 文档提取目标、约束与步骤，生成 Agent 指令 | 「指令库 → 从文档导入」 |

<!-- SCREENSHOT: multi-agent-swarm-build -->

::: tip 什么是 Agent-as-Tool
一个 Agent 可以把另一个 Agent 当作工具来调用——这是"群"的最小单元。你在 Agent 图里看到的**橙色连线**就是这种调用关系。Magician 和多条构建/更新工作流内部都使用这种组合。
:::

### 5. 从自然语言建立组织树

<!-- SCREENSHOT: org-builder -->

1. 在「组织管理」中选择「从描述生成」。
2. 粘贴一段自然语言描述，例如：

   ```
   某科技公司
     研发中心
       前端组
       后端组
     市场部
   ```

3. 点击「预览」：Agent 群解析层级并返回一棵候选组织树（仅预览，不落库）。
4. 确认无误后点击「创建」，批量落库并自动维护父子关系。

### 6. 从文档一键生成 Agent 指令

<!-- SCREENSHOT: directive-builder -->

1. 进入「指令库」，选择「从文档导入」。
2. 粘贴一份 Markdown 或纯文本 SOP。
3. 提交后 Agent 会判断该走 `guided`（软性建议）还是 `strict`（强约束步骤）模式，自动抽取目标、约束、步骤、检查点、质量标准。
4. 如果描述中提到某个部门名，系统会自动把新指令挂到该部门下；否则会让你手动选择父节点。

### 7. 从断点恢复一条 Agent 群工作流

构建/更新工作流在中途失败时，可以在项目详情页选择「从某阶段恢复」。平台会跳过已完成阶段，只从指定阶段开始继续执行；阶段状态由 Stage Tracker 持久化，关闭浏览器也不会丢。

## 关键参数 / 限制

| 项目 | 取值 / 说明 |
|------|------------|
| Agent 图节点类型 | `agent`、`agent_version`、`tool`、`tool_group` |
| Agent 图边类型 | `uses_tool`、`has_version`、`calls_agent`、`belongs_to`、`agent_as_tool` |
| 工具类型颜色 | `strands_tools`（蓝）、`generated_tools`（绿）、`system_tools`（黄）、`template_tools`（紫）、`mcp`（粉） |
| 图数据来源 | 读取 `prompts/generated_agents_prompts/` 下每个 Agent 的 YAML 元数据；没有 YAML 的 Agent 不会出现在图里 |
| Agent-as-Tool 识别规则 | 工具路径包含 `agent_tool` 或 `agent_as_tool` 关键字时，被识别为 Agent 间调用，不会再创建独立工具节点 |
| 构建 Agent 群阶段数 | 9（意图识别 + 8 个接力阶段，顺序执行，不可跳步） |
| 更新 Agent 群阶段数 | 5（顺序执行） |
| 工具构建群阶段数 | 6（顺序执行） |
| 断点恢复 | 构建工作流支持从任意指定阶段恢复；更新与工具构建流需按顺序重新执行 |
| Session 管理 | 每次启动生成 `session_id`，群内 Agent 共享同一 session；可手动指定以恢复旧会话 |
| 项目名称约束 | 启动时若指定了项目名称，后续 Agent 必须沿用，不会自行改名 |
| 组织构建输入上限 | 单次描述最多约 8 000 字符 |
| 指令构建输入上限 | 单份文档最多约 10 000 字符 |

::: warning 关于"跳过阶段"
构建、更新、工具构建三条工作流都是严格顺序执行的流水线，不能并行也不能跳过中间阶段。如果某阶段失败，修复后只能选择**从该阶段重跑**或**从后一阶段继续**（前提是前面的产出仍然有效）。
:::

## 常见问题

**Q：Agent 图里看不到我新建的 Agent？**
A：Agent 在「部署」阶段完成后才会写入提示词目录，图数据读取的是这些 YAML。构建工作流没跑到部署阶段时，图上暂时不会出现；部署完成后刷新页面即可。

**Q：同一个 Agent 的多个版本，图上怎么区分？**
A：主节点（紫色）下挂多个版本节点（浅紫色），两者通过"有版本"边连接。你可以只勾选某个版本，仅展示它绑定的工具与调用关系。

**Q：Agent 群里某个专家 Agent 失败了，前面的产出会白费吗？**
A：不会。所有已完成阶段的产物都保存在项目上下文中。你可以从失败的阶段重跑，前置阶段不会重复执行。

**Q：Magician 是怎么决定调哪几个 Agent 的？**
A：Magician 先读取模板库和已生成 Agent 列表，再根据你输入的语义匹配最合适的单个 Agent 或临时组装一个 Agent 群。你也可以直接指定模板路径跳过路由。

**Q：Agent 群之间会不会相互污染上下文？**
A：不会。每次启动会生成独立的 `session_id`，群内 Agent 共享同一 session，群与群之间不共享。断点恢复时沿用同一个 `session_id`。

**Q：我想让某个 Agent 调用另一个 Agent，该怎么做？**
A：在调用方 Agent 的工具依赖里引用目标 Agent（使用 Agent-as-Tool 形式），Agent 图会立刻在二者之间画出一条橙色"calls"边，方便你核对。
