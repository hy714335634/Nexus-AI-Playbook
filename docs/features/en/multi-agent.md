---
title: Multi-Agent Graph/Swarm
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - agents/system_agents/**
    - nexus_utils/agent_graph/**
  generated_at: 2026-05-08T15:45:01+00:00
  generated_by: docs-sync v2
---

# Multi-Agent Graph/Swarm

## What it is

The multi-agent graph/swarm feature lets you see "who calls whom and who uses which tool" on a single network map, and lets a team of specialist Agents relay the same task among themselves. It has two parts:

- **Agent Graph** — an interactive network diagram of every Agent, every version, every tool they depend on, and every Agent-to-Agent call relationship (Agent-as-Tool) on the platform.
- **Agent Swarm** — pre-orchestrated groups of specialist Agents that take turns on the same job and deliver a unified result. Nexus-AI ships with several out-of-the-box swarms: Agent Build, Agent Update, Tool Build, General Assistant, Magician router, multimodal analysis, Org Builder, and Directive Builder.

## When to use it

| Scenario | Use this capability |
|----------|--------------------|
| See which Agents exist in your workspace and which tools they share | Open the Agent Graph and filter by category / tag / tool type |
| Confirm "who else is using this tool" before you remove it | Click a tool node in the graph — the side panel lists every Agent that uses it |
| Describe a need in one sentence and have a team of specialists deliver | Ask from the Magician entry point; it routes to the right swarm automatically |
| Build a full company / department tree from a paragraph of text | Org Builder swarm |
| Turn an SOP document into an executable Agent directive | Directive Builder swarm |
| Let a "main Agent" call several "sub-Agents" as tools | Agent-as-Tool composition |

## How to use

### 1. Open the Agent Graph

Go to the **Agent Graph** page (or click `View as graph` in the top-right of the Agent list). The platform loads all registered Agents, version nodes, tool nodes, and their relationships into a force-directed network diagram.

<!-- SCREENSHOT: agent-graph-overview -->

You will see four kinds of nodes and five kinds of edges:

| Node type | Color | Meaning |
|-----------|-------|---------|
| Agent | Purple | The root node of an Agent |
| Agent version | Light purple | A specific version of the same Agent |
| Tool | Color by tool type (blue / green / yellow / purple / pink) | A single tool |
| Tool group | Teal | The group a tool belongs to (e.g. `strands_tools`, `mcp`) |

| Edge type | Color | Meaning |
|-----------|-------|---------|
| uses_tool | Gray | Agent version → tool |
| has_version | Light purple | Agent → Agent version |
| calls_agent | Orange | Agent A calls Agent B as a tool (Agent-as-Tool) |
| belongs_to | Teal | Tool → tool group |
| agent_as_tool | Red | Agent exposed externally as a tool |

### 2. Filter and search

The toolbar supports filtering by:

- **Category** — the Agent's business category
- **Tags** — tags carried by a specific Agent version
- **Tool type** — `strands_tools` / `generated_tools` / `system_tools` / `template_tools` / `mcp`

<!-- SCREENSHOT: agent-graph-filters -->

### 3. Inspect a node

Click any node; the right-side panel shows:

- **Agent node**: description, category, number of versions, tool count, related edges (who calls it, what it calls)
- **Version node**: version number, status, author, created date, tags, supported models, tool dependencies
- **Tool node**: tool path, tool type, which Agents use it

### 4. Let several Agents work as a team (Agent Swarm)

Nexus-AI packages common complex jobs as swarms. Submit one request at the matching entry point and the specialists relay the work:

| Swarm | Specialist roles (in order) | Typical entry point |
|-------|----------------------------|---------------------|
| Build Agent | intent recognition → orchestrator → requirements_analyzer → system_architect → agent_designer → tool_developer → prompt_engineer → agent_code_developer → agent_developer_manager → agent_deployer | **Create Agent** page |
| Update Agent | update_orchestrator → requirements_update → tool_update → prompt_update → code_update | **Update** tab on an Agent's detail page |
| Build Tool | orchestrator → requirements_analyzer → tool_designer → tool_developer → tool_validator → tool_documenter | **Create Tool** page |
| General Assistant | A single all-purpose Agent (knowledge, math, search, files, AWS services) | Main chat entry |
| Magician router | Picks the best template or assembles a temporary swarm from your input | Main chat entry, no Agent specified |
| Multimodal analysis | Handles mixed inputs: images, documents, text | Analysis entry after uploading a file |
| Org Builder | Creates organization and department nodes in bulk from a description | **Org Management → One-click generate** |
| Directive Builder | Extracts goals, constraints, and steps from SOP / Markdown to produce an Agent directive | **Directive Library → Import from document** |

<!-- SCREENSHOT: multi-agent-swarm-build -->

::: tip What is Agent-as-Tool?
One Agent can call another Agent as if it were a tool — this is the smallest unit of a swarm. The **orange edges** in the Agent Graph are exactly these calls. Magician and the build/update workflows rely on this pattern internally.
:::

### 5. Build an organization tree from text

<!-- SCREENSHOT: org-builder -->

1. In **Org Management**, choose **Generate from description**.
2. Paste a natural-language description, for example:

   ```
   Acme Tech
     R&D Center
       Frontend Team
       Backend Team
     Marketing
   ```

3. Click **Preview** — the swarm parses the hierarchy and returns a candidate tree (preview only, nothing is persisted yet).
4. After you confirm, click **Create**. The tree is persisted in a single batch with parent-child links set correctly.

### 6. Generate an Agent directive from a document

<!-- SCREENSHOT: directive-builder -->

1. Go to **Directive Library** and pick **Import from document**.
2. Paste a Markdown or plain-text SOP.
3. On submit, the swarm decides between `guided` mode (soft recommendations) and `strict` mode (enforced steps) and extracts the goal, constraints, steps, checkpoints, and quality criteria automatically.
4. If the text mentions a department name, the new directive is placed under that department; otherwise you pick the parent manually.

### 7. Resume a swarm workflow from a checkpoint

When a Build or Update workflow fails mid-way, go to the project detail page and choose **Resume from stage**. The platform skips already-completed stages and starts from the one you pick. Stage state is persisted by the Stage Tracker, so closing the browser does not lose progress.

## Key parameters & limits

| Item | Value / note |
|------|--------------|
| Agent Graph node types | `agent`, `agent_version`, `tool`, `tool_group` |
| Agent Graph edge types | `uses_tool`, `has_version`, `calls_agent`, `belongs_to`, `agent_as_tool` |
| Tool-type colors | `strands_tools` (blue), `generated_tools` (green), `system_tools` (yellow), `template_tools` (purple), `mcp` (pink) |
| Graph data source | YAML metadata under `prompts/generated_agents_prompts/`; Agents without YAML do not appear in the graph |
| Agent-as-Tool detection | A tool path containing `agent_tool` or `agent_as_tool` is treated as an Agent-to-Agent call and does not get its own tool node |
| Build swarm stages | 9 (intent recognition + 8 relay stages, strictly sequential, no skipping) |
| Update swarm stages | 5 (sequential) |
| Tool-Build swarm stages | 6 (sequential) |
| Checkpoint resume | Build workflow supports resuming from any specified stage; Update and Tool-Build must be re-run in order |
| Session management | A `session_id` is generated per run and shared by all Agents in the swarm; you can pass an existing id to resume |
| Project name constraint | If a project name is specified at launch, every downstream Agent must reuse it and cannot rename |
| Org Builder input cap | ~8,000 characters per description |
| Directive Builder input cap | ~10,000 characters per document |

::: warning About "skipping stages"
The Build, Update, and Tool-Build workflows are strict sequential pipelines — no parallelism, no mid-stage skips. If a stage fails, you can only **re-run from that stage** or **continue from the next one** (and only if earlier outputs are still valid).
:::

## FAQ

**Q: Why can't I see my new Agent in the graph?**
A: An Agent is written to the prompt directory only after the deploy stage finishes; the graph reads those YAML files. If the build workflow has not reached deploy yet, the Agent will not show up. Refresh once deploy completes.

**Q: How are multiple versions of the same Agent distinguished?**
A: Each version is a light-purple node hanging under the Agent's purple root node, linked by a "has_version" edge. You can toggle a single version to show only its tools and calls.

**Q: If a specialist Agent fails in a swarm, is the earlier work wasted?**
A: No. Outputs from every completed stage live in the project context. When you resume from the failed stage, earlier stages are not re-executed.

**Q: How does Magician decide which Agents to call?**
A: Magician reads the template library and the list of generated Agents, then matches your input to the best single Agent or assembles a temporary swarm. You can also specify a template path directly to skip routing.

**Q: Do swarms pollute each other's context?**
A: No. Each run gets its own `session_id`. Agents inside a swarm share that session; different swarms do not. Checkpoint resume reuses the same `session_id`.

**Q: How do I make one Agent call another Agent?**
A: Reference the target Agent in the calling Agent's tool dependencies using the Agent-as-Tool form. The Agent Graph immediately draws an orange "calls" edge between the two so you can verify the wiring.
