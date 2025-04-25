// State initial
const state = {
  wordCloud: [],
  topicTrends: {
    topics: [],
    evolution: {}
  },
  sentimentEvolution: {
    dates: [],
    polarity: [],
    subjectivity: []
  },
  loading: false,
  error: null
}

// Getters
const getters = {
  getWordCloud: state => state.wordCloud,
  getTopicTrends: state => state.topicTrends,
  getSentimentEvolution: state => state.sentimentEvolution,
  isLoading: state => state.loading,
  getError: state => state.error
}

// Actions
const actions = {
  async fetchWordCloud({ commit }, params = {}) {
    commit('SET_LOADING', true)
    try {
      // Simulation d'appel API (à remplacer par un appel réel)
      await new Promise(resolve => setTimeout(resolve, 500))
      const wordCloud = [
        { text: 'journal', count: 25, frequency: 0.05, evolution: 10 },
        { text: 'développement', count: 18, frequency: 0.036, evolution: 5 },
        { text: 'documentation', count: 15, frequency: 0.03, evolution: -2 },
        { text: 'analyse', count: 12, frequency: 0.024, evolution: 8 },
        { text: 'intégration', count: 10, frequency: 0.02, evolution: 15 }
      ]
      commit('SET_WORD_CLOUD', wordCloud)
      return wordCloud
    } catch (error) {
      commit('SET_ERROR', error.message)
      throw error
    } finally {
      commit('SET_LOADING', false)
    }
  },
  
  async fetchTopicTrends({ commit }, params = {}) {
    commit('SET_LOADING', true)
    try {
      // Simulation d'appel API (à remplacer par un appel réel)
      await new Promise(resolve => setTimeout(resolve, 500))
      const topicTrends = {
        topics: [
          { id: 0, name: 'Développement', words: ['code', 'développement', 'programmation'] },
          { id: 1, name: 'Documentation', words: ['documentation', 'notes', 'journal'] },
          { id: 2, name: 'Analyse', words: ['analyse', 'données', 'visualisation'] }
        ],
        evolution: {
          '2023-01': { 0: 0.5, 1: 0.3, 2: 0.2 },
          '2023-02': { 0: 0.4, 1: 0.4, 2: 0.2 },
          '2023-03': { 0: 0.3, 1: 0.3, 2: 0.4 }
        }
      }
      commit('SET_TOPIC_TRENDS', topicTrends)
      return topicTrends
    } catch (error) {
      commit('SET_ERROR', error.message)
      throw error
    } finally {
      commit('SET_LOADING', false)
    }
  },
  
  async fetchSentimentEvolution({ commit }, params = {}) {
    commit('SET_LOADING', true)
    try {
      // Simulation d'appel API (à remplacer par un appel réel)
      await new Promise(resolve => setTimeout(resolve, 500))
      const sentimentEvolution = {
        dates: ['2023-01-01', '2023-02-01', '2023-03-01', '2023-04-01'],
        polarity: [0.2, 0.3, 0.1, 0.4],
        subjectivity: [0.5, 0.6, 0.4, 0.7]
      }
      commit('SET_SENTIMENT_EVOLUTION', sentimentEvolution)
      return sentimentEvolution
    } catch (error) {
      commit('SET_ERROR', error.message)
      throw error
    } finally {
      commit('SET_LOADING', false)
    }
  },
  
  async runAnalysis({ commit }, analysisType) {
    commit('SET_LOADING', true)
    try {
      // Simulation d'appel API (à remplacer par un appel réel)
      await new Promise(resolve => setTimeout(resolve, 1000))
      return { success: true, message: 'Analyse terminée avec succès' }
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
  SET_WORD_CLOUD(state, wordCloud) {
    state.wordCloud = wordCloud
  },
  SET_TOPIC_TRENDS(state, topicTrends) {
    state.topicTrends = topicTrends
  },
  SET_SENTIMENT_EVOLUTION(state, sentimentEvolution) {
    state.sentimentEvolution = sentimentEvolution
  },
  SET_LOADING(state, loading) {
    state.loading = loading
  },
  SET_ERROR(state, error) {
    state.error = error
  }
}

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations
}
