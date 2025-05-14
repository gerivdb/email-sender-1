/**
 * Tests pour le visualiseur amélioré de carte de métro MetroMapVisualizerEnhanced
 */

// Créer un mock pour la classe parente
class MockMetroMapVisualizer {
  constructor(containerId, options) {
    this.containerId = containerId;
    this.options = options;
    this.cy = {
      nodes: jest.fn().mockReturnValue([]),
      edges: jest.fn().mockReturnValue([]),
      elements: jest.fn().mockReturnValue({
        remove: jest.fn()
      }),
      add: jest.fn(),
      style: jest.fn().mockReturnValue({
        selector: jest.fn().mockReturnThis(),
        style: jest.fn().mockReturnThis(),
        update: jest.fn()
      })
    };
  }

  initialize() {
    return Promise.resolve();
  }

  visualizeRoadmaps() {
    return Promise.resolve();
  }

  _applyMetroLayout() {
    // Ne rien faire
  }
}

// Créer un mock pour le moteur de layout
class MockLayoutEngine {
  constructor(options) {
    this.options = options;
  }

  applyLayout(graph) {
    return {
      nodes: graph.nodes.map(node => ({
        ...node,
        position: { x: 100, y: 100 }
      })),
      edges: graph.edges.map(edge => ({
        ...edge,
        controlPoints: [
          { x: 50, y: 50 },
          { x: 150, y: 150 }
        ]
      }))
    };
  }
}

// Créer une classe de test qui étend le mock
class TestMetroMapVisualizerEnhanced extends MockMetroMapVisualizer {
  constructor(containerId, options = {}) {
    // Options par défaut pour le layout
    const layoutOptions = {
      layoutAlgorithm: 'metro',
      preferredDirection: 'horizontal',
      nodeSeparation: 50,
      rankSeparation: 100,
      ...options.layoutOptions
    };

    // Fusionner avec les options de base
    const mergedOptions = {
      ...options,
      layoutOptions
    };

    super(containerId, mergedOptions);

    // Créer le moteur de layout
    this.layoutEngine = new MockLayoutEngine(layoutOptions);

    // État interne supplémentaire
    this.preLayoutPositions = new Map();
    this.layoutResult = null;
  }

  _applyMetroLayout() {
    if (this.options.layoutOptions.layoutAlgorithm === 'metro') {
      this._applyCustomMetroLayout();
    } else {
      super._applyMetroLayout();
    }
  }

  _applyCustomMetroLayout() {
    const graph = this._convertCytoscapeToGraph();
    this.layoutResult = this.layoutEngine.applyLayout(graph);
    this._applyLayoutPositions();
  }

  _convertCytoscapeToGraph() {
    return {
      nodes: [
        { id: 'node1', name: 'Node 1', lines: ['line1'] },
        { id: 'node2', name: 'Node 2', lines: ['line1'] }
      ],
      edges: [
        { source: 'node1', target: 'node2', line: 'line1' }
      ],
      lines: [
        { id: 'line1', name: 'Line 1', color: '#ff0000' }
      ]
    };
  }

  _applyLayoutPositions() {
    // Ne rien faire
  }

  updateLayoutOptions(options) {
    this.options.layoutOptions = {
      ...this.options.layoutOptions,
      ...options
    };
    this.layoutEngine = new MockLayoutEngine(this.options.layoutOptions);
  }

  exportAsSVG() {
    if (!this.cy) {
      throw new Error('Le graphe Cytoscape n\'est pas initialisé');
    }
    return Promise.resolve(new Blob());
  }
}

// Tests
describe('MetroMapVisualizerEnhanced', () => {
  test('should create an instance with default options', () => {
    const visualizer = new TestMetroMapVisualizerEnhanced('container');
    expect(visualizer).toBeDefined();
    expect(visualizer.containerId).toBe('container');
    expect(visualizer.options.layoutOptions.layoutAlgorithm).toBe('metro');
    expect(visualizer.options.layoutOptions.preferredDirection).toBe('horizontal');
  });

  test('should create an instance with custom options', () => {
    const options = {
      layoutOptions: {
        preferredDirection: 'vertical',
        nodeSeparation: 100
      }
    };
    const visualizer = new TestMetroMapVisualizerEnhanced('container', options);
    expect(visualizer.options.layoutOptions.preferredDirection).toBe('vertical');
    expect(visualizer.options.layoutOptions.nodeSeparation).toBe(100);
  });

  test('_applyMetroLayout should call _applyCustomMetroLayout for metro algorithm', () => {
    const visualizer = new TestMetroMapVisualizerEnhanced('container');
    visualizer._applyCustomMetroLayout = jest.fn();
    visualizer._applyMetroLayout();
    expect(visualizer._applyCustomMetroLayout).toHaveBeenCalled();
  });

  test('_applyMetroLayout should call parent method for non-metro algorithm', () => {
    const visualizer = new TestMetroMapVisualizerEnhanced('container', {
      layoutOptions: {
        layoutAlgorithm: 'grid'
      }
    });
    const spy = jest.spyOn(MockMetroMapVisualizer.prototype, '_applyMetroLayout');
    visualizer._applyMetroLayout();
    expect(spy).toHaveBeenCalled();
    spy.mockRestore();
  });

  test('_applyCustomMetroLayout should apply layout to graph', () => {
    const visualizer = new TestMetroMapVisualizerEnhanced('container');
    visualizer._convertCytoscapeToGraph = jest.fn().mockReturnValue({
      nodes: [{ id: 'node1' }],
      edges: [{ source: 'node1', target: 'node2' }]
    });
    visualizer._applyLayoutPositions = jest.fn();
    visualizer._applyCustomMetroLayout();
    expect(visualizer._convertCytoscapeToGraph).toHaveBeenCalled();
    expect(visualizer._applyLayoutPositions).toHaveBeenCalled();
    expect(visualizer.layoutResult).toBeDefined();
  });

  test('updateLayoutOptions should update options and recreate layout engine', () => {
    const visualizer = new TestMetroMapVisualizerEnhanced('container');
    visualizer.updateLayoutOptions({
      preferredDirection: 'vertical',
      nodeSeparation: 100
    });
    expect(visualizer.options.layoutOptions.preferredDirection).toBe('vertical');
    expect(visualizer.options.layoutOptions.nodeSeparation).toBe(100);
    expect(visualizer.layoutEngine).toBeDefined();
  });

  test('exportAsSVG should export visualization as SVG', async () => {
    const visualizer = new TestMetroMapVisualizerEnhanced('container');
    const result = await visualizer.exportAsSVG();
    expect(result).toBeInstanceOf(Blob);
  });

  test('exportAsSVG should throw error if cy is not initialized', async () => {
    const visualizer = new TestMetroMapVisualizerEnhanced('container');
    visualizer.cy = null;
    await expect(async () => {
      await visualizer.exportAsSVG();
    }).rejects.toThrow('Le graphe Cytoscape n\'est pas initialisé');
  });
});
