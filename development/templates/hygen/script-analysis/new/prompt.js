// prompt.js
module.exports = [
  {
    type: 'input',
    name: 'name',
    message: "Nom du script d'analyse (sans extension):"
  },
  {
    type: 'input',
    name: 'description',
    message: "Description courte du script:"
  },
  {
    type: 'input',
    name: 'additionalDescription',
    message: "Description additionnelle (optionnel):"
  },
  {
    type: 'input',
    name: 'subFolder',
    message: "Sous-dossier (optionnel, ex: plugins, tests):"
  },
  {
    type: 'input',
    name: 'author',
    message: "Auteur du script (laisser vide pour 'EMAIL_SENDER_1'):"
  },
  {
    type: 'input',
    name: 'tags',
    message: "Tags (séparés par des virgules, laisser vide pour 'analysis, scripts'):"
  }
]
