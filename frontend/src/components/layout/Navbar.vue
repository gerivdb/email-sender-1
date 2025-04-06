<template>
  <nav class="navbar">
    <div class="navbar-brand">
      <router-link to="/" class="brand-link">
        <span class="brand-logo">📔</span>
        <span class="brand-name">Journal RAG</span>
      </router-link>
    </div>
    
    <div class="navbar-menu">
      <router-link to="/" class="nav-link" exact>
        <i class="fas fa-tachometer-alt"></i>
        <span>Tableau de bord</span>
      </router-link>
      
      <router-link to="/journal" class="nav-link">
        <i class="fas fa-book"></i>
        <span>Journal</span>
      </router-link>
      
      <router-link to="/analysis" class="nav-link">
        <i class="fas fa-chart-bar"></i>
        <span>Analyse</span>
      </router-link>
      
      <router-link to="/settings" class="nav-link">
        <i class="fas fa-cog"></i>
        <span>Paramètres</span>
      </router-link>
    </div>
    
    <div class="navbar-actions">
      <div class="search-box">
        <input 
          type="text" 
          v-model="searchQuery" 
          placeholder="Rechercher..." 
          @keyup.enter="search"
          @focus="showSearchResults = true"
          @blur="hideSearchResultsDelayed"
        >
        <button @click="search">
          <i class="fas fa-search"></i>
        </button>
        
        <div v-if="showSearchResults && searchResults.length > 0" class="search-results">
          <div 
            v-for="result in searchResults" 
            :key="result.file"
            class="search-result"
            @mousedown.prevent="viewSearchResult(result)"
          >
            <div class="result-title">{{ result.title }}</div>
            <div class="result-meta">
              <span class="result-date">{{ formatDate(result.date) }}</span>
              <span 
                v-for="tag in result.tags.slice(0, 2)" 
                :key="tag"
                class="result-tag"
              >
                {{ tag }}
              </span>
            </div>
          </div>
          
          <div class="search-footer">
            <button @click.prevent="viewAllResults" class="view-all-button">
              Voir tous les résultats ({{ totalResults }})
            </button>
          </div>
        </div>
      </div>
      
      <div class="notifications-dropdown">
        <button 
          @click="toggleNotifications" 
          class="notifications-button"
          :class="{ 'has-unread': unreadCount > 0 }"
        >
          <i class="fas fa-bell"></i>
          <span v-if="unreadCount > 0" class="unread-badge">{{ unreadCount }}</span>
        </button>
        
        <notifications-panel 
          v-if="showNotifications" 
          @close="showNotifications = false"
          @view-notification="viewNotification"
        />
      </div>
      
      <div class="rag-dropdown">
        <button @click="toggleRag" class="rag-button">
          <i class="fas fa-robot"></i>
        </button>
        
        <div v-if="showRag" class="rag-panel">
          <div class="panel-header">
            <h3>Interroger le RAG</h3>
            <button @click="showRag = false" class="close-button">
              <i class="fas fa-times"></i>
            </button>
          </div>
          
          <div class="panel-content">
            <div class="rag-query">
              <textarea 
                v-model="ragQuery" 
                placeholder="Posez une question en langage naturel..."
                rows="3"
              ></textarea>
              <button @click="queryRag" :disabled="isRagLoading || !ragQuery.trim()" class="query-button">
                <i class="fas fa-paper-plane"></i>
                {{ isRagLoading ? 'Chargement...' : 'Interroger' }}
              </button>
            </div>
            
            <div v-if="ragResponse" class="rag-response">
              <div class="response-content" v-html="ragResponse"></div>
              
              <div v-if="ragSources.length > 0" class="response-sources">
                <h4>Sources:</h4>
                <div 
                  v-for="(source, index) in ragSources" 
                  :key="index"
                  class="source-item"
                >
                  <div class="source-title" @click="viewSource(source)">
                    {{ source.title }} ({{ formatDate(source.date) }})
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
      
      <div class="user-dropdown">
        <button @click="toggleUserMenu" class="user-button">
          <div class="user-avatar">
            <i class="fas fa-user"></i>
          </div>
        </button>
        
        <div v-if="showUserMenu" class="user-menu">
          <div class="menu-header">
            <div class="user-info">
              <div class="user-name">Utilisateur</div>
              <div class="user-email">utilisateur@example.com</div>
            </div>
          </div>
          
          <div class="menu-items">
            <router-link to="/settings/profile" class="menu-item" @click="showUserMenu = false">
              <i class="fas fa-user-cog"></i>
              <span>Profil</span>
            </router-link>
            
            <router-link to="/settings/preferences" class="menu-item" @click="showUserMenu = false">
              <i class="fas fa-sliders-h"></i>
              <span>Préférences</span>
            </router-link>
            
            <div class="menu-divider"></div>
            
            <button @click="logout" class="menu-item logout">
              <i class="fas fa-sign-out-alt"></i>
              <span>Déconnexion</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  </nav>
</template>

<script>
import { mapGetters, mapActions } from 'vuex';
import NotificationsPanel from '@/components/common/NotificationsPanel.vue';

export default {
  name: 'Navbar',
  components: {
    NotificationsPanel
  },
  data() {
    return {
      searchQuery: '',
      showSearchResults: false,
      searchResults: [],
      totalResults: 0,
      showNotifications: false,
      showRag: false,
      showUserMenu: false,
      ragQuery: '',
      ragResponse: '',
      ragSources: [],
      isRagLoading: false
    };
  },
  computed: {
    ...mapGetters({
      unreadCount: 'notifications/unreadNotifications',
      isLoading: 'journal/loading'
    })
  },
  mounted() {
    // Ajouter des écouteurs pour fermer les menus lors d'un clic à l'extérieur
    document.addEventListener('click', this.handleOutsideClick);
  },
  beforeUnmount() {
    document.removeEventListener('click', this.handleOutsideClick);
  },
  methods: {
    ...mapActions({
      searchJournal: 'journal/search',
      queryJournalRag: 'journal/queryRag'
    }),
    
    formatDate(dateString) {
      if (!dateString) return '';
      const date = new Date(dateString);
      return date.toLocaleDateString('fr-FR', {
        day: 'numeric',
        month: 'short',
        year: 'numeric'
      });
    },
    
    async search() {
      if (!this.searchQuery.trim()) {
        this.searchResults = [];
        this.totalResults = 0;
        return;
      }
      
      try {
        const results = await this.searchJournal({ query: this.searchQuery, limit: 5 });
        this.searchResults = results.slice(0, 5);
        this.totalResults = results.length;
        this.showSearchResults = true;
      } catch (error) {
        console.error('Error searching journal:', error);
      }
    },
    
    hideSearchResultsDelayed() {
      setTimeout(() => {
        this.showSearchResults = false;
      }, 200);
    },
    
    viewSearchResult(result) {
      const entryId = result.file.replace('.md', '');
      this.$router.push({ name: 'journal-entry', params: { id: entryId } });
      this.showSearchResults = false;
      this.searchQuery = '';
    },
    
    viewAllResults() {
      this.$router.push({ 
        name: 'journal', 
        query: { q: this.searchQuery } 
      });
      this.showSearchResults = false;
    },
    
    toggleNotifications(event) {
      event.stopPropagation();
      this.showNotifications = !this.showNotifications;
      this.showRag = false;
      this.showUserMenu = false;
    },
    
    toggleRag(event) {
      event.stopPropagation();
      this.showRag = !this.showRag;
      this.showNotifications = false;
      this.showUserMenu = false;
    },
    
    toggleUserMenu(event) {
      event.stopPropagation();
      this.showUserMenu = !this.showUserMenu;
      this.showNotifications = false;
      this.showRag = false;
    },
    
    handleOutsideClick(event) {
      const notificationsDropdown = this.$el.querySelector('.notifications-dropdown');
      const ragDropdown = this.$el.querySelector('.rag-dropdown');
      const userDropdown = this.$el.querySelector('.user-dropdown');
      
      if (notificationsDropdown && !notificationsDropdown.contains(event.target)) {
        this.showNotifications = false;
      }
      
      if (ragDropdown && !ragDropdown.contains(event.target)) {
        this.showRag = false;
      }
      
      if (userDropdown && !userDropdown.contains(event.target)) {
        this.showUserMenu = false;
      }
    },
    
    viewNotification(notification) {
      // Rediriger en fonction du type de notification
      switch (notification.type) {
        case 'term_frequency':
          this.$router.push({ name: 'analysis', query: { tab: 'terms' } });
          break;
        case 'sentiment':
          this.$router.push({ name: 'analysis', query: { tab: 'sentiment' } });
          break;
        case 'topic':
          this.$router.push({ name: 'analysis', query: { tab: 'topics' } });
          break;
        default:
          break;
      }
      
      this.showNotifications = false;
    },
    
    async queryRag() {
      if (!this.ragQuery.trim()) return;
      
      this.isRagLoading = true;
      
      try {
        const response = await this.queryJournalRag({ query: this.ragQuery });
        
        this.ragResponse = response.answer || 'Aucune réponse trouvée.';
        this.ragSources = response.sources || [];
      } catch (error) {
        console.error('Error querying RAG:', error);
        this.ragResponse = 'Une erreur est survenue lors de l\'interrogation du système RAG.';
        this.ragSources = [];
      } finally {
        this.isRagLoading = false;
      }
    },
    
    viewSource(source) {
      const entryId = source.file.replace('.md', '');
      this.$router.push({ name: 'journal-entry', params: { id: entryId } });
      this.showRag = false;
    },
    
    logout() {
      // Dans une implémentation réelle, cette fonction déconnecterait l'utilisateur
      alert('Déconnexion non implémentée');
      this.showUserMenu = false;
    }
  }
};
</script>

<style scoped>
.navbar {
  @apply flex items-center justify-between px-4 py-2 bg-white border-b border-gray-200 sticky top-0 z-10;
  height: 64px;
}

.navbar-brand {
  @apply flex-shrink-0;
}

.brand-link {
  @apply flex items-center text-xl font-bold text-gray-800 hover:text-gray-900;
}

.brand-logo {
  @apply mr-2;
}

.navbar-menu {
  @apply hidden md:flex items-center space-x-1;
}

.nav-link {
  @apply flex items-center px-3 py-2 text-sm text-gray-700 rounded-lg hover:bg-gray-100;
}

.nav-link.router-link-active {
  @apply bg-blue-50 text-blue-700;
}

.nav-link i {
  @apply mr-2;
}

.navbar-actions {
  @apply flex items-center space-x-2;
}

/* Search */
.search-box {
  @apply relative;
  width: 250px;
}

.search-box input {
  @apply w-full px-3 py-2 pr-10 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent;
}

.search-box button {
  @apply absolute right-0 top-0 h-full px-3 text-gray-500 hover:text-gray-700 focus:outline-none;
}

.search-results {
  @apply absolute left-0 right-0 mt-1 bg-white border border-gray-200 rounded-lg shadow-lg z-20;
  max-height: 400px;
  overflow-y: auto;
}

.search-result {
  @apply p-2 hover:bg-gray-50 cursor-pointer;
}

.result-title {
  @apply text-sm font-medium text-gray-800 mb-1;
}

.result-meta {
  @apply flex items-center;
}

.result-date {
  @apply text-xs text-gray-500 mr-2;
}

.result-tag {
  @apply text-xs px-1.5 py-0.5 bg-blue-100 text-blue-800 rounded-full mr-1;
}

.search-footer {
  @apply p-2 border-t border-gray-100;
}

.view-all-button {
  @apply w-full text-xs text-center text-blue-600 hover:text-blue-800 focus:outline-none;
}

/* Notifications */
.notifications-dropdown {
  @apply relative;
}

.notifications-button {
  @apply relative p-2 text-gray-700 hover:text-gray-900 hover:bg-gray-100 rounded-full focus:outline-none;
}

.notifications-button.has-unread::after {
  content: '';
  @apply absolute top-1 right-1 w-2 h-2 bg-red-500 rounded-full;
}

.unread-badge {
  @apply absolute -top-1 -right-1 flex items-center justify-center w-5 h-5 text-xs text-white bg-red-500 rounded-full;
}

/* RAG */
.rag-dropdown {
  @apply relative;
}

.rag-button {
  @apply p-2 text-gray-700 hover:text-gray-900 hover:bg-gray-100 rounded-full focus:outline-none;
}

.rag-panel {
  @apply absolute right-0 mt-2 bg-white border border-gray-200 rounded-lg shadow-lg overflow-hidden z-20;
  width: 350px;
}

.panel-header {
  @apply flex justify-between items-center p-3 border-b border-gray-200 bg-gray-50;
}

.panel-header h3 {
  @apply text-lg font-semibold text-gray-800;
}

.close-button {
  @apply text-gray-500 hover:text-gray-700 focus:outline-none;
}

.panel-content {
  @apply p-3;
}

.rag-query {
  @apply mb-3;
}

.rag-query textarea {
  @apply w-full px-3 py-2 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent mb-2 resize-none;
}

.query-button {
  @apply w-full flex items-center justify-center px-3 py-2 text-sm bg-blue-500 text-white rounded-lg hover:bg-blue-600 focus:outline-none disabled:opacity-50 disabled:cursor-not-allowed;
}

.query-button i {
  @apply mr-2;
}

.rag-response {
  @apply mt-4 p-3 bg-gray-50 border border-gray-200 rounded-lg;
}

.response-content {
  @apply text-sm text-gray-800 mb-3;
}

.response-sources h4 {
  @apply text-xs font-semibold text-gray-600 mb-1;
}

.source-item {
  @apply mb-1;
}

.source-title {
  @apply text-xs text-blue-600 hover:text-blue-800 cursor-pointer;
}

/* User */
.user-dropdown {
  @apply relative;
}

.user-button {
  @apply p-1 rounded-full focus:outline-none;
}

.user-avatar {
  @apply flex items-center justify-center w-8 h-8 bg-gray-200 text-gray-600 rounded-full;
}

.user-menu {
  @apply absolute right-0 mt-2 bg-white border border-gray-200 rounded-lg shadow-lg overflow-hidden z-20;
  width: 250px;
}

.menu-header {
  @apply p-3 border-b border-gray-200 bg-gray-50;
}

.user-info {
  @apply flex flex-col;
}

.user-name {
  @apply text-sm font-medium text-gray-800;
}

.user-email {
  @apply text-xs text-gray-500;
}

.menu-items {
  @apply py-1;
}

.menu-item {
  @apply flex items-center w-full px-4 py-2 text-sm text-left text-gray-700 hover:bg-gray-100 focus:outline-none;
}

.menu-item i {
  @apply mr-3 text-gray-500;
}

.menu-divider {
  @apply my-1 border-t border-gray-100;
}

.menu-item.logout {
  @apply text-red-600 hover:bg-red-50;
}

.menu-item.logout i {
  @apply text-red-500;
}

@media (max-width: 768px) {
  .navbar-menu {
    @apply hidden;
  }
  
  .search-box {
    width: 150px;
  }
}
</style>
