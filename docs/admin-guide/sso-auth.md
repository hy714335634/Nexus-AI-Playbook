---
title: 登录与 SSO
sync:
  source_commit: 9d40a32f2bad2c7858b3ed0cfb4390e1bd603a30
  source_files:
    - api/v2/auth/**
    - config/app_manifest.yaml
  generated_at: 2026-07-12T12:57:22+00:00
  generated_by: docs-sync v2
---

# 登录与 SSO

平台支持两种登录方式：**本地账号**（用户名 + 密码）和 **企业单点登录（SSO）**。SSO 基于 SAML 2.0，与 AWS IAM Identity Center 等身份提供商（IdP）对接，让员工用现有企业账号直接登录，不必单独建号。登录后系统会签发一个有时效的会话令牌，后续访问都凭它鉴权。

::: info
本地账号模式开箱即用，适合初次部署和小团队；SSO 需要你在配置里对接 IdP 后启用。两种方式可以并存——启用 SSO 后，登录页会同时给出 SSO 入口和本地账号入口。
:::

## 登录页

用户访问平台时首先看到登录页。启用 SSO 后，登录页会多出一个企业登录入口；点击后跳转到你的 IdP 完成认证，认证通过再跳回平台。本地账号则直接在登录页输入用户名和密码。

![login](/images/login.png)

## 两种认证模式

| 模式 | 适用场景 | 账号来源 | 密码管理 |
|------|----------|----------|----------|
| **本地账号** | 初次部署、小团队、内网环境 | 平台内创建（见「用户与权限」章节） | 平台内设置与重置 |
| **SSO（SAML 2.0）** | 已有企业身份体系、需统一登录与集中管控 | 首次登录时自动建档 | 由 IdP 管理，平台侧不可改 |

::: warning
本平台的登录相关设置以配置文件为准，改动后**需重启服务**才生效。修改与重启的入口见「配置管理」和「服务状态」章节。
:::

## 配置 SSO（SAML 2.0）

平台作为服务提供商（SP）与你的 IdP 对接。配置分为两步：先在 IdP 侧登记本平台，再在平台配置里填入 IdP 信息。

### 操作步骤

1. 在 AWS IAM Identity Center（或其他 SAML 2.0 IdP）里新建一个自定义 SAML 应用，拿到 **IdP 元数据地址**（或下载元数据 XML 文件）。
2. 在 IdP 应用里填入本平台的回调地址：
   - **ACS（断言消费）地址** = 你的 `sp_acs_url`，形如 `https://<你的域名>/api/v2/auth/sso/acs`
   - **单点登出地址** = 你的 `sp_sls_url`，形如 `https://<你的域名>/api/v2/auth/sso/sls`
   - **实体 ID（Audience）** = 你的 `sp_entity_id`，默认 `nexus-ai-sp`
3. 在平台配置的 `sso` 分组里设置各项（见下表）：把 `enabled` 设为 `true`，填入 `idp_metadata_url`、`sp_acs_url`、`sp_sls_url`、`frontend_url`。
4. 如需限制哪些邮箱域名可以登录，设置 `allowed_email_domains`。
5. 重启服务使配置生效。
6. 打开登录页确认出现 SSO 入口，点击后应能跳转到 IdP 并成功返回。

![settings-config](/images/settings-config.png)

### SSO 配置项

| 配置项 | 作用 | 生效方式 |
|--------|------|----------|
| `sso.enabled` | 是否启用 SSO 登录 | 需重启 |
| `sso.idp_metadata_url` | IdP 元数据地址（从 AWS IAM Identity Center 获取） | 需重启 |
| `sso.idp_metadata_xml` | 本地 IdP 元数据 XML 文件路径（与上一项二选一） | 需重启 |
| `sso.sp_entity_id` | 本平台作为 SP 的实体 ID，默认 `nexus-ai-sp` | 需重启 |
| `sso.sp_acs_url` | 断言消费地址（IdP 回调），须为外部可访问的完整地址 | 需重启 |
| `sso.sp_sls_url` | 单点登出地址 | 需重启 |
| `sso.idp_logout_url` | IdP 侧的登出地址 | 需重启 |
| `sso.frontend_url` | 登录成功后跳回的前端地址 | 需重启 |
| `sso.allowed_email_domains` | 允许登录的邮箱域名白名单（留空 = 不限制） | 需重启 |
| `sso.jwt_expire_hours` | 登录会话有效小时数，默认 `24` | 需重启 |

::: warning
平台要求 IdP 对 SAML 断言和消息签名（否则会拒绝登录）。在 IdP 应用里务必开启断言签名，签名算法用 RSA-SHA256。
:::

::: warning
部署在 CloudFront / ALB 等反向代理之后时，SSL 在代理层终止，后端看到的是内部地址。请把 `sp_acs_url` 设成**用户实际访问的外部 HTTPS 地址**，否则 SAML 回调会失败。
:::

### 邮箱域名白名单

`allowed_email_domains` 用于限制哪些邮箱域名可以通过 SSO 登录。留空表示不限制；填入一个或多个域名后，只有邮箱属于这些域名的用户才能登录，其余一律拒绝。适合只放行本公司域名、挡掉外部账号的场景。

### SSO 用户的角色

首次通过 SSO 登录的用户会自动建档。其角色与权限可在「用户与权限」页里调整，规则与本地账号一致——权限以策略为准。详见「用户与权限」章节。

## 本地账号模式

不启用 SSO 时，用户凭平台内的用户名和密码登录。默认内置一个管理员账号（用户名 `admin`、密码 `nexus`），**首次部署后请立即修改**。日常的账号创建、改密、停用都在「用户与权限」页完成。

| 配置项 | 作用 | 生效方式 |
|--------|------|----------|
| `auth.user` | 内置账号用户名，默认 `admin` | 需重启 |
| `auth.password` | 内置账号密码，默认 `nexus` | 需重启 |
| `auth.secret_key` | 会话令牌签名密钥（可选，见下方注意事项） | 需重启 |
| `auth.enforce_auth` | 是否强制登录，默认开启（`true`） | 需重启 |

::: warning
`enforce_auth` 设为 `false` 会**放行所有未登录访问**，仅用于本地调试，切勿在生产环境关闭。
:::

## 会话有效期与登出

登录成功后，平台签发一个有时效的会话令牌，默认 **24 小时**过期，可用 `sso.jwt_expire_hours` 调整。令牌过期后需要重新登录。

- **登出**：从平台内退出即结束当前会话。
- **单点登出**：配置了 `sso.idp_logout_url` 后，SSO 用户登出会一并结束 IdP 侧会话。
- **被停用的账号**：一旦在「用户与权限」页被停用，即使持有未过期的令牌也无法再访问，会收到「账号已禁用」提示。

## 自定义登录页

登录页的外观来自应用清单（app manifest），可在配置里调整品牌与文案：

| 配置项 | 作用 |
|--------|------|
| `app-manifest.login.title` | 登录页标题（留空则用产品名） |
| `app-manifest.login.subtitle` | 副标题（留空则用产品标语） |
| `app-manifest.login.background_style` | 背景样式：`gradient` / `image` / `solid` |
| `app-manifest.login.background_image_url` | 背景图地址（`background_style` 为 `image` 时使用） |
| `app-manifest.login.show_copyright` | 是否在页脚显示版权信息 |
| `app-manifest.login.custom_notice` | 自定义提示（如维护公告、安全提示） |

## 配套 AI 助手

登录与 SSO 的所有开关都在配置里。到「配置管理」页可打开**配置助手**，让它帮你定位 `sso` 与 `auth` 分组、说明每一项的作用与是否需重启。改完配置后按「服务状态」章节的指引重启即可生效。

## 注意事项

- 登录相关配置改动后一律**需重启服务**才生效。
- 首次部署后务必修改内置账号 `admin` / `nexus` 的默认密码。
- 多实例部署时，请在 `auth.secret_key` 显式设置**统一的密钥**，否则各实例签发的会话令牌互不认可，用户会被反复要求重新登录。
- SSO 用户的密码由 IdP 管理，平台侧无法重置或修改。
- `sp_acs_url` 必须是用户实际访问的外部 HTTPS 地址；反向代理后面尤其要注意。
- IdP 必须对断言签名，否则登录会被拒绝。
- 生产环境切勿关闭 `enforce_auth`。
