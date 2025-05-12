/**
 * Système d'analyse des dépendances multi-niveaux
 * 
 * Ce module implémente l'analyse des dépendances pour l'architecture cognitive à 10 niveaux.
 * Il détecte les dépendances hiérarchiques, analyse les dépendances transversales et résout les conflits.
 */

class DependencyAnalyzer {
  /**
   * Constructeur
   * @param {Object} options - Options de configuration
   */
  constructor(options = {}) {
    this.options = {
      // Niveaux hiérarchiques
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
      
      // Seuils de conflit
      conflictThresholds: {
        minor: 0.3,    // Conflit mineur
        moderate: 0.6, // Conflit modéré
        major: 0.8     // Conflit majeur
      },
      
      // Autres options
      ...options
    };
    
    // Initialiser les systèmes
    this.hierarchicalDependencyDetector = new HierarchicalDependencyDetector(this.options);
    this.transversalDependencyAnalyzer = new TransversalDependencyAnalyzer(this.options);
    this.dependencyConflictResolver = new DependencyConflictResolver(this.options);
  }
  
  /**
   * Analyse les dépendances d'une roadmap
   * @param {Object} roadmap - Roadmap à analyser
   * @returns {Object} - Résultat de l'analyse des dépendances
   */
  analyze(roadmap) {
    try {
      console.log(`Analyse des dépendances pour la roadmap: ${roadmap.id}`);
      
      // Initialiser le résultat
      const result = {
        roadmapId: roadmap.id,
        hierarchicalDependencies: [],
        transversalDependencies: [],
        conflicts: [],
        nodeDependencies: {},
        dependencyGraph: {
          nodes: [],
          edges: []
        }
      };
      
      // Étape 1: Détecter les dépendances hiérarchiques
      const hierarchicalDependencies = this.hierarchicalDependencyDetector.detect(roadmap);
      result.hierarchicalDependencies = hierarchicalDependencies;
      
      // Étape 2: Analyser les dépendances transversales
      const transversalDependencies = this.transversalDependencyAnalyzer.analyze(roadmap, hierarchicalDependencies);
      result.transversalDependencies = transversalDependencies;
      
      // Étape 3: Résoudre les conflits de dépendances
      const conflicts = this.dependencyConflictResolver.resolve(hierarchicalDependencies, transversalDependencies);
      result.conflicts = conflicts;
      
      // Étape 4: Construire le graphe de dépendances
      this._buildDependencyGraph(result, roadmap);
      
      // Étape 5: Construire la table des dépendances par nœud
      this._buildNodeDependenciesTable(result);
      
      return result;
    } catch (error) {
      console.error('Erreur lors de l\'analyse des dépendances:', error);
      throw error;
    }
  }
  
  /**
   * Construit le graphe de dépendances
   * @param {Object} result - Résultat de l'analyse des dépendances
   * @param {Object} roadmap - Roadmap analysée
   * @private
   */
  _buildDependencyGraph(result, roadmap) {
    // Fonction récursive pour ajouter les nœuds au graphe
    const addNodesToGraph = (node) => {
      // Ajouter le nœud au graphe
      result.dependencyGraph.nodes.push({
        id: node.id,
        label: node.title,
        type: node.type,
        status: node.status
      });
      
      // Traiter les enfants
      if (node.children && node.children.length > 0) {
        node.children.forEach(child => {
          // Ajouter l'arête hiérarchique
          result.dependencyGraph.edges.push({
            id: `h-${node.id}-${child.id}`,
            source: node.id,
            target: child.id,
            type: 'hierarchical'
          });
          
          // Traiter le nœud enfant
          addNodesToGraph(child);
        });
      }
    };
    
    // Commencer par le nœud racine
    addNodesToGraph(roadmap);
    
    // Ajouter les dépendances transversales au graphe
    result.transversalDependencies.forEach(dep => {
      result.dependencyGraph.edges.push({
        id: `t-${dep.sourceId}-${dep.targetId}`,
        source: dep.sourceId,
        target: dep.targetId,
        type: 'transversal',
        strength: dep.strength
      });
    });
  }
  
  /**
   * Construit la table des dépendances par nœud
   * @param {Object} result - Résultat de l'analyse des dépendances
   * @private
   */
  _buildNodeDependenciesTable(result) {
    // Initialiser la table des dépendances
    const nodeDependencies = {};
    
    // Ajouter les dépendances hiérarchiques
    result.hierarchicalDependencies.forEach(dep => {
      if (!nodeDependencies[dep.childId]) {
        nodeDependencies[dep.childId] = [];
      }
      
      nodeDependencies[dep.childId].push({
        id: dep.parentId,
        type: 'hierarchical',
        strength: 1.0
      });
    });
    
    // Ajouter les dépendances transversales
    result.transversalDependencies.forEach(dep => {
      if (!nodeDependencies[dep.targetId]) {
        nodeDependencies[dep.targetId] = [];
      }
      
      nodeDependencies[dep.targetId].push({
        id: dep.sourceId,
        type: 'transversal',
        strength: dep.strength
      });
    });
    
    // Stocker la table des dépendances
    result.nodeDependencies = nodeDependencies;
  }
}

/**
 * Détecteur de dépendances hiérarchiques
 */
class HierarchicalDependencyDetector {
  /**
   * Constructeur
   * @param {Object} options - Options de configuration
   */
  constructor(options = {}) {
    this.options = options;
  }
  
  /**
   * Détecte les dépendances hiérarchiques d'une roadmap
   * @param {Object} roadmap - Roadmap à analyser
   * @returns {Array} - Dépendances hiérarchiques détectées
   */
  detect(roadmap) {
    const dependencies = [];
    
    // Fonction récursive pour détecter les dépendances hiérarchiques
    const detectDependencies = (node, parentId = null) => {
      // Si le nœud a un parent, ajouter la dépendance
      if (parentId) {
        dependencies.push({
          parentId,
          childId: node.id,
          type: 'hierarchical'
        });
      }
      
      // Traiter les enfants
      if (node.children && node.children.length > 0) {
        node.children.forEach(child => {
          detectDependencies(child, node.id);
        });
      }
    };
    
    // Commencer par le nœud racine
    detectDependencies(roadmap);
    
    return dependencies;
  }
}

/**
 * Analyseur de dépendances transversales
 */
class TransversalDependencyAnalyzer {
  /**
   * Constructeur
   * @param {Object} options - Options de configuration
   */
  constructor(options = {}) {
    this.options = options;
  }
  
  /**
   * Analyse les dépendances transversales d'une roadmap
   * @param {Object} roadmap - Roadmap à analyser
   * @param {Array} hierarchicalDependencies - Dépendances hiérarchiques
   * @returns {Array} - Dépendances transversales détectées
   */
  analyze(roadmap, hierarchicalDependencies) {
    const dependencies = [];
    const nodeMap = new Map();
    
    // Construire une carte des nœuds pour un accès rapide
    const buildNodeMap = (node) => {
      nodeMap.set(node.id, node);
      
      if (node.children && node.children.length > 0) {
        node.children.forEach(child => {
          buildNodeMap(child);
        });
      }
    };
    
    // Construire la carte des nœuds
    buildNodeMap(roadmap);
    
    // Fonction récursive pour analyser les dépendances transversales
    const analyzeDependencies = (node) => {
      // Analyser les dépendances explicites
      if (node.dependencies) {
        node.dependencies.forEach(depId => {
          // Vérifier que la dépendance existe
          if (nodeMap.has(depId)) {
            // Ajouter la dépendance transversale
            dependencies.push({
              sourceId: depId,
              targetId: node.id,
              type: 'transversal',
              strength: 1.0,
              explicit: true
            });
          }
        });
      }
      
      // Analyser les dépendances implicites basées sur les métadonnées
      if (node.metadata) {
        // Parcourir tous les autres nœuds pour détecter des dépendances implicites
        nodeMap.forEach((otherNode, otherNodeId) => {
          // Éviter les auto-dépendances et les dépendances hiérarchiques
          if (otherNodeId !== node.id && !this._isHierarchicalDependency(hierarchicalDependencies, otherNodeId, node.id)) {
            // Calculer la force de la dépendance implicite
            const strength = this._calculateImplicitDependencyStrength(node, otherNode);
            
            // Si la force dépasse un certain seuil, ajouter la dépendance
            if (strength > 0.5) {
              dependencies.push({
                sourceId: otherNodeId,
                targetId: node.id,
                type: 'transversal',
                strength,
                explicit: false
              });
            }
          }
        });
      }
      
      // Traiter les enfants
      if (node.children && node.children.length > 0) {
        node.children.forEach(child => {
          analyzeDependencies(child);
        });
      }
    };
    
    // Commencer par le nœud racine
    analyzeDependencies(roadmap);
    
    return dependencies;
  }
  
  /**
   * Vérifie si une dépendance est hiérarchique
   * @param {Array} hierarchicalDependencies - Dépendances hiérarchiques
   * @param {string} parentId - ID du parent potentiel
   * @param {string} childId - ID de l'enfant potentiel
   * @returns {boolean} - Vrai si la dépendance est hiérarchique
   * @private
   */
  _isHierarchicalDependency(hierarchicalDependencies, parentId, childId) {
    return hierarchicalDependencies.some(dep => 
      dep.parentId === parentId && dep.childId === childId);
  }
  
  /**
   * Calcule la force d'une dépendance implicite
   * @param {Object} node - Nœud cible
   * @param {Object} otherNode - Nœud source potentiel
   * @returns {number} - Force de la dépendance (0-1)
   * @private
   */
  _calculateImplicitDependencyStrength(node, otherNode) {
    let strength = 0;
    
    // Si les nœuds n'ont pas de métadonnées, pas de dépendance implicite
    if (!node.metadata || !otherNode.metadata) {
      return 0;
    }
    
    // Dimension temporelle
    if (node.metadata.temporal && otherNode.metadata.temporal) {
      // Si les deux nœuds ont le même horizon temporel, augmenter la force
      if (node.metadata.temporal.horizon === otherNode.metadata.temporal.horizon) {
        strength += 0.2;
      }
      
      // Si le nœud source a un horizon temporel plus court, augmenter la force
      const horizons = ['immediate', 'short_term', 'medium_term', 'long_term'];
      const nodeHorizonIndex = horizons.indexOf(node.metadata.temporal.horizon);
      const otherNodeHorizonIndex = horizons.indexOf(otherNode.metadata.temporal.horizon);
      
      if (nodeHorizonIndex > -1 && otherNodeHorizonIndex > -1 && otherNodeHorizonIndex < nodeHorizonIndex) {
        strength += 0.3;
      }
    }
    
    // Dimension cognitive
    if (node.metadata.cognitive && otherNode.metadata.cognitive) {
      // Si le nœud source a une complexité plus élevée, augmenter la force
      const complexities = ['simple', 'moderate', 'complex', 'systemic'];
      const nodeComplexityIndex = complexities.indexOf(node.metadata.cognitive.complexity);
      const otherNodeComplexityIndex = complexities.indexOf(otherNode.metadata.cognitive.complexity);
      
      if (nodeComplexityIndex > -1 && otherNodeComplexityIndex > -1 && otherNodeComplexityIndex > nodeComplexityIndex) {
        strength += 0.2;
      }
    }
    
    // Dimension stratégique
    if (node.metadata.strategic && otherNode.metadata.strategic) {
      // Si le nœud source a une priorité plus élevée, augmenter la force
      const priorities = ['low', 'medium', 'high', 'critical'];
      const nodePriorityIndex = priorities.indexOf(node.metadata.strategic.priority);
      const otherNodePriorityIndex = priorities.indexOf(otherNode.metadata.strategic.priority);
      
      if (nodePriorityIndex > -1 && otherNodePriorityIndex > -1 && otherNodePriorityIndex > nodePriorityIndex) {
        strength += 0.3;
      }
    }
    
    return Math.min(strength, 1);
  }
}

/**
 * Résolveur de conflits de dépendances
 */
class DependencyConflictResolver {
  /**
   * Constructeur
   * @param {Object} options - Options de configuration
   */
  constructor(options = {}) {
    this.options = options;
  }
  
  /**
   * Résout les conflits de dépendances
   * @param {Array} hierarchicalDependencies - Dépendances hiérarchiques
   * @param {Array} transversalDependencies - Dépendances transversales
   * @returns {Array} - Conflits détectés et résolus
   */
  resolve(hierarchicalDependencies, transversalDependencies) {
    const conflicts = [];
    
    // Détecter les cycles de dépendances
    const cyclicDependencies = this._detectCyclicDependencies(hierarchicalDependencies, transversalDependencies);
    
    // Ajouter les conflits de cycles
    cyclicDependencies.forEach(cycle => {
      conflicts.push({
        type: 'cycle',
        nodes: cycle,
        severity: this._calculateConflictSeverity(cycle, hierarchicalDependencies, transversalDependencies),
        resolution: this._resolveCyclicDependency(cycle, hierarchicalDependencies, transversalDependencies)
      });
    });
    
    // Détecter les conflits de priorité
    const priorityConflicts = this._detectPriorityConflicts(hierarchicalDependencies, transversalDependencies);
    
    // Ajouter les conflits de priorité
    priorityConflicts.forEach(conflict => {
      conflicts.push({
        type: 'priority',
        nodes: [conflict.node1, conflict.node2],
        severity: conflict.severity,
        resolution: this._resolvePriorityConflict(conflict)
      });
    });
    
    return conflicts;
  }
  
  /**
   * Détecte les cycles de dépendances
   * @param {Array} hierarchicalDependencies - Dépendances hiérarchiques
   * @param {Array} transversalDependencies - Dépendances transversales
   * @returns {Array} - Cycles de dépendances détectés
   * @private
   */
  _detectCyclicDependencies(hierarchicalDependencies, transversalDependencies) {
    // Construire le graphe de dépendances
    const graph = new Map();
    
    // Ajouter les dépendances hiérarchiques au graphe
    hierarchicalDependencies.forEach(dep => {
      if (!graph.has(dep.childId)) {
        graph.set(dep.childId, []);
      }
      
      graph.get(dep.childId).push(dep.parentId);
    });
    
    // Ajouter les dépendances transversales au graphe
    transversalDependencies.forEach(dep => {
      if (!graph.has(dep.targetId)) {
        graph.set(dep.targetId, []);
      }
      
      graph.get(dep.targetId).push(dep.sourceId);
    });
    
    // Détecter les cycles en utilisant l'algorithme DFS
    const cycles = [];
    const visited = new Set();
    const recursionStack = new Set();
    
    // Fonction DFS pour détecter les cycles
    const detectCycle = (nodeId, path = []) => {
      // Marquer le nœud comme visité
      visited.add(nodeId);
      recursionStack.add(nodeId);
      
      // Ajouter le nœud au chemin
      path.push(nodeId);
      
      // Parcourir les voisins
      const neighbors = graph.get(nodeId) || [];
      for (const neighbor of neighbors) {
        // Si le voisin est dans la pile de récursion, un cycle est détecté
        if (recursionStack.has(neighbor)) {
          // Extraire le cycle du chemin
          const cycleStartIndex = path.indexOf(neighbor);
          const cycle = path.slice(cycleStartIndex);
          cycles.push(cycle);
        } else if (!visited.has(neighbor)) {
          // Visiter le voisin
          detectCycle(neighbor, [...path]);
        }
      }
      
      // Retirer le nœud de la pile de récursion
      recursionStack.delete(nodeId);
    };
    
    // Parcourir tous les nœuds
    for (const [nodeId] of graph) {
      if (!visited.has(nodeId)) {
        detectCycle(nodeId);
      }
    }
    
    return cycles;
  }
  
  /**
   * Calcule la sévérité d'un conflit
   * @param {Array} cycle - Cycle de dépendances
   * @param {Array} hierarchicalDependencies - Dépendances hiérarchiques
   * @param {Array} transversalDependencies - Dépendances transversales
   * @returns {string} - Sévérité du conflit (minor, moderate, major)
   * @private
   */
  _calculateConflictSeverity(cycle, hierarchicalDependencies, transversalDependencies) {
    // Calculer la force moyenne des dépendances dans le cycle
    let totalStrength = 0;
    let count = 0;
    
    // Parcourir les arêtes du cycle
    for (let i = 0; i < cycle.length; i++) {
      const sourceId = cycle[i];
      const targetId = cycle[(i + 1) % cycle.length];
      
      // Chercher la dépendance dans les dépendances hiérarchiques
      const hierarchicalDep = hierarchicalDependencies.find(dep => 
        dep.parentId === sourceId && dep.childId === targetId);
      
      if (hierarchicalDep) {
        totalStrength += 1.0; // Les dépendances hiérarchiques ont une force de 1.0
        count++;
        continue;
      }
      
      // Chercher la dépendance dans les dépendances transversales
      const transversalDep = transversalDependencies.find(dep => 
        dep.sourceId === sourceId && dep.targetId === targetId);
      
      if (transversalDep) {
        totalStrength += transversalDep.strength;
        count++;
      }
    }
    
    // Calculer la force moyenne
    const averageStrength = count > 0 ? totalStrength / count : 0;
    
    // Déterminer la sévérité en fonction de la force moyenne
    if (averageStrength >= this.options.conflictThresholds.major) {
      return 'major';
    } else if (averageStrength >= this.options.conflictThresholds.moderate) {
      return 'moderate';
    } else {
      return 'minor';
    }
  }
  
  /**
   * Résout un conflit de cycle de dépendances
   * @param {Array} cycle - Cycle de dépendances
   * @param {Array} hierarchicalDependencies - Dépendances hiérarchiques
   * @param {Array} transversalDependencies - Dépendances transversales
   * @returns {Object} - Résolution du conflit
   * @private
   */
  _resolveCyclicDependency(cycle, hierarchicalDependencies, transversalDependencies) {
    // Trouver la dépendance la plus faible dans le cycle
    let weakestDependency = null;
    let minStrength = 1.1; // Plus grand que la force maximale possible (1.0)
    
    // Parcourir les arêtes du cycle
    for (let i = 0; i < cycle.length; i++) {
      const sourceId = cycle[i];
      const targetId = cycle[(i + 1) % cycle.length];
      
      // Chercher la dépendance dans les dépendances transversales
      const transversalDep = transversalDependencies.find(dep => 
        dep.sourceId === sourceId && dep.targetId === targetId);
      
      if (transversalDep && transversalDep.strength < minStrength) {
        minStrength = transversalDep.strength;
        weakestDependency = {
          sourceId,
          targetId,
          type: 'transversal',
          strength: transversalDep.strength
        };
      }
    }
    
    // Si aucune dépendance transversale n'a été trouvée, choisir une dépendance hiérarchique
    if (!weakestDependency) {
      for (let i = 0; i < cycle.length; i++) {
        const sourceId = cycle[i];
        const targetId = cycle[(i + 1) % cycle.length];
        
        // Chercher la dépendance dans les dépendances hiérarchiques
        const hierarchicalDep = hierarchicalDependencies.find(dep => 
          dep.parentId === sourceId && dep.childId === targetId);
        
        if (hierarchicalDep) {
          weakestDependency = {
            sourceId,
            targetId,
            type: 'hierarchical',
            strength: 1.0
          };
          break;
        }
      }
    }
    
    // Retourner la résolution
    return {
      action: 'remove_dependency',
      dependency: weakestDependency
    };
  }
  
  /**
   * Détecte les conflits de priorité
   * @param {Array} hierarchicalDependencies - Dépendances hiérarchiques
   * @param {Array} transversalDependencies - Dépendances transversales
   * @returns {Array} - Conflits de priorité détectés
   * @private
   */
  _detectPriorityConflicts(hierarchicalDependencies, transversalDependencies) {
    // TODO: Implémenter la détection des conflits de priorité
    return [];
  }
  
  /**
   * Résout un conflit de priorité
   * @param {Object} conflict - Conflit de priorité
   * @returns {Object} - Résolution du conflit
   * @private
   */
  _resolvePriorityConflict(conflict) {
    // TODO: Implémenter la résolution des conflits de priorité
    return {
      action: 'adjust_priority',
      node: conflict.node1,
      newPriority: 'high'
    };
  }
}

// Exporter les classes
if (typeof module !== 'undefined') {
  module.exports = {
    DependencyAnalyzer,
    HierarchicalDependencyDetector,
    TransversalDependencyAnalyzer,
    DependencyConflictResolver
  };
}

// Exposer les classes globalement dans les environnements navigateur
if (typeof window !== 'undefined') {
  window.DependencyAnalyzer = DependencyAnalyzer;
  window.HierarchicalDependencyDetector = HierarchicalDependencyDetector;
  window.TransversalDependencyAnalyzer = TransversalDependencyAnalyzer;
  window.DependencyConflictResolver = DependencyConflictResolver;
}
