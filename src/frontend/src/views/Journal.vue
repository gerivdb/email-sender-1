<template>
  <div class="journal-page">
    <div class="page-header">
      <h1>Journal de Bord</h1>
      <div class="header-actions">
        <button @click="createEntry" class="create-button">
          <i class="fas fa-plus"></i>
          Nouvelle entrée
        </button>
      </div>
    </div>
    
    <div class="journal-layout">
      <!-- Sidebar avec filtres et tags -->
      <div class="journal-sidebar">
        <div class="search-box">
          <input 
            type="text" 
            v-model="searchQuery" 
            placeholder="Rechercher..." 
            @keyup.enter="search"
          >
          <button @click="search">
            <i class="fas fa-search"></i>
          </button>
        </div>
        
        <div class="filter-section">
          <h3>Filtres</h3>
          
          <div class="filter-group">
            <h4>Période</h4>
            <div class="date-filter">
              <button 
                v-for="period in periods" 
                :key="period.value"
                :class="{ active: selectedPeriod === period.value }"
                @click="selectPeriod(period.value)"
              >
                {{ period.label }}
              </button>
            </div>
            
            <div v-if="selectedPeriod === 'custom'" class="custom-date-range">
              <div class="date-input">
                <label>Du:</label>
                <input type="date" v-model="dateRange.start">
              </div>
              <div class="date-input">
                <label>Au:</label>
                <input type="date" v-model="dateRange.end">
              </div>
              <button @click="applyDateRange" class="apply-button">
                Appliquer
              </button>
            </div>
          </div>
          
          <div class="filter-group">
            <h4>Tags</h4>
            <div class="tag-cloud">
              <button 
                v-for="tag in sortedTags" 
                :key="tag.name"
                :class="{ active: selectedTags.includes(tag.name) }"
                @click="toggleTag(tag.name)"
                :style="{ fontSize: getTagSize(tag.count) }"
              >
                {{ tag.name }} <span class="tag-count">({{ tag.count }})</span>
              </button>
            </div>
          </div>
        </div>
        
        <div class="rag-section">
          <h3>Interroger le RAG</h3>
          <div class="rag-query">
            <textarea 
              v-model="ragQuery" 
              placeholder="Posez une question en langage naturel..."
              rows="3"
            ></textarea>
            <button @click="queryRag" :disabled="isRagLoading" class="rag-button">
              <i class="fas fa-robot"></i>
              {{ isRagLoading ? 'Chargement...' : 'Interroger' }}
            </button>
          </div>
        </div>
      </div>
      
      <!-- Liste des entrées -->
      <div class="journal-content">
        <div v-if="isSearchMode" class="search-results-header">
          <h2>Résultats de recherche pour "{{ searchQuery }}"</h2>
          <button @click="clearSearch" class="clear-search">
            <i class="fas fa-times"></i> Effacer
          </button>
        </div>
        
        <div v-if="isRagMode" class="rag-results">
          <div class="rag-response">
            <h2>Réponse</h2>
            <div class="response-content" v-html="ragResponse"></div>
          </div>
          
          <h3>Sources</h3>
          <div class="rag-sources">
            <div 
              v-for="(source, index) in ragSources" 
              :key="index"
              class="source-item"
            >
              <div class="source-header" @click="toggleSource(index)">
                <h4>{{ source.title }}</h4>
                <span class="source-meta">
                  {{ formatDate(source.date) }} - {{ source.section }}
                </span>
                <i :class="['fas', expandedSources.includes(index) ? 'fa-chevron-up' : 'fa-chevron-down']"></i>
              </div>
              <div v-if="expandedSources.includes(index)" class="source-content">
                <p>{{ source.content }}</p>
                <button @click="viewEntry(source.file)" class="view-entry-button">
                  Voir l'entrée complète
                </button>
              </div>
            </div>
          </div>
          
          <button @click="clearRagResults" class="clear-rag">
            <i class="fas fa-times"></i> Effacer les résultats
          </button>
        </div>
        
        <div v-else-if="loading" class="loading-state">
          <i class="fas fa-spinner fa-spin"></i>
          <p>Chargement des entrées...</p>
        </div>
        
        <div v-else-if="filteredEntries.length === 0" class="empty-state">
          <i class="fas fa-book"></i>
          <p>Aucune entrée trouvée.</p>
          <button @click="createEntry" class="create-button">
            Créer une nouvelle entrée
          </button>
        </div>
        
        <div v-else class="entries-list">
          <div 
            v-for="entry in filteredEntries" 
            :key="entry.file"
            class="entry-card"
            @click="viewEntry(entry.file)"
          >
            <div class="entry-header">
              <h3>{{ entry.title }}</h3>
              <span class="entry-date">{{ formatDate(entry.date) }}</span>
            </div>
            
            <div class="entry-tags">
              <span 
                v-for="tag in entry.tags" 
                :key="tag"
                class="entry-tag"
              >
                {{ tag }}
              </span>
            </div>
            
            <p v-if="entry.excerpt" class="entry-excerpt">
              {{ entry.excerpt }}
            </p>
            
            <div class="entry-footer">
              <div class="entry-meta">
                <span v-if="entry.related && entry.related.length > 0" class="related-count">
                  <i class="fas fa-link"></i> {{ entry.related.length }}
                </span>
                <span v-if="entry.githubCommits && entry.githubCommits.length > 0" class="github-count">
                  <i class="fab fa-github"></i> {{ entry.githubCommits.length }}
                </span>
                <span v-if="entry.jiraIssues && entry.jiraIssues.length > 0" class="jira-count">
                  <i class="fab fa-jira"></i> {{ entry.jiraIssues.length }}
                </span>
              </div>
              <button class="view-button">
                Voir
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters, mapActions } from 'vuex';

export default {
  name: 'Journal',
  data() {
    return {
      searchQuery: '',
      selectedPeriod: 'all',
      periods: [
        { label: 'Tous', value: 'all' },
        { label: 'Aujourd\'hui', value: 'today' },
        { label: 'Cette semaine', value: 'week' },
        { label: 'Ce mois', value: 'month' },
        { label: 'Personnalisé', value: 'custom' }
      ],
      dateRange: {
        start: '',
        end: ''
      },
      selectedTags: [],
      isSearchMode: false,
      ragQuery: '',
      ragResponse: '',
      ragSources: [],
      expandedSources: [],
      isRagMode: false,
      isRagLoading: false
    };
  },
  computed: {
    ...mapGetters('journal', ['allEntries', 'allTags', 'loading', 'error']),
    
    filteredEntries() {
      if (this.isSearchMode) {
        return this.$store.getters['journal/searchResults'];
      }
      
      let entries = [...this.allEntries];
      
      // Filtrer par période
      if (this.selectedPeriod !== 'all') {
        const now = new Date();
        let cutoffDate;
        
        switch (this.selectedPeriod) {
          case 'today':
            cutoffDate = new Date(now.setHours(0, 0, 0, 0));
            break;
          case 'week':
            cutoffDate = new Date(now.setDate(now.getDate() - now.getDay()));
            break;
          case 'month':
            cutoffDate = new Date(now.setDate(1));
            break;
          case 'custom':
            if (this.dateRange.start) {
              cutoffDate = new Date(this.dateRange.start);
              entries = entries.filter(entry => new Date(entry.date) >= cutoffDate);
            }
            
            if (this.dateRange.end) {
              const endDate = new Date(this.dateRange.end);
              endDate.setHours(23, 59, 59, 999);
              entries = entries.filter(entry => new Date(entry.date) <= endDate);
            }
            
            return entries;
        }
        
        entries = entries.filter(entry => new Date(entry.date) >= cutoffDate);
      }
      
      // Filtrer par tags
      if (this.selectedTags.length > 0) {
        entries = entries.filter(entry => 
          entry.tags && this.selectedTags.every(tag => entry.tags.includes(tag))
        );
      }
      
      return entries;
    },
    
    sortedTags() {
      return [...this.allTags].sort((a, b) => b.count - a.count);
    }
  },
  mounted() {
    this.fetchData();
    
    // Vérifier si une recherche est spécifiée dans l'URL
    const query = this.$route.query.q;
    if (query) {
      this.searchQuery = query;
      this.search();
    }
  },
  methods: {
    ...mapActions('journal', ['fetchEntries', 'fetchTags', 'searchJournal', 'queryRag']),
    
    async fetchData() {
      if (this.allEntries.length === 0) {
        await this.fetchEntries();
      }
      
      if (this.allTags.length === 0) {
        await this.fetchTags();
      }
    },
    
    formatDate(dateString) {
      if (!dateString) return '';
      const date = new Date(dateString);
      return date.toLocaleDateString('fr-FR', {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
      });
    },
    
    getTagSize(count) {
      const minSize = 12;
      const maxSize = 18;
      const maxCount = Math.max(...this.allTags.map(tag => tag.count));
      const minCount = Math.min(...this.allTags.map(tag => tag.count));
      
      if (maxCount === minCount) return `${minSize}px`;
      
      const size = minSize + (maxSize - minSize) * (count - minCount) / (maxCount - minCount);
      return `${size}px`;
    },
    
    selectPeriod(period) {
      this.selectedPeriod = period;
      
      if (period === 'custom') {
        // Initialiser la plage de dates avec le mois en cours
        const now = new Date();
        const firstDay = new Date(now.getFullYear(), now.getMonth(), 1);
        const lastDay = new Date(now.getFullYear(), now.getMonth() + 1, 0);
        
        this.dateRange.start = firstDay.toISOString().split('T')[0];
        this.dateRange.end = lastDay.toISOString().split('T')[0];
      }
    },
    
    applyDateRange() {
      // Déjà géré par le computed filteredEntries
    },
    
    toggleTag(tag) {
      if (this.selectedTags.includes(tag)) {
        this.selectedTags = this.selectedTags.filter(t => t !== tag);
      } else {
        this.selectedTags.push(tag);
      }
    },
    
    async search() {
      if (!this.searchQuery.trim()) {
        this.clearSearch();
        return;
      }
      
      this.isSearchMode = true;
      this.isRagMode = false;
      
      try {
        await this.searchJournal({ query: this.searchQuery });
        
        // Mettre à jour l'URL
        this.$router.replace({ query: { ...this.$route.query, q: this.searchQuery } });
      } catch (error) {
        console.error('Erreur lors de la recherche:', error);
      }
    },
    
    clearSearch() {
      this.searchQuery = '';
      this.isSearchMode = false;
      
      // Supprimer le paramètre de recherche de l'URL
      const query = { ...this.$route.query };
      delete query.q;
      this.$router.replace({ query });
    },
    
    async queryRag() {
      if (!this.ragQuery.trim()) return;
      
      this.isRagLoading = true;
      this.isRagMode = true;
      this.isSearchMode = false;
      
      try {
        const response = await this.queryRag({ query: this.ragQuery });
        
        this.ragResponse = response.answer || 'Aucune réponse trouvée.';
        this.ragSources = response.sources || [];
        this.expandedSources = [];
      } catch (error) {
        console.error('Erreur lors de l\'interrogation du RAG:', error);
        this.ragResponse = 'Une erreur est survenue lors de l\'interrogation du système RAG.';
        this.ragSources = [];
      } finally {
        this.isRagLoading = false;
      }
    },
    
    toggleSource(index) {
      if (this.expandedSources.includes(index)) {
        this.expandedSources = this.expandedSources.filter(i => i !== index);
      } else {
        this.expandedSources.push(index);
      }
    },
    
    clearRagResults() {
      this.ragQuery = '';
      this.ragResponse = '';
      this.ragSources = [];
      this.expandedSources = [];
      this.isRagMode = false;
    },
    
    viewEntry(entryFile) {
      const entryId = entryFile.replace('.md', '');
      this.$router.push({ name: 'journal-entry', params: { id: entryId } });
    },
    
    createEntry() {
      this.$router.push({ name: 'journal-create' });
    }
  }
};
</script>

<style scoped>
.journal-page {
  @apply h-full flex flex-col;
}

.page-header {
  @apply flex justify-between items-center mb-6;
}

.page-header h1 {
  @apply text-2xl font-bold text-gray-800;
}

.create-button {
  @apply flex items-center px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2;
}

.create-button i {
  @apply mr-2;
}

.journal-layout {
  @apply flex flex-1 overflow-hidden;
}

.journal-sidebar {
  @apply w-64 bg-white border-r border-gray-200 p-4 flex flex-col overflow-y-auto;
}

.search-box {
  @apply relative mb-4;
}

.search-box input {
  @apply w-full px-4 py-2 pr-10 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent;
}

.search-box button {
  @apply absolute right-0 top-0 h-full px-3 text-gray-500 hover:text-gray-700 focus:outline-none;
}

.filter-section {
  @apply mb-4;
}

.filter-section h3 {
  @apply text-lg font-semibold mb-2;
}

.filter-group {
  @apply mb-4;
}

.filter-group h4 {
  @apply text-sm font-medium text-gray-600 mb-2;
}

.date-filter {
  @apply flex flex-wrap;
}

.date-filter button {
  @apply px-2 py-1 text-sm border border-gray-300 rounded-lg mr-1 mb-1 hover:bg-gray-100 focus:outline-none;
}

.date-filter button.active {
  @apply bg-blue-500 text-white border-blue-500;
}

.custom-date-range {
  @apply mt-2 p-2 border border-gray-200 rounded-lg bg-gray-50;
}

.date-input {
  @apply flex items-center mb-2;
}

.date-input label {
  @apply w-8 text-sm text-gray-600;
}

.date-input input {
  @apply flex-1 px-2 py-1 border border-gray-300 rounded-lg focus:outline-none focus:ring-1 focus:ring-blue-500 focus:border-transparent;
}

.apply-button {
  @apply w-full px-2 py-1 text-sm bg-blue-500 text-white rounded-lg hover:bg-blue-600 focus:outline-none focus:ring-1 focus:ring-blue-500 focus:ring-offset-1;
}

.tag-cloud {
  @apply flex flex-wrap;
}

.tag-cloud button {
  @apply px-2 py-1 text-sm border border-gray-300 rounded-lg mr-1 mb-1 hover:bg-gray-100 focus:outline-none;
}

.tag-cloud button.active {
  @apply bg-blue-500 text-white border-blue-500;
}

.tag-count {
  @apply text-xs opacity-70;
}

.rag-section {
  @apply mt-auto pt-4 border-t border-gray-200;
}

.rag-section h3 {
  @apply text-lg font-semibold mb-2;
}

.rag-query textarea {
  @apply w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent mb-2 resize-none;
}

.rag-button {
  @apply w-full flex items-center justify-center px-4 py-2 bg-purple-500 text-white rounded-lg hover:bg-purple-600 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed;
}

.rag-button i {
  @apply mr-2;
}

.journal-content {
  @apply flex-1 p-4 overflow-y-auto;
}

.search-results-header {
  @apply flex justify-between items-center mb-4 pb-2 border-b border-gray-200;
}

.search-results-header h2 {
  @apply text-xl font-semibold;
}

.clear-search {
  @apply text-sm text-gray-500 hover:text-gray-700 focus:outline-none;
}

.rag-results {
  @apply mb-4;
}

.rag-response {
  @apply mb-4 p-4 bg-purple-50 border border-purple-200 rounded-lg;
}

.rag-response h2 {
  @apply text-lg font-semibold text-purple-700 mb-2;
}

.response-content {
  @apply prose prose-sm max-w-none;
}

.rag-sources h3 {
  @apply text-lg font-semibold mb-2;
}

.source-item {
  @apply mb-2 border border-gray-200 rounded-lg overflow-hidden;
}

.source-header {
  @apply flex items-center justify-between p-3 bg-gray-50 cursor-pointer hover:bg-gray-100;
}

.source-header h4 {
  @apply font-medium;
}

.source-meta {
  @apply text-sm text-gray-500;
}

.source-content {
  @apply p-3 border-t border-gray-200;
}

.view-entry-button {
  @apply mt-2 text-sm text-blue-500 hover:text-blue-700 focus:outline-none;
}

.clear-rag {
  @apply mt-4 text-sm text-gray-500 hover:text-gray-700 focus:outline-none;
}

.loading-state {
  @apply flex flex-col items-center justify-center h-64 text-gray-500;
}

.loading-state i {
  @apply text-3xl mb-2;
}

.empty-state {
  @apply flex flex-col items-center justify-center h-64 text-gray-500;
}

.empty-state i {
  @apply text-5xl mb-4;
}

.empty-state p {
  @apply mb-4;
}

.entries-list {
  @apply grid gap-4;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
}

.entry-card {
  @apply bg-white border border-gray-200 rounded-lg p-4 hover:shadow-md transition-shadow cursor-pointer;
}

.entry-header {
  @apply flex justify-between items-start mb-2;
}

.entry-header h3 {
  @apply text-lg font-semibold text-gray-800 mr-2;
}

.entry-date {
  @apply text-sm text-gray-500 whitespace-nowrap;
}

.entry-tags {
  @apply flex flex-wrap mb-2;
}

.entry-tag {
  @apply text-xs px-2 py-1 bg-gray-100 rounded-full mr-1 mb-1;
}

.entry-excerpt {
  @apply text-sm text-gray-600 mb-4 line-clamp-3;
}

.entry-footer {
  @apply flex justify-between items-center;
}

.entry-meta {
  @apply flex;
}

.entry-meta span {
  @apply text-xs text-gray-500 mr-2;
}

.view-button {
  @apply text-sm text-blue-500 hover:text-blue-700 focus:outline-none;
}

@media (max-width: 768px) {
  .journal-layout {
    @apply flex-col;
  }
  
  .journal-sidebar {
    @apply w-full border-r-0 border-b;
  }
}
</style>
