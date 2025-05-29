// Logger helper for cross-platform compatibility
const chalk = require('chalk');
const os = require('os');

class Logger {
  constructor(options = {}) {
    this.verbosity = options.verbosity || 'info';
    this.useEmoji = options.useEmoji !== false;    this.platform = os.platform();
    this.levels = {
      error: 0,
      warn: 1,
      info: 2,
      debug: 3,
      success: 2 // Same level as info
    };
    this.emoji = {
      error: this.getFallbackEmoji('❌', 'x'),
      warn: this.getFallbackEmoji('⚠️', '!'),
      info: this.getFallbackEmoji('ℹ️', 'i'),
      debug: this.getFallbackEmoji('🔍', '?'),
      success: this.getFallbackEmoji('✅', '√')
    };
  }
  getFallbackEmoji(emoji, fallback) {
    if (!this.useEmoji) {
      return `[${fallback}]`;
    }
    return this.platform === 'win32' ? `${fallback} ` : `${emoji} `;
  }

  shouldLog(level) {
    return this.levels[level] <= this.levels[this.verbosity];
  }

  formatMessage(level, message) {
    const timestamp = new Date().toISOString();
    return `${this.emoji[level]} ${timestamp} ${message}`;
  }

  error(message) {
    if (this.shouldLog('error')) {
      console.error(chalk.red(this.formatMessage('error', message)));
    }
  }

  warn(message) {
    if (this.shouldLog('warn')) {
      console.warn(chalk.yellow(this.formatMessage('warn', message)));
    }
  }

  info(message) {
    if (this.shouldLog('info')) {
      console.info(chalk.blue(this.formatMessage('info', message)));
    }
  }
  debug(message) {
    if (this.shouldLog('debug')) {
      console.debug(chalk.gray(this.formatMessage('debug', message)));
    }
  }

  success(message) {
    if (this.shouldLog('success')) {
      console.log(chalk.green(this.formatMessage('success', message)));
    }
  }

  setVerbosity(level) {
    if (this.levels[level] !== undefined) {
      this.verbosity = level;
    }
  }

  setEmoji(enabled) {
    this.useEmoji = enabled;
  }
}

module.exports = {
  createLogger: (options) => new Logger(options)
};
