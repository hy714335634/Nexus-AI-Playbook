# Nexus-AI Feature Inventory (Code-Side Baseline)

**覆盖情况**: 59/59 页面路由, 44/44 router 文件, 45/45 router 实例 (config.py 导出 2 个)

本表格为 v4 手册功能底账，基于代码侧提取（`web/app/*/page.tsx` + `api/v2/routers/*.py` + 侧边栏/Spotlight/助手组件），供后续走查任务（A3-A8）与章节配置（B1）使用。

---

## 用户可见功能（按路由分组）

| 功能 | 路由 | API routers | v4 章节/slug | 走查任务 |
|---|---|---|---|---|
| **登录与认证** |
| 登录页 | /login | auth | getting-started/first-login | A3 |
| 403 无权限页 | /403 | auth | reference/error-pages | A3 |
| **核心工作台与空间** |
| 仪表盘（统计概览） | / | statistics | using/dashboard | A3 |
| My Home（Avatar 空间） | /home | avatar | using/avatar-space | A3 |
| **Agent 管理与对话** |
| Agent 列表 | /agents | agents | using/manage-agents | A4 |
| 创建 Agent | /agents/new | agents, workflows | using/create-agent | A4 |
| Agent 详情 | /agents/[id] | agents, agent_tools, skills, directives, favorites | using/agent-detail | A4 |
| Agent 文件管理 | /agents/[id]/files | agent_files | using/agent-files | A4 |
| Agent 对话（Agent Chat） | /agents/[id]/chat | sessions, agents, attachments, multimodal, workspace, favorites | using/chat | A4 |
| Agent 关系图谱 | /agents/network | agent_graph | using/agent-network | A4 |
| Agent 对话框（弹窗） | /agents/dialog | sessions, agents | using/agent-dialog | A4 |
| 通用对话页（Chat） | /chat | sessions, agents, attachments, multimodal, workspace, favorites | using/chat | A4 |
| **工坊（Projects）与构建** |
| 工坊列表 | /projects | projects | using/projects-build | A5 |
| 工坊详情 | /projects/[id] | projects, workflows, workflow_control, workflow_stats, tasks | using/project-detail | A5 |
| 工坊部署 | /projects/[id]/deploy | projects | using/project-deploy | A5 |
| 构建图谱 | /build/graph | projects, workflows | using/build-graph | A5 |
| 构建模块 | /build/modules | projects, workflows | using/build-modules | A5 |
| 构建总入口 | /build | projects, workflows | using/build-entry | A5 |
| **应用中心（App Center）** |
| 应用列表 | /apps | apps | using/app-center | A5 |
| 应用详情 | /apps/[appId] | apps | using/app-detail | A5 |
| **能力中心（Tools/MCP/Skills）** |
| 能力中心总入口 | /ability | agent_tools, skills, connectors | using/tools | A6 |
| 工具列表 | /ability/tools | agent_tools | using/tools | A6 |
| MCP 服务器管理 | /ability/mcp | agent_tools | using/mcp | A6 |
| Skill 列表 | /ability/skills | skills | using/skills | A6 |
| Skill 详情 | /ability/skills/[id] | skills | using/skill-detail | A6 |
| **业务集成（Integration Center）** |
| 业务集成中心 | /integration | connectors | using/integration-center | A6 |
| **资源组（Resource Groups）与共享** |
| 资源组列表 | /resource-groups | resource_groups, resource_shares | using/resource-groups-sharing | A7 |
| 资源组详情 | /resource-groups/[id] | resource_groups, resource_shares, groups | using/resource-group-detail | A7 |
| **任务面板（Event Jobs）** |
| 事件任务列表 | /events | event_jobs, missions | using/events | A7 |
| **进化框架（Evolution/PFR/Troubleshoot）** |
| 进化中心总入口 | /evolution | missions | using/evolution-pfr-troubleshoot | A7 |
| 进化 - Agent 列表 | /evolution/agents | missions | using/evolution-agents | A7 |
| 进化 - 分析面板 | /evolution/analytics | missions | using/evolution-analytics | A7 |
| 进化 - 历史记录 | /evolution/history | missions | using/evolution-history | A7 |
| 进化 - 进度看板 | /evolution/progress | missions | using/evolution-progress | A7 |
| 进化 - 提交任务 | /evolution/submit | missions | using/evolution-submit | A7 |
| PFR（问题-功能-请求）总入口 | /pfr | missions | using/evolution-pfr-troubleshoot | A7 |
| PFR 历史 | /pfr/history | missions | using/pfr-history | A7 |
| PFR 迭代详情 | /pfr/iterations/[id] | missions | using/pfr-iteration | A7 |
| 故障排查总入口 | /troubleshoot | missions | using/evolution-pfr-troubleshoot | A7 |
| 故障排查 - 分析 | /troubleshoot/analysis | missions | using/troubleshoot-analysis | A7 |
| 故障排查 - 代码审查 | /troubleshoot/code-review | missions | using/troubleshoot-code-review | A7 |
| 故障排查 - 修复 | /troubleshoot/fix | missions | using/troubleshoot-fix | A7 |
| 故障排查 - 复现 | /troubleshoot/reproduction | missions | using/troubleshoot-reproduction | A7 |
| 故障排查 - 追踪 | /troubleshoot/tracking | missions | using/troubleshoot-tracking | A7 |
| **用户管理** |
| 用户列表 | /users | users | admin/users-permissions | A7 |
| 用户详情 | /admin/users/[id]/usage | admin_billing, users | admin/users-permissions | A7 |
| **业务洞察与管理** |
| 业务洞察（Analytics） | /analytics | statistics, workflows, workflow_stats | admin/analytics | A8 |
| 运维管理（Management） | /management | admin_services, policies | admin/config-management | A8 |
| 运维面板（Ops） | /ops | admin_services, observability, sandbox | admin/ops-assistant | A8 |
| **管理员页面** |
| 用量报告（Billing） | /admin/billing | admin_billing, statistics | admin/billing | A8 |
| 服务状态 | /admin/service-status | admin_services, observability, sandbox | admin/service-status | A8 |
| **设置（Settings）** |
| 设置总入口 | /settings | config, users | admin/config-management | A8 |
| 个人设置 | /settings/profile | users | using/settings-profile | A8 |
| 平台配置 | /settings/config | config (manage_router: /config/manage/*) | admin/config-management | A8 |
| 审计追踪 | /settings/audit | audit | admin/audit | A8 |
| 共享管理 | /settings/sharing | resource_shares, file_shares | using/resource-groups-sharing | A7 |
| 模型目录 | /settings/model-catalog | config | admin/config-management | A8 |
| 浏览器扩展设置 | /settings/browser-extension | browser | using/browser-extension | A7 |
| **Demo 演示页面** |
| Demo Chat | /demos/chat | sessions, agents | getting-started/demos | A3 |

---

## 跨页面能力（Cross-Cutting Features）

| 功能 | 挂载位置/组件 | API routers | v4 章节/slug | 走查任务 |
|---|---|---|---|---|
| Spotlight 命令面板 | `web/components/spotlight/SpotlightCommandPalette.tsx`<br/>在 `main-layout.tsx` 全局挂载 | agents, projects, sessions, favorites | using/spotlight | A7 |
| 语言切换器 | `web/src/components/language-switcher.tsx`<br/>在 `sidebar.tsx` 底部渲染 | manifest, users | using/language-switch | A3 |
| 版本门控（Edition Gating） | `web/src/lib/edition.ts` + `EditionGate` 组件<br/>basic/enterprise 毛玻璃遮罩 | manifest | admin/config-management | A8 |
| **7 个内置助手（Helper Agents）** | | | | |
| 配置助手 (config) | 待确认挂载页面（`/settings/config` 推测） | config | admin/config-management | A8 |
| 审计助手 (audit) | `/settings/audit`<br/>`FloatingAssistantDot` in `page.tsx` | audit, users | admin/audit | A8 |
| 运维助手 (ops) | `/admin/service-status`<br/>`FloatingAssistantDot` in `page.tsx` | admin_services, observability, sandbox | admin/ops-assistant | A8 |
| 工具审查助手 (tool_review) | 待确认挂载页面（`/ability/tools` 推测） | agent_tools | using/tools | A6 |
| Skill 锻造助手 (skill_forge) | 待确认挂载页面（`/ability/skills` 推测） | skills | using/skills | A6 |
| 应用构建助手 (app_builder) | 待确认挂载页面（`/apps` 推测） | apps | using/app-center | A5 |
| Mission 助手 (mission) | 待确认挂载页面（`/evolution` 推测） | missions | using/evolution-pfr-troubleshoot | A7 |

---

## 无独立 UI 页面（纯 API / 页面内嵌能力）

以下 routers 无对应独立路由页，作为其他页面的后台数据支撑或嵌入式功能：

| API Router | 路径前缀 | 服务对象 | 归档章节/说明 | 走查任务 |
|---|---|---|---|---|
| workflow_control | /workflow | 工坊构建流程控制（start/pause/resume/cancel） | developer/workflow-control | A5 |
| workflows | /workflows | 工作流定义与查询 | developer/workflows | A5 |
| workflow_stats | /workflow-stats | 工作流统计（admin 专用） | admin/analytics | A8 |
| tasks | /tasks | 构建任务详情查询 | developer/tasks | A5 |
| clarifications | /clarifications | 构建中澄清交互（chat 嵌入） | developer/clarifications | A5 |
| attachments | （无前缀） | 对话附件上传/下载（chat 嵌入） | developer/attachments | A4 |
| multimodal | （无前缀） | 多模态解析（chat 嵌入） | developer/multimodal | A4 |
| workspace | （无前缀） | 工作空间文件管理（evolution/pfr/troubleshoot 嵌入） | developer/workspace | A7 |
| agentcore | /agentcore | Agent 运行时核心（session 底层） | developer/agentcore | A4 |
| directives | /directives | Agent 行为指令配置（agent 详情嵌入） | developer/directives | A4 |
| favorites | /favorites | 收藏功能（agent/session 卡片星标） | developer/favorites | A4 |
| policies | /policies | 权限策略管理（management 嵌入） | admin/users-permissions | A8 |
| groups | /groups | 用户组管理（resource-groups/users 嵌入） | admin/users-permissions | A7 |
| backup_shares | /backup | 备份共享（资源组/文件共享内部逻辑） | developer/backup-shares | A7 |
| file_shares | /shares | 文件共享（资源组嵌入） | using/resource-groups-sharing | A7 |
| template_assets | /templates | 模板资产（构建流程中模板选择） | developer/templates | A5 |
| template_collections | /template-collections | 模板集合（构建流程中模板选择） | developer/templates | A5 |
| template_shares | /template-shares | 模板共享（构建流程中模板选择） | developer/templates | A5 |
| template_ai_assist | /template-ai | 模板 AI 辅助（构建流程嵌入） | developer/templates | A5 |
| observability | /observability | 可观测性数据（service-status 嵌入） | admin/service-status | A8 |
| sandbox | /sandbox | 沙盒环境管理（service-status/agent 执行嵌入） | admin/sandbox | A8 |
| browser | （无前缀） | 浏览器扩展后端（browser-extension 嵌入） | using/browser-extension | A7 |
| manifest | （无前缀） | 应用清单/品牌/版本/i18n（全局配置） | reference/manifest | A3 |
| agent_api (apps.py) | /app-api | 应用中心 Agent API（应用详情调试嵌入） | using/app-center | A5 |

---

## 数据来源与验证

- **页面路由数**: 59 个（对应 `web/app/*/page.tsx`）
- **API router 文件数**: 44 个（`ls api/v2/routers/*.py | grep -v __init__ | wc -l`）
- **API router 实例数**: 45 个（`config.py` 导出 `router` + `manage_router` 两个实例）
- **侧边栏条目**: 16 个（与 A1 环境观测一致）
- **Spotlight 命令面板**: `web/components/spotlight/SpotlightCommandPalette.tsx`
- **内置助手提示词**: `prompts/system_agents_prompts/helper_agents/*.yaml` (7 个)
- **浏览器扩展设置**: `/settings/browser-extension` 独立页
- **语言切换**: `LanguageSwitcher` 组件在侧边栏底部
- **版本门控**: `web/src/lib/edition.ts` + `EditionGate` 组件

---

## 备注

1. **Evolution/PFR/Troubleshoot 三模块**：均由 `missions` router 支撑，前端分 9 个页面（/evolution/*、/pfr/*、/troubleshoot/*）。
2. **Helper Agents 挂载点**：目前仅在代码中确认 audit 和 ops 两个助手使用 `FloatingAssistantDot` 挂载；其余 5 个助手的前端入口需在走查中实地验证（推测按功能域就近挂载）。
3. **Demo 页面**：`/demos/chat` 为演示页，仅在特定场景使用，归 A3 顺带检查。
4. **Template 系列 routers**：4 个 template_* routers 无独立页面，均为构建流程（/projects、/build）中模板选择的后台 API。
5. **agent_api_router**：定义在 `apps.py` 中，前缀 `/app-api`，为应用中心应用详情页提供 Agent API 调试能力。

---

**下一步**: A3-A8 任务按此表格分批实地走查，确认每个页面/功能的 UI 完整性、i18n 覆盖、权限门控、数据流畅通；B1 任务按此表格编写 v4 手册章节配置。
