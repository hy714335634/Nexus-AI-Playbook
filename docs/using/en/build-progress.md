---
title: Build Progress
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - web/src/app/(authed)/projects/**
    - worker/handlers/build_handler*.py
  generated_at: 2026-05-08T15:00:18+00:00
  generated_by: docs-sync v2
---

# Build Progress

The Build Progress page shows every step of an Agent build in real time. You are automatically redirected here after submitting an Agent creation request.

![Build Progress](/images/build-progress.png)

## Build Pipeline Overview

Each Agent is built by a team of **8 specialized Builder Agents** working together across **9 stages**. The whole flow is modeled after a software development pipeline:

```
Your requirement → [Orchestration] → [Requirements] → [Architecture] → [Design] → [Prompt] → [Tools] → [Code] → [Review] → [Deployment] → Ready-to-use Agent
```

The output of each stage is automatically passed as input to the next, forming a complete build chain.

### The Nine Stages in Detail

| # | Stage | Responsible Agent | Core Work | Deliverables |
|---|-------|-------------------|-----------|--------------|
| 1 | **Orchestration** | Orchestrator Agent | Analyze requirement complexity, draft the build plan, route tasks | Build plan, task routing scheme |
| 2 | **Requirements** | Requirements Agent | Turn natural-language requests into structured specs, fill in missing info | Detailed requirements doc (feature list, I/O definitions, constraints) |
| 3 | **Architecture** | Architecture Agent | Design the Agent's technical architecture, plan components and integrations | Architecture design doc, tech stack choices |
| 4 | **Agent Design** | Design Agent | Define behavior patterns, interaction flows, error-handling strategy | Behavior design doc, interaction flow, response templates |
| 5 | **Prompt Engineering** | Prompt Agent | Write the system prompt, tune instructions, define persona | System prompt file in YAML |
| 6 | **Tool Development** | Tools Agent | Build the tool functions the Agent needs, integrate APIs | Python tool function code |
| 7 | **Code Development** | Developer Agent | Write the Agent's main program, integrating all modules | Agent main program in Python |
| 8 | **Development Management** | DevManager Agent | Code review, quality assurance, integration testing | Review report, QA results |
| 9 | **Deployment** | Agent Deployer | Deploy the Agent so it can be invoked | Deployed Agent instance |

## Viewing Build Progress

### Progress Summary

The top of the page shows the overall build status:

| Field | Description |
|-------|-------------|
| **Project name** | Auto-generated from your requirement description |
| **Current stage** | Name of the stage currently running (e.g. "Tool Development - Tools Agent") |
| **Completion ratio** | Stages completed / 9 total stages |
| **Progress bar** | Visual 0–100% overall progress |
| **Status** | Building / Completed / Failed / Paused |

### Stage Timeline

The left side shows a timeline of all 9 stages, each marked with its status:

| Icon | Status | Description | Action |
|------|--------|-------------|--------|
| ✅ **Green check** | Completed | Stage finished successfully | Click to view deliverables |
| 🔄 **Blue spinner** | Running | Currently executing | Click to view live log |
| ⏳ **Gray hourglass** | Pending | Queued, waiting to run | — |
| ❌ **Red cross** | Failed | Error during execution | Click to view error log |

### Stage Detail

Click any stage in the timeline to see its details on the right-hand panel:

#### Basic Info
- **Stage name** — e.g. "Requirements (Requirements Agent)"
- **Stage description** — what this stage does
- **Execution status** — Running / Completed / Failed
- **Start time** — when this stage began
- **End time** — when this stage finished
- **Duration** — how long the stage took

#### Deliverables
Each completed stage produces artifacts you can view and download:

| Stage | Example Deliverables |
|-------|---------------------|
| Orchestration | Build plan document |
| Requirements | Structured requirements spec |
| Architecture | Architecture diagram and tech stack choices |
| Agent Design | Behavior design and interaction flow doc |
| Prompt Engineering | System prompt in YAML |
| Tool Development | Python tool function source code |
| Code Development | Agent main program source code (Python) |
| Development Management | Code review report |
| Deployment | Agent deployment confirmation |

#### Execution Log
Every stage has a detailed log of what the Builder Agent did:
- The Agent's "thought process"
- Which tools it called
- Intermediate results produced
- The specific error, if the stage failed

## A Closer Look at Each Stage

### Stage 1: Orchestration — "The Project Manager" Kicks Off

The **Orchestrator Agent** is the start of the pipeline and is responsible for:

1. **Interpreting your requirement** — understanding what kind of Agent you want
2. **Assessing complexity** — how many tools and integrations are needed
3. **Drafting the plan** — producing a detailed plan for the remaining 8 stages
4. **Allocating resources** — deciding what each stage should focus on

This stage is usually fast (about 30 seconds) because the Orchestrator mostly analyzes and plans — no actual code is written yet.

### Stage 2: Requirements — "The Product Manager" Shapes the Spec

The **Requirements Agent** turns your natural-language description into precise technical requirements:

- Extract and prioritize the core features
- Define input/output formats and data types
- Identify the external services and APIs needed
- Clarify behavior constraints and boundaries
- Produce a structured requirements specification

In **Guided Creation mode**, this stage engages you in a multi-turn Q&A to fill in missing details. In **Quick Creation mode**, the Requirements Agent infers missing information on its own.

### Stage 3: Architecture — "The Architect" Designs the Solution

The **Architecture Agent** designs the Agent's overall technical architecture based on the requirements doc:

- Decide which components are needed (model, tools, middleware)
- Plan how components interact
- Choose the most suitable model configuration
- Decide which external services and APIs to integrate
- Design data flow and processing pipeline

**Example output:** For a "Medical Literature Assistant," the architecture might include:
- Model: Claude (for understanding and generation)
- Tool chain: PubMed API search → PDF parser → citation formatter
- Data flow: user input → paper search → full-text fetch → content analysis → result output

### Stage 4: Agent Design — "The Designer" Defines the Experience

The **Design Agent** defines how the Agent interacts with users and the behavior logic behind it:

- Conversation flow design (what users say, how the Agent responds)
- Context management strategy across multi-turn dialogues
- How errors and exceptions are handled
- Reply style and formatting
- Behavior at the boundaries (when a user asks something out of scope)

### Stage 5: Prompt Engineering — "The Prompt Expert" Writes the Instructions

The **Prompt Agent** writes the system prompt — one of the biggest factors shaping Agent quality:

- Define the Agent's role and domain of expertise
- Write detailed task instructions
- Describe available tools and when to use them
- Set reply format and language style
- Define safety boundaries and behavior constraints

::: info Why the prompt matters
The system prompt is one of the most critical factors in how well your Agent performs. A good prompt is like a job description for the AI — the more detailed and accurate it is, the better the Agent performs. The Prompt Agent generates a high-quality prompt automatically based on the requirements and design docs.
:::

### Stage 6: Tool Development — "The Tool Engineer" Builds Capabilities

The **Tools Agent** builds all the tool functions the Agent needs:

- Decide which tools to build based on the architecture
- Write Python tool function code
- Define parameters and return values for each tool
- Integrate external APIs (e.g. PubMed API, AWS API)
- Verify the tools work correctly

**Common tool types:**
| Type | Examples |
|------|----------|
| File processing | Read CSV, parse Excel, write files |
| API calls | HTTP requests, search APIs, data queries |
| Data analysis | Statistics, data cleaning, format conversion |
| Code execution | Run Python scripts, shell commands |
| Web requests | Web scraping, API integration |

### Stage 7: Code Development — "The Software Engineer" Writes the Code

The **Developer Agent** combines the outputs of every prior stage to write the Agent's main program:

- Load the system prompt
- Register all tool functions
- Implement the conversation interface
- Handle file uploads and multimodal input
- Implement session management and context retention

### Stage 8: Development Management — "The Tech Lead" Reviews Quality

The **DevManager Agent** is the final quality gate:

- Review code line by line for bugs and security issues
- Verify that tool functions execute correctly
- Check that the prompt and the code are consistent
- Confirm the Agent's behavior matches the design doc
- Coordinate fixes with the Developer Agent if issues are found

::: warning
If the DevManager finds serious problems, it may send work back to an earlier stage. This adds build time but ensures the delivered Agent meets quality standards.
:::

### Stage 9: Deployment — "The Ops Engineer" Ships It

The **Agent Deployer** performs the final deployment:

- Configure the runtime environment and dependencies
- Register the Agent with the platform
- Support two deployment modes:
  - **Local deployment** — runs directly on the Nexus-AI server
  - **Cloud deployment** — published to AWS Bedrock AgentCore
- Verify the Agent can accept requests and respond correctly
- Set the Agent's status to "Running"

## Build Metrics

The Build Progress page shows key metrics in real time for this build:

| Metric | Description | What it tells you |
|--------|-------------|-------------------|
| **Total duration** | Cumulative time from start to now | Overall build speed |
| **Input tokens** | Total input tokens consumed across all Builder Agents | Resource usage |
| **Output tokens** | Total output tokens generated across all Builder Agents | Resource usage |
| **Tool call count** | Total number of tool invocations during the build | Build complexity |

::: tip Understanding token usage
Tokens are the basic units large language models use to process text. Input tokens represent how much information the Builder Agents "read"; output tokens represent how much they "wrote." More complex Agent builds consume more tokens.
:::

## Actions

### During the Build

| Action | Description |
|--------|-------------|
| **View live log** | Click the running stage to see the Builder Agent's live work log |
| **View a completed stage** | Click a completed stage to see its deliverables |

### After the Build Completes

| Action | Description |
|--------|-------------|
| **Test in chat** | Click the "Chat Test" button to start talking to the new Agent right away |
| **View stage report** | Click each stage to see the detailed output files |
| **View deliverables** | Download or preview files generated by each stage (code, prompts, etc.) |
| **View Agent** | Jump to the Agent detail page to see the full information |

## Handling Build Failures

If a stage fails during the build, you'll see a ❌ red marker on the timeline.

### Troubleshooting Steps

1. **View the error log** — click the failed stage to see the detailed error message
2. **Analyze the cause** — common causes include:

| Cause | Description | How to Fix |
|-------|-------------|------------|
| **Unclear requirement** | The Requirements Agent couldn't understand or specify your request | Use Guided Creation mode, or provide a more detailed requirement and rebuild |
| **Tool development failure** | The Tools Agent couldn't build a tool (e.g. an unavailable API) | Check whether the services referenced in the requirement are available; adjust and retry |
| **Code review failed** | The DevManager Agent found code quality issues | The system usually retries automatically; if it keeps failing, simplify the requirement |
| **Transient system issue** | A backend service is temporarily unavailable | Wait a while and create a new build project |
| **Quota limit** | You've exceeded your current quota | Contact your administrator to adjust the quota |

3. **Rebuild** — adjust the requirement based on the cause and create a new build project

::: warning
A failed build does not affect your existing Agents or data. Each build project is independent.
:::

## Build Time and Cost Reference

The figures below are real-world data from 11 production build cases:

### Overall Statistics

| Metric | Value |
|--------|-------|
| **Average build time** | 35.5 minutes |
| **Fastest build time** | 18.0 minutes |
| **Average tools generated** | 17.4 per project |
| **Average token usage** | 1,052K per project |
| **Average build cost** | $3.41 per project |
| **Workflow success rate** | **100%** |
| **Quality score** | **9.3/10** |

### By Complexity

| Complexity | Characteristics | Estimated Time | Tools | Reference Cost |
|------------|-----------------|----------------|-------|----------------|
| **Simple** | 6–7 tools, single-purpose domain | 18–28 min | 6–14 | $2.3–3.3 |
| **Medium** | 12–25 tools, multi-feature, requires API integration | 28–40 min | 12–25 | $3.1–4.1 |
| **Complex** | 25–53 tools, complex business logic, multiple data sources | 40–62 min | 25–53 | $3.3–5.1 |

### Details of 11 Real Cases

| Project | Build Time | Tokens | Tools | Cost |
|---------|-----------|--------|-------|------|
| Fitness Coach Agent | 18.0 min | 1,011K | 6 | $3.16 |
| Clinical Trial Lookup Agent | 23.5 min | 959K | 13 | $3.11 |
| PPT-to-Markdown Agent | 23.7 min | 692K | 12 | $2.29 |
| AWS Pricing Agent | 26.4 min | 773K | 14 | $2.57 |
| Disease HPO Lookup Agent | 27.6 min | 730K | 12 | $2.43 |
| Logo Design Agent | 28.2 min | 1,003K | 7 | $3.25 |
| Company Info Lookup Agent | 33.8 min | 1,199K | 25 | $3.88 |
| PubMed Literature Agent | 36.5 min | 1,284K | 12 | $4.06 |
| Medical Translation Agent | 52.7 min | 976K | 25 | $3.27 |
| HTML-to-PPTX Agent | 57.5 min | 1,621K | 53 | $5.14 |
| AWS Architecture Diagram Agent | 62.4 min | 1,325K | 12 | $4.24 |

### Token Usage by Stage

| Stage | Average Tokens | Share | Notes |
|-------|----------------|-------|-------|
| Orchestration | 59K | 5.6% | Analysis and planning — lowest usage |
| Requirements | 64K | 6.1% | Requirement parsing and specification |
| Architecture | 200K | 19.0% | More factors to consider in architecture design |
| Agent Design | 281K | 26.7% | Behavior design is relatively complex |
| Development Management | 448K | 42.6% | Code review, testing, and fixes — highest usage |

::: tip
You don't need to watch the page the whole time. Feel free to do other things and come back later to check progress. If you've enabled notifications (configured in [System Settings](/admin/settings)), you'll get a notification when the build completes or fails.
:::
