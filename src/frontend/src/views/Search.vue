<template>
  <div class="search">
    <h1>Recherche</h1>
    <div class="search-form">
      <input 
        type="text" 
        v-model="searchQuery" 
        placeholder="Rechercher dans le journal..." 
        @keyup.enter="search"
      />
      <button @click="search">Rechercher</button>
    </div>
    
    <div v-if="loading" class="loading">
      Recherche en cours...
    </div>
    
    <div v-else-if="results.length > 0" class="results">
      <h2>Résultats ({{ results.length }})</h2>
      <div v-for="result in results" :key="result.id" class="result-item">
        <router-link :to="{ name: 'JournalEntry', params: { id: result.id } }">
          <h3>{{ result.title }}</h3>
          <p class="date">{{ formatDate(result.date) }}</p>
          <p class="excerpt" v-html="result.excerpt"></p>
        </router-link>
      </div>
    </div>
    
    <div v-else-if="searched" class="no-results">
      Aucun résultat trouvé pour "{{ searchQuery }}"
    </div>
  </div>
</template>

<script>
export default {
  name: 'Search',
  data() {
    return {
      searchQuery: '',
      results: [],
      loading: false,
      searched: false
    }
  },
  methods: {
    async search() {
      if (!this.searchQuery.trim()) return
      
      this.loading = true
      this.searched = true
      
      try {
        // Simulation de recherche (à remplacer par un appel API réel)
        await new Promise(resolve => setTimeout(resolve, 500))
        this.results = []
      } catch (error) {
        console.error('Error searching:', error)
      } finally {
        this.loading = false
      }
    },
    
    formatDate(dateString) {
      if (!dateString) return ''
      
      const date = new Date(dateString)
      return date.toLocaleDateString()
    }
  }
}
</script>

<style scoped>
.search {
  padding: 20px;
}

.search-form {
  display: flex;
  margin-bottom: 20px;
}

.search-form input {
  flex: 1;
  padding: 10px;
  border: 1px solid #ccc;
  border-radius: 4px 0 0 4px;
}

.search-form button {
  padding: 10px 20px;
  background-color: #4CAF50;
  color: white;
  border: none;
  border-radius: 0 4px 4px 0;
  cursor: pointer;
}

.loading {
  text-align: center;
  padding: 20px;
  color: #666;
}

.results {
  margin-top: 20px;
}

.result-item {
  margin-bottom: 20px;
  padding: 15px;
  border: 1px solid #eee;
  border-radius: 4px;
}

.result-item a {
  text-decoration: none;
  color: inherit;
}

.result-item h3 {
  margin-top: 0;
  color: #2c3e50;
}

.result-item .date {
  color: #666;
  font-size: 0.9em;
}

.result-item .excerpt {
  margin-top: 10px;
}

.no-results {
  text-align: center;
  padding: 20px;
  color: #666;
}
</style>
