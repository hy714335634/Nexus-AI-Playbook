---
title: 技巧与最佳实践
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - CLAUDE.md
    - README.md
  generated_at: 2026-05-09T01:54:38+00:00
  generated_by: docs-sync v2
---

# 技巧与最佳实践

这一页汇总了在使用 Nexus-AI 过程中常见的实用技巧，帮助你写出更好的需求描述、选对模型、减少排障时间、控制云端成本。

## 选择合适的模型

Nexus-AI 在 AWS Bedrock 上默认配置了三档 Claude 模型，按任务复杂度选择能显著影响速度和成本：

| 场景 | 推荐档位 | 默认模型 ID |
|------|----------|--------------|
| 轻量分类、意图识别、简单问答 | 轻量（Haiku） | `us.anthropic.claude-haiku-4-5-20251001-v1:0` |
| 大多数日常 Agent 构建与对话 | 默认（Sonnet） | `us.anthropic.claude-sonnet-4-5-20250929-v1:0` |
| 复杂架构设计、长上下文分析 | 专业（Opus） | `us.anthropic.claude-opus-4-5-20251101-v1:0` |

在 `config/default_config.yaml` 的 `bedrock` 段可以替换默认/轻量/专业三档的模型 ID。

::: tip
把 Agent 构建流程中偏"规划型"的阶段跑在 Sonnet 上，把最后的"代码生成"阶段切到 Opus，能在质量与成本之间取得更好平衡。
:::

## 写好自然语言需求描述

Nexus-AI 的 Agent Build 工作流包含 8 个专业 Agent 协作（需求分析 → 架构设计 → Agent 设计 → 提示词工程 → 工具开发 → 代码生成 → 测试验证）。你描述得越清晰，前面阶段的输出越准，后面阶段越不容易跑偏。

推荐的描述结构：

1. **目标产物**：这个 Agent 最终要"能做什么"（一句话）。
2. **输入**：用户会给它什么（文本、文件类型、URL……）。
3. **输出**：你希望它返回什么（结构化 JSON、Markdown 报告、图表……）。
4. **关键约束**：数据来源、合规要求、必须使用的外部工具、调用频次限制等。
5. **示例**：一两组典型的输入/输出对。

对比这两种提示：

```text
❌ 做一个分析股票的 Agent
✅ 构建一个股票分析 Agent：输入 A 股代码（如 600519），
   拉取最近 3 年财报和最新行情，按 DCF 估值法输出包含
   估值区间、投资建议和关键风险的 Markdown 报告
```

## 高效使用 nexus-cli

`nexus-cli` 是 Nexus-AI 的统一入口，掌握几个常用组合能大幅提升效率。

| 需求 | 命令 |
|------|------|
| 一次性启动 API + Worker + Web | `./nexus-cli service start` |
| 同时启动 MCP Server（IDE 调用场景） | `./nexus-cli service start --mcp` |
| 只重启 API（改了路由/服务层时） | `./nexus-cli service restart --api` |
| 实时查看所有日志 | `./nexus-cli service logs -f` |
| 只看 API 日志 | `./nexus-cli service logs --api` |
| 只看 MCP Server 日志 | `./nexus-cli service logs --mcp` |
| 查看服务状态 | `./nexus-cli service status` |

::: warning
初始化只需要执行一次：`./nexus-cli init` 会创建所需的 DynamoDB 表、SQS 队列与 S3 桶。重复执行是安全的，但会产生无意义的 API 调用。
:::

## 把 Agent 作为 MCP Tool 接入 IDE

启动 MCP Server 后，平台上所有 `status=running` 的 Agent 会被自动注册成 MCP Tool，供 Kiro、Claude Code、Cursor 调用。

```bash
./nexus-cli service start --mcp
```

在 IDE 的 MCP 配置中添加：

```json
{
  "mcpServers": {
    "nexus-ai": {
      "url": "http://localhost:9000/mcp",
      "headers": {
        "Authorization": "Bearer <启动时生成的token>"
      }
    }
  }
}
```

| 配置文件位置 | IDE |
|-------------|-----|
| `~/.kiro/settings/mcp.json` | Kiro |
| `.mcp.json`（项目级） | Claude Code |

Token 获取有三种方式：启动时控制台输出、`.pids/mcp_token` 文件、或通过环境变量 `NEXUS_MCP_TOKEN` 预设固定值。**CI/脚本场景建议用环境变量**，避免每次启动 token 变化导致客户端反复更新。

## 多模态对话的几个坑

对话中可以直接上传图片、Excel、Word、PDF，系统会自动解析并把内容交给 Agent。使用前请确认：

- `config/default_config.yaml` 里的 `multimodal_parser.aws.s3_bucket` 指向一个**已存在且可写**的 S3 桶。
- `bedrock_region` 需要是一个你已开通 Claude 模型访问权限的区域。
- 单条消息中混合多个大文件会显著拉长首包时间；如果只是让 Agent "看一眼"，优先传截图或节选，而不是整本 PDF。

## 开发模式 vs SSO 模式

| 维度 | 开发模式（默认） | SSO 模式 |
|------|------------------|----------|
| 登录方式 | 账号密码（默认 `admin` / `nexus`） | SAML 2.0 IdP |
| 适用场景 | 本地开发、POC、单机试用 | 企业内部署、多用户生产 |
| 切换方式 | `sso.enabled: False` | `sso.enabled: True` + IdP 元数据 URL |
| 额外依赖 | 无 | `python3-saml` |

::: warning
生产部署默认密码一定要改。在 `config/default_config.yaml` 的 `nexus-ai.auth` 段修改 `user` 与 `password`，或直接启用 SSO。
:::

## 云端一键部署的常见选择

`nexus-cli deploy up` 基于 CloudFormation 一键创建 VPC + EC2 + Aurora + Valkey + ALB + CloudFront。几个需要提前想清楚的参数：

| 参数 | 建议 |
|------|------|
| `--instance-type` | 生产默认 `c8i.2xlarge`；小规模 POC 可选更小规格 |
| `--region` | 选一个你**已开通 Bedrock 访问**的区域（默认 `us-west-2`） |
| `--volume-size` | 默认 150 GB，日志/构建产物多时建议调到 200+ |
| `--enable-sso` | 多人生产环境强烈建议打开 |
| `--enable-sandbox` | 需要为每个 Agent 会话做 Firecracker microVM 隔离时打开 |

销毁环境时可加 `--clean-data` 连同 S3、DynamoDB、SQS 一起清理，避免遗留的数据继续计费。

## 观测与排障

- **服务没起来**：先 `./nexus-cli service status` 看各端口是否在监听，再 `./nexus-cli service logs --api` / `--worker` 定位报错。
- **Agent 构建卡住**：Agent Build 走 SQS 单阶段执行模型，每个消息触发一个工作流阶段后路由到下一个。停在某一阶段时优先查 Worker 日志。
- **分布式链路追踪**：按需启动 Jaeger 容器：
  ```bash
  docker run -d --name jaeger \
    -p 16686:16686 -p 4317:4317 -p 4318:4318 \
    jaegertracing/all-in-one:latest
  ```
  访问 `http://localhost:16686` 查看调用链。
- **前端调 API 失败**：确认 Web(:3000)、API(:8000)、Bridge(:8001)、MCP(:9000) 四个端口无冲突。

## 成本控制清单

| 措施 | 效果 |
|------|------|
| 日常对话改用 `lite_model_id`（Haiku） | 显著降低 Token 费用 |
| 停用不需要的服务（如 MCP Server） | 降低 EC2/带宽消耗 |
| 销毁测试环境时带 `--clean-data` | 避免 S3/DDB/SQS 遗留费用 |
| 生产关闭 Jaeger / OTEL 采样率 | 降低观测链路开销 |
| Sandbox 按需开启，并合理设置 `--sandbox-pool-size` | 避免空闲 microVM 节点长期计费 |

## 下一步

- 通读 [快速开始](../getting-started/quickstart.md) 跑通第一个 Agent。
- 查看 [FAQ](../reference/faq.md) 解决部署与运行中的常见问题。
- 在 [Agent 示例目录](../examples/index.md) 里找到贴近你场景的参考实现。
