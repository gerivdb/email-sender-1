// see types of prompts:
// https://github.com/enquirer/enquirer/tree/master/examples
//
module.exports = [
  {
    type: 'input',
    name: 'port',
    message: "Port du serveur",
    initial: "5002"
  },
  {
    type: 'input',
    name: 'host',
    message: "Hôte du serveur",
    initial: "0.0.0.0"
  },
  {
    type: 'confirm',
    name: 'debug',
    message: "Mode debug ?",
    initial: false
  },
  {
    type: 'input',
    name: 'github_token',
    message: "Token GitHub (laisser vide pour utiliser la variable d'environnement)",
    initial: ""
  }
]
