// prompt.js
import chalk from 'chalk';

module.exports = [
  {
    type: 'input',
    name: 'name',
    message: chalk.blue("🧪 Nom du script de test (sans extension et sans .Tests):")
  },
  {
    type: 'input',
    name: 'description',
    message: chalk.blue("📝 Description courte du script de test:")
  },
  {
    type: 'input',
    name: 'additionalDescription',
    message: chalk.blue("📋 Description additionnelle (optionnel):")
  },
  {
    type: 'input',
    name: 'scriptToTest',
    message: chalk.blue("🔍 Chemin relatif du script à tester (ex: automation/Example-Script.ps1):")
  },
  {
    type: 'input',
    name: 'functionName',
    message: "Nom de la fonction principale à tester (sans le préfixe 'Start-'):"
  },
  {
    type: 'input',
    name: 'author',
    message: "Auteur du script (laisser vide pour 'EMAIL_SENDER_1'):"
  },
  {
    type: 'input',
    name: 'tags',
    message: "Tags (séparés par des virgules, laisser vide pour 'tests, pester, scripts'):"
  }
]
