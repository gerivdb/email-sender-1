import authService from '@/services/authService'

const state = {
  user: null,
  token: localStorage.getItem('token') || null,
  loading: false,
  error: null
}

const getters = {
  currentUser: state => state.user,
  isAuthenticated: state => !!state.token,
  username: state => state.user ? state.user.username : 'Utilisateur',
  isLoading: state => state.loading,
  error: state => state.error
}

const mutations = {
  SET_USER(state, user) {
    state.user = user
  },
  SET_TOKEN(state, token) {
    state.token = token
    if (token) {
      localStorage.setItem('token', token)
    } else {
      localStorage.removeItem('token')
    }
  },
  SET_LOADING(state, loading) {
    state.loading = loading
  },
  SET_ERROR(state, error) {
    state.error = error
  },
  CLEAR_ERROR(state) {
    state.error = null
  }
}

const actions = {
  async login({ commit }, { username, password }) {
    commit('SET_LOADING', true)
    commit('CLEAR_ERROR')
    
    try {
      const response = await authService.login(username, password)
      commit('SET_USER', response.user)
      commit('SET_TOKEN', response.token)
      return response
    } catch (error) {
      commit('SET_ERROR', error.message || 'Erreur lors de la connexion')
      console.error('Error during login:', error)
      throw error
    } finally {
      commit('SET_LOADING', false)
    }
  },
  
  async logout({ commit }) {
    commit('SET_LOADING', true)
    commit('CLEAR_ERROR')
    
    try {
      await authService.logout()
      commit('SET_USER', null)
      commit('SET_TOKEN', null)
    } catch (error) {
      console.error('Error during logout:', error)
    } finally {
      commit('SET_LOADING', false)
    }
  },
  
  async fetchCurrentUser({ commit, state }) {
    if (!state.token) return
    
    commit('SET_LOADING', true)
    commit('CLEAR_ERROR')
    
    try {
      const user = await authService.getCurrentUser()
      commit('SET_USER', user)
    } catch (error) {
      commit('SET_ERROR', error.message || 'Erreur lors de la récupération du profil utilisateur')
      console.error('Error fetching current user:', error)
      
      // Si l'erreur est due à un token invalide, déconnecter l'utilisateur
      if (error.response && error.response.status === 401) {
        commit('SET_USER', null)
        commit('SET_TOKEN', null)
      }
    } finally {
      commit('SET_LOADING', false)
    }
  }
}

export default {
  namespaced: true,
  state,
  getters,
  mutations,
  actions
}
