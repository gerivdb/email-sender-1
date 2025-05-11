/**
 * hierarchical-diagram-invocation.js
 * Module de mécanismes d'invocation avancés pour les diagrammes hiérarchiques
 * Version: 1.0
 * Date: 2025-05-15
 */

/**
 * Classe InvocationManager
 * Gère les mécanismes d'invocation avancés pour les callbacks
 */
class InvocationManager {
    /**
     * Constructeur
     * @param {CallbackRegistry} callbackRegistry - Registre de callbacks
     * @param {Object} options - Options de configuration
     */
    constructor(callbackRegistry, options = {}) {
        // Options par défaut
        this.options = Object.assign({
            debug: false,
            maxConcurrent: 5,
            queueSize: 100,
            retryCount: 3,
            retryDelay: 1000,
            priorityLevels: 5,
            batchSize: 10,
            batchDelay: 50
        }, options);

        // Référence au registre de callbacks
        this.callbackRegistry = callbackRegistry;

        // État interne
        this.invocationQueue = [];
        this.activeInvocations = new Set();
        this.batchTimers = new Map();
        this.retryCounters = new Map();
        this.invocationResults = new Map();
        this.invocationPromises = new Map();
        this.invocationResolvers = new Map();
        this.invocationRejecters = new Map();
        this.middlewares = [];
        this.isProcessing = false;
        this.invocationCounter = 0;
    }

    /**
     * Invoque un callback avec des options avancées
     * @param {number|string} idOrName - ID ou nom du callback
     * @param {Array} args - Arguments à passer au callback
     * @param {Object} options - Options d'invocation
     * @returns {Promise} - Promise résolue avec le résultat
     */
    invoke(idOrName, args = [], options = {}) {
        // Options par défaut
        const invokeOptions = Object.assign({
            priority: 0,
            timeout: null,
            retry: false,
            retryCount: this.options.retryCount,
            retryDelay: this.options.retryDelay,
            batch: false,
            batchKey: null,
            batchDelay: this.options.batchDelay,
            context: null,
            metadata: {}
        }, options);

        // Générer un ID d'invocation unique
        const invocationId = ++this.invocationCounter;

        // Créer l'objet d'invocation
        const invocation = {
            id: invocationId,
            callbackId: idOrName,
            args,
            options: invokeOptions,
            timestamp: Date.now(),
            status: 'pending'
        };

        // Créer une promesse pour cette invocation
        const promise = new Promise((resolve, reject) => {
            this.invocationResolvers.set(invocationId, resolve);
            this.invocationRejecters.set(invocationId, reject);
        });

        // Stocker la promesse
        this.invocationPromises.set(invocationId, promise);

        // Si l'invocation doit être mise en lot
        if (invokeOptions.batch) {
            return this._batchInvocation(invocation);
        }

        // Ajouter à la file d'attente
        this._enqueueInvocation(invocation);

        // Traiter la file d'attente
        this._processQueue();

        return promise;
    }

    /**
     * Met en file d'attente une invocation
     * @param {Object} invocation - Objet d'invocation
     * @private
     */
    _enqueueInvocation(invocation) {
        // Vérifier la taille de la file d'attente
        if (this.invocationQueue.length >= this.options.queueSize) {
            // Supprimer l'invocation la moins prioritaire
            this.invocationQueue.sort((a, b) => b.options.priority - a.options.priority);
            const removed = this.invocationQueue.pop();
            
            // Rejeter la promesse associée
            const rejecter = this.invocationRejecters.get(removed.id);
            if (rejecter) {
                const error = new Error('Invocation annulée : file d\'attente pleine');
                error.code = 'QUEUE_FULL';
                rejecter(error);
            }
            
            // Nettoyer
            this.invocationResolvers.delete(removed.id);
            this.invocationRejecters.delete(removed.id);
            this.invocationPromises.delete(removed.id);
            
            this._debug(`Invocation ${removed.id} supprimée de la file d'attente (pleine)`);
        }
        
        // Ajouter à la file d'attente
        this.invocationQueue.push(invocation);
        
        // Trier par priorité
        this.invocationQueue.sort((a, b) => b.options.priority - a.options.priority);
        
        this._debug(`Invocation ${invocation.id} ajoutée à la file d'attente`);
    }

    /**
     * Met en lot une invocation
     * @param {Object} invocation - Objet d'invocation
     * @returns {Promise} - Promise résolue avec le résultat
     * @private
     */
    _batchInvocation(invocation) {
        // Déterminer la clé de lot
        const batchKey = invocation.options.batchKey || invocation.callbackId.toString();
        
        // Ajouter à la file d'attente
        this._enqueueInvocation(invocation);
        
        // Annuler le timer existant
        if (this.batchTimers.has(batchKey)) {
            clearTimeout(this.batchTimers.get(batchKey));
        }
        
        // Créer un nouveau timer
        const timerId = setTimeout(() => {
            // Traiter le lot
            this._processBatch(batchKey);
            
            // Supprimer le timer
            this.batchTimers.delete(batchKey);
        }, invocation.options.batchDelay);
        
        // Stocker le timer
        this.batchTimers.set(batchKey, timerId);
        
        return this.invocationPromises.get(invocation.id);
    }

    /**
     * Traite un lot d'invocations
     * @param {string} batchKey - Clé de lot
     * @private
     */
    _processBatch(batchKey) {
        // Trouver toutes les invocations pour cette clé
        const batchInvocations = this.invocationQueue.filter(inv => {
            if (!inv.options.batch) return false;
            const key = inv.options.batchKey || inv.callbackId.toString();
            return key === batchKey;
        });
        
        if (batchInvocations.length === 0) {
            return;
        }
        
        this._debug(`Traitement du lot '${batchKey}' avec ${batchInvocations.length} invocations`);
        
        // Regrouper par callbackId
        const groupedInvocations = new Map();
        
        for (const inv of batchInvocations) {
            const key = inv.callbackId;
            
            if (!groupedInvocations.has(key)) {
                groupedInvocations.set(key, []);
            }
            
            groupedInvocations.get(key).push(inv);
        }
        
        // Traiter chaque groupe
        for (const [callbackId, invocations] of groupedInvocations.entries()) {
            // Collecter tous les arguments
            const allArgs = invocations.map(inv => inv.args);
            
            // Créer une invocation de lot
            const batchInvocation = {
                id: ++this.invocationCounter,
                callbackId,
                args: [allArgs],
                options: { ...invocations[0].options, batch: false },
                timestamp: Date.now(),
                status: 'pending',
                batchedIds: invocations.map(inv => inv.id)
            };
            
            // Supprimer les invocations individuelles de la file d'attente
            this.invocationQueue = this.invocationQueue.filter(inv => !batchInvocation.batchedIds.includes(inv.id));
            
            // Ajouter l'invocation de lot à la file d'attente
            this._enqueueInvocation(batchInvocation);
            
            // Créer une promesse pour cette invocation
            const promise = new Promise((resolve, reject) => {
                this.invocationResolvers.set(batchInvocation.id, resolve);
                this.invocationRejecters.set(batchInvocation.id, reject);
            });
            
            // Stocker la promesse
            this.invocationPromises.set(batchInvocation.id, promise);
            
            // Ajouter un gestionnaire pour distribuer les résultats
            promise.then(result => {
                // Distribuer les résultats aux invocations individuelles
                if (Array.isArray(result) && result.length === allArgs.length) {
                    // Résultats individuels
                    for (let i = 0; i < invocations.length; i++) {
                        const resolver = this.invocationResolvers.get(invocations[i].id);
                        if (resolver) {
                            resolver(result[i]);
                        }
                    }
                } else {
                    // Même résultat pour tous
                    for (const inv of invocations) {
                        const resolver = this.invocationResolvers.get(inv.id);
                        if (resolver) {
                            resolver(result);
                        }
                    }
                }
            }).catch(error => {
                // Propager l'erreur à toutes les invocations
                for (const inv of invocations) {
                    const rejecter = this.invocationRejecters.get(inv.id);
                    if (rejecter) {
                        rejecter(error);
                    }
                }
            });
        }
        
        // Traiter la file d'attente
        this._processQueue();
    }

    /**
     * Traite la file d'attente d'invocations
     * @private
     */
    _processQueue() {
        if (this.isProcessing || this.invocationQueue.length === 0) {
            return;
        }
        
        this.isProcessing = true;
        
        // Traiter tant qu'il y a des invocations et des slots disponibles
        while (this.invocationQueue.length > 0 && this.activeInvocations.size < this.options.maxConcurrent) {
            // Récupérer la prochaine invocation
            const invocation = this.invocationQueue.shift();
            
            // Exécuter l'invocation
            this._executeInvocation(invocation);
        }
        
        this.isProcessing = false;
    }

    /**
     * Exécute une invocation
     * @param {Object} invocation - Objet d'invocation
     * @private
     */
    _executeInvocation(invocation) {
        // Marquer comme active
        this.activeInvocations.add(invocation.id);
        invocation.status = 'active';
        
        this._debug(`Exécution de l'invocation ${invocation.id}`);
        
        // Appliquer les middlewares
        let args = invocation.args;
        let options = invocation.options;
        
        for (const middleware of this.middlewares) {
            try {
                const result = middleware(invocation.callbackId, args, options);
                
                if (result) {
                    if (result.args) args = result.args;
                    if (result.options) options = result.options;
                    if (result.cancel) {
                        // Annuler l'invocation
                        this._completeInvocation(invocation, null, new Error('Invocation annulée par middleware'));
                        return;
                    }
                }
            } catch (error) {
                this._debug(`Erreur dans middleware:`, error);
            }
        }
        
        // Invoquer le callback
        try {
            const promise = this.callbackRegistry.invoke(invocation.callbackId, args, options);
            
            // Gérer le résultat
            if (promise instanceof Promise) {
                promise.then(result => {
                    this._completeInvocation(invocation, result);
                }).catch(error => {
                    this._handleInvocationError(invocation, error);
                });
            } else {
                // Résultat synchrone
                this._completeInvocation(invocation, promise);
            }
        } catch (error) {
            this._handleInvocationError(invocation, error);
        }
    }

    /**
     * Gère une erreur d'invocation
     * @param {Object} invocation - Objet d'invocation
     * @param {Error} error - Erreur survenue
     * @private
     */
    _handleInvocationError(invocation, error) {
        // Vérifier si on doit réessayer
        if (invocation.options.retry) {
            // Incrémenter le compteur de tentatives
            const retryCount = this.retryCounters.get(invocation.id) || 0;
            
            if (retryCount < invocation.options.retryCount) {
                // Mettre à jour le compteur
                this.retryCounters.set(invocation.id, retryCount + 1);
                
                // Réessayer après un délai
                setTimeout(() => {
                    this._debug(`Nouvelle tentative (${retryCount + 1}/${invocation.options.retryCount}) pour l'invocation ${invocation.id}`);
                    
                    // Remettre en file d'attente
                    invocation.status = 'pending';
                    this._enqueueInvocation(invocation);
                    
                    // Traiter la file d'attente
                    this._processQueue();
                }, invocation.options.retryDelay);
                
                // Marquer comme inactive
                this.activeInvocations.delete(invocation.id);
                
                return;
            }
        }
        
        // Compléter avec erreur
        this._completeInvocation(invocation, null, error);
    }

    /**
     * Complète une invocation
     * @param {Object} invocation - Objet d'invocation
     * @param {*} result - Résultat de l'invocation
     * @param {Error} error - Erreur éventuelle
     * @private
     */
    _completeInvocation(invocation, result, error = null) {
        // Marquer comme inactive
        this.activeInvocations.delete(invocation.id);
        
        // Mettre à jour le statut
        invocation.status = error ? 'error' : 'completed';
        invocation.endTimestamp = Date.now();
        invocation.duration = invocation.endTimestamp - invocation.timestamp;
        
        // Stocker le résultat
        this.invocationResults.set(invocation.id, { result, error });
        
        // Résoudre ou rejeter la promesse
        if (error) {
            const rejecter = this.invocationRejecters.get(invocation.id);
            if (rejecter) {
                rejecter(error);
            }
            
            this._debug(`Invocation ${invocation.id} terminée avec erreur:`, error);
        } else {
            const resolver = this.invocationResolvers.get(invocation.id);
            if (resolver) {
                resolver(result);
            }
            
            this._debug(`Invocation ${invocation.id} terminée avec succès`);
        }
        
        // Nettoyer
        setTimeout(() => {
            this.invocationResolvers.delete(invocation.id);
            this.invocationRejecters.delete(invocation.id);
            this.invocationPromises.delete(invocation.id);
            this.invocationResults.delete(invocation.id);
            this.retryCounters.delete(invocation.id);
        }, 5000);
        
        // Traiter la file d'attente
        this._processQueue();
    }

    /**
     * Ajoute un middleware
     * @param {Function} middleware - Fonction middleware
     * @returns {number} - Index du middleware
     */
    addMiddleware(middleware) {
        if (typeof middleware !== 'function') {
            throw new Error('Le middleware doit être une fonction');
        }
        
        this.middlewares.push(middleware);
        return this.middlewares.length - 1;
    }

    /**
     * Supprime un middleware
     * @param {number} index - Index du middleware
     * @returns {boolean} - True si la suppression a réussi
     */
    removeMiddleware(index) {
        if (index >= 0 && index < this.middlewares.length) {
            this.middlewares.splice(index, 1);
            return true;
        }
        
        return false;
    }

    /**
     * Annule une invocation
     * @param {number} invocationId - ID de l'invocation
     * @returns {boolean} - True si l'annulation a réussi
     */
    cancelInvocation(invocationId) {
        // Vérifier si l'invocation est en file d'attente
        const queueIndex = this.invocationQueue.findIndex(inv => inv.id === invocationId);
        
        if (queueIndex !== -1) {
            // Supprimer de la file d'attente
            const invocation = this.invocationQueue.splice(queueIndex, 1)[0];
            
            // Rejeter la promesse
            const rejecter = this.invocationRejecters.get(invocationId);
            if (rejecter) {
                const error = new Error('Invocation annulée');
                error.code = 'INVOCATION_CANCELLED';
                rejecter(error);
            }
            
            // Nettoyer
            this.invocationResolvers.delete(invocationId);
            this.invocationRejecters.delete(invocationId);
            this.invocationPromises.delete(invocationId);
            
            this._debug(`Invocation ${invocationId} annulée`);
            
            return true;
        }
        
        // Si l'invocation est active, on ne peut pas l'annuler directement
        // mais on peut essayer de l'interrompre via le CallbackRegistry
        if (this.activeInvocations.has(invocationId)) {
            this._debug(`Tentative d'interruption de l'invocation active ${invocationId}`);
            // Cette fonctionnalité dépend de l'implémentation du CallbackRegistry
            return false;
        }
        
        return false;
    }

    /**
     * Obtient le statut d'une invocation
     * @param {number} invocationId - ID de l'invocation
     * @returns {Object} - Statut de l'invocation
     */
    getInvocationStatus(invocationId) {
        // Vérifier dans la file d'attente
        const queuedInvocation = this.invocationQueue.find(inv => inv.id === invocationId);
        if (queuedInvocation) {
            return {
                id: invocationId,
                status: 'queued',
                position: this.invocationQueue.indexOf(queuedInvocation),
                timestamp: queuedInvocation.timestamp,
                elapsed: Date.now() - queuedInvocation.timestamp
            };
        }
        
        // Vérifier si active
        if (this.activeInvocations.has(invocationId)) {
            return {
                id: invocationId,
                status: 'active',
                timestamp: Date.now(),
                elapsed: Date.now() - (this.invocationQueue.find(inv => inv.id === invocationId)?.timestamp || Date.now())
            };
        }
        
        // Vérifier si terminée
        const result = this.invocationResults.get(invocationId);
        if (result) {
            return {
                id: invocationId,
                status: result.error ? 'error' : 'completed',
                hasError: !!result.error,
                errorMessage: result.error ? result.error.message : null,
                timestamp: Date.now()
            };
        }
        
        return {
            id: invocationId,
            status: 'unknown'
        };
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
                console.log(`[InvocationManager] ${message}`, data);
            } else {
                console.log(`[InvocationManager] ${message}`);
            }
        }
    }

    /**
     * Nettoie les ressources utilisées par le gestionnaire
     */
    dispose() {
        // Annuler tous les timers de lot
        for (const timerId of this.batchTimers.values()) {
            clearTimeout(timerId);
        }
        
        // Rejeter toutes les promesses en attente
        for (const [id, rejecter] of this.invocationRejecters.entries()) {
            const error = new Error('Invocation annulée : gestionnaire nettoyé');
            error.code = 'MANAGER_DISPOSED';
            rejecter(error);
        }
        
        // Réinitialiser les variables
        this.invocationQueue = [];
        this.activeInvocations.clear();
        this.batchTimers.clear();
        this.retryCounters.clear();
        this.invocationResults.clear();
        this.invocationPromises.clear();
        this.invocationResolvers.clear();
        this.invocationRejecters.clear();
        this.middlewares = [];
        this.isProcessing = false;
        
        this._debug('InvocationManager nettoyé');
    }
}

// Exporter la classe pour utilisation dans d'autres modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        InvocationManager
    };
}
