// prompt.js
module.exports = {
  prompt: ({ inquirer }) => {
    const questions = [
      {
        type: 'input',
        name: 'name',
        message: 'Nom du script (sans extension .ps1)'
      },
      {
        type: 'input',
        name: 'description',
        message: 'Description du script'
      },
      {
        type: 'list',
        name: 'category',
        message: 'Catégorie du script',
        choices: [
          'api',
          'augment',
          'backups',
          'cleanup',
          'docs',
          'duplication',
          'encoding',
          'error-handling',
          'git',
          'logs',
          'mcp',
          'modes',
          'monitoring',
          'organize',
          'paths',
          'performance',
          'roadmap',
          'services',
          'standards',
          'test',
          'utils',
          'vscode'
        ]
      }
    ]
    return inquirer
      .prompt(questions)
      .then(answers => {
        // Déterminer le chemin de destination en fonction de la catégorie
        const destPath = `development/scripts/maintenance/${answers.category}`
        return { ...answers, destPath }
      })
  }
}
