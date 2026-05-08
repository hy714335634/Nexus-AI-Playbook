import DefaultTheme from 'vitepress/theme'
import SyncFreshness from './SyncFreshness.vue'
import type { Theme } from 'vitepress'
import './custom.css'

export default {
  extends: DefaultTheme,
  enhanceApp({ app }) {
    app.component('SyncFreshness', SyncFreshness)
  }
} satisfies Theme
