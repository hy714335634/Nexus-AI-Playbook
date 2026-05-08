import { defineConfig } from 'vitepress'

export default defineConfig({
  base: '/playbook/',
  title: 'Nexus-AI',
  description: '用自然语言构建 AI Agent — 产品使用手册',
  lang: 'zh-CN',
  lastUpdated: true,
  cleanUrls: true,

  // Exclude internal planning docs from the build (they live alongside user-facing docs
  // for easy discoverability but should not ship to the deployed site).
  srcExclude: ['superpowers/**'],

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

    nav: [
      { text: '首页', link: '/' },
      { text: '快速上手', link: '/guide/login' },
      {
        text: '使用手册',
        items: [
          { text: '🏠 工作台', link: '/manual/dashboard' },
          { text: '🤖 创建 Agent', link: '/manual/create-agent' },
          { text: '📊 构建进度', link: '/manual/build-progress' },
          { text: '📋 项目管理', link: '/manual/projects' },
          { text: '🗂️ 管理 Agent', link: '/manual/manage-agents' },
          { text: '💬 对话测试', link: '/manual/chat' },
          { text: '🔧 能力工具', link: '/manual/tools' },
          { text: '🔌 MCP 服务器', link: '/manual/mcp' },
        ]
      },
      { text: '功能特性', link: '/features/' },
      { text: '集成', link: '/integrations/' },
      { text: '教程', link: '/tutorials/' },
      { text: '开发者', link: '/developer/' },
      { text: '参考', link: '/reference/' },
      {
        text: '了解更多',
        items: [
          { text: '💡 平台概述', link: '/overview/what-is-nexus' },
          { text: '⚙️ 构建原理', link: '/overview/how-it-works' },
          { text: '🛡️ 管理员指南', link: '/admin/settings' },
          { text: '📖 术语表', link: '/glossary/' },
          { text: '❓ 常见问题', link: '/faq' },
        ]
      },
    ],

    sidebar: {
      '/guide/': [
        {
          text: '🚀 快速上手',
          items: [
            { text: '登录系统', link: '/guide/login' },
            { text: '认识工作台', link: '/guide/workspace' },
            { text: '创建第一个 Agent', link: '/guide/first-agent' },
          ]
        }
      ],
      '/manual/': [
        {
          text: '📋 日常使用',
          items: [
            { text: '工作台', link: '/manual/dashboard' },
            { text: '创建 Agent', link: '/manual/create-agent' },
            { text: '构建进度', link: '/manual/build-progress' },
            { text: '项目管理', link: '/manual/projects' },
          ]
        },
        {
          text: '🤖 Agent 管理',
          items: [
            { text: '管理 Agent', link: '/manual/manage-agents' },
            { text: '对话测试', link: '/manual/chat' },
          ]
        },
        {
          text: '🔧 能力工具',
          items: [
            { text: '工具库', link: '/manual/tools' },
            { text: 'MCP 服务器', link: '/manual/mcp' },
          ]
        },
      ],
      '/overview/': [
        {
          text: '💡 平台介绍',
          items: [
            { text: '什么是 Nexus-AI', link: '/overview/what-is-nexus' },
            { text: '构建原理', link: '/overview/how-it-works' },
          ]
        }
      ],
      '/admin/': [
        {
          text: '🛡️ 管理员指南',
          items: [
            { text: '系统设置', link: '/admin/settings' },
            { text: '用户管理', link: '/admin/users' },
          ]
        }
      ],
      '/features/': [
        { text: '⚡ 功能特性', items: [] }
      ],
      '/integrations/': [
        { text: '🔌 集成', items: [] }
      ],
      '/tutorials/': [
        { text: '📚 教程', items: [] }
      ],
      '/developer/': [
        { text: '👨‍💻 开发者指南', items: [] }
      ],
      '/reference/': [
        { text: '📋 参考', items: [] }
      ],
      '/glossary/': [
        { text: '📖 术语表', items: [
          { text: 'Nexus-AI 术语表', link: '/glossary/' }
        ] }
      ],
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
