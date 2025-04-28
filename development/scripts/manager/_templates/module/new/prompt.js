// prompt.js
module.exports = {
  prompt: ({ inquirer }) => {
    const questions = [
      {
        type: 'input',
        name: 'name',
        message: 'Nom du module (sans extension .psm1)'
      },
      {
        type: 'input',
        name: 'description',
        message: 'Description du module'
      },
      {
        type: 'list',
        name: 'category',
        message: 'Catégorie du module',
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
        const destPath = `development/scripts/manager/${answers.category}/modules`
        return { ...answers, destPath }
      })
  }
}
