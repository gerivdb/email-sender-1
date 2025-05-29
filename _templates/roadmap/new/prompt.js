// prompt.js for roadmap template
const { createLogger } = require('../../helpers/logger-helper.js');
const chalk = require('chalk');

const logger = createLogger({ 
  verbosity: 'info',
  useEmoji: true
});

module.exports = [
  {
    type: 'input',
    name: 'name',
    message: chalk.blue("🗺️ Quel est le nom du script (sans l'extension .ps1) ?"),
    validate: input => {
      if (!input.length) {
        logger.warn('Le nom du script est requis');
        return 'Le nom du script est requis';
      }
      if (!/^[a-zA-Z][a-zA-Z0-9-_]*$/.test(input)) {
        logger.error('Format de nom de script invalide');
        return 'Le nom doit commencer par une lettre et ne contenir que des lettres, chiffres, - et _';
      }
      logger.debug(`Nom de script validé: ${input}`);
      return true;
    }
  },
  {
    type: 'input',
    name: 'description',
    message: chalk.blue("📝 Description courte du script :"),
    validate: input => {
      if (!input.length) {
        logger.warn('La description est requise');
        return 'La description est requise';
      }
      logger.info(`Description du script définie: ${input.substring(0,50)}...`);
      return true;
    }
  },
  {
    type: 'input',
    name: 'longDescription',
    message: chalk.blue("📋 Description détaillée du script (optionnel) :")
  },
  {
    type: 'select',
    name: 'category',
    message: 'Catégorie du script :',
    choices: ['core', 'journal', 'management', 'utils', 'tests', 'docs'],
    validate: input => {
      logger.debug(`Catégorie sélectionnée: ${input}`);
      return true;
    }
  },
  {
    type: 'input',
    name: 'subcategory',
    message: "Sous-catégorie du script (dossier dans la catégorie) :",
    validate: input => {
      if (!input.length) {
        logger.warn('La sous-catégorie est requise');
        return 'La sous-catégorie est requise';
      }
      logger.debug(`Sous-catégorie validée: ${input}`);
      return true;
    }
  },
  {
    type: 'input',
    name: 'author',
    message: "Auteur du script (optionnel) :",
    default: 'Roadmap Team',
    validate: input => {
      if (input.length > 0) {
        logger.debug(`Auteur défini: ${input}`);
      }
      return true;
    }
  }
]
