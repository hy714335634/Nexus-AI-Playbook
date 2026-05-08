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

## Overview

Nexus-AI ships with a development-only username/password login that is fine for single-host demos but not for production. For real deployments, front the platform with SAML 2.0 so user lifecycle, group membership, password policy, and MFA are all owned by your IdP (Identity Provider). The built-in SP (Service Provider) is tuned against AWS IAM Identity Center but works with any standards-compliant SAML 2.0 IdP — Okta, Microsoft Entra ID, Google Workspace, OneLogin, Keycloak, and similar.

All SSO configuration lives in the `sso` section of `config/default_config.yaml`. Once enabled, the login page swaps the username/password form for a single "Sign in with SSO" button. Users are redirected to the IdP, return to the platform after authentication, and the platform issues a JWT that it stores in a cookie. Subsequent API calls are authorised by RBAC role (`admin` / `editor` / `viewer`).

## Prerequisites

Before you begin, make sure you have:

- A working SAML 2.0 IdP and admin rights to create a new application (SAML / Enterprise Application).
- A stable public hostname for the Nexus-AI service (for example `https://nexus.example.com`) — `localhost` will not work because the ACS URL in the SAML assertion must match exactly what the IdP has on file.
- The IdP's metadata either fetchable by URL or exportable as an XML file that you can place on the Nexus-AI host.
- Assertions from the IdP that can carry at least these fields (attribute names vary by IdP):
  - User email (used as the unique identifier)
  - Display name
  - A role or group label that maps to `admin` / `editor` / `viewer`

::: tip Best fit: AWS IAM Identity Center
The SP defaults are tuned for AWS IAM Identity Center — in particular, `RequestedAuthnContext` is disabled so the IdP does not refuse to issue an assertion because it cannot satisfy a `PasswordProtectedTransport exact` comparison. Other IdPs are usually unaffected.
:::

## Configuration steps

### 1. Create the SAML application on the IdP

These three fields are required on the IdP side:

| Field | Value |
|-------|-------|
| Entity ID (SP Entity ID / Audience) | `nexus-ai-sp` (any value, as long as it matches `sp_entity_id` below) |
| ACS URL / Reply URL | `https://<your-domain>/api/v2/auth/sso/acs` |
| Single Logout URL (optional) | `https://<your-domain>/api/v2/auth/sso/sls` |
| NameID format | `urn:oasis:names:tc:SAML:1.1:nameid-format:unspecified` |
| Binding | ACS uses `HTTP-POST`; SLS uses `HTTP-Redirect` |

In the application's "Attribute Mappings", provide at least the following three claims:

| SAML attribute | Purpose |
|---------------|---------|
| `email` or `http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress` | User email — used as the login identifier in Nexus-AI |
| `name` or `displayName` | Display name shown in the UI |
| `role` or a custom attribute | Role — one of `admin` / `editor` / `viewer` |

<!-- SCREENSHOT: saml-idp-app-setup -->

### 2. Fill in the `sso` section

Open `config/default_config.yaml` and add or edit the `sso` section:

```yaml
sso:
  enabled: true

  # IdP metadata — pick one of the two
  idp_metadata_url: https://portal.sso.us-east-1.amazonaws.com/saml/metadata/xxx
  # idp_metadata_xml: /etc/nexus-ai/idp-metadata.xml

  # SP settings
  sp_entity_id: nexus-ai-sp
  sp_acs_url: https://nexus.example.com/api/v2/auth/sso/acs
  sp_sls_url: https://nexus.example.com/api/v2/auth/sso/sls

  # Where to land the user after a successful login
  frontend_url: https://nexus.example.com

  # IdP logout URL (optional — set it to redirect the user to the IdP on logout)
  idp_logout_url: https://portal.sso.us-east-1.amazonaws.com/saml/logout

  # JWT lifetime (hours)
  jwt_expire_hours: 24

  # Email-domain allow-list — empty means no restriction
  allowed_email_domains:
    - example.com
    - partner.io
```

::: info Metadata: URL or XML — not both
Set only one of `idp_metadata_url` (preferred) and `idp_metadata_xml`. The URL variant fits IdPs that expose a public metadata endpoint (AWS IAM Identity Center, Okta, Entra ID). Use the XML variant for air-gapped IdPs — export the metadata and place the file at a path readable by the service.
:::

::: warning The SP callback URL must be reachable
`sp_acs_url` and `sp_sls_url` must be addresses the IdP can redirect the user's browser to (public internet or corporate intranet). Protocol, port, and path must match the IdP application exactly — any mismatch is rejected by the SP.
:::

### 3. Protect the JWT signing key

After a successful SSO round-trip the platform issues a JWT and stores it in an `access_token` cookie. All API workers must share the same signing key, otherwise users will be randomly logged out when a request is handled by a different worker. Resolution order:

1. Environment variable `AUTH_SECRET_KEY` (recommended — most reliable for container / EC2 deployments)
2. `auth.secret_key` in `config/default_config.yaml`
3. Fallback: a SHA-256 derivation of `auth.password` (single-host development only)

For production, set `AUTH_SECRET_KEY` to a random string of at least 32 bytes:

```bash
export AUTH_SECRET_KEY="$(openssl rand -hex 32)"
```

### 4. Configure the domain allow-list (optional)

If you want to accept only employees from specific email domains, list them in `allowed_email_domains`. Any email whose domain is not on the list is rejected at the ACS callback even if the IdP authentication succeeded. Leave the list empty to accept every IdP-authenticated user.

### 5. Enable global authentication

Verify that the global authentication guard is on in the `auth` section:

```yaml
auth:
  enforce_auth: true     # Must be true in production
```

With `false`, protected APIs are not enforced — the server only parses the JWT on a best-effort basis. That is meant for local debugging; do **not** use it in production.

### 6. Restart the service

```bash
./nexus-cli service restart
```

## Verification

Three checks, from shallow to deep.

### Step 1 — IdP metadata loads cleanly

Watch the startup log for a `Failed to load IdP metadata` warning. If you are using the URL mode, fetch the metadata directly from the service host:

```bash
curl -sS "$IDP_METADATA_URL" | head -20
```

Seeing an `<EntityDescriptor>` element confirms the network path works and the IdP is not filtering by source IP.

### Step 2 — The login page offers SSO only

Open `https://<your-domain>`. The login page should show a single "Sign in with SSO" button — the username/password form should be hidden.

<!-- SCREENSHOT: saml-login-button -->

### Step 3 — Full login round-trip

Click the SSO button. The browser is redirected to the IdP, you authenticate (possibly through MFA), and are redirected back to `sp_acs_url` and finally to `frontend_url`. In browser DevTools, verify:

- An `access_token` cookie is present and marked `HttpOnly=true`.
- In Settings → Profile, the email, display name, and role are the values the IdP asserted.

<!-- SCREENSHOT: saml-logged-in -->

## Troubleshooting

| Symptom | Likely cause | What to try |
|---------|--------------|-------------|
| The login page still shows the username/password form | `sso.enabled` did not take effect | Double-check the config file path and restart the service; confirm `/api/v2/auth/config` returns `sso_enabled: true` |
| Clicking the SSO button, the IdP returns `AuthnRequest is invalid` | `sp_entity_id` or `sp_acs_url` does not match the IdP registration | Compare character-by-character: protocol (https), hostname, port, path, and case must all match exactly |
| Back at the ACS endpoint, the platform returns `Invalid Signature` | IdP metadata was rotated but the platform did not reload it, or the assertion was not signed with the IdP certificate | Restart Nexus-AI to reload metadata; confirm "Sign response + Sign assertion" is enabled on the IdP application |
| `Invalid Audience` | IdP application Audience differs from `sp_entity_id` | Set the IdP Audience to `nexus-ai-sp` (or your custom value); both sides must be identical |
| Errors mentioning `RequestedAuthnContext` | IdP requires a specific authentication context | The platform already disables this by default; if the IdP still insists, ask the IdP admin to relax the policy or use a different IdP |
| Login succeeds but the user is immediately kicked out | Workers do not share `AUTH_SECRET_KEY`, so each signs/validates with a different key | Pin a single key via env var or `auth.secret_key` and restart every worker |
| After login the UI shows "User account is disabled" | The user was disabled by an admin | Re-enable the account in Settings → User management |
| A specific employee sees "Email domain not allow-listed" | `allowed_email_domains` does not cover their domain | Add the domain, or clear the field to allow all |
| Logout does not redirect to the IdP | `idp_logout_url` is not set, or the IdP does not support SLS | Set `idp_logout_url` as needed; if the IdP does not support SLS, users need to log out of the IdP session manually |
| Behind a reverse proxy (CloudFront / ALB), SAML complains about protocol mismatch | The backend sees HTTP but the external URL is HTTPS | The platform derives the scheme from `sp_acs_url`; ensure it is `https://...` and not `http://...` |

::: info A restart is required when the IdP changes
The platform loads IdP metadata once at startup and caches it in memory. After switching IdPs, rotating certificates, or changing attribute mappings, run `./nexus-cli service restart` to pick up the new metadata.
:::
