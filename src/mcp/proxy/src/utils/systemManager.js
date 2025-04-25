/**
 * Module de gestion du système actif
 * Gère la lecture et l'écriture du fichier de lock pour déterminer le système actif
 */

const fs = require('fs-extra');
const path = require('path');
const config = require('./config');
const logger = require('./logger');

/**
 * Récupère le système actuellement actif
 * @returns {Promise<string>} Le nom du système actif
 */
const getActiveSystem = async () => {
  try {
    // Vérifier si le fichier de lock existe
    if (!await fs.pathExists(config.lockFile)) {
      // Si le fichier n'existe pas, utiliser le système par défaut
      const defaultSystem = config.proxy.defaultTarget;
      logger.info(`Fichier de lock non trouvé, utilisation du système par défaut: ${defaultSystem}`);
      
      // Créer le fichier de lock avec le système par défaut
      await fs.writeFile(config.lockFile, defaultSystem, 'utf8');
      return defaultSystem;
    }
    
    // Lire le fichier de lock
    const activeSystem = await fs.readFile(config.lockFile, 'utf8');
    
    // Vérifier si le système lu est valide
    if (!config.proxy.targets[activeSystem.trim()]) {
      logger.warn(`Système actif invalide dans le fichier de lock: ${activeSystem}, utilisation du système par défaut`);
      const defaultSystem = config.proxy.defaultTarget;
      await fs.writeFile(config.lockFile, defaultSystem, 'utf8');
      return defaultSystem;
    }
    
    return activeSystem.trim();
  } catch (error) {
    logger.error(`Erreur lors de la lecture du système actif: ${error.message}`);
    // En cas d'erreur, utiliser le système par défaut
    return config.proxy.defaultTarget;
  }
};

/**
 * Définit le système actif
 * @param {string} system - Le nom du système à activer
 * @returns {Promise<void>}
 */
const setActiveSystem = async (system) => {
  try {
    // Vérifier si le système est valide
    if (!config.proxy.targets[system]) {
      throw new Error(`Système invalide: ${system}`);
    }
    
    // Écrire le nouveau système dans le fichier de lock
    await fs.writeFile(config.lockFile, system, 'utf8');
    logger.info(`Système actif changé pour: ${system}`);
  } catch (error) {
    logger.error(`Erreur lors de la définition du système actif: ${error.message}`);
    throw error;
  }
};

module.exports = {
  getActiveSystem,
  setActiveSystem
};
