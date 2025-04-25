/**
 * Module de vérification de santé
 * Vérifie la santé des systèmes cibles
 */

const axios = require('axios');
const config = require('./config');
const logger = require('./logger');

// Cache pour les résultats de vérification de santé
const healthCache = {
  // Structure: { system: { isHealthy: boolean, lastCheck: Date, failCount: number } }
};

/**
 * Vérifie la santé d'un système
 * @param {string} system - Le nom du système à vérifier
 * @returns {Promise<boolean>} true si le système est en bonne santé, false sinon
 */
const checkSystemHealth = async (system) => {
  try {
    // Vérifier si le système est valide
    const systemConfig = config.proxy.targets[system];
    if (!systemConfig) {
      logger.error(`Système invalide pour la vérification de santé: ${system}`);
      return false;
    }
    
    // Vérifier si nous avons un résultat en cache récent
    const now = new Date();
    if (healthCache[system] && 
        (now - healthCache[system].lastCheck) < config.proxy.healthCheckInterval) {
      return healthCache[system].isHealthy;
    }
    
    // Construire l'URL de l'endpoint de santé
    const healthUrl = `${systemConfig.url}${systemConfig.healthEndpoint || config.proxy.standardEndpoints.health}`;
    
    // Effectuer la requête avec un timeout
    const response = await axios.get(healthUrl, { timeout: 5000 });
    
    // Vérifier la réponse
    const isHealthy = response.status === 200;
    
    // Mettre à jour le cache
    healthCache[system] = {
      isHealthy,
      lastCheck: now,
      failCount: isHealthy ? 0 : (healthCache[system]?.failCount || 0) + 1
    };
    
    if (!isHealthy) {
      logger.warn(`Le système ${system} n'est pas en bonne santé. Échec #${healthCache[system].failCount}`);
    }
    
    return isHealthy;
  } catch (error) {
    logger.error(`Erreur lors de la vérification de santé du système ${system}: ${error.message}`);
    
    // Mettre à jour le cache en cas d'erreur
    healthCache[system] = {
      isHealthy: false,
      lastCheck: new Date(),
      failCount: (healthCache[system]?.failCount || 0) + 1
    };
    
    logger.warn(`Le système ${system} n'est pas en bonne santé. Échec #${healthCache[system].failCount}`);
    
    return false;
  }
};

/**
 * Vérifie la santé de tous les systèmes configurés
 * @returns {Promise<Object>} Un objet avec les résultats de santé pour chaque système
 */
const checkAllSystemsHealth = async () => {
  const results = {};
  
  for (const system of Object.keys(config.proxy.targets)) {
    results[system] = await checkSystemHealth(system);
  }
  
  return results;
};

// Démarrer les vérifications périodiques de santé
setInterval(async () => {
  logger.debug('Exécution de la vérification périodique de santé');
  await checkAllSystemsHealth();
}, config.proxy.healthCheckInterval);

module.exports = {
  checkSystemHealth,
  checkAllSystemsHealth
};
