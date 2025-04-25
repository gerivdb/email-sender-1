/**
 * Module de journalisation
 * Configure et expose un logger Winston pour l'application
 */

const winston = require('winston');
const fs = require('fs-extra');
const path = require('path');
const config = require('./config');

// S'assurer que le répertoire de logs existe
fs.ensureDirSync(config.logging.directory);

// Configurer le format de journalisation
const logFormat = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
  winston.format.errors({ stack: true }),
  winston.format.splat(),
  winston.format.json()
);

// Créer le logger
const logger = winston.createLogger({
  level: config.logging.level,
  format: logFormat,
  defaultMeta: { service: 'mcp-proxy' },
  transports: [
    // Journalisation dans un fichier pour tous les niveaux
    new winston.transports.File({
      filename: path.join(config.logging.directory, 'error.log'),
      level: 'error'
    }),
    new winston.transports.File({
      filename: path.join(config.logging.directory, 'combined.log')
    })
  ]
});

// Ajouter la journalisation dans la console en développement
if (process.env.NODE_ENV !== 'production') {
  logger.add(new winston.transports.Console({
    format: winston.format.combine(
      winston.format.colorize(),
      winston.format.simple()
    )
  }));
}

// Journaliser le démarrage
logger.info('Logger initialisé');

module.exports = logger;
