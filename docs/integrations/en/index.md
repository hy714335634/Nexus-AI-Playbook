---
title: Integrations
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - (chapter index — aggregated)
  generated_at: 2026-05-08T22:43:13+00:00
  generated_by: docs-sync v2
---

# Integrations

Nexus-AI is not a self-contained system. Almost every capability it ships — model inference, authentication, data storage, external protocols — comes from an integration with an external service. This chapter breaks each integration out into its own page: what it does, why it's mandatory or optional, how to configure it, how to verify it works, and where to look when something breaks.

If you are a fresh deployer, start from the [Overview](./overview) and work through the integrations in the order **mandatory → recommended → optional**. If you already have a running environment and just want to add one capability (for example, turning on SSO or exposing agents to an IDE), jump straight to the relevant page.

## Docs in this chapter

| Doc | What it covers |
|-----|----------------|
| [Overview](./overview) | Classifies every integration into **mandatory / recommended / optional** and gives you a single decision table. |
| [AWS Bedrock](./aws-bedrock) | The default and only out-of-the-box model inference gateway, covering Claude, Nova, Llama, Mistral, DeepSeek, Qwen and more. |
| [MCP Clients](./mcp-clients) | Let platform agents call tools on external MCP servers, with stdio, SSE, and Streamable HTTP transports. |
| [MCP Server](./mcp-server) | The reverse direction: expose running platform agents as MCP tools so Claude Code, Kiro, Cursor and other clients can call them. |
| [SSO (SAML 2.0)](./sso-saml) | Connect an enterprise IdP over SAML 2.0 to replace username/password login, with RBAC role mapping baked in. |
| [Data Stores](./data-stores) | The four-piece data layer — Aurora PostgreSQL, DynamoDB, ElastiCache Valkey, and SQS — and which one handles relational, key-value, cache, and queue workloads. |
