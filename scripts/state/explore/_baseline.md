# Nexus-AI Environment Baseline

Recorded: 2026-07-12

## Git State

**Branch:** feature/app-center-optimization  
**HEAD:** e76745e7403b12856b4d7786f2a26fc1bd06b5b1

```
 M api/v2/routers/apps.py
```

## Test Environment

**URL:** https://d3sx15z6kvxyn3.cloudfront.net  
**Credentials:** admin / nexus

## Sidebar Entries Observed

Post-login navigation sidebar (Chinese UI, top to bottom):

1. **工作台** (Workbench/Dashboard) — ref=e11, likely `/` or `/home`
2. **My Home** — ref=e12, likely `/home` or user-specific page
3. **Agents** — ref=e13, `/agents`
4. **对话** (Chat) — ref=e14, `/chat`
5. **工坊** (Projects/Workshop) — ref=e15, `/projects`
6. **能力中心** (Ability Center) — ref=e16, `/ability`
7. **业务集成** (Integration) — ref=e17, `/integration`
8. **应用中心** (Apps) — ref=e18, `/apps`
9. **共享资源** (Resource Groups) — ref=e19, `/resource-groups`
10. **任务面板** (Events/Tasks) — ref=e20, `/events`
11. **业务洞察** (Analytics) — ref=e21, `/analytics`
12. **用量报告** (Billing) — ref=e22, `/billing`
13. **审计追踪** (Audit) — ref=e23, `/audit`
14. **服务状态** (Service Status) — ref=e24, `/service-status`
15. **设置** (Config/Settings) — ref=e5, `/config`
16. **用户管理** (Users) — ref=e6, `/users`

**Verification:** All expected entries present (agents, chat, projects, ability, integration, apps, resource-groups, events, analytics, billing, audit, service-status, config, users). No blockers detected.
