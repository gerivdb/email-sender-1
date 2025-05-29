// prompt.js for mode command template
const { createLogger } = require('../../helpers/logger-helper.js');

const logger = createLogger({ 
  verbosity: 'info',
  useEmoji: true
});

module.exports = [
  {
    type: 'input',
    name: 'mode',
    message: "Nom du mode existant (en majuscules) :",
    validate: input => {
      if (!input.length) {
        logger.warn('Le mode est requis');
        return 'Le mode est requis';
      }
      if (!/^[A-Z][A-Z0-9_]*$/.test(input)) {
        logger.error('Format de nom de mode invalide');
        return 'Le mode doit être en majuscules';
      }
      logger.debug(`Mode validé: ${input}`);
      return true;
    }
  },
  {
    type: 'input',
    name: 'name', 
    message: "Nom de la commande (en majuscules) :",
    validate: input => {
      if (!input.length) {
        logger.warn('Le nom de la commande est requis');
        return 'Le nom de la commande est requis';
      }
      if (!/^[A-Z][A-Z0-9_]*$/.test(input)) {
        logger.error('Format de nom de commande invalide');
        return 'La commande doit être en majuscules';
      }
      logger.debug(`Commande validée: ${input}`);
      return true;
    }
  }
]