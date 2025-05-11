/**
 * hierarchical-diagram-tooltips.js
 * Module de gestion des infobulles détaillées pour les diagrammes hiérarchiques
 * Version: 1.0
 * Date: 2025-05-15
 */

/**
 * Classe TooltipManager
 * Gère les infobulles détaillées dans un diagramme hiérarchique
 */
class TooltipManager {
    /**
     * Constructeur
     * @param {Object} options - Options de configuration
     * @param {string} options.containerId - ID du conteneur SVG
     * @param {string} options.nodeSelector - Sélecteur CSS pour les nœuds
     * @param {number} options.showDelay - Délai avant affichage en ms
     * @param {number} options.hideDelay - Délai avant masquage en ms
     * @param {boolean} options.followCursor - Suivre le curseur
     */
    constructor(options = {}) {
        // Options par défaut
        this.options = Object.assign({
            containerId: 'hierarchy-container',
            nodeSelector: '.node',
            showDelay: 300,
            hideDelay: 200,
            followCursor: false,
            maxWidth: 300,
            position: 'auto', // 'auto', 'top', 'right', 'bottom', 'left'
            offset: 10,
            showOnClick: false,
            pinnable: true,
            showArrow: true,
            theme: 'light', // 'light', 'dark', 'auto'
            zIndex: 1000,
            customClass: '',
            customTemplate: null,
            interactive: true
        }, options);

        // État interne
        this.container = document.getElementById(this.options.containerId);
        this.tooltip = null;
        this.tooltipContent = null;
        this.tooltipArrow = null;
        this.activeNode = null;
        this.showTimer = null;
        this.hideTimer = null;
        this.isPinned = false;
        this.isVisible = false;
        this.lastMousePosition = { x: 0, y: 0 };
        this.tooltipSize = { width: 0, height: 0 };
        this.containerRect = null;

        // Initialisation
        this._initialize();
    }

    /**
     * Initialise le gestionnaire d'infobulles
     * @private
     */
    _initialize() {
        if (!this.container) {
            console.error(`Conteneur avec ID '${this.options.containerId}' non trouvé`);
            return;
        }

        // Créer l'infobulle
        this._createTooltip();

        // Ajouter les styles CSS
        this._addStyles();

        // Configurer les gestionnaires d'événements
        this._setupEventListeners();
    }

    /**
     * Crée l'élément d'infobulle
     * @private
     */
    _createTooltip() {
        // Créer l'élément d'infobulle
        this.tooltip = document.createElement('div');
        this.tooltip.className = `diagram-tooltip ${this.options.customClass}`;
        this.tooltip.style.display = 'none';
        this.tooltip.style.position = 'absolute';
        this.tooltip.style.zIndex = this.options.zIndex;
        this.tooltip.style.maxWidth = `${this.options.maxWidth}px`;
        
        // Appliquer le thème
        this.tooltip.setAttribute('data-theme', this.options.theme);
        
        // Créer le contenu
        this.tooltipContent = document.createElement('div');
        this.tooltipContent.className = 'diagram-tooltip-content';
        this.tooltip.appendChild(this.tooltipContent);
        
        // Créer la flèche si nécessaire
        if (this.options.showArrow) {
            this.tooltipArrow = document.createElement('div');
            this.tooltipArrow.className = 'diagram-tooltip-arrow';
            this.tooltip.appendChild(this.tooltipArrow);
        }
        
        // Ajouter le bouton d'épinglage si nécessaire
        if (this.options.pinnable) {
            const pinButton = document.createElement('button');
            pinButton.className = 'diagram-tooltip-pin';
            pinButton.innerHTML = '📌';
            pinButton.title = 'Épingler l\'infobulle';
            pinButton.addEventListener('click', (event) => {
                this._togglePin();
                event.stopPropagation();
            });
            this.tooltip.appendChild(pinButton);
        }
        
        // Ajouter au document
        document.body.appendChild(this.tooltip);
    }

    /**
     * Ajoute les styles CSS nécessaires
     * @private
     */
    _addStyles() {
        if (document.getElementById('tooltip-manager-styles')) {
            return;
        }

        const style = document.createElement('style');
        style.id = 'tooltip-manager-styles';
        style.textContent = `
            .diagram-tooltip {
                background-color: white;
                border-radius: 4px;
                box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
                padding: 10px;
                font-family: 'Roboto', 'Segoe UI', Helvetica, Arial, sans-serif;
                font-size: 14px;
                line-height: 1.5;
                color: #333;
                pointer-events: none;
                opacity: 0;
                transition: opacity 0.2s ease, transform 0.2s ease;
                transform: translateY(5px);
            }
            
            .diagram-tooltip.visible {
                opacity: 1;
                transform: translateY(0);
            }
            
            .diagram-tooltip.interactive {
                pointer-events: auto;
            }
            
            .diagram-tooltip.pinned {
                box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
                border: 2px solid #4A86E8;
            }
            
            .diagram-tooltip-content {
                max-height: 300px;
                overflow-y: auto;
            }
            
            .diagram-tooltip-arrow {
                position: absolute;
                width: 10px;
                height: 10px;
                background-color: white;
                transform: rotate(45deg);
            }
            
            .diagram-tooltip[data-position="top"] .diagram-tooltip-arrow {
                bottom: -5px;
                left: 50%;
                margin-left: -5px;
            }
            
            .diagram-tooltip[data-position="right"] .diagram-tooltip-arrow {
                left: -5px;
                top: 50%;
                margin-top: -5px;
            }
            
            .diagram-tooltip[data-position="bottom"] .diagram-tooltip-arrow {
                top: -5px;
                left: 50%;
                margin-left: -5px;
            }
            
            .diagram-tooltip[data-position="left"] .diagram-tooltip-arrow {
                right: -5px;
                top: 50%;
                margin-top: -5px;
            }
            
            .diagram-tooltip-pin {
                position: absolute;
                top: 5px;
                right: 5px;
                width: 20px;
                height: 20px;
                border: none;
                background: transparent;
                cursor: pointer;
                padding: 0;
                font-size: 14px;
                opacity: 0.5;
                transition: opacity 0.2s ease;
            }
            
            .diagram-tooltip-pin:hover {
                opacity: 1;
            }
            
            .diagram-tooltip.pinned .diagram-tooltip-pin {
                opacity: 1;
                color: #4A86E8;
            }
            
            .diagram-tooltip[data-theme="dark"] {
                background-color: #333;
                color: #fff;
            }
            
            .diagram-tooltip[data-theme="dark"] .diagram-tooltip-arrow {
                background-color: #333;
            }
            
            .diagram-tooltip-title {
                font-weight: bold;
                margin-bottom: 5px;
                padding-bottom: 5px;
                border-bottom: 1px solid #eee;
            }
            
            .diagram-tooltip-section {
                margin-bottom: 8px;
            }
            
            .diagram-tooltip-label {
                font-weight: 500;
                margin-right: 5px;
            }
            
            .diagram-tooltip-value {
                color: #666;
            }
            
            .diagram-tooltip-progress {
                height: 5px;
                background-color: #eee;
                border-radius: 3px;
                margin-top: 3px;
                overflow: hidden;
            }
            
            .diagram-tooltip-progress-bar {
                height: 100%;
                background-color: #4A86E8;
            }
            
            .diagram-tooltip-progress-bar.low {
                background-color: #E74C3C;
            }
            
            .diagram-tooltip-progress-bar.medium {
                background-color: #F5B041;
            }
            
            .diagram-tooltip-progress-bar.high {
                background-color: #2ECC71;
            }
            
            @media (prefers-color-scheme: dark) {
                .diagram-tooltip[data-theme="auto"] {
                    background-color: #333;
                    color: #fff;
                }
                
                .diagram-tooltip[data-theme="auto"] .diagram-tooltip-arrow {
                    background-color: #333;
                }
                
                .diagram-tooltip[data-theme="auto"] .diagram-tooltip-title {
                    border-bottom-color: #555;
                }
                
                .diagram-tooltip[data-theme="auto"] .diagram-tooltip-value {
                    color: #ccc;
                }
                
                .diagram-tooltip[data-theme="auto"] .diagram-tooltip-progress {
                    background-color: #555;
                }
            }
        `;
        document.head.appendChild(style);
    }

    /**
     * Configure les gestionnaires d'événements
     * @private
     */
    _setupEventListeners() {
        // Gestionnaire pour le survol des nœuds
        this.container.addEventListener('mouseover', (event) => {
            const node = event.target.closest(this.options.nodeSelector);
            if (node && !this.isPinned) {
                this._scheduleShow(node, event);
            }
        });

        // Gestionnaire pour la sortie des nœuds
        this.container.addEventListener('mouseout', (event) => {
            const node = event.target.closest(this.options.nodeSelector);
            if (node && !this.isPinned) {
                this._scheduleHide();
            }
        });

        // Gestionnaire pour le déplacement de la souris
        if (this.options.followCursor) {
            document.addEventListener('mousemove', (event) => {
                this.lastMousePosition = {
                    x: event.clientX,
                    y: event.clientY
                };
                
                if (this.isVisible && !this.isPinned) {
                    this._positionTooltip();
                }
            });
        }

        // Gestionnaire pour le clic sur les nœuds
        if (this.options.showOnClick) {
            this.container.addEventListener('click', (event) => {
                const node = event.target.closest(this.options.nodeSelector);
                if (node) {
                    if (this.activeNode === node && this.isVisible) {
                        if (this.options.pinnable) {
                            this._togglePin();
                        } else {
                            this.hide();
                        }
                    } else {
                        this.show(node, event);
                    }
                    
                    event.stopPropagation();
                }
            });
        }

        // Gestionnaire pour le clic en dehors de l'infobulle
        document.addEventListener('click', (event) => {
            if (this.isVisible && !this.tooltip.contains(event.target) && 
                (!this.activeNode || !this.activeNode.contains(event.target))) {
                if (this.isPinned) {
                    this._togglePin();
                }
                this.hide();
            }
        });

        // Gestionnaire pour le redimensionnement de la fenêtre
        window.addEventListener('resize', () => {
            if (this.isVisible) {
                this.containerRect = this.container.getBoundingClientRect();
                this._positionTooltip();
            }
        });

        // Gestionnaire pour le défilement
        window.addEventListener('scroll', () => {
            if (this.isVisible && !this.isPinned) {
                this.containerRect = this.container.getBoundingClientRect();
                this._positionTooltip();
            }
        });

        // Gestionnaire pour l'infobulle elle-même
        if (this.options.interactive) {
            this.tooltip.addEventListener('mouseenter', () => {
                if (this.hideTimer) {
                    clearTimeout(this.hideTimer);
                    this.hideTimer = null;
                }
                this.tooltip.classList.add('interactive');
            });
            
            this.tooltip.addEventListener('mouseleave', () => {
                if (!this.isPinned) {
                    this._scheduleHide();
                }
                this.tooltip.classList.remove('interactive');
            });
        }
    }

    /**
     * Planifie l'affichage de l'infobulle
     * @param {Element} node - Élément DOM du nœud
     * @param {Event} event - Événement déclencheur
     * @private
     */
    _scheduleShow(node, event) {
        // Annuler le masquage s'il est planifié
        if (this.hideTimer) {
            clearTimeout(this.hideTimer);
            this.hideTimer = null;
        }
        
        // Planifier l'affichage
        this.showTimer = setTimeout(() => {
            this.show(node, event);
        }, this.options.showDelay);
    }

    /**
     * Planifie le masquage de l'infobulle
     * @private
     */
    _scheduleHide() {
        // Annuler l'affichage s'il est planifié
        if (this.showTimer) {
            clearTimeout(this.showTimer);
            this.showTimer = null;
        }
        
        // Planifier le masquage
        this.hideTimer = setTimeout(() => {
            this.hide();
        }, this.options.hideDelay);
    }

    /**
     * Affiche l'infobulle pour un nœud
     * @param {Element} node - Élément DOM du nœud
     * @param {Event} event - Événement déclencheur (optionnel)
     */
    show(node, event = null) {
        // Mettre à jour le nœud actif
        this.activeNode = node;
        
        // Récupérer les données du nœud
        const nodeData = this._getNodeData(node);
        
        // Mettre à jour le contenu
        this._updateContent(nodeData);
        
        // Mettre à jour la position
        if (event) {
            this.lastMousePosition = {
                x: event.clientX,
                y: event.clientY
            };
        }
        
        this.containerRect = this.container.getBoundingClientRect();
        this._positionTooltip();
        
        // Afficher l'infobulle
        this.tooltip.style.display = 'block';
        
        // Forcer un reflow pour permettre les transitions
        this.tooltip.offsetHeight;
        
        // Ajouter la classe de visibilité
        this.tooltip.classList.add('visible');
        this.isVisible = true;
    }

    /**
     * Masque l'infobulle
     */
    hide() {
        if (!this.isVisible || this.isPinned) return;
        
        // Retirer la classe de visibilité
        this.tooltip.classList.remove('visible');
        this.isVisible = false;
        
        // Masquer après la transition
        setTimeout(() => {
            if (!this.isVisible) {
                this.tooltip.style.display = 'none';
            }
        }, 200);
        
        // Réinitialiser le nœud actif
        this.activeNode = null;
    }

    /**
     * Bascule l'état d'épinglage de l'infobulle
     * @private
     */
    _togglePin() {
        this.isPinned = !this.isPinned;
        
        if (this.isPinned) {
            this.tooltip.classList.add('pinned');
        } else {
            this.tooltip.classList.remove('pinned');
            
            // Masquer si le curseur n'est plus sur le nœud
            if (!this._isMouseOverNode()) {
                this._scheduleHide();
            }
        }
    }

    /**
     * Vérifie si le curseur est sur le nœud actif
     * @returns {boolean} - True si le curseur est sur le nœud
     * @private
     */
    _isMouseOverNode() {
        if (!this.activeNode) return false;
        
        const nodeRect = this.activeNode.getBoundingClientRect();
        
        return this.lastMousePosition.x >= nodeRect.left &&
               this.lastMousePosition.x <= nodeRect.right &&
               this.lastMousePosition.y >= nodeRect.top &&
               this.lastMousePosition.y <= nodeRect.bottom;
    }

    /**
     * Met à jour le contenu de l'infobulle
     * @param {Object} nodeData - Données du nœud
     * @private
     */
    _updateContent(nodeData) {
        if (!nodeData) {
            this.tooltipContent.innerHTML = '<div class="diagram-tooltip-title">Données non disponibles</div>';
            return;
        }
        
        // Utiliser le template personnalisé si fourni
        if (typeof this.options.customTemplate === 'function') {
            this.tooltipContent.innerHTML = this.options.customTemplate(nodeData);
            return;
        }
        
        // Template par défaut
        let html = `
            <div class="diagram-tooltip-title">${nodeData.id}: ${nodeData.title}</div>
            
            <div class="diagram-tooltip-section">
                <span class="diagram-tooltip-label">Statut:</span>
                <span class="diagram-tooltip-value">${nodeData.status}</span>
            </div>
            
            <div class="diagram-tooltip-section">
                <span class="diagram-tooltip-label">Priorité:</span>
                <span class="diagram-tooltip-value">${nodeData.priority}</span>
            </div>
            
            <div class="diagram-tooltip-section">
                <span class="diagram-tooltip-label">Progression:</span>
                <span class="diagram-tooltip-value">${nodeData.progress}%</span>
                <div class="diagram-tooltip-progress">
                    <div class="diagram-tooltip-progress-bar ${this._getProgressClass(nodeData.progress)}" 
                         style="width: ${nodeData.progress}%"></div>
                </div>
            </div>
        `;
        
        // Ajouter la description si disponible
        if (nodeData.description) {
            html += `
                <div class="diagram-tooltip-section">
                    <div class="diagram-tooltip-label">Description:</div>
                    <div class="diagram-tooltip-value">${nodeData.description}</div>
                </div>
            `;
        }
        
        // Ajouter les métadonnées si disponibles
        if (nodeData.metadata && Object.keys(nodeData.metadata).length > 0) {
            html += `<div class="diagram-tooltip-section">
                <div class="diagram-tooltip-label">Métadonnées:</div>
                <div class="diagram-tooltip-value">
                    <ul style="margin: 5px 0; padding-left: 20px;">
            `;
            
            for (const [key, value] of Object.entries(nodeData.metadata)) {
                html += `<li><strong>${key}:</strong> ${value}</li>`;
            }
            
            html += `
                    </ul>
                </div>
            </div>`;
        }
        
        this.tooltipContent.innerHTML = html;
    }

    /**
     * Détermine la classe CSS pour la barre de progression
     * @param {number} progress - Valeur de progression (0-100)
     * @returns {string} - Classe CSS
     * @private
     */
    _getProgressClass(progress) {
        if (progress < 30) return 'low';
        if (progress < 70) return 'medium';
        return 'high';
    }

    /**
     * Positionne l'infobulle
     * @private
     */
    _positionTooltip() {
        if (!this.isVisible) return;
        
        // Mesurer la taille de l'infobulle
        this.tooltipSize = {
            width: this.tooltip.offsetWidth,
            height: this.tooltip.offsetHeight
        };
        
        let position = this.options.position;
        let x, y;
        
        if (this.options.followCursor) {
            // Positionnement relatif au curseur
            x = this.lastMousePosition.x;
            y = this.lastMousePosition.y;
            
            // Déterminer la position automatiquement
            if (position === 'auto') {
                const viewportWidth = window.innerWidth;
                const viewportHeight = window.innerHeight;
                
                // Espace disponible dans chaque direction
                const spaceRight = viewportWidth - x;
                const spaceLeft = x;
                const spaceBottom = viewportHeight - y;
                const spaceTop = y;
                
                // Choisir la meilleure position
                if (spaceRight >= this.tooltipSize.width + this.options.offset) {
                    position = 'right';
                } else if (spaceLeft >= this.tooltipSize.width + this.options.offset) {
                    position = 'left';
                } else if (spaceBottom >= this.tooltipSize.height + this.options.offset) {
                    position = 'bottom';
                } else {
                    position = 'top';
                }
            }
            
            // Calculer les coordonnées selon la position
            switch (position) {
                case 'top':
                    x -= this.tooltipSize.width / 2;
                    y -= this.tooltipSize.height + this.options.offset;
                    break;
                case 'right':
                    x += this.options.offset;
                    y -= this.tooltipSize.height / 2;
                    break;
                case 'bottom':
                    x -= this.tooltipSize.width / 2;
                    y += this.options.offset;
                    break;
                case 'left':
                    x -= this.tooltipSize.width + this.options.offset;
                    y -= this.tooltipSize.height / 2;
                    break;
            }
        } else if (this.activeNode) {
            // Positionnement relatif au nœud
            const nodeRect = this.activeNode.getBoundingClientRect();
            
            // Déterminer la position automatiquement
            if (position === 'auto') {
                const viewportWidth = window.innerWidth;
                const viewportHeight = window.innerHeight;
                
                // Espace disponible dans chaque direction
                const spaceRight = viewportWidth - nodeRect.right;
                const spaceLeft = nodeRect.left;
                const spaceBottom = viewportHeight - nodeRect.bottom;
                const spaceTop = nodeRect.top;
                
                // Choisir la meilleure position
                if (spaceRight >= this.tooltipSize.width + this.options.offset) {
                    position = 'right';
                } else if (spaceLeft >= this.tooltipSize.width + this.options.offset) {
                    position = 'left';
                } else if (spaceBottom >= this.tooltipSize.height + this.options.offset) {
                    position = 'bottom';
                } else {
                    position = 'top';
                }
            }
            
            // Calculer les coordonnées selon la position
            switch (position) {
                case 'top':
                    x = nodeRect.left + (nodeRect.width / 2) - (this.tooltipSize.width / 2);
                    y = nodeRect.top - this.tooltipSize.height - this.options.offset;
                    break;
                case 'right':
                    x = nodeRect.right + this.options.offset;
                    y = nodeRect.top + (nodeRect.height / 2) - (this.tooltipSize.height / 2);
                    break;
                case 'bottom':
                    x = nodeRect.left + (nodeRect.width / 2) - (this.tooltipSize.width / 2);
                    y = nodeRect.bottom + this.options.offset;
                    break;
                case 'left':
                    x = nodeRect.left - this.tooltipSize.width - this.options.offset;
                    y = nodeRect.top + (nodeRect.height / 2) - (this.tooltipSize.height / 2);
                    break;
            }
        } else {
            return;
        }
        
        // Ajuster pour éviter les débordements
        const viewportWidth = window.innerWidth;
        const viewportHeight = window.innerHeight;
        
        x = Math.max(10, Math.min(viewportWidth - this.tooltipSize.width - 10, x));
        y = Math.max(10, Math.min(viewportHeight - this.tooltipSize.height - 10, y));
        
        // Appliquer la position
        this.tooltip.style.left = `${x}px`;
        this.tooltip.style.top = `${y}px`;
        
        // Mettre à jour l'attribut de position pour les styles CSS
        this.tooltip.setAttribute('data-position', position);
        
        // Positionner la flèche si nécessaire
        if (this.options.showArrow && this.tooltipArrow) {
            this._positionArrow(position);
        }
    }

    /**
     * Positionne la flèche de l'infobulle
     * @param {string} position - Position de l'infobulle
     * @private
     */
    _positionArrow(position) {
        // Réinitialiser les styles
        this.tooltipArrow.style.top = '';
        this.tooltipArrow.style.right = '';
        this.tooltipArrow.style.bottom = '';
        this.tooltipArrow.style.left = '';
        
        // Positionner selon la position de l'infobulle
        switch (position) {
            case 'top':
                this.tooltipArrow.style.bottom = '-5px';
                this.tooltipArrow.style.left = '50%';
                this.tooltipArrow.style.marginLeft = '-5px';
                break;
            case 'right':
                this.tooltipArrow.style.left = '-5px';
                this.tooltipArrow.style.top = '50%';
                this.tooltipArrow.style.marginTop = '-5px';
                break;
            case 'bottom':
                this.tooltipArrow.style.top = '-5px';
                this.tooltipArrow.style.left = '50%';
                this.tooltipArrow.style.marginLeft = '-5px';
                break;
            case 'left':
                this.tooltipArrow.style.right = '-5px';
                this.tooltipArrow.style.top = '50%';
                this.tooltipArrow.style.marginTop = '-5px';
                break;
        }
    }

    /**
     * Récupère les données associées à un nœud
     * @param {Element} node - Élément DOM du nœud
     * @returns {Object} - Données du nœud ou null
     * @private
     */
    _getNodeData(node) {
        // Essayer de récupérer les données via d3.js
        if (node.__data__) {
            return node.__data__.data;
        }
        
        // Essayer de récupérer via attribut data-*
        if (node.dataset.nodeId) {
            return {
                id: node.dataset.nodeId,
                title: node.dataset.nodeTitle || '',
                status: node.dataset.nodeStatus || '',
                priority: node.dataset.nodePriority || '',
                progress: parseInt(node.dataset.nodeProgress || '0', 10),
                description: node.dataset.nodeDescription || ''
            };
        }
        
        return null;
    }

    /**
     * Définit un template personnalisé pour les infobulles
     * @param {Function} templateFunction - Fonction qui prend les données du nœud et retourne du HTML
     */
    setCustomTemplate(templateFunction) {
        if (typeof templateFunction === 'function') {
            this.options.customTemplate = templateFunction;
        }
    }

    /**
     * Nettoie les ressources utilisées par le gestionnaire d'infobulles
     */
    dispose() {
        // Annuler les timers
        if (this.showTimer) {
            clearTimeout(this.showTimer);
            this.showTimer = null;
        }
        
        if (this.hideTimer) {
            clearTimeout(this.hideTimer);
            this.hideTimer = null;
        }
        
        // Supprimer l'infobulle
        if (this.tooltip && this.tooltip.parentNode) {
            this.tooltip.parentNode.removeChild(this.tooltip);
        }
        
        // Réinitialiser les variables
        this.tooltip = null;
        this.tooltipContent = null;
        this.tooltipArrow = null;
        this.activeNode = null;
        this.isVisible = false;
        this.isPinned = false;
    }
}

// Exporter la classe pour utilisation dans d'autres modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        TooltipManager
    };
}
