// Structure helper pour templates EJS
const path = require('path');
const { createLogger } = require('./logger-helper');
const logger = createLogger({ verbosity: 'info' });

/**
 * Helper pour la standardisation des structures EJS
 */
module.exports = {
  // Sections standards pour tous les plans
  standardSections: {
    header: {
      title: true,
      version: true, 
      date: true,
      progress: true
    },
    tableOfContents: true,
    phases: {
      title: true,
      progress: true,
      tasks: {
        title: true,
        description: true,
        subtasks: true,
        status: true
      }
    },
    metrics: {
      completed: true,
      total: true,
      efficiency: true,
      coverage: true
    }
  },

  // Format standard des fichiers générés
  fileNamingPattern: (version, title) => {
    const sanitizedTitle = title.toLowerCase()
      .replace(/ /g, '-')
      .replace(/[^a-z0-9\-]/g, '')
      .slice(0, 50);
    return `plan-dev-${version}-${sanitizedTitle}.md`;
  },

  // Validation des modèles
  validateTemplate: (template) => {
    logger.debug('Validating template structure');
    // Vérifie la présence des sections requises
    const requiredSections = ['header', 'phases', 'metrics'];
    const missingSections = requiredSections.filter(section => !template[section]);
    
    if (missingSections.length > 0) {
      logger.warn(`Missing required sections: ${missingSections.join(', ')}`);
      return false;
    }
    return true;
  },

  // Normalisation des chemins de destination
  buildDestinationPath: (config, fileName) => {
    const basePath = path.resolve(config.projectRoot);
    const plansPath = path.join(basePath, 'projet', 'roadmaps', 'plans');
    return path.join(plansPath, fileName);
  },

  // Helpers pour accéder aux ressources communes
  getCommonHelpers: () => ({
    path: require('./path-helper'),
    metrics: require('./metrics-helper'),
    tasks: require('./tasks-helper'),
    commands: require('./commands-helper')
  })
};
