---
title: 集成总览
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - README.md
    - config/default_config.yaml
  generated_at: 2026-05-08T22:27:08+00:00
  generated_by: docs-sync v2
---

# 集成总览

Nexus-AI 不是一个"自给自足"的系统，它的绝大多数能力——模型推理、认证、存储、观测、IDE 调用、沙箱隔离——都来自与外部服务的集成。本章节按服务维度把每项集成单独展开：它是做什么的、为什么必须开启或可选、怎么在 `config/default_config.yaml` 里配置、怎么验证跑通、出了问题去哪里看。

如果你是刚上手的部署者，建议先按"必须集成"→"推荐集成"→"可选集成"的顺序逐一打通；如果你已经有一套跑起来的环境，只想补一项能力（例如接入 SSO、把 Agent 暴露给 IDE），直接跳到对应页面即可。

## 集成分类

Nexus-AI 的集成按是否必需分三类：

| 分类 | 说明 | 典型场景 |
|------|------|----------|
| **必须集成** | 平台核心依赖，不开启无法启动或关键功能不可用 | AWS Bedrock、Aurora、DynamoDB、Valkey、SQS、S3 |
| **推荐集成** | 生产部署强烈建议开启，影响可观测性与合规 | OpenTelemetry、CloudWatch Logs、SAML SSO |
| **可选集成** | 按需启用，带来独立增值能力 | MCP Server、Sandbox、AgentCore、Bridge |

## 本章节文档

| 文档 | 分类 | 简介 |
|------|------|------|
| [AWS Bedrock](./aws-bedrock) | 必须 | AI 模型推理的唯一入口，支持 Claude Sonnet / Opus / Haiku 全系列，默认区域 `us-west-2`。 |
| [Aurora PostgreSQL](./aurora) | 必须 | 关系型数据层，承载项目、Agent、会话、消息等 12 张核心表；生产环境使用 Serverless v2。 |
| [DynamoDB](./dynamodb) | 必须 | KV 数据层，承载工具、配置、事件调度、审计日志等 18 张表；表前缀 `nexus_`。 |
| [ElastiCache Valkey](./valkey) | 必须 | 缓存与 Stream 事件缓冲层，支撑流式响应断点续播与热数据聚合。 |
| [AWS SQS](./sqs) | 必须 | 异步任务队列，解耦 API 与 Worker，承担 Agent 构建、部署等长时任务。 |
| [AWS S3 / S3 Vectors](./s3) | 必须 | 对象存储（制品、会话附件、多模态内容）与向量存储（工具/提示词/Agent 检索）。 |
| [SAML 2.0 SSO](./sso) | 推荐 | 对接 AWS IAM Identity Center 或第三方 SAML IdP，替换默认账号密码模式。 |
| [OpenTelemetry](./opentelemetry) | 推荐 | 通过 OTLP HTTP 协议把 Trace 数据推送到 Jaeger / ADOT Collector，追踪 Agent 全链路。 |
| [CloudWatch](./cloudwatch) | 推荐 | 日志集中采集与指标面板，生产部署建议与 X-Ray 一起启用。 |
| [MCP Server](./mcp-server) | 可选 | 把平台 Agent 暴露为 MCP Tool，让 Kiro / Claude Code / Cursor 直接调用。 |
| [MCP 客户端](./mcp-client) | 可选 | 让 Agent 反过来调用外部 MCP 服务器，扩展能力边界。 |
| [Sandbox (Firecracker)](./sandbox) | 可选 | 为每轮对话分配独立 microVM，承担代码执行、文件操作、shell 命令等高风险工具。 |
| [AWS Bedrock AgentCore](./agentcore) | 可选 | 把构建完成的 Agent 一键部署成独立的 AgentCore Runtime。 |
| [Bridge 多连接](./bridge) | 可选 | 通过单条 `curl` 把 Agent 接到自建服务器，最多同接 5 台。 |
| [CloudFormation 部署](./cloudformation) | 可选 | `nexus-cli deploy` 一键创建 VPC + EC2 + Aurora + Valkey + ALB + CloudFront 的完整栈。 |

## 统一配置入口

所有集成的开关和参数都落在同一个文件里：

```bash
config/default_config.yaml
```

集成相关的顶层字段如下：

| 字段 | 覆盖的集成 |
|------|-----------|
| `aws` | AWS 全局凭证、区域、Bedrock Endpoint |
| `bedrock` | 模型 ID、Prompt Caching、超时重试 |
| `aurora` | Aurora PostgreSQL 连接信息 |
| `dynamodb` | DynamoDB 表前缀与表名映射 |
| `valkey` | Valkey 端点、端口、SSL |
| `sqs` | SQS 队列前缀与可见性超时 |
| `nexus_ai.auth` / `nexus_ai.sso` | 账号密码模式 / SAML SSO |
| `nexus_ai.sandbox` | Sandbox 开关、节点池、Firecracker 路径 |
| `nexus_ai.artifacts_s3_bucket` 等 | S3 各用途存储桶 |
| `s3_vectors` | 向量存储 Bucket 与 Embedding 模型 |
| `observability` | OpenTelemetry 开关、采样、数据捕获粒度 |
| `logging` | 本地日志级别与路径 |
| `agentcore` | Bedrock AgentCore 执行角色与运行时超时 |

::: tip
云端部署时 CloudFormation 的 `UserData` 会通过 `update_config.py` 自动覆盖大部分字段；本地开发只需按需改动 `aws.*` 和 `bedrock.model_id`。
:::

## 通用启用流程

每一篇集成文档都会详细讲各自的启用步骤，但大多数集成的流程是相同的：

1. **确认前置条件** — 例如 AWS 账号已开通对应服务、IAM 权限到位。
2. **修改 `config/default_config.yaml`** — 打开开关、填入端点/凭证。
3. **重启服务** — `./nexus-cli service restart`。
4. **验证** — 各集成有独立的验证命令或控制台入口。
5. **排查** — 失败时先看 `logs/nexus_ai.log`，再看 CloudWatch / Jaeger。

## 验证集成是否生效

最快的总体验证方法：

```bash
# 1. 启动所有核心服务
./nexus-cli service start

# 2. 查看状态（API / Worker / Web 均应为 running）
./nexus-cli service status

# 3. 跑一个内置 Agent，端到端验证模型、数据库、SQS、S3 集成
source .venv/bin/activate
python agents/system_agents/magician.py -i "Hello"
```

若上述命令能正常返回 Agent 响应，说明 Bedrock + Aurora + DynamoDB + Valkey + SQS + S3 六项必须集成均已就位。

## 故障排查

| 现象 | 可能原因 | 建议操作 |
|------|---------|---------|
| 服务启动时报 `AccessDenied` | EC2 IAM Instance Profile 权限不足 | 比对 README 的「EC2 运行时 IAM 权限」清单补齐 |
| Agent 响应报 `Could not connect to the endpoint URL` | `aws.bedrock_region_name` 填写错误或该区域未开通 Bedrock | 切回 `us-west-2` 或在 AWS 控制台申请目标区域的模型访问 |
| 登录页报 `SSO metadata invalid` | `sso.idp_metadata_url` / `idp_metadata_xml` 错误或 IdP 未发布 | 检查 IdP 元数据 URL 可直接 `curl` 取回，并确认 SP Entity ID 与 IdP 侧一致 |
| `service status` 显示 API running 但 Web 打不开 | 3000 端口被占用或 Next.js 构建失败 | `./nexus-cli service logs --web -f` 查看最新错误 |
| MCP Server 启动失败、报 `token required` | 未设置 `NEXUS_MCP_TOKEN` 也未生成随机 token | 查看 `.pids/mcp_token` 文件或用 `--mcp` 选项重新启动 |
| Jaeger UI 打不开 Trace | `observability.enabled = false` 或 Jaeger 未启动 | 改配置为 `true` 并启动 Jaeger 容器（见 README「链路追踪」） |
| Sandbox 节点启不起来 | EC2 实例类型不支持 KVM、`firecracker_bin` 路径错 | 换成 c8i / c8id 等支持 KVM 的机型，检查 `/opt/firecracker/firecracker` 是否存在 |

更详细的排查步骤请查阅各集成文档末尾的「故障排查」小节。
