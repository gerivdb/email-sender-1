// see types of prompts:
// https://github.com/enquirer/enquirer/tree/master/examples
//
module.exports = [
  {
    type: 'input',
    name: 'targetDir',
    message: "Répertoire à nettoyer (chemin relatif ou absolu) :"
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
