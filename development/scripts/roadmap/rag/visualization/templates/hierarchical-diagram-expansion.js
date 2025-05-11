/**
 * hierarchical-diagram-expansion.js
 * Module de gestion de l'expansion et réduction des branches pour les diagrammes hiérarchiques
 * Version: 1.0
 * Date: 2025-05-15
 */

/**
 * Classe ExpansionManager
 * Gère l'expansion et la réduction des branches dans un diagramme hiérarchique
 */
class ExpansionManager {
    /**
     * Constructeur
     * @param {Object} options - Options de configuration
     * @param {string} options.containerId - ID du conteneur SVG
     * @param {string} options.nodeSelector - Sélecteur CSS pour les nœuds
     * @param {Function} options.onExpansionChange - Callback appelé lors d'un changement d'expansion
     * @param {number} options.animationDuration - Durée des animations en ms
     * @param {boolean} options.rememberState - Mémoriser l'état d'expansion
     */
    constructor(options = {}) {
        // Options par défaut
        this.options = Object.assign({
            containerId: 'hierarchy-container',
            nodeSelector: '.node',
            onExpansionChange: null,
            animationDuration: 500,
            rememberState: true,
            defaultExpandLevel: 2,
            expandOnClick: true,
            expandOnDoubleClick: true,
            collapseEmptyNodes: false,
            expandIndicator: true
        }, options);

        // État interne
        this.container = document.getElementById(this.options.containerId);
        this.expandedNodes = new Set();
        this.collapsedNodes = new Set();
        this.nodeStates = new Map(); // Pour mémoriser l'état
        this.isInitialized = false;
        this.hierarchyData = null;
        this.d3Root = null;
        this.svgContainer = null;
        this.treeLayout = null;
        this.updateFunction = null;

        // Initialisation
        this._initialize();
    }

    /**
     * Initialise le gestionnaire d'expansion
     * @private
     */
    _initialize() {
        if (!this.container) {
            console.error(`Conteneur avec ID '${this.options.containerId}' non trouvé`);
            return;
        }

        // Ajouter les styles CSS
        this._addStyles();

        // Trouver le conteneur SVG
        this.svgContainer = this.container.querySelector('svg');
        if (!this.svgContainer) {
            console.warn('Conteneur SVG non trouvé, l\'initialisation sera retardée');
            return;
        }

        // Configurer les gestionnaires d'événements
        this._setupEventListeners();

        this.isInitialized = true;
    }

    /**
     * Ajoute les styles CSS nécessaires
     * @private
     */
    _addStyles() {
        if (document.getElementById('expansion-manager-styles')) {
            return;
        }

        const style = document.createElement('style');
        style.id = 'expansion-manager-styles';
        style.textContent = `
            .node.expandable {
                cursor: pointer;
            }
            
            .node.collapsed .expand-indicator {
                fill: #4A86E8;
                stroke: #2A66C8;
                stroke-width: 1px;
            }
            
            .node.expanded .expand-indicator {
                fill: #E74C3C;
                stroke: #C0392B;
                stroke-width: 1px;
            }
            
            .expand-indicator {
                cursor: pointer;
                transition: transform 0.3s ease;
            }
            
            .node.collapsed .expand-indicator {
                transform: rotate(0deg);
            }
            
            .node.expanded .expand-indicator {
                transform: rotate(90deg);
            }
            
            .node.leaf .expand-indicator {
                display: none;
            }
            
            @keyframes pulse {
                0% { transform: scale(1); opacity: 1; }
                50% { transform: scale(1.2); opacity: 0.8; }
                100% { transform: scale(1); opacity: 1; }
            }
            
            .node.expandable:hover .expand-indicator {
                animation: pulse 1s infinite;
            }
        `;
        document.head.appendChild(style);
    }

    /**
     * Configure les gestionnaires d'événements
     * @private
     */
    _setupEventListeners() {
        // Gestionnaire pour les clics sur les nœuds
        if (this.options.expandOnClick) {
            this.container.addEventListener('click', (event) => {
                // Vérifier si c'est un clic sur un indicateur d'expansion
                const indicator = event.target.closest('.expand-indicator');
                if (indicator) {
                    const node = indicator.closest(this.options.nodeSelector);
                    if (node) {
                        this._toggleNodeExpansion(node);
                        event.stopPropagation(); // Empêcher la propagation
                    }
                    return;
                }
                
                // Sinon, vérifier si c'est un clic sur un nœud
                const node = event.target.closest(this.options.nodeSelector);
                if (node && this._isExpandable(node)) {
                    // Ne pas traiter si l'expansion est gérée par double-clic
                    if (!this.options.expandOnDoubleClick) {
                        this._toggleNodeExpansion(node);
                    }
                }
            });
        }

        // Gestionnaire pour les double-clics sur les nœuds
        if (this.options.expandOnDoubleClick) {
            this.container.addEventListener('dblclick', (event) => {
                const node = event.target.closest(this.options.nodeSelector);
                if (node && this._isExpandable(node)) {
                    this._toggleNodeExpansion(node);
                    event.stopPropagation(); // Empêcher la propagation
                }
            });
        }

        // Gestionnaire pour les touches du clavier
        document.addEventListener('keydown', (event) => {
            // Touche + : Développer le(s) nœud(s) sélectionné(s)
            if (event.key === '+' || event.key === '=') {
                const selectedNodes = this.container.querySelectorAll(`${this.options.nodeSelector}.selected`);
                if (selectedNodes.length > 0) {
                    selectedNodes.forEach(node => {
                        if (this._isExpandable(node) && !this._isExpanded(node)) {
                            this._expandNode(node);
                        }
                    });
                    event.preventDefault();
                }
            }
            
            // Touche - : Réduire le(s) nœud(s) sélectionné(s)
            if (event.key === '-' || event.key === '_') {
                const selectedNodes = this.container.querySelectorAll(`${this.options.nodeSelector}.selected`);
                if (selectedNodes.length > 0) {
                    selectedNodes.forEach(node => {
                        if (this._isExpandable(node) && this._isExpanded(node)) {
                            this._collapseNode(node);
                        }
                    });
                    event.preventDefault();
                }
            }
            
            // Touche * : Développer tous les nœuds
            if (event.key === '*') {
                this.expandAll();
                event.preventDefault();
            }
            
            // Touche / : Réduire tous les nœuds
            if (event.key === '/') {
                this.collapseAll();
                event.preventDefault();
            }
        });
    }

    /**
     * Initialise les données hiérarchiques
     * @param {Object} hierarchyData - Données hiérarchiques
     * @param {Object} d3Root - Racine d3.hierarchy
     * @param {Function} updateFunction - Fonction de mise à jour du diagramme
     */
    initializeData(hierarchyData, d3Root, updateFunction) {
        this.hierarchyData = hierarchyData;
        this.d3Root = d3Root;
        this.updateFunction = updateFunction;
        
        // Ajouter les indicateurs d'expansion
        if (this.options.expandIndicator) {
            this._addExpandIndicators();
        }
        
        // Initialiser l'état d'expansion selon le niveau par défaut
        this._initializeExpansionState();
    }

    /**
     * Ajoute les indicateurs d'expansion aux nœuds
     * @private
     */
    _addExpandIndicators() {
        const nodes = this.container.querySelectorAll(this.options.nodeSelector);
        
        nodes.forEach(node => {
            // Vérifier si le nœud est expandable
            if (this._isExpandable(node)) {
                // Marquer comme expandable
                node.classList.add('expandable');
                
                // Ajouter l'indicateur s'il n'existe pas déjà
                if (!node.querySelector('.expand-indicator')) {
                    const nodeRect = node.querySelector('rect');
                    if (nodeRect) {
                        const rectWidth = parseFloat(nodeRect.getAttribute('width'));
                        const rectHeight = parseFloat(nodeRect.getAttribute('height'));
                        
                        // Créer l'indicateur
                        const indicator = document.createElementNS('http://www.w3.org/2000/svg', 'polygon');
                        indicator.setAttribute('class', 'expand-indicator');
                        indicator.setAttribute('points', '0,0 10,5 0,10');
                        indicator.setAttribute('transform', `translate(${rectWidth/2 + 10}, ${-rectHeight/2 + 15})`);
                        
                        // Ajouter au nœud
                        node.appendChild(indicator);
                    }
                }
                
                // Définir l'état initial
                if (this._isExpanded(node)) {
                    node.classList.add('expanded');
                    node.classList.remove('collapsed');
                } else {
                    node.classList.add('collapsed');
                    node.classList.remove('expanded');
                }
            } else {
                // Marquer comme feuille
                node.classList.add('leaf');
            }
        });
    }

    /**
     * Initialise l'état d'expansion selon le niveau par défaut
     * @private
     */
    _initializeExpansionState() {
        if (!this.d3Root) return;
        
        // Parcourir l'arbre et définir l'état initial
        this.d3Root.eachBefore(d => {
            // Développer jusqu'au niveau par défaut
            if (d.depth < this.options.defaultExpandLevel) {
                d.children = d._children || d.children;
                d._children = null;
                
                // Ajouter à l'ensemble des nœuds développés
                if (d.data.id) {
                    this.expandedNodes.add(d.data.id);
                }
            } else {
                // Réduire les niveaux supérieurs
                if (d.children) {
                    d._children = d.children;
                    d.children = null;
                    
                    // Ajouter à l'ensemble des nœuds réduits
                    if (d.data.id) {
                        this.collapsedNodes.add(d.data.id);
                    }
                }
            }
        });
        
        // Mettre à jour le diagramme
        if (typeof this.updateFunction === 'function') {
            this.updateFunction(this.d3Root);
        }
        
        // Mettre à jour les indicateurs visuels
        this._updateExpandIndicators();
    }

    /**
     * Met à jour les indicateurs d'expansion
     * @private
     */
    _updateExpandIndicators() {
        const nodes = this.container.querySelectorAll(this.options.nodeSelector);
        
        nodes.forEach(node => {
            // Récupérer l'ID du nœud
            const nodeId = this._getNodeId(node);
            if (!nodeId) return;
            
            // Mettre à jour les classes
            if (this.expandedNodes.has(nodeId)) {
                node.classList.add('expanded');
                node.classList.remove('collapsed');
            } else if (this.collapsedNodes.has(nodeId)) {
                node.classList.add('collapsed');
                node.classList.remove('expanded');
            }
        });
    }

    /**
     * Vérifie si un nœud est expandable (a des enfants)
     * @param {Element} node - Élément DOM du nœud
     * @returns {boolean} - True si le nœud est expandable
     * @private
     */
    _isExpandable(node) {
        // Vérifier via d3.js
        if (node.__data__) {
            return node.__data__._children || 
                  (node.__data__.children && node.__data__.children.length > 0);
        }
        
        // Vérifier via attributs data-*
        if (node.dataset.hasChildren === 'true') {
            return true;
        }
        
        return false;
    }

    /**
     * Vérifie si un nœud est actuellement développé
     * @param {Element} node - Élément DOM du nœud
     * @returns {boolean} - True si le nœud est développé
     * @private
     */
    _isExpanded(node) {
        // Récupérer l'ID du nœud
        const nodeId = this._getNodeId(node);
        if (!nodeId) return false;
        
        // Vérifier dans l'ensemble des nœuds développés
        return this.expandedNodes.has(nodeId);
    }

    /**
     * Récupère l'ID d'un nœud
     * @param {Element} node - Élément DOM du nœud
     * @returns {string} - ID du nœud ou null
     * @private
     */
    _getNodeId(node) {
        // Récupérer via d3.js
        if (node.__data__ && node.__data__.data && node.__data__.data.id) {
            return node.__data__.data.id;
        }
        
        // Récupérer via attributs data-*
        if (node.dataset.nodeId) {
            return node.dataset.nodeId;
        }
        
        return null;
    }

    /**
     * Bascule l'état d'expansion d'un nœud
     * @param {Element} node - Élément DOM du nœud
     * @private
     */
    _toggleNodeExpansion(node) {
        if (this._isExpanded(node)) {
            this._collapseNode(node);
        } else {
            this._expandNode(node);
        }
    }

    /**
     * Développe un nœud
     * @param {Element} node - Élément DOM du nœud
     * @private
     */
    _expandNode(node) {
        // Récupérer l'ID du nœud
        const nodeId = this._getNodeId(node);
        if (!nodeId) return;
        
        // Mettre à jour les ensembles
        this.expandedNodes.add(nodeId);
        this.collapsedNodes.delete(nodeId);
        
        // Mettre à jour l'état dans d3.js
        if (node.__data__) {
            if (node.__data__._children) {
                node.__data__.children = node.__data__._children;
                node.__data__._children = null;
            }
        }
        
        // Mettre à jour les classes
        node.classList.add('expanded');
        node.classList.remove('collapsed');
        
        // Mémoriser l'état si activé
        if (this.options.rememberState) {
            this.nodeStates.set(nodeId, 'expanded');
        }
        
        // Mettre à jour le diagramme
        if (typeof this.updateFunction === 'function') {
            this.updateFunction(node.__data__);
        }
        
        // Notifier le changement
        this._notifyExpansionChange(nodeId, true);
    }

    /**
     * Réduit un nœud
     * @param {Element} node - Élément DOM du nœud
     * @private
     */
    _collapseNode(node) {
        // Récupérer l'ID du nœud
        const nodeId = this._getNodeId(node);
        if (!nodeId) return;
        
        // Mettre à jour les ensembles
        this.expandedNodes.delete(nodeId);
        this.collapsedNodes.add(nodeId);
        
        // Mettre à jour l'état dans d3.js
        if (node.__data__) {
            if (node.__data__.children) {
                node.__data__._children = node.__data__.children;
                node.__data__.children = null;
            }
        }
        
        // Mettre à jour les classes
        node.classList.add('collapsed');
        node.classList.remove('expanded');
        
        // Mémoriser l'état si activé
        if (this.options.rememberState) {
            this.nodeStates.set(nodeId, 'collapsed');
        }
        
        // Mettre à jour le diagramme
        if (typeof this.updateFunction === 'function') {
            this.updateFunction(node.__data__);
        }
        
        // Notifier le changement
        this._notifyExpansionChange(nodeId, false);
    }

    /**
     * Développe tous les nœuds
     */
    expandAll() {
        if (!this.d3Root) return;
        
        // Parcourir l'arbre et développer tous les nœuds
        this.d3Root.eachBefore(d => {
            if (d._children) {
                d.children = d._children;
                d._children = null;
                
                // Ajouter à l'ensemble des nœuds développés
                if (d.data.id) {
                    this.expandedNodes.add(d.data.id);
                    this.collapsedNodes.delete(d.data.id);
                    
                    // Mémoriser l'état si activé
                    if (this.options.rememberState) {
                        this.nodeStates.set(d.data.id, 'expanded');
                    }
                }
            }
        });
        
        // Mettre à jour le diagramme
        if (typeof this.updateFunction === 'function') {
            this.updateFunction(this.d3Root);
        }
        
        // Mettre à jour les indicateurs visuels
        this._updateExpandIndicators();
        
        // Notifier le changement
        this._notifyExpansionChange('all', true);
    }

    /**
     * Réduit tous les nœuds
     * @param {number} keepLevel - Niveau à conserver développé (0 pour tout réduire)
     */
    collapseAll(keepLevel = 0) {
        if (!this.d3Root) return;
        
        // Parcourir l'arbre et réduire tous les nœuds
        this.d3Root.eachBefore(d => {
            if (d.depth >= keepLevel) {
                if (d.children) {
                    d._children = d.children;
                    d.children = null;
                    
                    // Ajouter à l'ensemble des nœuds réduits
                    if (d.data.id) {
                        this.expandedNodes.delete(d.data.id);
                        this.collapsedNodes.add(d.data.id);
                        
                        // Mémoriser l'état si activé
                        if (this.options.rememberState) {
                            this.nodeStates.set(d.data.id, 'collapsed');
                        }
                    }
                }
            }
        });
        
        // Mettre à jour le diagramme
        if (typeof this.updateFunction === 'function') {
            this.updateFunction(this.d3Root);
        }
        
        // Mettre à jour les indicateurs visuels
        this._updateExpandIndicators();
        
        // Notifier le changement
        this._notifyExpansionChange('all', false);
    }

    /**
     * Développe un nœud par son ID
     * @param {string} nodeId - ID du nœud
     * @returns {boolean} - True si le développement a réussi
     */
    expandNodeById(nodeId) {
        // Trouver le nœud dans le DOM
        const node = this.container.querySelector(`[data-node-id="${nodeId}"]`);
        if (node) {
            this._expandNode(node);
            return true;
        }
        
        // Si le nœud n'est pas dans le DOM, essayer via d3.js
        if (this.d3Root) {
            let found = false;
            
            this.d3Root.eachBefore(d => {
                if (d.data.id === nodeId && d._children) {
                    d.children = d._children;
                    d._children = null;
                    found = true;
                    
                    // Ajouter à l'ensemble des nœuds développés
                    this.expandedNodes.add(nodeId);
                    this.collapsedNodes.delete(nodeId);
                    
                    // Mémoriser l'état si activé
                    if (this.options.rememberState) {
                        this.nodeStates.set(nodeId, 'expanded');
                    }
                }
            });
            
            if (found) {
                // Mettre à jour le diagramme
                if (typeof this.updateFunction === 'function') {
                    this.updateFunction(this.d3Root);
                }
                
                // Notifier le changement
                this._notifyExpansionChange(nodeId, true);
                
                return true;
            }
        }
        
        return false;
    }

    /**
     * Réduit un nœud par son ID
     * @param {string} nodeId - ID du nœud
     * @returns {boolean} - True si la réduction a réussi
     */
    collapseNodeById(nodeId) {
        // Trouver le nœud dans le DOM
        const node = this.container.querySelector(`[data-node-id="${nodeId}"]`);
        if (node) {
            this._collapseNode(node);
            return true;
        }
        
        // Si le nœud n'est pas dans le DOM, essayer via d3.js
        if (this.d3Root) {
            let found = false;
            
            this.d3Root.eachBefore(d => {
                if (d.data.id === nodeId && d.children) {
                    d._children = d.children;
                    d.children = null;
                    found = true;
                    
                    // Ajouter à l'ensemble des nœuds réduits
                    this.expandedNodes.delete(nodeId);
                    this.collapsedNodes.add(nodeId);
                    
                    // Mémoriser l'état si activé
                    if (this.options.rememberState) {
                        this.nodeStates.set(nodeId, 'collapsed');
                    }
                }
            });
            
            if (found) {
                // Mettre à jour le diagramme
                if (typeof this.updateFunction === 'function') {
                    this.updateFunction(this.d3Root);
                }
                
                // Notifier le changement
                this._notifyExpansionChange(nodeId, false);
                
                return true;
            }
        }
        
        return false;
    }

    /**
     * Développe le chemin vers un nœud spécifique
     * @param {string} nodeId - ID du nœud cible
     * @returns {boolean} - True si le développement a réussi
     */
    expandPathToNode(nodeId) {
        if (!this.d3Root) return false;
        
        let targetNode = null;
        const pathNodes = [];
        
        // Trouver le nœud cible et collecter le chemin
        this.d3Root.eachBefore(d => {
            if (d.data.id === nodeId) {
                targetNode = d;
                
                // Collecter tous les ancêtres
                let current = d.parent;
                while (current) {
                    pathNodes.push(current);
                    current = current.parent;
                }
            }
        });
        
        if (!targetNode) return false;
        
        // Développer tous les nœuds du chemin
        let changed = false;
        
        pathNodes.forEach(d => {
            if (d._children) {
                d.children = d._children;
                d._children = null;
                changed = true;
                
                // Ajouter à l'ensemble des nœuds développés
                if (d.data.id) {
                    this.expandedNodes.add(d.data.id);
                    this.collapsedNodes.delete(d.data.id);
                    
                    // Mémoriser l'état si activé
                    if (this.options.rememberState) {
                        this.nodeStates.set(d.data.id, 'expanded');
                    }
                }
            }
        });
        
        if (changed) {
            // Mettre à jour le diagramme
            if (typeof this.updateFunction === 'function') {
                this.updateFunction(this.d3Root);
            }
            
            // Mettre à jour les indicateurs visuels
            this._updateExpandIndicators();
            
            // Notifier le changement
            this._notifyExpansionChange('path', true);
            
            return true;
        }
        
        return false;
    }

    /**
     * Restaure l'état d'expansion mémorisé
     * @returns {boolean} - True si la restauration a réussi
     */
    restoreExpansionState() {
        if (!this.options.rememberState || this.nodeStates.size === 0) {
            return false;
        }
        
        let changed = false;
        
        // Parcourir tous les états mémorisés
        this.nodeStates.forEach((state, nodeId) => {
            if (state === 'expanded') {
                changed = this.expandNodeById(nodeId) || changed;
            } else if (state === 'collapsed') {
                changed = this.collapseNodeById(nodeId) || changed;
            }
        });
        
        return changed;
    }

    /**
     * Notifie le changement d'expansion via le callback
     * @param {string} nodeId - ID du nœud concerné
     * @param {boolean} expanded - True si développé, false si réduit
     * @private
     */
    _notifyExpansionChange(nodeId, expanded) {
        if (typeof this.options.onExpansionChange === 'function') {
            this.options.onExpansionChange(nodeId, expanded, {
                expandedNodes: Array.from(this.expandedNodes),
                collapsedNodes: Array.from(this.collapsedNodes)
            });
        }
    }

    /**
     * Nettoie les ressources utilisées par le gestionnaire d'expansion
     */
    dispose() {
        // Réinitialiser les variables
        this.expandedNodes = new Set();
        this.collapsedNodes = new Set();
        this.nodeStates = new Map();
        this.isInitialized = false;
        this.hierarchyData = null;
        this.d3Root = null;
        this.updateFunction = null;
    }
}

// Exporter la classe pour utilisation dans d'autres modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        ExpansionManager
    };
}
