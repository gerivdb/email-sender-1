// prompt.js for commands
const { createLogger } = require('../../helpers/logger-helper.js');
const logger = createLogger({ 
  verbosity: 'info',
  useEmoji: true
});

module.exports = [
  {
    type: 'input',
    name: 'name',
    message: '⌨️ Command name:',
    validate: input => {
      if (!input.length) {
        logger.warn('Command name is required');
        return 'Command name is required';
      }
      if (!/^[a-zA-Z][a-zA-Z0-9-_]*$/.test(input)) {
        logger.error('Invalid command name format');
        return 'Command name must start with letter and contain only letters, numbers, - and _';
      }
      logger.debug(`Command name validated: ${input}`);
      return true;
    }
  },
  {
    type: 'input',
    name: 'description',
    message: '📋 Command description:',
    validate: input => {
      if (!input.length) {
        logger.warn('Description is required');
        return 'Description is required';
      }
      logger.info(`Command description set: ${input.substring(0,50)}...`);
      return true;
    }
  },
  {
    type: 'list',
    name: 'parameters',
    message: '🔧 Command parameters (one per line, empty line to finish):',
    validate: input => {
      if (input.length === 0) {
        logger.warn('At least one parameter is required');
        return 'At least one parameter is required';
      }
      logger.debug(`Parameters defined: ${input.length}`);
      return true;
    }
  },
  {
    type: 'confirm',
    name: 'addTests',
    message: '🧪 Generate test file?',
    default: true,
    validate: input => {
      logger.debug(`Test generation: ${input ? 'yes' : 'no'}`);
      return true;
    }
  },
  {
    type: 'confirm',
    name: 'addDocs',
    message: '📚 Generate documentation?',
    default: true,
    validate: input => {
      logger.debug(`Documentation generation: ${input ? 'yes' : 'no'}`);
      return true;
    }
  }
];
