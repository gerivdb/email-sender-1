/**
 * hierarchical-diagram-event-bus.js
 * Module de bus d'événements centralisé pour les diagrammes hiérarchiques
 * Version: 1.0
 * Date: 2025-05-15
 */

/**
 * Classe EventBus
 * Implémente un bus d'événements centralisé pour la communication entre composants
 */
class EventBus {
    /**
     * Constructeur
     * @param {Object} options - Options de configuration
     * @param {boolean} options.debug - Activer le mode debug
     * @param {boolean} options.enableHistory - Activer l'historique des événements
     */
    constructor(options = {}) {
        // Options par défaut
        this.options = Object.assign({
            debug: false,
            enableHistory: true,
            historySize: 100,
            enableMetrics: true,
            enableNamespaces: true,
            enableWildcards: true,
            enablePriorities: true,
            defaultPriority: 5,
            maxPriority: 10,
            asyncDispatch: true,
            dispatchTimeout: 5000
        }, options);

        // État interne
        this.subscribers = new Map();
        this.eventHistory = [];
        this.eventMetrics = new Map();
        this.namespaces = new Map();
        this.wildcardSubscribers = new Map();
        this.dispatchQueue = [];
        this.isDispatching = false;
        this.dispatchTimers = new Map();
        this.eventCounter = 0;
        this.subscriptionCounter = 0;
    }

    /**
     * Abonne un gestionnaire à un type d'événement
     * @param {string} eventType - Type d'événement
     * @param {Function} handler - Fonction de gestion
     * @param {Object} options - Options d'abonnement
     * @returns {number} - ID d'abonnement
     */
    subscribe(eventType, handler, options = {}) {
        if (typeof handler !== 'function') {
            throw new Error('Le gestionnaire doit être une fonction');
        }

        // Options par défaut
        const subscriptionOptions = Object.assign({
            priority: this.options.defaultPriority,
            once: false,
            context: null,
            filter: null,
            namespace: null,
            metadata: {}
        }, options);

        // Générer un ID d'abonnement unique
        const subscriptionId = ++this.subscriptionCounter;

        // Créer l'objet d'abonnement
        const subscription = {
            id: subscriptionId,
            eventType,
            handler,
            options: subscriptionOptions,
            timestamp: Date.now()
        };

        // Gérer les wildcards si activés
        if (this.options.enableWildcards && (eventType.includes('*') || eventType.includes('#'))) {
            this._addWildcardSubscription(subscription);
            return subscriptionId;
        }

        // Gérer les namespaces si activés
        if (this.options.enableNamespaces && subscriptionOptions.namespace) {
            this._addNamespacedSubscription(subscription);
        }

        // Ajouter à la collection des abonnés
        if (!this.subscribers.has(eventType)) {
            this.subscribers.set(eventType, []);
        }

        this.subscribers.get(eventType).push(subscription);

        // Trier par priorité si activé
        if (this.options.enablePriorities) {
            this._sortSubscribersByPriority(eventType);
        }

        this._debug(`Abonnement #${subscriptionId} ajouté pour l'événement '${eventType}'`);
        return subscriptionId;
    }

    /**
     * Ajoute un abonnement avec wildcard
     * @param {Object} subscription - Objet d'abonnement
     * @private
     */
    _addWildcardSubscription(subscription) {
        // Convertir le pattern en expression régulière
        let pattern = subscription.eventType
            .replace(/\./g, '\\.')  // Échapper les points
            .replace(/\*/g, '[^.]+')  // * correspond à tout sauf un point
            .replace(/#/g, '.*');     // # correspond à tout, y compris les points

        // Créer l'expression régulière
        const regex = new RegExp(`^${pattern}$`);

        // Stocker l'abonnement
        if (!this.wildcardSubscribers.has(subscription.eventType)) {
            this.wildcardSubscribers.set(subscription.eventType, []);
        }

        this.wildcardSubscribers.get(subscription.eventType).push({
            ...subscription,
            regex
        });

        this._debug(`Abonnement wildcard #${subscription.id} ajouté pour le pattern '${subscription.eventType}'`);
    }

    /**
     * Ajoute un abonnement avec namespace
     * @param {Object} subscription - Objet d'abonnement
     * @private
     */
    _addNamespacedSubscription(subscription) {
        const namespace = subscription.options.namespace;

        // Créer le namespace s'il n'existe pas
        if (!this.namespaces.has(namespace)) {
            this.namespaces.set(namespace, new Map());
        }

        // Ajouter l'abonnement au namespace
        const namespaceMap = this.namespaces.get(namespace);
        if (!namespaceMap.has(subscription.eventType)) {
            namespaceMap.set(subscription.eventType, []);
        }

        namespaceMap.get(subscription.eventType).push(subscription);

        this._debug(`Abonnement #${subscription.id} ajouté au namespace '${namespace}' pour l'événement '${subscription.eventType}'`);
    }

    /**
     * Trie les abonnés par priorité
     * @param {string} eventType - Type d'événement
     * @private
     */
    _sortSubscribersByPriority(eventType) {
        if (!this.subscribers.has(eventType)) {
            return;
        }

        // Trier par priorité (priorité plus élevée d'abord)
        this.subscribers.get(eventType).sort((a, b) => b.options.priority - a.options.priority);
    }

    /**
     * Désabonne un gestionnaire
     * @param {number|string|Function} idOrTypeOrHandler - ID d'abonnement, type d'événement ou fonction de gestion
     * @param {Function} handler - Fonction de gestion (si idOrTypeOrHandler est un type d'événement)
     * @returns {boolean} - True si le désabonnement a réussi
     */
    unsubscribe(idOrTypeOrHandler, handler = null) {
        // Désabonnement par ID
        if (typeof idOrTypeOrHandler === 'number') {
            return this._unsubscribeById(idOrTypeOrHandler);
        }

        // Désabonnement par type d'événement
        if (typeof idOrTypeOrHandler === 'string') {
            return this._unsubscribeByType(idOrTypeOrHandler, handler);
        }

        // Désabonnement par fonction de gestion
        if (typeof idOrTypeOrHandler === 'function') {
            return this._unsubscribeByHandler(idOrTypeOrHandler);
        }

        return false;
    }

    /**
     * Désabonne par ID
     * @param {number} subscriptionId - ID d'abonnement
     * @returns {boolean} - True si le désabonnement a réussi
     * @private
     */
    _unsubscribeById(subscriptionId) {
        let found = false;

        // Rechercher dans les abonnés normaux
        for (const [eventType, subscriptions] of this.subscribers.entries()) {
            const index = subscriptions.findIndex(sub => sub.id === subscriptionId);
            if (index !== -1) {
                subscriptions.splice(index, 1);
                found = true;
                this._debug(`Abonnement #${subscriptionId} supprimé pour l'événement '${eventType}'`);
                break;
            }
        }

        // Rechercher dans les abonnés wildcard
        if (!found) {
            for (const [pattern, subscriptions] of this.wildcardSubscribers.entries()) {
                const index = subscriptions.findIndex(sub => sub.id === subscriptionId);
                if (index !== -1) {
                    subscriptions.splice(index, 1);
                    found = true;
                    this._debug(`Abonnement wildcard #${subscriptionId} supprimé pour le pattern '${pattern}'`);
                    break;
                }
            }
        }

        // Rechercher dans les namespaces
        if (!found) {
            for (const namespaceMap of this.namespaces.values()) {
                for (const [eventType, subscriptions] of namespaceMap.entries()) {
                    const index = subscriptions.findIndex(sub => sub.id === subscriptionId);
                    if (index !== -1) {
                        subscriptions.splice(index, 1);
                        found = true;
                        this._debug(`Abonnement #${subscriptionId} supprimé du namespace pour l'événement '${eventType}'`);
                        break;
                    }
                }
                if (found) break;
            }
        }

        return found;
    }

    /**
     * Désabonne par type d'événement
     * @param {string} eventType - Type d'événement
     * @param {Function} handler - Fonction de gestion (optionnel)
     * @returns {boolean} - True si le désabonnement a réussi
     * @private
     */
    _unsubscribeByType(eventType, handler) {
        // Si pas de gestionnaire spécifié, supprimer tous les abonnements pour ce type
        if (!handler) {
            const hasSubscribers = this.subscribers.has(eventType);
            this.subscribers.delete(eventType);

            // Supprimer également des wildcards et namespaces
            if (this.options.enableWildcards) {
                this.wildcardSubscribers.delete(eventType);
            }

            if (this.options.enableNamespaces) {
                for (const namespaceMap of this.namespaces.values()) {
                    namespaceMap.delete(eventType);
                }
            }

            if (hasSubscribers) {
                this._debug(`Tous les abonnements supprimés pour l'événement '${eventType}'`);
            }

            return hasSubscribers;
        }

        // Sinon, supprimer uniquement l'abonnement spécifique
        if (!this.subscribers.has(eventType)) {
            return false;
        }

        const subscriptions = this.subscribers.get(eventType);
        const initialLength = subscriptions.length;
        const filtered = subscriptions.filter(sub => sub.handler !== handler);
        
        this.subscribers.set(eventType, filtered);
        
        const removed = filtered.length < initialLength;
        
        if (removed) {
            this._debug(`Abonnement spécifique supprimé pour l'événement '${eventType}'`);
        }
        
        return removed;
    }

    /**
     * Désabonne par fonction de gestion
     * @param {Function} handler - Fonction de gestion
     * @returns {boolean} - True si le désabonnement a réussi
     * @private
     */
    _unsubscribeByHandler(handler) {
        let found = false;

        // Rechercher dans les abonnés normaux
        for (const [eventType, subscriptions] of this.subscribers.entries()) {
            const initialLength = subscriptions.length;
            const filtered = subscriptions.filter(sub => sub.handler !== handler);
            
            if (filtered.length < initialLength) {
                this.subscribers.set(eventType, filtered);
                found = true;
                this._debug(`Abonnement(s) supprimé(s) pour le gestionnaire sur l'événement '${eventType}'`);
            }
        }

        // Rechercher dans les abonnés wildcard
        for (const [pattern, subscriptions] of this.wildcardSubscribers.entries()) {
            const initialLength = subscriptions.length;
            const filtered = subscriptions.filter(sub => sub.handler !== handler);
            
            if (filtered.length < initialLength) {
                this.wildcardSubscribers.set(pattern, filtered);
                found = true;
                this._debug(`Abonnement(s) wildcard supprimé(s) pour le gestionnaire sur le pattern '${pattern}'`);
            }
        }

        // Rechercher dans les namespaces
        for (const namespaceMap of this.namespaces.values()) {
            for (const [eventType, subscriptions] of namespaceMap.entries()) {
                const initialLength = subscriptions.length;
                const filtered = subscriptions.filter(sub => sub.handler !== handler);
                
                if (filtered.length < initialLength) {
                    namespaceMap.set(eventType, filtered);
                    found = true;
                    this._debug(`Abonnement(s) supprimé(s) pour le gestionnaire dans le namespace sur l'événement '${eventType}'`);
                }
            }
        }

        return found;
    }

    /**
     * Désabonne tous les gestionnaires d'un namespace
     * @param {string} namespace - Namespace à désabonner
     * @returns {boolean} - True si le désabonnement a réussi
     */
    unsubscribeNamespace(namespace) {
        if (!this.options.enableNamespaces) {
            return false;
        }

        const hasNamespace = this.namespaces.has(namespace);
        this.namespaces.delete(namespace);

        if (hasNamespace) {
            this._debug(`Tous les abonnements supprimés pour le namespace '${namespace}'`);
        }

        return hasNamespace;
    }

    /**
     * Publie un événement
     * @param {string} eventType - Type d'événement
     * @param {Object} data - Données de l'événement
     * @param {Object} options - Options de publication
     * @returns {string} - ID de l'événement
     */
    publish(eventType, data = {}, options = {}) {
        // Options par défaut
        const publishOptions = Object.assign({
            async: this.options.asyncDispatch,
            timeout: this.options.dispatchTimeout,
            namespace: null,
            metadata: {},
            origin: null
        }, options);

        // Générer un ID d'événement unique
        const eventId = `evt_${++this.eventCounter}`;

        // Créer l'objet événement
        const event = {
            id: eventId,
            type: eventType,
            data,
            timestamp: Date.now(),
            options: publishOptions
        };

        // Ajouter à l'historique si activé
        if (this.options.enableHistory) {
            this._addToHistory(event);
        }

        // Mettre à jour les métriques si activées
        if (this.options.enableMetrics) {
            this._updateMetrics(eventType);
        }

        // Ajouter à la file d'attente de dispatch
        this.dispatchQueue.push(event);

        // Traiter la file d'attente
        if (publishOptions.async) {
            // Dispatch asynchrone
            setTimeout(() => this._processDispatchQueue(), 0);
        } else {
            // Dispatch synchrone
            this._processDispatchQueue();
        }

        return eventId;
    }

    /**
     * Traite la file d'attente de dispatch
     * @private
     */
    _processDispatchQueue() {
        if (this.isDispatching || this.dispatchQueue.length === 0) {
            return;
        }

        this.isDispatching = true;

        try {
            // Récupérer le prochain événement
            const event = this.dispatchQueue.shift();

            // Dispatcher l'événement
            this._dispatchEvent(event);
        } finally {
            this.isDispatching = false;

            // Continuer à traiter la file d'attente s'il reste des événements
            if (this.dispatchQueue.length > 0) {
                setTimeout(() => this._processDispatchQueue(), 0);
            }
        }
    }

    /**
     * Dispatche un événement aux abonnés
     * @param {Object} event - Événement à dispatcher
     * @private
     */
    _dispatchEvent(event) {
        const eventType = event.type;
        const subscribers = this._getSubscribersForEvent(eventType, event.options.namespace);

        this._debug(`Dispatching de l'événement '${eventType}' à ${subscribers.length} abonnés`);

        // Appeler chaque abonné
        for (const subscription of subscribers) {
            try {
                // Appliquer le filtre si présent
                if (subscription.options.filter && !subscription.options.filter(event)) {
                    continue;
                }

                // Déterminer le contexte
                const context = subscription.options.context || this;

                // Appeler le gestionnaire
                subscription.handler.call(context, event.data, {
                    eventType,
                    eventId: event.id,
                    timestamp: event.timestamp,
                    metadata: { ...event.options.metadata, ...subscription.options.metadata }
                });

                // Supprimer l'abonnement s'il est à usage unique
                if (subscription.options.once) {
                    this.unsubscribe(subscription.id);
                }
            } catch (error) {
                console.error(`Erreur lors du dispatch de l'événement '${eventType}' à l'abonné #${subscription.id}:`, error);
            }
        }
    }

    /**
     * Récupère les abonnés pour un événement
     * @param {string} eventType - Type d'événement
     * @param {string} namespace - Namespace (optionnel)
     * @returns {Array} - Tableau des abonnés
     * @private
     */
    _getSubscribersForEvent(eventType, namespace) {
        const subscribers = [];

        // Ajouter les abonnés directs
        if (this.subscribers.has(eventType)) {
            subscribers.push(...this.subscribers.get(eventType));
        }

        // Ajouter les abonnés wildcard si activés
        if (this.options.enableWildcards) {
            for (const [pattern, wildcardSubs] of this.wildcardSubscribers.entries()) {
                for (const sub of wildcardSubs) {
                    if (sub.regex.test(eventType)) {
                        subscribers.push(sub);
                    }
                }
            }
        }

        // Ajouter les abonnés du namespace si spécifié et activé
        if (this.options.enableNamespaces && namespace) {
            if (this.namespaces.has(namespace)) {
                const namespaceMap = this.namespaces.get(namespace);
                if (namespaceMap.has(eventType)) {
                    subscribers.push(...namespaceMap.get(eventType));
                }

                // Ajouter également les wildcards du namespace
                if (this.options.enableWildcards) {
                    for (const [pattern, subs] of namespaceMap.entries()) {
                        if (pattern.includes('*') || pattern.includes('#')) {
                            const regex = new RegExp(`^${pattern
                                .replace(/\./g, '\\.')
                                .replace(/\*/g, '[^.]+')
                                .replace(/#/g, '.*')}$`);
                            
                            if (regex.test(eventType)) {
                                subscribers.push(...subs);
                            }
                        }
                    }
                }
            }
        }

        // Trier par priorité si activé
        if (this.options.enablePriorities) {
            subscribers.sort((a, b) => b.options.priority - a.options.priority);
        }

        return subscribers;
    }

    /**
     * Ajoute un événement à l'historique
     * @param {Object} event - Événement à ajouter
     * @private
     */
    _addToHistory(event) {
        this.eventHistory.push({
            id: event.id,
            type: event.type,
            timestamp: event.timestamp,
            data: event.data
        });

        // Limiter la taille de l'historique
        if (this.eventHistory.length > this.options.historySize) {
            this.eventHistory.shift();
        }
    }

    /**
     * Met à jour les métriques pour un type d'événement
     * @param {string} eventType - Type d'événement
     * @private
     */
    _updateMetrics(eventType) {
        if (!this.eventMetrics.has(eventType)) {
            this.eventMetrics.set(eventType, {
                count: 0,
                firstSeen: Date.now(),
                lastSeen: Date.now(),
                subscribers: 0
            });
        }

        const metrics = this.eventMetrics.get(eventType);
        metrics.count++;
        metrics.lastSeen = Date.now();
        metrics.subscribers = this.subscribers.has(eventType) ? this.subscribers.get(eventType).length : 0;
    }

    /**
     * Obtient l'historique des événements
     * @param {Object} filters - Filtres à appliquer
     * @returns {Array} - Historique des événements
     */
    getEventHistory(filters = {}) {
        if (!this.options.enableHistory) {
            return [];
        }

        let history = [...this.eventHistory];

        // Appliquer les filtres
        if (filters.eventType) {
            history = history.filter(evt => evt.type === filters.eventType);
        }

        if (filters.startTime) {
            history = history.filter(evt => evt.timestamp >= filters.startTime);
        }

        if (filters.endTime) {
            history = history.filter(evt => evt.timestamp <= filters.endTime);
        }

        // Limiter le nombre de résultats
        if (filters.limit) {
            history = history.slice(-filters.limit);
        }

        return history;
    }

    /**
     * Obtient les métriques des événements
     * @param {string} eventType - Type d'événement (optionnel)
     * @returns {Object} - Métriques des événements
     */
    getMetrics(eventType = null) {
        if (!this.options.enableMetrics) {
            return {};
        }

        if (eventType) {
            return this.eventMetrics.get(eventType) || {
                count: 0,
                firstSeen: null,
                lastSeen: null,
                subscribers: 0
            };
        }

        const metrics = {
            totalEvents: 0,
            uniqueEventTypes: this.eventMetrics.size,
            totalSubscribers: 0,
            eventTypes: {}
        };

        // Calculer les métriques globales
        for (const [type, typeMetrics] of this.eventMetrics.entries()) {
            metrics.totalEvents += typeMetrics.count;
            metrics.totalSubscribers += typeMetrics.subscribers;
            metrics.eventTypes[type] = typeMetrics;
        }

        return metrics;
    }

    /**
     * Vérifie si un type d'événement a des abonnés
     * @param {string} eventType - Type d'événement
     * @returns {boolean} - True si des abonnés existent
     */
    hasSubscribers(eventType) {
        // Vérifier les abonnés directs
        if (this.subscribers.has(eventType) && this.subscribers.get(eventType).length > 0) {
            return true;
        }

        // Vérifier les abonnés wildcard si activés
        if (this.options.enableWildcards) {
            for (const [pattern, subs] of this.wildcardSubscribers.entries()) {
                if (subs.length > 0) {
                    const regex = new RegExp(`^${pattern
                        .replace(/\./g, '\\.')
                        .replace(/\*/g, '[^.]+')
                        .replace(/#/g, '.*')}$`);
                    
                    if (regex.test(eventType)) {
                        return true;
                    }
                }
            }
        }

        // Vérifier les namespaces si activés
        if (this.options.enableNamespaces) {
            for (const namespaceMap of this.namespaces.values()) {
                if (namespaceMap.has(eventType) && namespaceMap.get(eventType).length > 0) {
                    return true;
                }

                // Vérifier également les wildcards du namespace
                if (this.options.enableWildcards) {
                    for (const [pattern, subs] of namespaceMap.entries()) {
                        if (subs.length > 0 && (pattern.includes('*') || pattern.includes('#'))) {
                            const regex = new RegExp(`^${pattern
                                .replace(/\./g, '\\.')
                                .replace(/\*/g, '[^.]+')
                                .replace(/#/g, '.*')}$`);
                            
                            if (regex.test(eventType)) {
                                return true;
                            }
                        }
                    }
                }
            }
        }

        return false;
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
                console.log(`[EventBus] ${message}`, data);
            } else {
                console.log(`[EventBus] ${message}`);
            }
        }
    }

    /**
     * Nettoie les ressources utilisées par le bus d'événements
     */
    dispose() {
        // Annuler tous les timeouts
        for (const timeoutId of this.dispatchTimers.values()) {
            clearTimeout(timeoutId);
        }

        // Réinitialiser les variables
        this.subscribers.clear();
        this.eventHistory = [];
        this.eventMetrics.clear();
        this.namespaces.clear();
        this.wildcardSubscribers.clear();
        this.dispatchQueue = [];
        this.dispatchTimers.clear();
        this.isDispatching = false;

        this._debug('EventBus nettoyé');
    }
}

// Exporter la classe pour utilisation dans d'autres modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        EventBus
    };
}
