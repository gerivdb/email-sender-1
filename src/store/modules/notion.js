// State initial
const state = {
  pages: [],
  databases: [],
  loading: false,
  error: null,
  config: {
    enabled: false,
    apiKey: ''
  }
}

// Getters
const getters = {
  getPages: state => state.pages,
  getDatabases: state => state.databases,
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
        apiKey: ''
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
  
  async fetchPages({ commit }) {
    commit('SET_LOADING', true)
    try {
      // Simulation d'appel API (à remplacer par un appel réel)
      await new Promise(resolve => setTimeout(resolve, 500))
      const pages = []
      commit('SET_PAGES', pages)
      return pages
    } catch (error) {
      commit('SET_ERROR', error.message)
      throw error
    } finally {
      commit('SET_LOADING', false)
    }
  },
  
  async fetchDatabases({ commit }) {
    commit('SET_LOADING', true)
    try {
      // Simulation d'appel API (à remplacer par un appel réel)
      await new Promise(resolve => setTimeout(resolve, 500))
      const databases = []
      commit('SET_DATABASES', databases)
      return databases
    } catch (error) {
      commit('SET_ERROR', error.message)
      throw error
    } finally {
      commit('SET_LOADING', false)
    }
  },
  
  async createPage({ commit }, page) {
    commit('SET_LOADING', true)
    try {
      // Simulation d'appel API (à remplacer par un appel réel)
      await new Promise(resolve => setTimeout(resolve, 500))
      return { id: 'page-id' }
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
  SET_PAGES(state, pages) {
    state.pages = pages
  },
  SET_DATABASES(state, databases) {
    state.databases = databases
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
