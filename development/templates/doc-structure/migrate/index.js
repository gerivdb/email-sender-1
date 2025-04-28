module.exports = {
  prompt: ({ inquirer }) => {
    const questions = require('./prompt.js')
    return inquirer
      .prompt(questions)
      .then(answers => {
        return {
          ...answers
        }
      })
  }
}
