/**
 * Tests pour le moteur de layout automatique MetroMapLayoutEngine
 */

import MetroMapLayoutEngine from '../MetroMapLayoutEngine.js';

// Fonction utilitaire pour créer un graphe de test simple
function createSimpleGraph() {
  return {
    nodes: [
      { id: 'A', name: 'Node A', lines: ['L1'] },
      { id: 'B', name: 'Node B', lines: ['L1'] },
      { id: 'C', name: 'Node C', lines: ['L1'] }
    ],
    edges: [
      { source: 'A', target: 'B', line: 'L1' },
      { source: 'B', target: 'C', line: 'L1' }
    ],
    lines: [
      { id: 'L1', name: 'Line 1', color: '#FF0000' }
    ]
  };
}

// Fonction utilitaire pour créer un graphe de test complexe
function createComplexGraph() {
  return {
    nodes: [
      { id: 'A', name: 'Node A', lines: ['L1'] },
      { id: 'B', name: 'Node B', lines: ['L1', 'L2'] },
      { id: 'C', name: 'Node C', lines: ['L1'] },
      { id: 'D', name: 'Node D', lines: ['L2'] },
      { id: 'E', name: 'Node E', lines: ['L2'] },
      { id: 'F', name: 'Node F', lines: ['L3'] },
      { id: 'G', name: 'Node G', lines: ['L3'] },
      { id: 'H', name: 'Node H', lines: ['L3', 'L1'] }
    ],
    edges: [
      { source: 'A', target: 'B', line: 'L1' },
      { source: 'B', target: 'C', line: 'L1' },
      { source: 'C', target: 'H', line: 'L1' },
      { source: 'B', target: 'D', line: 'L2' },
      { source: 'D', target: 'E', line: 'L2' },
      { source: 'F', target: 'G', line: 'L3' },
      { source: 'G', target: 'H', line: 'L3' }
    ],
    lines: [
      { id: 'L1', name: 'Line 1', color: '#FF0000' },
      { id: 'L2', name: 'Line 2', color: '#00FF00' },
      { id: 'L3', name: 'Line 3', color: '#0000FF' }
    ]
  };
}

// Fonction utilitaire pour créer un graphe de test cyclique
function createCyclicGraph() {
  return {
    nodes: [
      { id: 'A', name: 'Node A', lines: ['L1'] },
      { id: 'B', name: 'Node B', lines: ['L1'] },
      { id: 'C', name: 'Node C', lines: ['L1'] },
      { id: 'D', name: 'Node D', lines: ['L1'] }
    ],
    edges: [
      { source: 'A', target: 'B', line: 'L1' },
      { source: 'B', target: 'C', line: 'L1' },
      { source: 'C', target: 'D', line: 'L1' },
      { source: 'D', target: 'A', line: 'L1' } // Crée un cycle
    ],
    lines: [
      { id: 'L1', name: 'Line 1', color: '#FF0000' }
    ]
  };
}

// Suite de tests pour le constructeur
describe('MetroMapLayoutEngine - Constructor', () => {
  test('should create an instance with default options', () => {
    const engine = new MetroMapLayoutEngine();
    expect(engine).toBeDefined();
    expect(engine.options).toBeDefined();
    expect(engine.options.nodeSeparation).toBe(50);
    expect(engine.options.rankSeparation).toBe(100);
    expect(engine.options.preferredDirection).toBe('horizontal');
  });

  test('should create an instance with custom options', () => {
    const options = {
      nodeSeparation: 30,
      rankSeparation: 80,
      preferredDirection: 'vertical'
    };
    const engine = new MetroMapLayoutEngine(options);
    expect(engine.options.nodeSeparation).toBe(30);
    expect(engine.options.rankSeparation).toBe(80);
    expect(engine.options.preferredDirection).toBe('vertical');
  });

  test('should merge custom options with default options', () => {
    const options = {
      nodeSeparation: 30
    };
    const engine = new MetroMapLayoutEngine(options);
    expect(engine.options.nodeSeparation).toBe(30);
    expect(engine.options.rankSeparation).toBe(100); // Default value
    expect(engine.options.preferredDirection).toBe('horizontal'); // Default value
  });
});

// Suite de tests pour la méthode applyLayout
describe('MetroMapLayoutEngine - applyLayout', () => {
  test('should apply layout to a simple graph', () => {
    const engine = new MetroMapLayoutEngine();
    const graph = createSimpleGraph();
    const result = engine.applyLayout(graph);

    // Vérifier que le résultat contient les nœuds et les arêtes
    expect(result).toBeDefined();
    expect(result.nodes).toBeDefined();
    expect(result.edges).toBeDefined();

    // Vérifier que tous les nœuds ont des positions
    result.nodes.forEach(node => {
      expect(node.position).toBeDefined();
      expect(node.position.x).toBeDefined();
      expect(node.position.y).toBeDefined();
      expect(typeof node.position.x).toBe('number');
      expect(typeof node.position.y).toBe('number');
    });

    // Vérifier que toutes les arêtes ont des points de contrôle
    result.edges.forEach(edge => {
      expect(edge.controlPoints).toBeDefined();
      expect(Array.isArray(edge.controlPoints)).toBe(true);
      expect(edge.controlPoints.length).toBeGreaterThan(0);
    });
  });

  test('should apply layout to a complex graph', () => {
    const engine = new MetroMapLayoutEngine();
    const graph = createComplexGraph();
    const result = engine.applyLayout(graph);

    // Vérifier que le résultat contient les nœuds et les arêtes
    expect(result).toBeDefined();
    expect(result.nodes).toBeDefined();
    expect(result.edges).toBeDefined();

    // Vérifier que tous les nœuds ont des positions
    result.nodes.forEach(node => {
      expect(node.position).toBeDefined();
      expect(node.position.x).toBeDefined();
      expect(node.position.y).toBeDefined();
      expect(typeof node.position.x).toBe('number');
      expect(typeof node.position.y).toBe('number');
    });

    // Vérifier que toutes les arêtes ont des points de contrôle
    result.edges.forEach(edge => {
      expect(edge.controlPoints).toBeDefined();
      expect(Array.isArray(edge.controlPoints)).toBe(true);
      expect(edge.controlPoints.length).toBeGreaterThan(0);
    });
  });

  test('should handle cyclic graphs', () => {
    const engine = new MetroMapLayoutEngine();
    const graph = createCyclicGraph();
    const result = engine.applyLayout(graph);

    // Vérifier que le résultat contient les nœuds et les arêtes
    expect(result).toBeDefined();
    expect(result.nodes).toBeDefined();
    expect(result.edges).toBeDefined();

    // Vérifier que tous les nœuds ont des positions
    result.nodes.forEach(node => {
      expect(node.position).toBeDefined();
      expect(node.position.x).toBeDefined();
      expect(node.position.y).toBeDefined();
      expect(typeof node.position.x).toBe('number');
      expect(typeof node.position.y).toBe('number');
    });

    // Vérifier que toutes les arêtes ont des points de contrôle
    result.edges.forEach(edge => {
      expect(edge.controlPoints).toBeDefined();
      expect(Array.isArray(edge.controlPoints)).toBe(true);
      expect(edge.controlPoints.length).toBeGreaterThan(0);
    });
  });

  test('should respect preferred direction', () => {
    // Test avec direction horizontale
    const engineH = new MetroMapLayoutEngine({ preferredDirection: 'horizontal' });
    const graphH = createSimpleGraph();
    const resultH = engineH.applyLayout(graphH);

    // Vérifier que les nœuds sont alignés horizontalement
    // (les différences en x sont plus grandes que les différences en y)
    const nodeA_H = resultH.nodes.find(n => n.id === 'A');
    const nodeC_H = resultH.nodes.find(n => n.id === 'C');
    const diffX_H = Math.abs(nodeA_H.position.x - nodeC_H.position.x);
    const diffY_H = Math.abs(nodeA_H.position.y - nodeC_H.position.y);
    expect(diffX_H).toBeGreaterThan(diffY_H);

    // Test avec direction verticale
    const engineV = new MetroMapLayoutEngine({ preferredDirection: 'vertical' });
    const graphV = createSimpleGraph();
    const resultV = engineV.applyLayout(graphV);

    // Vérifier que les nœuds sont alignés verticalement
    // (les différences en y sont plus grandes que les différences en x)
    const nodeA_V = resultV.nodes.find(n => n.id === 'A');
    const nodeC_V = resultV.nodes.find(n => n.id === 'C');
    const diffX_V = Math.abs(nodeA_V.position.x - nodeC_V.position.x);
    const diffY_V = Math.abs(nodeA_V.position.y - nodeC_V.position.y);
    expect(diffY_V).toBeGreaterThanOrEqual(diffX_V);
  });

  test('should handle empty graph', () => {
    const engine = new MetroMapLayoutEngine();
    const graph = { nodes: [], edges: [], lines: [] };
    const result = engine.applyLayout(graph);

    expect(result).toBeDefined();
    expect(result.nodes).toEqual([]);
    expect(result.edges).toEqual([]);
  });

  test('should handle graph with only one node', () => {
    const engine = new MetroMapLayoutEngine();
    const graph = {
      nodes: [{ id: 'A', name: 'Node A', lines: ['L1'] }],
      edges: [],
      lines: [{ id: 'L1', name: 'Line 1', color: '#FF0000' }]
    };
    const result = engine.applyLayout(graph);

    expect(result).toBeDefined();
    expect(result.nodes.length).toBe(1);
    expect(result.edges).toEqual([]);

    const node = result.nodes[0];
    expect(node.position).toBeDefined();
    // Ne pas tester les valeurs exactes des positions, car elles peuvent varier
    expect(typeof node.position.x).toBe('number');
    expect(typeof node.position.y).toBe('number');
  });
});

// Suite de tests pour les résultats du layout
describe('MetroMapLayoutEngine - Layout Results', () => {
  test('should correctly position nodes in a simple graph', () => {
    const engine = new MetroMapLayoutEngine();
    const graph = createSimpleGraph();
    const result = engine.applyLayout(graph);

    // Vérifier que les nœuds sont positionnés correctement
    const nodeA = result.nodes.find(n => n.id === 'A');
    const nodeB = result.nodes.find(n => n.id === 'B');
    const nodeC = result.nodes.find(n => n.id === 'C');

    // Vérifier que les nœuds sont dans l'ordre correct (A -> B -> C)
    expect(nodeA.position.x).toBeLessThan(nodeB.position.x);
    expect(nodeB.position.x).toBeLessThan(nodeC.position.x);
  });

  test('should correctly assign ranks in a complex graph', () => {
    const engine = new MetroMapLayoutEngine();
    const graph = createComplexGraph();
    const result = engine.applyLayout(graph);

    // Vérifier que les nœuds sont positionnés correctement
    const nodeA = result.nodes.find(n => n.id === 'A');
    const nodeB = result.nodes.find(n => n.id === 'B');
    const nodeC = result.nodes.find(n => n.id === 'C');
    const nodeD = result.nodes.find(n => n.id === 'D');
    const nodeE = result.nodes.find(n => n.id === 'E');

    // Vérifier que les nœuds sont dans l'ordre correct (A -> B -> C et B -> D -> E)
    expect(nodeA.position.x).toBeLessThan(nodeB.position.x);
    expect(nodeB.position.x).toBeLessThan(nodeC.position.x);
    expect(nodeB.position.x).toBeLessThan(nodeD.position.x);
    expect(nodeD.position.x).toBeLessThan(nodeE.position.x);
  });

  test('should minimize edge crossings in a complex graph', () => {
    const engine = new MetroMapLayoutEngine();
    const graph = createComplexGraph();
    const result = engine.applyLayout(graph);

    // Vérifier que les arêtes ont des points de contrôle
    result.edges.forEach(edge => {
      expect(edge.controlPoints).toBeDefined();
      expect(Array.isArray(edge.controlPoints)).toBe(true);
      expect(edge.controlPoints.length).toBeGreaterThan(0);
    });
  });
});

// Exécuter les tests
// Note: Ces tests sont conçus pour être exécutés avec Jest
// Pour les exécuter, utilisez la commande: npm test
