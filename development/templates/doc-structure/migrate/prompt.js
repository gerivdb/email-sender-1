// see types of prompts:
// https://github.com/enquirer/enquirer/tree/master/examples
//
module.exports = [
  {
    type: 'input',
    name: 'sourcePath',
    message: "Chemin source (relatif à la racine du projet)"
  },
  {
    type: 'input',
    name: 'targetPath',
    message: "Chemin cible (relatif à la racine du projet)"
  },
  {
    type: 'confirm',
    name: 'recursive',
    message: "Migration récursive des sous-dossiers?",
    initial: true
  }
]
