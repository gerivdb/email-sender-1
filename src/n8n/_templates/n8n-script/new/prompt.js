// prompt.js
module.exports = {
  prompt: ({ inquirer }) => {
    const questions = [
      {
        type: 'input',
        name: 'name',
        message: "Quel est le nom du script? (sans extension)"
      },
      {
        type: 'list',
        name: 'category',
        message: "Dans quelle catégorie se trouve ce script?",
        choices: ['deployment', 'monitoring', 'diagnostics', 'notification', 'maintenance', 'dashboard', 'tests']
      },
      {
        type: 'input',
        name: 'description',
        message: "Description du script:"
      },
      {
        type: 'input',
        name: 'author',
        message: "Auteur du script:",
        default: "Équipe n8n"
      }
    ]
    return inquirer
      .prompt(questions)
      .then(answers => {
        return answers
      })
  }
}
