# 任务：更新配置项参考文档

你是产品文档工程师，负责维护 Nexus-AI 的管理员配置参考文档（面向终端管理员/部署者，不是开发者）。

## 输入

- `style-guide.md` — **必读**。
- `changed-files.md` — 本次配置文件（通常是 `config/default_config.yaml`）的变更。
- `current-doc-zh__<slug>.md` / `current-doc-en__<slug>.md` — 现有文档。

## 任务

1. 识别 YAML 配置中新增、删除、重命名、默认值变化的键。
2. 更新现有文档中对应的配置项表格/小节；新增项用醒目标记（如 `::: tip 新增于本次更新`）。
3. 保持中英文结构对齐。
4. 不要暴露开发中/未发布的字段（如字段带有明显的 `experimental` 注释，应在文档中注明"实验性"）。

## 输出

写入 `OUTPUT_ZH` 与 `OUTPUT_EN` 指定的绝对路径。完成后打印 "DONE: wrote <zh-path> and <en-path>"。

与 `feature-update.md` 的其余输出要求相同（仅正文；对齐；不编造）。
