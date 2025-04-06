# Tests des Composants

Cette page décrit les tests unitaires pour les composants Vue.js du système de journal de bord RAG.

## Configuration des tests

Les tests de composants utilisent Vue Test Utils pour monter les composants et interagir avec eux:

```javascript
import { shallowMount, createLocalVue } from '@vue/test-utils'
import Vuex from 'vuex'
import Component from '@/components/path/to/Component.vue'

const localVue = createLocalVue()
localVue.use(Vuex)

describe('Component.vue', () => {
  let store
  let actions
  
  beforeEach(() => {
    // Mock store actions
    actions = {
      'namespace/action': jest.fn()
    }
    
    // Create store
    store = new Vuex.Store({
      actions
    })
  })
  
  it('renders correctly', () => {
    const wrapper = shallowMount(Component, {
      store,
      localVue
    })
    
    // Assertions
    expect(wrapper.exists()).toBe(true)
  })
})
```

## ERPNextIntegration

Le fichier `tests/unit/components/integrations/ERPNextIntegration.spec.js` contient les tests pour le composant ERPNextIntegration.

### Fonctionnalités testées

- Chargement de la configuration
- Affichage/masquage du panneau de configuration
- Sauvegarde de la configuration
- Test de connexion
- Chargement des projets
- Sélection d'un projet et chargement de ses tâches
- Synchronisation ERPNext → Journal
- Synchronisation Journal → ERPNext
- Création d'une entrée de journal à partir d'une tâche

### Exemple de test

```javascript
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
```

## WordCloudVisualization

Le fichier `tests/unit/components/analysis/WordCloudVisualization.spec.js` contient les tests pour le composant WordCloudVisualization.

### Fonctionnalités testées

- Chargement des données du nuage de mots
- Changement de période et rechargement des données
- Changement du nombre de mots et rechargement des données
- Sélection d'un mot et chargement des entrées associées
- Extraction d'extraits contenant le mot
- Mise en évidence du mot dans les extraits
- Calcul des classes CSS pour l'évolution
- Formatage des dates
- Debounce des appels de fonction

### Exemple de test

```javascript
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
```

## Mocking des dépendances

Les tests mockent les dépendances externes comme D3.js et d3-cloud:

```javascript
// Mock d3 and d3-cloud
jest.mock('d3', () => ({
  scaleLinear: jest.fn().mockReturnValue({
    domain: jest.fn().mockReturnThis(),
    range: jest.fn().mockReturnThis()
  }),
  // ...
}))

jest.mock('d3-cloud', () => jest.fn().mockImplementation(() => ({
  size: jest.fn().mockReturnThis(),
  words: jest.fn().mockReturnThis(),
  // ...
})))
```

## Tests d'événements

Les tests vérifient également la gestion des événements:

```javascript
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
```

## Tests de méthodes utilitaires

Les tests vérifient également les méthodes utilitaires:

```javascript
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
```

## Bonnes pratiques

- Utiliser `shallowMount` pour les tests unitaires
- Mocker les dépendances externes
- Tester les méthodes du cycle de vie (created, mounted, etc.)
- Tester les méthodes de l'API publique
- Tester les méthodes utilitaires
- Tester les événements
- Tester les cas normaux et les cas d'erreur
