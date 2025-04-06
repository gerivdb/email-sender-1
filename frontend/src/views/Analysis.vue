<template>
  <div class="analysis-page">
    <div class="page-header">
      <h1>Analyse du Journal de Bord</h1>
      <p>Explorez les tendances, patterns et insights extraits de votre journal de bord.</p>
    </div>
    
    <div class="tab-navigation">
      <button 
        v-for="tab in tabs" 
        :key="tab.id"
        :class="{ active: activeTab === tab.id }"
        @click="activeTab = tab.id"
      >
        <i :class="tab.icon"></i>
        {{ tab.label }}
      </button>
    </div>
    
    <div class="tab-content">
      <!-- Nuage de mots -->
      <div v-if="activeTab === 'wordcloud'" class="tab-pane">
        <div class="visualization-container">
          <WordCloudViz 
            :width="visualizationWidth" 
            :height="visualizationHeight"
            @view-entry="viewEntry"
          />
        </div>
      </div>
      
      <!-- Évolution des tags -->
      <div v-else-if="activeTab === 'tag-evolution'" class="tab-pane">
        <div class="visualization-container">
          <TagEvolutionViz 
            :width="visualizationWidth" 
            :height="visualizationHeight"
          />
        </div>
      </div>
      
      <!-- Tendances des sujets -->
      <div v-else-if="activeTab === 'topic-trends'" class="tab-pane">
        <div class="visualization-container">
          <TopicTrendsViz 
            :width="visualizationWidth" 
            :height="visualizationHeight"
            @view-entry="viewEntry"
          />
        </div>
      </div>
      
      <!-- Relations entre entrées -->
      <div v-else-if="activeTab === 'entry-relationships'" class="tab-pane">
        <div class="visualization-container">
          <EntryRelationshipViz 
            :width="visualizationWidth" 
            :height="visualizationHeight"
            @view-entry="viewEntry"
          />
        </div>
      </div>
      
      <!-- Clustering -->
      <div v-else-if="activeTab === 'clustering'" class="tab-pane">
        <div class="visualization-container">
          <ClusteringViz 
            :width="visualizationWidth" 
            :height="visualizationHeight"
            @view-entry="viewEntry"
          />
        </div>
      </div>
      
      <!-- Analyse de sentiment -->
      <div v-else-if="activeTab === 'sentiment'" class="tab-pane">
        <div class="visualization-container">
          <SentimentViz 
            :width="visualizationWidth" 
            :height="visualizationHeight"
            @view-entry="viewEntry"
          />
        </div>
      </div>
      
      <!-- Insights -->
      <div v-else-if="activeTab === 'insights'" class="tab-pane">
        <div class="insights-container">
          <InsightsPanel />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import WordCloudViz from '@/components/visualizations/WordCloudViz.vue';
import TagEvolutionViz from '@/components/visualizations/TagEvolutionViz.vue';
import TopicTrendsViz from '@/components/visualizations/TopicTrendsViz.vue';
import EntryRelationshipViz from '@/components/visualizations/EntryRelationshipViz.vue';
import { mapActions } from 'vuex';

export default {
  name: 'Analysis',
  components: {
    WordCloudViz,
    TagEvolutionViz,
    TopicTrendsViz,
    EntryRelationshipViz
  },
  data() {
    return {
      activeTab: 'wordcloud',
      tabs: [
        { id: 'wordcloud', label: 'Nuage de mots', icon: 'fas fa-cloud' },
        { id: 'tag-evolution', label: 'Évolution des tags', icon: 'fas fa-tags' },
        { id: 'topic-trends', label: 'Tendances des sujets', icon: 'fas fa-chart-line' },
        { id: 'entry-relationships', label: 'Relations', icon: 'fas fa-project-diagram' },
        { id: 'clustering', label: 'Clustering', icon: 'fas fa-object-group' },
        { id: 'sentiment', label: 'Sentiment', icon: 'fas fa-smile' },
        { id: 'insights', label: 'Insights', icon: 'fas fa-lightbulb' }
      ],
      visualizationWidth: 800,
      visualizationHeight: 500
    };
  },
  mounted() {
    // Initialiser la taille des visualisations en fonction de la taille de la fenêtre
    this.updateVisualizationSize();
    
    // Mettre à jour la taille lors du redimensionnement de la fenêtre
    window.addEventListener('resize', this.updateVisualizationSize);
    
    // Vérifier si un onglet est spécifié dans l'URL
    const section = this.$route.query.section;
    if (section && this.tabs.some(tab => tab.id === section)) {
      this.activeTab = section;
    }
  },
  beforeUnmount() {
    window.removeEventListener('resize', this.updateVisualizationSize);
  },
  methods: {
    ...mapActions('journal', ['fetchEntry']),
    
    updateVisualizationSize() {
      const container = document.querySelector('.visualization-container');
      if (container) {
        this.visualizationWidth = container.clientWidth;
        this.visualizationHeight = Math.max(500, container.clientHeight);
      }
    },
    
    viewEntry(entryId) {
      this.$router.push({ name: 'journal-entry', params: { id: entryId } });
    }
  },
  watch: {
    activeTab(newTab) {
      // Mettre à jour l'URL pour refléter l'onglet actif
      this.$router.replace({ query: { ...this.$route.query, section: newTab } });
    }
  }
};
</script>

<style scoped>
.analysis-page {
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

.tab-navigation {
  @apply flex mb-4 border-b border-gray-200 overflow-x-auto;
}

.tab-navigation button {
  @apply px-4 py-2 text-gray-600 hover:text-gray-800 focus:outline-none whitespace-nowrap;
}

.tab-navigation button.active {
  @apply text-blue-500 border-b-2 border-blue-500;
}

.tab-navigation button i {
  @apply mr-2;
}

.tab-content {
  @apply flex-1 overflow-hidden;
}

.tab-pane {
  @apply h-full;
}

.visualization-container {
  @apply h-full border border-gray-200 rounded-lg bg-white p-4;
}

.insights-container {
  @apply h-full border border-gray-200 rounded-lg bg-white p-4 overflow-y-auto;
}
</style>
