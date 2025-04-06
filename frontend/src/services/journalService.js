import axios from 'axios'

const API_URL = process.env.VUE_APP_API_URL || 'http://localhost:8000/api'

export default {
  async getEntries(params = {}) {
    try {
      const response = await axios.get(`${API_URL}/journal/entries`, { params })
      return response.data
    } catch (error) {
      console.error('Error fetching journal entries:', error)
      throw error
    }
  },
  
  async getEntry(filename) {
    try {
      const response = await axios.get(`${API_URL}/journal/entry/${filename}`)
      return response.data
    } catch (error) {
      console.error(`Error fetching entry ${filename}:`, error)
      throw error
    }
  },
  
  async searchJournal(query, limit = 10) {
    try {
      const response = await axios.post(`${API_URL}/journal/search`, { query, limit })
      return response.data
    } catch (error) {
      console.error('Error searching journal:', error)
      throw error
    }
  },
  
  async queryRag(query, limit = 5) {
    try {
      const response = await axios.post(`${API_URL}/journal/rag`, { query, limit })
      return response.data
    } catch (error) {
      console.error('Error querying RAG:', error)
      throw error
    }
  },
  
  async createEntry(entryData) {
    try {
      const response = await axios.post(`${API_URL}/journal/entries`, entryData)
      return response.data
    } catch (error) {
      console.error('Error creating entry:', error)
      throw error
    }
  },
  
  async updateEntry(filename, entryData) {
    try {
      const response = await axios.put(`${API_URL}/journal/entry/${filename}`, entryData)
      return response.data
    } catch (error) {
      console.error(`Error updating entry ${filename}:`, error)
      throw error
    }
  },
  
  async getTags() {
    try {
      const response = await axios.get(`${API_URL}/journal/tags`)
      return response.data
    } catch (error) {
      console.error('Error fetching tags:', error)
      throw error
    }
  }
}
