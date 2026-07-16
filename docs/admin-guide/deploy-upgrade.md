---
title: 部署与升级
sync:
  source_commit: 7f4029536abf5945f2384f544555a3f6815c2519
  source_files:
    - config/deploy.yaml.template
    - docs/deployment/**
    - infrastructure/release/README.md
    - nexus-cli
  generated_at: 2026-07-12T12:22:31+00:00
  generated_by: docs-sync v2
---

# 部署与升级

本章面向负责把 Nexus-AI 部署到自己 AWS 账号、并在后续维护升级的 IT 管理员。整套部署由命令行工具 `nexus-cli` 完成：一条命令即可创建全套云资源；日后升级只更新计算节点上的代码，数据不受影响。

## 概述

- **一键部署**：`nexus-cli deploy up` 在你的 AWS 账号里创建整套环境（网络、应用节点、数据库、缓存、负载均衡、CDN 等），完成后给出访问地址与登录信息。
- **配置驱动**：所有部署参数集中在一份 `deploy.yaml` 里，便于复用与审阅；命令行参数可临时覆盖。
- **数据与计算分离**：数据库、缓存、对象存储都在应用节点之外，升级或重建节点都不会动到数据。
- **服务可管理**：部署完成后，用 `nexus-cli service` 系列命令查看状态、看日志、重启单个服务。

::: info
`deploy up` 后面紧跟的 **环境前缀（env-prefix）** 是这套环境的唯一标识，例如 `nexus-ai-prod`。它决定了所有资源的命名前缀，只能通过命令行参数指定，不在配置文件里。后续查看状态、升级、删除都要用同一个前缀。
:::

## 部署前置要求

在开始部署前，先准备好下列条件：

| 项目 | 要求 |
|------|------|
| 部署机 | 一台能运行 `nexus-cli` 的机器（推荐 Amazon Linux 2023，t3.small/medium，30GB 磁盘），需有公网出口 |
| AWS 凭证 | 部署机绑定一个含部署权限的 IAM Role，或配置好等效的 AWS 凭证 |
| 部署权限 | 该角色需覆盖 CloudFormation、EC2、RDS、ElastiCache、EFS、负载均衡、CloudFront、Lambda、SSM、S3、IAM 等一组权限；可直接套用平台随附的 IAM 策略文档 |
| 目标区域 | 确定部署区域（默认 `us-west-2`），并确认该区域的 EIP/VPC/NAT 等服务配额充足 |
| Key Pair（可选） | 如需 SSH 登录节点排障，先在目标区域创建 EC2 Key Pair，并在配置中填入其名称；留空则不绑定密钥 |
| 模型访问 | 在**部署区域**的 Bedrock 控制台 → *Model access* 中启用平台所需模型（Claude 系列）。这一步 IAM 无法代替，新账号首次必须手动申请 |

::: warning 模型访问必须先手动开通
如果部署后首次构建或对话报 `AccessDeniedException`（提示 `aws-marketplace:ViewSubscriptions/Subscribe`），说明目标模型尚未在账号中启用。到部署区域的 Bedrock 控制台的 *Model access* 页面申请开通对应模型，启用后重试即可。详见[模型目录与接入](./model-access.md)。
:::

## 首次部署

### 方式一：用配置文件部署（推荐）

参数较多时用配置文件更清晰，也便于团队复用和审阅。

1. 复制模板并按需修改：

   ```bash
   cp config/deploy.yaml.template config/deploy.yaml
   # 编辑 config/deploy.yaml 填入实际值（密码、区域、实例类型等）
   ```

2. 用配置文件创建环境（`env-prefix` 仍从命令行传入）：

   ```bash
   nexus-cli deploy up nexus-ai-prod --config config/deploy.yaml
   ```

3. 命令行参数可临时覆盖配置文件中的同名项，优先级更高：

   ```bash
   nexus-cli deploy up nexus-ai-staging \
     --config config/deploy.yaml \
     --branch release/v2.4 \
     --enable-sso
   ```

### 方式二：命令行快速部署

参数少时可直接在命令行指定：

```bash
# 最简方式（公开仓库，默认参数）
nexus-cli deploy up nexus-ai-test

# 私有仓库 + 自定义登录与数据库密码
nexus-cli deploy up nexus-ai-demo \
  --github-token ghp_xxxxxxxxxxxx \
  --user admin --password MyPass123 \
  --db-password StrongDBPass!

# 指定分支与实例类型
nexus-cli deploy up nexus-ai-dev \
  --branch develop \
  --instance-type m7i.xlarge \
  --github-token ghp_xxx

# CI/CD 场景：跳过确认提示
nexus-cli deploy up nexus-ai-ci -y --github-token ghp_xxx
```

部署过程约需 **15–25 分钟**（创建全套云资源）。完成后命令会输出 CloudFront 访问地址与登录信息。

::: tip 中文界面
所有命令都支持中文提示，加 `--lang zh` 即可：

```bash
nexus-cli --lang zh deploy up nexus-ai-test --github-token ghp_xxx
```
:::

## 部署配置项

以下为 `deploy.yaml` 支持的配置项。**这些都是部署时配置**，修改后需要通过升级流程重新下发才会生效。

**AWS 基础设施**

| 配置项 | 作用 | 默认值 |
|--------|------|--------|
| `region` | 所有资源所在的 AWS 区域 | `us-west-2` |
| `instance_type` | 应用节点 EC2 实例类型 | `c8i.2xlarge` |
| `key_name` | SSH Key Pair 名称，留空则不绑定密钥 | 空 |
| `iam_instance_profile` | 应用节点绑定的 IAM Instance Profile 名称 | `admin-for-ec2` |
| `volume_size` | 应用节点根卷大小（GB） | `150` |
| `vpc_cidr` | VPC 网段 | `10.0.0.0/16` |

**应用**

| 配置项 | 作用 | 默认值 |
|--------|------|--------|
| `git_repo_url` | 代码仓库地址 | 官方仓库 |
| `git_branch` | 部署的分支 | `main` |
| `github_token` | 私有仓库访问令牌（**敏感**） | 空 |

**认证（密码模式）**

| 配置项 | 作用 | 默认值 |
|--------|------|--------|
| `auth_user` | 密码模式登录用户名 | `admin` |
| `auth_password` | 密码模式登录密码（**敏感**） | — |

> 启用 SSO 后，密码模式凭证仍会作为后备的配置管理员保留。SSO 详见[登录与 SSO](./sso-auth.md)。

**数据库与缓存**

| 配置项 | 作用 | 默认值 |
|--------|------|--------|
| `db_password` | 数据库密码（**敏感**） | — |
| `aurora_min_capacity` | 数据库最小容量（ACU，越低越省钱） | `0.5` |
| `aurora_max_capacity` | 数据库最大容量（ACU） | `16` |
| `valkey_max_data_gb` | 缓存最大数据量（GB） | `5` |
| `valkey_max_ecpu` | 缓存最大计算量（ECPU/秒） | `15000` |

**SSO（IAM Identity Center）**

| 配置项 | 作用 | 默认值 |
|--------|------|--------|
| `enable_sso` | 是否启用 SSO 登录 | `false` |
| `sso_group_name` | Identity Center 中的用户组名 | `{env-prefix}-users` |
| `allowed_email_domains` | 允许登录的邮箱域名白名单，空=不限制 | 空 |

**沙箱运行时（可选）**

| 配置项 | 作用 | 默认值 |
|--------|------|--------|
| `enable_sandbox` | 是否部署沙箱运行时 | `false` |
| `sandbox_instance_type` | 沙箱节点实例类型，**须支持 KVM**（8 代 Intel `c8i/m8i/r8i` 或 `.metal`，不能用 `c8id` 等 `d` 变体） | `c8i.xlarge` |
| `sandbox_pool_size` | 沙箱节点数量 | `1` |

**部署行为**

| 配置项 | 作用 | 默认值 |
|--------|------|--------|
| `no_wait` | 提交后立即返回，不等待创建完成 | `false` |

::: warning 敏感配置项
`github_token`、`auth_password`、`db_password` 是敏感信息。请勿把填好真实值的 `deploy.yaml` 提交到代码仓库或以明文方式外发；建议部署后妥善保管或改用密钥管理。
:::

## 启用 SSO 登录

部署时启用 SSO，会自动在 IAM Identity Center 创建 SAML 应用与用户组，并推送到环境：

```bash
# 启用 SSO
nexus-cli deploy up nexus-ai-prod --github-token ghp_xxx --enable-sso

# 启用 SSO 并限制只允许指定邮箱域名登录
nexus-cli deploy up nexus-ai-prod \
  --github-token ghp_xxx \
  --enable-sso \
  --allowed-email-domains amazon.com \
  --allowed-email-domains subsidiary.co
```

启用 SSO 需要账号已开通 IAM Identity Center，且部署角色具备相应权限。完整的登录方式配置、用户组分配等内容见[登录与 SSO](./sso-auth.md)。

## 查看部署状态

用途：查看某个环境的详细状态，或列出账号里所有已部署的环境。

```bash
# 单个环境的详细状态（本地记录 + AWS 实时状态）
nexus-cli deploy status nexus-ai-prod

# 列出所有环境
nexus-cli deploy list
```

部署完成后，平台内也提供**[服务状态](./service-status.md)**页面，可在侧边栏「服务状态」中查看各服务是否正常运行。

![admin-service-status](/images/admin-service-status.png)

## 服务管理

用途：在应用节点上查看和控制平台各服务的运行状态。

```bash
# 查看所有服务状态
nexus-cli service status

# 查看某个服务的日志
nexus-cli service logs --mcp

# 重启某个服务
nexus-cli service restart --mcp

# 停止 / 启动服务
nexus-cli service stop --mcp
nexus-cli service start --mcp
```

::: tip
`nexus-cli service` 命令要在应用节点上执行。日常巡检也可以直接看平台内的**[服务状态](./service-status.md)**页面，无需登录节点。MCP 服务的启停与令牌管理详见[MCP 服务管理](./mcp.md)。
:::

### 配套：运维助手

平台内的**服务状态**页面配有**运维助手**。部署完成后，日常运维不必记命令，可以直接问它。

- **在哪里打开**：侧边栏「服务状态」页面，点右上角的助手图标。
- **能问什么**：哪个服务不正常、最近的错误日志、某个服务要不要重启。
- **会给什么**：以表格列出服务状态，需要操作时给出带确认的按钮。
- **护栏**：重启、停止等有影响的操作**必须二次确认**后才执行。

运维助手的完整能力见[内置 AI 助手](./helper-agents.md)与[服务状态监控](./service-status.md)。

![ops](/images/ops.png)

## 升级到新版本

用途：把已部署的环境更新到新版本。

**升级只更新计算节点上的代码与本地配置，数据不受影响** —— 数据库、缓存、对象存储都在节点之外。升级过程中平台会自动：备份现有配置 → 更新代码 → 合并配置（保留数据库/缓存连接等运行时值）→ 按需重装依赖 → 重建前端 → 重启服务。

对于以**一键交付**方式部署的环境，升级由维护者签发一条新的更新命令，你在部署机上粘贴执行即可，全程不接触代码仓库：

```bash
curl -fsSL "<维护者提供的更新链接>" | bash
```

::: warning 升级注意事项
- **更新链接有有效期**：默认数小时，最长 7 天；过期需请维护者重新签发。
- **目标版本需支持升级流程**：过旧的版本可能不含升级所需组件，需改为重新部署。
- 版本间被删除的旧文件在原地更新时不会被清理（通常无影响）。
- 升级会重启服务，会有短暂中断，建议在低峰期进行。
:::

## 删除环境

用途：不再使用的环境应及时销毁以停止计费。

```bash
# 仅删除云资源栈，保留数据
nexus-cli deploy down nexus-ai-test

# 删除云资源栈并清理所有数据（对象存储 / 数据表 / 队列）
nexus-cli deploy down nexus-ai-test --clean-data

# 跳过确认
nexus-cli deploy down nexus-ai-test --clean-data -y
```

::: warning --clean-data 不可恢复
加上 `--clean-data` 会连同数据一并删除，**无法恢复**。执行前请确认该环境的数据不再需要，或已另行备份。不带 `--clean-data` 时数据会保留，可用于日后重建。
:::

## 常见问题

| 现象 | 排查方向 |
|------|----------|
| 部署中途失败并留下半截资源 | 多为区域服务配额（EIP/VPC/NAT）不足或权限缺失；补齐后可用同一命令重新执行（会自动续跑，不重复建栈） |
| 首次构建/对话报 `AccessDeniedException` | 到部署区域的 Bedrock 控制台开通所需模型访问，见上文「部署前置要求」 |
| 找不到某个环境的状态 | 用 `nexus-cli deploy list` 确认环境前缀，再用 `deploy status <前缀>` 查看 |
| 某个服务异常 | 用 `nexus-cli service status` 或平台「服务状态」页面查看，必要时 `service restart` |

更多排障内容见[常见问题与排障](./faq-ops.md)。

## 相关章节

- [服务状态监控](./service-status.md) — 部署完成后查看各服务健康度、重启与日志
- [配置管理](./config-management.md) — 部署后调整运行时参数
