// index.js pour l'ajout d'une commande à un mode existant
const fs = require('fs');
const path = require('path');

module.exports = {
  prompt: ({ inquirer }) => {
    // Récupérer la liste des modes existants
    const modesDir = path.join(process.cwd(), 'development/scripts/modes');
    let modes = [];
    
    try {
      if (fs.existsSync(modesDir)) {
        modes = fs.readdirSync(modesDir)
          .filter(file => file.endsWith('-mode.ps1'))
          .map(file => file.replace('-mode.ps1', '').toUpperCase());
      }
    } catch (error) {
      console.error(`Erreur lors de la lecture du répertoire des modes: ${error.message}`);
    }

    const questions = [
      {
        type: 'list',
        name: 'mode',
        message: 'Mode auquel ajouter la commande:',
        choices: modes.length > 0 ? modes : ['DEBUG', 'GRAN', 'ARCHI', 'TEST'],
        validate: (input) => input.length > 0 ? true : 'Le mode est requis'
      },
      {
        type: 'input',
        name: 'name',
        message: 'Nom de la commande (en majuscules):',
        validate: (input) => {
          if (input.length === 0) return 'Le nom de la commande est requis';
          if (!/^[A-Z0-9-]+$/.test(input)) return 'Le nom doit être en majuscules et ne contenir que des lettres, chiffres et tirets';
          return true;
        }
      },
      {
        type: 'input',
        name: 'description',
        message: 'Description de la commande:',
        validate: (input) => input.length > 0 ? true : 'La description est requise'
      },
      {
        type: 'input',
        name: 'paramsRaw',
        message: 'Paramètres de la commande (format: nom:type, séparés par des virgules):',
        default: ''
      }
    ];

    return inquirer
      .prompt(questions)
      .then(answers => {
        // Traitement des paramètres
        const params = answers.paramsRaw
          ? answers.paramsRaw.split(',')
              .map(param => {
                const [name, type] = param.trim().split(':');
                return { name, type: type || 'string' };
              })
          : [];

        return {
          ...answers,
          params,
          // Formatage des noms
          modeLower: answers.mode.toLowerCase(),
          modeProper: answers.mode.charAt(0).toUpperCase() + answers.mode.slice(1).toLowerCase(),
          function: `Invoke-${answers.mode}${answers.name}`,
          // Date de génération
          date: new Date().toISOString().split('T')[0]
        };
      });
  }
};
