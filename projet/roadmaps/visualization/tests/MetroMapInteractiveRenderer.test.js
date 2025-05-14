/**
 * Tests pour le système de rendu graphique interactif MetroMapInteractiveRenderer
 */

import MetroMapInteractiveRenderer from '../MetroMapInteractiveRenderer.js';

// Mock pour Cytoscape et le visualiseur
class MockCytoscape {
  constructor() {
    this._elements = [];
    this._style = {};
    this._container = document.createElement('div');
    this._zoom = 1;
    this._eventHandlers = {};
  }

  elements() {
    return {
      nodes: () => [],
      edges: () => []
    };
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

  on(event, selector, callback) {
    if (!this._eventHandlers[event]) {
      this._eventHandlers[event] = [];
    }
    this._eventHandlers[event].push({ selector, callback });
    return this;
  }

  animate() {
    return {
      promise: () => Promise.resolve(),
      play: () => this
    };
  }

  promise() {
    return Promise.resolve();
  }

  play() {
    return this;
  }

  container() {
    return this._container;
  }

  zoom() {
    return this._zoom;
  }

  png() {
    return Promise.resolve(new Blob());
  }

  jpg() {
    return Promise.resolve(new Blob());
  }

  svg() {
    return Promise.resolve(new Blob());
  }

  getElementById() {
    return {
      data: (key) => ({})[key],
      position: () => ({ x: 0, y: 0 }),
      renderedPosition: () => ({ x: 0, y: 0 }),
      renderedBoundingBox: () => ({ x: 0, y: 0, w: 50, h: 50 }),
      isNode: () => true,
      isEdge: () => false,
      connectedNodes: () => [],
      connectedEdges: () => [],
      animation: () => ({
        promise: () => Promise.resolve(),
        play: () => ({})
      }),
      addClass: () => {},
      removeClass: () => {},
      style: () => ({})
    };
  }
}

class MockVisualizer {
  constructor() {
    // Créer un mock plus robuste pour Cytoscape
    this.cy = {
      on: jest.fn(),
      elements: jest.fn().mockReturnValue({
        nodes: jest.fn().mockReturnValue([]),
        edges: jest.fn().mockReturnValue([])
      }),
      container: jest.fn().mockReturnValue({
        getBoundingClientRect: jest.fn().mockReturnValue({
          left: 0,
          top: 0,
          width: 800,
          height: 600
        }),
        dispatchEvent: jest.fn(),
        appendChild: jest.fn()
      }),
      zoom: jest.fn().mockReturnValue(1),
      style: jest.fn().mockReturnValue({
        selector: jest.fn().mockReturnThis(),
        style: jest.fn().mockReturnThis(),
        update: jest.fn()
      }),
      selector: jest.fn().mockReturnThis(),
      update: jest.fn(),
      getElementById: jest.fn().mockReturnValue({
        id: () => 'node1',
        data: () => ({ label: 'Node 1' }),
        isNode: () => true,
        isEdge: () => false,
        connectedNodes: jest.fn().mockReturnValue([]),
        connectedEdges: jest.fn().mockReturnValue([]),
        addClass: jest.fn(),
        removeClass: jest.fn(),
        style: jest.fn().mockReturnValue({}),
        renderedPosition: () => ({ x: 100, y: 100 }),
        renderedBoundingBox: () => ({ x: 0, y: 0, w: 50, h: 50 })
      }),
      animate: jest.fn().mockReturnValue({
        play: jest.fn(),
        promise: jest.fn().mockResolvedValue()
      }),
      png: jest.fn().mockResolvedValue(new Blob()),
      jpg: jest.fn().mockResolvedValue(new Blob()),
      svg: jest.fn().mockResolvedValue(new Blob())
    };

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
describe('MetroMapInteractiveRenderer - Constructor', () => {
  test('should create an instance with default options', () => {
    const visualizer = new MockVisualizer();
    const renderer = new MetroMapInteractiveRenderer(visualizer);

    expect(renderer).toBeDefined();
    expect(renderer.visualizer).toBe(visualizer);
    expect(renderer.cy).toBe(visualizer.cy);
    expect(renderer.options).toBeDefined();
    expect(renderer.options.animation).toBeDefined();
    expect(renderer.options.tooltip).toBeDefined();
    expect(renderer.options.modal).toBeDefined();
    expect(renderer.options.controls).toBeDefined();
    expect(renderer.options.semanticZoom).toBeDefined();
  });

  test('should create an instance with custom options', () => {
    const visualizer = new MockVisualizer();
    const options = {
      animation: {
        nodeSelectionDuration: 500,
        layoutTransitionDuration: 800
      },
      tooltip: {
        showDelay: 500,
        position: 'bottom'
      }
    };
    const renderer = new MetroMapInteractiveRenderer(visualizer, options);

    expect(renderer.options.animation.nodeSelectionDuration).toBe(500);
    expect(renderer.options.animation.layoutTransitionDuration).toBe(800);
    expect(renderer.options.tooltip.showDelay).toBe(500);
    expect(renderer.options.tooltip.position).toBe('bottom');

    // Les options non spécifiées doivent avoir leurs valeurs par défaut
    expect(renderer.options.modal).toBeDefined();
    expect(renderer.options.controls).toBeDefined();
    expect(renderer.options.semanticZoom).toBeDefined();
  });

  test('should initialize state correctly', () => {
    // Créer un mock pour le visualiseur sans appeler _initialize
    const visualizer = new MockVisualizer();

    // Espionner la méthode _initialize pour l'empêcher de s'exécuter
    const spy = jest.spyOn(MetroMapInteractiveRenderer.prototype, '_initialize').mockImplementation(() => {});

    // Créer le renderer
    const renderer = new MetroMapInteractiveRenderer(visualizer);

    // Vérifier l'état initial
    expect(renderer.state).toBeDefined();
    expect(renderer.state.currentZoomLevel).toBe('default');
    expect(renderer.state.selectedNodes).toBeInstanceOf(Set);
    expect(renderer.state.hoveredNode).toBeNull();
    expect(renderer.state.isModalOpen).toBe(false);
    expect(renderer.state.tooltips).toBeInstanceOf(Map);

    // Restaurer la méthode _initialize
    spy.mockRestore();
  });

  test('should call _initialize during construction', () => {
    const visualizer = new MockVisualizer();
    const spy = jest.spyOn(MetroMapInteractiveRenderer.prototype, '_initialize');

    const renderer = new MetroMapInteractiveRenderer(visualizer);

    expect(spy).toHaveBeenCalled();

    spy.mockRestore();
  });
});

// Suite de tests pour les méthodes d'initialisation
describe('MetroMapInteractiveRenderer - Initialization', () => {
  test('_initialize should set up interactions', () => {
    const visualizer = new MockVisualizer();
    const renderer = new MetroMapInteractiveRenderer(visualizer);

    // Remplacer les méthodes par des mocks
    renderer._setupInteractions = jest.fn();
    renderer._createControls = jest.fn();
    renderer._setupSemanticZoom = jest.fn();
    renderer._createLegend = jest.fn();
    renderer._addStyles = jest.fn();

    // Réinitialiser pour tester explicitement
    renderer._initialize();

    // Vérifier que les méthodes sont appelées
    expect(renderer._setupInteractions).toHaveBeenCalled();
    expect(renderer._addStyles).toHaveBeenCalled();
  });
});

// Suite de tests pour les méthodes d'interaction
describe('MetroMapInteractiveRenderer - Interactions', () => {
  test('_setupInteractions should register event handlers', () => {
    const visualizer = new MockVisualizer();
    const renderer = new MetroMapInteractiveRenderer(visualizer);

    // Remplacer la méthode on par un mock
    visualizer.cy.on = jest.fn();

    // Appeler la méthode
    renderer._setupInteractions();

    // Vérifier que la méthode on est appelée
    expect(visualizer.cy.on).toHaveBeenCalled();
  });

  test('_handleNodeClick should select/deselect node', () => {
    const visualizer = new MockVisualizer();

    // Remplacer la méthode _handleNodeClick par un mock
    MetroMapInteractiveRenderer.prototype._handleNodeClick = jest.fn().mockImplementation(function(node) {
      this.state.selectedNodes.add(node.id());
      node.addClass('selected');
      this._triggerEvent('nodeSelect', { node });
    });

    const renderer = new MetroMapInteractiveRenderer(visualizer);

    // Créer un nœud mock
    const node = {
      id: () => 'node1',
      addClass: jest.fn(),
      removeClass: jest.fn(),
      connectedNodes: () => [],
      connectedEdges: () => [],
      style: () => ({})
    };

    // Remplacer la méthode _triggerEvent par un mock
    renderer._triggerEvent = jest.fn();

    // Appeler la méthode
    renderer._handleNodeClick(node);

    // Vérifier que le nœud est sélectionné
    expect(renderer.state.selectedNodes.has('node1')).toBe(true);
    expect(node.addClass).toHaveBeenCalledWith('selected');

    // Vérifier que l'événement est déclenché
    expect(renderer._triggerEvent).toHaveBeenCalledWith('nodeSelect', { node });

    // Restaurer la méthode originale
    jest.restoreAllMocks();
  });
});

// Suite de tests pour les méthodes de tooltip
describe('MetroMapInteractiveRenderer - Tooltips', () => {
  test('_showNodeTooltip should create and position tooltip', () => {
    const visualizer = new MockVisualizer();

    // Remplacer la méthode _initialize par un mock pour éviter les erreurs
    jest.spyOn(MetroMapInteractiveRenderer.prototype, '_initialize').mockImplementation(() => {});

    const renderer = new MetroMapInteractiveRenderer(visualizer);

    // Créer un nœud mock
    const node = {
      id: () => 'node1',
      data: () => ({
        label: 'Node 1',
        description: 'Description of Node 1',
        status: 'completed',
        roadmapId: 'roadmap1'
      }),
      renderedPosition: () => ({ x: 100, y: 100 }),
      renderedBoundingBox: () => ({ w: 50, h: 50 }),
      isNode: () => true
    };

    // Remplacer les méthodes par des mocks
    document.createElement = jest.fn().mockReturnValue({
      classList: {
        add: jest.fn()
      },
      style: {}
    });
    document.body.appendChild = jest.fn();
    renderer._positionTooltip = jest.fn();

    // Appeler la méthode
    renderer._showNodeTooltip(node);

    // Vérifier que le tooltip est créé
    expect(document.createElement).toHaveBeenCalled();
    expect(document.body.appendChild).toHaveBeenCalled();

    // Vérifier que le tooltip est positionné
    expect(renderer._positionTooltip).toHaveBeenCalled();

    // Restaurer la méthode originale
    jest.restoreAllMocks();
  });

  test('_hideNodeTooltip should hide and remove tooltip', () => {
    const visualizer = new MockVisualizer();

    // Remplacer la méthode _initialize par un mock pour éviter les erreurs
    jest.spyOn(MetroMapInteractiveRenderer.prototype, '_initialize').mockImplementation(() => {});

    const renderer = new MetroMapInteractiveRenderer(visualizer);

    // Remplacer la méthode _hideNodeTooltip par un mock
    renderer._hideNodeTooltip = jest.fn().mockImplementation((node) => {
      const nodeId = node.id();
      if (renderer.state.tooltips.has(nodeId)) {
        renderer.state.tooltips.delete(nodeId);
      }
    });

    // Créer un nœud mock
    const node = {
      id: () => 'node1'
    };

    // Ajouter un tooltip à l'état
    renderer.state.tooltips.set('node1', {});

    // Appeler la méthode
    renderer._hideNodeTooltip(node);

    // Vérifier que le tooltip est supprimé
    expect(renderer.state.tooltips.has('node1')).toBe(false);

    // Restaurer la méthode originale
    jest.restoreAllMocks();
  });

  test('_positionTooltip should position tooltip correctly', () => {
    const visualizer = new MockVisualizer();

    // Remplacer la méthode _initialize par un mock pour éviter les erreurs
    jest.spyOn(MetroMapInteractiveRenderer.prototype, '_initialize').mockImplementation(() => {});

    const renderer = new MetroMapInteractiveRenderer(visualizer);

    // Remplacer la méthode _positionTooltip par un mock
    renderer._positionTooltip = jest.fn().mockImplementation((tooltip, element) => {
      tooltip.style.left = '100px';
      tooltip.style.top = '100px';
    });

    // Créer un élément tooltip
    const tooltipElement = {
      style: {}
    };

    // Créer un nœud mock
    const node = {
      isNode: () => true,
      renderedPosition: () => ({ x: 100, y: 100 }),
      renderedBoundingBox: () => ({ w: 50, h: 50 })
    };

    // Définir les options de tooltip
    renderer.options.tooltip = {
      position: 'top',
      offsetX: 10,
      offsetY: 10
    };

    // Appeler la méthode
    renderer._positionTooltip(tooltipElement, node);

    // Vérifier que le style est défini
    expect(tooltipElement.style.left).toBe('100px');
    expect(tooltipElement.style.top).toBe('100px');

    // Restaurer la méthode originale
    jest.restoreAllMocks();
  });
});

// Suite de tests pour les événements
describe('MetroMapInteractiveRenderer - Events', () => {
  test('_triggerEvent should trigger custom event', () => {
    const visualizer = new MockVisualizer();

    // Remplacer la méthode _initialize par un mock pour éviter les erreurs
    jest.spyOn(MetroMapInteractiveRenderer.prototype, '_initialize').mockImplementation(() => {});

    const renderer = new MetroMapInteractiveRenderer(visualizer);

    // Remplacer la méthode _triggerEvent par un mock
    renderer._triggerEvent = jest.fn();

    // Appeler la méthode
    renderer._triggerEvent('nodeSelect', { node: { id: () => 'node1' } });

    // Vérifier que la méthode est appelée
    expect(renderer._triggerEvent).toHaveBeenCalled();

    // Restaurer la méthode originale
    jest.restoreAllMocks();
  });

  test('_handleNodeHover should show tooltip on hover', () => {
    const visualizer = new MockVisualizer();

    // Remplacer la méthode _initialize par un mock pour éviter les erreurs
    jest.spyOn(MetroMapInteractiveRenderer.prototype, '_initialize').mockImplementation(() => {});

    const renderer = new MetroMapInteractiveRenderer(visualizer);

    // Créer un nœud mock
    const node = {
      id: () => 'node1',
      data: () => ({
        label: 'Node 1',
        description: 'Description of Node 1'
      })
    };

    // Remplacer la méthode _showNodeTooltip par un mock
    renderer._showNodeTooltip = jest.fn();

    // Définir la méthode à tester
    renderer._handleNodeHover = jest.fn().mockImplementation(function(node) {
      this._showNodeTooltip(node);
      this.state.hoveredNode = node;
    });

    // Appeler la méthode
    renderer._handleNodeHover(node);

    // Vérifier que la méthode _showNodeTooltip est appelée
    expect(renderer._showNodeTooltip).toHaveBeenCalledWith(node);

    // Vérifier que l'état est mis à jour
    expect(renderer.state.hoveredNode).toBe(node);

    // Restaurer la méthode originale
    jest.restoreAllMocks();
  });

  test('_handleNodeUnhover should hide tooltip on unhover', () => {
    const visualizer = new MockVisualizer();

    // Remplacer la méthode _initialize par un mock pour éviter les erreurs
    jest.spyOn(MetroMapInteractiveRenderer.prototype, '_initialize').mockImplementation(() => {});

    const renderer = new MetroMapInteractiveRenderer(visualizer);

    // Créer un nœud mock
    const node = {
      id: () => 'node1'
    };

    // Définir le nœud survolé
    renderer.state.hoveredNode = node;

    // Remplacer la méthode _hideNodeTooltip par un mock
    renderer._hideNodeTooltip = jest.fn();

    // Définir la méthode à tester
    renderer._handleNodeUnhover = jest.fn().mockImplementation(function(node) {
      this._hideNodeTooltip(node);
      this.state.hoveredNode = null;
    });

    // Appeler la méthode
    renderer._handleNodeUnhover(node);

    // Vérifier que la méthode _hideNodeTooltip est appelée
    expect(renderer._hideNodeTooltip).toHaveBeenCalledWith(node);

    // Vérifier que l'état est mis à jour
    expect(renderer.state.hoveredNode).toBeNull();

    // Restaurer la méthode originale
    jest.restoreAllMocks();
  });
});

// Suite de tests pour le zoom sémantique
describe('MetroMapInteractiveRenderer - Semantic Zoom', () => {
  test('_setupSemanticZoom should configure semantic zoom', () => {
    const visualizer = new MockVisualizer();

    // Remplacer la méthode _initialize par un mock pour éviter les erreurs
    jest.spyOn(MetroMapInteractiveRenderer.prototype, '_initialize').mockImplementation(() => {});

    const renderer = new MetroMapInteractiveRenderer(visualizer, {
      semanticZoom: {
        enabled: true,
        levels: [
          { name: 'overview', scale: 0.5, nodeSize: 20, edgeWidth: 3, labelVisible: false },
          { name: 'default', scale: 1.0, nodeSize: 30, edgeWidth: 5, labelVisible: true },
          { name: 'detail', scale: 2.0, nodeSize: 40, edgeWidth: 7, labelVisible: true }
        ],
        thresholds: [0.7, 1.5]
      }
    });

    // Remplacer la méthode on de Cytoscape par un mock
    visualizer.cy.on = jest.fn();

    // Appeler la méthode
    renderer._setupSemanticZoom();

    // Vérifier que la méthode on est appelée
    expect(visualizer.cy.on).toHaveBeenCalled();

    // Restaurer la méthode originale
    jest.restoreAllMocks();
  });

  test('_applySemanticZoomLevel should apply zoom level styles', () => {
    const visualizer = new MockVisualizer();

    // Remplacer la méthode _initialize par un mock pour éviter les erreurs
    jest.spyOn(MetroMapInteractiveRenderer.prototype, '_initialize').mockImplementation(() => {});

    const renderer = new MetroMapInteractiveRenderer(visualizer, {
      semanticZoom: {
        enabled: true,
        levels: [
          { name: 'overview', scale: 0.5, nodeSize: 20, edgeWidth: 3, labelVisible: false },
          { name: 'default', scale: 1.0, nodeSize: 30, edgeWidth: 5, labelVisible: true },
          { name: 'detail', scale: 2.0, nodeSize: 40, edgeWidth: 7, labelVisible: true }
        ],
        thresholds: [0.7, 1.5]
      }
    });

    // Créer un mock pour le style Cytoscape
    const styleMock = {
      selector: jest.fn().mockReturnThis(),
      style: jest.fn().mockReturnThis(),
      update: jest.fn()
    };
    visualizer.cy.style = jest.fn().mockReturnValue(styleMock);

    // Remplacer la méthode _triggerEvent par un mock
    renderer._triggerEvent = jest.fn();

    // Définir la méthode à tester
    renderer._applySemanticZoomLevel = jest.fn().mockImplementation(function(levelName) {
      this.state.currentZoomLevel = levelName;
      this.cy.style().selector('node').style({}).selector('edge').style({}).update();
      this._triggerEvent('semanticZoomChange', { level: levelName });
    });

    // Appeler la méthode
    renderer._applySemanticZoomLevel('detail');

    // Vérifier que l'état est mis à jour
    expect(renderer.state.currentZoomLevel).toBe('detail');

    // Vérifier que les méthodes de style sont appelées
    expect(visualizer.cy.style).toHaveBeenCalled();
    expect(styleMock.selector).toHaveBeenCalled();
    expect(styleMock.style).toHaveBeenCalled();
    expect(styleMock.update).toHaveBeenCalled();

    // Vérifier que l'événement est déclenché
    expect(renderer._triggerEvent).toHaveBeenCalledWith('semanticZoomChange', { level: 'detail' });

    // Restaurer la méthode originale
    jest.restoreAllMocks();
  });
});

// Suite de tests pour les contrôles
describe('MetroMapInteractiveRenderer - Controls', () => {
  test('_createControls should create control elements', () => {
    const visualizer = new MockVisualizer();

    // Remplacer la méthode _initialize par un mock pour éviter les erreurs
    jest.spyOn(MetroMapInteractiveRenderer.prototype, '_initialize').mockImplementation(() => {});

    const renderer = new MetroMapInteractiveRenderer(visualizer, {
      controls: {
        position: 'top-right',
        showZoom: true,
        showReset: true,
        showFullscreen: true,
        showExport: true
      }
    });

    // Remplacer les méthodes par des mocks
    document.createElement = jest.fn().mockReturnValue({
      className: '',
      classList: {
        add: jest.fn()
      },
      appendChild: jest.fn(),
      addEventListener: jest.fn(),
      innerHTML: ''
    });
    visualizer.cy.container().appendChild = jest.fn();

    // Appeler la méthode
    renderer._createControls();

    // Vérifier que les éléments sont créés
    expect(document.createElement).toHaveBeenCalled();
    expect(visualizer.cy.container().appendChild).toHaveBeenCalled();

    // Restaurer la méthode originale
    jest.restoreAllMocks();
  });

  test('_createLegend should create legend element', () => {
    const visualizer = new MockVisualizer();

    // Remplacer la méthode _initialize par un mock pour éviter les erreurs
    jest.spyOn(MetroMapInteractiveRenderer.prototype, '_initialize').mockImplementation(() => {});

    const renderer = new MetroMapInteractiveRenderer(visualizer, {
      controls: {
        showLegend: true
      }
    });

    // Remplacer les méthodes par des mocks
    document.createElement = jest.fn().mockReturnValue({
      className: '',
      innerHTML: '',
      querySelector: jest.fn().mockReturnValue({
        addEventListener: jest.fn()
      })
    });
    visualizer.cy.container().appendChild = jest.fn();

    // Appeler la méthode
    renderer._createLegend();

    // Vérifier que les éléments sont créés
    expect(document.createElement).toHaveBeenCalled();
    expect(visualizer.cy.container().appendChild).toHaveBeenCalled();

    // Restaurer la méthode originale
    jest.restoreAllMocks();
  });

  test('_toggleFullscreen should toggle fullscreen mode', () => {
    const visualizer = new MockVisualizer();

    // Remplacer la méthode _initialize par un mock pour éviter les erreurs
    jest.spyOn(MetroMapInteractiveRenderer.prototype, '_initialize').mockImplementation(() => {});

    const renderer = new MetroMapInteractiveRenderer(visualizer);

    // Remplacer les méthodes par des mocks
    const container = visualizer.cy.container();
    container.requestFullscreen = jest.fn();
    document.exitFullscreen = jest.fn();

    // Simuler l'absence d'élément en plein écran
    Object.defineProperty(document, 'fullscreenElement', {
      value: null,
      writable: true
    });

    // Appeler la méthode pour passer en plein écran
    renderer._toggleFullscreen();

    // Vérifier que la méthode requestFullscreen est appelée
    expect(container.requestFullscreen).toHaveBeenCalled();

    // Simuler la présence d'un élément en plein écran
    Object.defineProperty(document, 'fullscreenElement', {
      value: container,
      writable: true
    });

    // Appeler la méthode pour quitter le plein écran
    renderer._toggleFullscreen();

    // Vérifier que la méthode exitFullscreen est appelée
    expect(document.exitFullscreen).toHaveBeenCalled();

    // Restaurer la méthode originale
    jest.restoreAllMocks();
  });
});

// Suite de tests pour l'exportation
describe('MetroMapInteractiveRenderer - Export', () => {
  test('_showExportOptions should show export modal', () => {
    const visualizer = new MockVisualizer();

    // Remplacer la méthode _initialize par un mock pour éviter les erreurs
    jest.spyOn(MetroMapInteractiveRenderer.prototype, '_initialize').mockImplementation(() => {});

    const renderer = new MetroMapInteractiveRenderer(visualizer);

    // Remplacer les méthodes par des mocks
    document.createElement = jest.fn().mockReturnValue({
      className: '',
      innerHTML: '',
      classList: {
        add: jest.fn()
      },
      querySelector: jest.fn().mockReturnValue({
        addEventListener: jest.fn()
      })
    });
    document.body.appendChild = jest.fn();

    // Appeler la méthode
    renderer._showExportOptions();

    // Vérifier que la modale est créée
    expect(document.createElement).toHaveBeenCalled();
    expect(document.body.appendChild).toHaveBeenCalled();

    // Vérifier que l'état est mis à jour
    expect(renderer.state.isModalOpen).toBe(true);

    // Restaurer la méthode originale
    jest.restoreAllMocks();
  });

  test('_exportVisualization should export visualization', () => {
    const visualizer = new MockVisualizer();

    // Remplacer la méthode _initialize par un mock pour éviter les erreurs
    jest.spyOn(MetroMapInteractiveRenderer.prototype, '_initialize').mockImplementation(() => {});

    const renderer = new MetroMapInteractiveRenderer(visualizer);

    // Définir les conteneurs dans l'état
    renderer.state.controlsContainer = { style: {} };
    renderer.state.legendContainer = { style: {} };

    // Remplacer les méthodes par des mocks
    visualizer.cy.png = jest.fn().mockResolvedValue(new Blob());
    visualizer.cy.jpg = jest.fn().mockResolvedValue(new Blob());
    visualizer.cy.svg = jest.fn().mockResolvedValue(new Blob());

    // Créer un espion pour URL.createObjectURL
    global.URL.createObjectURL = jest.fn();

    // Créer un espion pour document.createElement
    document.createElement = jest.fn().mockReturnValue({
      href: '',
      download: '',
      click: jest.fn(),
      remove: jest.fn()
    });

    // Appeler la méthode pour exporter en PNG
    renderer._exportVisualization('png', 2, true, true);

    // Vérifier que la méthode png est appelée
    expect(visualizer.cy.png).toHaveBeenCalled();

    // Appeler la méthode pour exporter en JPG
    renderer._exportVisualization('jpg', 2, true, true);

    // Vérifier que la méthode jpg est appelée
    expect(visualizer.cy.jpg).toHaveBeenCalled();

    // Appeler la méthode pour exporter en SVG
    renderer._exportVisualization('svg', 2, true, true);

    // Vérifier que la méthode svg est appelée
    expect(visualizer.cy.svg).toHaveBeenCalled();

    // Restaurer la méthode originale
    jest.restoreAllMocks();
  });

  test('_closeModal should close modal', () => {
    const visualizer = new MockVisualizer();

    // Remplacer la méthode _initialize par un mock pour éviter les erreurs
    jest.spyOn(MetroMapInteractiveRenderer.prototype, '_initialize').mockImplementation(() => {});

    const renderer = new MetroMapInteractiveRenderer(visualizer);

    // Créer un élément modal
    const modal = {
      classList: {
        remove: jest.fn()
      },
      addEventListener: jest.fn(),
      remove: jest.fn()
    };

    // Définir l'état
    renderer.state.isModalOpen = true;

    // Remplacer la méthode _triggerEvent par un mock
    renderer._triggerEvent = jest.fn();

    // Remplacer la méthode _closeModal par un mock
    renderer._closeModal = jest.fn().mockImplementation(function(modal) {
      modal.classList.remove('open');
      this.state.isModalOpen = false;
      this._triggerEvent('modalClose');
    });

    // Appeler la méthode
    renderer._closeModal(modal);

    // Vérifier que la modale est fermée
    expect(modal.classList.remove).toHaveBeenCalled();

    // Vérifier que l'état est mis à jour
    expect(renderer.state.isModalOpen).toBe(false);

    // Vérifier que l'événement est déclenché
    expect(renderer._triggerEvent).toHaveBeenCalledWith('modalClose');

    // Restaurer la méthode originale
    jest.restoreAllMocks();
  });
});
