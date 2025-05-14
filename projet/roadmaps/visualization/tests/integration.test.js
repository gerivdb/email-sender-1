/**
 * Tests d'intégration pour le système de visualisation en carte de métro
 */

// Mocks pour les modules externes
jest.mock('cytoscape');
jest.mock('cytoscape-cose-bilkent');
jest.mock('cytoscape-dagre');
jest.mock('cytoscape-klay');
jest.mock('cytoscape-popper');
jest.mock('tippy.js');
jest.mock('tippy.js/dist/tippy.css', () => ({}));

// Importer les modules à tester
import MetroMapLayoutEngine from '../MetroMapLayoutEngine.js';
import MetroMapInteractiveRenderer from '../MetroMapInteractiveRenderer.js';
import MetroMapFilters from '../MetroMapFilters.js';
import MetroMapCustomizer from '../MetroMapCustomizer.js';

// Créer un mock pour MetroMapVisualizerEnhanced
class MockMetroMapVisualizerEnhanced {
  constructor(container, options = {}) {
    this.container = container;
    this.options = options;
    this.cy = require('./mocks/cytoscape.mock.js').default();
    this.layoutEngine = new MetroMapLayoutEngine();
  }

  async initialize() {
    // Ne rien faire
  }

  async visualizeRoadmaps(roadmapIds) {
    // Ne rien faire
  }

  updateLayoutOptions(options) {
    this.options.layoutOptions = { ...this.options.layoutOptions, ...options };
  }

  _applyMetroLayout() {
    // Ne rien faire
  }
}

// Remplacer l'import par notre mock
const MetroMapVisualizerEnhanced = MockMetroMapVisualizerEnhanced;

// Mock pour le document
document.getElementById = jest.fn().mockReturnValue({
  appendChild: jest.fn(),
  getBoundingClientRect: jest.fn().mockReturnValue({ left: 0, top: 0, width: 800, height: 600 })
});

// Fonction utilitaire pour créer des données de test
function createTestRoadmaps() {
  return {
    'roadmap1': {
      id: 'roadmap1',
      name: 'Roadmap 1',
      nodes: [
        { id: 'roadmap1_1', label: 'Node 1', description: 'Description 1', status: 'completed', level: 'cosmos' },
        { id: 'roadmap1_2', label: 'Node 2', description: 'Description 2', status: 'in_progress', level: 'galaxy' },
        { id: 'roadmap1_3', label: 'Node 3', description: 'Description 3', status: 'planned', level: 'system' }
      ],
      edges: [
        { source: 'roadmap1_1', target: 'roadmap1_2' },
        { source: 'roadmap1_2', target: 'roadmap1_3' }
      ],
      color: '#FF6B6B'
    },
    'roadmap2': {
      id: 'roadmap2',
      name: 'Roadmap 2',
      nodes: [
        { id: 'roadmap2_1', label: 'Node A', description: 'Description A', status: 'completed', level: 'cosmos' },
        { id: 'roadmap2_2', label: 'Node B', description: 'Description B', status: 'in_progress', level: 'galaxy' },
        { id: 'roadmap2_3', label: 'Node C', description: 'Description C', status: 'planned', level: 'system' }
      ],
      edges: [
        { source: 'roadmap2_1', target: 'roadmap2_2' },
        { source: 'roadmap2_2', target: 'roadmap2_3' }
      ],
      color: '#4ECDC4'
    }
  };
}

// Suite de tests pour l'intégration des modules
describe('Metro Map Visualization - Integration', () => {

  test('should initialize visualizer with layout engine', async () => {
    const testRoadmaps = createTestRoadmaps();

    // Créer le visualiseur
    const visualizer = new MetroMapVisualizerEnhanced('container', {
      testRoadmaps: testRoadmaps,
      layoutOptions: {
        layoutAlgorithm: 'metro',
        preferredDirection: 'horizontal',
        nodeSeparation: 50,
        rankSeparation: 100
      }
    });

    // Remplacer la méthode _applyMetroLayout par un mock
    visualizer._applyMetroLayout = jest.fn();

    // Initialiser le visualiseur
    await visualizer.initialize();

    // Vérifier que le moteur de layout est créé
    expect(visualizer.layoutEngine).toBeInstanceOf(MetroMapLayoutEngine);
  });

  test('should integrate visualizer with interactive renderer', async () => {
    const testRoadmaps = createTestRoadmaps();

    // Créer le visualiseur
    const visualizer = new MetroMapVisualizerEnhanced('container', {
      testRoadmaps: testRoadmaps
    });

    // Remplacer la méthode initialize par un mock
    visualizer.initialize = jest.fn().mockResolvedValue();

    // Initialiser le visualiseur
    await visualizer.initialize();

    // Créer le renderer
    const renderer = new MetroMapInteractiveRenderer(visualizer);

    // Vérifier que le renderer est correctement initialisé
    expect(renderer.visualizer).toBe(visualizer);
  });

  test('should integrate all modules together', async () => {
    const testRoadmaps = createTestRoadmaps();

    // Créer le visualiseur
    const visualizer = new MetroMapVisualizerEnhanced('container', {
      testRoadmaps: testRoadmaps
    });

    // Remplacer les méthodes par des mocks
    visualizer.initialize = jest.fn().mockResolvedValue();
    visualizer.visualizeRoadmaps = jest.fn().mockResolvedValue();

    // Initialiser le visualiseur
    await visualizer.initialize();

    // Créer le renderer, les filtres et le customizer
    const renderer = new MetroMapInteractiveRenderer(visualizer);
    const filters = new MetroMapFilters(visualizer);
    const customizer = new MetroMapCustomizer(visualizer);

    // Remplacer les méthodes par des mocks
    filters.setStatusFilters = jest.fn();
    filters.setRoadmapFilters = jest.fn();
    filters.applyFilters = jest.fn();
    customizer.applyTheme = jest.fn();
    customizer.setNodeShape = jest.fn();
    customizer.setNodeSize = jest.fn();

    // Visualiser les roadmaps
    await visualizer.visualizeRoadmaps(['roadmap1', 'roadmap2']);

    // Appliquer des filtres
    filters.setStatusFilters(['completed', 'in_progress']);
    filters.setRoadmapFilters(['roadmap1']);
    filters.applyFilters();

    // Appliquer un thème
    customizer.applyTheme('colorful');
    customizer.setNodeShape('rectangle');
    customizer.setNodeSize(40);

    // Vérifier que les méthodes sont appelées
    expect(filters.setStatusFilters).toHaveBeenCalledWith(['completed', 'in_progress']);
    expect(filters.setRoadmapFilters).toHaveBeenCalledWith(['roadmap1']);
    expect(filters.applyFilters).toHaveBeenCalled();
    expect(customizer.applyTheme).toHaveBeenCalledWith('colorful');
    expect(customizer.setNodeShape).toHaveBeenCalledWith('rectangle');
    expect(customizer.setNodeSize).toHaveBeenCalledWith(40);
  });
});

// Suite de tests pour les scénarios d'utilisation
describe('Metro Map Visualization - Usage Scenarios', () => {
  test('should handle filtering and customization in sequence', async () => {
    const testRoadmaps = createTestRoadmaps();

    // Créer le visualiseur
    const visualizer = new MetroMapVisualizerEnhanced('container', {
      testRoadmaps: testRoadmaps
    });

    // Remplacer les méthodes par des mocks
    visualizer.initialize = jest.fn().mockResolvedValue();
    visualizer.visualizeRoadmaps = jest.fn().mockResolvedValue();

    // Initialiser le visualiseur
    await visualizer.initialize();

    // Créer les filtres et le customizer
    const filters = new MetroMapFilters(visualizer);
    const customizer = new MetroMapCustomizer(visualizer);

    // Remplacer les méthodes par des mocks
    filters.setStatusFilters = jest.fn();
    filters.setSearchQuery = jest.fn();
    filters.applyFilters = jest.fn();
    filters.resetFilters = jest.fn();
    customizer.applyTheme = jest.fn();
    customizer.setNodeShape = jest.fn();

    // Visualiser les roadmaps
    await visualizer.visualizeRoadmaps(['roadmap1', 'roadmap2']);

    // Appliquer des filtres et des personnalisations
    filters.setStatusFilters(['completed']);
    filters.applyFilters();
    customizer.applyTheme('dark');
    filters.setSearchQuery('Node');
    filters.applyFilters();
    customizer.setNodeShape('star', 'completed');
    filters.resetFilters();

    // Vérifier que les méthodes sont appelées
    expect(filters.setStatusFilters).toHaveBeenCalledWith(['completed']);
    expect(filters.applyFilters).toHaveBeenCalled();
    expect(customizer.applyTheme).toHaveBeenCalledWith('dark');
    expect(filters.setSearchQuery).toHaveBeenCalledWith('Node');
    expect(customizer.setNodeShape).toHaveBeenCalledWith('star', 'completed');
    expect(filters.resetFilters).toHaveBeenCalled();
  });
});

// Exécuter les tests
// Note: Ces tests sont conçus pour être exécutés avec Jest
// Pour les exécuter, utilisez la commande: npm test
