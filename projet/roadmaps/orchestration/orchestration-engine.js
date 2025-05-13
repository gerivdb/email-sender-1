/**
 * Moteur d'orchestration cognitive
 *
 * Ce module implémente le moteur d'orchestration pour l'architecture cognitive à 10 niveaux.
 * Il gère l'analyse des dépendances, l'optimisation des chemins critiques et l'équilibrage des ressources.
 */

// Dans un environnement navigateur, les classes sont déjà disponibles globalement
// Dans un environnement Node.js, nous les importons
if (typeof require !== 'undefined') {
  var { DependencyAnalyzer } = require('./dependency-analyzer');
  var CriticalPathOptimizer = require('./critical-path-optimizer');
  var ResourceBalancer = require('./resource-balancer');
}

class OrchestrationEngine {
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

      // Dimensions transversales
      dimensions: [
        'temporal',    // Dimension temporelle
        'cognitive',   // Dimension cognitive
        'organizational', // Dimension organisationnelle
        'strategic'    // Dimension stratégique
      ],

      // Seuils de charge cognitive
      cognitiveLoadThresholds: {
        low: 0.3,      // Charge cognitive faible
        medium: 0.6,   // Charge cognitive moyenne
        high: 0.8      // Charge cognitive élevée
      },

      // Poids des dimensions pour le calcul des priorités
      dimensionWeights: {
        temporal: 0.3,      // Poids de la dimension temporelle
        cognitive: 0.2,     // Poids de la dimension cognitive
        organizational: 0.2, // Poids de la dimension organisationnelle
        strategic: 0.3      // Poids de la dimension stratégique
      },

      // Autres options
      ...options
    };

    // Initialiser les systèmes
    this.dependencyAnalyzer = new DependencyAnalyzer(this.options);
    this.criticalPathOptimizer = new CriticalPathOptimizer(this.options);
    this.resourceBalancer = new ResourceBalancer(this.options);

    // État interne
    this.roadmaps = new Map(); // Stockage des roadmaps
    this.dependencies = new Map(); // Stockage des dépendances
    this.criticalPaths = new Map(); // Stockage des chemins critiques
    this.resourceAllocations = new Map(); // Stockage des allocations de ressources
  }

  /**
   * Charge une roadmap dans le moteur d'orchestration
   * @param {Object} roadmap - Données de la roadmap
   * @returns {string} - ID de la roadmap chargée
   */
  loadRoadmap(roadmap) {
    try {
      // Vérifier que la roadmap a un ID
      if (!roadmap.id) {
        roadmap.id = 'roadmap-' + Date.now();
      }

      // Stocker la roadmap
      this.roadmaps.set(roadmap.id, roadmap);

      // Analyser les dépendances
      this.analyzeDependencies(roadmap.id);

      return roadmap.id;
    } catch (error) {
      console.error('Erreur lors du chargement de la roadmap:', error);
      throw error;
    }
  }

  /**
   * Analyse les dépendances d'une roadmap
   * @param {string} roadmapId - ID de la roadmap à analyser
   * @returns {Object} - Résultat de l'analyse des dépendances
   */
  analyzeDependencies(roadmapId) {
    try {
      // Récupérer la roadmap
      const roadmap = this.roadmaps.get(roadmapId);
      if (!roadmap) {
        throw new Error(`Roadmap non trouvée: ${roadmapId}`);
      }

      // Analyser les dépendances
      const dependencies = this.dependencyAnalyzer.analyze(roadmap);

      // Stocker les dépendances
      this.dependencies.set(roadmapId, dependencies);

      return dependencies;
    } catch (error) {
      console.error('Erreur lors de l\'analyse des dépendances:', error);
      throw error;
    }
  }

  /**
   * Optimise les chemins critiques d'une roadmap
   * @param {string} roadmapId - ID de la roadmap à optimiser
   * @returns {Object} - Résultat de l'optimisation des chemins critiques
   */
  optimizeCriticalPaths(roadmapId) {
    try {
      // Récupérer la roadmap et ses dépendances
      const roadmap = this.roadmaps.get(roadmapId);
      const dependencies = this.dependencies.get(roadmapId);

      if (!roadmap) {
        throw new Error(`Roadmap non trouvée: ${roadmapId}`);
      }

      if (!dependencies) {
        throw new Error(`Dépendances non analysées pour la roadmap: ${roadmapId}`);
      }

      // Optimiser les chemins critiques
      const criticalPaths = this.criticalPathOptimizer.optimize(roadmap, dependencies);

      // Stocker les chemins critiques
      this.criticalPaths.set(roadmapId, criticalPaths);

      return criticalPaths;
    } catch (error) {
      console.error('Erreur lors de l\'optimisation des chemins critiques:', error);
      throw error;
    }
  }

  /**
   * Équilibre les ressources pour une roadmap
   * @param {string} roadmapId - ID de la roadmap à équilibrer
   * @param {Object} resources - Ressources disponibles
   * @returns {Object} - Résultat de l'équilibrage des ressources
   */
  balanceResources(roadmapId, resources) {
    try {
      // Récupérer la roadmap, ses dépendances et ses chemins critiques
      const roadmap = this.roadmaps.get(roadmapId);
      const dependencies = this.dependencies.get(roadmapId);
      const criticalPaths = this.criticalPaths.get(roadmapId);

      if (!roadmap) {
        throw new Error(`Roadmap non trouvée: ${roadmapId}`);
      }

      if (!dependencies) {
        throw new Error(`Dépendances non analysées pour la roadmap: ${roadmapId}`);
      }

      if (!criticalPaths) {
        throw new Error(`Chemins critiques non optimisés pour la roadmap: ${roadmapId}`);
      }

      // Équilibrer les ressources
      const resourceAllocations = this.resourceBalancer.balance(roadmap, dependencies, criticalPaths, resources);

      // Stocker les allocations de ressources
      this.resourceAllocations.set(roadmapId, resourceAllocations);

      return resourceAllocations;
    } catch (error) {
      console.error('Erreur lors de l\'équilibrage des ressources:', error);
      throw error;
    }
  }

  /**
   * Génère un plan d'exécution pour une roadmap
   * @param {string} roadmapId - ID de la roadmap
   * @returns {Object} - Plan d'exécution
   */
  generateExecutionPlan(roadmapId) {
    try {
      // Récupérer la roadmap, ses dépendances, ses chemins critiques et ses allocations de ressources
      const roadmap = this.roadmaps.get(roadmapId);
      const dependencies = this.dependencies.get(roadmapId);
      const criticalPaths = this.criticalPaths.get(roadmapId);
      const resourceAllocations = this.resourceAllocations.get(roadmapId);

      if (!roadmap) {
        throw new Error(`Roadmap non trouvée: ${roadmapId}`);
      }

      if (!dependencies) {
        throw new Error(`Dépendances non analysées pour la roadmap: ${roadmapId}`);
      }

      if (!criticalPaths) {
        throw new Error(`Chemins critiques non optimisés pour la roadmap: ${roadmapId}`);
      }

      if (!resourceAllocations) {
        throw new Error(`Ressources non équilibrées pour la roadmap: ${roadmapId}`);
      }

      // Générer le plan d'exécution
      const executionPlan = {
        roadmapId,
        tasks: [],
        criticalPath: criticalPaths.mainPath,
        resourceAllocations,
        estimatedCompletion: criticalPaths.estimatedCompletion,
        riskFactors: criticalPaths.riskFactors
      };

      // Ajouter les tâches au plan d'exécution
      this._addTasksToExecutionPlan(executionPlan, roadmap, dependencies, criticalPaths);

      return executionPlan;
    } catch (error) {
      console.error('Erreur lors de la génération du plan d\'exécution:', error);
      throw error;
    }
  }

  /**
   * Ajoute les tâches au plan d'exécution
   * @param {Object} executionPlan - Plan d'exécution
   * @param {Object} roadmap - Roadmap
   * @param {Object} dependencies - Dépendances
   * @param {Object} criticalPaths - Chemins critiques
   * @private
   */
  _addTasksToExecutionPlan(executionPlan, roadmap, dependencies, criticalPaths) {
    // Fonction récursive pour parcourir la roadmap
    const processNode = (node, parentId = null) => {
      // Créer la tâche
      const task = {
        id: node.id,
        title: node.title,
        type: node.type,
        status: node.status,
        description: node.description,
        parentId,
        dependencies: dependencies.nodeDependencies[node.id] || [],
        isCritical: criticalPaths.criticalNodes.includes(node.id),
        priority: this._calculatePriority(node, dependencies, criticalPaths),
        estimatedEffort: this._estimateEffort(node),
        allocatedResources: executionPlan.resourceAllocations.nodeAllocations[node.id] || {}
      };

      // Ajouter la tâche au plan d'exécution
      executionPlan.tasks.push(task);

      // Traiter les enfants
      if (node.children && node.children.length > 0) {
        node.children.forEach(child => {
          processNode(child, node.id);
        });
      }
    };

    // Commencer par le nœud racine
    processNode(roadmap);
  }

  /**
   * Calcule la priorité d'un nœud
   * @param {Object} node - Nœud
   * @param {Object} dependencies - Dépendances
   * @param {Object} criticalPaths - Chemins critiques
   * @returns {number} - Priorité du nœud
   * @private
   */
  _calculatePriority(node, dependencies, criticalPaths) {
    // Facteurs de priorité
    let priority = 0;

    // Facteur 1: Le nœud est-il sur le chemin critique?
    if (criticalPaths.criticalNodes.includes(node.id)) {
      priority += 0.5;
    }

    // Facteur 2: Nombre de dépendances
    const nodeDependencies = dependencies.nodeDependencies[node.id] || [];
    priority += nodeDependencies.length * 0.05;

    // Facteur 3: Dimensions
    if (node.metadata) {
      // Dimension temporelle
      if (node.metadata.temporal && node.metadata.temporal.horizon) {
        const horizon = node.metadata.temporal.horizon;
        if (horizon === 'immediate') priority += this.options.dimensionWeights.temporal * 1.0;
        else if (horizon === 'short_term') priority += this.options.dimensionWeights.temporal * 0.8;
        else if (horizon === 'medium_term') priority += this.options.dimensionWeights.temporal * 0.5;
        else if (horizon === 'long_term') priority += this.options.dimensionWeights.temporal * 0.2;
      }

      // Dimension cognitive
      if (node.metadata.cognitive && node.metadata.cognitive.complexity) {
        const complexity = node.metadata.cognitive.complexity;
        if (complexity === 'simple') priority += this.options.dimensionWeights.cognitive * 0.3;
        else if (complexity === 'moderate') priority += this.options.dimensionWeights.cognitive * 0.5;
        else if (complexity === 'complex') priority += this.options.dimensionWeights.cognitive * 0.7;
        else if (complexity === 'systemic') priority += this.options.dimensionWeights.cognitive * 1.0;
      }

      // Dimension stratégique
      if (node.metadata.strategic && node.metadata.strategic.priority) {
        const strategicPriority = node.metadata.strategic.priority;
        if (strategicPriority === 'critical') priority += this.options.dimensionWeights.strategic * 1.0;
        else if (strategicPriority === 'high') priority += this.options.dimensionWeights.strategic * 0.8;
        else if (strategicPriority === 'medium') priority += this.options.dimensionWeights.strategic * 0.5;
        else if (strategicPriority === 'low') priority += this.options.dimensionWeights.strategic * 0.2;
      }
    }

    // Normaliser la priorité entre 0 et 1
    return Math.min(Math.max(priority, 0), 1);
  }

  /**
   * Estime l'effort nécessaire pour un nœud
   * @param {Object} node - Nœud
   * @returns {number} - Effort estimé
   * @private
   */
  _estimateEffort(node) {
    // Estimation de base selon le type de nœud
    const baseEffort = {
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

    let effort = baseEffort[node.type] || 10;

    // Ajuster selon la complexité cognitive
    if (node.metadata && node.metadata.cognitive && node.metadata.cognitive.complexity) {
      const complexity = node.metadata.cognitive.complexity;
      if (complexity === 'simple') effort *= 0.5;
      else if (complexity === 'moderate') effort *= 1.0;
      else if (complexity === 'complex') effort *= 1.5;
      else if (complexity === 'systemic') effort *= 2.0;
    }

    return effort;
  }
}

// Exporter la classe
if (typeof module !== 'undefined') {
  module.exports = OrchestrationEngine;
}

// Exposer la classe globalement dans les environnements navigateur
if (typeof window !== 'undefined') {
  window.OrchestrationEngine = OrchestrationEngine;
}
