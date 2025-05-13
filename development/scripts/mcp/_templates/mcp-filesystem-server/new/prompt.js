// see types of prompts:
// https://github.com/enquirer/enquirer/tree/master/examples
//
module.exports = [
  {
    type: 'input',
    name: 'port',
    message: "Port du serveur",
    initial: "5001"
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
    name: 'root_dir',
    message: "Répertoire racine",
    initial: "D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1"
  }
]
