// prompt.js
module.exports = {
  prompt: ({ inquirer }) => {
    const questions = [
      {
        type: 'input',
        name: 'name',
        message: "Quel est le nom du document? (sans extension)"
      },
      {
        type: 'list',
        name: 'category',
        message: "Dans quelle catégorie se trouve ce document?",
        choices: ['architecture', 'workflows', 'api', 'guides', 'installation']
      },
      {
        type: 'input',
        name: 'description',
        message: "Description du document:"
      },
      {
        type: 'input',
        name: 'author',
        message: "Auteur du document:",
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
