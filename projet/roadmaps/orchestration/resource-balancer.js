/**
 * Système d'équilibrage des ressources
 * 
 * Ce module implémente l'équilibrage des ressources pour l'architecture cognitive à 10 niveaux.
 * Il analyse la charge cognitive, alloue les ressources de manière optimale et détecte les surcharges.
 */

class ResourceBalancer {
  /**
   * Constructeur
   * @param {Object} options - Options de configuration
   */
  constructor(options = {}) {
    this.options = {
      // Seuils de charge cognitive
      cognitiveLoadThresholds: {
        low: 0.3,      // Charge cognitive faible
        medium: 0.6,   // Charge cognitive moyenne
        high: 0.8      // Charge cognitive élevée
      },
      
      // Facteurs d'allocation
      allocationFactors: {
        criticality: 0.4,   // Poids de la criticité
        complexity: 0.3,    // Poids de la complexité
        priority: 0.3       // Poids de la priorité
      },
      
      // Autres options
      ...options
    };
  }
  
  /**
   * Équilibre les ressources pour une roadmap
   * @param {Object} roadmap - Roadmap à équilibrer
   * @param {Object} dependencies - Dépendances de la roadmap
   * @param {Object} criticalPaths - Chemins critiques de la roadmap
   * @param {Object} resources - Ressources disponibles
   * @returns {Object} - Résultat de l'équilibrage des ressources
   */
  balance(roadmap, dependencies, criticalPaths, resources) {
    try {
      console.log(`Équilibrage des ressources pour la roadmap: ${roadmap.id}`);
      
      // Initialiser le résultat
      const result = {
        roadmapId: roadmap.id,
        cognitiveLoadAnalysis: {},
        resourceAllocation: {},
        overloadDetection: {},
        nodeAllocations: {}
      };
      
      // Étape 1: Analyser la charge cognitive
      const cognitiveLoadAnalysis = this._analyzeCognitiveLoad(roadmap, dependencies, criticalPaths);
      result.cognitiveLoadAnalysis = cognitiveLoadAnalysis;
      
      // Étape 2: Allouer les ressources de manière optimale
      const resourceAllocation = this._allocateResources(roadmap, dependencies, criticalPaths, resources, cognitiveLoadAnalysis);
      result.resourceAllocation = resourceAllocation;
      
      // Étape 3: Détecter les surcharges
      const overloadDetection = this._detectOverloads(roadmap, resourceAllocation, resources);
      result.overloadDetection = overloadDetection;
      
      // Étape 4: Construire la table des allocations par nœud
      result.nodeAllocations = resourceAllocation.nodeAllocations;
      
      return result;
    } catch (error) {
      console.error('Erreur lors de l\'équilibrage des ressources:', error);
      throw error;
    }
  }
  
  /**
   * Analyse la charge cognitive d'une roadmap
   * @param {Object} roadmap - Roadmap à analyser
   * @param {Object} dependencies - Dépendances de la roadmap
   * @param {Object} criticalPaths - Chemins critiques de la roadmap
   * @returns {Object} - Résultat de l'analyse de la charge cognitive
   * @private
   */
  _analyzeCognitiveLoad(roadmap, dependencies, criticalPaths) {
    // Initialiser le résultat
    const result = {
      totalLoad: 0,
      averageLoad: 0,
      maxLoad: 0,
      loadDistribution: {
        low: 0,
        medium: 0,
        high: 0
      },
      nodeLoads: {}
    };
    
    // Calculer la charge cognitive pour chaque nœud
    const nodeLoads = this._calculateNodeLoads(roadmap, dependencies, criticalPaths);
    result.nodeLoads = nodeLoads;
    
    // Calculer les statistiques globales
    let totalLoad = 0;
    let maxLoad = 0;
    let nodeCount = 0;
    let lowCount = 0;
    let mediumCount = 0;
    let highCount = 0;
    
    for (const [nodeId, load] of Object.entries(nodeLoads)) {
      totalLoad += load;
      maxLoad = Math.max(maxLoad, load);
      nodeCount++;
      
      if (load < this.options.cognitiveLoadThresholds.low) {
        lowCount++;
      } else if (load < this.options.cognitiveLoadThresholds.medium) {
        mediumCount++;
      } else {
        highCount++;
      }
    }
    
    result.totalLoad = totalLoad;
    result.averageLoad = nodeCount > 0 ? totalLoad / nodeCount : 0;
    result.maxLoad = maxLoad;
    
    result.loadDistribution.low = nodeCount > 0 ? lowCount / nodeCount : 0;
    result.loadDistribution.medium = nodeCount > 0 ? mediumCount / nodeCount : 0;
    result.loadDistribution.high = nodeCount > 0 ? highCount / nodeCount : 0;
    
    return result;
  }
  
  /**
   * Calcule la charge cognitive pour chaque nœud
   * @param {Object} roadmap - Roadmap à analyser
   * @param {Object} dependencies - Dépendances de la roadmap
   * @param {Object} criticalPaths - Chemins critiques de la roadmap
   * @returns {Object} - Charge cognitive pour chaque nœud
   * @private
   */
  _calculateNodeLoads(roadmap, dependencies, criticalPaths) {
    const nodeLoads = {};
    
    // Fonction récursive pour calculer la charge cognitive
    const calculateLoad = (node) => {
      // Facteurs de charge cognitive
      let load = 0;
      
      // Facteur 1: Complexité cognitive
      if (node.metadata && node.metadata.cognitive && node.metadata.cognitive.complexity) {
        const complexity = node.metadata.cognitive.complexity;
        if (complexity === 'simple') load += 0.2;
        else if (complexity === 'moderate') load += 0.5;
        else if (complexity === 'complex') load += 0.8;
        else if (complexity === 'systemic') load += 1.0;
      } else {
        // Valeur par défaut
        load += 0.5;
      }
      
      // Facteur 2: Nombre de dépendances
      const nodeDependencies = dependencies.nodeDependencies[node.id] || [];
      load += Math.min(nodeDependencies.length * 0.1, 0.5);
      
      // Facteur 3: Criticité
      if (criticalPaths.criticalNodes.includes(node.id)) {
        load += 0.3;
      }
      
      // Normaliser la charge entre 0 et 1
      load = Math.min(Math.max(load, 0), 1);
      
      // Stocker la charge
      nodeLoads[node.id] = load;
      
      // Calculer la charge des enfants
      if (node.children && node.children.length > 0) {
        node.children.forEach(child => {
          calculateLoad(child);
        });
      }
    };
    
    // Commencer par le nœud racine
    calculateLoad(roadmap);
    
    return nodeLoads;
  }
  
  /**
   * Alloue les ressources de manière optimale
   * @param {Object} roadmap - Roadmap à équilibrer
   * @param {Object} dependencies - Dépendances de la roadmap
   * @param {Object} criticalPaths - Chemins critiques de la roadmap
   * @param {Object} resources - Ressources disponibles
   * @param {Object} cognitiveLoadAnalysis - Analyse de la charge cognitive
   * @returns {Object} - Résultat de l'allocation des ressources
   * @private
   */
  _allocateResources(roadmap, dependencies, criticalPaths, resources, cognitiveLoadAnalysis) {
    // Initialiser le résultat
    const result = {
      totalAllocation: {},
      utilizationRate: {},
      allocationEfficiency: 0,
      nodeAllocations: {}
    };
    
    // Vérifier que les ressources sont définies
    if (!resources || Object.keys(resources).length === 0) {
      console.warn('Aucune ressource disponible pour l\'allocation');
      return result;
    }
    
    // Calculer les priorités d'allocation pour chaque nœud
    const allocationPriorities = this._calculateAllocationPriorities(roadmap, dependencies, criticalPaths, cognitiveLoadAnalysis);
    
    // Allouer les ressources en fonction des priorités
    const nodeAllocations = this._allocateResourcesByPriority(roadmap, resources, allocationPriorities);
    result.nodeAllocations = nodeAllocations;
    
    // Calculer les statistiques globales
    const totalAllocation = {};
    const utilizationRate = {};
    
    // Initialiser les totaux
    for (const resourceType of Object.keys(resources)) {
      totalAllocation[resourceType] = 0;
    }
    
    // Calculer les totaux
    for (const [nodeId, allocation] of Object.entries(nodeAllocations)) {
      for (const [resourceType, amount] of Object.entries(allocation)) {
        if (totalAllocation[resourceType] !== undefined) {
          totalAllocation[resourceType] += amount;
        }
      }
    }
    
    // Calculer les taux d'utilisation
    for (const [resourceType, amount] of Object.entries(totalAllocation)) {
      utilizationRate[resourceType] = resources[resourceType] > 0 ? amount / resources[resourceType] : 0;
    }
    
    result.totalAllocation = totalAllocation;
    result.utilizationRate = utilizationRate;
    
    // Calculer l'efficacité de l'allocation
    result.allocationEfficiency = this._calculateAllocationEfficiency(nodeAllocations, allocationPriorities, resources);
    
    return result;
  }
  
  /**
   * Calcule les priorités d'allocation pour chaque nœud
   * @param {Object} roadmap - Roadmap à équilibrer
   * @param {Object} dependencies - Dépendances de la roadmap
   * @param {Object} criticalPaths - Chemins critiques de la roadmap
   * @param {Object} cognitiveLoadAnalysis - Analyse de la charge cognitive
   * @returns {Object} - Priorités d'allocation pour chaque nœud
   * @private
   */
  _calculateAllocationPriorities(roadmap, dependencies, criticalPaths, cognitiveLoadAnalysis) {
    const allocationPriorities = {};
    
    // Fonction récursive pour calculer les priorités
    const calculatePriority = (node) => {
      // Facteurs de priorité
      let priority = 0;
      
      // Facteur 1: Criticité
      if (criticalPaths.criticalNodes.includes(node.id)) {
        priority += this.options.allocationFactors.criticality;
      }
      
      // Facteur 2: Complexité cognitive
      const cognitiveLoad = cognitiveLoadAnalysis.nodeLoads[node.id] || 0;
      priority += cognitiveLoad * this.options.allocationFactors.complexity;
      
      // Facteur 3: Priorité stratégique
      if (node.metadata && node.metadata.strategic && node.metadata.strategic.priority) {
        const strategicPriority = node.metadata.strategic.priority;
        if (strategicPriority === 'critical') priority += this.options.allocationFactors.priority * 1.0;
        else if (strategicPriority === 'high') priority += this.options.allocationFactors.priority * 0.8;
        else if (strategicPriority === 'medium') priority += this.options.allocationFactors.priority * 0.5;
        else if (strategicPriority === 'low') priority += this.options.allocationFactors.priority * 0.2;
      }
      
      // Normaliser la priorité entre 0 et 1
      priority = Math.min(Math.max(priority, 0), 1);
      
      // Stocker la priorité
      allocationPriorities[node.id] = priority;
      
      // Calculer les priorités des enfants
      if (node.children && node.children.length > 0) {
        node.children.forEach(child => {
          calculatePriority(child);
        });
      }
    };
    
    // Commencer par le nœud racine
    calculatePriority(roadmap);
    
    return allocationPriorities;
  }
  
  /**
   * Alloue les ressources en fonction des priorités
   * @param {Object} roadmap - Roadmap à équilibrer
   * @param {Object} resources - Ressources disponibles
   * @param {Object} allocationPriorities - Priorités d'allocation
   * @returns {Object} - Allocations de ressources pour chaque nœud
   * @private
   */
  _allocateResourcesByPriority(roadmap, resources, allocationPriorities) {
    const nodeAllocations = {};
    
    // Trier les nœuds par priorité décroissante
    const sortedNodes = Object.entries(allocationPriorities)
      .sort((a, b) => b[1] - a[1])
      .map(([nodeId]) => nodeId);
    
    // Ressources restantes
    const remainingResources = { ...resources };
    
    // Allouer les ressources aux nœuds par ordre de priorité
    for (const nodeId of sortedNodes) {
      // Calculer l'allocation pour ce nœud
      const allocation = this._calculateNodeAllocation(nodeId, remainingResources, allocationPriorities[nodeId]);
      
      // Stocker l'allocation
      nodeAllocations[nodeId] = allocation;
      
      // Mettre à jour les ressources restantes
      for (const [resourceType, amount] of Object.entries(allocation)) {
        if (remainingResources[resourceType] !== undefined) {
          remainingResources[resourceType] -= amount;
        }
      }
    }
    
    return nodeAllocations;
  }
  
  /**
   * Calcule l'allocation de ressources pour un nœud
   * @param {string} nodeId - ID du nœud
   * @param {Object} remainingResources - Ressources restantes
   * @param {number} priority - Priorité d'allocation
   * @returns {Object} - Allocation de ressources pour le nœud
   * @private
   */
  _calculateNodeAllocation(nodeId, remainingResources, priority) {
    const allocation = {};
    
    // Allouer les ressources en fonction de la priorité
    for (const [resourceType, amount] of Object.entries(remainingResources)) {
      // Calculer l'allocation proportionnelle à la priorité
      const allocationAmount = amount * priority * 0.2; // Limiter à 20% des ressources restantes
      
      // Stocker l'allocation
      allocation[resourceType] = Math.min(allocationAmount, amount);
    }
    
    return allocation;
  }
  
  /**
   * Calcule l'efficacité de l'allocation des ressources
   * @param {Object} nodeAllocations - Allocations de ressources pour chaque nœud
   * @param {Object} allocationPriorities - Priorités d'allocation
   * @param {Object} resources - Ressources disponibles
   * @returns {number} - Efficacité de l'allocation (0-1)
   * @private
   */
  _calculateAllocationEfficiency(nodeAllocations, allocationPriorities, resources) {
    // TODO: Implémenter le calcul de l'efficacité de l'allocation
    return 0.8;
  }
  
  /**
   * Détecte les surcharges de ressources
   * @param {Object} roadmap - Roadmap à équilibrer
   * @param {Object} resourceAllocation - Allocation des ressources
   * @param {Object} resources - Ressources disponibles
   * @returns {Object} - Résultat de la détection des surcharges
   * @private
   */
  _detectOverloads(roadmap, resourceAllocation, resources) {
    // Initialiser le résultat
    const result = {
      overloadedResources: [],
      overloadedNodes: [],
      overloadSeverity: {},
      recommendations: []
    };
    
    // Détecter les ressources surchargées
    for (const [resourceType, utilizationRate] of Object.entries(resourceAllocation.utilizationRate)) {
      if (utilizationRate > 0.9) {
        result.overloadedResources.push(resourceType);
        result.overloadSeverity[resourceType] = 'high';
      } else if (utilizationRate > 0.7) {
        result.overloadedResources.push(resourceType);
        result.overloadSeverity[resourceType] = 'medium';
      }
    }
    
    // Détecter les nœuds surchargés
    for (const [nodeId, allocation] of Object.entries(resourceAllocation.nodeAllocations)) {
      let isOverloaded = false;
      
      for (const [resourceType, amount] of Object.entries(allocation)) {
        const resourceAmount = resources[resourceType] || 0;
        if (resourceAmount > 0 && amount / resourceAmount > 0.3) {
          isOverloaded = true;
          break;
        }
      }
      
      if (isOverloaded) {
        result.overloadedNodes.push(nodeId);
      }
    }
    
    // Générer des recommandations
    if (result.overloadedResources.length > 0) {
      result.recommendations.push({
        type: 'increase_resources',
        resources: result.overloadedResources,
        description: 'Augmenter les ressources disponibles pour les types surchargés'
      });
    }
    
    if (result.overloadedNodes.length > 0) {
      result.recommendations.push({
        type: 'redistribute_load',
        nodes: result.overloadedNodes,
        description: 'Redistribuer la charge des nœuds surchargés'
      });
    }
    
    return result;
  }
}

// Exporter la classe
if (typeof module !== 'undefined') {
  module.exports = ResourceBalancer;
}

// Exposer la classe globalement dans les environnements navigateur
if (typeof window !== 'undefined') {
  window.ResourceBalancer = ResourceBalancer;
}
