/**
 * Système d'optimisation des chemins critiques
 * 
 * Ce module implémente l'optimisation des chemins critiques pour l'architecture cognitive à 10 niveaux.
 * Il identifie les chemins critiques, suggère des optimisations et simule l'impact des modifications.
 */

class CriticalPathOptimizer {
  /**
   * Constructeur
   * @param {Object} options - Options de configuration
   */
  constructor(options = {}) {
    this.options = {
      // Seuils de criticité
      criticalityThresholds: {
        low: 0.3,      // Criticité faible
        medium: 0.6,   // Criticité moyenne
        high: 0.8      // Criticité élevée
      },
      
      // Facteurs de risque
      riskFactors: {
        complexity: 0.3,    // Poids de la complexité
        dependencies: 0.3,  // Poids des dépendances
        resources: 0.2,     // Poids des ressources
        uncertainty: 0.2    // Poids de l'incertitude
      },
      
      // Autres options
      ...options
    };
  }
  
  /**
   * Optimise les chemins critiques d'une roadmap
   * @param {Object} roadmap - Roadmap à optimiser
   * @param {Object} dependencies - Dépendances de la roadmap
   * @returns {Object} - Résultat de l'optimisation des chemins critiques
   */
  optimize(roadmap, dependencies) {
    try {
      console.log(`Optimisation des chemins critiques pour la roadmap: ${roadmap.id}`);
      
      // Initialiser le résultat
      const result = {
        roadmapId: roadmap.id,
        criticalPaths: [],
        criticalNodes: [],
        mainPath: null,
        optimizationSuggestions: [],
        simulationResults: {},
        estimatedCompletion: null,
        riskFactors: {}
      };
      
      // Étape 1: Identifier les chemins critiques
      const criticalPaths = this._identifyCriticalPaths(roadmap, dependencies);
      result.criticalPaths = criticalPaths;
      
      // Étape 2: Extraire les nœuds critiques
      const criticalNodes = this._extractCriticalNodes(criticalPaths);
      result.criticalNodes = criticalNodes;
      
      // Étape 3: Déterminer le chemin critique principal
      const mainPath = this._determineMainPath(criticalPaths);
      result.mainPath = mainPath;
      
      // Étape 4: Générer des suggestions d'optimisation
      const optimizationSuggestions = this._generateOptimizationSuggestions(roadmap, dependencies, criticalPaths);
      result.optimizationSuggestions = optimizationSuggestions;
      
      // Étape 5: Simuler l'impact des modifications
      const simulationResults = this._simulateModifications(roadmap, dependencies, optimizationSuggestions);
      result.simulationResults = simulationResults;
      
      // Étape 6: Estimer la date d'achèvement
      const estimatedCompletion = this._estimateCompletion(roadmap, dependencies, mainPath);
      result.estimatedCompletion = estimatedCompletion;
      
      // Étape 7: Calculer les facteurs de risque
      const riskFactors = this._calculateRiskFactors(roadmap, dependencies, criticalPaths);
      result.riskFactors = riskFactors;
      
      return result;
    } catch (error) {
      console.error('Erreur lors de l\'optimisation des chemins critiques:', error);
      throw error;
    }
  }
  
  /**
   * Identifie les chemins critiques d'une roadmap
   * @param {Object} roadmap - Roadmap à analyser
   * @param {Object} dependencies - Dépendances de la roadmap
   * @returns {Array} - Chemins critiques identifiés
   * @private
   */
  _identifyCriticalPaths(roadmap, dependencies) {
    // Construire le graphe de dépendances
    const graph = this._buildDependencyGraph(dependencies);
    
    // Calculer les temps au plus tôt et au plus tard pour chaque nœud
    const { earliestTimes, latestTimes, durations } = this._calculateNodeTimes(roadmap, graph);
    
    // Calculer les marges pour chaque nœud
    const slacks = new Map();
    for (const [nodeId, earliest] of earliestTimes.entries()) {
      const latest = latestTimes.get(nodeId);
      const slack = latest - earliest;
      slacks.set(nodeId, slack);
    }
    
    // Identifier les nœuds critiques (marge nulle ou très faible)
    const criticalNodes = [];
    for (const [nodeId, slack] of slacks.entries()) {
      if (slack <= 0.001) { // Utiliser une petite valeur epsilon pour gérer les erreurs d'arrondi
        criticalNodes.push(nodeId);
      }
    }
    
    // Construire les chemins critiques
    const criticalPaths = this._buildCriticalPaths(graph, criticalNodes);
    
    // Calculer la criticité de chaque chemin
    criticalPaths.forEach(path => {
      path.criticality = this._calculatePathCriticality(path, roadmap, dependencies);
      
      // Calculer la durée du chemin
      path.duration = path.nodes.reduce((total, nodeId) => total + (durations.get(nodeId) || 0), 0);
      
      // Calculer le risque du chemin
      path.risk = this._calculatePathRisk(path, roadmap, dependencies);
    });
    
    // Trier les chemins par criticité décroissante
    criticalPaths.sort((a, b) => b.criticality - a.criticality);
    
    return criticalPaths;
  }
  
  /**
   * Construit le graphe de dépendances
   * @param {Object} dependencies - Dépendances de la roadmap
   * @returns {Map} - Graphe de dépendances
   * @private
   */
  _buildDependencyGraph(dependencies) {
    const graph = new Map();
    
    // Ajouter les nœuds au graphe
    dependencies.dependencyGraph.nodes.forEach(node => {
      graph.set(node.id, {
        successors: [],
        predecessors: []
      });
    });
    
    // Ajouter les arêtes au graphe
    dependencies.dependencyGraph.edges.forEach(edge => {
      const source = edge.source;
      const target = edge.target;
      
      // Ajouter le successeur
      if (graph.has(source)) {
        graph.get(source).successors.push(target);
      }
      
      // Ajouter le prédécesseur
      if (graph.has(target)) {
        graph.get(target).predecessors.push(source);
      }
    });
    
    return graph;
  }
  
  /**
   * Calcule les temps au plus tôt et au plus tard pour chaque nœud
   * @param {Object} roadmap - Roadmap à analyser
   * @param {Map} graph - Graphe de dépendances
   * @returns {Object} - Temps au plus tôt et au plus tard pour chaque nœud
   * @private
   */
  _calculateNodeTimes(roadmap, graph) {
    // Calculer les durées des nœuds
    const durations = this._calculateNodeDurations(roadmap);
    
    // Trouver les nœuds de départ (sans prédécesseurs)
    const startNodes = [];
    for (const [nodeId, node] of graph.entries()) {
      if (node.predecessors.length === 0) {
        startNodes.push(nodeId);
      }
    }
    
    // Trouver les nœuds de fin (sans successeurs)
    const endNodes = [];
    for (const [nodeId, node] of graph.entries()) {
      if (node.successors.length === 0) {
        endNodes.push(nodeId);
      }
    }
    
    // Calculer les temps au plus tôt (forward pass)
    const earliestTimes = new Map();
    
    // Initialiser les nœuds de départ
    startNodes.forEach(nodeId => {
      earliestTimes.set(nodeId, 0);
    });
    
    // Parcourir le graphe en ordre topologique
    const visited = new Set();
    const topoOrder = [];
    
    // Fonction DFS pour le tri topologique
    const dfs = (nodeId) => {
      if (visited.has(nodeId)) return;
      
      visited.add(nodeId);
      
      const successors = graph.get(nodeId)?.successors || [];
      for (const successor of successors) {
        dfs(successor);
      }
      
      topoOrder.unshift(nodeId);
    };
    
    // Appliquer DFS à partir des nœuds de départ
    startNodes.forEach(nodeId => {
      dfs(nodeId);
    });
    
    // Calculer les temps au plus tôt en utilisant l'ordre topologique
    for (const nodeId of topoOrder) {
      const predecessors = graph.get(nodeId)?.predecessors || [];
      
      if (predecessors.length === 0) {
        // Nœud de départ, déjà initialisé
        continue;
      }
      
      // Calculer le temps au plus tôt comme le maximum des temps au plus tôt des prédécesseurs + leurs durées
      let earliest = 0;
      for (const predecessor of predecessors) {
        const predecessorEarliest = earliestTimes.get(predecessor) || 0;
        const predecessorDuration = durations.get(predecessor) || 0;
        earliest = Math.max(earliest, predecessorEarliest + predecessorDuration);
      }
      
      earliestTimes.set(nodeId, earliest);
    }
    
    // Calculer les temps au plus tard (backward pass)
    const latestTimes = new Map();
    
    // Calculer le temps de fin du projet
    let projectEnd = 0;
    for (const nodeId of endNodes) {
      const nodeEarliest = earliestTimes.get(nodeId) || 0;
      const nodeDuration = durations.get(nodeId) || 0;
      projectEnd = Math.max(projectEnd, nodeEarliest + nodeDuration);
    }
    
    // Initialiser les nœuds de fin
    endNodes.forEach(nodeId => {
      latestTimes.set(nodeId, projectEnd - (durations.get(nodeId) || 0));
    });
    
    // Parcourir le graphe en ordre topologique inverse
    for (let i = topoOrder.length - 1; i >= 0; i--) {
      const nodeId = topoOrder[i];
      const successors = graph.get(nodeId)?.successors || [];
      
      if (successors.length === 0) {
        // Nœud de fin, déjà initialisé
        continue;
      }
      
      // Calculer le temps au plus tard comme le minimum des temps au plus tard des successeurs - la durée du nœud
      let latest = Infinity;
      for (const successor of successors) {
        const successorLatest = latestTimes.get(successor) || 0;
        latest = Math.min(latest, successorLatest);
      }
      
      latestTimes.set(nodeId, latest);
    }
    
    return { earliestTimes, latestTimes, durations };
  }
  
  /**
   * Calcule les durées des nœuds
   * @param {Object} roadmap - Roadmap à analyser
   * @returns {Map} - Durées des nœuds
   * @private
   */
  _calculateNodeDurations(roadmap) {
    const durations = new Map();
    
    // Fonction récursive pour calculer les durées
    const calculateDuration = (node) => {
      // Calculer la durée de base selon le type de nœud
      const baseDuration = {
        cosmos: 100,
        galaxy: 80,
        stellar_system: 60,
        planet: 40,
        continent: 30,
        region: 20,
        locality: 10,
        district: 5,
        building: 2,
        foundation: 1
      };
      
      let duration = baseDuration[node.type] || 10;
      
      // Ajuster selon la complexité cognitive
      if (node.metadata && node.metadata.cognitive && node.metadata.cognitive.complexity) {
        const complexity = node.metadata.cognitive.complexity;
        if (complexity === 'simple') duration *= 0.5;
        else if (complexity === 'moderate') duration *= 1.0;
        else if (complexity === 'complex') duration *= 1.5;
        else if (complexity === 'systemic') duration *= 2.0;
      }
      
      // Stocker la durée
      durations.set(node.id, duration);
      
      // Calculer les durées des enfants
      if (node.children && node.children.length > 0) {
        node.children.forEach(child => {
          calculateDuration(child);
        });
      }
    };
    
    // Commencer par le nœud racine
    calculateDuration(roadmap);
    
    return durations;
  }
  
  /**
   * Construit les chemins critiques
   * @param {Map} graph - Graphe de dépendances
   * @param {Array} criticalNodes - Nœuds critiques
   * @returns {Array} - Chemins critiques
   * @private
   */
  _buildCriticalPaths(graph, criticalNodes) {
    const criticalPaths = [];
    
    // Trouver les nœuds de départ critiques
    const criticalStartNodes = criticalNodes.filter(nodeId => {
      const predecessors = graph.get(nodeId)?.predecessors || [];
      return predecessors.length === 0 || !predecessors.some(pred => criticalNodes.includes(pred));
    });
    
    // Construire les chemins à partir des nœuds de départ critiques
    criticalStartNodes.forEach(startNodeId => {
      const path = this._buildCriticalPath(graph, startNodeId, criticalNodes);
      if (path.nodes.length > 0) {
        criticalPaths.push(path);
      }
    });
    
    return criticalPaths;
  }
  
  /**
   * Construit un chemin critique à partir d'un nœud de départ
   * @param {Map} graph - Graphe de dépendances
   * @param {string} startNodeId - ID du nœud de départ
   * @param {Array} criticalNodes - Nœuds critiques
   * @returns {Object} - Chemin critique
   * @private
   */
  _buildCriticalPath(graph, startNodeId, criticalNodes) {
    const path = {
      id: `path-${startNodeId}`,
      nodes: [startNodeId],
      criticality: 0,
      duration: 0,
      risk: 0
    };
    
    let currentNodeId = startNodeId;
    
    // Construire le chemin en suivant les successeurs critiques
    while (true) {
      const successors = graph.get(currentNodeId)?.successors || [];
      const criticalSuccessors = successors.filter(succ => criticalNodes.includes(succ));
      
      if (criticalSuccessors.length === 0) {
        // Fin du chemin
        break;
      }
      
      // Choisir le premier successeur critique
      const nextNodeId = criticalSuccessors[0];
      path.nodes.push(nextNodeId);
      currentNodeId = nextNodeId;
    }
    
    return path;
  }
  
  /**
   * Calcule la criticité d'un chemin
   * @param {Object} path - Chemin à analyser
   * @param {Object} roadmap - Roadmap
   * @param {Object} dependencies - Dépendances
   * @returns {number} - Criticité du chemin (0-1)
   * @private
   */
  _calculatePathCriticality(path, roadmap, dependencies) {
    // Facteurs de criticité
    let criticality = 0;
    
    // Facteur 1: Longueur du chemin
    criticality += Math.min(path.nodes.length / 10, 1) * 0.3;
    
    // Facteur 2: Nombre de dépendances
    let dependencyCount = 0;
    path.nodes.forEach(nodeId => {
      const nodeDependencies = dependencies.nodeDependencies[nodeId] || [];
      dependencyCount += nodeDependencies.length;
    });
    criticality += Math.min(dependencyCount / 20, 1) * 0.3;
    
    // Facteur 3: Priorité stratégique
    let strategicPrioritySum = 0;
    let nodeCount = 0;
    
    // Fonction récursive pour trouver un nœud par ID
    const findNodeById = (node, id) => {
      if (node.id === id) {
        return node;
      }
      
      if (node.children) {
        for (const child of node.children) {
          const found = findNodeById(child, id);
          if (found) {
            return found;
          }
        }
      }
      
      return null;
    };
    
    // Calculer la priorité stratégique moyenne
    path.nodes.forEach(nodeId => {
      const node = findNodeById(roadmap, nodeId);
      if (node && node.metadata && node.metadata.strategic && node.metadata.strategic.priority) {
        const priority = node.metadata.strategic.priority;
        if (priority === 'critical') strategicPrioritySum += 1.0;
        else if (priority === 'high') strategicPrioritySum += 0.8;
        else if (priority === 'medium') strategicPrioritySum += 0.5;
        else if (priority === 'low') strategicPrioritySum += 0.2;
        nodeCount++;
      }
    });
    
    if (nodeCount > 0) {
      criticality += (strategicPrioritySum / nodeCount) * 0.4;
    }
    
    return Math.min(criticality, 1);
  }
  
  /**
   * Calcule le risque d'un chemin
   * @param {Object} path - Chemin à analyser
   * @param {Object} roadmap - Roadmap
   * @param {Object} dependencies - Dépendances
   * @returns {number} - Risque du chemin (0-1)
   * @private
   */
  _calculatePathRisk(path, roadmap, dependencies) {
    // TODO: Implémenter le calcul du risque d'un chemin
    return 0.5;
  }
  
  /**
   * Extrait les nœuds critiques de tous les chemins critiques
   * @param {Array} criticalPaths - Chemins critiques
   * @returns {Array} - Nœuds critiques
   * @private
   */
  _extractCriticalNodes(criticalPaths) {
    const criticalNodes = new Set();
    
    criticalPaths.forEach(path => {
      path.nodes.forEach(nodeId => {
        criticalNodes.add(nodeId);
      });
    });
    
    return Array.from(criticalNodes);
  }
  
  /**
   * Détermine le chemin critique principal
   * @param {Array} criticalPaths - Chemins critiques
   * @returns {Object} - Chemin critique principal
   * @private
   */
  _determineMainPath(criticalPaths) {
    if (criticalPaths.length === 0) {
      return null;
    }
    
    // Trier les chemins par criticité décroissante
    const sortedPaths = [...criticalPaths].sort((a, b) => b.criticality - a.criticality);
    
    // Retourner le chemin le plus critique
    return sortedPaths[0];
  }
  
  /**
   * Génère des suggestions d'optimisation
   * @param {Object} roadmap - Roadmap
   * @param {Object} dependencies - Dépendances
   * @param {Array} criticalPaths - Chemins critiques
   * @returns {Array} - Suggestions d'optimisation
   * @private
   */
  _generateOptimizationSuggestions(roadmap, dependencies, criticalPaths) {
    // TODO: Implémenter la génération de suggestions d'optimisation
    return [];
  }
  
  /**
   * Simule l'impact des modifications
   * @param {Object} roadmap - Roadmap
   * @param {Object} dependencies - Dépendances
   * @param {Array} optimizationSuggestions - Suggestions d'optimisation
   * @returns {Object} - Résultats de la simulation
   * @private
   */
  _simulateModifications(roadmap, dependencies, optimizationSuggestions) {
    // TODO: Implémenter la simulation de l'impact des modifications
    return {
      originalDuration: 100,
      optimizedDuration: 80,
      improvement: 20,
      riskReduction: 0.2
    };
  }
  
  /**
   * Estime la date d'achèvement
   * @param {Object} roadmap - Roadmap
   * @param {Object} dependencies - Dépendances
   * @param {Object} mainPath - Chemin critique principal
   * @returns {Object} - Estimation de la date d'achèvement
   * @private
   */
  _estimateCompletion(roadmap, dependencies, mainPath) {
    // TODO: Implémenter l'estimation de la date d'achèvement
    return {
      duration: 100,
      startDate: new Date(),
      endDate: new Date(Date.now() + 100 * 24 * 60 * 60 * 1000),
      confidence: 0.7
    };
  }
  
  /**
   * Calcule les facteurs de risque
   * @param {Object} roadmap - Roadmap
   * @param {Object} dependencies - Dépendances
   * @param {Array} criticalPaths - Chemins critiques
   * @returns {Object} - Facteurs de risque
   * @private
   */
  _calculateRiskFactors(roadmap, dependencies, criticalPaths) {
    // TODO: Implémenter le calcul des facteurs de risque
    return {
      complexity: 0.6,
      dependencies: 0.7,
      resources: 0.5,
      uncertainty: 0.4,
      overall: 0.55
    };
  }
}

// Exporter la classe
if (typeof module !== 'undefined') {
  module.exports = CriticalPathOptimizer;
}

// Exposer la classe globalement dans les environnements navigateur
if (typeof window !== 'undefined') {
  window.CriticalPathOptimizer = CriticalPathOptimizer;
}
