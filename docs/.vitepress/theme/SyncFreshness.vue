<template>
  <div v-if="syncInfo" class="sync-freshness">
    📅 本页基于 Nexus-AI commit
    <code>{{ syncInfo.source_commit.slice(0, 8) }}</code>
    于 <time :datetime="syncInfo.generated_at">{{ formatDate(syncInfo.generated_at) }}</time>
    由 <code>{{ syncInfo.generated_by }}</code> 自动生成。
    如发现过时，请 <a :href="issueUrl" target="_blank">报告问题</a>。
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useData } from 'vitepress'

const { frontmatter } = useData()
const syncInfo = computed(() => (frontmatter.value as any).sync)
const issueUrl = 'https://github.com/hy714335634/Nexus-AI-Playbook/issues/new?title=Docs+issue'

function formatDate(iso: string) {
  try { return new Date(iso).toISOString().split('T')[0] } catch { return iso }
}
</script>

<style scoped>
.sync-freshness {
  font-size: 0.85em;
  color: var(--vp-c-text-2);
  background: var(--vp-c-bg-soft);
  border-left: 3px solid var(--vp-c-brand-1);
  padding: 8px 12px;
  margin: 8px 0 24px;
  border-radius: 4px;
}
.sync-freshness code {
  font-size: inherit;
  padding: 1px 4px;
}
.sync-freshness a {
  color: var(--vp-c-brand-1);
}
</style>
