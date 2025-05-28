// see types of prompts:
// https://github.com/enquirer/enquirer/tree/master/examples
//
import chalk from 'chalk';

module.exports = [
  {
    type: 'input',
    name: 'name',
    message: chalk.blue("🗺️ Quel est le nom du script (sans l'extension .ps1) ?")
  },
  {
    type: 'input',
    name: 'description',
    message: chalk.blue("📝 Description courte du script :")
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
