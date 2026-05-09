---
title: 模型目录
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - config/model_catalog.yaml
    - nexus_utils/agent_factory.py
  generated_at: 2026-05-09T01:36:41+00:00
  generated_by: docs-sync v2
---

# 模型目录

Nexus-AI 的 Bedrock 语言模型目录，定义 Agent 可调用的所有模型条目。所有条目均经过 Strands Agent 实际对话验证。

## 概述

| 项 | 值 |
|----|----|
| 文件位置 | `config/model_catalog.yaml` |
| 加载时机 | 应用启动时加载；前端通过「刷新」按钮重新加载 |
| 最后验证 | 2026-04-29 |
| 条目总数 | 63 个模型 |
| 提供商数 | 13 家 |
| 工具调用 | 全部支持（不支持流式工具的模型会自动降级为非流式） |

::: info 手动编辑
`model_catalog.yaml` 可手动编辑：新增或删除模型条目后，前端点击刷新按钮即可生效，无需重启服务。
:::

## 顶层结构

```yaml
model_catalog:
  providers:
    - name: <提供商名称>
      models:
        - {id: "...", name: "...", tier: ..., is_global: ..., supports_vision: ...}
```

## 模型字段

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `id` | string | required | Bedrock model ID 或推理 profile ID；传给 `BedrockModel(model_id=...)` |
| `name` | string | required | 前端显示名；用户在界面上看到的模型名称 |
| `tier` | enum | required | 价格/能力档位：`pro` / `standard` / `lite`，见下表 |
| `is_global` | bool | required | `true` 表示 global cross-region 推理 profile；`false` 表示区域级 profile 或直接 model ID |
| `supports_vision` | bool | required | 是否支持图片/文档输入（来自 Bedrock `inputModalities`） |

## 档位（tier）说明

| tier | 定位 | 典型用途 |
|------|------|----------|
| `pro` | 顶级能力档 | 复杂推理、长上下文、高精度代码生成、视觉多模态旗舰模型 |
| `standard` | 主力常用档 | 日常对话、常规代码、结构化输出、大多数 Agent 场景 |
| `lite` | 低成本档 | 高并发、低时延、摘要/路由/分类等轻量任务 |

## 提供商总览

| 提供商 | 模型数 | 含全局 profile | 含视觉模型 |
|--------|-------:|:-------------:|:----------:|
| Anthropic | 12 | 是 | 是 |
| Amazon | 5 | 是 | 是 |
| Meta | 10 | 否 | 是 |
| Mistral | 11 | 否 | 是 |
| DeepSeek | 2 | 否 | 否 |
| Qwen | 6 | 否 | 是 |
| Google | 3 | 否 | 是 |
| NVIDIA | 3 | 否 | 是 |
| OpenAI | 2 | 否 | 否 |
| Moonshot | 2 | 否 | 是 |
| MiniMax | 2 | 否 | 否 |
| Writer | 2 | 否 | 否 |
| Z.AI | 3 | 否 | 否 |

## Anthropic

| id | name | tier | is_global | supports_vision |
|----|------|------|:---------:|:---------------:|
| `global.anthropic.claude-opus-4-6-v1` | Claude Opus 4.6 | pro | ✓ | ✓ |
| `global.anthropic.claude-opus-4-5-20251101-v1:0` | Claude Opus 4.5 | pro | ✓ | ✓ |
| `global.anthropic.claude-sonnet-4-6` | Claude Sonnet 4.6 | standard | ✓ | ✓ |
| `global.anthropic.claude-sonnet-4-5-20250929-v1:0` | Claude Sonnet 4.5 | standard | ✓ | ✓ |
| `global.anthropic.claude-sonnet-4-20250514-v1:0` | Claude Sonnet 4 | standard | ✓ | ✓ |
| `global.anthropic.claude-haiku-4-5-20251001-v1:0` | Claude Haiku 4.5 | lite | ✓ | ✓ |
| `us.anthropic.claude-opus-4-6-v1` | Claude Opus 4.6 (us) | pro | ✗ | ✓ |
| `us.anthropic.claude-opus-4-5-20251101-v1:0` | Claude Opus 4.5 (us) | pro | ✗ | ✓ |
| `us.anthropic.claude-sonnet-4-6` | Claude Sonnet 4.6 (us) | standard | ✗ | ✓ |
| `us.anthropic.claude-sonnet-4-20250514-v1:0` | Claude Sonnet 4 (us) | standard | ✗ | ✓ |
| `us.anthropic.claude-3-7-sonnet-20250219-v1:0` | Claude 3.7 Sonnet (us) | standard | ✗ | ✓ |
| `us.anthropic.claude-haiku-4-5-20251001-v1:0` | Claude Haiku 4.5 (us) | lite | ✗ | ✓ |

## Amazon

| id | name | tier | is_global | supports_vision |
|----|------|------|:---------:|:---------------:|
| `global.amazon.nova-2-lite-v1:0` | Nova 2 Lite | lite | ✓ | ✓ |
| `us.amazon.nova-pro-v1:0` | Nova Pro (us) | standard | ✗ | ✓ |
| `us.amazon.nova-2-lite-v1:0` | Nova 2 Lite (us) | lite | ✗ | ✓ |
| `us.amazon.nova-lite-v1:0` | Nova Lite (us) | lite | ✗ | ✓ |
| `us.amazon.nova-micro-v1:0` | Nova Micro (us) | lite | ✗ | ✗ |

## Meta

| id | name | tier | is_global | supports_vision |
|----|------|------|:---------:|:---------------:|
| `us.meta.llama4-maverick-17b-instruct-v1:0` | Llama 4 Maverick 17B | standard | ✗ | ✓ |
| `us.meta.llama4-scout-17b-instruct-v1:0` | Llama 4 Scout 17B | standard | ✗ | ✓ |
| `us.meta.llama3-3-70b-instruct-v1:0` | Llama 3.3 70B | pro | ✗ | ✗ |
| `meta.llama3-1-405b-instruct-v1:0` | Llama 3.1 405B | pro | ✗ | ✗ |
| `meta.llama3-1-70b-instruct-v1:0` | Llama 3.1 70B | pro | ✗ | ✗ |
| `us.meta.llama3-1-70b-instruct-v1:0` | Llama 3.1 70B (us) | pro | ✗ | ✗ |
| `meta.llama3-70b-instruct-v1:0` | Llama 3 70B | pro | ✗ | ✗ |
| `meta.llama3-1-8b-instruct-v1:0` | Llama 3.1 8B | lite | ✗ | ✗ |
| `us.meta.llama3-1-8b-instruct-v1:0` | Llama 3.1 8B (us) | lite | ✗ | ✗ |
| `meta.llama3-8b-instruct-v1:0` | Llama 3 8B | lite | ✗ | ✗ |

## Mistral

| id | name | tier | is_global | supports_vision |
|----|------|------|:---------:|:---------------:|
| `us.mistral.pixtral-large-2502-v1:0` | Pixtral Large (us) | pro | ✗ | ✓ |
| `mistral.mistral-large-3-675b-instruct` | Mistral Large 3 (675B) | pro | ✗ | ✓ |
| `mistral.mistral-large-2407-v1:0` | Mistral Large 2407 | pro | ✗ | ✗ |
| `mistral.mistral-large-2402-v1:0` | Mistral Large 2402 | pro | ✗ | ✗ |
| `mistral.devstral-2-123b` | Devstral 2 (123B) | standard | ✗ | ✗ |
| `mistral.magistral-small-2509` | Magistral Small | standard | ✗ | ✓ |
| `mistral.voxtral-small-24b-2507` | Voxtral Small (24B) | standard | ✗ | ✗ |
| `mistral.ministral-3-14b-instruct` | Ministral 3 (14B) | lite | ✗ | ✓ |
| `mistral.ministral-3-8b-instruct` | Ministral 3 (8B) | lite | ✗ | ✓ |
| `mistral.ministral-3-3b-instruct` | Ministral 3 (3B) | lite | ✗ | ✓ |
| `mistral.voxtral-mini-3b-2507` | Voxtral Mini (3B) | lite | ✗ | ✗ |

## DeepSeek

| id | name | tier | is_global | supports_vision |
|----|------|------|:---------:|:---------------:|
| `deepseek.v3.2` | DeepSeek V3.2 | standard | ✗ | ✗ |
| `deepseek.v3-v1:0` | DeepSeek V3 | standard | ✗ | ✗ |

## Qwen

| id | name | tier | is_global | supports_vision |
|----|------|------|:---------:|:---------------:|
| `qwen.qwen3-coder-480b-a35b-v1:0` | Qwen3 Coder 480B | pro | ✗ | ✗ |
| `qwen.qwen3-235b-a22b-2507-v1:0` | Qwen3 235B | pro | ✗ | ✗ |
| `qwen.qwen3-next-80b-a3b` | Qwen3 Next 80B | standard | ✗ | ✗ |
| `qwen.qwen3-vl-235b-a22b` | Qwen3 VL 235B | standard | ✗ | ✓ |
| `qwen.qwen3-32b-v1:0` | Qwen3 32B | standard | ✗ | ✗ |
| `qwen.qwen3-coder-30b-a3b-v1:0` | Qwen3 Coder 30B | lite | ✗ | ✗ |

## Google

| id | name | tier | is_global | supports_vision |
|----|------|------|:---------:|:---------------:|
| `google.gemma-3-27b-it` | Gemma 3 27B | standard | ✗ | ✓ |
| `google.gemma-3-12b-it` | Gemma 3 12B | standard | ✗ | ✓ |
| `google.gemma-3-4b-it` | Gemma 3 4B | lite | ✗ | ✓ |

## NVIDIA

| id | name | tier | is_global | supports_vision |
|----|------|------|:---------:|:---------------:|
| `nvidia.nemotron-super-3-120b` | Nemotron Super 120B | pro | ✗ | ✗ |
| `nvidia.nemotron-nano-3-30b` | Nemotron Nano 30B | standard | ✗ | ✗ |
| `nvidia.nemotron-nano-12b-v2` | Nemotron Nano 12B | lite | ✗ | ✓ |

## OpenAI

| id | name | tier | is_global | supports_vision |
|----|------|------|:---------:|:---------------:|
| `openai.gpt-oss-120b-1:0` | GPT OSS 120B | pro | ✗ | ✗ |
| `openai.gpt-oss-20b-1:0` | GPT OSS 20B | standard | ✗ | ✗ |

## Moonshot

| id | name | tier | is_global | supports_vision |
|----|------|------|:---------:|:---------------:|
| `moonshot.kimi-k2-thinking` | Kimi K2 Thinking | pro | ✗ | ✗ |
| `moonshotai.kimi-k2.5` | Kimi K2.5 | standard | ✗ | ✓ |

## MiniMax

| id | name | tier | is_global | supports_vision |
|----|------|------|:---------:|:---------------:|
| `minimax.minimax-m2.5` | MiniMax M2.5 | standard | ✗ | ✗ |
| `minimax.minimax-m2.1` | MiniMax M2.1 | standard | ✗ | ✗ |

## Writer

| id | name | tier | is_global | supports_vision |
|----|------|------|:---------:|:---------------:|
| `us.writer.palmyra-x5-v1:0` | Palmyra X5 | standard | ✗ | ✗ |
| `us.writer.palmyra-x4-v1:0` | Palmyra X4 | standard | ✗ | ✗ |

## Z.AI

| id | name | tier | is_global | supports_vision |
|----|------|------|:---------:|:---------------:|
| `zai.glm-5` | GLM 5 | standard | ✗ | ✗ |
| `zai.glm-4.7` | GLM 4.7 | standard | ✗ | ✗ |
| `zai.glm-4.7-flash` | GLM 4.7 Flash | lite | ✗ | ✗ |

## ID 前缀约定

| 前缀 | 含义 | 示例 |
|------|------|------|
| `global.` | Global cross-region 推理 profile；Bedrock 自动在多个区域间路由 | `global.anthropic.claude-opus-4-6-v1` |
| `us.` | US 区域级推理 profile；仅跨 US 各区域路由 | `us.anthropic.claude-opus-4-6-v1` |
| `&lt;provider&gt;.` 无前缀 | 直接 model ID，仅在模型所在的单一区域可用 | `mistral.mistral-large-2407-v1:0` |

::: tip `is_global` 的作用
当 `is_global: true`，请求会跨区域负载均衡，通常更稳定、更不易触发配额限制；`is_global: false` 则锁定在固定区域（多数为 us），延迟略低但受单区域配额约束。
:::

## 能力矩阵

按档位和视觉能力交叉统计的模型数量：

| tier | 支持视觉 | 不支持视觉 | 小计 |
|------|---------:|-----------:|-----:|
| pro | 6 | 12 | 18 |
| standard | 10 | 18 | 28 |
| lite | 8 | 9 | 17 |
| **总计** | **24** | **39** | **63** |

## 提示词缓存（Prompt Caching）

只有部分模型族支持 Bedrock 提示词缓存，其他模型族即使开启缓存配置也会被自动跳过：

| 模型族 | 支持缓存 |
|--------|:--------:|
| Anthropic Claude（3.5 / 4 / 4.5） | ✓ |
| Amazon Nova（Pro / Lite / Micro） | ✓ |
| Titan | ✗ |
| Llama | ✗ |
| Mistral | ✗ |
| Cohere | ✗ |
| AI21 | ✗ |
| 其他（DeepSeek / Qwen / Gemma / Nemotron / GPT OSS / Kimi / MiniMax / Palmyra / GLM） | ✗ |

缓存判定基于 model id 中是否包含 `claude`、`anthropic`、`nova`、`amazon.nova` 子串。

**计费**：首次写入按标准价 1.25 倍计费；命中窗口 5 分钟内按标准价 0.1 倍计费（9 折优惠）。

## 工具调用与流式

- **所有 63 个模型都支持工具调用**，可用于 Agent 场景。
- 不支持流式工具调用的模型会自动降级为非流式模式，调用方无需特殊处理。

## 完整示例 YAML

以下是最小可运行的 `model_catalog.yaml` 结构（仅保留一个提供商、两个模型作为示例）；完整目录参见上文各提供商小节。

```yaml
# Bedrock 可用语言模型目录（经 Strands Agent 实际对话验证）
# 可手动编辑，前端通过刷新按钮重新加载
# 最后验证: 2026-04-29
#
# supports_vision: 是否支持图片/文档输入（来自 Bedrock inputModalities）
# 所有模型均支持工具调用（不支持流式工具的模型会自动降级为非流式）

model_catalog:
  providers:
    - name: Anthropic
      models:
        - {id: "global.anthropic.claude-opus-4-6-v1", name: "Claude Opus 4.6", tier: pro, is_global: true, supports_vision: true}
        - {id: "global.anthropic.claude-haiku-4-5-20251001-v1:0", name: "Claude Haiku 4.5", tier: lite, is_global: true, supports_vision: true}

    - name: Amazon
      models:
        - {id: "us.amazon.nova-pro-v1:0", name: "Nova Pro (us)", tier: standard, is_global: false, supports_vision: true}
        - {id: "us.amazon.nova-micro-v1:0", name: "Nova Micro (us)", tier: lite, is_global: false, supports_vision: false}
```

## 修改目录

1. 编辑 `config/model_catalog.yaml`，按 YAML 语法新增或删除条目。
2. 保持字段齐全：`id` / `name` / `tier` / `is_global` / `supports_vision` 五项缺一不可。
3. 在前端界面点击「刷新模型」按钮，新条目立即生效；无需重启 Nexus-AI 服务。
4. 建议新增条目前先用 Bedrock Console 或 `aws bedrock list-foundation-models` 验证 model ID 可用性。

::: warning ID 拼写必须精确
`model_id` 不匹配 Bedrock 实际 ID 时，Agent 调用会抛 `ValidationException`。复制粘贴时注意版本后缀（如 `-v1:0`）和日期段。
:::

## 备注

- 条目顺序即为前端下拉框的显示顺序；同一提供商内通常按档位由高到低排列。
- 同一模型同时列出 global 和 us 两个条目时，前端会分别显示，由用户选择——global 更稳定，us 延迟更低。
- 本目录仅涵盖通过 AWS Bedrock 接入的模型；若需直连 Ollama / OpenAI / Anthropic API / LiteLLM / Mistral / Gemini / LlamaAPI 等提供商，见其他配置章节。
