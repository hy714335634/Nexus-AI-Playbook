import DefaultTheme from 'vitepress/theme'
import SyncFreshness from './SyncFreshness.vue'
import SidebarToggle from './SidebarToggle.vue'
import type { Theme } from 'vitepress'
import { useRoute } from 'vitepress'
import { h, onMounted, watch, nextTick } from 'vue'
import './custom.css'

// Click-to-zoom for screenshots (medium-zoom). Bind to content images and
// re-bind on route changes (VitePress is an SPA). SSR-guarded.
export default {
  extends: DefaultTheme,
  Layout() {
    // Place toggle in the nav bar (never overlaps document content).
    return h(DefaultTheme.Layout, null, {
      'nav-bar-content-before': () => h(SidebarToggle),
    })
  },
  enhanceApp({ app }) {
    app.component('SyncFreshness', SyncFreshness)
    app.component('SidebarToggle', SidebarToggle)
  },
  setup() {
    if (typeof window === 'undefined') return
    const route = useRoute()
    let zoom: any = null
    const bind = async () => {
      await nextTick()
      const { default: mediumZoom } = await import('medium-zoom')
      if (!zoom) {
        // container: full viewport so the zoomed image is never clipped by the
        // sidebar; large margin keeps it clear of page chrome.
        zoom = mediumZoom({
          background: 'rgba(15,23,42,0.94)',
          margin: 48,
          container: {
            width: window.innerWidth,
            height: window.innerHeight,
            top: 0,
            left: 0,
          },
        })
      }
      zoom.detach()
      // Only zoom real content screenshots, not logos/icons.
      zoom.attach('.vp-doc img:not(.no-zoom)')
    }
    onMounted(bind)
    watch(() => route.path, () => setTimeout(bind, 200))
  }
} satisfies Theme
