---
title: AWS Bedrock 模型接入
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - config/model_catalog.yaml
    - nexus_utils/agent_factory.py
  generated_at: 2026-05-08T22:29:34+00:00
  generated_by: docs-sync v2
---

# AWS Bedrock 模型接入

## 概述

AWS Bedrock 是 Nexus-AI 默认且唯一开箱即用的模型推理入口。平台上所有 Agent 的对话、工具调用、多模态输入，最终都通过 Bedrock 统一访问 Claude、Nova、Llama、Mistral、DeepSeek、Qwen、Gemma、GPT OSS 等模型。不开 Bedrock，平台无法启动；切换到其它提供商（OpenAI、Anthropic 直连、Gemini 等）属于可选扩展。

模型清单维护在 `config/model_catalog.yaml`，前端「模型选择」下拉菜单从这份目录加载；运行时参数（区域、重试、超时、Prompt Caching）落在 `config/default_config.yaml` 的 `aws` 与 `bedrock` 两个小节。本页讲的就是这两份文件怎么填，以及接入出问题后从哪一步开始查。

## 启用前提

开始前请确认：

- 一个可用的 AWS 账号，默认区域为 **`us-west-2`（俄勒冈）**，Claude 4.5/4.6 与 Nova 2 在该区域支持最完整。
- 已在 `AWS Console → Bedrock → Model access` 申请并获批你要用的模型（至少覆盖 `bedrock.model_id` / `bedrock.small_model_id` / `bedrock.large_model_id` 这三个默认模型键）。
- 运行 Nexus-AI 服务的身份（EC2 Instance Profile 或本地 AWS CLI 凭证）具备以下 Bedrock 权限：
  - `bedrock:InvokeModel`
  - `bedrock:InvokeModelWithResponseStream`
  - `bedrock:ListFoundationModels`
- 本地或容器内可直达 `https://bedrock-runtime.<region>.amazonaws.com`（企业网络下需放行出站 HTTPS）。

::: tip 凭证如何刷新
主机部署（EC2）走 IAM Instance Profile，凭证由 AWS 自动轮换；Sandbox VM 内通过环境变量定期刷新。两种模式下都无需手动配置长期 Access Key。
:::

## 配置步骤

### 1. 申请模型访问

进入 `AWS Console → Bedrock → Model access → Manage model access`，至少勾选你将使用的模型。默认部署会调用下表中三款 Claude，强烈建议一并申请：

| 用途 | 模型 ID |
|------|---------|
| 默认模型 | `us.anthropic.claude-sonnet-4-5-20250929-v1:0` |
| 轻量模型 | `us.anthropic.claude-haiku-4-5-20251001-v1:0` |
| 专业模型 | `us.anthropic.claude-opus-4-5-20251101-v1:0` |

<!-- SCREENSHOT: bedrock-model-access -->

### 2. 填写 `aws` 小节

打开 `config/default_config.yaml`，在 `aws` 小节写入区域：

```yaml
aws:
  aws_region_name: us-west-2        # 其它 AWS 资源使用的区域
  bedrock_region_name: us-west-2    # Bedrock 专用区域，可与上方不同
  aws_profile_name: ""              # 留空表示使用默认凭证链
```

::: info 为什么分两个 region
Bedrock 的可用区域独立于其它 AWS 服务。例如你的 DDB/Aurora 在 `ap-northeast-1`，但 Bedrock 仍可配置为 `us-west-2` 直接跨区调用。
:::

### 3. 填写 `bedrock` 小节

在同一份配置文件中新增或修改 `bedrock` 小节：

```yaml
bedrock:
  # 各 Agent 会引用的默认模型键（可以自由增减键名，只要 agent 配置里引用一致即可）
  model_id: us.anthropic.claude-sonnet-4-5-20250929-v1:0
  small_model_id: us.anthropic.claude-haiku-4-5-20251001-v1:0
  large_model_id: us.anthropic.claude-opus-4-5-20251101-v1:0

  # boto3 连接层配置
  connect_config:
    connect_timeout: 10    # 秒，建立 TCP 连接的超时
    read_timeout: 300      # 秒，等待模型响应的超时
    retries:
      max_attempts: 5      # 最大重试次数（含首次）
      mode: adaptive       # legacy / standard / adaptive

  # Prompt Caching（可选）
  prompt_caching:
    enabled: true
    cache_system_prompt: true
    cache_tools: true
```

::: warning `read_timeout` 的经验值
流式输出和长推理任务建议至少 `300` 秒。设置过短会在 Opus 深度推理、长文档总结等场景触发 `Read timeout` 异常。
:::

### 4. 选择模型 ID（可选）

平台自带的模型清单位于 `config/model_catalog.yaml`，前端「模型选择」下拉菜单从中加载。按提供商分组的主要模型：

| 提供商 | 代表模型 | 支持视觉 | 档位 |
|--------|---------|---------|------|
| Anthropic | Claude Opus 4.6 / 4.5、Sonnet 4.6 / 4.5、Haiku 4.5 | ✔ | pro / standard / lite |
| Amazon | Nova Pro、Nova 2 Lite、Nova Lite、Nova Micro | ✔（Micro 除外）| standard / lite |
| Meta | Llama 4 Maverick 17B、Llama 3.3 70B、Llama 3.1 405B/70B/8B | 仅 Llama 4 系列 | pro / standard / lite |
| Mistral | Mistral Large 3、Pixtral Large、Devstral 2、Ministral 3 | 部分 | pro / standard / lite |
| DeepSeek | DeepSeek V3.2、V3 | — | standard |
| Qwen | Qwen3 235B、Qwen3 VL 235B、Qwen3 Coder 480B/30B | Qwen3 VL | pro / standard / lite |
| Google | Gemma 3 27B / 12B / 4B | ✔ | standard / lite |
| NVIDIA | Nemotron Super 120B、Nemotron Nano 30B/12B | 仅 Nano 12B | pro / standard / lite |
| OpenAI | GPT OSS 120B / 20B | — | pro / standard |
| Moonshot | Kimi K2 Thinking、Kimi K2.5 | 仅 K2.5 | pro / standard |
| MiniMax | MiniMax M2.5 / M2.1 | — | standard |
| Writer | Palmyra X5 / X4 | — | standard |
| Z.AI | GLM 5、GLM 4.7、GLM 4.7 Flash | — | standard / lite |

带 `global.` 前缀的 ID 为全球跨区推理端点（Global Inference），不带前缀或带 `us.` 前缀的为单区/美国跨区端点。若某个全球模型在你当前区域不可用，优先尝试对应的 `us.*` 版本。

::: tip 自定义模型目录
如果你的账号已申请了 `config/model_catalog.yaml` 里没有列出的模型，直接编辑该文件即可。前端下拉菜单有「刷新」按钮，改完无需重启服务。
:::

### 5. Prompt Caching（可选但建议）

Bedrock 的 Prompt Caching 能把系统提示词与工具定义缓存 5 分钟，显著降低成本：

| 行为 | 费率 |
|------|------|
| 首次写入缓存 | 1.25× 标准价 |
| 5 分钟内命中缓存 | 0.1× 标准价（90% 折扣） |

当前支持 Prompt Caching 的模型族：

- Anthropic Claude 3.5 / 4 / 4.5（Sonnet / Opus / Haiku）
- Amazon Nova（Pro / Lite / Micro）

其它模型族（Titan / Llama / Mistral / Cohere / AI21）即使把 `prompt_caching.enabled` 设为 `true`，平台也会自动跳过缓存参数，不会报错。

### 6. 重启服务

改完配置后让运行时生效：

```bash
./nexus-cli service restart
```

## 验证

从浅到深三步确认接入跑通。

### 步骤 1：CLI 级验证

确认当前身份能列出 Bedrock 模型：

```bash
aws bedrock list-foundation-models --region us-west-2 | head -40
```

能看到成百上千个模型条目就说明 IAM 权限与区域均正常。若报 `AccessDenied`，回到「启用前提」检查 IAM。

### 步骤 2：服务级验证

```bash
./nexus-cli service status
```

API / Worker / Web 三项都应显示 `running`。如果 API 起不来，先查本地日志：

```bash
./nexus-cli service logs --api -f
```

重点搜索 `bedrock`、`boto`、`Could not connect` 等关键字。

### 步骤 3：端到端 Agent 验证

运行一个内置 Agent 完整走一遍推理链路：

```bash
source .venv/bin/activate
python agents/system_agents/magician.py -i "Hello"
```

能返回中文/英文回复即代表 Bedrock + Agent Factory + 工具加载全部正常。

<!-- SCREENSHOT: bedrock-agent-response -->

## 故障排查

| 现象 | 可能原因 | 建议操作 |
|------|---------|---------|
| 启动日志报 `AccessDeniedException` | IAM 身份缺少 `bedrock:InvokeModel` 等权限 | 对照「启用前提」补齐 Instance Profile 权限 |
| `Could not connect to the endpoint URL "https://bedrock-runtime.xxx.amazonaws.com"` | `aws.bedrock_region_name` 填错，或该区域未开通 Bedrock | 改回 `us-west-2`，或在目标区域申请模型访问 |
| `ValidationException: The provided model identifier is invalid` | 模型 ID 拼写错误；或该模型未在当前区域开放 | 在 AWS Console 的 Bedrock → Model catalog 搜索正确 ID，确认区域支持 |
| `ThrottlingException: Too many requests` | 命中 Bedrock 账号级 QPS / TPM 限额 | 申请配额提升；或把 `bedrock.connect_config.retries.mode` 改为 `adaptive` 让 SDK 自动退避 |
| 长推理场景报 `Read timeout on endpoint URL` | `read_timeout` 过低 | 把 `bedrock.connect_config.read_timeout` 调高到 300 秒以上 |
| 切到 Haiku 4.5 后报 `ModelStreamErrorException` | 该模型不支持流式工具调用 | 无需改配置，平台会自动降级为非流式调用；或在 Agent 配置里显式关闭流式 |
| Prompt Caching 没有任何命中 | 选用的模型族不在 Claude / Nova 名单中 | 换成 Claude 或 Nova；其它模型族即使配置 `enabled: true` 也不会触发缓存 |
| 明明申请了模型，却提示 `access to the model isn't authorized` | Bedrock Model access 的申请没走完/被驳回 | 回到 `Bedrock → Model access` 确认状态为 `Access granted` |
| 跨区调用报 `inference profile not found` | 你引用了 `global.*` 前缀的 ID，但账号未开通全球跨区推理 | 切回 `us.*` 前缀的同名模型 ID |
| Sandbox VM 内调用 Bedrock 报凭证过期 | VM 凭证轮换失败 | 查看 VM 内的凭证刷新日志，必要时重启 Sandbox 节点 |

::: info 从哪里开始查
排查顺序永远是：AWS CLI 能不能通 → Nexus-AI 服务进程能不能起 → Agent 能不能返回。在前两步没通之前，不要怀疑 Agent 或工具配置。
:::
