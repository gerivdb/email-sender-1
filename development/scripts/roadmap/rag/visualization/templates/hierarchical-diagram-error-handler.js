/**
 * hierarchical-diagram-error-handler.js
 * Module de gestion des erreurs et états de chargement pour les diagrammes hiérarchiques
 * Version: 1.0
 * Date: 2025-05-15
 */

/**
 * Classe DiagramStateManager
 * Gère les états de chargement, erreurs et notifications pour les diagrammes
 */
class DiagramStateManager {
    /**
     * Constructeur
     * @param {Object} options - Options de configuration
     * @param {string} options.containerId - ID du conteneur principal
     * @param {boolean} options.showLoadingIndicator - Afficher l'indicateur de chargement
     * @param {boolean} options.showErrorMessages - Afficher les messages d'erreur
     * @param {boolean} options.showNotifications - Afficher les notifications
     * @param {number} options.notificationDuration - Durée d'affichage des notifications en ms
     */
    constructor(options = {}) {
        // Options par défaut
        this.options = Object.assign({
            containerId: 'hierarchy-container',
            showLoadingIndicator: true,
            showErrorMessages: true,
            showNotifications: true,
            notificationDuration: 5000
        }, options);

        // État interne
        this.isLoading = false;
        this.errors = [];
        this.notifications = [];
        this.maxErrors = 10;
        this.maxNotifications = 10;
        this.loadingStartTime = null;
        this.loadingTimeout = 30000; // 30 secondes
        this.loadingTimeoutTimer = null;

        // Éléments DOM
        this.container = document.getElementById(this.options.containerId);
        this.containerParent = this.container ? this.container.parentNode : null;
        this.loadingOverlay = null;
        this.errorContainer = null;
        this.notificationContainer = null;

        // Initialisation
        this._createUIElements();
    }

    /**
     * Crée les éléments d'interface utilisateur
     * @private
     */
    _createUIElements() {
        if (!this.containerParent) {
            console.error('Conteneur parent introuvable');
            return;
        }

        // S'assurer que le conteneur parent a une position relative
        if (window.getComputedStyle(this.containerParent).position === 'static') {
            this.containerParent.style.position = 'relative';
        }

        // Créer l'overlay de chargement
        if (this.options.showLoadingIndicator) {
            this.loadingOverlay = document.createElement('div');
            this.loadingOverlay.className = 'diagram-loading-overlay';
            this.loadingOverlay.innerHTML = `
                <div class="diagram-loading-spinner"></div>
                <div class="diagram-loading-text">Chargement...</div>
                <div class="diagram-loading-progress">
                    <div class="diagram-loading-progress-bar"></div>
                </div>
            `;
            this.loadingOverlay.style.display = 'none';
            this.containerParent.appendChild(this.loadingOverlay);
        }

        // Créer le conteneur d'erreurs
        if (this.options.showErrorMessages) {
            this.errorContainer = document.createElement('div');
            this.errorContainer.className = 'diagram-error-container';
            this.errorContainer.style.display = 'none';
            this.containerParent.appendChild(this.errorContainer);
        }

        // Créer le conteneur de notifications
        if (this.options.showNotifications) {
            this.notificationContainer = document.createElement('div');
            this.notificationContainer.className = 'diagram-notification-container';
            document.body.appendChild(this.notificationContainer);
        }

        // Ajouter les styles CSS
        this._addStyles();
    }

    /**
     * Ajoute les styles CSS nécessaires
     * @private
     */
    _addStyles() {
        if (document.getElementById('diagram-state-styles')) {
            return;
        }

        const style = document.createElement('style');
        style.id = 'diagram-state-styles';
        style.textContent = `
            .diagram-loading-overlay {
                position: absolute;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
                background-color: rgba(255, 255, 255, 0.8);
                display: flex;
                flex-direction: column;
                justify-content: center;
                align-items: center;
                z-index: 1000;
            }
            
            .diagram-loading-spinner {
                width: 50px;
                height: 50px;
                border: 5px solid #f3f3f3;
                border-top: 5px solid #4A86E8;
                border-radius: 50%;
                animation: diagram-spin 1s linear infinite;
            }
            
            @keyframes diagram-spin {
                0% { transform: rotate(0deg); }
                100% { transform: rotate(360deg); }
            }
            
            .diagram-loading-text {
                margin-top: 15px;
                font-size: 16px;
                color: #333;
            }
            
            .diagram-loading-progress {
                width: 200px;
                height: 5px;
                background-color: #f3f3f3;
                border-radius: 5px;
                margin-top: 10px;
                overflow: hidden;
            }
            
            .diagram-loading-progress-bar {
                height: 100%;
                width: 0;
                background-color: #4A86E8;
                border-radius: 5px;
                transition: width 0.3s ease;
            }
            
            .diagram-error-container {
                position: absolute;
                bottom: 0;
                left: 0;
                width: 100%;
                max-height: 30%;
                overflow-y: auto;
                background-color: rgba(231, 76, 60, 0.9);
                color: white;
                z-index: 1001;
                padding: 10px;
                box-sizing: border-box;
            }
            
            .diagram-error-item {
                padding: 8px 12px;
                margin-bottom: 5px;
                background-color: rgba(0, 0, 0, 0.1);
                border-radius: 4px;
                display: flex;
                justify-content: space-between;
                align-items: center;
            }
            
            .diagram-error-message {
                flex: 1;
            }
            
            .diagram-error-time {
                font-size: 12px;
                opacity: 0.8;
                margin-left: 10px;
            }
            
            .diagram-error-close {
                cursor: pointer;
                margin-left: 10px;
                opacity: 0.8;
            }
            
            .diagram-error-close:hover {
                opacity: 1;
            }
            
            .diagram-notification-container {
                position: fixed;
                top: 20px;
                right: 20px;
                width: 300px;
                z-index: 1002;
            }
            
            .diagram-notification {
                padding: 12px 15px;
                margin-bottom: 10px;
                border-radius: 4px;
                box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
                animation: diagram-notification-in 0.3s ease;
                display: flex;
                justify-content: space-between;
                align-items: flex-start;
            }
            
            .diagram-notification.info {
                background-color: #3498DB;
                color: white;
            }
            
            .diagram-notification.success {
                background-color: #2ECC71;
                color: white;
            }
            
            .diagram-notification.warning {
                background-color: #F39C12;
                color: white;
            }
            
            .diagram-notification.error {
                background-color: #E74C3C;
                color: white;
            }
            
            .diagram-notification-content {
                flex: 1;
            }
            
            .diagram-notification-title {
                font-weight: bold;
                margin-bottom: 5px;
            }
            
            .diagram-notification-message {
                font-size: 14px;
            }
            
            .diagram-notification-close {
                cursor: pointer;
                opacity: 0.8;
                margin-left: 10px;
            }
            
            .diagram-notification-close:hover {
                opacity: 1;
            }
            
            @keyframes diagram-notification-in {
                from { transform: translateX(100%); opacity: 0; }
                to { transform: translateX(0); opacity: 1; }
            }
            
            @keyframes diagram-notification-out {
                from { transform: translateX(0); opacity: 1; }
                to { transform: translateX(100%); opacity: 0; }
            }
            
            .diagram-notification.removing {
                animation: diagram-notification-out 0.3s ease forwards;
            }
            
            @media (prefers-color-scheme: dark) {
                .diagram-loading-overlay {
                    background-color: rgba(30, 30, 30, 0.8);
                }
                
                .diagram-loading-spinner {
                    border-color: #444;
                    border-top-color: #4A86E8;
                }
                
                .diagram-loading-text {
                    color: #eee;
                }
                
                .diagram-loading-progress {
                    background-color: #444;
                }
            }
        `;
        document.head.appendChild(style);
    }

    /**
     * Démarre l'état de chargement
     * @param {string} message - Message de chargement (optionnel)
     * @param {number} progress - Progression initiale (0-100, optionnel)
     */
    startLoading(message = 'Chargement...', progress = 0) {
        this.isLoading = true;
        this.loadingStartTime = Date.now();

        if (this.loadingOverlay) {
            const textElement = this.loadingOverlay.querySelector('.diagram-loading-text');
            if (textElement) {
                textElement.textContent = message;
            }

            const progressBar = this.loadingOverlay.querySelector('.diagram-loading-progress-bar');
            if (progressBar) {
                progressBar.style.width = `${progress}%`;
            }

            this.loadingOverlay.style.display = 'flex';
        }

        // Configurer le timeout de chargement
        this._setupLoadingTimeout();
    }

    /**
     * Met à jour l'état de chargement
     * @param {number} progress - Progression (0-100)
     * @param {string} message - Nouveau message (optionnel)
     */
    updateLoading(progress, message = null) {
        if (!this.isLoading) return;

        if (this.loadingOverlay) {
            const progressBar = this.loadingOverlay.querySelector('.diagram-loading-progress-bar');
            if (progressBar) {
                progressBar.style.width = `${progress}%`;
            }

            if (message) {
                const textElement = this.loadingOverlay.querySelector('.diagram-loading-text');
                if (textElement) {
                    textElement.textContent = message;
                }
            }
        }
    }

    /**
     * Termine l'état de chargement
     */
    stopLoading() {
        this.isLoading = false;
        this.loadingStartTime = null;

        // Annuler le timeout
        if (this.loadingTimeoutTimer) {
            clearTimeout(this.loadingTimeoutTimer);
            this.loadingTimeoutTimer = null;
        }

        if (this.loadingOverlay) {
            this.loadingOverlay.style.display = 'none';
        }
    }

    /**
     * Configure le timeout de chargement
     * @private
     */
    _setupLoadingTimeout() {
        // Annuler tout timeout existant
        if (this.loadingTimeoutTimer) {
            clearTimeout(this.loadingTimeoutTimer);
        }

        // Configurer un nouveau timeout
        this.loadingTimeoutTimer = setTimeout(() => {
            if (this.isLoading) {
                // Ajouter une erreur de timeout
                this.addError('Le chargement prend plus de temps que prévu. Vérifiez votre connexion ou réessayez plus tard.');
                
                // Ne pas arrêter le chargement, juste notifier
            }
        }, this.loadingTimeout);
    }

    /**
     * Ajoute une erreur
     * @param {string} message - Message d'erreur
     * @param {Error} error - Objet d'erreur (optionnel)
     * @param {boolean} showNotification - Afficher également une notification
     */
    addError(message, error = null, showNotification = true) {
        const timestamp = new Date();
        const errorObj = {
            id: Date.now(),
            message,
            error,
            timestamp
        };

        // Ajouter l'erreur à la liste
        this.errors.unshift(errorObj);

        // Limiter le nombre d'erreurs
        if (this.errors.length > this.maxErrors) {
            this.errors.pop();
        }

        // Mettre à jour l'affichage des erreurs
        this._updateErrorDisplay();

        // Ajouter une notification si demandé
        if (showNotification && this.options.showNotifications) {
            this.addNotification('Erreur', message, 'error');
        }

        // Log l'erreur dans la console
        console.error('Erreur du diagramme:', message, error);
    }

    /**
     * Met à jour l'affichage des erreurs
     * @private
     */
    _updateErrorDisplay() {
        if (!this.errorContainer || !this.options.showErrorMessages) return;

        if (this.errors.length === 0) {
            this.errorContainer.style.display = 'none';
            return;
        }

        // Afficher le conteneur
        this.errorContainer.style.display = 'block';

        // Mettre à jour le contenu
        this.errorContainer.innerHTML = '';

        // Ajouter chaque erreur
        this.errors.forEach(error => {
            const errorItem = document.createElement('div');
            errorItem.className = 'diagram-error-item';
            
            const timeString = error.timestamp.toLocaleTimeString();
            
            errorItem.innerHTML = `
                <div class="diagram-error-message">${error.message}</div>
                <div class="diagram-error-time">${timeString}</div>
                <div class="diagram-error-close" data-error-id="${error.id}">×</div>
            `;
            
            this.errorContainer.appendChild(errorItem);
        });

        // Ajouter les gestionnaires d'événements pour les boutons de fermeture
        const closeButtons = this.errorContainer.querySelectorAll('.diagram-error-close');
        closeButtons.forEach(button => {
            button.addEventListener('click', () => {
                const errorId = parseInt(button.getAttribute('data-error-id'));
                this.removeError(errorId);
            });
        });
    }

    /**
     * Supprime une erreur par son ID
     * @param {number} errorId - ID de l'erreur à supprimer
     */
    removeError(errorId) {
        const index = this.errors.findIndex(error => error.id === errorId);
        
        if (index !== -1) {
            this.errors.splice(index, 1);
            this._updateErrorDisplay();
        }
    }

    /**
     * Efface toutes les erreurs
     */
    clearErrors() {
        this.errors = [];
        this._updateErrorDisplay();
    }

    /**
     * Ajoute une notification
     * @param {string} title - Titre de la notification
     * @param {string} message - Message de la notification
     * @param {string} type - Type de notification ('info', 'success', 'warning', 'error')
     * @param {number} duration - Durée d'affichage en ms (0 pour permanent)
     */
    addNotification(title, message, type = 'info', duration = null) {
        if (!this.notificationContainer || !this.options.showNotifications) return;

        const notificationId = Date.now();
        const notificationObj = {
            id: notificationId,
            title,
            message,
            type,
            timestamp: new Date()
        };

        // Ajouter la notification à la liste
        this.notifications.unshift(notificationObj);

        // Limiter le nombre de notifications
        if (this.notifications.length > this.maxNotifications) {
            const oldestNotification = this.notifications.pop();
            
            // Supprimer l'élément DOM correspondant s'il existe
            const oldElement = this.notificationContainer.querySelector(`[data-notification-id="${oldestNotification.id}"]`);
            if (oldElement) {
                oldElement.remove();
            }
        }

        // Créer l'élément de notification
        const notificationElement = document.createElement('div');
        notificationElement.className = `diagram-notification ${type}`;
        notificationElement.setAttribute('data-notification-id', notificationId);
        
        notificationElement.innerHTML = `
            <div class="diagram-notification-content">
                <div class="diagram-notification-title">${title}</div>
                <div class="diagram-notification-message">${message}</div>
            </div>
            <div class="diagram-notification-close">×</div>
        `;
        
        this.notificationContainer.appendChild(notificationElement);

        // Ajouter le gestionnaire d'événement pour le bouton de fermeture
        const closeButton = notificationElement.querySelector('.diagram-notification-close');
        closeButton.addEventListener('click', () => {
            this.removeNotification(notificationId);
        });

        // Configurer la disparition automatique
        const actualDuration = duration !== null ? duration : this.options.notificationDuration;
        
        if (actualDuration > 0) {
            setTimeout(() => {
                this.removeNotification(notificationId);
            }, actualDuration);
        }

        return notificationId;
    }

    /**
     * Supprime une notification par son ID
     * @param {number} notificationId - ID de la notification à supprimer
     */
    removeNotification(notificationId) {
        const index = this.notifications.findIndex(notification => notification.id === notificationId);
        
        if (index !== -1) {
            this.notifications.splice(index, 1);
            
            // Supprimer l'élément DOM avec animation
            const element = this.notificationContainer.querySelector(`[data-notification-id="${notificationId}"]`);
            
            if (element) {
                element.classList.add('removing');
                
                // Supprimer l'élément après l'animation
                element.addEventListener('animationend', () => {
                    if (element.parentNode) {
                        element.parentNode.removeChild(element);
                    }
                });
            }
        }
    }

    /**
     * Efface toutes les notifications
     */
    clearNotifications() {
        this.notifications = [];
        
        // Supprimer tous les éléments DOM avec animation
        const elements = this.notificationContainer.querySelectorAll('.diagram-notification');
        
        elements.forEach(element => {
            element.classList.add('removing');
            
            element.addEventListener('animationend', () => {
                if (element.parentNode) {
                    element.parentNode.removeChild(element);
                }
            });
        });
    }

    /**
     * Nettoie les ressources utilisées par le gestionnaire d'état
     */
    dispose() {
        // Annuler le timeout de chargement
        if (this.loadingTimeoutTimer) {
            clearTimeout(this.loadingTimeoutTimer);
            this.loadingTimeoutTimer = null;
        }

        // Supprimer les éléments DOM
        if (this.loadingOverlay && this.loadingOverlay.parentNode) {
            this.loadingOverlay.parentNode.removeChild(this.loadingOverlay);
        }

        if (this.errorContainer && this.errorContainer.parentNode) {
            this.errorContainer.parentNode.removeChild(this.errorContainer);
        }

        if (this.notificationContainer && this.notificationContainer.parentNode) {
            this.notificationContainer.parentNode.removeChild(this.notificationContainer);
        }

        // Réinitialiser les références
        this.loadingOverlay = null;
        this.errorContainer = null;
        this.notificationContainer = null;
        this.errors = [];
        this.notifications = [];
    }
}

// Exporter la classe pour utilisation dans d'autres modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        DiagramStateManager
    };
}
