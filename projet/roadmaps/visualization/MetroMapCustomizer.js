/**
 * MetroMapCustomizer.js
 * Module de personnalisation pour la visualisation en carte de métro
 *
 * Ce module fournit des fonctionnalités de personnalisation avancées pour la visualisation
 * des roadmaps en carte de métro, notamment la personnalisation des couleurs, des formes,
 * des styles, et des thèmes.
 *
 * Version: 1.0
 * Date: 2025-05-15
 */

/**
 * Classe principale pour la personnalisation des cartes de métro
 */
class MetroMapCustomizer {
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
      // Options de thème
      themes: {
        default: {
          name: 'Défaut',
          background: '#ffffff',
          nodeColors: {
            completed: '#4CAF50',
            in_progress: '#2196F3',
            planned: '#9E9E9E'
          },
          nodeBorderColors: {
            completed: '#2E7D32',
            in_progress: '#1565C0',
            planned: '#616161'
          },
          edgeColors: {
            default: '#666666'
          },
          fontFamily: 'Segoe UI, Tahoma, Geneva, Verdana, sans-serif',
          fontSize: 12
        },
        dark: {
          name: 'Sombre',
          background: '#333333',
          nodeColors: {
            completed: '#81C784',
            in_progress: '#64B5F6',
            planned: '#E0E0E0'
          },
          nodeBorderColors: {
            completed: '#4CAF50',
            in_progress: '#2196F3',
            planned: '#9E9E9E'
          },
          edgeColors: {
            default: '#BBBBBB'
          },
          fontFamily: 'Segoe UI, Tahoma, Geneva, Verdana, sans-serif',
          fontSize: 12,
          textColor: '#FFFFFF'
        },
        colorful: {
          name: 'Coloré',
          background: '#F5F5F5',
          nodeColors: {
            completed: '#FF6B6B',
            in_progress: '#4ECDC4',
            planned: '#F9C74F'
          },
          nodeBorderColors: {
            completed: '#FF5252',
            in_progress: '#26A69A',
            planned: '#F4A236'
          },
          edgeColors: {
            default: '#666666'
          },
          fontFamily: 'Segoe UI, Tahoma, Geneva, Verdana, sans-serif',
          fontSize: 12
        },
        minimal: {
          name: 'Minimal',
          background: '#FFFFFF',
          nodeColors: {
            completed: '#EEEEEE',
            in_progress: '#EEEEEE',
            planned: '#EEEEEE'
          },
          nodeBorderColors: {
            completed: '#4CAF50',
            in_progress: '#2196F3',
            planned: '#9E9E9E'
          },
          edgeColors: {
            default: '#CCCCCC'
          },
          fontFamily: 'Segoe UI, Tahoma, Geneva, Verdana, sans-serif',
          fontSize: 12,
          borderWidth: 3
        }
      },

      // Options de forme des nœuds
      nodeShapes: {
        default: 'ellipse',
        completed: 'ellipse',
        in_progress: 'ellipse',
        planned: 'ellipse',
        custom: {}
      },

      // Options de taille des nœuds
      nodeSizes: {
        default: 30,
        completed: 30,
        in_progress: 30,
        planned: 30,
        custom: {}
      },

      // Options de style des arêtes
      edgeStyles: {
        default: 'solid',
        types: {
          solid: {
            'line-style': 'solid'
          },
          dashed: {
            'line-style': 'dashed',
            'line-dash-pattern': [6, 3]
          },
          dotted: {
            'line-style': 'dotted',
            'line-dash-pattern': [1, 3]
          }
        }
      },

      // Options de style des étiquettes
      labelStyles: {
        position: 'center',
        fontWeight: 'normal',
        textTransform: 'none',
        textWrap: 'ellipsis',
        textMaxWidth: 100
      },

      // Fusionner avec les options fournies
      ...options
    };

    // État interne
    this.state = {
      currentTheme: 'default',
      customNodeStyles: new Map(), // Styles personnalisés par nœud
      customEdgeStyles: new Map(), // Styles personnalisés par arête
      customGlobalStyles: {} // Styles personnalisés globaux
    };

    // Appliquer le thème par défaut
    this.applyTheme(this.state.currentTheme);
  }

  /**
   * Applique un thème prédéfini
   * @param {string} themeName - Nom du thème à appliquer
   */
  applyTheme(themeName) {
    // Vérifier si le thème existe
    if (!this.options.themes[themeName]) {
      console.error(`Le thème "${themeName}" n'existe pas.`);
      return;
    }

    // Mettre à jour l'état
    this.state.currentTheme = themeName;

    // Récupérer le thème
    const theme = this.options.themes[themeName];

    // Appliquer le thème au conteneur
    const container = this.cy.container();
    container.style.backgroundColor = theme.background;

    // Appliquer le thème aux éléments Cytoscape
    this.cy.style()
      // Styles pour les nœuds
      .selector('node')
      .style({
        'background-color': theme.nodeColors.planned,
        'border-color': theme.nodeBorderColors.planned,
        'border-width': theme.borderWidth || 2,
        'shape': this.options.nodeShapes.default,
        'width': this.options.nodeSizes.default,
        'height': this.options.nodeSizes.default,
        'font-family': theme.fontFamily,
        'font-size': theme.fontSize,
        'color': theme.textColor || '#000000',
        'text-valign': this.options.labelStyles.position,
        'text-halign': this.options.labelStyles.position,
        'font-weight': this.options.labelStyles.fontWeight,
        'text-transform': this.options.labelStyles.textTransform,
        'text-wrap': this.options.labelStyles.textWrap,
        'text-max-width': this.options.labelStyles.textMaxWidth
      })

      // Styles pour les nœuds complétés
      .selector('node[status="completed"]')
      .style({
        'background-color': theme.nodeColors.completed,
        'border-color': theme.nodeBorderColors.completed,
        'shape': this.options.nodeShapes.completed
      })

      // Styles pour les nœuds en cours
      .selector('node[status="in_progress"]')
      .style({
        'background-color': theme.nodeColors.in_progress,
        'border-color': theme.nodeBorderColors.in_progress,
        'shape': this.options.nodeShapes.in_progress
      })

      // Styles pour les arêtes
      .selector('edge')
      .style({
        'width': 3,
        'line-color': theme.edgeColors.default,
        'target-arrow-color': theme.edgeColors.default,
        'source-arrow-color': theme.edgeColors.default,
        'curve-style': 'bezier',
        'line-style': this.options.edgeStyles.default
      })

      // Appliquer les styles
      .update();

    // Appliquer les styles personnalisés
    this._applyCustomStyles();

    // Déclencher un événement de changement de thème
    this._triggerEvent('themeChange', { theme: themeName });

    return this;
  }

  /**
   * Définit la forme des nœuds
   * @param {string} shape - Forme à appliquer ('ellipse', 'rectangle', 'triangle', 'diamond', etc.)
   * @param {string} status - Statut des nœuds à modifier (optionnel)
   */
  setNodeShape(shape, status) {
    // Vérifier si la forme est valide
    const validShapes = ['ellipse', 'rectangle', 'triangle', 'diamond', 'pentagon', 'hexagon', 'octagon', 'star', 'barrel'];

    if (!validShapes.includes(shape)) {
      console.error(`La forme "${shape}" n'est pas valide.`);
      return this;
    }

    // Mettre à jour les options
    if (status) {
      this.options.nodeShapes[status] = shape;
    } else {
      this.options.nodeShapes.default = shape;

      // Mettre à jour toutes les formes si aucun statut n'est spécifié
      for (const status of ['completed', 'in_progress', 'planned']) {
        this.options.nodeShapes[status] = shape;
      }
    }

    // Appliquer les changements
    this._applyNodeShapes();

    return this;
  }

  /**
   * Définit la taille des nœuds
   * @param {number} size - Taille à appliquer
   * @param {string} status - Statut des nœuds à modifier (optionnel)
   */
  setNodeSize(size, status) {
    // Vérifier si la taille est valide
    if (size <= 0) {
      console.error(`La taille "${size}" n'est pas valide.`);
      return this;
    }

    // Mettre à jour les options
    if (status) {
      this.options.nodeSizes[status] = size;
    } else {
      this.options.nodeSizes.default = size;

      // Mettre à jour toutes les tailles si aucun statut n'est spécifié
      for (const status of ['completed', 'in_progress', 'planned']) {
        this.options.nodeSizes[status] = size;
      }
    }

    // Appliquer les changements
    this._applyNodeSizes();

    return this;
  }

  /**
   * Définit le style des arêtes
   * @param {string} style - Style à appliquer ('solid', 'dashed', 'dotted')
   */
  setEdgeStyle(style) {
    // Vérifier si le style est valide
    if (!this.options.edgeStyles.types[style]) {
      console.error(`Le style "${style}" n'est pas valide.`);
      return this;
    }

    // Mettre à jour les options
    this.options.edgeStyles.default = style;

    // Appliquer les changements
    this._applyEdgeStyles();

    return this;
  }

  /**
   * Définit le style des étiquettes
   * @param {Object} styles - Styles à appliquer
   */
  setLabelStyles(styles) {
    // Mettre à jour les options
    this.options.labelStyles = {
      ...this.options.labelStyles,
      ...styles
    };

    // Appliquer les changements
    this._applyLabelStyles();

    return this;
  }

  /**
   * Définit un style personnalisé pour un nœud spécifique
   * @param {string} nodeId - ID du nœud
   * @param {Object} styles - Styles à appliquer
   */
  setCustomNodeStyle(nodeId, styles) {
    // Mettre à jour les styles personnalisés
    this.state.customNodeStyles.set(nodeId, styles);

    // Appliquer les changements
    this._applyCustomStyles();

    return this;
  }

  /**
   * Définit un style personnalisé pour une arête spécifique
   * @param {string} edgeId - ID de l'arête
   * @param {Object} styles - Styles à appliquer
   */
  setCustomEdgeStyle(edgeId, styles) {
    // Mettre à jour les styles personnalisés
    this.state.customEdgeStyles.set(edgeId, styles);

    // Appliquer les changements
    this._applyCustomStyles();

    return this;
  }

  /**
   * Définit des styles personnalisés globaux
   * @param {Object} styles - Styles à appliquer
   */
  setCustomGlobalStyles(styles) {
    // Mettre à jour les styles personnalisés
    this.state.customGlobalStyles = {
      ...this.state.customGlobalStyles,
      ...styles
    };

    // Appliquer les changements
    this._applyCustomStyles();

    return this;
  }

  /**
   * Réinitialise tous les styles personnalisés
   */
  resetCustomStyles() {
    // Réinitialiser les styles personnalisés
    this.state.customNodeStyles.clear();
    this.state.customEdgeStyles.clear();
    this.state.customGlobalStyles = {};

    // Réappliquer le thème actuel
    this.applyTheme(this.state.currentTheme);

    return this;
  }

  /**
   * Applique les formes des nœuds
   * @private
   */
  _applyNodeShapes() {
    // Appliquer la forme par défaut
    this.cy.style()
      .selector('node')
      .style({
        'shape': this.options.nodeShapes.default
      });

    // Appliquer les formes spécifiques aux statuts
    for (const status of ['completed', 'in_progress', 'planned']) {
      this.cy.style()
        .selector(`node[status="${status}"]`)
        .style({
          'shape': this.options.nodeShapes[status]
        });
    }

    // Appliquer les formes personnalisées
    if (this.options.nodeShapes.custom && typeof this.options.nodeShapes.custom === 'object') {
      for (const [nodeId, shape] of Object.entries(this.options.nodeShapes.custom)) {
        if (nodeId && shape) {
          this.cy.style()
            .selector(`#${nodeId}`)
            .style({
              'shape': shape
            });
        }
      }
    }

    // Mettre à jour les styles
    this.cy.style().update();
  }

  /**
   * Applique les tailles des nœuds
   * @private
   */
  _applyNodeSizes() {
    // Appliquer la taille par défaut
    this.cy.style()
      .selector('node')
      .style({
        'width': this.options.nodeSizes.default,
        'height': this.options.nodeSizes.default
      });

    // Appliquer les tailles spécifiques aux statuts
    for (const status of ['completed', 'in_progress', 'planned']) {
      this.cy.style()
        .selector(`node[status="${status}"]`)
        .style({
          'width': this.options.nodeSizes[status],
          'height': this.options.nodeSizes[status]
        });
    }

    // Appliquer les tailles personnalisées
    if (this.options.nodeSizes.custom && typeof this.options.nodeSizes.custom === 'object') {
      for (const [nodeId, size] of Object.entries(this.options.nodeSizes.custom)) {
        if (nodeId && size) {
          this.cy.style()
            .selector(`#${nodeId}`)
            .style({
              'width': size,
              'height': size
            });
        }
      }
    }

    // Mettre à jour les styles
    this.cy.style().update();
  }

  /**
   * Applique les styles des arêtes
   * @private
   */
  _applyEdgeStyles() {
    // Récupérer le style d'arête par défaut
    const edgeStyle = this.options.edgeStyles.types[this.options.edgeStyles.default];

    // Appliquer le style
    this.cy.style()
      .selector('edge')
      .style(edgeStyle);

    // Mettre à jour les styles
    this.cy.style().update();
  }

  /**
   * Applique les styles des étiquettes
   * @private
   */
  _applyLabelStyles() {
    // Appliquer les styles d'étiquette
    this.cy.style()
      .selector('node')
      .style({
        'text-valign': this.options.labelStyles.position,
        'text-halign': this.options.labelStyles.position,
        'font-weight': this.options.labelStyles.fontWeight,
        'text-transform': this.options.labelStyles.textTransform,
        'text-wrap': this.options.labelStyles.textWrap,
        'text-max-width': this.options.labelStyles.textMaxWidth
      });

    // Mettre à jour les styles
    this.cy.style().update();
  }

  /**
   * Applique les styles personnalisés
   * @private
   */
  _applyCustomStyles() {
    // Appliquer les styles personnalisés globaux
    if (Object.keys(this.state.customGlobalStyles).length > 0) {
      this.cy.style()
        .selector('*')
        .style(this.state.customGlobalStyles);
    }

    // Appliquer les styles personnalisés des nœuds
    this.state.customNodeStyles.forEach((styles, nodeId) => {
      this.cy.style()
        .selector(`#${nodeId}`)
        .style(styles);
    });

    // Appliquer les styles personnalisés des arêtes
    this.state.customEdgeStyles.forEach((styles, edgeId) => {
      this.cy.style()
        .selector(`#${edgeId}`)
        .style(styles);
    });

    // Mettre à jour les styles
    this.cy.style().update();
  }

  /**
   * Déclenche un événement personnalisé
   * @param {string} eventName - Nom de l'événement
   * @param {Object} data - Données associées à l'événement
   * @private
   */
  _triggerEvent(eventName, data = {}) {
    // Créer un événement personnalisé
    const event = new CustomEvent(`metro-map:${eventName}`, {
      detail: {
        customizer: this,
        visualizer: this.visualizer,
        ...data
      },
      bubbles: true,
      cancelable: true
    });

    // Déclencher l'événement sur le conteneur Cytoscape
    this.cy.container().dispatchEvent(event);
  }
}

// Exporter la classe
export default MetroMapCustomizer;
