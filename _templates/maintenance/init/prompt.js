// see types of prompts:
// https://github.com/enquirer/enquirer/tree/master/examples
//
module.exports = [
  {
    type: 'input',
    name: 'projectName',
    message: "Nom du projet :",
    default: "EMAIL_SENDER_1"
  },
  {
    type: 'input',
    name: 'author',
    message: "Auteur :",
    default: "Maintenance Team"
  },
  {
    type: 'confirm',
    name: 'createAllFolders',
    message: "Créer tous les dossiers de maintenance ?",
    default: true
  }
]
