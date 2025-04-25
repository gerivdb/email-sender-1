<template>
  <div class="sentiment-analysis-container">
    <div class="chart-header">
      <h3>Analyse de sentiment</h3>
      <div class="chart-controls">
        <div class="view-selector">
          <button 
            @click="activeView = 'evolution'" 
            :class="{ active: activeView === 'evolution' }"
            class="view-button"
          >
            Évolution
          </button>
          <button 
            @click="activeView = 'sections'" 
            :class="{ active: activeView === 'sections' }"
            class="view-button"
          >
            Sections
          </button>
        </div>
      </div>
    </div>
    
    <div class="chart-content">
      <div v-if="loading" class="loading-state">
        <i class="fas fa-spinner fa-spin"></i>
        <p>Chargement de l'analyse...</p>
      </div>
      
      <div v-else-if="error" class="error-state">
        <i class="fas fa-exclamation-triangle"></i>
        <p>{{ error }}</p>
        <button @click="fetchData" class="retry-button">
          Réessayer
        </button>
      </div>
      
      <div v-else-if="!hasData" class="empty-state">
        <i class="fas fa-chart-line"></i>
        <p>Aucune donnée d'analyse de sentiment disponible</p>
      </div>
      
      <div v-else>
        <!-- Évolution du sentiment -->
        <div v-if="activeView === 'evolution'" class="sentiment-evolution">
          <div class="chart-description">
            <p>
              Cette visualisation montre l'évolution du sentiment dans vos entrées de journal au fil du temps.
              <span class="text-blue-600">La polarité</span> indique si le sentiment est positif (valeurs positives) ou négatif (valeurs négatives).
              <span class="text-green-600">La subjectivité</span> indique si le contenu est objectif (valeurs proches de 0) ou subjectif (valeurs proches de 1).
            </p>
          </div>
          
          <div ref="evolutionChart" class="evolution-chart"></div>
          
          <div class="sentiment-stats">
            <div class="stat-card">
              <div class="stat-title">Polarité moyenne</div>
              <div class="stat-value" :class="getColorClass(averagePolarityScore)">
                {{ averagePolarityScore.toFixed(2) }}
              </div>
              <div class="stat-description">
                {{ getPolarityDescription(averagePolarityScore) }}
              </div>
            </div>
            
            <div class="stat-card">
              <div class="stat-title">Subjectivité moyenne</div>
              <div class="stat-value text-green-600">
                {{ averageSubjectivityScore.toFixed(2) }}
              </div>
              <div class="stat-description">
                {{ getSubjectivityDescription(averageSubjectivityScore) }}
              </div>
            </div>
            
            <div class="stat-card">
              <div class="stat-title">Tendance récente</div>
              <div class="stat-value" :class="getColorClass(recentTrend)">
                <i :class="getTrendIcon(recentTrend)"></i>
                {{ recentTrend > 0 ? '+' : '' }}{{ recentTrend.toFixed(2) }}
              </div>
              <div class="stat-description">
                {{ getTrendDescription(recentTrend) }}
              </div>
            </div>
          </div>
        </div>
        
        <!-- Sentiment par section -->
        <div v-else-if="activeView === 'sections'" class="sentiment-sections">
          <div class="chart-description">
            <p>
              Cette visualisation montre le sentiment moyen par section de vos entrées de journal.
              Cela vous permet d'identifier les sections qui contiennent généralement un contenu plus positif ou négatif.
            </p>
          </div>
          
          <div ref="sectionsChart" class="sections-chart"></div>
          
          <div class="sections-list">
            <div 
              v-for="(sentiment, section) in sectionSentiments" 
              :key="section"
              class="section-item"
            >
              <div class="section-header">
                <div class="section-name">{{ section }}</div>
                <div class="section-count">{{ sentiment.count }} entrées</div>
              </div>
              
              <div class="sentiment-bars">
                <div class="sentiment-bar">
                  <div class="bar-label">Polarité</div>
                  <div class="bar-container">
                    <div 
                      class="bar-value" 
                      :class="getColorClass(sentiment.polarity)"
                      :style="{ width: `${Math.abs(sentiment.polarity * 50) + 50}%`, marginLeft: sentiment.polarity < 0 ? 'auto' : '50%' }"
                    ></div>
                    <div class="bar-center-line"></div>
                  </div>
                  <div class="bar-score" :class="getColorClass(sentiment.polarity)">
                    {{ sentiment.polarity.toFixed(2) }}
                  </div>
                </div>
                
                <div class="sentiment-bar">
                  <div class="bar-label">Subjectivité</div>
                  <div class="bar-container">
                    <div 
                      class="bar-value bg-green-500"
                      :style="{ width: `${sentiment.subjectivity * 100}%` }"
                    ></div>
                  </div>
                  <div class="bar-score text-green-600">
                    {{ sentiment.subjectivity.toFixed(2) }}
                  </div>
                </div>
              </div>
            </div>
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
  name: 'SentimentAnalysis',
  data() {
    return {
      activeView: 'evolution',
      loading: false,
      error: null,
      sentimentEvolution: {
        dates: [],
        polarity: [],
        subjectivity: []
      },
      sectionSentiments: {}
    };
  },
  computed: {
    hasData() {
      return this.sentimentEvolution.dates.length > 0 || Object.keys(this.sectionSentiments).length > 0;
    },
    averagePolarityScore() {
      if (this.sentimentEvolution.polarity.length === 0) return 0;
      const sum = this.sentimentEvolution.polarity.reduce((a, b) => a + b, 0);
      return sum / this.sentimentEvolution.polarity.length;
    },
    averageSubjectivityScore() {
      if (this.sentimentEvolution.subjectivity.length === 0) return 0;
      const sum = this.sentimentEvolution.subjectivity.reduce((a, b) => a + b, 0);
      return sum / this.sentimentEvolution.subjectivity.length;
    },
    recentTrend() {
      const polarity = this.sentimentEvolution.polarity;
      if (polarity.length < 2) return 0;
      
      // Calculer la tendance sur les 3 dernières entrées (ou moins si pas assez de données)
      const recentCount = Math.min(3, polarity.length);
      const recentAvg = polarity.slice(-recentCount).reduce((a, b) => a + b, 0) / recentCount;
      const previousAvg = polarity.slice(-recentCount * 2, -recentCount).reduce((a, b) => a + b, 0) / Math.min(recentCount, polarity.length - recentCount);
      
      return recentAvg - previousAvg;
    }
  },
  mounted() {
    this.fetchData();
  },
  watch: {
    activeView() {
      this.$nextTick(() => {
        if (this.activeView === 'evolution') {
          this.renderEvolutionChart();
        } else if (this.activeView === 'sections') {
          this.renderSectionsChart();
        }
      });
    }
  },
  methods: {
    ...mapActions({
      fetchSentimentEvolution: 'analysis/fetchSentimentEvolution',
      fetchSentimentBySections: 'analysis/fetchSentimentBySections'
    }),
    
    async fetchData() {
      this.loading = true;
      this.error = null;
      
      try {
        // Récupérer l'évolution du sentiment
        const evolutionResponse = await this.fetchSentimentEvolution();
        this.sentimentEvolution = evolutionResponse;
        
        // Récupérer le sentiment par section
        const sectionsResponse = await this.fetchSentimentBySections();
        this.sectionSentiments = sectionsResponse;
        
        // Rendre le graphique actif
        this.$nextTick(() => {
          if (this.activeView === 'evolution') {
            this.renderEvolutionChart();
          } else if (this.activeView === 'sections') {
            this.renderSectionsChart();
          }
        });
      } catch (error) {
        console.error('Error fetching sentiment analysis:', error);
        this.error = 'Erreur lors du chargement de l\'analyse de sentiment';
      } finally {
        this.loading = false;
      }
    },
    
    renderEvolutionChart() {
      if (!this.$refs.evolutionChart || !this.hasData) return;
      
      // Nettoyer le conteneur
      const container = this.$refs.evolutionChart;
      container.innerHTML = '';
      
      // Dimensions
      const margin = { top: 20, right: 50, bottom: 30, left: 50 };
      const width = container.clientWidth - margin.left - margin.right;
      const height = 300 - margin.top - margin.bottom;
      
      // Préparer les données
      const data = this.sentimentEvolution.dates.map((date, i) => ({
        date,
        polarity: this.sentimentEvolution.polarity[i],
        subjectivity: this.sentimentEvolution.subjectivity[i]
      }));
      
      // Créer les échelles
      const x = d3.scaleBand()
        .domain(data.map(d => d.date))
        .range([0, width])
        .padding(0.1);
      
      const y = d3.scaleLinear()
        .domain([-1, 1])
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
        .attr('transform', `translate(0,${height / 2})`)
        .call(d3.axisBottom(x))
        .selectAll('text')
        .style('text-anchor', 'end')
        .attr('dx', '-.8em')
        .attr('dy', '.15em')
        .attr('transform', 'rotate(-45)');
      
      // Ajouter l'axe Y
      svg.append('g')
        .call(d3.axisLeft(y).ticks(5));
      
      // Ajouter la ligne horizontale à y=0
      svg.append('line')
        .attr('x1', 0)
        .attr('y1', y(0))
        .attr('x2', width)
        .attr('y2', y(0))
        .attr('stroke', '#ccc')
        .attr('stroke-width', 1)
        .attr('stroke-dasharray', '3,3');
      
      // Créer la ligne de polarité
      const polarityLine = d3.line()
        .x(d => x(d.date) + x.bandwidth() / 2)
        .y(d => y(d.polarity))
        .curve(d3.curveMonotoneX);
      
      svg.append('path')
        .datum(data)
        .attr('fill', 'none')
        .attr('stroke', '#3b82f6')
        .attr('stroke-width', 2)
        .attr('d', polarityLine);
      
      // Créer la ligne de subjectivité
      const subjectivityLine = d3.line()
        .x(d => x(d.date) + x.bandwidth() / 2)
        .y(d => y(d.subjectivity))
        .curve(d3.curveMonotoneX);
      
      svg.append('path')
        .datum(data)
        .attr('fill', 'none')
        .attr('stroke', '#10b981')
        .attr('stroke-width', 2)
        .attr('d', subjectivityLine);
      
      // Ajouter les points de polarité
      svg.selectAll('.polarity-dot')
        .data(data)
        .enter()
        .append('circle')
        .attr('class', 'polarity-dot')
        .attr('cx', d => x(d.date) + x.bandwidth() / 2)
        .attr('cy', d => y(d.polarity))
        .attr('r', 4)
        .attr('fill', d => d.polarity >= 0 ? '#3b82f6' : '#ef4444')
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
            .attr('x', x(d.date) + x.bandwidth() / 2)
            .attr('y', y(d.polarity) - 10)
            .attr('text-anchor', 'middle')
            .style('font-size', '12px')
            .style('fill', d.polarity >= 0 ? '#3b82f6' : '#ef4444')
            .text(`Polarité: ${d.polarity.toFixed(2)}`);
        })
        .on('mouseout', function() {
          d3.select(this)
            .transition()
            .duration(200)
            .attr('r', 4);
          
          // Supprimer la tooltip
          svg.selectAll('.tooltip').remove();
        });
      
      // Ajouter les points de subjectivité
      svg.selectAll('.subjectivity-dot')
        .data(data)
        .enter()
        .append('circle')
        .attr('class', 'subjectivity-dot')
        .attr('cx', d => x(d.date) + x.bandwidth() / 2)
        .attr('cy', d => y(d.subjectivity))
        .attr('r', 4)
        .attr('fill', '#10b981')
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
            .attr('x', x(d.date) + x.bandwidth() / 2)
            .attr('y', y(d.subjectivity) - 10)
            .attr('text-anchor', 'middle')
            .style('font-size', '12px')
            .style('fill', '#10b981')
            .text(`Subjectivité: ${d.subjectivity.toFixed(2)}`);
        })
        .on('mouseout', function() {
          d3.select(this)
            .transition()
            .duration(200)
            .attr('r', 4);
          
          // Supprimer la tooltip
          svg.selectAll('.tooltip').remove();
        });
      
      // Ajouter la légende
      const legend = svg.append('g')
        .attr('transform', `translate(${width - 100}, 0)`);
      
      // Polarité
      legend.append('circle')
        .attr('cx', 0)
        .attr('cy', 0)
        .attr('r', 4)
        .attr('fill', '#3b82f6');
      
      legend.append('text')
        .attr('x', 10)
        .attr('y', 4)
        .style('font-size', '12px')
        .text('Polarité');
      
      // Subjectivité
      legend.append('circle')
        .attr('cx', 0)
        .attr('cy', 20)
        .attr('r', 4)
        .attr('fill', '#10b981');
      
      legend.append('text')
        .attr('x', 10)
        .attr('y', 24)
        .style('font-size', '12px')
        .text('Subjectivité');
    },
    
    renderSectionsChart() {
      if (!this.$refs.sectionsChart || !this.hasData) return;
      
      // Nettoyer le conteneur
      const container = this.$refs.sectionsChart;
      container.innerHTML = '';
      
      // Dimensions
      const margin = { top: 20, right: 30, bottom: 40, left: 150 };
      const width = container.clientWidth - margin.left - margin.right;
      const height = 300 - margin.top - margin.bottom;
      
      // Préparer les données
      const data = Object.entries(this.sectionSentiments).map(([section, sentiment]) => ({
        section,
        polarity: sentiment.polarity,
        subjectivity: sentiment.subjectivity,
        count: sentiment.count
      }));
      
      // Trier les données par polarité
      data.sort((a, b) => b.polarity - a.polarity);
      
      // Limiter le nombre de sections affichées
      const maxSections = 10;
      const displayData = data.slice(0, maxSections);
      
      // Créer les échelles
      const y = d3.scaleBand()
        .domain(displayData.map(d => d.section))
        .range([0, height])
        .padding(0.1);
      
      const x = d3.scaleLinear()
        .domain([-1, 1])
        .range([0, width]);
      
      // Créer le SVG
      const svg = d3.select(container)
        .append('svg')
        .attr('width', width + margin.left + margin.right)
        .attr('height', height + margin.top + margin.bottom)
        .append('g')
        .attr('transform', `translate(${margin.left},${margin.top})`);
      
      // Ajouter l'axe Y
      svg.append('g')
        .call(d3.axisLeft(y));
      
      // Ajouter l'axe X
      svg.append('g')
        .attr('transform', `translate(0,${height})`)
        .call(d3.axisBottom(x).ticks(5));
      
      // Ajouter la ligne verticale à x=0
      svg.append('line')
        .attr('x1', x(0))
        .attr('y1', 0)
        .attr('x2', x(0))
        .attr('y2', height)
        .attr('stroke', '#ccc')
        .attr('stroke-width', 1)
        .attr('stroke-dasharray', '3,3');
      
      // Ajouter les barres de polarité
      svg.selectAll('.polarity-bar')
        .data(displayData)
        .enter()
        .append('rect')
        .attr('class', 'polarity-bar')
        .attr('y', d => y(d.section))
        .attr('x', d => d.polarity < 0 ? x(0) - Math.abs(x(d.polarity) - x(0)) : x(0))
        .attr('width', d => Math.abs(x(d.polarity) - x(0)))
        .attr('height', y.bandwidth() / 2)
        .attr('fill', d => d.polarity >= 0 ? '#3b82f6' : '#ef4444')
        .attr('opacity', 0.7)
        .on('mouseover', function(event, d) {
          d3.select(this)
            .transition()
            .duration(200)
            .attr('opacity', 1);
          
          // Afficher la tooltip
          svg.append('text')
            .attr('class', 'tooltip')
            .attr('x', d.polarity < 0 ? x(d.polarity) - 5 : x(d.polarity) + 5)
            .attr('y', y(d.section) + y.bandwidth() / 4)
            .attr('text-anchor', d.polarity < 0 ? 'end' : 'start')
            .style('font-size', '12px')
            .style('fill', d.polarity >= 0 ? '#3b82f6' : '#ef4444')
            .text(`Polarité: ${d.polarity.toFixed(2)}`);
        })
        .on('mouseout', function() {
          d3.select(this)
            .transition()
            .duration(200)
            .attr('opacity', 0.7);
          
          // Supprimer la tooltip
          svg.selectAll('.tooltip').remove();
        });
      
      // Ajouter les barres de subjectivité
      svg.selectAll('.subjectivity-bar')
        .data(displayData)
        .enter()
        .append('rect')
        .attr('class', 'subjectivity-bar')
        .attr('y', d => y(d.section) + y.bandwidth() / 2)
        .attr('x', x(0))
        .attr('width', d => x(d.subjectivity) - x(0))
        .attr('height', y.bandwidth() / 2)
        .attr('fill', '#10b981')
        .attr('opacity', 0.7)
        .on('mouseover', function(event, d) {
          d3.select(this)
            .transition()
            .duration(200)
            .attr('opacity', 1);
          
          // Afficher la tooltip
          svg.append('text')
            .attr('class', 'tooltip')
            .attr('x', x(d.subjectivity) + 5)
            .attr('y', y(d.section) + y.bandwidth() * 3/4)
            .attr('text-anchor', 'start')
            .style('font-size', '12px')
            .style('fill', '#10b981')
            .text(`Subjectivité: ${d.subjectivity.toFixed(2)}`);
        })
        .on('mouseout', function() {
          d3.select(this)
            .transition()
            .duration(200)
            .attr('opacity', 0.7);
          
          // Supprimer la tooltip
          svg.selectAll('.tooltip').remove();
        });
      
      // Ajouter la légende
      const legend = svg.append('g')
        .attr('transform', `translate(${width - 120}, -10)`);
      
      // Polarité
      legend.append('rect')
        .attr('x', 0)
        .attr('y', 0)
        .attr('width', 12)
        .attr('height', 12)
        .attr('fill', '#3b82f6');
      
      legend.append('text')
        .attr('x', 16)
        .attr('y', 10)
        .style('font-size', '12px')
        .text('Polarité');
      
      // Subjectivité
      legend.append('rect')
        .attr('x', 0)
        .attr('y', 20)
        .attr('width', 12)
        .attr('height', 12)
        .attr('fill', '#10b981');
      
      legend.append('text')
        .attr('x', 16)
        .attr('y', 30)
        .style('font-size', '12px')
        .text('Subjectivité');
    },
    
    getColorClass(score) {
      if (score >= 0.5) return 'text-green-600';
      if (score >= 0.1) return 'text-blue-600';
      if (score >= -0.1) return 'text-gray-600';
      if (score >= -0.5) return 'text-yellow-600';
      return 'text-red-600';
    },
    
    getPolarityDescription(score) {
      if (score >= 0.5) return 'Très positif';
      if (score >= 0.1) return 'Positif';
      if (score >= -0.1) return 'Neutre';
      if (score >= -0.5) return 'Négatif';
      return 'Très négatif';
    },
    
    getSubjectivityDescription(score) {
      if (score >= 0.75) return 'Très subjectif';
      if (score >= 0.5) return 'Subjectif';
      if (score >= 0.25) return 'Modérément objectif';
      return 'Très objectif';
    },
    
    getTrendIcon(trend) {
      if (trend > 0.1) return 'fas fa-arrow-up';
      if (trend < -0.1) return 'fas fa-arrow-down';
      return 'fas fa-equals';
    },
    
    getTrendDescription(trend) {
      if (trend > 0.3) return 'Amélioration significative';
      if (trend > 0.1) return 'Légère amélioration';
      if (trend > -0.1) return 'Stable';
      if (trend > -0.3) return 'Légère détérioration';
      return 'Détérioration significative';
    }
  }
};
</script>

<style scoped>
.sentiment-analysis-container {
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

.view-selector {
  @apply flex items-center border border-gray-200 rounded-lg overflow-hidden;
}

.view-button {
  @apply px-3 py-1 text-sm text-gray-600 hover:bg-gray-50 focus:outline-none;
}

.view-button.active {
  @apply bg-blue-500 text-white hover:bg-blue-600;
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

.chart-description {
  @apply text-sm text-gray-600 mb-4;
}

.evolution-chart, .sections-chart {
  @apply w-full h-72 bg-gray-50 rounded-lg overflow-hidden mb-4;
}

.sentiment-stats {
  @apply grid grid-cols-1 md:grid-cols-3 gap-4;
}

.stat-card {
  @apply border border-gray-200 rounded-lg p-3 text-center;
}

.stat-title {
  @apply text-sm text-gray-600 mb-1;
}

.stat-value {
  @apply text-xl font-semibold mb-1;
}

.stat-description {
  @apply text-xs text-gray-500;
}

.sections-list {
  @apply mt-4 max-h-96 overflow-y-auto;
}

.section-item {
  @apply border border-gray-200 rounded-lg p-3 mb-2;
}

.section-header {
  @apply flex justify-between items-center mb-2;
}

.section-name {
  @apply font-medium text-gray-800;
}

.section-count {
  @apply text-xs text-gray-500 bg-gray-100 px-2 py-0.5 rounded-full;
}

.sentiment-bars {
  @apply space-y-2;
}

.sentiment-bar {
  @apply flex items-center;
}

.bar-label {
  @apply text-xs text-gray-600 w-20;
}

.bar-container {
  @apply flex-1 h-4 bg-gray-100 rounded-full overflow-hidden relative;
}

.bar-value {
  @apply h-full rounded-full;
}

.bar-center-line {
  @apply absolute top-0 bottom-0 w-px bg-gray-300 left-1/2 transform -translate-x-1/2;
}

.bar-score {
  @apply text-xs font-medium ml-2 w-10 text-right;
}
</style>
