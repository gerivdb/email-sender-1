// prompt.js - Questions à poser lors de la génération d'un nouveau plan de développement
module.exports = [
  {
    type: 'input',
    name: 'version',
    message: "Numéro de version du plan (ex: v24):"
  },
  {
    type: 'input',
    name: 'title',
    message: "Titre du plan de développement:"
  },
  {
    type: 'input',
    name: 'description',
    message: "Description du plan (objectif principal):"
  },
  {
    type: 'input',
    name: 'phases',
    message: "Nombre de phases (1-6):",
    validate: function (value) {
      const num = parseInt(value);
      if (Number.isInteger(num) && num >= 1 && num <= 6) {
        return true;
      }
      return 'Veuillez entrer un nombre entre 1 et 6';
    },
    when: function (answers) {
      console.log('Phases prompt THIS:', this);
      console.log('Phases prompt ANSWERS:', answers);
      console.log('Phases prompt THIS.STATE.ANSWERS:', this.state.answers);
      console.log('Phases prompt THIS.OPTIONS:', this.options);
      // Try accessing phases from different potential locations
      const phasesArg = this.options?.phases || this.phases || this.state.answers?.phases;
      console.log('Phases arg found:', phasesArg);
      return !phasesArg; // Prompt if phasesArg is not found or is falsy
    },
    default: function (answers) {
      console.log('Phases default THIS:', this);
      console.log('Phases default ANSWERS:', answers);
      console.log('Phases default THIS.STATE.ANSWERS:', this.state.answers);
      console.log('Phases default THIS.OPTIONS:', this.options);
      // Try accessing phases from different potential locations
      const phasesArg = this.options?.phases || this.phases || this.state.answers?.phases;
      console.log('Phases default arg found:', phasesArg);
      return phasesArg || 5; // Use provided value or default to 5
    },
    validate: (input) => {
      const num = parseInt(input);
      if (isNaN(num) || num < 1 || num > 6) {
        return 'Veuillez entrer un nombre entre 1 et 6';
      }
      return true;
    }
  },
  {
    type: 'input',
    name: 'phaseDetails',
    message: "Détails des phases (JSON, ex: {\"1\":{\"inputs\":\"...\",\"outputs\":\"...\"}}):",
    when: function (answers) {
      console.log('PhaseDetails prompt THIS:', this);
      console.log('PhaseDetails prompt ANSWERS:', answers);
      console.log('PhaseDetails prompt THIS.STATE.ANSWERS:', this.state.answers);
      console.log('PhaseDetails prompt THIS.OPTIONS:', this.options);
      // Try accessing phaseDetails from different potential locations
      const phaseDetailsArg = this.options?.phaseDetails || this.phaseDetails || this.state.answers?.phaseDetails;
      console.log('PhaseDetails arg found:', phaseDetailsArg);
      return !phaseDetailsArg; // Prompt if phaseDetailsArg is not found or is falsy
    },
    default: function (answers) {
      console.log('PhaseDetails default THIS:', this);
      console.log('PhaseDetails default ANSWERS:', answers);
      console.log('PhaseDetails default THIS.STATE.ANSWERS:', this.state.answers);
      console.log('PhaseDetails default THIS.OPTIONS:', this.options);
      // Try accessing phaseDetails from different potential locations
      const phaseDetailsArg = this.options?.phaseDetails || this.phaseDetails || this.state.answers?.phaseDetails;
      console.log('PhaseDetails default arg found:', phaseDetailsArg);
      return phaseDetailsArg || '{}'; // Use provided value or default to "{}"
    },
    validate: (input) => {
      try {
        JSON.parse(input);
        return true;
      } catch (e) {
        return 'Veuillez entrer un JSON valide';
      }
    }
  }
];
