// prompt.js for doc-structure template
const { createLogger } = require('../../helpers/logger-helper.js');

const logger = createLogger({ 
  verbosity: 'info',
  useEmoji: true
});

module.exports = [
  {
    type: 'input',
    name: 'name',
    message: "Nom de la structure de documentation :",
    validate: input => {
      if (!input.length) {
        logger.warn('Le nom de la structure est requis');
        return 'Le nom de la structure est requis';
      }
      logger.debug(`Structure validée: ${input}`);
      return true;
    }
  },
  {
    type: 'input',
    name: 'version',
    message: "Version de la structure :",
    validate: input => {
      if (!input.length) {
        logger.warn('La version est requise');
        return 'La version est requise';
      }
      if (!/^\d+\.\d+(\.\d+)?$/.test(input)) {
        logger.error('Format de version invalide');
        return 'La version doit être au format x.y.z ou x.y';
      }
      logger.debug(`Version validée: ${input}`);
      return true;
    }
  }
]