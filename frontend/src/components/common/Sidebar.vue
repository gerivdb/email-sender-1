<template>
  <div class="sidebar">
    <div class="sidebar-header">
      <h1 class="sidebar-title">Journal RAG</h1>
    </div>
    <nav class="sidebar-nav">
      <router-link to="/" class="nav-item" exact>
        <i class="fas fa-home"></i>
        <span>Dashboard</span>
      </router-link>
      <router-link to="/journal" class="nav-item">
        <i class="fas fa-book"></i>
        <span>Journal</span>
      </router-link>
      <router-link to="/analysis" class="nav-item">
        <i class="fas fa-chart-bar"></i>
        <span>Analyse</span>
      </router-link>
      <router-link to="/github" class="nav-item">
        <i class="fab fa-github"></i>
        <span>GitHub</span>
      </router-link>
      <router-link to="/jira" class="nav-item">
        <i class="fab fa-jira"></i>
        <span>Jira</span>
      </router-link>
      <router-link to="/notion" class="nav-item">
        <i class="fas fa-sticky-note"></i>
        <span>Notion</span>
      </router-link>
      <router-link to="/settings" class="nav-item">
        <i class="fas fa-cog"></i>
        <span>Paramètres</span>
      </router-link>
    </nav>
    <div class="sidebar-footer">
      <NotificationBadge />
      <div class="user-info">
        <span>{{ username }}</span>
      </div>
    </div>
  </div>
</template>

<script>
import NotificationBadge from '@/components/common/NotificationBadge.vue';
import { mapGetters } from 'vuex';

export default {
  name: 'Sidebar',
  components: {
    NotificationBadge
  },
  computed: {
    ...mapGetters(['username'])
  }
}
</script>

<style scoped>
.sidebar {
  @apply w-64 bg-gray-800 text-white flex flex-col h-full;
}

.sidebar-header {
  @apply p-4 border-b border-gray-700;
}

.sidebar-title {
  @apply text-xl font-bold;
}

.sidebar-nav {
  @apply flex-1 overflow-y-auto py-4;
}

.nav-item {
  @apply flex items-center px-4 py-3 text-gray-300 hover:bg-gray-700 hover:text-white transition-colors;
}

.nav-item.router-link-active {
  @apply bg-gray-700 text-white;
}

.nav-item i {
  @apply mr-3 text-lg;
}

.sidebar-footer {
  @apply p-4 border-t border-gray-700 flex items-center justify-between;
}

.user-info {
  @apply text-sm;
}
</style>
