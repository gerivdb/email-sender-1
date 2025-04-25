/**
 * Module de configuration
 * Charge et expose la configuration du proxy MCP unifié
 */

const fs = require('fs-extra');
const path = require('path');

// Chemin vers le fichier de configuration
const configPath = path.resolve(__dirname, '../../config/default.json');

// Vérifier si le fichier de configuration existe
if (!fs.existsSync(configPath)) {
  console.error(`Fichier de configuration introuvable: ${configPath}`);
  process.exit(1);
}

// Charger la configuration
let config;
try {
  config = require(configPath);
} catch (error) {
  console.error(`Erreur lors du chargement de la configuration: ${error.message}`);
  process.exit(1);
}

// Valider la configuration minimale requise
const validateConfig = (config) => {
  const requiredFields = [
    'server.port',
    'server.host',
    'proxy.defaultTarget',
    'proxy.targets',
    'proxy.standardEndpoints',
    'logging.level',
    'logging.directory',
    'lockFile'
  ];
  
  for (const field of requiredFields) {
    const parts = field.split('.');
    let current = config;
    
    for (const part of parts) {
      if (current === undefined || current[part] === undefined) {
        throw new Error(`Champ de configuration manquant: ${field}`);
      }
      current = current[part];
    }
  }
  
  // Vérifier qu'il y a au moins un système cible configuré
  if (Object.keys(config.proxy.targets).length === 0) {
    throw new Error('Aucun système cible configuré');
  }
  
  // Vérifier que le système par défaut est configuré
  if (!config.proxy.targets[config.proxy.defaultTarget]) {
    throw new Error(`Le système par défaut '${config.proxy.defaultTarget}' n'est pas configuré`);
  }
};

try {
  validateConfig(config);
} catch (error) {
  console.error(`Configuration invalide: ${error.message}`);
  process.exit(1);
}

// Résoudre les chemins relatifs
if (config.logging.directory.startsWith('../') || config.logging.directory.startsWith('./')) {
  config.logging.directory = path.resolve(__dirname, config.logging.directory);
}

if (config.lockFile.startsWith('../') || config.lockFile.startsWith('./')) {
  config.lockFile = path.resolve(__dirname, config.lockFile);
}

// Exporter la configuration
module.exports = config;
