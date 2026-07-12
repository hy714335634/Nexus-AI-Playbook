import { defineConfig } from 'vitepress'

// Two-manual structure: 用户手册 (end users, zero IT skills) + 管理员手册 (IT admins).
const SIDEBAR = [
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
      { text: '部署与升级', link: '/admin-guide/deploy-upgrade' },
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
      { text: '文档', link: '/user-guide/quickstart' },
      { text: '🤖 手册助手', link: 'https://d3sx15z6kvxyn3.cloudfront.net/a/app_177cb4be76e8' },
      {
        text: '快速链接',
        items: [
          { text: '🚀 5 分钟上手', link: '/user-guide/quickstart' },
          { text: '🛡️ 管理员手册', link: '/admin-guide/deploy-upgrade' },
          { text: '❓ 常见问题', link: '/admin-guide/faq-ops' },
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
