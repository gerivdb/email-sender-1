<template>
  <div class="topic-trends-container">
    <div class="chart-header">
      <h3>Tendances des sujets</h3>
      <div class="chart-controls">
        <div class="period-selector">
          <label for="period">Période:</label>
          <select id="period" v-model="selectedPeriod" @change="fetchData">
            <option value="all">Tout</option>
            <option value="6months">6 derniers mois</option>
            <option value="year">Cette année</option>
          </select>
        </div>
      </div>
    </div>
    
    <div class="chart-content">
      <div v-if="loading" class="loading-state">
        <i class="fas fa-spinner fa-spin"></i>
        <p>Chargement des tendances...</p>
      </div>
      
      <div v-else-if="error" class="error-state">
        <i class="fas fa-exclamation-triangle"></i>
        <p>{{ error }}</p>
        <button @click="fetchData" class="retry-button">
          Réessayer
        </button>
      </div>
      
      <div v-else-if="!hasData" class="empty-state">
        <i class="fas fa-chart-area"></i>
        <p>Aucune donnée disponible pour cette période</p>
      </div>
      
      <div v-else class="topics-container">
        <div class="topics-list">
          <h4>Sujets détectés</h4>
          <div 
            v-for="topic in topics" 
            :key="topic.id"
            class="topic-item"
            :class="{ 'active': selectedTopicId === topic.id }"
            @click="selectTopic(topic.id)"
          >
            <div class="topic-header">
              <div class="topic-name">{{ topic.name }}</div>
              <div class="topic-score">{{ getTopicScore(topic.id) }}%</div>
            </div>
            <div class="topic-words">
              {{ topic.top_words.join(', ') }}
            </div>
          </div>
        </div>
        
        <div class="topic-details">
          <div v-if="selectedTopic" class="selected-topic">
            <h4>{{ selectedTopic.name }}</h4>
            
            <div class="topic-evolution">
              <h5>Évolution du sujet</h5>
              <div ref="evolutionChart" class="evolution-chart"></div>
            </div>
            
            <div class="topic-entries">
              <h5>Entrées associées</h5>
              <div v-if="topicEntries.length === 0" class="no-entries">
                Aucune entrée associée à ce sujet
              </div>
              <div v-else class="entries-list">
                <div 
                  v-for="entry in topicEntries" 
                  :key="entry.file"
                  class="entry-item"
                >
                  <router-link :to="{ name: 'JournalEntry', params: { filename: entry.file } }">
                    <div class="entry-title">{{ entry.title }}</div>
                    <div class="entry-date">{{ entry.date }}</div>
                  </router-link>
                </div>
              </div>
            </div>
          </div>
          
          <div v-else class="no-topic-selected">
            <i class="fas fa-hand-pointer"></i>
            <p>Sélectionnez un sujet pour voir les détails</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { mapActions } from 'vuex';
import * as d3 from 'd3';

export default {
  name: 'TopicTrends',
  props: {
    height: {
      type: Number,
      default: 500
    }
  },
  data() {
    return {
      selectedPeriod: 'all',
      loading: false,
      error: null,
      topics: [],
      evolution: {},
      entries: [],
      selectedTopicId: null
    };
  },
  computed: {
    hasData() {
      return this.topics.length > 0 && Object.keys(this.evolution).length > 0;
    },
    selectedTopic() {
      if (this.selectedTopicId === null) return null;
      return this.topics.find(topic => topic.id === this.selectedTopicId);
    },
    topicEntries() {
      if (this.selectedTopicId === null) return [];
      return this.entries.filter(entry => entry.dominant_topic === this.selectedTopicId);
    }
  },
  mounted() {
    this.fetchData();
  },
  methods: {
    ...mapActions({
      fetchTopicTrends: 'analysis/fetchTopicTrends'
    }),
    
    async fetchData() {
      this.loading = true;
      this.error = null;
      
      try {
        const response = await this.fetchTopicTrends(this.selectedPeriod);
        
        this.topics = response.topics || [];
        this.evolution = response.evolution || {};
        this.entries = response.entries || [];
        
        // Sélectionner le premier sujet par défaut
        if (this.topics.length > 0 && this.selectedTopicId === null) {
          this.selectTopic(this.topics[0].id);
        }
      } catch (error) {
        console.error('Error fetching topic trends:', error);
        this.error = 'Erreur lors du chargement des tendances des sujets';
      } finally {
        this.loading = false;
      }
    },
    
    selectTopic(topicId) {
      this.selectedTopicId = topicId;
      
      // Rendre le graphique d'évolution
      this.$nextTick(() => {
        this.renderEvolutionChart();
      });
    },
    
    getTopicScore(topicId) {
      // Calculer le score moyen du sujet sur toutes les périodes
      const months = Object.keys(this.evolution);
      if (months.length === 0) return 0;
      
      let totalScore = 0;
      let count = 0;
      
      months.forEach(month => {
        const monthData = this.evolution[month];
        const score = monthData[topicId] || 0;
        
        if (score > 0) {
          totalScore += score;
          count++;
        }
      });
      
      if (count === 0) return 0;
      return Math.round((totalScore / count) * 100);
    },
    
    renderEvolutionChart() {
      if (!this.selectedTopic || !this.$refs.evolutionChart) return;
      
      // Nettoyer le conteneur
      const container = this.$refs.evolutionChart;
      container.innerHTML = '';
      
      // Dimensions
      const margin = { top: 20, right: 30, bottom: 30, left: 40 };
      const width = container.clientWidth - margin.left - margin.right;
      const height = 200 - margin.top - margin.bottom;
      
      // Préparer les données
      const months = Object.keys(this.evolution).sort();
      const data = months.map(month => ({
        month,
        value: this.evolution[month][this.selectedTopicId] || 0
      }));
      
      // Créer les échelles
      const x = d3.scaleBand()
        .domain(months)
        .range([0, width])
        .padding(0.1);
      
      const y = d3.scaleLinear()
        .domain([0, d3.max(data, d => d.value) * 1.1])
        .nice()
        .range([height, 0]);
      
      // Créer le SVG
      const svg = d3.select(container)
        .append('svg')
        .attr('width', width + margin.left + margin.right)
        .attr('height', height + margin.top + margin.bottom)
        .append('g')
        .attr('transform', `translate(${margin.left},${margin.top})`);
      
      // Ajouter l'axe X
      svg.append('g')
        .attr('transform', `translate(0,${height})`)
        .call(d3.axisBottom(x))
        .selectAll('text')
        .style('text-anchor', 'end')
        .attr('dx', '-.8em')
        .attr('dy', '.15em')
        .attr('transform', 'rotate(-45)');
      
      // Ajouter l'axe Y
      svg.append('g')
        .call(d3.axisLeft(y).ticks(5).tickFormat(d => `${d * 100}%`));
      
      // Créer le gradient
      const gradient = svg.append('defs')
        .append('linearGradient')
        .attr('id', `gradient-${this.selectedTopicId}`)
        .attr('x1', '0%')
        .attr('y1', '0%')
        .attr('x2', '0%')
        .attr('y2', '100%');
      
      gradient.append('stop')
        .attr('offset', '0%')
        .attr('stop-color', '#3b82f6')
        .attr('stop-opacity', 0.8);
      
      gradient.append('stop')
        .attr('offset', '100%')
        .attr('stop-color', '#3b82f6')
        .attr('stop-opacity', 0.2);
      
      // Créer l'aire
      const area = d3.area()
        .x(d => x(d.month) + x.bandwidth() / 2)
        .y0(height)
        .y1(d => y(d.value))
        .curve(d3.curveMonotoneX);
      
      svg.append('path')
        .datum(data)
        .attr('fill', `url(#gradient-${this.selectedTopicId})`)
        .attr('d', area);
      
      // Créer la ligne
      const line = d3.line()
        .x(d => x(d.month) + x.bandwidth() / 2)
        .y(d => y(d.value))
        .curve(d3.curveMonotoneX);
      
      svg.append('path')
        .datum(data)
        .attr('fill', 'none')
        .attr('stroke', '#3b82f6')
        .attr('stroke-width', 2)
        .attr('d', line);
      
      // Ajouter les points
      svg.selectAll('.dot')
        .data(data)
        .enter()
        .append('circle')
        .attr('class', 'dot')
        .attr('cx', d => x(d.month) + x.bandwidth() / 2)
        .attr('cy', d => y(d.value))
        .attr('r', 4)
        .attr('fill', '#3b82f6')
        .attr('stroke', '#fff')
        .attr('stroke-width', 1.5)
        .on('mouseover', function(event, d) {
          d3.select(this)
            .transition()
            .duration(200)
            .attr('r', 6);
          
          // Afficher la tooltip
          svg.append('text')
            .attr('class', 'tooltip')
            .attr('x', x(d.month) + x.bandwidth() / 2)
            .attr('y', y(d.value) - 10)
            .attr('text-anchor', 'middle')
            .style('font-size', '12px')
            .style('fill', '#3b82f6')
            .text(`${(d.value * 100).toFixed(1)}%`);
        })
        .on('mouseout', function() {
          d3.select(this)
            .transition()
            .duration(200)
            .attr('r', 4);
          
          // Supprimer la tooltip
          svg.selectAll('.tooltip').remove();
        });
    }
  }
};
</script>

<style scoped>
.topic-trends-container {
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

.loading-state, .error-state, .empty-state, .no-topic-selected {
  @apply flex flex-col items-center justify-center h-64 text-gray-500;
}

.loading-state i, .error-state i, .empty-state i, .no-topic-selected i {
  @apply text-3xl mb-2;
}

.error-state i {
  @apply text-red-500;
}

.retry-button {
  @apply mt-2 px-3 py-1 text-sm bg-blue-500 text-white rounded-lg hover:bg-blue-600 focus:outline-none;
}

.topics-container {
  @apply flex flex-col md:flex-row gap-4;
  min-height: 400px;
}

.topics-list {
  @apply w-full md:w-1/3 border border-gray-200 rounded-lg p-4 overflow-auto;
  max-height: 500px;
}

.topics-list h4 {
  @apply text-base font-semibold text-gray-800 mb-3;
}

.topic-item {
  @apply border border-gray-200 rounded-lg p-3 mb-2 cursor-pointer hover:bg-gray-50 transition-colors;
}

.topic-item.active {
  @apply border-blue-500 bg-blue-50;
}

.topic-header {
  @apply flex justify-between items-center mb-1;
}

.topic-name {
  @apply font-medium text-gray-800;
}

.topic-score {
  @apply text-sm font-semibold text-blue-600 bg-blue-100 px-2 py-0.5 rounded-full;
}

.topic-words {
  @apply text-sm text-gray-600 truncate;
}

.topic-details {
  @apply w-full md:w-2/3 border border-gray-200 rounded-lg p-4;
}

.selected-topic h4 {
  @apply text-base font-semibold text-gray-800 mb-3;
}

.topic-evolution, .topic-entries {
  @apply mb-4;
}

.topic-evolution h5, .topic-entries h5 {
  @apply text-sm font-medium text-gray-700 mb-2;
}

.evolution-chart {
  @apply w-full h-48 bg-gray-50 rounded-lg overflow-hidden;
}

.no-entries {
  @apply text-sm text-gray-500 italic;
}

.entries-list {
  @apply max-h-48 overflow-y-auto;
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
</style>
