---
title: 工具与工具集
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - agents/template_agents/**
    - nexus_utils/skill/**
  generated_at: 2026-05-08T15:18:54+00:00
  generated_by: docs-sync v2
---

# 工具与工具集

## 这是什么

**工具（Tool）** 是 Agent 的单项能力，对应一个可调用函数，例如读取文件、抓取网页、执行 DCF 计算、查询 AWS 报价。**工具集（Toolset，又称 Skill）** 把一组工具、脚本、参考资料和执行配置打包在一起，按名称整体绑定给 Agent，也可以从 GitHub、URL 或本地目录导入到工作空间。

平台提供系统内置、模板自带、社区导入三类工具与工具集，创建 Agent 时按需勾选即可，无需自己造轮子。

## 使用场景

| 场景 | 用工具（单个） | 用工具集（Skill） |
|------|--------------|------------------|
| 给 Agent 加一项轻量能力 | 勾选 `strands_tools/file_read`、`strands_tools/http_request` 等单项工具 | — |
| 构建一个领域型 Agent（如 HTML→PPTX 转换） | — | 整包引用 `html2pptx` 工具集，一次拿到解析、样式映射、布局、图像、缓存等 40+ 工具 |
| 复用社区或 Anthropic/Claude Code 生态成果 | — | 从 GitHub 仓库批量导入，或迁移本地 Claude Code 的 Skill |
| 把自研脚本打包给 Agent 用 | — | 按标准目录组织后上传成一个 Skill |
| 给 Agent 加定时任务、时间函数 | 勾选 `strands_tools/current_time`、`strands_tools/calculator` | — |

<!-- SCREENSHOT: tools-toolsets-overview -->

## 如何使用

### 1. 浏览工具与工具集

左侧导航进入 **「工具」** 或 **「工具集（Skills）」** 页：

1. 顶部标签切换 `system`（系统内置）/ `generated`（平台构建产出）/ `community`（导入）/ `private`（私有）。
2. 搜索框按名称、描述、标签过滤；分类下拉按业务域筛选。
3. 点击任意卡片查看详情：文件清单（prompt / scripts / references / agents / assets / evals / config）、内含工具、来源、版本、使用次数。

<!-- SCREENSHOT: toolset-list -->

### 2. 识别工具命名

工具路径前缀能看出它的来源：

| 前缀 | 含义 |
|------|------|
| `strands_tools/xxx` | 平台内置通用工具（文件、时间、计算器、HTTP、RSS……） |
| `template_tools/&lt;domain&gt;/&lt;module&gt;/&lt;fn&gt;` | 模板自带的领域工具，如 `template_tools/data/visualization/chart_generator` |
| `generated_tools/&lt;agent_key&gt;/&lt;module&gt;/&lt;fn&gt;` | 某生成型 Agent 专用工具，如 `generated_tools/html2pptx/pptx_generator/add_slide` |

### 3. 在 Agent 中绑定工具

创建或编辑 Agent 时，在 **「工具依赖」** 面板逐项勾选需要的工具或整包工具集：

```yaml
tools_dependencies:
  - "strands_tools/file_read"
  - "strands_tools/current_time"
  - "template_tools/common/text_processor/text_analyzer"
  - "generated_tools/html2pptx/html_parser/parse_html"
```

::: tip
模板 Agent（如「深度研究专家」「API 集成专家」「HTML2PPTX 转换专家」）已预绑定一整套推荐工具组合，直接从模板创建即可。
:::

### 4. 导入外部工具集

在工具集页面点 **「导入」**，选择来源：

| 来源 | 需要的信息 | 行为 |
|------|-----------|------|
| GitHub（单个） | 仓库 URL + 仓库内路径 | 读取该路径下的 `SKILL.md` 与标准子目录 |
| GitHub（批量） | 仓库 URL + 基础路径 | 扫描基础路径下每一个含 `SKILL.md` 的子目录，先预览再选择性导入 |
| URL 直链 | 指向 `SKILL.md` 的 URL | 仅导入 `SKILL.md`，不含脚本或引用 |
| Claude Code | 本地扫描路径列表 | 扫描路径下所有含 `SKILL.md` 的子目录 |
| 本地目录 | 本机路径 | 递归收集标准结构下的文件 |

<!-- SCREENSHOT: toolset-import -->

导入成功后，平台会：

1. 解析 `SKILL.md` 的 YAML frontmatter（`name` / `description` / `tools` / `version`）。
2. 收集标准子目录：`scripts/`、`references/`、`assets/`、`agents/`、`eval-viewer/`、`evals/`、`config/`。
3. 写入本地工作目录 + 上传到对象存储 + 登记元数据（三层同步）。
4. 按来源自动创建或复用「分组」，同一 GitHub 仓库下的多个 Skill 归到同一分组。

### 5. 运行工具集里的脚本

含 `scripts/` 目录的工具集可以在 Agent 运行时执行脚本。平台按扩展名确定运行时：

| 扩展名 | 运行时 |
|--------|--------|
| `.py` | `python` |
| `.sh` | `bash` |
| `.js` | `node` |
| `.ts` | `npx ts-node` |

在工具集详情页的 **「脚本」** 标签：

1. 选择一个脚本，查看识别出的运行时。
2. 填入命令行参数，点 **「执行」**。
3. 查看 stdout / stderr、返回码、耗时。

脚本在工具集本地目录内执行，平台自动注入三个环境变量：`SKILL_DIR`、`SKILL_NAME`、`SKILL_ID`，默认超时 120 秒。

<!-- SCREENSHOT: skill-script-run -->

### 6. 更新与删除

- **再次导入**（相同来源）：平台识别为已存在，覆盖文件、刷新文件清单与内容哈希、更新摘要，分组归属保持不变。
- **编辑后上传**：本地与对象存储同步覆盖。
- **删除**：一次性清理本地目录、对象存储前缀、元数据记录，不可撤销。

## 关键参数 / 限制

| 项目 | 值 / 说明 |
|------|----------|
| 工具集类型 | `system`（官方内置）/ `generated`（平台构建产出）/ `community`（导入）/ `private`（私有） |
| 来源类型 | `claude-code` / `github` / `url` / `manual` / `platform` |
| 支持的标准子目录 | `scripts/`、`references/`、`assets/`、`agents/`、`eval-viewer/`、`evals/`、`config/` |
| 必需文件 | `SKILL.md`（缺失则导入失败） |
| 脚本运行时 | Python、Bash、Node.js、TypeScript（按扩展名识别） |
| 脚本默认超时 | 120 秒，调用时可覆盖 |
| 输出截断 | 命令模式下 stdout 保留末 5000 字符、stderr 保留末 2000 字符 |
| L1 摘要长度 | ≤ 200 字符，列表页只返回 L1 字段，详情页再加载完整 prompt |
| 批量导入来源 | 仅支持 GitHub |
| URL 导入范围 | 仅抓取 `SKILL.md`，不含脚本或引用 |

## 常见问题

**Q：「工具」和「工具集（Skill）」到底什么区别？**
A：工具是最小颗粒的一个可调用函数（如 `file_read`）。工具集是带 `SKILL.md` 的目录，里面可同时包含多个工具、脚本、参考资料和示例 Agent。给 Agent 加零散能力用工具；装一整套领域能力用工具集。

**Q：导入 GitHub 仓库时提示 "No SKILL.md found" 怎么办？**
A：检查你给的「仓库内路径」是否直接指向包含 `SKILL.md` 的那一层目录。批量模式下平台只把「基础路径」下**直接含 `SKILL.md`** 的子目录识别为 Skill。

**Q：脚本在哪里运行？会影响我本地电脑吗？**
A：不会。脚本运行在平台为该 Skill 分配的工作目录里，通过子进程隔离执行，并有超时保护。你本地机器不受影响。

**Q：为什么列表页看不到完整系统提示词，进详情页才出现？**
A：列表走 L1 摘要（名称、描述、标签、工具清单等轻量字段），详情页按需加载 L2 的完整 prompt，以加快列表加载速度、降低数据库读取成本。

**Q：同一个 Skill 重复导入会怎样？**
A：平台按名称与来源定位已有记录并执行更新，覆盖文件、刷新 `file_manifest` 与内容哈希，而不是创建重复项。

**Q：怎么自己做一个工具集上传？**
A：按 Anthropic Agent Skills 规范组织目录：顶层放 `SKILL.md`（带 YAML frontmatter），其余文件放到上表列出的标准子目录。然后从 **「本地目录」** 导入，或推到 GitHub 仓库再通过 GitHub 来源导入。
