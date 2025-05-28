// filepath: d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\.hygen.js
module.exports = {
  templates: 'D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/_templates',
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
        const r = (Math.random() * 16) | 0;
        const v = c === 'x' ? r : (r & 0x3) | 0x8;
        return v.toString(16);
      });
    },

    // Fonction pour formater la date en français
    formatDate: (date) => {
      return new Date(date).toLocaleDateString('fr-FR', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit'
      });
    }
  }
};