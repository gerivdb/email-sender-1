// prompt.js for PRD template
const { createLogger } = require('../../helpers/logger-helper.js');
const logger = createLogger({ 
  verbosity: 'info',
  useEmoji: true
});

module.exports = [
  {
    type: 'input',
    name: 'version',
    message: '📊 Version (ex: v1.0):',
    default: `v${new Date().getFullYear()}-${String(new Date().getMonth() + 1).padStart(2, '0')}`,
    validate: (input) => {
      if (!input.length) {
        logger.warn('Version is required');
        return 'Version is required';
      }
      logger.debug(`Version input validated: ${input}`);
      return true;
    }
  },
  {
    type: 'input',
    name: 'title',
    message: '📝 Title of PRD:',
    validate: (input) => {
      if (!input.length) {
        logger.warn('Title is required');
        return 'Title is required';
      }
      logger.debug(`Title input validated: ${input}`);
      return true;
    }
  },
  {
    type: 'input',
    name: 'description',
    message: '📋 Description:',
    validate: (input) => {
      if (!input.length) {
        logger.warn('Description is required');
        return 'Description is required';
      }
      logger.info(`PRD description set: ${input.substring(0,50)}...`);
      return true;
    }
  },
  {
    type: 'input',
    name: 'path',
    message: '📂 Output file path:',
    default: (answers) => {
      const path = `d:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/docs/prd-${answers.version}-${answers.title.toLowerCase().replace(/ /g, '-')}.md`;
      logger.debug(`Default path generated: ${path}`);
      return path;
    }
  },
  {
    type: 'confirm',
    name: 'has_introduction',
    message: '📄 Include introduction section?',
    default: true
  },
  {
    type: 'confirm', 
    name: 'has_user_stories',
    message: '👥 Include user stories section?',
    default: true
  },
  {
    type: 'confirm',
    name: 'has_dependencies',
    message: '🔗 Include dependencies section?',
    default: true
  },
  {
    type: 'confirm',
    name: 'has_timeline',
    message: '📅 Include timeline section?',
    default: true
  },
  {
    type: 'confirm',
    name: 'has_approval',
    message: '✍️ Include approval section?',
    default: true
  }
];
