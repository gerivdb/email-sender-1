// State initial
const state = {
  projects: [],
  issues: [],
  loading: false,
  error: null,
  config: {
    enabled: false,
    url: '',
    username: '',
    apiToken: ''
  }
}

// Getters
const getters = {
  getProjects: state => state.projects,
  getIssues: state => state.issues,
  isLoading: state => state.loading,
  getError: state => state.error,
  getConfig: state => state.config
}

// Actions
const actions = {
  async fetchConfig({ commit }) {
    commit('SET_LOADING', true)
    try {
      // Simulation d'appel API (à remplacer par un appel réel)
      await new Promise(resolve => setTimeout(resolve, 300))
      const config = {
        enabled: false,
        url: '',
        username: '',
        apiToken: ''
      }
      commit('SET_CONFIG', config)
      return config
    } catch (error) {
      commit('SET_ERROR', error.message)
      throw error
    } finally {
      commit('SET_LOADING', false)
    }
  },
  
  async updateConfig({ commit }, config) {
    commit('SET_LOADING', true)
    try {
      // Simulation d'appel API (à remplacer par un appel réel)
      await new Promise(resolve => setTimeout(resolve, 300))
      commit('SET_CONFIG', config)
      return config
    } catch (error) {
      commit('SET_ERROR', error.message)
      throw error
    } finally {
      commit('SET_LOADING', false)
    }
  },
  
  async fetchProjects({ commit }) {
    commit('SET_LOADING', true)
    try {
      // Simulation d'appel API (à remplacer par un appel réel)
      await new Promise(resolve => setTimeout(resolve, 500))
      const projects = []
      commit('SET_PROJECTS', projects)
      return projects
    } catch (error) {
      commit('SET_ERROR', error.message)
      throw error
    } finally {
      commit('SET_LOADING', false)
    }
  },
  
  async fetchIssues({ commit }, projectKey) {
    commit('SET_LOADING', true)
    try {
      // Simulation d'appel API (à remplacer par un appel réel)
      await new Promise(resolve => setTimeout(resolve, 500))
      const issues = []
      commit('SET_ISSUES', issues)
      return issues
    } catch (error) {
      commit('SET_ERROR', error.message)
      throw error
    } finally {
      commit('SET_LOADING', false)
    }
  },
  
  async createIssue({ commit }, issue) {
    commit('SET_LOADING', true)
    try {
      // Simulation d'appel API (à remplacer par un appel réel)
      await new Promise(resolve => setTimeout(resolve, 500))
      return { id: 'ISSUE-1', key: 'PROJ-1' }
    } catch (error) {
      commit('SET_ERROR', error.message)
      throw error
    } finally {
      commit('SET_LOADING', false)
    }
  },
  
  async syncToJournal({ commit }) {
    commit('SET_LOADING', true)
    try {
      // Simulation d'appel API (à remplacer par un appel réel)
      await new Promise(resolve => setTimeout(resolve, 1000))
      return { success: true, count: 0 }
    } catch (error) {
      commit('SET_ERROR', error.message)
      throw error
    } finally {
      commit('SET_LOADING', false)
    }
  },
  
  async syncFromJournal({ commit }) {
    commit('SET_LOADING', true)
    try {
      // Simulation d'appel API (à remplacer par un appel réel)
      await new Promise(resolve => setTimeout(resolve, 1000))
      return { success: true, count: 0 }
    } catch (error) {
      commit('SET_ERROR', error.message)
      throw error
    } finally {
      commit('SET_LOADING', false)
    }
  }
}

// Mutations
const mutations = {
  SET_PROJECTS(state, projects) {
    state.projects = projects
  },
  SET_ISSUES(state, issues) {
    state.issues = issues
  },
  SET_LOADING(state, loading) {
    state.loading = loading
  },
  SET_ERROR(state, error) {
    state.error = error
  },
  SET_CONFIG(state, config) {
    state.config = config
  }
}

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations
}
