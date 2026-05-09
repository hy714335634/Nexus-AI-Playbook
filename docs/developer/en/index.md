---
title: Developer Guide
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - (chapter index — aggregated)
  generated_at: 2026-05-09T00:59:57+00:00
  generated_by: docs-sync v2
---

# Developer Guide

This chapter is for developers who **contribute code to the Nexus-AI repository** or **extend the platform with new agents, tools, or skills**. Every document takes the source repository as its sole source of truth and covers local development, system architecture, core runtimes, extension points, and internal storage models.

If you only want to use the product, return to **Getting Started** and the **User Manual**. The content here assumes you are already comfortable with Python, AWS Bedrock, and the basics of the Strands SDK.

## Onboarding

| Document | Summary |
|----------|---------|
| [Contributing](./contributing) | What to install locally, the branch / commit / PR workflow, code conventions, and how Python and dependencies are pinned. |

## Architecture & Runtime

| Document | Summary |
|----------|---------|
| [Architecture Overview](./architecture-overview) | Responsibilities, data flow, and deployment topology of the 5 core plus 2 optional services. |
| [API Layer](./api-layer) | Routes, authentication, database clients, and shared middleware of the FastAPI app under `api/v2/*`. |
| [Worker](./worker) | The consumer process that long-polls SQS and dispatches workflow tasks to `WorkflowEngine`. |
| [Stage Engine](./stage-engine) | The kernel that splits a workflow into agent-executed stages, with co-existing V1 and V2 implementations. |

## Extending the Platform

| Document | Summary |
|----------|---------|
| [Adding Agents](./adding-agents) | Define a new agent via a prompt template plus a runner script, and register it with the platform catalog. |
| [Adding Tools](./adding-tools) | Author and register the five tool types (builtin / generated / system / template / mcp). |
| [Adding Skills](./adding-skills) | Build skill packages that follow the Anthropic Agent Skills standard: write SKILL.md, import, and load at runtime. |

## Data & Prompts

| Document | Summary |
|----------|---------|
| [Session Storage](./session-storage) | How Aurora, Valkey, S3, and local cache cooperate to persist the full lifecycle of an agent conversation. |
| [Dynamic Prompt Build](./dynamic-prompt) | The two-stage prompt pipeline: the `PromptManager` baseline layer plus the `runtime_injection` dynamic layer. |
