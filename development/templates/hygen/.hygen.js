module.exports = {
  templates: `${__dirname}`,
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

  // Fichiers à ne jamais déplacer automatiquement (géré dans organize_repo.py)
  // Voir development/scripts/python/utils/organize_repo.py pour la logique d'exclusion (NEVER_MOVE_FILES)
  neverMove: [
    'AGENT.md', // Exception : ce fichier doit rester accessible à la racine
    // ...ajoutez d'autres exceptions ici si besoin...
  ],

  // Configuration pour l'encodage des fichiers générés
  createPrompter: () => require('enquirer'),

  // Utiliser UTF-8 par défaut pour tous les fichiers générés
  exec: (action, body) => {
    const opts = body && body.length > 0 ? { encoding: 'utf8' } : {}
    return require('execa').shell(action, opts)
  },

  // Configurer l'encodage par défaut pour les fichiers générés
  logger: {
    ok: (msg) => console.log(msg)
  }
}
