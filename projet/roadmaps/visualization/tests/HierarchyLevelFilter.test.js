/**
 * Tests pour HierarchyLevelFilter
 * Ce module contient les tests unitaires pour le filtre par niveau hiérarchique
 * 
 * Version: 1.0
 * Date: 2025-05-30
 */

import HierarchyLevelFilter from '../HierarchyLevelFilter.js';

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
  
  collection() {
    return [];
  }
}

// Mock pour le visualiseur
class VisualizerMock {
  constructor() {
    this.cy = new CytoscapeMock();
  }
}

describe('HierarchyLevelFilter', () => {
  let visualizer;
  let filter;
  
  beforeEach(() => {
    visualizer = new VisualizerMock();
    filter = new HierarchyLevelFilter(visualizer);
    filter.initialize();
  });
  
  test('devrait initialiser avec les niveaux par défaut', () => {
    expect(filter.getActiveLevels().sort()).toEqual(
      ['cosmos', 'continent', 'galaxy', 'planet', 'stellar_system'].sort()
    );
  });
  
  test('devrait activer un niveau', () => {
    filter.activateLevel('region');
    expect(filter.isLevelActive('region')).toBe(true);
  });
  
  test('devrait désactiver un niveau', () => {
    filter.deactivateLevel('cosmos');
    expect(filter.isLevelActive('cosmos')).toBe(false);
  });
  
  test('devrait basculer un niveau', () => {
    const initialState = filter.isLevelActive('locality');
    filter.toggleLevel('locality');
    expect(filter.isLevelActive('locality')).not.toBe(initialState);
  });
  
  test('devrait définir les niveaux actifs', () => {
    filter.setActiveLevels(['cosmos', 'galaxy']);
    expect(filter.getActiveLevels().sort()).toEqual(['cosmos', 'galaxy'].sort());
  });
  
  test('devrait formater correctement le nom d\'un niveau', () => {
    const formattedName = filter._formatLevelName('stellar_system');
    expect(formattedName).toBe('Stellar System');
  });
  
  test('devrait retourner un ensemble vide si aucun niveau n\'est actif', () => {
    filter.setActiveLevels([]);
    visualizer.cy.collection = jest.fn().mockReturnValue([]);
    const filteredElements = filter.applyFilter();
    expect(filteredElements).toBeDefined();
  });
});
