/**
 * hierarchical-diagram-error-handling.js
 * Module de gestion des erreurs et timeouts pour les diagrammes hiérarchiques
 * Version: 1.0
 * Date: 2025-05-15
 */

/**
 * Classe ErrorHandler
 * Gère les erreurs et timeouts pour les callbacks et invocations
 */
class ErrorHandler {
    /**
     * Constructeur
     * @param {Object} options - Options de configuration
     * @param {boolean} options.debug - Activer le mode debug
     * @param {boolean} options.logErrors - Journaliser les erreurs
     * @param {number} options.maxErrorsStored - Nombre maximum d'erreurs stockées
     */
    constructor(options = {}) {
        // Options par défaut
        this.options = Object.assign({
            debug: false,
            logErrors: true,
            maxErrorsStored: 100,
            notifyErrors: true,
            groupSimilarErrors: true,
            errorRetention: 24 * 60 * 60 * 1000, // 24 heures
            errorThreshold: 10,
            errorThresholdPeriod: 60 * 1000, // 1 minute
            errorRecoveryStrategies: {}
        }, options);

        // État interne
        this.errors = [];
        this.errorGroups = new Map();
        this.errorCounts = new Map();
        this.errorListeners = [];
        this.recoveryStrategies = new Map();
        this.activeRecoveries = new Set();
        this.circuitBreakers = new Map();
    }

    /**
     * Gère une erreur
     * @param {Error} error - Erreur survenue
     * @param {Object} context - Contexte de l'erreur
     * @returns {Object} - Informations sur la gestion de l'erreur
     */
    handleError(error, context = {}) {
        // Créer l'objet d'erreur
        const errorObj = {
            error,
            message: error.message,
            stack: error.stack,
            code: error.code,
            timestamp: Date.now(),
            context: { ...context },
            handled: false,
            recovery: null
        };
        
        // Journaliser l'erreur
        if (this.options.logErrors) {
            this._logError(errorObj);
        }
        
        // Stocker l'erreur
        this._storeError(errorObj);
        
        // Vérifier le circuit breaker
        if (context.source) {
            this._updateCircuitBreaker(context.source, errorObj);
        }
        
        // Appliquer une stratégie de récupération
        const recovery = this._applyRecoveryStrategy(errorObj);
        if (recovery) {
            errorObj.recovery = recovery;
            errorObj.handled = true;
        }
        
        // Notifier les écouteurs
        if (this.options.notifyErrors) {
            this._notifyErrorListeners(errorObj);
        }
        
        return {
            handled: errorObj.handled,
            recovery: errorObj.recovery,
            id: errorObj.id
        };
    }

    /**
     * Journalise une erreur
     * @param {Object} errorObj - Objet d'erreur
     * @private
     */
    _logError(errorObj) {
        const { error, context } = errorObj;
        
        // Formater le message
        let message = `[ErrorHandler] Erreur`;
        
        if (context.source) {
            message += ` dans ${context.source}`;
        }
        
        if (context.operation) {
            message += ` pendant ${context.operation}`;
        }
        
        console.error(message, error);
        
        if (context.data) {
            console.error('Données associées:', context.data);
        }
    }

    /**
     * Stocke une erreur
     * @param {Object} errorObj - Objet d'erreur
     * @private
     */
    _storeError(errorObj) {
        // Générer un ID unique
        errorObj.id = `error_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
        
        // Ajouter à la liste des erreurs
        this.errors.push(errorObj);
        
        // Limiter le nombre d'erreurs stockées
        if (this.errors.length > this.options.maxErrorsStored) {
            this.errors.shift();
        }
        
        // Grouper les erreurs similaires si activé
        if (this.options.groupSimilarErrors) {
            this._groupError(errorObj);
        }
        
        // Mettre à jour les compteurs d'erreurs
        this._updateErrorCounts(errorObj);
    }

    /**
     * Groupe les erreurs similaires
     * @param {Object} errorObj - Objet d'erreur
     * @private
     */
    _groupError(errorObj) {
        // Créer une clé de groupe basée sur le message et le code
        const groupKey = `${errorObj.code || 'unknown'}_${errorObj.message}`;
        
        // Récupérer ou créer le groupe
        if (!this.errorGroups.has(groupKey)) {
            this.errorGroups.set(groupKey, {
                code: errorObj.code,
                message: errorObj.message,
                count: 0,
                firstSeen: errorObj.timestamp,
                lastSeen: errorObj.timestamp,
                occurrences: []
            });
        }
        
        const group = this.errorGroups.get(groupKey);
        
        // Mettre à jour le groupe
        group.count++;
        group.lastSeen = errorObj.timestamp;
        
        // Ajouter l'occurrence
        group.occurrences.push({
            id: errorObj.id,
            timestamp: errorObj.timestamp,
            context: errorObj.context
        });
        
        // Limiter le nombre d'occurrences stockées
        if (group.occurrences.length > 10) {
            group.occurrences.shift();
        }
    }

    /**
     * Met à jour les compteurs d'erreurs
     * @param {Object} errorObj - Objet d'erreur
     * @private
     */
    _updateErrorCounts(errorObj) {
        const { context } = errorObj;
        
        // Créer une clé basée sur la source
        const countKey = context.source || 'global';
        
        // Récupérer ou créer le compteur
        if (!this.errorCounts.has(countKey)) {
            this.errorCounts.set(countKey, []);
        }
        
        const counts = this.errorCounts.get(countKey);
        
        // Ajouter le timestamp
        counts.push(errorObj.timestamp);
        
        // Supprimer les timestamps trop anciens
        const threshold = Date.now() - this.options.errorThresholdPeriod;
        while (counts.length > 0 && counts[0] < threshold) {
            counts.shift();
        }
    }

    /**
     * Met à jour l'état du circuit breaker
     * @param {string} source - Source de l'erreur
     * @param {Object} errorObj - Objet d'erreur
     * @private
     */
    _updateCircuitBreaker(source, errorObj) {
        // Récupérer ou créer le circuit breaker
        if (!this.circuitBreakers.has(source)) {
            this.circuitBreakers.set(source, {
                state: 'closed', // closed, open, half-open
                failureCount: 0,
                lastFailure: 0,
                openTimestamp: 0,
                resetTimeout: null
            });
        }
        
        const breaker = this.circuitBreakers.get(source);
        
        // Mettre à jour selon l'état actuel
        switch (breaker.state) {
            case 'closed':
                // Incrémenter le compteur d'échecs
                breaker.failureCount++;
                breaker.lastFailure = errorObj.timestamp;
                
                // Vérifier si on doit ouvrir le circuit
                if (breaker.failureCount >= this.options.errorThreshold) {
                    this._openCircuitBreaker(source, breaker);
                }
                break;
                
            case 'half-open':
                // En cas d'échec en half-open, rouvrir le circuit
                this._openCircuitBreaker(source, breaker);
                break;
        }
    }

    /**
     * Ouvre un circuit breaker
     * @param {string} source - Source de l'erreur
     * @param {Object} breaker - État du circuit breaker
     * @private
     */
    _openCircuitBreaker(source, breaker) {
        // Annuler le timeout existant
        if (breaker.resetTimeout) {
            clearTimeout(breaker.resetTimeout);
        }
        
        // Ouvrir le circuit
        breaker.state = 'open';
        breaker.openTimestamp = Date.now();
        
        this._debug(`Circuit breaker ouvert pour ${source}`);
        
        // Planifier la réinitialisation
        breaker.resetTimeout = setTimeout(() => {
            // Passer en half-open
            breaker.state = 'half-open';
            breaker.failureCount = 0;
            
            this._debug(`Circuit breaker en half-open pour ${source}`);
        }, 30000); // 30 secondes
    }

    /**
     * Signale un succès au circuit breaker
     * @param {string} source - Source de l'opération
     * @returns {boolean} - True si le circuit est fermé
     */
    reportSuccess(source) {
        if (!this.circuitBreakers.has(source)) {
            return true;
        }
        
        const breaker = this.circuitBreakers.get(source);
        
        // Si en half-open, fermer le circuit
        if (breaker.state === 'half-open') {
            breaker.state = 'closed';
            breaker.failureCount = 0;
            
            this._debug(`Circuit breaker fermé pour ${source}`);
        }
        
        return breaker.state === 'closed';
    }

    /**
     * Vérifie si un circuit breaker est ouvert
     * @param {string} source - Source à vérifier
     * @returns {boolean} - True si le circuit est ouvert
     */
    isCircuitOpen(source) {
        if (!this.circuitBreakers.has(source)) {
            return false;
        }
        
        return this.circuitBreakers.get(source).state === 'open';
    }

    /**
     * Applique une stratégie de récupération
     * @param {Object} errorObj - Objet d'erreur
     * @returns {Object} - Informations sur la récupération
     * @private
     */
    _applyRecoveryStrategy(errorObj) {
        const { error, context } = errorObj;
        
        // Déterminer la clé de stratégie
        let strategyKey = null;
        
        // Essayer d'abord avec le code d'erreur et la source
        if (error.code && context.source) {
            strategyKey = `${context.source}:${error.code}`;
            if (this.recoveryStrategies.has(strategyKey)) {
                return this._executeRecoveryStrategy(strategyKey, errorObj);
            }
        }
        
        // Essayer avec le code d'erreur uniquement
        if (error.code) {
            strategyKey = error.code;
            if (this.recoveryStrategies.has(strategyKey)) {
                return this._executeRecoveryStrategy(strategyKey, errorObj);
            }
        }
        
        // Essayer avec la source uniquement
        if (context.source) {
            strategyKey = context.source;
            if (this.recoveryStrategies.has(strategyKey)) {
                return this._executeRecoveryStrategy(strategyKey, errorObj);
            }
        }
        
        // Stratégie par défaut
        if (this.recoveryStrategies.has('default')) {
            return this._executeRecoveryStrategy('default', errorObj);
        }
        
        return null;
    }

    /**
     * Exécute une stratégie de récupération
     * @param {string} strategyKey - Clé de la stratégie
     * @param {Object} errorObj - Objet d'erreur
     * @returns {Object} - Informations sur la récupération
     * @private
     */
    _executeRecoveryStrategy(strategyKey, errorObj) {
        const strategy = this.recoveryStrategies.get(strategyKey);
        
        // Vérifier si la stratégie est déjà active pour cette source
        if (errorObj.context.source && this.activeRecoveries.has(errorObj.context.source)) {
            this._debug(`Stratégie de récupération déjà active pour ${errorObj.context.source}`);
            return {
                strategy: strategyKey,
                status: 'already_active'
            };
        }
        
        try {
            // Marquer comme active
            if (errorObj.context.source) {
                this.activeRecoveries.add(errorObj.context.source);
            }
            
            // Exécuter la stratégie
            const result = strategy.handler(errorObj.error, errorObj.context);
            
            this._debug(`Stratégie de récupération '${strategyKey}' exécutée avec succès`);
            
            // Planifier la désactivation
            if (errorObj.context.source) {
                setTimeout(() => {
                    this.activeRecoveries.delete(errorObj.context.source);
                }, strategy.cooldown || 5000);
            }
            
            return {
                strategy: strategyKey,
                status: 'success',
                result
            };
        } catch (recoveryError) {
            this._debug(`Erreur dans la stratégie de récupération '${strategyKey}':`, recoveryError);
            
            // Désactiver immédiatement
            if (errorObj.context.source) {
                this.activeRecoveries.delete(errorObj.context.source);
            }
            
            return {
                strategy: strategyKey,
                status: 'error',
                error: recoveryError
            };
        }
    }

    /**
     * Notifie les écouteurs d'erreurs
     * @param {Object} errorObj - Objet d'erreur
     * @private
     */
    _notifyErrorListeners(errorObj) {
        for (const listener of this.errorListeners) {
            try {
                listener(errorObj);
            } catch (listenerError) {
                console.error('Erreur dans l\'écouteur d\'erreurs:', listenerError);
            }
        }
    }

    /**
     * Ajoute un écouteur d'erreurs
     * @param {Function} listener - Fonction écouteur
     * @returns {number} - Index de l'écouteur
     */
    addErrorListener(listener) {
        if (typeof listener !== 'function') {
            throw new Error('L\'écouteur doit être une fonction');
        }
        
        this.errorListeners.push(listener);
        return this.errorListeners.length - 1;
    }

    /**
     * Supprime un écouteur d'erreurs
     * @param {number} index - Index de l'écouteur
     * @returns {boolean} - True si la suppression a réussi
     */
    removeErrorListener(index) {
        if (index >= 0 && index < this.errorListeners.length) {
            this.errorListeners.splice(index, 1);
            return true;
        }
        
        return false;
    }

    /**
     * Ajoute une stratégie de récupération
     * @param {string} key - Clé de la stratégie
     * @param {Function} handler - Fonction de gestion
     * @param {Object} options - Options de la stratégie
     * @returns {boolean} - True si l'ajout a réussi
     */
    addRecoveryStrategy(key, handler, options = {}) {
        if (typeof handler !== 'function') {
            throw new Error('Le gestionnaire doit être une fonction');
        }
        
        this.recoveryStrategies.set(key, {
            handler,
            cooldown: options.cooldown || 5000,
            maxAttempts: options.maxAttempts || 3,
            priority: options.priority || 0
        });
        
        return true;
    }

    /**
     * Supprime une stratégie de récupération
     * @param {string} key - Clé de la stratégie
     * @returns {boolean} - True si la suppression a réussi
     */
    removeRecoveryStrategy(key) {
        return this.recoveryStrategies.delete(key);
    }

    /**
     * Crée un gestionnaire de timeout
     * @param {number} timeout - Timeout en ms
     * @param {string} message - Message d'erreur
     * @returns {Function} - Fonction de gestion de timeout
     */
    createTimeoutHandler(timeout, message = 'Opération expirée') {
        return (operation) => {
            return new Promise((resolve, reject) => {
                const timeoutId = setTimeout(() => {
                    const error = new Error(message);
                    error.code = 'TIMEOUT';
                    error.timeout = timeout;
                    
                    this.handleError(error, {
                        source: 'timeout',
                        operation,
                        timeout
                    });
                    
                    reject(error);
                }, timeout);
                
                // Fonction pour annuler le timeout
                const cancel = () => {
                    clearTimeout(timeoutId);
                };
                
                // Retourner la fonction d'annulation
                resolve(cancel);
            });
        };
    }

    /**
     * Crée un wrapper avec timeout pour une promesse
     * @param {Promise} promise - Promesse à surveiller
     * @param {number} timeout - Timeout en ms
     * @param {string} operation - Nom de l'opération
     * @returns {Promise} - Promesse avec timeout
     */
    withTimeout(promise, timeout, operation = 'unknown') {
        return Promise.race([
            promise,
            new Promise((_, reject) => {
                setTimeout(() => {
                    const error = new Error(`Timeout de ${timeout}ms dépassé pour l'opération ${operation}`);
                    error.code = 'TIMEOUT';
                    error.timeout = timeout;
                    error.operation = operation;
                    
                    this.handleError(error, {
                        source: 'timeout',
                        operation,
                        timeout
                    });
                    
                    reject(error);
                }, timeout);
            })
        ]);
    }

    /**
     * Obtient les statistiques d'erreurs
     * @returns {Object} - Statistiques
     */
    getErrorStats() {
        // Nettoyer les erreurs trop anciennes
        this._cleanupOldErrors();
        
        // Calculer les statistiques
        const stats = {
            total: this.errors.length,
            groups: this.errorGroups.size,
            bySource: {},
            byCode: {},
            recentCount: 0
        };
        
        // Compter les erreurs récentes
        const recentThreshold = Date.now() - this.options.errorThresholdPeriod;
        stats.recentCount = this.errors.filter(e => e.timestamp >= recentThreshold).length;
        
        // Compter par source
        for (const error of this.errors) {
            const source = error.context.source || 'unknown';
            
            if (!stats.bySource[source]) {
                stats.bySource[source] = 0;
            }
            
            stats.bySource[source]++;
            
            // Compter par code
            const code = error.code || 'unknown';
            
            if (!stats.byCode[code]) {
                stats.byCode[code] = 0;
            }
            
            stats.byCode[code]++;
        }
        
        // Ajouter l'état des circuit breakers
        stats.circuitBreakers = {};
        
        for (const [source, breaker] of this.circuitBreakers.entries()) {
            stats.circuitBreakers[source] = {
                state: breaker.state,
                failureCount: breaker.failureCount,
                openSince: breaker.state === 'open' ? Date.now() - breaker.openTimestamp : 0
            };
        }
        
        return stats;
    }

    /**
     * Nettoie les erreurs trop anciennes
     * @private
     */
    _cleanupOldErrors() {
        const threshold = Date.now() - this.options.errorRetention;
        
        // Nettoyer la liste des erreurs
        this.errors = this.errors.filter(error => error.timestamp >= threshold);
        
        // Nettoyer les groupes d'erreurs
        for (const [key, group] of this.errorGroups.entries()) {
            if (group.lastSeen < threshold) {
                this.errorGroups.delete(key);
            }
        }
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
                console.log(`[ErrorHandler] ${message}`, data);
            } else {
                console.log(`[ErrorHandler] ${message}`);
            }
        }
    }

    /**
     * Nettoie les ressources utilisées par le gestionnaire
     */
    dispose() {
        // Annuler tous les timeouts des circuit breakers
        for (const breaker of this.circuitBreakers.values()) {
            if (breaker.resetTimeout) {
                clearTimeout(breaker.resetTimeout);
            }
        }
        
        // Réinitialiser les variables
        this.errors = [];
        this.errorGroups.clear();
        this.errorCounts.clear();
        this.errorListeners = [];
        this.recoveryStrategies.clear();
        this.activeRecoveries.clear();
        this.circuitBreakers.clear();
        
        this._debug('ErrorHandler nettoyé');
    }
}

// Exporter la classe pour utilisation dans d'autres modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        ErrorHandler
    };
}
