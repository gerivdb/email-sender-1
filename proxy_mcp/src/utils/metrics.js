/**
 * Module de métriques
 * Collecte et expose des métriques sur le fonctionnement du proxy
 */

const os = require('os');
const fs = require('fs-extra');
const path = require('path');
const config = require('./config');
const logger = require('./logger');

// Métriques collectées
const metrics = {
  // Métriques du serveur
  server: {
    startTime: Date.now(),
    requestsTotal: 0,
    requestsSuccess: 0,
    requestsError: 0,
    responseTimeTotal: 0,
    responseTimeAvg: 0,
    lastRequestTime: null
  },
  
  // Métriques par système
  systems: {},
  
  // Métriques de basculement
  failover: {
    total: 0,
    automatic: 0,
    manual: 0,
    lastFailoverTime: null,
    lastFailoverReason: null
  },
  
  // Métriques système
  system: {
    cpuUsage: 0,
    memoryUsage: 0,
    uptime: 0
  }
};

// Initialiser les métriques pour chaque système
for (const system of Object.keys(config.proxy.targets)) {
  metrics.systems[system] = {
    requestsTotal: 0,
    requestsSuccess: 0,
    requestsError: 0,
    responseTimeTotal: 0,
    responseTimeAvg: 0,
    healthChecks: 0,
    healthChecksFailed: 0,
    lastHealthCheckTime: null,
    lastHealthCheckStatus: null,
    activeTime: 0,
    lastActiveTime: null
  };
}

/**
 * Enregistre une requête
 * @param {string} system - Le système cible
 * @param {boolean} success - Si la requête a réussi
 * @param {number} responseTime - Le temps de réponse en ms
 */
const recordRequest = (system, success, responseTime) => {
  // Métriques globales
  metrics.server.requestsTotal++;
  if (success) {
    metrics.server.requestsSuccess++;
  } else {
    metrics.server.requestsError++;
  }
  metrics.server.responseTimeTotal += responseTime;
  metrics.server.responseTimeAvg = metrics.server.responseTimeTotal / metrics.server.requestsTotal;
  metrics.server.lastRequestTime = Date.now();
  
  // Métriques par système
  if (metrics.systems[system]) {
    metrics.systems[system].requestsTotal++;
    if (success) {
      metrics.systems[system].requestsSuccess++;
    } else {
      metrics.systems[system].requestsError++;
    }
    metrics.systems[system].responseTimeTotal += responseTime;
    metrics.systems[system].responseTimeAvg = metrics.systems[system].responseTimeTotal / metrics.systems[system].requestsTotal;
  }
};

/**
 * Enregistre une vérification de santé
 * @param {string} system - Le système vérifié
 * @param {boolean} healthy - Si le système est en bonne santé
 */
const recordHealthCheck = (system, healthy) => {
  if (metrics.systems[system]) {
    metrics.systems[system].healthChecks++;
    if (!healthy) {
      metrics.systems[system].healthChecksFailed++;
    }
    metrics.systems[system].lastHealthCheckTime = Date.now();
    metrics.systems[system].lastHealthCheckStatus = healthy;
  }
};

/**
 * Enregistre un basculement
 * @param {string} fromSystem - Le système source
 * @param {string} toSystem - Le système cible
 * @param {boolean} automatic - Si le basculement était automatique
 * @param {string} reason - La raison du basculement
 */
const recordFailover = (fromSystem, toSystem, automatic, reason) => {
  metrics.failover.total++;
  if (automatic) {
    metrics.failover.automatic++;
  } else {
    metrics.failover.manual++;
  }
  metrics.failover.lastFailoverTime = Date.now();
  metrics.failover.lastFailoverReason = reason;
  
  // Mettre à jour le temps actif du système source
  if (metrics.systems[fromSystem] && metrics.systems[fromSystem].lastActiveTime) {
    const activeTime = Date.now() - metrics.systems[fromSystem].lastActiveTime;
    metrics.systems[fromSystem].activeTime += activeTime;
    metrics.systems[fromSystem].lastActiveTime = null;
  }
  
  // Initialiser le temps actif du système cible
  if (metrics.systems[toSystem]) {
    metrics.systems[toSystem].lastActiveTime = Date.now();
  }
};

/**
 * Enregistre un changement de système actif
 * @param {string} system - Le nouveau système actif
 */
const recordActiveSystem = (system) => {
  // Mettre à jour le temps actif pour tous les systèmes
  for (const [systemName, systemMetrics] of Object.entries(metrics.systems)) {
    if (systemName === system) {
      // Nouveau système actif
      systemMetrics.lastActiveTime = Date.now();
    } else if (systemMetrics.lastActiveTime) {
      // Ancien système actif
      const activeTime = Date.now() - systemMetrics.lastActiveTime;
      systemMetrics.activeTime += activeTime;
      systemMetrics.lastActiveTime = null;
    }
  }
};

/**
 * Met à jour les métriques système
 */
const updateSystemMetrics = () => {
  // CPU
  const cpus = os.cpus();
  let totalIdle = 0;
  let totalTick = 0;
  
  for (const cpu of cpus) {
    for (const type in cpu.times) {
      totalTick += cpu.times[type];
    }
    totalIdle += cpu.times.idle;
  }
  
  const idle = totalIdle / cpus.length;
  const total = totalTick / cpus.length;
  const usage = 100 - (idle / total * 100);
  
  metrics.system.cpuUsage = Math.round(usage * 100) / 100;
  
  // Mémoire
  const totalMem = os.totalmem();
  const freeMem = os.freemem();
  const usedMem = totalMem - freeMem;
  
  metrics.system.memoryUsage = Math.round(usedMem / totalMem * 10000) / 100;
  
  // Uptime
  metrics.system.uptime = Math.round((Date.now() - metrics.server.startTime) / 1000);
};

/**
 * Récupère toutes les métriques
 * @returns {Object} Les métriques collectées
 */
const getMetrics = () => {
  // Mettre à jour les métriques système
  updateSystemMetrics();
  
  return {
    ...metrics,
    timestamp: Date.now()
  };
};

/**
 * Sauvegarde les métriques dans un fichier
 * @returns {Promise<void>}
 */
const saveMetrics = async () => {
  try {
    const metricsDir = path.join(config.logging.directory, '../metrics');
    await fs.ensureDir(metricsDir);
    
    const metricsPath = path.join(metricsDir, `metrics_${new Date().toISOString().slice(0, 10)}.json`);
    
    // Vérifier si le fichier existe
    let existingMetrics = [];
    if (await fs.pathExists(metricsPath)) {
      existingMetrics = await fs.readJson(metricsPath);
    }
    
    // Ajouter les métriques actuelles
    existingMetrics.push({
      ...getMetrics(),
      timestamp: Date.now()
    });
    
    // Limiter le nombre d'entrées (garder les 1000 dernières)
    if (existingMetrics.length > 1000) {
      existingMetrics = existingMetrics.slice(-1000);
    }
    
    // Sauvegarder les métriques
    await fs.writeJson(metricsPath, existingMetrics, { spaces: 2 });
    
    logger.debug('Métriques sauvegardées');
  } catch (error) {
    logger.error(`Erreur lors de la sauvegarde des métriques: ${error.message}`);
  }
};

// Sauvegarder les métriques périodiquement (toutes les 5 minutes)
setInterval(saveMetrics, 5 * 60 * 1000);

module.exports = {
  recordRequest,
  recordHealthCheck,
  recordFailover,
  recordActiveSystem,
  getMetrics,
  saveMetrics
};
