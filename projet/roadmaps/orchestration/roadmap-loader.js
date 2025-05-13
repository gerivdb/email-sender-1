/**
 * Chargeur de plans de roadmap
 * Ce module charge tous les plans disponibles dans le dossier projet/roadmaps/json/
 */

// Liste des plans disponibles
const availablePlans = [
  {
    id: 'v12',
    title: 'Architecture Cognitive (v12)',
    file: 'plan-dev-v12-architecture-cognitive.json'
  },
  {
    id: 'v11',
    title: 'Orchestrateur de Roadmaps (v11)',
    file: 'plan-dev-v11-orchestrateur-roadmaps.json'
  },
  {
    id: 'v10',
    title: 'CRUD Thématique (v10)',
    file: 'plan-dev-v10-CRUD-thematique.json'
  },
  {
    id: 'v9',
    title: 'Task Master avec LWM/LCM (v9)',
    file: 'plan-dev-v9-LWM-LCM-task-master.json'
  },
  {
    id: 'v8',
    title: 'RAG Roadmap (v8)',
    file: 'plan-dev-v8-RAG-roadmap-s1-7.json'
  },
  {
    id: 'all',
    title: 'Tous les plans',
    file: 'all-plans.json'
  }
];

/**
 * Charge un plan de roadmap à partir de son fichier JSON
 * @param {string} planId - Identifiant du plan à charger
 * @returns {Promise<Object>} - Données du plan
 */
async function loadPlan(planId) {
  try {
    // Vérifier si on demande tous les plans
    if (planId === 'all') {
      return loadAllPlans();
    }

    // Trouver le plan dans la liste des plans disponibles
    const plan = availablePlans.find(p => p.id === planId);
    if (!plan) {
      throw new Error(`Plan ${planId} non trouvé`);
    }

    // Simuler le chargement du fichier JSON (dans un environnement réel, cela serait un fetch)
    // Dans cette version simplifiée, nous utilisons les données de test
    return loadTestRoadmapById(planId);
  } catch (error) {
    console.error('Erreur lors du chargement du plan:', error);
    // Retourner un plan par défaut en cas d'erreur
    return loadTestRoadmapById('v12');
  }
}

/**
 * Charge tous les plans disponibles et les combine en un seul
 * @returns {Promise<Object>} - Données combinées de tous les plans
 */
async function loadAllPlans() {
  try {
    // Charger tous les plans individuellement
    const plans = [];
    for (const plan of availablePlans) {
      if (plan.id !== 'all') {
        const planData = await loadTestRoadmapById(plan.id);
        plans.push(planData);
      }
    }

    // Combiner tous les plans en un seul
    const combinedPlan = {
      id: 'all-plans',
      title: 'Tous les plans de roadmap',
      description: 'Combinaison de tous les plans disponibles',
      type: 'COSMOS',
      status: 'in_progress',
      sections: []
    };

    // Ajouter les sections de chaque plan
    plans.forEach(plan => {
      // Ajouter une section principale pour le plan
      const planSection = {
        id: plan.id,
        title: plan.title,
        status: plan.status,
        description: plan.description,
        tasks: []
      };

      // Ajouter les tâches du plan
      if (plan.sections && plan.sections.length > 0) {
        plan.sections.forEach(section => {
          // Ajouter la section comme tâche
          planSection.tasks.push({
            id: `${plan.id}-${section.id}`,
            title: section.title,
            status: section.status,
            description: section.description,
            subtasks: section.tasks || []
          });
        });
      }

      combinedPlan.sections.push(planSection);
    });

    return combinedPlan;
  } catch (error) {
    console.error('Erreur lors du chargement de tous les plans:', error);
    return loadTestRoadmapById('v12');
  }
}

/**
 * Charge un plan de test en fonction de son ID
 * @param {string} planId - Identifiant du plan à charger
 * @returns {Object} - Données du plan de test
 */
function loadTestRoadmapById(planId) {
  // Plan v12 : Architecture Cognitive
  if (planId === 'v12') {
    // Dans un environnement réel, nous chargerions le fichier JSON
    // Ici, nous simulons la structure du fichier JSON
    const v12Data = {
      id: 'id-qd3fntj2w',
      title: 'Plan de développement v12 : Architecture cognitive des roadmaps',
      description: 'Plan de développement de l\'architecture cognitive à 10 niveaux',
      type: 'COSMOS',
      status: 'in_progress',
      sections: [
        {
          id: '1',
          title: 'Fondations de l\'architecture cognitive',
          status: 'in_progress',
          description: 'Établir les fondations conceptuelles de l\'architecture cognitive',
          tasks: [
            {
              id: '1.1',
              title: 'Définir le modèle hiérarchique complet',
              status: 'in_progress',
              description: 'Conception de la structure hiérarchique à 10 niveaux',
              subtasks: [
                {
                  id: '1.1.1',
                  title: 'Concevoir la structure à 10 niveaux',
                  status: 'completed',
                  description: 'Définition des 10 niveaux de l\'architecture cognitive'
                },
                {
                  id: '1.1.2',
                  title: 'Implémenter les dimensions transversales',
                  status: 'in_progress',
                  description: 'Intégration des dimensions temporelles, cognitives, organisationnelles et stratégiques'
                },
                {
                  id: '1.1.3',
                  title: 'Créer le système d\'émergence et d\'auto-organisation',
                  status: 'planned',
                  description: 'Développement des mécanismes d\'auto-organisation et d\'adaptation dynamique'
                }
              ]
            },
            {
              id: '1.2',
              title: 'Implémenter les dimensions transversales',
              status: 'planned',
              description: 'Développement des dimensions qui traversent tous les niveaux hiérarchiques'
            },
            {
              id: '1.3',
              title: 'Créer le système d\'émergence et d\'auto-organisation',
              status: 'planned',
              description: 'Mise en place des mécanismes d\'émergence et d\'auto-organisation'
            }
          ]
        },
        {
          id: '2',
          title: 'Modèle de données cognitif',
          status: 'planned',
          description: 'Conception et implémentation du modèle de données cognitif',
          tasks: [
            {
              id: '2.1',
              title: 'Concevoir le schéma de données hiérarchique',
              status: 'planned',
              description: 'Définition du schéma de données pour chaque niveau hiérarchique'
            },
            {
              id: '2.2',
              title: 'Implémenter le format de sérialisation',
              status: 'planned',
              description: 'Développement des formats JSON et Markdown pour la sérialisation des données'
            }
          ]
        },
        {
          id: '3',
          title: 'Visualisation cognitive',
          status: 'planned',
          description: 'Développement des visualisations pour l\'architecture cognitive',
          tasks: [
            {
              id: '3.1',
              title: 'Développer la visualisation "cosmos"',
              status: 'planned',
              description: 'Création de la visualisation cosmique pour les niveaux supérieurs'
            },
            {
              id: '3.2',
              title: 'Implémenter la navigation multi-échelle',
              status: 'planned',
              description: 'Développement de la navigation fluide entre les différents niveaux'
            },
            {
              id: '3.3',
              title: 'Ajouter les visualisations dimensionnelles',
              status: 'planned',
              description: 'Intégration des visualisations pour les dimensions transversales'
            }
          ]
        },
        {
          id: '4',
          title: 'Moteur d\'orchestration cognitive',
          status: 'in_progress',
          description: 'Développement du moteur d\'orchestration pour l\'architecture cognitive',
          tasks: [
            {
              id: '4.1',
              title: 'Implémenter l\'analyseur de dépendances',
              status: 'completed',
              description: 'Développement de l\'analyseur de dépendances hiérarchiques et transversales'
            },
            {
              id: '4.2',
              title: 'Créer l\'optimiseur de chemins critiques',
              status: 'in_progress',
              description: 'Implémentation de l\'optimiseur pour identifier et optimiser les chemins critiques'
            },
            {
              id: '4.3',
              title: 'Développer le système d\'équilibrage de ressources',
              status: 'planned',
              description: 'Création du système pour équilibrer les ressources entre les différentes tâches'
            }
          ]
        },
        {
          id: '5',
          title: 'Interface utilisateur cognitive',
          status: 'planned',
          description: 'Développement de l\'interface utilisateur pour l\'architecture cognitive',
          tasks: [
            {
              id: '5.1',
              title: 'Créer le tableau de bord principal',
              status: 'planned',
              description: 'Développement du tableau de bord pour visualiser l\'architecture cognitive'
            },
            {
              id: '5.2',
              title: 'Implémenter les contrôles de navigation',
              status: 'planned',
              description: 'Création des contrôles pour naviguer entre les différents niveaux'
            },
            {
              id: '5.3',
              title: 'Développer les outils d\'édition',
              status: 'planned',
              description: 'Implémentation des outils pour éditer l\'architecture cognitive'
            }
          ]
        }
      ]
    };

    return v12Data;
  }

  // Plan v11 : Orchestrateur de Roadmaps
  else if (planId === 'v11') {
    return {
      id: 'id-kxnaho7fz',
      title: 'Plan de développement v11 : Orchestrateur intelligent de roadmaps',
      description: 'Système d\'orchestration pour la gestion intelligente des roadmaps',
      type: 'COSMOS',
      status: 'in_progress',
      sections: [
        {
          id: '1',
          title: 'Conception de l\'architecture d\'orchestration',
          tasks: [
            { id: '1.1', title: 'Définir le modèle de données de l\'orchestrateur', status: 'planned' },
            { id: '1.2', title: 'Concevoir l\'architecture du service d\'orchestration', status: 'planned' }
          ]
        },
        {
          id: '2',
          title: 'Moteur d\'orchestration',
          tasks: [
            { id: '2.1', title: 'Développer le moteur d\'analyse de dépendances', status: 'planned' },
            { id: '2.2', title: 'Implémenter l\'optimiseur de chemins critiques', status: 'planned' },
            { id: '2.3', title: 'Créer le système d\'équilibrage de ressources', status: 'planned' }
          ]
        },
        {
          id: '3',
          title: 'Interface utilisateur',
          tasks: [
            { id: '3.1', title: 'Développer le tableau de bord principal', status: 'planned' },
            { id: '3.2', title: 'Créer les visualisations interactives', status: 'planned' }
          ]
        }
      ]
    };
  }

  // Plan v10 : CRUD Thématique
  else if (planId === 'v10') {
    return {
      id: 'id-caycfnrv2',
      title: 'Plan de développement v10 : Système CRUD modulaire thématique pour roadmaps',
      description: 'Système de gestion modulaire pour les roadmaps thématiques',
      type: 'COSMOS',
      status: 'in_progress',
      sections: [
        {
          id: '1',
          title: 'Analyse et cartographie des roadmaps existantes',
          tasks: [
            { id: '1.1', title: 'Analyser la structure thématique des roadmaps actuelles', status: 'planned' },
            { id: '1.2', title: 'Cartographier les relations entre thèmes', status: 'planned' }
          ]
        },
        {
          id: '2',
          title: 'Conception du système CRUD',
          tasks: [
            { id: '2.1', title: 'Définir le modèle de données thématique', status: 'planned' },
            { id: '2.2', title: 'Concevoir les interfaces de manipulation', status: 'planned' }
          ]
        },
        {
          id: '3',
          title: 'Implémentation du système',
          tasks: [
            { id: '3.1', title: 'Développer le module de création', status: 'planned' },
            { id: '3.2', title: 'Implémenter le module de lecture', status: 'planned' },
            { id: '3.3', title: 'Créer le module de mise à jour', status: 'planned' },
            { id: '3.4', title: 'Développer le module de suppression', status: 'planned' }
          ]
        }
      ]
    };
  }

  // Plan v9 : Task Master avec LWM/LCM
  else if (planId === 'v9') {
    return {
      id: 'id-sz1qcl5wp',
      title: 'Plan de développement v9 : Intégration des concepts de Task Master avec LWM/LCM',
      description: 'Intégration des modèles de workflow et de concepts',
      type: 'COSMOS',
      status: 'in_progress',
      sections: [
        {
          id: '1',
          title: 'Introduction et vision',
          tasks: [
            { id: '1.1', title: 'Objectifs principaux', status: 'planned' }
          ]
        },
        {
          id: '2',
          title: 'Large Workflow Models (LWM)',
          tasks: [
            { id: '2.1', title: 'Conception du modèle de workflow', status: 'planned' },
            { id: '2.2', title: 'Implémentation du moteur d\'exécution', status: 'planned' }
          ]
        },
        {
          id: '3',
          title: 'Large Concept Models (LCM)',
          tasks: [
            { id: '3.1', title: 'Définition du modèle conceptuel', status: 'planned' },
            { id: '3.2', title: 'Implémentation du système de raisonnement', status: 'planned' }
          ]
        }
      ]
    };
  }

  // Plan v8 : RAG Roadmap
  else if (planId === 'v8') {
    return {
      id: 'id-gh2faqjl4',
      title: 'Plan de développement v8 : Système RAG pour roadmaps',
      description: 'Système de Retrieval-Augmented Generation pour roadmaps',
      type: 'COSMOS',
      status: 'in_progress',
      sections: [
        {
          id: '1',
          title: 'Infrastructure RAG',
          tasks: [
            { id: '1.1', title: 'Mise en place de Qdrant', status: 'planned' },
            { id: '1.2', title: 'Configuration des embeddings', status: 'planned' }
          ]
        },
        {
          id: '2',
          title: 'Indexation des roadmaps',
          tasks: [
            { id: '2.1', title: 'Développer le système d\'extraction', status: 'planned' },
            { id: '2.2', title: 'Implémenter l\'indexation vectorielle', status: 'planned' }
          ]
        },
        {
          id: '3',
          title: 'Interface de recherche',
          tasks: [
            { id: '3.1', title: 'Créer l\'API de recherche sémantique', status: 'planned' },
            { id: '3.2', title: 'Développer l\'interface utilisateur', status: 'planned' }
          ]
        }
      ]
    };
  }

  // Plan par défaut
  else {
    return {
      id: 'default',
      title: 'Plan par défaut',
      description: 'Aucun plan spécifique trouvé',
      type: 'COSMOS',
      status: 'planned',
      sections: []
    };
  }
}

/**
 * Récupère la liste des plans disponibles
 * @returns {Array} - Liste des plans disponibles
 */
function getAvailablePlans() {
  return availablePlans;
}

// Exporter les fonctions
window.RoadmapLoader = {
  loadPlan,
  getAvailablePlans
};
