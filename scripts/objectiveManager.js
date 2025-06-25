// scripts/objectiveManager.js
// Gestionnaire d’objectifs pour l’intégration Code-Graph RAG & DocManager

class ObjectiveManager {
  constructor() {
    this.objectives = [];
  }
  defineObjectives(objs) {
    this.objectives = objs;
    // TODO: gestion erreurs, validation, log
  }
  validateObjectives() {
    return this.objectives.length > 0;
  }
}

module.exports = ObjectiveManager;
