---
title: FAQ 与故障排查
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - CLAUDE.md
    - CONTRIBUTING.md
    - README.md
  generated_at: 2026-05-09T01:45:54+00:00
  generated_by: docs-sync v2
---

# FAQ 与故障排查

本章节汇总了安装、配置、运行、部署、Agent 构建、认证、MCP 等各环节最常见的问题，以及对应的解决步骤。所有条目均来自仓库中已有的脚本、配置、文档；如某项在源码中未定义，会明确标注 `—`。

## 如何使用本文档

- **按场景查阅**：问题按生命周期阶段分组（安装 → 启动 → 配置 → 运行 → 部署）。
- **按关键字查阅**：每个问题都有唯一 ID（如 `Q-INSTALL-01`），方便在 Issue 中引用。
- **按症状查阅**：文末「故障症状索引」表按报错关键词定位。

## 术语约定

| 术语 | 含义 |
|------|------|
| `&lt;repo&gt;` | Nexus-AI 仓库根目录 |
| `nexus-cli` | 仓库根目录下的 `./nexus-cli` 脚本 |
| 核心服务 | API（`:8000`）+ Worker + Web（`:3000`） |
| 可选服务 | MCP Server（`:9000`）、OTEL Collector、Jaeger |
| 主配置 | `config/default_config.yaml` |

---

## 1. 安装与环境（Q-INSTALL）

### Q-INSTALL-01：需要哪些前置组件？

| 组件 | 最低版本 | 必填 | 说明 |
|------|----------|------|------|
| Python | 3.13+ | 必填 | 后端运行时 |
| Node.js | 18+ | 必填 | 前端（`web/`） |
| AWS 账户 | — | 必填 | 已开通 Bedrock 访问权限 |
| AWS CLI | — | 必填 | 需执行 `aws configure` 完成凭证配置 |
| Git | — | 必填 | 拉取代码、贡献 |

### Q-INSTALL-02：在 Amazon Linux 2023 上如何一键安装？

执行以下命令下载并运行仓库提供的脚本：

```bash
curl -O https://raw.githubusercontent.com/hy714335634/Nexus-AI/main/setup_env_alinux2023.sh
chmod +x setup_env_alinux2023.sh
./setup_env_alinux2023.sh
```

### Q-INSTALL-03：手动安装的完整步骤是什么？

```bash
# 克隆仓库
git clone https://github.com/hy714335634/Nexus-AI.git
cd Nexus-AI

# 创建并激活虚拟环境
python3.13 -m venv .venv
source .venv/bin/activate

# 安装依赖
pip install -r requirements.txt
pip install -e .

# 配置 AWS 凭证
aws configure

# 编辑主配置（S3 桶名等）
# vim config/default_config.yaml

# 前端依赖
cd web && npm install && cd ..
```

### Q-INSTALL-04：为什么推荐使用 `uv` 而不是 `pip`？

`CLAUDE.md` 明确指出 `uv pip install -r requirements.txt` 为首选方式（`preferred over pip`）。`uv` 可加速依赖解析与下载，但并非硬性要求，`pip` 也可工作。

### Q-INSTALL-05：首次运行必须执行什么初始化？

```bash
./nexus-cli init
```

此命令会创建所需的 DynamoDB 表、SQS 队列、S3 存储桶。参见架构总览。

### Q-INSTALL-06：必须逐次进入虚拟环境吗？

是。`CLAUDE.md` 中指出：任何 Python 命令执行前都必须先 `source .venv/bin/activate`。`nexus-cli` 脚本内部会处理，但直接调用 `python agents/...` 时必须手动激活。

---

## 2. 服务启动与管理（Q-SERVICE）

### Q-SERVICE-01：服务种类与端口有哪些？

| 服务 | 端口 | 启动标志 | 必填 |
|------|------|----------|------|
| Web 前端 | 3000 | `--web` | 默认启动 |
| API 后端 | 8000 | `--api` | 默认启动 |
| Worker | — | `--worker` | 默认启动 |
| Bridge | 8001 | —（随服务） | 默认启动 |
| MCP Server | 9000 | `--mcp` | 可选 |
| OTEL Collector | — | `--otel` | 可选 |

### Q-SERVICE-02：`nexus-cli service` 支持哪些子命令？

| 命令 | 作用 |
|------|------|
| `./nexus-cli service start` | 启动核心服务（API + Worker + Web） |
| `./nexus-cli service start --api` | 仅启动 API |
| `./nexus-cli service start --worker` | 仅启动 Worker |
| `./nexus-cli service start --web` | 仅启动 Web |
| `./nexus-cli service start --mcp` | 启动核心服务 + MCP Server |
| `./nexus-cli service start --otel` | 启动 OTEL Collector |
| `./nexus-cli service start --dev` | 开发模式启动 |
| `./nexus-cli service stop` | 停止所有服务 |
| `./nexus-cli service status` | 查看状态 |
| `./nexus-cli service restart` | 重启所有 |
| `./nexus-cli service restart --mcp` | 重启 MCP Server |
| `./nexus-cli service logs` | 查看所有日志 |
| `./nexus-cli service logs --api` | 查看 API 日志 |
| `./nexus-cli service logs --mcp` | 查看 MCP 日志 |
| `./nexus-cli service logs -f` | 实时跟踪日志 |

### Q-SERVICE-03：服务访问地址是什么？

| 服务 | 地址 |
|------|------|
| Web 前端 | `http://localhost:3000` |
| API Swagger UI | `http://localhost:8000/docs` |
| MCP Server | `http://localhost:9000/mcp` |

### Q-SERVICE-04：如何实时跟踪某个服务的日志？

```bash
./nexus-cli service logs --api -f     # 仅 API
./nexus-cli service logs --mcp        # MCP 最近日志
./nexus-cli service logs -f           # 所有服务实时日志
```

### Q-SERVICE-05：只想运行 Worker，不启动 API/Web 可以吗？

可以。执行：

```bash
./nexus-cli service start --worker
```

Worker 独立消费 SQS 消息，单 stage 执行模型（一条消息触发一个 workflow stage，通过 SQS 路由到下一 stage）。

### Q-SERVICE-06：前端在 3000 端口被占用该怎么办？

当前 `nexus-cli` 未提供直接切换 Web 端口的开关；可先停止占用进程，再重启：

```bash
./nexus-cli service stop
lsof -ti:3000 | xargs kill -9
./nexus-cli service start
```

> 若需长期修改端口，请查阅 `web/` 下 Next.js 配置。

### Q-SERVICE-07：前端常用 npm 脚本有哪些？

| 命令 | 作用 |
|------|------|
| `npm run dev` | 开发服务器（端口 3000） |
| `npm run build` | 生产构建 |
| `npm run lint` | ESLint 检查 |
| `npm run test` | Jest 测试 |
| `npm run test:watch` | Jest 观察模式 |

### Q-SERVICE-08：如何直接调用 Agent（不经过 Web/API）？

```bash
source .venv/bin/activate
python agents/system_agents/magician.py -i "your prompt here"
python agents/system_agents/agent_build_workflow/agent_build_workflow.py \
  -i "build description"
```

---

## 3. 配置（Q-CONFIG）

### Q-CONFIG-01：配置文件有哪些？优先级是什么？

| 配置文件 | 作用 | 优先级 |
|----------|------|--------|
| 环境变量 | 覆盖一切 | 最高 |
| `config/default_config.yaml` | 主配置（模型、SSO、多模态等） | 中 |
| `config/service_config.yaml` | 运行时参数（workers、线程池、超时等） | 中 |
| 代码内默认值 | 硬编码默认 | 最低 |

### Q-CONFIG-02：如何切换 Bedrock 模型？

编辑 `config/default_config.yaml`：

```yaml
bedrock:
  model_id: 'us.anthropic.claude-sonnet-4-5-20250929-v1:0'      # 默认模型
  lite_model_id: 'us.anthropic.claude-haiku-4-5-20251001-v1:0'   # 轻量模型
  pro_model_id: 'us.anthropic.claude-opus-4-5-20251101-v1:0'     # 专业模型
```

### Q-CONFIG-03：多模态对话（图片、Excel、Word、PDF）如何配置？

```yaml
nexus-ai:
  multimodal_parser:
    aws:
      s3_bucket: "your-file-storage-bucket"
      s3_prefix: "multimodal-content/"
      bedrock_region: "us-west-2"
```

### Q-CONFIG-04：如何启用 SSO？

```yaml
nexus-ai:
  auth:
    user: 'admin'
    password: 'nexus'
  sso:
    enabled: True
    idp_metadata_url: 'https://portal.sso.xxxxx/saml/metadata/xxxxx'
    sp_entity_id: 'nexus-ai-sp'
    sp_acs_url: 'https://your-domain/api/v2/auth/sso/acs'
    frontend_url: 'https://your-domain'
```

> 启用 SSO 需额外安装 `python3-saml` 依赖。

### Q-CONFIG-05：开发模式的默认账号密码是什么？

`admin` / `nexus`（`config/default_config.yaml` 的 `nexus-ai.auth`）。仅当 `sso.enabled: False`（默认）时生效。

### Q-CONFIG-06：哪些环境变量会被读取？

文档中明确提到的环境变量：

| 环境变量 | 作用 |
|----------|------|
| `API_PORT` | 覆盖 API 端口 |
| `NEXUS_API_WORKERS` | 覆盖 API worker 数量 |
| `NEXUS_MCP_TOKEN` | 预设固定 MCP Bearer Token |

> 其他环境变量按 `nexus_utils/config_loader.py` 的优先级规则覆盖 `default_config.yaml` 中的键；详见 `reference/environment-variables`。

### Q-CONFIG-07：Workflow 定义文件在哪？有哪些工作流？

位于 `config/workflows.yaml`。内置工作流：

| 工作流 | 版本 | 阶段数 | 特点 |
|--------|------|--------|------|
| `agent_build` | V2 | 8 | 支持 fork/join 并行 Agent 设计 |
| `agent_update` | V2 | 5 | 支持 `skip_stages` |
| `tool_build` | V2 | 5 | 工具构建 |
| `skill_build` | V2 | 5 | 技能构建 |
| `magician` | — | 1 | 单阶段意图路由 |

---

## 4. 认证与权限（Q-AUTH）

### Q-AUTH-01：支持哪些认证方式？

| 模式 | 启用方式 | 适用场景 |
|------|----------|----------|
| 账号密码（JWT） | `sso.enabled: False`（默认） | 开发、自测 |
| SAML 2.0 SSO | `sso.enabled: True` | 生产、IAM Identity Center 对接 |
| MCP Bearer Token | 启动 `--mcp` 时自动生成 | IDE 调用 Agent |

### Q-AUTH-02：MCP Bearer Token 从哪获取？

三种方式（满足任一即可）：

| 来源 | 位置 |
|------|------|
| 启动时控制台输出 | `./nexus-cli service start --mcp` 的 stdout |
| 本地文件 | `.pids/mcp_token` |
| 环境变量预设 | `NEXUS_MCP_TOKEN=&lt;your-token&gt;` |

### Q-AUTH-03：如何在 IDE 中配置 MCP 客户端？

```json
{
  "mcpServers": {
    "nexus-ai": {
      "url": "http://localhost:9000/mcp",
      "headers": {
        "Authorization": "Bearer <启动时生成的 token>"
      }
    }
  }
}
```

IDE 对应配置文件位置：

| 配置文件位置 | IDE |
|--------------|-----|
| `~/.kiro/settings/mcp.json` | Kiro |
| `.mcp.json`（项目级） | Claude Code |

---

## 5. 部署（Q-DEPLOY）

### Q-DEPLOY-01：`nexus-cli deploy` 有哪些子命令？

| 命令 | 作用 |
|------|------|
| `nexus-cli deploy up &lt;env&gt;` | 创建/更新 CloudFormation 环境 |
| `nexus-cli deploy list` | 列出所有已部署环境 |
| `nexus-cli deploy status &lt;env&gt;` | 查看指定环境状态 |
| `nexus-cli deploy down &lt;env&gt; -y` | 删除环境（保留数据） |
| `nexus-cli deploy down &lt;env&gt; --clean-data -y` | 删除环境并清理 S3/DDB/SQS 数据 |

### Q-DEPLOY-02：完整的部署参数有哪些？

| 参数 | 默认值 | 必填 | 说明 |
|------|--------|------|------|
| `ENV_PREFIX` | — | 必填 | 环境名称前缀，用于命名所有 AWS 资源 |
| `--github-token` | — | 必填 | GitHub Personal Access Token（拉取代码） |
| `--db-password` | — | 必填 | Aurora PostgreSQL 数据库密码 |
| `--branch` | `main` | 可选 | Git 分支 |
| `--instance-type` | `c8i.2xlarge` | 可选 | EC2 实例类型 |
| `--key-name` | `Og_Normal` | 可选 | SSH Key Pair 名称 |
| `--iam-instance-profile` | `admin-for-ec2` | 可选 | EC2 IAM Instance Profile |
| `--volume-size` | `150` | 可选 | EC2 根卷大小（GB） |
| `--vpc-cidr` | `10.0.0.0/16` | 可选 | VPC CIDR 地址段 |
| `--region` | `us-west-2` | 可选 | AWS 区域 |
| `--user` | `admin` | 可选 | Web 登录用户名 |
| `--password` | `nexus` | 可选 | Web 登录密码 |
| `--enable-sso` | 关闭 | 可选 | 启用 SAML 2.0 SSO |
| `--allowed-email-domains` | — | 可选 | SSO 允许的邮箱域名 |
| `--enable-sandbox` | 关闭 | 可选 | 启用 Sandbox 沙箱运行时 |
| `--sandbox-instance-type` | `c8i.xlarge` | 可选 | Sandbox 节点实例类型（需支持 KVM） |
| `--sandbox-pool-size` | `1` | 可选 | Sandbox 节点数量 |
| `--sandbox-default-runtime` | `ec2` | 可选 | 默认运行时模式（`local` / `ec2`） |
| `--sandbox-runtimes` | `local,ec2` | 可选 | 允许的运行时模式 |
| `--sandbox-prewarm-vms` | `1` | 可选 | 每节点预热 VM 数量 |
| `-y` | — | 可选 | 跳过确认提示 |

### Q-DEPLOY-03：一个最小可用的部署命令怎么写？

```bash
nexus-cli deploy up my-env \
  --github-token ghp_xxxx \
  --db-password 'MySecurePass123!'
```

### Q-DEPLOY-04：如何启用 Sandbox 沙箱运行时？

```bash
nexus-cli deploy up my-env \
  --github-token ghp_xxxx \
  --db-password 'MySecurePass123!' \
  --enable-sandbox \
  --sandbox-instance-type c8i.xlarge \
  --sandbox-pool-size 2 \
  --sandbox-default-runtime ec2 \
  --sandbox-runtimes local,ec2 \
  --sandbox-prewarm-vms 3 \
  -y
```

Sandbox 为每个 Agent 会话提供 Firecracker microVM 隔离执行环境。

### Q-DEPLOY-05：Sandbox 管理命令有哪些？

| 命令 | 作用 |
|------|------|
| `nexus-cli sandbox overview` | 查看沙箱总览（节点、VM、Agent） |
| `nexus-cli sandbox list` | 列出 VM 实例 |
| `nexus-cli sandbox nodes` | 列出计算节点 |
| `nexus-cli sandbox launch --count <N>` | 手动启动节点 |
| `nexus-cli sandbox terminate &lt;node-id&gt;` | 终止指定节点 |
| `nexus-cli sandbox rebuild-rootfs -y --restart-nodes` | 重建 VM rootfs 镜像（依赖变更后） |
| `nexus-cli sandbox logs --limit 20` | 查看最近调度日志 |

### Q-DEPLOY-06：部署者需要哪些 AWS IAM 权限？

执行 `deploy.sh` 的 IAM 用户/角色需要以下权限：

| 服务 | 权限 | 用途 |
|------|------|------|
| CloudFormation | `CreateStack`, `DeleteStack`, `DescribeStacks`, `DescribeStackEvents` | 管理 Stack |
| EC2 | `RunInstances`, `TerminateInstances`, `CreateVpc`, `CreateSubnet`, `CreateSecurityGroup`, `CreateNatGateway`, `AllocateAddress`, `CreateRouteTable`, `CreateRoute`, `CreateTags`, `Describe*` | 创建 VPC 网络和实例 |
| IAM | `CreateRole`, `DeleteRole`, `AttachRolePolicy`, `DetachRolePolicy`, `CreateInstanceProfile`, `AddRoleToInstanceProfile`, `PassRole` | 创建实例角色 |
| RDS | `CreateDBCluster`, `CreateDBInstance`, `CreateDBSubnetGroup`, `DeleteDB*`, `Describe*` | Aurora 集群 |
| ElastiCache | `CreateServerlessCache`, `DeleteServerlessCache`, `Describe*` | Valkey 缓存 |
| ELB | `CreateLoadBalancer`, `CreateTargetGroup`, `CreateListener`, `CreateRule`, `RegisterTargets`, `Delete*`, `Describe*` | ALB 负载均衡 |
| CloudFront | `CreateDistribution`, `DeleteDistribution`, `Get*`, `Update*` | CDN 分发 |
| Lambda | `CreateFunction`, `DeleteFunction`, `GetFunction` | 自定义资源 |
| S3 | `ListAllMyBuckets`, `DeleteBucket`, `DeleteObject`（仅 `--clean-data` 时） | 清理数据 |
| SQS | `ListQueues`, `DeleteQueue`（仅 `--clean-data` 时） | 清理数据 |
| DynamoDB | `ListTables`, `DeleteTable`（仅 `--clean-data` 时） | 清理数据 |
| SSM | `GetParameter` | 获取 AMI ID |

### Q-DEPLOY-07：EC2 实例运行时需要哪些 IAM 权限？

| 服务 | 权限 | 用途 |
|------|------|------|
| Bedrock | `InvokeModel`, `InvokeModelWithResponseStream`, `ListFoundationModels` | AI 模型推理 |
| DynamoDB | `CreateTable`, `PutItem`, `GetItem`, `UpdateItem`, `DeleteItem`, `Query`, `Scan` | 18 张保留表的 CRUD |
| SQS | `CreateQueue`, `SendMessage`, `ReceiveMessage`, `DeleteMessage`, `ChangeMessageVisibility` | 任务队列 |
| S3 | `CreateBucket`, `GetObject`, `PutObject`, `DeleteObject`, `ListBucket`, `PutBucketCors` | 文件存储 |
| S3 Vectors | `CreateVectorBucket`, `CreateIndex`, `PutObject`, `Query` | 向量检索 |
| RDS | `DescribeDBClusters`（Aurora 通过 TCP 直连，不需要 IAM Auth） | 连接信息查询 |
| CloudWatch Logs | `CreateLogGroup`, `CreateLogStream`, `PutLogEvents` | 日志 |
| ECR | `GetAuthorizationToken`, `BatchGetImage`, `PutImage`（AgentCore 部署时需要） | 容器镜像 |

### Q-DEPLOY-08：删除环境会一并删除数据吗？

默认 **不删除**。执行 `nexus-cli deploy down &lt;env&gt; -y` 仅删除 CloudFormation Stack 相关资源，保留 S3、DDB、SQS 数据；加 `--clean-data` 才会清理。

---

## 6. AWS 依赖（Q-AWS）

### Q-AWS-01：所有 AWS 服务都是必须的吗？

| 服务 | 用途 | 是否必须 |
|------|------|----------|
| AWS Bedrock | AI 模型推理（Claude Sonnet/Opus/Haiku） | 必须 |
| Aurora PostgreSQL Serverless v2 | 关系型数据（项目、Agent、会话、消息等 12 张表） | 必须 |
| ElastiCache Valkey Serverless | 缓存层（统计聚合、热数据、Stream 事件缓冲） | 必须 |
| DynamoDB | KV 数据（工具、配置、事件调度等 18 张表） | 必须 |
| SQS | 异步任务队列（构建、部署） | 必须 |
| S3 | Agent 制品存储、会话文件、多模态内容 | 必须 |
| IAM Identity Center | SSO 单点登录 | 可选 |

### Q-AWS-02：没有 Bedrock 访问权限如何申请？

在 AWS 控制台 → Bedrock → 「Model access」申请所需 Claude 模型。Nexus-AI 默认使用 `us.anthropic.claude-sonnet-4-5-20250929-v1:0`、`claude-haiku-4-5-20251001-v1:0`、`claude-opus-4-5-20251101-v1:0`。

### Q-AWS-03：Agent Factory 支持哪些模型提供商？

`CLAUDE.md` 指出 `agent_factory` 支持多提供商：

- Bedrock
- OpenAI
- Anthropic
- LiteLLM
- Ollama
- Gemini

---

## 7. Agent 构建与运行（Q-AGENT）

### Q-AGENT-01：构建 Agent 的完整流程是什么？

```
用户需求 → 需求分析 → 架构设计 → Agent设计 → 提示词工程 → 工具开发 → 代码生成 → 测试验证
           ↓          ↓          ↓           ↓           ↓          ↓          ↓
        需求分析师   架构师    Agent设计师  提示词工程师  工具开发者  代码开发者  测试工程师
```

共 8 个专业 Agent 协作，对应 `agent_build` 工作流的 8 个阶段。

### Q-AGENT-02：Agent Build 的数据流是怎样的？

```
API 收到请求
  → 写入 SQS 消息
  → Worker 拉取消息执行某个 stage
  → 结果保存到 DDB
  → 通过 SQS 路由到下一 stage
  → 前端轮询 stages 表获取进度
```

### Q-AGENT-03：Agent 运行时（Chat）的数据流是怎样的？

```
前端发起 SSE 请求
  → Sessions Router
  → AgentRuntimeService
  → S3SessionManager 加载上下文
  → Strands agent.stream()
  → 事件解析并通过 SSE 推送
  → 会话保存回 S3
```

### Q-AGENT-04：在命令行直接触发一次完整构建？

```bash
source .venv/bin/activate
python agents/system_agents/agent_build_workflow/agent_build_workflow.py \
  -i "创建一个能够分析 PDF 文档并提取关键信息的 Agent"
```

生成的 Agent 代码会输出到 `agents/generated_agents/` 目录。

### Q-AGENT-05：平台已有哪些内置 Agent 示例？

| 类别 | Agent | 功能 |
|------|-------|------|
| AWS | `aws_pricing_agent` | AWS 服务定价查询和配置推荐 |
| AWS | `aws_architecture_diagram_generator` | 自然语言生成 AWS 架构图 |
| AWS | `aws_network_topology_analyzer` | 网络拓扑分析与可视化，合规性评估 |
| 文档 | `html_courseware_generator` | 交互式 HTML 课件（数学公式、化学方程式） |
| 文档 | `html2pptx` | HTML 转 PPT，保留原始样式 |
| 文档 | `pdf_content_extractor` | PDF 内容提取，多模态处理 |
| 文档 | `ppt_to_markdown` | PPT 转 Markdown，保持结构层次 |
| 分析 | `stock_analysis_agent` | 股票分析与投资报告（DCF 估值法） |
| 分析 | `company_info_search_agent` | 企业信息搜索，批量处理 |
| 内容生成 | `logo_design_agent` | Logo 设计，生成图像与设计说明 |
| 医疗 | `medical_document_translation_agent` | 医学文档翻译，医学词库 |
| 医疗 | `openfda_data_agent` | FDA 数据查询（药物、医疗设备、食品） |
| 医疗 | `drug_feedback_collector` | 药物反馈收集，情感分析与主题分类 |
| 医疗 | `clinicaltrials_search_agent` | 临床试验数据智能搜索 |
| 医疗 | `pubmed_literature_agent` | PubMed 文献检索与分析 |
| 平台 | `Nexus-AI-QA-Assistant` | 项目知识库问答（支持 FastAPI） |

### Q-AGENT-06：验证安装是否成功的「第一次调用」怎么写？

```bash
source .venv/bin/activate
python agents/system_agents/magician.py \
  -i "AWS us-east-1 的 m8g.xlarge 实例价格是多少？"
```

---

## 8. MCP 协议（Q-MCP）

### Q-MCP-01：Nexus-AI 与 MCP 有哪两种关系？

| 角色 | 说明 |
|------|------|
| MCP Server | 将平台 `status=running` 的 Agent 自动注册为 MCP Tool，暴露给 Kiro/Claude Code/Cursor |
| MCP 客户端 | Agent 通过 MCP 协议调用外部工具（如预置的 AWS MCP 服务器） |

### Q-MCP-02：MCP Server 为什么不经过 API？

MCP Server 直接调用 `agent_factory.create_agent_from_prompt_template()` 实例化 Strands Agent，绕过 API 层，目的是降低调用链路延迟。身份校验通过 Bearer Token 完成。

### Q-MCP-03：在哪里配置 Agent 调用的外部 MCP 服务器？

| 配置文件 | 作用 |
|----------|------|
| `config/mcp/system_mcp_server.json` | 系统预置的 MCP 服务器（如 AWS） |
| `config/mcp/public_mcp_server.json` | 用户自定义 MCP 服务器 |

---

## 9. 链路追踪（Q-OBS）

### Q-OBS-01：如何启用分布式链路追踪？

```bash
docker run -d --name jaeger \
  -p 16686:16686 -p 4317:4317 -p 4318:4318 \
  jaegertracing/all-in-one:latest
```

Jaeger UI 访问地址：`http://localhost:16686`

### Q-OBS-02：API 已内置 OpenTelemetry 了吗？

是。API Backend 已集成 OpenTelemetry instrumentation，启动 Jaeger 后即可直接看到链路数据。

### Q-OBS-03：如何启动 OTEL Collector？

```bash
./nexus-cli service start --otel
```

---

## 10. 开发贡献（Q-CONTRIB）

### Q-CONTRIB-01：分支命名有什么规范？

| 类型 | 说明 | 示例 |
|------|------|------|
| `feature` | 新功能 | `feature/add-pricing-agent` |
| `fix` | Bug 修复 | `fix/login-error` |
| `hotfix` | 紧急修复 | `hotfix/critical-bug` |
| `docs` | 文档更新 | `docs/update-readme` |
| `refactor` | 代码重构 | `refactor/agent-factory` |
| `test` | 测试相关 | `test/add-unit-tests` |
| `chore` | 构建/工具 | `chore/update-deps` |

### Q-CONTRIB-02：所有分支合并到哪里？

`main`。项目采用简化的 GitHub Flow，所有分支基于 `main` 创建并合并回 `main`：

| 分支 | 用途 | 合并目标 |
|------|------|----------|
| `main` | 主分支 | - |
| `feature/*` | 功能开发 | main |
| `fix/*` | Bug 修复 | main |
| `hotfix/*` | 紧急修复 | main |

### Q-CONTRIB-03：Commit Message 使用什么规范？

采用 [Conventional Commits](https://www.conventionalcommits.org/)：

```
<type>(<scope>): <subject>

<body>

<footer>
```

| 类型 | 说明 |
|------|------|
| `feat` | 新功能 |
| `fix` | Bug 修复 |
| `docs` | 文档更新 |
| `style` | 代码格式（不影响功能） |
| `refactor` | 代码重构 |
| `perf` | 性能优化 |
| `test` | 测试相关 |
| `chore` | 构建/工具/依赖更新 |

Subject 主题需使用英文动词原形开头、首字母小写、不加句号、不超过 50 字符。

### Q-CONTRIB-04：代码规范有什么硬性要求？

`CLAUDE.md` 列出的约定：

| 领域 | 规则 |
|------|------|
| 后端代码、变量、注释 | 英文 |
| UI 字符串 | 支持 i18n（中文/英文需同步） |
| 提示词模板 | `prompts/` 下的 YAML，结构化 schema（`agent.versions[].system_prompt`） |
| 工具定义 | 使用 Strands 的 `@tool` 装饰器，存 S3 并同步到 DDB |
| API 分层 | `api/v2/routers/`（HTTP）→ `api/v2/services/`（业务）→ `api/v2/database/`（持久化） |
| 认证 | 开发模式 `admin/nexus`；生产 SAML 2.0 SSO |

### Q-CONTRIB-05：处理合并冲突的推荐流程？

```bash
# 同步 main
git fetch origin main
git rebase origin/main

# 解决冲突后
git add .
git rebase --continue

# 强制推送（rebase 后必需）
git push --force-with-lease
```

### Q-CONTRIB-06：常用 Git 应急命令？

| 需求 | 命令 |
|------|------|
| 撤销最近一次提交，保留修改 | `git reset --soft HEAD~1` |
| 修改最近一次提交信息 | `git commit --amend -m "new commit message"` |
| 暂存当前修改 | `git stash` |
| 恢复暂存 | `git stash pop` |
| 查看最近 10 次提交 | `git log --oneline -10` |

---

## 11. 故障症状索引

按症状关键字反向定位对应的 FAQ 条目。

| 症状 | 可能原因 | 参考条目 |
|------|----------|----------|
| `ModuleNotFoundError` | 未激活虚拟环境 | Q-INSTALL-06 |
| `aws: command not found` | AWS CLI 未安装 | Q-INSTALL-01 |
| `Could not connect to DynamoDB` | 未执行 `./nexus-cli init` | Q-INSTALL-05 |
| 3000 端口被占用 | 其他进程占用 | Q-SERVICE-06 |
| SSO 登录失败，提示找不到 `python3-saml` | 未安装 SAML 依赖 | Q-CONFIG-04 |
| MCP 客户端 401 Unauthorized | Bearer Token 错误 | Q-AUTH-02 |
| MCP 客户端连接不上 `:9000` | 未使用 `--mcp` 启动 | Q-SERVICE-02 |
| Bedrock `AccessDenied` | 模型未申请访问 | Q-AWS-02 |
| Web 登录默认账号密码提示错误 | 配置中已改 | Q-CONFIG-05 |
| CloudFormation 创建失败 | IAM 权限不全 | Q-DEPLOY-06 |
| 部署后 Bedrock 调用失败 | EC2 角色权限不全 | Q-DEPLOY-07 |
| 构建工作流卡在某阶段 | SQS 消息未消费 / Worker 未启动 | Q-SERVICE-05、Q-AGENT-02 |
| Agent 生成结果找不到 | 未查看 `agents/generated_agents/` | Q-AGENT-04 |

---

## 12. 文档索引

官方扩展文档一览：

| 文档 | 路径 |
|------|------|
| 完整安装指南 | `docs/NEXUS_AI_SYSTEM_GUIDE.md` |
| API 使用示例 | `docs/API_USAGE_EXAMPLES.md` |
| Agent 构建模板 | `docs/VIBE_CODING_AGENT_BUILD_TEMPLATE.md` |
| MCP Server 部署指南 | `docs/MCP_SERVER_SETUP.md` |
| IAM Policy JSON 示例 | `docs/infrastructure/IAM_POLICIES.md` |
