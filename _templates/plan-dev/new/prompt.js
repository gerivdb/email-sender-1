// filepath: d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\_templates\plan-dev\new\prompt.js
// prompt.js
import chalk from 'chalk';

module.exports = [
  {
    type: 'input',
    name: 'version',
    message: chalk.blue('📊 Version (ex: v2024-12):'),
    default: `v${new Date().getFullYear()}-${String(new Date().getMonth() + 1).padStart(2, '0')}`
  },
  {
    type: 'input',
    name: 'title',
    message: chalk.blue('📝 Titre du plan:'),
    validate: (input) => input.length > 0 || 'Le titre est requis'
  },
  {
    type: 'input',
    name: 'description',
    message: chalk.blue('📋 Description:'),
    default: 'Plan de développement avec tracking intégré'
  },
  {
    type: 'list',
    name: 'phases',
    message: chalk.blue('🎯 Nombre de phases:'),
    choices: [
      { name: '3 phases - Simple', value: 3 },
      { name: '4 phases - Standard', value: 4 },
      { name: '5 phases - Complet', value: 5 }
    ],
    default: 4
  },
  {
    type: 'input',
    name: 'author',
    message: chalk.blue('👤 Auteur:'),
    default: 'gerivdb'
  }
];