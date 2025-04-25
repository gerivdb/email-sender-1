import api from './api';

/**
 * Service pour gérer les notifications
 */
export default {
  /**
   * Récupère les notifications
   * @param {Object} params - Paramètres de la requête
   * @param {boolean} params.unread_only - Récupérer uniquement les notifications non lues
   * @param {number} params.limit - Nombre maximum de notifications
   * @returns {Promise} - Promesse contenant les notifications
   */
  getNotifications(params = {}) {
    return api.get('/notifications', { params });
  },

  /**
   * Marque une notification comme lue
   * @param {string} notificationId - ID de la notification
   * @returns {Promise} - Promesse contenant le résultat
   */
  markAsRead(notificationId) {
    return api.post(`/notifications/${notificationId}/read`);
  },

  /**
   * Marque toutes les notifications comme lues
   * @returns {Promise} - Promesse contenant le résultat
   */
  markAllAsRead() {
    return api.post('/notifications/read-all');
  },

  /**
   * Récupère les paramètres de notification
   * @returns {Promise} - Promesse contenant les paramètres
   */
  getSettings() {
    return api.get('/notifications/settings');
  },

  /**
   * Met à jour les paramètres de notification
   * @param {Object} settings - Nouveaux paramètres
   * @returns {Promise} - Promesse contenant le résultat
   */
  updateSettings(settings) {
    return api.put('/notifications/settings', settings);
  },

  /**
   * Déclenche la détection de patterns
   * @returns {Promise} - Promesse contenant le résultat
   */
  detectPatterns() {
    return api.post('/notifications/detect');
  },

  /**
   * Configure les canaux de notification
   * @param {string} channel - Nom du canal (email, desktop, web, slack)
   * @param {Object} config - Configuration du canal
   * @returns {Promise} - Promesse contenant le résultat
   */
  configureChannel(channel, config) {
    return api.post(`/notifications/channels/${channel}/configure`, config);
  },

  /**
   * Teste un canal de notification
   * @param {string} channel - Nom du canal (email, desktop, web, slack)
   * @returns {Promise} - Promesse contenant le résultat
   */
  testChannel(channel) {
    return api.post(`/notifications/channels/${channel}/test`);
  }
};
