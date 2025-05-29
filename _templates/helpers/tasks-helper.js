/**
 * Helper pour la gestion des phases et tâches dans les templates de plans
 */
const config = {
  defaultTasks: {
    standard: [
      'Analyse des besoins',
      'Conception technique',
      'Implémentation',
      'Tests et validation',
      'Documentation'
    ]
  }
};

module.exports = {
  /**
   * Génère la structure des phases avec leurs tâches
   * @param {number} phaseCount - Nombre de phases
   * @param {Array<string>} customTasks - Tâches personnalisées (optionnel)
   * @returns {Array} Phases avec leurs tâches
   */
  generatePhases: (phaseCount, customTasks = null) => {
    const tasks = customTasks || config.defaultTasks.standard;
    const phases = [];

    for (let i = 1; i <= phaseCount; i++) {
      phases.push({
        number: i,
        title: `Phase ${i}`,
        tasks: tasks.map(task => ({
          title: task,
          completed: false
        }))
      });
    }

    return phases;
  },

  /**
   * Calcule la progression d'une phase
   * @param {Array} tasks - Liste des tâches de la phase
   * @returns {number} Pourcentage de progression
   */
  calculatePhaseProgress: (tasks) => {
    if (!tasks || tasks.length === 0) return 0;
    const completed = tasks.filter(t => t.completed).length;
    return Math.round((completed / tasks.length) * 100);
  },

  /**
   * Formate le rendu Markdown d'une phase
   * @param {Object} phase - Phase à formater
   * @returns {string} Rendu Markdown de la phase
   */
  formatPhaseMarkdown: (phase) => {
    const progress = module.exports.calculatePhaseProgress(phase.tasks);
    let markdown = `## 🎯 Phase ${phase.number}\n`;
    markdown += `*Progression: ${progress}%*\n\n`;
    markdown += '### 📦 Scripts et Tâches\n';
    phase.tasks.forEach(task => {
      markdown += `- [${task.completed ? 'x' : ' '}] ${task.title}\n`;
    });
    markdown += '\n';
    return markdown;
  }
};
