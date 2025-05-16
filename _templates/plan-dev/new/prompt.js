// prompt.js - Questions à poser lors de la génération d'un nouveau plan de développement
module.exports = [
  {
    type: 'input',
    name: 'version',
    message: "Numéro de version du plan (ex: v24):"
  },
  {
    type: 'input',
    name: 'title',
    message: "Titre du plan de développement:"
  },
  {
    type: 'input',
    name: 'description',
    message: "Description du plan (objectif principal):"
  },
  {
    type: 'input',
    name: 'phases',
    message: "Nombre de phases (1-6):",
    validate: (input) => {
      const num = parseInt(input);
      if (isNaN(num) || num < 1 || num > 6) {
        return 'Veuillez entrer un nombre entre 1 et 6';
      }
      return true;
    }
  }
]
