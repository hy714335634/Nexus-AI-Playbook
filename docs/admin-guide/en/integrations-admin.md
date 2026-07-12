---
title: External Integrations
sync:
  source_commit: 9d40a32f2bad2c7858b3ed0cfb4390e1bd603a30
  source_files:
    - api/v2/routers/connectors.py
    - config/data_connector.yaml
    - config/mcp/**
  generated_at: 2026-07-12T13:02:06+00:00
  generated_by: docs-sync v2
---

# External Integrations

「Business Integration」brings the platform's connections to external systems into one place: connect data sources, keep access credentials in a central vault, and manage reusable template assets and business directives. As an admin, this is where you register data connections for your team, maintain keys, and control who can see and use them.

The page offers four sub-modules:

| Sub-module | Purpose | Current sample count |
|------------|---------|----------------------|
| **Asset Templates** | Centrally manage reusable templates (PPT / Word / Excel / HTML / PDF, etc.) | 0 (no collections yet) |
| **Data Connections** | Register external data sources (databases, warehouses, object storage, vector stores, etc.) | 0 (no connections yet) |
| **Key Management** | Centrally store sensitive credentials such as API keys and database credentials | 2 (bound) |
| **Business Directives** | Maintain global business directive nodes for agents | 0 (global) |

## Opening Business Integration

Sidebar「Business Integration」→ go to `/integration`. The page presents the four sub-modules as cards at the top; click any card to enter its management page.

![integration-connectors](/images/integration-connectors.png)

## Data Connections

「Data Connections」lets you register external data sources as **connectors**, bind access credentials, and make them available for agents to query at runtime. The platform ships safe defaults for every source type (read-only, row limits, dangerous-statement blocking, field masking), so you don't have to harden each connection by hand.

![integration-connectors](/images/integration-connectors.png)

### Supported Source Types

| Category | Source types |
|----------|--------------|
| Relational databases | MySQL, PostgreSQL |
| Data warehouses (OLAP) | Amazon Redshift, Snowflake, Google BigQuery |
| Spreadsheets | Google Sheets |
| Object storage | Amazon S3 |
| NoSQL | Amazon DynamoDB |
| HTTP endpoints | HTTP API |
| Vector search | Amazon OpenSearch Serverless, Amazon S3 Vectors, Bedrock Knowledge Base |

### Safe Defaults

When you create a connection, the platform applies a set of global default parameters. The most important ones for query sources are:

| Item | Default | Description |
|------|---------|-------------|
| Max rows per query | 1000 | Prevents pulling too much data at once |
| Query timeout | 30 seconds | Aborts automatically on timeout |
| Write operations | Off | Read-only by default; writes not allowed |
| DDL operations | Off | Structural changes (create/alter table, etc.) blocked by default |
| Dangerous-statement blocking | `DROP`, `TRUNCATE`, `ALTER` | Queries hitting these keywords are rejected |

**Field masking**: result columns matching the rules below are masked automatically to avoid leaking sensitive values.

| Column match | Masking strategy |
|--------------|------------------|
| `*password*` | Replace |
| `*secret*` | Replace |
| `*token*` | Partial |

> Four masking strategies are available: partial, hash, replace, and null.

Other defaults: relational databases use a connection pool (5 connections by default, up to 10 overflow, 30-second acquire timeout, recycled every 3600 seconds); S3 reads files up to 100MB and supports CSV / JSON / JSONL / Parquet / TXT / XLSX / YAML, with presigned download links valid for 1 hour; HTTP API has a 30-second request timeout, up to 3 retries, and a 10MB response cap; vector search returns the Top-10 by default with a 0.7 similarity threshold. Data-connection audit logging is on by default and retained for 90 days.

### Adding a Data Connection

1. On the「Data Connections」page, click the add button in the top-right to open the connector creation form.
2. Enter a connector **name**, choose a **source type**, and fill in the connection parameters that type requires (e.g. database host / port / name, S3 bucket and prefix, HTTP base URL).
3. Under **Authentication**, bind a stored key (see "Key Management" below), or create a credential as prompted.
4. Set access control (visibility) and save.

Once saved, use the search box (placeholder「Search connectors...」) to find connectors by name.

### Testing a Connection and Viewing the Schema

After a connection is created, verify it before handing it to agents:

- **Test Connection** — actually connects to the source and returns success or a specific error. Test first so you don't discover connectivity issues only at agent runtime.
- **View Schema** — fetches the source's tables / fields (a file list for S3, an index list for vector stores) so you can confirm the credential's permissions and visible scope match expectations.

### Parent and Child Connectors

For hierarchical sources like S3, you can create **child connectors** under a parent by sub-path, splitting different directories / prefixes into independently authorizable units. A parent's「Child Connectors」entry lists all connectors beneath it.

### Visibility and Permissions

Data connections are governed by resource permissions:

- **Admins** can view and manage all connectors platform-wide for centralized governance.
- **Regular users** only see connectors they created, ones shared platform-wide, and those made visible through sharing or resource groups.
- A connector can be **shared** with specific users or resource groups; deleting a connector also clears all of its share records.

::: info
When a connector is created, ownership is forced to the current authenticated identity and cannot be spoofed as someone else. Viewing / using a connection requires the corresponding read permission; modifying / deleting requires owner or editor permission.
:::

## Key Management

「Key Management」centrally stores the sensitive credentials needed to reach external systems (API keys, database usernames and passwords, cloud credentials, etc.). Register a key once and it can be **referenced** by data connections and by tools that require credentials — no repeating plaintext in multiple places.

![integration-keys](/images/integration-keys.png)

The top-right has **New Key**, and each key card in the list shows its name, type, reference count, and a description snippet; the search box at the top (placeholder「Search keys...」) finds keys by name.

### Key Types

The platform ships with these standard key types; the relevant fields appear automatically based on the type you pick:

| Type | Purpose | Main fields |
|------|---------|-------------|
| **API Key** | Access key for a third-party API | API Key |
| **Database Credentials** | Connection for relational databases like MySQL / PostgreSQL | Host, Port, Database, Username, Password |
| **Bearer Token** | OAuth / Bearer Token auth | Token |
| **AWS Credentials** | AWS Access Key / Secret Key auth | Access Key ID, Secret Access Key, Session Token (optional) |
| **GCP Service Account** | Google Cloud service account (for BigQuery / Google Sheets) | Service Account JSON |
| **OAuth 2.0** | OAuth 2.0 client credential auth | Client ID, Client Secret, Token URL (optional) |
| **Custom** | Credentials with a non-fixed structure | Fields you add dynamically |

### Creating a Key

1. Click **New Key** in the top-right.
2. Choose the key **type** and fill in the fields it requires (password fields are entered masked).
3. Enter a **name** and **description** for the key.
4. Set **visibility**: private / shared / public.
5. To let a specific tool use the key automatically, bind the corresponding tool here.
6. Save.

::: warning
A key's values are encrypted on save and never shown again in the UI. Lists and details only show metadata (name, type, description, reference count), never the secret itself. To rotate a credential, edit the key and re-enter it.
:::

### Visibility and Sharing

- **Private** — visible and usable only to the creator.
- **Shared / Public** — lets other members reference it read-only within the visibility scope; a read-only user (viewer) can use it but not modify it.
- Write actions — modify, delete, re-share — require editor or owner permission.
- **Admins** can view all keys platform-wide for governance.

### Binding Keys to Tools

Some tools need external credentials at runtime. In a key's binding settings you can associate the tools that require a key, and those tools then use the key automatically when called — no plaintext in the tool config. A key card's "reference count" reflects how many places currently use it.

### Key Storage and Security

Keys are stored in AWS Secrets Manager by default (secret names carry the shared prefix `nexus-ai/keys/`), with support for a specific region and a custom KMS encryption key. Only development environments may switch to local storage.

::: warning
A key is an access credential. Always use Secrets Manager storage in production; before deleting a key, confirm no connector or tool still references it (check the "reference count") so the referencing side doesn't fail at runtime.
:::

## Asset Templates

「Asset Templates」centrally manages reusable template files (PPT / Word / Excel / HTML / PDF, images, etc.) for generation tasks to apply. The left side filters by ownership (All / Created by me / Shared with me) and category (PPT / Excel / Docs / HTML / Other); the center is a drag-and-drop upload area (**Choose Files** / **Choose Folder**); the top-right **✨ AI** button helps generate or organize templates with AI assistance.

![integration-templates](/images/integration-templates.png)

## Business Directives

「Business Directives」maintains global business directive nodes for agents. The top-right offers **New Node**, **Create Architecture from Natural Language**, **Import from Document**, and **Refresh**; the floating buttons in the bottom-right offer **Manual Create** and **AI Create** — describe your intent in natural language and let AI build the directive structure for you.

![integration-directives](/images/integration-directives.png)

## MCP Services

Consuming and managing external tool servers (MCP) is a separate capability, reached via sidebar「Capability Center」→「MCP Services」; see *MCP Service Management*. It is also an external integration, but registering, enabling, and testing connections all happen in the Capability Center, not on this page.

## Notes

- Data connections are **read-only** by default and block dangerous statements like `DROP` / `TRUNCATE` / `ALTER`; if you genuinely need write access, assess the impact before adjusting individual connections.
- Fields matching the masking rules (including `password` / `secret` / `token`) are masked automatically — keep this in mind when troubleshooting data issues.
- A key's plaintext is never shown after save, and deletion is irreversible; check the "reference count" before deleting to confirm nothing uses it.
- Data-connection audit logs are retained for 90 days by default, useful for tracing who queried which source and when.
- Test a new connection before enabling it, so you don't expose unreachable sources or bad credentials only at agent runtime.
