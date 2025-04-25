// prompt.js
module.exports = {
  prompt: ({ inquirer }) => {
    const questions = [
      {
        type: 'input',
        name: 'name',
        message: "Quel est le nom du workflow?"
      },
      {
        type: 'list',
        name: 'environment',
        message: "Dans quel environnement ce workflow sera-t-il utilisé?",
        choices: ['local', 'ide', 'archive']
      },
      {
        type: 'checkbox',
        name: 'tags',
        message: "Sélectionnez les tags pour ce workflow:",
        choices: ['email', 'notification', 'automation', 'integration', 'api', 'data-processing', 'reporting']
      }
    ]
    return inquirer
      .prompt(questions)
      .then(answers => {
        return answers
      })
  }
}
