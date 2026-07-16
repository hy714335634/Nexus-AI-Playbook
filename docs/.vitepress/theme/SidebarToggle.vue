<script setup lang="ts">
import { ref, onMounted, watch } from 'vue'
import { useRoute } from 'vitepress'

const collapsed = ref(false)
const route = useRoute()

function apply(v: boolean) {
  if (typeof document === 'undefined') return
  document.documentElement.classList.toggle('nx-sidebar-collapsed', v)
}

function toggle() {
  collapsed.value = !collapsed.value
  apply(collapsed.value)
  try { localStorage.setItem('nx-sidebar-collapsed', collapsed.value ? '1' : '0') } catch {}
}

onMounted(() => {
  try { collapsed.value = localStorage.getItem('nx-sidebar-collapsed') === '1' } catch {}
  apply(collapsed.value)
})

const hasSidebar = ref(true)
function refresh() {
  if (typeof document === 'undefined') return
  hasSidebar.value = !document.body.classList.contains('VPHome')
    && !!document.querySelector('.VPSidebar')
}
onMounted(refresh)
watch(() => route.path, () => setTimeout(refresh, 120))
</script>

<template>
  <button
    v-if="hasSidebar"
    class="nx-sidebar-toggle"
    :class="{ 'is-collapsed': collapsed }"
    :title="collapsed ? '展开目录 Show sidebar' : '收起目录 Hide sidebar'"
    :aria-label="collapsed ? 'Show sidebar' : 'Hide sidebar'"
    @click="toggle"
  >
    <svg width="16" height="16" viewBox="0 0 16 16" fill="none" xmlns="http://www.w3.org/2000/svg">
      <rect x="1" y="2" width="14" height="12" rx="2" stroke="currentColor" stroke-width="1.3"/>
      <line x1="5.5" y1="2" x2="5.5" y2="14" stroke="currentColor" stroke-width="1.3"/>
      <path v-if="!collapsed" d="M9 6L7 8L9 10" stroke="currentColor" stroke-width="1.3" stroke-linecap="round" stroke-linejoin="round"/>
      <path v-else d="M9 6L11 8L9 10" stroke="currentColor" stroke-width="1.3" stroke-linecap="round" stroke-linejoin="round"/>
    </svg>
  </button>
</template>
