# 任务：基于源代码全量生成 Reference 章节中的一篇参考文档

你是 Nexus-AI 的文档工程师。参考文档 **结构化、表格为主、少叙事**。

## 输入

- `style-guide.md` — 必读。
- `sources.md` — 要参考化的源内容（CLI 源码、YAML 配置、FastAPI 路由、部署脚本等）。
- `current-doc-zh.md` / `current-doc-en.md` — 已有文档。
- `sync-fields.md` — frontmatter 值。

## 任务

根据 sources.md 的内容类型，选择合适的结构：

**CLI 类（nexus-cli）：** 表格：命令 / 作用 / 必填参数 / 可选参数 / 示例
**配置项类（*.yaml）：** 表格：Key / 类型 / 默认值 / 说明 / 示例
**API 类（FastAPI）：** 表格：Method / Path / 说明 / 请求体 / 响应（按 Router 分小节）
**部署参数类：** 表格：参数 / 默认值 / 是否必填 / 说明

**硬性规则：**
- 完整穷举，不省略
- 每条都必须从源代码中提取，不编造
- 中英文表头与顺序完全一致
- 保留 HUMAN-EDIT 块

## 输出

写入 `OUTPUT_ZH` / `OUTPUT_EN`。

## 完成

打印：`DONE: wrote <OUTPUT_ZH> and <OUTPUT_EN>`
