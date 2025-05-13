---
to: _templates/<%= name %>/<%= action || 'new' %>/prompt.js
---
// see types of prompts:
// https://github.com/enquirer/enquirer/tree/master/examples
//
module.exports = [
  {
    type: 'input',
    name: 'path',
    message: "Chemin du fichier (relatif à la racine du projet)"
  },
  {
    type: 'input',
    name: 'description',
    message: "Description"
  },
  {
    type: 'input',
    name: 'author',
    message: "Auteur",
    initial: "Système"
  }
]
