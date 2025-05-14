/**
 * MetroMapVisualizerEnhanced.js
 * Version améliorée du visualiseur de carte de métro avec moteur de layout automatique
 *
 * Ce module étend le visualiseur de carte de métro existant en intégrant
 * le moteur de layout automatique pour un rendu optimal des cartes de métro.
 *
 * Version: 1.0
 * Date: 2025-05-15
 */

// Importation des dépendances
import MetroMapVisualizer from '../../../development/scripts/roadmap/visualization/MetroMapVisualizer.js';
import MetroMapLayoutEngine from './MetroMapLayoutEngine.js';

/**
 * Classe principale pour la visualisation améliorée des roadmaps en carte de métro
 * Étend la classe MetroMapVisualizer avec des fonctionnalités de layout avancées
 */
class MetroMapVisualizerEnhanced extends MetroMapVisualizer {
  /**
   * Constructeur
   * @param {string} containerId - ID du conteneur HTML pour la visualisation
   * @param {Object} options - Options de configuration
   */
  constructor(containerId, options = {}) {
    // Options par défaut pour le layout
    const layoutOptions = {
      layoutAlgorithm: 'metro',
      preferredDirection: 'horizontal',
      nodeSeparation: 50,
      rankSeparation: 100,
      edgeSeparation: 50,
      optimizationIterations: 50,
      optimizationTemperature: 1.0,
      optimizationCooling: 0.95,
      directionBias: 0.7,
      ...options.layoutOptions
    };

    // Fusionner avec les options de base
    const mergedOptions = {
      ...options,
      layoutOptions
    };

    try {
      // Essayer d'appeler le constructeur parent
      super(containerId, mergedOptions);
    } catch (error) {
      console.warn('Erreur lors de l\'initialisation du visualiseur parent:', error);
      console.info('Initialisation du visualiseur en mode autonome');

      // Initialisation de secours si le constructeur parent échoue
      this.containerId = containerId;
      this.options = mergedOptions;
      this.cy = null; // Sera initialisé dans initialize()
      this.testRoadmaps = options.testRoadmaps || {}; // Données de test pour les roadmaps
    }

    // Créer le moteur de layout
    this.layoutEngine = new MetroMapLayoutEngine(layoutOptions);

    // État interne supplémentaire
    this.preLayoutPositions = new Map(); // Pour stocker les positions avant le layout
    this.layoutResult = null; // Pour stocker le résultat du layout
  }

  /**
   * Initialise le visualiseur
   * @returns {Promise<void>}
   */
  async initialize() {
    try {
      // Essayer d'utiliser la méthode du parent
      await super.initialize();
    } catch (error) {
      console.warn('Erreur lors de l\'initialisation standard:', error);
      console.info('Initialisation en mode de secours');

      // Initialisation de secours
      if (!window.cytoscape) {
        throw new Error('Cytoscape.js n\'est pas chargé');
      }

      // Initialiser Cytoscape
      this.cy = window.cytoscape({
        container: document.getElementById(this.containerId),
        style: [
          {
            selector: 'node',
            style: {
              'background-color': 'data(originalColor)',
              'label': 'data(label)',
              'color': '#fff',
              'text-outline-color': '#000',
              'text-outline-width': 1,
              'font-size': 12,
              'text-valign': 'center',
              'text-halign': 'center',
              'width': 30,
              'height': 30,
              'border-width': 2,
              'border-color': '#000'
            }
          },
          {
            selector: 'edge',
            style: {
              'width': 3,
              'line-color': 'data(originalColor)',
              'target-arrow-color': 'data(originalColor)',
              'target-arrow-shape': 'triangle',
              'curve-style': 'bezier'
            }
          },
          {
            selector: 'node[status="completed"]',
            style: {
              'background-color': '#4CAF50',
              'border-color': '#2E7D32'
            }
          },
          {
            selector: 'node[status="in_progress"]',
            style: {
              'background-color': '#2196F3',
              'border-color': '#1565C0'
            }
          },
          {
            selector: 'node[status="planned"]',
            style: {
              'background-color': '#9E9E9E',
              'border-color': '#616161'
            }
          }
        ],
        layout: {
          name: 'preset'
        }
      });

      // Ajouter des interactions
      this._setupInteractions();
    }
  }

  /**
   * Configure les interactions avec le graphe
   * @private
   */
  _setupInteractions() {
    if (!this.cy) return;

    // Ajouter des tooltips sur les nœuds
    this.cy.nodes().on('mouseover', event => {
      const node = event.target;
      const data = node.data();

      const tooltip = document.createElement('div');
      tooltip.className = 'metro-map-tooltip';
      tooltip.innerHTML = `
        <div><strong>${data.label}</strong></div>
        <div>${data.description || ''}</div>
        <div>Status: ${data.status || 'N/A'}</div>
      `;

      document.body.appendChild(tooltip);

      const updateTooltipPosition = event => {
        tooltip.style.position = 'absolute';
        tooltip.style.left = `${event.clientX + 10}px`;
        tooltip.style.top = `${event.clientY + 10}px`;
        tooltip.style.backgroundColor = '#fff';
        tooltip.style.padding = '8px';
        tooltip.style.borderRadius = '4px';
        tooltip.style.boxShadow = '0 2px 4px rgba(0, 0, 0, 0.2)';
        tooltip.style.zIndex = '1000';
        tooltip.style.maxWidth = '300px';
        tooltip.style.fontSize = '14px';
      };

      updateTooltipPosition(event.originalEvent);

      const mouseMoveHandler = event => {
        updateTooltipPosition(event);
      };

      document.addEventListener('mousemove', mouseMoveHandler);

      node.on('mouseout', () => {
        document.removeEventListener('mousemove', mouseMoveHandler);
        tooltip.remove();
      });
    });

    // Zoom sur double-clic
    this.cy.on('dblclick', 'node', event => {
      const node = event.target;
      this.cy.animate({
        zoom: 2,
        center: {
          eles: node
        }
      }, {
        duration: 500
      });
    });

    // Réinitialiser le zoom sur double-clic sur le fond
    this.cy.on('dblclick', event => {
      if (event.target === this.cy) {
        this.cy.animate({
          zoom: 1,
          center: {
            eles: this.cy.elements()
          }
        }, {
          duration: 500
        });
      }
    });
  }

  /**
   * Applique un layout de type métro amélioré
   * @override
   * @private
   */
  _applyMetroLayout() {
    // Si l'algorithme de layout est 'metro', utiliser notre moteur de layout personnalisé
    if (this.options.layoutOptions.layoutAlgorithm === 'metro') {
      this._applyCustomMetroLayout();
    } else {
      // Sinon, utiliser le layout Cytoscape standard
      super._applyMetroLayout();
    }
  }

  /**
   * Applique le layout de métro personnalisé
   * @private
   */
  _applyCustomMetroLayout() {
    // Convertir les éléments Cytoscape en format compatible avec le moteur de layout
    const graph = this._convertCytoscapeToGraph();

    // Appliquer le layout
    this.layoutResult = this.layoutEngine.applyLayout(graph);

    // Appliquer les positions calculées aux nœuds Cytoscape
    this._applyLayoutPositions();
  }

  /**
   * Convertit les éléments Cytoscape en format compatible avec le moteur de layout
   * @returns {Object} - Graphe au format attendu par le moteur de layout
   * @private
   */
  _convertCytoscapeToGraph() {
    const nodes = [];
    const edges = [];
    const lines = [];
    const lineColors = new Map();

    // Extraire les nœuds
    this.cy.nodes().forEach(node => {
      const nodeData = node.data();

      // Stocker la position actuelle
      this.preLayoutPositions.set(nodeData.id, {
        x: node.position('x'),
        y: node.position('y')
      });

      // Déterminer les lignes auxquelles appartient ce nœud
      const nodeLines = [];

      // Ajouter la ligne de la roadmap
      if (nodeData.roadmapId) {
        const lineId = `line_${nodeData.roadmapId}`;
        nodeLines.push(lineId);

        // Ajouter la ligne si elle n'existe pas encore
        if (!lineColors.has(lineId)) {
          lineColors.set(lineId, nodeData.originalColor || '#333');
          lines.push({
            id: lineId,
            name: `Roadmap ${nodeData.roadmapId}`,
            color: nodeData.originalColor || '#333'
          });
        }
      }

      // Créer le nœud
      nodes.push({
        id: nodeData.id,
        name: nodeData.label,
        lines: nodeLines,
        status: nodeData.status,
        description: nodeData.description
      });
    });

    // Extraire les arêtes
    this.cy.edges().forEach(edge => {
      const edgeData = edge.data();

      edges.push({
        source: edgeData.source,
        target: edgeData.target,
        line: `line_${edgeData.source.split('_')[0]}` // Utiliser la roadmap source comme ligne
      });
    });

    return {
      nodes,
      edges,
      lines: Array.from(lines)
    };
  }

  /**
   * Applique les positions calculées aux nœuds Cytoscape
   * @private
   */
  _applyLayoutPositions() {
    if (!this.layoutResult) return;

    // Créer un dictionnaire pour accéder rapidement aux nœuds par ID
    const nodesById = {};
    this.layoutResult.nodes.forEach(node => {
      nodesById[node.id] = node;
    });

    // Appliquer les positions avec animation
    this.cy.nodes().forEach(node => {
      const nodeId = node.id();
      const layoutNode = nodesById[nodeId];

      if (layoutNode && layoutNode.position) {
        node.animate({
          position: { x: layoutNode.position.x, y: layoutNode.position.y },
          duration: 800,
          easing: 'ease-in-out'
        });
      }
    });

    // Mettre à jour les arêtes pour utiliser des courbes de Bézier
    this.cy.style()
      .selector('edge')
      .style({
        'curve-style': 'unbundled-bezier',
        'control-point-distances': [40, -40],
        'control-point-weights': [0.25, 0.75]
      })
      .update();

    // Ajuster les courbes des arêtes en fonction des points de contrôle calculés
    if (this.layoutResult.edges) {
      this.layoutResult.edges.forEach(edge => {
        if (edge.controlPoints && edge.controlPoints.length >= 2) {
          const cyEdge = this.cy.getElementById(`${edge.source}_${edge.target}`);
          if (cyEdge.length > 0) {
            // Calculer les distances et poids relatifs des points de contrôle
            const sourceNode = this.cy.getElementById(edge.source);
            const targetNode = this.cy.getElementById(edge.target);

            if (sourceNode.length > 0 && targetNode.length > 0) {
              const sourcePos = sourceNode.position();
              const targetPos = targetNode.position();

              const dx = targetPos.x - sourcePos.x;
              const dy = targetPos.y - sourcePos.y;
              const edgeLength = Math.sqrt(dx * dx + dy * dy);

              // Calculer les distances relatives pour les points de contrôle
              const cp1 = edge.controlPoints[0];
              const cp2 = edge.controlPoints[1];

              // Calculer les vecteurs perpendiculaires
              const nx = -dy / edgeLength;
              const ny = dx / edgeLength;

              // Calculer les distances perpendiculaires
              const cp1Dist = ((cp1.x - sourcePos.x) * nx + (cp1.y - sourcePos.y) * ny) * 2;
              const cp2Dist = ((cp2.x - targetPos.x) * nx + (cp2.y - targetPos.y) * ny) * 2;

              // Appliquer les points de contrôle
              cyEdge.style({
                'control-point-distances': [cp1Dist, cp2Dist],
                'control-point-weights': [0.3, 0.7]
              });
            }
          }
        }
      });
    }
  }

  /**
   * Visualise les roadmaps spécifiées
   * @param {Array<string>} roadmapIds - IDs des roadmaps à visualiser
   * @returns {Promise<void>}
   */
  async visualizeRoadmaps(roadmapIds) {
    try {
      // Essayer d'utiliser la méthode du parent
      await super.visualizeRoadmaps(roadmapIds);
    } catch (error) {
      console.warn('Erreur lors de la visualisation standard:', error);
      console.info('Visualisation en mode de secours');

      // Vérifier si nous avons des données de test
      if (!this.options.testRoadmaps) {
        throw new Error('Aucune donnée de test disponible pour la visualisation');
      }

      // Filtrer les roadmaps disponibles
      const availableRoadmaps = roadmapIds.filter(id => this.options.testRoadmaps[id]);

      if (availableRoadmaps.length === 0) {
        throw new Error('Aucune roadmap disponible parmi les IDs spécifiés');
      }

      // Créer un graphe Cytoscape à partir des données de test
      const elements = [];

      // Ajouter les nœuds
      availableRoadmaps.forEach(roadmapId => {
        const roadmap = this.options.testRoadmaps[roadmapId];

        roadmap.nodes.forEach(node => {
          elements.push({
            group: 'nodes',
            data: {
              id: node.id,
              label: node.label,
              description: node.description,
              status: node.status,
              roadmapId: roadmap.id,
              originalColor: roadmap.color
            }
          });
        });

        // Ajouter les arêtes
        roadmap.edges.forEach(edge => {
          elements.push({
            group: 'edges',
            data: {
              id: `${edge.source}_${edge.target}`,
              source: edge.source,
              target: edge.target,
              roadmapId: roadmap.id,
              originalColor: roadmap.color
            }
          });
        });
      });

      // Ajouter les éléments au graphe Cytoscape
      this.cy.elements().remove();
      this.cy.add(elements);

      // Appliquer le layout
      this._applyMetroLayout();
    }
  }

  /**
   * Met à jour les options de layout
   * @param {Object} options - Nouvelles options de layout
   */
  updateLayoutOptions(options) {
    // Mettre à jour les options de layout
    this.options.layoutOptions = {
      ...this.options.layoutOptions,
      ...options
    };

    // Mettre à jour le moteur de layout
    this.layoutEngine = new MetroMapLayoutEngine(this.options.layoutOptions);
  }

  /**
   * Exporte la visualisation actuelle au format SVG
   * @returns {string} - Contenu SVG de la visualisation
   */
  exportAsSVG() {
    if (!this.cy) {
      throw new Error('Le graphe Cytoscape n\'est pas initialisé');
    }

    return this.cy.png({ output: 'blob-promise', scale: 2, bg: '#ffffff' });
  }

  /**
   * Modifie les options de layout
   * @param {Object} options - Nouvelles options de layout
   */
  updateLayoutOptions(options) {
    this.options.layoutOptions = {
      ...this.options.layoutOptions,
      ...options
    };

    // Mettre à jour le moteur de layout
    this.layoutEngine = new MetroMapLayoutEngine(this.options.layoutOptions);

    // Réappliquer le layout si des éléments sont présents
    if (this.cy.elements().length > 0) {
      this._applyMetroLayout();
    }
  }

  /**
   * Affiche les statistiques du layout
   * @returns {Object} - Statistiques du layout
   */
  getLayoutStats() {
    // Si nous avons un résultat de layout, utiliser les statistiques basées sur ce résultat
    if (this.layoutResult) {
      // Calculer diverses statistiques
      const nodeCount = this.layoutResult.nodes.length;
      const edgeCount = this.layoutResult.edges.length;

      // Calculer la surface occupée
      let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
      this.layoutResult.nodes.forEach(node => {
        minX = Math.min(minX, node.position.x);
        minY = Math.min(minY, node.position.y);
        maxX = Math.max(maxX, node.position.x);
        maxY = Math.max(maxY, node.position.y);
      });

      const width = maxX - minX;
      const height = maxY - minY;
      const area = width * height;

      // Calculer la densité
      const density = nodeCount / area;

      // Calculer le nombre de croisements d'arêtes
      const crossings = this._countEdgeCrossings();

      return {
        nodeCount,
        edgeCount,
        width,
        height,
        area,
        density,
        crossings
      };
    }
    // Sinon, si nous avons un graphe Cytoscape, utiliser les statistiques basées sur ce graphe
    else if (this.cy) {
      const nodes = this.cy.nodes();
      const edges = this.cy.edges();

      // Calculer la surface occupée
      const boundingBox = this.cy.elements().boundingBox();
      const width = boundingBox.w;
      const height = boundingBox.h;
      const area = width * height;

      // Calculer la densité
      const density = nodes.length / (area || 1); // Éviter la division par zéro

      // Calculer le nombre de croisements d'arêtes (approximation)
      const crossings = this._countCytoscapeEdgeCrossings();

      return {
        nodeCount: nodes.length,
        edgeCount: edges.length,
        width,
        height,
        area,
        density,
        crossings
      };
    }

    // Si nous n'avons ni résultat de layout ni graphe Cytoscape, retourner null
    return null;
  }

  /**
   * Compte le nombre de croisements d'arêtes dans le graphe Cytoscape
   * @returns {number} - Nombre de croisements
   * @private
   */
  _countCytoscapeEdgeCrossings() {
    if (!this.cy) return 0;

    let crossings = 0;
    const edges = this.cy.edges().toArray();

    // Fonction pour vérifier si deux segments se croisent
    function doSegmentsIntersect(p1, p2, p3, p4) {
      // Calcul des orientations
      function orientation(p, q, r) {
        const val = (q.y - p.y) * (r.x - q.x) - (q.x - p.x) * (r.y - q.y);
        if (val === 0) return 0;  // Colinéaires
        return (val > 0) ? 1 : 2; // Horaire ou anti-horaire
      }

      // Vérifie si le point p est sur le segment pr
      function onSegment(p, q, r) {
        return q.x <= Math.max(p.x, r.x) && q.x >= Math.min(p.x, r.x) &&
               q.y <= Math.max(p.y, r.y) && q.y >= Math.min(p.y, r.y);
      }

      const o1 = orientation(p1, p2, p3);
      const o2 = orientation(p1, p2, p4);
      const o3 = orientation(p3, p4, p1);
      const o4 = orientation(p3, p4, p2);

      // Cas général
      if (o1 !== o2 && o3 !== o4) return true;

      // Cas spéciaux
      if (o1 === 0 && onSegment(p1, p3, p2)) return true;
      if (o2 === 0 && onSegment(p1, p4, p2)) return true;
      if (o3 === 0 && onSegment(p3, p1, p4)) return true;
      if (o4 === 0 && onSegment(p3, p2, p4)) return true;

      return false;
    }

    // Vérifier chaque paire d'arêtes
    for (let i = 0; i < edges.length; i++) {
      for (let j = i + 1; j < edges.length; j++) {
        const edge1 = edges[i];
        const edge2 = edges[j];

        // Vérifier si les arêtes partagent un nœud
        if (edge1.source().id() === edge2.source().id() ||
            edge1.source().id() === edge2.target().id() ||
            edge1.target().id() === edge2.source().id() ||
            edge1.target().id() === edge2.target().id()) {
          continue; // Les arêtes partagent un nœud, pas de croisement
        }

        // Points des segments
        const p1 = edge1.source().position();
        const p2 = edge1.target().position();
        const p3 = edge2.source().position();
        const p4 = edge2.target().position();

        // Vérifier si les segments se croisent
        if (doSegmentsIntersect(p1, p2, p3, p4)) {
          crossings++;
        }
      }
    }

    return crossings;
  }

  /**
   * Compte le nombre de croisements d'arêtes
   * @returns {number} - Nombre de croisements
   * @private
   */
  _countEdgeCrossings() {
    if (!this.layoutResult || !this.layoutResult.edges) return 0;

    let crossings = 0;
    const edges = this.layoutResult.edges;

    // Fonction pour vérifier si deux segments se croisent
    function doSegmentsIntersect(p1, p2, p3, p4) {
      // Calcul des orientations
      function orientation(p, q, r) {
        const val = (q.y - p.y) * (r.x - q.x) - (q.x - p.x) * (r.y - q.y);
        if (val === 0) return 0;  // Colinéaires
        return (val > 0) ? 1 : 2; // Horaire ou anti-horaire
      }

      // Vérifie si le point p est sur le segment pr
      function onSegment(p, q, r) {
        return q.x <= Math.max(p.x, r.x) && q.x >= Math.min(p.x, r.x) &&
               q.y <= Math.max(p.y, r.y) && q.y >= Math.min(p.y, r.y);
      }

      const o1 = orientation(p1, p2, p3);
      const o2 = orientation(p1, p2, p4);
      const o3 = orientation(p3, p4, p1);
      const o4 = orientation(p3, p4, p2);

      // Cas général
      if (o1 !== o2 && o3 !== o4) return true;

      // Cas spéciaux
      if (o1 === 0 && onSegment(p1, p3, p2)) return true;
      if (o2 === 0 && onSegment(p1, p4, p2)) return true;
      if (o3 === 0 && onSegment(p3, p1, p4)) return true;
      if (o4 === 0 && onSegment(p3, p2, p4)) return true;

      return false;
    }

    // Vérifier chaque paire d'arêtes
    for (let i = 0; i < edges.length; i++) {
      for (let j = i + 1; j < edges.length; j++) {
        const edge1 = edges[i];
        const edge2 = edges[j];

        // Vérifier si les arêtes partagent un nœud
        if (edge1.source === edge2.source || edge1.source === edge2.target ||
            edge1.target === edge2.source || edge1.target === edge2.target) {
          continue; // Les arêtes partagent un nœud, pas de croisement
        }

        // Points des segments
        const p1 = edge1.sourcePoint;
        const p2 = edge1.targetPoint;
        const p3 = edge2.sourcePoint;
        const p4 = edge2.targetPoint;

        // Vérifier si les segments se croisent
        if (doSegmentsIntersect(p1, p2, p3, p4)) {
          crossings++;
        }
      }
    }

    return crossings;
  }
}

export default MetroMapVisualizerEnhanced;
