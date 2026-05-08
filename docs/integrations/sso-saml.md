---
title: SSO (SAML 2.0)
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - api/v2/auth/**
  generated_at: 2026-05-08T22:38:03+00:00
  generated_by: docs-sync v2
---

# SSO (SAML 2.0)

## 概述

Nexus-AI 的默认登录是开发模式的账号密码，只适合单机或演示环境。生产部署建议通过 SAML 2.0 接入企业统一身份源，把用户生命周期、分组、密码策略、MFA 完全交给 IdP（Identity Provider）托管。平台内置的 SP（Service Provider）参考 AWS IAM Identity Center 实现，对其它主流 IdP（Okta、Microsoft Entra ID、Google Workspace、OneLogin、Keycloak 等）同样兼容，只要它们支持标准 SAML 2.0 断言即可。

SSO 的所有配置落在 `config/default_config.yaml` 的 `sso` 小节。启用后，前端登录页会把「账号密码」按钮替换为「使用 SSO 登录」，用户被重定向到 IdP 完成认证后回到平台，平台签发 JWT 写入 Cookie，后续所有 API 请求按 RBAC 角色（admin / editor / viewer）鉴权。

## 启用前提

开始前请确认：

- 一个可用的 SAML 2.0 IdP，并具备创建应用（SAML 应用 / Enterprise Application）的管理员权限。
- Nexus-AI 服务的对外可达地址已经确定（例如 `https://nexus.example.com`），不能再用 `localhost`——SAML 断言里的回调 URL 必须与 IdP 登记的完全一致。
- IdP 的 metadata 可以通过 URL 公开拉取，或者你能拿到一份 XML 文件放到 Nexus-AI 服务能读的目录。
- IdP 的断言里至少能签发以下字段（字段名视 IdP 而定，后文会说如何配置）：
  - 用户邮箱（作为用户唯一标识）
  - 用户显示名
  - 角色标签或分组名（映射到 `admin` / `editor` / `viewer`）

::: tip 和 AWS IAM Identity Center 最贴合
平台 SP 默认参数是针对 AWS IAM Identity Center 调优过的——禁用了 `RequestedAuthnContext`，避免 IdP 因不支持 `PasswordProtectedTransport exact` 比较而拒绝签发断言。其它 IdP 通常不会受影响。
:::

## 配置步骤

### 1. 在 IdP 侧创建 SAML 应用

以下三项是 IdP 创建应用时必填的：

| 字段 | 值 |
|------|---|
| Entity ID（SP Entity ID / Audience）| `nexus-ai-sp`（可自定义，与步骤 2 中 `sp_entity_id` 一致即可）|
| ACS URL / Reply URL | `https://<你的域名>/api/v2/auth/sso/acs` |
| Single Logout URL（可选） | `https://<你的域名>/api/v2/auth/sso/sls` |
| NameID 格式 | `urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified` |
| Binding | ACS 使用 `HTTP-POST`；SLS 使用 `HTTP-Redirect` |

在应用的「属性映射 / Attribute Mappings」里配置断言字段，至少提供以下三个：

| SAML 属性名 | 说明 |
|------------|------|
| `email` 或 `http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress` | 用户邮箱，作为 Nexus-AI 的登录标识 |
| `name` 或 `displayName` | 在前端显示的用户名 |
| `role` 或自定义属性 | 角色名，取值 `admin` / `editor` / `viewer` |

<!-- SCREENSHOT: saml-idp-app-setup -->

### 2. 填写 `sso` 小节

打开 `config/default_config.yaml`，新增或修改 `sso` 小节：

```yaml
sso:
  enabled: true

  # IdP metadata —— 二选一
  idp_metadata_url: https://portal.sso.us-east-1.amazonaws.com/saml/metadata/xxx
  # idp_metadata_xml: /etc/nexus-ai/idp-metadata.xml

  # SP 配置
  sp_entity_id: nexus-ai-sp
  sp_acs_url: https://nexus.example.com/api/v2/auth/sso/acs
  sp_sls_url: https://nexus.example.com/api/v2/auth/sso/sls

  # 登录完成后跳转的前端地址
  frontend_url: https://nexus.example.com

  # IdP 的单点登出地址（可选，填了则登出时会把用户重定向到 IdP）
  idp_logout_url: https://portal.sso.us-east-1.amazonaws.com/saml/logout

  # JWT 过期时间（小时）
  jwt_expire_hours: 24

  # 邮箱域名白名单，空数组表示不限制
  allowed_email_domains:
    - example.com
    - partner.io
```

::: info metadata 二选一
`idp_metadata_url`（优先）和 `idp_metadata_xml` 只需填一个。URL 模式适合 IdP 公开 metadata endpoint 的场景（AWS IAM Identity Center、Okta、Entra ID）；XML 模式适合内网隔离的 IdP，只需把导出的 metadata 文件放到服务能读的路径即可。
:::

::: warning SP 回调地址必须对外可达
`sp_acs_url` / `sp_sls_url` 必须是 IdP 能把用户浏览器重定向到的公网（或企业内网）地址，且协议/端口/路径与 IdP 应用里登记的完全一致。任何差异都会被 SP 侧拒绝。
:::

### 3. 保护 JWT 签名密钥

SSO 成功后，平台会签发 JWT 写入 `access_token` Cookie。JWT 的签名密钥必须在所有 API worker 之间保持一致，否则会出现「登录后随机被踢出」的问题。优先级：

1. 环境变量 `AUTH_SECRET_KEY`（推荐，容器/EC2 部署最稳）
2. `config/default_config.yaml` 中 `auth.secret_key`
3. 若均未配置，则根据 `auth.password` 的 SHA-256 哈希派生（仅适用于单机开发）

生产环境请显式设置 `AUTH_SECRET_KEY` 为一个 32 字节以上的随机字符串：

```bash
export AUTH_SECRET_KEY="$(openssl rand -hex 32)"
```

### 4. 配置用户域名白名单（可选）

如果希望只允许特定邮箱域名的员工登录，把这些域名写进 `allowed_email_domains`。所有不在白名单里的邮箱，即使在 IdP 侧认证成功，也会在 ACS 回调中被拒绝。留空即对所有通过 IdP 认证的用户开放。

### 5. 启用全局认证拦截

在 `config/default_config.yaml` 的 `auth` 小节确认全局拦截已打开：

```yaml
auth:
  enforce_auth: true     # 生产环境必须 true
```

设为 `false` 时，后端不会对受保护 API 强制校验 JWT，只会「尽力解析」，方便本地调试，**不要**在生产环境使用。

### 6. 重启服务

```bash
./nexus-cli service restart
```

## 验证

从浅到深三步确认 SSO 接入跑通。

### 步骤 1：IdP metadata 可解析

观察服务启动日志，确认没有 `Failed to load IdP metadata`。如果是 URL 模式，从服务主机直接请求一次：

```bash
curl -sS "$IDP_METADATA_URL" | head -20
```

能看到 `<EntityDescriptor>` 就说明网络可达、IdP 未限制来源 IP。

### 步骤 2：登录页出现 SSO 入口

打开前端 `https://<你的域名>`，登录页应该只保留「使用 SSO 登录」按钮，不再显示账号密码表单。

<!-- SCREENSHOT: saml-login-button -->

### 步骤 3：完成一次完整登录

点击「使用 SSO 登录」后，浏览器被重定向到 IdP。完成认证（可能需要 MFA）后跳回 `sp_acs_url`，最终落在 `frontend_url`。在浏览器开发者工具中检查：

- `Cookie` 里存在 `access_token`，`HttpOnly=true`
- 进入「设置 → 个人信息」，邮箱、显示名、角色都来自 IdP 断言

<!-- SCREENSHOT: saml-logged-in -->

## 故障排查

| 现象 | 可能原因 | 建议操作 |
|------|---------|---------|
| 登录页仍显示账号密码表单 | `sso.enabled` 没有生效 | 确认配置文件路径、重启服务，观察 `/api/v2/auth/config` 返回是否 `sso_enabled: true` |
| 点击 SSO 按钮跳转 IdP 后报 `AuthnRequest is invalid` | `sp_entity_id` 或 `sp_acs_url` 与 IdP 登记的不一致 | 逐字符比对：协议（https）、域名、端口、路径、大小写都必须完全相同 |
| IdP 认证通过后跳回 ACS 报 `Invalid Signature` | IdP 元数据被替换但平台侧未刷新，或断言未用 IdP 证书签名 | 重启 Nexus-AI 服务让 metadata 重新加载；确认 IdP 应用开启了「签名响应 + 签名断言」|
| `Invalid Audience` | IdP 应用的 Audience 与 `sp_entity_id` 不一致 | 把 IdP 侧 Audience 改成 `nexus-ai-sp`（或自定义值），两侧严格相同 |
| `RequestedAuthnContext` 相关错误 | IdP 只接受特定身份验证上下文 | 平台默认已关闭该特性；若 IdP 仍强制要求，联系 IdP 管理员放宽策略或改用其它 IdP |
| 登录成功但立即被踢出 | 多 worker 间 `AUTH_SECRET_KEY` 不一致，各自签 / 验 JWT | 统一通过环境变量或 `auth.secret_key` 指定同一个密钥，重启所有 worker |
| 登录后前端显示「User account is disabled」 | 用户在 Nexus-AI 里被管理员禁用 | 进入「设置 → 用户管理」把该账号恢复为启用状态 |
| 特定员工报「邮箱域名不在白名单」 | `allowed_email_domains` 没覆盖该域名 | 把域名加到白名单或清空该字段 |
| 登出后没有跳回 IdP | `idp_logout_url` 未配置，或 IdP 不支持 SLS | 按需填入 `idp_logout_url`；若 IdP 不支持，用户需要手动登出 IdP 会话 |
| 通过反向代理（CloudFront / ALB）后 SAML 报协议不匹配 | 后端看到的是 HTTP，但外部是 HTTPS | 平台已按 `sp_acs_url` 的 scheme 判断协议；请确认 `sp_acs_url` 填的是 `https://...` 而不是 `http://...` |

::: info 换 IdP 后必须重启
平台在启动时一次性加载 IdP metadata 并缓存在内存。更换 IdP、轮换证书、修改属性映射后，都需要执行 `./nexus-cli service restart` 让新 metadata 生效。
:::
