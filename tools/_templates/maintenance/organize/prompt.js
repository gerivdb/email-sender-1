// see types of prompts:
// https://github.com/enquirer/enquirer/tree/master/examples
//
module.exports = [
  {
    type: 'input',
    name: 'targetDir',
    message: "Quel est le répertoire cible à organiser ? (chemin relatif ou absolu)"
  },
  {
    type: 'input',
    name: 'name',
    message: "Nom du script d'organisation (sans l'extension .ps1) :"
  },
  {
    type: 'input',
    name: 'description',
    message: "Description du script d'organisation :"
  },
  {
    type: 'select',
    name: 'type',
    message: 'Type d\'organisation :',
    choices: ['structure', 'files', 'modules', 'scripts', 'docs', 'custom']
  },
  {
    type: 'confirm',
    name: 'createCleanup',
    message: "Créer également un script de nettoyage ?"
  }
]
