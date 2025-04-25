<template>
  <header class="header">
    <div class="header-left">
      <button class="menu-toggle" @click="toggleSidebar">
        <i class="fas fa-bars"></i>
      </button>
      <h2 class="page-title">{{ pageTitle }}</h2>
    </div>
    <div class="header-right">
      <div class="search-bar">
        <input 
          type="text" 
          placeholder="Rechercher..." 
          v-model="searchQuery"
          @keyup.enter="search"
        >
        <button @click="search">
          <i class="fas fa-search"></i>
        </button>
      </div>
      <div class="header-actions">
        <button class="action-button" @click="createEntry">
          <i class="fas fa-plus"></i>
          <span>Nouvelle entrée</span>
        </button>
        <NotificationCenter />
      </div>
    </div>
  </header>
</template>

<script>
import NotificationCenter from '@/components/common/NotificationCenter.vue';
import { mapActions } from 'vuex';

export default {
  name: 'Header',
  components: {
    NotificationCenter
  },
  data() {
    return {
      searchQuery: ''
    }
  },
  computed: {
    pageTitle() {
      const route = this.$route;
      if (route.meta && route.meta.title) {
        return route.meta.title;
      }
      return 'Journal de Bord RAG';
    }
  },
  methods: {
    ...mapActions(['toggleSidebar']),
    search() {
      if (this.searchQuery.trim()) {
        this.$router.push({ 
          name: 'search', 
          query: { q: this.searchQuery } 
        });
        this.searchQuery = '';
      }
    },
    createEntry() {
      this.$router.push({ name: 'journal-create' });
    }
  }
}
</script>

<style scoped>
.header {
  @apply bg-white shadow-sm px-4 py-3 flex items-center justify-between;
}

.header-left {
  @apply flex items-center;
}

.menu-toggle {
  @apply mr-4 text-gray-500 hover:text-gray-700 focus:outline-none;
}

.page-title {
  @apply text-xl font-semibold text-gray-800;
}

.header-right {
  @apply flex items-center;
}

.search-bar {
  @apply relative mr-4;
}

.search-bar input {
  @apply w-64 px-4 py-2 pr-10 rounded-lg border border-gray-300 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent;
}

.search-bar button {
  @apply absolute right-0 top-0 h-full px-3 text-gray-500 hover:text-gray-700 focus:outline-none;
}

.header-actions {
  @apply flex items-center;
}

.action-button {
  @apply flex items-center px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 mr-2;
}

.action-button i {
  @apply mr-2;
}
</style>
