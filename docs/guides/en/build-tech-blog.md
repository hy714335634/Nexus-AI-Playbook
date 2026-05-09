---
title: Build a Tech Blog Generator
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - agents/generated_agents/tech_blog_generator_05b957e9/**
    - prompts/generated_agents_prompts/tech_blog_generator_05b957e9/**
  generated_at: 2026-05-09T01:57:33+00:00
  generated_by: docs-sync v2
---

# Build a Tech Blog Generator

This tutorial walks you through building a **tech blog generator agent** on Nexus-AI from scratch. Give it a topic and a few preferences — it will gather public technical material, analyze architecture and internals, summarize best practices, and produce a fully structured Markdown blog post saved to your local filesystem.

## What you'll get

- A **technical writing agent** callable in one-shot or interactive mode, turning a one-line request into a 1,000–4,000 word Markdown blog post.
- An automated **five-stage analysis pipeline**: material retrieval → architecture analysis → internals breakdown → best practices → blog generation.
- A deploy-ready agent code package you can ship to AgentCore Runtime.

## Prerequisites

| Item | Requirement |
| --- | --- |
| Nexus-AI account | Signed in, with permission to create projects |
| AWS credentials | Configured in the console and passing the credential check |
| Bedrock model | `global.anthropic.claude-sonnet-4-6` granted |
| IAM permissions | Bedrock invoke, AgentCore Runtime invoke, CloudWatch write |
| Network | Public internet access (the agent fetches technical material) |

::: tip
If Sonnet 4.6 is not yet enabled, request it from the Bedrock console's **Model access** page. It usually activates within a few minutes.
:::

## Approximate time

15–20 minutes.

---

## Step 1: Create a new agent project

1. Open the Nexus-AI console and go to **Agent Build** in the left nav.
2. Click **New project** and fill in:
   - **Project name**: `tech-blog-generator`
   - **Architecture**: `Single Agent`
   - **Description**: `Markdown blog post generator for any technical topic`
3. Click **Create**. The system assigns you a `Project ID`.

<!-- SCREENSHOT: create-project-dialog -->

**Expected result**: You are taken to the project detail page and see an empty **Build Workflow** panel in the `waiting for requirements` state.

## Step 2: Describe the agent

Paste the following into the **Requirement description** input:

```text
I need a tech blog generator agent that:
- Uses http_request to fetch public technical material (GitHub, official docs) about a given topic
- Analyzes it along three axes: architecture design, internals, applied practice
- Produces a fully structured Markdown blog post saved to local disk
- Accepts four parameters: target_audience, blog_style, content_length, focus_area
```

Click **Start build**.

<!-- SCREENSHOT: requirement-input -->

**Expected result**: The workflow advances to the **Prompt development** stage, with `prompt_development` highlighted in the stage rail.

## Step 3: Review and lock the prompt template

The platform auto-generates the agent's prompt template. Switch to the **Prompt** tab and verify these fields:

| Field | Expected value |
| --- | --- |
| `name` | `tech_blog_generator` |
| `production.model_id` | `global.anthropic.claude-sonnet-4-6` |
| `production.temperature` | `0.4` |
| `production.max_tokens` | `60000` |
| `conversation_manager.type` | `summarizing` |

Confirm that the `system_prompt` field contains the **Workflow (7-stage linear pipeline)** section.

::: info
Production uses a lower `temperature=0.4` — enough creativity for technical writing while maximizing factual accuracy.
:::

Click **Lock prompt**.

<!-- SCREENSHOT: prompt-review -->

## Step 4: Configure the tool set

Switch to the **Tools** tab and confirm that these 5 tools are attached:

| Tool | Type | Purpose |
| --- | --- | --- |
| `http_request` | Built-in | Fetch GitHub / official docs |
| `file_read` | Built-in | Read local reference files |
| `current_time` | Built-in | Timestamp the blog |
| `calculator` | Built-in | Count words / measure elapsed time |
| `file_writer` | Auto-generated | Write the blog to the `.cache/` directory |

If `file_writer` shows as **pending**, click **Auto-generate tool**. The platform derives it from the prompt requirements.

<!-- SCREENSHOT: tool-list -->

**Expected result**: All 5 tools show **Ready**.

## Step 5: Generate agent code

Switch to the **Code** tab and click **Generate code**. The platform produces a Python script named `tech_blog_generator.py`. Open the preview and verify it contains:

```text
├─ Telemetry setup (OpenTelemetry)
├─ BedrockAgentCoreApp instance
├─ create_agent_from_prompt_template(...) to build the agent
├─ @app.entrypoint async def handler(...)
└─ __main__: supports -i / --interactive / container mode
```

Click **Download code package** to get a zip file.

<!-- SCREENSHOT: generated-code -->

## Step 6: Smoke-test locally

Unzip the package in a local terminal and run the agent in one-shot mode:

```bash
python tech_blog_generator.py -i "Write a LangChain introduction for junior developers"
```

**Expected output** (excerpt):

```text
[Config] Audience: junior developers | Style: intro | Length: standard | Focus: general
[Stage 1/5] Retrieving LangChain technical material...
[Stage 2/5] Analyzing LangChain system architecture...
[Stage 3/5] Explaining LangChain internals...
[Stage 4/5] Summarizing applied best practices...
[Stage 5/5] Generating the blog post...
[Summary] Words: ~2,100 | Config: junior/intro/standard | Source: online | Elapsed: ~42s
```

Open `.cache/&lt;agent_id&gt;/&lt;session_id&gt;/` — you should see a `tech_blog_&lt;timestamp&gt;.md` file.

<!-- SCREENSHOT: local-run -->

::: warning
If `[Stage 1/5]` prints `switching to offline mode`, the network could not reach the target site. The agent falls back to pretraining knowledge and the disclaimer at the end of the post will mark the source as **offline**.
:::

## Step 7: Deploy to AgentCore Runtime

Back in the Nexus-AI console, open the project's **Deploy** tab:

1. Select runtime environment: `production`.
2. Confirm the model: `global.anthropic.claude-sonnet-4-6`.
3. Click **Deploy**.

When the deploy finishes you get a callable **Agent Runtime endpoint**.

<!-- SCREENSHOT: deploy-panel -->

## Verify

In the **Test** tab, submit this payload:

```json
{
  "prompt": "Generate an in-depth technical blog on the Kubernetes scheduler internals, for mid-to-senior developers, 3000+ words"
}
```

**Expected**:

- The streaming response prints the five pipeline stage markers in order.
- The final summary reports a word count ≥ 3,000.
- A `.cache/.../tech_blog_*.md` file is created containing all 10 sections: title, abstract, table of contents, introduction, architecture breakdown, internals, best practices, conclusion, source references, and disclaimer.
- The post ends with the standard disclaimer (generation time, source type, knowledge cutoff).

If any check fails, open the **Logs** tab and inspect the corresponding stage.

## Next steps

- Read [Build a Hermes Analyst Agent](./build-hermes-analyst.md) for the single-framework variant of this pattern.
- Read [Agent build tips](./tips.md) for practical advice on prompt tuning and tool-set orchestration.
- Read [Create an agent](../../using/en/create-agent.md) for the full Build Workflow V2 lifecycle.
