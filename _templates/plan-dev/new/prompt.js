// filepath: d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\_templates\plan-dev\new\prompt.js
// prompt.js
const { createLogger } = require('../../helpers/logger-helper.js');
const logger = createLogger({ 
  verbosity: 'info',
  useEmoji: true
});

module.exports = [
  {
    type: 'input',
    name: 'version',
    message: '📊 Version (ex: v2024-12):',
    default: `v${new Date().getFullYear()}-${String(new Date().getMonth() + 1).padStart(2, '0')}`,
    when: function(answers) {
      logger.debug('Version prompt triggered');
      return true;
    }
  },
  {
    type: 'input',
    name: 'title',
    message: '📝 Titre du plan:',
    validate: (input) => {
      if (!input.length) {
        logger.warn('Titre manquant');
        return 'Le titre est requis';
      }
      return true;
    }
  },
  {
    type: 'input',
    name: 'description',
    message: '📋 Description:',
    default: 'Plan de développement avec tracking intégré',
    when: function(answers) {
      logger.debug('Description prompt triggered');
      return true;
    }
  },
  {
    type: 'list',
    name: 'phases',
    message: '🎯 Nombre de phases:',
    choices: [
      { name: '3 phases - Simple', value: 3 },
      { name: '4 phases - Standard', value: 4 },
      { name: '5 phases - Complet', value: 5 }
    ],
    default: 4,
    when: function(answers) {
      logger.debug('Phases prompt triggered');
      return true;
    }
  },
  {
    type: 'input',
    name: 'author',
    message: '👤 Auteur:',
    default: 'gerivdb',
    when: function(answers) {
      logger.debug('Author prompt triggered');
      return true;
    }
  }
];