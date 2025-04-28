import axios from 'axios'
import ERPNextService from '@/services/ERPNextService'

// Mock axios
jest.mock('axios')

describe('ERPNextService', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  describe('getConfig', () => {
    it('should fetch ERPNext configuration', async () => {
      // Mock data
      const mockConfig = {
        enabled: true,
        api_url: 'https://erpnext.example.com',
        api_key: 'test-key',
        api_secret: 'test-secret'
      }

      // Mock axios response
      axios.get.mockResolvedValue({ data: mockConfig })

      // Call the service method
      const result = await ERPNextService.getConfig()

      // Assertions
      expect(axios.get).toHaveBeenCalledWith('http://localhost:8000/api/integrations/erpnext/config')
      expect(result).toEqual(mockConfig)
    })

    it('should handle errors when fetching configuration', async () => {
      // Mock axios error
      const error = new Error('Network error')
      axios.get.mockRejectedValue(error)

      // Call the service method and expect it to throw
      await expect(ERPNextService.getConfig()).rejects.toThrow(error)

      // Assertions
      expect(axios.get).toHaveBeenCalledWith('http://localhost:8000/api/integrations/erpnext/config')
    })
  })

  describe('updateConfig', () => {
    it('should update ERPNext configuration', async () => {
      // Mock data
      const mockConfig = {
        enabled: true,
        api_url: 'https://erpnext.example.com',
        api_key: 'test-key',
        api_secret: 'test-secret'
      }

      // Mock axios response
      axios.post.mockResolvedValue({ data: mockConfig })

      // Call the service method
      const result = await ERPNextService.updateConfig(mockConfig)

      // Assertions
      expect(axios.post).toHaveBeenCalledWith('http://localhost:8000/api/integrations/erpnext/config', mockConfig)
      expect(result).toEqual(mockConfig)
    })
  })

  describe('getProjects', () => {
    it('should fetch ERPNext projects', async () => {
      // Mock data
      const mockProjects = [
        { id: 'project1', name: 'Project 1', status: 'Open' },
        { id: 'project2', name: 'Project 2', status: 'Completed' }
      ]

      // Mock axios response
      axios.get.mockResolvedValue({ data: mockProjects })

      // Call the service method
      const result = await ERPNextService.getProjects()

      // Assertions
      expect(axios.get).toHaveBeenCalledWith('http://localhost:8000/api/integrations/erpnext/projects')
      expect(result).toEqual(mockProjects)
    })
  })

  describe('getTasks', () => {
    it('should fetch all ERPNext tasks when no project is specified', async () => {
      // Mock data
      const mockTasks = [
        { id: 'task1', subject: 'Task 1', status: 'Open' },
        { id: 'task2', subject: 'Task 2', status: 'Completed' }
      ]

      // Mock axios response
      axios.get.mockResolvedValue({ data: mockTasks })

      // Call the service method
      const result = await ERPNextService.getTasks()

      // Assertions
      expect(axios.get).toHaveBeenCalledWith('http://localhost:8000/api/integrations/erpnext/tasks', { params: {} })
      expect(result).toEqual(mockTasks)
    })

    it('should fetch tasks for a specific project', async () => {
      // Mock data
      const mockTasks = [
        { id: 'task1', subject: 'Task 1', status: 'Open' },
        { id: 'task2', subject: 'Task 2', status: 'Completed' }
      ]
      const projectName = 'project1'

      // Mock axios response
      axios.get.mockResolvedValue({ data: mockTasks })

      // Call the service method
      const result = await ERPNextService.getTasks(projectName)

      // Assertions
      expect(axios.get).toHaveBeenCalledWith('http://localhost:8000/api/integrations/erpnext/tasks', { params: { project: projectName } })
      expect(result).toEqual(mockTasks)
    })
  })

  describe('syncToJournal', () => {
    it('should sync ERPNext data to journal', async () => {
      // Mock data
      const mockResult = { success: true, count: 5 }

      // Mock axios response
      axios.post.mockResolvedValue({ data: mockResult })

      // Call the service method
      const result = await ERPNextService.syncToJournal()

      // Assertions
      expect(axios.post).toHaveBeenCalledWith('http://localhost:8000/api/integrations/erpnext/sync-to-journal')
      expect(result).toEqual(mockResult)
    })
  })

  describe('syncFromJournal', () => {
    it('should sync journal data to ERPNext', async () => {
      // Mock data
      const mockResult = { success: true, count: 3 }

      // Mock axios response
      axios.post.mockResolvedValue({ data: mockResult })

      // Call the service method
      const result = await ERPNextService.syncFromJournal()

      // Assertions
      expect(axios.post).toHaveBeenCalledWith('http://localhost:8000/api/integrations/erpnext/sync-from-journal')
      expect(result).toEqual(mockResult)
    })
  })
})
