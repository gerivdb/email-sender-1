<template>
  <div class="word-cloud-container">
    <div class="controls">
      <div class="period-selector">
        <button 
          v-for="period in periods" 
          :key="period.value"
          :class="{ active: selectedPeriod === period.value }"
          @click="selectedPeriod = period.value"
        >
          {{ period.label }}
        </button>
      </div>
      
      <div class="filters">
        <label>
          Min. fréquence:
          <input type="range" v-model.number="minFrequency" min="1" :max="maxFrequency" />
          {{ minFrequency }}
        </label>
        
        <label>
          Max. termes:
          <input type="range" v-model.number="maxTerms" min="10" max="200" step="10" />
          {{ maxTerms }}
        </label>
      </div>
    </div>
    
    <div class="visualization" ref="visualization"></div>
    
    <div v-if="selectedWord" class="word-details">
      <h3>{{ selectedWord }}</h3>
      <p>Fréquence: {{ selectedWordData.count }}</p>
      <p>Entrées associées:</p>
      <ul>
        <li v-for="entry in selectedWordData.entries" :key="entry.id">
          <a @click.prevent="$emit('view-entry', entry.id)" href="#">
            {{ entry.title }}
          </a>
        </li>
      </ul>
    </div>
  </div>
</template>

<script>
import * as d3 from 'd3';
import cloud from 'd3-cloud';
import { debounce } from 'lodash';
import { mapGetters } from 'vuex';

export default {
  name: 'WordCloudViz',
  props: {
    width: {
      type: Number,
      default: 800
    },
    height: {
      type: Number,
      default: 500
    }
  },
  data() {
    return {
      periods: [
        { label: 'Tous', value: 'all' },
        { label: 'Mois', value: 'month' },
        { label: 'Semaine', value: 'week' },
        { label: 'Jour', value: 'day' }
      ],
      selectedPeriod: 'all',
      minFrequency: 1,
      maxFrequency: 100,
      maxTerms: 100,
      selectedWord: null,
      selectedWordData: null,
      wordData: {},
      svg: null,
      layout: null
    };
  },
  computed: {
    ...mapGetters('analysis', ['termFrequencyData']),
    
    filteredWords() {
      if (!this.termFrequencyData || !this.termFrequencyData[this.selectedPeriod]) {
        return [];
      }
      
      const periodData = this.termFrequencyData[this.selectedPeriod];
      const words = Object.entries(periodData.top_terms)
        .filter(([_, count]) => count >= this.minFrequency)
        .sort((a, b) => b[1] - a[1])
        .slice(0, this.maxTerms)
        .map(([text, count]) => ({
          text,
          size: this.calculateFontSize(count, periodData.top_terms),
          count
        }));
      
      return words;
    }
  },
  watch: {
    selectedPeriod() {
      this.updateVisualization();
    },
    minFrequency: debounce(function() {
      this.updateVisualization();
    }, 300),
    maxTerms: debounce(function() {
      this.updateVisualization();
    }, 300),
    filteredWords() {
      this.updateVisualization();
    }
  },
  mounted() {
    this.initVisualization();
    this.fetchData();
  },
  methods: {
    async fetchData() {
      if (!this.termFrequencyData) {
        await this.$store.dispatch('analysis/fetchTermFrequency');
      }
      
      // Calculer la fréquence maximale
      if (this.termFrequencyData && this.termFrequencyData.all) {
        const counts = Object.values(this.termFrequencyData.all.top_terms);
        this.maxFrequency = Math.max(...counts);
      }
      
      this.updateVisualization();
    },
    
    initVisualization() {
      const container = this.$refs.visualization;
      
      this.svg = d3.select(container)
        .append('svg')
        .attr('width', this.width)
        .attr('height', this.height)
        .append('g')
        .attr('transform', `translate(${this.width / 2},${this.height / 2})`);
      
      this.layout = cloud()
        .size([this.width, this.height])
        .padding(5)
        .rotate(() => 0)
        .fontSize(d => d.size)
        .on('end', words => this.drawWordCloud(words));
    },
    
    updateVisualization() {
      if (!this.layout || this.filteredWords.length === 0) return;
      
      this.layout
        .words(this.filteredWords)
        .start();
    },
    
    drawWordCloud(words) {
      const color = d3.scaleOrdinal(d3.schemeCategory10);
      
      // Supprimer les mots existants
      this.svg.selectAll('text').remove();
      
      // Ajouter les nouveaux mots
      this.svg.selectAll('text')
        .data(words)
        .enter()
        .append('text')
        .style('font-size', d => `${d.size}px`)
        .style('fill', (_, i) => color(i))
        .attr('text-anchor', 'middle')
        .attr('transform', d => `translate(${d.x},${d.y})`)
        .text(d => d.text)
        .style('cursor', 'pointer')
        .on('mouseover', (event, d) => {
          d3.select(event.currentTarget)
            .transition()
            .duration(200)
            .style('font-size', `${d.size * 1.2}px`)
            .style('font-weight', 'bold');
        })
        .on('mouseout', (event, d) => {
          d3.select(event.currentTarget)
            .transition()
            .duration(200)
            .style('font-size', `${d.size}px`)
            .style('font-weight', 'normal');
        })
        .on('click', (event, d) => {
          this.selectWord(d.text, d.count);
        });
    },
    
    calculateFontSize(count, allCounts) {
      const maxCount = Math.max(...Object.values(allCounts));
      const minCount = Math.min(...Object.values(allCounts));
      const minSize = 12;
      const maxSize = 60;
      
      // Échelle logarithmique pour mieux distribuer les tailles
      return minSize + (maxSize - minSize) * Math.log(count - minCount + 1) / Math.log(maxCount - minCount + 1);
    },
    
    async selectWord(word, count) {
      this.selectedWord = word;
      
      // Si nous avons déjà les données pour ce mot, les utiliser
      if (this.wordData[word]) {
        this.selectedWordData = this.wordData[word];
        return;
      }
      
      // Sinon, rechercher les entrées contenant ce mot
      try {
        const response = await this.$store.dispatch('journal/searchJournal', { query: word, limit: 10 });
        
        this.selectedWordData = {
          count,
          entries: response.map(entry => ({
            id: entry.file.replace('.md', ''),
            title: entry.title,
            date: entry.date
          }))
        };
        
        // Mettre en cache les données
        this.wordData[word] = this.selectedWordData;
      } catch (error) {
        console.error('Erreur lors de la recherche des entrées:', error);
        this.selectedWordData = { count, entries: [] };
      }
    }
  }
};
</script>

<style scoped>
.word-cloud-container {
  @apply flex flex-col h-full;
}

.controls {
  @apply flex justify-between mb-4;
}

.period-selector button {
  @apply px-4 py-2 mr-2 border border-gray-300 rounded-lg bg-white hover:bg-gray-100 focus:outline-none;
}

.period-selector button.active {
  @apply bg-blue-500 text-white border-blue-500;
}

.filters {
  @apply flex items-center;
}

.filters label {
  @apply ml-4 flex items-center;
}

.filters input {
  @apply mx-2;
}

.visualization {
  @apply flex-1 border border-gray-200 rounded-lg overflow-hidden;
}

.word-details {
  @apply mt-4 p-4 border border-gray-200 rounded-lg bg-gray-50;
}

.word-details h3 {
  @apply mt-0 text-xl font-semibold text-blue-700;
}

.word-details ul {
  @apply pl-6;
}

.word-details a {
  @apply text-blue-500 hover:underline cursor-pointer;
}
</style>
