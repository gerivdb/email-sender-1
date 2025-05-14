/**
 * Tests pour le module de filtrage MetroMapFilters
 */

import MetroMapFilters from '../MetroMapFilters.js';

// Mock pour Cytoscape et le visualiseur
class MockCyElement {
  constructor(data = {}, isNode = true) {
    this._data = data;
    this._isNode = isNode;
    this._isEdge = !isNode;
    this._visible = true;
    this._style = {};
  }

  data(key) {
    return this._data[key];
  }

  isNode() {
    return this._isNode;
  }

  isEdge() {
    return this._isEdge;
  }

  style(key, value) {
    if (value !== undefined) {
      this._style[key] = value;
      return this;
    }
    return this._style[key];
  }

  visible() {
    return this._visible;
  }

  id() {
    return this._data.id || 'mock-id';
  }
}

class MockCyCollection {
  constructor(elements = []) {
    this.elements = elements;
  }

  filter(callback) {
    const filtered = this.elements.filter(callback);
    return new MockCyCollection(filtered);
  }

  nodes() {
    const nodes = this.elements.filter(el => el.isNode());
    return new MockCyCollection(nodes);
  }

  edges() {
    const edges = this.elements.filter(el => el.isEdge());
    return new MockCyCollection(edges);
  }

  edgesWith() {
    return this;
  }

  union(collection) {
    return new MockCyCollection([...this.elements, ...collection.elements]);
  }

  contains(element) {
    return this.elements.includes(element);
  }

  forEach(callback) {
    this.elements.forEach(callback);
  }

  get length() {
    return this.elements.length;
  }

  toArray() {
    return this.elements;
  }
}

class MockCytoscape {
  constructor(elements = []) {
    this.allElements = elements;
    this._style = {};
  }

  elements() {
    return new MockCyCollection(this.allElements);
  }

  style(key, value) {
    if (value !== undefined) {
      this._style[key] = value;
      return this;
    }
    return this;
  }

  selector() {
    return this;
  }

  update() {
    // Ne rien faire
  }
}

class MockVisualizer {
  constructor(elements = []) {
    this.cy = new MockCytoscape(elements);
  }
}

// Fonction utilitaire pour créer des éléments de test
function createTestElements() {
  // Nœuds
  const nodeA = new MockCyElement({ id: 'A', label: 'Node A', status: 'completed', roadmapId: 'roadmap1', level: 'cosmos' }, true);
  const nodeB = new MockCyElement({ id: 'B', label: 'Node B', status: 'in_progress', roadmapId: 'roadmap1', level: 'galaxy' }, true);
  const nodeC = new MockCyElement({ id: 'C', label: 'Node C', status: 'planned', roadmapId: 'roadmap2', level: 'system' }, true);
  const nodeD = new MockCyElement({ id: 'D', label: 'Node D', status: 'completed', roadmapId: 'roadmap2', level: 'planet' }, true);

  // Arêtes
  const edgeAB = new MockCyElement({ id: 'A_B', source: 'A', target: 'B', roadmapId: 'roadmap1' }, false);
  const edgeBC = new MockCyElement({ id: 'B_C', source: 'B', target: 'C', roadmapId: 'roadmap1' }, false);
  const edgeCD = new MockCyElement({ id: 'C_D', source: 'C', target: 'D', roadmapId: 'roadmap2' }, false);

  return [nodeA, nodeB, nodeC, nodeD, edgeAB, edgeBC, edgeCD];
}

// Suite de tests pour le constructeur
describe('MetroMapFilters - Constructor', () => {
  test('should create an instance with default options', () => {
    const visualizer = new MockVisualizer();
    const filters = new MetroMapFilters(visualizer);

    expect(filters).toBeDefined();
    expect(filters.visualizer).toBe(visualizer);
    expect(filters.cy).toBe(visualizer.cy);
    expect(filters.options).toBeDefined();
    expect(filters.options.statusFilters).toBeDefined();
    expect(filters.options.roadmapFilters).toBeDefined();
    expect(filters.options.levelFilters).toBeDefined();
    expect(filters.options.textSearch).toBeDefined();
    expect(filters.options.advancedFilters).toBeDefined();
  });

  test('should create an instance with custom options', () => {
    const visualizer = new MockVisualizer();
    const options = {
      statusFilters: {
        enabled: false,
        statuses: ['completed', 'in_progress']
      },
      textSearch: {
        enabled: true,
        searchFields: ['label', 'description'],
        minLength: 3,
        highlightResults: false
      }
    };
    const filters = new MetroMapFilters(visualizer, options);

    expect(filters.options.statusFilters.enabled).toBe(false);
    expect(filters.options.statusFilters.statuses).toEqual(['completed', 'in_progress']);
    expect(filters.options.textSearch.enabled).toBe(true);
    expect(filters.options.textSearch.searchFields).toEqual(['label', 'description']);
    expect(filters.options.textSearch.minLength).toBe(3);
    expect(filters.options.textSearch.highlightResults).toBe(false);

    // Les options non spécifiées doivent avoir leurs valeurs par défaut
    expect(filters.options.roadmapFilters).toBeDefined();
    expect(filters.options.levelFilters).toBeDefined();
    expect(filters.options.advancedFilters).toBeDefined();
  });

  test('should initialize state correctly', () => {
    const visualizer = new MockVisualizer();
    const filters = new MetroMapFilters(visualizer);

    expect(filters.state).toBeDefined();
    expect(filters.state.activeStatusFilters).toBeInstanceOf(Set);
    expect(filters.state.activeRoadmapFilters).toBeInstanceOf(Set);
    expect(filters.state.activeLevelFilters).toBeInstanceOf(Set);
    expect(filters.state.searchQuery).toBe('');
    expect(filters.state.advancedFilters).toEqual([]);
    expect(filters.state.filteredElements).toBeNull();
    expect(filters.state.originalElementsState).toBeInstanceOf(Map);
    expect(filters.state.highlightedElements).toBeInstanceOf(Set);
  });
});

// Suite de tests pour les méthodes de filtrage
describe('MetroMapFilters - Filtering Methods', () => {
  test('setStatusFilters should update active status filters', () => {
    const visualizer = new MockVisualizer();
    const filters = new MetroMapFilters(visualizer);

    // Remplacer la méthode applyFilters par un mock
    filters.applyFilters = jest.fn();

    // Appeler la méthode
    filters.setStatusFilters(['completed', 'planned']);

    // Vérifier que les filtres sont mis à jour
    expect(filters.state.activeStatusFilters).toEqual(new Set(['completed', 'planned']));

    // Vérifier que applyFilters est appelé
    expect(filters.applyFilters).toHaveBeenCalled();
  });

  test('setRoadmapFilters should update active roadmap filters', () => {
    const visualizer = new MockVisualizer();
    const filters = new MetroMapFilters(visualizer);

    // Remplacer la méthode applyFilters par un mock
    filters.applyFilters = jest.fn();

    // Appeler la méthode
    filters.setRoadmapFilters(['roadmap1', 'roadmap2']);

    // Vérifier que les filtres sont mis à jour
    expect(filters.state.activeRoadmapFilters).toEqual(new Set(['roadmap1', 'roadmap2']));

    // Vérifier que applyFilters est appelé
    expect(filters.applyFilters).toHaveBeenCalled();
  });

  test('setSearchQuery should update search query', () => {
    const visualizer = new MockVisualizer();
    const filters = new MetroMapFilters(visualizer);

    // Remplacer la méthode applyFilters par un mock
    filters.applyFilters = jest.fn();

    // Appeler la méthode
    filters.setSearchQuery('Node A');

    // Vérifier que la requête est mise à jour
    expect(filters.state.searchQuery).toBe('Node A');

    // Vérifier que applyFilters est appelé
    expect(filters.applyFilters).toHaveBeenCalled();
  });

  test('setLevelFilters should update active level filters', () => {
    const visualizer = new MockVisualizer();
    const filters = new MetroMapFilters(visualizer);

    // Remplacer la méthode applyFilters par un mock
    filters.applyFilters = jest.fn();

    // Appeler la méthode
    filters.setLevelFilters(['cosmos', 'galaxy']);

    // Vérifier que les filtres sont mis à jour
    expect(filters.state.activeLevelFilters).toEqual(new Set(['cosmos', 'galaxy']));

    // Vérifier que applyFilters est appelé
    expect(filters.applyFilters).toHaveBeenCalled();
  });

  test('setAdvancedFilters should update advanced filters', () => {
    const visualizer = new MockVisualizer();
    const filters = new MetroMapFilters(visualizer);

    // Remplacer la méthode applyFilters par un mock
    filters.applyFilters = jest.fn();

    // Créer des filtres avancés
    const advancedFilters = [
      { field: 'label', operator: 'contains', value: 'Node' },
      { field: 'status', operator: 'equals', value: 'completed' }
    ];

    // Appeler la méthode
    filters.setAdvancedFilters(advancedFilters);

    // Vérifier que les filtres sont mis à jour
    expect(filters.state.advancedFilters).toEqual(advancedFilters);

    // Vérifier que applyFilters est appelé
    expect(filters.applyFilters).toHaveBeenCalled();
  });

  test('applyFilters should apply all active filters', () => {
    const elements = createTestElements();
    const visualizer = new MockVisualizer(elements);
    const filters = new MetroMapFilters(visualizer);

    // Remplacer les méthodes de filtrage par des mocks
    filters._resetElementsState = jest.fn();
    filters._filterByStatus = jest.fn().mockReturnValue(new MockCyCollection(elements));
    filters._filterByRoadmap = jest.fn().mockReturnValue(new MockCyCollection(elements));
    filters._filterByLevel = jest.fn().mockReturnValue(new MockCyCollection(elements));
    filters._filterByText = jest.fn().mockReturnValue(new MockCyCollection(elements));
    filters._filterByAdvancedFilters = jest.fn().mockReturnValue(new MockCyCollection(elements));
    filters._applyVisualFilters = jest.fn();

    // Définir des filtres actifs
    filters.state.activeStatusFilters = new Set(['completed']);
    filters.state.activeRoadmapFilters = new Set(['roadmap1']);
    filters.state.activeLevelFilters = new Set(['cosmos']);
    filters.state.searchQuery = 'Node';
    filters.state.advancedFilters = [{ field: 'label', operator: 'contains', value: 'Node' }];

    // Appeler la méthode
    const result = filters.applyFilters();

    // Vérifier que les méthodes de filtrage sont appelées
    expect(filters._resetElementsState).toHaveBeenCalled();
    expect(filters._filterByStatus).toHaveBeenCalled();
    expect(filters._filterByRoadmap).toHaveBeenCalled();
    expect(filters._filterByLevel).toHaveBeenCalled();
    expect(filters._filterByText).toHaveBeenCalled();
    expect(filters._filterByAdvancedFilters).toHaveBeenCalled();
    expect(filters._applyVisualFilters).toHaveBeenCalled();

    // Vérifier que l'état est mis à jour
    expect(filters.state.filteredElements).toBeDefined();
  });

  test('resetFilters should reset all filters to default state', () => {
    const elements = createTestElements();
    const visualizer = new MockVisualizer(elements);
    const filters = new MetroMapFilters(visualizer);

    // Remplacer les méthodes par des mocks
    filters._resetElementsState = jest.fn();
    filters._applyVisualFilters = jest.fn();

    // Définir des filtres actifs
    filters.state.activeStatusFilters = new Set(['completed']);
    filters.state.activeRoadmapFilters = new Set(['roadmap1']);
    filters.state.activeLevelFilters = new Set(['cosmos']);
    filters.state.searchQuery = 'Node';
    filters.state.advancedFilters = [{ field: 'label', operator: 'contains', value: 'Node' }];

    // Appeler la méthode
    const result = filters.resetFilters();

    // Vérifier que les filtres sont réinitialisés
    expect(filters.state.activeStatusFilters).toEqual(new Set(filters.options.statusFilters.statuses));
    expect(filters.state.activeRoadmapFilters).toEqual(new Set());
    expect(filters.state.activeLevelFilters).toEqual(new Set(filters.options.levelFilters.levels));
    expect(filters.state.searchQuery).toBe('');
    expect(filters.state.advancedFilters).toEqual([]);

    // Vérifier que les méthodes sont appelées
    expect(filters._resetElementsState).toHaveBeenCalled();
    expect(filters._applyVisualFilters).toHaveBeenCalled();
  });
});

// Suite de tests pour les méthodes de filtrage spécifiques
describe('MetroMapFilters - Specific Filtering Methods', () => {
  test('_filterByStatus should filter nodes by status', () => {
    const elements = createTestElements();
    const visualizer = new MockVisualizer(elements);
    const filters = new MetroMapFilters(visualizer);

    // Définir les statuts actifs
    filters.state.activeStatusFilters = new Set(['completed']);

    // Créer une collection mock avec une méthode edgesWith
    const mockCollection = new MockCyCollection(elements);
    mockCollection.edgesWith = jest.fn().mockReturnValue(new MockCyCollection([]));

    // Appeler la méthode réelle
    const result = filters._filterByStatus(mockCollection);

    // Vérifier que des nœuds sont inclus
    expect(result.elements.length).toBeGreaterThan(0);
    expect(result.elements.some(node => node.isNode() && node.data('status') === 'completed')).toBe(true);
  });

  test('_filterByRoadmap should filter elements by roadmap', () => {
    const elements = createTestElements();
    const visualizer = new MockVisualizer(elements);
    const filters = new MetroMapFilters(visualizer);

    // Définir les roadmaps actives
    filters.state.activeRoadmapFilters = new Set(['roadmap1']);

    // Appeler la méthode réelle
    const result = filters._filterByRoadmap(new MockCyCollection(elements));

    // Vérifier que seuls les éléments de 'roadmap1' sont inclus
    expect(result.elements.some(el => el.data('roadmapId') === 'roadmap1')).toBe(true);
    expect(result.elements.every(el => el.data('roadmapId') === 'roadmap1')).toBe(true);
  });

  test('_filterByLevel should filter nodes by level', () => {
    const elements = createTestElements();
    const visualizer = new MockVisualizer(elements);
    const filters = new MetroMapFilters(visualizer);

    // Définir les niveaux actifs
    filters.state.activeLevelFilters = new Set(['cosmos', 'galaxy']);

    // Appeler la méthode réelle
    const result = filters._filterByLevel(new MockCyCollection(elements));

    // Vérifier que seuls les nœuds des niveaux 'cosmos' et 'galaxy' sont inclus
    expect(result.elements.some(node => node.isNode() && node.data('level') === 'cosmos')).toBe(true);
    expect(result.elements.some(node => node.isNode() && node.data('level') === 'galaxy')).toBe(true);
    expect(result.elements.every(node => !node.isNode() || node.data('level') === 'cosmos' || node.data('level') === 'galaxy' || node.isEdge())).toBe(true);
  });

  test('_filterByText should filter nodes by text search', () => {
    const elements = createTestElements();
    const visualizer = new MockVisualizer(elements);
    const filters = new MetroMapFilters(visualizer, {
      textSearch: {
        searchFields: ['label'],
        minLength: 1,
        highlightResults: true
      }
    });

    // Définir la requête de recherche
    filters.state.searchQuery = 'Node A';

    // Appeler la méthode réelle
    const result = filters._filterByText(new MockCyCollection(elements));

    // Vérifier que seuls les nœuds contenant 'Node A' sont inclus
    expect(result.elements.some(node => node.isNode() && node.data('label') === 'Node A')).toBe(true);

    // Vérifier que le nœud est mis en évidence
    expect(filters.state.highlightedElements.size).toBeGreaterThan(0);
  });

  test('_filterByAdvancedFilters should filter nodes by advanced filters', () => {
    const elements = createTestElements();
    const visualizer = new MockVisualizer(elements);
    const filters = new MetroMapFilters(visualizer);

    // Définir des filtres avancés
    filters.state.advancedFilters = [
      { field: 'status', operator: 'equals', value: 'completed' }
    ];

    // Appeler la méthode réelle
    const result = filters._filterByAdvancedFilters(new MockCyCollection(elements));

    // Vérifier que seuls les nœuds correspondant aux filtres sont inclus
    expect(result.elements.length).toBeGreaterThan(0);
    expect(result.elements.every(node => !node.isNode() || node.data('status') === 'completed' || node.isEdge())).toBe(true);
  });

  test('_filterByAdvancedFilters should handle multiple operators', () => {
    const elements = createTestElements();
    const visualizer = new MockVisualizer(elements);
    const filters = new MetroMapFilters(visualizer);

    // Tester différents opérateurs
    const testOperator = (operator, field, value, expectedResult) => {
      filters.state.advancedFilters = [{ field, operator, value }];
      const result = filters._filterByAdvancedFilters(new MockCyCollection(elements));
      return result.elements.length > 0;
    };

    // Tester l'opérateur 'equals'
    expect(testOperator('equals', 'status', 'completed', true)).toBe(true);

    // Tester l'opérateur 'contains'
    expect(testOperator('contains', 'label', 'Node', true)).toBe(true);

    // Tester l'opérateur 'startsWith'
    expect(testOperator('startsWith', 'label', 'Node', true)).toBe(true);

    // Tester l'opérateur 'endsWith'
    expect(testOperator('endsWith', 'label', 'A', true)).toBe(true);

    // Tester l'opérateur 'regex'
    expect(testOperator('regex', 'label', 'Node [A-D]', true)).toBe(true);
  });

  test('_resetElementsState should reset element states', () => {
    const elements = createTestElements();
    const visualizer = new MockVisualizer(elements);
    const filters = new MetroMapFilters(visualizer);

    // Simuler un état original vide
    filters.state.originalElementsState = new Map();

    // Appeler la méthode
    filters._resetElementsState();

    // Vérifier que l'état original est sauvegardé
    expect(filters.state.originalElementsState.size).toBeGreaterThan(0);

    // Vérifier que les éléments mis en évidence sont réinitialisés
    expect(filters.state.highlightedElements.size).toBe(0);
  });

  test('_applyVisualFilters should apply filters visually', () => {
    const elements = createTestElements();
    const visualizer = new MockVisualizer(elements);
    const filters = new MetroMapFilters(visualizer);

    // Ajouter la méthode getElementById au mock Cytoscape
    visualizer.cy.getElementById = jest.fn().mockReturnValue({
      isNode: () => true,
      style: jest.fn()
    });

    // Simuler des éléments filtrés
    filters.state.filteredElements = new MockCyCollection([elements[0]]); // Seulement le nœud A

    // Simuler des éléments mis en évidence
    filters.state.highlightedElements.add('A');

    // Appeler la méthode
    filters._applyVisualFilters();

    // Vérifier que getElementById est appelé
    expect(visualizer.cy.getElementById).toHaveBeenCalledWith('A');
  });
});

// Exécuter les tests
// Note: Ces tests sont conçus pour être exécutés avec Jest
// Pour les exécuter, utilisez la commande: npm test
