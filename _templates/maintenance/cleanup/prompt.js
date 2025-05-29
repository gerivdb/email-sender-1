// prompt.js for cleanup template
const { createLogger } = require('../../helpers/logger-helper.js');
const logger = createLogger({ 
  verbosity: 'info',
  useEmoji: true
});

module.exports = [
  {
    type: 'input',
    name: 'targetDir',
    message: "Répertoire à nettoyer (chemin relatif ou absolu) :",
    validate: input => {
      if (!input.length) {
        logger.warn('Le répertoire cible est requis');
        return 'Le répertoire cible est requis';
      }
      logger.debug(`Répertoire cible validé: ${input}`);
      return true;
    }
  },
  {
    type: 'input',
    name: 'name',
    message: "Nom du script de nettoyage (sans l'extension .ps1) :"
  },
  {
    type: 'input',
    name: 'description',
    message: "Description du script de nettoyage :"
  },
  {
    type: 'select',
    name: 'cleanupType',
    message: 'Type de nettoyage :',
    choices: ['temp', 'logs', 'backups', 'duplicates', 'empty', 'custom']
  },
  {
    type: 'input',
    name: 'customPattern',
    message: "Motif personnalisé (ex: *.bak) :",
    when: answers => answers.cleanupType === 'custom'
  },
  {
    type: 'confirm',
    name: 'recursive',
    message: "Nettoyer récursivement les sous-répertoires ?"
  },
  {
    type: 'confirm',
    name: 'createBackup',
    message: "Créer une sauvegarde avant le nettoyage ?"
  }
]
