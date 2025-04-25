// see types of prompts:
// https://github.com/enquirer/enquirer/tree/master/examples
//
module.exports = [
  {
    type: 'input',
    name: 'name',
    message: "Quel est le nom du script (sans l'extension .ps1) ?"
  },
  {
    type: 'input',
    name: 'description',
    message: "Description courte du script :"
  },
  {
    type: 'input',
    name: 'longDescription',
    message: "Description détaillée du script (optionnel) :"
  },
  {
    type: 'select',
    name: 'category',
    message: 'Catégorie du script :',
    choices: ['core', 'journal', 'management', 'utils', 'tests', 'docs']
  },
  {
    type: 'input',
    name: 'subcategory',
    message: "Sous-catégorie du script (dossier dans la catégorie) :"
  },
  {
    type: 'input',
    name: 'author',
    message: "Auteur du script (optionnel) :"
  }
]
