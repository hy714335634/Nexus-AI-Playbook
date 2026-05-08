---
title: Overview
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - README.md
    - config/default_config.yaml
  generated_at: 2026-05-08T22:27:08+00:00
  generated_by: docs-sync v2
---

# Overview

Nexus-AI is not a self-contained system. Almost every capability it ships — model inference, authentication, storage, observability, IDE callability, sandbox isolation — comes from an integration with an external service. This chapter breaks each integration out into its own page: what it does, why it's mandatory or optional, how to configure it in `config/default_config.yaml`, how to verify it works, and where to look when something breaks.

If you are a fresh deployer, work through the list in the order **mandatory → recommended → optional**. If you already have a running environment and just want to add one capability (for example, turning on SSO or exposing agents to an IDE), jump straight to the relevant page.

## Integration tiers

Nexus-AI's integrations fall into three tiers:

| Tier | Meaning | Typical examples |
|------|---------|------------------|
| **Mandatory** | Core platform dependencies — the service cannot start or key features break without them | AWS Bedrock, Aurora, DynamoDB, Valkey, SQS, S3 |
| **Recommended** | Strongly advised for any production deployment; affects observability and compliance | OpenTelemetry, CloudWatch Logs, SAML SSO |
| **Optional** | Turn on as needed; each adds a self-contained capability | MCP Server, Sandbox, AgentCore, Bridge |

## Docs in this chapter

| Doc | Tier | What it covers |
|-----|------|----------------|
| [AWS Bedrock](./aws-bedrock) | Mandatory | The only entry point for model inference — full Claude Sonnet / Opus / Haiku lineup, default region `us-west-2`. |
| [Aurora PostgreSQL](./aurora) | Mandatory | The relational layer backing 12 core tables (projects, agents, sessions, messages, etc.). Serverless v2 in production. |
| [DynamoDB](./dynamodb) | Mandatory | The key-value layer backing 18 tables (tools, configs, event scheduling, audit logs, etc.). Table prefix `nexus_`. |
| [ElastiCache Valkey](./valkey) | Mandatory | Cache plus Stream event buffer — powers stream-relay resume and hot aggregates. |
| [AWS SQS](./sqs) | Mandatory | Async task queue that decouples API from Worker; carries agent builds, deployments and other long-running work. |
| [AWS S3 / S3 Vectors](./s3) | Mandatory | Object storage (artifacts, session attachments, multimodal content) and vector storage (tool/prompt/agent search). |
| [SAML 2.0 SSO](./sso) | Recommended | Connect AWS IAM Identity Center or any SAML IdP in place of the default username/password mode. |
| [OpenTelemetry](./opentelemetry) | Recommended | Ship traces via OTLP HTTP to Jaeger or ADOT Collector — full end-to-end agent tracing. |
| [CloudWatch](./cloudwatch) | Recommended | Centralised log collection and metric dashboards; enable alongside X-Ray in production. |
| [MCP Server](./mcp-server) | Optional | Expose platform agents as MCP Tools so Kiro, Claude Code, and Cursor can call them directly. |
| [MCP Client](./mcp-client) | Optional | Let agents call external MCP servers to extend their toolkit. |
| [Sandbox (Firecracker)](./sandbox) | Optional | Give each conversation its own microVM for high-risk tools — code execution, file ops, shell commands. |
| [AWS Bedrock AgentCore](./agentcore) | Optional | One-click deploy a finished agent as a standalone AgentCore Runtime. |
| [Bridge Multi-Connection](./bridge) | Optional | Connect an agent to your own servers through a single `curl`, up to 5 hosts at once. |
| [CloudFormation Deployment](./cloudformation) | Optional | `nexus-cli deploy` spins up a full stack: VPC + EC2 + Aurora + Valkey + ALB + CloudFront. |

## Single configuration entry point

Every integration's switches and parameters live in one file:

```bash
config/default_config.yaml
```

The top-level keys that map to integrations are:

| Key | Covers |
|-----|--------|
| `aws` | AWS credentials, region, Bedrock endpoint |
| `bedrock` | Model IDs, prompt caching, timeouts and retries |
| `aurora` | Aurora PostgreSQL connection info |
| `dynamodb` | DynamoDB table prefix and table name map |
| `valkey` | Valkey endpoint, port, SSL |
| `sqs` | SQS queue prefix and visibility timeouts |
| `nexus_ai.auth` / `nexus_ai.sso` | Username/password mode / SAML SSO |
| `nexus_ai.sandbox` | Sandbox switch, node pool, Firecracker paths |
| `nexus_ai.artifacts_s3_bucket` etc. | Per-purpose S3 buckets |
| `s3_vectors` | Vector bucket layout and embedding model |
| `observability` | OpenTelemetry switch, sampling, capture granularity |
| `logging` | Local log level and path |
| `agentcore` | Bedrock AgentCore execution role and runtime timeout |

::: tip
Cloud deployments run CloudFormation `UserData` which calls `update_config.py` to overwrite most fields automatically. For local development you usually only touch `aws.*` and `bedrock.model_id`.
:::

## The general enablement flow

Every integration page has its own step-by-step guide, but the pattern is almost always:

1. **Confirm prerequisites** — e.g. the AWS service is enabled for your account, the IAM role has the right permissions.
2. **Edit `config/default_config.yaml`** — flip the switch, paste in the endpoint or credential.
3. **Restart services** — `./nexus-cli service restart`.
4. **Verify** — each integration ships its own verification command or console entry point.
5. **Debug** — when it fails, check `logs/nexus_ai.log` first, then CloudWatch or Jaeger.

## End-to-end verification

The fastest way to check that all mandatory integrations are healthy:

```bash
# 1. Start every core service
./nexus-cli service start

# 2. Check status — API / Worker / Web should all be "running"
./nexus-cli service status

# 3. Run a built-in agent to exercise Bedrock, the databases, SQS and S3 together
source .venv/bin/activate
python agents/system_agents/magician.py -i "Hello"
```

If the agent responds, all six mandatory integrations — Bedrock + Aurora + DynamoDB + Valkey + SQS + S3 — are wired up correctly.

## Troubleshooting

| Symptom | Likely cause | What to try |
|---------|--------------|-------------|
| Service startup logs `AccessDenied` | EC2 IAM Instance Profile missing permissions | Match the "EC2 runtime IAM permissions" list in the README and add the missing actions |
| Agent reply fails with `Could not connect to the endpoint URL` | `aws.bedrock_region_name` is wrong or Bedrock isn't enabled in that region | Switch back to `us-west-2` or request model access for the target region in the AWS console |
| Login page shows `SSO metadata invalid` | `sso.idp_metadata_url` / `idp_metadata_xml` is wrong, or the IdP hasn't published metadata | Confirm the metadata URL returns XML via `curl`, and that the SP Entity ID matches what the IdP has |
| `service status` shows API running but Web won't load | Port 3000 is taken, or the Next.js build failed | `./nexus-cli service logs --web -f` to tail the latest error |
| MCP Server fails to start with `token required` | Neither `NEXUS_MCP_TOKEN` nor a generated token is available | Check `.pids/mcp_token`, or restart with `--mcp` to regenerate |
| Jaeger UI shows no traces | `observability.enabled = false`, or Jaeger is not running | Set it to `true` and start the Jaeger container (see the README "Tracing" section) |
| Sandbox nodes fail to launch | The EC2 instance type doesn't support KVM, or `firecracker_bin` path is wrong | Switch to a KVM-capable type such as c8i / c8id, and confirm `/opt/firecracker/firecracker` exists |

Each integration page ends with its own Troubleshooting section with more specific recipes.
