/**
 * Tests pour StatusPriorityView
 * Ce module contient les tests unitaires pour les vues par statut et priorité
 * 
 * Version: 1.0
 * Date: 2025-05-30
 */

import StatusPriorityView from '../StatusPriorityView.js';

// Mock pour un nœud Cytoscape
class NodeMock {
  constructor(data) {
    this.nodeData = data;
  }
  
  data(field) {
    if (!field) {
      return this.nodeData;
    }
    
    // Accéder aux champs imbriqués (par exemple, 'metadata.strategic.priority')
    const parts = field.split('.');
    let value = this.nodeData;
    
    for (const part of parts) {
      if (value && typeof value === 'object' && part in value) {
        value = value[part];
      } else {
        return undefined;
      }
    }
    
    return value;
  }
}

// Mock pour Cytoscape
class CytoscapeMock {
  constructor() {
    this.mockCollection = [];
  }
  
  elements() {
    return {
      nodes: () => ({
        filter: jest.fn().mockReturnValue({
          edgesWith: jest.fn().mockReturnValue([]),
          union: jest.fn().mockReturnValue(this.mockCollection)
        })
      })
    };
  }
}

// Mock pour le visualiseur
class VisualizerMock {
  constructor() {
    this.cy = new CytoscapeMock();
  }
}

// Mock pour localStorage
const localStorageMock = (() => {
  let store = {};
  return {
    getItem: jest.fn(key => store[key] || null),
    setItem: jest.fn((key, value) => {
      store[key] = value.toString();
    }),
    clear: jest.fn(() => {
      store = {};
    })
  };
})();

// Mock pour document
global.document = {
  createElement: jest.fn(() => ({
    className: '',
    id: '',
    textContent: '',
    type: '',
    value: '',
    checked: false,
    required: false,
    addEventListener: jest.fn(),
    appendChild: jest.fn()
  })),
  getElementById: jest.fn(() => ({
    className: '',
    id: '',
    textContent: '',
    appendChild: jest.fn(),
    parentNode: {
      id: 'test-container'
    }
  })),
  dispatchEvent: jest.fn(),
  body: {
    appendChild: jest.fn(),
    removeChild: jest.fn()
  }
};

// Mock pour CustomEvent
global.CustomEvent = class CustomEvent {
  constructor(name, options = {}) {
    this.name = name;
    this.detail = options.detail || {};
  }
};

describe('StatusPriorityView', () => {
  let visualizer;
  let view;
  
  beforeEach(async () => {
    // Remplacer localStorage par notre mock
    Object.defineProperty(global, 'localStorage', { value: localStorageMock });
    
    visualizer = new VisualizerMock();
    view = new StatusPriorityView(visualizer);
    await view.initialize();
  });
  
  test('devrait initialiser avec les vues prédéfinies', () => {
    expect(view.state.views.length).toBeGreaterThan(0);
    expect(view.state.views.some(v => v.id === 'high-priority-tasks')).toBe(true);
  });
  
  test('devrait créer une nouvelle vue', () => {
    const viewId = view.createView({
      name: 'Test View',
      description: 'Test Description',
      filters: {
        status: ['completed'],
        priority: ['high']
      }
    });
    
    const createdView = view.getView(viewId);
    expect(createdView).toBeTruthy();
    expect(createdView.name).toBe('Test View');
    expect(createdView.description).toBe('Test Description');
    expect(createdView.filters.status).toEqual(['completed']);
    expect(createdView.filters.priority).toEqual(['high']);
  });
  
  test('devrait mettre à jour une vue existante', () => {
    const viewId = view.createView({
      name: 'Test View',
      description: 'Test Description',
      filters: {
        status: ['completed'],
        priority: ['high']
      }
    });
    
    const updated = view.updateView(viewId, {
      name: 'Updated View',
      description: 'Updated Description',
      filters: {
        status: ['in_progress'],
        priority: ['medium']
      }
    });
    
    expect(updated).toBe(true);
    
    const updatedView = view.getView(viewId);
    expect(updatedView.name).toBe('Updated View');
    expect(updatedView.description).toBe('Updated Description');
    expect(updatedView.filters.status).toEqual(['in_progress']);
    expect(updatedView.filters.priority).toEqual(['medium']);
  });
  
  test('devrait supprimer une vue personnalisée', () => {
    const viewId = view.createView({
      name: 'Test View',
      description: 'Test Description',
      filters: {
        status: ['completed'],
        priority: ['high']
      }
    });
    
    const deleted = view.deleteView(viewId);
    expect(deleted).toBe(true);
    expect(view.getView(viewId)).toBeFalsy();
  });
  
  test('ne devrait pas supprimer une vue prédéfinie', () => {
    const deleted = view.deleteView('high-priority-tasks');
    expect(deleted).toBe(false);
    expect(view.getView('high-priority-tasks')).toBeTruthy();
  });
  
  test('devrait activer et désactiver une vue', () => {
    const activated = view.activateView('high-priority-tasks');
    expect(activated).toBe(true);
    expect(view.state.activeView).toBe('high-priority-tasks');
    
    view.deactivateView();
    expect(view.state.activeView).toBe(null);
  });
  
  test('devrait obtenir le statut d\'un nœud', () => {
    // Créer un nœud de test
    const node = new NodeMock({
      id: 'test-node',
      status: 'completed'
    });
    
    // Obtenir le statut
    const status = view._getNodeStatus(node);
    
    // Vérifier le statut
    expect(status).toBe('completed');
  });
  
  test('devrait obtenir la priorité d\'un nœud', () => {
    // Créer un nœud de test
    const node = new NodeMock({
      id: 'test-node',
      metadata: {
        strategic: { priority: 0.8 }
      }
    });
    
    // Obtenir la priorité
    const priority = view._getNodePriority(node);
    
    // Vérifier la priorité
    expect(priority).toBe(0.8);
  });
  
  test('devrait obtenir le niveau de priorité d\'un nœud', () => {
    // Créer un nœud de test
    const node = new NodeMock({
      id: 'test-node',
      metadata: {
        strategic: { priority: 0.8 }
      }
    });
    
    // Obtenir le niveau de priorité
    const priorityLevel = view._getNodePriorityLevel(node);
    
    // Vérifier le niveau de priorité
    expect(priorityLevel).toBe('high');
  });
});
