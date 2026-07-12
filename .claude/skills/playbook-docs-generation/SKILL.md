---
name: playbook-docs-generation
description: Use when updating/regenerating the Nexus-AI Playbook manual — walking through the live test environment with agent-browser, capturing screenshots, running the docs-sync generation pipeline, resolving screenshot placeholders, or syncing docs to the Bedrock Knowledge Base. Also use when pages appear blank, clicks don't register, generation FAILED, or KB ingestion fails.
---

# Playbook 手册生成全流程（走查 → 截图 → 生成 → KB 同步）

本 skill 沉淀 2026-07 手册 v4 重构的全部实操经验。核心原则：**手册内容以实测走查为准（源码只作核实），截图必须来自当前环境，两册读者画像决定一切措辞**。

## 固定坐标

| 资源 | 值 |
|---|---|
| 测试环境 | https://d3sx15z6kvxyn3.cloudfront.net （admin/nexus，session 约 1h 过期） |
| 生成管线 | `scripts/sync.sh`（全量 `--full --chapter <ch>`，增量默认；操作手册 `scripts/README.md`） |
| 章节结构 | 两册：`user-guide`（终端用户，25 篇）+ `admin-guide`（IT 管理员，13 篇），定义在 `scripts/config.yaml` |
| 截图管线 | `scripts/screenshots/targets.yaml` + `capture.js`；产物 `docs/public/images/` |
| 占位符解析 | `scripts/lib/screenshot_refs.py`（`<!-- SCREENSHOT: name -->` → 真实图片引用） |
| KB | `scripts/lib/kb_sync.sh`（KB ZHIONELMF9 / us-east-1 / S3 Vectors；sync-s3→ingest→status→query） |
| 走查笔记 | `scripts/state/explore/0*.md`（生成时经 `extra_context` 注入，UI 行为最高权威） |

## 走查纪律（agent-browser）

**每一条都是真实误判换来的，不可跳过：**

1. **水合等待**：每次 `open`/导航后必须 `wait --load networkidle && wait 8000`。CloudFront SPA 冷加载水合要 5-10s；不等就截图/snapshot 会把正常页面误判成"空白页/客户端异常"（v4 走查曾因此误报 3 个"严重 bug"，全是假的）。判 broken 前再 `wait --text "<预期文案>"` 到 20s。
2. **React 点击失灵 → eval 直点**：agent-browser 常规 `click` 对部分 React 按钮偶发不触发（合成事件）。fallback：
   ```bash
   agent-browser --session S eval --stdin <<'EOF'
   (() => { const b=[...document.querySelectorAll('button')].find(x=>(x.textContent||'').includes('按钮文案')); if(!b) return 'not found'; b.click(); return 'clicked'; })()
   EOF
   ```
3. **弹窗探测别依赖 role=dialog**：本产品部分弹窗容器无 `role="dialog"`（a11y 缺失），用 `div.fixed.inset-0` 且 `offsetHeight>200` 探测浮层。v4 曾因此误报"工具构建入口不存在"。
4. **React 受控输入**：`fill` 不生效时用原型 setter：`Object.getOwnPropertyDescriptor(HTMLTextAreaElement.prototype,'value').set.call(el, text)` 后 dispatch `input` 事件。
5. **登录态**：session ~1h 过期。检测到登录页（textbox "用户名"）就重登（admin/nexus）并 `state save $PB/.agent-browser-auth.json`。所有命令统一 `--session nexus-explore`。
6. **截图必须绝对路径**：`screenshot` 的文件名相对 daemon cwd 解析，相对路径会把图落到别的仓库（曾污染 Nexus-AI 本体根目录）。
7. **聊天发送是 Shift+Enter**：Enter 只换行。发送后按钮变「停止生成」，完成后恢复。
8. **本体只读**：任何时候不写 /Users/qangz/Downloads/99.Project/Nexus-AI（用户在并行开发，判"污染"标准=我们的工具从不写入，而非 diff 固定基线）。

## 截图管线

- **批量重刷**（UI 变更后）：`cd scripts/screenshots && node capture.js --targets all --base-url https://d3sx15z6kvxyn3.cloudfront.net --user admin --password nexus --output-dir ../../docs/public/images`。capture.js 已内置 networkidle+8s 等待与 viewport 截图（不要改回 fullPage——虚拟化列表全页截图是坏的）。
- **弹窗/流程态截图**无法无人值守重刷：走查时人工截到 `scripts/state/explore/shots/<batch>/`（gitignored），需要入册时复制改名到 `docs/public/images/`。
- **占位符解析**：生成后跑 `find docs/<ch> -name '*.md' | xargs python3 scripts/lib/screenshot_refs.py`；报 missing 的名字要么在脚本 ALIASES 里补映射，要么从 shots/ 提图，要么删占位符——**成品文档零 `SCREENSHOT:` 残留**（用 `grep -rc "SCREENSHOT:" docs/user-guide docs/admin-guide` 验证）。
- 同一文档内重复图片引用要去重（生成器爱重复贴图）。

## 两册生成规范（prompt 已固化，勿逆向放松）

- `scripts/prompts/user-guide.md`：读者零 IT 能力。**禁**技术词汇（API/JSON/数据库/endpoint…）；每操作=编号步骤+按钮文案「」原文；只说做什么不讲原理。
- `scripts/prompts/admin-guide.md`：读者 IT 管理员但**非本平台开发者**。重点=平台自带管理功能（运维/审计/配置/用量）+ 每页配套 AI 助手（入口/能问什么/护栏）；**禁**内部类名/表名/模块路径/架构机制；命令行只到 `nexus-cli` 一层。
- UI 行为冲突时：走查笔记 > 源码。

## 生成管线操作

```bash
./scripts/sync.sh --estimate --chapter user-guide   # 先估成本（必做）
./scripts/sync.sh --full --chapter admin-guide      # 全量生成到 drafts/
./scripts/sync.sh --full --chapter user-guide --doc app-center --force-regenerate  # 单篇重做
# 合并：cp drafts/<ch>/*.md docs/<ch>/ && cp drafts/<ch>/en/*.md docs/<ch>/en/
# 卫生：find docs -name '*.md' -not -path 'docs/superpowers/*' | xargs python3 scripts/lib/sanitize_md.py
# 占位符：screenshot_refs.py（见上）→ npm run docs:build 必须过 → 逐章提交
./scripts/sync.sh --emit-llms-txt                   # 刷新 llms.txt
./scripts/sync.sh --init $(git -C ../Nexus-AI rev-parse HEAD)  # 全量重做后重置增量基线
```

**生成 FAILED 的头号原因是 sources 太肥**（单篇 >150 文件或 >150k tok_in 必超时）。修法：收窄该篇 `sources` 到关键文件（router + 主页面 + 配置），`--doc <slug> --force-regenerate` 重跑。v4 实测 3 篇（avatar/spotlight/evolution）全靠瘦身救活。estimate 单篇 >$15 就该收窄。

## KB 同步（手册更新后必做）

```bash
./scripts/lib/kb_sync.sh sync-s3   # 两册 md → s3://nexus-playbook-kb-845023/docs/
./scripts/lib/kb_sync.sh ingest && ./scripts/lib/kb_sync.sh status   # 至 COMPLETE 且 failed=0
./scripts/lib/kb_sync.sh query "如何发布应用"   # 冒烟
```

**两个已踩的坑**：① chunking 用 FIXED_SIZE(512tok/20%)——HIERARCHICAL 会触发 S3 Vectors "Filterable metadata >2048 bytes" 全量失败；② S3 Vectors index 必须把 `AMAZON_BEDROCK_TEXT` **和** `AMAZON_BEDROCK_METADATA` 都设为 nonFilterable，缺后者同样全量失败。重建 index 后 ingest 会把全部文档重索引。

## 常见故障速查

| 症状 | 原因 | 处理 |
|---|---|---|
| 页面"空白"/"异常" | 没等水合 | networkidle+8s+wait --text，再判 |
| click 无反应 | React 合成事件 | eval 直点 DOM |
| 找不到弹窗 | 无 role=dialog | `div.fixed.inset-0` 探测 |
| 突然回到登录页 | token 1h 过期 | 重登+state save |
| 生成 FAILED | sources 过肥 | 收窄+单篇重跑 |
| KB 全量 failed | chunking/index 元数据 | 见 KB 节两坑 |
| build 报未闭合标签 | `<uuid>` 类占位符 | sanitize_md.py |
| 估算跑不动(printf 报错) | macOS bash 3.2 | common.sh log() 已改 date，别改回 `%(...)T` |
| 图片是旧 UI | v3 遗留 | 只信 targets.yaml 重刷的图；旧图删 |
