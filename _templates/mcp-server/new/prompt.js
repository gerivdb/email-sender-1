// prompt.js - Questions pour générer un nouveau serveur MCP
// Les réponses sont utilisées pour générer tous les fichiers dans projet/mcp/servers/<%= name %>
import chalk from 'chalk';

module.exports = [
  {
    type: 'input',
    name: 'name',
    message: chalk.blue("🖥️ Nom du serveur MCP (sans le préfixe 'mcp-'):")
  },
  {
    type: 'input',
    name: 'description',
    message: chalk.blue("📝 Description du serveur MCP:")
  },
  {
    type: 'input',
    name: 'command',
    message: chalk.blue("⚙️ Commande pour démarrer le serveur (ex: npx):")
  },
  {
    type: 'input',
    name: 'args',
    message: "Arguments de la commande (séparés par des virgules):"
  },
  {
    type: 'confirm',
    name: 'needsEnv',
    message: "Le serveur nécessite-t-il des variables d'environnement?",
    default: false
  },
  {
    type: 'input',
    name: 'envVars',
    message: "Variables d'environnement (format: NOM=VALEUR, séparées par des virgules):",
    when: answers => answers.needsEnv
  },
  {
    type: 'input',
    name: 'port',
    message: "Port par défaut pour le serveur (laissez vide si non applicable):",
    default: ""
  },
  {
    type: 'confirm',
    name: 'createConfig',
    message: "Créer un fichier de configuration pour ce serveur?",
    default: true
  },
  {
    type: 'confirm',
    name: 'createDocs',
    message: "Créer une documentation pour ce serveur?",
    default: true
  }
];
