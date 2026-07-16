---
title: Administrator Guide
sync:
  source_commit: 9d40a32f2bad2c7858b3ed0cfb4390e1bd603a30
  source_files:
    - (chapter index — aggregated)
  generated_at: 2026-07-12T13:05:31+00:00
  generated_by: docs-sync v2
---

# Administrator Guide

This guide is for administrators who deploy, configure, and operate Nexus-AI. From installing the platform in your own AWS account to tuning parameters, managing accounts, controlling models, tracking usage, reviewing audit logs, and watching service health—the operations you need to run the platform are all here.

Most chapters map to a single admin page in the console, visible to administrators only. Read them in order, or jump straight to the task in front of you.

| Document | Summary |
| --- | --- |
| [Deployment & Upgrade](./deploy-upgrade) | Use the `nexus-cli` command-line tool to deploy Nexus-AI into your own AWS account in one command, and upgrade the compute nodes later without touching your data. |
| [Configuration Management](./config-management) | Adjust platform runtime parameters field by field in one screen, with each item marked as taking effect immediately or requiring a service restart. |
| [Users & Permissions](./users-permissions) | Create and deactivate accounts, organize the department tree, and assign roles and fine-grained permissions driven by policies. |
| [Resource Group Administration](./resource-group-admin) | Bundle multiple resources into a folder and share them as a unit by team, project, or purpose (called "shared resources" in the UI). |
| [Audit Trail](./audit) | Search tamper-proof activity records, export them for retention, subscribe to notifications, and have an AI assistant help investigate and produce compliance reports. |
| [Usage & Billing](./billing) | Attribute token consumption across models, users, projects, and applications, and set quotas for users and applications. |
| [Service Status Monitoring](./service-status) | Track the platform's overall health, restart / stop / start backend services, and view live logs. |
| [Built-in AI Assistants (Admin)](./helper-agents) | Use natural language to troubleshoot, configure, and audit across admin pages, with any change surfaced as a proposal you confirm before it takes effect. |
| [Model Catalog & Access](./model-access) | Decide which models are available on the platform, set their tiers, control image input, and test connectivity before saving. |
| [MCP Service Management](./mcp) | Register external MCP servers and connect the tools they provide to the platform for agents to call at runtime. |
| [Login & SSO](./sso-auth) | Configure local account login, or connect a SAML 2.0 identity provider to enable enterprise single sign-on. |
| [External Integrations](./integrations-admin) | Register and manage the external systems the platform connects to, maintaining connection credentials and toggles in one place. |
| [FAQ & Troubleshooting](./faq-ops) | A collection of common administrator questions and troubleshooting steps to help you quickly locate and resolve operational issues. |
