---
title: 提示词模板
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - nexus_utils/prompts_manager.py
    - prompts/template_prompts/**
  generated_at: 2026-05-08T15:31:56+00:00
  generated_by: docs-sync v2
---

# 提示词模板

## 这是什么

提示词模板是 Nexus-AI 内置的一组开箱即用的 Agent 配置蓝本。每个模板都是一份完整的 YAML 配置，包含系统提示词、环境参数、模型选择和工具依赖，让你在创建新 Agent 时直接套用，而不必从零编写提示词。

## 使用场景

| 场景 | 适合的模板 | 说明 |
| --- | --- | --- |
| 调通一个与外部 API 对话的 Agent（发起 HTTP 请求、处理鉴权、同步数据） | `api_integration` | 预置 HTTP 客户端、鉴权管理、数据同步等工具 |
| 让 Agent 产出文章、报告、营销文案或创意内容 | `content_generator` | 提高了温度参数以保证创意表达 |
| 读取 CSV/JSON/Excel 数据，输出统计与洞察 | `data_analyzer` | 内置文件读写与数据转换工具 |
| 对某个主题进行多源信息收集、深度分析并输出研究报告 | `deep_researcher` | 强制使用真实网络检索，输出带来源链接的 Markdown |
| 处理 PDF、DOCX、Markdown 等文档并提取关键信息 | `document_processor` | 覆盖文档解析、文本分析、格式转换 |
| 把一句话需求转成结构化的 JSON 需求文档 | `requirements_analyzer` | 严格输出 JSON，字段与验收标准已定义 |
| 想要一份覆盖所有可配置参数的参考样板 | `default` | 作为编写自定义模板的起点 |

## 如何使用

### 1. 在创建 Agent 时选择模板

进入「创建 Agent」页面，在「模板」环节选择一个预置模板；系统会把模板中的系统提示词、环境参数、工具依赖等字段自动填入表单。

<!-- SCREENSHOT: create-agent-choose-template -->

### 2. 查看模板内容

点击模板名称可以展开查看：

- **基本信息**：名称、描述、分类。
- **环境配置**：`development` / `production` / `testing` 三套环境下的 `max_tokens`、`temperature`、`streaming`。
- **系统提示词**：Agent 的行为指令。
- **工具依赖**：Agent 可以调用的工具列表。
- **支持的模型**：可用的底层模型 ID 列表（第一项为默认）。

<!-- SCREENSHOT: template-detail-view -->

### 3. 基于模板调整

模板只是起点，你可以在创建表单中直接修改任意字段：

1. 改写系统提示词，让 Agent 贴合你的业务语境。
2. 在工具列表里增删条目，例如加入 MCP 服务器或你自己生成的工具。
3. 调整温度、最大 token、是否流式输出。
4. 切换支持的模型，例如把默认模型从 Sonnet 换成 Haiku 以节约成本。

### 4. 发布并试跑

保存后点击「创建」生成新的 Agent，再进入聊天界面用典型问题跑一遍，确认提示词改写后的效果符合预期。

<!-- SCREENSHOT: chat-with-template-agent -->

## 模板一览

| 模板 | 分类 | 默认温度 | 典型用途 |
| --- | --- | --- | --- |
| `api_integration` | api_integration | 0.3 | REST API 调用、鉴权管理、跨系统数据同步 |
| `content_generator` | content_generation | 0.7 | 文章、报告、营销文案、创意写作 |
| `data_analyzer` | data_analysis | 0.3 | 多格式数据读取、清洗、统计与可视化 |
| `deep_researcher` | research_analysis | 0.3 | 多源信息收集与 Markdown 研究报告 |
| `document_processor` | document_processing | 0.3 | 文档解析、内容提取、格式转换 |
| `requirements_analyzer` | analysis | 0.3 | 自然语言需求 → 结构化 JSON 需求文档 |
| `default` | assistant | 0.3 | 全参考样板（所有可配置字段的示例） |

## 关键参数 / 限制

| 字段 | 含义 | 说明 |
| --- | --- | --- |
| `environments.*.max_tokens` | 单次响应的最大 token 数 | 生产环境通常设为 60000；测试与开发环境会更小以节省成本 |
| `environments.*.temperature` | 采样温度（0–1） | 确定性任务（分析/集成）建议 0.3，创意任务建议 0.7 |
| `environments.*.streaming` | 是否流式输出 | 所有模板默认为 `true` |
| `versions[].status` | 版本状态 | `stable` / `beta` / `deprecated`；加载时默认使用 `latest` |
| `metadata.supported_models` | 支持的模型列表 | 第一项为默认模型；可在创建时切换 |
| `metadata.tools_dependencies` | 工具依赖 | 按路径引用 Strands 内置工具、系统工具、模板工具、生成工具或已有 Agent |
| `metadata.mcp_dependencies` | MCP 依赖（可选） | 引用已配置的 MCP 服务器名称 |
| `metadata.model_provider` | 模型提供商（可选） | 默认为 `bedrock`，支持 `ollama`、`openai`、`anthropic` 等 |

::: tip
当未显式指定 `version` 时，系统会优先取名为 `latest` 的版本；若不存在则按语义化版本号挑选最高的一个。
:::

::: warning
`default` 模板是用于展示所有可配置参数的样板，并不适合直接拿去创建生产 Agent。请用它作为参考，选择业务对应的专业模板。
:::

## 常见问题

**Q：模板和我自己生成的 Agent 有什么区别？**
A：模板是 Nexus-AI 预置、随产品一起发布的蓝本，放在 `template_prompts` 目录；你创建的 Agent 会被保存成独立的配置（`generated_agents_prompts`），不会污染模板本身。

**Q：选了模板后改了系统提示词，原模板会被覆盖吗？**
A：不会。模板永远是只读蓝本，你的修改只影响新建出来的 Agent。

**Q：我能在一个 Agent 里混用多个模板的能力吗？**
A：一次只能以一个模板为起点，但你可以在创建表单中把其它模板的工具依赖、系统提示词片段复制过来，组合成你自己的版本。

**Q：不同环境（development / production / testing）的参数是怎么选用的？**
A：创建 Agent 时由平台根据部署环境自动选择；生产环境会使用 `production` 参数块，测试环境使用 `testing`，以此类推。

**Q：模板里的 `supported_models` 能随便改吗？**
A：可以调整顺序或增删，但请确保至少保留一个你账户和区域可访问的模型，否则 Agent 无法启动。
