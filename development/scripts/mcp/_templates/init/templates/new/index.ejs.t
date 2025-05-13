---
to: _templates/<%= name %>/index.js
---
// Helpers pour le générateur <%= name %>
module.exports = {
  params: ({ args }) => {
    return {
      // Ajouter des paramètres par défaut ici
    }
  },
  projectPath: () => {
    // Chemin racine du projet
    return 'D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1'
  },
  now: () => {
    // Date et heure actuelles au format ISO
    return new Date().toISOString()
  },
  changeCase: require('change-case')
}
