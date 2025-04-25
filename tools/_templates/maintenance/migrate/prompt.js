// see types of prompts:
// https://github.com/enquirer/enquirer/tree/master/examples
//
module.exports = [
  {
    type: 'input',
    name: 'sourceDir',
    message: "Répertoire source (chemin relatif ou absolu) :"
  },
  {
    type: 'input',
    name: 'targetDir',
    message: "Répertoire cible (chemin relatif ou absolu) :"
  },
  {
    type: 'input',
    name: 'name',
    message: "Nom du script de migration (sans l'extension .ps1) :"
  },
  {
    type: 'input',
    name: 'description',
    message: "Description du script de migration :"
  },
  {
    type: 'select',
    name: 'fileType',
    message: 'Type de fichiers à migrer :',
    choices: ['ps1', 'md', 'json', 'yaml', 'all', 'custom']
  },
  {
    type: 'input',
    name: 'customPattern',
    message: "Motif personnalisé (ex: *.txt) :",
    when: answers => answers.fileType === 'custom'
  },
  {
    type: 'confirm',
    name: 'createRollback',
    message: "Créer également un script de rollback ?"
  }
]
