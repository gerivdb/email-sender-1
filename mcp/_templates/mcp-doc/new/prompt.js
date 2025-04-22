// prompt.js
module.exports = [
  {
    type: 'input',
    name: 'name',
    message: "Nom du document (sans extension):"
  },
  {
    type: 'input',
    name: 'description',
    message: "Description du document:"
  },
  {
    type: 'input',
    name: 'category',
    message: "Catégorie du document (architecture, api, guides, etc.):"
  },
  {
    type: 'input',
    name: 'author',
    message: "Auteur du document (laisser vide pour 'MCP Team'):"
  }
]
