<template>
  <filter-panel 
    title="Filtres d'analyse" 
    :initial-expanded="initialExpanded"
    @apply="applyFilters"
    @reset="resetFilters"
  >
    <div class="filters-grid">
      <!-- Filtre de période -->
      <div class="filter-group">
        <label class="filter-label">Période</label>
        <div class="filter-options">
          <div 
            v-for="option in periodOptions" 
            :key="option.value"
            class="filter-option"
            :class="{ 'active': filters.period === option.value }"
            @click="filters.period = option.value"
          >
            {{ option.label }}
          </div>
        </div>
      </div>
      
      <!-- Filtre de tags -->
      <div class="filter-group">
        <label class="filter-label">Tags</label>
        <div class="tags-input">
          <div class="selected-tags">
            <div 
              v-for="tag in filters.tags" 
              :key="tag"
              class="selected-tag"
            >
              {{ tag }}
              <button 
                class="remove-tag"
                @click="removeTag(tag)"
              >
                <i class="fas fa-times"></i>
              </button>
            </div>
          </div>
          
          <div class="tags-autocomplete">
            <input 
              v-model="tagInput"
              type="text"
              class="tag-input"
              placeholder="Ajouter un tag..."
              @keydown.enter="addTag"
              @focus="showTagSuggestions = true"
              @blur="hideTagSuggestions"
            />
            
            <transition name="fade">
              <div v-if="showTagSuggestions && filteredTags.length > 0" class="tag-suggestions">
                <div 
                  v-for="tag in filteredTags" 
                  :key="tag"
                  class="tag-suggestion"
                  @mousedown="selectTag(tag)"
                >
                  {{ tag }}
                </div>
              </div>
            </transition>
          </div>
        </div>
      </div>
      
      <!-- Filtre de catégories -->
      <div class="filter-group">
        <label class="filter-label">Catégories</label>
        <div class="categories-select">
          <select 
            v-model="filters.category"
            class="category-select"
          >
            <option value="">Toutes les catégories</option>
            <option 
              v-for="category in categories" 
              :key="category"
              :value="category"
            >
              {{ category }}
            </option>
          </select>
        </div>
      </div>
      
      <!-- Filtre de recherche -->
      <div class="filter-group">
        <label class="filter-label">Recherche</label>
        <div class="search-input">
          <input 
            v-model="filters.search"
            type="text"
            class="search-field"
            placeholder="Rechercher..."
          />
          <button 
            v-if="filters.search"
            class="clear-search"
            @click="filters.search = ''"
          >
            <i class="fas fa-times"></i>
          </button>
        </div>
      </div>
      
      <!-- Filtre de date -->
      <div class="filter-group">
        <label class="filter-label">Plage de dates</label>
        <div class="date-range">
          <div class="date-input">
            <label class="date-label">Début</label>
            <input 
              v-model="filters.startDate"
              type="date"
              class="date-field"
            />
          </div>
          
          <div class="date-input">
            <label class="date-label">Fin</label>
            <input 
              v-model="filters.endDate"
              type="date"
              class="date-field"
            />
          </div>
        </div>
      </div>
      
      <!-- Filtre d'affichage -->
      <div class="filter-group">
        <label class="filter-label">Affichage</label>
        <div class="display-options">
          <div class="display-option">
            <input 
              v-model="filters.limit"
              type="number"
              class="limit-field"
              min="1"
              max="500"
            />
            <span class="limit-label">éléments</span>
          </div>
          
          <div class="sort-option">
            <select 
              v-model="filters.sortBy"
              class="sort-field"
            >
              <option value="date">Date</option>
              <option value="relevance">Pertinence</option>
              <option value="alphabetical">Alphabétique</option>
            </select>
            
            <button 
              class="sort-direction"
              @click="toggleSortDirection"
            >
              <i :class="filters.sortDirection === 'asc' ? 'fas fa-sort-up' : 'fas fa-sort-down'"></i>
            </button>
          </div>
        </div>
      </div>
    </div>
    
    <!-- Filtres actifs -->
    <div v-if="hasActiveFilters" class="active-filters">
      <div class="active-filters-header">
        <span class="active-filters-title">Filtres actifs</span>
        <button 
          class="clear-all-filters"
          @click="resetFilters"
        >
          Effacer tout
        </button>
      </div>
      
      <div class="active-filters-list">
        <div 
          v-if="filters.period !== 'all'"
          class="active-filter"
        >
          Période: {{ getPeriodLabel(filters.period) }}
          <button 
            class="remove-filter"
            @click="filters.period = 'all'"
          >
            <i class="fas fa-times"></i>
          </button>
        </div>
        
        <div 
          v-for="tag in filters.tags" 
          :key="`tag-${tag}`"
          class="active-filter"
        >
          Tag: {{ tag }}
          <button 
            class="remove-filter"
            @click="removeTag(tag)"
          >
            <i class="fas fa-times"></i>
          </button>
        </div>
        
        <div 
          v-if="filters.category"
          class="active-filter"
        >
          Catégorie: {{ filters.category }}
          <button 
            class="remove-filter"
            @click="filters.category = ''"
          >
            <i class="fas fa-times"></i>
          </button>
        </div>
        
        <div 
          v-if="filters.search"
          class="active-filter"
        >
          Recherche: {{ filters.search }}
          <button 
            class="remove-filter"
            @click="filters.search = ''"
          >
            <i class="fas fa-times"></i>
          </button>
        </div>
        
        <div 
          v-if="filters.startDate"
          class="active-filter"
        >
          Date début: {{ formatDate(filters.startDate) }}
          <button 
            class="remove-filter"
            @click="filters.startDate = ''"
          >
            <i class="fas fa-times"></i>
          </button>
        </div>
        
        <div 
          v-if="filters.endDate"
          class="active-filter"
        >
          Date fin: {{ formatDate(filters.endDate) }}
          <button 
            class="remove-filter"
            @click="filters.endDate = ''"
          >
            <i class="fas fa-times"></i>
          </button>
        </div>
      </div>
    </div>
  </filter-panel>
</template>

<script>
import FilterPanel from '@/components/common/FilterPanel.vue'
import { mapActions } from 'vuex'

export default {
  name: 'AnalysisFilters',
  components: {
    FilterPanel
  },
  props: {
    initialExpanded: {
      type: Boolean,
      default: false
    },
    initialFilters: {
      type: Object,
      default: () => ({})
    }
  },
  data() {
    return {
      filters: {
        period: this.initialFilters.period || 'all',
        tags: this.initialFilters.tags || [],
        category: this.initialFilters.category || '',
        search: this.initialFilters.search || '',
        startDate: this.initialFilters.startDate || '',
        endDate: this.initialFilters.endDate || '',
        limit: this.initialFilters.limit || 100,
        sortBy: this.initialFilters.sortBy || 'date',
        sortDirection: this.initialFilters.sortDirection || 'desc'
      },
      tagInput: '',
      showTagSuggestions: false,
      allTags: [],
      categories: []
    }
  },
  computed: {
    periodOptions() {
      return [
        { value: 'all', label: 'Tout' },
        { value: 'day', label: 'Aujourd\'hui' },
        { value: 'week', label: 'Cette semaine' },
        { value: 'month', label: 'Ce mois' },
        { value: 'quarter', label: 'Ce trimestre' },
        { value: 'year', label: 'Cette année' }
      ]
    },
    
    filteredTags() {
      if (!this.tagInput) return this.allTags.slice(0, 5)
      
      return this.allTags
        .filter(tag => 
          tag.toLowerCase().includes(this.tagInput.toLowerCase()) && 
          !this.filters.tags.includes(tag)
        )
        .slice(0, 5)
    },
    
    hasActiveFilters() {
      return (
        this.filters.period !== 'all' ||
        this.filters.tags.length > 0 ||
        this.filters.category !== '' ||
        this.filters.search !== '' ||
        this.filters.startDate !== '' ||
        this.filters.endDate !== ''
      )
    }
  },
  created() {
    this.fetchTags()
    this.fetchCategories()
  },
  methods: {
    ...mapActions({
      fetchAllTags: 'journal/fetchTags',
      fetchAllCategories: 'journal/fetchCategories'
    }),
    
    async fetchTags() {
      try {
        const tags = await this.fetchAllTags()
        this.allTags = tags
      } catch (error) {
        console.error('Error fetching tags:', error)
      }
    },
    
    async fetchCategories() {
      try {
        const categories = await this.fetchAllCategories()
        this.categories = categories
      } catch (error) {
        console.error('Error fetching categories:', error)
      }
    },
    
    addTag() {
      if (!this.tagInput) return
      
      const tag = this.tagInput.trim()
      
      if (tag && !this.filters.tags.includes(tag)) {
        this.filters.tags.push(tag)
      }
      
      this.tagInput = ''
    },
    
    removeTag(tag) {
      const index = this.filters.tags.indexOf(tag)
      if (index !== -1) {
        this.filters.tags.splice(index, 1)
      }
    },
    
    selectTag(tag) {
      if (!this.filters.tags.includes(tag)) {
        this.filters.tags.push(tag)
      }
      
      this.tagInput = ''
      this.showTagSuggestions = false
    },
    
    hideTagSuggestions() {
      // Delay to allow click events on suggestions
      setTimeout(() => {
        this.showTagSuggestions = false
      }, 200)
    },
    
    toggleSortDirection() {
      this.filters.sortDirection = this.filters.sortDirection === 'asc' ? 'desc' : 'asc'
    },
    
    applyFilters() {
      this.$emit('update:filters', { ...this.filters })
      this.$emit('apply')
    },
    
    resetFilters() {
      this.filters = {
        period: 'all',
        tags: [],
        category: '',
        search: '',
        startDate: '',
        endDate: '',
        limit: 100,
        sortBy: 'date',
        sortDirection: 'desc'
      }
      
      this.$emit('update:filters', { ...this.filters })
      this.$emit('reset')
    },
    
    getPeriodLabel(period) {
      const option = this.periodOptions.find(opt => opt.value === period)
      return option ? option.label : period
    },
    
    formatDate(dateString) {
      if (!dateString) return ''
      
      const date = new Date(dateString)
      return date.toLocaleDateString()
    }
  }
}
</script>

<style scoped>
.filters-grid {
  @apply grid grid-cols-1 md:grid-cols-2 gap-4;
}

.filter-group {
  @apply mb-3;
}

.filter-label {
  @apply block text-sm font-medium text-gray-700 mb-1;
}

.filter-options {
  @apply flex flex-wrap gap-2;
}

.filter-option {
  @apply px-3 py-1 text-sm border border-gray-300 rounded-md cursor-pointer hover:bg-gray-50 transition-colors;
}

.filter-option.active {
  @apply bg-blue-100 border-blue-300 text-blue-700;
}

.tags-input {
  @apply border border-gray-300 rounded-md overflow-hidden;
}

.selected-tags {
  @apply flex flex-wrap gap-1 p-2;
}

.selected-tag {
  @apply flex items-center px-2 py-1 text-xs bg-blue-100 text-blue-700 rounded-full;
}

.remove-tag {
  @apply ml-1 text-blue-500 hover:text-blue-700 focus:outline-none;
}

.tags-autocomplete {
  @apply relative;
}

.tag-input {
  @apply w-full px-3 py-2 border-t border-gray-300 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent;
}

.tag-suggestions {
  @apply absolute left-0 right-0 bg-white border border-gray-300 rounded-b-md shadow-lg z-10 max-h-40 overflow-y-auto;
}

.tag-suggestion {
  @apply px-3 py-2 hover:bg-gray-50 cursor-pointer;
}

.categories-select {
  @apply relative;
}

.category-select {
  @apply block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent;
}

.search-input {
  @apply relative;
}

.search-field {
  @apply block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent;
}

.clear-search {
  @apply absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-gray-600 focus:outline-none;
}

.date-range {
  @apply grid grid-cols-2 gap-2;
}

.date-input {
  @apply flex flex-col;
}

.date-label {
  @apply text-xs text-gray-500 mb-1;
}

.date-field {
  @apply block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent;
}

.display-options {
  @apply flex justify-between;
}

.display-option {
  @apply flex items-center;
}

.limit-field {
  @apply w-16 px-2 py-1 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent;
}

.limit-label {
  @apply ml-2 text-sm text-gray-600;
}

.sort-option {
  @apply flex items-center;
}

.sort-field {
  @apply px-2 py-1 border border-gray-300 rounded-l-md shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent;
}

.sort-direction {
  @apply px-2 py-1 border border-gray-300 border-l-0 rounded-r-md bg-gray-50 hover:bg-gray-100 focus:outline-none;
}

.active-filters {
  @apply mt-4 pt-3 border-t border-gray-200;
}

.active-filters-header {
  @apply flex justify-between items-center mb-2;
}

.active-filters-title {
  @apply text-sm font-medium text-gray-700;
}

.clear-all-filters {
  @apply text-xs text-blue-600 hover:text-blue-800 focus:outline-none;
}

.active-filters-list {
  @apply flex flex-wrap gap-2;
}

.active-filter {
  @apply flex items-center px-2 py-1 text-xs bg-gray-100 text-gray-700 rounded-full;
}

.remove-filter {
  @apply ml-1 text-gray-500 hover:text-gray-700 focus:outline-none;
}

/* Animations */
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s ease;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>
