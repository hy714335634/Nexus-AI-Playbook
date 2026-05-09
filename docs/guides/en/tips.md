---
title: Tips & Best Practices
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - CLAUDE.md
    - README.md
  generated_at: 2026-05-09T01:54:38+00:00
  generated_by: docs-sync v2
---

# Tips & Best Practices

This page collects practical tips for working with Nexus-AI — how to write better requirements, pick the right model, shorten troubleshooting loops, and keep cloud costs in check.

## Pick the right model

Nexus-AI ships three Claude tiers on AWS Bedrock by default. Matching the tier to the task has a large impact on latency and cost:

| Scenario | Recommended tier | Default model ID |
|----------|------------------|------------------|
| Light classification, intent routing, simple Q&A | Lite (Haiku) | `us.anthropic.claude-haiku-4-5-20251001-v1:0` |
| Most day-to-day Agent builds and chats | Default (Sonnet) | `us.anthropic.claude-sonnet-4-5-20250929-v1:0` |
| Complex architecture design, long-context analysis | Pro (Opus) | `us.anthropic.claude-opus-4-5-20251101-v1:0` |

Override the default / lite / pro tiers in the `bedrock` section of `config/default_config.yaml`.

::: tip
Run the "planning" stages of the Agent Build workflow on Sonnet and only switch the final "code generation" stage to Opus. You'll get better quality/cost tradeoffs than running everything on one tier.
:::

## Write good natural-language requirements

The Agent Build workflow chains 8 specialized agents (requirements → architecture → agent design → prompt engineering → tool development → code generation → testing). The clearer your description, the less each downstream stage has to guess — and the less drift accumulates.

Recommended structure:

1. **Outcome**: what the Agent must be able to do (one sentence).
2. **Input**: what users will feed it (text, file types, URLs…).
3. **Output**: what you want back (structured JSON, Markdown report, charts…).
4. **Constraints**: data sources, compliance requirements, external tools it must use, rate limits.
5. **Examples**: one or two typical input/output pairs.

Compare these two prompts:

```text
❌ Build an Agent that analyzes stocks
✅ Build a stock analysis Agent: given an A-share ticker (e.g. 600519),
   pull the last 3 years of filings plus current quotes, run a DCF
   valuation, and return a Markdown report with valuation range,
   recommendation, and key risks.
```

## Use nexus-cli effectively

`nexus-cli` is the single entry point for Nexus-AI. A few combos cover most daily work:

| Need | Command |
|------|---------|
| Start API + Worker + Web in one go | `./nexus-cli service start` |
| Start MCP Server too (for IDE integration) | `./nexus-cli service start --mcp` |
| Restart API only (after router/service changes) | `./nexus-cli service restart --api` |
| Tail all logs | `./nexus-cli service logs -f` |
| Tail API logs only | `./nexus-cli service logs --api` |
| Tail MCP Server logs only | `./nexus-cli service logs --mcp` |
| Check service status | `./nexus-cli service status` |

::: warning
Initialization is a one-time action: `./nexus-cli init` creates the required DynamoDB tables, SQS queues, and S3 buckets. Running it again is safe but wastes API calls.
:::

## Expose Agents as MCP Tools to your IDE

Once the MCP Server is running, every Agent on the platform with `status=running` is automatically registered as an MCP tool callable from Kiro, Claude Code, or Cursor.

```bash
./nexus-cli service start --mcp
```

Add this to your IDE's MCP configuration:

```json
{
  "mcpServers": {
    "nexus-ai": {
      "url": "http://localhost:9000/mcp",
      "headers": {
        "Authorization": "Bearer <token printed on startup>"
      }
    }
  }
}
```

| Config file location | IDE |
|----------------------|-----|
| `~/.kiro/settings/mcp.json` | Kiro |
| `.mcp.json` (project-level) | Claude Code |

There are three ways to get the token: from the startup console, from the `.pids/mcp_token` file, or by pre-setting `NEXUS_MCP_TOKEN`. **For CI or scripted setups use the environment variable** so your client config doesn't need to update on every restart.

## A few multimodal chat gotchas

Chats can ingest images, Excel, Word, and PDF files directly — the platform parses and hands the content to the Agent. Before you rely on it:

- Point `multimodal_parser.aws.s3_bucket` in `config/default_config.yaml` at an **existing, writable** S3 bucket.
- Set `bedrock_region` to a region where you've enabled Claude model access.
- Mixing several large files in one message noticeably increases time-to-first-token. If the Agent only needs "a look," prefer screenshots or excerpts over an entire PDF.

## Dev mode vs SSO mode

| Dimension | Dev mode (default) | SSO mode |
|-----------|--------------------|----------|
| Login | Username/password (defaults: `admin` / `nexus`) | SAML 2.0 IdP |
| Use case | Local development, POCs, single-user trials | Enterprise or multi-user production |
| How to switch | `sso.enabled: False` | `sso.enabled: True` + IdP metadata URL |
| Extra dependency | None | `python3-saml` |

::: warning
Always change the default password before going to production. Update `user` and `password` under `nexus-ai.auth` in `config/default_config.yaml`, or enable SSO.
:::

## Common choices for one-click cloud deployment

`nexus-cli deploy up` uses CloudFormation to provision VPC + EC2 + Aurora + Valkey + ALB + CloudFront in one shot. A few flags worth thinking about up front:

| Flag | Guidance |
|------|----------|
| `--instance-type` | `c8i.2xlarge` is a good production default; smaller sizes work for POCs |
| `--region` | Pick a region where **you've enabled Bedrock access** (default `us-west-2`) |
| `--volume-size` | Default 150 GB; bump to 200+ if you'll accumulate logs or build artifacts |
| `--enable-sso` | Strongly recommended for multi-user production |
| `--enable-sandbox` | Turn on if you need Firecracker microVM isolation per Agent session |

When tearing an environment down, add `--clean-data` to also remove S3, DynamoDB, and SQS resources so they stop accruing charges.

## Observability & troubleshooting

- **Services won't start**: run `./nexus-cli service status` first to see which ports are listening, then `./nexus-cli service logs --api` / `--worker` to locate the failure.
- **Agent build stuck**: Agent Build uses an SQS-driven single-stage execution model — each message runs one workflow stage and then routes to the next. When it gets stuck, check Worker logs first.
- **Distributed tracing**: start Jaeger on demand:
  ```bash
  docker run -d --name jaeger \
    -p 16686:16686 -p 4317:4317 -p 4318:4318 \
    jaegertracing/all-in-one:latest
  ```
  Visit `http://localhost:16686` to inspect traces.
- **Frontend can't reach the API**: verify that Web(:3000), API(:8000), Bridge(:8001), and MCP(:9000) aren't colliding with other local services.

## Cost control checklist

| Action | Effect |
|--------|--------|
| Route everyday chats to `lite_model_id` (Haiku) | Substantial token-cost reduction |
| Stop services you don't need (e.g. MCP Server) | Cuts EC2 and bandwidth usage |
| Tear down test environments with `--clean-data` | Avoids orphaned S3/DDB/SQS charges |
| Disable or lower Jaeger/OTEL sampling in production | Reduces observability overhead |
| Enable Sandbox only when needed and size `--sandbox-pool-size` conservatively | Prevents idle microVM nodes from billing indefinitely |

## Next steps

- Walk through [Quickstart](../getting-started/quickstart.md) to run your first Agent end-to-end.
- Browse the [FAQ](../reference/faq.md) for deployment and runtime issues.
- Find a starting point close to your use case in the [Agent examples](../examples/index.md).
