import { defineConfig } from 'vitepress'

// Single persistent sidebar used across every docs route.
// Groups are rendered as collapsible categories in Hermes style.
const SIDEBAR = [
  {
    text: '🚀 快速开始',
    collapsed: false,
    items: [
      { text: '5 分钟快速上手', link: '/getting-started/quickstart' },
      { text: '安装 Nexus-AI', link: '/getting-started/installation' },
      { text: 'AWS 环境准备', link: '/getting-started/aws-setup' },
      { text: '升级与卸载', link: '/getting-started/updating' },
      { text: '学习路径', link: '/getting-started/learning-path' },
    ]
  },
  {
    text: '📖 使用 Nexus-AI',
    collapsed: true,
    items: [
      { text: '工作台', link: '/using/dashboard' },
      { text: '创建 Agent', link: '/using/create-agent' },
      { text: '构建进度', link: '/using/build-progress' },
      { text: '对话', link: '/using/chat' },
      { text: '工坊管理', link: '/using/projects' },
      { text: 'Agent 管理', link: '/using/manage-agents' },
      { text: '应用中心', link: '/using/app-center' },
      { text: '工具库', link: '/using/tools' },
      { text: 'MCP 服务器', link: '/using/mcp' },
      { text: '技能系统', link: '/using/skills' },
      { text: '业务集成中心', link: '/using/integration-center' },
      { text: '资源组与共享', link: '/using/resource-groups-sharing' },
      { text: '事件任务', link: '/using/events' },
      { text: '内置助手', link: '/using/assistants' },
      { text: '浏览器扩展', link: '/using/browser-extension' },
      { text: 'Avatar 空间', link: '/using/avatar-space' },
      { text: 'Spotlight 命令面板', link: '/using/spotlight' },
      { text: '进化/PFR/故障排查', link: '/using/evolution-pfr-troubleshoot' },
    ]
  },
  {
    text: '⚡ 功能特性',
    collapsed: true,
    items: [
      { text: '概览', link: '/features/' },
      {
        text: 'Core',
        collapsed: true,
        items: [
          { text: '工具与工具集', link: '/features/tools-toolsets' },
          { text: '技能系统', link: '/features/skills-system' },
          { text: 'Agent Factory', link: '/features/agent-factory' },
          { text: '提示词模板', link: '/features/prompt-templates' },
        ]
      },
      {
        text: 'Runtime',
        collapsed: true,
        items: [
          { text: 'Sandbox 沙箱', link: '/features/sandbox' },
          { text: '工作流引擎', link: '/features/workflow-engine' },
          { text: '多 Agent 图/群', link: '/features/multi-agent' },
          { text: '流式响应中继', link: '/features/stream-relay' },
        ]
      },
      {
        text: 'Automation',
        collapsed: true,
        items: [
          { text: '事件调度', link: '/features/event-scheduler' },
          { text: 'Bridge 多连接', link: '/features/bridge' },
        ]
      },
      {
        text: 'Observability',
        collapsed: true,
        items: [
          { text: '可观测性', link: '/features/observability' },
          { text: '指标与计费', link: '/features/metrics-billing' },
          { text: '日志', link: '/features/logging' },
        ]
      },
      { text: '应用中心内部机制', link: '/features/app-center-internals' },
    ]
  },
  {
    text: '🔌 集成',
    collapsed: true,
    items: [
      { text: '集成总览', link: '/integrations/overview' },
      { text: 'AWS Bedrock 模型接入', link: '/integrations/aws-bedrock' },
      { text: '外部 MCP 服务器', link: '/integrations/mcp-clients' },
      { text: 'Agent as MCP Tool', link: '/integrations/mcp-server' },
      { text: 'SSO (SAML 2.0)', link: '/integrations/sso-saml' },
      { text: '数据存储', link: '/integrations/data-stores' },
      { text: '数据连接器', link: '/integrations/data-connectors' },
      { text: '浏览器扩展集成', link: '/integrations/browser-extension-integration' },
    ]
  },
  {
    text: '📚 使用指南',
    collapsed: true,
    items: [
      { text: '技巧与最佳实践', link: '/guides/tips' },
      { text: '发布第一个应用', link: '/guides/publish-first-app' },
      { text: '用工具扩展 Agent', link: '/guides/extend-agent-with-tools' },
      { text: '构建知识问答 Agent', link: '/guides/build-knowledge-qa' },
      { text: '在 Nexus-AI 中使用 MCP', link: '/guides/use-mcp-with-nexus' },
      { text: '团队协作', link: '/guides/team-collaboration' },
    ]
  },
  {
    text: '👨‍💻 开发者指南',
    collapsed: true,
    items: [
      { text: '贡献指南', link: '/developer/contributing' },
      {
        text: 'Architecture',
        collapsed: true,
        items: [
          { text: '架构总览', link: '/developer/architecture-overview' },
          { text: 'API 层架构', link: '/developer/api-layer' },
          { text: 'Worker 架构', link: '/developer/worker' },
          { text: 'Stage 引擎', link: '/developer/stage-engine' },
        ]
      },
      {
        text: 'Extending',
        collapsed: true,
        items: [
          { text: '添加 Agent', link: '/developer/adding-agents' },
          { text: '添加工具', link: '/developer/adding-tools' },
          { text: '添加技能', link: '/developer/adding-skills' },
        ]
      },
      {
        text: 'Internals',
        collapsed: true,
        items: [
          { text: '会话存储', link: '/developer/session-storage' },
          { text: '动态 Prompt 构建', link: '/developer/dynamic-prompt' },
        ]
      },
    ]
  },
  {
    text: '📋 参考',
    collapsed: true,
    items: [
      { text: 'nexus-cli 命令', link: '/reference/cli-commands' },
      { text: '配置项', link: '/reference/config-options' },
      { text: '环境变量', link: '/reference/environment-variables' },
      { text: 'API 端点', link: '/reference/api-endpoints' },
      { text: '部署参数', link: '/reference/deploy-params' },
      { text: 'IAM 权限', link: '/reference/iam-policies' },
      { text: '模型目录', link: '/reference/model-catalog' },
      { text: '术语表', link: '/reference/glossary' },
      { text: 'FAQ 与故障排查', link: '/reference/faq' },
      { text: '版本历史', link: '/reference/version-history' },
    ]
  },
  {
    text: '🛡️ 管理员指南',
    collapsed: true,
    items: [
      { text: '部署与升级', link: '/admin/deploy-upgrade' },
      { text: '配置管理', link: '/admin/config-management' },
      { text: '用户与权限', link: '/admin/users-permissions' },
      { text: '资源组管理', link: '/admin/resource-group-admin' },
      { text: '审计追踪', link: '/admin/audit' },
      { text: '用量与计费', link: '/admin/billing' },
      { text: '服务状态监控', link: '/admin/service-status' },
      { text: '运维助手', link: '/admin/ops-assistant' },
      { text: '发布说明', link: '/admin/release-notes' },
    ]
  },
]

export default defineConfig({
  base: '/playbook/',
  title: 'Nexus-AI',
  description: '用自然语言构建 AI Agent — 产品使用手册',
  lang: 'zh-CN',
  lastUpdated: true,
  cleanUrls: true,

  // Exclude internal planning docs and preview scratch area from the build.
  srcExclude: ['superpowers/**', 'preview/**'],

  // Many sidebar links point at docs that will be generated in later batches.
  // Ignore dead internal links for now; tighten after all batches land.
  ignoreDeadLinks: true,

  head: [
    ['link', { rel: 'icon', type: 'image/png', href: '/playbook/default_logo.png' }],
    ['meta', { name: 'theme-color', content: '#6366f1' }],
    ['meta', { name: 'apple-mobile-web-app-capable', content: 'yes' }],
    ['meta', { name: 'apple-mobile-web-app-status-bar-style', content: 'black-translucent' }],
    ['meta', { name: 'viewport', content: 'width=device-width, initial-scale=1.0, viewport-fit=cover' }],
  ],

  markdown: {
    lineNumbers: true,
  },

  themeConfig: {
    logo: '/default_logo.png',
    siteTitle: 'Nexus-AI',

    // Minimal top nav — sidebar is the primary navigation.
    nav: [
      { text: '首页', link: '/' },
      { text: '文档', link: '/getting-started/quickstart' },
      {
        text: '快速链接',
        items: [
          { text: '🚀 5 分钟上手', link: '/getting-started/quickstart' },
          { text: '🛡️ 管理员指南', link: '/admin/deploy-upgrade' },
          { text: '❓ FAQ', link: '/reference/faq' },
        ]
      },
    ],

    // Persistent sidebar shown across all docs routes.
    sidebar: {
      '/': SIDEBAR,
    },

    socialLinks: [
      { icon: 'github', link: 'https://github.com/hy714335634/Nexus-AI' }
    ],

    editLink: {
      pattern: 'https://github.com/hy714335634/Nexus-AI-Playbook/edit/main/docs/:path',
      text: '在 GitHub 上编辑此页'
    },

    footer: {
      message: 'Released under the MIT License.',
      copyright: 'Copyright © 2025-present Nexus-AI Team'
    },

    search: {
      provider: 'local',
      options: {
        translations: {
          button: { buttonText: '搜索文档', buttonAriaLabel: '搜索文档' },
          modal: {
            noResultsText: '没有找到相关内容',
            resetButtonTitle: '清除',
            footer: { selectText: '选择', navigateText: '切换', closeText: '关闭' }
          }
        }
      }
    },

    outline: { label: '📑 本页目录', level: [2, 3] },
    lastUpdated: { text: '最后更新' },
    docFooter: { prev: '← 上一篇', next: '下一篇 →' },
    returnToTopLabel: '回到顶部',
    sidebarMenuLabel: '菜单',
    darkModeSwitchLabel: '主题',
  }
})
