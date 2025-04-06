import axios from 'axios'

const API_URL = process.env.VUE_APP_API_URL || 'http://localhost:8000/api'

export default {
  /**
   * Récupère la configuration ERPNext
   * @returns {Promise<Object>} - Configuration ERPNext
   */
  async getConfig() {
    try {
      const response = await axios.get(`${API_URL}/integrations/erpnext/config`)
      return response.data
    } catch (error) {
      console.error('Error fetching ERPNext config:', error)
      throw error
    }
  },
  
  /**
   * Met à jour la configuration ERPNext
   * @param {Object} config - Nouvelle configuration
   * @returns {Promise<Object>} - Configuration mise à jour
   */
  async updateConfig(config) {
    try {
      const response = await axios.post(`${API_URL}/integrations/erpnext/config`, config)
      return response.data
    } catch (error) {
      console.error('Error updating ERPNext config:', error)
      throw error
    }
  },
  
  /**
   * Teste la connexion ERPNext
   * @returns {Promise<Object>} - Résultat du test
   */
  async testConnection() {
    try {
      const response = await axios.post(`${API_URL}/integrations/erpnext/test-connection`)
      return response.data
    } catch (error) {
      console.error('Error testing ERPNext connection:', error)
      throw error
    }
  },
  
  /**
   * Récupère les projets ERPNext
   * @returns {Promise<Array>} - Liste des projets
   */
  async getProjects() {
    try {
      const response = await axios.get(`${API_URL}/integrations/erpnext/projects`)
      return response.data
    } catch (error) {
      console.error('Error fetching ERPNext projects:', error)
      throw error
    }
  },
  
  /**
   * Récupère les tâches ERPNext
   * @param {string} projectName - Nom du projet (optionnel)
   * @returns {Promise<Array>} - Liste des tâches
   */
  async getTasks(projectName = null) {
    try {
      const params = projectName ? { project: projectName } : {}
      const response = await axios.get(`${API_URL}/integrations/erpnext/tasks`, { params })
      return response.data
    } catch (error) {
      console.error('Error fetching ERPNext tasks:', error)
      throw error
    }
  },
  
  /**
   * Crée une tâche ERPNext
   * @param {Object} task - Données de la tâche
   * @returns {Promise<Object>} - Tâche créée
   */
  async createTask(task) {
    try {
      const response = await axios.post(`${API_URL}/integrations/erpnext/tasks`, task)
      return response.data
    } catch (error) {
      console.error('Error creating ERPNext task:', error)
      throw error
    }
  },
  
  /**
   * Met à jour une tâche ERPNext
   * @param {string} taskId - ID de la tâche
   * @param {Object} task - Données de la tâche
   * @returns {Promise<Object>} - Tâche mise à jour
   */
  async updateTask(taskId, task) {
    try {
      const response = await axios.put(`${API_URL}/integrations/erpnext/tasks/${taskId}`, task)
      return response.data
    } catch (error) {
      console.error('Error updating ERPNext task:', error)
      throw error
    }
  },
  
  /**
   * Synchronise les tâches ERPNext vers le journal
   * @returns {Promise<Object>} - Résultat de la synchronisation
   */
  async syncToJournal() {
    try {
      const response = await axios.post(`${API_URL}/integrations/erpnext/sync-to-journal`)
      return response.data
    } catch (error) {
      console.error('Error syncing ERPNext to journal:', error)
      throw error
    }
  },
  
  /**
   * Synchronise le journal vers ERPNext
   * @returns {Promise<Object>} - Résultat de la synchronisation
   */
  async syncFromJournal() {
    try {
      const response = await axios.post(`${API_URL}/integrations/erpnext/sync-from-journal`)
      return response.data
    } catch (error) {
      console.error('Error syncing journal to ERPNext:', error)
      throw error
    }
  },
  
  /**
   * Crée une note ERPNext à partir d'une entrée de journal
   * @param {string} filename - Nom du fichier de l'entrée
   * @returns {Promise<Object>} - Note créée
   */
  async createNoteFromEntry(filename) {
    try {
      const response = await axios.post(`${API_URL}/integrations/erpnext/create-note`, {
        filename
      })
      return response.data
    } catch (error) {
      console.error('Error creating ERPNext note from entry:', error)
      throw error
    }
  }
}
