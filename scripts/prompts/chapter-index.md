# 任务：生成章节入口页 (index.md)

为某个章节生成一个入口页。它列出本章节下所有文档的链接与简介。

## 输入

- `style-guide.md` — 必读。
- `chapter-manifest.md` — 本章节的 manifest，包含章节标题、每篇文档的 slug、标题、首段摘要。
- `sync-fields.md` — frontmatter 值。

## 任务

生成中英双版的 `index.md`，结构：

- （frontmatter）
- H1：章节名
- 1-2 段"本章节涵盖什么"的引子
- 文档列表（卡片/表格二选一，整章统一）：每项包含文档标题 + 一句简介 + 链接

链接格式：`[标题](./<slug>)`（VitePress 的 cleanUrls 会处理）

## 输出

写入 `OUTPUT_ZH` / `OUTPUT_EN`。

## 完成

打印：`DONE: wrote <OUTPUT_ZH> and <OUTPUT_EN>`
