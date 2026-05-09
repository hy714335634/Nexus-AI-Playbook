---
title: Tools & Toolsets
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - agents/template_agents/**
    - nexus_utils/skill/**
  generated_at: 2026-05-08T15:18:54+00:00
  generated_by: docs-sync v2
---

# Tools & Toolsets

## What this is

A **tool** is a single capability your agent can call — one function behind the scenes that reads a file, fetches a URL, runs a DCF calculation, or looks up AWS pricing. A **toolset (Skill)** bundles a related group of tools, scripts, reference docs, and run configuration into one reusable unit. You attach it to an agent in one click, or import one from GitHub, a URL, or a local folder.

Nexus ships three tiers — system built-ins, template toolkits, and community imports — so you pick what you need when creating an agent instead of wiring things up from scratch.

## When to use

| Scenario | Use individual tools | Use a toolset (Skill) |
|----------|----------------------|------------------------|
| Add a small capability to an agent | Tick single tools like `strands_tools/file_read` or `strands_tools/http_request` | — |
| Build a domain agent (e.g. HTML→PPTX converter) | — | Reference the whole `html2pptx` toolset — 40+ tools for parsing, style mapping, layout, images, and caching attached at once |
| Reuse community or Claude Code work | — | Batch-import from a GitHub repo, or migrate a local Claude Code Skill |
| Package your own scripts for agents | — | Ship a Skill (`SKILL.md` + `scripts/` + `references/`) |
| Add timers and math helpers | Tick `strands_tools/current_time`, `strands_tools/calculator` | — |

<!-- SCREENSHOT: tools-toolsets-overview -->

## How to use

### 1. Browse tools and toolsets

From the left sidebar open **Tools** or **Toolsets (Skills)**:

1. Switch the top tabs between `system` (built-in), `generated` (platform-built), `community` (imported), and `private`.
2. Filter by name, description, or tag with the search box; narrow by category with the dropdown.
3. Click any card to see its file manifest (prompt / scripts / references / agents / assets / evals / config), bundled tools, source, version, and usage count.

<!-- SCREENSHOT: toolset-list -->

### 2. Recognize tool naming

A tool's path prefix tells you where it comes from:

| Prefix | Meaning |
|--------|---------|
| `strands_tools/xxx` | Platform built-ins (file, time, calculator, HTTP, RSS, …) |
| `template_tools/&lt;domain&gt;/&lt;module&gt;/&lt;fn&gt;` | Tools shipped with templates, e.g. `template_tools/data/visualization/chart_generator` |
| `generated_tools/&lt;agent_key&gt;/&lt;module&gt;/&lt;fn&gt;` | Tools generated for a specific agent, e.g. `generated_tools/html2pptx/pptx_generator/add_slide` |

### 3. Attach tools to an agent

When creating or editing an agent, tick what you need in the **Tool Dependencies** panel:

```yaml
tools_dependencies:
  - "strands_tools/file_read"
  - "strands_tools/current_time"
  - "template_tools/common/text_processor/text_analyzer"
  - "generated_tools/html2pptx/html_parser/parse_html"
```

::: tip
Template agents (Deep Research Expert, API Integration Expert, HTML2PPTX Converter, …) already come with a curated tool combo preselected. Start from a template instead of wiring tools one by one.
:::

### 4. Import an external toolset

On the toolsets page click **Import** and pick a source:

| Source | What you supply | Behavior |
|--------|-----------------|----------|
| GitHub (single) | Repo URL + path inside the repo | Reads `SKILL.md` and the standard subfolders under that path |
| GitHub (batch) | Repo URL + base path | Scans every subfolder under the base path that contains a `SKILL.md`; previews candidates first so you pick only the ones you want |
| Direct URL | URL pointing to `SKILL.md` | Imports the `SKILL.md` only — no scripts or references |
| Claude Code | One or more local scan paths | Scans each path for subdirectories that contain a `SKILL.md` |
| Local directory | A path on your machine | Recursively collects files from the standard layout |

<!-- SCREENSHOT: toolset-import -->

After a successful import, Nexus:

1. Parses the `SKILL.md` YAML frontmatter (`name` / `description` / `tools` / `version`).
2. Collects the standard subfolders: `scripts/`, `references/`, `assets/`, `agents/`, `eval-viewer/`, `evals/`, `config/`.
3. Writes to the local workspace, uploads to object storage, and registers metadata — three copies kept in sync.
4. Creates or reuses a **group** based on source. Multiple Skills from the same GitHub repo land in the same group.

### 5. Run scripts from a toolset

Toolsets with a `scripts/` folder can execute scripts at agent runtime. The runtime is picked from the file extension:

| Extension | Runtime |
|-----------|---------|
| `.py` | `python` |
| `.sh` | `bash` |
| `.js` | `node` |
| `.ts` | `npx ts-node` |

On the toolset detail page, switch to the **Scripts** tab:

1. Pick a script — the panel shows the detected runtime.
2. Enter command-line arguments and click **Run**.
3. Watch live stdout / stderr, return code, and duration.

Scripts run inside the Skill's local working directory. Three environment variables are injected automatically — `SKILL_DIR`, `SKILL_NAME`, `SKILL_ID` — and the default timeout is 120 seconds.

<!-- SCREENSHOT: skill-script-run -->

### 6. Update and delete

- **Re-import from the same source** — Nexus recognizes the existing record, overwrites the files, refreshes the file manifest and content hash, and updates the summary. The group assignment is preserved.
- **Edit and re-upload** — the local workspace and object storage are overwritten together.
- **Delete** — removes the local directory, the object-storage prefix, and the metadata record in one operation. Not reversible.

## Key parameters & limits

| Item | Value / note |
|------|--------------|
| Toolset type | `system` (built-in) / `generated` (platform-built) / `community` (imported) / `private` |
| Source type | `claude-code` / `github` / `url` / `manual` / `platform` |
| Supported standard folders | `scripts/`, `references/`, `assets/`, `agents/`, `eval-viewer/`, `evals/`, `config/` |
| Required file | `SKILL.md` — import fails without it |
| Script runtimes | Python, Bash, Node.js, TypeScript (detected from extension) |
| Default script timeout | 120 seconds, overridable per call |
| Output truncation | Command mode keeps the last 5000 chars of stdout and last 2000 chars of stderr |
| L1 summary length | ≤ 200 characters — list pages return L1 fields only; detail pages lazy-load the full prompt |
| Batch import source | GitHub only |
| URL import scope | `SKILL.md` only — no scripts or references |

## FAQ

**Q: What's the practical difference between a "tool" and a "toolset (Skill)"?**
A: A tool is one callable function (e.g. `file_read`). A toolset is a directory with a `SKILL.md` that can contain multiple tools, scripts, reference docs, and example agents. Use a tool to add a single capability; use a toolset to install an entire domain pack.

**Q: Why does a GitHub import fail with "No SKILL.md found"?**
A: Check that the repo path you provided points to the directory that directly contains `SKILL.md`. In batch mode, Nexus only treats subdirectories of the **base path** that **directly contain `SKILL.md`** as Skills.

**Q: Where do scripts actually run — on my machine?**
A: No. Scripts run inside the Skill's working directory on the platform, isolated in a subprocess with a timeout. Your local machine is not touched.

**Q: Why doesn't the list page show the full system prompt — only the detail page does?**
A: The list page returns the L1 summary (name, description, tags, tool list — lightweight fields only). The detail page lazily loads the L2 full prompt. This keeps the list fast and reduces database reads.

**Q: What happens if I import the same Skill twice?**
A: Nexus looks up the existing record by name and source, then updates it — files are overwritten, the file manifest and content hash are refreshed — instead of creating a duplicate.

**Q: Can I author and upload my own toolset?**
A: Yes. Follow the Anthropic Agent Skills layout: put `SKILL.md` (with YAML frontmatter) at the top level and everything else under the standard subfolders listed above. Then import from **Local directory**, or push to a GitHub repo and import from there.
