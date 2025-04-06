<template>
  <div class="erpnext-integration">
    <div class="card">
      <div class="card-header">
        <h3 class="card-title">Intégration ERPNext</h3>
        <div class="card-actions">
          <button 
            class="btn btn-sm btn-primary" 
            @click="toggleConfig"
          >
            <i class="fas fa-cog mr-1"></i>
            Configuration
          </button>
        </div>
      </div>
      
      <div class="card-body">
        <!-- Configuration -->
        <div v-if="showConfig" class="config-section mb-4">
          <h4 class="section-title">Configuration ERPNext</h4>
          
          <div class="form-group">
            <label for="api-url">URL de l'API</label>
            <input 
              id="api-url" 
              v-model="config.api_url" 
              type="text" 
              class="form-control" 
              placeholder="https://votre-instance.erpnext.com"
            />
          </div>
          
          <div class="form-group">
            <label for="api-key">Clé API</label>
            <input 
              id="api-key" 
              v-model="config.api_key" 
              type="text" 
              class="form-control" 
              placeholder="Clé API"
            />
          </div>
          
          <div class="form-group">
            <label for="api-secret">Secret API</label>
            <input 
              id="api-secret" 
              v-model="config.api_secret" 
              type="password" 
              class="form-control" 
              placeholder="Secret API"
            />
          </div>
          
          <div class="form-check mb-3">
            <input 
              id="enabled" 
              v-model="config.enabled" 
              type="checkbox" 
              class="form-check-input"
            />
            <label for="enabled" class="form-check-label">Activer l'intégration</label>
          </div>
          
          <div class="config-actions">
            <button 
              class="btn btn-primary mr-2" 
              @click="saveConfig"
              :disabled="saving"
            >
              <i v-if="saving" class="fas fa-spinner fa-spin mr-1"></i>
              <i v-else class="fas fa-save mr-1"></i>
              Enregistrer
            </button>
            
            <button 
              class="btn btn-secondary" 
              @click="testConnection"
              :disabled="testing || !config.api_url || !config.api_key || !config.api_secret"
            >
              <i v-if="testing" class="fas fa-spinner fa-spin mr-1"></i>
              <i v-else class="fas fa-plug mr-1"></i>
              Tester la connexion
            </button>
          </div>
        </div>
        
        <!-- Statut de l'intégration -->
        <div class="status-section mb-4">
          <div class="status-indicator">
            <div 
              class="status-dot" 
              :class="{ 
                'status-active': config.enabled && connected, 
                'status-inactive': !config.enabled,
                'status-error': config.enabled && !connected
              }"
            ></div>
            <div class="status-text">
              <span v-if="config.enabled && connected">Intégration active</span>
              <span v-else-if="config.enabled && !connected">Erreur de connexion</span>
              <span v-else>Intégration inactive</span>
            </div>
          </div>
          
          <div class="status-details" v-if="config.enabled">
            <div class="detail-item">
              <span class="detail-label">URL:</span>
              <span class="detail-value">{{ config.api_url }}</span>
            </div>
          </div>
        </div>
        
        <!-- Actions de synchronisation -->
        <div class="sync-section mb-4">
          <h4 class="section-title">Synchronisation</h4>
          
          <div class="sync-actions">
            <button 
              class="btn btn-primary mr-2" 
              @click="syncToJournal"
              :disabled="syncingToJournal || !config.enabled || !connected"
            >
              <i v-if="syncingToJournal" class="fas fa-spinner fa-spin mr-1"></i>
              <i v-else class="fas fa-download mr-1"></i>
              Synchroniser ERPNext → Journal
            </button>
            
            <button 
              class="btn btn-primary" 
              @click="syncFromJournal"
              :disabled="syncingFromJournal || !config.enabled || !connected"
            >
              <i v-if="syncingFromJournal" class="fas fa-spinner fa-spin mr-1"></i>
              <i v-else class="fas fa-upload mr-1"></i>
              Synchroniser Journal → ERPNext
            </button>
          </div>
        </div>
        
        <!-- Projets et tâches -->
        <div class="projects-section mb-4">
          <h4 class="section-title">
            Projets et tâches
            <button 
              class="btn btn-sm btn-outline-secondary ml-2" 
              @click="loadProjects"
              :disabled="loadingProjects || !config.enabled || !connected"
            >
              <i v-if="loadingProjects" class="fas fa-spinner fa-spin"></i>
              <i v-else class="fas fa-sync"></i>
            </button>
          </h4>
          
          <div v-if="loadingProjects" class="loading-indicator">
            <i class="fas fa-spinner fa-spin mr-1"></i>
            Chargement des projets...
          </div>
          
          <div v-else-if="!config.enabled || !connected" class="empty-state">
            <i class="fas fa-plug"></i>
            <p>Configurez et activez l'intégration pour accéder aux projets</p>
          </div>
          
          <div v-else-if="projects.length === 0" class="empty-state">
            <i class="fas fa-folder-open"></i>
            <p>Aucun projet trouvé</p>
          </div>
          
          <div v-else class="projects-list">
            <div 
              v-for="project in projects" 
              :key="project.id"
              class="project-item"
              :class="{ 'active': selectedProject && selectedProject.id === project.id }"
              @click="selectProject(project)"
            >
              <div class="project-header">
                <div class="project-name">{{ project.name }}</div>
                <div class="project-status" :class="getStatusClass(project.status)">
                  {{ project.status }}
                </div>
              </div>
              <div class="project-description">{{ project.description || 'Aucune description' }}</div>
            </div>
          </div>
          
          <div v-if="selectedProject" class="tasks-section mt-4">
            <h5 class="section-title">
              Tâches du projet: {{ selectedProject.name }}
              <button 
                class="btn btn-sm btn-outline-secondary ml-2" 
                @click="loadTasks(selectedProject.id)"
                :disabled="loadingTasks"
              >
                <i v-if="loadingTasks" class="fas fa-spinner fa-spin"></i>
                <i v-else class="fas fa-sync"></i>
              </button>
            </h5>
            
            <div v-if="loadingTasks" class="loading-indicator">
              <i class="fas fa-spinner fa-spin mr-1"></i>
              Chargement des tâches...
            </div>
            
            <div v-else-if="tasks.length === 0" class="empty-state">
              <i class="fas fa-tasks"></i>
              <p>Aucune tâche trouvée pour ce projet</p>
            </div>
            
            <div v-else class="tasks-list">
              <div 
                v-for="task in tasks" 
                :key="task.id"
                class="task-item"
              >
                <div class="task-header">
                  <div class="task-name">{{ task.subject }}</div>
                  <div class="task-status" :class="getStatusClass(task.status)">
                    {{ task.status }}
                  </div>
                </div>
                <div class="task-details">
                  <div class="task-priority" :class="getPriorityClass(task.priority)">
                    {{ task.priority }}
                  </div>
                  <div class="task-dates">
                    <span v-if="task.exp_start_date">{{ formatDate(task.exp_start_date) }}</span>
                    <span v-if="task.exp_start_date && task.exp_end_date">-</span>
                    <span v-if="task.exp_end_date">{{ formatDate(task.exp_end_date) }}</span>
                  </div>
                </div>
                <div class="task-description">{{ task.description || 'Aucune description' }}</div>
                <div class="task-actions">
                  <button 
                    class="btn btn-sm btn-outline-primary"
                    @click="createJournalEntry(task)"
                    :disabled="creatingEntry"
                  >
                    <i v-if="creatingEntry === task.id" class="fas fa-spinner fa-spin mr-1"></i>
                    <i v-else class="fas fa-file-alt mr-1"></i>
                    Créer une entrée
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { mapActions } from 'vuex'
import ERPNextService from '@/services/ERPNextService'

export default {
  name: 'ERPNextIntegration',
  data() {
    return {
      showConfig: false,
      config: {
        enabled: false,
        api_url: '',
        api_key: '',
        api_secret: ''
      },
      connected: false,
      saving: false,
      testing: false,
      
      projects: [],
      selectedProject: null,
      loadingProjects: false,
      
      tasks: [],
      loadingTasks: false,
      
      syncingToJournal: false,
      syncingFromJournal: false,
      
      creatingEntry: null
    }
  },
  created() {
    this.loadConfig()
  },
  methods: {
    ...mapActions({
      showNotification: 'notifications/showNotification'
    }),
    
    toggleConfig() {
      this.showConfig = !this.showConfig
    },
    
    async loadConfig() {
      try {
        const config = await ERPNextService.getConfig()
        this.config = config
        
        if (this.config.enabled) {
          this.testConnection(false)
        }
      } catch (error) {
        console.error('Error loading ERPNext config:', error)
        this.showNotification({
          type: 'error',
          message: 'Erreur lors du chargement de la configuration ERPNext'
        })
      }
    },
    
    async saveConfig() {
      this.saving = true
      
      try {
        await ERPNextService.updateConfig(this.config)
        
        this.showNotification({
          type: 'success',
          message: 'Configuration ERPNext enregistrée'
        })
        
        if (this.config.enabled) {
          await this.testConnection()
        }
      } catch (error) {
        console.error('Error saving ERPNext config:', error)
        this.showNotification({
          type: 'error',
          message: 'Erreur lors de l\'enregistrement de la configuration ERPNext'
        })
      } finally {
        this.saving = false
      }
    },
    
    async testConnection(showNotification = true) {
      this.testing = true
      
      try {
        const result = await ERPNextService.testConnection()
        this.connected = result.success
        
        if (showNotification) {
          if (this.connected) {
            this.showNotification({
              type: 'success',
              message: 'Connexion ERPNext réussie'
            })
          } else {
            this.showNotification({
              type: 'error',
              message: 'Erreur de connexion ERPNext: ' + result.message
            })
          }
        }
      } catch (error) {
        console.error('Error testing ERPNext connection:', error)
        this.connected = false
        
        if (showNotification) {
          this.showNotification({
            type: 'error',
            message: 'Erreur lors du test de connexion ERPNext'
          })
        }
      } finally {
        this.testing = false
      }
    },
    
    async loadProjects() {
      this.loadingProjects = true
      
      try {
        this.projects = await ERPNextService.getProjects()
      } catch (error) {
        console.error('Error loading ERPNext projects:', error)
        this.showNotification({
          type: 'error',
          message: 'Erreur lors du chargement des projets ERPNext'
        })
      } finally {
        this.loadingProjects = false
      }
    },
    
    selectProject(project) {
      this.selectedProject = project
      this.loadTasks(project.id)
    },
    
    async loadTasks(projectId) {
      this.loadingTasks = true
      
      try {
        this.tasks = await ERPNextService.getTasks(projectId)
      } catch (error) {
        console.error('Error loading ERPNext tasks:', error)
        this.showNotification({
          type: 'error',
          message: 'Erreur lors du chargement des tâches ERPNext'
        })
      } finally {
        this.loadingTasks = false
      }
    },
    
    async syncToJournal() {
      this.syncingToJournal = true
      
      try {
        const result = await ERPNextService.syncToJournal()
        
        this.showNotification({
          type: 'success',
          message: `Synchronisation ERPNext → Journal réussie: ${result.count} entrées créées`
        })
      } catch (error) {
        console.error('Error syncing ERPNext to journal:', error)
        this.showNotification({
          type: 'error',
          message: 'Erreur lors de la synchronisation ERPNext → Journal'
        })
      } finally {
        this.syncingToJournal = false
      }
    },
    
    async syncFromJournal() {
      this.syncingFromJournal = true
      
      try {
        const result = await ERPNextService.syncFromJournal()
        
        this.showNotification({
          type: 'success',
          message: `Synchronisation Journal → ERPNext réussie: ${result.count} entrées synchronisées`
        })
      } catch (error) {
        console.error('Error syncing journal to ERPNext:', error)
        this.showNotification({
          type: 'error',
          message: 'Erreur lors de la synchronisation Journal → ERPNext'
        })
      } finally {
        this.syncingFromJournal = false
      }
    },
    
    async createJournalEntry(task) {
      this.creatingEntry = task.id
      
      try {
        const result = await this.$store.dispatch('journal/createEntryFromERPNextTask', task)
        
        this.showNotification({
          type: 'success',
          message: `Entrée créée: ${result.title}`
        })
        
        // Rediriger vers l'entrée créée
        this.$router.push({ name: 'JournalEntry', params: { id: result.id } })
      } catch (error) {
        console.error('Error creating journal entry from ERPNext task:', error)
        this.showNotification({
          type: 'error',
          message: 'Erreur lors de la création de l\'entrée de journal'
        })
      } finally {
        this.creatingEntry = null
      }
    },
    
    getStatusClass(status) {
      switch (status) {
        case 'Open':
          return 'status-open'
        case 'Working':
          return 'status-working'
        case 'Pending Review':
          return 'status-pending'
        case 'Completed':
          return 'status-completed'
        case 'Cancelled':
          return 'status-cancelled'
        default:
          return 'status-default'
      }
    },
    
    getPriorityClass(priority) {
      switch (priority) {
        case 'Low':
          return 'priority-low'
        case 'Medium':
          return 'priority-medium'
        case 'High':
          return 'priority-high'
        case 'Urgent':
          return 'priority-urgent'
        default:
          return 'priority-default'
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
.erpnext-integration {
  @apply w-full;
}

.card {
  @apply bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden;
}

.card-header {
  @apply flex justify-between items-center p-4 border-b border-gray-200;
}

.card-title {
  @apply text-lg font-semibold text-gray-800;
}

.card-body {
  @apply p-4;
}

.section-title {
  @apply text-base font-medium text-gray-700 mb-3;
}

.form-group {
  @apply mb-3;
}

.form-group label {
  @apply block text-sm font-medium text-gray-700 mb-1;
}

.form-control {
  @apply block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 sm:text-sm;
}

.form-check {
  @apply flex items-center;
}

.form-check-input {
  @apply h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded;
}

.form-check-label {
  @apply ml-2 block text-sm text-gray-700;
}

.config-actions {
  @apply flex mt-4;
}

.btn {
  @apply inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-offset-2;
}

.btn-primary {
  @apply text-white bg-blue-600 hover:bg-blue-700 focus:ring-blue-500;
}

.btn-secondary {
  @apply text-gray-700 bg-white border-gray-300 hover:bg-gray-50 focus:ring-blue-500;
}

.btn-sm {
  @apply px-2 py-1 text-xs;
}

.btn-outline-secondary {
  @apply text-gray-700 bg-white border-gray-300 hover:bg-gray-50 focus:ring-gray-500;
}

.btn-outline-primary {
  @apply text-blue-700 bg-white border-blue-300 hover:bg-blue-50 focus:ring-blue-500;
}

.status-section {
  @apply p-4 bg-gray-50 rounded-lg;
}

.status-indicator {
  @apply flex items-center;
}

.status-dot {
  @apply w-3 h-3 rounded-full mr-2;
}

.status-active {
  @apply bg-green-500;
}

.status-inactive {
  @apply bg-gray-400;
}

.status-error {
  @apply bg-red-500;
}

.status-text {
  @apply text-sm font-medium;
}

.status-details {
  @apply mt-2 text-sm text-gray-600;
}

.detail-item {
  @apply flex items-center;
}

.detail-label {
  @apply font-medium mr-1;
}

.sync-actions {
  @apply flex flex-wrap gap-2;
}

.loading-indicator {
  @apply flex items-center justify-center p-4 text-gray-500;
}

.empty-state {
  @apply flex flex-col items-center justify-center p-8 text-gray-400;
}

.empty-state i {
  @apply text-3xl mb-2;
}

.projects-list {
  @apply space-y-2 max-h-60 overflow-y-auto;
}

.project-item {
  @apply p-3 border border-gray-200 rounded-lg cursor-pointer hover:bg-gray-50;
}

.project-item.active {
  @apply border-blue-500 bg-blue-50;
}

.project-header {
  @apply flex justify-between items-center mb-1;
}

.project-name {
  @apply font-medium;
}

.project-status {
  @apply text-xs px-2 py-0.5 rounded-full;
}

.project-description {
  @apply text-sm text-gray-600 truncate;
}

.tasks-list {
  @apply space-y-2 max-h-80 overflow-y-auto;
}

.task-item {
  @apply p-3 border border-gray-200 rounded-lg;
}

.task-header {
  @apply flex justify-between items-center mb-1;
}

.task-name {
  @apply font-medium;
}

.task-status {
  @apply text-xs px-2 py-0.5 rounded-full;
}

.task-details {
  @apply flex justify-between items-center mb-2 text-xs text-gray-500;
}

.task-priority {
  @apply px-2 py-0.5 rounded-full;
}

.task-description {
  @apply text-sm text-gray-600 mb-2;
}

.task-actions {
  @apply flex justify-end;
}

/* Status classes */
.status-open {
  @apply bg-blue-100 text-blue-800;
}

.status-working {
  @apply bg-yellow-100 text-yellow-800;
}

.status-pending {
  @apply bg-purple-100 text-purple-800;
}

.status-completed {
  @apply bg-green-100 text-green-800;
}

.status-cancelled {
  @apply bg-red-100 text-red-800;
}

.status-default {
  @apply bg-gray-100 text-gray-800;
}

/* Priority classes */
.priority-low {
  @apply bg-green-100 text-green-800;
}

.priority-medium {
  @apply bg-blue-100 text-blue-800;
}

.priority-high {
  @apply bg-yellow-100 text-yellow-800;
}

.priority-urgent {
  @apply bg-red-100 text-red-800;
}

.priority-default {
  @apply bg-gray-100 text-gray-800;
}
</style>
