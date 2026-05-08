# Nexus-AI Playbook 文档风格指南

这是 **Nexus-AI 产品的终端用户手册（User Manual）**，不是开发者文档。

## 核心原则

1. **面向终端用户** — 不要出现内部类名、函数名、数据库表名、文件路径。
2. **图文并茂** — 涉及 UI 操作时插入 `<!-- SCREENSHOT: <name> -->` 占位符（构建时由自动截图或人工替换）。
3. **简洁直接** — 一步一动作，尽量使用表格、有序列表呈现操作流程。
4. **中英文双版本对齐** — 两份文档结构、小节、示例完全一致；仅自然语言部分翻译。

## 格式约定

- 使用 Markdown + VitePress 扩展语法（`::: tip`、`::: info`、`::: warning`）。
- 标题层级从 `#` 开始（VitePress 要求每篇文档一个 H1）。
- 表格用于：功能对比、参数说明、限制约束、常见问题。
- 代码块用于：真实命令、示例输入、UI 文字标签（用 `「」` 或反引号）。

## 语气

- 中文：直呼"你"，不使用"您"；避免冗长修饰。
- English: second-person "you"; concise, imperative sentences.

## 不要做的事

- 不要解释"为什么这样实现"（这是用户手册，不是设计文档）。
- 不要暴露未发布功能或内部概念。
- 不要添加 TODO、占位符（截图占位符除外）、或"待补充"内容。
- 不要编造代码中不存在的功能。

## Frontmatter（v2 新增）

**每一份生成的 markdown 文档开头必须包含如下 YAML frontmatter**，由调用方注入实际字段值（详见 prompt 任务段的 `OUTPUT_FRONTMATTER_ZH` / `OUTPUT_FRONTMATTER_EN` 环境变量）：

```yaml
---
title: <文档标题>
sync:
  source_commit: <Nexus-AI 的 commit SHA>
  source_files:
    - path/to/source/file1
    - path/to/source/file2
  generated_at: <ISO 8601 时间戳>
  generated_by: docs-sync v2
---
```

**硬性规则：**

- 如果调用方通过 `PRE_FRONTMATTER` 环境变量提供了 frontmatter 块，**原封不动地放在文档开头**（你不需要重新发明字段）。
- frontmatter 之后空一行，然后是 H1 标题，然后是正文。

## HUMAN-EDIT 块保留（v2 新增）

若现有的中/英文档中含有如下注释块，必须在生成的新版文档中 **保留完全相同的内容和标签**，位置应尽量贴近相同章节上下文：

```markdown
<!-- HUMAN-EDIT-START: <标签名> -->
人工精心编辑的段落。
<!-- HUMAN-EDIT-END: <标签名> -->
```

**硬性规则：**

- 调用方会提前把现有文档里所有 HUMAN-EDIT 块通过 `HUMAN_EDIT_BLOCKS_ZH` / `HUMAN_EDIT_BLOCKS_EN` 环境变量（内容为 JSON）告知你。
- 你必须在新文档中对每个 label 产生一个 `HUMAN-EDIT-START/END` 对，**block 内容保持逐字节一致**（不改排版、不翻译、不删）。
- 放置位置：若原文档该 label 位于某小节下，新文档中尽量放到**语义最相关的同级章节**；若无法判断，放文档末尾"备注"小节之前。
