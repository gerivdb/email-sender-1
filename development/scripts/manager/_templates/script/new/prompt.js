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
          'analysis',
          'organization',
          'inventory',
          'documentation',
          'monitoring',
          'optimization',
          'testing',
          'configuration',
          'generation',
          'integration',
          'ui',
          'core'
        ]
      }
    ]
    return inquirer
      .prompt(questions)
      .then(answers => {
        // Déterminer le chemin de destination en fonction de la catégorie
        const destPath = `development/scripts/manager/${answers.category}`
        return { ...answers, destPath }
      })
  }
}
