<template>
  <div class="journal-create-page">
    <div class="page-header">
      <div class="header-actions">
        <button @click="goBack" class="back-button">
          <i class="fas fa-arrow-left"></i>
          Retour
        </button>
        
        <div class="action-buttons">
          <button @click="saveAsDraft" class="draft-button" :disabled="saving">
            <i class="fas fa-save"></i>
            Brouillon
          </button>
          <button @click="saveEntry" class="save-button" :disabled="saving || !isValid">
            <i class="fas fa-check"></i>
            Enregistrer
          </button>
        </div>
      </div>
      
      <h1>Nouvelle entrée</h1>
    </div>
    
    <div class="entry-form">
      <div class="form-group">
        <label for="title">Titre</label>
        <input 
          type="text" 
          id="title" 
          v-model="entry.title" 
          placeholder="Titre de l'entrée"
          class="form-control"
          :class="{ 'error': submitted && !entry.title }"
        >
        <div v-if="submitted && !entry.title" class="error-message">
          Le titre est requis
        </div>
      </div>
      
      <div class="form-row">
        <div class="form-group">
          <label for="date">Date</label>
          <input 
            type="date" 
            id="date" 
            v-model="entry.date" 
            class="form-control"
          >
        </div>
        
        <div class="form-group">
          <label for="time">Heure</label>
          <input 
            type="time" 
            id="time" 
            v-model="entry.time" 
            class="form-control"
          >
        </div>
      </div>
      
      <div class="form-group">
        <label for="tags">Tags</label>
        <div class="tags-input">
          <div class="selected-tags">
            <div 
              v-for="(tag, index) in entry.tags" 
              :key="index"
              class="tag-badge"
            >
              {{ tag }}
              <button @click="removeTag(index)" class="remove-tag">
                <i class="fas fa-times"></i>
              </button>
            </div>
          </div>
          
          <input 
            type="text" 
            id="tags" 
            v-model="tagInput" 
            placeholder="Ajouter un tag (Entrée pour valider)"
            class="tag-control"
            @keydown.enter.prevent="addTag"
            @keydown.tab.prevent="addTag"
            @keydown.comma.prevent="addTag"
          >
        </div>
        
        <div class="suggested-tags">
          <span>Suggestions:</span>
          <button 
            v-for="tag in suggestedTags" 
            :key="tag.name"
            class="suggested-tag"
            @click="addSuggestedTag(tag.name)"
          >
            {{ tag.name }}
          </button>
        </div>
      </div>
      
      <div class="form-group">
        <label for="related">Entrées liées</label>
        <div class="related-input">
          <div class="selected-related">
            <div 
              v-for="(related, index) in entry.related" 
              :key="index"
              class="related-badge"
            >
              {{ getRelatedTitle(related) }}
              <button @click="removeRelated(index)" class="remove-related">
                <i class="fas fa-times"></i>
              </button>
            </div>
          </div>
          
          <div class="related-search">
            <input 
              type="text" 
              id="related" 
              v-model="relatedSearch" 
              placeholder="Rechercher une entrée"
              class="related-control"
              @input="searchRelatedEntries"
              @focus="showRelatedResults = true"
            >
            
            <div v-if="showRelatedResults && relatedResults.length > 0" class="related-results">
              <div 
                v-for="result in relatedResults" 
                :key="result.file"
                class="related-result"
                @click="addRelatedEntry(result)"
              >
                <div class="result-title">{{ result.title }}</div>
                <div class="result-date">{{ formatDate(result.date) }}</div>
              </div>
            </div>
          </div>
        </div>
      </div>
      
      <div class="form-group">
        <label for="content">Contenu</label>
        <div class="editor-container">
          <div class="editor-toolbar">
            <button @click="insertSection('Actions réalisées')" class="toolbar-button">
              <i class="fas fa-tasks"></i>
              Actions
            </button>
            <button @click="insertSection('Résolution des erreurs, déductions tirées')" class="toolbar-button">
              <i class="fas fa-bug"></i>
              Erreurs
            </button>
            <button @click="insertSection('Optimisations identifiées')" class="toolbar-button">
              <i class="fas fa-bolt"></i>
              Optimisations
            </button>
            <button @click="insertSection('Enseignements techniques')" class="toolbar-button">
              <i class="fas fa-graduation-cap"></i>
              Enseignements
            </button>
            <button @click="insertSection('Impact sur le projet musical')" class="toolbar-button">
              <i class="fas fa-music"></i>
              Musique
            </button>
            <button @click="insertSection('Références et ressources')" class="toolbar-button">
              <i class="fas fa-link"></i>
              Références
            </button>
          </div>
          
          <textarea 
            id="content" 
            v-model="entry.content" 
            placeholder="Contenu de l'entrée (Markdown supporté)"
            class="content-editor"
            :class="{ 'error': submitted && !entry.content }"
            rows="15"
          ></textarea>
          
          <div v-if="submitted && !entry.content" class="error-message">
            Le contenu est requis
          </div>
        </div>
      </div>
      
      <div class="form-actions">
        <button @click="goBack" class="cancel-button">
          Annuler
        </button>
        <button @click="saveAsDraft" class="draft-button" :disabled="saving">
          <i class="fas fa-save"></i>
          Enregistrer comme brouillon
        </button>
        <button @click="saveEntry" class="save-button" :disabled="saving || !isValid">
          <i class="fas fa-check"></i>
          Enregistrer
        </button>
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters, mapActions } from 'vuex';

export default {
  name: 'JournalCreate',
  data() {
    return {
      entry: {
        title: '',
        date: this.getCurrentDate(),
        time: this.getCurrentTime(),
        tags: [],
        related: [],
        content: this.getDefaultContent()
      },
      tagInput: '',
      relatedSearch: '',
      relatedResults: [],
      showRelatedResults: false,
      submitted: false,
      saving: false
    };
  },
  computed: {
    ...mapGetters({
      allTags: 'journal/allTags',
      recentEntries: 'journal/recentEntries'
    }),
    
    isValid() {
      return this.entry.title && this.entry.content;
    },
    
    suggestedTags() {
      // Filtrer les tags les plus fréquents qui ne sont pas déjà sélectionnés
      return this.allTags
        .filter(tag => !this.entry.tags.includes(tag.name))
        .sort((a, b) => b.count - a.count)
        .slice(0, 5);
    }
  },
  mounted() {
    this.fetchData();
  },
  methods: {
    ...mapActions({
      fetchTags: 'journal/fetchTags',
      fetchEntries: 'journal/fetchEntries',
      createEntry: 'journal/createEntry'
    }),
    
    async fetchData() {
      try {
        // Charger les tags et les entrées récentes
        if (this.allTags.length === 0) {
          await this.fetchTags();
        }
        
        if (this.recentEntries.length === 0) {
          await this.fetchEntries({ limit: 10 });
        }
      } catch (error) {
        console.error('Error fetching data:', error);
      }
    },
    
    getCurrentDate() {
      const now = new Date();
      return now.toISOString().split('T')[0];
    },
    
    getCurrentTime() {
      const now = new Date();
      return `${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;
    },
    
    getDefaultContent() {
      return `# Titre

## Actions réalisées
- 

## Résolution des erreurs, déductions tirées
- 

## Optimisations identifiées
- Pour le système: 
- Pour le code: 
- Pour la gestion des erreurs: 
- Pour les workflows: 

## Enseignements techniques
- 

## Impact sur le projet musical
- 

## Références et ressources
- 
`;
    },
    
    formatDate(dateString) {
      if (!dateString) return '';
      const date = new Date(dateString);
      return date.toLocaleDateString('fr-FR', {
        year: 'numeric',
        month: 'long',
        day: 'numeric'
      });
    },
    
    goBack() {
      this.$router.go(-1);
    },
    
    addTag() {
      if (this.tagInput.trim()) {
        const newTag = this.tagInput.trim();
        if (!this.entry.tags.includes(newTag)) {
          this.entry.tags.push(newTag);
        }
        this.tagInput = '';
      }
    },
    
    removeTag(index) {
      this.entry.tags.splice(index, 1);
    },
    
    addSuggestedTag(tag) {
      if (!this.entry.tags.includes(tag)) {
        this.entry.tags.push(tag);
      }
    },
    
    searchRelatedEntries() {
      if (!this.relatedSearch.trim()) {
        this.relatedResults = [];
        return;
      }
      
      // Rechercher parmi les entrées récentes
      const search = this.relatedSearch.toLowerCase();
      this.relatedResults = this.recentEntries.filter(entry => 
        entry.title.toLowerCase().includes(search) &&
        !this.entry.related.includes(entry.file)
      ).slice(0, 5);
    },
    
    addRelatedEntry(entry) {
      if (!this.entry.related.includes(entry.file)) {
        this.entry.related.push(entry.file);
      }
      this.relatedSearch = '';
      this.relatedResults = [];
      this.showRelatedResults = false;
    },
    
    removeRelated(index) {
      this.entry.related.splice(index, 1);
    },
    
    getRelatedTitle(file) {
      const entry = this.recentEntries.find(e => e.file === file);
      return entry ? entry.title : file;
    },
    
    insertSection(sectionTitle) {
      const section = `\n\n## ${sectionTitle}\n- `;
      this.entry.content += section;
    },
    
    async saveAsDraft() {
      // Dans une implémentation réelle, cette fonction sauvegarderait l'entrée comme brouillon
      this.saving = true;
      
      try {
        // Simuler un délai
        await new Promise(resolve => setTimeout(resolve, 1000));
        
        alert('Brouillon sauvegardé');
        this.saving = false;
      } catch (error) {
        console.error('Error saving draft:', error);
        this.saving = false;
      }
    },
    
    async saveEntry() {
      this.submitted = true;
      
      if (!this.isValid) {
        return;
      }
      
      this.saving = true;
      
      try {
        // Dans une implémentation réelle, cette fonction appellerait l'API
        await this.createEntry(this.entry);
        
        // Rediriger vers la liste des entrées
        this.$router.push({ name: 'journal' });
      } catch (error) {
        console.error('Error saving entry:', error);
        alert('Erreur lors de l\'enregistrement de l\'entrée');
      } finally {
        this.saving = false;
      }
    }
  }
};
</script>

<style scoped>
.journal-create-page {
  @apply max-w-4xl mx-auto;
}

.page-header {
  @apply mb-6;
}

.header-actions {
  @apply flex justify-between items-center mb-4;
}

.back-button {
  @apply flex items-center px-3 py-1 text-sm text-gray-600 hover:text-gray-800 focus:outline-none;
}

.back-button i {
  @apply mr-1;
}

.action-buttons {
  @apply flex items-center;
}

.draft-button, .save-button {
  @apply flex items-center px-3 py-1 ml-2 text-sm rounded-lg focus:outline-none disabled:opacity-50 disabled:cursor-not-allowed;
}

.draft-button {
  @apply bg-white border border-gray-300 text-gray-700 hover:bg-gray-50;
}

.save-button {
  @apply bg-blue-500 text-white hover:bg-blue-600;
}

.draft-button i, .save-button i {
  @apply mr-1;
}

.page-header h1 {
  @apply text-2xl font-bold text-gray-800;
}

.entry-form {
  @apply bg-white border border-gray-200 rounded-lg p-6;
}

.form-group {
  @apply mb-4;
}

.form-row {
  @apply grid grid-cols-2 gap-4 mb-4;
}

.form-group label {
  @apply block text-sm font-medium text-gray-700 mb-1;
}

.form-control {
  @apply w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent;
}

.form-control.error {
  @apply border-red-500;
}

.error-message {
  @apply text-sm text-red-500 mt-1;
}

/* Tags input */
.tags-input {
  @apply border border-gray-300 rounded-lg p-2 bg-white;
}

.selected-tags {
  @apply flex flex-wrap mb-2;
}

.tag-badge {
  @apply flex items-center px-2 py-1 text-xs bg-blue-100 text-blue-800 rounded-full mr-2 mb-1;
}

.remove-tag {
  @apply ml-1 text-blue-500 hover:text-blue-700 focus:outline-none;
}

.tag-control {
  @apply w-full px-2 py-1 border-none focus:outline-none;
}

.suggested-tags {
  @apply mt-2 text-sm text-gray-500;
}

.suggested-tag {
  @apply px-2 py-1 text-xs bg-gray-100 text-gray-800 rounded-full mr-1 hover:bg-gray-200 focus:outline-none;
}

/* Related entries input */
.related-input {
  @apply border border-gray-300 rounded-lg p-2 bg-white;
}

.selected-related {
  @apply flex flex-wrap mb-2;
}

.related-badge {
  @apply flex items-center px-2 py-1 text-xs bg-green-100 text-green-800 rounded-full mr-2 mb-1;
}

.remove-related {
  @apply ml-1 text-green-500 hover:text-green-700 focus:outline-none;
}

.related-search {
  @apply relative;
}

.related-control {
  @apply w-full px-2 py-1 border-none focus:outline-none;
}

.related-results {
  @apply absolute left-0 right-0 mt-1 bg-white border border-gray-200 rounded-lg shadow-lg z-10 max-h-60 overflow-y-auto;
}

.related-result {
  @apply p-2 hover:bg-gray-50 cursor-pointer;
}

.result-title {
  @apply text-sm font-medium text-gray-800;
}

.result-date {
  @apply text-xs text-gray-500;
}

/* Content editor */
.editor-container {
  @apply border border-gray-300 rounded-lg overflow-hidden;
}

.editor-toolbar {
  @apply flex flex-wrap items-center p-2 bg-gray-50 border-b border-gray-300;
}

.toolbar-button {
  @apply flex items-center px-3 py-1 text-sm text-gray-700 hover:bg-gray-100 rounded-lg mr-2 mb-1 focus:outline-none;
}

.toolbar-button i {
  @apply mr-1;
}

.content-editor {
  @apply w-full px-3 py-2 focus:outline-none resize-none;
}

.content-editor.error {
  @apply border-red-500;
}

/* Form actions */
.form-actions {
  @apply flex justify-end mt-6;
}

.cancel-button {
  @apply px-4 py-2 text-sm text-gray-700 hover:text-gray-900 focus:outline-none;
}
</style>
