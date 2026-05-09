---
title: Agent Factory
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - nexus_utils/agent_factory.py
    - nexus_utils/safe_agent_factory.py
  generated_at: 2026-05-08T15:27:05+00:00
  generated_by: docs-sync v2
---

# Agent Factory

## 这是什么

Agent Factory 是 Nexus-AI 把「提示词模板 + 模型 + 工具」组装成一个可对话 Agent 的核心装配线。你在平台上点击「创建 Agent」、把 Agent 加入编排，或批量拉起多个 Agent 时，后台都是 Agent Factory 在按模板拉取配置、挑选模型、绑定工具，并在返回给你之前完成一次健康体检。

## 使用场景

| 场景 | Agent Factory 帮你做什么 |
| --- | --- |
| 从模板快速新建一个 Agent | 读取模板配置（模型、温度、工具清单、系统提示词），一键产出可运行实例 |
| 切换 Agent 的底层模型 | 在 Bedrock / OpenAI / Anthropic / Gemini / Mistral / Ollama / LlamaAPI / LiteLLM 之间切换，无需改模板结构 |
| 跑一组评测或批处理任务 | 用一份配置列表，批量生成多个 Agent，失败的单独标出、不拖累其他 Agent |
| 共享 Agent 时避免「在别人机器上跑不起来」 | 创建前自动校验依赖，缺工具或配置项会尝试自动补齐 |
| 关键流程想带一个兜底 Agent | 主 Agent 创建失败时，自动换到你指定的备用 Agent |

## 如何使用

### 方式一：从 UI 创建 Agent

<!-- SCREENSHOT: agent-factory-create-from-ui -->

1. 进入「Agents」页面，点击 `创建 Agent`。
2. 选择提示词模板（或基于现有模板复制修改）。
3. 选择模型提供商与具体模型（详见下方「关键参数 / 限制」）。
4. 勾选要绑定的工具：内置工具、系统工具、模板工具，或你自己上传到工作空间的生成工具。
5. 提交后 Agent Factory 会：
   - 校验依赖（模型可用、工具能导入、提示词存在）；
   - 缺失依赖时尝试自动修复（例如从工件仓库同步缺失的工具脚本）；
   - 做一次简短的功能自检；
   - 返回创建结果，成功则显示在你的 Agent 列表里。

### 方式二：带验证地创建单个 Agent

当你通过「高级创建」入口或 API 触发创建时，默认走的就是「带验证」流程：

1. 指定 Agent 名称（或模板相对路径）。
2. 选择环境：`production` / `development` / `test` 等（决定使用哪组温度、最大 token、流式设置）。
3. 选择版本号（默认 `latest`）。
4. 决定是否开启「自动修复依赖」（默认开启）。
5. 提交。平台会依次完成：依赖校验 → 依赖修复（可选）→ Agent 构建 → 功能自检 → 返回 Agent。

::: tip 自动修复做什么
只要你给出的模板/工具在平台仓库里「有记录」但「本地还没拉下来」，Agent Factory 会自动从工件存储把缺失的脚本同步到当前环境，无需你手动复制。
:::

### 方式三：批量创建 Agent

<!-- SCREENSHOT: agent-factory-batch-create -->

1. 准备一份 Agent 配置清单（每一项至少包含 Agent 名称；可选环境、版本、模型、状态等参数）。
2. 在「批量创建」页面上传或粘贴配置。
3. 选择「遇到错误时是否继续」：
   - 继续：跳过失败项，继续处理剩余 Agent；
   - 中止：第一个失败就停下，方便你排查。
4. 提交后查看结果面板：总数、成功数、失败数、每个 Agent 的详细状态。

### 方式四：带备用 Agent 创建

关键业务流程可以指定「主 Agent + 备用 Agent」：

1. 在创建表单的「高级」区填入主 Agent 名称。
2. 在「备用 Agent」字段填入回退目标。
3. 提交后如主 Agent 构建失败，Agent Factory 会自动尝试备用 Agent，并在返回结果中同时保留主 Agent 的错误信息供排查。

### 方式五：查看 Agent 健康状态

<!-- SCREENSHOT: agent-factory-health-status -->

对任意已创建的 Agent，可在详情页「健康」卡片查看：

- Agent 名称
- 所用模型 ID、最大 token、温度
- 绑定的工具数量
- 系统提示词长度
- 最近一次功能自检是否通过及其响应长度

## 关键参数 / 限制

| 参数 | 说明 | 默认值 |
| --- | --- | --- |
| 模型提供商 | `bedrock`、`ollama`、`openai`、`anthropic`、`litellm`、`llamaapi`、`mistral`、`gemini` | `bedrock` |
| 环境 (`env`) | 控制温度、最大 token、是否流式等运行时参数 | `production` |
| 版本 (`version`) | 指定提示词模板版本 | `latest` |
| 模型 ID (`model_id`) | 在选定提供商内指定具体模型 | `default` |
| 自动修复依赖 | 允许平台从工件仓库同步缺失的工具脚本 | 开启 |
| 功能自检 | 创建完成后发送一条测试消息验证可用 | 开启 |

| 限制 | 细节 |
| --- | --- |
| Prompt 缓存 | 仅对 Claude 3.5 / 4 / 4.5（Sonnet、Opus、Haiku）和 Amazon Nova（Pro、Lite、Micro）生效；其他模型族不启用 |
| 缓存计费 | 首次写入按 1.25× 标准价计费，5 分钟内命中按 0.1× 计费（90% 折扣） |
| 第三方提供商依赖 | 使用 Ollama / OpenAI / Anthropic / LiteLLM / LlamaAPI / Mistral / Gemini 需要在环境中安装对应扩展包，否则创建会报「缺少依赖」 |
| 工具同步 | 仅当工具路径符合平台约定（如 `generated_tools/&lt;dir&gt;/&lt;script&gt;/&lt;function&gt;`）时，自动同步才会触发 |
| 凭证刷新 | Bedrock 模型每次创建时会刷新一次凭证，确保在长会话后仍然可用 |
| 功能自检失败处理 | 自检失败不会阻止 Agent 返回；仅在日志/健康面板中标记为警告 |

## 常见问题

**Q1：我创建 Agent 时报「不支持的模型提供商」，怎么办？**
A：确认你选择的提供商是下列之一：`bedrock`、`ollama`、`openai`、`anthropic`、`litellm`、`llamaapi`、`mistral`、`gemini`。提供商名称大小写无关，但不能是其他值。

**Q2：我选了 OpenAI 但创建失败，提示缺少依赖？**
A：非 Bedrock 的提供商需要额外安装扩展，例如 `strands-agents[openai]`。联系你的管理员或在工作空间设置中启用对应扩展即可。

**Q3：为什么我看不到 prompt caching 的折扣？**
A：只有 Claude 和 Amazon Nova 系列模型启用了缓存。其他模型族（Titan、Llama、Mistral、Cohere、AI21）不会触发缓存逻辑，也因此没有折扣。

**Q4：「自动修复依赖」修了什么？会不会改坏我的配置？**
A：自动修复只做两件事：① 从工件仓库把模板里登记过、但当前环境缺失的工具脚本拉到本地；② 重新跑一次依赖校验。它不会改你的提示词模板、不会换你选的模型，也不会删除已有配置。如果你仍不放心，可在创建时关闭「自动修复」，改为手动修复后再次创建。

**Q5：批量创建里有一个 Agent 失败，其它 Agent 还能用吗？**
A：可以。默认模式下，失败的 Agent 仅在结果面板中标记为「失败」，成功的 Agent 正常返回并可立即使用。如果你希望第一次失败就停下排查，改为「遇错中止」模式即可。
