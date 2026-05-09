---
title: 构建 Hermes 分析 Agent
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - agents/generated_agents/hermes_analyst_agent_2026a96a/**
    - prompts/generated_agents_prompts/hermes_analyst_agent_2026a96a/**
  generated_at: 2026-05-09T01:56:08+00:00
  generated_by: docs-sync v2
---

# 构建 Hermes 分析 Agent

本教程带你在 Nexus-AI 平台上从零构建一个 **Hermes 分析 Agent**：只需给出一个写作要求，它会自动检索技术资料、分析架构与原理、总结最佳实践，最终生成一篇结构完整的 Markdown 技术博文并保存到本地。

## 你会得到什么

- 一个可单轮或交互式调用的 **技术写作 Agent**，输入一句话需求即可产出 2000~4000 字的 Markdown 博文。
- 自动执行的 **五阶段分析流水线**：资料检索 → 架构分析 → 原理解析 → 最佳实践 → 博文生成。
- 一份可直接部署到 AgentCore Runtime 的 Agent 代码包。

## 前置条件

| 项 | 要求 |
| --- | --- |
| Nexus-AI 账号 | 已登录，具备创建项目权限 |
| AWS 凭证 | 已在控制台配置并通过「凭证检测」 |
| Bedrock 模型 | `global.anthropic.claude-sonnet-4-6` 已开通 |
| IAM 权限 | 至少具备 Bedrock 调用、AgentCore Runtime 调用、CloudWatch 写入权限 |
| 网络 | 能访问公网（Agent 需要拉取技术资料） |

::: tip
如果你还没开通 Sonnet 4.6，打开 Bedrock 控制台的「模型访问」页面申请即可，通常几分钟内生效。
:::

## 大约耗时

15 ~ 20 分钟。

---

## 步骤 1: 新建 Agent 项目

1. 打开 Nexus-AI 控制台，进入左侧导航「Agent 构建」。
2. 点击「新建项目」，在对话框中填写：
   - **项目名称**：`hermes-analyst`
   - **架构类型**：`Single Agent`
   - **描述**：`专注于 Hermes Agent 框架深度解读的智能写作助手`
3. 点击「创建」，系统会为你分配一个 `Project ID`（例如 `proj_de684f8f08e8`）。

<!-- SCREENSHOT: create-project-dialog -->

**期望结果**：你会被跳转到项目详情页，看到一个空的「构建工作流」面板，处于「待输入需求」阶段。

## 步骤 2: 填写 Agent 需求

在「需求描述」输入框中，粘贴以下内容：

```text
我需要一个 Hermes Agent 分析师：
- 通过 http_request 抓取 Hermes Agent 的公开技术资料
- 从架构设计、工作原理、应用实践三个维度进行深度分析
- 输出一篇结构完整的 Markdown 技术博文，保存到本地
- 支持自定义目标读者、博文风格、内容长度、分析侧重四个参数
```

点击「开始构建」。

<!-- SCREENSHOT: requirement-input -->

**期望结果**：工作流进入「提示词开发」阶段，左侧阶段栏高亮 `prompt_development`。

## 步骤 3: 审阅并确认提示词模板

系统会自动生成 Agent 的提示词模板。切换到「提示词」标签页，检查以下关键字段：

| 字段 | 期望值 |
| --- | --- |
| `name` | `hermes_analyst_agent` |
| `production.model_id` | `global.anthropic.claude-sonnet-4-6` |
| `production.temperature` | `0.4` |
| `production.max_tokens` | `60000` |
| `conversation_manager.type` | `summarizing` |

确认 `system_prompt` 字段中包含「工作流程（7 阶段线性流水线）」章节。

::: info
生产环境使用较低的 `temperature=0.4`，在保持技术写作所需的适度创造性的同时，最大化事实准确性。
:::

点击「锁定提示词」。

<!-- SCREENSHOT: prompt-review -->

## 步骤 4: 配置工具集

切换到「工具」标签页，确认以下 5 个工具已挂载：

| 工具 | 类型 | 用途 |
| --- | --- | --- |
| `http_request` | 内置 | 抓取 GitHub / 官方文档 |
| `file_read` | 内置 | 读取本地参考文件 |
| `current_time` | 内置 | 为博文加时间戳 |
| `calculator` | 内置 | 统计字数 / 计算耗时 |
| `file_writer` | 自动生成 | 将博文写入 `.cache/` 目录 |

如果 `file_writer` 显示为「待生成」，点击「自动生成工具」按钮，平台会根据提示词需求自动产出该工具。

<!-- SCREENSHOT: tool-list -->

**期望结果**：所有 5 个工具状态均为 **已就绪**。

## 步骤 5: 生成 Agent 代码

切换到「代码」标签页，点击「生成代码」。平台会产出一份名为 `hermes_analyst_agent.py` 的 Python 脚本。打开预览，确认包含以下结构：

```text
├─ 遥测配置（OpenTelemetry）
├─ BedrockAgentCoreApp 实例
├─ create_agent_from_prompt_template(...) 创建 Agent
├─ @app.entrypoint async def handler(...)
└─ __main__：支持 -i / --interactive / 容器模式
```

点击「下载代码包」，得到一个 zip 文件。

<!-- SCREENSHOT: generated-code -->

## 步骤 6: 本地快速试跑

在本地终端解压代码包，用单次输入模式验证 Agent：

```bash
python hermes_analyst_agent.py -i "帮我写一篇面向初级开发者的 Hermes Agent 入门文章"
```

**期望输出**（节选）：

```text
[配置] 目标读者：初级开发者 | 博文风格：入门 | 内容长度：standard | 分析侧重：综合
[阶段 1/5] 正在检索 Hermes Agent 相关技术资料...
[阶段 2/5] 正在分析 Hermes Agent 系统架构...
[阶段 3/5] 正在解析 Hermes Agent 工作原理...
[阶段 4/5] 正在总结应用最佳实践...
[阶段 5/5] 正在生成技术博文...
[生成摘要] 字数：约 2100 字 | 配置：初级开发者/入门/standard | 信息来源：在线 | 耗时：约 42 秒
```

打开 `.cache/2026a96a-dad8-4ed7-9e54-19132cd1c3f3/&lt;session_id&gt;/` 目录，应能看到 `hermes_agent_blog_&lt;timestamp&gt;.md` 文件。

<!-- SCREENSHOT: local-run -->

::: warning
若 `[阶段 1/5]` 显示「切换离线模式」，说明当前网络无法访问 GitHub，Agent 会回落到基于预训练知识生成博文，并在末尾免责声明中标注「信息来源：离线」。
:::

## 步骤 7: 部署到 AgentCore Runtime

返回 Nexus-AI 控制台，进入项目的「部署」标签页：

1. 选择运行环境：`production`
2. 确认模型：`global.anthropic.claude-sonnet-4-6`
3. 点击「部署」。

部署完成后，你会得到一个可供调用的 **Agent Runtime 端点**。

<!-- SCREENSHOT: deploy-panel -->

## 验证

在「测试」标签页提交以下 payload：

```json
{
  "prompt": "生成一篇深度解析 Hermes Agent 工具调用机制的技术博文，面向中高级开发者，字数 3000 以上"
}
```

**期望**：

- 流式响应依次输出五个阶段的进度标记。
- 最终摘要字段显示字数 ≥ 3000。
- `.cache/.../hermes_agent_blog_*.md` 文件已生成，包含：标题、摘要、目录、引言、架构解析、工作原理、最佳实践、总结、信息来源、免责声明 共 10 个章节。
- 博文末尾包含标准免责声明（生成时间、信息来源类型、知识截止日期）。

如果任一检查失败，返回「日志」标签页查看对应阶段的异常信息。

## 下一步

- 阅读 [Agent 工作流概览](../tutorials/workflow-overview.md) 了解 Build Workflow V2 的完整生命周期。
- 阅读 [自定义工具开发指南](../tutorials/custom-tools.md) 学习如何手写并注册类似 `file_writer` 的工具。
- 阅读 [部署与监控](../tutorials/deploy-and-monitor.md) 了解如何为生产 Agent 配置告警和链路追踪。
