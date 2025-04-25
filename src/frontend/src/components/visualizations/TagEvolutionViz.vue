<template>
  <div class="tag-evolution-container">
    <div class="controls">
      <div class="tag-selector">
        <div class="selected-tags">
          <div 
            v-for="tag in selectedTags" 
            :key="tag"
            class="tag-chip"
            :style="{ backgroundColor: getTagColor(tag) }"
          >
            {{ tag }}
            <button @click="removeTag(tag)" class="remove-tag">×</button>
          </div>
        </div>
        
        <div class="tag-dropdown">
          <input 
            type="text" 
            v-model="tagSearch" 
            placeholder="Ajouter un tag..." 
            @focus="showTagDropdown = true"
            @blur="hideTagDropdownDelayed"
          />
          <div v-if="showTagDropdown" class="dropdown-content">
            <div 
              v-for="tag in filteredTags" 
              :key="tag.name"
              class="dropdown-item"
              @mousedown="addTag(tag.name)"
            >
              {{ tag.name }} ({{ tag.count }})
            </div>
            <div v-if="filteredTags.length === 0" class="dropdown-item empty">
              Aucun tag trouvé
            </div>
          </div>
        </div>
      </div>
      
      <div class="display-options">
        <label>
          <input type="checkbox" v-model="showRelative" />
          Valeurs relatives
        </label>
        <label>
          <input type="checkbox" v-model="smoothLines" />
          Courbes lissées
        </label>
      </div>
    </div>
    
    <div class="visualization" ref="visualization"></div>
    
    <div class="legend">
      <div 
        v-for="tag in selectedTags" 
        :key="tag"
        class="legend-item"
        @click="toggleTagVisibility(tag)"
      >
        <div class="color-box" :style="{ backgroundColor: getTagColor(tag) }"></div>
        <span :class="{ 'inactive': !visibleTags.includes(tag) }">{{ tag }}</span>
      </div>
    </div>
  </div>
</template>

<script>
import * as d3 from 'd3';
import { mapGetters } from 'vuex';

export default {
  name: 'TagEvolutionViz',
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
      selectedTags: [],
      visibleTags: [],
      tagSearch: '',
      showTagDropdown: false,
      showRelative: false,
      smoothLines: true,
      svg: null,
      xScale: null,
      yScale: null,
      colorScale: d3.scaleOrdinal(d3.schemeCategory10),
      tooltip: null
    };
  },
  computed: {
    ...mapGetters('analysis', ['tagEvolutionData', 'allTags']),
    
    filteredTags() {
      if (!this.allTags) return [];
      
      return this.allTags
        .filter(tag => !this.selectedTags.includes(tag.name) && 
                      tag.name.toLowerCase().includes(this.tagSearch.toLowerCase()))
        .sort((a, b) => b.count - a.count)
        .slice(0, 10);
    }
  },
  watch: {
    selectedTags() {
      this.visibleTags = [...this.selectedTags];
      this.updateVisualization();
    },
    visibleTags() {
      this.updateVisualization();
    },
    showRelative() {
      this.updateVisualization();
    },
    smoothLines() {
      this.updateVisualization();
    },
    tagEvolutionData() {
      this.updateVisualization();
    }
  },
  mounted() {
    this.initVisualization();
    this.fetchData();
  },
  methods: {
    async fetchData() {
      if (!this.tagEvolutionData) {
        await this.$store.dispatch('analysis/fetchTagEvolution');
      }
      
      if (this.allTags && this.allTags.length > 0) {
        // Sélectionner les 5 tags les plus fréquents par défaut
        this.selectedTags = this.allTags
          .sort((a, b) => b.count - a.count)
          .slice(0, 5)
          .map(tag => tag.name);
        
        this.visibleTags = [...this.selectedTags];
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
        .text('Fréquence');
      
      // Ajouter un groupe pour les lignes
      g.append('g')
        .attr('class', 'lines');
      
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
      if (!this.tagEvolutionData || this.visibleTags.length === 0) return;
      
      const margin = { top: 20, right: 50, bottom: 50, left: 50 };
      const width = this.width - margin.left - margin.right;
      const height = this.height - margin.top - margin.bottom;
      
      // Préparer les données
      const data = this.prepareData();
      
      // Mettre à jour les échelles
      this.xScale.domain(d3.extent(data.dates, d => d));
      
      const yMax = this.showRelative
        ? 1
        : d3.max(data.series, series => d3.max(series.values));
      
      this.yScale.domain([0, yMax * 1.1]);
      
      // Mettre à jour les axes
      const xAxis = d3.axisBottom(this.xScale)
        .ticks(Math.min(data.dates.length, 10))
        .tickFormat(d3.timeFormat('%Y-%m'));
      
      const yAxis = d3.axisLeft(this.yScale)
        .ticks(5)
        .tickFormat(d => this.showRelative ? `${(d * 100).toFixed(0)}%` : d);
      
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
        .text(this.showRelative ? 'Fréquence relative (%)' : 'Nombre d\'occurrences');
      
      // Créer la fonction de ligne
      const line = this.smoothLines
        ? d3.line()
            .x((d, i) => this.xScale(data.dates[i]))
            .y(d => this.yScale(d))
            .curve(d3.curveMonotoneX)
        : d3.line()
            .x((d, i) => this.xScale(data.dates[i]))
            .y(d => this.yScale(d));
      
      // Mettre à jour les lignes
      const lines = this.svg.select('.lines')
        .selectAll('.line')
        .data(data.series);
      
      // Supprimer les lignes qui ne sont plus nécessaires
      lines.exit().remove();
      
      // Ajouter les nouvelles lignes
      lines.enter()
        .append('path')
        .attr('class', 'line')
        .merge(lines)
        .attr('d', d => line(d.values))
        .attr('fill', 'none')
        .attr('stroke', d => this.getTagColor(d.tag))
        .attr('stroke-width', 2)
        .attr('opacity', 1);
      
      // Ajouter des points interactifs
      const pointGroups = this.svg.select('.lines')
        .selectAll('.point-group')
        .data(data.series);
      
      pointGroups.exit().remove();
      
      const newPointGroups = pointGroups.enter()
        .append('g')
        .attr('class', 'point-group');
      
      const allPointGroups = newPointGroups.merge(pointGroups);
      
      const points = allPointGroups.selectAll('.point')
        .data(d => d.values.map((value, i) => ({
          tag: d.tag,
          value,
          date: data.dates[i]
        })));
      
      points.exit().remove();
      
      points.enter()
        .append('circle')
        .attr('class', 'point')
        .merge(points)
        .attr('cx', d => this.xScale(d.date))
        .attr('cy', d => this.yScale(d.value))
        .attr('r', 5)
        .attr('fill', d => this.getTagColor(d.tag))
        .attr('stroke', 'white')
        .attr('stroke-width', 1)
        .style('cursor', 'pointer')
        .on('mouseover', (event, d) => {
          this.tooltip
            .style('opacity', 1)
            .html(`
              <strong>${d.tag}</strong><br>
              Date: ${d3.timeFormat('%Y-%m')(d.date)}<br>
              ${this.showRelative 
                ? `Fréquence: ${(d.value * 100).toFixed(1)}%` 
                : `Occurrences: ${d.value}`}
            `)
            .style('left', `${event.pageX + 10}px`)
            .style('top', `${event.pageY - 28}px`);
        })
        .on('mouseout', () => {
          this.tooltip.style('opacity', 0);
        });
    },
    
    prepareData() {
      // Convertir les dates en objets Date
      const dates = Object.keys(this.tagEvolutionData).map(date => new Date(date));
      
      // Créer les séries pour chaque tag visible
      const series = this.visibleTags.map(tag => {
        const values = Object.entries(this.tagEvolutionData).map(([date, data]) => {
          if (this.showRelative) {
            return data[tag] || 0;
          } else {
            // Convertir la fréquence relative en nombre absolu
            const totalTags = Object.values(data).reduce((sum, val) => sum + val, 0);
            return data[tag] ? data[tag] * totalTags : 0;
          }
        });
        
        return { tag, values };
      });
      
      return { dates, series };
    },
    
    addTag(tag) {
      if (!this.selectedTags.includes(tag)) {
        this.selectedTags.push(tag);
        this.visibleTags.push(tag);
      }
      this.tagSearch = '';
    },
    
    removeTag(tag) {
      this.selectedTags = this.selectedTags.filter(t => t !== tag);
      this.visibleTags = this.visibleTags.filter(t => t !== tag);
    },
    
    toggleTagVisibility(tag) {
      if (this.visibleTags.includes(tag)) {
        this.visibleTags = this.visibleTags.filter(t => t !== tag);
      } else {
        this.visibleTags.push(tag);
      }
    },
    
    getTagColor(tag) {
      return this.colorScale(tag);
    },
    
    hideTagDropdownDelayed() {
      setTimeout(() => {
        this.showTagDropdown = false;
      }, 200);
    }
  }
};
</script>

<style scoped>
.tag-evolution-container {
  @apply flex flex-col h-full;
}

.controls {
  @apply flex justify-between mb-4;
}

.tag-selector {
  @apply flex-1 mr-4;
}

.selected-tags {
  @apply flex flex-wrap mb-2;
}

.tag-chip {
  @apply px-3 py-1 rounded-full text-white text-sm mr-2 mb-2 flex items-center;
}

.remove-tag {
  @apply ml-2 text-white font-bold text-lg leading-none hover:text-gray-200 focus:outline-none;
}

.tag-dropdown {
  @apply relative;
}

.tag-dropdown input {
  @apply w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent;
}

.dropdown-content {
  @apply absolute z-10 w-full mt-1 bg-white border border-gray-300 rounded-lg shadow-lg max-h-60 overflow-y-auto;
}

.dropdown-item {
  @apply px-4 py-2 hover:bg-gray-100 cursor-pointer;
}

.dropdown-item.empty {
  @apply text-gray-500 italic;
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

.legend {
  @apply flex flex-wrap mt-4;
}

.legend-item {
  @apply flex items-center mr-4 mb-2 cursor-pointer;
}

.color-box {
  @apply w-4 h-4 mr-2 rounded;
}

.legend-item span.inactive {
  @apply text-gray-400 line-through;
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
