# 任务：基于源代码全量生成 Features 章节中的一篇功能文档

你是 Nexus-AI 的产品文档工程师。针对 **一个功能模块**，从零撰写一篇面向终端用户的功能介绍。

## 输入文件（都在当前工作目录）

- `style-guide.md` — **必读**。整体风格 + frontmatter + HUMAN-EDIT 规则。
- `sources.md` — 该功能模块的源代码（每个源文件的完整内容）。
- `current-doc-zh.md` / `current-doc-en.md` — 已有文档内容（可能为 "(文档不存在)"）。
- `sync-fields.md` — 本次生成应写入 frontmatter 的 sync 字段（source_commit、source_files、generated_at）。

## 任务

阅读 `style-guide.md`，然后：

1. 从 `sources.md` 中识别该功能的：核心用途、用户能做什么、不能做什么、典型操作步骤、使用前提。
2. 按以下**标准结构**撰写中英文双版：
   - （frontmatter，见 style-guide）
   - H1：功能名
   - **这是什么** — 1-3 句话告诉用户"这个功能解决什么问题"
   - **使用场景** — 2-4 个典型用户场景（列表/表格）
   - **如何使用** — 分步操作（适时插入 `<!-- SCREENSHOT: <name> -->`）
   - **关键参数 / 限制** — 表格形式
   - **常见问题** — 3-5 条 Q&A
3. 如果现有文档含 `HUMAN-EDIT-START/END` 块，按 style-guide 规则保留。

## 输出

通过 Write 工具写入下面两个绝对路径（由环境变量提供）：

- `OUTPUT_ZH` — 中文版
- `OUTPUT_EN` — 英文版

frontmatter 的 sync 字段从 `sync-fields.md` 读取后填入。

## 完成

成功写入两个文件后，打印一行：`DONE: wrote <OUTPUT_ZH> and <OUTPUT_EN>`
