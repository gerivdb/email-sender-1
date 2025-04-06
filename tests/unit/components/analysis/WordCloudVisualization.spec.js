import { shallowMount, createLocalVue } from '@vue/test-utils'
import Vuex from 'vuex'
import WordCloudVisualization from '@/components/analysis/WordCloudVisualization.vue'

// Mock d3 and d3-cloud
jest.mock('d3', () => ({
  scaleLinear: jest.fn().mockReturnValue({
    domain: jest.fn().mockReturnThis(),
    range: jest.fn().mockReturnThis()
  }),
  scaleLog: jest.fn().mockReturnValue({
    domain: jest.fn().mockReturnThis(),
    range: jest.fn().mockReturnThis()
  }),
  select: jest.fn().mockReturnValue({
    append: jest.fn().mockReturnThis(),
    attr: jest.fn().mockReturnThis(),
    style: jest.fn().mockReturnThis(),
    selectAll: jest.fn().mockReturnThis(),
    data: jest.fn().mockReturnThis(),
    enter: jest.fn().mockReturnThis(),
    text: jest.fn().mockReturnThis(),
    on: jest.fn().mockReturnThis()
  }),
  max: jest.fn().mockReturnValue(10),
  min: jest.fn().mockReturnValue(1)
}))

jest.mock('d3-cloud', () => jest.fn().mockImplementation(() => ({
  size: jest.fn().mockReturnThis(),
  words: jest.fn().mockReturnThis(),
  padding: jest.fn().mockReturnThis(),
  rotate: jest.fn().mockReturnThis(),
  fontSize: jest.fn().mockReturnThis(),
  on: jest.fn().mockReturnThis(),
  start: jest.fn().mockImplementation(function() {
    // Call the 'end' event handler
    const callback = this.on.mock.calls[0][1]
    callback([
      { text: 'word1', size: 30, x: 100, y: 100 },
      { text: 'word2', size: 20, x: 200, y: 200 }
    ])
    return this
  })
})))

const localVue = createLocalVue()
localVue.use(Vuex)

describe('WordCloudVisualization.vue', () => {
  let store
  let actions
  
  beforeEach(() => {
    // Mock store actions
    actions = {
      'analysis/fetchWordCloud': jest.fn().mockResolvedValue([
        { text: 'word1', count: 10, frequency: 0.05, evolution: 20 },
        { text: 'word2', count: 8, frequency: 0.04, evolution: -5 }
      ]),
      'journal/searchEntries': jest.fn().mockResolvedValue([
        { id: 'entry1', title: 'Entry 1', date: '2023-01-01', content: 'This is a test with word1 in it.' },
        { id: 'entry2', title: 'Entry 2', date: '2023-01-15', content: 'Another test with word1 mentioned.' }
      ])
    }
    
    // Create store
    store = new Vuex.Store({
      actions
    })
    
    // Mock Element.prototype properties and methods
    Object.defineProperty(Element.prototype, 'clientWidth', {
      value: 800
    })
    
    // Mock window.addEventListener
    window.addEventListener = jest.fn()
    window.removeEventListener = jest.fn()
  })
  
  afterEach(() => {
    jest.clearAllMocks()
  })
  
  it('fetches word cloud data on mount', async () => {
    const wrapper = shallowMount(WordCloudVisualization, {
      store,
      localVue,
      stubs: ['d3']
    })
    
    // Wait for promises to resolve
    await wrapper.vm.$nextTick()
    
    // Assertions
    expect(actions['analysis/fetchWordCloud']).toHaveBeenCalledWith(
      expect.anything(),
      {
        period: 'month',
        maxWords: 100
      },
      undefined
    )
    expect(wrapper.vm.words).toEqual([
      { text: 'word1', value: 10, frequency: 0.05, evolution: 20 },
      { text: 'word2', value: 8, frequency: 0.04, evolution: -5 }
    ])
  })
  
  it('changes period and refetches data', async () => {
    const wrapper = shallowMount(WordCloudVisualization, {
      store,
      localVue,
      stubs: ['d3']
    })
    
    // Wait for initial fetch to complete
    await wrapper.vm.$nextTick()
    
    // Change period
    wrapper.vm.selectedPeriod = 'year'
    await wrapper.vm.fetchData()
    
    // Assertions
    expect(actions['analysis/fetchWordCloud']).toHaveBeenCalledWith(
      expect.anything(),
      {
        period: 'year',
        maxWords: 100
      },
      undefined
    )
  })
  
  it('changes max words and refetches data', async () => {
    const wrapper = shallowMount(WordCloudVisualization, {
      store,
      localVue,
      stubs: ['d3']
    })
    
    // Wait for initial fetch to complete
    await wrapper.vm.$nextTick()
    
    // Change max words
    wrapper.vm.maxWords = 200
    await wrapper.vm.fetchData()
    
    // Assertions
    expect(actions['analysis/fetchWordCloud']).toHaveBeenCalledWith(
      expect.anything(),
      {
        period: 'month',
        maxWords: 200
      },
      undefined
    )
  })
  
  it('selects a word and fetches related entries', async () => {
    const wrapper = shallowMount(WordCloudVisualization, {
      store,
      localVue,
      stubs: ['d3']
    })
    
    // Wait for initial fetch to complete
    await wrapper.vm.$nextTick()
    
    // Select a word
    const word = {
      text: 'word1',
      value: 10,
      frequency: 0.05,
      evolution: 20
    }
    
    await wrapper.vm.selectWord(word)
    
    // Assertions
    expect(wrapper.vm.selectedWord).toEqual(word)
    expect(actions['journal/searchEntries']).toHaveBeenCalledWith(
      expect.anything(),
      {
        query: 'word1',
        limit: 5
      },
      undefined
    )
    expect(wrapper.vm.relatedEntries).toEqual([
      {
        id: 'entry1',
        title: 'Entry 1',
        date: '2023-01-01',
        excerpt: 'This is a test with word1 in it.'
      },
      {
        id: 'entry2',
        title: 'Entry 2',
        date: '2023-01-15',
        excerpt: 'Another test with word1 mentioned.'
      }
    ])
  })
  
  it('extracts excerpt containing the word', () => {
    const wrapper = shallowMount(WordCloudVisualization, {
      store,
      localVue,
      stubs: ['d3']
    })
    
    // Test with word in content
    const content = 'This is a test. Here is the word1 in a sentence. Another sentence.'
    const excerpt = wrapper.vm.getExcerpt(content, 'word1')
    expect(excerpt).toBe('Here is the word1 in a sentence.')
    
    // Test with word not in content
    const noMatchContent = 'This content does not contain the target word.'
    const noMatchExcerpt = wrapper.vm.getExcerpt(noMatchContent, 'word1')
    expect(noMatchExcerpt).toBe('This content does not contain the target word...')
    
    // Test with null content
    const nullExcerpt = wrapper.vm.getExcerpt(null, 'word1')
    expect(nullExcerpt).toBe('')
  })
  
  it('highlights word in text', () => {
    const wrapper = shallowMount(WordCloudVisualization, {
      store,
      localVue,
      stubs: ['d3']
    })
    
    // Test with word in text
    const text = 'This is a test with word1 in it.'
    const highlighted = wrapper.vm.highlightWord(text, 'word1')
    expect(highlighted).toBe('This is a test with <span class="highlight">word1</span> in it.')
    
    // Test with multiple occurrences
    const multiText = 'word1 appears twice: word1'
    const multiHighlighted = wrapper.vm.highlightWord(multiText, 'word1')
    expect(multiHighlighted).toBe('<span class="highlight">word1</span> appears twice: <span class="highlight">word1</span>')
    
    // Test with no match
    const noMatchText = 'No match here'
    const noMatchHighlighted = wrapper.vm.highlightWord(noMatchText, 'word1')
    expect(noMatchHighlighted).toBe('No match here')
    
    // Test with null text
    const nullHighlighted = wrapper.vm.highlightWord(null, 'word1')
    expect(nullHighlighted).toBe(null)
  })
  
  it('returns correct evolution class', () => {
    const wrapper = shallowMount(WordCloudVisualization, {
      store,
      localVue,
      stubs: ['d3']
    })
    
    // Assertions
    expect(wrapper.vm.getEvolutionClass(15)).toBe('text-green-600')
    expect(wrapper.vm.getEvolutionClass(5)).toBe('text-green-500')
    expect(wrapper.vm.getEvolutionClass(0)).toBe('text-gray-500')
    expect(wrapper.vm.getEvolutionClass(-5)).toBe('text-red-500')
    expect(wrapper.vm.getEvolutionClass(-15)).toBe('text-red-600')
  })
  
  it('returns correct evolution icon', () => {
    const wrapper = shallowMount(WordCloudVisualization, {
      store,
      localVue,
      stubs: ['d3']
    })
    
    // Assertions
    expect(wrapper.vm.getEvolutionIcon(15)).toBe('fas fa-arrow-up')
    expect(wrapper.vm.getEvolutionIcon(5)).toBe('fas fa-arrow-up')
    expect(wrapper.vm.getEvolutionIcon(0)).toBe('fas fa-equals')
    expect(wrapper.vm.getEvolutionIcon(-5)).toBe('fas fa-arrow-down')
    expect(wrapper.vm.getEvolutionIcon(-15)).toBe('fas fa-arrow-down')
  })
  
  it('formats date correctly', () => {
    const wrapper = shallowMount(WordCloudVisualization, {
      store,
      localVue,
      stubs: ['d3']
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
  
  it('debounces function calls', () => {
    const wrapper = shallowMount(WordCloudVisualization, {
      store,
      localVue,
      stubs: ['d3']
    })
    
    // Mock setTimeout and clearTimeout
    jest.useFakeTimers()
    
    // Create a mock function
    const mockFn = jest.fn()
    
    // Create debounced function
    const debouncedFn = wrapper.vm.debounce(mockFn, 200)
    
    // Call it multiple times
    debouncedFn()
    debouncedFn()
    debouncedFn()
    
    // Function should not have been called yet
    expect(mockFn).not.toHaveBeenCalled()
    
    // Fast-forward time
    jest.runAllTimers()
    
    // Function should have been called once
    expect(mockFn).toHaveBeenCalledTimes(1)
    
    // Restore timers
    jest.useRealTimers()
  })
})
