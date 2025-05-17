/**
 * Module de gestion des filtres personnalisés pour les roadmaps
 * Ce module intègre tous les types de filtres (hiérarchique, thématique, temporel, statut/priorité)
 *
 * Version: 1.0
 * Date: 2025-05-30
 */

// Importer les modules de filtres
import HierarchyLevelFilter from './HierarchyLevelFilter.js';
import { ThematicFilter, TemporalFilter } from './ThematicTemporalFilter.js';
import StatusPriorityView from './StatusPriorityView.js';

/**
 * Classe pour la gestion des filtres personnalisés
 */
class CustomFiltersManager {
  /**
   * Constructeur
   * @param {Object} visualizer - Instance de MetroMapVisualizerEnhanced
   * @param {Object} options - Options de configuration
   */
  constructor(visualizer, options = {}) {
    this.visualizer = visualizer;
    this.cy = visualizer.cy; // Référence à l'instance Cytoscape

    // Options par défaut
    this.options = {
      // Conteneur pour l'interface utilisateur
      uiContainer: 'custom-filters-container',

      // Options pour les filtres hiérarchiques
      hierarchyLevelFilterOptions: {},

      // Options pour les filtres thématiques
      thematicFilterOptions: {},

      // Options pour les filtres temporels
      temporalFilterOptions: {},

      // Options pour les vues par statut et priorité
      statusPriorityViewOptions: {},

      // Autres options
      ...options
    };

    // Créer les filtres
    this.hierarchyLevelFilter = new HierarchyLevelFilter(visualizer, this.options.hierarchyLevelFilterOptions);
    this.thematicFilter = new ThematicFilter(visualizer, this.options.thematicFilterOptions);
    this.temporalFilter = new TemporalFilter(visualizer, this.options.temporalFilterOptions);
    this.statusPriorityView = new StatusPriorityView(visualizer, this.options.statusPriorityViewOptions);

    // État interne
    this.state = {
      activeFilters: new Set(['hierarchyLevel', 'thematic', 'temporal', 'statusPriority']),
      filtersInitialized: false
    };
  }

  /**
   * Initialise tous les filtres
   * @returns {Promise<CustomFiltersManager>} - Instance courante pour chaînage
   */
  async initialize() {
    // Initialiser les filtres
    this.hierarchyLevelFilter.initialize();
    await this.thematicFilter.initialize();
    this.temporalFilter.initialize();
    await this.statusPriorityView.initialize();

    // Marquer comme initialisé
    this.state.filtersInitialized = true;

    return this;
  }

  /**
   * Active un type de filtre
   * @param {string} filterType - Type de filtre à activer
   * @returns {CustomFiltersManager} - Instance courante pour chaînage
   */
  activateFilter(filterType) {
    this.state.activeFilters.add(filterType);
    return this;
  }

  /**
   * Désactive un type de filtre
   * @param {string} filterType - Type de filtre à désactiver
   * @returns {CustomFiltersManager} - Instance courante pour chaînage
   */
  deactivateFilter(filterType) {
    this.state.activeFilters.delete(filterType);
    return this;
  }

  /**
   * Bascule l'état d'un type de filtre
   * @param {string} filterType - Type de filtre à basculer
   * @returns {CustomFiltersManager} - Instance courante pour chaînage
   */
  toggleFilter(filterType) {
    if (this.state.activeFilters.has(filterType)) {
      this.state.activeFilters.delete(filterType);
    } else {
      this.state.activeFilters.add(filterType);
    }
    return this;
  }

  /**
   * Vérifie si un type de filtre est actif
   * @param {string} filterType - Type de filtre à vérifier
   * @returns {boolean} - true si le filtre est actif, false sinon
   */
  isFilterActive(filterType) {
    return this.state.activeFilters.has(filterType);
  }

  /**
   * Applique tous les filtres actifs
   * @returns {Object} - Éléments filtrés
   */
  applyFilters() {
    // Vérifier si les filtres sont initialisés
    if (!this.state.filtersInitialized) {
      console.error('Les filtres ne sont pas initialisés');
      return this.cy.elements();
    }

    // Commencer avec tous les éléments
    let filteredElements = this.cy.elements();

    // Appliquer les filtres dans l'ordre
    if (this.state.activeFilters.has('hierarchyLevel')) {
      filteredElements = this.hierarchyLevelFilter.applyFilter(filteredElements);
    }

    if (this.state.activeFilters.has('thematic')) {
      filteredElements = this.thematicFilter.applyFilter(filteredElements);
    }

    if (this.state.activeFilters.has('temporal')) {
      filteredElements = this.temporalFilter.applyFilter(filteredElements);
    }

    if (this.state.activeFilters.has('statusPriority')) {
      filteredElements = this.statusPriorityView.applyActiveView(filteredElements);
    }

    return filteredElements;
  }

  /**
   * Crée l'interface utilisateur pour tous les filtres
   * @param {string} containerId - ID du conteneur HTML (par défaut, celui des options)
   * @returns {CustomFiltersManager} - Instance courante pour chaînage
   */
  createUI(containerId = null) {
    // Utiliser le conteneur spécifié ou celui des options
    const container = document.getElementById(containerId || this.options.uiContainer);

    if (!container) {
      console.error(`Conteneur ${containerId || this.options.uiContainer} non trouvé`);
      return this;
    }

    // Vider le conteneur
    container.innerHTML = '';

    // Créer le titre
    const title = document.createElement('h2');
    title.textContent = 'Filtres personnalisés';
    container.appendChild(title);

    // Créer les conteneurs pour chaque type de filtre
    const hierarchyLevelContainer = document.createElement('div');
    hierarchyLevelContainer.id = 'hierarchy-level-filter-container';
    hierarchyLevelContainer.className = 'filter-container';
    container.appendChild(hierarchyLevelContainer);

    const thematicContainer = document.createElement('div');
    thematicContainer.id = 'thematic-filter-container';
    thematicContainer.className = 'filter-container';
    container.appendChild(thematicContainer);

    const temporalContainer = document.createElement('div');
    temporalContainer.id = 'temporal-filter-container';
    temporalContainer.className = 'filter-container';
    container.appendChild(temporalContainer);

    const statusPriorityContainer = document.createElement('div');
    statusPriorityContainer.id = 'status-priority-view-container';
    statusPriorityContainer.className = 'filter-container';
    container.appendChild(statusPriorityContainer);

    // Créer les interfaces utilisateur pour chaque filtre
    this.hierarchyLevelFilter.createUI('hierarchy-level-filter-container');
    this.thematicFilter.createUI('thematic-filter-container');
    this.temporalFilter.createUI('temporal-filter-container');
    this.statusPriorityView.createUI('status-priority-view-container');

    // Créer le bouton d'application des filtres
    const applyButton = document.createElement('button');
    applyButton.textContent = 'Appliquer les filtres';
    applyButton.className = 'apply-filters-button';

    applyButton.addEventListener('click', () => {
      // Appliquer les filtres
      const filteredElements = this.applyFilters();

      // Mettre à jour la visualisation
      this._updateVisualization(filteredElements);

      // Déclencher un événement personnalisé
      const event = new CustomEvent('customFiltersApplied', {
        detail: {
          filteredElements
        }
      });

      document.dispatchEvent(event);
    });

    container.appendChild(applyButton);

    // Créer le bouton de réinitialisation des filtres
    const resetButton = document.createElement('button');
    resetButton.textContent = 'Réinitialiser les filtres';
    resetButton.className = 'reset-filters-button';

    resetButton.addEventListener('click', () => {
      // Réinitialiser les filtres
      this.resetFilters();

      // Mettre à jour l'interface utilisateur
      this.createUI(containerId || this.options.uiContainer);

      // Mettre à jour la visualisation
      this._updateVisualization(this.cy.elements());

      // Déclencher un événement personnalisé
      const event = new CustomEvent('customFiltersReset');
      document.dispatchEvent(event);
    });

    container.appendChild(resetButton);

    return this;
  }

  /**
   * Réinitialise tous les filtres
   * @returns {CustomFiltersManager} - Instance courante pour chaînage
   */
  resetFilters() {
    // Réinitialiser les filtres
    this.hierarchyLevelFilter.initialize();
    this.thematicFilter.initialize();
    this.temporalFilter.initialize();
    this.statusPriorityView.deactivateView();

    return this;
  }

  /**
   * Met à jour la visualisation avec les éléments filtrés
   * @param {Object} filteredElements - Éléments filtrés
   * @private
   */
  _updateVisualization(filteredElements) {
    // Masquer tous les éléments
    this.cy.elements().addClass('filtered-out');

    // Afficher les éléments filtrés
    filteredElements.removeClass('filtered-out');

    // Mettre à jour le layout si nécessaire
    if (this.visualizer.updateLayout) {
      this.visualizer.updateLayout();
    }
  }

  /**
   * Enregistre les événements pour les filtres
   * @returns {CustomFiltersManager} - Instance courante pour chaînage
   */
  registerEvents() {
    // Événement pour le changement de filtre hiérarchique
    document.addEventListener('hierarchyLevelFilterChanged', (event) => {
      if (this.options.autoApply) {
        const filteredElements = this.applyFilters();
        this._updateVisualization(filteredElements);
      }
    });

    // Événement pour le changement de filtre thématique
    document.addEventListener('thematicFilterChanged', (event) => {
      if (this.options.autoApply) {
        const filteredElements = this.applyFilters();
        this._updateVisualization(filteredElements);
      }
    });

    // Événement pour le changement de filtre temporel
    document.addEventListener('temporalFilterChanged', (event) => {
      if (this.options.autoApply) {
        const filteredElements = this.applyFilters();
        this._updateVisualization(filteredElements);
      }
    });

    // Événement pour le changement de vue par statut et priorité
    document.addEventListener('statusPriorityViewChanged', (event) => {
      if (this.options.autoApply) {
        const filteredElements = this.applyFilters();
        this._updateVisualization(filteredElements);
      }
    });

    return this;
  }
}

// Exporter la classe
export default CustomFiltersManager;

