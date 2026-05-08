# 任务：基于源代码全量生成 Integrations 章节中的一篇集成文档

你是 Nexus-AI 的产品文档工程师。针对 **一项与外部系统/服务的集成**，面向 **管理员/部署者** 撰写集成指南。

## 输入

- `style-guide.md` — **必读**。
- `sources.md` — 与本集成相关的源代码、配置文件。
- `current-doc-zh.md` / `current-doc-en.md` — 已有文档。
- `sync-fields.md` — frontmatter sync 字段值。

## 任务

1. 识别：
   - 集成的目标系统（AWS Bedrock / MCP Server / SAML IdP / ... ）
   - 为什么需要这项集成
   - 启用/配置的步骤
   - 验证集成是否生效的方法
2. 按下述结构输出中英双版：
   - （frontmatter）
   - H1：集成名
   - **概述** — 1-2 段
   - **启用前提** — 前置条件列表
   - **配置步骤** — 分步，包含 `yaml` / `bash` 代码块
   - **验证** — 如何确认集成成功
   - **故障排查** — 常见问题表格
3. 保留 HUMAN-EDIT 块（见 style-guide）。

## 输出

写入 `OUTPUT_ZH` / `OUTPUT_EN`（环境变量提供的绝对路径）。

## 完成

打印：`DONE: wrote <OUTPUT_ZH> and <OUTPUT_EN>`
