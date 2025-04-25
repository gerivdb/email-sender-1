import axios from 'axios'

const API_URL = process.env.VUE_APP_API_URL || 'http://localhost:8000/api'

// Intercepteur pour ajouter le token d'authentification
axios.interceptors.request.use(
  config => {
    const token = localStorage.getItem('token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  error => Promise.reject(error)
)

export default {
  async login(username, password) {
    try {
      const response = await axios.post(`${API_URL}/auth/login`, { username, password })
      return response.data
    } catch (error) {
      console.error('Error during login:', error)
      throw error
    }
  },
  
  async logout() {
    try {
      await axios.post(`${API_URL}/auth/logout`)
      localStorage.removeItem('token')
    } catch (error) {
      console.error('Error during logout:', error)
      throw error
    }
  },
  
  async getCurrentUser() {
    try {
      const response = await axios.get(`${API_URL}/auth/me`)
      return response.data
    } catch (error) {
      console.error('Error fetching current user:', error)
      throw error
    }
  },
  
  async register(userData) {
    try {
      const response = await axios.post(`${API_URL}/auth/register`, userData)
      return response.data
    } catch (error) {
      console.error('Error during registration:', error)
      throw error
    }
  },
  
  async updateProfile(userData) {
    try {
      const response = await axios.put(`${API_URL}/auth/profile`, userData)
      return response.data
    } catch (error) {
      console.error('Error updating profile:', error)
      throw error
    }
  },
  
  async changePassword(passwordData) {
    try {
      const response = await axios.put(`${API_URL}/auth/password`, passwordData)
      return response.data
    } catch (error) {
      console.error('Error changing password:', error)
      throw error
    }
  }
}
