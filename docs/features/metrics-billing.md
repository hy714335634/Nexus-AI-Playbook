---
title: 指标与计费
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - api/v2/routers/admin_billing.py
    - nexus_utils/observability/**
  generated_at: 2026-05-08T16:10:40+00:00
  generated_by: docs-sync v2
---

# 指标与计费

## 这是什么

**指标与计费**是 Nexus-AI 给**企业管理员**提供的用量统计与成本管控中心。它把平台里所有 LLM 调用、Agent 运行、构建流水线的消耗汇总成按用户 / 项目 / 模型切分的成本明细，让你回答两个问题：

1. 这个月谁用得最多、花在哪个模型上？
2. 如何给某个用户设上限，不让他把预算烧穿？

后台同时把这些数据以**标准业务指标**写入 CloudWatch，形成 8 个开箱即用的仪表板（Ops / API / Agent / Build / GenAI Cost / Sub-Agent Topology / Sandbox / Security），运维同事可以直接打开看。

## 使用场景

| 场景                  | 你会用到的入口                                    |
| --------------------- | ------------------------------------------------- |
| 月度成本复盘          | 管理后台 → `/admin/billing` → 总览                |
| 抓出「高消耗用户」    | 管理后台 → `/admin/billing` → 「Top 用户」        |
| 某个业务组的成本拆分  | 管理后台 → `/admin/billing` → 「Top 项目」        |
| 单个用户近 6 个月趋势 | 管理后台 → 用户详情页 → 用量                      |
| 给用户/租户设 Token 预算 | 管理后台 → 用户详情 → 配额                     |
| 监控线上健康度 / 延迟 | CloudWatch → Dashboard → `<Prefix>-OpsOverview` 等 |
| 审计谁改过配额        | CloudWatch Logs → `/nexus-ai/audit` 日志组        |

## 如何使用

### 1. 打开管理员计费总览

以 `admin` 角色登录，访问「管理」→「计费」。

<!-- SCREENSHOT: admin-billing-overview -->

页面展示的内容：

- **本月总成本** — 所有用户合计的 USD 金额
- **按模型分布** — 各 Bedrock 模型的调用量 / Token / 成本
- **Top 10 用户** — 成本排行榜
- **Top 10 项目** — 项目视角的成本排行

默认展示当月；想看历史某个月，在页面顶部切换 `YYYY-MM` 即可。

### 2. 定位高消耗用户，查看详情

在总览的「Top 用户」表格里点任意一行，进入**该用户近 N 个月趋势**：

<!-- SCREENSHOT: admin-billing-user-usage -->

- 近 6 个月月度曲线（默认 6 个月，可调到最多 24 个月）
- 本月按模型分布
- 当前配额和使用进度

### 3. 设置用户 Token 配额

在用户详情页点「编辑配额」：

<!-- SCREENSHOT: admin-billing-set-quota -->

| 字段                    | 说明                                                                    |
| ----------------------- | ----------------------------------------------------------------------- |
| `monthly_token_budget`  | 该用户**每自然月**的 Token 上限                                         |
| `alert_threshold_pct`   | 达到多少百分比时触发告警（默认 80%）                                    |
| `disable_on_exceed`     | 超额后是否**直接拒绝请求**（默认 `false`，只告警不拦截）                |
| `tenant_id`             | 可选，绑定到某个租户（留空=平台全局配额）                               |
| `notes`                 | 可选备注，会写入审计日志                                                |

点「保存」后，Nexus-AI 会：

1. 把新配额写入数据库，下一次请求立即生效
2. 写一条 `admin.quota.update` 审计事件到 `/nexus-ai/audit` 日志组
3. 当月用量超过 `alert_threshold_pct` 时触发告警

::: tip 小步走
第一次给团队设预算，建议先用 `disable_on_exceed=false` 观察一个月，再决定是否开启硬拦截。
:::

### 4. 打开 CloudWatch 仪表板

平台初始化时会在 CloudWatch 里自动创建 8 个仪表板。到 AWS Console → CloudWatch → Dashboards 里找以你的 `prefix` 开头的：

<!-- SCREENSHOT: cloudwatch-dashboards-list -->

| Dashboard 名                  | 观察谁用                                                    |
| ----------------------------- | ----------------------------------------------------------- |
| `<Prefix>-OpsOverview`        | SRE：API 错误、SQS 积压、Bedrock 限流                       |
| `<Prefix>-APIPerformance`     | API 工程师：请求量、延迟 P50/P90/P99、状态码分布、慢请求    |
| `<Prefix>-AgentRuntime`       | AI 工程师：Agent 调用、Token、工具耗时、错误类型            |
| `<Prefix>-BuildPipeline`      | 构建负责人：构建成功率、Stage 耗时、Fork 事件               |
| `<Prefix>-GenAICost`          | 管理员：各模型 Token 量、缓存命中率、Bedrock 延迟           |
| `<Prefix>-SubAgentTopology`   | AI 工程师：子 Agent 调用链、失败根因                        |
| `<Prefix>-SandboxRuntime`     | 平台工程：沙箱池空闲 / 忙碌、冷启动耗时、回收事件           |
| `<Prefix>-SecurityAudit`      | 安全：认证失败、RBAC 拒绝、敏感操作审计                     |

### 5. 用 Logs Insights 做即席查询

每个仪表板底部都有一个 Logs Insights 小部件（慢请求、错误 Top-N、审计事件等），点标题上的「在 Logs Insights 中打开」可以改查询条件，按 `user_id` / `project_id` / `trace_id` 切片。

<!-- SCREENSHOT: logs-insights-slow-requests -->

常用字段（日志默认为 JSON）：

- `user_id` / `project_id` / `agent_id` / `session_id` — 业务维度
- `trace_id` / `span_id` — 关联到 X-Ray trace
- `model_id` / `tokens_in` / `tokens_out` — LLM 调用详情
- `duration_ms` / `http.status_code` / `http.route` — API 请求

## 关键参数 / 限制

### 计费口径

| Token 类型        | 对 Bedrock 计费系数 | 说明                                                   |
| ----------------- | ------------------- | ------------------------------------------------------ |
| `input`           | 1.0x                | 正常输入（不含缓存）                                   |
| `output`          | 1.0x                | 模型输出                                               |
| `cache_read`      | **0.1x**            | 命中 prompt cache，便宜 10 倍                          |
| `cache_write`     | **1.25x**           | 写入 prompt cache，比正常输入贵 25%                    |

总成本公式：`tokens_in × 1.0 + cache_read × 0.1 + cache_write × 1.25 + tokens_out × output_unit_price`，按每个 `model_id` 单价分别乘算。

### 可切分的业务维度

| 维度            | 用途                                                        |
| --------------- | ----------------------------------------------------------- |
| `user_id`       | 单个用户成本、Top-N 排行                                    |
| `project_id`    | 业务组 / 项目成本                                           |
| `tenant_id`     | 租户维度（多租户部署）                                      |
| `agent_id`      | 该 Agent 的调用量与 Token                                   |
| `model_id`      | 模型级成本拆分                                              |
| `workflow_type` | agent_build / tool_build / skill_build / magician           |
| `runtime_type`  | local / agentcore / sandbox                                 |
| `stage_name`    | 构建流水线阶段                                              |
| `tool_name`     | 单个工具耗时 / 成功率                                       |

::: warning session_id 不进入指标
`session_id` 基数太大（每次对话一个），只写入 Trace span，**不会**出现在 CloudWatch 指标维度中，避免成本暴涨。如果需要按会话查，请用 Logs Insights。
:::

### 查询时间窗口

| 管控点                                         | 限制                             |
| ---------------------------------------------- | -------------------------------- |
| `/admin/billing/overview` 月份参数             | `YYYY-MM` 或 `YYYY-MM-DD`        |
| `/admin/billing/users/top` 返回数量            | `limit` ≤ **200**                |
| `/admin/billing/projects/top` 返回数量         | `limit` ≤ **200**                |
| 单用户趋势 `months` 参数                       | ≤ **24** 个月                    |
| CloudWatch Dashboard body                      | ≤ **400 KB** JSON（平台自动校验）|

### 日志保留周期

| 日志组                          | 保留天数 | 用途                   |
| ------------------------------- | -------- | ---------------------- |
| `/<slug>/application/*`         | 30 天    | 各服务应用日志         |
| `/<slug>/agent`                 | 30 天    | Agent 执行详情         |
| `/<slug>/build`                 | 30 天    | 构建流水线             |
| `/<slug>/access`                | **90 天**| API 访问日志（合规）   |
| `/<slug>/audit`                 | **90 天**| 敏感操作审计（合规）   |
| `/<slug>/security`              | **90 天**| 认证 / RBAC 拒绝       |
| `/<slug>/metrics`               | 7 天     | EMF 指标落盘           |
| `/<slug>/debug`                 | 3 天     | 临时调试               |

### 权限

- `/admin/billing/*` 的全部接口只允许 `role=admin` 访问，其它角色返回 **403**。
- 修改配额时会以当前管理员的 `user_id` 写入审计日志，不会匿名。

## 常见问题

**Q1：为什么管理后台的 cost 和 CloudWatch `GenAICost` 仪表板对不上？**

A：前端总览里的金额来自数据库里按月滚动聚合的账单表，数值稳定、每月结算一次；CloudWatch 仪表板看的是**原始 Token 量**，分钟级刷新。两者趋势一致，但不是逐美分对齐。需要精确金额就以 `/admin/billing/overview` 为准。

**Q2：我关掉 `observability` 开关后，计费还准吗？**

A：准。管理后台的用量/账单走的是业务数据库，不依赖 OTEL。`observability.enabled=false` 只是不往 CloudWatch 发指标和 trace，前端计费页和配额拦截仍然正常工作。

**Q3：`disable_on_exceed=true` 后，用户超额会看到什么？**

A：API 会返回配额超限错误，Chat / 构建任务无法启动，直到下个自然月自动重置或管理员调高预算。建议配合「超额前 80% 告警」，给用户留缓冲。

**Q4：缓存命中率一直很低怎么办？**

A：进 `<Prefix>-GenAICost` 看 `Cache Hit %` 小部件。长期低于 20%，通常是提示词前缀变化过大，导致每次都 cache miss。优先固定系统提示和工具清单顺序；如果仍无改善，可参考 [Bedrock Prompt Caching 文档](https://docs.aws.amazon.com/bedrock/latest/userguide/prompt-caching.html)调整缓存锚点。

**Q5：审计日志里最少能查到什么？**

A：`/nexus-ai/audit` 日志组里每条 `admin.quota.update` 事件至少包含：`timestamp` / `action` / `admin_user`（操作者）/ `target_user`（被改的用户）/ `token_budget` / `threshold` / `disable_on_exceed`。日志保留 **90 天**，满足大部分合规审计要求。
