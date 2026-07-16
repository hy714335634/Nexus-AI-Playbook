import { defineConfig } from 'vitepress'

const SIDEBAR_ZH = [
  {
    text: '📖 用户手册',
    collapsed: false,
    items: [
      {
        text: '入门',
        collapsed: false,
        items: [
          { text: '登录与界面导览', link: '/user-guide/first-login' },
          { text: '5 分钟快速上手', link: '/user-guide/quickstart' },
          { text: '学习路径', link: '/user-guide/learning-path' },
        ]
      },
      {
        text: '日常使用',
        collapsed: false,
        items: [
          { text: '工作台', link: '/user-guide/dashboard' },
          { text: '创建 Agent', link: '/user-guide/create-agent' },
          { text: '构建进度', link: '/user-guide/build-progress' },
          { text: '对话', link: '/user-guide/chat' },
          { text: '工坊管理', link: '/user-guide/projects' },
          { text: 'Agent 管理', link: '/user-guide/manage-agents' },
          { text: '应用中心', link: '/user-guide/app-center' },
        ]
      },
      {
        text: '能力扩展',
        collapsed: true,
        items: [
          { text: '工具库', link: '/user-guide/tools' },
          { text: '技能系统', link: '/user-guide/skills' },
          { text: '业务集成中心', link: '/user-guide/integration-center' },
          { text: '浏览器扩展', link: '/user-guide/browser-extension' },
        ]
      },
      {
        text: '协作与自动化',
        collapsed: true,
        items: [
          { text: '资源组与共享', link: '/user-guide/resource-groups-sharing' },
          { text: '事件任务', link: '/user-guide/events' },
          { text: '内置助手', link: '/user-guide/assistants' },
          { text: 'Avatar 空间', link: '/user-guide/avatar-space' },
          { text: 'Spotlight 命令面板', link: '/user-guide/spotlight' },
          { text: '进化/PFR/故障排查', link: '/user-guide/evolution-pfr-troubleshoot' },
        ]
      },
      {
        text: '实战教程',
        collapsed: true,
        items: [
          { text: '从目标到方案：能力编排配方', link: '/user-guide/orchestration-recipes' },
          { text: '连接服务器执行任务', link: '/user-guide/bridge-server' },
          { text: '技巧与最佳实践', link: '/user-guide/tips' },
          { text: '发布第一个应用', link: '/user-guide/publish-first-app' },
          { text: '用工具扩展 Agent', link: '/user-guide/extend-agent-with-tools' },
          { text: '构建知识问答 Agent', link: '/user-guide/build-knowledge-qa' },
          { text: '团队协作', link: '/user-guide/team-collaboration' },
        ]
      },
    ]
  },
  {
    text: '🛡️ 管理员手册',
    collapsed: true,
    items: [
      { text: '配置管理', link: '/admin-guide/config-management' },
      { text: '用户与权限', link: '/admin-guide/users-permissions' },
      { text: '资源组管理', link: '/admin-guide/resource-group-admin' },
      { text: '审计追踪', link: '/admin-guide/audit' },
      { text: '用量与计费', link: '/admin-guide/billing' },
      { text: '服务状态监控', link: '/admin-guide/service-status' },
      { text: '内置 AI 助手（管理员）', link: '/admin-guide/helper-agents' },
      { text: '模型目录与接入', link: '/admin-guide/model-access' },
      { text: 'MCP 服务管理', link: '/admin-guide/mcp' },
      { text: '登录与 SSO', link: '/admin-guide/sso-auth' },
      { text: '外部集成管理', link: '/admin-guide/integrations-admin' },
      { text: '常见问题与排障', link: '/admin-guide/faq-ops' },
    ]
  },
]

const SIDEBAR_EN = [
  {
    text: '📖 User Guide',
    collapsed: false,
    items: [
      {
        text: 'Getting Started',
        collapsed: false,
        items: [
          { text: 'Login & Interface', link: '/en/user-guide/first-login' },
          { text: '5-Minute Quickstart', link: '/en/user-guide/quickstart' },
          { text: 'Learning Path', link: '/en/user-guide/learning-path' },
        ]
      },
      {
        text: 'Daily Use',
        collapsed: false,
        items: [
          { text: 'Dashboard', link: '/en/user-guide/dashboard' },
          { text: 'Create an Agent', link: '/en/user-guide/create-agent' },
          { text: 'Build Progress', link: '/en/user-guide/build-progress' },
          { text: 'Chat', link: '/en/user-guide/chat' },
          { text: 'Projects', link: '/en/user-guide/projects' },
          { text: 'Manage Agents', link: '/en/user-guide/manage-agents' },
          { text: 'App Center', link: '/en/user-guide/app-center' },
        ]
      },
      {
        text: 'Extend Capabilities',
        collapsed: true,
        items: [
          { text: 'Tool Library', link: '/en/user-guide/tools' },
          { text: 'Skills', link: '/en/user-guide/skills' },
          { text: 'Integration Center', link: '/en/user-guide/integration-center' },
          { text: 'Browser Extension', link: '/en/user-guide/browser-extension' },
        ]
      },
      {
        text: 'Collaboration & Automation',
        collapsed: true,
        items: [
          { text: 'Resource Groups & Sharing', link: '/en/user-guide/resource-groups-sharing' },
          { text: 'Event Tasks', link: '/en/user-guide/events' },
          { text: 'Built-in Assistants', link: '/en/user-guide/assistants' },
          { text: 'Avatar Space', link: '/en/user-guide/avatar-space' },
          { text: 'Spotlight', link: '/en/user-guide/spotlight' },
          { text: 'Evolution / PFR / Troubleshoot', link: '/en/user-guide/evolution-pfr-troubleshoot' },
        ]
      },
      {
        text: 'Tutorials',
        collapsed: true,
        items: [
          { text: 'Orchestration Recipes', link: '/en/user-guide/orchestration-recipes' },
          { text: 'Connect a Server (Bridge)', link: '/en/user-guide/bridge-server' },
          { text: 'Tips & Best Practices', link: '/en/user-guide/tips' },
          { text: 'Publish Your First App', link: '/en/user-guide/publish-first-app' },
          { text: 'Extend Agent with Tools', link: '/en/user-guide/extend-agent-with-tools' },
          { text: 'Build a Knowledge Q&A Agent', link: '/en/user-guide/build-knowledge-qa' },
          { text: 'Team Collaboration', link: '/en/user-guide/team-collaboration' },
        ]
      },
    ]
  },
  {
    text: '🛡️ Admin Guide',
    collapsed: true,
    items: [
      { text: 'Configuration', link: '/en/admin-guide/config-management' },
      { text: 'Users & Permissions', link: '/en/admin-guide/users-permissions' },
      { text: 'Resource Groups', link: '/en/admin-guide/resource-group-admin' },
      { text: 'Audit Trail', link: '/en/admin-guide/audit' },
      { text: 'Usage & Billing', link: '/en/admin-guide/billing' },
      { text: 'Service Status', link: '/en/admin-guide/service-status' },
      { text: 'AI Helper Agents', link: '/en/admin-guide/helper-agents' },
      { text: 'Model Catalog & Access', link: '/en/admin-guide/model-access' },
      { text: 'MCP Service', link: '/en/admin-guide/mcp' },
      { text: 'Login & SSO', link: '/en/admin-guide/sso-auth' },
      { text: 'External Integrations', link: '/en/admin-guide/integrations-admin' },
      { text: 'FAQ & Troubleshooting', link: '/en/admin-guide/faq-ops' },
    ]
  },
]

export default defineConfig({
  base: '/playbook/',
  title: 'Nexus-AI',
  description: 'Nexus-AI Product Manual',
  lastUpdated: true,
  cleanUrls: true,

  srcExclude: ['superpowers/**', 'preview/**'],
  ignoreDeadLinks: true,

  head: [
    ['link', { rel: 'icon', type: 'image/png', href: '/playbook/default_logo.png' }],
    ['meta', { name: 'theme-color', content: '#6366f1' }],
    ['meta', { name: 'viewport', content: 'width=device-width, initial-scale=1.0, viewport-fit=cover' }],
  ],

  markdown: {
    lineNumbers: true,
  },

  locales: {
    root: {
      label: '中文',
      lang: 'zh-CN',
      themeConfig: {
        nav: [
          { text: '首页', link: '/' },
          { text: '用户手册', link: '/user-guide/quickstart' },
          { text: '管理手册', link: '/admin-guide/config-management' },
          { text: '🤖 手册助手', link: 'https://d3sx15z6kvxyn3.cloudfront.net/a/app_177cb4be76e8' },
          { text: 'v0.3.12', items: [{ text: 'v0.3.12 (当前)', link: '/' }] },
        ],
        sidebar: { '/': SIDEBAR_ZH },
        outline: { label: '本页目录', level: [2, 3] },
        lastUpdated: { text: '最后更新' },
        docFooter: { prev: '← 上一篇', next: '下一篇 →' },
        returnToTopLabel: '回到顶部',
        sidebarMenuLabel: '菜单',
        darkModeSwitchLabel: '主题',
      }
    },
    en: {
      label: 'English',
      lang: 'en-US',
      link: '/en/',
      themeConfig: {
        nav: [
          { text: 'Home', link: '/en/' },
          { text: 'User Guide', link: '/en/user-guide/quickstart' },
          { text: 'Admin Guide', link: '/en/admin-guide/config-management' },
          { text: '🤖 Manual Assistant', link: 'https://d3sx15z6kvxyn3.cloudfront.net/a/app_177cb4be76e8' },
          { text: 'v0.3.12', items: [{ text: 'v0.3.12 (current)', link: '/en/' }] },
        ],
        sidebar: { '/en/': SIDEBAR_EN },
        outline: { label: 'On this page', level: [2, 3] },
        lastUpdated: { text: 'Last updated' },
        docFooter: { prev: '← Previous', next: 'Next →' },
        returnToTopLabel: 'Back to top',
        sidebarMenuLabel: 'Menu',
        darkModeSwitchLabel: 'Theme',
      }
    }
  },

  themeConfig: {
    logo: '/default_logo.png',
    siteTitle: 'Nexus-AI',
    socialLinks: [],

    footer: {
      message: 'Nexus-AI v0.3.12',
      copyright: 'Copyright © 2025-present Nexus-AI Team'
    },

    search: {
      provider: 'local',
      options: {
        locales: {
          root: {
            translations: {
              button: { buttonText: '搜索文档', buttonAriaLabel: '搜索文档' },
              modal: {
                noResultsText: '没有找到相关内容',
                resetButtonTitle: '清除',
                footer: { selectText: '选择', navigateText: '切换', closeText: '关闭' }
              }
            }
          },
          en: {
            translations: {
              button: { buttonText: 'Search', buttonAriaLabel: 'Search docs' },
              modal: {
                noResultsText: 'No results found',
                resetButtonTitle: 'Clear',
                footer: { selectText: 'Select', navigateText: 'Navigate', closeText: 'Close' }
              }
            }
          }
        }
      }
    },
  }
})
