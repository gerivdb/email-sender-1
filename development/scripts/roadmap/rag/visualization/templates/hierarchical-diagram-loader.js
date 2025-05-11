/**
 * hierarchical-diagram-loader.js
 * Module de chargement dynamique des données pour les diagrammes hiérarchiques
 * Version: 1.0
 * Date: 2025-05-15
 */

/**
 * Classe HierarchicalDiagramLoader
 * Gère le chargement et la mise à jour des données pour les diagrammes hiérarchiques
 */
class HierarchicalDiagramLoader {
    /**
     * Constructeur
     * @param {Object} options - Options de configuration
     * @param {string} options.containerId - ID du conteneur SVG
     * @param {string} options.dataUrl - URL de l'API pour charger les données
     * @param {Function} options.onDataLoaded - Callback appelé quand les données sont chargées
     * @param {Function} options.onError - Callback appelé en cas d'erreur
     * @param {number} options.refreshInterval - Intervalle de rafraîchissement en ms (0 pour désactiver)
     * @param {Object} options.filters - Filtres initiaux à appliquer
     */
    constructor(options = {}) {
        // Options par défaut
        this.options = Object.assign({
            containerId: 'hierarchy-container',
            dataUrl: 'api/hierarchical-data',
            onDataLoaded: null,
            onError: null,
            refreshInterval: 0,
            filters: {}
        }, options);

        // État interne
        this.data = null;
        this.isLoading = false;
        this.lastLoadTime = null;
        this.refreshTimer = null;
        this.errorCount = 0;
        this.maxRetries = 3;
        this.retryDelay = 2000;
        this.abortController = null;

        // Éléments DOM
        this.container = document.getElementById(this.options.containerId);
        this.loadingIndicator = null;
        this.errorIndicator = null;

        // Initialisation
        this._createIndicators();
        
        // Démarrer le rafraîchissement automatique si configuré
        if (this.options.refreshInterval > 0) {
            this.startAutoRefresh();
        }
    }

    /**
     * Crée les indicateurs de chargement et d'erreur
     * @private
     */
    _createIndicators() {
        // Créer l'indicateur de chargement
        this.loadingIndicator = document.createElement('div');
        this.loadingIndicator.className = 'loading-indicator';
        this.loadingIndicator.innerHTML = `
            <div class="spinner"></div>
            <div class="loading-text">Chargement des données...</div>
        `;
        this.loadingIndicator.style.display = 'none';
        
        // Créer l'indicateur d'erreur
        this.errorIndicator = document.createElement('div');
        this.errorIndicator.className = 'error-indicator';
        this.errorIndicator.innerHTML = `
            <div class="error-icon">⚠️</div>
            <div class="error-text">Erreur lors du chargement des données</div>
            <button class="retry-button">Réessayer</button>
        `;
        this.errorIndicator.style.display = 'none';
        
        // Ajouter les gestionnaires d'événements
        this.errorIndicator.querySelector('.retry-button').addEventListener('click', () => {
            this.loadData();
        });
        
        // Ajouter les indicateurs au conteneur parent
        const parent = this.container.parentNode;
        parent.style.position = 'relative';
        parent.appendChild(this.loadingIndicator);
        parent.appendChild(this.errorIndicator);
        
        // Ajouter les styles CSS
        if (!document.getElementById('loader-styles')) {
            const style = document.createElement('style');
            style.id = 'loader-styles';
            style.textContent = `
                .loading-indicator, .error-indicator {
                    position: absolute;
                    top: 50%;
                    left: 50%;
                    transform: translate(-50%, -50%);
                    background-color: white;
                    padding: 20px;
                    border-radius: 8px;
                    box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
                    text-align: center;
                    z-index: 1000;
                }
                
                .spinner {
                    width: 40px;
                    height: 40px;
                    margin: 0 auto 10px;
                    border: 4px solid #f3f3f3;
                    border-top: 4px solid #3498db;
                    border-radius: 50%;
                    animation: spin 1s linear infinite;
                }
                
                @keyframes spin {
                    0% { transform: rotate(0deg); }
                    100% { transform: rotate(360deg); }
                }
                
                .loading-text, .error-text {
                    margin: 10px 0;
                    font-size: 14px;
                }
                
                .error-icon {
                    font-size: 32px;
                    margin-bottom: 10px;
                }
                
                .retry-button {
                    padding: 8px 16px;
                    background-color: #4A86E8;
                    color: white;
                    border: none;
                    border-radius: 4px;
                    cursor: pointer;
                    font-size: 14px;
                }
                
                .retry-button:hover {
                    background-color: #2A66C8;
                }
            `;
            document.head.appendChild(style);
        }
    }

    /**
     * Charge les données depuis l'API
     * @param {Object} filters - Filtres à appliquer (optionnel)
     * @returns {Promise} - Promise résolue avec les données ou rejetée avec une erreur
     */
    loadData(filters = null) {
        // Fusionner les filtres avec les filtres par défaut
        const mergedFilters = Object.assign({}, this.options.filters, filters || {});
        
        // Annuler toute requête en cours
        if (this.abortController) {
            this.abortController.abort();
        }
        
        // Créer un nouveau contrôleur d'abandon
        this.abortController = new AbortController();
        
        // Mettre à jour l'état
        this.isLoading = true;
        this._showLoading(true);
        this._showError(false);
        
        // Construire l'URL avec les paramètres de filtrage
        let url = this.options.dataUrl;
        const queryParams = new URLSearchParams();
        
        for (const [key, value] of Object.entries(mergedFilters)) {
            if (Array.isArray(value)) {
                // Pour les tableaux, ajouter chaque valeur séparément
                value.forEach(v => queryParams.append(`${key}[]`, v));
            } else if (value !== null && value !== undefined) {
                queryParams.append(key, value);
            }
        }
        
        // Ajouter un timestamp pour éviter la mise en cache
        queryParams.append('_t', Date.now());
        
        // Ajouter les paramètres à l'URL
        const queryString = queryParams.toString();
        if (queryString) {
            url += (url.includes('?') ? '&' : '?') + queryString;
        }
        
        // Effectuer la requête
        return fetch(url, {
            method: 'GET',
            headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json'
            },
            signal: this.abortController.signal
        })
        .then(response => {
            if (!response.ok) {
                throw new Error(`Erreur HTTP: ${response.status} ${response.statusText}`);
            }
            return response.json();
        })
        .then(data => {
            // Mettre à jour l'état
            this.data = data;
            this.lastLoadTime = new Date();
            this.isLoading = false;
            this.errorCount = 0;
            this._showLoading(false);
            
            // Appeler le callback
            if (typeof this.options.onDataLoaded === 'function') {
                this.options.onDataLoaded(data);
            }
            
            return data;
        })
        .catch(error => {
            // Ignorer les erreurs d'abandon
            if (error.name === 'AbortError') {
                console.log('Requête annulée');
                return;
            }
            
            // Mettre à jour l'état
            this.isLoading = false;
            this.errorCount++;
            this._showLoading(false);
            this._showError(true, error.message);
            
            // Appeler le callback d'erreur
            if (typeof this.options.onError === 'function') {
                this.options.onError(error);
            }
            
            // Réessayer automatiquement si configuré
            if (this.errorCount <= this.maxRetries) {
                console.log(`Tentative de rechargement (${this.errorCount}/${this.maxRetries}) dans ${this.retryDelay}ms`);
                setTimeout(() => {
                    this.loadData(filters);
                }, this.retryDelay);
            }
            
            throw error;
        });
    }

    /**
     * Démarre le rafraîchissement automatique des données
     */
    startAutoRefresh() {
        // Arrêter le timer existant s'il y en a un
        this.stopAutoRefresh();
        
        // Démarrer un nouveau timer
        if (this.options.refreshInterval > 0) {
            this.refreshTimer = setInterval(() => {
                // Ne recharger que si aucun chargement n'est en cours
                if (!this.isLoading) {
                    this.loadData();
                }
            }, this.options.refreshInterval);
            
            console.log(`Rafraîchissement automatique démarré (${this.options.refreshInterval}ms)`);
        }
    }

    /**
     * Arrête le rafraîchissement automatique des données
     */
    stopAutoRefresh() {
        if (this.refreshTimer) {
            clearInterval(this.refreshTimer);
            this.refreshTimer = null;
            console.log('Rafraîchissement automatique arrêté');
        }
    }

    /**
     * Met à jour les filtres et recharge les données
     * @param {Object} filters - Nouveaux filtres à appliquer
     * @param {boolean} merge - Si true, fusionne avec les filtres existants, sinon remplace
     */
    updateFilters(filters, merge = true) {
        if (merge) {
            this.options.filters = Object.assign({}, this.options.filters, filters);
        } else {
            this.options.filters = filters;
        }
        
        return this.loadData();
    }

    /**
     * Affiche ou masque l'indicateur de chargement
     * @param {boolean} show - True pour afficher, false pour masquer
     * @private
     */
    _showLoading(show) {
        if (this.loadingIndicator) {
            this.loadingIndicator.style.display = show ? 'block' : 'none';
        }
    }

    /**
     * Affiche ou masque l'indicateur d'erreur
     * @param {boolean} show - True pour afficher, false pour masquer
     * @param {string} message - Message d'erreur à afficher (optionnel)
     * @private
     */
    _showError(show, message = null) {
        if (this.errorIndicator) {
            this.errorIndicator.style.display = show ? 'block' : 'none';
            
            if (show && message) {
                const errorText = this.errorIndicator.querySelector('.error-text');
                if (errorText) {
                    errorText.textContent = message;
                }
            }
        }
    }

    /**
     * Nettoie les ressources utilisées par le loader
     */
    dispose() {
        // Arrêter le rafraîchissement automatique
        this.stopAutoRefresh();
        
        // Annuler toute requête en cours
        if (this.abortController) {
            this.abortController.abort();
            this.abortController = null;
        }
        
        // Supprimer les indicateurs
        if (this.loadingIndicator && this.loadingIndicator.parentNode) {
            this.loadingIndicator.parentNode.removeChild(this.loadingIndicator);
        }
        
        if (this.errorIndicator && this.errorIndicator.parentNode) {
            this.errorIndicator.parentNode.removeChild(this.errorIndicator);
        }
        
        // Réinitialiser les références
        this.loadingIndicator = null;
        this.errorIndicator = null;
        this.data = null;
    }
}

/**
 * Classe DataSourceAdapter
 * Adapte différentes sources de données au format attendu par le diagramme hiérarchique
 */
class DataSourceAdapter {
    /**
     * Constructeur
     * @param {string} sourceType - Type de source de données ('api', 'file', 'local')
     * @param {Object} options - Options spécifiques à la source
     */
    constructor(sourceType, options = {}) {
        this.sourceType = sourceType;
        this.options = options;
    }

    /**
     * Charge les données depuis la source
     * @param {Object} params - Paramètres de chargement
     * @returns {Promise} - Promise résolue avec les données au format attendu
     */
    loadData(params = {}) {
        switch (this.sourceType) {
            case 'api':
                return this._loadFromApi(params);
            case 'file':
                return this._loadFromFile(params);
            case 'local':
                return this._loadFromLocalStorage(params);
            default:
                return Promise.reject(new Error(`Type de source non pris en charge: ${this.sourceType}`));
        }
    }

    /**
     * Charge les données depuis une API
     * @param {Object} params - Paramètres de requête
     * @returns {Promise} - Promise résolue avec les données
     * @private
     */
    _loadFromApi(params) {
        const loader = new HierarchicalDiagramLoader({
            dataUrl: this.options.apiUrl || 'api/hierarchical-data',
            filters: params
        });
        
        return loader.loadData();
    }

    /**
     * Charge les données depuis un fichier
     * @param {Object} params - Paramètres de chargement
     * @returns {Promise} - Promise résolue avec les données
     * @private
     */
    _loadFromFile(params) {
        const filePath = this.options.filePath || 'data/hierarchical-data.json';
        
        return fetch(filePath)
            .then(response => {
                if (!response.ok) {
                    throw new Error(`Erreur lors du chargement du fichier: ${response.status} ${response.statusText}`);
                }
                return response.json();
            })
            .then(data => {
                // Appliquer les filtres côté client
                return this._applyFilters(data, params);
            });
    }

    /**
     * Charge les données depuis le localStorage
     * @param {Object} params - Paramètres de chargement
     * @returns {Promise} - Promise résolue avec les données
     * @private
     */
    _loadFromLocalStorage(params) {
        const key = this.options.storageKey || 'hierarchicalData';
        
        return new Promise((resolve, reject) => {
            try {
                const data = localStorage.getItem(key);
                
                if (!data) {
                    reject(new Error(`Aucune donnée trouvée dans localStorage avec la clé: ${key}`));
                    return;
                }
                
                const parsedData = JSON.parse(data);
                
                // Appliquer les filtres côté client
                const filteredData = this._applyFilters(parsedData, params);
                
                resolve(filteredData);
            } catch (error) {
                reject(error);
            }
        });
    }

    /**
     * Applique les filtres aux données
     * @param {Object} data - Données à filtrer
     * @param {Object} filters - Filtres à appliquer
     * @returns {Object} - Données filtrées
     * @private
     */
    _applyFilters(data, filters) {
        // Si aucun filtre, retourner les données telles quelles
        if (!filters || Object.keys(filters).length === 0) {
            return data;
        }
        
        // Fonction récursive pour filtrer les nœuds
        const filterNode = (node) => {
            // Vérifier si le nœud correspond aux filtres
            let matches = true;
            
            // Filtrer par statut
            if (filters.status && Array.isArray(filters.status) && filters.status.length > 0) {
                matches = matches && filters.status.includes(node.status);
            }
            
            // Filtrer par priorité
            if (filters.priority && Array.isArray(filters.priority) && filters.priority.length > 0) {
                matches = matches && filters.priority.includes(node.priority);
            }
            
            // Filtrer par progression
            if (filters.progressMin !== undefined) {
                matches = matches && node.progress >= filters.progressMin;
            }
            
            if (filters.progressMax !== undefined) {
                matches = matches && node.progress <= filters.progressMax;
            }
            
            // Filtrer par texte
            if (filters.searchText) {
                const searchText = filters.searchText.toLowerCase();
                const nodeText = (node.id + ' ' + node.title + ' ' + node.description).toLowerCase();
                matches = matches && nodeText.includes(searchText);
            }
            
            // Filtrer les enfants récursivement
            if (node.children && node.children.length > 0) {
                const filteredChildren = node.children
                    .map(filterNode)
                    .filter(child => child !== null);
                
                // Si des enfants correspondent, inclure ce nœud même s'il ne correspond pas lui-même
                if (filteredChildren.length > 0) {
                    return {
                        ...node,
                        children: filteredChildren
                    };
                }
            }
            
            // Si le nœud correspond, le retourner, sinon null
            return matches ? node : null;
        };
        
        // Appliquer le filtre à partir de la racine
        const filteredData = filterNode(data);
        
        // Si aucun nœud ne correspond, retourner une structure minimale
        if (filteredData === null) {
            return {
                id: "root",
                title: "Aucun résultat",
                status: "À faire",
                priority: "Basse",
                progress: 0,
                description: "Aucun élément ne correspond aux filtres sélectionnés.",
                children: []
            };
        }
        
        return filteredData;
    }
}

// Exporter les classes pour utilisation dans d'autres modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        HierarchicalDiagramLoader,
        DataSourceAdapter
    };
}
