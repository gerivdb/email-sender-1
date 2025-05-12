/**
 * Metro Map Cognitive Visualization
 * 
 * Visualisation "ligne de métro" adaptée à l'architecture cognitive à 10 niveaux.
 * Basée sur Cytoscape.js et intégrée avec le modèle hiérarchique cognitif.
 */

// Dans un environnement navigateur, cytoscape est attendu comme variable globale
// const cytoscape = require('cytoscape');
// const dagre = require('cytoscape-dagre');
// const coseBilkent = require('cytoscape-cose-bilkent');
// const klay = require('cytoscape-klay');
// const popper = require('cytoscape-popper');
// const tippy = require('tippy.js');

/**
 * Classe principale pour la visualisation cognitive en ligne de métro
 */
class MetroMapCognitiveVisualizer {
  /**
   * Constructeur
   * @param {string} containerId - ID du conteneur HTML pour la visualisation
   * @param {Object} options - Options de configuration
   */
  constructor(containerId, options = {}) {
    this.containerId = containerId;
    this.options = {
      // Configuration générale
      nodeSize: 30,
      lineWidth: 4,
      
      // Couleurs pour les différents niveaux hiérarchiques
      levelColors: {
        cosmos: '#1a237e',     // Bleu profond
        galaxy: '#7b1fa2',     // Violet
        stellar_system: '#d32f2f', // Rouge
        planet: '#ff9800',     // Orange
        continent: '#ffc107',  // Ambre
        region: '#4caf50',     // Vert
        locality: '#00bcd4',   // Cyan
        district: '#2196f3',   // Bleu
        building: '#3f51b5',   // Indigo
        foundation: '#212121'  // Noir
      },
      
      // Couleurs pour les dimensions
      dimensionColors: {
        temporal: '#2196f3',   // Bleu
        cognitive: '#9c27b0',  // Violet
        organizational: '#4caf50', // Vert
        strategic: '#f44336'   // Rouge
      },
      
      // Couleurs pour les statuts
      statusColors: {
        planned: '#2196f3',    // Bleu
        in_progress: '#ff9800', // Orange
        completed: '#4caf50',  // Vert
        blocked: '#f44336',    // Rouge
        cancelled: '#9e9e9e'   // Gris
      },
      
      // Configuration du layout
      layout: {
        name: 'dagre',
        rankDir: 'LR',         // De gauche à droite
        rankSep: 100,          // Espacement entre les rangs
        nodeSep: 50,           // Espacement entre les nœuds
        edgeSep: 50,           // Espacement entre les arêtes
        ranker: 'network-simplex', // Algorithme de rangement
        padding: 50,           // Marge autour du graphe
        spacingFactor: 1.5,    // Facteur d'espacement
        animate: true,         // Animation lors de l'application du layout
        animationDuration: 800 // Durée de l'animation
      },
      
      // Autres options
      ...options
    };
    
    this.cy = null;
    this.data = null;
    this.currentLevel = 'cosmos'; // Niveau de visualisation actuel
    this.currentFilter = null;    // Filtre actuel
    this.selectedNodes = new Set(); // Nœuds sélectionnés
    this.expandedNodes = new Set(); // Nœuds développés
  }

  /**
   * Initialise la visualisation
   */
  initialize() {
    // Créer l'instance Cytoscape
    this.cy = cytoscape({
      container: document.getElementById(this.containerId),
      style: this._createStylesheet(),
      layout: {
        name: 'preset'
      },
      wheelSensitivity: 0.3,
      minZoom: 0.2,
      maxZoom: 3
    });

    // Ajouter les interactions
    this._setupInteractions();
    
    // Créer les contrôles de l'interface utilisateur
    this._createControls();
    
    return this;
  }

  /**
   * Charge et visualise les données
   * @param {Object} data - Données hiérarchiques à visualiser
   */
  loadData(data) {
    this.data = data;
    this.visualize();
    return this;
  }

  /**
   * Visualise les données selon le niveau et les filtres actuels
   */
  visualize() {
    if (!this.data) {
      console.error('Aucune donnée à visualiser');
      return this;
    }
    
    // Construire les éléments du graphe
    const elements = this._buildGraphElements();
    
    // Réinitialiser et ajouter les éléments
    this.cy.elements().remove();
    this.cy.add(elements);
    
    // Appliquer le layout
    this._applyLayout();
    
    // Centrer la vue
    this.cy.fit();
    this.cy.zoom(0.8);
    
    return this;
  }

  /**
   * Change le niveau de visualisation
   * @param {string} level - Niveau à visualiser (cosmos, galaxy, etc.)
   */
  setLevel(level) {
    if (this.options.levelColors[level]) {
      this.currentLevel = level;
      this.visualize();
    } else {
      console.error(`Niveau invalide: ${level}`);
    }
    return this;
  }

  /**
   * Applique un filtre sur les données
   * @param {Function} filterFn - Fonction de filtrage
   */
  setFilter(filterFn) {
    this.currentFilter = filterFn;
    this.visualize();
    return this;
  }

  /**
   * Supprime le filtre actuel
   */
  clearFilter() {
    this.currentFilter = null;
    this.visualize();
    return this;
  }

  /**
   * Crée la feuille de style pour Cytoscape
   * @private
   */
  _createStylesheet() {
    return [
      // Style des nœuds (stations)
      {
        selector: 'node',
        style: {
          'width': this.options.nodeSize,
          'height': this.options.nodeSize,
          'background-color': 'data(color)',
          'border-width': 3,
          'border-color': '#333',
          'label': 'data(label)',
          'text-valign': 'center',
          'text-halign': 'center',
          'font-size': '10px',
          'text-wrap': 'wrap',
          'text-max-width': '80px',
          'text-outline-width': 2,
          'text-outline-color': 'white'
        }
      },
      // Style des nœuds sélectionnés
      {
        selector: 'node:selected',
        style: {
          'border-width': 5,
          'border-color': '#ffc107',
          'box-shadow': '0 0 15px #ffc107'
        }
      },
      // Style des liens (lignes de métro)
      {
        selector: 'edge',
        style: {
          'width': this.options.lineWidth,
          'line-color': 'data(color)',
          'target-arrow-color': 'data(color)',
          'target-arrow-shape': 'triangle',
          'curve-style': 'bezier',
          'line-style': 'data(lineStyle)'
        }
      },
      // Style des liens hiérarchiques
      {
        selector: 'edge[type="hierarchical"]',
        style: {
          'line-style': 'solid',
          'width': this.options.lineWidth * 1.5
        }
      },
      // Style des liens de dépendance
      {
        selector: 'edge[type="dependency"]',
        style: {
          'line-style': 'dashed',
          'width': this.options.lineWidth * 0.8
        }
      },
      // Style des liens dimensionnels
      {
        selector: 'edge[type="dimensional"]',
        style: {
          'line-style': 'dotted',
          'width': this.options.lineWidth * 0.6
        }
      },
      // Style des nœuds par statut
      {
        selector: 'node[status="planned"]',
        style: {
          'background-color': this.options.statusColors.planned
        }
      },
      {
        selector: 'node[status="in_progress"]',
        style: {
          'background-color': this.options.statusColors.in_progress
        }
      },
      {
        selector: 'node[status="completed"]',
        style: {
          'background-color': this.options.statusColors.completed
        }
      },
      {
        selector: 'node[status="blocked"]',
        style: {
          'background-color': this.options.statusColors.blocked
        }
      },
      {
        selector: 'node[status="cancelled"]',
        style: {
          'background-color': this.options.statusColors.cancelled,
          'opacity': 0.6
        }
      }
    ];
  }

  /**
   * Configure les interactions avec la visualisation
   * @private
   */
  _setupInteractions() {
    // Interaction au clic sur un nœud
    this.cy.on('tap', 'node', (event) => {
      const node = event.target;
      const nodeData = node.data();
      
      // Afficher les détails du nœud
      this._showNodeDetails(nodeData);
      
      // Si le nœud a des enfants, les développer/réduire
      if (nodeData.hasChildren) {
        if (this.expandedNodes.has(nodeData.id)) {
          this.expandedNodes.delete(nodeData.id);
        } else {
          this.expandedNodes.add(nodeData.id);
        }
        this.visualize();
      }
    });
    
    // Interaction au survol d'un nœud
    this.cy.on('mouseover', 'node', (event) => {
      const node = event.target;
      node.style('border-width', 5);
      
      // Mettre en évidence les nœuds connectés
      const connectedNodes = node.connectedNodes();
      connectedNodes.style('border-width', 4);
      
      // Mettre en évidence les liens
      const connectedEdges = node.connectedEdges();
      connectedEdges.style('width', this.options.lineWidth * 1.5);
    });
    
    // Fin du survol d'un nœud
    this.cy.on('mouseout', 'node', (event) => {
      const node = event.target;
      node.style('border-width', 3);
      
      // Restaurer les nœuds connectés
      const connectedNodes = node.connectedNodes();
      connectedNodes.style('border-width', 3);
      
      // Restaurer les liens
      const connectedEdges = node.connectedEdges();
      connectedEdges.style('width', this.options.lineWidth);
    });
  }

  /**
   * Crée les contrôles de l'interface utilisateur
   * @private
   */
  _createControls() {
    // À implémenter selon les besoins de l'interface
  }

  /**
   * Construit les éléments du graphe pour Cytoscape
   * @private
   */
  _buildGraphElements() {
    const elements = [];
    
    // Fonction récursive pour ajouter les nœuds et les liens
    const addNodeAndEdges = (node, parent = null, depth = 0) => {
      // Appliquer le filtre si défini
      if (this.currentFilter && !this.currentFilter(node)) {
        return;
      }
      
      // Déterminer si le nœud doit être affiché selon le niveau actuel
      const shouldDisplay = this._shouldDisplayNode(node, depth);
      if (!shouldDisplay) {
        return;
      }
      
      // Ajouter le nœud
      elements.push({
        group: 'nodes',
        data: {
          id: node.id,
          label: node.title,
          type: node.type,
          status: node.status,
          description: node.description,
          color: this.options.levelColors[node.type] || '#999',
          hasChildren: node.children && node.children.length > 0,
          depth: depth,
          parent: parent ? parent.id : null,
          metadata: node.metadata || {}
        }
      });
      
      // Ajouter le lien avec le parent si existant
      if (parent) {
        elements.push({
          group: 'edges',
          data: {
            id: `${parent.id}-${node.id}`,
            source: parent.id,
            target: node.id,
            color: this.options.levelColors[parent.type] || '#999',
            type: 'hierarchical',
            lineStyle: 'solid'
          }
        });
      }
      
      // Ajouter les enfants si le nœud est développé ou si on est à un niveau peu profond
      if (node.children && (this.expandedNodes.has(node.id) || depth < 2)) {
        node.children.forEach(child => {
          addNodeAndEdges(child, node, depth + 1);
        });
      }
      
      // Ajouter les dépendances si définies
      if (node.dependencies) {
        node.dependencies.forEach(dep => {
          elements.push({
            group: 'edges',
            data: {
              id: `dep-${node.id}-${dep.id}`,
              source: node.id,
              target: dep.id,
              color: '#999',
              type: 'dependency',
              lineStyle: 'dashed'
            }
          });
        });
      }
    };
    
    // Commencer par le nœud racine
    addNodeAndEdges(this.data);
    
    return elements;
  }

  /**
   * Détermine si un nœud doit être affiché selon le niveau actuel
   * @param {Object} node - Nœud à vérifier
   * @param {number} depth - Profondeur du nœud dans l'arborescence
   * @private
   */
  _shouldDisplayNode(node, depth) {
    // Logique pour déterminer si un nœud doit être affiché
    // selon le niveau de visualisation actuel
    
    // Si on est au niveau COSMOS, afficher seulement les niveaux supérieurs
    if (this.currentLevel === 'cosmos') {
      return node.type === 'cosmos' || node.type === 'galaxy' || node.type === 'stellar_system';
    }
    
    // Si on est au niveau GALAXIES, afficher les galaxies et leurs enfants directs
    if (this.currentLevel === 'galaxy') {
      return node.type === 'galaxy' || node.type === 'stellar_system' || node.type === 'planet' || 
             (node.type === 'cosmos' && depth === 0);
    }
    
    // Si on est au niveau SYSTÈMES STELLAIRES
    if (this.currentLevel === 'stellar_system') {
      return node.type === 'stellar_system' || node.type === 'planet' || node.type === 'continent' ||
             (node.type === 'galaxy' && depth <= 1) || (node.type === 'cosmos' && depth === 0);
    }
    
    // Pour les autres niveaux, afficher les nœuds de ce niveau et adjacents
    const levelOrder = ['cosmos', 'galaxy', 'stellar_system', 'planet', 'continent', 'region', 'locality', 'district', 'building', 'foundation'];
    const currentLevelIndex = levelOrder.indexOf(this.currentLevel);
    const nodeTypeIndex = levelOrder.indexOf(node.type);
    
    // Afficher les nœuds du niveau actuel et des niveaux adjacents (±2)
    return Math.abs(nodeTypeIndex - currentLevelIndex) <= 2 || this.expandedNodes.has(node.id);
  }

  /**
   * Applique le layout à la visualisation
   * @private
   */
  _applyLayout() {
    const layout = this.cy.layout(this.options.layout);
    layout.run();
  }

  /**
   * Affiche les détails d'un nœud
   * @param {Object} nodeData - Données du nœud
   * @private
   */
  _showNodeDetails(nodeData) {
    // À implémenter selon les besoins de l'interface
    console.log('Détails du nœud:', nodeData);
    
    // Exemple d'implémentation avec une boîte de dialogue
    if (typeof document !== 'undefined') {
      // Créer une modal pour afficher les détails
      const modal = document.createElement('div');
      modal.className = 'metro-map-modal';
      modal.innerHTML = `
        <div class="metro-map-modal-content">
          <span class="metro-map-modal-close">&times;</span>
          <h2>${nodeData.label}</h2>
          <p>${nodeData.description || 'Aucune description'}</p>
          <p><strong>Type:</strong> ${nodeData.type.toUpperCase()}</p>
          <p><strong>Statut:</strong> ${nodeData.status || 'Non défini'}</p>
          
          <div class="metro-map-modal-metadata">
            <h3>Métadonnées</h3>
            <div class="metro-map-modal-dimensions">
              ${this._formatMetadata(nodeData.metadata)}
            </div>
          </div>
          
          <div class="metro-map-modal-actions">
            <button class="metro-map-btn metro-map-btn-edit">Modifier</button>
            <button class="metro-map-btn metro-map-btn-expand">
              ${this.expandedNodes.has(nodeData.id) ? 'Réduire' : 'Développer'}
            </button>
          </div>
        </div>
      `;
      
      document.body.appendChild(modal);
      
      // Gérer la fermeture de la modal
      const closeBtn = modal.querySelector('.metro-map-modal-close');
      closeBtn.addEventListener('click', () => {
        document.body.removeChild(modal);
      });
      
      // Gérer l'expansion/réduction
      const expandBtn = modal.querySelector('.metro-map-btn-expand');
      expandBtn.addEventListener('click', () => {
        if (this.expandedNodes.has(nodeData.id)) {
          this.expandedNodes.delete(nodeData.id);
        } else {
          this.expandedNodes.add(nodeData.id);
        }
        document.body.removeChild(modal);
        this.visualize();
      });
    }
  }

  /**
   * Formate les métadonnées pour l'affichage
   * @param {Object} metadata - Métadonnées à formater
   * @private
   */
  _formatMetadata(metadata) {
    if (!metadata) return 'Aucune métadonnée';
    
    let html = '';
    
    // Formater chaque dimension
    for (const [dimension, data] of Object.entries(metadata)) {
      if (Object.keys(data).length === 0) continue;
      
      const dimensionColor = this.options.dimensionColors[dimension] || '#999';
      
      html += `<div class="dimension-section">
        <h4 style="color: ${dimensionColor}">${dimension.charAt(0).toUpperCase() + dimension.slice(1)}</h4>
        <ul>`;
      
      for (const [key, value] of Object.entries(data)) {
        html += `<li><strong>${key}:</strong> ${value}</li>`;
      }
      
      html += `</ul></div>`;
    }
    
    return html || 'Aucune métadonnée';
  }
}

// Exposer la classe globalement dans les environnements navigateur
if (typeof window !== 'undefined') {
  window.MetroMapCognitiveVisualizer = MetroMapCognitiveVisualizer;
}
