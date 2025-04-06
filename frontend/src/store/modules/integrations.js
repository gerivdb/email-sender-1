import integrationService from '@/services/integrationService';

// État initial
const state = {
  status: {
    notion: false,
    jira: false,
    github: false,
    n8n: false
  },
  notionPages: [],
  jiraIssues: [],
  githubCommits: [],
  n8nWorkflows: [],
  loading: false,
  error: null
};

// Getters
const getters = {
  status: state => state.status,
  notionPages: state => state.notionPages,
  jiraIssues: state => state.jiraIssues,
  githubCommits: state => state.githubCommits,
  n8nWorkflows: state => state.n8nWorkflows,
  loading: state => state.loading,
  error: state => state.error
};

// Actions
const actions = {
  /**
   * Récupère le statut des intégrations
   * @param {Object} context - Context Vuex
   */
  async fetchStatus({ commit }) {
    commit('SET_LOADING', true);
    commit('CLEAR_ERROR');
    
    try {
      const response = await integrationService.getIntegrationsStatus();
      commit('SET_STATUS', response.data);
    } catch (error) {
      commit('SET_ERROR', 'Erreur lors de la récupération du statut des intégrations');
      console.error('Error fetching integrations status:', error);
    } finally {
      commit('SET_LOADING', false);
    }
  },

  /**
   * Notion
   */
  
  /**
   * Configure l'intégration Notion
   * @param {Object} context - Context Vuex
   * @param {Object} config - Configuration Notion
   */
  async configureNotion({ commit, dispatch }, config) {
    commit('SET_LOADING', true);
    commit('CLEAR_ERROR');
    
    try {
      await integrationService.configureNotion(config);
      
      // Mettre à jour le statut
      dispatch('fetchStatus');
    } catch (error) {
      commit('SET_ERROR', 'Erreur lors de la configuration de Notion');
      console.error('Error configuring Notion:', error);
    } finally {
      commit('SET_LOADING', false);
    }
  },

  /**
   * Récupère les pages Notion
   * @param {Object} context - Context Vuex
   */
  async fetchNotionPages({ commit }) {
    commit('SET_LOADING', true);
    commit('CLEAR_ERROR');
    
    try {
      const response = await integrationService.getNotionPages();
      commit('SET_NOTION_PAGES', response.data.pages);
    } catch (error) {
      commit('SET_ERROR', 'Erreur lors de la récupération des pages Notion');
      console.error('Error fetching Notion pages:', error);
    } finally {
      commit('SET_LOADING', false);
    }
  },

  /**
   * Synchronise les pages Notion vers le journal
   * @param {Object} context - Context Vuex
   */
  async syncNotionToJournal({ commit }) {
    commit('SET_LOADING', true);
    commit('CLEAR_ERROR');
    
    try {
      await integrationService.syncNotionToJournal();
    } catch (error) {
      commit('SET_ERROR', 'Erreur lors de la synchronisation de Notion vers le journal');
      console.error('Error syncing Notion to journal:', error);
    } finally {
      commit('SET_LOADING', false);
    }
  },

  /**
   * Synchronise les entrées du journal vers Notion
   * @param {Object} context - Context Vuex
   */
  async syncJournalToNotion({ commit }) {
    commit('SET_LOADING', true);
    commit('CLEAR_ERROR');
    
    try {
      await integrationService.syncJournalToNotion();
    } catch (error) {
      commit('SET_ERROR', 'Erreur lors de la synchronisation du journal vers Notion');
      console.error('Error syncing journal to Notion:', error);
    } finally {
      commit('SET_LOADING', false);
    }
  },

  /**
   * Jira
   */
  
  /**
   * Configure l'intégration Jira
   * @param {Object} context - Context Vuex
   * @param {Object} config - Configuration Jira
   */
  async configureJira({ commit, dispatch }, config) {
    commit('SET_LOADING', true);
    commit('CLEAR_ERROR');
    
    try {
      await integrationService.configureJira(config);
      
      // Mettre à jour le statut
      dispatch('fetchStatus');
    } catch (error) {
      commit('SET_ERROR', 'Erreur lors de la configuration de Jira');
      console.error('Error configuring Jira:', error);
    } finally {
      commit('SET_LOADING', false);
    }
  },

  /**
   * Récupère les issues Jira
   * @param {Object} context - Context Vuex
   */
  async fetchJiraIssues({ commit }) {
    commit('SET_LOADING', true);
    commit('CLEAR_ERROR');
    
    try {
      const response = await integrationService.getJiraIssues();
      commit('SET_JIRA_ISSUES', response.data.issues);
    } catch (error) {
      commit('SET_ERROR', 'Erreur lors de la récupération des issues Jira');
      console.error('Error fetching Jira issues:', error);
    } finally {
      commit('SET_LOADING', false);
    }
  },

  /**
   * Synchronise les issues Jira vers le journal
   * @param {Object} context - Context Vuex
   */
  async syncJiraToJournal({ commit }) {
    commit('SET_LOADING', true);
    commit('CLEAR_ERROR');
    
    try {
      await integrationService.syncJiraToJournal();
    } catch (error) {
      commit('SET_ERROR', 'Erreur lors de la synchronisation de Jira vers le journal');
      console.error('Error syncing Jira to journal:', error);
    } finally {
      commit('SET_LOADING', false);
    }
  },

  /**
   * Synchronise les entrées du journal vers Jira
   * @param {Object} context - Context Vuex
   */
  async syncJournalToJira({ commit }) {
    commit('SET_LOADING', true);
    commit('CLEAR_ERROR');
    
    try {
      await integrationService.syncJournalToJira();
    } catch (error) {
      commit('SET_ERROR', 'Erreur lors de la synchronisation du journal vers Jira');
      console.error('Error syncing journal to Jira:', error);
    } finally {
      commit('SET_LOADING', false);
    }
  },

  /**
   * n8n
   */
  
  /**
   * Configure l'intégration n8n
   * @param {Object} context - Context Vuex
   * @param {Object} config - Configuration n8n
   */
  async configureN8n({ commit, dispatch }, config) {
    commit('SET_LOADING', true);
    commit('CLEAR_ERROR');
    
    try {
      await integrationService.configureN8n(config);
      
      // Mettre à jour le statut
      dispatch('fetchStatus');
    } catch (error) {
      commit('SET_ERROR', 'Erreur lors de la configuration de n8n');
      console.error('Error configuring n8n:', error);
    } finally {
      commit('SET_LOADING', false);
    }
  },

  /**
   * Récupère les workflows n8n
   * @param {Object} context - Context Vuex
   */
  async fetchN8nWorkflows({ commit }) {
    commit('SET_LOADING', true);
    commit('CLEAR_ERROR');
    
    try {
      const response = await integrationService.getN8nWorkflows();
      commit('SET_N8N_WORKFLOWS', response.data.workflows);
    } catch (error) {
      commit('SET_ERROR', 'Erreur lors de la récupération des workflows n8n');
      console.error('Error fetching n8n workflows:', error);
    } finally {
      commit('SET_LOADING', false);
    }
  },

  /**
   * Exécute un workflow n8n
   * @param {Object} context - Context Vuex
   * @param {Object} params - Paramètres
   * @param {string} params.workflowId - ID du workflow
   * @param {Object} params.data - Données pour l'exécution
   */
  async executeN8nWorkflow({ commit }, { workflowId, data }) {
    commit('SET_LOADING', true);
    commit('CLEAR_ERROR');
    
    try {
      await integrationService.executeN8nWorkflow(workflowId, data);
    } catch (error) {
      commit('SET_ERROR', 'Erreur lors de l\'exécution du workflow n8n');
      console.error('Error executing n8n workflow:', error);
    } finally {
      commit('SET_LOADING', false);
    }
  }
};

// Mutations
const mutations = {
  SET_STATUS(state, status) {
    state.status = status;
  },
  
  SET_NOTION_PAGES(state, pages) {
    state.notionPages = pages;
  },
  
  SET_JIRA_ISSUES(state, issues) {
    state.jiraIssues = issues;
  },
  
  SET_GITHUB_COMMITS(state, commits) {
    state.githubCommits = commits;
  },
  
  SET_N8N_WORKFLOWS(state, workflows) {
    state.n8nWorkflows = workflows;
  },
  
  SET_LOADING(state, loading) {
    state.loading = loading;
  },
  
  SET_ERROR(state, error) {
    state.error = error;
  },
  
  CLEAR_ERROR(state) {
    state.error = null;
  }
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations
};
