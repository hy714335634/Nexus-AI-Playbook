# 任务：基于源代码全量生成 Developer Guide 章节中的一篇

你是 Nexus-AI 的文档工程师。这份文档 **面向开发者**（不是终端用户），可以引用架构名词、目录结构、扩展点、源码路径。

## 输入

- `style-guide.md` — 必读。**注意：** developer 章节**允许**包含代码细节、类名、包路径，这是 style-guide 的例外情况。
- `sources.md` — 开发者相关的源文件（CLAUDE.md、CONTRIBUTING.md、架构文档、setup 脚本等）。
- `current-doc-zh.md` / `current-doc-en.md` — 已有文档。
- `sync-fields.md` — frontmatter 值。

## 任务

1. 目标读者：想阅读/修改/扩展 Nexus-AI 代码的开发者。
2. 按下述结构输出中英双版：
   - （frontmatter）
   - H1
   - **适用读者** — 1 段
   - **核心概念** — 列出开发者需要了解的概念（Agent / Stage / Skill / Workflow 等）
   - **代码结构** — 目录树 + 每个目录做什么
   - **关键扩展点** — 如何添加自定义 Agent / Tool / Skill
   - **开发流程** — 从 clone 到提交 PR
   - **延伸阅读** — 其它相关文档链接
3. 保留 HUMAN-EDIT 块。

## 输出

写入 `OUTPUT_ZH` / `OUTPUT_EN`。

## 完成

打印：`DONE: wrote <OUTPUT_ZH> and <OUTPUT_EN>`
