---
title: 集成
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - (chapter index — aggregated)
  generated_at: 2026-05-08T22:43:13+00:00
  generated_by: docs-sync v2
---

# 集成

Nexus-AI 不是一个自给自足的系统，它的绝大多数能力——模型推理、身份认证、数据存储、对外协议——都来自与外部服务的集成。本章节按服务维度把每一项集成独立成页：它是做什么的、为什么必须开启或可选、怎么在配置文件里填参数、怎么验证跑通、出了问题从哪里查。

如果你是刚上手的部署者，建议从 [集成总览](./overview) 读起，按"必须 → 推荐 → 可选"的顺序逐一打通；如果你已经有一套跑起来的环境，只想补一项能力（例如接入 SSO、把 Agent 暴露给 IDE），直接跳到对应页面即可。

## 本章节文档

| 文档 | 简介 |
|------|------|
| [集成总览](./overview) | 把所有集成按"必须 / 推荐 / 可选"三档分类，给出一张统一的决策表。 |
| [AWS Bedrock 模型接入](./aws-bedrock) | 平台默认且唯一开箱即用的模型推理入口，覆盖 Claude、Nova、Llama、Mistral、DeepSeek、Qwen 等全系列。 |
| [外部 MCP 服务器](./mcp-clients) | 让平台 Agent 调用外部 MCP 服务器的工具，支持 stdio / SSE / Streamable HTTP 三种传输。 |
| [Agent as MCP Tool](./mcp-server) | 反向把平台上运行中的 Agent 暴露成 MCP 工具，Claude Code、Kiro、Cursor 等客户端可直接调用。 |
| [SSO (SAML 2.0)](./sso-saml) | 通过 SAML 2.0 对接企业 IdP，用 SSO 替换默认账号密码登录，按 RBAC 角色分权。 |
| [数据存储](./data-stores) | 平台数据层四件套：Aurora PostgreSQL、DynamoDB、ElastiCache Valkey、SQS，各自承担关系、键值、缓存、队列。 |
