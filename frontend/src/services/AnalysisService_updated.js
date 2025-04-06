import axios from 'axios'

const API_URL = process.env.VUE_APP_API_URL || 'http://localhost:8000/api'

export default {
  async getTermFrequency(period = 'month') {
    try {
      const response = await axios.get(`${API_URL}/analysis/term-frequency`, { params: { period } })
      return response.data
    } catch (error) {
      console.error('Error fetching term frequency:', error)
      throw error
    }
  },
  
  async getWordCloud(period = null) {
    try {
      const params = period ? { period } : {}
      const response = await axios.get(`${API_URL}/analysis/word-cloud`, { params })
      return response.data
    } catch (error) {
      console.error('Error fetching word cloud:', error)
      throw error
    }
  },
  
  async getTagEvolution() {
    try {
      const response = await axios.get(`${API_URL}/analysis/tag-evolution`)
      return response.data
    } catch (error) {
      console.error('Error fetching tag evolution:', error)
      throw error
    }
  },
  
  async getTopicTrends(period = 'all') {
    try {
      const response = await axios.get(`${API_URL}/analysis/topic-trends`, {
        params: { period }
      })
      return response.data
    } catch (error) {
      console.error('Error fetching topic trends:', error)
      throw error
    }
  },
  
  async getClusters(n_clusters = 5) {
    try {
      const response = await axios.get(`${API_URL}/analysis/clusters`, { params: { n_clusters } })
      return response.data
    } catch (error) {
      console.error('Error fetching clusters:', error)
      throw error
    }
  },
  
  async getInsights(category = null) {
    try {
      const params = category ? { category } : {}
      const response = await axios.get(`${API_URL}/analysis/insights`, { params })
      return response.data
    } catch (error) {
      console.error('Error fetching insights:', error)
      throw error
    }
  },
  
  async getSentimentAnalysis() {
    try {
      const response = await axios.get(`${API_URL}/analysis/sentiment`)
      return response.data
    } catch (error) {
      console.error('Error fetching sentiment analysis:', error)
      throw error
    }
  },
  
  async getSentimentEvolution() {
    try {
      const response = await axios.get(`${API_URL}/analysis/sentiment/evolution`)
      return response.data
    } catch (error) {
      console.error('Error fetching sentiment evolution:', error)
      throw error
    }
  },
  
  async getSentimentBySections() {
    try {
      const response = await axios.get(`${API_URL}/analysis/sentiment/sections`)
      return response.data
    } catch (error) {
      console.error('Error fetching sentiment by sections:', error)
      throw error
    }
  },
  
  async getEntityRecognition() {
    try {
      const response = await axios.get(`${API_URL}/analysis/entities`)
      return response.data
    } catch (error) {
      console.error('Error fetching entity recognition:', error)
      throw error
    }
  },
  
  async runAnalysis(analysisType) {
    try {
      const response = await axios.post(`${API_URL}/analysis/run`, {
        analysis_type: analysisType
      })
      return response.data
    } catch (error) {
      console.error(`Error running ${analysisType} analysis:`, error)
      throw error
    }
  },
  
  async runAllAnalyses() {
    try {
      const response = await axios.post(`${API_URL}/analysis/run`, {
        analysis_type: 'all'
      })
      return response.data
    } catch (error) {
      console.error('Error running all analyses:', error)
      throw error
    }
  },
  
  async getSimilarEntries(filename, limit = 5) {
    try {
      const response = await axios.get(`${API_URL}/analysis/similar/${filename}`, {
        params: { limit }
      })
      return response.data
    } catch (error) {
      console.error('Error fetching similar entries:', error)
      throw error
    }
  },
  
  async queryRag(query) {
    try {
      const response = await axios.post(`${API_URL}/analysis/rag/query`, {
        query
      })
      return response.data
    } catch (error) {
      console.error('Error querying RAG system:', error)
      throw error
    }
  }
}
