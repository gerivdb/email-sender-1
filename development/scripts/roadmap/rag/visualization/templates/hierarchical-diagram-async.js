/**
 * hierarchical-diagram-async.js
 * Module de gestion des callbacks asynchrones pour les diagrammes hiérarchiques
 * Version: 1.0
 * Date: 2025-05-15
 */

/**
 * Classe AsyncCallbackManager
 * Gère les callbacks asynchrones pour les diagrammes hiérarchiques
 */
class AsyncCallbackManager {
    /**
     * Constructeur
     * @param {CallbackRegistry} callbackRegistry - Registre de callbacks
     * @param {ErrorHandler} errorHandler - Gestionnaire d'erreurs
     * @param {Object} options - Options de configuration
     */
    constructor(callbackRegistry, errorHandler, options = {}) {
        // Options par défaut
        this.options = Object.assign({
            debug: false,
            maxConcurrent: 10,
            defaultTimeout: 30000,
            retryCount: 3,
            retryDelay: 1000,
            useWorkers: true,
            maxWorkers: navigator.hardwareConcurrency || 4,
            priorityLevels: 3
        }, options);

        // Références aux autres gestionnaires
        this.callbackRegistry = callbackRegistry;
        this.errorHandler = errorHandler;

        // État interne
        this.pendingCallbacks = new Map();
        this.activeCallbacks = new Set();
        this.callbackPromises = new Map();
        this.callbackResolvers = new Map();
        this.callbackRejecters = new Map();
        this.callbackTimeouts = new Map();
        this.callbackResults = new Map();
        this.callbackCounter = 0;
        this.workers = [];
        this.workerPool = [];
        this.workerTasks = new Map();
        this.priorityQueues = new Map();

        // Initialisation
        this._initialize();
    }

    /**
     * Initialise le gestionnaire
     * @private
     */
    _initialize() {
        // Initialiser les files d'attente par priorité
        for (let i = 0; i < this.options.priorityLevels; i++) {
            this.priorityQueues.set(i, []);
        }

        // Initialiser les workers si activés
        if (this.options.useWorkers) {
            this._initializeWorkers();
        }

        this._debug('AsyncCallbackManager initialisé');
    }

    /**
     * Initialise les workers
     * @private
     */
    _initializeWorkers() {
        // Vérifier si les Web Workers sont supportés
        if (typeof Worker === 'undefined') {
            this._debug('Web Workers non supportés, désactivation');
            this.options.useWorkers = false;
            return;
        }

        // Créer les workers
        const workerCount = Math.min(this.options.maxWorkers, navigator.hardwareConcurrency || 4);
        
        for (let i = 0; i < workerCount; i++) {
            try {
                // Créer un worker inline
                const workerScript = `
                    self.onmessage = function(e) {
                        const { id, fn, args } = e.data;
                        
                        try {
                            // Exécuter la fonction
                            const fnBody = new Function('return ' + fn)();
                            const result = fnBody.apply(null, args);
                            
                            // Si c'est une promesse
                            if (result && typeof result.then === 'function') {
                                result.then(
                                    value => self.postMessage({ id, result: value, success: true }),
                                    error => self.postMessage({ 
                                        id, 
                                        error: { 
                                            message: error.message, 
                                            stack: error.stack,
                                            code: error.code
                                        }, 
                                        success: false 
                                    })
                                );
                            } else {
                                // Résultat synchrone
                                self.postMessage({ id, result, success: true });
                            }
                        } catch (error) {
                            self.postMessage({ 
                                id, 
                                error: { 
                                    message: error.message, 
                                    stack: error.stack,
                                    code: error.code
                                }, 
                                success: false 
                            });
                        }
                    };
                `;
                
                const blob = new Blob([workerScript], { type: 'application/javascript' });
                const worker = new Worker(URL.createObjectURL(blob));
                
                // Configurer le gestionnaire de messages
                worker.onmessage = (e) => this._handleWorkerMessage(worker, e);
                worker.onerror = (e) => this._handleWorkerError(worker, e);
                
                // Ajouter au pool
                this.workers.push(worker);
                this.workerPool.push(worker);
                
                this._debug(`Worker ${i + 1}/${workerCount} créé`);
            } catch (error) {
                console.error('Erreur lors de la création du worker:', error);
                
                // Désactiver les workers en cas d'erreur
                if (this.workers.length === 0) {
                    this.options.useWorkers = false;
                    break;
                }
            }
        }
    }

    /**
     * Gère un message d'un worker
     * @param {Worker} worker - Worker ayant envoyé le message
     * @param {MessageEvent} event - Événement de message
     * @private
     */
    _handleWorkerMessage(worker, event) {
        const { id, result, error, success } = event.data;
        
        // Récupérer la tâche
        const task = this.workerTasks.get(id);
        if (!task) {
            this._debug(`Tâche ${id} non trouvée pour le message du worker`);
            return;
        }
        
        // Traiter le résultat
        if (success) {
            task.resolve(result);
        } else {
            // Recréer l'erreur
            const reconstructedError = new Error(error.message);
            reconstructedError.stack = error.stack;
            reconstructedError.code = error.code;
            
            task.reject(reconstructedError);
        }
        
        // Nettoyer
        this.workerTasks.delete(id);
        
        // Remettre le worker dans le pool
        this.workerPool.push(worker);
        
        // Traiter la file d'attente
        this._processQueue();
    }

    /**
     * Gère une erreur d'un worker
     * @param {Worker} worker - Worker ayant généré l'erreur
     * @param {ErrorEvent} event - Événement d'erreur
     * @private
     */
    _handleWorkerError(worker, event) {
        this._debug(`Erreur dans le worker:`, event);
        
        // Trouver les tâches associées à ce worker
        for (const [id, task] of this.workerTasks.entries()) {
            if (task.worker === worker) {
                // Rejeter la tâche
                const error = new Error('Erreur dans le worker: ' + (event.message || 'Erreur inconnue'));
                error.code = 'WORKER_ERROR';
                task.reject(error);
                
                // Nettoyer
                this.workerTasks.delete(id);
            }
        }
        
        // Remplacer le worker
        const index = this.workers.indexOf(worker);
        if (index !== -1) {
            this.workers.splice(index, 1);
            
            // Créer un nouveau worker
            try {
                this._initializeWorkers();
            } catch (error) {
                console.error('Erreur lors de la recréation du worker:', error);
            }
        }
    }

    /**
     * Exécute une fonction dans un worker
     * @param {Function} fn - Fonction à exécuter
     * @param {Array} args - Arguments à passer à la fonction
     * @returns {Promise} - Promise résolue avec le résultat
     * @private
     */
    _executeInWorker(fn, args) {
        return new Promise((resolve, reject) => {
            // Vérifier si des workers sont disponibles
            if (this.workerPool.length === 0) {
                // Exécuter localement si aucun worker n'est disponible
                this._debug('Aucun worker disponible, exécution locale');
                try {
                    const result = fn.apply(null, args);
                    resolve(result);
                } catch (error) {
                    reject(error);
                }
                return;
            }
            
            // Récupérer un worker du pool
            const worker = this.workerPool.pop();
            
            // Générer un ID de tâche
            const taskId = Date.now() + '_' + Math.random().toString(36).substr(2, 9);
            
            // Stocker la tâche
            this.workerTasks.set(taskId, {
                worker,
                resolve,
                reject
            });
            
            // Convertir la fonction en chaîne
            let fnString;
            if (typeof fn === 'function') {
                fnString = fn.toString();
                
                // Vérifier si c'est une fonction fléchée sans accolades
                if (fnString.includes('=>') && !fnString.includes('{')) {
                    fnString = fnString.replace(/=>(.*)/, '=> { return $1; }');
                }
            } else {
                reject(new Error('La fonction doit être une fonction'));
                return;
            }
            
            // Envoyer la tâche au worker
            worker.postMessage({
                id: taskId,
                fn: fnString,
                args
            });
        });
    }

    /**
     * Exécute un callback de manière asynchrone
     * @param {number|string} idOrName - ID ou nom du callback
     * @param {Array} args - Arguments à passer au callback
     * @param {Object} options - Options d'exécution
     * @returns {Promise} - Promise résolue avec le résultat
     */
    executeAsync(idOrName, args = [], options = {}) {
        // Options par défaut
        const execOptions = Object.assign({
            timeout: this.options.defaultTimeout,
            priority: 1,
            retry: false,
            retryCount: this.options.retryCount,
            retryDelay: this.options.retryDelay,
            useWorker: this.options.useWorkers,
            context: null
        }, options);

        // Générer un ID d'exécution unique
        const execId = ++this.callbackCounter;

        // Créer une promesse pour cette exécution
        const promise = new Promise((resolve, reject) => {
            this.callbackResolvers.set(execId, resolve);
            this.callbackRejecters.set(execId, reject);
        });

        // Stocker la promesse
        this.callbackPromises.set(execId, promise);

        // Créer l'objet d'exécution
        const execution = {
            id: execId,
            callbackId: idOrName,
            args,
            options: execOptions,
            timestamp: Date.now(),
            status: 'pending',
            attempts: 0
        };

        // Ajouter à la file d'attente par priorité
        const priority = Math.min(Math.max(0, execOptions.priority), this.options.priorityLevels - 1);
        this.priorityQueues.get(priority).push(execution);

        // Configurer le timeout
        if (execOptions.timeout > 0) {
            const timeoutId = setTimeout(() => {
                // Vérifier si l'exécution est toujours en attente
                if (this.pendingCallbacks.has(execId) || this.activeCallbacks.has(execId)) {
                    // Créer l'erreur de timeout
                    const error = new Error(`Timeout de ${execOptions.timeout}ms dépassé pour le callback`);
                    error.code = 'CALLBACK_TIMEOUT';
                    
                    // Rejeter la promesse
                    this._rejectCallback(execId, error);
                    
                    // Gérer l'erreur
                    this.errorHandler.handleError(error, {
                        source: 'async_callback',
                        operation: 'execute',
                        callbackId: idOrName,
                        execId
                    });
                }
            }, execOptions.timeout);
            
            // Stocker l'ID du timeout
            this.callbackTimeouts.set(execId, timeoutId);
        }

        // Stocker dans les callbacks en attente
        this.pendingCallbacks.set(execId, execution);

        // Traiter la file d'attente
        this._processQueue();

        return promise;
    }

    /**
     * Traite la file d'attente des callbacks
     * @private
     */
    _processQueue() {
        // Vérifier si on peut exécuter plus de callbacks
        if (this.activeCallbacks.size >= this.options.maxConcurrent) {
            return;
        }

        // Parcourir les files d'attente par priorité
        for (let priority = 0; priority < this.options.priorityLevels; priority++) {
            const queue = this.priorityQueues.get(priority);
            
            if (queue.length > 0) {
                // Récupérer le prochain callback
                const execution = queue.shift();
                
                // Retirer des callbacks en attente
                this.pendingCallbacks.delete(execution.id);
                
                // Ajouter aux callbacks actifs
                this.activeCallbacks.add(execution.id);
                
                // Mettre à jour le statut
                execution.status = 'active';
                execution.startTimestamp = Date.now();
                execution.attempts++;
                
                // Exécuter le callback
                this._executeCallback(execution);
                
                // Sortir si on a atteint le maximum
                if (this.activeCallbacks.size >= this.options.maxConcurrent) {
                    break;
                }
            }
        }
    }

    /**
     * Exécute un callback
     * @param {Object} execution - Objet d'exécution
     * @private
     */
    _executeCallback(execution) {
        this._debug(`Exécution du callback ${execution.id} (tentative ${execution.attempts}/${execution.options.retryCount + 1})`);
        
        // Récupérer le callback
        this.callbackRegistry.invoke(execution.callbackId, execution.args, {
            context: execution.options.context,
            async: true
        }).then(result => {
            // Exécuter dans un worker si nécessaire
            if (execution.options.useWorker && typeof result === 'function') {
                return this._executeInWorker(result, execution.args);
            }
            
            return result;
        }).then(result => {
            // Résoudre la promesse
            this._resolveCallback(execution.id, result);
        }).catch(error => {
            // Gérer l'erreur
            this._handleCallbackError(execution, error);
        });
    }

    /**
     * Gère une erreur de callback
     * @param {Object} execution - Objet d'exécution
     * @param {Error} error - Erreur survenue
     * @private
     */
    _handleCallbackError(execution, error) {
        this._debug(`Erreur dans le callback ${execution.id}:`, error);
        
        // Vérifier si on doit réessayer
        if (execution.options.retry && execution.attempts <= execution.options.retryCount) {
            this._debug(`Nouvelle tentative ${execution.attempts}/${execution.options.retryCount} pour le callback ${execution.id}`);
            
            // Remettre en file d'attente après un délai
            setTimeout(() => {
                // Vérifier si l'exécution n'a pas été annulée entre-temps
                if (this.activeCallbacks.has(execution.id)) {
                    // Retirer des callbacks actifs
                    this.activeCallbacks.delete(execution.id);
                    
                    // Remettre en file d'attente
                    const priority = Math.min(Math.max(0, execution.options.priority), this.options.priorityLevels - 1);
                    this.priorityQueues.get(priority).push(execution);
                    
                    // Traiter la file d'attente
                    this._processQueue();
                }
            }, execution.options.retryDelay);
            
            return;
        }
        
        // Gérer l'erreur avec le gestionnaire d'erreurs
        this.errorHandler.handleError(error, {
            source: 'async_callback',
            operation: 'execute',
            callbackId: execution.callbackId,
            execId: execution.id,
            attempts: execution.attempts
        });
        
        // Rejeter la promesse
        this._rejectCallback(execution.id, error);
    }

    /**
     * Résout un callback
     * @param {number} execId - ID d'exécution
     * @param {*} result - Résultat du callback
     * @private
     */
    _resolveCallback(execId, result) {
        // Annuler le timeout
        if (this.callbackTimeouts.has(execId)) {
            clearTimeout(this.callbackTimeouts.get(execId));
            this.callbackTimeouts.delete(execId);
        }
        
        // Retirer des callbacks actifs
        this.activeCallbacks.delete(execId);
        
        // Stocker le résultat
        this.callbackResults.set(execId, {
            result,
            timestamp: Date.now(),
            success: true
        });
        
        // Résoudre la promesse
        const resolver = this.callbackResolvers.get(execId);
        if (resolver) {
            resolver(result);
        }
        
        // Nettoyer
        setTimeout(() => {
            this.callbackResolvers.delete(execId);
            this.callbackRejecters.delete(execId);
            this.callbackPromises.delete(execId);
            this.callbackResults.delete(execId);
        }, 5000);
        
        // Traiter la file d'attente
        this._processQueue();
    }

    /**
     * Rejette un callback
     * @param {number} execId - ID d'exécution
     * @param {Error} error - Erreur survenue
     * @private
     */
    _rejectCallback(execId, error) {
        // Annuler le timeout
        if (this.callbackTimeouts.has(execId)) {
            clearTimeout(this.callbackTimeouts.get(execId));
            this.callbackTimeouts.delete(execId);
        }
        
        // Retirer des callbacks actifs et en attente
        this.activeCallbacks.delete(execId);
        this.pendingCallbacks.delete(execId);
        
        // Stocker le résultat
        this.callbackResults.set(execId, {
            error,
            timestamp: Date.now(),
            success: false
        });
        
        // Rejeter la promesse
        const rejecter = this.callbackRejecters.get(execId);
        if (rejecter) {
            rejecter(error);
        }
        
        // Nettoyer
        setTimeout(() => {
            this.callbackResolvers.delete(execId);
            this.callbackRejecters.delete(execId);
            this.callbackPromises.delete(execId);
            this.callbackResults.delete(execId);
        }, 5000);
        
        // Traiter la file d'attente
        this._processQueue();
    }

    /**
     * Annule l'exécution d'un callback
     * @param {number} execId - ID d'exécution
     * @returns {boolean} - True si l'annulation a réussi
     */
    cancelExecution(execId) {
        // Vérifier si le callback est en attente
        if (this.pendingCallbacks.has(execId)) {
            const execution = this.pendingCallbacks.get(execId);
            
            // Retirer de la file d'attente par priorité
            const priority = Math.min(Math.max(0, execution.options.priority), this.options.priorityLevels - 1);
            const queue = this.priorityQueues.get(priority);
            const index = queue.findIndex(exec => exec.id === execId);
            
            if (index !== -1) {
                queue.splice(index, 1);
            }
            
            // Retirer des callbacks en attente
            this.pendingCallbacks.delete(execId);
            
            // Rejeter la promesse
            const error = new Error('Exécution annulée');
            error.code = 'EXECUTION_CANCELLED';
            this._rejectCallback(execId, error);
            
            return true;
        }
        
        // Si le callback est actif, on ne peut pas l'annuler directement
        // mais on peut essayer de l'interrompre via le worker
        if (this.activeCallbacks.has(execId)) {
            this._debug(`Tentative d'interruption de l'exécution active ${execId}`);
            
            // Cette fonctionnalité dépend de l'implémentation des workers
            return false;
        }
        
        return false;
    }

    /**
     * Obtient le statut d'une exécution
     * @param {number} execId - ID d'exécution
     * @returns {Object} - Statut de l'exécution
     */
    getExecutionStatus(execId) {
        // Vérifier si le callback est en attente
        if (this.pendingCallbacks.has(execId)) {
            const execution = this.pendingCallbacks.get(execId);
            
            return {
                id: execId,
                status: 'pending',
                timestamp: execution.timestamp,
                elapsed: Date.now() - execution.timestamp,
                attempts: execution.attempts
            };
        }
        
        // Vérifier si le callback est actif
        if (this.activeCallbacks.has(execId)) {
            return {
                id: execId,
                status: 'active',
                timestamp: Date.now(),
                elapsed: Date.now() - (this.pendingCallbacks.get(execId)?.startTimestamp || Date.now())
            };
        }
        
        // Vérifier si le callback a un résultat
        if (this.callbackResults.has(execId)) {
            const result = this.callbackResults.get(execId);
            
            return {
                id: execId,
                status: result.success ? 'completed' : 'error',
                timestamp: result.timestamp,
                hasError: !result.success,
                errorMessage: result.error ? result.error.message : null
            };
        }
        
        return {
            id: execId,
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
                console.log(`[AsyncCallbackManager] ${message}`, data);
            } else {
                console.log(`[AsyncCallbackManager] ${message}`);
            }
        }
    }

    /**
     * Nettoie les ressources utilisées par le gestionnaire
     */
    dispose() {
        // Annuler tous les timeouts
        for (const timeoutId of this.callbackTimeouts.values()) {
            clearTimeout(timeoutId);
        }
        
        // Terminer tous les workers
        for (const worker of this.workers) {
            worker.terminate();
        }
        
        // Rejeter toutes les promesses en attente
        for (const [execId, rejecter] of this.callbackRejecters.entries()) {
            const error = new Error('Exécution annulée : gestionnaire nettoyé');
            error.code = 'MANAGER_DISPOSED';
            rejecter(error);
        }
        
        // Réinitialiser les variables
        this.pendingCallbacks.clear();
        this.activeCallbacks.clear();
        this.callbackPromises.clear();
        this.callbackResolvers.clear();
        this.callbackRejecters.clear();
        this.callbackTimeouts.clear();
        this.callbackResults.clear();
        this.workers = [];
        this.workerPool = [];
        this.workerTasks.clear();
        
        // Vider les files d'attente
        for (const queue of this.priorityQueues.values()) {
            queue.length = 0;
        }
        
        this._debug('AsyncCallbackManager nettoyé');
    }
}

// Exporter la classe pour utilisation dans d'autres modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        AsyncCallbackManager
    };
}
