import chalk from 'chalk';
const { createLogger } = require('../../helpers/logger-helper.js');
const logger = createLogger({ verbosity: 'info' });

// prompt.js - Questions à poser lors de la génération d'un nouveau plan de développement
module.exports = [
  {
    type: 'input',
    name: 'version',
    message: chalk.blue("Numéro de version du plan (ex: v24):"),
    when: function (answers) {
      logger.debug('===== VERSION PROMPT =====');
      logger.debug('Context:', {
        instance: this,
        answers: answers,
        args: process.argv
      });
      
      // Try multiple sources for version
      const versionArg = process.env.npm_config_name || 
                        process.argv.find(arg => arg.startsWith('--name='))?.split('=')[1] ||
                        process.argv[process.argv.indexOf('--name') + 1] ||
                        this.options?.name || 
                        answers?.name;

      logger.debug('Version argument found:', versionArg);
      
      // If we have a version argument, don't show the prompt
      if (versionArg) {
        // Store it for the template to use
        this.version = versionArg.replace('plan-dev ', '');
        logger.info('Using version:', this.version);
        return false;
      }
      return true;
    },
    default: function (answers) {
      // If we already set the version in when(), use that
      if (this.version) {
        return this.version;
      }
      return 'v0';
    }
  },
  {
    type: 'input',
    name: 'title',
    message: chalk.blue("Titre du plan de développement:"),
    when: function (answers) {
      logger.debug('===== TITLE PROMPT =====');
      
      // Try multiple sources for title
      const titleArg = process.env.npm_config_title ||
                      process.argv.find(arg => arg.startsWith('--title='))?.split('=')[1] ||
                      process.argv[process.argv.indexOf('--title') + 1] ||
                      this.options?.title ||
                      answers?.title;

      logger.debug('Title argument found:', titleArg);
      
      // If we have a title argument, don't show the prompt
      if (titleArg) {
        // Store it for the template to use
        this.title = titleArg;
        logger.info('Using title:', this.title);
        return false;
      }
      return true;
    },
    default: function (answers) {
      // If we already set the title in when(), use that
      if (this.title) {
        return this.title;
      }
      return 'Default Title';
    }
  },
  {
    type: 'input',
    name: 'description',
    message: chalk.blue("Description du plan (objectif principal):"),
    when: function (answers) {
      logger.debug('===== DESCRIPTION PROMPT =====');
      
      // Try multiple sources for description
      const descriptionArg = process.env.npm_config_description ||
                            process.argv.find(arg => arg.startsWith('--description='))?.split('=')[1] ||
                            process.argv[process.argv.indexOf('--description') + 1] ||
                            this.options?.description ||
                            answers?.description;

      logger.debug('Description argument found:', descriptionArg);
      
      // If we have a description argument, don't show the prompt
      if (descriptionArg) {
        // Store it for the template to use
        this.description = descriptionArg;
        logger.info('Using description:', this.description);
        return false;
      }
      return true;
    },
    default: function (answers) {
      // If we already set the description in when(), use that
      if (this.description) {
        return this.description;
      }
      return 'Default description';
    }
  },
  {
    type: 'input',
    name: 'phases',
    message: chalk.blue("Nombre de phases (1-6):"),
    when: function (answers) {
      logger.debug('===== PHASES PROMPT =====');
      
      // Try multiple sources for phases
      const phasesArg = process.env.npm_config_phases ||
                        process.argv.find(arg => arg.startsWith('--phases='))?.split('=')[1] ||
                        process.argv[process.argv.indexOf('--phases') + 1] ||
                        this.options?.phases ||
                        answers?.phases;

      logger.debug('Phases argument found:', phasesArg);
      
      // If we have a phases argument, don't show the prompt
      if (phasesArg) {
        // Store it for the template to use
        this.phases = parseInt(phasesArg, 10);
        logger.info('Using phases:', this.phases);
        return false;
      }
      return true;
    },
    default: function (answers) {
      // If we already set the phases in when(), use that
      if (this.phases) {
        return this.phases;
      }
      return 5;
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
    message: chalk.blue("Détails des phases (JSON, ex: {\"1\":{\"inputs\":\"...\",\"outputs\":\"...\"}}):"),
    when: function (answers) {
      console.log('===== PHASE_DETAILS PROMPT =====');
      
      // Try multiple sources for phaseDetails
      const phaseDetailsArg = process.env.npm_config_phaseDetails ||
                              process.argv.find(arg => arg.startsWith('--phaseDetails='))?.split('=')[1] ||
                              process.argv[process.argv.indexOf('--phaseDetails') + 1] ||
                              this.options?.phaseDetails ||
                              answers?.phaseDetails;

      console.log('PHASE_DETAILS ARG FOUND:', phaseDetailsArg);
      
      // If we have a phaseDetails argument, don't show the prompt
      if (phaseDetailsArg) {
        // Store it for the template to use
        this.phaseDetails = phaseDetailsArg;
        console.log('USING PHASE_DETAILS:', this.phaseDetails);
        return false;
      }
      return true;
    },
    default: function (answers) {
      // If we already set the phaseDetails in when(), use that
      if (this.phaseDetails) {
        return this.phaseDetails;
      }
      return '{}';
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
