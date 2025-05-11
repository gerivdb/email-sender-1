/**
 * hierarchical-diagram-synchronization.js
 * Module de synchronisation pour les diagrammes hiérarchiques
 * Version: 1.0
 * Date: 2025-05-15
 */

/**
 * Classe SynchronizationManager
 * Gère la synchronisation entre composants et instances du diagramme
 */
class SynchronizationManager {
    /**
     * Constructeur
     * @param {EventBus} eventBus - Bus d'événements
     * @param {MessageSystem} messageSystem - Système de messages
     * @param {Object} options - Options de configuration
     */
    constructor(eventBus, messageSystem, options = {}) {
        // Options par défaut
        this.options = Object.assign({
            debug: false,
            enableLocks: true,
            lockTimeout: 30000,
            transactionTimeout: 60000,
            conflictResolution: 'last-write-wins', // 'last-write-wins', 'first-write-wins', 'merge', 'manual'
            syncInterval: 5000,
            enableVersioning: true,
            maxVersions: 10,
            persistState: true,
            stateStorageKey: 'hierarchical-diagram-state',
            instanceId: this._generateInstanceId()
        }, options);

        // Références aux autres gestionnaires
        this.eventBus = eventBus;
        this.messageSystem = messageSystem;

        // État interne
        this.locks = new Map();
        this.pendingLocks = new Map();
        this.transactions = new Map();
        this.pendingTransactions = new Map();
        this.versionHistory = new Map();
        this.currentVersion = 0;
        this.syncTimer = null;
        this.lockTimers = new Map();
        this.transactionTimers = new Map();
        this.conflictQueue = [];
        this.isProcessingConflicts = false;
        this.stateCache = new Map();
        this.dirtyState = new Set();
        this.syncListeners = [];
        this.instanceRegistry = new Map();
        this.instanceRegistry.set(this.options.instanceId, {
            id: this.options.instanceId,
            timestamp: Date.now(),
            active: true,
            lastSeen: Date.now()
        });

        // Initialisation
        this._initialize();
    }

    /**
     * Initialise le gestionnaire de synchronisation
     * @private
     */
    _initialize() {
        // Enregistrer le composant dans le système de messages
        if (this.messageSystem) {
            this.messageSystem.registerComponent('sync-manager', this, {
                groups: ['synchronization'],
                messageHandler: this._handleMessage.bind(this),
                messageTypes: [
                    'lock-request', 'lock-release', 'lock-response',
                    'transaction-begin', 'transaction-commit', 'transaction-rollback', 'transaction-response',
                    'state-sync', 'state-update', 'version-update',
                    'instance-heartbeat', 'instance-register', 'instance-unregister'
                ]
            });

            // S'abonner au canal de synchronisation
            this.messageSystem.subscribeToChannel('sync-manager', 'synchronization');
        }

        // S'abonner aux événements pertinents
        if (this.eventBus) {
            this.eventBus.subscribe('state:change', this._handleStateChange.bind(this));
            this.eventBus.subscribe('diagram:load', this._handleDiagramLoad.bind(this));
            this.eventBus.subscribe('diagram:save', this._handleDiagramSave.bind(this));
        }

        // Démarrer le timer de synchronisation
        if (this.options.syncInterval > 0) {
            this.syncTimer = setInterval(() => this._synchronizeState(), this.options.syncInterval);
        }

        // Charger l'état persistant si activé
        if (this.options.persistState) {
            this._loadPersistedState();
        }

        // Envoyer un heartbeat pour signaler la présence de cette instance
        this._sendHeartbeat();
        
        // Démarrer le timer de heartbeat
        setInterval(() => this._sendHeartbeat(), 30000);

        this._debug('SynchronizationManager initialisé');
    }

    /**
     * Génère un ID d'instance unique
     * @returns {string} - ID d'instance
     * @private
     */
    _generateInstanceId() {
        return 'instance_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
    }

    /**
     * Envoie un heartbeat pour signaler la présence de cette instance
     * @private
     */
    _sendHeartbeat() {
        if (!this.messageSystem) return;

        this.messageSystem.broadcastToGroup('sync-manager', 'synchronization', 'instance-heartbeat', {
            instanceId: this.options.instanceId,
            timestamp: Date.now()
        });

        // Mettre à jour le registre local
        if (this.instanceRegistry.has(this.options.instanceId)) {
            const instance = this.instanceRegistry.get(this.options.instanceId);
            instance.lastSeen = Date.now();
            instance.active = true;
        }

        this._debug('Heartbeat envoyé');
    }

    /**
     * Gère un message reçu
     * @param {Object} message - Message reçu
     * @private
     */
    _handleMessage(message) {
        const { type, data } = message;

        // Ignorer les messages provenant de cette instance
        if (data.instanceId === this.options.instanceId) {
            return;
        }

        this._debug(`Message reçu: ${type}`, data);

        switch (type) {
            case 'lock-request':
                this._handleLockRequest(data);
                break;
            case 'lock-release':
                this._handleLockRelease(data);
                break;
            case 'lock-response':
                this._handleLockResponse(data);
                break;
            case 'transaction-begin':
                this._handleTransactionBegin(data);
                break;
            case 'transaction-commit':
                this._handleTransactionCommit(data);
                break;
            case 'transaction-rollback':
                this._handleTransactionRollback(data);
                break;
            case 'transaction-response':
                this._handleTransactionResponse(data);
                break;
            case 'state-sync':
                this._handleStateSync(data);
                break;
            case 'state-update':
                this._handleStateUpdate(data);
                break;
            case 'version-update':
                this._handleVersionUpdate(data);
                break;
            case 'instance-heartbeat':
                this._handleInstanceHeartbeat(data);
                break;
            case 'instance-register':
                this._handleInstanceRegister(data);
                break;
            case 'instance-unregister':
                this._handleInstanceUnregister(data);
                break;
        }
    }

    /**
     * Gère une demande de verrou
     * @param {Object} data - Données de la demande
     * @private
     */
    _handleLockRequest(data) {
        const { resourceId, instanceId, lockId, mode, timeout } = data;

        // Vérifier si le verrou est déjà détenu
        if (this.locks.has(resourceId)) {
            const existingLock = this.locks.get(resourceId);

            // Si le verrou est détenu par cette instance, le renouveler
            if (existingLock.instanceId === this.options.instanceId) {
                existingLock.timestamp = Date.now();
                existingLock.timeout = timeout || this.options.lockTimeout;

                // Réinitialiser le timer
                if (this.lockTimers.has(resourceId)) {
                    clearTimeout(this.lockTimers.get(resourceId));
                }

                this.lockTimers.set(resourceId, setTimeout(() => {
                    this._releaseLock(resourceId);
                }, existingLock.timeout));

                // Envoyer une réponse positive
                this._sendLockResponse(instanceId, lockId, resourceId, true);
                return;
            }

            // Sinon, envoyer une réponse négative
            this._sendLockResponse(instanceId, lockId, resourceId, false);
            return;
        }

        // Acquérir le verrou
        this.locks.set(resourceId, {
            instanceId,
            lockId,
            mode: mode || 'exclusive',
            timestamp: Date.now(),
            timeout: timeout || this.options.lockTimeout
        });

        // Configurer le timer d'expiration
        this.lockTimers.set(resourceId, setTimeout(() => {
            this._releaseLock(resourceId);
        }, timeout || this.options.lockTimeout));

        // Envoyer une réponse positive
        this._sendLockResponse(instanceId, lockId, resourceId, true);

        this._debug(`Verrou accordé pour la ressource ${resourceId} à l'instance ${instanceId}`);
    }

    /**
     * Envoie une réponse à une demande de verrou
     * @param {string} instanceId - ID de l'instance destinataire
     * @param {string} lockId - ID du verrou
     * @param {string} resourceId - ID de la ressource
     * @param {boolean} granted - Verrou accordé ou non
     * @private
     */
    _sendLockResponse(instanceId, lockId, resourceId, granted) {
        if (!this.messageSystem) return;

        this.messageSystem.sendMessage('sync-manager', instanceId, 'lock-response', {
            lockId,
            resourceId,
            granted,
            instanceId: this.options.instanceId,
            timestamp: Date.now()
        });
    }

    /**
     * Gère une libération de verrou
     * @param {Object} data - Données de la libération
     * @private
     */
    _handleLockRelease(data) {
        const { resourceId, instanceId, lockId } = data;

        // Vérifier si le verrou existe et est détenu par l'instance qui le libère
        if (this.locks.has(resourceId)) {
            const lock = this.locks.get(resourceId);
            if (lock.instanceId === instanceId && lock.lockId === lockId) {
                // Libérer le verrou
                this.locks.delete(resourceId);

                // Annuler le timer d'expiration
                if (this.lockTimers.has(resourceId)) {
                    clearTimeout(this.lockTimers.get(resourceId));
                    this.lockTimers.delete(resourceId);
                }

                this._debug(`Verrou libéré pour la ressource ${resourceId} par l'instance ${instanceId}`);

                // Traiter les demandes en attente
                this._processPendingLocks(resourceId);
            }
        }
    }

    /**
     * Gère une réponse à une demande de verrou
     * @param {Object} data - Données de la réponse
     * @private
     */
    _handleLockResponse(data) {
        const { lockId, resourceId, granted } = data;

        // Vérifier si la demande est en attente
        if (this.pendingLocks.has(lockId)) {
            const pendingLock = this.pendingLocks.get(lockId);

            // Résoudre la promesse
            if (granted) {
                pendingLock.resolve({
                    lockId,
                    resourceId,
                    granted: true,
                    timestamp: Date.now()
                });
            } else {
                pendingLock.reject(new Error(`Verrou refusé pour la ressource ${resourceId}`));
            }

            // Supprimer la demande en attente
            this.pendingLocks.delete(lockId);
        }
    }

    /**
     * Traite les demandes de verrou en attente
     * @param {string} resourceId - ID de la ressource
     * @private
     */
    _processPendingLocks(resourceId) {
        // Trouver les demandes en attente pour cette ressource
        const pendingLocks = Array.from(this.pendingLocks.values())
            .filter(lock => lock.resourceId === resourceId)
            .sort((a, b) => a.timestamp - b.timestamp);

        if (pendingLocks.length === 0) {
            return;
        }

        // Traiter la première demande
        const nextLock = pendingLocks[0];
        this._handleLockRequest({
            resourceId: nextLock.resourceId,
            instanceId: nextLock.instanceId,
            lockId: nextLock.lockId,
            mode: nextLock.mode,
            timeout: nextLock.timeout
        });
    }

    /**
     * Acquiert un verrou sur une ressource
     * @param {string} resourceId - ID de la ressource
     * @param {Object} options - Options du verrou
     * @returns {Promise} - Promise résolue avec les informations du verrou
     */
    acquireLock(resourceId, options = {}) {
        if (!this.options.enableLocks) {
            return Promise.resolve({
                lockId: 'dummy-lock',
                resourceId,
                granted: true,
                timestamp: Date.now()
            });
        }

        // Options par défaut
        const lockOptions = Object.assign({
            mode: 'exclusive', // 'exclusive', 'shared'
            timeout: this.options.lockTimeout,
            retryCount: 3,
            retryDelay: 1000
        }, options);

        // Générer un ID de verrou unique
        const lockId = `lock_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

        // Vérifier si le verrou est déjà détenu localement
        if (this.locks.has(resourceId)) {
            const existingLock = this.locks.get(resourceId);
            if (existingLock.instanceId === this.options.instanceId) {
                // Renouveler le verrou
                existingLock.timestamp = Date.now();
                existingLock.timeout = lockOptions.timeout;

                // Réinitialiser le timer
                if (this.lockTimers.has(resourceId)) {
                    clearTimeout(this.lockTimers.get(resourceId));
                }

                this.lockTimers.set(resourceId, setTimeout(() => {
                    this._releaseLock(resourceId);
                }, existingLock.timeout));

                return Promise.resolve({
                    lockId: existingLock.lockId,
                    resourceId,
                    granted: true,
                    timestamp: Date.now()
                });
            }
        }

        // Créer une promesse pour cette demande
        return new Promise((resolve, reject) => {
            // Stocker la demande
            this.pendingLocks.set(lockId, {
                lockId,
                resourceId,
                instanceId: this.options.instanceId,
                mode: lockOptions.mode,
                timeout: lockOptions.timeout,
                timestamp: Date.now(),
                resolve,
                reject,
                retryCount: lockOptions.retryCount,
                retryDelay: lockOptions.retryDelay
            });

            // Envoyer la demande
            if (this.messageSystem) {
                this.messageSystem.broadcastToGroup('sync-manager', 'synchronization', 'lock-request', {
                    lockId,
                    resourceId,
                    instanceId: this.options.instanceId,
                    mode: lockOptions.mode,
                    timeout: lockOptions.timeout,
                    timestamp: Date.now()
                });
            } else {
                // Si pas de système de messages, acquérir le verrou localement
                this._handleLockRequest({
                    resourceId,
                    instanceId: this.options.instanceId,
                    lockId,
                    mode: lockOptions.mode,
                    timeout: lockOptions.timeout
                });
            }

            // Configurer un timeout pour la demande
            setTimeout(() => {
                if (this.pendingLocks.has(lockId)) {
                    const pendingLock = this.pendingLocks.get(lockId);
                    
                    // Si des tentatives restent, réessayer
                    if (pendingLock.retryCount > 0) {
                        pendingLock.retryCount--;
                        
                        setTimeout(() => {
                            // Envoyer une nouvelle demande
                            if (this.messageSystem) {
                                this.messageSystem.broadcastToGroup('sync-manager', 'synchronization', 'lock-request', {
                                    lockId,
                                    resourceId,
                                    instanceId: this.options.instanceId,
                                    mode: lockOptions.mode,
                                    timeout: lockOptions.timeout,
                                    timestamp: Date.now()
                                });
                            } else {
                                this._handleLockRequest({
                                    resourceId,
                                    instanceId: this.options.instanceId,
                                    lockId,
                                    mode: lockOptions.mode,
                                    timeout: lockOptions.timeout
                                });
                            }
                        }, pendingLock.retryDelay);
                    } else {
                        // Sinon, rejeter la promesse
                        pendingLock.reject(new Error(`Timeout lors de l'acquisition du verrou pour la ressource ${resourceId}`));
                        this.pendingLocks.delete(lockId);
                    }
                }
            }, lockOptions.timeout);
        });
    }

    /**
     * Libère un verrou
     * @param {string} resourceId - ID de la ressource
     * @param {string} lockId - ID du verrou (optionnel)
     * @returns {boolean} - True si le verrou a été libéré
     */
    releaseLock(resourceId, lockId = null) {
        if (!this.options.enableLocks) {
            return true;
        }

        // Vérifier si le verrou existe
        if (!this.locks.has(resourceId)) {
            return false;
        }

        const lock = this.locks.get(resourceId);

        // Vérifier si le verrou est détenu par cette instance
        if (lock.instanceId !== this.options.instanceId) {
            return false;
        }

        // Vérifier l'ID du verrou si spécifié
        if (lockId && lock.lockId !== lockId) {
            return false;
        }

        // Libérer le verrou
        return this._releaseLock(resourceId, lock.lockId);
    }

    /**
     * Libère un verrou (interne)
     * @param {string} resourceId - ID de la ressource
     * @param {string} lockId - ID du verrou
     * @returns {boolean} - True si le verrou a été libéré
     * @private
     */
    _releaseLock(resourceId, lockId = null) {
        // Vérifier si le verrou existe
        if (!this.locks.has(resourceId)) {
            return false;
        }

        const lock = this.locks.get(resourceId);
        
        // Si l'ID du verrou est spécifié, vérifier qu'il correspond
        if (lockId && lock.lockId !== lockId) {
            return false;
        }

        // Supprimer le verrou
        this.locks.delete(resourceId);

        // Annuler le timer d'expiration
        if (this.lockTimers.has(resourceId)) {
            clearTimeout(this.lockTimers.get(resourceId));
            this.lockTimers.delete(resourceId);
        }

        // Notifier les autres instances
        if (this.messageSystem) {
            this.messageSystem.broadcastToGroup('sync-manager', 'synchronization', 'lock-release', {
                lockId: lock.lockId,
                resourceId,
                instanceId: this.options.instanceId,
                timestamp: Date.now()
            });
        }

        this._debug(`Verrou libéré pour la ressource ${resourceId}`);

        // Traiter les demandes en attente
        this._processPendingLocks(resourceId);

        return true;
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
                console.log(`[SynchronizationManager] ${message}`, data);
            } else {
                console.log(`[SynchronizationManager] ${message}`);
            }
        }
    }

    /**
     * Nettoie les ressources utilisées par le gestionnaire
     */
    dispose() {
        // Annuler tous les timers
        clearInterval(this.syncTimer);
        
        for (const timerId of this.lockTimers.values()) {
            clearTimeout(timerId);
        }
        
        for (const timerId of this.transactionTimers.values()) {
            clearTimeout(timerId);
        }

        // Libérer tous les verrous détenus par cette instance
        for (const [resourceId, lock] of this.locks.entries()) {
            if (lock.instanceId === this.options.instanceId) {
                this._releaseLock(resourceId);
            }
        }

        // Annuler toutes les transactions en cours
        for (const [transactionId, transaction] of this.transactions.entries()) {
            if (transaction.instanceId === this.options.instanceId) {
                this._rollbackTransaction(transactionId);
            }
        }

        // Se désenregistrer du système de messages
        if (this.messageSystem) {
            this.messageSystem.unregisterComponent('sync-manager');
        }

        // Notifier les autres instances
        if (this.messageSystem) {
            this.messageSystem.broadcastToGroup('sync-manager', 'synchronization', 'instance-unregister', {
                instanceId: this.options.instanceId,
                timestamp: Date.now()
            });
        }

        this._debug('SynchronizationManager nettoyé');
    }
}

// Exporter la classe pour utilisation dans d'autres modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        SynchronizationManager
    };
}
