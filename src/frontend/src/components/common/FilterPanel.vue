<template>
  <div class="filter-panel">
    <div class="filter-header" @click="toggleExpanded">
      <h3 class="filter-title">
        <i class="fas fa-filter mr-2"></i>
        {{ title }}
      </h3>
      <button class="filter-toggle">
        <i :class="expanded ? 'fas fa-chevron-up' : 'fas fa-chevron-down'"></i>
      </button>
    </div>
    
    <transition name="filter">
      <div v-if="expanded" class="filter-content">
        <slot></slot>
        
        <div class="filter-actions">
          <button 
            class="btn btn-sm btn-primary mr-2"
            @click="applyFilters"
          >
            Appliquer
          </button>
          
          <button 
            class="btn btn-sm btn-secondary"
            @click="resetFilters"
          >
            Réinitialiser
          </button>
        </div>
      </div>
    </transition>
  </div>
</template>

<script>
export default {
  name: 'FilterPanel',
  props: {
    title: {
      type: String,
      default: 'Filtres'
    },
    initialExpanded: {
      type: Boolean,
      default: false
    }
  },
  data() {
    return {
      expanded: this.initialExpanded
    }
  },
  methods: {
    toggleExpanded() {
      this.expanded = !this.expanded
    },
    
    applyFilters() {
      this.$emit('apply')
    },
    
    resetFilters() {
      this.$emit('reset')
    }
  }
}
</script>

<style scoped>
.filter-panel {
  @apply bg-white border border-gray-200 rounded-lg shadow-sm overflow-hidden mb-4;
}

.filter-header {
  @apply flex justify-between items-center p-3 cursor-pointer hover:bg-gray-50;
}

.filter-title {
  @apply text-base font-medium text-gray-700;
}

.filter-toggle {
  @apply text-gray-500 hover:text-gray-700 focus:outline-none;
}

.filter-content {
  @apply p-3 border-t border-gray-200;
}

.filter-actions {
  @apply flex justify-end mt-3 pt-3 border-t border-gray-100;
}

.btn {
  @apply inline-flex items-center px-3 py-1 border border-transparent text-sm font-medium rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-offset-2;
}

.btn-primary {
  @apply text-white bg-blue-600 hover:bg-blue-700 focus:ring-blue-500;
}

.btn-secondary {
  @apply text-gray-700 bg-white border-gray-300 hover:bg-gray-50 focus:ring-blue-500;
}

.btn-sm {
  @apply px-2 py-1 text-xs;
}

/* Filter animation */
.filter-enter-active,
.filter-leave-active {
  transition: max-height 0.3s ease, opacity 0.3s ease, transform 0.3s ease;
  overflow: hidden;
}

.filter-enter-from,
.filter-leave-to {
  max-height: 0;
  opacity: 0;
  transform: translateY(-10px);
}

.filter-enter-to,
.filter-leave-from {
  max-height: 500px;
  opacity: 1;
  transform: translateY(0);
}
</style>
