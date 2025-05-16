/**
 * Tests pour ThematicFilter et TemporalFilter
 * Ce module contient les tests unitaires pour les filtres thématiques et temporels
 * 
 * Version: 1.0
 * Date: 2025-05-30
 */

import { ThematicFilter, TemporalFilter } from '../ThematicTemporalFilter.js';

// Mock pour un nœud Cytoscape
class NodeMock {
  constructor(data) {
    this.nodeData = data;
  }
  
  data(field) {
    if (!field) {
      return this.nodeData;
    }
    
    // Accéder aux champs imbriqués (par exemple, 'metadata.themes')
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
        }),
        forEach: jest.fn()
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

describe('ThematicFilter', () => {
  let visualizer;
  let filter;
  
  beforeEach(() => {
    visualizer = new VisualizerMock();
    filter = new ThematicFilter(visualizer, {
      availableThemes: ['architecture', 'cognitive', 'orchestration', 'intégration', 'déploiement']
    });
  });
  
  test('devrait initialiser avec les thèmes disponibles', async () => {
    await filter.initialize();
    expect(filter.state.availableThemes.sort()).toEqual(
      ['architecture', 'cognitive', 'orchestration', 'intégration', 'déploiement'].sort()
    );
  });
  
  test('devrait activer un thème', async () => {
    await filter.initialize();
    filter.setActiveThemes([]);
    filter.activateTheme('architecture');
    expect(filter.isThemeActive('architecture')).toBe(true);
  });
  
  test('devrait désactiver un thème', async () => {
    await filter.initialize();
    filter.deactivateTheme('architecture');
    expect(filter.isThemeActive('architecture')).toBe(false);
  });
  
  test('devrait basculer un thème', async () => {
    await filter.initialize();
    const initialState = filter.isThemeActive('cognitive');
    filter.toggleTheme('cognitive');
    expect(filter.isThemeActive('cognitive')).not.toBe(initialState);
  });
  
  test('devrait définir les thèmes actifs', async () => {
    await filter.initialize();
    filter.setActiveThemes(['architecture', 'cognitive']);
    expect(filter.getActiveThemes().sort()).toEqual(['architecture', 'cognitive'].sort());
  });
  
  test('devrait extraire les thèmes d\'un nœud', async () => {
    await filter.initialize();
    
    // Créer un nœud de test
    const node = new NodeMock({
      id: 'test-node',
      metadata: {
        themes: { 'architecture': 1.0, 'cognitive': 0.9 }
      }
    });
    
    // Extraire les thèmes
    const themes = filter._getNodeThemes(node);
    
    // Vérifier les thèmes
    expect(themes).toContain('architecture');
    expect(themes).toContain('cognitive');
  });
});

describe('TemporalFilter', () => {
  let visualizer;
  let filter;
  
  beforeEach(() => {
    visualizer = new VisualizerMock();
    filter = new TemporalFilter(visualizer);
    filter.initialize();
  });
  
  test('devrait initialiser avec les horizons par défaut', () => {
    expect(filter.getActiveHorizons().sort()).toEqual(
      ['immediate', 'short_term', 'medium_term', 'long_term', 'strategic'].sort()
    );
  });
  
  test('devrait activer un horizon', () => {
    filter.setActiveHorizons([]);
    filter.activateHorizon('short_term');
    expect(filter.isHorizonActive('short_term')).toBe(true);
  });
  
  test('devrait désactiver un horizon', () => {
    filter.deactivateHorizon('long_term');
    expect(filter.isHorizonActive('long_term')).toBe(false);
  });
  
  test('devrait basculer un horizon', () => {
    const initialState = filter.isHorizonActive('medium_term');
    filter.toggleHorizon('medium_term');
    expect(filter.isHorizonActive('medium_term')).not.toBe(initialState);
  });
  
  test('devrait définir les horizons actifs', () => {
    filter.setActiveHorizons(['short_term', 'medium_term']);
    expect(filter.getActiveHorizons().sort()).toEqual(['short_term', 'medium_term'].sort());
  });
  
  test('devrait obtenir l\'horizon temporel d\'un nœud', () => {
    // Créer un nœud de test
    const node = new NodeMock({
      id: 'test-node',
      metadata: {
        temporal: { horizon: 'medium_term' }
      }
    });
    
    // Obtenir l'horizon
    const horizon = filter._getNodeHorizon(node);
    
    // Vérifier l'horizon
    expect(horizon).toBe('medium_term');
  });
  
  test('devrait retourner null si le nœud n\'a pas d\'horizon', () => {
    // Créer un nœud de test sans horizon
    const node = new NodeMock({
      id: 'test-node'
    });
    
    // Obtenir l'horizon
    const horizon = filter._getNodeHorizon(node);
    
    // Vérifier que l'horizon est null
    expect(horizon).toBeNull();
  });
  
  test('devrait formater correctement le nom d\'un horizon', () => {
    const formattedName = filter._formatHorizonName('short_term');
    expect(formattedName).toBe('Short Term');
  });
});
