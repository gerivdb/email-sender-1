/**
 * Module de cache
 * Implémente un cache en mémoire pour améliorer les performances
 */

const logger = require('./logger');
const config = require('./config');

// Cache en mémoire
const cache = new Map();

// Statistiques du cache
const stats = {
  hits: 0,
  misses: 0,
  sets: 0,
  evictions: 0
};

/**
 * Récupère une valeur du cache
 * @param {string} key - La clé de la valeur à récupérer
 * @returns {*} La valeur associée à la clé ou undefined si elle n'existe pas
 */
const get = (key) => {
  // Vérifier si le cache est activé
  if (!config.cache?.enabled) {
    return undefined;
  }
  
  // Vérifier si la clé existe dans le cache
  if (!cache.has(key)) {
    stats.misses++;
    return undefined;
  }
  
  // Récupérer l'entrée du cache
  const entry = cache.get(key);
  
  // Vérifier si l'entrée est expirée
  if (entry.expiry && entry.expiry < Date.now()) {
    // Supprimer l'entrée expirée
    cache.delete(key);
    stats.evictions++;
    stats.misses++;
    return undefined;
  }
  
  // Mettre à jour les statistiques
  stats.hits++;
  
  // Retourner la valeur
  return entry.value;
};

/**
 * Ajoute ou met à jour une valeur dans le cache
 * @param {string} key - La clé de la valeur à ajouter
 * @param {*} value - La valeur à ajouter
 * @param {number} ttl - Durée de vie en secondes (optionnel)
 * @returns {boolean} true si la valeur a été ajoutée, false sinon
 */
const set = (key, value, ttl = null) => {
  // Vérifier si le cache est activé
  if (!config.cache?.enabled) {
    return false;
  }
  
  // Vérifier si le cache a atteint sa taille maximale
  if (!cache.has(key) && cache.size >= config.cache.maxSize) {
    // Supprimer l'entrée la plus ancienne
    const oldestKey = cache.keys().next().value;
    cache.delete(oldestKey);
    stats.evictions++;
    logger.debug(`Cache plein, suppression de l'entrée la plus ancienne: ${oldestKey}`);
  }
  
  // Calculer la date d'expiration
  const ttlValue = ttl || config.cache.ttl;
  const expiry = ttlValue ? Date.now() + (ttlValue * 1000) : null;
  
  // Ajouter l'entrée au cache
  cache.set(key, {
    value,
    expiry,
    createdAt: Date.now()
  });
  
  // Mettre à jour les statistiques
  stats.sets++;
  
  return true;
};

/**
 * Supprime une valeur du cache
 * @param {string} key - La clé de la valeur à supprimer
 * @returns {boolean} true si la valeur a été supprimée, false sinon
 */
const del = (key) => {
  // Vérifier si le cache est activé
  if (!config.cache?.enabled) {
    return false;
  }
  
  // Supprimer l'entrée du cache
  return cache.delete(key);
};

/**
 * Vide le cache
 * @returns {boolean} true si le cache a été vidé, false sinon
 */
const clear = () => {
  // Vérifier si le cache est activé
  if (!config.cache?.enabled) {
    return false;
  }
  
  // Vider le cache
  cache.clear();
  
  // Réinitialiser les statistiques
  stats.hits = 0;
  stats.misses = 0;
  stats.sets = 0;
  stats.evictions = 0;
  
  return true;
};

/**
 * Récupère les statistiques du cache
 * @returns {Object} Les statistiques du cache
 */
const getStats = () => {
  return {
    ...stats,
    size: cache.size,
    maxSize: config.cache?.maxSize || 0,
    hitRate: stats.hits + stats.misses > 0 ? stats.hits / (stats.hits + stats.misses) : 0,
    enabled: config.cache?.enabled || false
  };
};

/**
 * Récupère toutes les entrées du cache
 * @returns {Object} Les entrées du cache
 */
const getEntries = () => {
  const entries = {};
  
  for (const [key, entry] of cache.entries()) {
    entries[key] = {
      value: entry.value,
      expiry: entry.expiry,
      createdAt: entry.createdAt,
      ttl: entry.expiry ? Math.round((entry.expiry - Date.now()) / 1000) : null
    };
  }
  
  return entries;
};

/**
 * Nettoie les entrées expirées du cache
 * @returns {number} Le nombre d'entrées supprimées
 */
const cleanup = () => {
  // Vérifier si le cache est activé
  if (!config.cache?.enabled) {
    return 0;
  }
  
  let count = 0;
  const now = Date.now();
  
  // Parcourir toutes les entrées du cache
  for (const [key, entry] of cache.entries()) {
    // Vérifier si l'entrée est expirée
    if (entry.expiry && entry.expiry < now) {
      // Supprimer l'entrée expirée
      cache.delete(key);
      count++;
    }
  }
  
  // Mettre à jour les statistiques
  stats.evictions += count;
  
  return count;
};

// Nettoyer périodiquement les entrées expirées (toutes les minutes)
setInterval(cleanup, 60 * 1000);

module.exports = {
  get,
  set,
  del,
  clear,
  getStats,
  getEntries,
  cleanup
};
