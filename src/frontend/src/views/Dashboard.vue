<template>
  <div class="dashboard-page">
    <div class="page-header">
      <h1>Tableau de bord</h1>
      <p>Bienvenue dans votre journal de bord RAG</p>
    </div>
    
    <div class="dashboard-grid">
      <!-- Statistiques -->
      <div class="dashboard-card stats-card">
        <h2>Statistiques</h2>
        <div class="stats-grid">
          <div class="stat-item">
            <div class="stat-value">{{ stats.totalEntries }}</div>
            <div class="stat-label">Entrées</div>
          </div>
          <div class="stat-item">
            <div class="stat-value">{{ stats.totalTags }}</div>
            <div class="stat-label">Tags</div>
          </div>
          <div class="stat-item">
            <div class="stat-value">{{ stats.entriesThisMonth }}</div>
            <div class="stat-label">Ce mois</div>
          </div>
          <div class="stat-item">
            <div class="stat-value">{{ stats.entriesThisWeek }}</div>
            <div class="stat-label">Cette semaine</div>
          </div>
        </div>
      </div>
      
      <!-- Entrées récentes -->
      <div class="dashboard-card recent-entries-card">
        <div class="card-header">
          <h2>Entrées récentes</h2>
          <router-link to="/journal" class="view-all">Voir tout</router-link>
        </div>
        <div v-if="loading" class="loading-state">
          <i class="fas fa-spinner fa-spin"></i>
          <p>Chargement des entrées...</p>
        </div>
        <div v-else-if="recentEntries.length === 0" class="empty-state">
          <i class="fas fa-book"></i>
          <p>Aucune entrée récente.</p>
          <router-link to="/journal/create" class="create-button">
            Créer une entrée
          </router-link>
        </div>
        <div v-else class="recent-entries-list">
          <div 
            v-for="entry in recentEntries" 
            :key="entry.file"
            class="entry-item"
            @click="viewEntry(entry.file)"
          >
            <div class="entry-header">
              <h3>{{ entry.title }}</h3>
              <span class="entry-date">{{ formatDate(entry.date) }}</span>
            </div>
            <div class="entry-tags">
              <span 
                v-for="tag in entry.tags.slice(0, 3)" 
                :key="tag"
                class="entry-tag"
              >
                {{ tag }}
              </span>
              <span v-if="entry.tags.length > 3" class="more-tags">+{{ entry.tags.length - 3 }}</span>
            </div>
          </div>
        </div>
      </div>
      
      <!-- Insights -->
      <div class="dashboard-card insights-card">
        <h2>Insights</h2>
        <div v-if="loading" class="loading-state">
          <i class="fas fa-spinner fa-spin"></i>
          <p>Chargement des insights...</p>
        </div>
        <div v-else-if="insights.length === 0" class="empty-state">
          <i class="fas fa-lightbulb"></i>
          <p>Aucun insight disponible.</p>
        </div>
        <div v-else class="insights-list">
          <div 
            v-for="(insight, index) in insights" 
            :key="index"
            class="insight-item"
          >
            <div class="insight-icon" :class="insight.type">
              <i :class="getInsightIcon(insight.type)"></i>
            </div>
            <div class="insight-content">
              <h3>{{ insight.title }}</h3>
              <p>{{ insight.description }}</p>
            </div>
          </div>
        </div>
      </div>
      
      <!-- Activité récente -->
      <div class="dashboard-card activity-card">
        <h2>Activité récente</h2>
        <div v-if="loading" class="loading-state">
          <i class="fas fa-spinner fa-spin"></i>
          <p>Chargement de l'activité...</p>
        </div>
        <div v-else-if="activities.length === 0" class="empty-state">
          <i class="fas fa-history"></i>
          <p>Aucune activité récente.</p>
        </div>
        <div v-else class="activity-list">
          <div 
            v-for="(activity, index) in activities" 
            :key="index"
            class="activity-item"
          >
            <div class="activity-icon" :class="activity.type">
              <i :class="getActivityIcon(activity.type)"></i>
            </div>
            <div class="activity-content">
              <p>{{ activity.description }}</p>
              <span class="activity-time">{{ formatTime(activity.timestamp) }}</span>
            </div>
          </div>
        </div>
      </div>
      
      <!-- Intégrations -->
      <div class="dashboard-card integrations-card">
        <h2>Intégrations</h2>
        <div class="integrations-list">
          <div class="integration-item" :class="{ active: integrations.notion }">
            <div class="integration-icon">
              <i class="fab fa-notion"></i>
            </div>
            <div class="integration-content">
              <h3>Notion</h3>
              <p>{{ integrations.notion ? 'Connecté' : 'Non connecté' }}</p>
            </div>
          </div>
          <div class="integration-item" :class="{ active: integrations.github }">
            <div class="integration-icon">
              <i class="fab fa-github"></i>
            </div>
            <div class="integration-content">
              <h3>GitHub</h3>
              <p>{{ integrations.github ? 'Connecté' : 'Non connecté' }}</p>
            </div>
          </div>
          <div class="integration-item" :class="{ active: integrations.jira }">
            <div class="integration-icon">
              <i class="fab fa-jira"></i>
            </div>
            <div class="integration-content">
              <h3>Jira</h3>
              <p>{{ integrations.jira ? 'Connecté' : 'Non connecté' }}</p>
            </div>
          </div>
          <div class="integration-item" :class="{ active: integrations.n8n }">
            <div class="integration-icon">
              <i class="fas fa-cogs"></i>
            </div>
            <div class="integration-content">
              <h3>n8n</h3>
              <p>{{ integrations.n8n ? 'Connecté' : 'Non connecté' }}</p>
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
  name: 'Dashboard',
  data() {
    return {
      stats: {
        totalEntries: 0,
        totalTags: 0,
        entriesThisMonth: 0,
        entriesThisWeek: 0
      },
      recentEntries: [],
      insights: [],
      activities: [],
      integrations: {
        notion: false,
        github: false,
        jira: false,
        n8n: false
      }
    };
  },
  computed: {
    ...mapGetters({
      loading: 'isLoading',
      error: 'error'
    })
  },
  mounted() {
    this.fetchDashboardData();
  },
  methods: {
    ...mapActions({
      setLoading: 'setLoading',
      setError: 'setError',
      clearError: 'clearError'
    }),
    
    async fetchDashboardData() {
      this.setLoading(true);
      this.clearError();
      
      try {
        // Dans une implémentation réelle, ces données viendraient de l'API
        // Pour l'instant, nous utilisons des données fictives
        
        // Statistiques
        this.stats = {
          totalEntries: 42,
          totalTags: 18,
          entriesThisMonth: 12,
          entriesThisWeek: 5
        };
        
        // Entrées récentes
        this.recentEntries = [
          {
            file: '2025-04-05-14-30-implementation-du-systeme-rag.md',
            title: 'Implémentation du système RAG',
            date: '2025-04-05',
            tags: ['rag', 'python', 'nlp']
          },
          {
            file: '2025-04-03-10-15-integration-avec-notion.md',
            title: 'Intégration avec Notion',
            date: '2025-04-03',
            tags: ['notion', 'api', 'integration']
          },
          {
            file: '2025-04-01-16-45-analyse-semantique-avancee.md',
            title: 'Analyse sémantique avancée',
            date: '2025-04-01',
            tags: ['nlp', 'embeddings', 'analyse']
          }
        ];
        
        // Insights
        this.insights = [
          {
            type: 'trend',
            title: 'Tendance détectée',
            description: 'Le terme "embeddings" a augmenté de 150% ce mois-ci.'
          },
          {
            type: 'sentiment',
            title: 'Évolution du sentiment',
            description: 'Le sentiment général est devenu plus positif (+0.3).'
          },
          {
            type: 'topic',
            title: 'Nouveau sujet dominant',
            description: 'Un nouveau sujet "Intégration API" a émergé.'
          }
        ];
        
        // Activités
        this.activities = [
          {
            type: 'entry',
            description: 'Nouvelle entrée créée: "Implémentation du système RAG"',
            timestamp: new Date(2025, 3, 5, 14, 30)
          },
          {
            type: 'integration',
            description: 'Synchronisation avec Notion effectuée',
            timestamp: new Date(2025, 3, 4, 9, 15)
          },
          {
            type: 'analysis',
            description: 'Analyse sémantique terminée',
            timestamp: new Date(2025, 3, 3, 16, 45)
          }
        ];
        
        // Intégrations
        this.integrations = {
          notion: true,
          github: true,
          jira: false,
          n8n: true
        };
      } catch (error) {
        this.setError('Erreur lors du chargement des données du tableau de bord');
        console.error('Error fetching dashboard data:', error);
      } finally {
        this.setLoading(false);
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
    
    formatTime(timestamp) {
      if (!timestamp) return '';
      const now = new Date();
      const diff = now - timestamp;
      
      // Moins d'une minute
      if (diff < 60000) {
        return 'À l\'instant';
      }
      
      // Moins d'une heure
      if (diff < 3600000) {
        const minutes = Math.floor(diff / 60000);
        return `Il y a ${minutes} minute${minutes > 1 ? 's' : ''}`;
      }
      
      // Moins d'un jour
      if (diff < 86400000) {
        const hours = Math.floor(diff / 3600000);
        return `Il y a ${hours} heure${hours > 1 ? 's' : ''}`;
      }
      
      // Moins d'une semaine
      if (diff < 604800000) {
        const days = Math.floor(diff / 86400000);
        return `Il y a ${days} jour${days > 1 ? 's' : ''}`;
      }
      
      // Date complète
      return timestamp.toLocaleDateString('fr-FR', {
        year: 'numeric',
        month: 'short',
        day: 'numeric'
      });
    },
    
    getInsightIcon(type) {
      switch (type) {
        case 'trend':
          return 'fas fa-chart-line';
        case 'sentiment':
          return 'fas fa-smile';
        case 'topic':
          return 'fas fa-lightbulb';
        default:
          return 'fas fa-info-circle';
      }
    },
    
    getActivityIcon(type) {
      switch (type) {
        case 'entry':
          return 'fas fa-edit';
        case 'integration':
          return 'fas fa-plug';
        case 'analysis':
          return 'fas fa-chart-bar';
        default:
          return 'fas fa-history';
      }
    },
    
    viewEntry(entryFile) {
      const entryId = entryFile.replace('.md', '');
      this.$router.push({ name: 'journal-entry', params: { id: entryId } });
    }
  }
};
</script>

<style scoped>
.dashboard-page {
  @apply h-full flex flex-col;
}

.page-header {
  @apply mb-6;
}

.page-header h1 {
  @apply text-2xl font-bold text-gray-800 mb-2;
}

.page-header p {
  @apply text-gray-600;
}

.dashboard-grid {
  @apply grid gap-6 flex-1;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  grid-auto-rows: minmax(200px, auto);
}

.dashboard-card {
  @apply bg-white border border-gray-200 rounded-lg p-4 shadow-sm;
}

.dashboard-card h2 {
  @apply text-lg font-semibold text-gray-800 mb-4;
}

.card-header {
  @apply flex justify-between items-center mb-4;
}

.view-all {
  @apply text-sm text-blue-500 hover:text-blue-700;
}

/* Statistiques */
.stats-grid {
  @apply grid grid-cols-2 gap-4;
}

.stat-item {
  @apply flex flex-col items-center justify-center p-4 bg-gray-50 rounded-lg;
}

.stat-value {
  @apply text-2xl font-bold text-blue-600;
}

.stat-label {
  @apply text-sm text-gray-500 mt-1;
}

/* Entrées récentes */
.recent-entries-list {
  @apply space-y-3;
}

.entry-item {
  @apply p-3 border border-gray-100 rounded-lg hover:bg-gray-50 cursor-pointer;
}

.entry-header {
  @apply flex justify-between items-start mb-2;
}

.entry-header h3 {
  @apply text-base font-medium text-gray-800;
}

.entry-date {
  @apply text-xs text-gray-500;
}

.entry-tags {
  @apply flex flex-wrap;
}

.entry-tag {
  @apply text-xs px-2 py-1 bg-blue-100 text-blue-800 rounded-full mr-1;
}

.more-tags {
  @apply text-xs px-2 py-1 bg-gray-100 text-gray-600 rounded-full;
}

/* Insights */
.insights-list {
  @apply space-y-3;
}

.insight-item {
  @apply flex items-start p-3 border border-gray-100 rounded-lg;
}

.insight-icon {
  @apply flex-shrink-0 w-8 h-8 flex items-center justify-center rounded-full mr-3;
}

.insight-icon.trend {
  @apply bg-green-100 text-green-600;
}

.insight-icon.sentiment {
  @apply bg-blue-100 text-blue-600;
}

.insight-icon.topic {
  @apply bg-purple-100 text-purple-600;
}

.insight-content h3 {
  @apply text-sm font-medium text-gray-800 mb-1;
}

.insight-content p {
  @apply text-xs text-gray-600;
}

/* Activité récente */
.activity-list {
  @apply space-y-3;
}

.activity-item {
  @apply flex items-start p-3 border border-gray-100 rounded-lg;
}

.activity-icon {
  @apply flex-shrink-0 w-8 h-8 flex items-center justify-center rounded-full mr-3;
}

.activity-icon.entry {
  @apply bg-blue-100 text-blue-600;
}

.activity-icon.integration {
  @apply bg-green-100 text-green-600;
}

.activity-icon.analysis {
  @apply bg-purple-100 text-purple-600;
}

.activity-content p {
  @apply text-sm text-gray-800;
}

.activity-time {
  @apply text-xs text-gray-500;
}

/* Intégrations */
.integrations-list {
  @apply space-y-3;
}

.integration-item {
  @apply flex items-center p-3 border border-gray-200 rounded-lg;
}

.integration-item.active {
  @apply border-green-200 bg-green-50;
}

.integration-icon {
  @apply flex-shrink-0 w-10 h-10 flex items-center justify-center rounded-full mr-3 bg-gray-100 text-gray-500;
}

.integration-item.active .integration-icon {
  @apply bg-green-100 text-green-600;
}

.integration-content h3 {
  @apply text-sm font-medium text-gray-800;
}

.integration-content p {
  @apply text-xs text-gray-500;
}

.integration-item.active .integration-content p {
  @apply text-green-600;
}

/* États */
.loading-state, .empty-state {
  @apply flex flex-col items-center justify-center h-32 text-gray-500;
}

.loading-state i, .empty-state i {
  @apply text-2xl mb-2;
}

.create-button {
  @apply mt-2 px-3 py-1 text-sm bg-blue-500 text-white rounded-lg hover:bg-blue-600;
}
</style>
