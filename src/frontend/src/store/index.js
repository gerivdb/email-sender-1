import { createStore } from 'vuex'
import journalModule from './modules/journal'
import analysisModule from './modules/analysis'
import githubModule from './modules/github'
import jiraModule from './modules/jira'
import notionModule from './modules/notion'
import notificationsModule from './modules/notifications'
import userModule from './modules/user'

export default createStore({
  state: {
    sidebarCollapsed: false,
    notificationCenterOpen: false,
    loading: false,
    error: null
  },
  getters: {
    isSidebarCollapsed: state => state.sidebarCollapsed,
    isNotificationCenterOpen: state => state.notificationCenterOpen,
    isLoading: state => state.loading,
    error: state => state.error
  },
  mutations: {
    SET_SIDEBAR_COLLAPSED(state, collapsed) {
      state.sidebarCollapsed = collapsed
    },
    SET_NOTIFICATION_CENTER_OPEN(state, open) {
      state.notificationCenterOpen = open
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
  },
  actions: {
    toggleSidebar({ commit, state }) {
      commit('SET_SIDEBAR_COLLAPSED', !state.sidebarCollapsed)
    },
    toggleNotificationCenter({ commit }, open) {
      commit('SET_NOTIFICATION_CENTER_OPEN', open)
    },
    setLoading({ commit }, loading) {
      commit('SET_LOADING', loading)
    },
    setError({ commit }, error) {
      commit('SET_ERROR', error)
    },
    clearError({ commit }) {
      commit('CLEAR_ERROR')
    }
  },
  modules: {
    journal: journalModule,
    analysis: analysisModule,
    github: githubModule,
    jira: jiraModule,
    notion: notionModule,
    notifications: notificationsModule,
    user: userModule
  }
})
