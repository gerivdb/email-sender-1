/**
 * Tests pour CustomFiltersManager
 * Ce module contient les tests unitaires pour le gestionnaire de filtres personnalisés
 *
 * Version: 1.0
 * Date: 2025-05-30
 */

import CustomFiltersManager from '../CustomFiltersManager.js';
import HierarchyLevelFilter from '../HierarchyLevelFilter.js';
import { ThematicFilter, TemporalFilter } from '../ThematicTemporalFilter.js';
import StatusPriorityView from '../StatusPriorityView.js';

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
      }),
      addClass: jest.fn(),
      removeClass: jest.fn()
    };
  }
}

// Mock pour le visualiseur
class VisualizerMock {
  constructor() {
    this.cy = new CytoscapeMock();
  }

  updateLayout() {}
}

// Mock pour les filtres
jest.mock('../HierarchyLevelFilter.js', () => {
  return jest.fn().mockImplementation(() => {
    return {
      initialize: jest.fn().mockReturnThis(),
      activateLevel: jest.fn().mockReturnThis(),
      deactivateLevel: jest.fn().mockReturnThis(),
      toggleLevel: jest.fn().mockReturnThis(),
      setActiveLevels: jest.fn().mockReturnThis(),
      getActiveLevels: jest.fn().mockReturnValue(['cosmos', 'galaxy']),
      isLevelActive: jest.fn().mockReturnValue(true),
      applyFilter: jest.fn().mockReturnValue([]),
      createUI: jest.fn().mockReturnThis()
    };
  });
});

jest.mock('../ThematicTemporalFilter.js', () => {
  return {
    ThematicFilter: jest.fn().mockImplementation(() => {
      return {
        initialize: jest.fn().mockResolvedValue({}),
        activateTheme: jest.fn().mockReturnThis(),
        deactivateTheme: jest.fn().mockReturnThis(),
        toggleTheme: jest.fn().mockReturnThis(),
        setActiveThemes: jest.fn().mockReturnThis(),
        getActiveThemes: jest.fn().mockReturnValue(['architecture', 'cognitive']),
        isThemeActive: jest.fn().mockReturnValue(true),
        applyFilter: jest.fn().mockReturnValue([]),
        createUI: jest.fn().mockReturnThis()
      };
    }),
    TemporalFilter: jest.fn().mockImplementation(() => {
      return {
        initialize: jest.fn().mockReturnThis(),
        activateHorizon: jest.fn().mockReturnThis(),
        deactivateHorizon: jest.fn().mockReturnThis(),
        toggleHorizon: jest.fn().mockReturnThis(),
        setActiveHorizons: jest.fn().mockReturnThis(),
        getActiveHorizons: jest.fn().mockReturnValue(['short_term', 'medium_term']),
        isHorizonActive: jest.fn().mockReturnValue(true),
        applyFilter: jest.fn().mockReturnValue([]),
        createUI: jest.fn().mockReturnThis()
      };
    })
  };
});

jest.mock('../StatusPriorityView.js', () => {
  return jest.fn().mockImplementation(() => {
    return {
      initialize: jest.fn().mockResolvedValue({}),
      createView: jest.fn().mockReturnValue('custom-view-1'),
      updateView: jest.fn().mockReturnValue(true),
      deleteView: jest.fn().mockReturnValue(true),
      getViews: jest.fn().mockReturnValue([]),
      getView: jest.fn().mockReturnValue({}),
      activateView: jest.fn().mockReturnValue(true),
      deactivateView: jest.fn().mockReturnThis(),
      getActiveView: jest.fn().mockReturnValue({}),
      applyActiveView: jest.fn().mockReturnValue([]),
      applyViewFilters: jest.fn().mockReturnValue([]),
      createUI: jest.fn().mockReturnThis()
    };
  });
});

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
    innerHTML: ''
  })),
  addEventListener: jest.fn(),
  dispatchEvent: jest.fn()
};

// Transformer les méthodes en mocks Jest
document.getElementById = jest.fn(document.getElementById);
document.addEventListener = jest.fn(document.addEventListener);

describe('CustomFiltersManager', () => {
  let visualizer;
  let manager;

  beforeEach(async () => {
    visualizer = new VisualizerMock();
    manager = new CustomFiltersManager(visualizer);
    await manager.initialize();
  });

  test('devrait initialiser tous les filtres', () => {
    expect(manager.state.filtersInitialized).toBe(true);
    expect(HierarchyLevelFilter).toHaveBeenCalled();
    expect(ThematicFilter).toHaveBeenCalled();
    expect(TemporalFilter).toHaveBeenCalled();
    expect(StatusPriorityView).toHaveBeenCalled();
  });

  test('devrait activer et désactiver un filtre', () => {
    manager.deactivateFilter('hierarchyLevel');
    expect(manager.isFilterActive('hierarchyLevel')).toBe(false);

    manager.activateFilter('hierarchyLevel');
    expect(manager.isFilterActive('hierarchyLevel')).toBe(true);
  });

  test('devrait basculer un filtre', () => {
    const initialState = manager.isFilterActive('thematic');
    manager.toggleFilter('thematic');
    expect(manager.isFilterActive('thematic')).not.toBe(initialState);
  });

  test('devrait réinitialiser tous les filtres', () => {
    manager.resetFilters();
    expect(manager.hierarchyLevelFilter.initialize).toHaveBeenCalled();
    expect(manager.thematicFilter.initialize).toHaveBeenCalled();
    expect(manager.temporalFilter.initialize).toHaveBeenCalled();
    expect(manager.statusPriorityView.deactivateView).toHaveBeenCalled();
  });

  test('devrait appliquer tous les filtres actifs', () => {
    const filteredElements = manager.applyFilters();
    expect(filteredElements).toBeDefined();
    expect(manager.hierarchyLevelFilter.applyFilter).toHaveBeenCalled();
    expect(manager.thematicFilter.applyFilter).toHaveBeenCalled();
    expect(manager.temporalFilter.applyFilter).toHaveBeenCalled();
    expect(manager.statusPriorityView.applyActiveView).toHaveBeenCalled();
  });

  test('devrait créer l\'interface utilisateur', () => {
    // Simuler que getElementById retourne un élément valide
    document.getElementById.mockReturnValueOnce({
      className: '',
      id: 'test-container',
      textContent: '',
      appendChild: jest.fn(),
      innerHTML: ''
    });

    const result = manager.createUI('test-container');
    expect(result).toBe(manager);
    expect(document.getElementById).toHaveBeenCalledWith('test-container');
    expect(manager.hierarchyLevelFilter.createUI).toHaveBeenCalled();
    expect(manager.thematicFilter.createUI).toHaveBeenCalled();
    expect(manager.temporalFilter.createUI).toHaveBeenCalled();
    expect(manager.statusPriorityView.createUI).toHaveBeenCalled();
  });

  test('devrait enregistrer les événements', () => {
    const result = manager.registerEvents();
    expect(result).toBe(manager);
    expect(document.addEventListener).toHaveBeenCalledTimes(4);
  });
});
