import api from './api';

/**
 * Service pour gérer les intégrations externes
 */
export default {
  /**
   * Récupère le statut des intégrations
   * @returns {Promise} - Promesse contenant le statut des intégrations
   */
  getIntegrationsStatus() {
    return api.get('/integrations/status');
  },

  /**
   * Notion
   */
  
  /**
   * Configure l'intégration Notion
   * @param {Object} config - Configuration Notion
   * @returns {Promise} - Promesse contenant le résultat
   */
  configureNotion(config) {
    return api.post('/integrations/notion/configure', config);
  },

  /**
   * Récupère les pages Notion
   * @returns {Promise} - Promesse contenant les pages
   */
  getNotionPages() {
    return api.get('/integrations/notion/pages');
  },

  /**
   * Synchronise les pages Notion vers le journal
   * @returns {Promise} - Promesse contenant le résultat
   */
  syncNotionToJournal() {
    return api.post('/integrations/notion/sync-to-journal');
  },

  /**
   * Synchronise les entrées du journal vers Notion
   * @returns {Promise} - Promesse contenant le résultat
   */
  syncJournalToNotion() {
    return api.post('/integrations/notion/sync-from-journal');
  },

  /**
   * Jira
   */
  
  /**
   * Configure l'intégration Jira
   * @param {Object} config - Configuration Jira
   * @returns {Promise} - Promesse contenant le résultat
   */
  configureJira(config) {
    return api.post('/integrations/jira/configure', config);
  },

  /**
   * Récupère les issues Jira
   * @returns {Promise} - Promesse contenant les issues
   */
  getJiraIssues() {
    return api.get('/integrations/jira/issues');
  },

  /**
   * Synchronise les issues Jira vers le journal
   * @returns {Promise} - Promesse contenant le résultat
   */
  syncJiraToJournal() {
    return api.post('/integrations/jira/sync-to-journal');
  },

  /**
   * Synchronise les entrées du journal vers Jira
   * @returns {Promise} - Promesse contenant le résultat
   */
  syncJournalToJira() {
    return api.post('/integrations/jira/sync-from-journal');
  },

  /**
   * GitHub
   */
  
  /**
   * Configure l'intégration GitHub
   * @param {Object} config - Configuration GitHub
   * @returns {Promise} - Promesse contenant le résultat
   */
  configureGitHub(config) {
    return api.post('/integrations/github/configure', config);
  },

  /**
   * Récupère les commits GitHub
   * @returns {Promise} - Promesse contenant les commits
   */
  getGitHubCommits() {
    return api.get('/integrations/github/commits');
  },

  /**
   * n8n
   */
  
  /**
   * Configure l'intégration n8n
   * @param {Object} config - Configuration n8n
   * @returns {Promise} - Promesse contenant le résultat
   */
  configureN8n(config) {
    return api.post('/integrations/n8n/configure', config);
  },

  /**
   * Récupère les workflows n8n
   * @returns {Promise} - Promesse contenant les workflows
   */
  getN8nWorkflows() {
    return api.get('/integrations/n8n/workflows');
  },

  /**
   * Exécute un workflow n8n
   * @param {string} workflowId - ID du workflow
   * @param {Object} data - Données pour l'exécution
   * @returns {Promise} - Promesse contenant le résultat
   */
  executeN8nWorkflow(workflowId, data) {
    return api.post(`/integrations/n8n/execute/${workflowId}`, data);
  }
};
