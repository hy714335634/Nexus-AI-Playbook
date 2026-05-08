---
layout: home

hero:
  name: "Nexus-AI"
  text: "产品使用手册"
  tagline: 用自然语言构建 AI Agent — 8 个专业 AI 协作，从想法到可用 Agent，只需几分钟
  image:
    src: /default_logo.png
    alt: Nexus-AI
  actions:
    - theme: brand
      text: 🚀 快速开始
      link: /getting-started/quickstart
    - theme: alt
      text: 📖 Agent 使用手册
      link: /using/dashboard

features:
  - icon: 🚀
    title: 快速上手
    details: 从登录系统到创建第一个 Agent，手把手带你入门。支持快速创建和引导创建两种模式
    link: /guide/login
    linkText: 开始使用 →
  - icon: 📋
    title: 工作台
    details: 平台控制中心 — 快速构建入口、数据概览、项目跟踪、Agent 管理一站式操作
    link: /using/dashboard
    linkText: 查看详情 →
  - icon: 🤖
    title: 创建 Agent
    details: 快速创建（直接构建）和引导创建（AI 多轮提问完善需求），支持多模态附件输入
    link: /using/create-agent
    linkText: 了解更多 →
  - icon: 📊
    title: 构建进度
    details: 实时查看 8 个 Builder Agent 在 9 个阶段的协作进展，了解每个阶段的具体产出
    link: /using/build-progress
    linkText: 查看流程 →
  - icon: 💬
    title: 对话测试
    details: 多轮对话交互，支持文件上传（PDF/Excel/CSV/图片），Agent 响应支持 Markdown 和图表
    link: /using/chat
    linkText: 开始对话 →
  - icon: 🔧
    title: 能力工具 & MCP
    details: 5 种工具类型（内置/模板/生成/系统/MCP），通过 MCP 协议即插即用集成外部服务
    link: /using/tools
    linkText: 浏览工具 →
---

<style>
/* Home page specific enhancements */
.VPHome {
  position: relative;
}

/* Animated gradient orbs behind hero */
.VPHero::after {
  content: '';
  position: absolute;
  width: 600px;
  height: 600px;
  border-radius: 50%;
  background: radial-gradient(circle, rgba(99,102,241,0.08) 0%, transparent 70%);
  top: -200px;
  right: -200px;
  animation: orbFloat 15s ease-in-out infinite;
  pointer-events: none;
}

@keyframes orbFloat {
  0%, 100% { transform: translate(0, 0) scale(1); }
  33% { transform: translate(-30px, 20px) scale(1.05); }
  66% { transform: translate(20px, -15px) scale(0.95); }
}

/* Stats bar between hero and features */
.VPHome .VPFeatures {
  position: relative;
}

.VPHome .VPFeatures::before {
  content: '✨ 平均构建时间 35 分钟  ·  🎯 质量评分 9.3/10  ·  ✅ 成功率 100%  ·  💰 平均成本 $3.41';
  display: block;
  text-align: center;
  padding: 16px 24px;
  margin: 0 auto 40px;
  max-width: 800px;
  font-size: 0.88rem;
  font-weight: 500;
  color: var(--vp-c-text-2);
  background: linear-gradient(135deg, rgba(99,102,241,0.06) 0%, rgba(139,92,246,0.04) 100%);
  border: 1px solid rgba(99,102,241,0.1);
  border-radius: 12px;
  letter-spacing: 0.01em;
}

.dark .VPHome .VPFeatures::before {
  background: linear-gradient(135deg, rgba(99,102,241,0.1) 0%, rgba(139,92,246,0.06) 100%);
  border-color: rgba(129,140,248,0.15);
}
</style>
