---
title: 升级与卸载
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - README.md
    - nexus-cli
    - pyproject.toml
  generated_at: 2026-05-08T14:32:50+00:00
  generated_by: docs-sync v2
---

# 升级与卸载

## 这是什么

这篇文档告诉你如何把 Nexus-AI 升级到最新版本，以及当你不再需要它时如何干净卸载。本地安装（虚拟环境）和云端部署（CloudFormation Stack）采用不同的操作路径，下面分别说明。

## 使用场景

| 场景 | 你要做的事 |
|------|-----------|
| 新版本发布后想跟进 | 拉取最新代码、更新依赖、重启服务 |
| 修改了配置或依赖 | 重建虚拟环境或重启相关服务 |
| 环境坏了想重装 | 卸载后重新安装 |
| 云端演示环境用完 | 删除 CloudFormation Stack，选择是否清理数据 |
| 换一台机器部署 | 在老机器上卸载，在新机器上重新执行安装流程 |

## 如何使用

### 升级本地安装

::: tip
升级前建议先 `./nexus-cli service stop` 停掉正在运行的服务，避免代码替换过程中进程持有旧文件。
:::

1. **进入项目目录并拉取最新代码**

   ```bash
   cd Nexus-AI
   git pull
   ```

2. **激活虚拟环境并更新依赖**

   ```bash
   source .venv/bin/activate
   pip install -r requirements.txt
   pip install -e .
   ```

3. **重启服务**

   ```bash
   ./nexus-cli service restart
   ```

   如果同时运行了 MCP Server：

   ```bash
   ./nexus-cli service restart --mcp
   ```

4. **确认状态正常**

   ```bash
   ./nexus-cli service status
   ./nexus-cli service logs -f
   ```

   <!-- SCREENSHOT: cli-service-status-after-upgrade -->

### 升级云端部署

云端环境通过重新执行 `nexus-cli deploy up`（使用**相同的环境名**）即可刷新代码和配置。CloudFormation 会以更新的方式应用变更，数据库、缓存、存储桶等数据资源不会被销毁。

```bash
nexus-cli deploy up my-env \
  --github-token ghp_xxxx \
  --db-password 'MySecurePass123!' \
  --branch main \
  -y
```

升级后用下列命令确认状态：

```bash
nexus-cli deploy status my-env
```

::: warning
切换 `--branch`、`--instance-type`、`--enable-sso`、`--enable-sandbox` 等核心参数会触发资源重建，部分正在运行的会话可能会中断。生产环境请在维护窗口内操作。
:::

### 卸载本地安装

1. **停止所有服务**

   ```bash
   ./nexus-cli service stop
   ```

2. **删除虚拟环境和项目目录**

   ```bash
   deactivate 2>/dev/null
   cd ..
   rm -rf Nexus-AI
   ```

3. **（可选）清理 AWS 端的数据资源**

   `./nexus-cli init` 会在你的 AWS 账户中创建 DynamoDB 表、SQS 队列和 S3 存储桶。本地项目被删除后，这些资源**仍然存在并继续产生费用**。如果不再需要，前往 AWS 控制台手动删除，或继续使用 `nexus-cli` 管理其他环境。

### 卸载云端部署

云端部署对应一个 CloudFormation Stack，使用 `nexus-cli deploy down` 一键回收：

```bash
# 仅删除 Stack（保留 S3 / DynamoDB / SQS 中的数据）
nexus-cli deploy down my-env -y

# 同时清理数据资源
nexus-cli deploy down my-env --clean-data -y
```

::: warning
`--clean-data` 会删除 S3 存储桶、DynamoDB 表和 SQS 队列中的所有内容，**不可恢复**。执行前请确认已经备份你需要保留的 Agent 制品、会话记录和上传文件。
:::

查看当前账户下所有已部署环境：

```bash
nexus-cli deploy list
```

<!-- SCREENSHOT: cli-deploy-list -->

## 关键参数 / 限制

| 项目 | 说明 |
|------|------|
| 升级方式 | 本地：`git pull` + 重装依赖 + 重启服务；云端：同名 `deploy up` 再执行一次 |
| 数据迁移 | 本升级流程不含数据库 schema 迁移脚本；如升级说明中要求手动迁移，请按说明执行 |
| Python 版本 | 升级前确认 Python ≥ 3.12（`pyproject.toml` 要求），低版本需先升级 Python |
| 依赖变更 | 新版本可能新增 `pyproject.toml` 依赖；忽略 `pip install -e .` 会导致运行时 ImportError |
| 云端数据保留 | `deploy down` 默认保留 S3 / DynamoDB / SQS；加 `--clean-data` 才会彻底清除 |
| 本地卸载 | 删除项目目录不会自动清理 AWS 资源，请按需手动清理 |
| 部署者权限 | 云端升级/卸载需要执行者具备 CloudFormation、EC2、IAM、RDS、ElastiCache 等对应权限 |

## 常见问题

**Q1：升级后服务起不来、报 ImportError，怎么办？**
A：通常是新增依赖未安装。先 `source .venv/bin/activate`，再执行 `pip install -r requirements.txt` 与 `pip install -e .`，然后 `./nexus-cli service restart`。

**Q2：我只想升级到指定分支或某个 tag，可以吗？**
A：本地用 `git checkout <branch|tag>` 后重复升级步骤即可；云端在 `nexus-cli deploy up` 时传 `--branch <branch>` 重新部署。

**Q3：`nexus-cli deploy down` 删完后还收到 AWS 账单怎么办？**
A：默认不加 `--clean-data` 时，S3 桶、DynamoDB 表、SQS 队列会保留，它们可能继续产生存储/请求费用。在 AWS 控制台确认这些资源是否还需要，或用 `--clean-data` 重新执行一次删除命令。

**Q4：我把项目目录 `rm -rf` 了，还能恢复已构建的 Agent 吗？**
A：生成的 Agent 代码默认只保存在本地 `agents/generated_agents/` 目录，删除后无法从项目目录恢复。如果在云端部署中启用了 S3 制品存储，部分产物可能仍在 S3 桶中。下次执行前请先 `git stash` 或单独备份 `agents/generated_agents/`。

**Q5：升级会影响已存在的 Agent 吗？**
A：本地升级只替换平台代码，不会触碰你在数据库和 S3 里的 Agent 配置、会话记录和制品。但如果新版本改动了数据模型，请在升级说明里留意是否需要手动迁移。

**Q6：可以回退到旧版本吗？**
A：本地执行 `git checkout <old-commit>` 后重跑 `pip install -e .` 即可回退代码；但新版本写入数据库/DynamoDB 的新字段不会自动清理，旧代码读到新数据可能异常。生产环境建议先在独立环境验证回退方案。
