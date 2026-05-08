---
title: 功能特性
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - (chapter index — aggregated)
  generated_at: 2026-05-08T16:22:31+00:00
  generated_by: docs-sync v2
---

# 功能特性

本章节按能力域盘点 Nexus-AI 的全部主要特性：Agent 的装配材料（工具、技能、模板、Agent Factory）、运行时隔离（Sandbox）、编排与协作（工作流引擎、多 Agent 图/群）、实时交互（流式中继、事件调度、Bridge 多连接）、以及平台运维侧的可观测、指标计费与日志。

如果你想了解某一项功能"是什么、什么时候用、怎么在控制台里使到它"，直接跳到对应页面即可；想系统掌握平台能力地图，按下表顺序读完即可。

## 本章节文档

| 文档 | 简介 |
|------|------|
| [工具与工具集](./tools-toolsets) | 给 Agent 挂能力的两种粒度：单个工具函数，或一整包工具、脚本、资料组成的工具集（Skill）。 |
| [技能系统](./skills-system) | 把专项能力打包成可分发、可复用、可版本化的 Skill，多个 Agent 与项目之间共享。 |
| [Agent Factory](./agent-factory) | 把"提示词模板 + 模型 + 工具"组装成可对话 Agent 的核心装配线与健康体检机制。 |
| [提示词模板](./prompt-templates) | 开箱即用的 YAML Agent 蓝本，覆盖常见场景，避免从零写提示词。 |
| [Sandbox 沙箱](./sandbox) | 每轮对话跑在一台独立 Firecracker microVM 里，兼顾隔离安全与复用速度。 |
| [工作流引擎](./workflow-engine) | 把一句需求拆成意图识别→分析→设计→开发→验证→部署的多阶段流水线。 |
| [多 Agent 图/群](./multi-agent) | 用网络图看清谁调用谁，用预编排的 Swarm 让多个专家 Agent 分工接力。 |
| [流式响应中继](./stream-relay) | 回答逐字流出且服务端缓存整轮输出，换标签、刷新、短暂断网都能接着看。 |
| [事件调度](./event-scheduler) | 把任一 Agent 变成定时任务或持续自主任务，自动触发并归档结果。 |
| [Bridge 多连接](./bridge) | 一条 `curl` 把 Agent 接到你自己的服务器，最多同接 5 台并并行执行命令。 |
| [可观测性](./observability) | 请求量、延迟、Token、构建成功率、沙箱池状态自动汇总到 CloudWatch 与 X-Ray。 |
| [指标与计费](./metrics-billing) | 面向管理员的用量与成本中心：按用户/项目/模型切分支出，为用户设上限。 |
| [日志](./logging) | 本地彩色日志 + 结构化日志双层体系，按 `user_id`、`trace_id` 秒级定位任意请求。 |
