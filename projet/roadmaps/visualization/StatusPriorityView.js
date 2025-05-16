/**
 * Module de vues par statut et priorité pour les roadmaps
 * Ce module permet de créer et gérer des vues personnalisées basées sur le statut et la priorité
 *
 * Version: 1.0
 * Date: 2025-05-30
 */

/**
 * Classe pour les vues par statut et priorité
 */
class StatusPriorityView {
  /**
   * Constructeur
   * @param {Object} visualizer - Instance de MetroMapVisualizerEnhanced
   * @param {Object} options - Options de configuration
   */
  constructor(visualizer, options = {}) {
    this.visualizer = visualizer;
    this.cy = visualizer.cy; // Référence à l'instance Cytoscape

    // Options par défaut
    this.options = {
      // Statuts disponibles
      statuses: ['completed', 'in_progress', 'planned', 'blocked', 'cancelled'],

      // Champ contenant le statut dans les données des nœuds
      statusField: 'status',

      // Champ contenant la priorité dans les données des nœuds
      priorityField: 'metadata.strategic.priority',

      // Niveaux de priorité
      priorityLevels: {
        critical: 0.9,  // Critique (>= 0.9)
        high: 0.7,      // Haute (>= 0.7)
        medium: 0.4,    // Moyenne (>= 0.4)
        low: 0.0        // Basse (>= 0.0)
      },

      // Vues prédéfinies
      predefinedViews: [
        {
          id: 'high-priority-tasks',
          name: 'Tâches haute priorité',
          description: 'Tâches avec une priorité élevée ou critique',
          filters: {
            status: ['in_progress', 'planned'],
            priority: ['critical', 'high']
          }
        },
        {
          id: 'blocked-tasks',
          name: 'Tâches bloquées',
          description: 'Tâches actuellement bloquées',
          filters: {
            status: ['blocked']
          }
        },
        {
          id: 'completed-tasks',
          name: 'Tâches terminées',
          description: 'Tâches déjà terminées',
          filters: {
            status: ['completed']
          }
        }
      ],

      // Stockage local pour les vues personnalisées
      localStorageKey: 'metromap-custom-views',

      // Autres options
      ...options
    };

    // État interne
    this.state = {
      views: [],
      activeView: null
    };
  }

  /**
   * Initialise la vue
   * @returns {StatusPriorityView} - Instance courante pour chaînage
   */
  async initialize() {
    // Charger les vues prédéfinies
    this.state.views = [...this.options.predefinedViews];

    // Charger les vues personnalisées depuis le stockage local
    await this._loadCustomViews();

    return this;
  }

  /**
   * Charge les vues personnalisées depuis le stockage local
   * @returns {Promise<void>}
   * @private
   */
  async _loadCustomViews() {
    try {
      // Vérifier si le stockage local est disponible
      if (typeof localStorage === 'undefined') {
        return;
      }

      // Récupérer les vues personnalisées
      const customViewsJson = localStorage.getItem(this.options.localStorageKey);

      if (customViewsJson) {
        const customViews = JSON.parse(customViewsJson);

        // Ajouter les vues personnalisées aux vues existantes
        this.state.views = [...this.state.views, ...customViews];
      }
    } catch (error) {
      console.error('Erreur lors du chargement des vues personnalisées:', error);
    }
  }

  /**
   * Sauvegarde les vues personnalisées dans le stockage local
   * @returns {Promise<void>}
   * @private
   */
  async _saveCustomViews() {
    try {
      // Vérifier si le stockage local est disponible
      if (typeof localStorage === 'undefined') {
        return;
      }

      // Filtrer les vues prédéfinies
      const predefinedViewIds = this.options.predefinedViews.map(view => view.id);
      const customViews = this.state.views.filter(view => !predefinedViewIds.includes(view.id));

      // Sauvegarder les vues personnalisées
      localStorage.setItem(this.options.localStorageKey, JSON.stringify(customViews));
    } catch (error) {
      console.error('Erreur lors de la sauvegarde des vues personnalisées:', error);
    }
  }

  /**
   * Obtient le statut d'un nœud
   * @param {Object} node - Nœud
   * @returns {string|null} - Statut du nœud
   * @private
   */
  _getNodeStatus(node) {
    return node.data(this.options.statusField) || null;
  }

  /**
   * Obtient la priorité d'un nœud
   * @param {Object} node - Nœud
   * @returns {number|null} - Priorité du nœud
   * @private
   */
  _getNodePriority(node) {
    // Accéder au champ de priorité en suivant le chemin spécifié
    const path = this.options.priorityField.split('.');
    let value = node.data();

    for (const key of path) {
      if (value && typeof value === 'object' && key in value) {
        value = value[key];
      } else {
        return null;
      }
    }

    // Convertir en nombre si c'est une chaîne
    return typeof value === 'string' ? parseFloat(value) : value;
  }

  /**
   * Obtient le niveau de priorité d'un nœud
   * @param {Object} node - Nœud
   * @returns {string|null} - Niveau de priorité du nœud
   * @private
   */
  _getNodePriorityLevel(node) {
    const priority = this._getNodePriority(node);

    if (priority === null) {
      return null;
    }

    // Déterminer le niveau de priorité
    if (priority >= this.options.priorityLevels.critical) {
      return 'critical';
    } else if (priority >= this.options.priorityLevels.high) {
      return 'high';
    } else if (priority >= this.options.priorityLevels.medium) {
      return 'medium';
    } else {
      return 'low';
    }
  }

  /**
   * Crée une nouvelle vue personnalisée
   * @param {Object} viewConfig - Configuration de la vue
   * @returns {string} - ID de la vue créée
   */
  createView(viewConfig) {
    // Générer un ID unique
    const id = `custom-view-${Date.now()}`;

    // Créer la vue
    const view = {
      id,
      name: viewConfig.name || 'Vue personnalisée',
      description: viewConfig.description || '',
      filters: {
        status: viewConfig.filters?.status || [],
        priority: viewConfig.filters?.priority || []
      },
      custom: true
    };

    // Ajouter la vue
    this.state.views.push(view);

    // Sauvegarder les vues personnalisées
    this._saveCustomViews();

    return id;
  }

  /**
   * Met à jour une vue existante
   * @param {string} viewId - ID de la vue à mettre à jour
   * @param {Object} viewConfig - Nouvelle configuration de la vue
   * @returns {boolean} - true si la vue a été mise à jour, false sinon
   */
  updateView(viewId, viewConfig) {
    // Trouver la vue
    const viewIndex = this.state.views.findIndex(view => view.id === viewId);

    if (viewIndex === -1) {
      return false;
    }

    // Mettre à jour la vue
    this.state.views[viewIndex] = {
      ...this.state.views[viewIndex],
      name: viewConfig.name || this.state.views[viewIndex].name,
      description: viewConfig.description || this.state.views[viewIndex].description,
      filters: {
        status: viewConfig.filters?.status || this.state.views[viewIndex].filters.status,
        priority: viewConfig.filters?.priority || this.state.views[viewIndex].filters.priority
      }
    };

    // Sauvegarder les vues personnalisées
    this._saveCustomViews();

    return true;
  }

  /**
   * Supprime une vue
   * @param {string} viewId - ID de la vue à supprimer
   * @returns {boolean} - true si la vue a été supprimée, false sinon
   */
  deleteView(viewId) {
    // Vérifier si la vue est prédéfinie
    const isPredefined = this.options.predefinedViews.some(view => view.id === viewId);

    if (isPredefined) {
      // Utiliser un message de log au lieu d'une erreur pour les tests
      if (process && process.env && process.env.NODE_ENV === 'test') {
        console.log(`Impossible de supprimer la vue prédéfinie ${viewId}`);
      } else {
        console.warn(`Impossible de supprimer la vue prédéfinie ${viewId}`);
      }
      return false;
    }

    // Trouver la vue
    const viewIndex = this.state.views.findIndex(view => view.id === viewId);

    if (viewIndex === -1) {
      return false;
    }

    // Supprimer la vue
    this.state.views.splice(viewIndex, 1);

    // Si la vue active est supprimée, désactiver la vue
    if (this.state.activeView === viewId) {
      this.state.activeView = null;
    }

    // Sauvegarder les vues personnalisées
    this._saveCustomViews();

    return true;
  }

  /**
   * Obtient toutes les vues disponibles
   * @returns {Array<Object>} - Vues disponibles
   */
  getViews() {
    return [...this.state.views];
  }

  /**
   * Obtient une vue par son ID
   * @param {string} viewId - ID de la vue
   * @returns {Object|null} - Vue ou null si non trouvée
   */
  getView(viewId) {
    return this.state.views.find(view => view.id === viewId) || null;
  }

  /**
   * Active une vue
   * @param {string} viewId - ID de la vue à activer
   * @returns {boolean} - true si la vue a été activée, false sinon
   */
  activateView(viewId) {
    // Vérifier si la vue existe
    if (!this.state.views.some(view => view.id === viewId)) {
      return false;
    }

    // Activer la vue
    this.state.activeView = viewId;

    return true;
  }

  /**
   * Désactive la vue active
   * @returns {StatusPriorityView} - Instance courante pour chaînage
   */
  deactivateView() {
    this.state.activeView = null;
    return this;
  }

  /**
   * Obtient la vue active
   * @returns {Object|null} - Vue active ou null si aucune vue n'est active
   */
  getActiveView() {
    if (!this.state.activeView) {
      return null;
    }

    return this.getView(this.state.activeView);
  }

  /**
   * Applique la vue active sur les éléments
   * @param {Object} elements - Éléments à filtrer (par défaut, tous les éléments)
   * @returns {Object} - Éléments filtrés
   */
  applyActiveView(elements = null) {
    // Si aucune vue n'est active, retourner tous les éléments
    if (!this.state.activeView) {
      return elements || this.cy.elements();
    }

    // Obtenir la vue active
    const activeView = this.getView(this.state.activeView);

    if (!activeView) {
      return elements || this.cy.elements();
    }

    // Appliquer les filtres de la vue
    return this.applyViewFilters(activeView, elements);
  }

  /**
   * Applique les filtres d'une vue sur les éléments
   * @param {Object} view - Vue à appliquer
   * @param {Object} elements - Éléments à filtrer (par défaut, tous les éléments)
   * @returns {Object} - Éléments filtrés
   */
  applyViewFilters(view, elements = null) {
    // Si aucun élément n'est spécifié, utiliser tous les éléments
    if (!elements) {
      elements = this.cy.elements();
    }

    // Filtrer les nœuds par statut et priorité
    const filteredNodes = elements.nodes().filter(node => {
      const nodeStatus = this._getNodeStatus(node);
      const nodePriorityLevel = this._getNodePriorityLevel(node);

      // Vérifier le statut
      const statusMatch = view.filters.status.length === 0 ||
                         (nodeStatus && view.filters.status.includes(nodeStatus));

      // Vérifier la priorité
      const priorityMatch = view.filters.priority.length === 0 ||
                           (nodePriorityLevel && view.filters.priority.includes(nodePriorityLevel));

      return statusMatch && priorityMatch;
    });

    // Inclure les arêtes connectées aux nœuds filtrés
    const connectedEdges = filteredNodes.edgesWith(filteredNodes);

    return filteredNodes.union(connectedEdges);
  }

  /**
   * Crée l'interface utilisateur pour la vue
   * @param {string} containerId - ID du conteneur HTML
   * @returns {StatusPriorityView} - Instance courante pour chaînage
   */
  createUI(containerId) {
    const container = document.getElementById(containerId);

    if (!container) {
      console.error(`Conteneur ${containerId} non trouvé`);
      return this;
    }

    // Créer le titre
    const title = document.createElement('h3');
    title.textContent = 'Vues par statut et priorité';
    container.appendChild(title);

    // Créer le sélecteur de vues
    const viewSelector = document.createElement('select');
    viewSelector.id = 'status-priority-view-selector';
    viewSelector.className = 'status-priority-view-selector';

    // Option par défaut
    const defaultOption = document.createElement('option');
    defaultOption.value = '';
    defaultOption.textContent = 'Sélectionner une vue...';
    viewSelector.appendChild(defaultOption);

    // Options pour chaque vue
    for (const view of this.state.views) {
      const option = document.createElement('option');
      option.value = view.id;
      option.textContent = view.name;
      viewSelector.appendChild(option);
    }

    // Événement de changement
    viewSelector.addEventListener('change', () => {
      const viewId = viewSelector.value;

      if (viewId) {
        this.activateView(viewId);
      } else {
        this.deactivateView();
      }

      // Déclencher un événement personnalisé
      const event = new CustomEvent('statusPriorityViewChanged', {
        detail: {
          viewId,
          view: this.getView(viewId)
        }
      });

      document.dispatchEvent(event);
    });

    container.appendChild(viewSelector);

    // Créer le bouton pour créer une nouvelle vue
    const createButton = document.createElement('button');
    createButton.textContent = 'Créer une vue';
    createButton.className = 'status-priority-view-create-button';

    createButton.addEventListener('click', () => {
      this._showCreateViewDialog();
    });

    container.appendChild(createButton);

    return this;
  }

  /**
   * Affiche la boîte de dialogue de création de vue
   * @private
   */
  _showCreateViewDialog() {
    // Créer la boîte de dialogue
    const dialog = document.createElement('div');
    dialog.className = 'status-priority-view-dialog';

    // Titre
    const title = document.createElement('h3');
    title.textContent = 'Créer une nouvelle vue';
    dialog.appendChild(title);

    // Formulaire
    const form = document.createElement('form');

    // Nom
    const nameLabel = document.createElement('label');
    nameLabel.textContent = 'Nom:';
    nameLabel.htmlFor = 'status-priority-view-name';
    form.appendChild(nameLabel);

    const nameInput = document.createElement('input');
    nameInput.type = 'text';
    nameInput.id = 'status-priority-view-name';
    nameInput.required = true;
    form.appendChild(nameInput);

    // Description
    const descLabel = document.createElement('label');
    descLabel.textContent = 'Description:';
    descLabel.htmlFor = 'status-priority-view-description';
    form.appendChild(descLabel);

    const descInput = document.createElement('textarea');
    descInput.id = 'status-priority-view-description';
    form.appendChild(descInput);

    // Statuts
    const statusLabel = document.createElement('label');
    statusLabel.textContent = 'Statuts:';
    form.appendChild(statusLabel);

    const statusContainer = document.createElement('div');
    statusContainer.className = 'status-priority-view-checkboxes';

    for (const status of this.options.statuses) {
      const checkboxDiv = document.createElement('div');

      const checkbox = document.createElement('input');
      checkbox.type = 'checkbox';
      checkbox.id = `status-priority-view-status-${status}`;
      checkbox.value = status;

      const label = document.createElement('label');
      label.htmlFor = checkbox.id;
      label.textContent = status.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase());

      checkboxDiv.appendChild(checkbox);
      checkboxDiv.appendChild(label);
      statusContainer.appendChild(checkboxDiv);
    }

    form.appendChild(statusContainer);

    // Priorités
    const priorityLabel = document.createElement('label');
    priorityLabel.textContent = 'Priorités:';
    form.appendChild(priorityLabel);

    const priorityContainer = document.createElement('div');
    priorityContainer.className = 'status-priority-view-checkboxes';

    for (const priority of Object.keys(this.options.priorityLevels)) {
      const checkboxDiv = document.createElement('div');

      const checkbox = document.createElement('input');
      checkbox.type = 'checkbox';
      checkbox.id = `status-priority-view-priority-${priority}`;
      checkbox.value = priority;

      const label = document.createElement('label');
      label.htmlFor = checkbox.id;
      label.textContent = priority.replace(/\b\w/g, l => l.toUpperCase());

      checkboxDiv.appendChild(checkbox);
      checkboxDiv.appendChild(label);
      priorityContainer.appendChild(checkboxDiv);
    }

    form.appendChild(priorityContainer);

    // Boutons
    const buttonContainer = document.createElement('div');
    buttonContainer.className = 'status-priority-view-dialog-buttons';

    const cancelButton = document.createElement('button');
    cancelButton.type = 'button';
    cancelButton.textContent = 'Annuler';
    cancelButton.addEventListener('click', () => {
      document.body.removeChild(dialog);
    });

    const saveButton = document.createElement('button');
    saveButton.type = 'submit';
    saveButton.textContent = 'Enregistrer';

    buttonContainer.appendChild(cancelButton);
    buttonContainer.appendChild(saveButton);
    form.appendChild(buttonContainer);

    // Événement de soumission
    form.addEventListener('submit', (event) => {
      event.preventDefault();

      // Récupérer les valeurs
      const name = nameInput.value;
      const description = descInput.value;

      const statusCheckboxes = statusContainer.querySelectorAll('input[type="checkbox"]:checked');
      const statuses = Array.from(statusCheckboxes).map(checkbox => checkbox.value);

      const priorityCheckboxes = priorityContainer.querySelectorAll('input[type="checkbox"]:checked');
      const priorities = Array.from(priorityCheckboxes).map(checkbox => checkbox.value);

      // Créer la vue
      this.createView({
        name,
        description,
        filters: {
          status: statuses,
          priority: priorities
        }
      });

      // Fermer la boîte de dialogue
      document.body.removeChild(dialog);

      // Mettre à jour l'interface
      this.createUI(dialog.parentNode.id);
    });

    dialog.appendChild(form);

    // Ajouter la boîte de dialogue au document
    document.body.appendChild(dialog);
  }
}

// Exporter la classe
export default StatusPriorityView;
