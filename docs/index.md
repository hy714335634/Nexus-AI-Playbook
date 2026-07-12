---
layout: home

hero:
  name: "Nexus-AI"
  text: "产品使用手册"
  tagline: 用自然语言构建 AI Agent — 从想法到可用的智能应用，只需几分钟
  image:
    src: /default_logo.png
    alt: Nexus-AI
  actions:
    - theme: brand
      text: 📖 用户手册
      link: /user-guide/quickstart
    - theme: alt
      text: 🛡️ 管理员手册
      link: /admin-guide/deploy-upgrade

features:
  - icon: 🚀
    title: 5 分钟快速上手
    details: 从登录到创建第一个 Agent，手把手带你入门。不需要任何技术背景
    link: /user-guide/quickstart
    linkText: 开始使用 →
  - icon: 🤖
    title: 创建你的 Agent
    details: 用一句话描述需求，AI 自动完成构建。快速创建和引导创建两种模式
    link: /user-guide/create-agent
    linkText: 了解更多 →
  - icon: 💬
    title: 对话与使用
    details: 多轮对话交互，支持上传文件，回答支持图表与富文本
    link: /user-guide/chat
    linkText: 开始对话 →
  - icon: 🌐
    title: 发布为应用
    details: 把 Agent 包装成网页应用，一条链接分享给全公司使用，还能用一句话持续改进
    link: /user-guide/app-center
    linkText: 查看详情 →
  - icon: 🧰
    title: 工具与技能扩展
    details: 给 Agent 添加新能力：构建工具、挂载技能、连接业务数据
    link: /user-guide/tools
    linkText: 浏览工具 →
  - icon: 🛡️
    title: 平台管理
    details: 面向 IT 管理员：配置管理、用户权限、审计追踪、服务监控与内置 AI 助手
    link: /admin-guide/config-management
    linkText: 管理指南 →
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
