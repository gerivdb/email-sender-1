/**
 * hierarchical-diagram-messaging.js
 * Module de système de messages entre composants pour les diagrammes hiérarchiques
 * Version: 1.0
 * Date: 2025-05-15
 */

/**
 * Classe MessageSystem
 * Gère le système de messages entre composants
 */
class MessageSystem {
    /**
     * Constructeur
     * @param {Object} options - Options de configuration
     * @param {boolean} options.debug - Activer le mode debug
     * @param {boolean} options.validateMessages - Valider les messages selon leur schéma
     */
    constructor(options = {}) {
        // Options par défaut
        this.options = Object.assign({
            debug: false,
            validateMessages: true,
            bufferSize: 100,
            deliveryTimeout: 5000,
            retryCount: 3,
            retryDelay: 1000,
            priorityLevels: 3,
            broadcastEnabled: true
        }, options);

        // État interne
        this.components = new Map();
        this.channels = new Map();
        this.messageSchemas = new Map();
        this.messageBuffer = [];
        this.messageHistory = [];
        this.pendingMessages = new Map();
        this.messageCounter = 0;
        this.deliveryTimers = new Map();
        this.channelSubscriptions = new Map();
        this.componentGroups = new Map();
    }

    /**
     * Enregistre un composant
     * @param {string} componentId - ID du composant
     * @param {Object} component - Objet composant
     * @param {Object} options - Options d'enregistrement
     * @returns {boolean} - True si l'enregistrement a réussi
     */
    registerComponent(componentId, component, options = {}) {
        if (this.components.has(componentId)) {
            this._debug(`Composant '${componentId}' déjà enregistré`);
            return false;
        }

        // Options par défaut
        const componentOptions = Object.assign({
            groups: [],
            canSend: true,
            canReceive: true,
            messageHandler: null,
            messageTypes: null,
            priority: 1
        }, options);

        // Enregistrer le composant
        this.components.set(componentId, {
            id: componentId,
            component,
            options: componentOptions,
            registered: Date.now()
        });

        // Ajouter aux groupes
        for (const group of componentOptions.groups) {
            if (!this.componentGroups.has(group)) {
                this.componentGroups.set(group, new Set());
            }
            this.componentGroups.get(group).add(componentId);
        }

        this._debug(`Composant '${componentId}' enregistré`);
        return true;
    }

    /**
     * Désenregistre un composant
     * @param {string} componentId - ID du composant
     * @returns {boolean} - True si le désenregistrement a réussi
     */
    unregisterComponent(componentId) {
        if (!this.components.has(componentId)) {
            return false;
        }

        const component = this.components.get(componentId);

        // Retirer des groupes
        for (const group of component.options.groups) {
            if (this.componentGroups.has(group)) {
                this.componentGroups.get(group).delete(componentId);
                
                // Supprimer le groupe s'il est vide
                if (this.componentGroups.get(group).size === 0) {
                    this.componentGroups.delete(group);
                }
            }
        }

        // Supprimer les abonnements aux canaux
        for (const [channel, subscribers] of this.channelSubscriptions.entries()) {
            if (subscribers.has(componentId)) {
                subscribers.delete(componentId);
                
                // Supprimer le canal s'il n'a plus d'abonnés
                if (subscribers.size === 0) {
                    this.channelSubscriptions.delete(channel);
                }
            }
        }

        // Supprimer le composant
        this.components.delete(componentId);

        this._debug(`Composant '${componentId}' désenregistré`);
        return true;
    }

    /**
     * Envoie un message
     * @param {string} senderId - ID du composant émetteur
     * @param {string} receiverId - ID du composant destinataire
     * @param {string} type - Type de message
     * @param {Object} data - Données du message
     * @param {Object} options - Options d'envoi
     * @returns {string} - ID du message ou null en cas d'échec
     */
    sendMessage(senderId, receiverId, type, data = {}, options = {}) {
        // Vérifier si l'émetteur est enregistré
        if (!this.components.has(senderId)) {
            this._debug(`Émetteur '${senderId}' non enregistré`);
            return null;
        }

        // Vérifier si l'émetteur peut envoyer des messages
        const sender = this.components.get(senderId);
        if (!sender.options.canSend) {
            this._debug(`Émetteur '${senderId}' ne peut pas envoyer de messages`);
            return null;
        }

        // Vérifier si le destinataire est enregistré
        if (!this.components.has(receiverId)) {
            this._debug(`Destinataire '${receiverId}' non enregistré`);
            return null;
        }

        // Vérifier si le destinataire peut recevoir des messages
        const receiver = this.components.get(receiverId);
        if (!receiver.options.canReceive) {
            this._debug(`Destinataire '${receiverId}' ne peut pas recevoir de messages`);
            return null;
        }

        // Vérifier si le destinataire accepte ce type de message
        if (receiver.options.messageTypes && !receiver.options.messageTypes.includes(type)) {
            this._debug(`Destinataire '${receiverId}' n'accepte pas les messages de type '${type}'`);
            return null;
        }

        // Options par défaut
        const messageOptions = Object.assign({
            priority: 1,
            timeout: this.options.deliveryTimeout,
            retry: false,
            retryCount: this.options.retryCount,
            retryDelay: this.options.retryDelay,
            requireAck: false,
            metadata: {}
        }, options);

        // Créer le message
        const messageId = `msg_${++this.messageCounter}`;
        const message = {
            id: messageId,
            senderId,
            receiverId,
            type,
            data,
            options: messageOptions,
            timestamp: Date.now(),
            status: 'pending',
            attempts: 1
        };

        // Valider le message si nécessaire
        if (this.options.validateMessages && this.messageSchemas.has(type)) {
            const isValid = this._validateMessage(message, this.messageSchemas.get(type));
            if (!isValid) {
                this._debug(`Message de type '${type}' invalide`);
                return null;
            }
        }

        // Ajouter au buffer
        this.messageBuffer.push(message);

        // Limiter la taille du buffer
        if (this.messageBuffer.length > this.options.bufferSize) {
            this.messageBuffer.shift();
        }

        // Livrer le message
        this._deliverMessage(message);

        return messageId;
    }

    /**
     * Livre un message
     * @param {Object} message - Message à livrer
     * @private
     */
    _deliverMessage(message) {
        // Récupérer le destinataire
        const receiver = this.components.get(message.receiverId);
        if (!receiver) {
            this._debug(`Destinataire '${message.receiverId}' non trouvé pour le message ${message.id}`);
            message.status = 'failed';
            return;
        }

        // Mettre à jour le statut
        message.status = 'delivering';
        message.deliveryTimestamp = Date.now();

        // Stocker dans les messages en attente si un accusé de réception est requis
        if (message.options.requireAck) {
            this.pendingMessages.set(message.id, message);
            
            // Configurer le timeout
            const timeoutId = setTimeout(() => {
                // Vérifier si le message est toujours en attente
                if (this.pendingMessages.has(message.id)) {
                    const pendingMessage = this.pendingMessages.get(message.id);
                    
                    // Vérifier si on doit réessayer
                    if (pendingMessage.options.retry && pendingMessage.attempts < pendingMessage.options.retryCount) {
                        // Incrémenter le compteur de tentatives
                        pendingMessage.attempts++;
                        
                        this._debug(`Nouvelle tentative (${pendingMessage.attempts}/${pendingMessage.options.retryCount}) pour le message ${pendingMessage.id}`);
                        
                        // Réessayer après un délai
                        setTimeout(() => {
                            this._deliverMessage(pendingMessage);
                        }, pendingMessage.options.retryDelay);
                    } else {
                        // Marquer comme échoué
                        pendingMessage.status = 'failed';
                        
                        // Supprimer des messages en attente
                        this.pendingMessages.delete(pendingMessage.id);
                        
                        this._debug(`Livraison du message ${pendingMessage.id} échouée après ${pendingMessage.attempts} tentative(s)`);
                    }
                }
            }, message.options.timeout);
            
            // Stocker l'ID du timeout
            this.deliveryTimers.set(message.id, timeoutId);
        }

        try {
            // Appeler le gestionnaire de messages du destinataire
            if (typeof receiver.options.messageHandler === 'function') {
                receiver.options.messageHandler(message);
            } else if (receiver.component && typeof receiver.component.handleMessage === 'function') {
                receiver.component.handleMessage(message);
            } else {
                this._debug(`Destinataire '${message.receiverId}' n'a pas de gestionnaire de messages`);
                message.status = 'failed';
                return;
            }

            // Mettre à jour le statut si pas d'accusé de réception requis
            if (!message.options.requireAck) {
                message.status = 'delivered';
                
                // Ajouter à l'historique
                this._addToHistory(message);
            }
        } catch (error) {
            this._debug(`Erreur lors de la livraison du message ${message.id}:`, error);
            message.status = 'failed';
            message.error = error;
        }
    }

    /**
     * Accuse réception d'un message
     * @param {string} messageId - ID du message
     * @param {string} receiverId - ID du composant destinataire
     * @param {Object} response - Réponse optionnelle
     * @returns {boolean} - True si l'accusé de réception a réussi
     */
    acknowledgeMessage(messageId, receiverId, response = null) {
        // Vérifier si le message est en attente
        if (!this.pendingMessages.has(messageId)) {
            return false;
        }

        const message = this.pendingMessages.get(messageId);

        // Vérifier si le destinataire correspond
        if (message.receiverId !== receiverId) {
            this._debug(`Destinataire '${receiverId}' non autorisé à accuser réception du message ${messageId}`);
            return false;
        }

        // Annuler le timeout
        if (this.deliveryTimers.has(messageId)) {
            clearTimeout(this.deliveryTimers.get(messageId));
            this.deliveryTimers.delete(messageId);
        }

        // Mettre à jour le statut
        message.status = 'acknowledged';
        message.acknowledgementTimestamp = Date.now();
        message.response = response;

        // Supprimer des messages en attente
        this.pendingMessages.delete(messageId);

        // Ajouter à l'historique
        this._addToHistory(message);

        this._debug(`Message ${messageId} accusé de réception par '${receiverId}'`);
        return true;
    }

    /**
     * Diffuse un message à un groupe de composants
     * @param {string} senderId - ID du composant émetteur
     * @param {string} groupId - ID du groupe destinataire
     * @param {string} type - Type de message
     * @param {Object} data - Données du message
     * @param {Object} options - Options d'envoi
     * @returns {Array} - Tableau des IDs de messages envoyés
     */
    broadcastToGroup(senderId, groupId, type, data = {}, options = {}) {
        // Vérifier si la diffusion est activée
        if (!this.options.broadcastEnabled) {
            this._debug('Diffusion désactivée');
            return [];
        }

        // Vérifier si le groupe existe
        if (!this.componentGroups.has(groupId)) {
            this._debug(`Groupe '${groupId}' non trouvé`);
            return [];
        }

        const messageIds = [];

        // Envoyer le message à chaque membre du groupe
        for (const receiverId of this.componentGroups.get(groupId)) {
            // Ne pas envoyer à l'émetteur
            if (receiverId === senderId) {
                continue;
            }

            const messageId = this.sendMessage(senderId, receiverId, type, data, options);
            if (messageId) {
                messageIds.push(messageId);
            }
        }

        this._debug(`Message diffusé au groupe '${groupId}' (${messageIds.length} destinataires)`);
        return messageIds;
    }

    /**
     * Publie un message sur un canal
     * @param {string} senderId - ID du composant émetteur
     * @param {string} channel - Nom du canal
     * @param {string} type - Type de message
     * @param {Object} data - Données du message
     * @param {Object} options - Options d'envoi
     * @returns {Array} - Tableau des IDs de messages envoyés
     */
    publishToChannel(senderId, channel, type, data = {}, options = {}) {
        // Vérifier si le canal existe
        if (!this.channelSubscriptions.has(channel)) {
            this._debug(`Canal '${channel}' n'a pas d'abonnés`);
            return [];
        }

        const messageIds = [];

        // Envoyer le message à chaque abonné
        for (const receiverId of this.channelSubscriptions.get(channel)) {
            // Ne pas envoyer à l'émetteur
            if (receiverId === senderId) {
                continue;
            }

            const messageId = this.sendMessage(senderId, receiverId, type, data, options);
            if (messageId) {
                messageIds.push(messageId);
            }
        }

        this._debug(`Message publié sur le canal '${channel}' (${messageIds.length} abonnés)`);
        return messageIds;
    }

    /**
     * Abonne un composant à un canal
     * @param {string} componentId - ID du composant
     * @param {string} channel - Nom du canal
     * @returns {boolean} - True si l'abonnement a réussi
     */
    subscribeToChannel(componentId, channel) {
        // Vérifier si le composant est enregistré
        if (!this.components.has(componentId)) {
            this._debug(`Composant '${componentId}' non enregistré`);
            return false;
        }

        // Créer le canal s'il n'existe pas
        if (!this.channelSubscriptions.has(channel)) {
            this.channelSubscriptions.set(channel, new Set());
        }

        // Ajouter le composant aux abonnés
        this.channelSubscriptions.get(channel).add(componentId);

        this._debug(`Composant '${componentId}' abonné au canal '${channel}'`);
        return true;
    }

    /**
     * Désabonne un composant d'un canal
     * @param {string} componentId - ID du composant
     * @param {string} channel - Nom du canal
     * @returns {boolean} - True si le désabonnement a réussi
     */
    unsubscribeFromChannel(componentId, channel) {
        // Vérifier si le canal existe
        if (!this.channelSubscriptions.has(channel)) {
            return false;
        }

        // Retirer le composant des abonnés
        const result = this.channelSubscriptions.get(channel).delete(componentId);

        // Supprimer le canal s'il n'a plus d'abonnés
        if (this.channelSubscriptions.get(channel).size === 0) {
            this.channelSubscriptions.delete(channel);
        }

        if (result) {
            this._debug(`Composant '${componentId}' désabonné du canal '${channel}'`);
        }

        return result;
    }

    /**
     * Enregistre un schéma de message
     * @param {string} type - Type de message
     * @param {Object} schema - Schéma du message
     * @returns {boolean} - True si l'enregistrement a réussi
     */
    registerMessageSchema(type, schema) {
        this.messageSchemas.set(type, schema);
        this._debug(`Schéma enregistré pour les messages de type '${type}'`);
        return true;
    }

    /**
     * Valide un message selon son schéma
     * @param {Object} message - Message à valider
     * @param {Object} schema - Schéma du message
     * @returns {boolean} - True si le message est valide
     * @private
     */
    _validateMessage(message, schema) {
        // Implémentation simple de validation
        // Dans une version réelle, utiliser une bibliothèque comme Ajv
        
        try {
            // Vérifier les propriétés requises
            if (schema.required) {
                for (const prop of schema.required) {
                    if (!(prop in message.data)) {
                        this._debug(`Propriété requise '${prop}' manquante dans le message ${message.id}`);
                        return false;
                    }
                }
            }
            
            // Vérifier les types de propriétés
            if (schema.properties) {
                for (const [prop, propSchema] of Object.entries(schema.properties)) {
                    if (prop in message.data) {
                        const value = message.data[prop];
                        
                        // Vérifier le type
                        if (propSchema.type) {
                            let typeValid = false;
                            
                            switch (propSchema.type) {
                                case 'string':
                                    typeValid = typeof value === 'string';
                                    break;
                                case 'number':
                                    typeValid = typeof value === 'number';
                                    break;
                                case 'boolean':
                                    typeValid = typeof value === 'boolean';
                                    break;
                                case 'object':
                                    typeValid = typeof value === 'object' && value !== null;
                                    break;
                                case 'array':
                                    typeValid = Array.isArray(value);
                                    break;
                                case 'null':
                                    typeValid = value === null;
                                    break;
                            }
                            
                            if (!typeValid) {
                                this._debug(`Type invalide pour la propriété '${prop}' dans le message ${message.id}`);
                                return false;
                            }
                        }
                        
                        // Vérifier l'énumération
                        if (propSchema.enum && !propSchema.enum.includes(value)) {
                            this._debug(`Valeur invalide pour la propriété '${prop}' dans le message ${message.id}`);
                            return false;
                        }
                    }
                }
            }
            
            return true;
        } catch (error) {
            this._debug(`Erreur lors de la validation du message ${message.id}:`, error);
            return false;
        }
    }

    /**
     * Ajoute un message à l'historique
     * @param {Object} message - Message à ajouter
     * @private
     */
    _addToHistory(message) {
        this.messageHistory.push({
            id: message.id,
            senderId: message.senderId,
            receiverId: message.receiverId,
            type: message.type,
            timestamp: message.timestamp,
            deliveryTimestamp: message.deliveryTimestamp,
            acknowledgementTimestamp: message.acknowledgementTimestamp,
            status: message.status
        });

        // Limiter la taille de l'historique
        if (this.messageHistory.length > 100) {
            this.messageHistory.shift();
        }
    }

    /**
     * Obtient l'historique des messages
     * @param {Object} filters - Filtres à appliquer
     * @returns {Array} - Historique des messages
     */
    getMessageHistory(filters = {}) {
        let history = [...this.messageHistory];

        // Appliquer les filtres
        if (filters.senderId) {
            history = history.filter(msg => msg.senderId === filters.senderId);
        }

        if (filters.receiverId) {
            history = history.filter(msg => msg.receiverId === filters.receiverId);
        }

        if (filters.type) {
            history = history.filter(msg => msg.type === filters.type);
        }

        if (filters.status) {
            history = history.filter(msg => msg.status === filters.status);
        }

        if (filters.startTime) {
            history = history.filter(msg => msg.timestamp >= filters.startTime);
        }

        if (filters.endTime) {
            history = history.filter(msg => msg.timestamp <= filters.endTime);
        }

        // Limiter le nombre de résultats
        if (filters.limit) {
            history = history.slice(-filters.limit);
        }

        return history;
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
                console.log(`[MessageSystem] ${message}`, data);
            } else {
                console.log(`[MessageSystem] ${message}`);
            }
        }
    }

    /**
     * Nettoie les ressources utilisées par le système
     */
    dispose() {
        // Annuler tous les timeouts
        for (const timeoutId of this.deliveryTimers.values()) {
            clearTimeout(timeoutId);
        }

        // Réinitialiser les variables
        this.components.clear();
        this.channels.clear();
        this.messageSchemas.clear();
        this.messageBuffer = [];
        this.messageHistory = [];
        this.pendingMessages.clear();
        this.deliveryTimers.clear();
        this.channelSubscriptions.clear();
        this.componentGroups.clear();

        this._debug('MessageSystem nettoyé');
    }
}

// Exporter la classe pour utilisation dans d'autres modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        MessageSystem
    };
}
