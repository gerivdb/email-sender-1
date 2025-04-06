import axios from 'axios'

const API_URL = process.env.VUE_APP_API_URL || 'http://localhost:8000/api'

export default {
  async getNotifications() {
    try {
      const response = await axios.get(`${API_URL}/notifications`)
      return response.data
    } catch (error) {
      console.error('Error fetching notifications:', error)
      throw error
    }
  },
  
  async markAsRead(notificationId) {
    try {
      const response = await axios.post(`${API_URL}/notifications/${notificationId}/read`)
      return response.data
    } catch (error) {
      console.error('Error marking notification as read:', error)
      throw error
    }
  },
  
  async markAllAsRead() {
    try {
      const response = await axios.post(`${API_URL}/notifications/read-all`)
      return response.data
    } catch (error) {
      console.error('Error marking all notifications as read:', error)
      throw error
    }
  },
  
  async getSettings() {
    try {
      const response = await axios.get(`${API_URL}/notifications/settings`)
      return response.data
    } catch (error) {
      console.error('Error fetching notification settings:', error)
      throw error
    }
  },
  
  async updateSettings(settings) {
    try {
      const response = await axios.put(`${API_URL}/notifications/settings`, settings)
      return response.data
    } catch (error) {
      console.error('Error updating notification settings:', error)
      throw error
    }
  }
}
