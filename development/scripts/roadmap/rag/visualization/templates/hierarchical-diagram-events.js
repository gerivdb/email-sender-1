/**
 * hierarchical-diagram-events.js
 * Module de gestion des événements pour les diagrammes hiérarchiques
 * Version: 1.0
 * Date: 2025-05-15
 */

/**
 * Classe EventManager
 * Gère les événements et callbacks pour les diagrammes hiérarchiques
 */
class EventManager {
    /**
     * Constructeur
     * @param {Object} options - Options de configuration
     * @param {string} options.containerId - ID du conteneur SVG
     * @param {boolean} options.debug - Activer le mode debug
     * @param {boolean} options.bubbling - Activer la propagation des événements
     */
    constructor(options = {}) {
        // Options par défaut
        this.options = Object.assign({
            containerId: 'hierarchy-container',
            debug: false,
            bubbling: true,
            asyncCallbacks: true,
            maxCallbackTime: 100,
            throttleEvents: true,
            throttleDelay: 50
        }, options);

        // État interne
        this.container = document.getElementById(this.options.containerId);
        this.listeners = new Map();
        this.onceListeners = new Map();
        this.eventQueue = [];
        this.isProcessingEvent = false;
        this.lastEvents = new Map();
        this.throttleTimers = new Map();
        this.callbackRegistry = new Map();
        this.callbackCounter = 0;
        this.busyCallbacks = new Set();
        this.eventHistory = [];
        this.maxHistorySize = 100;

        // Initialisation
        this._initialize();
    }

    /**
     * Initialise le gestionnaire d'événements
     * @private
     */
    _initialize() {
        if (!this.container) {
            console.error(`Conteneur avec ID '${this.options.containerId}' non trouvé`);
            return;
        }

        // Configurer les gestionnaires d'événements standard
        this._setupStandardEvents();

        // Log d'initialisation
        this._debug('EventManager initialisé');
    }

    /**
     * Configure les gestionnaires d'événements standard
     * @private
     */
    _setupStandardEvents() {
        // Liste des événements standard à intercepter
        const standardEvents = [
            'click', 'dblclick', 'mousedown', 'mouseup', 'mousemove',
            'mouseover', 'mouseout', 'wheel', 'keydown', 'keyup'
        ];

        // Ajouter les gestionnaires pour chaque événement
        standardEvents.forEach(eventType => {
            this.container.addEventListener(eventType, (event) => {
                // Créer un événement personnalisé
                const customEvent = this._createCustomEvent(eventType, event);

                // Déclencher l'événement
                this.trigger(customEvent.type, customEvent);
            });
        });

        // Gestionnaire pour les redimensionnements
        window.addEventListener('resize', () => {
            // Throttle l'événement de redimensionnement
            this._throttle('resize', () => {
                const customEvent = this._createCustomEvent('resize', {
                    width: window.innerWidth,
                    height: window.innerHeight
                });

                this.trigger(customEvent.type, customEvent);
            });
        });

        // Ajouter les gestionnaires pour les événements spécifiques au diagramme
        this._setupDiagramEvents();
    }

    /**
     * Configure les gestionnaires d'événements spécifiques au diagramme
     * @private
     */
    _setupDiagramEvents() {
        // Événements de nœud
        this.container.addEventListener('click', (event) => {
            const node = event.target.closest('.node');
            if (node) {
                const nodeData = this._getNodeData(node);
                if (nodeData) {
                    const nodeEvent = this._createCustomEvent('node:click', {
                        originalEvent: event,
                        node: node,
                        nodeData: nodeData
                    });

                    this.trigger(nodeEvent.type, nodeEvent);
                }
            }
        });

        this.container.addEventListener('dblclick', (event) => {
            const node = event.target.closest('.node');
            if (node) {
                const nodeData = this._getNodeData(node);
                if (nodeData) {
                    const nodeEvent = this._createCustomEvent('node:dblclick', {
                        originalEvent: event,
                        node: node,
                        nodeData: nodeData
                    });

                    this.trigger(nodeEvent.type, nodeEvent);
                }
            }
        });

        // Événements de survol de nœud
        this.container.addEventListener('mouseover', (event) => {
            const node = event.target.closest('.node');
            if (node) {
                const nodeData = this._getNodeData(node);
                if (nodeData) {
                    const nodeEvent = this._createCustomEvent('node:mouseover', {
                        originalEvent: event,
                        node: node,
                        nodeData: nodeData
                    });

                    this.trigger(nodeEvent.type, nodeEvent);
                }
            }
        });

        this.container.addEventListener('mouseout', (event) => {
            const node = event.target.closest('.node');
            if (node) {
                const nodeData = this._getNodeData(node);
                if (nodeData) {
                    const nodeEvent = this._createCustomEvent('node:mouseout', {
                        originalEvent: event,
                        node: node,
                        nodeData: nodeData
                    });

                    this.trigger(nodeEvent.type, nodeEvent);
                }
            }
        });

        // Événements de lien
        this.container.addEventListener('click', (event) => {
            const link = event.target.closest('.link');
            if (link) {
                const linkData = this._getLinkData(link);
                if (linkData) {
                    const linkEvent = this._createCustomEvent('link:click', {
                        originalEvent: event,
                        link: link,
                        linkData: linkData
                    });

                    this.trigger(linkEvent.type, linkEvent);
                }
            }
        });

        // Événements de zoom
        this.container.addEventListener('wheel', (event) => {
            if (event.ctrlKey || event.metaKey) {
                event.preventDefault();

                const zoomEvent = this._createCustomEvent('diagram:zoom', {
                    originalEvent: event,
                    delta: event.deltaY < 0 ? 1.1 : 0.9,
                    center: {
                        x: event.clientX,
                        y: event.clientY
                    }
                });

                this.trigger(zoomEvent.type, zoomEvent);
            }
        });

        // Événements de pan (déplacement)
        let isPanning = false;
        let lastPanPosition = { x: 0, y: 0 };

        this.container.addEventListener('mousedown', (event) => {
            // Vérifier si c'est un clic du bouton du milieu ou un clic gauche avec la touche Alt
            if (event.button === 1 || (event.button === 0 && event.altKey)) {
                isPanning = true;
                lastPanPosition = { x: event.clientX, y: event.clientY };

                const panStartEvent = this._createCustomEvent('diagram:panstart', {
                    originalEvent: event,
                    position: { ...lastPanPosition }
                });

                this.trigger(panStartEvent.type, panStartEvent);

                // Empêcher la sélection de texte pendant le pan
                event.preventDefault();
            }
        });

        document.addEventListener('mousemove', (event) => {
            if (isPanning) {
                const dx = event.clientX - lastPanPosition.x;
                const dy = event.clientY - lastPanPosition.y;

                const panEvent = this._createCustomEvent('diagram:pan', {
                    originalEvent: event,
                    delta: { x: dx, y: dy },
                    position: { x: event.clientX, y: event.clientY }
                });

                this.trigger(panEvent.type, panEvent);

                lastPanPosition = { x: event.clientX, y: event.clientY };
            }
        });

        document.addEventListener('mouseup', (event) => {
            if (isPanning) {
                isPanning = false;

                const panEndEvent = this._createCustomEvent('diagram:panend', {
                    originalEvent: event,
                    position: { x: event.clientX, y: event.clientY }
                });

                this.trigger(panEndEvent.type, panEndEvent);
            }
        });

        // Événements de sélection
        let isSelecting = false;
        let selectionStart = { x: 0, y: 0 };

        this.container.addEventListener('mousedown', (event) => {
            // Vérifier si c'est un clic gauche sans modificateur sur le fond
            if (event.button === 0 && !event.target.closest('.node') && !event.target.closest('.link')) {
                isSelecting = true;
                selectionStart = { x: event.clientX, y: event.clientY };

                const selectStartEvent = this._createCustomEvent('diagram:selectstart', {
                    originalEvent: event,
                    position: { ...selectionStart }
                });

                this.trigger(selectStartEvent.type, selectStartEvent);
            }
        });

        document.addEventListener('mousemove', (event) => {
            if (isSelecting) {
                const selectEvent = this._createCustomEvent('diagram:select', {
                    originalEvent: event,
                    start: { ...selectionStart },
                    end: { x: event.clientX, y: event.clientY }
                });

                this.trigger(selectEvent.type, selectEvent);
            }
        });

        document.addEventListener('mouseup', (event) => {
            if (isSelecting) {
                isSelecting = false;

                const selectEndEvent = this._createCustomEvent('diagram:selectend', {
                    originalEvent: event,
                    start: { ...selectionStart },
                    end: { x: event.clientX, y: event.clientY }
                });

                this.trigger(selectEndEvent.type, selectEndEvent);
            }
        });
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
     * Récupère les données associées à un lien
     * @param {Element} link - Élément DOM du lien
     * @returns {Object} - Données du lien ou null
     * @private
     */
    _getLinkData(link) {
        // Essayer de récupérer les données via d3.js
        if (link.__data__) {
            return {
                source: link.__data__.source.data,
                target: link.__data__.target.data
            };
        }

        // Essayer de récupérer via attribut data-*
        if (link.dataset.linkSource && link.dataset.linkTarget) {
            return {
                source: link.dataset.linkSource,
                target: link.dataset.linkTarget
            };
        }

        return null;
    }

    /**
     * Crée un événement personnalisé à partir d'un événement standard
     * @param {string} type - Type d'événement
     * @param {Event|Object} originalEvent - Événement original ou données
     * @returns {Object} - Événement personnalisé
     * @private
     */
    _createCustomEvent(type, originalEvent) {
        // Base de l'événement personnalisé
        const customEvent = {
            type,
            timestamp: Date.now(),
            target: null,
            originalEvent: originalEvent instanceof Event ? originalEvent : null,
            data: !(originalEvent instanceof Event) ? originalEvent : null,
            defaultPrevented: false,
            propagationStopped: false,

            // Méthodes
            preventDefault: function() {
                this.defaultPrevented = true;
                if (this.originalEvent && typeof this.originalEvent.preventDefault === 'function') {
                    this.originalEvent.preventDefault();
                }
            },

            stopPropagation: function() {
                this.propagationStopped = true;
                if (this.originalEvent && typeof this.originalEvent.stopPropagation === 'function') {
                    this.originalEvent.stopPropagation();
                }
            }
        };

        // Ajouter des propriétés spécifiques selon le type d'événement
        if (originalEvent instanceof Event) {
            // Définir la cible
            customEvent.target = originalEvent.target;

            // Ajouter des propriétés spécifiques selon le type
            switch (type) {
                case 'click':
                case 'dblclick':
                case 'mousedown':
                case 'mouseup':
                case 'mousemove':
                case 'mouseover':
                case 'mouseout':
                    // Coordonnées de la souris
                    customEvent.clientX = originalEvent.clientX;
                    customEvent.clientY = originalEvent.clientY;
                    customEvent.button = originalEvent.button;

                    // Touches modificatrices
                    customEvent.ctrlKey = originalEvent.ctrlKey;
                    customEvent.shiftKey = originalEvent.shiftKey;
                    customEvent.altKey = originalEvent.altKey;
                    customEvent.metaKey = originalEvent.metaKey;

                    // Coordonnées relatives au conteneur
                    if (this.container) {
                        const rect = this.container.getBoundingClientRect();
                        customEvent.containerX = originalEvent.clientX - rect.left;
                        customEvent.containerY = originalEvent.clientY - rect.top;
                    }
                    break;

                case 'wheel':
                    // Informations de défilement
                    customEvent.deltaX = originalEvent.deltaX;
                    customEvent.deltaY = originalEvent.deltaY;
                    customEvent.deltaZ = originalEvent.deltaZ;
                    customEvent.deltaMode = originalEvent.deltaMode;
                    break;

                case 'keydown':
                case 'keyup':
                    // Informations de touche
                    customEvent.key = originalEvent.key;
                    customEvent.code = originalEvent.code;
                    customEvent.keyCode = originalEvent.keyCode;
                    customEvent.repeat = originalEvent.repeat;

                    // Touches modificatrices
                    customEvent.ctrlKey = originalEvent.ctrlKey;
                    customEvent.shiftKey = originalEvent.shiftKey;
                    customEvent.altKey = originalEvent.altKey;
                    customEvent.metaKey = originalEvent.metaKey;
                    break;
            }
        }

        return customEvent;
    }

    /**
     * Ajoute un écouteur d'événement
     * @param {string} eventType - Type d'événement
     * @param {Function} callback - Fonction de rappel
     * @param {Object} options - Options supplémentaires
     * @returns {number} - ID de l'écouteur
     */
    on(eventType, callback, options = {}) {
        if (typeof callback !== 'function') {
            throw new Error('Le callback doit être une fonction');
        }

        // Options par défaut
        const listenerOptions = Object.assign({
            priority: 0,
            context: null,
            once: false
        }, options);

        // Générer un ID unique pour l'écouteur
        const listenerId = ++this.callbackCounter;

        // Créer l'objet écouteur
        const listener = {
            id: listenerId,
            callback,
            options: listenerOptions
        };

        // Ajouter à la collection appropriée
        if (listenerOptions.once) {
            if (!this.onceListeners.has(eventType)) {
                this.onceListeners.set(eventType, []);
            }
            this.onceListeners.get(eventType).push(listener);
        } else {
            if (!this.listeners.has(eventType)) {
                this.listeners.set(eventType, []);
            }
            this.listeners.get(eventType).push(listener);

            // Trier par priorité (priorité plus élevée d'abord)
            this.listeners.get(eventType).sort((a, b) => b.options.priority - a.options.priority);
        }

        // Log d'ajout d'écouteur
        this._debug(`Écouteur ajouté pour '${eventType}', ID: ${listenerId}`);

        return listenerId;
    }

    /**
     * Ajoute un écouteur d'événement à usage unique
     * @param {string} eventType - Type d'événement
     * @param {Function} callback - Fonction de rappel
     * @param {Object} options - Options supplémentaires
     * @returns {number} - ID de l'écouteur
     */
    once(eventType, callback, options = {}) {
        options.once = true;
        return this.on(eventType, callback, options);
    }

    /**
     * Supprime un écouteur d'événement
     * @param {string} eventType - Type d'événement
     * @param {Function|number} callbackOrId - Fonction de rappel ou ID
     * @returns {boolean} - True si la suppression a réussi
     */
    off(eventType, callbackOrId) {
        let removed = false;

        // Fonction pour supprimer un écouteur d'une collection
        const removeFromCollection = (collection) => {
            if (!collection.has(eventType)) {
                return false;
            }

            const listeners = collection.get(eventType);
            const initialLength = listeners.length;

            // Filtrer selon le type de callbackOrId
            if (typeof callbackOrId === 'function') {
                // Supprimer par fonction
                const filtered = listeners.filter(listener => listener.callback !== callbackOrId);
                collection.set(eventType, filtered);
                removed = filtered.length < initialLength;
            } else if (typeof callbackOrId === 'number') {
                // Supprimer par ID
                const filtered = listeners.filter(listener => listener.id !== callbackOrId);
                collection.set(eventType, filtered);
                removed = filtered.length < initialLength;
            } else if (callbackOrId === undefined) {
                // Supprimer tous les écouteurs pour ce type
                collection.delete(eventType);
                removed = initialLength > 0;
            }

            return removed;
        };

        // Supprimer des deux collections
        const removedNormal = removeFromCollection(this.listeners);
        const removedOnce = removeFromCollection(this.onceListeners);

        // Log de suppression d'écouteur
        if (removedNormal || removedOnce) {
            this._debug(`Écouteur(s) supprimé(s) pour '${eventType}'`);
        }

        return removedNormal || removedOnce;
    }

    /**
     * Supprime tous les écouteurs
     * @param {string} eventType - Type d'événement (optionnel)
     */
    offAll(eventType = null) {
        if (eventType) {
            // Supprimer tous les écouteurs pour un type spécifique
            this.listeners.delete(eventType);
            this.onceListeners.delete(eventType);
            this._debug(`Tous les écouteurs supprimés pour '${eventType}'`);
        } else {
            // Supprimer tous les écouteurs
            this.listeners.clear();
            this.onceListeners.clear();
            this._debug('Tous les écouteurs supprimés');
        }
    }

    /**
     * Déclenche un événement
     * @param {string} eventType - Type d'événement
     * @param {Object} eventData - Données de l'événement
     * @returns {boolean} - True si l'événement n'a pas été annulé
     */
    trigger(eventType, eventData = {}) {
        // Créer l'événement s'il n'est pas déjà un objet d'événement personnalisé
        const event = eventData && eventData.type ?
            eventData : this._createCustomEvent(eventType, eventData);

        // Ajouter à l'historique
        this._addToHistory(event);

        // Mettre à jour le dernier événement de ce type
        this.lastEvents.set(eventType, event);

        // Ajouter à la file d'attente
        this.eventQueue.push(event);

        // Traiter la file d'attente si ce n'est pas déjà en cours
        if (!this.isProcessingEvent) {
            this._processEventQueue();
        }

        // Propager l'événement aux parents si la propagation est activée
        if (this.options.bubbling && event.target && !event.propagationStopped) {
            this._propagateEvent(event);
        }

        // Retourner true si l'événement n'a pas été annulé
        return !event.defaultPrevented;
    }

    /**
     * Traite la file d'attente d'événements
     * @private
     */
    _processEventQueue() {
        if (this.eventQueue.length === 0) {
            this.isProcessingEvent = false;
            return;
        }

        this.isProcessingEvent = true;

        // Récupérer le prochain événement
        const event = this.eventQueue.shift();

        // Log de déclenchement d'événement
        this._debug(`Traitement de l'événement '${event.type}'`, event);

        // Récupérer les écouteurs pour ce type d'événement
        const normalListeners = this.listeners.get(event.type) || [];
        const onceListeners = this.onceListeners.get(event.type) || [];

        // Combiner et trier par priorité
        const allListeners = [...normalListeners, ...onceListeners]
            .sort((a, b) => b.options.priority - a.options.priority);

        // Appeler chaque écouteur
        const promises = [];

        for (const listener of allListeners) {
            // Vérifier si la propagation a été arrêtée
            if (event.propagationStopped) {
                break;
            }

            // Appeler le callback
            try {
                const context = listener.options.context || this;
                const result = listener.callback.call(context, event);

                // Si le callback est asynchrone et que l'option est activée
                if (this.options.asyncCallbacks && result instanceof Promise) {
                    promises.push(result);
                }
            } catch (error) {
                console.error(`Erreur dans l'écouteur pour '${event.type}':`, error);
            }
        }

        // Supprimer les écouteurs à usage unique
        if (onceListeners.length > 0) {
            this.onceListeners.delete(event.type);
        }

        // Attendre les promesses si nécessaire
        if (promises.length > 0 && this.options.asyncCallbacks) {
            Promise.all(promises)
                .catch(error => console.error(`Erreur dans un callback asynchrone:`, error))
                .finally(() => {
                    // Continuer avec le prochain événement
                    this._processEventQueue();
                });
        } else {
            // Continuer avec le prochain événement
            this._processEventQueue();
        }
    }

    /**
     * Ajoute un événement à l'historique
     * @param {Object} event - Événement à ajouter
     * @private
     */
    _addToHistory(event) {
        // Ajouter à l'historique
        this.eventHistory.push({
            type: event.type,
            timestamp: event.timestamp,
            data: event
        });

        // Limiter la taille de l'historique
        if (this.eventHistory.length > this.maxHistorySize) {
            this.eventHistory.shift();
        }
    }

    /**
     * Propage un événement aux éléments parents
     * @param {Object} event - Événement à propager
     * @private
     */
    _propagateEvent(event) {
        if (!event.target || event.propagationStopped) {
            return;
        }

        // Créer une copie de l'événement pour la propagation
        const propagationEvent = { ...event };
        propagationEvent.originalTarget = event.target;
        propagationEvent.propagationPhase = 'bubbling';

        // Trouver les parents et propager l'événement
        let currentTarget = event.target.parentNode;

        while (currentTarget && !propagationEvent.propagationStopped) {
            // Mettre à jour la cible actuelle
            propagationEvent.target = currentTarget;

            // Créer un type d'événement spécifique pour la propagation
            const propagationEventType = `${event.type}.bubble`;

            // Déclencher l'événement sur la cible actuelle
            this.trigger(propagationEventType, propagationEvent);

            // Passer au parent suivant
            currentTarget = currentTarget.parentNode;
        }
    }

    /**
     * Capture un événement en descendant des parents vers la cible
     * @param {string} eventType - Type d'événement
     * @param {Element} target - Élément cible
     * @param {Object} eventData - Données de l'événement
     * @returns {boolean} - True si l'événement n'a pas été annulé
     */
    captureEvent(eventType, target, eventData = {}) {
        if (!target) {
            return true;
        }

        // Créer l'événement
        const event = this._createCustomEvent(eventType, eventData);
        event.originalTarget = target;
        event.target = target;
        event.propagationPhase = 'capturing';

        // Collecter les parents
        const parents = [];
        let currentParent = target.parentNode;

        while (currentParent) {
            parents.unshift(currentParent);
            currentParent = currentParent.parentNode;
        }

        // Propager l'événement de haut en bas
        for (const parent of parents) {
            if (event.propagationStopped) {
                break;
            }

            // Mettre à jour la cible actuelle
            event.target = parent;

            // Créer un type d'événement spécifique pour la capture
            const captureEventType = `${eventType}.capture`;

            // Déclencher l'événement sur le parent
            this.trigger(captureEventType, event);
        }

        // Finalement, déclencher l'événement sur la cible originale
        if (!event.propagationStopped) {
            event.target = target;
            return this.trigger(eventType, event);
        }

        return !event.defaultPrevented;
    }

    /**
     * Déclenche un événement avec les phases de capture et de bouillonnement
     * @param {string} eventType - Type d'événement
     * @param {Element} target - Élément cible
     * @param {Object} eventData - Données de l'événement
     * @returns {boolean} - True si l'événement n'a pas été annulé
     */
    dispatchEvent(eventType, target, eventData = {}) {
        if (!target) {
            return true;
        }

        // Phase de capture (du haut vers le bas)
        const captureResult = this.captureEvent(`${eventType}.capture`, target, eventData);

        // Si l'événement a été annulé pendant la capture, arrêter
        if (!captureResult) {
            return false;
        }

        // Phase cible (l'événement lui-même)
        const targetResult = this.trigger(eventType, { ...eventData, target });

        // Si l'événement a été annulé ou la propagation arrêtée, arrêter
        if (!targetResult || (eventData.propagationStopped)) {
            return targetResult;
        }

        // Phase de bouillonnement (du bas vers le haut)
        // Cette phase est gérée automatiquement par trigger() si bubbling est activé

        return targetResult;
    }

    /**
     * Limite la fréquence d'exécution d'une fonction
     * @param {string} key - Clé unique pour identifier la fonction
     * @param {Function} fn - Fonction à exécuter
     * @param {number} delay - Délai en ms (optionnel)
     * @private
     */
    _throttle(key, fn, delay = null) {
        const actualDelay = delay || this.options.throttleDelay;

        // Annuler le timer existant
        if (this.throttleTimers.has(key)) {
            clearTimeout(this.throttleTimers.get(key));
        }

        // Créer un nouveau timer
        this.throttleTimers.set(key, setTimeout(() => {
            fn();
            this.throttleTimers.delete(key);
        }, actualDelay));
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
                console.log(`[EventManager] ${message}`, data);
            } else {
                console.log(`[EventManager] ${message}`);
            }
        }
    }

    /**
     * Obtient le dernier événement d'un type spécifique
     * @param {string} eventType - Type d'événement
     * @returns {Object} - Dernier événement ou null
     */
    getLastEvent(eventType) {
        return this.lastEvents.get(eventType) || null;
    }

    /**
     * Vérifie si un type d'événement a des écouteurs
     * @param {string} eventType - Type d'événement
     * @returns {boolean} - True si des écouteurs existent
     */
    hasListeners(eventType) {
        return (this.listeners.has(eventType) && this.listeners.get(eventType).length > 0) ||
               (this.onceListeners.has(eventType) && this.onceListeners.get(eventType).length > 0);
    }

    /**
     * Obtient l'historique des événements
     * @param {string} eventType - Type d'événement (optionnel)
     * @param {number} limit - Nombre maximum d'événements à retourner (optionnel)
     * @returns {Array} - Historique des événements
     */
    getEventHistory(eventType = null, limit = null) {
        let history = [...this.eventHistory];

        // Filtrer par type si spécifié
        if (eventType) {
            history = history.filter(entry => entry.type === eventType);
        }

        // Limiter le nombre d'entrées si spécifié
        if (limit && limit > 0) {
            history = history.slice(-limit);
        }

        return history;
    }

    /**
     * Nettoie les ressources utilisées par le gestionnaire d'événements
     */
    dispose() {
        // Supprimer tous les écouteurs
        this.offAll();

        // Annuler tous les timers
        this.throttleTimers.forEach(timerId => clearTimeout(timerId));
        this.throttleTimers.clear();

        // Réinitialiser les variables
        this.eventQueue = [];
        this.isProcessingEvent = false;
        this.lastEvents.clear();
        this.eventHistory = [];

        this._debug('EventManager nettoyé');
    }

    /**
     * Abonne un objet à plusieurs événements à la fois
     * @param {Object} subscriber - Objet s'abonnant aux événements
     * @param {Object} eventMap - Mapping des événements aux méthodes
     * @returns {Object} - Objet contenant les IDs des écouteurs
     */
    subscribe(subscriber, eventMap) {
        if (!subscriber || typeof subscriber !== 'object') {
            throw new Error('Le subscriber doit être un objet');
        }

        if (!eventMap || typeof eventMap !== 'object') {
            throw new Error('Le eventMap doit être un objet');
        }

        const subscriptionIds = {};

        // Parcourir le mapping des événements
        for (const [eventType, handlerInfo] of Object.entries(eventMap)) {
            let handler, options = {};

            // Déterminer le handler et les options
            if (typeof handlerInfo === 'string') {
                // Si c'est une chaîne, c'est le nom de la méthode
                if (typeof subscriber[handlerInfo] !== 'function') {
                    console.warn(`La méthode '${handlerInfo}' n'existe pas sur le subscriber`);
                    continue;
                }
                handler = subscriber[handlerInfo].bind(subscriber);
            } else if (typeof handlerInfo === 'function') {
                // Si c'est une fonction, l'utiliser directement
                handler = handlerInfo.bind(subscriber);
            } else if (typeof handlerInfo === 'object') {
                // Si c'est un objet, extraire le handler et les options
                if (typeof handlerInfo.handler === 'string') {
                    if (typeof subscriber[handlerInfo.handler] !== 'function') {
                        console.warn(`La méthode '${handlerInfo.handler}' n'existe pas sur le subscriber`);
                        continue;
                    }
                    handler = subscriber[handlerInfo.handler].bind(subscriber);
                } else if (typeof handlerInfo.handler === 'function') {
                    handler = handlerInfo.handler.bind(subscriber);
                } else {
                    console.warn(`Handler invalide pour l'événement '${eventType}'`);
                    continue;
                }

                // Extraire les options
                if (handlerInfo.options && typeof handlerInfo.options === 'object') {
                    options = handlerInfo.options;
                }
            } else {
                console.warn(`Configuration invalide pour l'événement '${eventType}'`);
                continue;
            }

            // Ajouter le contexte
            options.context = subscriber;

            // Abonner à l'événement
            const listenerId = this.on(eventType, handler, options);

            // Stocker l'ID
            if (!subscriptionIds[eventType]) {
                subscriptionIds[eventType] = [];
            }
            subscriptionIds[eventType].push(listenerId);
        }

        // Stocker les IDs sur le subscriber pour faciliter le désabonnement
        if (!subscriber._eventSubscriptions) {
            subscriber._eventSubscriptions = {};
        }

        // Fusionner avec les abonnements existants
        for (const [eventType, ids] of Object.entries(subscriptionIds)) {
            if (!subscriber._eventSubscriptions[eventType]) {
                subscriber._eventSubscriptions[eventType] = [];
            }
            subscriber._eventSubscriptions[eventType].push(...ids);
        }

        this._debug(`Objet abonné à ${Object.keys(subscriptionIds).length} événements`, subscriptionIds);

        return subscriptionIds;
    }

    /**
     * Désabonne un objet de tous ses événements
     * @param {Object} subscriber - Objet à désabonner
     * @param {string|Array} eventTypes - Types d'événements spécifiques (optionnel)
     * @returns {boolean} - True si le désabonnement a réussi
     */
    unsubscribe(subscriber, eventTypes = null) {
        if (!subscriber || !subscriber._eventSubscriptions) {
            return false;
        }

        let success = false;
        const subscriptions = subscriber._eventSubscriptions;

        // Déterminer les types d'événements à désabonner
        const typesToUnsubscribe = eventTypes ?
            (Array.isArray(eventTypes) ? eventTypes : [eventTypes]) :
            Object.keys(subscriptions);

        // Désabonner de chaque type d'événement
        for (const eventType of typesToUnsubscribe) {
            if (subscriptions[eventType]) {
                // Désabonner de chaque ID
                for (const listenerId of subscriptions[eventType]) {
                    const removed = this.off(eventType, listenerId);
                    success = success || removed;
                }

                // Supprimer les IDs
                delete subscriptions[eventType];
            }
        }

        // Si tous les abonnements ont été supprimés, supprimer la propriété
        if (Object.keys(subscriptions).length === 0) {
            delete subscriber._eventSubscriptions;
        }

        this._debug(`Objet désabonné de ${typesToUnsubscribe.length} événements`);

        return success;
    }

    /**
     * Abonne un objet à un événement avec un filtre
     * @param {string} eventType - Type d'événement
     * @param {Function} callback - Fonction de rappel
     * @param {Function} filter - Fonction de filtre
     * @param {Object} options - Options supplémentaires
     * @returns {number} - ID de l'écouteur
     */
    onWithFilter(eventType, callback, filter, options = {}) {
        if (typeof callback !== 'function') {
            throw new Error('Le callback doit être une fonction');
        }

        if (typeof filter !== 'function') {
            throw new Error('Le filtre doit être une fonction');
        }

        // Créer un wrapper qui applique le filtre
        const wrappedCallback = function(event) {
            if (filter(event)) {
                return callback.call(this, event);
            }
        };

        // Abonner avec le wrapper
        return this.on(eventType, wrappedCallback, options);
    }

    /**
     * Abonne un objet à un événement avec un délai
     * @param {string} eventType - Type d'événement
     * @param {Function} callback - Fonction de rappel
     * @param {number} delay - Délai en ms
     * @param {Object} options - Options supplémentaires
     * @returns {number} - ID de l'écouteur
     */
    onWithDelay(eventType, callback, delay, options = {}) {
        if (typeof callback !== 'function') {
            throw new Error('Le callback doit être une fonction');
        }

        if (typeof delay !== 'number' || delay < 0) {
            throw new Error('Le délai doit être un nombre positif');
        }

        // Créer un wrapper qui applique le délai
        const wrappedCallback = function(event) {
            setTimeout(() => {
                callback.call(this, event);
            }, delay);
        };

        // Abonner avec le wrapper
        return this.on(eventType, wrappedCallback, options);
    }

    /**
     * Abonne un objet à un événement avec un debounce
     * @param {string} eventType - Type d'événement
     * @param {Function} callback - Fonction de rappel
     * @param {number} wait - Temps d'attente en ms
     * @param {Object} options - Options supplémentaires
     * @returns {number} - ID de l'écouteur
     */
    onWithDebounce(eventType, callback, wait, options = {}) {
        if (typeof callback !== 'function') {
            throw new Error('Le callback doit être une fonction');
        }

        if (typeof wait !== 'number' || wait < 0) {
            throw new Error('Le temps d\'attente doit être un nombre positif');
        }

        // Créer un wrapper avec debounce
        let timeoutId = null;
        const wrappedCallback = function(event) {
            const context = this;

            // Annuler le timeout précédent
            if (timeoutId !== null) {
                clearTimeout(timeoutId);
            }

            // Créer un nouveau timeout
            timeoutId = setTimeout(() => {
                timeoutId = null;
                callback.call(context, event);
            }, wait);
        };

        // Abonner avec le wrapper
        return this.on(eventType, wrappedCallback, options);
    }

    /**
     * Abonne un objet à un événement avec un throttle
     * @param {string} eventType - Type d'événement
     * @param {Function} callback - Fonction de rappel
     * @param {number} limit - Limite de temps en ms
     * @param {Object} options - Options supplémentaires
     * @returns {number} - ID de l'écouteur
     */
    onWithThrottle(eventType, callback, limit, options = {}) {
        if (typeof callback !== 'function') {
            throw new Error('Le callback doit être une fonction');
        }

        if (typeof limit !== 'number' || limit < 0) {
            throw new Error('La limite doit être un nombre positif');
        }

        // Créer un wrapper avec throttle
        let lastCall = 0;
        const wrappedCallback = function(event) {
            const now = Date.now();
            const context = this;

            if (now - lastCall >= limit) {
                lastCall = now;
                callback.call(context, event);
            }
        };

        // Abonner avec le wrapper
        return this.on(eventType, wrappedCallback, options);
    }
}

// Exporter la classe pour utilisation dans d'autres modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        EventManager
    };
}
