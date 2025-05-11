/**
 * hierarchical-diagram-selection.js
 * Module de gestion de la sélection pour les diagrammes hiérarchiques
 * Version: 1.0
 * Date: 2025-05-15
 */

/**
 * Classe SelectionManager
 * Gère la sélection des nœuds dans un diagramme hiérarchique
 */
class SelectionManager {
    /**
     * Constructeur
     * @param {Object} options - Options de configuration
     * @param {string} options.containerId - ID du conteneur SVG
     * @param {string} options.nodeSelector - Sélecteur CSS pour les nœuds
     * @param {Function} options.onSelectionChange - Callback appelé lors d'un changement de sélection
     * @param {boolean} options.multiSelect - Autoriser la sélection multiple
     * @param {string} options.selectedClass - Classe CSS pour les nœuds sélectionnés
     */
    constructor(options = {}) {
        // Options par défaut
        this.options = Object.assign({
            containerId: 'hierarchy-container',
            nodeSelector: '.node',
            onSelectionChange: null,
            multiSelect: false,
            selectedClass: 'selected',
            highlightRelatedNodes: true,
            selectionPersistence: true
        }, options);

        // État interne
        this.selectedNodes = new Set();
        this.lastSelectedNode = null;
        this.container = document.getElementById(this.options.containerId);
        this.selectionHistory = [];
        this.maxHistorySize = 10;
        this.isSelecting = false;
        this.selectionBox = null;
        this.startPoint = { x: 0, y: 0 };
        this.endPoint = { x: 0, y: 0 };

        // Initialisation
        this._initialize();
    }

    /**
     * Initialise le gestionnaire de sélection
     * @private
     */
    _initialize() {
        if (!this.container) {
            console.error(`Conteneur avec ID '${this.options.containerId}' non trouvé`);
            return;
        }

        // Ajouter les styles CSS
        this._addStyles();

        // Créer la boîte de sélection
        this._createSelectionBox();

        // Ajouter les gestionnaires d'événements
        this._setupEventListeners();
    }

    /**
     * Ajoute les styles CSS nécessaires
     * @private
     */
    _addStyles() {
        if (document.getElementById('selection-manager-styles')) {
            return;
        }

        const style = document.createElement('style');
        style.id = 'selection-manager-styles';
        style.textContent = `
            .${this.options.selectedClass} rect {
                stroke-width: 4px !important;
                filter: drop-shadow(0 0 3px rgba(0, 0, 0, 0.3));
            }
            
            .${this.options.selectedClass} text {
                font-weight: bold;
            }
            
            .related-node rect {
                stroke-dasharray: 5, 3;
                animation: dash 1s linear infinite;
            }
            
            @keyframes dash {
                to {
                    stroke-dashoffset: -8;
                }
            }
            
            .selection-box {
                position: absolute;
                border: 1px dashed #4A86E8;
                background-color: rgba(74, 134, 232, 0.1);
                pointer-events: none;
                z-index: 1000;
                display: none;
            }
            
            .node {
                cursor: pointer;
                transition: opacity 0.2s ease;
            }
            
            .node:hover rect {
                filter: brightness(1.05);
            }
            
            .node.dimmed {
                opacity: 0.4;
            }
        `;
        document.head.appendChild(style);
    }

    /**
     * Crée la boîte de sélection pour la sélection par zone
     * @private
     */
    _createSelectionBox() {
        this.selectionBox = document.createElement('div');
        this.selectionBox.className = 'selection-box';
        this.container.parentNode.appendChild(this.selectionBox);
    }

    /**
     * Configure les gestionnaires d'événements
     * @private
     */
    _setupEventListeners() {
        // Gestionnaire pour les clics sur les nœuds
        this.container.addEventListener('click', (event) => {
            // Ignorer si on est en train de faire une sélection par zone
            if (this.isSelecting) return;

            const node = event.target.closest(this.options.nodeSelector);
            if (!node) {
                // Clic en dehors d'un nœud, désélectionner tout si pas de touche Ctrl
                if (!event.ctrlKey && !event.metaKey) {
                    this.clearSelection();
                }
                return;
            }

            // Récupérer les données du nœud
            const nodeData = this._getNodeData(node);

            // Gérer la sélection
            if (event.ctrlKey || event.metaKey) {
                // Sélection multiple avec Ctrl/Cmd
                if (this.options.multiSelect) {
                    if (this.isSelected(node)) {
                        this.deselectNode(node);
                    } else {
                        this.selectNode(node, true);
                    }
                }
            } else if (event.shiftKey) {
                // Sélection de plage avec Shift
                if (this.options.multiSelect && this.lastSelectedNode) {
                    this._selectNodesBetween(this.lastSelectedNode, node);
                } else {
                    this.selectNode(node, false);
                }
            } else {
                // Sélection simple
                this.selectNode(node, false);
            }

            // Empêcher la propagation pour éviter de désélectionner
            event.stopPropagation();
        });

        // Gestionnaire pour la sélection par zone
        this.container.addEventListener('mousedown', (event) => {
            // Ignorer si c'est un clic sur un nœud
            if (event.target.closest(this.options.nodeSelector)) return;

            // Démarrer la sélection par zone
            this.isSelecting = true;
            
            // Calculer la position de départ relative au conteneur
            const containerRect = this.container.getBoundingClientRect();
            this.startPoint = {
                x: event.clientX - containerRect.left,
                y: event.clientY - containerRect.top
            };
            this.endPoint = { ...this.startPoint };
            
            // Afficher la boîte de sélection
            this._updateSelectionBox();
            this.selectionBox.style.display = 'block';
            
            // Empêcher la sélection de texte
            event.preventDefault();
        });

        // Gestionnaire pour le déplacement de la souris pendant la sélection
        document.addEventListener('mousemove', (event) => {
            if (!this.isSelecting) return;
            
            // Mettre à jour la position de fin
            const containerRect = this.container.getBoundingClientRect();
            this.endPoint = {
                x: event.clientX - containerRect.left,
                y: event.clientY - containerRect.top
            };
            
            // Mettre à jour la boîte de sélection
            this._updateSelectionBox();
        });

        // Gestionnaire pour la fin de la sélection par zone
        document.addEventListener('mouseup', (event) => {
            if (!this.isSelecting) return;
            
            // Terminer la sélection
            this.isSelecting = false;
            this.selectionBox.style.display = 'none';
            
            // Sélectionner les nœuds dans la zone
            if (Math.abs(this.startPoint.x - this.endPoint.x) > 5 && 
                Math.abs(this.startPoint.y - this.endPoint.y) > 5) {
                this._selectNodesInBox();
            }
        });

        // Gestionnaire pour les raccourcis clavier
        document.addEventListener('keydown', (event) => {
            // Ctrl+A : Sélectionner tout
            if ((event.ctrlKey || event.metaKey) && event.key === 'a') {
                if (this.options.multiSelect) {
                    this.selectAll();
                    event.preventDefault();
                }
            }
            
            // Échap : Désélectionner tout
            if (event.key === 'Escape') {
                this.clearSelection();
            }
        });
    }

    /**
     * Met à jour la position et la taille de la boîte de sélection
     * @private
     */
    _updateSelectionBox() {
        const left = Math.min(this.startPoint.x, this.endPoint.x);
        const top = Math.min(this.startPoint.y, this.endPoint.y);
        const width = Math.abs(this.startPoint.x - this.endPoint.x);
        const height = Math.abs(this.startPoint.y - this.endPoint.y);
        
        this.selectionBox.style.left = `${left}px`;
        this.selectionBox.style.top = `${top}px`;
        this.selectionBox.style.width = `${width}px`;
        this.selectionBox.style.height = `${height}px`;
    }

    /**
     * Sélectionne les nœuds contenus dans la boîte de sélection
     * @private
     */
    _selectNodesInBox() {
        const nodes = this.container.querySelectorAll(this.options.nodeSelector);
        const selectionRect = {
            left: Math.min(this.startPoint.x, this.endPoint.x),
            top: Math.min(this.startPoint.y, this.endPoint.y),
            right: Math.max(this.startPoint.x, this.endPoint.x),
            bottom: Math.max(this.startPoint.y, this.endPoint.y)
        };
        
        // Si pas de multi-sélection, désélectionner tout d'abord
        if (!this.options.multiSelect) {
            this.clearSelection();
        }
        
        // Vérifier chaque nœud
        nodes.forEach(node => {
            const rect = node.getBoundingClientRect();
            const containerRect = this.container.getBoundingClientRect();
            
            // Position relative au conteneur
            const nodeRect = {
                left: rect.left - containerRect.left,
                top: rect.top - containerRect.top,
                right: rect.right - containerRect.left,
                bottom: rect.bottom - containerRect.top
            };
            
            // Vérifier si le nœud est dans la boîte de sélection
            if (nodeRect.left < selectionRect.right && 
                nodeRect.right > selectionRect.left && 
                nodeRect.top < selectionRect.bottom && 
                nodeRect.bottom > selectionRect.top) {
                this.selectNode(node, true);
            }
        });
    }

    /**
     * Sélectionne tous les nœuds entre deux nœuds donnés
     * @param {Element} startNode - Nœud de départ
     * @param {Element} endNode - Nœud de fin
     * @private
     */
    _selectNodesBetween(startNode, endNode) {
        const nodes = Array.from(this.container.querySelectorAll(this.options.nodeSelector));
        const startIndex = nodes.indexOf(startNode);
        const endIndex = nodes.indexOf(endNode);
        
        if (startIndex === -1 || endIndex === -1) return;
        
        // Déterminer les indices de début et de fin
        const minIndex = Math.min(startIndex, endIndex);
        const maxIndex = Math.max(startIndex, endIndex);
        
        // Sélectionner tous les nœuds dans la plage
        for (let i = minIndex; i <= maxIndex; i++) {
            this.selectNode(nodes[i], true);
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
                priority: node.dataset.nodePriority || ''
            };
        }
        
        return null;
    }

    /**
     * Sélectionne un nœud
     * @param {Element} node - Élément DOM du nœud
     * @param {boolean} addToSelection - Ajouter à la sélection existante
     */
    selectNode(node, addToSelection = false) {
        // Si pas de multi-sélection, désélectionner tout d'abord
        if (!addToSelection || !this.options.multiSelect) {
            this.clearSelection();
        }
        
        // Ajouter la classe de sélection
        node.classList.add(this.options.selectedClass);
        
        // Ajouter à l'ensemble des nœuds sélectionnés
        this.selectedNodes.add(node);
        
        // Mettre à jour le dernier nœud sélectionné
        this.lastSelectedNode = node;
        
        // Mettre en évidence les nœuds liés si activé
        if (this.options.highlightRelatedNodes) {
            this._highlightRelatedNodes(node);
        }
        
        // Ajouter à l'historique de sélection
        if (this.options.selectionPersistence) {
            this._addToSelectionHistory();
        }
        
        // Appeler le callback
        this._notifySelectionChange();
    }

    /**
     * Désélectionne un nœud
     * @param {Element} node - Élément DOM du nœud
     */
    deselectNode(node) {
        // Retirer la classe de sélection
        node.classList.remove(this.options.selectedClass);
        
        // Retirer de l'ensemble des nœuds sélectionnés
        this.selectedNodes.delete(node);
        
        // Mettre à jour le dernier nœud sélectionné
        if (this.lastSelectedNode === node) {
            this.lastSelectedNode = this.selectedNodes.size > 0 ? 
                Array.from(this.selectedNodes)[this.selectedNodes.size - 1] : null;
        }
        
        // Supprimer la mise en évidence des nœuds liés
        if (this.options.highlightRelatedNodes) {
            this._removeRelatedNodesHighlight();
            
            // Remettre en évidence les nœuds liés aux nœuds encore sélectionnés
            this.selectedNodes.forEach(selectedNode => {
                this._highlightRelatedNodes(selectedNode);
            });
        }
        
        // Ajouter à l'historique de sélection
        if (this.options.selectionPersistence) {
            this._addToSelectionHistory();
        }
        
        // Appeler le callback
        this._notifySelectionChange();
    }

    /**
     * Vérifie si un nœud est sélectionné
     * @param {Element} node - Élément DOM du nœud
     * @returns {boolean} - True si le nœud est sélectionné
     */
    isSelected(node) {
        return this.selectedNodes.has(node) || node.classList.contains(this.options.selectedClass);
    }

    /**
     * Désélectionne tous les nœuds
     */
    clearSelection() {
        // Retirer la classe de sélection de tous les nœuds
        this.selectedNodes.forEach(node => {
            node.classList.remove(this.options.selectedClass);
        });
        
        // Vider l'ensemble des nœuds sélectionnés
        this.selectedNodes.clear();
        this.lastSelectedNode = null;
        
        // Supprimer la mise en évidence des nœuds liés
        if (this.options.highlightRelatedNodes) {
            this._removeRelatedNodesHighlight();
        }
        
        // Ajouter à l'historique de sélection
        if (this.options.selectionPersistence) {
            this._addToSelectionHistory();
        }
        
        // Appeler le callback
        this._notifySelectionChange();
    }

    /**
     * Sélectionne tous les nœuds
     */
    selectAll() {
        const nodes = this.container.querySelectorAll(this.options.nodeSelector);
        
        // Sélectionner chaque nœud
        nodes.forEach(node => {
            node.classList.add(this.options.selectedClass);
            this.selectedNodes.add(node);
        });
        
        // Mettre à jour le dernier nœud sélectionné
        this.lastSelectedNode = this.selectedNodes.size > 0 ? 
            Array.from(this.selectedNodes)[this.selectedNodes.size - 1] : null;
        
        // Ajouter à l'historique de sélection
        if (this.options.selectionPersistence) {
            this._addToSelectionHistory();
        }
        
        // Appeler le callback
        this._notifySelectionChange();
    }

    /**
     * Met en évidence les nœuds liés à un nœud donné
     * @param {Element} node - Élément DOM du nœud
     * @private
     */
    _highlightRelatedNodes(node) {
        // Cette méthode doit être adaptée selon la structure du diagramme
        // Exemple simple : mettre en évidence les nœuds parents et enfants
        
        const nodeData = this._getNodeData(node);
        if (!nodeData || !nodeData.id) return;
        
        // Trouver les nœuds liés (à adapter selon la structure)
        const relatedNodes = this._findRelatedNodes(node);
        
        // Mettre en évidence les nœuds liés
        relatedNodes.forEach(relatedNode => {
            if (!this.isSelected(relatedNode)) {
                relatedNode.classList.add('related-node');
            }
        });
    }

    /**
     * Trouve les nœuds liés à un nœud donné
     * @param {Element} node - Élément DOM du nœud
     * @returns {Array} - Tableau des nœuds liés
     * @private
     */
    _findRelatedNodes(node) {
        // Cette méthode doit être adaptée selon la structure du diagramme
        // Exemple simple : trouver les nœuds parents et enfants via d3.js
        
        const relatedNodes = [];
        
        // Si d3.js est utilisé et que les données sont disponibles
        if (node.__data__) {
            const d3Node = node.__data__;
            
            // Ajouter le parent
            if (d3Node.parent) {
                const parentNode = this.container.querySelector(`[data-node-id="${d3Node.parent.data.id}"]`);
                if (parentNode) relatedNodes.push(parentNode);
            }
            
            // Ajouter les enfants
            if (d3Node.children) {
                d3Node.children.forEach(child => {
                    const childNode = this.container.querySelector(`[data-node-id="${child.data.id}"]`);
                    if (childNode) relatedNodes.push(childNode);
                });
            }
        }
        
        return relatedNodes;
    }

    /**
     * Supprime la mise en évidence des nœuds liés
     * @private
     */
    _removeRelatedNodesHighlight() {
        const relatedNodes = this.container.querySelectorAll('.related-node');
        relatedNodes.forEach(node => {
            node.classList.remove('related-node');
        });
    }

    /**
     * Ajoute l'état de sélection actuel à l'historique
     * @private
     */
    _addToSelectionHistory() {
        // Créer une copie de l'état actuel
        const selectionState = {
            nodes: Array.from(this.selectedNodes).map(node => {
                const data = this._getNodeData(node);
                return data ? data.id : null;
            }).filter(id => id !== null)
        };
        
        // Ajouter à l'historique
        this.selectionHistory.push(selectionState);
        
        // Limiter la taille de l'historique
        if (this.selectionHistory.length > this.maxHistorySize) {
            this.selectionHistory.shift();
        }
    }

    /**
     * Restaure un état de sélection précédent
     * @param {number} index - Index dans l'historique (-1 pour le dernier)
     * @returns {boolean} - True si la restauration a réussi
     */
    restoreSelection(index = -1) {
        const actualIndex = index < 0 ? 
            this.selectionHistory.length + index : index;
        
        if (actualIndex < 0 || actualIndex >= this.selectionHistory.length) {
            return false;
        }
        
        // Récupérer l'état de sélection
        const selectionState = this.selectionHistory[actualIndex];
        
        // Désélectionner tout d'abord
        this.clearSelection();
        
        // Restaurer la sélection
        selectionState.nodes.forEach(nodeId => {
            const node = this.container.querySelector(`[data-node-id="${nodeId}"]`);
            if (node) {
                this.selectNode(node, true);
            }
        });
        
        return true;
    }

    /**
     * Notifie le changement de sélection via le callback
     * @private
     */
    _notifySelectionChange() {
        if (typeof this.options.onSelectionChange === 'function') {
            const selectedData = Array.from(this.selectedNodes).map(node => this._getNodeData(node));
            this.options.onSelectionChange(selectedData, this.selectedNodes);
        }
    }

    /**
     * Obtient les données des nœuds sélectionnés
     * @returns {Array} - Tableau des données des nœuds sélectionnés
     */
    getSelectedData() {
        return Array.from(this.selectedNodes).map(node => this._getNodeData(node));
    }

    /**
     * Obtient les éléments DOM des nœuds sélectionnés
     * @returns {Set} - Ensemble des éléments DOM sélectionnés
     */
    getSelectedNodes() {
        return new Set(this.selectedNodes);
    }

    /**
     * Sélectionne des nœuds par ID
     * @param {Array} nodeIds - Tableau des IDs de nœuds à sélectionner
     * @param {boolean} addToSelection - Ajouter à la sélection existante
     * @returns {number} - Nombre de nœuds sélectionnés
     */
    selectNodesById(nodeIds, addToSelection = false) {
        if (!Array.isArray(nodeIds)) {
            nodeIds = [nodeIds];
        }
        
        // Si pas de multi-sélection, désélectionner tout d'abord
        if (!addToSelection || !this.options.multiSelect) {
            this.clearSelection();
        }
        
        let count = 0;
        
        // Sélectionner chaque nœud par ID
        nodeIds.forEach(nodeId => {
            const node = this.container.querySelector(`[data-node-id="${nodeId}"]`);
            if (node) {
                this.selectNode(node, true);
                count++;
            }
        });
        
        return count;
    }

    /**
     * Nettoie les ressources utilisées par le gestionnaire de sélection
     */
    dispose() {
        // Supprimer la boîte de sélection
        if (this.selectionBox && this.selectionBox.parentNode) {
            this.selectionBox.parentNode.removeChild(this.selectionBox);
        }
        
        // Désélectionner tout
        this.clearSelection();
        
        // Réinitialiser les variables
        this.selectedNodes = new Set();
        this.lastSelectedNode = null;
        this.selectionHistory = [];
        this.isSelecting = false;
        this.selectionBox = null;
    }
}

// Exporter la classe pour utilisation dans d'autres modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        SelectionManager
    };
}
