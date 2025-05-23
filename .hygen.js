module.exports = {
  templates: 'D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/development/templates/hygen',
  helpers: {
    // Helpers personnalisés pour les templates
    now: () => new Date().toISOString().slice(0, 10),
    year: () => new Date().getFullYear(),

    // Fonction pour convertir un nom de fichier en nom de fonction
    toFunctionName: (name) => {
      // Supprimer les caractères non alphanumériques du début
      const cleanName = name.replace(/^[^a-zA-Z]+/, '');
      // Convertir en PascalCase
      return cleanName
        .split(/[-_]/)
        .map(part => part.charAt(0).toUpperCase() + part.slice(1))
        .join('');
    },

    // Fonction pour générer un identifiant unique
    uuid: () => {
      return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
        var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
        return v.toString(16);
      });
    },

    // Fonction pour dasherize un texte (convertir en minuscules avec tirets)
    dasherize: (text) => {
      return text.toLowerCase().replace(/\s+/g, '-');
    }
  },

  // Properly create a prompter with access to command-line arguments
  createPrompter: () => {
    const Enquirer = require('enquirer');
    const enquirer = new Enquirer();
    
    // Store all arguments as options on the enquirer instance
    const processArgs = process.argv.slice(2);
    enquirer.options = {};
    
    // Parse command-line arguments
    for (let i = 0; i < processArgs.length; i++) {
      const arg = processArgs[i];
      if (arg.startsWith('--')) {
        const key = arg.slice(2);
        const value = processArgs[i + 1];
        if (value && !value.startsWith('--')) {
          enquirer.options[key] = value;
          i++; // Skip the next arg as we've used it as a value
        } else {
          enquirer.options[key] = true;
        }
      }
    }
    
    console.log('Parsed CLI options:', enquirer.options);
    return enquirer;
  },
  
  logger: {
    ok: (msg) => console.log(msg),
    log: (msg) => console.log(msg),
    error: (msg) => console.error(msg)
  },

  // Fichiers à ne jamais déplacer automatiquement (géré dans organize_repo.py)
  // Voir development/scripts/python/utils/organize_repo.py pour la logique d'exclusion (NEVER_MOVE_FILES)
  neverMove: [
    'AGENT.md', // Exception : ce fichier doit rester accessible à la racine
    // ...ajoutez d'autres exceptions ici si besoin...
  ],

  // Utiliser UTF-8 par défaut pour tous les fichiers générés
  exec: (action, body) => {
    const opts = body && body.length > 0 ? { encoding: 'utf8' } : {}
    return require('execa').shell(action, opts)
  },

  // Configurer l'encodage par défaut pour les fichiers générés
  logger: {
    ok: (msg) => console.log(msg),
    log: (msg) => console.log(msg), // Ajout pour compatibilité
    error: (msg) => console.error(msg) // Ajout pour une journalisation d'erreur plus complète
  }
}
