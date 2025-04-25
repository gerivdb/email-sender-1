<template>
  <div class="tag-evolution-container">
    <div class="chart-header">
      <h3>Évolution des tags</h3>
      <div class="chart-controls">
        <div class="tags-selector">
          <label for="tags">Tags:</label>
          <div class="selected-tags">
            <div 
              v-for="tag in selectedTags" 
              :key="tag"
              class="selected-tag"
            >
              {{ tag }}
              <button @click="removeTag(tag)" class="remove-tag">
                <i class="fas fa-times"></i>
              </button>
            </div>
            
            <div class="tag-dropdown" v-if="availableTags.length > 0">
              <button @click="showTagsList = !showTagsList" class="add-tag-button">
                <i class="fas fa-plus"></i>
              </button>
              
              <div v-if="showTagsList" class="tags-list">
                <div class="tags-search">
                  <input 
                    type="text" 
                    v-model="tagSearch" 
                    placeholder="Rechercher un tag..."
                    @input="filterTags"
                  >
                </div>
                
                <div class="tags-options">
                  <div 
                    v-for="tag in filteredTags" 
                    :key="tag.name"
                    class="tag-option"
                    @click="addTag(tag.name)"
                  >
                    <span class="tag-name">{{ tag.name }}</span>
                    <span class="tag-count">({{ tag.count }})</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    
    <div class="chart-content">
      <div v-if="loading" class="loading-state">
        <i class="fas fa-spinner fa-spin"></i>
        <p>Chargement des données...</p>
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
        <p>Sélectionnez au moins un tag pour afficher l'évolution</p>
      </div>
      
      <div v-else ref="chartContainer" class="chart-container">
        <!-- Le graphique sera rendu ici -->
      </div>
    </div>
  </div>
</template>

<script>
import { mapActions, mapGetters } from 'vuex';
import * as d3 from 'd3';

export default {
  name: 'TagEvolution',
  props: {
    height: {
      type: Number,
      default: 400
    },
    initialTags: {
      type: Array,
      default: () => []
    }
  },
  data() {
    return {
      selectedTags: [...this.initialTags],
      showTagsList: false,
      tagSearch: '',
      filteredTags: [],
      evolutionData: {},
      loading: false,
      error: null
    };
  },
  computed: {
    ...mapGetters({
      allTags: 'journal/allTags'
    }),
    
    availableTags() {
      return this.allTags.filter(tag => !this.selectedTags.includes(tag.name));
    },
    
    hasData() {
      return this.selectedTags.length > 0 && Object.keys(this.evolutionData).length > 0;
    }
  },
  watch: {
    selectedTags() {
      this.fetchData();
    }
  },
  mounted() {
    this.fetchTags();
    this.fetchData();
    
    // Redimensionner le graphique lors du redimensionnement de la fenêtre
    window.addEventListener('resize', this.debounce(this.renderChart, 300));
    
    // Fermer la liste des tags lors d'un clic à l'extérieur
    document.addEventListener('click', this.handleOutsideClick);
  },
  beforeUnmount() {
    window.removeEventListener('resize', this.debounce(this.renderChart, 300));
    document.removeEventListener('click', this.handleOutsideClick);
  },
  methods: {
    ...mapActions({
      fetchAllTags: 'journal/fetchTags',
      fetchTagEvolution: 'analysis/fetchTagEvolution'
    }),
    
    async fetchTags() {
      if (this.allTags.length === 0) {
        await this.fetchAllTags();
      }
      this.filterTags();
    },
    
    async fetchData() {
      if (this.selectedTags.length === 0) return;
      
      this.loading = true;
      this.error = null;
      
      try {
        const response = await this.fetchTagEvolution();
        this.evolutionData = response;
        
        // Rendre le graphique
        this.$nextTick(() => {
          this.renderChart();
        });
      } catch (error) {
        console.error('Error fetching tag evolution data:', error);
        this.error = 'Erreur lors du chargement des données';
      } finally {
        this.loading = false;
      }
    },
    
    filterTags() {
      if (!this.tagSearch.trim()) {
        this.filteredTags = this.availableTags;
      } else {
        const search = this.tagSearch.toLowerCase();
        this.filteredTags = this.availableTags.filter(tag => 
          tag.name.toLowerCase().includes(search)
        );
      }
    },
    
    addTag(tag) {
      if (!this.selectedTags.includes(tag)) {
        this.selectedTags.push(tag);
      }
      this.showTagsList = false;
      this.tagSearch = '';
    },
    
    removeTag(tag) {
      const index = this.selectedTags.indexOf(tag);
      if (index !== -1) {
        this.selectedTags.splice(index, 1);
      }
    },
    
    handleOutsideClick(event) {
      const dropdown = this.$el.querySelector('.tag-dropdown');
      if (dropdown && !dropdown.contains(event.target)) {
        this.showTagsList = false;
      }
    },
    
    renderChart() {
      if (!this.hasData || !this.$refs.chartContainer) return;
      
      // Nettoyer le conteneur
      const container = this.$refs.chartContainer;
      container.innerHTML = '';
      
      // Dimensions
      const margin = { top: 20, right: 80, bottom: 30, left: 50 };
      const width = container.clientWidth - margin.left - margin.right;
      const height = this.height - margin.top - margin.bottom;
      
      // Préparer les données
      const data = [];
      const months = Object.keys(this.evolutionData).sort();
      
      months.forEach(month => {
        const monthData = this.evolutionData[month];
        
        this.selectedTags.forEach(tag => {
          data.push({
            month,
            tag,
            count: monthData[tag] || 0
          });
        });
      });
      
      // Créer les échelles
      const x = d3.scaleBand()
        .domain(months)
        .range([0, width])
        .padding(0.1);
      
      const y = d3.scaleLinear()
        .domain([0, d3.max(data, d => d.count)])
        .nice()
        .range([height, 0]);
      
      const color = d3.scaleOrdinal(d3.schemeCategory10)
        .domain(this.selectedTags);
      
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
        .call(d3.axisLeft(y));
      
      // Créer les lignes
      const line = d3.line()
        .x(d => x(d.month) + x.bandwidth() / 2)
        .y(d => y(d.count))
        .curve(d3.curveMonotoneX);
      
      // Grouper les données par tag
      const tagData = this.selectedTags.map(tag => {
        return {
          tag,
          values: data.filter(d => d.tag === tag)
        };
      });
      
      // Ajouter les lignes
      const lines = svg.selectAll('.line')
        .data(tagData)
        .enter()
        .append('path')
        .attr('class', 'line')
        .attr('d', d => line(d.values))
        .style('fill', 'none')
        .style('stroke', d => color(d.tag))
        .style('stroke-width', 2);
      
      // Ajouter les points
      const points = svg.selectAll('.point')
        .data(data)
        .enter()
        .append('circle')
        .attr('class', 'point')
        .attr('cx', d => x(d.month) + x.bandwidth() / 2)
        .attr('cy', d => y(d.count))
        .attr('r', 4)
        .style('fill', d => color(d.tag))
        .style('stroke', '#fff')
        .style('stroke-width', 1.5)
        .on('mouseover', function(event, d) {
          d3.select(this)
            .transition()
            .duration(200)
            .attr('r', 6);
          
          // Afficher la tooltip
          svg.append('text')
            .attr('class', 'tooltip')
            .attr('x', x(d.month) + x.bandwidth() / 2)
            .attr('y', y(d.count) - 10)
            .attr('text-anchor', 'middle')
            .style('font-size', '12px')
            .style('fill', color(d.tag))
            .text(`${d.tag}: ${d.count}`);
        })
        .on('mouseout', function(event, d) {
          d3.select(this)
            .transition()
            .duration(200)
            .attr('r', 4);
          
          // Supprimer la tooltip
          svg.selectAll('.tooltip').remove();
        });
      
      // Ajouter la légende
      const legend = svg.selectAll('.legend')
        .data(this.selectedTags)
        .enter()
        .append('g')
        .attr('class', 'legend')
        .attr('transform', (d, i) => `translate(0,${i * 20})`);
      
      legend.append('rect')
        .attr('x', width + 10)
        .attr('width', 18)
        .attr('height', 18)
        .style('fill', d => color(d));
      
      legend.append('text')
        .attr('x', width + 35)
        .attr('y', 9)
        .attr('dy', '.35em')
        .style('font-size', '12px')
        .text(d => d);
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
.tag-evolution-container {
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

.tags-selector {
  @apply flex items-center;
}

.tags-selector label {
  @apply text-sm text-gray-600 mr-2;
}

.selected-tags {
  @apply flex flex-wrap items-center;
}

.selected-tag {
  @apply flex items-center px-2 py-1 text-xs bg-blue-100 text-blue-800 rounded-full mr-2 mb-1;
}

.remove-tag {
  @apply ml-1 text-blue-500 hover:text-blue-700 focus:outline-none;
}

.tag-dropdown {
  @apply relative;
}

.add-tag-button {
  @apply flex items-center justify-center w-6 h-6 text-xs bg-gray-100 text-gray-600 rounded-full hover:bg-gray-200 focus:outline-none;
}

.tags-list {
  @apply absolute right-0 mt-1 bg-white border border-gray-200 rounded-lg shadow-lg z-10;
  width: 200px;
}

.tags-search {
  @apply p-2 border-b border-gray-100;
}

.tags-search input {
  @apply w-full px-2 py-1 text-sm border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent;
}

.tags-options {
  @apply max-h-40 overflow-y-auto;
}

.tag-option {
  @apply flex justify-between items-center p-2 text-sm hover:bg-gray-50 cursor-pointer;
}

.tag-count {
  @apply text-xs text-gray-500;
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

.chart-container {
  @apply w-full overflow-hidden;
}
</style>
