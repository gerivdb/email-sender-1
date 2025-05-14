/**
 * MetroMapInteractiveRenderer.js
 * Système de rendu graphique interactif pour la visualisation en carte de métro
 *
 * Ce module fournit des fonctionnalités interactives avancées pour la visualisation
 * des roadmaps en carte de métro, notamment le zoom sémantique, les animations,
 * les tooltips et les contrôles d'interface utilisateur.
 *
 * Version: 1.0
 * Date: 2025-05-15
 */

/**
 * Classe principale pour le rendu interactif des cartes de métro
 */
class MetroMapInteractiveRenderer {
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
      // Options d'animation
      animation: {
        nodeSelectionDuration: 300,
        layoutTransitionDuration: 500,
        zoomDuration: 400,
        highlightDuration: 200
      },

      // Options de tooltip
      tooltip: {
        showDelay: 300,
        hideDelay: 100,
        position: 'top',
        offsetX: 10,
        offsetY: -10,
        className: 'metro-map-tooltip',
        interactive: true
      },

      // Options de modal
      modal: {
        showAnimation: 'fade',
        closeOnEscape: true,
        closeOnClickOutside: true,
        width: '500px',
        className: 'metro-map-modal'
      },

      // Options de contrôles
      controls: {
        position: 'top-right',
        showZoom: true,
        showReset: true,
        showFullscreen: true,
        showExport: true,
        showLegend: true
      },

      // Options de zoom sémantique
      semanticZoom: {
        enabled: true,
        levels: [
          { name: 'overview', scale: 0.5, nodeSize: 20, edgeWidth: 3, labelVisible: false },
          { name: 'default', scale: 1.0, nodeSize: 30, edgeWidth: 5, labelVisible: true },
          { name: 'detail', scale: 2.0, nodeSize: 40, edgeWidth: 7, labelVisible: true }
        ],
        thresholds: [0.7, 1.5]
      },

      // Fusionner avec les options fournies
      ...options
    };

    // État interne
    this.state = {
      currentZoomLevel: 'default',
      selectedNodes: new Set(),
      hoveredNode: null,
      isModalOpen: false,
      tooltips: new Map(), // Map des tooltips actifs
      controlsContainer: null, // Conteneur des contrôles
      legendContainer: null, // Conteneur de la légende
      fullscreenElement: null // Élément en plein écran
    };

    // Initialiser le rendu interactif
    this._initialize();
  }

  /**
   * Initialise le rendu interactif
   * @private
   */
  _initialize() {
    // Vérifier que Cytoscape est disponible
    if (!this.cy) {
      console.error('Cytoscape n\'est pas initialisé dans le visualiseur');
      return;
    }

    // Configurer les interactions
    this._setupInteractions();

    // Créer les contrôles d'interface utilisateur
    if (this.options.controls) {
      this._createControls();
    }

    // Configurer le zoom sémantique
    if (this.options.semanticZoom && this.options.semanticZoom.enabled) {
      this._setupSemanticZoom();
    }

    // Créer la légende
    if (this.options.controls && this.options.controls.showLegend) {
      this._createLegend();
    }

    // Ajouter les styles CSS nécessaires
    this._addStyles();
  }

  /**
   * Crée les contrôles d'interface utilisateur
   * @private
   */
  _createControls() {
    // Créer le conteneur des contrôles
    const controlsContainer = document.createElement('div');
    controlsContainer.className = 'metro-map-controls';
    controlsContainer.classList.add(`position-${this.options.controls.position}`);

    // Stocker le conteneur dans l'état
    this.state.controlsContainer = controlsContainer;

    // Ajouter les contrôles de zoom si activés
    if (this.options.controls.showZoom) {
      const zoomControls = document.createElement('div');
      zoomControls.className = 'metro-map-control-group';

      // Bouton de zoom avant
      const zoomInBtn = document.createElement('button');
      zoomInBtn.className = 'metro-map-control-btn';
      zoomInBtn.innerHTML = '<svg viewBox="0 0 24 24"><path d="M19 13h-6v6h-2v-6H5v-2h6V5h2v6h6z"/></svg>';
      zoomInBtn.title = 'Zoom avant';
      zoomInBtn.addEventListener('click', () => {
        this.cy.animate({
          zoom: this.cy.zoom() * 1.2,
          duration: this.options.animation.zoomDuration / 2
        });
      });

      // Bouton de zoom arrière
      const zoomOutBtn = document.createElement('button');
      zoomOutBtn.className = 'metro-map-control-btn';
      zoomOutBtn.innerHTML = '<svg viewBox="0 0 24 24"><path d="M19 13H5v-2h14z"/></svg>';
      zoomOutBtn.title = 'Zoom arrière';
      zoomOutBtn.addEventListener('click', () => {
        this.cy.animate({
          zoom: this.cy.zoom() / 1.2,
          duration: this.options.animation.zoomDuration / 2
        });
      });

      // Ajouter les boutons au groupe
      zoomControls.appendChild(zoomInBtn);
      zoomControls.appendChild(zoomOutBtn);

      // Ajouter le groupe au conteneur
      controlsContainer.appendChild(zoomControls);
    }

    // Ajouter le bouton de réinitialisation si activé
    if (this.options.controls.showReset) {
      const resetBtn = document.createElement('button');
      resetBtn.className = 'metro-map-control-btn';
      resetBtn.innerHTML = '<svg viewBox="0 0 24 24"><path d="M17.65 6.35C16.2 4.9 14.21 4 12 4c-4.42 0-7.99 3.58-7.99 8s3.57 8 7.99 8c3.73 0 6.84-2.55 7.73-6h-2.08c-.82 2.33-3.04 4-5.65 4-3.31 0-6-2.69-6-6s2.69-6 6-6c1.66 0 3.14.69 4.22 1.78L13 11h7V4l-2.35 2.35z"/></svg>';
      resetBtn.title = 'Réinitialiser la vue';
      resetBtn.addEventListener('click', () => {
        this.cy.animate({
          fit: {
            eles: this.cy.elements(),
            padding: 50
          },
          duration: this.options.animation.zoomDuration
        });
      });

      // Ajouter le bouton au conteneur
      controlsContainer.appendChild(resetBtn);
    }

    // Ajouter le bouton de plein écran si activé
    if (this.options.controls.showFullscreen) {
      const fullscreenBtn = document.createElement('button');
      fullscreenBtn.className = 'metro-map-control-btn';
      fullscreenBtn.innerHTML = '<svg viewBox="0 0 24 24"><path d="M7 14H5v5h5v-2H7v-3zm-2-4h2V7h3V5H5v5zm12 7h-3v2h5v-5h-2v3zM14 5v2h3v3h2V5h-5z"/></svg>';
      fullscreenBtn.title = 'Plein écran';
      fullscreenBtn.addEventListener('click', () => {
        this._toggleFullscreen();
      });

      // Ajouter le bouton au conteneur
      controlsContainer.appendChild(fullscreenBtn);
    }

    // Ajouter le bouton d'exportation si activé
    if (this.options.controls.showExport) {
      const exportBtn = document.createElement('button');
      exportBtn.className = 'metro-map-control-btn';
      exportBtn.innerHTML = '<svg viewBox="0 0 24 24"><path d="M19 9h-4V3H9v6H5l7 7 7-7zM5 18v2h14v-2H5z"/></svg>';
      exportBtn.title = 'Exporter';
      exportBtn.addEventListener('click', () => {
        this._showExportOptions();
      });

      // Ajouter le bouton au conteneur
      controlsContainer.appendChild(exportBtn);
    }

    // Ajouter le conteneur au conteneur Cytoscape
    this.cy.container().appendChild(controlsContainer);
  }

  /**
   * Crée la légende
   * @private
   */
  _createLegend() {
    // Créer le conteneur de la légende
    const legendContainer = document.createElement('div');
    legendContainer.className = 'metro-map-legend';

    // Stocker le conteneur dans l'état
    this.state.legendContainer = legendContainer;

    // Construire le contenu de la légende
    legendContainer.innerHTML = `
      <div class="metro-map-legend-header">
        <h3>Légende</h3>
        <button class="metro-map-legend-toggle">▼</button>
      </div>
      <div class="metro-map-legend-content">
        <div class="metro-map-legend-section">
          <h4>Statuts</h4>
          <ul class="metro-map-legend-items">
            <li class="metro-map-legend-item">
              <span class="legend-color" style="background-color: #4CAF50;"></span>
              <span class="legend-label">Complété</span>
            </li>
            <li class="metro-map-legend-item">
              <span class="legend-color" style="background-color: #2196F3;"></span>
              <span class="legend-label">En cours</span>
            </li>
            <li class="metro-map-legend-item">
              <span class="legend-color" style="background-color: #9E9E9E;"></span>
              <span class="legend-label">Planifié</span>
            </li>
          </ul>
        </div>
        <div class="metro-map-legend-section">
          <h4>Interactions</h4>
          <ul class="metro-map-legend-items">
            <li class="metro-map-legend-item">
              <span class="legend-icon">🖱️</span>
              <span class="legend-label">Clic: Sélectionner</span>
            </li>
            <li class="metro-map-legend-item">
              <span class="legend-icon">👆</span>
              <span class="legend-label">Double-clic: Zoomer</span>
            </li>
            <li class="metro-map-legend-item">
              <span class="legend-icon">✋</span>
              <span class="legend-label">Glisser: Déplacer</span>
            </li>
          </ul>
        </div>
      </div>
    `;

    // Ajouter le gestionnaire pour le bouton de bascule
    const toggleBtn = legendContainer.querySelector('.metro-map-legend-toggle');
    const content = legendContainer.querySelector('.metro-map-legend-content');

    toggleBtn.addEventListener('click', () => {
      content.classList.toggle('collapsed');
      toggleBtn.textContent = content.classList.contains('collapsed') ? '▲' : '▼';
    });

    // Ajouter le conteneur au conteneur Cytoscape
    this.cy.container().appendChild(legendContainer);
  }

  /**
   * Bascule en mode plein écran
   * @private
   */
  _toggleFullscreen() {
    const container = this.cy.container();

    if (!document.fullscreenElement) {
      // Passer en plein écran
      if (container.requestFullscreen) {
        container.requestFullscreen();
      } else if (container.mozRequestFullScreen) {
        container.mozRequestFullScreen();
      } else if (container.webkitRequestFullscreen) {
        container.webkitRequestFullscreen();
      } else if (container.msRequestFullscreen) {
        container.msRequestFullscreen();
      }

      // Mettre à jour l'état
      this.state.fullscreenElement = container;
    } else {
      // Quitter le plein écran
      if (document.exitFullscreen) {
        document.exitFullscreen();
      } else if (document.mozCancelFullScreen) {
        document.mozCancelFullScreen();
      } else if (document.webkitExitFullscreen) {
        document.webkitExitFullscreen();
      } else if (document.msExitFullscreen) {
        document.msExitFullscreen();
      }

      // Mettre à jour l'état
      this.state.fullscreenElement = null;
    }
  }

  /**
   * Affiche les options d'exportation
   * @private
   */
  _showExportOptions() {
    // Créer la modale
    const modal = document.createElement('div');
    modal.className = 'metro-map-modal';

    // Construire le contenu de la modale
    modal.innerHTML = `
      <div class="metro-map-modal-content" style="width: 400px">
        <div class="metro-map-modal-header">
          <h2>Exporter la visualisation</h2>
          <button class="metro-map-modal-close">&times;</button>
        </div>
        <div class="metro-map-modal-body">
          <div class="metro-map-export-options">
            <div class="export-option">
              <h3>Format</h3>
              <div class="export-option-items">
                <label>
                  <input type="radio" name="export-format" value="png" checked>
                  PNG
                </label>
                <label>
                  <input type="radio" name="export-format" value="jpg">
                  JPG
                </label>
                <label>
                  <input type="radio" name="export-format" value="svg">
                  SVG
                </label>
              </div>
            </div>
            <div class="export-option">
              <h3>Qualité</h3>
              <div class="export-option-items">
                <label>
                  <input type="range" name="export-quality" min="1" max="4" value="2" step="1">
                  <span class="quality-label">Standard (2x)</span>
                </label>
              </div>
            </div>
            <div class="export-option">
              <h3>Options</h3>
              <div class="export-option-items">
                <label>
                  <input type="checkbox" name="export-background" checked>
                  Inclure l'arrière-plan
                </label>
                <label>
                  <input type="checkbox" name="export-controls" checked>
                  Masquer les contrôles
                </label>
              </div>
            </div>
          </div>
          <div class="metro-map-modal-actions">
            <button class="metro-map-btn metro-map-btn-primary" data-action="export">Exporter</button>
            <button class="metro-map-btn" data-action="cancel">Annuler</button>
          </div>
        </div>
      </div>
    `;

    // Ajouter la modale au document
    document.body.appendChild(modal);

    // Mettre à jour l'état
    this.state.isModalOpen = true;

    // Ajouter les gestionnaires d'événements
    const closeBtn = modal.querySelector('.metro-map-modal-close');
    closeBtn.addEventListener('click', () => {
      this._closeModal(modal);
    });

    // Gestionnaire pour le curseur de qualité
    const qualityInput = modal.querySelector('input[name="export-quality"]');
    const qualityLabel = modal.querySelector('.quality-label');

    qualityInput.addEventListener('input', () => {
      const value = qualityInput.value;
      let label = '';

      switch (value) {
        case '1':
          label = 'Basse (1x)';
          break;
        case '2':
          label = 'Standard (2x)';
          break;
        case '3':
          label = 'Haute (3x)';
          break;
        case '4':
          label = 'Ultra (4x)';
          break;
      }

      qualityLabel.textContent = label;
    });

    // Gestionnaire pour le bouton d'exportation
    const exportBtn = modal.querySelector('[data-action="export"]');
    exportBtn.addEventListener('click', () => {
      // Récupérer les options d'exportation
      const format = modal.querySelector('input[name="export-format"]:checked').value;
      const quality = parseInt(modal.querySelector('input[name="export-quality"]').value);
      const includeBackground = modal.querySelector('input[name="export-background"]').checked;
      const hideControls = modal.querySelector('input[name="export-controls"]').checked;

      // Exporter la visualisation
      this._exportVisualization(format, quality, includeBackground, hideControls);

      // Fermer la modale
      this._closeModal(modal);
    });

    // Gestionnaire pour le bouton d'annulation
    const cancelBtn = modal.querySelector('[data-action="cancel"]');
    cancelBtn.addEventListener('click', () => {
      this._closeModal(modal);
    });

    // Animer l'ouverture de la modale
    setTimeout(() => {
      modal.classList.add('open');
    }, 10);
  }

  /**
   * Exporte la visualisation
   * @param {string} format - Format d'exportation (png, jpg, svg)
   * @param {number} quality - Qualité d'exportation (1-4)
   * @param {boolean} includeBackground - Inclure l'arrière-plan
   * @param {boolean} hideControls - Masquer les contrôles
   * @private
   */
  _exportVisualization(format, quality, includeBackground, hideControls) {
    // Masquer temporairement les contrôles si nécessaire
    if (hideControls) {
      if (this.state.controlsContainer) {
        this.state.controlsContainer.style.display = 'none';
      }
      if (this.state.legendContainer) {
        this.state.legendContainer.style.display = 'none';
      }
    }

    // Configurer les options d'exportation
    const options = {
      output: 'blob',
      scale: quality,
      bg: includeBackground ? '#ffffff' : 'transparent',
      full: true
    };

    // Exporter la visualisation
    let exportPromise;

    switch (format) {
      case 'png':
        exportPromise = this.cy.png(options);
        break;
      case 'jpg':
        options.bg = includeBackground ? '#ffffff' : '#000000'; // JPG ne supporte pas la transparence
        exportPromise = this.cy.jpg(options);
        break;
      case 'svg':
        exportPromise = this.cy.svg(options);
        break;
      default:
        exportPromise = this.cy.png(options);
    }

    // Traiter le résultat
    exportPromise
      .then(blob => {
        // Créer un lien de téléchargement
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `metro-map.${format}`;
        a.click();

        // Libérer l'URL
        setTimeout(() => {
          URL.revokeObjectURL(url);
        }, 100);
      })
      .catch(error => {
        console.error('Erreur lors de l\'exportation:', error);
        // Afficher un message d'erreur à l'utilisateur
        alert('Erreur lors de l\'exportation. Veuillez réessayer.');
      })
      .finally(() => {
        // Restaurer les contrôles, qu'il y ait eu une erreur ou non
        if (hideControls) {
          if (this.state.controlsContainer) {
            this.state.controlsContainer.style.display = '';
          }
          if (this.state.legendContainer) {
            this.state.legendContainer.style.display = '';
          }
        }
      });
  }

  /**
   * Ajoute les styles CSS nécessaires
   * @private
   */
  _addStyles() {
    // Vérifier si les styles existent déjà
    if (document.getElementById('metro-map-interactive-styles')) {
      return;
    }

    // Créer l'élément de style
    const style = document.createElement('style');
    style.id = 'metro-map-interactive-styles';

    // Définir les styles
    style.textContent = `
      /* Styles pour les tooltips */
      .metro-map-tooltip {
        position: absolute;
        z-index: 1000;
        background-color: rgba(255, 255, 255, 0.95);
        border-radius: 4px;
        box-shadow: 0 2px 5px rgba(0, 0, 0, 0.2);
        padding: 8px 12px;
        font-size: 14px;
        max-width: 300px;
        pointer-events: none;
        opacity: 0;
        transform: translateY(5px);
        transition: opacity 0.2s, transform 0.2s;
      }

      .metro-map-tooltip.visible {
        opacity: 1;
        transform: translateY(0);
      }

      .tooltip-header {
        margin-bottom: 5px;
        border-bottom: 1px solid #eee;
        padding-bottom: 5px;
      }

      .tooltip-body p {
        margin: 5px 0;
      }

      /* Styles pour les modales */
      .metro-map-modal {
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background-color: rgba(0, 0, 0, 0.5);
        display: flex;
        justify-content: center;
        align-items: center;
        z-index: 2000;
        opacity: 0;
        visibility: hidden;
        transition: opacity 0.3s, visibility 0.3s;
      }

      .metro-map-modal.open {
        opacity: 1;
        visibility: visible;
      }

      .metro-map-modal-content {
        background-color: white;
        border-radius: 8px;
        box-shadow: 0 4px 20px rgba(0, 0, 0, 0.2);
        max-width: 90%;
        max-height: 90%;
        overflow: auto;
        transform: translateY(20px);
        transition: transform 0.3s;
      }

      .metro-map-modal.open .metro-map-modal-content {
        transform: translateY(0);
      }

      .metro-map-modal-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 15px 20px;
        border-bottom: 1px solid #eee;
      }

      .metro-map-modal-header h2 {
        margin: 0;
        font-size: 18px;
        font-weight: 600;
      }

      .metro-map-modal-close {
        background: none;
        border: none;
        font-size: 24px;
        cursor: pointer;
        color: #666;
      }

      .metro-map-modal-body {
        padding: 20px;
      }

      .metro-map-modal-info {
        display: grid;
        grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
        gap: 10px;
        margin-bottom: 20px;
      }

      .metro-map-modal-connections {
        margin-bottom: 20px;
      }

      .metro-map-modal-actions {
        display: flex;
        justify-content: flex-end;
        gap: 10px;
        margin-top: 20px;
      }

      .connections-list ul {
        list-style: none;
        padding: 0;
        margin: 0;
      }

      .connection {
        display: flex;
        align-items: center;
        padding: 8px;
        border-radius: 4px;
        margin-bottom: 5px;
        background-color: #f5f5f5;
      }

      .connection.outgoing {
        border-left: 4px solid #4CAF50;
      }

      .connection.incoming {
        border-left: 4px solid #2196F3;
      }

      .connection-direction {
        font-size: 12px;
        font-weight: 600;
        margin-right: 10px;
        color: #666;
      }

      .status {
        display: inline-block;
        padding: 2px 6px;
        border-radius: 10px;
        font-size: 12px;
        margin-left: 5px;
      }

      .status-completed {
        background-color: #E8F5E9;
        color: #2E7D32;
      }

      .status-in_progress {
        background-color: #E3F2FD;
        color: #1565C0;
      }

      .status-planned {
        background-color: #F5F5F5;
        color: #616161;
      }

      /* Styles pour les boutons */
      .metro-map-btn {
        padding: 8px 16px;
        border-radius: 4px;
        border: 1px solid #ddd;
        background-color: #f5f5f5;
        cursor: pointer;
        font-size: 14px;
        transition: background-color 0.2s;
      }

      .metro-map-btn:hover {
        background-color: #e0e0e0;
      }

      .metro-map-btn-primary {
        background-color: #2196F3;
        color: white;
        border-color: #1976D2;
      }

      .metro-map-btn-primary:hover {
        background-color: #1976D2;
      }

      /* Styles pour les contrôles */
      .metro-map-controls {
        position: absolute;
        z-index: 10;
        display: flex;
        flex-direction: column;
        gap: 10px;
        padding: 10px;
      }

      .metro-map-controls.position-top-right {
        top: 10px;
        right: 10px;
      }

      .metro-map-controls.position-top-left {
        top: 10px;
        left: 10px;
      }

      .metro-map-controls.position-bottom-right {
        bottom: 10px;
        right: 10px;
      }

      .metro-map-controls.position-bottom-left {
        bottom: 10px;
        left: 10px;
      }

      .metro-map-control-group {
        display: flex;
        flex-direction: column;
        gap: 5px;
        background-color: white;
        border-radius: 4px;
        box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
      }

      .metro-map-control-btn {
        width: 36px;
        height: 36px;
        border: none;
        background-color: white;
        border-radius: 4px;
        cursor: pointer;
        display: flex;
        justify-content: center;
        align-items: center;
        transition: background-color 0.2s;
      }

      .metro-map-control-btn:hover {
        background-color: #f5f5f5;
      }

      .metro-map-control-btn svg {
        width: 20px;
        height: 20px;
        fill: #666;
      }

      /* Styles pour la légende */
      .metro-map-legend {
        position: absolute;
        bottom: 10px;
        left: 10px;
        z-index: 10;
        background-color: white;
        border-radius: 4px;
        box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
        width: 250px;
        max-height: 300px;
        overflow: hidden;
      }

      .metro-map-legend-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 10px 15px;
        border-bottom: 1px solid #eee;
      }

      .metro-map-legend-header h3 {
        margin: 0;
        font-size: 16px;
        font-weight: 600;
      }

      .metro-map-legend-toggle {
        background: none;
        border: none;
        cursor: pointer;
        font-size: 14px;
      }

      .metro-map-legend-content {
        padding: 10px 15px;
        max-height: 250px;
        overflow-y: auto;
        transition: max-height 0.3s;
      }

      .metro-map-legend-content.collapsed {
        max-height: 0;
        padding: 0 15px;
        overflow: hidden;
      }

      .metro-map-legend-section {
        margin-bottom: 15px;
      }

      .metro-map-legend-section h4 {
        margin: 0 0 10px 0;
        font-size: 14px;
        font-weight: 600;
      }

      .metro-map-legend-items {
        list-style: none;
        padding: 0;
        margin: 0;
      }

      .metro-map-legend-item {
        display: flex;
        align-items: center;
        margin-bottom: 5px;
      }

      .legend-color {
        width: 16px;
        height: 16px;
        border-radius: 3px;
        margin-right: 10px;
      }

      .legend-icon {
        width: 16px;
        height: 16px;
        margin-right: 10px;
        text-align: center;
      }

      .legend-label {
        font-size: 14px;
      }

      /* Styles pour les options d'exportation */
      .metro-map-export-options {
        display: flex;
        flex-direction: column;
        gap: 15px;
      }

      .export-option h3 {
        margin: 0 0 10px 0;
        font-size: 16px;
        font-weight: 600;
      }

      .export-option-items {
        display: flex;
        flex-direction: column;
        gap: 8px;
      }

      .export-option-items label {
        display: flex;
        align-items: center;
        gap: 8px;
        cursor: pointer;
      }

      /* Styles pour les éléments Cytoscape */
      .highlighted {
        transition: all 0.3s ease;
      }
    `;

    // Ajouter l'élément de style au document
    document.head.appendChild(style);
  }

  /**
   * Configure les interactions avec la visualisation
   * @private
   */
  _setupInteractions() {
    // Fonction de gestion des erreurs pour les gestionnaires d'événements
    const safeEventHandler = (handler) => {
      return (event) => {
        try {
          handler(event);
        } catch (error) {
          console.error('Erreur lors de la gestion d\'un événement:', error);
        }
      };
    };

    // Interaction au clic sur un nœud
    this.cy.on('tap', 'node', safeEventHandler((event) => {
      const node = event.target;
      this._handleNodeClick(node);
    }));

    // Interaction au survol d'un nœud
    this.cy.on('mouseover', 'node', safeEventHandler((event) => {
      const node = event.target;
      this._handleNodeMouseOver(node);
    }));

    // Interaction à la sortie d'un nœud
    this.cy.on('mouseout', 'node', safeEventHandler((event) => {
      const node = event.target;
      this._handleNodeMouseOut(node);
    }));

    // Interaction au double-clic sur un nœud
    this.cy.on('dblclick', 'node', safeEventHandler((event) => {
      const node = event.target;
      this._handleNodeDoubleClick(node);
    }));

    // Interaction au clic sur une arête
    this.cy.on('tap', 'edge', safeEventHandler((event) => {
      const edge = event.target;
      this._handleEdgeClick(edge);
    }));

    // Interaction au survol d'une arête
    this.cy.on('mouseover', 'edge', safeEventHandler((event) => {
      const edge = event.target;
      this._handleEdgeMouseOver(edge);
    }));

    // Interaction à la sortie d'une arête
    this.cy.on('mouseout', 'edge', safeEventHandler((event) => {
      const edge = event.target;
      this._handleEdgeMouseOut(edge);
    }));

    // Interaction au zoom
    this.cy.on('zoom', safeEventHandler((event) => {
      this._handleZoom(event.cy.zoom());
    }));

    // Interaction au pan
    this.cy.on('pan', safeEventHandler(() => {
      this._updateTooltipPositions();
    }));

    // Interaction au clic sur le fond
    this.cy.on('tap', safeEventHandler((event) => {
      if (event.target === this.cy) {
        this._handleBackgroundClick();
      }
    }));

    // Interaction au double-clic sur le fond
    this.cy.on('dblclick', safeEventHandler((event) => {
      if (event.target === this.cy) {
        this._handleBackgroundDoubleClick();
      }
    }));

    // Interaction au clic droit
    this.cy.on('cxttap', safeEventHandler((event) => {
      this._handleContextMenu(event);
    }));
  }

  /**
   * Gère le clic sur un nœud
   * @param {Object} node - Nœud Cytoscape
   * @private
   */
  _handleNodeClick(node) {
    // Sélectionner/désélectionner le nœud
    if (this.state.selectedNodes.has(node.id())) {
      this.state.selectedNodes.delete(node.id());
      node.removeClass('selected');
    } else {
      this.state.selectedNodes.add(node.id());
      node.addClass('selected');
    }

    // Animer le nœud
    node.animation({
      style: {
        'border-width': 5,
        'border-color': '#FFC107'
      },
      duration: this.options.animation.nodeSelectionDuration
    }).play().promise('complete').then(() => {
      // Réinitialiser le style après l'animation si le nœud n'est plus sélectionné
      if (!this.state.selectedNodes.has(node.id())) {
        node.animation({
          style: {
            'border-width': 2,
            'border-color': node.style('background-color')
          },
          duration: this.options.animation.nodeSelectionDuration
        }).play();
      }
    });

    // Mettre en évidence les nœuds connectés
    const connectedNodes = node.connectedNodes();
    connectedNodes.forEach(connectedNode => {
      connectedNode.animation({
        style: {
          'border-width': 3,
          'border-color': '#4CAF50'
        },
        duration: this.options.animation.highlightDuration
      }).play();
    });

    // Mettre en évidence les arêtes connectées
    const connectedEdges = node.connectedEdges();
    connectedEdges.forEach(edge => {
      edge.animation({
        style: {
          'width': 7,
          'line-color': '#4CAF50'
        },
        duration: this.options.animation.highlightDuration
      }).play();
    });

    // Déclencher l'événement de sélection de nœud
    this._triggerEvent('nodeSelect', { node });
  }

  /**
   * Gère le survol d'un nœud
   * @param {Object} node - Nœud Cytoscape
   * @private
   */
  _handleNodeMouseOver(node) {
    // Mettre à jour l'état
    this.state.hoveredNode = node;

    // Mettre en évidence le nœud
    node.animation({
      style: {
        'border-width': 4,
        'border-opacity': 1
      },
      duration: this.options.animation.highlightDuration
    }).play();

    // Afficher le tooltip
    this._showNodeTooltip(node);

    // Déclencher l'événement de survol de nœud
    this._triggerEvent('nodeHover', { node });
  }

  /**
   * Gère la sortie d'un nœud
   * @param {Object} node - Nœud Cytoscape
   * @private
   */
  _handleNodeMouseOut(node) {
    // Mettre à jour l'état
    this.state.hoveredNode = null;

    // Réinitialiser le style du nœud s'il n'est pas sélectionné
    if (!this.state.selectedNodes.has(node.id())) {
      node.animation({
        style: {
          'border-width': 2,
          'border-opacity': 0.8
        },
        duration: this.options.animation.highlightDuration
      }).play();
    }

    // Masquer le tooltip
    this._hideNodeTooltip(node);

    // Déclencher l'événement de sortie de nœud
    this._triggerEvent('nodeUnhover', { node });
  }

  /**
   * Gère le double-clic sur un nœud
   * @param {Object} node - Nœud Cytoscape
   * @private
   */
  _handleNodeDoubleClick(node) {
    // Zoomer sur le nœud
    this.cy.animate({
      zoom: 2,
      center: {
        eles: node
      },
      duration: this.options.animation.zoomDuration,
      easing: 'ease-in-out-cubic'
    });

    // Afficher les détails du nœud
    this._showNodeDetails(node);

    // Déclencher l'événement de double-clic sur un nœud
    this._triggerEvent('nodeDoubleClick', { node });
  }

  /**
   * Gère le clic sur une arête
   * @param {Object} edge - Arête Cytoscape
   * @private
   */
  _handleEdgeClick(edge) {
    // Mettre en évidence l'arête
    edge.animation({
      style: {
        'width': 7,
        'line-color': '#2196F3'
      },
      duration: this.options.animation.highlightDuration
    }).play().promise('complete').then(() => {
      // Réinitialiser le style après l'animation
      edge.animation({
        style: {
          'width': 5,
          'line-color': edge.data('originalColor') || '#666'
        },
        duration: this.options.animation.highlightDuration
      }).play();
    });

    // Mettre en évidence les nœuds connectés
    const connectedNodes = edge.connectedNodes();
    connectedNodes.forEach(node => {
      node.animation({
        style: {
          'border-width': 4,
          'border-color': '#2196F3'
        },
        duration: this.options.animation.highlightDuration
      }).play();
    });

    // Déclencher l'événement de clic sur une arête
    this._triggerEvent('edgeClick', { edge });
  }

  /**
   * Gère le survol d'une arête
   * @param {Object} edge - Arête Cytoscape
   * @private
   */
  _handleEdgeMouseOver(edge) {
    // Mettre en évidence l'arête
    edge.animation({
      style: {
        'width': 6,
        'opacity': 1
      },
      duration: this.options.animation.highlightDuration
    }).play();

    // Afficher le tooltip
    this._showEdgeTooltip(edge);

    // Déclencher l'événement de survol d'arête
    this._triggerEvent('edgeHover', { edge });
  }

  /**
   * Gère la sortie d'une arête
   * @param {Object} edge - Arête Cytoscape
   * @private
   */
  _handleEdgeMouseOut(edge) {
    // Réinitialiser le style de l'arête
    edge.animation({
      style: {
        'width': 5,
        'opacity': 0.8
      },
      duration: this.options.animation.highlightDuration
    }).play();

    // Masquer le tooltip
    this._hideEdgeTooltip(edge);

    // Déclencher l'événement de sortie d'arête
    this._triggerEvent('edgeUnhover', { edge });
  }

  /**
   * Gère le zoom
   * @param {number} zoomLevel - Niveau de zoom actuel
   * @private
   */
  _handleZoom(zoomLevel) {
    // Mettre à jour les tooltips
    this._updateTooltipPositions();

    // Appliquer le zoom sémantique si activé
    if (this.options.semanticZoom && this.options.semanticZoom.enabled) {
      this._applySemanticZoom(zoomLevel);
    }

    // Déclencher l'événement de zoom
    this._triggerEvent('zoom', { level: zoomLevel });
  }

  /**
   * Gère le clic sur le fond
   * @private
   */
  _handleBackgroundClick() {
    // Désélectionner tous les nœuds
    this.state.selectedNodes.forEach(nodeId => {
      const node = this.cy.getElementById(nodeId);
      node.removeClass('selected');
    });
    this.state.selectedNodes.clear();

    // Déclencher l'événement de clic sur le fond
    this._triggerEvent('backgroundClick');
  }

  /**
   * Gère le double-clic sur le fond
   * @private
   */
  _handleBackgroundDoubleClick() {
    // Réinitialiser la vue
    this.cy.animate({
      fit: {
        eles: this.cy.elements(),
        padding: 50
      },
      duration: this.options.animation.zoomDuration,
      easing: 'ease-in-out-cubic'
    });

    // Déclencher l'événement de double-clic sur le fond
    this._triggerEvent('backgroundDoubleClick');
  }

  /**
   * Gère le menu contextuel
   * @param {Object} event - Événement Cytoscape
   * @private
   */
  _handleContextMenu(event) {
    // Empêcher le menu contextuel par défaut
    event.originalEvent.preventDefault();

    // Afficher le menu contextuel personnalisé
    const target = event.target;
    const isNode = target.isNode && target.isNode();
    const isEdge = target.isEdge && target.isEdge();

    if (isNode) {
      this._showNodeContextMenu(target, event.originalEvent);
    } else if (isEdge) {
      this._showEdgeContextMenu(target, event.originalEvent);
    } else {
      this._showBackgroundContextMenu(event.originalEvent);
    }

    // Déclencher l'événement de menu contextuel
    this._triggerEvent('contextMenu', { target, event: event.originalEvent });
  }

  /**
   * Affiche un tooltip pour un nœud
   * @param {Object} node - Nœud Cytoscape
   * @private
   */
  _showNodeTooltip(node) {
    // Vérifier si un tooltip existe déjà pour ce nœud
    if (this.state.tooltips.has(node.id())) {
      return;
    }

    // Créer le tooltip
    const tooltip = document.createElement('div');
    tooltip.className = this.options.tooltip.className;

    // Récupérer les données du nœud
    const nodeData = node.data();

    // Construire le contenu du tooltip
    tooltip.innerHTML = `
      <div class="tooltip-header">
        <strong>${nodeData.label || nodeData.id}</strong>
      </div>
      <div class="tooltip-body">
        ${nodeData.description ? `<p>${nodeData.description}</p>` : ''}
        <p><strong>Status:</strong> ${nodeData.status || 'N/A'}</p>
        ${nodeData.roadmapId ? `<p><strong>Roadmap:</strong> ${nodeData.roadmapId}</p>` : ''}
      </div>
    `;

    // Ajouter le tooltip au document
    document.body.appendChild(tooltip);

    // Positionner le tooltip
    this._positionTooltip(tooltip, node);

    // Stocker le tooltip dans l'état
    this.state.tooltips.set(node.id(), tooltip);

    // Ajouter un délai avant d'afficher le tooltip
    setTimeout(() => {
      if (this.state.tooltips.has(node.id())) {
        tooltip.classList.add('visible');
      }
    }, this.options.tooltip.showDelay);
  }

  /**
   * Masque le tooltip d'un nœud
   * @param {Object} node - Nœud Cytoscape
   * @private
   */
  _hideNodeTooltip(node) {
    // Vérifier si un tooltip existe pour ce nœud
    if (!this.state.tooltips.has(node.id())) {
      return;
    }

    // Récupérer le tooltip
    const tooltip = this.state.tooltips.get(node.id());

    // Masquer le tooltip
    tooltip.classList.remove('visible');

    // Supprimer le tooltip après un délai
    setTimeout(() => {
      if (document.body.contains(tooltip)) {
        document.body.removeChild(tooltip);
      }
      this.state.tooltips.delete(node.id());
    }, this.options.tooltip.hideDelay);
  }

  /**
   * Affiche un tooltip pour une arête
   * @param {Object} edge - Arête Cytoscape
   * @private
   */
  _showEdgeTooltip(edge) {
    // Vérifier si un tooltip existe déjà pour cette arête
    if (this.state.tooltips.has(edge.id())) {
      return;
    }

    // Créer le tooltip
    const tooltip = document.createElement('div');
    tooltip.className = this.options.tooltip.className;

    // Récupérer les données de l'arête
    const edgeData = edge.data();
    const sourceNode = this.cy.getElementById(edgeData.source);
    const targetNode = this.cy.getElementById(edgeData.target);

    // Construire le contenu du tooltip
    tooltip.innerHTML = `
      <div class="tooltip-header">
        <strong>Connexion</strong>
      </div>
      <div class="tooltip-body">
        <p><strong>De:</strong> ${sourceNode.data('label') || edgeData.source}</p>
        <p><strong>À:</strong> ${targetNode.data('label') || edgeData.target}</p>
        ${edgeData.roadmapId ? `<p><strong>Roadmap:</strong> ${edgeData.roadmapId}</p>` : ''}
      </div>
    `;

    // Ajouter le tooltip au document
    document.body.appendChild(tooltip);

    // Positionner le tooltip
    this._positionTooltip(tooltip, edge);

    // Stocker le tooltip dans l'état
    this.state.tooltips.set(edge.id(), tooltip);

    // Ajouter un délai avant d'afficher le tooltip
    setTimeout(() => {
      if (this.state.tooltips.has(edge.id())) {
        tooltip.classList.add('visible');
      }
    }, this.options.tooltip.showDelay);
  }

  /**
   * Masque le tooltip d'une arête
   * @param {Object} edge - Arête Cytoscape
   * @private
   */
  _hideEdgeTooltip(edge) {
    // Vérifier si un tooltip existe pour cette arête
    if (!this.state.tooltips.has(edge.id())) {
      return;
    }

    // Récupérer le tooltip
    const tooltip = this.state.tooltips.get(edge.id());

    // Masquer le tooltip
    tooltip.classList.remove('visible');

    // Supprimer le tooltip après un délai
    setTimeout(() => {
      if (document.body.contains(tooltip)) {
        document.body.removeChild(tooltip);
      }
      this.state.tooltips.delete(edge.id());
    }, this.options.tooltip.hideDelay);
  }

  /**
   * Positionne un tooltip par rapport à un élément Cytoscape
   * @param {HTMLElement} tooltip - Élément HTML du tooltip
   * @param {Object} element - Élément Cytoscape (nœud ou arête)
   * @private
   */
  _positionTooltip(tooltip, element) {
    // Obtenir la position de l'élément dans le viewport
    const renderedPosition = element.renderedPosition();
    const renderedBoundingBox = element.renderedBoundingBox();

    // Obtenir la position du conteneur Cytoscape
    const containerRect = this.cy.container().getBoundingClientRect();

    // Calculer la position absolue dans la page
    let x, y;

    if (element.isNode && element.isNode()) {
      // Positionner par rapport au nœud
      x = containerRect.left + renderedPosition.x;
      y = containerRect.top + renderedPosition.y;

      // Ajuster en fonction de la position du tooltip
      switch (this.options.tooltip.position) {
        case 'top':
          y -= renderedBoundingBox.h / 2 + this.options.tooltip.offsetY;
          break;
        case 'bottom':
          y += renderedBoundingBox.h / 2 + this.options.tooltip.offsetY;
          break;
        case 'left':
          x -= renderedBoundingBox.w / 2 + this.options.tooltip.offsetX;
          break;
        case 'right':
          x += renderedBoundingBox.w / 2 + this.options.tooltip.offsetX;
          break;
      }
    } else {
      // Positionner par rapport à l'arête (au milieu)
      const sourcePos = element.source().renderedPosition();
      const targetPos = element.target().renderedPosition();

      x = containerRect.left + (sourcePos.x + targetPos.x) / 2;
      y = containerRect.top + (sourcePos.y + targetPos.y) / 2;

      // Ajouter un décalage
      y += this.options.tooltip.offsetY;
    }

    // Appliquer la position
    tooltip.style.left = `${x}px`;
    tooltip.style.top = `${y}px`;
  }

  /**
   * Met à jour la position de tous les tooltips actifs
   * @private
   */
  _updateTooltipPositions() {
    this.state.tooltips.forEach((tooltip, elementId) => {
      const element = this.cy.getElementById(elementId);
      if (element.length > 0) {
        this._positionTooltip(tooltip, element);
      }
    });
  }

  /**
   * Affiche une modale avec les détails d'un nœud
   * @param {Object} node - Nœud Cytoscape
   * @private
   */
  _showNodeDetails(node) {
    // Récupérer les données du nœud
    const nodeData = node.data();

    // Créer la modale
    const modal = document.createElement('div');
    modal.className = this.options.modal.className;

    // Construire le contenu de la modale
    modal.innerHTML = `
      <div class="metro-map-modal-content" style="width: ${this.options.modal.width}">
        <div class="metro-map-modal-header">
          <h2>${nodeData.label || nodeData.id}</h2>
          <button class="metro-map-modal-close">&times;</button>
        </div>
        <div class="metro-map-modal-body">
          ${nodeData.description ? `<p class="description">${nodeData.description}</p>` : ''}

          <div class="metro-map-modal-info">
            <div class="info-item">
              <strong>ID:</strong> ${nodeData.id}
            </div>
            <div class="info-item">
              <strong>Status:</strong> ${nodeData.status || 'N/A'}
            </div>
            ${nodeData.roadmapId ? `
              <div class="info-item">
                <strong>Roadmap:</strong> ${nodeData.roadmapId}
              </div>
            ` : ''}
          </div>

          <div class="metro-map-modal-connections">
            <h3>Connexions</h3>
            <div class="connections-list">
              ${this._getNodeConnectionsHTML(node)}
            </div>
          </div>

          <div class="metro-map-modal-actions">
            <button class="metro-map-btn metro-map-btn-primary" data-action="center">Centrer sur ce nœud</button>
            <button class="metro-map-btn" data-action="select-connections">Sélectionner les connexions</button>
            <button class="metro-map-btn" data-action="highlight">Mettre en évidence</button>
          </div>
        </div>
      </div>
    `;

    // Ajouter la modale au document
    document.body.appendChild(modal);

    // Mettre à jour l'état
    this.state.isModalOpen = true;

    // Ajouter les gestionnaires d'événements
    const closeBtn = modal.querySelector('.metro-map-modal-close');
    closeBtn.addEventListener('click', () => {
      this._closeModal(modal);
    });

    // Gestionnaire pour la touche Escape
    if (this.options.modal.closeOnEscape) {
      const escHandler = (event) => {
        if (event.key === 'Escape') {
          this._closeModal(modal);
          document.removeEventListener('keydown', escHandler);
        }
      };
      document.addEventListener('keydown', escHandler);
    }

    // Gestionnaire pour le clic en dehors de la modale
    if (this.options.modal.closeOnClickOutside) {
      modal.addEventListener('click', (event) => {
        if (event.target === modal) {
          this._closeModal(modal);
        }
      });
    }

    // Gestionnaires pour les boutons d'action
    const centerBtn = modal.querySelector('[data-action="center"]');
    centerBtn.addEventListener('click', () => {
      this.cy.animate({
        center: {
          eles: node
        },
        zoom: 2,
        duration: this.options.animation.zoomDuration
      });
    });

    const selectConnectionsBtn = modal.querySelector('[data-action="select-connections"]');
    selectConnectionsBtn.addEventListener('click', () => {
      const connectedNodes = node.connectedNodes();
      connectedNodes.forEach(connectedNode => {
        this.state.selectedNodes.add(connectedNode.id());
        connectedNode.addClass('selected');
      });
      this._closeModal(modal);
    });

    const highlightBtn = modal.querySelector('[data-action="highlight"]');
    highlightBtn.addEventListener('click', () => {
      // Mettre en évidence le nœud et ses connexions
      node.addClass('highlighted');
      const connectedEdges = node.connectedEdges();
      connectedEdges.addClass('highlighted');

      // Animer le nœud
      node.animation({
        style: {
          'background-color': '#FFC107',
          'border-color': '#FF9800',
          'border-width': 5
        },
        duration: this.options.animation.highlightDuration * 2
      }).play();

      this._closeModal(modal);
    });

    // Animer l'ouverture de la modale
    setTimeout(() => {
      modal.classList.add('open');
    }, 10);

    // Déclencher l'événement d'ouverture de modale
    this._triggerEvent('modalOpen', { node, modal });
  }

  /**
   * Ferme une modale
   * @param {HTMLElement} modal - Élément HTML de la modale
   * @private
   */
  _closeModal(modal) {
    // Animer la fermeture
    modal.classList.remove('open');

    // Supprimer la modale après l'animation
    setTimeout(() => {
      if (document.body.contains(modal)) {
        document.body.removeChild(modal);
      }
      this.state.isModalOpen = false;

      // Déclencher l'événement de fermeture de modale
      this._triggerEvent('modalClose');
    }, 300);
  }

  /**
   * Génère le HTML pour les connexions d'un nœud
   * @param {Object} node - Nœud Cytoscape
   * @returns {string} - HTML des connexions
   * @private
   */
  _getNodeConnectionsHTML(node) {
    const connectedEdges = node.connectedEdges();

    if (connectedEdges.length === 0) {
      return '<p>Aucune connexion</p>';
    }

    let html = '<ul class="connections">';

    connectedEdges.forEach(edge => {
      const sourceId = edge.source().id();
      const targetId = edge.target().id();
      const isOutgoing = sourceId === node.id();

      const connectedNodeId = isOutgoing ? targetId : sourceId;
      const connectedNode = this.cy.getElementById(connectedNodeId);
      const connectedNodeData = connectedNode.data();

      html += `
        <li class="connection ${isOutgoing ? 'outgoing' : 'incoming'}">
          <div class="connection-direction">${isOutgoing ? 'Vers' : 'Depuis'}</div>
          <div class="connection-node">
            <strong>${connectedNodeData.label || connectedNodeId}</strong>
            ${connectedNodeData.status ? `<span class="status status-${connectedNodeData.status}">${connectedNodeData.status}</span>` : ''}
          </div>
        </li>
      `;
    });

    html += '</ul>';
    return html;
  }

  /**
   * Configure le zoom sémantique
   * @private
   */
  _setupSemanticZoom() {
    // Vérifier que les niveaux de zoom sont définis
    if (!this.options.semanticZoom.levels || this.options.semanticZoom.levels.length === 0) {
      return;
    }

    // Configurer le gestionnaire de zoom
    this.cy.on('zoom', (event) => {
      const zoomLevel = event.cy.zoom();
      this._applySemanticZoom(zoomLevel);
    });

    // Appliquer le zoom sémantique initial
    this._applySemanticZoom(this.cy.zoom());
  }

  /**
   * Applique le zoom sémantique en fonction du niveau de zoom
   * @param {number} zoomLevel - Niveau de zoom actuel
   * @private
   */
  _applySemanticZoom(zoomLevel) {
    // Trouver le niveau de zoom sémantique correspondant
    let semanticLevel = null;

    if (zoomLevel < this.options.semanticZoom.thresholds[0]) {
      semanticLevel = this.options.semanticZoom.levels[0]; // Vue d'ensemble
    } else if (zoomLevel > this.options.semanticZoom.thresholds[1]) {
      semanticLevel = this.options.semanticZoom.levels[2]; // Vue détaillée
    } else {
      semanticLevel = this.options.semanticZoom.levels[1]; // Vue par défaut
    }

    // Si le niveau n'a pas changé, ne rien faire
    if (this.state.currentZoomLevel === semanticLevel.name) {
      return;
    }

    // Mettre à jour l'état
    this.state.currentZoomLevel = semanticLevel.name;

    // Appliquer les styles correspondants au niveau de zoom
    this.cy.style()
      .selector('node')
      .style({
        'width': semanticLevel.nodeSize,
        'height': semanticLevel.nodeSize,
        'font-size': semanticLevel.labelVisible ? 12 : 0,
        'text-opacity': semanticLevel.labelVisible ? 1 : 0
      })
      .selector('edge')
      .style({
        'width': semanticLevel.edgeWidth,
        'font-size': semanticLevel.labelVisible ? 10 : 0,
        'text-opacity': semanticLevel.labelVisible ? 1 : 0
      })
      .update();

    // Déclencher l'événement de changement de niveau de zoom sémantique
    this._triggerEvent('semanticZoomChange', { level: semanticLevel.name, zoomValue: zoomLevel });
  }

  /**
   * Déclenche un événement personnalisé
   * @param {string} eventName - Nom de l'événement
   * @param {Object} data - Données associées à l'événement
   * @private
   */
  _triggerEvent(eventName, data = {}) {
    // Créer un événement personnalisé
    const event = new CustomEvent(`metro-map:${eventName}`, {
      detail: {
        renderer: this,
        visualizer: this.visualizer,
        ...data
      },
      bubbles: true,
      cancelable: true
    });

    // Déclencher l'événement sur le conteneur Cytoscape
    this.cy.container().dispatchEvent(event);
  }
}

// Exporter la classe
export default MetroMapInteractiveRenderer;
