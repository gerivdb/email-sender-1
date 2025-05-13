// development/templates/hygen/powershell-module/new/prompt.js
module.exports = [
  {
    type: 'input',
    name: 'name',
    message: "Nom du module PowerShell (sans extension):"
  },
  {
    type: 'input',
    name: 'description',
    message: "Description du module:"
  },
  {
    type: 'input',
    name: 'author',
    message: "Auteur du module (laisser vide pour 'Augment Agent'):"
  },
  {
    type: 'list',
    name: 'category',
    message: "Catégorie du module:",
    choices: [
      'core',
      'utils',
      'analysis',
      'reporting',
      'integration',
      'maintenance',
      'testing',
      'documentation',
      'optimization'
    ]
  },
  {
    type: 'list',
    name: 'type',
    message: "Type de module:",
    choices: [
      'standard',
      'advanced',
      'extension'
    ]
  }
]
