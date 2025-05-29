// prompt.js
const { createLogger } = require('../../helpers/logger-helper.js');
const logger = createLogger({ 
  verbosity: 'info',
  useEmoji: true
});
const chalk = require('chalk');

module.exports = [
  {
    type: 'input',
    name: 'name',
    message: chalk.blue("🔄 Nom du script d'intégration (sans extension):"),
    validate: input => {
      if (!input.length) {
        logger.warn('Le nom du script est requis');
        return 'Le nom du script est requis';
      }
      logger.debug(`Nom de script validé: ${input}`);
      return true;
    }
  },
  {
    type: 'input',
    name: 'description',
    message: chalk.blue("📝 Description courte du script:")
  },
  {
    type: 'input',
    name: 'additionalDescription',
    message: chalk.blue("📋 Description additionnelle (optionnel):")
  },
  {
    type: 'input',
    name: 'author',
    message: chalk.blue("👤 Auteur du script (laisser vide pour 'EMAIL_SENDER_1'):")
  },
  {
    type: 'input',
    name: 'tags',
    message: "Tags (séparés par des virgules, laisser vide pour 'integration, scripts'):"
  }
]
