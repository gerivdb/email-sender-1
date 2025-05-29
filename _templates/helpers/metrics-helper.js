/**
 * Helper pour la gestion des métriques et du formatage dans les templates de plans
 */
const config = {
  defaultMetrics: {
    totalTasks: 9,
    completedTasks: 0,
    efficiency: 0,
    testCoverage: 0
  },
  defaultWarnings: [
    { severity: 'HAUTE', message: 'Points critiques à surveiller' },
    { severity: 'MOYENNE', message: 'Points d\'attention régulière' },
    { severity: 'BASSE', message: 'Points à garder en mémoire' }
  ]
};

module.exports = {
  /**
   * Initialise les métriques par défaut du plan
   * @returns {Object} Métriques par défaut
   */
  getDefaultMetrics: () => {
    return { ...config.defaultMetrics };
  },

  /**
   * Obtient les warnings par défaut
   * @returns {Array} Liste des warnings
   */
  getDefaultWarnings: () => {
    return [...config.defaultWarnings];
  },

  /**
   * Calcule le pourcentage de progression
   * @param {number} completed - Nombre de tâches complétées
   * @param {number} total - Nombre total de tâches
   * @returns {number} Pourcentage de progression (0-100)
   */
  calculateProgress: (completed, total) => {
    if (total === 0) return 0;
    return Math.round((completed / total) * 100);
  },

  /**
   * Formate une date en français
   * @param {Date} date - Date à formater
   * @returns {string} Date formatée
   */
  formatDate: (date = new Date()) => {
    return date.toLocaleDateString('fr-FR', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit'
    });
  }
};
