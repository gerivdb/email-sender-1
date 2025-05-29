const { createLogger } = require('../logger-helper.js');
const os = require('os');

function testLoggerConfiguration() {
  console.log('Testing logger configuration on platform:', os.platform());
  
  // Test different verbosity levels
  const loggers = {
    debug: createLogger({ verbosity: 'debug', useEmoji: true }),
    info: createLogger({ verbosity: 'info', useEmoji: true }),
    warn: createLogger({ verbosity: 'warn', useEmoji: true }),
    error: createLogger({ verbosity: 'error', useEmoji: true })
  };

  // Test messages with emojis
  Object.entries(loggers).forEach(([level, logger]) => {
    console.log(`\nTesting ${level} level:`);
    logger.debug('Debug message with 🐛');
    logger.info('Info message with ℹ️');
    logger.warn('Warning message with ⚠️');
    logger.error('Error message with ❌');
  });

  // Test without emojis
  console.log('\nTesting without emojis:');
  const noEmojiLogger = createLogger({ verbosity: 'debug', useEmoji: false });
  noEmojiLogger.debug('Debug message without emoji');
  noEmojiLogger.info('Info message without emoji');
  noEmojiLogger.warn('Warning message without emoji');
  noEmojiLogger.error('Error message without emoji');
}

// Run tests
testLoggerConfiguration();
