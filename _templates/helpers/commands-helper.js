/**
 * Helper pour la gestion des commandes et de la configuration dans les templates
 */
const config = {
  commands: {
    update: 'hygen plan-dev update task-status --task "{taskId}" --status "{status}"',
    report: 'hygen plan-dev report progress --phase {phase}',
    metrics: 'hygen plan-dev report metrics',
    config: 'hygen plan-dev config set --key "{key}" --value "{value}"'
  },
  defaultConfig: {
    autoSave: true,
    backupEnabled: true,
    metricsCollection: true
  }
};

module.exports = {
  /**
   * Génère la section des commandes de suivi
   * @returns {string} Section de commandes formatée en Markdown
   */
  generateCommandsSection: () => {
    return `## 🚀 Commandes de Suivi

\`\`\`powershell
# Mettre à jour une tâche
${config.commands.update.replace('{taskId}', '1.1.1').replace('{status}', 'done')}

# Générer un rapport de progression
${config.commands.report.replace('{phase}', '1')}

# Visualiser les métriques de performance
${config.commands.metrics}

# Configurer les options
${config.commands.config.replace('{key}', 'autoSave').replace('{value}', 'true')}
\`\`\``;
  },

  /**
   * Obtient la configuration par défaut
   * @returns {Object} Configuration par défaut
   */
  getDefaultConfig: () => {
    return { ...config.defaultConfig };
  },

  /**
   * Formate une commande avec ses paramètres
   * @param {string} commandType - Type de commande (update|report|metrics|config)
   * @param {Object} params - Paramètres de la commande
   * @returns {string} Commande formatée
   */
  formatCommand: (commandType, params = {}) => {
    let command = config.commands[commandType];
    Object.entries(params).forEach(([key, value]) => {
      command = command.replace(`{${key}}`, value);
    });
    return command;
  }
};
