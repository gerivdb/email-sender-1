/**
 * Tests pour le module de personnalisation MetroMapCustomizer
 */

import MetroMapCustomizer from '../MetroMapCustomizer.js';

// Mock pour Cytoscape et le visualiseur
class MockCytoscape {
  constructor() {
    this._style = {};
    this._container = document.createElement('div');
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

  container() {
    return this._container;
  }

  getElementById() {
    return {
      style: (key, value) => {
        if (value !== undefined) {
          return {};
        }
        return {};
      }
    };
  }
}

class MockVisualizer {
  constructor() {
    this.cy = new MockCytoscape();
    this.options = {
      layoutOptions: {
        layoutAlgorithm: 'metro',
        preferredDirection: 'horizontal',
        nodeSeparation: 50,
        rankSeparation: 100
      }
    };
  }
}

// Suite de tests pour le constructeur
describe('MetroMapCustomizer - Constructor', () => {
  test('should create an instance with default options', () => {
    const visualizer = new MockVisualizer();
    const customizer = new MetroMapCustomizer(visualizer);

    expect(customizer).toBeDefined();
    expect(customizer.visualizer).toBe(visualizer);
    expect(customizer.cy).toBe(visualizer.cy);
    expect(customizer.options).toBeDefined();
    expect(customizer.options.themes).toBeDefined();
    expect(customizer.options.nodeShapes).toBeDefined();
    expect(customizer.options.nodeSizes).toBeDefined();
    expect(customizer.options.edgeStyles).toBeDefined();
    expect(customizer.options.labelStyles).toBeDefined();
  });

  test('should create an instance with custom options', () => {
    const visualizer = new MockVisualizer();
    const options = {
      themes: {
        custom: {
          name: 'Custom Theme',
          background: '#123456',
          nodeColors: {
            completed: '#AABBCC',
            in_progress: '#DDEEFF',
            planned: '#112233'
          }
        }
      },
      nodeShapes: {
        default: 'rectangle',
        completed: 'star'
      }
    };
    const customizer = new MetroMapCustomizer(visualizer, options);

    expect(customizer.options.themes.custom).toBeDefined();
    expect(customizer.options.themes.custom.name).toBe('Custom Theme');
    expect(customizer.options.themes.custom.background).toBe('#123456');
    expect(customizer.options.nodeShapes.default).toBe('rectangle');
    expect(customizer.options.nodeShapes.completed).toBe('star');

    // Les options non spécifiées doivent avoir leurs valeurs par défaut
    expect(customizer.options.nodeSizes).toBeDefined();
    expect(customizer.options.edgeStyles).toBeDefined();
    expect(customizer.options.labelStyles).toBeDefined();
  });

  test('should initialize state correctly', () => {
    const visualizer = new MockVisualizer();
    const customizer = new MetroMapCustomizer(visualizer);

    expect(customizer.state).toBeDefined();
    expect(customizer.state.currentTheme).toBe('default');
    expect(customizer.state.customNodeStyles).toBeInstanceOf(Map);
    expect(customizer.state.customEdgeStyles).toBeInstanceOf(Map);
    expect(customizer.state.customGlobalStyles).toEqual({});
  });

  test('should apply default theme during construction', () => {
    const visualizer = new MockVisualizer();

    // Espionner la méthode applyTheme
    const spy = jest.spyOn(MetroMapCustomizer.prototype, 'applyTheme');

    const customizer = new MetroMapCustomizer(visualizer);

    // Vérifier que applyTheme est appelé avec le thème par défaut
    expect(spy).toHaveBeenCalledWith('default');

    spy.mockRestore();
  });
});

// Suite de tests pour la méthode applyTheme
describe('MetroMapCustomizer - applyTheme', () => {
  test('should apply theme to container and elements', () => {
    const visualizer = new MockVisualizer();
    const customizer = new MetroMapCustomizer(visualizer);

    // S'assurer que les thèmes sont correctement définis
    customizer.options.themes = {
      default: {
        name: 'Défaut',
        background: '#ffffff',
        nodeColors: {
          completed: '#4CAF50',
          in_progress: '#2196F3',
          planned: '#9E9E9E'
        },
        nodeBorderColors: {
          completed: '#2E7D32',
          in_progress: '#1565C0',
          planned: '#616161'
        },
        edgeColors: {
          default: '#666666'
        },
        fontFamily: 'Segoe UI, Tahoma, Geneva, Verdana, sans-serif',
        fontSize: 12
      },
      dark: {
        name: 'Sombre',
        background: '#333333',
        nodeColors: {
          completed: '#81C784',
          in_progress: '#64B5F6',
          planned: '#E0E0E0'
        },
        nodeBorderColors: {
          completed: '#4CAF50',
          in_progress: '#2196F3',
          planned: '#9E9E9E'
        },
        edgeColors: {
          default: '#BBBBBB'
        },
        fontFamily: 'Segoe UI, Tahoma, Geneva, Verdana, sans-serif',
        fontSize: 12,
        textColor: '#FFFFFF'
      }
    };

    // Remplacer les méthodes par des mocks
    customizer._applyCustomStyles = jest.fn();
    customizer._triggerEvent = jest.fn();

    // Appeler la méthode
    customizer.applyTheme('dark');

    // Vérifier que l'état est mis à jour
    expect(customizer.state.currentTheme).toBe('dark');

    // Vérifier que les styles personnalisés sont appliqués
    expect(customizer._applyCustomStyles).toHaveBeenCalled();

    // Vérifier que l'événement est déclenché
    expect(customizer._triggerEvent).toHaveBeenCalledWith('themeChange', { theme: 'dark' });
  });
});

// Suite de tests pour les méthodes de personnalisation
describe('MetroMapCustomizer - Customization Methods', () => {
  test('setNodeShape should update node shapes', () => {
    const visualizer = new MockVisualizer();
    const customizer = new MetroMapCustomizer(visualizer);

    // Remplacer la méthode _applyNodeShapes par un mock
    customizer._applyNodeShapes = jest.fn();

    // Appeler la méthode
    const result = customizer.setNodeShape('rectangle');

    // Vérifier que les options sont mises à jour
    expect(customizer.options.nodeShapes.default).toBe('rectangle');

    // Vérifier que _applyNodeShapes est appelé
    expect(customizer._applyNodeShapes).toHaveBeenCalled();

    // Vérifier que la méthode retourne this pour le chaînage
    expect(result).toBe(customizer);
  });

  test('setNodeSize should update node sizes', () => {
    const visualizer = new MockVisualizer();
    const customizer = new MetroMapCustomizer(visualizer);

    // Remplacer la méthode _applyNodeSizes par un mock
    customizer._applyNodeSizes = jest.fn();

    // Appeler la méthode
    const result = customizer.setNodeSize(40);

    // Vérifier que les options sont mises à jour
    expect(customizer.options.nodeSizes.default).toBe(40);

    // Vérifier que _applyNodeSizes est appelé
    expect(customizer._applyNodeSizes).toHaveBeenCalled();

    // Vérifier que la méthode retourne this pour le chaînage
    expect(result).toBe(customizer);
  });
});

// Suite de tests pour les méthodes privées
describe('MetroMapCustomizer - Private Methods', () => {
  test('_applyNodeShapes should apply shapes to nodes', () => {
    const visualizer = new MockVisualizer();
    const customizer = new MetroMapCustomizer(visualizer);

    // Définir des formes personnalisées
    customizer.options.nodeShapes.custom = {
      'node1': 'star',
      'node2': 'triangle'
    };

    // Remplacer les méthodes par des mocks
    visualizer.cy.style = jest.fn().mockReturnThis();
    visualizer.cy.selector = jest.fn().mockReturnThis();
    visualizer.cy.update = jest.fn();

    // Appeler la méthode
    customizer._applyNodeShapes();

    // Vérifier que les styles sont appliqués
    expect(visualizer.cy.style).toHaveBeenCalled();
    expect(visualizer.cy.selector).toHaveBeenCalled();
    expect(visualizer.cy.update).toHaveBeenCalled();
  });
});

// Exécuter les tests
// Note: Ces tests sont conçus pour être exécutés avec Jest
// Pour les exécuter, utilisez la commande: npm test
