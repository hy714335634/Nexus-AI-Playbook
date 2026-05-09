---
title: 参考
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - (chapter index — aggregated)
  generated_at: 2026-05-09T01:50:29+00:00
  generated_by: docs-sync v2
---

# 参考

本章节是 Nexus-AI 的**查阅型文档**：命令、配置项、环境变量、API、部署参数、IAM 权限、模型目录、术语、FAQ。内容一律以仓库源码为准，不做推测。

遇到"这个参数叫什么？""这个端点返回什么？""这个报错怎么解？"这类具体问题时，直接按下方列表定位对应文档即可。

## 文档一览

| 文档 | 内容简介 |
|------|----------|
| [nexus-cli 命令](./cli-commands) | `nexus-cli` 的全部子命令、参数、输出格式；kubectl 风格的操作入口。 |
| [配置项](./config-options) | `config/` 目录下所有 YAML 配置文件的键、类型、默认值与作用。 |
| [环境变量](./environment-variables) | 启动期读取的所有环境变量，覆盖优先级与默认值说明。 |
| [API 端点](./api-endpoints) | Platform API v2 所有 HTTP 路由的请求体、响应体与鉴权要求。 |
| [部署参数](./deploy-params) | 本地、EC2、CloudFormation、Firecracker、AgentCore 五种部署模式的参数穷举。 |
| [IAM 权限](./iam-policies) | Deployer 与 EC2 Runtime 两份最小权限策略的 JSON 与字段解释。 |
| [模型目录](./model-catalog) | `model_catalog.yaml` 中 Bedrock 模型条目、提供商、能力与降级规则。 |
| [术语表](./glossary) | 文档、代码、CLI、YAML 键中出现的所有术语的统一定义。 |
| [FAQ 与故障排查](./faq) | 按生命周期阶段组织的常见问题、报错关键词索引与解决步骤。 |
