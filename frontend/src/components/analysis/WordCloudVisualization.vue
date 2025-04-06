<template>
  <div class="word-cloud-container">
    <div class="chart-header">
      <h3>Nuage de mots</h3>
      <div class="chart-controls">
        <div class="period-selector">
          <label for="period">Période:</label>
          <select id="period" v-model="selectedPeriod" @change="fetchData">
            <option value="all">Tout</option>
            <option value="month">Ce mois</option>
            <option value="quarter">Ce trimestre</option>
            <option value="year">Cette année</option>
          </select>
        </div>
        <div class="size-selector">
          <label for="max-words">Mots:</label>
          <select id="max-words" v-model="maxWords" @change="fetchData">
            <option value="50">50</option>
            <option value="100">100</option>
            <option value="200">200</option>
          </select>
        </div>
      </div>
    </div>
    
    <div class="chart-content">
      <div v-if="loading" class="loading-state">
        <i class="fas fa-spinner fa-spin"></i>
        <p>Génération du nuage de mots...</p>
      </div>
      
      <div v-else-if="error" class="error-state">
        <i class="fas fa-exclamation-triangle"></i>
        <p>{{ error }}</p>
        <button @click="fetchData" class="retry-button">
          Réessayer
        </button>
      </div>
      
      <div v-else-if="!hasData" class="empty-state">
        <i class="fas fa-cloud"></i>
        <p>Aucune donnée disponible pour cette période</p>
      </div>
      
      <div v-else ref="wordCloudChart" class="word-cloud-chart"></div>
    </div>
    
    <div v-if="selectedWord" class="word-details">
      <div class="word-header">
        <h4>{{ selectedWord.text }}</h4>
        <span class="word-count">{{ selectedWord.value }} occurrences</span>
      </div>
      
      <div class="word-stats">
        <div class="stat-item">
          <div class="stat-label">Fréquence relative</div>
          <div class="stat-value">{{ (selectedWord.frequency * 100).toFixed(2) }}%</div>
        </div>
        
        <div class="stat-item">
          <div class="stat-label">Évolution</div>
          <div class="stat-value" :class="getEvolutionClass(selectedWord.evolution)">
            <i :class="getEvolutionIcon(selectedWord.evolution)"></i>
            {{ selectedWord.evolution > 0 ? '+' : '' }}{{ selectedWord.evolution.toFixed(2) }}%
          </div>
        </div>
      </div>
      
      <div class="word-entries">
        <h5>Entrées récentes contenant "{{ selectedWord.text }}"</h5>
        <div v-if="relatedEntries.length === 0" class="loading-entries">
          <i class="fas fa-spinner fa-spin"></i>
          <p>Recherche d'entrées...</p>
        </div>
        <div v-else class="entries-list">
          <div 
            v-for="entry in relatedEntries" 
            :key="entry.id"
            class="entry-item"
          >
            <router-link :to="{ name: 'JournalEntry', params: { id: entry.id } }">
              <div class="entry-title">{{ entry.title }}</div>
              <div class="entry-date">{{ formatDate(entry.date) }}</div>
              <div class="entry-excerpt" v-html="highlightWord(entry.excerpt, selectedWord.text)"></div>
            </router-link>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { mapActions } from 'vuex';
import * as d3 from 'd3';
import cloud from 'd3-cloud';

export default {
  name: 'WordCloudVisualization',
  props: {
    height: {
      type: Number,
      default: 400
    }
  },
  data() {
    return {
      selectedPeriod: 'month',
      maxWords: 100,
      loading: false,
      error: null,
      words: [],
      selectedWord: null,
      relatedEntries: []
    };
  },
  computed: {
    hasData() {
      return this.words.length > 0;
    }
  },
  mounted() {
    this.fetchData();
    
    // Redimensionner le nuage de mots lors du redimensionnement de la fenêtre
    window.addEventListener('resize', this.debounce(this.renderWordCloud, 200));
  },
  beforeDestroy() {
    window.removeEventListener('resize', this.debounce(this.renderWordCloud, 200));
  },
  methods: {
    ...mapActions({
      fetchWordCloud: 'analysis/fetchWordCloud',
      searchEntries: 'journal/searchEntries'
    }),
    
    async fetchData() {
      this.loading = true;
      this.error = null;
      this.selectedWord = null;
      
      try {
        const response = await this.fetchWordCloud({
          period: this.selectedPeriod,
          maxWords: parseInt(this.maxWords)
        });
        
        this.words = response.map(word => ({
          text: word.text,
          value: word.count,
          frequency: word.frequency || 0,
          evolution: word.evolution || 0
        }));
        
        this.$nextTick(() => {
          this.renderWordCloud();
        });
      } catch (error) {
        console.error('Error fetching word cloud data:', error);
        this.error = 'Erreur lors du chargement des données du nuage de mots';
      } finally {
        this.loading = false;
      }
    },
    
    renderWordCloud() {
      if (!this.hasData || !this.$refs.wordCloudChart) return;
      
      // Nettoyer le conteneur
      const container = this.$refs.wordCloudChart;
      container.innerHTML = '';
      
      // Dimensions
      const width = container.clientWidth;
      const height = this.height;
      
      // Échelle de couleur basée sur la fréquence
      const color = d3.scaleLinear()
        .domain([0, d3.max(this.words, d => d.frequency)])
        .range(['#9CB7D8', '#1E40AF']);
      
      // Échelle de taille
      const size = d3.scaleLog()
        .domain([d3.min(this.words, d => d.value), d3.max(this.words, d => d.value)])
        .range([12, 60]);
      
      // Créer le layout du nuage de mots
      const layout = cloud()
        .size([width, height])
        .words(this.words.map(d => ({
          text: d.text,
          size: size(d.value),
          value: d.value,
          frequency: d.frequency,
          evolution: d.evolution
        })))
        .padding(5)
        .rotate(() => 0)
        .fontSize(d => d.size)
        .on('end', draw.bind(this));
      
      layout.start();
      
      // Fonction pour dessiner le nuage de mots
      function draw(words) {
        const svg = d3.select(container)
          .append('svg')
          .attr('width', layout.size()[0])
          .attr('height', layout.size()[1])
          .append('g')
          .attr('transform', `translate(${layout.size()[0] / 2},${layout.size()[1] / 2})`);
        
        svg.selectAll('text')
          .data(words)
          .enter()
          .append('text')
          .style('font-size', d => `${d.size}px`)
          .style('font-family', 'Impact')
          .style('fill', d => color(d.frequency))
          .attr('text-anchor', 'middle')
          .attr('transform', d => `translate(${d.x},${d.y})`)
          .text(d => d.text)
          .style('cursor', 'pointer')
          .on('mouseover', function(event, d) {
            d3.select(this)
              .transition()
              .duration(200)
              .style('font-size', `${d.size * 1.2}px`)
              .style('fill', '#1E3A8A');
          })
          .on('mouseout', function(event, d) {
            d3.select(this)
              .transition()
              .duration(200)
              .style('font-size', `${d.size}px`)
              .style('fill', color(d.frequency));
          })
          .on('click', (event, d) => {
            this.selectWord(d);
          });
      }
    },
    
    async selectWord(word) {
      this.selectedWord = {
        text: word.text,
        value: word.value,
        frequency: word.frequency,
        evolution: word.evolution
      };
      
      // Rechercher les entrées contenant ce mot
      this.relatedEntries = [];
      
      try {
        const entries = await this.searchEntries({
          query: word.text,
          limit: 5
        });
        
        this.relatedEntries = entries.map(entry => ({
          id: entry.id,
          title: entry.title,
          date: entry.date,
          excerpt: this.getExcerpt(entry.content, word.text)
        }));
      } catch (error) {
        console.error('Error searching entries:', error);
      }
    },
    
    getExcerpt(content, word, length = 150) {
      if (!content) return '';
      
      // Rechercher le mot dans le contenu
      const regex = new RegExp(`[^.!?]*\\b${word}\\b[^.!?]*[.!?]`, 'i');
      const match = content.match(regex);
      
      if (match) {
        let excerpt = match[0];
        
        // Limiter la longueur de l'extrait
        if (excerpt.length > length) {
          const wordIndex = excerpt.toLowerCase().indexOf(word.toLowerCase());
          const start = Math.max(0, wordIndex - length / 2);
          const end = Math.min(excerpt.length, wordIndex + word.length + length / 2);
          
          excerpt = (start > 0 ? '...' : '') + 
                    excerpt.substring(start, end) + 
                    (end < excerpt.length ? '...' : '');
        }
        
        return excerpt;
      }
      
      // Si le mot n'est pas trouvé, retourner un extrait du début
      return content.substring(0, length) + '...';
    },
    
    highlightWord(text, word) {
      if (!text || !word) return text;
      
      const regex = new RegExp(`\\b(${word})\\b`, 'gi');
      return text.replace(regex, '<span class="highlight">$1</span>');
    },
    
    getEvolutionClass(evolution) {
      if (evolution > 10) return 'text-green-600';
      if (evolution > 0) return 'text-green-500';
      if (evolution === 0) return 'text-gray-500';
      if (evolution > -10) return 'text-red-500';
      return 'text-red-600';
    },
    
    getEvolutionIcon(evolution) {
      if (evolution > 10) return 'fas fa-arrow-up';
      if (evolution > 0) return 'fas fa-arrow-up';
      if (evolution === 0) return 'fas fa-equals';
      if (evolution > -10) return 'fas fa-arrow-down';
      return 'fas fa-arrow-down';
    },
    
    formatDate(dateString) {
      if (!dateString) return '';
      
      const date = new Date(dateString);
      return date.toLocaleDateString();
    },
    
    debounce(func, wait) {
      let timeout;
      return function(...args) {
        const context = this;
        clearTimeout(timeout);
        timeout = setTimeout(() => func.apply(context, args), wait);
      };
    }
  }
};
</script>

<style scoped>
.word-cloud-container {
  @apply bg-white border border-gray-200 rounded-lg p-4 shadow-sm;
}

.chart-header {
  @apply flex justify-between items-center mb-4;
}

.chart-header h3 {
  @apply text-lg font-semibold text-gray-800;
}

.chart-controls {
  @apply flex items-center space-x-4;
}

.period-selector, .size-selector {
  @apply flex items-center;
}

.period-selector label, .size-selector label {
  @apply text-sm text-gray-600 mr-2;
}

.period-selector select, .size-selector select {
  @apply text-sm border border-gray-300 rounded-lg px-2 py-1 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent;
}

.chart-content {
  @apply relative;
}

.loading-state, .error-state, .empty-state {
  @apply flex flex-col items-center justify-center h-64 text-gray-500;
}

.loading-state i, .error-state i, .empty-state i {
  @apply text-3xl mb-2;
}

.error-state i {
  @apply text-red-500;
}

.retry-button {
  @apply mt-2 px-3 py-1 text-sm bg-blue-500 text-white rounded-lg hover:bg-blue-600 focus:outline-none;
}

.word-cloud-chart {
  @apply w-full bg-gray-50 rounded-lg overflow-hidden;
  min-height: 400px;
}

.word-details {
  @apply mt-4 p-4 border border-gray-200 rounded-lg;
}

.word-header {
  @apply flex justify-between items-center mb-3;
}

.word-header h4 {
  @apply text-lg font-semibold text-gray-800;
}

.word-count {
  @apply text-sm font-medium text-gray-500 bg-gray-100 px-2 py-1 rounded-full;
}

.word-stats {
  @apply grid grid-cols-2 gap-4 mb-4;
}

.stat-item {
  @apply p-3 bg-gray-50 rounded-lg;
}

.stat-label {
  @apply text-xs text-gray-500 mb-1;
}

.stat-value {
  @apply text-lg font-semibold;
}

.word-entries h5 {
  @apply text-sm font-medium text-gray-700 mb-2;
}

.loading-entries {
  @apply flex items-center text-sm text-gray-500;
}

.loading-entries i {
  @apply mr-2;
}

.entries-list {
  @apply space-y-2 max-h-60 overflow-y-auto;
}

.entry-item {
  @apply border-b border-gray-100 py-2 last:border-b-0;
}

.entry-item a {
  @apply block hover:bg-gray-50 rounded p-1 transition-colors;
}

.entry-title {
  @apply text-sm font-medium text-gray-800;
}

.entry-date {
  @apply text-xs text-gray-500;
}

.entry-excerpt {
  @apply text-xs text-gray-600 mt-1;
}

:deep(.highlight) {
  @apply bg-yellow-200 font-medium;
}
</style>
