---
title: Updating & Uninstalling
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - README.md
    - nexus-cli
    - pyproject.toml
  generated_at: 2026-05-08T14:32:50+00:00
  generated_by: docs-sync v2
---

# Updating & Uninstalling

## What this is

This page shows how to upgrade Nexus-AI to the latest version and, when you no longer need it, how to remove it cleanly. Local installs (virtual environment) and cloud deployments (CloudFormation Stack) follow different paths, covered separately below.

## When to use it

| Scenario | What you do |
|----------|-------------|
| A new release is out | Pull latest code, refresh dependencies, restart services |
| You changed config or dependencies | Rebuild the virtual environment or restart affected services |
| The environment is broken | Uninstall, then reinstall from scratch |
| Done with a cloud demo environment | Delete the CloudFormation Stack and choose whether to wipe data |
| Moving to another machine | Uninstall on the old box, run the install flow on the new one |

## How to use it

### Upgrade a local install

::: tip
Run `./nexus-cli service stop` before upgrading so running processes don't hold on to old files while code is being swapped.
:::

1. **Enter the project directory and pull the latest code**

   ```bash
   cd Nexus-AI
   git pull
   ```

2. **Activate the virtual environment and refresh dependencies**

   ```bash
   source .venv/bin/activate
   pip install -r requirements.txt
   pip install -e .
   ```

3. **Restart services**

   ```bash
   ./nexus-cli service restart
   ```

   If you also run the MCP Server:

   ```bash
   ./nexus-cli service restart --mcp
   ```

4. **Verify everything is healthy**

   ```bash
   ./nexus-cli service status
   ./nexus-cli service logs -f
   ```

   <!-- SCREENSHOT: cli-service-status-after-upgrade -->

### Upgrade a cloud deployment

To refresh code and configuration in the cloud, run `nexus-cli deploy up` again with the **same environment name**. CloudFormation applies changes as an update, so data resources (database, cache, storage buckets) are preserved.

```bash
nexus-cli deploy up my-env \
  --github-token ghp_xxxx \
  --db-password 'MySecurePass123!' \
  --branch main \
  -y
```

After the update, check status:

```bash
nexus-cli deploy status my-env
```

::: warning
Changing core parameters such as `--branch`, `--instance-type`, `--enable-sso`, or `--enable-sandbox` can trigger resource replacement, and some running sessions may be interrupted. Schedule this during a maintenance window in production.
:::

### Uninstall a local install

1. **Stop all services**

   ```bash
   ./nexus-cli service stop
   ```

2. **Remove the virtual environment and project directory**

   ```bash
   deactivate 2>/dev/null
   cd ..
   rm -rf Nexus-AI
   ```

3. **(Optional) Clean up AWS-side data resources**

   `./nexus-cli init` creates DynamoDB tables, SQS queues, and S3 buckets in your AWS account. Deleting the local project does **not** remove those resources — they keep incurring cost. Delete them from the AWS console if no longer needed, or continue to manage them through `nexus-cli` for other environments.

### Uninstall a cloud deployment

A cloud deployment is backed by a CloudFormation Stack. `nexus-cli deploy down` tears it down:

```bash
# Delete the Stack only (keep data in S3 / DynamoDB / SQS)
nexus-cli deploy down my-env -y

# Also wipe data resources
nexus-cli deploy down my-env --clean-data -y
```

::: warning
`--clean-data` deletes everything in the S3 buckets, DynamoDB tables, and SQS queues, **irreversibly**. Back up any Agent artifacts, session history, and uploaded files you need before running it.
:::

List every deployed environment in your account:

```bash
nexus-cli deploy list
```

<!-- SCREENSHOT: cli-deploy-list -->

## Key parameters / limits

| Item | Notes |
|------|-------|
| Upgrade path | Local: `git pull` + reinstall deps + restart; Cloud: re-run `deploy up` with the same name |
| Data migration | This flow does not include database schema migrations; follow release notes for manual steps if required |
| Python version | Confirm Python ≥ 3.12 (required by `pyproject.toml`) before upgrading; bump Python first if needed |
| Dependency drift | New releases may add entries to `pyproject.toml`; skipping `pip install -e .` leads to runtime ImportError |
| Cloud data retention | `deploy down` preserves S3 / DynamoDB / SQS by default; `--clean-data` is the only way to fully wipe them |
| Local uninstall | Removing the project directory does not clean AWS resources automatically — do it manually if needed |
| Deployer permissions | Cloud upgrade/uninstall requires CloudFormation, EC2, IAM, RDS, ElastiCache, and related permissions on the operator |

## FAQ

**Q1: After upgrading, services fail to start with ImportError. What now?**
A: Usually a new dependency wasn't installed. Run `source .venv/bin/activate`, then `pip install -r requirements.txt` and `pip install -e .`, and finally `./nexus-cli service restart`.

**Q2: Can I upgrade to a specific branch or tag?**
A: Locally, `git checkout &lt;branch|tag&gt;` and repeat the upgrade steps. In the cloud, pass `--branch &lt;branch&gt;` to `nexus-cli deploy up` and redeploy.

**Q3: I ran `nexus-cli deploy down` but still see AWS charges. Why?**
A: Without `--clean-data`, S3 buckets, DynamoDB tables, and SQS queues are retained and keep accruing storage/request cost. Check in the AWS console whether you still need them, or re-run the command with `--clean-data`.

**Q4: I `rm -rf`'d the project directory. Can I recover my built Agents?**
A: Generated Agent code is saved locally under `agents/generated_agents/` by default, and once deleted it isn't recoverable from the project folder. If you had cloud deployment with S3 artifact storage enabled, some artifacts may still live in the bucket. Back up `agents/generated_agents/` (or `git stash`) before next time.

**Q5: Will an upgrade affect existing Agents?**
A: A local upgrade only replaces platform code; Agent configuration, session history, and artifacts in your database and S3 are untouched. If a release changes data models, watch the release notes for manual migration requirements.

**Q6: Can I roll back to an older version?**
A: Locally, `git checkout &lt;old-commit&gt;` and re-run `pip install -e .` to roll code back. However, new fields written to databases/DynamoDB by the newer version are not cleaned up automatically, and the older code may choke on them. Validate any rollback in a separate environment before doing it in production.
