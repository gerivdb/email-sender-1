/**
 * Mock pour MetroMapVisualizerEnhanced
 * Ce fichier fournit une version simplifiée de MetroMapVisualizerEnhanced pour les tests
 * 
 * Version: 1.0
 * Date: 2025-05-30
 */

/**
 * Classe mock pour MetroMapVisualizerEnhanced
 */
class MetroMapVisualizerEnhancedMock {
  /**
   * Constructeur
   * @param {string} containerId - ID du conteneur HTML pour la visualisation
   * @param {Object} options - Options de configuration
   */
  constructor(containerId, options = {}) {
    this.containerId = containerId;
    this.options = options;
    this.cy = null;
  }
  
  /**
   * Initialise le visualiseur
   * @returns {Promise<void>}
   */
  async initialize() {
    // Initialiser Cytoscape
    this.cy = window.cytoscape({
      container: document.getElementById(this.containerId),
      style: [
        {
          selector: 'node',
          style: {
            'background-color': 'data(originalColor)',
            'label': 'data(label)',
            'color': '#fff',
            'text-outline-color': '#000',
            'text-outline-width': 1,
            'font-size': 12,
            'text-valign': 'center',
            'text-halign': 'center',
            'width': 30,
            'height': 30,
            'border-width': 2,
            'border-color': '#000'
          }
        },
        {
          selector: 'edge',
          style: {
            'width': 3,
            'line-color': 'data(originalColor)',
            'target-arrow-color': 'data(originalColor)',
            'target-arrow-shape': 'triangle',
            'curve-style': 'bezier'
          }
        },
        {
          selector: 'node[status="completed"]',
          style: {
            'background-color': '#4CAF50',
            'border-color': '#2E7D32'
          }
        },
        {
          selector: 'node[status="in_progress"]',
          style: {
            'background-color': '#2196F3',
            'border-color': '#1565C0'
          }
        },
        {
          selector: 'node[status="planned"]',
          style: {
            'background-color': '#9E9E9E',
            'border-color': '#616161'
          }
        }
      ],
      layout: {
        name: 'preset'
      }
    });
  }
  
  /**
   * Visualise les roadmaps spécifiées
   * @param {Array<string>} roadmapIds - IDs des roadmaps à visualiser
   * @returns {Promise<void>}
   */
  async visualizeRoadmaps(roadmapIds) {
    // Vérifier si nous avons des données de test
    if (!this.options.testRoadmaps) {
      throw new Error('Aucune donnée de test disponible pour la visualisation');
    }
    
    // Filtrer les roadmaps disponibles
    const availableRoadmaps = roadmapIds.filter(id => this.options.testRoadmaps[id]);
    
    if (availableRoadmaps.length === 0) {
      throw new Error('Aucune roadmap disponible parmi les IDs spécifiés');
    }
    
    // Créer un graphe Cytoscape à partir des données de test
    const elements = [];
    
    // Ajouter les nœuds
    availableRoadmaps.forEach(roadmapId => {
      const roadmap = this.options.testRoadmaps[roadmapId];
      
      roadmap.nodes.forEach(node => {
        elements.push({
          group: 'nodes',
          data: {
            id: node.id,
            label: node.label,
            description: node.description,
            status: node.status,
            roadmapId: roadmap.id,
            originalColor: roadmap.color
          }
        });
      });
      
      // Ajouter les arêtes
      roadmap.edges.forEach(edge => {
        elements.push({
          group: 'edges',
          data: {
            id: `${edge.source}_${edge.target}`,
            source: edge.source,
            target: edge.target,
            roadmapId: roadmap.id,
            originalColor: roadmap.color
          }
        });
      });
    });
    
    // Ajouter les éléments au graphe Cytoscape
    this.cy.elements().remove();
    this.cy.add(elements);
    
    // Appliquer un layout simple
    this.cy.layout({
      name: 'breadthfirst',
      directed: true,
      padding: 30,
      spacingFactor: 1.5,
      animate: false
    }).run();
  }
  
  /**
   * Met à jour le layout
   */
  updateLayout() {
    if (this.cy) {
      this.cy.layout({
        name: 'breadthfirst',
        directed: true,
        padding: 30,
        spacingFactor: 1.5,
        animate: false
      }).run();
    }
  }
}

export default MetroMapVisualizerEnhancedMock;
