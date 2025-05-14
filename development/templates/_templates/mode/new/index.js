// index.js pour la génération d'un nouveau mode
module.exports = {
  prompt: ({ inquirer }) => {
    const questions = [
      {
        type: 'input',
        name: 'name',
        message: 'Nom du mode (en majuscules):',
        validate: (input) => {
          if (input.length === 0) return 'Le nom du mode est requis';
          if (!/^[A-Z0-9-]+$/.test(input)) return 'Le nom doit être en majuscules et ne contenir que des lettres, chiffres et tirets';
          return true;
        }
      },
      {
        type: 'input',
        name: 'description',
        message: 'Description du mode:',
        validate: (input) => input.length > 0 ? true : 'La description est requise'
      },
      {
        type: 'list',
        name: 'category',
        message: 'Catégorie du mode:',
        choices: ['analyse', 'développement', 'optimisation', 'spécialisé']
      },
      {
        type: 'input',
        name: 'commandsRaw',
        message: 'Commandes spécifiques (séparées par des virgules):',
        default: 'RUN,CHECK,DEBUG,TEST,HELP'
      }
    ];

    return inquirer
      .prompt(questions)
      .then(answers => {
        // Traitement des commandes
        const commands = answers.commandsRaw.split(',')
          .map(cmd => cmd.trim())
          .filter(cmd => cmd.length > 0)
          .map(cmd => ({
            name: cmd,
            function: `Invoke-${answers.name}${cmd}`,
            description: `Exécute la commande ${cmd} du mode ${answers.name}`
          }));

        return {
          ...answers,
          commands,
          // Formatage du nom pour les différents cas d'utilisation
          nameLower: answers.name.toLowerCase(),
          nameProper: answers.name.charAt(0).toUpperCase() + answers.name.slice(1).toLowerCase(),
          // Date de génération
          date: new Date().toISOString().split('T')[0]
        };
      });
  }
};
