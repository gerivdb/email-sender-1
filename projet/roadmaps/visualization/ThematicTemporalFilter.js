/**
 * Module de filtrage thématique et temporel pour les roadmaps
 * Ce module permet de filtrer les éléments d'une roadmap par thème et période temporelle
 *
 * Version: 1.0
 * Date: 2025-05-30
 */

/**
 * Classe pour le filtrage thématique
 */
class ThematicFilter {
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
      // Thèmes disponibles (à charger dynamiquement)
      availableThemes: [],

      // Thèmes activés par défaut (tous)
      defaultActiveThemes: [],

      // Champ contenant les thèmes dans les données des nœuds
      themeField: 'metadata.themes',

      // Autres options
      ...options
    };

    // État interne
    this.state = {
      activeThemes: new Set(this.options.defaultActiveThemes),
      availableThemes: []
    };
  }

  /**
   * Initialise le filtre
   * @returns {ThematicFilter} - Instance courante pour chaînage
   */
  async initialize() {
    // Charger les thèmes disponibles
    await this._loadAvailableThemes();

    // Initialiser l'état
    this.state.activeThemes = new Set(
      this.options.defaultActiveThemes.length > 0
        ? this.options.defaultActiveThemes
        : this.state.availableThemes
    );

    return this;
  }

  /**
   * Charge les thèmes disponibles à partir des données
   * @returns {Promise<void>}
   * @private
   */
  async _loadAvailableThemes() {
    // Si des thèmes sont fournis dans les options, les utiliser
    if (this.options.availableThemes.length > 0) {
      this.state.availableThemes = [...this.options.availableThemes];
      return;
    }

    // Sinon, extraire les thèmes des nœuds
    const themes = new Set();

    try {
      // Vérifier si cy.nodes() est disponible
      if (this.cy && typeof this.cy.nodes === 'function') {
        this.cy.nodes().forEach(node => {
          const nodeThemes = this._getNodeThemes(node);

          for (const theme of nodeThemes) {
            themes.add(theme);
          }
        });
      }
    } catch (error) {
      console.warn('Erreur lors de l\'extraction des thèmes des nœuds:', error);
    }

    this.state.availableThemes = Array.from(themes).sort();
  }

  /**
   * Obtient les thèmes d'un nœud
   * @param {Object} node - Nœud
   * @returns {Array<string>} - Thèmes du nœud
   * @private
   */
  _getNodeThemes(node) {
    // Accéder au champ des thèmes en suivant le chemin spécifié
    const path = this.options.themeField.split('.');
    let value = node.data();

    for (const key of path) {
      if (value && typeof value === 'object' && key in value) {
        value = value[key];
      } else {
        return [];
      }
    }

    // Convertir en tableau si c'est un objet
    if (value && typeof value === 'object' && !Array.isArray(value)) {
      return Object.keys(value);
    }

    // Retourner un tableau vide si la valeur n'est pas un tableau
    return Array.isArray(value) ? value : [];
  }

  /**
   * Active un thème
   * @param {string} theme - Thème à activer
   * @returns {ThematicFilter} - Instance courante pour chaînage
   */
  activateTheme(theme) {
    this.state.activeThemes.add(theme);
    return this;
  }

  /**
   * Désactive un thème
   * @param {string} theme - Thème à désactiver
   * @returns {ThematicFilter} - Instance courante pour chaînage
   */
  deactivateTheme(theme) {
    this.state.activeThemes.delete(theme);
    return this;
  }

  /**
   * Bascule l'état d'un thème
   * @param {string} theme - Thème à basculer
   * @returns {ThematicFilter} - Instance courante pour chaînage
   */
  toggleTheme(theme) {
    if (this.state.activeThemes.has(theme)) {
      this.state.activeThemes.delete(theme);
    } else {
      this.state.activeThemes.add(theme);
    }
    return this;
  }

  /**
   * Définit les thèmes actifs
   * @param {Array<string>} themes - Thèmes à activer
   * @returns {ThematicFilter} - Instance courante pour chaînage
   */
  setActiveThemes(themes) {
    this.state.activeThemes = new Set(themes);
    return this;
  }

  /**
   * Obtient les thèmes actifs
   * @returns {Array<string>} - Thèmes actifs
   */
  getActiveThemes() {
    return Array.from(this.state.activeThemes);
  }

  /**
   * Vérifie si un thème est actif
   * @param {string} theme - Thème à vérifier
   * @returns {boolean} - true si le thème est actif, false sinon
   */
  isThemeActive(theme) {
    return this.state.activeThemes.has(theme);
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

    // Si aucun thème n'est actif ou tous les thèmes sont actifs, ne pas filtrer
    if (this.state.activeThemes.size === 0 ||
        this.state.activeThemes.size === this.state.availableThemes.length) {
      return elements;
    }

    // Filtrer les nœuds par thème
    const filteredNodes = elements.nodes().filter(node => {
      const nodeThemes = this._getNodeThemes(node);

      // Un nœud est inclus s'il a au moins un thème actif
      return nodeThemes.some(theme => this.state.activeThemes.has(theme));
    });

    // Inclure les arêtes connectées aux nœuds filtrés
    const connectedEdges = filteredNodes.edgesWith(filteredNodes);

    return filteredNodes.union(connectedEdges);
  }

  /**
   * Crée l'interface utilisateur pour le filtre
   * @param {string} containerId - ID du conteneur HTML
   * @returns {ThematicFilter} - Instance courante pour chaînage
   */
  createUI(containerId) {
    const container = document.getElementById(containerId);

    if (!container) {
      console.error(`Conteneur ${containerId} non trouvé`);
      return this;
    }

    // Créer le titre
    const title = document.createElement('h3');
    title.textContent = 'Filtres thématiques';
    container.appendChild(title);

    // Créer le conteneur des checkboxes
    const checkboxContainer = document.createElement('div');
    checkboxContainer.className = 'thematic-filter-checkboxes';
    container.appendChild(checkboxContainer);

    // Créer une checkbox pour chaque thème
    for (const theme of this.state.availableThemes) {
      const checkboxDiv = document.createElement('div');
      checkboxDiv.className = 'thematic-filter-checkbox';

      const checkbox = document.createElement('input');
      checkbox.type = 'checkbox';
      checkbox.id = `thematic-filter-${theme}`;
      checkbox.checked = this.state.activeThemes.has(theme);

      checkbox.addEventListener('change', () => {
        this.toggleTheme(theme);

        // Déclencher un événement personnalisé
        const event = new CustomEvent('thematicFilterChanged', {
          detail: {
            theme,
            active: checkbox.checked,
            activeThemes: this.getActiveThemes()
          }
        });

        document.dispatchEvent(event);
      });

      const label = document.createElement('label');
      label.htmlFor = checkbox.id;
      label.textContent = theme;

      checkboxDiv.appendChild(checkbox);
      checkboxDiv.appendChild(label);
      checkboxContainer.appendChild(checkboxDiv);
    }

    return this;
  }
}

/**
 * Classe pour le filtrage temporel
 */
class TemporalFilter {
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
      // Champ contenant les informations temporelles dans les données des nœuds
      temporalField: 'metadata.temporal',

      // Horizons temporels disponibles
      horizons: [
        'immediate',    // Immédiat (< 1 mois)
        'short_term',   // Court terme (1-3 mois)
        'medium_term',  // Moyen terme (3-12 mois)
        'long_term',    // Long terme (1-3 ans)
        'strategic'     // Stratégique (> 3 ans)
      ],

      // Horizons activés par défaut (tous)
      defaultActiveHorizons: [],

      // Autres options
      ...options
    };

    // État interne
    this.state = {
      activeHorizons: new Set(
        this.options.defaultActiveHorizons.length > 0
          ? this.options.defaultActiveHorizons
          : this.options.horizons
      )
    };
  }

  /**
   * Initialise le filtre
   * @returns {TemporalFilter} - Instance courante pour chaînage
   */
  initialize() {
    // Initialiser l'état
    this.state.activeHorizons = new Set(
      this.options.defaultActiveHorizons.length > 0
        ? this.options.defaultActiveHorizons
        : this.options.horizons
    );

    return this;
  }

  /**
   * Obtient l'horizon temporel d'un nœud
   * @param {Object} node - Nœud
   * @returns {string|null} - Horizon temporel du nœud
   * @private
   */
  _getNodeHorizon(node) {
    // Accéder au champ temporel en suivant le chemin spécifié
    const path = this.options.temporalField.split('.');
    let value = node.data();

    for (const key of path) {
      if (value && typeof value === 'object' && key in value) {
        value = value[key];
      } else {
        return null;
      }
    }

    // Si la valeur est un objet avec un champ 'horizon', l'utiliser
    if (value && typeof value === 'object' && 'horizon' in value) {
      return value.horizon;
    }

    // Sinon, retourner la valeur directement si c'est une chaîne
    return typeof value === 'string' ? value : null;
  }

  /**
   * Active un horizon temporel
   * @param {string} horizon - Horizon à activer
   * @returns {TemporalFilter} - Instance courante pour chaînage
   */
  activateHorizon(horizon) {
    if (this.options.horizons.includes(horizon)) {
      this.state.activeHorizons.add(horizon);
    }
    return this;
  }

  /**
   * Désactive un horizon temporel
   * @param {string} horizon - Horizon à désactiver
   * @returns {TemporalFilter} - Instance courante pour chaînage
   */
  deactivateHorizon(horizon) {
    this.state.activeHorizons.delete(horizon);
    return this;
  }

  /**
   * Bascule l'état d'un horizon temporel
   * @param {string} horizon - Horizon à basculer
   * @returns {TemporalFilter} - Instance courante pour chaînage
   */
  toggleHorizon(horizon) {
    if (this.state.activeHorizons.has(horizon)) {
      this.state.activeHorizons.delete(horizon);
    } else if (this.options.horizons.includes(horizon)) {
      this.state.activeHorizons.add(horizon);
    }
    return this;
  }

  /**
   * Définit les horizons actifs
   * @param {Array<string>} horizons - Horizons à activer
   * @returns {TemporalFilter} - Instance courante pour chaînage
   */
  setActiveHorizons(horizons) {
    this.state.activeHorizons.clear();

    for (const horizon of horizons) {
      if (this.options.horizons.includes(horizon)) {
        this.state.activeHorizons.add(horizon);
      }
    }

    return this;
  }

  /**
   * Obtient les horizons actifs
   * @returns {Array<string>} - Horizons actifs
   */
  getActiveHorizons() {
    return Array.from(this.state.activeHorizons);
  }

  /**
   * Vérifie si un horizon est actif
   * @param {string} horizon - Horizon à vérifier
   * @returns {boolean} - true si l'horizon est actif, false sinon
   */
  isHorizonActive(horizon) {
    return this.state.activeHorizons.has(horizon);
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

    // Si aucun horizon n'est actif ou tous les horizons sont actifs, ne pas filtrer
    if (this.state.activeHorizons.size === 0 ||
        this.state.activeHorizons.size === this.options.horizons.length) {
      return elements;
    }

    // Filtrer les nœuds par horizon temporel
    const filteredNodes = elements.nodes().filter(node => {
      const nodeHorizon = this._getNodeHorizon(node);

      // Si le nœud n'a pas d'horizon, l'inclure par défaut
      if (!nodeHorizon) {
        return true;
      }

      return this.state.activeHorizons.has(nodeHorizon);
    });

    // Inclure les arêtes connectées aux nœuds filtrés
    const connectedEdges = filteredNodes.edgesWith(filteredNodes);

    return filteredNodes.union(connectedEdges);
  }

  /**
   * Crée l'interface utilisateur pour le filtre
   * @param {string} containerId - ID du conteneur HTML
   * @returns {TemporalFilter} - Instance courante pour chaînage
   */
  createUI(containerId) {
    const container = document.getElementById(containerId);

    if (!container) {
      console.error(`Conteneur ${containerId} non trouvé`);
      return this;
    }

    // Créer le titre
    const title = document.createElement('h3');
    title.textContent = 'Filtres temporels';
    container.appendChild(title);

    // Créer le conteneur des checkboxes
    const checkboxContainer = document.createElement('div');
    checkboxContainer.className = 'temporal-filter-checkboxes';
    container.appendChild(checkboxContainer);

    // Créer une checkbox pour chaque horizon
    for (const horizon of this.options.horizons) {
      const checkboxDiv = document.createElement('div');
      checkboxDiv.className = 'temporal-filter-checkbox';

      const checkbox = document.createElement('input');
      checkbox.type = 'checkbox';
      checkbox.id = `temporal-filter-${horizon}`;
      checkbox.checked = this.state.activeHorizons.has(horizon);

      checkbox.addEventListener('change', () => {
        this.toggleHorizon(horizon);

        // Déclencher un événement personnalisé
        const event = new CustomEvent('temporalFilterChanged', {
          detail: {
            horizon,
            active: checkbox.checked,
            activeHorizons: this.getActiveHorizons()
          }
        });

        document.dispatchEvent(event);
      });

      const label = document.createElement('label');
      label.htmlFor = checkbox.id;
      label.textContent = this._formatHorizonName(horizon);

      checkboxDiv.appendChild(checkbox);
      checkboxDiv.appendChild(label);
      checkboxContainer.appendChild(checkboxDiv);
    }

    return this;
  }

  /**
   * Formate le nom d'un horizon pour l'affichage
   * @param {string} horizon - Horizon à formater
   * @returns {string} - Nom formaté
   * @private
   */
  _formatHorizonName(horizon) {
    // Remplacer les underscores par des espaces et mettre en majuscule la première lettre
    return horizon
      .replace(/_/g, ' ')
      .replace(/\b\w/g, l => l.toUpperCase());
  }
}

// Exporter les classes
export { ThematicFilter, TemporalFilter };
