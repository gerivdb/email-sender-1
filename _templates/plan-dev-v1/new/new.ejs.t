---
to: d:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/projet/roadmaps/plans/consolidated/plan-dev-<%= version %>-<%= title.toLowerCase().replace(/ /g, '-').replace(/[^a-z0-9\-]/g, '').slice(0,50) %>.md
encoding: utf8
---
<% 
// Initialize logger
const { createLogger } = require('../../../helpers/logger-helper.js');
const logger = createLogger({ verbosity: 'info' });

// Initialize tasks first to avoid 'Cannot access tasks before initialization' error
var tasks = []; 

function calculateProgress(taskList) {
  if (!taskList || taskList.length === 0) {
    logger.debug('No tasks found for progress calculation');
    return 0;
  }
  const totalTasks = taskList.reduce((sum, task) => sum + (task.subtasks ? task.subtasks.length : 1), 0);
  const completedTasks = taskList.reduce((sum, task) => sum + (task.done ? 1 : 0), 0);
  const progress = totalTasks === 0 ? 0 : Math.round((completedTasks / totalTasks) * 100);
  logger.debug(`Progress calculation: ${completedTasks}/${totalTasks} = ${progress}%`);
  return progress;
}

function generateTOC(phases) {
  logger.debug('Generating table of contents');
  let toc = '';
  for (let i = 1; i <= phases; i++) {
    toc += `- [${i}] Phase ${i}\n`;
  }
  return toc;
}
%>

# Plan de développement <%= version %> - <%= title %>
*Version 1.0 - <%= new Date().toISOString().split('T')[0] %> - Progression globale : <%= calculateProgress(tasks) %>%*

<%= description %>

## Table des matières
<%- generateTOC(phases) %>

<% 
// Étendre la granularité des tâches avec des niveaux supplémentaires
const extendedLevels = [2, 3, 3, 3, 3, 3, 3, 3, 3]; // Ajout de niveaux supplémentaires
const extendedLabels = ['Tâche principale', 'Sous-tâche', 'Sous-sous-tâche', 'Action', 'Étape', 'Détail', 'Sous-détail', 'Micro-détail', 'Nano-détail'];

// Ajout de descriptions personnalisées basées sur les paramètres d'entrée
const customDescriptions = {
  '1.1.1.1.1.1': 'Documenter les cas d\'utilisation pour les commandes de démarrage/arrêt.',
  '2.1.1.1.1': 'Définir les interfaces des modules pour assurer une intégration fluide.',
  '3.1.1.1': 'Identifier les scénarios de test pour chaque module.'
};

// Ajout de descriptions par défaut pour toutes les tâches
const defaultDescriptions = {
  '1': 'Phase d\'analyse et de conception.',
  '2': 'Phase de développement des fonctionnalités principales.',
  '3': 'Phase de tests pour valider les modules.',
  '4': 'Phase de déploiement en production.',
  '5': 'Phase d\'amélioration continue.'
};

// Ajout de modèles pour les sections "Entrées", "Sorties", et "Conditions préalables"
const predefinedSections = {
  inputs: "Entrées : commandes utilisateur, configurations système.",
  outputs: "Sorties : états des serveurs, fichiers de logs.",
  prerequisites: "Conditions préalables : serveurs MCP configurés, accès réseau disponible."
};

/**
 * Fonction mise à jour pour générer des tâches hiérarchiques avec granularité étendue et descriptions détaillées.
 * @param {string} prefix - Préfixe pour les identifiants des tâches (ex. : "1.").
 * @param {Array<number>} levels - Nombre d'éléments à chaque niveau.
 * @param {Array<string>} labels - Titres pour chaque niveau.
 * @param {number} depth - Profondeur actuelle dans la hiérarchie.
 * @returns {string} - Liste hiérarchique des tâches.
 */
function renderExtendedTasks(prefix, levels, labels, depth = 0) {
  logger.debug(`Rendering tasks for prefix ${prefix}`);
  let out = '';
  for (let i = 1; i <= (levels[0] || 1); i++) {
    const num = prefix + i;
    const label = labels[0] || 'Tâche';
    const indent = '  '.repeat(depth);
    const description = customDescriptions[num] || defaultDescriptions[prefix.split('.')[0]] || '';
    logger.debug(`Adding task ${num}: ${label} ${i} ${description}`);
    
    out += `${indent}- [ ] **${num}** ${label} ${i}${description ? ' - ' + description : ''}\n`;

    // Ajouter des sous-tâches si des niveaux supplémentaires existent
    if (levels.length > 1) {
      out += renderExtendedTasks(num + '.', levels.slice(1), labels.slice(1), depth + 1);
    }

    // Ajouter des descriptions détaillées pour chaque tâche
    out += `${indent}  - Étape 1 : Définir les objectifs\n`;
    out += `${indent}  - Étape 2 : Identifier les parties prenantes\n`;
    out += `${indent}  - Étape 3 : Documenter les résultats\n`;
    out += `${indent}  - Étape 4 : Valider les étapes avec l'équipe\n`;
    out += `${indent}  - Étape 5 : Ajouter des schémas ou diagrammes si nécessaire\n`;
    out += `${indent}  - Étape 6 : Vérifier les dépendances\n`;
    out += `${indent}  - Étape 7 : Finaliser et archiver\n`;
    out += `${indent}  - Étape 8 : Effectuer une revue par les pairs\n`;
    out += `${indent}  - Étape 9 : Planifier les prochaines actions\n`;

    // Ajouter les sections "Entrées", "Sorties", et "Conditions préalables"
    out += `${indent}  - ${predefinedSections.inputs}\n`;
    out += `${indent}  - ${predefinedSections.outputs}\n`;
    out += `${indent}  - ${predefinedSections.prerequisites}\n`;
  }
  return out;
}

// Étendre la granularité des phases 2 à 5 pour correspondre à la phase 1
const extendedLevelsByPhase = {
  1: [2, 3, 3, 3, 3, 3, 3, 3, 3],
  2: [2, 3, 3, 3, 3, 3, 3, 3, 3],
  3: [2, 3, 3, 3, 3, 3, 3, 3, 3],
  4: [2, 3, 3, 3, 3, 3, 3, 3, 3],
  5: [2, 3, 3, 3, 3, 3, 3, 3, 3]
};

// Générer des tâches pour chaque phase avec granularité uniforme
function renderTasksForPhase(phase) {
  logger.info(`Generating tasks for phase ${phase}`);
  return renderExtendedTasks(phase + '.', extendedLevelsByPhase[phase], extendedLabels);
}
%>

<% for (let i = 1; i <= phases; i++) { %>
## <%= i %>. Phase <%= i %> (Phase <%= i %>)
<%- renderTasksForPhase(i) %>
<% } %>
