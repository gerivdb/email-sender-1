/**
 * Données de test pour le moteur d'orchestration
 * 
 * Ce fichier contient des données de test pour simuler le fonctionnement du moteur d'orchestration
 * lorsque les fichiers JSON ne sont pas disponibles.
 */

// Roadmap de test
const testRoadmap = {
  id: "plan-dev-v12-architecture-cognitive",
  title: "Architecture Cognitive (v12)",
  description: "Plan de développement de l'architecture cognitive à 10 niveaux",
  type: "cosmos",
  status: "in_progress",
  metadata: {
    temporal: { horizon: "medium_term" },
    cognitive: { complexity: "complex" },
    strategic: { priority: "high" }
  },
  children: [
    {
      id: "section-1",
      title: "Fondations conceptuelles",
      type: "galaxy",
      status: "completed",
      children: []
    },
    {
      id: "section-4",
      title: "Système d'orchestration cognitive",
      type: "galaxy",
      status: "in_progress",
      children: [
        {
          id: "task-4-1",
          title: "Développer le moteur d'orchestration",
          type: "stellar_system",
          status: "completed",
          children: []
        }
      ]
    }
  ]
};

// Résultats de l'analyse des dépendances
const testDependencies = {
  roadmapId: "plan-dev-v12-architecture-cognitive",
  hierarchicalDependencies: [
    { parentId: "plan-dev-v12-architecture-cognitive", childId: "section-1", type: "hierarchical" },
    { parentId: "plan-dev-v12-architecture-cognitive", childId: "section-4", type: "hierarchical" },
    { parentId: "section-4", childId: "task-4-1", type: "hierarchical" }
  ],
  transversalDependencies: [
    { sourceId: "section-1", targetId: "section-4", type: "transversal", strength: 0.8, explicit: true }
  ],
  conflicts: [],
  nodeDependencies: {
    "section-1": [],
    "section-4": [
      { id: "section-1", type: "transversal", strength: 0.8 }
    ],
    "task-4-1": [
      { id: "section-4", type: "hierarchical", strength: 1.0 }
    ]
  },
  dependencyGraph: {
    nodes: [
      { id: "plan-dev-v12-architecture-cognitive", label: "Architecture Cognitive (v12)", type: "cosmos", status: "in_progress" },
      { id: "section-1", label: "Fondations conceptuelles", type: "galaxy", status: "completed" },
      { id: "section-4", label: "Système d'orchestration cognitive", type: "galaxy", status: "in_progress" },
      { id: "task-4-1", label: "Développer le moteur d'orchestration", type: "stellar_system", status: "completed" }
    ],
    edges: [
      { id: "h-plan-dev-v12-architecture-cognitive-section-1", source: "plan-dev-v12-architecture-cognitive", target: "section-1", type: "hierarchical" },
      { id: "h-plan-dev-v12-architecture-cognitive-section-4", source: "plan-dev-v12-architecture-cognitive", target: "section-4", type: "hierarchical" },
      { id: "h-section-4-task-4-1", source: "section-4", target: "task-4-1", type: "hierarchical" },
      { id: "t-section-1-section-4", source: "section-1", target: "section-4", type: "transversal", strength: 0.8 }
    ]
  }
};

// Résultats de l'optimisation des chemins critiques
const testCriticalPaths = {
  roadmapId: "plan-dev-v12-architecture-cognitive",
  criticalPaths: [
    {
      id: "path-section-1",
      nodes: ["section-1", "section-4", "task-4-1"],
      criticality: 0.85,
      duration: 60,
      risk: 0.4
    }
  ],
  criticalNodes: ["section-1", "section-4", "task-4-1"],
  mainPath: {
    id: "path-section-1",
    nodes: ["section-1", "section-4", "task-4-1"],
    criticality: 0.85,
    duration: 60,
    risk: 0.4
  },
  optimizationSuggestions: [
    {
      type: "parallelize",
      nodes: ["section-1", "section-4"],
      impact: {
        durationReduction: 15,
        riskIncrease: 0.1
      }
    }
  ],
  simulationResults: {
    originalDuration: 60,
    optimizedDuration: 45,
    improvement: 15,
    riskReduction: 0.2
  },
  estimatedCompletion: {
    duration: 60,
    startDate: new Date(),
    endDate: new Date(Date.now() + 60 * 24 * 60 * 60 * 1000),
    confidence: 0.7
  },
  riskFactors: {
    complexity: 0.6,
    dependencies: 0.7,
    resources: 0.5,
    uncertainty: 0.4,
    overall: 0.55
  }
};

// Résultats de l'équilibrage des ressources
const testResourceAllocations = {
  roadmapId: "plan-dev-v12-architecture-cognitive",
  cognitiveLoadAnalysis: {
    totalLoad: 2.1,
    averageLoad: 0.7,
    maxLoad: 0.9,
    loadDistribution: {
      low: 0.0,
      medium: 0.67,
      high: 0.33
    },
    nodeLoads: {
      "section-1": 0.5,
      "section-4": 0.9,
      "task-4-1": 0.7
    }
  },
  resourceAllocation: {
    totalAllocation: {
      developers: 4.5,
      designers: 1.8,
      testers: 2.7,
      cognitive_load: 80
    },
    utilizationRate: {
      developers: 0.9,
      designers: 0.9,
      testers: 0.9,
      cognitive_load: 0.8
    },
    allocationEfficiency: 0.85,
    nodeAllocations: {
      "section-1": {
        developers: 1.0,
        designers: 0.5,
        testers: 0.5,
        cognitive_load: 20
      },
      "section-4": {
        developers: 2.0,
        designers: 1.0,
        testers: 1.5,
        cognitive_load: 40
      },
      "task-4-1": {
        developers: 1.5,
        designers: 0.3,
        testers: 0.7,
        cognitive_load: 20
      }
    }
  },
  overloadDetection: {
    overloadedResources: ["developers"],
    overloadedNodes: ["section-4"],
    overloadSeverity: {
      developers: "medium"
    },
    recommendations: [
      {
        type: "increase_resources",
        resources: ["developers"],
        description: "Augmenter les ressources disponibles pour les développeurs"
      },
      {
        type: "redistribute_load",
        nodes: ["section-4"],
        description: "Redistribuer la charge du nœud 'Système d'orchestration cognitive'"
      }
    ]
  }
};

// Fonction pour simuler le chargement d'une roadmap
function loadTestRoadmap() {
  return testRoadmap;
}

// Fonction pour simuler l'analyse des dépendances
function analyzeTestDependencies() {
  return testDependencies;
}

// Fonction pour simuler l'optimisation des chemins critiques
function optimizeTestCriticalPaths() {
  return testCriticalPaths;
}

// Fonction pour simuler l'équilibrage des ressources
function balanceTestResources() {
  return testResourceAllocations;
}

// Fonction pour simuler la génération d'un plan d'exécution
function generateTestExecutionPlan() {
  return {
    roadmapId: "plan-dev-v12-architecture-cognitive",
    tasks: [
      {
        id: "section-1",
        title: "Fondations conceptuelles",
        type: "galaxy",
        status: "completed",
        description: "Établir les fondations conceptuelles de l'architecture cognitive",
        parentId: null,
        dependencies: [],
        isCritical: true,
        priority: 0.9,
        estimatedEffort: 30,
        allocatedResources: {
          developers: 1.0,
          designers: 0.5,
          testers: 0.5,
          cognitive_load: 20
        }
      },
      {
        id: "section-4",
        title: "Système d'orchestration cognitive",
        type: "galaxy",
        status: "in_progress",
        description: "Développer le système d'orchestration cognitive",
        parentId: null,
        dependencies: [
          { id: "section-1", type: "transversal", strength: 0.8 }
        ],
        isCritical: true,
        priority: 0.85,
        estimatedEffort: 40,
        allocatedResources: {
          developers: 2.0,
          designers: 1.0,
          testers: 1.5,
          cognitive_load: 40
        }
      },
      {
        id: "task-4-1",
        title: "Développer le moteur d'orchestration",
        type: "stellar_system",
        status: "completed",
        description: "Implémenter le moteur d'orchestration cognitive",
        parentId: "section-4",
        dependencies: [
          { id: "section-4", type: "hierarchical", strength: 1.0 }
        ],
        isCritical: true,
        priority: 0.8,
        estimatedEffort: 20,
        allocatedResources: {
          developers: 1.5,
          designers: 0.3,
          testers: 0.7,
          cognitive_load: 20
        }
      }
    ],
    criticalPath: testCriticalPaths.mainPath,
    resourceAllocations: testResourceAllocations,
    estimatedCompletion: testCriticalPaths.estimatedCompletion,
    riskFactors: testCriticalPaths.riskFactors
  };
}

// Exporter les fonctions
if (typeof module !== 'undefined') {
  module.exports = {
    loadTestRoadmap,
    analyzeTestDependencies,
    optimizeTestCriticalPaths,
    balanceTestResources,
    generateTestExecutionPlan
  };
}

// Exposer les fonctions globalement dans les environnements navigateur
if (typeof window !== 'undefined') {
  window.loadTestRoadmap = loadTestRoadmap;
  window.analyzeTestDependencies = analyzeTestDependencies;
  window.optimizeTestCriticalPaths = optimizeTestCriticalPaths;
  window.balanceTestResources = balanceTestResources;
  window.generateTestExecutionPlan = generateTestExecutionPlan;
}
