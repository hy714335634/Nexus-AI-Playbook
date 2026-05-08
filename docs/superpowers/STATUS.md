# Playbook Docs-Sync — 开发状态跟踪

> 本文件记录 Playbook 自动同步框架（docs-sync）的开发进展。
> 供项目协作者快速了解当前所处阶段与下一步动作。

## 当前阶段

**阶段：** v3 Batches 1+2+3 已完成。只剩 Batch 4（Developer + Reference + Guides）。

- ✅ Restructure: 7-category persistent Hermes-style sidebar (`5bed523`)
- ✅ /manual/ → /using/ migration with HUMAN-EDIT preservation (`eeb69bb`)
- ✅ Batch 1 (Getting Started, Opus 4.7): 5 zh + 5 en + index (`b867282`)
- ✅ Batch 2 (Using, Opus 4.7): 8 zh + 8 en + index；每页 human_blocks=1（HUMAN-EDIT 保留成功）(`6521481`)
- ✅ Batch 3a (Features, Opus 4.7): 13 zh + 13 en + index (`6521481`)
- ✅ Batch 3b (Integrations, Opus 4.7): 6 zh + 6 en + index (`6521481`)
- ⏳ Batch 4: Developer + Reference + Guides (~23 pages, ~$50-60) — 待指令

**产出汇总（截至当前）：**
- 32 个中文文档 + 32 个英文文档 + 4 个章节 index + 2 个 llms.txt 聚合
- `/getting-started/` (5) + `/using/` (8) + `/features/` (13) + `/integrations/` (6)
- `docs/public/llms.txt` = 51 entries

**Active versions:**
- Spec v2: `docs/superpowers/specs/2026-05-07-playbook-docs-sync-v2-design.md`
- Plan v3: `docs/superpowers/plans/2026-05-08-playbook-docs-sync-v3.md`
- Model: `global.anthropic.claude-opus-4-7` (switched from Sonnet for quality priority)
- Sidebar: 7 categories, persistent across all routes
- Content: Getting Started live at `/getting-started/*` (zh+en)

**Historical (superseded):**
- Spec v1: `docs/superpowers/specs/2026-05-06-playbook-docs-sync-design.md`
- Plan v1: `docs/superpowers/plans/2026-05-06-playbook-docs-sync.md`
- Plan v2: `docs/superpowers/plans/2026-05-07-playbook-docs-sync-v2.md`

## 进展时间线

| 日期 | 事件 | 产出 |
|------|------|------|
| 2026-05-06 | v1 brainstorm + spec | `specs/2026-05-06-playbook-docs-sync-design.md` |
| 2026-05-06 | v1 plan | `plans/2026-05-06-playbook-docs-sync.md` |
| 2026-05-06 | v1 implementation Tasks 1–12 | `scripts/` 完整 5 阶段管道已实施（未端到端验证） |
| 2026-05-07 | 方向从"增量补丁"扩展到"Wiki/CMS 全量框架" | — |
| 2026-05-07 | v2 spec 初稿 | `specs/2026-05-07-playbook-docs-sync-v2-design.md` |
| 2026-05-07 | v2 spec 追加 Wiki/CMS 强化 | 同上（+ llms.txt、signatures、HUMAN-EDIT、审计、成本预估等） |

## 核心要点（v2 Spec 摘要）

1. **范围**：全量生成 5 个新章节 (`features`、`integrations`、`tutorials`、`developer`、`reference`) + `glossary`，共约 25 篇中英双版文档
2. **双模式**：`--full --chapter X` 全量生成；默认增量模式基于 git diff（v1 保留）
3. **Wiki/CMS 强化**：
   - 端用户：`/llms.txt` + `/llms-full.txt`、frontmatter 新鲜度、editLink、glossary
   - 维护者：内容签名去重、HUMAN-EDIT 块保护、`--estimate` 成本预览、run 审计日志、`--doc`/`--force-regenerate` 细粒度
4. **自动化演进**：MVP 仍是半自动；设计已预留 cron→PR→无人值守的演进路径
5. **保持简单**：VitePress 主题不动；配置文件人工 owned；Claude Code 为生成引擎

## 下一步

1. **读 Spec v2** — `docs/superpowers/specs/2026-05-07-playbook-docs-sync-v2-design.md`
2. **写 Plan v2** — 通过 `superpowers:writing-plans` skill 产出详细任务拆分
3. **Plan 中解决的开放问题：**
   - tutorials 精选 3-5 个 Agent 案例（建议：stock_analysis_agent、pdf_content_extractor、aws_pricing_agent）
   - features 最终文档数（6-8 vs 8-10）
   - VitePress 顶级 nav 是否需要 dropdown 分组
4. **执行 Plan v2** — 分章节全量生成 + 人工 review + 合并

## 关键路径文件

```
Nexus-AI-Playbook/
├── docs/superpowers/
│   ├── STATUS.md                                              ← 本文件
│   ├── specs/
│   │   ├── 2026-05-06-playbook-docs-sync-design.md           v1（历史）
│   │   └── 2026-05-07-playbook-docs-sync-v2-design.md        ★ 当前有效
│   └── plans/
│       ├── 2026-05-06-playbook-docs-sync.md                   v1（历史）
│       └── 2026-05-07-playbook-docs-sync-v2.md                待写
│
└── scripts/                                                    v1 已实施，v2 会扩展
    ├── config.yaml
    ├── sync.sh
    ├── lib/
    ├── prompts/
    ├── screenshots/
    └── state/
```
