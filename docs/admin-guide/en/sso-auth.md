---
title: Login & SSO
sync:
  source_commit: 9d40a32f2bad2c7858b3ed0cfb4390e1bd603a30
  source_files:
    - api/v2/auth/**
    - config/app_manifest.yaml
  generated_at: 2026-07-12T12:57:22+00:00
  generated_by: docs-sync v2
---

# Login & SSO

The platform supports two ways to log in: **local accounts** (username + password) and **enterprise single sign-on (SSO)**. SSO is built on SAML 2.0 and integrates with identity providers (IdP) such as AWS IAM Identity Center, so employees log in with their existing corporate accounts instead of a separate one. After login, the platform issues a time-limited session token that authenticates every subsequent request.

::: info
Local-account mode works out of the box and suits first deployments and small teams; SSO requires you to wire up an IdP in the config before enabling it. The two can coexist — once SSO is on, the login page shows both an SSO entry and the local-account entry.
:::

## The Login Page

Users see the login page first. With SSO enabled, the login page adds an enterprise login entry; clicking it redirects to your IdP to authenticate and then returns to the platform. For local accounts, users just enter a username and password on the login page.

![login](/images/login.png)

## The Two Authentication Modes

| Mode | Best for | Account source | Password management |
|------|----------|----------------|---------------------|
| **Local account** | First deployment, small teams, intranet | Created in the platform (see "Users & Permissions") | Set and reset in the platform |
| **SSO (SAML 2.0)** | Existing corporate identity, unified login and central control | Provisioned automatically on first login | Managed by the IdP; not changeable on the platform |

::: warning
Login-related settings are driven by config files; changes take effect only **after a service restart**. Where to edit and how to restart are covered in "Config Management" and "Service Status".
:::

## Configuring SSO (SAML 2.0)

The platform acts as the service provider (SP) toward your IdP. Configuration is two steps: register the platform on the IdP side, then fill the IdP details into the platform config.

### Steps

1. In AWS IAM Identity Center (or another SAML 2.0 IdP), create a custom SAML application and obtain its **IdP metadata URL** (or download the metadata XML file).
2. In the IdP application, enter the platform's callback URLs:
   - **ACS (Assertion Consumer Service) URL** = your `sp_acs_url`, e.g. `https://&lt;your-domain&gt;/api/v2/auth/sso/acs`
   - **Single Logout URL** = your `sp_sls_url`, e.g. `https://&lt;your-domain&gt;/api/v2/auth/sso/sls`
   - **Entity ID (Audience)** = your `sp_entity_id`, default `nexus-ai-sp`
3. In the platform config's `sso` group, set the fields (see the table below): set `enabled` to `true` and fill in `idp_metadata_url`, `sp_acs_url`, `sp_sls_url`, and `frontend_url`.
4. To restrict which email domains may log in, set `allowed_email_domains`.
5. Restart the service to apply the config.
6. Open the login page to confirm the SSO entry appears; clicking it should redirect to the IdP and return successfully.

![settings-config](/images/settings-config.png)

### SSO Config Keys

| Key | Purpose | How it applies |
|-----|---------|----------------|
| `sso.enabled` | Whether SSO login is enabled | Restart required |
| `sso.idp_metadata_url` | IdP metadata URL (from AWS IAM Identity Center) | Restart required |
| `sso.idp_metadata_xml` | Path to a local IdP metadata XML file (alternative to the URL) | Restart required |
| `sso.sp_entity_id` | The platform's SP entity ID, default `nexus-ai-sp` | Restart required |
| `sso.sp_acs_url` | Assertion Consumer Service URL (IdP callback); must be an externally reachable full URL | Restart required |
| `sso.sp_sls_url` | Single Logout URL | Restart required |
| `sso.idp_logout_url` | Logout URL on the IdP side | Restart required |
| `sso.frontend_url` | Frontend URL to return to after a successful login | Restart required |
| `sso.allowed_email_domains` | Allowlist of email domains permitted to log in (empty = no restriction) | Restart required |
| `sso.jwt_expire_hours` | Session token lifetime in hours, default `24` | Restart required |

::: warning
The platform requires the IdP to sign SAML assertions and messages (otherwise login is rejected). Be sure to enable assertion signing in the IdP application, using the RSA-SHA256 signature algorithm.
:::

::: warning
When deployed behind a reverse proxy such as CloudFront / ALB, SSL terminates at the proxy and the backend sees an internal address. Set `sp_acs_url` to the **external HTTPS address users actually reach**, or the SAML callback will fail.
:::

### Email Domain Allowlist

`allowed_email_domains` restricts which email domains may log in via SSO. Leave it empty for no restriction; once you add one or more domains, only users whose email belongs to those domains can log in, and everyone else is rejected. This is useful for allowing only your company's domain and blocking outside accounts.

### Roles for SSO Users

Users who log in via SSO for the first time are provisioned automatically. Their role and permissions can be adjusted on the "Users & Permissions" page, following the same rules as local accounts — permissions are driven by policies. See "Users & Permissions" for details.

## Local-Account Mode

Without SSO, users log in with a username and password held in the platform. A default admin account ships built in (username `admin`, password `nexus`) — **change it immediately after the first deployment**. Day-to-day account creation, password changes, and disabling are all done on the "Users & Permissions" page.

| Key | Purpose | How it applies |
|-----|---------|----------------|
| `auth.user` | Built-in account username, default `admin` | Restart required |
| `auth.password` | Built-in account password, default `nexus` | Restart required |
| `auth.secret_key` | Session token signing key (optional; see Notes below) | Restart required |
| `auth.enforce_auth` | Whether login is enforced, default on (`true`) | Restart required |

::: warning
Setting `enforce_auth` to `false` **lets all unauthenticated requests through**. Use it only for local debugging; never turn it off in production.
:::

## Session Lifetime and Logout

After a successful login, the platform issues a time-limited session token that expires after **24 hours** by default; adjust it with `sso.jwt_expire_hours`. Once the token expires, users must log in again.

- **Logout**: signing out of the platform ends the current session.
- **Single logout**: with `sso.idp_logout_url` configured, an SSO user's logout also ends the session on the IdP side.
- **Disabled accounts**: once an account is disabled on the "Users & Permissions" page, it can no longer access the platform even with an unexpired token, and receives an "account is disabled" message.

## Customizing the Login Page

The login page's appearance comes from the app manifest; you can adjust branding and copy in the config:

| Key | Purpose |
|-----|---------|
| `app-manifest.login.title` | Login page title (empty = use the product name) |
| `app-manifest.login.subtitle` | Subtitle (empty = use the product tagline) |
| `app-manifest.login.background_style` | Background style: `gradient` / `image` / `solid` |
| `app-manifest.login.background_image_url` | Background image URL (used when `background_style` is `image`) |
| `app-manifest.login.show_copyright` | Whether to show copyright in the footer |
| `app-manifest.login.custom_notice` | Custom notice (e.g. maintenance or security message) |

## Companion AI Assistant

Every login and SSO switch lives in the config. On the "Config Management" page you can open the **Config Assistant** to help you locate the `sso` and `auth` groups and explain what each field does and whether it needs a restart. After editing the config, restart following the guidance in "Service Status" to apply the changes.

## Notes

- Any change to login-related config takes effect only **after a service restart**.
- Change the default `admin` / `nexus` credentials immediately after the first deployment.
- For multi-instance deployments, set a **shared** `auth.secret_key` explicitly; otherwise session tokens issued by one instance are not accepted by others, and users get repeatedly asked to log in again.
- SSO users' passwords are managed by the IdP; the platform cannot reset or change them.
- `sp_acs_url` must be the external HTTPS address users actually reach — especially important behind a reverse proxy.
- The IdP must sign assertions, or login will be rejected.
- Never disable `enforce_auth` in production.
