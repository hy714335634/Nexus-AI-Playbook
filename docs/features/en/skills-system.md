---
title: Skills System
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - nexus_utils/skill/**
  generated_at: 2026-05-08T15:23:44+00:00
  generated_by: docs-sync v2
---

# Skills System

## What it is

A Skill is a packaged unit of specialised expertise. It bundles an instruction file (`SKILL.md`) with optional scripts, reference material, subagents and evaluation data. Attach a skill to an agent and the agent will load that expertise on demand and run the associated scripts when a matching task comes in.

The Skills System lets you turn standard operating procedures, best practices and automation scripts into distributable, reusable, versioned capability packs that can be shared across agents and projects.

## Use cases

| Scenario | Description |
|----------|-------------|
| Extend an agent with domain skills | Attach skills like "PPT generation", "Excel processing" or "code review" to a general chat agent so it calls them automatically when needed |
| Reuse community work | Batch-import skill packs from public GitHub repos (e.g. Anthropic's official skills) |
| Share workflows across projects | Package a set of automation scripts as a skill and reuse it across multiple agents and projects |
| Codify team SOPs | Turn internal standard operating procedures into skills; every new teammate's agent gets them instantly |

## How to use it

### 1. Browse the skill library

Open the **Skill Library** page to see all available skills as cards. Filter by **category**, **tags** or **skill type** (`system` / `generated` / `community` / `private`), or search by keyword (matches name, description, tags).

<!-- SCREENSHOT: skills-library -->

Each card shows the skill's name, one-line summary, script/subagent badges, star count and usage count.

### 2. View skill details

Click any card to open its detail page, where you'll see:

- The full `SKILL.md` contents (usage instructions, invocation examples)
- The file manifest, grouped by type: prompt, scripts, references, subagents, assets, evals, config
- Version number and source (GitHub repo / URL / local / platform-generated)
- List of executable scripts

<!-- SCREENSHOT: skill-detail -->

### 3. Import a skill

Click **Import Skill**. Four sources are supported:

| Source | Input | When to use |
|--------|-------|-------------|
| `GitHub repo` | Repo URL + optional path | Public community repos, or picking one skill out of a multi-skill repo |
| `URL` | A direct link to a `SKILL.md` file | A lightweight skill that is just an instruction file |
| `Claude Code local directory` | A local path | Bulk-scan skills that already exist locally from Claude Code |
| `Local directory` | Any folder that contains a `SKILL.md` | Promote a skill from your working directory into the platform |

When importing, the platform will:

1. Fetch the files and parse the `SKILL.md` frontmatter (`name`, `description`, `tools`, `version`)
2. Recursively collect the standard subdirectories: `scripts/`, `references/`, `assets/`, `agents/`, `eval-viewer/`, `evals/`, `config/`
3. Save to local storage, upload to S3, and register the metadata
4. Create or match a **skill group** based on the source (e.g. `owner/repo`)

<!-- SCREENSHOT: skill-import -->

### 4. Batch-import from a GitHub repo

When a repo holds many skills (for example dozens of subdirectories under `skills/`):

1. Choose **Batch import from GitHub**, enter the repo URL and a base path (e.g. `skills`)
2. The platform scans and shows a preview: each skill's name, file count, total size, and whether it already exists locally
3. Tick the skills you want and click **Confirm Import**
4. Skills are fetched one by one; any that already exist locally are updated

<!-- SCREENSHOT: skill-batch-scan -->

### 5. Create or edit a skill

Click **New Skill**:

1. Fill in name, one-line description, category and tags
2. Write the `SKILL.md` body (the frontmatter can declare allowed tools)
3. Optionally upload scripts, reference files and subagents
4. Choose public or private
5. Save — the skill is immediately visible in the library

Editing an existing skill pushes changes to local storage, S3 and metadata in one go, and automatically refreshes fields like `l1_summary` and `updated_at`.

### 6. Attach skills to an agent

In the agent's configuration page, choose **Add Skills** and tick the ones you want. Agents use skills progressively:

- **Conversation start** — only each skill's summary is loaded (lightweight)
- **Trigger matched** — the full `SKILL.md` plus the `references/` material is expanded
- **Action needed** — the relevant script from `scripts/` is executed

### 7. Run a skill's script

Scripts under a skill's `scripts/` directory can be invoked by the agent or directly from the platform. Supported runtimes:

| Extension | Runtime |
|-----------|---------|
| `.py` | python |
| `.sh` | bash |
| `.js` | node |
| `.ts` | ts-node |

At execution time the platform injects the environment variables `SKILL_ID`, `SKILL_NAME`, `SKILL_DIR`; the default timeout is **120 seconds**. The result contains stdout, stderr, return code and duration.

## Key parameters & limits

| Item | Value / Notes |
|------|---------------|
| Skill types | `system` (built-in) / `generated` (platform-built) / `community` (imported) / `private` |
| Required file | `SKILL.md` at the skill's root |
| Standard subdirectories | `scripts/`, `references/`, `assets/`, `agents/`, `eval-viewer/`, `evals/`, `config/` |
| Script runtimes | python, bash, node, ts-node; flagged as `mixed` when combined |
| Default script timeout | 120 seconds |
| Script output truncation | Last 5000 chars of stdout, last 2000 chars of stderr |
| Source types | GitHub, URL, Claude Code, manual, platform |
| Summary field | The L1 summary is the first 200 characters of `description` |
| Batch scan | GitHub URLs only |
| Grouping | Auto-grouped by source (e.g. one group per GitHub repo); "combo" virtual groups are also supported |
| Storage layers | Local directory + S3 (partitioned by `skill_type/skill_id/`) + metadata store |

## FAQ

**Q: What's the difference between a skill and a subagent?**
A skill is a static capability bundle that an agent loads on demand; a subagent is a runtime role spawned by a primary agent to handle a subtask. A skill *can* contain a `agents/` directory — those are subagents that ship with that skill.

**Q: Does importing a skill with the same name cause a conflict?**
No. The platform matches on "skill name + source". Re-importing the same skill from the same GitHub repo updates it — and only rewrites files when the content hash (`import_hash`) has actually changed. Skills with the same name but different sources are kept separately.

**Q: Where does an imported skill live locally?**
Under a folder named after its type: `system_skills/`, `generated_skills/`, `community_skills/` or `private_skills/`, one subdirectory per skill, containing the original `SKILL.md` and all files. A copy is also kept in S3; if the local copy is lost, it is auto-synced back.

**Q: How are skill versions handled?**
Declare `version` in the `SKILL.md` frontmatter (e.g. `1.0.0`). When you re-import or update, the new version is written into the metadata; a new version upstream will overwrite the old one on import.

**Q: Is script execution safe?**
Scripts run in isolated subprocesses with a timeout (120 seconds by default); stdout and stderr are length-capped. Best practice: don't ship scripts that touch production data inside a skill, and prefer passing context via environment variables over hard-coding it.
