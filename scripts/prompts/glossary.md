# 任务：生成 Nexus-AI 术语表

从 Nexus-AI 源代码与现有文档中扫描专有名词，生成一份结构化术语表。

## 输入

- `style-guide.md` — 必读。
- `sources.md` — 源代码与既有文档聚合（CLAUDE.md、README.md、nexus_utils/ 代码等）。
- `current-doc-zh.md` / `current-doc-en.md` — 现有术语表（若存在）。
- `sync-fields.md` — frontmatter。

## 任务

1. 扫描 sources.md，识别 Nexus-AI 特有的术语：
   - Agent 类型（Magician Agent、Orchestrator Agent、Builder Agent...）
   - 架构组件（Stage、Skill、Bridge、Workflow Engine、Sandbox、Valkey Stream Relay...）
   - 协议/集成（MCP、SAML、FastMCP...）
   - 产品概念（Guided Creation、Quick Creation、Multi-Agent Swarm/Graph...）
2. 每条术语格式：
   ```markdown
   ### 术语名（英文缩写/全称）

   1-3 句简洁定义。链接到该术语在其它文档中详细出现的位置。
   ```
3. **按字母序组织**（A-Z），不按主题分组。
4. 排除通用技术词汇（Python、JSON、HTTP 这些）。
5. 中英文版**术语同序**，每条定义翻译对应。
6. 保留 HUMAN-EDIT 块。

## 输出

写入 `OUTPUT_ZH` / `OUTPUT_EN`。

## 完成

打印：`DONE: wrote <OUTPUT_ZH> and <OUTPUT_EN>`
