// prompt.js
import chalk from 'chalk';

module.exports = [
  {
    type: 'input',
    name: 'name',
    message: chalk.blue("🔄 Nom du script d'intégration (sans extension):")
  },
  {
    type: 'input',
    name: 'description',
    message: chalk.blue("📝 Description courte du script:")
  },
  {
    type: 'input',
    name: 'additionalDescription',
    message: chalk.blue("📋 Description additionnelle (optionnel):")
  },
  {
    type: 'input',
    name: 'author',
    message: chalk.blue("👤 Auteur du script (laisser vide pour 'EMAIL_SENDER_1'):")
  },
  {
    type: 'input',
    name: 'tags',
    message: "Tags (séparés par des virgules, laisser vide pour 'integration, scripts'):"
  }
]
