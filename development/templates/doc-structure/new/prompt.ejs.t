---
to: _templates/doc-structure/new/prompt.js
---
// see types of prompts:
// https://github.com/enquirer/enquirer/tree/master/examples
//
module.exports = [
  {
    type: 'input',
    name: 'docType',
    message: "Type de documentation (projet/development)"
  },
  {
    type: 'input',
    name: 'category',
    message: "Catégorie de documentation"
  },
  {
    type: 'input',
    name: 'subcategory',
    message: "Sous-catégorie (optionnel, laisser vide si aucune)"
  }
]
