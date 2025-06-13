# Filtrage Avancé

## Introduction

Le système de filtrage avancé permet aux utilisateurs de filtrer les données affichées dans les visualisations selon différents critères. Cette documentation décrit les composants et les fonctionnalités du système de filtrage.

## Composants de filtrage

### FilterPanel

Le composant `FilterPanel` est un composant réutilisable qui fournit une interface pour les filtres. Il peut être utilisé dans n'importe quelle visualisation ou page qui nécessite des filtres.

```html
<filter-panel 
  title="Filtres" 
  :initial-expanded="true"
  @apply="applyFilters"
  @reset="resetFilters"
>
  <!-- Contenu des filtres -->
</filter-panel>
```plaintext
### AnalysisFilters

Le composant `AnalysisFilters` est un composant spécifique pour les visualisations d'analyse. Il utilise le composant `FilterPanel` et ajoute des filtres spécifiques pour les analyses.

```html
<analysis-filters
  :initial-expanded="true"
  :initial-filters="filters"
  @update:filters="updateFilters"
  @apply="applyFilters"
  @reset="resetFilters"
/>
```plaintext
## Types de filtres

### Filtres de période

Les filtres de période permettent de filtrer les données par période:

- **Période prédéfinie**: Tout, Aujourd'hui, Cette semaine, Ce mois, Ce trimestre, Cette année
- **Période personnalisée**: Dates de début et de fin spécifiques

### Filtres de tags

Les filtres de tags permettent de filtrer les données par tags:

- **Sélection de tags**: Sélection de tags spécifiques
- **Autocomplétion**: Suggestions de tags lors de la saisie
- **Suppression de tags**: Suppression de tags sélectionnés

### Filtres de catégorie

Les filtres de catégorie permettent de filtrer les données par catégorie:

- **Sélection de catégorie**: Sélection d'une catégorie spécifique
- **Toutes les catégories**: Affichage de toutes les catégories

### Filtres de recherche

Les filtres de recherche permettent de filtrer les données par terme de recherche:

- **Recherche textuelle**: Recherche de termes spécifiques
- **Recherche avancée**: Opérateurs de recherche avancée (ET, OU, NOT)

### Filtres d'affichage

Les filtres d'affichage permettent de configurer l'affichage des données:

- **Limite**: Nombre maximum d'éléments à afficher
- **Tri**: Tri par date, pertinence ou ordre alphabétique
- **Direction de tri**: Ascendant ou descendant

## Utilisation

### Intégration dans les visualisations

Pour intégrer le système de filtrage dans une visualisation:

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
    }
  }
}
```plaintext
### Filtres actifs

Le composant `AnalysisFilters` affiche les filtres actifs et permet de les supprimer:

```html
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
    
    <!-- Autres filtres actifs -->
  </div>
</div>
```plaintext
## Animations

Le système de filtrage utilise des animations pour améliorer l'expérience utilisateur:

- **Transition de panneau**: Le panneau de filtrage apparaît/disparaît avec une animation
- **Transition de suggestions**: Les suggestions de tags apparaissent/disparaissent avec une animation
- **Transition de filtres actifs**: Les filtres actifs apparaissent/disparaissent avec une animation

```html
<transition name="filter">
  <div v-if="expanded" class="filter-content">
    <!-- Contenu des filtres -->
  </div>
</transition>
```plaintext
## Personnalisation

Le système de filtrage peut être personnalisé en modifiant les composants `FilterPanel` et `AnalysisFilters`. Vous pouvez:

- Ajouter de nouveaux types de filtres
- Modifier l'apparence des filtres
- Modifier le comportement des filtres
- Ajouter des fonctionnalités spécifiques à votre application
