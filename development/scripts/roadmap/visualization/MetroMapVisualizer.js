/**
 * MetroMapVisualizer.js
 * Module pour visualiser les roadmaps sous forme de carte de métro
 * Utilise Cytoscape.js pour la visualisation et s'intègre avec Qdrant
 * 
 * Version: 1.0
 * Date: 2025-05-15
 */

// Importation des dépendances
import cytoscape from 'cytoscape';
import coseBilkent from 'cytoscape-cose-bilkent';
import dagre from 'cytoscape-dagre';
import klay from 'cytoscape-klay';
import popper from 'cytoscape-popper';
import tippy from 'tippy.js';
import 'tippy.js/dist/tippy.css';

// Enregistrement des extensions Cytoscape
cytoscape.use(coseBilkent);
cytoscape.use(dagre);
cytoscape.use(klay);
cytoscape.use(popper);

/**
 * Classe principale pour la visualisation des roadmaps en carte de métro
 */
class MetroMapVisualizer {
  /**
   * Constructeur
   * @param {string} containerId - ID du conteneur HTML pour la visualisation
   * @param {Object} options - Options de configuration
   */
  constructor(containerId, options = {}) {
    this.containerId = containerId;
    this.options = {
      qdrantUrl: 'http://localhost:6333',
      qdrantCollection: 'roadmaps',
      nodeSize: 30,
      lineWidth: 4,
      metroColors: [
        '#FF6B6B', '#4ECDC4', '#45B7D1', '#FFA5A5', '#98D8C8',
        '#F9C74F', '#90BE6D', '#43AA8B', '#577590', '#F94144'
      ],
      ...options
    };
    
    this.cy = null;
    this.roadmaps = [];
    this.selectedRoadmaps = [];
    this.commonNodes = new Map();
    this.nodeStyles = new Map();
  }

  /**
   * Initialise la visualisation
   */
  async initialize() {
    // Créer l'instance Cytoscape
    this.cy = cytoscape({
      container: document.getElementById(this.containerId),
      style: this._createStylesheet(),
      layout: {
        name: 'preset'
      },
      wheelSensitivity: 0.3,
      minZoom: 0.2,
      maxZoom: 3
    });

    // Ajouter les interactions
    this._setupInteractions();
    
    // Charger les données initiales
    await this.loadRoadmaps();
  }

  /**
   * Charge les roadmaps depuis Qdrant
   */
  async loadRoadmaps() {
    try {
      const response = await fetch(`${this.options.qdrantUrl}/collections/${this.options.qdrantCollection}/points/scroll`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          limit: 1000,
          with_payload: true,
          with_vector: false
        })
      });

      if (!response.ok) {
        throw new Error(`Erreur lors de la récupération des roadmaps: ${response.statusText}`);
      }

      const data = await response.json();
      this.roadmaps = data.result.points.map(point => ({
        id: point.id,
        ...point.payload
      }));

      // Mettre à jour la liste des roadmaps disponibles
      this._updateRoadmapSelector();
      
      return this.roadmaps;
    } catch (error) {
      console.error('Erreur lors du chargement des roadmaps:', error);
      throw error;
    }
  }

  /**
   * Visualise les roadmaps sélectionnées
   * @param {Array} roadmapIds - IDs des roadmaps à visualiser
   */
  async visualizeRoadmaps(roadmapIds) {
    this.selectedRoadmaps = roadmapIds;
    
    // Récupérer les détails des roadmaps sélectionnées
    const roadmapDetails = await this._fetchRoadmapDetails(roadmapIds);
    
    // Construire les éléments du graphe
    const elements = this._buildGraphElements(roadmapDetails);
    
    // Réinitialiser et ajouter les éléments
    this.cy.elements().remove();
    this.cy.add(elements);
    
    // Appliquer le layout de type métro
    this._applyMetroLayout();
    
    // Mettre en évidence les nœuds communs
    this._highlightCommonNodes();
    
    // Centrer la vue
    this.cy.fit();
    this.cy.zoom(0.8);
  }

  /**
   * Crée une nouvelle roadmap
   * @param {Object} roadmapData - Données de la nouvelle roadmap
   */
  async createRoadmap(roadmapData) {
    try {
      // Générer un embedding pour la roadmap (simulé ici)
      const embedding = Array(512).fill(0).map(() => Math.random() - 0.5);
      
      // Préparer les données pour Qdrant
      const point = {
        id: roadmapData.id || `roadmap_${Date.now()}`,
        vector: embedding,
        payload: {
          title: roadmapData.title,
          description: roadmapData.description,
          tasks: roadmapData.tasks || [],
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString()
        }
      };
      
      // Envoyer à Qdrant
      const response = await fetch(`${this.options.qdrantUrl}/collections/${this.options.qdrantCollection}/points`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          points: [point]
        })
      });

      if (!response.ok) {
        throw new Error(`Erreur lors de la création de la roadmap: ${response.statusText}`);
      }
      
      // Recharger les roadmaps
      await this.loadRoadmaps();
      
      return point.id;
    } catch (error) {
      console.error('Erreur lors de la création de la roadmap:', error);
      throw error;
    }
  }

  /**
   * Met à jour une roadmap existante
   * @param {string} roadmapId - ID de la roadmap à mettre à jour
   * @param {Object} updateData - Données à mettre à jour
   */
  async updateRoadmap(roadmapId, updateData) {
    try {
      // Récupérer la roadmap existante
      const response = await fetch(`${this.options.qdrantUrl}/collections/${this.options.qdrantCollection}/points/${roadmapId}`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json'
        }
      });

      if (!response.ok) {
        throw new Error(`Erreur lors de la récupération de la roadmap: ${response.statusText}`);
      }

      const existingRoadmap = await response.json();
      
      // Mettre à jour les données
      const updatedPayload = {
        ...existingRoadmap.result.payload,
        ...updateData,
        updated_at: new Date().toISOString()
      };
      
      // Envoyer la mise à jour à Qdrant
      const updateResponse = await fetch(`${this.options.qdrantUrl}/collections/${this.options.qdrantCollection}/points`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          points: [{
            id: roadmapId,
            vector: existingRoadmap.result.vector,
            payload: updatedPayload
          }]
        })
      });

      if (!updateResponse.ok) {
        throw new Error(`Erreur lors de la mise à jour de la roadmap: ${updateResponse.statusText}`);
      }
      
      // Recharger les roadmaps
      await this.loadRoadmaps();
      
      // Mettre à jour la visualisation si la roadmap est sélectionnée
      if (this.selectedRoadmaps.includes(roadmapId)) {
        await this.visualizeRoadmaps(this.selectedRoadmaps);
      }
      
      return roadmapId;
    } catch (error) {
      console.error('Erreur lors de la mise à jour de la roadmap:', error);
      throw error;
    }
  }

  /**
   * Supprime une roadmap
   * @param {string} roadmapId - ID de la roadmap à supprimer
   */
  async deleteRoadmap(roadmapId) {
    try {
      const response = await fetch(`${this.options.qdrantUrl}/collections/${this.options.qdrantCollection}/points/delete`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          points: [roadmapId]
        })
      });

      if (!response.ok) {
        throw new Error(`Erreur lors de la suppression de la roadmap: ${response.statusText}`);
      }
      
      // Recharger les roadmaps
      await this.loadRoadmaps();
      
      // Mettre à jour la visualisation si la roadmap supprimée était sélectionnée
      if (this.selectedRoadmaps.includes(roadmapId)) {
        this.selectedRoadmaps = this.selectedRoadmaps.filter(id => id !== roadmapId);
        await this.visualizeRoadmaps(this.selectedRoadmaps);
      }
      
      return true;
    } catch (error) {
      console.error('Erreur lors de la suppression de la roadmap:', error);
      throw error;
    }
  }

  /**
   * Trouve les nœuds communs entre plusieurs roadmaps
   * @param {Array} roadmapIds - IDs des roadmaps à comparer
   */
  async findCommonNodes(roadmapIds) {
    try {
      const roadmapDetails = await this._fetchRoadmapDetails(roadmapIds);
      
      // Créer un dictionnaire pour compter les occurrences de chaque tâche
      const taskOccurrences = new Map();
      
      // Parcourir toutes les tâches de toutes les roadmaps
      roadmapDetails.forEach(roadmap => {
        roadmap.tasks.forEach(task => {
          const taskKey = `${task.title}:${task.description}`;
          if (!taskOccurrences.has(taskKey)) {
            taskOccurrences.set(taskKey, {
              task,
              roadmaps: new Set(),
              count: 0
            });
          }
          
          const entry = taskOccurrences.get(taskKey);
          entry.roadmaps.add(roadmap.id);
          entry.count++;
        });
      });
      
      // Filtrer pour ne garder que les tâches communes à plusieurs roadmaps
      const commonNodes = Array.from(taskOccurrences.values())
        .filter(entry => entry.count > 1)
        .map(entry => ({
          ...entry.task,
          roadmaps: Array.from(entry.roadmaps),
          occurrenceCount: entry.count
        }));
      
      return commonNodes;
    } catch (error) {
      console.error('Erreur lors de la recherche des nœuds communs:', error);
      throw error;
    }
  }

  /**
   * Détecte les conflits potentiels entre les roadmaps
   */
  async detectConflicts() {
    try {
      const commonNodes = await this.findCommonNodes(this.selectedRoadmaps);
      
      // Rechercher les conflits (par exemple, même tâche avec des dépendances différentes)
      const conflicts = [];
      
      for (const node of commonNodes) {
        // Récupérer les détails de cette tâche dans chaque roadmap
        const taskVersions = [];
        
        for (const roadmapId of node.roadmaps) {
          const roadmap = this.roadmaps.find(r => r.id === roadmapId);
          if (roadmap) {
            const task = roadmap.tasks.find(t => t.title === node.title);
            if (task) {
              taskVersions.push({
                roadmapId,
                roadmapTitle: roadmap.title,
                task
              });
            }
          }
        }
        
        // Comparer les versions pour détecter les conflits
        for (let i = 0; i < taskVersions.length; i++) {
          for (let j = i + 1; j < taskVersions.length; j++) {
            const version1 = taskVersions[i];
            const version2 = taskVersions[j];
            
            // Vérifier les différences dans les dépendances
            const deps1 = version1.task.dependencies || [];
            const deps2 = version2.task.dependencies || [];
            
            if (JSON.stringify(deps1.sort()) !== JSON.stringify(deps2.sort())) {
              conflicts.push({
                nodeTitle: node.title,
                type: 'dependency_conflict',
                roadmap1: {
                  id: version1.roadmapId,
                  title: version1.roadmapTitle,
                  dependencies: deps1
                },
                roadmap2: {
                  id: version2.roadmapId,
                  title: version2.roadmapTitle,
                  dependencies: deps2
                }
              });
            }
            
            // Vérifier les différences dans les statuts
            if (version1.task.status !== version2.task.status) {
              conflicts.push({
                nodeTitle: node.title,
                type: 'status_conflict',
                roadmap1: {
                  id: version1.roadmapId,
                  title: version1.roadmapTitle,
                  status: version1.task.status
                },
                roadmap2: {
                  id: version2.roadmapId,
                  title: version2.roadmapTitle,
                  status: version2.task.status
                }
              });
            }
          }
        }
      }
      
      return conflicts;
    } catch (error) {
      console.error('Erreur lors de la détection des conflits:', error);
      throw error;
    }
  }

  // Méthodes privées
  
  /**
   * Crée la feuille de style pour Cytoscape
   * @private
   */
  _createStylesheet() {
    return [
      // Style des nœuds (stations)
      {
        selector: 'node',
        style: {
          'width': this.options.nodeSize,
          'height': this.options.nodeSize,
          'background-color': '#fff',
          'border-width': 3,
          'border-color': '#333',
          'label': 'data(label)',
          'text-valign': 'center',
          'text-halign': 'center',
          'font-size': '10px',
          'text-wrap': 'wrap',
          'text-max-width': '80px'
        }
      },
      // Style des liens (lignes de métro)
      {
        selector: 'edge',
        style: {
          'width': this.options.lineWidth,
          'line-color': 'data(color)',
          'target-arrow-color': 'data(color)',
          'target-arrow-shape': 'triangle',
          'curve-style': 'bezier'
        }
      },
      // Style des nœuds sélectionnés
      {
        selector: 'node:selected',
        style: {
          'border-width': 5,
          'border-color': '#FFC107',
          'background-color': '#FFECB3'
        }
      },
      // Style des nœuds communs
      {
        selector: '.common-node',
        style: {
          'background-color': '#FFF9C4',
          'border-color': '#FFC107',
          'border-width': 4
        }
      },
      // Style des nœuds en conflit
      {
        selector: '.conflict-node',
        style: {
          'background-color': '#FFCDD2',
          'border-color': '#F44336',
          'border-width': 4
        }
      }
    ];
  }

  /**
   * Configure les interactions utilisateur
   * @private
   */
  _setupInteractions() {
    // Double-clic sur un nœud pour afficher les détails
    this.cy.on('dblclick', 'node', event => {
      const node = event.target;
      this._showNodeDetails(node);
    });
    
    // Survol d'un nœud pour afficher une infobulle
    this.cy.on('mouseover', 'node', event => {
      const node = event.target;
      const ref = node.popperRef();
      
      const content = document.createElement('div');
      content.innerHTML = `
        <strong>${node.data('label')}</strong>
        <p>${node.data('description') || 'Aucune description'}</p>
        <p>Statut: ${node.data('status') || 'Non défini'}</p>
      `;
      
      const tip = tippy(ref, {
        content,
        trigger: 'manual',
        arrow: true,
        placement: 'top',
        hideOnClick: false,
        interactive: true,
        appendTo: document.body
      });
      
      tip.show();
      
      node.data('tippy', tip);
    });
    
    this.cy.on('mouseout', 'node', event => {
      const node = event.target;
      const tip = node.data('tippy');
      if (tip) {
        tip.hide();
        tip.destroy();
      }
    });
    
    // Zoom et pan
    this.cy.on('zoom', () => {
      // Ajuster la taille des étiquettes en fonction du niveau de zoom
      const fontSize = Math.max(10, 10 / this.cy.zoom());
      this.cy.style()
        .selector('node')
        .style({
          'font-size': `${fontSize}px`
        })
        .update();
    });
  }

  /**
   * Met à jour le sélecteur de roadmaps
   * @private
   */
  _updateRoadmapSelector() {
    const selector = document.getElementById('roadmap-selector');
    if (!selector) return;
    
    // Vider le sélecteur
    selector.innerHTML = '';
    
    // Ajouter les roadmaps disponibles
    this.roadmaps.forEach(roadmap => {
      const option = document.createElement('option');
      option.value = roadmap.id;
      option.textContent = roadmap.title;
      selector.appendChild(option);
    });
  }

  /**
   * Récupère les détails des roadmaps
   * @param {Array} roadmapIds - IDs des roadmaps à récupérer
   * @private
   */
  async _fetchRoadmapDetails(roadmapIds) {
    try {
      const response = await fetch(`${this.options.qdrantUrl}/collections/${this.options.qdrantCollection}/points`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          ids: roadmapIds,
          with_payload: true,
          with_vector: false
        })
      });

      if (!response.ok) {
        throw new Error(`Erreur lors de la récupération des détails des roadmaps: ${response.statusText}`);
      }

      const data = await response.json();
      return data.result.map(point => ({
        id: point.id,
        ...point.payload
      }));
    } catch (error) {
      console.error('Erreur lors de la récupération des détails des roadmaps:', error);
      throw error;
    }
  }

  /**
   * Construit les éléments du graphe pour Cytoscape
   * @param {Array} roadmaps - Données des roadmaps
   * @private
   */
  _buildGraphElements(roadmaps) {
    const elements = [];
    this.commonNodes = new Map();
    
    // Attribuer une couleur à chaque roadmap
    roadmaps.forEach((roadmap, index) => {
      const colorIndex = index % this.options.metroColors.length;
      roadmap.color = this.options.metroColors[colorIndex];
    });
    
    // Ajouter les nœuds (tâches)
    roadmaps.forEach(roadmap => {
      roadmap.tasks.forEach(task => {
        const nodeId = `${roadmap.id}_${task.id}`;
        
        // Vérifier si c'est un nœud commun
        const taskKey = `${task.title}:${task.description}`;
        if (!this.commonNodes.has(taskKey)) {
          this.commonNodes.set(taskKey, {
            occurrences: [],
            nodeIds: []
          });
        }
        
        const commonNodeEntry = this.commonNodes.get(taskKey);
        commonNodeEntry.occurrences.push({
          roadmapId: roadmap.id,
          taskId: task.id,
          nodeId
        });
        commonNodeEntry.nodeIds.push(nodeId);
        
        // Ajouter le nœud
        elements.push({
          group: 'nodes',
          data: {
            id: nodeId,
            label: task.title,
            description: task.description,
            status: task.status,
            roadmapId: roadmap.id,
            taskId: task.id,
            originalColor: roadmap.color
          }
        });
      });
    });
    
    // Ajouter les liens (dépendances)
    roadmaps.forEach(roadmap => {
      roadmap.tasks.forEach(task => {
        const sourceId = `${roadmap.id}_${task.id}`;
        
        if (task.dependencies && task.dependencies.length > 0) {
          task.dependencies.forEach(depId => {
            const targetId = `${roadmap.id}_${depId}`;
            
            // Vérifier si le nœud cible existe
            if (elements.some(el => el.data && el.data.id === targetId)) {
              elements.push({
                group: 'edges',
                data: {
                  id: `${sourceId}_${targetId}`,
                  source: sourceId,
                  target: targetId,
                  color: roadmap.color
                }
              });
            }
          });
        }
      });
    });
    
    return elements;
  }

  /**
   * Applique un layout de type métro
   * @private
   */
  _applyMetroLayout() {
    // Utiliser le layout dagre pour un rendu de type métro
    const layout = this.cy.layout({
      name: 'dagre',
      rankDir: 'LR', // De gauche à droite
      rankSep: 100, // Espacement entre les rangs
      nodeSep: 50, // Espacement entre les nœuds
      edgeSep: 50, // Espacement entre les arêtes
      ranker: 'network-simplex', // Algorithme de rangement
      padding: 50, // Marge autour du graphe
      fit: true, // Ajuster la vue au graphe
      spacingFactor: 1.5, // Facteur d'espacement
      animate: true, // Animation lors de l'application du layout
      animationDuration: 800, // Durée de l'animation
      animationEasing: 'ease-in-out', // Type d'animation
      ready: function() {}, // Callback quand le layout est prêt
      stop: function() {} // Callback quand le layout est terminé
    });
    
    layout.run();
  }

  /**
   * Met en évidence les nœuds communs
   * @private
   */
  _highlightCommonNodes() {
    // Parcourir tous les nœuds communs
    for (const [taskKey, entry] of this.commonNodes.entries()) {
      if (entry.occurrences.length > 1) {
        // C'est un nœud commun, le mettre en évidence
        entry.nodeIds.forEach(nodeId => {
          const node = this.cy.$(`#${nodeId}`);
          node.addClass('common-node');
        });
      }
    }
  }

  /**
   * Affiche les détails d'un nœud
   * @param {Object} node - Nœud Cytoscape
   * @private
   */
  _showNodeDetails(node) {
    const nodeData = node.data();
    
    // Créer une modal pour afficher les détails
    const modal = document.createElement('div');
    modal.className = 'metro-map-modal';
    modal.innerHTML = `
      <div class="metro-map-modal-content">
        <span class="metro-map-modal-close">&times;</span>
        <h2>${nodeData.label}</h2>
        <p>${nodeData.description || 'Aucune description'}</p>
        <p><strong>Statut:</strong> ${nodeData.status || 'Non défini'}</p>
        <p><strong>Roadmap:</strong> ${this.roadmaps.find(r => r.id === nodeData.roadmapId)?.title || nodeData.roadmapId}</p>
        
        <div class="metro-map-modal-actions">
          <button class="metro-map-btn metro-map-btn-edit">Modifier</button>
          <button class="metro-map-btn metro-map-btn-delete">Supprimer</button>
        </div>
      </div>
    `;
    
    document.body.appendChild(modal);
    
    // Gérer la fermeture de la modal
    const closeBtn = modal.querySelector('.metro-map-modal-close');
    closeBtn.addEventListener('click', () => {
      document.body.removeChild(modal);
    });
    
    // Gérer les actions
    const editBtn = modal.querySelector('.metro-map-btn-edit');
    editBtn.addEventListener('click', () => {
      // Implémenter l'édition du nœud
      document.body.removeChild(modal);
      this._editNode(nodeData);
    });
    
    const deleteBtn = modal.querySelector('.metro-map-btn-delete');
    deleteBtn.addEventListener('click', () => {
      // Implémenter la suppression du nœud
      document.body.removeChild(modal);
      this._deleteNode(nodeData);
    });
  }

  /**
   * Édite un nœud
   * @param {Object} nodeData - Données du nœud
   * @private
   */
  _editNode(nodeData) {
    // À implémenter
    console.log('Édition du nœud:', nodeData);
  }

  /**
   * Supprime un nœud
   * @param {Object} nodeData - Données du nœud
   * @private
   */
  _deleteNode(nodeData) {
    // À implémenter
    console.log('Suppression du nœud:', nodeData);
  }
}

export default MetroMapVisualizer;
