/**
 * hierarchical-diagram-updater.js
 * Module de mise à jour incrémentale des diagrammes hiérarchiques
 * Version: 1.0
 * Date: 2025-05-15
 */

/**
 * Classe HierarchicalDiagramUpdater
 * Gère les mises à jour incrémentales des diagrammes hiérarchiques
 */
class HierarchicalDiagramUpdater {
    /**
     * Constructeur
     * @param {Object} options - Options de configuration
     * @param {string} options.containerId - ID du conteneur SVG
     * @param {Object} options.initialData - Données initiales du diagramme
     * @param {Function} options.onUpdate - Callback appelé après chaque mise à jour
     * @param {number} options.transitionDuration - Durée des transitions en ms
     * @param {boolean} options.animateChanges - Activer les animations pour les changements
     */
    constructor(options = {}) {
        // Options par défaut
        this.options = Object.assign({
            containerId: 'hierarchy-container',
            initialData: null,
            onUpdate: null,
            transitionDuration: 750,
            animateChanges: true
        }, options);

        // État interne
        this.currentData = this.options.initialData ? this._cloneData(this.options.initialData) : null;
        this.previousData = null;
        this.updateQueue = [];
        this.isUpdating = false;
        this.updateHistory = [];
        this.maxHistorySize = 50;
        this.currentHistoryIndex = -1;

        // Éléments DOM
        this.container = document.getElementById(this.options.containerId);
        
        // Initialisation
        if (this.currentData) {
            this._saveToHistory(this.currentData);
        }
    }

    /**
     * Clone profondément les données pour éviter les références partagées
     * @param {Object} data - Données à cloner
     * @returns {Object} - Clone des données
     * @private
     */
    _cloneData(data) {
        return JSON.parse(JSON.stringify(data));
    }

    /**
     * Sauvegarde l'état actuel dans l'historique
     * @param {Object} data - Données à sauvegarder
     * @private
     */
    _saveToHistory(data) {
        // Si nous ne sommes pas à la fin de l'historique, supprimer les états futurs
        if (this.currentHistoryIndex < this.updateHistory.length - 1) {
            this.updateHistory = this.updateHistory.slice(0, this.currentHistoryIndex + 1);
        }
        
        // Ajouter le nouvel état
        this.updateHistory.push(this._cloneData(data));
        
        // Limiter la taille de l'historique
        if (this.updateHistory.length > this.maxHistorySize) {
            this.updateHistory.shift();
        }
        
        // Mettre à jour l'index
        this.currentHistoryIndex = this.updateHistory.length - 1;
    }

    /**
     * Met à jour les données avec un nouvel ensemble de données
     * @param {Object} newData - Nouvelles données complètes
     * @param {boolean} incremental - Si true, calcule et applique les différences, sinon remplace tout
     * @returns {Object} - Différences appliquées
     */
    updateData(newData, incremental = true) {
        // Vérifier si les données sont valides
        if (!newData) {
            console.error('Données de mise à jour invalides');
            return null;
        }
        
        // Cloner les nouvelles données
        const clonedNewData = this._cloneData(newData);
        
        // Si pas de mise à jour incrémentale ou pas de données actuelles, remplacer complètement
        if (!incremental || !this.currentData) {
            this.previousData = this.currentData;
            this.currentData = clonedNewData;
            this._saveToHistory(this.currentData);
            
            // Appeler le callback
            if (typeof this.options.onUpdate === 'function') {
                this.options.onUpdate(this.currentData, null);
            }
            
            return { fullUpdate: true };
        }
        
        // Calculer les différences
        const diff = this._calculateDiff(this.currentData, clonedNewData);
        
        // Appliquer les différences
        if (diff.hasChanges) {
            this.previousData = this._cloneData(this.currentData);
            this._applyDiff(this.currentData, diff);
            this._saveToHistory(this.currentData);
            
            // Appeler le callback
            if (typeof this.options.onUpdate === 'function') {
                this.options.onUpdate(this.currentData, diff);
            }
        }
        
        return diff;
    }

    /**
     * Calcule les différences entre deux ensembles de données
     * @param {Object} oldData - Anciennes données
     * @param {Object} newData - Nouvelles données
     * @returns {Object} - Objet contenant les différences
     * @private
     */
    _calculateDiff(oldData, newData) {
        const diff = {
            hasChanges: false,
            added: [],
            removed: [],
            modified: [],
            moved: [],
            structureChanged: false
        };
        
        // Fonction récursive pour comparer les nœuds
        const compareNodes = (oldNode, newNode, path = []) => {
            // Vérifier les modifications de propriétés de base
            const propertyChanges = {};
            let hasPropertyChanges = false;
            
            // Propriétés à comparer
            const propertiesToCompare = ['title', 'status', 'priority', 'progress', 'description'];
            
            for (const prop of propertiesToCompare) {
                if (oldNode[prop] !== newNode[prop]) {
                    propertyChanges[prop] = {
                        old: oldNode[prop],
                        new: newNode[prop]
                    };
                    hasPropertyChanges = true;
                }
            }
            
            // Si des propriétés ont changé, ajouter aux modifications
            if (hasPropertyChanges) {
                diff.hasChanges = true;
                diff.modified.push({
                    id: oldNode.id,
                    path: [...path],
                    changes: propertyChanges
                });
            }
            
            // Comparer les enfants
            const oldChildren = oldNode.children || [];
            const newChildren = newNode.children || [];
            
            // Créer des maps pour faciliter la recherche
            const oldChildrenMap = new Map();
            const newChildrenMap = new Map();
            
            oldChildren.forEach(child => oldChildrenMap.set(child.id, child));
            newChildren.forEach(child => newChildrenMap.set(child.id, child));
            
            // Vérifier les nœuds supprimés
            for (const oldChild of oldChildren) {
                if (!newChildrenMap.has(oldChild.id)) {
                    diff.hasChanges = true;
                    diff.structureChanged = true;
                    diff.removed.push({
                        id: oldChild.id,
                        path: [...path, oldNode.id],
                        node: oldChild
                    });
                }
            }
            
            // Vérifier les nœuds ajoutés
            for (const newChild of newChildren) {
                if (!oldChildrenMap.has(newChild.id)) {
                    diff.hasChanges = true;
                    diff.structureChanged = true;
                    diff.added.push({
                        id: newChild.id,
                        path: [...path, oldNode.id],
                        node: newChild
                    });
                }
            }
            
            // Vérifier les changements d'ordre
            if (oldChildren.length > 0 && newChildren.length > 0) {
                const commonIds = oldChildren
                    .filter(child => newChildrenMap.has(child.id))
                    .map(child => child.id);
                
                // Extraire l'ordre des IDs communs dans les deux ensembles
                const oldOrder = commonIds.map(id => oldChildren.findIndex(child => child.id === id));
                const newOrder = commonIds.map(id => newChildren.findIndex(child => child.id === id));
                
                // Vérifier si l'ordre relatif a changé
                let orderChanged = false;
                for (let i = 0; i < commonIds.length - 1; i++) {
                    for (let j = i + 1; j < commonIds.length; j++) {
                        // Si l'ordre relatif de deux éléments a changé
                        if ((oldOrder[i] < oldOrder[j] && newOrder[i] > newOrder[j]) ||
                            (oldOrder[i] > oldOrder[j] && newOrder[i] < newOrder[j])) {
                            orderChanged = true;
                            break;
                        }
                    }
                    if (orderChanged) break;
                }
                
                if (orderChanged) {
                    diff.hasChanges = true;
                    diff.structureChanged = true;
                    diff.moved.push({
                        id: oldNode.id,
                        path: [...path],
                        oldOrder: oldChildren.map(child => child.id),
                        newOrder: newChildren.map(child => child.id)
                    });
                }
            }
            
            // Récursivement comparer les enfants communs
            for (const oldChild of oldChildren) {
                const newChild = newChildrenMap.get(oldChild.id);
                if (newChild) {
                    compareNodes(oldChild, newChild, [...path, oldNode.id]);
                }
            }
        };
        
        // Démarrer la comparaison à partir de la racine
        compareNodes(oldData, newData);
        
        return diff;
    }

    /**
     * Applique les différences calculées aux données actuelles
     * @param {Object} data - Données à mettre à jour
     * @param {Object} diff - Différences à appliquer
     * @private
     */
    _applyDiff(data, diff) {
        // Fonction pour trouver un nœud par chemin
        const findNodeByPath = (root, path) => {
            let current = root;
            
            for (let i = 0; i < path.length; i++) {
                const nodeId = path[i];
                if (!current.children) return null;
                
                const child = current.children.find(c => c.id === nodeId);
                if (!child) return null;
                
                current = child;
            }
            
            return current;
        };
        
        // Appliquer les modifications de propriétés
        for (const mod of diff.modified) {
            const node = mod.path.length === 0 
                ? data 
                : findNodeByPath(data, mod.path);
            
            if (node) {
                const targetNode = node.children.find(child => child.id === mod.id);
                
                if (targetNode) {
                    // Appliquer les changements de propriétés
                    for (const [prop, change] of Object.entries(mod.changes)) {
                        targetNode[prop] = change.new;
                    }
                }
            }
        }
        
        // Appliquer les suppressions
        for (const removed of diff.removed) {
            const parentNode = removed.path.length === 0 
                ? data 
                : findNodeByPath(data, removed.path);
            
            if (parentNode && parentNode.children) {
                const index = parentNode.children.findIndex(child => child.id === removed.id);
                
                if (index !== -1) {
                    parentNode.children.splice(index, 1);
                }
            }
        }
        
        // Appliquer les ajouts
        for (const added of diff.added) {
            const parentNode = added.path.length === 0 
                ? data 
                : findNodeByPath(data, added.path);
            
            if (parentNode) {
                if (!parentNode.children) {
                    parentNode.children = [];
                }
                
                parentNode.children.push(added.node);
            }
        }
        
        // Appliquer les déplacements
        for (const moved of diff.moved) {
            const parentNode = moved.path.length === 0 
                ? data 
                : findNodeByPath(data, moved.path);
            
            if (parentNode && parentNode.children) {
                // Créer une map des enfants actuels
                const childrenMap = new Map();
                parentNode.children.forEach(child => childrenMap.set(child.id, child));
                
                // Réorganiser les enfants selon le nouvel ordre
                const newChildren = [];
                
                for (const id of moved.newOrder) {
                    const child = childrenMap.get(id);
                    if (child) {
                        newChildren.push(child);
                    }
                }
                
                // Ajouter les enfants qui ne sont pas dans le nouvel ordre (ajoutés récemment)
                for (const child of parentNode.children) {
                    if (!moved.newOrder.includes(child.id)) {
                        newChildren.push(child);
                    }
                }
                
                // Remplacer les enfants
                parentNode.children = newChildren;
            }
        }
    }

    /**
     * Annule la dernière mise à jour
     * @returns {boolean} - True si l'annulation a réussi, false sinon
     */
    undo() {
        if (this.currentHistoryIndex <= 0) {
            console.warn('Aucune action à annuler');
            return false;
        }
        
        this.currentHistoryIndex--;
        this.currentData = this._cloneData(this.updateHistory[this.currentHistoryIndex]);
        
        // Appeler le callback
        if (typeof this.options.onUpdate === 'function') {
            this.options.onUpdate(this.currentData, { undoRedo: true });
        }
        
        return true;
    }

    /**
     * Rétablit la dernière mise à jour annulée
     * @returns {boolean} - True si le rétablissement a réussi, false sinon
     */
    redo() {
        if (this.currentHistoryIndex >= this.updateHistory.length - 1) {
            console.warn('Aucune action à rétablir');
            return false;
        }
        
        this.currentHistoryIndex++;
        this.currentData = this._cloneData(this.updateHistory[this.currentHistoryIndex]);
        
        // Appeler le callback
        if (typeof this.options.onUpdate === 'function') {
            this.options.onUpdate(this.currentData, { undoRedo: true });
        }
        
        return true;
    }

    /**
     * Ajoute une mise à jour à la file d'attente
     * @param {Object} update - Mise à jour à ajouter
     * @param {boolean} applyImmediately - Si true, applique immédiatement, sinon ajoute à la file
     */
    queueUpdate(update, applyImmediately = false) {
        this.updateQueue.push(update);
        
        if (applyImmediately) {
            this.processQueue();
        }
    }

    /**
     * Traite la file d'attente des mises à jour
     * @returns {Promise} - Promise résolue quand toutes les mises à jour sont appliquées
     */
    async processQueue() {
        if (this.isUpdating || this.updateQueue.length === 0) {
            return;
        }
        
        this.isUpdating = true;
        
        try {
            while (this.updateQueue.length > 0) {
                const update = this.updateQueue.shift();
                
                // Si c'est une fonction, l'exécuter pour obtenir les données
                const updateData = typeof update === 'function' 
                    ? await update(this.currentData) 
                    : update;
                
                // Appliquer la mise à jour
                this.updateData(updateData);
                
                // Attendre un peu pour permettre au rendu de se faire
                if (this.updateQueue.length > 0 && this.options.animateChanges) {
                    await new Promise(resolve => setTimeout(resolve, this.options.transitionDuration));
                }
            }
        } catch (error) {
            console.error('Erreur lors du traitement de la file de mises à jour:', error);
        } finally {
            this.isUpdating = false;
        }
    }

    /**
     * Obtient les différences entre les données actuelles et précédentes
     * @returns {Object} - Différences ou null si pas de données précédentes
     */
    getLastDiff() {
        if (!this.previousData || !this.currentData) {
            return null;
        }
        
        return this._calculateDiff(this.previousData, this.currentData);
    }

    /**
     * Obtient l'état actuel des données
     * @returns {Object} - Données actuelles
     */
    getCurrentData() {
        return this._cloneData(this.currentData);
    }

    /**
     * Vérifie si des annulations sont disponibles
     * @returns {boolean} - True si des annulations sont disponibles
     */
    canUndo() {
        return this.currentHistoryIndex > 0;
    }

    /**
     * Vérifie si des rétablissements sont disponibles
     * @returns {boolean} - True si des rétablissements sont disponibles
     */
    canRedo() {
        return this.currentHistoryIndex < this.updateHistory.length - 1;
    }

    /**
     * Nettoie les ressources utilisées par l'updater
     */
    dispose() {
        this.updateQueue = [];
        this.updateHistory = [];
        this.currentData = null;
        this.previousData = null;
    }
}

// Exporter la classe pour utilisation dans d'autres modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        HierarchicalDiagramUpdater
    };
}
