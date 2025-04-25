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
      </div>
    </div>
    
    <div class="chart-content">
      <div v-if="loading" class="loading-state">
        <i class="fas fa-spinner fa-spin"></i>
        <p>Chargement du nuage de mots...</p>
      </div>
      
      <div v-else-if="error" class="error-state">
        <i class="fas fa-exclamation-triangle"></i>
        <p>{{ error }}</p>
        <button @click="fetchData" class="retry-button">
          Réessayer
        </button>
      </div>
      
      <div v-else-if="!words.length" class="empty-state">
        <i class="fas fa-cloud"></i>
        <p>Aucune donnée disponible pour cette période</p>
      </div>
      
      <div v-else ref="cloudContainer" class="cloud-container">
        <!-- Le nuage de mots sera rendu ici -->
      </div>
    </div>
  </div>
</template>

<script>
import { mapActions } from 'vuex';
import * as d3 from 'd3';
import cloud from 'd3-cloud';

export default {
  name: 'WordCloud',
  props: {
    period: {
      type: String,
      default: 'all'
    },
    height: {
      type: Number,
      default: 400
    }
  },
  data() {
    return {
      selectedPeriod: this.period,
      words: [],
      loading: false,
      error: null
    };
  },
  mounted() {
    this.fetchData();
    
    // Redimensionner le nuage de mots lors du redimensionnement de la fenêtre
    window.addEventListener('resize', this.debounce(this.renderCloud, 300));
  },
  beforeUnmount() {
    window.removeEventListener('resize', this.debounce(this.renderCloud, 300));
  },
  methods: {
    ...mapActions({
      fetchWordCloud: 'analysis/fetchWordCloud'
    }),
    
    async fetchData() {
      this.loading = true;
      this.error = null;
      
      try {
        const response = await this.fetchWordCloud(this.selectedPeriod);
        this.words = response.words || [];
        
        // Rendre le nuage de mots
        this.$nextTick(() => {
          this.renderCloud();
        });
      } catch (error) {
        console.error('Error fetching word cloud data:', error);
        this.error = 'Erreur lors du chargement des données';
      } finally {
        this.loading = false;
      }
    },
    
    renderCloud() {
      if (!this.words.length || !this.$refs.cloudContainer) return;
      
      // Nettoyer le conteneur
      const container = this.$refs.cloudContainer;
      container.innerHTML = '';
      
      // Dimensions
      const width = container.clientWidth;
      const height = this.height;
      
      // Échelles de couleur
      const color = d3.scaleOrdinal(d3.schemeCategory10);
      
      // Créer le layout du nuage
      const layout = cloud()
        .size([width, height])
        .words(this.words.map(d => ({
          text: d.text,
          size: this.calculateFontSize(d.value),
          value: d.value
        })))
        .padding(5)
        .rotate(() => 0)
        .font('Inter')
        .fontSize(d => d.size)
        .on('end', words => {
          // Créer le SVG
          const svg = d3.select(container)
            .append('svg')
            .attr('width', width)
            .attr('height', height)
            .append('g')
            .attr('transform', `translate(${width / 2},${height / 2})`);
          
          // Ajouter les mots
          svg.selectAll('text')
            .data(words)
            .enter()
            .append('text')
            .style('font-size', d => `${d.size}px`)
            .style('font-family', 'Inter, sans-serif')
            .style('fill', (d, i) => color(i))
            .attr('text-anchor', 'middle')
            .attr('transform', d => `translate(${d.x},${d.y})`)
            .text(d => d.text)
            .on('mouseover', function(event, d) {
              d3.select(this)
                .transition()
                .duration(200)
                .style('font-size', `${d.size * 1.2}px`)
                .style('font-weight', 'bold');
              
              // Afficher la valeur
              svg.append('text')
                .attr('class', 'tooltip')
                .attr('x', d.x)
                .attr('y', d.y + d.size / 2 + 10)
                .attr('text-anchor', 'middle')
                .style('font-size', '12px')
                .style('fill', '#666')
                .text(`${d.value} occurrences`);
            })
            .on('mouseout', function(event, d) {
              d3.select(this)
                .transition()
                .duration(200)
                .style('font-size', `${d.size}px`)
                .style('font-weight', 'normal');
              
              // Supprimer la tooltip
              svg.selectAll('.tooltip').remove();
            });
        });
      
      // Générer le nuage
      layout.start();
    },
    
    calculateFontSize(value) {
      // Trouver la valeur maximale
      const maxValue = Math.max(...this.words.map(d => d.value));
      
      // Échelle logarithmique pour les tailles de police
      const minFontSize = 10;
      const maxFontSize = 60;
      
      return minFontSize + (maxFontSize - minFontSize) * Math.log(value + 1) / Math.log(maxValue + 1);
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
  @apply flex items-center;
}

.period-selector {
  @apply flex items-center;
}

.period-selector label {
  @apply text-sm text-gray-600 mr-2;
}

.period-selector select {
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

.cloud-container {
  @apply w-full overflow-hidden;
}
</style>
