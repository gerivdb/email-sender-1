import notificationsService from '@/services/notificationsService'

const state = {
  notifications: [],
  loading: false,
  error: null
}

const getters = {
  notifications: state => state.notifications,
  unreadNotifications: state => state.notifications.filter(n => !n.read),
  isLoading: state => state.loading,
  error: state => state.error
}

const mutations = {
  SET_NOTIFICATIONS(state, notifications) {
    state.notifications = notifications
  },
  ADD_NOTIFICATION(state, notification) {
    state.notifications.unshift(notification)
  },
  MARK_AS_READ(state, notificationId) {
    const notification = state.notifications.find(n => n.id === notificationId)
    if (notification) {
      notification.read = true
    }
  },
  MARK_ALL_AS_READ(state) {
    state.notifications.forEach(notification => {
      notification.read = true
    })
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
  async fetchNotifications({ commit }) {
    commit('SET_LOADING', true)
    commit('CLEAR_ERROR')
    
    try {
      const response = await notificationsService.getNotifications()
      commit('SET_NOTIFICATIONS', response.notifications)
    } catch (error) {
      commit('SET_ERROR', error.message || 'Erreur lors de la récupération des notifications')
      console.error('Error fetching notifications:', error)
    } finally {
      commit('SET_LOADING', false)
    }
  },
  
  async markNotificationAsRead({ commit }, notificationId) {
    commit('SET_LOADING', true)
    commit('CLEAR_ERROR')
    
    try {
      await notificationsService.markAsRead(notificationId)
      commit('MARK_AS_READ', notificationId)
    } catch (error) {
      commit('SET_ERROR', error.message || 'Erreur lors du marquage de la notification comme lue')
      console.error('Error marking notification as read:', error)
    } finally {
      commit('SET_LOADING', false)
    }
  },
  
  async markAllNotificationsAsRead({ commit }) {
    commit('SET_LOADING', true)
    commit('CLEAR_ERROR')
    
    try {
      await notificationsService.markAllAsRead()
      commit('MARK_ALL_AS_READ')
    } catch (error) {
      commit('SET_ERROR', error.message || 'Erreur lors du marquage de toutes les notifications comme lues')
      console.error('Error marking all notifications as read:', error)
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
