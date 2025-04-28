# Tests des Services

Cette page décrit les tests unitaires pour les services du système de journal de bord RAG.

## ERPNextService

Le fichier `development/testing/tests/unit/services/ERPNextService.spec.js` contient les tests pour le service ERPNextService.

### Méthodes testées

- `getConfig`: Récupère la configuration ERPNext
- `updateConfig`: Met à jour la configuration ERPNext
- `getProjects`: Récupère la liste des projets ERPNext
- `getTasks`: Récupère la liste des tâches ERPNext
- `syncToJournal`: Synchronise les tâches ERPNext vers le journal
- `syncFromJournal`: Synchronise les entrées de journal vers ERPNext

### Exemple de test

```javascript
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
```

## AnalysisService

Le fichier `development/testing/tests/unit/services/AnalysisService.spec.js` contient les tests pour le service AnalysisService.

### Méthodes testées

- `getTopicTrends`: Récupère les tendances des sujets
- `getSentimentEvolution`: Récupère l'évolution du sentiment
- `getSentimentBySections`: Récupère le sentiment par section
- `getWordCloud`: Récupère les données du nuage de mots
- `runAnalysis`: Exécute une analyse spécifique
- `runAllAnalyses`: Exécute toutes les analyses
- `getSimilarEntries`: Récupère les entrées similaires
- `queryRag`: Interroge le système RAG

### Exemple de test

```javascript
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
```

## Mocking des dépendances

Les tests utilisent Jest pour mocker les dépendances externes:

```javascript
// Mock axios
jest.mock('axios')

// Before each test
beforeEach(() => {
  jest.clearAllMocks()
})
```

## Gestion des erreurs

Les tests vérifient également la gestion des erreurs:

```javascript
it('should handle errors when fetching word cloud', async () => {
  // Mock axios error
  const error = new Error('Network error')
  axios.get.mockRejectedValue(error)

  // Call the service method and expect it to throw
  await expect(AnalysisService.getWordCloud()).rejects.toThrow(error)

  // Assertions
  expect(axios.get).toHaveBeenCalledWith('http://localhost:8000/api/analysis/word-cloud', {
    params: {}
  })
})
```

## Bonnes pratiques

- Mocker toutes les dépendances externes
- Tester les cas normaux et les cas d'erreur
- Vérifier que les méthodes appellent les bons endpoints avec les bons paramètres
- Vérifier que les méthodes retournent les bonnes données
- Vérifier que les erreurs sont correctement propagées
