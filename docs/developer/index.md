---
title: 开发者指南
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - (chapter index — aggregated)
  generated_at: 2026-05-09T00:59:57+00:00
  generated_by: docs-sync v2
---

# 开发者指南

本章节面向**向 Nexus-AI 仓库贡献代码**或**在平台上扩展 Agent / 工具 / 技能**的开发者。内容以源码仓库为唯一事实来源，覆盖本地开发流程、系统架构、核心运行时、扩展方式与内部存储模型。

如果你只想使用产品功能，请回到「快速开始」与「用户手册」；本章内容预设你已熟悉 Python、AWS Bedrock 以及 Strands SDK 的基本概念。

## 入门

| 文档 | 简介 |
|------|------|
| [贡献指南](./contributing) | 本地环境要装什么、分支/提交/PR 流程、代码规范与依赖版本锁定。 |

## 架构与运行时

| 文档 | 简介 |
|------|------|
| [架构总览](./architecture-overview) | 平台 5 个核心服务 + 2 个可选服务的职责划分、数据流向与部署拓扑。 |
| [API 层架构](./api-layer) | FastAPI 应用 `api/v2/*` 的路由、认证、数据库客户端与统一中间件。 |
| [Worker 架构](./worker) | 从 SQS 长轮询消息、分发工作流任务到 `WorkflowEngine` 的消费者进程。 |
| [Stage 引擎](./stage-engine) | 把工作流切分成由 Agent 执行的若干 Stage 的内核，含 V1 / V2 双实现。 |

## 扩展平台

| 文档 | 简介 |
|------|------|
| [添加 Agent](./adding-agents) | 通过 Prompt 模板 + 运行脚本定义新 Agent，并注册到平台目录。 |
| [添加工具](./adding-tools) | 五种工具类型（builtin / generated / system / template / mcp）的编写与注册。 |
| [添加技能](./adding-skills) | 兼容 Anthropic Agent Skills 标准的能力包：编写 SKILL.md、导入与运行时加载。 |

## 数据与 Prompt

| 文档 | 简介 |
|------|------|
| [会话存储](./session-storage) | Aurora / Valkey / S3 / 本地缓存协作承载一次 Agent 对话的持久化模型。 |
| [动态 Prompt 构建](./dynamic-prompt) | `PromptManager` 基线层 + `runtime_injection` 动态注入层的两级 Prompt 流水线。 |
