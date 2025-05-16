/**
 * Module de filtrage par niveau hiérarchique pour les roadmaps
 * Ce module permet de filtrer les éléments d'une roadmap par niveau hiérarchique
 *
 * Version: 1.0
 * Date: 2025-05-30
 */

/**
 * Classe pour le filtrage par niveau hiérarchique
 */
class HierarchyLevelFilter {
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
      // Niveaux hiérarchiques disponibles
      hierarchyLevels: [
        'cosmos',      // Méta-roadmap
        'galaxy',      // Branches stratégiques
        'stellar_system', // Main roadmaps
        'planet',      // Sections
        'continent',   // Sous-sections
        'region',      // Groupes de tâches
        'locality',    // Tâches
        'district',    // Sous-tâches
        'building',    // Actions
        'foundation'   // Micro-actions
      ],

      // Niveaux activés par défaut
      defaultActiveLevels: ['cosmos', 'galaxy', 'stellar_system', 'planet', 'continent'],

      // Autres options
      ...options
    };

    // État interne
    this.state = {
      activeLevels: new Set(this.options.defaultActiveLevels)
    };
  }

  /**
   * Initialise le filtre
   * @returns {HierarchyLevelFilter} - Instance courante pour chaînage
   */
  initialize() {
    // Initialiser l'état
    this.state.activeLevels = new Set(this.options.defaultActiveLevels);
    return this;
  }

  /**
   * Active un niveau hiérarchique
   * @param {string} level - Niveau à activer
   * @returns {HierarchyLevelFilter} - Instance courante pour chaînage
   */
  activateLevel(level) {
    if (this.options.hierarchyLevels.includes(level)) {
      this.state.activeLevels.add(level);
    }
    return this;
  }

  /**
   * Désactive un niveau hiérarchique
   * @param {string} level - Niveau à désactiver
   * @returns {HierarchyLevelFilter} - Instance courante pour chaînage
   */
  deactivateLevel(level) {
    this.state.activeLevels.delete(level);
    return this;
  }

  /**
   * Bascule l'état d'un niveau hiérarchique
   * @param {string} level - Niveau à basculer
   * @returns {HierarchyLevelFilter} - Instance courante pour chaînage
   */
  toggleLevel(level) {
    if (this.state.activeLevels.has(level)) {
      this.state.activeLevels.delete(level);
    } else if (this.options.hierarchyLevels.includes(level)) {
      this.state.activeLevels.add(level);
    }
    return this;
  }

  /**
   * Définit les niveaux actifs
   * @param {Array<string>} levels - Niveaux à activer
   * @returns {HierarchyLevelFilter} - Instance courante pour chaînage
   */
  setActiveLevels(levels) {
    this.state.activeLevels.clear();

    for (const level of levels) {
      if (this.options.hierarchyLevels.includes(level)) {
        this.state.activeLevels.add(level);
      }
    }

    return this;
  }

  /**
   * Obtient les niveaux actifs
   * @returns {Array<string>} - Niveaux actifs
   */
  getActiveLevels() {
    return Array.from(this.state.activeLevels);
  }

  /**
   * Vérifie si un niveau est actif
   * @param {string} level - Niveau à vérifier
   * @returns {boolean} - true si le niveau est actif, false sinon
   */
  isLevelActive(level) {
    return this.state.activeLevels.has(level);
  }

  /**
   * Applique le filtre sur les éléments
   * @param {Object} elements - Éléments à filtrer (par défaut, tous les éléments)
   * @returns {Object} - Éléments filtrés
   */
  applyFilter(elements = null) {
    // Si aucun élément n'est spécifié, utiliser tous les éléments
    if (!elements) {
      elements = this.cy.elements();
    }

    // Si aucun niveau n'est actif, retourner un ensemble vide
    if (this.state.activeLevels.size === 0) {
      return this.cy.collection();
    }

    // Filtrer les nœuds par niveau
    const filteredNodes = elements.nodes().filter(node => {
      const nodeType = node.data('type');
      return this.state.activeLevels.has(nodeType);
    });

    // Inclure les arêtes connectées aux nœuds filtrés
    const connectedEdges = filteredNodes.edgesWith(filteredNodes);

    return filteredNodes.union(connectedEdges);
  }

  /**
   * Crée l'interface utilisateur pour le filtre
   * @param {string} containerId - ID du conteneur HTML
   * @returns {HierarchyLevelFilter} - Instance courante pour chaînage
   */
  createUI(containerId) {
    const container = document.getElementById(containerId);

    if (!container) {
      console.error(`Conteneur ${containerId} non trouvé`);
      return this;
    }

    // Créer le titre
    const title = document.createElement('h3');
    title.textContent = 'Filtres par niveau hiérarchique';
    container.appendChild(title);

    // Créer le conteneur des checkboxes
    const checkboxContainer = document.createElement('div');
    checkboxContainer.className = 'hierarchy-level-filter-checkboxes';
    container.appendChild(checkboxContainer);

    // Créer une checkbox pour chaque niveau
    for (const level of this.options.hierarchyLevels) {
      const checkboxDiv = document.createElement('div');
      checkboxDiv.className = 'hierarchy-level-filter-checkbox';

      const checkbox = document.createElement('input');
      checkbox.type = 'checkbox';
      checkbox.id = `hierarchy-level-filter-${level}`;
      checkbox.checked = this.state.activeLevels.has(level);

      checkbox.addEventListener('change', () => {
        this.toggleLevel(level);

        // Déclencher un événement personnalisé
        const event = new CustomEvent('hierarchyLevelFilterChanged', {
          detail: {
            level,
            active: checkbox.checked,
            activeLevels: this.getActiveLevels()
          }
        });

        document.dispatchEvent(event);
      });

      const label = document.createElement('label');
      label.htmlFor = checkbox.id;
      label.textContent = this._formatLevelName(level);

      checkboxDiv.appendChild(checkbox);
      checkboxDiv.appendChild(label);
      checkboxContainer.appendChild(checkboxDiv);
    }

    return this;
  }

  /**
   * Formate le nom d'un niveau pour l'affichage
   * @param {string} level - Niveau à formater
   * @returns {string} - Nom formaté
   * @private
   */
  _formatLevelName(level) {
    // Remplacer les underscores par des espaces et mettre en majuscule la première lettre
    return level
      .replace(/_/g, ' ')
      .replace(/\b\w/g, l => l.toUpperCase());
  }
}

// Exporter la classe
export default HierarchyLevelFilter;
