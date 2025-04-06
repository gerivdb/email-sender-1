<template>
  <div class="topic-trends-container">
    <div class="controls">
      <div class="view-selector">
        <button 
          v-for="view in views" 
          :key="view.value"
          :class="{ active: selectedView === view.value }"
          @click="selectedView = view.value"
        >
          {{ view.label }}
        </button>
      </div>
      
      <div class="display-options">
        <label>
          <input type="checkbox" v-model="stackedView" />
          Vue empilée
        </label>
        <label>
          <input type="checkbox" v-model="showPercentage" />
          Pourcentages
        </label>
      </div>
    </div>
    
    <div class="visualization" ref="visualization"></div>
    
    <div v-if="selectedTopic" class="topic-details">
      <h3>{{ selectedTopic.name }}</h3>
      <p>{{ selectedTopic.description }}</p>
      <div v-if="selectedTopic.entries && selectedTopic.entries.length > 0">
        <p>Entrées récentes:</p>
        <ul>
          <li v-for="entry in selectedTopic.entries.slice(0, 5)" :key="entry.file">
            <a @click.prevent="$emit('view-entry', entry.file)" href="#">
              {{ entry.title }}
            </a>
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>

<script>
import * as d3 from 'd3';
import { mapGetters } from 'vuex';

export default {
  name: 'TopicTrendsViz',
  props: {
    width: {
      type: Number,
      default: 800
    },
    height: {
      type: Number,
      default: 400
    }
  },
  data() {
    return {
      views: [
        { label: 'Système', value: 'system' },
        { label: 'Code', value: 'code' },
        { label: 'Erreurs', value: 'errors' },
        { label: 'Workflows', value: 'workflow' },
        { label: 'Musique', value: 'music' }
      ],
      selectedView: 'system',
      stackedView: false,
      showPercentage: false,
      selectedTopic: null,
      svg: null,
      xScale: null,
      yScale: null,
      colorScale: d3.scaleOrdinal(d3.schemeCategory10),
      tooltip: null
    };
  },
  computed: {
    ...mapGetters('analysis', ['topicTrendsData']),
    
    currentViewData() {
      if (!this.topicTrendsData || !this.topicTrendsData[this.selectedView]) {
        return null;
      }
      
      return this.topicTrendsData[this.selectedView];
    }
  },
  watch: {
    selectedView() {
      this.updateVisualization();
    },
    stackedView() {
      this.updateVisualization();
    },
    showPercentage() {
      this.updateVisualization();
    },
    topicTrendsData() {
      this.updateVisualization();
    }
  },
  mounted() {
    this.initVisualization();
    this.fetchData();
  },
  methods: {
    async fetchData() {
      if (!this.topicTrendsData) {
        await this.$store.dispatch('analysis/fetchTopicTrends');
      }
      
      this.updateVisualization();
    },
    
    initVisualization() {
      const container = this.$refs.visualization;
      
      // Créer le SVG
      this.svg = d3.select(container)
        .append('svg')
        .attr('width', this.width)
        .attr('height', this.height);
      
      // Ajouter un groupe pour le graphique avec des marges
      const margin = { top: 20, right: 50, bottom: 50, left: 50 };
      const width = this.width - margin.left - margin.right;
      const height = this.height - margin.top - margin.bottom;
      
      const g = this.svg.append('g')
        .attr('transform', `translate(${margin.left},${margin.top})`);
      
      // Créer les échelles
      this.xScale = d3.scaleTime()
        .range([0, width]);
      
      this.yScale = d3.scaleLinear()
        .range([height, 0]);
      
      // Ajouter les axes
      g.append('g')
        .attr('class', 'x-axis')
        .attr('transform', `translate(0,${height})`);
      
      g.append('g')
        .attr('class', 'y-axis');
      
      // Ajouter un titre pour l'axe Y
      g.append('text')
        .attr('class', 'y-axis-label')
        .attr('transform', 'rotate(-90)')
        .attr('y', -40)
        .attr('x', -height / 2)
        .attr('text-anchor', 'middle')
        .text('Nombre d\'entrées');
      
      // Ajouter un groupe pour les barres
      g.append('g')
        .attr('class', 'bars');
      
      // Créer un tooltip
      this.tooltip = d3.select(container)
        .append('div')
        .attr('class', 'tooltip')
        .style('opacity', 0)
        .style('position', 'absolute')
        .style('background-color', 'white')
        .style('border', '1px solid #ddd')
        .style('border-radius', '4px')
        .style('padding', '8px')
        .style('pointer-events', 'none');
    },
    
    updateVisualization() {
      if (!this.currentViewData) return;
      
      const margin = { top: 20, right: 50, bottom: 50, left: 50 };
      const width = this.width - margin.left - margin.right;
      const height = this.height - margin.top - margin.bottom;
      
      // Préparer les données
      const data = this.prepareData();
      
      // Mettre à jour les échelles
      this.xScale.domain(d3.extent(data.months, d => new Date(d)));
      
      const yMax = this.stackedView
        ? d3.max(data.months.map(month => {
            return Object.values(data.topicsByMonth[month]).reduce((sum, val) => sum + val, 0);
          }))
        : d3.max(data.topics.map(topic => 
            d3.max(data.months.map(month => data.topicsByMonth[month][topic] || 0))
          ));
      
      this.yScale.domain([0, yMax * 1.1]);
      
      // Mettre à jour les axes
      const xAxis = d3.axisBottom(this.xScale)
        .ticks(Math.min(data.months.length, 10))
        .tickFormat(d3.timeFormat('%Y-%m'));
      
      const yAxis = d3.axisLeft(this.yScale)
        .ticks(5)
        .tickFormat(d => this.showPercentage ? `${(d * 100).toFixed(0)}%` : d);
      
      this.svg.select('.x-axis')
        .transition()
        .duration(500)
        .call(xAxis);
      
      this.svg.select('.y-axis')
        .transition()
        .duration(500)
        .call(yAxis);
      
      // Mettre à jour le titre de l'axe Y
      this.svg.select('.y-axis-label')
        .text(this.showPercentage ? 'Pourcentage d\'entrées' : 'Nombre d\'entrées');
      
      // Largeur des barres
      const barWidth = width / data.months.length * 0.8;
      
      if (this.stackedView) {
        // Vue empilée
        this.renderStackedBars(data, barWidth);
      } else {
        // Vue groupée
        this.renderGroupedBars(data, barWidth);
      }
    },
    
    renderStackedBars(data, barWidth) {
      const stack = d3.stack()
        .keys(data.topics)
        .value((d, key) => d[key] || 0);
      
      const stackedData = stack(data.months.map(month => data.topicsByMonth[month]));
      
      // Créer les groupes de barres
      const barGroups = this.svg.select('.bars')
        .selectAll('.bar-group')
        .data(stackedData);
      
      barGroups.exit().remove();
      
      const newBarGroups = barGroups.enter()
        .append('g')
        .attr('class', 'bar-group')
        .attr('fill', (d, i) => this.colorScale(data.topics[i]));
      
      const allBarGroups = newBarGroups.merge(barGroups);
      
      // Créer les barres
      const bars = allBarGroups.selectAll('rect')
        .data(d => d.map((value, i) => ({
          topic: d.key,
          month: data.months[i],
          y0: value[0],
          y1: value[1],
          total: Object.values(data.topicsByMonth[data.months[i]]).reduce((sum, val) => sum + val, 0)
        })));
      
      bars.exit().remove();
      
      bars.enter()
        .append('rect')
        .merge(bars)
        .attr('x', d => this.xScale(new Date(d.month)) - barWidth / 2)
        .attr('y', d => this.yScale(d.y1))
        .attr('height', d => this.yScale(d.y0) - this.yScale(d.y1))
        .attr('width', barWidth)
        .style('cursor', 'pointer')
        .on('mouseover', (event, d) => {
          const value = d.y1 - d.y0;
          const percentage = (value / d.total * 100).toFixed(1);
          
          this.tooltip
            .style('opacity', 1)
            .html(`
              <strong>${d.topic}</strong><br>
              Mois: ${d3.timeFormat('%Y-%m')(new Date(d.month))}<br>
              ${this.showPercentage 
                ? `Pourcentage: ${percentage}%` 
                : `Entrées: ${value}`}
            `)
            .style('left', `${event.pageX + 10}px`)
            .style('top', `${event.pageY - 28}px`);
        })
        .on('mouseout', () => {
          this.tooltip.style('opacity', 0);
        })
        .on('click', (event, d) => {
          this.selectTopic(d.topic, d.month);
        });
    },
    
    renderGroupedBars(data, barWidth) {
      // Largeur des barres individuelles
      const individualBarWidth = barWidth / data.topics.length;
      
      // Créer les groupes de barres
      const barGroups = this.svg.select('.bars')
        .selectAll('.bar-group')
        .data(data.months);
      
      barGroups.exit().remove();
      
      const newBarGroups = barGroups.enter()
        .append('g')
        .attr('class', 'bar-group');
      
      const allBarGroups = newBarGroups.merge(barGroups)
        .attr('transform', d => `translate(${this.xScale(new Date(d)) - barWidth / 2}, 0)`);
      
      // Créer les barres individuelles
      const bars = allBarGroups.selectAll('.bar')
        .data(d => data.topics.map((topic, i) => ({
          topic,
          month: d,
          value: data.topicsByMonth[d][topic] || 0,
          index: i,
          total: Object.values(data.topicsByMonth[d]).reduce((sum, val) => sum + val, 0)
        })));
      
      bars.exit().remove();
      
      bars.enter()
        .append('rect')
        .attr('class', 'bar')
        .merge(bars)
        .attr('x', d => d.index * individualBarWidth)
        .attr('y', d => this.yScale(d.value))
        .attr('height', d => this.yScale(0) - this.yScale(d.value))
        .attr('width', individualBarWidth * 0.9)
        .attr('fill', d => this.colorScale(d.topic))
        .style('cursor', 'pointer')
        .on('mouseover', (event, d) => {
          const percentage = (d.value / d.total * 100).toFixed(1);
          
          this.tooltip
            .style('opacity', 1)
            .html(`
              <strong>${d.topic}</strong><br>
              Mois: ${d3.timeFormat('%Y-%m')(new Date(d.month))}<br>
              ${this.showPercentage 
                ? `Pourcentage: ${percentage}%` 
                : `Entrées: ${d.value}`}
            `)
            .style('left', `${event.pageX + 10}px`)
            .style('top', `${event.pageY - 28}px`);
        })
        .on('mouseout', () => {
          this.tooltip.style('opacity', 0);
        })
        .on('click', (event, d) => {
          this.selectTopic(d.topic, d.month);
        });
    },
    
    prepareData() {
      // Extraire les mois uniques
      const months = Object.keys(this.currentViewData).sort();
      
      // Extraire les sujets uniques
      const topics = Array.from(new Set(
        months.flatMap(month => Object.keys(this.currentViewData[month]))
      ));
      
      // Créer un objet avec les données par mois et par sujet
      const topicsByMonth = {};
      
      months.forEach(month => {
        const monthData = this.currentViewData[month];
        
        if (this.showPercentage) {
          // Calculer le total pour ce mois
          const total = Object.values(monthData).reduce((sum, val) => sum + val, 0);
          
          // Convertir en pourcentages
          topicsByMonth[month] = {};
          Object.entries(monthData).forEach(([topic, value]) => {
            topicsByMonth[month][topic] = value / total;
          });
        } else {
          topicsByMonth[month] = { ...monthData };
        }
      });
      
      return { months, topics, topicsByMonth };
    },
    
    async selectTopic(topic, month) {
      try {
        // Récupérer les détails du sujet
        const response = await this.$store.dispatch('analysis/getTopicDetails', { 
          category: this.selectedView,
          topic,
          month
        });
        
        this.selectedTopic = {
          name: topic,
          description: response.description || 'Aucune description disponible.',
          entries: response.entries || []
        };
      } catch (error) {
        console.error('Erreur lors de la récupération des détails du sujet:', error);
        this.selectedTopic = {
          name: topic,
          description: 'Erreur lors de la récupération des détails.',
          entries: []
        };
      }
    }
  }
};
</script>

<style scoped>
.topic-trends-container {
  @apply flex flex-col h-full;
}

.controls {
  @apply flex justify-between mb-4;
}

.view-selector {
  @apply flex;
}

.view-selector button {
  @apply px-4 py-2 mr-2 border border-gray-300 rounded-lg bg-white hover:bg-gray-100 focus:outline-none;
}

.view-selector button.active {
  @apply bg-blue-500 text-white border-blue-500;
}

.display-options {
  @apply flex items-center;
}

.display-options label {
  @apply flex items-center ml-4;
}

.display-options input {
  @apply mr-2;
}

.visualization {
  @apply flex-1 border border-gray-200 rounded-lg overflow-hidden;
}

.topic-details {
  @apply mt-4 p-4 border border-gray-200 rounded-lg bg-gray-50;
}

.topic-details h3 {
  @apply mt-0 text-xl font-semibold text-blue-700;
}

.topic-details ul {
  @apply pl-6;
}

.topic-details a {
  @apply text-blue-500 hover:underline cursor-pointer;
}

/* Styles D3 */
:deep(.x-axis path),
:deep(.y-axis path),
:deep(.x-axis line),
:deep(.y-axis line) {
  stroke: #ddd;
}

:deep(.x-axis text),
:deep(.y-axis text) {
  fill: #666;
  font-size: 12px;
}
</style>
