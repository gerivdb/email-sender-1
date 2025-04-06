import axios from 'axios'
import AnalysisService from '@/services/AnalysisService'

// Mock axios
jest.mock('axios')

describe('AnalysisService', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  describe('getTopicTrends', () => {
    it('should fetch topic trends with default period', async () => {
      // Mock data
      const mockTrends = {
        topics: [
          { id: 0, name: 'Topic 1', words: ['word1', 'word2'] },
          { id: 1, name: 'Topic 2', words: ['word3', 'word4'] }
        ],
        evolution: {
          '2023-01': { 0: 0.5, 1: 0.3 },
          '2023-02': { 0: 0.4, 1: 0.6 }
        }
      }

      // Mock axios response
      axios.get.mockResolvedValue({ data: mockTrends })

      // Call the service method
      const result = await AnalysisService.getTopicTrends()

      // Assertions
      expect(axios.get).toHaveBeenCalledWith('http://localhost:8000/api/analysis/topic-trends', {
        params: { period: 'all' }
      })
      expect(result).toEqual(mockTrends)
    })

    it('should fetch topic trends with specified period', async () => {
      // Mock data
      const mockTrends = {
        topics: [
          { id: 0, name: 'Topic 1', words: ['word1', 'word2'] },
          { id: 1, name: 'Topic 2', words: ['word3', 'word4'] }
        ],
        evolution: {
          '2023-01': { 0: 0.5, 1: 0.3 },
          '2023-02': { 0: 0.4, 1: 0.6 }
        }
      }
      const period = 'year'

      // Mock axios response
      axios.get.mockResolvedValue({ data: mockTrends })

      // Call the service method
      const result = await AnalysisService.getTopicTrends(period)

      // Assertions
      expect(axios.get).toHaveBeenCalledWith('http://localhost:8000/api/analysis/topic-trends', {
        params: { period }
      })
      expect(result).toEqual(mockTrends)
    })
  })

  describe('getSentimentEvolution', () => {
    it('should fetch sentiment evolution data', async () => {
      // Mock data
      const mockEvolution = {
        dates: ['2023-01-01', '2023-01-15', '2023-02-01'],
        polarity: [0.2, 0.3, -0.1],
        subjectivity: [0.5, 0.6, 0.4]
      }

      // Mock axios response
      axios.get.mockResolvedValue({ data: mockEvolution })

      // Call the service method
      const result = await AnalysisService.getSentimentEvolution()

      // Assertions
      expect(axios.get).toHaveBeenCalledWith('http://localhost:8000/api/analysis/sentiment/evolution')
      expect(result).toEqual(mockEvolution)
    })
  })

  describe('getSentimentBySections', () => {
    it('should fetch sentiment by sections data', async () => {
      // Mock data
      const mockSections = {
        'Introduction': { polarity: 0.3, subjectivity: 0.5, count: 10 },
        'Conclusion': { polarity: 0.2, subjectivity: 0.4, count: 8 }
      }

      // Mock axios response
      axios.get.mockResolvedValue({ data: mockSections })

      // Call the service method
      const result = await AnalysisService.getSentimentBySections()

      // Assertions
      expect(axios.get).toHaveBeenCalledWith('http://localhost:8000/api/analysis/sentiment/sections')
      expect(result).toEqual(mockSections)
    })
  })

  describe('getWordCloud', () => {
    it('should fetch word cloud with default parameters', async () => {
      // Mock data
      const mockWordCloud = [
        { text: 'word1', count: 10, frequency: 0.05, evolution: 20 },
        { text: 'word2', count: 8, frequency: 0.04, evolution: -5 }
      ]

      // Mock axios response
      axios.get.mockResolvedValue({ data: mockWordCloud })

      // Call the service method
      const result = await AnalysisService.getWordCloud()

      // Assertions
      expect(axios.get).toHaveBeenCalledWith('http://localhost:8000/api/analysis/word-cloud', {
        params: {}
      })
      expect(result).toEqual(mockWordCloud)
    })

    it('should fetch word cloud with specified parameters', async () => {
      // Mock data
      const mockWordCloud = [
        { text: 'word1', count: 10, frequency: 0.05, evolution: 20 },
        { text: 'word2', count: 8, frequency: 0.04, evolution: -5 }
      ]
      const period = 'month'

      // Mock axios response
      axios.get.mockResolvedValue({ data: mockWordCloud })

      // Call the service method
      const result = await AnalysisService.getWordCloud(period)

      // Assertions
      expect(axios.get).toHaveBeenCalledWith('http://localhost:8000/api/analysis/word-cloud', {
        params: { period }
      })
      expect(result).toEqual(mockWordCloud)
    })
  })

  describe('runAnalysis', () => {
    it('should run a specific analysis', async () => {
      // Mock data
      const mockResult = { success: true, message: 'Analysis completed' }
      const analysisType = 'sentiment'

      // Mock axios response
      axios.post.mockResolvedValue({ data: mockResult })

      // Call the service method
      const result = await AnalysisService.runAnalysis(analysisType)

      // Assertions
      expect(axios.post).toHaveBeenCalledWith('http://localhost:8000/api/analysis/run', {
        analysis_type: analysisType
      })
      expect(result).toEqual(mockResult)
    })
  })

  describe('runAllAnalyses', () => {
    it('should run all analyses', async () => {
      // Mock data
      const mockResult = { success: true, message: 'All analyses completed' }

      // Mock axios response
      axios.post.mockResolvedValue({ data: mockResult })

      // Call the service method
      const result = await AnalysisService.runAllAnalyses()

      // Assertions
      expect(axios.post).toHaveBeenCalledWith('http://localhost:8000/api/analysis/run', {
        analysis_type: 'all'
      })
      expect(result).toEqual(mockResult)
    })
  })

  describe('getSimilarEntries', () => {
    it('should fetch similar entries with default limit', async () => {
      // Mock data
      const mockEntries = [
        { id: 'entry1', title: 'Entry 1', similarity: 0.9 },
        { id: 'entry2', title: 'Entry 2', similarity: 0.8 }
      ]
      const filename = 'test-entry.md'

      // Mock axios response
      axios.get.mockResolvedValue({ data: mockEntries })

      // Call the service method
      const result = await AnalysisService.getSimilarEntries(filename)

      // Assertions
      expect(axios.get).toHaveBeenCalledWith(`http://localhost:8000/api/analysis/similar/${filename}`, {
        params: { limit: 5 }
      })
      expect(result).toEqual(mockEntries)
    })

    it('should fetch similar entries with specified limit', async () => {
      // Mock data
      const mockEntries = [
        { id: 'entry1', title: 'Entry 1', similarity: 0.9 },
        { id: 'entry2', title: 'Entry 2', similarity: 0.8 },
        { id: 'entry3', title: 'Entry 3', similarity: 0.7 }
      ]
      const filename = 'test-entry.md'
      const limit = 3

      // Mock axios response
      axios.get.mockResolvedValue({ data: mockEntries })

      // Call the service method
      const result = await AnalysisService.getSimilarEntries(filename, limit)

      // Assertions
      expect(axios.get).toHaveBeenCalledWith(`http://localhost:8000/api/analysis/similar/${filename}`, {
        params: { limit }
      })
      expect(result).toEqual(mockEntries)
    })
  })

  describe('queryRag', () => {
    it('should query the RAG system', async () => {
      // Mock data
      const mockResponse = {
        answer: 'This is the answer',
        sources: [
          { id: 'entry1', title: 'Entry 1', relevance: 0.9 },
          { id: 'entry2', title: 'Entry 2', relevance: 0.8 }
        ]
      }
      const query = 'What is the meaning of life?'

      // Mock axios response
      axios.post.mockResolvedValue({ data: mockResponse })

      // Call the service method
      const result = await AnalysisService.queryRag(query)

      // Assertions
      expect(axios.post).toHaveBeenCalledWith('http://localhost:8000/api/analysis/rag/query', {
        query
      })
      expect(result).toEqual(mockResponse)
    })
  })
})
