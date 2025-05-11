/**
 * hierarchical-diagram-callbacks.js
 * Module de gestion des callbacks personnalisables pour les diagrammes hiérarchiques
 * Version: 1.0
 * Date: 2025-05-15
 */

/**
 * Classe CallbackRegistry
 * Gère l'enregistrement et l'invocation de callbacks personnalisables
 */
class CallbackRegistry {
    /**
     * Constructeur
     * @param {Object} options - Options de configuration
     * @param {boolean} options.debug - Activer le mode debug
     * @param {number} options.timeout - Timeout par défaut pour les callbacks en ms
     */
    constructor(options = {}) {
        // Options par défaut
        this.options = Object.assign({
            debug: false,
            timeout: 5000,
            asyncCallbacks: true,
            catchErrors: true,
            maxCallbacks: 100,
            maxCallStackSize: 20
        }, options);

        // État interne
        this.callbacks = new Map();
        this.callbackCounter = 0;
        this.activeCallbacks = new Set();
        this.callHistory = [];
        this.maxHistorySize = 100;
        this.callStack = [];
        this.errorHandlers = [];
        this.defaultContext = this;
    }

    /**
     * Enregistre un callback
     * @param {string} name - Nom du callback
     * @param {Function} callback - Fonction de callback
     * @param {Object} options - Options supplémentaires
     * @returns {number} - ID du callback
     */
    register(name, callback, options = {}) {
        if (typeof callback !== 'function') {
            throw new Error('Le callback doit être une fonction');
        }

        // Vérifier le nombre maximum de callbacks
        if (this.callbacks.size >= this.options.maxCallbacks) {
            this._debug(`Nombre maximum de callbacks atteint (${this.options.maxCallbacks})`);
            
            // Supprimer le callback le plus ancien
            const oldestCallback = Array.from(this.callbacks.values())[0];
            this.unregister(oldestCallback.id);
        }

        // Options par défaut
        const callbackOptions = Object.assign({
            context: null,
            timeout: this.options.timeout,
            priority: 0,
            once: false,
            async: this.options.asyncCallbacks,
            metadata: {}
        }, options);

        // Générer un ID unique
        const id = ++this.callbackCounter;

        // Créer l'objet callback
        const callbackObj = {
            id,
            name,
            callback,
            options: callbackOptions,
            registered: Date.now()
        };

        // Ajouter au registre
        this.callbacks.set(id, callbackObj);

        this._debug(`Callback '${name}' enregistré avec ID ${id}`);

        return id;
    }

    /**
     * Supprime un callback
     * @param {number|string} idOrName - ID ou nom du callback
     * @returns {boolean} - True si la suppression a réussi
     */
    unregister(idOrName) {
        // Suppression par ID
        if (typeof idOrName === 'number') {
            const result = this.callbacks.delete(idOrName);
            
            if (result) {
                this._debug(`Callback avec ID ${idOrName} supprimé`);
            }
            
            return result;
        }
        
        // Suppression par nom
        if (typeof idOrName === 'string') {
            let found = false;
            
            // Trouver tous les callbacks avec ce nom
            for (const [id, callback] of this.callbacks.entries()) {
                if (callback.name === idOrName) {
                    this.callbacks.delete(id);
                    found = true;
                    this._debug(`Callback '${idOrName}' avec ID ${id} supprimé`);
                }
            }
            
            return found;
        }
        
        return false;
    }

    /**
     * Invoque un callback
     * @param {number|string} idOrName - ID ou nom du callback
     * @param {Array} args - Arguments à passer au callback
     * @param {Object} options - Options d'invocation
     * @returns {Promise|*} - Résultat du callback ou Promise
     */
    invoke(idOrName, args = [], options = {}) {
        // Options par défaut
        const invokeOptions = Object.assign({
            timeout: null,
            context: null,
            async: null,
            metadata: {}
        }, options);
        
        // Trouver le(s) callback(s)
        const callbacksToInvoke = this._findCallbacks(idOrName);
        
        if (callbacksToInvoke.length === 0) {
            this._debug(`Aucun callback trouvé pour '${idOrName}'`);
            return Promise.resolve(null);
        }
        
        // Si plusieurs callbacks, les invoquer tous et retourner un tableau de résultats
        if (callbacksToInvoke.length > 1) {
            const results = callbacksToInvoke.map(callback => 
                this._invokeCallback(callback, args, invokeOptions)
            );
            
            // Si tous les callbacks sont synchrones, retourner directement les résultats
            if (results.every(r => !(r instanceof Promise))) {
                return results;
            }
            
            // Sinon, attendre que toutes les promesses soient résolues
            return Promise.all(results);
        }
        
        // Invoquer un seul callback
        return this._invokeCallback(callbacksToInvoke[0], args, invokeOptions);
    }

    /**
     * Invoque un callback de manière interne
     * @param {Object} callbackObj - Objet callback
     * @param {Array} args - Arguments à passer au callback
     * @param {Object} options - Options d'invocation
     * @returns {Promise|*} - Résultat du callback ou Promise
     * @private
     */
    _invokeCallback(callbackObj, args, options) {
        // Vérifier la profondeur de la pile d'appels
        if (this.callStack.length >= this.options.maxCallStackSize) {
            const error = new Error(`Profondeur maximale de la pile d'appels atteinte (${this.options.maxCallStackSize})`);
            this._handleError(error, callbackObj, args);
            return Promise.reject(error);
        }
        
        // Ajouter à la pile d'appels
        this.callStack.push(callbackObj.id);
        
        // Marquer comme actif
        this.activeCallbacks.add(callbackObj.id);
        
        // Déterminer le contexte
        const context = options.context || callbackObj.options.context || this.defaultContext;
        
        // Déterminer si le callback est asynchrone
        const isAsync = options.async !== null ? options.async : callbackObj.options.async;
        
        // Déterminer le timeout
        const timeout = options.timeout || callbackObj.options.timeout;
        
        // Créer l'objet d'invocation pour l'historique
        const invocation = {
            id: callbackObj.id,
            name: callbackObj.name,
            timestamp: Date.now(),
            args: [...args],
            async: isAsync,
            metadata: { ...callbackObj.options.metadata, ...options.metadata }
        };
        
        // Ajouter à l'historique
        this._addToHistory(invocation);
        
        try {
            // Invoquer le callback
            let result = callbackObj.callback.apply(context, args);
            
            // Si le callback est asynchrone et retourne une promesse
            if (isAsync && result instanceof Promise) {
                // Ajouter un timeout si nécessaire
                if (timeout > 0) {
                    result = this._addTimeout(result, timeout, callbackObj);
                }
                
                // Ajouter les gestionnaires de fin
                return result
                    .then(value => {
                        // Mettre à jour l'historique
                        invocation.result = value;
                        invocation.endTimestamp = Date.now();
                        invocation.duration = invocation.endTimestamp - invocation.timestamp;
                        
                        // Nettoyer
                        this._cleanupAfterInvocation(callbackObj);
                        
                        return value;
                    })
                    .catch(error => {
                        // Mettre à jour l'historique
                        invocation.error = error;
                        invocation.endTimestamp = Date.now();
                        invocation.duration = invocation.endTimestamp - invocation.timestamp;
                        
                        // Gérer l'erreur
                        this._handleError(error, callbackObj, args);
                        
                        // Nettoyer
                        this._cleanupAfterInvocation(callbackObj);
                        
                        throw error;
                    });
            }
            
            // Pour les callbacks synchrones
            invocation.result = result;
            invocation.endTimestamp = Date.now();
            invocation.duration = invocation.endTimestamp - invocation.timestamp;
            
            // Nettoyer
            this._cleanupAfterInvocation(callbackObj);
            
            return result;
        } catch (error) {
            // Mettre à jour l'historique
            invocation.error = error;
            invocation.endTimestamp = Date.now();
            invocation.duration = invocation.endTimestamp - invocation.timestamp;
            
            // Gérer l'erreur
            this._handleError(error, callbackObj, args);
            
            // Nettoyer
            this._cleanupAfterInvocation(callbackObj);
            
            // Si on ne capture pas les erreurs, les propager
            if (!this.options.catchErrors) {
                throw error;
            }
            
            // Sinon, retourner null ou rejeter la promesse
            return isAsync ? Promise.reject(error) : null;
        }
    }

    /**
     * Nettoie après l'invocation d'un callback
     * @param {Object} callbackObj - Objet callback
     * @private
     */
    _cleanupAfterInvocation(callbackObj) {
        // Retirer de la pile d'appels
        const index = this.callStack.lastIndexOf(callbackObj.id);
        if (index !== -1) {
            this.callStack.splice(index, 1);
        }
        
        // Retirer des callbacks actifs
        this.activeCallbacks.delete(callbackObj.id);
        
        // Si c'est un callback à usage unique, le supprimer
        if (callbackObj.options.once) {
            this.unregister(callbackObj.id);
        }
    }

    /**
     * Ajoute un timeout à une promesse
     * @param {Promise} promise - Promesse à surveiller
     * @param {number} timeout - Timeout en ms
     * @param {Object} callbackObj - Objet callback
     * @returns {Promise} - Promesse avec timeout
     * @private
     */
    _addTimeout(promise, timeout, callbackObj) {
        return Promise.race([
            promise,
            new Promise((_, reject) => {
                setTimeout(() => {
                    const error = new Error(`Timeout de ${timeout}ms dépassé pour le callback '${callbackObj.name}'`);
                    error.code = 'CALLBACK_TIMEOUT';
                    reject(error);
                }, timeout);
            })
        ]);
    }

    /**
     * Trouve les callbacks correspondant à un ID ou un nom
     * @param {number|string} idOrName - ID ou nom du callback
     * @returns {Array} - Tableau d'objets callback
     * @private
     */
    _findCallbacks(idOrName) {
        // Recherche par ID
        if (typeof idOrName === 'number') {
            const callback = this.callbacks.get(idOrName);
            return callback ? [callback] : [];
        }
        
        // Recherche par nom
        if (typeof idOrName === 'string') {
            return Array.from(this.callbacks.values())
                .filter(callback => callback.name === idOrName)
                .sort((a, b) => b.options.priority - a.options.priority);
        }
        
        return [];
    }

    /**
     * Gère une erreur survenue lors de l'invocation d'un callback
     * @param {Error} error - Erreur survenue
     * @param {Object} callbackObj - Objet callback
     * @param {Array} args - Arguments passés au callback
     * @private
     */
    _handleError(error, callbackObj, args) {
        this._debug(`Erreur dans le callback '${callbackObj.name}' (ID: ${callbackObj.id}):`, error);
        
        // Appeler les gestionnaires d'erreurs
        for (const handler of this.errorHandlers) {
            try {
                handler(error, callbackObj, args);
            } catch (handlerError) {
                console.error('Erreur dans le gestionnaire d\'erreurs:', handlerError);
            }
        }
    }

    /**
     * Ajoute une invocation à l'historique
     * @param {Object} invocation - Objet d'invocation
     * @private
     */
    _addToHistory(invocation) {
        this.callHistory.push(invocation);
        
        // Limiter la taille de l'historique
        if (this.callHistory.length > this.maxHistorySize) {
            this.callHistory.shift();
        }
    }

    /**
     * Ajoute un gestionnaire d'erreurs
     * @param {Function} handler - Fonction de gestion d'erreurs
     * @returns {number} - Index du gestionnaire
     */
    addErrorHandler(handler) {
        if (typeof handler !== 'function') {
            throw new Error('Le gestionnaire d\'erreurs doit être une fonction');
        }
        
        this.errorHandlers.push(handler);
        return this.errorHandlers.length - 1;
    }

    /**
     * Supprime un gestionnaire d'erreurs
     * @param {number} index - Index du gestionnaire
     * @returns {boolean} - True si la suppression a réussi
     */
    removeErrorHandler(index) {
        if (index >= 0 && index < this.errorHandlers.length) {
            this.errorHandlers.splice(index, 1);
            return true;
        }
        
        return false;
    }

    /**
     * Définit le contexte par défaut pour les callbacks
     * @param {Object} context - Contexte par défaut
     */
    setDefaultContext(context) {
        this.defaultContext = context || this;
    }

    /**
     * Obtient l'historique des appels
     * @param {string} name - Nom du callback (optionnel)
     * @param {number} limit - Nombre maximum d'entrées (optionnel)
     * @returns {Array} - Historique des appels
     */
    getCallHistory(name = null, limit = null) {
        let history = [...this.callHistory];
        
        // Filtrer par nom si spécifié
        if (name) {
            history = history.filter(entry => entry.name === name);
        }
        
        // Limiter le nombre d'entrées si spécifié
        if (limit && limit > 0) {
            history = history.slice(-limit);
        }
        
        return history;
    }

    /**
     * Vérifie si un callback est actif
     * @param {number|string} idOrName - ID ou nom du callback
     * @returns {boolean} - True si le callback est actif
     */
    isActive(idOrName) {
        // Vérification par ID
        if (typeof idOrName === 'number') {
            return this.activeCallbacks.has(idOrName);
        }
        
        // Vérification par nom
        if (typeof idOrName === 'string') {
            const callbacks = this._findCallbacks(idOrName);
            return callbacks.some(callback => this.activeCallbacks.has(callback.id));
        }
        
        return false;
    }

    /**
     * Obtient des statistiques sur les callbacks
     * @returns {Object} - Statistiques
     */
    getStats() {
        const stats = {
            total: this.callbacks.size,
            active: this.activeCallbacks.size,
            callHistory: this.callHistory.length,
            callStack: this.callStack.length,
            byName: {}
        };
        
        // Compter les callbacks par nom
        for (const callback of this.callbacks.values()) {
            if (!stats.byName[callback.name]) {
                stats.byName[callback.name] = 0;
            }
            
            stats.byName[callback.name]++;
        }
        
        return stats;
    }

    /**
     * Enregistre un message de debug
     * @param {string} message - Message à enregistrer
     * @param {Object} data - Données supplémentaires (optionnel)
     * @private
     */
    _debug(message, data = null) {
        if (this.options.debug) {
            if (data) {
                console.log(`[CallbackRegistry] ${message}`, data);
            } else {
                console.log(`[CallbackRegistry] ${message}`);
            }
        }
    }

    /**
     * Nettoie les ressources utilisées par le registre
     */
    dispose() {
        // Supprimer tous les callbacks
        this.callbacks.clear();
        
        // Réinitialiser les variables
        this.activeCallbacks.clear();
        this.callStack = [];
        this.callHistory = [];
        this.errorHandlers = [];
        
        this._debug('CallbackRegistry nettoyé');
    }
}

// Exporter la classe pour utilisation dans d'autres modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        CallbackRegistry
    };
}
