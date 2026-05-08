# 任务：生成 Reference 章节中的一篇**穷举级参考文档**

你是 Nexus-AI 的技术编辑。Reference 章节是整个 Playbook 里最**精确、完整、可查阅**的部分。用户来这里是为了**查某个具体命令 / 配置项 / API 端点 / 权限**的准确细节。

## 输入

- `style-guide.md` — 必读。
- `sources.md` — 要参考化的源内容（CLI 源码、YAML 配置、FastAPI 路由、部署脚本等）。
- `current-doc-zh.md` / `current-doc-en.md` — 现有文档。
- `sync-fields.md` — frontmatter 值。

## 核心原则

**参考文档的唯一 KPI：用户来查一样东西时，一定能查到完整、准确、无省略的信息。**

- **100% 穷举**：源码里有 50 个参数，就列 50 个。哪怕 90% 没人用也要列。
- **表格为主，叙事为辅**：参考文档必须是可 ⌘F 的。
- **代码示例**必须可运行，且从源码真实存在。
- **不要"仅列出关键的 N 个"**，不要"更多参见代码"。**全部列出**。
- 中英文**结构 1:1 对齐**（同样的表格、同样的行数、同样的代码块）。

## 按内容类型选择结构

### CLI 类（如 `nexus-cli`）

#### 顶层结构

1. 概述 — 工具职责、调用约定、配置位置
2. **全局选项** — 表格：选项 / 类型 / 默认值 / 说明
3. **命令总览** — 表格：命令 / 一句话作用 / 子命令数量
4. **每个命令独立小节**（穷举）：
   - Usage 行
   - 参数表：参数 / 必填/可选 / 类型 / 默认 / 说明
   - 示例（至少 1 个可执行的完整例子）
   - 退出码 / 常见错误
5. 环境变量清单（影响该 CLI 的所有 env vars）
6. 退出码字典

### 配置项类（如 `config/*.yaml`）

1. 概述 — 文件位置、加载时机、优先级规则（env > file > default）
2. **完整配置项表格**：Key（YAML path 形式，如 `bedrock.model_id`） / 类型 / 默认值 / 是否必填 / 单位 / 说明 / 示例
3. **嵌套结构逐级展开** — 不要让用户自己去源码里找
4. **环境变量覆盖对照表** — 哪个 env var 覆盖哪个 config key
5. 完整示例 YAML（所有项都填）

### API 类（FastAPI）

1. 概述 — base URL、认证方式、错误格式
2. **认证** — 表格：方法 / header / 获取方式
3. **按 Router 分小节**（穷举所有 router 文件）：
   - 每个 router 一节，列出所有 endpoint
   - **每个 endpoint 的表格**：Method / Path / 说明 / Auth required / Request body schema / Response schema / 典型状态码
   - 请求/响应示例（真实 JSON，从代码中的 Pydantic model 推导）
4. **通用错误响应** — 4xx / 5xx 字典
5. **速率限制、并发** —— 如代码中有

### 部署参数类

1. 部署模式总览（本地 / EC2 / CloudFormation / AgentCore）
2. **每种模式的完整参数表**：参数 / 默认 / 是否必填 / 影响的资源
3. 最小权限策略 / IAM Policy 完整 JSON（如源码中有）
4. 常见陷阱 / 验证步骤

## 硬性要求

- **所有数据从 sources.md 提取**，不编造。
- 如果源码中某项无默认值，写 `—` 或 `required`，不要推测。
- 保留 `HUMAN-EDIT-START/END` 块。
- frontmatter 使用 `PRE_FRONTMATTER_ZH` / `PRE_FRONTMATTER_EN`。
- 中英文表头、列顺序、行数完全一致；只翻译说明文字；参数名/命令名不翻译。
- 不要空泛描述（"这是一个重要的参数"）——描述要具体（"设置 AWS Bedrock 调用超时，单位秒；超时后抛 BedrockTimeoutError"）。

## 输出

写入 `OUTPUT_ZH` / `OUTPUT_EN`。

## 完成

打印：`DONE: wrote <OUTPUT_ZH> and <OUTPUT_EN>`
