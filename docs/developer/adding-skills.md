---
title: 添加技能
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

# 添加技能

## 概述

Nexus-AI 的 "Skill" 是**兼容 Anthropic Agent Skills 标准**的能力包，由一份 `SKILL.md`（YAML frontmatter + Markdown 正文）和可选的 `scripts/` / `references/` / `evals/` / `agents/` / `assets/` / `eval-viewer/` / `config/` 子目录组成。Skill 通过 `description` 字段**触发式加载**——当用户需求匹配 description 时，Claude 才加载 SKILL.md 正文，需要脚本或参考文档时再按需加载，从而实现 **L1（元数据）→ L2（正文 + references + scripts 拼装）→ L3（按需执行脚本）** 的渐进式信息暴露。

Skill 子系统的权威实现位于 `nexus_utils/skill/` 包，设计为**多端共用**（api / worker / cli），不依赖 FastAPI 或其他 Web 框架。核心组件有四个：`SkillStorage`（本地文件系统 + S3 双层存储）、`SkillImporter`（GitHub / URL / Claude Code / 本地目录四种导入源）、`SkillRuntime`（`subprocess` 执行脚本 / shell 命令）、`SkillManager`（对上述三者的统一入口，负责 CRUD、DDB 元数据同步、文件清单构建）。

平台同时内置一条**五阶段 Skill 构建工作流**（`prompts/system_agents_prompts/skill_build_workflow/`），由大模型从自然语言需求反向生成完整的 Skill 包：`intent_recognition` → `skill_design` → `skill_development` → `skill_validation` → `skill_deployment`。阶段 Agent 的提示词由 `nexus_utils/prompts_manager.py` 的 `PromptManager` 单例加载，提示词与 `agent:` 顶层键对齐。

主要入口与职责：

| 入口 | 文件 | 职责 |
|------|------|------|
| Skill 统一管理 | `nexus_utils/skill/manager.py:709`（`SkillManager`） | CRUD、导入、分组、L1/L2 加载 |
| 本地 + S3 存储 | `nexus_utils/skill/storage.py:2030`（`SkillStorage`） | 读写、sync、manifest、prompt 组装 |
| 多源导入 | `nexus_utils/skill/importer.py:123`（`SkillImporter`） | GitHub / URL / Claude Code / 本地目录 |
| 脚本执行运行时 | `nexus_utils/skill/runtime.py:1667`（`SkillRuntime`） | `subprocess` 隔离执行 |
| 数据模型 | `nexus_utils/skill/models.py` | `SkillType`、`SkillInfo`、`FileManifest` 等 |
| 构建工作流 Stage 1 | `prompts/system_agents_prompts/skill_build_workflow/skill_intent_recognizer.yaml` | 解析需求、生成 skill_name |
| 构建工作流 Stage 2 | `prompts/system_agents_prompts/skill_build_workflow/skill_designer.yaml` | 设计 SKILL.md 大纲和脚本计划 |
| 构建工作流 Stage 3 | `prompts/system_agents_prompts/skill_build_workflow/skill_developer.yaml` | 生成文件并写入 S3 |
| 构建工作流 Stage 4 | `prompts/system_agents_prompts/skill_build_workflow/skill_validator.yaml` | 结构 / 内容质量 / evals 验证 |
| 构建工作流 Stage 5 | `prompts/system_agents_prompts/skill_build_workflow/skill_deployer.yaml` | 汇总元数据，触发 DDB 注册 |
| 提示词加载 | `nexus_utils/prompts_manager.py:13453`（`PromptManager`） | 读取 `prompts/**/*.yaml`，支持 DDB+S3 懒加载 |

## 文件组织（File Layout）

| 路径 | 责任 | 主要依赖 |
|------|------|----------|
| `nexus_utils/skill/__init__.py` | 公开导出（`SkillType`、`SkillInfo`、`SkillManager` 等） | 子模块 |
| `nexus_utils/skill/models.py` | 数据模型、枚举、文件分类、`SKILL_STANDARD_DIRS` 常量 | `dataclasses`, `enum` |
| `nexus_utils/skill/storage.py` | 本地 + S3 双层存储、S3 缓存、prompt 组装 | `boto3`, `pathlib`, `threading` |
| `nexus_utils/skill/importer.py` | 四种来源导入、GitHub raw + REST 双通道、git clone 回退 | `httpx`, `yaml`, `subprocess` |
| `nexus_utils/skill/runtime.py` | 脚本 / shell 命令的 `subprocess` 执行、超时、环境变量注入 | `subprocess`, `time` |
| `nexus_utils/skill/manager.py` | 聚合入口：CRUD + 导入编排 + DDB 同步 + 分组管理 | 上述三个子模块 + `api.v2.database` |
| `prompts/system_agents_prompts/skill_build_workflow/skill_intent_recognizer.yaml` | Stage 1 意图识别 Agent 提示词 | `strands_tools/current_time` |
| `prompts/system_agents_prompts/skill_build_workflow/skill_designer.yaml` | Stage 2 设计 Agent 提示词 | `read_skill_reference` 等 |
| `prompts/system_agents_prompts/skill_build_workflow/skill_developer.yaml` | Stage 3 开发 Agent 提示词 | `write_skill_file_to_s3` 等 |
| `prompts/system_agents_prompts/skill_build_workflow/skill_validator.yaml` | Stage 4 验证 Agent 提示词 | `validate_skill_structure` 等 |
| `prompts/system_agents_prompts/skill_build_workflow/skill_deployer.yaml` | Stage 5 部署 Agent 提示词 | `list_skill_files_in_s3` 等 |
| `prompts/template_prompts/*.yaml` | 模板 Agent 提示词（含 `default.yaml`） | — |
| `nexus_utils/prompts_manager.py` | `PromptManager` 单例：解析 YAML、懒加载、版本路由 | `yaml`, `pathlib` |
| `skills/system_skills/&lt;name&gt;/` | 平台内置 Skill 本地存储根 | — |
| `skills/generated_skills/&lt;name&gt;/` | 工作流生成的 Skill 本地镜像 | — |
| `s3://{artifacts_bucket}/skills/{skill_id}/` | Skill 文件的 S3 权威副本 | `boto3` |
| `s3://{artifacts_bucket}/skills/{skill_type}/{skill_id}/` | 新版按类型分层的 S3 前缀 | `boto3` |

## 核心类型 / 类 / 数据结构

### `SkillType` 枚举（`nexus_utils/skill/models.py:1277`）

| 值 | 语义 | 本地目录 |
|----|------|----------|
| `"system"` | 平台内置 / 导入后归档的 Skill | `skills/system_skills/` |
| `"generated"` | 由构建工作流生成的 Skill | `skills/generated_skills/` |
| `"community"` | 社区贡献 | `skills/community_skills/` |
| `"private"` | 用户私有 | `skills/private_skills/` |

### `SourceType` 枚举（`nexus_utils/skill/models.py:1285`）

| 值 | 含义 |
|----|------|
| `"claude-code"` | 从 Claude Code 本地目录导入 |
| `"github"` | 从 GitHub 仓库导入（单个 / 批量） |
| `"url"` | 直接从 SKILL.md URL 导入（只含 SKILL.md） |
| `"manual"` | 手动创建 |
| `"platform"` | 构建工作流产出 |

### `SKILL_STANDARD_DIRS` 常量（`nexus_utils/skill/models.py:1335`）

导入器在递归收集文件时**只进入以下标准子目录**，其他目录被忽略：

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

### `FileInfo`（`nexus_utils/skill/models.py:1392`）

| 字段 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `key` | `str` | — | 相对路径（如 `scripts/run.py`） |
| `size` | `int` | `0` | 文件大小（字节） |
| `file_type` | `str` | `"other"` | `prompt` / `script` / `reference` / `agent` / `asset` / `eval` / `config` / `other` |
| `language` | `str` | `""` | 由扩展名推导的编程语言 |
| `last_modified` | `str` | `""` | ISO 格式最后修改时间 |

### `FileManifest`（`nexus_utils/skill/models.py:1413`）

| 字段 | 类型 | 说明 |
|------|------|------|
| `prompt` | `List[str]` | `SKILL.md` / `skill.md` |
| `scripts` | `List[str]` | `scripts/` 下的文件 |
| `references` | `List[str]` | `references/` 下 + 顶层 `.md` |
| `agents` | `List[str]` | `agents/` 下的文件 |
| `assets` | `List[str]` | `assets/` 下的文件 |
| `evals` | `List[str]` | `evals/` + `eval-viewer/` 下的文件 |
| `config` | `List[str]` | `config/` 下的文件 |
| `other` | `List[str]` | 其他文件 |

分类规则：`FileManifest._classify_file(key)`（`nexus_utils/skill/models.py:1443`）。顶层 `.md` 文件归入 `references`，`SKILL.md` / `skill.md` 归入 `prompt`。

### `SkillInfo`（`nexus_utils/skill/models.py:1474`）

DDB `nexus_skills` 表的单行数据类。字段总览：

| 字段 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `skill_id` | `str` | — | 主键，`sk-{uuid}` 格式 |
| `skill_name` | `str` | — | kebab-case 名称 |
| `description` | `str` | `""` | 触发导向型描述 |
| `skill_type` | `str` | `"system"` | `SkillType` 枚举值 |
| `category` | `str` | `"general"` | 分类 |
| `tools` | `List[str]` | `[]` | SKILL.md frontmatter 中的 `tools` |
| `tags` | `List[str]` | `[]` | 标签 |
| `version` | `Optional[str]` | `None` | 版本号 |
| `source` | `Optional[Dict]` | `None` | 来源元数据（`type`/`url`/`path`/`import_hash`） |
| `group_id` | `str` | `""` | 所属分组 ID |
| `local_path` | `str` | `""` | 本地目录绝对路径 |
| `s3_prefix` | `str` | `""` | S3 前缀（`skills/{id}/` 或 `skills/{type}/{id}/`） |
| `file_manifest` | `Optional[Dict]` | `None` | `FileManifest.to_dict()` |
| `s3_files` | `List[Dict]` | `[]` | `FileInfo.to_dict()` 列表 |
| `has_scripts` | `bool` | `False` | `scripts/` 非空 |
| `has_agents` | `bool` | `False` | `agents/` 非空 |
| `has_evals` | `bool` | `False` | `evals/` 非空 |
| `script_runtime` | `str` | `""` | `python` / `bash` / `node` / `mixed` |
| `local_synced` | `bool` | `False` | 本地与 S3 是否一致 |
| `last_synced_at` | `str` | `""` | ISO 时间戳 |
| `is_public` | `bool` | `True` | 公开标志（DDB GSI 要求 `"true"`/`"false"` 字符串） |
| `user_id` | `str` | `"system"` | 创建者 |
| `star_count` | `int` | `0` | 点赞数 |
| `usage_count` | `int` | `0` | 使用次数 |
| `total_size` | `int` | `0` | 所有文件总字节数 |
| `l1_summary` | `str` | `""` | ≤ 200 字符的 L1 摘要 |
| `readme` | `Optional[str]` | `None` | SKILL.md 原文（可选） |
| `parameters` | `Dict` | `{}` | 预留参数字段 |
| `created_at` / `updated_at` | `str` | `""` | ISO 时间戳 |

### `SkillGroupInfo`（`nexus_utils/skill/models.py:1294`）

| 字段 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `group_id` | `str` | — | 分组主键 |
| `group_name` | `str` | — | 分组名称 |
| `source_type` | `str` | `""` | `github` / `claude-code` / `url` / `manual` |
| `source_url` | `str` | `""` | 来源 URL |
| `source_path` | `str` | `""` | 来源内部路径 |
| `skill_count` | `int` | `0` | 分组内 Skill 数量 |
| `group_type` | `str` | `"source"` | `source`（来源分组）/ `combo`（虚拟组合） |
| `skill_ids` | `list` | `[]` | 虚拟组合关联的 skill_id |

### `ScanResult`（`nexus_utils/skill/models.py:1562`）

GitHub 批量扫描的预览结果（**不实际导入**）：

| 字段 | 类型 | 说明 |
|------|------|------|
| `skill_name` | `str` | 目录名（回退自 frontmatter） |
| `path` | `str` | 仓库内路径 |
| `has_skill_md` | `bool` | 是否找到 `SKILL.md` / `skill.md` |
| `file_count` | `int` | 文件数量（含子目录计 1） |
| `total_size` | `int` | 总字节数 |
| `exists_locally` | `bool` | 本地是否已有同名 Skill |
| `import_hash` | `str` | 内容 SHA |

### `ExecutionResult`（`nexus_utils/skill/models.py:1586`）

`SkillRuntime.execute_script` / `execute_command` 的返回值：

| 字段 | 类型 | 说明 |
|------|------|------|
| `success` | `bool` | `return_code == 0` |
| `stdout` | `str` | 标准输出（`execute_command` 截断尾部 5000 字节） |
| `stderr` | `str` | 标准错误（`execute_command` 截断尾部 2000 字节） |
| `return_code` | `int` | 退出码；`-1` 脚本不存在 / 不支持、`-2` 超时、`-3` 异常 |
| `duration_ms` | `int` | 执行耗时 |

### `ImportResult`（`nexus_utils/skill/models.py:1546`）

| 字段 | 类型 | 说明 |
|------|------|------|
| `imported` | `List[str]` | 成功导入的 Skill 名称 |
| `skipped` | `List[str]` | 已存在跳过的名称 |
| `errors` | `List[str]` | 错误信息 |

### 语言与 Content-Type 映射

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

## 关键函数 / 方法

### `SkillManager`（`nexus_utils/skill/manager.py:709`）

统一管理入口。构造时可注入 `storage` / `importer` / `runtime`，默认使用模块级单例 `skill_storage` / 新建的 `SkillImporter` / `skill_runtime`。DB 客户端 (`self.db`) **延迟加载**自 `api.v2.database`。

L1 摘要字段白名单（列表页只返回这些字段）：

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

| 方法 | 签名 | 职责 | 调用顺序 |
|------|------|------|----------|
| `create_skill` | `create_skill(skill_name, skill_type='system', description='', system_prompt_snippet='', tools=None, parameters=None, category='general', user_id='system', is_public=True, tags=None, source=None, version=None, readme=None, content_files=None, group_id='') -> Dict` | 写本地 → 上传 S3 → 写 DDB | `save_to_local` → `save_to_s3` → `build_file_manifest` → `detect_script_runtime` → `db.create_skill` |
| `register_built_skill` | `register_built_skill(skill_id, skill_name, project_id, stage_result, user_id='system') -> Dict` | 工作流产出回注：S3 已存在 → 构建 manifest → 写 DDB → S3 同步到本地 | `list_s3_files` → `build_file_manifest` → `db.create_skill` → `sync_s3_to_local` |
| `get_skill` | `get_skill(skill_id, include_prompt=True) -> Optional[Dict]` | L2 加载：附加拼装好的 `system_prompt_snippet` | `db.get_skill` → `storage.get_full_prompt` |
| `list_skills` | `list_skills(user_id=None, category=None, skill_type=None, search=None) -> List[Dict]` | L1 列表：按字段白名单过滤 | `db.list_skills` → L1_FIELDS 投影 |
| `update_skill` | `update_skill(skill_id, updates) -> Optional[Dict]` | 更新元数据 / 文件；`content_files` 同步到 S3 和本地 | `save_to_local` → `save_to_s3` → `build_file_manifest` → `db.update_skill` |
| `delete_skill` | `delete_skill(skill_id) -> bool` | 三层清理：本地 → S3 → DDB | `delete_local_skill` → `delete_s3_files` → `db.delete_skill` |
| `import_from_github` | `import_from_github(repo_url, path='', skill_type='system', user_id='system', group_id='') -> Dict` | 单 Skill 导入 + 分组归属 + 内容哈希去重 | `importer.import_from_github` → `ensure_group` → `update_skill` 或 `create_skill` |

> 因源码文件较长，`import_from_github` 之后还有 `import_from_github_batch` / `scan_github` / `import_from_claude_code` / `import_from_local_dir` / `import_from_url` / `ensure_group` / `list_groups` / `_find_existing_skill` 等方法，均以类似模式编排 `importer` + `storage` + `db`。

### `SkillImporter`（`nexus_utils/skill/importer.py:123`）

**四种导入源**对应的主入口：

| 来源 | 方法 | 签名 | 关键行为 |
|------|------|------|----------|
| GitHub 单 Skill | `import_from_github` | `import_from_github(repo_url, path='') -> Tuple[Dict[str, bytes], Dict[str, Any]]` | 解析 `https://github.com/owner/repo` → `_fetch_github_skill_files`（raw + REST）；非 GitHub URL → `_clone_and_collect` 回退 |
| GitHub 批量 | `scan_github_batch` | `scan_github_batch(repo_url, base_path='', existing_names=None) -> List[ScanResult]` | 扫描目录，返回预览；**不导入** |
| GitHub 批量导入 | `import_from_github_batch` | `import_from_github_batch(repo_url, base_path='', filter_names=None) -> List[Tuple[Dict, Dict, str]]` | 按 `filter_names` 批量拉取 |
| URL | `import_from_url` | `import_from_url(url) -> Tuple[Dict[str, bytes], Dict[str, Any]]` | 仅获取 `SKILL.md`，从 URL 推断 `skill_name` |
| Claude Code 扫描 | `scan_claude_code_paths` | `scan_claude_code_paths(scan_paths: List[str]) -> List[Path]` | 展开 `~`、扫描一级子目录下的 `SKILL.md` |
| 本地目录 | `import_from_local_dir` | `import_from_local_dir(skill_dir: Path) -> Tuple[Dict[str, bytes], Dict[str, Any]]` | 调用 `collect_skill_files` |

**SKILL.md 解析**：`parse_skill_md(content: str) -> Dict` (`importer.py:131`) 返回：

| 键 | 类型 | 含义 |
|----|------|------|
| `skill_name` | `str` | frontmatter `name` |
| `description` | `str` | frontmatter `description` |
| `tools` | `List[str]` | frontmatter `tools`（支持逗号分隔字符串或列表） |
| `version` | `Optional[str]` | frontmatter `version`（转为字符串） |
| `system_prompt_snippet` | `str` | frontmatter 之后的正文 |

**文件收集**：`collect_skill_files(skill_dir: Path) -> Dict[str, bytes]`（`importer.py:199`）。收集顶层非隐藏文件 + `SKILL_STANDARD_DIRS` 中每个标准子目录下的所有文件；跳过 `__pycache__` 和 `.` 开头的文件。

**GitHub 内部方法**（静态 / 私有）：

| 方法 | 签名 | 用途 |
|------|------|------|
| `_parse_github_url` | `_parse_github_url(repo_url: str) -> Optional[Tuple[str, str]]` | 正则 `https?://github\.com/([^/]+)/([^/]+?)(?:\.git)?/?$` |
| `_github_raw_fetch` | `_github_raw_fetch(owner, repo, file_path) -> Optional[bytes]` | 试 `main`/`master` 两个分支的 raw URL |
| `_github_api_list_dir` | `_github_api_list_dir(owner, repo, dir_path) -> Optional[List[Dict]]` | 调用 `api.github.com/repos/.../contents/...` |
| `_fetch_github_skill_files` | 内部方法 | 组合 `raw` + `API`：先取 `SKILL.md`，再列目录、递归取标准子目录 |
| `_fetch_github_dir_recursive` | 内部方法 | 深度递归标准子目录 |
| `_clone_and_collect` | `_clone_and_collect(repo_url, path='') -> Dict[str, bytes]` | 非 GitHub URL 的回退：`git clone --depth 1` 到临时目录 |

### `SkillStorage`（`nexus_utils/skill/storage.py:2030`）

本地 + S3 双层存储。默认本地根 `skills/`，S3 桶从 `config.get_nexus_ai_config().get('artifacts_s3_bucket', 'nexus-ai-artifacts-2026')` 读取；AWS 区域默认 `us-west-2`。S3 客户端和 S3 缓存都是**惰性初始化**，无 AWS 环境时创建对象不抛错。

**本地存储**：

| 方法 | 签名 | 说明 |
|------|------|------|
| `get_local_skill_dir` | `get_local_skill_dir(skill_type, skill_name) -> Path` | 路径：`{local_base}/{skill_type}_skills/{skill_name}` |
| `save_to_local` | `save_to_local(skill_type, skill_name, files: Dict[str, bytes]) -> Path` | 按相对路径逐个写入 |
| `read_local_file` | `read_local_file(skill_type, skill_name, rel_path) -> Optional[bytes]` | — |
| `list_local_files` | `list_local_files(skill_type, skill_name) -> List[FileInfo]` | 跳过 `.` 和 `__pycache__` |
| `local_skill_exists` | `local_skill_exists(skill_type, skill_name) -> bool` | 判断 `SKILL.md` 存在 |
| `delete_local_skill` | `delete_local_skill(skill_type, skill_name) -> bool` | `shutil.rmtree` |
| `collect_local_files` | `collect_local_files(skill_type, skill_name) -> Dict[str, bytes]` | 读全文件内容为字典 |
| `collect_directory_files` | `collect_directory_files(directory: Path) -> Dict[str, bytes]` | 通用目录收集，跳过 `.`/`__pycache__`/`node_modules` |

**S3 存储**：

| 方法 | 签名 | 说明 |
|------|------|------|
| `get_s3_prefix` | `get_s3_prefix(skill_id, skill_type='') -> str` | 传入 `skill_type` 返回 `skills/{type}/{id}/`；否则 `skills/{id}/`（兼容旧数据） |
| `save_to_s3` | `save_to_s3(skill_id, files: Dict[str, bytes], skill_type='') -> Dict` | 先清缓存、逐文件 `put_object`、返回 `s3_prefix`/`s3_files`/`total_size` |
| `read_s3_file` | `read_s3_file(skill_id, rel_path) -> Optional[bytes]` | 内存缓存；`NoSuchKey` 写入 `_NOT_FOUND` 哨兵 |
| `list_s3_files` | `list_s3_files(skill_id) -> List[FileInfo]` | 使用 `list_objects_v2` 分页器 |
| `delete_s3_files` | `delete_s3_files(skill_id) -> int` | 1000 一批调用 `delete_objects` |

**同步**：

| 方法 | 签名 | 说明 |
|------|------|------|
| `sync_s3_to_local` | `sync_s3_to_local(skill_id, skill_type, skill_name) -> Path` | 先用无类型前缀查；找不到再用 `skills/{type}/{id}/` 前缀 |
| `sync_local_to_s3` | `sync_local_to_s3(skill_type, skill_name, skill_id) -> Dict` | 收集本地文件 → `save_to_s3(skill_type=skill_type)` |
| `ensure_local` | `ensure_local(skill_id, skill_type, skill_name) -> Path` | 本地不存在则 `sync_s3_to_local` |

**Prompt 组装（L2 加载）**：

| 方法 | 签名 | 说明 |
|------|------|------|
| `get_full_prompt` | `get_full_prompt(skill_id, skill_type='', skill_name='') -> str` | 优先本地，本地缺失再走 S3 |
| `_assemble_prompt_from_local` | 内部方法 | 读 `SKILL.md` → 追加 `references/*.md` → 追加 `scripts/**` 作为代码块 |
| `_assemble_prompt_from_s3` | 内部方法 | 同上逻辑，但从 S3 拉取，二进制文件 (`UnicodeDecodeError`) 跳过 |

**工具方法**：`compute_content_hash(files) -> str` 返回所有 `(key, content)` 串起来的 SHA256，用于导入去重。

### `SkillRuntime`（`nexus_utils/skill/runtime.py:1667`）

脚本与 shell 命令执行，默认超时 120 秒：

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

| 方法 | 签名 | 说明 |
|------|------|------|
| `ensure_workspace` | `ensure_workspace(skill_id, skill_type, skill_name) -> Path` | 委托 `storage.ensure_local` |
| `list_scripts` | `list_scripts(skill_type, skill_name) -> List[Dict]` | 枚举 `scripts/` 下可执行脚本，过滤 `__init__.py` / `__pycache__` |
| `execute_script` | `execute_script(skill_id, skill_type, skill_name, script_path, args=None, timeout=120, env_vars=None) -> ExecutionResult` | 解析扩展名 → 选择 runtime → `subprocess.run(cwd=skill_dir)` |
| `execute_command` | `execute_command(skill_id, skill_type, skill_name, command, timeout=120, env_vars=None) -> ExecutionResult` | `subprocess.run(shell=True, cwd=skill_dir)`；stdout/stderr 截断尾部 |
| `detect_script_runtime` | `detect_script_runtime(skill_type, skill_name) -> str` | 返回 `python` / `bash` / `node` / `mixed` / `""` |

**环境变量注入**：执行任何脚本 / 命令时都会注入

| 变量 | 值 |
|------|----|
| `SKILL_DIR` | Skill 本地绝对路径（`.resolve()`） |
| `SKILL_NAME` | 传入的 `skill_name` |
| `SKILL_ID` | 传入的 `skill_id` |

**退出码约定**：`-1` = 脚本不存在 / 不支持的扩展名；`-2` = 超时；`-3` = 其他异常。

### `PromptManager`（`nexus_utils/prompts_manager.py:13453`）

提示词加载与路由的**全局单例**（`__new__` 锁定 `_instance`，`_initialized` 守护 `__init__`）。构造时扫描 `./prompts` 下所有 `*.yaml`，解析顶层键 `agent:`（`name` / `description` / `category` / `environments` / `versions[]`）。

| 方法 | 签名 | 用途 |
|------|------|------|
| `load_prompts` | `load_prompts() -> None` | 递归 `os.walk('./prompts')`，加载所有 `.yaml` |
| `get_agent` | `get_agent(agent_name: str) -> Optional[PromptAgent]` | 先查内存缓存；未命中尝试 DDB+S3 懒加载（`_try_load_from_s3`） |
| `reload` | `reload() -> None` | 清空缓存重新加载，运行时动态注册新提示词 |
| `load_single_prompt` | `load_single_prompt(prompt_file_path: str) -> bool` | 部署单个新 Agent 后热加载 |
| `_resolve_agent_record_from_ddb` | 内部方法 | `identifier` 可以是 agent_id（36 字符带 4 个 `-` 的 UUID）、`agent_name_en` 或 `relative_path` |

`PromptAgent` (`prompts_manager.py:13412`) 持有 `versions: Dict[str, PromptVersion]`，`get_version(version='latest')` 优先返回显式 `latest` 版本，否则按 `_version_key` 排序取最高版本号（`"2.0.0" -> (2, 0, 0)`）。

提示词中的 `metadata.tools_dependencies` 列表控制该 Agent 实际注入的工具（参见构建工作流 YAML 中的 `tools_dependencies` 字段）。

## 目录与 S3 布局

### 本地目录布局

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

`_ensure_local_dirs`（`storage.py:2061`）在 `SkillStorage.__init__` 时创建上述四个根目录。

### S3 布局

新写入的 Skill 使用按类型分层的前缀：

```
s3://{artifacts_bucket}/skills/{skill_type}/{skill_id}/
                                           ├── SKILL.md
                                           ├── scripts/...
                                           ├── references/...
                                           └── evals/...
```

旧数据兼容前缀：`skills/{skill_id}/`（不带 `skill_type`）。`sync_s3_to_local` 会**先尝试旧前缀**再回退到新前缀，保证存量数据可读。

### SKILL.md frontmatter 标准

```yaml
---
name: skill-name
description: 触发导向型描述。Use this skill whenever...
tools: Read, Glob, Grep           # 可选，逗号分隔
version: 1.0.0                    # 可选
---
# Markdown 正文（<500 行）
```

`parse_skill_md` 对缺失 `---` 的文件做降级：整个内容作为 `system_prompt_snippet`，其余字段置空。

## 调用关系 / 数据流

### 写入：创建 / 导入

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

### 读取：列表 / 详情 / Prompt

```
list_skills  ─▶ db.list_skills ─▶ L1_FIELDS 投影
get_skill    ─▶ db.get_skill
             └─▶ storage.get_full_prompt
                 ├─(本地存在)▶ _assemble_prompt_from_local
                 └─(本地缺失)▶ _assemble_prompt_from_s3
                              └─▶ list_s3_files → read_s3_file（带缓存）
```

### GitHub 导入流程

```
SkillImporter.import_from_github(repo_url, path)
    │
    ├─[URL 匹配 github.com?]
    │   ├─ 是 ─▶ _fetch_github_skill_files
    │   │        ├─ _github_raw_fetch(SKILL.md)         (main + master)
    │   │        ├─ _github_api_list_dir(skill_path)
    │   │        ├─ 顶层文件 raw_fetch
    │   │        └─ 对每个 SKILL_STANDARD_DIR:
    │   │             _fetch_github_dir_recursive
    │   └─ 否 ─▶ _clone_and_collect
    │             └─ git clone --depth 1 + collect_skill_files
    │
    └─▶ parse_skill_md(files['SKILL.md'])
```

### 脚本执行

```
SkillRuntime.execute_script
    │
    ├─▶ ensure_workspace ─▶ storage.ensure_local ─▶ (可能) sync_s3_to_local
    │
    ├─[ext 在 RUNTIME_MAP?]
    │   └─否 ─▶ ExecutionResult(return_code=-1)
    │
    ├─ env = {**os.environ, SKILL_DIR, SKILL_NAME, SKILL_ID, **env_vars}
    │
    └─▶ subprocess.run(cmd, cwd=skill_dir, timeout=timeout, env=env)
         ├─ TimeoutExpired ─▶ return_code=-2
         └─ Exception      ─▶ return_code=-3
```

### Skill Build Workflow（五阶段）

```
User 需求
    │
    ├─ Stage 1: skill_intent_recognizer
    │           输出: {skill_name, skill_description_draft, trigger_scenarios, tags, ...}
    │
    ├─ Stage 2: skill_designer
    │           输入: intent_recognition result
    │           输出: {skill_md_design, scripts_plan, references_plan, evals_plan, directory_structure}
    │           工具: read_skill_reference, get_project_info, get_stage_result
    │
    ├─ Stage 3: skill_developer
    │           输入: intent + design
    │           输出: {files[], skill_md_summary, tags, category, version}
    │           工具: write_skill_file_to_s3, read_skill_file_from_s3, read_skill_reference
    │           副作用: 向 s3://…/skills/{skill_type}/{skill_id}/ 写入所有文件
    │
    ├─ Stage 4: skill_validator
    │           输入: design + development
    │           输出: {validation_summary, structure_validation, content_quality, evals_validation, issues[]}
    │           工具: validate_skill_structure, read_skill_file_from_s3, write_skill_file_to_s3
    │
    └─ Stage 5: skill_deployer
                输入: 全部前序 INPUT CONTEXT
                输出: DDB 注册元数据 JSON（skill_id/name/description/s3_files/tags/category/version/has_* 等）
                工具: list_skill_files_in_s3, read_skill_file_from_s3
                Worker 回调: SkillManager.register_built_skill
```

Stage 5 产出的 JSON 直接对齐 DDB `nexus_skills` 表 schema，由 Worker 端 (`BuildHandlerV2._post_skill_deployment`) 调用 `SkillManager.register_built_skill`，后者负责：

1. `list_s3_files` 回读 S3 文件清单
2. 构建 `FileManifest`
3. 调用 `db.create_skill` 写入 DDB
4. `sync_s3_to_local` 把文件刻到 `skills/generated_skills/{skill_name}/`
5. 回写 DDB `local_path` / `local_synced` / `last_synced_at`

## 扩展点（Extending）

### 1. 新增一个平台内置 Skill（手动）

**目标**：把一个自制 Skill 放入 `skills/system_skills/&lt;name&gt;/`，同时登记到 DDB。

步骤：

1. 在本地目录准备标准结构：
   ```
   skills/system_skills/<name>/
   ├── SKILL.md           # 必须：YAML frontmatter + 正文
   ├── scripts/           # 可选
   │   └── *.py | *.sh | *.js | *.ts
   ├── references/        # 可选
   │   └── *.md
   └── evals/             # 可选
       └── evals.json
   ```
2. 通过 `SkillImporter.import_from_local_dir(Path('skills/system_skills/&lt;name&gt;'))` 读取并解析 `SKILL.md`。
3. 调用 `SkillManager.create_skill(...)` 传入 `content_files`（来自 `collect_skill_files`）、`skill_type=SkillType.SYSTEM.value`、`source={'type': 'manual'}`。

**最小代码范例**：

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

### 2. 从 GitHub 导入一个或多个 Skill

**单个**：

```python
manager.import_from_github(
    repo_url='https://github.com/org/repo',
    path='path/to/skill-dir',          # 仓库内的 Skill 目录
    skill_type=SkillType.SYSTEM.value,
    user_id='user-123',
    group_id='',                       # 留空则自动创建以 owner/repo 命名的分组
)
```

**批量扫描（预览）**：

```python
results = manager.importer.scan_github_batch(
    repo_url='https://github.com/org/repo',
    base_path='skills',                # 仓库下的 skills/ 目录
    existing_names={'code-reviewer'},  # 已存在的 skill 名，用于去重
)
for r in results:
    print(r.skill_name, r.file_count, r.exists_locally)
```

**批量导入**：`SkillManager.import_from_github_batch`（未在本页展开）会复用 `importer.import_from_github_batch`，逐个调用 `create_skill` / `update_skill`。

**陷阱**：

- `_parse_github_url` 只匹配 `https://github.com/owner/repo` 形式，其他 host 走 `_clone_and_collect`（依赖系统 `git` 命令，`timeout=120s`）。
- `_github_raw_fetch` 仅尝试 `main` / `master` 两个默认分支，其他分支名会 fallback 到 `git clone`。
- GitHub REST API 无 Token 时限流较严，批量扫描数量多时可能被 429。

### 3. 触发完整的 Skill Build Workflow

当你想让平台**从自然语言需求自动生成 Skill** 时，不是直接创建文件，而是提交一个 `skill_build` 项目，让五阶段 Agent 生成产物。

核心入口是构建 workflow 的 orchestrator（见 `prompts/system_agents_prompts/skill_build_workflow/`）。五个阶段的提示词文件：

| Stage | 文件 | 主要工具依赖（`tools_dependencies`） |
|-------|------|--------------------------------------|
| 1 intent_recognition | `skill_intent_recognizer.yaml` | `strands_tools/current_time` |
| 2 skill_design | `skill_designer.yaml` | `get_project_info`, `get_stage_result`, `read_skill_reference` |
| 3 skill_development | `skill_developer.yaml` | `write_skill_file_to_s3`, `read_skill_file_from_s3`, `list_skill_files_in_s3`, `read_skill_reference`, `get_project_info`, `get_stage_result` |
| 4 skill_validation | `skill_validator.yaml` | `validate_skill_structure`, `read_skill_file_from_s3`, `list_skill_files_in_s3`, `write_skill_file_to_s3` |
| 5 skill_deployment | `skill_deployer.yaml` | `list_skill_files_in_s3`, `read_skill_file_from_s3` |

**生成的 Skill 会落到 `SkillType.GENERATED`**：S3 前缀 `skills/generated/{skill_id}/`，本地镜像 `skills/generated_skills/{skill_name}/`。

### 4. 在 Agent 中调用 Skill 脚本

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

**约束**：

- `skill_path` 必须是**相对于 Skill 目录的路径**（如 `scripts/run.py`，不是绝对路径）。
- 仅支持 `.py` / `.sh` / `.js` / `.ts` 四种扩展名，其他返回 `return_code=-1`。
- 脚本以 Skill 本地目录为 `cwd` 执行；`SKILL_DIR` / `SKILL_NAME` / `SKILL_ID` 自动注入 env。
- 超时默认 120 秒，返回 `return_code=-2`。

### 5. 注册一个新的 Skill Build Stage Agent

如果你需要扩展构建工作流（例如加一个 Stage 3.5 做额外优化）：

1. 在 `prompts/system_agents_prompts/skill_build_workflow/` 下创建新的 `*.yaml`，顶层键 `agent:`，必须包含：
   - `name`、`description`、`category`
   - `environments` 下至少一个环境（`development` / `production` / `testing`）
   - `versions[]` 中至少一个 `version: latest` 的 `system_prompt` / `user_prompt_template`
   - `metadata.tools_dependencies` 列出需要的系统工具
2. 调用 `PromptManager().reload()` 或 `load_single_prompt('system_agents_prompts/skill_build_workflow/your_agent.yaml')` 动态注册（避免重启）。
3. 在上游 orchestrator 的工作流定义中加入新阶段，输出需与下游 Stage 的 `INPUT CONTEXT` 对接。

### 6. 扩展支持新的脚本语言

修改 `nexus_utils/skill/runtime.py:1659`：

```python
RUNTIME_MAP = {
    '.py': 'python',
    '.sh': 'bash',
    '.js': 'node',
    '.ts': 'npx ts-node',
    # 新增：
    '.rb': 'ruby',
}
```

同步检查 `nexus_utils/skill/models.py:1346` 的 `LANG_MAP`（用于文件分类和 prompt 代码块语言），必要时补齐。

### 7. 添加一个新的 `SKILL_STANDARD_DIRS`

例如想让导入器也收集 `hooks/` 目录：

1. 在 `nexus_utils/skill/models.py:1335` 的 `SKILL_STANDARD_DIRS` 列表加入 `'hooks'`。
2. 在 `FileManifest` 加 `hooks: List[str] = field(default_factory=list)` 字段，`to_dict()` 与 `_classify_file` 分支相应扩展。
3. 如需在 L2 prompt 组装里加入 `hooks/`，在 `_assemble_prompt_from_local` / `_assemble_prompt_from_s3` 追加 `hooks/` 循环。

## 常见调试 / 故障排查

| 现象 | 可能原因 | 诊断 |
|------|----------|------|
| `FileNotFoundError: No SKILL.md found` | 导入目录无 `SKILL.md` 或 `skill.md` | `importer.py:399` / `625`；检查文件名大小写 |
| `[sync] No S3 files found for skill …` | S3 中没有该 skill_id 的对象，可能前缀错 | `storage.py:2418`；检查 `s3_prefix` 字段，新数据应为 `skills/{type}/{id}/` |
| `Script not found: {path}` | `execute_script` 的 `script_path` 错误 | `runtime.py:1780`；传相对路径，不要加 `./` |
| `Unsupported script type: {ext}` | 扩展名不在 `RUNTIME_MAP` | `runtime.py:1789` |
| `Script timed out after {n} seconds` | 默认 120 秒 | 传入 `timeout=` 调大 |
| `git clone failed: …` | 非 GitHub URL 回退失败 | `importer.py:643`；检查网络、私仓凭证 |
| `Failed to parse SKILL.md frontmatter: …` | 非法 YAML | `importer.py:188`；检查 `---` 分隔符两侧格式 |
| `register_built_skill` 后 `local_path=''` | S3→本地同步失败 | `manager.py:1019` 的 `logger.warning(f"…Local sync failed")`；检查磁盘写权限 |
| `[s3] Failed to upload …` 全量失败 | AWS 凭证或桶权限 | `storage.py:2290` 抛出；查 `boto3` 配置 |

**关键日志前缀**：

| 前缀 | 模块 |
|------|------|
| `[create] / [update] / [delete]` | `SkillManager` |
| `[register_built_skill]` | `SkillManager.register_built_skill` |
| `[local]` / `[s3]` / `[sync]` / `[ensure]` | `SkillStorage` |
| `[runtime]` | `SkillRuntime` |
| `[claude-code]` / `[batch]` / `[scan]` | `SkillImporter` |

**常用诊断命令**：

```bash
# 直接看 S3 上的 Skill 文件
aws s3 ls s3://{artifacts_bucket}/skills/{skill_type}/{skill_id}/ --recursive

# 看本地同步状态
ls -laR skills/{skill_type}_skills/{skill_name}

# DDB 侧的元数据
aws dynamodb get-item --table-name nexus_skills \
  --key '{"skill_id":{"S":"sk-xxxx"}}'
```

## 延伸阅读

- 添加 Agent：`drafts/developer/adding-agents.md` — Skill 提供能力模板，Agent 在推理循环中通过 `get_full_prompt` 加载 Skill 正文。
- 添加工具：`drafts/developer/adding-tools.md` — Skill 自带的 `tools` frontmatter 字段与 Agent 工具注册的关系。
- Stage Engine：`drafts/developer/stage-engine.md` — Skill Build Workflow 的五阶段由 Stage Engine 驱动。
- Worker：`drafts/developer/worker.md` — `BuildHandlerV2._post_skill_deployment` 回调 `register_built_skill` 的位置。
- 源码锚点：
  - `nexus_utils/skill/__init__.py` 公开 API 导出
  - `nexus_utils/skill/manager.py:709` `SkillManager` 主类
  - `nexus_utils/skill/storage.py:2030` `SkillStorage` 主类
  - `nexus_utils/skill/importer.py:123` `SkillImporter` 主类
  - `nexus_utils/skill/runtime.py:1667` `SkillRuntime` 主类
  - `nexus_utils/prompts_manager.py:13453` `PromptManager` 单例
  - `prompts/system_agents_prompts/skill_build_workflow/` 五阶段 Agent
