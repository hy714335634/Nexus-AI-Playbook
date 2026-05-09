---
title: Reference
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - (chapter index — aggregated)
  generated_at: 2026-05-09T01:50:29+00:00
  generated_by: docs-sync v2
---

# Reference

This chapter is Nexus-AI's **lookup documentation**: commands, configuration keys, environment variables, APIs, deployment parameters, IAM policies, the model catalog, glossary, and FAQ. Every entry is sourced directly from the repository — nothing is inferred.

When you need to answer concrete questions like "what is this flag called?", "what does this endpoint return?", or "how do I fix this error?", jump straight to the matching page below.

## Documents

| Document | Summary |
|----------|---------|
| [nexus-cli Commands](./cli-commands) | Every `nexus-cli` subcommand, flag, and output format — the kubectl-style operational entry point. |
| [Configuration Options](./config-options) | Every key, type, and default in the YAML files under `config/`, plus what each one controls. |
| [Environment Variables](./environment-variables) | All environment variables read at startup, override precedence, and default values. |
| [API Endpoints](./api-endpoints) | Request and response bodies and auth requirements for every Platform API v2 HTTP route. |
| [Deployment Parameters](./deploy-params) | Exhaustive parameters for all five deployment modes: local, EC2, CloudFormation, Firecracker, and AgentCore. |
| [IAM Policies](./iam-policies) | Minimum-privilege JSON policies for the Deployer and EC2 Runtime identities, with per-field explanations. |
| [Model Catalog](./model-catalog) | Bedrock model entries, providers, capabilities, and fallback rules defined in `model_catalog.yaml`. |
| [Glossary](./glossary) | Canonical definitions for every term that appears in docs, code, CLI, and YAML keys. |
| [FAQ & Troubleshooting](./faq) | Common issues grouped by lifecycle stage, a symptom-keyword index, and step-by-step fixes. |
