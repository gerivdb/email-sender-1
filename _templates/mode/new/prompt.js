// prompt.js for mode template
const { createLogger } = require('../../helpers/logger-helper.js');

const logger = createLogger({ 
  verbosity: 'info',
  useEmoji: true
});

module.exports = [
  {
    type: 'input',
    name: 'name',
    message: "Nom du mode (en majuscules) :",
    validate: input => {
      if (!input.length) {
        logger.warn('Le nom du mode est requis');
        return 'Le nom du mode est requis';
      }
      if (!/^[A-Z][A-Z0-9_]*$/.test(input)) {
        logger.error('Format de nom de mode invalide');
        return 'Le nom doit être en majuscules et ne contenir que des lettres, chiffres et _';
      }
      logger.debug(`Nom de mode validé: ${input}`);
      return true;
    }
  }
]