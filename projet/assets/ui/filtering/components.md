# Composants de Filtrage

Cette page décrit les composants de filtrage disponibles dans le système de journal de bord RAG.

## FilterPanel

Le composant `FilterPanel` est un composant réutilisable qui fournit une interface pour les filtres.

### Props

- `title` (String): Titre du panneau de filtrage (défaut: "Filtres")
- `initialExpanded` (Boolean): État initial du panneau (défaut: false)

### Événements

- `apply`: Émis lorsque l'utilisateur clique sur le bouton "Appliquer"
- `reset`: Émis lorsque l'utilisateur clique sur le bouton "Réinitialiser"

### Slots

- Default: Contenu des filtres

### Exemple d'utilisation

```html
<filter-panel 
  title="Filtres avancés" 
  :initial-expanded="true"
  @apply="applyFilters"
  @reset="resetFilters"
>
  <div class="filter-group">
    <label class="filter-label">Période</label>
    <select v-model="filters.period" class="filter-select">
      <option value="all">Tout</option>
      <option value="month">Ce mois</option>
      <option value="year">Cette année</option>
    </select>
  </div>
</filter-panel>
```plaintext
### Implémentation

```vue
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
```plaintext
## AnalysisFilters

Le composant `AnalysisFilters` est un composant spécifique pour les visualisations d'analyse. Il utilise le composant `FilterPanel` et ajoute des filtres spécifiques pour les analyses.

### Props

- `initialExpanded` (Boolean): État initial du panneau (défaut: false)
- `initialFilters` (Object): Filtres initiaux (défaut: {})

### Événements

- `update:filters`: Émis lorsque les filtres sont mis à jour
- `apply`: Émis lorsque l'utilisateur clique sur le bouton "Appliquer"
- `reset`: Émis lorsque l'utilisateur clique sur le bouton "Réinitialiser"

### Exemple d'utilisation

```html
<analysis-filters
  :initial-expanded="true"
  :initial-filters="filters"
  @update:filters="updateFilters"
  @apply="applyFilters"
  @reset="resetFilters"
/>
```plaintext
### Structure des filtres

```javascript
{
  period: 'month',        // Période (all, day, week, month, quarter, year)
  tags: ['tag1', 'tag2'], // Tags sélectionnés
  category: 'category1',  // Catégorie sélectionnée
  search: 'search term',  // Terme de recherche
  startDate: '2023-01-01', // Date de début
  endDate: '2023-12-31',   // Date de fin
  limit: 100,             // Nombre maximum d'éléments
  sortBy: 'date',         // Tri (date, relevance, alphabetical)
  sortDirection: 'desc'   // Direction de tri (asc, desc)
}
```plaintext
### Fonctionnalités

- **Filtres de période**: Sélection de période prédéfinie ou personnalisée
- **Filtres de tags**: Sélection de tags avec autocomplétion
- **Filtres de catégorie**: Sélection de catégorie
- **Filtres de recherche**: Recherche textuelle
- **Filtres de date**: Sélection de plage de dates
- **Filtres d'affichage**: Limite et tri
- **Filtres actifs**: Affichage et suppression des filtres actifs

## Intégration avec les visualisations

Pour intégrer les filtres dans une visualisation:

1. Importez le composant `AnalysisFilters`
2. Ajoutez-le à votre template
3. Gérez les événements `update:filters`, `apply` et `reset`
4. Utilisez les filtres pour récupérer les données

```javascript
import AnalysisFilters from '@/components/analysis/AnalysisFilters.vue'

export default {
  components: {
    AnalysisFilters
  },
  data() {
    return {
      filters: {
        period: 'month',
        tags: [],
        category: '',
        search: '',
        startDate: '',
        endDate: '',
        limit: 100,
        sortBy: 'date',
        sortDirection: 'desc'
      },
      showFilters: false
    }
  },
  methods: {
    updateFilters(filters) {
      this.filters = { ...filters }
    },
    
    applyFilters() {
      this.fetchData()
    },
    
    resetFilters() {
      this.filters = {
        period: 'month',
        tags: [],
        category: '',
        search: '',
        startDate: '',
        endDate: '',
        limit: 100,
        sortBy: 'date',
        sortDirection: 'desc'
      }
      this.fetchData()
    },
    
    fetchData() {
      // Utilisez this.filters pour récupérer les données
      const params = {
        period: this.filters.period,
        maxWords: parseInt(this.maxWords)
      }
      
      // Ajouter les filtres avancés si activés
      if (this.showFilters) {
        if (this.filters.tags.length > 0) {
          params.tags = this.filters.tags
        }
        
        if (this.filters.category) {
          params.category = this.filters.category
        }
        
        if (this.filters.search) {
          params.search = this.filters.search
        }
        
        if (this.filters.startDate) {
          params.startDate = this.filters.startDate
        }
        
        if (this.filters.endDate) {
          params.endDate = this.filters.endDate
        }
      }
      
      // Appeler l'API avec les paramètres
      this.fetchWordCloud(params)
    }
  }
}
```plaintext
## Personnalisation

### Ajout de nouveaux filtres

Pour ajouter un nouveau filtre:

1. Ajoutez le filtre à la structure des filtres
2. Ajoutez le filtre à l'interface utilisateur
3. Ajoutez le filtre aux filtres actifs
4. Ajoutez le filtre aux paramètres de l'API

### Modification de l'apparence

Pour modifier l'apparence des filtres:

1. Modifiez les styles CSS dans les composants
2. Utilisez des classes TailwindCSS pour personnaliser l'apparence
3. Ajoutez des animations et des transitions

### Ajout de fonctionnalités

Pour ajouter des fonctionnalités:

1. Ajoutez des méthodes aux composants
2. Ajoutez des événements pour communiquer avec le parent
3. Ajoutez des props pour configurer le comportement
