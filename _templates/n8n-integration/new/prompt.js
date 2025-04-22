// prompt.js
module.exports = {
  prompt: ({ inquirer }) => {
    const questions = [
      {
        type: 'input',
        name: 'name',
        message: "Quel est le nom du script d'intégration? (sans extension)"
      },
      {
        type: 'list',
        name: 'system',
        message: "Avec quel système s'intègre ce script?",
        choices: ['mcp', 'ide', 'api', 'augment']
      },
      {
        type: 'input',
        name: 'description',
        message: "Description de l'intégration:"
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
