---
title: Adding Skills
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - nexus_utils/prompts_manager.py
    - nexus_utils/skill/**
    - prompts/system_agents_prompts/**
    - prompts/template_prompts/**
  generated_at: 2026-05-09T00:36:25+00:00
  generated_by: docs-sync v2
---

# Adding Skills

## Overview

A Nexus-AI "Skill" is an **Anthropic Agent Skills compatible** capability bundle: a `SKILL.md` (YAML frontmatter + Markdown body) plus optional `scripts/`, `references/`, `evals/`, `agents/`, `assets/`, `eval-viewer/`, and `config/` subdirectories. Skills use **trigger-based loading** via the `description` field — Claude only loads the SKILL.md body when user intent matches, and only loads scripts/references on demand, producing progressive disclosure across **L1 (metadata) → L2 (body + references + scripts assembled into one prompt) → L3 (on-demand script execution)**.

The authoritative skill subsystem lives under `nexus_utils/skill/` and is designed to be **shared across api / worker / cli** without depending on FastAPI or any web framework. Four core components: `SkillStorage` (local filesystem + S3 dual-layer storage), `SkillImporter` (four import sources: GitHub / URL / Claude Code / local directory), `SkillRuntime` (`subprocess` execution for scripts and shell commands), and `SkillManager` (unified entry point that coordinates the three and owns CRUD + DDB metadata + file manifest).

The platform also ships a **five-stage Skill Build Workflow** (`prompts/system_agents_prompts/skill_build_workflow/`) that reverse-engineers complete Skill bundles from natural-language requirements: `intent_recognition` → `skill_design` → `skill_development` → `skill_validation` → `skill_deployment`. Stage-agent prompts are loaded by `nexus_utils/prompts_manager.py`'s `PromptManager` singleton, keyed by the top-level `agent:` field.

Main entry points:

| Entry | File | Responsibility |
|-------|------|----------------|
| Unified skill management | `nexus_utils/skill/manager.py:709` (`SkillManager`) | CRUD, import, groups, L1/L2 loading |
| Local + S3 storage | `nexus_utils/skill/storage.py:2030` (`SkillStorage`) | Read/write, sync, manifest, prompt assembly |
| Multi-source import | `nexus_utils/skill/importer.py:123` (`SkillImporter`) | GitHub / URL / Claude Code / local directory |
| Script execution runtime | `nexus_utils/skill/runtime.py:1667` (`SkillRuntime`) | Isolated `subprocess` execution |
| Data models | `nexus_utils/skill/models.py` | `SkillType`, `SkillInfo`, `FileManifest`, etc. |
| Build workflow Stage 1 | `prompts/system_agents_prompts/skill_build_workflow/skill_intent_recognizer.yaml` | Parse intent, generate skill_name |
| Build workflow Stage 2 | `prompts/system_agents_prompts/skill_build_workflow/skill_designer.yaml` | Design SKILL.md outline and script plan |
| Build workflow Stage 3 | `prompts/system_agents_prompts/skill_build_workflow/skill_developer.yaml` | Generate files, write to S3 |
| Build workflow Stage 4 | `prompts/system_agents_prompts/skill_build_workflow/skill_validator.yaml` | Structure / content / evals validation |
| Build workflow Stage 5 | `prompts/system_agents_prompts/skill_build_workflow/skill_deployer.yaml` | Aggregate metadata, trigger DDB registration |
| Prompt loading | `nexus_utils/prompts_manager.py:13453` (`PromptManager`) | Load `prompts/**/*.yaml`, with DDB+S3 lazy loading |

## File Layout

| Path | Responsibility | Main Dependencies |
|------|----------------|-------------------|
| `nexus_utils/skill/__init__.py` | Public exports (`SkillType`, `SkillInfo`, `SkillManager`, etc.) | Submodules |
| `nexus_utils/skill/models.py` | Data models, enums, file classification, `SKILL_STANDARD_DIRS` | `dataclasses`, `enum` |
| `nexus_utils/skill/storage.py` | Local + S3 dual storage, S3 cache, prompt assembly | `boto3`, `pathlib`, `threading` |
| `nexus_utils/skill/importer.py` | Four-source import, GitHub raw + REST dual path, git clone fallback | `httpx`, `yaml`, `subprocess` |
| `nexus_utils/skill/runtime.py` | Script / shell `subprocess` execution, timeout, env injection | `subprocess`, `time` |
| `nexus_utils/skill/manager.py` | Aggregate entry: CRUD + import orchestration + DDB + group management | Sibling submodules + `api.v2.database` |
| `prompts/system_agents_prompts/skill_build_workflow/skill_intent_recognizer.yaml` | Stage 1 intent-recognizer prompt | `strands_tools/current_time` |
| `prompts/system_agents_prompts/skill_build_workflow/skill_designer.yaml` | Stage 2 designer prompt | `read_skill_reference`, etc. |
| `prompts/system_agents_prompts/skill_build_workflow/skill_developer.yaml` | Stage 3 developer prompt | `write_skill_file_to_s3`, etc. |
| `prompts/system_agents_prompts/skill_build_workflow/skill_validator.yaml` | Stage 4 validator prompt | `validate_skill_structure`, etc. |
| `prompts/system_agents_prompts/skill_build_workflow/skill_deployer.yaml` | Stage 5 deployer prompt | `list_skill_files_in_s3`, etc. |
| `prompts/template_prompts/*.yaml` | Template agent prompts (includes `default.yaml`) | — |
| `nexus_utils/prompts_manager.py` | `PromptManager` singleton: YAML parsing, lazy loading, version routing | `yaml`, `pathlib` |
| `skills/system_skills/&lt;name&gt;/` | Local root for platform-built-in skills | — |
| `skills/generated_skills/&lt;name&gt;/` | Local mirror for workflow-generated skills | — |
| `s3://{artifacts_bucket}/skills/{skill_id}/` | Legacy S3 prefix (no type layer) | `boto3` |
| `s3://{artifacts_bucket}/skills/{skill_type}/{skill_id}/` | New type-layered S3 prefix | `boto3` |

## Core Types / Classes / Data Structures

### `SkillType` enum (`nexus_utils/skill/models.py:1277`)

| Value | Semantics | Local directory |
|-------|-----------|-----------------|
| `"system"` | Platform built-in / imported-and-archived skills | `skills/system_skills/` |
| `"generated"` | Skills produced by the build workflow | `skills/generated_skills/` |
| `"community"` | Community-contributed | `skills/community_skills/` |
| `"private"` | User-private | `skills/private_skills/` |

### `SourceType` enum (`nexus_utils/skill/models.py:1285`)

| Value | Meaning |
|-------|---------|
| `"claude-code"` | Imported from a Claude Code local directory |
| `"github"` | Imported from a GitHub repo (single / batch) |
| `"url"` | Imported directly from a SKILL.md URL (only SKILL.md) |
| `"manual"` | Manually created |
| `"platform"` | Produced by the build workflow |

### `SKILL_STANDARD_DIRS` constant (`nexus_utils/skill/models.py:1335`)

When collecting files, the importer **only descends into these standard subdirectories**; anything else is ignored:

```python
SKILL_STANDARD_DIRS = [
    'scripts',
    'references',
    'assets',
    'agents',
    'eval-viewer',
    'evals',
    'config',
]
```

### `FileInfo` (`nexus_utils/skill/models.py:1392`)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `key` | `str` | — | Relative path (e.g. `scripts/run.py`) |
| `size` | `int` | `0` | File size in bytes |
| `file_type` | `str` | `"other"` | `prompt` / `script` / `reference` / `agent` / `asset` / `eval` / `config` / `other` |
| `language` | `str` | `""` | Language inferred from extension |
| `last_modified` | `str` | `""` | ISO timestamp |

### `FileManifest` (`nexus_utils/skill/models.py:1413`)

| Field | Type | Description |
|-------|------|-------------|
| `prompt` | `List[str]` | `SKILL.md` / `skill.md` |
| `scripts` | `List[str]` | Files under `scripts/` |
| `references` | `List[str]` | Files under `references/` + top-level `.md` |
| `agents` | `List[str]` | Files under `agents/` |
| `assets` | `List[str]` | Files under `assets/` |
| `evals` | `List[str]` | Files under `evals/` + `eval-viewer/` |
| `config` | `List[str]` | Files under `config/` |
| `other` | `List[str]` | Everything else |

Classification is done by `FileManifest._classify_file(key)` (`nexus_utils/skill/models.py:1443`). Top-level `.md` files fall into `references`; `SKILL.md` / `skill.md` fall into `prompt`.

### `SkillInfo` (`nexus_utils/skill/models.py:1474`)

One-row dataclass for the DDB `nexus_skills` table. Full field list:

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `skill_id` | `str` | — | Primary key, format `sk-{uuid}` |
| `skill_name` | `str` | — | kebab-case name |
| `description` | `str` | `""` | Trigger-oriented description |
| `skill_type` | `str` | `"system"` | `SkillType` value |
| `category` | `str` | `"general"` | Category |
| `tools` | `List[str]` | `[]` | `tools` from SKILL.md frontmatter |
| `tags` | `List[str]` | `[]` | Tags |
| `version` | `Optional[str]` | `None` | Version |
| `source` | `Optional[Dict]` | `None` | Source metadata (`type`/`url`/`path`/`import_hash`) |
| `group_id` | `str` | `""` | Owning group ID |
| `local_path` | `str` | `""` | Absolute local directory path |
| `s3_prefix` | `str` | `""` | S3 prefix (`skills/{id}/` or `skills/{type}/{id}/`) |
| `file_manifest` | `Optional[Dict]` | `None` | `FileManifest.to_dict()` |
| `s3_files` | `List[Dict]` | `[]` | List of `FileInfo.to_dict()` |
| `has_scripts` | `bool` | `False` | `scripts/` non-empty |
| `has_agents` | `bool` | `False` | `agents/` non-empty |
| `has_evals` | `bool` | `False` | `evals/` non-empty |
| `script_runtime` | `str` | `""` | `python` / `bash` / `node` / `mixed` |
| `local_synced` | `bool` | `False` | Whether local mirrors S3 |
| `last_synced_at` | `str` | `""` | ISO timestamp |
| `is_public` | `bool` | `True` | Public flag (DDB GSI requires `"true"`/`"false"` strings) |
| `user_id` | `str` | `"system"` | Creator |
| `star_count` | `int` | `0` | — |
| `usage_count` | `int` | `0` | — |
| `total_size` | `int` | `0` | Sum of bytes across all files |
| `l1_summary` | `str` | `""` | L1 summary, ≤ 200 chars |
| `readme` | `Optional[str]` | `None` | Raw SKILL.md (optional) |
| `parameters` | `Dict` | `{}` | Reserved |
| `created_at` / `updated_at` | `str` | `""` | ISO timestamps |

### `SkillGroupInfo` (`nexus_utils/skill/models.py:1294`)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `group_id` | `str` | — | Group primary key |
| `group_name` | `str` | — | Group name |
| `source_type` | `str` | `""` | `github` / `claude-code` / `url` / `manual` |
| `source_url` | `str` | `""` | Source URL |
| `source_path` | `str` | `""` | Inner source path |
| `skill_count` | `int` | `0` | Number of skills in the group |
| `group_type` | `str` | `"source"` | `source` (origin group) / `combo` (virtual combination) |
| `skill_ids` | `list` | `[]` | Associated skill_ids for combo groups |

### `ScanResult` (`nexus_utils/skill/models.py:1562`)

GitHub batch-scan preview (**does not actually import**):

| Field | Type | Description |
|-------|------|-------------|
| `skill_name` | `str` | Directory name (fallback from frontmatter) |
| `path` | `str` | Path inside the repo |
| `has_skill_md` | `bool` | Whether `SKILL.md` / `skill.md` was found |
| `file_count` | `int` | File count (subdirs counted as 1) |
| `total_size` | `int` | Total bytes |
| `exists_locally` | `bool` | Whether a same-named local skill exists |
| `import_hash` | `str` | Content SHA |

### `ExecutionResult` (`nexus_utils/skill/models.py:1586`)

Return value from `SkillRuntime.execute_script` / `execute_command`:

| Field | Type | Description |
|-------|------|-------------|
| `success` | `bool` | `return_code == 0` |
| `stdout` | `str` | Stdout (`execute_command` truncates the last 5000 bytes) |
| `stderr` | `str` | Stderr (`execute_command` truncates the last 2000 bytes) |
| `return_code` | `int` | Exit code; `-1` = missing / unsupported, `-2` = timeout, `-3` = exception |
| `duration_ms` | `int` | Execution time |

### `ImportResult` (`nexus_utils/skill/models.py:1546`)

| Field | Type | Description |
|-------|------|-------------|
| `imported` | `List[str]` | Names successfully imported |
| `skipped` | `List[str]` | Names skipped because they already existed |
| `errors` | `List[str]` | Error messages |

### Language and Content-Type maps

```python
# nexus_utils/skill/models.py:1346
LANG_MAP = {
    ".py": "python", ".js": "javascript", ".ts": "typescript",
    ".sh": "bash", ".rb": "ruby", ".go": "go", ".java": "java",
    ".rs": "rust", ".md": "markdown", ".yaml": "yaml", ".yml": "yaml",
    ".json": "json", ".html": "html", ".css": "css", ".xml": "xml",
    ".sql": "sql", ".txt": "text", ".csv": "csv",
}

# nexus_utils/skill/models.py:1368
CONTENT_TYPE_MAP = {
    ".md": "text/markdown", ".py": "text/x-python",
    ".js": "application/javascript", ".ts": "application/typescript",
    ".json": "application/json", ".yaml": "text/yaml", ".yml": "text/yaml",
    ".sh": "text/x-shellscript", ".html": "text/html", ".css": "text/css",
    ".txt": "text/plain", ".csv": "text/csv", ".xml": "application/xml",
    ".png": "image/png", ".jpg": "image/jpeg", ".jpeg": "image/jpeg",
    ".gif": "image/gif", ".svg": "image/svg+xml",
    ".pdf": "application/pdf", ".zip": "application/zip",
}
```

## Key Functions / Methods

### `SkillManager` (`nexus_utils/skill/manager.py:709`)

The unified management entry point. The constructor accepts optional `storage` / `importer` / `runtime` (defaulting to module singletons `skill_storage` / a fresh `SkillImporter` / `skill_runtime`). `self.db` is **lazily loaded** from `api.v2.database`.

L1 summary field whitelist (listing endpoints only return these):

```python
# manager.py:713
L1_FIELDS = {
    'skill_id', 'skill_name', 'description', 'skill_type', 'category',
    'tags', 'tools', 'source', 'version', 'is_public', 'star_count',
    'usage_count', 'user_id', 'created_at', 'updated_at',
    'l1_summary', 'local_path', 's3_prefix', 's3_files', 'total_size',
    'file_manifest', 'has_scripts', 'has_agents', 'has_evals',
    'script_runtime', 'local_synced', 'group_id',
}
```

| Method | Signature | Responsibility | Call order |
|--------|-----------|----------------|------------|
| `create_skill` | `create_skill(skill_name, skill_type='system', description='', system_prompt_snippet='', tools=None, parameters=None, category='general', user_id='system', is_public=True, tags=None, source=None, version=None, readme=None, content_files=None, group_id='') -> Dict` | Write local → upload S3 → write DDB | `save_to_local` → `save_to_s3` → `build_file_manifest` → `detect_script_runtime` → `db.create_skill` |
| `register_built_skill` | `register_built_skill(skill_id, skill_name, project_id, stage_result, user_id='system') -> Dict` | Workflow post-write: files already in S3 → build manifest → write DDB → S3→local sync | `list_s3_files` → `build_file_manifest` → `db.create_skill` → `sync_s3_to_local` |
| `get_skill` | `get_skill(skill_id, include_prompt=True) -> Optional[Dict]` | L2 load: attach assembled `system_prompt_snippet` | `db.get_skill` → `storage.get_full_prompt` |
| `list_skills` | `list_skills(user_id=None, category=None, skill_type=None, search=None) -> List[Dict]` | L1 listing: project using field whitelist | `db.list_skills` → L1_FIELDS projection |
| `update_skill` | `update_skill(skill_id, updates) -> Optional[Dict]` | Update metadata / files; `content_files` syncs to S3 and local | `save_to_local` → `save_to_s3` → `build_file_manifest` → `db.update_skill` |
| `delete_skill` | `delete_skill(skill_id) -> bool` | Three-layer cleanup: local → S3 → DDB | `delete_local_skill` → `delete_s3_files` → `db.delete_skill` |
| `import_from_github` | `import_from_github(repo_url, path='', skill_type='system', user_id='system', group_id='') -> Dict` | Single-skill import + group assignment + content-hash de-dup | `importer.import_from_github` → `ensure_group` → `update_skill` or `create_skill` |

> Because the source file is long, `import_from_github` is followed by `import_from_github_batch` / `scan_github` / `import_from_claude_code` / `import_from_local_dir` / `import_from_url` / `ensure_group` / `list_groups` / `_find_existing_skill`, all composing `importer` + `storage` + `db` in the same pattern.

### `SkillImporter` (`nexus_utils/skill/importer.py:123`)

**Four import sources**, each with its own main entry:

| Source | Method | Signature | Key behavior |
|--------|--------|-----------|--------------|
| GitHub single | `import_from_github` | `import_from_github(repo_url, path='') -> Tuple[Dict[str, bytes], Dict[str, Any]]` | Parse `https://github.com/owner/repo` → `_fetch_github_skill_files` (raw + REST); non-GitHub URL → `_clone_and_collect` fallback |
| GitHub batch scan | `scan_github_batch` | `scan_github_batch(repo_url, base_path='', existing_names=None) -> List[ScanResult]` | Scan directory and return previews; **does not import** |
| GitHub batch import | `import_from_github_batch` | `import_from_github_batch(repo_url, base_path='', filter_names=None) -> List[Tuple[Dict, Dict, str]]` | Batch fetch filtered by `filter_names` |
| URL | `import_from_url` | `import_from_url(url) -> Tuple[Dict[str, bytes], Dict[str, Any]]` | Fetch only `SKILL.md`, infer `skill_name` from URL |
| Claude Code scan | `scan_claude_code_paths` | `scan_claude_code_paths(scan_paths: List[str]) -> List[Path]` | Expand `~`, scan first-level subdirs for `SKILL.md` |
| Local directory | `import_from_local_dir` | `import_from_local_dir(skill_dir: Path) -> Tuple[Dict[str, bytes], Dict[str, Any]]` | Delegates to `collect_skill_files` |

**SKILL.md parsing**: `parse_skill_md(content: str) -> Dict` (`importer.py:131`) returns:

| Key | Type | Meaning |
|-----|------|---------|
| `skill_name` | `str` | `name` from frontmatter |
| `description` | `str` | `description` from frontmatter |
| `tools` | `List[str]` | `tools` from frontmatter (supports comma-string or list) |
| `version` | `Optional[str]` | `version` from frontmatter (coerced to str) |
| `system_prompt_snippet` | `str` | Body text after frontmatter |

**File collection**: `collect_skill_files(skill_dir: Path) -> Dict[str, bytes]` (`importer.py:199`). Collects top-level non-hidden files plus every file under the dirs in `SKILL_STANDARD_DIRS`; skips `__pycache__` and dot-prefixed files.

**GitHub internal methods** (static / private):

| Method | Signature | Purpose |
|--------|-----------|---------|
| `_parse_github_url` | `_parse_github_url(repo_url: str) -> Optional[Tuple[str, str]]` | Regex `https?://github\.com/([^/]+)/([^/]+?)(?:\.git)?/?$` |
| `_github_raw_fetch` | `_github_raw_fetch(owner, repo, file_path) -> Optional[bytes]` | Tries `main` and `master` raw URLs |
| `_github_api_list_dir` | `_github_api_list_dir(owner, repo, dir_path) -> Optional[List[Dict]]` | Calls `api.github.com/repos/.../contents/...` |
| `_fetch_github_skill_files` | Internal | Combines `raw` + `API`: fetch `SKILL.md`, list directory, recurse into standard subdirs |
| `_fetch_github_dir_recursive` | Internal | Deep recursion into standard subdirs |
| `_clone_and_collect` | `_clone_and_collect(repo_url, path='') -> Dict[str, bytes]` | Fallback for non-GitHub URLs: `git clone --depth 1` to a tempdir |

### `SkillStorage` (`nexus_utils/skill/storage.py:2030`)

Local + S3 dual-layer storage. Default local root `skills/`; S3 bucket comes from `config.get_nexus_ai_config().get('artifacts_s3_bucket', 'nexus-ai-artifacts-2026')`; AWS region defaults to `us-west-2`. Both the S3 client and the S3 cache are **lazily initialized**, so constructing `SkillStorage` does not fail in environments without AWS credentials.

**Local storage**:

| Method | Signature | Notes |
|--------|-----------|-------|
| `get_local_skill_dir` | `get_local_skill_dir(skill_type, skill_name) -> Path` | Path: `{local_base}/{skill_type}_skills/{skill_name}` |
| `save_to_local` | `save_to_local(skill_type, skill_name, files: Dict[str, bytes]) -> Path` | Writes each relative path |
| `read_local_file` | `read_local_file(skill_type, skill_name, rel_path) -> Optional[bytes]` | — |
| `list_local_files` | `list_local_files(skill_type, skill_name) -> List[FileInfo]` | Skips `.` and `__pycache__` |
| `local_skill_exists` | `local_skill_exists(skill_type, skill_name) -> bool` | Checks for `SKILL.md` |
| `delete_local_skill` | `delete_local_skill(skill_type, skill_name) -> bool` | `shutil.rmtree` |
| `collect_local_files` | `collect_local_files(skill_type, skill_name) -> Dict[str, bytes]` | Reads all file contents into a dict |
| `collect_directory_files` | `collect_directory_files(directory: Path) -> Dict[str, bytes]` | Generic directory walker; skips `.`/`__pycache__`/`node_modules` |

**S3 storage**:

| Method | Signature | Notes |
|--------|-----------|-------|
| `get_s3_prefix` | `get_s3_prefix(skill_id, skill_type='') -> str` | With `skill_type` returns `skills/{type}/{id}/`; else `skills/{id}/` (legacy) |
| `save_to_s3` | `save_to_s3(skill_id, files: Dict[str, bytes], skill_type='') -> Dict` | Invalidate cache → per-file `put_object` → return `s3_prefix`/`s3_files`/`total_size` |
| `read_s3_file` | `read_s3_file(skill_id, rel_path) -> Optional[bytes]` | In-memory cache; `NoSuchKey` writes a `_NOT_FOUND` sentinel |
| `list_s3_files` | `list_s3_files(skill_id) -> List[FileInfo]` | Uses `list_objects_v2` paginator |
| `delete_s3_files` | `delete_s3_files(skill_id) -> int` | 1000-at-a-time `delete_objects` batches |

**Sync**:

| Method | Signature | Notes |
|--------|-----------|-------|
| `sync_s3_to_local` | `sync_s3_to_local(skill_id, skill_type, skill_name) -> Path` | First tries legacy typeless prefix; falls back to `skills/{type}/{id}/` |
| `sync_local_to_s3` | `sync_local_to_s3(skill_type, skill_name, skill_id) -> Dict` | Collect local → `save_to_s3(skill_type=skill_type)` |
| `ensure_local` | `ensure_local(skill_id, skill_type, skill_name) -> Path` | Calls `sync_s3_to_local` if local is missing |

**Prompt assembly (L2 load)**:

| Method | Signature | Notes |
|--------|-----------|-------|
| `get_full_prompt` | `get_full_prompt(skill_id, skill_type='', skill_name='') -> str` | Prefer local; fall back to S3 |
| `_assemble_prompt_from_local` | Internal | Read `SKILL.md` → append `references/*.md` → append `scripts/**` as code blocks |
| `_assemble_prompt_from_s3` | Internal | Same logic but reads from S3; binary files (`UnicodeDecodeError`) are skipped |

**Utility**: `compute_content_hash(files) -> str` returns a SHA-256 over `(key, content)` concatenated, used for import de-duplication.

### `SkillRuntime` (`nexus_utils/skill/runtime.py:1667`)

Script and shell-command execution; default timeout 120 seconds:

```python
# runtime.py:1655
DEFAULT_TIMEOUT = 120

RUNTIME_MAP = {
    '.py': 'python',
    '.sh': 'bash',
    '.js': 'node',
    '.ts': 'npx ts-node',
}
```

| Method | Signature | Notes |
|--------|-----------|-------|
| `ensure_workspace` | `ensure_workspace(skill_id, skill_type, skill_name) -> Path` | Delegates to `storage.ensure_local` |
| `list_scripts` | `list_scripts(skill_type, skill_name) -> List[Dict]` | Enumerates executables under `scripts/`, filters `__init__.py` / `__pycache__` |
| `execute_script` | `execute_script(skill_id, skill_type, skill_name, script_path, args=None, timeout=120, env_vars=None) -> ExecutionResult` | Look up extension → pick runtime → `subprocess.run(cwd=skill_dir)` |
| `execute_command` | `execute_command(skill_id, skill_type, skill_name, command, timeout=120, env_vars=None) -> ExecutionResult` | `subprocess.run(shell=True, cwd=skill_dir)`; stdout/stderr tails truncated |
| `detect_script_runtime` | `detect_script_runtime(skill_type, skill_name) -> str` | Returns `python` / `bash` / `node` / `mixed` / `""` |

**Injected environment variables**: executing any script or command will set

| Variable | Value |
|----------|-------|
| `SKILL_DIR` | Resolved absolute local path (`.resolve()`) |
| `SKILL_NAME` | Passed-in `skill_name` |
| `SKILL_ID` | Passed-in `skill_id` |

**Return-code conventions**: `-1` = script missing or unsupported extension; `-2` = timeout; `-3` = other exception.

### `PromptManager` (`nexus_utils/prompts_manager.py:13453`)

**Global singleton** for prompt loading and routing (`__new__` locks `_instance`, `_initialized` guards `__init__`). At construction it scans every `*.yaml` under `./prompts` and parses the top-level `agent:` key (`name` / `description` / `category` / `environments` / `versions[]`).

| Method | Signature | Purpose |
|--------|-----------|---------|
| `load_prompts` | `load_prompts() -> None` | Recursively `os.walk('./prompts')` and load every `.yaml` |
| `get_agent` | `get_agent(agent_name: str) -> Optional[PromptAgent]` | Check in-memory cache first, then lazy-load from DDB+S3 via `_try_load_from_s3` |
| `reload` | `reload() -> None` | Clear cache and reload; enables runtime registration of new prompts |
| `load_single_prompt` | `load_single_prompt(prompt_file_path: str) -> bool` | Hot-load a single new agent YAML after deployment |
| `_resolve_agent_record_from_ddb` | Internal | `identifier` can be an agent_id (36-char UUID with 4 dashes), `agent_name_en`, or `relative_path` |

`PromptAgent` (`prompts_manager.py:13412`) holds `versions: Dict[str, PromptVersion]`. `get_version(version='latest')` prefers an explicit `latest` entry, otherwise picks the highest version by `_version_key` (`"2.0.0" -> (2, 0, 0)`).

A prompt's `metadata.tools_dependencies` list drives which tools get injected into the agent at runtime (see the `tools_dependencies` field in each build-workflow YAML).

## Directory and S3 Layout

### Local directory layout

```
skills/
├── system_skills/           # SkillType.SYSTEM
│   └── <skill_name>/
│       ├── SKILL.md
│       ├── scripts/
│       ├── references/
│       ├── agents/
│       ├── evals/
│       ├── assets/
│       └── config/
├── generated_skills/        # SkillType.GENERATED
│   └── <skill_name>/
├── community_skills/        # SkillType.COMMUNITY
└── private_skills/          # SkillType.PRIVATE
```

`_ensure_local_dirs` (`storage.py:2061`) creates these four root directories inside `SkillStorage.__init__`.

### S3 layout

Newly written skills use the type-layered prefix:

```
s3://{artifacts_bucket}/skills/{skill_type}/{skill_id}/
                                           ├── SKILL.md
                                           ├── scripts/...
                                           ├── references/...
                                           └── evals/...
```

Legacy prefix: `skills/{skill_id}/` (no `skill_type` segment). `sync_s3_to_local` **tries the legacy prefix first**, then falls back to the new one, so existing data remains readable.

### SKILL.md frontmatter standard

```yaml
---
name: skill-name
description: Trigger-oriented description. Use this skill whenever...
tools: Read, Glob, Grep           # optional, comma-separated
version: 1.0.0                    # optional
---
# Markdown body (<500 lines)
```

`parse_skill_md` gracefully degrades when `---` is missing: the whole content becomes `system_prompt_snippet`, and all other fields are empty.

## Call Graph / Data Flow

### Write: create / import

```
SkillManager.create_skill
    │
    ├─▶ SkillStorage.save_to_local      (skills/{type}_skills/{name}/)
    │
    ├─▶ SkillStorage.save_to_s3         (s3://…/skills/{type}/{id}/)
    │        │
    │        └─▶ _cache_invalidate / _cache_put
    │
    ├─▶ SkillStorage.build_file_manifest
    │        │
    │        └─▶ FileManifest._classify_file
    │
    ├─▶ SkillRuntime.detect_script_runtime
    │        │
    │        └─▶ SkillRuntime.list_scripts
    │
    └─▶ db_client.create_skill          (DDB nexus_skills)
```

### Read: list / detail / prompt

```
list_skills  ─▶ db.list_skills ─▶ L1_FIELDS projection
get_skill    ─▶ db.get_skill
             └─▶ storage.get_full_prompt
                 ├─(local exists)▶ _assemble_prompt_from_local
                 └─(local missing)▶ _assemble_prompt_from_s3
                                   └─▶ list_s3_files → read_s3_file (cached)
```

### GitHub import flow

```
SkillImporter.import_from_github(repo_url, path)
    │
    ├─[URL matches github.com?]
    │   ├─ yes ─▶ _fetch_github_skill_files
    │   │           ├─ _github_raw_fetch(SKILL.md)         (main + master)
    │   │           ├─ _github_api_list_dir(skill_path)
    │   │           ├─ raw_fetch each top-level file
    │   │           └─ for each SKILL_STANDARD_DIR:
    │   │                _fetch_github_dir_recursive
    │   └─ no  ─▶ _clone_and_collect
    │             └─ git clone --depth 1 + collect_skill_files
    │
    └─▶ parse_skill_md(files['SKILL.md'])
```

### Script execution

```
SkillRuntime.execute_script
    │
    ├─▶ ensure_workspace ─▶ storage.ensure_local ─▶ (maybe) sync_s3_to_local
    │
    ├─[ext in RUNTIME_MAP?]
    │   └─ no ─▶ ExecutionResult(return_code=-1)
    │
    ├─ env = {**os.environ, SKILL_DIR, SKILL_NAME, SKILL_ID, **env_vars}
    │
    └─▶ subprocess.run(cmd, cwd=skill_dir, timeout=timeout, env=env)
         ├─ TimeoutExpired ─▶ return_code=-2
         └─ Exception      ─▶ return_code=-3
```

### Skill Build Workflow (five stages)

```
User request
    │
    ├─ Stage 1: skill_intent_recognizer
    │           output: {skill_name, skill_description_draft, trigger_scenarios, tags, ...}
    │
    ├─ Stage 2: skill_designer
    │           input:  intent_recognition result
    │           output: {skill_md_design, scripts_plan, references_plan, evals_plan, directory_structure}
    │           tools:  read_skill_reference, get_project_info, get_stage_result
    │
    ├─ Stage 3: skill_developer
    │           input:  intent + design
    │           output: {files[], skill_md_summary, tags, category, version}
    │           tools:  write_skill_file_to_s3, read_skill_file_from_s3, read_skill_reference
    │           side effect: writes all files under s3://…/skills/{skill_type}/{skill_id}/
    │
    ├─ Stage 4: skill_validator
    │           input:  design + development
    │           output: {validation_summary, structure_validation, content_quality, evals_validation, issues[]}
    │           tools:  validate_skill_structure, read_skill_file_from_s3, write_skill_file_to_s3
    │
    └─ Stage 5: skill_deployer
                input:  all prior INPUT CONTEXT
                output: DDB registration metadata JSON (skill_id/name/description/s3_files/tags/category/version/has_* etc.)
                tools:  list_skill_files_in_s3, read_skill_file_from_s3
                Worker callback: SkillManager.register_built_skill
```

The JSON emitted by Stage 5 is aligned with the DDB `nexus_skills` schema. The worker-side `BuildHandlerV2._post_skill_deployment` calls `SkillManager.register_built_skill`, which does the following:

1. `list_s3_files` to read back the S3 file list
2. Build a `FileManifest`
3. Call `db.create_skill` to write DDB
4. `sync_s3_to_local` into `skills/generated_skills/{skill_name}/`
5. Update DDB with `local_path` / `local_synced` / `last_synced_at`

## Extending

### 1. Add a platform-built-in skill (manual)

**Goal**: drop a hand-made Skill into `skills/system_skills/&lt;name&gt;/` and register it in DDB.

Steps:

1. Prepare the standard structure locally:
   ```
   skills/system_skills/<name>/
   ├── SKILL.md           # required: YAML frontmatter + body
   ├── scripts/           # optional
   │   └── *.py | *.sh | *.js | *.ts
   ├── references/        # optional
   │   └── *.md
   └── evals/             # optional
       └── evals.json
   ```
2. Use `SkillImporter.import_from_local_dir(Path('skills/system_skills/&lt;name&gt;'))` to read and parse `SKILL.md`.
3. Call `SkillManager.create_skill(...)` with `content_files` (from `collect_skill_files`), `skill_type=SkillType.SYSTEM.value`, and `source={'type': 'manual'}`.

**Minimal example**:

```python
from pathlib import Path
from nexus_utils.skill import SkillManager, SkillImporter, SkillType

importer = SkillImporter()
files, parsed = importer.import_from_local_dir(Path('skills/system_skills/my-skill'))

manager = SkillManager()
skill = manager.create_skill(
    skill_name=parsed['skill_name'],
    skill_type=SkillType.SYSTEM.value,
    description=parsed['description'],
    system_prompt_snippet=parsed['system_prompt_snippet'],
    tools=parsed['tools'],
    version=parsed['version'],
    content_files=files,
    source={'type': 'manual'},
)
print(skill['skill_id'])
```

### 2. Import one or many skills from GitHub

**Single**:

```python
manager.import_from_github(
    repo_url='https://github.com/org/repo',
    path='path/to/skill-dir',          # skill directory inside the repo
    skill_type=SkillType.SYSTEM.value,
    user_id='user-123',
    group_id='',                       # empty → auto-create an "owner/repo" group
)
```

**Batch scan (preview only)**:

```python
results = manager.importer.scan_github_batch(
    repo_url='https://github.com/org/repo',
    base_path='skills',                # skills/ directory inside the repo
    existing_names={'code-reviewer'},  # existing skill names to de-dup
)
for r in results:
    print(r.skill_name, r.file_count, r.exists_locally)
```

**Batch import**: `SkillManager.import_from_github_batch` (not expanded on this page) reuses `importer.import_from_github_batch` and calls `create_skill` / `update_skill` per entry.

**Gotchas**:

- `_parse_github_url` only matches `https://github.com/owner/repo`; other hosts fall through to `_clone_and_collect`, which depends on the system `git` command with `timeout=120s`.
- `_github_raw_fetch` only tries the `main` and `master` default branches; other branch names fall back to `git clone`.
- Unauthenticated GitHub REST calls rate-limit aggressively; batch scans across many skills may hit 429.

### 3. Trigger the full Skill Build Workflow

When you want the platform to **generate a Skill from a natural-language requirement**, you do not create files directly — you submit a `skill_build` project and let the five-stage agents produce the artifacts.

The main entry is the build workflow's orchestrator (see `prompts/system_agents_prompts/skill_build_workflow/`). Prompt files for the five stages:

| Stage | File | Main `tools_dependencies` |
|-------|------|---------------------------|
| 1 intent_recognition | `skill_intent_recognizer.yaml` | `strands_tools/current_time` |
| 2 skill_design | `skill_designer.yaml` | `get_project_info`, `get_stage_result`, `read_skill_reference` |
| 3 skill_development | `skill_developer.yaml` | `write_skill_file_to_s3`, `read_skill_file_from_s3`, `list_skill_files_in_s3`, `read_skill_reference`, `get_project_info`, `get_stage_result` |
| 4 skill_validation | `skill_validator.yaml` | `validate_skill_structure`, `read_skill_file_from_s3`, `list_skill_files_in_s3`, `write_skill_file_to_s3` |
| 5 skill_deployment | `skill_deployer.yaml` | `list_skill_files_in_s3`, `read_skill_file_from_s3` |

**Generated skills are classified as `SkillType.GENERATED`**: S3 prefix `skills/generated/{skill_id}/`, local mirror `skills/generated_skills/{skill_name}/`.

### 4. Execute a skill script from an agent

```python
from nexus_utils.skill import SkillManager
from nexus_utils.skill.runtime import skill_runtime

manager = SkillManager()
skill = manager.get_skill(skill_id, include_prompt=False)

result = skill_runtime.execute_script(
    skill_id=skill['skill_id'],
    skill_type=skill['skill_type'],
    skill_name=skill['skill_name'],
    script_path='scripts/run_eval.py',
    args=['--input', 'doc.docx'],
    timeout=60,
    env_vars={'OPENAI_API_KEY': '...'},
)

if not result.success:
    print(f"script failed: rc={result.return_code}, stderr={result.stderr}")
```

**Constraints**:

- `script_path` must be **relative to the skill directory** (e.g. `scripts/run.py`, not an absolute path).
- Only `.py`, `.sh`, `.js`, `.ts` are supported; other extensions return `return_code=-1`.
- Scripts run with the skill's local directory as `cwd`; `SKILL_DIR`, `SKILL_NAME`, `SKILL_ID` are injected automatically.
- Timeout defaults to 120 seconds, returning `return_code=-2` on expiry.

### 5. Register a new Skill-Build stage agent

If you need to extend the build workflow (for example, a new Stage 3.5 that does extra polishing):

1. Create a new `*.yaml` under `prompts/system_agents_prompts/skill_build_workflow/` with the top-level `agent:` key, including:
   - `name`, `description`, `category`
   - At least one entry under `environments` (`development` / `production` / `testing`)
   - At least one `version: latest` entry in `versions[]` with `system_prompt` / `user_prompt_template`
   - `metadata.tools_dependencies` listing the system tools you need
2. Call `PromptManager().reload()` or `load_single_prompt('system_agents_prompts/skill_build_workflow/your_agent.yaml')` to register dynamically (no restart).
3. Wire the new stage into the upstream orchestrator workflow definition; the output must line up with the downstream stage's `INPUT CONTEXT`.

### 6. Add a new scripting-language runtime

Edit `nexus_utils/skill/runtime.py:1659`:

```python
RUNTIME_MAP = {
    '.py': 'python',
    '.sh': 'bash',
    '.js': 'node',
    '.ts': 'npx ts-node',
    # new:
    '.rb': 'ruby',
}
```

Also check `LANG_MAP` at `nexus_utils/skill/models.py:1346` (used for file classification and the language tag on assembled prompt code blocks) and extend it if necessary.

### 7. Add a new entry to `SKILL_STANDARD_DIRS`

For example, to make the importer also collect a `hooks/` directory:

1. Add `'hooks'` to `SKILL_STANDARD_DIRS` in `nexus_utils/skill/models.py:1335`.
2. Add `hooks: List[str] = field(default_factory=list)` to `FileManifest`, and extend `to_dict()` and `_classify_file` accordingly.
3. If `hooks/` should appear in L2 prompt assembly, add a matching loop to `_assemble_prompt_from_local` / `_assemble_prompt_from_s3`.

## Debugging / Troubleshooting

| Symptom | Possible cause | Diagnostics |
|---------|----------------|-------------|
| `FileNotFoundError: No SKILL.md found` | No `SKILL.md` or `skill.md` in the target directory | `importer.py:399` / `625`; check filename casing |
| `[sync] No S3 files found for skill …` | No S3 objects for that skill_id — likely prefix mismatch | `storage.py:2418`; check the `s3_prefix` field — new rows should be `skills/{type}/{id}/` |
| `Script not found: {path}` | Wrong `script_path` passed to `execute_script` | `runtime.py:1780`; use a relative path without `./` |
| `Unsupported script type: {ext}` | Extension not in `RUNTIME_MAP` | `runtime.py:1789` |
| `Script timed out after {n} seconds` | Default 120 s hit | Pass a larger `timeout=` |
| `git clone failed: …` | Non-GitHub fallback failed | `importer.py:643`; check network and private-repo credentials |
| `Failed to parse SKILL.md frontmatter: …` | Invalid YAML | `importer.py:188`; check the `---` delimiters |
| `register_built_skill` leaves `local_path=''` | S3→local sync failed | `manager.py:1019` emits `logger.warning(f"…Local sync failed")`; check disk write permissions |
| `[s3] Failed to upload …` on every file | AWS credentials or bucket permission | Raised from `storage.py:2290`; check `boto3` configuration |

**Key log prefixes**:

| Prefix | Module |
|--------|--------|
| `[create] / [update] / [delete]` | `SkillManager` |
| `[register_built_skill]` | `SkillManager.register_built_skill` |
| `[local]` / `[s3]` / `[sync]` / `[ensure]` | `SkillStorage` |
| `[runtime]` | `SkillRuntime` |
| `[claude-code]` / `[batch]` / `[scan]` | `SkillImporter` |

**Common diagnostic commands**:

```bash
# Inspect skill files on S3
aws s3 ls s3://{artifacts_bucket}/skills/{skill_type}/{skill_id}/ --recursive

# Inspect local mirror
ls -laR skills/{skill_type}_skills/{skill_name}

# DDB metadata row
aws dynamodb get-item --table-name nexus_skills \
  --key '{"skill_id":{"S":"sk-xxxx"}}'
```

## Further Reading

- Adding agents: `drafts/developer/en/adding-agents.md` — Skills supply capability templates that agents load via `get_full_prompt` during the reasoning loop.
- Adding tools: `drafts/developer/en/adding-tools.md` — the relationship between a Skill's `tools` frontmatter field and agent tool registration.
- Stage engine: `drafts/developer/en/stage-engine.md` — the five stages of the Skill Build Workflow are driven by the Stage Engine.
- Worker: `drafts/developer/en/worker.md` — where `BuildHandlerV2._post_skill_deployment` calls `register_built_skill`.
- Source anchors:
  - `nexus_utils/skill/__init__.py` — public API exports
  - `nexus_utils/skill/manager.py:709` — `SkillManager` class
  - `nexus_utils/skill/storage.py:2030` — `SkillStorage` class
  - `nexus_utils/skill/importer.py:123` — `SkillImporter` class
  - `nexus_utils/skill/runtime.py:1667` — `SkillRuntime` class
  - `nexus_utils/prompts_manager.py:13453` — `PromptManager` singleton
  - `prompts/system_agents_prompts/skill_build_workflow/` — five stage agents
