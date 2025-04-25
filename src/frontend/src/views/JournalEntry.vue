<template>
  <div class="journal-entry-page">
    <div v-if="loading" class="loading-state">
      <i class="fas fa-spinner fa-spin"></i>
      <p>Chargement de l'entrée...</p>
    </div>
    
    <div v-else-if="error" class="error-state">
      <i class="fas fa-exclamation-triangle"></i>
      <p>{{ error }}</p>
      <button @click="goBack" class="back-button">
        Retour
      </button>
    </div>
    
    <template v-else>
      <div class="entry-header">
        <div class="header-actions">
          <button @click="goBack" class="back-button">
            <i class="fas fa-arrow-left"></i>
            Retour
          </button>
          
          <div class="action-buttons">
            <button @click="editEntry" class="edit-button">
              <i class="fas fa-edit"></i>
              Modifier
            </button>
            <button @click="showExportOptions = !showExportOptions" class="export-button">
              <i class="fas fa-file-export"></i>
              Exporter
            </button>
            <div v-if="showExportOptions" class="export-options">
              <button @click="exportToNotion">
                <i class="fab fa-notion"></i>
                Notion
              </button>
              <button @click="exportToJira">
                <i class="fab fa-jira"></i>
                Jira
              </button>
              <button @click="exportToPDF">
                <i class="fas fa-file-pdf"></i>
                PDF
              </button>
            </div>
          </div>
        </div>
        
        <h1>{{ entry.title }}</h1>
        
        <div class="entry-meta">
          <div class="meta-item">
            <i class="fas fa-calendar"></i>
            <span>{{ formatDate(entry.date) }}</span>
          </div>
          <div class="meta-item">
            <i class="fas fa-clock"></i>
            <span>{{ entry.time }}</span>
          </div>
        </div>
        
        <div class="entry-tags">
          <span 
            v-for="tag in entry.tags" 
            :key="tag"
            class="tag-badge"
            @click="searchByTag(tag)"
          >
            {{ tag }}
          </span>
        </div>
      </div>
      
      <div class="entry-content">
        <div class="markdown-content" v-html="renderedContent"></div>
      </div>
      
      <div class="entry-footer">
        <div class="related-entries" v-if="entry.related && entry.related.length > 0">
          <h3>Entrées liées</h3>
          <div class="related-list">
            <div 
              v-for="relatedEntry in relatedEntries" 
              :key="relatedEntry.file"
              class="related-item"
              @click="viewEntry(relatedEntry.file)"
            >
              <div class="related-title">{{ relatedEntry.title }}</div>
              <div class="related-date">{{ formatDate(relatedEntry.date) }}</div>
            </div>
          </div>
        </div>
        
        <div class="external-links">
          <h3>Liens externes</h3>
          <div class="links-list">
            <div v-if="entry.githubCommits && entry.githubCommits.length > 0" class="links-section">
              <h4>GitHub</h4>
              <div 
                v-for="commit in entry.githubCommits" 
                :key="commit"
                class="link-item github"
                @click="openGitHubCommit(commit)"
              >
                <i class="fab fa-github"></i>
                <span>{{ commit.substring(0, 7) }}</span>
              </div>
            </div>
            
            <div v-if="entry.jiraIssues && entry.jiraIssues.length > 0" class="links-section">
              <h4>Jira</h4>
              <div 
                v-for="issue in entry.jiraIssues" 
                :key="issue"
                class="link-item jira"
                @click="openJiraIssue(issue)"
              >
                <i class="fab fa-jira"></i>
                <span>{{ issue }}</span>
              </div>
            </div>
            
            <div v-if="entry.notionPages && entry.notionPages.length > 0" class="links-section">
              <h4>Notion</h4>
              <div 
                v-for="page in entry.notionPages" 
                :key="page.id"
                class="link-item notion"
                @click="openNotionPage(page.id)"
              >
                <i class="fab fa-notion"></i>
                <span>{{ page.title }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>

<script>
import { mapGetters, mapActions } from 'vuex';
import marked from 'marked';
import DOMPurify from 'dompurify';

export default {
  name: 'JournalEntry',
  props: {
    id: {
      type: String,
      required: true
    }
  },
  data() {
    return {
      entry: {
        file: '',
        title: '',
        date: '',
        time: '',
        tags: [],
        related: [],
        content: '',
        githubCommits: [],
        jiraIssues: [],
        notionPages: []
      },
      relatedEntries: [],
      showExportOptions: false
    };
  },
  computed: {
    ...mapGetters({
      loading: 'journal/loading',
      error: 'journal/error'
    }),
    
    renderedContent() {
      if (!this.entry.content) return '';
      
      // Convertir le Markdown en HTML
      const rawHtml = marked(this.entry.content);
      
      // Nettoyer le HTML pour éviter les attaques XSS
      const cleanHtml = DOMPurify.sanitize(rawHtml);
      
      return cleanHtml;
    }
  },
  mounted() {
    this.fetchEntry();
  },
  methods: {
    ...mapActions({
      fetchEntryAction: 'journal/fetchEntry',
      searchEntriesByTag: 'journal/searchByTag'
    }),
    
    async fetchEntry() {
      try {
        const filename = `${this.id}.md`;
        const entry = await this.fetchEntryAction(filename);
        
        if (entry) {
          this.entry = entry;
          
          // Récupérer les entrées liées
          if (this.entry.related && this.entry.related.length > 0) {
            this.fetchRelatedEntries();
          }
        }
      } catch (error) {
        console.error('Error fetching entry:', error);
      }
    },
    
    async fetchRelatedEntries() {
      try {
        // Dans une implémentation réelle, ces données viendraient de l'API
        // Pour l'instant, nous utilisons des données fictives
        this.relatedEntries = this.entry.related.map(file => ({
          file,
          title: file.replace('.md', '').split('-').slice(3).join(' '),
          date: file.substring(0, 10)
        }));
      } catch (error) {
        console.error('Error fetching related entries:', error);
      }
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
    
    editEntry() {
      this.$router.push({ name: 'journal-edit', params: { id: this.id } });
    },
    
    viewEntry(entryFile) {
      const entryId = entryFile.replace('.md', '');
      this.$router.push({ name: 'journal-entry', params: { id: entryId } });
    },
    
    searchByTag(tag) {
      this.searchEntriesByTag(tag);
      this.$router.push({ name: 'journal', query: { tag } });
    },
    
    exportToNotion() {
      // Dans une implémentation réelle, cette fonction appellerait l'API
      alert('Export vers Notion non implémenté');
      this.showExportOptions = false;
    },
    
    exportToJira() {
      // Dans une implémentation réelle, cette fonction appellerait l'API
      alert('Export vers Jira non implémenté');
      this.showExportOptions = false;
    },
    
    exportToPDF() {
      // Dans une implémentation réelle, cette fonction appellerait l'API
      alert('Export vers PDF non implémenté');
      this.showExportOptions = false;
    },
    
    openGitHubCommit(commit) {
      // Dans une implémentation réelle, cette fonction ouvrirait le commit dans GitHub
      window.open(`https://github.com/user/repo/commit/${commit}`, '_blank');
    },
    
    openJiraIssue(issue) {
      // Dans une implémentation réelle, cette fonction ouvrirait l'issue dans Jira
      window.open(`https://jira.example.com/browse/${issue}`, '_blank');
    },
    
    openNotionPage(pageId) {
      // Dans une implémentation réelle, cette fonction ouvrirait la page dans Notion
      window.open(`https://notion.so/${pageId}`, '_blank');
    }
  }
};
</script>

<style scoped>
.journal-entry-page {
  @apply max-w-4xl mx-auto;
}

.entry-header {
  @apply mb-6 pb-4 border-b border-gray-200;
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
  @apply flex items-center relative;
}

.edit-button, .export-button {
  @apply flex items-center px-3 py-1 ml-2 text-sm bg-white border border-gray-300 rounded-lg hover:bg-gray-50 focus:outline-none;
}

.edit-button i, .export-button i {
  @apply mr-1;
}

.export-options {
  @apply absolute right-0 top-full mt-1 bg-white border border-gray-200 rounded-lg shadow-lg z-10;
}

.export-options button {
  @apply flex items-center w-full px-4 py-2 text-sm text-left hover:bg-gray-50 focus:outline-none;
}

.export-options button i {
  @apply mr-2;
}

.entry-header h1 {
  @apply text-2xl font-bold text-gray-800 mb-2;
}

.entry-meta {
  @apply flex items-center mb-3;
}

.meta-item {
  @apply flex items-center text-sm text-gray-500 mr-4;
}

.meta-item i {
  @apply mr-1;
}

.entry-tags {
  @apply flex flex-wrap;
}

.tag-badge {
  @apply px-2 py-1 text-xs bg-blue-100 text-blue-800 rounded-full mr-2 mb-2 cursor-pointer hover:bg-blue-200;
}

.entry-content {
  @apply mb-8;
}

.markdown-content {
  @apply prose prose-blue max-w-none;
}

.entry-footer {
  @apply grid gap-6 mt-8 pt-6 border-t border-gray-200;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
}

.related-entries, .external-links {
  @apply bg-gray-50 border border-gray-200 rounded-lg p-4;
}

.related-entries h3, .external-links h3 {
  @apply text-lg font-semibold text-gray-800 mb-3;
}

.related-list {
  @apply space-y-2;
}

.related-item {
  @apply p-2 bg-white border border-gray-100 rounded-lg cursor-pointer hover:bg-gray-50;
}

.related-title {
  @apply text-sm font-medium text-gray-800;
}

.related-date {
  @apply text-xs text-gray-500;
}

.links-list {
  @apply space-y-4;
}

.links-section h4 {
  @apply text-sm font-medium text-gray-700 mb-2;
}

.link-item {
  @apply flex items-center p-2 bg-white border border-gray-100 rounded-lg cursor-pointer hover:bg-gray-50 mb-2;
}

.link-item i {
  @apply mr-2;
}

.link-item.github i {
  @apply text-gray-800;
}

.link-item.jira i {
  @apply text-blue-500;
}

.link-item.notion i {
  @apply text-gray-900;
}

.loading-state, .error-state {
  @apply flex flex-col items-center justify-center h-64 text-gray-500;
}

.loading-state i, .error-state i {
  @apply text-3xl mb-2;
}

.error-state i {
  @apply text-red-500;
}

.error-state .back-button {
  @apply mt-4 px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 focus:outline-none;
}
</style>
