import { shallowMount, createLocalVue } from '@vue/test-utils'
import Vuex from 'vuex'
import ERPNextIntegration from '@/components/integrations/ERPNextIntegration.vue'
import ERPNextService from '@/services/ERPNextService'

// Mock ERPNextService
jest.mock('@/services/ERPNextService')

const localVue = createLocalVue()
localVue.use(Vuex)

describe('ERPNextIntegration.vue', () => {
  let store
  let actions
  
  beforeEach(() => {
    // Mock store actions
    actions = {
      'notifications/showNotification': jest.fn(),
      'journal/createEntryFromERPNextTask': jest.fn()
    }
    
    // Create store
    store = new Vuex.Store({
      actions
    })
    
    // Mock ERPNextService methods
    ERPNextService.getConfig.mockResolvedValue({
      enabled: true,
      api_url: 'https://erpnext.example.com',
      api_key: 'test-key',
      api_secret: 'test-secret'
    })
    
    ERPNextService.testConnection.mockResolvedValue({
      success: true
    })
    
    ERPNextService.getProjects.mockResolvedValue([
      { id: 'project1', name: 'Project 1', status: 'Open' },
      { id: 'project2', name: 'Project 2', status: 'Completed' }
    ])
    
    ERPNextService.getTasks.mockResolvedValue([
      { id: 'task1', subject: 'Task 1', status: 'Open', priority: 'Medium' },
      { id: 'task2', subject: 'Task 2', status: 'Completed', priority: 'High' }
    ])
    
    ERPNextService.syncToJournal.mockResolvedValue({
      success: true,
      count: 5
    })
    
    ERPNextService.syncFromJournal.mockResolvedValue({
      success: true,
      count: 3
    })
  })
  
  afterEach(() => {
    jest.clearAllMocks()
  })
  
  it('loads configuration on creation', async () => {
    const wrapper = shallowMount(ERPNextIntegration, {
      store,
      localVue
    })
    
    // Wait for promises to resolve
    await wrapper.vm.$nextTick()
    
    // Assertions
    expect(ERPNextService.getConfig).toHaveBeenCalled()
    expect(wrapper.vm.config).toEqual({
      enabled: true,
      api_url: 'https://erpnext.example.com',
      api_key: 'test-key',
      api_secret: 'test-secret'
    })
    expect(ERPNextService.testConnection).toHaveBeenCalled()
  })
  
  it('toggles configuration panel', async () => {
    const wrapper = shallowMount(ERPNextIntegration, {
      store,
      localVue
    })
    
    // Initial state
    expect(wrapper.vm.showConfig).toBe(false)
    
    // Toggle config
    await wrapper.vm.toggleConfig()
    expect(wrapper.vm.showConfig).toBe(true)
    
    // Toggle again
    await wrapper.vm.toggleConfig()
    expect(wrapper.vm.showConfig).toBe(false)
  })
  
  it('saves configuration', async () => {
    const wrapper = shallowMount(ERPNextIntegration, {
      store,
      localVue
    })
    
    // Setup
    ERPNextService.updateConfig.mockResolvedValue({
      enabled: true,
      api_url: 'https://erpnext.example.com',
      api_key: 'new-key',
      api_secret: 'new-secret'
    })
    
    // Update config
    wrapper.vm.config = {
      enabled: true,
      api_url: 'https://erpnext.example.com',
      api_key: 'new-key',
      api_secret: 'new-secret'
    }
    
    // Save config
    await wrapper.vm.saveConfig()
    
    // Assertions
    expect(ERPNextService.updateConfig).toHaveBeenCalledWith({
      enabled: true,
      api_url: 'https://erpnext.example.com',
      api_key: 'new-key',
      api_secret: 'new-secret'
    })
    expect(actions['notifications/showNotification']).toHaveBeenCalledWith(
      expect.anything(),
      {
        type: 'success',
        message: 'Configuration ERPNext enregistrée'
      },
      undefined
    )
    expect(ERPNextService.testConnection).toHaveBeenCalled()
  })
  
  it('tests connection', async () => {
    const wrapper = shallowMount(ERPNextIntegration, {
      store,
      localVue
    })
    
    // Test connection
    await wrapper.vm.testConnection()
    
    // Assertions
    expect(ERPNextService.testConnection).toHaveBeenCalled()
    expect(wrapper.vm.connected).toBe(true)
    expect(actions['notifications/showNotification']).toHaveBeenCalledWith(
      expect.anything(),
      {
        type: 'success',
        message: 'Connexion ERPNext réussie'
      },
      undefined
    )
  })
  
  it('loads projects', async () => {
    const wrapper = shallowMount(ERPNextIntegration, {
      store,
      localVue
    })
    
    // Load projects
    await wrapper.vm.loadProjects()
    
    // Assertions
    expect(ERPNextService.getProjects).toHaveBeenCalled()
    expect(wrapper.vm.projects).toEqual([
      { id: 'project1', name: 'Project 1', status: 'Open' },
      { id: 'project2', name: 'Project 2', status: 'Completed' }
    ])
  })
  
  it('selects a project and loads its tasks', async () => {
    const wrapper = shallowMount(ERPNextIntegration, {
      store,
      localVue
    })
    
    // Setup
    const project = { id: 'project1', name: 'Project 1', status: 'Open' }
    
    // Select project
    await wrapper.vm.selectProject(project)
    
    // Assertions
    expect(wrapper.vm.selectedProject).toEqual(project)
    expect(ERPNextService.getTasks).toHaveBeenCalledWith(project.id)
    expect(wrapper.vm.tasks).toEqual([
      { id: 'task1', subject: 'Task 1', status: 'Open', priority: 'Medium' },
      { id: 'task2', subject: 'Task 2', status: 'Completed', priority: 'High' }
    ])
  })
  
  it('syncs ERPNext to journal', async () => {
    const wrapper = shallowMount(ERPNextIntegration, {
      store,
      localVue
    })
    
    // Sync to journal
    await wrapper.vm.syncToJournal()
    
    // Assertions
    expect(ERPNextService.syncToJournal).toHaveBeenCalled()
    expect(actions['notifications/showNotification']).toHaveBeenCalledWith(
      expect.anything(),
      {
        type: 'success',
        message: 'Synchronisation ERPNext → Journal réussie: 5 entrées créées'
      },
      undefined
    )
  })
  
  it('syncs journal to ERPNext', async () => {
    const wrapper = shallowMount(ERPNextIntegration, {
      store,
      localVue
    })
    
    // Sync from journal
    await wrapper.vm.syncFromJournal()
    
    // Assertions
    expect(ERPNextService.syncFromJournal).toHaveBeenCalled()
    expect(actions['notifications/showNotification']).toHaveBeenCalledWith(
      expect.anything(),
      {
        type: 'success',
        message: 'Synchronisation Journal → ERPNext réussie: 3 entrées synchronisées'
      },
      undefined
    )
  })
  
  it('creates a journal entry from a task', async () => {
    const wrapper = shallowMount(ERPNextIntegration, {
      store,
      localVue,
      mocks: {
        $router: {
          push: jest.fn()
        }
      }
    })
    
    // Setup
    const task = { id: 'task1', subject: 'Task 1', status: 'Open', priority: 'Medium' }
    const createdEntry = { id: 'entry1', title: 'Task 1' }
    
    actions['journal/createEntryFromERPNextTask'].mockResolvedValue(createdEntry)
    
    // Create entry
    await wrapper.vm.createJournalEntry(task)
    
    // Assertions
    expect(actions['journal/createEntryFromERPNextTask']).toHaveBeenCalledWith(
      expect.anything(),
      task,
      undefined
    )
    expect(actions['notifications/showNotification']).toHaveBeenCalledWith(
      expect.anything(),
      {
        type: 'success',
        message: 'Entrée créée: Task 1'
      },
      undefined
    )
    expect(wrapper.vm.$router.push).toHaveBeenCalledWith({
      name: 'JournalEntry',
      params: { id: 'entry1' }
    })
  })
  
  it('returns correct status class', () => {
    const wrapper = shallowMount(ERPNextIntegration, {
      store,
      localVue
    })
    
    // Assertions
    expect(wrapper.vm.getStatusClass('Open')).toBe('status-open')
    expect(wrapper.vm.getStatusClass('Working')).toBe('status-working')
    expect(wrapper.vm.getStatusClass('Pending Review')).toBe('status-pending')
    expect(wrapper.vm.getStatusClass('Completed')).toBe('status-completed')
    expect(wrapper.vm.getStatusClass('Cancelled')).toBe('status-cancelled')
    expect(wrapper.vm.getStatusClass('Unknown')).toBe('status-default')
  })
  
  it('returns correct priority class', () => {
    const wrapper = shallowMount(ERPNextIntegration, {
      store,
      localVue
    })
    
    // Assertions
    expect(wrapper.vm.getPriorityClass('Low')).toBe('priority-low')
    expect(wrapper.vm.getPriorityClass('Medium')).toBe('priority-medium')
    expect(wrapper.vm.getPriorityClass('High')).toBe('priority-high')
    expect(wrapper.vm.getPriorityClass('Urgent')).toBe('priority-urgent')
    expect(wrapper.vm.getPriorityClass('Unknown')).toBe('priority-default')
  })
  
  it('formats date correctly', () => {
    const wrapper = shallowMount(ERPNextIntegration, {
      store,
      localVue
    })
    
    // Mock Date.prototype.toLocaleDateString
    const originalToLocaleDateString = Date.prototype.toLocaleDateString
    Date.prototype.toLocaleDateString = jest.fn(() => '01/01/2023')
    
    // Assertions
    expect(wrapper.vm.formatDate('2023-01-01')).toBe('01/01/2023')
    expect(wrapper.vm.formatDate('')).toBe('')
    
    // Restore original method
    Date.prototype.toLocaleDateString = originalToLocaleDateString
  })
})
