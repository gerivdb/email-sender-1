/**
 * MetroMapLayoutEngine.js
 * Moteur de rendu avec layout automatique pour la visualisation en carte de métro
 *
 * Ce module fournit des algorithmes avancés pour le positionnement optimal
 * des stations et des lignes dans une visualisation de type carte de métro.
 *
 * Version: 1.0
 * Date: 2025-05-15
 */

/**
 * Classe principale pour le moteur de layout de carte de métro
 */
class MetroMapLayoutEngine {
  /**
   * Constructeur
   * @param {Object} options - Options de configuration
   */
  constructor(options = {}) {
    this.options = {
      // Paramètres généraux
      nodeSeparation: 50,      // Distance minimale entre les nœuds
      rankSeparation: 100,     // Distance entre les rangs
      edgeSeparation: 50,      // Distance minimale entre les arêtes
      padding: 50,             // Marge autour du graphe

      // Paramètres d'optimisation
      optimizationIterations: 50,  // Nombre d'itérations pour l'optimisation
      optimizationTemperature: 1.0, // Température initiale pour le recuit simulé
      optimizationCooling: 0.95,   // Facteur de refroidissement

      // Paramètres de direction
      preferredDirection: 'horizontal', // Direction préférée ('horizontal' ou 'vertical')
      directionBias: 0.7,      // Biais pour la direction préférée (0-1)

      // Paramètres de layout
      layoutAlgorithm: 'metro', // Algorithme de layout ('metro', 'dagre', 'cose-bilkent', 'klay')

      // Paramètres spécifiques à l'algorithme metro
      metroLineSpacing: 30,    // Espacement entre les lignes parallèles
      metroStationRadius: 15,  // Rayon des stations
      metroJunctionRadius: 20, // Rayon des jonctions

      // Autres options
      ...options
    };

    // État interne
    this.graph = null;         // Graphe à disposer
    this.layoutResult = null;  // Résultat du layout
  }

  /**
   * Applique le layout au graphe
   * @param {Object} graph - Graphe à disposer (format { nodes, edges, lines })
   * @returns {Object} - Graphe avec les positions calculées
   */
  applyLayout(graph) {
    this.graph = this._preprocessGraph(graph);

    // Sélectionner l'algorithme de layout approprié
    switch (this.options.layoutAlgorithm) {
      case 'metro':
        this.layoutResult = this._applyMetroLayout();
        break;
      case 'dagre':
        this.layoutResult = this._applyDagreLayout();
        break;
      case 'cose-bilkent':
        this.layoutResult = this._applyCoseBilkentLayout();
        break;
      case 'klay':
        this.layoutResult = this._applyKlayLayout();
        break;
      default:
        this.layoutResult = this._applyMetroLayout();
    }

    // Post-traitement du résultat
    return this._postprocessLayout();
  }

  /**
   * Prétraite le graphe avant le layout
   * @param {Object} graph - Graphe à prétraiter
   * @returns {Object} - Graphe prétraité
   * @private
   */
  _preprocessGraph(graph) {
    // Copier le graphe pour éviter de modifier l'original
    const processedGraph = JSON.parse(JSON.stringify(graph));

    // Ajouter des propriétés nécessaires pour le layout
    processedGraph.nodes.forEach(node => {
      // Initialiser les positions si elles n'existent pas
      if (!node.position) {
        node.position = { x: 0, y: 0 };
      }

      // Calculer le poids du nœud en fonction du nombre de lignes
      node.weight = node.lines ? node.lines.length : 1;

      // Marquer les jonctions (nœuds appartenant à plusieurs lignes)
      node.isJunction = node.lines && node.lines.length > 1;
    });

    // Organiser les arêtes par ligne
    processedGraph.edgesByLine = {};
    if (processedGraph.lines) {
      processedGraph.lines.forEach(line => {
        processedGraph.edgesByLine[line.id] = [];
      });
    }

    processedGraph.edges.forEach(edge => {
      if (edge.line) {
        if (!processedGraph.edgesByLine[edge.line]) {
          processedGraph.edgesByLine[edge.line] = [];
        }
        processedGraph.edgesByLine[edge.line].push(edge);
      }
    });

    return processedGraph;
  }

  /**
   * Applique l'algorithme de layout spécifique aux cartes de métro
   * @returns {Object} - Résultat du layout
   * @private
   */
  _applyMetroLayout() {
    // Étape 1: Déterminer l'ordre topologique des nœuds
    const orderedNodes = this._computeTopologicalOrder();

    // Étape 2: Assigner les rangs (coordonnée principale)
    const rankedNodes = this._assignRanks(orderedNodes);

    // Étape 3: Minimiser les croisements (coordonnée secondaire)
    const positionedNodes = this._minimizeCrossings(rankedNodes);

    // Étape 4: Optimiser les positions pour un rendu esthétique
    const optimizedNodes = this._optimizePositions(positionedNodes);

    // Étape 5: Calculer les points de contrôle pour les arêtes
    const edges = this._routeEdges(optimizedNodes);

    return {
      nodes: optimizedNodes,
      edges: edges
    };
  }

  /**
   * Calcule l'ordre topologique des nœuds
   * @returns {Array} - Nœuds ordonnés topologiquement
   * @private
   */
  _computeTopologicalOrder() {
    const nodes = this.graph.nodes;
    const edges = this.graph.edges;

    // Créer un graphe orienté
    const adjacencyList = {};
    nodes.forEach(node => {
      adjacencyList[node.id] = [];
    });

    edges.forEach(edge => {
      adjacencyList[edge.source].push(edge.target);
    });

    // Algorithme de tri topologique
    const visited = {};
    const temp = {};
    const order = [];
    let hasCycle = false;

    function visit(nodeId) {
      if (temp[nodeId]) {
        hasCycle = true;
        return;
      }

      if (!visited[nodeId]) {
        temp[nodeId] = true;

        adjacencyList[nodeId].forEach(neighbor => {
          visit(neighbor);
        });

        temp[nodeId] = false;
        visited[nodeId] = true;
        order.unshift(nodeId);
      }
    }

    // Visiter tous les nœuds
    nodes.forEach(node => {
      if (!visited[node.id]) {
        visit(node.id);
      }
    });

    // Si un cycle est détecté, utiliser un autre algorithme
    if (hasCycle) {
      console.warn('Cycle détecté dans le graphe. Utilisation d\'un algorithme alternatif.');
      return this._computeLongestPathOrder();
    }

    // Convertir les IDs en objets nœuds
    return order.map(id => nodes.find(node => node.id === id));
  }

  /**
   * Calcule l'ordre des nœuds en fonction du chemin le plus long
   * @returns {Array} - Nœuds ordonnés par chemin le plus long
   * @private
   */
  _computeLongestPathOrder() {
    const nodes = this.graph.nodes;
    const edges = this.graph.edges;

    // Créer un graphe orienté
    const adjacencyList = {};
    const inDegree = {};

    nodes.forEach(node => {
      adjacencyList[node.id] = [];
      inDegree[node.id] = 0;
    });

    edges.forEach(edge => {
      adjacencyList[edge.source].push(edge.target);
      inDegree[edge.target] = (inDegree[edge.target] || 0) + 1;
    });

    // Trouver les nœuds sources (sans prédécesseurs)
    const sources = nodes.filter(node => inDegree[node.id] === 0).map(node => node.id);

    // Calculer la distance la plus longue pour chaque nœud
    const distance = {};
    nodes.forEach(node => {
      distance[node.id] = 0;
    });

    // Parcourir le graphe en largeur
    const queue = [...sources];
    while (queue.length > 0) {
      const current = queue.shift();

      adjacencyList[current].forEach(neighbor => {
        distance[neighbor] = Math.max(distance[neighbor], distance[current] + 1);

        inDegree[neighbor]--;
        if (inDegree[neighbor] === 0) {
          queue.push(neighbor);
        }
      });
    }

    // Trier les nœuds par distance
    return nodes.slice().sort((a, b) => distance[a.id] - distance[b.id]);
  }

  /**
   * Assigne des rangs aux nœuds
   * @param {Array} orderedNodes - Nœuds ordonnés topologiquement
   * @returns {Array} - Nœuds avec rangs assignés
   * @private
   */
  _assignRanks(orderedNodes) {
    const rankSeparation = this.options.rankSeparation;
    const preferredDirection = this.options.preferredDirection;

    // Assigner un rang à chaque nœud
    orderedNodes.forEach((node, index) => {
      if (preferredDirection === 'horizontal') {
        node.position.x = index * rankSeparation;
      } else {
        node.position.y = index * rankSeparation;
      }
    });

    return orderedNodes;
  }

  /**
   * Minimise les croisements entre les arêtes
   * @param {Array} rankedNodes - Nœuds avec rangs assignés
   * @returns {Array} - Nœuds avec positions optimisées
   * @private
   */
  _minimizeCrossings(rankedNodes) {
    const nodeSeparation = this.options.nodeSeparation;
    const preferredDirection = this.options.preferredDirection;

    // Regrouper les nœuds par rang
    const nodesByRank = {};
    rankedNodes.forEach(node => {
      const rank = preferredDirection === 'horizontal' ? node.position.x : node.position.y;
      if (!nodesByRank[rank]) {
        nodesByRank[rank] = [];
      }
      nodesByRank[rank].push(node);
    });

    // Pour chaque rang, optimiser l'ordre des nœuds
    Object.keys(nodesByRank).forEach(rank => {
      const nodesInRank = nodesByRank[rank];

      // Trier les nœuds pour minimiser les croisements
      // (Algorithme simplifié - dans un cas réel, utiliser un algorithme plus sophistiqué)
      nodesInRank.sort((a, b) => {
        // Utiliser le barycentre des voisins comme heuristique
        const aConnections = this._getNodeConnections(a);
        const bConnections = this._getNodeConnections(b);

        const aBarycentre = this._calculateBarycentre(aConnections);
        const bBarycentre = this._calculateBarycentre(bConnections);

        // Si les barycentres sont égaux, utiliser l'ID pour un tri stable
        if (Math.abs(aBarycentre - bBarycentre) < 0.001) {
          return a.id.localeCompare(b.id);
        }

        return aBarycentre - bBarycentre;
      });

      // Assigner les positions sur l'axe secondaire
      nodesInRank.forEach((node, index) => {
        if (preferredDirection === 'horizontal') {
          node.position.y = index * nodeSeparation;
        } else {
          node.position.x = index * nodeSeparation;
        }
      });
    });

    return rankedNodes;
  }

  /**
   * Obtient les connexions d'un nœud
   * @param {Object} node - Nœud
   * @returns {Array} - Nœuds connectés
   * @private
   */
  _getNodeConnections(node) {
    const edges = this.graph.edges;
    const connections = [];

    // Trouver toutes les arêtes connectées à ce nœud
    edges.forEach(edge => {
      if (edge.source === node.id) {
        const targetNode = this.graph.nodes.find(n => n.id === edge.target);
        if (targetNode) {
          connections.push(targetNode);
        }
      } else if (edge.target === node.id) {
        const sourceNode = this.graph.nodes.find(n => n.id === edge.source);
        if (sourceNode) {
          connections.push(sourceNode);
        }
      }
    });

    return connections;
  }

  /**
   * Calcule le barycentre des nœuds connectés
   * @param {Array} connections - Nœuds connectés
   * @returns {number} - Barycentre
   * @private
   */
  _calculateBarycentre(connections) {
    if (connections.length === 0) {
      return 0;
    }

    const preferredDirection = this.options.preferredDirection;
    let sum = 0;

    connections.forEach(node => {
      sum += preferredDirection === 'horizontal' ? node.position.y : node.position.x;
    });

    return sum / connections.length;
  }

  /**
   * Optimise les positions des nœuds pour un rendu esthétique
   * @param {Array} positionedNodes - Nœuds avec positions initiales
   * @returns {Array} - Nœuds avec positions optimisées
   * @private
   */
  _optimizePositions(positionedNodes) {
    // Implémenter un algorithme d'optimisation (ex: recuit simulé)
    // Pour simplifier, nous utilisons une version basique ici

    const iterations = this.options.optimizationIterations;
    const initialTemperature = this.options.optimizationTemperature;
    const coolingFactor = this.options.optimizationCooling;

    let currentNodes = JSON.parse(JSON.stringify(positionedNodes));
    let bestNodes = JSON.parse(JSON.stringify(positionedNodes));
    let bestEnergy = this._calculateLayoutEnergy(currentNodes);

    let temperature = initialTemperature;

    for (let i = 0; i < iterations; i++) {
      // Perturber légèrement les positions
      const perturbedNodes = this._perturbPositions(currentNodes, temperature);

      // Calculer l'énergie du nouveau layout
      const newEnergy = this._calculateLayoutEnergy(perturbedNodes);

      // Décider si on accepte le nouveau layout
      if (newEnergy < bestEnergy || Math.random() < Math.exp((bestEnergy - newEnergy) / temperature)) {
        currentNodes = perturbedNodes;

        if (newEnergy < bestEnergy) {
          bestNodes = perturbedNodes;
          bestEnergy = newEnergy;
        }
      }

      // Refroidir la température
      temperature *= coolingFactor;
    }

    return bestNodes;
  }

  /**
   * Perturbe légèrement les positions des nœuds
   * @param {Array} nodes - Nœuds à perturber
   * @param {number} temperature - Température actuelle (contrôle l'amplitude des perturbations)
   * @returns {Array} - Nœuds avec positions perturbées
   * @private
   */
  _perturbPositions(nodes, temperature) {
    const perturbedNodes = JSON.parse(JSON.stringify(nodes));

    perturbedNodes.forEach(node => {
      // Perturber les positions proportionnellement à la température
      node.position.x += (Math.random() * 2 - 1) * temperature * 10;
      node.position.y += (Math.random() * 2 - 1) * temperature * 10;
    });

    return perturbedNodes;
  }

  /**
   * Calcule l'énergie du layout (plus c'est bas, meilleur c'est)
   * @param {Array} nodes - Nœuds à évaluer
   * @returns {number} - Énergie du layout
   * @private
   */
  _calculateLayoutEnergy(nodes) {
    let energy = 0;

    // Pénalité pour les nœuds trop proches
    for (let i = 0; i < nodes.length; i++) {
      for (let j = i + 1; j < nodes.length; j++) {
        const dx = nodes[i].position.x - nodes[j].position.x;
        const dy = nodes[i].position.y - nodes[j].position.y;
        const distance = Math.sqrt(dx * dx + dy * dy);

        if (distance < this.options.nodeSeparation) {
          energy += (this.options.nodeSeparation - distance) * 10;
        }
      }
    }

    // Pénalité pour les arêtes trop longues
    this.graph.edges.forEach(edge => {
      const sourceNode = nodes.find(node => node.id === edge.source);
      const targetNode = nodes.find(node => node.id === edge.target);

      if (sourceNode && targetNode) {
        const dx = sourceNode.position.x - targetNode.position.x;
        const dy = sourceNode.position.y - targetNode.position.y;
        const distance = Math.sqrt(dx * dx + dy * dy);

        energy += distance;
      }
    });

    return energy;
  }

  /**
   * Calcule les points de contrôle pour les arêtes
   * @param {Array} nodes - Nœuds avec positions optimisées
   * @returns {Array} - Arêtes avec points de contrôle
   * @private
   */
  _routeEdges(nodes) {
    const edges = JSON.parse(JSON.stringify(this.graph.edges));
    const preferredDirection = this.options.preferredDirection;
    const directionBias = this.options.directionBias;

    // Créer un dictionnaire pour accéder rapidement aux nœuds par ID
    const nodesById = {};
    nodes.forEach(node => {
      nodesById[node.id] = node;
    });

    // Pour chaque arête, calculer les points de contrôle
    edges.forEach(edge => {
      const sourceNode = nodesById[edge.source];
      const targetNode = nodesById[edge.target];

      if (sourceNode && targetNode) {
        // Points de départ et d'arrivée
        edge.sourcePoint = { x: sourceNode.position.x, y: sourceNode.position.y };
        edge.targetPoint = { x: targetNode.position.x, y: targetNode.position.y };

        // Calculer les points de contrôle pour une courbe de Bézier
        const dx = targetNode.position.x - sourceNode.position.x;
        const dy = targetNode.position.y - sourceNode.position.y;
        const distance = Math.sqrt(dx * dx + dy * dy);

        // Ajuster les points de contrôle en fonction de la direction préférée
        if (preferredDirection === 'horizontal') {
          // Favoriser les segments horizontaux
          const sourceControlX = sourceNode.position.x + dx * directionBias;
          const targetControlX = targetNode.position.x - dx * directionBias;

          edge.controlPoints = [
            { x: sourceControlX, y: sourceNode.position.y },
            { x: targetControlX, y: targetNode.position.y }
          ];
        } else {
          // Favoriser les segments verticaux
          const sourceControlY = sourceNode.position.y + dy * directionBias;
          const targetControlY = targetNode.position.y - dy * directionBias;

          edge.controlPoints = [
            { x: sourceNode.position.x, y: sourceControlY },
            { x: targetNode.position.x, y: targetControlY }
          ];
        }
      }
    });

    return edges;
  }

  /**
   * Post-traite le résultat du layout
   * @returns {Object} - Résultat final du layout
   * @private
   */
  _postprocessLayout() {
    // Normaliser les positions pour qu'elles commencent à (0,0)
    const nodes = this.layoutResult.nodes;
    const edges = this.layoutResult.edges;

    // Trouver les coordonnées minimales
    let minX = Infinity;
    let minY = Infinity;

    nodes.forEach(node => {
      minX = Math.min(minX, node.position.x);
      minY = Math.min(minY, node.position.y);
    });

    // Décaler toutes les positions
    nodes.forEach(node => {
      node.position.x -= minX - this.options.padding;
      node.position.y -= minY - this.options.padding;
    });

    // Mettre à jour les points de contrôle des arêtes
    edges.forEach(edge => {
      if (edge.sourcePoint) {
        edge.sourcePoint.x -= minX - this.options.padding;
        edge.sourcePoint.y -= minY - this.options.padding;
      }

      if (edge.targetPoint) {
        edge.targetPoint.x -= minX - this.options.padding;
        edge.targetPoint.y -= minY - this.options.padding;
      }

      if (edge.controlPoints) {
        edge.controlPoints.forEach(point => {
          point.x -= minX - this.options.padding;
          point.y -= minY - this.options.padding;
        });
      }
    });

    return {
      nodes: nodes,
      edges: edges
    };
  }

  /**
   * Applique le layout Dagre (pour compatibilité avec Cytoscape)
   * @returns {Object} - Résultat du layout
   * @private
   */
  _applyDagreLayout() {
    // Cette méthode serait implémentée pour intégrer avec Cytoscape.js et dagre
    // Pour l'instant, on utilise notre propre algorithme
    return this._applyMetroLayout();
  }

  /**
   * Applique le layout Cose-Bilkent (pour compatibilité avec Cytoscape)
   * @returns {Object} - Résultat du layout
   * @private
   */
  _applyCoseBilkentLayout() {
    // Cette méthode serait implémentée pour intégrer avec Cytoscape.js et cose-bilkent
    // Pour l'instant, on utilise notre propre algorithme
    return this._applyMetroLayout();
  }

  /**
   * Applique le layout Klay (pour compatibilité avec Cytoscape)
   * @returns {Object} - Résultat du layout
   * @private
   */
  _applyKlayLayout() {
    // Cette méthode serait implémentée pour intégrer avec Cytoscape.js et klay
    // Pour l'instant, on utilise notre propre algorithme
    return this._applyMetroLayout();
  }
}

// Exporter la classe
export default MetroMapLayoutEngine;
