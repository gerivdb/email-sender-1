// State initial
const state = {
  repositories: [],
  issues: [],
  commits: [],
  loading: false,
  error: null,
  config: {
    enabled: false,
    token: '',
    username: '',
    repositories: []
  }
}

// Getters
const getters = {
  getRepositories: state => state.repositories,
  getIssues: state => state.issues,
  getCommits: state => state.commits,
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
        token: '',
        username: '',
        repositories: []
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
  
  async fetchRepositories({ commit }) {
    commit('SET_LOADING', true)
    try {
      // Simulation d'appel API (à remplacer par un appel réel)
      await new Promise(resolve => setTimeout(resolve, 500))
      const repositories = []
      commit('SET_REPOSITORIES', repositories)
      return repositories
    } catch (error) {
      commit('SET_ERROR', error.message)
      throw error
    } finally {
      commit('SET_LOADING', false)
    }
  },
  
  async fetchIssues({ commit }, repoName) {
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
  
  async fetchCommits({ commit }, repoName) {
    commit('SET_LOADING', true)
    try {
      // Simulation d'appel API (à remplacer par un appel réel)
      await new Promise(resolve => setTimeout(resolve, 500))
      const commits = []
      commit('SET_COMMITS', commits)
      return commits
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
  SET_REPOSITORIES(state, repositories) {
    state.repositories = repositories
  },
  SET_ISSUES(state, issues) {
    state.issues = issues
  },
  SET_COMMITS(state, commits) {
    state.commits = commits
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
