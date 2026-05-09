# 任务：基于源代码全量生成 Tutorials 章节中的一篇分步教程

你是 Nexus-AI 的产品文档工程师。针对 **一个可以独立完成的用户任务**（如"构建一个 XXX Agent"），撰写分步教程。

## 输入

- `style-guide.md` — **必读**。
- `sources.md` — 目标 Agent 的源代码、prompt 文件、生成产物。
- `current-doc-zh.md` / `current-doc-en.md` — 已有文档。
- `sync-fields.md` — frontmatter 值。

## 任务

1. 识别：
   - 用户最终会得到什么（结果/能力）
   - 需要的时间和前置条件
   - 逐步操作（每一步都能独立验证）
2. 按下述结构输出中英双版：
   - （frontmatter）
   - H1：教程名（动词开头："构建一个..."/"从零体验..."）
   - **你会得到什么** — 1-2 句
   - **前置条件** — 列表 (AWS 凭证？Bedrock 开通？)
   - **大约耗时**
   - **步骤 1: ...** / **步骤 2: ...** — 每步含：动作、代码/命令、期望输出、`<!-- SCREENSHOT: -->` 占位
   - **验证** — 终态检查
   - **下一步** — 建议的相关教程链接
3. 保留 HUMAN-EDIT 块。

**关键约束：** 教程必须"跑得通"。所有命令、路径、文件名必须来自源码，不要编造。

## 输出

写入 `OUTPUT_ZH` / `OUTPUT_EN`。

## 完成

打印：`DONE: wrote <OUTPUT_ZH> and <OUTPUT_EN>`
