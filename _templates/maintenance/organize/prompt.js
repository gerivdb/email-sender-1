// see types of prompts:
// https://github.com/enquirer/enquirer/tree/master/examples
//
const { createLogger } = require('../../helpers/logger-helper.js');
const logger = createLogger({ 
  verbosity: 'info',
  useEmoji: true
});

// prompt.js for organize template
const basePrompts = [
  {
    type: 'input',
    name: 'name',
    message: "Nom du script d'organisation (sans l'extension) :",
    validate: input => {
      if (!input.length) {
        logger.warn('Le nom du script est requis');
        return 'Le nom du script est requis';
      }
      if (!/^[a-zA-Z][a-zA-Z0-9-_]*$/.test(input)) {
        logger.error('Format de nom invalide');
        return 'Le nom doit commencer par une lettre et ne contenir que des lettres, chiffres, - et _';
      }
      logger.debug(`Nom validé: ${input}`);
      return true;
    }
  },
  {
    type: 'select',
    name: 'type',
    message: 'Type de contenu à organiser :',
    choices: ['files', 'modules', 'scripts', 'docs'],
    validate: input => {
      if (!input) {
        logger.warn('Le type est requis');
        return 'Le type est requis';
      }
      logger.debug(`Type validé: ${input}`);
      return true;
    }
  },
  {
    type: 'input',
    name: 'targetDir',
    message: 'Répertoire cible (chemin relatif ou absolu) :',
    validate: input => {
      if (!input.length) {
        logger.warn('Le répertoire cible est requis');
        return 'Le répertoire cible est requis'; 
      }
      logger.debug(`Répertoire validé: ${input}`);
      return true;
    }
  }
];

module.exports = {
  prompt: ({ inquirer }) => {
    return inquirer.prompt(basePrompts).then(answers => {
      return { ...answers, template: 'organize' };
    });
  }
}
