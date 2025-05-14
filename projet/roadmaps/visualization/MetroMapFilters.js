/**
 * MetroMapFilters.js
 * Module de filtrage pour la visualisation en carte de métro
 *
 * Ce module fournit des fonctionnalités de filtrage avancées pour la visualisation
 * des roadmaps en carte de métro, notamment le filtrage par statut, par roadmap,
 * par niveau, et par recherche textuelle.
 *
 * Version: 1.0
 * Date: 2025-05-15
 */

/**
 * Classe principale pour le filtrage des cartes de métro
 */
class MetroMapFilters {
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
      // Options de filtrage par statut
      statusFilters: {
        enabled: true,
        statuses: ['completed', 'in_progress', 'planned']
      },

      // Options de filtrage par roadmap
      roadmapFilters: {
        enabled: true
      },

      // Options de filtrage par niveau
      levelFilters: {
        enabled: true,
        levels: ['cosmos', 'galaxy', 'system', 'planet', 'continent']
      },

      // Options de recherche textuelle
      textSearch: {
        enabled: true,
        searchFields: ['label', 'description', 'id'],
        minLength: 2,
        highlightResults: true,
        highlightColor: '#FFC107',
        caseSensitive: false
      },

      // Options de filtrage avancé
      advancedFilters: {
        enabled: true,
        operators: ['equals', 'contains', 'startsWith', 'endsWith', 'regex'],
        fields: ['label', 'description', 'id', 'status', 'roadmapId']
      },

      // Fusionner avec les options fournies
      ...options
    };

    // État interne
    this.state = {
      activeStatusFilters: new Set(this.options.statusFilters.statuses),
      activeRoadmapFilters: new Set(),
      activeLevelFilters: new Set(this.options.levelFilters.levels),
      searchQuery: '',
      advancedFilters: [],
      filteredElements: null,
      originalElementsState: new Map(), // Pour stocker l'état original des éléments
      highlightedElements: new Set() // Pour stocker les éléments mis en évidence
    };
  }

  /**
   * Applique tous les filtres actifs
   * @returns {Object} - Éléments filtrés
   */
  applyFilters() {
    // Réinitialiser l'état des éléments
    this._resetElementsState();

    // Appliquer les filtres dans l'ordre
    let filteredElements = this.cy.elements();

    // 1. Filtrer par statut
    if (this.options.statusFilters.enabled && this.state.activeStatusFilters.size > 0) {
      filteredElements = this._filterByStatus(filteredElements);
    }

    // 2. Filtrer par roadmap
    if (this.options.roadmapFilters.enabled && this.state.activeRoadmapFilters.size > 0) {
      filteredElements = this._filterByRoadmap(filteredElements);
    }

    // 3. Filtrer par niveau
    if (this.options.levelFilters.enabled && this.state.activeLevelFilters.size > 0) {
      filteredElements = this._filterByLevel(filteredElements);
    }

    // 4. Filtrer par recherche textuelle
    if (this.options.textSearch.enabled && this.state.searchQuery.length >= this.options.textSearch.minLength) {
      filteredElements = this._filterByText(filteredElements);
    }

    // 5. Filtrer par filtres avancés
    if (this.options.advancedFilters.enabled && this.state.advancedFilters.length > 0) {
      filteredElements = this._filterByAdvancedFilters(filteredElements);
    }

    // Mettre à jour l'état
    this.state.filteredElements = filteredElements;

    // Appliquer les filtres visuellement
    this._applyVisualFilters();

    return filteredElements;
  }

  /**
   * Réinitialise tous les filtres
   */
  resetFilters() {
    // Réinitialiser l'état des filtres
    this.state.activeStatusFilters = new Set(this.options.statusFilters.statuses);
    this.state.activeRoadmapFilters = new Set();
    this.state.activeLevelFilters = new Set(this.options.levelFilters.levels);
    this.state.searchQuery = '';
    this.state.advancedFilters = [];

    // Réinitialiser l'état des éléments
    this._resetElementsState();

    // Mettre à jour l'état
    this.state.filteredElements = this.cy.elements();

    // Appliquer les filtres visuellement
    this._applyVisualFilters();

    return this.cy.elements();
  }

  /**
   * Définit les filtres de statut actifs
   * @param {Array<string>} statuses - Statuts à activer
   */
  setStatusFilters(statuses) {
    this.state.activeStatusFilters = new Set(statuses);
    return this.applyFilters();
  }

  /**
   * Définit les filtres de roadmap actifs
   * @param {Array<string>} roadmapIds - IDs des roadmaps à activer
   */
  setRoadmapFilters(roadmapIds) {
    this.state.activeRoadmapFilters = new Set(roadmapIds);
    return this.applyFilters();
  }

  /**
   * Définit les filtres de niveau actifs
   * @param {Array<string>} levels - Niveaux à activer
   */
  setLevelFilters(levels) {
    this.state.activeLevelFilters = new Set(levels);
    return this.applyFilters();
  }

  /**
   * Définit la requête de recherche textuelle
   * @param {string} query - Requête de recherche
   */
  setSearchQuery(query) {
    this.state.searchQuery = query;
    return this.applyFilters();
  }

  /**
   * Définit les filtres avancés
   * @param {Array<Object>} filters - Filtres avancés
   */
  setAdvancedFilters(filters) {
    this.state.advancedFilters = filters;
    return this.applyFilters();
  }

  /**
   * Filtre les éléments par statut
   * @param {Object} elements - Éléments Cytoscape à filtrer
   * @returns {Object} - Éléments filtrés
   * @private
   */
  _filterByStatus(elements) {
    // Si tous les statuts sont actifs, ne pas filtrer
    if (this.state.activeStatusFilters.size === this.options.statusFilters.statuses.length) {
      return elements;
    }

    // Filtrer les nœuds par statut
    const filteredNodes = elements.nodes().filter(node => {
      const status = node.data('status');
      return this.state.activeStatusFilters.has(status);
    });

    // Inclure les arêtes connectées aux nœuds filtrés
    const connectedEdges = filteredNodes.edgesWith(filteredNodes);

    return filteredNodes.union(connectedEdges);
  }

  /**
   * Filtre les éléments par roadmap
   * @param {Object} elements - Éléments Cytoscape à filtrer
   * @returns {Object} - Éléments filtrés
   * @private
   */
  _filterByRoadmap(elements) {
    // Si aucune roadmap n'est sélectionnée, ne pas filtrer
    if (this.state.activeRoadmapFilters.size === 0) {
      return elements;
    }

    // Filtrer les éléments par roadmap
    return elements.filter(element => {
      const roadmapId = element.data('roadmapId');
      return this.state.activeRoadmapFilters.has(roadmapId);
    });
  }

  /**
   * Filtre les éléments par niveau
   * @param {Object} elements - Éléments Cytoscape à filtrer
   * @returns {Object} - Éléments filtrés
   * @private
   */
  _filterByLevel(elements) {
    // Si tous les niveaux sont actifs, ne pas filtrer
    if (this.state.activeLevelFilters.size === this.options.levelFilters.levels.length) {
      return elements;
    }

    // Filtrer les nœuds par niveau
    const filteredNodes = elements.nodes().filter(node => {
      const level = node.data('level');

      // Si le nœud n'a pas de niveau défini, le considérer comme valide
      if (level === undefined) {
        return true;
      }

      return this.state.activeLevelFilters.has(level);
    });

    // Inclure les arêtes connectées aux nœuds filtrés
    const connectedEdges = filteredNodes.edgesWith(filteredNodes);

    return filteredNodes.union(connectedEdges);
  }

  /**
   * Filtre les éléments par recherche textuelle
   * @param {Object} elements - Éléments Cytoscape à filtrer
   * @returns {Object} - Éléments filtrés
   * @private
   */
  _filterByText(elements) {
    // Si la requête est vide, ne pas filtrer
    if (!this.state.searchQuery || this.state.searchQuery.length < this.options.textSearch.minLength) {
      return elements;
    }

    // Préparer la requête
    const query = this.options.textSearch.caseSensitive
      ? this.state.searchQuery
      : this.state.searchQuery.toLowerCase();

    // Filtrer les nœuds par texte
    const filteredNodes = elements.nodes().filter(node => {
      // Vérifier chaque champ de recherche
      for (const field of this.options.textSearch.searchFields) {
        const value = node.data(field);

        if (value) {
          const textValue = this.options.textSearch.caseSensitive
            ? value.toString()
            : value.toString().toLowerCase();

          if (textValue.includes(query)) {
            // Mettre en évidence le nœud si l'option est activée
            if (this.options.textSearch.highlightResults) {
              this.state.highlightedElements.add(node.id());
            }

            return true;
          }
        }
      }

      return false;
    });

    // Inclure les arêtes connectées aux nœuds filtrés
    const connectedEdges = filteredNodes.edgesWith(filteredNodes);

    return filteredNodes.union(connectedEdges);
  }

  /**
   * Filtre les éléments par filtres avancés
   * @param {Object} elements - Éléments Cytoscape à filtrer
   * @returns {Object} - Éléments filtrés
   * @private
   */
  _filterByAdvancedFilters(elements) {
    // Si aucun filtre avancé n'est défini, ne pas filtrer
    if (this.state.advancedFilters.length === 0) {
      return elements;
    }

    // Filtrer les nœuds par filtres avancés
    const filteredNodes = elements.nodes().filter(node => {
      // Vérifier chaque filtre
      for (const filter of this.state.advancedFilters) {
        const { field, operator, value } = filter;
        const nodeValue = node.data(field);

        if (nodeValue === undefined) {
          continue;
        }

        const stringValue = nodeValue.toString();
        const filterValue = value.toString();

        // Appliquer l'opérateur
        switch (operator) {
          case 'equals':
            if (stringValue !== filterValue) {
              return false;
            }
            break;
          case 'contains':
            if (!stringValue.includes(filterValue)) {
              return false;
            }
            break;
          case 'startsWith':
            if (!stringValue.startsWith(filterValue)) {
              return false;
            }
            break;
          case 'endsWith':
            if (!stringValue.endsWith(filterValue)) {
              return false;
            }
            break;
          case 'regex':
            try {
              const regex = new RegExp(filterValue);
              if (!regex.test(stringValue)) {
                return false;
              }
            } catch (error) {
              console.error('Erreur lors de la création de l\'expression régulière:', error);
              return false;
            }
            break;
        }
      }

      return true;
    });

    // Inclure les arêtes connectées aux nœuds filtrés
    const connectedEdges = filteredNodes.edgesWith(filteredNodes);

    return filteredNodes.union(connectedEdges);
  }

  /**
   * Réinitialise l'état des éléments
   * @private
   */
  _resetElementsState() {
    // Sauvegarder l'état original des éléments si ce n'est pas déjà fait
    if (this.state.originalElementsState.size === 0) {
      this.cy.elements().forEach(element => {
        this.state.originalElementsState.set(element.id(), {
          visible: element.visible(),
          style: {
            opacity: element.style('opacity'),
            'background-color': element.style('background-color'),
            'line-color': element.style('line-color'),
            'border-color': element.style('border-color')
          }
        });
      });
    }

    // Réinitialiser l'état des éléments
    this.cy.elements().forEach(element => {
      const originalState = this.state.originalElementsState.get(element.id());

      if (originalState) {
        element.style({
          'opacity': originalState.style.opacity,
          'background-color': originalState.style['background-color'],
          'line-color': originalState.style['line-color'],
          'border-color': originalState.style['border-color']
        });

        element.style('visibility', 'visible');
      }
    });

    // Réinitialiser les éléments mis en évidence
    this.state.highlightedElements.clear();
  }

  /**
   * Applique les filtres visuellement
   * @private
   */
  _applyVisualFilters() {
    // Si aucun élément n'est filtré, ne rien faire
    if (!this.state.filteredElements) {
      return;
    }

    // Masquer les éléments qui ne sont pas dans les résultats filtrés
    this.cy.elements().forEach(element => {
      if (!this.state.filteredElements.contains(element)) {
        element.style('visibility', 'hidden');
      }
    });

    // Mettre en évidence les éléments correspondant à la recherche textuelle
    if (this.options.textSearch.highlightResults) {
      this.state.highlightedElements.forEach(elementId => {
        const element = this.cy.getElementById(elementId);

        if (element.isNode()) {
          element.style({
            'background-color': this.options.textSearch.highlightColor,
            'border-color': this.options.textSearch.highlightColor,
            'border-width': 3
          });
        } else if (element.isEdge()) {
          element.style({
            'line-color': this.options.textSearch.highlightColor,
            'width': 5
          });
        }
      });
    }
  }
}

// Exporter la classe
export default MetroMapFilters;
