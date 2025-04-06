import journalService from '@/services/journalService'

const state = {
  entries: [],
  currentEntry: null,
  tags: [],
  loading: false,
  error: null,
  searchResults: []
}

const getters = {
  allEntries: state => state.entries,
  currentEntry: state => state.currentEntry,
  allTags: state => state.tags,
  isLoading: state => state.loading,
  error: state => state.error,
  searchResults: state => state.searchResults
}

const mutations = {
  SET_ENTRIES(state, entries) {
    state.entries = entries
  },
  SET_CURRENT_ENTRY(state, entry) {
    state.currentEntry = entry
  },
  ADD_ENTRY(state, entry) {
    state.entries.unshift(entry)
  },
  UPDATE_ENTRY(state, updatedEntry) {
    const index = state.entries.findIndex(entry => entry.file === updatedEntry.file)
    if (index !== -1) {
      state.entries.splice(index, 1, updatedEntry)
    }
    if (state.currentEntry && state.currentEntry.file === updatedEntry.file) {
      state.currentEntry = updatedEntry
    }
  },
  SET_TAGS(state, tags) {
    state.tags = tags
  },
  SET_LOADING(state, loading) {
    state.loading = loading
  },
  SET_ERROR(state, error) {
    state.error = error
  },
  CLEAR_ERROR(state) {
    state.error = null
  },
  SET_SEARCH_RESULTS(state, results) {
    state.searchResults = results
  }
}

const actions = {
  async fetchEntries({ commit }, { limit = 20, tag = null, date = null } = {}) {
    commit('SET_LOADING', true)
    commit('CLEAR_ERROR')
    
    try {
      const response = await journalService.getEntries({ limit, tag, date })
      commit('SET_ENTRIES', response.entries)
    } catch (error) {
      commit('SET_ERROR', error.message || 'Erreur lors de la récupération des entrées')
      console.error('Error fetching entries:', error)
    } finally {
      commit('SET_LOADING', false)
    }
  },
  
  async fetchEntry({ commit }, filename) {
    commit('SET_LOADING', true)
    commit('CLEAR_ERROR')
    
    try {
      const entry = await journalService.getEntry(filename)
      commit('SET_CURRENT_ENTRY', entry)
    } catch (error) {
      commit('SET_ERROR', error.message || `Erreur lors de la récupération de l'entrée ${filename}`)
      console.error(`Error fetching entry ${filename}:`, error)
    } finally {
      commit('SET_LOADING', false)
    }
  },
  
  async createEntry({ commit }, entryData) {
    commit('SET_LOADING', true)
    commit('CLEAR_ERROR')
    
    try {
      const newEntry = await journalService.createEntry(entryData)
      commit('ADD_ENTRY', newEntry)
      return newEntry
    } catch (error) {
      commit('SET_ERROR', error.message || 'Erreur lors de la création de l\'entrée')
      console.error('Error creating entry:', error)
      throw error
    } finally {
      commit('SET_LOADING', false)
    }
  },
  
  async updateEntry({ commit }, { filename, entryData }) {
    commit('SET_LOADING', true)
    commit('CLEAR_ERROR')
    
    try {
      const updatedEntry = await journalService.updateEntry(filename, entryData)
      commit('UPDATE_ENTRY', updatedEntry)
      return updatedEntry
    } catch (error) {
      commit('SET_ERROR', error.message || `Erreur lors de la mise à jour de l'entrée ${filename}`)
      console.error(`Error updating entry ${filename}:`, error)
      throw error
    } finally {
      commit('SET_LOADING', false)
    }
  },
  
  async fetchTags({ commit }) {
    commit('SET_LOADING', true)
    commit('CLEAR_ERROR')
    
    try {
      const response = await journalService.getTags()
      commit('SET_TAGS', response.tags)
    } catch (error) {
      commit('SET_ERROR', error.message || 'Erreur lors de la récupération des tags')
      console.error('Error fetching tags:', error)
    } finally {
      commit('SET_LOADING', false)
    }
  },
  
  async searchJournal({ commit }, { query, limit = 10 }) {
    commit('SET_LOADING', true)
    commit('CLEAR_ERROR')
    
    try {
      const response = await journalService.searchJournal(query, limit)
      commit('SET_SEARCH_RESULTS', response.results)
      return response.results
    } catch (error) {
      commit('SET_ERROR', error.message || 'Erreur lors de la recherche')
      console.error('Error searching journal:', error)
      throw error
    } finally {
      commit('SET_LOADING', false)
    }
  },
  
  async queryRag({ commit }, { query, limit = 5 }) {
    commit('SET_LOADING', true)
    commit('CLEAR_ERROR')
    
    try {
      const response = await journalService.queryRag(query, limit)
      return response.results
    } catch (error) {
      commit('SET_ERROR', error.message || 'Erreur lors de l\'interrogation du RAG')
      console.error('Error querying RAG:', error)
      throw error
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
